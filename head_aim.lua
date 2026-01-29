--[[
	Head Aim utility
	Provides a simple function to aim a camera or return a look CFrame toward a target's head.
]]

local HeadAim = {}

local DEFAULT_ENEMY_OPTIONS = {
	PreferClosest = true,
	RaycastParams = nil,
}

local function resolveCharacter(target)
	if typeof(target) ~= "Instance" then
		return nil
	end

	if target:IsA("Player") then
		return target.Character
	end

	if target:IsA("Model") then
		return target
	end

	if target:IsA("BasePart") then
		return target.Parent
	end

	return nil
end

function HeadAim.getHead(target)
	local character = resolveCharacter(target)
	if not character then
		return nil
	end

	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end

	local primaryPart = character.PrimaryPart
	if primaryPart and primaryPart:IsA("BasePart") then
		return primaryPart
	end

	return nil
end

local function getHeadPosition(target)
	local head = HeadAim.getHead(target)
	if not head then
		return nil, nil
	end

	return head, head.Position
end

local function isHeadObstructed(head, origin, position, raycastParams)
	if typeof(origin) ~= "Vector3" or typeof(position) ~= "Vector3" then
		return false
	end

	if not workspace or not workspace.Raycast then
		return false
	end

	local direction = position - origin
	local result = workspace:Raycast(origin, direction, raycastParams)
	if not result then
		return false
	end

	if head and (result.Instance == head or result.Instance:IsDescendantOf(head.Parent)) then
		return false
	end

	return true
end

local function getOriginPosition(camera, originOverride)
	if typeof(originOverride) == "Vector3" then
		return originOverride
	end

	if typeof(originOverride) == "Instance" and originOverride:IsA("BasePart") then
		return originOverride.Position
	end

	if camera and camera.CFrame then
		return camera.CFrame.Position
	end

	return Vector3.new(0, 0, 0)
end

function HeadAim.aimAtHead(camera, target, originOverride)
	local head = HeadAim.getHead(target)
	if not head then
		return nil, "Head not found"
	end

	local origin = getOriginPosition(camera, originOverride)

	local lookCFrame = CFrame.lookAt(origin, head.Position)
	if camera then
		camera.CFrame = lookCFrame
	end

	return lookCFrame
end

function HeadAim.getEnemyLocation(enemies, origin, options)
	if typeof(enemies) ~= "table" then
		return nil, "Enemies list must be a table"
	end

	local config = options or DEFAULT_ENEMY_OPTIONS
	local originPosition = origin
	if typeof(origin) ~= "Vector3" then
		originPosition = Vector3.new(0, 0, 0)
	end

	local chosenHead
	local chosenPosition
	local chosenDistance
	local chosenObstructed = false

	for _, enemy in ipairs(enemies) do
		local head, position = getHeadPosition(enemy)
		if head and position then
			local obstructed = isHeadObstructed(head, originPosition, position, config.RaycastParams)
			if not config.PreferClosest then
				return head, position, obstructed
			end

			local distance = (position - originPosition).Magnitude
			if not chosenDistance or distance < chosenDistance then
				chosenHead = head
				chosenPosition = position
				chosenDistance = distance
				chosenObstructed = obstructed
			end
		end
	end

	if not chosenHead then
		return nil, "No enemy head found"
	end

	return chosenHead, chosenPosition, chosenObstructed
end

function HeadAim.aimAtEnemyHead(camera, enemies, originOverride, options)
	local origin = getOriginPosition(camera, originOverride)
	local head, position = HeadAim.getEnemyLocation(enemies, origin, options)
	if not head or not position then
		return nil, "Enemy head not found"
	end

	local lookCFrame = CFrame.lookAt(origin, position)
	if camera then
		camera.CFrame = lookCFrame
	end

	return lookCFrame
end

return HeadAim
