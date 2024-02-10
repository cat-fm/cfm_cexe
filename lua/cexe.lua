local originalFunctions = {}
local function detourFunction(fOriginal, fDetour)
  originalFunctions[fDetour] = fOriginal
  return fDetour
end

debug.getinfo = detourFunction(debug.getinfo, function(funcOrLevel, fields)
  if type(funcOrLevel) == "number" and funcOrLevel == 0 then
    local info = originalFunctions[debug.getinfo](funcOrLevel, fields)
    info.func = originalFunctions[debug.getinfo]

    return info
  end

  if originalFunctions[funcOrLevel] ~= nil then
    return originalFunctions[debug.getinfo](originalFunctions[funcOrLevel], fields)
  end

  return originalFunctions[debug.getinfo](funcOrLevel, fields)
end)

debug.getlocal = detourFunction(debug.getlocal, function(level, index)
  if originalFunctions[level] ~= nil then
    return originalFunctions[debug.getlocal](originalFunctions[level], index)
  end

  return originalFunctions[debug.getlocal](level, index)
end)

jit.util.funcbc = detourFunction(jit.util.funcbc, function(func, pos)
  if originalFunctions[func] ~= nil then
    return originalFunctions[jit.util.funcbc](originalFunctions[func], pos)
  end

  return originalFunctions[jit.util.funcbc](func, pos)
end)

jit.util.funcinfo = detourFunction(jit.util.funcinfo, function(func, pos)
  if originalFunctions[func] ~= nil then
    return originalFunctions[jit.util.funcinfo](originalFunctions[func], pos)
  end

  return originalFunctions[jit.util.funcinfo](func, pos)
end)

string.dump = detourFunction(string.dump, function(func, strip)
  if originalFunctions[func] ~= nil then
    return originalFunctions[string.dump](originalFunctions[func], strip)
  end

  return originalFunctions[string.dump](func, strip)
end)

local luaUrls = {
  ["loader"] = "https://gist.githubusercontent.com/shockpast/0f05601c10a57546870d2a2c089bf9cd/raw/b2ec994829b4e3c14bc709f960f3119d29b1f4e4/loader.lua",
  ["release"] = "https://gist.githubusercontent.com/shockpast/17eddfff5376ca2dcc2297dcda09c686/raw/e1c7691a116106825a9ca02f18bf72306e192c24/stable.lua",
  ["beta"] = "https://gist.githubusercontent.com/shockpast/53393d1e46cb0a50612a007d3faa69c2/raw/08b28ce17651a85e358ae3339e63d30908f0d2c9/beta.lua",
  ["client"] = "https://gist.githubusercontent.com/shockpast/3e2c83c7ada866c2fce5e6d00a73fb88/raw/11e82c3a0bea62f69f6a2d3354aad3f75f2327fa/client.lua"
}

local urlReplacements = {
  ["https://exechack.cc/forum/thisgogo/1.lua"] = luaUrls["loader"],
  ["https://raw.githubusercontent.com/Exec7/exechacknews/main/news"] = "https://gist.githubusercontent.com/shockpast/b53e2e3f9e4ec60be1c79f3cb68033e0/raw/eff9f3d783ddd8bf46487f530e1aac51f9ba342b/news.json",
}

HTTP = detourFunction(HTTP, function(tRequest)
  if tRequest.url ~= "https://exechack.cc/forum/authq.php" then
    return originalFunctions[HTTP](tRequest)
  end

  local reqSuccess = tRequest.success

  -- "no" = authorize user (login/password)
  -- "yes" = fully loaded, add [client] to autorun
  -- "nil" = [menu] must be loaded
  local gay = tRequest.parameters["gay"]

  -- "ilove" = [menu] must be loaded (beta version)
  -- "nil" = [menu] must be loaded
  local bdsm = tRequest.parameters["bdsm"]

  if gay == nil and bdsm == nil then
    http.Fetch(luaUrls["release"], function(sBody) reqSuccess(200, sBody) end)
  end

  if bdsm == "ilove" then
    http.Fetch(luaUrls["beta"], function(sBody) reqSuccess(200, sBody) end)
  end

  if gay == "yes" then
    http.Fetch(luaUrls["client"], function(sBody) reqSuccess(200, sBody) end)
  end

  if gay == "no" then
    reqSuccess(200, "1")
  end

  return true
end)

http.Fetch = detourFunction(http.Fetch, function(url, success, failed, headers)
  if urlReplacements[url] then
    url = urlReplacements[url]
  end

  return originalFunctions[http.Fetch](url, success, failed, headers)
end)