export function normalizeCatalogTerm(value: string) {
  return value.normalize("NFKD").replace(/[\u0300-\u036f]/g, "").toLocaleLowerCase("id-ID").trim()
}

export function matchesCatalogQuery(values: string[], query: string) {
  const term = normalizeCatalogTerm(query)
  if (!term) return true
  return values.some((value) => normalizeCatalogTerm(value).includes(term))
}
