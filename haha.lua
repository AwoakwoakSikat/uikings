--[[ ================================================================
     VYPERSLIB  —  FULL FEATURE DEMO
     Semua fitur library dipakai di sini + komentar penjelasan.
     Tujuan: gampang ngecek kalau masih ada bug.
     Ganti RAW_URL kalau file lo pindah.
     ================================================================ ]]

local RAW_URL = "https://raw.githubusercontent.com/AwoakwoakSikat/uikings/refs/heads/main/VypersLib33.lua"
local Vypers  = loadstring(game:HttpGet(RAW_URL))()

-- ================================================================
--  SETUP GLOBAL  (panggil SEBELUM CreateWindow)
-- ================================================================
Vypers:SetFolder("VypersDemo")                    -- folder tempat simpan config
Vypers:SetAccent(Color3.fromRGB(120, 90, 240))    -- warna aksen global
Vypers:SetTheme({                                 -- override warna theme apapun (opsional)
    -- Success = Color3.fromRGB(80, 200, 130),     -- contoh ganti warna "success"
    -- Text    = Color3.fromRGB(240, 240, 255),    -- contoh ganti warna teks
})

-- helper: daftar nama semua player (buat dropdown auto-refresh)
local Players = game:GetService("Players")
local function playerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do table.insert(t, p.Name) end
    return t
end

local Settings = {}   -- tempat nampung state biar gampang diliat

-- ================================================================
--  BIKIN WINDOW  (semua opsi window dipakai)
-- ================================================================
local Window = Vypers:CreateWindow({
    Title           = "King Vypers",                     -- judul di kiri atas
    Icon            = "rbxassetid://139467646163013",    -- logo pas window di-minimize
    FloatIconRadius = 14,                                -- sudut logo minimize: 0 tajam | 14 squircle | 25 bulat
    SubTitle        = "v2.0",                            -- badge kecil sebelah judul (alias: Version)
    Author          = "by Yeremia",                      -- teks author kecil
    Background      = "rbxassetid://97514324988224",     -- gambar backdrop window
    BackgroundTransparency = 0,                          -- transparansi gambar backdrop (0 = solid)
    Overlay         = 0.3,                               -- tint gelap di atas gambar (0 terang .. 1 gelap)
    Size            = UDim2.new(0, 560, 0, 360),         -- ukuran awal window
    MinSize         = Vector2.new(480, 300),             -- batas minimal resize
    MaxSize         = Vector2.new(720, 480),             -- batas maksimal resize
    SideBarWidth    = 150,                               -- lebar sidebar tab
    Resizable       = true,                              -- boleh di-resize (pojok kanan bawah)
    Transparent     = true,                              -- mode glass (nyalain transparansi default)

    -- --- transparansi tiap layer (0 = solid .. 1 = ilang total) ---
    SurfaceTransparency = 0.5,   -- card tiap element
    SectionTransparency = 0.85,  -- panel section
    TabTransparency     = 0.4,   -- tombol tab sidebar

    -- --- warna background item ---
    ItemColor    = Color3.fromRGB(40, 40, 60),   -- card element
    SectionColor = Color3.fromRGB(28, 28, 44),   -- panel section
    TabColor     = Color3.fromRGB(34, 34, 52),   -- tab sidebar
    WindowColor  = Color3.fromRGB(20, 20, 30),   -- warna dasar window
    Accent       = Color3.fromRGB(120, 90, 240), -- aksen (bisa juga lewat SetAccent)
    -- Theme      = { Surface = ..., Border = ... }, -- override penuh sekaligus

    ToggleKey   = Enum.KeyCode.RightShift,  -- tombol buat show/hide window
    Folder      = "VypersDemo",             -- folder config (sama kayak SetFolder)
})

-- ================================================================
--  TAG DI TITLE BAR  (pill kecil sebelah judul)
-- ================================================================
Window:Tag({ Title = "BETA",   Color = Color3.fromRGB(220, 180, 70) })                 -- pill teks doang
Window:Tag({ Title = "Online", Icon = "bolt", Color = Color3.fromRGB(80, 190, 120) })  -- pill + icon
-- Window:Tag({ Title = "NEW", Radius = 4 })   -- Radius atur sudut pill (default 9)

-- ================================================================
--  TAB 1: HOME  (element display: paragraph, label, code, tag, divider, space)
-- ================================================================
local home = Window:CreateTab({ Title = "Home", Icon = "home" })   -- Icon glyph: home

local welcome = home:CreateSection({ Title = "Welcome", Opened = true })  -- Opened = expand di awal

-- Paragraph: judul + teks panjang (auto-wrap), bisa + gambar + tombol aksi
local introPara = welcome:CreateParagraph({
    Id    = "intro",
    Title = "Tentang Script",
    Text  = "Ini demo SEMUA fitur VypersLib. Scroll & pindah-pindah tab buat nyoba tiap element satu-satu.",
    Image = "rbxassetid://97514324988224",   -- gambar full-width di dalam paragraph (opsional)
    ImageHeight = 110,                        -- tinggi gambar (px)
    -- Thumbnail = 97514324988224, ThumbnailHeight = 120,  -- alternatif: thumbnail asset
    Buttons = {   -- baris tombol aksi di dalam paragraph (Variant: Primary | Secondary | Tertiary)
        { Title = "Primary",   Variant = "Primary",   Icon = "bolt", Callback = function() Window:Notify({ Title = "Primary", Content = "Diklik!", Type = "success" }) end },
        { Title = "Secondary", Variant = "Secondary", Callback = function() print("secondary") end },
        { Title = "Tertiary",  Variant = "Tertiary",  Callback = function() print("tertiary") end },
    },
})

-- Label: baris teks simpel (bisa di-update lewat handle:SetTitle)
local statusLabel = welcome:CreateLabel({ Id = "status", Title = "Status: idle" })

welcome:CreateDivider()   -- garis pemisah horizontal
welcome:CreateSpace(6)    -- spasi kosong vertikal (px)

-- Code: blok monospace + tombol copy otomatis
welcome:CreateCode({ Id = "loadstr", Code = 'loadstring(game:HttpGet("' .. RAW_URL .. '"))()' })

-- Tag element (beda sama Window:Tag): teks kiri + pill berwarna kanan
welcome:CreateTag({ Id = "ver", Title = "Versi Library", Text = "v2.0", Color = Color3.fromRGB(120, 90, 240) })

-- ================================================================
--  TAB 2: COMBAT  (button variasi, toggle, slider, keybind)
-- ================================================================
local combatTab = Window:CreateTab({ Title = "Combat", Icon = "combat" })

-- FontWeight header: Thin|Light|Regular|Medium|SemiBold|Bold|Black
local btnSec = combatTab:CreateSection({ Title = "Buttons", FontWeight = "Bold" })

btnSec:CreateButton({ Id = "btnPlain", Title = "Tombol Biasa", Callback = function() print("klik biasa") end })
btnSec:CreateButton({ Id = "btnColor", Title = "Tombol Warna", Color = Color3.fromRGB(210, 80, 80), Icon = "combat",
    Callback = function() Window:Notify({ Title = "Kill Aura", Content = "Sekali tembak!", Type = "warning" }) end })
-- Justify: Center|Left|Right|Between ; IconAlign: Left|Right
btnSec:CreateButton({ Id = "btnBetween", Title = "Justify Between", Justify = "Between", IconAlign = "Right", Icon = "bolt",
    Callback = function() print("justify between") end })

local ctrlSec = combatTab:CreateSection({ Title = "Toggle / Slider / Keybind" })

-- Toggle: Default (on/off), Desc (deskripsi kecil di bawah judul)
ctrlSec:CreateToggle({ Id = "autofarm", Title = "Auto Farm", Desc = "Nyala lagi otomatis pas config di-load",
    Default = false, Callback = function(on) Settings.AutoFarm = on end })

-- Slider angka bulat: Min/Max/Increment/Suffix/Default
ctrlSec:CreateSlider({ Id = "speed", Title = "Walk Speed", Min = 16, Max = 200, Increment = 1, Suffix = "spd",
    Default = 16, Desc = "Kecepatan jalan karakter", Callback = function(v) Settings.Speed = v end })

-- Slider desimal: Increment < 1 otomatis nampilin 2 angka di belakang koma
ctrlSec:CreateSlider({ Id = "fov", Title = "Aim FOV", Min = 0, Max = 1, Increment = 0.05, Default = 0.25,
    Callback = function(v) Settings.FOV = v end })

-- Keybind: klik lalu pencet tombol buat ganti; pencet tombol itu buat trigger callback
ctrlSec:CreateKeybind({ Id = "aimkey", Title = "Aim Key", Default = Enum.KeyCode.E, Desc = "Klik lalu pencet tombol",
    Callback = function(k) print("keybind ditekan:", k.Name) end })

-- ================================================================
--  TAB 3: INPUTS  (input, semua jenis dropdown, colorpicker)
-- ================================================================
local inputTab = Window:CreateTab({ Title = "Inputs", Icon = "list" })

local fields = inputTab:CreateSection({ Title = "Text & Pilihan" })

-- Input teks: Placeholder + Default
fields:CreateInput({ Id = "target", Title = "Target Name", Placeholder = "Ketik nama...", Default = "",
    Callback = function(txt) Settings.Target = txt end })

-- Dropdown single: list overlay, nutup pas milih
fields:CreateDropdown({ Id = "mode", Title = "Aim Mode",
    Values = { "Head", "Torso", "Nearest", "Random" }, Default = "Head",
    Callback = function(v) Settings.Mode = v end })

-- Dropdown advanced: tiap value bisa punya Icon, Desc, dan ada Divider (bukan pilihan)
fields:CreateDropdown({ Id = "weapon", Title = "Weapon", AllowNone = false,   -- AllowNone=false: wajib ada 1 kepilih
    Values = {
        { Divider = true, Title = "Melee" },
        { Title = "Sword", Value = "sword", Icon = "combat", Desc = "Jarak dekat" },
        { Divider = true, Title = "Ranged" },
        { Title = "Bow",   Value = "bow",   Icon = "bolt",   Desc = "Jarak jauh" },
    },
    Default = "sword",
    Callback = function(v) Settings.Weapon = v end })

-- MultiDropdown: checkmark, tetap kebuka, nampilin "N selected" kalau > 2
fields:CreateMultiDropdown({ Id = "esp", Title = "ESP Targets",
    Values = { "Players", "NPCs", "Items", "Chests", "Boss" }, Default = { "Players" },
    Callback = function(list) Settings.ESP = list; print("ESP:", table.concat(list, ", ")) end })

local sidebarSec = inputTab:CreateSection({ Title = "Sidebar Dropdown" })

-- Dropdown SIDEBAR single: drawer geser dari kanan + search box
sidebarSec:CreateDropdown({ Id = "tp", Title = "Target Player", Sidebar = true,
    Values = playerNames(), Refresh = playerNames, RefreshInterval = 2,   -- auto-refresh tiap 2 detik
    Callback = function(v) Settings.TP = v end })

-- Dropdown SIDEBAR multi: + tombol Select All / Clear otomatis
sidebarSec:CreateMultiDropdown({ Id = "tps", Title = "Target Players", Sidebar = true, Default = {},
    Values = playerNames(), Refresh = playerNames, RefreshInterval = 2,
    -- SelectAll = false,   -- set false kalau ga mau tombol Select All/Clear
    Callback = function(list) Settings.TPS = list end })

-- ColorPicker: panel HSV (Default = Color3)
sidebarSec:CreateColorPicker({ Id = "espcolor", Title = "ESP Color", Default = Color3.fromRGB(255, 0, 120),
    Callback = function(c) Settings.ESPColor = c end })

-- ================================================================
--  TAB 4: LAYOUT  (variasi section + kontrol section programatik)
-- ================================================================
local layoutTab = Window:CreateTab({ Title = "Layout", Icon = "eye" })

local boxed = layoutTab:CreateSection({ Title = "Boxed Section", Box = true, Opened = true })   -- Box=true: ada border
boxed:CreateLabel({ Title = "Section ini ada box/border-nya" })

local flat = layoutTab:CreateSection({ Title = "Flat Section", Box = false })   -- Box=false: flat tanpa border
flat:CreateLabel({ Title = "Section ini flat (tanpa box)" })

local collapsed = layoutTab:CreateSection({ Title = "Collapsed Awal", Opened = false })  -- Opened=false: ketutup awal
collapsed:CreateLabel({ Title = "Awalnya ketutup, klik header buat buka" })

local ctrlSecLayout = layoutTab:CreateSection({ Title = "Kontrol Section" })
ctrlSecLayout:CreateButton({ Title = "Buka/Tutup 'Collapsed Awal'", Callback = function() collapsed.Toggle() end })  -- section.Toggle()
ctrlSecLayout:CreateButton({ Title = "Paksa Buka (SetOpen)", Callback = function() collapsed.SetOpen(true) end })    -- section.SetOpen(true/false)

-- ================================================================
--  TAB 5: UI / POPUP  (notify, dialog, popup, toggle window, handle method)
-- ================================================================
local uiTab = Window:CreateTab({ Title = "UI / Popup", Icon = "bell" })

local notifSec = uiTab:CreateSection({ Title = "Notifikasi & Dialog" })

-- Notify: Type = info | success | warning | error ; Duration (detik)
notifSec:CreateButton({ Title = "Notify: Info",    Callback = function() Window:Notify({ Title = "Info",    Content = "Ini notifikasi info.", Type = "info",    Duration = 3 }) end })
notifSec:CreateButton({ Title = "Notify: Success", Callback = function() Window:Notify({ Title = "Sukses",  Content = "Berhasil!",             Type = "success" }) end })
notifSec:CreateButton({ Title = "Notify: Warning", Callback = function() Window:Notify({ Title = "Warning", Content = "Hati-hati ya.",         Type = "warning" }) end })
notifSec:CreateButton({ Title = "Notify: Error",   Callback = function() Window:Notify({ Title = "Error",   Content = "Ada yang gagal!",        Type = "error" }) end })

-- Dialog (modal): tombol terakhir otomatis jadi "primary" (aksen)
notifSec:CreateButton({ Title = "Dialog (modal)", Callback = function()
    Window:Dialog({ Title = "Konfirmasi", Content = "Yakin mau lanjut?",
        Buttons = {
            { Title = "Batal",  Callback = function() print("batal") end },
            { Title = "Lanjut", Callback = function() Window:Notify({ Title = "OK", Content = "Lanjut!", Type = "success" }) end },
        } })
end })

-- Popup (non-modal): kartu ngambang, ada tombol close, bisa auto-close pakai Duration
notifSec:CreateButton({ Title = "Popup (non-modal)", Callback = function()
    Window:Popup({ Title = "Info", Content = "Popup ini nutup sendiri 4 detik.", Duration = 4 })
end })

-- Toggle window (hide/show) programatik
notifSec:CreateButton({ Title = "Hide / Show Window", Callback = function() Window:Toggle() end })

-- Demo HANDLE method tiap element: Set / Get / Lock / Unlock / SetTitle / SetDesc / Destroy
local handleSec = uiTab:CreateSection({ Title = "Handle Element" })
local demoToggle = handleSec:CreateToggle({ Id = "demo", Title = "Demo Toggle", Default = false, Callback = function() end })
handleSec:CreateButton({ Title = "Set ON (handle.Set)",       Callback = function() demoToggle.Set(true) end })
handleSec:CreateButton({ Title = "Baca nilai (handle.Get)",   Callback = function() statusLabel.SetTitle("Status: " .. tostring(demoToggle.Get())) end })
handleSec:CreateButton({ Title = "Lock 1.5 detik (Lock/Unlock)", Callback = function() demoToggle.Lock(); task.delay(1.5, function() demoToggle.Unlock() end) end })
handleSec:CreateButton({ Title = "Ganti Judul (SetTitle)",    Callback = function() demoToggle.SetTitle("Judul Baru!") end })
handleSec:CreateButton({ Title = "Ganti Desc (SetDesc)",      Callback = function() demoToggle.SetDesc("Deskripsi baru muncul di sini") end })

-- ================================================================
--  TAB 6: CONFIG  (save / load / auto-save)
-- ================================================================
local cfgTab = Window:CreateTab({ Title = "Config", Icon = "gear" })
local cfgSec = cfgTab:CreateSection({ Title = "Simpan / Muat" })

cfgSec:CreateInput({ Id = "cfgname", Title = "Nama Config", Default = "default", Placeholder = "default",
    Callback = function(v) Settings.CfgName = v end })

cfgSec:CreateButton({ Title = "Save Config", Icon = "star", Callback = function()
    local ok, err = Vypers:SaveConfig(Settings.CfgName or "default")
    Window:Notify({ Title = ok and "Saved" or "Gagal", Content = ok and "Config disimpan." or tostring(err), Type = ok and "success" or "error" })
end })

cfgSec:CreateButton({ Title = "Load Config", Callback = function()
    local ok, err = Vypers:LoadConfig(Settings.CfgName or "default")
    Window:Notify({ Title = ok and "Loaded" or "Gagal", Content = ok and "Config dimuat." or tostring(err), Type = ok and "success" or "error" })
end })

cfgSec:CreateToggle({ Id = "autosave", Title = "Auto Save", Default = false,
    Callback = function(on) Vypers:AutoSave(on) end })   -- nyalain/matiin auto-save

-- ================================================================
--  TAB 7: SETTINGS  (ubah tampilan live)
-- ================================================================
local setTab = Window:CreateTab({ Title = "Settings", Icon = "settings" })
local setSec = setTab:CreateSection({ Title = "Tampilan" })

-- ganti accent color live
setSec:CreateColorPicker({ Id = "accent", Title = "Accent Color", Default = Color3.fromRGB(120, 90, 240),
    Callback = function(c) Vypers:SetAccent(c) end })

-- ganti tombol toggle window live
setSec:CreateKeybind({ Id = "togglekey", Title = "Toggle UI Key", Default = Enum.KeyCode.RightShift,
    Callback = function(k) Window:SetToggleKey(k) end })

-- ================================================================
--  ENABLE CONFIG  (PALING AKHIR, setelah semua UI dibuat)
--  -> muat config terakhir (kalau ada) + nyalain auto-save
-- ================================================================
Vypers:EnableConfig("default")

Window:Notify({ Title = "VypersLib", Content = "Demo full-feature ke-load!", Type = "success", Duration = 4 })
