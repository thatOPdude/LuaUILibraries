-- =======================================================================
--   🌍 ORBITAL UI LIBRARY  v4  ("Planetfall" Final Edition)
--
--   NEW IN v4
--   • Cinematic startup: singularity spark -> inward energy pulses ->
--     ignition flash + camera push-in -> ring boot sweep -> planet fade-in
--     -> nodes spiral in with comet trails and landing ripples -> title
--     scramble-decode.
--   • Planet: denser continents, NIGHT-SIDE CITY LIGHTS, atmosphere rim,
--     drifting clouds. Adaptive frame budget keeps it smooth on weak PCs.
--   • More 2.5D: foreground bokeh layer (in FRONT of the UI), per-star
--     depth, floating nodes with elevation shadows, tilted moon orbit.
--   • Touch support: floating toggle orb (auto-enabled on touch-only).
--   • Dropdowns scroll + highlight selection, Flags table, more APIs.
--   • Fixes: UTF-8 safe title animation, tab list snapshot during
--     startup, tracked connections, toast stack cap, safer mounting.
--
--   USAGE
--     local Orbital = loadstring(game:HttpGet("YOUR_URL"))()
--     local Win = Orbital:CreateWindow({
--         Title = "ORBITAL",
--         ToggleKey = Enum.KeyCode.RightShift,
--         Stars = true, Moon = true,
--         Parallax = true, ParallaxStrength = 1,   -- 0 = off, 2 = dramatic
--         Quality = "high",                        -- low | medium | high | ultra
--         ToggleButton = nil,                      -- nil = auto (touch-only)
--     })
--     local Tab = Win:CreateTab("Main", "⚙️")
--     Tab:CreateToggle({ Name = "Hello", Flag = "hello", Callback = print })
--     Win:CreateActionNode("Close", "✖", function() Win:Destroy() end)
--
--   WINDOW API : Minimize Restore Toggle Destroy Notify SetParallax
--                SetSounds SetToggleKey CreateTab CreateActionNode
--   TAB API    : CreateSection CreateLabel CreateButton CreateToggle
--                CreateSlider CreateDropdown CreateKeybind CreateInput
--                CreateParagraph      (values also stored in Orbital.Flags)
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
local DESIGN   = 1000 -- size (design px) of every depth layer canvas

-- Where can we mount the GUI? (executor hidden-ui -> CoreGui -> PlayerGui)
local function candidateParents()
	local list = {}
	if typeof(gethui) == "function" then
		local ok, ui = pcall(gethui)
		if ok and ui then table.insert(list, ui) end
	end
	local ok2, rg = pcall(function() return CoreGui:FindFirstChild("RobloxGui") end)
	if ok2 and rg then table.insert(list, rg) end
	local ok3, pg = pcall(function() return localPlayer:WaitForChild("PlayerGui", 5) end)
	if ok3 and pg then table.insert(list, pg) end
	return list
end

local Orbital = {
	Version = "4.0",
	SoundsEnabled = true,
	Flags = {},
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

-- A big transparent canvas centred on its parent: one "depth layer"
local function layer(name, z, parent)
	return new("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, DESIGN, 0, DESIGN),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = z,
	}, parent)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

-- split a string into UTF-8 glyphs (falls back to bytes on invalid input)
local function glyphsOf(str)
	local out = {}
	local ok = pcall(function()
		for _, c in utf8.codes(str) do out[#out + 1] = utf8.char(c) end
	end)
	if not ok or #out == 0 then
		out = {}
		for i = 1, #str do out[i] = string.sub(str, i, i) end
	end
	return out
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

local function tw(obj, props, duration, style, dir)
	local info = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local anim = TweenService:Create(obj, info, props)
	anim:Play()
	return anim
end

local function playSound(soundId, pitch, volume)
	if Orbital.SoundsEnabled == false then return end
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
--   PROCEDURAL EARTH  (true 3D dotted globe, no assets needed)
-- =======================================================================
local LAND_POLYS = {
	-- North America
	{ -168,65, -160,70, -140,70, -125,70, -110,72, -95,72, -82,68, -78,62, -90,58, -82,52,
	  -78,56, -70,60, -62,57, -56,52, -66,45, -70,42, -76,38, -81,31, -80,25, -83,29, -90,30,
	  -97,27, -97,21, -92,18, -88,21, -87,16, -83,10, -79,8, -83,8, -86,12, -92,15, -105,20,
	  -110,24, -113,31, -117,32, -124,40, -124,48, -130,54, -140,60, -150,60, -158,57, -165,60 },
	-- Baffin / arctic islands
	{ -78,63, -64,66, -68,71, -78,73 },
	-- Greenland
	{ -73,78, -60,82, -30,83, -20,76, -22,70, -40,63, -50,62, -55,68, -68,76 },
	-- South America
	{ -80,8, -72,12, -62,10, -52,5, -50,0, -40,-3, -35,-7, -38,-14, -41,-22, -48,-26, -53,-34,
	  -58,-38, -65,-42, -66,-48, -69,-52, -72,-54, -75,-48, -73,-38, -71,-28, -70,-18, -76,-14,
	  -81,-6, -80,-1, -78,4 },
	-- Europe
	{ -9,37, -9,43, -2,43.5, -1,46, -4.5,48, 2,51, 8,54, 9,57, 14,54, 20,55, 24,57, 28,60, 30,60,
	  33,52, 35,46, 30,45, 28,41, 23,36.5, 20,40, 16,38, 12,42, 10,44, 8,44, 3,43, 0,39, -5,36 },
	-- Scandinavia
	{ 5,59, 5,62, 10,64, 15,68, 20,70, 28,71, 30,69, 26,66, 22,65, 18,62, 18,59, 16,56, 13,55.5, 11,58, 8,58 },
	-- British Isles + Iceland
	{ -5,50, 1,51, 0,54, -3,58, -6,57, -3,54 },
	{ -24,64, -14,64, -14,66, -22,66 },
	-- Asia
	{ 28,41, 36,36, 35,30, 43,13, 52,16, 58,22, 57,26, 66,25, 72,20, 77,8, 80,15, 88,22, 92,20,
	  98,16, 100,8, 104,1, 108,12, 108,21, 118,24, 122,30, 121,38, 128,35, 130,43, 142,53, 156,60,
	  163,58, 180,66, 178,69, 160,70, 130,73, 105,77, 80,73, 60,70, 50,68, 40,67, 30,60, 30,52, 35,46 },
	-- Japan
	{ 130,31, 135,34, 140,36, 142,41, 141,45, 138,38, 133,35 },
	-- Africa
	{ -17,21, -10,30, -6,36, 10,37, 11,33, 20,31, 32,31, 34,28, 38,20, 43,12, 51,12, 44,2, 40,-5,
	  40,-15, 35,-24, 32,-29, 27,-34, 20,-35, 17,-30, 12,-17, 13,-8, 9,-1, 9,4, 4,6, -8,4, -13,8, -17,14 },
	-- Madagascar
	{ 44,-25, 47,-25, 50,-15, 49,-12, 44,-17 },
	-- Australia
	{ 114,-22, 122,-18, 130,-12, 136,-12, 142,-11, 146,-19, 153,-26, 151,-34, 146,-39, 138,-35, 131,-31, 115,-34 },
	-- Indonesia / New Guinea
	{ 109,1, 117,7, 119,1, 116,-4, 110,-3 },
	{ 95,5, 104,-3, 106,-6, 100,-1 },
	{ 131,-1, 141,-3, 150,-10, 141,-9, 134,-4 },
	-- New Zealand
	{ 172,-34, 178,-38, 175,-41, 172,-41 },
	{ 167,-46, 174,-41, 171,-45 },
}

local function inPoly(poly, x, y)
	local inside = false
	local n = #poly
	local j = n - 1
	for i = 1, n - 1, 2 do
		local xi, yi = poly[i], poly[i + 1]
		local xj, yj = poly[j], poly[j + 1]
		if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
			inside = not inside
		end
		j = i
	end
	return inside
end

local function isLand(lonD, latD)
	if latD < -71 then return true end -- Antarctica
	for i = 1, #LAND_POLYS do
		if inPoly(LAND_POLYS[i], lonD, latD) then return true end
	end
	return false
end

local landCache = {}
local function buildLandPoints(total)
	if landCache[total] then return landCache[total] end
	local pts = {}
	local golden = math.pi * (3 - math.sqrt(5))
	for i = 0, total - 1 do
		local y = 1 - 2 * (i + 0.5) / total
		local lat = math.asin(y)
		local lon = ((i * golden) % (2 * math.pi)) - math.pi
		if isLand(math.deg(lon), math.deg(lat)) then
			local r = math.cos(lat)
			pts[#pts + 1] = { x = r * math.sin(lon), y = y, z = r * math.cos(lon), lat = lat }
		end
	end
	landCache[total] = pts
	return pts
end

-- Globe constants: axial tilt, camera pitch, fixed light (view space)
local G_TILT  = -0.41
local G_PITCH = 0.30
local G_cT, G_sT = math.cos(G_TILT), math.sin(G_TILT)
local G_cP, G_sP = math.cos(G_PITCH), math.sin(G_PITCH)
local G_LX, G_LY, G_LZ = -0.55, 0.50, 0.67
local CITY_COL = Color3.fromRGB(255, 212, 128)
local CLOUD_COL = Color3.fromRGB(232, 246, 255)

local function createGlobe(parent, opts)
	opts = opts or {}
	local total  = opts.Dots or 1100
	local cloudN = opts.Clouds or 0
	local zi     = opts.ZIndex or 2
	local dotFrac = 0.34 * math.sqrt(4 * math.pi / total) -- dot size as fraction of globe diameter

	local Holder = new("Frame", {
		Name = "Globe",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = zi,
	}, parent)

	local Halo = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1.14, 0, 1.14, 0),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, Holder)
	round(Halo)

	local Atmos = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1.07, 0, 1.07, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, Holder)
	round(Atmos)
	local AtmosStroke = outline(Atmos, Theme.AccentGlow, 5, 0.86)

	local Body = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, Holder)
	round(Body)
	new("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(38, 150, 215)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 60, 125)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(3, 12, 34)),
		}),
	}, Body)
	local Rim = outline(Body, Theme.AccentGlow, 1.6, 0.5)

	-- land dots (some get night-side city lights) ------------------------
	local land = {}
	local landPts = buildLandPoints(total)
	local rngColor = Random.new(5)
	for i = 1, #landPts do
		local p = landPts[i]
		local ice = math.abs(p.lat) > 1.05
		local col
		if ice then
			col = Color3.fromRGB(226, 246, 255)
		else
			col = Theme.Aurora:Lerp(Theme.AccentGlow, rngColor:NextNumber(0, 0.45))
		end
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = col,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 3,
		}, Holder)
		round(f)
		land[i] = {
			f = f, x = p.x, y = p.y, z = p.z, k = ice and 1.15 or 1, vis = false,
			col = col, mode = 1, city = (not ice) and rngColor:NextNumber() < 0.11,
		}
	end

	-- cloud layer (own spin speed + slightly larger radius = real depth) --
	local clouds = {}
	local rng = Random.new(11)
	for i = 1, cloudN do
		local y = rng:NextNumber(-0.92, 0.92)
		local lon = rng:NextNumber(-math.pi, math.pi)
		local r = math.sqrt(1 - y * y)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = CLOUD_COL,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 4,
		}, Holder)
		round(f)
		clouds[i] = {
			f = f, x = r * math.sin(lon), y = y, z = r * math.cos(lon),
			k = rng:NextNumber(1.3, 2.1), vis = false, col = CLOUD_COL, mode = 1, city = false,
		}
	end

	-- terminator shading + specular glint (over the dots) ----------------
	local Shade = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 6,
	}, Holder)
	round(Shade)
	new("UIGradient", {
		Rotation = 45,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 1),
			NumberSequenceKeypoint.new(0.4, 0.96),
			NumberSequenceKeypoint.new(1.0, 0.3),
		}),
	}, Shade)

	local Spec = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.34, 0, 0.3, 0),
		Size = UDim2.new(0.3, 0, 0.3, 0),
		BackgroundColor3 = Color3.fromRGB(200, 240, 255),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, Holder)
	round(Spec)

	-- projection ---------------------------------------------------------
	local function project(list, ang, rMul, vis, maxA, nightOn)
		local cs, sn = math.cos(ang), math.sin(ang)
		for i = 1, #list do
			local d = list[i]
			-- spin about Y
			local x = d.x * cs + d.z * sn
			local z = d.z * cs - d.x * sn
			local y = d.y
			-- axial tilt about Z
			local x2 = x * G_cT - y * G_sT
			local y2 = x * G_sT + y * G_cT
			-- camera pitch about X
			local y3 = y2 * G_cP - z * G_sP
			local z3 = y2 * G_sP + z * G_cP
			local f = d.f
			if z3 > 0.04 then
				local lit = x2 * G_LX + y3 * G_LY + z3 * G_LZ
				local fade = math.min(1, z3 * 2.4)
				local isCity = nightOn and d.city and lit < 0
				local mode = isCity and 2 or 1
				if d.mode ~= mode then
					d.mode = mode
					f.BackgroundColor3 = isCity and CITY_COL or d.col
				end
				local a
				if isCity then
					a = math.clamp(vis * maxA * fade * 0.9, 0, 1)
				else
					local shade = math.clamp(0.5 + 0.62 * lit, 0.16, 1)
					a = math.clamp(vis * maxA * fade * shade, 0, 1)
				end
				local sf = dotFrac * d.k * (isCity and 1.2 or 1) * (0.42 + 0.58 * z3)
				if not d.vis then
					d.vis = true
					f.Visible = true
				end
				f.Position = UDim2.new(0.5 + x2 * rMul * 0.5, 0, 0.5 - y3 * rMul * 0.5, 0)
				f.Size = UDim2.new(sf, 0, sf, 0)
				f.BackgroundTransparency = 1 - a
			elseif d.vis then
				d.vis = false
				f.Visible = false
			end
		end
	end

	local G = { Holder = Holder }

	function G:Render(angle, diameter, vis, nightOn)
		if vis <= 0.004 or diameter < 3 then
			Holder.Visible = false
			return
		end
		Holder.Visible = true
		Holder.Size = UDim2.new(0, diameter, 0, diameter)
		Body.BackgroundTransparency = 1 - 0.97 * vis
		Halo.BackgroundTransparency = 1 - 0.07 * vis
		AtmosStroke.Transparency = 1 - 0.14 * vis
		Rim.Transparency = 1 - 0.5 * vis
		local strong = vis > 0.5
		Shade.Visible = strong
		Spec.Visible = strong
		project(land, angle, 1, vis, 0.95, nightOn ~= false)
		if #clouds > 0 then
			project(clouds, angle * 1.35 + 1.1, 1.05, vis, 0.42, false)
		end
	end

	return G
end

-- =======================================================================
--   NOTIFICATIONS
-- =======================================================================
local NotifyHolder
local toastList = {}

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
	local text     = tostring(config.Content or config.content or "")
	local duration = config.Duration or config.duration or 3.5
	local accent   = ACCENTS[string.lower(tostring(config.Type or config.type or "info"))] or ACCENTS.info

	playSound(Orbital.Sounds.Notify, 1, 0.95)

	local okT, sz = pcall(function()
		return TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(286, 10000))
	end)
	local textH = okT and sz.Y or 14
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

	-- cap the stack at 5 toasts: oldest one leaves first
	toastList[#toastList + 1] = dismiss
	if #toastList > 5 then
		local oldest = table.remove(toastList, 1)
		oldest()
	end

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
	local starsOn     = settings.Stars ~= false
	local moonOn      = settings.Moon ~= false
	local parallaxOn  = settings.Parallax ~= false
	local parStrength = tonumber(settings.ParallaxStrength) or 1
	local PARALLAX_PX = 14

	local quality = string.lower(tostring(settings.Quality or "high"))
	local globeDots, cloudDots, miniDots = 2600, 52, 800
	if quality == "low" then
		globeDots, cloudDots, miniDots = 1100, 0, 520
	elseif quality == "medium" then
		globeDots, cloudDots, miniDots = 1800, 30, 640
	elseif quality == "ultra" then
		globeDots, cloudDots, miniDots = 3600, 70, 1000
	end

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
		Size = UDim2.new(0, DESIGN, 0, DESIGN),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, ScreenGui)
	-- camera "push-in" used by the startup sequence
	local IntroScale = new("UIScale", { Scale = 1 }, OrbitCenter)

	-- full-screen ignition flash (startup only)
	local Flash = new("Frame", {
		Name = "Flash",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.AccentGlow,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
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

	-- ---------- DEPTH LAYERS (back -> front) ----------
	--   1 Glow  2 Stars  3 FX(back moon)  4 Core  5 FXTop(front moon)
	--   6 Shadows  7 Nodes  9 Front (bokeh, in FRONT of the UI)
	local GlowLayer   = layer("GlowLayer", 1, OrbitCenter)
	local StarLayer   = layer("StarLayer", 2, OrbitCenter)
	local FX          = layer("FX", 3, OrbitCenter)
	local FXTop       = layer("FXTop", 5, OrbitCenter)
	local ShadowLayer = layer("ShadowLayer", 6, OrbitCenter)
	local BaseCenter  = layer("BaseCenter", 7, OrbitCenter)
	local FrontLayer  = layer("FrontLayer", 9, OrbitCenter)

	local StarScale   = new("UIScale", nil, StarLayer)
	local FXScale     = new("UIScale", nil, FX)
	local FXTopScale  = new("UIScale", nil, FXTop)
	local ShadowScale = new("UIScale", nil, ShadowLayer)
	local BaseScale   = new("UIScale", nil, BaseCenter)
	local FrontScale  = new("UIScale", nil, FrontLayer)

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
		}, GlowLayer)
		round(g)
		Glow[i] = g
	end
	local glowIntensity, glowTarget = 0, 0

	local function shockwave(color, fromSize, toSize, duration, thickness, easeDir)
		local ring = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, fromSize, 0, fromSize),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, FX)
		round(ring)
		local st = outline(ring, color, thickness or 4, 0.1)
		tw(ring, { Size = UDim2.new(0, toSize, 0, toSize) }, duration, Enum.EasingStyle.Quint, easeDir or Enum.EasingDirection.Out)
		tw(st, { Transparency = 1, Thickness = 0.5 }, duration)
		Debris:AddItem(ring, duration + 0.1)
	end

	-- ripple under a node (lives in the node layer so it lines up exactly)
	local function ping(x, y, color)
		local ring = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, x, 0.5, y),
			Size = UDim2.new(0, 110, 0, 110),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, BaseCenter)
		round(ring)
		local st = outline(ring, color, 3, 0.2)
		tw(ring, { Size = UDim2.new(0, 200, 0, 200) }, 0.55, Enum.EasingStyle.Quint)
		tw(st, { Transparency = 1, Thickness = 0.5 }, 0.55)
		Debris:AddItem(ring, 0.65)
	end

	-- ---------- twinkling star field (each star has its own depth) ----------
	local stars = {}
	if starsOn then
		for i = 1, 52 do
			local a    = math.random() * math.pi * 2
			local r    = 150 + math.random() * 340
			local near = math.random()
			local sz   = (near > 0.8) and 3 or 2
			local bx, by = math.cos(a) * r, math.sin(a) * r
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5 + bx / DESIGN, 0, 0.5 + by / DESIGN, 0),
				Size = UDim2.new(0, sz, 0, sz),
				BackgroundColor3 = (math.random() < 0.35) and Theme.AccentGlow or Color3.fromRGB(235, 245, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			}, StarLayer)
			round(f)
			stars[i] = {
				f = f, bx = bx, by = by,
				dep = -(0.25 + near * 0.65),
				phase = math.random() * 6.28,
				speed = 0.8 + math.random() * 1.8,
				max = 0.3 + near * 0.65,
			}
		end
	end

	-- ---------- foreground bokeh (drifts IN FRONT of everything) ----------
	local bokeh = {}
	if starsOn then
		local cols = { Theme.Accent, Theme.Deep, Theme.Aurora, Theme.AccentGlow }
		for i = 1, 9 do
			local a  = math.random() * math.pi * 2
			local r  = 130 + math.random() * 360
			local sz = math.random(36, 112)
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, sz, 0, sz),
				BackgroundColor3 = cols[math.random(1, #cols)],
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, FrontLayer)
			round(f)
			bokeh[i] = {
				f = f, bx = math.cos(a) * r, by = math.sin(a) * r,
				dep = 1.1 + math.random() * 1.5,
				ph = math.random() * 6.28,
				sp = 0.15 + math.random() * 0.25,
				max = 0.05 + math.random() * 0.045,
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

	-- ---------- orbiting moon + tilted orbit path ----------
	local MOON_TRAIL = 8
	local MOON_TILT  = -0.32
	local MOON_COS, MOON_SIN = math.cos(MOON_TILT), math.sin(MOON_TILT)
	local MOON_FLAT  = 0.3
	local Moon
	local moonParts, moonBase, moonBaseTr = {}, {}, {}
	local orbitDots = {}
	if moonOn then
		Moon = new("Frame", {
			Name = "Moon",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
		}, FX)
		for i = 0, MOON_TRAIL do
			local sz = (i == 0) and 14 or math.max(3, 12 - i * 1.2)
			local tr = (i == 0) and 0 or math.min(0.95, 0.3 + i * 0.08)
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(sz / DESIGN, 0, sz / DESIGN, 0),
				BackgroundColor3 = (i == 0) and Color3.fromRGB(232, 240, 250) or Theme.AccentGlow,
				BackgroundTransparency = tr,
				BorderSizePixel = 0,
				ZIndex = (i == 0) and 3 or 2,
			}, Moon)
			round(f)
			if i == 0 then outline(f, Theme.AccentGlow, 1.6, 0.35) end
			moonParts[i], moonBase[i], moonBaseTr[i] = f, sz, tr
		end
		-- faint orbit path: back half hides behind the planet, front half crosses over it
		local ORBIT_N = 48
		for i = 1, ORBIT_N do
			local a = (i / ORBIT_N) * math.pi * 2
			local isFront = math.sin(a) > 0
			local base = isFront and 0.78 or 0.9
			local f = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 2, 0, 2),
				BackgroundColor3 = Theme.AccentGlow,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Visible = false,
			}, isFront and FXTop or FX)
			round(f)
			orbitDots[i] = { f = f, a = a, base = base }
		end
	end

	-- ---------- floating reopen globe ----------
	local MiniEarth = new("TextButton", {
		Name = "MiniEarth",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, -0.12, 0),
		Size = UDim2.new(0, 74, 0, 74),
		BackgroundColor3 = Theme.CoreBg,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 6,
	}, ScreenGui)
	round(MiniEarth)
	local MiniStroke = outline(MiniEarth, Color3.new(1, 1, 1), 3.5)
	sweep(MiniStroke, 90)
	local MiniGlobe = createGlobe(MiniEarth, { Dots = miniDots, Clouds = 0, ZIndex = 2 })

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
		ZIndex = 4,
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
		ZIndex = 1,
	}, CoreHolder)
	round(DecRing)
	outline(DecRing, Theme.BorderDim, 1.5, 0.35)

	-- The planet: lives in the core, shrinks into a backdrop when a page opens
	local CoreGlobe = createGlobe(CoreHolder, { Dots = globeDots, Clouds = cloudDots, ZIndex = 2 })

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
		ZIndex = 3,
	}, CoreHolder)

	local OrbitRing = makeOrbitRing(CollapsedView, 54, 36)

	local CoreTitle = label({
		Text = "", Font = Enum.Font.GothamBold, TextColor3 = Theme.AccentGlow, TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.8, 0),
		Size = UDim2.new(0.46, 0, 0.09, 0),
	}, CollapsedView)
	new("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 6 }, CoreTitle)

	-- Expanded view (680px disc)
	local ExpandedView = new("Frame", {
		Name = "ExpandedView",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 4,
	}, CoreHolder)

	local BigOrbitRing = makeOrbitRing(ExpandedView, 70, 48)

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
		tw(ReturnBtn, { BackgroundColor3 = Color3.fromRGB(18, 36, 60), Size = UDim2.new(0, 190, 0, 42), TextColor3 = Theme.AccentGlow }, 0.15)
		tw(ReturnStroke, { Color = Theme.AccentGlow, Thickness = 2.2 }, 0.15)
	end)
	ReturnBtn.MouseLeave:Connect(function()
		tw(ReturnBtn, { BackgroundColor3 = Color3.fromRGB(12, 24, 40), Size = UDim2.new(0, 180, 0, 40), TextColor3 = Theme.Accent }, 0.15)
		tw(ReturnStroke, { Color = Theme.BorderDim, Thickness = 1.6 }, 0.15)
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

	-- ---------- window state ----------
	local WindowHandler = {
		Tabs = {},
		Flags = Orbital.Flags,
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
	--   DRAGGING (clamped to the screen)
	-- ===================================================================
	local isDragging = false
	local dragStart = nil
	local dragStartOffset = Vector2.new(0, 0)
	local dragOffset = Vector2.new(0, 0)

	local function applyDrag()
		local cam = Workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local lx = math.max(0, vp.X / 2 - 70)
		local ly = math.max(0, vp.Y / 2 - 70)
		dragOffset = Vector2.new(math.clamp(dragOffset.X, -lx, lx), math.clamp(dragOffset.Y, -ly, ly))
		OrbitCenter.Position = UDim2.new(0.5, dragOffset.X, 0.5, dragOffset.Y)
	end

	local function makeDraggable(handle)
		handle.Active = true
		track(handle.InputBegan:Connect(function(input)
			if WindowHandler.InStartupAnim or WindowHandler.IsMinimized or WindowHandler.Destroyed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				dragStart = input.Position
				dragStartOffset = dragOffset
			end
		end))
	end

	makeDraggable(CollapsedView)
	makeDraggable(HeaderPill)
	makeDraggable(TopDragZone)

	track(UserInputService.InputChanged:Connect(function(input)
		if isDragging and dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			dragOffset = Vector2.new(dragStartOffset.X + delta.X, dragStartOffset.Y + delta.Y)
			applyDrag()
		end
	end))

	track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end))

	-- ---------- viewport scaling ----------
	local scales = { StarScale, FXScale, FXTopScale, ShadowScale, BaseScale, FrontScale, CoreScale }
	local function applyScale()
		local cam = Workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local s = math.clamp(math.min(vp.X, vp.Y) / 760, 0.45, 1)
		for _, u in ipairs(scales) do u.Scale = s end
		applyDrag()
	end
	applyScale()
	if Workspace.CurrentCamera then
		track(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale))
	end

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
		isDragging = false
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

	function WindowHandler:Toggle()
		if self.IsMinimized then self:Restore() else self:Minimize() end
	end

	function WindowHandler:Destroy()
		if self.Destroyed then return end
		self.Destroyed = true
		isDragging = false
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
			if NotifyHolder == nil or NotifyHolder.Parent == ScreenGui then NotifyHolder = nil end
			ScreenGui:Destroy()
		end)
	end

	function WindowHandler:Notify(cfg)
		Orbital:Notify(cfg)
	end

	function WindowHandler:SetParallax(on, strength)
		parallaxOn = on and true or false
		if strength then parStrength = tonumber(strength) or parStrength end
	end

	function WindowHandler:SetSounds(on)
		Orbital.SoundsEnabled = on and true or false
	end

	function WindowHandler:SetToggleKey(key)
		toggleKey = key
	end

	track(UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or WindowHandler.Destroyed then return end
		if toggleKey and input.KeyCode == toggleKey then
			WindowHandler:Toggle()
		end
	end))
	track(MiniEarth.MouseButton1Click:Connect(function() WindowHandler:Restore() end))

	-- touch-only devices have no toggle key: give them a floating orb
	local showToggleBtn = settings.ToggleButton
	if showToggleBtn == nil then
		showToggleBtn = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end
	if showToggleBtn then
		local TB = new("TextButton", {
			Name = "ToggleOrb",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.new(0, 46, 0, 46),
			BackgroundColor3 = Theme.CoreBg,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "🌍",
			TextSize = 22,
			Font = Enum.Font.GothamBold,
			ZIndex = 12,
		}, ScreenGui)
		round(TB)
		sweep(outline(TB, Color3.new(1, 1, 1), 2.5), 80)
		track(TB.MouseButton1Click:Connect(function()
			if WindowHandler.Destroyed then return end
			WindowHandler:Toggle()
		end))
	end

	-- ===================================================================
	--   NODE GENERATOR (with depth shadows)
	-- ===================================================================
	local function canHover()
		return (not WindowHandler.IsExpanded) and (not WindowHandler.IsMinimized) and (not WindowHandler.InStartupAnim) and (not isDragging)
	end

	local function createBaseNode(title, iconText, isClose)
		local baseCol = isClose and Theme.RedClose or Theme.Accent
		local glowCol = isClose and Theme.RedCloseGlow or Theme.AccentGlow

		-- depth shadows live in a lower layer and mirror the node every frame
		local ShadowB = new("Frame", {
			Name = title .. "_ShadowSoft",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(0, 4, 12),
			BackgroundTransparency = 0.88,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 1,
		}, ShadowLayer)
		round(ShadowB)
		local ShadowA = new("Frame", {
			Name = title .. "_ShadowGlow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = baseCol,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 2,
		}, ShadowLayer)
		round(ShadowA)

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
			ShadowA = ShadowA,
			ShadowB = ShadowB,
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

	-- globe reveal (driven by the startup sequence, read by the render loop)
	local globeRevealTarget = 0

	-- ===================================================================
	--   STARTUP ANIMATION  (cinematic)
	-- ===================================================================
	local function scrambleText(lbl, final, duration)
		local glyphs = glyphsOf(final)
		local n = #glyphs
		if n == 0 then return end
		local pool = glyphsOf("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#%&@")
		local steps = math.max(12, math.floor(duration / 0.03))
		for s = 1, steps do
			if WindowHandler.Destroyed then return end
			local reveal = math.floor(n * s / steps)
			local parts = {}
			for i = 1, n do
				if i <= reveal or glyphs[i] == " " then
					parts[i] = glyphs[i]
				else
					parts[i] = pool[math.random(1, #pool)]
				end
			end
			lbl.Text = table.concat(parts)
			task.wait(0.03)
		end
		lbl.Text = final
	end

	task.defer(function()
		WindowHandler.InStartupAnim = true
		CoreHolder.Size = UDim2.new(0, 0, 0, 0)
		IntroScale.Scale = 1.28

		-- ring dots stay dark until the boot sweep lights them
		local ringDots = {}
		for _, d in ipairs(OrbitRing:GetChildren()) do
			if d:IsA("Frame") then
				ringDots[#ringDots + 1] = { f = d, tr = d.BackgroundTransparency }
				d.BackgroundTransparency = 1
			end
		end

		task.wait(0.3)
		if WindowHandler.Destroyed then return end

		-- stage 1: singularity spark + energy converging inward ----------
		glowTarget = 1
		playSound(Orbital.Sounds.Open, 0.6, 0.8)
		local spark = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 3,
		}, FX)
		round(spark)
		tw(spark, { Size = UDim2.new(0, 24, 0, 24) }, 0.6, Enum.EasingStyle.Quint)
		for i = 1, 3 do
			task.delay((i - 1) * 0.15, function()
				if not WindowHandler.Destroyed then
					shockwave(Theme.AccentGlow, 320, 14, 0.55, 2.5)
				end
			end)
		end
		task.wait(0.75)
		if WindowHandler.Destroyed then return end

		-- stage 2: ignition (flash, camera push-in, core blooms) ---------
		playSound(Orbital.Sounds.Open, 0.8, 1.0)
		tw(spark, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.3)
		Debris:AddItem(spark, 0.4)
		Flash.BackgroundTransparency = 0.5
		tw(Flash, { BackgroundTransparency = 1 }, 0.7)
		tw(CoreHolder, { Size = UDim2.new(0, 300, 0, 300) }, 0.7, Enum.EasingStyle.Back)
		tw(IntroScale, { Scale = 1 }, 2.4, Enum.EasingStyle.Quint)
		shockwave(Theme.AccentGlow, 120, 760, 1.1, 5)
		shockwave(Color3.new(1, 1, 1), 80, 520, 0.7, 2)

		-- boot sweep: the orbit-ring dots light up one after another
		for i, rd in ipairs(ringDots) do
			task.delay(0.2 + i * 0.016, function()
				if rd.f.Parent then tw(rd.f, { BackgroundTransparency = rd.tr }, 0.3) end
			end)
		end
		task.wait(0.6)
		if WindowHandler.Destroyed then return end

		-- stage 3: the planet fades in ------------------------------------
		globeRevealTarget = 1
		shockwave(Theme.Deep, 200, 640, 0.9, 3)
		task.wait(0.6)
		if WindowHandler.Destroyed then return end

		-- stage 4: nodes spiral in with comet trails ----------------------
		playSound(Orbital.Sounds.Open, 1.15, 0.8)
		shockwave(Theme.Accent, 220, 780, 1.3, 3)

		local tabs = {}
		for i, t in ipairs(WindowHandler.Tabs) do tabs[i] = t end
		local total  = #tabs
		local R      = math.max(235, (total * 150) / (2 * math.pi))
		WindowHandler.Radius = R
		local tabDur, stagger = 1.3, 0.08
		local totalTime = tabDur + math.max(0, total - 1) * stagger

		for _, tab in ipairs(tabs) do
			tab.Frame.Size = UDim2.new(0, 0, 0, 0)
			tab.Frame.Position = UDim2.new(0.5, 0, 0.5, -60)
			tab.Frame.Visible = true
			tab.Stroke.Transparency = 0
			tab.Stroke.Thickness = 4.8
			tab.Icon.TextTransparency = 1
		end

		local landed = {}
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
						BackgroundColor3 = tab.IsClose and Theme.RedCloseGlow or Theme.AccentGlow,
						BorderSizePixel = 0,
					}, BaseCenter)
					round(d)
					d.ZIndex = 1
					tw(d, { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }, 0.55)
					Debris:AddItem(d, 0.6)
				end

				-- landing ripple + rising "tick"
				if tp >= 1 and not landed[i] then
					landed[i] = true
					ping(x, y, tab.IsClose and Theme.RedClose or Theme.AccentGlow)
					playSound(Orbital.Sounds.Hover, 1.1 + i * 0.07, 0.3)
				end
			end
		until el >= totalTime

		playSound(Orbital.Sounds.Notify, 1.4, 1.0)
		shockwave(Theme.AccentGlow, 210, 660, 0.9, 4)
		task.wait(0.12)
		if WindowHandler.Destroyed then return end
		for i, tab in ipairs(tabs) do
			task.delay((i - 1) * 0.04, function()
				resetTabToIdle(tab)
			end)
		end

		-- stage 5: title decodes ------------------------------------------
		scrambleText(CoreTitle, string.upper(winTitle), 0.7)
		if WindowHandler.Destroyed then return end

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
	--   MAIN RENDER LOOP  (planet spin, parallax, depth, moon, shadows)
	-- ===================================================================
	local t0 = os.clock()
	local starTimer = 3
	local moonFront = false
	local spinAngle = 0
	local expandBlend = 0
	local globeReveal = 0
	local parX, parY = 0, 0
	local lastOrbitR, lastMoonVis = -1, -1
	local avgDt, globeAcc = 1 / 60, 0
	local mounted = false

	local function shiftLayer(frame, ox, oy)
		frame.Position = UDim2.new(0.5 + ox / DESIGN, 0, 0.5 + oy / DESIGN, 0)
	end

	track(RunService.RenderStepped:Connect(function(dt)
		if WindowHandler.Destroyed then return end
		if mounted and ScreenGui.Parent == nil then
			-- GUI was removed externally (e.g. a newer window replaced it): stop all work
			WindowHandler.Destroyed = true
			for _, c in ipairs(conns) do
				pcall(function() c:Disconnect() end)
			end
			return
		end
		dt = math.min(dt, 0.1)
		local t = os.clock() - t0

		-- adaptive frame budget: globe re-renders at 30 Hz if the game is struggling
		avgDt = avgDt + (dt - avgDt) * 0.04
		local globeInterval = (avgDt > 1 / 40) and (1 / 30) or 0
		globeAcc = globeAcc + dt
		local doGlobe = globeAcc >= globeInterval
		if doGlobe then globeAcc = 0 end

		-- gradient sweeps
		for i = #spinners, 1, -1 do
			local s = spinners[i]
			if s.g.Parent then
				s.g.Rotation = (s.g.Rotation + s.speed * dt) % 360
			else
				table.remove(spinners, i)
			end
		end

		-- ---------- 2.5D parallax (smoothed cursor + idle drift) ----------
		local sc = CoreScale.Scale
		if parallaxOn then
			local tx, ty = 0, 0
			if UserInputService.MouseEnabled then
				local m = UserInputService:GetMouseLocation()
				local c = OrbitCenter.AbsolutePosition + (OrbitCenter.AbsoluteSize * 0.5)
				tx = math.clamp((m.X - c.X) / 420, -1, 1)
				ty = math.clamp((m.Y - c.Y) / 420, -1, 1)
			end
			tx = tx + math.sin(t * 0.55) * 0.16
			ty = ty + math.cos(t * 0.43) * 0.16
			local k = math.min(1, dt * 6)
			parX = parX + (tx - parX) * k
			parY = parY + (ty - parY) * k
		else
			parX, parY = 0, 0
		end
		local Sd = PARALLAX_PX * parStrength -- design px (inside scaled layers)
		local S  = Sd * sc                   -- real px (unscaled layers)
		local px, py = parX * S, parY * S

		-- layer depths: far = negative (moves against cursor), near = positive
		shiftLayer(GlowLayer,   px * -0.25, py * -0.25)
		shiftLayer(FX,          px * 0.25,  py * 0.25)
		shiftLayer(CoreHolder,  px * 0.25,  py * 0.25)
		shiftLayer(FXTop,       px * 0.25,  py * 0.25)
		shiftLayer(ShadowLayer, px * 0.65,  py * 0.65)
		shiftLayer(BaseCenter,  px * 1.0,   py * 1.0)
		shiftLayer(FrontLayer,  px * 1.7,   py * 1.7)

		-- ---------- ambient glow ----------
		glowIntensity = glowIntensity + (glowTarget - glowIntensity) * math.min(1, dt * 4)
		local flick = math.clamp(0.5 + math.noise(t * 2.2, 3.71), 0, 1)
		local coreDesign = CoreHolder.Visible and CoreHolder.Size.X.Offset or 0
		local coreSize = coreDesign * sc
		for i, g in ipairs(Glow) do
			local sz = coreSize + (2 * GLOW_PADS[i] * sc * (0.94 + 0.12 * flick))
			g.Size = UDim2.new(0, sz, 0, sz)
			g.BackgroundTransparency = 1 - ((1 - GLOW_BASE[i]) * glowIntensity * (0.78 + 0.22 * flick))
		end

		-- ---------- spinning rings ----------
		OrbitRing.Rotation = (t * 7) % 360
		BigOrbitRing.Rotation = (-t * 4) % 360

		-- ---------- the planet ----------
		expandBlend = expandBlend + ((WindowHandler.IsExpanded and 1 or 0) - expandBlend) * math.min(1, dt * 7)
		globeReveal = globeReveal + (globeRevealTarget - globeReveal) * math.min(1, dt * 3.2)
		spinAngle = (spinAngle + dt * 0.42) % (math.pi * 2)

		if CoreHolder.Visible and coreDesign > 4 then
			local dia = coreDesign * lerp(0.56, 0.9, expandBlend)
			-- inner parallax: planet floats above the core plate
			local gx, gy = parX * S * 0.3 / sc, parY * S * 0.3 / sc
			CoreGlobe.Holder.Position = UDim2.new(0.5 + gx / coreDesign, 0, lerp(0.45, 0.5, expandBlend) + gy / coreDesign, 0)
			if doGlobe then
				CoreGlobe:Render(spinAngle, dia, globeReveal * lerp(1, 0.26, expandBlend), expandBlend < 0.5)
			end
		else
			CoreGlobe.Holder.Visible = false
		end

		if MiniEarth.Visible and doGlobe then
			MiniGlobe:Render(spinAngle, MiniEarth.Size.X.Offset * 0.8, 1, false)
		end

		-- ---------- stars (per-star depth parallax) ----------
		for _, st in ipairs(stars) do
			local blink = 0.5 + 0.5 * math.sin(t * st.speed + st.phase)
			st.f.BackgroundTransparency = 1 - (st.max * (0.25 + 0.75 * blink) * glowIntensity)
			st.f.Position = UDim2.new(0.5 + (st.bx + parX * Sd * st.dep) / DESIGN, 0, 0.5 + (st.by + parY * Sd * st.dep) / DESIGN, 0)
		end

		-- ---------- foreground bokeh (fades out when a page is open) ----------
		local bokehVis = glowIntensity * (1 - expandBlend * 0.85)
		for _, b in ipairs(bokeh) do
			local wob = 0.6 + 0.4 * math.sin(t * b.sp * 2 + b.ph)
			b.f.BackgroundTransparency = 1 - (b.max * wob * bokehVis)
			local dx = math.sin(t * b.sp + b.ph) * 22
			local dy = math.cos(t * b.sp * 0.8 + b.ph) * 16
			b.f.Position = UDim2.new(0.5 + (b.bx + dx + parX * Sd * (b.dep - 1)) / DESIGN, 0, 0.5 + (b.by + dy + parY * Sd * (b.dep - 1)) / DESIGN, 0)
		end

		-- ---------- moon (depth-scaled) + orbit path ----------
		if moonOn and Moon then
			local mv = (1 - expandBlend) * math.clamp(glowIntensity * 1.6, 0, 1)
			local showMoon = coreDesign > 60 and mv > 0.04
			Moon.Visible = showMoon
			for i = 1, #orbitDots do orbitDots[i].f.Visible = showMoon end
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
					local sa = math.sin(a)
					local ox = math.cos(a) * R
					local oy = sa * R * MOON_FLAT
					local x  = (ox * MOON_COS) - (oy * MOON_SIN)
					local y  = (ox * MOON_SIN) + (oy * MOON_COS)
					local s  = (moonBase[i] * (1 + 0.32 * sa)) / DESIGN
					local mp = moonParts[i]
					mp.Position = UDim2.new(0.5 + x / DESIGN, 0, 0.5 + y / DESIGN, 0)
					mp.Size = UDim2.new(s, 0, s, 0)
					mp.BackgroundTransparency = lerp(moonBaseTr[i], 1, 1 - mv)
				end
				if math.abs(R - lastOrbitR) > 0.01 or math.abs(mv - lastMoonVis) > 0.005 then
					lastOrbitR, lastMoonVis = R, mv
					for i = 1, #orbitDots do
						local od = orbitDots[i]
						local ox = math.cos(od.a) * R
						local oy = math.sin(od.a) * R * MOON_FLAT
						local x  = (ox * MOON_COS) - (oy * MOON_SIN)
						local y  = (ox * MOON_SIN) + (oy * MOON_COS)
						od.f.Position = UDim2.new(0.5 + x / DESIGN, 0, 0.5 + y / DESIGN, 0)
						od.f.BackgroundTransparency = lerp(od.base, 1, 1 - mv)
					end
				end
			end
		end

		-- ---------- node depth shadows (mirror each node, lower layer) ----------
		for _, tab in ipairs(WindowHandler.Tabs) do
			local f = tab.Frame
			local fs = f.Size.X.Offset
			local a, b = tab.ShadowA, tab.ShadowB
			if f.Visible and fs > 2 then
				local elev = math.clamp((fs - 124) / 26, 0, 1.3)
				local p = f.Position
				a.Visible = true
				b.Visible = true
				a.Size = UDim2.new(0, fs * 0.9, 0, fs * 0.9)
				b.Size = UDim2.new(0, fs * 1.08, 0, fs * 1.08)
				a.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 6 + 8 * elev)
				b.Position = UDim2.new(p.X.Scale, p.X.Offset - 3 * elev, p.Y.Scale, p.Y.Offset + 14 + 12 * elev)
				a.BackgroundTransparency = 0.9 - 0.12 * elev
				b.BackgroundTransparency = 0.88 - 0.05 * elev
			else
				a.Visible = false
				b.Visible = false
			end
		end

		-- ---------- shooting stars ----------
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

		track(tab.ClickBtn.MouseButton1Click:Connect(function()
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
		end))
	end

	-- ===================================================================
	--   TAB (OPTIONS VIEW)
	-- ===================================================================
	function WindowHandler:CreateTab(tabName, icon)
		icon = icon or "🌍"
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
				PortalTitle.Text = icon .. "  " .. string.upper(tabName)
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

		local function setFlag(opts, v)
			if opts and opts.Flag then Orbital.Flags[opts.Flag] = v end
		end

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

			local lbl = label({
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

			local api = {}
			function api:Set(v) lbl.Text = "✦  " .. string.upper(tostring(v)) end
			return api
		end

		function TabElements:CreateLabel(text)
			local Card = makeCapsule(40)
			local lbl = label({
				Text = tostring(text or ""), TextSize = 13, TextColor3 = Theme.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -40, 1, 0),
			}, Card)
			local api = {}
			function api:Set(v) lbl.Text = tostring(v) end
			return api
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

			local nameLbl = label({
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

			local api = {}
			function api:SetName(v) nameLbl.Text = tostring(v) end
			return api
		end
		TabElements.AddButton = TabElements.CreateButton

		function TabElements:CreateToggle(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Toggle"
			local desc = opts.Description or opts.Desc or ""
			local state = opts.Default or false
			local callback = opts.Callback or function() end
			local hasDesc = (desc ~= "")
			setFlag(opts, state)

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
				setFlag(opts, state)
				playSound(Orbital.Sounds.Toggle, state and 1.3 or 0.85, 0.95)
				paint(state)
				task.spawn(callback, state)
			end)

			local api = {}
			function api:Set(v, silent)
				state = v and true or false
				setFlag(opts, state)
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
			if step <= 0 then step = 1 end
			local def = math.clamp(tonumber(opts.Default) or min, min, max)
			local callback = opts.Callback or function() end
			setFlag(opts, def)

			local decimals = 0
			if step < 1 then
				local s = string.format("%.6f", step):gsub("0+$", "")
				local dot = s:find("%.")
				decimals = dot and math.max(1, #s - dot) or 1
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
				local out = tonumber(formatVal(v)) or v
				setFlag(opts, out)
				task.spawn(callback, out)
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
				setFlag(opts, v)
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
			local maxVisible = math.max(1, tonumber(opts.MaxVisible) or 5)
			setFlag(opts, selected)

			local expanded = false
			local itemHeight = 36
			local collapsedHeight = 54
			local function listHeight()
				return math.min(#items, maxVisible) * (itemHeight + 4)
			end

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

			local ListHolder = new("ScrollingFrame", {
				Size = UDim2.new(1, -24, 0, listHeight()),
				Position = UDim2.new(0, 12, 0, collapsedHeight + 2),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Theme.Accent,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
			}, Card)
			new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, ListHolder)

			local DEFAULT_BG = Color3.fromRGB(12, 24, 40)
			local itemBtns = {}

			local function paintItems()
				for _, e in ipairs(itemBtns) do
					local sel = (e.item == selected)
					e.btn.BackgroundColor3 = sel and Theme.CardHover or DEFAULT_BG
					e.btn.TextColor3 = sel and Theme.AccentGlow or Theme.TextPrimary
					e.btn.Text = (sel and " ✦ " or "   ") .. tostring(e.item)
				end
			end

			local function choose(item, fire)
				selected = item
				curLbl.Text = tostring(item)
				setFlag(opts, item)
				paintItems()
				if fire then task.spawn(callback, selected) end
			end

			local function collapse()
				expanded = false
				tw(Arrow, { Rotation = 0 }, 0.2)
				tw(Card, { Size = UDim2.new(1, -12, 0, collapsedHeight) }, 0.25)
			end

			local function build()
				for _, c in ipairs(ListHolder:GetChildren()) do
					if c:IsA("TextButton") then c:Destroy() end
				end
				itemBtns = {}
				ListHolder.Size = UDim2.new(1, -24, 0, listHeight())
				for idx, item in ipairs(items) do
					local itmBtn = new("TextButton", {
						Size = UDim2.new(1, -4, 0, itemHeight),
						BackgroundColor3 = DEFAULT_BG,
						BorderSizePixel = 0,
						Font = Enum.Font.Gotham,
						TextSize = 13,
						TextColor3 = Theme.TextPrimary,
						Text = "   " .. tostring(item),
						TextXAlignment = Enum.TextXAlignment.Left,
						AutoButtonColor = false,
						LayoutOrder = idx,
					}, ListHolder)
					round(itmBtn, UDim.new(0, 8))
					itemBtns[#itemBtns + 1] = { btn = itmBtn, item = item }

					itmBtn.MouseEnter:Connect(function()
						playHoverSound(1.85, 0.5)
						tw(itmBtn, { BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.AccentGlow }, 0.12)
					end)
					itmBtn.MouseLeave:Connect(function()
						local sel = (item == selected)
						tw(itmBtn, {
							BackgroundColor3 = sel and Theme.CardHover or DEFAULT_BG,
							TextColor3 = sel and Theme.AccentGlow or Theme.TextPrimary,
						}, 0.12)
					end)
					itmBtn.MouseButton1Click:Connect(function()
						playSound(Orbital.Sounds.Click, 1.2, 0.9)
						choose(item, true)
						collapse()
					end)
				end
				paintItems()
			end
			build()

			HeaderBtn.MouseButton1Click:Connect(function()
				expanded = not expanded
				playSound(Orbital.Sounds.Click, 1.0, 0.9)
				local targetH = expanded and (collapsedHeight + listHeight() + 10) or collapsedHeight
				tw(Arrow, { Rotation = expanded and 180 or 0 }, 0.25)
				tw(Card, { Size = UDim2.new(1, -12, 0, targetH) }, 0.3, Enum.EasingStyle.Quint)
			end)

			local api = {}
			function api:Set(v, fire) choose(v, fire) end
			function api:Get() return selected end
			function api:Refresh(newItems, keepSelection)
				items = newItems or {}
				if not keepSelection then
					selected = items[1] or "Select..."
					curLbl.Text = tostring(selected)
					setFlag(opts, selected)
				end
				build()
				if expanded then
					Card.Size = UDim2.new(1, -12, 0, collapsedHeight + listHeight() + 10)
				end
			end
			return api
		end

		function TabElements:CreateKeybind(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Keybind"
			local currentKey = opts.Default or Enum.KeyCode.None
			local callback = opts.Callback or function() end
			local onChange = opts.OnChange or function() end
			setFlag(opts, currentKey)

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
							setFlag(opts, currentKey)
							playSound(Orbital.Sounds.Click, 0.95, 0.95)
							task.spawn(onChange, currentKey)
						end
						KeyBtn.Text = currentKey == Enum.KeyCode.None and "None" or currentKey.Name
					end
				elseif not gpe and currentKey ~= Enum.KeyCode.None and input.KeyCode == currentKey then
					task.spawn(callback, currentKey)
				end
			end))

			local api = {}
			function api:Get() return currentKey end
			function api:Set(k)
				currentKey = k or Enum.KeyCode.None
				setFlag(opts, currentKey)
				KeyBtn.Text = currentKey == Enum.KeyCode.None and "None" or currentKey.Name
			end
			return api
		end

		function TabElements:CreateInput(opts)
			opts = opts or {}
			local name = opts.Name or opts.Title or "Input"
			local callback = opts.Callback or function() end
			setFlag(opts, opts.Default or "")

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
				setFlag(opts, Box.Text)
				task.spawn(callback, Box.Text, enterPressed)
			end)

			local api = {}
			function api:Set(v) Box.Text = tostring(v); setFlag(opts, Box.Text) end
			function api:Get() return Box.Text end
			return api
		end

		function TabElements:CreateParagraph(opts)
			opts = opts or {}
			local title = opts.Title or "Information"
			local content = tostring(opts.Content or "")

			local okT, sz = pcall(function()
				return TextService:GetTextSize(content, 13, Enum.Font.Gotham, Vector2.new(360, 10000))
			end)
			local textH = okT and sz.Y or 16
			local Card = makeCapsule(math.max(64, 44 + textH + 14))

			local titleLbl = label({
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

			local api = {}
			function api:SetTitle(v) titleLbl.Text = tostring(v) end
			return api
		end

		return TabElements
	end

	-- ---------- mount ----------
	if typeof(syn) == "table" and syn.protect_gui then
		pcall(syn.protect_gui, ScreenGui)
	end
	for _, p in ipairs(candidateParents()) do
		local ok = pcall(function() ScreenGui.Parent = p end)
		if ok and ScreenGui.Parent == p then
			mounted = true
			break
		end
	end
	if not mounted then
		warn("[Orbital] Could not mount the UI to any container.")
	end

	return WindowHandler
end

return Orbital
