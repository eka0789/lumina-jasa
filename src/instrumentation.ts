import { logEvent } from "@/lib/observability/logger"

export function register() {
  logEvent("info", "application.boot")
}
