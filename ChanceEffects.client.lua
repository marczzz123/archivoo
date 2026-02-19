local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

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

-- ESTA FUNCIÓN SE LLAMA CADA VEZ QUE CAMBIA LA PROBABILIDAD
local function actualizarEfectos(probabilidad)
	local intensidad = math.clamp(probabilidad / 100, 0, 1)

	local blurSize = intensidad * MAX_BLUR
	local brightness = -intensidad * MAX_DARKNESS
	local contrast = intensidad * MAX_CONTRAST
	local saturation = -intensidad * MAX_DESATURATION

	TweenService:Create(blur, TweenInfo.new(TWEEN_TIME), {
		Size = blurSize,
	}):Play()

	TweenService:Create(color, TweenInfo.new(TWEEN_TIME), {
		Brightness = brightness,
		Contrast = contrast,
		Saturation = saturation,
	}):Play()

	if probabilidad > RED_TINT_THRESHOLD then
		color.TintColor = RED_TINT
	else
		color.TintColor = NORMAL_TINT
	end
end

-- Inicializa desde ChancePercent actual
actualizarEfectos(player:GetAttribute("ChancePercent") or 0)

-- Reacciona cuando cambia ChancePercent
player:GetAttributeChangedSignal("ChancePercent"):Connect(function()
	local currentChance = player:GetAttribute("ChancePercent") or 0
	actualizarEfectos(currentChance)
end)
