-- CONFIGURAÇÕES
_G.Disabled = false
_G.Aimlock = true
_G.AimKey = Enum.UserInputType.MouseButton1
_G.FOVRadius = 150
_G.HeadOffsetMultiplier = 0.25
_G.ExtraHeadOffset = 0.15

-- SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local aiming = false

-- FOV CIRCLE
local DrawingSuccess, Drawing = pcall(function() return Drawing end)
local FOVCircle
if DrawingSuccess and Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = true
    FOVCircle.Radius = _G.FOVRadius
    FOVCircle.Thickness = 2
    FOVCircle.Transparency = 1
    FOVCircle.Color = Color3.fromRGB(0,255,0)
    FOVCircle.Filled = false
end

if FOVCircle then
    RunService.RenderStepped:Connect(function()
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = mousePos
    end)
end

-- FUNÇÕES AUXILIARES
local function getAllParts(model)
    if not model then return {} end
    local parts = {}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    return parts
end

local function getClosestPart(model, mousePos)
    local parts = getAllParts(model)
    local closestPart, closestDist = nil, math.huge
    for _, part in ipairs(parts) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestPart = part
            end
        end
    end
    return closestPart
end

local function applyHighlight(model, color)
    if model and not model:FindFirstChild("HighlightESP") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "HighlightESP"
        highlight.FillColor = color
        highlight.OutlineColor = Color3.new(0,0,0)
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
        highlight.Adornee = model
    end
end

-- PEGAR O JOGADOR MAIS PRÓXIMO
local function getClosestPlayer(mousePos)
    local closestPlayer, smallestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local part = getClosestPart(player.Character, mousePos)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist <= _G.FOVRadius and dist < smallestDist then
                        closestPlayer = player.Character
                        smallestDist = dist
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- INPUT
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == _G.AimKey then aiming = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == _G.AimKey then aiming = false end
end)

-- LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    if _G.Disabled then
        if FOVCircle then FOVCircle.Visible = false end
        return
    else
        if FOVCircle then FOVCircle.Visible = true end
    end

    local mousePos = UserInputService:GetMouseLocation()

    -- Highlight jogadores inimigos
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            applyHighlight(player.Character, Color3.fromRGB(255,0,0))
        end
    end

    -- AIMLOCK
    if _G.Aimlock and aiming then
        local target = getClosestPlayer(mousePos)
        if target then
            local part = getClosestPart(target, mousePos)
            if part then
                local offsetY = (part.Size.Y * _G.HeadOffsetMultiplier) + _G.ExtraHeadOffset
                if offsetY < 0.05 then offsetY = 0.05 end
                local aimPos = part.Position + Vector3.new(0, offsetY, 0)
                local camPos = Camera.CFrame.Position
                Camera.CFrame = CFrame.new(camPos, aimPos)
            end
        end
    end
end)
