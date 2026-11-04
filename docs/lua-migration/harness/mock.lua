local out = {}
dofile((debug.getinfo(1, "S").source:sub(2):match("(.*/)") or "./") .. "json.lua")
local function rec(kind, ...)
  local a = { ... }
  local p = {}
  for i = 1, select("#", ...) do p[#p + 1] = ser(a[i]) end
  print(kind .. "\t" .. table.concat(p, "\t"))
end
local function dsp(path)
  return setmetatable({}, {
    __index = function(_, k) return dsp(path .. "." .. k) end,
    __call = function(_, ...) return { dsp = path, args = { ... } } end,
  })
end
hl = {
  dsp = dsp("dsp"),
  bind = function(...) rec("bind", ...) end,
  window_rule = function(...) rec("window_rule", ...) end,
  layer_rule = function(...) rec("layer_rule", ...) end,
  workspace_rule = function(...) rec("workspace_rule", ...) end,
  animation = function(...) rec("animation", ...) end,
  curve = function(...) rec("curve", ...) end,
  env = function(...) rec("env", ...) end,
  monitor = function(...) rec("monitor", ...) end,
  device = function(...) rec("device", ...) end,
  config = function(...) rec("config", ...) end,
  exec_cmd = function(...) rec("exec_once", ...) end,
  on = function(ev, fn) rec("on", ev); fn() end,
}
