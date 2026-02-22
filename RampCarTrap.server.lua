local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local model = script.Parent
local trigger = model:WaitForChild("Trigger")
local carSpawn = model:WaitForChild("CarSpawn")

local REQUIRED_CHANCE_PERCENT = 3
local TRIGGER_COOLDOWN = 8

local DAMAGE = 40
local MIN_SPEED_TO_DAMAGE = 20
local CAR_LIFETIME = 5
local RESPAWN_DELAY = 6 -- < TRIGGER_COOLDOWN para que el carro esté listo antes del reset

local debounce = false
local trapActive = false

local carTemplate = ReplicatedStorage:WaitForChild("Police Car")

local currentCar = nil
local chassisModule = nil

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

local function isCurrentCarValid()
	return currentCar and currentCar.Parent ~= nil
end

local function clearCurrentCar()
	if currentCar and currentCar.Parent then
		currentCar:Destroy()
	end
	currentCar = nil
	chassisModule = nil
end

local function connectDamageHitbox(carModel)
	local body = carModel:WaitForChild("Body")

	body.Touched:Connect(function(hit)
		if not trapActive or not chassisModule then
			return
		end

		local character = hit:FindFirstAncestorOfClass("Model")
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local speed = chassisModule.GetAverageVelocity()
		if speed >= MIN_SPEED_TO_DAMAGE then
			humanoid:TakeDamage(DAMAGE)
		end
	end)
end

local function spawnCar()
	if isCurrentCarValid() then
		return
	end

	currentCar = carTemplate:Clone()
	currentCar.Parent = workspace
	currentCar:PivotTo(carSpawn.CFrame)

	chassisModule = require(currentCar:WaitForChild("Scripts"):WaitForChild("Chassis"))
	connectDamageHitbox(currentCar)
end

local function launchCar()
	if not isCurrentCarValid() or not chassisModule then
		return
	end

	trapActive = true

	local currentSpeed = chassisModule.GetAverageVelocity()
	chassisModule.UpdateThrottle(currentSpeed, 1)

	task.delay(3, function()
		if chassisModule and isCurrentCarValid() then
			chassisModule.EnableHandbrake()
		end
		trapActive = false
	end)

	Debris:AddItem(currentCar, CAR_LIFETIME)

	task.delay(RESPAWN_DELAY, function()
		clearCurrentCar()
		spawnCar()
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

	if not isCurrentCarValid() then
		spawnCar()
	end
	if not isCurrentCarValid() then
		return
	end

	debounce = true
	launchCar()

	task.delay(TRIGGER_COOLDOWN, function()
		if not isCurrentCarValid() then
			spawnCar()
		end
		debounce = false
	end)
end)

spawnCar()
