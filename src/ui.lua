--// ui.lua
--// Stud UI Pack Edition - Figma Rays Header & Custom Vibrant Tab Colors
--// Fully compatible with main.lua

local tweenservice = game:GetService("TweenService")
local runservice   = game:GetService("RunService")

--------------------------------------------------------------
-- STUD UI PACK COLOR PALETTE & FONTS
--------------------------------------------------------------
local MAIN_BG    = Color3.fromRGB(16, 16, 22)      -- Main Studded Frame BG
local PANEL_BG   = Color3.fromRGB(24, 24, 32)      -- Inner Panels / Containers
local BLACK_OUT  = Color3.fromRGB(0, 0, 0)         -- Thick Black UI Strokes
local WHITE      = Color3.fromRGB(255, 255, 255)
local LIGHT_GRAY = Color3.fromRGB(210, 215, 230)
local MUTED_GRAY = Color3.fromRGB(150, 155, 175)

-- Header Base Gradient
local BLUE_TOP   = Color3.fromRGB(0, 180, 255)     -- Header Blue Top
local BLUE_BOT   = Color3.fromRGB(0, 105, 210)     -- Header Blue Bottom

-- Tab Theme Color Palette (Distinct Stud Colors for Each Tab)
local TAB_THEMES = {
	Home      = { Top = Color3.fromRGB(0, 180, 255),   Bot = Color3.fromRGB(0, 105, 210),   Accent = Color3.fromRGB(0, 230, 255) },
	Game      = { Top = Color3.fromRGB(0, 220, 110),   Bot = Color3.fromRGB(0, 130, 60),    Accent = Color3.fromRGB(50, 255, 140) },
	Gameslist = { Top = Color3.fromRGB(255, 210, 20),   Bot = Color3.fromRGB(180, 130, 0),   Accent = Color3.fromRGB(255, 235, 80) },
	Settings  = { Top = Color3.fromRGB(210, 50, 240),  Bot = Color3.fromRGB(120, 20, 150),  Accent = Color3.fromRGB(245, 120, 255) },
	Credits   = { Top = Color3.fromRGB(255, 70, 80),   Bot = Color3.fromRGB(170, 20, 30),   Accent = Color3.fromRGB(255, 130, 140) },
}

local TAB_INACT_1 = Color3.fromRGB(55, 55, 70)    -- Inactive Tab Top
local TAB_INACT_2 = Color3.fromRGB(35, 35, 45)    -- Inactive Tab Bottom
local RED_TOP    = Color3.fromRGB(255, 60, 70)     -- Close Button Red Top
local RED_BOT    = Color3.fromRGB(180, 15, 25)     -- Close Button Red Bottom

local F_STUD = Enum.Font.FredokaOne
local F_SUB  = Enum.Font.FredokaOne

local SMOOTH = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GLIDE  = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local BOUNCE = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SNAP   = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------
local function tw(o, i, p)
	local t = tweenservice:Create(o, i, p)
	t:Play()
	return t
end

local function lighten(c, f)
	return Color3.new(math.min(c.R * f, 1), math.min(c.G * f, 1), math.min(c.B * f, 1))
end

local function corner(p, rad)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, rad or 8)
	c.Parent = p
	return c
end

local function stroke(p, th, col)
	local s = Instance.new("UIStroke")
	s.Thickness = th or 2.5
	s.Color = col or BLACK_OUT
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function textStroke(p, th, col)
	local s = Instance.new("UIStroke")
	s.Thickness = th or 2
	s.Color = col or BLACK_OUT
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = p
	return s
end

local function glossyGradient(p, topCol, botCol, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(topCol, botCol)
	g.Rotation = rot or 90
	g.Parent = p
	return g
end

local rng = Random.new(os.time() % 99991)

--------------------------------------------------------------
-- STUDDED BACKGROUND PATTERN
--------------------------------------------------------------
local function addStudBackground(parent)
	local bg = Instance.new("Frame")
	bg.Name = "StuddedBackground"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = MAIN_BG
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true
	bg.Active = false
	bg.ZIndex = 400
	bg.Parent = parent

	-- Tiled studs texture overlay
	local studs = Instance.new("ImageLabel")
	studs.Name = "StudGridTexture"
	studs.Size = UDim2.new(1, 0, 1, 0)
	studs.BackgroundTransparency = 1
	studs.Image = "rbxassetid://9826359020" -- Roblox stud grid texture
	studs.ImageColor3 = Color3.fromRGB(45, 45, 60)
	studs.ImageTransparency = 0.65
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.new(0, 24, 0, 24)
	studs.ZIndex = 400
	studs.Parent = bg

	-- Vignette overlay
	local vig = Instance.new("Frame")
	vig.Name = "vignette"
	vig.Size = UDim2.new(1, 0, 1, 0)
	vig.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	vig.BackgroundTransparency = 0.75
	vig.BorderSizePixel = 0
	vig.ZIndex = 400
	vig.Parent = bg

	local vg = Instance.new("UIGradient")
	vg.Rotation = 90
	vg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.9),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	vg.Parent = vig

	return bg
end

--------------------------------------------------------------
-- ROOT GUI
--------------------------------------------------------------
local ui = Instance.new("ScreenGui")
ui.Name = "\0LoadedHub"
ui.ResetOnSpawn = false
ui.IgnoreGuiInset = true
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.DisplayOrder = 9999

--------------------------------------------------------------
-- TOGGLE BUTTON
--------------------------------------------------------------
local togglebtn = Instance.new("TextButton")
togglebtn.Name = "togglebtn"
togglebtn.Size = UDim2.new(0, 170, 0, 44)
togglebtn.Position = UDim2.new(0.5, -85, 0.03, 0)
togglebtn.BackgroundColor3 = BLUE_TOP
togglebtn.AutoButtonColor = false
togglebtn.Text = "LOADED HUB"
togglebtn.TextColor3 = WHITE
togglebtn.TextSize = 18
togglebtn.Font = F_STUD
togglebtn.BorderSizePixel = 0
togglebtn.ClipsDescendants = true
togglebtn.Visible = false
togglebtn.ZIndex = 600
togglebtn.Parent = ui

corner(togglebtn, 8)
stroke(togglebtn, 3, BLACK_OUT)
textStroke(togglebtn, 2, BLACK_OUT)
glossyGradient(togglebtn, BLUE_TOP, BLUE_BOT, 90)

local scToggle = Instance.new("UIScale")
scToggle.Parent = togglebtn

task.spawn(function()
	while togglebtn.Parent do
		if togglebtn.Visible then
			tw(scToggle, TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = 1.035})
			task.wait(1.4)
			tw(scToggle, TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = 1})
			task.wait(1.4)
		else
			task.wait(0.5)
		end
	end
end)

--------------------------------------------------------------
-- MAIN FRAME
--------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Frame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 782, 0, 480)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = MAIN_BG
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 400
MainFrame.Parent = ui

corner(MainFrame, 10)
stroke(MainFrame, 3.5, BLACK_OUT)

addStudBackground(MainFrame)

local scMain = Instance.new("UIScale")
scMain.Scale = 0.9
scMain.Parent = MainFrame
tw(scMain, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

--------------------------------------------------------------
-- TOPBAR (FIGMA RAYS STYLE HEADER)
--------------------------------------------------------------
local Topbar = Instance.new("Frame")
Topbar.Name = "TopBar"
Topbar.Size = UDim2.new(1, 0, 0, 70)
Topbar.BackgroundColor3 = BLUE_TOP
Topbar.BorderSizePixel = 0
Topbar.ClipsDescendants = true
Topbar.ZIndex = 401
Topbar.Parent = MainFrame

corner(Topbar, 8)
stroke(Topbar, 3, BLACK_OUT)
glossyGradient(Topbar, BLUE_TOP, BLUE_BOT, 90)

-- FIGMA LIGHT RAYS OVERLAY EFFECT
do
	local raysOverlay = Instance.new("ImageLabel")
	raysOverlay.Name = "RaysOverlay"
	raysOverlay.Size = UDim2.new(1, 0, 1, 0)
	raysOverlay.Position = UDim2.new(0, 0, 0, 0)
	raysOverlay.BackgroundTransparency = 1
	raysOverlay.Image = "rbxassetid://10842502695" -- High quality Figma diagonal light rays
	raysOverlay.ImageColor3 = Color3.fromRGB(255, 255, 255)
	raysOverlay.ImageTransparency = 0.65
	raysOverlay.ScaleType = Enum.ScaleType.Crop
	raysOverlay.ZIndex = 402
	raysOverlay.Parent = Topbar

	-- Additional procedural light ray beams
	for i = 1, 3 do
		local beam = Instance.new("Frame")
		beam.Name = "RayBeam" .. i
		beam.AnchorPoint = Vector2.new(0.5, 0.5)
		beam.Size = UDim2.new(0, i * 45 + 30, 2.5, 0)
		beam.Position = UDim2.new(i * 0.28, 0, 0.5, 0)
		beam.BackgroundColor3 = WHITE
		beam.BackgroundTransparency = 0.88
		beam.BorderSizePixel = 0
		beam.Rotation = -35
		beam.ZIndex = 402
		beam.Parent = Topbar

		local bg = Instance.new("UIGradient")
		bg.Rotation = 90
		bg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		bg.Parent = beam
	end
end

-- Sheen animation across header
do
	local sheen = Instance.new("Frame")
	sheen.Name = "sheen"
	sheen.Size = UDim2.new(0, 110, 2.5, 0)
	sheen.Position = UDim2.new(0, -150, -0.5, 0)
	sheen.BackgroundColor3 = WHITE
	sheen.BackgroundTransparency = 0.85
	sheen.BorderSizePixel = 0
	sheen.Rotation = 25
	sheen.ZIndex = 403
	sheen.Parent = Topbar

	task.spawn(function()
		while sheen.Parent do
			task.wait(rng:NextNumber(4, 7))
			sheen.Position = UDim2.new(0, -150, -0.5, 0)
			tw(sheen, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Position = UDim2.new(1, 170, -0.5, 0)})
		end
	end)
end

-- Header Icon Box (White Stud Box)
local badge = Instance.new("Frame")
badge.Name = "badge"
badge.AnchorPoint = Vector2.new(0, 0.5)
badge.Size = UDim2.new(0, 44, 0, 44)
badge.Position = UDim2.new(0, 14, 0.5, 0)
badge.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
badge.BorderSizePixel = 0
badge.ZIndex = 404
badge.Parent = Topbar

corner(badge, 8)
stroke(badge, 2.5, BLACK_OUT)
glossyGradient(badge, Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 210, 225), 90)

local badgeTxt = Instance.new("TextLabel")
badgeTxt.Name = "lh"
badgeTxt.Size = UDim2.new(1, 0, 1, 0)
badgeTxt.BackgroundTransparency = 1
badgeTxt.Text = "LH"
badgeTxt.TextColor3 = Color3.fromRGB(0, 110, 210)
badgeTxt.TextSize = 20
badgeTxt.Font = F_STUD
badgeTxt.ZIndex = 405
badgeTxt.Parent = badge
textStroke(badgeTxt, 2, BLACK_OUT)

-- Header Title & Subtitle
local title = Instance.new("TextLabel")
title.Name = "title"
title.AnchorPoint = Vector2.new(0, 0.5)
title.Size = UDim2.new(0, 280, 0, 28)
title.Position = UDim2.new(0, 68, 0.5, -8)
title.BackgroundTransparency = 1
title.Text = "LOADED HUB"
title.TextColor3 = WHITE
title.TextSize = 24
title.Font = F_STUD
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 404
title.Parent = Topbar
textStroke(title, 2.5, BLACK_OUT)

local sub = Instance.new("TextLabel")
sub.Name = "sub"
sub.AnchorPoint = Vector2.new(0, 0.5)
sub.Size = UDim2.new(0, 280, 0, 16)
sub.Position = UDim2.new(0, 70, 0.5, 14)
sub.BackgroundTransparency = 1
sub.Text = "good games scripts"
sub.TextColor3 = Color3.fromRGB(210, 240, 255)
sub.TextSize = 13
sub.Font = F_SUB
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.ZIndex = 404
sub.Parent = Topbar
textStroke(sub, 1.5, BLACK_OUT)

-- Hide UI Button
local hidebtn = Instance.new("TextButton")
hidebtn.Name = "hidebtn"
hidebtn.AnchorPoint = Vector2.new(1, 0.5)
hidebtn.Size = UDim2.new(0, 100, 0, 36)
hidebtn.Position = UDim2.new(1, -62, 0.5, 0)
hidebtn.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
hidebtn.AutoButtonColor = false
hidebtn.Text = "Hide UI"
hidebtn.TextColor3 = WHITE
hidebtn.TextSize = 16
hidebtn.Font = F_STUD
hidebtn.ZIndex = 404
hidebtn.Parent = Topbar

corner(hidebtn, 6)
stroke(hidebtn, 2, BLACK_OUT)
textStroke(hidebtn, 2, BLACK_OUT)
glossyGradient(hidebtn, Color3.fromRGB(0, 160, 240), Color3.fromRGB(0, 90, 180), 90)

hidebtn.MouseEnter:Connect(function()
	tw(hidebtn, SMOOTH, {BackgroundColor3 = Color3.fromRGB(0, 180, 255)})
end)
hidebtn.MouseLeave:Connect(function()
	tw(hidebtn, SMOOTH, {BackgroundColor3 = Color3.fromRGB(0, 130, 220)})
end)

-- Close Button ("X" Red Glossy Button)
local closebtn = Instance.new("TextButton")
closebtn.Name = "closebtn"
closebtn.AnchorPoint = Vector2.new(1, 0.5)
closebtn.Size = UDim2.new(0, 38, 0, 38)
closebtn.Position = UDim2.new(1, -12, 0.5, 0)
closebtn.BackgroundColor3 = RED_TOP
closebtn.AutoButtonColor = false
closebtn.Text = "X"
closebtn.TextColor3 = WHITE
closebtn.TextSize = 20
closebtn.Font = F_STUD
closebtn.ZIndex = 404
closebtn.Parent = Topbar

corner(closebtn, 6)
stroke(closebtn, 2.5, BLACK_OUT)
textStroke(closebtn, 2, BLACK_OUT)
glossyGradient(closebtn, RED_TOP, RED_BOT, 90)

closebtn.MouseEnter:Connect(function()
	tw(closebtn, SMOOTH, {BackgroundColor3 = Color3.fromRGB(255, 90, 100)})
end)
closebtn.MouseLeave:Connect(function()
	tw(closebtn, SMOOTH, {BackgroundColor3 = RED_TOP})
end)

--------------------------------------------------------------
-- TAB LIST (STUD PANEL WITH DISTINCT TAB COLORS)
--------------------------------------------------------------
local TabList = Instance.new("Frame")
TabList.Name = "tablist"
TabList.Size = UDim2.new(0, 220, 1, -128)
TabList.Position = UDim2.new(0, 12, 0, 80)
TabList.BackgroundColor3 = PANEL_BG
TabList.BorderSizePixel = 0
TabList.ZIndex = 401
TabList.Parent = MainFrame

corner(TabList, 8)
stroke(TabList, 2.5, BLACK_OUT)

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 8)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = TabList

local tabPad = Instance.new("UIPadding")
tabPad.PaddingTop = UDim.new(0, 10)
tabPad.PaddingLeft = UDim.new(0, 8)
tabPad.PaddingRight = UDim.new(0, 8)
tabPad.Parent = TabList

-- Icon renderer for tabs
local function icon(parent, kind)
	local box = Instance.new("Frame")
	box.Name = "icon"
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.Size = UDim2.new(0, 24, 0, 24)
	box.Position = UDim2.new(0, 8, 0.5, 0)
	box.BackgroundTransparency = 1
	box.ZIndex = 406
	box.Parent = parent

	local function bit(w, h, x, y, rad, rot)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.new(0, w, 0, h)
		f.Position = UDim2.new(0.5, x, 0.5, y)
		f.BackgroundColor3 = WHITE
		f.BorderSizePixel = 0
		f.Rotation = rot or 0
		f.ZIndex = 406
		f.Parent = box
		if rad then corner(f, rad) end
		return f
	end

	local function outline(w, h, x, y, rad, th)
		local f = bit(w, h, x, y, rad)
		f.BackgroundTransparency = 1
		local s = Instance.new("UIStroke")
		s.Thickness = th or 2
		s.Color = WHITE
		s.Parent = f
		return f
	end

	if kind == "Home" then
		bit(14, 2, -4, -5, 1, 45)
		bit(14, 2, 4, -5, 1, -45)
		bit(2, 10, -6, 3, 1)
		bit(2, 10, 6, 3, 1)
		bit(14, 2, 0, 7, 1)
	elseif kind == "Game" then
		outline(20, 13, 0, 1, 4)
		bit(6, 2, -4, 1, 1)
		bit(2, 6, -4, 1, 1)
		bit(3, 3, 3, -1, 999)
		bit(3, 3, 6, 3, 999)
	elseif kind == "Gameslist" then
		outline(19, 17, 0, 0, 4)
		for i = -1, 1 do
			bit(3, 3, -4, i * 4, 999)
			bit(7, 2, 3, i * 4, 1)
		end
	elseif kind == "Settings" then
		outline(15, 15, 0, 0, 999, 2.5)
		for i = 0, 5 do
			local a = i * math.pi / 3
			bit(4, 4, math.floor(math.cos(a) * 9), math.floor(math.sin(a) * 9), 1, math.deg(a))
		end
	elseif kind == "Credits" then
		outline(14, 12, 0, -3, 3)
		bit(2, 5, 0, 5, 1)
		bit(10, 2, 0, 9, 1)
	end

	return box
end

-- Tab Button Creator with Custom Multi-Color Stud Themes
local function newTab(name, label, order)
	local b = Instance.new("TextButton")
	b.Name = name .. "Tab"
	b.Size = UDim2.new(1, 0, 0, 48)
	b.BackgroundColor3 = TAB_INACT_1
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.Text = ""
	b.BorderSizePixel = 0
	b.ClipsDescendants = true
	b.LayoutOrder = order
	b.ZIndex = 404
	b.Parent = TabList

	corner(b, 6)
	stroke(b, 2, BLACK_OUT)

	local theme = TAB_THEMES[name] or TAB_THEMES.Home

	-- Active/Hover Gradient
	local tabGrad = glossyGradient(b, TAB_INACT_1, TAB_INACT_2, 90)

	-- Highlight overlay
	local hl = Instance.new("Frame")
	hl.Name = "hl"
	hl.Size = UDim2.new(1, 0, 1, 0)
	hl.BackgroundColor3 = theme.Top
	hl.BackgroundTransparency = 1
	hl.BorderSizePixel = 0
	hl.ZIndex = 404
	hl.Parent = b
	corner(hl, 6)

	-- InnerShadow expected by main.lua
	local ish = Instance.new("Frame")
	ish.Name = "InnerShadow"
	ish.Size = UDim2.new(1, 0, 1, 0)
	ish.BackgroundColor3 = WHITE
	ish.BackgroundTransparency = 1
	ish.BorderSizePixel = 0
	ish.ZIndex = 405
	ish.Parent = b
	corner(ish, 6)

	-- Left Accent Bar (Custom Theme Accent)
	local mark = Instance.new("Frame")
	mark.Name = "mark"
	mark.AnchorPoint = Vector2.new(0, 0.5)
	mark.Size = UDim2.new(0, 4, 0, 0)
	mark.Position = UDim2.new(0, 3, 0.5, 0)
	mark.BackgroundColor3 = theme.Accent
	mark.BorderSizePixel = 0
	mark.ZIndex = 407
	mark.Parent = b
	corner(mark, 999)

	local ic = icon(b, name)
	local icScale = Instance.new("UIScale")
	icScale.Parent = ic

	local t = Instance.new("TextLabel")
	t.Name = "label"
	t.Size = UDim2.new(1, -44, 1, 0)
	t.Position = UDim2.new(0, 40, 0, 0)
	t.BackgroundTransparency = 1
	t.Text = label
	t.TextColor3 = LIGHT_GRAY
	t.TextSize = 17
	t.Font = F_STUD
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 406
	t.Parent = b
	textStroke(t, 2, BLACK_OUT)

	local active = false

	b.MouseEnter:Connect(function()
		if not active then
			tw(hl, SMOOTH, {BackgroundTransparency = 0.8})
			tw(t, SMOOTH, {TextColor3 = WHITE})
		end
		tw(icScale, BOUNCE, {Scale = 1.12})
	end)

	b.MouseLeave:Connect(function()
		if not active then
			tw(hl, SMOOTH, {BackgroundTransparency = 1})
			tw(t, SMOOTH, {TextColor3 = LIGHT_GRAY})
		end
		tw(icScale, SMOOTH, {Scale = 1})
	end)

	-- Synchronized with main.lua tab switching signal
	b:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		active = b.BackgroundTransparency < 0.5

		if active then
			tabGrad.Color = ColorSequence.new(theme.Top, theme.Bot)
			t.TextColor3 = WHITE
			tw(hl, GLIDE, {BackgroundTransparency = 0.1})
			tw(mark, BOUNCE, {Size = UDim2.new(0, 4, 0, 24)})
		else
			tabGrad.Color = ColorSequence.new(TAB_INACT_1, TAB_INACT_2)
			t.TextColor3 = LIGHT_GRAY
			tw(hl, GLIDE, {BackgroundTransparency = 1})
			tw(mark, SMOOTH, {Size = UDim2.new(0, 4, 0, 0)})
		end
	end)

	return b
end

newTab("Home",      "Home",       1)
newTab("Game",      "Game",       2)
newTab("Gameslist", "Games List", 3)
newTab("Settings",  "Settings",   4)
newTab("Credits",   "Credits",    5)

--------------------------------------------------------------
-- SECTION CONTAINERS
--------------------------------------------------------------
local SectionContainers = Instance.new("Frame")
SectionContainers.Name = "sectionContainers"
SectionContainers.Size = UDim2.new(1, -256, 1, -128)
SectionContainers.Position = UDim2.new(0, 244, 0, 80)
SectionContainers.BackgroundColor3 = PANEL_BG
SectionContainers.BorderSizePixel = 0
SectionContainers.ClipsDescendants = true
SectionContainers.ZIndex = 401
SectionContainers.Parent = MainFrame

corner(SectionContainers, 8)
stroke(SectionContainers, 2.5, BLACK_OUT)

local function newSection(name)
	local f = Instance.new("ScrollingFrame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Size = UDim2.new(1, -16, 1, -14)
	f.Position = UDim2.new(0.5, 0, 1, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.ScrollBarThickness = 5
	f.ScrollBarImageColor3 = BLUE_TOP
	f.CanvasSize = UDim2.new(0, 0, 0, 0)
	f.AutomaticCanvasSize = Enum.AutomaticSize.Y
	f.Visible = false
	f.ZIndex = 402
	f.Parent = SectionContainers

	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 8)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = f

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = f

	return f
end

newSection("homeframe")
newSection("gameFrame")
newSection("gamelistFrame")
newSection("settingsFrame")
newSection("creditsFrame")

--------------------------------------------------------------
-- FOOTER (STATUS, FPS, PING, CLOCK)
--------------------------------------------------------------
local footer = Instance.new("Frame")
footer.Name = "footer"
footer.AnchorPoint = Vector2.new(0.5, 1)
footer.Size = UDim2.new(1, -24, 0, 32)
footer.Position = UDim2.new(0.5, 0, 1, -8)
footer.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
footer.BorderSizePixel = 0
footer.ClipsDescendants = true
footer.ZIndex = 401
footer.Parent = MainFrame

corner(footer, 6)
stroke(footer, 2, BLACK_OUT)

footer.Size = UDim2.new(0, 0, 0, 32)
tw(footer, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{Size = UDim2.new(1, -24, 0, 32)})

-- Green Radar Dot
local dot = Instance.new("Frame")
dot.Name = "dot"
dot.AnchorPoint = Vector2.new(0, 0.5)
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 10, 0.5, 0)
dot.BackgroundColor3 = Color3.fromRGB(0, 230, 100)
dot.BorderSizePixel = 0
dot.ZIndex = 403
dot.Parent = footer
corner(dot, 999)

task.spawn(function()
	while dot.Parent do
		tw(dot, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.6})
		task.wait(1.15)
		tw(dot, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0})
		task.wait(1.15)
	end
end)

local fnote = Instance.new("TextLabel")
fnote.Name = "fnote"
fnote.AnchorPoint = Vector2.new(0, 0.5)
fnote.Size = UDim2.new(0, 300, 1, 0)
fnote.Position = UDim2.new(0, 24, 0.5, 0)
fnote.BackgroundTransparency = 1
fnote.Text = "Loaded Hub - by loaded"
fnote.TextColor3 = LIGHT_GRAY
fnote.TextSize = 13
fnote.Font = F_SUB
fnote.TextXAlignment = Enum.TextXAlignment.Left
fnote.ZIndex = 403
fnote.Parent = footer
textStroke(fnote, 1.5, BLACK_OUT)

local function readout(offset, w, txt)
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(1, 0.5)
	l.Size = UDim2.new(0, w, 1, 0)
	l.Position = UDim2.new(1, -offset, 0.5, 0)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = LIGHT_GRAY
	l.TextSize = 13
	l.Font = F_SUB
	l.TextXAlignment = Enum.TextXAlignment.Right
	l.ZIndex = 403
	l.Parent = footer
	textStroke(l, 1.5, BLACK_OUT)

	local pipe = Instance.new("Frame")
	pipe.AnchorPoint = Vector2.new(1, 0.5)
	pipe.Size = UDim2.new(0, 1, 0, 12)
	pipe.Position = UDim2.new(1, -offset - w - 6, 0.5, 0)
	pipe.BackgroundColor3 = BLACK_OUT
	pipe.BorderSizePixel = 0
	pipe.ZIndex = 403
	pipe.Parent = footer

	return l
end

local clock = readout(10, 50, "--:--")
local ping  = readout(72, 60, "-- ms")
local fps   = readout(144, 60, "-- fps")

task.spawn(function()
	local frames = 0
	local last = os.clock()
	local conn
	conn = runservice.Heartbeat:Connect(function()
		frames = frames + 1
		local now = os.clock()
		if now - last >= 1 then
			if not fps.Parent then
				conn:Disconnect()
				return
			end
			local n = math.floor(frames / (now - last) + 0.5)
			fps.Text = n .. " fps"
			fps.TextColor3 = n >= 45 and Color3.fromRGB(120, 230, 100)
				or (n >= 25 and Color3.fromRGB(250, 180, 50)
				or Color3.fromRGB(250, 80, 80))
			frames = 0
			last = now
		end
	end)
end)

task.spawn(function()
	local stats = game:GetService("Stats")
	while ping.Parent do
		local ms
		pcall(function()
			ms = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		if ms then
			ping.Text = ms .. " ms"
			ping.TextColor3 = ms < 120 and Color3.fromRGB(120, 230, 100)
				or (ms < 260 and Color3.fromRGB(250, 180, 50)
				or Color3.fromRGB(250, 80, 80))
		else
			ping.Text = "-- ms"
		end
		clock.Text = os.date("%H:%M")
		task.wait(2)
	end
end)

-- Busy Loading Rail
do
	local rail = Instance.new("Frame")
	rail.Name = "rail"
	rail.AnchorPoint = Vector2.new(0.5, 1)
	rail.Size = UDim2.new(1, -24, 0, 3)
	rail.Position = UDim2.new(0.5, 0, 1, -2)
	rail.BackgroundColor3 = BLACK_OUT
	rail.BackgroundTransparency = 1
	rail.BorderSizePixel = 0
	rail.ClipsDescendants = true
	rail.ZIndex = 402
	rail.Parent = MainFrame
	corner(rail, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.3, 0, 1, 0)
	fill.Position = UDim2.new(-0.3, 0, 0, 0)
	fill.BackgroundColor3 = BLUE_TOP
	fill.BorderSizePixel = 0
	fill.ZIndex = 403
	fill.Parent = rail
	corner(fill, 999)

	local busy = false
	task.spawn(function()
		while rail.Parent do
			if busy then
				fill.Position = UDim2.new(-0.3, 0, 0, 0)
				tw(fill, TweenInfo.new(0.95, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{Position = UDim2.new(1, 0, 0, 0)})
				task.wait(1)
			else
				task.wait(0.25)
			end
		end
	end)

	ui:SetAttribute("busy", false)
	ui:GetAttributeChangedSignal("busy"):Connect(function()
		busy = ui:GetAttribute("busy") == true
		tw(rail, SMOOTH, {BackgroundTransparency = busy and 0.4 or 1})
		tw(fill, SMOOTH, {BackgroundTransparency = busy and 0 or 1})
	end)
end

--------------------------------------------------------------
-- HOME LABELS
--------------------------------------------------------------
local home = SectionContainers.homeframe
local function homeLabel(name, text, col, size, order)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = UDim2.new(1, -10, 0, 24)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = col
	l.TextSize = size
	l.Font = F_STUD
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.LayoutOrder = order
	l.ZIndex = 404
	l.Parent = home
	textStroke(l, 2, BLACK_OUT)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.Parent = l

	return l
end

local head = homeLabel("ythead", "LOADED HUB", WHITE, 26, 1)
homeLabel("welcomeLabel", "Open the Game tab for active game options.", LIGHT_GRAY, 15, 2)

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -16, 0, 2)
sep.BackgroundColor3 = BLACK_OUT
sep.BorderSizePixel = 0
sep.LayoutOrder = 3
sep.ZIndex = 403
sep.Parent = home

homeLabel("execLabel",    "Executor: ...", WHITE, 15, 4)
homeLabel("versionLabel", "Version: ...",  WHITE, 15, 5)
homeLabel("placeLabel",   "PlaceId: ...",  WHITE, 15, 6)

local sep2 = sep:Clone()
sep2.LayoutOrder = 7
sep2.Parent = home

homeLabel("discan",    "Discord: redacted", BLUE_TOP, 15, 8)
homeLabel("bugsLabel", "Bugs? Report them at redacted", MUTED_GRAY, 14, 9)

task.spawn(function()
	for _, l in ipairs(home:GetChildren()) do
		if l:IsA("TextLabel") then
			local keep = l.TextTransparency
			l.TextTransparency = 1
			task.wait(0.045)
			tw(l, TweenInfo.new(0.3), {TextTransparency = keep})
		end
	end
end)

--------------------------------------------------------------
return ui
