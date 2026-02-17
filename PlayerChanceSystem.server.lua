local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Configuración general de probabilidad
local START_CHANCE = 1
local INCREASE_AMOUNT = 1
local INCREASE_EVERY_SECONDS = 10
local MAX_CHANCE = 100

-- Configuración de zonas de trampa
local TRAP_TAG = "TrapZone"
local DEFAULT_TRAP_MIN_CHANCE = 1
local DEFAULT_TRAP_MAX_CHANCE = 100

-- Tabla global para guardar la probabilidad de cada jugador
local playerChances = {}

-- Anti-spam de trampas por jugador
local trapCooldowns = {}
local TRAP_COOLDOWN_TIME = 3

local function getCharacterPlayer(otherPart)
    if not otherPart then
        return nil
    end

    local character = otherPart.Parent
    if not character then
        return nil
    end

    return Players:GetPlayerFromCharacter(character)
end

local function getTrapChanceRange(trapPart)
    local minChance = trapPart:GetAttribute("MinChance") or DEFAULT_TRAP_MIN_CHANCE
    local maxChance = trapPart:GetAttribute("MaxChance") or DEFAULT_TRAP_MAX_CHANCE

    minChance = math.clamp(minChance, 1, 100)
    maxChance = math.clamp(maxChance, 1, 100)

    if minChance > maxChance then
        minChance, maxChance = maxChance, minChance
    end

    return minChance, maxChance
end

local function activateTrapForPlayer(player)
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        humanoid.Health = 0
    end
end

local function onTrapTouched(trapPart, otherPart)
    local player = getCharacterPlayer(otherPart)
    if not player then
        return
    end

    if trapCooldowns[player] then
        return
    end

    trapCooldowns[player] = true
    task.delay(TRAP_COOLDOWN_TIME, function()
        trapCooldowns[player] = nil
    end)

    local chance = playerChances[player]
    if not chance then
        return
    end

    local minChance, maxChance = getTrapChanceRange(trapPart)
    if chance < minChance or chance > maxChance then
        return
    end

    local randomNumber = math.random(1, 100)
    print(
        string.format(
            "[TRAMPA] %s tocó %s | Chance=%d%% | Rango=%d-%d%% | Random=%d",
            player.Name,
            trapPart.Name,
            chance,
            minChance,
            maxChance,
            randomNumber
        )
    )

    if randomNumber <= chance then
        print("✅ Trampa activada para " .. player.Name)
        activateTrapForPlayer(player)
    end
end

local function connectTrapPart(trapPart)
    if not trapPart:IsA("BasePart") then
        warn("[TRAMPA] El objeto con tag TrapZone no es BasePart: " .. trapPart:GetFullName())
        return
    end

    trapPart.Touched:Connect(function(otherPart)
        onTrapTouched(trapPart, otherPart)
    end)
end

for _, trapPart in ipairs(CollectionService:GetTagged(TRAP_TAG)) do
    connectTrapPart(trapPart)
end

CollectionService:GetInstanceAddedSignal(TRAP_TAG):Connect(function(trapPart)
    connectTrapPart(trapPart)
end)

Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " se unió al juego")

    playerChances[player] = START_CHANCE
    print("Probabilidad inicial de " .. player.Name .. ": " .. playerChances[player] .. "%")

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")

        humanoid.Died:Connect(function()
            playerChances[player] = START_CHANCE
            print(player.Name .. " murió. Probabilidad reiniciada a " .. playerChances[player] .. "%")
        end)
    end)

    task.spawn(function()
        while player.Parent do
            task.wait(INCREASE_EVERY_SECONDS)

            if not playerChances[player] then
                break
            end

            playerChances[player] = math.min(playerChances[player] + INCREASE_AMOUNT, MAX_CHANCE)
            print("Probabilidad actual de " .. player.Name .. ": " .. playerChances[player] .. "%")
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerChances[player] = nil
    trapCooldowns[player] = nil
end)
