local Players = game:GetService("Players")

-- Configuración inicial
local START_CHANCE = 1
local INCREASE_AMOUNT = 1
local INCREASE_EVERY_SECONDS = 10
local MAX_CHANCE = 100

Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " se unió al juego")

    -- Creamos una variable para su probabilidad
    local chance = START_CHANCE

    print("Probabilidad inicial: " .. chance .. "%")

    -- Loop que aumenta la probabilidad con el tiempo
    while player.Parent do
        task.wait(INCREASE_EVERY_SECONDS)

        chance = math.min(chance + INCREASE_AMOUNT, MAX_CHANCE)

        print(player.Name .. " ahora tiene " .. chance .. "% de probabilidad")
    end
end)
