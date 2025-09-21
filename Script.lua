-- CONFIG
_G.HeadSize = 30
_G.Disabled = true
_G.Aimlock = true
_G.AimKey = Enum.UserInputType.MouseButton1
_G.FOVRadius = 150
_G.HeadOffsetMultiplier = 0.25
_G.ExtraHeadOffset = 0.15

-- SERVIÇOS
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local MobsFolder = workspace:FindFirstChild("Mobs")

local aiming = false

-- DRAWING FOV
local DrawingSuccess, Drawing = pcall(function() return Drawing end)
local FOVCircle
if DrawingSuccess and Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = true
    FOVCircle.Radius = _G.FOVRadius
    FOVCircle.Thickness = 2
    FOVCircle.Transparency = 1
    FOVCircle.Color = Color3.fromRGB(0, 255, 0)
    FOVCircle.Filled = false
end

if FOVCircle then
    RunService.RenderStepped:Connect(function()
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = mousePos
        FOVCircle.Radius = _G.FOVRadius
    end)
end

-- FUNÇÕES
local function applyPropertiesToEnemy(part)
    if part and part:IsA("BasePart") then
        local success, oldCFrame = pcall(function() return part.CFrame end)
        part.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
        if success and oldCFrame then
            part.CFrame = oldCFrame
        end
        part.Transparency = 0.7
        part.BrickColor = BrickColor.new("Really blue")
        part.Material = Enum.Material.Neon
        part.CanCollide = false
    end
end

local function applyHighlight(model, color)
    if not model:FindFirstChild("HighlightESP") then
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

-- Retorna qualquer parte disponível do modelo para mira (aimlock) – garante sempre uma posição
local function getAimPoint(model)
    -- Prioriza HumanoidRootPart ou Head
    local part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
    if part then return part.Position end
    -- Senão qualquer BasePart
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then return p.Position end
    end
    -- Senão, último recurso: posição do PrimaryPart ou centro do modelo
    if model.PrimaryPart then return model.PrimaryPart.Position end
    local cframeSum = Vector3.new(0,0,0)
    local count = 0
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            cframeSum += obj.Position
            count += 1
        end
    end
    if count > 0 then
        return cframeSum / count
    end
    return model:GetModelCFrame().Position or Vector3.new(0,0,0)
end

-- Pegar inimigo mais próximo dentro do FOV
local function getClosestEnemy()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    if not MobsFolder then return nil end

    local closest, smallestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, mob in ipairs(MobsFolder:GetChildren()) do
        if mob:IsA("Model") then
            local aimPos = getAimPoint(mob)
            local pos, onScreen = Camera:WorldToViewportPoint(aimPos)
            if onScreen then
                local screenPos = Vector2.new(pos.X, pos.Y)
                local magnitude = (screenPos - mousePos).Magnitude
                if magnitude <= _G.FOVRadius and magnitude < smallestDist then
                    closest = mob
                    smallestDist = magnitude
                end
            end
        end
    end

    return closest
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
    if not _G.Disabled then
        if FOVCircle then FOVCircle.Visible = false end
        return
    else
        if FOVCircle then FOVCircle.Visible = true end
    end

    -- Amigos: só highlight azul
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                applyHighlight(player.Character, Color3.fromRGB(0,170,255))
            end)
        end
    end

    -- Mobs: highlight vermelho + tamanho maior, aplica a todos mesmo se spawnarem depois
    if MobsFolder then
        for _, mob in ipairs(MobsFolder:GetChildren()) do
            if mob:IsA("Model") then
                local part = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
                if part then
                    pcall(function()
                        applyPropertiesToEnemy(part)
                        applyHighlight(mob, Color3.fromRGB(255,0,0))
                    end)
                end
            end
        end
    end

    -- AIMLOCK otimizado para sempre ter um ponto para mirar
    if _G.Aimlock and aiming then
        local target = getClosestEnemy()
        if target then
            local aimPos = getAimPoint(target) + Vector3.new(0, (_G.HeadOffsetMultiplier * _G.HeadSize) + _G.ExtraHeadOffset, 0)
            local camPos = Camera.CFrame.Position
            Camera.CFrame = CFrame.new(camPos, aimPos)
        end
    end
end)
