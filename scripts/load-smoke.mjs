import { performance } from "node:perf_hooks"

const target = process.env.TARGET_URL
if (!target) throw new Error("TARGET_URL wajib diisi")
const requests = Number(process.env.LOAD_REQUESTS ?? 100)
const concurrency = Number(process.env.LOAD_CONCURRENCY ?? 20)
const p95Limit = Number(process.env.LOAD_P95_MS ?? 1000)
if (!Number.isInteger(requests) || !Number.isInteger(concurrency) || requests < 1 || requests > 10_000 || concurrency < 1 || concurrency > 200) throw new Error("Profil load di luar batas aman")

let cursor = 0
const results = []
async function worker() {
  while (cursor < requests) {
    cursor += 1
    const started = performance.now()
    try {
      const response = await fetch(target, { headers: { "user-agent": "lumina-release-smoke/1.0" }, signal: AbortSignal.timeout(10_000) })
      results.push({ duration: performance.now() - started, ok: response.ok })
    } catch { results.push({ duration: performance.now() - started, ok: false }) }
  }
}
await Promise.all(Array.from({ length: Math.min(concurrency, requests) }, worker))
const durations = results.map((result) => result.duration).sort((a, b) => a - b)
const p95 = durations[Math.max(0, Math.ceil(durations.length * 0.95) - 1)] ?? Infinity
const errors = results.filter((result) => !result.ok).length
const errorRate = errors / results.length
const report = { target, requests, concurrency, p95Ms: Math.round(p95), errors, errorRate }
console.log(JSON.stringify(report))
if (p95 > p95Limit || errorRate >= 0.01) throw new Error(`Load smoke gagal: p95 ${Math.round(p95)} ms, error ${(errorRate * 100).toFixed(2)}%`)
