-- Keep disposable directory data out of the Touch's small flash overlay.
local M = {touch=false}
local file = io.open("/proc/cpuinfo", "r")
if file then
    local ok, cpu = pcall(function() return file:read("*a") end)
    pcall(function() file:close() end)
    M.touch = ok and type(cpu)=="string" and cpu:match("Hardware%s*:%s*Logitech Fab4 Board") ~= nil or false
end
M.cacheRoot = M.touch and "/tmp/standalone-radio/cache" or "/etc/squeezeplay/userpath/StandaloneRadio/cache"
M.directoryBytes = M.touch and 1024*1024 or nil
return M
