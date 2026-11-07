local file=assert(io.open("applet/StandaloneRadio/StandaloneRadioApplet.lua","r"))
local source=file:read("*a");file:close()
assert(source:match("local [^\n]*tonumber[^\n]*="), "applet module must capture tonumber before changing environments")
EVENT_CONSUME,EVENT_UNUSED="consume","unused"
EVENT_IR_PRESS="ir_press"
local actions,calls,listeners={},{},{}
Framework={addActionListener=function(_,name,owner,callback,priority)
    actions[name]=callback
    listeners[#listeners+1]={name=name,callback=callback,priority=math.abs(priority),order=#listeners+1}
    return name
end}
local irPress
Framework.addListener=function(_,mask,callback,priority)
    assert(mask==EVENT_IR_PRESS and priority<0)
    irPress=callback;return mask
end
Framework.getAction=function(_,event) return event.action end
Framework.getIRButtonName=function(_,code) return code end
jiveMain={state="on",getSoftPowerState=function(self) return self.state end,
    setSoftPowerState=function(self,state) self.state=state end}
hasServerMigration=true
ServerMigration={LOCAL_UUID="local"}
local server={id="local"}
local player={isLocal=function() return true end,getSlimServer=function() return server end}
appletManager={callService=function() return player end}
_logInfo=function() end
local registration=assert(source:find("function enableStandaloneMode(self)",1,true))
assert(loadstring(source:sub(registration)))()
local stream={ownsPlayback=false}
for _,name in ipairs({"play","pause","stop"}) do stream[name]=function() calls[name]=(calls[name] or 0)+1;return true end end
local applet={streamPlayer=stream,_ensureComponents=function() return true end}
enableStandaloneMode(applet)
for _,name in ipairs({"play","pause","stop"}) do
    assert(actions[name]()==EVENT_UNUSED and not calls[name],name)
end
stream.ownsPlayback=true
for _,name in ipairs({"play","pause","stop"}) do assert(actions[name]()==EVENT_CONSUME and calls[name]==1,name) end
stream.ownsPlayback=false
assert(actions.stop()==EVENT_UNUSED and calls.stop==1)
applet.lastStation={id="last"}
applet._playStation=function(_,station) assert(station==applet.lastStation);calls.restart=(calls.restart or 0)+1 end
jiveMain.state="off"
server.id="remote"
assert(actions.play()==EVENT_UNUSED and not calls.restart and jiveMain.state=="off")
server.id="local"
assert(actions.play()==EVENT_CONSUME and calls.restart==1 and jiveMain.state=="on")
jiveMain.state="off";applet.lastStation=nil
assert(actions.play()==EVENT_UNUSED and jiveMain.state=="off")
-- Firmware sorts global listeners by absolute priority, then newest first.
-- ScreenSavers may initialize after Radio. Its -100 listener wakes the player
-- before forwarding Play, so Radio must run before it to observe standby.
listeners[#listeners+1]={name="play",priority=100,order=#listeners+1,callback=function()
    jiveMain:setSoftPowerState("on")
    return EVENT_UNUSED
end}
table.sort(listeners,function(a,b)
    if a.priority==b.priority then return a.order>b.order end
    return a.priority<b.priority
end)
applet.lastStation={id="last"}
jiveMain.state="off"
local restarted=calls.restart
for _,listener in ipairs(listeners) do
    if listener.name=="play" and listener.callback()==EVENT_CONSUME then break end
end
assert(calls.restart==restarted+1,"standby Play must resume before firmware wakes or translates the action")
jiveMain.state="on";restarted=calls.restart
assert(actions.play()==EVENT_UNUSED and calls.restart==restarted,"awake non-owner Play must pass through")
applet.lastStation=nil
-- The actual clock's ignoreAllInputExcept converts raw IR within its window
-- and translates Play into Pause, bypassing global Play action listeners.
local function physicalPress(action)
    if irPress({action=action,getIRCode=function() return action end})==EVENT_CONSUME then return EVENT_CONSUME end
    if action=="play" then
        jiveMain:setSoftPowerState("on")
        return actions.pause()
    end
    return EVENT_UNUSED
end
applet.lastStation={id="last"};jiveMain.state="off";restarted=calls.restart
assert(physicalPress("play")==EVENT_CONSUME and calls.restart==restarted+1 and jiveMain.state=="on",
    "physical standby Play must resume before clock translates IR to Pause")
jiveMain.state="off";server.id="remote"
assert(irPress({action="play",getIRCode=function() return "play" end})==EVENT_UNUSED and jiveMain.state=="off")
server.id="local";applet.lastStation=nil
assert(irPress({action="play",getIRCode=function() return "play" end})==EVENT_UNUSED and jiveMain.state=="off")
applet.lastStation={id="last"};jiveMain.state="on"
assert(irPress({action="play"})==EVENT_UNUSED,"awake IR must retain normal menu behavior")
jiveMain.state="off"
assert(irPress({action="create_mix",getIRCode=function() return "play" end})==EVENT_UNUSED,"held Play must pass through")
assert(irPress({action="pause",getIRCode=function() return "pause" end})==EVENT_UNUSED,"physical Pause must pass through")
stream.ownsPlayback=true
assert(physicalPress("play")==EVENT_CONSUME and calls.play==2 and jiveMain.state=="on")
stream.ownsPlayback=false;applet.lastStation=nil
local presets={[1]={id="one"},[9]={id="nine"}}
applet.presetStore={getPreset=function(_,number) return presets[number] end}
applet._playStation=function(_,station) calls.selected=station end
local function numberPress(button)
    return irPress({getIRCode=function() return button end})
end
jiveMain.state="on"
assert(numberPress("1")==EVENT_UNUSED and not calls.selected,"non-owner numbers must pass through")
stream.ownsPlayback=true
assert(numberPress("1")==EVENT_CONSUME and calls.selected==presets[1])
assert(numberPress("9")==EVENT_CONSUME and calls.selected==presets[9])
assert(numberPress("2")==EVENT_UNUSED and calls.selected==presets[9],"unassigned number must pass through")
assert(numberPress("0")==EVENT_UNUSED and numberPress("play")==EVENT_UNUSED)
jiveMain.state="off"
stream.ownsPlayback=false
assert(numberPress("2")==EVENT_UNUSED and jiveMain.state=="off", "unassigned standby number must pass through")
assert(numberPress("1")==EVENT_CONSUME and jiveMain.state=="on" and calls.selected==presets[1], "standby preset must wake and play")
jiveMain.state="off"
assert(numberPress("9")==EVENT_CONSUME and jiveMain.state=="on" and calls.selected==presets[9], "standby preset 9 must wake and play")
jiveMain.state="on";stream.ownsPlayback=false
assert(loadstring(assert(source:match("(function _refreshMenu.-)function _selectedCountryCode"))))()
applet.string=function(_,key) return key end
applet.menuWidget={setItems=function(_,items) applet.items=items end,reLayout=function() end}
_refreshMenu(applet)
applet.items[1].callback();assert(calls.play==3,"explicit touchscreen Play should claim a remembered station")
applet.items[2].callback();assert(calls.stop==1,"touchscreen Stop must not stop an unrelated owner")
local saved={id="saved"}
applet.presetStore={getFavorites=function() return {saved} end,getPreset=function(_,n) return n==1 and saved or nil end}
applet._showStationList=function(_,title,stations) assert(#stations==1 and stations[1]==saved) end
applet.savedStationsMenu=savedStationsMenu
applet.items[3].callback()
local PresetStore=require("applets.StandaloneRadio.PresetStore")
local settings={}
local store=PresetStore.new({settings=settings,applet={storeSettings=function() end},log={info=function() end,warn=function() end}})
store:rememberStation({id="test",name="Test",url="http://example.com/radio",source="user"})
assert(store:getLastStation().id=="test")
assert(store:saveFavorite({id="radiobrowser:test",name="Test",url="http://example.com/radio",source="radiobrowser",stationuuid="test"}))
assert(#store:getFavorites()==1)
assert(store:assign(9,{id="nine",name="Nine",url="http://example.com/nine",source="user"}))
assert(store:getPreset(9).id=="nine" and not store:assign(10,{id="ten"}))
print("Touch controls, non-owner transport pass-through, saved presets and Radio Browser favorites passed")
