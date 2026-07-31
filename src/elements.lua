--// elements.lua
--// Stud UI Pack Edition - Sleek Clean Elements (ZERO STUDS INSIDE TABS)
--// 100% Compatible API: Label, Button, Toggle, Textbox, Unsupported,
--// addGame, Searchbar, CredHead, CredPerson, Header, Stat, Divider, Notify

local tweenservice = game:GetService("TweenService")
local players      = game:GetService("Players")
local plr          = players.LocalPlayer
local stuff        = {}

--------------------------------------------------------------
-- THEME & COLORS
--------------------------------------------------------------
local BG2     = Color3.fromRGB(28, 22, 42)
local BOX     = Color3.fromRGB(35, 35, 48)
local EDGE    = Color3.fromRGB(0, 0, 0)
local PURPLE  = Color3.fromRGB(0, 180, 255)
local LILAC   = Color3.fromRGB(180, 220, 255)
local GREEN   = Color3.fromRGB(0, 230, 110)
local ORANGE  = Color3.fromRGB(255, 180, 30)
local RED     = Color3.fromRGB(255, 60, 70)
local WHITE   = Color3.fromRGB(255, 255, 255)
local GRAY    = Color3.fromRGB(200, 205, 220)
local DIM     = Color3.fromRGB(140, 145, 165)
local GOLD    = Color3.fromRGB(255, 210, 20)
local TG_ON   = Color3.fromRGB(0, 200, 255)
local TG_OFF  = Color3.fromRGB(45, 45, 60)

local F  = Enum.Font.FredokaOne
local F2 = Enum.Font.FredokaOne

local SMOOTH = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BOUNCE = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SNAP   = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SND_CLICK = "rbxassetid://6042053626"
local SND_TOAST = "rbxassetid://4590662766"

--------------------------------------------------------------
-- HELPERS
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
	c.CornerRadius = UDim.new(0, rad or 8)
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

local function textStroke(p, th, col)
	local s = Instance.new("UIStroke")
	s.Thickness = th or 2
	s.Color = col or EDGE
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

-- NO STUDS INSIDE ELEMENTS (Clean glossy look)
local function studs(p, transp, rad)
	-- Intentionally empty: Zero studs inside tabs / cards / buttons
	return nil
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
-- 3D STUD BUTTON (CLEAN NO STUDS)
--------------------------------------------------------------
local SINK = 4
local function makeButton(parent, size, pos, color, text, txtSize, z, txtCol)
	local h = Instance.new("Frame")
	h.Size = size
	h.Position = pos
	h.BackgroundTransparency = 1
	h.ZIndex = z
	h.Parent = parent

	local base = Instance.new("Frame")
	base.Size = UDim2.new(1, 0, 1, 0)
	base.BackgroundColor3 = darken(color, 0.5)
	base.BorderSizePixel = 0
	base.ZIndex = z
	base.Parent = h
	corner(base, 8)
	stroke(base, 2, EDGE)

	local face = Instance.new("TextButton")
	face.Size = UDim2.new(1, 0, 1, -SINK)
	face.BackgroundColor3 = color
	face.AutoButtonColor = false
	face.Text = ""
	face.BorderSizePixel = 0
	face.ClipsDescendants = true
	face.ZIndex = z + 1
	face.Parent = h
	corner(face, 8)
	stroke(face, 2, EDGE)

	glossyGradient(face, color, darken(color, 0.75), 90)

	-- Top plastic glossy sheen
	local br = Instance.new("Frame")
	br.Size = UDim2.new(1, -10, 0, 3)
	br.Position = UDim2.new(0, 5, 0, 3)
	br.BackgroundColor3 = WHITE
	br.BackgroundTransparency = 0.75
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
	textStroke(lbl, 2, EDGE)

	local sc = Instance.new("UIScale")
	sc.Parent = face
	local scT = Instance.new("UIScale")
	scT.Parent = lbl

	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(0, 30, 2, 0)
	shine.Position = UDim2.new(0, -50, -0.5, 0)
	shine.BackgroundColor3 = WHITE
	shine.BackgroundTransparency = 1
	shine.BorderSizePixel = 0
	shine.Rotation = 18
	shine.ZIndex = z + 2
	shine.Parent = face

	local pressed = false

	face.MouseEnter:Connect(function()
		if pressed then return end
		tw(face, SMOOTH, {BackgroundColor3 = lighten(color, 1.15)})
		tw(sc, SMOOTH, {Scale = 1.02})
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
		tw(sc, SNAP, {Scale = 0.97})
		tw(scT, SNAP, {Scale = 0.94})

		local ax, ay = face.AbsolutePosition.X, face.AbsolutePosition.Y
		local rp = Instance.new("Frame")
		rp.AnchorPoint = Vector2.new(0.5, 0.5)
		rp.Position = UDim2.new(0, i.Position.X - ax, 0, i.Position.Y - ay)
		rp.Size = UDim2.new(0, 0, 0, 0)
		rp.BackgroundColor3 = WHITE
		rp.BackgroundTransparency = 0.5
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
		shine.BackgroundTransparency = 0.6
		tw(shine, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, 40, -0.5, 0),
			BackgroundTransparency = 1,
		})

		play(SND_CLICK, 0.4)
	end)

	return face, h
end

--------------------------------------------------------------
-- NOTIFY (TOASTS)
--------------------------------------------------------------
local T_W, T_H, T_GAP = 270, 64, 10
local toasts = {}
local toastRoot

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
		local hui = gethui or get_hidden_gui
		local ok = pcall(function()
			toastRoot = (hui and hui() or game:GetService("CoreGui")):FindFirstChild("\0LoadedHub")
		end)
		if not ok or not toastRoot then
			toastRoot = plr:FindFirstChildOfClass("PlayerGui")
		end
	end
	if not toastRoot then return end

	local col = colOf(kind)
	dur = dur or 3

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

	corner(t, 8)
	stroke(t, 2, EDGE)

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
	textStroke(tit, 2, EDGE)

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -60, 0, 22)
	body.Position = UDim2.new(0, 17, 0, 28)
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
	textStroke(body, 1.5, EDGE)

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
	textStroke(x, 2, EDGE)

	local dr = Instance.new("Frame")
	dr.Size = UDim2.new(1, -10, 0, 3)
	dr.Position = UDim2.new(0, 5, 1, -7)
	dr.BackgroundColor3 = col
	dr.BorderSizePixel = 0
	dr.ZIndex = 903
	dr.Parent = t
	corner(dr, 2)

	local sc = Instance.new("UIScale")
	sc.Scale = 0.9
	sc.Parent = t

	table.insert(toasts, t)
	restack()

	tw(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
	tw(dr, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)})
	play(SND_TOAST, 0.35)

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

	task.delay(dur, function() kill() end)
	return t
end

--------------------------------------------------------------
-- ELEMENTS (NO STUDS INSIDE)
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
	textStroke(l, 1.5, EDGE)

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
	l.TextSize = 17
	l.Font = F
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 404
	l.Parent = king
	textStroke(l, 2, EDGE)

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
	f.BorderSizePixel = 0
	f.ZIndex = 403
	f.Parent = king
	return f
end

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
	f.Size = UDim2.new(1, -8, 0, 32)
	f.BackgroundColor3 = BOX
	f.BorderSizePixel = 0
	f.ZIndex = 403
	f.Parent = king

	corner(f, 7)
	stroke(f, 2, EDGE)

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
	textStroke(a, 1.5, EDGE)

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
	textStroke(b, 2, EDGE)

	return b, f
end

function stuff:Button(str, king, cb)
	local face = makeButton(king, UDim2.new(1, -8, 0, 40), UDim2.new(0, 0, 0, 0), PURPLE, str, 16, 403)
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
	newTog.Size = UDim2.new(1, -8, 0, 42)
	newTog.BackgroundColor3 = BOX
	newTog.AutoButtonColor = false
	newTog.Text = ""
	newTog.BorderSizePixel = 0
	newTog.ZIndex = 403
	newTog.Parent = king

	corner(newTog, 8)
	local togStroke = stroke(newTog, 2, EDGE)

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
	textStroke(lbl, 2, EDGE)

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
	stroke(togbg, 2, EDGE)

	local knob = Instance.new("Frame")
	knob.Name = "leftrightlol"
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.Position = UDim2.new(0, 2, 0.5, 0)
	knob.BackgroundColor3 = WHITE
	knob.BorderSizePixel = 0
	knob.ZIndex = 406
	knob.Parent = togbg

	corner(knob, 999)
	stroke(knob, 2, EDGE)

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
	newTb.Size = UDim2.new(1, -8, 0, 42)
	newTb.BackgroundColor3 = BOX
	newTb.BorderSizePixel = 0
	newTb.ZIndex = 403
	newTb.Parent = king

	corner(newTb, 8)
	stroke(newTb, 2, EDGE)

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
	textStroke(lbl, 2, EDGE)

	local tbbg = Instance.new("Frame")
	tbbg.Name = "tbbg"
	tbbg.AnchorPoint = Vector2.new(1, 0.5)
	tbbg.Size = UDim2.new(0.5, -14, 0, 28)
	tbbg.Position = UDim2.new(1, -12, 0.5, 0)
	tbbg.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	tbbg.BorderSizePixel = 0
	tbbg.ZIndex = 405
	tbbg.Parent = newTb

	corner(tbbg, 6)
	stroke(tbbg, 2, EDGE)

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
	textStroke(inp, 1.5, EDGE)

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
	stroke(newUs, 2, EDGE)

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
	textStroke(h, 2, EDGE)

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
	textStroke(d, 1.5, EDGE)

	local glbtn = makeButton(newUs, UDim2.new(1, -28, 0, 38), UDim2.new(0, 14, 0, 90), PURPLE, "games list", 16, 405)
	glbtn.Name = "glbtn"

	local sug = makeButton(newUs, UDim2.new(1, -28, 0, 34), UDim2.new(0, 14, 0, 128), BOX, "suggest game", 15, 405)
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
	stroke(base, 2, EDGE)

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
	stroke(btn, 2, EDGE)

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
	stroke(status, 2, EDGE)

	if gstate == "🟢" or gstate == "\240\159\159\162" then
		status.BackgroundColor3 = Color3.fromRGB(0, 230, 100)
	elseif gstate == "🟡" or gstate == "\240\159\159\161" then
		status.BackgroundColor3 = Color3.fromRGB(250, 200, 30)
	elseif gstate == "🔴" or gstate == "\240\159\148\180" then
		status.BackgroundColor3 = Color3.fromRGB(250, 60, 60)
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
	textStroke(header, 1.5, EDGE)

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
	textStroke(fl, 1.5, EDGE)

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
	sb.Size = UDim2.new(1, -8, 0, 38)
	sb.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	sb.BorderSizePixel = 0
	sb.LayoutOrder = -1
	sb.ZIndex = 403
	sb.Parent = king

	corner(sb, 8)
	stroke(sb, 2, EDGE)

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
	textStroke(inp, 1.5, EDGE)

	local exservice
	pcall(function() exservice = game:GetService("ExperienceService") end)

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
	textStroke(newHead, 2, EDGE)

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
	textStroke(newCred, 1.5, EDGE)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.Parent = newCred

	return newCred
end

return stuff
