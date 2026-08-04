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
	universal = {
		aimbot        = false,
		wall_check    = true,
		drop_on_loss  = true,
		fov_circle    = false,
		team_check    = false,
		fov_radius    = 150,
		aim_smooth    = 1.0,
		aim_part      = "Head",
		esp           = false,
		esp_chams     = true,
		esp_names     = true,
		esp_health    = true,
		esp_tracers   = false,
		esp_team      = false,
		esp_dist      = 1000,
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
				Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.28, true)
		end

		sect.TabBtn.BackgroundTransparency = 0
		sect.Container:TweenPosition(UDim2.new(0.5, 0, 0, 0),
			Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.28, true)
		sect.Container.Visible = true

		CurSection = sect
	end)
end

local function goTo(sect)
	if CurSection == sect then return end
	if CurSection then
		CurSection.TabBtn.BackgroundTransparency = 1
		CurSection.Container:TweenPosition(UDim2.new(0.5, 0, 1, 0),
			Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.28, true)
	end
	sect.TabBtn.BackgroundTransparency = 0
	sect.Container:TweenPosition(UDim2.new(0.5, 0, 0, 0),
		Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.28, true)
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
-- UNIVERSAL AIMBOT + ESP
-- v5 - everything in here now persists. the values get read out of
-- Config.json before a single control is built, so the toggles come
-- up already flipped instead of snapping into place a frame later.
--
-- v4 was the perf pass: the old code called workspace:GetDescendants()
-- from inside the renderstep, over a millisecond every frame on a 4k
-- part map. thats gone, theres a cached npc registry now.
--------------------------------------------------------------
local UCFG = readCfg().universal or {}

-- little helpers so a missing or half written config cant nil out a
-- toggle. happened once when i added a key and old configs lacked it
local function ub(key, fallback)
	local v = UCFG[key]
	if v == nil then return fallback end
	return v == true
end

local function un(key, fallback, lo, hi)
	local v = tonumber(UCFG[key])
	if not v then return fallback end
	if lo and v < lo then return fallback end
	if hi and v > hi then return fallback end
	return v
end

local function us(key, fallback, allowed)
	local v = UCFG[key]
	if type(v) ~= "string" then return fallback end
	if allowed then
		for _, a in ipairs(allowed) do
			if a == v then return v end
		end
		return fallback
	end
	return v
end

-- saveKey lives further down with the settings tab, but universal
-- needs it up here. so it gets its own tiny one
local function saveUni(key, value)
	if not hasFS then return end
	pcall(function()
		local dec = readCfg()
		dec.universal = dec.universal or {}
		dec.universal[key] = value
		writefile(CFG_FILE, httpservice:JSONEncode(dec))
	end)
end

local camera = workspace.CurrentCamera
local aimbotEnabled = ub("aimbot", false)
local fovEnabled    = ub("fov_circle", false)
local fovRadius     = un("fov_radius", 150, 30, 500)
local aimSmooth     = un("aim_smooth", 1.0, 0.1, 1.0)
local aimPart       = us("aim_part", "Head", {"Head", "HumanoidRootPart", "Torso"})
local teamCheck     = ub("team_check", false)
local isAiming      = false
local lockedTargetPart = nil

local wallCheck  = ub("wall_check", true)
local dropOnLoss = ub("drop_on_loss", true)

-- pulling these out of the global table once. inside a renderstep
-- every _G lookup counts
local vec2      = Vector2.new
local cf        = CFrame.new
local clamp     = math.clamp
local floor     = math.floor
local sqrt      = math.sqrt
local osclock   = os.clock
local tinsert   = table.insert

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
end)

--------------------------------------------------------------
-- NPC REGISTRY
-- instead of sweeping the workspace we keep a table of every model
-- that owns a Humanoid and let the events maintain it. costs
-- nothing per frame, one full sweep on startup and thats it.
--------------------------------------------------------------
local npcSet = {}     -- [model] = humanoid
local npcCount = 0

local function trackModel(model)
	if npcSet[model] then return end
	if model == plr.Character then return end
	if players:GetPlayerFromCharacter(model) then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	npcSet[model] = hum
	npcCount = npcCount + 1
end

local function untrackModel(model)
	if not npcSet[model] then return end
	npcSet[model] = nil
	npcCount = npcCount - 1
end

task.spawn(function()
	-- the one and only full sweep, spread over frames so joining a
	-- big map doesnt hitch
	local all = workspace:GetDescendants()
	for i = 1, #all do
		local o = all[i]
		if o:IsA("Humanoid") then
			local m = o.Parent
			if m and m:IsA("Model") then trackModel(m) end
		end
		if i % 400 == 0 then task.wait() end
	end
end)

workspace.DescendantAdded:Connect(function(d)
	-- only humanoids matter, and the check is one comparison
	if d.ClassName ~= "Humanoid" then return end
	local m = d.Parent
	if m and m:IsA("Model") then
		task.defer(trackModel, m)
	end
end)

workspace.DescendantRemoving:Connect(function(d)
	if d.ClassName == "Humanoid" then
		local m = d.Parent
		if m then untrackModel(m) end
	elseif npcSet[d] then
		untrackModel(d)
	end
end)

--------------------------------------------------------------
-- FOV circle
--------------------------------------------------------------
local fovCircle = nil
pcall(function()
	if Drawing and Drawing.new then
		fovCircle = Drawing.new("Circle")
		fovCircle.Thickness = 2
		fovCircle.Color = Color3.fromRGB(0, 230, 255)
		fovCircle.Filled = false
		fovCircle.Transparency = 0.85
		fovCircle.NumSides = 48
		fovCircle.Radius = fovRadius
		fovCircle.Visible = false
	end
end)

-- was on RenderStepped doing work every frame even with the circle
-- off. now it bails immediately and only moves when its actually up
if fovCircle then
	runservice.RenderStepped:Connect(function()
		if not fovEnabled then
			if fovCircle.Visible then fovCircle.Visible = false end
			return
		end
		local show = MainFrame.Visible
		if fovCircle.Visible ~= show then fovCircle.Visible = show end
		if not show then return end
		local mp = userinputservice:GetMouseLocation()
		fovCircle.Position = vec2(mp.X, mp.Y)
	end)
end

--------------------------------------------------------------
-- LINE OF SIGHT
--------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- rebuilding this table every raycast was churning garbage. two
-- slots, overwritten in place
local skipList = {nil, nil}

local function canSee(part)
	if not wallCheck then return true end
	if not part then return false end

	local origin = camera.CFrame.Position
	local dest   = part.Position
	local dir    = dest - origin
	if dir.Magnitude < 1 then return true end

	skipList[1] = part.Parent
	skipList[2] = plr.Character
	rayParams.FilterDescendantsInstances = skipList

	local hit = workspace:Raycast(origin, dir, rayParams)
	if not hit then return true end

	-- the ray lands on the edge of the hitbox, not the centre. without
	-- this margin you get false negatives constantly
	local d = hit.Position - dest
	return (d.X * d.X + d.Y * d.Y + d.Z * d.Z) < 6.25   -- 2.5 squared
end

--------------------------------------------------------------
local function getTargetHeadPart(model)
	local part = model:FindFirstChild(aimPart)
	if part then return part end
	return model:FindFirstChild("Head")
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChild("Torso")
end

local function isValidLockedTarget(part)
	if not part or not part.Parent then return false end
	local model = part.Parent
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end

	local mp = userinputservice:GetMouseLocation()
	local sp, onScreen = camera:WorldToViewportPoint(part.Position)
	if not onScreen then return false end

	-- squared compare, no sqrt. 1.6x margin keeps the lock sticky
	local dx = sp.X - mp.X
	local dy = sp.Y - mp.Y
	local lim = fovRadius * 1.6
	if (dx * dx + dy * dy) > (lim * lim) then return false end

	if dropOnLoss and not canSee(part) then return false end
	return true
end

-- the search. one pass, no allocations, raycast only on the winner.
-- before this it raycast every candidate inside the loop which is
-- the second reason it stuttered in a crowded lobby
local function getClosestTargetToMouse()
	local mp = userinputservice:GetMouseLocation()
	local mx, my = mp.X, mp.Y
	local limit = fovRadius * fovRadius

	local bestPart, bestDist = nil, limit
	-- keep the runners up so if the closest one is behind a wall we
	-- can fall through to the next instead of giving up
	local p2, d2, p3, d3

	local function consider(model, hum)
		if hum.Health <= 0 then return end
		local part = getTargetHeadPart(model)
		if not part then return end

		local sp, onScreen = camera:WorldToViewportPoint(part.Position)
		if not onScreen then return end

		local dx = sp.X - mx
		local dy = sp.Y - my
		local d = dx * dx + dy * dy
		if d >= bestDist then
			if d < (d2 or limit) then p3, d3 = p2, d2; p2, d2 = part, d
			elseif d < (d3 or limit) then p3, d3 = part, d end
			return
		end
		p3, d3 = p2, d2
		p2, d2 = bestPart, bestDist
		bestPart, bestDist = part, d
	end

	local myTeam = plr.Team
	for _, p in ipairs(players:GetPlayers()) do
		if p ~= plr then
			local ch = p.Character
			if ch then
				if not (teamCheck and myTeam and p.Team == myTeam) then
					local hum = ch:FindFirstChildOfClass("Humanoid")
					if hum then consider(ch, hum) end
				end
			end
		end
	end

	-- cached npcs, no workspace sweep
	for model, hum in pairs(npcSet) do
		if model.Parent then
			consider(model, hum)
		else
			untrackModel(model)
		end
	end

	-- at most three raycasts instead of one per candidate
	if bestPart and canSee(bestPart) then return bestPart end
	if p2 and canSee(p2) then return p2 end
	if p3 and canSee(p3) then return p3 end
	return nil
end

userinputservice.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
		if aimbotEnabled then
			lockedTargetPart = getClosestTargetToMouse()
		end
	end
end)

userinputservice.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
		lockedTargetPart = nil
	end
end)

--------------------------------------------------------------
-- the hot path.
-- moving the camera has to happen every frame or it looks choppy,
-- but re-picking a target does not. so: aim always, re-scan at most
-- 20 times a second, and only when the current one went invalid.
--------------------------------------------------------------
local nextScan = 0
local RESCAN_EVERY = 0.05

runservice:BindToRenderStep("LoadedHubAimbotLock", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not aimbotEnabled or not isAiming then return end

	local part = lockedTargetPart
	if not part or not isValidLockedTarget(part) then
		local now = osclock()
		if now >= nextScan then
			nextScan = now + RESCAN_EVERY
			part = getClosestTargetToMouse()
			lockedTargetPart = part
		else
			part = nil
		end
	end

	if not part then return end

	local camCF = camera.CFrame
	local desired = cf(camCF.Position, part.Position)
	if aimSmooth >= 0.95 then
		camera.CFrame = desired
	else
		camera.CFrame = camCF:Lerp(desired, clamp(dt * (aimSmooth * 28), 0.05, 1))
	end
end)

--------------------------------------------------------------
-- ESP
-- highlights for the body, billboard for the text. tried Drawing
-- boxes first, they fight the camera every frame and wobble.
--------------------------------------------------------------
local espEnabled   = ub("esp", false)
local espChams     = ub("esp_chams", true)
local espName      = ub("esp_names", true)
local espHealth    = ub("esp_health", true)
local espTracer    = ub("esp_tracers", false)
local espTeamCheck = ub("esp_team", false)
local espMaxDist   = un("esp_dist", 1000, 50, 10000)

local espFolder = Instance.new("Folder")
espFolder.Name = "\0LH_esp"
espFolder.Parent = hui and hui() or coregui

local espCache = {}
local espActive = {}   -- flat array so the tracer loop isnt a pairs()

local function rebuildActive()
	local n = 0
	for _, e in pairs(espCache) do
		n = n + 1
		espActive[n] = e
	end
	for i = n + 1, #espActive do espActive[i] = nil end
end

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
	for i = 1, #espActive do espActive[i] = nil end
end

local C_ALLY   = Color3.fromRGB(90, 200, 255)
local C_ENEMY  = Color3.fromRGB(255, 80, 80)
local C_NPC    = Color3.fromRGB(255, 190, 60)
local C_HP_OK  = Color3.fromRGB(120, 235, 110)
local C_HP_MID = Color3.fromRGB(250, 190, 60)
local C_HP_LOW = Color3.fromRGB(250, 90, 90)
local C_WHITE  = Color3.fromRGB(255, 255, 255)
local C_BLACK  = Color3.fromRGB(0, 0, 0)

local function espColor(model)
	local p = players:GetPlayerFromCharacter(model)
	if not p then return C_NPC end
	if plr.Team and p.Team then
		return p.Team == plr.Team and C_ALLY or C_ENEMY
	end
	return C_ENEMY
end

local function buildEsp(model)
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
	if not root then return nil end

	local col = espColor(model)
	local e = {root = root, lastHp = -1, lastCol = col}

	local hl = Instance.new("Highlight")
	hl.Adornee = model
	hl.FillColor = col
	hl.FillTransparency = 0.62
	hl.OutlineColor = C_WHITE
	hl.OutlineTransparency = 0.15
	-- this line is what makes it draw through walls
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
	nm.TextColor3 = col
	nm.TextSize = 14
	nm.Font = Enum.Font.FredokaOne
	local pl = players:GetPlayerFromCharacter(model)
	nm.Text = pl and pl.DisplayName or model.Name
	nm.Parent = tag
	local ns = Instance.new("UIStroke")
	ns.Thickness = 2
	ns.Color = C_BLACK
	ns.Parent = nm
	e.nm = nm

	local hp = Instance.new("TextLabel")
	hp.Size = UDim2.new(1, 0, 0, 15)
	hp.Position = UDim2.new(0, 0, 0, 16)
	hp.BackgroundTransparency = 1
	hp.TextColor3 = C_HP_OK
	hp.TextSize = 12
	hp.Font = Enum.Font.FredokaOne
	hp.Text = ""
	hp.Parent = tag
	local hs = Instance.new("UIStroke")
	hs.Thickness = 2
	hs.Color = C_BLACK
	hs.Parent = hp
	e.hp = hp
	e.tag = tag

	if Drawing and Drawing.new then
		pcall(function()
			local l = Drawing.new("Line")
			l.Thickness = 1
			l.Color = C_WHITE
			l.Transparency = 0.6
			l.Visible = false
			e.line = l
		end)
	end

	espCache[model] = e
	return e
end

--------------------------------------------------------------
-- two loops on purpose.
-- the slow one rebuilds the list and rewrites text 8x a second,
-- because names and health simply do not need 240hz.
-- the fast one only touches tracers, and only when theyre on.
--------------------------------------------------------------
local espAccum = 0
local ESP_EVERY = 0.125

runservice.Heartbeat:Connect(function(dt)
	if not espEnabled then return end

	espAccum = espAccum + dt
	if espAccum < ESP_EVERY then return end
	espAccum = 0

	local myChar = plr.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local myPos  = myRoot and myRoot.Position
	local maxSq  = espMaxDist * espMaxDist
	local myTeam = plr.Team

	local seen = {}

	local function handle(model, hum, isPlayer, p)
		if hum.Health <= 0 then return end
		if espTeamCheck and isPlayer and myTeam and p.Team == myTeam then return end

		local e = espCache[model]
		local root = e and e.root
		if not root or not root.Parent then
			root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
			if not root then return end
		end

		if myPos then
			local d = root.Position - myPos
			local dsq = d.X * d.X + d.Y * d.Y + d.Z * d.Z
			if dsq > maxSq then return end
			seen[model] = true
			e = e or buildEsp(model)
			if not e then return end
			e.dist = floor(sqrt(dsq))
		else
			seen[model] = true
			e = e or buildEsp(model)
			if not e then return end
			e.dist = 0
		end

		if e.hl.Enabled ~= espChams then e.hl.Enabled = espChams end

		local wantTag = espName or espHealth
		if e.tag.Enabled ~= wantTag then e.tag.Enabled = wantTag end
		if not wantTag then return end

		if e.nm.Visible ~= espName then e.nm.Visible = espName end
		if e.hp.Visible ~= espHealth then e.hp.Visible = espHealth end

		local col = espColor(model)
		if col ~= e.lastCol then
			e.lastCol = col
			e.hl.FillColor = col
			e.nm.TextColor3 = col
		end

		if espHealth then
			local pct = floor((hum.Health / (hum.MaxHealth > 0 and hum.MaxHealth or 1)) * 100)
			-- only rewrite the string when the numbers actually moved.
			-- setting .Text every tick makes roblox re-measure the label
			if pct ~= e.lastHp or e.dist ~= e.lastDist then
				e.lastHp = pct
				e.lastDist = e.dist
				e.hp.Text = pct .. "%  " .. e.dist .. "m"
				e.hp.TextColor3 = pct > 60 and C_HP_OK
					or (pct > 30 and C_HP_MID or C_HP_LOW)
			end
		end
	end

	for _, p in ipairs(players:GetPlayers()) do
		if p ~= plr then
			local ch = p.Character
			if ch then
				local hum = ch:FindFirstChildOfClass("Humanoid")
				if hum then handle(ch, hum, true, p) end
			end
		end
	end

	-- same cached registry the aimbot uses, no workspace sweep here either
	for model, hum in pairs(npcSet) do
		if model.Parent then
			handle(model, hum, false, nil)
		else
			untrackModel(model)
		end
	end

	for model in pairs(espCache) do
		if not seen[model] then clearEsp(model) end
	end

	rebuildActive()
end)

-- tracers get their own connection so it can be disconnected outright
local tracerConn = nil

local function setTracers(on)
	espTracer = on
	if on and not tracerConn then
		tracerConn = runservice.RenderStepped:Connect(function()
			local vp = camera.ViewportSize
			local bx, by = vp.X * 0.5, vp.Y
			for i = 1, #espActive do
				local e = espActive[i]
				local l = e.line
				if l then
					local root = e.root
					if root and root.Parent then
						local sp, on2 = camera:WorldToViewportPoint(root.Position)
						if on2 then
							l.From = vec2(bx, by)
							l.To = vec2(sp.X, sp.Y)
							l.Color = e.lastCol or C_WHITE
							if not l.Visible then l.Visible = true end
						elseif l.Visible then
							l.Visible = false
						end
					elseif l.Visible then
						l.Visible = false
					end
				end
			end
		end)
	elseif not on and tracerConn then
		tracerConn:Disconnect()
		tracerConn = nil
		for i = 1, #espActive do
			local l = espActive[i].line
			if l then pcall(function() l.Visible = false end) end
		end
	end
end

--------------------------------------------------------------
-- UNIVERSAL TAB UI
-- every control writes its value straight to Config.json, and every
-- one of them starts from what was in there. the refs go in a table
-- so the load button can push values back into the widgets
--------------------------------------------------------------
local UContainer = Sections.Universal.Container
local W = {}   -- widget handles, keyed the same as the config

elements:Header(UContainer, "aimbot")

local lblCfg = elements:Stat(UContainer, "config",
	hasFS and "saved automatically" or "no filesystem", hasFS and "ok" or "err")

W.aimbot = elements:Toggle("Aimbot (Hold Right Click)", UContainer, aimbotEnabled, function(v)
	aimbotEnabled = v
	if not v then lockedTargetPart = nil end
	saveUni("aimbot", v)
	elements:Notify("aimbot", v and "hold RMB to lock" or "disabled", "info", 2)
end)

W.wall_check = elements:Toggle("Wall Check (ignore behind walls)", UContainer, wallCheck, function(v)
	wallCheck = v
	saveUni("wall_check", v)
	elements:Notify("wall check",
		v and "visible targets only" or "will lock through walls",
		v and "ok" or "warn", 2.4)
end)

W.drop_on_loss = elements:Toggle("Drop target when it hides", UContainer, dropOnLoss, function(v)
	dropOnLoss = v
	saveUni("drop_on_loss", v)
end)

W.fov_circle = elements:Toggle("Draw FOV Circle", UContainer, fovEnabled, function(v)
	fovEnabled = v
	if fovCircle and not v then fovCircle.Visible = false end
	saveUni("fov_circle", v)
end)

W.team_check = elements:Toggle("Team Check (off = FFA)", UContainer, teamCheck, function(v)
	teamCheck = v
	saveUni("team_check", v)
end)

elements:Divider(UContainer)
elements:Header(UContainer, "aimbot settings")

W.fov_radius = elements:Textbox("FOV Radius (30 - 500)", UContainer, tostring(fovRadius), function(txt)
	local n = tonumber(txt)
	if n and n >= 30 and n <= 500 then
		fovRadius = n
		if fovCircle then fovCircle.Radius = n end
		saveUni("fov_radius", n)
		elements:Notify("fov set", tostring(n), "ok", 1.8)
	else
		elements:Notify("invalid fov", "enter 30 - 500", "warn", 2)
	end
end)

W.aim_smooth = elements:Textbox("Aim Speed (1.0 instant, 0.2 smooth)", UContainer, tostring(aimSmooth), function(txt)
	local n = tonumber(txt)
	if n and n >= 0.1 and n <= 1.0 then
		aimSmooth = n
		saveUni("aim_smooth", n)
		elements:Notify("aim speed", tostring(n), "ok", 1.8)
	else
		elements:Notify("invalid speed", "enter 0.1 - 1.0", "warn", 2)
	end
end)

W.aim_part = elements:Textbox("Aim Part (Head / HumanoidRootPart)", UContainer, aimPart, function(txt)
	if txt == "Head" or txt == "HumanoidRootPart" or txt == "Torso" then
		aimPart = txt
		saveUni("aim_part", txt)
		elements:Notify("aim part", txt, "ok", 1.8)
	else
		elements:Notify("invalid part", "Head / HumanoidRootPart / Torso", "warn", 2)
	end
end)

elements:Divider(UContainer)
elements:Header(UContainer, "esp / wallhack")

W.esp = elements:Toggle("ESP", UContainer, espEnabled, function(v)
	espEnabled = v
	if not v then
		setTracers(false)
		clearAllEsp()
	end
	saveUni("esp", v)
	elements:Notify("esp", v and "enabled" or "disabled", "info", 1.8)
end)

W.esp_chams = elements:Toggle("Chams (see through walls)", UContainer, espChams, function(v)
	espChams = v
	if not v then
		for _, e in pairs(espCache) do if e.hl then e.hl.Enabled = false end end
	end
	saveUni("esp_chams", v)
end)

W.esp_names = elements:Toggle("Names", UContainer, espName, function(v)
	espName = v
	saveUni("esp_names", v)
end)

W.esp_health = elements:Toggle("Health + distance", UContainer, espHealth, function(v)
	espHealth = v
	saveUni("esp_health", v)
end)

W.esp_tracers = elements:Toggle("Tracers", UContainer, espTracer, function(v)
	setTracers(v)
	saveUni("esp_tracers", v)
end)

W.esp_team = elements:Toggle("ESP Team Check", UContainer, espTeamCheck, function(v)
	espTeamCheck = v
	clearAllEsp()
	saveUni("esp_team", v)
end)

W.esp_dist = elements:Textbox("ESP max distance", UContainer, tostring(espMaxDist), function(txt)
	local n = tonumber(txt)
	if not n or n < 50 or n > 10000 then
		return elements:Notify("invalid", "enter 50 - 10000", "warn", 2)
	end
	espMaxDist = n
	for _, e in pairs(espCache) do
		if e.tag then e.tag.MaxDistance = n end
	end
	saveUni("esp_dist", n)
	elements:Notify("esp range", n .. " studs", "ok", 2)
end)

--------------------------------------------------------------
-- CONFIG
-- pushing a value back into a widget is the fiddly part. Toggle
-- hands back {Set,Get} and Textbox hands back the TextBox itself,
-- so they need different treatment
--------------------------------------------------------------
local UNI_DEFAULTS = {
	aimbot = false, wall_check = true, drop_on_loss = true,
	fov_circle = false, team_check = false,
	fov_radius = 150, aim_smooth = 1.0, aim_part = "Head",
	esp = false, esp_chams = true, esp_names = true,
	esp_health = true, esp_tracers = false, esp_team = false,
	esp_dist = 1000,
}

-- applies a whole table to the live variables AND to the widgets.
-- silent = dont fire the callbacks, we already did the work here
local function applyUniversal(t)
	if type(t) ~= "table" then return false end

	local function b(k, cur) local v = t[k] if v == nil then return cur end return v == true end
	local function n(k, cur, lo, hi)
		local v = tonumber(t[k])
		if not v or (lo and v < lo) or (hi and v > hi) then return cur end
		return v
	end

	aimbotEnabled = b("aimbot", aimbotEnabled)
	wallCheck     = b("wall_check", wallCheck)
	dropOnLoss    = b("drop_on_loss", dropOnLoss)
	fovEnabled    = b("fov_circle", fovEnabled)
	teamCheck     = b("team_check", teamCheck)
	fovRadius     = n("fov_radius", fovRadius, 30, 500)
	aimSmooth     = n("aim_smooth", aimSmooth, 0.1, 1.0)
	if t.aim_part == "Head" or t.aim_part == "HumanoidRootPart" or t.aim_part == "Torso" then
		aimPart = t.aim_part
	end

	espChams    = b("esp_chams", espChams)
	espName     = b("esp_names", espName)
	espHealth   = b("esp_health", espHealth)
	espTeamCheck= b("esp_team", espTeamCheck)
	espMaxDist  = n("esp_dist", espMaxDist, 50, 10000)

	-- these two own live objects, so they go through their setters
	local wantEsp = b("esp", espEnabled)
	if wantEsp ~= espEnabled then
		espEnabled = wantEsp
		if not wantEsp then clearAllEsp() end
	end
	setTracers(b("esp_tracers", espTracer))

	if fovCircle then
		fovCircle.Radius = fovRadius
		if not fovEnabled then fovCircle.Visible = false end
	end
	for _, e in pairs(espCache) do
		if e.tag then e.tag.MaxDistance = espMaxDist end
	end
	if not aimbotEnabled then lockedTargetPart = nil end

	-- now move the widgets so the panel matches reality
	local function setTog(key, val)
		local w = W[key]
		if w and w.Set then pcall(w.Set, val) end
	end
	local function setBox(key, val)
		local w = W[key]
		if w and w.Text ~= nil then pcall(function() w.Text = tostring(val) end) end
	end

	setTog("aimbot", aimbotEnabled)
	setTog("wall_check", wallCheck)
	setTog("drop_on_loss", dropOnLoss)
	setTog("fov_circle", fovEnabled)
	setTog("team_check", teamCheck)
	setTog("esp", espEnabled)
	setTog("esp_chams", espChams)
	setTog("esp_names", espName)
	setTog("esp_health", espHealth)
	setTog("esp_tracers", espTracer)
	setTog("esp_team", espTeamCheck)

	setBox("fov_radius", fovRadius)
	setBox("aim_smooth", aimSmooth)
	setBox("aim_part", aimPart)
	setBox("esp_dist", espMaxDist)

	return true
end

local function currentUniversal()
	return {
		aimbot = aimbotEnabled, wall_check = wallCheck,
		drop_on_loss = dropOnLoss, fov_circle = fovEnabled,
		team_check = teamCheck, fov_radius = fovRadius,
		aim_smooth = aimSmooth, aim_part = aimPart,
		esp = espEnabled, esp_chams = espChams, esp_names = espName,
		esp_health = espHealth, esp_tracers = espTracer,
		esp_team = espTeamCheck, esp_dist = espMaxDist,
	}
end

elements:Divider(UContainer)
elements:Header(UContainer, "config")

elements:Label(UContainer,
	"everything above saves on its own. these are here for when you "
	.. "want to force it, undo a mess, or move the setup to another pc.")

elements:Button("save now", UContainer, function()
	if not hasFS then
		return elements:Notify("cant save", "your executor has no file access", "err", 3)
	end
	local ok = pcall(function()
		local dec = readCfg()
		dec.universal = currentUniversal()
		writefile(CFG_FILE, httpservice:JSONEncode(dec))
	end)
	lblCfg.Text = ok and "saved" or "save failed"
	elements:Notify(ok and "saved" or "failed",
		ok and "universal config written" or "couldnt write the file",
		ok and "ok" or "err", 2.2)
end)

elements:Button("load config", UContainer, function()
	if not hasFS then
		return elements:Notify("cant load", "your executor has no file access", "err", 3)
	end
	local dec = readCfg()
	if type(dec.universal) ~= "table" then
		return elements:Notify("nothing saved", "hit save first", "warn", 2.4)
	end
	applyUniversal(dec.universal)
	lblCfg.Text = "loaded from disk"
	elements:Notify("loaded", "config applied", "ok", 2.2)
end)

elements:Button("reset to defaults", UContainer, function()
	applyUniversal(UNI_DEFAULTS)
	if hasFS then
		pcall(function()
			local dec = readCfg()
			dec.universal = currentUniversal()
			writefile(CFG_FILE, httpservice:JSONEncode(dec))
		end)
	end
	lblCfg.Text = "back to defaults"
	elements:Notify("reset", "everything back to stock", "warn", 2.4)
end)

elements:Button("copy config", UContainer, function()
	local ok = pcall(function()
		setclipboard(httpservice:JSONEncode(currentUniversal()))
	end)
	elements:Notify(ok and "copied" or "couldnt copy",
		ok and "paste it in the box below to share it" or "no setclipboard",
		ok and "ok" or "err", 3)
end)

elements:Textbox("paste config here", UContainer, "", function(txt)
	if txt == "" then return end
	local ok, dec = pcall(function() return httpservice:JSONDecode(txt) end)
	if not ok or type(dec) ~= "table" then
		return elements:Notify("bad config", "that isnt valid json", "err", 3)
	end
	applyUniversal(dec)
	if hasFS then
		pcall(function()
			local c = readCfg()
			c.universal = currentUniversal()
			writefile(CFG_FILE, httpservice:JSONEncode(c))
		end)
	end
	lblCfg.Text = "imported"
	elements:Notify("imported", "config applied and saved", "ok", 2.6)
end)

-- the saved state has to reach the live objects too, not just the
-- variables. tracers own a connection, so it goes through its setter
if espTracer then
	espTracer = false      -- setTracers bails early if it thinks its on
	setTracers(true)
end
if fovCircle then fovCircle.Radius = fovRadius end

-- closing the gui should not leave highlights stuck on people
ui.Destroying:Connect(function()
	setTracers(false)
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
