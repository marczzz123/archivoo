local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- Sound IDs - Replace these with your actual sound IDs
local SOUND_IDS = {
	low = {
		{ id = 81877238273397, volume = 0.3 }, -- viento
		{ id = 131780609989651, volume = 0.25 }, -- ventilación
		-- Add more low sounds here
	},
	medium = {
		{ id = 81877238273397, volume = 0.4 }, -- viento
		{ id = 113662653409849, volume = 0.4 }, -- low pitched
	},
	high = { { id = 0 } }, -- Placeholder for high percentage sound (60-84%)
	extreme = { { id = 0 } }, -- Placeholder for extreme percentage sound (85-100%)
}

-- Event sounds for jump scares and tension
local EVENT_SOUNDS = {
	low = {
		918273645, -- metal drop 1
		827364554, -- eco metal
		-- Add more low event sounds here
	},
	medium = {
		123456789, -- Placeholder for medium event sound
		-- Add more medium event sounds here
	},
	high = {
		987654321, -- Placeholder for high event sound
		-- Add more high event sounds here
	},
	extreme = {
		0, -- Placeholder for extreme event sound
		-- Add more extreme event sounds here
	},
}

-- Percentage thresholds for different sound levels
local THRESHOLDS = {
	medium = 30,
	high = 60,
	extreme = 85,
}

-- Interval settings for random sound playback
local MIN_INTERVAL = 3 -- Minimum interval for higher percentages (seconds)
local MAX_INTERVAL = 8 -- Maximum interval for lower percentages (seconds)

-- Track the sound loop
local soundLoop = nil
local isPlaying = false

-- Function to get valid sound list for percentage
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

-- Function to calculate base volume (always audible environment)
local function calculateBaseVolume(_percentage)
	return 0.3 -- always audible environment
end

-- Function to calculate tension multiplier (psychological intensity)
-- Only applies in MEDIUM+ tiers
local function calculateTensionMultiplier(percentage)
	return 1 + (percentage / 100) * 0.5
end

-- Function to calculate pitch based on percentage (1.0 to 0.8)
-- Lower pitch creates more psychological tension and heaviness
local function calculatePitch(percentage)
	local normalized = percentage / 100
	return 1 - normalized * 0.2 -- lowers to 0.8
end

-- Function to get tier name based on percentage
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

-- Function to play random event sound (jump scares)
local function playRandomEventSound()
	local character = player.Character
	if not character then
		return
	end

	local percentage = player:GetAttribute("ChancePercent") or 0
	local tier = getTierForPercentage(percentage)

	local soundList = EVENT_SOUNDS[tier]
	if not soundList or #soundList == 0 then
		return
	end

	-- Filter out placeholder IDs (0)
	local validSounds = {}
	for _, id in ipairs(soundList) do
		if id ~= 0 then
			table.insert(validSounds, id)
		end
	end

	if #validSounds == 0 then
		return
	end

	local id = validSounds[math.random(1, #validSounds)]

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = 0.2
	sound.Parent = character
	sound:Play()

	print(string.format("[AmbientSoundSystem] Event sound played: ID %d (tier: %s, percentage: %d%%)", id, tier, percentage))

	Debris:AddItem(sound, 5)
end

-- Function to calculate interval based on percentage (higher percentage = shorter interval)
local function calculateInterval(percentage)
	-- Higher percentage = shorter interval (more frequent sounds)
	-- Lower percentage = longer interval (less frequent sounds)
	local interval = MAX_INTERVAL - (percentage / 100) * (MAX_INTERVAL - MIN_INTERVAL)
	return interval
end

-- Function to play a random sound
local function playRandomSound()
	if isPlaying then
		return
	end
	isPlaying = true

	local character = player.Character
	if not character then
		isPlaying = false
		return
	end

	local percentage = player:GetAttribute("ChancePercent") or 0
	local soundIds = getSoundListForPercentage(percentage)

	-- If no sound ID is set, don't play
	if #soundIds == 0 then
		isPlaying = false
		return
	end

	-- Randomly select one sound from the list
	local data = soundIds[math.random(1, #soundIds)]

	-- Create a new sound instance for each play
	local sound = Instance.new("Sound")
	sound.Name = "AmbientTrapSound"
	sound.SoundId = "rbxassetid://" .. data.id

	-- Calculate volume: base volume + tension multiplier (only for medium+)
	local baseVolume = calculateBaseVolume(percentage)
	local isMediumPlus = percentage >= THRESHOLDS.medium
	local tensionMultiplier = isMediumPlus and calculateTensionMultiplier(percentage) or 1
	local finalVolume = baseVolume * tensionMultiplier

	-- Apply custom volume multiplier if specified
	if data.volume then
		finalVolume = finalVolume * data.volume
	end

	sound.Volume = math.clamp(finalVolume, 0, 1)
	sound.Pitch = calculatePitch(percentage)
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 50
	sound.Parent = character

	-- Play the sound
	sound:Play()

	print(string.format(
		"[AmbientSoundSystem] Playing sound ID %d at %.2f volume (percentage: %d%%, base: %.2f, tension: %.2f)",
		data.id,
		sound.Volume,
		percentage,
		baseVolume,
		tensionMultiplier
	))

	-- Clean up after sound finishes
	sound.Ended:Connect(function()
		sound:Destroy()
		isPlaying = false
	end)

	-- Fallback cleanup in case sound doesn't fire Ended
	task.delay(10, function()
		if sound and sound.Parent then
			sound:Destroy()
			isPlaying = false
		end
	end)
end

-- Main loop to play sounds at intervals
local function startSoundLoop()
	if soundLoop then
		task.cancel(soundLoop)
	end

	soundLoop = task.spawn(function()
		while true do
			local percentage = player:GetAttribute("ChancePercent") or 0
			local interval = calculateInterval(percentage)

			-- Only play if we have valid sounds
			local soundIds = getSoundListForPercentage(percentage)
			if #soundIds > 0 then
				playRandomSound()
			end

			task.wait(interval)
		end
	end)
end

-- Function to handle character spawning
local function onCharacterAdded()
	task.wait(1) -- Wait for character to fully load
	startSoundLoop()
end

-- Setup player
if player.Character then
	onCharacterAdded()
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Listen for attribute changes (when percentage updates)
player:GetAttributeChangedSignal("ChancePercent"):Connect(function()
	local newPercentage = player:GetAttribute("ChancePercent") or 0
	print("[AmbientSoundSystem] ChancePercent changed to: " .. newPercentage .. "%")
	-- The loop automatically picks up the new percentage
end)

-- Smart loop for event sounds (jump scares)
task.spawn(function()
	while true do
		local waitTime = math.random(8, 15)
		task.wait(waitTime)
		playRandomEventSound()
	end
end)

print("Local Ambient Sound System initialized for player: " .. player.Name)
