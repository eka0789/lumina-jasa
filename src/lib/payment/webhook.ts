import { createHmac } from "crypto"
import { WebhookPayload, BookingOrder, PaymentIntent } from "./types"

export interface WebhookProcessingResult {
  success: boolean
  processed: boolean
  code: "SUCCESS" | "DUPLICATE_EVENT" | "INVALID_SIGNATURE" | "EXPIRED_TIMESTAMP" | "WRONG_AMOUNT" | "WRONG_CURRENCY" | "OUT_OF_ORDER_EVENT" | "UNKNOWN_ORDER" | "ORDER_EXPIRED" | "ORDER_CANCELLED" | "ALREADY_PAID"
  message: string
  intent?: PaymentIntent
}

// In-memory processed event registry
const processedEvents = new Map<string, { processedAt: number; result: WebhookProcessingResult }>()

/**
 * Computes HMAC-SHA256 signature for payment webhook payload.
 */
export function computeWebhookSignature(
  payload: Omit<WebhookPayload, "signature">,
  secret: string
): string {
  const rawData = `${payload.eventId}:${payload.bookingId}:${payload.amount}:${payload.currency}:${payload.eventTimestamp}`
  return createHmac("sha256", secret).update(rawData).digest("hex")
}

/**
 * Verifies HMAC-SHA256 webhook signature.
 */
export function verifyWebhookSignature(payload: WebhookPayload, secret: string): boolean {
  if (!payload.signature || !secret) return false
  const { signature, ...rest } = payload
  const expectedSignature = computeWebhookSignature(rest, secret)
  return expectedSignature === signature
}

/**
 * Verifies webhook event timestamp freshness (max 300 seconds drift).
 */
export function verifyTimestampFreshness(eventTimestampMs: number, maxDriftMs = 300000): boolean {
  const currentMs = Date.now()
  return Math.abs(currentMs - eventTimestampMs) <= maxDriftMs
}

/**
 * Processes payment webhook safely with full governance checks.
 */
export function processPaymentWebhook(
  payload: WebhookPayload,
  webhookSecret: string,
  getBookingFn: (bookingId: string) => BookingOrder | undefined,
  getPaymentIntentFn: (bookingId: string) => PaymentIntent | undefined,
  onPaymentSuccessFn: (booking: BookingOrder, intent: PaymentIntent, payload: WebhookPayload) => PaymentIntent
): WebhookProcessingResult {
  // 1. Signature Verification
  if (!verifyWebhookSignature(payload, webhookSecret)) {
    return {
      success: false,
      processed: false,
      code: "INVALID_SIGNATURE",
      message: "Webhook HMAC signature verification failed"
    }
  }

  // 2. Duplicate Event Check (Idempotency Key / Unique external_event_id)
  const existingRecord = processedEvents.get(payload.eventId)
  if (existingRecord) {
    return {
      ...existingRecord.result,
      processed: false,
      code: "DUPLICATE_EVENT",
      message: "Webhook event was already processed previously (Idempotent response)"
    }
  }

  // 3. Timestamp Freshness Check
  if (!verifyTimestampFreshness(payload.eventTimestamp)) {
    const res: WebhookProcessingResult = {
      success: false,
      processed: false,
      code: "EXPIRED_TIMESTAMP",
      message: "Webhook timestamp drift exceeds 300 seconds security window"
    }
    processedEvents.set(payload.eventId, { processedAt: Date.now(), result: res })
    return res
  }

  // 4. Currency Check
  if (payload.currency !== "IDR") {
    const res: WebhookProcessingResult = {
      success: false,
      processed: false,
      code: "WRONG_CURRENCY",
      message: `Invalid currency '${payload.currency}'. Platform only accepts IDR`
    }
    processedEvents.set(payload.eventId, { processedAt: Date.now(), result: res })
    return res
  }

  // 5. Lookup Booking Order
  const booking = getBookingFn(payload.bookingId)
  if (!booking) {
    const res: WebhookProcessingResult = {
      success: false,
      processed: false,
      code: "UNKNOWN_ORDER",
      message: `Booking order '${payload.bookingId}' not found`
    }
    processedEvents.set(payload.eventId, { processedAt: Date.now(), result: res })
    return res
  }

  // 6. Server-Side Amount Verification
  if (payload.amount !== booking.totalAmount) {
    const res: WebhookProcessingResult = {
      success: false,
      processed: false,
      code: "WRONG_AMOUNT",
      message: `Webhook amount (${payload.amount}) does not match server booking amount (${booking.totalAmount})`
    }
    processedEvents.set(payload.eventId, { processedAt: Date.now(), result: res })
    return res
  }

  // 7. Lookup Payment Intent
  const intent = getPaymentIntentFn(payload.bookingId)

  // 8. Order State Guards
  if (booking.status === "cancelled") {
    const res: WebhookProcessingResult = {
      success: false,
      processed: false,
      code: "ORDER_CANCELLED",
      message: "Order has already been cancelled"
    }
    processedEvents.set(payload.eventId, { processedAt: Date.now(), result: res })
    return res
  }

  if (booking.status === "expired" || booking.expiresAt <= payload.eventTimestamp) {
    const res: WebhookProcessingResult = {
      success: false,
      processed: false,
      code: "ORDER_EXPIRED",
      message: "Order payment window has expired"
    }
    processedEvents.set(payload.eventId, { processedAt: Date.now(), result: res })
    return res
  }

  // 9. Out-of-Order Sequence Check (Check before ALREADY_PAID)
  if (intent && intent.updatedAt > payload.eventTimestamp) {
    const res: WebhookProcessingResult = {
      success: false,
      processed: false,
      code: "OUT_OF_ORDER_EVENT",
      message: "Out-of-order webhook detected: Event timestamp is older than current intent state"
    }
    processedEvents.set(payload.eventId, { processedAt: Date.now(), result: res })
    return res
  }

  if (booking.status === "confirmed" || (intent && intent.status === "captured")) {
    const res: WebhookProcessingResult = {
      success: true,
      processed: false,
      code: "ALREADY_PAID",
      message: "Order is already confirmed and paid",
      intent
    }
    processedEvents.set(payload.eventId, { processedAt: Date.now(), result: res })
    return res
  }

  // 10. Execute Payment Capture Function
  const updatedIntent = onPaymentSuccessFn(booking, intent!, payload)

  const finalRes: WebhookProcessingResult = {
    success: true,
    processed: true,
    code: "SUCCESS",
    message: "Payment captured successfully via webhook",
    intent: updatedIntent
  }

  processedEvents.set(payload.eventId, { processedAt: Date.now(), result: finalRes })
  return finalRes
}
