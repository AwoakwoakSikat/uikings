--[[
    ╔═══════════════════════════════════════════════════╗
    ║   [CURE] Violence District — Multi Script         ║
    ║   Features: Vypers UI | ESP | Auto Parry          ║
    ║             Auto Perfect Gen | Crosshair          ║
    ╚═══════════════════════════════════════════════════╝
--]]

-- ─────────────────────────────────────────────────────
-- GLOBAL CLEANUP SYSTEM (Prevents duplicate runs & lag)
-- ─────────────────────────────────────────────────────
if _G.VD_Cleanup then
    pcall(_G.VD_Cleanup)
end

local Connections = {}
local Cleanups = {}

_G.VD_Cleanup = function()
    -- Disconnect all events
    for _, conn in ipairs(Connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    -- Run custom cleanups (UI, crosshair, ESP)
    for _, cleanup in ipairs(Cleanups) do
        pcall(cleanup)
    end
    print("[Violence District] Old script session cleaned up successfully.")
end

-- Helper to register connections
local function regConn(conn)
    table.insert(Connections, conn)
    return conn
end

-- ─────────────────────────────────────────────────────
-- UI LIBRARY (Vypers UI)
-- Ganti VYPERS_URL ke raw URL VypersLib41.lua lu.
-- ─────────────────────────────────────────────────────
local VYPERS_URL = "https://raw.githubusercontent.com/AwoakwoakSikat/uikings/refs/heads/main/VypersLib41.lua"

local VypersLib = _G.VypersLib
if not VypersLib then
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(VYPERS_URL))()
    end)
    if not ok or type(lib) ~= "table" then
        error("[Violence District] Gagal load Vypers UI Library: " .. tostring(lib))
    end
    VypersLib = lib
end
_G.VypersLib = VypersLib

-- ─────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────────────
-- REMOTES
-- ─────────────────────────────────────────────────────
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function waitRemote(parent, name)
    if not parent then return nil end
    return parent:WaitForChild(name, 5)
end

local GenRemotes         = waitRemote(Remotes, "Generator")
local SkillCheckEvent    = waitRemote(GenRemotes, "SkillCheckEvent")
local SkillCheckResult   = waitRemote(GenRemotes, "SkillCheckResultEvent")

local KPRemotes          = Remotes:FindFirstChild("KillerPerks")
local KSRemotes          = KPRemotes and KPRemotes:FindFirstChild("kingscourge")
local KingScourgeStart   = KSRemotes and KSRemotes:FindFirstChild("KingScourgeStart")
local KingScourgeHit     = KSRemotes and KSRemotes:FindFirstChild("KingScourgeHit")

local ItemRemotes        = waitRemote(Remotes, "Items")
local DaggerFolder       = ItemRemotes and ItemRemotes:FindFirstChild("Parrying Dagger")
local ParryEvent         = DaggerFolder and DaggerFolder:FindFirstChild("parry")
local ParryResultEvent   = DaggerFolder and DaggerFolder:FindFirstChild("parryResult")

local AttacksFolder      = waitRemote(Remotes, "Attacks")
local BasicAttack        = AttacksFolder and AttacksFolder:FindFirstChild("BasicAttack")

-- ─────────────────────────────────────────────────────
-- CONFIG (live-edited by toggles/sliders)
-- ─────────────────────────────────────────────────────
local Cfg = {
    -- ESP
    ESP_Enabled    = true,
    ESP_Killer     = true,
    ESP_Survivor   = true,
    ESP_Spectator  = false,
    ESP_Generator  = true,
    ESP_Names      = true,
    ESP_Distance   = true,
    ESP_Highlight  = true,
    -- Combat
    AutoParry      = false,
    ParryRange     = 18,
    AutoEquip      = true,
    ParryCooldown  = 1.0,
    -- Generator
    AutoPerfectGen = true,
    GenDelayMin    = 0.15,
    GenDelayMax    = 0.35,
    -- Crosshair
    Crosshair      = true,
    CHColor        = Color3.fromRGB(0, 220, 255),
    CHSize         = 10,
    CHGap          = 5,
    CHThick        = 2,
}

-- ─────────────────────────────────────────────────────
-- CROSSHAIR
-- ─────────────────────────────────────────────────────
local CrosshairGui = nil

local function DestroyCrosshair()
    if CrosshairGui and CrosshairGui.Parent then
        CrosshairGui:Destroy()
        CrosshairGui = nil
    end
end
table.insert(Cleanups, DestroyCrosshair)

local function BuildCrosshair()
    DestroyCrosshair()
    if not Cfg.Crosshair then return end

    local gui = Instance.new("ScreenGui")
    gui.Name            = "VD_Crosshair"
    gui.ResetOnSpawn    = false
    gui.DisplayOrder    = 999
    gui.IgnoreGuiInset  = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = PG end
    CrosshairGui = gui

    local function bar(sx, sy, px, py)
        local f = Instance.new("Frame", gui)
        f.Size                  = UDim2.new(0, sx, 0, sy)
        f.Position              = UDim2.new(0.5, px, 0.5, py)
        f.BackgroundColor3      = Cfg.CHColor
        f.BorderSizePixel       = 0
        f.ZIndex                = 10
        -- thin drop shadow
        local shadow = Instance.new("Frame", f)
        shadow.Size             = UDim2.new(1, 2, 1, 2)
        shadow.Position         = UDim2.new(0, -1, 0, 1)
        shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
        shadow.BorderSizePixel  = 0
        shadow.BackgroundTransparency = 0.7
        shadow.ZIndex           = 9
        return f
    end

    local sz, gap, th = Cfg.CHSize, Cfg.CHGap, Cfg.CHThick
    -- left  right  top  bottom  dot
    bar(sz, th, -sz - gap, -th/2)
    bar(sz, th,  gap,       -th/2)
    bar(th, sz, -th/2, -sz - gap)
    bar(th, sz, -th/2,  gap)
    bar(th, th, -th/2, -th/2)
end

-- ─────────────────────────────────────────────────────
-- ESP SYSTEM
-- ─────────────────────────────────────────────────────
local ESPObjects = {}  -- [model] = { highlight, billboard }

local RoleColors = {
    Killer    = Color3.fromRGB(255, 70,  70),
    Survivors = Color3.fromRGB(70,  160, 255),
    Spectator = Color3.fromRGB(180, 180, 180),
    Generator = Color3.fromRGB(255, 210, 50),
    GenDone   = Color3.fromRGB(50,  255, 100),
}

local function CleanESP(model)
    if ESPObjects[model] then
        for _, v in ipairs(ESPObjects[model]) do
            pcall(function()
                if typeof(v) == "Instance" then
                    v:Destroy()
                elseif type(v) == "userdata" and v.Disconnect then
                    v:Disconnect()
                end
            end)
        end
        ESPObjects[model] = nil
    end
end

local function MakeESP(model, role)
    CleanESP(model)
    if not Cfg.ESP_Enabled then return end

    local color = RoleColors[role] or Color3.fromRGB(255,255,255)
    local objs  = {}
    ESPObjects[model] = objs

    -- Highlight (chams)
    if Cfg.ESP_Highlight then
        local hl = Instance.new("Highlight")
        hl.Adornee         = model
        hl.FillColor          = color
        hl.FillTransparency   = 0.75
        hl.OutlineColor       = color
        hl.OutlineTransparency = 0.0
        hl.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent          = model
        table.insert(objs, hl)
    end

    -- Billboard
    local adornee = model:FindFirstChild("HumanoidRootPart")
                 or model:FindFirstChild("RootPart")
                 or model:FindFirstChild("HitBox")
                 or model:FindFirstChildWhichIsA("BasePart")
    if not adornee then return end

    local bb = Instance.new("BillboardGui")
    bb.Name          = "VD_ESP"
    bb.Adornee       = adornee
    bb.AlwaysOnTop   = true
    bb.Size          = UDim2.new(0, 220, 0, 55)
    bb.StudsOffset   = Vector3.new(0, 3.2, 0)
    bb.Parent        = adornee
    table.insert(objs, bb)

    local bg = Instance.new("Frame", bb)
    bg.Size                    = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3        = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency  = 0.55
    bg.BorderSizePixel         = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size                 = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3           = color
    lbl.TextStrokeColor3     = Color3.fromRGB(0,0,0)
    lbl.TextStrokeTransparency = 0.2
    lbl.Font                 = Enum.Font.GothamBold
    lbl.TextSize             = 13
    lbl.Text                 = ""

    -- Updater
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not model or not model.Parent then
            CleanESP(model)
            conn:Disconnect()
            return
        end

        local txt = ""
        local rootChar = LP.Character
        local hrp = rootChar and rootChar:FindFirstChild("HumanoidRootPart")

        if role == "Killer" or role == "Survivors" or role == "Spectator" then
            local player = Players:GetPlayerFromCharacter(model)
            local name   = player and player.DisplayName or model.Name
            if Cfg.ESP_Names then
                txt = ("[%s] %s"):format(role == "Survivors" and "SURVIVOR" or role:upper(), name)
            end
            if Cfg.ESP_Distance and hrp then
                local d = math.floor((adornee.Position - hrp.Position).Magnitude)
                txt = txt .. ("\n📍 %d studs"):format(d)
            end
            lbl.TextColor3 = color
        else
            -- Generator
            local prog = model:GetAttribute("RepairProgress") or 0
            local done = model:GetAttribute("Completed")
            local reg  = model:GetAttribute("Regressing")
            local repairing = (model:GetAttribute("PlayersRepairingCount") or 0) > 0

            local c  = done and RoleColors.GenDone or RoleColors.Generator
            txt = done and "⚙ Generator [✔ Done]"
                       or  ("⚙ Generator [%d%%]%s%s"):format(
                               math.floor(prog),
                               reg and " ↘" or "",
                               repairing and " 🔧" or "")

            if Cfg.ESP_Distance and hrp then
                local d = math.floor((adornee.Position - hrp.Position).Magnitude)
                txt = txt .. ("\n📍 %d studs"):format(d)
            end

            lbl.TextColor3 = c
            for _, o in ipairs(objs) do
                if typeof(o) == "Instance" and o:IsA("Highlight") then
                    o.FillColor    = c
                    o.OutlineColor = c
                    o.FillTransparency = 0.75
                    o.OutlineTransparency = 0.0
                end
            end
        end

        lbl.Text = txt
    end)
    table.insert(objs, conn)
end

local function RefreshESP()
    for model in pairs(ESPObjects) do
        CleanESP(model)
    end
    if not Cfg.ESP_Enabled then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local role = p.Team and p.Team.Name or "Unknown"
        local ok = (role == "Killer"   and Cfg.ESP_Killer)
                or (role == "Survivors" and Cfg.ESP_Survivor)
                or (role == "Spectator" and Cfg.ESP_Spectator)
        if ok and p.Character then
            MakeESP(p.Character, role)
        end
    end

    if Cfg.ESP_Generator then
        local gens = workspace:FindFirstChild("Map")
                 and workspace.Map:FindFirstChild("Generators")
        if gens then
            for _, g in ipairs(gens:GetChildren()) do
                if g.Name == "Generator" then
                    MakeESP(g, "Generator")
                end
            end
        end
    end
end

local function CleanAllESPObjects()
    for model in pairs(ESPObjects) do
        CleanESP(model)
    end
end
table.insert(Cleanups, CleanAllESPObjects)

-- Hook players
regConn(Players.PlayerAdded:Connect(function(p)
    regConn(p.CharacterAdded:Connect(function(char)
        task.wait(1)
        RefreshESP()
    end))
end))
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        regConn(p.CharacterAdded:Connect(function()
            task.wait(1)
            RefreshESP()
        end))
    end
end
regConn(Players.PlayerRemoving:Connect(function(p)
    if p.Character then CleanESP(p.Character) end
end))

-- Poll for new generators every 5s
task.spawn(function()
    while true do
        task.wait(5)
        if not Cfg.ESP_Generator or not Cfg.ESP_Enabled then continue end
        local gens = workspace:FindFirstChild("Map")
                 and workspace.Map:FindFirstChild("Generators")
        if gens then
            for _, g in ipairs(gens:GetChildren()) do
                if g.Name == "Generator" and not ESPObjects[g] then
                    MakeESP(g, "Generator")
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────
-- AUTO PARRY
-- ─────────────────────────────────────────────────────
local parryCD = false

local function TryParry()
    if not Cfg.AutoParry then return end
    if parryCD then return end
    if not LP.Character then return end

    -- Must have Parrying Dagger
    local dagger = LP.Character:FindFirstChild("Parrying Dagger")
                or LP.Backpack:FindFirstChild("Parrying Dagger")
    if not dagger then return end

    -- Auto equip
    if Cfg.AutoEquip and dagger.Parent == LP.Backpack then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(dagger)
            task.wait(0.1)
        end
    end

    -- Must still be equipped
    if not LP.Character:FindFirstChild("Parrying Dagger") then return end

    if ParryEvent then
        parryCD = true
        ParryEvent:FireServer()
        task.delay(Cfg.ParryCooldown, function() parryCD = false end)
    end
end

local function WatchKillerAnimations(killerChar)
    local hum = killerChar:WaitForChild("Humanoid", 5)
    local anim = hum and hum:WaitForChild("Animator", 5)
    if not anim then return end

    regConn(anim.AnimationPlayed:Connect(function(track)
        if not Cfg.AutoParry then return end
        if not LP.Character then return end
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        local khrp = killerChar:FindFirstChild("HumanoidRootPart")
        if not hrp or not khrp then return end

        local dist = (hrp.Position - khrp.Position).Magnitude
        if dist > Cfg.ParryRange then return end

        -- Parry on any animation played by killer within range
        TryParry()
    end))
end

local function SetupAutoParry()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local role = p.Team and p.Team.Name or ""
            if role == "Killer" and p.Character then
                WatchKillerAnimations(p.Character)
            end
            regConn(p.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                local r = p.Team and p.Team.Name or ""
                if r == "Killer" then WatchKillerAnimations(char) end
            end))
        end
    end

    regConn(Players.PlayerAdded:Connect(function(p)
        regConn(p.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            local r = p.Team and p.Team.Name or ""
            if r == "Killer" then WatchKillerAnimations(char) end
        end))
    end))
end

-- ─────────────────────────────────────────────────────
-- DUAL-LAYER AUTO PERFECT GENERATOR
-- Layer 1: Watch QTE appearance, snap line to success, simulate Space press.
-- Layer 2: Metamethod Hook (Failsafe) - Force success on any outgoing fail/neutral remotes.
-- ─────────────────────────────────────────────────────
do
    local genArg1, genArg2 = nil, nil
    local genWaiting       = false

    -- Capture generator QTE params on client event
    if SkillCheckEvent then
        regConn(SkillCheckEvent.OnClientEvent:Connect(function(p1, p2)
            genArg1   = p1
            genArg2   = p2
            genWaiting = true
        end))
    end

    local skillGui = PG:WaitForChild("SkillCheckPromptGui", 5)
    local Check    = skillGui and skillGui:WaitForChild("Check", 5)
    local Line     = Check and Check:WaitForChild("Line", 5)
    local Goal     = Check and Check:WaitForChild("Goal", 5)
    local lastVis  = false

    if Check and Line and Goal then
        regConn(RunService.Heartbeat:Connect(function()
            if not Cfg.AutoPerfectGen then
                lastVis = Check.Visible
                return
            end

            local vis = Check.Visible

            -- Detect when the SkillCheck UI turns visible
            if vis and not lastVis and genWaiting then
                genWaiting = false

                local delay = Cfg.GenDelayMin + math.random() * (Cfg.GenDelayMax - Cfg.GenDelayMin)

                task.delay(delay, function()
                    if not Cfg.AutoPerfectGen then return end
                    if not LP.Character then return end
                    local ci = LP.Character:FindFirstChild("CheckInterractable")
                    if not ci or not ci:GetAttribute("isRepairing") then return end

                    -- Snap line rotation into the success range (109 + Goal.Rotation)
                    Line.Rotation = 109 + Goal.Rotation

                    -- Simulate a real spacebar keystroke to trigger the game script's handler
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end)
            end

            lastVis = vis
        end))
    end
end

-- ─────────────────────────────────────────────────────
-- DUAL-LAYER AUTO PERFECT GENERATOR (King's Scourge)
-- ─────────────────────────────────────────────────────
do
    local ksArg2    = nil
    local ksWaiting = false

    if KingScourgeStart then
        regConn(KingScourgeStart.OnClientEvent:Connect(function(p1, p2, p3)
            ksArg2   = p2
            ksWaiting = true
        end))
    end

    local skillGui = PG:WaitForChild("SkillCheckPromptGui", 5)
    local Check    = skillGui and skillGui:WaitForChild("Check", 5)
    local Line     = Check and Check:WaitForChild("Line", 5)
    local Goal     = Check and Check:WaitForChild("Goal", 5)
    local ksLastVis = false

    if Check and Line and Goal then
        regConn(RunService.Heartbeat:Connect(function()
            if not Cfg.AutoPerfectGen then
                ksLastVis = Check.Visible
                return
            end

            local vis = Check.Visible

            if vis and not ksLastVis and ksWaiting then
                ksWaiting = false
                local delay = Cfg.GenDelayMin + math.random() * (Cfg.GenDelayMax - Cfg.GenDelayMin)

                task.delay(delay, function()
                    if not Cfg.AutoPerfectGen then return end
                    if not LP.Character then return end
                    local ci = LP.Character:FindFirstChild("CheckInterractable")
                    if not ci or not ci:GetAttribute("isRepairing") then return end

                    Line.Rotation = 109 + Goal.Rotation

                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end)
            end

            ksLastVis = vis
        end))
    end
end

-- ─────────────────────────────────────────────────────
-- LAYER 2: OUTGOING REMOTE METAMETHOD HOOK (FAILSAFE)
-- Automatically redirects any failed/neutral remote calls to "success"
-- ─────────────────────────────────────────────────────
local namecallHook = nil
pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        if method == "FireServer" and not checkcaller() then
            -- Intercept standard Generator QTE results
            if self == SkillCheckResult then
                if Cfg.AutoPerfectGen then
                    args[1] = "success"
                    args[2] = 1
                    return oldNamecall(self, table.unpack(args))
                end
            -- Intercept King's Scourge QTE results
            elseif self == KingScourgeHit then
                if Cfg.AutoPerfectGen then
                    args[2] = "success"
                    return oldNamecall(self, table.unpack(args))
                end
            end
        end

        return oldNamecall(self, ...)
    end))

    -- Save hook to be able to disable it on cleanups if required
    table.insert(Cleanups, function()
        -- Note: namecall hooks are persistent but dynamically controlled by Cfg.AutoPerfectGen
    end)
end)

-- ─────────────────────────────────────────────────────
-- VYPERS UI WINDOW
-- ─────────────────────────────────────────────────────
local Vypers = VypersLib

local Window = Vypers:CreateWindow({
    Title    = "[CURE] Violence District",
    SubTitle = "v1.0",
    Author   = "Multi Script • by ValleryBot",
    Size     = Vector2.new(620, 450),
    Accent   = Color3.fromRGB(255, 70, 70),
})
Window:SetToggleKey(Enum.KeyCode.RightShift)

Window:Tag({ Title = "Violence District", Color = Color3.fromRGB(255, 70, 70) })

table.insert(Cleanups, function()
    pcall(function()
        if Window and Window._gui then
            Window._gui:Destroy()
        elseif Window and Window._main then
            Window._main:Destroy()
        end
    end)
end)

local Tabs = {
    Main      = Window:CreateTab({ Title = "Main",      Icon = "home"      }),
    ESP       = Window:CreateTab({ Title = "ESP",       Icon = "eye"       }),
    Generator = Window:CreateTab({ Title = "Generator", Icon = "cpu"       }),
    Combat    = Window:CreateTab({ Title = "Combat",    Icon = "swords"    }),
    Crosshair = Window:CreateTab({ Title = "Crosshair", Icon = "crosshair" }),
    Config    = Window:CreateTab({ Title = "Config",    Icon = "settings"  }),
}

-- ── MAIN TAB ─────────────────────────────────────────
local secWelcome = Tabs.Main:CreateSection({ Title = "Welcome" })
secWelcome:CreateParagraph({
    Title = "Welcome!",
    Text  = "Press RightShift to toggle the UI.\nAll features are configured in their respective tabs.",
})
secWelcome:CreateTag({ Title = "Status", Text = "Loaded", Color = Color3.fromRGB(80, 190, 120) })

local secActions = Tabs.Main:CreateSection({ Title = "Quick Actions" })
secActions:CreateButton({
    Title       = "Refresh ESP",
    Description = "Re-scan all players & generators.",
    Icon        = "eye",
    Callback    = function()
        RefreshESP()
        Vypers:Notify({ Title = "ESP", Content = "ESP refreshed.", Type = "success", Duration = 3 })
    end,
})
secActions:CreateButton({
    Title       = "Rebuild Crosshair",
    Description = "Recreate crosshair with current settings.",
    Icon        = "crosshair",
    Callback    = function()
        BuildCrosshair()
        Vypers:Notify({ Title = "Crosshair", Content = "Crosshair rebuilt.", Type = "success", Duration = 3 })
    end,
})
secActions:CreateButton({
    Title       = "Unload Script",
    Description = "Clean up UI, ESP, crosshair & connections.",
    Color       = Color3.fromRGB(210, 80, 80),
    Callback    = function()
        Vypers:Dialog({
            Title   = "Unload",
            Content = "Are you sure you want to unload the script?",
            Buttons = {
                { Title = "Cancel",  Callback = function() end },
                { Title = "Unload", Callback = function()
                    if _G.VD_Cleanup then pcall(_G.VD_Cleanup) end
                end },
            },
        })
    end,
})

-- ── ESP TAB ──────────────────────────────────────────
local secEspMain = Tabs.ESP:CreateSection({ Title = "General" })
secEspMain:CreateToggle({
    Id = "ESPEnabled", Title = "Enable ESP", Default = Cfg.ESP_Enabled,
    Callback = function(state)
        Cfg.ESP_Enabled = state
        RefreshESP()
    end,
})
secEspMain:CreateToggle({
    Id = "ESPHighlight", Title = "Highlight (Chams)", Default = Cfg.ESP_Highlight,
    Callback = function(state)
        Cfg.ESP_Highlight = state
        RefreshESP()
    end,
})

local secEspTargets = Tabs.ESP:CreateSection({ Title = "Targets" })
secEspTargets:CreateToggle({
    Id = "ESPKiller", Title = "Show Killers", Default = Cfg.ESP_Killer,
    Callback = function(state) Cfg.ESP_Killer = state; RefreshESP() end,
})
secEspTargets:CreateToggle({
    Id = "ESPSurvivor", Title = "Show Survivors", Default = Cfg.ESP_Survivor,
    Callback = function(state) Cfg.ESP_Survivor = state; RefreshESP() end,
})
secEspTargets:CreateToggle({
    Id = "ESPSpectator", Title = "Show Spectators", Default = Cfg.ESP_Spectator,
    Callback = function(state) Cfg.ESP_Spectator = state; RefreshESP() end,
})
secEspTargets:CreateToggle({
    Id = "ESPGenerator", Title = "Show Generators", Description = "Includes live repair progress.",
    Default = Cfg.ESP_Generator,
    Callback = function(state) Cfg.ESP_Generator = state; RefreshESP() end,
})

local secEspInfo = Tabs.ESP:CreateSection({ Title = "Label Info" })
secEspInfo:CreateToggle({
    Id = "ESPNames", Title = "Show Names & Role", Default = Cfg.ESP_Names,
    Callback = function(state) Cfg.ESP_Names = state end,
})
secEspInfo:CreateToggle({
    Id = "ESPDistance", Title = "Show Distance", Default = Cfg.ESP_Distance,
    Callback = function(state) Cfg.ESP_Distance = state end,
})

-- ── GENERATOR TAB ────────────────────────────────────
local secGenInfo = Tabs.Generator:CreateSection({ Title = "Info" })
secGenInfo:CreateParagraph({
    Title = "Auto Perfect Generator",
    Text  = "Dual-layer system: snaps rotation + presses space. Outgoing fails/neutrals are hooked to succeed.",
})

local secGen = Tabs.Generator:CreateSection({ Title = "Settings" })
secGen:CreateToggle({
    Id = "AutoPerfectGen", Title = "Auto Perfect Generator", Default = Cfg.AutoPerfectGen,
    Callback = function(state) Cfg.AutoPerfectGen = state end,
})
secGen:CreateSlider({
    Id = "GenDelayMin", Title = "QTE Delay Min", Description = "Minimum humanized delay before firing success.",
    Min = 0.05, Max = 1.0, Increment = 0.01, Default = Cfg.GenDelayMin, Suffix = "s",
    Callback = function(v) Cfg.GenDelayMin = v end,
})
secGen:CreateSlider({
    Id = "GenDelayMax", Title = "QTE Delay Max", Description = "Maximum humanized delay before firing success.",
    Min = 0.1, Max = 1.5, Increment = 0.01, Default = Cfg.GenDelayMax, Suffix = "s",
    Callback = function(v) Cfg.GenDelayMax = v end,
})

-- ── COMBAT TAB ───────────────────────────────────────
local secCombatInfo = Tabs.Combat:CreateSection({ Title = "Info" })
secCombatInfo:CreateParagraph({
    Title = "Auto Parry",
    Text  = "Automatically parries when the killer plays an animation within range.\n⚠️ Requires Parrying Dagger in inventory or hand.",
})

local secCombat = Tabs.Combat:CreateSection({ Title = "Settings" })
secCombat:CreateToggle({
    Id = "AutoParry", Title = "Auto Parry", Default = Cfg.AutoParry,
    Callback = function(state) Cfg.AutoParry = state end,
})
secCombat:CreateToggle({
    Id = "AutoEquipDagger", Title = "Auto Equip Parrying Dagger",
    Description = "Equips dagger from backpack automatically if not held.",
    Default = Cfg.AutoEquip,
    Callback = function(state) Cfg.AutoEquip = state end,
})
secCombat:CreateSlider({
    Id = "ParryRange", Title = "Parry Range", Description = "Maximum distance from killer to trigger auto parry.",
    Min = 5, Max = 40, Increment = 1, Default = Cfg.ParryRange, Suffix = "studs",
    Callback = function(v) Cfg.ParryRange = v end,
})
secCombat:CreateSlider({
    Id = "ParryCooldown", Title = "Parry Cooldown", Description = "Minimum time between parry attempts.",
    Min = 0.5, Max = 5.0, Increment = 0.1, Default = Cfg.ParryCooldown, Suffix = "s",
    Callback = function(v) Cfg.ParryCooldown = v end,
})

local secCombatManual = Tabs.Combat:CreateSection({ Title = "Manual" })
secCombatManual:CreateButton({
    Title       = "Manual Parry",
    Description = "Manually fire the parry event right now.",
    Callback    = function()
        if ParryEvent then
            ParryEvent:FireServer()
            Vypers:Notify({ Title = "Parry", Content = "Parry event fired.", Type = "info", Duration = 2 })
        else
            Vypers:Notify({ Title = "Parry", Content = "Parry remote not found.", Type = "error", Duration = 4 })
        end
    end,
})
secCombatManual:CreateKeybind({
    Id = "ParryKey", Title = "Manual Parry Key", Default = Enum.KeyCode.V,
    Callback = function()
        if ParryEvent then ParryEvent:FireServer() end
    end,
})

-- ── CROSSHAIR TAB ────────────────────────────────────
local secCH = Tabs.Crosshair:CreateSection({ Title = "Crosshair" })
secCH:CreateToggle({
    Id = "CrosshairEnabled", Title = "Enable Crosshair", Default = Cfg.Crosshair,
    Callback = function(state) Cfg.Crosshair = state; BuildCrosshair() end,
})
secCH:CreateSlider({
    Id = "CHSize", Title = "Size", Min = 4, Max = 30, Increment = 1, Default = Cfg.CHSize, Suffix = "px",
    Callback = function(v) Cfg.CHSize = v; BuildCrosshair() end,
})
secCH:CreateSlider({
    Id = "CHGap", Title = "Gap", Min = 0, Max = 20, Increment = 1, Default = Cfg.CHGap, Suffix = "px",
    Callback = function(v) Cfg.CHGap = v; BuildCrosshair() end,
})
secCH:CreateSlider({
    Id = "CHThick", Title = "Thickness", Min = 1, Max = 6, Increment = 1, Default = Cfg.CHThick, Suffix = "px",
    Callback = function(v) Cfg.CHThick = v; BuildCrosshair() end,
})
secCH:CreateColorPicker({
    Id = "CHColor", Title = "Crosshair Color", Default = Cfg.CHColor,
    Callback = function(c) Cfg.CHColor = c; BuildCrosshair() end,
})

-- ── CONFIG TAB ───────────────────────────────────────
local secCfg = Tabs.Config:CreateSection({ Title = "Configuration" })
secCfg:CreateButton({
    Title = "Save Config",
    Callback = function()
        Vypers:SaveConfig("violence_district")
        Vypers:Notify({ Title = "Config", Content = "Settings saved.", Type = "success", Duration = 3 })
    end,
})
secCfg:CreateButton({
    Title = "Load Config",
    Callback = function()
        Vypers:LoadConfig("violence_district")
        Vypers:Notify({ Title = "Config", Content = "Settings loaded.", Type = "info", Duration = 3 })
    end,
})
secCfg:CreateToggle({
    Id = "AutoSaveCfg", Title = "Auto Save", Default = false,
    Callback = function(state) Vypers:AutoSave(state, "violence_district") end,
})
secCfg:CreateKeybind({
    Id = "ToggleUIKey", Title = "Toggle UI", Default = Enum.KeyCode.RightShift,
    Callback = function() Window:Toggle() end,
})

-- ─────────────────────────────────────────────────────
-- STARTUP
-- ─────────────────────────────────────────────────────
BuildCrosshair()
SetupAutoParry()
RefreshESP()

-- Respawn handler
regConn(LP.CharacterAdded:Connect(function()
    task.wait(2)
    RefreshESP()
end))

-- Persistent config (must be called AFTER every element is created)
pcall(function() Vypers:EnableConfig("violence_district") end)

Vypers:Notify({
    Title    = "[CURE] Violence District",
    Content  = "Script loaded! Press RightShift to toggle menu.",
    Type     = "success",
    Duration = 6,
})
