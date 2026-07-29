hl.bind(
	"CTRL+SUPER+ALT+Slash",
	hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
	{ description = "Edit user keybinds" }
)

local clicking = false
local INTERVAL = 100 -- ms between clicks -> 10 CPS

local function tick()
	if not clicking then
		return
	end
	hl.dispatch(hl.dsp.exec_cmd("ydotool click 0xC0")) -- 0xC0 = left down+up
	hl.timer(tick, { timeout = INTERVAL, type = "oneshot" }) -- re-arm
end

hl.bind("SUPER + SHIFT + CTRL + C", function()
	clicking = not clicking
	hl.notification.create({
		text = clicking and "Autoclicker ON (10 CPS)" or "Autoclicker OFF",
		timeout = 1000,
		icon = "ok",
	})
	if clicking then
		tick()
	end
end)
