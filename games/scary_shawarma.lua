--// Scary Shawarma Kiosk: The Anomaly - Game Module for Loaded Hub
--// Place IDs: 137826330724902 (Lobby) / 128001665358186 (In Game 1 Player)

return function(king, cfg, el)
	local players    = game:GetService("Players")
	local rs         = game:GetService("ReplicatedStorage")
	local runservice = game:GetService("RunService")
	local uis        = game:GetService("UserInputService")
	local ws         = game:GetService("Workspace")
	local plr        = players.LocalPlayer

	----------------------------------------------------------
	-- COLORS
	----------------------------------------------------------
	local GREEN   = Color3.fromRGB(0, 230, 100)
	local RED     = Color3.fromRGB(250, 40, 50)
	local ORANGE  = Color3.fromRGB(255, 140, 0)
	local WHITE   = Color3.fromRGB(255, 255, 255)
	local GRAY    = Color3.fromRGB(200, 205, 220)
	local DIM     = Color3.fromRGB(140, 145, 165)

	----------------------------------------------------------
	-- STATE & SETTINGS
	----------------------------------------------------------
	local espEnabled = false
	local autoScan   = false
	local walkSpeed  = 16
	local speedOn    = false
	local activeHighlights = {}

	----------------------------------------------------------
	-- UI INTERFACE
	----------------------------------------------------------
	el:Header(king, "scary shawarma kiosk")

	local lblScan   = el:Stat(king, "counter status", "safe", "ok")
	local lblTarget = el:Stat(king, "customer type", "none", "dim")
	local lblSpeed  = el:Stat(king, "walkspeed", "16", "loot")

	----------------------------------------------------------
	-- HELPER: CLASSIFY ENTITY / CUSTOMER
	----------------------------------------------------------
	local function classifyEntity(model)
		if not model or not model:IsA("Model") then return "none" end
		if model == plr.Character then return "none" end
		if players:GetPlayerFromCharacter(model) then return "human_player" end

		local name = string.lower(model.Name)

		if string.find(name, "inspector") or string.find(name, "floor") or string.find(name, "killer") or string.find(name, "punisher") then
			return "inspector"
		end

		local isAnomaly = model:GetAttribute("IsAnomaly") or model:GetAttribute("Anomaly") or model:GetAttribute("Corrupted")
		if isAnomaly == true then return "anomaly" end

		if string.find(name, "anomaly") or string.find(name, "skinwalker") or string.find(name, "smiling") or string.find(name, "distorted") or string.find(name, "monster") or string.find(name, "fake") then
			return "anomaly"
		end

		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("StringValue") or desc:IsA("BoolValue") then
				local dName = string.lower(desc.Name)
				if string.find(dName, "anomaly") or string.find(dName, "corrupt") then
					if desc.Value == true or desc.Value == "true" or desc.Value == "Anomaly" then
						return "anomaly"
					end
				end
			end
		end

		if model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Head") then
			return "human"
		end

		return "none"
	end

	----------------------------------------------------------
	-- ESP ENGINE
	----------------------------------------------------------
	local function clearESP()
		for model, hl in pairs(activeHighlights) do
			if hl and hl.Parent then
				hl:Destroy()
			end
		end
		table.clear(activeHighlights)
	end

	local function applyESP(model, category)
		if not model or not model.Parent then return end
		if activeHighlights[model] and activeHighlights[model].Parent then
			local hl = activeHighlights[model]
			if category == "human" then
				hl.FillColor = GREEN; hl.OutlineColor = GREEN
			elseif category == "anomaly" then
				hl.FillColor = RED; hl.OutlineColor = RED
			elseif category == "inspector" then
				hl.FillColor = ORANGE; hl.OutlineColor = ORANGE
			end
			return
		end

		local hl = Instance.new("Highlight")
		hl.Name = "ShawarmaESP"
		hl.Adornee = model
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillTransparency = 0.45
		hl.OutlineTransparency = 0.1

		if category == "human" then
			hl.FillColor = GREEN; hl.OutlineColor = GREEN
		elseif category == "anomaly" then
			hl.FillColor = RED; hl.OutlineColor = RED
		elseif category == "inspector" then
			hl.FillColor = ORANGE; hl.OutlineColor = ORANGE
		else
			return
		end

		hl.Parent = model
		activeHighlights[model] = hl
	end

	local function scanAndApplyESP()
		if not espEnabled then
			clearESP()
			return
		end

		local currentTargets = {}
		for _, obj in ipairs(ws:GetDescendants()) do
			if obj:IsA("Model") and obj ~= plr.Character then
				local cat = classifyEntity(obj)
				if cat == "human" or cat == "anomaly" or cat == "inspector" then
					currentTargets[obj] = cat
					applyESP(obj, cat)
				end
			end
		end

		for model, hl in pairs(activeHighlights) do
			if not currentTargets[model] or not model.Parent then
				if hl and hl.Parent then hl:Destroy() end
				activeHighlights[model] = nil
			end
		end
	end

	task.spawn(function()
		while true do
			if espEnabled then
				pcall(scanAndApplyESP)
			end
			task.wait(0.5)
		end
	end)

	----------------------------------------------------------
	-- AUTO SCANNER
	----------------------------------------------------------
	local lastAlertState = "none"

	local function checkCurrentCustomer()
		local detectedAnomaly = false
		local detectedInspector = false
		local detectedHuman = false

		for _, obj in ipairs(ws:GetDescendants()) do
			if obj:IsA("Model") and obj ~= plr.Character then
				local cat = classifyEntity(obj)
				if cat == "inspector" then
					detectedInspector = true
				elseif cat == "anomaly" then
					detectedAnomaly = true
				elseif cat == "human" then
					detectedHuman = true
				end
			end
		end

		if detectedInspector then
			lblScan.Text = "INSPECTOR AT KIOSK!"
			lblScan.TextColor3 = ORANGE
			lblTarget.Text = "inspector (killer)"
			lblTarget.TextColor3 = ORANGE
			if lastAlertState ~= "inspector" then
				lastAlertState = "inspector"
				el:Notify("DANGER!", "Inspector entity detected! Hide in backyard!", "err", 4)
			end
		elseif detectedAnomaly then
			lblScan.Text = "ANOMALY DETECTED!"
			lblScan.TextColor3 = RED
			lblTarget.Text = "anomaly (do not serve)"
			lblTarget.TextColor3 = RED
			if lastAlertState ~= "anomaly" then
				lastAlertState = "anomaly"
				el:Notify("ANOMALY!", "Anomalous customer! Close shutter!", "err", 3.5)
			end
		elseif detectedHuman then
			lblScan.Text = "safe customer"
			lblScan.TextColor3 = GREEN
			lblTarget.Text = "human (safe to serve)"
			lblTarget.TextColor3 = GREEN
			if lastAlertState ~= "human" then
				lastAlertState = "human"
				el:Notify("SAFE", "Normal human customer. Safe to serve.", "ok", 2)
			end
		else
			lblScan.Text = "no customer"
			lblScan.TextColor3 = GRAY
			lblTarget.Text = "counter empty"
			lblTarget.TextColor3 = DIM
			lastAlertState = "none"
		end
	end

	task.spawn(function()
		while true do
			if autoScan then
				pcall(checkCurrentCustomer)
			end
			task.wait(0.6)
		end
	end)

	----------------------------------------------------------
	-- SPEED CHANGER
	----------------------------------------------------------
	runservice.Heartbeat:Connect(function()
		if speedOn and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = walkSpeed
			end
		end
	end)

	----------------------------------------------------------
	-- CONTROLS
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "visuals & esp")

	el:Toggle("ESP Customers & Anomalies", king, false, function(v)
		espEnabled = v
		if not v then clearESP() end
		el:Notify("esp", v and "enabled (Green=Human, Red=Anomaly, Orange=Inspector)" or "disabled", "info", 2.2)
	end)

	el:Toggle("Auto Scan Customer", king, true, function(v)
		autoScan = v
		el:Notify("auto scan", v and "enabled" or "disabled", "info", 1.8)
	end)
	autoScan = true

	----------------------------------------------------------
	-- SPEED & MOVEMENT
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "player movement")

	el:Toggle("Enable Speed Changer", king, false, function(v)
		speedOn = v
		if not v and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = 16 end
		end
		el:Notify("speed", v and ("set to " .. walkSpeed) or "reset to 16", "info", 1.8)
	end)

	el:Textbox("WalkSpeed Value", king, tostring(walkSpeed), function(txt)
		local num = tonumber(txt)
		if num and num >= 16 and num <= 150 then
			walkSpeed = num
			lblSpeed.Text = tostring(num)
			el:Notify("speed set", tostring(num), "ok", 1.8)
		else
			el:Notify("invalid speed", "enter a number between 16 and 150", "warn", 2.2)
		end
	end)

	----------------------------------------------------------
	-- SHUTTER & HELPER ACTIONS
	----------------------------------------------------------
	el:Divider(king)
	el:Header(king, "kiosk actions")

	el:Button("toggle shutter (close/open)", king, function()
		local toggled = false
		for _, desc in ipairs(ws:GetDescendants()) do
			if desc:IsA("ProximityPrompt") and (string.find(string.lower(desc.Name), "shutter") or string.find(string.lower(desc.Parent.Name), "shutter") or string.find(string.lower(desc.Parent.Name), "door")) then
				pcall(function()
					fireproximityprompt(desc, 1)
					toggled = true
				end)
			end
		end
		if toggled then
			el:Notify("shutter", "toggled shutter door", "ok", 1.8)
		else
			el:Notify("shutter", "press shutter button manually", "warn", 2)
		end
	end)

	el:Button("tp to backyard (hide from inspector)", king, function()
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local hidingSpot = nil
			for _, obj in ipairs(ws:GetDescendants()) do
				if obj:IsA("BasePart") and (string.find(string.lower(obj.Name), "trash") or string.find(string.lower(obj.Name), "backyard")) then
					hidingSpot = obj.CFrame + Vector3.new(0, 3, 0)
					break
				end
			end

			if hidingSpot then
				plr.Character.HumanoidRootPart.CFrame = hidingSpot
				el:Notify("tp", "teleported to backyard hiding spot", "ok", 1.8)
			else
				plr.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -25)
				el:Notify("tp", "teleported backwards to safe area", "info", 1.8)
			end
		end
	end)

	----------------------------------------------------------
	-- KEYBINDS
	----------------------------------------------------------
	uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.E then
			espEnabled = not espEnabled
			if not espEnabled then clearESP() end
			el:Notify("esp toggle", espEnabled and "enabled" or "disabled", "info", 1.5)
		end
	end)

	el:Label(king, "E = toggle ESP on / off", DIM, 13)
end
