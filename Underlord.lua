local Underlord = (function()
local Underlord = { version = "2.3.0" }

local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

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
	scale = 0.95,
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
	headerFont = Enum.Font.SourceSans,
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
		AutoLocalize = false,
		TextScaled = false,
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
		AutoLocalize = false,
		TextScaled = false,
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
	if window.hideTooltip then window.hideTooltip() end
	local view = window.activePopup
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

local function placePopup(window, view)
	if not view.shell.Parent then return end
	local scale = window.scale.Scale
	local origin = view.control.AbsolutePosition
	local viewportOrigin = window.viewport.AbsolutePosition
	local viewport = window.viewport.AbsoluteSize
	local width = view.width or view.control.AbsoluteSize.X / scale
	local height = view.listHeight
	local left = math.clamp(origin.X - viewportOrigin.X, 2, math.max(2, viewport.X - width * scale - 2))
	local below = origin.Y - viewportOrigin.Y + view.control.AbsoluteSize.Y + scale
	local top = below
	if below + height * scale > viewport.Y - 2 then top = origin.Y - viewportOrigin.Y - height * scale - scale end
	top = math.clamp(top, 2, math.max(2, viewport.Y - height * scale - 2))
	local hostOrigin = window.host.AbsolutePosition - viewportOrigin
	view.shell.Position = UDim2.fromOffset((left - hostOrigin.X) / scale, (top - hostOrigin.Y) / scale)
	view.targetSize = UDim2.fromOffset(width, height)
	if not view.isAnimating then view.shell.Size = view.targetSize end
end

local function popupAnimation(window, view)
	local revision = 0
	return function(shouldOpen)
		revision = revision + 1
		local currentRevision = revision
		if not view.shell.Parent then return end
		if shouldOpen then
			placePopup(window, view)
			if not view.shell.Visible then
				view.shell.Size = UDim2.fromOffset(view.targetSize.X.Offset, 0)
			end
			view.shell.Visible = true
			window.activePopup = view
			window.popupOrder = (window.popupOrder or 0) + 1
			view.shell.ZIndex = window.popupOrder
		elseif window.activePopup == view then
			window.activePopup = nil
		end
		if view.scroll then
			view.scroll.Active = shouldOpen
			view.scroll.ScrollingEnabled = shouldOpen
		end
		view.blocker.Visible = not shouldOpen
		if view.arrow then animate(window, view.arrow, { Rotation = shouldOpen and 180 or 0 }) end
		view.isAnimating = true
		animate(window, view.list, { GroupTransparency = shouldOpen and 0 or 1 }, window.theme.popupDuration)
		local target = shouldOpen and view.targetSize or UDim2.fromOffset(view.shell.Size.X.Offset, 0)
		local tween = animate(window, view.shell, { Size = target }, window.theme.popupDuration, Enum.EasingStyle.Quart)
		task.spawn(function()
			tween.Completed:Wait()
			if window.isDestroyed or revision ~= currentRevision or not view.shell.Parent then return end
			view.isAnimating = false
			view.shell.Visible = shouldOpen
			if shouldOpen then placePopup(window, view) end
		end)
	end
end

local function bindPopupPosition(window, view)
	local function refresh()
		if window.activePopup == view then placePopup(window, view) end
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
		if isPointer(input) and window.activePopup then
			local position = Vector2.new(input.Position.X, input.Position.Y)
			local view = window.activePopup
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
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0.5, -96, 0, 38),
		Font = window.theme.headerFont, TextSize = 32, RichText = true, ClipsDescendants = true,
	})
	window.titlePrefix = options.titlePrefix or "UNDER"
	window.titleAccent = options.titleAccent or "LORD"
	window.title = title
	window.titleVersion = options.version or "v3.1.5"
	window.navigation = create("ScrollingFrame", header, {
		Name = "Navigation", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		ClipsDescendants = true,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 7), Size = UDim2.fromOffset(160, 27),
	})
	create("UIListLayout", window.navigation, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) })
	window.clock = label(window, header, "", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 2),
		Size = UDim2.fromOffset(110, 35), Font = window.theme.headerFont, TextSize = 16,
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
	window.root = frame(window.host, "Window", {
		Name = "Window", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = window.theme.background, BackgroundTransparency = 0,
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

local function limitText(text, maximum)
	text = tostring(text):gsub("[%c]", "")
	local length = utf8.len(text)
	if not length then return "" end
	if length <= maximum then return text end
	return text:sub(1, utf8.offset(text, maximum + 1) - 1)
end

local function createField(window, parent, width, text, maxLength)
	maxLength = maxLength or 256
	local field = create("TextBox", parent, {
		Name = "Input", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -1, 0.5, 0),
		Size = UDim2.fromOffset(width, 18), BackgroundTransparency = 1, BorderSizePixel = 0,
		Font = window.theme.font, TextColor3 = window.theme.text, TextSize = window.theme.textSize,
		AutoLocalize = false, TextScaled = false,
		Text = limitText(text, maxLength), ClearTextOnFocus = false, MultiLine = false, TextWrapped = false,
	})
	field:SetAttribute("MaxLength", maxLength)
	connect(window, field:GetPropertyChangedSignal("Text"), function()
		local limited = limitText(field.Text, maxLength)
		if field.Text ~= limited then field.Text = limited end
	end)
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
	return hitbox, knob, createField(window, row, fieldWidth, "0", 24), fill
end

local function createToggleView(section, options)
	local window = section.window
	local row = createRow(section)
	label(window, row, options.name or "Toggle", { Size = UDim2.new(1, -26, 1, 0), Active = false })
	local control = button(window, row, "", { Name = "Toggle", AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -1, 0.5, 0), Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = window.theme.accent })
	round(control, 4)
	local border = outline(control, window.theme.outline)
	local check = label(window, control, "✓", { Font = Enum.Font.SourceSansBold, TextSize = 19,
		TextColor3 = Color3.fromRGB(40, 19, 23), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1 })
	return control, border, check
end

local function createKeybindView(section, options)
	local window = section.window
	local row = createRow(section)
	local width = options.width or 84
	label(window, row, options.name or "Keybind", { Size = UDim2.new(1, -width - 6, 1, 0) })
	local control = button(window, row, "", { Name = "Keybind", AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -1, 0.5, 0), Size = UDim2.fromOffset(width, 18) })
	round(control, 2)
	local border = outline(control, window.theme.outline)
	textHover(window, control, border)
	return control, border
end

local function schedule(window, delaySeconds, callback)
	if window.isDestroyed then return nil end
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

local function destroyPopup(window, view, handle)
	if window.activePopup == view then window.activePopup = nil end
	if window.closePopup == handle.close then window.closePopup = nil end
	if view.connections then releaseConnections(window, view.connections) end
	for instance, tween in pairs(window.tweens) do
		if instance == view.shell or instance:IsDescendantOf(view.shell) then
			tween:Cancel()
			window.tweens[instance], window.targets[instance] = nil, nil
		end
	end
	view.shell:Destroy()
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

local function cancelScheduled(window, thread)
	if not thread then return end
	window.tasks[thread] = nil
	task.cancel(thread)
end

local function destroyOverlay(window, shell)
	for instance, tween in pairs(window.tweens) do
		if instance == shell or instance:IsDescendantOf(shell) then
			tween:Cancel()
			window.tweens[instance], window.targets[instance] = nil, nil
		end
	end
	shell:Destroy()
end

local function measureText(window, text, width, maximum)
	local bounds = TextService:GetTextSize(text, 12, window.theme.font, Vector2.new(math.max(1, width), 10000))
	return math.clamp(bounds.Y, 16, maximum)
end

local function overlayCard(window, parent, name, size, layer)
	local shell = frame(parent, name, { Size = size, ZIndex = layer or 1 })
	round(shell, 5)
	shadow(shell, 10, 3, 1, 0.35)
	local panel = create("CanvasGroup", shell, {
		Name = "Content", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0,
		BackgroundColor3 = window.theme.panel, GroupTransparency = 1,
	})
	round(panel, 5)
	outline(shell, Color3.fromRGB(49, 49, 53))
	return shell, panel
end

local function tooltipPosition(window, target, width, height)
	local viewport = window.viewport.AbsoluteSize
	local origin = target.AbsolutePosition - window.viewport.AbsolutePosition
	local top = origin.Y + target.AbsoluteSize.Y + 7
	if top + height > viewport.Y - 8 then top = origin.Y - height - 7 end
	return UDim2.fromOffset(math.clamp(origin.X, 8, math.max(8, viewport.X - width - 8)),
		math.clamp(top, 8, math.max(8, viewport.Y - height - 8)))
end

local function createTooltip(window, target, text)
	local width = math.max(48, math.min(250, window.viewport.AbsoluteSize.X - 16))
	local height = measureText(window, text, width - 20, 96) + 16
	local shell, panel = overlayCard(window, window.viewport, "Tooltip", UDim2.fromOffset(width, height), 400)
	label(window, panel, text, { Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 1, -16),
		TextWrapped = true, TextSize = 12, TextYAlignment = Enum.TextYAlignment.Top })
	local position = tooltipPosition(window, target, width, height)
	shell.Position = UDim2.fromOffset(position.X.Offset, position.Y.Offset + 4)
	animate(window, shell, { Position = position }, 0.12)
	animate(window, panel, { GroupTransparency = 0 }, 0.12)
	return shell, panel
end

local function addTooltip(window, target, text)
	local shell, panel, pending
	local function hide()
		cancelScheduled(window, pending)
		pending = nil
		if shell then
			local previous = shell
			animate(window, panel, { GroupTransparency = 1 }, 0.10)
			schedule(window, 0.10, function() destroyOverlay(window, previous) end)
			shell, panel = nil, nil
		end
	end
	bindHover(window, target, function(isHovered)
		hide()
		if not isHovered then return end
		if window.hideTooltip then window.hideTooltip() end
		window.hideTooltip = hide
		pending = schedule(window, 0.3, function()
			pending = nil
			if not window.isVisible or not target.Parent or window.isTransitioning then return end
			local ancestor = target
			while ancestor and ancestor ~= window.gui do
				if ancestor:IsA("GuiObject") and not ancestor.Visible then return end
				ancestor = ancestor.Parent
			end
			shell, panel = createTooltip(window, target, limitText(text, 320))
		end)
	end)
	connect(window, target:GetPropertyChangedSignal("AbsolutePosition"), hide)
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
		if self.hideTooltip then self.hideTooltip() end
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
		local length = utf8.len(setting)
		assert(length and length >= (handle.options.minLength or 0) and length <= (handle.options.maxLength or 64), "Longueur de texte invalide.")
		assert(limitText(setting, handle.options.maxLength or 64) == setting, "Caractères de contrôle refusés.")
		assert(not handle.options.validate or handle.options.validate(setting), "Texte refusé.")
	end
	if kind == "dropdown" then assert(handle:accepts(setting), "Sélection invalide.") end
	return setting
end

local function createDropdownPanel(section, options)
	local window = section.window
	local row = createRow(section, 44)
	label(window, row, options.name or "Dropdown", { Size = UDim2.new(1, 0, 0, 19) })
	local control = button(window, row, "", { Name = "Dropdown", Position = UDim2.fromOffset(1, 23), Size = UDim2.new(1, -2, 0, 19) })
	round(control, 4)
	outline(control, window.theme.outline)
	local caption = label(window, control, "", { Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -26, 1, 0), TextXAlignment = Enum.TextXAlignment.Center })
	local arrow = createIcon(window, control, "chevron-down", 14)
	arrow.Position = UDim2.new(1, -18, 0.5, -7)
	local shell = frame(window.popupLayer, "DropdownPopup", { Size = UDim2.fromOffset(230, 162), Visible = false, ClipsDescendants = true })
	round(shell, 5)
	shadow(shell, 8, 3, 1, 0.25)
	outline(shell, window.theme.outline)
	local list = create("CanvasGroup", shell, { Name = "Choices", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = window.theme.panel, BorderSizePixel = 0, GroupTransparency = 1 })
	round(list, 5)
	local search = createField(window, list, 180, "", 64)
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
	if window.activePopup == view then placePopup(window, view) end
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
	local shell = frame(window.popupLayer, "ColorPopup", {
		Size = UDim2.fromOffset(230, 158), Visible = false, ClipsDescendants = true,
	})
	round(shell, 5)
	shadow(shell, 8, 3, 1, 0.25)
	outline(shell, window.theme.outline)
	local list = create("CanvasGroup", shell, { Name = "Picker", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = window.theme.panel, BorderSizePixel = 0, GroupTransparency = 1 })
	round(list, 5)
	local panel = frame(list, "Content", {
		Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 142),
	})
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
	local hex = createField(window, panel, 90, "", 7)
	hex.Position = UDim2.new(1, -1, 0, 129)
	local blocker = button(window, list, "", { Name = "ClosingBlocker", ZIndex = 100, Visible = true, Selectable = false })
	return { row = row, control = control, swatch = swatch, panel = panel, shell = shell, list = list,
		blocker = blocker, width = 230, listHeight = 158, saturation = saturation, hueBase = hueBase,
		marker = marker, hue = hue, hueMarker = hueMarker, hex = hex }
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
	local control = button(window, row, options.name or "Button", {
		Name = "Action", Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2),
	})
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
	local control, border, check = createToggleView(self, options)
	local isEnabled, isHovered = options.default == true, false
	local function refresh()
		animate(window, border, { Color = (isEnabled or isHovered) and window.theme.accent or window.theme.outline })
		animate(window, control, { BackgroundTransparency = isEnabled and 0 or 1 })
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
	local animateOpen = popupAnimation(window, view)
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
		destroyPopup(window, view, handle)
	end
	connect(window, view.control.Destroying, cleanup)
	bindPopupPosition(window, view)
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
	local maximum, minimum = options.maxLength or 64, options.minLength or 0
	assert(type(maximum) == "number" and maximum % 1 == 0 and maximum >= 1 and maximum <= 32768, "maxLength doit être compris entre 1 et 32768.")
	assert(type(minimum) == "number" and minimum % 1 == 0 and minimum >= 0 and minimum <= maximum, "minLength invalide.")
	local initial = limitText(options.default or "", maximum)
	assert(utf8.len(initial) >= minimum and (not options.validate or options.validate(initial)), "Texte initial invalide.")
	local row = createRow(self)
	local width = options.width or 110
	label(window, row, options.name or "Input", { Size = UDim2.new(1, -width - 6, 1, 0) })
	local field = createField(window, row, width, initial, maximum)
	field.PlaceholderText = options.placeholder or ""
	local committed = field.Text
	local handle = { instance = field }
	function handle:set(text, shouldNotify)
		text = limitText(text, maximum)
		if utf8.len(text) < minimum or (options.validate and not options.validate(text)) then field.Text = committed; return false end
		local hasChanged = text ~= committed
		committed, field.Text = text, text
		if hasChanged and shouldNotify ~= false then dispatch(options.callback, text) end
		return true
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

local function layoutNotifications(window)
	local width = math.max(64, math.min(280, window.viewport.AbsoluteSize.X - 28))
	window.toastStack.Size = UDim2.fromOffset(width, 0)
	local offset = 0
	for index = #window.notifications, 1, -1 do
		local notice = window.notifications[index]
		notice:resize(width)
		animate(window, notice.shell, { Position = UDim2.new(1, 0, 0, -offset) }, 0.16)
		offset = offset + notice.shell.Size.Y.Offset + 8
	end
	if #window.notifications > 1 and offset > window.viewport.AbsoluteSize.Y - 28 then
		window.notifications[1]:dismiss(true)
	end
end

local function createNotificationView(window, options)
	local shell, panel = overlayCard(window, window.toastStack, "Notification", UDim2.fromOffset(280, 74))
	shell.AnchorPoint = Vector2.new(1, 1)
	shell.Position = UDim2.new(1, 24, 0, 0)
	local icon = createIcon(window, panel, options.icon or "bell", 16)
	icon.Position, icon.ImageColor3 = UDim2.fromOffset(10, 10), window.theme.accent
	label(window, panel, limitText(options.title or "Underlord", 64), {
		Position = UDim2.fromOffset(34, 8), Size = UDim2.new(1, -66, 0, 20), TextSize = 13,
	})
	local content = label(window, panel, limitText(options.content or "", 320), {
		Position = UDim2.fromOffset(10, 33), Size = UDim2.new(1, -20, 0, 30), TextSize = 12,
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = window.theme.muted,
	})
	local close = button(window, panel, "", {
		Name = "Dismiss", Position = UDim2.new(1, -27, 0, 7), Size = UDim2.fromOffset(20, 20),
	})
	local closeIcon = createIcon(window, close, "x", 12)
	closeIcon.Position = UDim2.fromOffset(4, 4)
	local progress = frame(panel, "Lifetime", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2),
		BackgroundTransparency = 0, BackgroundColor3 = window.theme.accent })
	return { shell = shell, panel = panel, content = content, close = close, closeIcon = closeIcon, progress = progress }
end

local function notificationHandle(window, view)
	local handle = { isDismissed = false, shell = view.shell, connections = {} }
	function handle:resize(width)
		local height = measureText(window, view.content.Text, width - 20, 64)
		view.content.Size = UDim2.new(1, -20, 0, height)
		view.shell.Size = UDim2.fromOffset(width, height + 45)
	end
	function handle:dismiss(shouldHideImmediately)
		if self.isDismissed or window.isDestroyed then return end
		self.isDismissed = true
		cancelScheduled(window, self.timer)
		releaseConnections(window, self.connections)
		local index = table.find(window.notifications, self)
		if index then table.remove(window.notifications, index) end
		if shouldHideImmediately then
			destroyOverlay(window, view.shell)
		else
			animate(window, view.panel, { GroupTransparency = 1 }, 0.14)
			animate(window, view.shell, { Position = UDim2.new(1, 24, 0, view.shell.Position.Y.Offset) }, 0.14)
			schedule(window, 0.14, function() destroyOverlay(window, view.shell) end)
		end
		layoutNotifications(window)
	end
	table.insert(handle.connections, connect(window, view.close.Activated, function() handle:dismiss() end))
	table.insert(handle.connections, connect(window, view.close.MouseEnter, function()
		animate(window, view.closeIcon, { ImageColor3 = window.theme.accent })
	end))
	table.insert(handle.connections, connect(window, view.close.MouseLeave, function()
		animate(window, view.closeIcon, { ImageColor3 = window.theme.text })
	end))
	return handle
end

Window.notify = function(self, options)
	options = options or {}
	if self.isDestroyed then return end
	if not self.toastStack then
		self.toastStack = frame(self.viewport, "Notifications", { AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(280, 0), ZIndex = 350 })
		connect(self, self.viewport:GetPropertyChangedSignal("AbsoluteSize"), function() layoutNotifications(self) end)
	end
	if #self.notifications >= 3 then self.notifications[1]:dismiss(true) end
	local duration = tonumber(options.duration) or 4
	if duration ~= duration then duration = 4 end
	duration = math.clamp(duration, 1, 15)
	local view = createNotificationView(self, options)
	local handle = notificationHandle(self, view)
	table.insert(self.notifications, handle)
	layoutNotifications(self)
	animate(self, view.panel, { GroupTransparency = 0 }, 0.16)
	animate(self, view.progress, { Size = UDim2.fromOffset(0, 2) }, duration, Enum.EasingStyle.Linear)
	handle.timer = schedule(self, duration, function() handle.timer = nil; handle:dismiss() end)
	return handle
end

Tab.setName = function(self, name)
	self.button.Name = name
end

Section.setVisible = function(self, isVisible)
	if self.window.hideTooltip then self.window.hideTooltip() end
	local popup = self.window.activePopup
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
	local animateOpen = popupAnimation(window, view)
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
		animateOpen(shouldOpen)
		if not shouldOpen then
			window.pointer = nil
			view.hex:ReleaseFocus()
		end
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
	bindPopupPosition(window, view)
	handle.cleanup = function() destroyPopup(window, view, handle) end
	connect(window, view.control.Destroying, handle.cleanup)
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

end)()

local Runtime = (function()
local Runtime = {}
Runtime.__index = Runtime

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local function create(className, parent, properties)
	local instance = Instance.new(className)
	for property, value in pairs(properties or {}) do instance[property] = value end
	instance.Parent = parent
	return instance
end

local function childValue(parent, name)
	local child = parent and parent:FindFirstChild(name)
	if child and child:IsA("ValueBase") then return child.Value end
	return nil
end

local function positionOf(instance)
	if not instance or not instance.Parent then return nil end
	if instance:IsA("BasePart") then return instance.Position end
	local part = instance:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position or nil
end

local function sortedKeys(entries)
	local names = {}
	for name in pairs(entries) do table.insert(names, name) end
	table.sort(names)
	return names
end

local function writeProperty(instance, property, record)
	local selected, order = record.original, -1
	for _, layer in pairs(record.layers) do
		if layer.order > order then selected, order = layer.value, layer.order end
	end
	record.applied = selected
	record.isWriting = true
	local isSuccess = pcall(function() instance[property] = selected end)
	record.isWriting = false
	return isSuccess
end

Runtime.new = function(window)
	local self = setmetatable({ window = window, connections = {}, patches = {}, order = 0, serial = 0,
		settings = { speed = 24, jump = 65, sprint = 1.6, flySpeed = 50, vertical = 0,
			isSpeed = false, isJump = false, isSprint = false, isNoclip = false, isFlying = false,
			isAirJump = false, isFullbright = false, isNoFog = false, isNoShadows = false,
			isClock = false, clock = 12, isFov = false, fov = 80, markerColor = Color3.fromRGB(222,65,88) },
		selectors = {}, labels = {}, histories = {}, markers = {}, owned = {}, trees = {}, shops = {}, tools = {},
		bookmarks = {}, playerOptions = {}, identifiers = setmetatable({}, { __mode = "k" }), nextId = 0, isDestroyed = false }, Runtime)
	self.folder = create("Folder", Workspace, { Name = "UnderlordLocal" })
	return self
end

Runtime.connect = function(self, key, signal, callback)
	if self.connections[key] then self.connections[key]:Disconnect() end
	self.connections[key] = signal:Connect(function(...)
		if not self.isDestroyed then callback(...) end
	end)
	return self.connections[key]
end

Runtime.disconnect = function(self, key)
	if not self.connections[key] then return end
	self.connections[key]:Disconnect()
	self.connections[key] = nil
end

Runtime.notice = function(self, message)
	if not self.isDestroyed then self.window:notify({ title = "Underlord · LT2", content = tostring(message) }) end
end

Runtime.copy = function(self, text)
	if type(setclipboard) ~= "function" then self:notice("Presse-papiers indisponible."); return end
	local isSuccess = pcall(setclipboard, tostring(text))
	self:notice(isSuccess and "Copié." or "Copie impossible.")
end

Runtime.patch = function(self, token, instance, property, value)
	if not instance then return end
	local properties = self.patches[instance]
	if not properties then properties = {}; self.patches[instance] = properties end
	local record = properties[property]
	if not record then
		record = { original = instance[property], layers = {}, isWriting = false }
		properties[property] = record
		record.connection = instance:GetPropertyChangedSignal(property):Connect(function()
			if record.isWriting or self.isDestroyed or instance[property] == record.applied then return end
			record.original = instance[property]
			writeProperty(instance, property, record)
		end)
	end
	self.order = self.order + 1
	record.layers[token] = { value = value, order = self.order }
	writeProperty(instance, property, record)
end

Runtime.restore = function(self, token)
	for instance, properties in pairs(self.patches) do
		for property, record in pairs(properties) do
			record.layers[token] = nil
			if not next(record.layers) then
				record.connection:Disconnect()
				pcall(function() instance[property] = record.original end)
				properties[property] = nil
			else
				writeProperty(instance, property, record)
			end
		end
		if not next(properties) then self.patches[instance] = nil end
	end
end

Runtime.setLabel = function(self, name, text)
	local label = self.labels[name]
	if label and not label.isDestroyed then label:setText(text) end
end

Runtime.updateCharacter = function(self)
	local humanoid = self.humanoid
	if not humanoid then return end
	local settings = self.settings
	self:restore("Speed")
	if settings.isSpeed or settings.isSprint then
		local speed = settings.isSpeed and settings.speed or humanoid.WalkSpeed
		if settings.isSprint and self.isShift then speed = speed * settings.sprint end
		self:patch("Speed", humanoid, "WalkSpeed", speed)
	end
	self:restore("Jump")
	if settings.isJump then
		self:patch("Jump", humanoid, "UseJumpPower", true)
		self:patch("Jump", humanoid, "JumpPower", settings.jump)
	end
	self:setLabel("health", string.format("Vie : %.0f / %.0f", humanoid.Health, humanoid.MaxHealth))
end

Runtime.applyCollision = function(self, instance)
	if self.settings.isNoclip and instance:IsA("BasePart") then self:patch("Noclip", instance, "CanCollide", false) end
end

Runtime.setNoclip = function(self, isEnabled)
	self.settings.isNoclip = isEnabled
	self:restore("Noclip")
	if isEnabled and self.character then
		for _, instance in ipairs(self.character:GetDescendants()) do self:applyCollision(instance) end
	end
end

Runtime.stopFly = function(self)
	self:disconnect("Fly")
	if self.flyVelocity then self.flyVelocity:Destroy(); self.flyVelocity = nil end
	if self.flyOrientation then self.flyOrientation:Destroy(); self.flyOrientation = nil end
	if self.flyAttachment then self.flyAttachment:Destroy(); self.flyAttachment = nil end
	self:restore("Flight")
	if self.root and self.root.Parent then self.root.AssemblyLinearVelocity = Vector3.zero end
	self.settings.isFlying = false
end

Runtime.flyStep = function(self)
	local camera, humanoid = Workspace.CurrentCamera, self.humanoid
	if not camera or not humanoid or humanoid.Health <= 0 or not self.root.Parent then self:stopFly(); return end
	local velocity = humanoid.MoveDirection
	local vertical = self.settings.vertical
	if not UserInputService:GetFocusedTextBox() then
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = vertical + 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical = vertical - 1 end
	else
		velocity, vertical = Vector3.zero, 0
	end
	local direction = velocity + Vector3.new(0, vertical, 0)
	if direction.Magnitude > 1 then direction = direction.Unit end
	self.flyVelocity.VectorVelocity = direction * self.settings.flySpeed
	local look = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude > 0.01 then self.flyOrientation.CFrame = CFrame.lookAt(Vector3.zero, look) end
end

Runtime.setFly = function(self, isEnabled)
	self:stopFly()
	if not isEnabled then return true end
	if not self.root or not self.humanoid or self.humanoid.Health <= 0 then self:notice("Personnage indisponible."); return false end
	self.humanoid.Sit = false
	self.flyAttachment = create("Attachment", self.root, { Name = "UnderlordFlight" })
	self.flyVelocity = create("LinearVelocity", self.root, { Name = "UnderlordVelocity", Attachment0 = self.flyAttachment,
		RelativeTo = Enum.ActuatorRelativeTo.World, ForceLimitsEnabled = false, VectorVelocity = Vector3.zero })
	self.flyOrientation = create("AlignOrientation", self.root, { Name = "UnderlordOrientation", Attachment0 = self.flyAttachment,
		Mode = Enum.OrientationAlignmentMode.OneAttachment, MaxTorque = 1000000, Responsiveness = 20 })
	self:patch("Flight", self.humanoid, "AutoRotate", false)
	self.settings.isFlying = true
	self:connect("Fly", RunService.PreSimulation, function() self:flyStep() end)
	return true
end

Runtime.teleport = function(self, position, shouldRecord)
	if not self.root or not self.character or not self.humanoid or self.humanoid.Health <= 0 then self:notice("Personnage indisponible."); return end
	if shouldRecord ~= false then
		table.insert(self.histories, self.root.Position)
		if #self.histories > 12 then table.remove(self.histories, 1) end
	end
	self.humanoid.Sit = false
	self.character:PivotTo(CFrame.new(position) * self.root.CFrame.Rotation)
	self.root.AssemblyLinearVelocity, self.root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
end

Runtime.goTo = function(self, instance)
	local position = positionOf(instance)
	if not position then self:notice("Objet absent ou non chargé."); return end
	self:teleport(position + Vector3.new(0, 6, 0))
end

Runtime.back = function(self)
	local position = table.remove(self.histories)
	if position then self:teleport(position, false) else self:notice("Historique vide.") end
end

Runtime.mark = function(self, name, instance)
	if self.markers[name] then self.markers[name]:Destroy(); self.markers[name] = nil end
	if not instance or not instance.Parent then return end
	self.markers[name] = create("Highlight", self.folder, { Name = "Marker", Adornee = instance,
		FillColor = self.settings.markerColor, OutlineColor = self.settings.markerColor,
		FillTransparency = 0.8, OutlineTransparency = 0.1, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop })
end

Runtime.clearMarkers = function(self)
	for name in pairs(self.markers) do self:mark(name, nil) end
end

Runtime.selectOptions = function(self, key, entries)
	local selector = self.selectors[key]
	if not selector then return end
	selector:setOptions(sortedKeys(entries), false)
end

Runtime.identifier = function(self, instance)
	if self.identifiers[instance] then return self.identifiers[instance] end
	self.nextId = self.nextId + 1
	self.identifiers[instance] = self.nextId
	return self.nextId
end

Runtime.scanWorld = function(self)
	if self.isScanning or self.isDestroyed then return end
	self.isScanning = true
	local owned, trees, shops = {}, {}, {}
	local models, ownedCount, treeCount = {}, 0, 0
	for index, instance in ipairs(Workspace:GetDescendants()) do
		if index % 2000 == 0 then
			task.wait()
			if self.isDestroyed then self.isScanning = false; return end
		end
		if instance:IsA("Model") and not instance:IsDescendantOf(self.folder) then table.insert(models, instance) end
	end
	for _, model in ipairs(models) do
		if childValue(model, "Owner") == player then
			ownedCount = ownedCount + 1
			local name = childValue(model, "ItemName") or childValue(model, "ToolName") or model.Name
			owned[string.format("%s [%d]", name, self:identifier(model))] = model
		end
		local treeClass = childValue(model, "TreeClass")
		if treeClass then
			treeCount = treeCount + 1
			trees[string.format("%s [%d]", treeClass, self:identifier(model))] = model
		end
	end
	local stores = Workspace:FindFirstChild("Stores")
	if stores then for _, shop in ipairs(stores:GetChildren()) do shops[shop.Name] = shop end end
	self.owned, self.trees, self.shops = owned, trees, shops
	self:selectOptions("owned", owned); self:selectOptions("trees", trees); self:selectOptions("shops", shops)
	self:setLabel("world", string.format("Objets à vous : %d · Bois : %d", ownedCount, treeCount))
	self.isScanning = false
end

Runtime.ownProperty = function(self)
	local properties = Workspace:FindFirstChild("Properties")
	if not properties then return nil end
	for _, property in ipairs(properties:GetChildren()) do
		if childValue(property, "Owner") == player then return property end
	end
	return nil
end

Runtime.nearestTree = function(self, treeClass)
	if not self.root then return nil end
	local closest, distance = nil, math.huge
	for _, tree in pairs(self.trees) do
		local position = positionOf(tree)
		if position and (treeClass == "" or tostring(childValue(tree, "TreeClass")):lower():find(treeClass:lower(), 1, true)) then
			local candidate = (position - self.root.Position).Magnitude
			if candidate < distance then closest, distance = tree, candidate end
		end
	end
	return closest, distance
end

Runtime.refreshInventory = function(self)
	local tools, count = {}, 0
	local function collect(parent)
		if not parent then return end
		for _, tool in ipairs(parent:GetChildren()) do
			if tool:IsA("Tool") then count = count + 1; tools[string.format("%s [%d]", tool.Name, self:identifier(tool))] = tool end
		end
	end
	collect(player:FindFirstChildOfClass("Backpack")); collect(self.character)
	self.tools = tools
	self:selectOptions("tools", tools)
	self:setLabel("inventory", "Outils possédés : " .. count)
end

Runtime.refreshCatalog = function(self)
	self.catalog = {}
	local catalog = ReplicatedStorage:FindFirstChild("ClientItemInfo")
	if catalog then for _, item in ipairs(catalog:GetChildren()) do self.catalog[item.Name] = item end end
	self:selectOptions("catalog", self.catalog)
	self:setLabel("catalog", "Catalogue : " .. #sortedKeys(self.catalog))
end

Runtime.catalogInfo = function(self)
	local item = self.catalog[self.selectors.catalog:get()]
	if not item then self:notice("Aucun article sélectionné."); return end
	local description = string.format("%s\nType : %s\nPrix : %s\nBois : %s\n%s", childValue(item,"ItemName") or item.Name,
		tostring(childValue(item,"Type") or "—"), tostring(childValue(item,"Price") or "—"),
		tostring(childValue(item,"WoodCost") or "—"), tostring(childValue(item,"Description") or ""))
	self:copy(description)
end

Runtime.refreshPlayers = function(self)
	local entries = {}
	for _, candidate in ipairs(Players:GetPlayers()) do
		if candidate ~= player then entries[candidate.Name] = candidate end
	end
	self.playerOptions = entries
	self:selectOptions("players", entries)
end

Runtime.selectedPlayer = function(self)
	return self.playerOptions[self.selectors.players:get()]
end

Runtime.spectate = function(self, target)
	self:restore("Spectate")
	self:disconnect("SpectateCharacter")
	self.spectated = target
	local function apply(character)
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
		if self.isDestroyed or self.spectated ~= target then return end
		if humanoid and Workspace.CurrentCamera then self:patch("Spectate", Workspace.CurrentCamera, "CameraSubject", humanoid) end
	end
	if target then
		self:connect("SpectateCharacter", target.CharacterAdded, apply)
		task.spawn(apply, target.Character)
	end
end

Runtime.applyLighting = function(self)
	local settings = self.settings
	for _, token in ipairs({"Bright","Fog","Shadows","Clock"}) do self:restore(token) end
	if settings.isFullbright then
		self:patch("Bright", Lighting, "Brightness", 2)
		self:patch("Bright", Lighting, "Ambient", Color3.fromRGB(160,160,160))
		self:patch("Bright", Lighting, "OutdoorAmbient", Color3.fromRGB(180,180,180))
	end
	if settings.isNoFog then
		self:patch("Fog", Lighting, "FogEnd", 100000)
		self:patch("Fog", Lighting, "FogStart", 100000)
	end
	if settings.isNoShadows then self:patch("Shadows", Lighting, "GlobalShadows", false) end
	if settings.isClock then self:patch("Clock", Lighting, "ClockTime", settings.clock) end
end

Runtime.applyCamera = function(self)
	self:disconnect("CameraEffect")
	local camera = Workspace.CurrentCamera
	if camera and self.disableEffect then
		self:connect("CameraEffect", camera.ChildAdded, self.disableEffect)
		for _, effect in ipairs(camera:GetChildren()) do self.disableEffect(effect) end
	end
	self:restore("Fov")
	if self.settings.isFov and Workspace.CurrentCamera then self:patch("Fov", Workspace.CurrentCamera, "FieldOfView", self.settings.fov) end
	if self.spectated then self:spectate(self.spectated) end
end

Runtime.updateStats = function(self)
	local stats = player:FindFirstChild("leaderstats")
	self:setLabel("money", "Argent : " .. tostring(childValue(stats, "Money") or "—"))
	self:setLabel("slot", "Sauvegarde : " .. tostring(childValue(player, "CurrentSaveSlot") or "—"))
	self:setLabel("busy", "Sauvegarde en cours : " .. tostring(childValue(player, "CurrentlySavingOrLoading") == true))
	self:updateCharacter()
end

Runtime.bindValue = function(self, instance)
	if not instance:IsA("ValueBase") then return end
	if instance.Name ~= "Money" and instance.Name ~= "CurrentSaveSlot" and instance.Name ~= "CurrentlySavingOrLoading" then return end
	self:connect(instance, instance.Changed, function() self:updateStats() end)
end

Runtime.bindBackpack = function(self, backpack)
	if not backpack or not backpack:IsA("Backpack") then return end
	self:connect("BackpackAdded", backpack.ChildAdded, function() self:refreshInventory() end)
	self:connect("BackpackRemoved", backpack.ChildRemoved, function() self:refreshInventory() end)
	self:refreshInventory()
end

Runtime.bindCharacter = function(self, character)
	self.serial = self.serial + 1
	local serial = self.serial
	self:stopFly()
	self:restore("Speed"); self:restore("Jump"); self:restore("Noclip")
	self.character, self.humanoid, self.root = character, nil, nil
	if self.flyToggle then self.flyToggle:set(false, false) end
	for _, key in ipairs({"CharacterAdded","CharacterRemoved","Health","MaxHealth","Death"}) do self:disconnect(key) end
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 10)
	if self.isDestroyed or serial ~= self.serial or not humanoid or not root then return end
	self.humanoid, self.root = humanoid, root
	self:connect("CharacterAdded", character.DescendantAdded, function(instance) self:applyCollision(instance); if instance:IsA("Tool") then self:refreshInventory() end end)
	self:connect("CharacterRemoved", character.ChildRemoved, function(instance) if instance:IsA("Tool") then self:refreshInventory() end end)
	self:connect("Health", humanoid.HealthChanged, function() self:updateCharacter() end)
	self:connect("MaxHealth", humanoid:GetPropertyChangedSignal("MaxHealth"), function() self:updateCharacter() end)
	self:connect("Death", humanoid.Died, function() self:stopFly(); if self.flyToggle then self.flyToggle:set(false, false) end end)
	self:updateCharacter(); self:setNoclip(self.settings.isNoclip); self:refreshInventory()
end

Runtime.bind = function(self)
	self:connect("Destroy", self.window.gui.Destroying, function() self:destroy() end)
	self:connect("Spawn", player.CharacterAdded, function(character) self:bindCharacter(character) end)
	self:connect("Despawn", player.CharacterRemoving, function()
		self.serial = self.serial + 1; self:stopFly()
		self:restore("Speed"); self:restore("Jump"); self:restore("Noclip")
		self.character, self.humanoid, self.root = nil, nil, nil
		if self.flyToggle then self.flyToggle:set(false,false) end
	end)
	self:connect("PlayerAdded", Players.PlayerAdded, function() self:refreshPlayers() end)
	self:connect("PlayerRemoved", Players.PlayerRemoving, function(target)
		if self.spectated == target then self:spectate(nil) end
		task.defer(function() if not self.isDestroyed then self:refreshPlayers() end end)
	end)
	self:connect("NewValue", player.DescendantAdded, function(instance) self:bindValue(instance) end)
	self:connect("Backpack", player.ChildAdded, function(instance) self:bindBackpack(instance) end)
	self:connect("Camera", Workspace:GetPropertyChangedSignal("CurrentCamera"), function() self:applyCamera() end)
	self:connect("KeyDown", UserInputService.InputBegan, function(input, isProcessed)
		if not isProcessed and input.KeyCode == Enum.KeyCode.LeftShift then self.isShift = true; self:updateCharacter() end
	end)
	self:connect("KeyUp", UserInputService.InputEnded, function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then self.isShift = false; self:updateCharacter() end
	end)
	self:connect("FocusLost", UserInputService.WindowFocusReleased, function() self.isShift = false; self.settings.vertical = 0; self.window:setFlag("vertical",0,false); self:updateCharacter() end)
	self:connect("AirJump", UserInputService.JumpRequest, function()
		if self.settings.isAirJump and not UserInputService:GetFocusedTextBox() and self.humanoid and self.humanoid.Health > 0 then self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
	for _, instance in ipairs(player:GetDescendants()) do self:bindValue(instance) end
	self:bindBackpack(player:FindFirstChildOfClass("Backpack"))
	if player.Character then task.spawn(function() self:bindCharacter(player.Character) end) end
	self:updateStats(); self:refreshPlayers(); self:refreshCatalog(); self:applyCamera()
end

Runtime.destroy = function(self)
	if self.isDestroyed then return end
	self:stopFly()
	self.isDestroyed = true
	for _, connection in pairs(self.connections) do connection:Disconnect() end
	for instance, properties in pairs(self.patches) do
		for property, record in pairs(properties) do
			record.connection:Disconnect()
			pcall(function() instance[property] = record.original end)
		end
	end
	table.clear(self.connections); table.clear(self.patches)
	self.folder:Destroy()
	self.window:destroy()
end

return Runtime

end)()

local Queue = (function()
local Queue = {}
Queue.__index = Queue

local Context = {}
Context.__index = Context

local function dispose(resources)
	for index = #resources, 1, -1 do
		pcall(resources[index])
	end
	table.clear(resources)
end

local function finishWait(state, ...)
	if state.isDone then return end
	state.isDone = true
	state.result = table.pack(...)
	state.event:Fire()
end

Context.isActive = function(self)
	local app = self.queue.app
	return not self.isCancelled and not app.isDestroyed
		and app.serial == self.serial and app.humanoid ~= nil
		and app.humanoid.Health > 0
end

Context.check = function(self)
	assert(self:isActive(), self.reason or "Opération annulée.")
end

Context.defer = function(self, callback)
	table.insert(self.resources, callback)
	return callback
end

Context.waitFor = function(self, signal, predicate, timeout)
	self:check()
	local state = { event = Instance.new("BindableEvent"), isDone = false }
	local connection = signal and signal:Connect(function(...)
		if not predicate or predicate(...) then finishWait(state, true, ...) end
	end)
	local cancellation = self.cancelled.Event:Connect(function()
		finishWait(state, false, self.reason or "Annulé")
	end)
	local timer = task.delay(timeout, function() finishWait(state, false, "Délai dépassé") end)
	if not self:isActive() then finishWait(state, false, "Annulé") end
	if not state.isDone then state.event.Event:Wait() end
	if connection then connection:Disconnect() end
	cancellation:Disconnect()
	pcall(task.cancel, timer)
	state.event:Destroy()
	self:check()
	return table.unpack(state.result, 1, state.result.n)
end

Context.wait = function(self, duration)
	self:waitFor(nil, nil, math.max(duration, 0.01))
	self:check()
end

Context.untilTrue = function(self, signal, predicate, timeout)
	self:check()
	if predicate() then return true end
	return self:waitFor(signal, predicate, timeout)
end

Context.progress = function(self, text)
	self:check()
	self.queue.app:setLabel("job", self.name .. " · " .. text)
end

Context.cancel = function(self, reason)
	if self.isCancelled then return end
	self.isCancelled = true
	self.reason = reason or "Annulé"
	self.cancelled:Fire()
	dispose(self.resources)
end

Queue.new = function(app)
	return setmetatable({
		app = app,
		pending = {},
		isPaused = false,
		isDestroyed = false,
		remoteLocks = {},
		history = {},
	}, Queue)
end

Queue.update = function(self)
	local prefix = self.isPaused and "En pause" or "En attente"
	self.app:setLabel("queue", string.format("%s · %d tâche(s)", prefix, #self.pending))
end

Queue.push = function(self, name, callback, key)
	assert(not self.isDestroyed, "Session fermée.")
	assert(#self.pending < 100, "File pleine : 100 tâches maximum.")
	if key then
		if self.active and self.active.key == key then return false end
		for _, pending in ipairs(self.pending) do
			if pending.key == key then return false end
		end
	end
	table.insert(self.pending, { name = name, run = callback, key = key })
	self:update()
	self:pump()
	return true
end

Queue.record = function(self, name, isSuccess, message)
	table.insert(self.history, {
		name = name,
		isSuccess = isSuccess,
		message = tostring(message or "Terminé"),
		time = os.time(),
	})
	if #self.history > 50 then table.remove(self.history, 1) end
end

Queue.finish = function(self, context, isSuccess, message)
	dispose(context.resources)
	context.cancelled:Destroy()
	if self.active ~= context then return end
	self.active = nil
	self:record(context.name, isSuccess, message)
	if not self.app.isDestroyed then
		self.app:setLabel("job", isSuccess and "Terminé : " .. context.name or tostring(message))
		if not isSuccess and not context.isCancelled then self.app:notice(message) end
	end
	self:update()
	self:pump()
	if self.app.world then self.app.world:emit() end
end

Queue.pump = function(self)
	if self.active or self.isPaused or self.isDestroyed or #self.pending == 0 then return end
	local item = table.remove(self.pending, 1)
	local context = setmetatable({
		queue = self,
		name = item.name,
		key = item.key,
		serial = self.app.serial,
		resources = {},
		cancelled = Instance.new("BindableEvent"),
		isCancelled = false,
	}, Context)
	self.active = context
	self:update()
	task.spawn(function()
		local isSuccess, message = pcall(function()
			context:check()
			item.run(context)
			context:check()
		end)
		self:finish(context, isSuccess, message)
	end)
end

Queue.setPaused = function(self, isPaused)
	self.isPaused = isPaused
	self:update()
	if not isPaused then self:pump() end
end

Queue.clear = function(self)
	table.clear(self.pending)
	self:update()
end

Queue.stop = function(self, reason)
	self:clear()
	if self.active then self.active:cancel(reason) end
end

Queue.skip = function(self)
	if self.active then self.active:cancel("Tâche ignorée.") end
end

Queue.removeLast = function(self)
	table.remove(self.pending)
	self:update()
end

Queue.reverse = function(self)
	local count = #self.pending
	for index = 1, math.floor(count / 2) do
		local opposite = count - index + 1
		self.pending[index], self.pending[opposite] = self.pending[opposite], self.pending[index]
	end
	self:update()
end

Queue.invoke = function(self, context, remote, timeout, ...)
	context:check()
	assert(remote and remote:IsA("RemoteFunction"), "RemoteFunction indisponible.")
	assert(not self.remoteLocks[remote], "Réponse précédente encore en attente : " .. remote.Name)
	self.remoteLocks[remote] = true
	local args = table.pack(...)
	local result
	local completed = Instance.new("BindableEvent")
	local isListening = true
	task.spawn(function()
		result = table.pack(pcall(function() return remote:InvokeServer(table.unpack(args, 1, args.n)) end))
		self.remoteLocks[remote] = nil
		if isListening then completed:Fire() end
	end)
	local isWaitSuccess, hasCompleted = pcall(function()
		if result then return true end
		return context:waitFor(completed.Event, nil, timeout)
	end)
	isListening = false
	completed:Destroy()
	assert(isWaitSuccess, hasCompleted)
	assert(hasCompleted and result, "Réponse incertaine : opération non répétée.")
	context:check()
	assert(result[1], tostring(result[2]))
	return table.unpack(result, 2, result.n)
end

Queue.destroy = function(self)
	self.isDestroyed = true
	self:stop("Session fermée.")
end

return Queue

end)()

local World = (function()
local World = {}
World.__index = World

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local function childValue(parent, name)
	local child = parent and parent:FindFirstChild(name)
	if child and child:IsA("ValueBase") then return child.Value end
end

local function findPath(parent, path)
	for name in string.gmatch(path, "[^/]+") do
		parent = parent and parent:FindFirstChild(name)
	end
	return parent
end

local function partOf(model)
	if not model or not model.Parent then return nil end
	if model:IsA("BasePart") then return model end
	local primary = model:IsA("Model") and model.PrimaryPart
	return primary or model:FindFirstChildWhichIsA("BasePart", true)
end

local function isFinite(number)
	return type(number) == "number" and number == number and math.abs(number) < math.huge
end

World.new = function(app)
	local changed = Instance.new("BindableEvent")
	changed.Name = "WorldChanged"
	changed.Parent = app.folder
	return setmetatable({ app = app, models = {}, npcs = {}, catalog = {}, revision = 0,
		changed = changed, watched = {}, isPending = false }, World)
end

World.emit = function(self)
	if self.isPending or self.app.isDestroyed then return end
	self.isPending = true
	task.defer(function()
		self.isPending = false
		if not self.app.isDestroyed then self.changed:Fire() end
	end)
end

World.watchMetadata = function(self, instance)
	if self.watched[instance] or not instance:IsA("ValueBase") then return end
	if instance.Name ~= "Owner" and instance.Name ~= "PurchasedBoxItemName" and instance.Name ~= "TreeClass" then return end
	self.watched[instance] = true
	self.app:connect(instance, instance.Changed, function() self:emit() end)
end

World.value = childValue
World.part = partOf
World.path = findPath
World.isFinite = isFinite

World.remote = function(self, path, className)
	local remote = findPath(ReplicatedStorage, path)
	assert(remote and remote:IsA(className or "RemoteEvent"), "Fonction absente : " .. path)
	return remote
end

World.position = function(self, instance)
	local part = partOf(instance)
	return part and part.Position
end

World.money = function(self)
	return childValue(player:FindFirstChild("leaderstats"), "Money") or 0
end

World.owner = function(self, model)
	return childValue(model, "Owner")
end

World.itemName = function(self, model)
	return childValue(model, "PurchasedBoxItemName") or childValue(model, "BoxItemName")
		or childValue(model, "ToolName") or childValue(model, "ItemName") or model.Name
end

World.isOwned = function(self, model)
	return model and model.Parent and self:owner(model) == player
end

World.isLoose = function(self, model)
	local part = partOf(model)
	if not part or part.Anchored then return false end
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") and child.Anchored then return false end
		if (child:IsA("Seat") or child:IsA("VehicleSeat")) and child.Occupant then return false end
	end
	return true
end

World.canInteract = function(self, model, kind)
	if not model or not model.Parent then return false end
	if self.permission then
		local isSuccess, canInteract = pcall(function()
			return self.permission:UserCanInteract(player, model, kind or "Grab")
		end)
		return isSuccess and canInteract == true
	end
	return self:isOwned(model)
end

World.resolve = function(self, instance)
	while instance and instance ~= Workspace do
		if instance:IsA("Model") and (
			instance:FindFirstChild("TreeClass") or instance:FindFirstChild("Owner")
			or instance:FindFirstChild("ItemName") or instance:FindFirstChild("ToolName")
			or instance:FindFirstChild("BoxItemName") or instance:FindFirstChild("PurchasedBoxItemName")
		) then return instance end
		instance = instance.Parent
	end
end

World.track = function(self, instance)
	if instance:IsDescendantOf(self.app.folder) then return end
	self:watchMetadata(instance)
	local model = instance:IsA("Model") and instance or instance.Parent
	if model and model:IsA("Model") and self:resolve(model) == model then
		self.models[model] = true
	end
	local candidate = instance:FindFirstChild("Dialog") and instance or instance.Parent
	if candidate and candidate:FindFirstChild("Dialog") and candidate:FindFirstChild("Character") then
		self.npcs[candidate] = true
	end
	self.revision = self.revision + 1
	self:emit()
end

World.untrack = function(self, instance)
	if self.watched[instance] then
		self.app:disconnect(instance)
		self.watched[instance] = nil
	end
	self.models[instance] = nil
	self.npcs[instance] = nil
	self.revision = self.revision + 1
	self:emit()
end

World.bind = function(self)
	local module = findPath(ReplicatedStorage, "Interaction/InteractionPermission")
	if module and module:IsA("ModuleScript") then
		local isSuccess, permission = pcall(require, module)
		if isSuccess then self.permission = permission end
	end
	self.app:connect("IndexAdded", Workspace.DescendantAdded, function(instance) self:track(instance) end)
	self.app:connect("IndexRemoved", Workspace.DescendantRemoving, function(instance) self:untrack(instance) end)
	for _, instance in ipairs(Workspace:GetDescendants()) do self:track(instance) end
	self:refreshCatalog()
end

World.refreshCatalog = function(self)
	table.clear(self.catalog)
	local catalog = ReplicatedStorage:FindFirstChild("ClientItemInfo")
	if not catalog then return end
	for _, item in ipairs(catalog:GetDescendants()) do
		if item:FindFirstChild("Price") and item:FindFirstChild("ItemName") then
			local price = childValue(item, "Price")
			if isFinite(price) and price >= 0 then self.catalog[item.Name] = item end
		end
	end
end

World.list = function(self, predicate, origin, limit)
	local candidates = {}
	for model in pairs(self.models) do
		local part = partOf(model)
		if part and (not predicate or predicate(model, part)) then
			table.insert(candidates, {
				model = model,
				distance = origin and (part.Position - origin).Magnitude or 0,
				id = self.app:identifier(model),
			})
		end
	end
	table.sort(candidates, function(first, second)
		if first.distance == second.distance then return first.id < second.id end
		return first.distance < second.distance
	end)
	local models = {}
	for index = 1, math.min(#candidates, limit or #candidates) do
		models[index] = candidates[index].model
	end
	return models
end

World.owned = function(self, category, radius)
	local origin = self.app.root and self.app.root.Position
	return self:list(function(model, part)
		if not self:isOwned(model) then return false end
		if radius and origin and (part.Position - origin).Magnitude > radius then return false end
		if category == "Tout" then return true end
		if category == "Bois" then return model:FindFirstChild("TreeClass") ~= nil end
		if category == "Boîtes" then return model:FindFirstChild("PurchasedBoxItemName") ~= nil end
		if category == "Outils" then return model:FindFirstChild("ToolName") ~= nil end
		if category == "Véhicules" then return model:FindFirstChild("DriveSeat", true) ~= nil end
		return tostring(childValue(model, "Type")) == category
	end, origin)
end

World.stock = function(self, itemName, store)
	return self:list(function(model)
		if self:owner(model) ~= nil then return false end
		if childValue(model, "BoxItemName") ~= itemName then return false end
		return not store or model:IsDescendantOf(store)
	end, self.app.root and self.app.root.Position)
end

World.trees = function(self, treeClass, radius)
	local origin = self.app.root and self.app.root.Position
	return self:list(function(model, part)
		local class = childValue(model, "TreeClass")
		if not class or not model:FindFirstChild("CutEvent") then return false end
		local isStanding = false
		for _, section in ipairs(model:GetChildren()) do
			if section:IsA("BasePart") and section.Anchored and section:FindFirstChild("ID") then isStanding = true; break end
		end
		if not isStanding then return false end
		if treeClass ~= "Toutes" and class ~= treeClass then return false end
		if radius and origin and (part.Position - origin).Magnitude > radius then return false end
		local owner = self:owner(model)
		return (owner == nil or owner == player) and self:canInteract(model, "Interact")
	end, origin)
end

World.treeClasses = function(self)
	local classes = { Toutes = true }
	for model in pairs(self.models) do
		local class = childValue(model, "TreeClass")
		if type(class) == "string" then classes[class] = true end
	end
	local names = {}
	for name in pairs(classes) do table.insert(names, name) end
	table.sort(names)
	return names
end

World.npcOptions = function(self)
	local options = {}
	for npc in pairs(self.npcs) do
		if npc.Parent then options[npc.Name .. " [" .. self.app:identifier(npc) .. "]"] = npc end
	end
	return options
end

World.modelOptions = function(self, models)
	local options = {}
	for _, model in ipairs(models) do
		options[self:itemName(model) .. " [" .. self.app:identifier(model) .. "]"] = model
	end
	return options
end

World.requireReady = function(self)
	assert(self.app.root and self.app.humanoid and self.app.humanoid.Health > 0, "Personnage indisponible.")
	assert(childValue(player, "CurrentlySavingOrLoading") ~= true, "Sauvegarde ou chargement en cours.")
end

World.requireOwned = function(self, model)
	self:requireReady()
	assert(self:isOwned(model), "Sélectionnez un objet qui vous appartient.")
end

World.requireLoose = function(self, model, canUseStock)
	self:requireReady()
	assert(model and model.Parent, "Objet absent.")
	assert(self:isOwned(model) or (canUseStock and self:owner(model) == nil), "Propriétaire incompatible.")
	assert(self:isLoose(model), "Objet ancré ou véhicule occupé.")
	assert(self:canInteract(model, "Grab"), "Le jeu refuse le déplacement de cet objet.")
end

return World

end)()

local Actions = (function()
local Actions = {}
Actions.__index = Actions

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local function create(className, parent, properties)
	local instance = Instance.new(className)
	for property, value in pairs(properties) do instance[property] = value end
	instance.Parent = parent
	return instance
end

local function stopAssembly(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function makeRig(part, speed)
	local attachment = create("Attachment", part, { Name = "UnderlordCarry" })
	local position = create("AlignPosition", part, {
		Name = "UnderlordCarryPosition",
		Mode = Enum.PositionAlignmentMode.OneAttachment,
		Attachment0 = attachment,
		Position = part.Position,
		MaxForce = math.max(17000, part.AssemblyMass * 1000),
		MaxVelocity = speed,
		Responsiveness = 35,
		ApplyAtCenterOfMass = true,
	})
	local orientation = create("AlignOrientation", part, {
		Name = "UnderlordCarryOrientation",
		Mode = Enum.OrientationAlignmentMode.OneAttachment,
		Attachment0 = attachment,
		CFrame = part.CFrame.Rotation,
		MaxTorque = math.max(20000, part.AssemblyMass * 2000),
		Responsiveness = 25,
	})
	return attachment, position, orientation
end

Actions.new = function(app)
	return setmetatable({ app = app, points = {}, undo = {}, selection = nil }, Actions)
end

Actions.point = function(self, name)
	local point = self.points[name]
	assert(point, "Enregistrez le point « " .. name .. " » d’abord.")
	return point
end

Actions.capturePoint = function(self, name, shouldUseMouse)
	self.app.world:requireReady()
	local frame = self.app.root.CFrame
	if shouldUseMouse then
		local mouse = player:GetMouse()
		assert(mouse.Target, "Visez une surface du monde.")
		frame = CFrame.new(mouse.Hit.Position) * frame.Rotation
	end
	self.points[name] = frame
	self.app:notice("Point enregistré : " .. name)
end

Actions.captureSelection = function(self)
	local target = player:GetMouse().Target
	local model = self.app.world:resolve(target)
	assert(model, "Visez un objet, un arbre ou un véhicule.")
	self.selection = model
	self.app:mark("Selection", model)
	self.app:setLabel("selection", self.app.world:itemName(model))
	return model
end

Actions.selected = function(self)
	assert(self.selection and self.selection.Parent, "Aucun objet sélectionné. Utilisez la touche de sélection.")
	return self.selection
end

Actions.remember = function(self, model)
	table.insert(self.undo, { model = model, pivot = model:GetPivot() })
	if #self.undo > 50 then table.remove(self.undo, 1) end
end

Actions.claim = function(self, model, context, canUseStock)
	self.app.world:requireLoose(model, canUseStock)
	self.app.humanoid:UnequipTools()
	local part = self.app.world.part(model)
	self.app:teleport(part.Position + Vector3.new(0, 4, 6), false)
	context:wait(0.2)
	context:check()
	local remote = self.app.world:remote("Interaction/ClientIsDragging")
	remote:FireServer(model)
	context:wait(0.6)
	self.app.world:requireLoose(model, canUseStock)
	return part, remote
end

Actions.carryStep = function(self, context, model, rig, target, remote, state, canUseStock)
	context:check()
	self.app.world:requireLoose(model, canUseStock)
	local part = rig.part
	local remaining = target.Position - part.Position
	local step = remaining.Magnitude > 5 and remaining.Unit * 5 or remaining
	local nextPosition = part.Position + step
	if (self.app.root.Position - nextPosition).Magnitude > 8 then
		self.app:teleport(nextPosition + Vector3.new(0, 4, 5), false)
	end
	rig.position.Position = nextPosition
	rig.orientation.CFrame = target.Rotation
	if os.clock() - state.lastClaim >= 0.5 then
		remote:FireServer(model)
		state.lastClaim = os.clock()
	end
	context:wait(0.1)
	return (part.Position - target.Position).Magnitude
end

Actions.carry = function(self, context, model, destination, canUseStock, shouldRemember, canBeConsumed)
	context:check()
	local part, remote = self:claim(model, context, canUseStock)
	if shouldRemember ~= false and self.app.world:isOwned(model) then self:remember(model) end
	local offset = model:GetPivot():ToObjectSpace(part.CFrame)
	local target = destination * offset
	local attachment, position, orientation = makeRig(part, self.app.settings.carrySpeed)
	local isReleased = false
	local release = context:defer(function()
		if isReleased then return end
		isReleased = true
		position:Destroy()
		orientation:Destroy()
		attachment:Destroy()
	end)
	self:carryUntil(context, model, { part = part, position = position, orientation = orientation }, target, remote, canUseStock, canBeConsumed)
	release()
	if model.Parent then stopAssembly(model) end
	context:wait(0.3)
	if canBeConsumed and not model.Parent then return end
	assert((part.Position - target.Position).Magnitude < 7, "Le déplacement n’a pas tenu ; le serveur peut l’avoir refusé.")
end

Actions.carryUntil = function(self, context, model, rig, target, remote, canUseStock, canBeConsumed)
	local start = rig.part.Position
	local deadline = os.clock() + math.clamp((start - target.Position).Magnitude / 12 + 12, 15, 180)
	local state = { lastClaim = 0 }
	local lastPosition, lastProgress = start, os.clock()
	while true do
		if canBeConsumed and not model.Parent and (rig.part.Position - target.Position).Magnitude < 8 then return end
		local distance = self:carryStep(context, model, rig, target, remote, state, canUseStock)
		if distance < 1.5 then return end
		if (rig.part.Position - lastPosition).Magnitude > 0.5 then
			lastPosition, lastProgress = rig.part.Position, os.clock()
		end
		assert(os.clock() - lastProgress < 5, "Objet bloqué ou contrôle physique refusé.")
		assert(os.clock() < deadline, "Transport trop long ; tâche arrêtée.")
	end
end

Actions.destination = function(self, name)
	if name == "Base" then
		local property = self.app:ownProperty()
		assert(property, "Aucune propriété chargée.")
		local position = self.app.world:position(property)
		assert(position, "Terrain non chargé.")
		return CFrame.new(position + Vector3.new(0, 6, 0))
	end
	if name == "Devant moi" then
		self.app.world:requireReady()
		return self.app.root.CFrame * CFrame.new(0, 1, -7)
	end
	return self:point(name)
end

Actions.moveSelection = function(self, destination)
	local model = self:selected()
	local frame = self:destination(destination)
	self.app.queue:push("Transport · " .. self.app.world:itemName(model), function(context)
		self:carry(context, model, frame)
	end)
end

Actions.transform = function(self, transform)
	local model = self:selected()
	self.app.world:requireOwned(model)
	local target = transform(model:GetPivot())
	self.app.queue:push("Ajuster l’objet", function(context) self:carry(context, model, target) end)
end

Actions.undoLast = function(self)
	local entry = table.remove(self.undo)
	assert(entry, "Aucun déplacement à annuler.")
	self.app.queue:push("Annuler le déplacement", function(context)
		self:carry(context, entry.model, entry.pivot, false, false)
	end)
end

Actions.interact = function(self, context, model, action, beforeSend)
	context:check()
	self.app.world:requireOwned(model)
	assert(self.app.world:canInteract(model, "Interact"), "Interaction refusée.")
	local part = self.app.world.part(model)
	assert(part, "Objet non chargé.")
	self.app:teleport(part.Position + Vector3.new(0, 3, 4), false)
	self.app.humanoid:UnequipTools()
	context:wait(0.25)
	context:check()
	self.app.world:requireOwned(model)
	if beforeSend then beforeSend() end
	self.app.world:remote("Interaction/ClientInteracted"):FireServer(model, action)
end

Actions.pickup = function(self, context, model)
	assert(model:FindFirstChild("ToolName"), "Cet objet n’est pas un outil au sol.")
	local name = self.app.world:itemName(model)
	self:interact(context, model, "Pick up tool")
	local backpack = player:FindFirstChildOfClass("Backpack")
	assert(backpack, "Inventaire indisponible.")
	context:wait(0.3)
	local function hasTool()
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name == name or self.app.world.value(tool, "ToolName") == name) then return true end
		end
		return false
	end
	local hasPicked = hasTool()
	if not hasPicked then
		hasPicked = context:waitFor(backpack.ChildAdded, function(tool)
			return tool:IsA("Tool") and (tool.Name == name or self.app.world.value(tool, "ToolName") == name)
		end, 4)
	end
	assert(hasPicked, "Ramassage non confirmé.")
end

Actions.pickupNearby = function(self)
	local models = self.app.world:owned("Outils", self.app.settings.workRadius)
	assert(#models > 0, "Aucun de vos outils au sol à proximité.")
	self.app.queue:push("Ramasser les outils", function(context)
		for index, model in ipairs(models) do
			context:progress(index .. " / " .. #models)
			if model.Parent then self:pickup(context, model) end
		end
	end, "PickupTools")
end

Actions.dropEquipped = function(self, context)
	context:check()
	self.app.world:requireReady()
	local tool = self.app.character:FindFirstChildOfClass("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	assert(handle and handle:IsA("BasePart"), "Équipez un outil à déposer.")
	assert(tool.Name ~= "BlueprintTool", "Cet outil ne peut pas être déposé.")
	local frame = handle.CFrame
	self.app.humanoid:UnequipTools()
	self.app.world:remote("Interaction/ClientInteracted"):FireServer(tool, "Drop tool", frame)
	local hasDropped = context:untilTrue(tool.AncestryChanged, function()
		return not tool:IsDescendantOf(player) and not tool:IsDescendantOf(self.app.character)
	end, 5)
	assert(hasDropped, "Dépôt non confirmé.")
end

Actions.pressButton = function(self, context, part)
	context:check()
	local model = self.app.world:resolve(part)
	self.app.world:requireOwned(model)
	assert(part and part:IsA("BasePart"), "Visez le bouton d’une machine.")
	local remote = model:FindFirstChild("ButtonRemote_" .. part.Name)
		or part.Parent:FindFirstChild("ButtonRemote_" .. part.Name)
	assert(remote, "Ce bouton n’utilise pas l’interaction reconnue.")
	assert(self.app.world:canInteract(model, "Interact"), "Interaction refusée.")
	self.app:teleport(part.Position + Vector3.new(0, 3, 4), false)
	context:wait(0.25)
	self.app.world:requireOwned(model)
	self.app.world:remote("Interaction/RemoteProxy"):FireServer(remote)
end

Actions.flatten = function(self)
	self:transform(function(frame)
		local _, yaw = frame:ToOrientation()
		return CFrame.new(frame.Position) * CFrame.Angles(0, yaw, 0)
	end)
end

Actions.snap = function(self)
	local grid = self.app.settings.gridSize
	self:transform(function(frame)
		local position = frame.Position
		return CFrame.new(
			math.round(position.X / grid) * grid,
			position.Y,
			math.round(position.Z / grid) * grid
		) * frame.Rotation
	end)
end

Actions.freezeSelection = function(self)
	local model = self:selected()
	self.app.world:requireOwned(model)
	stopAssembly(model)
end

Actions.returnHome = function(self)
	self.app:teleport(self:destination("Base").Position)
end

Actions.bind = function(self)
	local busy = player:FindFirstChild("CurrentlySavingOrLoading")
	if busy then
		self.app:connect("CancelOnSave", busy.Changed, function()
			if busy.Value then self.app.queue:stop("Sauvegarde ou chargement : tâches arrêtées.") end
		end)
	end
	self.app:connect("JobsDespawn", player.CharacterRemoving, function()
		self.app.queue:stop("Personnage retiré.")
	end)
end

return Actions

end)()

local AxeSpecs = (function()
local AxeSpecs = {}

AxeSpecs.Axe1 = {
	damage = 0.55,
	range = 10,
	cooldown = 0.73,
}

AxeSpecs.Axe2 = {
	damage = 0.93,
	range = 10,
	cooldown = 0.7,
}

AxeSpecs.Axe3 = {
	damage = 1.45,
	range = 10,
	cooldown = 0.65,
}

AxeSpecs.AxeAlphaTesters = {
	damage = 1.5,
	range = 10,
	cooldown = 0.5,
}

AxeSpecs.AxeAmber = {
	damage = 3.39,
	range = 9,
	cooldown = 1,
}

AxeSpecs.AxeBetaTesters = {
	damage = 1.45,
	range = 10,
	cooldown = 0.54,
}

AxeSpecs.AxeChicken = {
	damage = 0.9,
	range = 10,
	cooldown = 0.3,
}

AxeSpecs.AxePie = {
	damage = 0.95,
	range = 15.5,
	cooldown = 0.3,
	special = {
		Cherry = { damage = 1.9, cooldown = 0.25 },
	},
}

AxeSpecs.AxePig = {
	damage = 1.5,
	range = 10,
	cooldown = 0.5,
}

AxeSpecs.AxeSwamp = {
	damage = 0.8,
	range = 9,
	cooldown = 0.55,
	special = {
		GoldSwampy = { damage = 5.35, cooldown = 0.35 },
		GreenSwampy = { damage = 7, cooldown = 0.46 },
	},
}

AxeSpecs.AxeTwitter = {
	damage = 1.65,
	range = 16,
	cooldown = 0.4,
	special = {
		Volcano = { damage = 2.5, cooldown = 0.4 },
		CaveCrawler = { damage = 3.9, cooldown = 0.4 },
	},
}

AxeSpecs.BasicHatchet = {
	damage = 0.2,
	range = 10,
	cooldown = 0.65,
}

AxeSpecs.Beesaxe = {
	damage = 1.4,
	range = 13,
	cooldown = 0.5,
}

AxeSpecs.BluesteelAxe = {
	damage = 2.8,
	range = 12,
	cooldown = 0.8,
	special = {
		BlueSpruce = { damage = 12.1, cooldown = 0.68 },
	},
}

AxeSpecs.CandyCaneAxe = {
	damage = 0,
	range = 6,
	cooldown = 0.7,
}

AxeSpecs.CandyCornAxe = {
	damage = 1.75,
	range = 16,
	cooldown = 0.6,
}

AxeSpecs.CaveAxe = {
	damage = 0.4,
	range = 10,
	cooldown = 0.4,
	special = {
		CaveCrawler = { damage = 7.2, cooldown = 0.22 },
	},
}

AxeSpecs.EndTimesAxe = {
	damage = 1.58,
	range = 9,
	cooldown = 0.4,
	special = {
		LoneCave = { cooldown = 0.3 },
	},
}

AxeSpecs.FireAxe = {
	damage = 0.6,
	range = 9,
	cooldown = 0.55,
	special = {
		Volcano = { damage = 6.35, cooldown = 0.35 },
	},
}

AxeSpecs.GingerbreadAxe = {
	damage = 1.2,
	range = 32,
	cooldown = 0.5,
	special = {
		Koa = { damage = 11, cooldown = 0.4 },
		Walnut = { damage = 8.5, cooldown = 0.4 },
	},
}

AxeSpecs.GlorbAxe = {
	damage = 1.8,
	range = 10,
	cooldown = 0.38,
}

AxeSpecs.IceAxe = {
	damage = 0.36,
	range = 9.2,
	cooldown = 0.4,
	special = {
		Frost = { damage = 6, cooldown = 0.31 },
	},
}

AxeSpecs.InverseAxe = {
	damage = -1,
	range = 12,
	cooldown = 0.4,
}

AxeSpecs.ManyAxe = {
	damage = 10.2,
	range = 16,
	cooldown = 1.9,
}

AxeSpecs.MintAxe = {
	damage = 0.8,
	range = 1,
	cooldown = 5,
}

AxeSpecs.RefinedAxe = {
	damage = 0,
	range = 13,
	cooldown = 0.6,
	processedDamage = 12,
}

AxeSpecs.Rukiryaxe = {
	damage = 1.68,
	range = 9,
	cooldown = 0.4,
}

AxeSpecs.RustyAxe = {
	damage = 0.55,
	range = 10,
	cooldown = 0.4,
}

AxeSpecs.SilverAxe = {
	damage = 1.6,
	range = 10,
	cooldown = 0.48,
}

AxeSpecs.SpookyAxe = {
	damage = 0.2,
	range = 10,
	cooldown = 0.8,
	special = {
		SpookyNeon = { damage = 8.2, cooldown = 0.6 },
		Spooky = { damage = 8.2, cooldown = 0.6 },
	},
}

return AxeSpecs

end)()

local Timber = (function()
local Timber = {}
Timber.__index = Timber

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local function roundedNormal(normal)
	return Vector3.new(math.round(normal.X), math.round(normal.Y), math.round(normal.Z))
end

local function cutFace(part, normal, head, hit)
	local face = roundedNormal(part.CFrame:VectorToObjectSpace(normal))
	if face.Y ~= 0 then return nil end
	local reference = CFrame.lookAt(head, hit):ToObjectSpace(part.CFrame * CFrame.Angles(math.pi / 2, 0, 0))
	local direction = reference.LookVector.Y >= 0 and 1 or -1
	if face.X == 1 then return Vector3.new(0, 0, -direction) end
	if face.X == -1 then return Vector3.new(0, 0, direction) end
	if face.Z == 1 then return Vector3.new(direction, 0, 0) end
	if face.Z == -1 then return Vector3.new(-direction, 0, 0) end
end

Timber.new = function(app, specs)
	return setmetatable({ app = app, specs = specs, lastSwing = 0, completed = 0 }, Timber)
end

Timber.stats = function(self, tool, tree)
	local name = self.app.world.value(tool, "ToolName") or tool.Name
	local spec = self.specs[name]
	if not spec then return nil end
	local class = self.app.world.value(tree, "TreeClass")
	local special = spec.special and spec.special[class]
	local damage = special and special.damage or spec.damage
	local cooldown = special and special.cooldown or spec.cooldown
	local models = Workspace:FindFirstChild("PlayerModels")
	local isProcessed = models and tree and tree:IsDescendantOf(models)
	if not special and isProcessed and spec.processedDamage then damage = spec.processedDamage end
	if name == "EndTimesAxe" and class == "LoneCave" then
		local bridge = Workspace:FindFirstChild("Bridge")
		damage = ((bridge and bridge:HasTag("Set")) or isProcessed) and 10000000 or 1
	end
	return { damage = damage, cooldown = cooldown, range = spec.range }
end

Timber.bestAxe = function(self, tree)
	self.app:refreshInventory()
	local best, bestStats, score = nil, nil, -math.huge
	for _, tool in pairs(self.app.tools) do
		local stats = self:stats(tool, tree)
		if stats and stats.damage > 0 then
			local candidate = stats.damage / stats.cooldown
			if candidate > score then best, bestStats, score = tool, stats, candidate end
		end
	end
	return best, bestStats
end

Timber.equipBest = function(self, tree)
	self.app.world:requireReady()
	local tool, stats = self:bestAxe(tree)
	assert(tool, "Aucune hache compatible possédée.")
	self.app.humanoid:EquipTool(tool)
	return tool, stats
end

Timber.section = function(self, tree)
	local selected, lowest = nil, math.huge
	for _, part in ipairs(tree:GetChildren()) do
		if part:IsA("BasePart") and part:FindFirstChild("ID") then
			local bottom = (part.CFrame * CFrame.new(0, -part.Size.Y / 2, 0)).Position.Y
			if bottom < lowest then selected, lowest = part, bottom end
		end
	end
	return selected
end

Timber.cutPosition = function(self, part)
	local height = math.clamp(self.app.settings.cutHeight, 0.1, math.max(0.1, part.Size.Y - 0.1))
	local center = part.CFrame * CFrame.new(0, height - part.Size.Y / 2, 0)
	return center.Position, height
end

Timber.approach = function(self, context, part, range)
	local hit = self:cutPosition(part)
	local width = math.min(part.Size.X, part.Size.Z) / 2
	local distance = math.min(range * 0.6, width + 4)
	local offset = part.CFrame.RightVector * distance
	if part.Size.Z < part.Size.X then offset = part.CFrame.LookVector * distance end
	local target = hit + offset + Vector3.new(0, 2, 0)
	self.app:teleport(target, false)
	context:wait(0.25)
end

Timber.payload = function(self, part, tool, stats)
	local head = self.app.character:FindFirstChild("Head")
	assert(head, "Tête du personnage indisponible.")
	local hit, height = self:cutPosition(part)
	local direction = hit - head.Position
	assert(direction.Magnitude > 0 and direction.Magnitude < stats.range, "Arbre hors de portée.")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.app.character, self.app.folder }
	params.IgnoreWater = true
	local result = Workspace:Raycast(head.Position, direction.Unit * stats.range, params)
	assert(result and result.Instance == part, "Coupe bloquée par un obstacle.")
	local face = cutFace(part, result.Normal, head.Position, hit)
	assert(face, "Visez le côté du tronc.")
	return {
		cuttingClass = "Axe",
		sectionId = self.app.world.value(part, "ID"),
		faceVector = face,
		height = height,
		hitPoints = stats.damage,
		cooldown = 0.65 * stats.cooldown,
		tool = tool,
	}
end

Timber.hit = function(self, context, tree, part, tool, stats)
	context:check()
	self.app.world:requireReady()
	assert(tool.Parent == self.app.character, "La hache a été déséquipée.")
	assert(self.app.world:canInteract(tree, "Interact"), "Vous ne pouvez pas couper ce bois.")
	local remaining = stats.cooldown - (os.clock() - self.lastSwing)
	if remaining > 0 then context:wait(remaining) end
	local payload = self:payload(part, tool, stats)
	local cutEvent = tree:FindFirstChild("CutEvent")
	assert(cutEvent and payload.sectionId ~= nil, "Section de coupe disparue.")
	self.app.world:remote("Interaction/RemoteProxy"):FireServer(cutEvent, payload)
	self.lastSwing = os.clock()
end

Timber.chop = function(self, context, tree, isSingleHit)
	assert(tree and tree.Parent, "Arbre absent.")
	local part = self:section(tree)
	assert(part, "Aucune section de bois exploitable.")
	local tool, stats = self:equipBest(tree)
	local initialSize, wasAnchored, initialParent = part.Size, part.Anchored, tree.Parent
	self:approach(context, part, stats.range)
	for swing = 1, isSingleHit and 1 or self.app.settings.maxSwings do
		context:check()
		if not part.Parent or not tree.Parent then return true end
		if part.Size ~= initialSize or tree.Parent ~= initialParent or (wasAnchored and not part.Anchored) then
			self.completed = self.completed + 1
			return true
		end
		context:progress("Coup " .. swing .. " · " .. tostring(self.app.world.value(tree, "TreeClass")))
		self:hit(context, tree, part, tool, stats)
		context:wait(stats.cooldown + 0.08)
	end
	if isSingleHit then return false end
	if not part.Parent or not tree.Parent or part.Size ~= initialSize or tree.Parent ~= initialParent or (wasAnchored and not part.Anchored) then
		self.completed = self.completed + 1
		return true
	end
	error("Limite de coups atteinte ; aucune coupe confirmée.", 0)
end

Timber.selected = function(self)
	local model = self.app.actions:selected()
	assert(model:FindFirstChild("TreeClass"), "La sélection n’est pas du bois.")
	return model
end

Timber.nearest = function(self)
	local trees = self.app.world:trees(self.app.settings.woodClass, self.app.settings.treeRadius)
	assert(trees[1], "Aucun arbre compatible chargé dans le rayon choisi.")
	return trees[1]
end

Timber.queueSelected = function(self, isSingleHit)
	local tree = self:selected()
	self.app.queue:push(isSingleHit and "Un coup de hache" or "Couper la sélection", function(context)
		self:chop(context, tree, isSingleHit)
	end, "ChopSelected")
end

Timber.queueNearest = function(self)
	local tree = self:nearest()
	self.app.queue:push("Couper l’arbre proche", function(context) self:chop(context, tree) end, "ChopNearest")
end

Timber.harvest = function(self)
	local trees = self.app.world:trees(self.app.settings.woodClass, self.app.settings.treeRadius)
	local limit = math.min(#trees, self.app.settings.treeLimit)
	assert(limit > 0, "Aucun arbre compatible.")
	self.app.queue:push("Coupe en série", function(context)
		for index = 1, limit do
			local tree = trees[index]
			context:progress(index .. " / " .. limit)
			if tree.Parent then self:chop(context, tree) end
		end
	end, "Harvest")
end

Timber.transportLogs = function(self, pointName)
	local destination = self.app.actions:destination(pointName)
	local logs = self.app.world:owned("Bois", self.app.settings.workRadius)
	self.app.workshop:arrange(logs, destination, "Grille", "Transporter le bois")
end

Timber.processOne = function(self)
	local model = self:selected()
	self.app.world:requireOwned(model)
	local entry = self.app.actions:point("Scierie")
	self.app.queue:push("Alimenter la scierie", function(context)
		self.app.actions:carry(context, model, entry, false, nil, true)
	end)
end

Timber.processAll = function(self)
	local entry = self.app.actions:point("Scierie")
	local logs = self.app.world:owned("Bois", self.app.settings.workRadius)
	self.app.queue:push("Alimentation de la scierie", function(context)
		for index, model in ipairs(logs) do
			context:progress(index .. " / " .. #logs)
			if model.Parent and self.app.world:isLoose(model) then
				self.app.actions:carry(context, model, entry, false, nil, true)
				context:wait(self.app.settings.feedDelay)
			end
		end
	end, "Sawmill")
end

Timber.sell = function(self, isBatch)
	local destination = self.app.actions:point("Vente")
	local logs = isBatch and self.app.world:owned("Bois", self.app.settings.workRadius) or { self:selected() }
	self.app.queue:push("Livrer le bois à la vente", function(context)
		for index, model in ipairs(logs) do
			context:progress(index .. " / " .. #logs)
			self.app.world:requireOwned(model)
			self.app.actions:carry(context, model, destination, false, nil, true)
			context:wait(self.app.settings.feedDelay)
		end
	end, "SellWood")
end

return Timber

end)()

local Market = (function()
local Market = {}
Market.__index = Market

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function choicesOf(dialog)
	local choices = {}
	if typeof(dialog) ~= "Instance" then return choices end
	for _, choice in ipairs(dialog:GetChildren()) do
		if choice:IsA("DialogChoice") then
			choices[choice.Name .. " · " .. choice.UserDialog] = choice
		end
	end
	return choices
end

Market.new = function(app)
	return setmetatable({
		app = app,
		cart = {},
		path = {},
		learnedPath = {},
		choices = {},
		spent = 0,
		purchased = 0,
		isClosing = false,
	}, Market)
end

Market.setNpc = function(self, npc)
	assert(not self.npc, "Terminez le dialogue en cours avant de changer de marchand.")
	self.selectedNpc = npc
	self.learnedNpc = nil
	table.clear(self.learnedPath)
end

Market.renderDialog = function(self, dialog)
	self.dialog = dialog
	self.choices = choicesOf(dialog)
	self.app.marketChoices = self.choices
	self.app:selectOptions("marketChoices", self.choices)
	local text = typeof(dialog) == "Instance" and dialog.ResponseDialog or "Dialogue terminé"
	self.app:setLabel("dialog", tostring(text))
end

Market.requireBudget = function(self, price, subtotal)
	assert(self.app.world.isFinite(price) and price >= 0, "Prix invalide.")
	assert(price <= self.app.settings.maxPrice, "Prix unitaire supérieur à votre limite.")
	assert(subtotal + price <= self.app.settings.buyBudget, "Budget de cette série atteint.")
	assert(self.app.world:money() - price >= self.app.settings.moneyReserve, "Réserve d’argent atteinte.")
end

Market.price = function(self, itemName)
	local item = self.app.world.catalog[itemName]
	assert(item, "Prix catalogue absent pour cet article.")
	local price = self.app.world.value(item, "Price")
	assert(self.app.world.isFinite(price) and price >= 0, "Prix catalogue invalide.")
	return price
end

Market.open = function(self, context, npc)
	assert(not self.isClosing, "Fermeture du dialogue précédent en cours.")
	assert(not self.npc, "Un dialogue marchand est déjà ouvert.")
	assert(npc and npc.Parent and npc:FindFirstChild("Dialog"), "Sélectionnez un marchand chargé.")
	self.app.world:requireReady()
	local character = npc:FindFirstChild("Character")
	local head = character and character:FindFirstChild("Head")
	assert(head, "Personnage du marchand non chargé.")
	self.app:teleport(head.Position + head.CFrame.LookVector * 5, false)
	context:wait(0.25)
	self.npc = npc
	local stateRemote = self.app.world:remote("NPCDialog/SetChattingValue", "RemoteFunction")
	local chatRemote = self.app.world:remote("NPCDialog/PlayerChatted", "RemoteFunction")
	self.app.queue:invoke(context, stateRemote, 8, 2)
	local dialog = self.app.queue:invoke(context, chatRemote, 8, npc, "Initiate")
	self:renderDialog(dialog or npc.Dialog)
	return self.dialog
end

Market.close = function(self)
	local npc = self.npc
	if not npc or self.isClosing then return end
	self.npc = nil
	self.isClosing = true
	self:renderDialog(nil)
	local chat = self.app.world:remote("NPCDialog/PlayerChatted", "RemoteFunction")
	local state = self.app.world:remote("NPCDialog/SetChattingValue", "RemoteFunction")
	local locks = self.app.queue.remoteLocks
	if locks[chat] or locks[state] then
		self.app:notice("Dialogue sans réponse : fermeture automatique suspendue. Rejoignez une nouvelle session si nécessaire.")
		return
	end
	locks[chat], locks[state] = true, true
	task.spawn(function()
		pcall(function() chat:InvokeServer(npc, "EndChat") end)
		pcall(function() state:InvokeServer(0) end)
		locks[chat], locks[state] = nil, nil
		self.isClosing = false
	end)
end

Market.choose = function(self, context, choice)
	assert(self.npc and self.npc.Parent, "Ouvrez le dialogue d’abord.")
	assert(choice and choice.Parent == self.dialog, "Ce choix ne fait plus partie du dialogue actuel.")
	local remote = self.app.world:remote("NPCDialog/PlayerChatted", "RemoteFunction")
	local dialog = self.app.queue:invoke(context, remote, 8, self.npc, choice.Name)
	self:renderDialog(dialog or choice)
	return self.dialog
end

Market.beginLearning = function(self)
	local npc = self.selectedNpc
	self.app.queue:push("Dialogue marchand", function(context)
		table.clear(self.path)
		local isSuccess, message = pcall(function() self:open(context, npc) end)
		if not isSuccess then self:close(); error(message, 0) end
	end, "LearnDialogue")
end

Market.learnChoice = function(self, label)
	local choice = self.choices[label]
	self.app.queue:push("Choix marchand", function(context)
		assert(choice, "Sélectionnez une réponse réelle du marchand.")
		assert(#self.path < 8, "Parcours limité à huit choix.")
		local name = choice.Name
		self:choose(context, choice)
		table.insert(self.path, name)
	end, "LearnChoice")
end

Market.acceptPath = function(self)
	assert(self.npc and #self.path > 0, "Effectuez d’abord le parcours de dialogue voulu.")
	self.learnedNpc = self.npc
	self.learnedPath = table.clone(self.path)
	self:close()
	self.app:notice("Parcours enregistré pour ce marchand.")
end

Market.addCart = function(self, itemName, quantity)
	self:price(itemName)
	assert(self.app.world.isFinite(quantity), "Quantité invalide.")
	quantity = math.clamp(math.floor(quantity), 1, 30)
	local total = 0
	for _, entry in ipairs(self.cart) do total = total + entry.quantity end
	assert(total + quantity <= 60, "Panier limité à 60 articles.")
	table.insert(self.cart, { name = itemName, quantity = quantity })
	self:renderCart()
end

Market.renderCart = function(self)
	local count, cost = 0, 0
	for _, entry in ipairs(self.cart) do
		count = count + entry.quantity
		cost = cost + self:price(entry.name) * entry.quantity
	end
	self.app:setLabel("cart", string.format("%d article(s) · estimation : %g $", count, cost))
end

Market.clearCart = function(self)
	table.clear(self.cart)
	self:renderCart()
end

Market.removeLast = function(self)
	table.remove(self.cart)
	self:renderCart()
end

Market.sortCart = function(self)
	table.sort(self.cart, function(first, second) return self:price(first.name) < self:price(second.name) end)
	self:renderCart()
end

Market.ensureCounterClear = function(self, frame, selected)
	for model in pairs(self.app.world.models) do
		if model ~= selected and model.Parent and model:FindFirstChild("BoxItemName") and not self.app.world:owner(model) then
			local position = self.app.world:position(model)
			assert(not position or (position - frame.Position).Magnitude > 10, "Un autre article non payé est trop près du comptoir.")
		end
	end
end

Market.stockForNpc = function(self, itemName)
	local stores = game:GetService("Workspace"):FindFirstChild("Stores")
	local store = self.learnedNpc
	while store and store.Parent ~= stores do store = store.Parent end
	assert(store, "Ce marchand n’est pas rattaché à un magasin chargé.")
	local stock = self.app.world:stock(itemName, store)
	assert(stock[1], "Rupture de stock : " .. itemName)
	return stock[1]
end

Market.replay = function(self, context, model)
	self:open(context, self.learnedNpc)
	for _, name in ipairs(self.learnedPath) do
		context:check()
		local choice = self.dialog and self.dialog:FindFirstChild(name)
		assert(choice and choice:IsA("DialogChoice"), "Le parcours marchand a changé ; série interrompue.")
		context:wait(0.85)
		self:choose(context, choice)
		if self.app.world:isOwned(model) then break end
	end
end

Market.confirmPurchase = function(self, context, model, beforeMoney, price)
	local owner = model:FindFirstChild("Owner")
	local hasPurchased = self.app.world:isOwned(model)
	if not hasPurchased and owner then
		hasPurchased = context:untilTrue(owner.Changed, function() return self.app.world:isOwned(model) end, 8)
	end
	assert(hasPurchased, "Achat non confirmé : aucune nouvelle tentative automatique.")
	local difference = math.max(0, beforeMoney - self.app.world:money())
	assert(difference <= price, "Débit supérieur au prix prévu ; série arrêtée.")
	return math.max(price, difference)
end

Market.buyOne = function(self, context, entry, subtotal)
	local price = self:price(entry.name)
	self:requireBudget(price, subtotal)
	local model = self:stockForNpc(entry.name)
	local counter = self.app.actions:point("Comptoir")
	self:ensureCounterClear(counter, model)
	self.app.actions:carry(context, model, counter, true, false)
	self:ensureCounterClear(counter, model)
	self:requireBudget(price, subtotal)
	local beforeMoney = self.app.world:money()
	local isSuccess, result = pcall(function()
		self:replay(context, model)
		return self:confirmPurchase(context, model, beforeMoney, price)
	end)
	self:close()
	assert(isSuccess, result)
	self.spent, self.purchased = self.spent + result, self.purchased + 1
	self.app:setLabel("purchases", string.format("Achats confirmés : %d · budget engagé : %g $", self.purchased, self.spent))
	local destination = self.app.actions:destination(self.app.settings.buyDestination)
	self.app.actions:carry(context, model, destination * CFrame.new((self.purchased % 4) * 5, 0, 0))
	return result
end

Market.checkout = function(self, entries)
	assert(self.learnedNpc and self.learnedNpc.Parent and #self.learnedPath > 0, "Enregistrez le parcours d’achat du marchand.")
	assert(not self.npc and not self.isClosing, "Attendez la fermeture du dialogue.")
	assert(#entries > 0, "Le panier est vide.")
	local snapshot = {}
	for index, entry in ipairs(entries) do snapshot[index] = table.clone(entry) end
	self.app.queue:push("Autobuy", function(context)
		context:defer(function() self:close() end)
		local subtotal = 0
		for _, entry in ipairs(snapshot) do
			for index = 1, entry.quantity do
				context:progress(entry.name .. " · " .. index .. " / " .. entry.quantity)
				subtotal = subtotal + self:buyOne(context, entry, subtotal)
				context:wait(self.app.settings.buyDelay)
			end
		end
	end, "Autobuy")
end

Market.buySelected = function(self, itemName, quantity)
	self:checkout({ { name = itemName, quantity = quantity } })
end

return Market

end)()

local Workshop = (function()
local Workshop = {}
Workshop.__index = Workshop

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local function dimensions(model)
	local _, size = model:GetBoundingBox()
	return size
end

local function largestFootprint(models)
	local size = Vector3.new(1, 1, 1)
	for _, model in ipairs(models) do
		local current = dimensions(model)
		size = Vector3.new(math.max(size.X, current.X), math.max(size.Y, current.Y), math.max(size.Z, current.Z))
	end
	return size
end

local function isVehicle(model)
	return model:FindFirstChild("DriveSeat", true) ~= nil
end

Workshop.new = function(app)
	return setmetatable({ app = app, group = {}, vehicle = nil, cargoOffset = nil }, Workshop)
end

Workshop.models = function(self)
	local models = {}
	for model in pairs(self.group) do
		if model.Parent and self.app.world:isOwned(model) then table.insert(models, model) end
	end
	table.sort(models, function(first, second)
		return self.app:identifier(first) < self.app:identifier(second)
	end)
	return models
end

Workshop.updateGroup = function(self)
	self.app:setLabel("group", #self:models() .. " objet(s) dans le groupe")
end

Workshop.addSelection = function(self)
	local model = self.app.actions:selected()
	self.app.world:requireOwned(model)
	assert(#self:models() < 100, "Groupe limité à 100 objets.")
	self.group[model] = true
	self:updateGroup()
end

Workshop.removeSelection = function(self)
	self.group[self.app.actions:selected()] = nil
	self:updateGroup()
end

Workshop.clearGroup = function(self)
	table.clear(self.group)
	self:updateGroup()
end

Workshop.collect = function(self, category)
	local models = self.app.world:owned(category, self.app.settings.workRadius)
	table.clear(self.group)
	local count = 0
	for _, model in ipairs(models) do
		if count >= 100 then break end
		if self.app.world:isLoose(model) and not isVehicle(model) then
			self.group[model] = true
			count = count + 1
		end
	end
	self:updateGroup()
end

Workshop.placement = function(self, index, size, layout)
	local spacing, columns = self.app.settings.spacing, self.app.settings.columns
	local xStep, zStep = size.X + spacing, size.Z + spacing
	if layout == "Ligne" then return CFrame.new((index - 1) * xStep, size.Y / 2, 0) end
	if layout == "Pile" then return CFrame.new(0, (index - 1) * (size.Y + spacing) + size.Y / 2, 0) end
	if layout == "Cercle" then
		local count = math.max(columns, 3)
		local angle = ((index - 1) % count) / count * math.pi * 2
		local radius = math.max(xStep, zStep) * count / (2 * math.pi)
		local layer = math.floor((index - 1) / count)
		return CFrame.new(math.cos(angle) * radius, layer * (size.Y + spacing) + size.Y / 2, math.sin(angle) * radius)
	end
	local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
	return CFrame.new(column * xStep, size.Y / 2, row * zStep)
end

Workshop.arrange = function(self, models, destination, layout, name)
	local filtered = {}
	for _, model in ipairs(models) do
		if self.app.world:isOwned(model) and self.app.world:isLoose(model) and not isVehicle(model) then
			table.insert(filtered, model)
		end
	end
	assert(#filtered > 0, "Aucun objet mobile compatible dans la sélection.")
	local size = largestFootprint(filtered)
	self.app.queue:push(name or "Ranger les objets", function(context)
		for index, model in ipairs(filtered) do
			context:progress(index .. " / " .. #filtered)
			local target = destination * self:placement(index, size, layout)
			self.app.actions:carry(context, model, target)
		end
	end)
end

Workshop.arrangeGroup = function(self, layout)
	local destination = self.app.actions:point("Dépôt")
	self:arrange(self:models(), destination, layout, "Rangement · " .. layout)
end

Workshop.sortedGroup = function(self, criterion)
	local models = self:models()
	table.sort(models, function(first, second)
		if criterion == "Volume" then
			local firstSize, secondSize = dimensions(first), dimensions(second)
			return firstSize.X * firstSize.Y * firstSize.Z < secondSize.X * secondSize.Y * secondSize.Z
		end
		if criterion == "Essence" then
			return tostring(self.app.world.value(first, "TreeClass")) < tostring(self.app.world.value(second, "TreeClass"))
		end
		return self.app.world:itemName(first) < self.app.world:itemName(second)
	end)
	self:arrange(models, self.app.actions:point("Dépôt"), "Grille", "Tri · " .. criterion)
end

Workshop.separateWood = function(self)
	local models = self.app.world:owned("Bois", self.app.settings.workRadius)
	local groups, names = {}, {}
	for _, model in ipairs(models) do
		local class = tostring(self.app.world.value(model, "TreeClass"))
		if not groups[class] then groups[class] = {}; table.insert(names, class) end
		table.insert(groups[class], model)
	end
	table.sort(names)
	local destination = self.app.actions:point("Dépôt")
	local offset = 0
	for _, name in ipairs(names) do
		local size = largestFootprint(groups[name])
		self:arrange(groups[name], destination * CFrame.new(offset, 0, 0), "Grille", "Ranger " .. name)
		offset = offset + (size.X + self.app.settings.spacing) * self.app.settings.columns + 6
	end
end

Workshop.selectVehicle = function(self, model)
	self.app.world:requireOwned(model)
	assert(isVehicle(model), "La sélection n’est pas un véhicule.")
	self.vehicle = model
	self.cargoOffset = nil
	self.app:mark("Vehicle", model)
	self.app:setLabel("vehicle", self.app.world:itemName(model))
end

Workshop.requireVehicle = function(self)
	self.app.world:requireOwned(self.vehicle)
	assert(isVehicle(self.vehicle), "Véhicule indisponible.")
	return self.vehicle
end

Workshop.selectNearestVehicle = function(self)
	local vehicles = self.app.world:owned("Véhicules")
	assert(vehicles[1], "Aucun de vos véhicules chargé.")
	self:selectVehicle(vehicles[1])
end

Workshop.captureCargo = function(self)
	local vehicle = self:requireVehicle()
	local mouse = player:GetMouse()
	assert(mouse.Target and mouse.Target:IsDescendantOf(vehicle), "Visez le plancher de la benne.")
	self.cargoOffset = vehicle:GetPivot():ToObjectSpace(CFrame.new(mouse.Hit.Position))
	self.app:notice("Point de chargement enregistré sur ce véhicule.")
end

Workshop.cargoFrame = function(self)
	local vehicle = self:requireVehicle()
	assert(self.cargoOffset, "Enregistrez d’abord le point de chargement dans la benne.")
	return vehicle:GetPivot() * self.cargoOffset
end

Workshop.load = function(self, category)
	local models = category == "Groupe" and self:models() or self.app.world:owned(category, self.app.settings.workRadius)
	self:arrange(models, self:cargoFrame(), "Grille", "Charger le véhicule")
end

Workshop.unload = function(self)
	local vehicle = self:requireVehicle()
	local frame, size = vehicle:GetBoundingBox()
	local models = self.app.world:list(function(model, part)
		if model == vehicle or not self.app.world:isOwned(model) then return false end
		local localPosition = frame:PointToObjectSpace(part.Position)
		return math.abs(localPosition.X) <= size.X / 2 + 3
			and math.abs(localPosition.Z) <= size.Z / 2 + 3
			and localPosition.Y >= -size.Y / 2 and localPosition.Y <= size.Y / 2 + 15
	end)
	self:arrange(models, self.app.actions:point("Dépôt"), "Grille", "Décharger le véhicule")
end

Workshop.moveVehicle = function(self, destination)
	local vehicle = self:requireVehicle()
	local frame = self.app.actions:destination(destination)
	self.app.queue:push("Déplacer le véhicule vide", function(context)
		self.app.actions:carry(context, vehicle, frame)
	end)
end

Workshop.flipVehicle = function(self)
	local vehicle = self:requireVehicle()
	local pivot = vehicle:GetPivot()
	local _, yaw = pivot:ToOrientation()
	local frame = CFrame.new(pivot.Position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, yaw, 0)
	self.app.queue:push("Redresser le véhicule", function(context)
		self.app.actions:carry(context, vehicle, frame)
	end)
end

Workshop.seat = function(self)
	local vehicle = self:requireVehicle()
	local seat = vehicle:FindFirstChild("DriveSeat", true)
	assert(seat:IsA("Seat") or seat:IsA("VehicleSeat"), "Siège de conduite incompatible.")
	assert(not seat.Occupant, "Le véhicule est occupé.")
	self.app:teleport(seat.Position + Vector3.new(0, 3, 0))
	seat:Sit(self.app.humanoid)
end

Workshop.applyVehicleSpeed = function(self, isEnabled)
	self.app:restore("VehicleSpeed")
	if not isEnabled then return end
	local vehicle = self:requireVehicle()
	local configuration = vehicle:FindFirstChild("Configuration")
	local speed = configuration and configuration:FindFirstChild("MaxSpeed")
	assert(speed and speed:IsA("NumberValue"), "Vitesse du véhicule non exposée.")
	self.app:patch("VehicleSpeed", speed, "Value", self.app.settings.vehicleSpeed)
end

Workshop.brake = function(self)
	local vehicle = self:requireVehicle()
	for _, part in ipairs(vehicle:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

Workshop.stageForPlayer = function(self, target, isGroup)
	assert(target and target.Parent == Players, "Le destinataire n’est plus dans le serveur.")
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	assert(root, "Personnage du destinataire indisponible.")
	local models = isGroup and self:models() or { self.app.actions:selected() }
	self:arrange(models, root.CFrame * CFrame.new(0, 0, -8), "Grille", "Déposer près de " .. target.Name)
end

Workshop.donate = function(self, target, amount)
	assert(target and target ~= player and target.Parent == Players, "Choisissez un autre joueur présent.")
	assert(self.app.world.isFinite(amount) and amount > 0 and amount % 1 == 0, "Saisissez un montant entier positif.")
	self.app.queue:push("Don à " .. target.Name, function(context)
		self.app.world:requireReady()
		assert(target.Parent == Players, "Destinataire déconnecté.")
		assert(self.app.world:money() - amount >= self.app.settings.moneyReserve, "Réserve d’argent insuffisante.")
		local slot = self.app.world.value(player, "CurrentSaveSlot")
		assert(type(slot) == "number" and slot > 0, "Aucune sauvegarde chargée.")
		local remote = self.app.world:remote("Transactions/ClientToServer/Donate", "RemoteFunction")
		local isSuccess, message = self.app.queue:invoke(context, remote, 12, target, amount, slot)
		assert(isSuccess, tostring(message or "Don refusé par le serveur."))
		self.app:notice("Don confirmé : " .. amount .. " $ à " .. target.Name)
	end, "Donate")
end

return Workshop

end)()

local Routes = (function()
local Routes = {}
Routes.__index = Routes

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local function packFrame(frame)
	return { frame:GetComponents() }
end

local function unpackFrame(components)
	assert(type(components) == "table" and #components == 12, "Position enregistrée invalide.")
	for _, component in ipairs(components) do
		assert(type(component) == "number" and component == component and math.abs(component) < 1000000, "Coordonnée invalide.")
	end
	return CFrame.new(table.unpack(components))
end

Routes.new = function(app)
	return setmetatable({ app = app, points = {}, isFollowing = false, followTarget = nil }, Routes)
end

Routes.render = function(self)
	local options = {}
	for index, point in ipairs(self.points) do options[string.format("%02d · %s", index, point.name)] = index end
	self.app.routePoints = options
	self.app:selectOptions("routePoints", options)
	self.app:setLabel("route", #self.points .. " étape(s)")
end

Routes.add = function(self, name)
	self.app.world:requireReady()
	assert(#self.points < 50, "Itinéraire limité à 50 étapes.")
	table.insert(self.points, { name = name ~= "" and name or "Étape " .. (#self.points + 1), frame = self.app.root.CFrame })
	self:render()
end

Routes.remove = function(self, index)
	assert(index and self.points[index], "Sélectionnez une étape.")
	table.remove(self.points, index)
	self:render()
end

Routes.clear = function(self)
	table.clear(self.points)
	self:render()
end

Routes.reverse = function(self)
	local count = #self.points
	for index = 1, math.floor(count / 2) do
		local opposite = count - index + 1
		self.points[index], self.points[opposite] = self.points[opposite], self.points[index]
	end
	self:render()
end

Routes.moveStep = function(self, index, offset)
	assert(index and self.points[index], "Sélectionnez une étape.")
	local other = math.clamp(index + offset, 1, #self.points)
	self.points[index], self.points[other] = self.points[other], self.points[index]
	self:render()
end

Routes.walk = function(self, context, position)
	self.app.world:requireReady()
	local humanoid, root = self.app.humanoid, self.app.root
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentCanClimb = true })
	context:defer(function() path:Destroy() end)
	path:ComputeAsync(root.Position, position)
	context:check()
	assert(path.Status == Enum.PathStatus.Success, "Aucun chemin praticable.")
	local blockedIndex = math.huge
	local connection = path.Blocked:Connect(function(index) blockedIndex = index end)
	local cleanup = context:defer(function()
		connection:Disconnect()
		if root.Parent then humanoid:MoveTo(root.Position) end
	end)
	for index, waypoint in ipairs(path:GetWaypoints()) do
		context:check()
		assert(index < blockedIndex, "Chemin bloqué ; relancez le trajet.")
		if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
		humanoid:MoveTo(waypoint.Position)
		local hasSignal, hasReached = context:waitFor(humanoid.MoveToFinished, nil, 9)
		assert(hasSignal and hasReached, "Déplacement à pied interrompu.")
	end
	cleanup()
end

Routes.run = function(self, mode, shouldReverse)
	assert(#self.points > 0, "Ajoutez des étapes à l’itinéraire.")
	local points = {}
	for index, point in ipairs(self.points) do points[index] = table.clone(point) end
	local loops = self.app.settings.routeLoops
	self.app.queue:push("Itinéraire · " .. mode, function(context)
		for lap = 1, loops do
			for step = 1, #points do
				local index = shouldReverse and (#points - step + 1) or step
				local point = points[index]
				context:progress(point.name .. " · tour " .. lap)
				if mode == "Marche" then self:walk(context, point.frame.Position)
				else self.app:teleport(point.frame.Position, false) end
				context:wait(self.app.settings.routeDelay)
			end
		end
	end, "Route")
end

Routes.walkToSelection = function(self)
	local position = self.app.world:position(self.app.actions:selected())
	assert(position, "Objet non chargé.")
	self.app.queue:push("Marcher vers la sélection", function(context)
		self:walk(context, position + Vector3.new(0, 0, 5))
	end, "WalkSelection")
end

Routes.stopFollow = function(self)
	self.isFollowing = false
	self.followTarget = nil
	self.app:disconnect("FollowPlayer")
	if self.app.root and self.app.humanoid then self.app.humanoid:MoveTo(self.app.root.Position) end
end

Routes.follow = function(self, target)
	self:stopFollow()
	assert(target and target.Parent == Players, "Choisissez un joueur présent.")
	self.followTarget, self.isFollowing = target, true
	local elapsed = 0
	self.app:connect("FollowPlayer", RunService.Heartbeat, function(delta)
		elapsed = elapsed + delta
		if elapsed < 0.3 then return end
		elapsed = 0
		if not target.Parent or not self.app.root or not self.app.humanoid then self:stopFollow(); return end
		if self.app.queue.active or UserInputService:GetFocusedTextBox() then return end
		local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local distance = (root.Position - self.app.root.Position).Magnitude
		if distance > self.app.settings.followDistance then
			self.app.humanoid:MoveTo(root.Position - root.CFrame.LookVector * self.app.settings.followDistance)
		else self.app.humanoid:MoveTo(self.app.root.Position) end
	end)
end

Routes.save = function(self, name)
	assert(type(writefile) == "function", "Écriture locale indisponible.")
	assert(name:match("^[%w_-]+$") and #name <= 24, "Nom de fichier : lettres, chiffres, tirets ; 24 caractères maximum.")
	local document = { version = 1, placeId = game.PlaceId, points = {}, destinations = {} }
	for _, point in ipairs(self.points) do
		table.insert(document.points, { name = point.name, frame = packFrame(point.frame) })
	end
	for key, frame in pairs(self.app.actions.points) do document.destinations[key] = packFrame(frame) end
	writefile("UnderlordLT2-" .. name .. ".json", HttpService:JSONEncode(document))
	self.app:notice("Itinéraire enregistré.")
end

Routes.load = function(self, name)
	assert(type(readfile) == "function", "Lecture locale indisponible.")
	assert(name:match("^[%w_-]+$") and #name <= 24, "Nom de fichier invalide.")
	local encoded = readfile("UnderlordLT2-" .. name .. ".json")
	assert(#encoded <= 65536, "Fichier trop volumineux.")
	local document = HttpService:JSONDecode(encoded)
	assert(type(document) == "table" and document.version == 1 and document.placeId == game.PlaceId, "Fichier incompatible.")
	self:import(document)
end

Routes.import = function(self, document)
	assert(type(document.points) == "table" and #document.points <= 50, "Itinéraire invalide.")
	assert(type(document.destinations) == "table", "Destinations invalides.")
	local points, destinations = {}, {}
	for index, point in ipairs(document.points) do
		assert(type(point.name) == "string" and #point.name <= 96, "Nom d’étape invalide.")
		points[index] = { name = point.name, frame = unpackFrame(point.frame) }
	end
	local count = 0
	for name, components in pairs(document.destinations) do
		count = count + 1
		assert(count <= 20 and type(name) == "string" and #name <= 40, "Destination invalide.")
		destinations[name] = unpackFrame(components)
	end
	self.points, self.app.actions.points = points, destinations
	self:render()
	self.app:notice("Itinéraire chargé.")
end

Routes.bind = function(self)
	self.app:connect("FollowDespawn", player.CharacterRemoving, function() self:stopFollow() end)
	self.app:connect("FollowManual", UserInputService.InputBegan, function(input, isProcessed)
		if isProcessed or not self.isFollowing then return end
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A
			or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D then self:stopFollow() end
	end)
end

return Routes

end)()

local Pipeline = (function()
local Pipeline = {}
Pipeline.__index = Pipeline

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function setOf(models)
	local entries = {}
	for _, model in ipairs(models) do entries[model] = true end
	return entries
end

Pipeline.new = function(app)
	return setmetatable({
		app = app,
		seen = setmetatable({}, { __mode = "k" }),
		isCollecting = false,
		isTools = false,
		isBoxes = false,
		isWood = false,
	}, Pipeline)
end

Pipeline.looseWoodNear = function(self, position, radius, previous)
	return self.app.world:list(function(model, part)
		if previous and previous[model] then return false end
		return model:FindFirstChild("TreeClass") and self.app.world:isOwned(model)
			and self.app.world:isLoose(model) and (part.Position - position).Magnitude <= radius
	end, position)
end

Pipeline.waitForWood = function(self, context, position, radius, previous, timeout)
	local found = {}
	local function search()
		found = self:looseWoodNear(position, radius, previous)
		return #found > 0
	end
	local hasFound = context:untilTrue(self.app.world.changed.Event, search, timeout)
	assert(hasFound, "Aucune nouvelle pièce de bois possédée confirmée à cette étape.")
	context:wait(0.4)
	search()
	return found
end

Pipeline.harvestOne = function(self, context, tree)
	local position = self.app.world:position(tree)
	assert(position, "Arbre non chargé.")
	local previous = setOf(self.app.world:owned("Bois"))
	previous[tree] = nil
	self.app.timber:chop(context, tree)
	local logs = self:waitForWood(context, position, 80, previous, 10)
	for _, log in ipairs(logs) do self.seen[log] = true end
	return logs
end

Pipeline.deliver = function(self, context, models, destination, startIndex)
	local layout = startIndex or { x = 0, z = 0, depth = 0, column = 0 }
	for _, model in ipairs(models) do
		context:check()
		if model.Parent then
			self.seen[model] = true
			local size = model:GetExtentsSize()
			local offset = self:nextSlot(layout, size)
			self.app.actions:carry(context, model, destination * offset)
		end
	end
	return layout
end

Pipeline.nextSlot = function(self, layout, size)
	local frame = CFrame.new(layout.x + size.X / 2, size.Y / 2, layout.z + size.Z / 2)
	layout.x = layout.x + size.X + self.app.settings.spacing
	layout.depth = math.max(layout.depth, size.Z)
	layout.column = layout.column + 1
	if layout.column >= self.app.settings.columns then
		layout.x, layout.z = 0, layout.z + layout.depth + self.app.settings.spacing
		layout.depth, layout.column = 0, 0
	end
	return frame
end

Pipeline.millOne = function(self, context, log)
	local input = self.app.actions:point("Scierie")
	local output = self.app.actions:point("Sortie scierie")
	local previous = setOf(self.app.world:owned("Bois"))
	self.app.actions:carry(context, log, input, false, nil, true)
	return self:waitForWood(context, output.Position, 25, previous, self.app.settings.millTimeout)
end

Pipeline.harvestTo = function(self, shouldMill)
	local trees = self.app.world:trees(self.app.settings.woodClass, self.app.settings.treeRadius)
	local count = math.min(#trees, self.app.settings.treeLimit)
	assert(count > 0, "Aucun arbre compatible dans le rayon choisi.")
	local destination = self.app.actions:destination(self.app.settings.pipelineDestination)
	if shouldMill then self.app.actions:point("Scierie"); self.app.actions:point("Sortie scierie") end
	self.app.queue:push(shouldMill and "Coupe → Scierie → Dépôt" or "Coupe → Dépôt", function(context)
		local placed
		for index = 1, count do
			context:progress("Arbre " .. index .. " / " .. count)
			local logs = self:harvestOne(context, trees[index])
			if shouldMill then
				for _, log in ipairs(logs) do placed = self:deliver(context, self:millOne(context, log), destination, placed) end
			else placed = self:deliver(context, logs, destination, placed) end
		end
	end, "WoodPipeline")
end

Pipeline.millToDeposit = function(self)
	local logs = self.app.world:owned("Bois", self.app.settings.workRadius)
	local destination = self.app.actions:destination(self.app.settings.pipelineDestination)
	assert(#logs > 0, "Aucun bois possédé dans le rayon choisi.")
	self.app.queue:push("Bois proche → Scierie → Dépôt", function(context)
		local placed
		for index, log in ipairs(logs) do
			context:progress(index .. " / " .. #logs)
			if log.Parent and self.app.world:isLoose(log) then
				placed = self:deliver(context, self:millOne(context, log), destination, placed)
			end
		end
	end, "MillPipeline")
end

Pipeline.sellOne = function(self, context, model)
	self.app.world:requireOwned(model)
	local destination = self.app.actions:point("Vente")
	local money = player:FindFirstChild("leaderstats")
	money = money and money:FindFirstChild("Money")
	assert(money, "Solde du joueur indisponible.")
	local before = money.Value
	self.app.actions:carry(context, model, destination, false, nil, true)
	local hasPaid = context:untilTrue(money.Changed, function() return money.Value > before end, 12)
	assert(hasPaid, "Aucun paiement observé ; chaîne de vente arrêtée.")
	return money.Value - before
end

Pipeline.sellGroup = function(self)
	local models = self.app.workshop:models()
	assert(#models > 0, "Groupe vide.")
	for _, model in ipairs(models) do assert(model:FindFirstChild("TreeClass"), "La vente accepte uniquement du bois.") end
	self.app.queue:push("Vendre le groupe de bois", function(context)
		local earnings = 0
		for index, model in ipairs(models) do
			context:progress(index .. " / " .. #models)
			earnings = earnings + self:sellOne(context, model)
		end
		self.app:notice("Hausse de solde observée pendant la série : " .. earnings .. " $")
	end, "SellGroup")
end

Pipeline.setAuto = function(self, key, isEnabled)
	if isEnabled then self.app.actions:point("Dépôt") end
	self[key] = isEnabled
	for model in pairs(self.app.world.models) do self.seen[model] = true end
	self.autoLayout = { x = 0, z = 0, depth = 0, column = 0 }
end

Pipeline.matches = function(self, model)
	if self.seen[model] or not self.app.world:isOwned(model) then return false end
	if not self.app.world:isLoose(model) then return false end
	if self.isTools and model:FindFirstChild("ToolName") then return true end
	if self.isBoxes and model:FindFirstChild("PurchasedBoxItemName") then return true end
	if self.isWood and model:FindFirstChild("TreeClass") then return true end
	return false
end

Pipeline.collectNew = function(self)
	if self.isCollecting or self.app.queue.active or self.app.queue.isPaused or self.app.queue.isDestroyed or not self.app.root then return end
	if not self.isTools and not self.isBoxes and not self.isWood then return end
	local origin = self.app.root.Position
	local models = self.app.world:list(function(model, part)
		return self:matches(model) and (part.Position - origin).Magnitude <= self.app.settings.workRadius
	end, origin, 20)
	if #models == 0 then return end
	self.isCollecting = true
	self.app.queue:push("Récupération automatique", function(context)
		context:defer(function() self.isCollecting = false end)
		for _, model in ipairs(models) do
			context:check()
			if self:matches(model) then self:collectOne(context, model) end
		end
	end, "AutoCollect")
end

Pipeline.collectOne = function(self, context, model)
	self.seen[model] = true
	if model:FindFirstChild("ToolName") then self.app.actions:pickup(context, model); return end
	local destination = self.app.actions:point("Dépôt")
	local size = model:GetExtentsSize()
	self.app.actions:carry(context, model, destination * self:nextSlot(self.autoLayout, size))
end

Pipeline.bind = function(self)
	self.app:connect("CollectNewOwned", self.app.world.changed.Event, function()
		local isSuccess, message = pcall(function() self:collectNew() end)
		if not isSuccess then
			self.isTools, self.isBoxes, self.isWood = false, false, false
			self.app:notice(message)
		end
	end)
end

return Pipeline

end)()

local Construction = (function()
local Construction = {}
Construction.__index = Construction

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local supported = { Structure = true, Furniture = true, Vehicle = true, ["Vehicle Spot"] = true }

local function findTemplate(world, box)
	local name = world.value(box, "PurchasedBoxItemName")
	assert(name, "Sélectionnez une boîte déjà achetée.")
	local catalog = ReplicatedStorage:FindFirstChild("ClientItemInfo")
	local item = catalog and catalog:FindFirstChild(name, true)
	local template = item and (item:FindFirstChild("PlacingModel") or item:FindFirstChild("Model"))
	assert(template and template:IsA("Model"), "Modèle de placement non disponible.")
	return name, template
end

Construction.new = function(app)
	return setmetatable({ app = app, preview = nil, box = nil, committed = setmetatable({}, { __mode = "k" }) }, Construction)
end

Construction.validator = function(self)
	if self.canPlace then return self.canPlace end
	local interaction = ReplicatedStorage:FindFirstChild("Interaction")
	local module = interaction and interaction:FindFirstChild("CanPlace")
	assert(module and module:IsA("ModuleScript"), "Validateur de placement du jeu indisponible.")
	self.canPlace = require(module)
	assert(type(self.canPlace) == "table" and type(self.canPlace.CanPlace) == "function", "API de placement incompatible.")
	return self.canPlace
end

Construction.requireBox = function(self, box)
	self.app.world:requireOwned(box)
	assert(box:FindFirstChild("PurchasedBoxItemName"), "La sélection n’est pas une boîte achetée.")
	assert(supported[self.app.world.value(box, "Type")], "Utilisez l’ouverture simple pour les outils ; les câbles gardent leur placement natif.")
	assert(not self.committed[box], "Placement déjà envoyé pour cette boîte ; aucune répétition automatique.")
end

Construction.makePreview = function(self, box, frame)
	self:requireBox(box)
	local _, template = findTemplate(self.app.world, box)
	local preview = template:Clone()
	preview.Name = "ConstructionPreview"
	preview.PrimaryPart = preview.PrimaryPart or preview:FindFirstChild("Main") or preview:FindFirstChildWhichIsA("BasePart", true)
	assert(preview.PrimaryPart, "Modèle sans pièce principale.")
	for _, descendant in ipairs(preview:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Transparency = math.max(descendant.Transparency, 0.55)
		end
	end
	preview:PivotTo(frame * preview.PrimaryPart.CFrame:ToObjectSpace(preview:GetPivot()))
	preview.Parent = self.app.folder
	return preview
end

Construction.checkPlacement = function(self, preview)
	local validator = self:validator()
	local permissions = { "PlaceStructure", "MoveStructure", "Destroy" }
	local land = validator:GetPlayerLand(player, permissions)
	local canPlace, owner = validator:CanPlace(player, preview, { Land = land, PermissionType = permissions })
	return canPlace == true, owner
end

Construction.paintPreview = function(self)
	if not self.preview then return end
	local canPlace = self:checkPlacement(self.preview)
	self.app:mark("Placement", self.preview)
	local marker = self.app.markers.Placement
	if marker then
		local color = canPlace and Color3.fromRGB(115, 210, 150) or self.app.window.theme.accent
		marker.FillColor, marker.OutlineColor = color, color
	end
	self.app:setLabel("placement", canPlace and "Placement accepté par le validateur local" or "Placement refusé à cette position")
end

Construction.cancel = function(self)
	if self.preview then self.preview:Destroy() end
	self.preview, self.box = nil, nil
	self.app:mark("Placement", nil)
	self.app:setLabel("placement", "Aucun aperçu")
end

Construction.previewSelection = function(self)
	local box = self.app.actions:selected()
	local frame = self.app.actions:point("Construction")
	self:cancel()
	self.preview = self:makePreview(box, frame)
	self.box = box
	self:paintPreview()
end

Construction.transform = function(self, callback)
	assert(self.preview and self.preview.Parent, "Créez un aperçu d’abord.")
	self.preview:PivotTo(callback(self.preview:GetPivot()))
	self:paintPreview()
end

Construction.commit = function(self, context, box, frame)
	context:check()
	self:requireBox(box)
	local name = self.app.world.value(box, "PurchasedBoxItemName")
	local preview = self:makePreview(box, frame)
	context:defer(function() preview:Destroy() end)
	local canPlace, owner = self:checkPlacement(preview)
	assert(canPlace, "Le jeu refuse ce placement.")
	local before = {}
	for model in pairs(self.app.world.models) do before[model] = true end
	local position = self.app.world:position(box)
	assert(position, "Boîte non chargée.")
	self.app:teleport(position + Vector3.new(0, 3, 5), false)
	context:wait(0.25)
	self:requireBox(box)
	self.committed[box] = true
	self.app.world:remote("PlaceStructure/ClientPlacedStructure"):FireServer(name, preview.PrimaryPart.CFrame, owner, nil, box, false, true)
	preview:Destroy()
	return self:waitForPlacement(context, box, name, frame.Position, before)
end

Construction.waitForPlacement = function(self, context, box, name, position, before)
	local placed
	local function findPlaced()
		if box.Parent and box:FindFirstChild("PurchasedBoxItemName") then return false end
		for model in pairs(self.app.world.models) do
			if not before[model] and self.app.world:isOwned(model) and self.app.world:itemName(model) == name then
				local location = self.app.world:position(model)
				if location and (location - position).Magnitude < 30 then placed = model; return true end
			end
		end
		return false
	end
	local hasPlaced = context:untilTrue(self.app.world.changed.Event, findPlaced, 12)
	assert(hasPlaced and placed, "Placement non confirmé ; cette boîte ne sera pas renvoyée automatiquement.")
	return placed
end

Construction.placePreview = function(self)
	assert(self.preview and self.box, "Créez un aperçu d’abord.")
	local box, frame = self.box, self.preview.PrimaryPart.CFrame
	self:cancel()
	self.app.queue:push("Placer la boîte achetée", function(context)
		self:commit(context, box, frame)
	end)
end

Construction.placeGroup = function(self)
	local boxes = self.app.workshop:models()
	assert(#boxes > 0, "Ajoutez vos boîtes achetées au groupe.")
	local start = self.app.actions:point("Construction")
	for _, box in ipairs(boxes) do self:requireBox(box) end
	self.app.queue:push("Installer les boîtes du groupe", function(context)
		local x, z, depth, column = 0, 0, 0, 0
		for index, box in ipairs(boxes) do
			context:progress(index .. " / " .. #boxes)
			local _, template = findTemplate(self.app.world, box)
			local size = template:GetExtentsSize()
			local frame = start * CFrame.new(x + size.X / 2, size.Y / 2, z + size.Z / 2)
			self:commit(context, box, frame)
			x, depth, column = x + size.X + self.app.settings.spacing, math.max(depth, size.Z), column + 1
			if column >= self.app.settings.columns then
				x, z, depth, column = 0, z + depth + self.app.settings.spacing, 0, 0
			end
		end
	end, "PlaceGroup")
end

Construction.openSimple = function(self, context, box)
	self.app.world:requireOwned(box)
	local kind = self.app.world.value(box, "Type")
	assert(not supported[kind] and kind ~= "Wire", "Cette boîte utilise un placement de structure.")
	assert(box:FindFirstChild("PurchasedBoxItemName"), "La boîte n’a pas été achetée.")
	assert(not self.committed[box], "Une ouverture a déjà été envoyée pour cette boîte.")
	self.app.actions:interact(context, box, "Open box", function() self.committed[box] = true end)
	local hasOpened = context:untilTrue(self.app.world.changed.Event, function()
		return not box.Parent or not box:FindFirstChild("PurchasedBoxItemName")
	end, 8)
	assert(hasOpened, "Ouverture non confirmée.")
end

Construction.openSelected = function(self)
	local box = self.app.actions:selected()
	self.app.queue:push("Ouvrir la boîte achetée", function(context) self:openSimple(context, box) end)
end

Construction.openTools = function(self)
	local boxes = self.app.world:owned("Boîtes", self.app.settings.workRadius)
	self.app.queue:push("Déballer les outils proches", function(context)
		for _, box in ipairs(boxes) do
			local kind = self.app.world.value(box, "Type")
			if kind == "Tool" and box.Parent then self:openSimple(context, box) end
		end
	end, "OpenTools")
end

return Construction

end)()

local Workbench = (function()
local Workbench = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local defaults = {
	carrySpeed = 35,
	workRadius = 150,
	gridSize = 2,
	spacing = 2,
	columns = 4,
	cutHeight = 1,
	maxSwings = 120,
	treeLimit = 5,
	treeRadius = 400,
	woodClass = "Toutes",
	feedDelay = 5,
	buyBudget = 1000,
	maxPrice = 500,
	moneyReserve = 100,
	buyDelay = 3,
	buyDestination = "Base",
	buyQuantity = 1,
	vehicleSpeed = 2,
	routeDelay = 1,
	routeLoops = 1,
	followDistance = 7,
	category = "Tout",
	pipelineDestination = "Dépôt",
	millTimeout = 45,
}

local function protect(app, callback)
	return function(...)
		if app.isDestroyed then return end
		local isSuccess, message = pcall(callback, ...)
		if not isSuccess then app:notice(message) end
	end
end

local function button(app, section, name, callback, tooltip)
	return section:addButton({ name = name, callback = protect(app, callback), tooltip = tooltip, debounce = 0.3 })
end

local function slider(app, section, name, key, minimum, maximum, step, callback)
	return section:addSlider({
		name = name,
		id = key,
		min = minimum,
		max = maximum,
		step = step or 1,
		default = app.settings[key],
		callback = protect(app, function(number)
			app.settings[key] = number
			if callback then callback(number) end
		end),
	})
end

local function dropdown(app, section, name, key, options, callback)
	local selector = section:addDropdown({
		name = name,
		options = options or {},
		searchable = true,
		maxVisible = 6,
		default = app.settings[key],
		callback = protect(app, function(option)
			app.settings[key] = option
			if callback then callback(option) end
		end),
	})
	app.selectors[key] = selector
	return selector
end

local function label(app, section, key, text, height)
	app.labels[key] = section:addLabel({ text = text, height = height or 36, wrapped = true })
end

local function pointButton(app, section, name, key)
	button(app, section, name, function() app.actions:capturePoint(key) end)
end

local function selectedIndex(app)
	local selected = app.selectors.routePoints:get()
	return app.routePoints and app.routePoints[selected]
end

local function selectedTarget(app)
	local name = app.selectors.players:get()
	local target = app.playerOptions[name]
	assert(target and target.Parent == Players, "Sélectionnez un joueur présent.")
	return target
end

local function stopAll(app)
	for _, flag in ipairs({ "isAutoTools", "isAutoBoxes", "isAutoWood" }) do
		if app.window.flags[flag] then app.window:setFlag(flag, false) end
	end
	app.queue:stop("Arrêt général.")
	app.routes:stopFollow()
	app:stopFly()
	if app.flyToggle then app.flyToggle:set(false, false) end
	app:setNoclip(false)
	if app.window.flags.isNoclip then app.window:setFlag("isNoclip", false) end
	app:restore("VehicleSpeed")
	app:restore("Gravity")
	if app.window.flags.isGravity then app.window:setFlag("isGravity", false) end
	app.market:close()
end

local function autoToggle(app, section, name, id, key)
	local handle
	handle = section:addToggle({ name = name, id = id, default = false, shouldSave = false, callback = function(isEnabled)
		local isSuccess, message = pcall(function() app.pipeline:setAuto(key, isEnabled) end)
		if not isSuccess then handle:set(false, false); app:notice(message) end
	end })
end

local function pipelineSections(app, tab)
	local pipeline = tab:createSection("Chaînes de travail")
	dropdown(app, pipeline, "Destination finale", "pipelineDestination", { "Dépôt", "Base" })
	button(app, pipeline, "Couper puis ranger", function() app.pipeline:harvestTo(false) end)
	button(app, pipeline, "Couper, scier puis ranger", function() app.pipeline:harvestTo(true) end)
	button(app, pipeline, "Scier mon bois proche puis ranger", function() app.pipeline:millToDeposit() end)
	button(app, pipeline, "Vendre le groupe de bois", function() app.pipeline:sellGroup() end)
	pointButton(app, pipeline, "Enregistrer la sortie de scierie ici", "Sortie scierie")
	slider(app, pipeline, "Attente maximale de transformation", "millTimeout", 10, 120)
	local automatic = tab:createSection("Nouveaux objets possédés")
	autoToggle(app, automatic, "Ramasser mes nouveaux outils", "isAutoTools", "isTools")
	autoToggle(app, automatic, "Ranger mes nouvelles boîtes", "isAutoBoxes", "isBoxes")
	autoToggle(app, automatic, "Ranger mon nouveau bois", "isAutoWood", "isWood")
	automatic:addLabel({ text = "S’applique aux objets apparus après activation, dans le rayon de travail. Dépôt requis.", height = 48, wrapped = true })
end

local function automationTab(app)
	local tab = app.window:createTab({ name = "Automations", icon = "zap" })
	local queue = tab:createSection("File d’actions")
	label(app, queue, "job", "Prêt")
	label(app, queue, "queue", "Aucune tâche")
	button(app, queue, "Arrêt général", function() stopAll(app) end)
	button(app, queue, "Arrêter cette tâche", function() app.queue:skip() end)
	button(app, queue, "Mettre la file en pause", function() app.queue:setPaused(true) end,
		"La tâche en cours termine ; les suivantes attendent.")
	button(app, queue, "Reprendre la file", function() app.queue:setPaused(false) end)
	button(app, queue, "Vider les tâches en attente", function() app.queue:clear() end)
	button(app, queue, "Retirer la dernière tâche", function() app.queue:removeLast() end)
	button(app, queue, "Inverser les tâches en attente", function() app.queue:reverse() end)
	queue:addKeybind({ name = "Arrêt immédiat", default = Enum.KeyCode.End, callback = protect(app, function() stopAll(app) end) })
	local quick = tab:createSection("Actions rapides")
	button(app, quick, "Couper l’arbre proche", function() app.timber:queueNearest() end)
	button(app, quick, "Ramasser mes outils proches", function() app.actions:pickupNearby() end)
	button(app, quick, "Rapporter mon bois à la base", function() app.timber:transportLogs("Base") end)
	button(app, quick, "Retourner à ma base", function() app.actions:returnHome() end)
	button(app, quick, "Annuler le dernier transport", function() app.actions:undoLast() end)
	local scope = tab:createSection("Zone de travail")
	slider(app, scope, "Rayon des objets", "workRadius", 10, 1000)
	slider(app, scope, "Vitesse de transport", "carrySpeed", 10, 70)
	button(app, scope, "Enregistrer le dépôt ici", function() app.actions:capturePoint("Dépôt") end)
	pipelineSections(app, tab)
end

local function constructionTab(app)
	local tab = app.window:createTab({ name = "Construction", icon = "hammer" })
	local preview = tab:createSection("Boîtes de structures achetées")
	label(app, preview, "placement", "Aucun aperçu")
	pointButton(app, preview, "Définir le point de construction ici", "Construction")
	button(app, preview, "Prévisualiser la boîte sélectionnée", function() app.construction:previewSelection() end)
	button(app, preview, "Installer à cette position", function() app.construction:placePreview() end)
	button(app, preview, "Annuler l’aperçu", function() app.construction:cancel() end)
	local adjust = tab:createSection("Ajuster l’aperçu")
	button(app, adjust, "Tourner à droite", function()
		app.construction:transform(function(frame) return frame * CFrame.Angles(0, math.pi / 2, 0) end)
	end)
	button(app, adjust, "Tourner à gauche", function()
		app.construction:transform(function(frame) return frame * CFrame.Angles(0, -math.pi / 2, 0) end)
	end)
	button(app, adjust, "Décaler vers l’avant", function()
		app.construction:transform(function(frame) return frame * CFrame.new(0, 0, -app.settings.gridSize) end)
	end)
	button(app, adjust, "Décaler vers l’arrière", function()
		app.construction:transform(function(frame) return frame * CFrame.new(0, 0, app.settings.gridSize) end)
	end)
	button(app, adjust, "Décaler à droite", function()
		app.construction:transform(function(frame) return frame * CFrame.new(app.settings.gridSize, 0, 0) end)
	end)
	button(app, adjust, "Décaler à gauche", function()
		app.construction:transform(function(frame) return frame * CFrame.new(-app.settings.gridSize, 0, 0) end)
	end)
	button(app, adjust, "Monter l’aperçu", function()
		app.construction:transform(function(frame) return frame + Vector3.new(0, app.settings.gridSize, 0) end)
	end)
	button(app, adjust, "Descendre l’aperçu", function()
		app.construction:transform(function(frame) return frame - Vector3.new(0, app.settings.gridSize, 0) end)
	end)
	local batch = tab:createSection("Installation en série")
	button(app, batch, "Installer les boîtes du groupe en grille", function() app.construction:placeGroup() end)
	button(app, batch, "Ouvrir la boîte d’outil sélectionnée", function() app.construction:openSelected() end)
	button(app, batch, "Déballer mes boîtes d’outils proches", function() app.construction:openTools() end)
end

local function timberTab(app)
	local tab = app.window:createTab({ name = "Bois", icon = "trees" })
	local cut = tab:createSection("Coupe")
	dropdown(app, cut, "Essence", "woodClass", { "Toutes" })
	button(app, cut, "Actualiser les essences", function() app.selectors.woodClass:setOptions(app.world:treeClasses(), false) end)
	button(app, cut, "Équiper la meilleure hache", function() app.timber:equipBest(app.actions.selection) end)
	button(app, cut, "Donner un coup à la sélection", function() app.timber:queueSelected(true) end)
	button(app, cut, "Couper la sélection", function() app.timber:queueSelected(false) end)
	button(app, cut, "Couper le plus proche", function() app.timber:queueNearest() end)
	button(app, cut, "Lancer la coupe en série", function() app.timber:harvest() end)
	slider(app, cut, "Nombre d’arbres", "treeLimit", 1, 30)
	slider(app, cut, "Rayon de recherche", "treeRadius", 20, 2000)
	slider(app, cut, "Hauteur de coupe", "cutHeight", 0.1, 20, 0.1)
	slider(app, cut, "Coups maximum / arbre", "maxSwings", 5, 200)
	local carry = tab:createSection("Récolte")
	button(app, carry, "Rapporter la sélection à la base", function() app.actions:moveSelection("Base") end)
	button(app, carry, "Rapporter tout mon bois à la base", function() app.timber:transportLogs("Base") end)
	button(app, carry, "Ranger mon bois au dépôt", function() app.timber:transportLogs("Dépôt") end)
	button(app, carry, "Séparer les essences au dépôt", function() app.workshop:separateWood() end)
	local mill = tab:createSection("Scierie")
	pointButton(app, mill, "Enregistrer l’entrée ici", "Scierie")
	button(app, mill, "Alimenter avec la sélection", function() app.timber:processOne() end)
	button(app, mill, "Alimenter avec mon bois proche", function() app.timber:processAll() end)
	slider(app, mill, "Intervalle d’alimentation", "feedDelay", 2, 30, 0.5)
	local sale = tab:createSection("Livraison au point de vente")
	pointButton(app, sale, "Enregistrer la zone de vente ici", "Vente")
	button(app, sale, "Livrer le bois sélectionné", function() app.timber:sell(false) end)
	button(app, sale, "Livrer tout mon bois proche", function() app.timber:sell(true) end)
end

local function marketSetup(app, tab)
	local setup = tab:createSection("Marchand / Parcours")
	dropdown(app, setup, "Marchand", "merchants", {}, function(name) app.market:setNpc(app.merchants[name]) end)
	button(app, setup, "Actualiser les marchands", function()
		app.merchants = app.world:npcOptions()
		app:selectOptions("merchants", app.merchants)
	end)
	pointButton(app, setup, "Enregistrer le comptoir ici", "Comptoir")
	button(app, setup, "Ouvrir le dialogue", function()
		app.market.selectedNpc = app.merchants[app.selectors.merchants:get()]
		app.market:beginLearning()
	end)
	label(app, setup, "dialog", "Choisissez les réponses du marchand pour enregistrer le parcours d’achat.", 56)
	dropdown(app, setup, "Réponse", "marketChoices")
	button(app, setup, "Envoyer cette réponse", function() app.market:learnChoice(app.selectors.marketChoices:get()) end,
		"Effectue réellement le choix de dialogue, achat compris.")
	button(app, setup, "Utiliser ce parcours pour autobuy", function() app.market:acceptPath() end)
	button(app, setup, "Fermer le dialogue", function() app.market:close() end)
end

local function marketTab(app)
	local tab = app.window:createTab({ name = "Achats", icon = "shopping-cart" })
	local buy = tab:createSection("Autobuy")
	dropdown(app, buy, "Article", "buyItem")
	button(app, buy, "Actualiser les articles", function()
		app.world:refreshCatalog()
		app:selectOptions("buyItem", app.world.catalog)
	end)
	slider(app, buy, "Quantité", "buyQuantity", 1, 30)
	button(app, buy, "Acheter un exemplaire", function() app.market:buySelected(app.selectors.buyItem:get(), 1) end)
	button(app, buy, "Acheter la quantité choisie", function() app.market:buySelected(app.selectors.buyItem:get(), app.settings.buyQuantity) end)
	dropdown(app, buy, "Livrer vers", "buyDestination", { "Base", "Dépôt" })
	label(app, buy, "purchases", "Aucun achat confirmé")
	local cart = tab:createSection("Panier")
	label(app, cart, "cart", "Panier vide")
	button(app, cart, "Ajouter au panier", function() app.market:addCart(app.selectors.buyItem:get(), app.settings.buyQuantity) end)
	button(app, cart, "Acheter le panier", function() app.market:checkout(app.market.cart) end)
	button(app, cart, "Trier du moins cher au plus cher", function() app.market:sortCart() end)
	button(app, cart, "Retirer le dernier ajout", function() app.market:removeLast() end)
	button(app, cart, "Vider le panier", function() app.market:clearCart() end)
	local limits = tab:createSection("Limites de la série")
	slider(app, limits, "Budget maximal", "buyBudget", 0, 50000, 50)
	slider(app, limits, "Prix unitaire maximal", "maxPrice", 0, 25000, 10)
	slider(app, limits, "Argent à conserver", "moneyReserve", 0, 50000, 10)
	slider(app, limits, "Intervalle entre achats", "buyDelay", 2, 20, 0.5)
	marketSetup(app, tab)
end

local function selectionSection(app, tab)
	local selection = tab:createSection("Objet sélectionné")
	label(app, selection, "selection", "Visez un objet et appuyez sur G")
	selection:addKeybind({ name = "Sélectionner sous le curseur", default = Enum.KeyCode.G,
		callback = protect(app, function() app.actions:captureSelection() end) })
	button(app, selection, "Amener devant moi", function() app.actions:moveSelection("Devant moi") end)
	button(app, selection, "Envoyer à la base", function() app.actions:moveSelection("Base") end)
	button(app, selection, "Envoyer au dépôt", function() app.actions:moveSelection("Dépôt") end)
	button(app, selection, "Remettre à plat", function() app.actions:flatten() end)
	button(app, selection, "Aligner sur la grille", function() app.actions:snap() end)
	button(app, selection, "Tourner de 90°", function()
		app.actions:transform(function(frame) return frame * CFrame.Angles(0, math.pi / 2, 0) end)
	end)
	button(app, selection, "Tourner de −90°", function()
		app.actions:transform(function(frame) return frame * CFrame.Angles(0, -math.pi / 2, 0) end)
	end)
	button(app, selection, "Monter d’un cran", function()
		app.actions:transform(function(frame) return frame + Vector3.new(0, app.settings.gridSize, 0) end)
	end)
	button(app, selection, "Descendre d’un cran", function()
		app.actions:transform(function(frame) return frame - Vector3.new(0, app.settings.gridSize, 0) end)
	end)
	button(app, selection, "Arrêter la rotation / vitesse", function() app.actions:freezeSelection() end)
	button(app, selection, "Annuler le dernier déplacement", function() app.actions:undoLast() end)
end

local function workshopTab(app)
	local tab = app.window:createTab({ name = "Rangement", icon = "boxes" })
	selectionSection(app, tab)
	local group = tab:createSection("Groupe d’objets")
	label(app, group, "group", "Groupe vide")
	button(app, group, "Ajouter la sélection", function() app.workshop:addSelection() end)
	button(app, group, "Retirer la sélection", function() app.workshop:removeSelection() end)
	dropdown(app, group, "Catégorie", "category", { "Tout", "Bois", "Boîtes", "Outils" })
	button(app, group, "Grouper mes objets proches", function() app.workshop:collect(app.settings.category) end)
	button(app, group, "Vider le groupe", function() app.workshop:clearGroup() end)
	local layout = tab:createSection("Organisation au dépôt")
	pointButton(app, layout, "Définir l’origine ici", "Dépôt")
	button(app, layout, "Ranger en grille", function() app.workshop:arrangeGroup("Grille") end)
	button(app, layout, "Ranger en ligne", function() app.workshop:arrangeGroup("Ligne") end)
	button(app, layout, "Empiler", function() app.workshop:arrangeGroup("Pile") end)
	button(app, layout, "Disposer en cercle", function() app.workshop:arrangeGroup("Cercle") end)
	button(app, layout, "Trier par nom", function() app.workshop:sortedGroup("Nom") end)
	button(app, layout, "Trier par volume", function() app.workshop:sortedGroup("Volume") end)
	button(app, layout, "Trier par essence", function() app.workshop:sortedGroup("Essence") end)
	slider(app, layout, "Colonnes / places du cercle", "columns", 1, 12)
	slider(app, layout, "Espacement", "spacing", 0.5, 12, 0.5)
	slider(app, layout, "Taille d’un cran", "gridSize", 0.5, 10, 0.5)
	local machine = tab:createSection("Machines")
	machine:addKeybind({ name = "Actionner le bouton visé", default = Enum.KeyCode.H, callback = protect(app, function()
		local part = player:GetMouse().Target
		app.queue:push("Actionner la machine", function(context) app.actions:pressButton(context, part) end)
	end) })
end

local function vehicleTab(app)
	local tab = app.window:createTab({ name = "Véhicules", icon = "truck" })
	local vehicle = tab:createSection("Mon véhicule")
	label(app, vehicle, "vehicle", "Aucun véhicule choisi")
	button(app, vehicle, "Choisir le véhicule proche", function() app.workshop:selectNearestVehicle() end)
	button(app, vehicle, "Utiliser l’objet sélectionné", function() app.workshop:selectVehicle(app.actions:selected()) end)
	button(app, vehicle, "Rejoindre le véhicule", function() app:goTo(app.workshop:requireVehicle()) end)
	button(app, vehicle, "Prendre le volant", function() app.workshop:seat() end)
	button(app, vehicle, "Sortir du véhicule", function() if app.humanoid then app.humanoid.Sit = false end end)
	button(app, vehicle, "Redresser le véhicule vide", function() app.workshop:flipVehicle() end)
	button(app, vehicle, "Ramener le véhicule vide à la base", function() app.workshop:moveVehicle("Base") end)
	button(app, vehicle, "Amener le véhicule vide devant moi", function() app.workshop:moveVehicle("Devant moi") end)
	button(app, vehicle, "Frein d’urgence", function() app.workshop:brake() end)
	local cargo = tab:createSection("Chargement")
	cargo:addKeybind({ name = "Définir la benne sous le curseur", default = Enum.KeyCode.J,
		callback = protect(app, function() app.workshop:captureCargo() end) })
	button(app, cargo, "Charger mon bois proche", function() app.workshop:load("Bois") end)
	button(app, cargo, "Charger mes boîtes proches", function() app.workshop:load("Boîtes") end)
	button(app, cargo, "Charger le groupe", function() app.workshop:load("Groupe") end)
	button(app, cargo, "Décharger au dépôt", function() app.workshop:unload() end)
	local driving = tab:createSection("Conduite locale")
	slider(app, driving, "Vitesse moteur", "vehicleSpeed", 0.5, 8, 0.1)
	button(app, driving, "Appliquer la vitesse", function() app.workshop:applyVehicleSpeed(true) end)
	button(app, driving, "Restaurer la vitesse", function() app.workshop:applyVehicleSpeed(false) end)
end

local function inventoryTab(app)
	local tab = app.window:createTab({ name = "Inventaire", icon = "backpack" })
	local tools = tab:createSection("Outils")
	dropdown(app, tools, "Outil", "tools")
	button(app, tools, "Équiper", function()
		app.world:requireReady()
		local tool = app.tools[app.selectors.tools:get()]
		assert(tool and tool.Parent, "Outil indisponible.")
		app.humanoid:EquipTool(tool)
	end)
	button(app, tools, "Équiper la meilleure hache", function() app.timber:equipBest(app.actions.selection) end)
	button(app, tools, "Déséquiper", function() app.world:requireReady(); app.humanoid:UnequipTools() end)
	button(app, tools, "Déposer l’outil équipé", function()
		app.queue:push("Déposer l’outil", function(context) app.actions:dropEquipped(context) end)
	end)
	button(app, tools, "Ramasser l’outil sélectionné", function()
		local model = app.actions:selected()
		app.queue:push("Ramasser l’outil", function(context) app.actions:pickup(context, model) end)
	end)
	button(app, tools, "Ramasser tous mes outils proches", function() app.actions:pickupNearby() end)
	local storage = tab:createSection("Stockage")
	button(app, storage, "Ranger mes outils au dépôt", function()
		app.workshop:arrange(app.world:owned("Outils", app.settings.workRadius), app.actions:point("Dépôt"), "Grille", "Ranger les outils")
	end)
	button(app, storage, "Ranger mes boîtes au dépôt", function()
		app.workshop:arrange(app.world:owned("Boîtes", app.settings.workRadius), app.actions:point("Dépôt"), "Grille", "Ranger les boîtes")
	end)
end

local function routeTab(app)
	local tab = app.window:createTab({ name = "Trajets", icon = "route" })
	local path = tab:createSection("Itinéraire")
	local name = path:addInput({ name = "Nom de l’étape", default = "Étape", maxLength = 24 })
	label(app, path, "route", "Aucune étape")
	dropdown(app, path, "Étape", "routePoints")
	button(app, path, "Ajouter ma position", function() app.routes:add(name:get()) end)
	button(app, path, "Rejoindre l’étape", function()
		local point = app.routes.points[selectedIndex(app)]
		assert(point, "Sélectionnez une étape.")
		app:teleport(point.frame.Position)
	end)
	button(app, path, "Monter l’étape", function() app.routes:moveStep(selectedIndex(app), -1) end)
	button(app, path, "Descendre l’étape", function() app.routes:moveStep(selectedIndex(app), 1) end)
	button(app, path, "Retirer l’étape", function() app.routes:remove(selectedIndex(app)) end)
	button(app, path, "Inverser le parcours", function() app.routes:reverse() end)
	button(app, path, "Effacer le parcours", function() app.routes:clear() end)
	local run = tab:createSection("Déplacement")
	button(app, run, "Parcourir en téléportation", function() app.routes:run("Téléportation", false) end)
	button(app, run, "Parcourir à pied", function() app.routes:run("Marche", false) end)
	button(app, run, "Retour à pied", function() app.routes:run("Marche", true) end)
	button(app, run, "Marcher vers l’objet sélectionné", function() app.routes:walkToSelection() end)
	slider(app, run, "Tours", "routeLoops", 1, 20)
	slider(app, run, "Pause à chaque étape", "routeDelay", 0.25, 30, 0.25)
	local travel = tab:createSection("Accès rapide")
	dropdown(app, travel, "Magasin", "shops")
	button(app, travel, "Rejoindre le magasin", function() app:goTo(app.shops[app.selectors.shops:get()]) end)
	button(app, travel, "Rejoindre ma base", function() app.actions:returnHome() end)
	button(app, travel, "Rejoindre mon dépôt", function() app:teleport(app.actions:point("Dépôt").Position) end)
	button(app, travel, "Revenir en arrière", function() app:back() end)
	local storage = tab:createSection("Parcours enregistrés")
	local profile = storage:addInput({ name = "Nom", default = "travail", maxLength = 24,
		validate = function(text) return text:match("^[%w_-]+$") ~= nil, "Lettres, chiffres et tirets uniquement." end })
	button(app, storage, "Enregistrer le parcours et les points", function() app.routes:save(profile:get()) end)
	button(app, storage, "Charger le parcours et les points", function() app.routes:load(profile:get()) end)
end

local function cooperativeTab(app)
	local tab = app.window:createTab({ name = "Coop / Alt", icon = "users" })
	local target = tab:createSection("Compte destinataire")
	dropdown(app, target, "Joueur / Alt", "players")
	local identifier = target:addInput({ name = "UserId de l’alt", maxLength = 18, placeholder = "UserId" })
	button(app, target, "Sélectionner cet alt", function()
		local userId = tonumber(identifier:get())
		assert(userId and userId > 0 and userId % 1 == 0, "UserId invalide.")
		local candidate = Players:GetPlayerByUserId(userId)
		assert(candidate and candidate ~= player, "Cet alt n’est pas présent dans ce serveur.")
		app.selectors.players:set(candidate.Name, false)
	end)
	button(app, target, "Rejoindre", function() app:goTo(selectedTarget(app).Character) end)
	button(app, target, "Suivre à pied", function() app.routes:follow(selectedTarget(app)) end)
	button(app, target, "Arrêter le suivi", function() app.routes:stopFollow() end)
	slider(app, target, "Distance de suivi", "followDistance", 3, 25)
	local transfer = tab:createSection("Livraisons entre comptes")
	button(app, transfer, "Déposer la sélection près du joueur", function() app.workshop:stageForPlayer(selectedTarget(app), false) end)
	button(app, transfer, "Déposer le groupe près du joueur", function() app.workshop:stageForPlayer(selectedTarget(app), true) end)
	transfer:addLabel({ text = "Dépôt physique de vos objets. Le propriétaire et les permissions restent gérés par le jeu.", height = 52, wrapped = true })
	local money = tab:createSection("Don d’argent")
	local amount = money:addInput({ name = "Montant", default = "100", maxLength = 9,
		validate = function(text)
			local number = tonumber(text)
			return number and number > 0 and number % 1 == 0, "Montant entier positif requis."
		end })
	button(app, money, "Envoyer ce don", function() app.workshop:donate(selectedTarget(app), tonumber(amount:get())) end)
	local camera = tab:createSection("Caméra du compte choisi")
	button(app, camera, "Observer le joueur", function() app:spectate(selectedTarget(app)) end)
	button(app, camera, "Reprendre ma caméra", function() app:spectate(nil) end)
end

Workbench.initialize = function(app, modules)
	for key, value in pairs(defaults) do app.settings[key] = value end
	app.queue = modules.Queue.new(app)
	app.world = modules.World.new(app)
	app.actions = modules.Actions.new(app)
	app.timber = modules.Timber.new(app, modules.AxeSpecs)
	app.market = modules.Market.new(app)
	app.workshop = modules.Workshop.new(app)
	app.routes = modules.Routes.new(app)
	app.pipeline = modules.Pipeline.new(app)
	app.construction = modules.Construction.new(app)
	app.merchants = {}
	local destroy = app.destroy
	app.destroy = function(self)
		if self.isDestroyed or self.isClosingWorkbench then return end
		self.isClosingWorkbench = true
		self.queue:destroy()
		self.routes:stopFollow()
		self.construction:cancel()
		pcall(function() self.market:close() end)
		destroy(self)
	end
end

Workbench.build = function(app)
	automationTab(app)
	timberTab(app)
	marketTab(app)
	workshopTab(app)
	constructionTab(app)
	vehicleTab(app)
	inventoryTab(app)
	routeTab(app)
	cooperativeTab(app)
end

Workbench.bind = function(app)
	app.world:bind()
	app.actions:bind()
	app.routes:bind()
	app.pipeline:bind()
	app:connect("AutomationDespawn", player.CharacterRemoving, function()
		for _, flag in ipairs({ "isAutoTools", "isAutoBoxes", "isAutoWood" }) do app.window:setFlag(flag, false) end
	end)
	app.merchants = app.world:npcOptions()
	app:selectOptions("merchants", app.merchants)
	app:selectOptions("buyItem", app.world.catalog)
	app.selectors.woodClass:setOptions(app.world:treeClasses(), false)
	app.queue:update()
end

return Workbench

end)()

local Interface = (function()
local Interface = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local function action(app, callback)
	return function(...)
		if app.isDestroyed then return end
		local isSuccess, message = pcall(callback, ...)
		if not isSuccess then app:notice(tostring(message)) end
	end
end

local function addButton(app, section, name, callback, tooltip)
	return section:addButton({ name = name, callback = action(app, callback), tooltip = tooltip })
end

local function addToggle(app, section, key, name, callback, shouldSave)
	return section:addToggle({ id = key, name = name, default = app.settings[key] == true, shouldSave = shouldSave ~= false,
		callback = action(app, function(isEnabled)
			app.settings[key] = isEnabled
			if callback then callback(isEnabled) end
		end) })
end

local function addSlider(app, section, key, name, minimum, maximum, step, callback)
	return section:addSlider({ id = key, name = name, min = minimum, max = maximum, step = step,
		default = app.settings[key] or minimum, callback = action(app, function(number)
			app.settings[key] = number
			if callback then callback(number) end
		end) })
end

local function addSelector(app, section, key, name, callback)
	local selector = section:addDropdown({ name = name, options = {}, searchable = true,
		callback = callback and action(app, callback), maxVisible = 7 })
	app.selectors[key] = selector
	return selector
end

local function selected(app, key)
	local selector = app.selectors[key]
	return selector and app[key] and app[key][selector:get()] or nil
end

local function playerTab(app)
	local tab = app.window:createTab({ name = "Player", icon = "user" })
	local status = tab:createSection("Personnage")
	app.labels.health = status:addLabel({ text = "Vie : —" })
	app.labels.money = status:addLabel({ text = "Argent : —" })
	app.labels.slot = status:addLabel({ text = "Sauvegarde : —" })
	app.labels.busy = status:addLabel({ text = "Sauvegarde en cours : —", height = 34, wrapped = true })
	addButton(app, status, "Actualiser", function() app:updateStats() end)
	local speed = tab:createSection("Marche / Sprint")
	addToggle(app, speed, "isSpeed", "Vitesse personnalisée", function() app:updateCharacter() end)
	addSlider(app, speed, "speed", "Vitesse", 8, 100, 1, function() app:updateCharacter() end)
	addToggle(app, speed, "isSprint", "Sprint avec Shift", function() app:updateCharacter() end)
	addSlider(app, speed, "sprint", "Multiplicateur", 1, 3, 0.1, function() app:updateCharacter() end)
	local jump = tab:createSection("Saut")
	addToggle(app, jump, "isJump", "Saut personnalisé", function() app:updateCharacter() end)
	addSlider(app, jump, "jump", "Puissance", 20, 150, 1, function() app:updateCharacter() end)
	addToggle(app, jump, "isAirJump", "Saut aérien", nil, false)
	addButton(app, jump, "Se relever", function()
		if app.humanoid then app.humanoid.Sit = false; app.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
	end)
end

local function movementTab(app)
	local tab = app.window:createTab({ name = "Movement", icon = "chevrons-up-down" })
	local flight = tab:createSection("Fly")
	app.flyToggle = addToggle(app, flight, "isFlying", "Activer le vol", function(isEnabled)
		if not app:setFly(isEnabled) then app.flyToggle:set(false, false) end
	end, false)
	addSlider(app, flight, "flySpeed", "Vitesse", 5, 160, 1)
	addSlider(app, flight, "vertical", "Axe vertical", -1, 1, 0.1)
	flight:addLabel({ text = "Déplacement habituel · Espace / Ctrl : monter / descendre", height = 46, wrapped = true })
	flight:addKeybind({ name = "Vol", default = Enum.KeyCode.F, callback = action(app, function() app.flyToggle:set(not app.settings.isFlying) end) })
	local physics = tab:createSection("Physique locale")
	addToggle(app, physics, "isNoclip", "Noclip", function(isEnabled) app:setNoclip(isEnabled) end, false)
	app.settings.gravity = Workspace.Gravity
	local function applyGravity()
		app:restore("Gravity")
		if app.settings.isGravity then app:patch("Gravity", Workspace, "Gravity", app.settings.gravity) end
	end
	addToggle(app, physics, "isGravity", "Gravité personnalisée", applyGravity, false)
	addSlider(app, physics, "gravity", "Gravité", 0, 300, 1, applyGravity)
	local recovery = tab:createSection("Récupération")
	addButton(app, recovery, "Arrêter le vol", function() app.flyToggle:set(false) end)
	addButton(app, recovery, "Annuler la vitesse", function()
		if app.root then app.root.AssemblyLinearVelocity = Vector3.zero; app.root.AssemblyAngularVelocity = Vector3.zero end
	end)
	addButton(app, recovery, "Sortir du véhicule", function() if app.humanoid then app.humanoid.Sit = false end end)
	addButton(app, recovery, "Revenir en arrière", function() app:back() end)
end

local function cameraTab(app)
	local tab = app.window:createTab({ name = "Camera", icon = "eye" })
	local lens = tab:createSection("Objectif")
	addToggle(app, lens, "isFov", "FOV personnalisé", function() app:applyCamera() end)
	addSlider(app, lens, "fov", "FOV", 40, 120, 1, function() app:applyCamera() end)
	addToggle(app, lens, "isFirstPerson", "Première personne", function(isEnabled)
		app:restore("FirstPerson")
		if isEnabled then app:patch("FirstPerson", player, "CameraMode", Enum.CameraMode.LockFirstPerson) end
	end)
	local zoom = tab:createSection("Zoom")
	app.settings.zoom = 128
	local function applyZoom()
		app:restore("Zoom")
		if app.settings.isZoom then
			app:patch("Zoom", player, "CameraMinZoomDistance", 0.5)
			app:patch("Zoom", player, "CameraMaxZoomDistance", app.settings.zoom)
		end
	end
	addToggle(app, zoom, "isZoom", "Zoom étendu", applyZoom)
	addSlider(app, zoom, "zoom", "Distance max.", 10, 500, 1, applyZoom)

	local follow = tab:createSection("Suivi")
	addButton(app, follow, "Suivre le joueur choisi", function()
		local target = app:selectedPlayer()
		if target then app:spectate(target) else app:notice("Choisissez un joueur dans Players.") end
	end)
	addButton(app, follow, "Revenir à ma caméra", function() app:spectate(nil) end)
	addButton(app, follow, "Centrer l’interface", function() app.window:center() end)
end

local function visualsTab(app)
	local tab = app.window:createTab({ name = "Visuals", icon = "sun" })
	local light = tab:createSection("Éclairage local")
	addToggle(app, light, "isFullbright", "Fullbright", function() app:applyLighting() end)
	addToggle(app, light, "isNoFog", "Retirer le brouillard", function() app:applyLighting() end)
	addToggle(app, light, "isNoShadows", "Retirer les ombres", function() app:applyLighting() end)
	local clock = tab:createSection("Heure locale")
	addToggle(app, clock, "isClock", "Fixer l’heure", function() app:applyLighting() end)
	addSlider(app, clock, "clock", "Heure", 0, 24, 0.25, function() app:applyLighting() end)
	addButton(app, clock, "Midi", function() app.window:setFlag("clock", 12); app.window:setFlag("isClock", true) end)
	addButton(app, clock, "Minuit", function() app.window:setFlag("clock", 0); app.window:setFlag("isClock", true) end)
	local effects = tab:createSection("Effets / Repères")
	local function disableEffect(instance)
		if app.settings.isNoEffects and instance:IsA("PostEffect") then app:patch("Effects", instance, "Enabled", false) end
	end
	addToggle(app, effects, "isNoEffects", "Sans post-traitement", function(isEnabled)
		app:restore("Effects")
		if isEnabled then
			for _, effect in ipairs(Lighting:GetChildren()) do disableEffect(effect) end
			if Workspace.CurrentCamera then for _, effect in ipairs(Workspace.CurrentCamera:GetChildren()) do disableEffect(effect) end end
		end
	end)
	app.disableEffect = disableEffect
	app:connect("LightingEffect", Lighting.ChildAdded, disableEffect)
	effects:addColorPicker({ name = "Repères", default = app.settings.markerColor, callback = action(app, function(color)
		app.settings.markerColor = color
		for _, marker in pairs(app.markers) do marker.FillColor, marker.OutlineColor = color, color end
	end) })
	addButton(app, effects, "Effacer les repères", function() app:clearMarkers() end)
end

local function settingsTab(app)
	local tab = app.window:createTab({ name = "Settings", icon = "settings" })
	local theme = tab:createSection("Underlord")
	theme:addColorPicker({ name = "Accent", default = app.window.theme.accent, callback = action(app,function(color) app.window:setAccent(color) end) })
	theme:addSlider({ name = "Échelle", min = 0.5, max = 1.2, step = 0.05, default = 0.95, callback = action(app,function(scale)
		app.window.theme.scale = scale; app.window:setSize(app.window.theme.size)
	end) })
	theme:addKeybind({ name = "Afficher / Masquer", default = Enum.KeyCode.RightShift,
		onChanged = action(app,function(key) app.window.theme.toggleKey = key end) })
	addButton(app, theme, "Centrer", function() app.window:center() end)
	local profiles = tab:createSection("Profils locaux")
	local name = profiles:addInput({ name = "Profil", default = "lt2", maxLength = 32 })
	addButton(app, profiles, "Enregistrer", function()
		local isSuccess, message = app.window:saveConfig(name:get()); app:notice(isSuccess and "Profil enregistré." or message)
	end)
	addButton(app, profiles, "Charger", function()
		local isSuccess, message = app.window:loadConfig(name:get(),true); app:notice(isSuccess and "Profil chargé." or message)
	end)
	addButton(app, profiles, "Réinitialiser", function() app.window:reset(true) end)
	local session = tab:createSection("Session")

	addButton(app, session, "Masquer l’interface", function() app.window:setVisible(false) end)
	addButton(app, session, "Fermer et restaurer", function() app:destroy() end)
end

Interface.build = function(app)
	playerTab(app)
	movementTab(app)
	cameraTab(app)
	visualsTab(app)
	settingsTab(app)
end

return Interface

end)()

local Players = game:GetService("Players")
assert(Players.LocalPlayer, "Contexte client requis.")
assert(game.PlaceId == 13822889 or game.GameId == 2471084, "Ce script cible Lumber Tycoon 2.")

local storage
if type(readfile) == "function" and type(writefile) == "function" then
	storage = { read = readfile, write = writefile }
end

assert(type(Underlord) == "table" and type(Underlord.new) == "function", "Mettez à jour Library.lua avec la source Underlord fournie.")

local window = Underlord.new({ name = "UnderlordLT2", version = " LT2", storage = storage,
	theme = { scale = 0.95, size = Vector2.new(780,470) } })
local app = Runtime.new(window)
Workbench.initialize(app, {
	Queue = Queue,
	World = World,
	Actions = Actions,
	Timber = Timber,
	Market = Market,
	Workshop = Workshop,
	Routes = Routes,
	AxeSpecs = AxeSpecs,
	Pipeline = Pipeline,
	Construction = Construction,
})
local isSuccess, message = pcall(function()
	Workbench.build(app)
	Interface.build(app)
	app:bind()
	Workbench.bind(app)
end)
if not isSuccess then app:destroy(); error(message,0) end

task.defer(function()
	if app.isDestroyed then return end
	local hasScanned, scanError = pcall(function() app:scanWorld() end)
	if not hasScanned then app.isScanning = false; app:notice(scanError) end
end)

return app
