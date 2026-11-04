function ser(v)
  local t = type(v)
  if t == "table" then
    local n = #v
    local isarr = n > 0
    for k in pairs(v) do if type(k) ~= "number" then isarr = false end end
    local parts = {}
    if isarr then
      for i = 1, n do parts[#parts + 1] = ser(v[i]) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = tostring(k) end
    table.sort(keys)
    for _, k in ipairs(keys) do parts[#parts + 1] = string.format("%q", k) .. ":" .. ser(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif t == "string" then return string.format("%q", v)
  elseif t == "nil" then return "null"
  else return tostring(v) end
end
