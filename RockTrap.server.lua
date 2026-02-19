local rock = script.Parent
local Players = game:GetService("Players")

-- Configuración base
local RAGDOLL_DURATION = 1 -- cuánto dura el ragdoll
local DAMAGE_AMOUNT = 10 -- daño al activarse
local COOLDOWN_TIME = 2 -- cooldown por jugador

-- Compatibilidad con ChancePercent
local USE_CHANCE_PERCENT = true -- si false, usa TRAP_SUCCESS_CHANCE fija
local TRAP_SUCCESS_CHANCE = 5 -- fallback fijo si USE_CHANCE_PERCENT = false
local MIN_REQUIRED_CHANCE = 1 -- chance mínima para permitir activación
local MAX_REQUIRED_CHANCE = 100 -- chance máxima para permitir activación

-- Track cooldowns
local cooldowns = {}

local function applyRagdoll(humanoid)
	if not humanoid then
		return
	end

	-- Enable ragdoll simple
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	-- Disable ragdoll after duration
	task.delay(RAGDOLL_DURATION, function()
		if humanoid and humanoid.Parent and humanoid.Health > 0 then
			humanoid.PlatformStand = false
		end
	end)
end

local function getPlayerChance(player)
	local chance = player:GetAttribute("ChancePercent")
	if typeof(chance) ~= "number" then
		return nil
	end

	return math.clamp(chance, 1, 100)
end

local function onRockTouched(otherPart)
	-- Check if it's a player character
	local character = otherPart and otherPart.Parent
	if not character then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	-- Check cooldown
	if cooldowns[player] then
		return
	end

	cooldowns[player] = true
	task.delay(COOLDOWN_TIME, function()
		cooldowns[player] = nil
	end)

	-- Get humanoid
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Obtener chance compatible con sistema global
	local chance = USE_CHANCE_PERCENT and getPlayerChance(player) or TRAP_SUCCESS_CHANCE
	if not chance then
		-- Si no existe atributo todavía, no activar para evitar comportamientos inconsistentes
		return
	end

	if chance < MIN_REQUIRED_CHANCE or chance > MAX_REQUIRED_CHANCE then
		return
	end

	-- Check if trap activates (chance%)
	local randomChance = math.random(1, 100)
	if randomChance > chance then
		return
	end

	-- Apply damage + ragdoll
	humanoid:TakeDamage(DAMAGE_AMOUNT)
	applyRagdoll(humanoid)
end

-- Connect the Touched event
rock.Touched:Connect(onRockTouched)
