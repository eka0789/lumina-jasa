import {
  BookingOrder,
  PaymentIntent,
  PaymentHold,
  Payout,
  Refund,
  Dispute,
  LedgerAccount,
  LedgerTransaction,
  LedgerEntry,
  ReconciliationResult
} from "./types"

export class PaymentEngineError extends Error {
  constructor(public code: string, message: string) {
    super(message)
    this.name = "PaymentEngineError"
  }
}

export class PaymentStore {
  bookings = new Map<string, BookingOrder>()
  paymentIntents = new Map<string, PaymentIntent>()
  paymentHolds = new Map<string, PaymentHold>()
  payouts = new Map<string, Payout>()
  refunds = new Map<string, Refund>()
  disputes = new Map<string, Dispute>()
  ledgerAccounts = new Map<string, LedgerAccount>()
  ledgerTransactions: LedgerTransaction[] = []

  // Idempotency registries
  payoutIdempotency = new Set<string>()
  refundIdempotency = new Set<string>()

  // Row lock simulator
  activeLocks = new Set<string>()

  lockRow(resourceKey: string): void {
    if (this.activeLocks.has(resourceKey)) {
      throw new PaymentEngineError("CONCURRENT_LOCK_ERROR", `Resource '${resourceKey}' is locked by a concurrent transaction`)
    }
    this.activeLocks.add(resourceKey)
  }

  unlockRow(resourceKey: string): void {
    this.activeLocks.delete(resourceKey)
  }

  clear(): void {
    this.bookings.clear()
    this.paymentIntents.clear()
    this.paymentHolds.clear()
    this.payouts.clear()
    this.refunds.clear()
    this.disputes.clear()
    this.ledgerAccounts.clear()
    this.ledgerTransactions = []
    this.payoutIdempotency.clear()
    this.refundIdempotency.clear()
    this.activeLocks.clear()
  }
}

/**
 * Asserts double-entry ledger entries balance to exactly 0.
 */
export function assertLedgerBalance(entries: LedgerEntry[]): void {
  const sum = entries.reduce((acc, curr) => acc + curr.amount, 0)
  if (Math.abs(sum) > 0.0001) {
    throw new PaymentEngineError("LEDGER_IMBALANCE", `Double-entry ledger transaction is imbalanced! Sum = ${sum}`)
  }
}

/**
 * Captures payment for booking and posts balanced ledger entry.
 */
export function capturePaymentTransaction(
  store: PaymentStore,
  bookingId: string,
  paymentAmount: number,
  currency = "IDR",
  actorId = "system"
): { booking: BookingOrder; intent: PaymentIntent; hold: PaymentHold } {
  store.lockRow(`booking:${bookingId}`)
  try {
    const booking = store.bookings.get(bookingId)
    if (!booking) throw new PaymentEngineError("ORDER_NOT_FOUND", "Booking order not found")

    // Server-Side Amount & Currency Validation
    if (currency !== "IDR") throw new PaymentEngineError("WRONG_CURRENCY", "Only IDR currency is accepted")
    if (paymentAmount !== booking.totalAmount) throw new PaymentEngineError("WRONG_AMOUNT", `Payment amount ${paymentAmount} does not match booking total ${booking.totalAmount}`)

    if (booking.status === "cancelled") throw new PaymentEngineError("ORDER_CANCELLED", "Order is cancelled")
    if (booking.status === "expired" || booking.expiresAt <= Date.now()) throw new PaymentEngineError("ORDER_EXPIRED", "Order is expired")
    if (booking.status === "confirmed") throw new PaymentEngineError("ALREADY_PAID", "Order is already paid and confirmed")

    let intent = Array.from(store.paymentIntents.values()).find(i => i.bookingId === bookingId)
    if (!intent) {
      intent = {
        id: `intent-${bookingId}`,
        bookingId,
        provider: "sandbox_psp",
        status: "pending",
        amount: booking.totalAmount,
        currency,
        expiresAt: booking.expiresAt,
        version: 1,
        createdAt: Date.now(),
        updatedAt: Date.now()
      }
      store.paymentIntents.set(intent.id, intent)
    }

    if (intent.status === "captured") throw new PaymentEngineError("ALREADY_PAID", "Payment intent is already captured")

    // Update Intent & Booking State
    intent.status = "captured"
    intent.updatedAt = Date.now()
    intent.version++

    booking.status = "confirmed"
    booking.updatedAt = Date.now()
    booking.version++

    // Create Payment Hold
    const hold: PaymentHold = {
      id: `hold-${bookingId}`,
      bookingId,
      paymentIntentId: intent.id,
      amount: booking.totalAmount,
      status: "held",
      version: 1,
      createdAt: Date.now()
    }
    store.paymentHolds.set(hold.id, hold)

    // Ledger Postings (Double Entry Balance Check)
    const entries: LedgerEntry[] = [
      { id: `e-1-${Date.now()}`, transactionId: `tx-${bookingId}`, accountId: "acc-psp-cash", amount: booking.totalAmount }, // Asset +
      { id: `e-2-${Date.now()}`, transactionId: `tx-${bookingId}`, accountId: `acc-provider-${booking.providerId}`, amount: -booking.subtotal }, // Liability -
      { id: `e-3-${Date.now()}`, transactionId: `tx-${bookingId}`, accountId: "acc-platform-fee", amount: -booking.platformFee } // Revenue -
    ]
    if (booking.taxAmount > 0) {
      entries.push({ id: `e-4-${Date.now()}`, transactionId: `tx-${bookingId}`, accountId: "acc-tax-payable", amount: -booking.taxAmount }) // Liability -
    }

    assertLedgerBalance(entries)

    const tx: LedgerTransaction = {
      id: `tx-${bookingId}`,
      referenceType: "payment_intent",
      referenceId: intent.id,
      kind: "payment_captured",
      description: "Sandbox payment captured",
      createdBy: actorId,
      createdAt: Date.now(),
      entries
    }
    store.ledgerTransactions.push(tx)

    return { booking, intent, hold }
  } finally {
    store.unlockRow(`booking:${bookingId}`)
  }
}

/**
 * Opens dispute and freezes payment hold to block payout.
 */
export function openDisputeHold(
  store: PaymentStore,
  bookingId: string,
  disputedAmount: number,
  reason: string,
  actorId: string
): Dispute {
  store.lockRow(`booking:${bookingId}`)
  try {
    const booking = store.bookings.get(bookingId)
    if (!booking) throw new PaymentEngineError("ORDER_NOT_FOUND", "Booking order not found")

    const hold = store.paymentHolds.get(`hold-${bookingId}`)
    if (!hold) throw new PaymentEngineError("HOLD_NOT_FOUND", "Payment hold record not found")

    if (hold.status === "released") throw new PaymentEngineError("PAYOUT_ALREADY_RELEASED", "Cannot open dispute: Payout has already been released")

    // Freeze Payment Hold
    hold.status = "frozen"
    hold.version++

    booking.status = "disputed"
    booking.updatedAt = Date.now()

    const dispute: Dispute = {
      id: `dispute-${bookingId}`,
      bookingId,
      openedBy: actorId,
      reason,
      disputedAmount,
      status: "opened",
      createdAt: Date.now()
    }
    store.disputes.set(dispute.id, dispute)

    return dispute
  } finally {
    store.unlockRow(`booking:${bookingId}`)
  }
}

/**
 * Releases payout to provider after customer confirmation.
 */
export function releasePayout(
  store: PaymentStore,
  bookingId: string,
  idempotencyKey: string,
  actorId = "system"
): Payout {
  store.lockRow(`booking:${bookingId}`)
  try {
    // Idempotency Check
    if (store.payoutIdempotency.has(idempotencyKey)) {
      const existingPayout = Array.from(store.payouts.values()).find(p => p.idempotencyKey === idempotencyKey)
      if (existingPayout) return existingPayout
    }

    const booking = store.bookings.get(bookingId)
    if (!booking) throw new PaymentEngineError("ORDER_NOT_FOUND", "Booking order not found")

    const hold = store.paymentHolds.get(`hold-${bookingId}`)
    if (!hold) throw new PaymentEngineError("HOLD_NOT_FOUND", "Payment hold not found")

    if (hold.status === "frozen") throw new PaymentEngineError("DISPUTE_ACTIVE", "Cannot release payout: Payment hold is frozen due to active dispute")
    if (hold.status === "released") throw new PaymentEngineError("PAYOUT_ALREADY_RELEASED", "Payout has already been released for this booking")
    if (hold.status === "refunded") throw new PaymentEngineError("ALREADY_REFUNDED", "Cannot release payout: Payment has been refunded")

    // Check if payout record already exists
    const existingPayout = Array.from(store.payouts.values()).find(p => p.bookingId === bookingId)
    if (existingPayout && (existingPayout.status === "succeeded" || existingPayout.status === "processing")) {
      throw new PaymentEngineError("PAYOUT_ALREADY_RELEASED", "Payout already exists and is released or processing")
    }

    if (booking.status !== "customer_confirmed") {
      throw new PaymentEngineError("ORDER_NOT_CONFIRMED", "Payout requires customer confirmation of service completion")
    }

    // Release Payment Hold
    hold.status = "released"
    hold.releasedAt = Date.now()
    hold.version++

    const payout: Payout = {
      id: `payout-${bookingId}`,
      providerId: booking.providerId,
      bookingId,
      amount: booking.subtotal,
      status: "succeeded",
      idempotencyKey,
      processedAt: Date.now(),
      createdAt: Date.now()
    }

    store.payouts.set(payout.id, payout)
    store.payoutIdempotency.add(idempotencyKey)

    // Ledger Postings (Debit Provider Liability, Credit Bank Asset)
    const entries: LedgerEntry[] = [
      { id: `e-p1-${Date.now()}`, transactionId: `tx-payout-${bookingId}`, accountId: `acc-provider-${booking.providerId}`, amount: booking.subtotal }, // Liability +
      { id: `e-p2-${Date.now()}`, transactionId: `tx-payout-${bookingId}`, accountId: "acc-bank-out", amount: -booking.subtotal } // Asset -
    ]
    assertLedgerBalance(entries)

    store.ledgerTransactions.push({
      id: `tx-payout-${bookingId}`,
      referenceType: "payout",
      referenceId: payout.id,
      kind: "payout_disbursed",
      description: "Provider payout disbursed",
      createdBy: actorId,
      createdAt: Date.now(),
      entries
    })

    return payout
  } finally {
    store.unlockRow(`booking:${bookingId}`)
  }
}

/**
 * Refunds booking payment safely with anti-double-refund & anti-concurrent-payout guards.
 */
export function executeRefund(
  store: PaymentStore,
  bookingId: string,
  refundAmount: number,
  reasonCode: string,
  idempotencyKey: string,
  actorId: string
): Refund {
  store.lockRow(`booking:${bookingId}`)
  try {
    // Idempotency Check
    if (store.refundIdempotency.has(idempotencyKey)) {
      const existingRefund = Array.from(store.refunds.values()).find(r => r.idempotencyKey === idempotencyKey)
      if (existingRefund) return existingRefund
    }

    const booking = store.bookings.get(bookingId)
    if (!booking) throw new PaymentEngineError("ORDER_NOT_FOUND", "Booking order not found")

    const intent = store.paymentIntents.get(`intent-${bookingId}`)
    if (!intent || intent.status !== "captured") {
      throw new PaymentEngineError("NOT_PAID", "Cannot refund: Order is not paid")
    }

    const hold = store.paymentHolds.get(`hold-${bookingId}`)
    if (!hold) throw new PaymentEngineError("HOLD_NOT_FOUND", "Payment hold not found")

    // Check conflict with Payout
    const payout = store.payouts.get(`payout-${bookingId}`)
    if (payout && (payout.status === "succeeded" || payout.status === "processing")) {
      throw new PaymentEngineError("REFUND_PAYOUT_CONFLICT", "Cannot refund: Provider payout has already been released")
    }

    if (hold.status === "refunded") {
      throw new PaymentEngineError("ALREADY_REFUNDED", "Booking payment has already been refunded")
    }

    if (refundAmount <= 0 || refundAmount > booking.totalAmount) {
      throw new PaymentEngineError("INVALID_REFUND_AMOUNT", `Refund amount ${refundAmount} exceeds maximum refundable ${booking.totalAmount}`)
    }

    // Process Refund
    const refund: Refund = {
      id: `refund-${bookingId}`,
      bookingId,
      paymentIntentId: intent.id,
      amount: refundAmount,
      reasonCode,
      status: "succeeded",
      requestedBy: actorId,
      approvedBy: actorId,
      idempotencyKey,
      processedAt: Date.now(),
      createdAt: Date.now()
    }

    store.refunds.set(refund.id, refund)
    store.refundIdempotency.add(idempotencyKey)

    // Update statuses
    intent.status = refundAmount === booking.totalAmount ? "refunded" : "partially_refunded"
    intent.version++

    hold.status = refundAmount === booking.totalAmount ? "refunded" : "partially_refunded"
    hold.version++

    booking.status = "resolved"
    booking.version++

    const dispute = store.disputes.get(`dispute-${bookingId}`)
    if (dispute) {
      dispute.status = "resolved"
      dispute.resolvedRefund = refundAmount
      dispute.resolvedAt = Date.now()
    }

    // Ledger Postings (Reverse Payment Ledger Entry)
    const ratio = refundAmount / booking.totalAmount
    const providerPart = Math.round(booking.subtotal * ratio)
    const feePart = Math.round(booking.platformFee * ratio)
    const taxPart = refundAmount - providerPart - feePart

    const entries: LedgerEntry[] = [
      { id: `e-r1-${Date.now()}`, transactionId: `tx-refund-${bookingId}`, accountId: "acc-psp-cash", amount: -refundAmount }, // Asset - (Returned to customer)
      { id: `e-r2-${Date.now()}`, transactionId: `tx-refund-${bookingId}`, accountId: `acc-provider-${booking.providerId}`, amount: providerPart }, // Liability +
      { id: `e-r3-${Date.now()}`, transactionId: `tx-refund-${bookingId}`, accountId: "acc-platform-fee", amount: feePart } // Revenue +
    ]
    if (taxPart !== 0) {
      entries.push({ id: `e-r4-${Date.now()}`, transactionId: `tx-refund-${bookingId}`, accountId: "acc-tax-payable", amount: taxPart })
    }

    assertLedgerBalance(entries)

    store.ledgerTransactions.push({
      id: `tx-refund-${bookingId}`,
      referenceType: "refund",
      referenceId: refund.id,
      kind: "refund_succeeded",
      description: "Sandbox dispute refund",
      createdBy: actorId,
      createdAt: Date.now(),
      entries
    })

    return refund
  } finally {
    store.unlockRow(`booking:${bookingId}`)
  }
}

/**
 * Runs financial reconciliation audit job across all transactions.
 */
export function runReconciliationJob(store: PaymentStore): ReconciliationResult {
  let matched = 0
  let unmatched = 0
  let amountMismatches = 0
  let statusDiscrepancies = 0
  const anomalies: string[] = []

  for (const booking of store.bookings.values()) {
    const intent = store.paymentIntents.get(`intent-${booking.id}`)
    if (booking.status === "confirmed" || booking.status === "customer_confirmed" || booking.status === "closed") {
      if (!intent) {
        unmatched++
        anomalies.push(`Booking '${booking.id}' is ${booking.status} but missing PaymentIntent`)
        continue
      }
      if (intent.status !== "captured") {
        statusDiscrepancies++
        anomalies.push(`Booking '${booking.id}' status (${booking.status}) conflicts with PaymentIntent status (${intent.status})`)
      }
      if (intent.amount !== booking.totalAmount) {
        amountMismatches++
        anomalies.push(`Booking '${booking.id}' total (${booking.totalAmount}) mismatches PaymentIntent amount (${intent.amount})`)
      }
      matched++
    }
  }

  // Check ledger balances
  for (const tx of store.ledgerTransactions) {
    try {
      assertLedgerBalance(tx.entries)
    } catch (err: any) {
      anomalies.push(`Imbalanced ledger transaction '${tx.id}': ${err.message}`)
    }
  }

  return {
    totalProcessedEvents: store.paymentIntents.size + store.payouts.size + store.refunds.size,
    successfulMatches: matched,
    unmatchedWebhooks: unmatched,
    amountMismatches,
    statusDiscrepancies,
    flaggedAnomalies: anomalies
  }
}
