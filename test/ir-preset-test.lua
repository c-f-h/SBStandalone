local file=assert(io.open("applet/StandaloneRadio/StandaloneRadioApplet.lua","r"))
local source=file:read("*a"); file:close()
assert(source:match("local [^\n]*tonumber[^\n]*="))
EVENT_CONSUME,EVENT_UNUSED,EVENT_IR_PRESS="consume","unused","ir"
local ir
Framework={addActionListener=function() return {} end,
    addListener=function(_,mask,callback) assert(mask==EVENT_IR_PRESS); ir=callback; return {} end,
    getIRButtonName=function(_,code) return code end,
    getAction=function(_,event) return event.action end}
jiveMain={state="on",getSoftPowerState=function(self) return self.state end,
    setSoftPowerState=function(self,state) self.state=state end}
_logInfo=function() end
local registration=assert(source:find("function enableStandaloneMode(self)",1,true))
assert(loadstring(source:sub(registration)))()
local stations={[1]={id="one"},[9]={id="nine"}}
local stream={ownsPlayback=false}
local applet={streamPlayer=stream,_ensureComponents=function() return true end,
    presetStore={getPreset=function(_,n) return stations[n] end},
    _playStation=function(self,station) self.selected=station end}
enableStandaloneMode(applet)
local function press(key) return ir({getIRCode=function() return key end}) end
assert(press("1")==EVENT_UNUSED and not applet.selected)
stream.ownsPlayback=true
assert(press("1")==EVENT_CONSUME and applet.selected==stations[1])
assert(press("9")==EVENT_CONSUME and applet.selected==stations[9])
assert(press("2")==EVENT_UNUSED and press("0")==EVENT_UNUSED)
jiveMain.state="off"; stream.ownsPlayback=false
assert(press("2")==EVENT_UNUSED and jiveMain.state=="off")
assert(press("1")==EVENT_CONSUME and jiveMain.state=="on" and applet.selected==stations[1])
jiveMain.state="off"
assert(press("9")==EVENT_CONSUME and jiveMain.state=="on" and applet.selected==stations[9])
print("IR presets pass awake and standby checks")
