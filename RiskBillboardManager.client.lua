local Players = game:GetService("Players")

-- Function to get color based on percentage
local function getRiskColor(percentage)
	if percentage <= 20 then
		return Color3.new(0, 1, 0) -- Green
	elseif percentage <= 40 then
		return Color3.new(1, 1, 0) -- Yellow
	elseif percentage <= 60 then
		return Color3.new(1, 0.5, 0) -- Orange
	elseif percentage <= 80 then
		return Color3.new(1, 0, 0) -- Red
	else
		return Color3.new(0.5, 0, 0) -- Dark Red
	end
end

-- Function to create BillboardGui for a player
local function createBillboardGui(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Create BillboardGui
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "RiskBillboard"
	billboardGui.Parent = humanoidRootPart
	billboardGui.Size = UDim2.new(0, 100, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.MaxDistance = 50

	-- Create main frame
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Parent = billboardGui
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.Parent = frame
	corner.CornerRadius = UDim.new(0, 8)

	-- Create percentage label
	local label = Instance.new("TextLabel")
	label.Name = "RiskLabel"
	label.Parent = frame
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "0%"
	label.TextColor3 = Color3.new(0, 1, 0)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.new(0, 0, 0)

	-- Function to update billboard
	local function updateBillboard()
		local chance = player:GetAttribute("ChancePercent") or 0
		local color = getRiskColor(chance)

		label.Text = chance .. "%"
		label.TextColor3 = color
		frame.BackgroundColor3 = color:lerp(Color3.new(0, 0, 0), 0.7)
	end

	-- Update when attribute changes
	player:GetAttributeChangedSignal("ChancePercent"):Connect(updateBillboard)

	-- Initial update
	updateBillboard()

	return billboardGui
end

-- Function to handle player character added
local function onCharacterAdded(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Remove existing billboard if any
	local existingBillboard = humanoidRootPart:FindFirstChild("RiskBillboard")
	if existingBillboard then
		existingBillboard:Destroy()
	end

	-- Create new billboard
	createBillboardGui(player)
end

-- Function to handle player added
local function onPlayerAdded(player)
	if player.Character then
		onCharacterAdded(player)
	end

	player.CharacterAdded:Connect(function()
		onCharacterAdded(player)
	end)
end

-- Connect to existing players
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Connect to new players
Players.PlayerAdded:Connect(onPlayerAdded)
