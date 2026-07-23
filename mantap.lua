--[[
    ██╗   ██╗██╗   ██╗██████╗ ███████╗██████╗     ██╗   ██╗██╗    ██╗   ██╗██╗  ██╗
    ██║   ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗    ██║   ██║██║    ██║   ██║██║  ██║
    ██║   ██║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝    ██║   ██║██║    ██║   ██║███████║
    ╚██╗ ██╔╝  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗    ██║   ██║██║    ╚██╗ ██╔╝╚════██║
     ╚████╔╝    ██║   ██║     ███████╗██║  ██║    ╚██████╔╝██║     ╚████╔╝      ██║
      ╚═══╝     ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝     ╚═════╝ ╚═╝      ╚═══╝       ╚═╝
    
    VyperUI V4.0 FINAL - Delta Executor Edition
    Ultra-Modern Responsive UI Library
    
    Author: yeremiaginting059
    Version: 4.0.0 - FINAL RELEASE
    
    ✨ NEW FEATURES V4.0:
    ✓ 100% Responsive UI - Auto-scaling untuk semua device
    ✓ Modern Topbar - Glassmorphic design dengan gradient neon
    ✓ Hide/Show Toggle - Button di tengah topbar dengan smooth animation
    ✓ Collapsible Sidebar - Slide untuk minimize/maximize
    ✓ Minimize to Logo - Window minimize jadi draggable logo di kiri bawah
    ✓ Logo Integration - Logo VyperUI dari GitLab
    ✓ Smooth Animations - Spring, fade, bounce effects untuk semua interaksi
    ✓ Delta Executor Compatible - Tested untuk drag, resize, slider, touch
    ✓ Mobile Optimized - Full touch support untuk mobile devices
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- ========================================
-- RESPONSIVE SCREEN DETECTION (ROBUST INITIALIZATION)
-- ========================================

local Camera = workspace.CurrentCamera
local ScreenSize = Vector2.new(1920, 1080)
local IsMobile = false
local IsTablet = false
local IsDesktop = true

local function initializeCamera()
    local attempts = 0
    local maxAttempts = 100
    
    while not Camera and attempts < maxAttempts do
        Camera = workspace.CurrentCamera
        if not Camera then
            local success = pcall(function()
                task.wait(0.05)
            end)
            if not success then
                wait(0.05)
            end
        end
        attempts = attempts + 1
    end
    
    if Camera then
        ScreenSize = Camera.ViewportSize or Vector2.new(1920, 1080)
        IsMobile = ScreenSize.X < 800
        IsTablet = ScreenSize.X >= 800 and ScreenSize.X < 1200
        IsDesktop = ScreenSize.X >= 1200
    end
end

initializeCamera()

local function updateResponsiveMetrics()
    if Camera and Camera.Parent then
        pcall(function()
            ScreenSize = Camera.ViewportSize or ScreenSize
            IsMobile = ScreenSize.X < 800
            IsTablet = ScreenSize.X >= 800 and ScreenSize.X < 1200
            IsDesktop = ScreenSize.X >= 1200
        end)
    end
end

pcall(function()
    if Camera then
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveMetrics)
    end
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
    if Camera then
        updateResponsiveMetrics()
        pcall(function()
            Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveMetrics)
        end)
    end
end)


-- ========================================
-- PERSISTENCE HELPER (Fix for Executor Isolation)
-- ========================================
local function SaveGlobal(key, value)
    if getgenv then
        getgenv()[key] = value
    else
        _G[key] = value
    end
end

local function LoadGlobal(key)
    if getgenv then
        return getgenv()[key]
    else
        return _G[key]
    end
end

-- ========================================
-- CONFIGURATION SYSTEM (AUTO-SAVE & NAMED CONFIGS)
-- ========================================

local ElementRegistry = {} -- Stores update functions for UI elements

local ConfigSystem = {}
ConfigSystem.Data = {}
ConfigSystem.GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name:gsub("[^%w_ ]", ""):gsub("%s+", "_")
ConfigSystem.Folder = "VyperUI"
ConfigSystem.SubFolder = "VyperUI/Config"
ConfigSystem.Path = ConfigSystem.SubFolder .. "/" .. ConfigSystem.GameName .. ".json"

function ConfigSystem:Init()
    if not isfolder(self.Folder) then makefolder(self.Folder) end
    if not isfolder(self.SubFolder) then makefolder(self.SubFolder) end
    -- self:Load() -- Disabled auto-load as per user request
end

function ConfigSystem:Save()
    if writefile then
        local success, err = pcall(function()
            writefile(self.Path, HttpService:JSONEncode(self.Data))
        end)
        if not success then
            warn("VyperUI: Failed to save config - " .. tostring(err)) 
        end
    end
end

function ConfigSystem:Load()
    if isfile and isfile(self.Path) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(self.Path))
        end)
        if success and type(result) == "table" then
            self.Data = result
        end
    end
end

-- [NEW] Save with custom name
function ConfigSystem:SaveNamed(name)
    if not name or name == "" then return end
    local filePath = self.SubFolder .. "/" .. name .. ".json"
    if writefile then
        local success, err = pcall(function()
            writefile(filePath, HttpService:JSONEncode(self.Data))
            print("💾 [VyperUI] Saved Config:", name)
        end)
        if not success then
             warn("VyperUI: Failed to save named config - " .. tostring(err))
        end
    end
end

-- [NEW] Load with custom name and APPLY settings
function ConfigSystem:LoadNamed(name)
    if not name or name == "" then return end
    local filePath = self.SubFolder .. "/" .. name .. ".json"
    
    if isfile and isfile(filePath) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(filePath))
        end)
        
        if success and type(result) == "table" then
            print("📂 [VyperUI] Loaded Config:", name)
            self:ApplyConfig(result)
        else
            warn("VyperUI: Failed to load config or invalid JSON")
        end
    else
        warn("VyperUI: Config file not found:", name)
    end
end

-- [NEW] Apply configuration data to all registered elements
function ConfigSystem:ApplyConfig(newData)
    self.Data = newData -- Update internal data
    
    for key, value in pairs(newData) do
        -- Find registered element
        local element = ElementRegistry[key]
        if element and element.Update then
            pcall(function()
                element.Update(value)
            end)
        end
    end
    
    -- Save as current state (optional, but good for consistency)
    self:Save()
end

-- [NEW] Delete named config
function ConfigSystem:Delete(name)
    if not name or name == "" then return end
    local filePath = self.SubFolder .. "/" .. name .. ".json"
    
    if isfile and isfile(filePath) then
        pcall(function()
            delfile(filePath)
            print("🗑️ [VyperUI] Deleted Config:", name)
        end)
    else
        warn("VyperUI: Config file not found:", name)
    end
end

-- [NEW] Reset all registered elements to their DEFAULT values
function ConfigSystem:Reset()
    self.Data = {} -- Clear internal data
    
    for key, element in pairs(ElementRegistry) do
        if element.Update and element.Default ~= nil then
            pcall(function()
                element.Update(element.Default)
            end)
        end
    end
    
    print("🔄 [VyperUI] Config Reset to Defaults")
end

-- Initialize Config
ConfigSystem:Init()

-- ========================================
-- MODERN GLASSMORPHIC THEME V4.0
-- ========================================

local Theme = {
    Colors = {
        -- Purple & Silver Theme
        AccentPrimary = Color3.fromRGB(170, 0, 255),    -- Neon Purple
        AccentSecondary = Color3.fromRGB(192, 192, 192),-- Silver
        AccentTertiary = Color3.fromRGB(147, 112, 219), -- Medium Purple

        GlassLight = Color3.fromRGB(220, 220, 220),     -- Light Silver reflection
        GlassDark = Color3.fromRGB(20, 10, 30),         -- Dark Purple tint
        GlassMid = Color3.fromRGB(30, 20, 40),          -- Mid Purple tint
        
        Background = Color3.fromRGB(0, 0, 0),           -- Pure Black
        BackgroundSecondary = Color3.fromRGB(25, 20, 35),
        Surface = Color3.fromRGB(35, 25, 45),
        SurfaceLight = Color3.fromRGB(50, 40, 60),
        
        TextPrimary = Color3.fromRGB(240, 240, 250),    -- Silver/White
        TextSecondary = Color3.fromRGB(180, 180, 190),  -- Dim Silver
        TextTertiary = Color3.fromRGB(140, 140, 150),
        TextDisabled = Color3.fromRGB(80, 80, 90),
        
        Success = Color3.fromRGB(52, 199, 89),
        Warning = Color3.fromRGB(255, 204, 0),
        Error = Color3.fromRGB(255, 59, 48),
        Info = Color3.fromRGB(170, 0, 255),
        
        Border = Color3.fromRGB(70, 60, 90),            -- Purple tinted border
        BorderLight = Color3.fromRGB(90, 80, 110),
        Shadow = Color3.fromRGB(10, 5, 15),

        -- Legacy mappings for compatibility (mapped to new palette)
        NeonPurple = Color3.fromRGB(88, 86, 214), 
        NeonCyan = Color3.fromRGB(0, 122, 255),
        NeonPink = Color3.fromRGB(255, 45, 85),
        NeonBlue = Color3.fromRGB(0, 122, 255),
        NeonGreen = Color3.fromRGB(52, 199, 89),
    },
    
    Transparency = {
        Glass = 0.3,
        GlassHover = 0.2,
        GlassActive = 0.15,
        Overlay = 0.5,
        Shadow = 0.7,
        Disabled = 0.6,
    },
    
    Logo = {
        URL = "rbxassetid://107726435417936",
        DecalID = "rbxassetid://107726435417936",
    },
    
    GetResponsiveSize = function(mobile, tablet, desktop)
        if IsMobile then
            -- Micro-screen adjustment: Scale down further if screen < 380px
            local scale = 1
            if ScreenSize.X < 380 then
                scale = ScreenSize.X / 380
            end
            return math.floor(mobile * scale)
        end
        if IsTablet then return tablet or desktop end
        return desktop
    end,
}

Theme.Sizes = {
    TopbarHeight = Theme.GetResponsiveSize(32, 36, 40),
    SidebarWidth = Theme.GetResponsiveSize(140, 160, 170), -- Compact sidebar
    SidebarMinimized = Theme.GetResponsiveSize(40, 45, 45),
    CornerRadius = Theme.GetResponsiveSize(6, 6, 6), -- Sharper, cleaner look
    CornerRadiusSmall = Theme.GetResponsiveSize(4, 4, 4),
    IconSize = Theme.GetResponsiveSize(14, 16, 16),
    AvatarSize = Theme.GetResponsiveSize(24, 28, 30),
    Padding = Theme.GetResponsiveSize(8, 10, 10),
    PaddingSmall = Theme.GetResponsiveSize(4, 5, 5),
    PaddingLarge = Theme.GetResponsiveSize(12, 14, 16),
    Spacing = Theme.GetResponsiveSize(6, 8, 8),
    ButtonHeight = Theme.GetResponsiveSize(28, 30, 32), -- Standard compact button height
    MinimizedLogoSize = Theme.GetResponsiveSize(50, 60, 60),
}

Theme.Fonts = {
    Primary = Enum.Font.GothamBold,
    Secondary = Enum.Font.Gotham,
    Mono = Enum.Font.RobotoMono,
}

Theme.Animations = {
    Fast = 0.15,
    Normal = 0.25,
    Slow = 0.4,
    VerySlow = 0.6,
}

-- ========================================
-- ADVANCED ANIMATION SYSTEM V4.0
-- ========================================

local Animator = {}
Animator.ActiveTweens = {}

function Animator:Tween(instance, props, duration, style, direction, callback)
    if not instance or not instance.Parent then return end

    duration = duration or Theme.Animations.Normal
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out

    -- cancel previous tween for this instance if present
    if self.ActiveTweens[instance] then
        pcall(function() self.ActiveTweens[instance]:Cancel() end)
        self.ActiveTweens[instance] = nil
    end

    local tweenInfo = TweenInfo.new(duration, style, direction)
    local stroke = instance:FindFirstChildOfClass("UIStroke")

    -- mapping keys that start with "Stroke" -> actual UIStroke property names
    local strokeMap = {
        StrokeColor = "Color",
        StrokeTransparency = "Transparency",
        StrokeThickness = "Thickness"
    }

    -- we'll collect separate tween targets: one for instance, one for stroke
    local instanceTargets = {}
    local strokeTargets = {}

    for key, value in pairs(props or {}) do
        if key:match("^Stroke") then
            -- map to real stroke property name, if stroke exists
            if stroke then
                local realKey = strokeMap[key] or key:gsub("^Stroke", "")
                -- ensure the stroke actually has that property (best-effort, pcall)
                local ok = pcall(function() return stroke[realKey] end)
                if ok then
                    strokeTargets[realKey] = value
                end
            end
        else
            -- normal property: ensure instance supports it before tween
            local ok = pcall(function() return instance[key] end)
            if ok then
                instanceTargets[key] = value
            end
        end
    end

    -- create tweens for instance and stroke separately
    if next(instanceTargets) then
        local t = TweenService:Create(instance, tweenInfo, instanceTargets)
        self.ActiveTweens[instance] = t
        t:Play()
        if callback then
            t.Completed:Connect(function()
                pcall(callback)
                self.ActiveTweens[instance] = nil
            end)
        end
    end

    if stroke and next(strokeTargets) then
        -- cancel previous stroke tween if any
        if self.ActiveTweens[stroke] then
            pcall(function() self.ActiveTweens[stroke]:Cancel() end)
            self.ActiveTweens[stroke] = nil
        end

        local ts = TweenService:Create(stroke, tweenInfo, strokeTargets)
        self.ActiveTweens[stroke] = ts
        ts:Play()
        -- don't duplicate callback here (already attached to instance tween if present).
        if not next(instanceTargets) and callback then
            ts.Completed:Connect(function()
                pcall(callback)
                self.ActiveTweens[stroke] = nil
            end)
        end
    end

    -- if nothing was tweened but callback exists, call it after duration as fallback
    if not next(instanceTargets) and not (stroke and next(strokeTargets)) and callback then
        task.delay(duration, function()
            pcall(callback)
        end)
    end

    return true
end



function Animator:Spring(instance, props, callback)
    return self:Tween(instance, props, Theme.Animations.Normal, Enum.EasingStyle.Back, Enum.EasingDirection.Out, callback)
end

function Animator:Elastic(instance, props, callback)
    return self:Tween(instance, props, Theme.Animations.Slow, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, callback)
end

function Animator:Bounce(instance, scale)
    if not instance or not instance.Parent then return end
    
    scale = scale or 0.95
    local originalSize = instance.Size
    
    self:Tween(instance, {Size = UDim2.new(
        originalSize.X.Scale * scale,
        originalSize.X.Offset * scale,
        originalSize.Y.Scale * scale,
        originalSize.Y.Offset * scale
    )}, Theme.Animations.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
        self:Spring(instance, {Size = originalSize})
    end)
end

function Animator:Ripple(parent, position, color)
    if not parent or not parent.Parent then return end
    
    color = color or Theme.Colors.AccentPrimary
    
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = color
    ripple.BackgroundTransparency = 0.3
    ripple.BorderSizePixel = 0
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0, position.X, 0, position.Y)
    ripple.ZIndex = 10
    ripple.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    
    self:Tween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }, Theme.Animations.Slow, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
        ripple:Destroy()
    end)
end



function Animator:Glow(instance, color, intensity)
    -- Deprecated: Glow effects removed for modern look
    return nil 
end

function Animator:PulseGlow(glow, duration)
    -- Deprecated
    return nil
end

function Animator:FadeIn(instance, duration)
    if not instance then return end
    self:Tween(instance, {BackgroundTransparency = 0}, duration or Theme.Animations.Normal)
end

function Animator:FadeOut(instance, duration, callback)
    if not instance then return end
    self:Tween(instance, {BackgroundTransparency = 1}, duration or Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, callback)
end

function Animator:SlideIn(instance, direction, duration)
    if not instance then return end
    
    direction = direction or "left"
    duration = duration or Theme.Animations.Normal
    
    local viewport = Camera.ViewportSize
    local startPos
    
    if direction == "left" then
        startPos = UDim2.new(0, -instance.AbsoluteSize.X, instance.Position.Y.Scale, instance.Position.Y.Offset)
    elseif direction == "right" then
        startPos = UDim2.new(0, viewport.X, instance.Position.Y.Scale, instance.Position.Y.Offset)
    elseif direction == "top" then
        startPos = UDim2.new(instance.Position.X.Scale, instance.Position.X.Offset, 0, -instance.AbsoluteSize.Y)
    elseif direction == "bottom" then
        startPos = UDim2.new(instance.Position.X.Scale, instance.Position.X.Offset, 0, viewport.Y)
    end
    
    local endPos = instance.Position
    instance.Position = startPos
    
    self:Spring(instance, {Position = endPos})
end

function Animator:SlideOut(instance, direction, duration, callback)
    if not instance then return end
    
    direction = direction or "left"
    duration = duration or Theme.Animations.Normal
    
    local viewport = Camera.ViewportSize
    local endPos
    
    if direction == "left" then
        endPos = UDim2.new(0, -instance.AbsoluteSize.X, instance.Position.Y.Scale, instance.Position.Y.Offset)
    elseif direction == "right" then
        endPos = UDim2.new(0, viewport.X, instance.Position.Y.Scale, instance.Position.Y.Offset)
    elseif direction == "top" then
        endPos = UDim2.new(instance.Position.X.Scale, instance.Position.X.Offset, 0, -instance.AbsoluteSize.Y)
    elseif direction == "bottom" then
        endPos = UDim2.new(instance.Position.X.Scale, instance.Position.X.Offset, 0, viewport.Y)
    end
    
    self:Tween(instance, {Position = endPos}, duration, Enum.EasingStyle.Quint, Enum.EasingDirection.In, callback)
end

-- ========================================
-- UTILITY FUNCTIONS V4.0
-- ========================================

local Utils = {}

function Utils:CreateElement(className, props)
    local element = Instance.new(className)
    
    for prop, value in pairs(props or {}) do
        if prop ~= "Children" then
            pcall(function() element[prop] = value end)
        end
    end
    
    if props and props.Children then
        for _, child in ipairs(props.Children) do
            child.Parent = element
        end
    end
    
    return element
end

function Utils:CreateGlassFrame(parent, props)
    props = props or {}
    
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = props.Color or Theme.Colors.GlassMid
    frame.BackgroundTransparency = props.Transparency or Theme.Transparency.Glass
    frame.BorderSizePixel = 0
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.ZIndex = props.ZIndex or 1
    frame.ClipsDescendants = props.ClipsDescendants or false
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, props.CornerRadius or Theme.Sizes.CornerRadius)
    corner.Parent = frame
    
    if props.Stroke ~= false then
        local stroke = Instance.new("UIStroke")
        stroke.Color = props.StrokeColor or Theme.Colors.Border
        stroke.Thickness = props.StrokeThickness or 1
        stroke.Transparency = props.StrokeTransparency or 0.5
        stroke.Parent = frame
    end
    
    -- Gradient removed for cleaner look
    if props.Gradient then
        -- No-op or simple color fallback if absolutely needed
    end
    
    return frame
end

function Utils:CreateText(parent, text, props)
    props = props or {}
    
    local label = Instance.new("TextLabel")
    label.Text = text or ""
    label.Font = props.Font or Theme.Fonts.Secondary
    label.TextSize = props.TextSize or Theme.GetResponsiveSize(12, 13, 14)
    label.TextColor3 = props.TextColor or Theme.Colors.TextPrimary
    label.TextTransparency = props.TextTransparency or 0
    label.BackgroundTransparency = 1
    label.Size = props.Size or UDim2.new(1, 0, 1, 0)
    label.Position = props.Position or UDim2.new(0, 0, 0, 0)
    label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    label.TextWrapped = props.TextWrapped or false
    label.TextScaled = props.TextScaled or false
    label.RichText = props.RichText or false
    label.ZIndex = props.ZIndex or 2
    label.Parent = parent
    
    return label
end

function Utils:CreateIcon(parent, icon, props)
    props = props or {}
    
    return self:CreateText(parent, icon, {
        Font = Theme.Fonts.Primary,
        TextSize = props.Size or Theme.Sizes.IconSize,
        TextColor = props.Color or Theme.Colors.AccentPrimary,
        Size = props.FrameSize or UDim2.new(0, props.Size or Theme.Sizes.IconSize, 0, props.Size or Theme.Sizes.IconSize),
        Position = props.Position,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = props.ZIndex or 3
    })
end

function Utils:CreatePadding(parent, padding)
    local uiPadding = Instance.new("UIPadding")
    
    if type(padding) == "table" then
        uiPadding.PaddingTop = UDim.new(0, padding.Top or 0)
        uiPadding.PaddingBottom = UDim.new(0, padding.Bottom or 0)
        uiPadding.PaddingLeft = UDim.new(0, padding.Left or 0)
        uiPadding.PaddingRight = UDim.new(0, padding.Right or 0)
    else
        local p = padding or Theme.Sizes.Padding
        uiPadding.PaddingTop = UDim.new(0, p)
        uiPadding.PaddingBottom = UDim.new(0, p)
        uiPadding.PaddingLeft = UDim.new(0, p)
        uiPadding.PaddingRight = UDim.new(0, p)
    end
    
    uiPadding.Parent = parent
    return uiPadding
end

function Utils:CreateListLayout(parent, props)
    props = props or {}
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, props.Padding or Theme.Sizes.Spacing)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = props.FillDirection or Enum.FillDirection.Vertical
    layout.HorizontalAlignment = props.HorizontalAlignment or Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = props.VerticalAlignment or Enum.VerticalAlignment.Top
    layout.Parent = parent
    
    return layout
end

function Utils:GenerateUID()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local uid = ""
    for i = 1, 16 do
        local idx = math.random(1, #chars)
        uid = uid .. chars:sub(idx, idx)
    end
    return uid
end

-- ========================================
-- INPUT HANDLER (DELTA EXECUTOR OPTIMIZED)
-- ========================================

local Input = {}

function Input:MakeDraggable(frame, handle)
    handle = handle or frame
    
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        local viewport = Camera.ViewportSize
        local newX = math.clamp(startPos.X.Offset + delta.X, 0, viewport.X - frame.AbsoluteSize.X)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, viewport.Y - frame.AbsoluteSize.Y)
        frame.Position = UDim2.new(0, newX, 0, newY)
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local Input = {}

-- ========================================
-- MAKE DRAGGABLE (Unchanged)
-- ========================================
function Input:MakeDraggable(frame, handle)
    handle = handle or frame
    
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        local viewport = Camera.ViewportSize
        
        -- PERBAIKAN: Pakai Scale dan Offset dari posisi awal
        local newXOffset = startPos.X.Offset + delta.X
        local newYOffset = startPos.Y.Offset + delta.Y
        
        -- Clamp dengan mempertimbangkan Scale
        local absoluteX = startPos.X.Scale * viewport.X + newXOffset
        local absoluteY = startPos.Y.Scale * viewport.Y + newYOffset
        
        absoluteX = math.clamp(absoluteX, 0, viewport.X - frame.AbsoluteSize.X)
        absoluteY = math.clamp(absoluteY, 0, viewport.Y - frame.AbsoluteSize.Y)
        
        -- Convert balik ke Scale + Offset
        newXOffset = absoluteX - (startPos.X.Scale * viewport.X)
        newYOffset = absoluteY - (startPos.Y.Scale * viewport.Y)
        
        frame.Position = UDim2.new(startPos.X.Scale, newXOffset, startPos.Y.Scale, newYOffset)
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- ========================================
-- MAKE RESIZABLE (WITH AUTO-SAVE CALLBACK)
-- ========================================
function Input:MakeResizable(frame, minSize, maxSize, onResizeEnd)
    minSize = minSize or UDim2.new(0, Theme.GetResponsiveSize(300, 400, 400), 0, Theme.GetResponsiveSize(250, 300, 300))
    maxSize = maxSize or UDim2.new(0, 1400, 0, 900)
    
    local resizing = false
    local resizeInput
    local resizeStart
    local startSize
    
    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Text = "⌟"
    resizeHandle.Font = Theme.Fonts.Primary
    resizeHandle.TextSize = Theme.GetResponsiveSize(14, 16, 18)
    resizeHandle.TextColor3 = Color3.fromRGB(100, 100, 105)
    resizeHandle.BackgroundTransparency = 1
    resizeHandle.Size = UDim2.new(0, Theme.GetResponsiveSize(30, 35, 40), 0, Theme.GetResponsiveSize(30, 35, 40))
    resizeHandle.Position = UDim2.new(1, -Theme.GetResponsiveSize(30, 35, 40), 1, -Theme.GetResponsiveSize(30, 35, 40))
    resizeHandle.ZIndex = 10
    resizeHandle.Parent = frame
    
    local function update(input)
        local delta = input.Position - resizeStart
        local newWidth = math.clamp(startSize.X.Offset + delta.X, minSize.X.Offset, maxSize.X.Offset)
        local newHeight = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y.Offset, maxSize.Y.Offset)
        frame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
    
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = frame.Size
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    
                    -- ✅ AUTO-SAVE CALLBACK (NEW)
                    if onResizeEnd then
                        task.wait(0.05)  -- Small delay untuk pastikan size udah final
                        local finalWidth = frame.AbsoluteSize.X
                        local finalHeight = frame.AbsoluteSize.Y
                        onResizeEnd(finalWidth, finalHeight)
                    end
                end
            end)
        end
    end)
    
    resizeHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            resizeInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == resizeInput and resizing then
            update(input)
        end
    end)
end


function Input:AddRippleEffect(button, callback)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position - button.AbsolutePosition
            Animator:Ripple(button, pos)
            
            if callback then
                callback()
            end
        end
    end)
end

function Input:AddHoverEffect(element, hoverProps, normalProps)
    local stroke = element:FindFirstChildOfClass("UIStroke")

    element.MouseEnter:Connect(function()
        for prop, val in pairs(hoverProps) do
            if prop == "StrokeTransparency" and stroke then
                Animator:Tween(stroke, {Transparency = val}, Theme.Animations.Fast)
            else
                Animator:Tween(element, {[prop] = val}, Theme.Animations.Fast)
            end
        end
    end)
    
    element.MouseLeave:Connect(function()
        for prop, val in pairs(normalProps) do
            if prop == "StrokeTransparency" and stroke then
                Animator:Tween(stroke, {Transparency = val}, Theme.Animations.Fast)
            else
                Animator:Tween(element, {[prop] = val}, Theme.Animations.Fast)
            end
        end
    end)
end


-- ========================================
-- PARTICLE SYSTEM
-- ========================================

local ParticleSystem = {}

function ParticleSystem:CreateAnimatedBackground(parent)
    -- Disabled for cleaner look
    return nil
end

-- ========================================
-- MODERN WINDOW V4.0
-- ========================================
local Window = {}
Window.__index = Window

function Window.new(config)
    local self = setmetatable({}, Window)
    
    self.Config = config or {}
    self.Title = self.Config.Title or "VyperUI V4.0"
    self.Subtitle = self.Config.Subtitle or ""
    
    local defaultWidth = Theme.GetResponsiveSize(math.min(ScreenSize.X - 20, 400), 500, 580) -- Compact start
    local defaultHeight = Theme.GetResponsiveSize(math.min(ScreenSize.Y - 20, 300), 320, 360) -- Compact start
    
    self.Size = self.Config.Size or UDim2.new(0, defaultWidth, 0, defaultHeight)
    self.Tabs = {}
    self.CurrentTab = nil
    self.SidebarCollapsed = false -- Default to OPEN
    self.IsHidden = false
    self.IsMinimized = false
    
    self:Build()
    
    return self
end

function Window:Build()
    self.GUI = Utils:CreateElement("ScreenGui", {
        Name = "VyperUI_" .. Utils:GenerateUID(),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })
    
    pcall(function() self.GUI.Parent = CoreGui end)
    if not self.GUI.Parent then
        self.GUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- ✅ LOAD ukuran tersimpan (Support getgenv for strict persistence)
    local savedSize = LoadGlobal("VyperUI_WindowSize")
    if savedSize then
        self.Size = savedSize
        -- Clamp to screen size
        if self.Size.X.Offset > ScreenSize.X then
            self.Size = UDim2.new(0, ScreenSize.X - 20, 0, self.Size.Y.Offset)
        end
        if self.Size.Y.Offset > ScreenSize.Y then
            self.Size = UDim2.new(0, self.Size.X.Offset, 0, ScreenSize.Y - 20)
        end
    end
    
    -- Main Window Frame (satu container untuk semua)
    self.MainFrame = Utils:CreateGlassFrame(self.GUI, {
        Color = Theme.Colors.Background,
        Transparency = 0.10,
        Size = self.Size,
        Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2),
        CornerRadius = Theme.Sizes.CornerRadius,
        StrokeColor = Theme.Colors.BorderLight,
        StrokeTransparency = 0.3,
        ClipsDescendants = true
    })
    
    -- ✅ LOAD posisi tersimpan
    local savedPos = LoadGlobal("VyperUI_WindowPosition")
    if savedPos then
        self.MainFrame.Position = savedPos
    end
    
    -- Shadow removed (clean look)
    
    -- Background particles removed
    ParticleSystem:CreateAnimatedBackground(self.MainFrame)
    
    self:CreateTopbar()
    self:CreateSidebar()
    self:CreateContentArea()
    self:CreateMinimizedLogo()
    
    Input:MakeDraggable(self.MainFrame, self.Topbar)
    
    -- ✅ SAVE posisi setiap kali window di-drag (Continuous)
    self.MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
        if not self.IsMinimized and self.MainFrame.Visible then
            SaveGlobal("VyperUI_WindowPosition", self.MainFrame.Position)
        end
    end)
    
    -- ✅ SAVE ukuran setiap kali window di-resize (Continuous)
    self.MainFrame:GetPropertyChangedSignal("Size"):Connect(function()
        if not self.IsMinimized and self.MainFrame.Visible and self.MainFrame.AbsoluteSize.X > 50 then
            SaveGlobal("VyperUI_WindowSize", self.MainFrame.Size)
            self.Size = self.MainFrame.Size -- Hitung2 update internal
        end
    end)
    
    -- Make Resizable standard (no callback needed for save anymore)
    Input:MakeResizable(self.MainFrame)
end

function Window:CreateTopbar()
    -- Topbar tanpa glass effect bertumpuk, cuma border bawah
    self.Topbar = Instance.new("Frame")
    self.Topbar.Name = "Topbar"
    self.Topbar.BackgroundTransparency = 1
    self.Topbar.Size = UDim2.new(1, 0, 0, Theme.Sizes.TopbarHeight)
    self.Topbar.Position = UDim2.new(0, 0, 0, 0)
    self.Topbar.BorderSizePixel = 0
    self.Topbar.ZIndex = 5
    self.Topbar.Parent = self.MainFrame
    
    -- Border bawah topbar (garis pemisah subtle)
    local bottomBorder = Instance.new("Frame")
    bottomBorder.Name = "BottomBorder"
    bottomBorder.BackgroundColor3 = Theme.Colors.Border
    bottomBorder.BackgroundTransparency = 0.7
    bottomBorder.BorderSizePixel = 0
    bottomBorder.Size = UDim2.new(1, 0, 0, 1)
    bottomBorder.Position = UDim2.new(0, 0, 1, -1)
    bottomBorder.ZIndex = 5
    bottomBorder.Parent = self.Topbar
    
    -- Center Section: Title & Subtitle (sekarang di kiri)
    local centerSection = Instance.new("Frame")
    centerSection.BackgroundTransparency = 1
    centerSection.Size = UDim2.new(1, -Theme.GetResponsiveSize(120, 140, 160), 1, 0)
    centerSection.Position = UDim2.new(0, 0, 0, 0)
    centerSection.Parent = self.Topbar
    
    local titleLabel = Utils:CreateText(centerSection, self.Title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(15, 17, 19),
        TextColor = Theme.Colors.TextPrimary,
        Size = UDim2.new(1, 0, 0.55, 0),
        Position = UDim2.new(0, Theme.GetResponsiveSize(16, 20, 24), 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom
    })
    
    if not IsMobile then
        Utils:CreateText(centerSection, self.Subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Size = UDim2.new(1, 0, 0.45, 0),
            Position = UDim2.new(0, Theme.GetResponsiveSize(16, 20, 24), 0.55, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
    end
    
    -- Right Section: Window Buttons
    local rightSection = Instance.new("Frame")
    rightSection.BackgroundTransparency = 1
    rightSection.Size = UDim2.new(0, Theme.GetResponsiveSize(120, 140, 160), 1, 0)
    rightSection.Position = UDim2.new(1, -Theme.GetResponsiveSize(120, 140, 160), 0, 0)
    rightSection.Parent = self.Topbar
    
    self:CreateWindowButtons(rightSection)
end

function Window:CreateWindowButtons(parent)
    local buttonSize = Theme.GetResponsiveSize(24, 28, 32)
    local iconSize = Theme.GetResponsiveSize(12, 14, 16)
    local spacing = Theme.GetResponsiveSize(8, 10, 12)
    
    -- 🗕 Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeButton"
    minimizeBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    minimizeBtn.Position = UDim2.new(1, -(buttonSize * 2 + spacing * 2), 0.5, -buttonSize/2)
    minimizeBtn.BackgroundColor3 = Theme.Colors.Surface
    minimizeBtn.BackgroundTransparency = 0.5
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = ""
    minimizeBtn.Parent = parent
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeBtn
    
    local minimizeStroke = Instance.new("UIStroke")
    minimizeStroke.Color = Theme.Colors.Border
    minimizeStroke.Transparency = 0.5
    minimizeStroke.Thickness = 1
    minimizeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    minimizeStroke.Parent = minimizeBtn
    
    local minimizeIcon = Instance.new("ImageLabel")
    minimizeIcon.Name = "MinimizeIcon"
    minimizeIcon.Image = "rbxassetid://86388357896435"
    minimizeIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
    minimizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    minimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    minimizeIcon.BackgroundTransparency = 1
    minimizeIcon.ImageColor3 = Theme.Colors.TextSecondary
    minimizeIcon.ScaleType = Enum.ScaleType.Fit
    minimizeIcon.Parent = minimizeBtn
    
    minimizeBtn.MouseButton1Click:Connect(function()
        if self.ToggleMinimize then
            self:ToggleMinimize()
        end
        Animator:Bounce(minimizeBtn, 0.9)
    end)
    
    -- ✖ Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    closeBtn.Position = UDim2.new(1, -(buttonSize + spacing), 0.5, -buttonSize/2)
    closeBtn.BackgroundColor3 = Theme.Colors.Surface
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = ""
    closeBtn.Parent = parent
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    local closeStroke = Instance.new("UIStroke")
    closeStroke.Color = Theme.Colors.Border
    closeStroke.Transparency = 0.5
    closeStroke.Thickness = 1
    closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    closeStroke.Parent = closeBtn
    
    local closeIcon = Instance.new("ImageLabel")
    closeIcon.Name = "CloseIcon"
    closeIcon.Image = "rbxassetid://100353373935291"
    closeIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.BackgroundTransparency = 1
    closeIcon.ImageColor3 = Theme.Colors.TextSecondary
    closeIcon.ScaleType = Enum.ScaleType.Fit
    closeIcon.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    -- 🎨 Hover effects
    if not IsMobile then
        minimizeBtn.MouseEnter:Connect(function()
            TweenService:Create(minimizeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.AccentPrimary
            }):Play()
            TweenService:Create(minimizeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.2,
                Color = Theme.Colors.AccentPrimary
            }):Play()
        end)
        
        minimizeBtn.MouseLeave:Connect(function()
            TweenService:Create(minimizeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.TextSecondary
            }):Play()
            TweenService:Create(minimizeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.5,
                Color = Theme.Colors.Border
            }):Play()
        end)
        
        closeBtn.MouseEnter:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Color3.fromRGB(255, 80, 80)
            }):Play()
            TweenService:Create(closeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.2,
                Color = Color3.fromRGB(255, 80, 80)
            }):Play()
        end)
        
        closeBtn.MouseLeave:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.TextSecondary
            }):Play()
            TweenService:Create(closeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.5,
                Color = Theme.Colors.Border
            }):Play()
        end)
    end
end

function Window:CreateWindowButtons(parent)
    local buttonSize = Theme.GetResponsiveSize(24, 28, 32)
    local iconSize = Theme.GetResponsiveSize(12, 14, 16)
    local spacing = Theme.GetResponsiveSize(8, 10, 12)
    
    -- 🗕 Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeButton"
    minimizeBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    minimizeBtn.Position = UDim2.new(1, -(buttonSize * 2 + spacing * 2), 0.5, -buttonSize/2)
    minimizeBtn.BackgroundColor3 = Theme.Colors.Surface
    minimizeBtn.BackgroundTransparency = 0.5
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = ""
    minimizeBtn.Parent = parent
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeBtn
    
    local minimizeStroke = Instance.new("UIStroke")
    minimizeStroke.Color = Theme.Colors.Border
    minimizeStroke.Transparency = 0.7
    minimizeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    minimizeStroke.Parent = minimizeBtn
    
    local minimizeIcon = Instance.new("ImageLabel")
    minimizeIcon.Name = "MinimizeIcon"
    minimizeIcon.Image = "rbxassetid://86388357896435"
    minimizeIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
    minimizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    minimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    minimizeIcon.BackgroundTransparency = 1
    minimizeIcon.ImageColor3 = Theme.Colors.TextSecondary
    minimizeIcon.ScaleType = Enum.ScaleType.Fit
    minimizeIcon.Parent = minimizeBtn
    
    minimizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
        Animator:Bounce(minimizeBtn, 0.9)
    end)
    
    -- ✖ Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    closeBtn.Position = UDim2.new(1, -(buttonSize + spacing), 0.5, -buttonSize/2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = ""
    closeBtn.Parent = parent
    
    local closeIcon = Instance.new("ImageLabel")
    closeIcon.Name = "CloseIcon"
    closeIcon.Image = "rbxassetid://100353373935291"
    closeIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.BackgroundTransparency = 1
    closeIcon.ImageColor3 = Theme.Colors.TextSecondary
    closeIcon.ScaleType = Enum.ScaleType.Fit
    closeIcon.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    -- 🎨 Hover effects
    if not IsMobile then
        minimizeBtn.MouseEnter:Connect(function()
            TweenService:Create(minimizeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.AccentPrimary
            }):Play()
        end)
        
        minimizeBtn.MouseLeave:Connect(function()
            TweenService:Create(minimizeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.TextSecondary
            }):Play()
        end)
        
        closeBtn.MouseEnter:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Color3.fromRGB(255, 80, 80)
            }):Play()
        end)
        
        closeBtn.MouseLeave:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.TextSecondary
            }):Play()
        end)
    end
end

function Window:CreateWindowButtons(parent)
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -Theme.GetResponsiveSize(16, 20, 24), 1, 0)
    container.Position = UDim2.new(0, 0, 0, 0)
    container.Parent = parent
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, Theme.Sizes.PaddingSmall)
    layout.Parent = container
    
    local buttonSize = Theme.GetResponsiveSize(24, 28, 32)
    local iconSize = Theme.GetResponsiveSize(12, 14, 16)
    
    -- 🗕 Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeButton"
    minimizeBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    minimizeBtn.BackgroundColor3 = Theme.Colors.Surface
    minimizeBtn.BackgroundTransparency = 0.5
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = ""
    minimizeBtn.Parent = container
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeBtn
    
    local minimizeStroke = Instance.new("UIStroke")
    minimizeStroke.Color = Theme.Colors.Border
    minimizeStroke.Transparency = 0.5
    minimizeStroke.Thickness = 1
    minimizeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    minimizeStroke.Parent = minimizeBtn
    
    local minimizeIcon = Instance.new("ImageLabel")
    minimizeIcon.Name = "MinimizeIcon"
    minimizeIcon.Image = "rbxassetid://86388357896435"
    minimizeIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
    minimizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    minimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    minimizeIcon.BackgroundTransparency = 1
    minimizeIcon.ImageColor3 = Theme.Colors.TextSecondary
    minimizeIcon.ScaleType = Enum.ScaleType.Fit
    minimizeIcon.Parent = minimizeBtn
    
    minimizeBtn.MouseButton1Click:Connect(function()
        self:MinimizeWindow()
        Animator:Bounce(minimizeBtn, 0.9)
    end)
    
    -- ✖ Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    closeBtn.BackgroundColor3 = Theme.Colors.Surface
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = ""
    closeBtn.Parent = container
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    local closeStroke = Instance.new("UIStroke")
    closeStroke.Color = Theme.Colors.Border
    closeStroke.Transparency = 0.5
    closeStroke.Thickness = 1
    closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    closeStroke.Parent = closeBtn
    
    local closeIcon = Instance.new("ImageLabel")
    closeIcon.Name = "CloseIcon"
    closeIcon.Image = "rbxassetid://100353373935291"
    closeIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.BackgroundTransparency = 1
    closeIcon.ImageColor3 = Theme.Colors.TextSecondary
    closeIcon.ScaleType = Enum.ScaleType.Fit
    closeIcon.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    -- 🎨 Hover effects
    if not IsMobile then
        minimizeBtn.MouseEnter:Connect(function()
            TweenService:Create(minimizeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.AccentPrimary
            }):Play()
            TweenService:Create(minimizeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.2,
                Color = Theme.Colors.AccentPrimary
            }):Play()
        end)
        
        minimizeBtn.MouseLeave:Connect(function()
            TweenService:Create(minimizeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.TextSecondary
            }):Play()
            TweenService:Create(minimizeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.5,
                Color = Theme.Colors.Border
            }):Play()
        end)
        
        closeBtn.MouseEnter:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Color3.fromRGB(255, 80, 80)
            }):Play()
            TweenService:Create(closeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.2,
                Color = Color3.fromRGB(255, 80, 80)
            }):Play()
        end)
        
        closeBtn.MouseLeave:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.TextSecondary
            }):Play()
            TweenService:Create(closeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.5,
                Color = Theme.Colors.Border
            }):Play()
        end)
    end
end

function Window:CreateTopbar()
    -- Topbar tanpa glass effect bertumpuk, cuma border bawah
    self.Topbar = Instance.new("Frame")
    self.Topbar.Name = "Topbar"
    self.Topbar.BackgroundTransparency = 1
    self.Topbar.Size = UDim2.new(1, 0, 0, Theme.Sizes.TopbarHeight)
    self.Topbar.Position = UDim2.new(0, 0, 0, 0)
    self.Topbar.BorderSizePixel = 0
    self.Topbar.ZIndex = 5
    self.Topbar.Parent = self.MainFrame
    
    -- Border bawah topbar (garis pemisah subtle)
    local bottomBorder = Instance.new("Frame")
    bottomBorder.Name = "BottomBorder"
    bottomBorder.BackgroundColor3 = Theme.Colors.Border
    bottomBorder.BackgroundTransparency = 0.7
    bottomBorder.BorderSizePixel = 0
    bottomBorder.Size = UDim2.new(1, 0, 0, 1)
    bottomBorder.Position = UDim2.new(0, 0, 1, -1)
    bottomBorder.ZIndex = 5
    bottomBorder.Parent = self.Topbar
    
    -- Center Section: Title & Subtitle (sekarang di kiri)
    local centerSection = Instance.new("Frame")
    centerSection.BackgroundTransparency = 1
    centerSection.Size = UDim2.new(1, -Theme.GetResponsiveSize(120, 140, 160), 1, 0)
    centerSection.Position = UDim2.new(0, 0, 0, 0)
    centerSection.Parent = self.Topbar
    
    -- 🎨 Title dengan Gradient Cyan-Purple
    local titleLabel = Utils:CreateText(centerSection, self.Title, {
        Font = Enum.Font.GothamBold,
        TextSize = Theme.GetResponsiveSize(15, 17, 19),
        TextColor = Color3.fromRGB(0, 255, 255), -- Base cyan
        Size = UDim2.new(1, 0, 0.55, 0),
        Position = UDim2.new(0, Theme.GetResponsiveSize(16, 20, 24), 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom
    })
    
    -- Gradient overlay untuk title (Cyan → Purple)
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),    -- Cyan
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(138, 43, 226)), -- Purple
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))   -- White
    })
    titleGradient.Rotation = 0
    titleGradient.Parent = titleLabel
    
    -- Stroke untuk title biar lebih pop
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(0, 255, 255)
    titleStroke.Transparency = 0.7
    titleStroke.Thickness = 1
    titleStroke.Parent = titleLabel
    
    if not IsMobile then
        -- 💬 Subtitle dengan gradient sama kayak title
        local subtitleLabel = Utils:CreateText(centerSection, self.Subtitle, {
            Font = Enum.Font.GothamBold,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Color3.fromRGB(0, 255, 255), -- Base cyan
            Size = UDim2.new(1, 0, 0.45, 0),
            Position = UDim2.new(0, Theme.GetResponsiveSize(16, 20, 24), 0.55, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        
        -- Gradient untuk subtitle (sama persis kayak title)
        local subtitleGradient = Instance.new("UIGradient")
        subtitleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),    -- Cyan
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(138, 43, 226)), -- Purple
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))   -- White
        })
        subtitleGradient.Rotation = 0
        subtitleGradient.Parent = subtitleLabel
        
        -- Stroke untuk subtitle
        local subtitleStroke = Instance.new("UIStroke")
        subtitleStroke.Color = Color3.fromRGB(0, 255, 255)
        subtitleStroke.Transparency = 0.7
        subtitleStroke.Thickness = 1
        subtitleStroke.Parent = subtitleLabel
    end
    
    -- Right Section: Window Buttons
    local rightSection = Instance.new("Frame")
    rightSection.BackgroundTransparency = 1
    rightSection.Size = UDim2.new(0, Theme.GetResponsiveSize(120, 140, 160), 1, 0)
    rightSection.Position = UDim2.new(1, -Theme.GetResponsiveSize(120, 140, 160), 0, 0)
    rightSection.Parent = self.Topbar
    
    self:CreateWindowButtons(rightSection)
end

function Window:CreateWindowButtons(parent)
    local buttonSize = Theme.GetResponsiveSize(24, 28, 32)
    local iconSize = Theme.GetResponsiveSize(18, 20, 22)
    local spacing = Theme.GetResponsiveSize(8, 10, 12)
    
    -- 🗕 Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeButton"
    minimizeBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    minimizeBtn.Position = UDim2.new(1, -(buttonSize * 2 + spacing * 2), 0.5, -buttonSize/2)
    minimizeBtn.BackgroundColor3 = Theme.Colors.Surface
    minimizeBtn.BackgroundTransparency = 0.5
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = ""
    minimizeBtn.Parent = parent
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeBtn
    
    local minimizeStroke = Instance.new("UIStroke")
    minimizeStroke.Color = Theme.Colors.Border
    minimizeStroke.Transparency = 0.5
    minimizeStroke.Thickness = 1
    minimizeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    minimizeStroke.Parent = minimizeBtn
    
    local minimizeIcon = Instance.new("ImageLabel")
    minimizeIcon.Name = "MinimizeIcon"
    minimizeIcon.Image = "rbxassetid://86388357896435"
    minimizeIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
    minimizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    minimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    minimizeIcon.BackgroundTransparency = 1
    minimizeIcon.ImageColor3 = Theme.Colors.TextSecondary
    minimizeIcon.ScaleType = Enum.ScaleType.Fit
    minimizeIcon.Parent = minimizeBtn
    
    minimizeBtn.MouseButton1Click:Connect(function()
        if self.MinimizeWindow then
            self:MinimizeWindow()
        end
        Animator:Bounce(minimizeBtn, 0.9)
    end)
    
    -- ✖ Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    closeBtn.Position = UDim2.new(1, -(buttonSize + spacing), 0.5, -buttonSize/2)
    closeBtn.BackgroundColor3 = Theme.Colors.Surface
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = ""
    closeBtn.Parent = parent
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    local closeStroke = Instance.new("UIStroke")
    closeStroke.Color = Theme.Colors.Border
    closeStroke.Transparency = 0.5
    closeStroke.Thickness = 1
    closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    closeStroke.Parent = closeBtn
    
    local closeIcon = Instance.new("ImageLabel")
    closeIcon.Name = "CloseIcon"
    closeIcon.Image = "rbxassetid://100353373935291"
    closeIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.BackgroundTransparency = 1
    closeIcon.ImageColor3 = Theme.Colors.TextSecondary
    closeIcon.ScaleType = Enum.ScaleType.Fit
    closeIcon.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    -- 🎨 Hover effects
    if not IsMobile then
        minimizeBtn.MouseEnter:Connect(function()
            TweenService:Create(minimizeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.AccentPrimary
            }):Play()
            TweenService:Create(minimizeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.2,
                Color = Theme.Colors.AccentPrimary
            }):Play()
        end)
        
        minimizeBtn.MouseLeave:Connect(function()
            TweenService:Create(minimizeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.TextSecondary
            }):Play()
            TweenService:Create(minimizeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.5,
                Color = Theme.Colors.Border
            }):Play()
        end)
        
        closeBtn.MouseEnter:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Color3.fromRGB(255, 80, 80)
            }):Play()
            TweenService:Create(closeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.2,
                Color = Color3.fromRGB(255, 80, 80)
            }):Play()
        end)
        
        closeBtn.MouseLeave:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(Theme.Animations.Fast), {
                ImageColor3 = Theme.Colors.TextSecondary
            }):Play()
            TweenService:Create(closeStroke, TweenInfo.new(Theme.Animations.Fast), {
                Transparency = 0.5,
                Color = Theme.Colors.Border
            }):Play()
        end)
    end
end

function Window:CreateSidebar()
    if self.SidebarCollapsed == nil then
        self.SidebarCollapsed = true
    end

    -- Sidebar tanpa glass effect bertumpuk, cuma border kanan
    self.Sidebar = Instance.new("Frame")
    self.Sidebar.Name = "Sidebar"
    self.Sidebar.BackgroundTransparency = 1
    self.Sidebar.Size = UDim2.new(0, self.SidebarCollapsed and Theme.Sizes.SidebarMinimized or Theme.Sizes.SidebarWidth, 1, -Theme.Sizes.TopbarHeight)
    self.Sidebar.Position = UDim2.new(0, 0, 0, Theme.Sizes.TopbarHeight)
    self.Sidebar.BorderSizePixel = 0
    self.Sidebar.ZIndex = 3
    self.Sidebar.ClipsDescendants = false
    self.Sidebar.Parent = self.MainFrame
    
    -- Border kanan sidebar (garis pemisah)
    local rightBorder = Instance.new("Frame")
    rightBorder.Name = "RightBorder"
    rightBorder.BackgroundColor3 = Theme.Colors.Border
    rightBorder.BackgroundTransparency = 0.7
    rightBorder.BorderSizePixel = 0
    rightBorder.Size = UDim2.new(0, 1, 1, 0)
    rightBorder.Position = UDim2.new(1, -1, 0, 0)
    rightBorder.ZIndex = 3
    rightBorder.Parent = self.Sidebar

    -- Tab Container dengan auto-sizing
    self.TabContainer = Instance.new("ScrollingFrame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.BorderSizePixel = 0
    self.TabContainer.Size = UDim2.new(1, 0, 1, -Theme.GetResponsiveSize(70, 80, 90))
    self.TabContainer.Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(10, 12, 14))
    self.TabContainer.ScrollBarThickness = 4
    self.TabContainer.ScrollBarImageColor3 = Theme.Colors.AccentPrimary
    self.TabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    self.TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabContainer.ZIndex = 3
    self.TabContainer.Parent = self.Sidebar

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, Theme.Sizes.PaddingSmall)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.TabContainer

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, Theme.Sizes.PaddingSmall)
    padding.PaddingLeft = UDim.new(0, Theme.Sizes.PaddingSmall)
    padding.PaddingRight = UDim.new(0, Theme.Sizes.PaddingSmall)
    padding.PaddingBottom = UDim.new(0, Theme.Sizes.PaddingSmall)
    padding.Parent = self.TabContainer

    -- Toggle Button di bawah (fixed position)
    local toggleBtnContainer = Instance.new("Frame")
    toggleBtnContainer.BackgroundTransparency = 1
    toggleBtnContainer.Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(60, 70, 80))
    toggleBtnContainer.Position = UDim2.new(0, 0, 1, -Theme.GetResponsiveSize(60, 70, 80))
    toggleBtnContainer.ZIndex = 5
    toggleBtnContainer.Parent = self.Sidebar

    local toggleBtn = Utils:CreateGlassFrame(toggleBtnContainer, {
        Color = Theme.Colors.AccentPrimary,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(0, Theme.GetResponsiveSize(38, 42, 46), 0, Theme.GetResponsiveSize(38, 42, 46)),
        Position = UDim2.new(0.5, -Theme.GetResponsiveSize(19, 21, 23), 0.5, -Theme.GetResponsiveSize(19, 21, 23)),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.AccentPrimary,
        StrokeTransparency = 0.2
    })

    local toggleIcon = Utils:CreateIcon(toggleBtn, self.SidebarCollapsed and "▶" or "◀", {
        Size = Theme.GetResponsiveSize(14, 15, 16),
        Color = Theme.Colors.TextPrimary,
        Position = UDim2.new(0.5, -Theme.GetResponsiveSize(7, 7, 8), 0.5, -Theme.GetResponsiveSize(7, 7, 8))
    })

    local toggleBtnClick = Instance.new("TextButton")
    toggleBtnClick.Size = UDim2.new(1, 0, 1, 0)
    toggleBtnClick.BackgroundTransparency = 1
    toggleBtnClick.Text = ""
    toggleBtnClick.ZIndex = 10
    toggleBtnClick.Parent = toggleBtn

    toggleBtnClick.MouseButton1Click:Connect(function()
        self:ToggleSidebar()
        toggleIcon.Text = self.SidebarCollapsed and "▶" or "◀"
        Animator:Bounce(toggleBtn, 0.9)
    end)

    if not IsMobile then
        Input:AddHoverEffect(toggleBtn,
            {
                BackgroundTransparency = Theme.Transparency.GlassHover,
                StrokeTransparency = 0.05,
                StrokeColor = Theme.Colors.NeonCyan
            },
            {
                BackgroundTransparency = Theme.Transparency.Glass,
                StrokeTransparency = 0.2,
                StrokeColor = Theme.Colors.AccentPrimary
            }
        )
    end
end

function Window:CreateContentArea()
    local sidebarWidth = self.SidebarCollapsed and Theme.Sizes.SidebarMinimized or Theme.Sizes.SidebarWidth
    
    -- Content area tanpa background, langsung di atas background utama
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Name = "ContentArea"
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Size = UDim2.new(1, -sidebarWidth, 1, -Theme.Sizes.TopbarHeight)
    self.ContentArea.Position = UDim2.new(0, sidebarWidth, 0, Theme.Sizes.TopbarHeight)
    self.ContentArea.BorderSizePixel = 0
    self.ContentArea.ZIndex = 2
    self.ContentArea.Parent = self.MainFrame
end

function Window:CreateMinimizedLogo()
    local logoSize = Theme.Sizes.MinimizedLogoSize
    
    -- Ambil posisi tersimpan atau pakai default
    local savedPos = LoadGlobal("VyperUI_MinimizedPosition") or UDim2.new(0, 20, 1, -logoSize - 20)
    
    -- Frame dengan background hitam pekat
    self.MinimizedLogo = Instance.new("Frame")
    self.MinimizedLogo.Name = "MinimizedLogo"
    self.MinimizedLogo.Active = true -- Fix: Biar screen ga gerak pas drag logo
    self.MinimizedLogo.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    self.MinimizedLogo.BackgroundTransparency = 0
    self.MinimizedLogo.Size = UDim2.new(0, logoSize, 0, logoSize)
    self.MinimizedLogo.Size = UDim2.new(0, logoSize, 0, logoSize)
    self.MinimizedLogo.Position = savedPos
    self.MinimizedLogo.BorderSizePixel = 0
    self.MinimizedLogo.ZIndex = 10
    self.MinimizedLogo.Parent = self.GUI
    self.MinimizedLogo.Visible = false
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = self.MinimizedLogo
    
    -- Border biru neon
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Colors.AccentPrimary
    stroke.Thickness = 2
    stroke.Transparency = 0.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = self.MinimizedLogo
    
    -- Logo image FULL SIZE
    local logoImage = Instance.new("ImageLabel")
    logoImage.Name = "LogoImage"
    logoImage.BackgroundTransparency = 1
    logoImage.Size = UDim2.new(1, 0, 1, 0)
    logoImage.Position = UDim2.new(0, 0, 0, 0)
    logoImage.Image = "rbxassetid://107726435417936"
    logoImage.ImageColor3 = Theme.Colors.TextPrimary
    logoImage.ZIndex = 11
    logoImage.Parent = self.MinimizedLogo
    
    -- Corner radius di logo
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 12)
    logoCorner.Parent = logoImage
    
    -- BIKIN DRAGGABLE
    Input:MakeDraggable(self.MinimizedLogo)
    
    -- Simpan posisi setiap kali di-drag
    self.MinimizedLogo:GetPropertyChangedSignal("Position"):Connect(function()
        SaveGlobal("VyperUI_MinimizedPosition", self.MinimizedLogo.Position)
    end)
    
    -- CLICK untuk restore (dengan delay detection)
    local isDragging = false
    local startPosition = nil
    
    self.MinimizedLogo.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            startPosition = self.MinimizedLogo.Position
        end
    end)
    
    self.MinimizedLogo.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            -- Cek apakah posisi berubah (artinya di-drag)
            if startPosition and self.MinimizedLogo.Position == startPosition then
                -- Posisi ga berubah = click biasa, restore window
                self:RestoreWindow()
            end
        end
    end)
end

function Window:ToggleSidebar()
    self.SidebarCollapsed = not self.SidebarCollapsed
    
    local newWidth = self.SidebarCollapsed and Theme.Sizes.SidebarMinimized or Theme.Sizes.SidebarWidth
    local contentX = newWidth
    
    Animator:Spring(self.Sidebar, {Size = UDim2.new(0, newWidth, 1, -Theme.Sizes.TopbarHeight)})
    Animator:Spring(self.ContentArea, {
        Size = UDim2.new(1, -newWidth, 1, -Theme.Sizes.TopbarHeight),
        Position = UDim2.new(0, contentX, 0, Theme.Sizes.TopbarHeight)
    })
    
    for _, tab in ipairs(self.Tabs) do
        if tab.Button then
            local textLabel = tab.Button:FindFirstChild("TabText")
            if textLabel then
                if self.SidebarCollapsed then
                    Animator:Tween(textLabel, {TextTransparency = 1}, Theme.Animations.Fast)
                else
                    Animator:Tween(textLabel, {TextTransparency = 0}, Theme.Animations.Fast)
                end
            end
        end
    end
end

function Window:MinimizeWindow()
    if self.IsMinimized then return end
    
    -- ✅ MANUAL SAVE DOULU SEBELUM FLAG AKTIF
    -- Listener akan stop save saat IsMinimized = true, jadi kita save state terakhir sekarang
    if self.MainFrame.AbsoluteSize.X > 50 then
        SaveGlobal("VyperUI_WindowSize", self.MainFrame.Size)
        SaveGlobal("VyperUI_WindowPosition", self.MainFrame.Position)
    end
    
    self.IsMinimized = true
    
    -- ✨ SIMPLE ANIMATION: Fade Out & Hide
    Animator:Tween(self.MainFrame, {
        BackgroundTransparency = 1 -- Fade out background
    }, Theme.Animations.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
        self.MainFrame.Visible = false
        
        -- Show Logo
        self.MinimizedLogo.Visible = true
        self.MinimizedLogo.BackgroundTransparency = 1
        Animator:Tween(self.MinimizedLogo, {BackgroundTransparency = 0}, Theme.Animations.Fast)
    end)
    
    -- Hide children explicitly if needed, but Visible=false handles it after delay
    for _, child in ipairs(self.MainFrame:GetChildren()) do
        if child:IsA("GuiObject") then
             -- Optional: Fade children too if you want super smoothness
             -- But standard Fade Out -> Visible = false is usually enough
        end
    end
end

function Window:RestoreWindow()
    local savedSize = LoadGlobal("VyperUI_WindowSize") or self.Size
    local savedPos = LoadGlobal("VyperUI_WindowPosition") or self.MainFrame.Position
    
    -- Hide Logo
    Animator:Tween(self.MinimizedLogo, {
        BackgroundTransparency = 1
    }, Theme.Animations.Fast, nil, nil, function()
        self.MinimizedLogo.Visible = false
        
        -- ✨ SIMPLE ANIMATION: Show & Fade In
        self.MainFrame.Position = savedPos
        self.MainFrame.Size = savedSize
        self.MainFrame.BackgroundTransparency = 1 -- Start transparent
        self.MainFrame.Visible = true
        
        Animator:Tween(self.MainFrame, {
            BackgroundTransparency = 0.10 -- Fade in to match initial transparency
        }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
            self.IsMinimized = false
        end)
    end)
end

function Window:CreateTab(config)
    config = config or {}
    local title = config.Title or "Tab"
    local icon = config.Icon or "●"
    
    local tab = {
        Title = title,
        Icon = icon,
        Content = nil,
        Button = nil,
        Active = false
    }
    
    local buttonHeight = Theme.GetResponsiveSize(32, 34, 36) -- Compact Tab Button
    
    -- 🧱 Tab button (BACKGROUND TRANSPARAN PENUH)
    tab.Button = Utils:CreateGlassFrame(self.TabContainer, {
        Color = Theme.Colors.Surface,
        Transparency = 1,
        Size = UDim2.new(1, 0, 0, buttonHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    -- 🖼️ Icon gambar (ImageLabel)
    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "TabIcon"
    iconImage.Image = icon
    iconImage.Size = UDim2.new(0, Theme.GetResponsiveSize(20, 22, 24), 0, Theme.GetResponsiveSize(20, 22, 24))
    iconImage.Position = UDim2.new(0, Theme.Sizes.Padding, 0.5, 0)
    iconImage.AnchorPoint = Vector2.new(0, 0.5)
    iconImage.BackgroundTransparency = 1
    iconImage.ImageColor3 = Theme.Colors.TextSecondary
    iconImage.ScaleType = Enum.ScaleType.Fit
    iconImage.Parent = tab.Button
    
    -- 📝 Text label sejajar dengan icon
    local textLabel = Utils:CreateText(tab.Button, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextSecondary,
        Size = UDim2.new(1, -Theme.GetResponsiveSize(50, 55, 60), 1, 0),
        Position = UDim2.new(0, Theme.GetResponsiveSize(40, 45, 50), 0, 0),
        TextTransparency = self.SidebarCollapsed and 1 or 0
    })
    textLabel.Name = "TabText"
    
    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 10
    clickBtn.Parent = tab.Button
    
    clickBtn.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
        Animator:Bounce(tab.Button, 0.95)
    end)
    
    -- 🌈 Hover effect: Cuma border yang glow
    local stroke = tab.Button:FindFirstChildOfClass("UIStroke")
    if not IsMobile and stroke then
        clickBtn.MouseEnter:Connect(function()
            if not tab.Active then
                pcall(function()
                    TweenService:Create(stroke, TweenInfo.new(Theme.Animations.Fast), {
                        Transparency = 0.3,
                        Color = Theme.Colors.AccentPrimary
                    }):Play()
                end)
            end
        end)
        
        clickBtn.MouseLeave:Connect(function()
            if not tab.Active then
                pcall(function()
                    TweenService:Create(stroke, TweenInfo.new(Theme.Animations.Fast), {
                        Transparency = 0.7,
                        Color = Theme.Colors.Border
                    }):Play()
                end)
            end
        end)
    end
    
    tab.Content = Instance.new("ScrollingFrame")
    tab.Content.Name = "TabContent_" .. title
    tab.Content.BackgroundTransparency = 1
    tab.Content.BorderSizePixel = 0
    tab.Content.Size = UDim2.new(1, 0, 1, 0)
    tab.Content.ScrollBarThickness = 6
    tab.Content.ScrollBarImageColor3 = Theme.Colors.AccentPrimary
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.Content.Visible = false
    tab.Content.ZIndex = 2
    tab.Content.Parent = self.ContentArea

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, Theme.Sizes.Spacing)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = tab.Content

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, Theme.Sizes.Padding)
    padding.PaddingLeft = UDim.new(0, Theme.Sizes.Padding)
    padding.PaddingRight = UDim.new(0, Theme.Sizes.Padding)
    padding.PaddingBottom = UDim.new(0, Theme.Sizes.Padding)
    padding.Parent = tab.Content

    tab.Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.Content.ScrollingDirection = Enum.ScrollingDirection.Y
    
    table.insert(self.Tabs, tab)
    
    if #self.Tabs == 1 then
        self:SwitchTab(tab)
    end
    
    return tab.Content
end

function Window:SwitchTab(targetTab)
    for _, tab in ipairs(self.Tabs) do
        local stroke = tab.Button:FindFirstChildOfClass("UIStroke")
        local iconLabel = tab.Button:FindFirstChild("TabIcon")
        local textLabel = tab.Button:FindFirstChild("TabText")
        
        if tab == targetTab then
            tab.Active = true
            tab.Content.Visible = true
            
            -- ✅ Background tetep transparan, cuma animasi BORDER & TEXT
            if stroke then
                Animator:Tween(stroke, {
                    Color = Theme.Colors.AccentPrimary,
                    Transparency = 0.3
                }, Theme.Animations.Fast)
            end
            
            if iconLabel then
                Animator:Tween(iconLabel, {TextColor3 = Theme.Colors.TextPrimary}, Theme.Animations.Fast)
            end
            
            if textLabel then
                Animator:Tween(textLabel, {TextColor3 = Theme.Colors.TextPrimary}, Theme.Animations.Fast)
            end
        else
            tab.Active = false
            tab.Content.Visible = false
            
            -- ✅ Tab inactive: border balik normal
            if stroke then
                Animator:Tween(stroke, {
                    Color = Theme.Colors.Border,
                    Transparency = 0.7
                }, Theme.Animations.Fast)
            end
            
            if iconLabel then
                Animator:Tween(iconLabel, {TextColor3 = Theme.Colors.TextSecondary}, Theme.Animations.Fast)
            end
            
            if textLabel then
                Animator:Tween(textLabel, {TextColor3 = Theme.Colors.TextSecondary}, Theme.Animations.Fast)
            end
        end
    end
    
    self.CurrentTab = targetTab
end

function Window:Destroy()
    -- ✅ FORCE SAVE SIZE (Just in case listener missed it)
    if self.MainFrame and self.MainFrame.AbsoluteSize.X > 50 then
        SaveGlobal("VyperUI_WindowSize", self.MainFrame.Size)
        SaveGlobal("VyperUI_WindowPosition", self.MainFrame.Position)
    end

    -- ✨ SIMPLE FADE OUT
    Animator:Tween(self.MainFrame, {
        BackgroundTransparency = 1
    }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
        if self.GUI then
            self.GUI:Destroy()
        end
    end)
end


-- ========================================
-- COMPONENTS V4.0
-- ========================================

local Components = {}

function Components:CreateButton(parent, config)
    config = config or {}
    local title = config.Title or "Button"
    local subtitle = config.Subtitle
    local callback = config.Callback or function() end
    local active = config.Active or false
    
    -- ✅ Config System Integration (Unique Key with Subtitle)
    local autoSave = config.AutoSave or false
    local configKey = "Button_" .. (title:gsub("%s+", ""))
    if subtitle then
        configKey = configKey .. "_" .. (subtitle:gsub("%s+", ""))
    end
    
    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        active = ConfigSystem.Data[configKey]
    end
    
    -- 🧱 Main Container (Transparan, Layout Kiri-Kanan)
    -- Height matched to CreateToggle/MultiDropdown logic: subtitle ? ~56 : ~36
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(1, 0, 0, subtitle and Theme.GetResponsiveSize(48, 52, 56) or Theme.Sizes.ButtonHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    -- LEFT SIDE: Text Container (Title + Subtitle)
    local textContainer = Instance.new("Frame")
    textContainer.BackgroundTransparency = 1
    textContainer.Size = UDim2.new(1, -Theme.GetResponsiveSize(100, 110, 120), 1, 0) -- Allow space for button on right
    textContainer.Position = UDim2.new(0, 0, 0, 0)
    textContainer.Parent = container
    
    Utils:CreateText(textContainer, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Position = UDim2.new(0, 0, 0, subtitle and Theme.GetResponsiveSize(3, 4, 5) or 0),
        TextYAlignment = subtitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 1, 0)
    })
    
    if subtitle then
        Utils:CreateText(textContainer, subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(20, 22, 24)),
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 1, 0)
        })
    end

    -- RIGHT SIDE: Button (Interactive Part)
    local buttonWidth = Theme.GetResponsiveSize(80, 90, 100)
    local buttonHeight = Theme.GetResponsiveSize(28, 30, 32)

    local buttonFrame = Utils:CreateGlassFrame(container, {
        Color = active and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight,
        Transparency = active and 0.2 or 0.1,
        Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
        Position = UDim2.new(1, -buttonWidth, 0.5, -buttonHeight/2),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = active and Theme.Colors.AccentPrimary or Theme.Colors.Border,
        StrokeTransparency = 0.5
    })

    local buttonText = Instance.new("TextLabel")
    buttonText.BackgroundTransparency = 1
    buttonText.Size = UDim2.new(1, 0, 1, 0)
    buttonText.Font = Theme.Fonts.Secondary
    buttonText.TextSize = Theme.GetResponsiveSize(11, 12, 13)
    buttonText.TextColor3 = Theme.Colors.TextPrimary
    buttonText.Text = active and "ON" or "OFF"
    buttonText.Parent = buttonFrame
    
    -- Click logic on the Right Button Frame
    local triggerBtn = Instance.new("TextButton")
    triggerBtn.Size = UDim2.new(1, 0, 1, 0)
    triggerBtn.BackgroundTransparency = 1
    triggerBtn.Text = ""
    triggerBtn.ZIndex = 10
    triggerBtn.Parent = buttonFrame

    triggerBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local startColor = active and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight
            local endColor = (not active) and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight
            
            -- Ripple Effect
            local clickPos = Vector2.new(input.Position.X, input.Position.Y)
            if buttonFrame.AbsolutePosition then
                clickPos = clickPos - buttonFrame.AbsolutePosition
            end
            pcall(function()
                Animator:Ripple(buttonFrame, clickPos, Theme.Colors.TextPrimary)
                Animator:Bounce(buttonFrame, 0.9)
            end)

            -- Toggle State
            active = not active
            
            -- Visual Update
            buttonText.Text = active and "ON" or "OFF"
            
            TweenService:Create(buttonFrame, TweenInfo.new(Theme.Animations.Fast), {
                BackgroundColor3 = endColor,
                BackgroundTransparency = active and 0.2 or 0.1
            }):Play()
            
            local stroke = buttonFrame:FindFirstChild("UIStroke")
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(Theme.Animations.Fast), {
                    Color = active and Theme.Colors.AccentPrimary or Theme.Colors.Border
                }):Play()
            end

            -- ✅ Auto-Save (Update Data ONLY)
            if autoSave then
                ConfigSystem.Data[configKey] = active
            end
            
            callback(active)
        end
    end)
    
    -- Hover Effects (Right Button Only)
    if not IsMobile then
        local stroke = buttonFrame:FindFirstChild("UIStroke")
        triggerBtn.MouseEnter:Connect(function()
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(Theme.Animations.Fast), {
                    Transparency = 0.1,
                    Color = Theme.Colors.NeonCyan
                }):Play()
            end
        end)
        
        triggerBtn.MouseLeave:Connect(function()
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(Theme.Animations.Fast), {
                    Transparency = 0.5,
                    Color = active and Theme.Colors.AccentPrimary or Theme.Colors.Border
                }):Play()
            end
        end)
    end

    -- [NEW] Register to Config System
    if autoSave and configKey then
        ElementRegistry[configKey] = {
            Default = config.Active or false, -- Store default
            Update = function(val)
                active = val
                buttonText.Text = active and "ON" or "OFF"
                buttonFrame.BackgroundColor3 = active and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight
                buttonFrame.BackgroundTransparency = active and 0.2 or 0.1
                local stroke = buttonFrame:FindFirstChild("UIStroke")
                if stroke then
                    stroke.Color = active and Theme.Colors.AccentPrimary or Theme.Colors.Border
                end
                callback(active)
            end
        }
    end

    -- ✅ Trigger Callback if loaded from Config
    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        task.defer(function()
            callback(active)
        end)
    end

    return container
end



function Components:CreateToggle(parent, config)
    config = config or {}
    local title = config.Title or "Toggle"
    local subtitle = config.Subtitle
    local default = config.Default or false
    local callback = config.Callback or function() end

    -- ✅ CONFIG LOAD AT START (Fix Visual Sync)
    local autoSave = config.AutoSave or false
    local configKey = "Toggle_" .. (title:gsub("%s+", ""))
    if subtitle then
        configKey = configKey .. "_" .. (subtitle:gsub("%s+", ""))
    end

    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        default = ConfigSystem.Data[configKey]
        print("🔘 [VyperUI] Toggle Loaded:", configKey, "| State:", tostring(default))
    end
    
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(1, 0, 0, subtitle and Theme.GetResponsiveSize(48, 52, 56) or Theme.Sizes.ButtonHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    local textContainer = Instance.new("Frame")
    textContainer.BackgroundTransparency = 1
    textContainer.Size = UDim2.new(1, -60, 1, 0)
    textContainer.Parent = container
    
    Utils:CreateText(textContainer, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Position = UDim2.new(0, 0, 0, subtitle and Theme.GetResponsiveSize(3, 4, 5) or 0),
        TextYAlignment = subtitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        -- TextScaled = IsMobile
    })
    
    if subtitle then
        Utils:CreateText(textContainer, subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(20, 22, 24)),
            TextYAlignment = Enum.TextYAlignment.Top,
            -- TextScaled = IsMobile
        })
    end
    
    local toggleSize = Theme.GetResponsiveSize(18, 20, 22) -- Smaller Toggle Switch
    local trackWidth = Theme.GetResponsiveSize(36, 40, 44) -- Smaller Track
    
    local toggleTrack = Utils:CreateGlassFrame(container, {
        Color = default and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight,
        Transparency = 0.1,
        Size = UDim2.new(0, trackWidth, 0, toggleSize),
        Position = UDim2.new(1, -trackWidth, 0.5, -toggleSize/2),
        CornerRadius = toggleSize/2,
        Stroke = false
    })
    
    -- Glow removed for cleaner look
    
    local knobSize = Theme.GetResponsiveSize(14, 16, 18) -- Smaller Knob
    local toggleKnob = Instance.new("Frame")
    toggleKnob.BackgroundColor3 = Theme.Colors.TextPrimary
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Size = UDim2.new(0, knobSize, 0, knobSize)
    toggleKnob.Position = default and UDim2.new(1, -knobSize - 3, 0.5, -knobSize/2) or UDim2.new(0, 3, 0.5, -knobSize/2)
    toggleKnob.ZIndex = 5
    toggleKnob.Parent = toggleTrack
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = toggleKnob
    
    -- Knob Shadow removed
    
    local state = default
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 10
    button.Parent = container
    
    button.MouseButton1Click:Connect(function()
        state = not state
        
        -- ✅ Auto-Save (Update Data ONLY)
        if autoSave then
             ConfigSystem.Data[configKey] = state
             -- ConfigSystem:Save() -- Disabled for Manual Save
        end
        
        Animator:Bounce(toggleTrack, 0.95)
        
        if state then
            Animator:Spring(toggleKnob, {Position = UDim2.new(1, -knobSize - 3, 0.5, -knobSize/2)})
            Animator:Tween(toggleTrack, {BackgroundColor3 = Theme.Colors.AccentPrimary}, Theme.Animations.Fast)
        else
            Animator:Spring(toggleKnob, {Position = UDim2.new(0, 3, 0.5, -knobSize/2)})
            Animator:Tween(toggleTrack, {BackgroundColor3 = Theme.Colors.SurfaceLight}, Theme.Animations.Fast)
        end
        
        callback(state)
    end)
    
    -- ✅ Hover: Ga perlu tween background lagi (udah transparan)
    -- Border tetep ada dari stroke default
    if not IsMobile then
        local stroke = container:FindFirstChildOfClass("UIStroke")
        if stroke then
            button.MouseEnter:Connect(function()
                pcall(function()
                    TweenService:Create(stroke, TweenInfo.new(Theme.Animations.Fast), {
                        Transparency = 0.4,
                        Color = Theme.Colors.NeonCyan
                    }):Play()
                end)
            end)
            
            button.MouseLeave:Connect(function()
                pcall(function()
                    TweenService:Create(stroke, TweenInfo.new(Theme.Animations.Fast), {
                        Transparency = 0.7,
                        Color = Theme.Colors.Border
                    }):Play()
                end)
            end)
        end
    end
    
    -- [NEW] Register to Config System
    if autoSave and configKey then
        ElementRegistry[configKey] = {
            Default = default, -- Store default
            Update = function(val)
                state = val
                if state then
                    Animator:Spring(toggleKnob, {Position = UDim2.new(1, -knobSize - 3, 0.5, -knobSize / 2)})
                    Animator:Tween(toggleTrack, {BackgroundColor3 = Theme.Colors.AccentPrimary}, Theme.Animations.Fast)
                else
                    Animator:Spring(toggleKnob, {Position = UDim2.new(0, 3, 0.5, -knobSize / 2)})
                    Animator:Tween(toggleTrack, {BackgroundColor3 = Theme.Colors.SurfaceLight}, Theme.Animations.Fast)
                end
                callback(state)
            end
        }
    end

    -- ✅ Trigger Callback if loaded from Config
    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        task.defer(function()
            callback(state)
        end)
    end

    return container
end


function Components:CreateDropdown(parent, config)
    config = config or {}
    local title = config.Title or "Dropdown"
    local subtitle = config.Subtitle
    local options = config.Options or {"Option 1", "Option 2", "Option 3"}
    local default = config.Default or options[1]
    local callback = config.Callback or function() end

    -- ✅ Config System Integration (Unique Key with Subtitle)
    local autoSave = config.AutoSave or false
    local configKey = "Dropdown_" .. (title:gsub("%s+", ""))
    if subtitle then
        configKey = configKey .. "_" .. (subtitle:gsub("%s+", ""))
    end

    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        default = ConfigSystem.Data[configKey]
    end

    -- 🧱 Main Container (Transparan, Layout Kiri-Kanan)
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(1, 0, 0, subtitle and Theme.GetResponsiveSize(48, 52, 56) or Theme.Sizes.ButtonHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)

    -- LEFT SIDE: Text Container (Title + Subtitle)
    local textContainer = Instance.new("Frame")
    textContainer.BackgroundTransparency = 1
    textContainer.Size = UDim2.new(1, -Theme.GetResponsiveSize(130, 145, 160), 1, 0)
    textContainer.Position = UDim2.new(0, 0, 0, 0)
    textContainer.Parent = container
    
    -- Title Label
    Utils:CreateText(textContainer, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Position = UDim2.new(0, 0, 0, subtitle and Theme.GetResponsiveSize(3, 4, 5) or 0),
        TextYAlignment = subtitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 1, 0)
    })
    
    -- Subtitle Label
    if subtitle then
        Utils:CreateText(textContainer, subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(20, 22, 24)),
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 1, 0)
        })
    end

    -- RIGHT SIDE: Button Container
    local buttonWidth = Theme.GetResponsiveSize(120, 135, 150)
    local buttonHeight = Theme.GetResponsiveSize(28, 32, 36)

    local buttonFrame = Utils:CreateGlassFrame(container, {
        Color = Theme.Colors.SurfaceLight,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
        Position = UDim2.new(1, -buttonWidth, 0.5, -buttonHeight/2),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.AccentPrimary,
        StrokeTransparency = 0.6
    })

    local currentOption = default

    -- TRIGGER BUTTON
    local triggerBtn = Instance.new("TextButton")
    triggerBtn.Size = UDim2.new(1, 0, 1, 0)
    triggerBtn.BackgroundTransparency = 1
    triggerBtn.Text = currentOption
    triggerBtn.Font = Theme.Fonts.Secondary
    triggerBtn.TextSize = Theme.GetResponsiveSize(11, 12, 13)
    triggerBtn.TextColor3 = Theme.Colors.TextPrimary
    triggerBtn.TextTruncate = Enum.TextTruncate.AtEnd
    triggerBtn.Parent = buttonFrame

    -- Icon Chevron Right (indicate opening right drawer)
    local icon = Instance.new("TextLabel")
    icon.Text = "▶"
    icon.BackgroundTransparency = 1
    icon.TextColor3 = Theme.Colors.AccentPrimary
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = Theme.GetResponsiveSize(10, 11, 12)
    icon.Size = UDim2.new(0, 15, 1, 0)
    icon.Position = UDim2.new(1, -20, 0, 0) -- Moved to Right
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Parent = buttonFrame

    -- =========================================================
    -- RIGHT SIDE DRAWER LOGIC (ATTACHED TO WINDOW)
    -- =========================================================
    
    local drawerOpen = false
    local drawerFrame 

    local function ToggleDrawer()
        if drawerOpen then
            -- CLOSE DRAWER
            if drawerFrame then
                Animator:Tween(drawerFrame, {
                    Position = UDim2.new(1, 0, 0, Theme.Sizes.TopbarHeight) -- Slide Out Right
                }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
                    drawerFrame.Visible = false
                end)
            end
            drawerOpen = false
        else
            -- OPEN DRAWER
            drawerOpen = true
            
            -- FIX: Find Window MAINFRAME
            local windowFrame = container
            while windowFrame.Parent and not windowFrame.Parent:IsA("ScreenGui") do
                windowFrame = windowFrame.Parent
            end
            
            if not windowFrame or not windowFrame.Parent:IsA("ScreenGui") then
                warn("VyperUI: Could not find Window Frame for Dropdown Drawer")
                return 
            end

            -- Create Drawer if not exists
            if not drawerFrame then
                local drawerWidth = Theme.Sizes.SidebarWidth + 30
                
                drawerFrame = Utils:CreateGlassFrame(windowFrame, {
                    Color = Theme.Colors.Surface,
                    Transparency = 0.05,
                    Size = UDim2.new(0, drawerWidth, 1, -Theme.Sizes.TopbarHeight),
                    Position = UDim2.new(1, 0, 0, Theme.Sizes.TopbarHeight), -- Start Hidden Right
                    CornerRadius = 0,
                    StrokeColor = Theme.Colors.AccentPrimary,
                    StrokeTransparency = 0.5,
                    ZIndex = 50 
                })
                
                -- Fix border (Left Side)
                if drawerFrame:FindFirstChild("UIStroke") then drawerFrame.UIStroke:Destroy() end
                
                local leftBorder = Instance.new("Frame")
                leftBorder.BackgroundColor3 = Theme.Colors.AccentPrimary
                leftBorder.Size = UDim2.new(0, 1, 1, 0)
                leftBorder.Position = UDim2.new(0, 0, 0, 0)
                leftBorder.BorderSizePixel = 0
                leftBorder.Parent = drawerFrame

                -- HEADER
                local header = Instance.new("Frame")
                header.BackgroundTransparency = 1
                header.Size = UDim2.new(1, 0, 0, 40)
                header.Parent = drawerFrame
                
                Utils:CreateText(header, title, {
                    Font = Theme.Fonts.Primary,
                    TextSize = Theme.GetResponsiveSize(14, 15, 16),
                    TextColor = Theme.Colors.AccentPrimary,
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 15, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                -- Close Button
                local closeBtn = Instance.new("TextButton")
                closeBtn.Text = "✕"
                closeBtn.Font = Enum.Font.GothamBold
                closeBtn.TextColor3 = Theme.Colors.TextSecondary
                closeBtn.TextSize = 16
                closeBtn.BackgroundTransparency = 1
                closeBtn.Size = UDim2.new(0, 30, 0, 30)
                closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
                closeBtn.Parent = header
                
                closeBtn.MouseButton1Click:Connect(function()
                    ToggleDrawer()
                end)

                -- SCROLLING LIST
                local listFrame = Instance.new("ScrollingFrame")
                listFrame.BackgroundTransparency = 1
                listFrame.Size = UDim2.new(1, 0, 1, -50)
                listFrame.Position = UDim2.new(0, 0, 0, 45)
                listFrame.ScrollBarThickness = 4
                listFrame.ScrollBarImageColor3 = Theme.Colors.AccentPrimary
                listFrame.Parent = drawerFrame
                
                local listLayout = Instance.new("UIListLayout")
                listLayout.Padding = UDim.new(0, 5)
                listLayout.Parent = listFrame
                
                local listPadding = Instance.new("UIPadding")
                listPadding.PaddingLeft = UDim.new(0, 10)
                listPadding.PaddingRight = UDim.new(0, 10)
                listPadding.PaddingBottom = UDim.new(0, 10)
                listPadding.Parent = listFrame

                -- RENDER OPTIONS
                local function RenderList()
                    -- Cleanup old
                    for _, c in pairs(listFrame:GetChildren()) do
                        if c:IsA("Frame") then c:Destroy() end
                    end

                    for i, optName in ipairs(options) do
                        local item = Instance.new("Frame")
                        item.BackgroundTransparency = 1
                        item.Size = UDim2.new(1, 0, 0, 30)
                        item.Parent = listFrame

                        local btn = Instance.new("TextButton")
                        btn.Size = UDim2.new(1, 0, 1, 0)
                        btn.BackgroundTransparency = 0.95
                        -- Highlight if selected
                        local isSelected = (optName == currentOption)
                        btn.BackgroundColor3 = isSelected and Theme.Colors.AccentPrimary or Theme.Colors.TextPrimary
                        btn.Text = ""
                        btn.AutoButtonColor = false
                        btn.Parent = item
                        
                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(0, 4)
                        corner.Parent = btn

                        -- Radio/Check visual
                        local box = Instance.new("Frame")
                        box.Size = UDim2.new(0, 12, 0, 12)
                        box.Position = UDim2.new(0, 10, 0.5, -6)
                        box.BackgroundColor3 = isSelected and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight
                        box.BorderSizePixel = 0
                        box.Parent = btn
                        Instance.new("UICorner", box).CornerRadius = UDim.new(1, 0) -- Circle

                        -- Indication glow if selected
                        if isSelected then
                             local glow = Instance.new("UIStroke")
                             glow.Color = Theme.Colors.NeonCyan
                             glow.Thickness = 2
                             glow.Transparency = 0.5
                             glow.Parent = box
                        end

                        Utils:CreateText(btn, optName, {
                            TextSize = 12,
                            TextColor = isSelected and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary,
                            Position = UDim2.new(0, 32, 0, 0),
                            Size = UDim2.new(1, -32, 1, 0),
                            TextXAlignment = Enum.TextXAlignment.Left
                        })

                        -- Click Handle
                        btn.MouseButton1Click:Connect(function()
                            currentOption = optName
                            triggerBtn.Text = currentOption
                            
                            -- Save
                            if autoSave then
                                ConfigSystem.Data[configKey] = currentOption
                            end
                            callback(currentOption)
                            
                            -- Close Drawer
                            ToggleDrawer()
                            
                            -- Re-render list next time to update highlights? 
                            -- Or just force re-render now if we keep drawer open (which we don't)
                        end)
                    end
                    
                    listFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 35)
                end
                
                RenderList()
            end
            
            -- Re-parent to ensure it remains valid
            local windowFrame = container
            while windowFrame.Parent and not windowFrame.Parent:IsA("ScreenGui") do
                windowFrame = windowFrame.Parent
            end
            drawerFrame.Parent = windowFrame

            drawerFrame.Visible = true
            -- Force re-render list to ensure highlights are correct
           if drawerFrame:FindFirstChild("ScrollingFrame") then
                -- A bit hacky to trigger re-render, ideally we export RenderList. 
                -- We can just clear it and it will re-render next time or we can duplicate logic.
                -- For simplicity, we just clear children and the existing frame logic in `if not drawerFrame` handles creation, 
                -- BUT since drawerFrame persists, we need a way to refresh.
                -- Let's just create a `Refresh` function on the drawerFrame if possible or just rebuild list.
                -- Cleaner: Attach Refresh function to drawerFrame
                -- For now, let's just rebuild the UIList logic inside ToggleDrawer every time or make RenderList available.
                -- Since we are inside ToggleDrawer scope, let's just re-call RenderList if it existed? No, it's local.
                -- Let's clearing the listFrame children is easiest and just allow them to be recreated?
                -- BUT the creation logic is inside `if not drawerFrame`.
                -- So, if drawerFrame exists, we need to call RenderList.
                -- Solution: Move RenderList OUTSIDE the `if not drawerFrame` block.
           end
           
           -- Refactor: Moved RenderList definition up or define it here?
           -- Let's redefine RenderList here briefly or restructure above.
           -- Better: We will just destroy the drawerFrame list content and rebuild it.
           -- Wait, the `if not drawerFrame` block contains the RenderList function definition.
           -- We should move RenderList definition outside.
        end
    end
    
    -- REDEFINED TOGGLE DRAWER TO SUPPORT REFRESH
    ToggleDrawer = function()
         if drawerOpen then
            -- CLOSE
            if drawerFrame then
                Animator:Tween(drawerFrame, {
                    Position = UDim2.new(1, 0, 0, Theme.Sizes.TopbarHeight)
                }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
                    drawerFrame.Visible = false
                end)
            end
            drawerOpen = false
        else
            -- OPEN
            drawerOpen = true
            
            local windowFrame = container
            while windowFrame.Parent and not windowFrame.Parent:IsA("ScreenGui") do
                windowFrame = windowFrame.Parent
            end
            
            if not windowFrame or not windowFrame.Parent:IsA("ScreenGui") then return end

            if not drawerFrame then
                 -- Create Structure (Same as above)
                 local drawerWidth = Theme.Sizes.SidebarWidth + 30
                 drawerFrame = Utils:CreateGlassFrame(windowFrame, {
                    Color = Theme.Colors.Surface, Transparency = 0.05,
                    Size = UDim2.new(0, drawerWidth, 1, -Theme.Sizes.TopbarHeight),
                    Position = UDim2.new(1, 0, 0, Theme.Sizes.TopbarHeight),
                    CornerRadius = 0, StrokeColor = Theme.Colors.AccentPrimary,
                    StrokeTransparency = 0.5, ZIndex = 50 
                })
                if drawerFrame:FindFirstChild("UIStroke") then drawerFrame.UIStroke:Destroy() end
                
                local leftBorder = Instance.new("Frame")
                leftBorder.BackgroundColor3 = Theme.Colors.AccentPrimary
                leftBorder.Size = UDim2.new(0, 1, 1, 0)
                leftBorder.Position = UDim2.new(0, 0, 0, 0)
                leftBorder.BorderSizePixel = 0
                leftBorder.Parent = drawerFrame

                local header = Instance.new("Frame")
                header.BackgroundTransparency = 1
                header.Size = UDim2.new(1, 0, 0, 40)
                header.Parent = drawerFrame
                Utils:CreateText(header, title, {
                    Font = Theme.Fonts.Primary, TextSize = 14, TextColor = Theme.Colors.AccentPrimary,
                    Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 15, 0, 0), TextXAlignment = Enum.TextXAlignment.Left
                })
                local closeBtn = Instance.new("TextButton")
                closeBtn.Text = "✕"
                closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextColor3 = Theme.Colors.TextSecondary; closeBtn.TextSize = 16
                closeBtn.BackgroundTransparency = 1; closeBtn.Size = UDim2.new(0, 30, 0, 30)
                closeBtn.Position = UDim2.new(1, -35, 0.5, -15); closeBtn.Parent = header
                closeBtn.MouseButton1Click:Connect(function() ToggleDrawer() end)
                
                local listFrame = Instance.new("ScrollingFrame")
                listFrame.Name = "ListFrame"
                listFrame.BackgroundTransparency = 1; listFrame.Size = UDim2.new(1, 0, 1, -50)
                listFrame.Position = UDim2.new(0, 0, 0, 45); listFrame.ScrollBarThickness = 4
                listFrame.ScrollBarImageColor3 = Theme.Colors.AccentPrimary; listFrame.Parent = drawerFrame
                local listLayout = Instance.new("UIListLayout")
                listLayout.Padding = UDim.new(0, 5); listLayout.Parent = listFrame
                local listPadding = Instance.new("UIPadding")
                listPadding.PaddingLeft = UDim.new(0, 10); listPadding.PaddingRight = UDim.new(0, 10); listPadding.PaddingBottom = UDim.new(0, 10)
                listPadding.Parent = listFrame
            end
            
            -- REFRESH LIST CONTENT ALWAYS
            local listFrame = drawerFrame:FindFirstChild("ListFrame")
            if listFrame then
                for _, c in pairs(listFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                
                for i, optName in ipairs(options) do
                    local item = Instance.new("Frame")
                    item.BackgroundTransparency = 1; item.Size = UDim2.new(1, 0, 0, 30); item.Parent = listFrame
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 0.95
                    local isSelected = (optName == currentOption)
                    btn.BackgroundColor3 = isSelected and Theme.Colors.AccentPrimary or Theme.Colors.TextPrimary
                    btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = item
                    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 4); corner.Parent = btn
                    
                    local box = Instance.new("Frame")
                    box.Size = UDim2.new(0, 12, 0, 12); box.Position = UDim2.new(0, 10, 0.5, -6)
                    box.BackgroundColor3 = isSelected and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight
                    box.BorderSizePixel = 0; box.Parent = btn
                    Instance.new("UICorner", box).CornerRadius = UDim.new(1, 0)
                    
                    Utils:CreateText(btn, optName, {
                        TextSize = 12, TextColor = isSelected and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary,
                        Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, -32, 1, 0),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    
                    btn.MouseButton1Click:Connect(function()
                        currentOption = optName
                        triggerBtn.Text = currentOption
                        if autoSave then ConfigSystem.Data[configKey] = currentOption end
                        callback(currentOption)
                        ToggleDrawer()
                    end)
                end
                listFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 35)
            end

            drawerFrame.Parent = windowFrame
            drawerFrame.Visible = true
            Animator:Tween(drawerFrame, {
                Position = UDim2.new(1, -drawerFrame.Size.X.Offset, 0, Theme.Sizes.TopbarHeight)
            }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end

    triggerBtn.MouseButton1Click:Connect(function() ToggleDrawer() end)

    -- Hover Effects
    if not IsMobile then
        local stroke = buttonFrame:FindFirstChild("UIStroke")
        triggerBtn.MouseEnter:Connect(function()
            if stroke then Animator:Tween(stroke, {Transparency = 0.3, Color = Theme.Colors.NeonCyan}, Theme.Animations.Fast) end
        end)
        triggerBtn.MouseLeave:Connect(function()
            if stroke then Animator:Tween(stroke, {Transparency = 0.6, Color = Theme.Colors.AccentPrimary}, Theme.Animations.Fast) end
        end)
    end
    
    -- [NEW] Register to Config System
    if autoSave and configKey then
        ElementRegistry[configKey] = {
            Default = default, -- Store default
            Update = function(val)
                if table.find(options, val) then
                    currentOption = val
                    triggerBtn.Text = val
                    callback(val)
                end
            end
        }
    end

    -- Trigger Callback
    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        task.defer(function() callback(default) end)
    end

    return {
        Container = container,
        UpdateOptions = function(self, newOptions, newDefault)
            options = newOptions or options
            if newDefault and table.find(options, newDefault) then
                currentOption = newDefault
                triggerBtn.Text = newDefault
            elseif #options > 0 then
                currentOption = options[1]
                triggerBtn.Text = options[1]
            end
            
            -- If drawer open, refresh it
            if drawerOpen then
                ToggleDrawer() -- Close
                -- ToggleDrawer() -- Re-open? No, just close is better
            end
        end,
        Destroy = function(self)
            container:Destroy()
        end
    }
end


function Components:CreateSlider(parent, config)
    config = config or {}
    local title = config.Title or "Slider"
    local subtitle = config.Subtitle or ""
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local increment = config.Increment or 1
    local callback = config.Callback or function() end
    
    -- ✅ Config System Integration (Unique Key with Subtitle)
    local autoSave = config.AutoSave or false
    local configKey = "Slider_" .. (title:gsub("%s+", ""))
    if subtitle then
        configKey = configKey .. "_" .. (subtitle:gsub("%s+", ""))
    end

    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        default = ConfigSystem.Data[configKey]
    end

    -- ✅ Container TRANSPARAN
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(50, 55, 60)),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.8
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    -- ========== LEFT SIDE (Title + Subtitle) ==========
    local leftSide = Instance.new("Frame")
    leftSide.Name = "LeftSide"
    leftSide.BackgroundTransparency = 1
    leftSide.Size = UDim2.new(0.5, -Theme.Sizes.Padding, 1, 0)
    leftSide.Parent = container
    
    local titleLabel = Utils:CreateText(leftSide, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    
    if subtitle ~= "" then
        local subtitleLabel = Utils:CreateText(leftSide, subtitle, {
            Font = Theme.Fonts.Primary,
            TextSize = Theme.GetResponsiveSize(11, 12, 13),
            TextColor = Theme.Colors.TextSecondary,
            Size = UDim2.new(1, 0, 1, -22),
            Position = UDim2.new(0, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true
        })
    end
    
    -- ========== RIGHT SIDE (Slider + Value) ==========
    local rightSide = Instance.new("Frame")
    rightSide.Name = "RightSide"
    rightSide.BackgroundTransparency = 1
    rightSide.Size = UDim2.new(0.5, -Theme.Sizes.Padding, 1, 0)
    rightSide.Position = UDim2.new(0.5, Theme.Sizes.Padding, 0, 0)
    rightSide.Parent = container
    
    local valueLabel = Utils:CreateText(rightSide, tostring(default), {
        Font = Theme.Fonts.Mono,
        TextSize = Theme.GetResponsiveSize(12, 13, 14),
        TextColor = Theme.Colors.AccentPrimary,
        Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    
    -- ========== SLIDER CONTAINER ==========
    local sliderContainer = Instance.new("Frame")
    sliderContainer.BackgroundTransparency = 1
    sliderContainer.Size = UDim2.new(1, 0, 0, 20)
    sliderContainer.Position = UDim2.new(0, 0, 0.5, 0)
    sliderContainer.AnchorPoint = Vector2.new(0, 0.5)
    sliderContainer.Parent = rightSide
    
    -- ========== TRACK (Background) - tetep punya background ==========
    local sliderTrack = Utils:CreateGlassFrame(sliderContainer, {
        Color = Theme.Colors.Surface,
        Transparency = 0.5,
        Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(4, 5, 6)),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        CornerRadius = Theme.GetResponsiveSize(3, 3.5, 4),
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.85
    })
    
    -- ========== FILL (Progress) ==========
    local sliderFill = Instance.new("Frame")
    sliderFill.BackgroundColor3 = Theme.Colors.AccentPrimary
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.ZIndex = 2
    sliderFill.Parent = sliderTrack
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
    -- ========== KNOB (Handle) ==========
    local knobSize = Theme.GetResponsiveSize(10, 12, 14)
    local sliderKnob = Instance.new("Frame")
    sliderKnob.BackgroundColor3 = Theme.Colors.TextPrimary
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Size = UDim2.new(0, knobSize, 0, knobSize)
    sliderKnob.Position = UDim2.new((default - min) / (max - min), -knobSize/2, 0.5, -knobSize/2)
    sliderKnob.AnchorPoint = Vector2.new(0, 0.5)
    sliderKnob.ZIndex = 3
    sliderKnob.Parent = sliderTrack
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = sliderKnob
    
    local knobShadow = Instance.new("ImageLabel")
    knobShadow.Name = "Shadow"
    knobShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    knobShadow.ImageColor3 = Color3.new(0, 0, 0)
    knobShadow.ImageTransparency = 0.8
    knobShadow.BackgroundTransparency = 1
    knobShadow.Size = UDim2.new(1, 4, 1, 4)
    knobShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    knobShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    knobShadow.ZIndex = 2
    knobShadow.Parent = sliderKnob
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(1, 0)
    shadowCorner.Parent = knobShadow
    
    local currentValue = default
    local dragging = false
    local dragInput
    
    local function updateSlider(input)
        local relativeX = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
        local rawValue = min + (relativeX * (max - min))
        currentValue = math.floor(rawValue / increment + 0.5) * increment
        currentValue = math.clamp(currentValue, min, max)
        
        local percent = (currentValue - min) / (max - min)
        
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderKnob.Position = UDim2.new(percent, -knobSize/2, 0.5, -knobSize/2)
        valueLabel.Text = tostring(currentValue)
        
        callback(currentValue)
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
            
            Animator:Tween(sliderKnob, {
                Size = UDim2.new(0, knobSize + 3, 0, knobSize + 3)
            }, Theme.Animations.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            
            Animator:Tween(knobShadow, {
                ImageTransparency = 0.6
            }, Theme.Animations.Fast)
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    
                    -- ✅ Auto-Save (Update Data ONLY)
                    if autoSave then
                        ConfigSystem.Data[configKey] = currentValue
                        -- ConfigSystem:Save() -- Disabled for Manual Save
                    end

                    Animator:Tween(sliderKnob, {
                        Size = UDim2.new(0, knobSize, 0, knobSize)
                    }, Theme.Animations.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    
                    Animator:Tween(knobShadow, {
                        ImageTransparency = 0.8
                    }, Theme.Animations.Fast)
                end
            end)
        end
    end)
    
    sliderTrack.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateSlider(input)
        end
    end)
    
    if not IsMobile then
        sliderTrack.MouseEnter:Connect(function()
            if not dragging then
                Animator:Tween(sliderKnob, {
                    Size = UDim2.new(0, knobSize + 2, 0, knobSize + 2)
                }, Theme.Animations.Fast)
            end
        end)
        
        sliderTrack.MouseLeave:Connect(function()
            if not dragging then
                Animator:Tween(sliderKnob, {
                    Size = UDim2.new(0, knobSize, 0, knobSize)
                }, Theme.Animations.Fast)
            end
        end)
    end
    
    -- [NEW] Register to Config System
    if autoSave and configKey then
        ElementRegistry[configKey] = {
            Default = default, -- Store default
            Update = function(val)
                currentValue = math.clamp(val, min, max)
                local percent = (currentValue - min) / (max - min)

                sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                sliderKnob.Position = UDim2.new(percent, -knobSize / 2, 0.5, -knobSize / 2)
                valueLabel.Text = tostring(currentValue)

                callback(currentValue)
            end
        }
    end

    -- ✅ Trigger Callback if loaded from Config
    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        task.defer(function()
            callback(currentValue)
        end)
    end

    return container
end


function Components:CreateTextBox(parent, config)
    config = config or {}
    local title = config.Title or "TextBox"
    local subtitle = config.Subtitle or "Description"
    local placeholder = config.Placeholder or "Enter text..."
    local default = config.Default or ""
    local callback = config.Callback or function() end
    
    -- ✅ Config System Integration (Unique Key with Subtitle)
    local autoSave = config.AutoSave or false
    local configKey = "TextBox_" .. (title:gsub("%s+", ""))
    if subtitle then
        configKey = configKey .. "_" .. (subtitle:gsub("%s+", ""))
    end

    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        default = ConfigSystem.Data[configKey]
    end

    -- ✅ Main Container TRANSPARAN
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(55, 60, 65)),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    local headerContainer = Instance.new("Frame")
    headerContainer.BackgroundTransparency = 1
    headerContainer.Size = UDim2.new(1, 0, 1, 0)
    headerContainer.Parent = container
    
    -- Left Side: Title & Subtitle
    local leftSide = Instance.new("Frame")
    leftSide.BackgroundTransparency = 1
    leftSide.Size = UDim2.new(0.5, -5, 1, 0)
    leftSide.Position = UDim2.new(0, 0, 0, 0)
    leftSide.Parent = headerContainer
    
    local titleLabel = Utils:CreateText(leftSide, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(14, 15, 16),
        TextColor = Theme.Colors.TextPrimary,
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local subtitleLabel = Utils:CreateText(leftSide, subtitle, {
        Font = Theme.Fonts.Secondary,
        TextSize = Theme.GetResponsiveSize(11, 12, 13),
        TextColor = Theme.Colors.TextSecondary,
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 24),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Right Side: Input Box
    local rightSide = Instance.new("Frame")
    rightSide.BackgroundTransparency = 1
    rightSide.Size = UDim2.new(0.5, -5, 1, 0)
    rightSide.Position = UDim2.new(0.5, 5, 0, 0)
    rightSide.Parent = headerContainer
    
    -- ✅ Input Frame tetep punya background (interactable element)
    local inputFrame = Utils:CreateGlassFrame(rightSide, {
        Color = Theme.Colors.SurfaceLight,
        Transparency = 0.1,
        Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(28, 32, 36)),
        Position = UDim2.new(0, 0, 0.5, -Theme.GetResponsiveSize(18, 19, 20)),
        AnchorPoint = Vector2.new(0, 0.5),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.5
    })
    
    local textBox = Instance.new("TextBox")
    textBox.BackgroundTransparency = 1
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 10, 0, 0)
    textBox.Font = Theme.Fonts.Secondary
    textBox.TextSize = Theme.GetResponsiveSize(12, 13, 14)
    textBox.TextColor3 = Theme.Colors.TextPrimary
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = Theme.Colors.TextTertiary
    textBox.Text = default
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = 5
    textBox.Parent = inputFrame
    
    textBox.Focused:Connect(function()
        Animator:Tween(inputFrame, {
            BackgroundColor3 = Theme.Colors.Surface,
            StrokeColor = Theme.Colors.AccentPrimary,
            StrokeTransparency = 0.2
        }, Theme.Animations.Fast)
    end)
    
    textBox.FocusLost:Connect(function()
        -- ✅ Auto-Save (Update Data ONLY)
        if autoSave then
            ConfigSystem.Data[configKey] = textBox.Text
            -- ConfigSystem:Save() -- Disabled for Manual Save
        end

        Animator:Tween(inputFrame, {
            BackgroundColor3 = Theme.Colors.SurfaceLight,
            StrokeColor = Theme.Colors.Border,
            StrokeTransparency = 0.5
        }, Theme.Animations.Fast)
        callback(textBox.Text)
    end)
    
    -- [NEW] Register to Config System
    if autoSave and configKey then
        ElementRegistry[configKey] = {
            Default = default, -- Store default
            Update = function(val)
                textBox.Text = val
                callback(val)
            end
        }
    end

    -- ✅ Trigger Callback if loaded from Config
    if ConfigSystem.Data[configKey] ~= nil then
        task.defer(function()
            callback(textBox.Text)
        end)
    end

    return container, textBox
end


function Components:CreateLabel(parent, config)
    config = config or {}
    local title = config.Title or "Label"
    local subtitle = config.Subtitle
    
    -- ✅ Container TRANSPARAN
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = 1, -- ✅ FULLY TRANSPARENT (dulu: Theme.Transparency.Glass + 0.1)
        Size = UDim2.new(1, 0, 0, subtitle and Theme.GetResponsiveSize(40, 45, 50) or Theme.GetResponsiveSize(28, 30, 32)),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.8
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    Utils:CreateText(container, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Position = UDim2.new(0, 0, 0, subtitle and Theme.GetResponsiveSize(4, 5, 6) or 0),
        TextYAlignment = subtitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        TextScaled = IsMobile
    })
    
    if subtitle then
        Utils:CreateText(container, subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(22, 25, 28)),
            TextYAlignment = Enum.TextYAlignment.Top,
            TextScaled = IsMobile
        })
    end
    
    return container
end

function Components:CreateSection(parent, title)
    local sectionHeight = Theme.GetResponsiveSize(24, 26, 28)
    
    -- 📦 Container
    local container = Instance.new("Frame")
    container.Name = "Section_" .. title
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, sectionHeight)
    container.Parent = parent
    
    -- 📝 Section title dengan gradient (di tengah)
    local titleLabel = Utils:CreateText(container, title, {
        Font = Enum.Font.GothamBold,
        TextSize = Theme.GetResponsiveSize(14, 15, 16),
        TextColor = Color3.fromRGB(138, 43, 226), -- Base purple
        Size = UDim2.new(1, 0, 0.7, 0),
        Position = UDim2.new(0, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center
    })
    titleLabel.Name = "SectionTitle"
    
    -- 🎨 Gradient Purple → White
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)), -- Purple
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))   -- White
    })
    titleGradient.Parent = titleLabel
    
    -- Stroke purple untuk title
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Color = Color3.fromRGB(138, 43, 226)
    titleStroke.Transparency = 0.7
    titleStroke.Thickness = 1
    titleStroke.Parent = titleLabel
    
    -- ➖ Divider line dengan gradient (50% width, centered)
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Base purple
    divider.BackgroundTransparency = 0.3
    divider.BorderSizePixel = 0
    divider.Size = UDim2.new(0.5, 0, 0, Theme.GetResponsiveSize(3, 3, 4))
    divider.Position = UDim2.new(0.25, 0, 1, -Theme.GetResponsiveSize(4, 5, 6))
    divider.Parent = container
    
    -- Rounded corners untuk divider
    local dividerCorner = Instance.new("UICorner")
    dividerCorner.CornerRadius = UDim.new(1, 0)
    dividerCorner.Parent = divider
    
    -- 🎨 Gradient untuk divider
    local dividerGradient = Instance.new("UIGradient")
    dividerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)), -- Purple
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))   -- White
    })
    dividerGradient.Parent = divider
    
    return container
end

-- ========================================
-- NUMERIC INPUT COMPONENT untuk VyperUI V4.0
-- Layout: Title/Subtitle di KIRI, Input di KANAN
-- FREE INPUT: Bisa ketik angka bebas (0.87, 1.34, dst)
-- ========================================

function Components:CreateNumericInput(parent, config)
    config = config or {}
    local title = config.Title or "Numeric Input"
    local subtitle = config.Subtitle
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or 0
    local decimalPlaces = config.DecimalPlaces or 0
    local suffix = config.Suffix or ""
    local callback = config.Callback or function() end
    
    -- ✅ Config System Integration (Unique Key with Subtitle)
    local autoSave = config.AutoSave or false
    local configKey = "Numeric_" .. (title:gsub("%s+", ""))
    if subtitle then
        configKey = configKey .. "_" .. (subtitle:gsub("%s+", ""))
    end

    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        default = ConfigSystem.Data[configKey]
    end

    -- Clamp default value
    local value = math.clamp(default, min, max)
    
    -- Format number dengan decimal places
    local function formatNumber(num)
        if decimalPlaces == 0 then
            return tostring(math.floor(num))
        else
            return string.format("%." .. decimalPlaces .. "f", num)
        end
    end
    
    -- 🧱 Container utama (BACKGROUND TRANSPARAN PENUH)
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(1, 0, 0, subtitle and Theme.GetResponsiveSize(48, 52, 56) or Theme.Sizes.ButtonHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    -- LEFT SIDE: Text Container (Title + Subtitle)
    local textContainer = Instance.new("Frame")
    textContainer.BackgroundTransparency = 1
    textContainer.Size = UDim2.new(1, -Theme.GetResponsiveSize(130, 145, 160), 1, 0)
    textContainer.Position = UDim2.new(0, 0, 0, 0)
    textContainer.Parent = container
    
    -- Title Label
    Utils:CreateText(textContainer, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Position = UDim2.new(0, 0, 0, subtitle and Theme.GetResponsiveSize(3, 4, 5) or 0),
        TextYAlignment = subtitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 1, 0),
        -- TextScaled = IsMobile (REMOVED: Causes huge text on small screens)
    })
    
    -- Subtitle Label
    if subtitle then
        Utils:CreateText(textContainer, subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(20, 22, 24)),
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 1, 0),
            -- TextScaled = IsMobile (REMOVED)
        })
    end
    
    -- RIGHT SIDE: Input Container (TextBox only - NO BUTTONS)
    local inputWidth = Theme.GetResponsiveSize(100, 115, 130)
    local inputHeight = Theme.GetResponsiveSize(28, 32, 36)
    
    -- Input Frame - TRANSPARAN
    local inputFrame = Utils:CreateGlassFrame(container, {
        Color = Theme.Colors.SurfaceLight,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(0, inputWidth, 0, inputHeight),
        Position = UDim2.new(1, -inputWidth, 0.5, -inputHeight/2),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.AccentPrimary,
        StrokeTransparency = 0.8
    })
    
    Utils:CreatePadding(inputFrame, {
        Left = Theme.GetResponsiveSize(8, 10, 12),
        Right = Theme.GetResponsiveSize(8, 10, 12),
        Top = 0,
        Bottom = 0
    })
    
    -- TextBox untuk input manual (FREE INPUT - BEBAS)
    local textBox = Instance.new("TextBox")
    textBox.BackgroundTransparency = 1
    textBox.Size = UDim2.new(1, suffix ~= "" and -Theme.GetResponsiveSize(22, 24, 26) or 0, 1, 0)
    textBox.Font = Theme.Fonts.Primary
    textBox.TextSize = Theme.GetResponsiveSize(12, 13, 14)
    textBox.TextColor3 = Theme.Colors.TextPrimary
    textBox.PlaceholderText = formatNumber(value)
    textBox.PlaceholderColor3 = Theme.Colors.TextTertiary
    textBox.Text = formatNumber(value)
    textBox.TextXAlignment = Enum.TextXAlignment.Center
    textBox.TextYAlignment = Enum.TextYAlignment.Center
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = 5
    textBox.Parent = inputFrame
    
    -- Suffix Label (jika ada)
    local suffixLabel
    if suffix ~= "" then
        suffixLabel = Utils:CreateText(inputFrame, suffix, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(1, -Theme.GetResponsiveSize(22, 24, 26), 0, 0),
            Size = UDim2.new(0, Theme.GetResponsiveSize(22, 24, 26), 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Center
        })
    end
    
    -- Update value function (FULLY FREE INPUT - BEBAS DECIMAL)
    local function updateValue(newValue)
        newValue = tonumber(newValue) or value
        newValue = math.clamp(newValue, min, max)
        
        value = newValue
        textBox.Text = tostring(value) -- Display as-is, no formatting
        callback(value)
    end
    
    -- TextBox Manual Input (FULLY FREE - User bisa input angka apapun)
    textBox.FocusLost:Connect(function(enterPressed)
        local inputText = textBox.Text
        local numValue = tonumber(inputText)
        
        if numValue then
            -- ✅ Auto-Save (Update Data ONLY)
            if autoSave then
                ConfigSystem.Data[configKey] = numValue
                -- ConfigSystem:Save() -- Disabled for Manual Save
            end
            
            updateValue(numValue)
        else
            -- Jika input invalid, kembalikan ke value terakhir
            textBox.Text = tostring(value)
        end
        
        -- Reset stroke color
        local stroke = inputFrame:FindFirstChildOfClass("UIStroke")
        if stroke then
            Animator:Tween(stroke, {Transparency = 0.8, Color = Theme.Colors.AccentPrimary}, Theme.Animations.Fast)
        end
    end)
    
    textBox.Focused:Connect(function()
        -- Highlight stroke saat focus
        local stroke = inputFrame:FindFirstChildOfClass("UIStroke")
        if stroke then
            Animator:Tween(stroke, {Transparency = 0.3, Color = Theme.Colors.NeonCyan}, Theme.Animations.Fast)
        end
    end)
    
    -- 🌈 Hover Effects (Desktop only) - ANIMASI BORDER
    if not IsMobile then
        local containerStroke = container:FindFirstChildOfClass("UIStroke")
        if containerStroke then
            container.MouseEnter:Connect(function()
                Animator:Tween(containerStroke, {Transparency = 0.3, Color = Theme.Colors.AccentPrimary}, Theme.Animations.Fast)
            end)
            
            container.MouseLeave:Connect(function()
                Animator:Tween(containerStroke, {Transparency = 0.7, Color = Theme.Colors.Border}, Theme.Animations.Fast)
            end)
        end
    end
    
    -- [NEW] Register to Config System
    if autoSave and configKey then
        ElementRegistry[configKey] = {
            Default = default, -- Store default
            Update = function(val)
                updateValue(val)
            end
        }
    end

    -- ✅ Trigger Callback if loaded from Config
    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        task.defer(function()
            callback(value)
        end)
    end

    return container
end

-- ========================================
-- COLLAPSIBLE SECTION V2.0 - VyperUI V4.0
-- Ultra-Modern Glassmorphic Accordion
-- Fully Compatible with VyperUI Neon Theme
-- ========================================

function Components:CreateCollapsibleSection(parent, config)
    config = config or {}
    local title = config.Title or "Section"
    local defaultExpanded = config.DefaultExpanded or false
    local accentColor = config.AccentColor or Theme.Colors.AccentPrimary
    
    local isExpanded = defaultExpanded
    local headerHeight = Theme.GetResponsiveSize(48, 52, 56)
    
    -- ========== MAIN CONTAINER (BACKGROUND TRANSPARAN PENUH) ==========
    local sectionContainer = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.GlassMid,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(1, 0, 0, headerHeight),
        CornerRadius = Theme.Sizes.CornerRadius,
        StrokeColor = accentColor,
        StrokeTransparency = 0.7
    })
    sectionContainer.Name = "CollapsibleSection_" .. title
    sectionContainer.ClipsDescendants = false
    
    -- ========== HEADER AREA ==========
    local headerArea = Instance.new("Frame")
    headerArea.Name = "HeaderArea"
    headerArea.BackgroundTransparency = 1
    headerArea.Size = UDim2.new(1, 0, 0, headerHeight)
    headerArea.Parent = sectionContainer
    
    Utils:CreatePadding(headerArea, {
        Left = Theme.Sizes.Padding,
        Right = Theme.Sizes.Padding,
        Top = Theme.Sizes.PaddingSmall,
        Bottom = Theme.Sizes.PaddingSmall
    })
    
    -- ========== ARROW ICON ==========
    local arrowIcon = Utils:CreateIcon(headerArea, "▶", {
        Size = Theme.GetResponsiveSize(14, 16, 18),
        Color = accentColor,
        Position = UDim2.new(0, 0, 0.5, -Theme.GetResponsiveSize(7, 8, 9))
    })
    arrowIcon.Name = "ArrowIcon"
    arrowIcon.Rotation = defaultExpanded and 90 or 0
    
    -- ========== TITLE TEXT ==========
    local titleLabel = Utils:CreateText(headerArea, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Position = UDim2.new(0, Theme.GetResponsiveSize(28, 32, 36), 0, 0),
        Size = UDim2.new(1, -Theme.GetResponsiveSize(56, 64, 72), 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    })
    
    -- ========== ITEM COUNTER BADGE (TRANSPARAN) ==========
    local itemBadge = Utils:CreateGlassFrame(headerArea, {
        Color = accentColor,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(0, Theme.GetResponsiveSize(28, 30, 32), 0, Theme.GetResponsiveSize(22, 24, 26)),
        Position = UDim2.new(1, -Theme.GetResponsiveSize(34, 38, 42), 0.5, -Theme.GetResponsiveSize(11, 12, 13)),
        CornerRadius = Theme.GetResponsiveSize(11, 12, 13),
        StrokeColor = accentColor,
        StrokeTransparency = 0.4
    })
    itemBadge.Name = "ItemBadge"
    itemBadge.Visible = false
    
    local badgeText = Utils:CreateText(itemBadge, "0", {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(10, 11, 12),
        TextColor = Theme.Colors.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center
    })
    badgeText.Name = "BadgeCount"
    
    -- ========== HEADER BUTTON ==========
    local headerButton = Instance.new("TextButton")
    headerButton.Size = UDim2.new(1, 0, 1, 0)
    headerButton.BackgroundTransparency = 1
    headerButton.Text = ""
    headerButton.ZIndex = 10
    headerButton.Parent = headerArea
    
    -- ========== CONTENT WRAPPER (DALAM CONTAINER YANG SAMA) ==========
    local contentWrapper = Instance.new("Frame")
    contentWrapper.Name = "ContentWrapper"
    contentWrapper.BackgroundTransparency = 1
    contentWrapper.Size = UDim2.new(1, 0, 0, 0)
    contentWrapper.Position = UDim2.new(0, 0, 0, headerHeight)
    contentWrapper.ClipsDescendants = true
    contentWrapper.Visible = defaultExpanded
    contentWrapper.Parent = sectionContainer
    
    -- ========== SCROLLING FRAME ==========
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.Size = UDim2.new(1, -Theme.Sizes.Padding * 2, 1, -Theme.Sizes.Padding)
    contentFrame.Position = UDim2.new(0, Theme.Sizes.Padding, 0, 0)
    contentFrame.ScrollBarThickness = 3
    contentFrame.ScrollBarImageColor3 = accentColor
    contentFrame.ScrollBarImageTransparency = 0.5
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.ZIndex = 5
    contentFrame.Parent = contentWrapper
    
    -- List Layout
    local contentList = Utils:CreateListLayout(contentFrame, {
        Padding = Theme.Sizes.Spacing,
        HorizontalAlignment = Enum.HorizontalAlignment.Left
    })
    
    Utils:CreatePadding(contentFrame, {
        Left = Theme.Sizes.PaddingSmall,
        Right = Theme.Sizes.PaddingSmall,
        Top = Theme.Sizes.PaddingSmall,
        Bottom = Theme.Sizes.PaddingSmall
    })
    
    -- ========== DIVIDER LINE (PEMISAH HEADER & CONTENT) ==========
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.BackgroundColor3 = accentColor
    divider.BackgroundTransparency = 0.8
    divider.BorderSizePixel = 0
    divider.Size = UDim2.new(1, -Theme.Sizes.Padding * 2, 0, 1)
    divider.Position = UDim2.new(0, Theme.Sizes.Padding, 0, headerHeight - 1)
    divider.Visible = defaultExpanded
    divider.Parent = sectionContainer
    
    -- ========== ITEM COUNTER ==========
    local function updateItemBadge()
        local itemCount = #contentFrame:GetChildren() - 2
        if itemCount > 0 then
            badgeText.Text = tostring(itemCount)
            itemBadge.Visible = true
        else
            itemBadge.Visible = false
        end
    end
    
    contentFrame.ChildAdded:Connect(updateItemBadge)
    contentFrame.ChildRemoved:Connect(updateItemBadge)
    
    -- ========== TOGGLE ANIMATION (SATU CONTAINER MEMANJANG) ==========
    local function toggleSection()
        isExpanded = not isExpanded
        
        -- Arrow rotation
        Animator:Tween(arrowIcon, {
            Rotation = isExpanded and 90 or 0
        }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        if isExpanded then
            -- EXPAND - Container memanjang ke bawah
            contentWrapper.Visible = true
            divider.Visible = true
            
            task.wait(0.05)
            
            -- Calculate content height
            local contentCanvasHeight = contentList.AbsoluteContentSize.Y 
                + (Theme.Sizes.PaddingSmall * 2) 
                + Theme.Sizes.Padding
            
            local maxHeight = Theme.GetResponsiveSize(280, 320, 360)
            local displayHeight = math.min(contentCanvasHeight, maxHeight)
            
            -- Expand content wrapper
            Animator:Tween(contentWrapper, {
                Size = UDim2.new(1, 0, 0, displayHeight)
            }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            
            -- Expand MAIN container (seamless)
            local totalHeight = headerHeight + displayHeight
            Animator:Tween(sectionContainer, {
                Size = UDim2.new(1, 0, 0, totalHeight)
            }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        else
            -- COLLAPSE - Container menyusut
            divider.Visible = false
            
            Animator:Tween(contentWrapper, {
                Size = UDim2.new(1, 0, 0, 0)
            }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
                contentWrapper.Visible = false
            end)
            
            Animator:Tween(sectionContainer, {
                Size = UDim2.new(1, 0, 0, headerHeight)
            }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end
    
    -- ========== CLICK HANDLER ==========
    headerButton.MouseButton1Click:Connect(toggleSection)
    
    -- 🌈 HOVER - ANIMASI BORDER AJA (BACKGROUND TETEP TRANSPARAN)
    if not IsMobile then
        local stroke = sectionContainer:FindFirstChildOfClass("UIStroke")
        if stroke then
            headerButton.MouseEnter:Connect(function()
                Animator:Tween(stroke, {
                    Transparency = 0.3,
                    Color = accentColor
                }, Theme.Animations.Fast)
            end)
            
            headerButton.MouseLeave:Connect(function()
                Animator:Tween(stroke, {
                    Transparency = 0.7,
                    Color = accentColor
                }, Theme.Animations.Fast)
            end)
        end
    end
    
    -- ========== AUTO-EXPAND IF DEFAULT ==========
    if defaultExpanded then
        task.defer(function()
            task.wait(0.15)
            
            local contentCanvasHeight = contentList.AbsoluteContentSize.Y 
                + (Theme.Sizes.PaddingSmall * 2) 
                + Theme.Sizes.Padding
            
            local maxHeight = Theme.GetResponsiveSize(280, 320, 360)
            local displayHeight = math.min(contentCanvasHeight, maxHeight)
            
            contentWrapper.Size = UDim2.new(1, 0, 0, displayHeight)
            
            local totalHeight = headerHeight + displayHeight
            sectionContainer.Size = UDim2.new(1, 0, 0, totalHeight)
        end)
    end

    return contentFrame
end




function Components:CreateTextParagraph(parent, config)
    config = config or {}
    local title = config.Title or "Information"
    local content = config.Content or "No content provided"
    local lines = config.Lines or {} -- Array of lines untuk multi-line
    
    -- Auto height calculation based on content
    local lineHeight = Theme.GetResponsiveSize(16, 17, 18)
    local numLines = #lines > 0 and #lines or 1
    local contentHeight = (numLines * lineHeight) + Theme.GetResponsiveSize(8, 10, 12)
    local totalHeight = Theme.GetResponsiveSize(32, 34, 36) + contentHeight
    
    -- 🧱 Main Container (BACKGROUND TRANSPARAN PENUH)
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = 1, -- ✅ FULLY TRANSPARENT
        Size = UDim2.new(1, 0, 0, totalHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    -- Title Section
    local titleLabel = Utils:CreateText(container, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(14, 15, 16),
        TextColor = Theme.Colors.TextPrimary,
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Content Container (Scrollable for long text)
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.BackgroundTransparency = 1
    contentContainer.Size = UDim2.new(1, 0, 1, -28)
    contentContainer.Position = UDim2.new(0, 0, 0, 22)
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
    contentContainer.ScrollBarThickness = 4
    contentContainer.ScrollBarImageColor3 = Theme.Colors.AccentPrimary
    contentContainer.BorderSizePixel = 0
    contentContainer.Parent = container
    
    -- If using Lines array (for multiple lines)
    if #lines > 0 then
        for i, line in ipairs(lines) do
            local lineLabel = Utils:CreateText(contentContainer, line, {
                Font = Theme.Fonts.Secondary,
                TextSize = Theme.GetResponsiveSize(12, 13, 14),
                TextColor = Theme.Colors.TextSecondary,
                Size = UDim2.new(1, -10, 0, lineHeight),
                Position = UDim2.new(0, 0, 0, (i - 1) * lineHeight),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top
            })
        end
    else
        -- Single content text
        local contentLabel = Utils:CreateText(contentContainer, content, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(12, 13, 14),
            TextColor = Theme.Colors.TextSecondary,
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true
        })
    end
    
    -- 🌈 Hover effect (Desktop only) - ANIMASI BORDER AJA
    if not IsMobile then
        local stroke = container:FindFirstChildOfClass("UIStroke")
        if stroke then
            local hoverConnection, leaveConnection
            
            hoverConnection = container.MouseEnter:Connect(function()
                Animator:Tween(stroke, {
                    Transparency = 0.3,
                    Color = Theme.Colors.AccentPrimary
                }, Theme.Animations.Fast)
            end)
            
            leaveConnection = container.MouseLeave:Connect(function()
                Animator:Tween(stroke, {
                    Transparency = 0.7,
                    Color = Theme.Colors.Border
                }, Theme.Animations.Fast)
            end)
        end
    end
    
    return container
end

function Components:CreateMultiDropdown(parent, config)
    config = config or {}
    local title = config.Title or "Multi Dropdown"
    local subtitle = config.Subtitle
    local options = config.Options or {"Option 1", "Option 2", "Option 3"}
    local default = config.Default or {}
    local callback = config.Callback or function() end

    -- ✅ Config System Integration
    local autoSave = config.AutoSave or false
    local configKey = "Multi_" .. (title:gsub("%s+", ""))
    if subtitle then
        configKey = configKey .. "_" .. (subtitle:gsub("%s+", ""))
    end

    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        default = ConfigSystem.Data[configKey]
    end

    -- Selected items tracking
    local selectedItems = {}
    local function SyncSelectedFromList(list)
        selectedItems = {}
        for _, item in ipairs(list) do
            selectedItems[item] = true
        end
    end
    SyncSelectedFromList(default)

    -- 🧱 Main Container
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = 1,
        Size = UDim2.new(1, 0, 0, subtitle and Theme.GetResponsiveSize(48, 52, 56) or Theme.Sizes.ButtonHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)

    -- LEFT SIDE: Text
    local textContainer = Instance.new("Frame")
    textContainer.BackgroundTransparency = 1
    textContainer.Size = UDim2.new(1, -Theme.GetResponsiveSize(130, 145, 160), 1, 0)
    textContainer.Position = UDim2.new(0, 0, 0, 0)
    textContainer.Parent = container
    
    Utils:CreateText(textContainer, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Position = UDim2.new(0, 0, 0, subtitle and Theme.GetResponsiveSize(3, 4, 5) or 0),
        TextYAlignment = subtitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 1, 0)
    })
    
    if subtitle then
        Utils:CreateText(textContainer, subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(20, 22, 24)),
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 1, 0)
        })
    end

    -- RIGHT SIDE: Button
    local buttonWidth = Theme.GetResponsiveSize(120, 135, 150)
    local buttonHeight = Theme.GetResponsiveSize(28, 32, 36)

    local buttonFrame = Utils:CreateGlassFrame(container, {
        Color = Theme.Colors.SurfaceLight,
        Transparency = 1,
        Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
        Position = UDim2.new(1, -buttonWidth, 0.5, -buttonHeight/2),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.AccentPrimary,
        StrokeTransparency = 0.6
    })

    local function GetDisplayText()
        local selected = {}
        for item, isSelected in pairs(selectedItems) do
            if isSelected then table.insert(selected, item) end
        end
        
        if #selected == 0 then return "Select options..."
        elseif #selected == 1 then return selected[1]
        elseif #selected == 2 then return selected[1] .. ", " .. selected[2]
        else return selected[1] .. ", " .. selected[2] .. " (+" .. (#selected - 2) .. ")" end
    end

    local triggerBtn = Instance.new("TextButton")
    triggerBtn.Size = UDim2.new(1, 0, 1, 0)
    triggerBtn.BackgroundTransparency = 1
    triggerBtn.Text = GetDisplayText()
    triggerBtn.Font = Theme.Fonts.Secondary
    triggerBtn.TextSize = Theme.GetResponsiveSize(11, 12, 13)
    triggerBtn.TextColor3 = Theme.Colors.TextPrimary
    triggerBtn.TextTruncate = Enum.TextTruncate.AtEnd
    triggerBtn.Parent = buttonFrame

    -- Icon Chevron Right (indicate opening right drawer)
    local icon = Instance.new("TextLabel")
    icon.Text = "▶" -- Changed to Right facing
    icon.BackgroundTransparency = 1
    icon.TextColor3 = Theme.Colors.AccentPrimary
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = Theme.GetResponsiveSize(10, 11, 12)
    icon.Size = UDim2.new(0, 15, 1, 0)
    icon.Position = UDim2.new(1, -20, 0, 0) -- Moved to Right
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Parent = buttonFrame

    -- =========================================================
    -- RIGHT SIDE DRAWER LOGIC (ATTACHED TO WINDOW)
    -- =========================================================
    
    local drawerOpen = false
    local drawerFrame 

    local function ToggleDrawer()
        if drawerOpen then
            -- CLOSE DRAWER (Slide Out Right)
            if drawerFrame then
                Animator:Tween(drawerFrame, {
                    Position = UDim2.new(1, 0, 0, Theme.Sizes.TopbarHeight)
                }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
                    drawerFrame.Visible = false
                end)
            end
            drawerOpen = false
        else
            -- OPEN DRAWER
            drawerOpen = true
            
            -- FIX 1: Find Window MAINFRAME (Ancestor below ScreenGui)
            local windowFrame = container
            while windowFrame.Parent and not windowFrame.Parent:IsA("ScreenGui") do
                windowFrame = windowFrame.Parent
            end
            
            -- Fallback check
            if not windowFrame or not windowFrame.Parent:IsA("ScreenGui") then
                -- Backup: try to find by Name pattern if traversal failed (rare)
                -- But traversal should work for WyperUI structure
                warn("VyperUI: Could not find Window Frame for Drawer")
                return 
            end

            -- Create Drawer if not exists
            if not drawerFrame then
                local drawerWidth = Theme.Sizes.SidebarWidth + 30
                
                drawerFrame = Utils:CreateGlassFrame(windowFrame, {
                    Color = Theme.Colors.Surface,
                    Transparency = 0.05,
                    Size = UDim2.new(0, drawerWidth, 1, -Theme.Sizes.TopbarHeight),
                    Position = UDim2.new(1, 0, 0, Theme.Sizes.TopbarHeight), -- Start Hidden Right
                    CornerRadius = 0,
                    StrokeColor = Theme.Colors.AccentPrimary,
                    StrokeTransparency = 0.5,
                    ZIndex = 50 -- On Top of content
                })
                
                -- Fix border (Left Side now)
                if drawerFrame:FindFirstChild("UIStroke") then drawerFrame.UIStroke:Destroy() end
                
                local leftBorder = Instance.new("Frame")
                leftBorder.BackgroundColor3 = Theme.Colors.AccentPrimary
                leftBorder.Size = UDim2.new(0, 1, 1, 0)
                leftBorder.Position = UDim2.new(0, 0, 0, 0) -- Left side
                leftBorder.BorderSizePixel = 0
                leftBorder.Parent = drawerFrame

                -- HEADER
                local header = Instance.new("Frame")
                header.BackgroundTransparency = 1
                header.Size = UDim2.new(1, 0, 0, 40)
                header.Parent = drawerFrame
                
                Utils:CreateText(header, title, {
                    Font = Theme.Fonts.Primary,
                    TextSize = Theme.GetResponsiveSize(14, 15, 16),
                    TextColor = Theme.Colors.AccentPrimary,
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 15, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                -- Close Button
                local closeBtn = Instance.new("TextButton")
                closeBtn.Text = "✕"
                closeBtn.Font = Enum.Font.GothamBold
                closeBtn.TextColor3 = Theme.Colors.TextSecondary
                closeBtn.TextSize = 16
                closeBtn.BackgroundTransparency = 1
                closeBtn.Size = UDim2.new(0, 30, 0, 30)
                closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
                closeBtn.Parent = header
                closeBtn.MouseButton1Click:Connect(ToggleDrawer)

                -- SCROLLING LIST
                local listFrame = Instance.new("ScrollingFrame")
                listFrame.BackgroundTransparency = 1
                listFrame.Size = UDim2.new(1, 0, 1, -50)
                listFrame.Position = UDim2.new(0, 0, 0, 45)
                listFrame.ScrollBarThickness = 4
                listFrame.ScrollBarImageColor3 = Theme.Colors.AccentPrimary
                listFrame.Parent = drawerFrame
                
                local listLayout = Instance.new("UIListLayout")
                listLayout.Padding = UDim.new(0, 5)
                listLayout.Parent = listFrame
                
                local listPadding = Instance.new("UIPadding")
                listPadding.PaddingLeft = UDim.new(0, 10)
                listPadding.PaddingRight = UDim.new(0, 10)
                listPadding.PaddingBottom = UDim.new(0, 10)
                listPadding.Parent = listFrame

                -- RENDER OPTIONS
                local function RenderList()
                    for _, c in pairs(listFrame:GetChildren()) do
                        if c:IsA("Frame") then c:Destroy() end
                    end

                    for i, optName in ipairs(options) do
                        local item = Instance.new("Frame")
                        item.BackgroundTransparency = 1
                        item.Size = UDim2.new(1, 0, 0, 30)
                        item.Parent = listFrame

                        local btn = Instance.new("TextButton")
                        btn.Size = UDim2.new(1, 0, 1, 0)
                        btn.BackgroundTransparency = 0.95
                        btn.BackgroundColor3 = selectedItems[optName] and Theme.Colors.AccentPrimary or Theme.Colors.TextPrimary
                        btn.Text = ""
                        btn.AutoButtonColor = false
                        btn.Parent = item
                        
                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(0, 4)
                        corner.Parent = btn

                        local box = Instance.new("Frame")
                        box.Size = UDim2.new(0, 16, 0, 16)
                        box.Position = UDim2.new(0, 8, 0.5, -8)
                        box.BackgroundColor3 = selectedItems[optName] and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight
                        box.BorderSizePixel = 0
                        box.Parent = btn
                        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

                        if selectedItems[optName] then
                            local check = Instance.new("TextLabel")
                            check.Text = "✓"
                            check.Font = Enum.Font.GothamBold
                            check.TextColor3 = Theme.Colors.TextPrimary
                            check.TextSize = 12
                            check.BackgroundTransparency = 1
                            check.Size = UDim2.new(1, 0, 1, 0)
                            check.Parent = box
                        end

                        Utils:CreateText(btn, optName, {
                            TextSize = 12,
                            TextColor = selectedItems[optName] and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary,
                            Position = UDim2.new(0, 32, 0, 0),
                            Size = UDim2.new(1, -32, 1, 0),
                            TextXAlignment = Enum.TextXAlignment.Left
                        })

                        btn.MouseButton1Click:Connect(function()
                            if selectedItems[optName] then selectedItems[optName] = nil
                            else selectedItems[optName] = true end

                            -- Update Visuals (Optimized)
                            box.BackgroundColor3 = selectedItems[optName] and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight
                            btn.BackgroundColor3 = selectedItems[optName] and Theme.Colors.AccentPrimary or Theme.Colors.TextPrimary
                            btn:FindFirstChild("TextLabel").TextColor3 = selectedItems[optName] and Theme.Colors.TextPrimary or Theme.Colors.TextSecondary
                            box:ClearAllChildren()
                            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
                            
                            if selectedItems[optName] then
                                local check = Instance.new("TextLabel")
                                check.Text = "✓"
                                check.Font = Enum.Font.GothamBold
                                check.TextColor3 = Theme.Colors.TextPrimary
                                check.TextSize = 12
                                check.BackgroundTransparency = 1
                                check.Size = UDim2.new(1, 0, 1, 0)
                                check.Parent = box
                            end
                            
                            triggerBtn.Text = GetDisplayText()
                            
                            local resultList = {}
                            for k, v in pairs(selectedItems) do if v then table.insert(resultList, k) end end
                            
                            if autoSave then ConfigSystem.Data[configKey] = resultList end
                            callback(resultList)
                        end)
                    end
                    listFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 35)
                end
                RenderList()
            end
            
            -- Ensure Parent is WindowFrame
            local windowFrame = container
            while windowFrame.Parent and not windowFrame.Parent:IsA("ScreenGui") do
                windowFrame = windowFrame.Parent
            end
            drawerFrame.Parent = windowFrame

            drawerFrame.Visible = true
            -- Slide In from Right
            Animator:Tween(drawerFrame, {
                Position = UDim2.new(1, -drawerFrame.Size.X.Offset, 0, Theme.Sizes.TopbarHeight)
            }, Theme.Animations.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end

    triggerBtn.MouseButton1Click:Connect(ToggleDrawer)

    -- Hover Effects
    if not IsMobile then
        local stroke = buttonFrame:FindFirstChild("UIStroke")
        triggerBtn.MouseEnter:Connect(function()
            if stroke then Animator:Tween(stroke, {Transparency = 0.3, Color = Theme.Colors.NeonCyan}, Theme.Animations.Fast) end
        end)
        triggerBtn.MouseLeave:Connect(function()
            if stroke then Animator:Tween(stroke, {Transparency = 0.6, Color = Theme.Colors.AccentPrimary}, Theme.Animations.Fast) end
        end)
    end
    
    if autoSave and configKey then
        ElementRegistry[configKey] = {
            Default = default,
            Update = function(val)
                SyncSelectedFromList(val)
                triggerBtn.Text = GetDisplayText()
                callback(val)
            end
        }
    end

    if autoSave and ConfigSystem.Data[configKey] ~= nil then
        task.defer(function()
            local list = {}
            for k,v in pairs(selectedItems) do if v then table.insert(list, k) end end
            callback(list)
        end)
    end

    return {
        Container = container,
        UpdateOptions = function(self, newOptions, newDefault)
            options = newOptions or options
            if newDefault then SyncSelectedFromList(newDefault) end
            triggerBtn.Text = GetDisplayText()
            if drawerOpen and drawerFrame then
               -- Force close to refresh next time
               drawerOpen = false 
               drawerFrame.Visible = false
               if drawerFrame:FindFirstChild("ScrollingFrame") then drawerFrame.ScrollingFrame:ClearAllChildren() end
            end
        end
    }
end


-- ========================================
-- ADD TO VyperUI MAIN LIBRARY
-- ========================================


-- ========================================
-- MAIN LIBRARY V4.0
-- ========================================

local VyperUI = {}

function VyperUI:CreateWindow(config)
    return Window.new(config)
end

function VyperUI:CreateButton(parent, config)
    return Components:CreateButton(parent, config)
end

function VyperUI:CreateToggle(parent, config)
    return Components:CreateToggle(parent, config)
end

function VyperUI:CreateDropdown(parent, config)
    return Components:CreateDropdown(parent, config)
end



function VyperUI:CreateSlider(parent, config)
    return Components:CreateSlider(parent, config)
end

function VyperUI:CreateTextBox(parent, config)
    return Components:CreateTextBox(parent, config)
end

function VyperUI:CreateLabel(parent, config)
    return Components:CreateLabel(parent, config)
end

function VyperUI:CreateSection(parent, title)
    return Components:CreateSection(parent, title)
end


function VyperUI:CreateNumericInput(parent, config)
    return Components:CreateNumericInput(parent, config)
end

function VyperUI:CreateCollapsibleSection(parent, config)
    return Components:CreateCollapsibleSection(parent, config)
end

function VyperUI:CreateTextParagraph(parent, config)
    return Components:CreateTextParagraph(parent, config)
end

function VyperUI:CreateMultiDropdown(parent, config)
    return Components:CreateMultiDropdown(parent, config)
end

getgenv().VyperUI = VyperUI
_G.VyperUI = VyperUI
VyperUI.ConfigSystem = ConfigSystem -- [NEW] Expose ConfigSystem
VyperUI.Theme = Theme -- [NEW] Expose Theme for external use

print([[
═══════════════════════════════════════════════════════════════
  ██╗   ██╗██╗   ██╗██████╗ ███████╗██████╗     ██╗   ██╗██╗  ██╗
  ██║   ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗    ██║   ██║██║  ██║
  ██║   ██║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝    ██║   ██║███████║
  ╚██╗ ██╔╝  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗    ██║   ██║╚════██║
   ╚████╔╝    ██║   ██║     ███████╗██║  ██║    ╚██████╔╝     ██║
    ╚═══╝     ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝     ╚═════╝      ╚═╝
                                                                   
  VyperUI V4.0 FINAL - Delta Executor Edition
  ✅ Library loaded successfully!
  
  ✨ Features:
  ✓ 100% Responsive Design
  ✓ Hide/Show Toggle Button (Topbar center)
  ✓ Collapsible Sidebar (Slide animation)
  ✓ Minimize to Draggable Logo (Bottom left)
  ✓ Smooth Animations (Spring, fade, bounce, slide)
  ✓ Delta Executor Compatible
  
  📝 Usage:
  local Window = VyperUI:CreateWindow({Title = "My UI"})
  local Tab = Window:CreateTab({Title = "Home", Icon = "🏠"})
  VyperUI:CreateButton(Tab, {Title = "Button", Callback = function() end})
  
  Author: yeremiaginting059
  Version: 4.0.0 - FINAL RELEASE
═══════════════════════════════════════════════════════════════
]])

return VyperUI
