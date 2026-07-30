--// Obby as a Brainrot  (meowl farm)
--// gets (king, cfg, el) from the loader
--// to farm another brainrot just change the CONFIG below

return function(king, cfg, el)

	local players = game:GetService("Players")
	local rs      = game:GetService("ReplicatedStorage")
	local uis     = game:GetService("UserInputService")
	local plr     = players.LocalPlayer

	----------------------------------------------------------
	-- CONFIG  (this is the only thing you touch)
	----------------------------------------------------------
	local CONFIG = {
		TargetName  = "Meowl",
		LandingPos  = Vector3.new(4, -99, 4514),
		TeleportPos = Vector3.new(8, 21, -558),
		PrePos      = Vector3.new(9, 19, -493),
		Mutation    = "Normal",
		Rarity      = "OG",
		BlockName   = "Uncommon Lucky Block",
		Power       = 10.642112568062,
	}

	----------------------------------------------------------
	-- remotes
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

	-- if the remotes arent there i build nothing, just warn
	if not rem or #missing > 0 then
		el:Header(king, "meowl farm")
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
	-- ui
	----------------------------------------------------------
	el:Header(king, "meowl farm")

	local lblState  = el:Stat(king, "state", "idle", "dim")
	local lblCount  = el:Stat(king, "caught", "0", "gold")
	local lblTarget = el:Stat(king, "target", CONFIG.TargetName, "loot")

	----------------------------------------------------------
	-- state
	----------------------------------------------------------
	local farming = false
	local gen = 0        -- generation counter, kills the old thread on stop
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
	-- the loop. same remotes and timings as always
	----------------------------------------------------------
	local function loop(mine)
		while farming and gen == mine do
			local ok, err = pcall(function()
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
				r.Landed:FireServer({
					LandingPosition = CONFIG.LandingPos,
					ItemName        = CONFIG.TargetName,
					Rarity          = CONFIG.Rarity,
					BlockName       = CONFIG.BlockName,
					LandingRarity   = CONFIG.Rarity,
					Mutation        = CONFIG.Mutation,
					Power           = CONFIG.Power,
				})
				task.wait(0.6)
				tp(CONFIG.TeleportPos)

				count = count + 1
				lblCount.Text = tostring(count)
				setState("caught!", "ok")

				-- ping every 10
				if count % 10 == 0 then
					el:Notify("streak!", "youre at " .. count .. " " .. CONFIG.TargetName, "ok", 3.4)
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
		local mine = gen     -- if the number changes it means i was stopped
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
		el:Notify("stopped", "youre at " .. count .. " total", "warn", 2.8)
	end

	----------------------------------------------------------
	-- controls
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
	-- change target without touching the code
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "target")

	el:Textbox("Name", king, CONFIG.TargetName, function(txt)
		if txt == "" then return end
		CONFIG.TargetName = txt
		lblTarget.Text = txt
		el:Notify("target", "now farming " .. txt, "ok", 2.2)
	end)

	el:Textbox("Rarity", king, CONFIG.Rarity, function(txt)
		if txt == "" then return end
		CONFIG.Rarity = txt
		el:Notify("rarity", txt, "ok", 2)
	end)

	el:Textbox("Mutation", king, CONFIG.Mutation, function(txt)
		if txt == "" then return end
		CONFIG.Mutation = txt
		el:Notify("mutation", txt, "ok", 2)
	end)

	----------------------------------------------------------
	-- manual
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
	-- diagnostics
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "remotes")
	el:Stat(king, "throw remotes", "ok  (5/5)", "ok")

	----------------------------------------------------------
	-- keybind
	----------------------------------------------------------
	uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.F then
			if farming then stop() else start() end
		end
	end)

	el:Label(king, "F = toggle on / off", Color3.fromRGB(120, 110, 146), 13)
end
