-- ═══════════════════════════════════════════════════════════════════════════
-- GUI (Theme Nordic)
-- ═══════════════════════════════════════════════════════════════════════════
local C = {
    bg           = Color3.fromRGB(24,  28,  38),
    bg2          = Color3.fromRGB(30,  35,  48),
    bg3          = Color3.fromRGB(36,  42,  57),
    bg4          = Color3.fromRGB(44,  51,  68),
    card         = Color3.fromRGB(32,  37,  52),
    hover        = Color3.fromRGB(48,  56,  74),
    text         = Color3.fromRGB(218, 224, 236),
    textSub      = Color3.fromRGB(145, 156, 176),
    selectedText = Color3.fromRGB(24,  28,  38),
    play         = Color3.fromRGB(163, 190, 140),
    pause        = Color3.fromRGB(235, 203, 139),
    stop         = Color3.fromRGB(191,  97, 106),
    accent       = Color3.fromRGB(130, 182, 182),
    accentBlue   = Color3.fromRGB(110, 148, 210),
    border       = Color3.fromRGB(52,  60,  80),
    console      = Color3.fromRGB(16,  20,  30),
    shadow       = Color3.fromRGB( 4,   5,  10),
    favActive    = Color3.fromRGB(235, 203, 139),
}

local BTN_H = IS_MOBILE and 42 or 36
local FSIZE = IS_MOBILE and 15 or 13

-- ════════════════════════════════════
-- ICON SYSTEM 
-- ═══════════════════════════════════════════════════════════════════════════
local function icoBar(parent, color, x, y, w, h, radius)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = color; f.BorderSizePixel = 0
    f.Size = UDim2.new(0, w, 0, h)
    f.Position = UDim2.new(0, x, 0, y)
    f.Parent = parent
    if radius and radius > 0 then
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius); c.Parent = f
    end
    return f
end

local function makeNavIcon(parent, name, sz, xOff, yOff, col)
    local ico = Instance.new("Frame")
    ico.BackgroundTransparency = 1
    ico.Size = UDim2.new(0, sz, 0, sz)
    ico.Position = UDim2.new(0, xOff, 0, yOff)
    ico.Parent = parent
    col = col or C.textSub
    local s = sz
    if name == "library" then
        icoBar(ico, col, s-4, 0, 3, s-3, 1)
        icoBar(ico, col, 1, s-5, s-3, 5, 3)
        icoBar(ico, col, s-4, 0, s-2, 3, 1)
    elseif name == "options" then
        icoBar(ico, col, 0, 1, s, 2, 1)
        icoBar(ico, col, 0, 6, s, 2, 1)
        icoBar(ico, col, 0, 11, s, 2, 1)
        icoBar(ico, col, math.floor(s*0.15), -1, 4, 6, 3)
        icoBar(ico, col, math.floor(s*0.55), 4, 4, 6, 3)
        icoBar(ico, col, math.floor(s*0.25), 9, 4, 6, 3)
    elseif name == "console" then
        icoBar(ico, col, 1, 3, 2, s-6, 0)
        icoBar(ico, col, 1, 3, 6, 2, 0)
        icoBar(ico, col, 1, s-5, 6, 2, 0)
        icoBar(ico, col, math.floor(s*0.5)+1, math.floor(s*0.5), math.floor(s*0.46), 2, 1)
    elseif name == "languages" then
        icoBar(ico, col, math.floor(s/2)-1, 0, 2, s, 1)
        icoBar(ico, col, 0, math.floor(s/2)-1, s, 2, 1)
        icoBar(ico, col, 2, 2, s-4, 2, 1)
        icoBar(ico, col, 2, s-4, s-4, 2, 1)
        local ring = Instance.new("Frame"); ring.BackgroundTransparency=1; ring.BorderSizePixel=0
        ring.Size=UDim2.new(0,s,0,s); ring.Position=UDim2.new(0,0,0,0); ring.Parent=ico
        local stroke=Instance.new("UIStroke"); stroke.Color=col; stroke.Thickness=2; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Parent=ring
        local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0.5,0); corner.Parent=ring
    end
    return ico
end

local function makeWinIcon(parent, name, sz, pos, col)
    local ico = Instance.new("Frame")
    ico.BackgroundTransparency = 1
    ico.Size = UDim2.new(0, sz, 0, sz)
    ico.Position = pos
    ico.Parent = parent
    col = col or C.text
    local s = sz
    if name == "close" then
        local function diagBar(angle)
            local b = Instance.new("Frame"); b.BackgroundColor3=col; b.BorderSizePixel=0
            b.AnchorPoint=Vector2.new(0.5,0.5); b.Size=UDim2.new(0,2,0,s-2)
            b.Position=UDim2.new(0.5,0,0.5,0); b.Rotation=angle
            local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,1); c.Parent=b
            b.Parent=ico
        end
        diagBar(45); diagBar(-45)
    elseif name == "minimize" then
        icoBar(ico, col, 2, math.floor(s/2)-1, s-4, 2, 1)
    elseif name == "maximize" then
        icoBar(ico, col, 1, 1, s-2, 2, 0)
        icoBar(ico, col, 1, s-3, s-2, 2, 0)
        icoBar(ico, col, 1, 1, 2, s-2, 0)
        icoBar(ico, col, s-3, 1, 2, s-2, 0)
    elseif name == "maximize_restore" then
        icoBar(ico, col, 3, 1, s-4, 2, 0)
        icoBar(ico, col, 3, s-3, s-4, 2, 0)
        icoBar(ico, col, 3, 1, 2, s-4, 0)
        icoBar(ico, col, s-3, 1, 2, s-4, 0)
        icoBar(ico, col, 1, 3, s-4, 2, 0)
        icoBar(ico, col, 1, 3, 2, s-4, 0)
    end
    return ico
end

-- ═══════════════════════════════════════════════════════════════════════════
-- makeFolderQuestionIcon
-- ═══════════════════════════════════════════════════════════════════════════
local function makeFolderQuestionIcon(parent, sz, col)
    col = col or C.textSub
    local ico = Instance.new("Frame")
    ico.BackgroundTransparency = 1
    ico.BorderSizePixel = 0
    ico.Size = UDim2.new(0, sz, 0, sz)
    ico.AnchorPoint = Vector2.new(0.5, 0)
    ico.Position = UDim2.new(0.5, 0, 0, 0)
    ico.Parent = parent

    local tabW = math.floor(sz * 0.46)
    local tabH = math.floor(sz * 0.14)
    local tabY = math.floor(sz * 0.16)
    local tab = Instance.new("Frame")
    tab.BackgroundColor3 = col
    tab.BackgroundTransparency = 0.55
    tab.BorderSizePixel = 0
    tab.Size = UDim2.new(0, tabW, 0, tabH)
    tab.Position = UDim2.new(0, 0, 0, tabY)
    tab.Parent = ico
    local tabC = Instance.new("UICorner"); tabC.CornerRadius = UDim.new(0, math.max(3, math.floor(sz*0.06))); tabC.Parent = tab

    local bodyH = math.floor(sz * 0.60)
    local bodyY = math.floor(sz * 0.28)
    local body = Instance.new("Frame")
    body.BackgroundColor3 = col
    body.BackgroundTransparency = 0.58
    body.BorderSizePixel = 0
    body.Size = UDim2.new(0, sz, 0, bodyH)
    body.Position = UDim2.new(0, 0, 0, bodyY)
    body.Parent = ico
    local bodyC = Instance.new("UICorner"); bodyC.CornerRadius = UDim.new(0, math.max(4, math.floor(sz*0.07))); bodyC.Parent = body
    local bodyStroke = Instance.new("UIStroke")
    bodyStroke.Color = col
    bodyStroke.Thickness = math.max(2, math.floor(sz * 0.04))
    bodyStroke.Transparency = 0.22
    bodyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    bodyStroke.Parent = body

    local qLabel = Instance.new("TextLabel")
    qLabel.BackgroundTransparency = 1
    qLabel.BorderSizePixel = 0
    qLabel.Size = UDim2.new(1, 0, 0, bodyH)
    qLabel.Position = UDim2.new(0, 0, 0, bodyY)
    qLabel.Text = "?"
    qLabel.TextColor3 = col
    qLabel.TextTransparency = 0.04
    qLabel.Font = Enum.Font.GothamBlack
    qLabel.TextSize = math.floor(bodyH * 0.74)
    qLabel.TextXAlignment = Enum.TextXAlignment.Center
    qLabel.TextYAlignment = Enum.TextYAlignment.Center
    qLabel.Parent = ico

    return ico
end

-- ═══════════════════════════════════════════════════════════════════════════
-- makeFavIcon
-- ═══════════════════════════════════════════════════════════════════════════
local function makeFavIcon(parent, sz, xOff, yOff, col, filled)
    local ico = Instance.new("Frame")
    ico.Name = "FavIcon"; ico.BackgroundTransparency = 1; ico.BorderSizePixel = 0
    ico.Size = UDim2.new(0, sz, 0, sz)
    ico.Position = UDim2.new(0, xOff, 0, yOff)
    ico.Parent = parent

    local alpha = filled and 0.0 or 0.22

    local D   = math.ceil(sz / 2) + (sz >= 12 and 1 or 0)
    local bSz = math.floor(sz * 0.62)
    local cY  = math.floor(sz * 0.97 - bSz * 0.707)

    local body = Instance.new("Frame")
    body.AnchorPoint = Vector2.new(0.5, 0.5); body.BorderSizePixel = 0
    body.Size        = UDim2.new(0, bSz, 0, bSz)
    body.Position    = UDim2.new(0.5, 0, 0, cY)
    body.Rotation    = 45
    body.BackgroundColor3        = col
    body.BackgroundTransparency  = alpha
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, math.max(1, math.floor(bSz * 0.15)))
    bc.Parent = body; body.Parent = ico

    local lh = Instance.new("Frame")
    lh.Size = UDim2.new(0, D, 0, D); lh.Position = UDim2.new(0, 0, 0, 0)
    lh.BorderSizePixel = 0; lh.BackgroundColor3 = col; lh.BackgroundTransparency = alpha
    local lhc = Instance.new("UICorner"); lhc.CornerRadius = UDim.new(0.5, 0); lhc.Parent = lh
    lh.Parent = ico

    local rh = Instance.new("Frame")
    rh.Size = UDim2.new(0, D, 0, D); rh.Position = UDim2.new(1, -D, 0, 0)
    rh.BorderSizePixel = 0; rh.BackgroundColor3 = col; rh.BackgroundTransparency = alpha
    local rhc = Instance.new("UICorner"); rhc.CornerRadius = UDim.new(0.5, 0); rhc.Parent = rh
    rh.Parent = ico

    return ico
end

-- ═══════════════════════════════════════════════════════════════════════════
