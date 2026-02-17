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

local detectorCooldowns = {}

local infoPuertas = TweenInfo.new(
    1,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.In,
    0,
    true,
    0
)

local abrirPuerta1 = {
    CFrame = CFrame.new(PosicionPuerta1.Position)
}

local abrirPuerta2 = {
    CFrame = CFrame.new(PosicionPuerta2.Position)
}

local movimientoPuerta1 = TweenService:Create(Puerta1, infoPuertas, abrirPuerta1)
local movimientoPuerta2 = TweenService:Create(Puerta2, infoPuertas, abrirPuerta2)

local function openDoorNormally()
    movimientoPuerta1:Play()
    movimientoPuerta2:Play()
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
        print(string.format("[PUERTA-TRAMPA] %s tiene %d%% (>= %d%%). Activando trampa.", playerName, chance, TRAP_CHANCE_THRESHOLD))
        openDoorNormally()

        if humanoid.Health > 0 then
            humanoid.Health = 0
        end

        return
    end

    print(string.format("[PUERTA] %s tiene %d%% (< %d%%). Puerta normal.", playerName, chance, TRAP_CHANCE_THRESHOLD))
    openDoorNormally()
end

Detector1.Touched:Connect(function(hit)
    processDetectorTouch(Detector1, hit)
end)

Detector2.Touched:Connect(function(hit)
    processDetectorTouch(Detector2, hit)
end)
