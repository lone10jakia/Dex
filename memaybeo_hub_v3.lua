--== MEMAYBEO HUB v3 (FULL + Auto Băng <50HP + Toggle Icon) ==--

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
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
MainFrame.Size = UDim2.new(0, 130, 0, 270)
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
local HitBoxButton = makeButton(130, "📦 HitBox:")
local AutoAttackButton = makeButton(165, "⚔️ Auto Đánh:")
local FixLagButton = makeButton(200, "⚡ FixLag:")
local AutoBangButton = makeButton(235, "🤕 Auto Băng:")

-- Variables
local spinActive = persisted.spinActive or false
local speedBoost = persisted.speedBoost or false
local healthVisible = persisted.healthVisible or false
local hitBoxActive = persisted.hitBoxActive or false
local autoAttack = persisted.autoAttack or false
local fixLag = persisted.fixLag or false
local autoBang = persisted.autoBang or false
local preferredWeaponName = persisted.preferredWeaponName or ""
local autoBangBusy = false

local spinSpeed = 2500
local normalSpeed, boostedSpeed = 16, 32
local hitBoxSize = Vector3.new(7, 7, 7)

local function persistState()
	saveSettings({
		spinActive = spinActive,
		speedBoost = speedBoost,
		healthVisible = healthVisible,
		hitBoxActive = hitBoxActive,
		autoAttack = autoAttack,
		fixLag = fixLag,
		autoBang = autoBang,
		preferredWeaponName = preferredWeaponName,
	})
end

local function setToggleText(button, label, value)
	button.Text = label .. " " .. (value and "ON" or "OFF")
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
	while task.wait(0.5) do
		if speedBoost then
			applySpeed()
		end
	end
end)

------------------------------------------------------------------------
-- HEALTH BAR
------------------------------------------------------------------------
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
HealthButton.MouseButton1Click:Connect(function()
	healthVisible = not healthVisible
	setToggleText(HealthButton, "❤️ Thanh máu:", healthVisible)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			addHealthBar(plr.Character)
		end
	end
	persistState()
end)
------------------------------------------------------------------------
-- HITBOX
------------------------------------------------------------------------
local function setHitBox(char, size)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Size = size
		hrp.Transparency = 0.7
		hrp.Color = Color3.fromRGB(255, 0, 0)
		hrp.Material = Enum.Material.Neon
		hrp.CanCollide = false
	end
end

HitBoxButton.MouseButton1Click:Connect(function()
	hitBoxActive = not hitBoxActive
	setToggleText(HitBoxButton, "📦 HitBox:", hitBoxActive)
	persistState()
end)

task.spawn(function()
	while task.wait(0.3) do
		if hitBoxActive then
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= LocalPlayer and pl.Character then
					setHitBox(pl.Character, hitBoxSize)
				end
			end
		end
	end
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
	while task.wait(0.05) do
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
	if not tool or not tool:IsA("Tool") then
		return
	end

	if isHealTool(tool) then
		return
	end

	preferredWeaponName = tool.Name
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

local function waitForFullHealth(hum, timeout)
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		if not hum.Parent or hum.Health <= 0 then
			return false
		end
		if hum.Health >= hum.MaxHealth then
			return true
		end
		task.wait(0.1)
	end
	return hum.Health >= hum.MaxHealth
end

local function bindCharacter(char)
	char.ChildAdded:Connect(function(child)
		syncPreferredWeaponFromTool(child)
	end)
	local currentTool = char:FindFirstChildOfClass("Tool")
	if currentTool then
		syncPreferredWeaponFromTool(currentTool)
	end
end

task.spawn(function()
	while task.wait(0.2) do
		if autoBang and LocalPlayer.Character and not autoBangBusy then
			local char = LocalPlayer.Character
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health >= 50 then
				continue
			end
			autoBangBusy = true

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
				autoBangBusy = false
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
			waitForFullHealth(hum, 6)
			if returnTool then
				hum:EquipTool(returnTool)
				waitForEquipped(char, returnTool, 1.2)
			end
			autoBangBusy = false
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(bindCharacter)

if LocalPlayer.Character then
	bindCharacter(LocalPlayer.Character)
end

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
	setToggleText(HitBoxButton, "📦 HitBox:", hitBoxActive)
	setToggleText(AutoAttackButton, "⚔️ Auto Đánh:", autoAttack)
	setToggleText(FixLagButton, "⚡ FixLag:", fixLag)
	setToggleText(AutoBangButton, "🤕 Auto Băng:", autoBang)

	if speedBoost then
		applySpeed()
	end

	if healthVisible then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				addHealthBar(plr.Character)
			end
		end
	end
end

applyInitialState()

game:BindToClose(function()
	persistState()
end)
