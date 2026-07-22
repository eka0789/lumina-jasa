import { z } from "zod"
import { executeAIPipeline, AIPipelineResult } from "./pipeline"

export interface FraudSignal {
  type: "velocity" | "device_linkage" | "payment_anomaly" | "text_pattern" | "behavioral"
  score: number
  detail: string
}

export interface FraudDetectionInput {
  userId: string
  bookingId?: string
  textPayload?: string
  signals: FraudSignal[]
}

export const FraudDetectionOutputSchema = z.object({
  riskScore: z.number().min(0).max(100),
  riskBand: z.enum(["low", "medium", "high", "critical"]),
  detectedFlags: z.array(z.string()),
  explanations: z.array(z.string()),
  recommendedAction: z.enum(["allow", "step_up_verification", "queue_manual_review", "hold_payout"]),
  requiresHumanReview: z.boolean(),
  confidence: z.number().min(0).max(1),
  modelVersion: z.string()
})

export type FraudDetectionOutput = z.infer<typeof FraudDetectionOutputSchema>

/**
 * Deterministic rule-based fraud detection fallback.
 */
export function fallbackFraudDetection(input: FraudDetectionInput, _reason: string): FraudDetectionOutput {
  let rawScore = 0
  const detectedFlags: string[] = []
  const explanations: string[] = []

  // Aggregate input signals
  for (const sig of input.signals) {
    rawScore += sig.score * 100
    detectedFlags.push(sig.type)
    explanations.push(sig.detail)
  }

  // Regex text threat check
  if (input.textPayload) {
    if (/(ancam|bunuh|penipuan|nomor kartu|kata sandi|rekening palsu)/i.test(input.textPayload)) {
      rawScore += 40
      detectedFlags.push("suspicious_text_pattern")
      explanations.push("Ditemukan pola kata berisiko tinggi pada teks")
    }
  }

  const riskScore = Math.min(100, Math.round(rawScore))
  let riskBand: "low" | "medium" | "high" | "critical" = "low"
  let recommendedAction: "allow" | "step_up_verification" | "queue_manual_review" | "hold_payout" = "allow"

  if (riskScore >= 80) {
    riskBand = "critical"
    recommendedAction = "hold_payout"
  } else if (riskScore >= 60) {
    riskBand = "high"
    recommendedAction = "queue_manual_review"
  } else if (riskScore >= 30) {
    riskBand = "medium"
    recommendedAction = "step_up_verification"
  }

  return {
    riskScore,
    riskBand,
    detectedFlags,
    explanations,
    recommendedAction,
    requiresHumanReview: riskScore >= 60,
    confidence: 0.88,
    modelVersion: "deterministic-fraud-rules-v1"
  }
}

/**
 * Executes AI Fraud Detection pipeline with explainable risk scoring and human review queue.
 */
export async function executeFraudDetection(
  input: FraudDetectionInput,
  mockProviderCall?: (prompt: string, signal: AbortSignal) => Promise<string>,
  tenantKey = "default"
): Promise<AIPipelineResult<FraudDetectionOutput>> {
  return executeAIPipeline<FraudDetectionInput, FraudDetectionOutput>(
    {
      module: "fraud_detection",
      modelVersion: "fraud-claude-v1",
      promptVersion: "prompt.fraud.v1",
      schemaVersion: "schema.fraud.v1",
      schema: FraudDetectionOutputSchema,
      minConfidenceThreshold: 0.60,
      systemPrompt: "You are an AI Fraud Detection engine. Evaluate risk signals and output explainable risk scores (0-100), risk band, and recommended action. AI cannot ban accounts directly. Output strict JSON.",
      buildUserPrompt: (inData) => JSON.stringify({
        userId: inData.userId,
        bookingId: inData.bookingId,
        textPayload: inData.textPayload,
        signals: inData.signals
      }),
      providerCall: mockProviderCall ?? (async () => {
        throw new Error("Provider not configured")
      }),
      fallback: (inData, reason) => fallbackFraudDetection(inData, reason)
    },
    input,
    tenantKey
  )
}
