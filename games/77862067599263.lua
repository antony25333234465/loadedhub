--// Obby as a Brainrot (Universal Farm)
--// Compatible con todas las rarezas (Common, Uncommon, Rare, Epic, Legendary, Mythic, Secret, Celestial, Cosmic, Hacker, OG)

return function(king, cfg, el)
	local players = game:GetService("Players")
	local rs      = game:GetService("ReplicatedStorage")
	local uis     = game:GetService("UserInputService")
	local plr     = players.LocalPlayer

	----------------------------------------------------------
	-- BASE DE DATOS LOCAL (Extraída de ItemConfigurations)
	----------------------------------------------------------
	local ITEM_DATABASE = {
		-- Common
		["Noobini Pizzanini"] = "Common",
		["Boneca Ambalabu"] = "Common",
		["Tim Cheese"] = "Common",
		["Br Br Batabim"] = "Common",
		["Brri Brri Bicus"] = "Common",
		["Cacto Hipopotamo"] = "Common",
		["Tric Trac Baraboom"] = "Common",
		["Trippi Troppi"] = "Common",
		["Bandito Bobritto"] = "Common",
		-- Uncommon
		["Fluri Flura"] = "Uncommon",
		["Gangster Footera"] = "Uncommon",
		["Glorbo Fruitto Drillo"] = "Uncommon",
		["Avocadini Buffo"] = "Uncommon",
		["Salamino Penguino"] = "Uncommon",
		["Kiwi Pipi"] = "Uncommon",
		["Lirili Larila"] = "Uncommon",
		["Svinino"] = "Uncommon",
		-- Rare
		["Tung Tung Tung Sahur"] = "Rare",
		["Talpa Di Ferro"] = "Rare",
		["Talpa Di Ferro Triple"] = "Rare",
		["Frigo Camelo"] = "Rare",
		["Lioneli Cactusini"] = "Rare",
		["Trulimero Truli"] = "Rare",
		["Tu Tu Tu Sahur"] = "Rare",
		-- Epic
		["Octopus"] = "Epic",
		["Cameloni Meleloni"] = "Epic",
		["Cappoccino Assassino"] = "Epic",
		["Chimpanzini Bananini"] = "Epic",
		["Cocofanto Elefanto"] = "Epic",
		["Dolphinita"] = "Epic",
		-- Legendary
		["Elefanto Frigo"] = "Legendary",
		["Gorillo Watermelondrillo"] = "Legendary",
		["Melon Otter"] = "Legendary",
		["Avocadini Antilopini"] = "Legendary",
		["Ballerina Cappuccina"] = "Legendary",
		["Bambini Crostini"] = "Legendary",
		["Udin Din Din Dun"] = "Legendary",
		-- Mythic
		["Tralalero Tralala"] = "Mythic",
		["Bombardini Crocodilo"] = "Mythic",
		["Bombardini Gusini"] = "Mythic",
		["Blackhole Goat"] = "Mythic",
		["Garamararamararaman"] = "Mythic",
		["To To To Sahur"] = "Mythic",
		["Orangutini Ananasini"] = "Mythic",
		["Alessio"] = "Mythic",
		["Corn Sahur"] = "Mythic",
		-- Secret
		["Torrtuginni Dragonfrutini"] = "Secret",
		["La Vacca Saturno Saturnita"] = "Secret",
		["Los Tralaleritos"] = "Secret",
		["Stoppo Luminino"] = "Secret",
		["Madung"] = "Secret",
		["Job Application"] = "Secret",
		["Las Vaquitas Saturnitas"] = "Secret",
		-- Celestial
		["Waterdino"] = "Celestial",
		["Calculino"] = "Celestial",
		["Mangolini Parrocini"] = "Celestial",
		["Bisonte Giuppitere"] = "Celestial",
		["Castlino Fortini"] = "Celestial",
		["67"] = "Celestial",
		-- Cosmic
		["Cappuccino Clownino"] = "Cosmic",
		["Swag Soda"] = "Cosmic",
		["Chillin' Chilli"] = "Cosmic",
		["Burguro"] = "Cosmic",
		["Smurf Cat"] = "Cosmic",
		-- Hacker
		["Spaghetti Tualetti"] = "Hacker",
		["Nuclearo Dinossauro"] = "Hacker",
		["Rexosaurus"] = "Hacker",
		["Tic Tac Sahur"] = "Hacker",
		["Tuff Toucan"] = "Hacker",
		-- OG
		["Gattatino Nyanino"] = "OG",
		["Strawberry Elefant"] = "OG",
		["Skibi Toilet"] = "OG",
		["Dragon Cannelloni"] = "OG",
		["Meowl"] = "OG",
	}

	----------------------------------------------------------
	-- FUNCIÓN: Obtener Rareza Dinámica
	----------------------------------------------------------
	local function getRarity(itemName)
		-- 1. Intentar leer directo de ReplicatedStorage.Modules.ItemConfigurations
		local modules = rs:FindFirstChild("Modules")
		if modules then
			local itemConfigModule = modules:FindFirstChild("ItemConfigurations")
			if itemConfigModule then
				local ok, itemConfig = pcall(require, itemConfigModule)
				if ok and itemConfig and itemConfig.GetItemData then
					local data = itemConfig.GetItemData(itemName)
					if data and data.Rarity then
						return data.Rarity
					end
				end
			end
		end
		-- 2. Fallback a la base de datos local incorporada
		if ITEM_DATABASE[itemName] then
			return ITEM_DATABASE[itemName]
		end
		-- 3. Si no existe, fallback seguro
		return "OG"
	end

	----------------------------------------------------------
	-- CONFIG
	----------------------------------------------------------
	local CONFIG = {
		TargetName  = "67",
		LandingPos  = Vector3.new(4, -99, 4514),
		TeleportPos = Vector3.new(8, 21, -558),
		PrePos      = Vector3.new(9, 19, -493),
		Mutation    = "Normal",
		Rarity      = getRarity("67"),
		BlockName   = "Uncommon Lucky Block",
		Power       = 10.642112568062,
	}

	----------------------------------------------------------
	-- REMOTES
	----------------------------------------------------------
	local rem = rs:FindFirstChild("ThrowLuckyBlockRemotes")
	local r = {}
	local missing = {}
	if rem then
		r.ZoneBat = rem:FindFirstChild("ThrowZoneBatVisual")
		r.Started = rem:FindFirstChild("ThrowStarted")
		r.BatHit  = rem:FindFirstChild("ThrowBatHit")
		r.Cleanup = rem:FindFirstChild("ThrowBatTimingVfxCleanup")
		r.Landed  = rem:FindFirstChild("LuckyBlockLanded")
		for k, v in pairs(r) do
			if not v then table.insert(missing, k) end
		end
	end

	if not rem or #missing > 0 then
		el:Header(king, "universal farm")
		el:Stat(king, "remotes", rem and ("missing " .. #missing) or "not found", "err")
		el:Label(king, rem
			and ("couldnt find: " .. table.concat(missing, ", "))
			or "ThrowLuckyBlockRemotes doesnt exist. are you in the right game?")
		return
	end

	local function tp(pos)
		local c = plr.Character
		if not c then return end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = CFrame.new(pos) end
	end

	----------------------------------------------------------
	-- UI
	----------------------------------------------------------
	el:Header(king, "universal farm")
	local lblState  = el:Stat(king, "state", "idle", "dim")
	local lblCount  = el:Stat(king, "caught", "0", "gold")
	local lblTarget = el:Stat(king, "target", CONFIG.TargetName, "loot")
	local lblRarity = el:Stat(king, "rarity", CONFIG.Rarity, "loot")

	----------------------------------------------------------
	-- STATE
	----------------------------------------------------------
	local farming = false
	local gen = 0
	local count = 0
	local tgFarm

	local function setState(txt, kind)
		lblState.Text = txt
		local c = Color3.fromRGB(168, 158, 192)
		if kind == "ok"   then c = Color3.fromRGB(124, 190, 84)  end
		if kind == "warn" then c = Color3.fromRGB(228, 158, 56)  end
		if kind == "err"  then c = Color3.fromRGB(203, 82, 66)   end
		lblState.TextColor3 = c
	end

	----------------------------------------------------------
	-- LOOP DE FARMING
	----------------------------------------------------------
	local function loop(mine)
		while farming and gen == mine do
			local ok, err = pcall(function()
				-- Detecta automáticamente la rareza exacta del Target
				local currentRarity = getRarity(CONFIG.TargetName)
				CONFIG.Rarity = currentRarity
				lblRarity.Text = currentRarity

				tp(CONFIG.PrePos)
				task.wait(0.3)
				r.ZoneBat:FireServer(true)
				task.wait(0.15)
				r.Started:FireServer()
				task.wait(0.15)
				r.BatHit:FireServer(nil, false)
				task.wait(0.15)
				r.Cleanup:FireServer()
				task.wait(0.15)

				-- Envía el payload con la rareza correcta sincronizada
				r.Landed:FireServer({
					LandingPosition = CONFIG.LandingPos,
					ItemName        = CONFIG.TargetName,
					Rarity          = currentRarity,
					BlockName       = CONFIG.BlockName,
					LandingRarity   = currentRarity,
					Mutation        = CONFIG.Mutation,
					Power           = CONFIG.Power,
				})

				task.wait(0.6)
				tp(CONFIG.TeleportPos)
				count = count + 1
				lblCount.Text = tostring(count)
				setState("caught!", "ok")

				if count % 10 == 0 then
					el:Notify("streak!", "youre at " .. count .. " " .. CONFIG.TargetName .. " (" .. currentRarity .. ")", "ok", 3.4)
				end
				task.wait(0.4)
				if farming and gen == mine then setState("farming", "warn") end
			end)

			if not ok then
				setState("error", "err")
				el:Notify("something broke", "retrying in 2s...", "err", 2.6)
				task.wait(2)
			end
		end
	end

	local function start()
		if farming then return end
		farming = true
		gen = gen + 1
		local mine = gen
		if tgFarm then tgFarm.Set(true) end
		setState("farming", "warn")
		local detectedRarity = getRarity(CONFIG.TargetName)
		el:Notify("running", "farming " .. CONFIG.TargetName .. " [" .. detectedRarity .. "]", "ok", 2.4)
		task.spawn(loop, mine)
	end

	local function stop()
		if not farming then return end
		farming = false
		gen = gen + 1
		if tgFarm then tgFarm.Set(false) end
		setState("idle", "dim")
		el:Notify("stopped", "youre at " .. count .. " total", "warn", 2.8)
	end

	----------------------------------------------------------
	-- CONTROLES
	----------------------------------------------------------
	el:Divider(king)
	tgFarm = el:Toggle("Auto Farm", king, false, function(v)
		if v then start() else stop() end
	end)

	el:Button("reset counter", king, function()
		if count == 0 then
			return el:Notify("nothing to reset", "counter is already at 0", "warn", 2.2)
		end
		local old = count
		count = 0
		lblCount.Text = "0"
		el:Notify("reset", "cleared " .. old .. " from the counter", "info", 2.6)
	end)

	----------------------------------------------------------
	-- TARGET (CON AUTO-DETECCIÓN DE RAREZA)
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "target")

	el:Textbox("Name", king, CONFIG.TargetName, function(txt)
		if txt == "" then return end
		CONFIG.TargetName = txt
		lblTarget.Text = txt

		local autoRarity = getRarity(txt)
		CONFIG.Rarity = autoRarity
		lblRarity.Text = autoRarity

		el:Notify("target changed", txt .. " -> " .. autoRarity, "ok", 2.5)
	end)

	el:Textbox("Rarity (Manual Override)", king, CONFIG.Rarity, function(txt)
		if txt == "" then return end
		CONFIG.Rarity = txt
		lblRarity.Text = txt
		el:Notify("rarity override", txt, "ok", 2)
	end)

	el:Textbox("Mutation", king, CONFIG.Mutation, function(txt)
		if txt == "" then return end
		CONFIG.Mutation = txt
		el:Notify("mutation", txt, "ok", 2)
	end)

	----------------------------------------------------------
	-- MANUAL TPs
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "manual")
	el:Button("go to spot", king, function()
		tp(CONFIG.PrePos)
		el:Notify("tp", "at the spot", "ok", 1.6)
	end)

	el:Button("go to base", king, function()
		tp(CONFIG.TeleportPos)
		el:Notify("tp", "at the base", "ok", 1.6)
	end)

	----------------------------------------------------------
	-- DIAGNÓSTICO
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "remotes")
	el:Stat(king, "throw remotes", "ok  (5/5)", "ok")

	----------------------------------------------------------
	-- KEYBIND (F = ON / OFF)
	----------------------------------------------------------
	uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.F then
			if farming then stop() else start() end
		end
	end)

	el:Label(king, "F = toggle on / off", Color3.fromRGB(120, 110, 146), 13)
end
