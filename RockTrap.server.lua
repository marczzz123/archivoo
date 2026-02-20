local rock = script.Parent
local Players = game:GetService("Players")

-- Configuración base
local RAGDOLL_DURATION = 1 -- cuánto dura el ragdoll
local DAMAGE_AMOUNT = 10 -- daño al activarse
local COOLDOWN_TIME = 2 -- cooldown por jugador

-- Activación por umbral fijo de ChancePercent
local REQUIRED_CHANCE_PERCENT = 5 -- >= 5 activa siempre

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

	-- Si no existe atributo todavía, no activar para evitar comportamientos inconsistentes
	local chance = getPlayerChance(player)
	if not chance then
		return
	end

	-- Umbral fijo: activa siempre con >= 5, no activa con < 5
	if chance < REQUIRED_CHANCE_PERCENT then
		return
	end

	-- Apply damage + ragdoll
	humanoid:TakeDamage(DAMAGE_AMOUNT)
	applyRagdoll(humanoid)
end

-- Connect the Touched event
rock.Touched:Connect(onRockTouched)
