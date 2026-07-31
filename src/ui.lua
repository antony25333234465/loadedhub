--// ui.lua
--// v5 - rebuilt to match the studio model 1:1. no more studs.
--// pulled the colors straight off a screenshot of the original so
--// they are the real ones, not something i eyeballed
--// node names are the ones main.lua expects:
--//   togglebtn, Frame, TopBar, sectionContainers, tablist,
--//   hidebtn, closebtn, HomeTab, gameFrame, ...

local tweenservice = game:GetService("TweenService")

--------------------------------------------------------------
-- theme
-- BODY 79,75,164   the big lilac panels
-- BAR  52,49,105   topbar and every border
-- EDGE 39,37,79    the dark outline around the whole thing
--------------------------------------------------------------
local BODY   = Color3.fromRGB(79, 75, 164)
local BAR    = Color3.fromRGB(52, 49, 105)
local EDGE   = Color3.fromRGB(39, 37, 79)

local HOVER  = Color3.fromRGB(92, 88, 180)   -- body a bit lighter
local SEL    = Color3.fromRGB(99, 94, 190)   -- the active tab
local BOX    = Color3.fromRGB(68, 64, 142)   -- sunken bits, textboxes

local WHITE  = Color3.fromRGB(255, 255, 255)
local GRAY   = Color3.fromRGB(196, 193, 224)
local DIM    = Color3.fromRGB(150, 146, 192)

local GREEN  = Color3.fromRGB(126, 217, 87)
local ORANGE = Color3.fromRGB(255, 176, 46)
local RED    = Color3.fromRGB(226, 82, 82)
local GOLD   = Color3.fromRGB(255, 205, 74)

-- the model uses a serif, closest one roblox ships is this
local F  = Enum.Font.Merriweather
local F2 = Enum.Font.SourceSansSemibold

local SMOOTH = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BOUNCE = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

--------------------------------------------------------------
-- helpers
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
	c.CornerRadius = UDim.new(0, rad)
	c.Parent = p
	return c
end

-- every panel in the model has the same 3px bar-colored outline
local function stroke(p, th, col)
	local s = Instance.new("UIStroke")
	s.Thickness = th or 3
	s.Color = col or BAR
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

--------------------------------------------------------------
-- flat button. no studs, no sinking, just a tint on hover
--------------------------------------------------------------
local function button(parent, size, pos, color, text, txtSize, z, txtCol)
	-- keeping the holder a TextButton so ui.togglebtn and
	-- Topbar.hidebtn are the clickable node themselves
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color
	b.AutoButtonColor = false
	b.Text = text
	b.TextColor3 = txtCol or WHITE
	b.TextSize = txtSize
	b.Font = F
	b.BorderSizePixel = 0
	b.ZIndex = z
	b.Parent = parent
	corner(b, 8)
	stroke(b, 3)

	b.MouseEnter:Connect(function()
		tw(b, SMOOTH, {BackgroundColor3 = lighten(color, 1.16)})
	end)
	b.MouseLeave:Connect(function()
		tw(b, SMOOTH, {BackgroundColor3 = color})
	end)
	b.MouseButton1Down:Connect(function()
		tw(b, TweenInfo.new(0.07), {BackgroundColor3 = lighten(color, 0.86)})
	end)
	b.MouseButton1Up:Connect(function()
		tw(b, SMOOTH, {BackgroundColor3 = lighten(color, 1.16)})
	end)

	return b
end

--------------------------------------------------------------
-- ROOT
--------------------------------------------------------------
local ui = Instance.new("ScreenGui")
ui.Name = "\0BrainrotHub"
ui.ResetOnSpawn = false
ui.IgnoreGuiInset = true
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.DisplayOrder = 9999

--------------------------------------------------------------
-- togglebtn
--------------------------------------------------------------
local togglebtn = button(ui, UDim2.new(0, 152, 0, 40),
	UDim2.new(0.5, -76, 0.03, 0), BAR, "Show UI", 17, 600)
togglebtn.Name = "togglebtn"
togglebtn.Visible = false

--------------------------------------------------------------
-- Frame
-- model is 782x477 so im keeping that
--------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Frame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 782, 0, 477)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = BAR
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 400
MainFrame.Parent = ui
corner(MainFrame, 14)

-- the dark ring around everything
local outer = Instance.new("UIStroke")
outer.Thickness = 3
outer.Color = EDGE
outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
outer.Parent = MainFrame

local scMain = Instance.new("UIScale")
scMain.Scale = 0.92
scMain.Parent = MainFrame
tw(scMain, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

--------------------------------------------------------------
-- TopBar   (74px tall in the model)
--------------------------------------------------------------
local Topbar = Instance.new("Frame")
Topbar.Name = "TopBar"
Topbar.Size = UDim2.new(1, 0, 0, 74)
Topbar.BackgroundColor3 = BAR
Topbar.BorderSizePixel = 0
Topbar.ZIndex = 401
Topbar.Parent = MainFrame

-- the badge on the left
local badge = Instance.new("Frame")
badge.Name = "badge"
badge.AnchorPoint = Vector2.new(0, 0.5)
badge.Size = UDim2.new(0, 44, 0, 46)
badge.Position = UDim2.new(0, 18, 0.5, 0)
badge.BackgroundColor3 = Color3.fromRGB(63, 59, 124)
badge.BorderSizePixel = 0
badge.ZIndex = 403
badge.Parent = Topbar
corner(badge, 10)
stroke(badge, 2, Color3.fromRGB(120, 115, 190))

local badgeTxt = Instance.new("TextLabel")
badgeTxt.Size = UDim2.new(1, 0, 1, 0)
badgeTxt.BackgroundTransparency = 1
badgeTxt.Text = "BH"
badgeTxt.TextColor3 = Color3.fromRGB(178, 172, 232)
badgeTxt.TextSize = 15
badgeTxt.Font = F
badgeTxt.ZIndex = 404
badgeTxt.Parent = badge

-- in the model the right side is plain text, not a boxed button
local hidebtn = Instance.new("TextButton")
hidebtn.Name = "hidebtn"
hidebtn.AnchorPoint = Vector2.new(1, 0.5)
hidebtn.Size = UDim2.new(0, 130, 0, 40)
hidebtn.Position = UDim2.new(1, -22, 0.5, 0)
hidebtn.BackgroundTransparency = 1
hidebtn.AutoButtonColor = false
hidebtn.Text = "Hide UI"
hidebtn.TextColor3 = WHITE
hidebtn.TextSize = 25
hidebtn.Font = F
hidebtn.TextXAlignment = Enum.TextXAlignment.Right
hidebtn.ZIndex = 404
hidebtn.Parent = Topbar

hidebtn.MouseEnter:Connect(function()
	tw(hidebtn, SMOOTH, {TextColor3 = Color3.fromRGB(190, 185, 240)})
end)
hidebtn.MouseLeave:Connect(function()
	tw(hidebtn, SMOOTH, {TextColor3 = WHITE})
end)

-- the model has no X, but main.lua wants one. tucking it next to
-- Hide UI, same flat look so it doesnt clash
local closebtn = Instance.new("TextButton")
closebtn.Name = "closebtn"
closebtn.AnchorPoint = Vector2.new(1, 0.5)
closebtn.Size = UDim2.new(0, 34, 0, 34)
closebtn.Position = UDim2.new(1, -166, 0.5, 0)
closebtn.BackgroundTransparency = 1
closebtn.AutoButtonColor = false
closebtn.Text = "X"
closebtn.TextColor3 = Color3.fromRGB(198, 192, 236)
closebtn.TextSize = 20
closebtn.Font = F
closebtn.ZIndex = 404
closebtn.Parent = Topbar

closebtn.MouseEnter:Connect(function()
	tw(closebtn, SMOOTH, {TextColor3 = RED})
end)
closebtn.MouseLeave:Connect(function()
	tw(closebtn, SMOOTH, {TextColor3 = Color3.fromRGB(198, 192, 236)})
end)

--------------------------------------------------------------
-- tablist   (x 12..248 of the frame, 236 wide)
--------------------------------------------------------------
local TabList = Instance.new("Frame")
TabList.Name = "tablist"
TabList.Size = UDim2.new(0, 236, 1, -100)
TabList.Position = UDim2.new(0, 12, 0, 87)
TabList.BackgroundColor3 = BODY
TabList.BorderSizePixel = 0
TabList.ZIndex = 401
TabList.Parent = MainFrame
corner(TabList, 12)
stroke(TabList, 3)

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 6)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = TabList

local tabPad = Instance.new("UIPadding")
tabPad.PaddingTop = UDim.new(0, 14)
tabPad.PaddingLeft = UDim.new(0, 10)
tabPad.PaddingRight = UDim.new(0, 10)
tabPad.Parent = TabList

-- little vector icon per tab, drawn with frames. beats hunting
-- down 5 asset ids and it matches the outline look of the model
local function icon(parent, kind)
	local box = Instance.new("Frame")
	box.Name = "icon"
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.Size = UDim2.new(0, 26, 0, 26)
	box.Position = UDim2.new(0, 8, 0.5, 0)
	box.BackgroundTransparency = 1
	box.ZIndex = 406
	box.Parent = parent

	local function piece(w, h, x, y, rad, rot)
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

	if kind == "Home" then
		piece(15, 2, 0, -6, 1, 45).Position = UDim2.new(0.5, -5, 0.5, -6)
		piece(15, 2, 5, -6, 1, -45)
		piece(2, 11, -7, 3, 1)
		piece(2, 11, 7, 3, 1)
		piece(16, 2, 0, 8, 1)
	elseif kind == "Game" then
		local pad = piece(22, 13, 0, 1, 5)
		pad.BackgroundTransparency = 1
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = WHITE
		s.Parent = pad
		piece(6, 2, -5, 1, 1)
		piece(2, 6, -5, 1, 1)
		piece(3, 3, 5, 1, 999)
	elseif kind == "Gameslist" then
		local bx = piece(20, 18, 0, 0, 4)
		bx.BackgroundTransparency = 1
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = WHITE
		s.Parent = bx
		for i = -1, 1 do
			piece(2, 2, -5, i * 5, 999)
			piece(8, 2, 2, i * 5, 1)
		end
	elseif kind == "Settings" then
		local ring = piece(18, 18, 0, 0, 999)
		ring.BackgroundTransparency = 1
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Color = WHITE
		s.Parent = ring
		for i = 0, 3 do
			piece(4, 4, 0, 0, 1, i * 45).Position =
				UDim2.new(0.5, math.floor(math.cos(i * math.pi / 4) * 10),
				          0.5, math.floor(math.sin(i * math.pi / 4) * 10))
		end
	elseif kind == "Credits" then
		local cup = piece(14, 12, 0, -3, 3)
		cup.BackgroundTransparency = 1
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = WHITE
		s.Parent = cup
		piece(2, 6, 0, 5, 1)
		piece(10, 2, 0, 9, 1)
		piece(4, 2, -8, -4, 1, 30)
		piece(4, 2, 8, -4, 1, -30)
	end

	return box
end

local function newTab(name, label, order)
	local b = Instance.new("TextButton")
	b.Name = name .. "Tab"
	b.Size = UDim2.new(1, 0, 0, 52)
	b.BackgroundColor3 = SEL
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.Text = ""
	b.BorderSizePixel = 0
	b.LayoutOrder = order
	b.ZIndex = 404
	b.Parent = TabList
	corner(b, 8)

	-- main.lua looks for a child called InnerShadow and pokes
	-- BackgroundTransparency on it for the hover
	local ish = Instance.new("Frame")
	ish.Name = "InnerShadow"
	ish.Size = UDim2.new(1, 0, 1, 0)
	ish.BackgroundColor3 = WHITE
	ish.BackgroundTransparency = 1
	ish.BorderSizePixel = 0
	ish.ZIndex = 405
	ish.Parent = b
	corner(ish, 8)

	icon(b, name)

	local t = Instance.new("TextLabel")
	t.Name = "label"
	t.Size = UDim2.new(1, -44, 1, 0)
	t.Position = UDim2.new(0, 42, 0, 0)
	t.BackgroundTransparency = 1
	t.Text = label
	t.TextColor3 = WHITE
	t.TextSize = 22
	t.Font = F
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 406
	t.Parent = b

	-- main.lua only flips BackgroundTransparency, everything else
	-- rides along from here
	b:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		local on = b.BackgroundTransparency < 0.5
		tw(t, SMOOTH, {TextColor3 = on and WHITE or GRAY})
	end)

	return b
end

newTab("Home",      "Home",       1)
newTab("Game",      "Game",       2)
newTab("Gameslist", "Games List", 3)
newTab("Settings",  "Settings",   4)
newTab("Credits",   "Credits",    5)

--------------------------------------------------------------
-- sectionContainers   (the big panel on the right)
--------------------------------------------------------------
local SectionContainers = Instance.new("Frame")
SectionContainers.Name = "sectionContainers"
SectionContainers.Size = UDim2.new(1, -272, 1, -100)
SectionContainers.Position = UDim2.new(0, 260, 0, 87)
SectionContainers.BackgroundColor3 = BODY
SectionContainers.BorderSizePixel = 0
SectionContainers.ClipsDescendants = true
SectionContainers.ZIndex = 401
SectionContainers.Parent = MainFrame
corner(SectionContainers, 12)
stroke(SectionContainers, 3)

local function newSection(name)
	local f = Instance.new("ScrollingFrame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Size = UDim2.new(1, -16, 1, -14)
	f.Position = UDim2.new(0.5, 0, 1, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.ScrollBarThickness = 4
	f.ScrollBarImageColor3 = Color3.fromRGB(140, 134, 214)
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
-- home labels
-- main.lua gsubs "redacted" on these, so they must exist
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
	l.Font = F2
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.LayoutOrder = order
	l.ZIndex = 404
	l.Parent = home

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.Parent = l
	return l
end

local head = homeLabel("ythead", "brainrot hub", WHITE, 24, 1)
head.Font = F

homeLabel("welcomeLabel", "open the Game tab for the current game options.", GRAY, 15, 2)

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -16, 0, 2)
sep.BackgroundColor3 = BAR
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

homeLabel("discan",    "discord: redacted", Color3.fromRGB(178, 172, 232), 15, 8)
homeLabel("bugsLabel", "bugs? report them at redacted", GRAY, 14, 9)

--------------------------------------------------------------
return ui
