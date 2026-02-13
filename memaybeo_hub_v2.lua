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
MainFrame.Size = UDim2.new(0, 130, 0, 380)
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
local AutoBangButton = makeButton(235, "🤕 Auto Băng:")
local AutoBuyBandageButton = makeButton(270, "🛒 Mua Băng:")

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

local WeaponSelectButton = Instance.new("TextButton")
WeaponSelectButton.Size = UDim2.new(0, 110, 0, 26)
WeaponSelectButton.Position = UDim2.new(0, 10, 0, 351)
WeaponSelectButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
WeaponSelectButton.Text = "🎯 Chọn vũ khí"
WeaponSelectButton.TextSize = 11
WeaponSelectButton.Font = Enum.Font.Gotham
WeaponSelectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
WeaponSelectButton.Parent = MainFrame
Instance.new("UICorner", WeaponSelectButton).CornerRadius = UDim.new(0, 5)

-- Variables
local spinActive = persisted.spinActive or false
local speedBoost = persisted.speedBoost or false
local healthVisible = persisted.healthVisible or false
local stunActive = persisted.stunActive or false
local stunBusy = false
local autoAttack = persisted.autoAttack or false
local fixLag = persisted.fixLag or false
local autoBang = persisted.autoBang or false
local autoBandageBuy = persisted.autoBandageBuy
if autoBandageBuy == nil then
	autoBandageBuy = true
end
local preferredWeaponName = persisted.preferredWeaponName or ""
local autoWeaponCapture = persisted.autoWeaponCapture
if autoWeaponCapture == nil then
	autoWeaponCapture = true
end

local spinSpeed = 2500
local normalSpeed, boostedSpeed = 16, 32
local stunDuration = 0.6
local stunSpeed = 8
local autoBangThreshold = 75
local autoBangCooldown = 0.4
local autoBandageMinCount = 99
local bandageBuyCooldown = 1.5

local function persistState()
	saveSettings({
		spinActive = spinActive,
		speedBoost = speedBoost,
		healthVisible = healthVisible,
		stunActive = stunActive,
		autoAttack = autoAttack,
		fixLag = fixLag,
		autoBang = autoBang,
		autoBandageBuy = autoBandageBuy,
		preferredWeaponName = preferredWeaponName,
		autoWeaponCapture = autoWeaponCapture,
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
	while task.wait(0.5) do
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

local function applyStun(hum)
	if stunBusy then
		return
	end
	stunBusy = true
	local original = desiredSpeed()
	hum.WalkSpeed = math.max(stunSpeed, original * 0.5)
	task.delay(stunDuration, function()
		if hum and hum.Parent then
			hum.WalkSpeed = desiredSpeed()
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
-- AUTO BĂNG CHUẨN <75 HP
------------------------------------------------------------------------

AutoBangButton.MouseButton1Click:Connect(function()
	autoBang = not autoBang
	setToggleText(AutoBangButton, "🤕 Auto Băng:", autoBang)
	persistState()
end)

AutoBuyBandageButton.MouseButton1Click:Connect(function()
	autoBandageBuy = not autoBandageBuy
	setToggleText(AutoBuyBandageButton, "🛒 Mua Băng:", autoBandageBuy)
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
	WeaponLabel.Text = "🎯 Vũ khí: " .. preferredWeaponName
	persistState()
end

local function setPreferredWeapon(tool)
	if not tool or not tool:IsA("Tool") or isHealTool(tool) then
		return false
	end

	preferredWeaponName = tool.Name
	WeaponInput.Text = preferredWeaponName
	WeaponLabel.Text = "🎯 Vũ khí: " .. preferredWeaponName
	persistState()
	return true
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

local function isBandageNodeName(name)
	local n = string.lower(name or "")
	return (n:find("băng") and n:find("gạc")) or (n:find("bang") and n:find("gac")) or n:find("bandage")
end

local function getBandageShopRoot()
	return Workspace:FindFirstChild("NPCs")
		and Workspace.NPCs:FindFirstChild("Shop")
		and Workspace.NPCs.Shop:FindFirstChild("Bán băng gạc")
end

local function findShopEntryPrompt(shopRoot)
	for _, node in ipairs(shopRoot:GetDescendants()) do
		if node:IsA("ProximityPrompt") then
			local owner = node.Parent
			local ownerName = owner and string.lower(owner.Name) or ""
			if ownerName:find("shop") or ownerName:find("cửa") or ownerName:find("hang") or ownerName:find("mở") or ownerName:find("open") then
				return node
			end
		end
	end
	return nil
end

local function findBandageItemPrompt(shopRoot)
	local itemsFolder = shopRoot:FindFirstChild("Items")
	if not itemsFolder then
		return nil
	end

	local exactItem = itemsFolder:FindFirstChild("băng gạc") or itemsFolder:FindFirstChild("Băng gạc") or itemsFolder:FindFirstChild("bang gac")
	if exactItem then
		local exactPrompt = exactItem:FindFirstChildWhichIsA("ProximityPrompt", true)
		if exactPrompt then
			return exactPrompt
		end
	end

	local firstItemPrompt = nil
	for _, node in ipairs(itemsFolder:GetDescendants()) do
		if node:IsA("ProximityPrompt") then
			if not firstItemPrompt then
				firstItemPrompt = node
			end
			local owner = node.Parent
			if owner and isBandageNodeName(owner.Name) then
				return node
			end
			if owner and owner.Parent and isBandageNodeName(owner.Parent.Name) then
				return node
			end
		end
	end
	return firstItemPrompt
end

local function getPromptWorldPosition(prompt)
	local parent = prompt.Parent
	if parent and parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then
		return parent.Parent.Position
	end
	if parent and parent:IsA("BasePart") then
		return parent.Position
	end
	if parent and parent:IsA("Model") then
		return parent:GetPivot().Position
	end
	return nil
end

local function moveNearPrompt(prompt)
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local promptPosition = getPromptWorldPosition(prompt)
	if hrp and promptPosition and (hrp.Position - promptPosition).Magnitude > 14 then
		pcall(function()
			hrp.CFrame = CFrame.new(promptPosition + Vector3.new(0, 2, 0))
		end)
		task.wait(0.1)
	end
end

local function triggerPrompt(prompt)
	local fired = false
	pcall(function()
		fireproximityprompt(prompt, 1, true)
		fired = true
	end)
	if not fired then
		pcall(function()
			fireproximityprompt(prompt)
			fired = true
		end)
	end
	return fired
end

local function buyBandagePack(times)
	if not fireproximityprompt then
		return false
	end

	local shopRoot = getBandageShopRoot()
	if not shopRoot then
		return false
	end

	local shopPrompt = findShopEntryPrompt(shopRoot)
	local itemPrompt = findBandageItemPrompt(shopRoot)
	if not itemPrompt then
		return false
	end

	if shopPrompt then
		moveNearPrompt(shopPrompt)
		triggerPrompt(shopPrompt)
		task.wait(0.1)
	end

	moveNearPrompt(itemPrompt)
	times = math.max(1, times or 5)
	local success = false
	for _ = 1, times do
		if shopPrompt then
			triggerPrompt(shopPrompt)
			task.wait(0.05)
		end
		if triggerPrompt(itemPrompt) then
			success = true
		end
		task.wait(0.2)
	end

	return success
end

local function isBandageTool(tool)
	if not (tool and tool:IsA("Tool")) then
		return false
	end

	local n = tool.Name:lower()
	return n:find("băng gạc") or n:find("bang gac") or n:find("bandage")
end

local function readBandageAmountFromTool(tool)
	local valueNames = { "Amount", "Count", "Stack", "Uses", "Value" }
	for _, key in ipairs(valueNames) do
		local child = tool:FindFirstChild(key)
		if child and (child:IsA("IntValue") or child:IsA("NumberValue")) then
			return child.Value
		end
	end

	for _, key in ipairs(valueNames) do
		local attr = tool:GetAttribute(key)
		if type(attr) == "number" then
			return attr
		end
	end

	local digits = tool.Name:match("(%d+)")
	if digits then
		return tonumber(digits) or 1
	end

	return 1
end

local function countBandages()
	local total = 0
	local function collect(container)
		for _, tool in ipairs(container:GetChildren()) do
			if isBandageTool(tool) then
				total += readBandageAmountFromTool(tool)
			end
		end
	end

	if LocalPlayer.Character then
		collect(LocalPlayer.Character)
	end
	collect(LocalPlayer.Backpack)
	return total
end

local lastHealAt = 0
local healingInProgress = false
local lastForceEquipAt = 0
local postHealForceUntil = 0
local lastBandageBuyAt = 0

local function forcePreferredWeapon(char, hum)
	if not char or not hum then
		return
	end
	local preferred = findToolByName(preferredWeaponName)
	if preferred then
		hum:EquipTool(preferred)
		waitForEquipped(char, preferred, 1.2)
	end
end

task.spawn(function()
	while task.wait(0.2) do
		if (autoBang or autoBandageBuy) and LocalPlayer.Character and not healingInProgress then
			local char = LocalPlayer.Character
			local hum = char:FindFirstChildOfClass("Humanoid")

			local currentBandages = countBandages()
			if autoBandageBuy and currentBandages < autoBandageMinCount and (os.clock() - lastBandageBuyAt) > bandageBuyCooldown then
				local needed = autoBandageMinCount - currentBandages
				local buyTimes = math.clamp(math.ceil(needed / 5), 1, 20)
				if buyBandagePack(buyTimes) then
					lastBandageBuyAt = os.clock()
					task.wait(0.3)
				end
			end

			if hum and hum.Health >= hum.MaxHealth and os.clock() < postHealForceUntil then
				local equipped = char:FindFirstChildOfClass("Tool")
				if equipped and isHealTool(equipped) then
					if os.clock() - lastForceEquipAt > 0.2 then
						lastForceEquipAt = os.clock()
						equipped.Parent = LocalPlayer.Backpack
						forcePreferredWeapon(char, hum)
					end
				end
			end
			if not hum or hum.Health >= autoBangThreshold then
				local currentTool = char:FindFirstChildOfClass("Tool")
				if currentTool and isHealTool(currentTool) and hum and hum.Health >= hum.MaxHealth then
					if os.clock() - lastForceEquipAt > 0.5 then
						lastForceEquipAt = os.clock()
						currentTool.Parent = LocalPlayer.Backpack
						forcePreferredWeapon(char, hum)
					end
				end
				continue
			end

			if os.clock() - lastHealAt < autoBangCooldown then
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

			healingInProgress = true
			hum:EquipTool(heal)
			waitForEquipped(char, heal, 1)

			local start = os.clock()
			while autoBang and hum.Health < hum.MaxHealth and (os.clock() - start) < 6 do
				pcall(function()
					heal:Activate()
				end)
				task.wait(0.35)
			end
			lastHealAt = os.clock()
			healingInProgress = false
			postHealForceUntil = os.clock() + 3

			local preferred = findToolByName(preferredWeaponName)
			local returnTool = preferred or old
			if returnTool then
				hum:EquipTool(returnTool)
				waitForEquipped(char, returnTool, 1.2)
			end
			local equipped = char:FindFirstChildOfClass("Tool")
			if equipped and isHealTool(equipped) then
				equipped.Parent = LocalPlayer.Backpack
				forcePreferredWeapon(char, hum)
			end
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function(child)
		syncPreferredWeaponFromTool(child)
		if autoBang and child:IsA("Tool") and isHealTool(child) then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health >= hum.MaxHealth then
				child.Parent = LocalPlayer.Backpack
				forcePreferredWeapon(char, hum)
			end
		end
	end)

	if stunActive then
		setupStun(char)
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
	setToggleText(AutoAttackButton, "⚔️ Auto Đánh:", autoAttack)
	setToggleText(FixLagButton, "⚡ FixLag:", fixLag)
	setToggleText(AutoBangButton, "🤕 Auto Băng:", autoBang)
	setToggleText(AutoBuyBandageButton, "🛒 Mua Băng:", autoBandageBuy)
	WeaponInput.Text = preferredWeaponName
	if preferredWeaponName ~= "" then
		WeaponLabel.Text = "🎯 Vũ khí: " .. preferredWeaponName
	end

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
end

applyInitialState()

WeaponInput.FocusLost:Connect(function()
	preferredWeaponName = WeaponInput.Text
	if preferredWeaponName ~= "" then
		WeaponLabel.Text = "🎯 Vũ khí: " .. preferredWeaponName
	else
		WeaponLabel.Text = "🎯 Vũ khí:"
	end
	persistState()
end)

WeaponSelectButton.MouseButton1Click:Connect(function()
	local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
	if not tool then
		for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if v:IsA("Tool") and not isHealTool(v) then
				tool = v
				break
			end
		end
	end

	if setPreferredWeapon(tool) then
		WeaponSelectButton.Text = "🎯 Đã lưu"
		task.delay(0.8, function()
			if WeaponSelectButton then
				WeaponSelectButton.Text = "🎯 Chọn vũ khí"
			end
		end)
	else
		WeaponSelectButton.Text = "❌ Không thấy"
		task.delay(0.8, function()
			if WeaponSelectButton then
				WeaponSelectButton.Text = "🎯 Chọn vũ khí"
			end
		end)
	end
end)

game:BindToClose(function()
	persistState()
end)
