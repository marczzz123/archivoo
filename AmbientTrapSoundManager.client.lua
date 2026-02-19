local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Sound IDs - Replace these with your actual sound IDs
local SOUND_IDS = {
	low = {
		{ id = 81877238273397, volume = 0.4 }, -- viento
		{ id = 131780609989651, volume = 0.25 }, -- ventilación
	},
	medium = { { id = 0 } }, -- Placeholder for medium percentage sound (30-59%)
	high = { { id = 0 } }, -- Placeholder for high percentage sound (60-84%)
	extreme = { { id = 0 } }, -- Placeholder for extreme percentage sound (85-100%)
}

-- Percentage thresholds for different sound levels
local THRESHOLDS = {
	medium = 30,
	high = 60,
	extreme = 85,
}

-- Volumen personalizado para sonidos LOW (multiplicador)
local LOW_VOLUME_MULTIPLIER = 0.6

-- Function to return a non-placeholder list of sounds for percentage
local function getSoundListForPercentage(percentage)
	local soundTable
	if percentage >= THRESHOLDS.extreme then
		soundTable = SOUND_IDS.extreme
	elseif percentage >= THRESHOLDS.high then
		soundTable = SOUND_IDS.high
	elseif percentage >= THRESHOLDS.medium then
		soundTable = SOUND_IDS.medium
	else
		soundTable = SOUND_IDS.low
	end

	local valid = {}
	for _, data in ipairs(soundTable) do
		if data.id ~= 0 then
			table.insert(valid, data)
		end
	end

	return valid
end

-- Function to calculate volume based on percentage (0.1 to 1.0)
local function calculateVolume(percentage)
	return 0.1 + (percentage / 100) * 0.9
end

-- Function to calculate pitch based on percentage (0.8 to 1.5)
local function calculatePitch(percentage)
	return 0.8 + (percentage / 100) * 0.7
end

local function cleanupAmbientSounds(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Sound") and string.find(child.Name, "AmbientTrapSound") then
			child:Stop()
			child:Destroy()
		end
	end
end

-- Function to update or create ambient sound(s)
local function updateAmbientSound()
	local character = player.Character
	if not character then
		return
	end

	local percentage = player:GetAttribute("ChancePercent") or 0
	local soundIds = getSoundListForPercentage(percentage)

	-- If no sound ID is set, cleanup and stop
	if #soundIds == 0 then
		cleanupAmbientSounds(character)
		return
	end

	local baseVolume = calculateVolume(percentage)
	local pitch = calculatePitch(percentage)
	local isLowTier = percentage < THRESHOLDS.medium

	cleanupAmbientSounds(character)

	if isLowTier then
		-- LOW tier: reproduce TODOS los sonidos a la vez
		for i, data in ipairs(soundIds) do
			local sound = Instance.new("Sound")
			sound.Name = "AmbientTrapSound_Low_" .. i
			sound.Looped = true
			sound.RollOffMode = Enum.RollOffMode.Linear
			sound.RollOffMinDistance = 10
			sound.RollOffMaxDistance = 50
			sound.SoundId = "rbxassetid://" .. data.id

			local finalVolume = baseVolume * data.volume * LOW_VOLUME_MULTIPLIER
			sound.Volume = math.clamp(finalVolume, 0, 1)

			sound.Pitch = pitch
			sound.Parent = character
			sound:Play()
		end
		return
	end

	-- medium/high/extreme: elegir uno aleatorio
	local data = soundIds[math.random(1, #soundIds)]
	local sound = Instance.new("Sound")
	sound.Name = "AmbientTrapSound"
	sound.Looped = true
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 50
	sound.SoundId = "rbxassetid://" .. data.id
	sound.Volume = baseVolume
	sound.Pitch = pitch
	sound.Parent = character
	sound:Play()
end

-- Function to handle character spawning
local function onCharacterAdded()
	task.wait(1) -- Wait for character to fully load
	updateAmbientSound()
end

-- Setup player
if player.Character then
	onCharacterAdded()
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Listen for attribute changes (when percentage updates)
player:GetAttributeChangedSignal("ChancePercent"):Connect(function()
	updateAmbientSound()
end)

print("Local Ambient Sound System initialized for player: " .. player.Name)
