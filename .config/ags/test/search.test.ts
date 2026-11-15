import { test } from "node:test"
import assert from "node:assert/strict"
import { clampIndex, MAX_RESULTS, nextFilter, normalize, visibleEntries, type Entry } from "../widget/omenu/search.ts"

const app = (title: string): Entry => ({ kind: "app", title, category: "Apps" })
const action = (category: string, title: string, subtitle = ""): Entry => ({ kind: "action", title, category, subtitle })

const APPS = ["Firefox", "Discord", "kitty", "Obsidian", "Spotify", "Kdenlive", "Nautilus"].map(app)
const ACTIONS = [
  action("Estilo", "Nuevo tema", "Abre el creador de temas"),
  action("Sistema", "Reiniciar Waybar", "wbrestart.sh"),
  action("Sistema", "Menú de apagado", "wlogout"),
  action("Instalar", "Actualizar sistema", "yay -Syu en kitty"),
]
const titles = (entries: Entry[]) => entries.map((e) => e.title)

test("normalize quita tildes y mayúsculas", () => {
  assert.equal(normalize("  Menú de Apagado "), "menu de apagado")
})

test("sin búsqueda, Todo muestra 5 apps y luego acciones, hasta el máximo", () => {
  const result = visibleEntries(APPS, ACTIONS, "Todo", "")
  assert.deepEqual(titles(result), ["Firefox", "Discord", "kitty", "Obsidian", "Spotify", "Nuevo tema", "Reiniciar Waybar", "Menú de apagado", "Actualizar sistema"])
  assert.equal(result.length, MAX_RESULTS)
})

test("buscar 'waybar' encuentra la acción aunque esté en otra categoría", () => {
  const result = visibleEntries([], ACTIONS, "Todo", "waybar")
  assert.deepEqual(titles(result), ["Reiniciar Waybar"])
})

test("la búsqueda de acciones ignora tildes y mira el subtítulo", () => {
  assert.deepEqual(titles(visibleEntries([], ACTIONS, "Todo", "menu")), ["Menú de apagado"])
  assert.deepEqual(titles(visibleEntries([], ACTIONS, "Todo", "wlogout")), ["Menú de apagado"])
})

test("con búsqueda, las apps (ya ordenadas por AstalApps) van antes que las acciones", () => {
  const result = visibleEntries([app("kitty")], ACTIONS, "Todo", "kitty")
  assert.deepEqual(titles(result), ["kitty", "Actualizar sistema"])
})

test("el filtro de categoría deja solo sus acciones", () => {
  assert.deepEqual(titles(visibleEntries(APPS, ACTIONS, "Sistema", "")), ["Reiniciar Waybar", "Menú de apagado"])
})

test("el filtro Apps deja solo apps, hasta el máximo", () => {
  const many = Array.from({ length: 20 }, (_, i) => app(`App ${i}`))
  const result = visibleEntries(many, ACTIONS, "Apps", "")
  assert.equal(result.length, MAX_RESULTS)
  assert.ok(result.every((e) => e.kind === "app"))
})

test("nextFilter da la vuelta en ambos sentidos", () => {
  assert.equal(nextFilter("Todo", -1), "Instalar")
  assert.equal(nextFilter("Instalar", 1), "Todo")
  assert.equal(nextFilter("Apps", 1), "Estilo")
})

test("clampIndex mantiene la selección dentro de la lista", () => {
  assert.equal(clampIndex(5, 3), 2)
  assert.equal(clampIndex(-1, 3), 0)
  assert.equal(clampIndex(4, 0), 0)
})
