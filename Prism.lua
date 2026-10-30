-- =======================================================================
--   💎 PRISM UI LIBRARY  v2.0  (Realistic 2.5D Gemstone Engine)
--   Point-light sheen reflections • internal crystal refraction
--   Perspective foreshortening • dynamic bevel illumination
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

local GUI_NAME = "Prism_Main"
local SQ = 0.70710678 -- 1 / sqrt(2)

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

local Prism = {
	Sounds = {
		Click  = "rbxassetid://6895079853",
		Hover  = "rbxassetid://6895079853",
		Toggle = "rbxassetid://6895079853",
		Notify = "rbxassetid://4590662766",
		Open   = "rbxassetid://4590662766",
	},
	Theme = {
		CoreBg       = Color3.fromRGB(9, 8, 20),
		InnerRing    = Color3.fromRGB(21, 17, 44),
		NodeBg       = Color3.fromRGB(13, 11, 28),
		NodeHover    = Color3.fromRGB(32, 24, 68),
		NodeActive   = Color3.fromRGB(48, 34, 96),
		Accent       = Color3.fromRGB(160, 110, 255),
		AccentGlow   = Color3.fromRGB(205, 182, 255),
		AccentDark   = Color3.fromRGB(84, 58, 168),
		Deep         = Color3.fromRGB(86, 70, 255),
		Ice          = Color3.fromRGB(110, 232, 255),
		Pink         = Color3.fromRGB(255, 125, 215),
		RedClose     = Color3.fromRGB(255, 70, 95),
		RedCloseGlow = Color3.fromRGB(255, 125, 140),
		CardBg       = Color3.fromRGB(17, 14, 37),
		CardHover    = Color3.fromRGB(29, 23, 60),
		BorderDim    = Color3.fromRGB(48, 40, 96),
		TextPrimary  = Color3.fromRGB(245, 241, 255),
		TextMuted    = Color3.fromRGB(164, 154, 210),
		Success      = Color3.fromRGB(110, 235, 170),
		Warn         = Color3.fromRGB(255, 205, 80),
	},
}
local Theme = Prism.Theme

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

local function round(parent, px)
	local r = px and UDim.new(0, px) or UDim.new(1, 0)
	return new("UICorner", { CornerRadius = r }, parent)
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

local function bevel(parent, darkness, rotation)
	local d = darkness or 150
	return new("UIGradient", {
		Rotation = rotation or 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(d, d, d)),
	}, parent)
end

local function diamond(parent, props, scale)
	local p = {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(SQ * (scale or 1), 0, SQ * (scale or 1), 0),
		Rotation = 45,
		BorderSizePixel = 0,
	}
	if props then
		for k, v in pairs(props) do p[k] = v end
	end
	return new("Frame", p, parent)
end

local PRISM = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(100, 232, 255)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(165, 115, 255)),
	ColorSequenceKeypoint.new(0.70, Color3.fromRGB(255, 125, 215)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(100, 232, 255)),
})
local PRISM_RED = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 70, 95)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 170)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 70, 95)),
})

-- Realistic point specular glint curve (sharp central gleam that tapers off)
local GEM_SPECULAR = NumberSequence.new({
	NumberSequenceKeypoint.new(0.00, 1.0),
	NumberSequenceKeypoint.new(0.35, 1.0),
	NumberSequenceKeypoint.new(0.48, 0.55),
	NumberSequenceKeypoint.new(0.50, 0.25),
	NumberSequenceKeypoint.new(0.52, 0.55),
	NumberSequenceKeypoint.new(0.65, 1.0),
	NumberSequenceKeypoint.new(1.00, 1.0),
})

local PTS = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }
local function perimeterPoint(u, R)
	u = u % 1
	local seg = math.floor(u * 4)
	local f = (u * 4) - seg
	local a, b = PTS[seg + 1], PTS[seg + 2]
	return (a[1] + (b[1] - a[1]) * f) * R, (a[2] + (b[2] - a[2]) * f) * R
end

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
		playSound(Prism.Sounds.Hover, pitch or 1.65, volume or 0.5)
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

function Prism:Notify(config)
	if not NotifyHolder or not NotifyHolder.Parent then return end
	config = config or {}
	local title    = config.Title or config.title or "💎 Notification"
	local text     = config.Content or config.content or ""
	local duration = config.Duration or config.duration or 3.5
	local accent   = ACCENTS[string.lower(tostring(config.Type or config.type or "info"))] or ACCENTS.info

	playSound(Prism.Sounds.Notify, 1, 0.95)

	local textH = TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(280, 10000)).Y
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
	round(toast, 8)
	bevel(toast, 175)
	outline(toast, accent, 1.5, 0.15)

	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 16, 0, 20),
		Size = UDim2.new(0, 8, 0, 8),
		Rotation = 45,
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
	}, toast)

	label({
		Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 30, 0, 11), Size = UDim2.new(1, -40, 0, 18),
	}, toast)

	label({
		Text = text, TextSize = 12, TextColor3 = Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.new(0, 16, 0, 34), Size = UDim2.new(1, -28, 0, textH),
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
end

-- =======================================================================
--   CREATE WINDOW
-- =======================================================================
function Prism:CreateWindow(settings)
	settings = settings or {}
	local winTitle  = tostring(settings.Title or "PRISM")
	local toggleKey = settings.ToggleKey
	if toggleKey == nil then toggleKey = Enum.KeyCode.RightShift end
	local parallax  = tonumber(settings.Parallax) or 1
	local shardsOn  = settings.Shards ~= false

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
		local g = new("UIGradient", { Color = seq or PRISM, Rotation = math.random(0, 359) }, stroke)
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

	-- ===================================================================
	--   STAGE & DEPTH ENGINE
	-- ===================================================================
	local Stage = new("Frame", {
		Name = "Stage",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
	}, ScreenGui)
	local StageScale = new("UIScale", nil, Stage)

	local layers = {}
	local function addLayer(obj, depth)
		layers[#layers + 1] = { obj = obj, base = obj.Position, depth = depth }
	end

	local Shadow = new("Frame", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 36),
		Size = UDim2.new(0, 0, 0, 0),
		Rotation = 45,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, Stage)
	round(Shadow, 24)
	addLayer(Shadow, -1.8)

	local GLOW_PADS  = { 50, 110, 180 }
	local GLOW_BASE  = { 0.85, 0.92, 0.965 }
	local GLOW_COLOR = { Theme.Accent, Theme.Deep, Theme.Ice }
	local GLOW_ROUND = { 30, 50, 80 }
	local Glow = {}
	for i = 1, 3 do
		local g = new("Frame", {
			Name = "Glow" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			Rotation = 45,
			BackgroundColor3 = GLOW_COLOR[i],
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, Stage)
		round(g, GLOW_ROUND[i])
		addLayer(g, -0.9)
		Glow[i] = g
	end
	local glowIntensity, glowTarget = 0, 0

	local shards = {}
	if shardsOn then
		local palette = { Theme.Ice, Theme.Accent, Theme.Pink, Color3.fromRGB(235, 240, 255) }
		for i = 1, 18 do
			local depth = -0.8 + math.random() * 2.6
			local ang = math.random() * math.pi * 2
			local rad = 330 + math.random() * 250
			local sz = 5 + math.max(0, depth + 0.8) * 5 + math.random() * 4
			local sx, sy = math.cos(ang) * rad, math.sin(ang) * rad
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, sx, 0.5, sy),
				Size = UDim2.new(0, sz, 0, sz),
				Rotation = 45,
				BackgroundColor3 = palette[math.random(1, #palette)],
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = (depth < 0.4) and 3 or 7,
			}, Stage)
			shards[i] = {
				f = f, x = sx, y = sy, depth = depth,
				sp = 0.4 + math.random() * 0.8,
				ph = math.random() * 6.28,
				bob = 4 + math.random() * 8,
				a = 0.3 + 0.6 * ((depth + 0.8) / 2.6),
			}
		end
	end
	local shardMul = 0

	local FX = new("Frame", {
		Name = "FX",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, Stage)

	local function shockwave(color, fromD, toD, duration, thickness)
		local ring = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, fromD * SQ, 0, fromD * SQ),
			Rotation = 45,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, FX)
		round(ring, 14)
		local st = outline(ring, color, thickness or 4, 0.1)
		tw(ring, { Size = UDim2.new(0, toD * SQ, 0, toD * SQ) }, duration, Enum.EasingStyle.Quint)
		tw(st, { Transparency = 1, Thickness = 0.5 }, duration)
		Debris:AddItem(ring, duration + 0.1)
	end

	local MiniGem = new("TextButton", {
		Name = "MiniGem",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, -0.12, 0),
		Size = UDim2.new(0, 80, 0, 80),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 8,
	}, ScreenGui)
	local MiniBody = diamond(MiniGem, { BackgroundColor3 = Theme.CoreBg }, 1)
	round(MiniBody, 8)
	bevel(MiniBody, 170, 45)
	local MiniStroke = outline(MiniBody, Color3.new(1, 1, 1), 3.5)
	sweep(MiniStroke, 90)
	label({
		Text = "💎", TextSize = 30,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 1, 0),
	}, MiniGem)

	MiniGem.MouseEnter:Connect(function()
		tw(MiniGem, { Size = UDim2.new(0, 92, 0, 92) }, 0.18, Enum.EasingStyle.Back)
		tw(MiniStroke, { Thickness = 4.5 }, 0.15)
		playHoverSound(1.6, 0.4)
	end)
	MiniGem.MouseLeave:Connect(function()
		tw(MiniGem, { Size = UDim2.new(0, 80, 0, 80) }, 0.15)
		tw(MiniStroke, { Thickness = 3.5 }, 0.15)
	end)

	local COLLAPSED_D = 250
	local EXPANDED_D  = 920

	local CoreRoot = new("Frame", {
		Name = "CoreRoot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, Stage)

	local Body = diamond(CoreRoot, { BackgroundColor3 = Theme.CoreBg, ZIndex = 1 }, 1)
	round(Body, 12)
	local CoreBevel = bevel(Body, 175, 45)
	local CoreStroke = outline(Body, Color3.new(1, 1, 1), 4.5)
	sweep(CoreStroke, 35)

	local BodySheen = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, Body)
	round(BodySheen, 12)
	local BodySheenGrad = new("UIGradient", { Rotation = 45, Transparency = GEM_SPECULAR }, BodySheen)

	local Inner1 = diamond(CoreRoot, { BackgroundTransparency = 1, ZIndex = 2 }, 0.72)
	round(Inner1, 8)
	outline(Inner1, Theme.AccentGlow, 1.4, 0.55)
	addLayer(Inner1, -0.5)

	local function facetLine(yScale, widthScale, alpha)
		local line = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, yScale, 0),
			Size = UDim2.new(widthScale, 0, 0, 2),
			BackgroundColor3 = Theme.AccentGlow,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, CoreRoot)
		new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0.0, alpha),
				NumberSequenceKeypoint.new(0.3, math.min(1, alpha + 0.55)),
				NumberSequenceKeypoint.new(0.5, 1),
				NumberSequenceKeypoint.new(0.7, math.min(1, alpha + 0.55)),
				NumberSequenceKeypoint.new(1.0, alpha),
			}),
		}, line)
		return line
	end
	facetLine(0.5, 1.0, 0.15)
	facetLine(0.3, 0.58, 0.45)
	facetLine(0.7, 0.58, 0.45)

	local jewels = {}
	local jewelPos = {
		UDim2.new(0.5, 0, 0, 0), UDim2.new(1, 0, 0.5, 0),
		UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 0, 0.5, 0),
	}
	for i = 1, 4 do
		local j = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = jewelPos[i],
			Size = UDim2.new(0, 12, 0, 12),
			Rotation = 45,
			BackgroundColor3 = Theme.AccentGlow,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, CoreRoot)
		outline(j, Color3.fromRGB(255, 255, 255), 1.2, 0.3)
		addLayer(j, 0.6)
		jewels[i] = j
	end

	local CollapsedView = new("Frame", {
		Name = "CollapsedView",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, CoreRoot)

	local Inner2 = diamond(CollapsedView, { BackgroundColor3 = Theme.InnerRing, ZIndex = 1 }, 0.5)
	round(Inner2, 6)
	local Inner2Bevel = bevel(Inner2, 140, 45)
	outline(Inner2, Theme.Accent, 2, 0.35)
	addLayer(Inner2, -1.0)

	local CoreIcon = label({
		Text = "💎", TextScaled = true, TextTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.45, 0),
		Size = UDim2.new(0.26, 0, 0.26, 0),
		ZIndex = 2,
	}, CollapsedView)
	addLayer(CoreIcon, 1.1)

	local CoreTitle = label({
		Text = "", Font = Enum.Font.GothamBold, TextColor3 = Theme.AccentGlow, TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.8, 0),
		Size = UDim2.new(0.38, 0, 0.09, 0),
		ZIndex = 2,
	}, CollapsedView)
	new("UITextSizeConstraint", { MaxTextSize = 18, MinTextSize = 6 }, CoreTitle)
	addLayer(CoreTitle, 1.4)

	local ExpandedView = new("Frame", {
		Name = "ExpandedView",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 7,
	}, CoreRoot)

	local HeaderPill = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -284),
		Size = UDim2.new(0, 240, 0, 36),
		BackgroundColor3 = Theme.CardBg,
		BorderSizePixel = 0,
	}, ExpandedView)
	round(HeaderPill, 8)
	bevel(HeaderPill, 160)
	local HeaderStroke = outline(HeaderPill, Color3.new(1, 1, 1), 1.6, 0.2)
	sweep(HeaderStroke, 50)
	addLayer(HeaderPill, 1.3)

	local PortalTitle = label({
		Text = "💎 OPTIONS", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.AccentGlow,
		Size = UDim2.new(1, 0, 1, 0),
	}, HeaderPill)

	local ReturnBtn = new("TextButton", {
		Name = "ReturnBtn",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 284),
		Size = UDim2.new(0, 170, 0, 36),
		BackgroundColor3 = Color3.fromRGB(24, 19, 52),
		Text = "◀  RETURN",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Accent,
		BorderSizePixel = 0,
		AutoButtonColor = false,
	}, ExpandedView)
	round(ReturnBtn, 8)
	local ReturnStroke = outline(ReturnBtn, Theme.BorderDim, 1.6)
	addLayer(ReturnBtn, 1.3)

	ReturnBtn.MouseEnter:Connect(function()
		playHoverSound(1.7, 0.4)
		tw(ReturnBtn, { BackgroundColor3 = Color3.fromRGB(40, 30, 82), Size = UDim2.new(0, 182, 0, 38) }, 0.15)
		tw(ReturnStroke, { Color = Theme.AccentGlow, Thickness = 2.2 }, 0.15)
		tw(ReturnBtn, { TextColor3 = Theme.AccentGlow }, 0.15)
	end)
	ReturnBtn.MouseLeave:Connect(function()
		tw(ReturnBtn, { BackgroundColor3 = Color3.fromRGB(24, 19, 52), Size = UDim2.new(0, 170, 0, 36) }, 0.15)
		tw(ReturnStroke, { Color = Theme.BorderDim, Thickness = 1.6 }, 0.15)
		tw(ReturnBtn, { TextColor3 = Theme.Accent }, 0.15)
	end)

	local PagesMask = new("CanvasGroup", {
		Name = "PagesMask",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 390, 0, 500),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = 0,
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
	addLayer(PagesMask, 0.7)

	local BaseCenter = new("Frame", {
		Name = "BaseCenter",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, Stage)
	addLayer(BaseCenter, 0.7)

	local function applyScale()
		local cam = Workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		StageScale.Scale = math.clamp(math.min(vp.X, vp.Y) / 1000, 0.4, 1)
	end
	applyScale()
	if Workspace.CurrentCamera then
		track(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale))
	end

	local WindowHandler = {
		Tabs = {},
		Radius = 250,
		CurrentActive = nil,
		IsExpanded = false,
		IsMinimized = false,
		Started = false,
		InStartupAnim = false,
		Destroyed = false,
		PagesMask = PagesMask,
	}
	local ExpandedReady = false

	local function nodeRadius(total)
		return math.max(250, total * 27)
	end

	local function nodeTarget(i, total)
		return perimeterPoint((i - 1) / total, WindowHandler.Radius)
	end

	local function resetTabVisuals(tab)
		tab.liftT = 0
		tw(tab.Body, { BackgroundColor3 = Theme.NodeBg }, 0.2)
		tw(tab.Stroke, { Transparency = 0.5, Thickness = 3 }, 0.2)
		tw(tab.DecStroke, { Transparency = 0.5, Color = Theme.BorderDim }, 0.2)
		tw(tab.InnerPlate, { BackgroundColor3 = Theme.InnerRing }, 0.2)
		tw(tab.Icon, {
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
			tab.liftT = 0
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
		playSound(Prism.Sounds.Click, 0.9)

		for _, tab in ipairs(WindowHandler.Tabs) do
			if tab.Page then tab.Page.Visible = false end
		end
		ExpandedView.Visible = false
		CollapsedView.Visible = true
		tw(CoreRoot, { Size = UDim2.new(0, COLLAPSED_D, 0, COLLAPSED_D) }, 0.5, Enum.EasingStyle.Back)

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
		playSound(Prism.Sounds.Click, 0.85)
		glowTarget = 0

		for _, tab in ipairs(self.Tabs) do
			if tab.Page then tab.Page.Visible = false end
			flyIn(tab, 0)
		end
		ExpandedView.Visible = false
		CollapsedView.Visible = true
		tw(CoreRoot, { Size = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)

		task.delay(0.37, function()
			if not self.IsMinimized or self.Destroyed then return end
			CoreRoot.Visible = false
			MiniGem.Position = UDim2.new(0.5, 0, -0.12, 0)
			MiniGem.Visible = true
			tw(MiniGem, { Position = UDim2.new(0.5, 0, 0.04, 0) }, 0.45, Enum.EasingStyle.Back)
		end)
	end

	function WindowHandler:Restore()
		if not self.IsMinimized or self.InStartupAnim or self.Destroyed then return end
		self.IsMinimized = false
		playSound(Prism.Sounds.Open, 1.1)
		glowTarget = 1

		local hide = tw(MiniGem, { Position = UDim2.new(0.5, 0, -0.12, 0) }, 0.25)
		hide.Completed:Connect(function()
			if not self.IsMinimized then MiniGem.Visible = false end
		end)

		CollapsedView.Visible = true
		ExpandedView.Visible = false
		CoreRoot.Size = UDim2.new(0, 0, 0, 0)
		CoreRoot.Visible = true
		tw(CoreRoot, { Size = UDim2.new(0, COLLAPSED_D, 0, COLLAPSED_D) }, 0.5, Enum.EasingStyle.Back)
		shockwave(Theme.AccentGlow, 160, 600, 0.8, 3.5)

		local total = #self.Tabs
		for i, tab in ipairs(self.Tabs) do
			tab.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
			tab.Frame.Size = UDim2.new(0, 0, 0, 0)
			flyOut(tab, i, 0.15 + (i - 1) * 0.05, total)
		end
	end

	function WindowHandler:SetParallax(v)
		parallax = math.clamp(tonumber(v) or 1, 0, 3)
	end

	function WindowHandler:Destroy()
		if self.Destroyed then return end
		self.Destroyed = true
		playSound(Prism.Sounds.Click, 0.8, 0.9)
		glowTarget = 0
		for _, tab in ipairs(self.Tabs) do
			tw(tab.Frame, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		end
		tw(CoreRoot, { Size = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.4, function()
			for _, c in ipairs(conns) do
				pcall(function() c:Disconnect() end)
			end
			ScreenGui:Destroy()
		end)
	end

	function WindowHandler:Notify(cfg)
		Prism:Notify(cfg)
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
	track(MiniGem.MouseButton1Click:Connect(function() WindowHandler:Restore() end))

	-- ===================================================================
	--   NODE GENERATOR (Multi-Layer Depth Planes)
	-- ===================================================================
	local function canHover()
		return (not WindowHandler.IsExpanded) and (not WindowHandler.IsMinimized) and (not WindowHandler.InStartupAnim)
	end

	local function createBaseNode(title, iconText, isClose)
		local glowCol = isClose and Theme.RedCloseGlow or Theme.AccentGlow

		local NodeFrame = new("Frame", {
			Name = title .. "_Node",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 2,
		}, BaseCenter)
		local NodeScale = new("UIScale", nil, NodeFrame)

		local NodeBody = diamond(NodeFrame, { BackgroundColor3 = Theme.NodeBg }, 1)
		round(NodeBody, 8)
		local NodeBevel = bevel(NodeBody, 170, 45)
		local NodeStroke = outline(NodeBody, Color3.new(1, 1, 1), 3, 0.5)
		sweep(NodeStroke, isClose and 70 or 55, isClose and PRISM_RED or PRISM)

		local NodeSheen = new("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, NodeBody)
		round(NodeSheen, 8)
		local NodeSheenGrad = new("UIGradient", { Rotation = 45, Transparency = GEM_SPECULAR }, NodeSheen)

		-- Inner plate sits on an internal refractive plane
		local InnerPlateHolder = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, NodeFrame)

		local InnerPlate = diamond(InnerPlateHolder, { BackgroundColor3 = Theme.InnerRing }, 0.66)
		round(InnerPlate, 6)
		local InnerPlateBevel = bevel(InnerPlate, 125, 45)
		local NodeDecStroke = outline(InnerPlate, Theme.BorderDim, 1.2, 0.5)

		-- Float layer sits on the highest depth plane
		local Float = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = 3,
		}, NodeFrame)

		local NodeIcon = label({
			Text = iconText or "💎",
			Font = Enum.Font.GothamBold,
			TextSize = isClose and 36 or 34,
			TextColor3 = isClose and Theme.RedClose or Theme.TextMuted,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -6),
			Size = UDim2.new(0, 50, 0, 50),
		}, Float)

		local NodeLabel = label({
			Text = string.upper(title),
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = isClose and Color3.fromRGB(255, 150, 160) or Theme.TextPrimary,
			TextTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 26),
			Size = UDim2.new(1, -20, 0, 16),
		}, Float)

		local ClickBtn = new("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.7, 0, 0.7, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 4,
		}, NodeFrame)

		local tab = {
			Frame = NodeFrame,
			Scale = NodeScale,
			Body = NodeBody,
			ClickBtn = ClickBtn,
			Icon = NodeIcon,
			Label = NodeLabel,
			Stroke = NodeStroke,
			DecStroke = NodeDecStroke,
			InnerPlate = InnerPlate,
			InnerHolder = InnerPlateHolder,
			InnerBevel = InnerPlateBevel,
			BodyBevel = NodeBevel,
			Float = Float,
			SheenGrad = NodeSheenGrad,
			Title = title,
			IsClose = isClose,
			lift = 0,
			liftT = 0,
		}

		ClickBtn.MouseEnter:Connect(function()
			if not canHover() then return end
			playHoverSound(1.65, 0.4)
			tab.liftT = 1
			tw(NodeFrame, { Size = UDim2.new(0, 150, 0, 150) }, 0.2, Enum.EasingStyle.Back)
			tw(NodeBody, { BackgroundColor3 = Theme.NodeHover }, 0.2)
			tw(InnerPlate, { BackgroundColor3 = Color3.fromRGB(40, 30, 84) }, 0.2)
			tw(NodeStroke, { Transparency = 0, Thickness = 4.4 }, 0.2)
			tw(NodeDecStroke, { Transparency = 0.1, Color = Theme.AccentDark }, 0.2)
			tw(NodeIcon, { TextColor3 = glowCol }, 0.2)
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
		self.Radius = nodeRadius(total)
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
		CoreRoot.Size = UDim2.new(0, 0, 0, 0)
		task.wait(0.35)
		if WindowHandler.Destroyed then return end

		glowTarget = 1
		playSound(Prism.Sounds.Open, 0.75, 1.0)
		tw(CoreRoot, { Size = UDim2.new(0, 330, 0, 330) }, 0.7, Enum.EasingStyle.Back)
		shockwave(Theme.Ice, 140, 820, 1.1, 4)
		task.wait(0.35)
		shockwave(Theme.Accent, 140, 700, 1.0, 3)
		tw(CoreStroke, { Thickness = 8 }, 0.2)
		task.wait(0.2)
		tw(CoreStroke, { Thickness = 4.5 }, 0.4)
		task.wait(0.2)

		tw(CoreIcon, { TextTransparency = 0 }, 0.5)
		task.wait(0.55)
		if WindowHandler.Destroyed then return end

		playSound(Prism.Sounds.Open, 1.15, 0.8)
		shockwave(Theme.Pink, 220, 780, 1.2, 3)

		local tabs   = WindowHandler.Tabs
		local total  = #tabs
		local R      = nodeRadius(total)
		WindowHandler.Radius = R
		local tabDur, stagger = 1.3, 0.1
		local totalTime = tabDur + math.max(0, total - 1) * stagger

		for _, tab in ipairs(tabs) do
			tab.Frame.Size = UDim2.new(0, 0, 0, 0)
			tab.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
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
			local cs = 330 - (80 * coreEase)
			CoreRoot.Size = UDim2.new(0, cs, 0, cs)

			trailTimer = trailTimer + dt
			local doTrail = trailTimer > 0.045
			if doTrail then trailTimer = 0 end

			for i, tab in ipairs(tabs) do
				local tp = math.clamp((el - (i - 1) * stagger) / tabDur, 0, 1)
				local sizeEase = TweenService:GetValue(tp, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				local slide    = TweenService:GetValue(tp, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local grow     = TweenService:GetValue(math.min(1, tp * 1.5), Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local uFinal   = (i - 1) / total
				local px, py   = perimeterPoint(uFinal * slide, R)
				local x, y     = px * grow, py * grow
				local s        = 130 * sizeEase

				tab.Frame.Position = UDim2.new(0.5, x, 0.5, y)
				tab.Frame.Size = UDim2.new(0, s, 0, s)
				tab.Icon.TextTransparency = 1 - math.clamp(tp * 1.6, 0, 1)

				if doTrail and tp > 0 and tp < 0.9 then
					local ts = math.random(4, 8)
					local d = new("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, x, 0.5, y),
						Size = UDim2.new(0, ts, 0, ts),
						Rotation = 45,
						BackgroundColor3 = (math.random() < 0.5) and Theme.Ice or Theme.Pink,
						BorderSizePixel = 0,
						ZIndex = 1,
					}, BaseCenter)
					tw(d, { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }, 0.55)
					Debris:AddItem(d, 0.6)
				end
			end
		until el >= totalTime

		playSound(Prism.Sounds.Notify, 1.4, 1.0)
		shockwave(Theme.AccentGlow, 210, 680, 0.9, 4)
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
		WindowHandler.Radius = nodeRadius(newTotal)
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
	--   2.5D REALISTIC GEMSTONE RENDER LOOP
	-- ===================================================================
	local t0 = os.clock()
	local pointer = Vector2.new(0, 0)
	local mouseEnabled = UserInputService.MouseEnabled

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

		-- Normalized mouse vector (-1 to 1)
		local cam = Workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local tx, ty = 0, 0
		local mouseScreenPos = Vector2.new(vp.X * 0.5, vp.Y * 0.5)

		if mouseEnabled then
			local ml = UserInputService:GetMouseLocation()
			mouseScreenPos = ml
			tx = math.clamp((ml.X - vp.X * 0.5) / (vp.X * 0.5), -1, 1)
			ty = math.clamp((ml.Y - vp.Y * 0.5) / (vp.Y * 0.5), -1, 1)
			tx = tx + math.sin(t * 0.6) * 0.04
			ty = ty + math.cos(t * 0.45) * 0.03
		else
			tx = math.sin(t * 0.6) * 0.45
			ty = math.cos(t * 0.45) * 0.35
		end
		pointer = pointer:Lerp(Vector2.new(tx, ty), 1 - math.exp(-dt * 9))
		local px, py = pointer.X, pointer.Y

		-- Whole stage moves with parallax
		Stage.Position = UDim2.new(0.5, px * 12 * parallax, 0.5, py * 9 * parallax)
		local K = 26 * parallax
		for _, l in ipairs(layers) do
			l.obj.Position = UDim2.new(
				l.base.X.Scale, l.base.X.Offset + (px * K * l.depth),
				l.base.Y.Scale, l.base.Y.Offset + (py * K * l.depth)
			)
		end

		-- Dynamic bevel lighting on the main crystal
		local lightAngle = math.deg(math.atan2(py, px))
		CoreBevel.Rotation = 45 + (px * 15)
		Inner2Bevel.Rotation = 45 - (px * 20)
		BodySheenGrad.Offset = Vector2.new(0.55 * (px + py) * math.max(0.4, parallax), 0)

		-- ===============================================================
		--   PER-DIAMOND POINT-LIGHT & 3D REFRACTION CALCULATION
		-- ===============================================================
		for _, tab in ipairs(WindowHandler.Tabs) do
			tab.lift = tab.lift + (tab.liftT - tab.lift) * math.min(1, dt * 14)

			if tab.Frame.Visible then
				local tabCenter = tab.Frame.AbsolutePosition + (tab.Frame.AbsoluteSize * 0.5)
				local diff = mouseScreenPos - tabCenter
				local dist = diff.Magnitude
				local normDiff = dist > 0 and (diff / dist) or Vector2.zero

				-- 1. Point-light sheen angle & position on this specific diamond
				local sheenOffset = math.clamp((normDiff.X + normDiff.Y) * 0.45, -0.7, 0.7)
				tab.SheenGrad.Offset = Vector2.new(sheenOffset, 0)
				local angle = math.deg(math.atan2(normDiff.Y, normDiff.X))
				tab.SheenGrad.Rotation = 45 + (normDiff.X * 20)

				-- 2. Facet lighting rotates to face the cursor
				tab.BodyBevel.Rotation = 45 + (normDiff.X * 18)
				tab.InnerBevel.Rotation = 45 - (normDiff.Y * 18)

				-- 3. Multi-layer refraction depth (Inner plate shifts inward, icon shifts outward)
				local innerX = -normDiff.X * 4 * parallax
				local innerY = -normDiff.Y * 4 * parallax
				tab.InnerHolder.Position = UDim2.new(0.5, innerX, 0.5, innerY)

				local floatX = (px * 8 * parallax) + (normDiff.X * 5)
				local floatY = (py * 8 * parallax) + (normDiff.Y * 5) - (tab.lift * 12)
				tab.Float.Position = UDim2.new(0.5, floatX, 0.5, floatY)

				-- 4. 3D Tilt perspective foreshortening
				-- Diamonds tilting toward the mouse scale up slightly, away shrink slightly
				local tiltDot = (normDiff.X * px + normDiff.Y * py)
				local targetScale = 1 + (tiltDot * 0.045 * parallax)
				tab.Scale.Scale = math.clamp(targetScale, 0.94, 1.06)
			end
		end

		-- Glow & shadow tracking
		glowIntensity = glowIntensity + (glowTarget - glowIntensity) * math.min(1, dt * 4)
		local flick = math.clamp(0.5 + math.noise(t * 2.2, 3.71), 0, 1)
		local coreD = CoreRoot.Visible and CoreRoot.Size.X.Offset or 0
		for i, g in ipairs(Glow) do
			local side = 0
			if coreD > 1 then
				side = (coreD + (2 * GLOW_PADS[i] * (0.94 + 0.12 * flick))) * SQ
			end
			g.Size = UDim2.new(0, side, 0, side)
			g.BackgroundTransparency = 1 - ((1 - GLOW_BASE[i]) * glowIntensity * (0.78 + 0.22 * flick))
		end
		local shSide = coreD * SQ
		Shadow.Size = UDim2.new(0, shSide, 0, shSide)
		Shadow.BackgroundTransparency = 1 - (0.5 * glowIntensity)

		local pulse = 0.26 + 0.01 * math.sin(t * 2.2)
		CoreIcon.Size = UDim2.new(pulse, 0, pulse, 0)
		for i, j in ipairs(jewels) do
			j.BackgroundTransparency = 0.05 + 0.4 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.3))
		end

		local shardTarget = (WindowHandler.IsExpanded and 0.22 or 1) * glowIntensity
		shardMul = shardMul + (shardTarget - shardMul) * math.min(1, dt * 3)
		for _, s in ipairs(shards) do
			local ox = (px * K * s.depth) + (math.sin(t * s.sp + s.ph) * s.bob)
			local oy = (py * K * s.depth) + (math.cos(t * s.sp * 0.8 + s.ph) * s.bob)
			s.f.Position = UDim2.new(0.5, s.x + ox, 0.5, s.y + oy)
			s.f.Rotation = 45 + (math.sin(t * s.sp + s.ph) * 25)
			s.f.BackgroundTransparency = 1 - (s.a * shardMul * (0.7 + 0.3 * math.sin(t * s.sp * 2 + s.ph)))
		end
	end))

	-- ===================================================================
	--   ACTION NODE (Uses clean standard 'X' for glyph safety)
	-- ===================================================================
	function WindowHandler:CreateActionNode(tabName, icon, callback)
		local isClose = (string.lower(tabName):find("close") ~= nil)
		local displayIcon = icon
		if isClose and (icon == "✕" or icon == nil) then
			displayIcon = "X"
		end

		local tab = createBaseNode(tabName, displayIcon, isClose)
		registerTab(tab)

		tab.ClickBtn.MouseButton1Click:Connect(function()
			if self.IsExpanded or self.IsMinimized or self.InStartupAnim then return end
			playSound(Prism.Sounds.Click, 1.1, 0.95)
			tw(tab.Frame, { Size = UDim2.new(0, 120, 0, 120) }, 0.08)
			tw(tab.Body, { BackgroundColor3 = Theme.NodeActive }, 0.08)
			shockwave(isClose and Theme.RedClose or Theme.Accent, 150, 280, 0.45, 2)
			task.delay(0.1, function()
				if not self.IsExpanded and not self.IsMinimized and not self.Destroyed then
					tw(tab.Frame, { Size = UDim2.new(0, 150, 0, 150) }, 0.2, Enum.EasingStyle.Back)
					tw(tab.Body, { BackgroundColor3 = Theme.NodeHover }, 0.2)
				end
			end)
			task.spawn(callback or function() end)
		end)
	end

	-- ===================================================================
	--   TAB CREATION
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
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}, Page)
		new("UIPadding", {
			PaddingTop = UDim.new(0, 30),
			PaddingBottom = UDim.new(0, 46),
		}, Page)

		local orderCounter = 0
		local function nextOrder()
			orderCounter = orderCounter + 1
			return orderCounter
		end

		tab.Page = Page
		registerTab(tab)

		track(tab.ClickBtn.MouseButton1Click:Connect(function()
			if WindowHandler.IsExpanded or WindowHandler.IsMinimized or WindowHandler.InStartupAnim then return end
			WindowHandler.IsExpanded = true
			ExpandedReady = false
			WindowHandler.CurrentActive = tab
			playSound(Prism.Sounds.Open, 1.15, 0.95)

			for i, t in ipairs(WindowHandler.Tabs) do
				if t.Page then t.Page.Visible = false end
				flyIn(t, (i - 1) * 0.025)
			end

			tw(CoreRoot, { Size = UDim2.new(0, EXPANDED_D, 0, EXPANDED_D) }, 0.55, Enum.EasingStyle.Back)
			shockwave(Theme.AccentGlow, 260, 560, 0.6, 3)

			task.delay(0.3, function()
				if not WindowHandler.IsExpanded or WindowHandler.CurrentActive ~= tab then return end
				PortalTitle.Text = (icon or "💎") .. "  " .. string.upper(tabName)
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
				BackgroundTransparency = 0.05,
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
			}, Page)
			round(Card, 8)
			bevel(Card, 175)

			local stroke = outline(Card, Theme.BorderDim, 1.3)

			local Pip = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 15, 0.5, 0),
				Size = UDim2.new(0, 8, 0, 8),
				Rotation = 45,
				BackgroundColor3 = Theme.AccentDark,
				BorderSizePixel = 0,
			}, Card)

			local count = 0
			local function apply(on)
				if on then
					playHoverSound(1.7, 0.6)
					tw(stroke, { Color = Theme.Accent }, 0.15)
					tw(Card, { BackgroundColor3 = Theme.CardHover }, 0.15)
					tw(Pip, { BackgroundColor3 = Theme.AccentGlow, Size = UDim2.new(0, 12, 0, 12), Rotation = 135 }, 0.22, Enum.EasingStyle.Back)
				else
					tw(stroke, { Color = Theme.BorderDim }, 0.2)
					tw(Card, { BackgroundColor3 = Theme.CardBg }, 0.2)
					tw(Pip, { BackgroundColor3 = Theme.AccentDark, Size = UDim2.new(0, 8, 0, 8), Rotation = 45 }, 0.2)
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
				LayoutOrder = nextOrder(),
			}, Page)

			new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 15, 0, 18),
				Size = UDim2.new(0, 8, 0, 8),
				Rotation = 45,
				BackgroundColor3 = Theme.AccentGlow,
				BorderSizePixel = 0,
			}, sec)

			label({
				Text = string.upper(secName), Font = Enum.Font.GothamBold, TextSize = 13,
				TextColor3 = Theme.AccentGlow, TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 30, 0, 8), Size = UDim2.new(1, -40, 0, 20),
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
		TabElements.AddSection = TabElements.CreateSection

		function TabElements:CreateLabel(text)
			local Card = makeCapsule(40)
			local lbl = label({
				Text = tostring(text or ""), TextSize = 13, TextColor3 = Theme.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(1, -44, 1, 0),
			}, Card)
			local api = {}
			function api:Set(v) lbl.Text = tostring(v) end
			return api
		end
		TabElements.AddLabel = TabElements.CreateLabel

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
				Position = UDim2.new(0, 30, 0, hasDesc and 11 or 0),
				Size = UDim2.new(1, -76, 0, hasDesc and 18 or 54),
			}, Card)

			if hasDesc then
				label({
					Text = desc, TextSize = 12, TextColor3 = Theme.TextMuted,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 30, 0, 35), Size = UDim2.new(1, -76, 0, 18),
				}, Card)
			end

			label({
				Text = "◆", TextSize = 16, TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold,
				Position = UDim2.new(1, -40, 0.5, -10), Size = UDim2.new(0, 20, 0, 20),
			}, Card)

			ClickArea.MouseButton1Click:Connect(function()
				playSound(Prism.Sounds.Click, 1.0, 0.95)
				local flash = tw(Card, { BackgroundColor3 = Color3.fromRGB(52, 38, 108) }, 0.1)
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
				Position = UDim2.new(0, 30, 0, hasDesc and 11 or 0),
				Size = UDim2.new(1, -102, 0, hasDesc and 18 or 56),
			}, Card)

			if hasDesc then
				label({
					Text = desc, TextSize = 12, TextColor3 = Theme.TextMuted,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 30, 0, 35), Size = UDim2.new(1, -102, 0, 18),
				}, Card)
			end

			local Switch = new("TextButton", {
				Size = UDim2.new(0, 58, 0, 28),
				Position = UDim2.new(1, -72, 0.5, -14),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
			}, Card)
			local Rail = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, -8, 0, 6),
				BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(34, 27, 70),
				BorderSizePixel = 0,
			}, Switch)
			round(Rail)
			local RailStroke = outline(Rail, state and Theme.AccentGlow or Theme.BorderDim, 1.2)
			bind(Switch)

			local Knob = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = state and UDim2.new(1, -9, 0.5, 0) or UDim2.new(0, 9, 0.5, 0),
				Size = UDim2.new(0, 14, 0, 14),
				Rotation = 45,
				BackgroundColor3 = Color3.fromRGB(245, 241, 255),
				BorderSizePixel = 0,
			}, Switch)
			outline(Knob, Theme.Accent, 1.6)

			local function paint(v)
				if v then
					tw(Rail, { BackgroundColor3 = Theme.Accent }, 0.18)
					tw(RailStroke, { Color = Theme.AccentGlow }, 0.18)
					tw(Knob, { Position = UDim2.new(1, -9, 0.5, 0), Rotation = 225 }, 0.25, Enum.EasingStyle.Back)
				else
					tw(Rail, { BackgroundColor3 = Color3.fromRGB(34, 27, 70) }, 0.18)
					tw(RailStroke, { Color = Theme.BorderDim }, 0.18)
					tw(Knob, { Position = UDim2.new(0, 9, 0.5, 0), Rotation = 45 }, 0.25, Enum.EasingStyle.Back)
				end
			end

			Switch.MouseButton1Click:Connect(function()
				state = not state
				playSound(Prism.Sounds.Toggle, state and 1.3 or 0.85, 0.95)
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
				Position = UDim2.new(0, 30, 0, 9), Size = UDim2.new(1, -100, 0, 18),
			}, Card)

			local valLbl = label({
				Text = formatVal(def), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.AccentGlow,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(1, -72, 0, 9), Size = UDim2.new(0, 56, 0, 18),
			}, Card)

			local Track = new("TextButton", {
				Size = UDim2.new(1, -52, 0, 6),
				Position = UDim2.new(0, 26, 0, 48),
				BackgroundColor3 = Color3.fromRGB(32, 25, 66),
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
				Color = ColorSequence.new(Theme.Ice, Theme.Pink),
			}, Fill)

			local Knob = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 13, 0, 13),
				Rotation = 45,
				BackgroundColor3 = Color3.fromRGB(245, 241, 255),
				BorderSizePixel = 0,
				ZIndex = 2,
			}, Fill)
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
					playSound(Prism.Sounds.Click, 1.4, 0.8)
					tw(Knob, { Size = UDim2.new(0, 19, 0, 19) }, 0.12, Enum.EasingStyle.Back)
					updateFromInput(input)
				end
			end)
			track(UserInputService.InputEnded:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					sliding = false
					tw(Knob, { Size = UDim2.new(0, 13, 0, 13) }, 0.15)
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
				Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(0.5, -10, 0, collapsedHeight),
			}, Card)

			local curLbl = label({
				Text = tostring(selected), TextSize = 13, TextColor3 = Theme.AccentGlow,
				TextXAlignment = Enum.TextXAlignment.Right,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -44, 0, 0), Size = UDim2.new(0.4, 0, 0, collapsedHeight),
			}, Card)

			local Arrow = label({
				Text = "▾", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.TextMuted,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -26, 0, collapsedHeight / 2), Size = UDim2.new(0, 18, 0, 18),
			}, Card)

			local ListHolder = new("Frame", {
				Size = UDim2.new(1, -24, 0, #items * (itemHeight + 4)),
				Position = UDim2.new(0, 12, 0, collapsedHeight + 2),
				BackgroundTransparency = 1,
			}, Card)
			new("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, ListHolder)

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

			for idx, item in ipairs(items) do
				local itmBtn = new("TextButton", {
					Size = UDim2.new(1, 0, 0, itemHeight),
					BackgroundColor3 = Color3.fromRGB(24, 19, 52),
					BorderSizePixel = 0,
					Font = Enum.Font.Gotham,
					TextSize = 13,
					TextColor3 = Theme.TextPrimary,
					Text = "   " .. tostring(item),
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					LayoutOrder = idx,
				}, ListHolder)
				round(itmBtn, 6)

				itmBtn.MouseEnter:Connect(function()
					playHoverSound(1.85, 0.5)
					tw(itmBtn, { BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.AccentGlow }, 0.12)
				end)
				itmBtn.MouseLeave:Connect(function()
					tw(itmBtn, { BackgroundColor3 = Color3.fromRGB(24, 19, 52), TextColor3 = Theme.TextPrimary }, 0.12)
				end)
				itmBtn.MouseButton1Click:Connect(function()
					playSound(Prism.Sounds.Click, 1.2, 0.9)
					choose(item, true)
					collapse()
				end)
			end

			HeaderBtn.MouseButton1Click:Connect(function()
				expanded = not expanded
				playSound(Prism.Sounds.Click, 1.0, 0.9)
				local targetH = expanded and (collapsedHeight + (#items * (itemHeight + 4)) + 10) or collapsedHeight
				tw(Arrow, { Rotation = expanded and 180 or 0 }, 0.25)
				tw(Card, { Size = UDim2.new(1, -12, 0, targetH) }, 0.3, Enum.EasingStyle.Quint)
			end)

			local api = {}
			function api:Set(v, fire) choose(v, fire) end
			function api:Get() return selected end
			return api
		end
		TabElements.AddDropdown = TabElements.CreateDropdown

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
				Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(0.6, -20, 1, 0),
			}, Card)

			local KeyBtn = new("TextButton", {
				Size = UDim2.new(0, 96, 0, 30),
				Position = UDim2.new(1, -110, 0.5, -15),
				BackgroundColor3 = Color3.fromRGB(28, 22, 58),
				BorderSizePixel = 0,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextColor3 = Theme.AccentGlow,
				Text = currentKey == Enum.KeyCode.None and "None" or currentKey.Name,
				AutoButtonColor = false,
			}, Card)
			round(KeyBtn, 6)
			local KeyStroke = outline(KeyBtn, Theme.BorderDim, 1.3)
			bind(KeyBtn)

			local listening = false
			KeyBtn.MouseButton1Click:Connect(function()
				listening = true
				KeyBtn.Text = "..."
				tw(KeyStroke, { Color = Theme.AccentGlow }, 0.15)
				playSound(Prism.Sounds.Click, 1.25, 0.9)
			end)

			track(UserInputService.InputBegan:Connect(function(input, gpe)
				if listening then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						listening = false
						tw(KeyStroke, { Color = Theme.BorderDim }, 0.15)
						if input.KeyCode ~= Enum.KeyCode.Escape then
							currentKey = input.KeyCode
							playSound(Prism.Sounds.Click, 0.95, 0.95)
							task.spawn(onChange, currentKey)
						end
						KeyBtn.Text = currentKey == Enum.KeyCode.None and "None" or currentKey.Name
					end
				elseif not gpe and currentKey ~= Enum.KeyCode.None and input.KeyCode == currentKey then
					task.spawn(callback, currentKey)
				end
			end))
		end
		TabElements.AddKeybind = TabElements.CreateKeybind

		function TabElements:CreateInput(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Input"
			local callback = opts.Callback or function() end

			local Card, stroke, pip, bind = makeCapsule(56)

			label({
				Text = name, Font = Enum.Font.GothamSemibold, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(0.5, -30, 1, 0),
			}, Card)

			local Box = new("TextBox", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.new(0.44, 0, 0, 32),
				BackgroundColor3 = Color3.fromRGB(28, 22, 58),
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
			round(Box, 6)
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
		TabElements.AddInput = TabElements.CreateInput

		function TabElements:CreateParagraph(opts)
			opts = opts or {}
			local title = opts.Title or "Information"
			local content = opts.Content or ""

			local textH = TextService:GetTextSize(content, 13, Enum.Font.Gotham, Vector2.new(320, 10000)).Y
			local Card = makeCapsule(math.max(64, 44 + textH + 14))

			label({
				Text = title, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.AccentGlow,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 30, 0, 12), Size = UDim2.new(1, -50, 0, 18),
			}, Card)

			label({
				Text = content, TextSize = 13, TextColor3 = Theme.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				Position = UDim2.new(0, 30, 0, 36), Size = UDim2.new(1, -50, 0, textH),
			}, Card)
		end
		TabElements.AddParagraph = TabElements.CreateParagraph

		return TabElements
	end

	for _, p in ipairs(candidateParents()) do
		local ok = pcall(function() ScreenGui.Parent = p end)
		if ok and ScreenGui.Parent == p then break end
	end

	return WindowHandler
end

return Prism
