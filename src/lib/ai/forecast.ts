export type ForecastPoint = { p10: number; p50: number; p90: number; modelVersion: "historical-baseline-v1" }

export function forecastDemand(history: number[], horizonDays = 7): ForecastPoint {
  if (history.length === 0 || horizonDays < 1) return { p10: 0, p50: 0, p90: 0, modelVersion: "historical-baseline-v1" }
  const clean = history.filter((value) => Number.isFinite(value) && value >= 0)
  if (clean.length === 0) return { p10: 0, p50: 0, p90: 0, modelVersion: "historical-baseline-v1" }
  const daily = clean.reduce((sum, value) => sum + value, 0) / clean.length
  const baseline = daily * horizonDays
  return { p10: Math.max(0, Math.round(baseline * 0.65)), p50: Math.round(baseline), p90: Math.round(baseline * 1.45), modelVersion: "historical-baseline-v1" }
}

export function weightedAbsolutePercentageError(actual: number[], predicted: number[]) {
  if (actual.length !== predicted.length || actual.length === 0) return null
  const denominator = actual.reduce((sum, value) => sum + Math.abs(value), 0)
  if (denominator === 0) return null
  return actual.reduce((sum, value, index) => sum + Math.abs(value - (predicted[index] ?? 0)), 0) / denominator
}
