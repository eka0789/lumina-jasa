export type PaymentStatus =
  | "created"
  | "pending"
  | "captured"
  | "failed"
  | "cancelled"
  | "expired"
  | "refunded"
  | "partially_refunded"

export type OrderStatus =
  | "awaiting_payment"
  | "confirmed"
  | "accepted"
  | "en_route"
  | "in_progress"
  | "provider_completed"
  | "customer_confirmed"
  | "closed"
  | "disputed"
  | "resolved"
  | "cancelled"
  | "expired"

export type HoldStatus =
  | "held"
  | "partially_released"
  | "released"
  | "partially_refunded"
  | "refunded"
  | "frozen"

export type PayoutStatus =
  | "pending"
  | "processing"
  | "succeeded"
  | "failed"
  | "cancelled"

export type RefundStatus =
  | "requested"
  | "approved"
  | "processing"
  | "succeeded"
  | "failed"
  | "rejected"

export type DisputeStatus =
  | "opened"
  | "under_review"
  | "resolved"
  | "dismissed"

export interface BookingOrder {
  id: string
  jobId: string
  customerId: string
  providerId: string
  businessId?: string
  status: OrderStatus
  subtotal: number
  platformFee: number
  taxAmount: number
  totalAmount: number
  currency: string
  expiresAt: number
  version: number
  createdAt: number
  updatedAt: number
}

export interface PaymentIntent {
  id: string
  bookingId: string
  provider: string
  providerReference?: string
  status: PaymentStatus
  amount: number
  currency: string
  expiresAt: number
  version: number
  createdAt: number
  updatedAt: number
}

export interface PaymentHold {
  id: string
  bookingId: string
  paymentIntentId: string
  amount: number
  status: HoldStatus
  version: number
  createdAt: number
  releasedAt?: number
}

export interface Payout {
  id: string
  providerId: string
  bookingId: string
  amount: number
  status: PayoutStatus
  idempotencyKey: string
  processedAt?: number
  createdAt: number
}

export interface Refund {
  id: string
  bookingId: string
  paymentIntentId: string
  disputeId?: string
  amount: number
  reasonCode: string
  status: RefundStatus
  requestedBy: string
  approvedBy?: string
  idempotencyKey: string
  processedAt?: number
  createdAt: number
}

export interface Dispute {
  id: string
  bookingId: string
  openedBy: string
  reason: string
  disputedAmount: number
  status: DisputeStatus
  assignedTo?: string
  resolution?: string
  resolvedRefund?: number
  createdAt: number
  resolvedAt?: number
}

export interface LedgerAccount {
  id: string
  ownerType: "psp" | "provider" | "platform" | "tax" | "customer"
  ownerId: string
  accountType: "asset" | "liability" | "equity" | "revenue" | "expense"
  currency: string
  name: string
  status: "active" | "suspended"
}

export interface LedgerEntry {
  id: string
  transactionId: string
  accountId: string
  amount: number // positive = debit, negative = credit
}

export interface LedgerTransaction {
  id: string
  referenceType: "payment_intent" | "payout" | "refund" | "dispute"
  referenceId: string
  kind: "payment_captured" | "payout_disbursed" | "refund_succeeded" | "fee_accrued"
  description: string
  createdBy: string
  createdAt: number
  entries: LedgerEntry[]
}

export interface WebhookPayload {
  eventId: string
  eventType: "payment.captured" | "payment.failed" | "payment.expired" | "payout.completed" | "refund.processed"
  providerReference: string
  bookingId: string
  amount: number
  currency: string
  eventTimestamp: number
  signature: string
}

export interface ReconciliationResult {
  totalProcessedEvents: number
  successfulMatches: number
  unmatchedWebhooks: number
  amountMismatches: number
  statusDiscrepancies: number
  flaggedAnomalies: string[]
}
