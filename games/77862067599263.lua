--// Obby as a Brainrot (OG Brainrot Farm)
--// Note: Server validation only accepts OG rarity brainrots.

return function(king, cfg, el)
	local players = game:GetService("Players")
	local rs      = game:GetService("ReplicatedStorage")
	local uis     = game:GetService("UserInputService")
	local plr     = players.LocalPlayer

	----------------------------------------------------------
	-- CONFIG
	----------------------------------------------------------
	local CONFIG = {
		TargetName  = "Meowl",
		Rarity      = "OG",
		BlockName   = "Uncommon Lucky Block",
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
		el:Header(king, "og brainrot farm")
		el:Stat(king, "remotes", rem and ("missing " .. #missing) or "not found", "err")
		el:Label(king, rem
			and ("couldnt find: " .. table.concat(missing, ", "))
			or "ThrowLuckyBlockRemotes doesnt exist. Are you in the right game?")
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
	el:Header(king, "og brainrot farm")
	el:Label(king, "INFO: Only OG Brainrots are supported by game server", Color3.fromRGB(228, 158, 56), 12)

	local lblState  = el:Stat(king, "state", "idle", "dim")
	local lblCount  = el:Stat(king, "caught", "0", "gold")
	local lblTarget = el:Stat(king, "target", CONFIG.TargetName, "loot")
	local lblRarity = el:Stat(king, "rarity", CONFIG.Rarity, "loot")

	----------------------------------------------------------
	-- STATE (ALL AUTOMATIONS DEFAULT TO FALSE)
	----------------------------------------------------------
	local farming  = false
	local autoCol  = false
	local autoUpgr = false
	local autoRebr = false
	local gen      = 0
	local count    = 0
	local tgFarm, tgCol, tgUpgr, tgRebr

	local function setState(txt, kind)
		lblState.Text = txt
		local c = Color3.fromRGB(168, 158, 192)
		if kind == "ok"   then c = Color3.fromRGB(124, 190, 84)  end
		if kind == "warn" then c = Color3.fromRGB(228, 158, 56)  end
		if kind == "err"  then c = Color3.fromRGB(203, 82, 66)   end
		lblState.TextColor3 = c
	end

	----------------------------------------------------------
	-- THROW EXECUTION
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

		r.Landed:FireServer({
			LandingPosition = CONFIG.LandingPos,
			ItemName        = CONFIG.TargetName,
			Rarity          = CONFIG.Rarity,
			BlockName       = CONFIG.BlockName,
			LandingRarity   = CONFIG.Rarity,
			Mutation        = CONFIG.Mutation,
			Power           = CONFIG.Power,
		})

		task.wait(0.4)
		tp(CONFIG.TeleportPos)
	end

	----------------------------------------------------------
	-- AUTO FARM LOOP
	----------------------------------------------------------
	local function loop(mine)
		while farming and gen == mine do
			local ok, err = pcall(function()
				triggerThrow()

				count = count + 1
				lblCount.Text = tostring(count)
				setState("caught!", "ok")

				if count % 10 == 0 then
					el:Notify("streak!", "you are at " .. count .. " " .. CONFIG.TargetName, "ok", 3.4)
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
		el:Notify("running", "farming " .. CONFIG.TargetName, "ok", 2.4)
		task.spawn(loop, mine)
	end

	local function stop()
		if not farming then return end
		farming = false
		gen = gen + 1
		if tgFarm then tgFarm.Set(false) end
		setState("idle", "dim")
		el:Notify("stopped", "total caught: " .. count, "warn", 2.8)
	end

	----------------------------------------------------------
	-- SECONDARY AUTOMATIONS (COLLECT, UPGRADE, REBIRTH)
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
	-- FARM CONTROLS
	----------------------------------------------------------
	el:Divider(king)
	tgFarm = el:Toggle("Auto Farm OG Brainrots", king, false, function(v)
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
	-- TARGET SETTINGS
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "target settings")

	el:Textbox("Target Name", king, CONFIG.TargetName, function(txt)
		if txt == "" then return end
		CONFIG.TargetName = txt
		lblTarget.Text = txt
		el:Notify("target changed", "now farming " .. txt, "ok", 2.2)
	end)

	el:Textbox("Mutation", king, CONFIG.Mutation, function(txt)
		if txt == "" then return end
		CONFIG.Mutation = txt
		el:Notify("mutation set", txt, "ok", 2)
	end)

	----------------------------------------------------------
	-- AUTOMATION TOGGLES (OFF BY DEFAULT)
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "automation")

	tgCol = el:Toggle("Auto Collect Base", king, false, function(v)
		autoCol = v
		el:Notify("auto collect", v and "enabled" or "disabled", "info", 1.8)
	end)

	tgUpgr = el:Toggle("Auto Upgrade Slots", king, false, function(v)
		autoUpgr = v
		el:Notify("auto upgrade", v and "enabled" or "disabled", "info", 1.8)
	end)

	tgRebr = el:Toggle("Auto Rebirth", king, false, function(v)
		autoRebr = v
		el:Notify("auto rebirth", v and "enabled" or "disabled", "info", 1.8)
	end)

	----------------------------------------------------------
	-- MANUAL TELEPORTS
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

	----------------------------------------------------------
	-- KEYBIND
	----------------------------------------------------------
	uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.F then
			if farming then stop() else start() end
		end
	end)

	el:Label(king, "F = toggle auto farm on / off", Color3.fromRGB(120, 110, 146), 13)
end
