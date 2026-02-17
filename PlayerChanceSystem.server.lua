local Players = game:GetService("Players")

-- Configuración inicial
local START_CHANCE = 1
local INCREASE_AMOUNT = 1
local INCREASE_EVERY_SECONDS = 10
local MAX_CHANCE = 100

Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " se unió al juego")

    local chance = START_CHANCE
    local currentHumanoid

    print("Probabilidad inicial: " .. chance .. "%")

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        currentHumanoid = humanoid

        humanoid.Died:Connect(function()
            chance = START_CHANCE
            print(player.Name .. " murió. Probabilidad reiniciada a " .. chance .. "%")
        end)
    end)

    -- Loop que aumenta la probabilidad con el tiempo y dispara el evento
    while player.Parent do
        task.wait(INCREASE_EVERY_SECONDS)

        chance = math.min(chance + INCREASE_AMOUNT, MAX_CHANCE)

        local randomNumber = math.random(1, 100)
        print(player.Name .. " | Probabilidad: " .. chance .. "% | Random: " .. randomNumber)

        if randomNumber <= chance then
            print("✅ Evento activado para " .. player.Name)

            -- Evento actual: morir
            if currentHumanoid and currentHumanoid.Health > 0 then
                currentHumanoid.Health = 0
            end
        end
    end
end)
