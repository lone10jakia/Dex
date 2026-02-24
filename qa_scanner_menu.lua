-- QA Scanner Menu
-- Menu chỉ tập trung auto trả lời câu hỏi bằng cách quét câu hỏi + đáp án trên màn hình.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui

if playerGui:FindFirstChild("QAScannerMenu") then
	playerGui.QAScannerMenu:Destroy()
end

local autoAnswerEnabled = false
local autoAnswerLoopRunning = false
local menuVisible = true
local stealthHideEnabled = false
local autoHideBusy = false
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

local semanticRules = {
	{
		questionKeywords = {"goc", "angle"},
		answerKeywords = {"phai", "phải", "vuong", "vuông", "right", "right angle"},
	},
}

local function removeVietnameseDiacritics(text)
	local replaces = {
		{"à", "a"}, {"á", "a"}, {"ả", "a"}, {"ã", "a"}, {"ạ", "a"},
		{"ă", "a"}, {"ằ", "a"}, {"ắ", "a"}, {"ẳ", "a"}, {"ẵ", "a"}, {"ặ", "a"},
		{"â", "a"}, {"ầ", "a"}, {"ấ", "a"}, {"ẩ", "a"}, {"ẫ", "a"}, {"ậ", "a"},
		{"è", "e"}, {"é", "e"}, {"ẻ", "e"}, {"ẽ", "e"}, {"ẹ", "e"},
		{"ê", "e"}, {"ề", "e"}, {"ế", "e"}, {"ể", "e"}, {"ễ", "e"}, {"ệ", "e"},
		{"ì", "i"}, {"í", "i"}, {"ỉ", "i"}, {"ĩ", "i"}, {"ị", "i"},
		{"ò", "o"}, {"ó", "o"}, {"ỏ", "o"}, {"õ", "o"}, {"ọ", "o"},
		{"ô", "o"}, {"ồ", "o"}, {"ố", "o"}, {"ổ", "o"}, {"ỗ", "o"}, {"ộ", "o"},
		{"ơ", "o"}, {"ờ", "o"}, {"ớ", "o"}, {"ở", "o"}, {"ỡ", "o"}, {"ợ", "o"},
		{"ù", "u"}, {"ú", "u"}, {"ủ", "u"}, {"ũ", "u"}, {"ụ", "u"},
		{"ư", "u"}, {"ừ", "u"}, {"ứ", "u"}, {"ử", "u"}, {"ữ", "u"}, {"ự", "u"},
		{"ỳ", "y"}, {"ý", "y"}, {"ỷ", "y"}, {"ỹ", "y"}, {"ỵ", "y"},
		{"đ", "d"},
	}
	for _, pair in ipairs(replaces) do
		text = text:gsub(pair[1], pair[2])
	end
	return text
end

local function normalize(text)
	text = tostring(text or ""):lower()
	text = removeVietnameseDiacritics(text)
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
	expr = tostring(expr or "")
	expr = expr:gsub("×", "*"):gsub("x", "*"):gsub("X", "*"):gsub("÷", "/")
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
	expr = expr:gsub("×", "*"):gsub("x", "*"):gsub("X", "*"):gsub("÷", "/")
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

local function isLikelyMathQuestion(questionText)
	local q = normalize(questionText)
	if q:find("dien tich", 1, true) or q:find("area", 1, true) or q:find("fraction", 1, true)
		or q:find("phan", 1, true) then
		return true
	end
	if tostring(questionText or ""):find("[%d][%s]*[%+%-%*/=][%s]*[%d]") then
		return true
	end
	return tostring(questionText or ""):find("%d") ~= nil
end

local function extractGeometryTarget(questionText, questionLabel)
	local q = normalize(questionText)
	if not (q:find("dien tich", 1, true) or q:find("area", 1, true) or q:find("shape", 1, true) or q:find("hinh", 1, true)) then
		return nil
	end
	if not questionLabel then
		return nil
	end

	local xMin = questionLabel.AbsolutePosition.X - 260
	local xMax = questionLabel.AbsolutePosition.X + questionLabel.AbsoluteSize.X + 260
	local yMin = questionLabel.AbsolutePosition.Y - 20
	local yMax = questionLabel.AbsolutePosition.Y + 220

	local nums = {}
	local freq = {}
	for _, node in ipairs(playerGui:GetDescendants()) do
		if node:IsA("TextLabel") and node.Visible and (not gui or not node:IsDescendantOf(gui)) then
			local text = tostring(node.Text or "")
			if #text <= 4 and text:match("^%s*%-?%d+%.?%d*%s*$") then
				local cx = node.AbsolutePosition.X + node.AbsoluteSize.X / 2
				local cy = node.AbsolutePosition.Y + node.AbsoluteSize.Y / 2
				if cx >= xMin and cx <= xMax and cy >= yMin and cy <= yMax then
					local v = tonumber(text)
					if v and math.abs(v) <= 1000 and node.AbsoluteSize.X >= 8 and node.AbsoluteSize.Y >= 8 then
						table.insert(nums, v)
						freq[v] = (freq[v] or 0) + 1
					end
				end
			end
		end
	end

	if #nums < 2 then
		return nil
	end

	table.sort(nums)

	local frequent = {}
	for value, count in pairs(freq) do
		table.insert(frequent, {value = value, count = count})
	end
	table.sort(frequent, function(a, b)
		if a.count == b.count then
			return math.abs(a.value) < math.abs(b.value)
		end
		return a.count > b.count
	end)

	local a, b
	if #frequent >= 2 then
		a, b = frequent[1].value, frequent[2].value
	elseif #frequent == 1 then
		a, b = frequent[1].value, frequent[1].value
	else
		a, b = nums[1], nums[2]
	end

	return (a * b) / 2
end

local function findNearbyHintText(questionLabel)
	if not questionLabel then
		return ""
	end
	local qX = questionLabel.AbsolutePosition.X
	local qY = questionLabel.AbsolutePosition.Y
	local qW = questionLabel.AbsoluteSize.X
	local qH = questionLabel.AbsoluteSize.Y

	local best = ""
	for _, node in ipairs(playerGui:GetDescendants()) do
		if node:IsA("TextLabel") and node.Visible and (not gui or not node:IsDescendantOf(gui)) then
			local text = tostring(node.Text or "")
			local n = normalize(text)
			if n:find("goi y", 1, true) or n:find("hint", 1, true) then
				local cx = node.AbsolutePosition.X + node.AbsoluteSize.X / 2
				local cy = node.AbsolutePosition.Y + node.AbsoluteSize.Y / 2
				if cx >= qX - 300 and cx <= qX + qW + 300 and cy >= qY + qH and cy <= qY + qH + 420 then
					if #text > #best then
						best = text
					end
				end
			end
		end
	end
	return best
end

local function extractQuestionTarget(questionText, questionLabel)
	local raw = tostring(questionText or "")
	local sequencePart = raw:match("([%d%s,%.%-]+%?)") or raw
	local sequenceNumbers = {}
	for n in sequencePart:gmatch("%-?%d+%.?%d*") do
		table.insert(sequenceNumbers, tonumber(n))
	end
	if #sequenceNumbers >= 3 and raw:find("%?") then
		local last = sequenceNumbers[#sequenceNumbers]
		local prev = sequenceNumbers[#sequenceNumbers - 1]
		local prev2 = sequenceNumbers[#sequenceNumbers - 2]
		if last and prev and prev2 then
			local d1 = last - prev
			local d2 = prev - prev2
			if math.abs(d1 - d2) <= 0.001 then
				return last + d1
			end
		end
	end

	if raw:find("%?") and #sequenceNumbers >= 2 then
		local hintText = findNearbyHintText(questionLabel)
		local hintDelta = hintText:match("thay doi%s*(%-?%d+%.?%d*)") or hintText:match("change%s*by%s*(%-?%d+%.?%d*)")
		if hintDelta then
			local delta = tonumber(hintDelta)
			if delta then
				return sequenceNumbers[#sequenceNumbers] + delta
			end
		end
	end

	local q = normalize(raw)
	if q:find("lam tron", 1, true) or q:find("round", 1, true) then
		local value = raw:match("(%-?%d+%.%d+)")
		if value then
			local n = tonumber(value)
			if n then
				if n >= 0 then
					return math.floor(n + 0.5)
				else
					return math.ceil(n - 0.5)
				end
			end
		end
	end

	local pct = raw:match("(%-?%d+%.?%d*)%%")
	if pct then
		return tonumber(pct) / 100
	end
	local leftExpr = raw:match("([%d%.%s%+%-%*/×xX÷%(%)]+)%s*=%s*%?+")
	if leftExpr then
		local calc = evaluateExpression(leftExpr)
		if calc ~= nil then
			return calc
		end
	end
	local geometry = extractGeometryTarget(questionText, questionLabel)
	if geometry ~= nil then
		return geometry
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



local function getButtonDisplayText(node)
	if node:IsA("TextButton") then
		return tostring(node.Text or "")
	end
	local best = ""
	for _, d in ipairs(node:GetDescendants()) do
		if d:IsA("TextLabel") and d.Visible then
			local txt = tostring(d.Text or "")
			if #txt > #best then
				best = txt
			end
		end
	end
	return best
end
local function collectVisibleAnswerButtons(root, questionText)
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
		if t:match("^%-?%d+/%d+$") or t:match("^%-?%d+%%$") then
			return true
		end
		return #t <= 32
	end

	local candidates = {}
	for _, node in ipairs(playerGui:GetDescendants()) do
		if (node:IsA("TextButton") or node:IsA("ImageButton")) and node.Visible and (not gui or not node:IsDescendantOf(gui)) then
			local txt = getButtonDisplayText(node)
			if looksLikeGameAnswer(txt) then
				local cX = node.AbsolutePosition.X + node.AbsoluteSize.X / 2
				local cY = node.AbsolutePosition.Y + node.AbsoluteSize.Y / 2
				if cY < qBottomY + 35 or cY > qBottomY + 430 or math.abs(cX - qCenterX) > 560 then
					continue
				end
				local score = 0
				local numeric = parseNumericValue(txt)
				if numeric ~= nil then score = score + 10 end
				if node.AbsoluteSize.X >= 90 and node.AbsoluteSize.Y >= 40 then score = score + 2 end
				if cY > qBottomY then score = score + 2 else score = score - 3 end
				-- ưu tiên cụm đáp án ngay bên dưới câu hỏi
				score = score - math.abs(cY - (qBottomY + 150)) / 180
				score = score - math.abs(cX - qCenterX) / 260
				table.insert(candidates, {node = node, score = score, numeric = numeric, text = txt, y = cY})
			end
		end
	end

	table.sort(candidates, function(a, b)
		return a.score > b.score
	end)

	local picked = {}
	local numericCount = 0
	for i = 1, math.min(12, #candidates) do
		local c = candidates[i]
		table.insert(picked, c)
		if c.numeric ~= nil then
			numericCount = numericCount + 1
		end
	end

	local parentBuckets = {}
	for _, c in ipairs(picked) do
		local parent = c.node.Parent
		parentBuckets[parent] = (parentBuckets[parent] or 0) + 1
	end
	local bestParent, bestParentCount = nil, -1
	for parent, count in pairs(parentBuckets) do
		if count > bestParentCount then
			bestParentCount = count
			bestParent = parent
		end
	end
	if bestParent and bestParentCount >= 2 then
		local parentFiltered = {}
		for _, c in ipairs(picked) do
			if c.node.Parent == bestParent then
				table.insert(parentFiltered, c)
			end
		end
		if #parentFiltered >= 2 then
			picked = parentFiltered
		end
	end

	local rowBuckets = {}
	for _, c in ipairs(picked) do
		local bucket = math.floor(c.y / 35 + 0.5)
		rowBuckets[bucket] = (rowBuckets[bucket] or 0) + 1
	end
	local bestBucket, bestCount = nil, -1
	for bucket, count in pairs(rowBuckets) do
		if count > bestCount then
			bestCount = count
			bestBucket = bucket
		end
	end
	if bestBucket then
		local rowFiltered = {}
		for _, c in ipairs(picked) do
			local bucket = math.floor(c.y / 35 + 0.5)
			if math.abs(bucket - bestBucket) <= 1 then
				table.insert(rowFiltered, c)
			end
		end
		if #rowFiltered >= 2 then
			picked = rowFiltered
		end
	end

	if numericCount >= 2 then
		for _, c in ipairs(picked) do
			if c.numeric ~= nil then
				table.insert(result, c.node)
			end
		end
	else
		for _, c in ipairs(picked) do
			table.insert(result, c.node)
		end
	end

	if isLikelyMathQuestion(questionText or "") then
		local numericOnly = {}
		for _, button in ipairs(result) do
			if parseNumericValue(getButtonDisplayText(button)) ~= nil then
				table.insert(numericOnly, button)
			end
		end
		if #numericOnly >= 2 then
			result = numericOnly
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

local function buttonMatchesAnyKeyword(button, keywords)
	local text = normalize(getButtonDisplayText(button))
	for _, keyword in ipairs(keywords) do
		if text:find(keyword, 1, true) then
			return true
		end
	end
	return false
end

local function chooseBySemanticRules(questionText, buttons)
	local q = normalize(questionText)
	for _, rule in ipairs(semanticRules) do
		local questionHit = false
		for _, keyword in ipairs(rule.questionKeywords) do
			if q:find(keyword, 1, true) then
				questionHit = true
				break
			end
		end
		if questionHit then
			for _, button in ipairs(buttons) do
				if buttonMatchesAnyKeyword(button, rule.answerKeywords) then
					return button
				end
			end
		end
	end
	return nil
end

local function hideMenuBriefly(seconds)
	if not gui then
		return
	end
	if not stealthHideEnabled then
		return
	end
	if not menuVisible then
		return
	end
	if autoHideBusy then
		return
	end
	autoHideBusy = true
	gui.Enabled = false
	task.delay(seconds or 1, function()
		if gui and gui.Parent and menuVisible then
			gui.Enabled = true
		end
		autoHideBusy = false
	end)
end

local function chooseBestAnswer(questionText, questionLabel, buttons)
	if #buttons == 0 then
		return nil
	end

	if isLikelyMathQuestion(questionText) then
		local numericButtons = {}
		for _, button in ipairs(buttons) do
			if parseNumericValue(getButtonDisplayText(button)) ~= nil then
				table.insert(numericButtons, button)
			end
		end
		if #numericButtons >= 2 then
			buttons = numericButtons
		end
	end

	local questionTarget = extractQuestionTarget(questionText, questionLabel)

	if questionTarget then
		local bestButton
		local bestDelta = math.huge
		for _, button in ipairs(buttons) do
			local value = parseNumericValue(getButtonDisplayText(button))
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

	local semanticPick = chooseBySemanticRules(questionText, buttons)
	if semanticPick then
		return semanticPick
	end

	local preferredAnswer = findRuleAnswer(questionText)
	if preferredAnswer then
		local winner
		local best = -1
		for _, button in ipairs(buttons) do
			local score = overlapScore(getButtonDisplayText(button), preferredAnswer)
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
		local score = overlapScore(questionText, getButtonDisplayText(button))
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
	local answerButtons = collectVisibleAnswerButtons(questionLabel, questionText)
	local picked = chooseBestAnswer(questionText, questionLabel, answerButtons)
	if not picked then
		statusLabel.Text = "Không tìm thấy đáp án."
		return
	end

	local questionKey = normalize(questionText)
	local pickedText = getButtonDisplayText(picked)
	if questionKey == lastQuestionKey and normalize(pickedText) == lastAnsweredText and (time() - lastAnswerTime) < 1.2 then
		statusLabel.Text = string.format("Đang chờ câu mới... (%s)", pickedText)
		return
	end

	if clickButton(picked) then
		hideMenuBriefly(1)
		statusLabel.Text = string.format("Đã chọn: %s", pickedText)
		lastQuestionKey = questionKey
		lastAnsweredText = normalize(pickedText)
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

local hideToggle = Instance.new("TextButton")
hideToggle.Size = UDim2.new(0, 34, 0, 26)
hideToggle.Position = UDim2.new(1, -44, 0, 8)
hideToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 85)
hideToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
hideToggle.Font = Enum.Font.GothamBold
hideToggle.TextSize = 12
hideToggle.Text = "ẨN"
hideToggle.Parent = frame

local hideToggleCorner = Instance.new("UICorner")
hideToggleCorner.CornerRadius = UDim.new(0, 6)
hideToggleCorner.Parent = hideToggle

local stealthToggle = Instance.new("TextButton")
stealthToggle.Size = UDim2.new(0, 105, 0, 26)
stealthToggle.Position = UDim2.new(1, -154, 0, 8)
stealthToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 85)
stealthToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
stealthToggle.Font = Enum.Font.GothamBold
stealthToggle.TextSize = 12
stealthToggle.Text = "Stealth: OFF"
stealthToggle.Parent = frame

local stealthCorner = Instance.new("UICorner")
stealthCorner.CornerRadius = UDim.new(0, 6)
stealthCorner.Parent = stealthToggle

scanNow.MouseButton1Click:Connect(function()
	autoAnswerStep(status)
end)

local function setAutoAnswer(state)
	autoAnswerEnabled = state

	if autoAnswerEnabled then
		toggle.Text = "Tắt Auto Trả Lời"
		toggle.BackgroundColor3 = Color3.fromRGB(220, 70, 95)
		status.Text = "Đang tự động quét câu hỏi..."
		if not autoAnswerLoopRunning then
			autoAnswerLoopRunning = true
			task.spawn(function()
				while autoAnswerEnabled and gui and gui.Parent do
					autoAnswerStep(status)
					task.wait(0.12)
				end
				autoAnswerLoopRunning = false
			end)
		end
	else
		toggle.Text = "Bật Auto Trả Lời"
		toggle.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
		status.Text = "Đã tắt auto."
	end
end

toggle.MouseButton1Click:Connect(function()
	setAutoAnswer(not autoAnswerEnabled)
end)

hideToggle.MouseButton1Click:Connect(function()
	menuVisible = not menuVisible
	gui.Enabled = menuVisible
	hideToggle.Text = menuVisible and "ẨN" or "HIỆN"
end)

stealthToggle.MouseButton1Click:Connect(function()
	stealthHideEnabled = not stealthHideEnabled
	stealthToggle.Text = stealthHideEnabled and "Stealth: ON" or "Stealth: OFF"
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightControl then
		menuVisible = not menuVisible
		gui.Enabled = menuVisible
		hideToggle.Text = menuVisible and "ẨN" or "HIỆN"
	end
end)

player.AncestryChanged:Connect(function(_, parent)
	if not parent then
		autoAnswerEnabled = false
	end
end)
