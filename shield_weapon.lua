--[[
	Ultimate Shield + Weapon Script (Roblox)
	- Vòng lá chắn thật (có collision) để chặn quái áp sát
	- Lá chắn gây sát thương + hất lùi quái
	- Vũ khí đẹp hơn, đánh ổn định, ưu tiên hạ quái nhanh
	- Luôn mở khóa camera + zoom out

	Lưu ý:
	- Trong game FilteringEnabled mạnh, việc kill NPC từ client có thể bị hạn chế bởi server.
	- Script đã thêm nhiều cơ chế gây damage/kill để tăng tỉ lệ hoạt động.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local localPlayer = Players.LocalPlayer
if not localPlayer then
	error("Không tìm thấy LocalPlayer")
end

-- Shield config
local SHIELD_ORBS = 10
local SHIELD_RADIUS = 6.5
local SHIELD_HEIGHT = 2.5
local SHIELD_DAMAGE = 65
local SHIELD_HIT_COOLDOWN = 0.2
local SHIELD_SCAN_RADIUS = 10
local SHIELD_PUSH_DISTANCE = 8
local SHIELD_PUSH_FORCE = 130
local SHIELD_WALL_SEGMENTS = 14

-- Weapon config
local WEAPON_NAME = "Abyss Reaver"
local WEAPON_RANGE = 32
local WEAPON_COOLDOWN = 0.2
local WEAPON_DAMAGE = 2500

local shieldModel
local shieldConnection
local cameraConnection
local weaponCooldown = false
local lastShieldHit = {}

local function getCharacter()
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	return character, humanoid, root
end

local function isMonster(model)
	if not model or not model:IsA("Model") then
		return false
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	return Players:GetPlayerFromCharacter(model) == nil
end

local function getMonsterRoot(model)
	if not model then
		return nil
	end
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local function hardKillHumanoid(humanoid)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	pcall(function()
		humanoid:TakeDamage(WEAPON_DAMAGE)
	end)

	pcall(function()
		humanoid.Health = 0
	end)

	pcall(function()
		if humanoid.Parent then
			humanoid.Parent:BreakJoints()
		end
	end)
end

local function damageHumanoid(humanoid, amount)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	pcall(function()
		humanoid:TakeDamage(amount)
	end)
end

local function enforceCameraUnlock()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	cameraConnection = RunService.RenderStepped:Connect(function()
		localPlayer.CameraMode = Enum.CameraMode.Classic
		localPlayer.CameraMinZoomDistance = 0.5
		localPlayer.CameraMaxZoomDistance = 200

		local cam = workspace.CurrentCamera
		if cam then
			cam.CameraType = Enum.CameraType.Custom
		end
	end)
end

local function repelMonster(monsterModel, playerRoot)
	local monsterRoot = getMonsterRoot(monsterModel)
	if not monsterRoot or not playerRoot then
		return
	end

	local offset = monsterRoot.Position - playerRoot.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude < 0.01 then
		flat = playerRoot.CFrame.LookVector
	end

	local direction = flat.Unit
	local currentDistance = flat.Magnitude

	if currentDistance < SHIELD_PUSH_DISTANCE then
		local newPosition = playerRoot.Position + direction * SHIELD_PUSH_DISTANCE + Vector3.new(0, 2, 0)
		pcall(function()
			monsterRoot.CFrame = CFrame.new(newPosition, newPosition + direction)
		end)
	end

	pcall(function()
		monsterRoot.AssemblyLinearVelocity = direction * SHIELD_PUSH_FORCE + Vector3.new(0, 12, 0)
	end)
end

local function makeOrb(index)
	local part = Instance.new("Part")
	part.Name = "ShieldOrb_" .. index
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1.1, 1.1, 1.1)
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(0, 190, 255)
	part.Transparency = 0.1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function makeWallSegment(index)
	local wall = Instance.new("Part")
	wall.Name = "ShieldWall_" .. index
	wall.Size = Vector3.new(2.2, 5, 1)
	wall.Material = Enum.Material.ForceField
	wall.Color = Color3.fromRGB(80, 200, 255)
	wall.Transparency = 0.4
	wall.Anchored = true
	wall.CanCollide = true
	wall.CanTouch = false
	wall.CanQuery = false
	wall.TopSurface = Enum.SurfaceType.Smooth
	wall.BottomSurface = Enum.SurfaceType.Smooth
	return wall
end

local function clearShield()
	if shieldConnection then
		shieldConnection:Disconnect()
		shieldConnection = nil
	end

	if shieldModel then
		shieldModel:Destroy()
		shieldModel = nil
	end

	table.clear(lastShieldHit)
end

local function createShield()
	clearShield()

	local character, humanoid, root = getCharacter()

	shieldModel = Instance.new("Model")
	shieldModel.Name = "ProtectionShield"
	shieldModel.Parent = workspace

	local orbs = {}
	for i = 1, SHIELD_ORBS do
		local orb = makeOrb(i)
		orb.Parent = shieldModel
		table.insert(orbs, orb)
	end

	local walls = {}
	for i = 1, SHIELD_WALL_SEGMENTS do
		local wall = makeWallSegment(i)
		wall.Parent = shieldModel
		table.insert(walls, wall)
	end

	shieldConnection = RunService.Heartbeat:Connect(function()
		if not character.Parent or humanoid.Health <= 0 then
			return
		end

		local now = os.clock()
		local spin = now * 1.8

		for i, orb in ipairs(orbs) do
			local angle = spin + ((2 * math.pi / SHIELD_ORBS) * (i - 1))
			local offset = Vector3.new(
				math.cos(angle) * SHIELD_RADIUS,
				SHIELD_HEIGHT + math.sin(spin * 1.2 + i) * 0.45,
				math.sin(angle) * SHIELD_RADIUS
			)
			orb.CFrame = root.CFrame + offset
		end

		for i, wall in ipairs(walls) do
			local angle = spin * 0.55 + ((2 * math.pi / SHIELD_WALL_SEGMENTS) * (i - 1))
			local center = root.Position + Vector3.new(math.cos(angle) * (SHIELD_RADIUS - 0.8), 1.8, math.sin(angle) * (SHIELD_RADIUS - 0.8))
			local look = root.Position + Vector3.new(math.cos(angle), 0, math.sin(angle))
			wall.CFrame = CFrame.lookAt(center, look)
		end

		for _, obj in ipairs(workspace:GetPartBoundsInRadius(root.Position, SHIELD_SCAN_RADIUS)) do
			local model = obj:FindFirstAncestorOfClass("Model")
			if isMonster(model) then
				local enemyHumanoid = model:FindFirstChildOfClass("Humanoid")
				if enemyHumanoid then
					local last = lastShieldHit[enemyHumanoid] or 0
					if now - last >= SHIELD_HIT_COOLDOWN then
						lastShieldHit[enemyHumanoid] = now
						damageHumanoid(enemyHumanoid, SHIELD_DAMAGE)
					end
					repelMonster(model, root)
				end
			end
		end
	end)
end

local function findNearestMonster(rootPosition, range)
	local nearestHumanoid
	local nearestRoot
	local nearestDistance = range

	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("Humanoid") and item.Health > 0 then
			local model = item.Parent
			if isMonster(model) then
				local mr = getMonsterRoot(model)
				if mr then
					local distance = (mr.Position - rootPosition).Magnitude
					if distance <= nearestDistance then
						nearestDistance = distance
						nearestHumanoid = item
						nearestRoot = mr
					end
				end
			end
		end
	end

	return nearestHumanoid, nearestRoot, nearestDistance
end

local function makeWeaponVisual(tool)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 4, 0.45)
	handle.Material = Enum.Material.Metal
	handle.Color = Color3.fromRGB(32, 32, 38)
	handle.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(3.2, 0.35, 0.9)
	guard.Material = Enum.Material.Metal
	guard.Color = Color3.fromRGB(10, 10, 15)
	guard.Massless = true
	guard.CanCollide = false
	guard.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.35, 6.4, 1.2)
	blade.Material = Enum.Material.Neon
	blade.Color = Color3.fromRGB(0, 220, 255)
	blade.Massless = true
	blade.CanCollide = false
	blade.Parent = tool

	local bladeMesh = Instance.new("SpecialMesh")
	bladeMesh.MeshType = Enum.MeshType.Wedge
	bladeMesh.Scale = Vector3.new(0.7, 1, 1)
	bladeMesh.Parent = blade

	local aura = Instance.new("PointLight")
	aura.Color = Color3.fromRGB(0, 220, 255)
	aura.Brightness = 2.2
	aura.Range = 10
	aura.Parent = blade

	local weldGuard = Instance.new("WeldConstraint")
	weldGuard.Part0 = handle
	weldGuard.Part1 = guard
	weldGuard.Parent = handle

	local weldBlade = Instance.new("WeldConstraint")
	weldBlade.Part0 = handle
	weldBlade.Part1 = blade
	weldBlade.Parent = handle

	guard.CFrame = handle.CFrame * CFrame.new(0, 1.6, 0)
	blade.CFrame = handle.CFrame * CFrame.new(0, 4.5, 0)
end

local function createHitBeam(fromPos, toPos)
	local dist = (toPos - fromPos).Magnitude
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanTouch = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(255, 70, 140)
	beam.Size = Vector3.new(0.35, 0.35, math.max(0.5, dist))
	beam.CFrame = CFrame.lookAt(fromPos, toPos) * CFrame.new(0, 0, -dist / 2)
	beam.Parent = workspace
	Debris:AddItem(beam, 0.08)
end

local function createWeapon()
	local backpack = localPlayer:WaitForChild("Backpack")
	local character = localPlayer.Character

	for _, place in ipairs({backpack, character}) do
		if place then
			local old = place:FindFirstChild(WEAPON_NAME)
			if old and old:IsA("Tool") then
				old:Destroy()
			end
		end
	end

	local tool = Instance.new("Tool")
	tool.Name = WEAPON_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	makeWeaponVisual(tool)

	tool.Activated:Connect(function()
		if weaponCooldown then
			return
		end
		weaponCooldown = true

		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local targetHumanoid, targetRoot = findNearestMonster(root.Position, WEAPON_RANGE)
			if targetHumanoid and targetRoot then
				hardKillHumanoid(targetHumanoid)
				createHitBeam(root.Position, targetRoot.Position)
			end
		end

		task.delay(WEAPON_COOLDOWN, function()
			weaponCooldown = false
		end)
	end)

	tool.Parent = backpack
end

local function setupForCharacter()
	enforceCameraUnlock()
	createShield()
	createWeapon()
end

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.2)
	setupForCharacter()
end)

if localPlayer.Character then
	setupForCharacter()
end

print("[ShieldWeapon] Ready: shield block + knockback, pretty weapon, camera unlock.")
