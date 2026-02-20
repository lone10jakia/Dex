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
local storedCameraType
local storedCameraSubject
local locatorEnabled = false
local locatorConnection
local locatorBillboards = {}
local ignoreTeamEnabled = true
local wallbangEnabled = false
local infiniteAmmoEnabled = false
local fastReloadEnabled = false
local ammoConnection
local ammoOriginals = {}
local minimized = false
local silentAimEnabled = false
local silentAimHooked = false
local originalNamecall
local npcFlyEnabled = false
local npcFlyConnection
local npcFlyAutoRotate
local npcFlyOffset = -10
local npcFlyOffsetStep = 3
local npcFlyMode = "off"
local npcOrbitAngle = 0
local npcOrbitRadius = 6
local npcOrbitSpeed = 1.5
local npcOrbitHeight = 0
local npcHoverOffset = 6
local npcTuneSpeedStep = 0.5
local npcTuneHeightStep = 2
local npcTuneDistanceStep = 2
local autoAttackEnabled = false
local autoAttackConnection
local autoBandageEnabled = false
local autoBandageConnection
local autoCollectEnabled = false
local autoCollectConnection
local autoCollectRadius = 20
local vipUnlocked = false
local antiKickEnabled = false
local antiKickHooked = false
local antiKickOriginalNamecall
local autoHealEnabled = false
local autoHealConnection
local autoHealTargetCFrame
local autoHealThreshold = 25
local autoHealCooldown = 0
local npcShieldEnabled = false
local npcShieldConnection
local npcShieldRadius = 18
local npcShieldForce = 120
local aimParts = {"Head", "UpperTorso", "HumanoidRootPart"}
local aimPartLabels = {
	vi = {
		Head = "Đầu",
		UpperTorso = "Thân trên",
		HumanoidRootPart = "Thân giữa",
	},
	en = {
		Head = "Head",
		UpperTorso = "Upper Torso",
		HumanoidRootPart = "Root",
	},
}
local aimPartIndex = 1
local hitboxEnabled = false
local hitboxConnection
local hitboxOriginals = {}
local currentLanguage = "vi"
local configKey = "_FancyMenuConfig"
local savedConfig = rawget(_G, configKey)

local languageStrings = {
	vi = {
		tab_player = "Nhân vật",
		tab_world = "Thế giới",
		tab_utility = "Tiện ích",
		tab_pvp = "PVP",
		tab_settings = "Cài đặt",
		section_player = "Điều khiển nhân vật",
		section_world = "Cài đặt thế giới",
		section_utility = "Công cụ tiện ích",
		section_pvp = "Công cụ PVP",
		section_settings = "Tùy chỉnh",
		key_title = "MEMAYBEO HUB Mã truy cập",
		key_subtitle = "Nhập mã để mở menu",
		key_placeholder = "Nhập mã (vd: MEMAYBEO-HUB-2024)",
		key_required = "Cần mã truy cập.",
		key_unlock = "Mở khóa",
		key_success = "Đã xác thực.",
		key_invalid = "Sai mã. Thử lại.",
		menu_title = "MEMAYBEO HUB Menu đa chức năng",
		hint = "Nhấn RightShift để ẩn/hiện menu",
		status_idle = "Trạng thái: Sẵn sàng",
		status_locator_off = "Trạng thái: Tắt định vị",
		status_locator_on = "Trạng thái: Đang định vị...",
		status_auto_off = "Trạng thái: Tắt tự ngắm",
		status_auto_on = "Trạng thái: Tự ngắm hoạt động",
		status_wait_respawn = "Trạng thái: Chờ hồi sinh",
		status_target_blocked = "Trạng thái: Mục tiêu bị che",
		status_locked = "Trạng thái: Khóa %s (%.0fm)",
		status_no_target = "Trạng thái: Không có mục tiêu",
		no_enemy = "Không tìm thấy người chơi phù hợp.",
		status_locate_fail = "Trạng thái: Không thể định vị.",
		status_target_fail = "Trạng thái: Không thể xác định vị trí.",
		status_nearest = "Trạng thái: Gần nhất %s (%.0fm)",
		status_headmagnet_on = "Trạng thái: Bật hút đầu",
		status_headmagnet_off = "Trạng thái: Tắt hút đầu",
		walkspeed = "Tốc độ chạy (16)",
		jumppower = "Sức bật (50)",
		apply = "Áp dụng",
		reset = "Đặt lại",
		time = "Giờ (0-24)",
		apply_time = "Áp dụng giờ",
		fullbright = "Bật/Tắt sáng",
		rejoin = "Vào lại server",
		copy_pos = "Sao chép vị trí",
		npc_fly_on = "Bay dưới chân NPC: BẬT",
		npc_fly_off = "Bay dưới chân NPC: TẮT",
		npc_tele = "Tele dưới chân NPC",
		npc_fly_up = "Bay cao hơn",
		npc_fly_down = "Bay thấp hơn",
		npc_orbit_on = "Bay vòng quanh: BẬT",
		npc_orbit_off = "Bay vòng quanh: TẮT",
		npc_hover_on = "Bay trên đầu: BẬT",
		npc_hover_off = "Bay trên đầu: TẮT",
		npc_tune_speed_up = "Tăng tốc bay",
		npc_tune_speed_down = "Giảm tốc bay",
		npc_tune_height_up = "Tăng độ cao",
		npc_tune_height_down = "Giảm độ cao",
		npc_tune_distance_up = "Tăng khoảng cách",
		npc_tune_distance_down = "Giảm khoảng cách",
		auto_attack_on = "Tự đánh khi cầm vũ khí: BẬT",
		auto_attack_off = "Tự đánh khi cầm vũ khí: TẮT",
		auto_bandage_on = "Auto dùng băng gạc: BẬT",
		auto_bandage_off = "Auto dùng băng gạc: TẮT",
		auto_collect_on = "Auto nhặt: BẬT",
		auto_collect_off = "Auto nhặt: TẮT",
		move_speed = "Tốc độ di chuyển (16)",
		quick_collect_radius = "Bán kính nhặt (stud)",
		apply_collect = "Áp dụng cài đặt",
		vip_unlock_on = "Mở khóa VIP: BẬT",
		vip_unlock_off = "Mở khóa VIP: TẮT",
		antikick_on = "Anti-kick khi tele: BẬT",
		antikick_off = "Anti-kick khi tele: TẮT",
		collect_nearby = "Nhặt xung quanh",
		auto_heal_on = "Tự hồi máu 25%: BẬT",
		auto_heal_off = "Tự hồi máu 25%: TẮT",
		set_heal_spot = "Lưu vị trí hồi máu",
		create_npc_weapon = "Tạo vũ khí diệt NPC",
		npc_weapon_created = "Đã tạo vũ khí trong balo",
		npc_shield_on = "Khiên đẩy NPC: BẬT",
		npc_shield_off = "Khiên đẩy NPC: TẮT",
		auto_on = "Tự ngắm: BẬT",
		auto_off = "Tự ngắm: TẮT",
		locator_on = "Định vị: BẬT",
		locator_off = "Định vị: TẮT",
		ignore_team_on = "Bỏ qua team: BẬT",
		ignore_team_off = "Bỏ qua team: TẮT",
		wallbang_on = "Xuyên tường: BẬT",
		wallbang_off = "Xuyên tường: TẮT",
		infinite_on = "Đạn vô hạn: BẬT",
		infinite_off = "Đạn vô hạn: TẮT",
		reload_on = "Nạp nhanh: BẬT",
		reload_off = "Nạp nhanh: TẮT",
		headmagnet_on = "Hút đầu: BẬT",
		headmagnet_off = "Hút đầu: TẮT",
		aim_part = "Vị trí ngắm: %s",
		hitbox_on = "Vùng trúng: BẬT",
		hitbox_off = "Vùng trúng: TẮT",
		ping = "Ping gần nhất",
		save_settings = "Lưu cài đặt",
		clear_settings = "Xóa lưu",
		language_toggle = "Ngôn ngữ: Việt",
		settings_saved = "Trạng thái: Đã lưu cài đặt",
		settings_cleared = "Trạng thái: Đã xóa lưu",
	},
	en = {
		tab_player = "Player",
		tab_world = "World",
		tab_utility = "Utility",
		tab_pvp = "PVP",
		tab_settings = "Settings",
		section_player = "Player Controls",
		section_world = "World Settings",
		section_utility = "Utility Tools",
		section_pvp = "PVP Toolkit",
		section_settings = "Preferences",
		key_title = "MEMAYBEO HUB Access Key",
		key_subtitle = "Enter the key to unlock the menu",
		key_placeholder = "Enter key (ex: MEMAYBEO-HUB-2024)",
		key_required = "Key required.",
		key_unlock = "Unlock",
		key_success = "Access granted.",
		key_invalid = "Invalid key. Try again.",
		menu_title = "MEMAYBEO HUB Multi-Function Menu",
		hint = "Press RightShift to toggle menu",
		status_idle = "Status: Ready",
		status_locator_off = "Status: Locator Off",
		status_locator_on = "Status: Locating players...",
		status_auto_off = "Status: Auto aim off",
		status_auto_on = "Status: Auto aim active",
		status_wait_respawn = "Status: Waiting for respawn",
		status_target_blocked = "Status: Target blocked",
		status_locked = "Status: Locked %s (%.0fm)",
		status_no_target = "Status: No target",
		no_enemy = "No suitable player found.",
		status_locate_fail = "Status: Unable to locate.",
		status_target_fail = "Status: Cannot resolve target.",
		status_nearest = "Status: Nearest %s (%.0fm)",
		status_headmagnet_on = "Status: Head magnet enabled",
		status_headmagnet_off = "Status: Head magnet disabled",
		walkspeed = "WalkSpeed (16)",
		jumppower = "JumpPower (50)",
		apply = "Apply",
		reset = "Reset",
		time = "Time (0-24)",
		apply_time = "Apply Time",
		fullbright = "Toggle Fullbright",
		rejoin = "Rejoin Server",
		copy_pos = "Copy Position",
		npc_fly_on = "Fly under NPC: ON",
		npc_fly_off = "Fly under NPC: OFF",
		npc_tele = "Teleport under NPC",
		npc_fly_up = "Fly higher",
		npc_fly_down = "Fly lower",
		npc_orbit_on = "Orbit NPC: ON",
		npc_orbit_off = "Orbit NPC: OFF",
		npc_hover_on = "Hover above NPC: ON",
		npc_hover_off = "Hover above NPC: OFF",
		npc_tune_speed_up = "Increase speed",
		npc_tune_speed_down = "Decrease speed",
		npc_tune_height_up = "Raise height",
		npc_tune_height_down = "Lower height",
		npc_tune_distance_up = "Increase distance",
		npc_tune_distance_down = "Decrease distance",
		auto_attack_on = "Auto attack on equip: ON",
		auto_attack_off = "Auto attack on equip: OFF",
		auto_bandage_on = "Auto use bandage: ON",
		auto_bandage_off = "Auto use bandage: OFF",
		auto_collect_on = "Auto pickup: ON",
		auto_collect_off = "Auto pickup: OFF",
		move_speed = "Move speed (16)",
		quick_collect_radius = "Pickup radius (stud)",
		apply_collect = "Apply settings",
		vip_unlock_on = "VIP unlock: ON",
		vip_unlock_off = "VIP unlock: OFF",
		antikick_on = "Anti-kick on teleport: ON",
		antikick_off = "Anti-kick on teleport: OFF",
		collect_nearby = "Collect nearby",
		auto_heal_on = "Auto heal at 25%: ON",
		auto_heal_off = "Auto heal at 25%: OFF",
		set_heal_spot = "Save heal spot",
		create_npc_weapon = "Create NPC killer weapon",
		npc_weapon_created = "Weapon added to backpack",
		npc_shield_on = "NPC repel shield: ON",
		npc_shield_off = "NPC repel shield: OFF",
		auto_on = "Auto aim: ON",
		auto_off = "Auto aim: OFF",
		locator_on = "Locator: ON",
		locator_off = "Locator: OFF",
		ignore_team_on = "Ignore team: ON",
		ignore_team_off = "Ignore team: OFF",
		wallbang_on = "Wallbang: ON",
		wallbang_off = "Wallbang: OFF",
		infinite_on = "Infinite ammo: ON",
		infinite_off = "Infinite ammo: OFF",
		reload_on = "Fast reload: ON",
		reload_off = "Fast reload: OFF",
		headmagnet_on = "Head magnet: ON",
		headmagnet_off = "Head magnet: OFF",
		aim_part = "Aim part: %s",
		hitbox_on = "Hitbox: ON",
		hitbox_off = "Hitbox: OFF",
		ping = "Ping Nearest",
		save_settings = "Save settings",
		clear_settings = "Clear saved",
		language_toggle = "Language: English",
		settings_saved = "Status: Settings saved",
		settings_cleared = "Status: Saved cleared",
	},
}

if savedConfig and type(savedConfig) == "table" and languageStrings[savedConfig.language] then
	currentLanguage = savedConfig.language
end

local function getText(key)
	local lang = languageStrings[currentLanguage] or languageStrings.vi
	return lang[key] or key
end

local function getNpcRoot()
	local cityFolder = workspace:FindFirstChild("CityNPCs")
	local npcFolder = cityFolder and cityFolder:FindFirstChild("NPCs")
	if not npcFolder then
		return nil
	end
	local npc = npcFolder:GetChildren()[2]
	if not npc then
		return nil
	end
	return npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
end

local function getNpcUndergroundCFrame(npcRoot)
	local targetPosition = npcRoot.Position + Vector3.new(0, npcFlyOffset, 0)
	return CFrame.new(targetPosition, targetPosition + Vector3.new(0, 1, 0))
end

local function setNpcFlyMode(mode)
	if npcFlyConnection then
		npcFlyConnection:Disconnect()
		npcFlyConnection = nil
	end
	if npcFlyAutoRotate ~= nil then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = npcFlyAutoRotate
		end
		npcFlyAutoRotate = nil
	end

	npcFlyMode = mode or "off"
	npcFlyEnabled = npcFlyMode == "under"

	if npcFlyMode == "off" then
		return
	end

	npcFlyConnection = RunService.Heartbeat:Connect(function(delta)
		local npcRoot = getNpcRoot()
		if not npcRoot then
			return
		end
		local character = player.Character
		if not character then
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and npcFlyAutoRotate == nil then
			npcFlyAutoRotate = humanoid.AutoRotate
			humanoid.AutoRotate = false
		end
			if npcFlyMode == "under" then
				root.CFrame = getNpcUndergroundCFrame(npcRoot)
			elseif npcFlyMode == "orbit" then
				npcOrbitAngle = (npcOrbitAngle + npcOrbitSpeed * delta) % (math.pi * 2)
				local offset = Vector3.new(math.cos(npcOrbitAngle) * npcOrbitRadius, npcOrbitHeight, math.sin(npcOrbitAngle) * npcOrbitRadius)
				local targetPosition = npcRoot.Position + offset
				root.CFrame = CFrame.new(targetPosition, npcRoot.Position)
		elseif npcFlyMode == "above" then
			local targetPosition = npcRoot.Position + Vector3.new(0, npcHoverOffset, 0)
			root.CFrame = CFrame.new(targetPosition, npcRoot.Position)
		end
	end)
end

local function updateNpcFly(enable)
	setNpcFlyMode(enable and "under" or "off")
end

local function updateAntiKick(enable)
	antiKickEnabled = enable
	if antiKickHooked then
		return
	end
	if not enable or not hookmetamethod then
		return
	end
	antiKickHooked = true
	antiKickOriginalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if antiKickEnabled and method == "Kick" then
			return
		end
		return antiKickOriginalNamecall(self, ...)
	end)
end

local function updateAutoAttack(enable)
	autoAttackEnabled = enable
	if autoAttackConnection then
		autoAttackConnection:Disconnect()
		autoAttackConnection = nil
	end
	if not enable then
		return
	end
	autoAttackConnection = RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character then
			return
		end
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			pcall(function()
				tool:Activate()
			end)
		end
	end)
end

local collectNearbyItems

local function findBandageTool()
	local character = player.Character
	local backpack = player:FindFirstChild("Backpack")
	local function findIn(container)
		if not container then
			return nil
		end
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") and string.find(tool.Name:lower(), "bandage") then
				return tool
			end
		end
		return nil
	end
	return findIn(character) or findIn(backpack)
end

local function updateAutoBandage(enable)
	autoBandageEnabled = enable
	if autoBandageConnection then
		autoBandageConnection:Disconnect()
		autoBandageConnection = nil
	end
	if not enable then
		return
	end
	autoBandageConnection = RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		if humanoid.Health <= autoHealThreshold then
			local bandage = findBandageTool()
			if bandage then
				if bandage.Parent ~= character then
					bandage.Parent = character
				end
				pcall(function()
					bandage:Activate()
				end)
			end
		end
	end)
end

local function updateAutoCollect(enable)
	autoCollectEnabled = enable
	if autoCollectConnection then
		autoCollectConnection:Disconnect()
		autoCollectConnection = nil
	end
	if not enable then
		return
	end
	autoCollectConnection = RunService.Heartbeat:Connect(function()
		collectNearbyItems(autoCollectRadius)
	end)
end

collectNearbyItems = function(radiusOverride)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local radius = radiusOverride or autoCollectRadius
	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("Tool") and item.Parent ~= character then
			local handle = item:FindFirstChild("Handle")
			if handle and (handle.Position - root.Position).Magnitude <= radius then
				item.Parent = player.Backpack
			end
		elseif item:IsA("BasePart") then
			local toolParent = item.Parent
			if toolParent and toolParent:IsA("Tool") and toolParent.Parent ~= character then
				if (item.Position - root.Position).Magnitude <= radius then
					toolParent.Parent = player.Backpack
				end
			end
		end
	end

	local cashFolder = workspace:FindFirstChild("CityNPCs")
	cashFolder = cashFolder and cashFolder:FindFirstChild("Drop")
	cashFolder = cashFolder and cashFolder:FindFirstChild("Cash")
	if cashFolder then
		for _, cashItem in ipairs(cashFolder:GetDescendants()) do
			if cashItem:IsA("BasePart") and (cashItem.Position - root.Position).Magnitude <= radius then
				cashItem.CFrame = root.CFrame
			end
		end
	end
end

local function updateAutoHeal(enable)
	autoHealEnabled = enable
	if autoHealConnection then
		autoHealConnection:Disconnect()
		autoHealConnection = nil
	end
	if not enable then
		return
	end
	autoHealConnection = RunService.Heartbeat:Connect(function(delta)
		if not autoHealTargetCFrame then
			return
		end
		if autoHealCooldown > 0 then
			autoHealCooldown = math.max(0, autoHealCooldown - delta)
			return
		end
		local character = player.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 and humanoid.Health <= autoHealThreshold then
			root.CFrame = autoHealTargetCFrame
			autoHealCooldown = 2
		end
	end)
end

local function getNpcModels()
	local cityFolder = workspace:FindFirstChild("CityNPCs")
	local npcFolder = cityFolder and cityFolder:FindFirstChild("NPCs")
	if not npcFolder then
		return {}
	end
	local npcs = {}
	for _, npc in ipairs(npcFolder:GetChildren()) do
		if npc:IsA("Model") then
			table.insert(npcs, npc)
		end
	end
	return npcs
end

local function createNpcWeapon()
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return nil
	end
	local weapon = Instance.new("Tool")
	weapon.Name = "NPC Slayer"
	weapon.RequiresHandle = true
	weapon.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 4, 1)
	handle.Color = Color3.fromRGB(220, 45, 45)
	handle.Material = Enum.Material.Neon
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = weapon

	weapon.Activated:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		for _, npc in ipairs(getNpcModels()) do
			local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
			local humanoid = npc:FindFirstChildOfClass("Humanoid")
			if npcRoot and humanoid and humanoid.Health > 0 then
				if (npcRoot.Position - root.Position).Magnitude <= 18 then
					humanoid.Health = 0
				end
			end
		end
	end)

	weapon.Parent = backpack
	return weapon
end

local function updateNpcShield(enable)
	npcShieldEnabled = enable
	if npcShieldConnection then
		npcShieldConnection:Disconnect()
		npcShieldConnection = nil
	end
	if not enable then
		return
	end
	npcShieldConnection = RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		for _, npc in ipairs(getNpcModels()) do
			local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
			if npcRoot then
				local offset = npcRoot.Position - root.Position
				local distance = offset.Magnitude
				if distance > 0 and distance <= npcShieldRadius then
					local pushDir = offset.Unit
					npcRoot.AssemblyLinearVelocity = pushDir * npcShieldForce + Vector3.new(0, 20, 0)
				end
			end
		end
	end)
end

local function getAimPartLabel()
	local labels = aimPartLabels[currentLanguage] or aimPartLabels.vi
	return labels[aimParts[aimPartIndex]] or labels.Head
end

local function applySavedConfig()
	if not savedConfig or type(savedConfig) ~= "table" then
		return
	end

	autoAimEnabled = savedConfig.autoAimEnabled or false
	locatorEnabled = savedConfig.locatorEnabled or false
	ignoreTeamEnabled = savedConfig.ignoreTeamEnabled ~= false
	wallbangEnabled = savedConfig.wallbangEnabled or false
	infiniteAmmoEnabled = savedConfig.infiniteAmmoEnabled or false
	fastReloadEnabled = savedConfig.fastReloadEnabled or false
	silentAimEnabled = savedConfig.silentAimEnabled or false
	hitboxEnabled = savedConfig.hitboxEnabled or false
	if type(savedConfig.aimPartIndex) == "number" then
		aimPartIndex = math.max(1, math.min(#aimParts, savedConfig.aimPartIndex))
	end
end

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

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
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

local function getAimPart(targetPlayer)
	if not targetPlayer then
		return nil
	end

	local character = targetPlayer.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
		return nil
	end

	local partName = aimParts[aimPartIndex] or "Head"
	local part = character:FindFirstChild(partName)
	if part and part:IsA("BasePart") then
		return part
	end

	return getHeadPart(targetPlayer)
end

local function getCandidatePlayers()
	local candidates = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			if ignoreTeamEnabled and player.Team ~= nil and other.Team ~= nil and other.Team == player.Team then
				continue
			end
			table.insert(candidates, other)
		end
	end
	return candidates
end

local function getNearestPlayer()
	local root = getRoot()
	local origin = root and root.Position
	if not origin then
		local camera = workspace.CurrentCamera
		origin = camera and camera.CFrame.Position or Vector3.new(0, 0, 0)
	end

	local nearest
	local nearestDistance
	for _, other in ipairs(getCandidatePlayers()) do
		local part = getAimPart(other)
		if part then
			local distance = (part.Position - origin).Magnitude
			if not nearestDistance or distance < nearestDistance then
				nearest = other
				nearestDistance = distance
			end
		end
	end

	if not nearest then
		return nil, getText("no_enemy")
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
			setStatusLabel(statusLabel, "status_locator_off")
		end
		return
	end

	if statusLabel then
		setStatusLabel(statusLabel, "status_locator_on")
	end
	locatorConnection = RunService.RenderStepped:Connect(function()
		local origin
		local root = getRoot()
		if root then
			origin = root.Position
		else
			local camera = workspace.CurrentCamera
			origin = camera and camera.CFrame.Position or Vector3.new(0, 0, 0)
		end

		local candidates = getCandidatePlayers()
			for _, other in ipairs(candidates) do
				local part = getAimPart(other)
				if part then
					if not locatorBillboards[other] or not locatorBillboards[other].Parent then
						createLocatorBillboard(other, part)
					end
					local billboard = locatorBillboards[other]
					local label = billboard and billboard:FindFirstChild("Frame") and billboard.Frame:FindFirstChild("NameLabel")
					if label then
						local distance = (part.Position - origin).Magnitude
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
		local camera = workspace.CurrentCamera
		if camera and storedCameraType then
			camera.CameraType = storedCameraType
			if storedCameraSubject then
				camera.CameraSubject = storedCameraSubject
			end
		end
		storedCameraType = nil
		storedCameraSubject = nil
		if statusLabel then
			setStatusLabel(statusLabel, "status_auto_off")
		end
		return
	end

	do
		local camera = workspace.CurrentCamera
		if camera then
			storedCameraType = camera.CameraType
			storedCameraSubject = camera.CameraSubject
			camera.CameraType = Enum.CameraType.Scriptable
		end
	end

	if statusLabel then
		setStatusLabel(statusLabel, "status_auto_on")
	end

	autoAimConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		if not isCharacterAlive() then
			if statusLabel then
				setStatusLabel(statusLabel, "status_wait_respawn")
			end
			return
		end

		local target, distanceOrError = getNearestPlayer()
		if not target then
			if statusLabel then
				if distanceOrError then
					statusLabel.Text = distanceOrError
				else
					setStatusLabel(statusLabel, "status_no_target")
				end
			end
			return
		end

		local part = getAimPart(target)
		if not part then
			return
		end

		if not wallbangEnabled and workspace and workspace.Raycast then
			local origin = camera.CFrame.Position
			local direction = part.Position - origin
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			local character = getCharacter()
			if character then
				rayParams.FilterDescendantsInstances = {character}
			else
				rayParams.FilterDescendantsInstances = {}
			end
			local result = workspace:Raycast(origin, direction, rayParams)
			if result and result.Instance and not result.Instance:IsDescendantOf(part.Parent) then
				if statusLabel then
					setStatusLabel(statusLabel, "status_target_blocked")
				end
				return
			end
		end

		camera.CFrame = CFrame.lookAt(camera.CFrame.Position, part.Position)
		if statusLabel then
			setStatusLabel(statusLabel, "status_locked", target.Name, distanceOrError)
		end
	end)
end

local function setStatusLabel(label, key, ...)
	if not label then
		return
	end
	local text = getText(key)
	if select("#", ...) > 0 then
		text = string.format(text, ...)
	end
	label.Text = text
end

local currentStatusKey = "status_idle"
local currentStatusArgs = {}

local function setPvpStatus(key, ...)
	currentStatusKey = key
	currentStatusArgs = {...}
	setStatusLabel(pvpStatus, key, ...)
end

local AMMO_VALUE_NAMES = {
	Ammo = true,
	AmmoInClip = true,
	Clip = true,
	ClipAmmo = true,
	CurrentAmmo = true,
	ReserveAmmo = true,
	StoredAmmo = true,
}

local MAX_AMMO_NAMES = {
	MaxAmmo = true,
	MaxClip = true,
	ClipSize = true,
	MagazineSize = true,
}

local RELOAD_VALUE_NAMES = {
	ReloadTime = true,
	ReloadSpeed = true,
	ReloadDuration = true,
}

local function findMaxAmmo(tool)
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("NumberValue") or descendant:IsA("IntValue") then
			if MAX_AMMO_NAMES[descendant.Name] then
				return descendant.Value
			end
		end
	end
	return nil
end

local function applyAmmoSettings(tool)
	if not tool then
		return
	end

	local maxAmmo = findMaxAmmo(tool)
	for _, descendant in ipairs(tool:GetDescendants()) do
		if descendant:IsA("NumberValue") or descendant:IsA("IntValue") then
			if infiniteAmmoEnabled and AMMO_VALUE_NAMES[descendant.Name] then
				local targetValue = maxAmmo or descendant.Value
				descendant.Value = targetValue
			end

			if fastReloadEnabled and RELOAD_VALUE_NAMES[descendant.Name] then
				if ammoOriginals[descendant] == nil then
					ammoOriginals[descendant] = descendant.Value
				end
				descendant.Value = math.max(0.05, descendant.Value * 0.2)
			elseif not fastReloadEnabled and ammoOriginals[descendant] ~= nil then
				descendant.Value = ammoOriginals[descendant]
				ammoOriginals[descendant] = nil
			end
		end
	end
end

local function updateAmmoForCharacter(character)
	if not character then
		return
	end

	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") then
			applyAmmoSettings(item)
		end
	end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				applyAmmoSettings(item)
			end
		end
	end
end

local function setAmmoHelpersEnabled()
	if ammoConnection then
		ammoConnection:Disconnect()
		ammoConnection = nil
	end

	if not (infiniteAmmoEnabled or fastReloadEnabled) then
		for value, original in pairs(ammoOriginals) do
			if value and value.Parent then
				value.Value = original
			end
			ammoOriginals[value] = nil
		end
		return
	end

	ammoConnection = RunService.RenderStepped:Connect(function()
		local character = getCharacter()
		if character then
			updateAmmoForCharacter(character)
		end
	end)
end

local function applyHitbox(playerTarget)
	local part = getAimPart(playerTarget)
	if not part then
		return
	end

	if hitboxEnabled then
		if not hitboxOriginals[part] then
			hitboxOriginals[part] = {
				Size = part.Size,
				Transparency = part.Transparency,
			}
		end
		part.Size = part.Size * 1.6
		part.Transparency = math.max(part.Transparency, 0.35)
	else
		local original = hitboxOriginals[part]
		if original then
			part.Size = original.Size
			part.Transparency = original.Transparency
			hitboxOriginals[part] = nil
		end
	end
end

local function setHitboxEnabled()
	if hitboxConnection then
		hitboxConnection:Disconnect()
		hitboxConnection = nil
	end

	if not hitboxEnabled then
		for part, original in pairs(hitboxOriginals) do
			if part and part.Parent then
				part.Size = original.Size
				part.Transparency = original.Transparency
			end
			hitboxOriginals[part] = nil
		end
		return
	end

	hitboxConnection = RunService.RenderStepped:Connect(function()
		for _, other in ipairs(getCandidatePlayers()) do
			applyHitbox(other)
		end
	end)
end

local function ensureSilentAimHook()
	if silentAimHooked then
		return
	end

	if typeof(hookmetamethod) ~= "function" or typeof(getnamecallmethod) ~= "function" then
		return
	end

	silentAimHooked = true
	originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		local args = {...}

		if silentAimEnabled and method == "Raycast" and self == workspace then
			local origin = args[1]
			local direction = args[2]
			local rayParams = args[3]

			if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
				local target, _ = getNearestPlayer()
				local part = target and getAimPart(target)
				if part then
					if not wallbangEnabled and workspace and workspace.Raycast then
						local rayParams = RaycastParams.new()
						rayParams.FilterType = Enum.RaycastFilterType.Blacklist
						local character = getCharacter()
						if character then
							rayParams.FilterDescendantsInstances = {character}
						else
							rayParams.FilterDescendantsInstances = {}
						end
						local hit = workspace:Raycast(origin, part.Position - origin, rayParams)
						if hit and hit.Instance and not hit.Instance:IsDescendantOf(part.Parent) then
							return originalNamecall(self, ...)
						end
					end
					args[2] = part.Position - origin
					if wallbangEnabled and rayParams and typeof(rayParams) == "Instance" and rayParams:IsA("RaycastParams") then
						rayParams.FilterType = Enum.RaycastFilterType.Whitelist
						rayParams.FilterDescendantsInstances = {part.Parent}
					end
					return originalNamecall(self, table.unpack(args))
				end
			end
		end

		return originalNamecall(self, ...)
	end)
end

local screenGui = create("ScreenGui", {
	Name = "FancyMenu",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
})

screenGui.Parent = playerGui

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
	Text = getText("key_title"),
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
	Text = getText("key_subtitle"),
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
	PlaceholderText = getText("key_placeholder"),
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
	Text = getText("key_required"),
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
	Text = getText("key_unlock"),
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
	Text = getText("menu_title"),
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

local minimizeButton = create("TextButton", {
	Name = "Minimize",
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -70, 0.5, -14),
	BackgroundColor3 = theme.panel,
	Text = "–",
	Font = Enum.Font.GothamBold,
	TextColor3 = theme.muted,
	TextSize = 18,
	Parent = topBar,
})

create("UICorner", {
	CornerRadius = UDim.new(0, 8),
	Parent = minimizeButton,
})

local tabBar = create("ScrollingFrame", {
	Name = "TabBar",
	Size = UDim2.new(0, 160, 1, -48),
	Position = UDim2.new(0, 0, 0, 48),
	BackgroundColor3 = theme.panelDark,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = theme.stroke,
	CanvasSize = UDim2.new(0, 0, 0, 0),
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

tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	tabBar.CanvasSize = UDim2.new(0, 0, 0, tabList.AbsoluteContentSize.Y + 20)
end)

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

local fullSize = main.Size
local minimizedSize = UDim2.new(0, 520, 0, 48)

local function applyMinimizeState()
	if minimized then
		main.Size = minimizedSize
		tabBar.Visible = false
		content.Visible = false
		if hint then
			hint.Visible = false
		end
	else
		main.Size = fullSize
		tabBar.Visible = true
		content.Visible = true
		if hint then
			hint.Visible = true
		end
	end
end

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
	return section, titleLabel
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

local function createTab(key)
	local tabButton = create("TextButton", {
		BackgroundColor3 = theme.panel,
		Size = UDim2.new(1, 0, 0, 36),
		Font = Enum.Font.GothamSemibold,
		Text = getText("tab_" .. key),
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

	tabs[key] = tabButton
	pages[key] = page

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

local playerTabName = "player"
local worldTabName = "world"
local utilityTabName = "utility"
local pvpTabName = "pvp"
local settingsTabName = "settings"

local playerPage = createTab(playerTabName)
local worldPage = createTab(worldTabName)
local utilityPage = createTab(utilityTabName)
local pvpPage = createTab(pvpTabName)
local settingsPage = createTab(settingsTabName)

tabs[playerTabName].BackgroundColor3 = theme.accent
pages[playerTabName].Visible = true

-- Nhân vật section
local playerSection, playerSectionTitle = createSection(playerPage, getText("section_player"))
local playerLayout = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = playerSection,
})
playerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
playerLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local walkSpeedInput = createInput(playerSection, getText("walkspeed"))
local jumpPowerInput = createInput(playerSection, getText("jumppower"))
local applyPlayerButton = createButton(playerSection, getText("apply"))

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

local resetButton = createButton(playerSection, getText("reset"))
resetButton.MouseButton1Click:Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end
end)

-- Thế giới section
local worldSection, worldSectionTitle = createSection(worldPage, getText("section_world"))
local worldLayout = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = worldSection,
})
worldLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
worldLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local timeInput = createInput(worldSection, getText("time"))
local applyTimeButton = createButton(worldSection, getText("apply_time"))
applyTimeButton.MouseButton1Click:Connect(function()
	local value = tonumber(timeInput.Text)
	if value then
		Lighting.ClockTime = math.clamp(value, 0, 24)
	end
end)

setPvpStatus("status_idle")

local fullbright = false
local fullbrightButton = createButton(worldSection, getText("fullbright"))
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

-- Tiện ích section
local utilSection, utilSectionTitle = createSection(utilityPage, getText("section_utility"))
utilSection.Size = UDim2.new(1, -24, 0, 260)
local utilScroll = create("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 12, 0, 38),
	Size = UDim2.new(1, -24, 1, -48),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = theme.stroke,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = utilSection,
})
local utilLayout = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = utilScroll,
})
utilLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
utilLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local rejoinButton = createButton(utilScroll, getText("rejoin"))
rejoinButton.MouseButton1Click:Connect(function()
	TeleportService:Teleport(game.PlaceId, player)
end)

local copyPosButton = createButton(utilScroll, getText("copy_pos"))
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

local npcFlyToggle = createButton(utilScroll, getText("npc_fly_off"))
local npcTeleportButton = createButton(utilScroll, getText("npc_tele"))
local npcFlyUpButton = createButton(utilScroll, getText("npc_fly_up"))
local npcFlyDownButton = createButton(utilScroll, getText("npc_fly_down"))
local npcOrbitToggle = createButton(utilScroll, getText("npc_orbit_off"))
local npcHoverToggle = createButton(utilScroll, getText("npc_hover_off"))
local npcTuneSpeedUpButton = createButton(utilScroll, getText("npc_tune_speed_up"))
local npcTuneSpeedDownButton = createButton(utilScroll, getText("npc_tune_speed_down"))
local npcTuneHeightUpButton = createButton(utilScroll, getText("npc_tune_height_up"))
local npcTuneHeightDownButton = createButton(utilScroll, getText("npc_tune_height_down"))
local npcTuneDistanceUpButton = createButton(utilScroll, getText("npc_tune_distance_up"))
local npcTuneDistanceDownButton = createButton(utilScroll, getText("npc_tune_distance_down"))
local autoAttackToggle = createButton(utilScroll, getText("auto_attack_off"))
local autoBandageToggle = createButton(utilScroll, getText("auto_bandage_off"))
local autoCollectToggle = createButton(utilScroll, getText("auto_collect_off"))
local moveSpeedInput = createInput(utilScroll, getText("move_speed"))
local quickCollectRadiusInput = createInput(utilScroll, getText("quick_collect_radius"))
local applyCollectButton = createButton(utilScroll, getText("apply_collect"))
local vipUnlockToggle = createButton(utilScroll, getText("vip_unlock_off"))
local antiKickToggle = createButton(utilScroll, getText("antikick_off"))
local collectNearbyButton = createButton(utilScroll, getText("collect_nearby"))
local autoHealToggle = createButton(utilScroll, getText("auto_heal_off"))
local setHealSpotButton = createButton(utilScroll, getText("set_heal_spot"))
local createNpcWeaponButton = createButton(utilScroll, getText("create_npc_weapon"))
local npcShieldToggle = createButton(utilScroll, getText("npc_shield_off"))

npcFlyToggle.MouseButton1Click:Connect(function()
	if npcFlyMode == "under" then
		setNpcFlyMode("off")
	else
		setNpcFlyMode("under")
	end
	npcFlyToggle.Text = npcFlyMode == "under" and getText("npc_fly_on") or getText("npc_fly_off")
	npcOrbitToggle.Text = npcFlyMode == "orbit" and getText("npc_orbit_on") or getText("npc_orbit_off")
	npcHoverToggle.Text = npcFlyMode == "above" and getText("npc_hover_on") or getText("npc_hover_off")
end)

npcTeleportButton.MouseButton1Click:Connect(function()
	updateAntiKick(antiKickEnabled)
	local npcRoot = getNpcRoot()
	if not npcRoot then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = getNpcUndergroundCFrame(npcRoot)
	end
end)

npcFlyUpButton.MouseButton1Click:Connect(function()
	npcFlyOffset = math.min(npcFlyOffset + npcFlyOffsetStep, 50)
end)

npcFlyDownButton.MouseButton1Click:Connect(function()
	npcFlyOffset = math.max(npcFlyOffset - npcFlyOffsetStep, -200)
end)

npcOrbitToggle.MouseButton1Click:Connect(function()
	if npcFlyMode == "orbit" then
		setNpcFlyMode("off")
	else
		setNpcFlyMode("orbit")
	end
	npcFlyToggle.Text = npcFlyMode == "under" and getText("npc_fly_on") or getText("npc_fly_off")
	npcOrbitToggle.Text = npcFlyMode == "orbit" and getText("npc_orbit_on") or getText("npc_orbit_off")
	npcHoverToggle.Text = npcFlyMode == "above" and getText("npc_hover_on") or getText("npc_hover_off")
end)

npcHoverToggle.MouseButton1Click:Connect(function()
	if npcFlyMode == "above" then
		setNpcFlyMode("off")
	else
		setNpcFlyMode("above")
	end
	npcFlyToggle.Text = npcFlyMode == "under" and getText("npc_fly_on") or getText("npc_fly_off")
	npcOrbitToggle.Text = npcFlyMode == "orbit" and getText("npc_orbit_on") or getText("npc_orbit_off")
	npcHoverToggle.Text = npcFlyMode == "above" and getText("npc_hover_on") or getText("npc_hover_off")
end)

npcTuneSpeedUpButton.MouseButton1Click:Connect(function()
	npcOrbitSpeed = math.min(npcOrbitSpeed + npcTuneSpeedStep, 6)
end)

npcTuneSpeedDownButton.MouseButton1Click:Connect(function()
	npcOrbitSpeed = math.max(npcOrbitSpeed - npcTuneSpeedStep, 0.2)
end)

npcTuneHeightUpButton.MouseButton1Click:Connect(function()
	if npcFlyMode == "orbit" then
		npcOrbitHeight = math.min(npcOrbitHeight + npcTuneHeightStep, 50)
	elseif npcFlyMode == "above" then
		npcHoverOffset = math.min(npcHoverOffset + npcTuneHeightStep, 50)
	else
		npcFlyOffset = math.min(npcFlyOffset + npcTuneHeightStep, 50)
	end
end)

npcTuneHeightDownButton.MouseButton1Click:Connect(function()
	if npcFlyMode == "orbit" then
		npcOrbitHeight = math.max(npcOrbitHeight - npcTuneHeightStep, -50)
	elseif npcFlyMode == "above" then
		npcHoverOffset = math.max(npcHoverOffset - npcTuneHeightStep, 2)
	else
		npcFlyOffset = math.max(npcFlyOffset - npcTuneHeightStep, -200)
	end
end)

npcTuneDistanceUpButton.MouseButton1Click:Connect(function()
	npcOrbitRadius = math.min(npcOrbitRadius + npcTuneDistanceStep, 30)
end)

npcTuneDistanceDownButton.MouseButton1Click:Connect(function()
	npcOrbitRadius = math.max(npcOrbitRadius - npcTuneDistanceStep, 2)
end)

autoAttackToggle.MouseButton1Click:Connect(function()
	updateAutoAttack(not autoAttackEnabled)
	autoAttackToggle.Text = autoAttackEnabled and getText("auto_attack_on") or getText("auto_attack_off")
end)

autoBandageToggle.MouseButton1Click:Connect(function()
	updateAutoBandage(not autoBandageEnabled)
	autoBandageToggle.Text = autoBandageEnabled and getText("auto_bandage_on") or getText("auto_bandage_off")
end)

autoCollectToggle.MouseButton1Click:Connect(function()
	updateAutoCollect(not autoCollectEnabled)
	autoCollectToggle.Text = autoCollectEnabled and getText("auto_collect_on") or getText("auto_collect_off")
end)

applyCollectButton.MouseButton1Click:Connect(function()
	local moveSpeedValue = tonumber(moveSpeedInput.Text)
	if moveSpeedValue then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = math.clamp(moveSpeedValue, 1, 300)
		end
	end
	local radiusValue = tonumber(quickCollectRadiusInput.Text)
	if radiusValue then
		autoCollectRadius = math.clamp(radiusValue, 5, 120)
	end
end)

vipUnlockToggle.MouseButton1Click:Connect(function()
	vipUnlocked = not vipUnlocked
	vipUnlockToggle.Text = vipUnlocked and getText("vip_unlock_on") or getText("vip_unlock_off")
end)

antiKickToggle.MouseButton1Click:Connect(function()
	updateAntiKick(not antiKickEnabled)
	antiKickToggle.Text = antiKickEnabled and getText("antikick_on") or getText("antikick_off")
end)

collectNearbyButton.MouseButton1Click:Connect(function()
	collectNearbyItems()
end)

autoHealToggle.MouseButton1Click:Connect(function()
	updateAutoHeal(not autoHealEnabled)
	autoHealToggle.Text = autoHealEnabled and getText("auto_heal_on") or getText("auto_heal_off")
end)

setHealSpotButton.MouseButton1Click:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		autoHealTargetCFrame = root.CFrame
	end
end)

createNpcWeaponButton.MouseButton1Click:Connect(function()
	local weapon = createNpcWeapon()
	if weapon then
		createNpcWeaponButton.Text = getText("npc_weapon_created")
		task.delay(1.5, function()
			if createNpcWeaponButton and createNpcWeaponButton.Parent then
				createNpcWeaponButton.Text = getText("create_npc_weapon")
			end
		end)
	end
end)

npcShieldToggle.MouseButton1Click:Connect(function()
	updateNpcShield(not npcShieldEnabled)
	npcShieldToggle.Text = npcShieldEnabled and getText("npc_shield_on") or getText("npc_shield_off")
end)

-- PVP section (UI only)
local pvpSection, pvpSectionTitle = createSection(pvpPage, getText("section_pvp"))
pvpSection.Size = UDim2.new(1, -24, 0, 250)

local pvpStatus = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 20),
	Position = UDim2.new(0, 12, 0, 32),
	Font = Enum.Font.Gotham,
	Text = getText("status_idle"),
	TextSize = 12,
	TextColor3 = theme.muted,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = pvpSection,
})

setPvpStatus("status_idle")

local pvpBody = Instance.new("ScrollingFrame")
pvpBody.BackgroundTransparency = 1
pvpBody.BorderSizePixel = 0
pvpBody.ScrollBarThickness = 4
pvpBody.ScrollBarImageColor3 = theme.stroke
pvpBody.Position = UDim2.new(0, 12, 0, 58)
pvpBody.Size = UDim2.new(1, -24, 1, -66)
pvpBody.CanvasSize = UDim2.new(0, 0, 0, 0)
pvpBody.Parent = pvpSection

local pvpLayout = create("UIGridLayout", {
	CellSize = UDim2.new(0, 150, 0, 30),
	CellPadding = UDim2.new(0, 6, 0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = pvpBody,
})
pvpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
pvpLayout.VerticalAlignment = Enum.VerticalAlignment.Top

pvpLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	pvpBody.CanvasSize = UDim2.new(0, 0, 0, pvpLayout.AbsoluteContentSize.Y + 6)
end)

local aimToggle = createButton(pvpBody, getText("auto_off"))

local locatorToggle = createButton(pvpBody, getText("locator_off"))

local teamToggle = createButton(pvpBody, getText("ignore_team_on"))

local wallbangToggle = createButton(pvpBody, getText("wallbang_off"))

local infiniteAmmoToggle = createButton(pvpBody, getText("infinite_off"))

local fastReloadToggle = createButton(pvpBody, getText("reload_off"))

local silentAimToggle = createButton(pvpBody, getText("headmagnet_off"))

local aimPartToggle = createButton(pvpBody, string.format(getText("aim_part"), getAimPartLabel()))

local hitboxToggle = createButton(pvpBody, getText("hitbox_off"))

local pingButton = createButton(pvpBody, getText("ping"))

-- Settings section
local settingsSection, settingsSectionTitle = createSection(settingsPage, getText("section_settings"))
settingsSection.Size = UDim2.new(1, -24, 0, 180)
local settingsLayout = create("UIListLayout", {
	Padding = UDim.new(0, 8),
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = settingsSection,
})
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local saveSettingsButton = createButton(settingsSection, getText("save_settings"))
local clearSettingsButton = createButton(settingsSection, getText("clear_settings"))
local languageToggleButton = createButton(settingsSection, getText("language_toggle"))

local settingsStatus = create("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -24, 0, 20),
	Font = Enum.Font.Gotham,
	Text = "",
	TextSize = 12,
	TextColor3 = theme.muted,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = settingsSection,
})

local function applyLanguage()
	keyTitle.Text = getText("key_title")
	keySubtitle.Text = getText("key_subtitle")
	keyInput.PlaceholderText = getText("key_placeholder")
	keyButton.Text = getText("key_unlock")
	if keyGate.Visible then
		keyStatus.Text = getText("key_required")
	end

	title.Text = getText("menu_title")
	hint.Text = getText("hint")

	tabs[playerTabName].Text = getText("tab_player")
	tabs[worldTabName].Text = getText("tab_world")
	tabs[utilityTabName].Text = getText("tab_utility")
	tabs[pvpTabName].Text = getText("tab_pvp")
	tabs[settingsTabName].Text = getText("tab_settings")

	playerSectionTitle.Text = getText("section_player")
	worldSectionTitle.Text = getText("section_world")
	utilSectionTitle.Text = getText("section_utility")
	pvpSectionTitle.Text = getText("section_pvp")
	settingsSectionTitle.Text = getText("section_settings")

	walkSpeedInput.PlaceholderText = getText("walkspeed")
	jumpPowerInput.PlaceholderText = getText("jumppower")
	applyPlayerButton.Text = getText("apply")
	resetButton.Text = getText("reset")
	timeInput.PlaceholderText = getText("time")
	applyTimeButton.Text = getText("apply_time")
	fullbrightButton.Text = getText("fullbright")
	rejoinButton.Text = getText("rejoin")
	copyPosButton.Text = getText("copy_pos")
	npcFlyToggle.Text = npcFlyMode == "under" and getText("npc_fly_on") or getText("npc_fly_off")
	npcTeleportButton.Text = getText("npc_tele")
	npcFlyUpButton.Text = getText("npc_fly_up")
	npcFlyDownButton.Text = getText("npc_fly_down")
	npcOrbitToggle.Text = npcFlyMode == "orbit" and getText("npc_orbit_on") or getText("npc_orbit_off")
	npcHoverToggle.Text = npcFlyMode == "above" and getText("npc_hover_on") or getText("npc_hover_off")
	npcTuneSpeedUpButton.Text = getText("npc_tune_speed_up")
	npcTuneSpeedDownButton.Text = getText("npc_tune_speed_down")
	npcTuneHeightUpButton.Text = getText("npc_tune_height_up")
	npcTuneHeightDownButton.Text = getText("npc_tune_height_down")
	npcTuneDistanceUpButton.Text = getText("npc_tune_distance_up")
	npcTuneDistanceDownButton.Text = getText("npc_tune_distance_down")
	autoAttackToggle.Text = autoAttackEnabled and getText("auto_attack_on") or getText("auto_attack_off")
	autoBandageToggle.Text = autoBandageEnabled and getText("auto_bandage_on") or getText("auto_bandage_off")
	autoCollectToggle.Text = autoCollectEnabled and getText("auto_collect_on") or getText("auto_collect_off")
	moveSpeedInput.PlaceholderText = getText("move_speed")
	quickCollectRadiusInput.PlaceholderText = getText("quick_collect_radius")
	applyCollectButton.Text = getText("apply_collect")
	vipUnlockToggle.Text = vipUnlocked and getText("vip_unlock_on") or getText("vip_unlock_off")
	antiKickToggle.Text = antiKickEnabled and getText("antikick_on") or getText("antikick_off")
	collectNearbyButton.Text = getText("collect_nearby")
	autoHealToggle.Text = autoHealEnabled and getText("auto_heal_on") or getText("auto_heal_off")
	setHealSpotButton.Text = getText("set_heal_spot")
	createNpcWeaponButton.Text = getText("create_npc_weapon")
	npcShieldToggle.Text = npcShieldEnabled and getText("npc_shield_on") or getText("npc_shield_off")

	aimToggle.Text = autoAimEnabled and getText("auto_on") or getText("auto_off")
	locatorToggle.Text = locatorEnabled and getText("locator_on") or getText("locator_off")
	teamToggle.Text = ignoreTeamEnabled and getText("ignore_team_on") or getText("ignore_team_off")
	wallbangToggle.Text = wallbangEnabled and getText("wallbang_on") or getText("wallbang_off")
	infiniteAmmoToggle.Text = infiniteAmmoEnabled and getText("infinite_on") or getText("infinite_off")
	fastReloadToggle.Text = fastReloadEnabled and getText("reload_on") or getText("reload_off")
	silentAimToggle.Text = silentAimEnabled and getText("headmagnet_on") or getText("headmagnet_off")
	aimPartToggle.Text = string.format(getText("aim_part"), getAimPartLabel())
	hitboxToggle.Text = hitboxEnabled and getText("hitbox_on") or getText("hitbox_off")
	pingButton.Text = getText("ping")

	saveSettingsButton.Text = getText("save_settings")
	clearSettingsButton.Text = getText("clear_settings")
	languageToggleButton.Text = getText("language_toggle")

	setPvpStatus(currentStatusKey, table.unpack(currentStatusArgs))
end

local function saveConfig()
	_G[configKey] = {
		language = currentLanguage,
		autoAimEnabled = autoAimEnabled,
		locatorEnabled = locatorEnabled,
		ignoreTeamEnabled = ignoreTeamEnabled,
		wallbangEnabled = wallbangEnabled,
		infiniteAmmoEnabled = infiniteAmmoEnabled,
		fastReloadEnabled = fastReloadEnabled,
		silentAimEnabled = silentAimEnabled,
		aimPartIndex = aimPartIndex,
		hitboxEnabled = hitboxEnabled,
	}
	settingsStatus.Text = getText("settings_saved")
end

local function clearConfig()
	_G[configKey] = nil
	settingsStatus.Text = getText("settings_cleared")
end

saveSettingsButton.MouseButton1Click:Connect(saveConfig)
clearSettingsButton.MouseButton1Click:Connect(clearConfig)
languageToggleButton.MouseButton1Click:Connect(function()
	currentLanguage = currentLanguage == "vi" and "en" or "vi"
	applyLanguage()
end)

aimToggle.MouseButton1Click:Connect(function()
	autoAimEnabled = not autoAimEnabled
	if autoAimEnabled then
		aimToggle.Text = getText("auto_on")
	else
		aimToggle.Text = getText("auto_off")
	end
	setAutoAim(autoAimEnabled, pvpStatus)
end)

locatorToggle.MouseButton1Click:Connect(function()
	locatorEnabled = not locatorEnabled
	if locatorEnabled then
		locatorToggle.Text = getText("locator_on")
	else
		locatorToggle.Text = getText("locator_off")
	end
	setLocatorEnabled(locatorEnabled, pvpStatus)
end)

teamToggle.MouseButton1Click:Connect(function()
	ignoreTeamEnabled = not ignoreTeamEnabled
	if ignoreTeamEnabled then
		teamToggle.Text = getText("ignore_team_on")
	else
		teamToggle.Text = getText("ignore_team_off")
	end
end)

wallbangToggle.MouseButton1Click:Connect(function()
	wallbangEnabled = not wallbangEnabled
	if wallbangEnabled then
		wallbangToggle.Text = getText("wallbang_on")
	else
		wallbangToggle.Text = getText("wallbang_off")
	end
	if autoAimEnabled then
		setAutoAim(true, pvpStatus)
	end
end)

infiniteAmmoToggle.MouseButton1Click:Connect(function()
	infiniteAmmoEnabled = not infiniteAmmoEnabled
	if infiniteAmmoEnabled then
		infiniteAmmoToggle.Text = getText("infinite_on")
	else
		infiniteAmmoToggle.Text = getText("infinite_off")
	end
	setAmmoHelpersEnabled()
end)

fastReloadToggle.MouseButton1Click:Connect(function()
	fastReloadEnabled = not fastReloadEnabled
	if fastReloadEnabled then
		fastReloadToggle.Text = getText("reload_on")
	else
		fastReloadToggle.Text = getText("reload_off")
	end
	setAmmoHelpersEnabled()
end)

silentAimToggle.MouseButton1Click:Connect(function()
	silentAimEnabled = not silentAimEnabled
	if silentAimEnabled then
		silentAimToggle.Text = getText("headmagnet_on")
		ensureSilentAimHook()
		setPvpStatus("status_headmagnet_on")
	else
		silentAimToggle.Text = getText("headmagnet_off")
		setPvpStatus("status_headmagnet_off")
	end
end)

aimPartToggle.MouseButton1Click:Connect(function()
	aimPartIndex = aimPartIndex + 1
	if aimPartIndex > #aimParts then
		aimPartIndex = 1
	end
	aimPartToggle.Text = string.format(getText("aim_part"), getAimPartLabel())
end)

hitboxToggle.MouseButton1Click:Connect(function()
	hitboxEnabled = not hitboxEnabled
	if hitboxEnabled then
		hitboxToggle.Text = getText("hitbox_on")
	else
		hitboxToggle.Text = getText("hitbox_off")
	end
	setHitboxEnabled()
end)

pingButton.MouseButton1Click:Connect(function()
	local target, distanceOrError = getNearestPlayer()
	if not target then
		if distanceOrError then
			pvpStatus.Text = distanceOrError
		else
			setPvpStatus("status_locate_fail")
		end
		return
	end

	local head = getHeadPart(target)
	if not head then
		setPvpStatus("status_target_fail")
		return
	end

	setPvpStatus("status_nearest", target.Name, distanceOrError)
	if setclipboard then
		setclipboard(string.format("CFrame.new(%.2f, %.2f, %.2f)", head.Position.X, head.Position.Y, head.Position.Z))
	end
end)

local function setVisible(state)
	if state then
		main.Position = UDim2.new(0.5, -260, 0.5, -170)
	end
	main.Visible = state
	if state then
		applyMinimizeState()
	end
end

applySavedConfig()

closeButton.MouseButton1Click:Connect(function()
	setVisible(false)
end)

minimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	applyMinimizeState()
end)

keyButton.MouseButton1Click:Connect(function()
	if keyInput.Text == accessKey then
		keyStatus.Text = getText("key_success")
		keyStatus.TextColor3 = Color3.fromRGB(134, 239, 172)
		main.Visible = true
		keyGate.Visible = false
	else
		keyStatus.Text = getText("key_invalid")
		keyStatus.TextColor3 = Color3.fromRGB(248, 113, 113)
	end
end)

if not requireKey then
	keyGate.Visible = false
	setVisible(true)
end

applyLanguage()
if autoAimEnabled then
	setAutoAim(true, pvpStatus)
end
if locatorEnabled then
	setLocatorEnabled(true, pvpStatus)
end
if infiniteAmmoEnabled or fastReloadEnabled then
	setAmmoHelpersEnabled()
end
if silentAimEnabled then
	ensureSilentAimHook()
end
if hitboxEnabled then
	setHitboxEnabled()
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

player.CharacterAdded:Connect(function()
	if infiniteAmmoEnabled or fastReloadEnabled then
		setAmmoHelpersEnabled()
	end
end)

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
	Text = getText("hint"),
	TextSize = 11,
	TextColor3 = theme.muted,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = main,
})

applyMinimizeState()

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
