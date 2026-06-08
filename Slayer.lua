-- --- 1. CONFIGURACIÓN DE LA INTERFAZ FLUENT ---
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Private hub",
    [span_6](start_span)Subtitle = "by Paolo", -- ¡Tus créditos aquí[span_6](end_span)!
    TabWidth = 160,
    Size = UDim2.fromOffset(530, 420),
    Acrylic = true, -- Efecto difuminado de fondo
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Para PC, en móvil trae botón flotante solo
})

-- Aplicamos tu tema personalizado Negro y Rojo
Fluent:OverrideTheme({
    Background = Color3.fromRGB(12, 12, 12),       -- Negro Profundo
    MainFocused = Color3.fromRGB(18, 18, 18),      -- Paneles internos oscuros
    Accent = Color3.fromRGB(255, 35, 35),          -- Rojo Intenso para botones activos y sliders
    TitleText = Color3.fromRGB(255, 255, 255),     -- Texto blanco
})

-- --- 2. SISTEMA DE GUARDADO PROPIO (.JSON) ---
local HttpService = game:GetService("HttpService")
local configFileName = "PrivateHub_MurderConfig.json"

-[span_7](start_span)- Valores por defecto sacados de tu plugin original[span_7](end_span)
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
    if writefile then
        pcall(function()
            writefile(configFileName, HttpService:JSONEncode(config))
        end)
    end
end

local function loadConfig()
    if readfile and isfile and isfile(configFileName) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(configFileName)) end)
        if success then
            for k, v in pairs(decoded) do config[k] = v end
        end
    end
end
loadConfig()

-[span_8](start_span)- Traspasamos la configuración a las variables del script[span_8](end_span)
local buttonSize = config.ash_button_size_value
local buttonShape = config.ash_button_shape
local buttonTransparency = config.ash_button_transparency
local lockPosition = config.ash_lock_position
local autoUnequip = config.ash_auto_unequip_gun
local soundVolume = config.ash_shoot_sound_volume
local savedX, savedY = config.ash_button_x, config.ash_button_y
local savedOffsetX, savedOffsetY = config.ash_button_offset_x, config.ash_button_offset_y
local buttonEnabled = config.ash_button_enabled
local tracerEnabled = config.ash_tracer_enabled
local leadTimeTracerEnabled = config.ash_lead_time_tracer_enabled
local wallCheckEnabled = config.ash_wall_check_enabled
local knifeEspEnabled = config.ash_knife_esp_enabled
local horizIntensity = config.horizIntensity
local vertIntensity = config.vertIntensity
local leadTimeValue = config.ash_lead_time_value
local responsiveValue = config.ash_responsive_value

-- --- 3. SERVICIOS Y LÓGICA DEL MOTOR DE TIRO ---
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local ScreenGui, ShootButton, UICorner, UIStroke, CrosshairFrame, ShootText
local PredictionTracer, LeadTimeTracer, KnifeBoxAdornment, ShootSoundObj
local crossCenter, crossTop, crossBottom, crossLeft, crossRight
local tracerRenderConnection, knifeEspConnection, thrownKnifeConnection
local knifeStates = {}
local smoothedVelocity = Vector3.new(0, 0, 0)
local lastTarget = nil
local isReloading = false

local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.IgnoreWater = true

local function getMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            [span_9](start_span)if player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then[span_9](end_span)
                return player
            end
        end
    end
    return nil
end

local function getGun()
    if LocalPlayer.Character then
        [span_10](start_span)local gun = LocalPlayer.Character:FindFirstChild("Gun")[span_10](end_span)
        [span_11](start_span)if gun and gun:FindFirstChild("Shoot") then return gun end[span_11](end_span)
    end
    [span_12](start_span)local gunInBackpack = LocalPlayer.Backpack:FindFirstChild("Gun")[span_12](end_span)
    [span_13](start_span)if gunInBackpack and gunInBackpack:FindFirstChild("Shoot") then return gunInBackpack end[span_13](end_span)
    return nil
end

local function getPredictedPosition(murderer)
    [span_14](start_span)if not murderer or not murderer.Character or not murderer.Character:FindFirstChild("HumanoidRootPart") then[span_14](end_span)
        return nil
    end
    [span_15](start_span)local targetHRP = murderer.Character.HumanoidRootPart[span_15](end_span)
    [span_16](start_span)local currentVelocity = targetHRP.AssemblyLinearVelocity[span_16](end_span)
    [span_17](start_span)if lastTarget ~= murderer then[span_17](end_span)
        smoothedVelocity = currentVelocity
        [span_18](start_span)[span_19](start_span)lastTarget = murderer[span_18](end_span)[span_19](end_span)
    end
    [span_20](start_span)local lerpAlpha = math.clamp(responsiveValue / 100, 0.1, 1.0)[span_20](end_span)
    [span_21](start_span)smoothedVelocity = smoothedVelocity:Lerp(currentVelocity, lerpAlpha)[span_21](end_span)
    [span_22](start_span)local scaleH = horizIntensity / 100[span_22](end_span)
    [span_23](start_span)local scaleV = (vertIntensity / 100) * 0.35[span_23](end_span)
    [span_24](start_span)local rawPredY = smoothedVelocity.Y * scaleV[span_24](end_span)
    [span_25](start_span)local clampedPredY = math.clamp(rawPredY, -1.8, 1.8)[span_25](end_span)
    [span_26](start_span)return targetHRP.Position + Vector3.new(smoothedVelocity.X * scaleH, clampedPredY, smoothedVelocity.Z * scaleH)[span_26](end_span)
end

local function checkWallObstruction(origin, targetPosition)
    [span_27](start_span)if not wallCheckEnabled or not LocalPlayer.Character then return false end[span_27](end_span)
    [span_28](start_span)wallCheckParams.FilterDescendantsInstances = {LocalPlayer.Character}[span_28](end_span)
    [span_29](start_span)local direction = targetPosition - origin[span_29](end_span)
    [span_30](start_span)local raycastResult = workspace:Raycast(origin, direction, wallCheckParams)[span_30](end_span)
    if raycastResult then
        local hitInstance = raycastResult.Instance
        [span_31](start_span)if hitInstance.CanCollide == false then return false end[span_31](end_span)
        [span_32](start_span)local model = hitInstance:FindFirstAncestorOfClass("Model")[span_32](end_span)
        [span_33](start_span)if model and model:FindFirstChildOfClass("Humanoid") then return false end[span_33](end_span)
        return true
    end
    return false
end

local function executePredictedShoot()
    [span_34](start_span)if ShootSoundObj and soundVolume > 0 then[span_34](end_span)
        [span_35](start_span)ShootSoundObj.Volume = soundVolume / 100[span_35](end_span)
        [span_36](start_span)ShootSoundObj:Play()[span_36](end_span)
    end
    [span_37](start_span)if isReloading then return end[span_37](end_span)
    local gun = getGun()
    [span_38](start_span)if not gun then return end[span_38](end_span)
    local character = LocalPlayer.Character
    [span_39](start_span)local humanoid = character and character:FindFirstChildOfClass("Humanoid")[span_39](end_span)
    [span_40](start_span)if not humanoid or humanoid.Health <= 0 then return end[span_40](end_span)
    [span_41](start_span)if gun.Parent == LocalPlayer.Backpack then[span_41](end_span)
        [span_42](start_span)humanoid:EquipTool(gun)[span_42](end_span)
        task.wait(0.05)
    end
    local murderer = getMurderer()
    [span_43](start_span)local predictedPos = getPredictedPosition(murderer)[span_43](end_span)
    [span_44](start_span)if not predictedPos then return end[span_44](end_span)
    [span_45](start_span)local myHRP = character:FindFirstChild("HumanoidRootPart")[span_45](end_span)
    [span_46](start_span)if not myHRP then return end[span_46](end_span)
    [span_47](start_span)local originPos = myHRP.Position[span_47](end_span)
    [span_48](start_span)if checkWallObstruction(originPos, predictedPos) then return end[span_48](end_span)
    [span_49](start_span)isReloading = true[span_49](end_span)
    [span_50](start_span)task.delay(1.5, function() isReloading = false end)[span_50](end_span)
    [span_51](start_span)local originCFrame = myHRP:FindFirstChild("GunRaycastAttachment") and myHRP.GunRaycastAttachment.WorldCFrame or myHRP.CFrame[span_51](end_span)
    [span_52](start_span)local targetCFrame = CFrame.new(predictedPos)[span_52](end_span)
    [span_53](start_span)gun.Shoot:FireServer(originCFrame, targetCFrame)[span_53](end_span)
    [span_54](start_span)if autoUnequip then[span_54](end_span)
        [span_55](start_span)task.wait(0.04)[span_55](end_span)
        [span_56](start_span)if humanoid and humanoid.Parent then[span_56](end_span)
            [span_57](start_span)humanoid:UnequipTools()[span_57](end_span)
        end
    end
end

-- --- 4. CÓDIGO VISUAL (ESP, BOTÓN, TRACERS) ---
-- [Mantenemos intactas tus funciones del plugin original para que no pierda poder]
local function startKnifeVisuals()
    if knifeEspConnection then knifeEspConnection:Disconnect() end
    if thrownKnifeConnection then thrownKnifeConnection:Disconnect() end
    if not KnifeBoxAdornment or not KnifeBoxAdornment.Parent then
        KnifeBoxAdornment = Instance.new("BoxHandleAdornment")
        KnifeBoxAdornment.Name = "PrivateKnife3DBox"
        KnifeBoxAdornment.Color3 = Color3.fromRGB(0, 255, 100)
        KnifeBoxAdornment.Transparency = 0.15
        KnifeBoxAdornment.AlwaysOnTop = true
        KnifeBoxAdornment.ZIndex = 5
        KnifeBoxAdornment.Parent = game.CoreGui
    end
    knifeEspConnection = RunService.RenderStepped:Connect(function()
        for knife in pairs(knifeStates) do if not knife or not knife.Parent then knifeStates[knife] = nil end end
        if knifeEspEnabled then
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
            else KnifeBoxAdornment.Visible = false end
        else KnifeBoxAdornment.Visible = false end

        if knifeEspEnabled then
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
                            local hl = obj:FindFirstChild("PrivateKnifeHighlight")
                            if isMoving then
                                if not hl then
                                    hl = Instance.new("Highlight")
                                    hl.Name = "PrivateKnifeHighlight"
                                    hl.FillColor = Color3.fromRGB(0, 255, 100)
                                    hl.FillTransparency = 0.4
                                    hl.OutlineColor = Color3.fromRGB(0, 255, 0)
                                    hl.OutlineTransparency = 0
                                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    hl.Parent = obj
                                end
                            else if hl then hl:Destroy() end end
                        end
                    end
                end
            end
        end
    end)
end

local function removeKnifeVisuals()
    if knifeEspConnection then knifeEspConnection:Disconnect() knifeEspConnection = nil end
    if thrownKnifeConnection then thrownKnifeConnection:Disconnect() thrownKnifeConnection = nil end
    if KnifeBoxAdornment then KnifeBoxAdornment:Destroy() KnifeBoxAdornment = nil end
    for _, obj in ipairs(workspace:GetChildren()) do
        local hl = obj:FindFirstChild("PrivateKnifeHighlight")
        if hl then hl:Destroy() end
    end
    knifeStates = {}
end

local function startInfiniteCrosshairLoop()
    task.spawn(function()
        while CrosshairFrame and CrosshairFrame.Parent do
            if buttonShape == "Square" and CrosshairFrame.Visible then
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
            else task.wait(0.5) end
        end
    end)
end

local function startTracerLoop()
    if tracerRenderConnection then tracerRenderConnection:Disconnect() end
    tracerRenderConnection = RunService.RenderStepped:Connect(function()
        local murderer = getMurderer()
        local predictedPos = getPredictedPosition(murderer)

        if PredictionTracer and tracerEnabled and predictedPos then
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
            else PredictionTracer.Visible = false end
        elseif PredictionTracer then PredictionTracer.Visible = false end

        if LeadTimeTracer and leadTimeTracerEnabled and murderer and murderer.Character and LocalPlayer.Character then
            local targetHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local leadTimeSeconds = leadTimeValue / 100
                local stabilizedY = math.clamp(smoothedVelocity.Y * 0.35, -2.5, 2.5)
                local customCalculatedPos = targetHRP.Position + Vector3.new(smoothedVelocity.X * leadTimeSeconds, stabilizedY * leadTimeSeconds, smoothedVelocity.Z * leadTimeSeconds)
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
                    else LeadTimeTracer.Visible = false end
                else LeadTimeTracer.Visible = false end
            else LeadTimeTracer.Visible = false end
        elseif LeadTimeTracer then LeadTimeTracer.Visible = false end
    end)
end

local function updateTransparency(t)
    if not ShootButton then return end
    buttonTransparency = t
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
    if buttonShape == "Square" then
        ShootButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
        UICorner.CornerRadius = UDim.new(0, 30)
        CrosshairFrame.Visible = true
        ShootText.Position = UDim2.new(0.5, 0, 0.8, 0)
        ShootText.TextSize = 13
    elseif buttonShape == "Circle" then
        ShootButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
        UICorner.CornerRadius = UDim.new(1, 0)
        CrosshairFrame.Visible = false
        ShootText.Position = UDim2.new(0.5, 0, 0.5, 0)
        ShootText.TextSize = 14
    elseif buttonShape == "Rectangle" then
        ShootButton.Size = UDim2.new(0, math.floor(buttonSize * 1.85), 0, math.floor(buttonSize * 0.75))
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
    ScreenGui.Name = "PrivateMobileShootUI"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 99999

    local success, targetGui = pcall(function() return gethui and gethui() or LocalPlayer:WaitForChild("PlayerGui", 15) end)
    ScreenGui.Parent = success and targetGui or LocalPlayer:WaitForChild("PlayerGui")

    PredictionTracer = Instance.new("Frame", ScreenGui)
    PredictionTracer.AnchorPoint = Vector2.new(0.5, 0.5)
    PredictionTracer.BackgroundColor3 = Color3.fromRGB(255, 35, 35)
    PredictionTracer.BackgroundTransparency = 0.25
    PredictionTracer.ZIndex = 1
    PredictionTracer.Visible = false

    LeadTimeTracer = Instance.new("Frame", ScreenGui)
    LeadTimeTracer.AnchorPoint = Vector2.new(0.5, 0.5)
    LeadTimeTracer.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    LeadTimeTracer.BackgroundTransparency = 0.25
    LeadTimeTracer.ZIndex = 1
    LeadTimeTracer.Visible = false

    ShootButton = Instance.new("TextButton", ScreenGui)
    ShootButton.Position = UDim2.new(savedX, savedOffsetX, savedY, savedOffsetY)
    ShootButton.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
    ShootButton.Text = ""
    ShootButton.AutoButtonColor = false
    ShootButton.ZIndex = 100
    ShootButton.Active = true

    ShootSoundObj = Instance.new("Sound")
    ShootSoundObj.SoundId = "rbxassetid://101735926591481"
    ShootSoundObj.Volume = soundVolume / 100
    ShootSoundObj.Parent = ShootButton

    UICorner = Instance.new("UICorner", ShootButton)
    UIStroke = Instance.new("UIStroke", ShootButton)
    UIStroke.Thickness = 2
    UIStroke.Color = Color3.fromRGB(255, 35, 35) -- Borde Rojo estilo tu nuevo tema

    CrosshairFrame = Instance.new("Frame", ShootButton)
    CrosshairFrame.Size = UDim2.new(0, 50, 0, 50)
    CrosshairFrame.Position = UDim2.new(0.5, 0, 0.42, 0)
    CrosshairFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    CrosshairFrame.BackgroundTransparency = 1
    CrosshairFrame.ZIndex = 101

    crossCenter = createCrossPart(CrosshairFrame, UDim2.new(0, 7, 0, 7), UDim2.new(0.5, 0, 0.5, 0), Color3.fromRGB(255, 35, 35))
    crossCenter.ZIndex = 103
    crossTop = createCrossPart(CrosshairFrame, UDim2.new(0, 2.8, 0, 19), UDim2.new(0.5, 0, 0.5, -10.5), Color3.fromRGB(255, 255, 255))
    crossBottom = createCrossPart(CrosshairFrame, UDim2.new(0, 2.8, 0, 19), UDim2.new(0.5, 0, 0.5, 10.5), Color3.fromRGB(255, 255, 255))
    crossLeft = createCrossPart(CrosshairFrame, UDim2.new(0, 19, 0, 2.8), UDim2.new(0.5, -10.5, 0.5, 0), Color3.fromRGB(255, 255, 255))
    crossRight = createCrossPart(CrosshairFrame, UDim2.new(0, 19, 0, 2.8), UDim2.new(0.5, 10.5, 0.5, 0), Color3.fromRGB(255, 255, 255))

    ShootText = Instance.new("TextLabel", ShootButton)
    ShootText.Size = UDim2.new(1, 0, 0, 20)
    ShootText.AnchorPoint = Vector2.new(0.5, 0.5)
    ShootText.BackgroundTransparency = 1
    ShootText.Text = "SHOOT"
    ShootText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ShootText.Font = Enum.Font.GothamBold
    ShootText.ZIndex = 101

    updateShape()
    updateTransparency(buttonTransparency)
    startInfiniteCrosshairLoop()
    startTracerLoop()
    startKnifeVisuals()

    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    ShootButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ShootButton.Position
            hasMoved = false
            TweenService:Create(ShootButton, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 15, 15)}):Play()
            local connection; connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    TweenService:Create(ShootButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 16, 32)}):Play()
                    savedX = ShootButton.Position.X.Scale
                    savedOffsetX = ShootButton.Position.X.Offset
                    savedY = ShootButton.Position.Y.Scale
                    savedOffsetY = ShootButton.Position.Y.Offset
                    config.ash_button_x = savedX
                    config.ash_button_offset_x = savedOffsetX
                    config.ash_button_y = savedY
                    config.ash_button_offset_y = savedOffsetY
                    saveConfig()
                    connection:Disconnect()
                end
            end)
        end
    end)

    ShootButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging and not lockPosition then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then hasMoved = true end
            ShootButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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

-- --- 5. ESTRUCTURA Y ORGANIZACIÓN DE LAS PESTAÑAS (FLUENT) ---
local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }) -- Creación de pestaña Combat
}

-- Sección 1: Toggles Principales
local SectionMain = Tabs.Combat:AddSection("Main Toggles")

local ToggleButton = Tabs.Combat:AddToggle("ShowShootBtn", {Title = "Show Shoot Button", Default = buttonEnabled})
ToggleButton:OnChanged(function(state)
    buttonEnabled = state
    config.ash_button_enabled = state
    saveConfig()
    if state then createFloatingButton() else removeFloatingButton() end
end)

local ToggleTracer = Tabs.Combat:AddToggle("PredTracer", {Title = "Enable Prediction Tracer (Red)", Default = tracerEnabled})
ToggleTracer:OnChanged(function(state)
    tracerEnabled = state
    config.ash_tracer_enabled = state
    saveConfig()
end)

local ToggleLead = Tabs.Combat:AddToggle("LeadTracer", {Title = "Enable Lead Time Tracer (Green)", Default = leadTimeTracerEnabled})
ToggleLead:OnChanged(function(state)
    leadTimeTracerEnabled = state
    config.ash_lead_time_tracer_enabled = state
    saveConfig()
end)

local ToggleWall = Tabs.Combat:AddToggle("WallCheck", {Title = "Enable Wall Check", Default = wallCheckEnabled})
ToggleWall:OnChanged(function(state)
    wallCheckEnabled = state
    config.ash_wall_check_enabled = state
    saveConfig()
end)

local ToggleEsp = Tabs.Combat:AddToggle("KnifeEsp", {Title = "Knife ESP & Thrown Highlight", Default = knifeEspEnabled})
ToggleEsp:OnChanged(function(state)
    knifeEspEnabled = state
    config.ash_knife_esp_enabled = state
    saveConfig()
end)

-- Sección 2: Ajustes de Predicción
local SectionPred = Tabs.Combat:AddSection("Prediction Settings")

local SliderHoriz = Tabs.Combat:AddSlider("HorizPred", {Title = "Horizontal Prediction", Min = 5, Max = 50, Default = horizIntensity, Rounding = 0})
SliderHoriz:OnChanged(function(val)
    horizIntensity = val
    config.horizIntensity = val
    saveConfig()
end)

local SliderVert = Tabs.Combat:AddSlider("VertPred", {Title = "Vertical Prediction", Min = 5, Max = 50, Default = vertIntensity, Rounding = 0})
SliderVert:OnChanged(function(val)
    vertIntensity = val
    config.vertIntensity = val
    saveConfig()
end)

local SliderLeadVal = Tabs.Combat:AddSlider("LeadVal", {Title = "Lead Time (15 = 0.15s / 30 = 0.30s)", Min = 0, Max = 100, Default = leadTimeValue, Rounding = 0})
SliderLeadVal:OnChanged(function(val)
    leadTimeValue = val
    config.ash_lead_time_value = val
    saveConfig()
end)

local SliderResp = Tabs.Combat:AddSlider("RespPred", {Title = "Prediction Responsiveness (Reacción)", Min = 10, Max = 100, Default = responsiveValue, Rounding = 0})
SliderResp:OnChanged(function(val)
    responsiveValue = val
    config.ash_responsive_value = val
    saveConfig()
end)

-- Sección 3: Personalización del Botón
local SectionBtn = Tabs.Combat:AddSection("Button Customization")

local SliderVol = Tabs.Combat:AddSlider("SoundVol", {Title = "Shoot Sound Volume (%)", Min = 0, Max = 100, Default = soundVolume, Rounding = 0})
SliderVol = SliderVol:OnChanged(function(val)
    soundVolume = val
    if ShootSoundObj then ShootSoundObj.Volume = val / 100 end
    config.ash_shoot_sound_volume = val
    saveConfig()
end)

local ToggleUnequip = Tabs.Combat:AddToggle("AutoUnequip", {Title = "Auto Unequip Gun", Default = autoUnequip})
ToggleUnequip:OnChanged(function(state)
    autoUnequip = state
    config.ash_auto_unequip_gun = state
    saveConfig()
end)

local ToggleLock = Tabs.Combat:AddToggle("LockPos", {Title = "Lock Button Position", Default = lockPosition})
ToggleLock:OnChanged(function(state)
    lockPosition = state
    config.ash_lock_position = state
    saveConfig()
end)

local SliderSize = Tabs.Combat:AddSlider("BtnSize", {Title = "Shot Button Size (px)", Min = 60, Max = 150, Default = buttonSize, Rounding = 0})
SliderSize:OnChanged(function(val)
    buttonSize = val
    updateShape()
    config.ash_button_size_value = val
    saveConfig()
end)

local DropShape = Tabs.Combat:AddDropdown("BtnShape", {Title = "Shot Button Design", Values = {"Square", "Circle", "Rectangle"}, Default = buttonShape})
DropShape:OnChanged(function(option)
    buttonShape = option
    updateShape()
    config.ash_button_shape = option
    saveConfig()
end)

local SliderTrans = Tabs.Combat:AddSlider("BtnTrans", {Title = "Button Transparency (%)", Min = 0, Max = 100, Default = math.floor(buttonTransparency * 100), Rounding = 0})
SliderTrans:OnChanged(function(val)
    local t = val / 100
    updateTransparency(t)
    config.ash_button_transparency = t
    saveConfig()
end)

-- Selector por defecto para Fluent al cargar
Window:SelectTab(Tabs.Combat)

-- --- 6. CONTROL DE INICIO ---
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(1.0)
    if buttonEnabled then createFloatingButton() end
end)
