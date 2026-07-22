import { z } from "zod"
import { executeAIPipeline, AIPipelineResult } from "./pipeline"

export interface PricingInput {
  serviceId?: string
  serviceCategory: string
  jobDescription: string
  catalogBasePrice?: number
}

export const PredictivePricingOutputSchema = z.object({
  currency: z.literal("IDR"),
  p10: z.number().positive(),
  p50: z.number().positive(),
  p90: z.number().positive(),
  durationMinutes: z.object({
    low: z.number().positive(),
    high: z.number().positive()
  }),
  difficulty: z.enum(["easy", "medium", "hard", "complex"]),
  included: z.array(z.string()),
  excluded: z.array(z.string()),
  assumptions: z.array(z.string()),
  confidence: z.number().min(0).max(1),
  modelVersion: z.string()
})

export type PredictivePricingOutput = z.infer<typeof PredictivePricingOutputSchema>

/**
 * Deterministic fallback pricing estimator using catalog baseline statistics.
 */
export function fallbackPricing(input: PricingInput, _reason: string): PredictivePricingOutput {
  const basePrice = input.catalogBasePrice && input.catalogBasePrice > 0 ? input.catalogBasePrice : 250000
  const p50 = Math.round(basePrice)
  const p10 = Math.round(basePrice * 0.70)
  const p90 = Math.round(basePrice * 1.40)

  return {
    currency: "IDR",
    p10,
    p50,
    p90,
    durationMinutes: { low: 45, high: 120 },
    difficulty: "medium",
    included: ["Standar pemeriksaan awal", "Jasa pengerjaan dasar"],
    excluded: ["Suku cadang atau material pengganti"],
    assumptions: ["Lokasi kerja dapat diakses dengan aman"],
    confidence: 0.62,
    modelVersion: "catalog-baseline-rules-v1"
  }
}

/**
 * Enforces catalog bounds on AI pricing predictions.
 */
export function applyCatalogPricingBounds(output: PredictivePricingOutput, catalogBasePrice?: number): PredictivePricingOutput {
  if (!catalogBasePrice || catalogBasePrice <= 0) return output
  const minBound = Math.round(catalogBasePrice * 0.50)
  const maxBound = Math.round(catalogBasePrice * 2.50)

  return {
    ...output,
    p10: Math.max(minBound, output.p10),
    p50: Math.min(Math.max(minBound, output.p50), maxBound),
    p90: Math.min(output.p90, maxBound)
  }
}

/**
 * Executes AI Predictive Pricing pipeline.
 */
export async function executePredictivePricing(
  input: PricingInput,
  mockProviderCall?: (prompt: string, signal: AbortSignal) => Promise<string>,
  userKey = "default"
): Promise<AIPipelineResult<PredictivePricingOutput>> {
  const result = await executeAIPipeline<PricingInput, PredictivePricingOutput>(
    {
      module: "predictive_pricing",
      modelVersion: "pricing-gemini-v1",
      promptVersion: "prompt.pricing.v1",
      schemaVersion: "schema.pricing.v1",
      schema: PredictivePricingOutputSchema,
      minConfidenceThreshold: 0.60,
      systemPrompt: "You are an AI Predictive Pricing engine. Estimate job price intervals (p10, p50, p90 in IDR) and duration. Output strict JSON.",
      buildUserPrompt: (inData) => JSON.stringify({
        serviceCategory: inData.serviceCategory,
        jobDescription: inData.jobDescription,
        catalogBasePrice: inData.catalogBasePrice ?? 250000
      }),
      providerCall: mockProviderCall ?? (async () => {
        throw new Error("Provider not configured")
      }),
      fallback: (inData, reason) => fallbackPricing(inData, reason)
    },
    input,
    userKey
  )

  // Enforce deterministic catalog bounds on price predictions
  const boundedOutput = applyCatalogPricingBounds(result.output, input.catalogBasePrice)
  return { ...result, output: boundedOutput }
}
