local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local model = script.Parent
local Puerta1 = model.Puerta1
local Puerta2 = model.Puerta2

local PosicionPuerta1 = model.PosicionPuerta1
local PosicionPuerta2 = model.PosicionPuerta2

local Detector1 = model.Detector1
local Detector2 = model.Detector2

local TRAP_CHANCE_THRESHOLD = 15
local DETECTOR_COOLDOWN_TIME = 2

-- Velocidades de movimiento
local OPEN_TIME = 1
local NORMAL_CLOSE_TIME = 1
local TRAP_CLOSE_TIME = 0.25
local HOLD_OPEN_TIME = 0.2

local detectorCooldowns = {}
local crushedCharacters = {}

-- Estado de aplastamiento real
local puertaCerrando = false
local trapDamageEnabled = false
local doorBusy = false

local puerta1ClosedCFrame = Puerta1.CFrame
local puerta2ClosedCFrame = Puerta2.CFrame
local puerta1OpenCFrame = PosicionPuerta1.CFrame
local puerta2OpenCFrame = PosicionPuerta2.CFrame

local function createDoorTween(target1, target2, duration)
	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In,
		0,
		false,
		0
	)

	local tween1 = TweenService:Create(Puerta1, tweenInfo, { CFrame = target1 })
	local tween2 = TweenService:Create(Puerta2, tweenInfo, { CFrame = target2 })

	return tween1, tween2
end

local function playDoorCycle(closeDuration, isTrapMode)
	if doorBusy then
		return
	end

	doorBusy = true

	local openTween1, openTween2 = createDoorTween(puerta1OpenCFrame, puerta2OpenCFrame, OPEN_TIME)
	openTween1:Play()
	openTween2:Play()

	task.delay(OPEN_TIME + HOLD_OPEN_TIME, function()
		puertaCerrando = true
		trapDamageEnabled = isTrapMode

		local closeTween1, closeTween2 = createDoorTween(puerta1ClosedCFrame, puerta2ClosedCFrame, closeDuration)
		closeTween1:Play()
		closeTween2:Play()

		task.delay(closeDuration, function()
			puertaCerrando = false
			trapDamageEnabled = false
			doorBusy = false
		end)
	end)
end

local function tryCrushPlayer(hit)
	if not puertaCerrando or not trapDamageEnabled then
		return
	end

	local character = hit and hit.Parent
	if not character or crushedCharacters[character] then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		crushedCharacters[character] = true
		humanoid.Health = 0

		task.delay(1, function()
			crushedCharacters[character] = nil
		end)
	end
end

local function processDetectorTouch(detector, hit)
	local character = hit and hit.Parent
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if detectorCooldowns[detector] then
		return
	end

	detectorCooldowns[detector] = true
	task.delay(DETECTOR_COOLDOWN_TIME, function()
		detectorCooldowns[detector] = nil
	end)

	local player = Players:GetPlayerFromCharacter(character)
	local playerName = player and player.Name or character.Name
	local chance = player and player:GetAttribute("ChancePercent") or 0

	if chance >= TRAP_CHANCE_THRESHOLD then
		print(string.format("[PUERTA-TRAMPA] %s tiene %d%% (>= %d%%). Cierre rápido con daño por aplastamiento.", playerName, chance, TRAP_CHANCE_THRESHOLD))
		playDoorCycle(TRAP_CLOSE_TIME, true)
		return
	end

	print(string.format("[PUERTA] %s tiene %d%% (< %d%%). Cierre normal sin daño.", playerName, chance, TRAP_CHANCE_THRESHOLD))
	playDoorCycle(NORMAL_CLOSE_TIME, false)
end

Detector1.Touched:Connect(function(hit)
	processDetectorTouch(Detector1, hit)
end)

Detector2.Touched:Connect(function(hit)
	processDetectorTouch(Detector2, hit)
end)

Puerta1.Touched:Connect(function(hit)
	tryCrushPlayer(hit)
end)

Puerta2.Touched:Connect(function(hit)
	tryCrushPlayer(hit)
end)
