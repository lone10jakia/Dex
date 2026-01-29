-- Fancy Multi-Function Menu
-- Standalone Roblox LocalScript-style UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("FancyMenu") then
	playerGui.FancyMenu:Destroy()
end

local theme = {
	background = Color3.fromRGB(22, 24, 30),
	panel = Color3.fromRGB(30, 33, 41),
	panelDark = Color3.fromRGB(25, 27, 34),
	accent = Color3.fromRGB(96, 165, 250),
	text = Color3.fromRGB(235, 238, 245),
	muted = Color3.fromRGB(155, 160, 175),
	stroke = Color3.fromRGB(55, 60, 75),
}

local autoAimEnabled = false
local autoAimConnection
local locatorEnabled = false
local locatorConnection
local locatorBillboards = {}
local ignoreTeamEnabled = true
 codex/add-aim-head-menu-and-localization-g6nxpx
local wallbangEnabled = true

local function create(className, props)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		inst[key] = value
	end
	return inst
end

local function tween(obj, props, time)
	TweenService:Create(obj, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function getCharacter()
	return player.Character
end

local function getRoot()
	local character = getCharacter()
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function isCharacterAlive()
	local character = getCharacter()
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0
end

local function getHeadPart(targetPlayer)
	if not targetPlayer then
		return nil
	end

	local character = targetPlayer.Character
	if not character then
		return nil
	end

	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end

	local primary = character.PrimaryPart
	if primary and primary:IsA("BasePart") then
		return primary
	end

	return nil
end

local function getCandidatePlayers()
	local candidates = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and (not ignoreTeamEnabled or other.Team ~= player.Team) then
			table.insert(candidates, other)
		end
	end
	return candidates
end

local function getNearestPlayer()
	local root = getRoot()
	if not root then
		return nil, "Không tìm thấy HumanoidRootPart."
	end

	local nearest
	local nearestDistance
	for _, other in ipairs(getCandidatePlayers()) do
		local head = getHeadPart(other)
		if head then
			local distance = (head.Position - root.Position).Magnitude
			if not nearestDistance or distance < nearestDistance then
				nearest = other
				nearestDistance = distance
			end
		end
	end

	if not nearest then
		return nil, "Không tìm thấy người chơi phù hợp."
	end

	return nearest, nearestDistance
end

local function createLocatorBillboard(targetPlayer, head)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FancyLocator"
	billboard.Size = UDim2.new(0, 160, 0, 34)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = theme.panel
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Parent = billboard

	create("UICorner", {
		CornerRadius = UDim.new(0, 6),
		Parent = frame,
	})

	create("UIStroke", {
		Color = theme.stroke,
		Thickness = 1,
		Parent = frame,
	})

	local label = create("TextLabel", {
		Name = "NameLabel",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.new(0, 4, 0, 0),
		Font = Enum.Font.GothamBold,
		Text = targetPlayer.Name,
		TextSize = 12,
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})

	locatorBillboards[targetPlayer] = billboard
	return label
end

local function clearLocatorBillboards()
	for target, billboard in pairs(locatorBillboards) do
		if billboard then
			billboard:Destroy()
		end
		locatorBillboards[target] = nil
	end
end

local function setLocatorEnabled(enabled, statusLabel)
	locatorEnabled = enabled
	if locatorConnection then
		locatorConnection:Disconnect()
		locatorConnection = nil
	end
	clearLocatorBillboards()

	if not enabled then
		if statusLabel then
			statusLabel.Text = "Status: Locator Off"
		end
		return
	end

	if statusLabel then
		statusLabel.Text = "Status: Locating players..."
	end
	locatorConnection = RunService.RenderStepped:Connect(function()
		local root = getRoot()
		if not root then
			return
		end

		local candidates = getCandidatePlayers()
		for _, other in ipairs(candidates) do
			local head = getHeadPart(other)
			if head then
				if not locatorBillboards[other] or not locatorBillboards[other].Parent then
					createLocatorBillboard(other, head)
				end
				local billboard = locatorBillboards[other]
				local label = billboard and billboard:FindFirstChild("Frame") and billboard.Frame:FindFirstChild("NameLabel")
				if label then
					local distance = (head.Position - root.Position).Magnitude
					label.Text = string.format("%s • %.0fm", other.Name, distance)
				end
			end
		end

		for target, billboard in pairs(locatorBillboards) do
			if not table.find(candidates, target) then
				if billboard then
					billboard:Destroy()
				end
				locatorBillboards[target] = nil
			end
		end
	end)
end

local function setAutoAim(enabled, statusLabel)
	autoAimEnabled = enabled
	if autoAimConnection then
		autoAimConnection:Disconnect()
		autoAimConnection = nil
	end

	if not enabled then
		if statusLabel then
			statusLabel.Text = "Status: Auto Aim Off"
		end
		return
	end

	if statusLabel then
		statusLabel.Text = "Status: Auto Aim Active"
	end

	autoAimConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		if not isCharacterAlive() then
			if statusLabel then
				statusLabel.Text = "Status: Waiting for respawn"
			end
			return
		end

		local root = getRoot()
		if not root then
			return
		end

		local target, distanceOrError = getNearestPlayer()
		if not target then
			if statusLabel then
				statusLabel.Text = distanceOrError or "Status: No target"
			end
			return
		end

		local head = getHeadPart(target)
		if not head then
			return
		end

		if not wallbangEnabled and workspace and workspace.Raycast then
			local origin = camera.CFrame.Position
			local direction = head.Position - origin
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			local character = getCharacter()
			if character then
				rayParams.FilterDescendantsInstances = {character}
			else
				rayParams.FilterDescendantsInstances = {}
			end
			local result = workspace:Raycast(origin, direction, rayParams)
			if result and result.Instance and not result.Instance:IsDescendantOf(head.Parent) then
				if statusLabel then
					statusLabel.Text = "Status: Target blocked"
				end
				return
			end
		end

		camera.CFrame = CFrame.lookAt(camera.CFrame.Position, head.Position)
		if statusLabel then
			statusLabel.Text = string.format("Status: Locked %s (%.0fm)", target.Name, distanceOrError)
		end
	end)
end

local screenGui = create("ScreenGui", {
	Name = "FancyMenu",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local accessKey = "MEMAYBEO-HUB-2024"
local requireKey = false
local animeImageId = "rbxassetid://11924456731"

local keyGate = create("Frame", {
	Name = "KeyGate",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(12, 14, 20),
	BackgroundTransparency = 0.05,
	Parent = screenGui,
})

local keyPanel = create("Frame", {
	Size = UDim2.new(0, 420, 0, 260),
	Position = UDim2.new(0.5, -210, 0.5, -130),
	BackgroundColor3 = theme.panel,
	BorderSizePixel = 0,
	Parent = keyGate,
})

create("UICorner", {
	CornerRadius = UDim.new(0, 14),
	Parent = keyPanel,
})

create("UIStroke", {
	Color = theme.stroke,
	Thickness = 1,
	Parent = keyPanel,
})

local keyTitle = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 28),
	Position = UDim2.new(0, 12, 0, 12),
	Font = Enum.Font.GothamBold,
	Text = "MEMAYBEO HUB Access Key",
	TextSize = 20,
	TextColor3 = theme.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = keyPanel,
})

local keySubtitle = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 18),
	Position = UDim2.new(0, 12, 0, 44),
	Font = Enum.Font.Gotham,
	Text = "Enter the key to unlock the menu",
	TextSize = 12,
	TextColor3 = theme.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = keyPanel,
})

local keyArt = create("ImageLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 140, 0, 140),
	Position = UDim2.new(1, -160, 0, 70),
	Image = animeImageId,
	ScaleType = Enum.ScaleType.Crop,
	Parent = keyPanel,
})

create("UICorner", {
	CornerRadius = UDim.new(0, 10),
	Parent = keyArt,
})

local keyInput = create("TextBox", {
	BackgroundColor3 = theme.panelDark,
	Size = UDim2.new(1, -24, 0, 36),
	Position = UDim2.new(0, 12, 0, 120),
	Font = Enum.Font.GothamSemibold,
	Text = "",
	PlaceholderText = "Enter key (ex: MEMAYBEO-HUB-2024)",
	TextSize = 13,
	TextColor3 = theme.text,
	PlaceholderColor3 = theme.muted,
	ClearTextOnFocus = false,
	Parent = keyPanel,
})

create("UICorner", {
	CornerRadius = UDim.new(0, 8),
	Parent = keyInput,
})

create("UIStroke", {
	Color = theme.stroke,
	Thickness = 1,
	Parent = keyInput,
})

local keyStatus = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 18),
	Position = UDim2.new(0, 12, 0, 164),
	Font = Enum.Font.Gotham,
	Text = "Key required.",
	TextSize = 12,
	TextColor3 = theme.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = keyPanel,
})

local keyButton = create("TextButton", {
	BackgroundColor3 = theme.accent,
	Size = UDim2.new(0, 140, 0, 34),
	Position = UDim2.new(0, 12, 1, -50),
	Font = Enum.Font.GothamBold,
	Text = "Unlock",
	TextSize = 13,
	TextColor3 = theme.text,
	AutoButtonColor = false,
	Parent = keyPanel,
})

create("UICorner", {
	CornerRadius = UDim.new(0, 8),
	Parent = keyButton,
})

local main = create("Frame", {
	Name = "Main",
	Size = UDim2.new(0, 520, 0, 340),
	Position = UDim2.new(0.5, -260, 0.5, -170),
	BackgroundColor3 = theme.panel,
	BorderSizePixel = 0,
	Visible = false,
	Parent = screenGui,
})

create("UICorner", {
	CornerRadius = UDim.new(0, 14),
	Parent = main,
})

create("UIStroke", {
	Color = theme.stroke,
	Thickness = 1,
	Parent = main,
})

local topBar = create("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = theme.panelDark,
	BorderSizePixel = 0,
	Parent = main,
})

create("UICorner", {
	CornerRadius = UDim.new(0, 14),
	Parent = topBar,
})

local title = create("TextLabel", {
	Name = "Title",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -48, 1, 0),
	Position = UDim2.new(0, 20, 0, 0),
	Font = Enum.Font.GothamBold,
	Text = "MEMAYBEO HUB Multi-Function Menu",
	TextSize = 18,
	TextColor3 = theme.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = topBar,
})

local closeButton = create("TextButton", {
	Name = "Close",
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -36, 0.5, -14),
	BackgroundColor3 = theme.panel,
	Text = "×",
	Font = Enum.Font.GothamBold,
	TextColor3 = theme.muted,
	TextSize = 18,
	Parent = topBar,
})

create("UICorner", {
	CornerRadius = UDim.new(0, 8),
	Parent = closeButton,
})

local tabBar = create("Frame", {
	Name = "TabBar",
	Size = UDim2.new(0, 160, 1, -48),
	Position = UDim2.new(0, 0, 0, 48),
	BackgroundColor3 = theme.panelDark,
	BorderSizePixel = 0,
	Parent = main,
})

create("UIStroke", {
	Color = theme.stroke,
	Thickness = 1,
	Parent = tabBar,
})

local tabList = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = tabBar,
})

create("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
	Parent = tabBar,
})

local content = create("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -160, 1, -48),
	Position = UDim2.new(0, 160, 0, 48),
	BackgroundTransparency = 1,
	Parent = main,
})

local heroArt = create("ImageLabel", {
	Name = "HeroArt",
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 110, 0, 110),
	Position = UDim2.new(0, 16, 0, 12),
	Image = animeImageId,
	ScaleType = Enum.ScaleType.Crop,
	Parent = tabBar,
})

create("UICorner", {
	CornerRadius = UDim.new(0, 10),
	Parent = heroArt,
})

local function createSection(parent, titleText)
	local section = create("Frame", {
		BackgroundColor3 = theme.panelDark,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -24, 0, 130),
		Parent = parent,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0, 10),
		Parent = section,
	})
	create("UIStroke", {
		Color = theme.stroke,
		Thickness = 1,
		Parent = section,
	})
	local titleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -24, 0, 20),
		Font = Enum.Font.GothamSemibold,
		Text = titleText,
		TextSize = 14,
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = section,
	})
	return section
end

local function createButton(parent, text)
	local button = create("TextButton", {
		BackgroundColor3 = theme.panel,
		Size = UDim2.new(0, 140, 0, 34),
		Font = Enum.Font.GothamSemibold,
		Text = text,
		TextSize = 13,
		TextColor3 = theme.text,
		AutoButtonColor = false,
		Parent = parent,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = button,
	})
	create("UIStroke", {
		Color = theme.stroke,
		Thickness = 1,
		Parent = button,
	})
	button.MouseEnter:Connect(function()
		tween(button, {BackgroundColor3 = theme.accent})
	end)
	button.MouseLeave:Connect(function()
		tween(button, {BackgroundColor3 = theme.panel})
	end)
	return button
end

local function createInput(parent, placeholder)
	local box = create("TextBox", {
		BackgroundColor3 = theme.panel,
		Size = UDim2.new(0, 120, 0, 30),
		Font = Enum.Font.Gotham,
		Text = "",
		PlaceholderText = placeholder,
		TextSize = 12,
		TextColor3 = theme.text,
		PlaceholderColor3 = theme.muted,
		ClearTextOnFocus = false,
		Parent = parent,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = box,
	})
	create("UIStroke", {
		Color = theme.stroke,
		Thickness = 1,
		Parent = box,
	})
	return box
end

local tabs = {}
local pages = {}

local function createTab(name)
	local tabButton = create("TextButton", {
		BackgroundColor3 = theme.panel,
		Size = UDim2.new(1, 0, 0, 36),
		Font = Enum.Font.GothamSemibold,
		Text = name,
		TextSize = 13,
		TextColor3 = theme.text,
		AutoButtonColor = false,
		Parent = tabBar,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = tabButton,
	})

	local page = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		Parent = content,
	})

	local layout = create("UIListLayout", {
		Padding = UDim.new(0, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top

	create("UIPadding", {
		PaddingTop = UDim.new(0, 14),
		Parent = page,
	})

	tabs[name] = tabButton
	pages[name] = page

	tabButton.MouseButton1Click:Connect(function()
		for tabName, button in pairs(tabs) do
			button.BackgroundColor3 = theme.panel
			pages[tabName].Visible = false
		end
		tabButton.BackgroundColor3 = theme.accent
		page.Visible = true
	end)

	return page
end

local playerPage = createTab("Player")
local worldPage = createTab("World")
local utilityPage = createTab("Utility")
local pvpPage = createTab("PVP")

tabs.Player.BackgroundColor3 = theme.accent
pages.Player.Visible = true

-- Player section
local playerSection = createSection(playerPage, "Player Controls")
local playerLayout = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = playerSection,
})
playerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
playerLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local walkSpeedInput = createInput(playerSection, "WalkSpeed (16)")
local jumpPowerInput = createInput(playerSection, "JumpPower (50)")
local applyPlayerButton = createButton(playerSection, "Apply")

applyPlayerButton.MouseButton1Click:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local walkValue = tonumber(walkSpeedInput.Text)
	local jumpValue = tonumber(jumpPowerInput.Text)
	if walkValue then
		humanoid.WalkSpeed = math.clamp(walkValue, 1, 300)
	end
	if jumpValue then
		humanoid.JumpPower = math.clamp(jumpValue, 1, 300)
	end
end)

local resetButton = createButton(playerSection, "Reset Defaults")
resetButton.MouseButton1Click:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end
end)

-- World section
local worldSection = createSection(worldPage, "World Settings")
local worldLayout = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = worldSection,
})
worldLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
worldLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local timeInput = createInput(worldSection, "Time (0-24)")
local applyTimeButton = createButton(worldSection, "Apply Time")
applyTimeButton.MouseButton1Click:Connect(function()
	local value = tonumber(timeInput.Text)
	if value then
		Lighting.ClockTime = math.clamp(value, 0, 24)
	end
end)

local fullbright = false
local fullbrightButton = createButton(worldSection, "Toggle Fullbright")
fullbrightButton.MouseButton1Click:Connect(function()
	fullbright = not fullbright
	if fullbright then
		Lighting.Brightness = 3
		Lighting.Ambient = Color3.fromRGB(200, 200, 200)
		Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
	else
		Lighting.Brightness = 1
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	end
end)

-- Utility section
local utilSection = createSection(utilityPage, "Utility Tools")
local utilLayout = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = utilSection,
})
utilLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
utilLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local rejoinButton = createButton(utilSection, "Rejoin Server")
rejoinButton.MouseButton1Click:Connect(function()
	TeleportService:Teleport(game.PlaceId, player)
end)

local copyPosButton = createButton(utilSection, "Copy Position")
copyPosButton.MouseButton1Click:Connect(function()
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and setclipboard then
		setclipboard(string.format("Vector3.new(%.2f, %.2f, %.2f)", root.Position.X, root.Position.Y, root.Position.Z))
	end
end)

-- PVP section (UI only)
local pvpSection = createSection(pvpPage, "PVP Toolkit")
local pvpLayout = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = pvpSection,
})
pvpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
pvpLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local pvpStatus = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 20),
	Font = Enum.Font.Gotham,
	Text = "Status: Idle",
	TextSize = 12,
	TextColor3 = theme.muted,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = pvpSection,
})

local aimToggle = createButton(pvpSection, "Auto Aim: OFF")
aimToggle.Size = UDim2.new(0, 180, 0, 34)

local locatorToggle = createButton(pvpSection, "Locator: OFF")
locatorToggle.Size = UDim2.new(0, 180, 0, 34)

local teamToggle = createButton(pvpSection, "Ignore Team: ON")
teamToggle.Size = UDim2.new(0, 180, 0, 34)

codex/add-aim-head-menu-and-localization-g6nxpx
local wallbangToggle = createButton(pvpSection, "Wallbang: ON")
wallbangToggle.Size = UDim2.new(0, 180, 0, 34)

local pingButton = createButton(pvpSection, "Ping Nearest")
pingButton.Size = UDim2.new(0, 180, 0, 34)

aimToggle.MouseButton1Click:Connect(function()
	autoAimEnabled = not autoAimEnabled
	if autoAimEnabled then
		aimToggle.Text = "Auto Aim: ON"
	else
		aimToggle.Text = "Auto Aim: OFF"
	end
	setAutoAim(autoAimEnabled, pvpStatus)
end)

locatorToggle.MouseButton1Click:Connect(function()
	locatorEnabled = not locatorEnabled
	if locatorEnabled then
		locatorToggle.Text = "Locator: ON"
	else
		locatorToggle.Text = "Locator: OFF"
	end
	setLocatorEnabled(locatorEnabled, pvpStatus)
end)

teamToggle.MouseButton1Click:Connect(function()
	ignoreTeamEnabled = not ignoreTeamEnabled
	if ignoreTeamEnabled then
		teamToggle.Text = "Ignore Team: ON"
	else
		teamToggle.Text = "Ignore Team: OFF"
	end
end)

wallbangToggle.MouseButton1Click:Connect(function()
	wallbangEnabled = not wallbangEnabled
	if wallbangEnabled then
		wallbangToggle.Text = "Wallbang: ON"
	else
		wallbangToggle.Text = "Wallbang: OFF"
	end
	if autoAimEnabled then
		setAutoAim(true, pvpStatus)
	end
end)

pingButton.MouseButton1Click:Connect(function()
	local target, distanceOrError = getNearestPlayer()
	if not target then
		pvpStatus.Text = distanceOrError or "Status: Không thể định vị."
		return
	end

	local head = getHeadPart(target)
	if not head then
		pvpStatus.Text = "Status: Không thể xác định vị trí."
		return
	end

	pvpStatus.Text = string.format("Status: Nearest %s (%.0fm)", target.Name, distanceOrError)
	if setclipboard then
		setclipboard(string.format("CFrame.new(%.2f, %.2f, %.2f)", head.Position.X, head.Position.Y, head.Position.Z))
	end
end)

local function setVisible(state)
	main.Visible = state
end

closeButton.MouseButton1Click:Connect(function()
	setVisible(false)
end)

keyButton.MouseButton1Click:Connect(function()
	if keyInput.Text == accessKey then
		keyStatus.Text = "Access granted."
		keyStatus.TextColor3 = Color3.fromRGB(134, 239, 172)
		main.Visible = true
		keyGate.Visible = false
	else
		keyStatus.Text = "Invalid key. Try again."
		keyStatus.TextColor3 = Color3.fromRGB(248, 113, 113)
	end
end)

if not requireKey then
	keyGate.Visible = false
	main.Visible = true
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightShift then
		if not keyGate.Visible then
			setVisible(not main.Visible)
		end
	end
end)

screenGui.Parent = playerGui

local drag = false
local dragStart
local startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

local function beginDrag(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	drag = true
	dragStart = input.Position
	startPos = main.Position

	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			drag = false
		end
	end)
end

topBar.InputBegan:Connect(beginDrag)
main.InputBegan:Connect(beginDrag)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if drag then
			updateDrag(input)
		end
	end
end)

local hint = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 22),
	Position = UDim2.new(0, 0, 1, -22),
	Font = Enum.Font.Gotham,
	Text = "Press RightShift to toggle menu",
	TextSize = 11,
	TextColor3 = theme.muted,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = main,
})

create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.accent),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(236, 72, 153)),
	}),
	Rotation = 45,
	Parent = topBar,
})

create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 23, 42)),
		ColorSequenceKeypoint.new(1, theme.panel),
	}),
	Rotation = -30,
	Parent = main,
})
