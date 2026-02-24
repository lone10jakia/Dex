-- QA Scanner Menu
-- Menu chỉ tập trung auto trả lời câu hỏi bằng cách quét câu hỏi + đáp án trên màn hình.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui

if playerGui:FindFirstChild("QAScannerMenu") then
	playerGui.QAScannerMenu:Destroy()
end

local autoAnswerEnabled = false
local autoAnswerConnection
local lastQuestionKey = ""
local lastAnsweredText = ""
local lastAnswerTime = 0

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



local function parseNumericValue(text)
	local cleaned = normalize(text):gsub(" ", "")
	local a, b = cleaned:match("^(%-?%d+)%/(%-?%d+)$")
	if a and b then
		local den = tonumber(b)
		if den and den ~= 0 then
			return tonumber(a) / den
		end
	end
	local pct = cleaned:match("^(%-?%d+%.?%d*)%%$")
	if pct then
		return tonumber(pct) / 100
	end
	local n = tonumber(cleaned)
	if n then
		return n
	end
	return nil
end

local function tokenizeExpression(expr)
	local tokens = {}
	local i = 1
	while i <= #expr do
		local ch = expr:sub(i, i)
		if ch:match("%s") then
			i = i + 1
		elseif ch:match("[%+%-%*/%(%)]") then
			table.insert(tokens, ch)
			i = i + 1
		else
			local num = expr:match("^%d+%.?%d*", i) or expr:match("^%.%d+", i)
			if not num then
				return nil
			end
			table.insert(tokens, tonumber(num))
			i = i + #num
		end
	end
	return tokens
end

local function evaluateExpression(expr)
	if type(expr) ~= "string" or expr == "" then
		return nil
	end
	local tokens = tokenizeExpression(expr)
	if not tokens or #tokens == 0 then
		return nil
	end
	local pos = 1
	local parseExpr, parseTerm, parseFactor
	local function cur() return tokens[pos] end
	parseFactor = function()
		local t = cur()
		if t == nil then return nil end
		if t == "(" then
			pos = pos + 1
			local v = parseExpr()
			if cur() ~= ")" then return nil end
			pos = pos + 1
			return v
		elseif t == "+" then
			pos = pos + 1
			return parseFactor()
		elseif t == "-" then
			pos = pos + 1
			local v = parseFactor()
			return v and -v or nil
		elseif type(t) == "number" then
			pos = pos + 1
			return t
		end
		return nil
	end
	parseTerm = function()
		local v = parseFactor()
		if v == nil then return nil end
		while true do
			local t = cur()
			if t == "*" or t == "/" then
				pos = pos + 1
				local rhs = parseFactor()
				if rhs == nil then return nil end
				if t == "*" then
					v = v * rhs
				else
					if rhs == 0 then return nil end
					v = v / rhs
				end
			else
				break
			end
		end
		return v
	end
	parseExpr = function()
		local v = parseTerm()
		if v == nil then return nil end
		while true do
			local t = cur()
			if t == "+" or t == "-" then
				pos = pos + 1
				local rhs = parseTerm()
				if rhs == nil then return nil end
				if t == "+" then v = v + rhs else v = v - rhs end
			else
				break
			end
		end
		return v
	end
	local result = parseExpr()
	if result == nil or pos <= #tokens then return nil end
	return result
end

local function extractQuestionTarget(questionText)
	local raw = tostring(questionText or "")
	local pct = raw:match("(%-?%d+%.?%d*)%%")
	if pct then
		return tonumber(pct) / 100
	end
	local leftExpr = raw:match("([%d%.%s%+%-%*/%(%)]+)%s*=%s*%?+")
	if leftExpr then
		local calc = evaluateExpression(leftExpr)
		if calc ~= nil then
			return calc
		end
	end
	return parseNumericValue(raw)
end
local function findVisibleQuestionLabel()
	local bestLabel
	local bestScore = -1
	for _, node in ipairs(playerGui:GetDescendants()) do
		if node:IsA("TextLabel") and node.Visible and node.AbsoluteSize.Magnitude > 20 then
			local rawText = tostring(node.Text or "")
			local txt = normalize(rawText)
			if txt ~= "" then
				local score = 0
				if rawText:find("%?") then score += 4 end
				if rawText:find("=") then score += 5 end
				if rawText:find("%%") then score += 5 end
				if txt:find("cau hoi", 1, true) or txt:find("question", 1, true) then score += 2 end
				if txt:find("so phan", 1, true) or txt:find("fraction", 1, true) then score += 3 end
				score += math.min(#txt, 120) / 100
				if score > bestScore then
					bestScore = score
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

	local qCenterX = root.AbsolutePosition.X + root.AbsoluteSize.X / 2
	local qBottomY = root.AbsolutePosition.Y + root.AbsoluteSize.Y

	local function looksLikeGameAnswer(text)
		local t = normalize(text)
		if t == "" then
			return false
		end
		if t:find("cua hang", 1, true) or t:find("cai dat", 1, true) or t:find("danh gia", 1, true)
			or t:find("chon cau hoi", 1, true) or t:find("nhay", 1, true) or t:find("auto", 1, true)
			or t:find("quet", 1, true) or t:find("menu", 1, true) then
			return false
		end
		if parseNumericValue(t) ~= nil then
			return true
		end
		if t:match("^%d+/%d+$") or t:match("^%d+%%$") then
			return true
		end
		return #t <= 16
	end

	local candidates = {}
	for _, node in ipairs(playerGui:GetDescendants()) do
		if node:IsA("TextButton") and node.Visible and (not gui or not node:IsDescendantOf(gui)) then
			local txt = tostring(node.Text or "")
			if looksLikeGameAnswer(txt) then
				local cX = node.AbsolutePosition.X + node.AbsoluteSize.X / 2
				local cY = node.AbsolutePosition.Y + node.AbsoluteSize.Y / 2
				local score = 0
				if parseNumericValue(txt) ~= nil then score = score + 8 end
				if node.AbsoluteSize.X >= 70 and node.AbsoluteSize.Y >= 35 then score = score + 2 end
				if cY > qBottomY then score = score + 2 else score = score - 2 end
				score = score - math.abs(cX - qCenterX) / 220
				score = score - math.abs(cY - (qBottomY + 120)) / 260
				table.insert(candidates, {node = node, score = score})
			end
		end
	end

	table.sort(candidates, function(a, b)
		return a.score > b.score
	end)

	for i = 1, math.min(8, #candidates) do
		table.insert(result, candidates[i].node)
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

	local questionTarget = extractQuestionTarget(questionText)

	if questionTarget then
		local bestButton
		local bestDelta = math.huge
		for _, button in ipairs(buttons) do
			local value = parseNumericValue(button.Text)
			if value ~= nil then
				local delta = math.abs(value - questionTarget)
				if delta < bestDelta then
					bestDelta = delta
					bestButton = button
				end
			end
		end
		if bestButton then
			return bestButton
		end
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

	local questionKey = normalize(questionText)
	if questionKey == lastQuestionKey and normalize(picked.Text) == lastAnsweredText and (time() - lastAnswerTime) < 1.2 then
		statusLabel.Text = string.format("Đang chờ câu mới... (%s)", picked.Text)
		return
	end

	if clickButton(picked) then
		statusLabel.Text = string.format("Đã chọn: %s", picked.Text)
		lastQuestionKey = questionKey
		lastAnsweredText = normalize(picked.Text)
		lastAnswerTime = time()
	else
		statusLabel.Text = "Không thể bấm đáp án."
	end
end

gui = Instance.new("ScreenGui")
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
