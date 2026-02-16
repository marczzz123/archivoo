local Players = game:GetService("Players")

-- Configuración inicial
local START_CHANCE = 1

Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " se unió al juego")

    -- Creamos una variable para su probabilidad
    local chance = START_CHANCE

    print("Probabilidad inicial: " .. chance .. "%")
end)
