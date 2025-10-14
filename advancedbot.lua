-- read user-defined variable
local function read_address(address, domain, datasize, bigendian)
	if type(address) ~= "number" then return 0 end
	if domain then pcall(function() memory.usememorydomain(domain) end) end
	local val
	if datasize == 1 then
		val = memory.read_u8(address)
	elseif datasize == 2 then
		val = (bigendian and memory.read_u16_be(address)) or memory.read_u16_le(address)
	else	-- default to 4 bytes
		val = (bigendian and memory.read_u32_be(address)) or memory.read_u32_le(address)
	end
	return val or 0
end

local function validate_address(address, domain, datasize)
	if type(address) ~= "number" or address < 0 then
		return false, "address must not be negative"
	end
	local domains = {}
	if memory.getmemorydomainlist then
		for _, d in ipairs(memory.getmemorydomainlist()) do domains[d] = true end
	end
	if next(domains) and not domains[domain] then
		return false, "Unknown memory domain: " .. tostring(domain)
	end
	local dsize = memory.getmemorydomainsize(domain)
	if type(dsize) ~= "number" or dsize <= 0 then
		local ok = pcall(function() memory.usememorydomain(domain) end)
		if not ok then
			return false, "Cannot access memory domain: " .. tostring(domain)
		end
		return false, "Could not determine size of domain '" .. tostring(domain) .. "'."
	end
	local size = (datasize == 1 and 1) or (datasize == 2 and 2) or 4
	local last = address + size - 1
	if last >= dsize then
		return false, string.format(
			"Address 0x%X (size %d) is out of range for domain '%s' (size 0x%X).",
			address, size, tostring(domain), dsize
		)
	end
	return true
end



-- ui
local field_width_small = 80
local field_width_large = 120
local BTN_LIST = {"Up","Down","Left","Right","A","B","L","R"}
local frm = forms.newform(320, 590, "AdvancedBot")
local ybase = 10

forms.label(frm, "Total duration (in frames):", 10, ybase, 130, 20)
local in_fd = forms.textbox(frm, "", field_width_small, 20, nil, 150, ybase-2)

ybase = ybase+28
forms.label(frm, "Min # of sweep frames:", 10, ybase, 130, 20)
local in_kmin = forms.textbox(frm, "", field_width_small, 20, nil, 150, ybase-2)

ybase = ybase+28
forms.label(frm, "Max # of sweep frames:", 10, ybase, 130, 20)
local in_kmax = forms.textbox(frm, "", field_width_small, 20, nil, 150, ybase-2)

ybase = ybase+40
forms.label(frm, "Address to watch (hex):", 10, ybase, 130, 20)
local in_address = forms.textbox(frm, "", field_width_small, 20, nil, 150, ybase-2)

ybase = ybase+28
forms.label(frm, "Memory Domain:", 10, ybase, 130, 20)
local dd_domain = forms.dropdown(frm, {"IWRAM","EWRAM","BIOS","PALRAM","VRAM","OAM","ROM","SRAM","Combined WRAM","System Bus"}, 150, ybase-2, field_width_large, 22)

ybase = ybase+28
forms.label(frm, "Data size:", 10, ybase, 60, 20)
local dd_valuesize = forms.dropdown(frm, {"1-byte","2-byte","4-byte"}, 80, ybase-2, field_width_small, 22)

local chk_be = forms.checkbox(frm, "Big Endian?", 200, ybase-4)
pcall(function() forms.setproperty(chk_be, "Checked", false) end)

ybase = ybase+44
forms.label(frm, "Trials:", 10, ybase, 60, 20)
local lbl_trials = forms.label(frm, "-", 80, ybase, 80, 20)

ybase = ybase+20
forms.label(frm, "Frames:", 10, ybase, 60, 20)
local lbl_frames = forms.label(frm, "-", 80, ybase, 80, 20)

ybase = ybase-20
forms.label(frm, "FPS value:", 170, ybase, 60, 20)
local in_fps = forms.textbox(frm, "300", 60, 20, nil, 250, ybase-4)

ybase = ybase+20
forms.label(frm, "Est. time:", 170, ybase, 60, 20)
local lbl_eta = forms.label(frm, "-", 250, ybase, 60, 20)

local function seconds_to_hms(sec)
	if not sec or sec ~= sec or sec == math.huge or sec <= 0 then return "-" end
	local s = math.floor(sec + 0.5)
	local h = math.floor(s / 3600)
	s = s % 3600
	local m = math.floor(s / 60)
	s = s % 60
	return string.format("%d:%02d:%02d", h, m, s)
end

-- special case: k=0 is just 1 trial
local function count_trials(fd, kmin, kmax)
	local n = 0
	for k = kmin, kmax do
		if k == 0 then
			n = n + 1
		else
			n = n + (fd - k + 1)
		end
	end
	return math.max(0, n)
end

local function clamp_params(fd, kmin, kmax)
	fd = math.max(1, math.floor(fd or 1))
	kmin = math.max(0, math.floor(kmin or 0))
	kmax = math.max(0, math.floor(kmax or fd))
	if kmin > kmax then kmin, kmax = kmax, kmin end	-- taking care of all kinds of edge cases
	if kmin > fd then kmin = fd end
	if kmax > fd then kmax = fd end
	return fd, kmin, kmax
end

local function update_counters_once()
	local fd_ui = tonumber(forms.gettext(in_fd))
	local kmin_ui = tonumber(forms.gettext(in_kmin))
	local kmax_ui = tonumber(forms.gettext(in_kmax))
	local speed_ui = tonumber(forms.gettext(in_fps)) or 1.0
	local fd, kmin, kmax = clamp_params(fd_ui or 1, kmin_ui or 0, kmax_ui or (fd_ui or 1))
	local trials = count_trials(fd, kmin, kmax)
	local frames = trials * fd
	local denom = (speed_ui > 0) and (speed_ui) or nil
	local eta = denom and (frames / denom) or nil
	pcall(function() forms.settext(lbl_trials, tostring(trials)) end)
	pcall(function() forms.settext(lbl_frames, tostring(frames)) end)
	pcall(function() forms.settext(lbl_eta, seconds_to_hms(eta)) end)
end

ybase=ybase+20
local btn_update = forms.button(frm, "Update", function() update_counters_once() end, 230, ybase, 70, 28)

ybase=ybase+28
forms.label(frm, "Always-held buttons:", 10, ybase, 180, 20)
local chk = {}
ybase=ybase+20
for i, b in ipairs(BTN_LIST) do
	local row = math.floor((i-1)/3)
	local col = (i-1)%3
	chk[b] = forms.checkbox(frm, b, 20 + col*120, ybase + row*24)
end

ybase = ybase + 8 + (math.floor(#BTN_LIST/3)+1)*24
forms.label(frm, "Sweep button (held consecutively):", 10, ybase, 200, 20)
local dd_sweep = forms.dropdown(frm, BTN_LIST, 240, ybase, 60, 22)

ybase=ybase+28
forms.label(frm, "TAStudio Branch #:", 10, ybase, 220, 20)
local in_branch = forms.textbox(frm, "2", 60, 20, nil, 240, ybase)

ybase=ybase+24
local chk_apply_best = forms.checkbox(frm, "Input best", 10, ybase)
pcall(function() forms.setproperty(chk_apply_best, "Checked", true) end)

-- buttons at the bottom of the window
local btn_run = nil
local btn_pause = nil
local btn_close = nil
local btn_about = nil

local function dbg(tag, msg) console.log(string.format("[%s] %s", tag, msg or "")) end

local function load_branch(idx0)
	if not tastudio or not tastudio.engaged() then
		return false, "TAStudio not engaged"
	end
	local ok, err
	if tastudio.loadbranch then ok, err = pcall(tastudio.loadbranch, idx0); if ok then return true end end
	return false, "no compatible tastudio.loadbranch function"
end

local function write_window_to_tastudio(start_frame, fd, k, s, sweep_btn, always)
	tastudio.clearinputchanges()
	for f = 0, fd - 1 do
		local frame = start_frame + f
		-- always held
		for b, on in pairs(always) do
			if on then tastudio.submitinputchange(frame, b, true) end
		end
		-- sweep button
		local in_window = (f+1 > s) and (f+1 <= s + k)
		tastudio.submitinputchange(frame, sweep_btn, in_window)
	end
	tastudio.applyinputchanges()
end

-- config/state
local cfg = {
	fd = 0,
	kmin = 0,
	kmax = 0,
	address = nil,
	domain = nil,
	datasize = nil,
	bigendian = false,
	addresscheck = false,
	sweep_btn = "",
	always = {},
	branch0 = 1,
}

local running = false
local paused = false
local phase = "idle"	-- values: idle, seek, window, nextTrial, done
local k = 0	-- length of sweep
local s = 0	-- start offset (0-based)
local i = 0	-- window frame index
local tried = 0
local total_trials = 0
local baseline_user_value = nil
local first_change = nil
local best = nil	-- syntax: {abs_frame, k, s, window_frame}
local start_frame = 0	-- absolute frame where the test window begins

local function reset_search()
	phase = "idle"
	address = nil
	domain = nil
	datasize = nil
	bigendian = false
	addresscheck = false
	k, s, i = cfg.kmin, 0, 0
	tried = 0
	baseline_user_value = nil
	first_change = nil
	best = nil
	start_frame = 0
end

local function start_search()
	cfg.fd, cfg.kmin, cfg.kmax = clamp_params(cfg.fd, cfg.kmin, cfg.kmax)	-- take care of edge cases/wrong inputs
	total_trials = count_trials(cfg.fd, cfg.kmin, cfg.kmax)
	reset_search()
	running = true
	paused = false
	if btn_pause then pcall(function() forms.settext(btn_pause, "Pause sweep") end) end
	if tastudio and tastudio.engaged() then
		tastudio.setrecording(true)
	else
		dbg("ERR", "TAStudio not engaged; open TAStudio before running.")
	end
	phase = "seek"
	client.unpause()
end

local function stop_everything()
	running = false
	paused = false
	phase = "idle"
	event.unregisterbyname("ROOM_SWEEP_MACHINE")
	event.unregisterbyname("ROOM_SWEEP_INPUTS")
end

local function step_machine()
	if not running or paused then return end
	if phase == "seek" then
		if i == 0 then
			local ok, err = load_branch(cfg.branch0)
			if not ok then
				console.write("Failed to load TAStudio branch: " .. tostring(err))
				running = false
				phase = "idle"
				return
			end
			start_frame = emu.framecount()
			tastudio.setplayback(start_frame - 1)
			baseline_user_value = read_address(cfg.address,cfg.domain,cfg.datasize,cfg.bigendian)
			first_change = nil
			write_window_to_tastudio(start_frame, cfg.fd, k, s, cfg.sweep_btn, cfg.always)
			i = 1
			phase = "window"
			return
		end
	end

	if phase == "window" then
		local r = read_address(cfg.address,cfg.domain,cfg.datasize,cfg.bigendian)
		if (first_change == nil) and (r ~= baseline_user_value) then
			first_change = emu.framecount()
		end
		if i < cfg.fd+2 then	-- +2 needed because i does not start at 0 (i=1 in seek and +1 from starting a frame early in write_window_to_tastudio, so I need this +2 to offset things)
			i = i + 1
		else
			tried = tried + 1
			if first_change then
				if (not best) or (first_change < best.abs_frame) then
					best = {abs_frame = first_change, k = k, s = s, window_frame = first_change - start_frame + 1}
					dbg("BEST", string.format("New best: change happened on abs=%d k=%d s=%d windowFrame=%d", best.abs_frame, best.k, best.s, best.window_frame))
				end
			end
			phase = "nextTrial"
		end
		return
	end

	if phase == "nextTrial" then
		local max_s_for_k = (k == 0) and 0 or (cfg.fd - k)	-- k=0 special case
		if s < max_s_for_k then
			s = s + 1
		else
			if k < cfg.kmax then
				k = k + 1
				s = 0
			else
				phase = "done"
			end
		end
		if phase ~= "done" then
			i = 0
			baseline_user_value = nil
			first_change = nil
			phase = "seek"
		end
		return
	end
	
	if phase == "done" then
		running = false
		client.pause()
		if best then
			local hold_from = best.s + 1
			local hold_to = best.s + best.k
			console.write("\n","--- DONE ---","\n")
			console.write(string.format("Earliest variable change at absolute frame %d (window frame %d of %d).", best.abs_frame, best.window_frame, cfg.fd),"\n")
			console.write(string.format("Sweep: %s held consecutively on frames [%d..%d] (len %d).", cfg.sweep_btn, hold_from, hold_to, best.k),"\n")
			local apply_best = forms.ischecked(chk_apply_best)
			if apply_best then	-- apply best solution if checkbox is checked
				local ok, err = load_branch(cfg.branch0)
				if not ok then
					dbg("ERR", "Could not reload branch to apply best: " .. tostring(err))
				else
					local startf = emu.framecount()
					tastudio.setplayback(startf - 1)
					write_window_to_tastudio(startf, cfg.fd, best.k, best.s, cfg.sweep_btn, cfg.always)
					dbg("BEST", string.format("Best solution written at frame %d (len=%d, start offset=%d). Address change happened on frame %d", startf, best.k, best.s, best.abs_frame))
				end
			end
			local ah = {}
			for _, b in ipairs(BTN_LIST) do if cfg.always[b] then table.insert(ah, b) end end
				console.write("Always held: " .. (#ah > 0 and table.concat(ah, "+") or "(none)"))
		else
			console.write(string.format("No variable change detected in any of the %d trials.", total_trials))
		end
		return
	end
end

-- buttons, events, manual counters

local function read_ui_into_cfg()
	cfg.fd = tonumber(forms.gettext(in_fd))
--	cfg.fd=cfg.fd+1	-- if the final frame should be (branch frame + total duration). basically a 0/1 index issue
	cfg.kmin = tonumber(forms.gettext(in_kmin)) or 0
	cfg.kmax = tonumber(forms.gettext(in_kmax)) or (cfg.fd or 0)
	local s = forms.gettext(in_address) or ""
	s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^0[xX]", "")	-- accepts with or without 0x
	cfg.address = tonumber(s, 16)
	if not cfg.address then
		console.log("Please enter a hex address to be read so the script knows what solutions to prefer")
		cfg.addresscheck = false
		return
	end
	cfg.domain    = forms.gettext(dd_domain) or "System Bus"
	local _sz     = forms.gettext(dd_valuesize) or "1-byte"
	cfg.datasize  = (_sz:find("^1") and 1) or (_sz:find("^2") and 2) or 4
	cfg.bigendian = forms.ischecked(chk_be)
	local why = nil
	cfg.addresscheck, why = validate_address(cfg.address, cfg.domain, cfg.datasize)	-- check to see whether the address given by the user is valid
	if not cfg.addresscheck then
		console.write("Address check failed: " .. tostring(why))
		console.write("\n","Script did not start","\n")
		return
	end
	cfg.sweep_btn = forms.gettext(dd_sweep) or "Up"	-- up is default/fallback
	cfg.branch0 = (tonumber(forms.gettext(in_branch)) or 1) - 1
	cfg.always = {}
	for _, b in ipairs(BTN_LIST) do cfg.always[b] = forms.ischecked(chk[b]) end
end

local function start_sweep_from_ui()
	read_ui_into_cfg()
	if cfg.addresscheck then start_search() end
end

local function toggle_pause()
	if not running then
		paused = not paused
		if paused then client.pause() else client.unpause() end
		if btn_pause then pcall(function() forms.settext(btn_pause, paused and "Resume sweep" or "Pause sweep") end) end
		return
	end
	paused = not paused
	if paused then client.pause() else client.unpause() end
	if btn_pause then pcall(function() forms.settext(btn_pause, paused and "Resume sweep" or "Pause sweep") end) end
end

local function close_window()
	event.unregisterbyname("ROOM_SWEEP_MACHINE")
	event.unregisterbyname("ROOM_SWEEP_INPUTS")
	pcall(function() forms.destroy(frm) end)
end

local function open_about()
	local W, H = 520, 520
	local af = forms.newform(W, H, "About AdvancedBot")
	local txt = [[
AdvancedBot is a Lua script to be used with BizHawk & TAStudio. It is currently written with GBA games in mind.

AdvancedBot searches for the earliest frame (within a fixed window) where the the value of a given address changes, while holding: a set of "always-held" buttons for the whole window, plus one "sweep button" for a consecutive run of k frames inside that window. It records the inputs for which the fastest change happens (and posts a corresponding log message) and at the end inserts the fastest one into the selected branch within TAStudio.

How it works
-----------------------
1. The bot reloads a selected TAStudio branch before each run
2. Inputs begin on the frame the branch is loaded
3. Inputs are written straight into TAStudio (recording mode is turned on automatically)
4. After each frame in the window the bot reads the given address. If the corresponding value differs from its initial value, that frame is recorded as a "change"
5. Across all trials, the earliest absolute frame with a change is reported. If the "Input best" checkbox is enabled, the corresponding input window is written back into TAStudio at the selected branch

UI reference
------------
- Total duration (in frames): The window size to simulate per trial
- Min/Max # of sweep frames: To further limit the search space so only sweep button sequences of length k_min <= k <= k_max are tested. If left empty, k_min = 0 and k_max = total duration
- Trials / Frames / FPS value / Est. time / Update: To give an idea of how long the sweep will take. The FPS value has to be entered by hand, and the Est. Time updates only when the "Update" button is clicked
- Always-held buttons: As the name suggests, buttons that are held for every frame of the window in every trial
- Sweep button: The button that is tested for k consecutive frames within the window. 
- TAStudio Branch: Input which TAStudio branch should be used for testing. The frame of the corresponding branch is also the first frame of the testing window
- Input best: If checked, after the sweep finishes (and a best is found), the bot reloads the branch once more and writes the best input sequence into TAStudio
- Run sweep: Starts the sweep using the given values
- Pause sweep: Toggles pause/resume of the script
- Close window: Stops the sweep and closes the window
- About: Opens this window (you did it!)

Console output
-----------------------
The console logs all best attempts, including the following info:
- Earliest variable change at absolute frame X
- Duration of frames the sweep button is held (k), and what frame it starts on relative to the first frame of the testing window (s)
- Assuming any change was found at all, the final message will also remind you which buttons were held always, and what was the sweep button
]]
	local tb = forms.textbox(af, txt, W - 30, H - 60, nil, 10, 10, true, false, "Vertical")
	pcall(function()
		forms.setproperty(tb, "Multiline", true)
		forms.setproperty(tb, "WordWrap",  true)
		forms.setproperty(tb, "ReadOnly",  true)
		forms.setproperty(tb, "ScrollBars","Vertical")
	end)
	local crlf = txt:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\n", "\r\n")
	forms.settext(tb, crlf)
	forms.button(af, "Close", function() forms.destroy(af) end, W - 90, H - 40, 70, 24)
end

ybase=ybase+28
btn_run = forms.button(frm, "Run sweep", start_sweep_from_ui, 60, ybase, 200, 28)
ybase=ybase+32
btn_pause = forms.button(frm, "Pause sweep", toggle_pause, 60, ybase, 200, 28)
ybase=ybase+32
btn_close = forms.button(frm, "Close window",close_window, 60, ybase, 200, 28)
ybase=ybase+32
btn_about = forms.button(frm, "About", open_about, 60, ybase, 200, 28)

update_counters_once()
event.unregisterbyname("ROOM_SWEEP_MACHINE")
event.unregisterbyname("ROOM_SWEEP_INPUTS")
event.oninputpoll(function() end, "ROOM_SWEEP_INPUTS")
event.onframeend(step_machine, "ROOM_SWEEP_MACHINE")