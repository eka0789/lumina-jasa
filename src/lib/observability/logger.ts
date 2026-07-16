type LogLevel = "info" | "warn" | "error"

const SENSITIVE_KEY = /authorization|cookie|token|secret|password|document|bank|payment|coordinate|message/i

export function sanitizeContext(context: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(context).map(([key, value]) => [key, SENSITIVE_KEY.test(key) ? "[REDACTED]" : value]),
  )
}

export function logEvent(level: LogLevel, event: string, context: Record<string, unknown> = {}) {
  const record = JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    event,
    service: "lumina-jasa-web",
    environment: process.env.APP_ENV ?? process.env.NODE_ENV ?? "unknown",
    version: process.env.APP_VERSION ?? "local",
    ...sanitizeContext(context),
  })

  if (level === "error") console.error(record)
  else if (level === "warn") console.warn(record)
  else console.info(record)
}
