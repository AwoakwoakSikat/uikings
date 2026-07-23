--[[
    ██╗   ██╗██╗   ██╗██████╗ ███████╗██████╗   
    ██║   ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗   
    ██║   ██║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝  
    ╚██╗ ██╔╝  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗   
     ╚████╔╝    ██║   ██║     ███████╗██║  ██║   
      ╚═══╝     ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝   

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
-- MODERN GLASSMORPHIC THEME V4.0
-- ========================================

local Theme = {
    Colors = {
        NeonPurple = Color3.fromRGB(138, 43, 226),
        NeonCyan = Color3.fromRGB(0, 255, 255),
        NeonPink = Color3.fromRGB(255, 20, 147),
        NeonBlue = Color3.fromRGB(64, 156, 255),
        NeonGreen = Color3.fromRGB(57, 255, 20),
        
        GlassLight = Color3.fromRGB(255, 255, 255),
        GlassDark = Color3.fromRGB(15, 15, 25),
        GlassMid = Color3.fromRGB(25, 25, 40),
        
        Background = Color3.fromRGB(10, 10, 18),
        BackgroundSecondary = Color3.fromRGB(15, 15, 25),
        Surface = Color3.fromRGB(20, 20, 32),
        SurfaceLight = Color3.fromRGB(30, 30, 48),
        
        TextPrimary = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 200),
        TextTertiary = Color3.fromRGB(120, 120, 140),
        TextDisabled = Color3.fromRGB(80, 80, 100),
        
        AccentPrimary = Color3.fromRGB(138, 43, 226),
        AccentSecondary = Color3.fromRGB(64, 156, 255),
        AccentTertiary = Color3.fromRGB(255, 20, 147),
        
        Success = Color3.fromRGB(57, 255, 20),
        Warning = Color3.fromRGB(255, 193, 7),
        Error = Color3.fromRGB(244, 67, 54),
        Info = Color3.fromRGB(33, 150, 243),
        
        Border = Color3.fromRGB(60, 60, 80),
        BorderLight = Color3.fromRGB(80, 80, 120),
        Shadow = Color3.fromRGB(0, 0, 0),
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
        URL = "rbxassetid://82137490580832",
        DecalID = "rbxassetid://82137490580832",
    },
    
    GetResponsiveSize = function(mobile, tablet, desktop)
        if IsMobile then return mobile end
        if IsTablet then return tablet or desktop end
        return desktop
    end,
}

Theme.Sizes = {
    TopbarHeight = Theme.GetResponsiveSize(45, 55, 60),
    SidebarWidth = Theme.GetResponsiveSize(60, 200, 240),
    SidebarMinimized = Theme.GetResponsiveSize(50, 65, 70),
    CornerRadius = Theme.GetResponsiveSize(8, 10, 12),
    CornerRadiusSmall = Theme.GetResponsiveSize(6, 7, 8),
    IconSize = Theme.GetResponsiveSize(16, 18, 20),
    AvatarSize = Theme.GetResponsiveSize(28, 32, 36),
    Padding = Theme.GetResponsiveSize(12, 14, 16),
    PaddingSmall = Theme.GetResponsiveSize(6, 7, 8),
    PaddingLarge = Theme.GetResponsiveSize(16, 20, 24),
    Spacing = Theme.GetResponsiveSize(8, 10, 12),
    ButtonHeight = Theme.GetResponsiveSize(40, 45, 50),
    MinimizedLogoSize = Theme.GetResponsiveSize(50, 60, 70),
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
    ripple.BackgroundTransparency = 0.5
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
    if not instance then return nil end
    
    color = color or Theme.Colors.AccentPrimary
    intensity = intensity or 0.5
    
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://6014261993"
    glow.ImageColor3 = color
    glow.ImageTransparency = 1 - intensity
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(49, 49, 450, 450)
    glow.Size = UDim2.new(1, 40, 1, 40)
    glow.Position = UDim2.new(0, -20, 0, -20)
    glow.ZIndex = 0
    glow.Parent = instance
    
    return glow
end

function Animator:PulseGlow(glow, duration)
    if not glow then return end
    
    duration = duration or 2
    
    local function pulse()
        if not glow or not glow.Parent then return end
        
        self:Tween(glow, {ImageTransparency = 0.3}, duration/2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, function()
            if not glow or not glow.Parent then return end
            
            self:Tween(glow, {ImageTransparency = 0.7}, duration/2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, function()
                if glow and glow.Parent then
                    pulse()
                end
            end)
        end)
    end
    
    pulse()
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
    
    if props.Gradient then
        local gradient = Instance.new("UIGradient")
        gradient.Color = props.GradientColors or ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Colors.NeonPurple),
            ColorSequenceKeypoint.new(0.5, Theme.Colors.NeonCyan),
            ColorSequenceKeypoint.new(1, Theme.Colors.NeonPink)
        })
        gradient.Rotation = props.GradientRotation or 45
        gradient.Parent = frame
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

function Input:MakeResizable(frame, minSize, maxSize)
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
    if IsMobile then
        return nil
    end
    
    local container = Instance.new("Frame")
    container.Name = "ParticleBackground"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.ZIndex = 0
    container.Parent = parent
    
    for i = 1, 15 do
        spawn(function()
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5))
            particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
            particle.BackgroundColor3 = i % 3 == 0 and Theme.Colors.NeonPurple or (i % 3 == 1 and Theme.Colors.NeonCyan or Theme.Colors.NeonPink)
            particle.BackgroundTransparency = 0.7
            particle.BorderSizePixel = 0
            particle.ZIndex = 0
            particle.Parent = container
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = particle
            
            while particle.Parent and container.Parent do
                local randomX = math.random()
                local randomY = math.random()
                local duration = math.random(8, 15)
                
                Animator:Tween(particle, {
                    Position = UDim2.new(randomX, 0, randomY, 0),
                    BackgroundTransparency = math.random(50, 90) / 100
                }, duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                
                wait(duration)
            end
        end)
    end
    
    return container
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
    self.Subtitle = self.Config.Subtitle or "Delta Executor Edition"
    
    local defaultWidth = Theme.GetResponsiveSize(math.min(ScreenSize.X - 20, 400), 700, 850)
    local defaultHeight = Theme.GetResponsiveSize(math.min(ScreenSize.Y - 20, 500), 500, 550)
    
    self.Size = self.Config.Size or UDim2.new(0, defaultWidth, 0, defaultHeight)
    self.Tabs = {}
    self.CurrentTab = nil
    self.SidebarCollapsed = IsMobile
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
    
    self.MainFrame = Utils:CreateGlassFrame(self.GUI, {
        Color = Theme.Colors.Background,
        Transparency = 0.05,
        Size = self.Size,
        Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2),
        CornerRadius = Theme.Sizes.CornerRadius,
        StrokeColor = Theme.Colors.BorderLight,
        StrokeTransparency = 0.3,
        ClipsDescendants = true
    })
    
    local shadow = Animator:Glow(self.MainFrame, Theme.Colors.AccentPrimary, 0.2)
    
    ParticleSystem:CreateAnimatedBackground(self.MainFrame)
    
    self:CreateTopbar()
    self:CreateSidebar()
    self:CreateContentArea()
    self:CreateMinimizedLogo()
    
    Input:MakeDraggable(self.MainFrame, self.Topbar)
    Input:MakeResizable(self.MainFrame)
end

function Window:CreateTopbar()
    self.Topbar = Utils:CreateGlassFrame(self.MainFrame, {
        Color = Theme.Colors.GlassMid,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(1, 0, 0, Theme.Sizes.TopbarHeight),
        Position = UDim2.new(0, 0, 0, 0),
        CornerRadius = Theme.Sizes.CornerRadius,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7,
        Gradient = true,
        GradientRotation = 90
    })
    
    local bottomCover = Instance.new("Frame")
    bottomCover.BackgroundColor3 = Theme.Colors.GlassMid
    bottomCover.BackgroundTransparency = Theme.Transparency.Glass
    bottomCover.BorderSizePixel = 0
    bottomCover.Size = UDim2.new(1, 0, 0, Theme.Sizes.CornerRadius)
    bottomCover.Position = UDim2.new(0, 0, 1, -Theme.Sizes.CornerRadius)
    bottomCover.ZIndex = 1
    bottomCover.Parent = self.Topbar
    
    local leftSection = Instance.new("Frame")
    leftSection.BackgroundTransparency = 1
    leftSection.Size = UDim2.new(0.33, 0, 1, 0)
    leftSection.Parent = self.Topbar
    
    Utils:CreatePadding(leftSection, {Left = Theme.GetResponsiveSize(12, 16, 20), Right = 10})
    
    local logo = Utils:CreateIcon(leftSection, "⚡", {
        Size = Theme.GetResponsiveSize(20, 24, 28),
        Color = Theme.Colors.NeonCyan,
        Position = UDim2.new(0, 0, 0.5, -Theme.GetResponsiveSize(10, 12, 14))
    })
    
    local glow = Animator:Glow(logo, Theme.Colors.NeonCyan, 0.6)
    Animator:PulseGlow(glow, 3)
    
    local titleContainer = Instance.new("Frame")
    titleContainer.BackgroundTransparency = 1
    titleContainer.Size = UDim2.new(1, -Theme.GetResponsiveSize(35, 40, 45), 1, 0)
    titleContainer.Position = UDim2.new(0, Theme.GetResponsiveSize(35, 40, 45), 0, 0)
    titleContainer.Parent = leftSection
    
    Utils:CreateText(titleContainer, self.Title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(14, 16, 18),
        TextColor = Theme.Colors.TextPrimary,
        Size = UDim2.new(1, 0, 1, IsMobile and -16 or -10),
        Position = UDim2.new(0, 0, 0, IsMobile and 8 or 5),
        TextYAlignment = Enum.TextYAlignment.Bottom
    })
    
    if not IsMobile then
        Utils:CreateText(titleContainer, self.Subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 1, -18),
            TextYAlignment = Enum.TextYAlignment.Top
        })
    end
    
    local centerSection = Instance.new("Frame")
    centerSection.BackgroundTransparency = 1
    centerSection.Size = UDim2.new(0.34, 0, 1, 0)
    centerSection.Position = UDim2.new(0.33, 0, 0, 0)
    centerSection.Parent = self.Topbar
    
    self:CreateHideToggleButton(centerSection)
    
    local rightSection = Instance.new("Frame")
    rightSection.BackgroundTransparency = 1
    rightSection.Size = UDim2.new(0.33, 0, 1, 0)
    rightSection.Position = UDim2.new(0.67, 0, 0, 0)
    rightSection.Parent = self.Topbar
    
    Utils:CreatePadding(rightSection, {Left = 10, Right = Theme.GetResponsiveSize(12, 16, 20)})
    
    self:CreateWindowButtons(rightSection)
end

function Window:CreateHideToggleButton(parent)
    local buttonSize = Theme.GetResponsiveSize(30, 35, 40)
    
    local button = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(0, buttonSize, 0, buttonSize),
        Position = UDim2.new(0.5, -buttonSize/2, 0.5, -buttonSize/2),
        CornerRadius = buttonSize/2,
        StrokeColor = Theme.Colors.AccentPrimary,
        StrokeTransparency = 0.5
    })
    
    local icon = Utils:CreateIcon(button, "👁", {
        Size = Theme.GetResponsiveSize(16, 18, 20),
        Color = Theme.Colors.AccentPrimary,
        Position = UDim2.new(0.5, -Theme.GetResponsiveSize(8, 9, 10), 0.5, -Theme.GetResponsiveSize(8, 9, 10))
    })
    
    local btnGlow = Animator:Glow(button, Theme.Colors.AccentPrimary, 0.3)
    
    local clickButton = Instance.new("TextButton")
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.ZIndex = 10
    clickButton.Parent = button
    
    clickButton.MouseButton1Click:Connect(function()
        self:ToggleHide()
        Animator:Bounce(button, 0.9)
        
        if btnGlow then
            Animator:Tween(btnGlow, {ImageTransparency = 0.1}, Theme.Animations.Fast, nil, nil, function()
                Animator:Tween(btnGlow, {ImageTransparency = 0.7}, Theme.Animations.Fast)
            end)
        end
    end)
    
    if not IsMobile then
        Input:AddHoverEffect(button,
            {BackgroundTransparency = Theme.Transparency.GlassHover, StrokeTransparency = 0.2},
            {BackgroundTransparency = Theme.Transparency.Glass, StrokeTransparency = 0.5}
        )
    end
end

function Window:CreateWindowButtons(parent)
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 1, 0)
    container.Parent = parent
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, Theme.Sizes.PaddingSmall)
    layout.Parent = container
    
    local buttonSize = Theme.GetResponsiveSize(28, 32, 36)
    
    local minimizeBtn = self:CreateTopbarButton(container, "−", Theme.Colors.Info, buttonSize)
    minimizeBtn.MouseButton1Click:Connect(function()
        self:MinimizeWindow()
    end)
    
    local closeBtn = self:CreateTopbarButton(container, "✕", Theme.Colors.Error, buttonSize)
    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
end

function Window:CreateTopbarButton(parent, icon, color, size)
    local button = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(0, size, 0, size),
        CornerRadius = size/2,
        StrokeColor = color,
        StrokeTransparency = 0.7
    })
    
    Utils:CreateIcon(button, icon, {
        Size = Theme.GetResponsiveSize(12, 14, 16),
        Color = color,
        Position = UDim2.new(0.5, -Theme.GetResponsiveSize(6, 7, 8), 0.5, -Theme.GetResponsiveSize(6, 7, 8))
    })
    
    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 10
    clickBtn.Parent = button
    
    clickBtn.MouseButton1Click:Connect(function()
        Animator:Bounce(button, 0.85)
    end)
    
    if not IsMobile then
        Input:AddHoverEffect(button,
            {BackgroundTransparency = Theme.Transparency.GlassHover, StrokeTransparency = 0.3},
            {BackgroundTransparency = Theme.Transparency.Glass, StrokeTransparency = 0.7}
        )
    end
    
    return clickBtn
end

function Window:CreateSidebar()
    self.Sidebar = Utils:CreateGlassFrame(self.MainFrame, {
        Color = Theme.Colors.GlassMid,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(0, self.SidebarCollapsed and Theme.Sizes.SidebarMinimized or Theme.Sizes.SidebarWidth, 1, -Theme.Sizes.TopbarHeight),
        Position = UDim2.new(0, 0, 0, Theme.Sizes.TopbarHeight),
        CornerRadius = 0,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    local topCover = Instance.new("Frame")
    topCover.BackgroundColor3 = Theme.Colors.GlassMid
    topCover.BackgroundTransparency = Theme.Transparency.Glass
    topCover.BorderSizePixel = 0
    topCover.Size = UDim2.new(1, 0, 0, Theme.Sizes.CornerRadius)
    topCover.Position = UDim2.new(0, 0, 0, 0)
    topCover.ZIndex = 1
    topCover.Parent = self.Sidebar
    
    local rightCover = Instance.new("Frame")
    rightCover.BackgroundColor3 = Theme.Colors.GlassMid
    rightCover.BackgroundTransparency = Theme.Transparency.Glass
    rightCover.BorderSizePixel = 0
    rightCover.Size = UDim2.new(0, 1, 1, 0)
    rightCover.Position = UDim2.new(1, -1, 0, 0)
    rightCover.ZIndex = 1
    rightCover.Parent = self.Sidebar

        -- ===== TAB CONTAINER (auto-fit & clean scroll) =====
    self.TabContainer = Instance.new("ScrollingFrame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.BorderSizePixel = 0
    self.TabContainer.Size = UDim2.new(1, 0, 1, -Theme.GetResponsiveSize(70, 80, 90)) -- sisakan ruang untuk tombol bawah
    self.TabContainer.Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(10, 12, 14))
    self.TabContainer.ScrollBarThickness = 4
    self.TabContainer.ScrollBarImageColor3 = Theme.Colors.AccentPrimary
    self.TabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    self.TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y -- ✅ biar tinggi menyesuaikan isi
    self.TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabContainer.ZIndex = 2
    self.TabContainer.Parent = self.Sidebar

    -- layout & padding
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


    -- ===== FIXED TOGGLE BUTTON DI BAWAH =====
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

    -- ===== Efek Glow Hover (Neon Purple / Cyan) =====
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
    
    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Name = "ContentArea"
    self.ContentArea.BackgroundTransparency = 1
    self.ContentArea.Size = UDim2.new(1, -sidebarWidth, 1, -Theme.Sizes.TopbarHeight)
    self.ContentArea.Position = UDim2.new(0, sidebarWidth, 0, Theme.Sizes.TopbarHeight)
    self.ContentArea.ZIndex = 1
    self.ContentArea.Parent = self.MainFrame
end

function Window:CreateMinimizedLogo()
    local logoSize = Theme.Sizes.MinimizedLogoSize
    
    self.MinimizedLogo = Utils:CreateGlassFrame(self.GUI, {
        Color = Theme.Colors.GlassMid,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(0, logoSize, 0, logoSize),
        Position = UDim2.new(0, 20, 1, -logoSize - 20),
        CornerRadius = logoSize/2,
        StrokeColor = Theme.Colors.AccentPrimary,
        StrokeTransparency = 0.3,
        Gradient = true
    })
    
    self.MinimizedLogo.Visible = false
    
    local logoGlow = Animator:Glow(self.MinimizedLogo, Theme.Colors.AccentPrimary, 0.5)
    Animator:PulseGlow(logoGlow, 2)
    
    local logoImage = Instance.new("ImageLabel")
    logoImage.Name = "LogoImage"
    logoImage.BackgroundTransparency = 1
    logoImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    logoImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    logoImage.Image = Theme.Logo.URL
    logoImage.ImageColor3 = Theme.Colors.TextPrimary
    logoImage.ZIndex = 3
    logoImage.Parent = self.MinimizedLogo
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(1, 0)
    logoCorner.Parent = logoImage
    
    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 10
    clickBtn.Parent = self.MinimizedLogo
    
    clickBtn.MouseButton1Click:Connect(function()
        self:RestoreWindow()
        Animator:Bounce(self.MinimizedLogo, 0.9)
    end)
    
    Input:MakeDraggable(self.MinimizedLogo)
    
    if not IsMobile then
        Input:AddHoverEffect(self.MinimizedLogo,
            {Size = UDim2.new(0, logoSize + 10, 0, logoSize + 10), StrokeTransparency = 0.1},
            {Size = UDim2.new(0, logoSize, 0, logoSize), StrokeTransparency = 0.3}
        )
    end
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

function Window:ToggleHide()
    self.IsHidden = not self.IsHidden
    
    if self.IsHidden then
        Animator:SlideOut(self.MainFrame, "top", Theme.Animations.Normal, function()
            self.MainFrame.Visible = false
        end)
    else
        self.MainFrame.Visible = true
        Animator:SlideIn(self.MainFrame, "top", Theme.Animations.Normal)
    end
end

function Window:MinimizeWindow()
    self.IsMinimized = true
    
    Animator:Tween(self.MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, 20, 1, -Theme.Sizes.MinimizedLogoSize - 20)
    }, Theme.Animations.Normal, Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
        self.MainFrame.Visible = false
        self.MinimizedLogo.Visible = true
        Animator:Spring(self.MinimizedLogo, {Size = UDim2.new(0, Theme.Sizes.MinimizedLogoSize, 0, Theme.Sizes.MinimizedLogoSize)})
    end)
end

function Window:RestoreWindow()
    self.IsMinimized = false
    
    Animator:Tween(self.MinimizedLogo, {
        Size = UDim2.new(0, 0, 0, 0)
    }, Theme.Animations.Fast, nil, nil, function()
        self.MinimizedLogo.Visible = false
        self.MainFrame.Visible = true
        
        Animator:Spring(self.MainFrame, {
            Size = self.Size,
            Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2)
        })
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
    
    local buttonHeight = Theme.GetResponsiveSize(40, 45, 50)
    
    tab.Button = Utils:CreateGlassFrame(self.TabContainer, {
        Color = Theme.Colors.Surface,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(1, 0, 0, buttonHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    local iconLabel = Utils:CreateIcon(tab.Button, icon, {
        Size = Theme.GetResponsiveSize(16, 18, 20),
        Color = Theme.Colors.TextSecondary,
        Position = UDim2.new(0, Theme.Sizes.Padding, 0.5, -Theme.GetResponsiveSize(8, 9, 10))
    })
    iconLabel.Name = "TabIcon"
    
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
        if tab == targetTab then
            tab.Active = true
            tab.Content.Visible = true
            
            local iconLabel = tab.Button:FindFirstChild("TabIcon")
            local textLabel = tab.Button:FindFirstChild("TabText")
            
            Animator:Tween(tab.Button, {
                BackgroundColor3 = Theme.Colors.AccentPrimary,
                BackgroundTransparency = Theme.Transparency.GlassActive
            }, Theme.Animations.Fast)
            
            if iconLabel then
                Animator:Tween(iconLabel, {TextColor3 = Theme.Colors.TextPrimary}, Theme.Animations.Fast)
            end
            
            if textLabel then
                Animator:Tween(textLabel, {TextColor3 = Theme.Colors.TextPrimary}, Theme.Animations.Fast)
            end
        else
            tab.Active = false
            tab.Content.Visible = false
            
            local iconLabel = tab.Button:FindFirstChild("TabIcon")
            local textLabel = tab.Button:FindFirstChild("TabText")
            
            Animator:Tween(tab.Button, {
                BackgroundColor3 = Theme.Colors.Surface,
                BackgroundTransparency = Theme.Transparency.Glass
            }, Theme.Animations.Fast)
            
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
    Animator:Tween(self.MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }, Theme.Animations.Normal, Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
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
    local active = config.Active or false -- status awal tombol (optional)
    
    -- 🧱 Container utama tombol
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(1, 0, 0, subtitle and Theme.GetResponsiveSize(60, 65, 70) or Theme.Sizes.ButtonHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.AccentPrimary,
        StrokeTransparency = 0.7,
        ClipsDescendants = true
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    local textContainer = Instance.new("Frame")
    textContainer.BackgroundTransparency = 1
    textContainer.Size = UDim2.new(1, 0, 1, 0)
    textContainer.Parent = container
    
    Utils:CreateText(textContainer, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Position = UDim2.new(0, 0, 0, subtitle and Theme.GetResponsiveSize(6, 7, 8) or 0),
        TextYAlignment = subtitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        TextScaled = IsMobile
    })
    
    if subtitle then
        Utils:CreateText(textContainer, subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(26, 28, 32)),
            TextYAlignment = Enum.TextYAlignment.Top,
            TextScaled = IsMobile
        })
    end

    -- 🟦 Tombol klik tak terlihat di atas container
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 10
    button.Parent = container

    -- ✅ Pastikan ada UIStroke
    local stroke = container:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Color = Theme.Colors.AccentPrimary
        stroke.Thickness = 1
        stroke.Transparency = 0.7
        stroke.Parent = container
    end

    -- 💡 Dynamic Ripple Color Function
    local function getRippleColor()
        if active then
            return Theme.Colors.Success or Color3.fromRGB(0, 255, 100)
        else
            return Theme.Colors.Danger or Color3.fromRGB(255, 80, 80)
        end
    end

    -- ⚡ Klik efek: Ripple, Bounce, Toggle
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local clickPos = Vector2.new(input.Position.X, input.Position.Y)
            if container.AbsolutePosition then
                clickPos = clickPos - container.AbsolutePosition
            end

            -- Ripple dinamis + bounce
            pcall(function()
                Animator:Ripple(container, clickPos, getRippleColor())
                Animator:Bounce(container, 0.9)
            end)

            -- Toggle status aktif
            active = not active
            callback(active)
        end
    end)

    -- 🌈 Hover efek neon glow (cyan default)
    if not IsMobile then
        button.MouseEnter:Connect(function()
            pcall(function()
                TweenService:Create(container, Theme.Animations.Fast, {
                    BackgroundTransparency = Theme.Transparency.GlassHover
                }):Play()
                TweenService:Create(stroke, Theme.Animations.Fast, {
                    Transparency = 0.25,
                    Color = Theme.Colors.NeonCyan
                }):Play()
            end)
        end)
        
        button.MouseLeave:Connect(function()
            pcall(function()
                TweenService:Create(container, Theme.Animations.Fast, {
                    BackgroundTransparency = Theme.Transparency.Glass
                }):Play()
                TweenService:Create(stroke, Theme.Animations.Fast, {
                    Transparency = 0.7,
                    Color = Theme.Colors.AccentPrimary
                }):Play()
            end)
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
    
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(1, 0, 0, subtitle and Theme.GetResponsiveSize(60, 65, 70) or Theme.Sizes.ButtonHeight),
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
        Position = UDim2.new(0, 0, 0, subtitle and Theme.GetResponsiveSize(6, 7, 8) or 0),
        TextYAlignment = subtitle and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        TextScaled = IsMobile
    })
    
    if subtitle then
        Utils:CreateText(textContainer, subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10, 11, 12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(0, 0, 0, Theme.GetResponsiveSize(26, 28, 32)),
            TextYAlignment = Enum.TextYAlignment.Top,
            TextScaled = IsMobile
        })
    end
    
    local toggleSize = Theme.GetResponsiveSize(22, 24, 26)
    local trackWidth = Theme.GetResponsiveSize(42, 46, 50)
    
    local toggleTrack = Utils:CreateGlassFrame(container, {
        Color = default and Theme.Colors.AccentPrimary or Theme.Colors.SurfaceLight,
        Transparency = 0.1,
        Size = UDim2.new(0, trackWidth, 0, toggleSize),
        Position = UDim2.new(1, -trackWidth, 0.5, -toggleSize/2),
        CornerRadius = toggleSize/2,
        Stroke = false
    })
    
    local glow = Animator:Glow(toggleTrack, Theme.Colors.AccentPrimary, default and 0.5 or 0)
    
    local knobSize = Theme.GetResponsiveSize(16, 18, 20)
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
    
    local knobShadow = Animator:Glow(toggleKnob, Theme.Colors.Shadow, 0.3)
    
    local state = default
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 10
    button.Parent = container
    
    button.MouseButton1Click:Connect(function()
        state = not state
        
        Animator:Bounce(toggleTrack, 0.95)
        
        if state then
            Animator:Spring(toggleKnob, {Position = UDim2.new(1, -knobSize - 3, 0.5, -knobSize/2)})
            Animator:Tween(toggleTrack, {BackgroundColor3 = Theme.Colors.AccentPrimary}, Theme.Animations.Fast)
            if glow then
                Animator:Tween(glow, {ImageTransparency = 0.5}, Theme.Animations.Fast)
            end
        else
            Animator:Spring(toggleKnob, {Position = UDim2.new(0, 3, 0.5, -knobSize/2)})
            Animator:Tween(toggleTrack, {BackgroundColor3 = Theme.Colors.SurfaceLight}, Theme.Animations.Fast)
            if glow then
                Animator:Tween(glow, {ImageTransparency = 1}, Theme.Animations.Fast)
            end
        end
        
        callback(state)
    end)
    
    if not IsMobile then
        Input:AddHoverEffect(container,
            {BackgroundTransparency = Theme.Transparency.GlassHover},
            {BackgroundTransparency = Theme.Transparency.Glass}
        )
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

    local closedHeight = subtitle and Theme.GetResponsiveSize(80,85,90) or Theme.GetResponsiveSize(65,70,75)
    local optionHeight = Theme.GetResponsiveSize(26,28,30)
    local maxVisible = 5 -- 🔥 cuma tampil 5 item, sisanya scrollable

    -- Hitung total tinggi kalau semua opsi muncul
    local expandedHeight = math.min(#options, maxVisible) * optionHeight + 10
    local scrollHeight = #options > maxVisible and (maxVisible * optionHeight + 10) or (#options * optionHeight + 10)

    -- 🧱 Container utama
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(1, 0, 0, closedHeight),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.AccentPrimary,
        StrokeTransparency = 0.7,
        ClipsDescendants = true,
    })
    Utils:CreatePadding(container, Theme.Sizes.PaddingSmall)

    -- 🏷️ Label
    Utils:CreateText(container, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13,14,15),
        TextColor = Theme.Colors.TextPrimary,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    if subtitle then
        Utils:CreateText(container, subtitle, {
            Font = Theme.Fonts.Secondary,
            TextSize = Theme.GetResponsiveSize(10,11,12),
            TextColor = Theme.Colors.TextSecondary,
            Position = UDim2.new(0,0,0,Theme.GetResponsiveSize(24,26,28)),
            TextYAlignment = Enum.TextYAlignment.Top
        })
    end

    -- 🎛 Tombol dropdown
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Size = UDim2.new(1,-10,0,Theme.GetResponsiveSize(28,30,32))
    dropdownButton.Position = UDim2.new(0,0,0,Theme.GetResponsiveSize(38,40,45))
    dropdownButton.BackgroundTransparency = 1
    dropdownButton.Text = default
    dropdownButton.TextColor3 = Theme.Colors.TextPrimary
    dropdownButton.Font = Theme.Fonts.Primary
    dropdownButton.TextSize = Theme.GetResponsiveSize(13,14,15)
    dropdownButton.ZIndex = 10
    dropdownButton.Parent = container

    local arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.Font = Enum.Font.SourceSansBold
    arrow.TextColor3 = Theme.Colors.TextSecondary
    arrow.TextSize = 16
    arrow.AnchorPoint = Vector2.new(1,0.5)
    arrow.Position = UDim2.new(1,-5,0.5,0)
    arrow.ZIndex = 11
    arrow.Parent = dropdownButton

    -- 📜 ScrollFrame (biar bisa scroll)
    local dropdownFrame = Instance.new("ScrollingFrame")
    dropdownFrame.Active = true
    dropdownFrame.ScrollBarThickness = 4
    dropdownFrame.ScrollBarImageColor3 = Theme.Colors.AccentPrimary
    dropdownFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dropdownFrame.CanvasSize = UDim2.new(0,0,0,0)
    dropdownFrame.BackgroundColor3 = Theme.Colors.GlassMid
    dropdownFrame.BackgroundTransparency = 0.3
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.Visible = false
    dropdownFrame.Size = UDim2.new(1,0,0,0)
    dropdownFrame.Position = UDim2.new(0,0,0,Theme.GetResponsiveSize(70,75,80))
    dropdownFrame.ZIndex = 9
    dropdownFrame.Parent = container

    local uiList = Instance.new("UIListLayout")
    uiList.Parent = dropdownFrame
    uiList.Padding = UDim.new(0,2)

    for _, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1,-8,0,optionHeight)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = option
        optBtn.Font = Theme.Fonts.Primary
        optBtn.TextSize = Theme.GetResponsiveSize(12,13,14)
        optBtn.TextColor3 = Theme.Colors.TextPrimary
        optBtn.ZIndex = 12
        optBtn.Parent = dropdownFrame

        -- Hover highlight effect
        optBtn.MouseEnter:Connect(function()
            TweenService:Create(optBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Colors.NeonCyan}):Play()
        end)
        optBtn.MouseLeave:Connect(function()
            TweenService:Create(optBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Colors.TextPrimary}):Play()
        end)

        optBtn.MouseButton1Click:Connect(function()
            dropdownButton.Text = option
            callback(option)

            -- Tutup dropdown
            TweenService:Create(container, TweenInfo.new(0.25), {
                Size = UDim2.new(1,0,0,closedHeight)
            }):Play()
            TweenService:Create(dropdownFrame, TweenInfo.new(0.25), {
                Size = UDim2.new(1,0,0,0)
            }):Play()
            task.wait(0.25)
            dropdownFrame.Visible = false
            arrow.Text = "▼"
        end)
    end

    -- 🔄 Toggle buka/tutup dropdown
    dropdownButton.MouseButton1Click:Connect(function()
        if dropdownFrame.Visible then
            -- Tutup
            TweenService:Create(container, TweenInfo.new(0.25), {
                Size = UDim2.new(1,0,0,closedHeight)
            }):Play()
            TweenService:Create(dropdownFrame, TweenInfo.new(0.25), {
                Size = UDim2.new(1,0,0,0)
            }):Play()
            task.wait(0.25)
            dropdownFrame.Visible = false
            arrow.Text = "▼"
        else
            -- Buka
            dropdownFrame.Visible = true
            arrow.Text = "▲"
            TweenService:Create(container, TweenInfo.new(0.3), {
                Size = UDim2.new(1,0,0,closedHeight + scrollHeight + 10)
            }):Play()
            TweenService:Create(dropdownFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(1,0,0,scrollHeight)
            }):Play()
        end
    end)

    return container
end








function Components:CreateSlider(parent, config)
    config = config or {}
    local title = config.Title or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local increment = config.Increment or 1
    local callback = config.Callback or function() end
    
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(60, 65, 70)),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    local header = Instance.new("Frame")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 20)
    header.Parent = container
    
    Utils:CreateText(header, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Size = UDim2.new(1, -50, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local valueLabel = Utils:CreateText(header, tostring(default), {
        Font = Theme.Fonts.Mono,
        TextSize = Theme.GetResponsiveSize(12, 13, 14),
        TextColor = Theme.Colors.AccentPrimary,
        Size = UDim2.new(0, 50, 1, 0),
        Position = UDim2.new(1, -50, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right
    })
    
    local sliderTrack = Utils:CreateGlassFrame(container, {
        Color = Theme.Colors.SurfaceLight,
        Transparency = 0.1,
        Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(5, 5, 6)),
        Position = UDim2.new(0, 0, 1, -12),
        CornerRadius = 3,
        Stroke = false
    })
    
    local sliderFill = Instance.new("Frame")
    sliderFill.BackgroundColor3 = Theme.Colors.AccentPrimary
    sliderFill.BorderSizePixel = 0
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.ZIndex = 2
    sliderFill.Parent = sliderTrack
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
    local fillGlow = Animator:Glow(sliderFill, Theme.Colors.AccentPrimary, 0.6)
    
    local knobSize = Theme.GetResponsiveSize(14, 15, 16)
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
    
    local knobGlow = Animator:Glow(sliderKnob, Theme.Colors.AccentPrimary, 0)
    
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
            
            Animator:Tween(sliderKnob, {Size = UDim2.new(0, knobSize + 4, 0, knobSize + 4)}, Theme.Animations.Fast)
            if knobGlow then
                Animator:Tween(knobGlow, {ImageTransparency = 0.4}, Theme.Animations.Fast)
            end
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    Animator:Tween(sliderKnob, {Size = UDim2.new(0, knobSize, 0, knobSize)}, Theme.Animations.Fast)
                    if knobGlow then
                        Animator:Tween(knobGlow, {ImageTransparency = 1}, Theme.Animations.Fast)
                    end
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
    
    return container
end

function Components:CreateTextBox(parent, config)
    config = config or {}
    local title = config.Title or "TextBox"
    local placeholder = config.Placeholder or "Enter text..."
    local default = config.Default or ""
    local callback = config.Callback or function() end
    
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = Theme.Transparency.Glass,
        Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(60, 65, 70)),
        CornerRadius = Theme.Sizes.CornerRadiusSmall,
        StrokeColor = Theme.Colors.Border,
        StrokeTransparency = 0.7
    })
    
    Utils:CreatePadding(container, Theme.Sizes.Padding)
    
    Utils:CreateText(container, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(13, 14, 15),
        TextColor = Theme.Colors.TextPrimary,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 0)
    })
    
    local inputFrame = Utils:CreateGlassFrame(container, {
        Color = Theme.Colors.SurfaceLight,
        Transparency = 0.1,
        Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(28, 30, 32)),
        Position = UDim2.new(0, 0, 1, -Theme.GetResponsiveSize(28, 30, 32)),
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
            StrokeTransparency = 0.3
        }, Theme.Animations.Fast)
    end)
    
    textBox.FocusLost:Connect(function()
        Animator:Tween(inputFrame, {
            BackgroundColor3 = Theme.Colors.SurfaceLight,
            StrokeColor = Theme.Colors.Border,
            StrokeTransparency = 0.5
        }, Theme.Animations.Fast)
        callback(textBox.Text)
    end)
    
    return container
end

function Components:CreateLabel(parent, config)
    config = config or {}
    local title = config.Title or "Label"
    local subtitle = config.Subtitle
    
    local container = Utils:CreateGlassFrame(parent, {
        Color = Theme.Colors.Surface,
        Transparency = Theme.Transparency.Glass + 0.1,
        Size = UDim2.new(1, 0, 0, subtitle and Theme.GetResponsiveSize(50, 55, 60) or Theme.GetResponsiveSize(35, 38, 40)),
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
    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, Theme.GetResponsiveSize(25, 28, 30))
    container.Parent = parent
    
    Utils:CreateText(container, title, {
        Font = Theme.Fonts.Primary,
        TextSize = Theme.GetResponsiveSize(14, 15, 16),
        TextColor = Theme.Colors.AccentPrimary,
        Size = UDim2.new(1, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom
    })
    
    local divider = Instance.new("Frame")
    divider.BackgroundColor3 = Theme.Colors.AccentPrimary
    divider.BackgroundTransparency = 0.7
    divider.BorderSizePixel = 0
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 1, -2)
    divider.Parent = container
    
    return container
end

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

getgenv().VyperUI = VyperUI
_G.VyperUI = VyperUI

print([[
═══════════════════════════════════════════════
  ██╗   ██╗██╗   ██╗██████╗ ███████╗██████╗    
  ██║   ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗   
  ██║   ██║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝  
  ╚██╗ ██╔╝  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗  
   ╚████╔╝    ██║   ██║     ███████╗██║  ██║  
    ╚═══╝     ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝   
                                                                   
═══════════════════════════════════════════════
]])

return VyperUI
