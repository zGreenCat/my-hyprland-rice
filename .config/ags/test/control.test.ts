import { test } from "node:test"
import assert from "node:assert/strict"
import {
  appColorIndex,
  initial,
  LIMITS,
  plainText,
  timeLabel,
  truncate,
  parseBluetoothPowered,
  parseBrightness,
  parseConnectedDevice,
  parsePlayer,
  parseWifi,
  timeAgo,
} from "../widget/control/parse.ts"
import { monthGrid, monthTitle, shiftMonth } from "../widget/calendar/month.ts"

test("parseWifi toma la red activa y desescapa ':'", () => {
  assert.deepEqual(parseWifi("enabled\n", "no:Vecino\nyes:Casa\\:5G\n"), { enabled: true, ssid: "Casa:5G" })
})

test("parseWifi sin red activa o con Wi-Fi apagado no inventa nombre", () => {
  assert.deepEqual(parseWifi("enabled", "no:Vecino"), { enabled: true, ssid: null })
  assert.deepEqual(parseWifi("disabled", "yes:Casa"), { enabled: false, ssid: null })
})

test("parseBrightness lee el porcentaje de brightnessctl -m", () => {
  assert.equal(parseBrightness("intel_backlight,backlight,12000,50%,24000\n"), 50)
  assert.equal(parseBrightness(""), null)
})

test("parseBluetoothPowered", () => {
  assert.equal(parseBluetoothPowered("Controller AA:BB\n\tPowered: yes\n\tDiscoverable: no"), true)
  assert.equal(parseBluetoothPowered("Controller AA:BB\n\tPowered: no"), false)
  assert.equal(parseBluetoothPowered("No default controller available"), false)
})

test("parseConnectedDevice devuelve el nombre completo del primer dispositivo", () => {
  assert.equal(parseConnectedDevice("Device 11:22:33:44:55:66 Audífonos WH-1000XM4\n"), "Audífonos WH-1000XM4")
  assert.equal(parseConnectedDevice(""), null)
})

test("parsePlayer acepta Playing/Paused con título y descarta lo demás", () => {
  assert.deepEqual(parsePlayer("Playing\tAruarian Dance\tNujabes\tspotify\n"), {
    status: "Playing",
    title: "Aruarian Dance",
    artist: "Nujabes",
    player: "spotify",
  })
  assert.equal(parsePlayer("Stopped\tAlgo\tAlguien\tspotify"), null)
  assert.equal(parsePlayer("Playing\t\t\tfirefox"), null)
  assert.equal(parsePlayer(""), null)
})

test("timeAgo", () => {
  const now = 1_800_000_000_000
  const s = now / 1000
  assert.equal(timeAgo(s - 10, now), "ahora")
  assert.equal(timeAgo(s - 600, now), "10 min")
  assert.equal(timeAgo(s - 7200, now), "2 h")
  assert.equal(timeAgo(s - 3 * 86400, now), "3 d")
})

test("monthGrid: noviembre 2026 empieza en domingo, así que lleva 6 días de relleno", () => {
  const cells = monthGrid({ year: 2026, month: 10 }, new Date(2026, 10, 14))
  assert.equal(cells.length % 7, 0)
  assert.deepEqual(cells.slice(0, 7).map((c) => [c.day, c.inMonth]), [
    [26, false], [27, false], [28, false], [29, false], [30, false], [31, false], [1, true],
  ])
  const today = cells.filter((c) => c.today)
  assert.equal(today.length, 1)
  assert.equal(today[0].day, 14)
  assert.equal(today[0].weekend, true)
})

test("monthGrid: febrero bisiesto tiene 29 días", () => {
  const cells = monthGrid({ year: 2028, month: 1 }, new Date(2026, 0, 1))
  assert.equal(cells.filter((c) => c.inMonth).length, 29)
  assert.equal(cells.some((c) => c.today), false)
})

test("shiftMonth cruza años en ambos sentidos", () => {
  assert.deepEqual(shiftMonth({ year: 2026, month: 0 }, -1), { year: 2025, month: 11 })
  assert.deepEqual(shiftMonth({ year: 2026, month: 11 }, 1), { year: 2027, month: 0 })
  assert.equal(monthTitle({ year: 2026, month: 10 }), "Noviembre 2026")
})

test("plainText quita HTML de Chromium y convierte entidades", () => {
  const body = '<a href="https://cl.pinterest.com/">cl.pinterest.com</a>\n\nIdeas basadas en tu gusto <img src="file:///tmp/x.png" alt=""/>'
  assert.equal(plainText(body), "cl.pinterest.com Ideas basadas en tu gusto")
  assert.equal(plainText("Tom &amp; Jerry &lt;3 &#39;hola&#x27; &nbsp;fin"), "Tom & Jerry <3 'hola' fin")
  assert.equal(plainText("línea 1<br>línea 2"), "línea 1 línea 2")
})

test("truncate respeta el límite y corta en una palabra", () => {
  const text = "¿Subiste el tema charigod? Quiero probarlo esta noche con el portfolio"
  const short = truncate(text, LIMITS.islandBody)
  assert.ok([...short].length <= LIMITS.islandBody)
  assert.ok(short.endsWith("…"))
  assert.equal(short, "¿Subiste el tema charigod? Quiero probarlo esta noche con…")
  assert.equal(truncate("corto", 32), "corto")
})

test("truncate corta en seco si no hay espacios útiles", () => {
  assert.equal(truncate("~/Pictures/Screenshots/2026-11-14_23-31.png", 20), "~/Pictures/Screensh…")
})

test("truncate cuenta emoji como un carácter", () => {
  assert.equal(truncate("🎉🎉🎉🎉", 3), "🎉🎉…")
})

test("timeLabel: hora hoy, ayer, o fecha", () => {
  const now = new Date(2026, 10, 15, 0, 30)
  const at = (d: Date) => d.getTime() / 1000
  assert.equal(timeLabel(at(new Date(2026, 10, 15, 0, 5)), now), "00:05")
  assert.equal(timeLabel(at(new Date(2026, 10, 14, 23, 52)), now), "ayer")
  assert.equal(timeLabel(at(new Date(2026, 10, 13, 9, 0)), now), "13/11")
})

test("appColorIndex es estable y está en rango", () => {
  assert.equal(appColorIndex("Discord"), appColorIndex("discord"))
  for (const app of ["Discord", "Spotify", "Claude Code", "Chromium", ""]) {
    const i = appColorIndex(app)
    assert.ok(i >= 0 && i < 8)
  }
})

test("initial", () => {
  assert.equal(initial("discord"), "D")
  assert.equal(initial("  ñandú"), "Ñ")
  assert.equal(initial(""), "?")
})
