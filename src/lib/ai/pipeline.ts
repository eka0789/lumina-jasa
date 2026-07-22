import { z } from "zod"
import { createHash } from "crypto"

export interface AIPipelineConfig<TInput, TOutput> {
  module: string
  modelVersion: string
  promptVersion: string
  schemaVersion: string
  schema: z.ZodSchema<TOutput>
  timeoutMs?: number
  maxRetries?: number
  minConfidenceThreshold?: number
  rateLimitMaxPerMin?: number
  systemPrompt: string
  buildUserPrompt: (input: TInput) => string
  providerCall: (prompt: string, signal: AbortSignal) => Promise<string>
  fallback: (input: TInput, reason: string) => TOutput
}

export interface AIPipelineResult<TOutput> {
  output: TOutput
  status: "succeeded" | "fallback" | "rejected"
  mode: "provider" | "fallback"
  inputHash: string
  latencyMs: number
  requiresHumanReview: boolean
  confidence: number
  reason?: string
}

// In-memory rate limiter per user/tenant key
const rateLimitMap = new Map<string, { count: number; resetAt: number }>()

// In-memory deduplication cache
const responseCache = new Map<string, { output: any; cachedAt: number }>()

/**
 * Redacts PII (NIK, card numbers, email, phone numbers, API keys) from raw text.
 */
export function sanitizeInputText(rawText: string): string {
  if (!rawText) return ""
  return rawText
    // Redact 16-digit NIK
    .replace(/\b\d{16}\b/g, "[REDACTED_NIK]")
    // Redact 13-19 digit Credit/Debit Card Numbers
    .replace(/\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{1,7}\b/g, "[REDACTED_CARD]")
    // Redact Email addresses
    .replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/g, "[REDACTED_EMAIL]")
    // Redact Indonesian phone numbers (+62 / 08...)
    .replace(/\b(\+62|62|0)8[1-9][0-9]{6,10}\b/g, "[REDACTED_PHONE]")
    // Neutralize injection keywords
    .replace(/(ignore previous instructions|you are now admin|system:|override rules|set user_role|set payment_status)/gi, "[REDACTED_INJECTION]")
}

/**
 * Checks sliding window rate limit.
 */
function checkRateLimit(key: string, limitPerMin: number): boolean {
  const now = Date.now()
  const record = rateLimitMap.get(key)
  if (!record || now > record.resetAt) {
    rateLimitMap.set(key, { count: 1, resetAt: now + 60000 })
    return true
  }
  if (record.count >= limitPerMin) return false
  record.count++
  return true
}

/**
 * Asserts that AI output does NOT dictate sensitive system authority.
 */
function assertGovernanceRules(output: any): void {
  if (typeof output !== "object" || output === null) return
  const forbiddenKeys = ["role", "user_role", "ownership", "payment_status", "payout_status", "refund_status", "authorization"]
  for (const key of forbiddenKeys) {
    if (key in output && output[key] !== undefined) {
      throw new Error(`Governance Violation: AI output attempts to specify restricted authority field '${key}'`)
    }
  }
}

/**
 * Executes AI call through strict governance pipeline.
 */
export async function executeAIPipeline<TInput, TOutput>(
  config: AIPipelineConfig<TInput, TOutput>,
  input: TInput,
  userOrTenantKey = "default"
): Promise<AIPipelineResult<TOutput>> {
  const startTime = Date.now()
  const timeoutMs = config.timeoutMs ?? 5000
  const maxRetries = config.maxRetries ?? 1
  const minConfidence = config.minConfidenceThreshold ?? 0.60
  const rateLimit = config.rateLimitMaxPerMin ?? 30

  // 1. Preprocessing & Input Sanitization
  const userPromptRaw = config.buildUserPrompt(input)
  const sanitizedUserPrompt = sanitizeInputText(userPromptRaw)

  // 2. Input Length Boundary Check (Max 10,000 chars)
  if (sanitizedUserPrompt.length > 10000) {
    const latencyMs = Date.now() - startTime
    const fallbackOutput = config.fallback(input, "Oversized input payload (>10000 chars)")
    return {
      output: fallbackOutput,
      status: "rejected",
      mode: "fallback",
      inputHash: createHash("sha256").update(sanitizedUserPrompt).digest("hex"),
      latencyMs,
      requiresHumanReview: true,
      confidence: 0,
      reason: "Oversized input payload"
    }
  }

  // 3. Rate Limit Check
  if (!checkRateLimit(userOrTenantKey, rateLimit)) {
    const latencyMs = Date.now() - startTime
    const fallbackOutput = config.fallback(input, "Rate limit exceeded")
    return {
      output: fallbackOutput,
      status: "rejected",
      mode: "fallback",
      inputHash: createHash("sha256").update(sanitizedUserPrompt).digest("hex"),
      latencyMs,
      requiresHumanReview: true,
      confidence: 0,
      reason: "Rate limit exceeded"
    }
  }

  // 4. Prompt Construction with Strict XML Isolation
  const fullPrompt = `${config.systemPrompt}\n\n<user_input>\n${sanitizedUserPrompt}\n</user_input>`
  const inputHash = createHash("sha256").update(`${config.modelVersion}:${config.promptVersion}:${fullPrompt}`).digest("hex")

  // 5. Deduplication Cache Check
  const cached = responseCache.get(inputHash)
  if (cached && (Date.now() - cached.cachedAt < 300000)) {
    const latencyMs = Date.now() - startTime
    return {
      output: cached.output,
      status: "succeeded",
      mode: "provider",
      inputHash,
      latencyMs,
      requiresHumanReview: false,
      confidence: (cached.output as any)?.confidence ?? 1.0,
      reason: "Cached response"
    }
  }

  // 6. Provider Call with Timeout & Bounded Exponential Retry
  let lastError: Error | null = null
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    const controller = new AbortController()
    const timer = setTimeout(() => controller.abort(), timeoutMs)

    try {
      if (attempt > 0) {
        // Exponential backoff delay (100ms, 200ms) with jitter
        const delay = Math.pow(2, attempt - 1) * 100 + Math.random() * 50
        await new Promise((resolve) => setTimeout(resolve, delay))
      }

      const rawResponse = await config.providerCall(fullPrompt, controller.signal)
      clearTimeout(timer)

      // 7. Output Parsing (JSON)
      let parsedJson: unknown
      try {
        parsedJson = JSON.parse(rawResponse)
      } catch {
        throw new Error("Invalid JSON returned by provider")
      }

      // 8. Strict Schema Validation (Zod)
      const validatedOutput = config.schema.parse(parsedJson)

      // 9. Governance Rule Assertion
      assertGovernanceRules(validatedOutput)

      // 10. Confidence Evaluation
      const confidence = (validatedOutput as any)?.confidence ?? 1.0
      const requiresHumanReview = confidence < minConfidence

      const latencyMs = Date.now() - startTime

      if (!requiresHumanReview) {
        responseCache.set(inputHash, { output: validatedOutput, cachedAt: Date.now() })
      }

      return {
        output: validatedOutput,
        status: requiresHumanReview ? "fallback" : "succeeded",
        mode: "provider",
        inputHash,
        latencyMs,
        requiresHumanReview,
        confidence,
        reason: requiresHumanReview ? "Low confidence response flagged for human review" : undefined
      }

    } catch (err: any) {
      clearTimeout(timer)
      lastError = err

      // Non-retryable errors: Zod schema mismatch, Governance violation, Invalid JSON
      if (err instanceof z.ZodError || err.message?.includes("Governance Violation") || err.message?.includes("Invalid JSON")) {
        break
      }
    }
  }

  // 11. Fallback Path Execution
  const latencyMs = Date.now() - startTime
  const reason = lastError?.name === "AbortError" ? "Provider request timed out" : lastError?.message || "Provider call failed"
  const fallbackOutput = config.fallback(input, reason)

  return {
    output: fallbackOutput,
    status: "fallback",
    mode: "fallback",
    inputHash,
    latencyMs,
    requiresHumanReview: true,
    confidence: (fallbackOutput as any)?.confidence ?? 0,
    reason
  }
}
