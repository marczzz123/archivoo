local Players = game:GetService("Players")

local model = script.Parent
local car = model:WaitForChild("TK's Vision GT")
local trigger = model:WaitForChild("Trigger")

local REQUIRED_CHANCE_PERCENT = 10 -- >=10 activa, <10 no hace nada
local TRIGGER_COOLDOWN = 8
local LAUNCH_SPEED = 35 -- empuje inicial base
local USE_PHYSICS_IMPULSE = true
local IMPULSE_MULTIPLIER = 80000

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
			end
		end
	elseif car:IsA("BasePart") then
		car.Anchored = anchored
	end
end

local function launchCar()
	local root = getCarRoot()
	if not root then
		warn("[RAMP CAR TRAP] No se encontró BasePart en TK's Vision GT")
		return
	end

	local humanoid = getCarHumanoid()
	if humanoid then
		humanoid.PlatformStand = true
	end

	setCarAnchored(false)
	root.AssemblyLinearVelocity = root.CFrame.LookVector * LAUNCH_SPEED

	if USE_PHYSICS_IMPULSE then
		root:ApplyImpulse(root.CFrame.LookVector * IMPULSE_MULTIPLIER * root.AssemblyMass)
	end
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
