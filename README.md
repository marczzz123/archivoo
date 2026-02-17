# Sistema de probabilidad por jugador (Paso 2)

Ahora el sistema ya hace 3 cosas:

- Detecta cuando un jugador entra al juego.
- Le asigna una probabilidad inicial de `1%`.
- Aumenta su probabilidad automáticamente cada cierto tiempo.

## Dónde va cada archivo (Roblox Studio)

Si lo vas a copiar y pegar manualmente, hazlo así:

1. Ve a **ServerScriptService**.
2. Crea un **Script** nuevo.
3. Ponle este nombre: **`PlayerChanceSystem`**.
4. Copia el contenido de `PlayerChanceSystem.server.lua` dentro de ese Script.

> Resumen rápido: `PlayerChanceSystem.server.lua` va dentro de **ServerScriptService** como un **Script** llamado **PlayerChanceSystem**.

## Script completo (Paso 2)

```lua
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
```

## Qué hace cada configuración

- `START_CHANCE`: probabilidad inicial al entrar.
- `INCREASE_AMOUNT`: cuánto sube cada vez.
- `INCREASE_EVERY_SECONDS`: cada cuántos segundos sube.
- `MAX_CHANCE`: límite máximo para no pasar de `100%`.

## Siguiente paso sugerido

Guardar la probabilidad por jugador en una tabla para usarla después en eventos, muertes o mecánicas de juego.
