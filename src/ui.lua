--// ui.lua
--// v6 - LH rebrand, animated backdrop, footer w/ fps.
--// spent way too long on the drifting shapes, the trick was
--// clipping them on the main frame and keeping them at zindex 400
--// so they never fight the panels for draw order.
--// v5 was the flat rebuild, v4 was the studs one (rip)
--//
--// nodes main.lua reaches for:
--//   togglebtn, Frame, TopBar, sectionContainers, tablist,
--//   hidebtn, closebtn, HomeTab..CreditsTab, homeframe..creditsFrame

local tweenservice = game:GetService("TweenService")
local runservice   = game:GetService("RunService")

--------------------------------------------------------------
-- theme. pulled off a screenshot of the studio model so these
-- are the real values, not something i eyeballed
--------------------------------------------------------------
local BODY   = Color3.fromRGB(79, 75, 164)   -- the big panels
local BAR    = Color3.fromRGB(52, 49, 105)   -- topbar + every border
local EDGE   = Color3.fromRGB(39, 37, 79)    -- outline round the whole thing

local DEEP = Color3.fromRGB(79, 75, 164)    -- backdrop, a hair off BAR
local HOVER  = Color3.fromRGB(92, 88, 180)
local SEL    = Color3.fromRGB(103, 98, 196)
local BOX    = Color3.fromRGB(68, 64, 142)

local WHITE  = Color3.fromRGB(255, 255, 255)
local GRAY   = Color3.fromRGB(196, 193, 224)
local DIM    = Color3.fromRGB(150, 146, 192)
local LILAC  = Color3.fromRGB(178, 172, 232)

local GREEN  = Color3.fromRGB(126, 217, 87)
local RED    = Color3.fromRGB(226, 82, 82)

local F  = Enum.Font.Merriweather
local F2 = Enum.Font.SourceSansSemibold

local SMOOTH = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GLIDE  = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local BOUNCE = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SNAP   = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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

local function stroke(p, th, col)
	local s = Instance.new("UIStroke")
	s.Thickness = th or 3
	s.Color = col or BAR
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local rng = Random.new(os.time() % 99991)

--------------------------------------------------------------
-- animated backdrop
-- diamonds floating up + a gradient that never sits still.
-- everything here is Active=false or it starts eating clicks
--------------------------------------------------------------
local function backdrop(parent)
	local bg = Instance.new("Frame")
	bg.Name = "backdrop"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = DEEP
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true
	bg.Active = false
	bg.ZIndex = 400
	bg.Parent = parent

	-- slow colour wash. rotation would snap back at 360 so i just
	-- swing it there and back instead of looping it round
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(58, 54, 118)),
		ColorSequenceKeypoint.new(0.47, Color3.fromRGB(44, 41, 90)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(66, 61, 132)),
	})
	g.Rotation = 25
	g.Parent = bg

	task.spawn(function()
		while bg.Parent do
			tw(g, TweenInfo.new(9.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Rotation = 205})
			task.wait(9.4)
			if not bg.Parent then return end
			tw(g, TweenInfo.new(9.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Rotation = 25})
			task.wait(9.4)
		end
	end)

	----------------------------------------------------------
	-- layer 1: the two fat blobs, so the corners arent dead flat
	----------------------------------------------------------
	for i = 1, 2 do
		local blob = Instance.new("Frame")
		blob.Name = "blob" .. i
		blob.AnchorPoint = Vector2.new(0.5, 0.5)
		blob.Size = UDim2.new(0, 290, 0, 290)
		blob.Position = UDim2.new(i == 1 and 0.18 or 0.86, 0, i == 1 and 0.24 or 0.78, 0)
		blob.BackgroundColor3 = i == 1
			and Color3.fromRGB(96, 88, 196)
			or Color3.fromRGB(72, 66, 152)
		blob.BackgroundTransparency = 0.87
		blob.BorderSizePixel = 0
		blob.Active = false
		blob.ZIndex = 400
		blob.Parent = bg
		corner(blob, 999)

		local bs = Instance.new("UIScale")
		bs.Parent = blob

		task.spawn(function()
			local up = true
			while blob.Parent do
				local dx = rng:NextNumber(-0.07, 0.07)
				local dy = up and -0.09 or 0.09
				up = not up
				tw(blob, TweenInfo.new(7.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Position = UDim2.new(
						math.clamp(blob.Position.X.Scale + dx, 0.05, 0.95), 0,
						math.clamp(blob.Position.Y.Scale + dy, 0.05, 0.95), 0),
				})
				-- breathe on a different clock than the drift, otherwise
				-- the two line up and it looks mechanical
				tw(bs, TweenInfo.new(5.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Scale = up and 1.12 or 0.92})
				task.wait(7.7)
			end
		end)
	end

	----------------------------------------------------------
	-- layer 2: grid of dots that fades in and out in patches
	----------------------------------------------------------
	do
		local grid = Instance.new("Frame")
		grid.Name = "grid"
		grid.Size = UDim2.new(1, 0, 1, 0)
		grid.BackgroundTransparency = 1
		grid.Active = false
		grid.ZIndex = 400
		grid.Parent = bg

		local dots = {}
		local cols, rows = 13, 8
		for cx = 0, cols - 1 do
			for cy = 0, rows - 1 do
				local p = Instance.new("Frame")
				p.AnchorPoint = Vector2.new(0.5, 0.5)
				p.Size = UDim2.new(0, 3, 0, 3)
				p.Position = UDim2.new((cx + 0.5) / cols, 0, (cy + 0.5) / rows, 0)
				p.BackgroundColor3 = Color3.fromRGB(150, 142, 226)
				p.BackgroundTransparency = 0.93
				p.BorderSizePixel = 0
				p.Active = false
				p.ZIndex = 400
				p.Parent = grid
				corner(p, 999)
				dots[#dots + 1] = p
			end
		end

		-- light up a random patch, let it fade, pick another spot
		task.spawn(function()
			while grid.Parent do
				local hx = rng:NextNumber(0, 1)
				local hy = rng:NextNumber(0, 1)
				for _, p in ipairs(dots) do
					local dx = p.Position.X.Scale - hx
					local dy = p.Position.Y.Scale - hy
					local dist = math.sqrt(dx * dx + dy * dy)
					if dist < 0.29 then
						local near = 1 - (dist / 0.29)
						tw(p, TweenInfo.new(1.4, Enum.EasingStyle.Sine),
							{BackgroundTransparency = 0.93 - near * 0.55})
					end
				end
				task.wait(1.6)
				for _, p in ipairs(dots) do
					tw(p, TweenInfo.new(2.1, Enum.EasingStyle.Sine),
						{BackgroundTransparency = 0.93})
				end
				task.wait(rng:NextNumber(1.9, 3.4))
			end
		end)
	end

	----------------------------------------------------------
	-- layer 3: streaks that slide across on a diagonal
	----------------------------------------------------------
	for i = 1, 4 do
		local ln = Instance.new("Frame")
		ln.Name = "streak"
		ln.AnchorPoint = Vector2.new(0.5, 0.5)
		ln.Size = UDim2.new(0, 2, 0, 150)
		ln.BackgroundColor3 = Color3.fromRGB(158, 150, 235)
		ln.BackgroundTransparency = 1
		ln.BorderSizePixel = 0
		ln.Rotation = 24
		ln.Active = false
		ln.ZIndex = 400
		ln.Parent = bg

		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		grad.Parent = ln

		task.spawn(function()
			task.wait(rng:NextNumber(0, 9))
			while ln.Parent do
				local y = rng:NextNumber(0.08, 0.92)
				local dur = rng:NextNumber(2.6, 4.4)
				ln.Position = UDim2.new(-0.12, 0, y, 0)
				ln.Size = UDim2.new(0, rng:NextInteger(2, 3), 0, rng:NextInteger(110, 210))
				ln.BackgroundTransparency = rng:NextNumber(0.55, 0.75)
				tw(ln, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Position = UDim2.new(1.12, 0, y - 0.14, 0)})
				task.wait(dur - 0.5)
				if not ln.Parent then return end
				tw(ln, TweenInfo.new(0.5), {BackgroundTransparency = 1})
				task.wait(rng:NextNumber(3.5, 9.5))
			end
		end)
	end

	----------------------------------------------------------
	-- layer 4: the diamonds. 11 felt right, 20 was noisy
	----------------------------------------------------------
	for i = 1, 11 do
		local d = Instance.new("Frame")
		d.Name = "shard"
		d.AnchorPoint = Vector2.new(0.5, 0.5)
		d.BackgroundColor3 = i % 3 == 0
			and Color3.fromRGB(126, 118, 224)
			or Color3.fromRGB(98, 92, 190)
		d.BorderSizePixel = 0
		d.Rotation = 45
		d.Active = false
		d.ZIndex = 400
		d.Parent = bg
		corner(d, 3)

		task.spawn(function()
			-- stagger or they all launch on the same frame and it
			-- reads as a wave instead of drifting
			task.wait(rng:NextNumber(0, 6.5))
			while d.Parent do
				local size = rng:NextInteger(9, 27)
				local x    = rng:NextNumber(0.03, 0.97)
				local dur  = rng:NextNumber(11.5, 23)
				local spin = rng:NextNumber(-140, 140)
				local sway = rng:NextNumber(-0.11, 0.11)

				d.Size = UDim2.new(0, size, 0, size)
				d.Position = UDim2.new(x, 0, 1.15, 0)
				d.Rotation = rng:NextNumber(0, 90)
				d.BackgroundTransparency = 1

				tw(d, TweenInfo.new(1.6), {BackgroundTransparency = rng:NextNumber(0.72, 0.9)})
				-- two hops instead of one straight line so it wobbles
				tw(d, TweenInfo.new(dur * 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Position = UDim2.new(x + sway, 0, 0.55, 0),
					Rotation = d.Rotation + spin * 0.5,
				})
				task.wait(dur * 0.5)
				if not d.Parent then return end
				tw(d, TweenInfo.new(dur * 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Position = UDim2.new(x - sway, 0, -0.2, 0),
					Rotation = d.Rotation + spin,
				})
				task.wait(dur * 0.5 - 1.7)
				if not d.Parent then return end
				tw(d, TweenInfo.new(1.6), {BackgroundTransparency = 1})
				task.wait(1.8)
			end
		end)
	end

	----------------------------------------------------------
	-- layer 5: vignette so the middle reads brighter than the edges
	----------------------------------------------------------
	do
		local vig = Instance.new("Frame")
		vig.Name = "vignette"
		vig.Size = UDim2.new(1, 0, 1, 0)
		vig.BackgroundColor3 = Color3.fromRGB(24, 21, 52)
		vig.BackgroundTransparency = 0.72
		vig.BorderSizePixel = 0
		vig.Active = false
		vig.ZIndex = 400
		vig.Parent = bg

		local vg = Instance.new("UIGradient")
		vg.Rotation = 90
		vg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(0.45, 1),
			NumberSequenceKeypoint.new(1, 0.35),
		})
		vg.Parent = vig
	end

	return bg
end

--------------------------------------------------------------
-- flat button. tint on hover, darken on press, ripple. no studs
--------------------------------------------------------------
local function button(parent, size, pos, color, text, txtSize, z, txtCol)
	-- holder IS the TextButton so ui.togglebtn / Topbar.hidebtn
	-- land on something with MouseButton1Click
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
	b.ClipsDescendants = true
	b.ZIndex = z
	b.Parent = parent
	corner(b, 8)
	stroke(b, 3)

	local sc = Instance.new("UIScale")
	sc.Parent = b

	b.MouseEnter:Connect(function()
		tw(b, SMOOTH, {BackgroundColor3 = lighten(color, 1.16)})
		tw(sc, SMOOTH, {Scale = 1.03})
	end)
	b.MouseLeave:Connect(function()
		tw(b, SMOOTH, {BackgroundColor3 = color})
		tw(sc, SMOOTH, {Scale = 1})
	end)
	b.MouseButton1Down:Connect(function()
		tw(b, SNAP, {BackgroundColor3 = lighten(color, 0.86)})
		tw(sc, SNAP, {Scale = 0.97})
	end)
	b.MouseButton1Up:Connect(function()
		tw(b, SMOOTH, {BackgroundColor3 = lighten(color, 1.16)})
		tw(sc, BOUNCE, {Scale = 1.03})
	end)

	return b
end

--------------------------------------------------------------
-- ROOT
--------------------------------------------------------------
local ui = Instance.new("ScreenGui")
ui.Name = "\0LoadedHub"
ui.ResetOnSpawn = false
ui.IgnoreGuiInset = true
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.DisplayOrder = 9999

--------------------------------------------------------------
-- togglebtn
--------------------------------------------------------------
local togglebtn = button(ui, UDim2.new(0, 168, 0, 42),
	UDim2.new(0.5, -84, 0.03, 0), BAR, "loaded hub", 18, 600)
togglebtn.Name = "togglebtn"
togglebtn.Visible = false

-- breathes a bit while its sitting there so you notice it
task.spawn(function()
	local s = togglebtn:FindFirstChildOfClass("UIScale")
	while togglebtn.Parent do
		if togglebtn.Visible then
			tw(s, TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Scale = 1.035})
			task.wait(1.4)
			tw(s, TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Scale = 1})
			task.wait(1.4)
		else
			task.wait(0.5)
		end
	end
end)

--------------------------------------------------------------
-- Frame
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

local outer = Instance.new("UIStroke")
outer.Thickness = 3
outer.Color = EDGE
outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
outer.Parent = MainFrame

backdrop(MainFrame)

local scMain = Instance.new("UIScale")
scMain.Scale = 0.9
scMain.Parent = MainFrame
tw(scMain, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

--------------------------------------------------------------
-- TopBar
--------------------------------------------------------------
local Topbar = Instance.new("Frame")
Topbar.Name = "TopBar"
Topbar.Size = UDim2.new(1, 0, 0, 74)
Topbar.BackgroundColor3 = BAR
Topbar.BackgroundTransparency = 0.08
Topbar.BorderSizePixel = 0
Topbar.ClipsDescendants = true
Topbar.ZIndex = 401
Topbar.Parent = MainFrame

-- a sheen that crosses the bar every so often
do
	local sheen = Instance.new("Frame")
	sheen.Name = "sheen"
	sheen.Size = UDim2.new(0, 90, 2, 0)
	sheen.Position = UDim2.new(0, -140, -0.5, 0)
	sheen.BackgroundColor3 = WHITE
	sheen.BackgroundTransparency = 0.94
	sheen.BorderSizePixel = 0
	sheen.Rotation = 14
	sheen.Active = false
	sheen.ZIndex = 402
	sheen.Parent = Topbar

	task.spawn(function()
		while sheen.Parent do
			task.wait(rng:NextNumber(4.5, 8))
			sheen.Position = UDim2.new(0, -140, -0.5, 0)
			tw(sheen, TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Position = UDim2.new(1, 160, -0.5, 0)})
		end
	end)
end

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 2)
topLine.Position = UDim2.new(0, 0, 1, -2)
topLine.BackgroundColor3 = EDGE
topLine.BackgroundTransparency = 0.35
topLine.BorderSizePixel = 0
topLine.ZIndex = 403
topLine.Parent = Topbar

-- badge
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
stroke(badge, 2, Color3.fromRGB(124, 118, 196))

local badgeTxt = Instance.new("TextLabel")
badgeTxt.Name = "lh"
badgeTxt.Size = UDim2.new(1, 0, 1, 0)
badgeTxt.BackgroundTransparency = 1
badgeTxt.Text = "LH"
badgeTxt.TextColor3 = LILAC
badgeTxt.TextSize = 17
badgeTxt.Font = F
badgeTxt.ZIndex = 404
badgeTxt.Parent = badge

do
	local br = Instance.new("UIScale")
	br.Parent = badge
	task.spawn(function()
		while badge.Parent do
			tw(br, TweenInfo.new(2.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Scale = 1.055})
			task.wait(2.2)
			tw(br, TweenInfo.new(2.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Scale = 1})
			task.wait(2.2)
		end
	end)
end

local title = Instance.new("TextLabel")
title.Name = "title"
title.AnchorPoint = Vector2.new(0, 0.5)
title.Size = UDim2.new(0, 260, 0, 32)
title.Position = UDim2.new(0, 74, 0.5, -7)
title.BackgroundTransparency = 1
title.Text = "loaded hub"
title.TextColor3 = WHITE
title.TextSize = 25
title.Font = F
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 404
title.Parent = Topbar

local sub = Instance.new("TextLabel")
sub.Name = "sub"
sub.AnchorPoint = Vector2.new(0, 0.5)
sub.Size = UDim2.new(0, 260, 0, 16)
sub.Position = UDim2.new(0, 76, 0.5, 14)
sub.BackgroundTransparency = 1
sub.Text = "brainrot tools"
sub.TextColor3 = Color3.fromRGB(146, 140, 198)
sub.TextSize = 13
sub.Font = F2
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.ZIndex = 404
sub.Parent = Topbar

local hidebtn = Instance.new("TextButton")
hidebtn.Name = "hidebtn"
hidebtn.AnchorPoint = Vector2.new(1, 0.5)
hidebtn.Size = UDim2.new(0, 122, 0, 40)
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

-- little underline that wipes in from the right
local hu = Instance.new("Frame")
hu.AnchorPoint = Vector2.new(1, 0)
hu.Size = UDim2.new(0, 0, 0, 2)
hu.Position = UDim2.new(1, 0, 1, -6)
hu.BackgroundColor3 = LILAC
hu.BorderSizePixel = 0
hu.ZIndex = 405
hu.Parent = hidebtn
corner(hu, 999)

hidebtn.MouseEnter:Connect(function()
	tw(hidebtn, SMOOTH, {TextColor3 = LILAC})
	tw(hu, GLIDE, {Size = UDim2.new(0, 88, 0, 2)})
end)
hidebtn.MouseLeave:Connect(function()
	tw(hidebtn, SMOOTH, {TextColor3 = WHITE})
	tw(hu, SMOOTH, {Size = UDim2.new(0, 0, 0, 2)})
end)

-- model has no X but main.lua wants one
local closebtn = Instance.new("TextButton")
closebtn.Name = "closebtn"
closebtn.AnchorPoint = Vector2.new(1, 0.5)
closebtn.Size = UDim2.new(0, 34, 0, 34)
closebtn.Position = UDim2.new(1, -158, 0.5, 0)
closebtn.BackgroundColor3 = RED
closebtn.BackgroundTransparency = 1
closebtn.AutoButtonColor = false
closebtn.Text = "X"
closebtn.TextColor3 = Color3.fromRGB(190, 184, 232)
closebtn.TextSize = 19
closebtn.Font = F
closebtn.ZIndex = 404
closebtn.Parent = Topbar
corner(closebtn, 8)

closebtn.MouseEnter:Connect(function()
	tw(closebtn, SMOOTH, {TextColor3 = WHITE, BackgroundTransparency = 0.25})
end)
closebtn.MouseLeave:Connect(function()
	tw(closebtn, SMOOTH, {
		TextColor3 = Color3.fromRGB(190, 184, 232),
		BackgroundTransparency = 1,
	})
end)

--------------------------------------------------------------
-- tablist
--------------------------------------------------------------
local TabList = Instance.new("Frame")
TabList.Name = "tablist"
TabList.Size = UDim2.new(0, 236, 1, -138)
TabList.Position = UDim2.new(0, 12, 0, 87)
TabList.BackgroundColor3 = BODY
TabList.BackgroundTransparency = 0.06
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
tabPad.PaddingTop = UDim.new(0, 13)
tabPad.PaddingLeft = UDim.new(0, 10)
tabPad.PaddingRight = UDim.new(0, 10)
tabPad.Parent = TabList

-- icons drawn out of frames. beats tracking down 5 asset ids and
-- it matches the outline look of the model
local function icon(parent, kind)
	local box = Instance.new("Frame")
	box.Name = "icon"
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.Size = UDim2.new(0, 26, 0, 26)
	box.Position = UDim2.new(0, 9, 0.5, 0)
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
		bit(15, 2, -5, -6, 1, 45)
		bit(15, 2, 5, -6, 1, -45)
		bit(2, 11, -7, 3, 1)
		bit(2, 11, 7, 3, 1)
		bit(16, 2, 0, 8, 1)
	elseif kind == "Game" then
		outline(22, 14, 0, 1, 6)
		bit(7, 2, -5, 1, 1)
		bit(2, 7, -5, 1, 1)
		bit(3, 3, 4, -1, 999)
		bit(3, 3, 7, 3, 999)
	elseif kind == "Gameslist" then
		outline(21, 19, 0, 0, 4)
		for i = -1, 1 do
			bit(3, 3, -5, i * 5, 999)
			bit(8, 2, 3, i * 5, 1)
		end
	elseif kind == "Settings" then
		outline(17, 17, 0, 0, 999, 3)
		for i = 0, 5 do
			local a = i * math.pi / 3
			bit(5, 5, math.floor(math.cos(a) * 11), math.floor(math.sin(a) * 11), 1,
				math.deg(a))
		end
	elseif kind == "Credits" then
		outline(15, 13, 0, -3, 3)
		bit(2, 6, 0, 6, 1)
		bit(11, 2, 0, 10, 1)
		bit(5, 2, -9, -4, 1, 32)
		bit(5, 2, 9, -4, 1, -32)
	end

	return box
end

local function newTab(name, label, order)
	local b = Instance.new("TextButton")
	b.Name = name .. "Tab"
	b.Size = UDim2.new(1, 0, 0, 52)
	-- same colour as the panel behind it. main.lua flips this to
	-- transparency 0 with no tween, so if it were a bright colour
	-- youd see it pop. the visible highlight is the hl frame
	b.BackgroundColor3 = BODY
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.Text = ""
	b.BorderSizePixel = 0
	b.ClipsDescendants = true
	b.LayoutOrder = order
	b.ZIndex = 404
	b.Parent = TabList
	corner(b, 8)

	local hl = Instance.new("Frame")
	hl.Name = "hl"
	hl.Size = UDim2.new(1, 0, 1, 0)
	hl.BackgroundColor3 = SEL
	hl.BackgroundTransparency = 1
	hl.BorderSizePixel = 0
	hl.ZIndex = 404
	hl.Parent = b
	corner(hl, 8)

	-- main.lua pokes BackgroundTransparency on a child named
	-- InnerShadow for the hover, so it has to exist
	local ish = Instance.new("Frame")
	ish.Name = "InnerShadow"
	ish.Size = UDim2.new(1, 0, 1, 0)
	ish.BackgroundColor3 = WHITE
	ish.BackgroundTransparency = 1
	ish.BorderSizePixel = 0
	ish.ZIndex = 405
	ish.Parent = b
	corner(ish, 8)

	-- the bar that slides in on the left of the active one
	local mark = Instance.new("Frame")
	mark.Name = "mark"
	mark.AnchorPoint = Vector2.new(0, 0.5)
	mark.Size = UDim2.new(0, 3, 0, 0)
	mark.Position = UDim2.new(0, 3, 0.5, 0)
	mark.BackgroundColor3 = LILAC
	mark.BorderSizePixel = 0
	mark.ZIndex = 407
	mark.Parent = b
	corner(mark, 999)

	local ic = icon(b, name)
	local icScale = Instance.new("UIScale")
	icScale.Parent = ic

	local t = Instance.new("TextLabel")
	t.Name = "label"
	t.Size = UDim2.new(1, -46, 1, 0)
	t.Position = UDim2.new(0, 44, 0, 0)
	t.BackgroundTransparency = 1
	t.Text = label
	t.TextColor3 = GRAY
	t.TextSize = 22
	t.Font = F
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 406
	t.Parent = b

	local active = false

	b.MouseEnter:Connect(function()
		if not active then
			tw(hl, SMOOTH, {BackgroundTransparency = 0.75})
			tw(t, SMOOTH, {TextColor3 = WHITE})
		end
		tw(icScale, BOUNCE, {Scale = 1.14})
		tw(t, GLIDE, {Position = UDim2.new(0, 48, 0, 0)})
	end)

	b.MouseLeave:Connect(function()
		if not active then
			tw(hl, SMOOTH, {BackgroundTransparency = 1})
			tw(t, SMOOTH, {TextColor3 = GRAY})
		end
		tw(icScale, SMOOTH, {Scale = 1})
		tw(t, GLIDE, {Position = UDim2.new(0, 44, 0, 0)})
	end)

	-- main.lua only touches BackgroundTransparency, so everything
	-- else rides along off this signal
	b:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		active = b.BackgroundTransparency < 0.5
		tw(hl, GLIDE, {BackgroundTransparency = active and 0 or 1})
		tw(t, SMOOTH, {TextColor3 = active and WHITE or GRAY})
		tw(mark, active and BOUNCE or SMOOTH,
			{Size = UDim2.new(0, 3, 0, active and 22 or 0)})
		if active then
			icScale.Scale = 0.8
			tw(icScale, TweenInfo.new(0.42, Enum.EasingStyle.Back,
				Enum.EasingDirection.Out), {Scale = 1})
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
-- sectionContainers
--------------------------------------------------------------
local SectionContainers = Instance.new("Frame")
SectionContainers.Name = "sectionContainers"
SectionContainers.Size = UDim2.new(1, -272, 1, -138)
SectionContainers.Position = UDim2.new(0, 260, 0, 87)
SectionContainers.BackgroundColor3 = BODY
SectionContainers.BackgroundTransparency = 0.06
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
-- footer. status dot, live fps, ping and a clock.
-- the strip along the very bottom is a loading bar that only
-- shows up when something is actually fetching
--------------------------------------------------------------
local footer = Instance.new("Frame")
footer.Name = "footer"
footer.AnchorPoint = Vector2.new(0.5, 1)
footer.Size = UDim2.new(1, -24, 0, 32)
footer.Position = UDim2.new(0.5, 0, 1, -8)
footer.BackgroundColor3 = BAR
footer.BackgroundTransparency = 0.22
footer.BorderSizePixel = 0
footer.ClipsDescendants = true
footer.ZIndex = 401
footer.Parent = MainFrame
corner(footer, 8)

-- the bar wipes in from the left on open
footer.Size = UDim2.new(0, 0, 0, 32)
tw(footer, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{Size = UDim2.new(1, -24, 0, 32)})

local dot = Instance.new("Frame")
dot.Name = "dot"
dot.AnchorPoint = Vector2.new(0, 0.5)
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 12, 0.5, 0)
dot.BackgroundColor3 = GREEN
dot.BorderSizePixel = 0
dot.ZIndex = 403
dot.Parent = footer
corner(dot, 999)

-- ring that pings out of the dot, like a radar blip
task.spawn(function()
	while dot.Parent do
		local r = Instance.new("Frame")
		r.AnchorPoint = Vector2.new(0.5, 0.5)
		r.Size = UDim2.new(0, 8, 0, 8)
		r.Position = UDim2.new(0.5, 0, 0.5, 0)
		r.BackgroundTransparency = 1
		r.BorderSizePixel = 0
		r.ZIndex = 402
		r.Parent = dot
		corner(r, 999)
		local rs = Instance.new("UIStroke")
		rs.Thickness = 1
		rs.Color = GREEN
		rs.Transparency = 0.35
		rs.Parent = r

		tw(r, TweenInfo.new(1.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 26, 0, 26)})
		tw(rs, TweenInfo.new(1.7), {Transparency = 1})
		task.delay(1.8, function() r:Destroy() end)
		task.wait(2.3)
	end
end)

task.spawn(function()
	while dot.Parent do
		tw(dot, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{BackgroundTransparency = 0.62})
		task.wait(1.15)
		tw(dot, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{BackgroundTransparency = 0})
		task.wait(1.15)
	end
end)

local fnote = Instance.new("TextLabel")
fnote.Name = "fnote"
fnote.AnchorPoint = Vector2.new(0, 0.5)
fnote.Size = UDim2.new(0, 300, 1, 0)
fnote.Position = UDim2.new(0, 26, 0.5, 0)
fnote.BackgroundTransparency = 1
fnote.Text = "Made by loaded credits to the ui library owner"
fnote.TextColor3 = Color3.fromRGB(160, 154, 208)
fnote.TextSize = 13
fnote.Font = F2
fnote.TextXAlignment = Enum.TextXAlignment.Left
fnote.ZIndex = 403
fnote.Parent = footer

-- little readout on the right. one label per stat with a thin
-- divider between them
local function readout(offset, w, txt)
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(1, 0.5)
	l.Size = UDim2.new(0, w, 1, 0)
	l.Position = UDim2.new(1, -offset, 0.5, 0)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = Color3.fromRGB(160, 154, 208)
	l.TextSize = 13
	l.Font = F2
	l.TextXAlignment = Enum.TextXAlignment.Right
	l.ZIndex = 403
	l.Parent = footer

	local pipe = Instance.new("Frame")
	pipe.AnchorPoint = Vector2.new(1, 0.5)
	pipe.Size = UDim2.new(0, 1, 0, 12)
	pipe.Position = UDim2.new(1, -offset - w - 7, 0.5, 0)
	pipe.BackgroundColor3 = Color3.fromRGB(104, 98, 158)
	pipe.BackgroundTransparency = 0.45
	pipe.BorderSizePixel = 0
	pipe.ZIndex = 403
	pipe.Parent = footer

	return l
end

local clock = readout(12, 52, "--:--")
local ping  = readout(78, 62, "-- ms")
local fps   = readout(154, 62, "-- fps")

-- counting frames over a whole second. 1/dt jumps around way
-- too much to read
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
			fps.TextColor3 = n >= 45 and Color3.fromRGB(150, 200, 130)
				or (n >= 25 and Color3.fromRGB(214, 178, 108)
				or Color3.fromRGB(210, 120, 110))
			frames = 0
			last = now
		end
	end)
end)

-- ping + clock. both cheap, 2s apart is plenty
task.spawn(function()
	local stats = game:GetService("Stats")
	while ping.Parent do
		local ms
		pcall(function()
			ms = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		if ms then
			ping.Text = ms .. " ms"
			ping.TextColor3 = ms < 120 and Color3.fromRGB(150, 200, 130)
				or (ms < 260 and Color3.fromRGB(214, 178, 108)
				or Color3.fromRGB(210, 120, 110))
		else
			ping.Text = "-- ms"
		end
		clock.Text = os.date("%H:%M")
		task.wait(2)
	end
end)

-- thin strip glued to the bottom edge. hidden until something
-- calls ui:SetBusy(true), then it slides back and forth
do
	local rail = Instance.new("Frame")
	rail.Name = "rail"
	rail.AnchorPoint = Vector2.new(0.5, 1)
	rail.Size = UDim2.new(1, -24, 0, 3)
	rail.Position = UDim2.new(0.5, 0, 1, -3)
	rail.BackgroundColor3 = Color3.fromRGB(38, 35, 76)
	rail.BackgroundTransparency = 1
	rail.BorderSizePixel = 0
	rail.ClipsDescendants = true
	rail.ZIndex = 402
	rail.Parent = MainFrame
	corner(rail, 999)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.3, 0, 1, 0)
	fill.Position = UDim2.new(-0.3, 0, 0, 0)
	fill.BackgroundColor3 = LILAC
	fill.BorderSizePixel = 0
	fill.ZIndex = 403
	fill.Parent = rail
	corner(fill, 999)

	local busy = false

	task.spawn(function()
		while rail.Parent do
			if busy then
				fill.Position = UDim2.new(-0.3, 0, 0, 0)
				tw(fill, TweenInfo.new(0.95, Enum.EasingStyle.Quad,
					Enum.EasingDirection.InOut), {Position = UDim2.new(1, 0, 0, 0)})
				task.wait(1)
			else
				task.wait(0.25)
			end
		end
	end)

	-- exposed so main.lua can flip it while it fetches
	ui:SetAttribute("busy", false)
	ui:GetAttributeChangedSignal("busy"):Connect(function()
		busy = ui:GetAttribute("busy") == true
		tw(rail, SMOOTH, {BackgroundTransparency = busy and 0.4 or 1})
		tw(fill, SMOOTH, {BackgroundTransparency = busy and 0 or 1})
	end)
end

--------------------------------------------------------------
-- home labels. main.lua gsubs "redacted" on these so they must exist
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

local head = homeLabel("ythead", "loaded hub", WHITE, 26, 1)
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

homeLabel("discan",    "discord: redacted", LILAC, 15, 8)
homeLabel("bugsLabel", "bugs? report them at redacted", GRAY, 14, 9)

-- fade the home rows in one after another, looks nicer than
-- everything appearing at once
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
