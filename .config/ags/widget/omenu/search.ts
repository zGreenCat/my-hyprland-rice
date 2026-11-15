export type EntryKind = "app" | "action"

export interface Entry {
  kind: EntryKind
  title: string
  category: string
  subtitle?: string
}

export const FILTERS = ["Todo", "Apps", "Estilo", "Aprender", "Sistema", "Instalar"] as const
export type Filter = (typeof FILTERS)[number]

export const MAX_RESULTS = 9
const IDLE_APPS = 5

export function normalize(text: string): string {
  return text.normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase().trim()
}

function matches(entry: Entry, query: string): boolean {
  const q = normalize(query)
  if (!q) return true
  return [entry.title, entry.subtitle ?? "", entry.category].some((field) => normalize(field).includes(q))
}

/**
 * `rankedApps` ya viene ordenada por AstalApps (búsqueda difusa y frecuencia de uso);
 * aquí solo se filtran las acciones y se arma la lista final: apps primero, luego acciones.
 */
export function visibleEntries<T extends Entry>(
  rankedApps: T[],
  actions: T[],
  filter: Filter,
  query: string,
  limit = MAX_RESULTS,
): T[] {
  if (filter === "Apps") return rankedApps.slice(0, limit)

  const filteredActions = actions.filter(
    (action) => (filter === "Todo" || action.category === filter) && matches(action, query),
  )
  if (filter !== "Todo") return filteredActions.slice(0, limit)

  const appCount = normalize(query) ? limit : IDLE_APPS
  const apps = rankedApps.slice(0, appCount)
  return [...apps, ...filteredActions].slice(0, limit)
}

export function nextFilter(current: Filter, step: 1 | -1): Filter {
  const i = FILTERS.indexOf(current)
  return FILTERS[(i + step + FILTERS.length) % FILTERS.length]
}

export function clampIndex(index: number, length: number): number {
  if (length === 0) return 0
  return Math.max(0, Math.min(length - 1, index))
}
