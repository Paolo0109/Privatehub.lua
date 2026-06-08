-- --- 1. CONFIGURACIÓN DE LA INTERFAZ FLUENT ---
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Forzamos el tema Dark de Fluent a Negro y Rojo antes de abrir la ventana
Fluent.Themes.Dark.Background = Color3.fromRGB(12, 12, 12)       -- Negro Profundo
Fluent.Themes.Dark.MainFocused = Color3.fromRGB(18, 18, 18)      -- Paneles internos oscuros
Fluent.Themes.Dark.Accent = Color3.fromRGB(255, 35, 35)          -- Rojo Intenso
Fluent.Themes.Dark.TitleText = Color3.fromRGB(255, 255, 255)     -- Texto blanco

local Window = Fluent:CreateWindow({
    Title = "Private hub",
    Subtitle = "by Paolo",
    TabWidth = 160,
    Size = UDim2.fromOffset(530, 420),
    Acrylic = true, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- --- 2. SISTEMA DE GUARDADO CONFIG (.JSON) ---
local HttpService = game:GetService("HttpService")
local configFileName = "PrivateHub_MurderConfig.json"

local config = {
    ash_button_size_value = 95,
    ash_button_shape = "Square", 
    ash_button_transparency = 0.1,
    ash_lock_position = false, 
    ash_auto_unequip_gun = false, 
    ash_shoot_sound_volume = 50, 
    ash_button_x = 0.85,
    ash_button_y = 0.25,
    ash_button_offset_x = -47,
    ash_button_offset_y = -47,
    ash_button_enabled = false,
    ash_tracer_enabled = true,
    ash_lead_time_tracer_enabled = true, 
    ash_wall_check_enabled = true,
    ash_knife_esp_enabled = true,
    horizIntensity = 16,
    vertIntensity = 19,
    ash_lead_time_value = 20, 
    ash_responsive_value = 45 
}

local function saveConfig()
    writefile(configFileName, HttpService:JSONEncode(config))
end

local function loadConfig()
    if isfile(configFileName) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(configFileName))
        end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                config[k] = v
            end
        end
    end
end
loadConfig()

-- --- 3. SERVICIOS Y VARIABLES DE COMBATE ---
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local ScreenGui = nil
local ShootButton = nil
local UICorner = nil
local UIStroke = nil
local CrosshairFrame = nil
local ShootText = nil
local PredictionTracer = nil 
local LeadTimeTracer = nil 
local KnifeBoxAdornment = nil 
local ShootSoundObj = nil 

local crossCenter, crossTop, crossBottom, crossLeft, crossRight
local tracerRenderConnection = nil
local knifeEspConnection = nil
local knifeStates = {} 

local smoothedVelocity = Vector3.new(0, 0, 0)
local lastTarget = nil
local isReloading = false 

local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.IgnoreWater = true

-- --- 4. LÓGICA CORE DE DISPARO Y PREDICCIÓN ---
local function getMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then
                return player
            end
        end
    end
    return nil
end

local function getGun()
    if LocalPlayer.Character then
        local gun = LocalPlayer.Character:FindFirstChild("Gun")
        if gun and gun:FindFirstChild("Shoot") then return gun end
    end
    local gunInBackpack = LocalPlayer.Backpack:FindFirstChild("Gun")
    if gunInBackpack and gunInBackpack:FindFirstChild("Shoot") then return gunInBackpack end
    return nil
end

local function getPredictedPosition(murderer)
    if not murderer or not murderer.Character or not murderer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local targetHRP = murderer.Character.HumanoidRootPart
    local currentVelocity = targetHRP.AssemblyLinearVelocity

    if lastTarget ~= murderer then
        smoothedVelocity = currentVelocity
        lastTarget = murderer
    end

    local lerpAlpha = math.clamp(config.ash_responsive_value / 100, 0.1, 1.0)
    smoothedVelocity = smoothedVelocity:Lerp(currentVelocity, lerpAlpha)

    local scaleH = config.horizIntensity / 100
    local scaleV = (config.vertIntensity / 100) * 0.35 

    local rawPredY = smoothedVelocity.Y * scaleV
    local clampedPredY = math.clamp(rawPredY, -1.8, 1.8) 

    return targetHRP.Position + Vector3.new(
        smoothedVelocity.X * scaleH,
        clampedPredY,
        smoothedVelocity.Z * scaleH
    )
end

local function checkWallObstruction(origin, targetPosition)
    if not config.ash_wall_check_enabled or not LocalPlayer.Character then return false end
    
    wallCheckParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local direction = targetPosition - origin
    local raycastResult = workspace:Raycast(origin, direction, wallCheckParams)
    
    if raycastResult then
        local hitInstance = raycastResult.Instance
        if hitInstance.CanCollide == false then return false end
        
        local model = hitInstance:FindFirstAncestorOfClass("Model")
        if model and model:FindFirstChildOfClass("Humanoid") then
            return false
        end
        return true
    end
    return false
end

local function executePredictedShoot()
    if isReloading then return end 

    local gun = getGun()
    if not gun then return end 

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    if gun.Parent == LocalPlayer.Backpack then
        humanoid:EquipTool(gun)
        task.wait(0.05)
    end

    local murderer = getMurderer()
    local predictedPos = getPredictedPosition(murderer)
    if not predictedPos then return end

    local myHRP = character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local originPos = myHRP.Position
    if checkWallObstruction(originPos, predictedPos) then return end

    isReloading = true
    task.delay(1.5, function() 
        isReloading = false
    end)

    local originCFrame = myHRP:FindFirstChild("GunRaycastAttachment") and myHRP.GunRaycastAttachment.WorldCFrame or myHRP.CFrame
    local targetCFrame = CFrame.new(predictedPos)

    if ShootSoundObj and config.ash_shoot_sound_volume > 0 then
        ShootSoundObj.Volume = config.ash_shoot_sound_volume / 100
        ShootSoundObj:Play()
    end

    gun.Shoot:FireServer(originCFrame, targetCFrame)

    if config.ash_auto_unequip_gun then
        task.wait(0.04) 
        if humanoid and humanoid.Parent then
            humanoid:UnequipTools()
        end
    end
end

-- --- 5. RENDERIZADO VISUAL (ESP Y TRACERS) ---
local function startKnifeVisuals()
    if knifeEspConnection then knifeEspConnection:Disconnect() end

    if not KnifeBoxAdornment or not KnifeBoxAdornment.Parent then
        KnifeBoxAdornment = Instance.new("BoxHandleAdornment")
        KnifeBoxAdornment.Name = "HoneyKnife3DBox"
        KnifeBoxAdornment.Color3 = Color3.fromRGB(0, 255, 100) 
        KnifeBoxAdornment.Transparency = 0.15 
        KnifeBoxAdornment.AlwaysOnTop = true 
        KnifeBoxAdornment.ZIndex = 5 
        KnifeBoxAdornment.Parent = game.CoreGui
    end

    knifeEspConnection = RunService.RenderStepped:Connect(function()
        for knife in pairs(knifeStates) do 
            if not knife or not knife.Parent then knifeStates[knife] = nil end 
        end

        if config.ash_knife_esp_enabled then
            local murderer = getMurderer()
            local targetPart = nil

            if murderer and murderer.Character then
                local knifeTool = murderer.Character:FindFirstChild("Knife")
                if knifeTool and knifeTool:FindFirstChild("Handle") then targetPart = knifeTool.Handle end
            end

            if targetPart and targetPart:IsA("BasePart") then
                if KnifeBoxAdornment.Adornee ~= targetPart then 
                    KnifeBoxAdornment.Adornee = targetPart 
                    KnifeBoxAdornment.Size = targetPart.Size + Vector3.new(0.4, 0.4, 0.4) 
                end
                KnifeBoxAdornment.Visible = true
            else 
                KnifeBoxAdornment.Visible = false 
            end
        else
            KnifeBoxAdornment.Visible = false
        end

        if config.ash_knife_esp_enabled then
            for _, obj in ipairs(workspace:GetChildren()) do
                if (obj:IsA("BasePart") or obj:IsA("Model")) and (string.find(obj.Name, "Knife") or string.find(obj.Name, "Weapon")) then
                    if not obj:IsDescendantOf(Players) then
                        local mainPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                        if mainPart then
                            local currentPos = mainPart.Position
                            local state = knifeStates[obj]
                            local isMoving = true
                            
                            if not state then 
                                knifeStates[obj] = {lastPosition = currentPos, framesStuck = 0}
                            else
                                local distanceMoved = (currentPos - state.lastPosition).Magnitude
                                if distanceMoved < 0.05 then state.framesStuck = state.framesStuck + 1 else state.framesStuck = 0 end
                                state.lastPosition = currentPos
                                if state.framesStuck > 3 then isMoving = false end
                            end
                            
                            local hl = obj:FindFirstChild("HoneyKnifeHighlight")
                            if isMoving then
                                if not hl then
                                    hl = Instance.new("Highlight")
                                    hl.Name = "HoneyKnifeHighlight"
                                    hl.FillColor = Color3.fromRGB(0, 255, 100)
                                    hl.FillTransparency = 0.4
                                    hl.OutlineColor = Color3.fromRGB(0, 255, 0) 
                                    hl.OutlineTransparency = 0
                                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    hl.Parent = obj
                                end
                            else 
                                if hl then hl:Destroy() end 
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function removeKnifeVisuals()
    if knifeEspConnection then knifeEspConnection:Disconnect() knifeEspConnection = nil end
    if KnifeBoxAdornment then KnifeBoxAdornment:Destroy() KnifeBoxAdornment = nil end
    for _, obj in ipairs(workspace:GetChildren()) do
        local hl = obj:FindFirstChild("HoneyKnifeHighlight")
        if hl then hl:Destroy() end
    end
    knifeStates = {}
end

local function startInfiniteCrosshairLoop()
    task.spawn(function()
        while CrosshairFrame and CrosshairFrame.Parent do
            if config.ash_button_shape == "Square" and CrosshairFrame.Visible then
                local duration = 0.8 
                local startTime = os.clock()
                while CrosshairFrame and CrosshairFrame.Parent and (os.clock() - startTime) < duration do
                    local t = (os.clock() - startTime) / duration
                    local ease = t * t * (3 - 2 * t)
                    CrosshairFrame.Rotation = ease * 360 
                    task.wait()
                end
                if CrosshairFrame then CrosshairFrame.Rotation = 360 end
                task.wait(0.06)
                
                startTime = os.clock()
                while CrosshairFrame and CrosshairFrame.Parent and (os.clock() - startTime) < duration do
                    local t = (os.clock() - startTime) / duration
                    local ease = t * t * (3 - 2 * t)
                    CrosshairFrame.Rotation = 360 - (ease * 360)
                    task.wait()
                end
                if CrosshairFrame then CrosshairFrame.Rotation = 0 end
                task.wait(0.06)
            else
                task.wait(0.5)
            end
        end
    end)
end

local function startTracerLoop()
    if tracerRenderConnection then tracerRenderConnection:Disconnect() end
    
    tracerRenderConnection = RunService.RenderStepped:Connect(function()
        local murderer = getMurderer()
        local predictedPos = getPredictedPosition(murderer)

        -- Tracer Rojo (Predicción)
        if PredictionTracer and config.ash_tracer_enabled and predictedPos then
            local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
            if onScreen then
                local viewportSize = Camera.ViewportSize
                local startPos = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                local endPos = Vector2.new(screenPos.X, screenPos.Y)
                local diff = endPos - startPos
                local distance = diff.Magnitude
                local angle = math.deg(math.atan2(diff.Y, diff.X))

                PredictionTracer.Size = UDim2.new(0, distance, 0, 1) 
                PredictionTracer.Position = UDim2.new(0, startPos.X + (diff.X / 2), 0, startPos.Y + (diff.Y / 2))
                PredictionTracer.Rotation = angle
                PredictionTracer.Visible = true
            else
                PredictionTracer.Visible = false
            end
        elseif PredictionTracer then
            PredictionTracer.Visible = false
        end

        -- Tracer Verde (Lead Time)
        if LeadTimeTracer and config.ash_lead_time_tracer_enabled and murderer and murderer.Character and LocalPlayer.Character then
            local targetHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local leadTimeSeconds = config.ash_lead_time_value / 100
                local stabilizedY = math.clamp(smoothedVelocity.Y * 0.35, -2.5, 2.5)
                local customCalculatedPos = targetHRP.Position + Vector3.new(
                    smoothedVelocity.X * leadTimeSeconds,
                    stabilizedY * leadTimeSeconds,
                    smoothedVelocity.Z * leadTimeSeconds
                )
                local targetScreenPos, targetOnScreen = Camera:WorldToViewportPoint(customCalculatedPos)
                
                if targetOnScreen then
                    local rightHand = LocalPlayer.Character:FindFirstChild("RightHand") or LocalPlayer.Character:FindFirstChild("Right Arm")
                    if rightHand then
                        local handScreenPos = Camera:WorldToViewportPoint(rightHand.Position)
                        local startPos = Vector2.new(handScreenPos.X, handScreenPos.Y)
                        local endPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                        local diff = endPos - startPos
                        local distance = diff.Magnitude
                        local angle = math.deg(math.atan2(diff.Y, diff.X))

                        LeadTimeTracer.Size = UDim2.new(0, distance, 0, 1) 
                        LeadTimeTracer.Position = UDim2.new(0, startPos.X + (diff.X / 2), 0, startPos.Y + (diff.Y / 2))
                        LeadTimeTracer.Rotation = angle
                        LeadTimeTracer.Visible = true
                    else
                        LeadTimeTracer.Visible = false
                    end
                else
                    LeadTimeTracer.Visible = false
                end
            else
                LeadTimeTracer.Visible = false
            end
        elseif LeadTimeTracer then
            LeadTimeTracer.Visible = false
        end
    end)
end

-- --- 6. AGREGAR INTERFAZ DINÁMICA DEL BOTÓN FLOTANTE ---
local function updateTransparency(t)
    if not ShootButton then return end
    ShootButton.BackgroundTransparency = t
    UIStroke.Transparency = t
    ShootText.TextTransparency = t
    if crossCenter then crossCenter.BackgroundTransparency = t end
    if crossTop then crossTop.BackgroundTransparency = t end
    if crossBottom then crossBottom.BackgroundTransparency = t end
    if crossLeft then crossLeft.BackgroundTransparency = t end
    if crossRight then crossRight.BackgroundTransparency = t end
end

local function updateShape()
    if not ShootButton then return end
    if config.ash_button_shape == "Square" then
        ShootButton.Size = UDim2.new(0, config.ash_button_size_value, 0, config.ash_button_size_value)
        UICorner.CornerRadius = UDim.new(0, 30) 
        CrosshairFrame.Visible = true
        ShootText.Position = UDim2.new(0.5, 0, 0.8, 0)
        ShootText.TextSize = 13 
    elseif config.ash_button_shape == "Circle" then
        ShootButton.Size = UDim2.new(0, config.ash_button_size_value, 0, config.ash_button_size_value)
        UICorner.CornerRadius = UDim.new(1, 0) 
        CrosshairFrame.Visible = false 
        ShootText.Position = UDim2.new(0.5, 0, 0.5, 0) 
        ShootText.TextSize = 14 
    elseif config.ash_button_shape == "Rectangle" then
        ShootButton.Size = UDim2.new(0, math.floor(config.ash_button_size_value * 1.85), 0, math.floor(config.ash_button_size_value * 0.75))
        UICorner.CornerRadius = UDim.new(0, 18) 
        CrosshairFrame.Visible = false
        ShootText.Position = UDim2.new(0.5, 0, 0.5, 0)
        ShootText.TextSize = 13
    end
end

local function createCrossPart(parent, size, pos, color)
    local part = Instance.new("Frame", parent)
    part.Size = size
    part.Position = pos
    part.AnchorPoint = Vector2.new(0.5, 0.5)
    part.BackgroundColor3 = color
    part.BorderSizePixel = 0
    part.ZIndex = 102
    Instance.new("UICorner", part).CornerRadius = UDim.new(1, 0)
    return part
end

local function createFloatingButton()
    if ScreenGui then ScreenGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PrivateMobileLegitShootUI"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 99999

    local success, targetGui = pcall(function()
        return gethui and gethui() or LocalPlayer:WaitForChild("PlayerGui", 15)
    end)
    ScreenGui.Parent = success and targetGui or LocalPlayer:WaitForChild("PlayerGui")

    PredictionTracer = Instance.new("Frame", ScreenGui)
    PredictionTracer.Name = "PredictionTracerLine"
    PredictionTracer.AnchorPoint = Vector2.new(0.5, 0.5)
    PredictionTracer.BackgroundColor3 = Color3.fromRGB(255, 35, 35) 
    PredictionTracer.BackgroundTransparency = 0.25 
    PredictionTracer.BorderSizePixel = 0
    PredictionTracer.ZIndex = 1
    PredictionTracer.Visible = false

    LeadTimeTracer = Instance.new("Frame", ScreenGui)
    LeadTimeTracer.Name = "LeadTimeTracerLine"
    LeadTimeTracer.AnchorPoint = Vector2.new(0.5, 0.5)
    LeadTimeTracer.BackgroundColor3 = Color3.fromRGB(0, 255, 100) 
    LeadTimeTracer.BackgroundTransparency = 0.25 
    LeadTimeTracer.BorderSizePixel = 0
    LeadTimeTracer.ZIndex = 1
    LeadTimeTracer.Visible = false

    ShootButton = Instance.new("TextButton", ScreenGui)
    ShootButton.Position = UDim2.new(config.ash_button_x, config.ash_button_offset_x, config.ash_button_y, config.ash_button_offset_y)
    ShootButton.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
    ShootButton.Text = "" 
    ShootButton.AutoButtonColor = false
    ShootButton.ZIndex = 100
    ShootButton.Active = true 

    ShootSoundObj = Instance.new("Sound")
    ShootSoundObj.Name = "PrivateShootCustomSound"
    ShootSoundObj.SoundId = "rbxassetid://101735926591481"
    ShootSoundObj.Volume = config.ash_shoot_sound_volume / 100
    ShootSoundObj.Parent = ShootButton

    UICorner = Instance.new("UICorner", ShootButton)
    UIStroke = Instance.new("UIStroke", ShootButton)
    UIStroke.Thickness = 2
    UIStroke.Color = Color3.fromRGB(255, 35, 35) -- Combinación de borde Rojo con Fluent

    CrosshairFrame = Instance.new("Frame", ShootButton)
    CrosshairFrame.Size = UDim2.new(0, 50, 0, 50) 
    CrosshairFrame.Position = UDim2.new(0.5, 0, 0.42, 0)
    CrosshairFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    CrosshairFrame.BackgroundTransparency = 1
    CrosshairFrame.ZIndex = 101

    crossCenter = createCrossPart(CrosshairFrame, UDim2.new(0, 7, 0, 7), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(255, 35, 35))
    crossCenter.ZIndex = 103 

    crossTop = createCrossPart(CrosshairFrame, UDim2.new(0, 2.8, 0, 20), UDim2.new(0.5, 0, 0.5, -10.5), Color3.fromRGB(255, 255, 255))
    crossBottom = createCrossPart(CrosshairFrame, UDim2.new(0, 2.8, 0, 20), UDim2.new(0.5, 0, 0.5, 10.5), Color3.fromRGB(255, 255, 255))
    crossLeft = createCrossPart(CrosshairFrame, UDim2.new(0, 20, 0, 2.8), UDim2.new(0.5, -10.5, 0.5, 0), Color3.fromRGB(255, 255, 255))
    crossRight = createCrossPart(CrosshairFrame, UDim2.new(0, 20, 0, 2.8), UDim2.new(0.5, 10.5, 0.5, 0), Color3.fromRGB(255, 255, 255))

    ShootText = Instance.new("TextLabel", ShootButton)
    ShootText.Size = UDim2.new(1, 0, 0, 20)
    ShootText.AnchorPoint = Vector2.new(0.5, 0.5)
    ShootText.BackgroundTransparency = 1
    ShootText.Text = "SHOOT"
    ShootText.TextColor3 = Color3.fromRGB(255, 255, 255) 
    ShootText.Font = Enum.Font.GothamBold
    ShootText.ZIndex = 101

    updateShape() 
    updateTransparency(config.ash_button_transparency)

    startInfiniteCrosshairLoop()
    startTracerLoop()
    startKnifeVisuals()

    -- Sistema de Arrastre Adaptado
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    ShootButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ShootButton.Position
            hasMoved = false

            TweenService:Create(ShootButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(55, 15, 15)}):Play()

            local connection;
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    TweenService:Create(ShootButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 16, 32)}):Play()

                    config.ash_button_x = ShootButton.Position.X.Scale
                    config.ash_button_offset_x = ShootButton.Position.X.Offset
                    config.ash_button_y = ShootButton.Position.Y.Scale
                    config.ash_button_offset_y = ShootButton.Position.Y.Offset
                    saveConfig()
                    connection:Disconnect()
                end
            end)
        end
    end)

    ShootButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and not config.ash_lock_position then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then hasMoved = true end
            ShootButton.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X, 
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    ShootButton.MouseButton1Click:Connect(function()
        if not hasMoved then executePredictedShoot() end
    end)
end

local function removeFloatingButton()
    if tracerRenderConnection then tracerRenderConnection:Disconnect() tracerRenderConnection = nil end
    removeKnifeVisuals()
    if ShootSoundObj then ShootSoundObj:Destroy() ShootSoundObj = nil end
    if ScreenGui then ScreenGui:Destroy() ScreenGui = nil end
end

-- --- 7. PESTAÑAS Y CONTROLES DE LA INTERFAZ FLUENT ---
local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    Design = Window:AddTab({ Title = "Button Design", Icon = "palette" })
}

-- Pestaña: Combat
Tabs.Combat:AddToggle("ShowBtn", {Title = "Show Shoot Button", Default = config.ash_button_enabled})
:OnChanged(function(state)
    config.ash_button_enabled = state
    saveConfig()
    if state then createFloatingButton() else removeFloatingButton() end
end)

Tabs.Combat:AddToggle("PredTracer", {Title = "Enable Prediction Tracer (Red)", Default = config.ash_tracer_enabled})
:OnChanged(function(state)
    config.ash_tracer_enabled = state
    saveConfig()
end)

Tabs.Combat:AddToggle("LeadTracer", {Title = "Enable Lead Time Tracer (Green)", Default = config.ash_lead_time_tracer_enabled})
:OnChanged(function(state)
    config.ash_lead_time_tracer_enabled = state
    saveConfig()
end)

Tabs.Combat:AddToggle("WallCheck", {Title = "Enable Wall Check", Default = config.ash_wall_check_enabled})
:OnChanged(function(state)
    config.ash_wall_check_enabled = state
    saveConfig()
end)

Tabs.Combat:AddToggle("KnifeESP", {Title = "Knife ESP & Highlights", Default = config.ash_knife_esp_enabled})
:OnChanged(function(state)
    config.ash_knife_esp_enabled = state
    saveConfig()
end)

Tabs.Combat:AddSlider("HorizPred", {Title = "Horizontal Prediction", Min = 5, Max = 50, Default = config.horizIntensity, Rounding = 0})
:OnChanged(function(val)
    config.horizIntensity = val
    saveConfig()
end)

-- Pestaña: Button Design
Tabs.Design:AddToggle("AutoUnequip", {Title = "Auto Unequip Gun", Default = config.ash_auto_unequip_gun})
:OnChanged(function(state)
    config.ash_auto_unequip_gun = state
    saveConfig()
end)

Tabs.Design:AddToggle("LockPos", {Title = "Lock Button Position", Default = config.ash_lock_position})
:OnChanged(function(state)
    config.ash_lock_position = state
    saveConfig()
end)

Tabs.Design:AddSlider("Vol", {Title = "Shoot Sound Volume (%)", Min = 0, Max = 100, Default = config.ash_shoot_sound_volume, Rounding = 0})
:OnChanged(function(val)
    config.ash_shoot_sound_volume = val
    if ShootSoundObj then ShootSoundObj.Volume = val / 100 end
    saveConfig()
end)

Tabs.Design:AddSlider("BtnSize", {Title = "Shot Button Size (px)", Min = 60, Max = 150, Default = config.ash_button_size_value, Rounding = 0})
:OnChanged(function(val)
    config.ash_button_size_value = val
    updateShape()
    saveConfig()
end)

Tabs.Design:AddDropdown("BtnShape", {Title = "Shot Button Design", Values = {"Square", "Circle", "Rectangle"}, Default = config.ash_button_shape})
:OnChanged(function(option)
    config.ash_button_shape = option
    updateShape()
    saveConfig()
end)

Tabs.Design:AddSlider("BtnTrans", {Title = "Button Transparency (%)", Min = 0, Max = 100, Default = math.floor(config.ash_button_transparency * 100), Rounding = 0})
:OnChanged(function(val)
    local t = val / 100
    updateTransparency(t)
    config.ash_button_transparency = t
    saveConfig()
end)

-- --- 8. INICIALIZACIÓN DE INICIO ---
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(1.0) 
    if config.ash_button_enabled then
        createFloatingButton()
    end
end)

-- Al cerrar o desactivar el ejecutor, limpiamos las instancias
Window:SelectTab(Tabs.Combat)
Fluent:Notify({
    Title = "Private Hub",
    Content = "Script cargado con éxito. Desarrollado por Paolo.",
    Duration = 5
})
