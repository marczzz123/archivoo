# Sistema de probabilidad + trampas + puerta con umbral (15%)

Ahora tienes 7 scripts conectados:

1. `PlayerChanceSystem.server.lua` (sistema central de probabilidad).
2. `DoorTrap.server.lua` (puerta que actúa normal o trampa según `%`).
3. `RiskBillboardManager.client.lua` (UI sobre la cabeza con el `%` de riesgo).
4. `FirstPersonEnforcer.client.lua` (fuerza cámara en primera persona).
5. `RockTrap.server.lua` (trampa de roca con daño + ragdoll compatible con `%`).
6. `AmbientTrapSoundManager.client.lua` (sonido ambiente por riesgo).
7. `ChanceEffects.client.lua` (efectos visuales dinámicos por riesgo).

## Dónde va cada archivo (Roblox Studio)

### 1) Sistema central
- **Archivo:** `PlayerChanceSystem.server.lua`
- **Ubicación:** `ServerScriptService`
- **Tipo:** `Script`
- **Nombre sugerido:** `PlayerChanceSystem`

### 2) Script de la puerta
- **Archivo:** `DoorTrap.server.lua`
- **Ubicación:** dentro del **Model de la puerta** (normalmente en `Workspace`)
- **Tipo:** `Script`
- **Nombre sugerido:** `DoorTrap`

### 3) Billboard de riesgo (UI)
- **Archivo:** `RiskBillboardManager.client.lua`
- **Ubicación:** `StarterPlayer > StarterPlayerScripts`
- **Tipo:** `LocalScript`
- **Nombre sugerido:** `RiskBillboardManager`

### 4) Primera persona forzada
- **Archivo:** `FirstPersonEnforcer.client.lua`
- **Ubicación:** `StarterPlayer > StarterPlayerScripts`
- **Tipo:** `LocalScript`
- **Nombre sugerido:** `FirstPersonEnforcer`

### 5) Trampa de roca
- **Archivo:** `RockTrap.server.lua`
- **Ubicación:** dentro del `Part` roca en `Workspace`
- **Tipo:** `Script`
- **Nombre sugerido:** `RockTrap`

### 6) Sonido ambiente por riesgo
- **Archivo:** `AmbientTrapSoundManager.client.lua`
- **Ubicación:** `StarterPlayer > StarterPlayerScripts`
- **Tipo:** `LocalScript`
- **Nombre sugerido:** `AmbientTrapSoundManager`

### 7) Efectos visuales por probabilidad
- **Archivo:** `ChanceEffects.client.lua`
- **Ubicación:** `StarterPlayer > StarterPlayerScripts`
- **Tipo:** `LocalScript`
- **Nombre sugerido:** `ChanceEffects`

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
  - y cierra más rápido (modo trampa).

La muerte **no es instantánea** al activar trampa: solo ocurre si el jugador toca `Puerta1` o `Puerta2` mientras la puerta se está cerrando en modo trampa (aplastamiento real).

## Configuración de velocidades (DoorTrap)

En `DoorTrap.server.lua` puedes ajustar:

- `OPEN_TIME = 1`
- `NORMAL_CLOSE_TIME = 1`
- `TRAP_CLOSE_TIME = 0.25`
- `HOLD_OPEN_TIME = 0.2`
- `ENABLE_RAGDOLL_ON_CRUSH = true`
- `RAGDOLL_FREEZE_TIME = 1.5`

## Nota técnica importante

`PlayerChanceSystem` guarda la probabilidad en atributo del jugador:

- `player:SetAttribute("ChancePercent", valor)`

Eso permite que `DoorTrap` lea el porcentaje sin depender de variables locales.

## Anti-spam

- En `PlayerChanceSystem` existe anti-spam por jugador para trampas de `Touched`.
- En `DoorTrap` existe cooldown por detector para evitar múltiples activaciones instantáneas.


## Daño por aplastamiento (justo)

`DoorTrap` usa dos estados internos:

- `puertaCerrando`: `true` solo durante el tween de cierre.
- `trapDamageEnabled`: `true` solo en cierre de modo trampa.
- `doorBusy`: evita solapar ciclos si varios jugadores activan detectores al mismo tiempo.
- `crushedCharacters`: evita intentos repetidos de matar al mismo personaje en el mismo cierre.

Con esto:

- En modo normal no hay muerte por tocar puerta.
- En modo trampa solo muere si hay contacto real durante el cierre.
- Si el jugador corre y evita la puerta cerrándose, sobrevive.


## Billboard de riesgo (RiskBillboardManager)

Este LocalScript crea un `BillboardGui` llamado `RiskBillboard` sobre cada jugador y muestra su `ChancePercent` con color dinámico:

- 0-20: verde
- 21-40: amarillo
- 41-60: naranja
- 61-80: rojo
- 81-100: rojo oscuro

Se actualiza automáticamente cuando cambia el atributo `ChancePercent` y se recrea en respawn (`CharacterAdded`).


## FirstPersonEnforcer

Este LocalScript fuerza cámara en primera persona (`LockFirstPerson`) al cargar, al respawn y con verificación periódica cada 3 segundos.


## ¿Ragdoll en la puerta?

Sí, se puede y **ya quedó integrado en el mismo `DoorTrap.server.lua`** para mantener todo junto y simple:

- Cuando la puerta aplasta, primero aplica un ragdoll simple (`Physics` + `PlatformStand`) y luego mata al jugador.
- Si quieres desactivarlo, cambia `ENABLE_RAGDOLL_ON_CRUSH = false`.

Si luego quieres un ragdoll más avanzado (con constraints), ahí sí conviene moverlo a un `ModuleScript` aparte para reutilizar en otras trampas.


## Corrección: muerte consistente con ragdoll

Si alguna vez ves que el jugador queda vivo con poca vida en modo trampa, `DoorTrap` ahora usa `forceKillHumanoid()` después del ragdoll para forzar estado `Dead` con fallback adicional.


## RockTrap compatible con ChancePercent

`RockTrap.server.lua` quedó adaptado para usar el sistema global de probabilidad:

- Lee `player:GetAttribute("ChancePercent")` si `USE_CHANCE_PERCENT = true`.
- Usa ese valor (1-100) como probabilidad real de activación de la roca.
- Mantiene cooldown por jugador para evitar spam.
- Aplica daño + ragdoll simple cuando activa.

Si quieres volver al comportamiento fijo (por ejemplo 5%), pon `USE_CHANCE_PERCENT = false` y ajusta `TRAP_SUCCESS_CHANCE`.


## AmbientTrapSoundManager

`AmbientTrapSoundManager.client.lua` usa una arquitectura profesional por niveles de tensión:

- `AMBIENT_LAYERS.low`
- `AMBIENT_LAYERS.medium`
- `AMBIENT_LAYERS.high`
- `AMBIENT_LAYERS.extreme`

Comportamiento esperado:

- 0–29%: solo capas LOW (ej. viento).
- 30–59%: LOW + MEDIUM.
- 60–84%: LOW + MEDIUM + HIGH.
- 85%+: LOW + MEDIUM + HIGH + EXTREME (ej. latido).
- 95%+: el tier `extreme` acelera (`PlaybackSpeed`) para subir tensión.

Además mantiene una capa de eventos intermitentes (`EVENT_SOUNDS`) con intervalo dinámico según `ChancePercent`.

Configuración clave:

- `AMBIENT_LAYERS = { low, medium, high, extreme }` con `{ id, volume }`.
- `EVENT_SOUNDS` por tier.
- `THRESHOLDS` (incluye `heartbeatFast`).
- `USE_CAMERA_AUDIO` para audio interno en `workspace.CurrentCamera`.

## ChanceEffects (Lighting)

Antes de usar `ChanceEffects.client.lua`, en `Lighting` agrega:

- `BlurEffect` con `Size = 0`
- `ColorCorrectionEffect` con:
  - `Brightness = 0`
  - `Contrast = 0`
  - `Saturation = 0`

El script lee `ChancePercent` del jugador y aplica tween dinámico:

- Blur
- Oscurecimiento suave (`Brightness` negativo)
- Más contraste
- Menos saturación

Además, al superar 70% aplica un leve tinte rojo (`TintColor`) para sensación de peligro.


- `ChanceEffects` ahora anima `TintColor` con tween y cancela tweens anteriores (`blurTween`, `colorTween`, `tintTween`) para evitar acumulación al actualizar la probabilidad.
