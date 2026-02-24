-- QA Scanner Menu
-- Menu chỉ tập trung auto trả lời câu hỏi bằng cách quét câu hỏi + đáp án trên màn hình.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("QAScannerMenu") then
	playerGui.QAScannerMenu:Destroy()
end

local autoAnswerEnabled = false
local autoAnswerConnection

local questionAnswerRules = {
	{question = "thu do viet nam", answer = "ha noi"},
	{question = "2+2", answer = "4"},
	{question = "mau do", answer = "red"},
	{question = "water", answer = "h2o"},
	{question = "largest planet", answer = "jupiter"},
}

local function normalize(text)
	text = tostring(text or ""):lower()
	text = text:gsub("[%c%p]", " ")
	text = text:gsub("%s+", " ")
	return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function tokenize(text)
	local tokens = {}
	for token in normalize(text):gmatch("%S+") do
		tokens[token] = true
	end
	return tokens
end

local function overlapScore(a, b)
	local ta = tokenize(a)
	local tb = tokenize(b)
	local score = 0
	for token in pairs(ta) do
		if tb[token] then
			score += 1
		end
	end
	return score
end

local function findVisibleQuestionLabel()
	local bestLabel
	local bestLength = 0
	for _, node in ipairs(playerGui:GetDescendants()) do
		if node:IsA("TextLabel") and node.Visible and node.AbsoluteSize.Magnitude > 20 then
			local txt = normalize(node.Text)
			if txt ~= "" and (txt:find("?") or txt:find("cau hoi") or txt:find("question")) then
				if #txt > bestLength then
					bestLength = #txt
					bestLabel = node
				end
			end
		end
	end
	return bestLabel
end

local function collectVisibleAnswerButtons(root)
	local result = {}
	if not root then
		return result
	end

	local parent = root.Parent
	if not parent then
		return result
	end

	for _, node in ipairs(parent:GetDescendants()) do
		if node:IsA("TextButton") and node.Visible and normalize(node.Text) ~= "" then
			table.insert(result, node)
		end
	end

	if #result == 0 then
		for _, node in ipairs(playerGui:GetDescendants()) do
			if node:IsA("TextButton") and node.Visible and normalize(node.Text) ~= "" then
				table.insert(result, node)
			end
		end
	end

	return result
end

local function findRuleAnswer(questionText)
	local q = normalize(questionText)
	for _, rule in ipairs(questionAnswerRules) do
		if q:find(rule.question, 1, true) then
			return rule.answer
		end
	end
	return nil
end

local function chooseBestAnswer(questionText, buttons)
	if #buttons == 0 then
		return nil
	end

	local preferredAnswer = findRuleAnswer(questionText)
	if preferredAnswer then
		local winner
		local best = -1
		for _, button in ipairs(buttons) do
			local score = overlapScore(button.Text, preferredAnswer)
			if score > best then
				best = score
				winner = button
			end
		end
		if winner then
			return winner
		end
	end

	local fallback
	local bestScore = -1
	for _, button in ipairs(buttons) do
		local score = overlapScore(questionText, button.Text)
		if score > bestScore then
			bestScore = score
			fallback = button
		end
	end

	return fallback or buttons[1]
end

local function clickButton(button)
	if not button then
		return false
	end

	local clicked = false
	pcall(function()
		button:Activate()
		clicked = true
	end)

	if firesignal then
		pcall(function()
			firesignal(button.MouseButton1Click)
			clicked = true
		end)
	end

	return clicked
end

local function autoAnswerStep(statusLabel)
	local questionLabel = findVisibleQuestionLabel()
	if not questionLabel then
		statusLabel.Text = "Không thấy câu hỏi."
		return
	end

	local questionText = questionLabel.Text
	local answerButtons = collectVisibleAnswerButtons(questionLabel)
	local picked = chooseBestAnswer(questionText, answerButtons)
	if not picked then
		statusLabel.Text = "Không tìm thấy đáp án."
		return
	end

	if clickButton(picked) then
		statusLabel.Text = string.format("Đã chọn: %s", picked.Text)
	else
		statusLabel.Text = "Không thể bấm đáp án."
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "QAScannerMenu"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 150)
frame.Position = UDim2.new(0.5, -160, 0.15, 0)
frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "QA Scanner Menu"
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(240, 240, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 44)
status.Position = UDim2.new(0, 10, 0, 44)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.Text = "Sẵn sàng quét câu hỏi..."
status.TextWrapped = true
status.TextSize = 13
status.TextColor3 = Color3.fromRGB(190, 200, 220)
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 145, 0, 34)
toggle.Position = UDim2.new(0, 10, 1, -44)
toggle.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.Font = Enum.Font.GothamSemibold
toggle.TextSize = 13
toggle.Text = "Bật Auto Trả Lời"
toggle.Parent = frame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggle

local scanNow = Instance.new("TextButton")
scanNow.Size = UDim2.new(0, 145, 0, 34)
scanNow.Position = UDim2.new(1, -155, 1, -44)
scanNow.BackgroundColor3 = Color3.fromRGB(85, 85, 110)
scanNow.TextColor3 = Color3.fromRGB(255, 255, 255)
scanNow.Font = Enum.Font.GothamSemibold
scanNow.TextSize = 13
scanNow.Text = "Quét & Chọn Ngay"
scanNow.Parent = frame

local scanNowCorner = Instance.new("UICorner")
scanNowCorner.CornerRadius = UDim.new(0, 8)
scanNowCorner.Parent = scanNow

scanNow.MouseButton1Click:Connect(function()
	autoAnswerStep(status)
end)

local function setAutoAnswer(state)
	autoAnswerEnabled = state
	if autoAnswerConnection then
		autoAnswerConnection:Disconnect()
		autoAnswerConnection = nil
	end

	if autoAnswerEnabled then
		toggle.Text = "Tắt Auto Trả Lời"
		toggle.BackgroundColor3 = Color3.fromRGB(220, 70, 95)
		status.Text = "Đang tự động quét câu hỏi..."
		autoAnswerConnection = RunService.Heartbeat:Connect(function()
			autoAnswerStep(status)
			task.wait(0.75)
		end)
	else
		toggle.Text = "Bật Auto Trả Lời"
		toggle.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
		status.Text = "Đã tắt auto."
	end
end

toggle.MouseButton1Click:Connect(function()
	setAutoAnswer(not autoAnswerEnabled)
end)

player.AncestryChanged:Connect(function(_, parent)
	if not parent and autoAnswerConnection then
		autoAnswerConnection:Disconnect()
		autoAnswerConnection = nil
	end
end)
