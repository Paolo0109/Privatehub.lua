-- ============================================================================
-- 🩸 KILLER HUB UNIVERSAL FRAMEWORK | MASTER EXPERT EDITION (V3.0)
-- 🧑‍💻 Desarrollado por: Paolo
-- 🚀 Parches: Fix de Desborde en Inputs (AnchorPoint), Sliders de Configuración 1 en 1
-- ============================================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local TargetParent = (gethui and gethui()) or (pcall(function() return CoreGui.Name end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")

if TargetParent:FindFirstChild("KillerHub_Universal") then
    TargetParent.KillerHub_Universal:Destroy()
end

-- ============================================================================
-- 🎨 PALETAS DE COLORES REALINEADAS
-- ============================================================================
local Themes = {
    ["Void Premium"] = {
        BG_MAIN = Color3.fromRGB(8, 5, 12),
        BG_SIDEBAR = Color3.fromRGB(11, 8, 16),
        BG_SECONDARY = Color3.fromRGB(15, 11, 22),
        ACCENT = Color3.fromRGB(138, 43, 226),
        TEXT_WHITE = Color3.fromRGB(245, 240, 255),
        TEXT_MUTED = Color3.fromRGB(130, 115, 145),
        BORDER = Color3.fromRGB(40, 20, 65)
    },
    ["Crimson Dark"] = {
        BG_MAIN = Color3.fromRGB(11, 11, 13),
        BG_SIDEBAR = Color3.fromRGB(14, 14, 16),
        BG_SECONDARY = Color3.fromRGB(18, 18, 22),
        ACCENT = Color3.fromRGB(235, 35, 35),
        TEXT_WHITE = Color3.fromRGB(245, 245, 245),
        TEXT_MUTED = Color3.fromRGB(140, 130, 130),
        BORDER = Color3.fromRGB(38, 28, 28)
    },
    ["Classic Dark"] = {
        BG_MAIN = Color3.fromRGB(15, 15, 15),
        BG_SIDEBAR = Color3.fromRGB(20, 20, 20),
        BG_SECONDARY = Color3.fromRGB(25, 25, 25),
        ACCENT = Color3.fromRGB(245, 245, 245),
        TEXT_WHITE = Color3.fromRGB(245, 245, 245),
        TEXT_MUTED = Color3.fromRGB(130, 130, 130),
        BORDER = Color3.fromRGB(40, 40, 40)
    },
    ["Blood"] = {
        BG_MAIN = Color3.fromRGB(12, 12, 12),       
        BG_SIDEBAR = Color3.fromRGB(15, 13, 13),    
        BG_SECONDARY = Color3.fromRGB(20, 16, 16),  
        ACCENT = Color3.fromRGB(185, 0, 0),         
        TEXT_WHITE = Color3.fromRGB(250, 245, 245), 
        TEXT_MUTED = Color3.fromRGB(140, 115, 115), 
        BORDER = Color3.fromRGB(50, 20, 20)         
    }
}

local CurrentTheme = Themes["Void Premium"]

-- ============================================================================
-- 💾 ALMACENAMIENTO DE PARÁMETROS LOCALES (ESCALAS PRECISAS)
-- ============================================================================
local CONFIG_FILE = "KillerHub_Universal_Config.json"
local DefaultConfig = {
    Volume = 50, ToggleKey = "RightControl", SelectedTheme = "Void Premium",
    GuiWidth = 50, GuiHeight = 50, UiOpacity = 100, ToggleBtnSize = 46
}
local Config, Flags, Connections = {}, {}, {}

local function connect(event, callback)
    local conn = event:Connect(callback)
    table.insert(Connections, conn)
    return conn
end

for k, v in pairs(DefaultConfig) do Config[k] = v end

local function saveConfig()
    if writefile then pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end) end
end

pcall(function()
    if isfile and readfile and isfile(CONFIG_FILE) then
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(data) == "table" then for k, v in pairs(data) do Config[k] = v end end
    end
end)

if Themes[Config.SelectedTheme] then CurrentTheme = Themes[Config.SelectedTheme] end

local function create(instanceType, properties, parent)
    local obj = Instance.new(instanceType)
    for prop, val in pairs(properties) do obj[prop] = val end
    if parent then obj.Parent = parent end
    return obj
end

local function playUISound()
    if not Config.Volume or Config.Volume <= 0 then return end
    local sound = create("Sound", {SoundId = "rbxassetid://101735926591481", Volume = Config.Volume / 100}, SoundService)
    sound:Play() Debris:AddItem(sound, 1.5)
end

-- ============================================================================
-- 🖥️ ENTORNO GRÁFICO SEGURO
-- ============================================================================
local ScreenGui = create("ScreenGui", {
    Name = "KillerHub_Universal", 
    IgnoreGuiInset = true, 
    ScreenInsets = Enum.ScreenInsets.None, 
    ResetOnSpawn = false, 
    DisplayOrder = 999999, 
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, TargetParent)

local MainFrame = create("Frame", {Name = "MainFrame", BackgroundColor3 = CurrentTheme.BG_MAIN, BorderSizePixel = 0, Active = true, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0)}, ScreenGui)
local MainStroke = create("UIStroke", {Thickness = 1.2, Color = CurrentTheme.BORDER}, MainFrame)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, MainFrame)

local BordeGradient = create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 35, 45)),
        ColorSequenceKeypoint.new(0.5, CurrentTheme.ACCENT),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 25))
    }), Rotation = 45
}, MainStroke)

local function updateGuiSize()
    local wOffset = ((Config.GuiWidth or 50) / 100) * 280
    local hOffset = ((Config.GuiHeight or 50) / 100) * 230
    MainFrame.Size = UDim2.new(0, math.floor(430 + wOffset), 0, math.floor(280 + hOffset))
end
updateGuiSize()

local Topbar = create("Frame", {Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = CurrentTheme.BG_MAIN, BorderSizePixel = 0, Active = true}, MainFrame)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, Topbar)
local TopbarPatch = create("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = CurrentTheme.BG_MAIN, BorderSizePixel = 0}, Topbar)

local Title = create("TextLabel", {Size = UDim2.new(0, 250, 1, 0), Position = UDim2.new(0, 18, 0, 0), BackgroundTransparency = 1, Text = "Killer Hub | Premium v3.0 👻", TextColor3 = CurrentTheme.ACCENT, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 14}, Topbar)
local DecorLine = create("Frame", {Size = UDim2.new(0, 50, 0, 2), Position = UDim2.new(0, 18, 1, -2), BackgroundColor3 = CurrentTheme.ACCENT, BorderSizePixel = 0}, Topbar)
local PerformanceLabel = create("TextLabel", {Size = UDim2.new(0, 160, 1, 0), Position = UDim2.new(1, -15, 0, 0), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Text = "FPS: -- | PING: --", TextColor3 = CurrentTheme.TEXT_MUTED, TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium, TextSize = 11}, Topbar)

task.spawn(function()
    while task.wait(1) do
        if ScreenGui and ScreenGui.Parent then
            local fps = math.floor(Workspace:GetRealPhysicsFPS())
            local ping = 0
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
            PerformanceLabel.Text = string.format("FPS: %d | PING: %dms", fps, ping)
        else break end
    end
end)

-- ============================================================================
-- 🕹️ MOTOR DE ARRASTRE SIN DESFASES
-- ============================================================================
local function makeDraggable(clickObject, dragObject)
    local dragging, dragStart, startPos
    connect(clickObject.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragObject.Position
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            task.defer(function()
                local delta = input.Position - dragStart
                local screenSize = ScreenGui.AbsoluteSize
                if dragObject == MainFrame then
                    local frameSize = MainFrame.AbsoluteSize
                    local absoluteX = (screenSize.X * 0.5) + (startPos.X.Offset + delta.X)
                    local absoluteY = (screenSize.Y * 0.5) + (startPos.Y.Offset + delta.Y)
                    local clampedX = math.clamp(absoluteX, frameSize.X / 2, screenSize.X - (frameSize.X / 2))
                    local clampedY = math.clamp(absoluteY, frameSize.Y / 2, screenSize.Y - (frameSize.Y / 2))
                    dragObject.Position = UDim2.new(0.5, clampedX - (screenSize.X * 0.5), 0.5, clampedY - (screenSize.Y * 0.5))
                else
                    local btnSize = dragObject.AbsoluteSize
                    local newX = math.clamp(startPos.X.Offset + delta.X, 0, screenSize.X - btnSize.X)
                    local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, screenSize.Y - btnSize.Y)
                    dragObject.Position = UDim2.new(0, newX, 0, newY)
                end
            end)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

makeDraggable(Topbar, MainFrame)

local Sidebar = create("Frame", {Name = "Sidebar", Size = UDim2.new(0, 125, 1, -45), Position = UDim2.new(0, 0, 0, 45), BackgroundColor3 = CurrentTheme.BG_SIDEBAR, BorderSizePixel = 0, Active = true}, MainFrame)
local SidebarLine = create("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Color3.fromRGB(24, 24, 28), BorderSizePixel = 0}, Sidebar)

local SearchBoxContainer = create("Frame", {Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0, 6, 0, 8), BackgroundColor3 = CurrentTheme.BG_SECONDARY}, Sidebar)
create("UICorner", {CornerRadius = UDim.new(0, 5)}, SearchBoxContainer)
local SearchInput = create("TextBox", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, PlaceholderText = "Buscar...", PlaceholderColor3 = CurrentTheme.TEXT_MUTED, Text = "", TextColor3 = CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamMedium, TextSize = 11, ClearTextOnFocus = false}, SearchBoxContainer)

local SidebarTabsContainer = create("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -85), Position = UDim2.new(0, 0, 0, 38), BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0}, Sidebar)
local SidebarListLayout = create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}, SidebarTabsContainer)
create("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, SidebarTabsContainer)

connect(SidebarListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
    SidebarTabsContainer.CanvasSize = UDim2.new(0, 0, 0, SidebarListLayout.AbsoluteContentSize.Y + 10)
end)

local SettingsContainer = create("Frame", {Size = UDim2.new(1, -12, 0, 36), Position = UDim2.new(0, 6, 1, -42), BackgroundTransparency = 1}, Sidebar)
local ContentContainer = create("Frame", {Name = "ContentContainer", Size = UDim2.new(1, -125, 1, -45), Position = UDim2.new(0, 125, 0, 45), BackgroundTransparency = 1, Active = true}, MainFrame)

local OpenCloseBtn = create("TextButton", {Name = "KillerHubToggle", Size = UDim2.new(0, 46, 0, 46), Position = UDim2.new(0, 15, 0, 100), BackgroundColor3 = CurrentTheme.BG_MAIN, Text = "", Active = true}, ScreenGui)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, OpenCloseBtn)
local FloatingStroke = create("UIStroke", {Thickness = 1.5, Color = CurrentTheme.BORDER}, OpenCloseBtn)
local BtnIcon = create("ImageLabel", {Name = "Icon", Size = UDim2.new(1, 0, 1, 0), ScaleType = Enum.ScaleType.Crop, BackgroundTransparency = 1, Image = "rbxassetid://84689030731870", ImageColor3 = CurrentTheme.ACCENT}, OpenCloseBtn)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, BtnIcon)

makeDraggable(OpenCloseBtn, OpenCloseBtn)

local function updateUiOpacity()
    local trans = 1 - ((Config.UiOpacity or 100) / 100)
    MainFrame.BackgroundTransparency = trans Topbar.BackgroundTransparency = trans Sidebar.BackgroundTransparency = trans
end

local function updateButtonSize()
    local s = Config.ToggleBtnSize or 46 OpenCloseBtn.Size = UDim2.new(0, s, 0, s)
end

updateUiOpacity() updateButtonSize()

local menuVisible = true
local function setMenuVisibility(visible)
    menuVisible = visible MainFrame.Visible = visible
    BtnIcon.ImageColor3 = visible and CurrentTheme.ACCENT or CurrentTheme.TEXT_WHITE
end
connect(OpenCloseBtn.MouseButton1Click, function() playUISound() setMenuVisibility(not menuVisible) end)

connect(UserInputService.InputBegan, function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == (Config.ToggleKey or "RightControl") then
        playUISound() setMenuVisibility(not menuVisible)
    end
end)

-- ============================================================================
-- 📦 API CORE INTEGRADA
-- ============================================================================
local Killer = {
    Tabs = {}, Frames = {}, Buttons = {}, Config = Config, Flags = Flags,
    CurrentTab = nil, AllElements = {}, TargetThemeElements = {}, _Trash = {}
}

function Killer:AddTask(obj) table.insert(self._Trash, obj) return obj end

connect(SearchInput:GetPropertyChangedSignal("Text"), function()
    local query = SearchInput.Text:lower()
    for _, element in ipairs(Killer.AllElements) do
        if element.Label and element.Instance then
            if query == "" or element.Label.Text:lower():find(query) then
                element.Instance.Visible = true
            else
                element.Instance.Visible = false
            end
        end
    end
end)

function Killer:ApplyHover(instance, getNormalColor, getHoverColor, property)
    property = property or "BackgroundColor3"
    local cEnter = instance.MouseEnter:Connect(function()
        TweenService:Create(instance, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[property] = getHoverColor()}):Play()
    end)
    local cLeave = instance.MouseLeave:Connect(function()
        TweenService:Create(instance, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[property] = getNormalColor()}):Play()
    end)
    table.insert(Connections, cEnter) table.insert(Connections, cLeave)
end

function Killer:Unload()
    for _, conn in ipairs(Connections) do if conn then pcall(function() conn:Disconnect() end) end end
    for _, item in ipairs(self._Trash) do
        if typeof(item) == "RBXScriptConnection" then pcall(function() item:Disconnect() end)
        elseif typeof(item) == "Instance" then pcall(function() item:Destroy() end) end
    end
    if ScreenGui then ScreenGui:Destroy() end
end

function Killer:SetTheme(themeName)
    if not Themes[themeName] then return end CurrentTheme = Themes[themeName] Config.SelectedTheme = themeName saveConfig()
    MainFrame.BackgroundColor3 = CurrentTheme.BG_MAIN MainStroke.Color = CurrentTheme.BORDER Sidebar.BackgroundColor3 = CurrentTheme.BG_SIDEBAR
    Topbar.BackgroundColor3 = CurrentTheme.BG_MAIN TopbarPatch.BackgroundColor3 = CurrentTheme.BG_MAIN
    Title.TextColor3 = CurrentTheme.ACCENT DecorLine.BackgroundColor3 = CurrentTheme.ACCENT PerformanceLabel.TextColor3 = CurrentTheme.TEXT_MUTED
    SearchBoxContainer.BackgroundColor3 = CurrentTheme.BG_SECONDARY OpenCloseBtn.BackgroundColor3 = CurrentTheme.BG_MAIN FloatingStroke.Color = CurrentTheme.BORDER
    
    BordeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 35, 45)), ColorSequenceKeypoint.new(0.5, CurrentTheme.ACCENT), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 25))
    })
    for _, refreshCallback in ipairs(Killer.TargetThemeElements) do pcall(refreshCallback) end
end

local TabMethods = {} TabMethods.__index = TabMethods

function TabMethods:RegisterElement(inst, textLabel, tabName)
    table.insert(Killer.AllElements, {Instance = inst, Label = textLabel, Tab = tabName})
end

function TabMethods:CreateSection(text)
    local Container = create("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1}, self.Frame)
    local Label = create("TextLabel", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = text:upper(), TextColor3 = CurrentTheme.ACCENT, Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left}, Container)
    
    local Line = create("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 16), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}, Container)
    local Gradient = create("UIGradient", {
        Color = ColorSequence.new(CurrentTheme.ACCENT),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.2), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.9, 0.2), NumberSequenceKeypoint.new(1, 1)
        })
    }, Line)

    table.insert(Killer.TargetThemeElements, function() 
        Label.TextColor3 = CurrentTheme.ACCENT 
        Gradient.Color = ColorSequence.new(CurrentTheme.ACCENT)
    end)
    return Container
end

function TabMethods:CreateToggle(flagName, text, callback)
    if Config[flagName] == nil then Config[flagName] = false end Flags[flagName] = { CurrentValue = Config[flagName] }
    
    local ToggleButton = create("TextButton", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = CurrentTheme.BG_SECONDARY, Text = "", AutoButtonColor = false}, self.Frame)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, ToggleButton)
    local Stroke = create("UIStroke", {Thickness = 1, Color = CurrentTheme.BORDER}, ToggleButton)
    
    local ToggleLabel = create("TextLabel", {Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Config[flagName] and CurrentTheme.TEXT_WHITE or CurrentTheme.TEXT_MUTED, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamMedium, TextSize = 12}, ToggleButton)
    local Track = create("Frame", {Size = UDim2.new(0, 34, 0, 18), Position = UDim2.new(1, -46, 0.5, -9), BackgroundColor3 = Config[flagName] and CurrentTheme.ACCENT or Color3.fromRGB(40, 40, 46)}, ToggleButton)
    create("UICorner", {CornerRadius = UDim.new(1, 0)}, Track)
    local Knob = create("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = Config[flagName] and UDim2.new(1, -15, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = CurrentTheme.TEXT_WHITE}, Track)
    create("UICorner", {CornerRadius = UDim.new(1, 0)}, Knob)

    local function stateUpdate()
        local active = Flags[flagName].CurrentValue
        ToggleLabel.TextColor3 = active and CurrentTheme.TEXT_WHITE or CurrentTheme.TEXT_MUTED
        TweenService:Create(Track, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = active and CurrentTheme.ACCENT or Color3.fromRGB(40, 40, 46)}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Position = active and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
    end
    
    connect(ToggleButton.MouseButton1Click, function()
        Flags[flagName].CurrentValue = not Flags[flagName].CurrentValue Config[flagName] = Flags[flagName].CurrentValue saveConfig() playUISound()
        stateUpdate() task.spawn(callback, Flags[flagName].CurrentValue)
    end)
    
    table.insert(Killer.TargetThemeElements, function()
        ToggleButton.BackgroundColor3 = CurrentTheme.BG_SECONDARY Stroke.Color = CurrentTheme.BORDER stateUpdate()
    end)

    Killer:ApplyHover(ToggleButton, function() return CurrentTheme.BG_SECONDARY end, function() return CurrentTheme.BG_MAIN end)
    stateUpdate() task.spawn(callback, Flags[flagName].CurrentValue)
    self:RegisterElement(ToggleButton, ToggleLabel, self.Frame.Name)
    return {Set = function(_, bool) Flags[flagName].CurrentValue = bool Config[flagName] = bool saveConfig() stateUpdate() pcall(callback, bool) end}
end

-- ============================================================================
-- 🛠️ MOTOR SLIDER (PARCHE DE CONTROL DE PASOS DE 1 EN 1 ENTEROS COMPLETOS)
-- ============================================================================
function TabMethods:CreateSlider(flagName, text, min, max, step, callback)
    if type(step) == "function" then
        callback = step
        step = 1
    end
    step = step or 1

    if Config[flagName] == nil then Config[flagName] = min end
    Flags[flagName] = { CurrentValue = Config[flagName] }
    
    local SliderFrame = create("Frame", {Name = flagName, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Active = true}, self.Frame)
    local Label = create("TextLabel", {Size = UDim2.new(1, -60, 0, 18), Position = UDim2.new(0, 2, 0, 2), BackgroundTransparency = 1, Text = text, TextColor3 = CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, SliderFrame)
    local ValueBox = create("TextBox", {Size = UDim2.new(0, 50, 0, 18), Position = UDim2.new(1, -2, 0, 2), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, TextColor3 = CurrentTheme.ACCENT, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, ClearTextOnFocus = false}, SliderFrame)
    local Track = create("Frame", {Size = UDim2.new(1, -4, 0, 6), Position = UDim2.new(0, 2, 0, 26), BackgroundColor3 = Color3.fromRGB(36, 36, 42)}, SliderFrame)
    create("UICorner", {CornerRadius = UDim.new(0, 3)}, Track)
    local Fill = create("Frame", {BackgroundColor3 = CurrentTheme.ACCENT}, Track)
    create("UICorner", {CornerRadius = UDim.new(0, 3)}, Fill)
    local Knob = create("TextButton", {Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = CurrentTheme.TEXT_WHITE, Text = "", AutoButtonColor = false}, Track)
    create("UICorner", {CornerRadius = UDim.new(1, 0)}, Knob)

    local function runSliderValue(v)
        v = math.clamp(v, min, max)
        if step and step > 0 then
            v = math.round(v / step) * step
        end
        v = math.clamp(v, min, max)
        
        Flags[flagName].CurrentValue = v 
        Config[flagName] = v 
        saveConfig()
        
        local pct = (max == min) and 0 or (v - min) / (max - min)
        Fill.Size = UDim2.new(pct, 0, 1, 0) 
        Knob.Position = UDim2.new(pct, -6, 0.5, -6)
        
        if step and step < 1 then
            local decimals = tostring(step):match("%.(%d+)")
            local numDecimals = decimals and #decimals or 2
            ValueBox.Text = string.format("%." .. numDecimals .. "f", v)
        else
            ValueBox.Text = tostring(math.round(v))
        end
        pcall(callback, v)
    end
    
    connect(ValueBox.FocusLost, function()
        local inputNum = tonumber(ValueBox.Text)
        if not inputNum then 
            runSliderValue(Flags[flagName].CurrentValue) 
        else 
            runSliderValue(inputNum) 
        end
    end)
    
    local sliding = false
    local function snap(input)
        local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        runSliderValue(min + (pct * (max - min)))
    end
    
    local dragConn, endConn
    connect(Knob.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true snap(input)
            if dragConn then dragConn:Disconnect() end
            if endConn then endConn:Disconnect() end
            dragConn = UserInputService.InputChanged:Connect(function(changedInput)
                if sliding and (changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch) then snap(changedInput) end
            end)
            endConn = UserInputService.InputEnded:Connect(function(endedInput)
                if endedInput.UserInputType == Enum.UserInputType.MouseButton1 or endedInput.UserInputType == Enum.UserInputType.Touch then
                    sliding = false 
                    if dragConn then dragConn:Disconnect() dragConn = nil end
                    if endConn then endConn:Disconnect() endConn = nil end
                end
            end)
        end
    end)
    
    table.insert(Killer.TargetThemeElements, function()
        Label.TextColor3 = CurrentTheme.TEXT_WHITE ValueBox.TextColor3 = CurrentTheme.ACCENT Fill.BackgroundColor3 = CurrentTheme.ACCENT
        runSliderValue(Flags[flagName].CurrentValue)
    end)

    runSliderValue(Flags[flagName].CurrentValue)
    self:RegisterElement(SliderFrame, Label, self.Frame.Name)
    return {Set = function(_, value) runSliderValue(value) end}
end

function TabMethods:CreateDropdown(flagName, text, options, callback)
    if Config[flagName] == nil then Config[flagName] = options[1] or "" end Flags[flagName] = { CurrentValue = Config[flagName] }
    
    local DDFrame = create("Frame", {Name = flagName, Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = CurrentTheme.BG_SECONDARY, ClipsDescendants = true}, self.Frame)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, DDFrame)
    local Stroke = create("UIStroke", {Thickness = 1, Color = CurrentTheme.BORDER}, DDFrame)
    
    local Trigger = create("TextButton", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = ""}, DDFrame)
    local Label = create("TextLabel", {Size = UDim2.new(0.5, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, Trigger)
    local SelLabel = create("TextLabel", {Size = UDim2.new(0.5, -38, 1, 0), Position = UDim2.new(1, -38, 0, 0), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Text = Flags[flagName].CurrentValue, TextColor3 = CurrentTheme.ACCENT, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right}, Trigger)
    local Arrow = create("TextLabel", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -22, 0.5, -10), BackgroundTransparency = 1, Text = "▼", TextColor3 = CurrentTheme.TEXT_MUTED, Font = Enum.Font.GothamBold, TextSize = 11}, Trigger)
    
    local OptsScroll = create("ScrollingFrame", {Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 8, 0, 38), BackgroundTransparency = 1, ScrollBarThickness = 0}, DDFrame)
    local layout = create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}, OptsScroll)

    local open = false
    local function makeOptions()
        for _, child in ipairs(OptsScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for i, name in ipairs(options) do
            local OptBtn = create("TextButton", {Size = UDim2.new(1, -4, 0, 26), BackgroundColor3 = CurrentTheme.BG_MAIN, Text = name, TextColor3 = (name == Flags[flagName].CurrentValue) and CurrentTheme.ACCENT or CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamMedium, TextSize = 11, LayoutOrder = i}, OptsScroll)
            create("UICorner", {CornerRadius = UDim.new(0, 4)}, OptBtn)
            
            connect(OptBtn.MouseButton1Click, function()
                Flags[flagName].CurrentValue = name Config[flagName] = name saveConfig() SelLabel.Text = name playUISound() open = false
                TweenService:Create(DDFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 38)}):Play()
                TweenService:Create(Arrow, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Rotation = 0}):Play()
                pcall(callback, name) makeOptions()
            end)
            Killer:ApplyHover(OptBtn, function() return CurrentTheme.BG_MAIN end, function() return CurrentTheme.BG_SECONDARY end)
        end
        OptsScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    end

    connect(Trigger.MouseButton1Click, function()
        open = not open playUISound()
        local targetH = open and math.min(layout.AbsoluteContentSize.Y, 120) or 0
        TweenService:Create(DDFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 38 + targetH + (open and 6 or 0))}):Play()
        TweenService:Create(OptsScroll, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.new(1, -16, 0, targetH)}):Play()
        TweenService:Create(Arrow, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Rotation = open and 180 or 0}):Play()
    end)

    table.insert(Killer.TargetThemeElements, function()
        DDFrame.BackgroundColor3 = CurrentTheme.BG_SECONDARY Stroke.Color = CurrentTheme.BORDER Label.TextColor3 = CurrentTheme.TEXT_WHITE SelLabel.TextColor3 = CurrentTheme.ACCENT Arrow.TextColor3 = CurrentTheme.TEXT_MUTED
        makeOptions()
    end)

    Killer:ApplyHover(DDFrame, function() return CurrentTheme.BG_SECONDARY end, function() return CurrentTheme.BG_MAIN end)
    makeOptions() task.spawn(callback, Flags[flagName].CurrentValue)
    self:RegisterElement(DDFrame, Label, self.Frame.Name)
    return {Refresh = function(_, newOptions) options = newOptions makeOptions() end}
end

function TabMethods:CreateMultiDropdown(flagName, text, options, callback)
    if Config[flagName] == nil or type(Config[flagName]) ~= "table" then Config[flagName] = {} end
    Flags[flagName] = { CurrentValue = Config[flagName] }
    
    local DDFrame = create("Frame", {Name = flagName, Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = CurrentTheme.BG_SECONDARY, ClipsDescendants = true}, self.Frame)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, DDFrame)
    local Stroke = create("UIStroke", {Thickness = 1, Color = CurrentTheme.BORDER}, DDFrame)
    
    local Trigger = create("TextButton", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = ""}, DDFrame)
    local Label = create("TextLabel", {Size = UDim2.new(0.5, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, Trigger)
    local SelLabel = create("TextLabel", {Size = UDim2.new(0.5, -38, 1, 0), Position = UDim2.new(1, -38, 0, 0), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Text = "...", TextColor3 = CurrentTheme.ACCENT, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right}, Trigger)
    local Arrow = create("TextLabel", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -22, 0.5, -10), BackgroundTransparency = 1, Text = "▼", TextColor3 = CurrentTheme.TEXT_MUTED, Font = Enum.Font.GothamBold, TextSize = 11}, Trigger)
    
    local OptsScroll = create("ScrollingFrame", {Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 8, 0, 38), BackgroundTransparency = 1, ScrollBarThickness = 0}, DDFrame)
    local layout = create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}, OptsScroll)

    local open = false
    
    local function updateSelLabel()
        local selected = {}
        for _, name in ipairs(options) do if Config[flagName][name] then table.insert(selected, name) end end
        if #selected == 0 then SelLabel.Text = "Ninguno"
        elseif #selected > 2 then SelLabel.Text = tostring(#selected) .. " Selecc."
        else SelLabel.Text = table.concat(selected, ", ") end
    end

    local function makeOptions()
        for _, child in ipairs(OptsScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for i, name in ipairs(options) do
            if Config[flagName][name] == nil then Config[flagName][name] = false end
            local active = Config[flagName][name]
            
            local OptBtn = create("TextButton", {Size = UDim2.new(1, -4, 0, 26), BackgroundColor3 = CurrentTheme.BG_MAIN, Text = name, TextColor3 = active and CurrentTheme.ACCENT or CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamMedium, TextSize = 11, LayoutOrder = i}, OptsScroll)
            create("UICorner", {CornerRadius = UDim.new(0, 4)}, OptBtn)
            
            connect(OptBtn.MouseButton1Click, function()
                Config[flagName][name] = not Config[flagName][name]
                Flags[flagName].CurrentValue = Config[flagName]
                saveConfig() playUISound()
                OptBtn.TextColor3 = Config[flagName][name] and CurrentTheme.ACCENT or CurrentTheme.TEXT_WHITE
                updateSelLabel() pcall(callback, Config[flagName])
            end)
            Killer:ApplyHover(OptBtn, function() return CurrentTheme.BG_MAIN end, function() return CurrentTheme.BG_SECONDARY end)
        end
        OptsScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
        updateSelLabel()
    end

    connect(Trigger.MouseButton1Click, function()
        open = not open playUISound()
        local targetH = open and math.min(layout.AbsoluteContentSize.Y, 120) or 0
        TweenService:Create(DDFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 38 + targetH + (open and 6 or 0))}):Play()
        TweenService:Create(OptsScroll, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.new(1, -16, 0, targetH)}):Play()
        TweenService:Create(Arrow, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Rotation = open and 180 or 0}):Play()
    end)

    table.insert(Killer.TargetThemeElements, function()
        DDFrame.BackgroundColor3 = CurrentTheme.BG_SECONDARY Stroke.Color = CurrentTheme.BORDER Label.TextColor3 = CurrentTheme.TEXT_WHITE SelLabel.TextColor3 = CurrentTheme.ACCENT Arrow.TextColor3 = CurrentTheme.TEXT_MUTED
        makeOptions()
    end)

    Killer:ApplyHover(DDFrame, function() return CurrentTheme.BG_SECONDARY end, function() return CurrentTheme.BG_MAIN end)
    makeOptions() task.spawn(callback, Flags[flagName].CurrentValue)
    self:RegisterElement(DDFrame, Label, self.Frame.Name)
    return {Refresh = function(_, newOptions) options = newOptions makeOptions() end}
end

-- ============================================================================
-- 📝 COMPONENTE INPUT PARCHADO (CON ANCHORPOINT ABSOLUTO Y RELLENO INTERNO)
-- ============================================================================
function TabMethods:CreateInput(flagName, text, placeholder, callback)
    if Config[flagName] == nil then Config[flagName] = "" end 
    
    local InpFrame = create("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = CurrentTheme.BG_SECONDARY}, self.Frame)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, InpFrame) 
    local Stroke = create("UIStroke", {Thickness = 1, Color = CurrentTheme.BORDER}, InpFrame)
    
    local Label = create("TextLabel", {Size = UDim2.new(1, -170, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, InpFrame)
    
    local Box = create("TextBox", {
        Size = UDim2.new(0, 140, 0, 26), 
        Position = UDim2.new(1, -12, 0.5, 0), 
        AnchorPoint = Vector2.new(1, 0.5), -- FIX: Centrado perimetral exacto dentro de la UI
        BackgroundColor3 = CurrentTheme.BG_MAIN, 
        Text = Config[flagName], 
        PlaceholderText = placeholder, 
        PlaceholderColor3 = CurrentTheme.TEXT_MUTED, 
        TextColor3 = CurrentTheme.TEXT_WHITE, 
        Font = Enum.Font.GothamMedium, 
        TextSize = 11, 
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left
    }, InpFrame)
    create("UICorner", {CornerRadius = UDim.new(0, 4)}, Box)
    create("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, Box) -- Margen interno elegante
    
    connect(Box.FocusLost, function() Config[flagName] = Box.Text saveConfig() pcall(callback, Box.Text) end)
    
    table.insert(Killer.TargetThemeElements, function()
        InpFrame.BackgroundColor3 = CurrentTheme.BG_SECONDARY Stroke.Color = CurrentTheme.BORDER Label.TextColor3 = CurrentTheme.TEXT_WHITE Box.BackgroundColor3 = CurrentTheme.BG_MAIN Box.TextColor3 = CurrentTheme.TEXT_WHITE
    end)
    
    CleanHover = Killer:ApplyHover(InpFrame, function() return CurrentTheme.BG_SECONDARY end, function() return CurrentTheme.BG_MAIN end)
    self:RegisterElement(InpFrame, Label, self.Frame.Name)
end

function TabMethods:CreateKeybind(flagName, text, defaultKey, callback)
    if Config[flagName] == nil then Config[flagName] = defaultKey.Name end 
    
    local KFrame = create("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = CurrentTheme.BG_SECONDARY}, self.Frame)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, KFrame) 
    local Stroke = create("UIStroke", {Thickness = 1, Color = CurrentTheme.BORDER}, KFrame)
    
    local Lbl = create("TextLabel", {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, KFrame)
    local BBtn = create("TextButton", {Size = UDim2.new(0, 85, 0, 26), Position = UDim2.new(1, -12, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = CurrentTheme.BG_MAIN, Text = Config[flagName], TextColor3 = CurrentTheme.ACCENT, Font = Enum.Font.GothamBold, TextSize = 11}, KFrame)
    create("UICorner", {CornerRadius = UDim.new(0, 4)}, BBtn)
    
    local listening = false 
    connect(BBtn.MouseButton1Click, function() listening = true BBtn.Text = "..." playUISound() end)
    connect(UserInputService.InputBegan, function(input, gp) 
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then 
            listening = false Config[flagName] = input.KeyCode.Name saveConfig() BBtn.Text = input.KeyCode.Name pcall(callback, input.KeyCode) 
        end 
    end)
    
    table.insert(Killer.TargetThemeElements, function()
        KFrame.BackgroundColor3 = CurrentTheme.BG_SECONDARY Stroke.Color = CurrentTheme.BORDER Lbl.TextColor3 = CurrentTheme.TEXT_WHITE BBtn.BackgroundColor3 = CurrentTheme.BG_MAIN BBtn.TextColor3 = CurrentTheme.ACCENT
    end)
    
    Killer:ApplyHover(KFrame, function() return CurrentTheme.BG_SECONDARY end, function() return CurrentTheme.BG_MAIN end)
    self:RegisterElement(KFrame, Lbl, self.Frame.Name)
end

function TabMethods:CreateButton(text, callback)
    local Button = create("TextButton", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = CurrentTheme.BG_SECONDARY, Text = text, TextColor3 = CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamBold, TextSize = 12}, self.Frame)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, Button)
    local Stroke = create("UIStroke", {Thickness = 1, Color = CurrentTheme.BORDER}, Button)
    
    connect(Button.MouseButton1Click, function() playUISound() pcall(callback) end)
    table.insert(Killer.TargetThemeElements, function()
        Button.BackgroundColor3 = CurrentTheme.BG_SECONDARY Stroke.Color = CurrentTheme.BORDER Button.TextColor3 = CurrentTheme.TEXT_WHITE
    end)
    Killer:ApplyHover(Button, function() return CurrentTheme.BG_SECONDARY end, function() return CurrentTheme.BG_MAIN end)
    self:RegisterElement(Button, Button, self.Frame.Name)
end

function TabMethods:CreateParagraph(title, text)
    local Frame = create("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = CurrentTheme.BG_SECONDARY}, self.Frame)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, Frame)
    local Stroke = create("UIStroke", {Thickness = 1, Color = CurrentTheme.BORDER}, Frame)
    
    local Tl = create("TextLabel", {Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 12, 0, 5), BackgroundTransparency = 1, Text = title, TextColor3 = CurrentTheme.ACCENT, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, Frame)
    local Tx = create("TextLabel", {Size = UDim2.new(1, -24, 0, 26), Position = UDim2.new(0, 12, 0, 21), BackgroundTransparency = 1, Text = text, TextColor3 = CurrentTheme.TEXT_MUTED, Font = Enum.Font.GothamMedium, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, Frame)
    
    table.insert(Killer.TargetThemeElements, function()
        Frame.BackgroundColor3 = CurrentTheme.BG_SECONDARY Stroke.Color = CurrentTheme.BORDER Tl.TextColor3 = CurrentTheme.ACCENT Tx.TextColor3 = CurrentTheme.TEXT_MUTED
    end)
end

-- ============================================================================
-- 🔓 INYECTOR DE CONTENEDORES ASÍNCRONOS
-- ============================================================================
function Killer:CreateTab(name, iconId)
    local isSettings = (name == "Settings")
    local frame = create("ScrollingFrame", {
        Name = name .. "Frame", Size = UDim2.new(1, -24, 1, -24), Position = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = CurrentTheme.BG_SECONDARY, Visible = false, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0
    }, ContentContainer)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
    local stroke = create("UIStroke", {Thickness = 1, Color = CurrentTheme.BORDER}, frame)
    
    local layout = create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}, frame)
    create("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, frame)
    
    connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function() 
        frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15) 
    end)

    local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = ""}, (isSettings and SettingsContainer or SidebarTabsContainer))
    local btnLabel = create("TextLabel", {Size = UDim2.new(1, iconId and -24 or 0, 1, 0), Position = UDim2.new(0, iconId and 24 or 0, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = CurrentTheme.TEXT_MUTED, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, btn)

    local iconImg
    if iconId then iconImg = create("ImageLabel", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 4, 0.5, -7), BackgroundTransparency = 1, Image = iconId, ImageColor3 = CurrentTheme.TEXT_MUTED}, btn) end
    local line = create("Frame", {Name = "IndicatorLine", Size = UDim2.new(0, 2, 0, 14), Position = UDim2.new(0, -4, 0.5, -7), BackgroundColor3 = CurrentTheme.ACCENT, BackgroundTransparency = 1}, btn)

    Killer.Frames[name] = frame Killer.Buttons[name] = btn
    
    local function selectTab()
        for tName, tFrame in pairs(Killer.Frames) do
            local tBtn = Killer.Buttons[tName] local tLine = tBtn:FindFirstChild("IndicatorLine") local tLabel = tBtn:FindFirstChildWhichIsA("TextLabel") local tIcon = tBtn:FindFirstChildWhichIsA("ImageLabel")
            if tName == name then 
                tFrame.Visible = true if tLabel then tLabel.TextColor3 = CurrentTheme.TEXT_WHITE end if tLine then tLine.BackgroundTransparency = 0 end if tIcon then tIcon.ImageColor3 = CurrentTheme.TEXT_WHITE end
            else 
                tFrame.Visible = false if tLabel then tLabel.TextColor3 = CurrentTheme.TEXT_MUTED end if tLine then tLine.BackgroundTransparency = 1 end if tIcon then tIcon.ImageColor3 = CurrentTheme.TEXT_MUTED end
            end
        end
        Killer.CurrentTab = name
    end
    
    connect(btn.MouseButton1Click, function() if Killer.CurrentTab ~= name then selectTab() playUISound() end end)
    
    table.insert(Killer.TargetThemeElements, function()
        frame.BackgroundColor3 = CurrentTheme.BG_SECONDARY stroke.Color = CurrentTheme.BORDER line.BackgroundColor3 = CurrentTheme.ACCENT
        if Killer.CurrentTab == name then
            btnLabel.TextColor3 = CurrentTheme.TEXT_WHITE if iconImg then iconImg.ImageColor3 = CurrentTheme.TEXT_WHITE end
        else
            btnLabel.TextColor3 = CurrentTheme.TEXT_MUTED if iconImg then iconImg.ImageColor3 = CurrentTheme.TEXT_MUTED end
        end
    end)

    local tabObj = setmetatable({ Frame = frame }, TabMethods)
    Killer.Tabs[name] = tabObj return tabObj
end

-- ============================================================================
-- 🏠 PESTAÑA PRINCIPAL (DASHBOARD HOME)
-- ============================================================================
local HomeTab = Killer:CreateTab("Home", "rbxassetid://10747383845")
HomeTab:CreateSection("Panel De Control Principal")

local WelcomeCard = create("Frame", {Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = CurrentTheme.BG_MAIN}, HomeTab.Frame)
create("UICorner", {CornerRadius = UDim.new(0, 8)}, WelcomeCard)
create("UIStroke", {Thickness = 1, Color = CurrentTheme.BORDER}, WelcomeCard)

local AvatarImage = create("ImageLabel", {Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 10, 0.5, -25), BackgroundColor3 = CurrentTheme.BG_SECONDARY, Image = "rbxassetid://0"}, WelcomeCard)
create("UICorner", {CornerRadius = UDim.new(1, 0)}, AvatarImage)

task.spawn(function()
    pcall(function()
        local content, ready = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        if ready then AvatarImage.Image = content end
    end)
end)

local UserWelcomeLabel = create("TextLabel", {Size = UDim2.new(1, -80, 0, 20), Position = UDim2.new(0, 70, 0, 15), BackgroundTransparency = 1, Text = "Hola, " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")", TextColor3 = CurrentTheme.TEXT_WHITE, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, WelcomeCard)
local StatusLabel = create("TextLabel", {Size = UDim2.new(1, -80, 0, 16), Position = UDim2.new(0, 70, 0, 33), BackgroundTransparency = 1, Text = "Estatus: Premium Activo 💎", TextColor3 = Color3.fromRGB(0, 230, 115), Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, WelcomeCard)

local ExecName = (identifyexecutor and identifyexecutor()) or "Mobile/PC Executor"
HomeTab:CreateSection("Información De Execution")
HomeTab:CreateParagraph("Software Detectado:", "Estás ejecutando Killer Hub mediante: " .. tostring(ExecName))
HomeTab:CreateParagraph("Soporte Técnico Universal:", "Librería gráfica optimizada al 100% con protector perimetral contra pérdida de UI.")

table.insert(Killer.TargetThemeElements, function()
    WelcomeCard.BackgroundColor3 = CurrentTheme.BG_MAIN WelcomeCard.UIStroke.Color = CurrentTheme.BORDER
    UserWelcomeLabel.TextColor3 = CurrentTheme.TEXT_WHITE
end)

-- ============================================================================
-- ⚙️ PESTAÑA DE AJUSTES GLOBALES (ESCALAS ESTRICTAS DE 1 EN 1)
-- ============================================================================
local SettingsTab = Killer:CreateTab("Settings", "rbxassetid://10747372517")
SettingsTab:CreateSection("Personalización")
SettingsTab:CreateDropdown("SelectedTheme", "Tema Visual:", {"Void Premium", "Crimson Dark", "Blood", "Classic Dark"}, function(selected) Killer:SetTheme(selected) end)
SettingsTab:CreateSlider("UiOpacity", "Opacidad de la Interfaz (%)", 10, 100, 1, function(v) updateUiOpacity() end)

SettingsTab:CreateSection("Controles del Menú")
SettingsTab:CreateKeybind("ToggleKey", "Cerrar / Abrir Menu (PC)", Enum.KeyCode.RightControl)
SettingsTab:CreateSlider("ToggleBtnSize", "Tamaño de Botón Flotante", 30, 80, 1, function(v) updateButtonSize() end)
SettingsTab:CreateSlider("Volume", "Volumen Interfaz (%)", 0, 100, 1, function(v) Config.Volume = v end)
SettingsTab:CreateSlider("GuiWidth", "Ajustar Ancho Ventana", 0, 100, 1, function(v) updateGuiSize() end)
SettingsTab:CreateSlider("GuiHeight", "Ajustar Alto Ventana", 0, 100, 1, function(v) updateGuiSize() end)

SettingsTab:CreateSection("Seguridad y Limpieza")
SettingsTab:CreateButton("Apagar Script por Completo (Unload)", function() Killer:Unload() end)

task.defer(function()
    if Killer.Buttons["Home"] then 
        for tName, tFrame in pairs(Killer.Frames) do
            tFrame.Visible = (tName == "Home")
            local tBtn = Killer.Buttons[tName]
            if tBtn then
                local lbl = tBtn:FindFirstChildWhichIsA("TextLabel")
                if lbl then lbl.TextColor3 = (tName == "Home") and CurrentTheme.TEXT_WHITE or CurrentTheme.TEXT_MUTED end
                local ind = tBtn:FindFirstChild("IndicatorLine")
                if ind then ind.BackgroundTransparency = (tName == "Home") and 0 or 1 end
            end
        end
        Killer.CurrentTab = "Home"
    end
end)

getgenv().Killer = Killer
return Killer
