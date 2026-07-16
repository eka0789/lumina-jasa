const target = process.env.TARGET_URL
if (!target) throw new Error("TARGET_URL wajib diisi, misalnya https://staging.example.com")

const response = await fetch(target, { redirect: "manual", signal: AbortSignal.timeout(10_000) })
const required = {
  "content-security-policy": ["default-src 'self'", "frame-ancestors 'none'", "object-src 'none'"],
  "x-content-type-options": ["nosniff"],
  "x-frame-options": ["DENY"],
  "referrer-policy": ["strict-origin-when-cross-origin"],
  "permissions-policy": ["camera=()", "microphone=()"],
  "strict-transport-security": ["max-age="],
  "cross-origin-opener-policy": ["same-origin"],
}

const failures = []
for (const [name, fragments] of Object.entries(required)) {
  const value = response.headers.get(name) ?? ""
  for (const fragment of fragments) if (!value.includes(fragment)) failures.push(`${name} tidak memuat ${fragment}`)
}
if (failures.length) throw new Error(`Security header gate gagal:\n- ${failures.join("\n- ")}`)
console.log(JSON.stringify({ target, status: response.status, gate: "security-headers", result: "pass" }))
