import { z } from "zod"
import { executeAIPipeline, AIPipelineResult } from "./pipeline"

export interface OCRInput {
  documentType: "identity_card" | "business_registration"
  documentPath: string
  claimedNik?: string
  claimedName?: string
}

export const OCROutputSchema = z.object({
  documentType: z.enum(["identity_card", "business_registration"]),
  extractedNik: z.string().optional(),
  extractedName: z.string().optional(),
  extractedAddress: z.string().optional(),
  confidence: z.number().min(0).max(1),
  isMatch: z.boolean(),
  mismatchFields: z.array(z.string()),
  requiresHumanReview: z.boolean(),
  modelVersion: z.string()
})

export type OCROutput = z.infer<typeof OCROutputSchema>

/**
 * Fuzzy comparison between claimed text and OCR extracted text.
 */
function compareFields(claimed?: string, extracted?: string): boolean {
  if (!claimed || !extracted) return true
  const normClaimed = claimed.trim().toLowerCase()
  const normExtracted = extracted.trim().toLowerCase()
  return normClaimed === normExtracted || normExtracted.includes(normClaimed) || normClaimed.includes(normExtracted)
}

/**
 * Fallback OCR processor when vendor/model fails.
 */
export function fallbackOCR(input: OCRInput, _reason: string): OCROutput {
  return {
    documentType: input.documentType,
    extractedNik: undefined,
    extractedName: undefined,
    extractedAddress: undefined,
    confidence: 0,
    isMatch: false,
    mismatchFields: ["unprocessed_ocr"],
    requiresHumanReview: true,
    modelVersion: "ocr-fallback-manual-review-v1"
  }
}

/**
 * Cross-compares extracted OCR data with claimed input.
 */
export function crossCompareOCR(extracted: OCROutput, claimedNik?: string, claimedName?: string): OCROutput {
  const mismatchFields: string[] = []

  if (claimedNik && extracted.extractedNik && !compareFields(claimedNik, extracted.extractedNik)) {
    mismatchFields.push("nik")
  }
  if (claimedName && extracted.extractedName && !compareFields(claimedName, extracted.extractedName)) {
    mismatchFields.push("name")
  }

  const isMatch = mismatchFields.length === 0
  const requiresHumanReview = !isMatch || extracted.confidence < 0.80

  return {
    ...extracted,
    isMatch,
    mismatchFields,
    requiresHumanReview
  }
}

/**
 * Executes OCR extraction pipeline with cross-comparison guardrails.
 */
export async function executeOCRProcessing(
  input: OCRInput,
  mockProviderCall?: (prompt: string, signal: AbortSignal) => Promise<string>,
  tenantKey = "default"
): Promise<AIPipelineResult<OCROutput>> {
  const result = await executeAIPipeline<OCRInput, OCROutput>(
    {
      module: "ocr_processing",
      modelVersion: "ocr-vision-v1",
      promptVersion: "prompt.ocr.v1",
      schemaVersion: "schema.ocr.v1",
      schema: OCROutputSchema,
      minConfidenceThreshold: 0.80,
      systemPrompt: "You are an OCR Document Processing engine. Extract structured identity document fields (NIK, Name, Address) and return strict JSON.",
      buildUserPrompt: (inData) => JSON.stringify({
        documentType: inData.documentType,
        documentPath: inData.documentPath,
        claimedNik: inData.claimedNik,
        claimedName: inData.claimedName
      }),
      providerCall: mockProviderCall ?? (async () => {
        throw new Error("Provider not configured")
      }),
      fallback: (inData, reason) => fallbackOCR(inData, reason)
    },
    input,
    tenantKey
  )

  // Apply cross-comparison against claimed input
  const evaluatedOutput = crossCompareOCR(result.output, input.claimedNik, input.claimedName)
  return { ...result, output: evaluatedOutput, requiresHumanReview: evaluatedOutput.requiresHumanReview }
}
