# Touch trial changes

The local Fab4 trial adds visible **Play last station**, **Stop**, **Saved
stations**, and **Save current station** entries. Saved Stations combines the
nine preset slots and favorites without duplicates. Radio Browser station rows expose
the same favorite/preset actions as provider stations.

While Standalone Radio owns playback, a short press of the physical IR remote's
number keys 1–9 recalls the corresponding assigned preset. From standby, an
assigned number wakes the Touch and starts that preset. Assign slots 1–9
through a station's action menu or **Save current
station**. Unassigned numbers and numbers used while Radio does not own
playback while awake pass through to the normal interface. The six physical Radio preset
buttons retain their existing behavior.

Global Pause/Stop handlers pass through when Standalone Radio does not own
playback. Awake Play may resume a stopped Radio on the selected local Base
player; an external-library selection or another native stream start revokes
that permission. A remembered station alone does not capture awake Play.
The explicit Play menu entry and assigned standalone presets can
still start a standalone station. Unassigned presets and preset assignment while
another source owns playback pass through.

Standby Play resumes the remembered station when the local player is attached
to StandaloneBase. On Touch, the powered-off clock converts raw infrared input
inside `Window._ignoreAllInputListener` and `ScreenSavers._powerActionHandler`
wakes the player and translates Play to Pause. A global Play action listener
alone therefore cannot handle physical remote Play. Radio now intercepts a
short `EVENT_IR_PRESS` mapped to Play before the clock window and shares the
normal Play handler. Awake infrared input, other buttons, held Play, absent
stations and external-server playback still pass through. Play action priority
also precedes the screensaver's global listener regardless of load order.

Power-off now stops standalone playback before the native LocalPlayer power
transition. The firmware normally pauses only the decoder, leaving the radio
stream and its recovery timers active; recovery could therefore produce audio
behind the clock. Stop clears active station intent and invalidates callbacks
before cancelling pending work, while retaining the remembered station. The
standby regression covers underrun recovery, watchdog/keepalive ticks, queued
retries and late stream callbacks, followed by explicit Play.

On a detected Logitech Fab4 Board, directory caches live under
`/tmp/standalone-radio/cache`, rather than the flash settings tree. The duplicate
downloaded logo cache is disabled for this trial; native/Base artwork routing is
retained. A country directory is limited to 1 MiB, only one country refresh runs
at once, and other countries' disk cache files are evicted. Refreshes exceeding
the limit fail explicitly rather than silently truncating a country's stations.
Temporary replacement data can consume another 1 MiB and popular data at most
256 KiB. Caches do not survive a reboot. Radio hardware retains its existing
cache behavior.

The startup diagnostic marker still starts preset 1 after five seconds. Its
playback is now bounded to thirty seconds and is stopped only if the user has
not selected another station in the meantime. Normal boot never starts this
diagnostic without its `/tmp/standalone-radio-autotest` marker.

The 28-suite Lua runner includes stopped-radio resume, standby recovery, ownership/UI/favorites and Touch cache-limit
regressions. Four existing static integration checks and the real Touch volume
contract also pass. Hardware playback, touchscreen operation and reboot behavior
must be recorded separately from these mocked/host checks.

The awake Stop/Pause -> Play correction is currently source/host-tested only;
it has not been deployed to the Touch.
