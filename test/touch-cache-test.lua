local realIO=io
io={open=function() return {read=function() return "Hardware : Logitech Fab4 Board\n" end,close=function() end} end}
local policy=require("applets.StandaloneRadio.TouchPolicy")
io=realIO
assert(policy.touch and policy.cacheRoot=="/tmp/standalone-radio/cache" and policy.directoryBytes==1024*1024)
-- Execute the production refresh path with a tiny test quota and fake disk/network.
local f=assert(io.open("applet/StandaloneRadio/RadioBrowser.lua","r"));local source=f:read("*a");f:close()
RadioBrowser={};TouchPolicy=policy;TouchPolicy.directoryBytes=64
CACHE_DIR="/tmp/cache";API_BASE="http://offline.invalid";PAGE_SIZE=250
local removed,output,result,errorMessage={},"",nil,nil
lfs={dir=function() local names={"station-cache-BE.jsonl","station-cache-NL.jsonl"};local i=0;return function() i=i+1;return names[i] end end}
local realOS=os
os={remove=function(path) removed[path]=true;return true end,rename=function() return true end}
io={open=function() return {write=function(_,line) output=output..line;return true end,close=function() end} end}
dataPath=function(code) return CACHE_DIR.."/station-cache-"..code..".jsonl" end
legacyPath=dataPath
closeFile=function(file) if file then file:close() end end
compatible=function() return true end;toStation=function() return {name="Station"} end;cacheRecord=function(station) return station end
local encoded=string.rep("x",65)
json={encode=function() return encoded end,decode=function() return {{name="Station"}} end}
UrlTransport={forRequest=function() return {host="offline.invalid"} end}
assert(loadstring(assert(source:match("(function RadioBrowser:refresh.-)function RadioBrowser:recordClick"))))()
local browser=setmetatable({refreshes={},log={info=function() end,warn=function() end},
    cancelSearch=function() end,cancelPopular=function() end,
    resolver={resolve=function(_,host,cb) cb("127.0.0.1") end},
    _fetchWithIp=function(_,ip,url,sink) sink("fixture") end,
    _addPopular=function() end,_writeMetadata=function() return true end,_writePopular=function() return true end}, {__index=RadioBrowser})
browser:refresh("NL",function(directory,err) result=directory;errorMessage=err end)
assert(not result and errorMessage:find("Touch cache limit") and #output==0)
assert(removed[CACHE_DIR.."/station-cache-BE.jsonl"])
assert(not removed[CACHE_DIR.."/station-cache-NL.jsonl"])
encoded="small";errorMessage=nil
browser:refresh("NL",function(directory,err) result=directory;errorMessage=err end)
assert(result and result.count==1 and not errorMessage and #output<=64)
browser.refreshes.NL={}
assert(browser:refresh("BE",function(_,err) errorMessage=err end)==false and errorMessage:find("in progress"))
io=realIO;os=realOS
print("Touch RAM-cache selection, byte quota, country eviction and single-refresh limit passed")
