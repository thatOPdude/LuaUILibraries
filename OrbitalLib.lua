-- =======================================================================
--   🌍 ORBITAL UI LIBRARY  v2  ("Planetfall" Edition)
--   Radial planet hub • aurora borders • orbiting moon • twinkling stars
--   Orbital-capture startup • nodes dock into the core • toast system
--   + DRAGGABLE HUB & DRAGGABLE EXPANDED VIEW
-- =======================================================================

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

local GUI_NAME = "Orbital_Main"

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

local Orbital = {
	Sounds = {
		Click  = "rbxassetid://6895079853",
		Hover  = "rbxassetid://6895079853",
		Toggle = "rbxassetid://6895079853",
		Notify = "rbxassetid://4590662766",
		Open   = "rbxassetid://4590662766",
	},
	Theme = {
		CoreBg       = Color3.fromRGB(6, 11, 20),
		InnerRing    = Color3.fromRGB(12, 24, 42),
		NodeBg       = Color3.fromRGB(10, 17, 28),
		NodeHover    = Color3.fromRGB(16, 34, 58),
		NodeActive   = Color3.fromRGB(20, 50, 82),
		Accent       = Color3.fromRGB(0, 210, 255),
		AccentGlow   = Color3.fromRGB(90, 238, 255),
		AccentDark   = Color3.fromRGB(0, 110, 165),
		Deep         = Color3.fromRGB(0, 105, 255),
		Aurora       = Color3.fromRGB(110, 255, 190),
		RedClose     = Color3.fromRGB(255, 55, 65),
		RedCloseGlow = Color3.fromRGB(255, 105, 105),
		CardBg       = Color3.fromRGB(13, 21, 34),
		CardHover    = Color3.fromRGB(20, 34, 54),
		BorderDim    = Color3.fromRGB(26, 46, 74),
		TextPrimary  = Color3.fromRGB(240, 248, 255),
		TextMuted    = Color3.fromRGB(145, 178, 208),
		Success      = Color3.fromRGB(110, 235, 150),
		Warn         = Color3.fromRGB(255, 205, 60),
	},
}
local Theme = Orbital.Theme

-- =======================================================================
--   SMALL HELPERS
-- =======================================================================
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
		Font = Enum.Font.Gotham,
		TextColor3 = Theme.TextPrimary,
		TextSize = 14,
		Text = "",
	}
	for k, v in pairs(props) do p[k] = v end
	return new("TextLabel", p, parent)
end

-- Top-light / bottom-dark bevel
local function bevel(parent, darkness)
	local d = darkness or 150
	return new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(d, d, d)),
	}, parent)
end

local SWEEP_AURORA = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 225, 255)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(110, 255, 190)),
	ColorSequenceKeypoint.new(0.66, Color3.fromRGB(150, 120, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 225, 255)),
})
local SWEEP_RED = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 60, 70)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 160, 160)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 60, 70)),
})

local GLOBES = { "🌍", "🌏", "🌎" }

local function tw(obj, props, duration, style, dir)
	local info = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local anim = TweenService:Create(obj, info, props)
	anim:Play()
	return anim
end

local function playSound(soundId, pitch, volume)
	task.spawn(function()
		local s = Instance.new("Sound")
		s.SoundId = soundId
		s.Pitch = pitch or 1
		s.Volume = volume or 0.85
		s.Parent = SoundService
		s:Play()
		Debris:AddItem(s, 4)
	end)
end

local lastHoverTick = 0
local function playHoverSound(pitch, volume)
	local now = tick()
	if now - lastHoverTick > 0.04 then
		lastHoverTick = now
		playSound(Orbital.Sounds.Hover, pitch or 1.65, volume or 0.5)
	end
end

-- =======================================================================
--   NOTIFICATIONS
-- =======================================================================
local NotifyHolder

local ACCENTS = {
	info    = Theme.AccentGlow,
	success = Theme.Success,
	warn    = Theme.Warn,
	error   = Theme.RedClose,
}

function Orbital:Notify(config)
	if not NotifyHolder or not NotifyHolder.Parent then return end
	config = config or {}
	local title    = config.Title or config.title or "🌍 Notification"
	local text     = config.Content or config.content or ""
	local duration = config.Duration or config.duration or 3.5
	local accent   = ACCENTS[string.lower(tostring(config.Type or config.type or "info"))] or ACCENTS.info

	playSound(Orbital.Sounds.Notify, 1, 0.95)

	local textH = TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(286, 10000)).Y
	local height = math.max(62, 40 + textH + 12)

	local wrap = new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
	}, NotifyHolder)

	local toast = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(1.2, 0, 0, 0),
		BackgroundColor3 = Theme.CoreBg,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, wrap)
	round(toast, UDim.new(0, 10))
	bevel(toast, 175)
	local stroke = outline(toast, accent, 1.5, 0.15)

	new("Frame", {
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
	}, toast)

	label({
		Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(1, -26, 0, 18),
	}, toast)

	label({
		Text = text, TextSize = 12, TextColor3 = Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.new(0, 16, 0, 32), Size = UDim2.new(1, -26, 0, textH),
	}, toast)

	local bar = new("Frame", {
		Position = UDim2.new(0, 16, 1, -7), Size = UDim2.new(1, -32, 0, 2),
		BackgroundColor3 = accent, BackgroundTransparency = 0.2, BorderSizePixel = 0,
	}, toast)
	round(bar)

	tw(toast, { Position = UDim2.new(0, 0, 0, 0) }, 0.45, Enum.EasingStyle.Back)
	tw(bar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

	local dismissed = false
	local function dismiss()
		if dismissed then return end
		dismissed = true
		local out = tw(toast, { Position = UDim2.new(1.2, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		out.Completed:Connect(function()
			local shrink = tw(wrap, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
			shrink.Completed:Connect(function() wrap:Destroy() end)
		end)
	end

	local clickCatcher = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5,
	}, toast)
	clickCatcher.MouseButton1Click:Connect(dismiss)

	task.delay(duration, dismiss)
	return stroke
end

-- =======================================================================
--   CREATE WINDOW
-- =======================================================================
function Orbital:CreateWindow(settings)
	settings = settings or {}
	local winTitle  = tostring(settings.Title or "ORBITAL")
	local toggleKey = settings.ToggleKey
	if toggleKey == nil then toggleKey = Enum.KeyCode.RightShift end
	local starsOn   = settings.Stars ~= false
	local moonOn    = settings.Moon ~= false

	for _, p in ipairs(candidateParents()) do
		local old = p:FindFirstChild(GUI_NAME)
		if old then pcall(function() old:Destroy() end) end
	end

	local conns = {}
	local function track(c)
		conns[#conns + 1] = c
		return c
	end

	local spinners = {}
	local function sweep(stroke, speed, seq)
		local g = new("UIGradient", { Color = seq or SWEEP_AURORA, Rotation = math.random(0, 359) }, stroke)
		spinners[#spinners + 1] = { g = g, speed = speed or 60 }
		return g
	end

	local ScreenGui = new("ScreenGui", {
		Name = GUI_NAME,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
	})

	-- ---------- master draggable anchor ----------
	local OrbitCenter = new("Frame", {
		Name = "OrbitCenter",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, ScreenGui)

	-- ---------- notification holder ----------
	NotifyHolder = new("Frame", {
		Name = "NotifyHolder",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.new(0, 320, 1, -48),
		BackgroundTransparency = 1,
		ZIndex = 10,
	}, ScreenGui)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 10),
	}, NotifyHolder)

	-- ---------- ambient glow ----------
	local GLOW_PADS  = { 46, 92, 150 }
	local GLOW_BASE  = { 0.84, 0.91, 0.965 }
	local GLOW_COLOR = { Theme.Accent, Theme.Deep, Theme.Deep }
	local Glow = {}
	for i = 1, 3 do
		local g = new("Frame", {
			Name = "Glow" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = GLOW_COLOR[i],
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, OrbitCenter)
		round(g)
		Glow[i] = g
	end
	local glowIntensity, glowTarget = 0, 0

	-- ---------- FX layer ----------
	local FX = new("Frame", {
		Name = "FX",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, OrbitCenter)
	local FXScale = new("UIScale", nil, FX)

	local function shockwave(color, fromSize, toSize, duration, thickness)
		local ring = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, fromSize, 0, fromSize),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, FX)
		round(ring)
		local st = outline(ring, color, thickness or 4, 0.1)
		tw(ring, { Size = UDim2.new(0, toSize, 0, toSize) }, duration, Enum.EasingStyle.Quint)
		tw(st, { Transparency = 1, Thickness = 0.5 }, duration)
		Debris:AddItem(ring, duration + 0.1)
	end

	-- ---------- FXTop ----------
	local FXTop = new("Frame", {
		Name = "FXTop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, OrbitCenter)
	local FXTopScale = new("UIScale", nil, FXTop)

	-- ---------- twinkling star field ----------
	local stars = {}
	if starsOn then
		for i = 1, 40 do
			local a  = math.random() * math.pi * 2
			local r  = 150 + math.random() * 290
			local sz = (math.random() < 0.2) and 3 or 2
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, math.cos(a) * r, 0.5, math.sin(a) * r),
				Size = UDim2.new(0, sz, 0, sz),
				BackgroundColor3 = (math.random() < 0.35) and Theme.AccentGlow or Color3.fromRGB(235, 245, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, FX)
			round(f)
			stars[i] = {
				f = f,
				phase = math.random() * 6.28,
				speed = 0.8 + math.random() * 1.8,
				max = 0.45 + math.random() * 0.5,
			}
		end
	end

	local function shootingStar()
		local len  = math.random(70, 130)
		local ang  = math.rad(math.random(20, 40))
		local sx   = math.random(-420, -120)
		local sy   = math.random(-330, -150)
		local dist = math.random(260, 420)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, sx, 0.5, sy),
			Size = UDim2.new(0, len, 0, 2),
			Rotation = math.deg(ang),
			BackgroundColor3 = Color3.fromRGB(225, 250, 255),
			BorderSizePixel = 0,
			ZIndex = 2,
		}, FX)
		round(f)
		new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}, f)
		tw(f, {
			Position = UDim2.new(0.5, sx + math.cos(ang) * dist, 0.5, sy + math.sin(ang) * dist),
		}, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		task.delay(0.6, function()
			if f.Parent then tw(f, { BackgroundTransparency = 1 }, 0.3) end
		end)
		Debris:AddItem(f, 1.1)
	end

	-- ---------- orbiting moon ----------
	local MOON_TRAIL = 8
	local MOON_TILT  = -0.32
	local MOON_COS, MOON_SIN = math.cos(MOON_TILT), math.sin(MOON_TILT)
	local Moon
	local moonParts = {}
	if moonOn then
		Moon = new("Frame", {
			Name = "Moon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 2,
		}, FX)
		for i = 0, MOON_TRAIL do
			local sz = (i == 0) and 14 or math.max(3, 12 - i * 1.2)
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(0, sz, 0, sz),
				BackgroundColor3 = (i == 0) and Color3.fromRGB(232, 240, 250) or Theme.AccentGlow,
				BackgroundTransparency = (i == 0) and 0 or math.min(0.95, 0.3 + i * 0.08),
				BorderSizePixel = 0,
				ZIndex = (i == 0) and 3 or 2,
			}, Moon)
			round(f)
			if i == 0 then outline(f, Theme.AccentGlow, 1.6, 0.35) end
			moonParts[i] = f
		end
	end

	-- ---------- BaseCenter (holds orbiting nodes) ----------
	local BaseCenter = new("Frame", {
		Name = "BaseCenter",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, OrbitCenter)
	local BaseScale = new("UIScale", nil, BaseCenter)

	-- ---------- floating reopen globe ----------
	local MiniEarth = new("TextButton", {
		Name = "MiniEarth",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, -0.12, 0),
		Size = UDim2.new(0, 74, 0, 74),
		BackgroundColor3 = Theme.CoreBg,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "🌍",
		TextSize = 40,
		Visible = false,
		ZIndex = 6,
	}, ScreenGui)
	round(MiniEarth)
	local MiniStroke = outline(MiniEarth, Color3.new(1, 1, 1), 3.5)
	sweep(MiniStroke, 90)

	MiniEarth.MouseEnter:Connect(function()
		tw(MiniEarth, { Size = UDim2.new(0, 84, 0, 84) }, 0.15, Enum.EasingStyle.Back)
		tw(MiniStroke, { Thickness = 4.5 }, 0.15)
		playHoverSound(1.6, 0.4)
	end)
	MiniEarth.MouseLeave:Connect(function()
		tw(MiniEarth, { Size = UDim2.new(0, 74, 0, 74) }, 0.15)
		tw(MiniStroke, { Thickness = 3.5 }, 0.15)
	end)

	-- ---------- core disc ----------
	local CoreHolder = new("Frame", {
		Name = "CoreHolder",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Theme.CoreBg,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, OrbitCenter)
	round(CoreHolder)
	bevel(CoreHolder, 190)
	local CoreScale = new("UIScale", nil, CoreHolder)

	local CoreStroke = outline(CoreHolder, Color3.new(1, 1, 1), 4.5)
	sweep(CoreStroke, 38)

	local DecRing = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -36, 1, -36),
		BackgroundTransparency = 1,
	}, CoreHolder)
	round(DecRing)
	outline(DecRing, Theme.BorderDim, 1.5, 0.35)

	local function makeOrbitRing(parent, inset, count)
		local ring = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -inset, 1, -inset),
			BackgroundTransparency = 1,
		}, parent)
		for i = 1, count do
			local a = (i / count) * 2 * math.pi
			local big = (i % 3 == 0)
			local d = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5 + math.cos(a) * 0.5, 0, 0.5 + math.sin(a) * 0.5, 0),
				Size = big and UDim2.new(0, 6, 0, 6) or UDim2.new(0, 3, 0, 3),
				BackgroundColor3 = big and Theme.AccentGlow or Theme.AccentDark,
				BackgroundTransparency = big and 0.1 or 0.4,
				BorderSizePixel = 0,
			}, ring)
			round(d)
		end
		return ring
	end

	-- Collapsed view
	local CollapsedView = new("Frame", {
		Name = "CollapsedView",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, CoreHolder)

	local OrbitRing = makeOrbitRing(CollapsedView, 54, 36)

	local InnerCoreDeco = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.62, 0, 0.62, 0),
		BackgroundColor3 = Theme.InnerRing,
		BorderSizePixel = 0,
	}, CollapsedView)
	round(InnerCoreDeco)
	bevel(InnerCoreDeco, 130)
	outline(InnerCoreDeco, Theme.AccentDark, 2, 0.35)

	local CoreIcon = label({
		Text = "🌍", TextScaled = true, TextTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.4, 0),
		Size = UDim2.new(0.3, 0, 0.3, 0),
	}, CollapsedView)

	local CoreTitle = label({
		Text = "", Font = Enum.Font.GothamBold, TextColor3 = Theme.AccentGlow, TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.7, 0),
		Size = UDim2.new(0.5, 0, 0.1, 0),
	}, CollapsedView)
	new("UITextSizeConstraint", { MaxTextSize = 18, MinTextSize = 6 }, CoreTitle)

	-- Expanded view (680px disc)
	local ExpandedView = new("Frame", {
		Name = "ExpandedView",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, CoreHolder)

	local BigOrbitRing = makeOrbitRing(ExpandedView, 70, 48)

	-- Drag zone at the top of the expanded circle
	local TopDragZone = new("Frame", {
		Name = "TopDragZone",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 110),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, ExpandedView)

	local HeaderPill = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 40),
		Size = UDim2.new(0, 280, 0, 40),
		BackgroundColor3 = Theme.CardBg,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, ExpandedView)
	round(HeaderPill)
	bevel(HeaderPill, 160)
	local HeaderStroke = outline(HeaderPill, Color3.new(1, 1, 1), 1.6, 0.2)
	sweep(HeaderStroke, 50)

	local PortalTitle = label({
		Text = "🌍 OPTIONS", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.AccentGlow,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 5,
	}, HeaderPill)

	local ReturnBtn = new("TextButton", {
		Name = "ReturnBtn",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -34),
		Size = UDim2.new(0, 180, 0, 40),
		BackgroundColor3 = Color3.fromRGB(12, 24, 40),
		Text = "◀  RETURN",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Accent,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ZIndex = 6,
	}, ExpandedView)
	round(ReturnBtn)
	local ReturnStroke = outline(ReturnBtn, Theme.BorderDim, 1.6)

	ReturnBtn.MouseEnter:Connect(function()
		playHoverSound(1.7, 0.4)
		tw(ReturnBtn, { BackgroundColor3 = Color3.fromRGB(18, 36, 60), Size = UDim2.new(0, 190, 0, 42) }, 0.15)
		tw(ReturnStroke, { Color = Theme.AccentGlow, Thickness = 2.2 }, 0.15)
		tw(ReturnBtn, { TextColor3 = Theme.AccentGlow }, 0.15)
	end)
	ReturnBtn.MouseLeave:Connect(function()
		tw(ReturnBtn, { BackgroundColor3 = Color3.fromRGB(12, 24, 40), Size = UDim2.new(0, 180, 0, 40) }, 0.15)
		tw(ReturnStroke, { Color = Theme.BorderDim, Thickness = 1.6 }, 0.15)
		tw(ReturnBtn, { TextColor3 = Theme.Accent }, 0.15)
	end)

	local PagesMask = new("CanvasGroup", {
		Name = "PagesMask",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.51, 0),
		Size = UDim2.new(0, 420, 0, 470),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = 0,
		ZIndex = 4,
	}, ExpandedView)
	new("UIGradient", {
		Name = "FadeMask",
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1.0),
			NumberSequenceKeypoint.new(0.07, 0.0),
			NumberSequenceKeypoint.new(0.93, 0.0),
			NumberSequenceKeypoint.new(1.00, 1.0),
		}),
	}, PagesMask)

	-- ---------- viewport scaling ----------
	local scales = { FXScale, FXTopScale, BaseScale, CoreScale }
	local function applyScale()
		local cam = Workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local s = math.clamp(math.min(vp.X, vp.Y) / 760, 0.45, 1)
		for _, u in ipairs(scales) do u.Scale = s end
	end
	applyScale()
	if Workspace.CurrentCamera then
		track(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale))
	end

	-- ---------- window state ----------
	local WindowHandler = {
		Tabs = {},
		Radius = 235,
		CurrentActive = nil,
		IsExpanded = false,
		IsMinimized = false,
		Started = false,
		InStartupAnim = false,
		Destroyed = false,
		PagesMask = PagesMask,
	}
	local ExpandedReady = false

	-- ===================================================================
	--   DRAGGING SYSTEM
	-- ===================================================================
	local isDragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil

	local function makeDraggable(handle)
		handle.Active = true
		track(handle.InputBegan:Connect(function(input)
			if WindowHandler.InStartupAnim or WindowHandler.IsMinimized or WindowHandler.Destroyed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				dragStart = input.Position
				startPos = OrbitCenter.Position

				local endedConn
				endedConn = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						isDragging = false
						if endedConn then endedConn:Disconnect() end
					end
				end)
				track(endedConn)
			end
		end))

		track(handle.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end))
	end

	-- Make both the collapsed planet and the expanded title/top bar draggable
	makeDraggable(CollapsedView)
	makeDraggable(HeaderPill)
	makeDraggable(TopDragZone)

	track(UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			OrbitCenter.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))

	track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end))

	-- ===================================================================
	--   NODE TARGETING & TRANSITIONS
	-- ===================================================================
	local function nodeTarget(i, total)
		local a = ((i - 1) * (2 * math.pi / total)) - (math.pi / 2)
		return math.cos(a) * WindowHandler.Radius, math.sin(a) * WindowHandler.Radius
	end

	local function resetTabVisuals(tab)
		tw(tab.Frame, { BackgroundColor3 = Theme.NodeBg }, 0.2)
		tw(tab.Stroke, {
			Transparency = 0.5,
			Thickness = 3,
		}, 0.2)
		tw(tab.DecStroke, { Transparency = 0.5, Color = Theme.BorderDim }, 0.2)
		tw(tab.InnerPlate, { BackgroundColor3 = Theme.InnerRing }, 0.2)
		tw(tab.Icon, {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			TextColor3 = tab.IsClose and Theme.RedClose or Theme.TextMuted,
			TextTransparency = 0,
		}, 0.2)
		tw(tab.Label, { TextTransparency = 1 }, 0.2)
	end

	local function resetTabToIdle(tab)
		resetTabVisuals(tab)
		tw(tab.Frame, { Size = UDim2.new(0, 130, 0, 130) }, 0.2)
	end

	local function flyIn(tab, delay)
		task.delay(delay or 0, function()
			local t = tw(tab.Frame, {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 0, 0, 0),
			}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			t.Completed:Connect(function()
				if WindowHandler.IsExpanded or WindowHandler.IsMinimized then
					tab.Frame.Visible = false
				end
			end)
		end)
	end

	local function flyOut(tab, i, delay, total)
		task.delay(delay or 0, function()
			if WindowHandler.IsExpanded or WindowHandler.IsMinimized or WindowHandler.Destroyed then return end
			local x, y = nodeTarget(i, total)
			tab.Frame.Visible = true
			resetTabVisuals(tab)
			tw(tab.Frame, {
				Position = UDim2.new(0.5, x, 0.5, y),
				Size = UDim2.new(0, 130, 0, 130),
			}, 0.5, Enum.EasingStyle.Back)
		end)
	end

	local function collapseToRadial()
		if not WindowHandler.IsExpanded or WindowHandler.IsMinimized or WindowHandler.InStartupAnim or not ExpandedReady then return end
		ExpandedReady = false
		WindowHandler.IsExpanded = false
		WindowHandler.CurrentActive = nil
		playSound(Orbital.Sounds.Click, 0.9)

		for _, tab in ipairs(WindowHandler.Tabs) do
			if tab.Page then tab.Page.Visible = false end
		end
		ExpandedView.Visible = false
		CollapsedView.Visible = true
		tw(CoreHolder, { Size = UDim2.new(0, 210, 0, 210) }, 0.5, Enum.EasingStyle.Back)

		local total = #WindowHandler.Tabs
		for i, tab in ipairs(WindowHandler.Tabs) do
			flyOut(tab, i, 0.12 + (i - 1) * 0.04, total)
		end
	end
	track(ReturnBtn.MouseButton1Click:Connect(collapseToRadial))

	function WindowHandler:Minimize()
		if self.IsMinimized or self.InStartupAnim or self.Destroyed then return end
		self.IsMinimized = true
		self.IsExpanded = false
		ExpandedReady = false
		self.CurrentActive = nil
		playSound(Orbital.Sounds.Click, 0.85)
		glowTarget = 0

		for _, tab in ipairs(self.Tabs) do
			if tab.Page then tab.Page.Visible = false end
			flyIn(tab, 0)
		end
		ExpandedView.Visible = false
		CollapsedView.Visible = true
		tw(CoreHolder, { Size = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)

		task.delay(0.37, function()
			if not self.IsMinimized or self.Destroyed then return end
			CoreHolder.Visible = false
			MiniEarth.Position = UDim2.new(0.5, 0, -0.12, 0)
			MiniEarth.Visible = true
			tw(MiniEarth, { Position = UDim2.new(0.5, 0, 0.04, 0) }, 0.45, Enum.EasingStyle.Back)
		end)
	end

	function WindowHandler:Restore()
		if not self.IsMinimized or self.InStartupAnim or self.Destroyed then return end
		self.IsMinimized = false
		playSound(Orbital.Sounds.Open, 1.1)
		glowTarget = 1

		local hide = tw(MiniEarth, { Position = UDim2.new(0.5, 0, -0.12, 0) }, 0.25)
		hide.Completed:Connect(function()
			if not self.IsMinimized then MiniEarth.Visible = false end
		end)

		CollapsedView.Visible = true
		ExpandedView.Visible = false
		CoreHolder.Size = UDim2.new(0, 0, 0, 0)
		CoreHolder.Visible = true
		tw(CoreHolder, { Size = UDim2.new(0, 210, 0, 210) }, 0.5, Enum.EasingStyle.Back)
		shockwave(Theme.AccentGlow, 160, 560, 0.8, 3.5)

		local total = #self.Tabs
		for i, tab in ipairs(self.Tabs) do
			tab.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
			tab.Frame.Size = UDim2.new(0, 0, 0, 0)
			flyOut(tab, i, 0.15 + (i - 1) * 0.05, total)
		end
	end

	function WindowHandler:Destroy()
		if self.Destroyed then return end
		self.Destroyed = true
		playSound(Orbital.Sounds.Click, 0.8, 0.9)
		glowTarget = 0
		for _, tab in ipairs(self.Tabs) do
			tw(tab.Frame, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		end
		tw(CoreHolder, { Size = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.4, function()
			for _, c in ipairs(conns) do
				pcall(function() c:Disconnect() end)
			end
			ScreenGui:Destroy()
		end)
	end

	function WindowHandler:Notify(cfg)
		Orbital:Notify(cfg)
	end

	track(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or WindowHandler.Destroyed then return end
		if toggleKey and input.KeyCode == toggleKey then
			if WindowHandler.IsMinimized then
				WindowHandler:Restore()
			else
				WindowHandler:Minimize()
			end
		end
	end))
	track(MiniEarth.MouseButton1Click:Connect(function() WindowHandler:Restore() end))

	-- ===================================================================
	--   NODE GENERATOR
	-- ===================================================================
	local function canHover()
		return (not WindowHandler.IsExpanded) and (not WindowHandler.IsMinimized) and (not WindowHandler.InStartupAnim) and (not isDragging)
	end

	local function createBaseNode(title, iconText, isClose)
		local baseCol = isClose and Theme.RedClose or Theme.Accent
		local glowCol = isClose and Theme.RedCloseGlow or Theme.AccentGlow

		local NodeFrame = new("Frame", {
			Name = title .. "_Node",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Theme.NodeBg,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 2,
		}, BaseCenter)
		round(NodeFrame)
		bevel(NodeFrame, 170)

		local NodeStroke = outline(NodeFrame, Color3.new(1, 1, 1), 3, 0.5)
		sweep(NodeStroke, isClose and 70 or 55, isClose and SWEEP_RED or SWEEP_AURORA)

		local NodeDecRing = new("Frame", {
			Name = "BevelRing",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -18, 1, -18),
			BackgroundTransparency = 1,
		}, NodeFrame)
		round(NodeDecRing)
		local NodeDecStroke = outline(NodeDecRing, Theme.BorderDim, 1.2, 0.5)

		local InnerNodePlate = new("Frame", {
			Name = "InnerPlate",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -30, 1, -30),
			BackgroundColor3 = Theme.InnerRing,
			BorderSizePixel = 0,
		}, NodeFrame)
		round(InnerNodePlate)
		bevel(InnerNodePlate, 125)

		local NodeIcon = label({
			Text = iconText or "🌍",
			Font = Enum.Font.GothamBold,
			TextSize = isClose and 44 or 42,
			TextColor3 = isClose and Theme.RedClose or Theme.TextMuted,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 56, 0, 56),
		}, InnerNodePlate)

		local NodeLabel = label({
			Text = string.upper(title),
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = isClose and Color3.fromRGB(255, 130, 130) or Theme.TextPrimary,
			TextTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(1, -10, 0, 18),
		}, InnerNodePlate)

		local ClickBtn = new("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 3,
		}, NodeFrame)

		local tab = {
			Frame = NodeFrame,
			ClickBtn = ClickBtn,
			Icon = NodeIcon,
			Label = NodeLabel,
			Stroke = NodeStroke,
			DecStroke = NodeDecStroke,
			InnerPlate = InnerNodePlate,
			Title = title,
			IsClose = isClose,
		}

		ClickBtn.MouseEnter:Connect(function()
			if not canHover() then return end
			playHoverSound(1.65, 0.4)
			tw(NodeFrame, { Size = UDim2.new(0, 148, 0, 148), BackgroundColor3 = Theme.NodeHover }, 0.2, Enum.EasingStyle.Back)
			tw(InnerNodePlate, { BackgroundColor3 = Color3.fromRGB(18, 38, 64) }, 0.2)
			tw(NodeStroke, { Transparency = 0, Thickness = 4.4 }, 0.2)
			tw(NodeDecStroke, { Transparency = 0.1, Color = Theme.AccentDark }, 0.2)
			tw(NodeIcon, { Position = UDim2.new(0.5, 0, 0.38, 0), TextColor3 = glowCol }, 0.2)
			tw(NodeLabel, { TextTransparency = 0 }, 0.2)
		end)

		ClickBtn.MouseLeave:Connect(function()
			if not canHover() then return end
			resetTabToIdle(tab)
		end)

		return tab
	end

	function WindowHandler:RealignNodes()
		local total = #self.Tabs
		if total == 0 then return end
		self.Radius = math.max(235, (total * 150) / (2 * math.pi))

		if self.InStartupAnim or self.IsExpanded or self.IsMinimized then return end

		for i, tab in ipairs(self.Tabs) do
			local x, y = nodeTarget(i, total)
			local target = UDim2.new(0.5, x, 0.5, y)
			if self.Started and tab.Frame.Visible then
				tw(tab.Frame, { Position = target }, 0.45, Enum.EasingStyle.Back)
			elseif not self.Started then
				tab.Frame.Position = target
			end
		end
	end

	local function registerTab(tab)
		table.insert(WindowHandler.Tabs, tab)
		WindowHandler:RealignNodes()
		if WindowHandler.Started and not WindowHandler.InStartupAnim and not WindowHandler.IsExpanded and not WindowHandler.IsMinimized then
			local total = #WindowHandler.Tabs
			tab.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
			tab.Frame.Size = UDim2.new(0, 0, 0, 0)
			flyOut(tab, #WindowHandler.Tabs, 0.05, total)
		end
	end

	-- ===================================================================
	--   STARTUP ANIMATION
	-- ===================================================================
	task.defer(function()
		WindowHandler.InStartupAnim = true
		CoreHolder.Size = UDim2.new(0, 0, 0, 0)
		task.wait(0.35)
		if WindowHandler.Destroyed then return end

		glowTarget = 1
		playSound(Orbital.Sounds.Open, 0.75, 1.0)
		tw(CoreHolder, { Size = UDim2.new(0, 300, 0, 300) }, 0.65, Enum.EasingStyle.Back)
		shockwave(Theme.AccentGlow, 120, 720, 1.1, 5)
		task.wait(0.55)

		tw(CoreIcon, { TextTransparency = 0 }, 0.55)
		shockwave(Theme.Deep, 200, 640, 0.9, 3)
		task.wait(0.6)
		if WindowHandler.Destroyed then return end

		playSound(Orbital.Sounds.Open, 1.15, 0.8)
		shockwave(Theme.Accent, 220, 780, 1.3, 3)

		local tabs   = WindowHandler.Tabs
		local total  = #tabs
		local R      = math.max(235, (total * 150) / (2 * math.pi))
		WindowHandler.Radius = R
		local tabDur, stagger = 1.4, 0.08
		local totalTime = tabDur + math.max(0, total - 1) * stagger

		for _, tab in ipairs(tabs) do
			tab.Frame.Size = UDim2.new(0, 0, 0, 0)
			tab.Frame.Position = UDim2.new(0.5, 0, 0.5, -60)
			tab.Frame.Visible = true
			tab.Stroke.Transparency = 0
			tab.Stroke.Thickness = 4.8
			tab.Icon.TextTransparency = 1
		end

		local startT = os.clock()
		local trailTimer = 0
		local el = 0
		repeat
			local dt = RunService.RenderStepped:Wait()
			if WindowHandler.Destroyed then return end
			el = os.clock() - startT
			local p = math.clamp(el / totalTime, 0, 1)

			local coreEase = TweenService:GetValue(p, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			local cs = 300 - (90 * coreEase)
			CoreHolder.Size = UDim2.new(0, cs, 0, cs)

			trailTimer = trailTimer + dt
			local doTrail = trailTimer > 0.045
			if doTrail then trailTimer = 0 end

			for i, tab in ipairs(tabs) do
				local tp = math.clamp((el - (i - 1) * stagger) / tabDur, 0, 1)
				local sizeEase = TweenService:GetValue(tp, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				local posEase  = TweenService:GetValue(tp, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local finalAngle = ((i - 1) * (2 * math.pi / total)) - (math.pi / 2)
				local ang = finalAngle - ((1 - posEase) * (math.pi * 1.6))
				local rad = R + ((1 - posEase) * (R * 1.5))
				local x = math.cos(ang) * rad
				local y = math.sin(ang) * rad
				local s = 130 * sizeEase

				tab.Frame.Position = UDim2.new(0.5, x, 0.5, y)
				tab.Frame.Size = UDim2.new(0, s, 0, s)
				tab.Icon.TextTransparency = 1 - math.clamp(tp * 1.6, 0, 1)

				if doTrail and tp > 0 and tp < 0.9 then
					local ts = math.random(4, 8)
					local d = new("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, x, 0.5, y),
						Size = UDim2.new(0, ts, 0, ts),
						BackgroundColor3 = Theme.AccentGlow,
						BorderSizePixel = 0,
						ZIndex = 2,
					}, FX)
					round(d)
					tw(d, { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }, 0.55)
					Debris:AddItem(d, 0.6)
				end
			end
		until el >= totalTime

		playSound(Orbital.Sounds.Notify, 1.4, 1.0)
		shockwave(Theme.AccentGlow, 210, 660, 0.9, 4)
		task.wait(0.15)
		for i, tab in ipairs(tabs) do
			task.delay((i - 1) * 0.04, function()
				resetTabToIdle(tab)
			end)
		end

		local upper = string.upper(winTitle)
		for i = 1, #upper do
			CoreTitle.Text = string.sub(upper, 1, i)
			task.wait(0.06)
		end

		WindowHandler.InStartupAnim = false
		WindowHandler.Started = true

		local newTotal = #WindowHandler.Tabs
		WindowHandler.Radius = math.max(235, (newTotal * 150) / (2 * math.pi))
		for i, tab in ipairs(WindowHandler.Tabs) do
			local x, y = nodeTarget(i, newTotal)
			if not tab.Frame.Visible then
				tab.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
				flyOut(tab, i, 0.05 * i, newTotal)
			else
				tw(tab.Frame, { Position = UDim2.new(0.5, x, 0.5, y) }, 0.45, Enum.EasingStyle.Back)
			end
		end
	end)

	-- ===================================================================
	--   MAIN RENDER LOOP
	-- ===================================================================
	local t0 = os.clock()
	local starTimer = 3
	local globeIndex = 1
	local moonFront = false
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

		glowIntensity = glowIntensity + (glowTarget - glowIntensity) * math.min(1, dt * 4)
		local flick = math.clamp(0.5 + math.noise(t * 2.2, 3.71), 0, 1)
		local sc = CoreScale.Scale
		local coreDesign = CoreHolder.Visible and CoreHolder.Size.X.Offset or 0
		local coreSize = coreDesign * sc
		for i, g in ipairs(Glow) do
			local sz = coreSize + (2 * GLOW_PADS[i] * sc * (0.94 + 0.12 * flick))
			g.Size = UDim2.new(0, sz, 0, sz)
			g.BackgroundTransparency = 1 - ((1 - GLOW_BASE[i]) * glowIntensity * (0.78 + 0.22 * flick))
		end

		OrbitRing.Rotation = (t * 7) % 360
		BigOrbitRing.Rotation = (-t * 4) % 360

		local pulse = 0.3 + 0.012 * math.sin(t * 2.4)
		CoreIcon.Size = UDim2.new(pulse, 0, pulse, 0)
		local gi = (math.floor(t / 1.8) % 3) + 1
		if gi ~= globeIndex then
			globeIndex = gi
			CoreIcon.Text = GLOBES[gi]
			MiniEarth.Text = GLOBES[gi]
		end

		for _, st in ipairs(stars) do
			local blink = 0.5 + 0.5 * math.sin(t * st.speed + st.phase)
			st.f.BackgroundTransparency = 1 - (st.max * (0.25 + 0.75 * blink) * glowIntensity)
		end

		if moonOn and Moon then
			local showMoon = coreDesign > 60 and glowIntensity > 0.25
			Moon.Visible = showMoon
			if showMoon then
				local R  = (coreDesign * 0.5) + 34
				local a0 = t * 0.6
				local front = math.sin(a0) > 0
				if front ~= moonFront then
					moonFront = front
					Moon.Parent = front and FXTop or FX
				end
				for i = 0, MOON_TRAIL do
					local a  = a0 - (i * 0.075)
					local ox = math.cos(a) * R
					local oy = math.sin(a) * R * 0.3
					local x  = (ox * MOON_COS) - (oy * MOON_SIN)
					local y  = (ox * MOON_SIN) + (oy * MOON_COS)
					moonParts[i].Position = UDim2.new(0.5, x, 0.5, y)
				end
			end
		end

		if starsOn then
			starTimer = starTimer - dt
			if starTimer <= 0 then
				starTimer = 4 + math.random() * 5
				if glowIntensity > 0.6 and not WindowHandler.IsMinimized then
					shootingStar()
				end
			end
		end
	end))

	-- ===================================================================
	--   ACTION NODE
	-- ===================================================================
	function WindowHandler:CreateActionNode(tabName, icon, callback)
		local isClose = (string.lower(tabName):find("close") ~= nil)
		local tab = createBaseNode(tabName, icon, isClose)
		registerTab(tab)

		tab.ClickBtn.MouseButton1Click:Connect(function()
			if self.IsExpanded or self.IsMinimized or self.InStartupAnim or isDragging then return end
			playSound(Orbital.Sounds.Click, 1.1, 0.95)
			tw(tab.Frame, { BackgroundColor3 = Theme.NodeActive, Size = UDim2.new(0, 120, 0, 120) }, 0.08)
			shockwave(isClose and Theme.RedClose or Theme.Accent, 150, 260, 0.45, 2)
			task.delay(0.1, function()
				if not self.IsExpanded and not self.IsMinimized and not self.Destroyed then
					tw(tab.Frame, { Size = UDim2.new(0, 148, 0, 148), BackgroundColor3 = Theme.NodeHover }, 0.2, Enum.EasingStyle.Back)
				end
			end)
			task.spawn(callback or function() end)
		end)
	end

	-- ===================================================================
	--   TAB (OPTIONS VIEW)
	-- ===================================================================
	function WindowHandler:CreateTab(tabName, icon)
		local tab = createBaseNode(tabName, icon, false)

		local Page = new("ScrollingFrame", {
			Name = tabName .. "_Page",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			ScrollBarImageTransparency = 0.4,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		}, PagesMask)

		new("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, Page)
		new("UIPadding", {
			PaddingTop = UDim.new(0, 18),
			PaddingBottom = UDim.new(0, 40),
			PaddingLeft = UDim.new(0, 4),
		}, Page)

		tab.Page = Page
		registerTab(tab)

		track(tab.ClickBtn.MouseButton1Click:Connect(function()
			if WindowHandler.IsExpanded or WindowHandler.IsMinimized or WindowHandler.InStartupAnim or isDragging then return end
			WindowHandler.IsExpanded = true
			ExpandedReady = false
			WindowHandler.CurrentActive = tab
			playSound(Orbital.Sounds.Open, 1.15, 0.95)

			for i, t in ipairs(WindowHandler.Tabs) do
				if t.Page then t.Page.Visible = false end
				flyIn(t, (i - 1) * 0.025)
			end

			tw(CoreHolder, { Size = UDim2.new(0, 680, 0, 680) }, 0.55, Enum.EasingStyle.Back)
			shockwave(Theme.AccentGlow, 220, 520, 0.6, 3)

			task.delay(0.3, function()
				if not WindowHandler.IsExpanded or WindowHandler.CurrentActive ~= tab then return end
				PortalTitle.Text = (icon or "🌍") .. "  " .. string.upper(tabName)
				Page.CanvasPosition = Vector2.new(0, 0)
				CollapsedView.Visible = false
				ExpandedView.Visible = true
				PagesMask.GroupTransparency = 1
				Page.Position = UDim2.new(0.5, 0, 0.5, 22)
				Page.Visible = true
				tw(PagesMask, { GroupTransparency = 0 }, 0.35)
				tw(Page, { Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.4, Enum.EasingStyle.Quint)
				ExpandedReady = true
			end)
		end))

		local TabElements = {}

		local function makeCapsule(h)
			local Card = new("Frame", {
				Size = UDim2.new(1, -12, 0, h or 58),
				BackgroundColor3 = Theme.CardBg,
				BackgroundTransparency = 0.04,
				BorderSizePixel = 0,
			}, Page)
			round(Card, UDim.new(0, 16))
			bevel(Card, 175)

			local stroke = outline(Card, Theme.BorderDim, 1.4)

			local Pip = new("Frame", {
				Size = UDim2.new(0, 5, 0, 22),
				Position = UDim2.new(0, 7, 0.5, -11),
				BackgroundColor3 = Theme.AccentDark,
				BorderSizePixel = 0,
			}, Card)
			round(Pip)

			local count = 0
			local function apply(on)
				if on then
					playHoverSound(1.7, 0.6)
					tw(stroke, { Color = Theme.Accent }, 0.15)
					tw(Card, { BackgroundColor3 = Theme.CardHover }, 0.15)
					tw(Pip, { BackgroundColor3 = Theme.AccentGlow, Size = UDim2.new(0, 5, 0, 32), Position = UDim2.new(0, 7, 0.5, -16) }, 0.18, Enum.EasingStyle.Back)
				else
					tw(stroke, { Color = Theme.BorderDim }, 0.2)
					tw(Card, { BackgroundColor3 = Theme.CardBg }, 0.2)
					tw(Pip, { BackgroundColor3 = Theme.AccentDark, Size = UDim2.new(0, 5, 0, 22), Position = UDim2.new(0, 7, 0.5, -11) }, 0.2)
				end
			end
			local function bind(obj)
				obj.MouseEnter:Connect(function()
					count = count + 1
					if count == 1 then apply(true) end
				end)
				obj.MouseLeave:Connect(function()
					count = math.max(0, count - 1)
					if count == 0 then apply(false) end
				end)
			end
			bind(Card)

			return Card, stroke, Pip, bind
		end

		function TabElements:CreateSection(secName)
			local sec = new("Frame", {
				Size = UDim2.new(1, -12, 0, 34),
				BackgroundTransparency = 1,
			}, Page)

			label({
				Text = "✦  " .. string.upper(secName), Font = Enum.Font.GothamBold, TextSize = 13,
				TextColor3 = Theme.AccentGlow, TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -16, 0, 20),
			}, sec)

			local line = new("Frame", {
				Size = UDim2.new(1, -16, 0, 1),
				Position = UDim2.new(0, 8, 1, -2),
				BackgroundColor3 = Theme.AccentDark,
				BorderSizePixel = 0,
			}, sec)
			new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}, line)
		end

		function TabElements:CreateLabel(text)
			local Card = makeCapsule(40)
			label({
				Text = tostring(text or ""), TextSize = 13, TextColor3 = Theme.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -40, 1, 0),
			}, Card)
		end

		function TabElements:CreateButton(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Button"
			local desc = opts.Description or opts.Desc or ""
			local callback = opts.Callback or function() end
			local hasDesc = (desc ~= "")

			local Card, stroke, pip, bind = makeCapsule(hasDesc and 68 or 54)

			local ClickArea = new("TextButton", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 2,
			}, Card)
			bind(ClickArea)

			label({
				Text = name, Font = Enum.Font.GothamSemibold, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 20, 0, hasDesc and 11 or 0),
				Size = UDim2.new(1, -70, 0, hasDesc and 18 or 54),
			}, Card)

			if hasDesc then
				label({
					Text = desc, TextSize = 12, TextColor3 = Theme.TextMuted,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 20, 0, 35), Size = UDim2.new(1, -70, 0, 18),
				}, Card)
			end

			label({
				Text = "🌍", TextSize = 20,
				Position = UDim2.new(1, -42, 0.5, -12), Size = UDim2.new(0, 24, 0, 24),
			}, Card)

			ClickArea.MouseButton1Click:Connect(function()
				playSound(Orbital.Sounds.Click, 1.0, 0.95)
				local flash = tw(Card, { BackgroundColor3 = Color3.fromRGB(20, 46, 76) }, 0.1)
				flash.Completed:Connect(function()
					tw(Card, { BackgroundColor3 = Theme.CardHover }, 0.2)
				end)
				task.spawn(callback)
			end)
		end
		TabElements.AddButton = TabElements.CreateButton

		function TabElements:CreateToggle(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Toggle"
			local desc = opts.Description or opts.Desc or ""
			local state = opts.Default or false
			local callback = opts.Callback or function() end
			local hasDesc = (desc ~= "")

			local Card, stroke, pip, bind = makeCapsule(hasDesc and 68 or 56)

			label({
				Text = name, Font = Enum.Font.GothamSemibold, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 20, 0, hasDesc and 11 or 0),
				Size = UDim2.new(1, -96, 0, hasDesc and 18 or 56),
			}, Card)

			if hasDesc then
				label({
					Text = desc, TextSize = 12, TextColor3 = Theme.TextMuted,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 20, 0, 35), Size = UDim2.new(1, -96, 0, 18),
				}, Card)
			end

			local Switch = new("TextButton", {
				Size = UDim2.new(0, 54, 0, 28),
				Position = UDim2.new(1, -68, 0.5, -14),
				BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(16, 28, 46),
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
			}, Card)
			round(Switch)
			local SwitchStroke = outline(Switch, state and Theme.AccentGlow or Theme.BorderDim, 1.4)
			bind(Switch)

			local Thumb = new("Frame", {
				Size = UDim2.new(0, 20, 0, 20),
				Position = state and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10),
				BackgroundColor3 = Color3.fromRGB(240, 248, 255),
				BorderSizePixel = 0,
			}, Switch)
			round(Thumb)

			local function paint(v)
				if v then
					tw(Switch, { BackgroundColor3 = Theme.Accent }, 0.18)
					tw(SwitchStroke, { Color = Theme.AccentGlow }, 0.18)
					tw(Thumb, { Position = UDim2.new(1, -24, 0.5, -10) }, 0.25, Enum.EasingStyle.Back)
				else
					tw(Switch, { BackgroundColor3 = Color3.fromRGB(16, 28, 46) }, 0.18)
					tw(SwitchStroke, { Color = Theme.BorderDim }, 0.18)
					tw(Thumb, { Position = UDim2.new(0, 4, 0.5, -10) }, 0.25, Enum.EasingStyle.Back)
				end
			end

			Switch.MouseButton1Click:Connect(function()
				state = not state
				playSound(Orbital.Sounds.Toggle, state and 1.3 or 0.85, 0.95)
				paint(state)
				task.spawn(callback, state)
			end)

			local api = {}
			function api:Set(v, silent)
				state = v and true or false
				paint(state)
				if not silent then task.spawn(callback, state) end
			end
			function api:Get() return state end
			return api
		end
		TabElements.AddToggle = TabElements.CreateToggle

		function TabElements:CreateSlider(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Slider"
			local min = tonumber(opts.Min) or 0
			local max = tonumber(opts.Max) or 100
			local step = tonumber(opts.Increment or opts.Step) or 1
			local def = math.clamp(tonumber(opts.Default) or min, min, max)
			local callback = opts.Callback or function() end

			local decimals = 0
			if step < 1 then
				local s = tostring(step)
				local dot = s:find("%.")
				decimals = dot and (#s - dot) or 1
			end
			local function formatVal(v)
				if decimals > 0 then
					return string.format("%." .. decimals .. "f", v)
				end
				return tostring(math.floor(v + 0.5))
			end

			local Card, stroke, pip, bind = makeCapsule(70)

			label({
				Text = name, Font = Enum.Font.GothamSemibold, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 20, 0, 9), Size = UDim2.new(1, -90, 0, 18),
			}, Card)

			local valLbl = label({
				Text = formatVal(def), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.AccentGlow,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -72, 0, 9), Size = UDim2.new(0, 56, 0, 18),
			}, Card)

			local Track = new("TextButton", {
				Size = UDim2.new(1, -42, 0, 8),
				Position = UDim2.new(0, 20, 0, 46),
				BackgroundColor3 = Color3.fromRGB(16, 28, 46),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
			}, Card)
			round(Track)
			outline(Track, Theme.BorderDim, 1, 0.3)
			bind(Track)

			local startPercent = (def - min) / math.max(0.0001, (max - min))
			local Fill = new("Frame", {
				Size = UDim2.new(startPercent, 0, 1, 0),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
			}, Track)
			round(Fill)
			new("UIGradient", {
				Color = ColorSequence.new(Theme.AccentDark, Theme.AccentGlow),
			}, Fill)

			local Knob = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),
				BackgroundColor3 = Color3.fromRGB(240, 248, 255),
				BorderSizePixel = 0,
				ZIndex = 2,
			}, Fill)
			round(Knob)
			outline(Knob, Theme.Accent, 2)

			local sliding = false
			local function setVisual(v)
				local pos = math.clamp((v - min) / math.max(0.0001, (max - min)), 0, 1)
				valLbl.Text = formatVal(v)
				tw(Fill, { Size = UDim2.new(pos, 0, 1, 0) }, 0.05)
			end

			local function updateFromInput(input)
				local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / math.max(1, Track.AbsoluteSize.X), 0, 1)
				local rawVal = min + ((max - min) * pos)
				local stepped = math.floor((rawVal / step) + 0.5) * step
				local v = math.clamp(stepped, min, max)
				setVisual(v)
				task.spawn(callback, tonumber(formatVal(v)) or v)
			end

			Track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					playSound(Orbital.Sounds.Click, 1.4, 0.8)
					tw(Knob, { Size = UDim2.new(0, 22, 0, 22) }, 0.12, Enum.EasingStyle.Back)
					updateFromInput(input)
				end
			end)
			track(UserInputService.InputEnded:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					sliding = false
					tw(Knob, { Size = UDim2.new(0, 16, 0, 16) }, 0.15)
				end
			end))
			track(UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromInput(input)
				end
			end))

			local api = {}
			function api:Set(v, fire)
				v = math.clamp(tonumber(v) or min, min, max)
				setVisual(v)
				if fire then task.spawn(callback, v) end
			end
			return api
		end
		TabElements.AddSlider = TabElements.CreateSlider

		function TabElements:CreateDropdown(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Dropdown"
			local items = opts.Options or {}
			local selected = opts.Default or (items[1] or "Select...")
			local callback = opts.Callback or function() end

			local expanded = false
			local itemHeight = 36
			local collapsedHeight = 54

			local Card, stroke, pip, bind = makeCapsule(collapsedHeight)
			Card.ClipsDescendants = true

			local HeaderBtn = new("TextButton", {
				Size = UDim2.new(1, 0, 0, collapsedHeight), BackgroundTransparency = 1, Text = "", ZIndex = 2,
			}, Card)
			bind(HeaderBtn)

			label({
				Text = name, Font = Enum.Font.GothamSemibold, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(0.5, 0, 0, collapsedHeight),
			}, Card)

			local curLbl = label({
				Text = tostring(selected), TextSize = 13, TextColor3 = Theme.AccentGlow,
				TextXAlignment = Enum.TextXAlignment.Right,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -44, 0, 0), Size = UDim2.new(0.4, 0, 0, collapsedHeight),
			}, Card)

			local Arrow = label({
				Text = "▼", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.TextMuted,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -26, 0, collapsedHeight / 2), Size = UDim2.new(0, 16, 0, 18),
			}, Card)

			local ListHolder = new("Frame", {
				Size = UDim2.new(1, -24, 0, #items * (itemHeight + 4)),
				Position = UDim2.new(0, 12, 0, collapsedHeight + 2),
				BackgroundTransparency = 1,
			}, Card)
			new("UIListLayout", { Padding = UDim.new(0, 4) }, ListHolder)

			local function choose(item, fire)
				selected = item
				curLbl.Text = tostring(item)
				if fire then task.spawn(callback, selected) end
			end

			local function collapse()
				expanded = false
				tw(Arrow, { Rotation = 0 }, 0.2)
				tw(Card, { Size = UDim2.new(1, -12, 0, collapsedHeight) }, 0.25)
			end

			for _, item in ipairs(items) do
				local itmBtn = new("TextButton", {
					Size = UDim2.new(1, 0, 0, itemHeight),
					BackgroundColor3 = Color3.fromRGB(12, 24, 40),
					BorderSizePixel = 0,
					Font = Enum.Font.Gotham,
					TextSize = 13,
					TextColor3 = Theme.TextPrimary,
					Text = "   " .. tostring(item),
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
				}, ListHolder)
				round(itmBtn, UDim.new(0, 8))

				itmBtn.MouseEnter:Connect(function()
					playHoverSound(1.85, 0.5)
					tw(itmBtn, { BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.AccentGlow }, 0.12)
				end)
				itmBtn.MouseLeave:Connect(function()
					tw(itmBtn, { BackgroundColor3 = Color3.fromRGB(12, 24, 40), TextColor3 = Theme.TextPrimary }, 0.12)
				end)
				itmBtn.MouseButton1Click:Connect(function()
					playSound(Orbital.Sounds.Click, 1.2, 0.9)
					choose(item, true)
					collapse()
				end)
			end

			HeaderBtn.MouseButton1Click:Connect(function()
				expanded = not expanded
				playSound(Orbital.Sounds.Click, 1.0, 0.9)
				local targetH = expanded and (collapsedHeight + (#items * (itemHeight + 4)) + 10) or collapsedHeight
				tw(Arrow, { Rotation = expanded and 180 or 0 }, 0.25)
				tw(Card, { Size = UDim2.new(1, -12, 0, targetH) }, 0.3, Enum.EasingStyle.Quint)
			end)

			local api = {}
			function api:Set(v, fire) choose(v, fire) end
			function api:Get() return selected end
			return api
		end

		function TabElements:CreateKeybind(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Keybind"
			local currentKey = opts.Default or Enum.KeyCode.None
			local callback = opts.Callback or function() end
			local onChange = opts.OnChange or function() end

			local Card, stroke, pip, bind = makeCapsule(56)

			label({
				Text = name, Font = Enum.Font.GothamSemibold, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
			}, Card)

			local KeyBtn = new("TextButton", {
				Size = UDim2.new(0, 96, 0, 30),
				Position = UDim2.new(1, -110, 0.5, -15),
				BackgroundColor3 = Color3.fromRGB(16, 28, 46),
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextColor3 = Theme.AccentGlow,
				Text = currentKey == Enum.KeyCode.None and "None" or currentKey.Name,
				AutoButtonColor = false,
			}, Card)
			round(KeyBtn, UDim.new(0, 8))
			local KeyStroke = outline(KeyBtn, Theme.BorderDim, 1.3)
			bind(KeyBtn)

			local listening = false
			KeyBtn.MouseButton1Click:Connect(function()
				listening = true
				KeyBtn.Text = "..."
				tw(KeyStroke, { Color = Theme.AccentGlow }, 0.15)
				playSound(Orbital.Sounds.Click, 1.25, 0.9)
			end)

			track(UserInputService.InputBegan:Connect(function(input, gpe)
				if listening then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						listening = false
						tw(KeyStroke, { Color = Theme.BorderDim }, 0.15)
						if input.KeyCode ~= Enum.KeyCode.Escape then
							currentKey = input.KeyCode
							playSound(Orbital.Sounds.Click, 0.95, 0.95)
							task.spawn(onChange, currentKey)
						end
						KeyBtn.Text = currentKey == Enum.KeyCode.None and "None" or currentKey.Name
					end
				elseif not gpe and currentKey ~= Enum.KeyCode.None and input.KeyCode == currentKey then
					task.spawn(callback, currentKey)
				end
			end))
		end

		function TabElements:CreateInput(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Input"
			local callback = opts.Callback or function() end

			local Card, stroke, pip, bind = makeCapsule(56)

			label({
				Text = name, Font = Enum.Font.GothamSemibold, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(0.5, -20, 1, 0),
			}, Card)

			local Box = new("TextBox", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.new(0.44, 0, 0, 32),
				BackgroundColor3 = Color3.fromRGB(16, 28, 46),
				BorderSizePixel = 0,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Theme.TextPrimary,
				PlaceholderText = opts.Placeholder or "Type here...",
				PlaceholderColor3 = Theme.TextMuted,
				Text = opts.Default or "",
				ClearTextOnFocus = opts.ClearOnFocus or false,
				ClipsDescendants = true,
			}, Card)
			round(Box, UDim.new(0, 8))
			local BoxStroke = outline(Box, Theme.BorderDim, 1.3)
			bind(Box)

			Box.Focused:Connect(function()
				tw(BoxStroke, { Color = Theme.AccentGlow, Thickness = 1.8 }, 0.15)
			end)
			Box.FocusLost:Connect(function(enterPressed)
				tw(BoxStroke, { Color = Theme.BorderDim, Thickness = 1.3 }, 0.15)
				task.spawn(callback, Box.Text, enterPressed)
			end)

			local api = {}
			function api:Set(v) Box.Text = tostring(v) end
			function api:Get() return Box.Text end
			return api
		end

		function TabElements:CreateParagraph(opts)
			opts = opts or {}
			local title = opts.Title or "Information"
			local content = opts.Content or ""

			local textH = TextService:GetTextSize(content, 13, Enum.Font.Gotham, Vector2.new(360, 10000)).Y
			local Card = makeCapsule(math.max(64, 44 + textH + 14))

			label({
				Text = title, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.AccentGlow,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 20, 0, 12), Size = UDim2.new(1, -40, 0, 18),
			}, Card)

			label({
				Text = content, TextSize = 13, TextColor3 = Theme.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				Position = UDim2.new(0, 20, 0, 36), Size = UDim2.new(1, -40, 0, textH),
			}, Card)
		end

		return TabElements
	end

	for _, p in ipairs(candidateParents()) do
		local ok = pcall(function() ScreenGui.Parent = p end)
		if ok and ScreenGui.Parent == p then break end
	end

	return WindowHandler
end

return Orbital
