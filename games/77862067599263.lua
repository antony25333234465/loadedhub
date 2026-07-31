--// Obby as a Brainrot (Universal Brainrot Farm)
--// Funciona con TODOS los Brainrots: 67, Common, Celestial, Secret, OG, etc.

return function(king, cfg, el)
	local players = game:GetService("Players")
	local rs      = game:GetService("ReplicatedStorage")
	local uis     = game:GetService("UserInputService")
	local plr     = players.LocalPlayer

	----------------------------------------------------------
	-- BASE DE DATOS LOCAL DE BRAINROTS (63 ITEMS)
	----------------------------------------------------------
	local ITEM_DATABASE = {
		-- Common
		["Noobini Pizzanini"]        = "Common",
		["Boneca Ambalabu"]          = "Common",
		["Tim Cheese"]               = "Common",
		["Br Br Batabim"]            = "Common",
		["Brri Brri Bicus"]          = "Common",
		["Cacto Hipopotamo"]         = "Common",
		["Tric Trac Baraboom"]       = "Common",
		["Trippi Troppi"]            = "Common",
		["Bandito Bobritto"]         = "Common",
		-- Uncommon
		["Fluri Flura"]              = "Uncommon",
		["Gangster Footera"]         = "Uncommon",
		["Glorbo Fruitto Drillo"]    = "Uncommon",
		["Avocadini Buffo"]          = "Uncommon",
		["Salamino Penguino"]        = "Uncommon",
		["Kiwi Pipi"]                = "Uncommon",
		["Lirili Larila"]            = "Uncommon",
		["Svinino"]                  = "Uncommon",
		-- Rare
		["Tung Tung Tung Sahur"]     = "Rare",
		["Talpa Di Ferro"]           = "Rare",
		["Talpa Di Ferro Triple"]    = "Rare",
		["Frigo Camelo"]             = "Rare",
		["Lioneli Cactusini"]        = "Rare",
		["Trulimero Truli"]          = "Rare",
		["Tu Tu Tu Sahur"]           = "Rare",
		-- Epic
		["Octopus"]                  = "Epic",
		["Cameloni Meleloni"]        = "Epic",
		["Cappoccino Assassino"]     = "Epic",
		["Chimpanzini Bananini"]     = "Epic",
		["Cocofanto Elefanto"]       = "Epic",
		["Dolphinita"]               = "Epic",
		-- Legendary
		["Elefanto Frigo"]           = "Legendary",
		["Gorillo Watermelondrillo"] = "Legendary",
		["Melon Otter"]              = "Legendary",
		["Avocadini Antilopini"]     = "Legendary",
		["Ballerina Cappuccina"]     = "Legendary",
		["Bambini Crostini"]         = "Legendary",
		["Udin Din Din Dun"]         = "Legendary",
		-- Mythic
		["Tralalero Tralala"]        = "Mythic",
		["Bombardini Crocodilo"]     = "Mythic",
		["Bombardini Gusini"]        = "Mythic",
		["Blackhole Goat"]           = "Mythic",
		["Garamararamararaman"]      = "Mythic",
		["To To To Sahur"]           = "Mythic",
		["Orangutini Ananasini"]     = "Mythic",
		["Alessio"]                  = "Mythic",
		["Corn Sahur"]               = "Mythic",
		-- Secret
		["Torrtuginni Dragonfrutini"] = "Secret",
		["La Vacca Saturno Saturnita"]= "Secret",
		["Los Tralaleritos"]         = "Secret",
		["Stoppo Luminino"]          = "Secret",
		["Madung"]                   = "Secret",
		["Job Application"]          = "Secret",
		["Las Vaquitas Saturnitas"]   = "Secret",
		-- Celestial
		["Waterdino"]                = "Celestial",
		["Calculino"]                = "Celestial",
		["Mangolini Parrocini"]      = "Celestial",
		["Bisonte Giuppitere"]       = "Celestial",
		["Castlino Fortini"]         = "Celestial",
		["67"]                       = "Celestial",
		-- Cosmic
		["Cappuccino Clownino"]      = "Cosmic",
		["Swag Soda"]                = "Cosmic",
		["Chillin' Chilli"]          = "Cosmic",
		["Burguro"]                  = "Cosmic",
		["Smurf Cat"]                = "Cosmic",
		-- Hacker
		["Spaghetti Tualetti"]       = "Hacker",
		["Nuclearo Dinossauro"]      = "Hacker",
		["Rexosaurus"]               = "Hacker",
		["Tic Tac Sahur"]            = "Hacker",
		["Tuff Toucan"]              = "Hacker",
		-- OG
		["Gattatino Nyanino"]        = "OG",
		["Strawberry Elefant"]       = "OG",
		["Skibi Toilet"]             = "OG",
		["Dragon Cannelloni"]        = "OG",
		["Meowl"]                    = "OG",
	}

	----------------------------------------------------------
	-- RESOLVER EN TIEMPO REAL DESDE LA MEMORIA DEL JUEGO
	----------------------------------------------------------
	local function resolveBrainrot(itemName)
		local rarity = ITEM_DATABASE[itemName] or "Celestial"
		local blockName = "Uncommon Lucky Block"

		pcall(function()
			local modules = rs:FindFirstChild("Modules")
			if not modules then return end

			-- 1. Leer rareza real desde ItemConfigurations
			local itemConfigMod = modules:FindFirstChild("ItemConfigurations")
			if itemConfigMod then
				local ok, itemConfig = pcall(require, itemConfigMod)
				if ok and itemConfig then
					if itemConfig.GetItemData then
						local data = itemConfig.GetItemData(itemName)
						if data and data.Rarity then rarity = data.Rarity end
					elseif itemConfig.Items and itemConfig.Items[itemName] then
						local data = itemConfig.Items[itemName]
						if data and data.Rarity then rarity = data.Rarity end
					end
				end
			end

			-- 2. Buscar bloque correspondiente en LuckyBlockDefinitions
			local lbDefMod = modules:FindFirstChild("LuckyBlockDefinitions")
			if lbDefMod then
				local ok, lbDef = pcall(require, lbDefMod)
				if ok and lbDef and lbDef.Blocks then
					-- Coincidencia exacta de rareza
					for bName, bData in pairs(lbDef.Blocks) do
						if bData and bData.Rarity == rarity then
							blockName = bName
							return
						end
					end
					-- Buscar por nombre
					for bName, _ in pairs(lbDef.Blocks) do
						if string.find(string.lower(bName), string.lower(rarity)) then
							blockName = bName
							return
						end
					end
					-- Fallback: primer bloque disponible
					for bName, _ in pairs(lbDef.Blocks) do
						blockName = bName
						break
					end
				end
			end
		end)

		return rarity, blockName
	end

	----------------------------------------------------------
	-- CONFIGURACIÓN INICIAL
	----------------------------------------------------------
	local initialRarity, initialBlock = resolveBrainrot("67")

	local CONFIG = {
		TargetName  = "67",
		Rarity      = initialRarity,
		BlockName   = initialBlock,
		ForceOG     = false,
		LandingPos  = Vector3.new(4, -99, 4514),
		TeleportPos = Vector3.new(8, 21, -558),
		PrePos      = Vector3.new(9, 19, -493),
		Mutation    = "Disco",
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
		el:Header(king, "brainrot farm")
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
		pcall(function() c:MoveTo(pos) end)
	end

	----------------------------------------------------------
	-- UI INTERFACE
	----------------------------------------------------------
	el:Header(king, "brainrot farm")
	local lblState  = el:Stat(king, "state", "idle", "dim")
	local lblCount  = el:Stat(king, "caught", "0", "gold")
	local lblTarget = el:Stat(king, "target", CONFIG.TargetName, "loot")
	local lblRarity = el:Stat(king, "rarity", CONFIG.Rarity, "loot")
	local lblBlock  = el:Stat(king, "block", CONFIG.BlockName, "loot")

	----------------------------------------------------------
	-- STATE
	----------------------------------------------------------
	local farming  = false
	local autoCol  = false
	local autoUpgr = false
	local autoRebr = false
	local gen      = 0
	local count    = 0
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
	-- EJECUCIÓN DEL LANZAMIENTO (TIEMPOS RÁPIDOS REALES)
	----------------------------------------------------------
	local function triggerThrow()
		tp(CONFIG.PrePos)
		task.wait(0.3)

		r.ZoneBat:FireServer(true)
		task.wait()
		r.Started:FireServer()
		task.wait()
		r.BatHit:FireServer(nil, false)
		task.wait()
		r.Cleanup:FireServer()
		task.wait()

		local finalRarity = CONFIG.ForceOG and "OG" or CONFIG.Rarity

		r.Landed:FireServer({
			LandingPosition = CONFIG.LandingPos,
			ItemName        = CONFIG.TargetName,
			Rarity          = finalRarity,
			BlockName       = CONFIG.BlockName,
			LandingRarity   = finalRarity,
			Mutation        = CONFIG.Mutation,
			Power           = CONFIG.Power,
		})

		task.wait(0.4)
		tp(CONFIG.TeleportPos)
	end

	----------------------------------------------------------
	-- BUCLE AUTO FARM BRAINROTS
	----------------------------------------------------------
	local function loop(mine)
		while farming and gen == mine do
			local ok, err = pcall(function()
				triggerThrow()

				count = count + 1
				lblCount.Text = tostring(count)
				setState("caught!", "ok")

				if count % 10 == 0 then
					el:Notify("streak!", "caught " .. count .. "x " .. CONFIG.TargetName, "ok", 3.4)
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
		el:Notify("running", "farming " .. CONFIG.TargetName .. " [" .. CONFIG.Rarity .. "]", "ok", 2.4)
		task.spawn(loop, mine)
	end

	local function stop()
		if not farming then return end
		farming = false
		gen = gen + 1
		if tgFarm then tgFarm.Set(false) end
		setState("idle", "dim")
		el:Notify("stopped", "total: " .. count .. " " .. CONFIG.TargetName, "warn", 2.8)
	end

	----------------------------------------------------------
	-- FUNCIONES SECUNDARIAS (COLLECT, UPGRADE, REBIRTH)
	----------------------------------------------------------
	task.spawn(function()
		while true do
			if autoCol then
				pcall(function()
					local myPlot = workspace:FindFirstChild("Plot_" .. plr.Name)
					if myPlot then
						for _, flName in ipairs({"Floor1", "Floor2", "Floor3"}) do
							local floorObj = myPlot:FindFirstChild(flName)
							if floorObj and floorObj:FindFirstChild("Slots") then
								for _, slot in pairs(floorObj.Slots:GetChildren()) do
									local touch = slot:FindFirstChild("CollectTouch")
									if touch and plr.Character and plr.Character:FindFirstChild("Head") then
										firetouchinterest(plr.Character.Head, touch, true)
										task.wait()
										firetouchinterest(plr.Character.Head, touch, false)
									end
								end
							end
						end
					end
				end)
			end
			task.wait(0.5)
		end
	end)

	task.spawn(function()
		while true do
			if autoUpgr then
				pcall(function()
					local events = rs:FindFirstChild("Events")
					if events and events:FindFirstChild("RequestSlotUpgrade") then
						local req = events.RequestSlotUpgrade
						for _, floor in ipairs({"Floor1", "Floor2", "Floor3"}) do
							for i = 1, 10 do
								req:FireServer(floor, "Slot" .. tostring(i))
							end
						end
					end
				end)
			end
			task.wait(1)
		end
	end)

	task.spawn(function()
		while true do
			if autoRebr then
				pcall(function()
					local events = rs:FindFirstChild("Events")
					if events and events:FindFirstChild("RequestRebirth") then
						events.RequestRebirth:FireServer()
					end
				end)
			end
			task.wait(3)
		end
	end)

	----------------------------------------------------------
	-- CONTROLES UI
	----------------------------------------------------------
	el:Divider(king)
	tgFarm = el:Toggle("Auto Farm Brainrot", king, false, function(v)
		if v then start() else stop() end
	end)

	el:Button("test single throw", king, function()
		local ok, err = pcall(triggerThrow)
		if ok then
			el:Notify("test fired", "sent " .. CONFIG.TargetName .. " (" .. CONFIG.Rarity .. ")", "ok", 2.5)
		else
			el:Notify("test failed", tostring(err), "err", 3)
		end
	end)

	el:Button("reset counter", king, function()
		local old = count
		count = 0
		lblCount.Text = "0"
		el:Notify("reset", "cleared " .. old .. " count", "info", 2.6)
	end)

	----------------------------------------------------------
	-- CONTROLES DE TARGET
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "target settings")

	el:Textbox("Target Name", king, CONFIG.TargetName, function(txt)
		if txt == "" then return end
		CONFIG.TargetName = txt
		lblTarget.Text = txt

		-- Sincronizar rareza y bloque automáticamente
		local rName, bName = resolveBrainrot(txt)
		CONFIG.Rarity = rName
		CONFIG.BlockName = bName
		lblRarity.Text = rName
		lblBlock.Text = bName

		el:Notify("target changed", txt .. " [" .. rName .. "]", "ok", 2.5)
	end)

	el:Toggle("Force OG Rarity", king, false, function(v)
		CONFIG.ForceOG = v
		el:Notify("force og", v and "enabled" or "disabled", "info", 2)
	end)

	el:Textbox("Mutation", king, CONFIG.Mutation, function(txt)
		if txt == "" then return end
		CONFIG.Mutation = txt
		el:Notify("mutation", txt, "ok", 2)
	end)

	----------------------------------------------------------
	-- OTRAS FUNCIONES (COLLECT, UPGRADE, REBIRTH)
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "automation")

	el:Toggle("Auto Collect Base", king, false, function(v)
		autoCol = v
		el:Notify("collect", v and "enabled" or "disabled", "info", 1.8)
	end)

	el:Toggle("Auto Upgrade Slots", king, false, function(v)
		autoUpgr = v
		el:Notify("upgrade", v and "enabled" or "disabled", "info", 1.8)
	end)

	el:Toggle("Auto Rebirth", king, false, function(v)
		autoRebr = v
		el:Notify("rebirth", v and "enabled" or "disabled", "info", 1.8)
	end)

	----------------------------------------------------------
	-- TELEPORTS Y KEYBIND
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "manual tp")
	el:Button("go to spot", king, function()
		tp(CONFIG.PrePos)
		el:Notify("tp", "at the spot", "ok", 1.6)
	end)

	el:Button("go to base", king, function()
		tp(CONFIG.TeleportPos)
		el:Notify("tp", "at the base", "ok", 1.6)
	end)

	uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.F then
			if farming then stop() else start() end
		end
	end)

	el:Label(king, "F = toggle farm on / off", Color3.fromRGB(120, 110, 146), 13)
end
