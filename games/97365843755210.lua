--// Cut Grass for Brainrots
--// autofarm + auto attack + noclip
--// gets (king, cfg, el) from the loader

return function(king, cfg, el)

	local players    = game:GetService("Players")
	local rs         = game:GetService("ReplicatedStorage")
	local runservice = game:GetService("RunService")
	local uis        = game:GetService("UserInputService")
	local ws         = game:GetService("Workspace")
	local plr        = players.LocalPlayer

	local FARM = {
		-- zone 1 is the good one even if its almost always empty
		Area1   = CFrame.new(864.7, 32.9, 0.1),
		Area2   = CFrame.new(514.7, 32.9, 0.1),
		ClaimCF = CFrame.new(-910.1, 33.5, -0.183),
		Radius  = 300,
		Rescan  = 3,
	}

	local GREEN  = Color3.fromRGB(124, 190, 84)
	local ORANGE = Color3.fromRGB(228, 158, 56)
	local RED    = Color3.fromRGB(203, 82, 66)
	local GRAY   = Color3.fromRGB(168, 158, 192)
	local PURPLE = Color3.fromRGB(157, 122, 232)
	local LILAC  = Color3.fromRGB(186, 158, 245)
	local GOLD   = Color3.fromRGB(238, 196, 92)
	local DIM    = Color3.fromRGB(120, 110, 146)

	----------------------------------------------------------
	-- knit
	----------------------------------------------------------
	local function findKnit(class, name)
		local r
		pcall(function()
			local idx = rs:WaitForChild("Packages", 8):WaitForChild("_Index", 5)
			local k = idx:WaitForChild("acecateer_knit@1.7.2", 5)
			if name == "GetIsCarryingBrainrot" then
				r = k.knit.Services.DataService.RF.GetIsCarryingBrainrot
			elseif name == "AttackRequested" then
				r = k.knit.Services.AttackService.RE.AttackRequested
			end
		end)
		if not r then
			-- in case they bump the package version
			pcall(function()
				for _, o in ipairs(rs:GetDescendants()) do
					if o:IsA(class) and o.Name == name then r = o break end
				end
			end)
		end
		return r
	end

	local rfCarry  = findKnit("RemoteFunction", "GetIsCarryingBrainrot")
	local reAttack = findKnit("RemoteEvent", "AttackRequested")

	-- the RF is the truth but costs a server trip, so i cache it a bit
	local carryCache, carryT = false, 0

	local function carrying(force)
		if not force and os.clock() - carryT < 0.25 then return carryCache end
		if rfCarry then
			local ok, r = pcall(function() return rfCarry:InvokeServer() end)
			if ok then
				carryCache = (r == true)
				carryT = os.clock()
				return carryCache
			end
		end
		local c = plr.Character
		if c then
			if c:GetAttribute("CarryingBrainrot") then return true end
			for _, v in ipairs(c:GetChildren()) do
				if v:IsA("Model") and v:FindFirstChildWhichIsA("BasePart")
				   and v.Name ~= "EquippedShovel"
				   and not v:FindFirstChildOfClass("Humanoid") then
					return true
				end
			end
		end
		return false
	end

	----------------------------------------------------------
	-- character
	----------------------------------------------------------
	local rnd = Random.new(os.clock() * 1000 % 99991)

	local function hrp()
		local c = plr.Character
		if not c then return nil end
		return c:FindFirstChild("HumanoidRootPart")
	end

	local function alive()
		local c = plr.Character
		if not c then return false end
		local h = c:FindFirstChildOfClass("Humanoid")
		return h ~= nil and h.Health > 0
	end

	local noclipOn, noclipCon = false, nil

	local function noclip(on)
		if on then
			if noclipCon then return end
			noclipOn = true
			noclipCon = runservice.Stepped:Connect(function()
				local c = plr.Character
				if not c then return end
				for _, v in ipairs(c:GetDescendants()) do
					if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
				end
			end)
		else
			noclipOn = false
			if noclipCon then noclipCon:Disconnect() noclipCon = nil end
			local c = plr.Character
			if c then
				for _, v in ipairs(c:GetDescendants()) do
					if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
						pcall(function() v.CanCollide = true end)
					end
				end
			end
		end
	end

	-- hop in steps, not one giant teleport.
	-- and zero the velocity each step, otherwise you fly off
	local function moveTo(dest)
		local root = hrp()
		if not root then return false end

		local from = root.Position
		local to   = dest.Position
		local dist = (to - from).Magnitude
		local step = (cfg.settings and cfg.settings.tp_step) or 160

		if dist <= step then
			root.CFrame = dest
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			return true
		end

		local n = math.ceil(dist / step)
		for i = 1, n do
			root = hrp()
			if not root then return false end
			local p = from:Lerp(to, i / n)
			-- a bit of noise so its not a perfect straight line
			if i < n then
				p = p + Vector3.new(rnd:NextNumber(-1.5, 1.5), 0, rnd:NextNumber(-1.5, 1.5))
				root.CFrame = CFrame.new(p, to)
			else
				root.CFrame = dest
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			task.wait(0.05)
		end
		return true
	end

	-- make sure i get there, sometimes moveTo falls short
	local function arrive(cf)
		moveTo(cf)
		for _ = 1, 3 do
			local root = hrp()
			if not root then return false end
			if (root.Position - cf.Position).Magnitude < 8 then return true end
			root.CFrame = cf
			root.AssemblyLinearVelocity = Vector3.zero
			task.wait(0.12)
		end
		return true
	end

	-- the claim sometimes runs on Touched and if you stand still it never fires
	local function stomp(cf, secs, stopFn)
		local t0, i = os.clock(), 0
		while os.clock() - t0 < secs do
			if stopFn and stopFn() then return true end
			local root = hrp()
			if root then
				i = i + 1
				local ang = i * 1.9
				local r = 0.8 + (i % 3) * 0.5
				root.CFrame = cf * CFrame.new(math.cos(ang) * r, (i % 2) * 0.7, math.sin(ang) * r)
				root.AssemblyLinearVelocity = Vector3.zero
			end
			task.wait(0.07)
		end
		return false
	end

	----------------------------------------------------------
	-- value, so i grab the best one
	----------------------------------------------------------
	local SUFFIX = {[""] = 1, k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18}

	local function toNumber(txt)
		if not txt then return 0 end
		local clean = string.lower(txt):gsub(",", ""):gsub("%s", "")
		local n, suf = string.match(clean, "([%d%.]+)([kmbtq]?[ai]?)")
		if not n then return 0 end
		return (tonumber(n) or 0) * (SUFFIX[suf or ""] or 1)
	end

	local RARITY = {common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5,
		mythic = 6, ["brainrot god"] = 7, secret = 8, admin = 9, og = 10, limited = 11}

	local function valueOf(m)
		local best = 0
		for _, k in ipairs({"Generation", "Income", "Value", "Price", "MoneyPerSec", "Cost"}) do
			local v = m:GetAttribute(k)
			if type(v) == "number" and v > best then best = v end
			if type(v) == "string" then
				local n = toNumber(v)
				if n > best then best = n end
			end
		end
		if best > 0 then return best end

		-- the sign above usually shows the $/s
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextBox") then
				local t = d.Text or ""
				if string.find(t, "%$") or string.find(string.lower(t), "/s") then
					local n = toNumber(t)
					if n > best then best = n end
				end
			end
		end
		if best > 0 then return best end

		local all = string.lower(m.Name)
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("TextLabel") then all = all .. " " .. string.lower(d.Text or "") end
		end
		for word, weight in pairs(RARITY) do
			if string.find(all, word, 1, true) and weight > best then best = weight end
		end
		return best
	end

	local function short(n)
		if n >= 1e12 then return string.format("%.1fT", n / 1e12) end
		if n >= 1e9  then return string.format("%.1fB", n / 1e9)  end
		if n >= 1e6  then return string.format("%.1fM", n / 1e6)  end
		if n >= 1e3  then return string.format("%.1fK", n / 1e3)  end
		return tostring(math.floor(n))
	end

	----------------------------------------------------------
	-- search
	----------------------------------------------------------
	local blacklist = {}

	local function posOf(m)
		if not m then return nil end
		if m:IsA("BasePart") then return m.Position end
		local ok, cf = pcall(function() return m:GetPivot() end)
		if ok and cf then return cf.Position end
		local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
		return pp and pp.Position or nil
	end

	local BAD = {"claim", "sell", "buy", "shop", "door", "rebirth", "upgrade",
		"spawn", "base", "conveyor", "plot", "wall", "floor"}

	local function badName(n)
		n = string.lower(n or "")
		for _, m in ipairs(BAD) do
			if string.find(n, m, 1, true) then return true end
		end
		return false
	end

	local function isTarget(o)
		if not o:IsA("Model") or not o.Parent then return false end
		if o == plr.Character then return false end
		if players:GetPlayerFromCharacter(o) then return false end
		if blacklist[o] then return false end
		if badName(o.Name) then return false end

		-- if its inside a character someone is already carrying it
		local pa = o.Parent
		while pa and pa ~= ws do
			if pa:IsA("Model") and players:GetPlayerFromCharacter(pa) then return false end
			pa = pa.Parent
		end

		local n = 0
		for _, p in ipairs(o:GetDescendants()) do
			if p:IsA("BasePart") then
				n = n + 1
				if n > 80 then return false end -- thats a building
			end
		end
		if n == 0 then return false end

		if o:FindFirstChildWhichIsA("ProximityPrompt", true) then return true end
		if o:FindFirstChildWhichIsA("BillboardGui", true) then return true end
		if o:FindFirstChildWhichIsA("Highlight", true) then return true end
		if o:GetAttribute("Generation") or o:GetAttribute("Rarity") then return true end
		if o:FindFirstChildOfClass("Humanoid") then return true end
		return false
	end

	local function scan(areaCF)
		local list, seen, pool = {}, {}, {}
		local center = areaCF.Position

		local folders = {}
		for _, n in ipairs({"Items", "Brainrots", "SpawnedItems", "Loot", "Drops", "RunningBrainrots"}) do
			local f = ws:FindFirstChild(n)
			if f then table.insert(folders, f) end
		end
		if #folders > 0 then
			for _, f in ipairs(folders) do
				for _, o in ipairs(f:GetDescendants()) do
					if o:IsA("Model") then table.insert(pool, o) end
				end
			end
		else
			for _, o in ipairs(ws:GetDescendants()) do
				if o:IsA("Model") then table.insert(pool, o) end
			end
		end

		for _, o in ipairs(pool) do
			if not seen[o] and isTarget(o) then
				local pos = posOf(o)
				if pos and (pos - center).Magnitude <= FARM.Radius then
					seen[o] = true
					table.insert(list, {model = o, pos = pos, name = o.Name, value = valueOf(o)})
				end
			end
		end

		-- most expensive first
		table.sort(list, function(a, b) return a.value > b.value end)
		return list
	end

	local f_touch  = rawget(getfenv(), "firetouchinterest") or (getgenv and getgenv().firetouchinterest)
	local f_prompt = rawget(getfenv(), "fireproximityprompt") or (getgenv and getgenv().fireproximityprompt)

	local function firePrompt(m)
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("ProximityPrompt") then
				pcall(function()
					p.Enabled = true
					p.RequiresLineOfSight = false
					p.MaxActivationDistance = math.max(p.MaxActivationDistance, 60)
					p.HoldDuration = 0
				end)
				if f_prompt then
					pcall(f_prompt, p, 1)
				else
					pcall(function()
						p:InputHoldBegin()
						task.wait(0.06)
						p:InputHoldEnd()
					end)
				end
			end
		end
	end

	local function fireTouch(m)
		if not f_touch then return end
		local root = hrp()
		if not root then return end
		local n = 0
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				pcall(f_touch, root, p, 0)
				pcall(f_touch, root, p, 1)
				n = n + 1
				if n >= 8 then break end
			end
		end
	end

	----------------------------------------------------------
	-- ui
	----------------------------------------------------------
	el:Header(king, "automatic")

	local lblState = el:Stat(king, "state", "idle", "dim")
	local lblClaims = el:Stat(king, "claims", "0", "gold")
	local lblZone  = el:Stat(king, "best in zone", "--", "loot")
	local lblCarry = el:Stat(king, "carrying", "no", "dim")

	local claims, running, curArea = 0, false, 1
	local attacking, atkGen = false, 0
	local tgFarm, tgAtk, tgNoclip

	local function setState(txt, col)
		lblState.Text = txt
		lblState.TextColor3 = col or GRAY
	end

	local function drawZone(list)
		if #list == 0 then
			lblZone.Text = "z" .. curArea .. " empty"
			lblZone.TextColor3 = DIM
			return
		end
		local top = list[1]
		lblZone.Text = "z" .. curArea .. "  " ..
			(top.value > 0 and short(top.value) or (#list .. " items"))
		lblZone.TextColor3 = PURPLE
	end

	----------------------------------------------------------
	-- auto attack
	-- one single thread, one FireServer every 0.5s. dont put it
	-- on Heartbeat or spawn a thread per shot, thats what lags
	----------------------------------------------------------
	local function stopAtk()
		if not attacking then return end
		attacking = false
		atkGen = atkGen + 1   -- this makes the running thread give up
		if tgAtk then tgAtk.Set(false) end
	end

	local function startAtk()
		if attacking then return end
		if not reAttack then
			el:Notify("no attack", "couldnt find AttackRequested", "err", 4)
			if tgAtk then tgAtk.Set(false) end
			return
		end
		attacking = true
		atkGen = atkGen + 1
		local mine = atkGen   -- my number. if it changes i was turned off
		if tgAtk then tgAtk.Set(true) end

		task.spawn(function()
			while attacking and atkGen == mine do
				if alive() then
					pcall(function() reAttack:FireServer() end)
				end
				-- split wait, so turning it off cuts instantly
				local t0 = os.clock()
				while os.clock() - t0 < ((cfg.farm and cfg.farm.atk_cooldown) or 0.5) do
					if not attacking or atkGen ~= mine then return end
					task.wait(0.1)
				end
			end
		end)
	end

	----------------------------------------------------------
	-- autofarm
	----------------------------------------------------------
	local function grabOne(obj)
		local m = obj.model
		if not m or not m.Parent then return "gone" end

		setState("grabbing", PURPLE)

		local pos = posOf(m) or obj.pos
		arrive(CFrame.new(pos + Vector3.new(0, 2.5, 0)))
		task.wait(0.12)

		firePrompt(m)
		fireTouch(m)

		local t0, i = os.clock(), 0
		while os.clock() - t0 < ((cfg.farm and cfg.farm.stomp) or 1.2) do
			if not running then return "stop" end
			if not m.Parent then break end
			if carrying() then break end

			local root = hrp()
			if root then
				i = i + 1
				local ang = i * 1.6
				local p = posOf(m) or pos
				root.CFrame = CFrame.new(p + Vector3.new(math.cos(ang) * 1.2, 2.2, math.sin(ang) * 1.2), p)
				root.AssemblyLinearVelocity = Vector3.zero
			end
			if i % 3 == 0 then firePrompt(m) fireTouch(m) end
			task.wait(0.08)
		end

		if not running then return "stop" end
		if carrying(true) then return "ok" end

		-- didnt work, blacklist it a while and move on
		blacklist[m] = true
		task.delay(12, function() blacklist[m] = nil end)
		return "fail"
	end

	local function takeToClaim()
		setState("to claim", GOLD)

		local root = hrp()
		if root and (root.Position - FARM.ClaimCF.Position).Magnitude > 250 then
			-- stop nearby and drop noclip there
			moveTo(CFrame.new(root.Position:Lerp(FARM.ClaimCF.Position, 0.75)))
		end

		-- NOCLIP OFF ONE SEC BEFORE GOING IN, else the zone wont catch me
		if noclipOn then
			noclip(false)
			if tgNoclip then tgNoclip.Set(false) end
			task.wait((cfg.farm and cfg.farm.noclip_off) or 1.0)
		end

		arrive(FARM.ClaimCF)

		stomp(FARM.ClaimCF, (cfg.farm and cfg.farm.claim_timeout) or 7, function()
			return (not running) or (not carrying())
		end)

		if not running then return false end

		if carrying(true) then
			arrive(FARM.ClaimCF)
			stomp(FARM.ClaimCF, 3, function() return not carrying() end)
		end

		local dropped = not carrying(true)
		if running then
			noclip(true)
			if tgNoclip then tgNoclip.Set(true) end
		end
		return dropped
	end

	local function loop()
		while running do
			local ok, err = pcall(function()

				if not alive() then
					setState("dead", RED)
					repeat task.wait(0.4) until (not running) or alive()
					task.wait(1)
					noclip(true)
					return
				end

				-- if im already carrying one, drop it first
				if carrying(true) then
					if takeToClaim() then
						claims = claims + 1
						lblClaims.Text = tostring(claims)
						setState("claim", GREEN)
						el:Notify("claimed", "total " .. claims, "ok", 2)
					end
					return
				end

				-- ALWAYS CHECK ZONE 1 FIRST. its the good one even if
				-- its almost always empty, still worth the trip
				local list, cf
				curArea = 1
				setState("checking z1", PURPLE)

				cf = FARM.Area1
				local root = hrp()
				if not root or (root.Position - cf.Position).Magnitude > FARM.Radius then
					arrive(cf)
					task.wait(0.4)
				end

				list = scan(cf)
				drawZone(list)

				if #list > 0 then
					el:Notify("zone 1", #list .. " in the good one", "loot", 2.2)
				else
					-- nothing in 1, go for 2
					curArea = 2
					cf = FARM.Area2
					setState("checking z2", LILAC)

					root = hrp()
					if not root or (root.Position - cf.Position).Magnitude > FARM.Radius then
						arrive(cf)
						task.wait(0.4)
					end
					list = scan(cf)
					drawZone(list)
				end

				if #list == 0 then
					setState("nothing", ORANGE)
					task.wait(FARM.Rescan)
					return
				end

				-- the first one is the most expensive
				local obj = list[1]
				local res = grabOne(obj)

				if res == "ok" then
					el:Notify("grabbed", obj.name ..
						(obj.value > 0 and ("  " .. short(obj.value)) or ""), "loot", 2)

					local dropped = takeToClaim()
					if not running then return end

					if dropped then
						claims = claims + 1
						lblClaims.Text = tostring(claims)
						setState("claim", GREEN)
						el:Notify("claimed", obj.name .. "  -  " .. claims, "ok", 2)
					else
						setState("not dropped", ORANGE)
						el:Notify("not dropped", "retrying", "warn", 2)
					end

				elseif res == "fail" then
					el:Notify("wouldnt grab", obj.name, "err", 2)
				end
			end)

			if not ok then
				setState("error", RED)
				el:Notify("something broke", tostring(err):sub(1, 60), "err", 3)
				task.wait(1.5)
			end
			task.wait(0.15)
		end
	end

	local function startAuto()
		if running then return end
		running = true
		if tgFarm then tgFarm.Set(true) end
		noclip(true)
		if tgNoclip then tgNoclip.Set(true) end
		setState("starting", ORANGE)
		el:Notify("auto farm on", "noclip on", "ok", 2.2)
		task.spawn(loop)
	end

	local function stopAuto()
		if not running then return end
		running = false
		if tgFarm then tgFarm.Set(false) end
		noclip(false)
		if tgNoclip then tgNoclip.Set(false) end
		setState("idle", GRAY)
		el:Notify("auto farm off", claims .. " claims", "warn", 2.2)
	end

	----------------------------------------------------------
	-- toggles
	----------------------------------------------------------
	el:Divider(king)

	tgFarm = el:Toggle("Auto Farm", king, false, function(v)
		if v then startAuto() else stopAuto() end
	end)

	tgAtk = el:Toggle("Auto Attack", king, false, function(v)
		if v then startAtk() else stopAtk() end
	end)

	tgNoclip = el:Toggle("Noclip", king, false, function(v)
		noclip(v)
	end)

	----------------------------------------------------------
	-- manual
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "manual")

	el:Button("go to zone 1", king, function()
		if not alive() then return el:Notify("dead", "wait to respawn", "err", 2) end
		arrive(FARM.Area1)
		el:Notify("tp", "zone 1", "ok", 1.6)
	end)

	el:Button("go to zone 2", king, function()
		if not alive() then return el:Notify("dead", "wait to respawn", "err", 2) end
		arrive(FARM.Area2)
		el:Notify("tp", "zone 2", "ok", 1.6)
	end)

	el:Button("go to claim", king, function()
		if not alive() then return el:Notify("dead", "wait to respawn", "err", 2) end
		local had = noclipOn
		if had then noclip(false) task.wait((cfg.farm and cfg.farm.noclip_off) or 1) end
		arrive(FARM.ClaimCF)
		if had then noclip(true) end
		el:Notify("tp", "claim zone", "ok", 1.6)
	end)

	----------------------------------------------------------
	-- remotes
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "remotes")
	el:Stat(king, "carry rf", rfCarry and "ok" or "missing", rfCarry and "ok" or "err")
	el:Stat(king, "attack re", reAttack and "ok" or "missing", reAttack and "ok" or "err")

	----------------------------------------------------------
	-- keybinds + refresh
	----------------------------------------------------------
	uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.F then
			if running then stopAuto() else startAuto() end
		elseif input.KeyCode == Enum.KeyCode.G then
			if attacking then stopAtk() else startAtk() end
		end
	end)

	plr.CharacterAdded:Connect(function()
		task.wait(1)
		if running then noclip(true) end
	end)

	task.spawn(function()
		while king and king.Parent do
			local has = carrying()
			lblCarry.Text = has and "yes" or "no"
			lblCarry.TextColor3 = has and GREEN or GRAY
			if not running then
				local cf = (curArea == 1) and FARM.Area1 or FARM.Area2
				local ok, list = pcall(scan, cf)
				if ok then drawZone(list) end
			end
			task.wait(1.5)
		end
	end)

	el:Label(king, "F = auto farm  -  G = auto attack", DIM, 13)
end
