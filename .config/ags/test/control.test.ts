import { test } from "node:test"
import assert from "node:assert/strict"
import {
  groupByApp,
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

test("groupByApp agrupa respetando el orden de aparición", () => {
  const items = [
    { id: 1, appName: "Discord" },
    { id: 2, appName: "Spotify" },
    { id: 3, appName: "Discord" },
    { id: 4, appName: "" },
  ]
  const groups = groupByApp(items)
  assert.deepEqual(groups.map((g) => [g.app, g.items.map((i) => i.id)]), [
    ["Discord", [1, 3]],
    ["Spotify", [2]],
    ["Notificación", [4]],
  ])
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
