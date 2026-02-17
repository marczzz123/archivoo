# Sistema de probabilidad por jugador (Paso 3)

Ahora el sistema hace esto:

- Detecta cuando un jugador entra al juego.
- Le asigna una probabilidad inicial de `1%`.
- Aumenta esa probabilidad automáticamente cada cierto tiempo.
- Lanza una tirada aleatoria (`math.random(1,100)`) para intentar activar el evento.
- Si se cumple la probabilidad, activa el evento (por ahora: matar al jugador).
- Reinicia la probabilidad **solo cuando el jugador realmente muere** (`Humanoid.Died`).

## Dónde va cada archivo (Roblox Studio)

1. Ve a **ServerScriptService**.
2. Crea un **Script**.
3. Nómbralo **`PlayerChanceSystem`**.
4. Copia dentro el contenido de `PlayerChanceSystem.server.lua`.

## Script completo

```lua
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
```

## Configuración rápida

- `START_CHANCE`: probabilidad inicial.
- `INCREASE_AMOUNT`: cuánto sube por ciclo.
- `INCREASE_EVERY_SECONDS`: cada cuántos segundos se evalúa.
- `MAX_CHANCE`: límite máximo.

## Nota importante

En este sistema, la probabilidad **no se reinicia cuando se cumple el `if`**.
Se reinicia cuando ocurre la muerte real (`Humanoid.Died`), que es el enfoque más correcto.
