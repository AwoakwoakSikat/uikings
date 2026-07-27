local RAW_URL = "https://raw.githubusercontent.com/AwoakwoakSikat/uikings/refs/heads/main/VypersLib42.lua"
local Vypers  = loadstring(game:HttpGet(RAW_URL))()
-- Nonaktifkan print & warn untuk modul ini agar console tidak spam
local print = function(...) end
local warn = function(...) end
-- ================================================================
--  SETUP GLOBAL  (panggil SEBELUM CreateWindow)
-- ================================================================
Vypers:SetFolder("VypersDemo")                    -- folder tempat simpan config
Vypers:SetAccent(Color3.fromRGB(120, 90, 240))    -- warna aksen global
Vypers:SetTheme({                                 -- override warna theme apapun (opsional)
    -- Success = Color3.fromRGB(80, 200, 130),     -- contoh ganti warna "success"
    -- Text    = Color3.fromRGB(240, 240, 255),    -- contoh ganti warna teks
})

-- ================================================================
--  LOADING SCREEN DULU (SEBELUM CreateWindow!)
--  biar kartu progress udah kelihatan sebelum build UI yang berat.
-- ================================================================
Vypers:SetBuildBudget(4)   -- max 4ms kerja UI per frame -> game tetep smooth

local Loader = Vypers:CreateLoadingScreen({
    Title    = "King Vypers",
    SubTitle = "Menyiapkan antarmuka...",
    Accent   = Color3.fromRGB(120, 90, 240),
})
task.wait()   -- 1 frame biar loading screen kegambar dulu

local Window = Vypers:CreateWindow({
    Title           = "King Vypers",                     -- judul di kiri atas
    Icon            = "rbxassetid://107726435417936",    -- logo pas window di-minimize
    FloatIconRadius = 14,                               -- sudut logo minimize: 0 tajam | 14 squircle | 25 bulat
    SubTitle        = "FAM V0.5",                            -- badge kecil sebelah judul (alias: Version)
    Background      = "rbxassetid://97514324988224",     -- gambar backdrop window
    BackgroundTransparency = 0,                          -- transparansi gambar backdrop (0 = solid)
    Overlay         = 0.3,                               -- tint gelap di atas gambar (0 terang .. 1 gelap)
    Size            = UDim2.new(0, 560, 0, 360),         -- ukuran awal window
    MinSize         = Vector2.new(480, 300),             -- batas minimal resize
    MaxSize         = Vector2.new(720, 480),             -- batas maksimal resize
    SideBarWidth    = 150,                               -- lebar sidebar tab
    Resizable       = true,                              -- boleh di-resize (pojok kanan bawah)
    Transparent     = false,                              -- mode glass (nyalain transparansi default)

    -- --- transparansi tiap layer (0 = solid .. 1 = ilang total) ---
    SurfaceTransparency = 0.3,   -- card tiap element
    SectionTransparency = 0.3,  -- panel section
    TabTransparency     = 0.3,   -- tombol tab sidebar

    -- --- warna background item ---
    ItemColor    = Color3.fromRGB(40, 40, 60),   -- card element
    SectionColor = Color3.fromRGB(28, 28, 44),   -- panel section
    TabColor     = Color3.fromRGB(34, 34, 52),   -- tab sidebar
    WindowColor  = Color3.fromRGB(20, 20, 30),   -- warna dasar window
    Accent       = Color3.fromRGB(120, 90, 240), -- aksen (bisa juga lewat SetAccent)
    -- Theme      = { Surface = ..., Border = ... }, -- override penuh sekaligus

    ToggleKey   = Enum.KeyCode.RightShift,  -- tombol buat show/hide window
    Deferred    = true,  -- build UI hidden dulu, reveal setelah loading kelar
    Folder      = "VypersDemo",             -- folder config (sama kayak SetFolder)
})

-- ================================================================
--  LOADING SCREEN  (progress bar clean di pojok kanan bawah)
--  UI di-build hidden + kesebar antar-frame biar gak nge-frame;
--  window baru MUNCUL setelah semua keload (lihat bagian paling akhir).
-- ================================================================
-- (Loader udah dibuat di atas, sebelum CreateWindow)

-- ================================================================
--  TAG DI TITLE BAR  (pill kecil sebelah judul)
-- ================================================================
Window:Tag({ Title = "PREMIUM",   Color = Color3.fromRGB(220, 180, 70) })                 -- pill teks doang
Window:Tag({ Title = "Protected", Color = Color3.fromRGB(80, 190, 120) })  -- pill + icon
Window:Tag({ Title = "VypersUI V0.2", Color = Color3.fromRGB(80, 190, 120) })  -- pill + icon

-- Window:Tag({ Title = "NEW", Radius = 4 })   -- Radius atur sudut pill (default 9)

-- ================================================================
--  Fishing Tab
-- ================================================================
Loader:Set(0.1, "Fishing")
task.wait()
local FishingTab = Window:CreateTab({ Title = "Fishing", Icon = "fish" })
local InstantFish = FishingTab:CreateSection({ Title = "Instant Fishing", Opened = true })

local instantFishEnabled = false
local instantFishTask = nil
local instantFishDelay = 3

InstantFish:CreateInput({
    Id = "instant_fish_delay",
    Title = "Fish Delay",
    Placeholder = "Angka (Contoh: 3)",
    Default = tostring(instantFishDelay),
    Callback = function(input)
        local val = tonumber(input)
        if val then
            instantFishDelay = val
            print("[Instant Fish] Delay diatur ke: " .. val .. " detik")
        else
            print("[Instant Fish] Input delay tidak valid!")
        end
    end
})

InstantFish:CreateToggle({
    Id = "instant_fishing_toggle",
    Title = "Instant Fishing",
    Icon = "zap",
    Default = instantFishEnabled,
    Callback = function(state)
        instantFishEnabled = state
        if state then
            print("[Instant Fish] ON")
            Window:Notify({
                Title = "Instant Fishing Active",
                Content = "Jika ikan sering lepas, silakan naikkan Fish Delay!",
                Type = "warning",
                Duration = 4
            })
            
            instantFishTask = task.spawn(function()
                local RS = game:GetService("ReplicatedStorage")
                local LP = game:GetService("Players").LocalPlayer
                local Knit = RS.Packages._Index["sleitnick_knit@1.7.0"].knit.Services
                
                local FishingRF = Knit.FishingReplicationService.RF
                local RewardRF  = Knit.FishingRewardService.RF
                local RewardRE  = Knit.FishingRewardService.RE
                
                local START_FISHING      = FishingRF.StartFishing
                local THROW_FLOATER      = FishingRF.ThrowFloater
                local CONFIRM_CAST       = FishingRF.ConfirmFloatingCast
                local REQUEST_FISH_BITE  = RewardRF.RequestFishBite
                local START_PULLING      = FishingRF.StartPulling
                local FISHING_PULL_INPUT = RewardRF.FishingPullInput
                local STOP_FISHING       = FishingRF.StopFishing
                local PULL_STATE_EVENT   = RewardRE:WaitForChild("FishingPullState")
                
                local FLOATER = "Floater_Doll"
                local FLOATER_PROPS = {
                    LightInfluence = 0,
                    Transparency   = 0.12,
                    LightEmission  = 0.6,
                    Color          = Color3.new(0, 1, 1),
                    FaceCamera     = true,
                    Width          = 0.16
                }
                
                local function getCastPos()
                    local char = LP.Character or LP.CharacterAdded:Wait()
                    local hrp = char:WaitForChild("HumanoidRootPart")
                    local playerPos = hrp.Position
                    local lookDir = hrp.CFrame.LookVector
                    local targetXZ = playerPos + (lookDir * 15)
                    
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {char}
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    rayParams.IgnoreWater = false
                    
                    local origin = targetXZ + Vector3.new(0, 15, 0)
                    local result = workspace:Raycast(origin, Vector3.new(0, -100, 0), rayParams)
                    local castPos = result and result.Position or (targetXZ + Vector3.new(0, -8, 0))
                    
                    local tool = char:FindFirstChildOfClass("Tool")
                    local rodName = tool and tool.Name or "BananaRod"
                    return playerPos, castPos, rodName
                end
                
                local isResolved = false
                local activeSessionId = nil
                local lastTooEarlyNotify = 0
                
                local function notifyTooEarly()
                    local now = tick()
                    if now - lastTooEarlyNotify > 5 then
                        lastTooEarlyNotify = now
                        Window:Notify({
                            Title = "Ikan Lepas!",
                            Content = "Fish delay terlalu cepat. Silakan naikkan Fish Delay.",
                            Type = "error",
                            Duration = 4
                        })
                    end
                end
                
                local resolvedConn
                resolvedConn = PULL_STATE_EVENT.OnClientEvent:Connect(function(data)
                    if type(data) == "table" then
                        if data.sessionId and data.type == "resolved" and data.sessionId == activeSessionId then
                            isResolved = true
                        elseif data.type == "cancelled" or data.type == "failed" or (data.reason and tostring(data.reason):lower():find("early")) then
                            notifyTooEarly()
                        end
                    end
                end)
                
                while instantFishEnabled do
                    if shared.isDoingEvent then task.wait(1) continue end
                    
                    isResolved = false
                    activeSessionId = nil
                    local playerPos, castPos, rodName = getCastPos()
                    
                    pcall(function() START_FISHING:InvokeServer(rodName, FLOATER) end)
                    pcall(function() THROW_FLOATER:InvokeServer(playerPos, castPos, rodName, FLOATER, FLOATER_PROPS, 10) end)
                    pcall(function() CONFIRM_CAST:InvokeServer(castPos) end)
                    
                    local sessionId = nil
                    local ok, result = pcall(function() return REQUEST_FISH_BITE:InvokeServer(castPos) end)
                    if ok and type(result) == "table" and result.SessionId then
                        sessionId = result.SessionId
                        activeSessionId = sessionId
                        print("[Instant Fish] Session:", sessionId)
                    else
                        print("[Instant Fish] RequestFishBite gagal / tidak ada session (Too Early!).")
                        notifyTooEarly()
                    end
                    
                    task.wait(instantFishDelay)
                    
                    pcall(function() START_PULLING:InvokeServer() end)
                    
                    if sessionId then
                        pcall(function() FISHING_PULL_INPUT:InvokeServer(sessionId, "begin") end)
                        local waitStart = tick()
                        while not isResolved and instantFishEnabled and tick() - waitStart < 15 do
                            task.spawn(function()
                                pcall(function() FISHING_PULL_INPUT:InvokeServer(sessionId, "tap") end)
                            end)
                            task.wait()
                        end
                        print("[Instant Fish] Selesai! resolved:", isResolved)
                    else
                        print("[Instant Fish] Gagal dapet SessionId, skip...")
                    end
                    
                    pcall(function() STOP_FISHING:InvokeServer() end)
                end
                
                resolvedConn:Disconnect()
            end)
        else
            print("[Instant Fish] OFF")
            instantFishEnabled = false
            if instantFishTask then
                task.cancel(instantFishTask)
                instantFishTask = nil
            end
        end
    end
})

-- ================================================================
--  Legit Fish Section
-- ================================================================
local LegitFishSection = FishingTab:CreateSection({ Title = "Legit Fish", Box = true, Opened = false })

local legitFishingEnabled = false
local legitFishingTask = nil

LegitFishSection:CreateToggle({
    Id = "legit_fishing_toggle",
    Title = "Legit Fishing",
    Icon = "fish",
    Default = false,
    Callback = function(state)
        legitFishingEnabled = state
        if state then
            print("[Legit Fish] ON")
            Window:Notify({
                Title = "Legit Fishing Active",
                Content = "Sedang menjalankan mode Legit Fishing!",
                Type = "success",
                Duration = 3
            })
            
            -- ⏱️ DELAY 1 DETIK CUMA DI SINI (sebelum spawn, cuma sekali)
            task.wait(1)
            print("[Legit Fish] Delay 1 detik selesai, mulai mancing!")
            
            legitFishingTask = task.spawn(function()
                local player = game:GetService("Players").LocalPlayer
                local char = player.Character or player.CharacterAdded:Wait()
                local VIM = game:GetService("VirtualInputManager")
                local Knit = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.7.0"].knit.Services
                local ReplicationRF = Knit.FishingReplicationService.RF
                local RewardRF = Knit.FishingRewardService.RF
                local RewardRE = Knit.FishingRewardService.RE
                
                -- Auto detect
                local reelButton = player.PlayerGui.FishingMobile:FindFirstChild("ReelButton")
                local IS_MOBILE = reelButton ~= nil
                print(IS_MOBILE and "Mobile detected!" or "PC detected!")
                
                local currentUUID = nil
                local isPulling = false
                local castSuccess = false
                local castFailed = false
                
                -- Listen FishCaught
                local caughtConn = RewardRE.FishCaught.OnClientEvent:Connect(function(data)
                    if data then
                        print("[CAUGHT]", data.FishID, "|", data.Weight, "Kg")
                    end
                    isPulling = false
                end)
                
                -- Hook ConfirmFloatingCast + StopFishing via __namecall
                local ConfirmRF = Knit.FishingReplicationService.RF.ConfirmFloatingCast
                local StopRF = Knit.FishingReplicationService.RF.StopFishing
                local mt = getrawmetatable(game)
                local oldNamecall = mt.__namecall
                setreadonly(mt, false)
                mt.__namecall = function(self, ...)
                    local method = getnamecallmethod()
                    if self == ConfirmRF and method == "InvokeServer" then
                        castSuccess = true
                        print("[Cast Sukses! ConfirmFloatingCast datang]")
                    elseif self == StopRF and method == "InvokeServer" then
                        castFailed = true
                        print("[Cast Gagal! StopFishing datang]")
                    end
                    return oldNamecall(self, ...)
                end
                setreadonly(mt, true)
                
                -- Langsung masuk loop, TANPA delay lagi
                while legitFishingEnabled do
                    castSuccess = false
                    castFailed = false
                    currentUUID = nil
                    isPulling = false
                    
                    -- [1] Cek dan equip rod
                    local equippedTool = char:FindFirstChildOfClass("Tool")
                    if equippedTool then
                        print("[1] Sudah pegang rod:", equippedTool.Name)
                    else
                        print("[1] Belum pegang rod, equip slot 1...")
                        VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                        task.wait(0.1)
                        VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
                        task.wait(0.5)
                        print("[1] Slot 1 equipped!")
                    end
                    
                    -- [2] Cast loop sampai sukses
                    local fillbar = player.PlayerGui.FishingPanel.ThrowFrame.FillContainer.Fillbar
                    repeat
                        if not legitFishingEnabled then break end
                        castSuccess = false
                        castFailed = false
                        currentUUID = nil
                        print("[2] Casting...")
                        if IS_MOBILE then
                            firesignal(reelButton.MouseButton1Down)
                        else
                            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        end
                        
                        local maxFillWait = 0
                        repeat 
                            task.wait(0.05) 
                            maxFillWait += 0.05
                        until fillbar.Size.Y.Scale >= 0.99 or castFailed or not legitFishingEnabled or maxFillWait > 3
                        
                        if IS_MOBILE then
                            firesignal(reelButton.MouseButton1Up)
                        else
                            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        end
                        
                        local timeout = 0
                        while not castSuccess and not castFailed and timeout < 10 and legitFishingEnabled do
                            task.wait(0.1)
                            timeout += 0.1
                        end
                        
                        if castFailed then
                            print("[Cast Gagal! StopFishing detected, retry...")
                            task.wait(1)
                        elseif not castSuccess then
                            print("[Cast Gagal] Timeout 10 detik, retry...")
                        end
                    until castSuccess or not legitFishingEnabled
                    
                    if not legitFishingEnabled then break end
                    print("[3] Cast done! Waiting fish...")
                    
                    -- [3] Tunggu UUID pake event
                    local uuidEvent = Instance.new("BindableEvent")
                    local uuidConn
                    uuidConn = RewardRE.FishingPullState.OnClientEvent:Connect(function(data)
                        if data and data.sessionId and currentUUID == nil then
                            currentUUID = data.sessionId
                            print("[UUID]", currentUUID)
                            uuidConn:Disconnect()
                            uuidEvent:Fire()
                        end
                    end)
                    
                    local uuidTimeout = task.delay(15, function()
                        uuidEvent:Fire()
                    end)
                    uuidEvent.Event:Wait()
                    uuidEvent:Destroy()
                    pcall(function() task.cancel(uuidTimeout) end)
                    
                    if currentUUID == nil then
                        print("[ERROR] UUID timeout!")
                        if not legitFishingEnabled then break end
                        task.wait(1)
                        continue
                    end
                    
                    -- [4] Pull instant
                    print("[4] Pulling UUID:", currentUUID)
                    isPulling = true
                    
                    local isResolved = false
                    local resolvedConn2
                    resolvedConn2 = RewardRE.FishingPullState.OnClientEvent:Connect(function(data)
                        if type(data) == "table" and data.sessionId == currentUUID and data.type == "resolved" then
                            isResolved = true
                            isPulling = false
                        end
                    end)
                    
                    RewardRF.FishingPullInput:InvokeServer(currentUUID, "begin")
                    task.wait(0.05)
                    
                    local pullStart = tick()
                    while isPulling and legitFishingEnabled and tick() - pullStart < 15 do
                        task.spawn(function()
                            for i = 1, 5 do
                                pcall(function() RewardRF.FishingPullInput:InvokeServer(currentUUID, "tap") end)
                            end
                        end)
                        task.wait()
                    end
                    resolvedConn2:Disconnect()
                    print("[5] Done! Looping...")
                    task.wait(3)
                end
                
                -- Cleanup
                caughtConn:Disconnect()
                setreadonly(mt, false)
                mt.__namecall = oldNamecall
                setreadonly(mt, true)
                print("[Legit Fish] OFF")
            end)
        else
            print("[Legit Fish] Stopping...")
            legitFishingEnabled = false
            if legitFishingTask then
                task.cancel(legitFishingTask)
                legitFishingTask = nil
            end
        end
    end
})
local autoMinigameEnabled = false
local autoMinigameConnUUID = nil
local autoMinigameConnCaught = nil

LegitFishSection:CreateToggle({
    Id = "auto_minigame_only_toggle",
    Title = "Auto Minigame Only",
    Icon = "gamepad-2",
    Default = false,
    Callback = function(state)
        autoMinigameEnabled = state
        local Knit = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.7.0"].knit.Services
        local RewardRF = Knit.FishingRewardService.RF
        local RewardRE = Knit.FishingRewardService.RE
        
        if state then
            print("[Auto Minigame] ON")
            Window:Notify({
                Title = "Auto Minigame Active",
                Content = "Hanya akan menjalankan minigame saat casting manual!",
                Type = "info",
                Duration = 3
            })
            
            local isPulling = false
            local pullTask = nil
            
            autoMinigameConnCaught = RewardRE.FishCaught.OnClientEvent:Connect(function(data)
                isPulling = false
                if pullTask then
                    task.cancel(pullTask)
                    pullTask = nil
                end
                print("[Auto Minigame] Ikan ketangkep!")
            end)
            
            autoMinigameConnUUID = RewardRE.FishingPullState.OnClientEvent:Connect(function(data)
                if data and data.sessionId and autoMinigameEnabled then
                    local currentUUID = data.sessionId
                    print("[Auto Minigame] Minigame mulai! UUID:", currentUUID)
                    isPulling = true
                    RewardRF.FishingPullInput:InvokeServer(currentUUID, "begin")
                    pullTask = task.spawn(function()
                        while isPulling and autoMinigameEnabled do
                            RewardRF.FishingPullInput:InvokeServer(currentUUID, "tap")
                            task.wait()
                        end
                    end)
                end
            end)
        else
            print("[Auto Minigame] OFF")
            if autoMinigameConnUUID then 
                autoMinigameConnUUID:Disconnect() 
                autoMinigameConnUUID = nil 
            end
            if autoMinigameConnCaught then 
                autoMinigameConnCaught:Disconnect() 
                autoMinigameConnCaught = nil 
            end
        end
    end
})


-- ================================================================
--  Support Fishing Section
-- ================================================================
local SupportFishSection = FishingTab:CreateSection({ Title = "Support Fishing", Box = true, Opened = false })

-- =============================================
-- HIDE FISH CAUGHT UI MODULE (PERMANENT HIDE)
-- =============================================
local HideFishCaught = (function()
    local M = { Enabled = false }
    local lp = game:GetService("Players").LocalPlayer
    local PlayerGui = lp:WaitForChild("PlayerGui")

    local targets = {
        { gui = "NewFishDiscovery_Display", name = "FishImg" },
        { gui = "NewFishDiscovery",         name = "FishImg" },
        { gui = "NewFishDiscovery_Display", name = "ShineImg" },
        { gui = "NewFishDiscovery",         name = "ShineImg" },
        { gui = "NewFishDiscovery_Display", name = "Viginatte" },
        { gui = "NewFishDiscovery",         name = "Viginatte" },
    }

    local function setVisibility(state)
        -- 1. Hide/Show main targets (Fish, Shine, Vignette)
        for _, t in ipairs(targets) do
            local gui = PlayerGui:FindFirstChild(t.gui)
            if gui then
                local obj = gui:FindFirstChild(t.name, true)
                if obj then
                    obj.Visible = state
                    if state == false then
                        print("[DDS] Hidden:", t.gui, "->", t.name)
                    else
                        print("[DDS] Restored:", t.gui, "->", t.name)
                    end
                end
            end
        end

        -- 2. Hide/Show Hotbar icons
        local hotbar = PlayerGui:FindFirstChild("HotbarGUI")
        if hotbar then
            local container = hotbar:FindFirstChild("HotbarContainer")
            if container then
                for _, slot in ipairs(container:GetChildren()) do
                    if slot:IsA("Frame") and slot.Name:find("Slot") then
                        local btn = slot:FindFirstChild("Button")
                        if btn then
                            local icon = btn:FindFirstChild("Icon")
                            if icon then
                                icon.Visible = state
                            end
                        end
                    end
                end
            end
        end
        
        if state == false then
            print("[DDS] Done! Semua gambar ikan permanen hidden!")
        else
            print("[DDS] Done! Semua gambar ikan dikembalikan!")
        end
    end

    function M.Start()
        if M.Enabled then return end
        M.Enabled = true
        setVisibility(false) -- Langsung hide semua
        Window:Notify({ 
            Title = "Anti Lag Active", 
            Content = "Semua gambar & efek ikan disembunyikan permanen!", 
            Type = "success", 
            Duration = 3 
        })
    end
    
    function M.Stop()
        if not M.Enabled then return end
        M.Enabled = false
        setVisibility(true) -- Balikin lagi kalau dimatikan
        Window:Notify({ 
            Title = "Anti Lag Disabled", 
            Content = "Tampilan ikan dikembalikan ke normal.", 
            Type = "info", 
            Duration = 3 
        })
    end
    
    return M
end)()

SupportFishSection:CreateToggle({
    Id = "hide_fish_caught_ui_toggle",
    Title = "Disable Fish Notification",
    Icon = "eye-off",
    Default = false,
    Callback = function(state)
        if state then
            HideFishCaught.Start()
        else
            HideFishCaught.Stop()
        end
    end
})

-- =============================================
-- AUTO EQUIP ROD MODULE
-- =============================================
local AutoEquipRod = (function()
    local M = {
        Enabled = false,
        Thread = nil,
    }
    
    function M.Start()
        if M.Enabled then return end
        M.Enabled = true
        print("[AutoEquipRod] ON")
        Window:Notify({ Title = "Auto Equip Rod Active", Content = "Otomatis mengequip rod jika tangan kosong.", Type = "info", Duration = 3 })
        
        M.Thread = task.spawn(function()
            local LP = game:GetService("Players").LocalPlayer
            while M.Enabled do
                local char = LP.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local equippedTool = char:FindFirstChildOfClass("Tool")
                    
                    if hum and not equippedTool then
                        local backpack = LP:FindFirstChild("Backpack")
                        if backpack then
                            local rod = nil
                            for _, item in ipairs(backpack:GetChildren()) do
                                if item:IsA("Tool") and item.Name:lower():find("rod") then
                                    rod = item
                                    break
                                end
                            end
                            
                            if not rod then
                                rod = backpack:FindFirstChildOfClass("Tool")
                            end
                            
                            if rod then
                                hum:EquipTool(rod)
                                print("[AutoEquipRod] Equip:", rod.Name)
                            end
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end
    
    function M.Stop()
        if not M.Enabled then return end
        M.Enabled = false
        if M.Thread then
            task.cancel(M.Thread)
            M.Thread = nil
        end
        print("[AutoEquipRod] OFF")
        Window:Notify({ Title = "Auto Equip Rod Deactivated", Content = "Fitur auto equip rod dimatikan.", Type = "success", Duration = 3 })
    end
    
    return M
end)()

SupportFishSection:CreateToggle({
    Id = "auto_equip_rod_toggle",
    Title = "Auto Equip Rod",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        if state then
            AutoEquipRod.Start()
        else
            AutoEquipRod.Stop()
        end
    end
})

-- =============================================
-- WALK ON WATER MODULE
-- =============================================
local WalkOnWater = (function()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local M = { Enabled = false, Platform = nil, AlignPos = nil, Connection = nil }
    local PLATFORM_SIZE = 14
    local OFFSET = 2.5
    local WATER_Y = nil
    local TICK = 0
    local SCAN_INTERVAL = 10
    
    local function getChar()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        return char, hum, hrp
    end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = false
    
    local function isAboveWater(hrp)
        rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
        local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -50, 0), rayParams)
        if result and result.Instance:IsA("Terrain") then
            return result.Material == Enum.Material.Water
        end
        return false
    end
    
    local function scanWaterY(hrp)
        rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
        local result = Workspace:Raycast(
            hrp.Position + Vector3.new(0, 100, 0),
            Vector3.new(0, -500, 0),
            rayParams
        )
        if result and result.Instance:IsA("Terrain") and result.Material == Enum.Material.Water then
            return result.Position.Y
        end
        return nil
    end
    
    local function createPlatform()
        if M.Platform then M.Platform:Destroy() end
        local p = Instance.new("Part")
        p.Name = "WaterLockPlatform"
        p.Size = Vector3.new(PLATFORM_SIZE, 1, PLATFORM_SIZE)
        p.Anchored = true
        p.CanCollide = true
        p.CanQuery = false
        p.CanTouch = false
        p.Transparency = 1
        p.Parent = Workspace
        M.Platform = p
    end
    
    local function setupAlign(hrp)
        if M.AlignPos then M.AlignPos:Destroy() end
        local att = hrp:FindFirstChild("WOW_Att") or Instance.new("Attachment")
        att.Name = "WOW_Att"
        att.Parent = hrp
        local ap = Instance.new("AlignPosition")
        ap.Attachment0 = att
        ap.MaxForce = math.huge
        ap.MaxVelocity = math.huge
        ap.Responsiveness = 200
        ap.RigidityEnabled = true
        ap.Parent = hrp
        M.AlignPos = ap
    end
    
    local function cleanup()
        if M.Connection then M.Connection:Disconnect() M.Connection = nil end
        if M.AlignPos then M.AlignPos:Destroy() M.AlignPos = nil end
        if M.Platform then M.Platform:Destroy() M.Platform = nil end
        WATER_Y = nil
        TICK = 0
    end
    
    function M.Start()
        if M.Enabled then return end
        local _, hum, hrp = getChar()
        if not hum or not hrp then
            print("[WOW] Karakter tidak ditemukan!")
            return
        end
        M.Enabled = true
        createPlatform()
        setupAlign(hrp)
        print("[WOW] ON")
        Window:Notify({ Title = "Walk on Water Active", Content = "Kamu sekarang bisa berjalan di atas air!", Type = "info", Duration = 3 })
        
        M.Connection = RunService.Heartbeat:Connect(function()
            if not M.Enabled then return end
            local _, curHum, curHRP = getChar()
            if not curHum or not curHRP then return end
            local pos = curHRP.Position
            TICK += 1
            
            if curHum:GetState() == Enum.HumanoidStateType.Swimming then
                curHRP.Velocity = Vector3.new(curHRP.Velocity.X, 60, curHRP.Velocity.Z)
            end
            
            if TICK % SCAN_INTERVAL == 0 then
                local y = scanWaterY(curHRP)
                if y then WATER_Y = y end
            end
            
            local aboveWater = isAboveWater(curHRP)
            if aboveWater and WATER_Y then
                M.Platform.CFrame = CFrame.new(pos.X, WATER_Y - 0.5, pos.Z)
                M.AlignPos.Position = Vector3.new(pos.X, WATER_Y + OFFSET, pos.Z)
            else
                M.Platform.CFrame = CFrame.new(pos.X, -9999, pos.Z)
                M.AlignPos.Position = pos
            end
        end)
    end
    
    function M.Stop()
        M.Enabled = false
        cleanup()
        print("[WOW] OFF")
        Window:Notify({ Title = "Walk on Water Deactivated", Content = "Fitur berjalan di atas air dimatikan.", Type = "success", Duration = 3 })
    end
    
    LocalPlayer.CharacterAdded:Connect(function()
        if M.Enabled then
            task.wait(0.5)
            cleanup()
            M.Enabled = false
            M.Start()
        end
    end)
    
    return M
end)()

SupportFishSection:CreateToggle({
    Id = "walk_on_water_toggle",
    Title = "Walk on Water",
    Icon = "waves",
    Default = false,
    Callback = function(state)
        if state then
            WalkOnWater.Start()
        else
            WalkOnWater.Stop()
        end
    end
})

-- =============================================
-- NOCLIP MODULE
-- =============================================
local noclipEnabled = false
local noclipConn = nil

local function setNoclip(state)
    noclipEnabled = state
    if state then
        noclipConn = game:GetService("RunService").Stepped:Connect(function()
            local char = game:GetService("Players").LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
        Window:Notify({ Title = "Noclip Active", Content = "Kamu sekarang bisa menembus objek!", Type = "info", Duration = 3 })
    else
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
        local char = game:GetService("Players").LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = part:IsA("MeshPart") or part.Name == "HumanoidRootPart" and false or true
                end
            end
        end
        Window:Notify({ Title = "Noclip Deactivated", Content = "CanCollide telah dikembalikan ke normal.", Type = "success", Duration = 3 })
    end
end

SupportFishSection:CreateToggle({
    Id = "noclip_toggle",
    Title = "Noclip",
    Icon = "ghost",
    Default = false,
    Callback = function(state)
        setNoclip(state)
    end
})
-- ================================================================
--  Shop Tab
-- ================================================================
Loader:Set(0.25, "Shop")
task.wait()
local ShopTab = Window:CreateTab({ Title = "Shop", Icon = "fish" })
local AutoSellFish = ShopTab:CreateSection({ Title = "Auto Sell Fish", Opened = true })

-- =============================================
-- AUTO SELL MODULE
-- =============================================
local selectedRarities = {}
local autoSellInterval = 35 -- Default in minutes
local autoSellEnabled = false
local autoSellTask = nil

AutoSellFish:CreateMultiDropdown({
    Id = "auto_sell_rarity",
    Title = "Pilih Rarity",
    Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary" },
    Default = {},
    Callback = function(selected)
        selectedRarities = {}
        if type(selected) == "table" then
            for _, rarity in ipairs(selected) do
                selectedRarities[rarity] = true
            end
        end
        print("[Auto Sell] Rarity dipilih:", #selected > 0 and table.concat(selected, ", ") or "All")
    end
})

AutoSellFish:CreateInput({
    Id = "auto_sell_interval",
    Title = "Auto Sell (Minutes)",
    Placeholder = "30",
    Default = tostring(autoSellInterval),
    Callback = function(text)
        local val = tonumber(text)
        if val and val > 0 then
            autoSellInterval = val
            print("[Auto Sell] Interval diatur ke:", val, "menit")
        else
            print("[Auto Sell] Input interval tidak valid!")
        end
    end
})

local function ExecuteSell()
    print("[AutoSell] Memulai Auto Sell (GUI Method)...")
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService") -- Panggil TweenService
    local LP = Players.LocalPlayer
    local PlayerGui = LP:FindFirstChild("PlayerGui")
    local RS = game:GetService("ReplicatedStorage")
    local Knit = RS.Packages._Index["sleitnick_knit@1.7.0"].knit.Services
    local FISH_SOLD = Knit.FishermanShopService.RE.FishSold
    
    local function waitForUI()
        print("⏳ Nunggu FishermanShopGUI kebuka...")
        local gui = PlayerGui:WaitForChild("FishermanShopGUI", 10)
        if not gui then
            print("❌ FishermanShopGUI ga muncul!")
            return false
        end
        print("✅ UI kebuka!")
        return true
    end
    
    local function clickButton(btn, name)
        local success = false
        while not success do
            local ok, err = pcall(function()
                firesignal(btn.MouseButton1Click)
            end)
            if ok then
                print("✅ Klik " .. name .. " berhasil!")
                success = true
            else
                print("❌ Gagal klik " .. name .. ":", err, "| Mencoba lagi...")
                task.wait(0.5)
            end
        end
        task.wait(0.5)
    end
    
    local character = LP.Character or LP.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local originalCFrame = nil
    
    if hrp then
        originalCFrame = hrp.CFrame
        print("[AutoSell] Tween ke lokasi sell...")
        
        local targetPosition = nil
        
        if game.PlaceId == 90457367396205 then
            -- Map 2 logic
            local hud = LP.PlayerGui:FindFirstChild("HUD")
            local statsPanel = hud and hud:FindFirstChild("PlayerStatsPanel", true)
            local levelLabel = statsPanel and statsPanel:FindFirstChild("LevelLabel", true)
            local level = 0
            if levelLabel then
                level = tonumber(levelLabel.Text:match("%d+")) or 0
            end
            local unlockIslands = {
                { name = "Bamboo",            pos = Vector3.new(-1119.28, 227.39, 256.52),    unlockLevel = 1  },
                { name = "Iceberg",           pos = Vector3.new(-521.57, 309.43, -818.11),    unlockLevel = 1  },
                { name = "Lost Whale Island", pos = Vector3.new(-2470.06, 65.96, -89.39),     unlockLevel = 10 },
                { name = "Bora Reef",         pos = Vector3.new(-3774.61, 200.02, 2078.67),   unlockLevel = 20 },
                { name = "Volcano Vent",      pos = Vector3.new(-1855.89, 316.16, 6046.96),   unlockLevel = 30 },
                { name = "Cape Town",         pos = Vector3.new(1259.36, 214.58, 2513.89),    unlockLevel = 35 },
            }
            local sellLocations = {
                Vector3.new(-605.20, 172.88, 25.43),
                Vector3.new(-2660.34, 172.12, 203.34),
                Vector3.new(-1409.31, 173.55, 400.75),
                Vector3.new(804.61, 187.62, 2952.89),
                Vector3.new(-3996.39, 171.44, 2028.85),
                Vector3.new(-1686.41, 173.81, 5931.25),
            }
            local validSellLocs = {}
            for _, sell in ipairs(sellLocations) do
                local nearest, nearestDist = nil, math.huge
                for _, island in ipairs(unlockIslands) do
                    local dist = (sell - island.pos).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = island
                    end
                end
                if nearest and level >= nearest.unlockLevel then
                    table.insert(validSellLocs, sell)
                end
            end
            local bestSellLoc = nil
            local bestDist = math.huge
            for _, loc in ipairs(validSellLocs) do
                local dist = (hrp.Position - loc).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestSellLoc = loc
                end
            end
            
            if bestSellLoc then
                targetPosition = bestSellLoc + Vector3.new(0, 15, 0)
            else
                targetPosition = sellLocations[1] + Vector3.new(0, 15, 0)
            end
        else
            -- Default / Map 1 logic (111385005478215)
            targetPosition = Vector3.new(280.2694396972656, 201.01766967773438 + 15, 1551.6795654296875)
        end
        
        -- Eksekusi Tween ke Lokasi Sell
        if targetPosition then
            local randomTime = math.random(30, 70) / 10 -- Random waktu antara 3.0 sampai 7.0 detik
            print("[AutoSell] Waktu tween ke shop: " .. randomTime .. " detik")
            
            local tweenInfo = TweenInfo.new(randomTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPosition)})
            tween:Play()
            tween.Completed:Wait() -- Tunggu sampai tween selesai
            task.wait(0.5) -- Kasih jeda dikit biar server sync posisi akhir
            print("✅ Sampai di lokasi sell!")
        end
    end
    
    local prompt = nil
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.ActionText == "Sell Fish" then
            prompt = v
            break
        end
    end
    
    if not prompt then
        print("❌ Prompt Sell Fish ga ketemu!")
        Window:Notify({ Title = "Auto Sell", Content = "Prompt Sell Fish tidak ditemukan!", Type = "error", Duration = 4 })
        if hrp and originalCFrame then 
            -- Tween balik kalau prompt ga ketemu
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
            TweenService:Create(hrp, tweenInfo, {CFrame = originalCFrame}):Play()
        end
        return
    end
    
    print("🐟 Trigger Sell Fish...")
    local uiOpened = false
    while not uiOpened do
        fireproximityprompt(prompt)
        uiOpened = waitForUI()
        if not uiOpened then
            print("⚠️ UI Sell belum terbuka, mencoba fire proximity prompt lagi...")
            task.wait(1)
        end
    end
    
    task.wait(0.5)
    local ShopPanel = PlayerGui.FishermanShopGUI.ShopPanel
    local CartPanel = PlayerGui.FishermanShopGUI.CartPanel
    
    -- Listen FishSold sebelum klik confirm
    local sellDone = false
    local totalEarned = 0
    local soldConn
    soldConn = FISH_SOLD.OnClientEvent:Connect(function(data)
        sellDone = true
        totalEarned = data.Earned or 0
        print("💰 FishSold! Earned:", data.Earned, "| NewMoney:", data.NewMoney, "| Quantity:", data.Quantity)
        if data.SoldFish then
            for _, fish in ipairs(data.SoldFish) do
                print("   🐟", fish.Name, "x" .. fish.Count, "| Value:", fish.Value)
            end
        end
        soldConn:Disconnect()
    end)
    
    -- Step 1: Filter by selected rarities or "All"
    local validRarities = {"All", "Common", "Epic", "Legendary", "Rare", "Uncommon"}
    local raritiesToSell = {}
    for _, rarity in ipairs(validRarities) do
        if selectedRarities[rarity] then
            table.insert(raritiesToSell, rarity)
        end
    end
    
    if #raritiesToSell > 0 then
        for _, rarity in ipairs(raritiesToSell) do
            local filterBtnName = "Filter_" .. rarity
            local filterBtn = ShopPanel.FilterFrame:FindFirstChild(filterBtnName)
            while not filterBtn do
                print("⏳ Menunggu tombol " .. filterBtnName .. "...")
                task.wait(0.5)
                filterBtn = ShopPanel.FilterFrame:FindFirstChild(filterBtnName)
            end
            clickButton(filterBtn, filterBtnName)
            
            -- Insert to cart
            local sellAllBtn = ShopPanel.ActionBar.BtnFrame:FindFirstChild("SellAll")
            while not sellAllBtn do
                task.wait(0.5)
                sellAllBtn = ShopPanel.ActionBar.BtnFrame:FindFirstChild("SellAll")
            end
            clickButton(sellAllBtn, "SellAll (Add to cart for " .. rarity .. ")")
        end
    else
        local filterAllBtn = ShopPanel.FilterFrame:FindFirstChild("Filter_All")
        while not filterAllBtn do
            task.wait(0.5)
            filterAllBtn = ShopPanel.FilterFrame:FindFirstChild("Filter_All")
        end
        clickButton(filterAllBtn, "Filter_All")
        
        local sellAllBtn = ShopPanel.ActionBar.BtnFrame:FindFirstChild("SellAll")
        while not sellAllBtn do
            task.wait(0.5)
            sellAllBtn = ShopPanel.ActionBar.BtnFrame:FindFirstChild("SellAll")
        end
        clickButton(sellAllBtn, "SellAll")
    end
    
    -- Step 2: ViewCart
    clickButton(ShopPanel.ActionBar.BtnFrame.ViewCart, "ViewCart")
    
    -- Step 3: ConfirmSell
    clickButton(CartPanel.CartActionFrame.ConfirmSellBtn, "ConfirmSellBtn")
    
    -- Tunggu FishSold event max 5 detik
    local timeout = tick()
    while not sellDone and tick() - timeout < 5 do
        task.wait(0.1)
    end
    
    if sellDone then
        print("🏁 Auto Sell selesai! Total earned:", totalEarned)
        Window:Notify({ 
            Title = "Auto Sell", 
            Content = "Berhasil jual ikan! Earned: $" .. tostring(totalEarned), 
            Type = "success", 
            Duration = 4 
        })
    else
        print("⚠️ FishSold event ga kedetect, mungkin inventory kosong?")
        soldConn:Disconnect()
    end
    
    -- Tween kembali ke posisi awal
    if hrp and originalCFrame then
        print("[AutoSell] Tween kembali ke posisi awal...")
        task.wait(0.5)
        
        local randomTimeReturn = math.random(20, 50) / 10 -- Random waktu antara 2.0 sampai 5.0 detik
        print("[AutoSell] Waktu tween kembali: " .. randomTimeReturn .. " detik")
        
        local tweenInfo = TweenInfo.new(randomTimeReturn, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = originalCFrame})
        tween:Play()
        tween.Completed:Wait()
        print("✅ Kembali ke posisi awal!")
    end
end

AutoSellFish:CreateToggle({
    Id = "auto_sell_toggle",
    Title = "Enable Auto Sell",
    Icon = "refresh-cw",
    Default = false,
    Callback = function(state)
        autoSellEnabled = state
        if state then
            print("[Auto Sell] ON")
            Window:Notify({ 
                Title = "Auto Sell Active", 
                Content = "Auto sell akan berjalan tiap " .. autoSellInterval .. " menit.", 
                Type = "success", 
                Duration = 3 
            })
            
            autoSellTask = task.spawn(function()
                while autoSellEnabled do
                    -- Tunggu interval dulu sebelum sell pertama kali di loop
                    local waited = 0
                    while autoSellEnabled and waited < (autoSellInterval * 60) do
                        task.wait(1)
                        waited += 1
                    end
                    
                    -- Pause kalau lagi event biar ga tabrakan
                    if shared.isDoingEvent then
                        print("[Auto Sell] Lagi event, tunda sell dulu...")
                        while shared.isDoingEvent and autoSellEnabled do
                            task.wait(1)
                        end
                        print("[Auto Sell] Event selesai, lanjut sell!")
                    end
                    
                    -- Setelah tunggu, baru sell
                    if autoSellEnabled then
                        ExecuteSell()
                    end
                end
            end)
        else
            print("[Auto Sell] OFF")
            if autoSellTask then
                task.cancel(autoSellTask)
                autoSellTask = nil
            end
        end
    end
})

AutoSellFish:CreateButton({
    Id = "sell_now_button",
    Title = "Sell Now",
    Icon = "shopping-cart",
    Callback = function()
        Window:Notify({ 
            Title = "Auto Sell", 
            Content = "Menjalankan sell manual...", 
            Type = "info", 
            Duration = 2 
        })
        task.spawn(ExecuteSell)
    end
})
-- ================================================================
--  Favorit Tab
-- ================================================================
Loader:Set(0.4, "Favorit")
task.wait()
local FavoritTab = Window:CreateTab({ Title = "Favorit", Icon = "" })
local FavoritSection = FavoritTab:CreateSection({ Title = "Auto Favorit", Box = true, Opened = true })

local favSelectedRarities = {}
local favSelectedMutations = {}
local autoFavEnabled = false
local autoFavConnection = nil

-- =============================================
-- DROPDOWN PILIH RARITY
-- =============================================
FavoritSection:CreateMultiDropdown({
    Id = "fav_rarity",
    Sidebar = true,
    Title = "Pilih Rarity",
    Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Monster" },
    Default = {},
    Callback = function(selected)
        favSelectedRarities = {}
        if type(selected) == "table" then
            for _, rarity in ipairs(selected) do
                favSelectedRarities[rarity] = true
            end
        end
        print("[Auto Favorit] Rarity dipilih:", #selected > 0 and table.concat(selected, ", ") or "None")
    end
})

-- =============================================
-- DROPDOWN PILIH MUTATION
-- =============================================
FavoritSection:CreateMultiDropdown({
    Id = "fav_mutation",
    Sidebar = true,
    Title = "Pilih Mutation",
    Values = { "Electric", "GlassFin", "Shiny", "Zombie", "Metal" },
    Default = {},
    Callback = function(selected)
        favSelectedMutations = {}
        if type(selected) == "table" then
            for _, mutation in ipairs(selected) do
                favSelectedMutations[mutation] = true
            end
        end
        print("[Auto Favorit] Mutation dipilih:", #selected > 0 and table.concat(selected, ", ") or "None")
    end
})

-- =============================================
-- TOGGLE AUTO FAVORIT
-- =============================================
FavoritSection:CreateToggle({
    Id = "auto_favorit_toggle",
    Title = "Enable Auto Favorit",
    Icon = "star",
    Default = false,
    Callback = function(state)
        autoFavEnabled = state
        local Knit = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.7.0"].knit.Services
        local RewardRE = Knit.FishingRewardService.RE
        local ShopRF = Knit.FishermanShopService.RF
        
        if state then
            print("[Auto Favorit] ON")
            Window:Notify({
                Title = "Auto Favorit Active",
                Content = "Ikan dengan rarity/mutation terpilih akan otomatis di-favorit!",
                Type = "success",
                Duration = 3
            })
            
            if autoFavConnection == nil then
                autoFavConnection = RewardRE.FishCaught.OnClientEvent:Connect(function(data)
                    if not autoFavEnabled then return end
                    if type(data) == "table" and data.InstanceId and data.FishData then
                        local rarity = data.FishData.Rarity
                        local fishName = data.FishData.Name or ""
                        local mutation = data.Mutation or data.FishData.Mutation
                        local shouldFavorite = false
                        
                        -- Cek Rarity
                        if rarity and favSelectedRarities[rarity] then
                            shouldFavorite = true
                        end
                        
                        -- Cek Mutation
                        if not shouldFavorite then
                            local fishNameLower = string.lower(fishName)
                            for mut, _ in pairs(favSelectedMutations) do
                                local mutLower = string.lower(mut)
                                
                                -- 1. Cek dari nama ikan (case insensitive)
                                if string.find(fishNameLower, mutLower) then
                                    shouldFavorite = true
                                    break
                                end
                                
                                -- 2. Cek dari properti Mutation/Mutations
                                local mutData = data.Mutation or data.Mutations or (data.FishData and (data.FishData.Mutation or data.FishData.Mutations))
                                if type(mutData) == "string" and string.find(string.lower(mutData), mutLower) then
                                    shouldFavorite = true
                                    break
                                elseif type(mutData) == "table" then
                                    for _, m in pairs(mutData) do
                                        if type(m) == "string" and string.find(string.lower(m), mutLower) then
                                            shouldFavorite = true
                                            break
                                        end
                                    end
                                    if shouldFavorite then break end
                                end
                            end
                        end
                        
                        if shouldFavorite then
                            print("[Auto Favorit] Favoriting " .. tostring(fishName))
                            pcall(function()
                                ShopRF.ToggleFavoriteFish:InvokeServer(data.InstanceId)
                            end)
                            Window:Notify({
                                Title = "Auto Favorit",
                                Content = "Ikan " .. fishName .. " berhasil di-favorit!",
                                Type = "info",
                                Duration = 3
                            })
                        end
                    end
                end)
            end
        else
            print("[Auto Favorit] OFF")
            if autoFavConnection then
                autoFavConnection:Disconnect()
                autoFavConnection = nil
            end
        end
    end
})


-- ================================================================
--  Teleport Tab
-- ================================================================
Loader:Set(0.52, "Teleport")
task.wait()

local TeleportTab = Window:CreateTab({ Title = "Teleport", Icon = "arrow-left-right" })

-- =============================================
-- TELEPORT ISLAND SECTION
-- =============================================
local TeleportIslandSection = TeleportTab:CreateSection({ Title = "Teleport Island", Box = true, Opened = true })

local LP = game:GetService("Players").LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- Daftar Island di dalam Map Explore Island
local islands = {
    { name = "Bamboo",            cframe = CFrame.new(-1364.95, 180.10, 320.49) * CFrame.Angles(0, 2.70, 0),   unlockLevel = 1  },
    { name = "Iceberg",           cframe = CFrame.new(-582.31, 190.07, -529.37) * CFrame.Angles(0, -1.28, 0),  unlockLevel = 1  },
    { name = "Lost Whale Island", cframe = CFrame.new(-2676.25, 179.97, 39.09) * CFrame.Angles(0, 2.06, 0),   unlockLevel = 10 },
    { name = "Bora Reef",         cframe = CFrame.new(-3996.39, 171.44, 2028.85),                              unlockLevel = 20 },
    { name = "Volcano Vent",      cframe = CFrame.new(-1686.41, 173.81, 5931.25),                              unlockLevel = 30 },
    { name = "Cape Town",         cframe = CFrame.new(804.61, 187.62, 2952.89),                                unlockLevel = 35 },
    { name = "Mystic Mangrove",   cframe = CFrame.new(4428.54, 176.34, 1155.71),                               unlockLevel = 50 },
}

local islandOptions = {}
local islandMap = {}
for _, island in ipairs(islands) do
    local displayName = island.name .. " (Lv. " .. island.unlockLevel .. ")"
    table.insert(islandOptions, displayName)
    islandMap[displayName] = island
end

local selectedIslandName = nil

-- Dropdown Pilih Island
TeleportIslandSection:CreateDropdown({
    Id = "tp_island",
    Title = "Pilih Island",
    Values = islandOptions,
    Default = nil,
    Callback = function(v)
        selectedIslandName = v
        print("[Teleport Island] Target:", v or "None")
    end
})

-- Tombol Teleport ke Island yang dipilih (Hanya work di dalam Map Explore Island)
TeleportIslandSection:CreateButton({
    Id = "tp_island_btn",
    Title = "Teleport to Island",
    Callback = function()
        if game.PlaceId ~= 90457367396205 then
            Window:Notify({ Title = "Salah Map", Content = "Kamu harus berada di map Explore Island dulu!", Type = "error", Duration = 4 })
            return
        end
        
        if not selectedIslandName then
            Window:Notify({ Title = "Teleport", Content = "Pilih island terlebih dahulu di dropdown!", Type = "warning", Duration = 3 })
            return
        end
        
        local island = islandMap[selectedIslandName]
        if not island then return end
        
        -- Cek Level Player
        local hud = LP.PlayerGui:FindFirstChild("HUD")
        local statsPanel = hud and hud:FindFirstChild("PlayerStatsPanel", true)
        local levelLabel = statsPanel and statsPanel:FindFirstChild("LevelLabel", true)
        local level = 0
        if levelLabel then
            level = tonumber(levelLabel.Text:match("%d+")) or 0
        end
        
        if level >= island.unlockLevel then
            local char = LP.Character or LP.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = island.cframe
                Window:Notify({ Title = "Teleport Berhasil", Content = "Berhasil teleport ke " .. island.name, Type = "success", Duration = 3 })
            end
        else
            Window:Notify({ Title = "Level Kurang", Content = "Level kamu belum cukup! Butuh Lv. " .. island.unlockLevel, Type = "error", Duration = 3 })
        end
    end
})

-- =============================================
-- MAP SWITCHING BUTTONS (2 Tombol Terpisah)
-- =============================================
TeleportIslandSection:CreateDivider()
TeleportIslandSection:CreateSpace(4)
-- Tombol 1: Ke Base Map
TeleportIslandSection:CreateButton({
    Id = "tp_base_map_btn",
    Title = "Teleport to Base",
    Callback = function()
        if game.PlaceId == 111385005478215 then
            Window:Notify({ Title = "Info", Content = "Kamu sudah berada di Base Map!", Type = "info", Duration = 3 })
            return
        end
        
        Window:Notify({ Title = "Teleporting...", Content = "Pindah ke Base Map...", Type = "info", Duration = 3 })
        task.wait(0.5) -- Delay kecil biar executor gak nge-bug saat request teleport
        TeleportService:Teleport(111385005478215, LP)
    end
})

-- Tombol 2: Ke Explore Island Map
TeleportIslandSection:CreateButton({
    Id = "tp_explore_map_btn",
    Title = "Teleport to Island",
    Callback = function()
        if game.PlaceId == 90457367396205 then
            Window:Notify({ Title = "Info", Content = "Kamu sudah berada di Explore Island!", Type = "info", Duration = 3 })
            return
        end
        
        Window:Notify({ Title = "Teleporting...", Content = "Pindah ke Explore Island...", Type = "info", Duration = 3 })
        task.wait(0.5) -- Delay kecil biar executor gak nge-bug saat request teleport
        TeleportService:Teleport(90457367396205, LP)
    end
})


-- =============================================
-- TELEPORT PLAYER SECTION
-- =============================================
local TeleportPlayerSection = TeleportTab:CreateSection({ Title = "Teleport Player", Box = true, Opened = false })

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(names, p.Name)
        end
    end
    return names
end

local selectedPlayer = nil

TeleportPlayerSection:CreateDropdown({
    Id = "tp_player",
    Title = "Select Player",
    Sidebar = true,
    Values = getPlayerNames(),
    Refresh = getPlayerNames,
    RefreshInterval = 2,
    Callback = function(v)
        selectedPlayer = v
        print("[Teleport Player] Target:", v or "None")
    end
})

TeleportPlayerSection:CreateButton({
    Id = "tp_player_btn",
    Title = "Teleport Now",
    Icon = "map-pin",
    Callback = function()
        if not selectedPlayer then
            Window:Notify({ Title = "Teleport", Content = "Pilih player terlebih dahulu!", Type = "warning", Duration = 3 })
            return
        end
        
        local target = Players:FindFirstChild(selectedPlayer)
        if not target then
            Window:Notify({ Title = "Teleport", Content = "Player '" .. selectedPlayer .. "' tidak ditemukan!", Type = "error", Duration = 3 })
            return
        end
        
        if not target.Character then
            Window:Notify({ Title = "Teleport", Content = selectedPlayer .. " tidak punya karakter!", Type = "error", Duration = 3 })
            return
        end
        
        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then
            Window:Notify({ Title = "Teleport", Content = selectedPlayer .. " tidak punya HumanoidRootPart!", Type = "error", Duration = 3 })
            return
        end
        
        local localChar = LP.Character
        if not localChar then
            Window:Notify({ Title = "Teleport", Content = "Karakter kamu tidak ditemukan!", Type = "error", Duration = 3 })
            return
        end
        
        local localHRP = localChar:FindFirstChild("HumanoidRootPart")
        if not localHRP then
            Window:Notify({ Title = "Teleport", Content = "Kamu tidak punya HumanoidRootPart!", Type = "error", Duration = 3 })
            return
        end
        
        local success, err = pcall(function()
            localHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        end)
        
        if success then
            Window:Notify({ Title = "Teleport", Content = "Berhasil teleport ke " .. selectedPlayer, Type = "success", Duration = 3 })
            print("✅ Teleported to " .. selectedPlayer)
        else
            Window:Notify({ Title = "Teleport", Content = "Teleport gagal: " .. tostring(err), Type = "error", Duration = 3 })
            print("❌ Teleport failed: " .. tostring(err))
        end
    end
})


-- =============================================
-- TELEPORT EVENT SECTION
-- =============================================
local TeleportEventSection = TeleportTab:CreateSection({ Title = "Teleport Event", Box = true, Opened = false })

local function getAvailableEvents()
    local list = {}
    local EventFolder = workspace:FindFirstChild("Event")
    if EventFolder then
        for _, child in ipairs(EventFolder:GetChildren()) do
            local clean = child.Name:gsub("Event$", "")
            if not table.find(list, clean) then
                table.insert(list, clean)
            end
        end
    end
    if #list == 0 then
        list = {"Losi", "Windah"}
    end
    return list
end

local function findEventPosition(eventName)
    -- 1. Check direct BossEventMarker (e.g. for Losi)
    if eventName:lower() == "losi" then
        local ok, losiPillar = pcall(function()
            return workspace.BossEventMarker_Losi_Clown.BossEventPillar
        end)
        if ok and losiPillar then
            return losiPillar.Position, "Losi_Clown"
        end
    end
    
    -- 2. General search in workspace.Event
    local EventFolder = workspace:FindFirstChild("Event")
    if EventFolder then
        for _, folder in ipairs(EventFolder:GetChildren()) do
            if folder.Name:lower():find(eventName:lower(), 1, true) then
                for _, point in ipairs(folder:GetChildren()) do
                    for _, obj in ipairs(point:GetChildren()) do
                        if obj:IsA("BasePart") then
                            return obj.Position, folder.Name
                        elseif obj.Name:find("Anchor", 1, true) or obj.Name:find("Pillar", 1, true) then
                            return obj.Position, folder.Name
                        end
                    end
                end
            end
        end
    end
    return nil
end

local selectedTeleportEvent = nil

local teleportEventDropdown = TeleportEventSection:CreateDropdown({
    Id = "tp_event",
    Title = "Select Event Boss",
    Values = getAvailableEvents(),
    Default = getAvailableEvents()[1] or "",
    Callback = function(v)
        selectedTeleportEvent = v
        print("[Teleport Event] Target:", v or "None")
    end
})

selectedTeleportEvent = getAvailableEvents()[1]

TeleportEventSection:CreateButton({
    Id = "tp_event_btn",
    Title = "Teleport to Event",
    Icon = "map-pin",
    Callback = function()
        if not selectedTeleportEvent or selectedTeleportEvent == "" then
            Window:Notify({ Title = "Error", Content = "Pilih event terlebih dahulu!", Type = "warning", Duration = 3 })
            return
        end
        
        local pos, realName = findEventPosition(selectedTeleportEvent)
        if pos then
            local char = LP.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                Window:Notify({ 
                    Title = "Teleport Success", 
                    Content = "Teleport ke event: " .. selectedTeleportEvent .. " (" .. tostring(realName) .. ")", 
                    Type = "success", 
                    Duration = 3 
                })
            else
                Window:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Type = "error", Duration = 3 })
            end
        else
            Window:Notify({ Title = "Error", Content = "Event " .. selectedTeleportEvent .. " sedang tidak aktif!", Type = "error", Duration = 3 })
        end
    end
})

-- Auto-refresh dropdown values if a new event starts in the server
pcall(function()
    local EventFolder = workspace:FindFirstChild("Event")
    if EventFolder then
        EventFolder.ChildAdded:Connect(function()
            task.wait(0.5)
            if teleportEventDropdown then
                pcall(function()
                    local evs = getAvailableEvents()
                    if type(teleportEventDropdown.SetValues) == "function" then
                        teleportEventDropdown.SetValues(evs)
                    end
                end)
            end
        end)
    end
end)


-- ================================================================
--  Auto Tab
-- ================================================================
Loader:Set(0.64, "Auto")
task.wait()
local AutoTab = Window:CreateTab({ Title = "Auto", Icon = "rotate-ccw" })
local AutoEventSection = AutoTab:CreateSection({ Title = "Auto Event", Box = true, Opened = true })

-- =============================================
-- AUTO EVENT MODULE
-- =============================================
local function getAvailableEvents()
    local list = {}
    local EventFolder = workspace:FindFirstChild("Event")
    if EventFolder then
        for _, child in ipairs(EventFolder:GetChildren()) do
            local clean = child.Name:gsub("Event$", "")
            if not table.find(list, clean) then
                table.insert(list, clean)
            end
        end
    end
    if #list == 0 then
        list = {"Losi", "Windah"}
    end
    return list
end

local selectedEvents = {}

local eventDropdown = AutoEventSection:CreateMultiDropdown({
    Id = "auto_event_selection",
    Title = "Select Event Boss",
    Values = getAvailableEvents(),
    Default = {},
    Callback = function(selected)
        selectedEvents = {}
        if type(selected) == "table" then
            for _, v in ipairs(selected) do
                selectedEvents[v] = true
            end
        end
        print("[Auto Event] Event dipilih:", #selected > 0 and table.concat(selected, ", ") or "All")
    end
})

-- Auto-refresh pilihan dropdown jika ada folder Event baru yang muncul
pcall(function()
    local EventFolder = workspace:FindFirstChild("Event")
    if EventFolder then
        EventFolder.ChildAdded:Connect(function()
            task.wait(0.5)
            if eventDropdown then
                pcall(function()
                    local evs = getAvailableEvents()
                    if type(eventDropdown.SetValues) == "function" then
                        eventDropdown.SetValues(evs)
                    end
                end)
            end
        end)
    end
end)

local function getActiveBossId()
    local EventFolder = workspace:FindFirstChild("Event")
    if not EventFolder then return nil, nil end
    for _, folder in ipairs(EventFolder:GetChildren()) do
        for _, point in ipairs(folder:GetChildren()) do
            for _, obj in ipairs(point:GetChildren()) do
                -- Format: SeaMonsterTitleAnchor_BossId
                local bossId = obj.Name:match("SeaMonsterTitleAnchor_(.+)")
                if bossId then
                    return bossId, folder.Name
                end
            end
        end
    end
    return nil, nil
end

local autoEventEnabled = false
local eventAnnounceConn = nil
local eventScanTask = nil

local function handleEvent(position, bossName)
    if shared.isDoingEvent then return end
    shared.isDoingEvent = true
    
    local LP = game:GetService("Players").LocalPlayer
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local PlayerGui = LP:WaitForChild("PlayerGui")
    
    -- 1. Save original position
    local originalCFrame = hrp.CFrame
    print("✅ Menyimpan posisi awal:", originalCFrame)
    
    -- 2. Teleport ke event
    hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
    print("✅ Teleport ke event:", bossName, "| Pos:", position)
    task.wait(5) -- Jeda 5 detik biar map/UI server bener-bener keload
    
    print("🚨 LANGSUNG PARTICIPATE!")
    
    -- 3. Participate
    local ok, btn = pcall(function()
        return PlayerGui.BossFishEventGUI.FishMonsterContainer.FishMonsterBtn
    end)
    if ok and btn then
        firesignal(btn.Activated)
        print("✅ PARTICIPATE!")
    else
        print("❌ Tombol participate ga ketemu!")
    end
    
    task.wait(1)
    
    -- 4. Setup EventEnd listener DULU sebelum spam tap
    local RS = game:GetService("ReplicatedStorage")
    local Knit = RS.Packages._Index["sleitnick_knit@1.7.0"].knit.Services
    local isEventEnded = false
    local endConn
    endConn = Knit.BossFishEventService.RE.EventEnd.OnClientEvent:Connect(function(data)
        print("🏁 EventEnd diterima dari server! State:", data and data.State or "nil")
        isEventEnded = true
    end)
    
    -- 5. Listen to StartPulling via namecall hook
    print("⏳ Menunggu instruksi StartPulling dari game/server...")
    local isPullingStarted = false
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    pcall(function()
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "InvokeServer" and tostring(self) == "StartPulling" then
                isPullingStarted = true
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
    
    -- Scan text untuk nentuin timeout (kalau-kalau eventnya masih lama)
    local timeout = 600 -- fallback 10 menit
    pcall(function()
        local readyPanel = PlayerGui:WaitForChild("BossFishEventGUI", 2):WaitForChild("ReadyPanel", 2)
        local label = readyPanel:WaitForChild("TextLabel", 2)
        local text = label.Text
        print("📊 Status Event pas nunggu StartPulling:", text)
        local secs = string.match(text, "in: (%d+)s") or string.match(text, "(%d+)s")
        if secs then
            timeout = tonumber(secs) + 60 -- Kasih buffer 60 detik dari sisa waktu countdown
            print("⏱️ Sisa waktu event:", secs, "detik. Set timeout nunggu StartPulling jadi:", timeout, "detik")
        end
    end)
    
    -- Tunggu StartPulling sesuai timeout, atau sampai EventEnd keluar
    local waitPull = tick()
    while not isPullingStarted and not isEventEnded and tick() - waitPull < timeout do
        task.wait(0.1)
    end
    
    -- balikin namecall
    pcall(function()
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        setreadonly(mt, true)
    end)
    
    if isEventEnded then
        print("⚠️ EventEnd sudah keluar sebelum StartPulling, skip tap...")
        endConn:Disconnect()
        task.wait(1)
        pcall(function()
            local cBtn1 = PlayerGui.BossEndgameGUI.EndgameUI.CloseButton
            firesignal(cBtn1.Activated)
            print("🏆 Close EndgameUI")
        end)
        task.wait(0.3)
        pcall(function()
            local cBtn2 = PlayerGui.RewardGui.RewardPanel.Header.CloseBtn
            firesignal(cBtn2.MouseButton1Click)
            print("🎁 Close RewardGui")
        end)
        task.wait(1)
        hrp.CFrame = originalCFrame
        print("🔙 Kembali ke posisi awal!")
        shared.isDoingEvent = false
        print("▶️ Instant Fishing dilanjutkan!")
        return
    end
    
    if isPullingStarted then
        print("🎣 StartPulling terdeteksi! Lanjut ke tap...")
    else
        print("⚠️ Timeout nunggu StartPulling, lanjut aja...")
    end
    
    -- 6. Spam tap event dengan BossID dinamis
    local detectedBossId, activeEventName = getActiveBossId()
    local tapBossName = detectedBossId or (bossName:lower():find("losi") and "Losi_Coral" or "Windah_SM_Clown")
    print("👾 Spam tap boss ID:", tapBossName, "(Event:", tostring(activeEventName or bossName), ") mulai!")
    
    local PlayerTap = Knit.BossFishEventService.RF.PlayerTap
    
    -- Cek juga dari UI kalau-kalau onClientEvent kelewat
    task.spawn(function()
        task.wait(5) -- Kasih jeda dulu sebelum mulai ngecek UI biar gak false positive awal
        while not isEventEnded and shared.isDoingEvent do
            local hasVictory = false
            local hasReward = false
            pcall(function()
                hasVictory = PlayerGui.BossEndgameGUI.Enabled and PlayerGui.BossEndgameGUI.EndgameUI.Visible
            end)
            pcall(function()
                hasReward = PlayerGui.RewardGui.Enabled and PlayerGui.RewardGui.RewardPanel.Visible
            end)
            if hasVictory or hasReward then
                print("🏆 UI Kemenangan kedetect! Event berarti kelar.")
                isEventEnded = true
            end
            task.wait(1)
        end
    end)
    
    local count = 0
    -- Spam tap sampai EventEnd dari server, UI selesai, atau bossId sudah hilang
    while not isEventEnded and shared.isDoingEvent do
        local curBossId, _ = getActiveBossId()
        curBossId = curBossId or tapBossName
        local ok, res = pcall(function() return PlayerTap:InvokeServer(curBossId) end)
        if ok then
            count = count + 1
            if count % 20 == 0 then
                print("✅ Tap ke-" .. count .. " | BossID: " .. tostring(curBossId))
            end
        else
            print("❌ Error tap:", res)
            break
        end
        task.wait(0.05)
    end
    
    endConn:Disconnect()
    print("🏁 Event selesai! Total tap:", count)
    
    -- 7. Close GUI
    task.wait(1)
    pcall(function()
        local cBtn1 = PlayerGui.BossEndgameGUI.EndgameUI.CloseButton
        firesignal(cBtn1.Activated)
        print("🏆 Close EndgameUI")
    end)
    task.wait(0.3)
    pcall(function()
        local cBtn2 = PlayerGui.RewardGui.RewardPanel.Header.CloseBtn
        firesignal(cBtn2.MouseButton1Click)
        print("🎁 Close RewardGui")
    end)
    task.wait(1)
    
    -- 8. Teleport Back
    hrp.CFrame = originalCFrame
    print("🔙 Kembali ke posisi awal!")
    shared.isDoingEvent = false
    print("▶️ Instant Fishing dilanjutkan!")
end

local function scanActiveEvent()
    local bossId, folderName = getActiveBossId()
    if bossId and folderName then
        local cleanFolderName = folderName:gsub("Event$", "")
        local hasSelection = next(selectedEvents) ~= nil
        local isAllowed = not hasSelection or selectedEvents[cleanFolderName] or selectedEvents[folderName]
        
        if isAllowed then
            local EventFolder = workspace:FindFirstChild("Event")
            if EventFolder then
                local folderObj = EventFolder:FindFirstChild(folderName)
                if folderObj then
                    for _, point in ipairs(folderObj:GetChildren()) do
                        for _, obj in ipairs(point:GetChildren()) do
                            if obj.Name:find(bossId, 1, true) then
                                print("🎯 Event aktif ditemukan! Folder:", folderName, "| BossID:", bossId)
                                task.spawn(handleEvent, obj.Position, bossId)
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    
    if selectedEvents["Losi"] then
        local ok, losiPillar = pcall(function()
            return workspace.BossEventMarker_Losi_Clown.BossEventPillar
        end)
        if ok and losiPillar then
            print("🎯 Losi event aktif!")
            task.spawn(handleEvent, losiPillar.Position, "Losi_Clown")
            return true
        end
    end
    
    return false
end

AutoEventSection:CreateToggle({
    Id = "auto_event_toggle",
    Title = "Enable Auto Event",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        autoEventEnabled = state
        if state then
            print("[Auto Event] ON")
            Window:Notify({
                Title = "Auto Event Active",
                Content = "Menunggu event boss muncul...",
                Type = "success",
                Duration = 3
            })
            
            local RS = game:GetService("ReplicatedStorage")
            local Knit = RS.Packages._Index["sleitnick_knit@1.7.0"].knit.Services
            local EVENT_ANNOUNCE = Knit.BossFishEventService.RE.EventAnnounce
            
            print("👂 Listen EventAnnounce...")
            eventAnnounceConn = EVENT_ANNOUNCE.OnClientEvent:Connect(function(data)
                if not autoEventEnabled then return end
                print("📢 EVENT ANNOUNCE!")
                print("   Boss:", data.BossDisplayName, "(" .. data.BossName .. ")")
                print("   State:", data.CurrentState)
                
                local bName = (data.BossName or ""):lower()
                local bDisplay = (data.BossDisplayName or ""):lower()
                local hasSelection = next(selectedEvents) ~= nil
                local isAllowed = not hasSelection
                
                if hasSelection then
                    for evName, enabled in pairs(selectedEvents) do
                        if enabled then
                            local lowEv = evName:lower()
                            if bName:find(lowEv) or bDisplay:find(lowEv) then
                                isAllowed = true
                                break
                            end
                        end
                    end
                end
                
                if isAllowed and (data.CurrentState == "Announcing" or data.CurrentState == "Gathering") then
                    local eventPos = Vector3.new(
                        data.EventPosition[1],
                        data.EventPosition[2],
                        data.EventPosition[3]
                    )
                    print("📍 Event Position:", eventPos)
                    task.spawn(handleEvent, eventPos, data.BossName)
                end
            end)
            
            print("✅ Auto Event aktif, nunggu event...")
            eventScanTask = task.spawn(function()
                while autoEventEnabled do
                    if not shared.isDoingEvent then
                        scanActiveEvent()
                    end
                    task.wait(3)
                end
            end)
        else
            print("[Auto Event] OFF")
            if eventAnnounceConn then
                eventAnnounceConn:Disconnect()
                eventAnnounceConn = nil
            end
            if eventScanTask then
                task.cancel(eventScanTask)
                eventScanTask = nil
            end
            -- Reset flag biar bisa deteksi event lagi kalau toggle dihidupin balik
            shared.isDoingEvent = false
            Window:Notify({
                Title = "Auto Event Deactivated",
                Content = "Auto event dimatikan.",
                Type = "info",
                Duration = 3
            })
        end
    end
})

AutoEventSection:CreateButton({
    Id = "auto_event_teleport_now",
    Title = "Teleport Now",
    Icon = "map-pin",
    Callback = function()
        local found = scanActiveEvent()
        if not found then
            Window:Notify({
                Title = "Auto Event",
                Content = "Tidak ada event aktif yang terdeteksi!",
                Type = "warning",
                Duration = 3
            })
        end
    end
})


local autoMinigameEnabled = false
local autoMinigameTask = nil

AutoEventSection:CreateToggle({
    Id = "auto_minigame_toggle",
    Title = "Auto Minigame Only",
    Icon = "activity",
    Default = false,
    Callback = function(state)
        autoMinigameEnabled = state

        if state then
            print("[Auto Minigame] ON")
            Window:Notify({
                Title = "Auto Minigame Active",
                Content = "Scanning event aktif...",
                Type = "success",
                Duration = 3
            })

            autoMinigameTask = task.spawn(function()
                while autoMinigameEnabled do
                    -- Scan event aktif
                    local bossId, folderName = getActiveBossId()

                    if not bossId then
                        print("[Auto Minigame] ⏳ Belum ada event aktif, retry...")
                        task.wait(3)
                        continue
                    end

                    -- Cek apakah sesuai pilihan dropdown
                    local cleanFolderName = folderName and folderName:gsub("Event$", "") or ""
                    local hasSelection = next(selectedEvents) ~= nil
                    local isAllowed = not hasSelection
                        or selectedEvents[cleanFolderName]
                        or selectedEvents[folderName]

                    if not isAllowed then
                        print("[Auto Minigame] ⚠️ Event", bossId, "tidak dipilih, skip...")
                        task.wait(3)
                        continue
                    end

                    print("[Auto Minigame] 🎯 Event ditemukan:", bossId)

                    local RS = game:GetService("ReplicatedStorage")
                    local Knit = RS.Packages._Index["sleitnick_knit@1.7.0"].knit.Services
                    local PlayerTap = Knit.BossFishEventService.RF.PlayerTap
                    local LP = game:GetService("Players").LocalPlayer
                    local PlayerGui = LP:WaitForChild("PlayerGui")

                    -- =============================================
                    -- STEP 1: Tunggu StartPulling dulu
                    -- =============================================
                    print("[Auto Minigame] ⏳ Nunggu StartPulling dari server...")
                    local isPullingStarted = false
                    local isEventEnded = false

                    -- Listen EventEnd
                    local endConn
                    endConn = Knit.BossFishEventService.RE.EventEnd.OnClientEvent:Connect(function(data)
                        print("[Auto Minigame] 🏁 EventEnd saat nunggu pull! State:", data and data.State or "nil")
                        isEventEnded = true
                    end)

                    -- Hook namecall buat detect StartPulling
                    local mt = getrawmetatable(game)
                    local oldNamecall = mt.__namecall
                    pcall(function()
                        setreadonly(mt, false)
                        mt.__namecall = newcclosure(function(self, ...)
                            local method = getnamecallmethod()
                            if method == "InvokeServer" then
                                local name = tostring(self.Name or "")
                                if name == "StartPulling" then
                                    print("[Auto Minigame] 🎣 StartPulling terdeteksi!")
                                    isPullingStarted = true
                                end
                            end
                            return oldNamecall(self, ...)
                        end)
                        setreadonly(mt, true)
                    end)

                    -- Tunggu sampai StartPulling atau EventEnd (max 10 menit)
                    local waitStart = tick()
                    while not isPullingStarted and not isEventEnded and autoMinigameEnabled do
                        task.wait(0.1)
                        if tick() - waitStart > 600 then
                            print("[Auto Minigame] ⚠️ Timeout nunggu StartPulling!")
                            break
                        end
                    end

                    -- Restore namecall
                    pcall(function()
                        setreadonly(mt, false)
                        mt.__namecall = oldNamecall
                        setreadonly(mt, true)
                    end)

                    -- Kalau event udah kelar sebelum pull
                    if isEventEnded or not autoMinigameEnabled then
                        endConn:Disconnect()
                        print("[Auto Minigame] ⚠️ Event berakhir sebelum pull dimulai, skip...")
                        task.wait(3)
                        continue
                    end

                    -- =============================================
                    -- STEP 2: StartPulling kedetect → spam tap
                    -- =============================================
                    print("[Auto Minigame] 🚀 StartPulling OK! Mulai spam tap...")

                    -- Monitor UI kemenangan
                    task.spawn(function()
                        task.wait(3)
                        while not isEventEnded and autoMinigameEnabled do
                            local hasVictory, hasReward = false, false
                            pcall(function()
                                hasVictory = PlayerGui.BossEndgameGUI.Enabled
                                    and PlayerGui.BossEndgameGUI.EndgameUI.Visible
                            end)
                            pcall(function()
                                hasReward = PlayerGui.RewardGui.Enabled
                                    and PlayerGui.RewardGui.RewardPanel.Visible
                            end)
                            if hasVictory or hasReward then
                                print("[Auto Minigame] 🏆 UI kemenangan kedetect!")
                                isEventEnded = true
                            end
                            task.wait(1)
                        end
                    end)

                    -- Spam tap loop
                    local count = 0
                    while not isEventEnded and autoMinigameEnabled do
                        local curBossId, _ = getActiveBossId()
                        curBossId = curBossId or bossId

                        local ok, res = pcall(function()
                            return PlayerTap:InvokeServer(curBossId)
                        end)

                        if ok then
                            count += 1
                            if count % 20 == 0 then
                                print("[Auto Minigame] ✅ Tap ke-" .. count .. " | Boss:", curBossId)
                            end
                        else
                            print("[Auto Minigame] ❌ Error tap:", res)
                            break
                        end

                        task.wait(0.05)
                    end

                    endConn:Disconnect()
                    print("[Auto Minigame] 🏁 Selesai! Total tap:", count)

                    -- Close GUI
                    task.wait(1)
                    pcall(function()
                        firesignal(PlayerGui.BossEndgameGUI.EndgameUI.CloseButton.Activated)
                        print("[Auto Minigame] 🏆 Close EndgameUI")
                    end)
                    task.wait(0.3)
                    pcall(function()
                        firesignal(PlayerGui.RewardGui.RewardPanel.Header.CloseBtn.MouseButton1Click)
                        print("[Auto Minigame] 🎁 Close RewardGui")
                    end)

                    print("[Auto Minigame] ⏳ Nunggu event berikutnya...")
                    task.wait(5)
                end
            end)

        else
            print("[Auto Minigame] OFF")
            if autoMinigameTask then
                task.cancel(autoMinigameTask)
                autoMinigameTask = nil
            end
            Window:Notify({
                Title = "Auto Minigame",
                Content = "Auto minigame dimatikan.",
                Type = "info",
                Duration = 3
            })
        end
    end
})

-- ================================================================
--  Webhook Tab
-- ================================================================
Loader:Set(0.78, "Webhook")
task.wait()
local WebhookTab = Window:CreateTab({ Title = "Webhook", Icon = "link" })

-- =============================================
-- WEBHOOK MODULE (LOGIKA INTI - 100% SAMA)
-- =============================================
local WebhookModule = (function()
    local M = {}
    
    -- Cari HTTP request function yang tersedia
    local function getHTTPRequest()
        local funcs = { request, http_request,
            (syn and syn.request),
            (fluxus and fluxus.request),
            (http and http.request),
            (solara and solara.request),
        }
        for _, f in ipairs(funcs) do
            if f and type(f) == "function" then return f end
        end
        return nil
    end
    
    local httpRequest = getHTTPRequest()
    local HttpService = game:GetService("HttpService")
    
    -- Config (state lokal, di-sync dari UI)
    M.FishConfig = {
        WebhookURL = "",
        DiscordUserID = "",
        HideIdentity = "",
        EnabledRarities = {},
        Enabled = false
    }
    M.DisconnectConfig = {
        WebhookURL = "",
        DiscordUserID = "",
        HideIdentity = "",
        Enabled = false
    }
    M.LeaderboardConfig = {
        WebhookURL = "",
        DiscordUserID = "",
        HideIdentity = "",
        DelayMinutes = 5,
        Enabled = false
    }
    
    local RARITY_COLORS = {
        Common    = 9807270,
        Uncommon  = 3066993,
        Rare      = 3447003,
        Epic      = 10181046,
        Legendary = 15844367,
        Mythic    = 16711680,
        Secret    = 65535,
        Monster   = 16711935,
    }
    
    local isFishRunning = false
    local fishEventConn = nil
    local isDisconnectEnabled = false
    local disconnectSetup = false
    local isLeaderboardRunning = false
    local leaderboardThread = nil
    
    local function getDisplayName(config)
        if config.HideIdentity and config.HideIdentity ~= "" then
            return config.HideIdentity
        end
        local lp = game:GetService("Players").LocalPlayer
        return lp.DisplayName or lp.Name
    end
    
    local function getImageUrl(imageID)
        if not imageID then return "https://i.imgur.com/UMWNYK7.png" end
        local id = tostring(imageID):match("%d+")
        if not id then return "https://i.imgur.com/UMWNYK7.png" end
        local thumbnailUrl = string.format(
            "https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false",
            id
        )
        if httpRequest then
            local success, result = pcall(function()
                local response = httpRequest({ Url = thumbnailUrl, Method = "GET" })
                if response and response.Body then
                    local data = HttpService:JSONDecode(response.Body)
                    if data and data.data and data.data[1] and data.data[1].imageUrl then
                        return data.data[1].imageUrl
                    end
                end
            end)
            if success and result then return result end
        end
        return "https://tr.rbxcdn.com/180DAY-" .. id .. "/420/420/Image/Png"
    end
    
    local function formatPrice(price)
        local formatted = tostring(math.floor(tonumber(price) or 0))
        return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end
    
    local function sendFishWebhook(data)
        if not M.FishConfig.WebhookURL or M.FishConfig.WebhookURL == "" then return end
        if not httpRequest then return end
        
        local fishData = data.FishData or {}
        local rarity = fishData.Rarity or "Common"
        local color = RARITY_COLORS[rarity] or RARITY_COLORS.Common
        
        -- Filter rarity
        local enabledRarities = M.FishConfig.EnabledRarities
        if enabledRarities and next(enabledRarities) then
            local hasFilter = false
            local passed = false
            for k, v in pairs(enabledRarities) do
                hasFilter = true
                local r = (type(k) == "string" and v == true) and k or v
                if r == rarity then passed = true break end
            end
            if hasFilter and not passed then return end
        end
        
        local playerName = getDisplayName(M.FishConfig)
        local mention = M.FishConfig.DiscordUserID ~= "" and "<@" .. M.FishConfig.DiscordUserID .. ">" or ""
        local imageUrl = getImageUrl(fishData.ImageID)
        local fishName = fishData.Name or data.FishID or "Unknown"
        local weightStr = data.WeightFormatted or (string.format("%.2f Kg", data.Weight or 0))
        local weightTier = data.WeightTier or "-"
        local price = formatPrice(data.Price or fishData.Price or 0)
        local basePrice = formatPrice(fishData.Price or 0)
        
        local payload = {
            username = "King Vypers",
            avatar_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg",
            content = mention ~= "" and (mention .. " **" .. playerName .. "** caught a **" .. rarity .. "** fish!") or nil,
            embeds = {{
                author = { name = "King Vypers | Fish Caught" },
                color = color,
                fields = {
                    { name = "🐟 Fish Name",   value = "```" .. fishName .. "```",  inline = false },
                    { name = "⭐ Rarity",       value = "```" .. rarity .. "```",    inline = true  },
                    { name = "⚖️ Weight",       value = "```" .. weightStr .. "```", inline = true  },
                    { name = "🏆 Weight Tier",  value = "```" .. weightTier .. "```",inline = true  },
                    { name = "💰 Base Price",   value = "```$" .. basePrice .. "```",inline = true  },
                    { name = "💸 Sold For",     value = "```$" .. price .. "```",    inline = true  },
                    { name = "👤 Player",       value = "```" .. playerName .. "```",inline = true  },
                },
                image = { url = imageUrl },
                footer = {
                    text = "King Vypers • " .. os.date("%m/%d/%Y at %I:%M %p"),
                    icon_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        pcall(function()
            httpRequest({
                Url = M.FishConfig.WebhookURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end
    
    local function sendDisconnectWebhook(reason)
        if not isDisconnectEnabled then return end
        local url = M.DisconnectConfig.WebhookURL
        if not url or url == "" then return end
        if not httpRequest then return end
        
        local playerName = getDisplayName(M.DisconnectConfig)
        local mention = M.DisconnectConfig.DiscordUserID ~= ""
            and "<@" .. M.DisconnectConfig.DiscordUserID:gsub("%D", "") .. ">"
            or ""
        
        local payload = {
            content = mention ~= "" and (mention .. " Account disconnected!") or nil,
            username = "King Vypers",
            avatar_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg",
            embeds = {{
                author = { name = "King Vypers | Disconnect Alert" },
                title = "⚠️ Connection Lost",
                description = "Roblox session disconnected. Attempting rejoin...",
                color = 16711680,
                fields = {
                    { name = "���� Account", value = "```" .. playerName .. "```", inline = true },
                    { name = "🕐 Time",    value = "```" .. os.date("%m/%d/%Y at %I:%M %p") .. "```", inline = true },
                    { name = "📋 Reason",  value = "```" .. (reason or "Disconnected") .. "```", inline = false },
                },
                footer = {
                    text = "King Vypers • Auto-rejoin enabled",
                    icon_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        task.spawn(function()
            pcall(function()
                httpRequest({
                    Url = url, Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload)
                })
            end)
        end)
    end
    
    local function setupDisconnectDetection()
        if disconnectSetup then return end
        disconnectSetup = true
        
        local done = false
        local function handleDisconnect(reason)
            if not done and isDisconnectEnabled then
                done = true
                sendDisconnectWebhook(reason or "Disconnected from server")
                task.wait(2)
                game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
            end
        end
        
        game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
            if msg and msg ~= "" then handleDisconnect(msg) end
        end)
    end
    
    local function sendLeaderboardWebhook(isTest)
        local url = M.LeaderboardConfig.WebhookURL
        if not url or url == "" then return end
        if not httpRequest then return end
        
        local player = game.Players.LocalPlayer
        local playerName = M.LeaderboardConfig.HideIdentity ~= "" and M.LeaderboardConfig.HideIdentity or (player.DisplayName or player.Name)
        local mention = M.LeaderboardConfig.DiscordUserID ~= "" and "<@" .. M.LeaderboardConfig.DiscordUserID:gsub("%D", "") .. ">" or ""
        local headshotUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
        
        -- Extract stats
        local statsDict = {}
        if player:FindFirstChild("leaderstats") then
            for _, stat in pairs(player.leaderstats:GetChildren()) do
                statsDict[stat.Name] = tostring(stat.Value)
            end
        end
        if player:FindFirstChild("PlayerData") then
            for _, stat in pairs(player.PlayerData:GetChildren()) do
                if stat:IsA("ValueBase") then
                    statsDict[stat.Name] = tostring(stat.Value)
                end
            end
        end
        local levelLabel = player.PlayerGui:FindFirstChild("HUD")
        if levelLabel then
            local ok, lvl = pcall(function()
                return player.PlayerGui.HUD.PlayerStatsPanel.LevelExpRow.LevelLabel.Text
            end)
            if ok then statsDict["Level"] = lvl end
        end
        
        local orderedStats = {
            { key = "Level", name = "Level", emoji = "🌟" },
            { key = "Fish", name = "Fish", emoji = "🐟" },
            { key = "Playtime", name = "Playtime", emoji = "⏳" },
            { key = "Money", name = "Money", emoji = "💰" },
            { key = "Shards", name = "Shards", emoji = "💎" },
        }
        
        local fields = {}
        local processed = {}
        
        table.insert(fields, {
            name = "👤 Player Name",
            value = "```" .. playerName .. "```",
            inline = true
        })
        
        for _, entry in ipairs(orderedStats) do
            local foundKey = nil
            for k, _ in pairs(statsDict) do
                if k:lower() == entry.key:lower() then
                    foundKey = k
                    break
                end
            end
            if foundKey then
                local val = statsDict[foundKey]
                local displayVal = val
                if entry.key == "Money" then
                    local cleanNum = val:gsub("[^%d%.]", "")
                    local num = tonumber(cleanNum)
                    if num then
                        displayVal = "$" .. formatPrice(num)
                    else
                        displayVal = "$" .. val
                    end
                end
                table.insert(fields, {
                    name = entry.emoji .. " " .. entry.name,
                    value = "```" .. displayVal .. "```",
                    inline = true
                })
                processed[foundKey] = true
            end
        end
        
        for k, v in pairs(statsDict) do
            if not processed[k] then
                table.insert(fields, {
                    name = "📊 " .. k,
                    value = "```" .. v .. "```",
                    inline = true
                })
            end
        end
        
        local softGreen = 7855479
        
        local payload = {
            username = "King Vypers",
            avatar_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg",
            content = isTest and "🧪 **Leaderboard Webhook Test**" or (mention ~= "" and mention or nil),
            embeds = {{
                author = { 
                    name = "King Vypers | Leaderboard Updates",
                    icon_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg"
                },
                title = isTest and "✅ Webhook Test Success!" or "📈 Current Leaderboard & Progress",
                description = isTest and "Test leaderboard webhook configuration succeeded." or nil,
                color = softGreen,
                thumbnail = { url = headshotUrl },
                fields = fields,
                footer = {
                    text = "King Vypers • " .. os.date("%m/%d/%Y at %I:%M %p"),
                    icon_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        pcall(function()
            httpRequest({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end
    
    -- Public API
    function M:StartFishWebhook()
        if isFishRunning then return end
        if not httpRequest then print("[Webhook] HTTP ga tersedia!") return false end
        if not self.FishConfig.WebhookURL or self.FishConfig.WebhookURL == "" then
            print("[Webhook] URL belum diisi!") return false
        end
        
        local RS = game:GetService("ReplicatedStorage")
        local ok, FishCaught = pcall(function()
            return RS.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.FishingRewardService.RE.FishCaught
        end)
        if not ok or not FishCaught then print("[Webhook] FishCaught event ga ketemu!") return false end
        
        fishEventConn = FishCaught.OnClientEvent:Connect(function(data)
            task.spawn(sendFishWebhook, data)
        end)
        isFishRunning = true
        self.FishConfig.Enabled = true
        print("[Webhook] Fish Webhook ON!")
        return true
    end
    
    function M:StopFishWebhook()
        if not isFishRunning then return end
        if fishEventConn then fishEventConn:Disconnect() fishEventConn = nil end
        isFishRunning = false
        self.FishConfig.Enabled = false
        print("[Webhook] Fish Webhook OFF!")
    end
    
    function M:EnableDisconnectWebhook(enabled)
        self.DisconnectConfig.Enabled = enabled
        isDisconnectEnabled = enabled
        if enabled then setupDisconnectDetection() end
    end
    
    function M:StartLeaderboardWebhook()
        if isLeaderboardRunning then return end
        if not httpRequest then print("[Webhook] HTTP ga tersedia!") return false end
        if not self.LeaderboardConfig.WebhookURL or self.LeaderboardConfig.WebhookURL == "" then
            print("[Webhook] URL belum diisi!") return false
        end
        
        isLeaderboardRunning = true
        self.LeaderboardConfig.Enabled = true
        print("[Webhook] Leaderboard Webhook ON!")
        
        leaderboardThread = task.spawn(function()
            while isLeaderboardRunning do
                sendLeaderboardWebhook(false)
                local delayTime = (tonumber(self.LeaderboardConfig.DelayMinutes) or 5) * 60
                task.wait(delayTime)
            end
        end)
        return true
    end
    
    function M:StopLeaderboardWebhook()
        if not isLeaderboardRunning then return end
        isLeaderboardRunning = false
        self.LeaderboardConfig.Enabled = false
        if leaderboardThread then
            pcall(task.cancel, leaderboardThread)
            leaderboardThread = nil
        end
        print("[Webhook] Leaderboard Webhook OFF!")
    end
    
    function M:IsLeaderboardRunning() return isLeaderboardRunning end
    
    function M:TestFishWebhook()
        if not httpRequest then return false end
        if not self.FishConfig.WebhookURL or self.FishConfig.WebhookURL == "" then return false end
        local ok = pcall(function()
            httpRequest({
                Url = self.FishConfig.WebhookURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    username = "King Vypers",
                    avatar_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg",
                    embeds = {{
                        title = "✅ Webhook Test Berhasil!",
                        description = "Fish Webhook sudah terhubung dan siap menerima notifikasi!",
                        color = 3066993,
                        footer = {
                            text = "King Vypers • Test",
                            icon_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg"
                        },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }}
                })
            })
        end)
        return ok
    end
    
    function M:TestDisconnectWebhook()
        sendDisconnectWebhook("Test - Simulasi Disconnect")
    end
    
    function M:TestLeaderboardWebhook()
        if not httpRequest then return false end
        if not self.LeaderboardConfig.WebhookURL or self.LeaderboardConfig.WebhookURL == "" then return false end
        sendLeaderboardWebhook(true)
        return true
    end
    
    return M
end)()

-- =============================================
-- FISH CAUGHT WEBHOOK SECTION
-- =============================================
local FishWebhookSection = WebhookTab:CreateSection({ Title = "Fish Caught Webhook", Box = true, Opened = true })

FishWebhookSection:CreateInput({
    Id = "fish_webhook_url",
    Title = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default = "",
    Callback = function(v)
        local val = v:gsub("^%s*(.-)%s*$", "%1")
        WebhookModule.FishConfig.WebhookURL = val
    end
})

FishWebhookSection:CreateInput({
    Id = "fish_discord_user_id",
    Title = "Discord User ID",
    Placeholder = "123456789012345678",
    Default = "",
    Callback = function(v)
        local val = v:gsub("^%s*(.-)%s*$", "%1")
        WebhookModule.FishConfig.DiscordUserID = val
    end
})

FishWebhookSection:CreateInput({
    Id = "fish_custom_name",
    Title = "Custom Name",
    Placeholder = "Masukkan nama custom...",
    Default = "",
    Callback = function(v)
        local val = v:gsub("^%s*(.-)%s*$", "%1")
        WebhookModule.FishConfig.HideIdentity = val
    end
})

FishWebhookSection:CreateMultiDropdown({
    Id = "fish_rarity_filter",
    Title = "Filter Rarity",
    Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Monster" },
    Default = {},
    Callback = function(selected)
        local rarityMap = {}
        if type(selected) == "table" then
            for _, v in ipairs(selected) do
                rarityMap[v] = true
            end
        end
        WebhookModule.FishConfig.EnabledRarities = rarityMap
    end
})

local fishToggleRef = FishWebhookSection:CreateToggle({
    Id = "fish_webhook_toggle",
    Title = "Enable Fish Webhook",
    Icon = "zap",
    Default = false,
    Callback = function(state)
        if state then
            if WebhookModule.FishConfig.WebhookURL == "" then
                Window:Notify({ Title = "Webhook", Content = "URL belum diisi!", Type = "error", Duration = 3 })
                fishToggleRef.Set(false)
                return
            end
            local ok = WebhookModule:StartFishWebhook()
            if ok then
                Window:Notify({ Title = "Fish Webhook", Content = "Fish webhook aktif!", Type = "success", Duration = 3 })
            else
                fishToggleRef.Set(false)
            end
        else
            WebhookModule:StopFishWebhook()
            Window:Notify({ Title = "Fish Webhook", Content = "Fish webhook dimatikan.", Type = "info", Duration = 3 })
        end
    end
})

FishWebhookSection:CreateButton({
    Id = "fish_webhook_test",
    Title = "Test Fish Webhook",
    Icon = "send",
    Callback = function()
        if WebhookModule.FishConfig.WebhookURL == "" then
            Window:Notify({ Title = "Webhook", Content = "URL belum diisi!", Type = "error", Duration = 3 })
            return
        end
        local ok = WebhookModule:TestFishWebhook()
        Window:Notify({ 
            Title = "Fish Webhook Test", 
            Content = ok and "Test berhasil dikirim!" or "Gagal mengirim test.", 
            Type = ok and "success" or "error", 
            Duration = 3 
        })
    end
})

-- =============================================
-- DISCONNECT WEBHOOK SECTION
-- =============================================
local DisconnectSection = WebhookTab:CreateSection({ Title = "Disconnect Webhook", Box = true, Opened = false })

DisconnectSection:CreateInput({
    Id = "disconnect_webhook_url",
    Title = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default = "",
    Callback = function(v)
        local val = v:gsub("^%s*(.-)%s*$", "%1")
        WebhookModule.DisconnectConfig.WebhookURL = val
    end
})

DisconnectSection:CreateInput({
    Id = "disconnect_discord_user_id",
    Title = "Discord User ID",
    Placeholder = "123456789012345678",
    Default = "",
    Callback = function(v)
        local val = v:gsub("^%s*(.-)%s*$", "%1")
        WebhookModule.DisconnectConfig.DiscordUserID = val
    end
})

DisconnectSection:CreateInput({
    Id = "disconnect_custom_name",
    Title = "Custom Name",
    Placeholder = "Masukkan nama custom...",
    Default = "",
    Callback = function(v)
        local val = v:gsub("^%s*(.-)%s*$", "%1")
        WebhookModule.DisconnectConfig.HideIdentity = val
    end
})

DisconnectSection:CreateToggle({
    Id = "disconnect_webhook_toggle",
    Title = "Enable Disconnect Webhook",
    Icon = "wifi-off",
    Default = false,
    Callback = function(state)
        if state then
            if WebhookModule.DisconnectConfig.WebhookURL == "" then
                Window:Notify({ Title = "Webhook", Content = "URL belum diisi!", Type = "error", Duration = 3 })
                return
            end
            WebhookModule:EnableDisconnectWebhook(true)
            Window:Notify({ Title = "Disconnect Webhook", Content = "Disconnect webhook aktif!", Type = "success", Duration = 3 })
        else
            WebhookModule:EnableDisconnectWebhook(false)
            Window:Notify({ Title = "Disconnect Webhook", Content = "Disconnect webhook dimatikan.", Type = "info", Duration = 3 })
        end
    end
})

DisconnectSection:CreateButton({
    Id = "disconnect_webhook_test",
    Title = "Test Disconnect Webhook",
    Icon = "send",
    Callback = function()
        if WebhookModule.DisconnectConfig.WebhookURL == "" then
            Window:Notify({ Title = "Webhook", Content = "URL belum diisi!", Type = "error", Duration = 3 })
            return
        end
        WebhookModule:TestDisconnectWebhook()
        Window:Notify({ Title = "Disconnect Webhook Test", Content = "Test dikirim!", Type = "success", Duration = 3 })
    end
})

-- =============================================
-- LEADERBOARD WEBHOOK SECTION
-- =============================================
local LeaderboardSection = WebhookTab:CreateSection({ Title = "Leaderboard Webhook", Box = true, Opened = false })

LeaderboardSection:CreateInput({
    Id = "leaderboard_webhook_url",
    Title = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default = "",
    Callback = function(v)
        local val = v:gsub("^%s*(.-)%s*$", "%1")
        WebhookModule.LeaderboardConfig.WebhookURL = val
    end
})

LeaderboardSection:CreateInput({
    Id = "leaderboard_discord_user_id",
    Title = "Discord User ID",
    Placeholder = "123456789012345678",
    Default = "",
    Callback = function(v)
        local val = v:gsub("^%s*(.-)%s*$", "%1")
        WebhookModule.LeaderboardConfig.DiscordUserID = val
    end
})

LeaderboardSection:CreateInput({
    Id = "leaderboard_custom_name",
    Title = "Custom Name",
    Placeholder = "Masukkan nama custom...",
    Default = "",
    Callback = function(v)
        local val = v:gsub("^%s*(.-)%s*$", "%1")
        WebhookModule.LeaderboardConfig.HideIdentity = val
    end
})

LeaderboardSection:CreateInput({
    Id = "leaderboard_delay_minutes",
    Title = "Delay (Minutes)",
    Placeholder = "5",
    Default = "5",
    Callback = function(v)
        local val = tonumber(v:gsub("^%s*(.-)%s*$", "%1"))
        if val and val > 0 then
            WebhookModule.LeaderboardConfig.DelayMinutes = val
            -- Restart kalau lagi jalan biar delay baru kepake
            if WebhookModule:IsLeaderboardRunning() then
                WebhookModule:StopLeaderboardWebhook()
                WebhookModule:StartLeaderboardWebhook()
            end
        end
    end
})

local leaderboardToggleRef = LeaderboardSection:CreateToggle({
    Id = "leaderboard_webhook_toggle",
    Title = "Enable Leaderboard Webhook",
    Icon = "award",
    Default = false,
    Callback = function(state)
        if state then
            if WebhookModule.LeaderboardConfig.WebhookURL == "" then
                Window:Notify({ Title = "Webhook", Content = "URL belum diisi!", Type = "error", Duration = 3 })
                leaderboardToggleRef.Set(false)
                return
            end
            local ok = WebhookModule:StartLeaderboardWebhook()
            if ok then
                Window:Notify({ Title = "Leaderboard Webhook", Content = "Leaderboard webhook aktif!", Type = "success", Duration = 3 })
            else
                leaderboardToggleRef.Set(false)
            end
        else
            WebhookModule:StopLeaderboardWebhook()
            Window:Notify({ Title = "Leaderboard Webhook", Content = "Leaderboard webhook dimatikan.", Type = "info", Duration = 3 })
        end
    end
})

LeaderboardSection:CreateButton({
    Id = "leaderboard_webhook_test",
    Title = "Test Leaderboard Webhook",
    Icon = "send",
    Callback = function()
        if WebhookModule.LeaderboardConfig.WebhookURL == "" then
            Window:Notify({ Title = "Webhook", Content = "URL belum diisi!", Type = "error", Duration = 3 })
            return
        end
        local ok = WebhookModule:TestLeaderboardWebhook()
        Window:Notify({ 
            Title = "Leaderboard Webhook Test", 
            Content = ok and "Test berhasil dikirim!" or "Gagal mengirim test.", 
            Type = ok and "success" or "error", 
            Duration = 3 
        })
    end
})


-- ================================================================
--  Settings Tab
-- ================================================================
Loader:Set(0.9, "Settings")
task.wait()
local SettingsTab = Window:CreateTab({ Title = "Settings", Icon = "" })

-- =============================================
-- PROTECTION SECTION
-- =============================================
local ProtectionSection = SettingsTab:CreateSection({ Title = "Protection", Box = true, Opened = true })

-- =============================================
-- ANTI-AFK MODULE
-- =============================================
local AntiAFK = (function()
    local AA = {
        Enabled = false,
        Thread = nil,
        Conn = nil,
    }
    
    function AA.Start()
        if AA.Enabled then return end
        AA.Enabled = true
        local VirtualUser = game:GetService("VirtualUser")
        
        -- Bypass Anti-AFK Roblox native yang paling ampuh
        AA.Conn = game:GetService("Players").LocalPlayer.Idled:Connect(function()
            if AA.Enabled then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                print("[Anti-AFK] Roblox Idle bypassed!")
            end
        end)
        
        AA.Thread = task.spawn(function()
            while AA.Enabled do
                task.wait(600)
                if not AA.Enabled then break end
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end
        end)
    end
    
    function AA.Stop()
        if not AA.Enabled then return end
        AA.Enabled = false
        if AA.Thread then
            task.cancel(AA.Thread)
            AA.Thread = nil
        end
        if AA.Conn then
            AA.Conn:Disconnect()
            AA.Conn = nil
        end
    end
    
    return AA
end)()

ProtectionSection:CreateToggle({
    Id = "anti_afk_toggle",
    Title = "Anti-AFK",
    Icon = "shield-check",
    Default = false,
    Callback = function(state)
        if state then
            AntiAFK.Start()
            Window:Notify({ Title = "Anti-AFK", Content = "Anti-AFK aktif!", Type = "success", Duration = 3 })
        else
            AntiAFK.Stop()
            Window:Notify({ Title = "Anti-AFK", Content = "Anti-AFK dimatikan.", Type = "info", Duration = 3 })
        end
    end
})

-- =============================================
-- ANTI-ADMIN MODULE
-- =============================================
local AntiAdmin = (function()
    local AA = {
        Enabled = false,
        Conns = {},
        Kicked = false,
        PlayerConns = {}
    }
    
    local STAFF_KEYWORDS = {
        "admin", "mod", "moderator", "staff", "owner", "developer",
        "dev", "manager", "supervisor", "helper"
    }
    
    local function isAdminByAttribute(player)
        return player:GetAttribute("IsAdmin") == true
            or player:GetAttribute("IsPrimaryAdmin") == true
            or (player:GetAttribute("AdminAccess") ~= nil and player:GetAttribute("AdminAccess") ~= "")
    end
    
    local function checkAdminByGroupRole(player, onDetected)
        task.spawn(function()
            if not player or not player.Parent then return end
            local ok, role = pcall(function()
                return player:GetRoleInGroup(game.CreatorId)
            end)
            if not ok or not role then return end
            local roleLower = role:lower()
            
            for _, keyword in ipairs(STAFF_KEYWORDS) do
                if roleLower:find(keyword) then
                    onDetected(player, "GroupRole: " .. role)
                    return
                end
            end
        end)
    end
    
    local function isAdmin(player)
        return isAdminByAttribute(player)
    end
    
    local function safeKick(reason)
        warn("🚨 " .. reason)
        warn("🚪 Auto-kick untuk keamanan!")
        local LP = game:GetService("Players").LocalPlayer
        LP:Kick("🚨 SAFETY KICK\n" .. reason .. "\nScript otomatis keluar untuk keamanan.")
    end
    
    local function checkAdmin(player, context)
        if AA.Kicked then return end
        local LP = game:GetService("Players").LocalPlayer
        if player == LP then return end
        
        if isAdmin(player) then
            AA.Kicked = true
            safeKick("ADMIN/STAFF TERDETEKSI!\nNama: " .. player.Name .. "\nKonteks: " .. context)
            return
        end
        
        if game.CreatorType == Enum.CreatorType.Group then
            checkAdminByGroupRole(player, function(p, ctx)
                if AA.Kicked then return end
                AA.Kicked = true
                safeKick("STAFF/ADMIN TERDETEKSI (GROUP)!\nNama: " .. p.Name .. "\nKonteks: " .. ctx)
            end)
        end
    end
    
    local function cleanupPlayerConns(player)
        if AA.PlayerConns[player] then
            for _, conn in ipairs(AA.PlayerConns[player]) do
                if conn then conn:Disconnect() end
            end
            AA.PlayerConns[player] = nil
        end
    end
    
    local function setupPlayerListeners(player)
        cleanupPlayerConns(player)
        AA.PlayerConns[player] = {}
        table.insert(AA.PlayerConns[player], player:GetAttributeChangedSignal("IsAdmin"):Connect(function()
            if AA.Enabled then checkAdmin(player, "IsAdmin berubah jadi true") end
        end))
        table.insert(AA.PlayerConns[player], player:GetAttributeChangedSignal("IsPrimaryAdmin"):Connect(function()
            if AA.Enabled then checkAdmin(player, "IsPrimaryAdmin berubah jadi true") end
        end))
        table.insert(AA.PlayerConns[player], player:GetAttributeChangedSignal("AdminAccess"):Connect(function()
            if AA.Enabled then checkAdmin(player, "AdminAccess berubah") end
        end))
    end
    
    function AA.Start()
        if AA.Enabled then return end
        AA.Enabled = true
        AA.Kicked = false
        local Players = game:GetService("Players")
        local LP = Players.LocalPlayer
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LP then
                print("✅ " .. player.Name .. " = kamu sendiri")
            elseif isAdmin(player) then
                checkAdmin(player, "Already in server")
            else
                print("✅ " .. player.Name .. " = player biasa")
            end
        end
        
        table.insert(AA.Conns, Players.PlayerAdded:Connect(function(player)
            if not AA.Enabled then return end
            task.wait(1)
            checkAdmin(player, "Baru join server")
            setupPlayerListeners(player)
        end))
        
        table.insert(AA.Conns, Players.PlayerRemoving:Connect(function(player)
            cleanupPlayerConns(player)
        end))
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LP then continue end
            setupPlayerListeners(player)
        end
        
        print("🛡️ Anti-Admin aktif! Auto-kick kalau ada admin masuk.")
    end
    
    function AA.Stop()
        if not AA.Enabled then return end
        AA.Enabled = false
        for _, conn in ipairs(AA.Conns) do
            if conn then conn:Disconnect() end
        end
        AA.Conns = {}
        for player, _ in pairs(AA.PlayerConns) do
            cleanupPlayerConns(player)
        end
        AA.PlayerConns = {}
        AA.Kicked = false
        print("🛡️ Anti-Admin mati!")
    end
    
    return AA
end)()

ProtectionSection:CreateToggle({
    Id = "anti_admin_toggle",
    Title = "Anti Staff/Admin",
    Icon = "shield",
    Default = false,
    Callback = function(state)
        if state then
            AntiAdmin.Start()
            Window:Notify({ Title = "Anti-Admin", Content = "Auto-kick kalau ada staff masuk!", Type = "success", Duration = 3 })
        else
            AntiAdmin.Stop()
            Window:Notify({ Title = "Anti-Admin", Content = "Anti-admin dimatikan.", Type = "info", Duration = 3 })
        end
    end
})

-- =============================================
-- CONFIG SECTION
-- =============================================
local ConfigSection = SettingsTab:CreateSection({ Title = "Config", Box = true, Opened = false })

local function cfgNotify(content, kind, dur)
	Window:Notify({ Title = "Config", Content = content, Type = kind or "info", Duration = dur or 3 })
end

-- baca clipboard (support macam-macam executor)
local function getClipboard()
	local fn = (getclipboard or getclipboardtext or readclipboard
		or (syn and syn.get_clipboard) or (getgenv and getgenv().getclipboard))
	if not fn then return nil end
	local ok, res = pcall(fn)
	if ok then return res end
	return nil
end

-- 1) Copy config kamu ke clipboard (buat dibagi ke orang lain)
ConfigSection:CreateButton({
	Id = "copy_config_btn",
	Title = "Copy Your Config",
	Icon = "copy",
	Callback = function()
		if not setclipboard then
			return cfgNotify("Executor tidak support setclipboard!", "error")
		end
		local ok, jsonStr = pcall(function() return Vypers:GetConfigJSON() end)
		if ok and jsonStr and jsonStr ~= "" then
			setclipboard(jsonStr)
			cfgNotify("Config berhasil dicopy ke clipboard!", "success")
		else
			cfgNotify("Gagal meng-copy config!", "error")
		end
	end,
})

-- 2) Input paste (paling atas dari grup load)
local sharedConfigInput = ""
local loadConfigInput = ConfigSection:CreateInput({
	Id = "load_config_input",
	Title = "Load Config",
	Placeholder = "Paste config JSON disini...",
	Default = "",
	Callback = function(v)
		sharedConfigInput = (v or ""):gsub("^%s*(.-)%s*$", "%1")
	end,
})

-- 3) Dua button bersebelahan: Load Config | Paste Config
ConfigSection:CreateButtonRow({
	Buttons = {
		{
			Title = "Load Config",
			Callback = function()
				if sharedConfigInput == "" then
					return cfgNotify("Input config kosong!", "warning")
				end
				local ok, result = pcall(function()
					return Vypers:LoadConfigFromJSON(sharedConfigInput)
				end)
				if ok and result then
					cfgNotify("Config berhasil di-load!", "success", 5)
				else
					cfgNotify("Gagal meload config! Pastikan format JSON valid.", "error")
				end
			end,
		},
		{
			Title = "Paste Config",
			Callback = function()
				local text = getClipboard()
				if not text or text == "" then
					return cfgNotify("Clipboard kosong / executor tidak support,paste manual!", "error")
				end
				text = text:gsub("^%s*(.-)%s*$", "%1")
				sharedConfigInput = text
				loadConfigInput.Set(text)   -- otomatis masuk ke input
				cfgNotify("Config di-paste! Sekarang tekan Load Config.", "success")
			end,
		},
	},
})

-- 4) Reset ke default
-- 4) Restore & Delete bersebelahan
ConfigSection:CreateButtonRow({
	Buttons = {
		{
			Title = "Restore Config Default",
			Callback = function()
				local ok = pcall(function() Vypers:ResetConfig() end)
				if ok then
					cfgNotify("Config dikembalikan ke default!", "success", 5)
				else
					cfgNotify("Gagal restore config!", "error")
				end
			end,
		},
		{
			Title = "Delete Config",
			Color = Color3.fromRGB(200, 60, 60),  -- merah, tanda aksi hapus
			Callback = function()
				local ok = pcall(function() Vypers:DeleteConfig() end)
				-- bersihin juga input & config yang lagi kepaste
				sharedConfigInput = ""
				pcall(function() loadConfigInput.Set("") end)
				if ok then
					cfgNotify("Config tersimpan dihapus & input dibersihkan!", "success", 5)
				else
					cfgNotify("Gagal menghapus config!", "error")
				end
			end,
		},
	},
})

-- =============================================
-- CUSTOM SETTINGS SECTION
-- =============================================
Loader:Set(0.95, "Custom Settings")
task.wait()
local CustomSection = SettingsTab:CreateSection({ Title = "Custom Settings", Box = true, Opened = false })

-- =============================================
-- AUTO REJOIN & AUTO EXECUTE MODULE
-- =============================================
local AutoRejoin = (function()
    local AR = {}
    AR.Enabled = false
    AR.AutoExecEnabled = false
    AR.AutoToPosEnabled = false
    AR.SavedCFrame = nil      -- Menyimpan CFrame (Posisi + Rotasi)
    AR.SavedPlaceId = nil     -- Menyimpan ID Map tempat posisi di-save

    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local disconnectSetup = false
    local hasTriggered = false

    local SCRIPT_URL = "https://raw.githubusercontent.com/AwoakwoakSikat/emangbowleh/refs/heads/main/loader-news.lua" 
    local EXEC_DELAY = 15 

    local function getQueueOnTeleport()
        local getQueue = nil
        pcall(function() getQueue = queue_on_teleport end)
        if getQueue then return getQueue end
        pcall(function() getQueue = queueonteleport end)
        if getQueue then return getQueue end
        pcall(function() getQueue = syn and syn.queue_on_teleport end)
        if getQueue then return getQueue end
        pcall(function() getQueue = fluxus and fluxus.queue_on_teleport end)
        if getQueue then return getQueue end
        pcall(function() getQueue = solara and solara.queue_on_teleport end)
        if getQueue then return getQueue end
        return nil
    end

    local autoExecQueued = false
    local function setupAutoExecuteQueue()
        if autoExecQueued then return true end
        local queueTeleport = getQueueOnTeleport()
        if not queueTeleport then 
            warn("[Auto Rejoin] Executor lu tidak mendukung queue_on_teleport!")
            return false 
        end
        if not AR.AutoExecEnabled then return false end

        -- Siapkan data posisi jika Auto To Position aktif DAN ada data yang tersimpan
        local positionTweenCode = ""
        if AR.AutoToPosEnabled and AR.SavedCFrame and AR.SavedPlaceId then
            -- Ambil 12 komponen CFrame (X, Y, Z + 9 matriks rotasi)
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = AR.SavedCFrame:components()
            local savedPlaceId = AR.SavedPlaceId
            
            -- Suntikkan pengecekan PlaceId di dalam kode yang akan di-execute nanti
            positionTweenCode = string.format([[
                task.wait(%d) -- Tunggu sedikit lebih lama dari EXEC_DELAY agar karakter & UI selesai load
                pcall(function()
                    if game.PlaceId == %d then
                        local player = game:GetService("Players").LocalPlayer
                        local character = player.Character or player.CharacterAdded:Wait()
                        local hrp = character:WaitForChild("HumanoidRootPart", 5)
                        if hrp then
                            local targetCFrame = CFrame.new(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)
                            local TweenService = game:GetService("TweenService")
                            local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                            tween:Play()
                            print("[Auto Exec] Kembali ke spot mancing yang disimpan di map ini!")
                        end
                    else
                        print("[Auto Exec] Posisi tersimpan untuk map lain (ID: %d). Skip tween agar tidak nyangkut.")
                    end
                end)
            ]], EXEC_DELAY + 2, savedPlaceId, x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22, savedPlaceId)
        end

        -- Gabungkan kode eksekusi utama dengan kode tween posisi
        local autoExecCode = string.format([[
            task.wait(%d)
            pcall(function()
                print("[Auto Exec] Menjalankan script setelah rejoin...")
                loadstring(game:HttpGet("%s"))()
            end)
            %s
        ]], EXEC_DELAY, SCRIPT_URL, positionTweenCode)

        local ok = pcall(function() queueTeleport(autoExecCode) end)
        if ok then 
            autoExecQueued = true 
            print("[Auto Rejoin] Queue on teleport berhasil diatur!")
        end
        return ok
    end

    local function doRejoin()
        if hasTriggered then return end
        if not AR.Enabled then return end
        hasTriggered = true

        print("[Auto Rejoin] Terdeteksi kick/disconnect! Melakukan rejoin...")
        
        if AR.AutoExecEnabled then
            setupAutoExecuteQueue()
        end

        task.spawn(function()
            local attempt = 0
            while attempt < 5 do 
                attempt += 1
                local success, err = pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
                
                if success then
                    print("[Auto Rejoin] Perintah teleport dikirim!")
                    break
                else
                    print("[Auto Rejoin] Gagal teleport, mencoba lagi dalam 3 detik... ("..attempt.."/5)")
                    task.wait(3)
                end
            end
        end)
    end

    local function setupDetection()
        if disconnectSetup then return end
        disconnectSetup = true

        pcall(function()
            game:GetService("GuiService").ErrorMessageChanged:Connect(function(message)
                if message and message ~= "" and AR.Enabled then
                    task.wait(1)
                    doRejoin()
                end
            end)
        end)

        pcall(function()
            local CoreGui = game:GetService("CoreGui")
            local RobloxPromptGui = CoreGui:WaitForChild("RobloxPromptGui", 5)
            if RobloxPromptGui then
                local promptOverlay = RobloxPromptGui:WaitForChild("promptOverlay", 5)
                if promptOverlay then
                    promptOverlay.ChildAdded:Connect(function(child)
                        if child.Name == "ErrorPrompt" and AR.Enabled then
                            task.wait(0.5)
                            doRejoin()
                        end
                    end)
                end
            end
        end)

        pcall(function()
            LocalPlayer.Idled:Connect(function(t)
                if t > 1150 and AR.Enabled then 
                    print("[Auto Rejoin] Terdeteksi Idle Kick, rejoining...")
                    doRejoin()
                end
            end)
        end)
    end

    -- Public Functions
    function AR.Start()
        if AR.Enabled then return end
        AR.Enabled = true
        hasTriggered = false
        setupDetection()
        if AR.AutoExecEnabled then setupAutoExecuteQueue() end
        print("[Auto Rejoin] Fitur diaktifkan.")
    end

    function AR.Stop()
        AR.Enabled = false
        hasTriggered = false
        print("[Auto Rejoin] Fitur dinonaktifkan.")
    end

    function AR.EnableAutoExec()
        AR.AutoExecEnabled = true
        if AR.Enabled then setupAutoExecuteQueue() end
    end

    function AR.DisableAutoExec()
        AR.AutoExecEnabled = false
        autoExecQueued = false
    end

    function AR.SetScriptURL(url)
        if type(url) == "string" and url ~= "" then
            SCRIPT_URL = url
            autoExecQueued = false
        end
    end

    function AR.IsQueueSupported()
        return getQueueOnTeleport() ~= nil
    end

    -- Fungsi Save Position (Update: Simpan PlaceId juga)
    function AR.SavePosition()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            AR.SavedCFrame = hrp.CFrame
            AR.SavedPlaceId = game.PlaceId
            print("[Auto Rejoin] Posisi berhasil disimpan di Map ID:", AR.SavedPlaceId, AR.SavedCFrame.Position)
            return true
        end
        return false
    end

    -- Fungsi Clear Position (Update: Reset PlaceId juga)
    function AR.ClearPosition()
        AR.SavedCFrame = nil
        AR.SavedPlaceId = nil
        print("[Auto Rejoin] Posisi yang disimpan telah dihapus.")
    end

    -- =====================================================
    -- DATA LOKASI ISLAND (diambil dari data "Teleport to Island")
    -- Dipakai buat deteksi otomatis lu lagi mancing paling deket island mana.
    -- =====================================================
    AR.Islands = {
        { name = "Bamboo",            pos = Vector3.new(-1364.95, 180.10, 320.49) },
        { name = "Iceberg",           pos = Vector3.new(-582.31, 190.07, -529.37) },
        { name = "Lost Whale Island", pos = Vector3.new(-2676.25, 179.97, 39.09) },
        { name = "Bora Reef",         pos = Vector3.new(-3996.39, 171.44, 2028.85) },
        { name = "Volcano Vent",      pos = Vector3.new(-1686.41, 173.81, 5931.25) },
        { name = "Cape Town",         pos = Vector3.new(804.61, 187.62, 2952.89) },
        { name = "Mystic Mangrove",   pos = Vector3.new(4428.54, 176.34, 1155.71) },
    }

    -- Cari island terdekat dari sebuah posisi. Return: nama, jarak (studs)
    function AR.GetNearestIsland(position)
        if not position then return nil, nil end
        local nearest, bestDist = nil, math.huge
        for _, isl in ipairs(AR.Islands) do
            local d = (position - isl.pos).Magnitude
            if d < bestDist then
                bestDist = d
                nearest = isl
            end
        end
        if nearest then return nearest.name, bestDist end
        return nil, nil
    end

    -- Label lokasi (nama island terdekat) buat posisi yang lagi disimpan.
    -- Kalau jaraknya deket (<= 800 studs) langsung pakai namanya, kalau jauh dikasih "Near".
    function AR.GetNearestIslandLabel(position)
        position = position or (AR.SavedCFrame and AR.SavedCFrame.Position)
        local name, dist = AR.GetNearestIsland(position)
        if name then
            if dist <= 800 then
                return name
            else
                return "Near " .. name
            end
        end
        return "Open Sea"
    end

    -- Ambil label lokasi realtime dari posisi karakter SEKARANG (belum tentu di-save).
    function AR.GetCurrentIslandLabel()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then return "Karakter belum spawn" end
        return AR.GetNearestIslandLabel(hrp.Position)
    end

    -- Fungsi Get String (Update: Tampilkan nama Island terdekat + Map)
    function AR.GetSavedPositionString()
        if AR.SavedCFrame and AR.SavedPlaceId then
            local mapName = "Unknown Map"
            if AR.SavedPlaceId == 90457367396205 then
                mapName = "Explore Island"
            elseif AR.SavedPlaceId == 111385005478215 then
                mapName = "Base Map"
            else
                mapName = "Map " .. AR.SavedPlaceId
            end

            -- Nama spot = island terdekat (hanya relevan di map Explore Island)
            local spot
            if AR.SavedPlaceId == 90457367396205 then
                spot = AR.GetNearestIslandLabel(AR.SavedCFrame.Position)
            else
                spot = mapName
            end

            return string.format("%s @ %s (X: %.1f, Y: %.1f, Z: %.1f)", spot, mapName,
                AR.SavedCFrame.Position.X, AR.SavedCFrame.Position.Y, AR.SavedCFrame.Position.Z)
        end
        return "Belum ada posisi disimpan"
    end

    return AR
end)()

-- =============================================
-- UI ELEMENTS FOR AUTO REJOIN & POSITION
-- =============================================

-- 1. Toggle Auto Rejoin
CustomSection:CreateToggle({
    Id = "auto_rejoin_toggle",
    Title = "Auto Rejoin on Kick",
    Icon = "refresh-ccw",
    Default = false,
    Callback = function(state)
        if state then
            AutoRejoin.Start()
            Window:Notify({ Title = "Auto Rejoin", Content = "Fitur Auto Rejoin diaktifkan!", Type = "success", Duration = 3 })
        else
            AutoRejoin.Stop()
            Window:Notify({ Title = "Auto Rejoin", Content = "Fitur Auto Rejoin dinonaktifkan.", Type = "info", Duration = 3 })
        end
    end
})

-- 2. Toggle Auto Execute
CustomSection:CreateToggle({
    Id = "auto_exec_toggle",
    Title = "Auto Execute after Rejoin",
    Icon = "code",
    Default = false,
    Callback = function(state)
        if state then
            if not AutoRejoin.IsQueueSupported() then
                Window:Notify({ Title = "Auto Execute", Content = "Executor lu mungkin tidak mendukung queue_on_teleport!", Type = "warning", Duration = 4 })
            end
            AutoRejoin.EnableAutoExec()
            Window:Notify({ Title = "Auto Execute", Content = "Akan auto execute 15 detik setelah rejoin.", Type = "success", Duration = 3 })
        else
            AutoRejoin.DisableAutoExec()
            Window:Notify({ Title = "Auto Execute", Content = "Auto Execute dinonaktifkan.", Type = "info", Duration = 3 })
        end
    end
})

CustomSection:CreateDivider()
CustomSection:CreateSpace(4)

-- 3. 🎣 STATUS + SAVE/CLEAR (SIDE BY SIDE) 🎣
local statusLabel

local function refreshStatusLabel()
    if not statusLabel then return end
    if AutoRejoin.SavedCFrame then
        statusLabel.SetTitle("📍 Saved Spot: " .. AutoRejoin.GetSavedPositionString())
    else
        statusLabel.SetTitle("📡 Lokasi Sekarang: " .. AutoRejoin.GetCurrentIslandLabel())
    end
end

CustomSection:CreateButtonRow({
    Buttons = {
        {
            Title = "💾 Save Lokasi",
            Color = Color3.fromRGB(80, 190, 120),
            Callback = function()
                local success = AutoRejoin.SavePosition()
                if success then
                    local spot = AutoRejoin.GetNearestIslandLabel()
                    Window:Notify({
                        Title = "Posisi Disimpan",
                        Content = "Spot mancing di '" .. spot .. "' berhasil disimpan! Bakal otomatis balik ke sini setelah rejoin (map yang sama).",
                        Type = "success",
                        Duration = 3
                    })
                    refreshStatusLabel()
                else
                    Window:Notify({
                        Title = "Gagal Menyimpan",
                        Content = "Karakter tidak ditemukan. Pastikan lu sudah spawn di game.",
                        Type = "error",
                        Duration = 3
                    })
                end
            end
        },
        {
            Title = "🗑️ Hapus Lokasi",
            Color = Color3.fromRGB(220, 90, 90),
            Callback = function()
                AutoRejoin.ClearPosition()
                refreshStatusLabel()
                Window:Notify({ Title = "Dihapus", Content = "Posisi yang disimpan telah dihapus.", Type = "info", Duration = 2 })
            end
        },
    }
})

statusLabel = CustomSection:CreateLabel({
    Id = "saved_position_label",
    Title = "📡 Lokasi Sekarang: -",
    Description = "Update realtime pas klik Save / Clear."
})

task.spawn(function()
    while true do
        pcall(refreshStatusLabel)
        task.wait(0.5)
    end
end)

-- 4. Toggle Auto To Saved Position
CustomSection:CreateToggle({
    Id = "auto_to_position_toggle",
    Title = "Auto Return to Saved Spot",
    Icon = "navigation",
    Default = false,
    Callback = function(state)
        AutoRejoin.AutoToPosEnabled = state
        if state then
            if not AutoRejoin.SavedCFrame then
                Window:Notify({
                    Title = "Peringatan",
                    Content = "Lu belum save posisi apapun! Klik 'Save Lokasi' dulu.",
                    Type = "warning",
                    Duration = 4
                })
            else
                Window:Notify({
                    Title = "Auto Return Aktif",
                    Content = "Player akan otomatis tween ke spot yang disimpan (jika map-nya sama) setelah rejoin.",
                    Type = "success",
                    Duration = 3
                })
            end
        else
            Window:Notify({ Title = "Auto Return", Content = "Fitur kembali ke spot dinonaktifkan.", Type = "info", Duration = 3 })
        end
    end
})

-- 5. 🏃‍♂️ BUTTON: GO TO SAVED LOCATION (TWEEN) 🏃‍♂️
CustomSection:CreateButton({
    Id = "go_to_saved_location_btn",
    Title = "🏃‍♂️ Go to Saved Location (Tween)",
    Icon = "map-pin",
    Callback = function()
        -- 1. Cek apakah ada data yang di-save
        if not AutoRejoin.SavedCFrame then
            Window:Notify({
                Title = "Gagal",
                Content = "Belum ada lokasi yang disimpan! Klik 'Save Lokasi' dulu.",
                Type = "error",
                Duration = 3
            })
            return
        end

        -- 2. Cek apakah player berada di map yang sama dengan lokasi yang di-save
        if game.PlaceId ~= AutoRejoin.SavedPlaceId then
            Window:Notify({
                Title = "Salah Map",
                Content = "Lokasi tersimpan ada di map lain. Pindah ke map tersebut dulu!",
                Type = "warning",
                Duration = 3
            })
            return
        end

        -- 3. Eksekusi Tween
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")

        if not hrp then
            Window:Notify({
                Title = "Gagal",
                Content = "Karakter tidak ditemukan!",
                Type = "error",
                Duration = 3
            })
            return
        end

        Window:Notify({
            Title = "Menuju Lokasi",
            Content = "Sedang tween ke lokasi yang disimpan...",
            Type = "info",
            Duration = 2
        })

        local TweenService = game:GetService("TweenService")
        -- Tween selama 3 detik dengan gaya Quad agar mulus
        local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = AutoRejoin.SavedCFrame})
        
        tween:Play()
        
        -- Notif pas sampai
        tween.Completed:Connect(function()
            Window:Notify({
                Title = "Berhasil",
                Content = "Sampai di lokasi yang disimpan!",
                Type = "success",
                Duration = 3
            })
        end)
    end
})
-- 7. 🚨 TEST KICK BUTTON 🚨
-- CustomSection:CreateButton({
--     Id = "test_kick_button",
--     Title = "🚨 Test Kick (Uji Auto Rejoin & Return)",
--     Icon = "alert-triangle",
--     Callback = function()
--         if not AutoRejoin.Enabled then
--             Window:Notify({ Title = "Test Kick Gagal", Content = "Nyalakan dulu toggle 'Auto Rejoin on Kick' sebelum test!", Type = "error", Duration = 3 })
--             return
--         end

--         Window:Notify({ Title = "Test Kick", Content = "Mengkick player dalam 2 detik untuk test...", Type = "warning", Duration = 2 })
        
--         task.delay(2, function()
--             local LocalPlayer = game:GetService("Players").LocalPlayer
--             LocalPlayer:Kick("[TEST] Menguji fitur Auto Rejoin, Auto Execute & Auto Return to Position")
--         end)
--     end
-- })
-- ================================================================
--  TAB About
-- ================================================================
Loader:Set(0.97, "About")
task.wait()
local home = Window:CreateTab({ Title = "About", Icon = "" })
local welcome = home:CreateSection({ Title = "About", Opened = true })


-- Paragraph + gambar (sekarang FULL, ImageScaleType = "Crop")
local introPara = welcome:CreateParagraph({
	Id    = "intro",
	Text  = "Crafting smooth, clean, and powerful Roblox scripts with a focus on quality and performance.",
	Image = "rbxassetid://97514324988224",
	ImageHeight = 110,
	ImageScaleType = "Crop",   -- << gambar full penuhin card, gak ada bar hitam lagi
	Buttons = {
		{ Title = "Primary",   Variant = "Primary",   Icon = "bolt", Callback = function() Window:Notify({ Title = "Primary", Content = "Diklik!", Type = "success" }) end },
		{ Title = "Secondary", Variant = "Secondary", Callback = function() print("secondary") end },
		{ Title = "Tertiary",  Variant = "Tertiary",  Callback = function() print("tertiary") end },
	},
})

local statusLabel = welcome:CreateLabel({ Id = "status", Title = "Status: idle" })
welcome:CreateDivider()
-- >>> KARTU DEVELOPERS (compact, bisa banyak orang) <<<
welcome:CreateDevelopers({
	Id     = "devs",
	Title  = "Developers By:",                       -- header (opsional)
	Accent = Color3.fromRGB(120, 90, 240),       -- warna ring default (opsional)
	AvatarSize = 30,                             -- kecilin/gedein avatar (opsional)
	List = {
		{
			Name  = "King Vypers",
			Role  = "Lead Developer",
			Image = "rbxassetid://139467646163013",
		},
		{
			Name  = "King Akbar",
			Role  = "Co-Developer",
			Image = "rbxassetid://84070081307966",       -- ganti assetid foto temenmu
			Accent = Color3.fromRGB(80, 190, 120),   -- ring beda warna (opsional per orang)
		},
		-- tambah lagi kalau perlu:
		-- { Name = "...", Role = "...", Image = "rbxassetid://..." },
	},
})

welcome:CreateSpace(4)

welcome:CreateSpace(6)
welcome:CreateTag({ Id = "ver", Title = "Versi Library", Text = "v0.2", Color = Color3.fromRGB(120, 90, 240) })


-- ================================================================
--  ENABLE CONFIG  (PALING AKHIR) — DEFERRED biar ga nge-frame
-- ================================================================
-- ================================================================
--  SELESAI: load config -> tutup loading -> baru munculin window
-- ================================================================
Loader:Set(0.99, "Memuat konfigurasi")
task.wait()

local ok, err = pcall(function()
    Vypers:EnableConfig("default")
end)
if not ok then
    warn("[King Vypers] Gagal load config:", err)
end

-- isi bar ke 100%, fade out loading, LALU reveal window (anti nge-frame)
Loader:Finish(function()
    Window:Show()
    Window:Notify({
        Title = "King Vypers",
        Content = "Script berhasil di-load! Semua fitur siap digunakan.",
        Type = "success",
        Duration = 4,
    })
end)
