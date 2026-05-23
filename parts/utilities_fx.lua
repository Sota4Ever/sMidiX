-- ═══════════════════════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════

local _normalizeCache = {}
local function normalizeArtist(name)
    name = tostring(name or "Unknown")
    local cached = _normalizeCache[name]
    if cached then return cached end
    local result = name:match("^%s*(.-)%s*$") or name
    result = result:gsub("%s+", " ")
    if result == "" then result = "Unknown" end
    _normalizeCache[name] = result
    return result
end

local function songFavKey(song)
    return normalizeArtist(song.artist) .. "\0" .. (song.title or "")
end

local function fitDimension(desired, minimum, maximum, available)
    local hardMax = math.max(math.min(maximum, available), 240)
    local hardMin = math.min(minimum, hardMax)
    return math.max(math.min(desired, hardMax), hardMin)
end

local function getViewportSize()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

-- Detect small screen globally (updated on each buildGUI call)
-- Only triggers on truly tiny screens (below ~360dp), NOT on normal mobile (400dp+)
IS_SMALL_SCREEN = false
local function updateSmallScreenFlag()
    local viewport = getViewportSize()
    IS_SMALL_SCREEN = (viewport.X < 420 or viewport.Y < 360)
end

local function getWindowMetrics()
    local viewport = getViewportSize()
    updateSmallScreenFlag()

    local SS = IS_SMALL_SCREEN

    -- Only reduce margins for small screens; normal devices keep original spacing
    local availableW = math.max(SS and 200 or 320, viewport.X - (SS and 16 or 24))
    local availableH = math.max(SS and 200 or 360, viewport.Y - (SS and 16 or 24))

    -- Detect small screens to fill more of the viewport
    local smallW = viewport.X < 420
    local smallH = viewport.Y < 360

    local normalW = fitDimension(
        IS_MOBILE and math.floor(viewport.X * 0.96) or (smallW and math.floor(viewport.X * 0.94) or math.floor(viewport.X * 0.78)),
        IS_MOBILE and (SS and 240 or 340) or (smallW and 280 or 920),
        IS_MOBILE and 760 or 1120,
        availableW
    )
    local normalH = fitDimension(
        IS_MOBILE and math.floor(viewport.Y * (smallH and 0.92 or 0.84)) or (smallH and math.floor(viewport.Y * 0.90) or math.floor(viewport.Y * 0.76)),
        IS_MOBILE and (SS and 240 or 470) or (smallH and 280 or 560),
        IS_MOBILE and 700 or 700,
        availableH
    )

    local maxW = fitDimension(
        IS_MOBILE and availableW or math.floor(viewport.X * 0.92),
        normalW, availableW, availableW
    )
    local maxH = fitDimension(
        IS_MOBILE and availableH or math.floor(viewport.Y * 0.88),
        normalH, availableH, availableH
    )

    local dockW = fitDimension(IS_MOBILE and math.floor(viewport.X * 0.88) or 430, SS and 280 or 320, 460, availableW)
    local dockH = IS_MOBILE and 60 or 56

    return {
        normalSize  = UDim2.new(0, normalW, 0, normalH),
        normalPos   = UDim2.new(0.5, -math.floor(normalW / 2), 0.5, -math.floor(normalH / 2)),
        maxSize     = UDim2.new(0, maxW, 0, maxH),
        maxPos      = UDim2.new(0.5, -math.floor(maxW / 2), 0.5, -math.floor(maxH / 2)),
        dockSize    = UDim2.new(0, dockW, 0, dockH),
        dockPos     = UDim2.new(0.5, -math.floor(dockW / 2), 1, -(dockH + 16)),
        launcherPos = UDim2.new(0, 16, 1, -58),
    }
end

local function offsetPos(pos, dx, dy)
    return UDim2.new(pos.X.Scale, pos.X.Offset + dx, pos.Y.Scale, pos.Y.Offset + dy)
end

tweenObject = function(obj, goals, duration, style, direction)
    if not obj then return end
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
        goals
    )
    tween:Play()
    return tween
end

local function addStroke(target, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or C.border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = target
    return stroke
end

local function addPadding(target, left, right, top, bottom)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or 0)
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or 0)
    padding.Parent = target
    return padding
end

local function addGradient(target, topColor, bottomColor, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(topColor, bottomColor)
    gradient.Rotation = rotation or 90
    gradient.Parent = target
    return gradient
end

local _durationCache = {}
local function getSongDuration(song)
    if not song then return 0 end
    local cached = _durationCache[song]
    if cached then return cached end
    local total = 0
    if song.events then
        for _, event in ipairs(song.events) do
            total = total + (tonumber(event.time) or 0)
        end
    end
    local result = total / Config.baseSpeed
    _durationCache[song] = result
    return result
end

local function formatDuration(seconds)
    local rounded = math.max(0, math.floor((seconds or 0) + 0.5))
    local mins = math.floor(rounded / 60)
    local secs = rounded % 60
    return string.format("%d:%02d", mins, secs)
end

local function getStatusText()
    if isRunning and not paused then return T("status_playing") end
    if paused then return T("status_paused") end
    return T("status_ready")
end

local function getStatusColor()
    if isRunning and not paused then return C.play end
    if paused then return C.pause end
    return C.accent
end

local function getStatusTextColor()
    local color = getStatusColor()
    if color == C.stop then return C.text end
    return C.selectedText
end

local function newFrame(parent, size, pos, color, radius)
    local f = Instance.new("Frame")
    f.Size = size; f.Position = pos
    f.BackgroundColor3 = color or C.bg2
    f.BorderSizePixel = 0; f.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = f
    return f
end

local function newLabel(parent, text, size, pos, bgColor, textColor, fontSize, xAlign)
    local l = Instance.new("TextLabel")
    l.Size = size; l.Position = pos; l.Text = text
    l.BackgroundColor3 = bgColor or C.bg2
    l.BackgroundTransparency = bgColor and 0 or 1
    l.TextColor3 = textColor or C.text
    l.Font = Enum.Font.GothamMedium
    l.TextSize = fontSize or FSIZE
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.BorderSizePixel = 0
    l.Parent = parent
    return l
end

local function newButton(parent, text, size, pos, bgColor, hoverColor, onClick, textColor)
    local btn = Instance.new("TextButton")
    btn.Size             = size
    btn.Position         = pos
    btn.Text             = text
    btn.BackgroundColor3 = bgColor
    btn.TextColor3       = textColor or C.text
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = FSIZE
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    btn.Active           = true
    btn.Parent           = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    addStroke(btn, C.border, 1, 0.45)
    btn.Activated:Connect(onClick)
    if not IS_MOBILE then
        btn.MouseEnter:Connect(function()
            if btn:GetAttribute("Locked") then return end
            tweenObject(btn, {BackgroundColor3 = hoverColor}, 0.12)
        end)
        btn.MouseLeave:Connect(function()
            if btn:GetAttribute("Locked") then return end
            tweenObject(btn, {BackgroundColor3 = bgColor}, 0.12)
        end)
    end
    return btn
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INTERACTION FX
-- ═══════════════════════════════════════════════════════════════════════════
local function ensureFxLayer(sg)
    if windowRefs and windowRefs.fxLayer and windowRefs.fxLayer.Parent then
        return windowRefs.fxLayer
    end
    local fx = Instance.new("Frame")
    fx.Name = "FXLayer"
    fx.BackgroundTransparency = 1
    fx.BorderSizePixel = 0
    fx.Size = UDim2.new(1, 0, 1, 0)
    fx.Position = UDim2.new(0, 0, 0, 0)
    fx.ZIndex = 9999
    fx.Parent = sg
    windowRefs.fxLayer = fx
    return fx
end

local function toVec2(p)
    local v = Vector2.new(p.X, p.Y)
    local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
    if ok and inset then
        v = v + Vector2.new(inset.X, inset.Y)
    end
    return v
end

local function spawnRipple(screenPos, col)
    local fx = (windowRefs and windowRefs.fxLayer)
    if not (fx and fx.Parent) then return end

    col = col or C.accentBlue
    local maxR = IS_MOBILE and 150 or 180
    local ring = Instance.new("Frame")
    ring.Name = "Ripple"
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
    ring.Size = UDim2.new(0, 10, 0, 10)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.ZIndex = fx.ZIndex
    ring.Parent = fx

    local stroke = Instance.new("UIStroke")
    stroke.Color = col
    stroke.Thickness = 2
    stroke.Transparency = 0.15
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = ring
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0.5, 0); corner.Parent = ring

    tweenObject(ring, {Size = UDim2.new(0, maxR, 0, maxR)}, 0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tweenObject(stroke, {Transparency = 1}, 0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    task.delay(0.45, function() if ring and ring.Parent then ring:Destroy() end end)

    local pieces = IS_MOBILE and 10 or 14
    for i = 1, pieces do
        local p = Instance.new("Frame")
        p.Name = "Foam"
        p.AnchorPoint = Vector2.new(0.5, 0.5)
        p.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
        p.Size = UDim2.new(0, math.random(3, 6), 0, math.random(3, 6))
        p.BackgroundColor3 = Color3.fromRGB(210, 245, 255)
        p.BackgroundTransparency = 0.12
        p.BorderSizePixel = 0
        p.ZIndex = fx.ZIndex
        p.Parent = fx
        local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0.5, 0); pc.Parent = p

        local ang = math.random() * math.pi * 2
        local dist = math.random(24, maxR * 0.45)
        local drift = Vector2.new(math.cos(ang) * dist, math.sin(ang) * dist)
        tweenObject(p, {Position = UDim2.new(0, screenPos.X + drift.X, 0, screenPos.Y + drift.Y)}, 0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        tweenObject(p, {BackgroundTransparency = 1}, 0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.delay(0.45, function() if p and p.Parent then p:Destroy() end end)
    end
end

local function spawnVizSplash(screenPos, col)
    local viz = windowRefs and windowRefs.vizCard
    if not (viz and viz.Parent) then return end
    col = col or C.accentBlue

    local ap = viz.AbsolutePosition
    local as = viz.AbsoluteSize
    if as.X <= 1 or as.Y <= 1 then return end
    local lx = math.clamp(screenPos.X - ap.X, 8, as.X - 8)
    local ly = math.clamp(screenPos.Y - ap.Y, 8, as.Y - 8)

    local splash = Instance.new("Frame")
    splash.Name = "VizSplash"
    splash.BackgroundTransparency = 1
    splash.BorderSizePixel = 0
    splash.Size = UDim2.new(0, 1, 0, 1)
    splash.Position = UDim2.new(0, lx, 0, ly)
    splash.ZIndex = 50
    splash.Parent = viz

    local n = IS_MOBILE and 10 or 16
    for i = 1, n do
        local drop = Instance.new("Frame")
        drop.AnchorPoint = Vector2.new(0.5, 0.5)
        drop.Position = UDim2.new(0, 0, 0, 0)
        local sz = math.random(3, 8)
        drop.Size = UDim2.new(0, sz, 0, sz)
        drop.BackgroundColor3 = Color3.fromRGB(210, 245, 255)
        drop.BackgroundTransparency = 0.06
        drop.BorderSizePixel = 0
        drop.ZIndex = 50
        drop.Parent = splash
        local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0.5, 0); dc.Parent = drop

        local ang = (-math.pi/2) + (math.random() - 0.5) * 1.6
        local dist = math.random(20, 60)
        local dx = math.cos(ang) * dist
        local dy = math.sin(ang) * dist
        tweenObject(drop, {Position = UDim2.new(0, dx, 0, dy)}, 0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        tweenObject(drop, {BackgroundTransparency = 1}, 0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    local flash = Instance.new("Frame")
    flash.BackgroundColor3 = col
    flash.BackgroundTransparency = 0.86
    flash.BorderSizePixel = 0
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.Position = UDim2.new(0, 0, 0, 0)
    flash.ZIndex = 20
    flash.Parent = viz
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 12); fc.Parent = flash
    tweenObject(flash, {BackgroundTransparency = 1}, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    task.delay(0.45, function()
        if splash and splash.Parent then splash:Destroy() end
        if flash and flash.Parent then flash:Destroy() end
    end)
end

local function triggerInteractionFX(screenPos)
    if not (windowRefs and windowRefs.fxLayer and windowRefs.fxLayer.Parent) then return end

    windowRefs.fxLast = windowRefs.fxLast or 0
    local now = os.clock()
    if now - windowRefs.fxLast < (IS_MOBILE and 0.07 or 0.05) then return end
    windowRefs.fxLast = now

    local col = C.accentBlue
    spawnRipple(screenPos, col)
    spawnVizSplash(screenPos, col)

    windowRefs.interactionSpikeEnd = now + 0.28

    if windowRefs.vizStroke and windowRefs.vizStroke.Parent then
        tweenObject(windowRefs.vizStroke, {Color = Color3.fromRGB(140, 220, 255), Transparency = 0.05}, 0.14)
        task.delay(0.18, function()
            if windowRefs and windowRefs.vizStroke and windowRefs.vizStroke.Parent then
                tweenObject(windowRefs.vizStroke, {Transparency = 0.40}, 0.22)
            end
        end)
    end
end

local function attachInteractionFX(obj)
    if not obj then return end
    if obj:GetAttribute("sMidiXFXAttached") then return end
    obj:SetAttribute("sMidiXFXAttached", true)

    local dragging = false
    local dragInput = nil
    local lastDragFx = 0

    obj.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = inp
            triggerInteractionFX(toVec2(inp.Position))
        end
    end)
    obj.InputEnded:Connect(function(inp)
        if inp == dragInput then
            dragging = false
            dragInput = nil
        end
    end)
    obj.InputChanged:Connect(function(inp)
        if dragging and dragInput and inp.UserInputType == dragInput.UserInputType then
            local t = os.clock()
            if t - lastDragFx > (IS_MOBILE and 0.10 or 0.08) then
                lastDragFx = t
                triggerInteractionFX(toVec2(inp.Position))
            end
        end
    end)
end

local function setupGlobalInteractionFX(sg, titleBar)
    if not (sg and sg.Parent) then return end
    ensureFxLayer(sg)

    local function scan(root)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("TextButton") or d:IsA("ImageButton") or d:IsA("ScrollingFrame") then
                attachInteractionFX(d)
            end
        end
    end
    scan(sg)
    sg.DescendantAdded:Connect(function(d)
        if d:IsA("TextButton") or d:IsA("ImageButton") or d:IsA("ScrollingFrame") then
            attachInteractionFX(d)
        end
    end)

    if titleBar then
        local last = 0
        titleBar.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                local t = os.clock()
                if t - last > (IS_MOBILE and 0.12 or 0.10) then
                    last = t
                    triggerInteractionFX(toVec2(inp.Position))
                end
            end
        end)
    end
end

local function refreshSongButton(entry, active)
    if not entry then return end
    entry.isActive = active
    entry.button.BackgroundColor3 = active and C.accent or C.card
    entry.button.BackgroundTransparency = active and 0.02 or 0.12
    entry.title.TextColor3 = active and C.selectedText or C.text
    entry.meta.TextColor3 = active and C.selectedText or C.textSub
    entry.indicator.BackgroundTransparency = active and 0 or 0.82
    entry.indicator.BackgroundColor3 = active and C.accentBlue or C.border
    entry.stroke.Transparency = active and 0.12 or 0.48
end

local function refreshSectionButton(name)
    local entry = sectionButtons[name]
    if not entry then return end
    local active = currentSection == name
    local col = active and C.selectedText or C.textSub
    entry.button.BackgroundColor3 = active and C.accent or C.bg2
    entry.button.BackgroundTransparency = active and 0.02 or 0.16
    entry.button.TextColor3 = col
    entry.pill.BackgroundTransparency = active and 0 or 1
    if entry.label then entry.label.TextColor3 = col end
    for _, child in ipairs(entry.button:GetChildren()) do
        if child:IsA("Frame") and child ~= entry.pill then
            for _, f in ipairs(child:GetDescendants()) do
                if f:IsA("Frame") and f.BackgroundTransparency < 1 then
                    f.BackgroundColor3 = col
                elseif f:IsA("UIStroke") then
                    f.Color = col
                end
            end
            for _, f in ipairs(child:GetChildren()) do
                if f:IsA("Frame") and f.BackgroundTransparency < 1 then
                    f.BackgroundColor3 = col
                end
            end
        end
    end
end

local function refreshToggleRow(row)
    if not row then return end
    local active = row.get()
    row.track.BackgroundColor3 = active and C.accent or C.bg4
    row.track.BackgroundTransparency = active and 0.06 or 0.22
    row.knob.Position = active and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    row.knob.BackgroundColor3 = active and C.selectedText or C.text
    row.title.TextColor3 = active and C.text or C.textSub
    row.stroke.Transparency = active and 0.22 or 0.5
end

local function animatePanel(scaleRef)
    if not scaleRef then return end
    scaleRef.Scale = 0.96
    tweenObject(scaleRef, {Scale = 1.0}, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function setSection(sectionName)
    currentSection = sectionName
    local isLib = (sectionName == "library")
    if windowRefs.libraryPane then
        windowRefs.libraryPane.Visible = isLib
    end
    if windowRefs.content and windowRefs.contentX_lib and windowRefs.contentX_nav then
        local cx = isLib and windowRefs.contentX_lib or windowRefs.contentX_nav
        windowRefs.content.Size = UDim2.new(1, -cx, 1, 0)
        windowRefs.content.Position = UDim2.new(0, cx, 0, 0)
    end
    if windowRefs.libContent  then windowRefs.libContent.Visible  = isLib;                    if isLib then animatePanel(windowRefs.libScale) end end
    if windowRefs.optContent  then windowRefs.optContent.Visible  = (sectionName=="options");  if sectionName=="options"   then animatePanel(windowRefs.optScale)  end end
    if windowRefs.consContent then windowRefs.consContent.Visible = (sectionName=="console");  if sectionName=="console"   then animatePanel(windowRefs.consScale)  end end
    if windowRefs.langContent then windowRefs.langContent.Visible = (sectionName=="languages");if sectionName=="languages" then animatePanel(windowRefs.langScale) end end
    for name in pairs(sectionButtons) do refreshSectionButton(name) end
    if windowRefs.sectionLabel then
        local names = { library=T("section_library"), options=T("section_options"), console=T("section_console"), languages=T("section_languages") }
        windowRefs.sectionLabel.Text = string.format("%s  •  %s", names[sectionName] or sectionName, IS_MOBILE and T("touch_label") or T("desktop_label"))
    end
end

local function applyWindowTarget(size, position, duration)
    if not windowRefs.panel or not windowRefs.shadow then return end
    local d = duration or 0.22
    tweenObject(windowRefs.panel,  {Size = size, Position = position}, d)
    tweenObject(windowRefs.shadow, {Size = size, Position = offsetPos(position, 8, 10)}, d)
    if windowRefs.krnlGlow then
        local gs = UDim2.new(size.X.Scale, size.X.Offset + 28, size.Y.Scale, size.Y.Offset + 28)
        tweenObject(windowRefs.krnlGlow, {Size = gs, Position = offsetPos(position, -14, -14)}, d)
    end
end

local function showFullWindow()
    local metrics = getWindowMetrics()
    if not windowRefs.panel then return end
    if windowRefs.maximized then
        applyWindowTarget(metrics.maxSize, metrics.maxPos, 0.22)
    elseif not windowRefs.restoreSize then
        applyWindowTarget(metrics.normalSize, metrics.normalPos, 0.22)
    end
    windowRefs.shadow.Visible = true
    windowRefs.panel.Visible = true
    if windowRefs.krnlGlow then windowRefs.krnlGlow.Visible = true end
    if windowRefs.dock then windowRefs.dock.Visible = false end
    if windowRefs.launcher then windowRefs.launcher.Visible = false end
end

local function showCompactDock()
    if not windowRefs.panel then return end
    windowRefs.shadow.Visible = false
    windowRefs.panel.Visible = false
    if windowRefs.krnlGlow then windowRefs.krnlGlow.Visible = false end
    if windowRefs.dock then windowRefs.dock.Visible = true end
    if windowRefs.launcher then windowRefs.launcher.Visible = false end
end

local function showClosedLauncher()
    if not windowRefs.panel then return end
    windowRefs.shadow.Visible = false
    windowRefs.panel.Visible = false
    if windowRefs.krnlGlow then windowRefs.krnlGlow.Visible = false end
    if windowRefs.dock then windowRefs.dock.Visible = false end
    if windowRefs.launcher then windowRefs.launcher.Visible = true end
end

local function toggleMaximize()
    if not windowRefs.panel then return end
    local metrics = getWindowMetrics()
    if windowRefs.maximized then
        windowRefs.maximized = false
        applyWindowTarget(windowRefs.restoreSize or metrics.normalSize, windowRefs.restorePos or metrics.normalPos, 0.24)
    else
        windowRefs.maximized = true
        windowRefs.restoreSize = windowRefs.panel.Size
        windowRefs.restorePos = windowRefs.panel.Position
        applyWindowTarget(metrics.maxSize, metrics.maxPos, 0.24)
    end
    if windowRefs.maxButton then
        for _, ch in ipairs(windowRefs.maxButton:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        makeWinIcon(windowRefs.maxButton, windowRefs.maximized and "maximize_restore" or "maximize", 12, UDim2.new(0.5,-6,0.5,-6), C.text)
    end
end
