-- ═══════════════════════════════════════════════════════════════════════════
-- buildGUI
-- ═══════════════════════════════════════════════════════════════════════════
local function buildGUI()
    local old = playerGui:FindFirstChild("sMidiXGUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "sMidiXGUI"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = playerGui

    songButtons = {}; toggleRows = {}; sectionButtons = {}; contentPanels = {}
    windowRefs = { maximized = false }
    ensureFxLayer(sg)

    local metrics = getWindowMetrics()
    windowRefs.restoreSize = metrics.normalSize
    windowRefs.restorePos = metrics.normalPos

    -- Adaptive sizes for small screens
    local SS = IS_SMALL_SCREEN  -- shorthand
    local TITLE_H = SS and 38 or (IS_MOBILE and 52 or 48)
    local BODY_Y  = TITLE_H + (SS and 10 or 18)
    local NAV_W   = SS and 44 or (IS_MOBILE and 64 or 96)
    local LIB_W   = SS and 128 or (IS_MOBILE and 148 or 272)

    --Nordic exterior halo
    local sz = metrics.normalSize
    local krnlGlow = newFrame(sg,
        UDim2.new(sz.X.Scale, sz.X.Offset + 28, sz.Y.Scale, sz.Y.Offset + 28),
        UDim2.new(metrics.normalPos.X.Scale, metrics.normalPos.X.Offset - 14,
                  metrics.normalPos.Y.Scale, metrics.normalPos.Y.Offset - 14),
        Color3.fromRGB(48, 64, 105), 22)
    krnlGlow.BackgroundTransparency = 0.72
    addGradient(krnlGlow, Color3.fromRGB(55, 72, 118), Color3.fromRGB(34, 46, 80), 135)
    krnlGlow.ZIndex = 0; windowRefs.krnlGlow = krnlGlow

    local shadow = newFrame(sg, metrics.normalSize, offsetPos(metrics.normalPos, 8, 10), C.shadow, 20)
    shadow.BackgroundTransparency = 0.62
    addGradient(shadow, Color3.fromRGB(4, 5, 10), Color3.fromRGB(8, 10, 18), 135)
    shadow.ZIndex = 0; windowRefs.shadow = shadow

    local panel = newFrame(sg, metrics.normalSize, metrics.normalPos, C.bg, 18)
    panel.BackgroundTransparency = 0.04
    addStroke(panel, Color3.fromRGB(55, 90, 160), 2, 0.42)
    addGradient(panel, Color3.fromRGB(34, 38, 54), Color3.fromRGB(18, 22, 32), 125)
    windowRefs.panel = panel

    local titleBar = newFrame(panel, UDim2.new(1, -16, 0, TITLE_H), UDim2.new(0, 8, 0, 8), C.bg2, 14)
    titleBar.BackgroundTransparency = 0.06
    addStroke(titleBar, C.border, 1, 0.30)
    addGradient(titleBar, Color3.fromRGB(38, 44, 62), Color3.fromRGB(28, 33, 47), 125)

    local logoWrap = newFrame(titleBar, UDim2.new(0, 34, 0, 34), UDim2.new(0, 12, 0.5, -17), C.accent, 12)
    logoWrap.BackgroundTransparency = 0.04; addStroke(logoWrap, C.border, 1, 0.35)
    local liSz = 16; local liX = math.floor((34-liSz)/2); local liY = math.floor((34-liSz)/2)
    makeNavIcon(logoWrap, "library", liSz, liX, liY, C.selectedText)

    newLabel(titleBar, "sMidiX", UDim2.new(0,210,0,22), UDim2.new(0,56,0, SS and 4 or 8), nil, C.text, SS and 13 or 17, Enum.TextXAlignment.Left).Font = Enum.Font.GothamBlack
    windowRefs.sectionLabel = newLabel(titleBar, T("section_library").."  •  "..T(IS_MOBILE and "touch_label" or "desktop_label"), UDim2.new(0,260,0,18), UDim2.new(0,56,0, SS and 18 or 28), nil, C.textSub, SS and 8 or 10, Enum.TextXAlignment.Left)

    local winGroup = newFrame(titleBar, UDim2.new(0,102,1,-10), UDim2.new(1,-108,0,5), C.bg3, 10)
    winGroup.BackgroundTransparency = 0.5; addStroke(winGroup, C.border, 1, 0.55)

    local function createWinBtn(xOff, bgColor, hoverCol, callback, iconName)
        local btn = Instance.new("TextButton")
        btn.Text=""; btn.AutoButtonColor=false; btn.BorderSizePixel=0
        btn.BackgroundColor3=bgColor; btn.BackgroundTransparency=0.08
        btn.Size=UDim2.new(0,28,1,-6); btn.Position=UDim2.new(0,xOff,0,3); btn.Parent=winGroup
        local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=btn
        makeWinIcon(btn, iconName, 12, UDim2.new(0.5,-6,0.5,-6), C.text)
        if not IS_MOBILE then
            btn.MouseEnter:Connect(function() tweenObject(btn, {BackgroundColor3=hoverCol}, 0.1) end)
            btn.MouseLeave:Connect(function() tweenObject(btn, {BackgroundColor3=bgColor}, 0.1) end)
        end
        btn.Activated:Connect(callback)
        return btn
    end
    createWinBtn(4,  C.stop, Color3.fromRGB(205,114,122), showClosedLauncher, "close")
    createWinBtn(36, C.bg3, C.hover, showCompactDock, "minimize")
    windowRefs.maxButton = createWinBtn(68, C.bg3, C.hover, toggleMaximize, "maximize")

    do
        local dragging = false; local dragStart = Vector2.new(0,0); local panelStart = Vector2.new(0,0)
        local function onDragBegin(pos)
            if windowRefs.maximized then return end
            dragging=true; dragStart=Vector2.new(pos.X,pos.Y)
            panelStart=Vector2.new(panel.Position.X.Offset, panel.Position.Y.Offset)
        end
        local function onDragMove(pos)
            if not dragging or windowRefs.maximized then return end
            local viewport=getViewportSize(); local dx=pos.X-dragStart.X; local dy=pos.Y-dragStart.Y
            local w=panel.Size.X.Offset; local h=panel.Size.Y.Offset
            local tx=math.clamp(panelStart.X+dx, 8-math.floor(w*0.2), math.max(8,viewport.X-80))
            local ty=math.clamp(panelStart.Y+dy, 8, math.max(8,viewport.Y-90))
            panel.Position=UDim2.new(0,tx,0,ty); shadow.Position=offsetPos(panel.Position,8,10)
            if windowRefs.krnlGlow then windowRefs.krnlGlow.Position=offsetPos(panel.Position,-14,-14) end
        end
        titleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then onDragBegin(inp.Position) end
        end)
        titleBar.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then onDragMove(inp.Position) end
        end)
    end

    local body = Instance.new("Frame")
    body.BackgroundTransparency=1; body.Size=UDim2.new(1,-16,1,-(BODY_Y+10))
    body.Position=UDim2.new(0,8,0,BODY_Y); body.Parent=panel

    local sidebar = newFrame(body, UDim2.new(0,NAV_W,1,0), UDim2.new(0,0,0,0), C.bg2, 16)
    sidebar.BackgroundTransparency=0.08; addStroke(sidebar,C.border,1,0.34)
    sidebar.ClipsDescendants=true
    addGradient(sidebar, Color3.fromRGB(58,65,81), Color3.fromRGB(48,54,67), 180)

    newLabel(sidebar,"Panel",UDim2.new(1,-20,0,18),UDim2.new(0, SS and 4 or 10,0, SS and 6 or 12),nil,C.textSub, SS and 8 or 10).Font=Enum.Font.GothamSemibold

    local navButtons = {
        {key="library",   icon="library",   text=T("nav_library")},
        {key="options",   icon="options",   text=T("nav_options")},
        {key="console",   icon="console",   text=T("nav_console")},
        {key="languages", icon="languages", text=T("nav_languages")},
    }
    local BTN_NAV_H = SS and 28 or (IS_MOBILE and 38 or 38)
    local BTN_NAV_ICO = SS and 10 or (IS_MOBILE and 14 or 14)
    for i, item in ipairs(navButtons) do
        local yPos = (SS and 24 or 34) + (i-1)*(BTN_NAV_H + (SS and 4 or 6))
        local button=newButton(sidebar,"",UDim2.new(1,-10,0,BTN_NAV_H),UDim2.new(0,5,0,yPos),C.bg2,C.hover,function() setSection(item.key); updateGUI() end, C.textSub)
        button.BackgroundTransparency=0.16; button.BorderSizePixel=0
        local icoXOff = SS and 4 or (IS_MOBILE and 8 or 10)
        local icoYOff=math.floor((BTN_NAV_H-BTN_NAV_ICO)/2)
        makeNavIcon(button,item.icon,BTN_NAV_ICO,icoXOff,icoYOff,C.textSub)
        local textLbl=newLabel(button,item.text,UDim2.new(1,-(icoXOff+BTN_NAV_ICO+6),1,0),UDim2.new(0,icoXOff+BTN_NAV_ICO+6,0,0),nil,C.textSub, SS and 8 or (IS_MOBILE and 10 or 11))
        textLbl.TextXAlignment=Enum.TextXAlignment.Left; textLbl.Font=Enum.Font.GothamMedium
        textLbl.TextTruncate=Enum.TextTruncate.AtEnd
        local pill=newFrame(button,UDim2.new(0,3,0, SS and 10 or 14),UDim2.new(0,IS_MOBILE and 2 or 3,0.5, SS and -5 or -7),C.accentBlue,99)
        pill.BackgroundTransparency=1
        sectionButtons[item.key]={button=button,pill=pill,label=textLbl}
    end

    local AVATAR_SZ = SS and 20 or (IS_MOBILE and 28 or 32)
    local avatarImg=Instance.new("ImageLabel")
    avatarImg.BackgroundColor3=C.bg4; avatarImg.BackgroundTransparency=0.3
    avatarImg.BorderSizePixel=0; avatarImg.Size=UDim2.new(0,AVATAR_SZ,0,AVATAR_SZ)
    avatarImg.Position=UDim2.new(0.5,-math.floor(AVATAR_SZ/2),1, SS and -34 or -50)
    avatarImg.Image=""; avatarImg.ScaleType=Enum.ScaleType.Crop; avatarImg.Parent=sidebar
    local avC=Instance.new("UICorner"); avC.CornerRadius=UDim.new(0.5,0); avC.Parent=avatarImg
    addStroke(avatarImg,C.border,1,0.4)
    local sidebarNameLabel=newLabel(sidebar,localPlayer.DisplayName or localPlayer.Name,UDim2.new(1,-4,0, SS and 10 or 14),UDim2.new(0,2,1, SS and -12 or -16),nil,C.textSub, SS and 7 or 9,Enum.TextXAlignment.Center)
    sidebarNameLabel.TextTruncate=Enum.TextTruncate.AtEnd
    task.spawn(function()
        local ok,url=pcall(function() return Players:GetUserThumbnailAsync(localPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48) end)
        if ok and url and avatarImg and avatarImg.Parent then avatarImg.Image=url end
    end)

    -- ── LIBRARY PANEL ──
    local libraryPane=newFrame(body,UDim2.new(0,LIB_W,1,0),UDim2.new(0,NAV_W+12,0,0),C.bg2,16)
    libraryPane.BackgroundTransparency=0.06; addStroke(libraryPane,C.border,1,0.32)
    addGradient(libraryPane,Color3.fromRGB(57,65,80),Color3.fromRGB(47,53,66),180)
    windowRefs.libraryPane=libraryPane

    local libraryTitle=newLabel(libraryPane,T("library_title"),UDim2.new(1,-60,0,22),UDim2.new(0, SS and 6 or 12,0, SS and 6 or 12),nil,C.text, SS and 11 or 15)
    libraryTitle.Font=Enum.Font.GothamBold
    windowRefs.libraryStats=newLabel(libraryPane,"0 "..T("songs_count"),UDim2.new(1,-60,0,18),UDim2.new(0, SS and 6 or 12,0, SS and 20 or 34),nil,C.textSub, SS and 8 or 10)

    -- ── ADD SONG "+" BUTTON ──
    local ADD_BTN_SZ = SS and 24 or 30
    local addSongBtn = Instance.new("TextButton")
    addSongBtn.Name = "AddSongBtn"
    addSongBtn.Size = UDim2.new(0, ADD_BTN_SZ, 0, ADD_BTN_SZ)
    addSongBtn.Position = UDim2.new(1, -(ADD_BTN_SZ + (SS and 6 or 10)), 0, SS and 6 or 10)
    addSongBtn.BackgroundColor3 = C.accent
    addSongBtn.BackgroundTransparency = 0.08
    addSongBtn.BorderSizePixel = 0
    addSongBtn.Text = "+"
    addSongBtn.TextColor3 = C.selectedText
    addSongBtn.TextSize = SS and 16 or 20
    addSongBtn.Font = Enum.Font.GothamBold
    addSongBtn.AutoButtonColor = false
    addSongBtn.Parent = libraryPane
    local addBtnCorner = Instance.new("UICorner"); addBtnCorner.CornerRadius = UDim.new(0, 8); addBtnCorner.Parent = addSongBtn
    addStroke(addSongBtn, C.accentBlue, 1, 0.3)

    if not IS_MOBILE then
        addSongBtn.MouseEnter:Connect(function() tweenObject(addSongBtn, {BackgroundColor3 = C.accentBlue}, 0.12) end)
        addSongBtn.MouseLeave:Connect(function() tweenObject(addSongBtn, {BackgroundColor3 = C.accent}, 0.12) end)
    end

    -- NoteSmith popup overlay
    local noteSmithOverlay = Instance.new("Frame")
    noteSmithOverlay.Name = "NoteSmithOverlay"
    noteSmithOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    noteSmithOverlay.BackgroundTransparency = 0.45
    noteSmithOverlay.BorderSizePixel = 0
    noteSmithOverlay.Size = UDim2.new(1, 0, 1, 0)
    noteSmithOverlay.Position = UDim2.new(0, 0, 0, 0)
    noteSmithOverlay.ZIndex = 50
    noteSmithOverlay.Visible = false
    noteSmithOverlay.Parent = panel

    local NS_W = SS and 240 or (IS_MOBILE and 300 or 360)
    local NS_H = SS and 180 or (IS_MOBILE and 220 or 240)
    local noteSmithPanel = newFrame(noteSmithOverlay, UDim2.new(0, NS_W, 0, NS_H), UDim2.new(0.5, -math.floor(NS_W/2), 0.5, -math.floor(NS_H/2)), C.bg, 18)
    noteSmithPanel.BackgroundTransparency = 0.02
    noteSmithPanel.ZIndex = 51
    noteSmithPanel.Active = true -- Block clicks from passing through to overlay
    addStroke(noteSmithPanel, C.accentBlue, 2, 0.2)
    addGradient(noteSmithPanel, Color3.fromRGB(34, 40, 58), Color3.fromRGB(22, 26, 38), 135)
    local nsScale = Instance.new("UIScale"); nsScale.Scale = 1; nsScale.Parent = noteSmithPanel

    -- Title
    local nsTitle = newLabel(noteSmithPanel, T("notesmith_title"), UDim2.new(1, -24, 0, 26), UDim2.new(0, 12, 0, SS and 12 or 16), nil, C.text, SS and 13 or 17)
    nsTitle.Font = Enum.Font.GothamBold; nsTitle.ZIndex = 52

    -- Description
    local nsDesc = newLabel(noteSmithPanel, T("notesmith_desc"), UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, SS and 40 or 50), nil, C.textSub, SS and 9 or 11)
    nsDesc.TextWrapped = true; nsDesc.TextYAlignment = Enum.TextYAlignment.Top; nsDesc.ZIndex = 52

    -- Link display
    local nsLink = newLabel(noteSmithPanel, "https://bit.ly/Notesmith-smidix", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, SS and 82 or 100), nil, C.accentBlue, SS and 9 or 11)
    nsLink.Font = Enum.Font.GothamMedium; nsLink.ZIndex = 52; nsLink.TextWrapped = true

    -- Open button
    local NS_BTN_W = SS and 120 or 160
    local NS_BTN_H = SS and 28 or 36
    local nsOpenBtn  -- declared first so the callback can reference it safely
    nsOpenBtn = newButton(noteSmithPanel, T("notesmith_open"), UDim2.new(0, NS_BTN_W, 0, NS_BTN_H), UDim2.new(0.5, -math.floor(NS_BTN_W/2), 1, -(NS_BTN_H + (SS and 36 or 48))), C.play, Color3.fromRGB(184, 211, 160), function()
        local NS_URL = "https://bit.ly/Notesmith-smidix"
        if setclipboard then setclipboard(NS_URL) end
        log("NoteSmith: " .. NS_URL)
        if nsOpenBtn then nsOpenBtn.Text = T("notesmith_copied") end
        task.delay(2, function()
            if nsOpenBtn and nsOpenBtn.Parent then
                nsOpenBtn.Text = T("notesmith_open")
            end
        end)
    end, C.selectedText)
    nsOpenBtn.ZIndex = 52; nsOpenBtn.Font = Enum.Font.GothamBold

    -- Close button
    local NS_CLOSE_W = SS and 70 or 90
    local NS_CLOSE_H = SS and 24 or 30

    -- Open/Close animation helpers
    local function openNoteSmith()
        noteSmithOverlay.Visible = true
        noteSmithOverlay.BackgroundTransparency = 1
        nsScale.Scale = 0.85
        noteSmithPanel.BackgroundTransparency = 0.5
        tweenObject(noteSmithOverlay, {BackgroundTransparency = 0.45}, 0.22)
        tweenObject(nsScale, {Scale = 1}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tweenObject(noteSmithPanel, {BackgroundTransparency = 0.02}, 0.18)
    end

    local function closeNoteSmith()
        tweenObject(noteSmithOverlay, {BackgroundTransparency = 1}, 0.18)
        tweenObject(nsScale, {Scale = 0.88}, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tweenObject(noteSmithPanel, {BackgroundTransparency = 0.6}, 0.14)
        task.delay(0.2, function()
            if noteSmithOverlay and noteSmithOverlay.Parent then
                noteSmithOverlay.Visible = false
            end
        end)
    end

    local nsCloseBtn = newButton(noteSmithPanel, T("notesmith_close"), UDim2.new(0, NS_CLOSE_W, 0, NS_CLOSE_H), UDim2.new(0.5, -math.floor(NS_CLOSE_W/2), 1, -(NS_CLOSE_H + (SS and 6 or 10))), C.bg3, C.hover, function()
        closeNoteSmith()
    end, C.textSub)
    nsCloseBtn.ZIndex = 52

    -- Block input on overlay background so touches don't pass through to elements below
    local nsOverlayBlock = Instance.new("TextButton")
    nsOverlayBlock.BackgroundTransparency = 1; nsOverlayBlock.Text = ""; nsOverlayBlock.Size = UDim2.new(1, 0, 1, 0)
    nsOverlayBlock.ZIndex = 50; nsOverlayBlock.Active = true; nsOverlayBlock.Parent = noteSmithOverlay

    -- "+" button opens the overlay
    addSongBtn.Activated:Connect(function()
        openNoteSmith()
    end)

    local songList=Instance.new("ScrollingFrame")
    songList.Name="SongList"; songList.BackgroundTransparency=1; songList.BorderSizePixel=0
    songList.ScrollBarThickness=5; songList.ScrollBarImageColor3=C.accentBlue
    songList.CanvasSize=UDim2.new(0,0,0,0)
    songList.Size=UDim2.new(1,-6,1, SS and -72 or -108); songList.Position=UDim2.new(0,3,0, SS and 38 or 60)
    songList.Parent=libraryPane; windowRefs.songListFrame=songList

    local songLayout=Instance.new("UIListLayout")
    songLayout.Padding=UDim.new(0,5); songLayout.Parent=songList
    songLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        songList.CanvasSize=UDim2.new(0,0,0,songLayout.AbsoluteContentSize.Y+8)
    end)

    rebuildLibrary(songList)

    local libraryHint=newLabel(libraryPane,T("hint_hint"),UDim2.new(1,-20,0,32),UDim2.new(0, SS and 6 or 12,1, SS and -30 or -42),nil,C.textSub, SS and 8 or 10,Enum.TextXAlignment.Left)
    libraryHint.TextYAlignment=Enum.TextYAlignment.Top

    -- ── MAIN CONTENT PANEL ──
    local contentX    = NAV_W + LIB_W + 24
    local contentXNav = NAV_W + 12
    local content=newFrame(body,UDim2.new(1,-contentX,1,0),UDim2.new(0,contentX,0,0),C.bg2,16)
    content.BackgroundTransparency=0.04; addStroke(content,C.border,1,0.24)
    addGradient(content,Color3.fromRGB(36,42,58),Color3.fromRGB(24,29,42),125)
    content.ClipsDescendants = true
    windowRefs.content=content; windowRefs.contentX_lib=contentX; windowRefs.contentX_nav=contentXNav

    local libContent=newFrame(content,UDim2.new(1,0,1,0),UDim2.new(),C.bg2,0)
    libContent.BackgroundTransparency=1; libContent.ClipsDescendants=true; windowRefs.libContent=libContent
    do local sc=Instance.new("UIScale"); sc.Scale=1; sc.Parent=libContent; windowRefs.libScale=sc end

    local FOLDER_ICO_SZ = IS_MOBILE and 68 or 78
    local noSelHint = Instance.new("Frame")
    noSelHint.BackgroundTransparency = 1; noSelHint.BorderSizePixel = 0
    noSelHint.Size = UDim2.new(1, -40, 0, FOLDER_ICO_SZ + 60)
    noSelHint.AnchorPoint = Vector2.new(0.5, 0.5)
    noSelHint.Position = UDim2.new(0.5, 0, 0.5, -10)
    noSelHint.Parent = libContent
    windowRefs.noSelHint = noSelHint

    -- Folder icon with question mark (large, Nordic colors)
    makeFolderQuestionIcon(noSelHint, FOLDER_ICO_SZ, C.textSub)

    -- Text below the icon
    local hintLabel = newLabel(
        noSelHint, T("hint_select"),
        UDim2.new(1, 0, 0, 46),
        UDim2.new(0, 0, 0, FOLDER_ICO_SZ + 10),
        nil, C.textSub, IS_MOBILE and 13 or 12
    )
    hintLabel.TextXAlignment = Enum.TextXAlignment.Center
    hintLabel.TextYAlignment = Enum.TextYAlignment.Top
    hintLabel.TextWrapped = true

    local SPD_BTN_H = SS and 22 or (IS_MOBILE and 34 or 28)
    local SPD_Y     = 10 + BTN_H + 8
    local PROG_H    = SS and 30 or (IS_MOBILE and 24 or 44)
    local CTRL_H    = SPD_Y + SPD_BTN_H + PROG_H + (SS and 6 or (IS_MOBILE and 10 or 18))
    local HERO_H    = SS and 60 or (IS_MOBILE and 92 or 106)
    local VIZ_H     = SS and 30 or (IS_MOBILE and 50 or 68)
    local CGAP      = SS and 4 or (IS_MOBILE and 6 or 8)
    local SEL_H     = 10 + HERO_H + CGAP + VIZ_H + CGAP + CTRL_H + 10

    local selContent=newFrame(libContent,UDim2.new(1,0,0,SEL_H),UDim2.new(),C.bg2,0)
    selContent.BackgroundTransparency=1; selContent.Visible=false; windowRefs.selContent=selContent

    -- Auto-fit: scale playback section to available height without overflow (small screens only)
    if SS then
        local selFitScale=Instance.new("UIScale"); selFitScale.Scale=1; selFitScale.Parent=selContent
        local function updatePlaybackFit()
            if not (libContent and libContent.Parent and selFitScale and selFitScale.Parent) then return end
            local availH=libContent.AbsoluteSize.Y
            if availH>0 and availH<SEL_H then
                local s=availH/SEL_H
                selFitScale.Scale=s
                selContent.Size=UDim2.new(1/s, 0, 0, SEL_H)
            else
                selFitScale.Scale=1
                selContent.Size=UDim2.new(1, 0, 0, SEL_H)
            end
        end
        libContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePlaybackFit)
        task.defer(updatePlaybackFit)
    end

    local heroCard=newFrame(selContent,UDim2.new(1,-20,0,HERO_H),UDim2.new(0,10,0,10),C.card,16)
    heroCard.BackgroundTransparency=0.05; addStroke(heroCard,C.border,1,0.28)
    addGradient(heroCard,Color3.fromRGB(40,46,64),Color3.fromRGB(28,33,48),135)

    local heroAccent=newFrame(heroCard,UDim2.new(0,6,1,-20),UDim2.new(0,12,0,10),C.accent,99)
    heroAccent.BackgroundTransparency=0

    -- Title and goal of the active song
    guiSongLabel=newLabel(heroCard,"...",UDim2.new(1, SS and -80 or -140,0,26),UDim2.new(0,28,0, SS and 6 or 12),nil,C.text, SS and 12 or (IS_MOBILE and 16 or 20))
    guiSongLabel.Font=Enum.Font.GothamBold; guiSongLabel.TextWrapped=false; guiSongLabel.TextTruncate=Enum.TextTruncate.AtEnd

    guiSongMetaLabel=newLabel(heroCard,"...",UDim2.new(1, SS and -80 or -140,0,18),UDim2.new(0,28,0, SS and 28 or 42),nil,C.textSub, SS and 8 or 10)
    guiSongMetaLabel.TextWrapped=false; guiSongMetaLabel.TextTruncate=Enum.TextTruncate.AtEnd

    -- Status badge
    local badgeW = SS and 80 or 118
    local badgeH = SS and 22 or 30
    windowRefs.statusBadge=newFrame(heroCard,UDim2.new(0,badgeW,0,badgeH),UDim2.new(1,-(badgeW+14),0, SS and 10 or 16),C.accent,99)
    addStroke(windowRefs.statusBadge,C.border,1,0.28)
    guiStatusLabel=newLabel(windowRefs.statusBadge,T("status_ready"),UDim2.new(1,0,1,0),UDim2.new(),nil,C.selectedText, SS and 9 or 11,Enum.TextXAlignment.Center)
    guiStatusLabel.Font=Enum.Font.GothamBold; guiStatusLabel.TextYAlignment=Enum.TextYAlignment.Center

    -- ── CAVA Visualizer ──
    local vizCard=newFrame(selContent,UDim2.new(1,-20,0,VIZ_H),UDim2.new(0,10,0,10+HERO_H+CGAP),Color3.fromRGB(7,16,34),12)
    vizCard.BackgroundTransparency=0.0
    local vizStroke=addStroke(vizCard,Color3.fromRGB(30,100,180),1,0.4)
    addGradient(vizCard,Color3.fromRGB(10,22,48),Color3.fromRGB(5,12,26),90)
    windowRefs.vizCard=vizCard; windowRefs.vizStroke=vizStroke

    local VIZ_BAR_COUNT=IS_MOBILE and 20 or 32; local VIZ_MAX_H=VIZ_H-12
    windowRefs.eqBars={}; windowRefs.eqFoam={}; windowRefs.eqBarMaxH=VIZ_MAX_H
    local OC_DEEP  = Color3.fromRGB(12, 50, 115)
    local OC_MID   = Color3.fromRGB(35, 120, 195)
    local OC_CREST = Color3.fromRGB(90, 200, 255)
    local OC_FOAM  = Color3.fromRGB(195, 238, 255)
    for bi=1,VIZ_BAR_COUNT do
        local barFrac=1/VIZ_BAR_COUNT
        -- Wave column
        local eb=Instance.new("Frame"); eb.AnchorPoint=Vector2.new(0,1)
        eb.BackgroundColor3=OC_MID; eb.BackgroundTransparency=0.08; eb.BorderSizePixel=0
        eb.Size=UDim2.new(barFrac,-2,0,5); eb.Position=UDim2.new((bi-1)*barFrac,1,1,-3); eb.Parent=vizCard
        local ec=Instance.new("UICorner"); ec.CornerRadius=UDim.new(0,2); ec.Parent=eb
        local grad=Instance.new("UIGradient")
        grad.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,OC_FOAM),
            ColorSequenceKeypoint.new(0.3,OC_CREST),
            ColorSequenceKeypoint.new(1,OC_DEEP)
        }); grad.Rotation=90; grad.Parent=eb
        table.insert(windowRefs.eqBars,eb)
        -- Foam cap at wave crest
        local fm=Instance.new("Frame"); fm.AnchorPoint=Vector2.new(0,1)
        fm.BackgroundColor3=OC_FOAM; fm.BackgroundTransparency=0.85; fm.BorderSizePixel=0
        fm.Size=UDim2.new(barFrac,-4,0,3); fm.Position=UDim2.new((bi-1)*barFrac,2,1,-3); fm.Parent=vizCard
        local fmc=Instance.new("UICorner"); fmc.CornerRadius=UDim.new(0.5,0); fmc.Parent=fm
        table.insert(windowRefs.eqFoam,fm)
    end
    -- Water surface baseline
    local wLine=Instance.new("Frame"); wLine.AnchorPoint=Vector2.new(0,1)
    wLine.BackgroundColor3=Color3.fromRGB(70,175,240); wLine.BackgroundTransparency=0.45; wLine.BorderSizePixel=0
    wLine.Size=UDim2.new(1,-14,0,1); wLine.Position=UDim2.new(0,7,1,-3); wLine.Parent=vizCard
    local wlg=Instance.new("UIGradient")
    wlg.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(20,90,170)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(110,210,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(20,90,170))
    }); wlg.Parent=wLine; windowRefs.waterLine=wLine

    -- ── Control Panel ──
    local controlCard=newFrame(selContent,UDim2.new(1,-20,0,CTRL_H),UDim2.new(0,10,0,10+HERO_H+CGAP+VIZ_H+CGAP),C.card,16)
    controlCard.BackgroundTransparency=0.06; addStroke(controlCard,C.border,1,0.3)

    btnPrev=newButton(controlCard,"◀",UDim2.new(0,36,0,BTN_H),UDim2.new(0,12,0,12),C.bg3,C.hover,function()
        if isRunning then stopPlayback() end
        currentSongIndex=math.max(1,currentSongIndex-1); updateGUI()
    end,C.text)

    btnPlay=newButton(controlCard,"▶  "..T("play"),UDim2.new(0.46,-54,0,BTN_H),UDim2.new(0,54,0,12),C.play,Color3.fromRGB(184,211,160),function()
        if not isRunning then startPlayback() else pausePlayback() end
    end,C.selectedText)
    do
        local bpSc=Instance.new("UIScale"); bpSc.Parent=btnPlay
        btnPlay.Activated:Connect(function() bpSc.Scale=0.91; tweenObject(bpSc,{Scale=1.0},0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out) end)
    end

    btnStop=newButton(controlCard,"■  "..T("stop"),UDim2.new(0.28,-8,0,BTN_H),UDim2.new(0.46,8,0,12),C.stop,Color3.fromRGB(205,114,122),stopPlayback,C.text)
    do
        local bsSc=Instance.new("UIScale"); bsSc.Parent=btnStop
        btnStop.Activated:Connect(function() bsSc.Scale=0.91; tweenObject(bsSc,{Scale=1.0},0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out) end)
    end

    btnNext=newButton(controlCard,"▶",UDim2.new(0,36,0,BTN_H),UDim2.new(1,-48,0,12),C.bg3,C.hover,function()
        if isRunning then stopPlayback() end
        currentSongIndex=math.min(#SongData.songs,currentSongIndex+1); updateGUI()
    end,C.text)

    local spdSep=newFrame(controlCard,UDim2.new(1,-24,0,1),UDim2.new(0,12,0,SPD_Y-6),C.border,0)
    spdSep.BackgroundTransparency=0.55

    btnSpdDn=newButton(controlCard,"−  10%",UDim2.new(0,76,0,SPD_BTN_H),UDim2.new(0,12,0,SPD_Y),C.bg3,C.hover,function() changeSpeed(-Config.decreaseSize) end,C.text)

    guiSpeedLabel=newLabel(controlCard,T("speed").."  100%",UDim2.new(1,-180,0,SPD_BTN_H),UDim2.new(0,92,0,SPD_Y),nil,C.textSub, SS and 8 or (IS_MOBILE and 11 or 10))
    guiSpeedLabel.TextXAlignment=Enum.TextXAlignment.Center; guiSpeedLabel.TextYAlignment=Enum.TextYAlignment.Center; guiSpeedLabel.TextWrapped=false

    btnSpdUp=newButton(controlCard,"+  10%",UDim2.new(0,76,0,SPD_BTN_H),UDim2.new(1,-88,0,SPD_Y),C.bg3,C.hover,function() changeSpeed(Config.decreaseSize) end,C.text)

    -- ── PROGRESS BAR WITH SEEK (click/drag to search position) ──
    local PROG_BAR_Y = SPD_Y + SPD_BTN_H + 8
    local PROG_BAR_H = IS_MOBILE and 12 or 8
    local progTrack=newFrame(controlCard,UDim2.new(1,-24,0,PROG_BAR_H),UDim2.new(0,12,0,PROG_BAR_Y),C.bg3,4)
    progTrack.BackgroundTransparency=0.18

    guiProgressFill=newFrame(progTrack,UDim2.new(0,0,1,0),UDim2.new(),C.accentBlue,4)
    guiProgressFill.BackgroundTransparency=0.1; addStroke(guiProgressFill,C.accentBlue,1,0.5)

    -- Position indicator dot
    local scrubDot=Instance.new("Frame")
    scrubDot.BackgroundColor3=C.text; scrubDot.BackgroundTransparency=0.08; scrubDot.BorderSizePixel=0
    scrubDot.Size=UDim2.new(0,IS_MOBILE and 14 or 10,0,IS_MOBILE and 14 or 10)
    scrubDot.AnchorPoint=Vector2.new(0.5,0.5); scrubDot.Position=UDim2.new(0,0,0.5,0); scrubDot.ZIndex=6; scrubDot.Parent=progTrack
    local scrubDotC=Instance.new("UICorner"); scrubDotC.CornerRadius=UDim.new(0.5,0); scrubDotC.Parent=scrubDot

    -- Transparent click/drag zone over the bar
    local progScrub=Instance.new("TextButton")
    progScrub.BackgroundTransparency=1; progScrub.BorderSizePixel=0; progScrub.Text=""
    progScrub.AutoButtonColor=false; progScrub.Size=UDim2.new(1,0,1,0); progScrub.ZIndex=7; progScrub.Parent=progTrack

    local isScrubbing = false
    local scrubRatio  = 0

    local function computeRatio(inputPos)
        local absPos  = progTrack.AbsolutePosition
        local absSize = progTrack.AbsoluteSize
        if absSize.X <= 0 then return scrubRatio end
        return math.clamp((inputPos.X - absPos.X) / absSize.X, 0, 1)
    end

    local function applyVisualRatio(r)
        if guiProgressFill then guiProgressFill.Size = UDim2.new(r,0,1,0) end
        if scrubDot then scrubDot.Position = UDim2.new(r,0,0.5,0) end
    end

    progScrub.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            isScrubbing = true
            scrubRatio  = computeRatio(inp.Position)
            applyVisualRatio(scrubRatio)
        end
    end)

    progScrub.InputEnded:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) and isScrubbing then
            isScrubbing = false
            scrubRatio  = computeRatio(inp.Position)
            applyVisualRatio(scrubRatio)
            if SongData.songs[currentSongIndex] then
                local r = scrubRatio
                task.spawn(function() seekPlayback(r) end)
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if isScrubbing then
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                scrubRatio = computeRatio(inp.Position)
                applyVisualRatio(scrubRatio)
            end
        end
    end)

    -- Synchronize the dot with the progress bar during playback
    task.spawn(function()
        while true do
            task.wait(0.05)
            if not isScrubbing and guiProgressFill and scrubDot then
                scrubDot.Position = UDim2.new(guiProgressFill.Size.X.Scale, 0, 0.5, 0)
            end
        end
    end)

    guiProgressTimeLabel=newLabel(controlCard,"0:00",UDim2.new(1,-24,0,12),UDim2.new(0,12,0,PROG_BAR_Y+(IS_MOBILE and 14 or 10)),nil,C.textSub,9)
    guiProgressTimeLabel.Font=Enum.Font.Gotham; guiProgressTimeLabel.TextXAlignment=Enum.TextXAlignment.Right

    if not IS_MOBILE and not SS then
        local dockHint=newLabel(controlCard,"F1 Play/Pause  •  F2 Pause  •  F3 Stop  •  F4 +Vel  •  F5 -Vel",UDim2.new(1,-24,0,14),UDim2.new(0,12,0,PROG_BAR_Y+22),nil,C.textSub,9)
        dockHint.TextTruncate=Enum.TextTruncate.AtEnd
    end

    -- ── OPTIONS PANEL ──
    local optContent=newFrame(content,UDim2.new(1,0,1,0),UDim2.new(),C.card,16)
    optContent.BackgroundTransparency=0.06; addStroke(optContent,C.border,1,0.32)
    optContent.Visible=false; windowRefs.optContent=optContent
    do local sc=Instance.new("UIScale"); sc.Scale=1; sc.Parent=optContent; windowRefs.optScale=sc end

    local optionsList=Instance.new("ScrollingFrame")
    optionsList.BackgroundTransparency=1; optionsList.BorderSizePixel=0
    optionsList.ScrollBarThickness=5; optionsList.ScrollBarImageColor3=C.accentBlue
    optionsList.CanvasSize=UDim2.new(0,0,0,0)
    optionsList.Size=UDim2.new(1,-20,1,-16); optionsList.Position=UDim2.new(0,10,0,8); optionsList.Parent=optContent

    local optionsLayout=Instance.new("UIListLayout")
    optionsLayout.Padding=UDim.new(0,8); optionsLayout.Parent=optionsList
    optionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        optionsList.CanvasSize=UDim2.new(0,0,0,optionsLayout.AbsoluteContentSize.Y+8)
    end)

    createSettingRow(optionsList,T("no_doubles"),   T("d_no_doubles"),   function() return Config.noDoubles end,               function(v) Config.noDoubles=v end)
    createSettingRow(optionsList,T("use88"),        T("d_use88"),        function() return Config.use88Keys end,               function(v) Config.use88Keys=v end)
    createSettingRow(optionsList,T("loop"),         T("d_loop"),         function() return Config.loopSong end,                function(v) Config.loopSong=v end)
    createSettingRow(optionsList,T("sustain"),      T("d_sustain"),      function() return Config.sustain end,                 function(v) Config.sustain=v end)
    createSettingRow(optionsList,T("velocity"),     T("d_velocity"),     function() return Config.velocity end,                function(v) Config.velocity=v end)
    createSettingRow(optionsList,T("rand_fail"),    T("d_rand_fail"),    function() return Config.randomFail.enabled end,      function(v) Config.randomFail.enabled=v end)
    createSettingRow(optionsList,T("custom_hold"),  T("d_custom_hold"),  function() return Config.customHoldLength.enabled end, function(v) Config.customHoldLength.enabled=v end)
    createSettingRow(optionsList,T("release_pause"),T("d_release_pause"),function() return Config.releaseOnPause end,          function(v) Config.releaseOnPause=v end)

    task.defer(function() optionsList.CanvasSize=UDim2.new(0,0,0,optionsLayout.AbsoluteContentSize.Y+8) end)

    -- ── CONSOLE PANEL ──
    local consContent=newFrame(content,UDim2.new(1,0,1,0),UDim2.new(),C.console,16)
    consContent.BackgroundTransparency=0.02; addStroke(consContent,C.border,1,0.28)
    consContent.Visible=false; windowRefs.consContent=consContent
    do local sc=Instance.new("UIScale"); sc.Scale=1; sc.Parent=consContent; windowRefs.consScale=sc end

    local consoleTitle=newLabel(consContent,T("console_title"),UDim2.new(1,-24,0,22),UDim2.new(0,12,0,12),nil,C.text, SS and 11 or 15)
    consoleTitle.Font=Enum.Font.GothamBold
    guiLogLabel=newLabel(consContent,T("console_ready").."\n"..string.format(T("console_ready_fmt"),#SongData.songs-externalSongs,externalSongs),UDim2.new(1,-24,1,-54),UDim2.new(0,12,0,40),nil,C.textSub, SS and 9 or 11,Enum.TextXAlignment.Left)
    guiLogLabel.Font=Enum.Font.Code; guiLogLabel.TextYAlignment=Enum.TextYAlignment.Bottom

    -- ── LANGUAGES PANEL ──
    local langContent=newFrame(content,UDim2.new(1,0,1,0),UDim2.new(),C.bg2,16)
    langContent.BackgroundTransparency=0.04; addStroke(langContent,C.border,1,0.32)
    langContent.Visible=false; windowRefs.langContent=langContent
    do local sc=Instance.new("UIScale"); sc.Scale=1; sc.Parent=langContent; windowRefs.langScale=sc end

    local langTitleLabel=newLabel(langContent,T("lang_title"),UDim2.new(1,-24,0,24),UDim2.new(0,14,0,14),nil,C.text, SS and 12 or 16)
    langTitleLabel.Font=Enum.Font.GothamBold
    newLabel(langContent,T("lang_subtitle"),UDim2.new(1,-24,0,18),UDim2.new(0,14,0, SS and 34 or 40),nil,C.textSub, SS and 9 or 11)

    local langScroll=Instance.new("ScrollingFrame")
    langScroll.BackgroundTransparency=1; langScroll.BorderSizePixel=0
    langScroll.ScrollBarThickness=5; langScroll.ScrollBarImageColor3=C.accentBlue
    langScroll.CanvasSize=UDim2.new(0,0,0,0)
    langScroll.Size=UDim2.new(1,-20,1,-72); langScroll.Position=UDim2.new(0,10,0,64); langScroll.Parent=langContent

    local langGrid=Instance.new("UIGridLayout")
    langGrid.CellSize=UDim2.new(0, SS and 100 or (IS_MOBILE and 140 or 160), 0, SS and 38 or (IS_MOBILE and 52 or 48))
    langGrid.CellPadding=UDim2.new(0, SS and 4 or 8, 0, SS and 4 or 8); langGrid.HorizontalAlignment=Enum.HorizontalAlignment.Left; langGrid.Parent=langScroll

    local langOrder={"en","es","pt","fr","de","it","ja","ko","zh","ru","ar","pl","tr","nl","id","sv","da","vi","cs","hi","el","uk","hu"}
    for _,code in ipairs(langOrder) do
        local data=LANGS[code]
        if data then
            local isActive=(code==currentLang)
            local lbtn=Instance.new("TextButton"); lbtn.Size=UDim2.new(0,0,0,0); lbtn.Text=""; lbtn.AutoButtonColor=false; lbtn.BorderSizePixel=0
            lbtn.BackgroundColor3=isActive and C.accent or C.card; lbtn.BackgroundTransparency=isActive and 0.05 or 0.1; lbtn.Parent=langScroll
            local lc=Instance.new("UICorner"); lc.CornerRadius=UDim.new(0,10); lc.Parent=lbtn
            addStroke(lbtn,isActive and C.accentBlue or C.border,1,isActive and 0.25 or 0.55)
            local nameLabel=newLabel(lbtn,data._name,UDim2.new(1,-12,0,22),UDim2.new(0, SS and 6 or 10,0, SS and 4 or 6),nil,isActive and C.selectedText or C.text, SS and 10 or (IS_MOBILE and 13 or 13))
            nameLabel.Font=Enum.Font.GothamSemibold; nameLabel.TextTruncate=Enum.TextTruncate.AtEnd
            newLabel(lbtn,code,UDim2.new(1,-12,0,14),UDim2.new(0, SS and 6 or 10,0, SS and 20 or 26),nil,isActive and C.selectedText or C.textSub, SS and 8 or 10)
            lbtn.Activated:Connect(function() currentLang=code; buildGUI(); setSection("languages") end)
        end
    end
    task.defer(function() langScroll.CanvasSize=UDim2.new(0,0,0,langGrid.AbsoluteContentSize.Y+12) end)
    langGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() langScroll.CanvasSize=UDim2.new(0,0,0,langGrid.AbsoluteContentSize.Y+12) end)

    -- ── COMPACT DOCK ──
    local dock=newFrame(sg,metrics.dockSize,metrics.dockPos,C.bg2,18)
    dock.Visible=false; dock.BackgroundTransparency=0.08; addStroke(dock,C.border,1,0.28)
    addGradient(dock,Color3.fromRGB(61,69,85),Color3.fromRGB(47,54,68),90); windowRefs.dock=dock

    guiDockSongLabel=newLabel(dock,T("no_songs"),UDim2.new(1,-154,0,22),UDim2.new(0,14,0,8),nil,C.text,14)
    guiDockSongLabel.Font=Enum.Font.GothamBold
    guiDockStateLabel=newLabel(dock,T("status_ready"),UDim2.new(1,-154,0,18),UDim2.new(0,14,0,30),nil,C.textSub,10)

    dockPlayButton=newButton(dock,"▶",UDim2.new(0,38,0,38),UDim2.new(1,-120,0.5,-19),C.play,Color3.fromRGB(184,211,160),function()
        if not isRunning then startPlayback() else pausePlayback() end
    end,C.selectedText)
    dockPlayButton.TextSize=18

    newButton(dock,T("btn_open"),UDim2.new(0,62,0,32),UDim2.new(1,-74,0.5,-16),C.bg3,C.hover,showFullWindow,C.text)

    local launcher=newButton(sg,"sMidiX",UDim2.new(0,108,0,40),metrics.launcherPos,C.bg2,C.hover,showFullWindow,C.text)
    launcher.Visible=false; launcher.BackgroundTransparency=0.08; windowRefs.launcher=launcher

    setSection("library"); updateGUI(); showFullWindow()
    setupGlobalInteractionFX(sg, titleBar)

    -- ═══════════════════════════════════════════════════════════════════════
    -- SEA/OCEAN EFFECTS
    -- ═══════════════════════════════════════════════════════════════════════

    -- Semi-transparent overlay that tints the entire panel with sea colors
    local oceanOverlay = Instance.new("Frame")
    oceanOverlay.BackgroundColor3 = Color3.fromRGB(20, 80, 160)
    oceanOverlay.BackgroundTransparency = 0.94
    oceanOverlay.BorderSizePixel = 0
    oceanOverlay.Size  = UDim2.new(1, 0, 1, 0)
    oceanOverlay.Position = UDim2.new(0, 0, 0, 0)
    oceanOverlay.ZIndex = 1
    oceanOverlay.Parent = panel
    windowRefs.oceanOverlay = oceanOverlay

    -- Ocean color palette — cycles slowly (2-3 s per phase)
    local OCEAN_PAL = {
        { ov = Color3.fromRGB(15,  60, 145), sh = Color3.fromRGB( 4,  6, 14),  vz = Color3.fromRGB(20,  82, 168), gl = Color3.fromRGB(42, 58, 100) },
        { ov = Color3.fromRGB( 8,  48, 128), sh = Color3.fromRGB( 3,  5, 12),  vz = Color3.fromRGB(12,  65, 148), gl = Color3.fromRGB(36, 50,  90) },
        { ov = Color3.fromRGB(18,  85, 158), sh = Color3.fromRGB( 5, 10, 22),  vz = Color3.fromRGB(26, 105, 178), gl = Color3.fromRGB(50, 68, 112) },
        { ov = Color3.fromRGB(12,  55, 138), sh = Color3.fromRGB( 4,  7, 16),  vz = Color3.fromRGB(16,  72, 155), gl = Color3.fromRGB(44, 60, 105) },
        { ov = Color3.fromRGB(24,  98, 168), sh = Color3.fromRGB( 6, 12, 26),  vz = Color3.fromRGB(32, 118, 188), gl = Color3.fromRGB(55, 72, 118) },
    }
    local opi = 1
    task.spawn(function()
        while oceanOverlay and oceanOverlay.Parent do
            task.wait(2.6)
            opi = (opi % #OCEAN_PAL) + 1
            local p = OCEAN_PAL[opi]
            -- Intensity: slightly brighter when 
            local alpha = (isRunning and not paused) and 0.90 or 0.95
            tweenObject(oceanOverlay, {BackgroundColor3 = p.ov, BackgroundTransparency = alpha}, 2.0)
            -- Exterior shade with a sea tint
            if shadow and shadow.Parent then
                tweenObject(shadow, {BackgroundColor3 = p.sh}, 2.5)
            end
            -- The edge of the display pulsates gently
            if windowRefs.vizStroke and windowRefs.vizStroke.Parent then
                tweenObject(windowRefs.vizStroke, {Color = p.vz}, 2.0)
            end
            -- Nordic blue halo exterior gently presses
            if windowRefs.krnlGlow and windowRefs.krnlGlow.Parent then
                tweenObject(windowRefs.krnlGlow, {BackgroundColor3 = p.gl}, 2.5)
            end
        end
    end)

    -- Diagonal shimmer — a tilted glass reflection that sweeps across the panel
    panel.ClipsDescendants = true
    local shimmer = Instance.new("Frame")
    shimmer.BackgroundColor3 = Color3.fromRGB(62, 72, 100)
    shimmer.BackgroundTransparency = 0
    shimmer.BorderSizePixel = 0
    shimmer.AnchorPoint = Vector2.new(0.5, 0.5)
    shimmer.Size     = UDim2.new(0, 130, 1, 0)
    shimmer.Position = UDim2.new(-0.12, 0, 0.5, 0)
    shimmer.Rotation = 0
    shimmer.ZIndex   = 10
    shimmer.Parent   = panel
    local shimGrad = Instance.new("UIGradient")
    -- Rotation=14: the gradient within the frame is DIAGONAL (tilted ~14°).
    shimGrad.Rotation = 14
    shimGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(24, 28, 38)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(84, 96, 130)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(24, 28, 38)),
    })
    shimGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,    1),
        NumberSequenceKeypoint.new(0.35, 0.88),
        NumberSequenceKeypoint.new(0.5,  0.82),
        NumberSequenceKeypoint.new(0.65, 0.88),
        NumberSequenceKeypoint.new(1,    1),
    })
    shimGrad.Parent = shimmer
    task.spawn(function()
        while shimmer and shimmer.Parent do
            shimmer.Position = UDim2.new(-0.12, 0, 0.5, 0)
            tweenObject(shimmer, {Position = UDim2.new(1.12, 0, 0.5, 0)}, 3.8,
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(3.8 + 3.8 + math.random() * 2.0)
        end
    end)

    -- Idle wave — smooth ocean animation when NO song is playing
    task.spawn(function()
        while panel and panel.Parent do
            task.wait(0.05)
            if not isRunning and windowRefs.eqBars then
                local bars    = windowRefs.eqBars
                local foams   = windowRefs.eqFoam
                local numBars = #bars
                local t       = os.clock()
                local spikeK = 0
                if windowRefs.interactionSpikeEnd and t < windowRefs.interactionSpikeEnd then
                    spikeK = math.clamp((windowRefs.interactionSpikeEnd - t) / 0.28, 0, 1)
                end
                -- Pre-compute loop invariants
                local barFrac  = 1 / numBars
                local denom    = math.max(numBars - 1, 1)
                local baseH    = 13 + 10 * spikeK
                local foamBase = 0.5 + 0.35 * spikeK
                for bi = 1, numBars do
                    local pos   = (bi - 1) / denom
                    local swell = math.sin(t * 0.65 - pos * math.pi * 2.0) * 0.5 + 0.5
                    local chop  = math.sin(t * 1.45 - pos * math.pi * 4.2) * 0.14 + 0.14
                    local wave  = swell * 0.76 + chop * 0.24
                    local h     = math.max(3, baseH * wave)
                    bars[bi].Size = UDim2.new(barFrac, -2, 0, h)
                    if foams and foams[bi] then
                        foams[bi].Position = UDim2.new((bi-1)*barFrac, 1, 1, -3 - h)
                        foams[bi].BackgroundTransparency = math.max(0.25, 0.95 - wave * foamBase)
                    end
                end
            end
        end
    end)
end
