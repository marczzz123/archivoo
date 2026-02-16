# Primer paso del proyecto

Este script implementa la base del sistema:

- Detecta cuando un jugador entra al juego.
- Crea su probabilidad inicial en `1%`.
- Deja lista la estructura para aumentar esa probabilidad con el tiempo en el siguiente paso.

## Dónde va cada archivo (Roblox Studio)

Si lo vas a copiar y pegar manualmente, hazlo así:

1. Ve a **ServerScriptService**.
2. Crea un **Script** nuevo.
3. Ponle este nombre: **`PlayerChanceSystem`**.
4. Copia el contenido de `PlayerChanceSystem.server.lua` dentro de ese Script.

> Resumen rápido: `PlayerChanceSystem.server.lua` va dentro de **ServerScriptService** como un **Script** llamado **PlayerChanceSystem**.

## Script base

Usa `PlayerChanceSystem.server.lua`:

```lua
local Players = game:GetService("Players")

-- Configuración inicial
local START_CHANCE = 1

Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " se unió al juego")

    -- Creamos una variable para su probabilidad
    local chance = START_CHANCE

    print("Probabilidad inicial: " .. chance .. "%")
end)
```

## Qué hace

- `game:GetService("Players")`: obtiene el sistema que controla a los jugadores.
- `Players.PlayerAdded`: se activa cuando alguien entra al juego.
- `local chance = START_CHANCE`: asigna la probabilidad inicial al jugador.

## Siguiente paso

Crear un loop para aumentar `chance` cada cierto tiempo.
