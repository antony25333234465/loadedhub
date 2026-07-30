--// ui.lua
--// builds the whole gui and returns the ScreenGui.
--// this is what replaces import("rbxassetid://...")
--// node names are the ones main.lua expects:
--//   togglebtn, Frame, TopBar, sectionContainers, tablist,
--//   hidebtn, closebtn, HomeTab, gameFrame, ...

local tweenservice = game:GetService("TweenService")

--------------------------------------------------------------
-- theme
--------------------------------------------------------------
local BG      = Color3.fromRGB(37, 30, 54)
local BG2     = Color3.fromRGB(28, 22, 42)
local BAR     = Color3.fromRGB(50, 40, 74)
local BOX     = Color3.fromRGB(46, 37, 68)
local EDGE    = Color3.fromRGB(18, 14, 28)

local PURPLE  = Color3.fromRGB(157, 122, 232)
local LILAC   = Color3.fromRGB(186, 158, 245)
local RED     = Color3.fromRGB(203, 82, 66)
local WHITE   = Color3.fromRGB(240, 236, 250)
local GRAY    = Color3.fromRGB(168, 158, 192)
local DIM     = Color3.fromRGB(120, 110, 146)

local F  = Enum.Font.FredokaOne
local F2 = Enum.Font.SourceSansSemibold

local STUDS = "rbxassetid://117006067003358"

local SMOOTH = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BOUNCE = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SNAP   = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--------------------------------------------------------------
-- helpers
--------------------------------------------------------------
local function tw(o, i, p)
	local t = tweenservice:Create(o, i, p)
	t:Play()
	return t
end

local function darken(c, f) return Color3.new(c.R * f, c.G * f, c.B * f) end
local function lighten(c, f)
	return Color3.new(math.min(c.R * f, 1), math.min(c.G * f, 1), math.min(c.B * f, 1))
end

local function corner(p, rad)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, rad)
	c.Parent = p
	return c
end

local function stroke(p, gr, col)
	local s = Instance.new("UIStroke")
	s.Thickness = gr or 2
	s.Color = col or EDGE
	s.Parent = p
	return s
end

-- HEADS UP: dont call this on a frame with a UIListLayout,
-- the image would count as a list item and push everything out
local function studs(p, transp, rad)
	local i = Instance.new("ImageLabel")
	i.Name = "studs"
	i.Size = UDim2.new(1, 0, 1, 0)
	i.BackgroundTransparency = 1
	i.Image = STUDS
	i.ImageTransparency = transp or 0.85
	i.ScaleType = Enum.ScaleType.Tile
	i.TileSize = UDim2.new(0, 52, 0, 52)
	i.Active = false -- otherwise this eats the clicks
	i.ZIndex = p.ZIndex
	i.Parent = p
	corner(i, rad or 8)
	return i
end

-- for the ones with a layout: texture goes as a sibling behind it
local function studsBehind(p, transp, rad)
	local i = Instance.new("ImageLabel")
	i.Name = p.Name .. "_studs"
	i.Size = p.Size
	i.Position = p.Position
	i.AnchorPoint = p.AnchorPoint
	i.BackgroundTransparency = 1
	i.Image = STUDS
	i.ImageTransparency = transp or 0.85
	i.ScaleType = Enum.ScaleType.Tile
	i.TileSize = UDim2.new(0, 52, 0, 52)
	i.Active = false
	i.ZIndex = p.ZIndex
	i.Parent = p.Parent
	corner(i, rad or 8)

	p:GetPropertyChangedSignal("Size"):Connect(function() i.Size = p.Size end)
	p:GetPropertyChangedSignal("Position"):Connect(function() i.Position = p.Position end)
	p:GetPropertyChangedSignal("Visible"):Connect(function() i.Visible = p.Visible end)
	return i
end

--------------------------------------------------------------
-- 3d button
--------------------------------------------------------------
local SINK = 5

local function animate(btn, face, base, lbl, baseCol)
	local sc = Instance.new("UIScale")
	sc.Parent = face

	local scT = Instance.new("UIScale")
	scT.Parent = lbl

	face.ClipsDescendants = true

	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(0, 26, 2, 0)
	shine.Position = UDim2.new(0, -50, -0.5, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 1
	shine.BorderSizePixel = 0
	shine.Rotation = 17
	shine.ZIndex = face.ZIndex + 2
	shine.Parent = face

	local pressed = false

	btn.MouseEnter:Connect(function()
		if pressed then return end
		tw(face, SMOOTH, {BackgroundColor3 = lighten(baseCol, 1.13)})
		tw(sc, SMOOTH, {Scale = 1.022})
	end)

	btn.MouseLeave:Connect(function()
		tw(face, SMOOTH, {BackgroundColor3 = baseCol})
		tw(sc, SMOOTH, {Scale = 1})
		if pressed then
			pressed = false
			tw(face, BOUNCE, {Position = UDim2.new(0, 0, 0, 0)})
		end
	end)

	btn.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1
		and i.UserInputType ~= Enum.UserInputType.Touch then return end
		if pressed then return end
		pressed = true
		tw(face, SNAP, {Position = UDim2.new(0, 0, 0, SINK)})
		tw(sc, SNAP, {Scale = 0.965})
		tw(scT, SNAP, {Scale = 0.93})

		local ax, ay = face.AbsolutePosition.X, face.AbsolutePosition.Y
		local rp = Instance.new("Frame")
		rp.AnchorPoint = Vector2.new(0.5, 0.5)
		rp.Position = UDim2.new(0, i.Position.X - ax, 0, i.Position.Y - ay)
		rp.Size = UDim2.new(0, 0, 0, 0)
		rp.BackgroundColor3 = Color3.new(1, 1, 1)
		rp.BackgroundTransparency = 0.55
		rp.BorderSizePixel = 0
		rp.ZIndex = face.ZIndex + 1
		rp.Parent = face
		corner(rp, 999)

		local big = math.max(face.AbsoluteSize.X, face.AbsoluteSize.Y) * 2.3
		tw(rp, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, big, 0, big),
			BackgroundTransparency = 1,
		})
		task.delay(0.5, function() rp:Destroy() end)
	end)

	btn.InputEnded:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1
		and i.UserInputType ~= Enum.UserInputType.Touch then return end
		if not pressed then return end
		pressed = false
		tw(face, BOUNCE, {Position = UDim2.new(0, 0, 0, 0)})
		tw(sc, BOUNCE, {Scale = 1})
		tw(scT, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Scale = 1})

		shine.Position = UDim2.new(0, -50, -0.5, 0)
		shine.BackgroundTransparency = 0.62
		tw(shine, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, 40, -0.5, 0),
			BackgroundTransparency = 1,
		})
	end)
end

local function button(parent, size, pos, color, text, txtSize, z, txtCol)
	-- the holder is a TextButton, not a Frame. that way the node you
	-- name is the one that gets clicked, and ui.togglebtn /
	-- Topbar.hidebtn resolve straight to something with MouseButton1Click
	local h = Instance.new("TextButton")
	h.Size = size
	h.Position = pos
	h.BackgroundTransparency = 1
	h.Text = ""
	h.AutoButtonColor = false
	h.ZIndex = z
	h.Parent = parent

	local base = Instance.new("Frame")
	base.Size = UDim2.new(1, 0, 1, 0)
	base.BackgroundColor3 = darken(color, 0.6)
	base.BorderSizePixel = 0
	base.ZIndex = z
	base.Parent = h
	corner(base, 9)
	stroke(base, 2)

	-- the face is just visual now, it must not eat the clicks
	local face = Instance.new("Frame")
	face.Size = UDim2.new(1, 0, 1, -SINK)
	face.BackgroundColor3 = color
	face.BorderSizePixel = 0
	face.ZIndex = z + 1
	face.Parent = h
	corner(face, 9)
	stroke(face, 2)
	studs(face, 0.87, 9)

	-- little shine on top so it looks like plastic
	local br = Instance.new("Frame")
	br.Size = UDim2.new(1, -9, 0, 3)
	br.Position = UDim2.new(0, 5, 0, 4)
	br.BackgroundColor3 = Color3.new(1, 1, 1)
	br.BackgroundTransparency = 0.8
	br.BorderSizePixel = 0
	br.ZIndex = z + 3
	br.Parent = face
	corner(br, 2)

	local t = Instance.new("TextLabel")
	t.Name = "TextLabel"
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = txtCol or WHITE
	t.TextSize = txtSize
	t.Font = F
	t.ZIndex = z + 4
	t.Parent = face

	animate(h, face, base, t, color)
	return h
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
-- main.lua does ui.togglebtn and connects MouseButton1Click, so this
-- node has to be a direct child of ui and be clickable. button()
-- returns the TextButton itself now, so it just works
local togglebtn = button(ui, UDim2.new(0, 168, 0, 44),
	UDim2.new(0.5, -84, 0.03, 0), PURPLE, "brainrot hub", 17, 600)
togglebtn.Name = "togglebtn"
togglebtn.Visible = false

--------------------------------------------------------------
-- Frame
--------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Frame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 522, 0, 396)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = BG
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 400
MainFrame.Parent = ui

corner(MainFrame, 12)
stroke(MainFrame, 3)

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(196, 182, 226)),
})
grad.Rotation = 90
grad.Parent = MainFrame

studs(MainFrame, 0.86, 12)

local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 14, 1, 14)
shadow.Position = UDim2.new(0, -7, 0, -3)
shadow.BackgroundColor3 = Color3.fromRGB(12, 8, 22)
shadow.BackgroundTransparency = 0.62
shadow.BorderSizePixel = 0
shadow.ZIndex = 399
shadow.Parent = MainFrame
corner(shadow, 15)

local scMain = Instance.new("UIScale")
scMain.Scale = 0.9
scMain.Parent = MainFrame
tw(scMain, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

--------------------------------------------------------------
-- TopBar
--------------------------------------------------------------
local Topbar = Instance.new("Frame")
Topbar.Name = "TopBar"
Topbar.Size = UDim2.new(1, 0, 0, 48)
Topbar.BackgroundColor3 = BAR
Topbar.BorderSizePixel = 0
Topbar.ZIndex = 401
Topbar.Parent = MainFrame
corner(Topbar, 12)
studs(Topbar, 0.81, 12)

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 3)
topLine.Position = UDim2.new(0, 0, 1, -3)
topLine.BackgroundColor3 = EDGE
topLine.BorderSizePixel = 0
topLine.ZIndex = 403
topLine.Parent = Topbar

local title = Instance.new("TextLabel")
title.Name = "title"
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0, 15, 0, 1)
title.BackgroundTransparency = 1
title.Text = "brainrot hub"
title.TextColor3 = LILAC
title.TextSize = 21
title.Font = F
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 404
title.Parent = Topbar
stroke(title, 2)

local hidebtn = button(Topbar, UDim2.new(0, 36, 0, 32), UDim2.new(1, -86, 0.5, -16),
	BOX, "-", 22, 404)
hidebtn.Name = "hidebtn"

local closebtn = button(Topbar, UDim2.new(0, 36, 0, 32), UDim2.new(1, -44, 0.5, -16),
	RED, "X", 18, 404, Color3.fromRGB(255, 243, 238))
closebtn.Name = "closebtn"

--------------------------------------------------------------
-- tablist
--------------------------------------------------------------
local TabList = Instance.new("Frame")
TabList.Name = "tablist"
TabList.Size = UDim2.new(0, 118, 1, -58)
TabList.Position = UDim2.new(0, 8, 0, 54)
TabList.BackgroundColor3 = BG2
TabList.BorderSizePixel = 0
TabList.ZIndex = 401
TabList.Parent = MainFrame
corner(TabList, 10)
stroke(TabList, 2)
studsBehind(TabList, 0.9, 10)

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 5)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = TabList

local tabPad = Instance.new("UIPadding")
tabPad.PaddingTop = UDim.new(0, 6)
tabPad.PaddingLeft = UDim.new(0, 6)
tabPad.PaddingRight = UDim.new(0, 6)
tabPad.Parent = TabList

local function newTab(name, order)
	local b = Instance.new("TextButton")
	b.Name = name .. "Tab"
	b.Size = UDim2.new(1, 0, 0, 34)
	b.BackgroundColor3 = BOX
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.Text = name
	b.TextColor3 = DIM
	b.TextSize = 15
	b.Font = F
	b.BorderSizePixel = 0
	b.LayoutOrder = order
	b.ZIndex = 404
	b.Parent = TabList
	corner(b, 7)
	stroke(b, 2, EDGE)

	local ish = Instance.new("Frame")
	ish.Name = "InnerShadow"
	ish.Size = UDim2.new(1, 0, 1, 0)
	ish.BackgroundColor3 = Color3.new(1, 1, 1)
	ish.BackgroundTransparency = 1
	ish.BorderSizePixel = 0
	ish.ZIndex = 405
	ish.Parent = b
	corner(ish, 7)

	-- the lilac bar on the active one. main.lua only touches
	-- BackgroundTransparency, so i drive the rest from here
	local mark = Instance.new("Frame")
	mark.Name = "mark"
	mark.AnchorPoint = Vector2.new(0, 0.5)
	mark.Size = UDim2.new(0, 3, 0, 0)
	mark.Position = UDim2.new(0, 3, 0.5, 0)
	mark.BackgroundColor3 = LILAC
	mark.BorderSizePixel = 0
	mark.ZIndex = 406
	mark.Parent = b
	corner(mark, 999)

	b:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		local on = b.BackgroundTransparency < 0.5
		tw(b, SMOOTH, {TextColor3 = on and WHITE or DIM})
		tw(mark, on
			and TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			or SMOOTH,
			{Size = UDim2.new(0, 3, 0, on and 20 or 0)})
	end)

	return b
end

newTab("Home", 1)
newTab("Game", 2)
newTab("Gameslist", 3)
newTab("Settings", 4)
newTab("Credits", 5)

--------------------------------------------------------------
-- sectionContainers
--------------------------------------------------------------
local SectionContainers = Instance.new("Frame")
SectionContainers.Name = "sectionContainers"
SectionContainers.Size = UDim2.new(1, -142, 1, -58)
SectionContainers.Position = UDim2.new(0, 134, 0, 54)
SectionContainers.BackgroundColor3 = BG2
SectionContainers.BorderSizePixel = 0
SectionContainers.ClipsDescendants = true
SectionContainers.ZIndex = 401
SectionContainers.Parent = MainFrame
corner(SectionContainers, 10)
stroke(SectionContainers, 2)
studs(SectionContainers, 0.9, 10)

local function newSection(name)
	local f = Instance.new("ScrollingFrame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Size = UDim2.new(1, -12, 1, -12)
	f.Position = UDim2.new(0.5, 0, 1, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.ScrollBarThickness = 3
	f.ScrollBarImageColor3 = PURPLE
	f.CanvasSize = UDim2.new(0, 0, 0, 0)
	f.AutomaticCanvasSize = Enum.AutomaticSize.Y
	f.Visible = false
	f.ZIndex = 402
	f.Parent = SectionContainers

	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 7)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = f

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
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
	l.Size = UDim2.new(1, -8, 0, 22)
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
	pad.PaddingLeft = UDim.new(0, 8)
	pad.Parent = l
	return l
end

local head = homeLabel("ythead", "brainrot hub", LILAC, 20, 1)
head.Font = F

homeLabel("welcomeLabel", "open the Game tab for the current game options.", GRAY, 14, 2)

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -14, 0, 2)
sep.BackgroundColor3 = EDGE
sep.BackgroundTransparency = 0.4
sep.BorderSizePixel = 0
sep.LayoutOrder = 3
sep.ZIndex = 403
sep.Parent = home

homeLabel("execLabel",    "Executor: ...", WHITE, 14, 4)
homeLabel("versionLabel", "Version: ...",  WHITE, 14, 5)
homeLabel("placeLabel",   "PlaceId: ...",  WHITE, 14, 6)

local sep2 = sep:Clone()
sep2.LayoutOrder = 7
sep2.Parent = home

homeLabel("discan",    "discord: redacted", LILAC, 14, 8)
homeLabel("bugsLabel", "bugs? report them at redacted", GRAY, 13, 9)

--------------------------------------------------------------
return ui
