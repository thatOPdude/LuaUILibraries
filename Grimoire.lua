--[[
	☠  THE GRIMOIRE  ☠   Halloween UI library for Roblox  (v4.0 - 2.5D edition)

	NEW IN 4.0
	• ZERO emoji: every icon (pumpkin, bat, skull, ghost, spider, witch hat, potion, bone, candle,
	  flame, crystal ball, moon, blood drop, bolt, sparkle, leaf, snowflake, gear, palette, dice...)
	  is built from Frames / UICorners / gradients at runtime. Add your own with Hallow.Icons.myicon = function(root, pal) ... end
	• 2.5D look: the window is a thick extruded slab with a cast shadow, cards are raised keys that lift
	  on hover and press down on click, toggles / knobs / orb have drop shadows, and everything
	  parallaxes against your cursor so the slab appears to turn toward the mouse.

	• "The Summoning" intro: ritual circle, candles ignite one by one, runes spin up,
	  lightning strikes, a swarm bursts out, then the window splits open like a crypt door
	• A spider (or bat / skull / ghost / crystal ball, depending on theme) hangs from the window on a thread
	• Floating orb at the top of the screen reopens the UI after you minimize (draggable)
	• 6 built-in themes, switched LIVE (lightning + shockwave + swarm), plus Hallow:AddTheme()
	• Fog, drifting spirits, embers, sweeping border light, staggered card slide-ins
	• Elements: Section, Label, Paragraph, Button, Toggle, Slider, Dropdown, Keybind, Input
	• Window:CreateThemeTab() builds a ready-made Themes / Settings tab for you

	ICON NAMES (use for tabs, buttons, themes)
		pumpkin bat skull ghost spider hat potion bone candle flame orb moon drop bolt star leaf flake
		gear palette dice check warn

	USAGE
		local Hallow = loadstring(game:HttpGet("<raw url of this file>"))()
		local Win = Hallow:CreateWindow({ Title = "MY HAUNTED HUB", Theme = "Vampire" })
		local Main = Win:CreateTab("Main", "pumpkin")
		Main:CreateButton({ Name = "Boo", Icon = "ghost", Callback = function() print("boo") end })
		Win:CreateThemeTab()
]]

local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")
local Debris           = game:GetService("Debris")
local Workspace        = game:GetService("Workspace")
local localPlayer      = Players.LocalPlayer

local GUI_NAME = "Grimoire_Main"

-- Where can we mount the GUI? (executor hidden-ui -> CoreGui -> PlayerGui)
local function candidateParents()
	local list = {}
	if typeof(gethui) == "function" then
		local ok, ui = pcall(gethui)
		if ok and ui then table.insert(list, ui) end
	end
	local ok2, rg = pcall(function() return CoreGui:FindFirstChild("RobloxGui") end)
	if ok2 and rg then table.insert(list, rg) end
	table.insert(list, localPlayer:WaitForChild("PlayerGui"))
	return list
end

-- =======================================================================
--   THEMES
-- =======================================================================
local function C(r, g, b) return Color3.fromRGB(r, g, b) end

local Hallow = { SoundsEnabled = true, Version = "4.0" }

-- Swap these ids for any sound you like
Hallow.Sounds = {
	Click   = "rbxassetid://6895079853",
	Hover   = "rbxassetid://6895079853",
	Toggle  = "rbxassetid://6895079853",
	Notify  = "rbxassetid://4590662766",
	Open    = "rbxassetid://4590662766",
	Thunder = "rbxassetid://4590662766",
}

-- Icon / Mascot / Swarm / Floaters are ICON NAMES (see list above). MascotRot 180 = hangs upside-down.
Hallow.Themes = {
	Pumpkin = {
		Name = "Jack-o'-Lantern", Tag = "warm candlelight",
		Icon = "pumpkin", Mascot = "spider", MascotRot = 180, Swarm = "pumpkin", Floaters = { "pumpkin", "leaf", "candle" },
		Bg = C(15, 7, 3), Panel = C(24, 11, 5), Card = C(34, 15, 6), CardHover = C(54, 23, 8),
		Border = C(72, 31, 10), Accent = C(255, 140, 20), Glow = C(255, 206, 80), Dark = C(150, 66, 10),
		Text = C(255, 241, 226), Muted = C(204, 152, 120), Fog = C(255, 120, 40),
	},
	Vampire = {
		Name = "Vampire", Tag = "crimson & velvet",
		Icon = "bat", Mascot = "bat", MascotRot = 180, Swarm = "bat", Floaters = { "bat", "drop", "candle" },
		Bg = C(14, 4, 8), Panel = C(23, 7, 13), Card = C(33, 10, 19), CardHover = C(54, 15, 28),
		Border = C(78, 20, 38), Accent = C(228, 28, 62), Glow = C(255, 105, 125), Dark = C(122, 10, 32),
		Text = C(255, 233, 236), Muted = C(203, 140, 152), Fog = C(190, 25, 55),
	},
	Horseman = {
		Name = "Headless Horseman", Tag = "spectral hollow fire",
		Icon = "skull", Mascot = "skull", MascotRot = 0, Swarm = "leaf", Floaters = { "leaf", "skull", "moon" },
		Bg = C(7, 11, 17), Panel = C(12, 19, 27), Card = C(16, 27, 36), CardHover = C(24, 44, 54),
		Border = C(32, 66, 72), Accent = C(70, 235, 150), Glow = C(160, 255, 205), Dark = C(20, 120, 80),
		Text = C(226, 250, 240), Muted = C(130, 175, 160), Fog = C(60, 200, 140),
	},
	Witch = {
		Name = "Witch's Brew", Tag = "cauldron & starlight",
		Icon = "hat", Mascot = "orb", MascotRot = 0, Swarm = "star", Floaters = { "star", "orb", "potion" },
		Bg = C(12, 6, 22), Panel = C(20, 10, 36), Card = C(28, 14, 48), CardHover = C(44, 22, 76),
		Border = C(66, 36, 110), Accent = C(170, 90, 255), Glow = C(225, 170, 255), Dark = C(95, 45, 170),
		Text = C(244, 234, 255), Muted = C(170, 145, 205), Fog = C(150, 80, 230),
	},
	Specter = {
		Name = "Specter", Tag = "cold moonlit mist",
		Icon = "ghost", Mascot = "ghost", MascotRot = 0, Swarm = "ghost", Floaters = { "ghost", "flake", "moon" },
		Bg = C(8, 13, 22), Panel = C(14, 22, 36), Card = C(20, 32, 50), CardHover = C(32, 50, 76),
		Border = C(44, 72, 104), Accent = C(110, 200, 255), Glow = C(200, 240, 255), Dark = C(40, 100, 160),
		Text = C(236, 246, 255), Muted = C(140, 170, 200), Fog = C(140, 200, 255),
	},
	Bone = {
		Name = "Bone Yard", Tag = "ash & ancient bone",
		Icon = "skull", Mascot = "spider", MascotRot = 180, Swarm = "skull", Floaters = { "skull", "bone", "spider" },
		Bg = C(12, 12, 12), Panel = C(20, 20, 19), Card = C(28, 28, 26), CardHover = C(44, 43, 40),
		Border = C(66, 64, 58), Accent = C(226, 218, 196), Glow = C(255, 250, 235), Dark = C(130, 124, 106),
		Text = C(244, 240, 228), Muted = C(158, 152, 136), Fog = C(200, 195, 180),
	},
}
Hallow.ThemeOrder = { "Pumpkin", "Vampire", "Horseman", "Witch", "Specter", "Bone" }

function Hallow:AddTheme(key, def)
	local base = {}
	for k, v in pairs(Hallow.Themes.Pumpkin) do base[k] = v end
	for k, v in pairs(def or {}) do base[k] = v end
	base.Name = base.Name or key
	if not Hallow.Themes[key] then table.insert(Hallow.ThemeOrder, key) end
	Hallow.Themes[key] = base
end

local DEFAULTS = { Success = C(125, 225, 110), Warn = C(255, 205, 60), Danger = C(255, 75, 85) }
local Theme = {}
Hallow.Theme = Theme

local function loadTheme(name)
	local def = Hallow.Themes[name] or Hallow.Themes.Pumpkin
	for k in pairs(Theme) do Theme[k] = nil end
	for k, v in pairs(DEFAULTS) do Theme[k] = v end
	for k, v in pairs(def) do Theme[k] = v end
end
loadTheme("Pumpkin")

-- =======================================================================
--   SMALL HELPERS
-- =======================================================================
local CENTER = Vector2.new(0.5, 0.5)
local Easing, Dir = Enum.EasingStyle, Enum.EasingDirection
local Left, Right = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
local Reg, Bold, Semi = Enum.Font.Gotham, Enum.Font.GothamBold, Enum.Font.GothamSemibold
local BLACK = Color3.new(0, 0, 0)

local function new(class, props, parent)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do inst[k] = v end
	end
	if parent then inst.Parent = parent end
	return inst
end

local function round(parent, radius)
	return new("UICorner", { CornerRadius = radius or UDim.new(1, 0) }, parent)
end

local function outline(parent, color, thickness, transparency)
	return new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color,
		Thickness = thickness or 1.4,
		Transparency = transparency or 0,
	}, parent)
end

local function label(props, parent)
	local p = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Reg,
		TextColor3 = Theme.Text,
		TextSize = 14,
		Text = "",
	}
	for k, v in pairs(props) do p[k] = v end
	return new("TextLabel", p, parent)
end

-- top-light / bottom-dark bevel (multiplies the frame's own colour)
local function bevel(parent, darkness)
	local d = darkness or 150
	return new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(d, d, d)),
	}, parent)
end

-- lit-from-above rim for a stroke (top bright, bottom faded) -> fake directional light
local function rimLight(stroke)
	return new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.7) }),
	}, stroke)
end

-- bright arcs that travel around a stroke (stroke colour gets multiplied by this)
local SWEEP = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 90, 90)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
})

local function tw(obj, props, duration, style, dir)
	local info = TweenInfo.new(duration or 0.25, style or Easing.Quad, dir or Dir.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

-- instant on first build, tweened on theme change / hover
local function paint(inst, props, instant, dur)
	if instant then
		for k, v in pairs(props) do inst[k] = v end
	else
		tw(inst, props, dur or 0.5, Easing.Sine)
	end
end

local function mix(a, b, t) return a:Lerp(b, t) end

local function playSound(id, pitch, volume)
	if not Hallow.SoundsEnabled or not id then return end
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = id
			s.PlaybackSpeed = pitch or 1
			s.Volume = volume or 0.8
			s.Parent = SoundService
			s:Play()
			Debris:AddItem(s, 5)
		end)
	end)
end

local lastHover = 0
local function playHoverSound(pitch, volume)
	local now = os.clock()
	if now - lastHover > 0.05 then
		lastHover = now
		playSound(Hallow.Sounds.Hover, pitch or 1.7, volume or 0.35)
	end
end

-- utf8-safe "first n characters"
local function ssub(s, n)
	if n <= 0 then return "" end
	local len = utf8.len(s)
	if not len or n >= len then return s end
	return string.sub(s, 1, utf8.offset(s, n + 1) - 1)
end

-- expanding ring (parent should be a zero-size frame centred where you want it)
local function shockwave(parent, color, from, to, dur, thick, pos)
	local ring = new("Frame", {
		AnchorPoint = CENTER,
		Position = pos or UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, from, 0, from),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, parent)
	round(ring)
	local st = outline(ring, color, thick or 3, 0.1)
	tw(ring, { Size = UDim2.new(0, to, 0, to) }, dur, Easing.Quint)
	tw(st, { Transparency = 1, Thickness = 0.5 }, dur)
	Debris:AddItem(ring, dur + 0.1)
end

-- =======================================================================
--   ICON SET  (everything is drawn from Frames - no emoji, no images)
--   Shapes are placed in a 0..1 box:  P(root, kind, centerX, centerY, w, h, color, rotation, bevelDarkness)
--   kind: "ellipse" (fully rounded), "round" (soft rect), "rect"
-- =======================================================================
local function palette()
	return { a = Theme.Accent, g = Theme.Glow, d = Theme.Dark, bg = Theme.Bg, t = Theme.Text }
end

local function P(parent, kind, x, y, w, h, col, rot, d)
	local f = new("Frame", {
		AnchorPoint = CENTER, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h),
		BackgroundColor3 = col, BorderSizePixel = 0, Rotation = rot or 0,
	}, parent)
	if kind == "ellipse" then
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
	elseif kind == "round" then
		new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, f)
	end
	if d then bevel(f, d) end
	return f
end

local function HL(r, x, y, w, h, rot, a) -- soft white highlight
	local f = P(r, "ellipse", x, y, w, h, Color3.new(1, 1, 1), rot)
	f.BackgroundTransparency = a or 0.78
	return f
end

local Icons = {}
Hallow.Icons = Icons

Icons.pumpkin = function(r, p)
	local o1, o2, o3 = C(255, 146, 24), C(232, 108, 10), C(176, 70, 6)
	local dk, gl = C(58, 22, 4), C(255, 224, 110)
	P(r, "ellipse", 0.25, 0.60, 0.38, 0.58, o3, 0, 160)
	P(r, "ellipse", 0.75, 0.60, 0.38, 0.58, o3, 0, 160)
	P(r, "ellipse", 0.37, 0.59, 0.40, 0.68, o2, 0, 175)
	P(r, "ellipse", 0.63, 0.59, 0.40, 0.68, o2, 0, 175)
	P(r, "ellipse", 0.50, 0.58, 0.36, 0.72, o1, 0, 190)
	P(r, "round", 0.53, 0.19, 0.11, 0.22, C(86, 120, 44), 14, 160)
	P(r, "round", 0.37, 0.53, 0.115, 0.115, dk, 45)
	P(r, "round", 0.63, 0.53, 0.115, 0.115, dk, 45)
	P(r, "round", 0.37, 0.53, 0.06, 0.06, gl, 45)
	P(r, "round", 0.63, 0.53, 0.06, 0.06, gl, 45)
	P(r, "round", 0.50, 0.63, 0.06, 0.06, dk, 45)
	P(r, "ellipse", 0.50, 0.75, 0.38, 0.11, dk)
	P(r, "ellipse", 0.50, 0.75, 0.32, 0.065, gl)
	P(r, "rect", 0.42, 0.715, 0.05, 0.05, o1)
	P(r, "rect", 0.58, 0.785, 0.05, 0.05, o1)
	HL(r, 0.31, 0.42, 0.06, 0.2, 10)
end

Icons.bat = function(r, p)
	local dk = C(14, 6, 24)
	local bc, wc, wm = mix(p.a, dk, 0.60), mix(p.a, dk, 0.40), mix(p.a, dk, 0.52)
	for _, s in ipairs({ -1, 1 }) do
		P(r, "ellipse", 0.5 + s * 0.27, 0.36, 0.44, 0.10, wc, s * -22, 175)
		P(r, "ellipse", 0.5 + s * 0.22, 0.52, 0.38, 0.30, wm, s * -12, 165)
		P(r, "ellipse", 0.5 + s * 0.40, 0.61, 0.15, 0.15, wm, 0, 165)
		P(r, "ellipse", 0.5 + s * 0.30, 0.67, 0.15, 0.15, wm, 0, 165)
		P(r, "ellipse", 0.5 + s * 0.20, 0.70, 0.15, 0.15, wm, 0, 165)
		P(r, "round", 0.5 + s * 0.07, 0.25, 0.06, 0.14, bc, s * 14, 170)
	end
	P(r, "ellipse", 0.5, 0.55, 0.20, 0.38, bc, 0, 160)
	P(r, "ellipse", 0.5, 0.37, 0.21, 0.20, mix(bc, p.g, 0.14), 0, 175)
	for _, s in ipairs({ -1, 1 }) do
		P(r, "ellipse", 0.5 + s * 0.05, 0.36, 0.045, 0.045, p.g)
		P(r, "round", 0.5 + s * 0.028, 0.455, 0.02, 0.055, C(250, 250, 244))
	end
end

Icons.skull = function(r, p)
	local b1, b2, dk = C(238, 232, 214), C(212, 204, 182), C(24, 16, 22)
	P(r, "round", 0.5, 0.71, 0.36, 0.28, b2, 0, 175)
	P(r, "ellipse", 0.5, 0.42, 0.66, 0.60, b1, 0, 195)
	P(r, "ellipse", 0.35, 0.46, 0.17, 0.19, dk)
	P(r, "ellipse", 0.65, 0.46, 0.17, 0.19, dk)
	P(r, "ellipse", 0.36, 0.47, 0.06, 0.07, p.g)
	P(r, "ellipse", 0.64, 0.47, 0.06, 0.07, p.g)
	P(r, "round", 0.5, 0.61, 0.07, 0.07, dk, 45)
	for i = 1, 4 do P(r, "rect", 0.5 + (i - 2.5) * 0.075, 0.75, 0.016, 0.14, dk) end
	HL(r, 0.29, 0.26, 0.10, 0.20, 18)
end

Icons.ghost = function(r, p)
	local g1, g2, dk = C(238, 245, 255), C(196, 212, 238), C(30, 36, 60)
	P(r, "ellipse", 0.13, 0.58, 0.24, 0.10, g2, -28)
	P(r, "ellipse", 0.87, 0.58, 0.24, 0.10, g2, 28)
	P(r, "ellipse", 0.50, 0.36, 0.58, 0.54, g1)
	P(r, "rect", 0.50, 0.64, 0.58, 0.44, g1)
	for i = -1, 1 do P(r, "ellipse", 0.5 + i * 0.2, 0.87, 0.20, 0.20, g1) end
	P(r, "ellipse", 0.40, 0.38, 0.08, 0.11, dk)
	P(r, "ellipse", 0.60, 0.38, 0.08, 0.11, dk)
	P(r, "ellipse", 0.50, 0.56, 0.09, 0.12, dk)
	local c1 = P(r, "ellipse", 0.31, 0.50, 0.08, 0.05, p.a)
	local c2 = P(r, "ellipse", 0.69, 0.50, 0.08, 0.05, p.a)
	c1.BackgroundTransparency, c2.BackgroundTransparency = 0.6, 0.6
	HL(r, 0.31, 0.24, 0.10, 0.16, 15, 0.5)
end

Icons.spider = function(r, p)
	local dk = C(18, 10, 24)
	local bc, lc = mix(p.a, dk, 0.55), mix(p.a, dk, 0.42)
	local ups = { -50, -20, 10, 40 }
	for _, s in ipairs({ -1, 1 }) do
		for i = 1, 4 do
			local th = math.rad(ups[i])
			local sx, sy, L1 = 0.5 + s * 0.08, 0.42 + (i - 1) * 0.06, 0.20
			local dx, dy = math.cos(th) * s, math.sin(th)
			P(r, "ellipse", sx + dx * L1 / 2, sy + dy * L1 / 2, L1, 0.035, lc, s * ups[i])
			local ex, ey = sx + dx * L1, sy + dy * L1
			local ph, L2 = math.rad(62), 0.22
			local dx2, dy2 = math.cos(ph) * s, math.sin(ph)
			P(r, "ellipse", ex + dx2 * L2 / 2, ey + dy2 * L2 / 2, L2, 0.03, lc, s * 62)
		end
	end
	P(r, "ellipse", 0.5, 0.63, 0.34, 0.38, bc, 0, 165)
	P(r, "ellipse", 0.5, 0.37, 0.22, 0.19, mix(bc, p.g, 0.12), 0, 175)
	P(r, "round", 0.5, 0.65, 0.09, 0.09, p.g, 45)
	P(r, "ellipse", 0.455, 0.355, 0.04, 0.04, C(255, 236, 232))
	P(r, "ellipse", 0.545, 0.355, 0.04, 0.04, C(255, 236, 232))
	HL(r, 0.42, 0.55, 0.07, 0.14, 15, 0.72)
end

Icons.hat = function(r, p)
	local dk = C(24, 10, 40)
	local cc, cd = mix(p.a, dk, 0.45), mix(p.a, dk, 0.62)
	P(r, "round", 0.41, 0.46, 0.26, 0.66, cc, 11, 180)
	P(r, "round", 0.59, 0.46, 0.26, 0.66, cc, -11, 180)
	P(r, "round", 0.57, 0.12, 0.11, 0.22, cc, 38, 170)
	P(r, "rect", 0.5, 0.69, 0.42, 0.075, mix(p.g, p.a, 0.35))
	P(r, "round", 0.5, 0.69, 0.10, 0.11, C(244, 204, 84))
	P(r, "round", 0.5, 0.69, 0.05, 0.06, cd)
	P(r, "ellipse", 0.5, 0.80, 0.92, 0.17, cd, 0, 170)
end

Icons.potion = function(r, p)
	local gl = C(200, 228, 246)
	P(r, "round", 0.5, 0.31, 0.18, 0.32, gl, 0, 200)
	P(r, "ellipse", 0.5, 0.66, 0.62, 0.62, gl, 0, 200)
	P(r, "ellipse", 0.5, 0.70, 0.52, 0.50, p.a, 0, 170)
	P(r, "ellipse", 0.42, 0.64, 0.07, 0.07, p.g)
	P(r, "ellipse", 0.58, 0.74, 0.05, 0.05, p.g)
	P(r, "ellipse", 0.52, 0.80, 0.04, 0.04, p.g)
	P(r, "round", 0.5, 0.14, 0.20, 0.10, C(158, 108, 64), 0, 170)
	HL(r, 0.34, 0.60, 0.07, 0.22, 14)
end

Icons.bone = function(r, p)
	local b1 = C(238, 232, 214)
	local th = math.rad(-40)
	local dx, dy = math.cos(th), math.sin(th)
	local px, py = -dy, dx
	P(r, "round", 0.5, 0.5, 0.68, 0.15, b1, -40, 190)
	for _, e in ipairs({ -1, 1 }) do
		for _, q in ipairs({ -1, 1 }) do
			P(r, "ellipse", 0.5 + dx * e * 0.34 + px * q * 0.065, 0.5 + dy * e * 0.34 + py * q * 0.065, 0.17, 0.17, b1, 0, 190)
		end
	end
end

Icons.flame = function(r, p)
	P(r, "ellipse", 0.5, 0.66, 0.52, 0.52, p.a, 0, 190)
	P(r, "ellipse", 0.52, 0.36, 0.22, 0.50, p.a, 10, 190)
	P(r, "ellipse", 0.5, 0.70, 0.32, 0.34, p.g)
	P(r, "ellipse", 0.5, 0.74, 0.16, 0.20, C(255, 252, 235))
end

Icons.candle = function(r, p)
	local wax = C(238, 230, 206)
	P(r, "ellipse", 0.5, 0.92, 0.62, 0.10, mix(p.d, BLACK, 0.4), 0, 170)
	P(r, "round", 0.5, 0.69, 0.28, 0.46, wax, 0, 175)
	P(r, "ellipse", 0.42, 0.50, 0.07, 0.12, wax, 0, 200)
	P(r, "rect", 0.5, 0.435, 0.016, 0.07, C(40, 30, 24))
	P(r, "ellipse", 0.5, 0.29, 0.16, 0.28, p.a, 0, 190)
	P(r, "ellipse", 0.5, 0.32, 0.08, 0.16, p.g)
end

Icons.orb = function(r, p)
	local dk = C(20, 10, 30)
	P(r, "round", 0.5, 0.87, 0.58, 0.16, mix(p.a, dk, 0.55), 0, 170)
	P(r, "ellipse", 0.5, 0.48, 0.76, 0.76, mix(p.a, dk, 0.35), 0, 150)
	P(r, "ellipse", 0.5, 0.50, 0.64, 0.64, p.a, 0, 185)
	local gl = P(r, "ellipse", 0.5, 0.58, 0.38, 0.34, p.g)
	gl.BackgroundTransparency = 0.4
	HL(r, 0.33, 0.30, 0.14, 0.20, 30, 0.5)
end

Icons.moon = function(r, p)
	P(r, "ellipse", 0.5, 0.5, 0.84, 0.84, C(246, 238, 196), 0, 200)
	P(r, "ellipse", 0.37, 0.37, 0.18, 0.18, C(214, 204, 160))
	P(r, "ellipse", 0.63, 0.58, 0.22, 0.22, C(214, 204, 160))
	P(r, "ellipse", 0.40, 0.70, 0.11, 0.11, C(214, 204, 160))
	HL(r, 0.28, 0.5, 0.05, 0.3, 0, 0.6)
end

Icons.drop = function(r, p)
	local red = C(204, 16, 40)
	P(r, "round", 0.5, 0.36, 0.30, 0.30, red, 45, 190)
	P(r, "ellipse", 0.5, 0.63, 0.50, 0.50, red, 0, 190)
	HL(r, 0.37, 0.64, 0.09, 0.20, 12)
end

Icons.bolt = function(r, p)
	local y1, y2 = C(255, 226, 84), C(255, 250, 214)
	P(r, "round", 0.58, 0.30, 0.20, 0.48, y1, 24, 190)
	P(r, "round", 0.50, 0.52, 0.42, 0.13, y1, -8, 190)
	P(r, "round", 0.42, 0.73, 0.20, 0.46, y1, 24, 190)
	P(r, "round", 0.58, 0.30, 0.07, 0.38, y2, 24)
	P(r, "round", 0.42, 0.73, 0.07, 0.36, y2, 24)
end

Icons.star = function(r, p)
	P(r, "ellipse", 0.5, 0.5, 0.13, 0.92, p.g)
	P(r, "ellipse", 0.5, 0.5, 0.92, 0.13, p.g)
	P(r, "ellipse", 0.5, 0.5, 0.08, 0.56, p.g, 45)
	P(r, "ellipse", 0.5, 0.5, 0.08, 0.56, p.g, -45)
	P(r, "ellipse", 0.5, 0.5, 0.20, 0.20, Color3.new(1, 1, 1))
end

Icons.leaf = function(r, p)
	P(r, "ellipse", 0.5, 0.5, 0.40, 0.80, C(206, 98, 24), 38, 175)
	P(r, "ellipse", 0.53, 0.46, 0.17, 0.58, C(238, 146, 44), 38)
	P(r, "rect", 0.5, 0.5, 0.025, 0.72, C(140, 60, 12), 38)
	P(r, "rect", 0.21, 0.86, 0.035, 0.15, C(110, 70, 30), 38)
end

Icons.flake = function(r, p)
	local col = C(214, 240, 255)
	for _, a in ipairs({ 0, 60, 120 }) do P(r, "ellipse", 0.5, 0.5, 0.07, 0.90, col, a) end
	P(r, "ellipse", 0.5, 0.5, 0.20, 0.20, Color3.new(1, 1, 1))
end

Icons.gear = function(r, p)
	local col = C(182, 190, 206)
	for _, a in ipairs({ 0, 45, 90, 135 }) do P(r, "round", 0.5, 0.5, 0.20, 0.92, col, a, 190) end
	P(r, "ellipse", 0.5, 0.5, 0.68, 0.68, col, 0, 190)
	P(r, "ellipse", 0.5, 0.5, 0.30, 0.30, mix(p.bg, BLACK, 0.35))
end

Icons.palette = function(r, p)
	P(r, "ellipse", 0.5, 0.52, 0.90, 0.74, C(214, 172, 124), 0, 190)
	P(r, "ellipse", 0.70, 0.66, 0.16, 0.14, mix(p.bg, BLACK, 0.3))
	P(r, "ellipse", 0.28, 0.42, 0.14, 0.14, p.a)
	P(r, "ellipse", 0.46, 0.30, 0.14, 0.14, p.g)
	P(r, "ellipse", 0.66, 0.34, 0.14, 0.14, p.d)
	P(r, "ellipse", 0.30, 0.64, 0.13, 0.13, C(120, 200, 120))
end

Icons.dice = function(r, p)
	local dk = C(32, 24, 30)
	P(r, "round", 0.5, 0.5, 0.72, 0.72, C(244, 240, 228), 12, 195)
	local pips = { { 0.5, 0.5 }, { 0.34, 0.34 }, { 0.66, 0.66 }, { 0.66, 0.34 }, { 0.34, 0.66 } }
	for _, q in ipairs(pips) do
		-- rotate pip positions by 12 degrees around the centre to match the die
		local c, s = math.cos(math.rad(12)), math.sin(math.rad(12))
		local x, y = q[1] - 0.5, q[2] - 0.5
		P(r, "ellipse", 0.5 + x * c - y * s, 0.5 + x * s + y * c, 0.11, 0.11, dk)
	end
end

Icons.check = function(r, p)
	local g = C(125, 225, 110)
	P(r, "ellipse", 0.30, 0.65, 0.30, 0.13, g, 45)
	P(r, "ellipse", 0.60, 0.525, 0.62, 0.13, g, -48)
end

Icons.warn = function(r, p)
	local dk = C(40, 28, 10)
	P(r, "round", 0.5, 0.5, 0.64, 0.64, C(255, 205, 60), 45, 195)
	P(r, "round", 0.5, 0.44, 0.08, 0.26, dk)
	P(r, "ellipse", 0.5, 0.66, 0.09, 0.09, dk)
end

local function drawInto(root, name, pal)
	for _, c in ipairs(root:GetChildren()) do c:Destroy() end
	local fn = Icons[name]
	if fn then
		fn(root, pal or palette())
	elseif name then
		label({ Text = tostring(name), TextScaled = true, Size = UDim2.new(1, 0, 1, 0) }, root)
	end
end

-- o: Size (number or UDim2), Position, AnchorPoint, ZIndex, Rotation, Pal
local function mkIcon(name, parent, o)
	o = o or {}
	local sz = o.Size or 24
	local root = new("CanvasGroup", {
		AnchorPoint = o.AnchorPoint or Vector2.new(0, 0), Position = o.Position or UDim2.new(0, 0, 0, 0),
		Size = (typeof(sz) == "number") and UDim2.new(0, sz, 0, sz) or sz,
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = o.ZIndex or 1, Rotation = o.Rotation or 0,
	}, parent)
	if name then drawInto(root, name, o.Pal) end
	return root
end
Hallow.DrawIcon = mkIcon

-- a swarm of drawn icons blasting out of a point (bats, pumpkins, leaves, ghosts...)
local function burst(parent, iconName, count, o)
	o = o or {}
	local life = o.Life or 2
	local minS, maxS = o.MinSpeed or 260, o.MaxSpeed or 760
	local s0 = o.Size0 or 18
	local pal = palette()
	local items = {}
	for i = 1, count do
		local a = math.random() * math.pi * 2
		local sp = minS + math.random() * (maxS - minS)
		items[i] = {
			l = mkIcon(iconName, parent, { Size = s0, AnchorPoint = CENTER, ZIndex = 8, Pal = pal }),
			x = 0, y = 0,
			vx = math.cos(a) * sp, vy = math.sin(a) * sp - (o.Lift or 140),
			ph = math.random() * 6.28,
			life = life * (0.7 + math.random() * 0.6), age = 0,
			s0 = s0, s1 = (o.Size1 or 54) * (0.7 + math.random() * 0.5),
		}
	end
	task.spawn(function()
		local alive = true
		while alive do
			local dt = RunService.RenderStepped:Wait()
			alive = false
			for _, b in ipairs(items) do
				local l = b.l
				if l and l.Parent then
					b.age += dt
					if b.age >= b.life then
						l:Destroy()
					else
						alive = true
						local k = b.age / b.life
						local drag = 1 - math.min(1, 0.8 * dt)
						b.vx *= drag
						b.vy = b.vy * drag - 40 * dt
						b.x += b.vx * dt
						b.y += b.vy * dt
						local sp = math.sqrt(b.vx * b.vx + b.vy * b.vy) + 1
						local fl = math.sin(b.age * 16 + b.ph)
						local sz = math.floor(b.s0 + (b.s1 - b.s0) * k)
						l.Size = UDim2.new(0, sz, 0, sz)
						l.Position = UDim2.new(0, b.x + (-b.vy / sp) * fl * 9, 0, b.y + (b.vx / sp) * fl * 9)
						l.Rotation = fl * 22 + (b.vx / sp) * 15
						l.GroupTransparency = (k > 0.65) and ((k - 0.65) / 0.35) or 0
					end
				end
			end
		end
	end)
end

-- =======================================================================
--   NOTIFICATIONS (slide-in toasts, raised on a slab)
-- =======================================================================
local NotifyHolder

function Hallow:Notify(cfg)
	if not NotifyHolder or not NotifyHolder.Parent then return end
	cfg = cfg or {}
	local title    = cfg.Title or cfg.title or "Notification"
	local text     = cfg.Content or cfg.content or ""
	local duration = cfg.Duration or cfg.duration or 4
	local kind     = string.lower(tostring(cfg.Type or cfg.type or "info"))
	local accent   = ({ info = Theme.Glow, success = Theme.Success, warn = Theme.Warn, error = Theme.Danger })[kind] or Theme.Glow
	local icon     = ({ info = "candle", success = "check", warn = "warn", error = "skull" })[kind] or "candle"

	playSound(Hallow.Sounds.Notify, 1, 0.9)

	local textH = TextService:GetTextSize(text, 12, Reg, Vector2.new(250, 10000)).Y
	local height = math.max(64, 40 + textH + 16)
	local DEPTH = 6

	local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, height + DEPTH), BackgroundTransparency = 1 }, NotifyHolder)
	local mover = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(1.2, 0, 0, 0), BackgroundTransparency = 1,
	}, wrap)
	local slab = new("Frame", {
		Position = UDim2.new(0, 0, 0, DEPTH), Size = UDim2.new(1, 0, 1, -DEPTH),
		BackgroundColor3 = mix(accent, BLACK, 0.62), BorderSizePixel = 0, ZIndex = 1,
	}, mover)
	round(slab, UDim.new(0, 10))
	local toast = new("Frame", {
		Size = UDim2.new(1, 0, 1, -DEPTH),
		BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.03,
		BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2,
	}, mover)
	round(toast, UDim.new(0, 10))
	bevel(toast, 190)
	rimLight(outline(toast, accent, 1.5, 0.1))

	new("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0 }, toast)
	mkIcon(icon, toast, {
		Size = 26, Position = UDim2.new(0, 14, 0, 8),
		Pal = { a = accent, g = accent, d = accent, bg = Theme.Bg, t = Theme.Text },
	})
	label({
		Text = title, Font = Bold, TextSize = 14, TextColor3 = accent, TextXAlignment = Left,
		Position = UDim2.new(0, 46, 0, 10), Size = UDim2.new(1, -56, 0, 18),
	}, toast)
	label({
		Text = text, TextSize = 12, TextColor3 = Theme.Muted, TextXAlignment = Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
		Position = UDim2.new(0, 46, 0, 31), Size = UDim2.new(1, -58, 0, textH),
	}, toast)

	local bar = new("Frame", {
		Position = UDim2.new(0, 14, 1, -7), Size = UDim2.new(1, -28, 0, 2),
		BackgroundColor3 = accent, BackgroundTransparency = 0.25, BorderSizePixel = 0,
	}, toast)
	round(bar)

	tw(mover, { Position = UDim2.new(0, 0, 0, 0) }, 0.45, Easing.Back)
	tw(bar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Easing.Linear)

	local dismissed = false
	local function dismiss()
		if dismissed then return end
		dismissed = true
		local out = tw(mover, { Position = UDim2.new(1.2, 0, 0, 0) }, 0.3, Easing.Back, Dir.In)
		out.Completed:Connect(function()
			local shrink = tw(wrap, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
			shrink.Completed:Connect(function() wrap:Destroy() end)
		end)
	end

	local catcher = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5 }, toast)
	catcher.MouseButton1Click:Connect(dismiss)
	task.delay(duration, dismiss)
end

-- =======================================================================
--   CREATE WINDOW
-- =======================================================================
function Hallow:CreateWindow(cfg)
	cfg = cfg or {}
	local W = tonumber(cfg.Width) or 660
	local H = tonumber(cfg.Height) or 440
	local winTitle = tostring(cfg.Title or "THE GRIMOIRE")
	local winSub = tostring(cfg.Subtitle or "halloween edition")
	local toggleKey = cfg.ToggleKey
	if toggleKey == nil then toggleKey = Enum.KeyCode.RightShift end -- pass false to disable
	local introOn = cfg.Intro ~= false
	local FX = {
		Embers = cfg.Embers ~= false, Floaters = cfg.Floaters ~= false, Fog = cfg.Fog ~= false,
		Parallax = cfg.Parallax ~= false,
	}

	-- theme: explicit > saved > Pumpkin
	local startTheme = cfg.Theme
	if not startTheme and cfg.RememberTheme ~= false and typeof(readfile) == "function" then
		local ok, saved = pcall(readfile, "Grimoire_Theme.txt")
		if ok and type(saved) == "string" and Hallow.Themes[saved] then startTheme = saved end
	end
	if not Hallow.Themes[startTheme or ""] then startTheme = "Pumpkin" end
	loadTheme(startTheme)

	-- remove any previous copy
	for _, p in ipairs(candidateParents()) do
		local old = p:FindFirstChild(GUI_NAME)
		if old then pcall(function() old:Destroy() end) end
	end

	local Win = {
		Tabs = {}, ThemeName = startTheme, Current = nil,
		Started = false, InIntro = false, Minimized = false, Busy = false, Destroyed = false, Listening = false,
	}

	local conns = {}
	local function track(c) conns[#conns + 1] = c return c end

	-- ---------- live theming ----------
	local appliers = {}
	local function themed(fn) appliers[#appliers + 1] = fn; fn(true) end
	local function bindTheme(inst, map)
		themed(function(i)
			local p = {}
			for prop, key in pairs(map) do p[prop] = Theme[key] end
			paint(inst, p, i)
		end)
		return inst
	end
	local function tl(props, parent, key) -- themed label
		local l = label(props, parent)
		if key then bindTheme(l, { TextColor3 = key }) end
		return l
	end
	-- icon that re-draws itself whenever the theme changes (name = nil -> follows the theme's main icon)
	local function themedIcon(parent, name, o)
		local root = mkIcon(nil, parent, o)
		themed(function() drawInto(root, name or Theme.Icon, (o and o.Pal) or palette()) end)
		return root
	end

	local spinners = {}
	local function sweep(stroke, speed)
		local g = new("UIGradient", { Color = SWEEP, Rotation = math.random(0, 359) }, stroke)
		spinners[#spinners + 1] = { g = g, speed = speed or 50 }
		return g
	end

	-- =====================================================================
	--   LAYERS
	-- =====================================================================
	local ScreenGui = new("ScreenGui", {
		Name = GUI_NAME, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true, DisplayOrder = 999,
	})

	local Dim = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = BLACK,
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1,
	}, ScreenGui)

	local Flash = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 50,
	}, ScreenGui)

	NotifyHolder = new("Frame", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -22),
		Size = UDim2.new(0, 320, 1, -44), BackgroundTransparency = 1, ZIndex = 60,
	}, ScreenGui)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 10),
	}, NotifyHolder)

	-- intro stage (zero-size, screen centre; sits above the window)
	local Stage = new("Frame", {
		AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1, ZIndex = 10,
	}, ScreenGui)
	local StageScale = new("UIScale", nil, Stage)

	-- root: everything that belongs to the window (draggable)
	local Root = new("Frame", {
		Name = "Root", AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, W, 0, H), BackgroundTransparency = 1, Visible = false, ZIndex = 5,
	}, ScreenGui)
	local RootScale = new("UIScale", nil, Root)

	local RootFX = new("Frame", { -- zero-size, Root centre: shockwaves & swarms
		AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1, ZIndex = 25,
	}, Root)

	-- scaling to fit the viewport
	local userScale = 1
	local scaled = { RootScale, StageScale }
	local function applyScale()
		local cam = Workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local s = math.clamp(math.min(vp.X / (W + 70), vp.Y / (H + 90)), 0.4, 1) * userScale
		for _, u in ipairs(scaled) do u.Scale = s end
	end
	applyScale()
	if Workspace.CurrentCamera then
		track(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale))
	end

	-- ambient glow behind the window (follows the window's live size)
	local GLOW_PADS, GLOW_BASE = { 20, 48, 88 }, { 0.86, 0.93, 0.968 }
	local Glow = {}
	for i = 1, 3 do
		local g = new("Frame", {
			AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1,
		}, Root)
		round(g, UDim.new(0, 14 + GLOW_PADS[i]))
		Glow[i] = g
	end
	local glowTarget, glowI = 0, 0

	-- cast shadow on the "ground" (soft stacked layers, shifts with the cursor)
	local Shadow = {}
	for i = 1, 5 do
		local s = new("Frame", {
			AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 24), Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = BLACK, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
		}, Root)
		round(s, UDim.new(0, 14 + i * 7))
		Shadow[i] = s
	end

	-- the extruded slab: stacked copies behind the window give it real thickness
	local SLABS = 9
	local Slab = {}
	for k = SLABS, 1, -1 do
		local s = new("Frame", {
			AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Theme.Border, BorderSizePixel = 0, ZIndex = 3 + (SLABS - k),
		}, Root)
		round(s, UDim.new(0, 14))
		Slab[k] = s
	end
	local function slabColor(k) return mix(Theme.Border, BLACK, (k - 1) / (SLABS - 1) * 0.82) end
	themed(function(i)
		for k = 1, SLABS do paint(Slab[k], { BackgroundColor3 = slabColor(k) }, i) end
	end)
	-- bright edge on the front lip of the slab
	local SlabLip = outline(Slab[1], Theme.Accent, 1.2, 0.55)
	bindTheme(SlabLip, { Color = "Accent" })

	-- =====================================================================
	--   THE WINDOW
	-- =====================================================================
	local Window = new("Frame", {
		Name = "Window", AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, W, 0, H), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 20,
	}, Root)
	round(Window, UDim.new(0, 14))
	bevel(Window, 200)
	local WinStroke = outline(Window, Theme.Glow, 2.5, 0.05)
	sweep(WinStroke, 42)
	bindTheme(Window, { BackgroundColor3 = "Bg" })
	bindTheme(WinStroke, { Color = "Glow" })

	-- Body has a FIXED size, so when the Window width animates it looks like a door opening
	local Body = new("Frame", {
		AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, W, 0, H),
		BackgroundTransparency = 1,
	}, Window)

	local FXLayer = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 1 }, Body)

	-- fog blobs
	local fogBlobs = {}
	for i = 1, 7 do
		local bw, bh = math.random(240, 360), math.random(90, 130)
		local f = new("Frame", {
			Size = UDim2.new(0, bw, 0, bh), BackgroundColor3 = Theme.Fog,
			BackgroundTransparency = 0.925, BorderSizePixel = 0, ZIndex = 1,
		}, FXLayer)
		round(f)
		bindTheme(f, { BackgroundColor3 = "Fog" })
		fogBlobs[i] = { f = f, x0 = math.random(-60, W - 200), y = H - math.random(70, 120),
			amp = math.random(50, 140), sp = 0.12 + math.random() * 0.2, ph = math.random() * 6.28 }
	end

	-- ---------- header ----------
	local TAB_H, TAB_GAP, SB_W = 42, 4, 150
	local TitleL

	local Header = new("Frame", {
		Name = "Header", Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0, ZIndex = 3, Active = true,
	}, Body)
	round(Header, UDim.new(0, 14))
	bindTheme(Header, { BackgroundColor3 = "Panel" })
	local HeaderFill = new("Frame", { -- squares off the header's bottom corners
		Position = UDim2.new(0, 0, 1, -16), Size = UDim2.new(1, 0, 0, 16),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, ZIndex = 3,
	}, Header)
	bindTheme(HeaderFill, { BackgroundColor3 = "Panel" })
	local HeaderLine = new("Frame", {
		Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 4,
	}, Header)
	bindTheme(HeaderLine, { BackgroundColor3 = "Accent" })
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.92), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 0.92),
		}),
	}, HeaderLine)
	-- header "shelf": a shadow strip under the header so the content sits lower than the bar
	local HeaderShade = new("Frame", {
		Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 3,
	}, Header)
	new("UIGradient", {
		Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) }),
	}, HeaderShade)

	-- the header icon sits on a little raised medallion
	local Medal = new("Frame", {
		Position = UDim2.new(0, 10, 0.5, -20), Size = UDim2.new(0, 40, 0, 40), BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0, ZIndex = 4,
	}, Header)
	round(Medal)
	bevel(Medal, 170)
	bindTheme(Medal, { BackgroundColor3 = "Card" })
	rimLight(outline(Medal, Theme.Accent, 1.5, 0.3))
	themedIcon(Medal, nil, { Size = 30, AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), ZIndex = 5 })

	TitleL = tl({
		Text = "", Font = Bold, TextSize = 17, TextXAlignment = Left,
		Position = UDim2.new(0, 60, 0, 10), Size = UDim2.new(0, 300, 0, 22), ZIndex = 5,
	}, Header, "Glow")
	tl({
		Text = winSub, TextSize = 11, TextXAlignment = Left,
		Position = UDim2.new(0, 60, 0, 32), Size = UDim2.new(0, 300, 0, 14), ZIndex = 5,
	}, Header, "Muted")

	local function headerBtn(kind, xOff, danger)
		local b = new("TextButton", {
			Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, xOff, 0.5, -14),
			BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 6,
		}, Header)
		round(b)
		bevel(b, 175)
		local st = outline(b, Theme.Border, 1.2)
		local bars = {}
		local function bar(rot, wd)
			local f = new("Frame", {
				AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, wd, 0, 2.6),
				Rotation = rot, BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, ZIndex = 7,
			}, b)
			round(f)
			bars[#bars + 1] = f
		end
		if kind == "min" then bar(0, 12) else bar(45, 14); bar(-45, 14) end
		local hov = false
		local function rp(i, dur)
			local col = danger and Theme.Danger or Theme.Glow
			paint(b, { BackgroundColor3 = hov and Theme.CardHover or Theme.Card }, i, dur)
			paint(st, { Color = hov and col or Theme.Border }, i, dur)
			for _, f in ipairs(bars) do paint(f, { BackgroundColor3 = hov and col or Theme.Muted }, i, dur) end
		end
		themed(rp)
		b.MouseEnter:Connect(function() hov = true; playHoverSound(1.7, 0.35); rp(false, 0.12) end)
		b.MouseLeave:Connect(function() hov = false; rp(false, 0.15) end)
		return b
	end
	local MinBtn = headerBtn("min", -78, false)
	local CloseBtn = headerBtn("close", -42, true)

	-- dragging (header drags the whole Root)
	do
		local dragging, dragStart, startPos = false, nil, nil
		Header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, dragStart, startPos = true, input.Position, Root.Position
			end
		end)
		track(UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - dragStart
				Root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end))
		track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
	end

	-- ---------- sidebar ----------
	local TabScroll, Indicator, Highlight
	do
		local Sidebar = new("Frame", {
			Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(0, SB_W, 1, -56), BackgroundTransparency = 1, ZIndex = 3,
		}, Body)
		local sbLine = new("Frame", {
			Position = UDim2.new(1, -1, 0, 10), Size = UDim2.new(0, 1, 1, -20),
			BackgroundColor3 = Theme.Border, BorderSizePixel = 0, ZIndex = 3,
		}, Sidebar)
		bindTheme(sbLine, { BackgroundColor3 = "Border" })

		TabScroll = new("ScrollingFrame", {
			Position = UDim2.new(0, 0, 0, 10), Size = UDim2.new(1, -2, 1, -66), BackgroundTransparency = 1,
			BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 3,
		}, Sidebar)

		Highlight = new("Frame", {
			Visible = false, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -12, 0, TAB_H),
			BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 2,
		}, TabScroll)
		round(Highlight, UDim.new(0, 8))
		bindTheme(Highlight, { BackgroundColor3 = "Accent" })
		new("UIGradient", {
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.62), NumberSequenceKeypoint.new(1, 1) }),
		}, Highlight)

		Indicator = new("Frame", {
			Visible = false, Position = UDim2.new(0, 1, 0, 0), Size = UDim2.new(0, 3, 0, 22),
			BackgroundColor3 = Theme.Glow, BorderSizePixel = 0, ZIndex = 4,
		}, TabScroll)
		round(Indicator)
		bindTheme(Indicator, { BackgroundColor3 = "Glow" })

		local footer = new("Frame", {
			Position = UDim2.new(0, 0, 1, -52), Size = UDim2.new(1, -2, 0, 52), BackgroundTransparency = 1, ZIndex = 3,
		}, Sidebar)
		mkIcon("candle", footer, { Size = 20, Position = UDim2.new(0, 12, 0, 6), ZIndex = 3 })
		tl({
			Text = tostring(localPlayer.DisplayName), Font = Semi, TextSize = 12, TextXAlignment = Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0, 38, 0, 8), Size = UDim2.new(1, -46, 0, 18), ZIndex = 3,
		}, footer, "Text")
		tl({
			Text = toggleKey and (toggleKey.Name .. " to hide") or "", TextSize = 10, TextXAlignment = Left,
			Position = UDim2.new(0, 14, 0, 29), Size = UDim2.new(1, -22, 0, 14), ZIndex = 3,
		}, footer, "Muted")
	end

	local Content = new("Frame", {
		Position = UDim2.new(0, SB_W + 8, 0, 64), Size = UDim2.new(1, -(SB_W + 16), 1, -72),
		BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3,
	}, Body)
	local PAGE_W = W - SB_W - 16

	-- =====================================================================
	--   HANGING MASCOT (spider / bat / skull / ghost / orb ...)
	-- =====================================================================
	local SPIDER_LEN = 38
	local SpiderRoot = new("Frame", {
		Name = "Mascot", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0, W - 150, 0, 3),
		Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 30,
	}, Root)
	local Thread = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 2, 0, 0), BackgroundColor3 = Theme.Muted,
		BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 4,
	}, SpiderRoot)
	bindTheme(Thread, { BackgroundColor3 = "Muted" })
	local Bug = mkIcon(Theme.Mascot, SpiderRoot, {
		Size = 38, AnchorPoint = Vector2.new(0.5, 0.1), Position = UDim2.new(0, 0, 0, 0),
		Rotation = Theme.MascotRot or 0, ZIndex = 5,
	})
	Bug.GroupTransparency = 1

	local function setSpider(len, dur, style, dir)
		if len > 0 then Bug.GroupTransparency = 0 end
		tw(Thread, { Size = UDim2.new(0, 2, 0, len) }, dur, style, dir)
		local t = tw(Bug, { Position = UDim2.new(0, 0, 0, len) }, dur, style, dir)
		if len <= 0 then
			t.Completed:Connect(function() Bug.GroupTransparency = 1 end)
		end
	end

	-- =====================================================================
	--   FLOATING ORB (reopen button) - a glossy sphere on a shadow
	-- =====================================================================
	local orbHome = UDim2.new(0.5, 0, 0, 14)
	local Orb = new("Frame", {
		Name = "Orb", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -110),
		Size = UDim2.new(0, 64, 0, 64), BackgroundTransparency = 1, Active = true, Visible = false, ZIndex = 20,
	}, ScreenGui)
	local OrbShadow = new("Frame", {
		AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 1, 14), Size = UDim2.new(0, 38, 0, 9),
		BackgroundColor3 = BLACK, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 1,
	}, Orb)
	round(OrbShadow)
	local OrbHalo = new("Frame", {
		AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
	}, Orb)
	round(OrbHalo)
	local OrbHaloS = outline(OrbHalo, Theme.Accent, 2, 0.5)
	local OrbBase = new("Frame", {
		AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 5), Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Dark, BorderSizePixel = 0, ZIndex = 1,
	}, Orb)
	round(OrbBase)
	bevel(OrbBase, 120)
	bindTheme(OrbBase, { BackgroundColor3 = "Dark" })
	local Bob = new("Frame", {
		AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, ZIndex = 2,
	}, Orb)
	round(Bob)
	bevel(Bob, 175)
	bindTheme(Bob, { BackgroundColor3 = "Bg" })
	local BobScale = new("UIScale", nil, Bob)
	local OrbStroke = outline(Bob, Theme.Glow, 3)
	sweep(OrbStroke, 95)
	bindTheme(OrbStroke, { Color = "Glow" })
	themedIcon(Bob, nil, { Size = 40, AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0.5, 0), ZIndex = 2 })
	local OrbGloss = new("Frame", {
		AnchorPoint = CENTER, Position = UDim2.new(0.30, 0, 0.22, 0), Size = UDim2.new(0, 24, 0, 11), Rotation = -35,
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 3,
	}, Bob)
	round(OrbGloss)
	local OrbTip = tl({
		Text = "OPEN", Font = Bold, TextSize = 11, TextTransparency = 1, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 24), Size = UDim2.new(0, 120, 0, 16),
	}, Orb, "Glow")

	local function showOrb()
		Orb.Position = UDim2.new(orbHome.X.Scale, orbHome.X.Offset, 0, -110)
		Orb.Visible = true
		tw(Orb, { Position = orbHome }, 0.55, Easing.Back)
	end
	local function hideOrb()
		local t = tw(Orb, { Position = UDim2.new(orbHome.X.Scale, orbHome.X.Offset, 0, -110) }, 0.3, Easing.Back, Dir.In)
		t.Completed:Connect(function() if not Win.Minimized then Orb.Visible = false end end)
	end

	Orb.MouseEnter:Connect(function()
		tw(BobScale, { Scale = 1.14 }, 0.15, Easing.Back)
		tw(OrbTip, { TextTransparency = 0 }, 0.15)
		playHoverSound(1.6, 0.4)
	end)
	Orb.MouseLeave:Connect(function()
		tw(BobScale, { Scale = 1 }, 0.15)
		tw(OrbTip, { TextTransparency = 1 }, 0.15)
	end)

	-- =====================================================================
	--   EFFECT HELPERS (need the layers above)
	-- =====================================================================
	local function lightning(power)
		power = power or 1
		task.spawn(function()
			Flash.BackgroundColor3 = Color3.new(1, 1, 1):Lerp(Theme.Glow, 0.25)
			Flash.BackgroundTransparency = 1 - 0.55 * power
			tw(Flash, { BackgroundTransparency = 1 }, 0.12)
			task.wait(0.15)
			Flash.BackgroundTransparency = 1 - 0.8 * power
			tw(Flash, { BackgroundTransparency = 1 }, 0.5)
		end)
		playSound(Hallow.Sounds.Thunder, 0.5, 1)
	end

	local function shake(target, power, dur)
		task.spawn(function()
			local base = target.Position
			local t = 0
			while t < dur do
				local dt = RunService.RenderStepped:Wait()
				t += dt
				local k = 1 - t / dur
				target.Position = UDim2.new(
					base.X.Scale, base.X.Offset + (math.random() - 0.5) * 2 * power * k,
					base.Y.Scale, base.Y.Offset + (math.random() - 0.5) * 2 * power * k)
			end
			target.Position = base
		end)
	end

	local function scramble(lbl, text)
		local pool = "#%&@$?/\\|<>~^*+="
		local n = utf8.len(text) or #text
		for i = 1, n do
			for _ = 1, 2 do
				if not lbl.Parent then return end
				local r = math.random(#pool)
				lbl.Text = ssub(text, i - 1) .. string.sub(pool, r, r)
				task.wait(0.025)
			end
		end
		if lbl.Parent then lbl.Text = text end
	end

	local function openWindow()
		Root.Visible = true
		Window.BackgroundColor3 = Theme.Glow
		Window.Size = UDim2.new(0, 3, 0, 0)
		glowTarget = 1
		playSound(Hallow.Sounds.Open, 1.1, 0.9)
		tw(Window, { Size = UDim2.new(0, 3, 0, H) }, 0.35, Easing.Quint)
		task.wait(0.3)
		shockwave(RootFX, Theme.Glow, 60, W * 1.1, 0.7, 3)
		tw(Window, { Size = UDim2.new(0, W, 0, H), BackgroundColor3 = Theme.Bg }, 0.7, Easing.Quint)
		task.wait(0.6)
	end

	local function closeWindow()
		glowTarget = 0
		tw(Window, { Size = UDim2.new(0, 3, 0, H), BackgroundColor3 = Theme.Glow }, 0.4, Easing.Quint, Dir.In)
		task.wait(0.4)
		tw(Window, { Size = UDim2.new(0, 3, 0, 0) }, 0.22, Easing.Quint, Dir.In)
		task.wait(0.22)
		Root.Visible = false
	end

	local function spawnEmber()
		local size = math.random(3, 5)
		local sx = math.random(20, W - 20)
		local rise = math.random(160, 320)
		local life = 2.4 + math.random() * 1.6
		local e = new("Frame", {
			AnchorPoint = CENTER, Position = UDim2.new(0, sx, 0, H + 6), Size = UDim2.new(0, size, 0, size),
			BackgroundColor3 = (math.random() < 0.5) and Theme.Glow or Theme.Accent,
			BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1,
		}, FXLayer)
		round(e)
		tw(e, { BackgroundTransparency = 0.2 }, 0.4)
		tw(e, { Position = UDim2.new(0, sx + math.random(-50, 50), 0, H - rise), Size = UDim2.new(0, 1, 0, 1) }, life, Easing.Sine)
		task.delay(life * 0.55, function() if e.Parent then tw(e, { BackgroundTransparency = 1 }, life * 0.45) end end)
		Debris:AddItem(e, life + 0.1)
	end

	local floaters = {}
	local function spawnFloater()
		local list = Theme.Floaters or { "pumpkin" }
		local sz = math.random(20, 32)
		local l = mkIcon(list[math.random(#list)], FXLayer, { Size = sz, AnchorPoint = CENTER, ZIndex = 1 })
		l.GroupTransparency = 1
		floaters[#floaters + 1] = {
			l = l, x = math.random(40, W - 40), age = 0, life = 9 + math.random() * 6, ph = math.random() * 6.28,
		}
	end

	-- =====================================================================
	--   TABS
	-- =====================================================================
	local Current = nil

	local function moveIndicator(y, instant)
		local hp, ip = UDim2.new(0, 6, 0, y), UDim2.new(0, 1, 0, y + (TAB_H - 22) / 2)
		Highlight.Visible, Indicator.Visible = true, true
		if instant then
			Highlight.Position, Indicator.Position = hp, ip
		else
			tw(Highlight, { Position = hp }, 0.35, Easing.Quint)
			tw(Indicator, { Position = ip }, 0.4, Easing.Back)
		end
	end

	local function selectTab(tab)
		if Current == tab then return end
		local prev = Current
		Current = tab
		Win.Current = tab
		playSound(Hallow.Sounds.Click, 1.15, 0.7)
		if prev then
			prev.Page.Visible = false
			prev.Refresh(false, 0.2)
		end
		tab.Page.CanvasPosition = Vector2.new(0, 0)
		tab.Page.Visible = true
		tab.Refresh(false, 0.2)
		moveIndicator(tab.Y, prev == nil)
		-- cards slide in one after another
		for idx, h in ipairs(tab.Holders) do
			h.Card.Position = UDim2.new(0, 44, 0, 0)
			task.delay((idx - 1) * 0.035, function()
				tw(h.Card, { Position = UDim2.new(0, 0, 0, 0) }, 0.45, Easing.Quint)
			end)
		end
	end

	function Win:SelectTab(which)
		for i, tab in ipairs(self.Tabs) do
			if tab == which or tab.Title == which or i == which then selectTab(tab) return end
		end
	end

	-- ---------- element chrome (raised "keys": face + slab) ----------
	local DEPTH, REST, LIFT, PRESS = 5, 2, 0, 4

	local function makeHolder(tab, h)
		local Holder = new("Frame", {
			Size = UDim2.new(1, -10, 0, h), BackgroundTransparency = 1, LayoutOrder = #tab.Holders + 1,
		}, tab.Page)
		local Mover = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, Holder)
		tab.Holders[#tab.Holders + 1] = { Holder = Holder, Card = Mover }
		return Holder, Mover
	end

	local function makeCard(tab, h)
		local Holder, Mover = makeHolder(tab, h + DEPTH)

		local Base = new("Frame", {
			Position = UDim2.new(0, 0, 0, DEPTH), Size = UDim2.new(1, 0, 1, -DEPTH),
			BackgroundColor3 = Theme.Border, BorderSizePixel = 0, ZIndex = 1,
		}, Mover)
		round(Base, UDim.new(0, 10))

		local Card = new("Frame", {
			Position = UDim2.new(0, 0, 0, REST), Size = UDim2.new(1, 0, 1, -DEPTH),
			BackgroundColor3 = Theme.Card, BorderSizePixel = 0, ZIndex = 2,
		}, Mover)
		round(Card, UDim.new(0, 10))
		bevel(Card, 190)
		local stroke = outline(Card, Theme.Border, 1.2)
		rimLight(stroke)
		-- thin specular line along the top edge
		local gloss = new("Frame", {
			Position = UDim2.new(0, 10, 0, 1), Size = UDim2.new(1, -20, 0, 1),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 1,
		}, Card)
		new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1),
			}),
		}, gloss)
		local Pip = new("Frame", {
			Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, 7, 0.5, -9),
			BackgroundColor3 = Theme.Dark, BorderSizePixel = 0,
		}, Card)
		round(Pip)

		local hover = false
		local function repaint(i, dur)
			paint(Card, {
				BackgroundColor3 = hover and Theme.CardHover or Theme.Card,
				Position = UDim2.new(0, 0, 0, hover and LIFT or REST),
			}, i, dur)
			paint(Base, {
				BackgroundColor3 = hover and mix(Theme.Dark, BLACK, 0.2) or mix(Theme.Border, BLACK, 0.4),
			}, i, dur)
			paint(stroke, { Color = hover and Theme.Accent or Theme.Border }, i, dur)
			paint(Pip, {
				BackgroundColor3 = hover and Theme.Glow or Theme.Dark,
				Size = hover and UDim2.new(0, 3, 0, 28) or UDim2.new(0, 3, 0, 18),
				Position = hover and UDim2.new(0, 7, 0.5, -14) or UDim2.new(0, 7, 0.5, -9),
			}, i, dur)
		end
		themed(repaint)

		local count = 0
		local function bind(obj)
			obj.MouseEnter:Connect(function()
				count += 1
				if count == 1 then hover = true; playHoverSound(1.7, 0.3); repaint(false, 0.15) end
			end)
			obj.MouseLeave:Connect(function()
				count = math.max(0, count - 1)
				if count == 0 then hover = false; repaint(false, 0.2) end
			end)
		end
		bind(Mover)

		local function press(down)
			tw(Card, { Position = UDim2.new(0, 0, 0, down and PRESS or (hover and LIFT or REST)) }, down and 0.06 or 0.2, down and Easing.Quad or Easing.Back)
		end
		return Card, bind, repaint, Holder, press
	end

	local function ripple(card)
		local m = UserInputService:GetMouseLocation()
		local sc = RootScale.Scale
		local r = new("Frame", {
			AnchorPoint = CENTER,
			Position = UDim2.new(0, (m.X - card.AbsolutePosition.X) / sc, 0, (m.Y - card.AbsolutePosition.Y) / sc),
			Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Theme.Glow, BackgroundTransparency = 0.7,
			BorderSizePixel = 0, ZIndex = 1,
		}, card)
		round(r)
		tw(r, { Size = UDim2.new(0, 340, 0, 340), BackgroundTransparency = 1 }, 0.55)
		Debris:AddItem(r, 0.6)
	end

	function Win:CreateTab(tabName, icon)
		tabName = tostring(tabName or "Tab")
		local index = #self.Tabs + 1
		local y = (index - 1) * (TAB_H + TAB_GAP) + 2

		local Btn = new("TextButton", {
			Name = tabName .. "_Tab", Position = UDim2.new(0, 6, 0, y), Size = UDim2.new(1, -12, 0, TAB_H),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3,
		}, TabScroll)
		local IconL = themedIcon(Btn, icon, { Size = 24, Position = UDim2.new(0, 12, 0.5, -12), ZIndex = 3 })
		IconL.GroupTransparency = 0.5
		local NameL = label({
			Text = string.upper(tabName), Font = Bold, TextSize = 12, TextColor3 = Theme.Muted, TextXAlignment = Left,
			Position = UDim2.new(0, 46, 0, 0), Size = UDim2.new(1, -50, 1, 0), ZIndex = 3,
		}, Btn)

		local Page = new("ScrollingFrame", {
			Name = tabName .. "_Page", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.3,
			ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
		}, Content)
		bindTheme(Page, { ScrollBarImageColor3 = "Accent" })
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Page)
		new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 18), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8) }, Page)

		local tab = { Title = tabName, Btn = Btn, Page = Page, Holders = {}, Index = index, Hover = false, Y = y }
		self.Tabs[index] = tab
		TabScroll.CanvasSize = UDim2.new(0, 0, 0, index * (TAB_H + TAB_GAP) + 8)

		local function refresh(i, dur)
			local active = (Current == tab)
			paint(NameL, { TextColor3 = active and Theme.Glow or (tab.Hover and Theme.Text or Theme.Muted) }, i, dur)
			paint(IconL, {
				GroupTransparency = active and 0 or (tab.Hover and 0.1 or 0.5),
				Position = UDim2.new(0, (active or tab.Hover) and 16 or 12, 0.5, -12),
			}, i, dur)
		end
		tab.Refresh = refresh
		themed(refresh)

		Btn.MouseEnter:Connect(function() tab.Hover = true; playHoverSound(1.6, 0.35); refresh(false, 0.15) end)
		Btn.MouseLeave:Connect(function() tab.Hover = false; refresh(false, 0.15) end)
		Btn.MouseButton1Click:Connect(function()
			if Win.InIntro or Win.Busy then return end
			selectTab(tab)
		end)

		if Win.Started and not Current then selectTab(tab) end

		-- ---------------------------------------------------------------
		--   ELEMENTS
		-- ---------------------------------------------------------------
		local E = {}

		function E:CreateHolder(h) -- blank area for your own custom UI
			local _, inner = makeHolder(tab, h or 60)
			return inner
		end

		function E:CreateSection(secName)
			local _, Inner = makeHolder(tab, 32)
			themedIcon(Inner, "star", { Size = 14, Position = UDim2.new(0, 6, 0, 8), ZIndex = 2 })
			tl({
				Text = string.upper(tostring(secName)), Font = Bold, TextSize = 12, TextXAlignment = Left,
				Position = UDim2.new(0, 26, 0, 6), Size = UDim2.new(1, -32, 0, 18),
			}, Inner, "Glow")
			local line = new("Frame", {
				Position = UDim2.new(0, 6, 1, -3), Size = UDim2.new(1, -12, 0, 1), BackgroundColor3 = Theme.Dark, BorderSizePixel = 0,
			}, Inner)
			bindTheme(line, { BackgroundColor3 = "Dark" })
			new("UIGradient", {
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
			}, line)
		end

		function E:CreateLabel(text)
			local Card = makeCard(tab, 38)
			local l = tl({
				Text = tostring(text or ""), TextSize = 13, TextXAlignment = Left,
				Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -40, 1, 0),
			}, Card, "Muted")
			local api = {}
			function api:Set(v) l.Text = tostring(v) end
			return api
		end

		function E:CreateParagraph(o)
			o = o or {}
			local content = tostring(o.Content or "")
			local textH = TextService:GetTextSize(content, 13, Reg, Vector2.new(PAGE_W - 80, 10000)).Y
			local Card = makeCard(tab, math.max(60, 40 + textH + 14))
			tl({
				Text = o.Title or "Information", Font = Bold, TextSize = 14, TextXAlignment = Left,
				Position = UDim2.new(0, 20, 0, 11), Size = UDim2.new(1, -40, 0, 18),
			}, Card, "Glow")
			tl({
				Text = content, TextSize = 13, TextXAlignment = Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
				Position = UDim2.new(0, 20, 0, 34), Size = UDim2.new(1, -40, 0, textH + 2),
			}, Card, "Muted")
		end

		function E:CreateButton(o)
			o = o or {}
			local name = o.Name or o.Title or "Button"
			local desc = o.Description or o.Desc or ""
			local cb = o.Callback or function() end
			local hasDesc = desc ~= ""
			local Card, bind, repaint, _, press = makeCard(tab, hasDesc and 62 or 48)
			Card.ClipsDescendants = true

			local Click = new("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 3 }, Card)
			bind(Click)

			tl({
				Text = name, Font = Semi, TextSize = 14, TextXAlignment = Left,
				Position = UDim2.new(0, 20, 0, hasDesc and 10 or 0), Size = UDim2.new(1, -70, 0, hasDesc and 18 or 48),
			}, Card, "Text")
			if hasDesc then
				tl({
					Text = desc, TextSize = 12, TextXAlignment = Left,
					Position = UDim2.new(0, 20, 0, 31), Size = UDim2.new(1, -70, 0, 18),
				}, Card, "Muted")
			end
			themedIcon(Card, o.Icon, { Size = 26, Position = UDim2.new(1, -44, 0.5, -13) })

			Click.MouseButton1Down:Connect(function() press(true) end)
			Click.MouseButton1Up:Connect(function() press(false) end)
			Click.MouseLeave:Connect(function() press(false) end)
			Click.MouseButton1Click:Connect(function()
				playSound(Hallow.Sounds.Click, 1.0, 0.9)
				ripple(Card)
				task.spawn(cb)
			end)
		end
		E.AddButton = E.CreateButton

		function E:CreateToggle(o)
			o = o or {}
			local name = o.Name or o.Title or "Toggle"
			local desc = o.Description or o.Desc or ""
			local state = o.Default and true or false
			local cb = o.Callback or function() end
			local hasDesc = desc ~= ""
			local Card, bind = makeCard(tab, hasDesc and 62 or 48)

			tl({
				Text = name, Font = Semi, TextSize = 14, TextXAlignment = Left,
				Position = UDim2.new(0, 20, 0, hasDesc and 10 or 0), Size = UDim2.new(1, -92, 0, hasDesc and 18 or 48),
			}, Card, "Text")
			if hasDesc then
				tl({
					Text = desc, TextSize = 12, TextXAlignment = Left,
					Position = UDim2.new(0, 20, 0, 31), Size = UDim2.new(1, -92, 0, 18),
				}, Card, "Muted")
			end

			local Switch = new("TextButton", {
				Size = UDim2.new(0, 48, 0, 24), Position = UDim2.new(1, -62, 0.5, -12),
				BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
			}, Card)
			round(Switch)
			local SwStroke = outline(Switch, Theme.Border, 1.3)
			bind(Switch)
			-- sunken groove look
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 150, 150), Color3.new(1, 1, 1)) }, Switch)

			local ThumbH = new("Frame", {
				Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 3, 0.5, -9), BackgroundTransparency = 1,
			}, Switch)
			local ThumbSh = new("Frame", {
				Position = UDim2.new(0, 0, 0, 2), Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = BLACK,
				BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 1,
			}, ThumbH)
			round(ThumbSh)
			local Thumb = new("Frame", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C(255, 246, 232), BorderSizePixel = 0, ZIndex = 2,
			}, ThumbH)
			round(Thumb)
			bevel(Thumb, 190)

			local function paintSwitch(i, dur)
				paint(Switch, { BackgroundColor3 = state and Theme.Accent or Theme.Panel }, i, dur)
				paint(SwStroke, { Color = state and Theme.Glow or Theme.Border }, i, dur)
			end
			themed(paintSwitch)
			ThumbH.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

			local function apply()
				paintSwitch(false, 0.18)
				tw(ThumbH, { Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) }, 0.25, Easing.Back)
			end
			Switch.MouseButton1Click:Connect(function()
				state = not state
				playSound(Hallow.Sounds.Toggle, state and 1.3 or 0.85, 0.8)
				apply()
				task.spawn(cb, state)
			end)

			local api = {}
			function api:Set(v, silent)
				state = v and true or false
				apply()
				if not silent then task.spawn(cb, state) end
			end
			function api:Get() return state end
			return api
		end
		E.AddToggle = E.CreateToggle

		function E:CreateSlider(o)
			o = o or {}
			local name = o.Name or o.Title or "Slider"
			local min = tonumber(o.Min) or 0
			local max = tonumber(o.Max) or 100
			local step = tonumber(o.Increment or o.Step) or 1
			local suffix = o.Suffix or ""
			local value = math.clamp(tonumber(o.Default) or min, min, max)
			local cb = o.Callback or function() end

			local decimals = 0
			if step < 1 then
				local s = tostring(step)
				local dot = s:find("%.")
				decimals = dot and (#s - dot) or 1
			end
			local function fmt(v)
				if decimals > 0 then return string.format("%." .. decimals .. "f", v) end
				return tostring(math.floor(v + 0.5))
			end

			local Card, bind = makeCard(tab, 62)
			tl({
				Text = name, Font = Semi, TextSize = 14, TextXAlignment = Left,
				Position = UDim2.new(0, 20, 0, 8), Size = UDim2.new(1, -110, 0, 18),
			}, Card, "Text")
			local valL = tl({
				Text = fmt(value) .. suffix, Font = Bold, TextSize = 14, TextXAlignment = Right,
				Position = UDim2.new(1, -92, 0, 8), Size = UDim2.new(0, 72, 0, 18),
			}, Card, "Glow")

			local Track = new("TextButton", {
				Size = UDim2.new(1, -40, 0, 8), Position = UDim2.new(0, 20, 0, 40), BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0, Text = "", AutoButtonColor = false,
			}, Card)
			round(Track)
			local tst = outline(Track, Theme.Border, 1, 0.3)
			bindTheme(Track, { BackgroundColor3 = "Panel" })
			bindTheme(tst, { Color = "Border" })
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(140, 140, 140), Color3.new(1, 1, 1)) }, Track)
			bind(Track)

			local Fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, Track)
			round(Fill)
			local grad = new("UIGradient", nil, Fill)
			themed(function() grad.Color = ColorSequence.new(Theme.Dark, Theme.Glow) end)

			local KnobH = new("Frame", {
				AnchorPoint = CENTER, Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 16, 0, 16),
				BackgroundTransparency = 1, ZIndex = 3,
			}, Fill)
			local KnobSh = new("Frame", {
				Position = UDim2.new(0, 0, 0, 3), Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = BLACK,
				BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 3,
			}, KnobH)
			round(KnobSh)
			local Knob = new("Frame", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C(255, 248, 235), BorderSizePixel = 0, ZIndex = 4,
			}, KnobH)
			round(Knob)
			bevel(Knob, 185)
			local kst = outline(Knob, Theme.Accent, 2)
			bindTheme(kst, { Color = "Accent" })

			local function visual(v)
				valL.Text = fmt(v) .. suffix
				Fill.Size = UDim2.new(math.clamp((v - min) / math.max(1e-6, max - min), 0, 1), 0, 1, 0)
			end
			visual(value)

			local sliding = false
			local function fromInput(input)
				local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / math.max(1, Track.AbsoluteSize.X), 0, 1)
				local v = math.clamp(math.floor(((min + (max - min) * pos) / step) + 0.5) * step, min, max)
				value = tonumber(fmt(v)) or v
				visual(v)
				task.spawn(cb, value)
			end
			Track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					playSound(Hallow.Sounds.Click, 1.4, 0.6)
					tw(KnobH, { Size = UDim2.new(0, 22, 0, 22) }, 0.12, Easing.Back)
					fromInput(input)
				end
			end)
			track(UserInputService.InputEnded:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					sliding = false
					tw(KnobH, { Size = UDim2.new(0, 16, 0, 16) }, 0.15)
				end
			end))
			track(UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					fromInput(input)
				end
			end))

			local api = {}
			function api:Set(v, fire)
				value = math.clamp(tonumber(v) or min, min, max)
				visual(value)
				if fire then task.spawn(cb, value) end
			end
			function api:Get() return value end
			return api
		end
		E.AddSlider = E.CreateSlider

		function E:CreateDropdown(o)
			o = o or {}
			local name = o.Name or o.Title or "Dropdown"
			local items = o.Options or {}
			local selected = o.Default or items[1] or "Select…"
			local cb = o.Callback or function() end
			local ITEM_H, HEAD_H = 32, 48
			local expanded = false

			local Card, bind, _, Holder = makeCard(tab, HEAD_H)
			Card.ClipsDescendants = true

			local HeaderBtn = new("TextButton", { Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, Text = "", ZIndex = 2 }, Card)
			bind(HeaderBtn)
			tl({
				Text = name, Font = Semi, TextSize = 14, TextXAlignment = Left,
				Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(0.5, 0, 0, HEAD_H),
			}, Card, "Text")
			local curL = tl({
				Text = tostring(selected), TextSize = 13, TextXAlignment = Right, AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0.4, 0, 0, HEAD_H),
			}, Card, "Glow")

			-- chevron drawn from two bars (rotates when the list opens)
			local Arrow = new("Frame", {
				AnchorPoint = CENTER, Position = UDim2.new(1, -22, 0, HEAD_H / 2), Size = UDim2.new(0, 16, 0, 16),
				BackgroundTransparency = 1,
			}, Card)
			for _, s in ipairs({ -1, 1 }) do
				local bar = new("Frame", {
					AnchorPoint = CENTER, Position = UDim2.new(0.5, s * 3.4, 0.5, 1), Size = UDim2.new(0, 9, 0, 2.6),
					Rotation = -s * 40, BackgroundColor3 = Theme.Muted, BorderSizePixel = 0,
				}, Arrow)
				round(bar)
				bindTheme(bar, { BackgroundColor3 = "Muted" })
			end

			local ListHolder = new("Frame", {
				Position = UDim2.new(0, 12, 0, HEAD_H), Size = UDim2.new(1, -24, 0, 0), BackgroundTransparency = 1,
			}, Card)
			new("UIListLayout", { Padding = UDim.new(0, 4) }, ListHolder)

			local recs = {}
			local function fullH() return HEAD_H + #items * (ITEM_H + 4) + 8 + DEPTH end

			local function choose(item, fire)
				selected = item
				curL.Text = tostring(item)
				for _, r in ipairs(recs) do r.repaint(false, 0.15) end
				if fire then task.spawn(cb, item) end
			end

			local function collapse()
				expanded = false
				tw(Arrow, { Rotation = 0 }, 0.2)
				tw(Holder, { Size = UDim2.new(1, -10, 0, HEAD_H + DEPTH) }, 0.3, Easing.Quint)
			end

			local function build()
				for _, r in ipairs(recs) do r.btn:Destroy() end
				table.clear(recs)
				ListHolder.Size = UDim2.new(1, -24, 0, #items * (ITEM_H + 4))
				for _, item in ipairs(items) do
					local b = new("TextButton", {
						Size = UDim2.new(1, 0, 0, ITEM_H), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
						Font = Reg, TextSize = 13, TextColor3 = Theme.Text, Text = "   " .. tostring(item),
						TextXAlignment = Left, AutoButtonColor = false,
					}, ListHolder)
					round(b, UDim.new(0, 8))
					bevel(b, 205)
					local rec = { btn = b, hover = false }
					rec.repaint = function(i, dur)
						paint(b, {
							BackgroundColor3 = rec.hover and Theme.CardHover or Theme.Panel,
							TextColor3 = (item == selected or rec.hover) and Theme.Glow or Theme.Text,
						}, i, dur)
					end
					themed(rec.repaint)
					b.MouseEnter:Connect(function() rec.hover = true; playHoverSound(1.85, 0.3); rec.repaint(false, 0.12) end)
					b.MouseLeave:Connect(function() rec.hover = false; rec.repaint(false, 0.12) end)
					b.MouseButton1Click:Connect(function()
						playSound(Hallow.Sounds.Click, 1.2, 0.8)
						choose(item, true)
						collapse()
					end)
					recs[#recs + 1] = rec
				end
			end
			build()

			HeaderBtn.MouseButton1Click:Connect(function()
				expanded = not expanded
				playSound(Hallow.Sounds.Click, 1.0, 0.8)
				tw(Arrow, { Rotation = expanded and 180 or 0 }, 0.25)
				tw(Holder, { Size = UDim2.new(1, -10, 0, expanded and fullH() or (HEAD_H + DEPTH)) }, 0.3, Easing.Quint)
			end)

			local api = {}
			function api:Set(v, fire) choose(v, fire) end
			function api:Get() return selected end
			function api:SetOptions(list, keep)
				items = list or {}
				if not keep then selected = items[1] or "Select…"; curL.Text = tostring(selected) end
				build()
				if expanded then tw(Holder, { Size = UDim2.new(1, -10, 0, fullH()) }, 0.2) end
			end
			return api
		end

		function E:CreateKeybind(o)
			o = o or {}
			local name = o.Name or o.Title or "Keybind"
			local key = o.Default or Enum.KeyCode.None
			local cb = o.Callback or function() end      -- fires when the key is PRESSED
			local onChange = o.OnChange or function() end -- fires when the key is REBOUND
			local Card, bind = makeCard(tab, 48)

			tl({
				Text = name, Font = Semi, TextSize = 14, TextXAlignment = Left,
				Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
			}, Card, "Text")
			local KeyBtn = new("TextButton", {
				Size = UDim2.new(0, 96, 0, 28), Position = UDim2.new(1, -110, 0.5, -14), BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0, Font = Bold, TextSize = 12, TextColor3 = Theme.Glow,
				Text = key == Enum.KeyCode.None and "None" or key.Name, AutoButtonColor = false,
			}, Card)
			round(KeyBtn, UDim.new(0, 8))
			bevel(KeyBtn, 200)
			local ks = outline(KeyBtn, Theme.Border, 1.3)
			bindTheme(KeyBtn, { BackgroundColor3 = "Panel", TextColor3 = "Glow" })
			bindTheme(ks, { Color = "Border" })
			bind(KeyBtn)

			local listening = false
			KeyBtn.MouseButton1Click:Connect(function()
				listening = true
				Win.Listening = true
				KeyBtn.Text = "…"
				tw(ks, { Color = Theme.Glow }, 0.15)
				playSound(Hallow.Sounds.Click, 1.25, 0.8)
			end)
			track(UserInputService.InputBegan:Connect(function(input, gpe)
				if listening then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						listening = false
						task.delay(0.1, function() Win.Listening = false end)
						tw(ks, { Color = Theme.Border }, 0.15)
						if input.KeyCode ~= Enum.KeyCode.Escape then
							key = input.KeyCode
							playSound(Hallow.Sounds.Click, 0.95, 0.8)
							task.spawn(onChange, key)
						end
						KeyBtn.Text = key == Enum.KeyCode.None and "None" or key.Name
					end
				elseif not gpe and key ~= Enum.KeyCode.None and input.KeyCode == key then
					task.spawn(cb, key)
				end
			end))

			local api = {}
			function api:Get() return key end
			function api:Set(k) key = k; KeyBtn.Text = k == Enum.KeyCode.None and "None" or k.Name end
			return api
		end

		function E:CreateInput(o)
			o = o or {}
			local name = o.Name or o.Title or "Input"
			local cb = o.Callback or function() end
			local Card, bind = makeCard(tab, 48)
			tl({
				Text = name, Font = Semi, TextSize = 14, TextXAlignment = Left,
				Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(0.5, -20, 1, 0),
			}, Card, "Text")
			local Box = new("TextBox", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0.44, 0, 0, 30),
				BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Font = Reg, TextSize = 13, TextColor3 = Theme.Text,
				PlaceholderText = o.Placeholder or "Type here…", PlaceholderColor3 = Theme.Muted,
				Text = o.Default or "", ClearTextOnFocus = o.ClearOnFocus or false, ClipsDescendants = true,
			}, Card)
			round(Box, UDim.new(0, 8))
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 150, 150), Color3.new(1, 1, 1)) }, Box)
			local bs = outline(Box, Theme.Border, 1.3)
			bindTheme(Box, { BackgroundColor3 = "Panel", TextColor3 = "Text", PlaceholderColor3 = "Muted" })
			bindTheme(bs, { Color = "Border" })
			bind(Box)
			Box.Focused:Connect(function() tw(bs, { Color = Theme.Glow, Thickness = 1.8 }, 0.15) end)
			Box.FocusLost:Connect(function(enter)
				tw(bs, { Color = Theme.Border, Thickness = 1.3 }, 0.15)
				task.spawn(cb, Box.Text, enter)
			end)
			local api = {}
			function api:Set(v) Box.Text = tostring(v) end
			function api:Get() return Box.Text end
			return api
		end

		return E
	end

	-- =====================================================================
	--   THEME TAB (cards + ambient effect toggles + scale + toggle key)
	-- =====================================================================
	function Win:CreateThemeTab(tabName, icon)
		local tab = self:CreateTab(tabName or "Themes", icon or "palette")

		tab:CreateSection("Choose Your Haunting")
		local rows = math.ceil(#Hallow.ThemeOrder / 2)
		local Grid = tab:CreateHolder(rows * 86 - 8)
		new("UIGridLayout", {
			CellSize = UDim2.new(0.5, -4, 0, 78), CellPadding = UDim2.new(0, 8, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		}, Grid)

		for n, key in ipairs(Hallow.ThemeOrder) do
			local def = Hallow.Themes[key]
			local Cell = new("Frame", { BackgroundTransparency = 1, LayoutOrder = n }, Grid)
			local Slab = new("Frame", {
				Position = UDim2.new(0, 0, 0, 5), Size = UDim2.new(1, 0, 1, -5),
				BackgroundColor3 = mix(def.Accent, BLACK, 0.6), BorderSizePixel = 0, ZIndex = 1,
			}, Cell)
			round(Slab, UDim.new(0, 12))
			local Card = new("TextButton", {
				Position = UDim2.new(0, 0, 0, 2), Size = UDim2.new(1, 0, 1, -5),
				BackgroundColor3 = def.Panel, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 2,
			}, Cell)
			round(Card, UDim.new(0, 12))
			bevel(Card, 205)
			local st = outline(Card, def.Accent, 1.5, 0.55)

			mkIcon(def.Icon, Card, {
				Size = 42, Position = UDim2.new(0, 9, 0, 8), ZIndex = 2,
				Pal = { a = def.Accent, g = def.Glow, d = def.Dark, bg = def.Bg, t = def.Text },
			})
			label({
				Text = def.Name or key, Font = Bold, TextSize = 14, TextColor3 = def.Text, TextXAlignment = Left,
				Position = UDim2.new(0, 58, 0, 10), Size = UDim2.new(1, -66, 0, 18),
			}, Card)
			label({
				Text = def.Tag or "", TextSize = 11, TextColor3 = def.Muted, TextXAlignment = Left,
				Position = UDim2.new(0, 58, 0, 28), Size = UDim2.new(1, -66, 0, 14),
			}, Card)
			for s, col in ipairs({ def.Accent, def.Glow, def.Dark, def.Border }) do
				local dot = new("Frame", {
					Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 60 + (s - 1) * 19, 1, -22),
					BackgroundColor3 = col, BorderSizePixel = 0,
				}, Card)
				round(dot)
				bevel(dot, 170)
			end
			local Badge = label({
				Text = "ACTIVE", Font = Bold, TextSize = 10, TextColor3 = def.Glow, TextXAlignment = Right,
				TextTransparency = 1, Position = UDim2.new(1, -10, 1, -22), Size = UDim2.new(0, 80, 0, 14),
			}, Card)

			themed(function(i)
				local on = (Win.ThemeName == key)
				paint(st, { Transparency = on and 0 or 0.55, Thickness = on and 2.5 or 1.5 }, i, 0.25)
				paint(Badge, { TextTransparency = on and 0 or 1 }, i, 0.25)
			end)

			Card.MouseEnter:Connect(function()
				playHoverSound(1.7, 0.3)
				tw(Card, { Position = UDim2.new(0, 0, 0, -1) }, 0.15, Easing.Back)
			end)
			Card.MouseLeave:Connect(function() tw(Card, { Position = UDim2.new(0, 0, 0, 2) }, 0.15) end)
			Card.MouseButton1Down:Connect(function() tw(Card, { Position = UDim2.new(0, 0, 0, 5) }, 0.06) end)
			Card.MouseButton1Up:Connect(function() tw(Card, { Position = UDim2.new(0, 0, 0, -1) }, 0.2, Easing.Back) end)
			Card.MouseButton1Click:Connect(function() Win:SetTheme(key) end)
		end

		tab:CreateButton({ Name = "Random Theme", Description = "let the spirits decide", Icon = "dice", Callback = function()
			local pool = {}
			for _, k in ipairs(Hallow.ThemeOrder) do if k ~= Win.ThemeName then pool[#pool + 1] = k end end
			if #pool > 0 then Win:SetTheme(pool[math.random(#pool)]) end
		end })
		tab:CreateButton({ Name = "Lightning Strike", Description = "because why not", Icon = "bolt", Callback = function()
			Win:Lightning()
		end })

		tab:CreateSection("Ambience")
		tab:CreateToggle({ Name = "Rising Embers", Default = FX.Embers, Callback = function(v) FX.Embers = v end })
		tab:CreateToggle({ Name = "Floating Spirits", Description = "drawn spirits drifting through the window", Default = FX.Floaters, Callback = function(v) FX.Floaters = v end })
		tab:CreateToggle({ Name = "Creeping Fog", Default = FX.Fog, Callback = function(v) FX.Fog = v end })
		tab:CreateToggle({ Name = "Depth Parallax", Description = "the slab turns toward your cursor", Default = FX.Parallax, Callback = function(v) FX.Parallax = v end })
		tab:CreateToggle({ Name = "UI Sounds", Default = Hallow.SoundsEnabled, Callback = function(v) Hallow.SoundsEnabled = v end })

		tab:CreateSection("Window")
		tab:CreateSlider({ Name = "UI Scale", Min = 60, Max = 120, Default = 100, Suffix = "%", Callback = function(v)
			userScale = v / 100
			applyScale()
		end })
		tab:CreateKeybind({ Name = "Toggle Key", Default = toggleKey or Enum.KeyCode.None, OnChange = function(k) toggleKey = k end })
		return tab
	end

	-- =====================================================================
	--   THEME SWITCHING
	-- =====================================================================
	function Win:SetTheme(name, silent)
		if not Hallow.Themes[name] then return false end
		if name == self.ThemeName then return true end
		self.ThemeName = name
		loadTheme(name)

		local live = self.Started and not self.Minimized and not self.InIntro and not self.Destroyed
		for _, fn in ipairs(appliers) do pcall(fn, not live) end

		Bug.Rotation = Theme.MascotRot or 0
		if live then
			-- the mascot lowers itself away, swaps, and drops back in
			setSpider(0, 0.3, Easing.Back, Dir.In)
			task.delay(0.35, function()
				if self.Destroyed then return end
				drawInto(Bug, Theme.Mascot, palette())
				setSpider(SPIDER_LEN, 0.9, Easing.Bounce, Dir.Out)
			end)
			lightning(0.55)
			shake(Root, 6, 0.3)
			shockwave(RootFX, Theme.Glow, 120, W * 1.3, 0.8, 4)
			burst(RootFX, Theme.Swarm, 14, { Life = 1.6, MinSpeed = 220, MaxSpeed = 560 })
		else
			drawInto(Bug, Theme.Mascot, palette())
		end

		if cfg.RememberTheme ~= false and typeof(writefile) == "function" then
			pcall(writefile, "Grimoire_Theme.txt", name)
		end
		if cfg.OnThemeChanged then task.spawn(cfg.OnThemeChanged, name) end
		if not silent and live then
			Hallow:Notify({ Title = Theme.Name or name, Content = "The " .. (Theme.Tag or "mood") .. " takes hold.", Duration = 2.5 })
		end
		return true
	end
	function Win:GetTheme() return self.ThemeName end
	function Win:Lightning() lightning(1); shake(Root, 8, 0.4) end
	function Win:Notify(c) Hallow:Notify(c) end
	function Win:SetToggleKey(k) toggleKey = k end
	function Win:SetScale(s) userScale = math.clamp(s, 0.5, 1.4); applyScale() end

	-- =====================================================================
	--   MINIMIZE / RESTORE / DESTROY
	-- =====================================================================
	function Win:Minimize()
		if self.Minimized or self.InIntro or self.Busy or self.Destroyed then return end
		self.Busy, self.Minimized = true, true
		playSound(Hallow.Sounds.Click, 0.85, 0.9)
		setSpider(0, 0.3, Easing.Back, Dir.In)
		burst(RootFX, Theme.Swarm, 8, { Life = 1.3, MinSpeed = 200, MaxSpeed = 420, Size1 = 40 })
		task.spawn(function()
			closeWindow()
			if self.Destroyed then return end
			showOrb()
			self.Busy = false
		end)
	end

	function Win:Restore()
		if not self.Minimized or self.InIntro or self.Busy or self.Destroyed then return end
		self.Busy, self.Minimized = true, false
		hideOrb()
		task.spawn(function()
			openWindow()
			if self.Destroyed then return end
			setSpider(SPIDER_LEN, 1.1, Easing.Bounce, Dir.Out)
			self.Busy = false
		end)
	end

	function Win:Toggle()
		if self.Minimized then self:Restore() else self:Minimize() end
	end

	function Win:Destroy()
		if self.Destroyed then return end
		self.Destroyed = true
		playSound(Hallow.Sounds.Click, 0.8, 0.9)
		task.spawn(function()
			lightning(0.7)
			if Root.Visible then
				burst(RootFX, Theme.Swarm, 20, { Life = 1.5 })
				setSpider(0, 0.25, Easing.Back, Dir.In)
				closeWindow()
			end
			tw(Orb, { Position = UDim2.new(orbHome.X.Scale, orbHome.X.Offset, 0, -110) }, 0.3)
			task.wait(0.35)
			for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
			NotifyHolder = nil
			ScreenGui:Destroy()
		end)
	end

	MinBtn.MouseButton1Click:Connect(function() playSound(Hallow.Sounds.Click, 1, 0.8); Win:Minimize() end)
	CloseBtn.MouseButton1Click:Connect(function() Win:Destroy() end)

	track(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or Win.Destroyed or Win.Listening then return end
		if toggleKey and input.KeyCode == toggleKey then Win:Toggle() end
	end))

	-- orb: click to restore, drag to move
	do
		local down, moved, startV, startPos = false, false, nil, nil
		Orb.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				down, moved, startV, startPos = true, false, input.Position, Orb.Position
			end
		end)
		track(UserInputService.InputChanged:Connect(function(input)
			if down and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local d = input.Position - startV
				if d.Magnitude > 6 then moved = true end
				if moved then
					Orb.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
				end
			end
		end))
		track(UserInputService.InputEnded:Connect(function(input)
			if down and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				down = false
				if moved then
					orbHome = Orb.Position
				else
					playSound(Hallow.Sounds.Open, 1.2, 0.8)
					Win:Restore()
				end
			end
		end))
	end

	-- =====================================================================
	--   THE SUMMONING  (intro)
	-- =====================================================================
	-- a hand-built rune (a few bars), 6 variants
	local function rune(parent, v, col, size)
		local g = new("CanvasGroup", {
			AnchorPoint = CENTER, Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1, GroupTransparency = 1,
		}, parent)
		if v == 1 then
			P(g, "rect", 0.4, 0.5, 0.12, 0.9, col); P(g, "rect", 0.62, 0.32, 0.12, 0.55, col, -40)
		elseif v == 2 then
			P(g, "rect", 0.4, 0.5, 0.12, 0.9, col); P(g, "rect", 0.64, 0.28, 0.12, 0.45, col, -55); P(g, "rect", 0.64, 0.60, 0.12, 0.45, col, -55)
		elseif v == 3 then
			P(g, "round", 0.5, 0.5, 0.5, 0.5, col, 45); P(g, "rect", 0.5, 0.5, 0.1, 0.95, col)
		elseif v == 4 then
			P(g, "rect", 0.5, 0.5, 0.12, 0.95, col, 45); P(g, "rect", 0.5, 0.5, 0.12, 0.95, col, -45)
		elseif v == 5 then
			P(g, "rect", 0.35, 0.5, 0.12, 0.9, col); P(g, "rect", 0.62, 0.33, 0.12, 0.5, col, -40); P(g, "rect", 0.62, 0.67, 0.12, 0.5, col, 40)
		else
			P(g, "ellipse", 0.5, 0.3, 0.34, 0.34, col); P(g, "rect", 0.5, 0.72, 0.12, 0.5, col)
		end
		return g
	end

	local function runIntro()
		Win.InIntro = true
		local ritual = {}
		local function keep(o) ritual[#ritual + 1] = o return o end

		local RING_R = 175
		local S = RING_R * 2 + 60

		local function ring(strokeCol, thick)
			local f = keep(new("Frame", {
				AnchorPoint = CENTER, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1, ZIndex = 1,
			}, Stage))
			round(f)
			return f, outline(f, strokeCol, thick, 1)
		end
		local ringOuter, ringOuterS = ring(Theme.Accent, 2)
		local ringInner, ringInnerS = ring(Theme.Glow, 1.5)

		-- rotating rune ring
		local Runes = keep(new("Frame", {
			AnchorPoint = CENTER, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1, ZIndex = 2,
		}, Stage))
		local runeLabels = {}
		local RUNES = 32
		local fr = (RING_R + 22) / S
		for i = 1, RUNES do
			local a = (i / RUNES) * 2 * math.pi
			local big = (i % 4 == 0)
			local rn = rune(Runes, (i - 1) % 6 + 1, big and Theme.Glow or Theme.Accent, big and 20 or 14)
			rn.Position = UDim2.new(0.5 + math.cos(a) * fr, 0, 0.5 + math.sin(a) * fr, 0)
			rn.Rotation = math.deg(a) + 90
			runeLabels[i] = rn
		end

		-- eight candles (hidden until the circle is drawn)
		local CANDLES = 8
		local candles = {}
		for i = 1, CANDLES do
			local a = (i - 1) / CANDLES * 2 * math.pi - math.pi / 2
			local cx, cy = math.cos(a) * RING_R, math.sin(a) * RING_R
			local holder = keep(new("Frame", {
				AnchorPoint = CENTER, Position = UDim2.new(0, cx, 0, cy), Size = UDim2.new(0, 30, 0, 64),
				BackgroundTransparency = 1, ZIndex = 3,
			}, Stage))
			local halo = new("Frame", {
				AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1,
			}, holder)
			round(halo)
			local body = new("Frame", { -- starts flat + invisible, rises later
				AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 8, 0, 0),
				BackgroundColor3 = C(232, 224, 200), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
			}, holder)
			round(body, UDim.new(0, 3))
			bevel(body, 150)
			local flame = new("Frame", {
				AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = Theme.Glow, BorderSizePixel = 0, ZIndex = 3,
			}, holder)
			round(flame)
			candles[i] = { holder = holder, body = body, flame = flame, halo = halo, lit = false, cx = cx, cy = cy }
		end

		-- centre sigil (the theme's icon)
		local sigilGlow = keep(new("Frame", {
			AnchorPoint = CENTER, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 3,
		}, Stage))
		round(sigilGlow)
		local sigil = keep(mkIcon(Theme.Icon, Stage, {
			Size = UDim2.new(0, 0, 0, 0), AnchorPoint = CENTER, Position = UDim2.new(0, 0, 0, 0), ZIndex = 4,
		}))

		local status = keep(label({
			Text = "", TextSize = 13, TextColor3 = Theme.Muted, TextTransparency = 1, AnchorPoint = CENTER,
			Position = UDim2.new(0, 0, 0, RING_R + 62), Size = UDim2.new(0, 320, 0, 20), ZIndex = 4,
		}, Stage))
		local function say(text)
			status.Text = text
			status.TextTransparency = 1
			tw(status, { TextTransparency = 0.15 }, 0.35)
		end

		-- spin + flicker loop
		local spin, spinTarget, t = 8, 8, 0
		local conn = RunService.RenderStepped:Connect(function(dt)
			t += dt
			spin += (spinTarget - spin) * math.min(1, dt * 2.5)
			Runes.Rotation = (Runes.Rotation + spin * dt) % 360
			for i, c in ipairs(candles) do
				if c.lit and c.holder.Parent then
					local n = math.noise(t * 4, i * 3.7)
					c.flame.Size = UDim2.new(0, 11 * (1 + n * 0.5), 0, 17 * (1 + n * 0.8))
					c.halo.BackgroundTransparency = 0.8 + n * 0.1
				end
			end
		end)

		-- 1. dim the world, draw the circle FIRST
		tw(Dim, { BackgroundTransparency = 0.38 }, 0.8)
		task.wait(0.4)
		if Win.Destroyed then conn:Disconnect() return end
		say("invoking the spirits…")
		tw(ringOuter, { Size = UDim2.new(0, RING_R * 2 + 16, 0, RING_R * 2 + 16) }, 0.9, Easing.Quint)
		tw(ringOuterS, { Transparency = 0.2 }, 0.9)
		tw(ringInner, { Size = UDim2.new(0, RING_R * 2 - 80, 0, RING_R * 2 - 80) }, 1.1, Easing.Quint)
		tw(ringInnerS, { Transparency = 0.45 }, 1.1)
		tw(Runes, { Size = UDim2.new(0, S, 0, S) }, 1.0, Easing.Quint)
		for i, l in ipairs(runeLabels) do
			task.delay(0.15 + i * 0.02, function() tw(l, { GroupTransparency = 0.05 }, 0.25) end)
		end
		task.wait(1.0) -- let the circle finish before any candle appears
		if Win.Destroyed then conn:Disconnect() return end

		-- 2. candles rise out of the circle and ignite one by one
		for i, c in ipairs(candles) do
			playSound(Hallow.Sounds.Click, 0.7 + i * 0.1, 0.7)
			tw(c.body, { Size = UDim2.new(0, 8, 0, 26), BackgroundTransparency = 0 }, 0.28, Easing.Back)
			task.delay(0.2, function()
				if not c.holder.Parent then return end
				tw(c.flame, { Size = UDim2.new(0, 11, 0, 17) }, 0.25, Easing.Back)
				tw(c.halo, { Size = UDim2.new(0, 86, 0, 86), BackgroundTransparency = 0.82 }, 0.4)
				shockwave(Stage, Theme.Glow, 14, 64, 0.45, 2, UDim2.new(0, c.cx, 0, c.cy - 6))
				task.delay(0.28, function() c.lit = true end)
			end)
			task.wait(0.15)
		end
		task.wait(0.5)
		if Win.Destroyed then conn:Disconnect() return end

		-- 3. the sigil rises, the circle spins up
		say("the veil grows thin…")
		spinTarget = 300
		playSound(Hallow.Sounds.Open, 0.7, 1)
		tw(sigilGlow, { Size = UDim2.new(0, 150, 0, 150) }, 0.7, Easing.Quint)
		tw(sigil, { Size = UDim2.new(0, 96, 0, 96) }, 0.6, Easing.Back)
		task.wait(0.85)
		if Win.Destroyed then conn:Disconnect() return end

		-- 4. STRIKE
		lightning(1)
		shake(Stage, 14, 0.5)
		burst(Stage, Theme.Swarm, 24, { Life = 2.1, MinSpeed = 320, MaxSpeed = 900, Size1 = 58 })
		shockwave(Stage, Theme.Glow, 160, 900, 1.1, 5)
		shockwave(Stage, Theme.Accent, 220, 1100, 1.4, 3)
		status.TextTransparency = 1
		for _, c in ipairs(candles) do
			c.lit = false
			tw(c.flame, { Size = UDim2.new(0, 0, 0, 0) }, 0.25, Easing.Back, Dir.In)
			tw(c.halo, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.3)
			tw(c.body, { Size = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1 }, 0.3, Easing.Back, Dir.In)
		end
		tw(Runes, { Size = UDim2.new(0, S * 1.7, 0, S * 1.7) }, 0.7, Easing.Quint)
		for _, l in ipairs(runeLabels) do tw(l, { GroupTransparency = 1 }, 0.5) end
		tw(ringOuter, { Size = UDim2.new(0, RING_R * 3, 0, RING_R * 3) }, 0.7, Easing.Quint)
		tw(ringOuterS, { Transparency = 1 }, 0.6)
		tw(ringInner, { Size = UDim2.new(0, RING_R * 2, 0, RING_R * 2) }, 0.7, Easing.Quint)
		tw(ringInnerS, { Transparency = 1 }, 0.6)
		tw(sigil, { Size = UDim2.new(0, 0, 0, 0) }, 0.3, Easing.Back, Dir.In)
		tw(sigilGlow, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.35)
		task.wait(0.35)
		-- candles are gone visually; remove them for real before the window opens
		for _, c in ipairs(candles) do c.holder:Destroy() end
		if Win.Destroyed then conn:Disconnect() return end

		-- 5. the crypt door opens
		openWindow()
		if Win.Destroyed then conn:Disconnect() return end
		tw(Dim, { BackgroundTransparency = 1 }, 0.9)
		conn:Disconnect()
		for _, o in ipairs(ritual) do pcall(function() o:Destroy() end) end -- no leftovers

		Win.InIntro = false
		Win.Started = true
		setSpider(SPIDER_LEN, 1.2, Easing.Bounce, Dir.Out)
		if #Win.Tabs > 0 and not Win.Current then selectTab(Win.Tabs[1]) end
		task.spawn(scramble, TitleL, winTitle)
		if cfg.WelcomeToast ~= false then
			Hallow:Notify({
				Title = "The spirits welcome you",
				Content = toggleKey and ("Press " .. toggleKey.Name .. " to vanish. Click the orb to return.") or "Click the orb to return after minimizing.",
				Duration = 5,
			})
		end
	end

	-- =====================================================================
	--   MAIN LOOP (sweeping borders, slab parallax, glow flicker, fog, spirits, embers...)
	-- =====================================================================
	local t0 = os.clock()
	local emberT, floatT = 0.5, 1.5
	local pm = Vector2.new(0, 0) -- smoothed cursor offset, -1..1
	track(RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - t0

		for i = #spinners, 1, -1 do
			local s = spinners[i]
			if s.g.Parent then
				s.g.Rotation = (s.g.Rotation + s.speed * dt) % 360
			else
				table.remove(spinners, i)
			end
		end

		-- cursor -> parallax target
		local target = Vector2.new(0, 0)
		if FX.Parallax and Root.Visible then
			local mp = UserInputService:GetMouseLocation()
			local rc = Root.AbsolutePosition + Root.AbsoluteSize / 2
			target = Vector2.new(math.clamp((mp.X - rc.X) / 500, -1, 1), math.clamp((mp.Y - rc.Y) / 350, -1, 1))
		end
		pm = pm + (target - pm) * math.min(1, dt * 6)

		-- window glow, cast shadow and extruded slab all follow the window's live size
		glowI += (glowTarget - glowI) * math.min(1, dt * 4)
		local flick = math.clamp(0.5 + math.noise(t * 2.2, 3.71), 0, 1)
		local gw, gh = Window.Size.X.Offset, Window.Size.Y.Offset
		for i, g in ipairs(Glow) do
			local pad = GLOW_PADS[i] * (0.94 + 0.12 * flick)
			g.Size = UDim2.new(0, gw + pad * 2, 0, gh + pad * 2)
			g.BackgroundColor3 = (i == 1) and Theme.Accent or Theme.Dark
			g.BackgroundTransparency = 1 - (1 - GLOW_BASE[i]) * glowI * (0.8 + 0.2 * flick)
		end
		for i, s in ipairs(Shadow) do
			local pad = i * 8 - 6
			s.Size = UDim2.new(0, math.max(0, gw + pad * 2 - 20), 0, math.max(0, gh + pad * 2 - 20))
			s.Position = UDim2.new(0.5, pm.X * 10, 0.5, 26 + pm.Y * 8)
			s.BackgroundTransparency = 1 - 0.085 * glowI
		end
		for k = 1, SLABS do
			local s = Slab[k]
			s.Position = UDim2.new(0.5, pm.X * k * 1.25, 0.5, pm.Y * k * 0.95 + k * 1.5)
			s.Size = UDim2.new(0, math.max(0, gw - k * 0.9), 0, math.max(0, gh - k * 0.9))
		end

		-- layers inside the window drift against the cursor (background deeper than foreground)
		FXLayer.Position = UDim2.new(0, -pm.X * 9, 0, -pm.Y * 7)
		SpiderRoot.Position = UDim2.new(0, W - 150 + pm.X * 5, 0, 3)

		-- hanging mascot swings
		SpiderRoot.Rotation = math.sin(t * 1.5) * 7

		-- orb: bob + pulsing halo + squashing shadow
		if Orb.Visible then
			local by = math.sin(t * 2.2) * 3
			Bob.Position = UDim2.new(0.5, 0, 0.5, by)
			OrbBase.Position = UDim2.new(0.5, 0, 0.5, by + 5)
			OrbShadow.Size = UDim2.new(0, 38 - by * 2.5, 0, 9 - by * 0.6)
			OrbShadow.BackgroundTransparency = 0.6 + by * 0.04
			local k = (t % 1.8) / 1.8
			OrbHalo.Size = UDim2.new(1, k * 40, 1, k * 40)
			OrbHaloS.Transparency = 0.3 + 0.7 * k
			OrbHaloS.Color = Theme.Accent
		end

		if Root.Visible then
			for _, b in ipairs(fogBlobs) do
				b.f.Visible = FX.Fog
				b.f.Position = UDim2.new(0, b.x0 + math.sin(t * b.sp + b.ph) * b.amp, 0, b.y)
			end

			if Win.Started and not Win.Minimized then
				if FX.Embers then
					emberT -= dt
					if emberT <= 0 then emberT = 0.2 + math.random() * 0.3; spawnEmber() end
				end
				if FX.Floaters then
					floatT -= dt
					if floatT <= 0 then floatT = 2.2 + math.random() * 2.8; spawnFloater() end
				end
			end

			for i = #floaters, 1, -1 do
				local f = floaters[i]
				f.age += dt
				local k = f.age / f.life
				if k >= 1 or not f.l.Parent then
					f.l:Destroy()
					table.remove(floaters, i)
				else
					f.l.Position = UDim2.new(0, f.x + math.sin(f.age * 0.9 + f.ph) * 26, 0, H + 30 - k * (H + 80))
					f.l.Rotation = math.sin(f.age * 0.7 + f.ph) * 12
					f.l.GroupTransparency = 0.62 + 0.38 * (math.abs(k * 2 - 1) ^ 3)
				end
			end
		end
	end))

	-- =====================================================================
	--   MOUNT + START
	-- =====================================================================
	for _, p in ipairs(candidateParents()) do
		local ok = pcall(function() ScreenGui.Parent = p end)
		if ok and ScreenGui.Parent == p then break end
	end

	task.defer(function()
		if Win.Destroyed then return end
		if introOn then
			runIntro()
		else
			Root.Visible = true
			Window.Size = UDim2.new(0, W, 0, H)
			glowTarget = 1
			TitleL.Text = winTitle
			Win.Started = true
			setSpider(SPIDER_LEN, 0.9, Easing.Bounce, Dir.Out)
			if #Win.Tabs > 0 and not Win.Current then selectTab(Win.Tabs[1]) end
		end
	end)

	return Win
end

return Hallow
