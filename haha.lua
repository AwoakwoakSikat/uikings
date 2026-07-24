--[[
    =====================================================================
      VYPERS UI - CONTOH FULL FITUR
    ---------------------------------------------------------------
      Ganti RAW_URL sama link raw GitHub punya lo.
    =====================================================================
]]

-- ====== LOAD LIBRARY (via raw GitHub) =========================
local RAW_URL = "https://raw.githubusercontent.com/AwoakwoakSikat/uikings/refs/heads/main/VypersLib33.lua"
local Vypers = loadstring(game:HttpGet(RAW_URL))()

-- ====== SERVICES / STATE ======================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    WalkSpeed = 16,
    JumpPower = 50,
    AutoFarm  = false,
    ESPColor  = Color3.fromRGB(91, 155, 213),
}

local function playerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(names, p.Name)
    end
    return names
end

-- ====== KONFIG GLOBAL (opsional) ==============================
Vypers:SetFolder("VypersDemo")
Vypers:SetAccent(Color3.fromRGB(120, 90, 240))

-- ====== BIKIN WINDOW ==========================================
local Window = Vypers:CreateWindow({
    Title       = "King Vypers",
    Icon        = "rbxassetid://139467646163013", -- logo pas window di-minimize
    FloatIconRadius = 14,   -- sudut logo minimize: 0 = kotak tajam, 14 = squircle, 25 = bulat penuh
    Background   = "rbxassetid://97514324988224", -- gambar backdrop window
    SubTitle    = "v2.0",
    Author      = "by Yeremia",
    Size = UDim2.new(0, 530, 0, 300),
    MinSize = Vector2.new(530, 300),
    MaxSize = Vector2.new(530, 300),
    SideBarWidth= 150,
    Resizable   = true,
    Transparent = true,  -- efek glass (false = solid, transparansi mati)

    -- =========================================================
    --  ATUR TRANSPARANSI DI SINI  (0 = solid, 1 = ilang total)
    --  makin gede angkanya = makin tembus = gambar makin keliatan
    -- =========================================================
    SurfaceTransparency = 0.5,   -- card tiap element (slider/toggle/button/dll)
    SectionTransparency = 0.85,  -- panel/box section (Movement, Combat, dll)
    TabTransparency     = 0.4,   -- tombol tab di sidebar (Main, Player, dll)
    Overlay             = 0.3,   -- tint gelap DI ATAS gambar (0 terang, 1 gelap)

    -- =========================================================
    --  ATUR WARNA BACKGROUND ITEM DI SINI
    --  (comment/hapus yang ga dipakai kalau mau warna default)
    -- =========================================================
    ItemColor    = Color3.fromRGB(40, 40, 60),   -- card tiap element
    SectionColor = Color3.fromRGB(28, 28, 44),   -- panel section + title bar
    TabColor     = Color3.fromRGB(34, 34, 52),   -- tombol tab sidebar
    WindowColor  = Color3.fromRGB(20, 20, 30),   -- warna dasar window
    Accent       = Color3.fromRGB(120, 90, 240), -- warna aksen (tab aktif)
    -- Atau override penuh sekaligus:
    -- Theme = { Surface = ..., SurfaceLight = ..., Border = ..., Text = ... },

    ToggleKey   = Enum.KeyCode.RightShift,
    Folder      = "VypersDemo",
})

Window:Tag({ Title = "BETA",   Color = Color3.fromRGB(220, 180, 70) })
Window:Tag({ Title = "Online", Icon = "bolt", Color = Color3.fromRGB(80, 190, 120) })

-- =====================================================================
--  TAB 1: MAIN
-- =====================================================================
local mainTab = Window:CreateTab({ Title = "Main", Icon = "home" })

local move = mainTab:CreateSection({ Title = "Movement", Opened = true })

move:CreateSlider({
    Id = "walkspeed", Title = "Walk Speed", Desc = "Kecepatan jalan karakter",
    Min = 16, Max = 300, Default = 16, Increment = 1, Suffix = "studs",
    Callback = function(v)
        Settings.WalkSpeed = v
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").WalkSpeed = v
        end
    end,
})

move:CreateSlider({
    Id = "jumppower", Title = "Jump Power",
    Min = 50, Max = 500, Default = 50, Increment = 5, Suffix = "",
    Callback = function(v)
        Settings.JumpPower = v
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").JumpPower = v
        end
    end,
})

move:CreateToggle({
    Id = "infjump", Title = "Infinite Jump", Desc = "Lompat tanpa batas",
    Default = false,
    Callback = function(state) Settings.InfJump = state end,
})

local combat = mainTab:CreateSection({ Title = "Combat", FontWeight = "Bold" })

combat:CreateToggle({
    Id = "autofarm", Title = "Auto Farm", Desc = "Nyala otomatis lagi kalau config di-load",
    Default = false,
    Callback = function(state)
        Settings.AutoFarm = state
        if state then
            Window:Notify({ Title = "Auto Farm", Content = "Aktif!", Type = "success" })
        end
    end,
})

combat:CreateButton({
    Id = "kill", Title = "Kill Aura", Icon = "combat", Color = Color3.fromRGB(210, 80, 80),
    Callback = function()
        Window:Notify({ Title = "Kill Aura", Content = "Diaktifkan sekali.", Type = "warning" })
    end,
})

combat:CreateButton({
    Id = "execute", Title = "Execute", Icon = "bolt",
    Callback = function()
        Vypers:Notify({ Title = "Executed!", Content = "Tombol ditekan.", Type = "success", Duration = 3 })
    end,
})

-- =====================================================================
--  TAB 2: PLAYER
-- =====================================================================
local playerTab = Window:CreateTab({ Title = "Player", Icon = "user" })

local targeting = playerTab:CreateSection({ Title = "Targeting" })

targeting:CreateInput({
    Id = "targetname", Title = "Target Name", Placeholder = "Ketik nama...",
    Default = "",
    Callback = function(txt) Settings.Target = txt end,
})

targeting:CreateDropdown({
    Id = "mode", Title = "Aim Mode",
    Values = { "Head", "Torso", "Nearest", "Random" }, Default = "Head",
    Callback = function(v) Settings.AimMode = v end,
})

targeting:CreateMultiDropdown({
    Id = "esptargets", Title = "ESP Targets",
    Values = { "Players", "NPCs", "Items", "Chests", "Boss" }, Default = { "Players" },
    Callback = function(list)
        print("ESP Targets:", table.concat(list, ", "))
    end,
})

targeting:CreateDropdown({
    Id = "targetplayer", Title = "Target Player",
    Values = playerNames(),
    Refresh = playerNames,
    Sidebar = true,
    RefreshInterval = 2,
    Callback = function(v) Settings.TargetPlayer = v end,
})

-- MULTI-SELECT versi sidebar (bisa pilih banyak player sekaligus)
-- ada tombol Select All / Clear di atas list, dan tetap kebuka pas milih.
targeting:CreateMultiDropdown({
    Id = "targetplayers", Title = "Target Players",
    Values = playerNames(),
    Refresh = playerNames,
    Sidebar = true,            -- sidebar sekarang support multi!
    RefreshInterval = 2,
    Default = {},              -- boleh kosong (AllowNone default true di multi)
    -- SelectAll = false,      -- set false kalau ga mau tombol Select All/Clear
    Callback = function(list)
        Settings.TargetPlayers = list
        print("Target players:", table.concat(list, ", "))
    end,
})

local visuals = playerTab:CreateSection({ Title = "Visuals" })

visuals:CreateToggle({
    Id = "esp", Title = "ESP", Default = false,
    Callback = function(state) Settings.ESP = state end,
})

visuals:CreateColorPicker({
    Id = "espcolor", Title = "ESP Color", Default = Color3.fromRGB(91, 155, 213),
    Callback = function(c) Settings.ESPColor = c end,
})

visuals:CreateKeybind({
    Id = "panickey", Title = "Panic (unload UI)", Default = Enum.KeyCode.End,
    Callback = function()
        Window:Notify({ Title = "Panic!", Content = "UI disembunyikan.", Type = "error" })
        Window:Toggle()
    end,
})

-- =====================================================================
--  TAB 3: INFO
-- =====================================================================
local infoTab = Window:CreateTab({ Title = "Info", Icon = "info" })

local about = infoTab:CreateSection({ Title = "About" })

about:CreateParagraph({
    Title = "Vypers Hub",
    Text  = "UI library dark-theme yang clean & flat. Paragraf ini otomatis wrap ke beberapa baris.",
    Buttons = {
        { Title = "Discord", Variant = "Primary",   Callback = function() Vypers:Notify({ Title = "Discord", Content = "Link disalin!", Type = "info" }) end },
        { Title = "Copy Key", Variant = "Secondary", Callback = function() Vypers:Notify({ Title = "Key", Content = "Disalin ke clipboard.", Type = "success" }) end },
        { Title = "More",     Variant = "Tertiary",  Callback = function() print("more") end },
    },
})

about:CreateLabel({ Id = "statuslbl", Title = "Status: Ready" })
about:CreateTag({ Title = "Version", Text = "v2.0",   Color = Color3.fromRGB(91, 155, 213) })
about:CreateTag({ Title = "Build",   Text = "Stable", Color = Color3.fromRGB(80, 190, 120) })
about:CreateDivider()
about:CreateSpace(6)
about:CreateCode({
    Title = "Loadstring",
    Code  = 'loadstring(game:HttpGet("' .. RAW_URL .. '"))()',
})

local fpsLabel = about:CreateLabel({ Title = "FPS: --" })
task.spawn(function()
    while fpsLabel.Instance and fpsLabel.Instance.Parent do
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        fpsLabel.Set("FPS: " .. fps)
        task.wait(0.5)
    end
end)

-- =====================================================================
--  TAB 4: OVERLAYS
-- =====================================================================
local overlayTab = Window:CreateTab({ Title = "Overlays", Icon = "bell" })

local ov = overlayTab:CreateSection({ Title = "Overlays" })

ov:CreateButton({ Title = "Notify: Info",
    Callback = function() Vypers:Notify({ Title = "Info", Content = "Ini notif info.", Type = "info", Duration = 3 }) end })
ov:CreateButton({ Title = "Notify: Success",
    Callback = function() Vypers:Notify({ Title = "Success", Content = "Berhasil!", Type = "success", Duration = 3 }) end })
ov:CreateButton({ Title = "Notify: Warning",
    Callback = function() Vypers:Notify({ Title = "Warning", Content = "Hati-hati.", Type = "warning", Duration = 3 }) end })
ov:CreateButton({ Title = "Notify: Error",
    Callback = function() Vypers:Notify({ Title = "Error", Content = "Ada yang salah.", Type = "error", Duration = 3 }) end })
ov:CreateDivider()
ov:CreateButton({ Title = "Show Popup",
    Callback = function()
        Vypers:Popup({ Title = "Popup", Content = "Kartu melayang yang bisa ditutup.", Duration = 5 })
    end })
ov:CreateButton({ Title = "Show Dialog",
    Callback = function()
        Vypers:Dialog({
            Title = "Konfirmasi",
            Content = "Yakin mau lanjut?",
            Buttons = {
                { Title = "Batal",  Callback = function() print("dibatalkan") end },
                { Title = "Lanjut", Callback = function() Vypers:Notify({ Title = "Dikonfirmasi", Type = "success" }) end },
            },
        })
    end })

-- =====================================================================
--  TAB 5: SETTINGS
-- =====================================================================
local setTab = Window:CreateTab({ Title = "Settings", Icon = "settings" })

local cfg = setTab:CreateSection({ Title = "Configuration" })

cfg:CreateButton({ Title = "Save Config",
    Callback = function()
        Vypers:SaveConfig("myconfig")
        Vypers:Notify({ Title = "Saved", Content = "Config tersimpan.", Type = "success" })
    end })
cfg:CreateButton({ Title = "Load Config",
    Callback = function()
        Vypers:LoadConfig("myconfig")
        Vypers:Notify({ Title = "Loaded", Content = "Config dimuat.", Type = "info" })
    end })
cfg:CreateToggle({ Id = "autosave", Title = "Auto Save", Default = true,
    Callback = function(s) Vypers:AutoSave(s) end })

local winSec = setTab:CreateSection({ Title = "Window", Box = false })
winSec:CreateKeybind({ Id = "togglekey", Title = "Toggle UI Key", Default = Enum.KeyCode.RightShift,
    Callback = function(key) Window:SetToggleKey(key) end })
winSec:CreateButton({ Title = "Hide / Show Window",
    Callback = function() Window:Toggle() end })

-- =====================================================================
--  AUTO-SAVE PERSISTEN (WAJIB paling akhir)
-- =====================================================================
Vypers:EnableConfig("myconfig")
Vypers:Notify({ Title = "Vypers Hub", Content = "Loaded! Tekan RightShift buat toggle.", Type = "success", Duration = 5 })
