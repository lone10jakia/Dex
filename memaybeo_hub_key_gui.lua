-- ====================[ KEY GUI CLEAN ]===================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local lp = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- Key GUI
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "MEMAYBEO_KEY_GUI"
keyGui.ResetOnSpawn = false
keyGui.IgnoreGuiInset = true
keyGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame", keyGui)
Frame.Size = UDim2.new(0, 360, 0, 220)
Frame.Position = UDim2.new(0.5, -180, 0.5, -110)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.2
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 14)

-- Viền 7 màu (giảm lag bằng cách throttle)
local UIStroke = Instance.new("UIStroke", Frame)
UIStroke.Thickness = 2.5
do
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		UIStroke.Color = Color3.fromHSV((tick() * 0.35 % 1), 1, 1)
	end)
end

-- Title
local title = Instance.new("TextLabel", Frame)
title.Size = UDim2.new(1, 0, 0, 32)
title.Text = "MEMAYBEO HUB - NHẬP KEY"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 22

-- Info
local info = Instance.new("TextLabel", Frame)
info.Size = UDim2.new(1, -20, 0, 40)
info.Position = UDim2.new(0, 10, 0, 40)
info.BackgroundTransparency = 1
info.Text = "Mua key VIP ib TikTok: memaybeohub"
info.TextColor3 = Color3.fromRGB(220, 220, 220)
info.Font = Enum.Font.Gotham
info.TextSize = 17
info.TextWrapped = true

-- Input box
local box = Instance.new("TextBox", Frame)
box.Size = UDim2.new(0.85, 0, 0, 40)
box.Position = UDim2.new(0.075, 0, 0, 95)
box.PlaceholderText = "Nhập key..."
box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
box.BackgroundTransparency = 0.3
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.GothamBold
box.TextSize = 18
box.Text = ""
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)

-- Confirm button
local confirm = Instance.new("TextButton", Frame)
confirm.Size = UDim2.new(0.55, 0, 0, 40)
confirm.Position = UDim2.new(0.225, 0, 0, 150)
confirm.Text = "Xác nhận"
confirm.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
confirm.TextColor3 = Color3.new(1, 1, 1)
confirm.Font = Enum.Font.GothamBold
confirm.TextSize = 18
Instance.new("UICorner", confirm).CornerRadius = UDim.new(0, 12)

-- Keys
local KEY_FREE = "free123"
local KEY_VIP = "vip123"
local Valid = false

confirm.MouseButton1Click:Connect(function()
	local k = tostring(box.Text)
	if k == KEY_FREE or k == KEY_VIP then
		Valid = true
		keyGui:Destroy()
	else
		confirm.Text = "Sai key!"
		confirm.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
		task.wait(1)
		confirm.Text = "Xác nhận"
		confirm.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	end
end)
repeat task.wait() until Valid

-- ====================[ ANTI AFK ]===================
lp.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- ====================[ NHÂN VẬT ]===================
local hrp, hum
local function getChar()
	local char = lp.Character or lp.CharacterAdded:Wait()
	hrp = char:WaitForChild("HumanoidRootPart")
	hum = char:WaitForChild("Humanoid")
	return char
end
getChar()
lp.CharacterAdded:Connect(function()
	task.wait(1)
	getChar()
end)

-- ====================[ GUI CHÍNH + COLLAPSE ]===================
local guiMain = Instance.new("ScreenGui", lp:WaitForChild("PlayerGui"))
guiMain.Name = "MEMAYBEO_HUB"

local main = Instance.new("Frame", guiMain)
main.Size = UDim2.new(0, 300, 0, 470)
main.Position = UDim2.new(0.05, 0, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BackgroundTransparency = 0.2
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

-- 7 màu viền (giảm lag)
local UIStroke2 = Instance.new("UIStroke", main)
UIStroke2.Thickness = 2
do
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		UIStroke2.Color = Color3.fromHSV((tick() * 0.4 % 1), 1, 1)
	end)
end

-- Title
local title2 = Instance.new("TextLabel", main)
title2.Size = UDim2.new(1, 0, 0, 30)
title2.Position = UDim2.new(0, 0, 0, 0)
title2.BackgroundTransparency = 1
title2.Text = "MEMAYBEO HUB"
title2.TextColor3 = Color3.new(1, 1, 1)
title2.Font = Enum.Font.SourceSansBold
title2.TextSize = 18

-- Collapse button
local collapseBtn = Instance.new("TextButton", main)
collapseBtn.Size = UDim2.new(0, 30, 0, 30)
collapseBtn.Position = UDim2.new(1, -35, 0, 0)
collapseBtn.Text = "-"
collapseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
collapseBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0, 6)

-- Content
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, 0, 1, -30)
content.Position = UDim2.new(0, 0, 0, 30)
content.BackgroundTransparency = 1

-- Nút Farm
local btnFarm = Instance.new("TextButton", content)
btnFarm.Size = UDim2.new(0, 260, 0, 30)
btnFarm.Position = UDim2.new(0, 20, 0, 10)
btnFarm.Text = "✅ Auto Farm NPC2"
btnFarm.TextColor3 = Color3.new(1, 1, 1)
btnFarm.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", btnFarm).CornerRadius = UDim.new(0, 8)

-- Auto Pickup
local btnPickup = Instance.new("TextButton", content)
btnPickup.Size = UDim2.new(0, 260, 0, 30)
btnPickup.Position = UDim2.new(0, 20, 0, 50)
btnPickup.Text = "🟢 Auto Nhặt Vật Phẩm (OFF)"
btnPickup.TextColor3 = Color3.new(1, 1, 1)
btnPickup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", btnPickup).CornerRadius = UDim.new(0, 8)

-- Server Hop
local btnHop = Instance.new("TextButton", content)
btnHop.Size = UDim2.new(0, 260, 0, 30)
btnHop.Position = UDim2.new(0, 20, 0, 90)
btnHop.Text = "🌐 Đổi Server"
btnHop.TextColor3 = Color3.new(1, 1, 1)
btnHop.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", btnHop).CornerRadius = UDim.new(0, 8)

-- Thanh HP
local hpBg = Instance.new("Frame", content)
hpBg.Size = UDim2.new(1, -40, 0, 25)
hpBg.Position = UDim2.new(0, 20, 0, 130)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 6)

local hpLabel = Instance.new("TextLabel", hpBg)
hpLabel.Size = UDim2.new(1, 0, 1, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.TextColor3 = Color3.new(1, 1, 1)
hpLabel.Font = Enum.Font.SourceSansBold
hpLabel.TextSize = 16
hpLabel.Text = "NPC2: ??? / ???"

-- Auto băng + chọn vũ khí
local btnAutoBang = Instance.new("TextButton", content)
btnAutoBang.Size = UDim2.new(0, 260, 0, 30)
btnAutoBang.Position = UDim2.new(0, 20, 0, 170)
btnAutoBang.Text = "🤕 Auto Băng (OFF)"
btnAutoBang.TextColor3 = Color3.new(1, 1, 1)
btnAutoBang.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", btnAutoBang).CornerRadius = UDim.new(0, 8)

local btnCityFarm = Instance.new("TextButton", content)
btnCityFarm.Size = UDim2.new(0, 260, 0, 30)
btnCityFarm.Position = UDim2.new(0, 20, 0, 170)
btnCityFarm.Text = "⚔️ Auto Farm CityNPC (OFF)"
btnCityFarm.TextColor3 = Color3.new(1, 1, 1)
btnCityFarm.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", btnCityFarm).CornerRadius = UDim.new(0, 8)

local btnCityPickup = Instance.new("TextButton", content)
btnCityPickup.Size = UDim2.new(0, 260, 0, 30)
btnCityPickup.Position = UDim2.new(0, 20, 0, 210)
btnCityPickup.Text = "📦 Nhặt Drop CityNPC (OFF)"
btnCityPickup.TextColor3 = Color3.new(1, 1, 1)
btnCityPickup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", btnCityPickup).CornerRadius = UDim.new(0, 8)

btnAutoBang.Position = UDim2.new(0, 20, 0, 250)

local weaponLabel = Instance.new("TextLabel", content)
weaponLabel.Size = UDim2.new(0, 260, 0, 20)
weaponLabel.Position = UDim2.new(0, 20, 0, 290)
weaponLabel.BackgroundTransparency = 1
weaponLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
weaponLabel.Font = Enum.Font.SourceSans
weaponLabel.TextSize = 16
weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponLabel.Text = "🎯 Vũ khí: (chưa chọn)"

local btnWeapon = Instance.new("TextButton", content)
btnWeapon.Size = UDim2.new(0, 260, 0, 30)
btnWeapon.Position = UDim2.new(0, 20, 0, 315)
btnWeapon.Text = "🎯 Chọn vũ khí"
btnWeapon.TextColor3 = Color3.new(1, 1, 1)
btnWeapon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", btnWeapon).CornerRadius = UDim.new(0, 8)

-- Collapse logic
local collapsed = false
collapseBtn.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	content.Visible = not collapsed
	main.Size = collapsed and UDim2.new(0, 300, 0, 30) or UDim2.new(0, 300, 0, 470)
	collapseBtn.Text = collapsed and "+" or "-"
end)

-- ====================[ AUTO FARM + PICKUP + SERVER HOP LOGIC ]===================
local farming = false
local autoPickup = false
local orbitAngle = 0
local cityFarm = false
local cityPickup = false

btnFarm.MouseButton1Click:Connect(function()
	farming = not farming
	btnFarm.Text = farming and "🟢 Đang Farm NPC2" or "✅ Auto Farm NPC2"
	btnFarm.BackgroundColor3 = farming and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

btnPickup.MouseButton1Click:Connect(function()
	autoPickup = not autoPickup
	btnPickup.Text = autoPickup and "🟢 Auto Nhặt Vật Phẩm (ON)" or "🟢 Auto Nhặt Vật Phẩm (OFF)"
	btnPickup.BackgroundColor3 = autoPickup and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

btnHop.MouseButton1Click:Connect(function()
	local gameId = game.PlaceId
	local best
	local cursor = ""
	while true do
		local url = "https://games.roblox.com/v1/games/" .. gameId .. "/servers/Public?limit=100&cursor=" .. cursor
		local s, data = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(url))
		end)
		if not s then
			break
		end
		for _, srv in ipairs(data.data) do
			if srv.id ~= game.JobId then
				best = srv.id
				break
			end
		end
		if best then
			break
		end
		cursor = data.nextPageCursor
		if not cursor then
			break
		end
	end
	if best then
		TeleportService:TeleportToPlaceInstance(gameId, best, lp)
	end
end)

btnCityFarm.MouseButton1Click:Connect(function()
	cityFarm = not cityFarm
	btnCityFarm.Text = cityFarm and "⚔️ Auto Farm CityNPC (ON)" or "⚔️ Auto Farm CityNPC (OFF)"
	btnCityFarm.BackgroundColor3 = cityFarm and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

btnCityPickup.MouseButton1Click:Connect(function()
	cityPickup = not cityPickup
	btnCityPickup.Text = cityPickup and "📦 Nhặt Drop CityNPC (ON)" or "📦 Nhặt Drop CityNPC (OFF)"
	btnCityPickup.BackgroundColor3 = cityPickup and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

local function isHealTool(tool)
	local n = tool.Name:lower()
	return n:find("bang") or n:find("băng") or n:find("med") or n:find("heal") or n:find("kit") or n:find("band")
end

local function findBandagePrompt()
	local shop = workspace:FindFirstChild("NPCs")
		and workspace.NPCs:FindFirstChild("Shop")
		and workspace.NPCs.Shop:FindFirstChild("Bán băng gạc")
	if not shop then
		return nil
	end
	for _, prompt in ipairs(shop:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			return prompt
		end
	end
	return nil
end

local function buyBandagePack()
	if not fireproximityprompt then
		return false
	end
	local prompt = findBandagePrompt()
	if not prompt then
		return false
	end
	for _ = 1, 5 do
		pcall(function()
			fireproximityprompt(prompt)
		end)
		task.wait(0.2)
	end
	return true
end

local preferredWeaponName = ""
local function setPreferredWeapon(tool)
	if tool and tool:IsA("Tool") and not isHealTool(tool) then
		preferredWeaponName = tool.Name
		weaponLabel.Text = "🎯 Vũ khí: " .. preferredWeaponName
		return true
	end
	return false
end

btnWeapon.MouseButton1Click:Connect(function()
	local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
	if not tool then
		for _, v in ipairs(lp.Backpack:GetChildren()) do
			if v:IsA("Tool") and not isHealTool(v) then
				tool = v
				break
			end
		end
	end

	if setPreferredWeapon(tool) then
		btnWeapon.Text = "🎯 Đã lưu"
	else
		btnWeapon.Text = "❌ Không thấy"
	end
	task.delay(0.8, function()
		if btnWeapon then
			btnWeapon.Text = "🎯 Chọn vũ khí"
		end
	end)
end)

local autoBang = false
local autoBangThreshold = 75
local healingInProgress = false
local lastHealAt = 0

btnAutoBang.MouseButton1Click:Connect(function()
	autoBang = not autoBang
	btnAutoBang.Text = autoBang and "🤕 Auto Băng (ON)" or "🤕 Auto Băng (OFF)"
	btnAutoBang.BackgroundColor3 = autoBang and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

local function findHealTool()
	local char = lp.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and isHealTool(tool) then
				return tool
			end
		end
	end

	for _, tool in ipairs(lp.Backpack:GetChildren()) do
		if tool:IsA("Tool") and isHealTool(tool) then
			return tool
		end
	end

	return nil
end

local function findToolByName(name)
	if name == "" then
		return nil
	end
	local lower = name:lower()
	local char = lp.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and tool.Name:lower() == lower then
				return tool
			end
		end
	end
	for _, tool in ipairs(lp.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower() == lower then
			return tool
		end
	end
	return nil
end

local function waitForEquipped(char, tool, timeout)
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		if char:FindFirstChildOfClass("Tool") == tool then
			return true
		end
		task.wait(0.05)
	end
	return char:FindFirstChildOfClass("Tool") == tool
end

local function collectDropParts(container)
	for _, item in ipairs(container:GetDescendants()) do
		if item:IsA("BasePart") then
			pcall(function()
				hrp.CFrame = CFrame.new(item.Position)
			end)
		elseif item:IsA("ProximityPrompt") and fireproximityprompt then
			pcall(function()
				fireproximityprompt(item)
			end)
		end
	end
end

task.spawn(function()
	while task.wait(0.25) do
		if not autoBang or healingInProgress then
			continue
		end
		local char = lp.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health >= autoBangThreshold then
			continue
		end
		if os.clock() - lastHealAt < 0.5 then
			continue
		end

		local healTool = findHealTool()
		if not healTool then
			if buyBandagePack() then
				task.wait(0.4)
				healTool = findHealTool()
			end
			if not healTool then
				continue
			end
		end

		local current = char:FindFirstChildOfClass("Tool")
		if current and not isHealTool(current) and preferredWeaponName == "" then
			setPreferredWeapon(current)
		end

		healingInProgress = true
		humanoid:EquipTool(healTool)
		waitForEquipped(char, healTool, 1)

		local start = os.clock()
		while autoBang and humanoid.Health < humanoid.MaxHealth and (os.clock() - start) < 6 do
			pcall(function()
				healTool:Activate()
			end)
			task.wait(0.35)
		end

		lastHealAt = os.clock()
		healingInProgress = false

		local returnTool = findToolByName(preferredWeaponName) or current
		if returnTool then
			task.defer(function()
				humanoid:EquipTool(returnTool)
				waitForEquipped(char, returnTool, 1)
			end)
		end
	end
end)

-- Find nearest NPC2
local function getNearestNPC2()
	local nearest, dist, npcHRP = nil, 99999, nil
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name == "NPC2" then
			local h = m:FindFirstChildOfClass("Humanoid")
			local p = m:FindFirstChild("HumanoidRootPart")
			if h and p and h.Health > 0 then
				local d = (p.Position - hrp.Position).Magnitude
				if d < dist then
					nearest = m
					dist = d
					npcHRP = p
				end
			end
		end
	end
	return nearest, npcHRP
end

local function getCityNPC()
	local folder = workspace:FindFirstChild("CityNPCs")
	if not folder then
		return nil
	end
	local npcFolder = folder:FindFirstChild("NPCs")
	if not npcFolder then
		return nil
	end
	return npcFolder:GetChildren()[3]
end

-- Heartbeat loop
RunService.Heartbeat:Connect(function(dt)
	if hrp and hum and hum.Health > 0 then
		if farming then
			local npc, npcHRP = getNearestNPC2()
			if npcHRP then
				orbitAngle += dt * 15
				local offset = Vector3.new(math.cos(orbitAngle), 0, math.sin(orbitAngle)) * 10
				hrp.CFrame = CFrame.new(npcHRP.Position + offset, npcHRP.Position)

				local tool = lp.Character:FindFirstChildOfClass("Tool") or lp.Backpack:FindFirstChildOfClass("Tool")
				if tool then
					tool.Parent = lp.Character
					pcall(function()
						tool:Activate()
					end)
				end
			end
		end

		if autoPickup then
			for _, item in ipairs(workspace:GetDescendants()) do
				if item:IsA("BasePart") and (item.Position - hrp.Position).Magnitude <= 15 then
					pcall(function()
						hrp.CFrame = CFrame.new(item.Position)
					end)
				end
			end
		end

		if cityFarm then
			local cityNpc = getCityNPC()
			if cityNpc then
				local h = cityNpc:FindFirstChildOfClass("Humanoid")
				local p = cityNpc:FindFirstChild("HumanoidRootPart")
				if h and p and h.Health > 0 then
					orbitAngle += dt * 12
					local offset = Vector3.new(math.cos(orbitAngle), 0, math.sin(orbitAngle)) * 9
					hrp.CFrame = CFrame.new(p.Position + offset, p.Position)
					local tool = lp.Character:FindFirstChildOfClass("Tool") or lp.Backpack:FindFirstChildOfClass("Tool")
					if tool then
						tool.Parent = lp.Character
						pcall(function()
							tool:Activate()
						end)
					end
				end
			end
		end

		if cityPickup then
			local dropFolder = workspace:FindFirstChild("CityNPCs")
			dropFolder = dropFolder and dropFolder:FindFirstChild("Drop")
			if dropFolder then
				collectDropParts(dropFolder)
			end
		end

		-- Update HP
		local npc = getNearestNPC2()
		if npc and npc:FindFirstChildOfClass("Humanoid") then
			local h = npc:FindFirstChildOfClass("Humanoid")
			hpLabel.Text = "NPC2: " .. math.floor(h.Health) .. " / " .. math.floor(h.MaxHealth)
		else
			hpLabel.Text = "NPC2: Không thấy"
		end
	end
end)
