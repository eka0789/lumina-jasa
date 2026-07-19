import { z } from "zod"
import { createHmac } from "crypto"

export interface LivenessCallbackPayload {
  sessionId: string
  providerId: string
  livenessScore: number
  isRealPerson: boolean
  timestamp: number
  nonce: string
  signature: string
}

export const LivenessVerificationSchema = z.object({
  sessionId: z.string(),
  providerId: z.string(),
  livenessScore: z.number().min(0).max(1),
  isRealPerson: z.boolean(),
  signatureVerified: z.boolean(),
  timestampFresh: z.boolean(),
  isValid: z.boolean(),
  requiresHumanReview: z.boolean(),
  reason: z.string().optional()
})

export type LivenessVerificationOutput = z.infer<typeof LivenessVerificationSchema>

/**
 * Server-side HMAC-SHA256 signature verification for vendor liveness webhooks.
 */
export function verifyLivenessSignature(
  payload: Omit<LivenessCallbackPayload, "signature">,
  signature: string,
  secret: string
): boolean {
  if (!signature || !secret) return false
  const rawBody = `${payload.sessionId}:${payload.providerId}:${payload.livenessScore}:${payload.isRealPerson}:${payload.timestamp}:${payload.nonce}`
  const expectedSig = createHmac("sha256", secret).update(rawBody).digest("hex")
  return expectedSig === signature
}

/**
 * Validates timestamp freshness (5-minute maximum drift).
 */
export function isTimestampFresh(timestampMs: number, maxDriftMs = 300000): boolean {
  const diff = Math.abs(Date.now() - timestampMs)
  return diff <= maxDriftMs
}

/**
 * Fallback handler when liveness callback fails server verification.
 */
export function fallbackLivenessVerification(payload: Partial<LivenessCallbackPayload>, reason: string): LivenessVerificationOutput {
  return {
    sessionId: payload.sessionId ?? "unknown",
    providerId: payload.providerId ?? "unknown",
    livenessScore: 0,
    isRealPerson: false,
    signatureVerified: false,
    timestampFresh: false,
    isValid: false,
    requiresHumanReview: true,
    reason
  }
}

/**
 * Verifies vendor liveness callback on server.
 */
export function verifyLivenessCallback(
  payload: LivenessCallbackPayload,
  webhookSecret: string
): LivenessVerificationOutput {
  const { signature, ...restPayload } = payload

  const signatureVerified = verifyLivenessSignature(restPayload, signature, webhookSecret)
  const timestampFresh = isTimestampFresh(payload.timestamp)

  const isValid = signatureVerified && timestampFresh && payload.isRealPerson && payload.livenessScore >= 0.85
  const requiresHumanReview = !isValid || payload.livenessScore < 0.90

  let reason: string | undefined
  if (!signatureVerified) reason = "HMAC signature verification failed"
  else if (!timestampFresh) reason = "Callback timestamp expired (replay attempt)"
  else if (!payload.isRealPerson) reason = "Vendor flagged potential spoofing/fake attempt"
  else if (payload.livenessScore < 0.85) reason = "Liveness score below threshold (0.85)"

  return LivenessVerificationSchema.parse({
    sessionId: payload.sessionId,
    providerId: payload.providerId,
    livenessScore: payload.livenessScore,
    isRealPerson: payload.isRealPerson,
    signatureVerified,
    timestampFresh,
    isValid,
    requiresHumanReview,
    reason
  })
}
