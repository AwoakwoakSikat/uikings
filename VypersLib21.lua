--[[
	Vypers UI Library
	-----------------
	A clean, flat, dark-themed Roblox UI library for executor scripts.

	Architecture:
		local Vypers = loadstring(game:HttpGet("..."))()
		local Window  = Vypers:CreateWindow({ Title = "My Script", SubTitle = "v1.0" })
		local Tab     = Window:CreateTab({ Title = "Main", Icon = "home" })
		local Section = Tab:CreateSection({ Title = "Combat" })
		Section:CreateToggle({ ... })

	UI          : Window, Tab, Section, Dialog, Popup, Tag, Notification, Divider, Space
	Elements    : Button, Code, ColorPicker, Dropdown, MultiDropdown, Input,
	              Keybind, Paragraph, Label, Slider, Toggle

	See the fully-featured commented example at the bottom of this file.
]]

-- =====================================================================
--  SERVICES
-- =====================================================================
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local LocalPlayer       = Players.LocalPlayer

-- =====================================================================
--  THEME / CONSTANTS  (edit here for easy re-theming)
-- =====================================================================
local THEME = {
	Background   = Color3.fromRGB(26, 26, 26),   -- #1a1a1a  main window bg
	Surface      = Color3.fromRGB(36, 36, 36),   -- #242424  panels / elements
	SurfaceHover = Color3.fromRGB(46, 46, 46),   -- hover state (slightly lighter)
	SurfaceLight = Color3.fromRGB(54, 54, 54),   -- lighter surface (inputs / tracks)
	Border       = Color3.fromRGB(51, 51, 51),   -- #333333  subtle borders
	Accent       = Color3.fromRGB(91, 155, 213), -- #5b9bd5  accent (customizable)
	Text         = Color3.fromRGB(235, 235, 235),
	TextDim      = Color3.fromRGB(150, 150, 150),
	TextMuted    = Color3.fromRGB(110, 110, 110),
	ToggleOff    = Color3.fromRGB(60, 60, 60),
	-- semantic colors (tags / notifications)
	Success      = Color3.fromRGB(80, 190, 120),
	Warning      = Color3.fromRGB(220, 180, 70),
	Error        = Color3.fromRGB(210, 80, 80),
	Info         = Color3.fromRGB(91, 155, 213),
}

local FONT_TITLE = Enum.Font.GothamBold  -- titles
local FONT_VALUE = Enum.Font.Gotham      -- values / body
local FONT_CODE  = Enum.Font.Code        -- code blocks

local RADIUS_LARGE = 8 -- most elements
local RADIUS_SMALL = 5 -- small elements

local PADDING      = 10
local ELEMENT_H    = 36 -- default element height
local HEADER_H     = 38 -- section header height

local WINDOW_TRANSPARENCY = 0.2 -- 20% transparent window background (subtle glass)

-- =====================================================================
--  SIMPLE ICON SET (unicode glyphs -- no external image dependencies)
-- =====================================================================
local ICONS = {
	home     = "\u{2302}",  settings = "\u{2699}",  combat = "\u{2694}",
	user     = "\u{263A}",  star     = "\u{2605}",  bolt   = "\u{26A1}",
	gear     = "\u{2699}",  list     = "\u{2261}",  search = "\u{2315}",
	info     = "\u{2139}",  flag     = "\u{2691}",  heart  = "\u{2665}",
	bell     = "\u{1F514}", code     = "\u{2328}",  eye    = "\u{25C9}",
}

-- =====================================================================
--  IMAGE ICON TEMPLATE  (paste your uploaded Roblox decal IDs here)
-- ---------------------------------------------------------------------
--  1. Upload your icon to Roblox, grab its rbxassetid.
--  2. Add an entry below:  ["bird"] = "rbxassetid://1234567890",
--  3. Use it anywhere as  Icon = "bird"  (Window / Tab / etc).
--  You can also pass a raw id directly, e.g. Icon = "rbxassetid://123".
-- =====================================================================
local IMAGE_ICONS = {
	-- ["door-open"] = "rbxassetid://0000000000",
	-- ["bird"]      = "rbxassetid://0000000000",
	-- ["github"]    = "rbxassetid://0000000000",
	-- ["house"]     = "rbxassetid://0000000000",
	-- ["trash"]     = "rbxassetid://0000000000",
}

-- Turn any icon input into { image = "rbxassetid://..." } or { glyph = "?" }.
-- Priority: raw asset url > IMAGE_ICONS table > built-in glyph set > literal emoji.
local function resolveIcon(icon)
	if type(icon) ~= "string" or icon == "" then return nil end
	if icon:match("^rbxassetid://") or icon:match("^rbxthumb://") or icon:match("^http") then
		return { image = icon }
	end
	if IMAGE_ICONS[icon] then return { image = IMAGE_ICONS[icon] } end
	if ICONS[icon] then return { glyph = ICONS[icon] } end
	if #icon <= 2 then return { glyph = icon } end
	return nil
end

-- =====================================================================
--  UTILITY HELPERS
-- =====================================================================
local function create(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then inst[k] = v end
		end
		if props.Parent then inst.Parent = props.Parent end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = inst end
	end
	return inst
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or RADIUS_LARGE), Parent = parent })
end

local function stroke(parent, color, thickness)
	return create("UIStroke", {
		Color = color or THEME.Border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- lightweight hover helper (color swap only, no heavy animation)
local function addHover(inst, base, hover)
	inst.MouseEnter:Connect(function() inst.BackgroundColor3 = hover end)
	inst.MouseLeave:Connect(function() inst.BackgroundColor3 = base end)
end

local function clamp(v, min, max)
	if v < min then return min end
	if v > max then return max end
	return v
end

local function round(v, step)
	step = step or 1
	return math.floor(v / step + 0.5) * step
end

local function setClipboard(text)
	local fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if fn then pcall(fn, text) end
end

-- Executor file API detection (safe no-ops when not present)
local hasFileAPI = (typeof(writefile) == "function") and (typeof(readfile) == "function")
local function safeIsFile(path)
	if typeof(isfile) == "function" then
		local ok, res = pcall(isfile, path)
		return ok and res
	end
	return false
end
local function safeMakeFolder(path)
	if typeof(makefolder) == "function" then pcall(makefolder, path) end
end

-- only one dropdown list may be open at a time
local activeDropdownClose = nil

-- Lock overlay: covers an element and swallows input while it is locked.
local function makeLockable(inst)
	local overlay
	local function lock()
		if overlay then return end
		overlay = create("TextButton", {
			Parent = inst, BackgroundColor3 = THEME.Background, BackgroundTransparency = 0.5,
			BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 60,
			Size = UDim2.new(1, 0, 1, 0),
		})
		corner(overlay, RADIUS_SMALL)
	end
	local function unlock()
		if overlay then overlay:Destroy(); overlay = nil end
	end
	return lock, unlock
end

-- Attach the shared element methods every element gets:
--   :SetTitle(text)  :SetDesc(text)  :Lock()  :Unlock()  :Destroy()
local function attachCommon(handle, inst, titleLabel, descLabel)
	local lock, unlock = makeLockable(inst)
	handle.Lock    = function() lock();   return handle end
	handle.Unlock  = function() unlock(); return handle end
	handle.Destroy = function() if inst then inst:Destroy() end end
	if titleLabel then
		handle.SetTitle = function(t) titleLabel.Text = tostring(t); return handle end
	end
	handle.SetDesc = function(t) if descLabel then descLabel.Text = tostring(t) end; return handle end
	return handle
end

-- =====================================================================
--  ROOT SCREENGUI
-- =====================================================================
local function mountGui()
	local parentGui = (gethui and gethui()) or CoreGui
	local existing = parentGui:FindFirstChild("VypersUI")
	if existing then existing:Destroy() end

	local gui = create("ScreenGui", {
		Name = "VypersUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
	})

	local ok = false
	if typeof(gethui) == "function" then
		ok = pcall(function() gui.Parent = gethui() end)
	end
	if not ok and syn and syn.protect_gui then
		pcall(function() syn.protect_gui(gui); gui.Parent = CoreGui end)
		ok = true
	end
	if not ok then
		pcall(function() gui.Parent = CoreGui end)
		if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	end
	return gui
end

-- =====================================================================
--  VYPERS OBJECT
-- =====================================================================
local Vypers = {}
Vypers.__index = Vypers

Vypers._elements = {}       -- [Id] = elementHandle
Vypers._autoSave  = false
Vypers._configName = nil
Vypers._folder    = "Vypers"
Vypers._gui       = nil
Vypers._theme     = THEME

local function registerElement(id, handle)
	if id then Vypers._elements[id] = handle end
end

local function autoSaveTrigger()
	if Vypers._autoSave and Vypers._configName then
		Vypers:SaveConfig(Vypers._configName)
	end
end

function Vypers:_ensureGui()
	if not self._gui or not self._gui.Parent then
		self._gui = mountGui()
	end
	return self._gui
end

-- =====================================================================
--  CONFIG SYSTEM
-- =====================================================================
function Vypers:_configPath(name)
	return self._folder .. "/" .. tostring(name) .. ".json"
end

function Vypers:SaveConfig(name)
	name = name or self._configName
	if not name then return false, "no config name" end
	self._configName = name

	local data = {}
	for id, el in pairs(self._elements) do
		if el.Get then
			local ok, val = pcall(el.Get)
			if ok then data[id] = val end
		end
	end

	local json = HttpService:JSONEncode(data)
	if hasFileAPI then
		safeMakeFolder(self._folder)
		local ok, err = pcall(writefile, self:_configPath(name), json)
		if not ok then return false, err end
		return true
	else
		self._memoryConfig = self._memoryConfig or {}
		self._memoryConfig[name] = json
		return true, "stored in memory (no executor file API)"
	end
end

function Vypers:LoadConfig(name)
	name = name or self._configName
	if not name then return false, "no config name" end
	self._configName = name

	local json
	if hasFileAPI and safeIsFile(self:_configPath(name)) then
		local ok, res = pcall(readfile, self:_configPath(name))
		if ok then json = res end
	elseif self._memoryConfig and self._memoryConfig[name] then
		json = self._memoryConfig[name]
	end
	if not json then return false, "config not found" end

	local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
	if not ok then return false, "invalid config json" end

	for id, val in pairs(data) do
		local el = self._elements[id]
		if el and el.Set then
			pcall(el.Set, val)
			-- re-fire the element's callback so restored state actually takes effect
			-- (e.g. an Auto Farm toggle => the farm loop starts again). Keybinds are
			-- intentionally excluded so we never trigger their bound action on load.
			if el.Callback then
				local arg = val
				if el.Get then
					local okg, g = pcall(el.Get)
					if okg then arg = g end
				end
				pcall(el.Callback, arg)
			end
		end
	end
	return true
end

function Vypers:AutoSave(state, name)
	self._autoSave = state and true or false
	if name then self._configName = name end
	return self._autoSave
end

-- convenience: restore the last saved config (applies values AND fires callbacks,
-- so e.g. a saved "Auto Farm" toggle turns back ON and actually runs), then turn
-- on auto-save. Call this LAST, after the whole UI has been built.
function Vypers:EnableConfig(name)
	name = name or "default"
	self._configName = name
	local ok = self:LoadConfig(name)   -- ignores "not found" on the very first run
	self:AutoSave(true)
	return ok
end

function Vypers:SetFolder(folder) self._folder = folder or "Vypers" end
function Vypers:SetAccent(color3) self._theme.Accent = color3 end

-- =====================================================================
--  NOTIFICATIONS (toast, bottom-right)
-- =====================================================================
function Vypers:_noteHolder()
	if self._notes and self._notes.Parent then return self._notes end
	local gui = self:_ensureGui()
	local holder = create("Frame", {
		Name = "Notifications",
		Parent = gui,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(290, 500),
		ZIndex = 500,
	})
	create("UIListLayout", {
		Parent = holder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	self._notes = holder
	return holder
end

-- Vypers:Notify({ Title, Content, Duration = 3, Type = "info"|"success"|"warning"|"error" })
function Vypers:Notify(opts)
	opts = opts or {}
	local theme = self._theme
	local holder = self:_noteHolder()
	local typeColor = ({
		info = theme.Info, success = theme.Success,
		warning = theme.Warning, error = theme.Error,
	})[opts.Type or "info"] or theme.Info

	local card = create("Frame", {
		Parent = holder,
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 501,
	})
	corner(card, RADIUS_LARGE)
	stroke(card, theme.Border, 1)
	create("Frame", { -- accent stripe (overlay; kept OUT of the layout flow)
		Parent = card, BackgroundColor3 = typeColor, BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0), ZIndex = 503,
	})
	-- text lives in its own body frame so the scale-height stripe never feeds
	-- back into the card's AutomaticSize (that feedback loop made the toast huge)
	local body = create("Frame", {
		Parent = card, BackgroundTransparency = 1, ZIndex = 502,
		Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -22, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	create("UIPadding", {
		Parent = body,
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
	})
	create("UIListLayout", { Parent = body, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
	create("TextLabel", {
		Parent = body, BackgroundTransparency = 1, Font = FONT_TITLE,
		Text = opts.Title or "Notification", TextColor3 = theme.Text, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 1, ZIndex = 502,
	})
	if opts.Content then
		create("TextLabel", {
			Parent = body, BackgroundTransparency = 1, Font = FONT_VALUE,
			Text = opts.Content, TextColor3 = theme.TextDim, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2, ZIndex = 502,
		})
	end

	local duration = opts.Duration or 3
	task.delay(duration, function()
		if card and card.Parent then card:Destroy() end
	end)
	return card
end

-- =====================================================================
--  DIALOG (modal) and POPUP (non-modal card)
-- =====================================================================
-- Vypers:Dialog({ Title, Content, Buttons = { { Title = "OK", Callback = fn }, ... } })
function Vypers:Dialog(opts)
	opts = opts or {}
	local theme = self._theme
	local gui = self:_ensureGui()

	local dim = create("TextButton", {
		Name = "DialogDim", Parent = gui, AutoButtonColor = false, Text = "",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 600, Modal = true,
	})
	local box = create("Frame", {
		Parent = dim, BackgroundColor3 = theme.Background, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 601,
	})
	corner(box, RADIUS_LARGE)
	stroke(box, theme.Border, 1)
	create("UIPadding", {
		Parent = box, PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
	})
	create("UIListLayout", { Parent = box, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	create("TextLabel", {
		Parent = box, BackgroundTransparency = 1, Font = FONT_TITLE,
		Text = opts.Title or "Dialog", TextColor3 = theme.Text, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 1, ZIndex = 602,
	})
	if opts.Content then
		create("TextLabel", {
			Parent = box, BackgroundTransparency = 1, Font = FONT_VALUE,
			Text = opts.Content, TextColor3 = theme.TextDim, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2, ZIndex = 602,
		})
	end

	local function close() if dim and dim.Parent then dim:Destroy() end end

	local btnRow = create("Frame", {
		Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 3, ZIndex = 602,
	})
	create("UIListLayout", {
		Parent = btnRow, FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local buttons = opts.Buttons or { { Title = "OK" } }
	for i, b in ipairs(buttons) do
		local isPrimary = (i == #buttons)
		local btn = create("TextButton", {
			Parent = btnRow, AutoButtonColor = false, Font = FONT_TITLE,
			Text = b.Title or "OK", TextColor3 = isPrimary and Color3.fromRGB(255,255,255) or theme.Text,
			TextSize = 13, BorderSizePixel = 0,
			BackgroundColor3 = isPrimary and theme.Accent or theme.SurfaceLight,
			Size = UDim2.fromOffset(96, 30), LayoutOrder = i, ZIndex = 603,
		})
		corner(btn, RADIUS_SMALL)
		btn.MouseButton1Click:Connect(function()
			close()
			if b.Callback then pcall(b.Callback) end
		end)
	end

	return { Close = close, Instance = dim }
end

-- Vypers:Popup({ Title, Content, Duration }) -- non-modal floating card, closable
function Vypers:Popup(opts)
	opts = opts or {}
	local theme = self._theme
	local gui = self:_ensureGui()

	local card = create("Frame", {
		Name = "Popup", Parent = gui, BackgroundColor3 = theme.Surface, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 20),
		Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 550,
	})
	corner(card, RADIUS_LARGE)
	stroke(card, theme.Border, 1)
	create("UIPadding", {
		Parent = card, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
	})
	create("UIListLayout", { Parent = card, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

	local header = create("Frame", {
		Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, ZIndex = 551,
	})
	create("TextLabel", {
		Parent = header, BackgroundTransparency = 1, Font = FONT_TITLE,
		Text = opts.Title or "Popup", TextColor3 = theme.Text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -20, 1, 0), ZIndex = 551,
	})
	local function close() if card and card.Parent then card:Destroy() end end
	local closeBtn = create("TextButton", {
		Parent = header, AutoButtonColor = false, BackgroundTransparency = 1,
		Font = FONT_TITLE, Text = "\u{2715}", TextColor3 = theme.TextDim, TextSize = 14,
		Position = UDim2.new(1, -16, 0, 0), Size = UDim2.fromOffset(16, 18), ZIndex = 551,
	})
	closeBtn.MouseButton1Click:Connect(close)

	if opts.Content then
		create("TextLabel", {
			Parent = card, BackgroundTransparency = 1, Font = FONT_VALUE,
			Text = opts.Content, TextColor3 = theme.TextDim, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2, ZIndex = 551,
		})
	end
	if opts.Duration then
		task.delay(opts.Duration, close)
	end
	return { Close = close, Instance = card }
end

-- =====================================================================
--  WINDOW
-- =====================================================================
local Window = {}
Window.__index = Window

function Vypers:CreateWindow(opts)
	opts = opts or {}
	local title    = opts.Title or "Vypers"
	-- version badge accepts SubTitle or Version; Author shows as a muted line
	local subtitle = opts.SubTitle or opts.Version or ""
	local author   = opts.Author or ""

	-- Size accepts a Vector2 or a UDim2 (offset). MinSize / MaxSize are Vector2.
	local function toXY(v, dx, dy)
		if typeof(v) == "Vector2" then return v.X, v.Y
		elseif typeof(v) == "UDim2" then return v.X.Offset, v.Y.Offset end
		return dx, dy
	end
	local sizeX, sizeY = toXY(opts.Size, 560, 420)
	local minSize = opts.MinSize or Vector2.new(400, 300)
	local maxSize = opts.MaxSize or Vector2.new(4096, 4096)

	-- Transparent = false => fully opaque window; true (default) keeps the glass look
	local winT = (opts.Transparent == false) and 0 or WINDOW_TRANSPARENCY

	if opts.Folder then self._folder = opts.Folder end

	local gui = self:_ensureGui()

	-- ---- main window frame -------------------------------------------
	local main = create("Frame", {
		Name = "Window", Parent = gui,
		BackgroundColor3 = self._theme.Background,
		BackgroundTransparency = winT,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(sizeX, sizeY),
		Position = UDim2.new(0.5, -sizeX/2, 0.5, -sizeY/2),
		ClipsDescendants = true, Active = true,
	})
	corner(main, RADIUS_LARGE)
	stroke(main, self._theme.Border, 1)

	-- ---- title bar ---------------------------------------------------
	local titleBar = create("Frame", {
		Name = "TitleBar", Parent = main, BackgroundColor3 = self._theme.Surface,
		BackgroundTransparency = winT, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 40),
	})
	corner(titleBar, RADIUS_LARGE)
	create("Frame", { -- mask bottom corners
		Parent = titleBar, BackgroundColor3 = self._theme.Surface, BackgroundTransparency = winT,
		BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, RADIUS_LARGE), Position = UDim2.new(0, 0, 1, -RADIUS_LARGE),
	})
	-- title + version sit together on the left, like a page title
	local titleHolder = create("Frame", {
		Parent = titleBar, BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -114, 1, 0),
	})
	create("UIListLayout", {
		Parent = titleHolder, FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	create("TextLabel", {
		Parent = titleHolder, BackgroundTransparency = 1, Font = FONT_TITLE, Text = title,
		TextColor3 = self._theme.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 1,
	})
	if subtitle ~= "" then
		-- version rendered as a rounded badge/pill next to the title
		local verBadge = create("TextLabel", {
			Parent = titleHolder, BackgroundColor3 = self._theme.Accent, BorderSizePixel = 0,
			Font = FONT_TITLE, Text = subtitle, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 18), LayoutOrder = 2,
		})
		corner(verBadge, 9)
		create("UIPadding", { Parent = verBadge, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
	end
	if author ~= "" then
		create("TextLabel", {
			Parent = titleHolder, BackgroundTransparency = 1, Font = FONT_VALUE, Text = author,
			TextColor3 = self._theme.TextMuted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center, AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 3,
		})
	end

	local function makeCtrlButton(char, xOffset, hoverColor)
		local b = create("TextButton", {
			Parent = titleBar, BackgroundColor3 = self._theme.SurfaceLight, BorderSizePixel = 0,
			Text = char, Font = FONT_TITLE, TextColor3 = self._theme.Text, TextSize = 16,
			AutoButtonColor = false, Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, xOffset, 0.5, -12),
		})
		corner(b, RADIUS_SMALL)
		addHover(b, self._theme.SurfaceLight, hoverColor or self._theme.SurfaceHover)
		return b
	end
	local closeBtn = makeCtrlButton("\u{2715}", -30, Color3.fromRGB(200, 60, 60))
	local minBtn   = makeCtrlButton("\u{2013}", -60, self._theme.SurfaceHover)

	-- ---- sidebar (vertical, scrollable) — holds the tabs -------------
	local SIDEBAR_W = opts.SideBarWidth or 150
	local sidebar = create("ScrollingFrame", {
		Name = "Sidebar", Parent = main, BackgroundColor3 = self._theme.Surface, BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(0, SIDEBAR_W, 1, -40),
		ScrollBarThickness = 3, ScrollBarImageColor3 = self._theme.Border,
		ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})
	create("UIListLayout", { Parent = sidebar, FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
	create("UIPadding", { Parent = sidebar, PaddingTop = UDim.new(0, PADDING), PaddingBottom = UDim.new(0, PADDING),
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })

	create("Frame", { -- vertical separator
		Parent = main, BackgroundColor3 = self._theme.Border, BorderSizePixel = 0,
		Position = UDim2.new(0, SIDEBAR_W, 0, 40), Size = UDim2.new(0, 1, 1, -40),
	})

	-- ---- content holder ----------------------------------------------
	local content = create("Frame", {
		Name = "Content", Parent = main, BackgroundTransparency = 1,
		Position = UDim2.new(0, SIDEBAR_W + 1, 0, 40), Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, -40),
	})

	create("Frame", { -- horizontal separator under the title bar (crisp divider so
		-- the body never looks like it merges/overlaps with the title bar)
		Parent = main, BackgroundColor3 = self._theme.Border, BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 1), ZIndex = 3,
	})

	-- ---- resize handle -----------------------------------------------
	local resizeHandle = create("TextButton", {
		Name = "Resize", Parent = main, BackgroundTransparency = 1, Text = "\u{25E2}",
		Font = FONT_TITLE, TextColor3 = self._theme.TextMuted, TextSize = 14, AutoButtonColor = false,
		Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -18, 1, -18), ZIndex = 5,
		Visible = (opts.Resizable ~= false),
	})

	local self_win = setmetatable({}, Window)
	self_win._vypers  = self
	self_win._gui     = gui
	self_win._main    = main
	self_win._content = content
	self_win._sidebar = sidebar
	self_win._tabs    = {}
	self_win._activeTab = nil
	self_win._minSize = minSize
	self_win._titleHolder = titleHolder
	self_win._tagOrder = 10

	-- DRAG --------------------------------------------------------------
	do
		local dragging, dragStart, startPos
		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; dragStart = input.Position; startPos = main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
	end

	-- RESIZE ------------------------------------------------------------
	do
		local resizing, resizeStart, startSize
		resizeHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true; resizeStart = input.Position; startSize = main.AbsoluteSize
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then resizing = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - resizeStart
				main.Size = UDim2.fromOffset(clamp(startSize.X + delta.X, minSize.X, maxSize.X), clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y))
			end
		end)
	end

	-- MINIMIZE -> floating circle --------------------------------------
	local floatIcon = create("TextButton", {
		Name = "FloatIcon", Parent = gui, BackgroundColor3 = self._theme.Surface, BorderSizePixel = 0,
		Text = string.sub(title, 1, 1):upper(), Font = FONT_TITLE, TextColor3 = self._theme.Accent, TextSize = 20,
		AutoButtonColor = false, Size = UDim2.fromOffset(50, 50), Position = UDim2.new(0, 20, 1, -70),
		Visible = false, Active = true, ZIndex = 400,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = floatIcon })
	stroke(floatIcon, self._theme.Accent, 1)
	addHover(floatIcon, self._theme.Surface, self._theme.SurfaceHover)
	do
		local fDragging, fStart, fPos, moved
		floatIcon.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				fDragging = true; moved = false; fStart = input.Position; fPos = floatIcon.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						fDragging = false
						if not moved then main.Visible = true; floatIcon.Visible = false end
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if fDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - fStart
				if delta.Magnitude > 4 then moved = true end
				floatIcon.Position = UDim2.new(fPos.X.Scale, fPos.X.Offset + delta.X, fPos.Y.Scale, fPos.Y.Offset + delta.Y)
			end
		end)
	end

	minBtn.MouseButton1Click:Connect(function()
		main.Visible = false; floatIcon.Visible = true
		if activeDropdownClose then activeDropdownClose() end
	end)
	closeBtn.MouseButton1Click:Connect(function()
		if activeDropdownClose then activeDropdownClose() end
		gui:Destroy()
	end)

	self_win._floatIcon = floatIcon
	self_win._toggleKey = opts.ToggleKey

	-- ToggleKey: press the key to show/hide the window (Window:SetToggleKey to change)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if self_win._toggleKey and input.KeyCode == self_win._toggleKey then
			self_win:Toggle()
		end
	end)

	return self_win
end

function Window:Toggle()
	self._main.Visible = not self._main.Visible
	self._floatIcon.Visible = not self._main.Visible
	if activeDropdownClose then activeDropdownClose() end
end

function Window:SetToggleKey(key)
	if typeof(key) == "EnumItem" then self._toggleKey = key
	elseif type(key) == "string" and Enum.KeyCode[key] then self._toggleKey = Enum.KeyCode[key] end
	return self._toggleKey
end

-- convenience passthroughs
function Window:Notify(o) return self._vypers:Notify(o) end
function Window:Dialog(o) return self._vypers:Dialog(o) end
function Window:Popup(o) return self._vypers:Popup(o) end

-- Window:Tag -> a small colored pill in the title bar, next to the title/version.
-- opts = { Title, Icon, Color = Color3, Radius = 0..13 }
function Window:Tag(opts)
	opts = opts or {}
	local theme = self._vypers._theme
	local holder = self._titleHolder
	if not holder then return nil end
	self._tagOrder = (self._tagOrder or 10) + 1

	local color = opts.Color or theme.Accent
	-- readable text color based on pill luminance
	local lum = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	local textColor = (lum > 0.6) and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)

	local ri = resolveIcon(opts.Icon)
	local prefix = (ri and ri.glyph) and (ri.glyph .. " ") or ""

	local pill = create("TextLabel", {
		Parent = holder, BackgroundColor3 = color, BorderSizePixel = 0, Font = FONT_TITLE,
		Text = prefix .. (opts.Title or "Tag"), TextColor3 = textColor, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 18), LayoutOrder = self._tagOrder,
	})
	local rad = opts.Radius
	if rad == nil then rad = 9 end
	corner(pill, rad)
	create("UIPadding", { Parent = pill, PaddingLeft = UDim.new(0, ri and ri.image and 20 or 8), PaddingRight = UDim.new(0, 8) })
	if ri and ri.image then
		create("ImageLabel", {
			Parent = pill, BackgroundTransparency = 1, Image = ri.image, AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(12, 12), ZIndex = 2,
		})
	end

	return {
		Type = "Tag", Instance = pill,
		SetTitle = function(t) pill.Text = prefix .. tostring(t) end,
		SetColor = function(c) pill.BackgroundColor3 = c end,
		Destroy = function() pill:Destroy() end,
	}
end

-- =====================================================================
--  TAB
-- =====================================================================
local Tab = {}
Tab.__index = Tab

function Window:CreateTab(opts)
	opts = opts or {}
	local title = opts.Title or "Tab"
	local icon  = opts.Icon
	local theme = self._vypers._theme

	local resolved = resolveIcon(icon)
	local textPrefix = ""
	if resolved and resolved.glyph then textPrefix = resolved.glyph .. "  " end

	local btn = create("TextButton", {
		Name = "Tab_" .. title, Parent = self._sidebar, BackgroundColor3 = theme.SurfaceHover,
		BackgroundTransparency = 0, BorderSizePixel = 0,
		Text = textPrefix .. title, Font = FONT_TITLE, TextColor3 = theme.TextDim, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 34),
	})
	corner(btn, RADIUS_SMALL)
	local tabLeftPad = (resolved and resolved.image) and 34 or 12
	create("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0, tabLeftPad), PaddingRight = UDim.new(0, 10) })
	if resolved and resolved.image then
		create("ImageLabel", {
			Parent = btn, BackgroundTransparency = 1, Image = resolved.image,
			Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, -tabLeftPad + 10, 0.5, -8),
		})
	end

	local page = create("ScrollingFrame", {
		Name = "Page_" .. title, Parent = self._content, BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 4, ScrollBarImageColor3 = theme.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
	})
	create("UIListLayout", { Parent = page, FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, PADDING), SortOrder = Enum.SortOrder.LayoutOrder })
	create("UIPadding", { Parent = page, PaddingTop = UDim.new(0, PADDING), PaddingBottom = UDim.new(0, PADDING),
		PaddingLeft = UDim.new(0, PADDING + 2), PaddingRight = UDim.new(0, PADDING + 2) })

	local self_tab = setmetatable({}, Tab)
	self_tab._window = self
	self_tab._vypers = self._vypers
	self_tab._btn = btn
	self_tab._page = page
	self_tab._theme = theme

	local function activate()
		if activeDropdownClose then activeDropdownClose() end
		for _, t in ipairs(self._tabs) do
			t._page.Visible = false
			t._btn.BackgroundColor3 = theme.SurfaceHover
			t._btn.BackgroundTransparency = 0
			t._btn.TextColor3 = theme.TextDim
		end
		page.Visible = true
		btn.BackgroundColor3 = theme.Accent
		btn.BackgroundTransparency = 0
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		self._activeTab = self_tab
	end
	self_tab.Activate = activate

	btn.MouseButton1Click:Connect(activate)
	btn.MouseEnter:Connect(function()
		if self._activeTab ~= self_tab then
			btn.BackgroundColor3 = theme.SurfaceLight
			btn.BackgroundTransparency = 0
		end
	end)
	btn.MouseLeave:Connect(function()
		if self._activeTab ~= self_tab then
			btn.BackgroundColor3 = theme.SurfaceHover
			btn.BackgroundTransparency = 0
		end
	end)

	table.insert(self._tabs, self_tab)
	if #self._tabs == 1 then activate() end
	return self_tab
end

-- =====================================================================
--  SECTION (collapsible)
-- =====================================================================
local Section = {}
Section.__index = Section

function Tab:CreateSection(opts)
	opts = opts or {}
	local title = opts.Title or "Section"
	local theme = self._theme

	-- Section options:
	--   Box        = true|false  -> boxed surface + border (default true); false = flat/transparent group
	--   Opened     = true|false  -> initial expanded state (default true)
	--   FontWeight = "Thin"|"Light"|"Regular"|"Medium"|"SemiBold"|"Bold"|"Black" -> header title font
	local boxed = opts.Box ~= false
	local startOpen = opts.Opened ~= false
	local function weightFont(w)
		if typeof(w) == "EnumItem" then return w end
		local map = {
			Thin = Enum.Font.Gotham, Light = Enum.Font.Gotham, Regular = Enum.Font.Gotham,
			Medium = Enum.Font.GothamMedium, SemiBold = Enum.Font.GothamBold,
			Bold = Enum.Font.GothamBold, Black = Enum.Font.GothamBlack, Heavy = Enum.Font.GothamBlack,
		}
		return map[tostring(w)] or FONT_TITLE
	end
	local headerFont = opts.FontWeight and weightFont(opts.FontWeight) or FONT_TITLE

	local container = create("Frame", {
		Name = "Section_" .. title, Parent = self._page,
		BackgroundColor3 = theme.Surface, BackgroundTransparency = boxed and 0 or 1, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, HEADER_H), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
	})
	corner(container, RADIUS_LARGE)
	if boxed then stroke(container, theme.Border, 1) end
	create("UIListLayout", { Parent = container, FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder })

	local header = create("TextButton", {
		Name = "Header", Parent = container, BackgroundColor3 = theme.Surface, BackgroundTransparency = 1,
		BorderSizePixel = 0, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, HEADER_H), LayoutOrder = 0,
	})
	local arrow = create("TextLabel", {
		Parent = header, BackgroundTransparency = 1, Font = FONT_TITLE, Text = startOpen and "\u{25BC}" or "\u{25B6}",
		TextColor3 = theme.Accent, TextSize = 10, Size = UDim2.fromOffset(20, HEADER_H), Position = UDim2.new(1, -26, 0, 0),
	})
	create("TextLabel", {
		Parent = header, BackgroundTransparency = 1, Font = headerFont, Text = title,
		TextColor3 = theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, boxed and 14 or 4, 0, 0), Size = UDim2.new(1, -44, 1, 0),
	})

	local body = create("Frame", {
		Name = "Body", Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Visible = startOpen,
	})
	create("UIListLayout", { Parent = body, FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	create("UIPadding", { Parent = body, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, boxed and 12 or 4),
		PaddingLeft = UDim.new(0, boxed and 12 or 0), PaddingRight = UDim.new(0, boxed and 12 or 0) })

	local open = startOpen
	header.MouseButton1Click:Connect(function()
		open = not open
		body.Visible = open
		arrow.Text = open and "\u{25BC}" or "\u{25B6}"
		if activeDropdownClose then activeDropdownClose() end
	end)

	local self_sec = setmetatable({}, Section)
	self_sec._vypers = self._vypers
	self_sec._window = self._window
	self_sec._body = body
	self_sec._theme = theme
	self_sec._order = 0
	-- section-level controls: expand / collapse programmatically
	self_sec.SetOpen = function(v)
		open = (v ~= false)
		body.Visible = open
		arrow.Text = open and "\u{25BC}" or "\u{25B6}"
	end
	self_sec.Toggle = function() self_sec.SetOpen(not open) end
	return self_sec
end

function Section:_next() self._order = self._order + 1; return self._order end

function Section:_row(height)
	local row = create("Frame", {
		Parent = self._body, BackgroundColor3 = self._theme.SurfaceLight, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height or ELEMENT_H), LayoutOrder = self:_next(),
	})
	corner(row, RADIUS_LARGE)
	return row
end

-- Optional subtitle/description shown under a row title. It grows the row height,
-- moves a vertically-centered title to the top, then adds a small muted label
-- underneath. Returns the desc label (or nil when no desc text was provided) so
-- the caller can hand it to attachCommon for a working handle.SetDesc().
local function applyDesc(row, titleLbl, descText, theme)
	if not descText or descText == "" then return nil end
	local sz = row.Size
	row.Size = UDim2.new(sz.X.Scale, sz.X.Offset, sz.Y.Scale, sz.Y.Offset + 14)
	local tx = titleLbl.Position.X
	local titleH = titleLbl.Size.Y.Offset
	if titleLbl.Size.Y.Scale == 1 then
		-- vertically-centered title -> pin it to the top so the desc fits below
		titleLbl.TextYAlignment = Enum.TextYAlignment.Top
		titleLbl.Position = UDim2.new(tx.Scale, tx.Offset, 0, 6)
		titleLbl.Size = UDim2.new(titleLbl.Size.X.Scale, titleLbl.Size.X.Offset, 0, 15)
		titleH = 15
	end
	local descY = titleLbl.Position.Y.Offset + titleH
	return create("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_VALUE, Text = descText,
		TextColor3 = theme.TextMuted, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.new(tx.Scale, tx.Offset, 0, descY),
		Size = UDim2.new(titleLbl.Size.X.Scale, titleLbl.Size.X.Offset, 0, 14),
	})
end

-- =====================================================================
--  ELEMENT: LABEL
-- =====================================================================
function Section:CreateLabel(opts)
	opts = opts or {}
	local row = create("TextLabel", {
		Parent = self._body, BackgroundColor3 = self._theme.SurfaceLight, BorderSizePixel = 0,
		Font = FONT_VALUE, Text = "  " .. (opts.Title or ""), TextColor3 = self._theme.TextDim, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = self:_next(),
	})
	corner(row, RADIUS_SMALL)
	local handle = {
		Type = "Label", Id = opts.Id, Instance = row,
		Set = function(v) row.Text = "  " .. tostring(v) end,
		Get = function() return (row.Text:gsub("^%s+", "")) end,
		SetText = function(v) row.Text = "  " .. tostring(v) end,
	}
	attachCommon(handle, row)
	handle.SetTitle = function(t) row.Text = "  " .. tostring(t); return handle end
	registerElement(opts.Id, handle)
	return handle
end

-- =====================================================================
--  ELEMENT: PARAGRAPH (title + wrapped body)
-- =====================================================================
function Section:CreateParagraph(opts)
	opts = opts or {}
	local theme = self._theme
	local function toAsset(v)
		if type(v) == "number" then return "rbxassetid://" .. v end
		return tostring(v)
	end
	local box = create("Frame", {
		Parent = self._body, BackgroundColor3 = theme.SurfaceLight, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self:_next(),
	})
	corner(box, RADIUS_LARGE)
	create("UIPadding", { Parent = box, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
	create("UIListLayout", { Parent = box, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
	local titleLbl
	if opts.Title then
		titleLbl = create("TextLabel", {
			Parent = box, BackgroundTransparency = 1, Font = FONT_TITLE, Text = opts.Title,
			TextColor3 = theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1,
		})
	end
	local bodyLbl = create("TextLabel", {
		Parent = box, BackgroundTransparency = 1, Font = FONT_VALUE, Text = opts.Text or opts.Content or "",
		TextColor3 = theme.TextDim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
	})

	-- optional inline image (full width). opts.Image = assetid|url, opts.ImageHeight optional.
	local imageObj
	if opts.Image then
		imageObj = create("ImageLabel", {
			Parent = box, BackgroundColor3 = theme.Background, BorderSizePixel = 0, Image = toAsset(opts.Image),
			ScaleType = Enum.ScaleType.Fit, Size = UDim2.new(1, 0, 0, opts.ImageHeight or 140), LayoutOrder = 3,
		})
		corner(imageObj, RADIUS_SMALL)
	end

	-- optional thumbnail. opts.Thumbnail = assetid (number/string) or a full rbxthumb/rbxassetid/http url.
	local thumbObj
	if opts.Thumbnail then
		local t = opts.Thumbnail
		local src
		if type(t) == "string" and (string.sub(t, 1, 9) == "rbxthumb:" or string.sub(t, 1, 3) == "rbx" or string.sub(t, 1, 4) == "http") then
			src = t
		else
			local id = (tostring(t):gsub("%D", ""))
			src = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
		end
		thumbObj = create("ImageLabel", {
			Parent = box, BackgroundColor3 = theme.Background, BorderSizePixel = 0, Image = src,
			ScaleType = Enum.ScaleType.Fit, Size = UDim2.new(1, 0, 0, opts.ThumbnailHeight or 150), LayoutOrder = 4,
		})
		corner(thumbObj, RADIUS_SMALL)
	end

	-- optional action buttons row. opts.Buttons = { { Title, Callback, Variant, Icon } }
	-- Variant: "Primary" (accent) | "Secondary" (outlined, default) | "Tertiary" (ghost)
	if type(opts.Buttons) == "table" and #opts.Buttons > 0 then
		local btnRow = create("Frame", {
			Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 5,
		})
		create("UIListLayout", {
			Parent = btnRow, FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		})
		for i, b in ipairs(opts.Buttons) do
			local variant = b.Variant or "Secondary"
			local bg, fg, painted = theme.SurfaceHover, theme.Text, true
			if variant == "Primary" then
				bg, fg = theme.Accent, Color3.fromRGB(255, 255, 255)
			elseif variant == "Tertiary" then
				painted = false; fg = theme.TextDim
			end
			local ri = resolveIcon(b.Icon)
			local prefix = (ri and ri.glyph) and (ri.glyph .. "  ") or ""
			local btn = create("TextButton", {
				Parent = btnRow, AutoButtonColor = false, Font = FONT_TITLE, Text = prefix .. (b.Title or "OK"),
				TextColor3 = fg, TextSize = 12, BorderSizePixel = 0,
				BackgroundColor3 = painted and bg or theme.SurfaceLight, BackgroundTransparency = painted and 0 or 1,
				AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 28), LayoutOrder = i,
			})
			corner(btn, RADIUS_SMALL)
			if variant == "Secondary" then stroke(btn, theme.Border, 1) end
			create("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) })
			if ri and ri.image then
				create("ImageLabel", {
					Parent = btn, BackgroundTransparency = 1, Image = ri.image, AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(14, 14),
				})
			end
			btn.MouseButton1Click:Connect(function() if b.Callback then pcall(b.Callback) end end)
		end
	end

	local handle = {
		Type = "Paragraph", Id = opts.Id, Instance = box,
		Set = function(v) bodyLbl.Text = tostring(v) end,
		SetText = function(v) bodyLbl.Text = tostring(v) end,
		SetImage = function(v) if imageObj then imageObj.Image = toAsset(v) end end,
	}
	attachCommon(handle, box, titleLbl, bodyLbl)
	return handle
end

-- =====================================================================
--  ELEMENT: CODE (monospace block + copy)
-- =====================================================================
function Section:CreateCode(opts)
	opts = opts or {}
	local codeText = opts.Code or opts.Text or ""
	local box = create("Frame", {
		Parent = self._body, BackgroundColor3 = self._theme.Background, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self:_next(),
	})
	corner(box, RADIUS_LARGE)
	stroke(box, self._theme.Border, 1)
	create("UIPadding", { Parent = box, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 34) })
	local label = create("TextLabel", {
		Parent = box, BackgroundTransparency = 1, Font = FONT_CODE, Text = codeText,
		TextColor3 = self._theme.Success, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	})
	local copyBtn = create("TextButton", {
		Parent = box, AutoButtonColor = false, BackgroundColor3 = self._theme.SurfaceLight, BorderSizePixel = 0,
		Font = FONT_TITLE, Text = "\u{29C9}", TextColor3 = self._theme.TextDim, TextSize = 12,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(22, 22),
	})
	corner(copyBtn, RADIUS_SMALL)
	local onCopyFn
	copyBtn.MouseButton1Click:Connect(function()
		setClipboard(label.Text)
		copyBtn.Text = "\u{2713}"
		if onCopyFn then pcall(onCopyFn) end
		task.delay(1, function() if copyBtn and copyBtn.Parent then copyBtn.Text = "\u{29C9}" end end)
	end)
	local handle = {
		Type = "Code", Id = opts.Id, Instance = box,
		Set = function(v) label.Text = tostring(v) end,
		SetCode = function(v) label.Text = tostring(v) end,
		Get = function() return label.Text end,
		OnCopy = function(fn) onCopyFn = fn end,
	}
	attachCommon(handle, box)
	return handle
end

-- =====================================================================
--  ELEMENT: TAG (title + colored pill)
-- =====================================================================
function Section:CreateTag(opts)
	opts = opts or {}
	local color = opts.Color or self._theme.Accent
	local row = self:_row(ELEMENT_H)
	local titleLbl = create("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_VALUE, Text = opts.Title or "Tag",
		TextColor3 = self._theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -120, 1, 0),
	})
	local pill = create("TextLabel", {
		Parent = row, BackgroundColor3 = color, BorderSizePixel = 0, Font = FONT_TITLE,
		Text = opts.Text or "Tag", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 11,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X,
	})
	corner(pill, 10)
	create("UIPadding", { Parent = pill, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
	local handle = {
		Type = "Tag", Id = opts.Id, Instance = row,
		Set = function(v) pill.Text = tostring(v) end,
		SetColor = function(c) pill.BackgroundColor3 = c end,
		Get = function() return pill.Text end,
	}
	attachCommon(handle, row, titleLbl)
	return handle
end

-- =====================================================================
--  ELEMENT: DIVIDER
-- =====================================================================
function Section:CreateDivider()
	local holder = create("Frame", {
		Parent = self._body, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 9), LayoutOrder = self:_next(),
	})
	create("Frame", {
		Parent = holder, BackgroundColor3 = self._theme.Border, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 1),
	})
	return { Type = "Divider", Instance = holder }
end

-- =====================================================================
--  ELEMENT: SPACE (vertical spacer)
-- =====================================================================
function Section:CreateSpace(px)
	local holder = create("Frame", {
		Parent = self._body, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, px or 8), LayoutOrder = self:_next(),
	})
	return { Type = "Space", Instance = holder }
end

-- =====================================================================
--  ELEMENT: BUTTON
-- =====================================================================
function Section:CreateButton(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end

	-- advanced options: Color (paint the button), Justify, IconAlign, Icon
	local baseColor = opts.Color or self._theme.SurfaceLight
	local function pickText(c)
		local lum = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
		return (lum > 0.6) and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
	end
	local function lighten(c, a)
		return Color3.new(math.min(c.R + a, 1), math.min(c.G + a, 1), math.min(c.B + a, 1))
	end
	local textColor  = opts.Color and pickText(opts.Color) or self._theme.Text
	local hoverColor = opts.Color and lighten(opts.Color, 0.08) or self._theme.SurfaceHover

	local btn = create("TextButton", {
		Parent = self._body, BackgroundColor3 = baseColor, BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, ELEMENT_H), LayoutOrder = self:_next(),
	})
	corner(btn, RADIUS_LARGE)
	stroke(btn, self._theme.Border, 1)
	addHover(btn, baseColor, hoverColor)

	local justify   = opts.Justify or "Center"   -- Center | Left | Right | Between
	local iconAlign = opts.IconAlign or "Left"     -- Left | Right
	local resolved  = resolveIcon(opts.Icon)

	local iconEl
	if resolved and resolved.image then
		iconEl = create("ImageLabel", { BackgroundTransparency = 1, Image = resolved.image, Size = UDim2.fromOffset(16, 16) })
	elseif resolved and resolved.glyph then
		iconEl = create("TextLabel", { BackgroundTransparency = 1, Font = FONT_TITLE, Text = resolved.glyph,
			TextColor3 = textColor, TextSize = 14, Size = UDim2.fromOffset(16, 16) })
	end

	local label = create("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_TITLE, Text = opts.Title or "Button",
		TextColor3 = textColor, TextSize = 13, TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
	})

	if justify == "Between" then
		label.AutomaticSize = Enum.AutomaticSize.None
		label.Parent = btn
		if iconEl then iconEl.Parent = btn; iconEl.AnchorPoint = Vector2.new(0, 0.5) end
		if iconAlign == "Right" then
			if iconEl then iconEl.Position = UDim2.new(1, -28, 0.5, 0) end
			label.Position = UDim2.new(0, 12, 0, 0); label.Size = UDim2.new(1, -40, 1, 0)
			label.TextXAlignment = Enum.TextXAlignment.Left
		else
			if iconEl then iconEl.Position = UDim2.new(0, 12, 0.5, 0) end
			label.Position = UDim2.new(0, (iconEl and 36 or 12), 0, 0)
			label.Size = UDim2.new(1, (iconEl and -48 or -24), 1, 0)
			label.TextXAlignment = Enum.TextXAlignment.Right
		end
	else
		local holder = create("Frame", {
			Parent = btn, BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
		})
		local hAlign = (justify == "Left" and Enum.HorizontalAlignment.Left)
			or (justify == "Right" and Enum.HorizontalAlignment.Right)
			or Enum.HorizontalAlignment.Center
		create("UIListLayout", {
			Parent = holder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = hAlign,
			VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		})
		label.Parent = holder; label.LayoutOrder = 1
		if iconEl then
			iconEl.Parent = holder
			iconEl.LayoutOrder = (iconAlign == "Right") and 2 or 0
		end
	end

	btn.MouseButton1Click:Connect(function() pcall(callback) end)

	local handle = {
		Type = "Button", Id = opts.Id, Instance = btn,
		SetColor = function(c) btn.BackgroundColor3 = c end,
		Fire = function() pcall(callback) end,
	}
	attachCommon(handle, btn, label)
	registerElement(opts.Id, handle)
	return handle
end

-- =====================================================================
--  ELEMENT: TOGGLE
-- =====================================================================
function Section:CreateToggle(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end
	local state = opts.Default and true or false

	local row = self:_row(ELEMENT_H)
	local titleLbl = create("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_VALUE, Text = opts.Title or "Toggle",
		TextColor3 = self._theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -60, 1, 0),
	})
	local switch = create("TextButton", {
		Parent = row, BackgroundColor3 = state and self._theme.Accent or self._theme.ToggleOff, BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -48, 0.5, -10),
	})
	corner(switch, 10)
	local knob = create("Frame", {
		Parent = switch, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
		Size = UDim2.fromOffset(16, 16), Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
	})
	corner(knob, 8)
	local function render()
		switch.BackgroundColor3 = state and self._theme.Accent or self._theme.ToggleOff
		knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	end
	local function set(v, skipCb)
		state = v and true or false; render()
		if not skipCb then pcall(callback, state); autoSaveTrigger() end
	end
	switch.MouseButton1Click:Connect(function() set(not state) end)
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then set(not state) end
	end)
	addHover(row, self._theme.SurfaceLight, self._theme.SurfaceHover)
	local descLbl = applyDesc(row, titleLbl, opts.Desc or opts.Description, self._theme)
	local handle = {
		Type = "Toggle", Id = opts.Id, Instance = row,
		Get = function() return state end, Set = function(v) set(v, true) end,
		Callback = callback,
	}
	attachCommon(handle, row, titleLbl, descLbl)
	registerElement(opts.Id, handle)
	if state then pcall(callback, state) end
	return handle
end

-- =====================================================================
--  ELEMENT: SLIDER
-- =====================================================================
function Section:CreateSlider(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end
	local min = opts.Min or 0
	local max = opts.Max or 100
	local step = opts.Increment or 1
	local suffix = opts.Suffix or ""
	local value = clamp(opts.Default or min, min, max)

	local row = self:_row(46)
	local titleLbl = create("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_VALUE, Text = opts.Title or "Slider",
		TextColor3 = self._theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -80, 0, 18),
	})
	local valueLbl = create("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_VALUE,
		Text = tostring(value) .. (suffix ~= "" and (" " .. suffix) or ""), TextColor3 = self._theme.Accent,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -80, 0, 4), Size = UDim2.new(0, 70, 0, 18),
	})
	local track = create("Frame", {
		Parent = row, BackgroundColor3 = self._theme.ToggleOff, BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 1, -16), Size = UDim2.new(1, -20, 0, 6),
	})
	corner(track, 3)
	local fill = create("Frame", {
		Parent = track, BackgroundColor3 = self._theme.Accent, BorderSizePixel = 0,
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
	})
	corner(fill, 3)
	local function render()
		local a = (value - min) / (max - min)
		fill.Size = UDim2.new(a, 0, 1, 0)
		local shown = (step < 1) and string.format("%.2f", value) or tostring(round(value, step))
		valueLbl.Text = shown .. (suffix ~= "" and (" " .. suffix) or "")
	end
	local function set(v, skipCb)
		value = clamp(round(v, step), min, max); render()
		if not skipCb then pcall(callback, value); autoSaveTrigger() end
	end
	local dragging = false
	local function updateFromX(px)
		local rel = clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		set(min + rel * (max - min))
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; updateFromX(input.Position.X)
		end
	end)
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)
	local descLbl = applyDesc(row, titleLbl, opts.Desc or opts.Description, self._theme)
	local handle = {
		Type = "Slider", Id = opts.Id, Instance = row,
		Get = function() return value end, Set = function(v) set(v, true) end,
		SetMin = function(m) min = m; set(value, true) end,
		SetMax = function(m) max = m; set(value, true) end,
		Callback = callback,
	}
	attachCommon(handle, row, titleLbl, descLbl)
	registerElement(opts.Id, handle)
	pcall(callback, value)
	return handle
end

-- =====================================================================
--  ELEMENT: INPUT
-- =====================================================================
function Section:CreateInput(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end
	local row = self:_row(ELEMENT_H)
	local titleLbl = create("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_VALUE, Text = opts.Title or "Input",
		TextColor3 = self._theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.4, -10, 1, 0),
	})
	local boxHolder = create("Frame", {
		Parent = row, BackgroundColor3 = self._theme.Background, BorderSizePixel = 0,
		Position = UDim2.new(0.4, 4, 0.5, -12), Size = UDim2.new(0.6, -14, 0, 24),
	})
	corner(boxHolder, RADIUS_SMALL)
	stroke(boxHolder, self._theme.Border, 1)
	local box = create("TextBox", {
		Parent = boxHolder, BackgroundTransparency = 1, Font = FONT_VALUE, Text = opts.Default or "",
		PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = self._theme.TextMuted,
		TextColor3 = self._theme.Text, TextSize = 12, ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0),
	})
	box.FocusLost:Connect(function() pcall(callback, box.Text); autoSaveTrigger() end)
	local descLbl = applyDesc(row, titleLbl, opts.Desc or opts.Description, self._theme)
	local handle = {
		Type = "Input", Id = opts.Id, Instance = row,
		Get = function() return box.Text end, Set = function(v) box.Text = tostring(v) end,
		SetPlaceholder = function(v) box.PlaceholderText = tostring(v) end,
		Callback = callback,
	}
	attachCommon(handle, row, titleLbl, descLbl)
	registerElement(opts.Id, handle)
	return handle
end

-- =====================================================================
--  ELEMENT: KEYBIND
-- =====================================================================
function Section:CreateKeybind(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end
	local key = opts.Default or Enum.KeyCode.RightShift
	local listening = false
	local row = self:_row(ELEMENT_H)
	local titleLbl = create("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_VALUE, Text = opts.Title or "Keybind",
		TextColor3 = self._theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -110, 1, 0),
	})
	local keyBtn = create("TextButton", {
		Parent = row, BackgroundColor3 = self._theme.Background, BorderSizePixel = 0, Font = FONT_VALUE,
		Text = key.Name, TextColor3 = self._theme.Accent, TextSize = 12, AutoButtonColor = false,
		Size = UDim2.fromOffset(90, 24), Position = UDim2.new(1, -100, 0.5, -12),
	})
	corner(keyBtn, RADIUS_SMALL)
	stroke(keyBtn, self._theme.Border, 1)
	keyBtn.MouseButton1Click:Connect(function() listening = true; keyBtn.Text = "..." end)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false; key = input.KeyCode; keyBtn.Text = key.Name; autoSaveTrigger()
		elseif not listening and not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
			pcall(callback, key)
		end
	end)
	local descLbl = applyDesc(row, titleLbl, opts.Desc or opts.Description, self._theme)
	local handle = {
		Type = "Keybind", Id = opts.Id, Instance = row,
		Get = function() return key.Name end,
		Set = function(v)
			if typeof(v) == "EnumItem" then key = v
			elseif type(v) == "string" and Enum.KeyCode[v] then key = Enum.KeyCode[v] end
			keyBtn.Text = key.Name
		end,
	}
	attachCommon(handle, row, titleLbl, descLbl)
	registerElement(opts.Id, handle)
	return handle
end

-- =====================================================================
--  ELEMENT: DROPDOWN (overlay list; single or multi)
-- =====================================================================
local function inRect(guiObj, x, y)
	local p, s = guiObj.AbsolutePosition, guiObj.AbsoluteSize
	return x >= p.X and x <= p.X + s.X and y >= p.Y and y <= p.Y + s.Y
end

function Section:_buildDropdown(opts, multi)
	opts = opts or {}
	local callback = opts.Callback or function() end
	local values = opts.Values or {}
	local gui = self._vypers:_ensureGui()

	-- SIDEBAR MODE state (opts.Sidebar = true): render the option list as a panel
	-- docked to the right of the window with a search box, instead of an overlay.
	local sidebarMode = opts.Sidebar == true
	local sidebarW = 210
	local searchQuery = ""
	local sidebarPanel, searchBox

	-- AllowNone: single-select defaults to REQUIRING a choice; multi defaults to
	-- allowing an empty selection. Override with opts.AllowNone.
	local allowNone = (multi and (opts.AllowNone ~= false)) or (opts.AllowNone == true)

	local selected = {}
	if multi then
		if type(opts.Default) == "table" then
			for _, v in ipairs(opts.Default) do selected[v] = true end
		elseif opts.Default ~= nil then selected[opts.Default] = true end
	else
		if opts.Default ~= nil then selected[opts.Default] = true end
	end

	-- Values accept plain strings OR advanced entries:
	--   { Title = "Label", Value = "key", Icon = "sword", Desc = "extra text" }
	--   { Divider = true, Title = "Section" }  -- non-selectable separator
	local function normalize(raw)
		local ents, vlist = {}, {}
		for _, item in ipairs(raw or {}) do
			if type(item) == "table" then
				if item.Divider then
					table.insert(ents, { divider = true, title = item.Title })
				else
					local val = item.Value
					if val == nil then val = item.Title end
					table.insert(ents, { value = val, title = tostring(item.Title or val), icon = item.Icon, desc = item.Desc })
					table.insert(vlist, val)
				end
			else
				table.insert(ents, { value = item, title = tostring(item) })
				table.insert(vlist, item)
			end
		end
		return ents, vlist
	end
	local entries, valueList = normalize(values)

	local function orderedSelection()
		local list = {}
		for _, v in ipairs(valueList) do if selected[v] then table.insert(list, v) end end
		return list
	end
	local function labelFor(v)
		for _, e in ipairs(entries) do
			if not e.divider and e.value == v then return e.title end
		end
		return tostring(v)
	end
	local function selectionText()
		local list = orderedSelection()
		if #list == 0 then return "None" end
		if multi and #list > 2 then return tostring(#list) .. " selected" end
		local labels = {}
		for _, v in ipairs(list) do table.insert(labels, labelFor(v)) end
		return table.concat(labels, ", ")
	end
	local function selectionValue()
		if multi then return orderedSelection() else return orderedSelection()[1] end
	end

	local OPT_H = 30
	local DESC_EXTRA = 16
	local MAX_H = 210
	local contentHeight = 0

	-- the row stays a FIXED height; the list is a floating overlay
	local row = self:_row(ELEMENT_H)
	local titleLbl = create("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_VALUE,
		Text = opts.Title or (multi and "Multi Dropdown" or "Dropdown"),
		TextColor3 = self._theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.4, -10, 1, 0),
	})
	local selBtn = create("TextButton", {
		Parent = row, BackgroundColor3 = self._theme.Background, BorderSizePixel = 0, Font = FONT_VALUE,
		Text = "  " .. selectionText(), TextColor3 = self._theme.Text, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		AutoButtonColor = false, Position = UDim2.new(0.4, 4, 0.5, -12), Size = UDim2.new(0.6, -14, 0, 24),
	})
	corner(selBtn, RADIUS_SMALL)
	stroke(selBtn, self._theme.Border, 1)
	addHover(selBtn, self._theme.Background, self._theme.SurfaceHover)
	local arrow = create("TextLabel", {
		Parent = selBtn, BackgroundTransparency = 1, Font = FONT_TITLE, Text = "\u{25BC}",
		TextColor3 = self._theme.TextDim, TextSize = 9, Position = UDim2.new(1, -18, 0, 0), Size = UDim2.fromOffset(16, 24),
	})

	-- click-catcher (full screen) + list, both parented to the top-level gui
	local catcher = create("TextButton", {
		Name = "DropCatcher", Parent = gui, AutoButtonColor = false, Text = "",
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 300,
	})
	local listFrame = create("ScrollingFrame", {
		Name = "DropList", Parent = gui, BackgroundColor3 = self._theme.Surface, BorderSizePixel = 0,
		Size = UDim2.fromOffset(120, 0), Visible = false, ZIndex = 301, ClipsDescendants = true,
		ScrollBarThickness = 3, ScrollBarImageColor3 = self._theme.Border,
		ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})
	corner(listFrame, RADIUS_SMALL)
	stroke(listFrame, self._theme.Border, 1)
	create("UIListLayout", { Parent = listFrame, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
	-- inner padding so options don't touch the rounded corners (cleaner look)
	create("UIPadding", { Parent = listFrame,
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })

	local optionButtons = {}
	local function refresh()
		selBtn.Text = "  " .. selectionText()
		for v, o in pairs(optionButtons) do
			local isSel = selected[v] and true or false
			-- clean look: no blue fill; selection shown via brighter text + a check mark
			o.button.BackgroundColor3 = self._theme.Surface
			o.title.TextColor3 = isSel and self._theme.Text or self._theme.TextDim
			if o.check then o.check.Text = isSel and "\u{2713}" or "" end
		end
	end

	local open = false
	local posConn
	-- LIST_PAD must match the UIPadding (top+bottom) applied to listFrame above.
	local LIST_PAD = 4
	local TITLEBAR_H = 41 -- window title bar height (+1 separator) to stay clear of
	-- Robust overlay placement: the list always stays INSIDE the window body.
	-- It opens below the button; if it doesn't fit, it opens upward; whichever
	-- side is chosen, its height is capped to the room available and a final
	-- clamp guarantees it can never cover the title bar or spill past any edge.
	local function positionList()
		if sidebarMode then return end
		local btnPos, btnSize = selBtn.AbsolutePosition, selBtn.AbsoluteSize
		local width = btnSize.X
		local gap = 4
		local desiredH = math.min(contentHeight + LIST_PAD * 2, MAX_H)
		local mainFrame = self._window and self._window._main

		if not (mainFrame and mainFrame.Parent) then
			listFrame.Position = UDim2.fromOffset(btnPos.X, btnPos.Y + btnSize.Y + gap)
			listFrame.Size = UDim2.fromOffset(width, desiredH)
			return
		end

		local mPos, mSize = mainFrame.AbsolutePosition, mainFrame.AbsoluteSize
		local edge   = 8
		local top    = mPos.Y + TITLEBAR_H          -- never overlap the title bar
		local bottom = mPos.Y + mSize.Y - edge
		local left   = mPos.X + edge
		local right  = mPos.X + mSize.X - edge

		local roomBelow = bottom - (btnPos.Y + btnSize.Y + gap)
		local roomAbove = (btnPos.Y - gap) - top

		local h, y
		if desiredH <= roomBelow or roomBelow >= roomAbove then
			-- open downward (fits, or the button simply has more room below it)
			h = math.min(desiredH, math.max(OPT_H, roomBelow))
			y = btnPos.Y + btnSize.Y + gap
		else
			-- open upward
			h = math.min(desiredH, math.max(OPT_H, roomAbove))
			y = btnPos.Y - gap - h
		end

		-- hard safety clamp: the list can never leave the window body
		if y + h > bottom then y = bottom - h end
		if y < top then y = top end
		local x = clamp(btnPos.X, left, right - width)

		listFrame.Position = UDim2.fromOffset(x, y)
		listFrame.Size = UDim2.fromOffset(width, h)
	end
	local slideConn
	local function closeList()
		open = false
		if sidebarMode and sidebarPanel then
			-- slide the drawer back out to the right edge, then hide it
			sidebarPanel:TweenPosition(UDim2.new(1, sidebarW, 0, 41), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.16, true, function()
				if not open and sidebarPanel then sidebarPanel.Visible = false end
			end)
		else
			listFrame.Visible = false
		end
		catcher.Visible = false
		arrow.Text = "\u{25BC}"
		if posConn then posConn:Disconnect(); posConn = nil end
		if slideConn then slideConn:Disconnect(); slideConn = nil end
		if activeDropdownClose == closeList then activeDropdownClose = nil end
	end
	local function openList()
		if activeDropdownClose and activeDropdownClose ~= closeList then activeDropdownClose() end
		open = true
		arrow.Text = "\u{25B2}"
		if sidebarMode and sidebarPanel then
			-- drawer stays INSIDE the window (main clips it) and slides in from the right
			sidebarPanel.Position = UDim2.new(1, sidebarW, 0, 41)
			sidebarPanel.Visible = true
			listFrame.Visible = true
			sidebarPanel:TweenPosition(UDim2.new(1, 0, 0, 41), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
			slideConn = UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local p = input.Position
					if not inRect(sidebarPanel, p.X, p.Y) and not inRect(selBtn, p.X, p.Y) then closeList() end
				end
			end)
			activeDropdownClose = closeList
			return
		end
		positionList()
		listFrame.Visible = true
		catcher.Visible = true
		posConn = RunService.RenderStepped:Connect(positionList)
		activeDropdownClose = closeList
	end

	local function rebuild()
		-- clear old rows (keep the UIListLayout), then recreate from `entries`
		for _, c in ipairs(listFrame:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		optionButtons = {}
		contentHeight = 0
		for i, entry in ipairs(entries) do
			local hidden = sidebarMode and searchQuery ~= "" and not entry.divider
				and not string.find(string.lower(entry.title or ""), searchQuery, 1, true)
			if hidden then
				-- filtered out by the search box; skip rendering this entry
			elseif entry.divider then
				local dh = entry.title and 24 or 9
				local dframe = create("Frame", {
					Parent = listFrame, BackgroundColor3 = self._theme.Surface, BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, dh), LayoutOrder = i, ZIndex = 302,
				})
				create("Frame", { -- thin separator line
					Parent = dframe, BackgroundColor3 = self._theme.Border, BorderSizePixel = 0,
					Position = UDim2.new(0, 8, entry.title and 1 or 0.5, entry.title and -1 or 0),
					Size = UDim2.new(1, -16, 0, 1), ZIndex = 303,
				})
				if entry.title then
					create("TextLabel", {
						Parent = dframe, BackgroundTransparency = 1, Font = FONT_TITLE, Text = string.upper(entry.title),
						TextColor3 = self._theme.TextMuted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.new(0, 8, 0, 3),
						Size = UDim2.new(1, -16, 0, dh - 6), ZIndex = 303,
					})
				end
				contentHeight = contentHeight + dh
			else
				local v = entry.value
				local h = entry.desc and (OPT_H + DESC_EXTRA) or OPT_H
				local ob = create("TextButton", {
					Parent = listFrame, BackgroundColor3 = self._theme.Surface, BorderSizePixel = 0, Text = "",
					AutoButtonColor = false, Size = UDim2.new(1, 0, 0, h), LayoutOrder = i, ZIndex = 302,
				})
				local textX = 10
				local ri = resolveIcon(entry.icon)
				if ri and ri.glyph then
					create("TextLabel", {
						Parent = ob, BackgroundTransparency = 1, Font = FONT_VALUE, Text = ri.glyph,
						TextColor3 = self._theme.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center,
						Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(0, 18, 0, OPT_H), ZIndex = 303,
					})
					textX = 28
				elseif ri and ri.image then
					create("ImageLabel", {
						Parent = ob, BackgroundTransparency = 1, Image = ri.image, AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 8, 0, OPT_H / 2), Size = UDim2.fromOffset(16, 16), ZIndex = 303,
					})
					textX = 30
				end
				local titleLabel = create("TextLabel", {
					Parent = ob, BackgroundTransparency = 1, Font = FONT_VALUE, Text = entry.title,
					TextColor3 = self._theme.TextDim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, textX, 0, 0), Size = UDim2.new(1, -textX - 24, 0, entry.desc and 18 or OPT_H),
					ZIndex = 303,
				})
				if entry.desc then
					titleLabel.Position = UDim2.new(0, textX, 0, 5)
					titleLabel.TextYAlignment = Enum.TextYAlignment.Bottom
					create("TextLabel", {
						Parent = ob, BackgroundTransparency = 1, Font = FONT_VALUE, Text = entry.desc,
						TextColor3 = self._theme.TextMuted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
						Position = UDim2.new(0, textX, 0, 24), Size = UDim2.new(1, -textX - 24, 0, DESC_EXTRA + 2), ZIndex = 303,
					})
				end
				local check = create("TextLabel", {
					Name = "Check", Parent = ob, BackgroundTransparency = 1, Font = FONT_TITLE,
					Text = selected[v] and "\u{2713}" or "", TextColor3 = self._theme.Accent, TextSize = 13,
					Position = UDim2.new(1, -20, 0, 0), Size = UDim2.new(0, 16, 1, 0), ZIndex = 303,
				})
				optionButtons[v] = { button = ob, title = titleLabel, check = check }
				addHover(ob, self._theme.Surface, self._theme.SurfaceHover)
				ob.MouseButton1Click:Connect(function()
					if multi then
						if selected[v] then
							if allowNone or #orderedSelection() > 1 then selected[v] = nil end
						else
							selected[v] = true
						end
						refresh()
						pcall(callback, selectionValue())
						autoSaveTrigger()
					else
						if allowNone and selected[v] then
							selected[v] = nil
						else
							for k in pairs(selected) do selected[k] = nil end
							selected[v] = true
						end
						refresh()
						closeList()
						pcall(callback, selectionValue())
						autoSaveTrigger()
					end
				end)
				contentHeight = contentHeight + h
			end
		end
		refresh()
		if open then positionList() end
	end
	rebuild()

	-- SIDEBAR MODE build: dock the list to the right of the window + search box on top
	if sidebarMode then
		local mainFrame = (self._window and self._window._main) or gui
		sidebarPanel = create("Frame", {
			Name = "DropSidebar", Parent = mainFrame, BackgroundColor3 = self._theme.Surface, BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, sidebarW, 0, 41),
			Size = UDim2.new(0, sidebarW, 1, -41), Visible = false, ZIndex = 50, ClipsDescendants = true,
		})
		corner(sidebarPanel, RADIUS_LARGE)
		stroke(sidebarPanel, self._theme.Border, 1)
		create("TextLabel", {
			Parent = sidebarPanel, BackgroundTransparency = 1, Font = FONT_TITLE,
			Text = opts.Title or (multi and "Multi Select" or "Select"),
			TextColor3 = self._theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(1, -24, 0, 16), ZIndex = 302,
		})
		local searchHolder = create("Frame", {
			Parent = sidebarPanel, BackgroundColor3 = self._theme.Background, BorderSizePixel = 0,
			Position = UDim2.new(0, 10, 0, 34), Size = UDim2.new(1, -20, 0, 28), ZIndex = 302,
		})
		corner(searchHolder, RADIUS_SMALL)
		stroke(searchHolder, self._theme.Border, 1)
		create("TextLabel", {
			Parent = searchHolder, BackgroundTransparency = 1, Font = FONT_VALUE, Text = "\u{1F50D}",
			TextColor3 = self._theme.TextMuted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 6, 0, 0), Size = UDim2.fromOffset(18, 28), ZIndex = 303,
		})
		searchBox = create("TextBox", {
			Parent = searchHolder, BackgroundTransparency = 1, Font = FONT_VALUE, Text = "",
			PlaceholderText = "Search...", PlaceholderColor3 = self._theme.TextMuted,
			TextColor3 = self._theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false, ClipsDescendants = true,
			Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -36, 1, 0), ZIndex = 303,
		})
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			searchQuery = string.lower(searchBox.Text)
			rebuild()
		end)
		-- dock the option list under the search box, filling the rest of the panel
		listFrame.Parent = sidebarPanel
		listFrame.Position = UDim2.new(0, 10, 0, 70)
		listFrame.Size = UDim2.new(1, -20, 1, -80)
		listFrame.ZIndex = 302
	end

	selBtn.MouseButton1Click:Connect(function()
		if open then closeList() else openList() end
	end)
	catcher.MouseButton1Click:Connect(closeList)

	local function sameList(a, b)
		if #a ~= #b then return false end
		for i = 1, #a do if tostring(a[i]) ~= tostring(b[i]) then return false end end
		return true
	end
	-- swap the option list at runtime; by default prunes selections that no longer exist
	local function setValues(newValues, keepSelection)
		newValues = newValues or {}
		values = newValues
		entries, valueList = normalize(values)
		if not keepSelection then
			local valid = {}
			for _, v in ipairs(valueList) do valid[v] = true end
			for k in pairs(selected) do if not valid[k] then selected[k] = nil end end
		end
		rebuild()
	end

	local handle = {
		Type = multi and "MultiDropdown" or "Dropdown",
		Id = opts.Id, Instance = row, Multi = multi,
		Get = function() return selectionValue() end,
		Set = function(val)
			for k in pairs(selected) do selected[k] = nil end
			if multi and type(val) == "table" then
				for _, item in ipairs(val) do selected[item] = true end
			elseif val ~= nil then
				selected[val] = true
			end
			refresh()
		end,
		SetValues = setValues,   -- handle.SetValues({ "A", "B" })
		Refresh   = setValues,   -- alias
		GetValues = function() return values end,
		Callback  = callback,
	}
	handle.Select = handle.Set
	local descLbl = applyDesc(row, titleLbl, opts.Desc or opts.Description, self._theme)
	attachCommon(handle, row, titleLbl, descLbl)
	registerElement(opts.Id, handle)
	pcall(callback, selectionValue())

	-- built-in AUTO-REFRESH: pass opts.Refresh = function() return { ... } end
	-- the list re-polls every opts.RefreshInterval seconds (default 1) and only
	-- rebuilds when the returned list actually changed (e.g. players join/leave).
	if type(opts.Refresh) == "function" then
		local interval = opts.RefreshInterval or 1
		task.spawn(function()
			while row and row.Parent do
				local ok, newValues = pcall(opts.Refresh)
				if ok and type(newValues) == "table" then
					local _, newVList = normalize(newValues)
					if not sameList(newVList, valueList) then setValues(newValues, true) end
				end
				task.wait(interval)
			end
		end)
	end

	return handle
end

-- Single-select dropdown (list closes on pick). Legacy: pass Multi=true for multi.
function Section:CreateDropdown(opts)
	opts = opts or {}
	if opts.Multi then return self:_buildDropdown(opts, true) end
	return self:_buildDropdown(opts, false)
end

-- Multi-select dropdown (checkmarks, stays open, shows "N selected" when >2).
function Section:CreateMultiDropdown(opts)
	return self:_buildDropdown(opts, true)
end

-- =====================================================================
--  ELEMENT: COLORPICKER (overlay HSV panel)
-- =====================================================================
function Section:CreateColorPicker(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end
	local color = opts.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = color:ToHSV()
	local gui = self._vypers:_ensureGui()

	local row = self:_row(ELEMENT_H)
	local titleLbl = create("TextLabel", {
		Parent = row, BackgroundTransparency = 1, Font = FONT_VALUE, Text = opts.Title or "Color",
		TextColor3 = self._theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -60, 1, 0),
	})
	local preview = create("TextButton", {
		Parent = row, BackgroundColor3 = color, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
		Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -48, 0.5, -10),
	})
	corner(preview, RADIUS_SMALL)
	stroke(preview, self._theme.Border, 1)

	local catcher = create("TextButton", {
		Name = "ColorCatcher", Parent = gui, AutoButtonColor = false, Text = "",
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 310,
	})
	local panel = create("Frame", {
		Name = "ColorPanel", Parent = gui, BackgroundColor3 = self._theme.Surface, BorderSizePixel = 0,
		Size = UDim2.fromOffset(194, 140), Visible = false, ZIndex = 311,
	})
	corner(panel, RADIUS_LARGE)
	stroke(panel, self._theme.Border, 1)
	create("UIPadding", { Parent = panel, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

	local sv = create("ImageLabel", {
		Parent = panel, Image = "rbxassetid://4155801252", BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel = 0, Size = UDim2.fromOffset(150, 120), Position = UDim2.fromOffset(0, 0), ZIndex = 312,
	})
	create("ImageLabel", {
		Parent = sv, Image = "rbxassetid://3641079629", BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1), ZIndex = 313,
	})
	local svCursor = create("Frame", {
		Parent = sv, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
		Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 314,
	})
	corner(svCursor, 3)
	stroke(svCursor, Color3.fromRGB(0, 0, 0), 1)

	local hue = create("Frame", {
		Parent = panel, BorderSizePixel = 0, Size = UDim2.fromOffset(14, 120), Position = UDim2.fromOffset(160, 0), ZIndex = 312,
	})
	create("UIGradient", { Parent = hue, Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
	}) })
	corner(hue, RADIUS_SMALL)
	local hueCursor = create("Frame", {
		Parent = hue, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 314,
	})

	local function updateColor(fireCb)
		color = Color3.fromHSV(h, s, v)
		preview.BackgroundColor3 = color
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.fromScale(s, 1 - v)
		hueCursor.Position = UDim2.fromScale(0, h)
		if fireCb then pcall(callback, color); autoSaveTrigger() end
	end
	updateColor(false)

	local svDrag, hueDrag = false, false
	local function svUpdate(px, py)
		s = clamp((px - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
		v = 1 - clamp((py - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
		updateColor(true)
	end
	local function hueUpdate(py)
		h = clamp((py - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
		updateColor(true)
	end
	sv.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			svDrag = true; svUpdate(i.Position.X, i.Position.Y)
		end
	end)
	hue.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			hueDrag = true; hueUpdate(i.Position.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			svDrag = false; hueDrag = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			if svDrag then svUpdate(i.Position.X, i.Position.Y) end
			if hueDrag then hueUpdate(i.Position.Y) end
		end
	end)

	local pOpen, pConn = false, nil
	local function posPanel()
		panel.Position = UDim2.fromOffset(preview.AbsolutePosition.X - 156, preview.AbsolutePosition.Y + preview.AbsoluteSize.Y + 4)
	end
	local function closeP()
		pOpen = false; panel.Visible = false; catcher.Visible = false
		if pConn then pConn:Disconnect(); pConn = nil end
	end
	local function openP()
		pOpen = true; posPanel(); panel.Visible = true; catcher.Visible = true
		pConn = RunService.RenderStepped:Connect(posPanel)
	end
	preview.MouseButton1Click:Connect(function() if pOpen then closeP() else openP() end end)
	catcher.MouseButton1Click:Connect(closeP)

	local descLbl = applyDesc(row, titleLbl, opts.Desc or opts.Description, self._theme)
	local handle = {
		Type = "ColorPicker", Id = opts.Id, Instance = row,
		Get = function()
			return { math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5) }
		end,
		Set = function(val)
			if typeof(val) == "Color3" then
				h, s, v = val:ToHSV()
			elseif type(val) == "table" then
				h, s, v = Color3.fromRGB(val[1] or 255, val[2] or 255, val[3] or 255):ToHSV()
			end
			updateColor(false)
		end,
	}
	attachCommon(handle, row, titleLbl, descLbl)
	registerElement(opts.Id, handle)
	return handle
end

-- =====================================================================
--  RETURN
-- =====================================================================
return Vypers

--[[  ================================================================
      FULL-FEATURE USAGE EXAMPLE  (copy below into your own script)
      ================================================================

local Vypers = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

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

================================================================ ]]
