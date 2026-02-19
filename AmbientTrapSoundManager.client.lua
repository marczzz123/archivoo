local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- Capas de audio ambiente (loop permanente)
local AMBIENT_SOUNDS = {
	{ id = 81877238273397, volume = 0.3 }, -- viento
	{ id = 131780609989651, volume = 0.25 }, -- ventilación
	-- Puedes añadir más capas base aquí
}

-- Sonidos de eventos intermitentes (jump-scare / tensión)
local EVENT_SOUNDS = {
	low = {
		918273645, -- metal drop 1
		827364554, -- eco metal
	},
	medium = {
		123456789,
	},
	high = {
		987654321,
	},
	extreme = {
		0,
	},
}

local THRESHOLDS = {
	medium = 30,
	high = 60,
	extreme = 85,
}

-- Intervalos para eventos (a mayor porcentaje, más frecuentes)
local MIN_EVENT_INTERVAL = 3
local MAX_EVENT_INTERVAL = 8

-- Audio interno/cinemático (en cámara)
local USE_CAMERA_AUDIO = true

local ambientSounds = {}
local eventLoop = nil

local function calculateBaseVolume(percentage)
	return 0.25 + (percentage / 100) * 0.35
end

local function calculatePitch(percentage)
	local normalized = percentage / 100
	return 1 - normalized * 0.2
end

local function calculateTensionMultiplier(percentage)
	if percentage < THRESHOLDS.medium then
		return 1
	end

	return 1 + (percentage / 100) * 0.5
end

local function getTierForPercentage(percentage)
	if percentage >= THRESHOLDS.extreme then
		return "extreme"
	elseif percentage >= THRESHOLDS.high then
		return "high"
	elseif percentage >= THRESHOLDS.medium then
		return "medium"
	else
		return "low"
	end
end

local function calculateEventInterval(percentage)
	return MAX_EVENT_INTERVAL - (percentage / 100) * (MAX_EVENT_INTERVAL - MIN_EVENT_INTERVAL)
end

local function cleanupAmbientSounds()
	for _, sound in ipairs(ambientSounds) do
		if sound and sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
	end
	ambientSounds = {}
end

local function getAudioParent(character)
	if USE_CAMERA_AUDIO and workspace.CurrentCamera then
		return workspace.CurrentCamera
	end

	return character
end

local function setupAmbientSounds()
	local character = player.Character
	if not character then
		return
	end

	local audioParent = getAudioParent(character)

	cleanupAmbientSounds()

	for i, data in ipairs(AMBIENT_SOUNDS) do
		if data.id ~= 0 then
			local sound = Instance.new("Sound")
			sound.Name = "AmbientLayer_" .. i
			sound.SoundId = "rbxassetid://" .. data.id
			sound.Looped = true
			sound.Volume = 0
			sound.RollOffMode = Enum.RollOffMode.Linear
			sound.RollOffMinDistance = 10
			sound.RollOffMaxDistance = 60
			sound.Parent = audioParent
			sound:Play()

			table.insert(ambientSounds, { sound = sound, base = data.volume or 1 })
		end
	end
end

local function updateAmbientVolumes()
	local percentage = player:GetAttribute("ChancePercent") or 0
	local baseVolume = calculateBaseVolume(percentage)
	local tensionMultiplier = calculateTensionMultiplier(percentage)
	local pitch = calculatePitch(percentage)

	for _, layer in ipairs(ambientSounds) do
		local sound = layer.sound
		if sound and sound.Parent then
			sound.Volume = math.clamp(baseVolume * layer.base * tensionMultiplier, 0, 1)
			sound.Pitch = pitch
		end
	end
end

local function playRandomEventSound()
	local character = player.Character
	if not character then
		return
	end

	local audioParent = getAudioParent(character)

	local percentage = player:GetAttribute("ChancePercent") or 0
	local tier = getTierForPercentage(percentage)
	local tierList = EVENT_SOUNDS[tier]
	if not tierList or #tierList == 0 then
		return
	end

	local valid = {}
	for _, id in ipairs(tierList) do
		if id ~= 0 then
			table.insert(valid, id)
		end
	end
	if #valid == 0 then
		return
	end

	local id = valid[math.random(1, #valid)]
	local sound = Instance.new("Sound")
	sound.Name = "AmbientEventSound"
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = 0.2
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 80
	sound.Parent = audioParent
	sound:Play()

	Debris:AddItem(sound, 5)
end

local function startEventLoop()
	if eventLoop then
		task.cancel(eventLoop)
	end

	eventLoop = task.spawn(function()
		while true do
			local percentage = player:GetAttribute("ChancePercent") or 0
			task.wait(calculateEventInterval(percentage))
			playRandomEventSound()
		end
	end)
end

local function onCharacterAdded()
	task.wait(1)
	setupAmbientSounds()
	updateAmbientVolumes()
	startEventLoop()
end

if player.Character then
	onCharacterAdded()
end

player.CharacterAdded:Connect(onCharacterAdded)

player:GetAttributeChangedSignal("ChancePercent"):Connect(function()
	updateAmbientVolumes()
end)

print("AmbientTrapSoundManager initialized for player: " .. player.Name)
