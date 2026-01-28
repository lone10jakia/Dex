--== MEMAYBEO HUB v3 (FULL + Auto Băng <50HP + Toggle Icon) ==--

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local SAVE_FILE = "memaybeo_hub_v3_settings.json"

local function loadSettings()
	if not (readfile and isfile) then
		return {}
	end

	if not isfile(SAVE_FILE) then
		return {}
	end

	local ok, data = pcall(readfile, SAVE_FILE)
	if not ok or not data then
		return {}
	end

	local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, data)
	if not okDecode or type(decoded) ~= "table" then
		return {}
	end

	return decoded
end

local function saveSettings(settings)
	if not writefile then
		return
	end

	pcall(function()
		writefile(SAVE_FILE, HttpService:JSONEncode(settings))
	end)
end

local persisted = loadSettings()

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.ResetOnSpawn = false

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 40, 0, 40)
ToggleButton.Position = UDim2.new(1, -50, 0, 10)
ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ToggleButton.Text = "😏"
ToggleButton.TextSize = 22
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextColor3 = Color3.fromRGB(0, 255, 127)
ToggleButton.BorderSizePixel = 0
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 130, 0, 385)
MainFrame.Position = UDim2.new(1, 150, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 20)
Title.BackgroundTransparency = 1
Title.Text = "MEMAYBEO HUB/cuonglonlonglon"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(0, 255, 127)

-- Button creator
local function makeButton(posY, text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 110, 0, 30)
	btn.Position = UDim2.new(0, 10, 0, posY)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.Text = text .. " OFF"
	btn.TextSize = 12
	btn.Font = Enum.Font.Gotham
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = MainFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
	return btn
end

local SpinButton = makeButton(25, "🔄 Xoay:")
local SpeedButton = makeButton(60, "👟 Tăng tốc:")
local HealthButton = makeButton(95, "❤️ Thanh máu:")
local StunButton = makeButton(130, "🥴 Choáng:")
local AutoAttackButton = makeButton(165, "⚔️ Auto Đánh:")
local FixLagButton = makeButton(200, "⚡ FixLag:")
local RespawnButton = makeButton(235, "♻️ Hồi sinh:")
local AutoBangButton = makeButton(270, "🤕 Auto Băng:")

local WeaponLabel = Instance.new("TextLabel")
WeaponLabel.Size = UDim2.new(0, 110, 0, 16)
WeaponLabel.Position = UDim2.new(0, 10, 0, 305)
WeaponLabel.BackgroundTransparency = 1
WeaponLabel.Text = "🎯 Vũ khí:"
WeaponLabel.TextSize = 12
WeaponLabel.Font = Enum.Font.Gotham
WeaponLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
WeaponLabel.TextXAlignment = Enum.TextXAlignment.Left
WeaponLabel.Parent = MainFrame

local WeaponInput = Instance.new("TextBox")
WeaponInput.Size = UDim2.new(0, 110, 0, 24)
WeaponInput.Position = UDim2.new(0, 10, 0, 323)
WeaponInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
WeaponInput.Text = ""
WeaponInput.PlaceholderText = "Tên vũ khí"
WeaponInput.TextSize = 12
WeaponInput.Font = Enum.Font.Gotham
WeaponInput.TextColor3 = Color3.fromRGB(255, 255, 255)
WeaponInput.ClearTextOnFocus = false
WeaponInput.Parent = MainFrame
Instance.new("UICorner", WeaponInput).CornerRadius = UDim.new(0, 5)

local WeaponSuggestion = Instance.new("TextLabel")
WeaponSuggestion.Size = UDim2.new(0, 110, 0, 14)
WeaponSuggestion.Position = UDim2.new(0, 10, 0, 350)
WeaponSuggestion.BackgroundTransparency = 1
WeaponSuggestion.Text = ""
WeaponSuggestion.TextSize = 10
WeaponSuggestion.Font = Enum.Font.Gotham
WeaponSuggestion.TextColor3 = Color3.fromRGB(120, 255, 180)
WeaponSuggestion.TextXAlignment = Enum.TextXAlignment.Left
WeaponSuggestion.Parent = MainFrame

-- Variables
local spinActive = persisted.spinActive or false
local speedBoost = persisted.speedBoost or false
local healthVisible = persisted.healthVisible or false
local stunActive = persisted.stunActive or false
local stunBusy = false
local fastRespawn = persisted.fastRespawn or false
local autoAttack = persisted.autoAttack or false
local fixLag = persisted.fixLag or false
local autoBang = persisted.autoBang or false
local preferredWeaponName = persisted.preferredWeaponName or ""
local suggestedWeaponName = ""
local autoWeaponCapture = persisted.autoWeaponCapture
if autoWeaponCapture == nil then
	autoWeaponCapture = true
end

local spinSpeed = 2500
local normalSpeed, boostedSpeed = 16, 32
local stunDuration = 0.6
local stunSpeed = 8

local function persistState()
	saveSettings({
		spinActive = spinActive,
		speedBoost = speedBoost,
		healthVisible = healthVisible,
		stunActive = stunActive,
		fastRespawn = fastRespawn,
		autoAttack = autoAttack,
		fixLag = fixLag,
		autoBang = autoBang,
		preferredWeaponName = preferredWeaponName,
		autoWeaponCapture = autoWeaponCapture,
	})
end

local function setToggleText(button, label, value)
	button.Text = label .. " " .. (value and "ON" or "OFF")
end

local function getAllToolNames()
	local names = {}
	local seen = {}
	local char = LocalPlayer.Character

	local function collect(container)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and not seen[child.Name] then
				seen[child.Name] = true
				table.insert(names, child.Name)
			end
		end
	end

	collect(char)
	collect(LocalPlayer.Backpack)
	return names
end

local function findWeaponSuggestion(inputText)
	if inputText == "" then
		return ""
	end

	local normalized = inputText:lower()
	for _, name in ipairs(getAllToolNames()) do
		if name:lower():sub(1, #normalized) == normalized then
			return name
		end
	end

	return ""
end

local function updateWeaponSuggestion()
	suggestedWeaponName = findWeaponSuggestion(WeaponInput.Text)
	if suggestedWeaponName ~= "" and WeaponInput.Text:lower() ~= suggestedWeaponName:lower() then
		WeaponSuggestion.Text = "Gợi ý: " .. suggestedWeaponName
	else
		WeaponSuggestion.Text = ""
	end
end

------------------------------------------------------------------------
-- SPIN
------------------------------------------------------------------------
SpinButton.MouseButton1Click:Connect(function()
	spinActive = not spinActive
	setToggleText(SpinButton, "🔄 Xoay:", spinActive)
	persistState()
end)

RunService.RenderStepped:Connect(function(dt)
	if spinActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		LocalPlayer.Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(spinSpeed * dt), 0)
	end
end)

------------------------------------------------------------------------
-- SPEED
------------------------------------------------------------------------
local function applySpeed()
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	if hum then
		if stunActive and stunBusy then
			return
		end
		hum.WalkSpeed = speedBoost and boostedSpeed or normalSpeed
	end
end

SpeedButton.MouseButton1Click:Connect(function()
	speedBoost = not speedBoost
	setToggleText(SpeedButton, "👟 Tăng tốc:", speedBoost)
	applySpeed()
	persistState()
end)

task.spawn(function()
	while task.wait(0.75) do
		if speedBoost then
			applySpeed()
		end
	end
end)

------------------------------------------------------------------------
-- HEALTH BAR
------------------------------------------------------------------------
local healthConnections = {}

local function removeHealthBar(char)
	local head = char:FindFirstChild("Head")
	if head then
		local existing = head:FindFirstChild("HealthDisplay")
		if existing then
			existing:Destroy()
		end
	end
end

local function addHealthBar(char)
	if not healthVisible then
		return
	end

	local head, hum = char:FindFirstChild("Head"), char:FindFirstChild("Humanoid")
	if not (head and hum) or head:FindFirstChild("HealthDisplay") then
		return
	end

	local Billboard = Instance.new("BillboardGui")
	Billboard.Name, Billboard.Size, Billboard.StudsOffset, Billboard.AlwaysOnTop =
		"HealthDisplay", UDim2.new(4, 0, 1, 0), Vector3.new(0, 3, 0), true
	Billboard.Adornee, Billboard.Parent = head, head

	local barBack = Instance.new("Frame")
	barBack.Size = UDim2.new(1, 0, 0.4, 0)
	barBack.Position = UDim2.new(0, 0, 0.3, 0)
	barBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	barBack.BorderSizePixel = 0
	barBack.Parent = Billboard

	local bar = Instance.new("Frame")
	bar.Name, bar.Size, bar.BackgroundColor3, bar.BorderSizePixel =
		"Bar", UDim2.new(1, 0, 1, 0), Color3.fromRGB(0, 255, 0), 0
	bar.Parent = barBack

	local hpText = Instance.new("TextLabel")
	hpText.Size, hpText.BackgroundTransparency, hpText.Font, hpText.TextScaled, hpText.TextColor3 =
		UDim2.new(1, 0, 1, 0), 1, Enum.Font.GothamBold, true, Color3.fromRGB(255, 255, 255)
	hpText.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
	hpText.Parent = barBack

	hum.HealthChanged:Connect(function(h)
		local ratio = math.max(h / hum.MaxHealth, 0)
		bar.Size = UDim2.new(ratio, 0, 1, 0)
		bar.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
		hpText.Text = math.floor(h) .. " / " .. math.floor(hum.MaxHealth)
	end)
end

local function connectHealthForPlayer(plr)
	if healthConnections[plr] then
		return
	end

	local connection = plr.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		addHealthBar(char)
	end)
	healthConnections[plr] = connection
	if plr.Character then
		addHealthBar(plr.Character)
	end
end

local function disconnectHealthConnections()
	for plr, conn in pairs(healthConnections) do
		conn:Disconnect()
		healthConnections[plr] = nil
		if plr.Character then
			removeHealthBar(plr.Character)
		end
	end
end

HealthButton.MouseButton1Click:Connect(function()
	healthVisible = not healthVisible
	setToggleText(HealthButton, "❤️ Thanh máu:", healthVisible)
	if healthVisible then
		for _, plr in ipairs(Players:GetPlayers()) do
			connectHealthForPlayer(plr)
		end
	else
		disconnectHealthConnections()
	end
	persistState()
end)

Players.PlayerAdded:Connect(function(plr)
	if healthVisible then
		connectHealthForPlayer(plr)
	end
end)

------------------------------------------------------------------------
-- STUN
------------------------------------------------------------------------
local stunConnection = nil

local function desiredSpeed()
	return speedBoost and boostedSpeed or normalSpeed
end

local function showStunEffect(char)
	if not char then
		return
	end

	local existing = char:FindFirstChild("StunEffect")
	if existing then
		existing:Destroy()
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "StunEffect"
	highlight.FillColor = Color3.fromRGB(255, 220, 90)
	highlight.OutlineColor = Color3.fromRGB(255, 120, 60)
	highlight.FillTransparency = 0.4
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char

	task.delay(stunDuration, function()
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
	end)
end

local function applyStun(hum)
	if stunBusy then
		return
	end
	stunBusy = true
	local original = desiredSpeed()
	local originalJump = hum.JumpPower
	hum.WalkSpeed = math.max(stunSpeed, original * 0.5)
	hum.JumpPower = math.max(25, originalJump * 0.6)
	showStunEffect(hum.Parent)
	task.delay(stunDuration, function()
		if hum and hum.Parent then
			hum.WalkSpeed = desiredSpeed()
			hum.JumpPower = originalJump
		end
		stunBusy = false
	end)
end

local function setupStun(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	local lastHealth = hum.Health
	if stunConnection then
		stunConnection:Disconnect()
	end

	stunConnection = hum.HealthChanged:Connect(function(current)
		if not stunActive then
			lastHealth = current
			return
		end

		if current < lastHealth then
			applyStun(hum)
		end
		lastHealth = current
	end)
end

StunButton.MouseButton1Click:Connect(function()
	stunActive = not stunActive
	setToggleText(StunButton, "🥴 Choáng:", stunActive)
	if stunActive and LocalPlayer.Character then
		setupStun(LocalPlayer.Character)
	else
		if stunConnection then
			stunConnection:Disconnect()
			stunConnection = nil
		end
		stunBusy = false
		applySpeed()
	end
	persistState()
end)

------------------------------------------------------------------------
-- FAST RESPAWN
------------------------------------------------------------------------
local respawnConnection = nil

local function setupFastRespawn(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	if respawnConnection then
		respawnConnection:Disconnect()
	end

	respawnConnection = hum.Died:Connect(function()
		if fastRespawn then
			task.wait(0.1)
			LocalPlayer:LoadCharacter()
		end
	end)
end

RespawnButton.MouseButton1Click:Connect(function()
	fastRespawn = not fastRespawn
	setToggleText(RespawnButton, "♻️ Hồi sinh:", fastRespawn)
	if fastRespawn and LocalPlayer.Character then
		setupFastRespawn(LocalPlayer.Character)
	else
		if respawnConnection then
			respawnConnection:Disconnect()
			respawnConnection = nil
		end
	end
	persistState()
end)

------------------------------------------------------------------------
-- AUTO ATTACK
------------------------------------------------------------------------
AutoAttackButton.MouseButton1Click:Connect(function()
	autoAttack = not autoAttack
	setToggleText(AutoAttackButton, "⚔️ Auto Đánh:", autoAttack)
	persistState()
end)

task.spawn(function()
	while task.wait(0.1) do
		if autoAttack and LocalPlayer.Character then
			local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
			if tool then
				pcall(function()
					tool:Activate()
				end)
			end
		end
	end
end)

------------------------------------------------------------------------
-- AUTO BĂNG CHUẨN <50 HP
------------------------------------------------------------------------

AutoBangButton.MouseButton1Click:Connect(function()
	autoBang = not autoBang
	setToggleText(AutoBangButton, "🤕 Auto Băng:", autoBang)
	persistState()
end)

local function isHealTool(tool)
	local n = tool.Name:lower()
	return n:find("bang") or n:find("băng") or n:find("med") or n:find("heal") or n:find("kit") or n:find("band")
end

local function findToolByName(targetName)
	if targetName == "" then
		return nil
	end

	local normalized = targetName:lower()
	local char = LocalPlayer.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and tool.Name:lower() == normalized then
				return tool
			end
		end
	end

	for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower() == normalized then
			return tool
		end
	end

	return nil
end

local function syncPreferredWeaponFromTool(tool)
	if not autoWeaponCapture or not tool or not tool:IsA("Tool") then
		return
	end

	if isHealTool(tool) then
		return
	end

	preferredWeaponName = tool.Name
	WeaponInput.Text = preferredWeaponName
	updateWeaponSuggestion()
	persistState()
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

task.spawn(function()
	while task.wait(0.3) do
		if autoBang and LocalPlayer.Character then
			local char = LocalPlayer.Character
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health >= 50 then
				continue
			end

			local current = char:FindFirstChildOfClass("Tool")
			syncPreferredWeaponFromTool(current)
			local heal = nil

			if current and isHealTool(current) then
				heal = current
			else
				for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
					if v:IsA("Tool") and isHealTool(v) then
						heal = v
						break
					end
				end
			end
			if not heal then
				continue
			end

			local old = nil
			if current and not isHealTool(current) then
				old = current
			end

			hum:EquipTool(heal)
			task.wait(0.2)
			pcall(function()
				heal:Activate()
			end)

			local preferred = findToolByName(preferredWeaponName)
			local returnTool = preferred or old
			if returnTool then
				task.defer(function()
					hum:EquipTool(returnTool)
					waitForEquipped(char, returnTool, 1.2)
				end)
			end
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function(child)
		syncPreferredWeaponFromTool(child)
	end)

	if stunActive then
		setupStun(char)
	end

	if fastRespawn then
		setupFastRespawn(char)
	end
end)

------------------------------------------------------------------------
-- FIXLAG
------------------------------------------------------------------------
FixLagButton.MouseButton1Click:Connect(function()
	fixLag = not fixLag
	setToggleText(FixLagButton, "⚡ FixLag:", fixLag)
	persistState()
end)

------------------------------------------------------------------------
-- UI Toggle
------------------------------------------------------------------------
local menuVisible = false
ToggleButton.MouseButton1Click:Connect(function()
	menuVisible = not menuVisible
	if menuVisible then
		MainFrame.Visible = true
		TweenService:Create(MainFrame, TweenInfo.new(0.3), { Position = UDim2.new(1, -150, 0.3, 0) }):Play()
	else
		local t = TweenService:Create(MainFrame, TweenInfo.new(0.3), { Position = UDim2.new(1, 150, 0.3, 0) })
		t:Play()
		t.Completed:Connect(function()
			MainFrame.Visible = false
		end)
	end
end)

local function applyInitialState()
	setToggleText(SpinButton, "🔄 Xoay:", spinActive)
	setToggleText(SpeedButton, "👟 Tăng tốc:", speedBoost)
	setToggleText(HealthButton, "❤️ Thanh máu:", healthVisible)
	setToggleText(StunButton, "🥴 Choáng:", stunActive)
	setToggleText(RespawnButton, "♻️ Hồi sinh:", fastRespawn)
	setToggleText(AutoAttackButton, "⚔️ Auto Đánh:", autoAttack)
	setToggleText(FixLagButton, "⚡ FixLag:", fixLag)
	setToggleText(AutoBangButton, "🤕 Auto Băng:", autoBang)
	WeaponInput.Text = preferredWeaponName
	updateWeaponSuggestion()

	if speedBoost then
		applySpeed()
	end

	if healthVisible then
		for _, plr in ipairs(Players:GetPlayers()) do
			connectHealthForPlayer(plr)
		end
	end

	if stunActive and LocalPlayer.Character then
		setupStun(LocalPlayer.Character)
	end

	if fastRespawn and LocalPlayer.Character then
		setupFastRespawn(LocalPlayer.Character)
	end
end

applyInitialState()

WeaponInput:GetPropertyChangedSignal("Text"):Connect(function()
	updateWeaponSuggestion()
end)

WeaponInput.FocusLost:Connect(function()
	if suggestedWeaponName ~= "" and WeaponInput.Text ~= "" then
		if suggestedWeaponName:lower():sub(1, #WeaponInput.Text:lower()) == WeaponInput.Text:lower() then
			WeaponInput.Text = suggestedWeaponName
		end
	end
	preferredWeaponName = WeaponInput.Text
	updateWeaponSuggestion()
	persistState()
end)

game:BindToClose(function()
	persistState()
end)
