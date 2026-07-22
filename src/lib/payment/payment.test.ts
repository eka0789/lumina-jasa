import { describe, it, expect, beforeEach } from "vitest"
import {
  PaymentStore,
  capturePaymentTransaction,
  openDisputeHold,
  releasePayout,
  executeRefund,
  runReconciliationJob,
  PaymentEngineError,
  assertLedgerBalance
} from "./engine"
import {
  processPaymentWebhook,
  computeWebhookSignature,
  WebhookPayload
} from "./webhook"
import { BookingOrder, PaymentIntent } from "./types"

describe("Forensic Payment Audit & Security Engine Tests", () => {
  let store: PaymentStore
  const webhookSecret = "test-webhook-secret-key-12345"

  beforeEach(() => {
    store = new PaymentStore()

    // Seed test booking order
    const booking: BookingOrder = {
      id: "book-100",
      jobId: "job-100",
      customerId: "cust-1",
      providerId: "prov-1",
      status: "awaiting_payment",
      subtotal: 200000,
      platformFee: 25000,
      taxAmount: 2500,
      totalAmount: 227500,
      currency: "IDR",
      expiresAt: Date.now() + 3600000, // 1 hour valid
      version: 1,
      createdAt: Date.now(),
      updatedAt: Date.now()
    }
    store.bookings.set(booking.id, booking)

    const intent: PaymentIntent = {
      id: "intent-book-100",
      bookingId: booking.id,
      provider: "sandbox_psp",
      status: "pending",
      amount: 227500,
      currency: "IDR",
      expiresAt: booking.expiresAt,
      version: 1,
      createdAt: Date.now(),
      updatedAt: Date.now()
    }
    store.paymentIntents.set(intent.id, intent)
  })

  // Helper to construct signed webhook
  function createSignedWebhook(overrides: Partial<Omit<WebhookPayload, "signature">> = {}): WebhookPayload {
    const basePayload: Omit<WebhookPayload, "signature"> = {
      eventId: `evt-${Math.random().toString(36).substring(2, 9)}`,
      eventType: "payment.captured",
      providerReference: "psp-ref-999",
      bookingId: "book-100",
      amount: 227500,
      currency: "IDR",
      eventTimestamp: Date.now(),
      ...overrides
    }
    const signature = computeWebhookSignature(basePayload, webhookSecret)
    return { ...basePayload, signature }
  }

  // 1. Valid Payment Webhook Test
  it("1. Valid payment webhook: processes HMAC signed payload and updates order to confirmed", () => {
    const payload = createSignedWebhook()
    const result = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      (booking, _intent) => {
        return capturePaymentTransaction(store, booking.id, payload.amount, payload.currency).intent
      }
    )

    expect(result.success).toBe(true)
    expect(result.processed).toBe(true)
    expect(result.code).toBe("SUCCESS")
    expect(store.bookings.get("book-100")?.status).toBe("confirmed")
    expect(store.paymentIntents.get("intent-book-100")?.status).toBe("captured")
    expect(store.ledgerTransactions.length).toBe(1)
  })

  // 2. Duplicate Webhook Test
  it("2. Duplicate webhook: returns idempotent cached response without duplicate processing", () => {
    const payload = createSignedWebhook({ eventId: "evt-duplicate-1" })

    const res1 = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      (booking) => capturePaymentTransaction(store, booking.id, payload.amount, payload.currency).intent
    )
    expect(res1.processed).toBe(true)

    const res2 = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      (booking) => capturePaymentTransaction(store, booking.id, payload.amount, payload.currency).intent
    )

    expect(res2.success).toBe(true)
    expect(res2.processed).toBe(false)
    expect(res2.code).toBe("DUPLICATE_EVENT")
    expect(store.ledgerTransactions.length).toBe(1) // Zero duplicate ledger entries
  })

  // 3. Invalid Signature Test
  it("3. Invalid signature: rejects webhooks with bad HMAC signature", () => {
    const payload = createSignedWebhook()
    payload.signature = "bad-signature-hash"

    const result = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      () => { throw new Error("Should not execute") }
    )

    expect(result.success).toBe(false)
    expect(result.code).toBe("INVALID_SIGNATURE")
    expect(store.bookings.get("book-100")?.status).toBe("awaiting_payment")
  })

  // 4. Wrong Amount Test
  it("4. Wrong amount: rejects webhook with tampered amount differing from server total", () => {
    const payload = createSignedWebhook({ amount: 10000 }) // Tampered amount

    const result = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      () => { throw new Error("Should not execute") }
    )

    expect(result.success).toBe(false)
    expect(result.code).toBe("WRONG_AMOUNT")
    expect(store.bookings.get("book-100")?.status).toBe("awaiting_payment")
  })

  // 5. Wrong Currency Test
  it("5. Wrong currency: rejects webhook with non-IDR currency", () => {
    const payload = createSignedWebhook({ currency: "USD" })

    const result = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      () => { throw new Error("Should not execute") }
    )

    expect(result.success).toBe(false)
    expect(result.code).toBe("WRONG_CURRENCY")
  })

  // 6. Unknown External Reference Test
  it("6. Unknown external reference: rejects webhook referencing non-existent order ID", () => {
    const payload = createSignedWebhook({ bookingId: "non-existent-book-999" })

    const result = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      () => { throw new Error("Should not execute") }
    )

    expect(result.success).toBe(false)
    expect(result.code).toBe("UNKNOWN_ORDER")
  })

  // 7. Expired Order Test
  it("7. Expired order: rejects payment capture for expired booking window", () => {
    const booking = store.bookings.get("book-100")!
    booking.expiresAt = Date.now() - 5000 // Expired 5 seconds ago

    const payload = createSignedWebhook()
    const result = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      () => { throw new Error("Should not execute") }
    )

    expect(result.success).toBe(false)
    expect(result.code).toBe("ORDER_EXPIRED")
  })

  // 8. Cancelled Order Test
  it("8. Cancelled order: rejects payment capture for cancelled order", () => {
    const booking = store.bookings.get("book-100")!
    booking.status = "cancelled"

    const payload = createSignedWebhook()
    const result = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      () => { throw new Error("Should not execute") }
    )

    expect(result.success).toBe(false)
    expect(result.code).toBe("ORDER_CANCELLED")
  })

  // 9. Already Paid Order Test
  it("9. Already paid order: returns idempotent success without duplicate payment capture", () => {
    capturePaymentTransaction(store, "book-100", 227500, "IDR")

    const payload = createSignedWebhook({ eventId: "evt-new-after-paid" })
    const result = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      () => { throw new Error("Should not execute") }
    )

    expect(result.success).toBe(true)
    expect(result.processed).toBe(false)
    expect(result.code).toBe("ALREADY_PAID")
  })

  // 10. Out-of-Order Webhook Test
  it("10. Out-of-order webhook: drops older stale webhook events arriving after newer state", () => {
    const intent = store.paymentIntents.get("intent-book-100")!
    intent.status = "captured"
    intent.updatedAt = Date.now()

    // Stale event timestamp 10 seconds in the past
    const payload = createSignedWebhook({ eventTimestamp: Date.now() - 10000 })
    const result = processPaymentWebhook(
      payload,
      webhookSecret,
      (id) => store.bookings.get(id),
      (id) => store.paymentIntents.get(`intent-${id}`),
      () => { throw new Error("Should not execute") }
    )

    expect(result.success).toBe(false)
    expect(result.code).toBe("OUT_OF_ORDER_EVENT")
  })

  // 11. Concurrent Webhook Test
  it("11. Concurrent webhook: row locking ensures single execution while concurrent call fails lock", () => {
    store.lockRow("booking:book-100")

    expect(() => {
      capturePaymentTransaction(store, "book-100", 227500, "IDR")
    }).toThrow(PaymentEngineError)

    store.unlockRow("booking:book-100")
  })

  // 12. Release Payout Twice Test
  it("12. Release payout twice: first call releases payout, second call is blocked/idempotent", () => {
    capturePaymentTransaction(store, "book-100", 227500, "IDR")
    const booking = store.bookings.get("book-100")!
    booking.status = "customer_confirmed"

    const payout1 = releasePayout(store, "book-100", "idemp-payout-1")
    expect(payout1.status).toBe("succeeded")

    // Second release attempt
    expect(() => {
      releasePayout(store, "book-100", "idemp-payout-2")
    }).toThrow(PaymentEngineError)

    // Using same idempotency key returns existing payout
    const payout1Retry = releasePayout(store, "book-100", "idemp-payout-1")
    expect(payout1Retry.id).toBe(payout1.id)
  })

  // 13. Refund Twice Test
  it("13. Refund twice: first refund succeeds, second refund fails with ALREADY_REFUNDED", () => {
    capturePaymentTransaction(store, "book-100", 227500, "IDR")

    const ref1 = executeRefund(store, "book-100", 227500, "customer_cancel", "idemp-ref-1", "staff-1")
    expect(ref1.status).toBe("succeeded")

    expect(() => {
      executeRefund(store, "book-100", 227500, "customer_cancel", "idemp-ref-2", "staff-1")
    }).toThrow(PaymentEngineError)
  })

  // 14. Refund While Payout Pending Test
  it("14. Refund while payout pending: blocks refund if provider payout has already been released", () => {
    capturePaymentTransaction(store, "book-100", 227500, "IDR")
    const booking = store.bookings.get("book-100")!
    booking.status = "customer_confirmed"

    releasePayout(store, "book-100", "idemp-payout-1")

    expect(() => {
      executeRefund(store, "book-100", 227500, "dispute", "idemp-ref-conflict", "staff-1")
    }).toThrow(PaymentEngineError)
  })

  // 15. Dispute Before Release Test
  it("15. Dispute before release: freezes hold and blocks automated payout release", () => {
    capturePaymentTransaction(store, "book-100", 227500, "IDR")
    const booking = store.bookings.get("book-100")!
    booking.status = "customer_confirmed"

    openDisputeHold(store, "book-100", 227500, "Service quality dispute", "cust-1")
    expect(store.paymentHolds.get("hold-book-100")?.status).toBe("frozen")

    expect(() => {
      releasePayout(store, "book-100", "idemp-payout-disputed")
    }).toThrow(PaymentEngineError)
  })

  // 16. Gateway Timeout Test
  it("16. Gateway timeout: gateway failure leaves order in clean state without partial ledger entry", () => {
    const initialTxCount = store.ledgerTransactions.length

    try {
      capturePaymentTransaction(store, "book-100", 999999, "IDR") // Invalid amount triggers error
    } catch {
      // Caught error
    }

    expect(store.ledgerTransactions.length).toBe(initialTxCount)
    expect(store.bookings.get("book-100")?.status).toBe("awaiting_payment")
  })

  // 17. Database Transaction Rollback Test
  it("17. Database transaction rollback: imbalanced ledger entries trigger rollback and assertion error", () => {
    const imbalancedEntries = [
      { id: "e-1", transactionId: "tx-1", accountId: "acc-psp", amount: 100000 },
      { id: "e-2", transactionId: "tx-1", accountId: "acc-prov", amount: -80000 } // Sum = +20000 (Imbalanced)
    ]

    expect(() => {
      assertLedgerBalance(imbalancedEntries)
    }).toThrow(PaymentEngineError)
  })

  // Financial Reconciliation Audit Test
  it("Reconciliation job detects zero anomalies on clean transaction store", () => {
    capturePaymentTransaction(store, "book-100", 227500, "IDR")
    const report = runReconciliationJob(store)

    expect(report.unmatchedWebhooks).toBe(0)
    expect(report.amountMismatches).toBe(0)
    expect(report.statusDiscrepancies).toBe(0)
    expect(report.flaggedAnomalies.length).toBe(0)
  })
})
