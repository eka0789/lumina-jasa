export const AAL2_PATH_PREFIXES = ["/admin", "/operasional", "/keuangan"] as const

export function requiresAal2(pathname: string) {
  return AAL2_PATH_PREFIXES.some((prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`))
}

export function hasAal2(currentLevel: string | null | undefined) {
  return currentLevel === "aal2"
}
