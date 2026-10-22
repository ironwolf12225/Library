local Underlord = { version = "2.1.0" }

local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Window = {}
local Tab = {}
local Section = {}

Window.__index = Window
Tab.__index = Tab
Section.__index = Section

local defaults = {
	size = Vector2.new(780, 470),
	scale = 0.5,
	dragDuration = 0.10,
	tintDuration = 0.08,
	slideDuration = 0.20,
	revealDuration = 0.16,
	popupDuration = 0.10,
	accent = Color3.fromRGB(222, 65, 88),
	background = Color3.fromRGB(15, 15, 18),
	panel = Color3.fromRGB(17, 17, 18),
	text = Color3.fromRGB(213, 213, 213),
	muted = Color3.fromRGB(139, 139, 139),
	outline = Color3.fromRGB(130, 130, 130),
	font = Enum.Font.Code,
	textSize = 13,
	hoverDuration = 0.14,
	fadeOutDuration = 0.09,
	fadeInDuration = 0.12,
	toggleKey = Enum.KeyCode.RightShift,
}

local function create(className, parent, properties)
	local instance = Instance.new(className)

	for property, value in pairs(properties or {}) do
		instance[property] = value
	end

	instance.Parent = parent
	return instance
end

local function frame(parent, name, properties)
	local instance = create("Frame", nil, {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	for property, value in pairs(properties or {}) do
		instance[property] = value
	end

	instance.Parent = parent
	return instance
end

local function round(instance, radius)
	return create("UICorner", instance, { CornerRadius = UDim.new(0, radius) })
end

local function outline(instance, color, thickness)
	return create("UIStroke", instance, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color,
		Thickness = thickness or 1,
	})
end

local function shadow(parent, radius, offset, spread, transparency)
	return create("UIShadow", parent, {
		Name = "Shadow", BlurRadius = UDim.new(0, radius),
		Color = Color3.new(0, 0, 0), Offset = UDim2.fromOffset(0, offset),
		Spread = UDim2.fromOffset(spread, spread), Transparency = transparency,
	})
end

local function connect(window, signal, callback)
	local scope = window.connectionScope
	local connection = signal:Connect(function(...)
		if scope and scope.owner and (scope.owner.isDestroyed or not scope.owner.isEnabled) then return end
		callback(...)
	end)
	window.connections[connection] = true
	if window.connectionScope then table.insert(window.connectionScope, connection) end
	return connection
end

local function animate(window, instance, properties, duration, easingStyle, easingDirection)
	if window.isDestroyed then return nil end
	local previous = window.tweens[instance]
	if previous then
		previous:Cancel()
	end

	local tween = TweenService:Create(instance,
		TweenInfo.new(duration or window.theme.hoverDuration, easingStyle or Enum.EasingStyle.Quad, easingDirection or Enum.EasingDirection.Out),
		properties)

	window.tweens[instance] = tween
	window.targets[instance] = properties
	tween:Play()
	return tween
end

local function dispatch(callback, ...)
	if callback then
		task.spawn(callback, ...)
	end
end

local function label(window, parent, text, properties)
	local instance = create("TextLabel", nil, {
		Name = "Label",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = window.theme.font,
		Text = text,
		TextColor3 = window.theme.text,
		TextSize = window.theme.textSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.fromScale(1, 1),
	})

	for property, value in pairs(properties or {}) do
		instance[property] = value
	end

	instance.Parent = parent
	return instance
end

local function button(window, parent, text, properties)
	local instance = create("TextButton", nil, {
		Name = "Button",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = window.theme.font,
		Text = text,
		TextColor3 = window.theme.text,
		TextSize = window.theme.textSize,
		Size = UDim2.fromScale(1, 1),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	for property, value in pairs(properties or {}) do
		instance[property] = value
	end

	instance.Parent = parent
	return instance
end

local function bindHover(window, target, refresh)
	connect(window, target.MouseEnter, function() refresh(true) end)
	connect(window, target.MouseLeave, function() refresh(false) end)
	connect(window, target.SelectionGained, function() refresh(true) end)
	connect(window, target.SelectionLost, function() refresh(false) end)
end

local function textHover(window, target, border)
	bindHover(window, target, function(isHovered)
		animate(window, target, { TextColor3 = isHovered and window.theme.accent or window.theme.text })
		if border then
			animate(window, border, { Color = isHovered and window.theme.accent or window.theme.outline })
		end
	end)
end

local fallbackIcons = {
	["crosshair"] = { 16898613044, 453, 869 },
	["eye"] = { 16898613353, 771, 563 },
	["compass"] = { 16898613044, 514, 967 },
	["folder-plus"] = { 16898613353, 661, 918 },
	["menu"] = { 16898613613, 49, 820 },
	["chevron-down"] = { 16898612819, 196, 918 },
	["check"] = { 16898612819, 710, 869 },
	["x"] = { 16898613869, 869, 906 },
	["search"] = { 16898613699, 918, 857 },
	["info"] = { 16898613509, 612, 869 },
	["palette"] = { 16898613613, 453, 918 },
	["settings"] = { 16898613777, 771, 257 },
	["bell"] = { 16898612819, 820, 257 },
	["save"] = { 16898613699, 918, 453 },
	["copy"] = { 16898613044, 918, 612 },
	["circle-help"] = { 16898613044, 820, 257 },
	["mouse-pointer"] = { 16898613613, 612, 869 },
	["keyboard"] = { 16898613509, 453, 820 },
	["sliders-horizontal"] = { 16898613777, 820, 355 },
	["user"] = { 16898613869, 661, 869 },
	["sun"] = { 16898613777, 967, 453 },
	["shield"] = { 16898613777, 869, 0 },
	["chevrons-up-down"] = { 16898612819, 918, 759 },
	["grip"] = { 16898613509, 869, 257 },
	["minus"] = { 16898613613, 771, 196 },
}

local iconUrl = "https://github.com/latte-soft/lucide-roblox/releases/download/0.1.3/lucide-roblox.luau"
local cachedIcons
local hasTriedIcons = false

local function fetchText(url)
	local isSuccess, body = pcall(function() return game:HttpGet(url) end)
	if isSuccess and type(body) == "string" then return body end
	return HttpService:GetAsync(url)
end

local function fallbackAsset(name)
	local record = fallbackIcons[name]
	if not record then return nil end
	return {
		Url = "rbxassetid://" .. record[1],
		ImageRectSize = Vector2.new(48, 48),
		ImageRectOffset = Vector2.new(record[2], record[3]),
	}
end

local function resolveIcon(window, name)
	name = name:gsub("^lucide%-", "")
	if name == "folder" then name = "folder-plus" end
	if name:match("^rbxassetid://%d+$") then return { Url = name } end
	if window.icons then
		local isSuccess, asset = pcall(window.icons.GetAsset, name, 48)
		if isSuccess and type(asset) == "table" then return asset end
	end
	return fallbackAsset(name) or fallbackAsset("circle-help")
end

local function createIcon(window, parent, name, size)
	local asset = resolveIcon(window, name)
	return create("ImageLabel", parent, {
		Name = "Icon", BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size), Image = asset.Url,
		ImageRectSize = asset.ImageRectSize or Vector2.new(0, 0),
		ImageRectOffset = asset.ImageRectOffset or Vector2.new(0, 0),
		ImageColor3 = window.theme.text, ScaleType = Enum.ScaleType.Fit,
	})
end

local function refreshTab(tab)
	local window = tab.window
	local isHighlighted = window.targetTab == tab or tab.isHovered
	animate(window, tab.icon, { ImageColor3 = isHighlighted and window.theme.accent or window.theme.text })
end

local function closePopup(window, shouldHideImmediately)
	local view = window.activeDropdown
	if window.closePopup then
		window.closePopup()
		window.closePopup = nil
	end
	if shouldHideImmediately and view and view.shell.Parent then view.shell.Visible = false end
end

local function runTransition(window)
	window.isTransitioning = true
	window.cover.Visible = true

	while not window.isDestroyed and window.targetTab ~= window.activeTab do
		animate(window, window.cover, { BackgroundTransparency = 0 }, window.theme.fadeOutDuration).Completed:Wait()
		if window.isDestroyed then return end

		if window.activeTab then window.activeTab.page.Visible = false end
		window.activeTab = window.targetTab
		window.activeTab.page.Visible = true
		animate(window, window.cover, { BackgroundTransparency = 1 }, window.theme.fadeInDuration).Completed:Wait()
	end

	if window.isDestroyed then return end
	window.cover.Visible = false
	window.isTransitioning = false
end

local function clampWindowPosition(window, left, top)
	local viewport = window.viewport.AbsoluteSize
	local scale = window.scale.Scale
	local height = window.isMinimized and 40 or window.theme.size.Y
	return UDim2.fromOffset(
		math.clamp(left, 0, math.max(0, viewport.X - window.theme.size.X * scale)),
		math.clamp(top, 0, math.max(0, viewport.Y - height * scale)))
end

local function hiddenPosition(window)
	local height = window.isMinimized and 40 or window.theme.size.Y
	return UDim2.fromOffset(window.shownPosition.X.Offset, -height * window.scale.Scale - 48)
end

local function fitWindow(window, shouldCenter)
	local viewport = window.viewport.AbsoluteSize
	if viewport.X < 1 or viewport.Y < 1 then return end
	local size = window.theme.size
	local scale = math.max(0.1, math.min(window.theme.scale, (viewport.X - 24) / size.X, (viewport.Y - 24) / size.Y))
	window.scale.Scale = scale
	local position = window.shownPosition or window.host.Position
	local left = shouldCenter and (viewport.X - size.X * scale) / 2 or position.X.Offset
	local height = window.isMinimized and 40 or size.Y
	local top = shouldCenter and (viewport.Y - height * scale) / 2 or position.Y.Offset
	window.shownPosition = clampWindowPosition(window, left, top)
	if not window.isVisibilityAnimating then
		window.host.Position = window.isVisible and window.shownPosition or hiddenPosition(window)
	end
end

local function finishVisibility(window, revision, isVisible)
	if window.isDestroyed or revision ~= window.visibilityRevision then return end
	window.isVisibilityAnimating = false
	window.host.Visible = isVisible
	window.visibilityCover.Visible = not isVisible
	if isVisible then window.visibilityCover.BackgroundTransparency = 1 end
end

local function animateVisibility(window, revision, isVisible)
	if isVisible then
		local movement = animate(window, window.host, { Position = window.shownPosition }, window.theme.slideDuration, Enum.EasingStyle.Quart)
		animate(window, window.visibilityCover, { BackgroundTransparency = 1 }, window.theme.revealDuration)
		movement.Completed:Wait()
	else
		animate(window, window.visibilityCover, { BackgroundTransparency = 0 }, window.theme.tintDuration).Completed:Wait()
		if window.isDestroyed or revision ~= window.visibilityRevision then return end
		animate(window, window.host, { Position = hiddenPosition(window) }, window.theme.slideDuration,
			Enum.EasingStyle.Cubic, Enum.EasingDirection.In).Completed:Wait()
	end
	finishVisibility(window, revision, isVisible)
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function startPointer(window, input, move)
	if not isPointer(input) then return end
	window.pointer = { input = input, move = move }
end

local function movePointer(window, input)
	local pointer = window.pointer
	if not pointer then return end
	local isMouse = pointer.input.UserInputType == Enum.UserInputType.MouseButton1
	if input == pointer.input or (isMouse and input.UserInputType == Enum.UserInputType.MouseMovement) then
		pointer.move(Vector2.new(input.Position.X, input.Position.Y))
	end
end

local function bindDrag(window, header)
	connect(window, header.InputBegan, function(input)
		if not isPointer(input) or not window.isVisible or window.isVisibilityAnimating then return end
		local origin = Vector2.new(input.Position.X, input.Position.Y)
		local start = window.host.Position
		window.hasDragged = false
		closePopup(window)
		startPointer(window, input, function(position)
			local delta = position - origin
			if delta.Magnitude > 3 then window.hasDragged = true end
			window.shownPosition = clampWindowPosition(window, start.X.Offset + delta.X, start.Y.Offset + delta.Y)
			animate(window, window.host, { Position = window.shownPosition }, window.theme.dragDuration)
		end)
	end)
end

local function containsPoint(instance, position)
	local origin, size = instance.AbsolutePosition, instance.AbsoluteSize
	return position.X >= origin.X and position.Y >= origin.Y
		and position.X <= origin.X + size.X and position.Y <= origin.Y + size.Y
end

local function placeDropdown(window, view)
	if not view.shell.Parent then return end
	local scale = window.scale.Scale
	local origin = view.control.AbsolutePosition
	local viewportOrigin = window.viewport.AbsolutePosition
	local viewport = window.viewport.AbsoluteSize
	local width = view.control.AbsoluteSize.X / scale
	local height = view.listHeight
	local left = math.clamp(origin.X - viewportOrigin.X, 2, math.max(2, viewport.X - width * scale - 2))
	local below = origin.Y - viewportOrigin.Y + view.control.AbsoluteSize.Y + scale
	local top = below
	if below + height * scale > viewport.Y - 2 then top = origin.Y - viewportOrigin.Y - height * scale - scale end
	top = math.clamp(top, 2, math.max(2, viewport.Y - height * scale - 2))
	local hostOrigin = window.host.AbsolutePosition - viewportOrigin
	view.shell.Position = UDim2.fromOffset((left - hostOrigin.X) / scale, (top - hostOrigin.Y) / scale)
	view.shell.Size = UDim2.fromOffset(width, height)
end

local function dropdownAnimation(window, view)
	local revision = 0
	return function(shouldOpen)
		revision = revision + 1
		local currentRevision = revision
		if not view.shell.Parent then return end
		if shouldOpen then
			placeDropdown(window, view)
			view.shell.Visible = true
			window.activeDropdown = view
			window.popupOrder = (window.popupOrder or 0) + 1
			view.shell.ZIndex = window.popupOrder
		elseif window.activeDropdown == view then
			window.activeDropdown = nil
		end
		view.scroll.Active = shouldOpen
		view.scroll.ScrollingEnabled = shouldOpen
		view.blocker.Visible = not shouldOpen
		animate(window, view.arrow, { Rotation = shouldOpen and 180 or 0 })
		local tween = animate(window, view.list, { GroupTransparency = shouldOpen and 0 or 1 }, window.theme.popupDuration)
		task.spawn(function()
			tween.Completed:Wait()
			if not window.isDestroyed and revision == currentRevision and view.shell.Parent then view.shell.Visible = shouldOpen end
		end)
	end
end

local function bindDropdownPosition(window, view)
	local function refresh()
		if window.activeDropdown == view then placeDropdown(window, view) end
	end
	connect(window, view.control:GetPropertyChangedSignal("AbsolutePosition"), refresh)
	connect(window, view.control:GetPropertyChangedSignal("AbsoluteSize"), refresh)
	connect(window, window.viewport:GetPropertyChangedSignal("AbsoluteSize"), refresh)
	connect(window, window.host:GetPropertyChangedSignal("AbsolutePosition"), refresh)
end

local function bindInput(window)
	connect(window, UserInputService.InputChanged, function(input) movePointer(window, input) end)
	connect(window, UserInputService.InputEnded, function(input)
		if window.pointer and window.pointer.input == input then window.pointer = nil end
	end)
	connect(window, UserInputService.WindowFocusReleased, function() window.pointer = nil end)
	connect(window, UserInputService.InputBegan, function(input, isProcessed)
		if isPointer(input) and window.activeDropdown then
			local position = Vector2.new(input.Position.X, input.Position.Y)
			local view = window.activeDropdown
			if not containsPoint(view.shell, position) and not containsPoint(view.control, position) then closePopup(window) end
		end
		if UserInputService:GetFocusedTextBox() then return end
		if window.captureKey then
			window.captureKey(input)
			return
		end
		if isProcessed then return end
		if input.KeyCode == window.theme.toggleKey then
			window:setVisible(not window.isVisible)
			return
		end
		for _, binding in ipairs(window.keybinds) do
			if binding.key == input.KeyCode and not binding.isDisabled then dispatch(binding.callback, binding.key) end
		end
	end)
end

local function updateClock(window)
	if window.isDestroyed then return end
	window.clock.Text = os.date("%I:%M %p\n%m/%d/%Y")
	window.clockTask = task.delay(60 - tonumber(os.date("%S")), updateClock, window)
end

local function buildHeader(window, options)
	local header = frame(window.root, "Header", { Size = UDim2.new(1, 0, 0, 40), Active = true })
	local title = button(window, header, "", {
		Name = "Title", TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(8, -1), Size = UDim2.fromOffset(300, 38),
		Font = Enum.Font.SourceSans, TextSize = 32, TextTruncate = Enum.TextTruncate.None,
	})
	window.titlePrefix = options.titlePrefix or "UNDER"
	window.titleAccent = options.titleAccent or "LORD"
	window.title = title
	window.titleVersion = options.version or "v3.1.5"
	window.navigation = create("ScrollingFrame", header, {
		Name = "Navigation", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 7), Size = UDim2.fromOffset(160, 27),
	})
	create("UIListLayout", window.navigation, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) })
	window.clock = label(window, header, "", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 2),
		Size = UDim2.fromOffset(110, 35), Font = Enum.Font.SourceSans, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local divider = frame(header, "Divider", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(215, 215, 215) })
	create("UIGradient", divider, {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 65, 70)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(220, 220, 220)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 50)) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.35, 0.12), NumberSequenceKeypoint.new(1, 0.65) }),
	})
	bindDrag(window, header)
	bindDrag(window, title)
	local lastClick = -math.huge
	connect(window, title.Activated, function()
		if window.hasDragged then lastClick = -math.huge; return end
		local now = os.clock()
		if now - lastClick <= 0.28 then window:setMinimized(not window.isMinimized) end
		lastClick = now
	end)
	updateClock(window)
end

local function buildWindow(window, parent, options)
	local previous = parent:FindFirstChild(options.name or "Underlord")
	if previous and previous:GetAttribute("UnderlordManaged") then previous:Destroy() end
	window.gui = create("ScreenGui", parent, {
		Name = options.name or "Underlord", ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = options.displayOrder or 50,
		IgnoreGuiInset = true,
	})
	window.gui:SetAttribute("UnderlordManaged", true)
	window.viewport = frame(window.gui, "Viewport", { Size = UDim2.fromScale(1, 1) })
	window.host = frame(window.viewport, "WindowHost", {
		Size = UDim2.fromOffset(window.theme.size.X, window.theme.size.Y), ZIndex = 10,
	})
	window.scale = create("UIScale", window.host, { Scale = window.theme.scale })
	shadow(window.host, 22, 7, 3, 0.25)
	window.root = create("CanvasGroup", window.host, {
		Name = "Window", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = window.theme.background, GroupTransparency = 0,
	})
	window.popupLayer = frame(window.host, "PopupLayer", { Size = UDim2.fromScale(1, 1), ZIndex = 300 })
	window.visibilityCover = button(window, window.root, "", {
		Name = "VisibilityCover", BackgroundTransparency = 1, BackgroundColor3 = window.theme.accent,
		Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 500, Selectable = false,
	})
	outline(window.root, Color3.fromRGB(28, 28, 30))
	buildHeader(window, options)
	window.body = frame(window.root, "Body", {
		Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), ClipsDescendants = true,
	})
	window.cover = button(window, window.body, "", {
		Name = "Transition", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		Visible = false, ZIndex = 100, Active = true, Selectable = false,
	})
end

local function createRow(section, height)
	section.rowCount = section.rowCount + 1
	local row = create("CanvasGroup", section.content, {
		Name = "Control", BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, -2, 0, height or 20), LayoutOrder = section.rowCount,
	})
	section.pendingRow = row
	return row
end

local function createField(window, parent, width, text)
	local field = create("TextBox", parent, {
		Name = "Input", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -1, 0.5, 0),
		Size = UDim2.fromOffset(width, 19), BackgroundTransparency = 1, BorderSizePixel = 0,
		Font = window.theme.font, TextColor3 = window.theme.text, TextSize = window.theme.textSize,
		Text = text, ClearTextOnFocus = false,
	})
	round(field, 2)
	local border = outline(field, window.theme.outline)
	connect(window, field.Focused, function() animate(window, border, { Color = window.theme.accent }) end)
	connect(window, field.FocusLost, function() animate(window, border, { Color = window.theme.outline }) end)
	return field
end

local function createSliderView(section, options)
	local window = section.window
	local row = createRow(section)
	local fieldWidth = options.valueWidth or ((options.step or 1) < 1 and 44 or 28)
	label(window, row, options.name or "Slider", { Size = UDim2.new(0.46, -4, 1, 0) })
	local hitbox = button(window, row, "", {
		Name = "Slider", Position = UDim2.new(0.46, 2, 0, 0), Size = UDim2.new(0.54, -fieldWidth - 17, 1, 0),
	})
	frame(hitbox, "Track", { Position = UDim2.new(0, 0, 0.5, -2), Size = UDim2.new(1, 0, 0, 4),
		BackgroundTransparency = 0, BackgroundColor3 = window.theme.outline })
	local fill = frame(hitbox, "Fill", { Position = UDim2.new(0, 0, 0.5, -2),
		Size = UDim2.fromOffset(0, 4), BackgroundTransparency = 0, BackgroundColor3 = window.theme.accent })
	local knob = frame(hitbox, "Knob", { AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(13, 13),
		BackgroundTransparency = 0, BackgroundColor3 = window.theme.accent })
	round(knob, 100)
	return hitbox, knob, createField(window, row, fieldWidth, "0"), fill
end

local function createToggleView(section, options)
	local window = section.window
	local row = createRow(section)
	local control = button(window, row, "", { Name = "Toggle" })
	local caption = label(window, control, options.name or "Toggle", { Size = UDim2.new(1, -26, 1, 0) })
	local box = frame(control, "Checkbox", { AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -1, 0.5, 0), Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = window.theme.accent })
	round(box, 4)
	local border = outline(box, window.theme.outline)
	local check = label(window, box, "✓", { Font = Enum.Font.SourceSansBold, TextSize = 19,
		TextColor3 = Color3.fromRGB(40, 19, 23), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1 })
	return control, caption, box, border, check
end

local function createKeybindView(section, options)
	local window = section.window
	local row = createRow(section)
	local width = options.width or 84
	label(window, row, options.name or "Keybind", { Size = UDim2.new(1, -width - 6, 1, 0) })
	local control = button(window, row, "", { Name = "Keybind", AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -1, 0.5, 0), Size = UDim2.fromOffset(width, 19) })
	round(control, 2)
	local border = outline(control, window.theme.outline)
	textHover(window, control, border)
	return control, border
end

local function schedule(window, delaySeconds, callback)
	local thread
	thread = task.delay(delaySeconds, function()
		window.tasks[thread] = nil
		if not window.isDestroyed then callback() end
	end)
	window.tasks[thread] = true
	return thread
end

local function releaseConnections(window, connections)
	for _, connection in ipairs(connections) do
		connection:Disconnect()
		window.connections[connection] = nil
	end
	local owner = connections.owner
	table.clear(connections)
	connections.owner = owner
end

local function escapeRichText(text)
	return tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function refreshTitle(window)
	local accent = window.theme.accent
	window.title.Text = string.format('%s<font color="rgb(%d,%d,%d)">%s</font><font size="11" color="#888888">%s</font>',
		escapeRichText(window.titlePrefix), math.round(accent.R * 255), math.round(accent.G * 255),
		math.round(accent.B * 255), escapeRichText(window.titleAccent), escapeRichText(window.titleVersion))
end

local function addTooltip(window, target, text)
	local tooltip
	local revision = 0
	local function hide()
		revision = revision + 1
		if tooltip then tooltip:Destroy(); tooltip = nil end
	end
	bindHover(window, target, function(isHovered)
		hide()
		if not isHovered then return end
		local currentRevision = revision
		schedule(window, 0.35, function()
			if revision ~= currentRevision or not target.Parent or not window.isVisible then return end
			tooltip = label(window, window.viewport, text, {
				Name = "Tooltip", BackgroundTransparency = 0, BackgroundColor3 = window.theme.panel,
				Size = UDim2.fromOffset(240, 40), TextWrapped = true, TextSize = 12, ZIndex = 300,
				TextXAlignment = Enum.TextXAlignment.Center, BorderSizePixel = 0,
			})
			local position = target.AbsolutePosition - window.viewport.AbsolutePosition
			tooltip.Position = UDim2.fromOffset(math.clamp(position.X, 0, math.max(0, window.viewport.AbsoluteSize.X - 240)),
				math.clamp(position.Y + target.AbsoluteSize.Y + 5, 0, math.max(0, window.viewport.AbsoluteSize.Y - 40)))
			outline(tooltip, window.theme.outline)
		end)
	end)
	connect(window, target.Destroying, hide)
	return hide
end

local function attachControl(section, handle, options, kind, connections)
	local window = section.window
	local row = handle.instance.Parent
	handle.kind, handle.row = kind, row
	handle.isEnabled, handle.isDestroyed = true, false
	handle.options = options
	handle.connections = connections
	if handle.get then handle.default = handle:get() end
	handle.blocker = button(window, row, "", { Name = "Disabled", Visible = false, ZIndex = 90, Selectable = false })
	if options.tooltip then handle.hideTooltip = addTooltip(window, handle.instance, options.tooltip) end
	function handle:setVisible(isVisible)
		if self.isDestroyed then return end
		self.row.Visible = isVisible == true
		if self.hideTooltip then self.hideTooltip() end
		if not isVisible and self.close then self.close() end
	end
	function handle:setEnabled(isEnabled)
		if self.isDestroyed then return end
		self.isEnabled = isEnabled == true
		self.blocker.Visible = not self.isEnabled
		if not self.isEnabled and self.close then self.close() end
		if self.binding then self.binding.isDisabled = not self.isEnabled end
		if not self.isEnabled and window.captureOwner == self.instance and window.cancelKeyCapture then window.cancelKeyCapture() end
		animate(window, row, { GroupTransparency = self.isEnabled and 0 or 0.55 })
	end
	function handle:reset(shouldNotify)
		if self.set and self.default ~= nil then self:set(self.default, shouldNotify) end
	end
	table.insert(window.controls, handle)
	if options.id then
		assert(not window.flags[options.id], "Identifiant de contrôle déjà utilisé : " .. options.id)
		window.flags[options.id] = handle
	end
	return handle
end

local function destroyControl(window, handle)
	if handle.isDestroyed then return end
	if window.captureOwner == handle.instance and window.cancelKeyCapture then window.cancelKeyCapture() end
	if handle.cleanup then handle.cleanup() end
	if window.closePopup == handle.close then window.closePopup = nil end
	handle.isDestroyed = true
	if handle.hideTooltip then handle.hideTooltip() end
	if handle.binding then
		local index = table.find(window.keybinds, handle.binding)
		if index then table.remove(window.keybinds, index) end
	end
	releaseConnections(window, handle.connections)
	for instance, tween in pairs(window.tweens) do
		if instance == handle.row or instance:IsDescendantOf(handle.row) then
			tween:Cancel()
			window.tweens[instance] = nil
		end
	end
	if handle.options.id then window.flags[handle.options.id] = nil end
	local index = table.find(window.controls, handle)
	if index then table.remove(window.controls, index) end
	handle.row:Destroy()
end

local function registerControl(method, kind)
	local constructor = Section[method]
	Section[method] = function(section, options)
		options = options or {}
		local window = section.window
		assert(not window.isDestroyed, "La fenêtre a été détruite.")
		assert(not options.id or not window.flags[options.id], "Identifiant de contrôle déjà utilisé.")
		local connections = {}
		section.pendingRow = nil
		window.connectionScope = connections
		local isSuccess, handle = pcall(constructor, section, options)
		if isSuccess then handle = attachControl(section, handle, options, kind, connections) end
		window.connectionScope = nil
		if not isSuccess then
			releaseConnections(window, connections)
			if section.pendingRow then section.pendingRow:Destroy() end
			section.pendingRow = nil
			error(handle, 2)
		end
		section.pendingRow = nil
		connections.owner = handle
		function handle:destroy() destroyControl(window, self) end
		if options.isEnabled == false then handle:setEnabled(false) end
		if options.isVisible == false then handle:setVisible(false) end
		return handle
	end
end

local function encodeSetting(setting)
	if typeof(setting) == "Color3" then return { kind = "color", hex = setting:ToHex() } end
	if typeof(setting) == "EnumItem" then return { kind = "key", name = setting.Name } end
	if type(setting) == "table" then return table.clone(setting) end
	return setting
end

local function decodeSetting(handle, setting)
	local kind = handle.kind
	if kind == "color" then
		assert(type(setting) == "table" and setting.kind == "color" and type(setting.hex) == "string", "Couleur invalide.")
		assert(setting.hex:match("^%x%x%x%x%x%x$"), "Couleur hexadécimale invalide.")
		return Color3.fromHex(setting.hex)
	end
	if kind == "keybind" then
		assert(type(setting) == "table" and setting.kind == "key", "Raccourci invalide.")
		return Enum.KeyCode[setting.name]
	end
	if kind == "toggle" then assert(type(setting) == "boolean", "Booléen attendu.") end
	if kind == "slider" then
		assert(type(setting) == "number" and setting == setting and math.abs(setting) < math.huge, "Nombre fini attendu.")
	end
	if kind == "input" then
		assert(type(setting) == "string", "Texte attendu.")
		assert(not handle.options.validate or handle.options.validate(setting), "Texte refusé.")
	end
	if kind == "dropdown" then assert(handle:accepts(setting), "Sélection invalide.") end
	return setting
end

local function createDropdownPanel(section, options)
	local window = section.window
	local row = createRow(section, 44)
	label(window, row, options.name or "Dropdown", { Size = UDim2.new(1, 0, 0, 19) })
	local control = button(window, row, "", { Name = "Dropdown", Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, 0, 0, 19) })
	outline(control, window.theme.outline)
	local caption = label(window, control, "", { Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -26, 1, 0), TextXAlignment = Enum.TextXAlignment.Center })
	local arrow = createIcon(window, control, "chevron-down", 14)
	arrow.Position = UDim2.new(1, -18, 0.5, -7)
	local shell = frame(window.popupLayer, "DropdownPopup", { Size = UDim2.fromOffset(230, 162), Visible = false })
	shadow(shell, 8, 3, 1, 0.25)
	outline(shell, window.theme.outline)
	local list = create("CanvasGroup", shell, { Name = "Choices", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = window.theme.panel, BorderSizePixel = 0, GroupTransparency = 1 })
	local search = createField(window, list, 180, "")
	search.Name, search.PlaceholderText = "Search", "Search..."
	search.AnchorPoint, search.Position, search.Size = Vector2.new(0, 0), UDim2.fromOffset(2, 2), UDim2.new(1, -4, 0, 20)
	search.Visible = options.searchable == true
	local top = search.Visible and 25 or 0
	local scroll = create("ScrollingFrame", list, { Name = "Options", Position = UDim2.fromOffset(1, top), Size = UDim2.new(1, -2, 1, -top - 1),
		BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 1, ScrollBarImageColor3 = window.theme.outline, ScrollingDirection = Enum.ScrollingDirection.Y })
	create("UIListLayout", scroll, { SortOrder = Enum.SortOrder.LayoutOrder })
	local blocker = button(window, list, "", { Name = "ClosingBlocker", ZIndex = 100, Visible = true, Selectable = false })
	return { row = row, control = control, caption = caption, arrow = arrow, shell = shell, list = list, scroll = scroll,
		search = search, blocker = blocker, listHeight = 162, top = top, maxVisible = math.max(1, options.maxVisible or 8), entries = {}, connections = {} }
end

local function validateChoices(choices)
	assert(type(choices) == "table", "Liste d'options attendue.")
	local seen = {}
	for _, choice in ipairs(choices) do
		assert(type(choice) == "string" and not seen[choice], "Les options doivent être des chaînes uniques.")
		seen[choice] = true
	end
	return table.clone(choices)
end

local function refreshChoice(window, entry)
	local isHighlighted = entry.isHovered or entry.isSelected
	animate(window, entry.button, { TextColor3 = isHighlighted and window.theme.accent or window.theme.text })
	animate(window, entry.mark, { ImageTransparency = entry.isMulti and entry.isSelected and 0 or 1 })
end

local function refreshDropdown(window, view, selected, isMulti)
	view.caption.Text = isMulti and (#selected > 0 and table.concat(selected, ", ") or "None") or (selected or "None")
	local query = string.lower(view.search.Text)
	local visibleCount = 0
	for _, entry in ipairs(view.entries) do
		entry.isMulti = isMulti
		entry.isSelected = isMulti and table.find(selected, entry.name) ~= nil or selected == entry.name
		entry.button.Visible = query == "" or string.find(string.lower(entry.name), query, 1, true) ~= nil
		if entry.button.Visible then visibleCount = visibleCount + 1 end
		refreshChoice(window, entry)
	end
	view.listHeight = math.min(math.max(visibleCount, 1), view.maxVisible) * 20 + view.top + 1
	if window.activeDropdown == view then placeDropdown(window, view) end
end

local function rebuildChoices(window, view, choices, onSelect)
	releaseConnections(window, view.connections)
	for _, entry in ipairs(view.entries) do entry.button:Destroy() end
	table.clear(view.entries)
	local previousScope = window.connectionScope
	window.connectionScope = view.connections
	for index, choice in ipairs(choices) do
		local entry = { name = choice, isHovered = false, isSelected = false }
		entry.button = button(window, view.scroll, choice, { Name = "Choice", Size = UDim2.new(1, 0, 0, 20), LayoutOrder = index })
		frame(entry.button, "Divider", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
			BackgroundTransparency = 0.25, BackgroundColor3 = window.theme.outline })
		entry.mark = createIcon(window, entry.button, "check", 12)
		entry.mark.Position, entry.mark.ImageColor3 = UDim2.new(1, -16, 0.5, -6), window.theme.accent
		bindHover(window, entry.button, function(isHovered) entry.isHovered = isHovered; refreshChoice(window, entry) end)
		connect(window, entry.button.Activated, function() onSelect(choice) end)
		table.insert(view.entries, entry)
	end
	window.connectionScope = previousScope
end

local function createColorPanel(section, options)
	local window = section.window
	local row = createRow(section, 20)
	local control = button(window, row, "", { Name = "Color", Size = UDim2.new(1, 0, 0, 20) })
	label(window, control, options.name or "Color", { Size = UDim2.new(1, -34, 1, 0) })
	local swatch = frame(control, "Swatch", { Position = UDim2.new(1, -29, 0, 2), Size = UDim2.fromOffset(28, 16), BackgroundTransparency = 0 })
	round(swatch, 2)
	outline(swatch, window.theme.outline)
	local panel = create("CanvasGroup", row, { Name = "Picker", Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 142), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
	local saturation = button(window, panel, "", { Name = "Saturation", Size = UDim2.new(1, -24, 0, 110), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1) })
	create("UIGradient", saturation, { Color = ColorSequence.new(Color3.new(1, 1, 1)), Transparency = NumberSequence.new(0, 1) })
	local hueBase = frame(panel, "HueBase", { Size = saturation.Size, BackgroundTransparency = 0, ZIndex = 0 })
	saturation.ZIndex = 1
	local shade = frame(saturation, "Value", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0 })
	create("UIGradient", shade, { Rotation = 90, Transparency = NumberSequence.new(1, 0) })
	local marker = frame(saturation, "Cursor", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6), ZIndex = 3 })
	round(marker, 99)
	outline(marker, Color3.new(1, 1, 1))
	local hue = button(window, panel, "", { Name = "Hue", Position = UDim2.new(1, -16, 0, 0), Size = UDim2.fromOffset(14, 110), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1) })
	local stops = {}
	for index = 0, 6 do table.insert(stops, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6, 1, 1))) end
	create("UIGradient", hue, { Rotation = 90, Color = ColorSequence.new(stops) })
	local hueMarker = frame(hue, "Cursor", { Size = UDim2.new(1, 4, 0, 2), Position = UDim2.fromOffset(-2, 0), BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1) })
	local hex = createField(window, panel, 90, "")
	hex.Position = UDim2.new(1, -1, 0, 129)
	return { row = row, control = control, swatch = swatch, panel = panel, saturation = saturation, hueBase = hueBase, marker = marker, hue = hue, hueMarker = hueMarker, hex = hex }
end

local function refreshColor(window, view, color)
	local hue, saturation, brightness = color:ToHSV()
	if saturation > 0 and brightness > 0 then view.selectedHue = hue end
	hue = view.selectedHue or hue
	view.hex.Text = "#" .. color:ToHex()
	view.hueBase.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
	view.marker.Position = UDim2.fromScale(saturation, 1 - brightness)
	view.hueMarker.Position = UDim2.new(0, -2, hue, -1)
	animate(window, view.swatch, { BackgroundColor3 = color })
end

local function bindColorPointer(window, view, handle)
	local function bind(target, isHue)
		connect(window, target.InputBegan, function(input)
			if not isPointer(input) then return end
			local function update(position)
				local relative = position - target.AbsolutePosition
				local hue, saturation, brightness = handle:get():ToHSV()
				hue = view.selectedHue or hue
				if isHue then
					hue = math.clamp(relative.Y / math.max(1, target.AbsoluteSize.Y), 0, 0.9999)
					view.selectedHue = hue
				else
					saturation = math.clamp(relative.X / math.max(1, target.AbsoluteSize.X), 0, 1)
					brightness = 1 - math.clamp(relative.Y / math.max(1, target.AbsoluteSize.Y), 0, 1)
				end
				handle:set(Color3.fromHSV(hue, saturation, brightness))
			end
			startPointer(window, input, update)
			update(Vector2.new(input.Position.X, input.Position.Y))
		end)
	end
	bind(view.hue, true)
	bind(view.saturation, false)
end

Underlord.new = function(options)
	options = options or {}
	local player = Players.LocalPlayer
	assert(player, "Underlord nécessite un contexte client Roblox.")
	local parent = options.parent or player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
	assert(parent, "PlayerGui introuvable.")
	local theme = table.clone(defaults)
	for key, value in pairs(options.theme or {}) do theme[key] = value end
	local window = setmetatable({ theme = theme, connections = {}, tweens = setmetatable({}, { __mode = "k" }), targets = setmetatable({}, { __mode = "k" }), tabs = {}, keybinds = {},
		controls = {}, flags = {}, tasks = {}, notifications = {},
		isVisible = true, isDestroyed = false, isTransitioning = false, visibilityRevision = 0 }, Window)
	window.storage = options.storage
	window.icons = options.icons or Underlord.loadIcons(options.httpGet)
	buildWindow(window, parent, options)
	refreshTitle(window)
	bindInput(window)
	if options.showToggleButton or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then window:createToggleButton() end
	fitWindow(window, true)
	connect(window, window.viewport:GetPropertyChangedSignal("AbsoluteSize"), function() fitWindow(window, false) end)
	connect(window, window.gui.Destroying, function() window:destroy() end)
	return window
end

Window.setVisible = function(self, isVisible)
	isVisible = isVisible == true
	if self.isDestroyed or self.isVisible == isVisible then return end
	if not self.isVisibilityAnimating and self.isVisible then self.shownPosition = self.host.Position end
	self.isVisible = isVisible
	self.visibilityRevision = self.visibilityRevision + 1
	self.isVisibilityAnimating = true
	self.pointer = nil
	closePopup(self, true)
	if self.cancelKeyCapture then self.cancelKeyCapture() end
	local movement = self.tweens[self.host]
	if movement then movement:Cancel() end
	self.host.Visible = true
	self.popupLayer.Visible = isVisible
	self.visibilityCover.Visible = true
	self.visibilityCover.BackgroundColor3 = self.theme.accent
	task.spawn(animateVisibility, self, self.visibilityRevision, isVisible)
end

Window.selectTab = function(self, tab)
	if self.isDestroyed or tab.window ~= self or self.targetTab == tab then return end
	closePopup(self, true)
	if self.cancelKeyCapture then self.cancelKeyCapture() end
	self.pointer = nil
	self.targetTab = tab
	for _, entry in ipairs(self.tabs) do refreshTab(entry) end
	if not self.activeTab then
		self.activeTab = tab
		tab.page.Visible = true
		return
	end
	if not self.isTransitioning then task.spawn(runTransition, self) end
end

Window.createTab = function(self, options)
	options = options or {}
	local index = #self.tabs + 1
	local tab = setmetatable({ window = self, sections = {}, isHovered = false }, Tab)
	tab.button = button(self, self.navigation, "", {
		Name = options.name or "Tab", Size = UDim2.fromOffset(26, 26), LayoutOrder = index,
	})
	tab.icon = createIcon(self, tab.button, options.icon or "menu", 26)
	tab.page = create("ScrollingFrame", self.body, {
		Name = options.name or "Page", BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), Visible = false, ScrollBarThickness = 2,
		ScrollBarImageColor3 = self.theme.muted, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})
	create("UIPadding", tab.page, { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) })
	create("UIGridLayout", tab.page, { CellSize = UDim2.new(1 / 3, -18, 0, options.sectionHeight or 190),
		CellPadding = UDim2.fromOffset(26, 24), FillDirectionMaxCells = 3, SortOrder = Enum.SortOrder.LayoutOrder })
	table.insert(self.tabs, tab)
	refreshTab(tab)
	bindHover(self, tab.button, function(isHovered) tab.isHovered = isHovered; refreshTab(tab) end)
	connect(self, tab.button.Activated, function() self:selectTab(tab) end)
	if index == 1 then self:selectTab(tab) end
	return tab
end

Window.destroy = function(self)
	if self.isDestroyed then return end
	self.isDestroyed = true
	self.pointer = nil
	if self.clockTask then task.cancel(self.clockTask) end
	for connection in pairs(self.connections) do connection:Disconnect() end
	for thread in pairs(self.tasks) do task.cancel(thread) end
	for _, tween in pairs(self.tweens) do tween:Cancel() end
	table.clear(self.connections)
	table.clear(self.tweens)
	table.clear(self.keybinds)
	table.clear(self.tasks)
	table.clear(self.targets)
	table.clear(self.controls)
	table.clear(self.flags)
	self.gui:Destroy()
end

Tab.createSection = function(self, name)
	local window = self.window
	local section = setmetatable({ window = window, rowCount = 0 }, Section)
	section.frame = frame(self.page, "Section", { BackgroundTransparency = 0,
		BackgroundColor3 = window.theme.panel, LayoutOrder = #self.sections + 1 })
	shadow(section.frame, 11, 4, 2, 0.30)
	outline(section.frame, Color3.fromRGB(12, 12, 13))
	label(window, section.frame, name, { Name = "Title", Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 23), TextSize = #name > 24 and 13 or 16 })
	section.content = create("ScrollingFrame", section.frame, {
		Name = "Controls", Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 1, -30),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 1,
		ScrollBarImageColor3 = window.theme.muted, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	})
	create("UIPadding", section.content, { PaddingLeft = UDim.new(0, 1), PaddingTop = UDim.new(0, 1),
		PaddingBottom = UDim.new(0, 2), PaddingRight = UDim.new(0, 1) })
	create("UIListLayout", section.content, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
	table.insert(self.sections, section)
	return section
end

Section.addButton = function(self, options)
	local window = self.window
	local row = createRow(self, 19)
	local control = button(window, row, options.name or "Button", { Name = "Action" })
	round(control, 2)
	outline(control, window.theme.outline)
	textHover(window, control)
	local lastActivation = -math.huge
	connect(window, control.Activated, function()
		local now = os.clock()
		if now - lastActivation < (options.debounce or 0.15) then return end
		lastActivation = now
		dispatch(options.callback)
	end)
	return { instance = control, setText = function(_, text) control.Text = text end }
end

Section.addToggle = function(self, options)
	local window = self.window
	local control, caption, box, border, check = createToggleView(self, options)
	local isEnabled, isHovered = options.default == true, false
	local function refresh()
		animate(window, border, { Color = (isEnabled or isHovered) and window.theme.accent or window.theme.outline })
		animate(window, box, { BackgroundTransparency = isEnabled and 0 or 1 })
		animate(window, check, { TextTransparency = isEnabled and 0 or 1 })
	end
	local handle = { instance = control }
	function handle:set(nextState, shouldNotify)
		nextState = nextState == true
		if nextState == isEnabled then return end
		isEnabled = nextState
		refresh()
		if shouldNotify ~= false then dispatch(options.callback, isEnabled) end
	end
	function handle:get() return isEnabled end
	bindHover(window, control, function(hovered) isHovered = hovered; refresh() end)
	connect(window, control.Activated, function() handle:set(not isEnabled) end)
	refresh()
	return handle
end

Section.addSlider = function(self, options)
	local window = self.window
	local minimum, maximum, step = options.min or 0, options.max or 100, options.step or 1
	assert(maximum > minimum and step > 0, "Bornes du slider invalides.")
	local hitbox, knob, field, fill = createSliderView(self, options)
	local current = math.clamp(options.default or minimum, minimum, maximum)
	local handle = { instance = hitbox }
	function handle:set(number, shouldNotify)
		if type(number) ~= "number" or number ~= number then return end
		number = math.clamp(minimum + math.round((number - minimum) / step) * step, minimum, maximum)
		local hasChanged = number ~= current
		current = number
		field.Text = string.format("%.4g", current)
		local ratio = (current - minimum) / (maximum - minimum)
		knob.Position = UDim2.fromScale(ratio, 0.5)
		fill.Size = UDim2.new(ratio, 0, 0, 4)
		if hasChanged and shouldNotify ~= false then dispatch(options.callback, current) end
	end
	function handle:get() return current end
	local function updateFromPointer(position)
		local ratio = math.clamp((position.X - hitbox.AbsolutePosition.X) / math.max(1, hitbox.AbsoluteSize.X), 0, 1)
		handle:set(minimum + ratio * (maximum - minimum))
	end
	connect(window, hitbox.InputBegan, function(input)
		if not isPointer(input) then return end
		startPointer(window, input, updateFromPointer)
		updateFromPointer(Vector2.new(input.Position.X, input.Position.Y))
	end)
	connect(window, hitbox.InputBegan, function(input)
		if input.KeyCode == Enum.KeyCode.Left then handle:set(current - step) end
		if input.KeyCode == Enum.KeyCode.Right then handle:set(current + step) end
	end)
	connect(window, field.FocusLost, function() handle:set(tonumber(field.Text) or current) end)
	handle:set(current, false)
	return handle
end

Section.addKeybind = function(self, options)
	local window = self.window
	local control, border = createKeybindView(self, options)
	local binding = { key = options.default or Enum.KeyCode.Unknown, callback = options.callback }
	table.insert(window.keybinds, binding)
	local handle = { instance = control, binding = binding }
	function handle:set(key, shouldNotify)
		assert(typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode, "KeyCode attendu.")
		local hasChanged = binding.key ~= key
		binding.key = key
		if hasChanged and shouldNotify ~= false then dispatch(options.onChanged, key) end
		control.Text = key == Enum.KeyCode.Unknown and "None" or key.Name
	end
	function handle:get() return binding.key end
	local function cancelCapture()
		window.captureKey, window.cancelKeyCapture, window.captureOwner = nil, nil, nil
		handle:set(binding.key)
		animate(window, border, { Color = window.theme.outline })
	end
	connect(window, control.Activated, function()
		if window.cancelKeyCapture then window.cancelKeyCapture() end
		control.Text = "..."
		animate(window, border, { Color = window.theme.accent })
		window.cancelKeyCapture = cancelCapture
		window.captureOwner = control
		window.captureKey = function(input)
			if input.KeyCode == Enum.KeyCode.Unknown then return end
			if input.KeyCode ~= Enum.KeyCode.Escape then
				handle:set(input.KeyCode == Enum.KeyCode.Backspace and Enum.KeyCode.Unknown or input.KeyCode)
			end
			cancelCapture()
		end
	end)
	handle:set(binding.key)
	return handle
end

Section.addDropdown = function(self, options)
	local window = self.window
	local choices = validateChoices(options.options or { "None" })
	local view = createDropdownPanel(self, options)
	local isMulti = options.isMulti == true
	local selected = isMulti and {} or (choices[1] or "")
	local isOpen = false
	local animateOpen = dropdownAnimation(window, view)
	local handle = { instance = view.control }
	view.connections.owner = handle
	function handle:get() return isMulti and table.clone(selected) or selected end
	function handle:accepts(selection)
		if not isMulti then return type(selection) == "string" and (table.find(choices, selection) ~= nil or (#choices == 0 and selection == "")) end
		if type(selection) ~= "table" then return false end
		for key in pairs(selection) do
			if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #selection then return false end
		end
		local seen = {}
		for _, choice in ipairs(selection) do
			if not table.find(choices, choice) or seen[choice] then return false end
			seen[choice] = true
		end
		return true
	end
	function handle:set(selection, shouldNotify)
		if not self:accepts(selection) then return false end
		local nextSelection = isMulti and table.clone(selection) or selection
		local hasChanged = isMulti and table.concat(selected, "\0") ~= table.concat(nextSelection, "\0") or (not isMulti and selected ~= nextSelection)
		selected = nextSelection
		refreshDropdown(window, view, selected, isMulti)
		if hasChanged and shouldNotify ~= false then dispatch(options.callback, self:get()) end
		return true
	end
	local function setOpen(shouldOpen)
		isOpen = shouldOpen
		animateOpen(shouldOpen)
		if not shouldOpen then view.search:ReleaseFocus() end
	end
	handle.close = function() setOpen(false) end
	local function selectChoice(choice)
		if isMulti then
			local selection = handle:get()
			local index = table.find(selection, choice)
			if index then table.remove(selection, index) else table.insert(selection, choice) end
			handle:set(selection)
		else
			handle:set(choice)
			closePopup(window)
		end
	end
	function handle:setOptions(nextChoices, shouldNotify)
		choices = validateChoices(nextChoices)
		rebuildChoices(window, view, choices, selectChoice)
		local nextSelection = selected
		if isMulti then
			nextSelection = {}
			for _, choice in ipairs(selected) do if table.find(choices, choice) then table.insert(nextSelection, choice) end end
		elseif not table.find(choices, selected) then nextSelection = choices[1] or "" end
		self:set(nextSelection, shouldNotify)
	end
	connect(window, view.control.Activated, function()
		local shouldOpen = not isOpen
		closePopup(window)
		if shouldOpen then window.closePopup = handle.close; setOpen(true) end
	end)
	connect(window, view.search:GetPropertyChangedSignal("Text"), function() refreshDropdown(window, view, selected, isMulti) end)
	local function cleanup()
		if window.activeDropdown == view then window.activeDropdown = nil end
		if window.closePopup == handle.close then window.closePopup = nil end
		releaseConnections(window, view.connections)
		local tween = window.tweens[view.list]
		if tween then tween:Cancel(); window.tweens[view.list] = nil end
		view.shell:Destroy()
	end
	connect(window, view.control.Destroying, cleanup)
	bindDropdownPosition(window, view)
	bindHover(window, view.control, function(isHovered)
		animate(window, view.caption, { TextColor3 = isHovered and window.theme.accent or window.theme.text })
	end)
	handle.cleanup = cleanup
	handle:setOptions(choices, false)
	if options.default ~= nil then assert(handle:set(options.default, false), "Sélection par défaut invalide.") end
	return handle
end

Section.addInput = function(self, options)
	local window = self.window
	local row = createRow(self)
	local width = options.width or 110
	label(window, row, options.name or "Input", { Size = UDim2.new(1, -width - 6, 1, 0) })
	local field = createField(window, row, width, options.default or "")
	field.PlaceholderText = options.placeholder or ""
	local committed = field.Text
	local handle = { instance = field }
	function handle:set(text, shouldNotify)
		text = tostring(text):sub(1, options.maxLength or 256)
		if options.validate and not options.validate(text) then field.Text = committed; return end
		local hasChanged = text ~= committed
		committed, field.Text = text, text
		if hasChanged and shouldNotify ~= false then dispatch(options.callback, text) end
	end
	function handle:get() return committed end
	connect(window, field.FocusLost, function() handle:set(field.Text) end)
	return handle
end


Underlord.loadIcons = function(httpGet)
	if hasTriedIcons then return cachedIcons end
	hasTriedIcons = true
	if type(loadstring) ~= "function" then return nil end
	local isSuccess, provider = pcall(function()
		local source = (httpGet or fetchText)(iconUrl)
		local chunk, compileError = loadstring(source, "Lucide")
		assert(chunk, compileError)
		local icons = chunk()
		assert(type(icons) == "table" and type(icons.GetAsset) == "function", "API Lucide invalide.")
		return icons
	end)
	if isSuccess then cachedIcons = provider end
	return cachedIcons
end

Underlord.getIcon = function(name)
	return resolveIcon({ icons = cachedIcons }, name)
end

Window.getFlag = function(self, id)
	local control = self.flags[id]
	assert(control and control.get, "Contrôle introuvable : " .. tostring(id))
	return control:get()
end

Window.setFlag = function(self, id, setting, shouldNotify)
	local control = self.flags[id]
	assert(control and control.set, "Contrôle introuvable : " .. tostring(id))
	control:set(setting, shouldNotify)
end

Window.exportConfig = function(self)
	local settings = {}
	for id, control in pairs(self.flags) do
		if control.get and control.options.shouldSave ~= false then settings[id] = encodeSetting(control:get()) end
	end
	return HttpService:JSONEncode({ format = "Underlord", version = 1, settings = settings })
end

Window.importConfig = function(self, json, shouldNotify)
	local isSuccess, result = pcall(function()
		local config = HttpService:JSONDecode(json)
		assert(type(config) == "table" and config.format == "Underlord" and config.version == 1, "Configuration incompatible.")
		assert(type(config.settings) == "table", "Configuration invalide.")
		local updates = {}
		for id, setting in pairs(config.settings) do
			local control = self.flags[id]
			if control and control.set and control.options.shouldSave ~= false then
				table.insert(updates, { control = control, setting = decodeSetting(control, setting) })
			end
		end
		return updates
	end)
	if not isSuccess then return false, tostring(result) end
	for _, update in ipairs(result) do update.control:set(update.setting, shouldNotify == true) end
	return true
end

Window.reset = function(self, shouldNotify)
	for _, control in ipairs(self.controls) do control:reset(shouldNotify) end
end

Window.setAccent = function(self, accent)
	assert(typeof(accent) == "Color3", "Color3 attendu.")
	if self.isDestroyed then return end
	local previous = self.theme.accent
	self.theme.accent = accent
	for _, instance in ipairs(self.gui:GetDescendants()) do
		local properties = self.targets[instance] or {}
		local replacements = {}
		for _, property in ipairs({ "Color", "BackgroundColor3", "TextColor3", "ImageColor3" }) do
			local isReadable, current = pcall(function() return instance[property] end)
			if instance.Name ~= "Swatch" and isReadable and (current == previous or properties[property] == previous) then
				replacements[property] = accent
			end
		end
		if next(replacements) then animate(self, instance, replacements) end
	end
	refreshTitle(self)
	for _, tab in ipairs(self.tabs) do refreshTab(tab) end
end

Window.setSize = function(self, size)
	assert(typeof(size) == "Vector2" and size.X >= 560 and size.Y >= 300, "Taille minimale : 560 × 300.")
	self.theme.size = size
	self.host.Size = UDim2.fromOffset(size.X, self.isMinimized and 40 or size.Y)
	fitWindow(self, false)
end

Window.setPosition = function(self, position)
	assert(typeof(position) == "Vector2", "Vector2 attendu.")
	self.shownPosition = UDim2.fromOffset(position.X, position.Y)
	fitWindow(self, false)
end

Window.center = function(self)
	fitWindow(self, true)
end

Window.setMinimized = function(self, isMinimized)
	if self.isDestroyed then return end
	self.isMinimized = isMinimized == true
	closePopup(self, true)
	self.body.Visible = not self.isMinimized
	self.host.Size = UDim2.fromOffset(self.theme.size.X, self.isMinimized and 40 or self.theme.size.Y)
	fitWindow(self, false)
end

Window.setTitle = function(self, prefix, accentText, version)
	self.titlePrefix, self.titleAccent = prefix or "UNDER", accentText or "LORD"
	self.titleVersion = version or self.titleVersion
	refreshTitle(self)
end

Window.notify = function(self, options)
	local window = self
	options = options or {}
	if self.isDestroyed then return end
	if not self.toastStack then
		self.toastStack = frame(self.viewport, "Notifications", { AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(280, 500), ZIndex = 200 })
		create("UIListLayout", self.toastStack, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	end
	if #self.notifications >= 4 then self.notifications[1]:dismiss() end
	local toast = create("CanvasGroup", self.toastStack, { Name = "Notification", Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = self.theme.panel, BorderSizePixel = 0, GroupTransparency = 1 })
	outline(toast, self.theme.outline)
	local icon = createIcon(self, toast, options.icon or "info", 18)
	icon.Position, icon.ImageColor3 = UDim2.fromOffset(10, 12), self.theme.accent
	label(self, toast, options.title or "Underlord", { Position = UDim2.fromOffset(36, 7), Size = UDim2.new(1, -44, 0, 22) })
	label(self, toast, options.content or "", { Position = UDim2.fromOffset(10, 31), Size = UDim2.new(1, -20, 0, 32),
		TextSize = 12, TextWrapped = true, TextColor3 = self.theme.muted })
	local handle = { isDismissed = false }
	function handle:dismiss()
		if self.isDismissed or window.isDestroyed then return end
		self.isDismissed = true
		local index = table.find(window.notifications, self)
		if index then table.remove(window.notifications, index) end
		animate(window, toast, { GroupTransparency = 1 })
		schedule(window, window.theme.hoverDuration, function() toast:Destroy() end)
	end
	table.insert(self.notifications, handle)
	animate(self, toast, { GroupTransparency = 0 })
	schedule(self, options.duration or 4, function() handle:dismiss() end)
	return handle
end

Tab.setName = function(self, name)
	self.button.Name = name
end

Section.setVisible = function(self, isVisible)
	local popup = self.window.activeDropdown
	if not isVisible and popup and popup.control:IsDescendantOf(self.frame) then closePopup(self.window, true) end
	self.frame.Visible = isVisible == true
end

Section.setTitle = function(self, title)
	local heading = self.frame:FindFirstChild("Title")
	if heading then heading.Text = title end
end

Section.addLabel = function(self, options)
	local row = createRow(self, options.height or 20)
	local caption = label(self.window, row, options.text or options.name or "", { TextWrapped = options.wrapped == true })
	return { instance = caption, setText = function(_, text) caption.Text = text end }
end

Section.addSeparator = function(self, options)
	local row = createRow(self, options.name and 22 or 8)
	local divider = frame(row, "Divider", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(42, 42, 44) })
	if options.name then label(self.window, row, options.name, { TextSize = 12, TextColor3 = self.window.theme.muted }) end
	return { instance = divider }
end

Section.addColorPicker = function(self, options)
	local window = self.window
	local selected = options.default or window.theme.accent
	assert(typeof(selected) == "Color3", "Color3 attendu.")
	local view = createColorPanel(self, options)
	local isOpen = false
	local handle = { instance = view.control }
	function handle:get() return selected end
	function handle:set(color, shouldNotify)
		if typeof(color) ~= "Color3" then return end
		local hasChanged = color ~= selected
		selected = color
		refreshColor(window, view, color)
		if hasChanged and shouldNotify ~= false then dispatch(options.callback, color) end
	end
	local function setOpen(shouldOpen)
		isOpen = shouldOpen
		view.panel.Visible = true
		animate(window, view.row, { Size = UDim2.new(1, -2, 0, isOpen and 172 or 20) })
		animate(window, view.panel, { GroupTransparency = isOpen and 0 or 1 })
	end
	handle.close = function() setOpen(false) end
	connect(window, view.control.Activated, function()
		local shouldOpen = not isOpen
		closePopup(window)
		if shouldOpen then window.closePopup = handle.close; setOpen(true) end
	end)
	connect(window, view.hex.FocusLost, function()
		local hex = view.hex.Text:gsub("^#", "")
		if hex:match("^%x%x%x%x%x%x$") then handle:set(Color3.fromHex(hex)) else refreshColor(window, view, selected) end
	end)
	bindColorPointer(window, view, handle)
	handle:set(selected, false)
	return handle
end

Window.saveConfig = function(self, name)
	if not self.storage or type(self.storage.write) ~= "function" then return false, "Stockage non configuré." end
	if type(name) ~= "string" or not name:match("^[%w_-]+$") then return false, "Nom de profil invalide." end
	return pcall(self.storage.write, "Underlord_" .. name .. ".json", self:exportConfig())
end

Window.loadConfig = function(self, name, shouldNotify)
	if not self.storage or type(self.storage.read) ~= "function" then return false, "Stockage non configuré." end
	if type(name) ~= "string" or not name:match("^[%w_-]+$") then return false, "Nom de profil invalide." end
	local isSuccess, json = pcall(self.storage.read, "Underlord_" .. name .. ".json")
	if not isSuccess then return false, tostring(json) end
	return self:importConfig(json, shouldNotify)
end

Window.createToggleButton = function(self)
	if self.toggleButton then return self.toggleButton end
	local control = button(self, self.viewport, "UL", {
		Name = "ToggleWindow", Position = UDim2.fromOffset(16, 110), Size = UDim2.fromOffset(38, 30),
		BackgroundTransparency = 0, BackgroundColor3 = self.theme.background, ZIndex = 200,
	})
	outline(control, self.theme.outline)
	textHover(self, control)
	connect(self, control.Activated, function() self:setVisible(not self.isVisible) end)
	self.toggleButton = control
	return control
end

registerControl("addButton", "button")
registerControl("addToggle", "toggle")
registerControl("addSlider", "slider")
registerControl("addDropdown", "dropdown")
registerControl("addKeybind", "keybind")
registerControl("addInput", "input")
registerControl("addColorPicker", "color")
registerControl("addLabel", "label")
registerControl("addSeparator", "separator")

return Underlord
