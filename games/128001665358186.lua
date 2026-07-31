local mod = require and script and pcall(function() return require(script) end)
local src = [=[
return function(king, cfg, el)
	local players    = game:GetService("Players")
	local rs         = game:GetService("ReplicatedStorage")
	local runservice = game:GetService("RunService")
	local uis        = game:GetService("UserInputService")
	local ws         = game:GetService("Workspace")
	local plr        = players.LocalPlayer

	local GREEN = Color3.fromRGB(0, 255, 100)
	local RED   = Color3.fromRGB(255, 30, 40)
	local WHITE = Color3.fromRGB(255, 255, 255)
	local GRAY  = Color3.fromRGB(200, 205, 220)
	local DIM   = Color3.fromRGB(140, 145, 165)

	local espEnabled = false
	local walkSpeed  = 16
	local speedOn    = false
	local activeHighlights = {}

	el:Header(king, "scary shawarma kiosk")

	local lblScan   = el:Stat(king, "customer status", "none", "dim")
	local lblSpeed  = el:Stat(king, "walkspeed", "16", "loot")

	local function checkIsAnomaly(model)
		if not model or not model:IsA("Model") or not model.Parent then return false end
		if model == plr.Character then return false end
		if players:GetPlayerFromCharacter(model) then return false end

		if model:GetAttribute("IsAnomaly") == true 
		or model:GetAttribute("Anomaly") == true 
		or model:GetAttribute("IsFake") == true 
		or model:GetAttribute("Corrupted") == true
		or model:GetAttribute("IsCorrupted") == true then
			return true
		end

		if model:GetAttribute("RealCustomer") == false 
		or model:GetAttribute("IsReal") == false 
		or model:GetAttribute("IsHuman") == false then
			return true
		end

		local mName = string.lower(model.Name)
		if string.find(mName, "anomaly") or string.find(mName, "fake") or string.find(mName, "skinwalker") or string.find(mName, "smiling") or string.find(mName, "distorted") or string.find(mName, "monster") or string.find(mName, "creature") or string.find(mName, "inspector") or string.find(mName, "killer") then
			return true
		end

		for _, v in ipairs(model:GetDescendants()) do
			if v:IsA("ValueBase") then
				local vName = string.lower(v.Name)
				if string.find(vName, "anomaly") or string.find(vName, "fake") or string.find(vName, "corrupt") then
					if v.Value == true or v.Value == "true" or v.Value == "Anomaly" or v.Value == "Corrupted" or v.Value == "Fake" then
						return true
					end
				elseif string.find(vName, "real") or string.find(vName, "human") then
					if v.Value == false or v.Value == "false" then
						return true
					end
				end
			end

			if v:IsA("Decal") and string.find(string.lower(v.Name), "face") then
				if string.find(tostring(v.Texture), "0") or v.Transparency == 1 then
					return true
				end
			end
		end

		return false
	end

	local function isCustomerModel(model)
		if not model or not model:IsA("Model") or not model.Parent then return false end
		if model == plr.Character then return false end
		if players:GetPlayerFromCharacter(model) then return false end

		local mName = string.lower(model.Name)
		if model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Head") or string.find(mName, "customer") or string.find(mName, "npc") or string.find(mName, "buyer") or string.find(mName, "human") or string.find(mName, "person") or string.find(mName, "anomaly") or string.find(mName, "skinwalker") then
			return true
		end

		return false
	end

	local function clearESP()
		for model, hl in pairs(activeHighlights) do
			if hl and hl.Parent then hl:Destroy() end
		end
		table.clear(activeHighlights)
	end

	local function applyBodyESP(model, isAnomalous)
		if not model or not model.Parent then return end
		local targetColor = isAnomalous and RED or GREEN

		if activeHighlights[model] and activeHighlights[model].Parent then
			local hl = activeHighlights[model]
			hl.FillColor = targetColor
			hl.OutlineColor = targetColor
			return
		end

		local hl = Instance.new("Highlight")
		hl.Name = "BodyESP"
		hl.Adornee = model
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillColor = targetColor
		hl.OutlineColor = targetColor
		hl.FillTransparency = 0.40
		hl.OutlineTransparency = 0.0

		pcall(function() hl.Parent = model end)
		activeHighlights[model] = hl
	end

	local function updateESPAndStatus()
		if not espEnabled then
			clearESP()
			lblScan.Text = "esp disabled"
			lblScan.TextColor3 = GRAY
			return
		end

		local currentCustomers = {}
		local foundAnomalyAtCounter = false
		local foundHumanAtCounter = false

		for _, obj in ipairs(ws:GetDescendants()) do
			if obj:IsA("Model") and isCustomerModel(obj) then
				currentCustomers[obj] = true
				local anomalous = checkIsAnomaly(obj)
				applyBodyESP(obj, anomalous)

				if anomalous then foundAnomalyAtCounter = true
				else foundHumanAtCounter = true end
			end
		end

		if foundAnomalyAtCounter then
			lblScan.Text = "ANOMALY (RED)"
			lblScan.TextColor3 = RED
		elseif foundHumanAtCounter then
			lblScan.Text = "HUMAN (GREEN)"
			lblScan.TextColor3 = GREEN
		else
			lblScan.Text = "no customer"
			lblScan.TextColor3 = DIM
		end

		for model, hl in pairs(activeHighlights) do
			if not currentCustomers[model] or not model.Parent then
				if hl and hl.Parent then hl:Destroy() end
				activeHighlights[model] = nil
			end
		end
	end

	task.spawn(function()
		while true do
			if espEnabled then pcall(updateESPAndStatus) end
			task.wait(0.3)
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

	el:Toggle("ESP Body Outline & Fill", king, false, function(v)
		espEnabled = v
		if not v then clearESP() end
		el:Notify("esp", v and "enabled (Green=Human, Red=Anomaly)" or "disabled", "info", 2.2)
	end)

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
