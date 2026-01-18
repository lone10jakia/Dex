-- Fancy Multi-Function Menu
-- Standalone Roblox LocalScript-style UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

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

local screenGui = create("ScreenGui", {
	Name = "FancyMenu",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local main = create("Frame", {
	Name = "Main",
	Size = UDim2.new(0, 520, 0, 340),
	Position = UDim2.new(0.5, -260, 0.5, -170),
	BackgroundColor3 = theme.panel,
	BorderSizePixel = 0,
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
	Text = "Dex Multi-Function Menu",
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

local function setVisible(state)
	main.Visible = state
end

closeButton.MouseButton1Click:Connect(function()
	setVisible(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightShift then
		setVisible(not main.Visible)
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

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		drag = true
		dragStart = input.Position
		startPos = main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				drag = false
			end
		end)
	end
end)

topBar.InputChanged:Connect(function(input)
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
