local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Function to force first-person view
local function forceFirstPerson()
	-- Set camera mode
	player.CameraMode = Enum.CameraMode.LockFirstPerson
end

-- Wait for player to be fully loaded
local function waitForPlayerLoad()
	if not player.Character then
		player.CharacterAdded:Wait()
	end

	-- Wait for HumanoidRootPart to exist
	local character = player.Character
	character:WaitForChild("HumanoidRootPart")
	character:WaitForChild("Humanoid")

	-- Wait a bit more for camera to initialize
	task.wait(0.5)

	-- Now force first person
	forceFirstPerson()
end

-- Start the system
local success, errorMsg = pcall(function()
	waitForPlayerLoad()
end)

if not success then
	print("Error in FirstPersonEnforcer: " .. tostring(errorMsg))
	-- Try again after a delay
	task.wait(2)
	waitForPlayerLoad()
end

-- Handle character respawns
player.CharacterAdded:Connect(function()
	task.wait(1) -- Wait for character to fully load
	forceFirstPerson()
end)

-- Continuously enforce first-person view (but less aggressively)
task.spawn(function()
	while task.wait(3) do -- Check every 3 seconds instead of 2
		if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
			forceFirstPerson()
		end
	end
end)
