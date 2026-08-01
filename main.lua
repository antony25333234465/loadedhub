--// LOADED HUB - loader
--// Stud UI Pack Edition - Anti-Jitter Universal Aimbot (Sticky Target Lock)
--// Features: Sticky Target Lock (No Screen Shake/Jitter), FOV Circle, FFA Support

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
			local dec = httpservice:JSONEncode(readfile(CFG_FILE))
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
		return httpservice:JSONEncode(readfile(CFG_FILE))
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
	or (secure_load and nil)

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
	return (ok and type(dec) == "table") and dec or fallback
end

--------------------------------------------------------------
-- UI INITIALIZATION
--------------------------------------------------------------
pcall(function()
	local root = hui and hui() or coregui
	local old = root:FindFirstChild("\0LoadedHub")
	if old then old:Destroy() end
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
	{ game = "Cut Grass for Brainrots",           id = "97365843755210",  status = "🟢" },
	{ game = "Obby as a Brainrot",                id = "77862067599263",  status = "🟢" },
	{ game = "Scary Shawarma Kiosk: The Anomaly", id = "137826330724902", status = "🟢" },
	{ game = "Scary Shawarma (In Game)",          id = "128001665358186", status = "🟢" }
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
-- UNIVERSAL AIMBOT & FOV ENGINE (STICKY TARGET LOCK - NO JITTER / SCREEN SHAKE)
--------------------------------------------------------------
local camera = workspace.CurrentCamera
local aimbotEnabled = false
local fovEnabled    = false
local fovRadius     = 150
local aimSmooth     = 1.0     -- 1.0 = Instant Head Lock, 0.2 = Smooth
local aimPart       = "Head"
local teamCheck     = false   -- Off by default for FFA compatibility!
local isAiming      = false
local lockedTargetPart = nil   -- Sticky Lock (Eliminates Target Swapping Shaking!)

-- Drawing FOV Circle
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

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
end)

runservice.RenderStepped:Connect(function()
	if fovCircle then
		fovCircle.Radius = fovRadius
		fovCircle.Visible = fovEnabled and MainFrame.Visible
		if fovCircle.Visible then
			local mousePos = userinputservice:GetMouseLocation()
			fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
		end
	end
end)

local function getTargetHeadPart(model)
	if not model or not model:IsA("Model") or not model.Parent then return nil end
	local part = model:FindFirstChild(aimPart)
	if not part then
		part = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
	end
	return part
end

local function isValidLockedTarget(part)
	if not part or not part.Parent then return false end
	local model = part.Parent
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end

	local mousePos = userinputservice:GetMouseLocation()
	local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
	if not onScreen then return false end

	-- Allow 1.6x FOV margin while tracking target so lock stays sticky
	local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
	if dist > (fovRadius * 1.6) then return false end

	return true
end

local function getClosestTargetToMouse()
	local closestPart = nil
	local shortestDist = fovRadius
	local mousePos = userinputservice:GetMouseLocation()

	-- 1. Scan Players
	for _, p in ipairs(players:GetPlayers()) do
		if p ~= plr and p.Character then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local sameTeam = false
				if teamCheck and p.Team and plr.Team and p.Team == plr.Team then
					sameTeam = true
				end

				if not sameTeam then
					local part = getTargetHeadPart(p.Character)
					if part then
						local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
						if onScreen then
							local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
							if dist < shortestDist then
								shortestDist = dist
								closestPart = part
							end
						end
					end
				end
			end
		end
	end

	-- 2. Scan NPCs / Bots
	if not closestPart then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj ~= plr.Character and not players:GetPlayerFromCharacter(obj) then
				local hum = obj:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					local part = getTargetHeadPart(obj)
					if part then
						local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
						if onScreen then
							local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
							if dist < shortestDist then
								shortestDist = dist
								closestPart = part
							end
						end
					end
				end
			end
		end
	end

	return closestPart
end

-- Aimbot Key / Mouse Input (RMB Hold with Sticky Lock)
userinputservice.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
		lockedTargetPart = getClosestTargetToMouse() -- Lock onto target!
	end
end)

userinputservice.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
		lockedTargetPart = nil -- Release target lock!
	end
end)

-- High Priority Anti-Jitter Camera RenderStep
runservice:BindToRenderStep("LoadedHubAimbotLock", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if aimbotEnabled and isAiming then
		-- Validate or acquire target lock
		if not isValidLockedTarget(lockedTargetPart) then
			lockedTargetPart = getClosestTargetToMouse()
		end

		if lockedTargetPart then
			local targetPos = lockedTargetPart.Position
			local camPos = camera.CFrame.Position
			local desiredCF = CFrame.new(camPos, targetPos)

			if aimSmooth >= 0.95 then
				camera.CFrame = desiredCF
			else
				-- Framerate-independent smooth interpolation (No Jitter)
				local lerpFactor = math.clamp(dt * (aimSmooth * 28), 0.05, 1)
				camera.CFrame = camera.CFrame:Lerp(desiredCF, lerpFactor)
			end
		end
	end
end)

-- Universal UI Elements
local UContainer = Sections.Universal.Container
elements:Header(UContainer, "universal aimbot & fov")

elements:Toggle("Aimbot (Hold Right Click)", UContainer, false, function(v)
	aimbotEnabled = v
	if not v then lockedTargetPart = nil end
	elements:Notify("aimbot", v and "enabled (Hold RMB to Lock Head)" or "disabled", "info", 2)
end)

elements:Toggle("Draw FOV Circle", UContainer, false, function(v)
	fovEnabled = v
	if fovCircle then fovCircle.Visible = v end
	elements:Notify("fov circle", v and "enabled" or "disabled", "info", 1.8)
end)

elements:Toggle("Team Check (Disable for FFA)", UContainer, false, function(v)
	teamCheck = v
	elements:Notify("team check", v and "enabled" or "disabled (FFA Mode)", "info", 1.8)
end)

elements:Divider(UContainer)
elements:Header(UContainer, "aimbot settings")

elements:Textbox("FOV Radius (30 - 500)", UContainer, tostring(fovRadius), function(txt)
	local num = tonumber(txt)
	if num and num >= 30 and num <= 500 then
		fovRadius = num
		if fovCircle then fovCircle.Radius = num end
		elements:Notify("fov set", tostring(num), "ok", 1.8)
	else
		elements:Notify("invalid fov", "enter number 30 - 500", "warn", 2)
	end
end)

elements:Textbox("Aim Speed (1.0 = Instant, 0.2 = Smooth)", UContainer, tostring(aimSmooth), function(txt)
	local num = tonumber(txt)
	if num and num >= 0.1 and num <= 1.0 then
		aimSmooth = num
		elements:Notify("aim speed set", tostring(num), "ok", 1.8)
	else
		elements:Notify("invalid speed", "enter number 0.1 - 1.0", "warn", 2)
	end
end)

elements:Textbox("Aim Part (Head / HumanoidRootPart)", UContainer, aimPart, function(txt)
	if txt == "Head" or txt == "HumanoidRootPart" or txt == "Torso" then
		aimPart = txt
		elements:Notify("aim part set", txt, "ok", 1.8)
	else
		elements:Notify("invalid part", "use Head or HumanoidRootPart", "warn", 2)
	end
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
		elements:Notify("taking you there", g.game .. " · hub reopens on teleport", "ok")
	else
		elements:Notify("taking you there",
			g.game .. " · autoexec unavailable, run script again", "warn")
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
