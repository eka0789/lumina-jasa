import { z } from "zod"
import { executeAIPipeline, AIPipelineResult } from "./pipeline"

export interface FaceMatchInput {
  providerId: string
  documentFacePath: string
  selfieFacePath: string
}

export const FaceMatchOutputSchema = z.object({
  similarityScore: z.number().min(0).max(1),
  status: z.enum(["matched", "mismatch", "manual_review"]),
  requiresHumanReview: z.boolean(),
  confidence: z.number().min(0).max(1),
  reason: z.string().optional(),
  modelVersion: z.string()
})

export type FaceMatchOutput = z.infer<typeof FaceMatchOutputSchema>

/**
 * Fallback handler when face matching service fails.
 */
export function fallbackFaceMatch(input: FaceMatchInput, reason: string): FaceMatchOutput {
  return {
    similarityScore: 0,
    status: "manual_review",
    requiresHumanReview: true,
    confidence: 0,
    reason: `Face matching fallback: ${reason}`,
    modelVersion: "facematch-fallback-v1"
  }
}

/**
 * Evaluates similarity score against high/medium risk thresholds.
 */
export function evaluateFaceMatchThresholds(rawOutput: FaceMatchOutput): FaceMatchOutput {
  const score = rawOutput.similarityScore

  if (score >= 0.85) {
    return { ...rawOutput, status: "matched", requiresHumanReview: false }
  } else if (score >= 0.70) {
    return {
      ...rawOutput,
      status: "manual_review",
      requiresHumanReview: true,
      reason: "Borderline facial similarity score (0.70 - 0.84), sent for human verification"
    }
  } else {
    return {
      ...rawOutput,
      status: "mismatch",
      requiresHumanReview: true,
      reason: "Facial similarity score below 0.70 threshold"
    }
  }
}

/**
 * Executes Face Matching AI pipeline.
 */
export async function executeFaceMatch(
  input: FaceMatchInput,
  mockProviderCall?: (prompt: string, signal: AbortSignal) => Promise<string>,
  tenantKey = "default"
): Promise<AIPipelineResult<FaceMatchOutput>> {
  const result = await executeAIPipeline<FaceMatchInput, FaceMatchOutput>(
    {
      module: "face_matching",
      modelVersion: "facematch-vision-v1",
      promptVersion: "prompt.facematch.v1",
      schemaVersion: "schema.facematch.v1",
      schema: FaceMatchOutputSchema,
      minConfidenceThreshold: 0.80,
      systemPrompt: "You are an AI Face Matching engine. Compare identity document face photo with selfie image and return similarity score (0-1) and status. Output strict JSON.",
      buildUserPrompt: (inData) => JSON.stringify({
        providerId: inData.providerId,
        documentFacePath: inData.documentFacePath,
        selfieFacePath: inData.selfieFacePath
      }),
      providerCall: mockProviderCall ?? (async () => {
        throw new Error("Provider not configured")
      }),
      fallback: (inData, reason) => fallbackFaceMatch(inData, reason)
    },
    input,
    tenantKey
  )

  const evaluatedOutput = evaluateFaceMatchThresholds(result.output)
  return { ...result, output: evaluatedOutput, requiresHumanReview: evaluatedOutput.requiresHumanReview }
}
