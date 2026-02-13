-- ====================[ KEY GUI CLEAN ]===================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local lp = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local placeId = game.PlaceId
local lastServerId = game.JobId
local autoRejoinEnabled = true
local rejoiningNow = false
local blockAutoRejoin = false

local function tryAutoRejoin()
	if not autoRejoinEnabled or rejoiningNow or blockAutoRejoin then
		return
	end
	rejoiningNow = true
	task.delay(1.5, function()
		pcall(function()
			if lastServerId and lastServerId ~= "" then
				TeleportService:TeleportToPlaceInstance(placeId, lastServerId, lp)
			else
				TeleportService:Teleport(placeId, lp)
			end
		end)
		task.delay(8, function()
			rejoiningNow = false
		end)
	end)
end

-- Key GUI
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "MEMAYBEO_KEY_GUI"
keyGui.ResetOnSpawn = false
keyGui.IgnoreGuiInset = true
keyGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame", keyGui)
Frame.Size = UDim2.new(0, 360, 0, 220)
Frame.Position = UDim2.new(0.5, -180, 0.5, -110)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.5
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 14)

-- Viền 7 màu (giảm lag bằng cách throttle)
local UIStroke = Instance.new("UIStroke", Frame)
UIStroke.Thickness = 2.5
do
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		UIStroke.Color = Color3.fromHSV((tick() * 0.35 % 1), 1, 1)
	end)
end

-- Title
local title = Instance.new("TextLabel", Frame)
title.Size = UDim2.new(1, 0, 0, 32)
title.Text = "MEMAYBEO HUB - NHẬP KEY"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextStrokeColor3 = Color3.new(0, 0, 0)
title.TextStrokeTransparency = 0.2

local clockInfo = Instance.new("TextLabel", Frame)
clockInfo.Size = UDim2.new(1, -20, 0, 16)
clockInfo.Position = UDim2.new(0, 10, 0, 32)
clockInfo.BackgroundTransparency = 1
clockInfo.Text = "Giờ hiện tại: --"
clockInfo.TextColor3 = Color3.fromRGB(220, 220, 220)
clockInfo.Font = Enum.Font.Gotham
clockInfo.TextSize = 13
clockInfo.TextXAlignment = Enum.TextXAlignment.Left
clockInfo.TextStrokeColor3 = Color3.new(0, 0, 0)
clockInfo.TextStrokeTransparency = 0.4

-- Info
local info = Instance.new("TextLabel", Frame)
info.Size = UDim2.new(1, -20, 0, 40)
info.Position = UDim2.new(0, 10, 0, 50)
info.BackgroundTransparency = 1
info.Text = "Mua key VIP ib TikTok: memaybeohub"
info.TextColor3 = Color3.fromRGB(220, 220, 220)
info.Font = Enum.Font.Gotham
info.TextSize = 17
info.TextWrapped = true
info.TextStrokeColor3 = Color3.new(0, 0, 0)
info.TextStrokeTransparency = 0.4

local timeInfo = Instance.new("TextLabel", Frame)
timeInfo.Size = UDim2.new(1, -20, 0, 20)
timeInfo.Position = UDim2.new(0, 10, 0, 85)
timeInfo.BackgroundTransparency = 1
timeInfo.Text = "Hạn key: --"
timeInfo.TextColor3 = Color3.fromRGB(220, 220, 220)
timeInfo.Font = Enum.Font.Gotham
timeInfo.TextSize = 14
timeInfo.TextXAlignment = Enum.TextXAlignment.Left
timeInfo.TextStrokeColor3 = Color3.new(0, 0, 0)
timeInfo.TextStrokeTransparency = 0.4

-- Input box
local box = Instance.new("TextBox", Frame)
box.Size = UDim2.new(0.85, 0, 0, 40)
box.Position = UDim2.new(0.075, 0, 0, 108)
box.PlaceholderText = "Nhập key..."
box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
box.BackgroundTransparency = 0.3
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.GothamBold
box.TextSize = 18
box.Text = ""
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)

-- Confirm button
local confirm = Instance.new("TextButton", Frame)
confirm.Size = UDim2.new(0.55, 0, 0, 40)
confirm.Position = UDim2.new(0.225, 0, 0, 160)
confirm.Text = "Xác nhận"
confirm.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
confirm.TextColor3 = Color3.new(1, 1, 1)
confirm.Font = Enum.Font.GothamBold
confirm.TextSize = 18
confirm.TextStrokeColor3 = Color3.new(0, 0, 0)
confirm.TextStrokeTransparency = 0.2
Instance.new("UICorner", confirm).CornerRadius = UDim.new(0, 12)

-- Keys
local KEY_FREE = "free123"
local KEY_VIP = "vip123"
local KEY_URL = "https://mwmaksjzj-1.onrender.com"
local KEY_VALIDATE = KEY_URL .. "/validate/"
local KEY_ENDPOINTS = {
	KEY_VALIDATE,
}
local SAVED_KEY_FILE = "memaybeo_saved_key.txt"
local Valid = false
local keyExpiryDisplay = "Hạn key: --"
local keyExpiryAt = nil
local keyTimeMain
local currentTimeMain
local currentTimeOutside
local keyTimeOutside

local function sanitizeKey(text)
	return tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function loadSavedKey()
	if not (readfile and isfile) then
		return ""
	end
	if not isfile(SAVED_KEY_FILE) then
		return ""
	end
	local ok, data = pcall(readfile, SAVED_KEY_FILE)
	if not ok or not data then
		return ""
	end
	return sanitizeKey(data)
end

local function saveKey(value)
	if not writefile then
		return
	end
	pcall(function()
		writefile(SAVED_KEY_FILE, sanitizeKey(value))
	end)
end

local function clearSavedKey()
	if not delfile or not isfile then
		return
	end
	if not isfile(SAVED_KEY_FILE) then
		return
	end
	pcall(delfile, SAVED_KEY_FILE)
end

box.Text = loadSavedKey()

local function parseExpiry(value)
	if not value then
		return nil
	end
	if type(value) == "number" then
		return value
	end
	local asNumber = tonumber(value)
	if asNumber then
		return asNumber
	end
	if type(value) == "string" then
		local y, mo, d, h, mi, s = value:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
		if y and mo and d then
			return os.time({
				year = tonumber(y),
				month = tonumber(mo),
				day = tonumber(d),
				hour = tonumber(h) or 0,
				min = tonumber(mi) or 0,
				sec = tonumber(s) or 0,
			})
		end
		local okDate, dateTime = pcall(function()
			return DateTime.fromIsoDateTime(value)
		end)
		if okDate and dateTime then
			return dateTime.UnixTimestamp
		end
	end
	return nil
end

local function getDeviceFingerprint()
	local ok, id = pcall(function()
		return game:GetService("RbxAnalyticsService"):GetClientId()
	end)
	if ok and id and id ~= "" then
		return tostring(id)
	end
	return tostring(lp.UserId)
end

local function normalizeKeyData(raw)
	if type(raw) == "table" then
		return raw
	end
	if raw == nil then
		return nil
	end
	local text = tostring(raw):gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" or text:lower() == "forbidden" then
		return nil
	end
	if text:sub(1, 1) ~= "{" then
		return nil
	end
	local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, text)
	if okDecode and type(decoded) == "table" then
		return decoded
	end
	return nil
end

local function requestKeyData(url)
	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = {
				["Accept"] = "application/json,text/plain,*/*",
			},
		})
	end)
	if ok and res then
		return res
	end

	if not ok or not res then
		local okGet, body = pcall(function()
			return game:HttpGet(url)
		end)
		if okGet and body then
			return {
				Success = true,
				StatusCode = 200,
				Body = body,
			}
		end
		return nil
	end

	return nil
end

local function fetchWebKeyWithInput(inputKey)
	local cleanKey = sanitizeKey(inputKey)
	if cleanKey == "" then
		return nil
	end
	local fp = HttpService:UrlEncode(getDeviceFingerprint())
	for _ = 1, 2 do
		for _, endpoint in ipairs(KEY_ENDPOINTS) do
			local url = endpoint .. HttpService:UrlEncode(cleanKey) .. "?fp=" .. fp
			local response = requestKeyData(url)
			if response and response.Body then
				local normalized = normalizeKeyData(response.Body)
				if normalized then
					normalized._status = response.StatusCode
					return normalized
				end
			end
		end
		task.wait(0.25)
	end
	return nil
end

local function formatCountdown(seconds)
	if seconds <= 0 then
		return "00:00:00"
	end
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function refreshKeyExpiryDisplay()
	if keyExpiryAt then
		local left = keyExpiryAt - os.time()
		if left <= 0 then
			keyExpiryDisplay = "Hạn key còn: 00:00:00"
		else
			keyExpiryDisplay = "Hạn key còn: " .. formatCountdown(left)
		end
	else
		if keyExpiryDisplay == "Hạn key: --" then
			return
		end
		keyExpiryDisplay = "Hạn key: Không giới hạn"
	end
end

task.spawn(function()
	while true do
		refreshKeyExpiryDisplay()
		if keyGui.Parent then
			clockInfo.Text = "Giờ hiện tại: " .. os.date("%d/%m/%Y %H:%M:%S")
		end
		if keyTimeMain and keyTimeMain.Parent then
			keyTimeMain.Text = keyExpiryDisplay
		end
		if currentTimeMain and currentTimeMain.Parent then
			currentTimeMain.Text = "Giờ hiện tại: " .. os.date("%H:%M:%S")
		end
		if currentTimeOutside and currentTimeOutside.Parent then
			currentTimeOutside.Text = "🕒 " .. os.date("%H:%M:%S")
		end
		if keyTimeOutside and keyTimeOutside.Parent then
			keyTimeOutside.Text = keyExpiryDisplay
		end
		task.wait(1)
	end
end)

local function updateWebExpiryLabel()
	local data = fetchWebKeyWithInput(sanitizeKey(box.Text))
	if not data then
		return
	end
	local expiresAt = parseExpiry(data.expires_at or data.expiresAt or data.expireAt or data.expires)
	if expiresAt then
		keyExpiryAt = expiresAt
		refreshKeyExpiryDisplay()
		timeInfo.Text = keyExpiryDisplay
	end
end

local function isKeyValidFromWeb(inputKey)
	local cleanKey = sanitizeKey(inputKey)
	local data = fetchWebKeyWithInput(cleanKey)
	if not data then
		return false
	end
	local expiresAt = parseExpiry(data.expires_at or data.expiresAt or data.expireAt or data.expires)
	if expiresAt then
		keyExpiryAt = expiresAt
		refreshKeyExpiryDisplay()
	end
	if data.ok == true or data.valid == true or data.success == true then
		return true
	end
	if type(data.message) == "string" then
		timeInfo.Text = "Web: " .. data.message
	end
	if data.ok == false or data.valid == false or data.success == false then
		return false
	end
	local webKey = tostring(data.key or data.Key or data.accessKey or "")
	if webKey ~= "" and cleanKey ~= webKey then
		if type(data.keys) == "table" then
			local found = false
			for _, entry in ipairs(data.keys) do
				if tostring(entry) == cleanKey then
					found = true
					break
				end
			end
			if not found then
				return false
			end
		elseif not tostring(data):find(cleanKey, 1, true) then
			return false
		end
	end
	if expiresAt and os.time() > expiresAt then
		return false
	end
	if not expiresAt then
		keyExpiryAt = nil
		keyExpiryDisplay = "Hạn key: Không giới hạn"
	end
	refreshKeyExpiryDisplay()
	return true
end

task.spawn(function()
	local saved = sanitizeKey(loadSavedKey())
	if saved == "" then
		return
	end
	box.Text = saved
	updateWebExpiryLabel()
	if saved == KEY_FREE or saved == KEY_VIP or isKeyValidFromWeb(saved) then
		Valid = true
		keyGui:Destroy()
	else
		clearSavedKey()
	end
end)

confirm.MouseButton1Click:Connect(function()
	local k = sanitizeKey(box.Text)
	updateWebExpiryLabel()
	if k == KEY_FREE or k == KEY_VIP or isKeyValidFromWeb(k) then
		saveKey(k)
		Valid = true
		keyGui:Destroy()
	else
		confirm.Text = "Sai key!"
		confirm.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
		task.wait(1)
		confirm.Text = "Xác nhận"
		confirm.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	end
end)
repeat task.wait() until Valid

task.spawn(function()
	while true do
		if keyExpiryAt and os.time() >= keyExpiryAt then
			blockAutoRejoin = true
			clearSavedKey()
			lp:Kick("Key đã hết hạn, vui lòng lấy key mới.")
			break
		end
		task.wait(1)
	end
end)

GuiService.ErrorMessageChanged:Connect(function(message)
	if type(message) ~= "string" then
		return
	end
	if message == "" then
		return
	end
	tryAutoRejoin()
end)

-- ====================[ ANTI AFK ]===================
lp.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- ====================[ NHÂN VẬT ]===================
local hrp, hum
local function getChar()
	local char = lp.Character or lp.CharacterAdded:Wait()
	hrp = char:WaitForChild("HumanoidRootPart")
	hum = char:WaitForChild("Humanoid")
	return char
end
getChar()
lp.CharacterAdded:Connect(function()
	task.wait(1)
	getChar()
end)

-- ====================[ GUI CHÍNH + COLLAPSE ]===================
local guiMain = Instance.new("ScreenGui", lp:WaitForChild("PlayerGui"))
guiMain.Name = "MEMAYBEO_HUB"
guiMain.ResetOnSpawn = false

currentTimeOutside = Instance.new("TextLabel", guiMain)
currentTimeOutside.Size = UDim2.new(0, 120, 0, 24)
currentTimeOutside.Position = UDim2.new(0, 10, 0, 10)
currentTimeOutside.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
currentTimeOutside.BackgroundTransparency = 0.35
currentTimeOutside.Text = "🕒 --:--:--"
currentTimeOutside.TextColor3 = Color3.new(1, 1, 1)
currentTimeOutside.Font = Enum.Font.GothamBold
currentTimeOutside.TextSize = 14
currentTimeOutside.TextStrokeColor3 = Color3.new(0, 0, 0)
currentTimeOutside.TextStrokeTransparency = 0.35
Instance.new("UICorner", currentTimeOutside).CornerRadius = UDim.new(0, 8)

keyTimeOutside = Instance.new("TextLabel", guiMain)
keyTimeOutside.Size = UDim2.new(0, 220, 0, 24)
keyTimeOutside.Position = UDim2.new(0, 10, 0, 38)
keyTimeOutside.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
keyTimeOutside.BackgroundTransparency = 0.35
keyTimeOutside.Text = keyExpiryDisplay
keyTimeOutside.TextColor3 = Color3.new(1, 1, 1)
keyTimeOutside.Font = Enum.Font.GothamBold
keyTimeOutside.TextSize = 13
keyTimeOutside.TextXAlignment = Enum.TextXAlignment.Left
keyTimeOutside.TextStrokeColor3 = Color3.new(0, 0, 0)
keyTimeOutside.TextStrokeTransparency = 0.35
Instance.new("UICorner", keyTimeOutside).CornerRadius = UDim.new(0, 8)

local main = Instance.new("Frame", guiMain)
main.Size = UDim2.new(0, 300, 0, 650)
main.Position = UDim2.new(0.05, 0, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
main.BackgroundTransparency = 0.5
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

-- 7 màu viền (giảm lag)
local UIStroke2 = Instance.new("UIStroke", main)
UIStroke2.Thickness = 2
do
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		UIStroke2.Color = Color3.fromHSV((tick() * 0.4 % 1), 1, 1)
	end)
end

-- Title
local title2 = Instance.new("TextLabel", main)
title2.Size = UDim2.new(1, 0, 0, 30)
title2.Position = UDim2.new(0, 0, 0, 0)
title2.BackgroundTransparency = 1
title2.Text = "MEMAYBEO HUB"
title2.TextColor3 = Color3.new(1, 1, 1)
title2.Font = Enum.Font.GothamBlack
title2.TextSize = 18
title2.TextStrokeColor3 = Color3.new(0, 0, 0)
title2.TextStrokeTransparency = 0.2

keyTimeMain = Instance.new("TextLabel", main)
keyTimeMain.Size = UDim2.new(1, -20, 0, 16)
keyTimeMain.Position = UDim2.new(0, 10, 1, -20)
keyTimeMain.BackgroundTransparency = 1
keyTimeMain.Text = keyExpiryDisplay
keyTimeMain.TextColor3 = Color3.fromRGB(220, 220, 220)
keyTimeMain.Font = Enum.Font.Gotham
keyTimeMain.TextSize = 12
keyTimeMain.TextXAlignment = Enum.TextXAlignment.Left
keyTimeMain.TextStrokeColor3 = Color3.new(0, 0, 0)
keyTimeMain.TextStrokeTransparency = 0.4

currentTimeMain = Instance.new("TextLabel", main)
currentTimeMain.Size = UDim2.new(1, -20, 0, 16)
currentTimeMain.Position = UDim2.new(0, 10, 1, -36)
currentTimeMain.BackgroundTransparency = 1
currentTimeMain.Text = "Giờ hiện tại: --:--:--"
currentTimeMain.TextColor3 = Color3.fromRGB(220, 220, 220)
currentTimeMain.Font = Enum.Font.Gotham
currentTimeMain.TextSize = 12
currentTimeMain.TextXAlignment = Enum.TextXAlignment.Left
currentTimeMain.TextStrokeColor3 = Color3.new(0, 0, 0)
currentTimeMain.TextStrokeTransparency = 0.4

-- Collapse button
local collapseBtn = Instance.new("TextButton", main)
collapseBtn.Size = UDim2.new(0, 30, 0, 30)
collapseBtn.Position = UDim2.new(1, -35, 0, 0)
collapseBtn.Text = "-"
collapseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
collapseBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0, 6)

-- Content
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, 0, 1, -30)
content.Position = UDim2.new(0, 0, 0, 30)
content.BackgroundTransparency = 1

-- Nút Farm
local btnFarm = Instance.new("TextButton", content)
btnFarm.Size = UDim2.new(0, 260, 0, 30)
btnFarm.Position = UDim2.new(0, 20, 0, 10)
btnFarm.Text = "✅ Auto Farm NPC2"
btnFarm.TextColor3 = Color3.new(1, 1, 1)
btnFarm.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnFarm.BackgroundTransparency = 0.2
btnFarm.Font = Enum.Font.GothamBold
btnFarm.TextStrokeColor3 = Color3.new(0, 0, 0)
btnFarm.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnFarm).CornerRadius = UDim.new(0, 8)

-- Auto Pickup
local btnPickup = Instance.new("TextButton", content)
btnPickup.Size = UDim2.new(0, 260, 0, 30)
btnPickup.Position = UDim2.new(0, 20, 0, 50)
btnPickup.Text = "🟢 Nhặt Drop GiangHo2 (OFF)"
btnPickup.TextColor3 = Color3.new(1, 1, 1)
btnPickup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnPickup.BackgroundTransparency = 0.2
btnPickup.Font = Enum.Font.GothamBold
btnPickup.TextStrokeColor3 = Color3.new(0, 0, 0)
btnPickup.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnPickup).CornerRadius = UDim.new(0, 8)

-- Server Hop
local btnHop = Instance.new("TextButton", content)
btnHop.Size = UDim2.new(0, 260, 0, 30)
btnHop.Position = UDim2.new(0, 20, 0, 90)
btnHop.Text = "🌐 Đổi Server"
btnHop.TextColor3 = Color3.new(1, 1, 1)
btnHop.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnHop.BackgroundTransparency = 0.2
btnHop.Font = Enum.Font.GothamBold
btnHop.TextStrokeColor3 = Color3.new(0, 0, 0)
btnHop.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnHop).CornerRadius = UDim.new(0, 8)

-- Thanh HP
local hpBg = Instance.new("Frame", content)
hpBg.Size = UDim2.new(1, -40, 0, 25)
hpBg.Position = UDim2.new(0, 20, 0, 130)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hpBg.BackgroundTransparency = 0.2
Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 6)

local hpLabel = Instance.new("TextLabel", hpBg)
hpLabel.Size = UDim2.new(1, 0, 1, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.TextColor3 = Color3.new(1, 1, 1)
hpLabel.Font = Enum.Font.GothamBlack
hpLabel.TextSize = 16
hpLabel.Text = "NPC2: ??? / ???"
hpLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
hpLabel.TextStrokeTransparency = 0.2

local npcCountLabel = Instance.new("TextLabel", content)
npcCountLabel.Size = UDim2.new(0, 260, 0, 20)
npcCountLabel.Position = UDim2.new(0, 20, 0, 155)
npcCountLabel.BackgroundTransparency = 1
npcCountLabel.TextColor3 = Color3.new(1, 1, 1)
npcCountLabel.Font = Enum.Font.GothamBold
npcCountLabel.TextSize = 14
npcCountLabel.TextXAlignment = Enum.TextXAlignment.Left
npcCountLabel.Text = "NPC2 còn: 0"
npcCountLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
npcCountLabel.TextStrokeTransparency = 0.25

local cityCountLabel = Instance.new("TextLabel", content)
cityCountLabel.Size = UDim2.new(0, 260, 0, 20)
cityCountLabel.Position = UDim2.new(0, 20, 0, 175)
cityCountLabel.BackgroundTransparency = 1
cityCountLabel.TextColor3 = Color3.new(1, 1, 1)
cityCountLabel.Font = Enum.Font.GothamBold
cityCountLabel.TextSize = 14
cityCountLabel.TextXAlignment = Enum.TextXAlignment.Left
cityCountLabel.Text = "CityNPC còn: 0"
cityCountLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
cityCountLabel.TextStrokeTransparency = 0.25

local speedLabel = Instance.new("TextLabel", content)
speedLabel.Size = UDim2.new(0, 260, 0, 20)
speedLabel.Position = UDim2.new(0, 20, 0, 195)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Text = "Tốc độ: 12"
speedLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
speedLabel.TextStrokeTransparency = 0.25

local distanceLabel = Instance.new("TextLabel", content)
distanceLabel.Size = UDim2.new(0, 260, 0, 20)
distanceLabel.Position = UDim2.new(0, 20, 0, 215)
distanceLabel.BackgroundTransparency = 1
distanceLabel.TextColor3 = Color3.new(1, 1, 1)
distanceLabel.Font = Enum.Font.GothamBold
distanceLabel.TextSize = 14
distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
distanceLabel.Text = "Khoảng cách: 9"
distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
distanceLabel.TextStrokeTransparency = 0.25

local speedInput = Instance.new("TextBox", content)
speedInput.Size = UDim2.new(0, 125, 0, 26)
speedInput.Position = UDim2.new(0, 20, 0, 235)
speedInput.PlaceholderText = "Nhập tốc độ"
speedInput.Text = "12"
speedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
speedInput.BackgroundTransparency = 0.2
speedInput.TextColor3 = Color3.new(1, 1, 1)
speedInput.Font = Enum.Font.GothamBold
speedInput.TextSize = 13
speedInput.ClearTextOnFocus = false
Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 8)

local distanceInput = Instance.new("TextBox", content)
distanceInput.Size = UDim2.new(0, 125, 0, 26)
distanceInput.Position = UDim2.new(0, 155, 0, 235)
distanceInput.PlaceholderText = "Nhập khoảng cách"
distanceInput.Text = "9"
distanceInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
distanceInput.BackgroundTransparency = 0.2
distanceInput.TextColor3 = Color3.new(1, 1, 1)
distanceInput.Font = Enum.Font.GothamBold
distanceInput.TextSize = 13
distanceInput.ClearTextOnFocus = false
Instance.new("UICorner", distanceInput).CornerRadius = UDim.new(0, 8)

local btnSpeed = Instance.new("TextButton", content)
btnSpeed.Size = UDim2.new(0, 260, 0, 28)
btnSpeed.Position = UDim2.new(0, 20, 0, 265)
btnSpeed.Text = "⚡ Áp dụng tốc độ/khoảng cách"
btnSpeed.TextColor3 = Color3.new(1, 1, 1)
btnSpeed.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnSpeed.BackgroundTransparency = 0.2
btnSpeed.Font = Enum.Font.GothamBold
btnSpeed.TextStrokeColor3 = Color3.new(0, 0, 0)
btnSpeed.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnSpeed).CornerRadius = UDim.new(0, 8)

local btnDistance = Instance.new("TextButton", content)
btnDistance.Size = UDim2.new(0, 260, 0, 28)
btnDistance.Position = UDim2.new(0, 20, 0, 295)
btnDistance.Text = "🚀 Fix Lag (OFF)"
btnDistance.TextColor3 = Color3.new(1, 1, 1)
btnDistance.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnDistance.BackgroundTransparency = 0.2
btnDistance.Font = Enum.Font.GothamBold
btnDistance.TextStrokeColor3 = Color3.new(0, 0, 0)
btnDistance.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnDistance).CornerRadius = UDim.new(0, 8)

-- Auto băng + chọn vũ khí
local btnAutoBang = Instance.new("TextButton", content)
btnAutoBang.Size = UDim2.new(0, 260, 0, 30)
btnAutoBang.Position = UDim2.new(0, 20, 0, 300)
btnAutoBang.Text = "🤕 Auto Băng (OFF)"
btnAutoBang.TextColor3 = Color3.new(1, 1, 1)
btnAutoBang.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnAutoBang.BackgroundTransparency = 0.2
btnAutoBang.Font = Enum.Font.GothamBold
btnAutoBang.TextStrokeColor3 = Color3.new(0, 0, 0)
btnAutoBang.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnAutoBang).CornerRadius = UDim.new(0, 8)

local btnAutoBuyBandage = Instance.new("TextButton", content)
btnAutoBuyBandage.Size = UDim2.new(0, 260, 0, 30)
btnAutoBuyBandage.Position = UDim2.new(0, 20, 0, 522)
btnAutoBuyBandage.Text = "🛒 Auto mua Băng gạc (OFF)"
btnAutoBuyBandage.TextColor3 = Color3.new(1, 1, 1)
btnAutoBuyBandage.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnAutoBuyBandage.BackgroundTransparency = 0.2
btnAutoBuyBandage.Font = Enum.Font.GothamBold
btnAutoBuyBandage.TextStrokeColor3 = Color3.new(0, 0, 0)
btnAutoBuyBandage.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnAutoBuyBandage).CornerRadius = UDim.new(0, 8)

local btnCityFarm = Instance.new("TextButton", content)
btnCityFarm.Size = UDim2.new(0, 260, 0, 30)
btnCityFarm.Position = UDim2.new(0, 20, 0, 335)
btnCityFarm.Text = "⚔️ Auto Farm CityNPC (OFF)"
btnCityFarm.TextColor3 = Color3.new(1, 1, 1)
btnCityFarm.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnCityFarm.BackgroundTransparency = 0.2
btnCityFarm.Font = Enum.Font.GothamBold
btnCityFarm.TextStrokeColor3 = Color3.new(0, 0, 0)
btnCityFarm.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnCityFarm).CornerRadius = UDim.new(0, 8)

local btnCityPickup = Instance.new("TextButton", content)
btnCityPickup.Size = UDim2.new(0, 260, 0, 30)
btnCityPickup.Position = UDim2.new(0, 20, 0, 372)
btnCityPickup.Text = "📦 Nhặt Drop CityNPC (OFF)"
btnCityPickup.TextColor3 = Color3.new(1, 1, 1)
btnCityPickup.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnCityPickup.BackgroundTransparency = 0.2
btnCityPickup.Font = Enum.Font.GothamBold
btnCityPickup.TextStrokeColor3 = Color3.new(0, 0, 0)
btnCityPickup.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnCityPickup).CornerRadius = UDim.new(0, 8)

local btnNoAnim = Instance.new("TextButton", content)
btnNoAnim.Size = UDim2.new(0, 260, 0, 30)
btnNoAnim.Position = UDim2.new(0, 20, 0, 410)
btnNoAnim.Text = "🎬 Không hoạt ảnh đánh (OFF)"
btnNoAnim.TextColor3 = Color3.new(1, 1, 1)
btnNoAnim.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnNoAnim.BackgroundTransparency = 0.2
btnNoAnim.Font = Enum.Font.GothamBold
btnNoAnim.TextStrokeColor3 = Color3.new(0, 0, 0)
btnNoAnim.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnNoAnim).CornerRadius = UDim.new(0, 8)

local btnAntiWall = Instance.new("TextButton", content)
btnAntiWall.Size = UDim2.new(0, 260, 0, 30)
btnAntiWall.Position = UDim2.new(0, 20, 0, 447)
btnAntiWall.Text = "🧱 Chống kẹt tường (TẮT)"
btnAntiWall.TextColor3 = Color3.new(1, 1, 1)
btnAntiWall.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnAntiWall.BackgroundTransparency = 0.2
btnAntiWall.Font = Enum.Font.GothamBold
btnAntiWall.TextStrokeColor3 = Color3.new(0, 0, 0)
btnAntiWall.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnAntiWall).CornerRadius = UDim.new(0, 8)

btnAutoBang.Position = UDim2.new(0, 20, 0, 484)

local weaponLabel = Instance.new("TextLabel", content)
weaponLabel.Size = UDim2.new(0, 260, 0, 20)
weaponLabel.Position = UDim2.new(0, 20, 0, 560)
weaponLabel.BackgroundTransparency = 1
weaponLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
weaponLabel.Font = Enum.Font.GothamBold
weaponLabel.TextSize = 16
weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponLabel.Text = "🎯 Vũ khí: (chưa chọn)"
weaponLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
weaponLabel.TextStrokeTransparency = 0.25

local btnWeapon = Instance.new("TextButton", content)
btnWeapon.Size = UDim2.new(0, 260, 0, 30)
btnWeapon.Position = UDim2.new(0, 20, 0, 590)
btnWeapon.Text = "🎯 Chọn vũ khí"
btnWeapon.TextColor3 = Color3.new(1, 1, 1)
btnWeapon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btnWeapon.BackgroundTransparency = 0.2
btnWeapon.Font = Enum.Font.GothamBold
btnWeapon.TextStrokeColor3 = Color3.new(0, 0, 0)
btnWeapon.TextStrokeTransparency = 0.2
Instance.new("UICorner", btnWeapon).CornerRadius = UDim.new(0, 8)

-- Collapse logic
local collapsed = false
collapseBtn.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	content.Visible = not collapsed
	main.Size = collapsed and UDim2.new(0, 300, 0, 30) or UDim2.new(0, 300, 0, 650)
	collapseBtn.Text = collapsed and "+" or "-"
end)

-- ====================[ AUTO FARM + PICKUP + SERVER HOP LOGIC ]===================
local farming = false
local autoPickup = false
local orbitAngle = 0
local cityFarm = false
local cityPickup = false
local cityNpcIndex = 1
local orbitSpeed = 12
local orbitRadius = 9
local fixLag = false
local noAttackAnim = false
local antiWallStuck = false
local lastSafePosition = nil
local wallStuckElapsed = 0
local lagDisabledEmitters = {}
local lagDisabledTrails = {}

local function applyFixLagState(enabled)
	if enabled then
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 1e10
			Lighting.Brightness = 1
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter") and obj.Enabled then
					lagDisabledEmitters[obj] = true
					obj.Enabled = false
				elseif obj:IsA("Trail") and obj.Enabled then
					lagDisabledTrails[obj] = true
					obj.Enabled = false
				elseif obj:IsA("BasePart") then
					obj.Material = Enum.Material.Plastic
					obj.Reflectance = 0
				end
			end
		end)
	else
		pcall(function()
			Lighting.GlobalShadows = true
			Lighting.FogEnd = 100000
			for emitter in pairs(lagDisabledEmitters) do
				if emitter and emitter.Parent then
					emitter.Enabled = true
				end
			end
			for trail in pairs(lagDisabledTrails) do
				if trail and trail.Parent then
					trail.Enabled = true
				end
			end
			lagDisabledEmitters = {}
			lagDisabledTrails = {}
		end)
	end
end

btnFarm.MouseButton1Click:Connect(function()
	farming = not farming
	btnFarm.Text = farming and "🟢 Đang Farm NPC2" or "✅ Auto Farm NPC2"
	btnFarm.BackgroundColor3 = farming and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

btnPickup.MouseButton1Click:Connect(function()
	autoPickup = not autoPickup
	btnPickup.Text = autoPickup and "🟢 Nhặt Drop GiangHo2 (ON)" or "🟢 Nhặt Drop GiangHo2 (OFF)"
	btnPickup.BackgroundColor3 = autoPickup and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

btnHop.MouseButton1Click:Connect(function()
	local gameId = game.PlaceId
	local best
	local bestPlayers = math.huge
	local cursor = ""
	while true do
		local url = "https://games.roblox.com/v1/games/" .. gameId .. "/servers/Public?limit=100&cursor=" .. cursor
		local s, data = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(url))
		end)
		if not s then
			break
		end
		for _, srv in ipairs(data.data) do
			if srv.id ~= game.JobId and srv.playing and srv.maxPlayers then
				if srv.playing < srv.maxPlayers and srv.playing < bestPlayers then
					best = srv.id
					bestPlayers = srv.playing
				end
			end
		end
		cursor = data.nextPageCursor
		if not cursor then
			break
		end
	end
	if best then
		TeleportService:TeleportToPlaceInstance(gameId, best, lp)
	end
end)

btnCityFarm.MouseButton1Click:Connect(function()
	cityFarm = not cityFarm
	btnCityFarm.Text = cityFarm and "⚔️ Auto Farm CityNPC (ON)" or "⚔️ Auto Farm CityNPC (OFF)"
	btnCityFarm.BackgroundColor3 = cityFarm and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

btnCityPickup.MouseButton1Click:Connect(function()
	cityPickup = not cityPickup
	btnCityPickup.Text = cityPickup and "📦 Nhặt Drop CityNPC (ON)" or "📦 Nhặt Drop CityNPC (OFF)"
	btnCityPickup.BackgroundColor3 = cityPickup and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

local function updateSpeedLabel()
	speedLabel.Text = "Tốc độ: " .. tostring(orbitSpeed)
end

local function updateDistanceLabel()
	distanceLabel.Text = "Khoảng cách: " .. tostring(orbitRadius)
end

btnSpeed.MouseButton1Click:Connect(function()
	local parsedSpeed = tonumber(speedInput.Text)
	local parsedDistance = tonumber(distanceInput.Text)
	if parsedSpeed and parsedSpeed >= 1 and parsedSpeed <= 60 then
		orbitSpeed = math.floor(parsedSpeed)
	else
		speedInput.Text = tostring(orbitSpeed)
	end
	if parsedDistance and parsedDistance >= 2 and parsedDistance <= 50 then
		orbitRadius = math.floor(parsedDistance)
	else
		distanceInput.Text = tostring(orbitRadius)
	end
	updateSpeedLabel()
	updateDistanceLabel()
end)

btnDistance.MouseButton1Click:Connect(function()
	fixLag = not fixLag
	btnDistance.Text = fixLag and "🚀 Fix Lag (ON)" or "🚀 Fix Lag (OFF)"
	btnDistance.BackgroundColor3 = fixLag and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
	applyFixLagState(fixLag)
end)

btnNoAnim.MouseButton1Click:Connect(function()
	noAttackAnim = not noAttackAnim
	btnNoAnim.Text = noAttackAnim and "🎬 Không hoạt ảnh đánh (ON)" or "🎬 Không hoạt ảnh đánh (OFF)"
	btnNoAnim.BackgroundColor3 = noAttackAnim and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
	if noAttackAnim and hum and hum.Parent then
		for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
			pcall(function()
				track:Stop(0)
			end)
		end
	end
end)

btnAntiWall.MouseButton1Click:Connect(function()
	antiWallStuck = not antiWallStuck
	btnAntiWall.Text = antiWallStuck and "🧱 Chống kẹt tường (ON)" or "🧱 Chống kẹt tường (OFF)"
	btnAntiWall.BackgroundColor3 = antiWallStuck and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
	wallStuckElapsed = 0
	if antiWallStuck and hrp then
		lastSafePosition = hrp.Position
	end
end)

updateSpeedLabel()
updateDistanceLabel()
speedInput.Text = tostring(orbitSpeed)
distanceInput.Text = tostring(orbitRadius)

if queue_on_teleport then
	local scriptText = string.format(
		"local TeleportService=game:GetService('TeleportService');local Players=game:GetService('Players');local lp=Players.LocalPlayer;TeleportService:TeleportToPlaceInstance(%d,'%s',lp)",
		placeId,
		lastServerId
	)
	queue_on_teleport(scriptText)
end

local function isHealTool(tool)
	local n = tool.Name:lower()
	return n:find("bang") or n:find("băng") or n:find("med") or n:find("heal") or n:find("kit") or n:find("band")
end

local function findBandagePrompt()
	local shop = workspace:FindFirstChild("NPCs")
		and workspace.NPCs:FindFirstChild("Shop")
		and workspace.NPCs.Shop:FindFirstChild("Bán băng gạc")
	if not shop then
		return nil
	end
	for _, prompt in ipairs(shop:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			return prompt
		end
	end
	return nil
end

local function buyBandagePack(times)
	if not fireproximityprompt then
		return false
	end
	local prompt = findBandagePrompt()
	if not prompt then
		return false
	end
	times = math.max(1, times or 5)
	for _ = 1, times do
		pcall(function()
			fireproximityprompt(prompt)
		end)
		task.wait(0.2)
	end
	return true
end

local function readBandageAmountFromTool(tool)
	local values = { "Amount", "Count", "Stack", "Uses", "Value" }
	for _, key in ipairs(values) do
		local child = tool:FindFirstChild(key)
		if child and (child:IsA("IntValue") or child:IsA("NumberValue")) then
			return child.Value
		end
	end

	for _, key in ipairs(values) do
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

local function isBandageTool(tool)
	if not (tool and tool:IsA("Tool")) then
		return false
	end
	local n = tool.Name:lower()
	return n:find("băng gạc") or n:find("bang gac") or n:find("bandage")
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

	if lp.Character then
		collect(lp.Character)
	end
	collect(lp.Backpack)
	return total
end

local preferredWeaponName = ""
local function setPreferredWeapon(tool)
	if tool and tool:IsA("Tool") and not isHealTool(tool) then
		preferredWeaponName = tool.Name
		weaponLabel.Text = "🎯 Vũ khí: " .. preferredWeaponName
		return true
	end
	return false
end

btnWeapon.MouseButton1Click:Connect(function()
	local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
	if not tool then
		for _, v in ipairs(lp.Backpack:GetChildren()) do
			if v:IsA("Tool") and not isHealTool(v) then
				tool = v
				break
			end
		end
	end

	if setPreferredWeapon(tool) then
		btnWeapon.Text = "🎯 Đã lưu"
	else
		btnWeapon.Text = "❌ Không thấy"
	end
	task.delay(0.8, function()
		if btnWeapon then
			btnWeapon.Text = "🎯 Chọn vũ khí"
		end
	end)
end)

local autoBang = false
local autoBandageBuy = true
local autoBangThreshold = 75
local autoBandageMinCount = 99
local bandageBuyCooldown = 1.5
local healingInProgress = false
local lastHealAt = 0
local lastBandageBuyAt = 0

btnAutoBang.MouseButton1Click:Connect(function()
	autoBang = not autoBang
	btnAutoBang.Text = autoBang and "🤕 Auto Băng (ON)" or "🤕 Auto Băng (OFF)"
	btnAutoBang.BackgroundColor3 = autoBang and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)

end)

btnAutoBuyBandage.MouseButton1Click:Connect(function()
	autoBandageBuy = not autoBandageBuy
	btnAutoBuyBandage.Text = autoBandageBuy and "🛒 Auto mua Băng gạc (ON)" or "🛒 Auto mua Băng gạc (OFF)"
	btnAutoBuyBandage.BackgroundColor3 = autoBandageBuy and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end)

local function applyDefaultToggleState()
	btnFarm.Text = farming and "🟢 Đang Farm NPC2" or "✅ Auto Farm NPC2"
	btnFarm.BackgroundColor3 = farming and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)

	btnPickup.Text = autoPickup and "🟢 Nhặt Drop GiangHo2 (ON)" or "🟢 Nhặt Drop GiangHo2 (OFF)"
	btnPickup.BackgroundColor3 = autoPickup and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)

	btnCityFarm.Text = cityFarm and "⚔️ Auto Farm CityNPC (ON)" or "⚔️ Auto Farm CityNPC (OFF)"
	btnCityFarm.BackgroundColor3 = cityFarm and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)

	btnCityPickup.Text = cityPickup and "📦 Nhặt Drop CityNPC (ON)" or "📦 Nhặt Drop CityNPC (OFF)"
	btnCityPickup.BackgroundColor3 = cityPickup and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)

	btnDistance.Text = fixLag and "🚀 Fix Lag (ON)" or "🚀 Fix Lag (OFF)"
	btnDistance.BackgroundColor3 = fixLag and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
	applyFixLagState(fixLag)

	btnNoAnim.Text = noAttackAnim and "🎬 Không hoạt ảnh đánh (ON)" or "🎬 Không hoạt ảnh đánh (OFF)"
	btnNoAnim.BackgroundColor3 = noAttackAnim and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)

	btnAntiWall.Text = antiWallStuck and "🧱 Chống kẹt tường (ON)" or "🧱 Chống kẹt tường (OFF)"
	btnAntiWall.BackgroundColor3 = antiWallStuck and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
	if antiWallStuck and hrp then
		lastSafePosition = hrp.Position
	end

	btnAutoBang.Text = autoBang and "🤕 Auto Băng (ON)" or "🤕 Auto Băng (OFF)"
	btnAutoBang.BackgroundColor3 = autoBang and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)

	btnAutoBuyBandage.Text = autoBandageBuy and "🛒 Auto mua Băng gạc (ON)" or "🛒 Auto mua Băng gạc (OFF)"
	btnAutoBuyBandage.BackgroundColor3 = autoBandageBuy and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(30, 30, 30)
end

applyDefaultToggleState()

local function findHealTool()
	local char = lp.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and isHealTool(tool) then
				return tool
			end
		end
	end

	for _, tool in ipairs(lp.Backpack:GetChildren()) do
		if tool:IsA("Tool") and isHealTool(tool) then
			return tool
		end
	end

	return nil
end

local function findToolByName(name)
	if name == "" then
		return nil
	end
	local lower = name:lower()
	local char = lp.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and tool.Name:lower() == lower then
				return tool
			end
		end
	end
	for _, tool in ipairs(lp.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower() == lower then
			return tool
		end
	end
	return nil
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

local function collectDropParts(container)
	for _, item in ipairs(container:GetDescendants()) do
		if item:IsA("BasePart") then
			pcall(function()
				hrp.CFrame = CFrame.new(item.Position)
			end)
		elseif item:IsA("ProximityPrompt") and fireproximityprompt then
			pcall(function()
				fireproximityprompt(item)
			end)
		end
	end
end

task.spawn(function()
	while task.wait(0.25) do
		if (not autoBang and not autoBandageBuy) or healingInProgress then
			continue
		end
		local char = lp.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")

		local currentBandages = countBandages()
		if autoBandageBuy and currentBandages < autoBandageMinCount and (os.clock() - lastBandageBuyAt) > bandageBuyCooldown then
			local needed = autoBandageMinCount - currentBandages
			local buyTimes = math.clamp(math.ceil(needed / 5), 1, 20)
			if buyBandagePack(buyTimes) then
				lastBandageBuyAt = os.clock()
				task.wait(0.3)
			end
		end

		if not humanoid or humanoid.Health >= autoBangThreshold then
			continue
		end
		if os.clock() - lastHealAt < 0.5 then
			continue
		end

		local healTool = findHealTool()
		if not healTool then
			if buyBandagePack() then
				task.wait(0.4)
				healTool = findHealTool()
			end
			if not healTool then
				continue
			end
		end

		local current = char:FindFirstChildOfClass("Tool")
		if current and not isHealTool(current) and preferredWeaponName == "" then
			setPreferredWeapon(current)
		end

		healingInProgress = true
		humanoid:EquipTool(healTool)
		waitForEquipped(char, healTool, 1)

		local start = os.clock()
		while autoBang and humanoid.Health < humanoid.MaxHealth and (os.clock() - start) < 6 do
			pcall(function()
				healTool:Activate()
			end)
			task.wait(0.35)
		end

		lastHealAt = os.clock()
		healingInProgress = false

		local returnTool = findToolByName(preferredWeaponName) or current
		if returnTool then
			task.defer(function()
				humanoid:EquipTool(returnTool)
				waitForEquipped(char, returnTool, 1)
			end)
		end
	end
end)

-- Find nearest NPC2
local function getNearestNPC2()
	local nearest, dist, npcHRP = nil, 99999, nil
	local count = 0
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name == "NPC2" then
			local h = m:FindFirstChildOfClass("Humanoid")
			local p = m:FindFirstChild("HumanoidRootPart")
			if h and p and h.Health > 0 then
				count += 1
				local d = (p.Position - hrp.Position).Magnitude
				if d < dist then
					nearest = m
					dist = d
					npcHRP = p
				end
			end
		end
	end
	return nearest, npcHRP, count
end

local function getCityNPCs()
	local folder = workspace:FindFirstChild("CityNPCs")
	if not folder then
		return {}, 0
	end
	local npcFolder = folder:FindFirstChild("NPCs")
	if not npcFolder then
		return {}, 0
	end
	local count = 0
	local list = {}
	for _, npc in ipairs(npcFolder:GetChildren()) do
		local h = npc:FindFirstChildOfClass("Humanoid")
		local p = npc:FindFirstChild("HumanoidRootPart")
		if h and p and h.Health > 0 then
			count += 1
			table.insert(list, npc)
		end
	end
	return list, count
end

-- Heartbeat loop
RunService.Heartbeat:Connect(function(dt)
	if hrp and hum and hum.Health > 0 then
		if antiWallStuck then
			local velocity = hrp.AssemblyLinearVelocity
			local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			if horizontalSpeed > 2 then
				lastSafePosition = hrp.Position
				wallStuckElapsed = 0
			else
				wallStuckElapsed += dt
			end

			if wallStuckElapsed >= 0.7 then
				local returnPos = lastSafePosition or hrp.Position
				local floorPos = Vector3.new(returnPos.X, returnPos.Y + 4, returnPos.Z)
				pcall(function()
					hrp.CFrame = CFrame.new(floorPos)
				end)
				wallStuckElapsed = 0
			end
		end

		if noAttackAnim then
			for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
				pcall(function()
					track:Stop(0)
				end)
			end
		end
		if farming then
			local npc, npcHRP = getNearestNPC2()
			if npcHRP then
				local targetPos = npcHRP.Position
				if targetPos.Y >= -20 then
					local distance = (targetPos - hrp.Position).Magnitude
					if distance > 60 then
						hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0), targetPos)
					else
						orbitAngle += dt * orbitSpeed
						local offset = Vector3.new(math.cos(orbitAngle), 0, math.sin(orbitAngle)) * orbitRadius
						hrp.CFrame = CFrame.new(targetPos + offset, targetPos)
					end

					local tool = lp.Character:FindFirstChildOfClass("Tool") or lp.Backpack:FindFirstChildOfClass("Tool")
					if tool then
						tool.Parent = lp.Character
						pcall(function()
							tool:Activate()
						end)
					end
				end
			end
		end

		if autoPickup then
			local dropFolder = workspace:FindFirstChild("GiangHo2")
			dropFolder = dropFolder and dropFolder:FindFirstChild("Drop")
			if dropFolder then
				collectDropParts(dropFolder)
			end
		end

		local cityNpcs, cityCount = getCityNPCs()
		if cityFarm then
			if #cityNpcs > 0 then
				if cityNpcIndex > #cityNpcs then
					cityNpcIndex = 1
				end
				local cityNpc = cityNpcs[cityNpcIndex]
				local h = cityNpc and cityNpc:FindFirstChildOfClass("Humanoid")
				local p = cityNpc and cityNpc:FindFirstChild("HumanoidRootPart")
				if h and p and h.Health > 0 then
					local cityPos = p.Position
					if cityPos.Y < -20 then
						cityNpcIndex += 1
					else
						local distance = (cityPos - hrp.Position).Magnitude
						if distance > 60 then
							hrp.CFrame = CFrame.new(cityPos + Vector3.new(0, 3, 0), cityPos)
						else
							orbitAngle += dt * orbitSpeed
							local offset = Vector3.new(math.cos(orbitAngle), 0, math.sin(orbitAngle)) * orbitRadius
							hrp.CFrame = CFrame.new(cityPos + offset, cityPos)
						end
						local tool = lp.Character:FindFirstChildOfClass("Tool") or lp.Backpack:FindFirstChildOfClass("Tool")
						if tool then
							tool.Parent = lp.Character
							pcall(function()
								tool:Activate()
							end)
						end
						if h.Health <= 0 then
							cityNpcIndex += 1
						end
					end
				else
					cityNpcIndex += 1
				end
				if cityNpcIndex > #cityNpcs then
					cityNpcIndex = 1
				end
			end
		end

		if cityPickup then
			local dropFolder = workspace:FindFirstChild("CityNPCs")
			dropFolder = dropFolder and dropFolder:FindFirstChild("Drop")
			if dropFolder then
				collectDropParts(dropFolder)
			end
		end

		-- Update HP
		local npc, _, count = getNearestNPC2()
		if npc and npc:FindFirstChildOfClass("Humanoid") then
			local h = npc:FindFirstChildOfClass("Humanoid")
			hpLabel.Text = "NPC2: " .. math.floor(h.Health) .. " / " .. math.floor(h.MaxHealth)
		else
			hpLabel.Text = "NPC2: Không thấy"
		end
		if count then
			npcCountLabel.Text = "NPC2 còn: " .. tostring(count)
		end
		if cityCount then
			cityCountLabel.Text = "CityNPC còn: " .. tostring(cityCount)
		end
	end
end)
