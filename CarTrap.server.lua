local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Chat = game:GetService("Chat")

local model = script.Parent

local trigger = model:WaitForChild("trigger gas1")
local carSpawn = model:WaitForChild("car spawn")
local carPoint1 = model:WaitForChild("car point1")
local carPoint2 = model:WaitForChild("car point2")
local npcSpawn = model:WaitForChild("npc spawn")

local carModel = ReplicatedStorage:WaitForChild("car")
local npcModel = ReplicatedStorage:WaitForChild("npc")

local debounce = false
local isRegenerating = false

-- Configuración
local EXPLOSION_RADIUS = 200
local EXPLOSION_BLAST_PRESSURE = 500000
local STATION_EXPLOSION_RADIUS = 35
local STATION_EXPLOSION_COUNT = 10
local DEBRIS_LIFETIME = 15
local REGENERATION_TIME = 60
local TRAP_CHANCE_THRESHOLD = 3 -- 50% o más activa
local CAR_HEIGHT_OFFSET = 2 -- evita que el coche quede bajo el suelo
local SPAWN_RIGHT_ROTATION_DEG = -90
local POINT1_LEFT_ROTATION_DEG = -90

local NPC_DIALOGUE = "I'm tired of traveling so much, I think I'll take out my cell phone"

local function ensurePrimaryPart(instance)
	if instance.PrimaryPart then
		return instance.PrimaryPart
	end

	instance.PrimaryPart = instance:FindFirstChildWhichIsA("BasePart")
	return instance.PrimaryPart
end

local function getCharacterFromHit(hit)
	local current = hit
	while current do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
			return current
		end
		current = current.Parent
	end

	return nil
end

local function getPlayerFromHit(hit)
	if not hit then
		return nil
	end

	local character = getCharacterFromHit(hit)
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function setModelAnchored(modelInstance, anchored)
	for _, descendant in ipairs(modelInstance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
		end
	end
end

local function withHeightOffset(cframe)
	return cframe + Vector3.new(0, CAR_HEIGHT_OFFSET, 0)
end

local function rotateCarYawDegrees(car, yawDegrees)
	local pivot = car:GetPivot()
	local rotated = pivot * CFrame.Angles(0, math.rad(yawDegrees), 0)
	car:PivotTo(rotated)
end

local function moveCarTo(car, targetPart, duration)
	local startPivot = car:GetPivot()
	local startPosition = startPivot.Position
	local goalPosition = withHeightOffset(targetPart.CFrame).Position

	local direction = goalPosition - startPosition
	if direction.Magnitude <= 0.001 then
		return true
	end

	-- Mantener orientación actual para evitar giros de 360°
	local currentLook = startPivot.LookVector
	local fixedRotation = CFrame.lookAt(Vector3.zero, currentLook)

	local tweenValue = Instance.new("NumberValue")
	tweenValue.Value = 0

	local connection = tweenValue:GetPropertyChangedSignal("Value"):Connect(function()
		local alpha = tweenValue.Value
		local newPosition = startPosition:Lerp(goalPosition, alpha)
		local newCFrame = CFrame.new(newPosition) * fixedRotation
		car:PivotTo(newCFrame)
	end)

	local tween = TweenService:Create(
		tweenValue,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Value = 1 }
	)

	tween:Play()
	tween.Completed:Wait()

	connection:Disconnect()
	tweenValue:Destroy()

	return true
end

local function createExplosion(position, radius, pressure)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = radius
	explosion.BlastPressure = pressure
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.DestroyJointRadiusPercent = 1
	explosion.Parent = workspace
end

local function explode(position)
	createExplosion(position, EXPLOSION_RADIUS, EXPLOSION_BLAST_PRESSURE)

	for _ = 1, 20 do
		local debris = Instance.new("Part")
		debris.Size = Vector3.new(math.random(1, 3), math.random(1, 3), math.random(1, 3))
		debris.Position = position + Vector3.new(
			math.random(-10, 10),
			math.random(5, 20),
			math.random(-10, 10)
		)
		debris.Anchored = false
		debris.Material = Enum.Material.Concrete
		debris.Color = Color3.fromRGB(100, 100, 100)
		debris.Parent = workspace

		debris.AssemblyLinearVelocity = Vector3.new(
			math.random(-50, 50),
			math.random(20, 80),
			math.random(-50, 50)
		)

		Debris:AddItem(debris, DEBRIS_LIFETIME)
	end
end

local function explodeStation(stationModel)
	local candidateParts = {}
	for _, descendant in ipairs(stationModel:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.CanCollide then
			table.insert(candidateParts, descendant)
		end
	end

	if #candidateParts == 0 then
		return
	end

	for _ = 1, math.min(STATION_EXPLOSION_COUNT, #candidateParts) do
		local part = candidateParts[math.random(1, #candidateParts)]
		createExplosion(part.Position, STATION_EXPLOSION_RADIUS, EXPLOSION_BLAST_PRESSURE)
	end
end

local function makeNpcSpeak(npc)
	if not npc then
		return
	end

	local head = npc:FindFirstChild("Head") or npc:FindFirstChildWhichIsA("BasePart")
	if not head then
		return
	end

	-- Crear Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 250, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	billboard.Parent = head

	-- Crear texto
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeTransparency = 0
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = NPC_DIALOGUE
	textLabel.Parent = billboard

	-- Auto destruir después de 4 segundos
	Debris:AddItem(billboard, 4)
end
local function activateTrap()
	if isRegenerating then
		return
	end

	local car = carModel:Clone()
	car.Parent = workspace

	local carPrimary = ensurePrimaryPart(car)
	if not carPrimary then
		car:Destroy()
		return
	end

	setModelAnchored(car, true)
	car:PivotTo(withHeightOffset(carSpawn.CFrame))
	rotateCarYawDegrees(car, SPAWN_RIGHT_ROTATION_DEG)
	task.wait(1)

	moveCarTo(car, carPoint1, 3)
	rotateCarYawDegrees(car, POINT1_LEFT_ROTATION_DEG)
	moveCarTo(car, carPoint2, 3)

	task.wait(1)

	local npc = npcModel:Clone()
	npc.Parent = workspace

	local npcPrimary = ensurePrimaryPart(npc)
	if not npcPrimary then
	else
		npc:SetPrimaryPartCFrame(npcSpawn.CFrame)
		makeNpcSpeak(npc)
	end

	task.wait(3)

	local carPivot = car:GetPivot()
	explode(carPivot.Position)
	explodeStation(model)

	car:Destroy()
	npc:Destroy()

	isRegenerating = true
	task.delay(REGENERATION_TIME, function()
		isRegenerating = false
	end)
end

trigger.Touched:Connect(function(hit)
	if debounce or isRegenerating then
		return
	end

	local player = getPlayerFromHit(hit)
	if not player then
		return
	end

	local chance = player:GetAttribute("ChancePercent")
	if typeof(chance) ~= "number" then
		chance = 0
	end

	if chance < TRAP_CHANCE_THRESHOLD then
		print(string.format("[TRAMP CAR] %s tiene %d%% (< %d%%). Trampa no activada.", player.Name, chance, TRAP_CHANCE_THRESHOLD))
		return
	end

	debounce = true
	print(string.format("[TRAMP CAR] %s tiene %d%% (>= %d%%). ¡TRAMPA ACTIVADA!", player.Name, chance, TRAP_CHANCE_THRESHOLD))

	local ok, err = pcall(activateTrap)
	if not ok then
		warn("[TRAMP CAR] Error al activar trampa:", err)
	end

	debounce = false
end)
