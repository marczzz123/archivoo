local Players = game:GetService("Players")

local model = script.Parent
local car = model:WaitForChild("TK's Vision GT")
local trigger = model:WaitForChild("Trigger")

local REQUIRED_CHANCE_PERCENT = 10 -- >=10 activa, <10 no hace nada
local TRIGGER_COOLDOWN = 8

local debounce = false

local function getPlayerFromHit(hit)
	if not hit then
		return nil
	end

	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function getCarRoot()
	if car:IsA("Model") then
		if car.PrimaryPart then
			return car.PrimaryPart
		end
		return car:FindFirstChildWhichIsA("BasePart")
	end

	if car:IsA("BasePart") then
		return car
	end

	return nil
end

local function getCarHumanoid()
	if car:IsA("Model") then
		return car:FindFirstChildOfClass("Humanoid")
	end

	return nil
end

local function setCarAnchored(anchored)
	if car:IsA("Model") then
		for _, d in ipairs(car:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = anchored
				d.CanCollide = true
			end
		end
	elseif car:IsA("BasePart") then
		car.Anchored = anchored
		car.CanCollide = true
	end
end

local function launchCar()
	local root = getCarRoot()
	if not root then
		warn("[RAMP CAR TRAP] No se encontró BasePart en TK's Vision GT")
		return
	end

	local humanoid = getCarHumanoid()
	if not humanoid then
		warn("[RAMP CAR TRAP] El carro no tiene Humanoid")
		return
	end

	setCarAnchored(false)
	humanoid:MoveTo(trigger.Position)
end

trigger.Touched:Connect(function(hit)
	if debounce then
		return
	end

	local player = getPlayerFromHit(hit)
	if not player then
		return
	end

	local chance = player:GetAttribute("ChancePercent")
	if typeof(chance) ~= "number" then
		chance = 0
	end

	if chance < REQUIRED_CHANCE_PERCENT then
		return
	end

	debounce = true
	launchCar()
	task.delay(TRIGGER_COOLDOWN, function()
		debounce = false
	end)
end)
