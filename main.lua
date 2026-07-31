--// BRAINROT HUB - loader
--// same layout as the original: ui + elements + per game modules
--// everything is fetched from the repo, so you only push files

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
-- REPO
-- point this at your raw github. everything else hangs off it
--------------------------------------------------------------
local BASE = getgenv and getgenv().HUB_BASE
	or "https://raw.githubusercontent.com/antony25333234465/loadedhub/refs/heads/main/"

function getgitpath(what)
	if what == "games" then return BASE .. "games/" end
	if what == "src"   then return BASE .. "src/"   end
	return BASE
end

local FOLDER   = "BrainrotHub"
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
			-- fill whats missing, in case i add new options later
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
-- FETCH
-- tries the repo first, falls back to the local copy on disk.
-- that way it still works if github is down or you are offline
--------------------------------------------------------------
-- raw.githubusercontent caches for ~5 min. sticking a junk param on the
-- end makes it a different url so it always gives me the fresh one
local function bust(url)
	return url .. "?nocache=" .. tostring(math.random(100000, 999999)) .. tostring(os.time())
end

local function fetch(url, cachePath)
	local ok, body = pcall(function() return game:HttpGet(bust(url)) end)

	if not ok then
		warn("[hub] http failed on " .. url .. " -> " .. tostring(body))
	elseif body == "404: Not Found" then
		warn("[hub] 404, that file is not on the repo: " .. url)
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
		warn("[hub] falling back to the copy on disk: " .. cachePath)
		local ok2, cached = pcall(function() return readfile(cachePath) end)
		if ok2 then return cached end
	end
	return nil
end

-- json that shouts when it breaks. the silent pcall was hiding a
-- trailing comma for ages and the list just showed up empty
local function decode(raw, what, fallback)
	if not raw then
		warn("[hub] no " .. what .. ", couldnt download it")
		return fallback
	end
	local ok, dec = pcall(function() return httpservice:JSONDecode(raw) end)
	if not ok then
		warn("[hub] " .. what .. " is broken json -> " .. tostring(dec))
		warn("[hub] check for a comma after the last } , thats the usual one")
		return fallback
	end
	if type(dec) ~= "table" then
		warn("[hub] " .. what .. " didnt decode into a table")
		return fallback
	end
	return dec
end

--------------------------------------------------------------
-- UI
--------------------------------------------------------------
-- close the old one first, otherwise they stack up
pcall(function()
	local root = hui and hui() or coregui
	local old = root:FindFirstChild("\0BrainrotHub")
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
-- drag
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
-- HOME labels
--------------------------------------------------------------
local H = Sections.Home.Container

H.discan.Text     = H.discan.Text:gsub("redacted", DISCORD)
H.bugsLabel.Text  = H.bugsLabel.Text:gsub("redacted", DISCORD)
H.execLabel.Text  = "Executor: " .. tostring((pcall(getexec) and getexec()) or "unknown")
H.versionLabel.Text = "Version: " .. VERSION
H.placeLabel.Text = "PlaceId: " .. tostring(game.PlaceId)

--------------------------------------------------------------
-- REMOTE DATA
--------------------------------------------------------------
local elementsSrc = fetch(getgitpath("src") .. "elements.lua", FOLDER .. "/src_elements.lua")
if not elementsSrc then
	warn("[hub] couldnt fetch elements.lua")
	return
end
local elements = loadstring(elementsSrc)()

local gameListRaw = fetch(getgitpath("src") .. "gameslist.json", FOLDER .. "/gameslist.json")
local creditsRaw  = fetch(getgitpath("src") .. "credits.json",   FOLDER .. "/credits.json")

local gameList    = decode(gameListRaw, "gameslist.json", {})
local creditsList = decode(creditsRaw,   "credits.json",   {})

-- tells me if the game im in shows up on the list
local function gameFromList(pid)
	pid = tostring(pid)
	for _, g in ipairs(gameList) do
		if tostring(g.id) == pid then return g end
	end
	return nil
end

--------------------------------------------------------------
-- GAME  (PlaceId detection)
--------------------------------------------------------------
local pid = tostring(game.PlaceId)
local hereGame = gameFromList(pid)

-- debug: getgenv().FORCE_MODULE = "97365843755210" loads that module
-- in any game so you can test without joining the right one
local wantId = (getgenv and getgenv().FORCE_MODULE) and tostring(getgenv().FORCE_MODULE) or pid

local okGame, gamePath = pcall(function()
	return game:HttpGet(getgitpath("games") .. wantId .. ".lua")
end)

local loadedModule = false

if not okGame or not gamePath or #gamePath == 0 or gamePath == "404: Not Found" then
	-- nothing on the repo, try a local file
	local handledLocally = false

	if hasFS and isfile(FOLDER .. "/games/" .. wantId .. ".lua") then
		local okLocal, err = pcall(function()
			local mod = loadstring(readfile(FOLDER .. "/games/" .. wantId .. ".lua"))()
			mod(Sections.Game.Container, readCfg(), elements)
		end)
		if okLocal then
			handledLocally = true
			loadedModule = true
		else
			warn("[hub] local module blew up:", err)
		end
	end

	if not handledLocally then
		if hereGame then
			-- its on the list but has no module yet
			elements:Header(Sections.Game.Container, hereGame.game)
			elements:Stat(Sections.Game.Container, "cheat", "coming soon", "warn")
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
	-- cache it so it still works offline next time
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
		Sections.Game.TabBtn.TextColor3 = Color3.fromRGB(157, 122, 232)
	end)
end

--------------------------------------------------------------
-- GAMES LIST
--------------------------------------------------------------
elements:Searchbar(Sections.GamesList.Container, gameList)

-- if the list came back empty its always the json, so say it out loud
-- instead of leaving the tab blank like it did before
if #gameList == 0 then
	elements:Header(Sections.GamesList.Container, "empty list")
	elements:Stat(Sections.GamesList.Container, "gameslist.json", "not loaded", "err")
	elements:Label(Sections.GamesList.Container,
		"either its not up on the repo yet or the json is malformed. "
		.. "the classic one is a comma after the last }")
	elements:Button("retry", Sections.GamesList.Container, function()
		elements:Notify("reload", "run the script again", "warn")
	end)
end

for _, g in ipairs(gameList) do
	elements:addGame(Sections.GamesList.Container, g["game"], g["status"], function()
		if tostring(g.id) == pid then
			elements:Notify("already here", g.game, "info")
			return
		end
		local okLaunch = pcall(function()
			exservice:LaunchExperience({placeId = tonumber(g.id)})
		end)
		if not okLaunch then
			-- if theres no ExperienceService fall back to normal teleport
			pcall(function()
				game:GetService("TeleportService"):Teleport(tonumber(g.id), plr)
			end)
		end
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
	pcall(function() setclipboard(pid) end)
	elements:Notify("copied", pid, "ok")
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
-- auto rejoin
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
-- keybind
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
-- startup
--------------------------------------------------------------
if dec1.settings.disable_3d_rendering then
	pcall(function() runservice:Set3dRenderingEnabled(false) end)
end
if getgenv then
	getgenv().autorjjjj = dec1.settings.auto_rejoin_on_kick
	getgenv().hubSounds = dec1.settings.sounds
end

-- open straight on Game if the game is supported, else Home
goTo(loadedModule and Sections.Game or Sections.Home)

task.delay(0.4, function()
	elements:Notify("brainrot hub", "right shift to hide", "ok")
end)
