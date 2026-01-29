--[[
	Multi Tool App Module

	Utility hub with a polished multi-function menu.
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local MultiTool = {}

	local window
	local fpsLabel
	local memoryLabel
	local positionLabel
	local statusLabel

	local lightingSnapshot = {}
	local statsConnection
	local autoAimConnection
	local autoAimEnabled = false
	local ignoreTeamEnabled = true
	local locatorEnabled = false
	local locatorConnection
	local locatorBillboards = {}
	local headAimModule
	local headAimLoaded = false
	local headAimError

	local function setStatus(text,color)
		statusLabel.Text = text
		statusLabel.TextColor3 = color or Settings.Theme.Text
	end

	local function getCharacter()
		return plr.Character or plr.CharacterAdded:Wait()
	end

	local function getHumanoid()
		local character = getCharacter()
		return character and character:FindFirstChildOfClass("Humanoid")
	end

	local function getRoot()
		local character = getCharacter()
		return character and character:FindFirstChild("HumanoidRootPart")
	end

	local function formatVector(vec)
		return string.format("%.2f, %.2f, %.2f", vec.X, vec.Y, vec.Z)
	end

	local function loadHeadAim()
		if headAimLoaded then
			return headAimModule, headAimError
		end

		headAimLoaded = true

		if not env or not env.loadfile then
			headAimError = "Executor không hỗ trợ loadfile."
			return nil, headAimError
		end

		local ok, chunk = pcall(env.loadfile, "head_aim.lua")
		if not ok or type(chunk) ~= "function" then
			headAimError = "Không thể tải head_aim.lua."
			return nil, headAimError
		end

		local okModule, moduleData = pcall(chunk)
		if not okModule or type(moduleData) ~= "table" then
			headAimError = "Module head_aim.lua không hợp lệ."
			return nil, headAimError
		end

		headAimModule = moduleData
		return headAimModule, nil
	end

	local function getEnemyTargets()
		local enemies = {}
		for _, player in ipairs(service.Players:GetPlayers()) do
			if player ~= plr then
				if not ignoreTeamEnabled or player.Team ~= plr.Team then
					table.insert(enemies, player)
				end
			end
		end
		return enemies
	end

	local function getHeadPart(target)
		if not target then
			return nil
		end

		local character = target.Character
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

	local function getNearestPlayer()
		local root = getRoot()
		if not root then
			return nil, "Không tìm thấy HumanoidRootPart."
		end

		local nearest
		local nearestDistance
		for _, player in ipairs(service.Players:GetPlayers()) do
			if player ~= plr and (not ignoreTeamEnabled or player.Team ~= plr.Team) then
				local head = getHeadPart(player)
				if head then
					local distance = (head.Position - root.Position).Magnitude
					if not nearestDistance or distance < nearestDistance then
						nearest = player
						nearestDistance = distance
					end
				end
			end
		end

		if not nearest then
			return nil, "Không tìm thấy người chơi phù hợp."
		end

		return nearest, nearestDistance
	end

	local function createLocatorBillboard(player, head)
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "DexLocator"
		billboard.Size = UDim2.new(0,160,0,36)
		billboard.StudsOffset = Vector3.new(0,2.6,0)
		billboard.AlwaysOnTop = true
		billboard.Parent = head

		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = Settings.Theme.Main2
		frame.BackgroundTransparency = 0.15
		frame.BorderSizePixel = 0
		frame.Size = UDim2.new(1,0,1,0)
		frame.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0,6)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Color = Settings.Theme.Outline2
		stroke.Transparency = 0.3
		stroke.Parent = frame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(1,-8,1,0)
		nameLabel.Position = UDim2.new(0,4,0,0)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Settings.Theme.Text
		nameLabel.TextSize = 12
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = frame

		locatorBillboards[player] = billboard
	end

	local function clearLocatorBillboards()
		for player, billboard in pairs(locatorBillboards) do
			if billboard then
				billboard:Destroy()
			end
			locatorBillboards[player] = nil
		end
	end

	local function setLocatorEnabled(enabled)
		locatorEnabled = enabled
		if locatorConnection then
			locatorConnection:Disconnect()
			locatorConnection = nil
		end
		clearLocatorBillboards()

		if not enabled then
			setStatus("Đã tắt định vị người chơi.",Settings.Theme.PlaceholderText)
			return
		end

		setStatus("Đang định vị người chơi...",Color3.fromRGB(129,214,152))
		locatorConnection = service.RunService.RenderStepped:Connect(function()
			local root = getRoot()
			if not root then
				return
			end

			local validPlayers = {}
			for _, player in ipairs(service.Players:GetPlayers()) do
				if player ~= plr and (not ignoreTeamEnabled or player.Team ~= plr.Team) then
					table.insert(validPlayers, player)
				end
			end

			for _, player in ipairs(validPlayers) do
				local head = getHeadPart(player)
				if head then
					if not locatorBillboards[player] or not locatorBillboards[player].Parent then
						createLocatorBillboard(player, head)
					end
					local billboard = locatorBillboards[player]
					if billboard and billboard:FindFirstChild("Frame") then
						local label = billboard.Frame:FindFirstChild("NameLabel")
						if label then
							local distance = (head.Position - root.Position).Magnitude
							label.Text = string.format("%s • %.0fm", player.Name, distance)
						end
					end
				end
			end

			for player, billboard in pairs(locatorBillboards) do
				if not table.find(validPlayers, player) then
					if billboard then
						billboard:Destroy()
					end
					locatorBillboards[player] = nil
				end
			end
		end)
	end

	local function setAutoAim(enabled)
		autoAimEnabled = enabled
		if autoAimConnection then
			autoAimConnection:Disconnect()
			autoAimConnection = nil
		end

		if not enabled then
			setStatus("Đã tắt auto aim.",Settings.Theme.PlaceholderText)
			return
		end

		local moduleData, loadError = loadHeadAim()
		if not moduleData then
			setStatus(loadError or "Không thể bật auto aim.",Settings.Theme.Important)
			autoAimEnabled = false
			return
		end

		setStatus("Auto aim đang chạy.",Color3.fromRGB(129,214,152))
		autoAimConnection = service.RunService.RenderStepped:Connect(function()
			local camera = workspace.CurrentCamera
			if not camera or not autoAimEnabled then
				return
			end

			local origin = camera.CFrame.Position
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			local character = plr.Character
			if character then
				rayParams.FilterDescendantsInstances = {character}
			else
				rayParams.FilterDescendantsInstances = {}
			end

			local enemies = getEnemyTargets()
			local head, position, obstructed = moduleData.getEnemyLocation(enemies, origin, {
				PreferClosest = true,
				RaycastParams = rayParams,
			})

			if head and position then
				camera.CFrame = CFrame.lookAt(origin, position)
				if obstructed then
					setStatus("Đang khóa mục tiêu sau vật cản.",Color3.fromRGB(255,176,81))
				else
					setStatus("Đang khóa mục tiêu.",Color3.fromRGB(129,214,152))
				end
			else
				setStatus("Không tìm thấy mục tiêu.",Settings.Theme.PlaceholderText)
			end
		end)
	end

	local function snapshotLighting()
		local lighting = service.Lighting
		lightingSnapshot = {
			Brightness = lighting.Brightness,
			ExposureCompensation = lighting.ExposureCompensation,
			ClockTime = lighting.ClockTime,
			Ambient = lighting.Ambient,
			OutdoorAmbient = lighting.OutdoorAmbient,
			EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
			EnvironmentSpecularScale = lighting.EnvironmentSpecularScale,
		}
	end

	local function applyLightingSnapshot()
		local lighting = service.Lighting
		for key,value in pairs(lightingSnapshot) do
			lighting[key] = value
		end
	end

	local function createLabel(parent,text,size,weight)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Text = text
		label.Font = weight or Enum.Font.GothamBold
		label.TextSize = size or 14
		label.TextColor3 = Settings.Theme.Text
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = parent
		return label
	end

	local function styleButton(button)
		button.AutoButtonColor = false
		button.BackgroundColor3 = Settings.Theme.Button
		button.BorderColor3 = Settings.Theme.Outline2
		button.Font = Enum.Font.GothamBold
		button.TextColor3 = Settings.Theme.Text
		button.TextSize = 13
		button.TextWrapped = true
		button.ClipsDescendants = true
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0,6)
		corner.Parent = button
		local stroke = Instance.new("UIStroke")
		stroke.Color = Settings.Theme.Outline2
		stroke.Transparency = 0.4
		stroke.Parent = button
		Lib.ButtonAnim(button,{
			Mode = 2,
			StartColor = Settings.Theme.Button,
			HoverColor = Settings.Theme.ButtonHover,
			PressColor = Settings.Theme.ButtonPress,
			OutlineColor = Settings.Theme.Outline2
		})
	end

	local function createSection(parent,title,subtitle,layoutType)
		local section = Instance.new("Frame")
		section.BackgroundColor3 = Settings.Theme.Main2
		section.BorderSizePixel = 0
		section.Size = UDim2.new(1,0,0,140)
		section.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0,10)
		corner.Parent = section

		local stroke = Instance.new("UIStroke")
		stroke.Color = Settings.Theme.Outline2
		stroke.Transparency = 0.35
		stroke.Parent = section

		local header = Instance.new("Frame")
		header.BackgroundTransparency = 1
		header.Size = UDim2.new(1,-20,0,32)
		header.Position = UDim2.new(0,10,0,8)
		header.Parent = section

		local headerTitle = createLabel(header,title,15,Enum.Font.GothamBold)
		headerTitle.Size = UDim2.new(1,0,0,18)

		local headerSubtitle = createLabel(header,subtitle,12,Enum.Font.GothamMedium)
		headerSubtitle.TextColor3 = Settings.Theme.PlaceholderText
		headerSubtitle.Position = UDim2.new(0,0,0,18)
		headerSubtitle.Size = UDim2.new(1,0,0,14)

		local body = Instance.new("Frame")
		body.BackgroundTransparency = 1
		body.Size = UDim2.new(1,-20,1,-52)
		body.Position = UDim2.new(0,10,0,44)
		body.Parent = section

		local layout
		if layoutType == "list" then
			layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			layout.VerticalAlignment = Enum.VerticalAlignment.Top
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0,6)
			layout.Parent = body
		else
			layout = Instance.new("UIGridLayout")
			layout.CellSize = UDim2.new(0.5,-4,0,36)
			layout.CellPadding = UDim2.new(0,8,0,8)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = body
		end

		return section, body
	end

	MultiTool.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Multi Tool")
		window:Resize(420,480)
		MultiTool.Window = window

		local content = window.GuiElems.Content
		content.BackgroundTransparency = 1

		local header = Instance.new("Frame")
		header.Name = "Header"
		header.BackgroundColor3 = Settings.Theme.Main1
		header.BorderSizePixel = 0
		header.Size = UDim2.new(1,0,0,88)
		header.Parent = content

		local headerCorner = Instance.new("UICorner")
		headerCorner.CornerRadius = UDim.new(0,10)
		headerCorner.Parent = header

		local headerStroke = Instance.new("UIStroke")
		headerStroke.Color = Settings.Theme.Outline1
		headerStroke.Transparency = 0.5
		headerStroke.Parent = header

		local headerGradient = Instance.new("UIGradient")
		headerGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,Settings.Theme.Main1),
			ColorSequenceKeypoint.new(1,Settings.Theme.Main2)
		})
		headerGradient.Rotation = 90
		headerGradient.Parent = header

		local title = createLabel(header,"MEMAYBEO HUB Multi Tool",18,Enum.Font.GothamBlack)
		title.Position = UDim2.new(0,16,0,14)
		title.Size = UDim2.new(1,-32,0,22)

		local subtitle = createLabel(header,"Bộ công cụ đa năng với menu sắc nét",12,Enum.Font.GothamMedium)
		subtitle.TextColor3 = Settings.Theme.PlaceholderText
		subtitle.Position = UDim2.new(0,16,0,40)
		subtitle.Size = UDim2.new(1,-32,0,16)

		statusLabel = createLabel(header,"Sẵn sàng hoạt động.",12,Enum.Font.GothamMedium)
		statusLabel.TextColor3 = Color3.fromRGB(129,214,152)
		statusLabel.Position = UDim2.new(0,16,0,60)
		statusLabel.Size = UDim2.new(1,-32,0,16)

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Sections"
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.Position = UDim2.new(0,0,0,96)
		scroll.Size = UDim2.new(1,0,1,-96)
		scroll.ScrollBarThickness = 4
		scroll.ScrollBarImageColor3 = Settings.Theme.Outline2
		scroll.Parent = content

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0,12)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = scroll

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0,12)
		padding.PaddingRight = UDim.new(0,12)
		padding.PaddingTop = UDim.new(0,4)
		padding.PaddingBottom = UDim.new(0,12)
		padding.Parent = scroll

		listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scroll.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y + 8)
		end)

		local quickSection, quickBody = createSection(scroll,"Quick Actions","Thao tác nhanh cho nhân vật","grid")
		quickSection.LayoutOrder = 1

		local copyPos = Instance.new("TextButton")
		copyPos.Text = "Copy Position"
		copyPos.Size = UDim2.new(0.5,-4,1,0)
		copyPos.Parent = quickBody
		styleButton(copyPos)
		copyPos.MouseButton1Click:Connect(function()
			local root = getRoot()
			if not root then
				setStatus("Không tìm thấy HumanoidRootPart.",Settings.Theme.Important)
				return
			end
			if env.setclipboard then
				env.setclipboard("CFrame.new("..formatVector(root.Position)..")")
				setStatus("Đã sao chép vị trí: "..formatVector(root.Position)..".",Color3.fromRGB(129,214,152))
			else
				setStatus("Executor chưa hỗ trợ clipboard.",Settings.Theme.Important)
			end
		end)

		local tpCamera = Instance.new("TextButton")
		tpCamera.Text = "Teleport to Camera"
		tpCamera.Size = UDim2.new(0.5,-4,1,0)
		tpCamera.Parent = quickBody
		styleButton(tpCamera)
		tpCamera.MouseButton1Click:Connect(function()
			local root = getRoot()
			local camera = workspace.CurrentCamera
			if not root or not camera then
				setStatus("Thiếu nhân vật hoặc camera.",Settings.Theme.Important)
				return
			end
			root.CFrame = camera.CFrame * CFrame.new(0,0,-5)
			setStatus("Đã dịch chuyển đến vị trí camera.",Color3.fromRGB(129,214,152))
		end)

		local infoSection, infoBody = createSection(scroll,"System Stats","Theo dõi hiệu năng trực tiếp","list")
		infoSection.LayoutOrder = 2
		infoSection.Size = UDim2.new(1,0,0,120)

		fpsLabel = createLabel(infoBody,"FPS: --",14,Enum.Font.GothamBold)
		fpsLabel.Size = UDim2.new(1,0,0,22)
		fpsLabel.LayoutOrder = 1

		memoryLabel = createLabel(infoBody,"Memory: -- MB",14,Enum.Font.GothamBold)
		memoryLabel.Size = UDim2.new(1,0,0,22)
		memoryLabel.LayoutOrder = 2

		positionLabel = createLabel(infoBody,"Position: --",13,Enum.Font.GothamMedium)
		positionLabel.TextColor3 = Settings.Theme.PlaceholderText
		positionLabel.Size = UDim2.new(1,0,0,22)
		positionLabel.LayoutOrder = 3

		local playerSection, playerBody = createSection(scroll,"Player Tweaks","Chỉnh thông số di chuyển nhanh","grid")
		playerSection.LayoutOrder = 3
		playerSection.Size = UDim2.new(1,0,0,150)

		local speedBox = Instance.new("TextBox")
		speedBox.Text = ""
		speedBox.PlaceholderText = "WalkSpeed (mặc định 16)"
		speedBox.Font = Enum.Font.GothamMedium
		speedBox.TextColor3 = Settings.Theme.Text
		speedBox.PlaceholderColor3 = Settings.Theme.PlaceholderText
		speedBox.BackgroundColor3 = Settings.Theme.TextBox
		speedBox.BorderColor3 = Settings.Theme.Outline3
		speedBox.Size = UDim2.new(0.5,-4,0,32)
		speedBox.Parent = playerBody
		local speedCorner = Instance.new("UICorner",speedBox)
		speedCorner.CornerRadius = UDim.new(0,6)

		local jumpBox = Instance.new("TextBox")
		jumpBox.Text = ""
		jumpBox.PlaceholderText = "JumpPower (mặc định 50)"
		jumpBox.Font = Enum.Font.GothamMedium
		jumpBox.TextColor3 = Settings.Theme.Text
		jumpBox.PlaceholderColor3 = Settings.Theme.PlaceholderText
		jumpBox.BackgroundColor3 = Settings.Theme.TextBox
		jumpBox.BorderColor3 = Settings.Theme.Outline3
		jumpBox.Size = UDim2.new(0.5,-4,0,32)
		jumpBox.Parent = playerBody
		local jumpCorner = Instance.new("UICorner",jumpBox)
		jumpCorner.CornerRadius = UDim.new(0,6)

		local applyButton = Instance.new("TextButton")
		applyButton.Text = "Apply"
		applyButton.Size = UDim2.new(0.5,-4,0,32)
		applyButton.Parent = playerBody
		styleButton(applyButton)

		local resetButton = Instance.new("TextButton")
		resetButton.Text = "Reset Defaults"
		resetButton.Size = UDim2.new(0.5,-4,0,32)
		resetButton.Parent = playerBody
		styleButton(resetButton)

		applyButton.MouseButton1Click:Connect(function()
			local humanoid = getHumanoid()
			if not humanoid then
				setStatus("Không tìm thấy Humanoid.",Settings.Theme.Important)
				return
			end
			local speed = tonumber(speedBox.Text)
			local jump = tonumber(jumpBox.Text)
			if speed then humanoid.WalkSpeed = speed end
			if jump then humanoid.JumpPower = jump end
			setStatus("Đã áp dụng tốc độ/nhảy mới.",Color3.fromRGB(129,214,152))
		end)

		resetButton.MouseButton1Click:Connect(function()
			local humanoid = getHumanoid()
			if not humanoid then
				setStatus("Không tìm thấy Humanoid.",Settings.Theme.Important)
				return
			end
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			speedBox.Text = ""
			jumpBox.Text = ""
			setStatus("Đã reset WalkSpeed/JumpPower.",Color3.fromRGB(129,214,152))
		end)

		local envSection, envBody = createSection(scroll,"Environment","Tăng độ sáng & phục hồi nhanh","grid")
		envSection.LayoutOrder = 4
		envSection.Size = UDim2.new(1,0,0,140)

		local boostButton = Instance.new("TextButton")
		boostButton.Text = "Boost Lighting"
		boostButton.Size = UDim2.new(0.5,-4,0,36)
		boostButton.Parent = envBody
		styleButton(boostButton)

		local restoreButton = Instance.new("TextButton")
		restoreButton.Text = "Restore Lighting"
		restoreButton.Size = UDim2.new(0.5,-4,0,36)
		restoreButton.Parent = envBody
		styleButton(restoreButton)

		boostButton.MouseButton1Click:Connect(function()
			local lighting = service.Lighting
			lighting.Brightness = 3
			lighting.ExposureCompensation = 0.2
			lighting.EnvironmentDiffuseScale = 1
			lighting.EnvironmentSpecularScale = 1
			lighting.Ambient = Color3.fromRGB(170,170,170)
			lighting.OutdoorAmbient = Color3.fromRGB(170,170,170)
			setStatus("Đã tăng độ sáng môi trường.",Color3.fromRGB(129,214,152))
		end)

		restoreButton.MouseButton1Click:Connect(function()
			applyLightingSnapshot()
			setStatus("Đã khôi phục lighting ban đầu.",Color3.fromRGB(129,214,152))
		end)

		local combatSection, combatBody = createSection(scroll,"Combat Assist","Hỗ trợ khóa mục tiêu qua vật cản","grid")
		combatSection.LayoutOrder = 5
		combatSection.Size = UDim2.new(1,0,0,120)

		local aimToggle = Instance.new("TextButton")
		aimToggle.Text = "Auto Aim: OFF"
		aimToggle.Size = UDim2.new(0.5,-4,0,36)
		aimToggle.Parent = combatBody
		styleButton(aimToggle)

		local teamToggle = Instance.new("TextButton")
		teamToggle.Text = "Ignore Team: ON"
		teamToggle.Size = UDim2.new(0.5,-4,0,36)
		teamToggle.Parent = combatBody
		styleButton(teamToggle)

		aimToggle.MouseButton1Click:Connect(function()
			autoAimEnabled = not autoAimEnabled
			if autoAimEnabled then
				aimToggle.Text = "Auto Aim: ON"
			else
				aimToggle.Text = "Auto Aim: OFF"
			end
			setAutoAim(autoAimEnabled)
		end)

		teamToggle.MouseButton1Click:Connect(function()
			ignoreTeamEnabled = not ignoreTeamEnabled
			if ignoreTeamEnabled then
				teamToggle.Text = "Ignore Team: ON"
			else
				teamToggle.Text = "Ignore Team: OFF"
			end
		end)

		local locateSection, locateBody = createSection(scroll,"Locate Players","Định vị & ghim vị trí người chơi","grid")
		locateSection.LayoutOrder = 6
		locateSection.Size = UDim2.new(1,0,0,120)

		local locatorToggle = Instance.new("TextButton")
		locatorToggle.Text = "Locator: OFF"
		locatorToggle.Size = UDim2.new(0.5,-4,0,36)
		locatorToggle.Parent = locateBody
		styleButton(locatorToggle)

		local pingButton = Instance.new("TextButton")
		pingButton.Text = "Ping Nearest"
		pingButton.Size = UDim2.new(0.5,-4,0,36)
		pingButton.Parent = locateBody
		styleButton(pingButton)

		locatorToggle.MouseButton1Click:Connect(function()
			locatorEnabled = not locatorEnabled
			if locatorEnabled then
				locatorToggle.Text = "Locator: ON"
			else
				locatorToggle.Text = "Locator: OFF"
			end
			setLocatorEnabled(locatorEnabled)
		end)

		pingButton.MouseButton1Click:Connect(function()
			local target, distanceOrError = getNearestPlayer()
			if not target then
				setStatus(distanceOrError or "Không thể định vị.",Settings.Theme.Important)
				return
			end

			local head = getHeadPart(target)
			if not head then
				setStatus("Không thể xác định vị trí mục tiêu.",Settings.Theme.Important)
				return
			end

			setStatus(string.format("Mục tiêu gần nhất: %s (%.0fm).", target.Name, distanceOrError),Color3.fromRGB(129,214,152))
			if env.setclipboard then
				env.setclipboard("CFrame.new("..formatVector(head.Position)..")")
			end
		end)

		snapshotLighting()

		local lastTick = tick()
		local frames = 0
		statsConnection = service.RunService.RenderStepped:Connect(function()
			frames = frames + 1
			local now = tick()
			if now - lastTick >= 1 then
				local fps = math.floor(frames / (now - lastTick) + 0.5)
				fpsLabel.Text = "FPS: "..fps
				frames = 0
				lastTick = now

				local root = getRoot()
				if root then
					positionLabel.Text = "Position: "..formatVector(root.Position)
				end

				local ok,mem = pcall(function()
					return service.Stats:GetTotalMemoryUsageMb()
				end)
				if ok then
					memoryLabel.Text = string.format("Memory: %.1f MB",mem)
				else
					memoryLabel.Text = "Memory: -- MB"
				end
			end
		end)
	end

	return MultiTool
end

-- TODO: Remove when open source
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end
