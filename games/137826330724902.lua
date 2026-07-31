local mod = require and script and pcall(function() return require(script) end)
local src = [=[
return function(king, cfg, el)
	local players    = game:GetService("Players")
	local rs         = game:GetService("ReplicatedStorage")
	local runservice = game:GetService("RunService")
	local uis        = game:GetService("UserInputService")
	local ws         = game:GetService("Workspace")
	local plr        = players.LocalPlayer

	local GREEN   = Color3.fromRGB(0, 230, 100)
	local RED     = Color3.fromRGB(250, 40, 50)
	local ORANGE  = Color3.fromRGB(255, 140, 0)
	local WHITE   = Color3.fromRGB(255, 255, 255)
	local GRAY    = Color3.fromRGB(200, 205, 220)
	local DIM     = Color3.fromRGB(140, 145, 165)
	local BLACK   = Color3.fromRGB(0, 0, 0)

	local espEnabled = false
	local autoScan   = false
	local walkSpeed  = 16
	local speedOn    = false
	local activeESP  = {}

	el:Header(king, "scary shawarma kiosk")

	local lblScan   = el:Stat(king, "counter status", "safe", "ok")
	local lblTarget = el:Stat(king, "customer type", "none", "dim")
	local lblSpeed  = el:Stat(king, "walkspeed", "16", "loot")

	local function classifyEntity(model)
		if not model or not model:IsA("Model") or not model.Parent then return "none" end
		if model == plr.Character then return "none" end
		if players:GetPlayerFromCharacter(model) then return "none" end

		local name = string.lower(model.Name)

		if string.find(name, "inspector") or string.find(name, "killer") or string.find(name, "punisher") or string.find(name, "cleaner") then
			return "inspector"
		end

		local isAnomaly = model:GetAttribute("IsAnomaly") or model:GetAttribute("Anomaly") or model:GetAttribute("Corrupted") or model:GetAttribute("IsFake")
		if isAnomaly == true then return "anomaly" end

		if string.find(name, "anomaly") or string.find(name, "skinwalker") or string.find(name, "smiling") or string.find(name, "distorted") or string.find(name, "monster") or string.find(name, "fake") or string.find(name, "creature") then
			return "anomaly"
		end

		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BoolValue") or desc:IsA("StringValue") then
				local dName = string.lower(desc.Name)
				if string.find(dName, "anomaly") or string.find(dName, "corrupt") or string.find(dName, "fake") then
					if desc.Value == true or desc.Value == "true" or desc.Value == "Anomaly" or desc.Value == "Corrupted" then
						return "anomaly"
					end
				end
			end
		end

		if model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Head") or string.find(name, "customer") or string.find(name, "npc") or string.find(name, "buyer") or string.find(name, "human") or string.find(name, "person") then
			return "human"
		end

		return "none"
	end

	local function clearESP()
		for model, data in pairs(activeESP) do
			if data then
				if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
				if data.Billboard and data.Billboard.Parent then data.Billboard:Destroy() end
			end
		end
		table.clear(activeESP)
	end

	local function createOrUpdateESP(model, category)
		if not model or not model.Parent then return end

		local head = model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		if not head then return end

		local col = GREEN
		local textTag = "🟢 HUMAN [SAFE]"
		if category == "anomaly" then
			col = RED; textTag = "🔴 ANOMALY! [DO NOT SERVE]"
		elseif category == "inspector" then
			col = ORANGE; textTag = "🟠 INSPECTOR! [RUN/HIDE]"
		end

		local distStr = ""
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local d = math.floor((head.Position - plr.Character.HumanoidRootPart.Position).Magnitude)
			distStr = " (" .. d .. "m)"
		end

		local data = activeESP[model]

		if not data or not data.Billboard or not data.Billboard.Parent then
			local hl = Instance.new("Highlight")
			hl.Name = "ShawarmaHighlightESP"
			hl.Adornee = model
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.FillColor = col; hl.OutlineColor = col
			hl.FillTransparency = 0.45; hl.OutlineTransparency = 0.1
			pcall(function() hl.Parent = model end)

			local bb = Instance.new("BillboardGui")
			bb.Name = "ShawarmaTextESP"
			bb.Adornee = head
			bb.AlwaysOnTop = true
			bb.Size = UDim2.new(0, 160, 0, 40)
			bb.StudsOffset = Vector3.new(0, 2.5, 0)

			local txt = Instance.new("TextLabel")
			txt.Name = "Tag"
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.Text = textTag .. distStr
			txt.TextColor3 = col
			txt.TextSize = 13
			txt.Font = Enum.Font.FredokaOne
			txt.TextStrokeTransparency = 0
			txt.TextStrokeColor3 = BLACK
			txt.Parent = bb

			pcall(function() bb.Parent = head end)
			activeESP[model] = { Highlight = hl, Billboard = bb, Text = txt, Category = category }
		else
			data.Highlight.FillColor = col; data.Highlight.OutlineColor = col
			data.Text.TextColor3 = col
			data.Text.Text = textTag .. distStr
		end
	end

	local function scanAndApplyESP()
		if not espEnabled then clearESP() return end
		local currentTargets = {}

		for _, obj in ipairs(ws:GetDescendants()) do
			if obj:IsA("Model") and obj ~= plr.Character then
				local cat = classifyEntity(obj)
				if cat == "human" or cat == "anomaly" or cat == "inspector" then
					currentTargets[obj] = cat
					createOrUpdateESP(obj, cat)
				end
			end
		end

		for model, data in pairs(activeESP) do
			if not currentTargets[model] or not model.Parent then
				if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
				if data.Billboard and data.Billboard.Parent then data.Billboard:Destroy() end
				activeESP[model] = nil
			end
		end
	end

	task.spawn(function()
		while true do
			if espEnabled then pcall(scanAndApplyESP) end
			task.wait(0.3)
		end
	end)

	local lastAlertState = "none"
	local function checkCurrentCustomer()
		local detectedAnomaly, detectedInspector, detectedHuman = false, false, false
		for _, obj in ipairs(ws:GetDescendants()) do
			if obj:IsA("Model") and obj ~= plr.Character then
				local cat = classifyEntity(obj)
				if cat == "inspector" then detectedInspector = true
				elseif cat == "anomaly" then detectedAnomaly = true
				elseif cat == "human" then detectedHuman = true end
			end
		end

		if detectedInspector then
			lblScan.Text = "INSPECTOR AT KIOSK!"; lblScan.TextColor3 = ORANGE
			lblTarget.Text = "inspector (killer)"; lblTarget.TextColor3 = ORANGE
			if lastAlertState ~= "inspector" then lastAlertState = "inspector"; el:Notify("DANGER!", "Inspector entity detected!", "err", 4) end
		elseif detectedAnomaly then
			lblScan.Text = "ANOMALY DETECTED!"; lblScan.TextColor3 = RED
			lblTarget.Text = "anomaly (do not serve)"; lblTarget.TextColor3 = RED
			if lastAlertState ~= "anomaly" then lastAlertState = "anomaly"; el:Notify("ANOMALY!", "Close shutter now!", "err", 3.5) end
		elseif detectedHuman then
			lblScan.Text = "safe customer"; lblScan.TextColor3 = GREEN
			lblTarget.Text = "human (safe)"; lblTarget.TextColor3 = GREEN
			if lastAlertState ~= "human" then lastAlertState = "human"; el:Notify("SAFE", "Normal customer. Safe to serve.", "ok", 2) end
		else
			lblScan.Text = "no customer"; lblScan.TextColor3 = GRAY
			lblTarget.Text = "counter empty"; lblTarget.TextColor3 = DIM
			lastAlertState = "none"
		end
	end

	task.spawn(function()
		while true do
			if autoScan then pcall(checkCurrentCustomer) end
			task.wait(0.5)
		end
	end)

	runservice.Heartbeat:Connect(function()
		if speedOn and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = walkSpeed end
		end
	end)

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
			el:Notify("invalid speed", "enter number 16 - 150", "warn", 2.2)
		end
	end)

	el:Divider(king)
	el:Header(king, "kiosk actions")

	el:Button("toggle shutter (close/open)", king, function()
		local toggled = false
		for _, desc in ipairs(ws:GetDescendants()) do
			if desc:IsA("ProximityPrompt") and (string.find(string.lower(desc.Name), "shutter") or string.find(string.lower(desc.Parent.Name), "shutter") or string.find(string.lower(desc.Parent.Name), "door")) then
				pcall(function() fireproximityprompt(desc, 1); toggled = true end)
			end
		end
		if toggled then el:Notify("shutter", "toggled shutter", "ok", 1.8)
		else el:Notify("shutter", "press shutter button manually", "warn", 2) end
	end)

	el:Button("tp to backyard (hide)", king, function()
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
				el:Notify("tp", "teleported to backyard", "ok", 1.8)
			else
				plr.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -25)
				el:Notify("tp", "teleported backwards", "info", 1.8)
			end
		end
	end)

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
]=]
return loadstring(src)()
