import { z } from "zod"
import { executeAIPipeline, AIPipelineResult } from "./pipeline"
import { rankProviders, type RankableProvider } from "./ranking"

export interface ProviderCandidate extends RankableProvider {
  status: "active" | "suspended" | "pending"
  verificationStatus: "verified" | "pending" | "rejected"
  isBlacklisted?: boolean
}

export interface MatchmakingInput {
  jobCategory: string
  jobDescription: string
  jobArea: string
  candidates: ProviderCandidate[]
}

export const MatchmakingOutputSchema = z.object({
  rankedProviderIds: z.array(z.string()),
  explanations: z.record(z.string(), z.array(z.string())),
  confidence: z.number().min(0).max(1),
  modelVersion: z.string()
})

export type MatchmakingOutput = z.infer<typeof MatchmakingOutputSchema>

/**
 * Hard filters candidates before AI ranking.
 */
export function filterEligibleProviders(candidates: ProviderCandidate[], area: string): ProviderCandidate[] {
  return candidates.filter((p) => {
    if (p.status !== "active") return false
    if (p.verificationStatus !== "verified") return false
    if (p.isBlacklisted) return false
    if (area && p.areas.length > 0 && !p.areas.some(a => a.toLowerCase().includes(area.toLowerCase()))) return false
    return true
  })
}

/**
 * Deterministic fallback ranker when AI provider is unavailable.
 */
export function fallbackMatchmaking(input: MatchmakingInput, _reason: string): MatchmakingOutput {
  const eligible = filterEligibleProviders(input.candidates, input.jobArea)
  const ranked = rankProviders(eligible, input.jobDescription, input.jobArea)
  const explanations: Record<string, string[]> = {}
  ranked.forEach(r => {
    explanations[r.provider.id] = r.reasons
  })
  return {
    rankedProviderIds: ranked.map(r => r.provider.id),
    explanations,
    confidence: 0.85,
    modelVersion: "deterministic-bayesian-v1"
  }
}

/**
 * Executes AI Smart Matchmaking with hard filters and fallback governance.
 */
export async function executeMatchmaking(
  input: MatchmakingInput,
  mockProviderCall?: (prompt: string, signal: AbortSignal) => Promise<string>,
  tenantKey = "default"
): Promise<AIPipelineResult<MatchmakingOutput>> {
  const eligibleCandidates = filterEligibleProviders(input.candidates, input.jobArea)

  return executeAIPipeline<MatchmakingInput, MatchmakingOutput>(
    {
      module: "smart_matchmaking",
      modelVersion: "matchmaking-gpt4o-v1",
      promptVersion: "prompt.matchmaking.v1",
      schemaVersion: "schema.matchmaking.v1",
      schema: MatchmakingOutputSchema,
      minConfidenceThreshold: 0.60,
      systemPrompt: "You are an AI Smart Matchmaking engine. Rank the provided eligible service providers according to customer job requirements. Output JSON only matching the strict schema.",
      buildUserPrompt: (inData) => JSON.stringify({
        jobCategory: inData.jobCategory,
        jobDescription: inData.jobDescription,
        jobArea: inData.jobArea,
        eligibleCandidates: eligibleCandidates.map(c => ({ id: c.id, name: c.name, rating: c.rating, reviewCount: c.reviewCount, completedJobs: c.completedJobs, responseRate: c.responseRate }))
      }),
      providerCall: mockProviderCall ?? (async () => {
        throw new Error("Provider not configured")
      }),
      fallback: (inData, reason) => fallbackMatchmaking({ ...inData, candidates: eligibleCandidates }, reason)
    },
    { ...input, candidates: eligibleCandidates },
    tenantKey
  )
}
