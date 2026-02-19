--[[
	Abyss Guardian (Roblox LocalScript)
	- Vũ khí đẹp + hiệu ứng mạnh, đánh theo chạm + quét mục tiêu gần
	- Lá chắn thật bám người chơi để chặn quái + đẩy lùi liên tục
	- Camera zoom bình thường (luôn thấy nhân vật ở góc nhìn thứ 3)

	Lưu ý: Trong game FE nghiêm ngặt, server có thể chặn sát thương client.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then
	error("LocalPlayer not found")
end

-- Shield config
local SHIELD_RADIUS = 7
local SHIELD_HEIGHT = 6
local SHIELD_DAMAGE = 60
local SHIELD_COOLDOWN = 0.15
local SHIELD_REPEL_FORCE = 145
local SHIELD_MIN_DISTANCE = 8
local SHIELD_SCAN_RADIUS = 11

-- Weapon config
local WEAPON_NAME = "Abyss Reaver Ω"
local WEAPON_DAMAGE = 1e6
local WEAPON_RANGE = 38
local WEAPON_COOLDOWN = 0.16

local shieldModel
local shieldLoop
local weaponCooldown = false
local shieldHitTime = {}

local function getCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	return char, humanoid, root
end

local function isMonster(model)
	if not model or not model:IsA("Model") then
		return false
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end
	return Players:GetPlayerFromCharacter(model) == nil
end

local function monsterRoot(model)
	if not model then
		return nil
	end
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local function killHumanoid(humanoid)
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	pcall(function() humanoid:TakeDamage(WEAPON_DAMAGE) end)
	pcall(function() humanoid.Health = 0 end)
	pcall(function() if humanoid.Parent then humanoid.Parent:BreakJoints() end end)
end

local function damageHumanoid(humanoid, amount)
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	pcall(function() humanoid:TakeDamage(amount) end)
end

local function normalCameraMode()
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = 10
	player.CameraMaxZoomDistance = 90

	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function createPulse(position, color)
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.2, 2.5, 2.5)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace

	local tween = TweenService:Create(ring, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, 14, 14),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(ring, 0.3)
end

local function repelMonster(model, root)
	local mr = monsterRoot(model)
	if not mr then
		return
	end

	local offset = mr.Position - root.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude < 0.01 then
		flat = root.CFrame.LookVector
	end
	local dir = flat.Unit

	if flat.Magnitude < SHIELD_MIN_DISTANCE then
		local newPos = root.Position + dir * SHIELD_MIN_DISTANCE + Vector3.new(0, 2, 0)
		pcall(function() mr.CFrame = CFrame.new(newPos, newPos + dir) end)
	end

	pcall(function()
		mr.AssemblyLinearVelocity = dir * SHIELD_REPEL_FORCE + Vector3.new(0, 12, 0)
	end)
end

local function clearShield()
	if shieldLoop then
		shieldLoop:Disconnect()
		shieldLoop = nil
	end
	if shieldModel then
		shieldModel:Destroy()
		shieldModel = nil
	end
	table.clear(shieldHitTime)
end

local function createShield()
	clearShield()
	local char, hum, root = getCharacter()

	shieldModel = Instance.new("Model")
	shieldModel.Name = "AbyssGuardianShield"
	shieldModel.Parent = char

	-- Barrier bám theo người chơi (không collision để tránh lỗi văng/lọt map)
	local barrier = Instance.new("Part")
	barrier.Name = "Barrier"
	barrier.Shape = Enum.PartType.Cylinder
	barrier.Size = Vector3.new(0.7, SHIELD_RADIUS * 2, SHIELD_RADIUS * 2)
	barrier.Material = Enum.Material.ForceField
	barrier.Color = Color3.fromRGB(95, 220, 255)
	barrier.Transparency = 0.35
	barrier.CanCollide = false
	barrier.CanTouch = false
	barrier.CanQuery = false
	barrier.Massless = true
	barrier.Parent = shieldModel

	local barrierWeld = Instance.new("WeldConstraint")
	barrierWeld.Part0 = root
	barrierWeld.Part1 = barrier
	barrierWeld.Parent = barrier
	barrier.CFrame = root.CFrame * CFrame.new(0, SHIELD_HEIGHT * 0.5 - 1, 0) * CFrame.Angles(0, 0, math.rad(90))

	local barrierLight = Instance.new("PointLight")
	barrierLight.Color = Color3.fromRGB(90, 220, 255)
	barrierLight.Brightness = 1.8
	barrierLight.Range = SHIELD_RADIUS * 2.3
	barrierLight.Parent = barrier

	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxassetid://243098098"
	particles.Color = ColorSequence.new(Color3.fromRGB(150, 245, 255), Color3.fromRGB(30, 150, 255))
	particles.Rate = 90
	particles.Speed = NumberRange.new(0.6, 1.6)
	particles.Lifetime = NumberRange.new(0.3, 0.7)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Parent = barrier

	shieldLoop = RunService.Heartbeat:Connect(function()
		if not char.Parent or hum.Health <= 0 then
			return
		end

		for _, part in ipairs(workspace:GetPartBoundsInRadius(root.Position, SHIELD_SCAN_RADIUS)) do
			local model = part:FindFirstAncestorOfClass("Model")
			if isMonster(model) then
				local enemyHum = model:FindFirstChildOfClass("Humanoid")
				if enemyHum then
					local now = os.clock()
					local last = shieldHitTime[enemyHum] or 0
					if now - last >= SHIELD_COOLDOWN then
						shieldHitTime[enemyHum] = now
						damageHumanoid(enemyHum, SHIELD_DAMAGE)
					end
					repelMonster(model, root)
				end
			end
		end
	end)
end

local function findNearestTarget(origin)
	local nearestHumanoid
	local nearestRoot
	local nearestDistance = WEAPON_RANGE

	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Humanoid") and inst.Health > 0 then
			local model = inst.Parent
			if isMonster(model) then
				local r = monsterRoot(model)
				if r then
					local d = (r.Position - origin).Magnitude
					if d <= nearestDistance then
						nearestDistance = d
						nearestHumanoid = inst
						nearestRoot = r
					end
				end
			end
		end
	end

	return nearestHumanoid, nearestRoot, nearestDistance
end

local function styleWeapon(tool)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 4.2, 0.5)
	handle.Material = Enum.Material.Metal
	handle.Color = Color3.fromRGB(20, 20, 28)
	handle.Parent = tool

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(3.8, 0.36, 1)
	guard.Material = Enum.Material.Metal
	guard.Color = Color3.fromRGB(8, 8, 12)
	guard.CanCollide = false
	guard.Massless = true
	guard.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.32, 7.3, 1.4)
	blade.Material = Enum.Material.Neon
	blade.Color = Color3.fromRGB(0, 240, 255)
	blade.CanCollide = false
	blade.Massless = true
	blade.Parent = tool

	local bladeMesh = Instance.new("SpecialMesh")
	bladeMesh.MeshType = Enum.MeshType.Wedge
	bladeMesh.Scale = Vector3.new(0.7, 1, 1)
	bladeMesh.Parent = blade

	local aura = Instance.new("PointLight")
	aura.Color = Color3.fromRGB(0, 240, 255)
	aura.Brightness = 3
	aura.Range = 14
	aura.Parent = blade

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 2.8, 0)
	a0.Parent = blade
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -2.8, 0)
	a1.Parent = blade

	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 80, 175), Color3.fromRGB(0, 240, 255))
	trail.Lifetime = 0.18
	trail.MinLength = 0
	trail.Parent = blade

	for _, pair in ipairs({{handle, guard, CFrame.new(0, 1.75, 0)}, {handle, blade, CFrame.new(0, 4.8, 0)}}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = pair[1]
		weld.Part1 = pair[2]
		weld.Parent = handle
		pair[2].CFrame = handle.CFrame * pair[3]
	end

	return handle
end

local function createSlashEffect(fromPos, toPos)
	local distance = (toPos - fromPos).Magnitude
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanTouch = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(255, 90, 160)
	beam.Size = Vector3.new(0.45, 0.45, math.max(1, distance))
	beam.CFrame = CFrame.lookAt(fromPos, toPos) * CFrame.new(0, 0, -distance * 0.5)
	beam.Parent = workspace
	Debris:AddItem(beam, 0.08)

	createPulse(toPos, Color3.fromRGB(0, 230, 255))
end

local function createWeapon()
	local backpack = player:WaitForChild("Backpack")
	local char = player.Character

	for _, parent in ipairs({backpack, char}) do
		if parent then
			local old = parent:FindFirstChild(WEAPON_NAME)
			if old and old:IsA("Tool") then
				old:Destroy()
			end
		end
	end

	local tool = Instance.new("Tool")
	tool.Name = WEAPON_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = styleWeapon(tool)

	-- Đánh khi va chạm
	handle.Touched:Connect(function(hit)
		local model = hit and hit:FindFirstAncestorOfClass("Model")
		if isMonster(model) then
			local hum = model:FindFirstChildOfClass("Humanoid")
			killHumanoid(hum)
		end
	end)

	-- Đánh theo kích hoạt (không cần chạm vẫn hit trong tầm)
	tool.Activated:Connect(function()
		if weaponCooldown then
			return
		end
		weaponCooldown = true

		local c = player.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if root then
			local targetHum, targetRoot = findNearestTarget(root.Position)
			if targetHum and targetRoot then
				killHumanoid(targetHum)
				createSlashEffect(root.Position, targetRoot.Position)
			end
		end

		task.delay(WEAPON_COOLDOWN, function()
			weaponCooldown = false
		end)
	end)

	tool.Parent = backpack
end

local function setup()
	normalCameraMode()
	createShield()
	createWeapon()
end

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	setup()
end)

if player.Character then
	setup()
end

print("[Abyss Guardian] Weapon + Shield + Camera ready.")
