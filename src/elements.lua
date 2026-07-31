--// elements.lua
--// same api as the original: Label, Button, Toggle, Textbox,
--// Unsupported, addGame, Searchbar, CredHead, CredPerson
--// plus Header, Stat, Divider and Notify

local tweenservice     = game:GetService("TweenService")
local players          = game:GetService("Players")
local plr              = players.LocalPlayer

local stuff = {}

--------------------------------------------------------------
-- theme  (same values as ui.lua)
--------------------------------------------------------------
local BG2     = Color3.fromRGB(28, 22, 42)
local BOX     = Color3.fromRGB(46, 37, 68)
local EDGE    = Color3.fromRGB(18, 14, 28)

local PURPLE  = Color3.fromRGB(157, 122, 232)
local LILAC   = Color3.fromRGB(186, 158, 245)
local GREEN   = Color3.fromRGB(124, 190, 84)
local ORANGE  = Color3.fromRGB(228, 158, 56)
local RED     = Color3.fromRGB(203, 82, 66)
local WHITE   = Color3.fromRGB(240, 236, 250)
local GRAY    = Color3.fromRGB(168, 158, 192)
local DIM     = Color3.fromRGB(120, 110, 146)
local GOLD    = Color3.fromRGB(238, 196, 92)

local TG_ON   = Color3.fromRGB(138, 96, 224)
local TG_OFF  = Color3.fromRGB(58, 47, 82)

local F  = Enum.Font.FredokaOne
local F2 = Enum.Font.SourceSansSemibold

local STUDS = "rbxassetid://117006067003358"

local SMOOTH = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BOUNCE = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SNAP   = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SND_CLICK = "rbxassetid://6042053626"
local SND_TOAST = "rbxassetid://4590662766"

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

local sndCache
local function play(id, vol)
	if getgenv and getgenv().hubSounds == false then return end
	pcall(function()
		if not sndCache then
			sndCache = Instance.new("Folder")
			sndCache.Name = "hub_snd"
			sndCache.Parent = plr:FindFirstChildOfClass("PlayerGui")
		end
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = vol or 0.4
		s.PlayOnRemove = true
		s.Parent = sndCache
		s:Destroy()
	end)
end

local function colOf(kind)
	if kind == "ok"   then return GREEN  end
	if kind == "warn" then return ORANGE end
	if kind == "err"  then return RED    end
	if kind == "loot" then return PURPLE end
	return PURPLE
end

--------------------------------------------------------------
-- 3d button
--------------------------------------------------------------
local SINK = 5

local function makeButton(parent, size, pos, color, text, txtSize, z, txtCol)
	local h = Instance.new("Frame")
	h.Size = size
	h.Position = pos
	h.BackgroundTransparency = 1
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

	local face = Instance.new("TextButton")
	face.Size = UDim2.new(1, 0, 1, -SINK)
	face.BackgroundColor3 = color
	face.AutoButtonColor = false
	face.Text = ""
	face.BorderSizePixel = 0
	face.ClipsDescendants = true
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

	local lbl = Instance.new("TextLabel")
	lbl.Name = "TextLabel"
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = txtCol or WHITE
	lbl.TextSize = txtSize
	lbl.Font = F
	lbl.ZIndex = z + 4
	lbl.Parent = face

	local sc = Instance.new("UIScale")
	sc.Parent = face
	local scT = Instance.new("UIScale")
	scT.Parent = lbl

	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(0, 26, 2, 0)
	shine.Position = UDim2.new(0, -50, -0.5, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 1
	shine.BorderSizePixel = 0
	shine.Rotation = 17
	shine.ZIndex = z + 2
	shine.Parent = face

	local pressed = false

	face.MouseEnter:Connect(function()
		if pressed then return end
		tw(face, SMOOTH, {BackgroundColor3 = lighten(color, 1.13)})
		tw(sc, SMOOTH, {Scale = 1.022})
	end)

	face.MouseLeave:Connect(function()
		tw(face, SMOOTH, {BackgroundColor3 = color})
		tw(sc, SMOOTH, {Scale = 1})
		if pressed then
			pressed = false
			tw(face, BOUNCE, {Position = UDim2.new(0, 0, 0, 0)})
		end
	end)

	face.InputBegan:Connect(function(i)
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
		rp.ZIndex = z + 2
		rp.Parent = face
		corner(rp, 999)

		local big = math.max(face.AbsoluteSize.X, face.AbsoluteSize.Y) * 2.3
		tw(rp, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, big, 0, big),
			BackgroundTransparency = 1,
		})
		task.delay(0.5, function() rp:Destroy() end)
	end)

	face.InputEnded:Connect(function(i)
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
		play(SND_CLICK, 0.4)
	end)

	return face, h
end

--------------------------------------------------------------
-- NOTIFY  (toasts)
--------------------------------------------------------------
local T_W, T_H, T_GAP = 268, 62, 9
local toasts = {}
local toastRoot

-- restacks them bottom to top every time one comes or goes
local function restack()
	local y = -14
	for i = #toasts, 1, -1 do
		local t = toasts[i]
		if t and t.Parent then
			tw(t, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.new(1, -14, 1, y)
			})
			y = y - (T_H + T_GAP)
		end
	end
end

function stuff:Notify(title, text, kind, dur)
	if not toastRoot then
		-- hang them off whatever screen gui we can reach
		local hui = gethui or get_hidden_gui
		local ok = pcall(function()
			toastRoot = (hui and hui() or game:GetService("CoreGui")):FindFirstChild("\0BrainrotHub")
		end)
		if not ok or not toastRoot then
			toastRoot = plr:FindFirstChildOfClass("PlayerGui")
		end
	end
	if not toastRoot then return end

	local col = colOf(kind)
	dur = dur or 3

	-- if there are too many kill the oldest, else the screen fills up
	if #toasts >= 4 then
		local v = toasts[1]
		if v and v:FindFirstChild("closer") then v.closer:Destroy() end
	end

	local t = Instance.new("Frame")
	t.Name = "toast"
	t.AnchorPoint = Vector2.new(1, 1)
	t.Size = UDim2.new(0, T_W, 0, T_H)
	t.Position = UDim2.new(1, 320, 1, -14)
	t.BackgroundColor3 = BOX
	t.BorderSizePixel = 0
	t.ClipsDescendants = true
	t.ZIndex = 900
	t.Parent = toastRoot
	corner(t, 9)
	stroke(t, 2)
	studs(t, 0.87, 9)

	local sh = Instance.new("Frame")
	sh.Size = UDim2.new(1, 8, 1, 8)
	sh.Position = UDim2.new(0, -4, 0, -1)
	sh.BackgroundColor3 = Color3.new(0, 0, 0)
	sh.BackgroundTransparency = 0.74
	sh.BorderSizePixel = 0
	sh.ZIndex = 899
	sh.Parent = t
	corner(sh, 11)

	local sc = Instance.new("UIScale")
	sc.Scale = 0.9
	sc.Parent = t

	local acc = Instance.new("Frame")
	acc.Size = UDim2.new(0, 5, 1, -10)
	acc.Position = UDim2.new(0, 5, 0, 5)
	acc.BackgroundColor3 = col
	acc.BorderSizePixel = 0
	acc.ZIndex = 903
	acc.Parent = t
	corner(acc, 3)

	local tit = Instance.new("TextLabel")
	tit.Size = UDim2.new(1, -60, 0, 20)
	tit.Position = UDim2.new(0, 17, 0, 8)
	tit.BackgroundTransparency = 1
	tit.Text = title
	tit.TextColor3 = col
	tit.TextSize = 17
	tit.Font = F
	tit.TextXAlignment = Enum.TextXAlignment.Left
	tit.ZIndex = 903
	tit.Parent = t

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -60, 0, 22)
	body.Position = UDim2.new(0, 17, 0, 27)
	body.BackgroundTransparency = 1
	body.Text = text or ""
	body.TextColor3 = GRAY
	body.TextSize = 14
	body.Font = F2
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.ZIndex = 903
	body.Parent = t

	local x = Instance.new("TextButton")
	x.Name = "closer"
	x.Size = UDim2.new(0, 20, 0, 20)
	x.Position = UDim2.new(1, -26, 0, 6)
	x.BackgroundTransparency = 1
	x.Text = "x"
	x.TextColor3 = DIM
	x.TextSize = 16
	x.Font = F
	x.ZIndex = 904
	x.Parent = t

	local dr = Instance.new("Frame")
	dr.Size = UDim2.new(1, -10, 0, 3)
	dr.Position = UDim2.new(0, 5, 1, -7)
	dr.BackgroundColor3 = col
	dr.BackgroundTransparency = 0.35
	dr.BorderSizePixel = 0
	dr.ZIndex = 903
	dr.Parent = t
	corner(dr, 2)

	table.insert(toasts, t)
	restack()

	tw(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
	tw(dr, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)})
	play(SND_TOAST, 0.35)

	task.spawn(function()
		task.wait(0.12)
		tw(acc, TweenInfo.new(0.18), {BackgroundColor3 = lighten(col, 1.5)})
		task.wait(0.2)
		tw(acc, TweenInfo.new(0.3), {BackgroundColor3 = col})
	end)

	local dead = false
	local function kill()
		if dead then return end
		dead = true
		for i, v in ipairs(toasts) do
			if v == t then table.remove(toasts, i) break end
		end
		tw(sc, TweenInfo.new(0.2), {Scale = 0.92})
		local leave = tw(t, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 330, t.Position.Y.Scale, t.Position.Y.Offset)
		})
		restack()
		leave.Completed:Connect(function() t:Destroy() end)
	end

	x.MouseButton1Click:Connect(kill)
	x.Destroying:Connect(kill)

	local hovering = false
	t.MouseEnter:Connect(function() hovering = true end)
	t.MouseLeave:Connect(function() hovering = false end)

	task.delay(dur, function()
		while hovering do task.wait(0.2) end
		kill()
	end)

	return t
end

--------------------------------------------------------------
-- ELEMENTS
--------------------------------------------------------------
function stuff:Label(king, str, col, size)
	local l = Instance.new("TextLabel")
	l.Name = "LabelElement"
	l.Size = UDim2.new(1, -8, 0, 20)
	l.BackgroundTransparency = 1
	l.Text = str
	l.TextColor3 = col or GRAY
	l.TextSize = size or 14
	l.Font = F2
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.ZIndex = 404
	l.Parent = king

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.Parent = l
	return l
end

function stuff:Header(king, str)
	local l = Instance.new("TextLabel")
	l.Name = "HeaderElement"
	l.Size = UDim2.new(1, -8, 0, 24)
	l.BackgroundTransparency = 1
	l.Text = str
	l.TextColor3 = PURPLE
	l.TextSize = 16
	l.Font = F
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 404
	l.Parent = king

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.Parent = l
	return l
end

function stuff:Divider(king)
	local f = Instance.new("Frame")
	f.Name = "DividerElement"
	f.Size = UDim2.new(1, -14, 0, 2)
	f.BackgroundColor3 = EDGE
	f.BackgroundTransparency = 0.4
	f.BorderSizePixel = 0
	f.ZIndex = 403
	f.Parent = king
	return f
end

-- label on the left, value on the right. returns the value label
-- so you can keep updating it
function stuff:Stat(king, str, value, kind)
	local col = WHITE
	if kind == "ok"   then col = GREEN  end
	if kind == "warn" then col = ORANGE end
	if kind == "err"  then col = RED    end
	if kind == "gold" then col = GOLD   end
	if kind == "loot" then col = PURPLE end
	if kind == "dim"  then col = DIM    end
	if typeof(kind) == "Color3" then col = kind end

	local f = Instance.new("Frame")
	f.Name = "StatElement"
	f.Size = UDim2.new(1, -8, 0, 30)
	f.BackgroundColor3 = BOX
	f.BorderSizePixel = 0
	f.ZIndex = 403
	f.Parent = king
	corner(f, 7)
	stroke(f, 2)
	studs(f, 0.89, 7)

	local a = Instance.new("TextLabel")
	a.Size = UDim2.new(0.5, 0, 1, 0)
	a.Position = UDim2.new(0, 11, 0, 0)
	a.BackgroundTransparency = 1
	a.Text = str
	a.TextColor3 = GRAY
	a.TextSize = 14
	a.Font = F2
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.ZIndex = 405
	a.Parent = f

	local b = Instance.new("TextLabel")
	b.Name = "val"
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Size = UDim2.new(0.5, -11, 1, 0)
	b.Position = UDim2.new(1, -11, 0.5, 0)
	b.BackgroundTransparency = 1
	b.Text = tostring(value or "--")
	b.TextColor3 = col
	b.TextSize = 14
	b.Font = F
	b.TextXAlignment = Enum.TextXAlignment.Right
	b.TextTruncate = Enum.TextTruncate.AtEnd
	b.ZIndex = 405
	b.Parent = f

	return b, f
end

function stuff:Button(str, king, cb)
	local face = makeButton(king, UDim2.new(1, -8, 0, 40), UDim2.new(0, 0, 0, 0),
		PURPLE, str, 16, 403)
	local holder = face.Parent
	holder.Name = "ButtonElement"

	face.MouseButton1Click:Connect(function()
		task.spawn(function()
			local ok, err = pcall(cb)
			if not ok then warn("[hub] button:", err) end
		end)
	end)
	return face
end

function stuff:Toggle(str, king, def, cb)
	local newTog = Instance.new("TextButton")
	newTog.Name = "ToggleElement"
	newTog.Size = UDim2.new(1, -8, 0, 40)
	newTog.BackgroundColor3 = BOX
	newTog.AutoButtonColor = false
	newTog.Text = ""
	newTog.BorderSizePixel = 0
	newTog.ZIndex = 403
	newTog.Parent = king
	corner(newTog, 8)
	local togStroke = stroke(newTog, 2)
	studs(newTog, 0.89, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Name = "TextLabel"
	lbl.Size = UDim2.new(1, -80, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = str
	lbl.TextColor3 = WHITE
	lbl.TextSize = 15
	lbl.Font = F
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 405
	lbl.Parent = newTog

	local togbg = Instance.new("Frame")
	togbg.Name = "togglebg"
	togbg.AnchorPoint = Vector2.new(1, 0.5)
	togbg.Size = UDim2.new(0, 52, 0, 24)
	togbg.Position = UDim2.new(1, -12, 0.5, 0)
	togbg.BackgroundColor3 = TG_OFF
	togbg.BorderSizePixel = 0
	togbg.ZIndex = 405
	togbg.Parent = newTog
	corner(togbg, 999)
	stroke(togbg, 2)

	local knob = Instance.new("Frame")
	knob.Name = "leftrightlol"
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.Position = UDim2.new(0, 2, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(240, 234, 252)
	knob.BorderSizePixel = 0
	knob.ZIndex = 406
	knob.Parent = togbg
	corner(knob, 999)
	stroke(knob, 2)

	local isTog = def and true or false

	local function paint(animated)
		local t = animated and 0.2 or 0
		if isTog then
			tw(togbg, TweenInfo.new(t), {BackgroundColor3 = TG_ON})
			tw(togStroke, TweenInfo.new(t), {Color = PURPLE})
			tw(knob, TweenInfo.new(t, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(1, -22, 0.5, 0)
			})
		else
			tw(togbg, TweenInfo.new(t), {BackgroundColor3 = TG_OFF})
			tw(togStroke, TweenInfo.new(t), {Color = EDGE})
			tw(knob, TweenInfo.new(t, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, 2, 0.5, 0)
			})
		end
	end

	paint(false)
	task.defer(function()
		local ok, err = pcall(cb, isTog)
		if not ok then warn("[hub] toggle init:", err) end
	end)

	newTog.MouseButton1Click:Connect(function()
		isTog = not isTog
		paint(true)
		play(SND_CLICK, 0.32)
		task.spawn(function()
			local ok, err = pcall(cb, isTog)
			if not ok then warn("[hub] toggle:", err) end
		end)
	end)

	newTog.MouseEnter:Connect(function()
		tw(newTog, SMOOTH, {BackgroundColor3 = lighten(BOX, 1.12)})
	end)
	newTog.MouseLeave:Connect(function()
		tw(newTog, SMOOTH, {BackgroundColor3 = BOX})
	end)

	-- so it can be flipped from outside (keybinds)
	return {
		Set = function(v)
			if isTog == v then return end
			isTog = v
			paint(true)
		end,
		Get = function() return isTog end,
	}
end

function stuff:Textbox(str, king, def, cb)
	local newTb = Instance.new("Frame")
	newTb.Name = "TextboxElement"
	newTb.Size = UDim2.new(1, -8, 0, 40)
	newTb.BackgroundColor3 = BOX
	newTb.BorderSizePixel = 0
	newTb.ZIndex = 403
	newTb.Parent = king
	corner(newTb, 8)
	stroke(newTb, 2)
	studs(newTb, 0.89, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Name = "TextLabel"
	lbl.Size = UDim2.new(0.45, 0, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = str
	lbl.TextColor3 = WHITE
	lbl.TextSize = 15
	lbl.Font = F
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 405
	lbl.Parent = newTb

	local tbbg = Instance.new("Frame")
	tbbg.Name = "tbbg"
	tbbg.AnchorPoint = Vector2.new(1, 0.5)
	tbbg.Size = UDim2.new(0.5, -14, 0, 26)
	tbbg.Position = UDim2.new(1, -12, 0.5, 0)
	tbbg.BackgroundColor3 = Color3.fromRGB(24, 19, 36)
	tbbg.BorderSizePixel = 0
	tbbg.ZIndex = 405
	tbbg.Parent = newTb
	corner(tbbg, 6)
	stroke(tbbg, 2)

	local inp = Instance.new("TextBox")
	inp.Name = "Inp"
	inp.Size = UDim2.new(1, -12, 1, 0)
	inp.Position = UDim2.new(0, 6, 0, 0)
	inp.BackgroundTransparency = 1
	inp.Text = tostring(def or "")
	inp.PlaceholderText = "..."
	inp.PlaceholderColor3 = DIM
	inp.TextColor3 = WHITE
	inp.TextSize = 14
	inp.Font = F2
	inp.ClearTextOnFocus = false
	inp.TextXAlignment = Enum.TextXAlignment.Left
	inp.ZIndex = 406
	inp.Parent = tbbg

	inp.FocusLost:Connect(function()
		task.spawn(function()
			local ok, err = pcall(cb, inp.Text)
			if not ok then warn("[hub] textbox:", err) end
		end)
	end)
	return inp
end

function stuff:Unsupported(king, cb)
	local newUs = Instance.new("Frame")
	newUs.Name = "unsupportElement"
	newUs.Size = UDim2.new(1, -8, 0, 168)
	newUs.BackgroundColor3 = BOX
	newUs.BorderSizePixel = 0
	newUs.ZIndex = 403
	newUs.Parent = king
	corner(newUs, 9)
	stroke(newUs, 2)
	studs(newUs, 0.88, 9)

	local h = Instance.new("TextLabel")
	h.Size = UDim2.new(1, -20, 0, 30)
	h.Position = UDim2.new(0, 10, 0, 14)
	h.BackgroundTransparency = 1
	h.Text = "game not supported"
	h.TextColor3 = ORANGE
	h.TextSize = 19
	h.Font = F
	h.ZIndex = 405
	h.Parent = newUs

	local d = Instance.new("TextLabel")
	d.Size = UDim2.new(1, -28, 0, 40)
	d.Position = UDim2.new(0, 14, 0, 44)
	d.BackgroundTransparency = 1
	d.Text = "no module for this game yet.\ncheck the list of supported ones."
	d.TextColor3 = GRAY
	d.TextSize = 14
	d.Font = F2
	d.TextWrapped = true
	d.ZIndex = 405
	d.Parent = newUs

	local glbtn = makeButton(newUs, UDim2.new(1, -28, 0, 38), UDim2.new(0, 14, 0, 90),
		PURPLE, "games list", 16, 405)
	glbtn.Name = "glbtn"

	local sug = makeButton(newUs, UDim2.new(1, -28, 0, 34), UDim2.new(0, 14, 0, 128),
		BOX, "suggest game", 15, 405)
	sug.Name = "suggestbtn"

	local sugLbl = sug:FindFirstChild("TextLabel")
	sug.MouseButton1Click:Connect(function()
		pcall(function() setclipboard("discord.gg/yourserver") end)
		if sugLbl then
			sugLbl.Text = "copied link!"
			task.wait(1)
			sugLbl.Text = "suggest game"
		end
	end)

	glbtn.MouseButton1Click:Connect(cb)
	return newUs
end

function stuff:addGame(king, gname, gstate, cb)
	local newGame = Instance.new("Frame")
	newGame.Name = "GameElement"
	newGame.Size = UDim2.new(1, -8, 0, 44)
	newGame.BackgroundTransparency = 1
	newGame.ZIndex = 403
	newGame.Parent = king

	local base = Instance.new("Frame")
	base.Size = UDim2.new(1, 0, 1, 0)
	base.BackgroundColor3 = darken(BOX, 0.6)
	base.BorderSizePixel = 0
	base.ZIndex = 403
	base.Parent = newGame
	corner(base, 8)
	stroke(base, 2)

	local btn = Instance.new("TextButton")
	btn.Name = "ButtonElement"
	btn.Size = UDim2.new(1, 0, 1, -4)
	btn.BackgroundColor3 = BOX
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.BorderSizePixel = 0
	btn.ZIndex = 404
	btn.Parent = newGame
	corner(btn, 8)
	stroke(btn, 2)
	studs(btn, 0.89, 8)

	local status = Instance.new("Frame")
	status.Name = "status"
	status.AnchorPoint = Vector2.new(0, 0.5)
	status.Size = UDim2.new(0, 11, 0, 11)
	status.Position = UDim2.new(0, 12, 0.5, 0)
	status.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	status.BorderSizePixel = 0
	status.ZIndex = 406
	status.Parent = btn
	corner(status, 999)
	stroke(status, 2)

	if gstate == "\240\159\159\162" then          -- green circle
		status.BackgroundColor3 = Color3.fromRGB(0, 220, 60)
	elseif gstate == "\240\159\159\161" then      -- yellow circle
		status.BackgroundColor3 = Color3.fromRGB(240, 210, 40)
	elseif gstate == "\240\159\148\180" then      -- red circle
		status.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
	end

	local header = Instance.new("TextLabel")
	header.Name = "header"
	header.Size = UDim2.new(1, -70, 1, 0)
	header.Position = UDim2.new(0, 32, 0, 0)
	header.BackgroundTransparency = 1
	header.Text = gname
	header.TextColor3 = WHITE
	header.TextSize = 14
	header.Font = F
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextTruncate = Enum.TextTruncate.AtEnd
	header.ZIndex = 406
	header.Parent = btn

	local fl = Instance.new("TextLabel")
	fl.AnchorPoint = Vector2.new(1, 0.5)
	fl.Size = UDim2.new(0, 26, 1, 0)
	fl.Position = UDim2.new(1, -10, 0.5, 0)
	fl.BackgroundTransparency = 1
	fl.Text = ">"
	fl.TextColor3 = DIM
	fl.TextSize = 16
	fl.Font = F
	fl.ZIndex = 406
	fl.Parent = btn

	-- mark the one youre in right now
	if tostring(game.PlaceId) == tostring(gname) then end

	btn.MouseEnter:Connect(function()
		tw(btn, SMOOTH, {BackgroundColor3 = lighten(BOX, 1.15)})
		tw(fl, SMOOTH, {TextColor3 = LILAC})
	end)
	btn.MouseLeave:Connect(function()
		tw(btn, SMOOTH, {BackgroundColor3 = BOX})
		tw(fl, SMOOTH, {TextColor3 = DIM})
	end)
	btn.MouseButton1Down:Connect(function()
		btn.Position = UDim2.new(0, 0, 0, 4)
	end)
	local function up() btn.Position = UDim2.new(0, 0, 0, 0) end
	btn.MouseButton1Up:Connect(up)
	btn.MouseLeave:Connect(up)

	btn.MouseButton1Click:Connect(function()
		play(SND_CLICK, 0.3)
		task.spawn(cb)
	end)

	return newGame
end

function stuff:Searchbar(king, gameList, onPick)
	local sb = Instance.new("Frame")
	sb.Name = "searchBar"
	sb.Size = UDim2.new(1, -8, 0, 36)
	sb.BackgroundColor3 = Color3.fromRGB(24, 19, 36)
	sb.BorderSizePixel = 0
	sb.LayoutOrder = -1
	sb.ZIndex = 403
	sb.Parent = king
	corner(sb, 8)
	stroke(sb, 2)

	local inp = Instance.new("TextBox")
	inp.Name = "Inp"
	inp.Size = UDim2.new(1, -24, 1, 0)
	inp.Position = UDim2.new(0, 12, 0, 0)
	inp.BackgroundTransparency = 1
	inp.Text = ""
	inp.PlaceholderText = "search game..."
	inp.PlaceholderColor3 = DIM
	inp.TextColor3 = WHITE
	inp.TextSize = 14
	inp.Font = F2
	inp.ClearTextOnFocus = false
	inp.TextXAlignment = Enum.TextXAlignment.Left
	inp.ZIndex = 405
	inp.Parent = sb

	local exservice
	pcall(function() exservice = game:GetService("ExperienceService") end)

	-- main.lua passes onPick so the search results teleport the exact
	-- same way as the normal list does (queueing the script first).
	-- without this the ones you find by searching jumped raw and the
	-- hub didnt come back
	local function jump(g)
		if onPick then return onPick(g) end
		pcall(function()
			exservice:LaunchExperience({placeId = tonumber(g.id)})
		end)
	end

	inp:GetPropertyChangedSignal("Text"):Connect(function()
		for _, v in pairs(king:GetChildren()) do
			if v.Name == "GameElement" then v:Destroy() end
		end
		for _, g in ipairs(gameList or {}) do
			if g.game:lower():find(inp.Text:lower(), 1, true) then
				stuff:addGame(king, g.game, g.status, function()
					jump(g)
				end)
			end
		end
	end)

	return sb
end

function stuff:CredHead(king, txt)
	local newHead = Instance.new("TextLabel")
	newHead.Name = "CreditHeader"
	newHead.Size = UDim2.new(1, -8, 0, 24)
	newHead.BackgroundTransparency = 1
	newHead.Text = "> " .. txt
	newHead.TextColor3 = PURPLE
	newHead.TextSize = 16
	newHead.Font = F
	newHead.TextXAlignment = Enum.TextXAlignment.Left
	newHead.ZIndex = 404
	newHead.Parent = king

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.Parent = newHead
	return newHead
end

function stuff:CredPerson(king, txt)
	local newCred = Instance.new("TextLabel")
	newCred.Name = "CreditPerson"
	newCred.Size = UDim2.new(1, -8, 0, 20)
	newCred.BackgroundTransparency = 1
	newCred.Text = "      + " .. txt
	newCred.TextColor3 = GRAY
	newCred.TextSize = 14
	newCred.Font = F2
	newCred.TextXAlignment = Enum.TextXAlignment.Left
	newCred.ZIndex = 404
	newCred.Parent = king

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.Parent = newCred
	return newCred
end

return stuff
