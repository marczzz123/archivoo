local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Capas de ambiente por nivel de tensión
local AMBIENT_LAYERS = {
	low = {
		{ id = 81877238273397, volume = 0.5 }, -- viento
	},
	medium = {
		{ id = 131780609989651, volume = 0.4 }, -- ventilación
	},
	high = {
		{ id = 113662653409849, volume = 0.5 }, -- tensión grave
	},

	extreme = {
		{ id = 134914789373072, volume = 1, name = "Heartbeat" },
		{ id = 112304764602363, volume = 0.6, name = "Breathing" },
		{ id = 117797174283617, volume = 0.8, name = "Pressure" },
	},
}

-- Sonidos de eventos intermitentes (jump-scare / tensión)
local EVENT_SOUNDS = {
	low = { 101445086121072, 96197402719407 },
	medium = { 101445086121072 },
	high = { 101445086121072 },
	extreme = { 101445086121072 },
}

local THRESHOLDS = {
	medium = 30,
	high = 60,
	extreme = 85,
	heartbeatFast = 95,
}

local MIN_EVENT_INTERVAL = 3
local MAX_EVENT_INTERVAL = 8

-- Audio interno/cinemático (en cámara)
local USE_CAMERA_AUDIO = true
local VOLUME_TWEEN_TIME = 0.6

local ambientSounds = {}
local volumeTweens = {}
local eventLoop = nil

local function calculateBaseVolume(percentage)
	return 0.22 + (percentage / 100) * 0.28
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

local function getActiveLayerKeys(percentage)
	if percentage >= THRESHOLDS.extreme then
		return { "low", "medium", "high", "extreme" }
	elseif percentage >= THRESHOLDS.high then
		return { "low", "medium", "high" }
	elseif percentage >= THRESHOLDS.medium then
		return { "low", "medium" }
	else
		return { "low" }
	end
end

local function calculateEventInterval(percentage)
	return MAX_EVENT_INTERVAL - (percentage / 100) * (MAX_EVENT_INTERVAL - MIN_EVENT_INTERVAL)
end

local function getAudioParent(character)
	if USE_CAMERA_AUDIO and workspace.CurrentCamera then
		return workspace.CurrentCamera
	end

	return character
end

local function cleanupAmbientSounds()
	for _, layer in pairs(ambientSounds) do
		for _, entry in ipairs(layer) do
			local sound = entry.sound
			if sound and sound.Parent then
				sound:Stop()
				sound:Destroy()
			end
		end
	end
	ambientSounds = {}
	volumeTweens = {}
end

local function setupAmbientSounds()
	local character = player.Character
	if not character then
		return
	end

	local audioParent = getAudioParent(character)
	cleanupAmbientSounds()

	for tier, list in pairs(AMBIENT_LAYERS) do
		ambientSounds[tier] = {}
		for i, data in ipairs(list) do
			if data.id ~= 0 then
				local sound = Instance.new("Sound")
				sound.Name = data.name or string.format("AmbientLayer_%s_%d", tier, i)
				sound.SoundId = "rbxassetid://" .. data.id
				sound.Looped = true
				sound.Volume = 0
				sound.RollOffMode = Enum.RollOffMode.Linear
				sound.RollOffMinDistance = 10
				sound.RollOffMaxDistance = 60
				sound.Parent = audioParent
				sound:Play()

				table.insert(ambientSounds[tier], {
					sound = sound,
					base = data.volume or 1,
					name = data.name,
				})
			end
		end
	end
end

local function isTierActive(activeTierKeys, tier)
	for _, key in ipairs(activeTierKeys) do
		if key == tier then
			return true
		end
	end
	return false
end

local function updateAmbientVolumes()
	local percentage = player:GetAttribute("ChancePercent") or 0
	local baseVolume = calculateBaseVolume(percentage)
	local tensionMultiplier = calculateTensionMultiplier(percentage)
	local pitch = calculatePitch(percentage)
	local activeKeys = getActiveLayerKeys(percentage)

	for tier, entries in pairs(ambientSounds) do
		local active = isTierActive(activeKeys, tier)
		for _, entry in ipairs(entries) do
			local sound = entry.sound
			if sound and sound.Parent then
				local targetVolume = 0

				if active then
					targetVolume = math.clamp(baseVolume * entry.base * tensionMultiplier, 0, 1)

					if tier == "extreme" then
						local normalized = math.clamp((percentage - THRESHOLDS.extreme) / (100 - THRESHOLDS.extreme), 0, 1)

						if sound.Name == "Heartbeat" then
							sound.PlaybackSpeed = 1 + normalized * 0.4
							targetVolume = targetVolume * normalized
						elseif sound.Name == "Breathing" then
							sound.PlaybackSpeed = 1
							targetVolume = targetVolume * (normalized ^ 1.5)
						elseif sound.Name == "Pressure" then
							sound.PlaybackSpeed = 1
						else
							sound.PlaybackSpeed = 1
							targetVolume = targetVolume * normalized
						end

						targetVolume = math.clamp(targetVolume, 0, 1)
					else
						sound.PlaybackSpeed = 1
					end
				end

				sound.Pitch = pitch

				if volumeTweens[sound] then
					volumeTweens[sound]:Cancel()
				end

				local tween = TweenService:Create(sound, TweenInfo.new(VOLUME_TWEEN_TIME), {
					Volume = targetVolume,
				})
				volumeTweens[sound] = tween
				tween:Play()
			end
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
