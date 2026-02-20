local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Espera efectos en Lighting
local blur = Lighting:WaitForChild("BlurEffect")
local color = Lighting:WaitForChild("ColorCorrectionEffect")

-- Configuración
local MAX_BLUR = 20
local MAX_DARKNESS = 0.3
local MAX_CONTRAST = 0.5
local MAX_DESATURATION = 0.4
local TWEEN_TIME = 0.5
local RED_TINT_THRESHOLD = 70
local RED_TINT = Color3.fromRGB(120, 0, 0)
local NORMAL_TINT = Color3.new(1, 1, 1)

-- FOV respiración en extreme
local EXTREME_FOV_THRESHOLD = 85
local BASE_FOV = 70
local FOV_OFFSET = 3
local FOV_PULSE_SPEED = 2
local FOV_PULSE_AMOUNT = 0.8

local blurTween
local colorTween
local tintTween
local breathingConnection

local function stopBreathingFov()
	if breathingConnection then
		breathingConnection:Disconnect()
		breathingConnection = nil
	end

	if camera then
		camera.FieldOfView = BASE_FOV
	end
end

local function startBreathingFov()
	if breathingConnection then
		return
	end

	breathingConnection = RunService.RenderStepped:Connect(function()
		local percentage = player:GetAttribute("ChancePercent") or 0

		if percentage < EXTREME_FOV_THRESHOLD then
			stopBreathingFov()
			return
		end

		local t = tick()
		local pulse = math.sin(t * FOV_PULSE_SPEED) * FOV_PULSE_AMOUNT
		camera.FieldOfView = BASE_FOV + FOV_OFFSET + pulse
	end)
end

-- ESTA FUNCIÓN SE LLAMA CADA VEZ QUE CAMBIA LA PROBABILIDAD
local function actualizarEfectos(probabilidad)
	local intensidad = math.clamp(probabilidad / 100, 0, 1)

	local blurSize = intensidad * MAX_BLUR
	local brightness = -intensidad * MAX_DARKNESS
	local contrast = intensidad * MAX_CONTRAST
	local saturation = -intensidad * MAX_DESATURATION

	if blurTween then
		blurTween:Cancel()
	end

	if colorTween then
		colorTween:Cancel()
	end

	if tintTween then
		tintTween:Cancel()
	end

	blurTween = TweenService:Create(blur, TweenInfo.new(TWEEN_TIME), {
		Size = blurSize,
	})
	blurTween:Play()

	colorTween = TweenService:Create(color, TweenInfo.new(TWEEN_TIME), {
		Brightness = brightness,
		Contrast = contrast,
		Saturation = saturation,
	})
	colorTween:Play()

	local tintObjetivo = NORMAL_TINT
	if probabilidad > RED_TINT_THRESHOLD then
		tintObjetivo = RED_TINT
	end

	tintTween = TweenService:Create(color, TweenInfo.new(TWEEN_TIME), {
		TintColor = tintObjetivo,
	})
	tintTween:Play()

	if probabilidad >= EXTREME_FOV_THRESHOLD then
		startBreathingFov()
	else
		stopBreathingFov()
	end
end

-- Inicializa desde ChancePercent actual
actualizarEfectos(player:GetAttribute("ChancePercent") or 0)

-- Reacciona cuando cambia ChancePercent
player:GetAttributeChangedSignal("ChancePercent"):Connect(function()
	local currentChance = player:GetAttribute("ChancePercent") or 0
	actualizarEfectos(currentChance)
end)

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	camera = workspace.CurrentCamera
	actualizarEfectos(player:GetAttribute("ChancePercent") or 0)
end)
