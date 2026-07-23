local Vypers = loadstring(game:HttpGet("https://raw.githubusercontent.com/AwoakwoakSikat/uikings/refs/heads/main/VypersLib13.lua"))()

local Window = Vypers:CreateWindow({ Title = "My Script", SubTitle = "v1.0" })

-- ========== TAB 1: MAIN (interactive elements) ==========
local main = Window:CreateTab({ Title = "Main", Icon = "home" })

local combat = main:CreateSection({ Title = "Combat" })
combat:CreateToggle({ Id = "autofarm", Title = "Auto Farm", Default = false,
	Callback = function(state) print("AutoFarm:", state) end })
combat:CreateSlider({ Id = "walkspeed", Title = "Walk Speed", Min = 16, Max = 200, Default = 16, Suffix = "studs",
	Callback = function(val) print("WalkSpeed:", val) end })
combat:CreateButton({ Title = "Execute",
	Callback = function() Vypers:Notify({ Title = "Executed!", Content = "Button pressed.", Type = "success" }) end })

local inputs = main:CreateSection({ Title = "Inputs" })
inputs:CreateInput({ Id = "target", Title = "Target", Placeholder = "Enter name...",
	Callback = function(txt) print("Target:", txt) end })
inputs:CreateKeybind({ Id = "togglekey", Title = "Toggle UI", Default = Enum.KeyCode.RightControl,
	Callback = function() Window:Toggle() end })

-- SINGLE dropdown (closes on pick, returns one value)
inputs:CreateDropdown({ Id = "mode", Title = "Select Mode",
	Values = { "Mode A", "Mode B", "Mode C", "Mode D", "Mode E", "Mode F", "Mode G" }, Default = "Mode A",
	Callback = function(v) print("Mode:", v) end })

-- MULTI dropdown (checkmarks, stays open, returns a table)
inputs:CreateMultiDropdown({ Id = "targets", Title = "ESP Targets",
	Values = { "Players", "NPCs", "Items", "Chests", "Boss" }, Default = { "Players" },
	Callback = function(list) print("Targets:", table.concat(list, ", ")) end })

-- AUTO-REFRESH dropdown: list updates itself when players join / leave
local Players = game:GetService("Players")
local function playerNames()
	local names = {}
	for _, p in ipairs(Players:GetPlayers()) do table.insert(names, p.Name) end
	return names
end
local targetDrop = inputs:CreateDropdown({ Id = "targetplayer", Title = "Target Player",
	Values = playerNames(),
	Refresh = playerNames,   -- polled automatically (default every 1s)
	RefreshInterval = 1,
	Callback = function(v) print("Target player:", v) end })
-- (manual alternative, if you prefer event-driven instead of polling:)
-- Players.PlayerAdded:Connect(function() targetDrop.SetValues(playerNames(), true) end)
-- Players.PlayerRemoving:Connect(function() task.defer(function() targetDrop.SetValues(playerNames(), true) end) end)

inputs:CreateColorPicker({ Id = "espcolor", Title = "ESP Color", Default = Color3.fromRGB(91, 155, 213),
	Callback = function(c) print("Color:", c) end })

-- ========== TAB 2: DISPLAY (static UI) ==========
local display = Window:CreateTab({ Title = "Display", Icon = "list" })

local info = display:CreateSection({ Title = "Information" })
info:CreateParagraph({ Title = "About",
	Text = "Vypers is a clean, flat dark-themed UI library. This paragraph wraps across multiple lines automatically." })
info:CreateLabel({ Title = "Status: Ready" })
info:CreateTag({ Title = "Version", Text = "v1.0", Color = Color3.fromRGB(91, 155, 213) })
info:CreateTag({ Title = "Server", Text = "Online", Color = Color3.fromRGB(80, 190, 120) })
info:CreateDivider()
info:CreateSpace(6)
info:CreateCode({ Title = "Snippet", Code = 'loadstring(game:HttpGet("url"))()' })

-- ========== TAB 3: POPUPS (dialog / popup / notification) ==========
local popups = Window:CreateTab({ Title = "Popups", Icon = "bell" })
local pp = popups:CreateSection({ Title = "Overlays" })
pp:CreateButton({ Title = "Show Notification",
	Callback = function() Vypers:Notify({ Title = "Hello!", Content = "This is a toast notification.", Type = "info", Duration = 3 }) end })
pp:CreateButton({ Title = "Show Popup",
	Callback = function() Vypers:Popup({ Title = "Popup", Content = "A dismissable floating card.", Duration = 5 }) end })
pp:CreateButton({ Title = "Show Dialog",
	Callback = function()
		Vypers:Dialog({ Title = "Confirm", Content = "Are you sure you want to proceed?", Buttons = {
			{ Title = "Cancel", Callback = function() print("cancelled") end },
			{ Title = "Confirm", Callback = function() Vypers:Notify({ Title = "Confirmed", Type = "success" }) end },
		} })
	end })

-- ========== TAB 4: CONFIG ==========
local cfg = Window:CreateTab({ Title = "Config", Icon = "settings" })
local cs = cfg:CreateSection({ Title = "Configuration" })
cs:CreateButton({ Title = "Save Config",
	Callback = function() Vypers:SaveConfig("default"); Vypers:Notify({ Title = "Saved", Type = "success" }) end })
cs:CreateButton({ Title = "Load Config",
	Callback = function() Vypers:LoadConfig("default"); Vypers:Notify({ Title = "Loaded", Type = "info" }) end })
cs:CreateToggle({ Title = "Auto Save", Default = false, Callback = function(s) Vypers:AutoSave(s) end })

-- ============== PERSISTENT AUTO-SAVE (the important part) ==============
-- Call this LAST, AFTER every tab / section / element has been created.
-- First run: no saved file yet, so nothing happens.
-- After the user flips e.g. "Auto Farm" ON, it is saved automatically. Next time
-- they execute the script, EnableConfig restores it AND fires the callback, so
-- Auto Farm turns back ON and actually starts by itself.
Vypers:EnableConfig("myconfig")
