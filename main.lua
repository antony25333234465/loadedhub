--// LOADED HUB - loader
--// Stud UI Pack Edition - Universal Aimbot + ESP
--// v3 - wall check on the aimbot (no more locking through walls)
--//      and esp/chams so you can actually see them
local hui              = gethui or get_hidden_gui
local getexec          = identifyexecutor

local coregui          = game:GetService("CoreGui")
local userinputservice = game:GetService("UserInputService")
local httpservice      = game:GetService("HttpService")
local tweenservice     = game:GetService("TweenService")
local runservice       = game:GetService("RunService")
local players          = game:GetService("Players")

-- ExperienceService is not on every client
local exservice
pcall(function() exservice = game:GetService("ExperienceService") end)

local plr = players.LocalPlayer

--------------------------------------------------------------
-- PLACE ID ALIAS MAP
--------------------------------------------------------------
local PLACE_ALIASES = {
	["128001665358186"] = "137826330724902", -- Scary Shawarma (In Game) -> Main Place ID
}

--------------------------------------------------------------
-- REPO
--------------------------------------------------------------
local BASE = getgenv and getgenv().HUB_BASE
	or "https://raw.githubusercontent.com/antony25333234465/loadedhub/refs/heads/main/"

function getgitpath(what)
	if what == "games" then return BASE .. "games/" end
	if what == "src"   then return BASE .. "src/"   end
	return BASE
end

local FOLDER   = "LoadedHub"
local CFG_FILE = FOLDER .. "/Config.json"
local VERSION  = "1.0"
local DISCORD  = "discord.gg/yourserver"

--------------------------------------------------------------
-- CONFIG ON DISK
--------------------------------------------------------------
local DEFAULTS = {
	settings = {
		disable_3d_rendering = false,
		auto_rejoin_on_kick = false,
		auto_exec_on_tp = true,
		sounds = true,
		tp_step = 160,
	},
	farm = {
		stomp = 1.2,
		claim_timeout = 7,
		noclip_off = 1.0,
		atk_cooldown = 0.5,
	},
}

local hasFS = (isfolder ~= nil and makefolder ~= nil and isfile ~= nil
	and readfile ~= nil and writefile ~= nil)

if hasFS then
	pcall(function()
		if not isfolder(FOLDER) then makefolder(FOLDER) end
		if not isfolder(FOLDER .. "/games") then makefolder(FOLDER .. "/games") end
		if not isfile(CFG_FILE) then
			writefile(CFG_FILE, httpservice:JSONEncode(DEFAULTS))
		else
			-- this said JSONEncode before, which handed back a string and
			-- silently threw every saved setting away. took me ages to spot
			local dec = httpservice:JSONDecode(readfile(CFG_FILE))
			local changed = false
			for sec, vals in pairs(DEFAULTS) do
				if type(dec[sec]) ~= "table" then dec[sec] = {} changed = true end
				for k, v in pairs(vals) do
					if dec[sec][k] == nil then dec[sec][k] = v changed = true end
				end
			end
			if changed then writefile(CFG_FILE, httpservice:JSONEncode(dec)) end
		end
	end)
end

local function readCfg()
	if not hasFS then return DEFAULTS end
	local ok, dec = pcall(function()
		return httpservice:JSONDecode(readfile(CFG_FILE))
	end)
	return (ok and type(dec) == "table") and dec or DEFAULTS
end

--------------------------------------------------------------
-- AUTO EXEC ON TELEPORT
--------------------------------------------------------------
local queueTp = (syn and syn.queue_on_teleport)
	or queue_on_teleport
	or (fluxus and fluxus.queue_on_teleport)
	or queueonteleport

local function tpPayload()
	return ([[
getgenv().HUB_BASE = %q
getgenv().HUB_FROM_TP = true
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(%d)
local ok, err = pcall(function()
	loadstring(game:HttpGet(%q))()
end)
if not ok then warn("[hub] autoexec failed: " .. tostring(err)) end
]]):format(BASE, 3, BASE .. "main.lua")
end

local function armTeleport()
	if not queueTp then return false end
	local cfg = readCfg()
	if cfg.settings and cfg.settings.auto_exec_on_tp == false then return false end
	local ok = pcall(queueTp, tpPayload())
	if not ok then warn("[hub] couldnt queue script for teleport") end
	return ok
end

pcall(function()
	plr.OnTeleport:Connect(function(state)
		if state == Enum.TeleportState.Started
		or state == Enum.TeleportState.RequestedFromServer then
			armTeleport()
		end
	end)
end)

--------------------------------------------------------------
-- FETCH
--------------------------------------------------------------
local function bust(url)
	return url .. "?nocache=" .. tostring(math.random(100000, 999999)) .. tostring(os.time())
end

local function fetch(url, cachePath)
	local ok, body = pcall(function() return game:HttpGet(bust(url)) end)

	if not ok then
		warn("[hub] http failed on " .. url .. " -> " .. tostring(body))
	elseif body == "404: Not Found" then
		warn("[hub] 404 file not found: " .. url)
	elseif not body or #body == 0 then
		warn("[hub] empty answer from " .. url)
	end

	if ok and body and #body > 0 and body ~= "404: Not Found" then
		if hasFS and cachePath then
			pcall(function() writefile(cachePath, body) end)
		end
		return body
	end

	if hasFS and cachePath and isfile(cachePath) then
		warn("[hub] falling back to disk copy: " .. cachePath)
		local ok2, cached = pcall(function() return readfile(cachePath) end)
		if ok2 then return cached end
	end
	return nil
end

local function decode(raw, what, fallback)
	if not raw then return fallback end
	local ok, dec = pcall(function() return httpservice:JSONDecode(raw) end)
	if not ok then
		warn("[hub] " .. what .. " is broken json -> " .. tostring(dec))
	end
	return (ok and type(dec) == "table") and dec or fallback
end

--------------------------------------------------------------
-- UI INITIALIZATION
--------------------------------------------------------------
pcall(function()
	local root = hui and hui() or coregui
	local old = root:FindFirstChild("\0LoadedHub")
	if old then old:Destroy() end
	-- the esp folder lives outside the gui so it survives a reload
	local oldEsp = root:FindFirstChild("\0LH_esp")
	if oldEsp then oldEsp:Destroy() end
end)

local uiSrc = fetch(getgitpath("src") .. "ui.lua", FOLDER .. "/src_ui.lua")
if not uiSrc then
	warn("[hub] couldnt fetch ui.lua")
	return
end

local ui = loadstring(uiSrc)()
ui.Parent = hui and hui() or coregui

pcall(function() if syn and syn.protect_gui then syn.protect_gui(ui) end end)
pcall(function() if protectgui then protectgui(ui) end end)

local ToggleButton      = ui.togglebtn
local MainFrame         = ui.Frame
local Topbar            = MainFrame.TopBar
local SectionContainers = MainFrame.sectionContainers
local TabList           = MainFrame.tablist
local HideButton        = Topbar.hidebtn
local CloseButton       = Topbar.closebtn

local Sections = {
	Home = {
		TabBtn = TabList.HomeTab,
		Container = SectionContainers.homeframe
	},
	Game = {
		TabBtn = TabList.GameTab,
		Container = SectionContainers.gameFrame
	},
	Universal = {
		TabBtn = TabList.UniversalTab,
		Container = SectionContainers.universalframe
	},
	GamesList = {
		TabBtn = TabList.GameslistTab,
		Container = SectionContainers.gamelistFrame
	},
	Settings = {
		TabBtn = TabList.SettingsTab,
		Container = SectionContainers.settingsFrame
	},
	Credits = {
		TabBtn = TabList.CreditsTab,
		Container = SectionContainers.creditsFrame
	}
}

local CurSection

for _, sect in pairs(Sections) do
	sect.TabBtn.MouseEnter:Connect(function()
		for _, stroke in pairs(sect.TabBtn:GetChildren()) do
			if stroke.Name == "InnerShadow" then
				stroke.BackgroundTransparency = 0.95
			end
		end
	end)

	sect.TabBtn.MouseLeave:Connect(function()
		for _, stroke in pairs(sect.TabBtn:GetChildren()) do
			if stroke.Name == "InnerShadow" then
				stroke.BackgroundTransparency = 1
			end
		end
	end)

	sect.TabBtn.MouseButton1Click:Connect(function()
		if CurSection == sect then return end

		if CurSection then
			CurSection.TabBtn.BackgroundTransparency = 1
			CurSection.Container:TweenPosition(UDim2.new(0.5, 0, 1, 0),
				Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
		end

		sect.TabBtn.BackgroundTransparency = 0
		sect.Container:TweenPosition(UDim2.new(0.5, 0, 0, 0),
			Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
		sect.Container.Visible = true

		CurSection = sect
	end)
end

local function goTo(sect)
	if CurSection == sect then return end
	if CurSection then
		CurSection.TabBtn.BackgroundTransparency = 1
		CurSection.Container:TweenPosition(UDim2.new(0.5, 0, 1, 0),
			Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
	end
	sect.TabBtn.BackgroundTransparency = 0
	sect.Container:TweenPosition(UDim2.new(0.5, 0, 0, 0),
		Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
	sect.Container.Visible = true
	CurSection = sect
end

HideButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	ToggleButton.Visible = true
end)

ToggleButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	ToggleButton.Visible = false
end)

CloseButton.MouseButton1Click:Connect(function()
	ui:Destroy()
end)

--------------------------------------------------------------
-- DRAG
--------------------------------------------------------------
local dragging = false
local dragInput, mousePos, framePos

Topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		mousePos = input.Position
		framePos = MainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Topbar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

userinputservice.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - mousePos
		MainFrame.Position = UDim2.new(
			framePos.X.Scale,
			framePos.X.Offset + delta.X,
			framePos.Y.Scale,
			framePos.Y.Offset + delta.Y
		)
	end
end)

--------------------------------------------------------------
-- HOME LABELS
--------------------------------------------------------------
local H = Sections.Home.Container

H.discan.Text       = H.discan.Text:gsub("redacted", DISCORD)
H.bugsLabel.Text    = H.bugsLabel.Text:gsub("redacted", DISCORD)
H.execLabel.Text    = "exec: " .. tostring((pcall(getexec) and getexec()) or "unknown")
H.versionLabel.Text = "ver: " .. VERSION
H.placeLabel.Text   = "placeid: " .. tostring(game.PlaceId)

--------------------------------------------------------------
-- REMOTE DATA & DEFAULT GAMES
--------------------------------------------------------------
pcall(function() ui:SetAttribute("busy", true) end)

local elementsSrc = fetch(getgitpath("src") .. "elements.lua", FOLDER .. "/src_elements.lua")
if not elementsSrc then
	warn("[hub] couldnt fetch elements.lua")
	return
end
local elements = loadstring(elementsSrc)()

local gameListRaw = fetch(getgitpath("src") .. "gameslist.json", FOLDER .. "/gameslist.json")
local creditsRaw  = fetch(getgitpath("src") .. "credits.json",   FOLDER .. "/credits.json")

local defaultGames = {
	{ game = "Cut Grass for Brainrots",           id = "97365843755210",  status = "\240\159\159\162" },
	{ game = "Obby as a Brainrot",                id = "77862067599263",  status = "\240\159\159\162" },
	{ game = "Scary Shawarma Kiosk: The Anomaly", id = "137826330724902", status = "\240\159\159\162" },
	{ game = "Scary Shawarma (In Game)",          id = "128001665358186", status = "\240\159\159\162" }
}

local gameList    = decode(gameListRaw, "gameslist.json", defaultGames)
local creditsList = decode(creditsRaw,   "credits.json",   {})
if #gameList == 0 then gameList = defaultGames end

pcall(function() ui:SetAttribute("busy", false) end)

local function gameFromList(pid)
	pid = tostring(pid)
	for _, g in ipairs(gameList) do
		if tostring(g.id) == pid then return g end
	end
	if PLACE_ALIASES[pid] then
		local mappedId = PLACE_ALIASES[pid]
		for _, g in ipairs(gameList) do
			if tostring(g.id) == mappedId then return g end
		end
	end
	return nil
end

--------------------------------------------------------------
-- GAME (PlaceId Detection)
--------------------------------------------------------------
local rawPid = tostring(game.PlaceId)
local pid = PLACE_ALIASES[rawPid] or rawPid
local hereGame = gameFromList(rawPid) or gameFromList(pid)

local wantId = (getgenv and getgenv().FORCE_MODULE) and tostring(getgenv().FORCE_MODULE) or pid

local okGame, gamePath = pcall(function()
	return game:HttpGet(getgitpath("games") .. wantId .. ".lua")
end)

local loadedModule = false

if not okGame or not gamePath or #gamePath == 0 or gamePath == "404: Not Found" then
	local handledLocally = false
	local localCheckPaths = { wantId, rawPid }

	for _, chkId in ipairs(localCheckPaths) do
		if hasFS and isfile(FOLDER .. "/games/" .. chkId .. ".lua") then
			local okLocal, err = pcall(function()
				local mod = loadstring(readfile(FOLDER .. "/games/" .. chkId .. ".lua"))()
				mod(Sections.Game.Container, readCfg(), elements)
			end)
			if okLocal then
				handledLocally = true
				loadedModule = true
				break
			else
				warn("[hub] local module blew up:", err)
			end
		end
	end

	if not handledLocally then
		if hereGame then
			elements:Header(Sections.Game.Container, hereGame.game)
			elements:Stat(Sections.Game.Container, "status", "coming soon", "warn")
			elements:Label(Sections.Game.Container,
				"this game is on the list but has no module yet.")
			elements:Button("see game list", Sections.Game.Container, function()
				goTo(Sections.GamesList)
			end)
		else
			elements:Unsupported(Sections.Game.Container, function()
				goTo(Sections.GamesList)
			end)
		end
	end
else
	if hasFS then
		pcall(function()
			writefile(FOLDER .. "/games/" .. wantId .. ".lua", gamePath)
		end)
	end

	local okRun, err = pcall(function()
		local gameModule = loadstring(gamePath)()
		gameModule(Sections.Game.Container, readCfg(), elements)
	end)

	if okRun then
		loadedModule = true
	else
		warn("[hub] module blew up:", err)
		elements:Header(Sections.Game.Container, "error")
		elements:Label(Sections.Game.Container, tostring(err))
	end
end

if loadedModule then
	Sections.Game.TabBtn.Text = "Game"
	pcall(function()
		Sections.Game.TabBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
	end)
end

--------------------------------------------------------------
-- UNIVERSAL AIMBOT (STICKY LOCK + WALL CHECK)
--------------------------------------------------------------
local camera = workspace.CurrentCamera
local aimbotEnabled = false
local fovEnabled    = false
local fovRadius     = 150
local aimSmooth     = 1.0     -- 1.0 = instant, 0.2 = smooth
local aimPart       = "Head"
local teamCheck     = false   -- off for FFA
local isAiming      = false
local lockedTargetPart = nil

local wallCheck  = true   -- dont lock onto people behind cover
local dropOnLoss = true   -- and let them go the moment they hide

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
end)

-- FOV circle
local fovCircle = nil
pcall(function()
	if Drawing and Drawing.new then
		fovCircle = Drawing.new("Circle")
		fovCircle.Thickness = 2
		fovCircle.Color = Color3.fromRGB(0, 230, 255)
		fovCircle.Filled = false
		fovCircle.Transparency = 0.85
		fovCircle.NumSides = 64
		fovCircle.Radius = fovRadius
		fovCircle.Visible = false
	end
end)

runservice.RenderStepped:Connect(function()
	if fovCircle then
		fovCircle.Radius = fovRadius
		fovCircle.Visible = fovEnabled and MainFrame.Visible
		if fovCircle.Visible then
			local mp = userinputservice:GetMouseLocation()
			fovCircle.Position = Vector2.new(mp.X, mp.Y)
		end
	end
end)

--------------------------------------------------------------
-- LINE OF SIGHT
-- one raycast from the camera to the part. i skip my own character
-- and the target's, otherwise his own arm counts as a wall and
-- nothing is ever visible
--------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function canSee(part)
	if not wallCheck then return true end
	if not part or not part.Parent then return false end

	local origin = camera.CFrame.Position
	local dest   = part.Position
	local dir    = dest - origin
	if dir.Magnitude < 1 then return true end

	local skip = {part.Parent}
	if plr.Character then table.insert(skip, plr.Character) end
	rayParams.FilterDescendantsInstances = skip

	local hit = workspace:Raycast(origin, dir, rayParams)
	if not hit then return true end

	-- the ray lands on the edge of the hitbox, not the centre. without
	-- this margin you get false negatives constantly
	return (hit.Position - dest).Magnitude < 2.5
end

local function getTargetHeadPart(model)
	if not model or not model:IsA("Model") or not model.Parent then return nil end
	local part = model:FindFirstChild(aimPart)
	if not part then
		part = model:FindFirstChild("Head")
			or model:FindFirstChild("HumanoidRootPart")
			or model:FindFirstChild("Torso")
			or model:FindFirstChild("UpperTorso")
	end
	return part
end

local function isValidLockedTarget(part)
	if not part or not part.Parent then return false end
	local model = part.Parent
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end

	local mp = userinputservice:GetMouseLocation()
	local sp, onScreen = camera:WorldToViewportPoint(part.Position)
	if not onScreen then return false end

	-- 1.6x margin while tracking so the lock stays sticky
	local dist = (Vector2.new(sp.X, sp.Y) - Vector2.new(mp.X, mp.Y)).Magnitude
	if dist > (fovRadius * 1.6) then return false end

	-- ducked behind cover, drop him instead of tracking a wall
	if dropOnLoss and not canSee(part) then return false end

	return true
end

local function getClosestTargetToMouse()
	local closestPart = nil
	local shortestDist = fovRadius
	local mp = userinputservice:GetMouseLocation()
	local mv = Vector2.new(mp.X, mp.Y)

	local function consider(model)
		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return end
		local part = getTargetHeadPart(model)
		if not part then return end
		local sp, onScreen = camera:WorldToViewportPoint(part.Position)
		if not onScreen then return end
		local dist = (Vector2.new(sp.X, sp.Y) - mv).Magnitude
		if dist >= shortestDist then return end
		-- checked last on purpose, the raycast is the expensive bit
		if not canSee(part) then return end
		shortestDist = dist
		closestPart = part
	end

	-- players first
	for _, p in ipairs(players:GetPlayers()) do
		if p ~= plr and p.Character then
			local same = teamCheck and p.Team and plr.Team and p.Team == plr.Team
			if not same then consider(p.Character) end
		end
	end

	-- then npcs, only if no player matched
	if not closestPart then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj ~= plr.Character
			and not players:GetPlayerFromCharacter(obj) then
				consider(obj)
			end
		end
	end

	return closestPart
end

userinputservice.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
		lockedTargetPart = getClosestTargetToMouse()
	end
end)

userinputservice.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
		lockedTargetPart = nil
	end
end)

runservice:BindToRenderStep("LoadedHubAimbotLock", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not (aimbotEnabled and isAiming) then return end

	if not isValidLockedTarget(lockedTargetPart) then
		lockedTargetPart = getClosestTargetToMouse()
	end

	if lockedTargetPart then
		local desiredCF = CFrame.new(camera.CFrame.Position, lockedTargetPart.Position)
		if aimSmooth >= 0.95 then
			camera.CFrame = desiredCF
		else
			-- framerate independent, no jitter
			local f = math.clamp(dt * (aimSmooth * 28), 0.05, 1)
			camera.CFrame = camera.CFrame:Lerp(desiredCF, f)
		end
	end
end)

--------------------------------------------------------------
-- ESP
-- highlights for the body, billboard for the text. tried Drawing
-- boxes first but they fight the camera every frame and wobble.
-- highlights are basically free and render through walls
--------------------------------------------------------------
local espEnabled   = false
local espChams     = true
local espName      = true
local espHealth    = true
local espTracer    = false
local espTeamCheck = false
local espMaxDist   = 1000

local espFolder = Instance.new("Folder")
espFolder.Name = "\0LH_esp"
espFolder.Parent = hui and hui() or coregui

local espCache = {}

local function clearEsp(model)
	local e = espCache[model]
	if not e then return end
	if e.hl then e.hl:Destroy() end
	if e.tag then e.tag:Destroy() end
	if e.line then pcall(function() e.line:Remove() end) end
	espCache[model] = nil
end

local function clearAllEsp()
	for m in pairs(espCache) do clearEsp(m) end
end

local function espColor(model)
	local p = players:GetPlayerFromCharacter(model)
	if p and plr.Team and p.Team then
		return p.Team == plr.Team and Color3.fromRGB(90, 200, 255)
			or Color3.fromRGB(255, 80, 80)
	end
	return p and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 190, 60)
end

local function buildEsp(model)
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
	if not root then return nil end

	local e = {}

	local hl = Instance.new("Highlight")
	hl.Adornee = model
	hl.FillColor = espColor(model)
	hl.FillTransparency = 0.62
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.OutlineTransparency = 0.15
	-- this line is what makes it show through walls
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = espFolder
	e.hl = hl

	local tag = Instance.new("BillboardGui")
	tag.Adornee = root
	tag.Size = UDim2.new(0, 190, 0, 34)
	tag.StudsOffset = Vector3.new(0, 2.6, 0)
	tag.AlwaysOnTop = true
	tag.MaxDistance = espMaxDist
	tag.Parent = espFolder

	local nm = Instance.new("TextLabel")
	nm.Size = UDim2.new(1, 0, 0, 17)
	nm.BackgroundTransparency = 1
	nm.TextColor3 = Color3.fromRGB(255, 255, 255)
	nm.TextSize = 14
	nm.Font = Enum.Font.FredokaOne
	nm.Text = model.Name
	nm.Parent = tag
	local ns = Instance.new("UIStroke")
	ns.Thickness = 2
	ns.Color = Color3.fromRGB(0, 0, 0)
	ns.Parent = nm
	e.nm = nm

	local hp = Instance.new("TextLabel")
	hp.Size = UDim2.new(1, 0, 0, 15)
	hp.Position = UDim2.new(0, 0, 0, 16)
	hp.BackgroundTransparency = 1
	hp.TextColor3 = Color3.fromRGB(120, 235, 110)
	hp.TextSize = 12
	hp.Font = Enum.Font.FredokaOne
	hp.Text = ""
	hp.Parent = tag
	local hs = Instance.new("UIStroke")
	hs.Thickness = 2
	hs.Color = Color3.fromRGB(0, 0, 0)
	hs.Parent = hp
	e.hp = hp

	e.tag = tag
	e.root = root

	if Drawing and Drawing.new then
		pcall(function()
			local l = Drawing.new("Line")
			l.Thickness = 1
			l.Color = Color3.fromRGB(255, 255, 255)
			l.Transparency = 0.6
			l.Visible = false
			e.line = l
		end)
	end

	espCache[model] = e
	return e
end

local function espEligible(model)
	if model == plr.Character then return false end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	if espTeamCheck then
		local p = players:GetPlayerFromCharacter(model)
		if p and p.Team and plr.Team and p.Team == plr.Team then return false end
	end
	return true
end

-- runs on Heartbeat with a 0.1s accumulator, not every frame.
-- scanning the whole workspace 240 times a second kills your fps
local espAccum = 0
runservice.Heartbeat:Connect(function(dt)
	if not espEnabled then return end

	espAccum = espAccum + dt
	if espAccum < 0.1 then
		-- tracers are the only thing that has to keep up with the camera
		for _, e in pairs(espCache) do
			if e.line then
				if espTracer and e.root and e.root.Parent then
					local sp, on = camera:WorldToViewportPoint(e.root.Position)
					if on then
						local vp = camera.ViewportSize
						e.line.From = Vector2.new(vp.X / 2, vp.Y)
						e.line.To = Vector2.new(sp.X, sp.Y)
						e.line.Color = e.hl and e.hl.FillColor or Color3.new(1, 1, 1)
						e.line.Visible = true
					else
						e.line.Visible = false
					end
				else
					e.line.Visible = false
				end
			end
		end
		return
	end
	espAccum = 0

	local seen = {}
	local myRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

	local function handle(model)
		if not espEligible(model) then return end
		local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
		if myRoot and root and (root.Position - myRoot.Position).Magnitude > espMaxDist then
			return
		end

		seen[model] = true
		local e = espCache[model] or buildEsp(model)
		if not e then return end

		local col = espColor(model)
		e.hl.Enabled = espChams
		e.hl.FillColor = col
		e.hl.Adornee = model

		e.tag.Enabled = espName or espHealth
		e.nm.Visible = espName
		e.hp.Visible = espHealth

		if espName then
			local p = players:GetPlayerFromCharacter(model)
			e.nm.Text = p and p.DisplayName or model.Name
			e.nm.TextColor3 = col
		end

		if espHealth then
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum then
				local pct = math.floor((hum.Health / math.max(hum.MaxHealth, 1)) * 100)
				local dst = ""
				if myRoot and e.root and e.root.Parent then
					dst = "  " .. math.floor((e.root.Position - myRoot.Position).Magnitude) .. "m"
				end
				e.hp.Text = pct .. "%" .. dst
				e.hp.TextColor3 = pct > 60 and Color3.fromRGB(120, 235, 110)
					or (pct > 30 and Color3.fromRGB(250, 190, 60)
					or Color3.fromRGB(250, 90, 90))
			end
		end
	end

	for _, p in ipairs(players:GetPlayers()) do
		if p ~= plr and p.Character then handle(p.Character) end
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and not players:GetPlayerFromCharacter(obj) then
			if obj:FindFirstChildOfClass("Humanoid") then handle(obj) end
		end
	end

	-- anything that died or walked out of range
	for model in pairs(espCache) do
		if not seen[model] then clearEsp(model) end
	end
end)

--------------------------------------------------------------
-- UNIVERSAL TAB UI
--------------------------------------------------------------
local UContainer = Sections.Universal.Container

elements:Header(UContainer, "aimbot")

elements:Toggle("Aimbot (Hold Right Click)", UContainer, false, function(v)
	aimbotEnabled = v
	if not v then lockedTargetPart = nil end
	elements:Notify("aimbot", v and "hold RMB to lock" or "disabled", "info", 2)
end)

elements:Toggle("Wall Check (ignore behind walls)", UContainer, true, function(v)
	wallCheck = v
	elements:Notify("wall check",
		v and "visible targets only" or "will lock through walls",
		v and "ok" or "warn", 2.4)
end)

elements:Toggle("Drop target when it hides", UContainer, true, function(v)
	dropOnLoss = v
end)

elements:Toggle("Draw FOV Circle", UContainer, false, function(v)
	fovEnabled = v
	if fovCircle then fovCircle.Visible = v end
end)

elements:Toggle("Team Check (off = FFA)", UContainer, false, function(v)
	teamCheck = v
end)

elements:Divider(UContainer)
elements:Header(UContainer, "aimbot settings")

elements:Textbox("FOV Radius (30 - 500)", UContainer, tostring(fovRadius), function(txt)
	local n = tonumber(txt)
	if n and n >= 30 and n <= 500 then
		fovRadius = n
		if fovCircle then fovCircle.Radius = n end
		elements:Notify("fov set", tostring(n), "ok", 1.8)
	else
		elements:Notify("invalid fov", "enter 30 - 500", "warn", 2)
	end
end)

elements:Textbox("Aim Speed (1.0 instant, 0.2 smooth)", UContainer, tostring(aimSmooth), function(txt)
	local n = tonumber(txt)
	if n and n >= 0.1 and n <= 1.0 then
		aimSmooth = n
		elements:Notify("aim speed", tostring(n), "ok", 1.8)
	else
		elements:Notify("invalid speed", "enter 0.1 - 1.0", "warn", 2)
	end
end)

elements:Textbox("Aim Part (Head / HumanoidRootPart)", UContainer, aimPart, function(txt)
	if txt == "Head" or txt == "HumanoidRootPart" or txt == "Torso" then
		aimPart = txt
		elements:Notify("aim part", txt, "ok", 1.8)
	else
		elements:Notify("invalid part", "Head / HumanoidRootPart / Torso", "warn", 2)
	end
end)

elements:Divider(UContainer)
elements:Header(UContainer, "esp / wallhack")

elements:Toggle("ESP", UContainer, false, function(v)
	espEnabled = v
	if not v then clearAllEsp() end
	elements:Notify("esp", v and "enabled" or "disabled", "info", 1.8)
end)

elements:Toggle("Chams (see through walls)", UContainer, true, function(v)
	espChams = v
	if not v then
		for _, e in pairs(espCache) do if e.hl then e.hl.Enabled = false end end
	end
end)

elements:Toggle("Names", UContainer, true, function(v) espName = v end)
elements:Toggle("Health + distance", UContainer, true, function(v) espHealth = v end)

elements:Toggle("Tracers", UContainer, false, function(v)
	espTracer = v
	if not v then
		for _, e in pairs(espCache) do
			if e.line then pcall(function() e.line.Visible = false end) end
		end
	end
end)

elements:Toggle("ESP Team Check", UContainer, false, function(v)
	espTeamCheck = v
	clearAllEsp()
end)

elements:Textbox("ESP max distance", UContainer, tostring(espMaxDist), function(txt)
	local n = tonumber(txt)
	if not n or n < 50 or n > 10000 then
		return elements:Notify("invalid", "enter 50 - 10000", "warn", 2)
	end
	espMaxDist = n
	for _, e in pairs(espCache) do
		if e.tag then e.tag.MaxDistance = n end
	end
	elements:Notify("esp range", n .. " studs", "ok", 2)
end)

-- closing the gui should not leave highlights stuck on people
ui.Destroying:Connect(function()
	clearAllEsp()
	pcall(function() espFolder:Destroy() end)
	pcall(function() runservice:UnbindFromRenderStep("LoadedHubAimbotLock") end)
	if fovCircle then pcall(function() fovCircle:Remove() end) end
end)

--------------------------------------------------------------
-- GAMES LIST
--------------------------------------------------------------
local function jumpTo(g)
	if tostring(g.id) == pid or tostring(g.id) == rawPid then
		elements:Notify("already here", g.game, "info")
		return
	end

	local armed = armTeleport()
	if armed then
		elements:Notify("taking you there", g.game .. " - hub reopens on teleport", "ok")
	else
		elements:Notify("taking you there",
			g.game .. " - autoexec unavailable, run script again", "warn")
	end

	task.wait(0.35)

	local okLaunch = pcall(function()
		exservice:LaunchExperience({placeId = tonumber(g.id)})
	end)
	if not okLaunch then
		pcall(function()
			game:GetService("TeleportService"):Teleport(tonumber(g.id), plr)
		end)
	end
end

elements:Searchbar(Sections.GamesList.Container, gameList, jumpTo)

for _, g in ipairs(gameList) do
	elements:addGame(Sections.GamesList.Container, g["game"], g["status"], function()
		jumpTo(g)
	end)
end

--------------------------------------------------------------
-- CREDITS
--------------------------------------------------------------
for sect, c in pairs(creditsList) do
	elements:CredHead(Sections.Credits.Container, sect)
	for _, person in ipairs(c) do
		elements:CredPerson(Sections.Credits.Container, person)
	end
end

--------------------------------------------------------------
-- SETTINGS
--------------------------------------------------------------
local dec1 = readCfg()

local function saveKey(sec, key, v)
	if not hasFS then return end
	pcall(function()
		local dec = readCfg()
		dec[sec] = dec[sec] or {}
		dec[sec][key] = v
		writefile(CFG_FILE, httpservice:JSONEncode(dec))
	end)
end

elements:Toggle("Disable 3D Rendering", Sections.Settings.Container,
	dec1.settings.disable_3d_rendering, function(v)
		saveKey("settings", "disable_3d_rendering", v)
		pcall(function() runservice:Set3dRenderingEnabled(not v) end)
	end)

elements:Toggle("Auto Rejoin (when kicked)", Sections.Settings.Container,
	dec1.settings.auto_rejoin_on_kick, function(v)
		saveKey("settings", "auto_rejoin_on_kick", v)
		if getgenv then getgenv().autorjjjj = v end
	end)

elements:Toggle("Auto Exec on Teleport", Sections.Settings.Container,
	dec1.settings.auto_exec_on_tp ~= false, function(v)
		saveKey("settings", "auto_exec_on_tp", v)
		if v and not queueTp then
			elements:Notify("wont work", "your executor has no queue_on_teleport", "err")
		end
	end)

elements:Toggle("Sounds", Sections.Settings.Container,
	dec1.settings.sounds, function(v)
		saveKey("settings", "sounds", v)
		if getgenv then getgenv().hubSounds = v end
	end)

elements:Divider(Sections.Settings.Container)
elements:Header(Sections.Settings.Container, "teleport")
elements:Label(Sections.Settings.Container,
	"studs per hop. if the game sends you back to spawn, lower it.")

elements:Textbox("Studs per hop", Sections.Settings.Container,
	tostring(dec1.settings.tp_step), function(txt)
		local n = tonumber(txt)
		if not n or n < 20 or n > 500 then
			elements:Notify("weird value", "put something between 20 and 500", "warn")
			return
		end
		saveKey("settings", "tp_step", n)
		elements:Notify("saved", "step = " .. n, "ok")
	end)

elements:Divider(Sections.Settings.Container)
elements:Header(Sections.Settings.Container, "misc")

elements:Button("copy placeid", Sections.Settings.Container, function()
	pcall(function() setclipboard(rawPid) end)
	elements:Notify("copied", rawPid, "ok")
end)

elements:Button("clear cache", Sections.Settings.Container, function()
	if not hasFS then
		return elements:Notify("no filesystem", "your executor cant write files", "err")
	end
	pcall(function()
		if isfile(FOLDER .. "/src_ui.lua") then delfile(FOLDER .. "/src_ui.lua") end
		if isfile(FOLDER .. "/src_elements.lua") then delfile(FOLDER .. "/src_elements.lua") end
	end)
	elements:Notify("cache cleared", "reload the script", "warn")
end)

--------------------------------------------------------------
-- AUTO REJOIN
--------------------------------------------------------------
task.spawn(function()
	local gc = coregui:FindFirstChild("RobloxPromptGui")
	if not gc then return end
	local prompt = gc:FindFirstChild("promptOverlay")
	if not prompt then return end

	prompt.ChildAdded:Connect(function(child)
		local cfg = readCfg()
		if not cfg.settings.auto_rejoin_on_kick then return end
		if child.Name == "ErrorPrompt" then
			pcall(function()
				game:GetService("TeleportService"):Teleport(game.PlaceId, plr)
			end)
		end
	end)
end)

--------------------------------------------------------------
-- KEYBIND
--------------------------------------------------------------
userinputservice.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if MainFrame.Visible then
			MainFrame.Visible = false
			ToggleButton.Visible = true
		else
			MainFrame.Visible = true
			ToggleButton.Visible = false
		end
	end
end)

--------------------------------------------------------------
-- STARTUP
--------------------------------------------------------------
if dec1.settings.disable_3d_rendering then
	pcall(function() runservice:Set3dRenderingEnabled(false) end)
end
if getgenv then
	getgenv().autorjjjj = dec1.settings.auto_rejoin_on_kick
	getgenv().hubSounds = dec1.settings.sounds
end

goTo(loadedModule and Sections.Game or Sections.Home)

task.delay(0.4, function()
	if getgenv and getgenv().HUB_FROM_TP then
		getgenv().HUB_FROM_TP = nil
		elements:Notify("back in", "loaded on its own after teleport", "ok")
	else
		elements:Notify("loaded hub", "right shift to hide", "ok")
	end
end)
