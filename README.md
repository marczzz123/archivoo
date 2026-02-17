# Sistema de probabilidad + trampas + puerta con umbral (15%)

Ahora tienes 2 scripts conectados:

1. `PlayerChanceSystem.server.lua` (sistema central de probabilidad).
2. `DoorTrap.server.lua` (puerta que actúa normal o trampa según `%`).

## Dónde va cada archivo (Roblox Studio)

### 1) Sistema central
- **Archivo:** `PlayerChanceSystem.server.lua`
- **Ubicación:** `ServerScriptService`
- **Tipo:** `Script`
- **Nombre sugerido:** `PlayerChanceSystem`

### 2) Script de la puerta
- **Archivo:** `DoorTrap.server.lua`
- **Ubicación:** dentro del **Model de la puerta**
- **Tipo:** `Script`
- **Nombre sugerido:** `DoorTrap`

## Estructura del modelo de puerta

Dentro del modelo (padre del script `DoorTrap`) debes tener:

- `Puerta1` (Part)
- `Puerta2` (Part)
- `PosicionPuerta1` (Part de destino de apertura)
- `PosicionPuerta2` (Part de destino de apertura)
- `Detector1` (Part)
- `Detector2` (Part)

## Lógica solicitada

- Si el jugador tiene **menos de 15%** (`ChancePercent < 15`):
  - la puerta abre normal,
  - y cierra con velocidad estándar.

- Si el jugador tiene **15% o más** (`ChancePercent >= 15`):
  - la puerta abre normal,
  - y cierra más rápido (modo trampa),
  - provocando muerte del jugador.

## Configuración de velocidades (DoorTrap)

En `DoorTrap.server.lua` puedes ajustar:

- `OPEN_TIME = 1`
- `NORMAL_CLOSE_TIME = 1`
- `TRAP_CLOSE_TIME = 0.25`
- `HOLD_OPEN_TIME = 0.2`

## Nota técnica importante

`PlayerChanceSystem` guarda la probabilidad en atributo del jugador:

- `player:SetAttribute("ChancePercent", valor)`

Eso permite que `DoorTrap` lea el porcentaje sin depender de variables locales.

## Anti-spam

- En `PlayerChanceSystem` existe anti-spam por jugador para trampas de `Touched`.
- En `DoorTrap` existe cooldown por detector para evitar múltiples activaciones instantáneas.
