local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local model = script.Parent
local trigger = model:WaitForChild("Trigger")
local spawnPart = model:WaitForChild("Spawn")

local REQUIRED_CHANCE_PERCENT = 3
local TRIGGER_COOLDOWN = 8

local DAMAGE = 100
local FRIDGE_LIFETIME = 4
local ACTIVE_DAMAGE_TIME = 1.5
local SPAWN_RANDOM_XZ = 2 -- menos predecible

local debounce = false
local trapActive = false

local fridgeTemplate = ReplicatedStorage:WaitForChild("Refri")
local currentFridge = nil

local function getPlayerFromHit(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function clearFridge()
	if currentFridge and currentFridge.Parent then
		currentFridge:Destroy()
	end
	currentFridge = nil
end

local function weldModel(modelToWeld)
	local primary = modelToWeld.PrimaryPart or modelToWeld:FindFirstChildWhichIsA("BasePart")
	if not primary then
		warn("[FRIDGE TRAP] El Refri necesita al menos una BasePart")
		return false
	end

	modelToWeld.PrimaryPart = primary

	for _, part in ipairs(modelToWeld:GetDescendants()) do
		if part:IsA("BasePart") and part ~= primary then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primary
			weld.Part1 = part
			weld.Parent = primary
		end
	end

	return true
end

local function setModelAnchored(modelToSet, anchored)
	for _, part in ipairs(modelToSet:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = anchored
			part.CanCollide = true
		end
	end
end

local function connectImpactDamage(fridge)
	local hitbox = fridge.PrimaryPart
	if not hitbox then
		return
	end

	local damaged = {}

	task.spawn(function()
		while trapActive and fridge.Parent do
			local parts = workspace:GetPartsInPart(hitbox)

			for _, part in ipairs(parts) do
				local character = part:FindFirstAncestorOfClass("Model")
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 and not damaged[humanoid] then
						damaged[humanoid] = true
						humanoid:TakeDamage(DAMAGE)
					end
				end
			end

			task.wait(0.03)
		end
	end)
end
local function getSpawnCFrame()
	local offset = Vector3.new(
		math.random(-SPAWN_RANDOM_XZ, SPAWN_RANDOM_XZ),
		0,
		math.random(-SPAWN_RANDOM_XZ, SPAWN_RANDOM_XZ)
	)
	return spawnPart.CFrame + offset
end

local function spawnAndDropFridge()
	clearFridge()

	local fridge = fridgeTemplate:Clone()
	if not weldModel(fridge) then
		fridge:Destroy()
		return
	end

	setModelAnchored(fridge, true)
	fridge:PivotTo(getSpawnCFrame())
	fridge.Parent = workspace
	currentFridge = fridge

	trapActive = true
	connectImpactDamage(fridge)
	setModelAnchored(fridge, false)

	task.delay(ACTIVE_DAMAGE_TIME, function()
		trapActive = false
	end)

	task.delay(FRIDGE_LIFETIME, function()
		clearFridge()
	end)
end

trigger.Touched:Connect(function(hit)
	if debounce then
		return
	end

	local player = getPlayerFromHit(hit)
	if not player then
		return
	end

	local chance = player:GetAttribute("ChancePercent") or 0
	if chance < REQUIRED_CHANCE_PERCENT then
		return
	end

	debounce = true
	spawnAndDropFridge()

	task.delay(TRIGGER_COOLDOWN, function()
		debounce = false
	end)
end)
