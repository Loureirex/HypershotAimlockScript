-- CONFIGURAÇÕES
_G.HeadSize = 30
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
local MobsFolder = workspace:FindFirstChild("Mobs") or workspace:WaitForChild("Mobs",5)

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

-- FUNÇÕES AUXILIARES
local function getValidPart(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") 
        or model:FindFirstChild("Head") 
        or model:FindFirstChildWhichIsA("BasePart")
end

local function applyHighlight(model,color)
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

local function applyPropertiesToEnemy(part)
    if part and part:IsA("BasePart") then
        pcall(function()
            part.Size = Vector3.new(_G.HeadSize,_G.HeadSize,_G.HeadSize)
            part.Transparency = 0.7
            part.BrickColor = BrickColor.new("Really blue")
            part.Material = Enum.Material.Neon
            part.CanCollide = false
        end)
    end
end

-- PEGA O INIMIGO MAIS PRÓXIMO
local function getClosestEnemy()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local closest, smallestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()

    -- PRIORIDADE: JOGADORES INIMIGOS
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local part = getValidPart(player.Character)
            if part then
                local pos,onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X,pos.Y) - mousePos).Magnitude
                    if mag <= _G.FOVRadius and mag < smallestDist then
                        closest = player.Character
                        smallestDist = mag
                    end
                end
            end
        end
    end

    -- MOBS (se existirem)
    if MobsFolder then
        for _, mob in ipairs(MobsFolder:GetChildren()) do
            if mob:IsA("Model") then
                local part = getValidPart(mob)
                if part then
                    local pos,onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mag = (Vector2.new(pos.X,pos.Y) - mousePos).Magnitude
                        if mag <= _G.FOVRadius and mag < smallestDist then
                            closest = mob
                            smallestDist = mag
                        end
                    end
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

    -- HIGHLIGHT JOGADORES
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            applyHighlight(player.Character, Color3.fromRGB(0,170,255))
        end
    end

    -- HIGHLIGHT MOBS
    if MobsFolder then
        for _, mob in ipairs(MobsFolder:GetChildren()) do
            if mob:IsA("Model") then
                local part = getValidPart(mob)
                if part then
                    applyPropertiesToEnemy(part)
                    applyHighlight(mob, Color3.fromRGB(255,0,0))
                end
            end
        end
    end

    -- AIMLOCK
    if _G.Aimlock and aiming then
        local target = getClosestEnemy()
        if target then
            local part = getValidPart(target)
            if part then
                local offsetY = (part.Size.Y*_G.HeadOffsetMultiplier)+_G.ExtraHeadOffset
                if offsetY < 0.05 then offsetY = 0.05 end
                local aimPos = part.Position + Vector3.new(0,offsetY,0)
                local camPos = Camera.CFrame.Position
                Camera.CFrame = CFrame.new(camPos, aimPos)
            end
        end
    end
end)
