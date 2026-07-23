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

	See the commented usage example at the bottom of this file.
]]

-- =====================================================================
--  SERVICES
-- =====================================================================
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local LocalPlayer       = Players.LocalPlayer
local Mouse             = LocalPlayer and LocalPlayer:GetMouse()

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
}

local FONT_TITLE = Enum.Font.GothamBold  -- titles
local FONT_VALUE = Enum.Font.Gotham      -- values / body

local RADIUS_LARGE = 6 -- most elements
local RADIUS_SMALL = 4 -- small elements

local PADDING      = 8
local ELEMENT_H    = 34 -- default element height
local HEADER_H     = 32 -- section header height

-- =====================================================================
--  SIMPLE ICON SET (unicode glyphs -- no external image dependencies)
-- =====================================================================
local ICONS = {
	home     = "\u{2302}",
	settings = "\u{2699}",
	combat   = "\u{2694}",
	user     = "\u{263A}",
	star     = "\u{2605}",
	bolt     = "\u{26A1}",
	gear     = "\u{2699}",
	list     = "\u{2261}",
	search   = "\u{2315}",
	info     = "\u{2139}",
	flag     = "\u{2691}",
	heart    = "\u{2665}",
}

-- =====================================================================
--  UTILITY HELPERS
-- =====================================================================
local function create(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
		if props.Parent then
			inst.Parent = props.Parent
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	return inst
end

local function corner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or RADIUS_LARGE),
		Parent = parent,
	})
end

local function stroke(parent, color, thickness)
	return create("UIStroke", {
		Color = color or THEME.Border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function padding(parent, all)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
		Parent = parent,
	})
end

-- lightweight hover helper (color swap only, no heavy animation)
local function addHover(inst, base, hover)
	inst.MouseEnter:Connect(function()
		inst.BackgroundColor3 = hover
	end)
	inst.MouseLeave:Connect(function()
		inst.BackgroundColor3 = base
	end)
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
	if typeof(makefolder) == "function" then
		pcall(makefolder, path)
	end
end

-- =====================================================================
--  ROOT SCREENGUI
-- =====================================================================
local function mountGui()
	-- remove a previous instance if the script is re-run
	local existing = (gethui and gethui() or CoreGui):FindFirstChild("VypersUI")
	if existing then existing:Destroy() end

	local gui = create("ScreenGui", {
		Name = "VypersUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	})

	-- protect / parent using the best available method
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
		if not gui.Parent then
			gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		end
	end
	return gui
end

-- =====================================================================
--  VYPERS OBJECT
-- =====================================================================
local Vypers = {}
Vypers.__index = Vypers

-- registry of all elements for the config system
Vypers._elements = {}       -- [Id] = elementHandle
Vypers._autoSave  = false
Vypers._configName = nil
Vypers._folder    = "Vypers"
Vypers._gui       = nil
Vypers._theme     = THEME

-- register an element for config save/load
local function registerElement(id, handle)
	if id then
		Vypers._elements[id] = handle
	end
end

local function autoSaveTrigger()
	if Vypers._autoSave and Vypers._configName then
		Vypers:SaveConfig(Vypers._configName)
	end
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
			if ok then
				data[id] = val
			end
		end
	end

	local json = HttpService:JSONEncode(data)
	if hasFileAPI then
		safeMakeFolder(self._folder)
		local ok, err = pcall(writefile, self:_configPath(name), json)
		if not ok then return false, err end
		return true
	else
		-- fallback: keep in-memory only
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
		end
	end
	return true
end

function Vypers:AutoSave(state)
	self._autoSave = state and true or false
	return self._autoSave
end

function Vypers:SetFolder(folder)
	self._folder = folder or "Vypers"
end

function Vypers:SetAccent(color3)
	self._theme.Accent = color3
end

-- =====================================================================
--  WINDOW
-- =====================================================================
local Window = {}
Window.__index = Window

function Vypers:CreateWindow(opts)
	opts = opts or {}
	local title    = opts.Title or "Vypers"
	local subtitle = opts.SubTitle or ""
	local size     = opts.Size or Vector2.new(560, 420)
	local minSize  = Vector2.new(400, 300)

	if not self._gui then
		self._gui = mountGui()
	end
	local gui = self._gui

	-- ---- main window frame -------------------------------------------
	local main = create("Frame", {
		Name = "Window",
		Parent = gui,
		BackgroundColor3 = self._theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.new(0.5, -size.X/2, 0.5, -size.Y/2),
		ClipsDescendants = true,
		Active = true,
	})
	corner(main, RADIUS_LARGE)
	stroke(main, self._theme.Border, 1)

	-- ---- title bar ---------------------------------------------------
	local titleBar = create("Frame", {
		Name = "TitleBar",
		Parent = main,
		BackgroundColor3 = self._theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
	})
	corner(titleBar, RADIUS_LARGE)
	-- mask bottom corners of the title bar
	create("Frame", {
		Parent = titleBar,
		BackgroundColor3 = self._theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, RADIUS_LARGE),
		Position = UDim2.new(0, 0, 1, -RADIUS_LARGE),
	})

	local titleLabel = create("TextLabel", {
		Parent = titleBar,
		BackgroundTransparency = 1,
		Font = FONT_TITLE,
		Text = title,
		TextColor3 = self._theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
	})

	local subLabel = create("TextLabel", {
		Parent = titleBar,
		BackgroundTransparency = 1,
		Font = FONT_VALUE,
		Text = subtitle,
		TextColor3 = self._theme.TextDim,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14 + titleLabel.TextBounds.X + 8, 0, 1),
		Size = UDim2.new(0.4, 0, 1, 0),
	})
	-- reposition subtitle after title measured
	task.defer(function()
		subLabel.Position = UDim2.new(0, 14 + titleLabel.TextBounds.X + 8, 0, 1)
	end)

	-- window control buttons (minimize / close)
	local function makeCtrlButton(char, xOffset, hoverColor)
		local b = create("TextButton", {
			Parent = titleBar,
			BackgroundColor3 = self._theme.SurfaceLight,
			BorderSizePixel = 0,
			Text = char,
			Font = FONT_TITLE,
			TextColor3 = self._theme.Text,
			TextSize = 16,
			AutoButtonColor = false,
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.new(1, xOffset, 0.5, -12),
		})
		corner(b, RADIUS_SMALL)
		addHover(b, self._theme.SurfaceLight, hoverColor or self._theme.SurfaceHover)
		return b
	end

	local closeBtn = makeCtrlButton("\u{2715}", -30, Color3.fromRGB(200, 60, 60))
	local minBtn   = makeCtrlButton("\u{2013}", -60, self._theme.SurfaceHover)

	-- ---- sidebar (vertical, scrollable) — holds the tabs -------------
	local SIDEBAR_W = 150
	local sidebar = create("ScrollingFrame", {
		Name = "Sidebar",
		Parent = main,
		BackgroundColor3 = self._theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, SIDEBAR_W, 1, -40),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = self._theme.Border,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})
	create("UIListLayout", {
		Parent = sidebar,
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	create("UIPadding", {
		Parent = sidebar,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	-- vertical separator between sidebar and content
	create("Frame", {
		Parent = main,
		BackgroundColor3 = self._theme.Border,
		BorderSizePixel = 0,
		Position = UDim2.new(0, SIDEBAR_W, 0, 40),
		Size = UDim2.new(0, 1, 1, -40),
	})

	-- ---- content holder (per-tab pages live here) --------------------
	local content = create("Frame", {
		Name = "Content",
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, SIDEBAR_W + 1, 0, 40),
		Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, -40),
	})

	-- ---- resize handle (bottom-right) --------------------------------
	local resizeHandle = create("TextButton", {
		Name = "Resize",
		Parent = main,
		BackgroundTransparency = 1,
		Text = "\u{25E2}",
		Font = FONT_TITLE,
		TextColor3 = self._theme.TextMuted,
		TextSize = 14,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -18, 1, -18),
		ZIndex = 5,
	})

	-- =============================================================
	--  window object
	-- =============================================================
	local self_win = setmetatable({}, Window)
	self_win._vypers  = self
	self_win._gui     = gui
	self_win._main    = main
	self_win._content = content
	self_win._sidebar = sidebar
	self_win._tabs    = {}
	self_win._activeTab = nil
	self_win._minSize = minSize

	-- =============================================================
	--  DRAG (title bar)
	-- =============================================================
	do
		local dragging, dragStart, startPos
		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				main.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	-- =============================================================
	--  RESIZE (bottom-right corner, min 400x300)
	-- =============================================================
	do
		local resizing, resizeStart, startSize
		resizeHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				resizeStart = input.Position
				startSize = main.AbsoluteSize
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						resizing = false
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - resizeStart
				local newX = clamp(startSize.X + delta.X, minSize.X, 4096)
				local newY = clamp(startSize.Y + delta.Y, minSize.Y, 4096)
				main.Size = UDim2.fromOffset(newX, newY)
			end
		end)
	end

	-- =============================================================
	--  MINIMIZE -> floating circle icon (bottom-left)
	-- =============================================================
	local floatIcon = create("TextButton", {
		Name = "FloatIcon",
		Parent = gui,
		BackgroundColor3 = self._theme.Surface,
		BorderSizePixel = 0,
		Text = string.sub(title, 1, 1):upper(),
		Font = FONT_TITLE,
		TextColor3 = self._theme.Accent,
		TextSize = 20,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(0, 20, 1, -70),
		Visible = false,
		Active = true,
		ZIndex = 20,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = floatIcon }) -- full circle
	stroke(floatIcon, self._theme.Accent, 1)
	addHover(floatIcon, self._theme.Surface, self._theme.SurfaceHover)

	-- make the floating icon draggable too
	do
		local fDragging, fStart, fPos, moved
		floatIcon.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				fDragging = true
				moved = false
				fStart = input.Position
				fPos = floatIcon.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						fDragging = false
						if not moved then
							-- treat as click -> restore
							main.Visible = true
							floatIcon.Visible = false
						end
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if fDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - fStart
				if delta.Magnitude > 4 then moved = true end
				floatIcon.Position = UDim2.new(
					fPos.X.Scale, fPos.X.Offset + delta.X,
					fPos.Y.Scale, fPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	minBtn.MouseButton1Click:Connect(function()
		main.Visible = false
		floatIcon.Visible = true
	end)

	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	self_win._floatIcon = floatIcon
	return self_win
end

function Window:Toggle()
	self._main.Visible = not self._main.Visible
	self._floatIcon.Visible = not self._main.Visible
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

	-- tab button
	local iconText = ""
	if icon and ICONS[icon] then
		iconText = ICONS[icon] .. "  "
	elseif icon and type(icon) == "string" and #icon <= 2 then
		iconText = icon .. "  "
	end

	local btn = create("TextButton", {
		Name = "Tab_" .. title,
		Parent = self._sidebar,
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Text = iconText .. title,
		Font = FONT_TITLE,
		TextColor3 = theme.TextDim,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 30),
	})
	corner(btn, RADIUS_SMALL)
	create("UIPadding", {
		Parent = btn,
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 10),
	})

	-- content page for this tab (scrolling)
	local page = create("ScrollingFrame", {
		Name = "Page_" .. title,
		Parent = self._content,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
	})
	create("UIListLayout", {
		Parent = page,
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, PADDING),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	create("UIPadding", {
		Parent = page,
		PaddingTop = UDim.new(0, PADDING),
		PaddingBottom = UDim.new(0, PADDING),
		PaddingLeft = UDim.new(0, PADDING + 2),
		PaddingRight = UDim.new(0, PADDING + 2),
	})

	local self_tab = setmetatable({}, Tab)
	self_tab._window = self
	self_tab._vypers = self._vypers
	self_tab._btn = btn
	self_tab._page = page
	self_tab._theme = theme

	local function activate()
		for _, t in ipairs(self._tabs) do
			t._page.Visible = false
			t._btn.BackgroundColor3 = theme.Surface
			t._btn.TextColor3 = theme.TextDim
		end
		page.Visible = true
		btn.BackgroundColor3 = theme.Accent
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		self._activeTab = self_tab
	end
	self_tab.Activate = activate

	btn.MouseButton1Click:Connect(activate)
	btn.MouseEnter:Connect(function()
		if self._activeTab ~= self_tab then
			btn.BackgroundColor3 = theme.SurfaceHover
		end
	end)
	btn.MouseLeave:Connect(function()
		if self._activeTab ~= self_tab then
			btn.BackgroundColor3 = theme.Surface
		end
	end)

	table.insert(self._tabs, self_tab)
	if #self._tabs == 1 then
		activate() -- first tab active by default
	end
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

	local container = create("Frame", {
		Name = "Section_" .. title,
		Parent = self._page,
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, HEADER_H),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
	})
	corner(container, RADIUS_LARGE)
	stroke(container, theme.Border, 1)

	local layout = create("UIListLayout", {
		Parent = container,
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	-- header (click to collapse/expand)
	local header = create("TextButton", {
		Name = "Header",
		Parent = container,
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, HEADER_H),
		LayoutOrder = 0,
	})
	local arrow = create("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Font = FONT_TITLE,
		Text = "\u{25BC}",
		TextColor3 = theme.Accent,
		TextSize = 10,
		Size = UDim2.fromOffset(20, HEADER_H),
		Position = UDim2.new(1, -26, 0, 0),
	})
	create("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Font = FONT_TITLE,
		Text = title,
		TextColor3 = theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -40, 1, 0),
	})

	-- body holds elements
	local body = create("Frame", {
		Name = "Body",
		Parent = container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	})
	create("UIListLayout", {
		Parent = body,
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	create("UIPadding", {
		Parent = body,
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local open = true
	header.MouseButton1Click:Connect(function()
		open = not open
		body.Visible = open
		arrow.Text = open and "\u{25BC}" or "\u{25B6}"
	end)

	local self_sec = setmetatable({}, Section)
	self_sec._vypers = self._vypers
	self_sec._body = body
	self_sec._theme = theme
	self_sec._order = 0
	return self_sec
end

-- helper for consistent element ordering
function Section:_next()
	self._order = self._order + 1
	return self._order
end

-- base row builder shared by most elements
function Section:_row(height)
	local row = create("Frame", {
		Parent = self._body,
		BackgroundColor3 = self._theme.SurfaceLight,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height or ELEMENT_H),
		LayoutOrder = self:_next(),
	})
	corner(row, RADIUS_LARGE)
	return row
end

-- =====================================================================
--  ELEMENT: LABEL
-- =====================================================================
function Section:CreateLabel(opts)
	opts = opts or {}
	local row = create("TextLabel", {
		Parent = self._body,
		BackgroundColor3 = self._theme.SurfaceLight,
		BorderSizePixel = 0,
		Font = FONT_VALUE,
		Text = "  " .. (opts.Title or ""),
		TextColor3 = self._theme.TextDim,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = self:_next(),
	})
	corner(row, RADIUS_SMALL)

	local handle = {
		Type = "Label",
		Id = opts.Id,
		Instance = row,
		Set = function(v) row.Text = "  " .. tostring(v) end,
		Get = function() return (row.Text:gsub("^%s+", "")) end,
		SetText = function(v) row.Text = "  " .. tostring(v) end,
	}
	registerElement(opts.Id, handle)
	return handle
end

-- =====================================================================
--  ELEMENT: BUTTON
-- =====================================================================
function Section:CreateButton(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end

	local btn = create("TextButton", {
		Parent = self._body,
		BackgroundColor3 = self._theme.SurfaceLight,
		BorderSizePixel = 0,
		Font = FONT_TITLE,
		Text = opts.Title or "Button",
		TextColor3 = self._theme.Text,
		TextSize = 13,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, ELEMENT_H),
		LayoutOrder = self:_next(),
	})
	corner(btn, RADIUS_LARGE)
	stroke(btn, self._theme.Border, 1)
	addHover(btn, self._theme.SurfaceLight, self._theme.SurfaceHover)

	btn.MouseButton1Click:Connect(function()
		pcall(callback)
	end)

	local handle = { Type = "Button", Id = opts.Id, Instance = btn }
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
		Parent = row,
		BackgroundTransparency = 1,
		Font = FONT_VALUE,
		Text = opts.Title or "Toggle",
		TextColor3 = self._theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -60, 1, 0),
	})

	local switch = create("TextButton", {
		Parent = row,
		BackgroundColor3 = state and self._theme.Accent or self._theme.ToggleOff,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -48, 0.5, -10),
	})
	corner(switch, 10)
	local knob = create("Frame", {
		Parent = switch,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(16, 16),
		Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
	})
	corner(knob, 8)

	local function render()
		switch.BackgroundColor3 = state and self._theme.Accent or self._theme.ToggleOff
		knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	end

	local function set(v, skipCb)
		state = v and true or false
		render()
		if not skipCb then
			pcall(callback, state)
			autoSaveTrigger()
		end
	end

	switch.MouseButton1Click:Connect(function() set(not state) end)
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			set(not state)
		end
	end)
	addHover(row, self._theme.SurfaceLight, self._theme.SurfaceHover)

	local handle = {
		Type = "Toggle",
		Id = opts.Id,
		Instance = row,
		Get = function() return state end,
		Set = function(v) set(v, true) end,
	}
	registerElement(opts.Id, handle)

	-- fire once for default
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
		Parent = row,
		BackgroundTransparency = 1,
		Font = FONT_VALUE,
		Text = opts.Title or "Slider",
		TextColor3 = self._theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 4),
		Size = UDim2.new(1, -80, 0, 18),
	})
	local valueLbl = create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Font = FONT_VALUE,
		Text = tostring(value) .. (suffix ~= "" and (" " .. suffix) or ""),
		TextColor3 = self._theme.Accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -80, 0, 4),
		Size = UDim2.new(0, 70, 0, 18),
	})

	local track = create("Frame", {
		Parent = row,
		BackgroundColor3 = self._theme.ToggleOff,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 1, -16),
		Size = UDim2.new(1, -20, 0, 6),
	})
	corner(track, 3)
	local fill = create("Frame", {
		Parent = track,
		BackgroundColor3 = self._theme.Accent,
		BorderSizePixel = 0,
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
		value = clamp(round(v, step), min, max)
		render()
		if not skipCb then
			pcall(callback, value)
			autoSaveTrigger()
		end
	end

	local dragging = false
	local function updateFromX(px)
		local rel = clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		set(min + rel * (max - min))
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)

	local handle = {
		Type = "Slider",
		Id = opts.Id,
		Instance = row,
		Get = function() return value end,
		Set = function(v) set(v, true) end,
	}
	registerElement(opts.Id, handle)
	pcall(callback, value)
	return handle
end

-- =====================================================================
--  ELEMENT: INPUT (text box)
-- =====================================================================
function Section:CreateInput(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end

	local row = self:_row(ELEMENT_H)
	create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Font = FONT_VALUE,
		Text = opts.Title or "Input",
		TextColor3 = self._theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.4, -10, 1, 0),
	})

	local boxHolder = create("Frame", {
		Parent = row,
		BackgroundColor3 = self._theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.4, 4, 0.5, -12),
		Size = UDim2.new(0.6, -14, 0, 24),
	})
	corner(boxHolder, RADIUS_SMALL)
	stroke(boxHolder, self._theme.Border, 1)

	local box = create("TextBox", {
		Parent = boxHolder,
		BackgroundTransparency = 1,
		Font = FONT_VALUE,
		Text = opts.Default or "",
		PlaceholderText = opts.Placeholder or "",
		PlaceholderColor3 = self._theme.TextMuted,
		TextColor3 = self._theme.Text,
		TextSize = 12,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
	})

	box.FocusLost:Connect(function()
		pcall(callback, box.Text)
		autoSaveTrigger()
	end)

	local handle = {
		Type = "Input",
		Id = opts.Id,
		Instance = row,
		Get = function() return box.Text end,
		Set = function(v) box.Text = tostring(v) end,
	}
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
	create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Font = FONT_VALUE,
		Text = opts.Title or "Keybind",
		TextColor3 = self._theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -110, 1, 0),
	})

	local keyBtn = create("TextButton", {
		Parent = row,
		BackgroundColor3 = self._theme.Background,
		BorderSizePixel = 0,
		Font = FONT_VALUE,
		Text = key.Name,
		TextColor3 = self._theme.Accent,
		TextSize = 12,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(90, 24),
		Position = UDim2.new(1, -100, 0.5, -12),
	})
	corner(keyBtn, RADIUS_SMALL)
	stroke(keyBtn, self._theme.Border, 1)

	keyBtn.MouseButton1Click:Connect(function()
		listening = true
		keyBtn.Text = "..."
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			key = input.KeyCode
			keyBtn.Text = key.Name
			autoSaveTrigger()
		elseif not listening and not gpe
			and input.UserInputType == Enum.UserInputType.Keyboard
			and input.KeyCode == key then
			pcall(callback, key)
		end
	end)

	local handle = {
		Type = "Keybind",
		Id = opts.Id,
		Instance = row,
		Get = function() return key.Name end,
		Set = function(v)
			if typeof(v) == "EnumItem" then
				key = v
			elseif type(v) == "string" and Enum.KeyCode[v] then
				key = Enum.KeyCode[v]
			end
			keyBtn.Text = key.Name
		end,
	}
	registerElement(opts.Id, handle)
	return handle
end

-- =====================================================================
--  ELEMENT: DROPDOWN (single or multi select)
-- =====================================================================
function Section:CreateDropdown(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end
	local values = opts.Values or {}
	local multi = opts.Multi and true or false

	-- selection state
	local selected = {}
	if multi then
		if type(opts.Default) == "table" then
			for _, v in ipairs(opts.Default) do selected[v] = true end
		end
	else
		if opts.Default ~= nil then selected[opts.Default] = true end
	end

	local function selectionText()
		local list = {}
		for _, v in ipairs(values) do
			if selected[v] then table.insert(list, v) end
		end
		if #list == 0 then return "None" end
		return table.concat(list, ", ")
	end

	local function selectionValue()
		if multi then
			local list = {}
			for _, v in ipairs(values) do
				if selected[v] then table.insert(list, v) end
			end
			return list
		else
			for _, v in ipairs(values) do
				if selected[v] then return v end
			end
			return nil
		end
	end

	local row = self:_row(ELEMENT_H)
	row.ClipsDescendants = false -- allow list to overflow visually
	create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Font = FONT_VALUE,
		Text = opts.Title or "Dropdown",
		TextColor3 = self._theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.4, -10, 1, 0),
	})

	local selBtn = create("TextButton", {
		Parent = row,
		BackgroundColor3 = self._theme.Background,
		BorderSizePixel = 0,
		Font = FONT_VALUE,
		Text = "  " .. selectionText(),
		TextColor3 = self._theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutoButtonColor = false,
		Position = UDim2.new(0.4, 4, 0.5, -12),
		Size = UDim2.new(0.6, -14, 0, 24),
	})
	corner(selBtn, RADIUS_SMALL)
	stroke(selBtn, self._theme.Border, 1)
	create("TextLabel", {
		Parent = selBtn,
		BackgroundTransparency = 1,
		Font = FONT_TITLE,
		Text = "\u{25BC}",
		TextColor3 = self._theme.TextDim,
		TextSize = 9,
		Position = UDim2.new(1, -18, 0, 0),
		Size = UDim2.fromOffset(16, 24),
	})

	-- dropdown list (expands the row height when open)
	local listFrame = create("Frame", {
		Parent = row,
		BackgroundColor3 = self._theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.4, 4, 1, 2),
		Size = UDim2.new(0.6, -14, 0, 0),
		Visible = false,
		ZIndex = 10,
		ClipsDescendants = true,
	})
	corner(listFrame, RADIUS_SMALL)
	stroke(listFrame, self._theme.Border, 1)
	local listLayout = create("UIListLayout", {
		Parent = listFrame,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local optionButtons = {}
	local function refresh()
		selBtn.Text = "  " .. selectionText()
		for v, b in pairs(optionButtons) do
			b.BackgroundColor3 = selected[v] and self._theme.Accent or self._theme.Background
			b.TextColor3 = selected[v] and Color3.fromRGB(255,255,255) or self._theme.TextDim
		end
	end

	local open = false
	local function setOpen(v)
		open = v
		listFrame.Visible = open
		if open then
			listFrame.Size = UDim2.new(0.6, -14, 0, math.min(#values, 6) * 26)
			row.Size = UDim2.new(1, 0, 0, ELEMENT_H + math.min(#values, 6) * 26 + 4)
		else
			listFrame.Size = UDim2.new(0.6, -14, 0, 0)
			row.Size = UDim2.new(1, 0, 0, ELEMENT_H)
		end
	end

	for i, v in ipairs(values) do
		local ob = create("TextButton", {
			Parent = listFrame,
			BackgroundColor3 = self._theme.Background,
			BorderSizePixel = 0,
			Font = FONT_VALUE,
			Text = "  " .. tostring(v),
			TextColor3 = self._theme.TextDim,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = i,
			ZIndex = 11,
		})
		optionButtons[v] = ob
		ob.MouseButton1Click:Connect(function()
			if multi then
				selected[v] = not selected[v] or nil
			else
				selected = { [v] = true }
				setOpen(false)
			end
			refresh()
			pcall(callback, selectionValue())
			autoSaveTrigger()
		end)
		ob.MouseEnter:Connect(function()
			if not selected[v] then ob.BackgroundColor3 = self._theme.SurfaceHover end
		end)
		ob.MouseLeave:Connect(function()
			if not selected[v] then ob.BackgroundColor3 = self._theme.Background end
		end)
	end

	selBtn.MouseButton1Click:Connect(function() setOpen(not open) end)
	refresh()

	local handle = {
		Type = "Dropdown",
		Id = opts.Id,
		Instance = row,
		Get = function() return selectionValue() end,
		Set = function(v)
			selected = {}
			if multi and type(v) == "table" then
				for _, val in ipairs(v) do selected[val] = true end
			elseif v ~= nil then
				selected[v] = true
			end
			refresh()
		end,
		Refresh = function(newValues)
			-- (optional) replace value list
			values = newValues or values
		end,
	}
	registerElement(opts.Id, handle)
	pcall(callback, selectionValue())
	return handle
end

-- =====================================================================
--  ELEMENT: COLOR PICKER
-- =====================================================================
function Section:CreateColorPicker(opts)
	opts = opts or {}
	local callback = opts.Callback or function() end
	local color = opts.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = Color3.toHSV(color)

	local row = self:_row(ELEMENT_H)
	row.ClipsDescendants = false
	create("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Font = FONT_VALUE,
		Text = opts.Title or "Color",
		TextColor3 = self._theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -60, 1, 0),
	})

	local preview = create("TextButton", {
		Parent = row,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -48, 0.5, -10),
	})
	corner(preview, RADIUS_SMALL)
	stroke(preview, self._theme.Border, 1)

	-- picker panel (SV area + hue bar)
	local panel = create("Frame", {
		Parent = row,
		BackgroundColor3 = self._theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -158, 1, 4),
		Size = UDim2.fromOffset(150, 130),
		Visible = false,
		ZIndex = 12,
	})
	corner(panel, RADIUS_SMALL)
	stroke(panel, self._theme.Border, 1)

	local svArea = create("ImageLabel", {
		Parent = panel,
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(110, 90),
		Image = "rbxassetid://4155801252", -- white->transparent gradient (SV map)
		ZIndex = 13,
	})
	corner(svArea, RADIUS_SMALL)
	-- darkening overlay for value axis
	create("ImageLabel", {
		Parent = svArea,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Image = "rbxassetid://3641079629", -- transparent->black overlay
		ZIndex = 13,
	})
	local svCursor = create("Frame", {
		Parent = svArea,
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(6, 6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(s, 0, 1 - v, 0),
		ZIndex = 14,
	})
	corner(svCursor, 3)

	local hueBar = create("Frame", {
		Parent = panel,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(124, 8),
		Size = UDim2.fromOffset(16, 90),
		ZIndex = 13,
	})
	corner(hueBar, RADIUS_SMALL)
	create("UIGradient", {
		Parent = hueBar,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
		}),
	})
	local hueCursor = create("Frame", {
		Parent = hueBar,
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 3),
		Position = UDim2.new(0, 0, h, 0),
		ZIndex = 14,
	})

	local function apply(skipCb)
		color = Color3.fromHSV(h, s, v)
		preview.BackgroundColor3 = color
		svArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		hueCursor.Position = UDim2.new(0, 0, h, 0)
		if not skipCb then
			pcall(callback, color)
			autoSaveTrigger()
		end
	end

	-- SV dragging
	local svDrag = false
	local function svUpdate(px, py)
		local rx = clamp((px - svArea.AbsolutePosition.X) / svArea.AbsoluteSize.X, 0, 1)
		local ry = clamp((py - svArea.AbsolutePosition.Y) / svArea.AbsoluteSize.Y, 0, 1)
		s = rx
		v = 1 - ry
		apply()
	end
	svArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = true
			svUpdate(input.Position.X, input.Position.Y)
		end
	end)

	-- Hue dragging
	local hueDrag = false
	local function hueUpdate(py)
		local ry = clamp((py - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
		h = ry
		apply()
	end
	local hueHit = create("TextButton", {
		Parent = hueBar,
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 15,
	})
	hueHit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			hueDrag = true
			hueUpdate(input.Position.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			svDrag = false
			hueDrag = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if svDrag then svUpdate(input.Position.X, input.Position.Y) end
			if hueDrag then hueUpdate(input.Position.Y) end
		end
	end)

	local open = false
	preview.MouseButton1Click:Connect(function()
		open = not open
		panel.Visible = open
		row.Size = open and UDim2.new(1, 0, 0, ELEMENT_H + 140)
			or UDim2.new(1, 0, 0, ELEMENT_H)
	end)

	local handle = {
		Type = "ColorPicker",
		Id = opts.Id,
		Instance = row,
		Get = function()
			return { R = math.floor(color.R*255+0.5), G = math.floor(color.G*255+0.5), B = math.floor(color.B*255+0.5) }
		end,
		Set = function(val)
			if typeof(val) == "Color3" then
				color = val
			elseif type(val) == "table" and val.R then
				color = Color3.fromRGB(val.R, val.G, val.B)
			end
			h, s, v = Color3.toHSV(color)
			apply(true)
		end,
	}
	registerElement(opts.Id, handle)
	pcall(callback, color)
	return handle
end

-- =====================================================================
--  RETURN THE VYPERS OBJECT
-- =====================================================================
local instance = setmetatable({}, Vypers)
instance._elements = Vypers._elements
instance._autoSave = false
instance._folder = "Vypers"
instance._theme = THEME
return instance

--[[
=========================================================================
 USAGE EXAMPLE
=========================================================================

local Vypers = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

Vypers:SetFolder("MyScriptConfigs")   -- optional: where configs are saved

local Window = Vypers:CreateWindow({
    Title = "My Script",
    SubTitle = "v1.0",
})

local MainTab = Window:CreateTab({ Title = "Main", Icon = "home" })
local Combat  = MainTab:CreateSection({ Title = "Combat" })

Combat:CreateToggle({
    Id = "autoFarm",
    Title = "Auto Farm",
    Default = false,
    Callback = function(state) print("Auto Farm:", state) end,
})

Combat:CreateSlider({
    Id = "walkSpeed",
    Title = "Walk Speed",
    Min = 0, Max = 500, Default = 16,
    Suffix = "studs",
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = value
        end
    end,
})

Combat:CreateButton({
    Title = "Execute",
    Callback = function() print("Executed!") end,
})

Combat:CreateDropdown({
    Id = "mode",
    Title = "Select Mode",
    Values = { "Mode A", "Mode B", "Mode C" },
    Default = "Mode A",
    Multi = false,
    Callback = function(value) print("Mode:", value) end,
})

Combat:CreateInput({
    Id = "target",
    Title = "Target",
    Placeholder = "Enter value...",
    Callback = function(text) print("Target:", text) end,
})

Combat:CreateLabel({ Title = "Version 1.0" })

Combat:CreateKeybind({
    Id = "toggleKey",
    Title = "Toggle Script",
    Default = Enum.KeyCode.RightShift,
    Callback = function(key) Window:Toggle() end,
})

local Settings = Window:CreateTab({ Title = "Settings", Icon = "settings" })
local Theme = Settings:CreateSection({ Title = "Appearance" })

Theme:CreateColorPicker({
    Id = "accent",
    Title = "Accent Color",
    Default = Color3.fromRGB(100, 200, 255),
    Callback = function(color) print("Color:", color) end,
})

-- Config system --------------------------------------------------------
Vypers:AutoSave(true)              -- auto-save on any change
Vypers:SaveConfig("MyConfig")      -- save all element states to JSON
Vypers:LoadConfig("MyConfig")      -- restore all element states

=========================================================================
]]
