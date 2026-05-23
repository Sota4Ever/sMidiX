-- ═══════════════════════════════════════════════════════════════════════════
-- createSongButton
-- ═══════════════════════════════════════════════════════════════════════════
local function createSongButton(parent, index, song)
    local DBTN        = IS_MOBILE and 34 or 28
    local TITLE_FSIZE = IS_MOBILE and 13 or 12
    local META_FSIZE  = IS_MOBILE and 11 or 10
    local FAV_BTN_SZ  = IS_MOBILE and 28 or 22
    local BTN_BASE_H  = IS_MOBILE and 76 or 68

    local button = Instance.new("TextButton")
    button.Name = "Song_" .. index
    button.Size = UDim2.new(1, 0, 0, BTN_BASE_H)
    button.BackgroundColor3 = C.card
    button.BackgroundTransparency = 0.12
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = parent

    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = button
    local stroke = addStroke(button, C.border, 1, 0.48)

    local indicator = newFrame(button, UDim2.new(0, 4, 1, -14), UDim2.new(0, 0, 0, 7), C.accentBlue, 99)
    indicator.BackgroundTransparency = 0.82

    local rightPad = song._external and (DBTN + FAV_BTN_SZ + 32) or (FAV_BTN_SZ + 16)

    local titleW = BTN_BASE_H - (IS_MOBILE and 32 or 28)
    local title = newLabel(
        button,
        song.title or ("Song " .. index),
        UDim2.new(1, -rightPad, 0, titleW),
        UDim2.new(0, 14, 0, 4),
        nil, C.text, TITLE_FSIZE
    )
    title.Font = Enum.Font.GothamSemibold
    title.TextTruncate = Enum.TextTruncate.None
    title.TextWrapped = true
    title.TextYAlignment = Enum.TextYAlignment.Top

    local metaY = BTN_BASE_H - (IS_MOBILE and 28 or 24)
    local meta = newLabel(
        button,
        formatDuration(getSongDuration(song)),
        UDim2.new(1, -rightPad, 0, 18),
        UDim2.new(0, 14, 0, metaY),
        nil, C.textSub, META_FSIZE
    )
    meta.TextWrapped = false
    meta.TextTruncate = Enum.TextTruncate.AtEnd

    local favKey = songFavKey(song)
    local favBtn = Instance.new("TextButton")
    favBtn.Size = UDim2.new(0, FAV_BTN_SZ, 0, FAV_BTN_SZ)
    favBtn.Position = song._external
        and UDim2.new(1, -(DBTN + FAV_BTN_SZ + 6), 0, 4)
        or  UDim2.new(1, -(FAV_BTN_SZ + 4), 0, 4)
    favBtn.BackgroundTransparency = 1
    favBtn.BorderSizePixel = 0
    favBtn.Text = ""
    favBtn.ZIndex = 10
    favBtn.AutoButtonColor = false
    favBtn.Parent = button
    local FAV_ICO_SZ  = IS_MOBILE and 14 or 11
    local FAV_ICO_OFF = math.floor((FAV_BTN_SZ - FAV_ICO_SZ) / 2)
    makeFavIcon(favBtn, FAV_ICO_SZ, FAV_ICO_OFF, FAV_ICO_OFF,
        favorites.songs[favKey] and C.favActive or C.textSub,
        favorites.songs[favKey] == true)

    favBtn.Activated:Connect(function()
        favorites.songs[favKey] = not favorites.songs[favKey]
        if windowRefs.songListFrame then
            rebuildLibrary(windowRefs.songListFrame)
        end
    end)

    -- Delete button: only for external (user-loaded) songs, not built-in ones
    if song._external then
        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, DBTN, 0, DBTN)
        delBtn.Position = UDim2.new(1, -(DBTN + 4), 0, 4)
        delBtn.BackgroundColor3 = C.bg4
        delBtn.BackgroundTransparency = 0.55
        delBtn.BorderSizePixel = 0
        delBtn.Text = "×"
        delBtn.TextColor3 = C.textSub
        delBtn.TextSize = IS_MOBILE and 17 or 14
        delBtn.Font = Enum.Font.GothamBold
        delBtn.ZIndex = 10
        delBtn.AutoButtonColor = false
        delBtn.Parent = button
        local delC = Instance.new("UICorner"); delC.CornerRadius = UDim.new(0, 8); delC.Parent = delBtn
        local delConfirming = false
        delBtn.Activated:Connect(function()
            if not delConfirming then
                delConfirming = true
                delBtn.Text = "✓"
                delBtn.BackgroundColor3 = C.stop
                delBtn.BackgroundTransparency = 0.1
                delBtn.TextColor3 = C.selectedText
                task.delay(2.5, function()
                    if delConfirming then
                        delConfirming = false
                        delBtn.Text = "×"
                        delBtn.BackgroundColor3 = C.bg4
                        delBtn.BackgroundTransparency = 0.55
                        delBtn.TextColor3 = C.textSub
                    end
                end)
            else
                delConfirming = false
                local removedTitle = song.title or ("Song " .. index)
                table.remove(SongData.songs, index)
                if currentSongIndex >= index and currentSongIndex > 1 then currentSongIndex = currentSongIndex - 1 end
                if currentSongIndex > #SongData.songs then currentSongIndex = #SongData.songs end
                if windowRefs.songListFrame then rebuildLibrary(windowRefs.songListFrame) end
                log(T("log_removed") .. removedTitle)
                updateGUI()
            end
        end)
    end

    local entry = { button=button, title=title, meta=meta, indicator=indicator, stroke=stroke, isActive=false }

    button.Activated:Connect(function()
        if currentSongIndex == index then
            if isRunning then stopPlayback() end
            currentSongIndex = 0
            log(T("log_deselected"))
        else
            if isRunning then stopPlayback() end
            currentSongIndex = index
            setSection("library")
            log(T("log_selected") .. (song.title or ("Song " .. index)))
        end
        updateGUI()
    end)

    if not IS_MOBILE then
        button.MouseEnter:Connect(function()
            if entry.isActive then return end
            tweenObject(button, {BackgroundColor3 = C.bg4}, 0.12)
        end)
        button.MouseLeave:Connect(function()
            if entry.isActive then return end
            tweenObject(button, {BackgroundColor3 = C.card}, 0.12)
        end)
    end

    songButtons[index] = entry
    refreshSongButton(entry, index == currentSongIndex)
    return entry
end

-- ═══════════════════════════════════════════════════════════════════════════
-- rebuildLibrary
-- ═══════════════════════════════════════════════════════════════════════════
rebuildLibrary = function(parent)
    for _, ch in ipairs(parent:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    songButtons = {}
    parent.CanvasPosition = Vector2.new(0, 0)

    local songs = SongData.songs

    local artistGroups = {}
    local artistOrder  = {}
    for i, song in ipairs(songs) do
        local artist = normalizeArtist(song.artist)
        if not artistGroups[artist] then
            artistGroups[artist] = {}
            table.insert(artistOrder, artist)
        end
        table.insert(artistGroups[artist], i)
    end

    table.sort(artistOrder, function(a, b)
        local fa = favorites.artists[a] or false
        local fb = favorites.artists[b] or false
        if fa ~= fb then return fa end
        return a:lower() < b:lower()
    end)

    if currentArtistView ~= nil then
        local artistName = currentArtistView
        local indices    = artistGroups[artistName] or {}
        local isFavArtist = favorites.artists[artistName] or false

        table.sort(indices, function(a, b)
            local ka = songFavKey(songs[a]); local kb = songFavKey(songs[b])
            local fa2 = favorites.songs[ka] or false; local fb2 = favorites.songs[kb] or false
            if fa2 ~= fb2 then return fa2 end
            return (songs[a].title or ""):lower() < (songs[b].title or ""):lower()
        end)

        local BACK_H  = IS_MOBILE and 40 or 34
        local FAV_SZ2 = IS_MOBILE and 24 or 18

        local backRow = newFrame(parent, UDim2.new(1, 0, 0, BACK_H), UDim2.new(), C.bg3, 9)
        backRow.BackgroundTransparency = 0.08
        addStroke(backRow, C.border, 1, 0.38)

        local MINI_W = IS_MOBILE and 62 or 52
        local MINI_H = BACK_H - (IS_MOBILE and 8 or 6)
        local miniBack = Instance.new("TextButton")
        miniBack.Name             = "BackToArtists"
        miniBack.Size             = UDim2.new(0, MINI_W, 0, MINI_H)
        miniBack.Position         = UDim2.new(0, IS_MOBILE and 4 or 3, 0.5, -math.floor(MINI_H / 2))
        miniBack.BackgroundColor3 = C.bg4
        miniBack.BackgroundTransparency = 0.18
        miniBack.BorderSizePixel  = 0
        miniBack.Text             = ""
        miniBack.AutoButtonColor  = false
        miniBack.ZIndex           = 5
        miniBack.Parent           = backRow
        local miniC = Instance.new("UICorner"); miniC.CornerRadius = UDim.new(0, 7); miniC.Parent = miniBack
        local miniStroke = Instance.new("UIStroke")
        miniStroke.Color            = C.accentBlue
        miniStroke.Thickness        = 1.5
        miniStroke.Transparency     = 0.15
        miniStroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
        miniStroke.Parent           = miniBack

        local arrowIco = Instance.new("TextLabel")
        arrowIco.BackgroundTransparency = 1
        arrowIco.BorderSizePixel  = 0
        arrowIco.Size             = UDim2.new(0, IS_MOBILE and 18 or 15, 1, 0)
        arrowIco.Position         = UDim2.new(0, IS_MOBILE and 5 or 4, 0, 0)
        arrowIco.Text             = "←"
        arrowIco.TextColor3       = C.accentBlue
        arrowIco.Font             = Enum.Font.GothamBold
        arrowIco.TextSize         = IS_MOBILE and 15 or 13
        arrowIco.TextXAlignment   = Enum.TextXAlignment.Center
        arrowIco.TextYAlignment   = Enum.TextYAlignment.Center
        arrowIco.Parent           = miniBack

        local backTextLbl = newLabel(
            miniBack,
            T("back_btn"),
            UDim2.new(1, -(IS_MOBILE and 24 or 20), 1, 0),
            UDim2.new(0, IS_MOBILE and 22 or 18, 0, 0),
            nil, C.accentBlue, IS_MOBILE and 10 or 9
        )
        backTextLbl.Font             = Enum.Font.GothamSemibold
        backTextLbl.TextXAlignment   = Enum.TextXAlignment.Left
        backTextLbl.TextYAlignment   = Enum.TextYAlignment.Center

        local miniSc = Instance.new("UIScale"); miniSc.Scale = 1; miniSc.Parent = miniBack

        miniBack.Activated:Connect(function()
            miniSc.Scale = 0.86
            tweenObject(miniSc, {Scale = 1.0}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            task.defer(function()
                currentArtistView = nil
                rebuildLibrary(parent)
            end)
        end)
        if not IS_MOBILE then
            miniBack.MouseEnter:Connect(function() tweenObject(miniBack, {BackgroundColor3 = C.hover}, 0.1) end)
            miniBack.MouseLeave:Connect(function() tweenObject(miniBack, {BackgroundColor3 = C.bg4}, 0.1) end)
        end

        local MINI_END = (IS_MOBILE and 4 or 3) + MINI_W + 8
        local nameLbl = newLabel(
            backRow, artistName,
            UDim2.new(1, -(MINI_END + FAV_SZ2 + 12), 1, 0),
            UDim2.new(0, MINI_END, 0, 0),
            nil, isFavArtist and C.favActive or C.text, IS_MOBILE and 12 or 11
        )
        nameLbl.Font             = Enum.Font.GothamSemibold
        nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
        nameLbl.TextYAlignment   = Enum.TextYAlignment.Center

        local artFavBtn2 = Instance.new("TextButton")
        artFavBtn2.Size               = UDim2.new(0, FAV_SZ2, 0, FAV_SZ2)
        artFavBtn2.Position           = UDim2.new(1, -(FAV_SZ2 + 4), 0.5, -math.floor(FAV_SZ2 / 2))
        artFavBtn2.BackgroundTransparency = 1; artFavBtn2.BorderSizePixel = 0
        artFavBtn2.Text               = ""
        artFavBtn2.ZIndex             = 10
        artFavBtn2.AutoButtonColor    = false
        artFavBtn2.Parent             = backRow
        local AFI2_SZ  = IS_MOBILE and 12 or 10
        local AFI2_OFF = math.floor((FAV_SZ2 - AFI2_SZ) / 2)
        makeFavIcon(artFavBtn2, AFI2_SZ, AFI2_OFF, AFI2_OFF, isFavArtist and C.favActive or C.textSub, isFavArtist)
        artFavBtn2.Activated:Connect(function()
            favorites.artists[artistName] = not favorites.artists[artistName]
            rebuildLibrary(parent); updateGUI()
        end)

        for _, songIdx in ipairs(indices) do
            createSongButton(parent, songIdx, songs[songIdx])
        end

        task.defer(function()
            local ly = parent:FindFirstChildOfClass("UIListLayout")
            if ly then parent.CanvasSize = UDim2.new(0, 0, 0, ly.AbsoluteContentSize.Y + 8) end
        end)
        return
    end

    local FOLDER_H = IS_MOBILE and 42 or 36
    local FAV_SZ   = IS_MOBILE and 24 or 18

    for _, artistName in ipairs(artistOrder) do
        local indices     = artistGroups[artistName]
        local isFavArtist = favorites.artists[artistName] or false

        local folderBtn = Instance.new("TextButton")
        folderBtn.Name = "Artist_" .. artistName
        folderBtn.Size = UDim2.new(1, 0, 0, FOLDER_H)
        folderBtn.BackgroundColor3 = isFavArtist and Color3.fromRGB(64, 70, 84) or C.bg3
        folderBtn.BackgroundTransparency = 0.10
        folderBtn.BorderSizePixel = 0
        folderBtn.Text = ""
        folderBtn.AutoButtonColor = false
        folderBtn.Parent = parent

        local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0, 9); fC.Parent = folderBtn
        addStroke(folderBtn, C.border, 1, isFavArtist and 0.20 or 0.44)

        local arrowLbl = Instance.new("TextLabel")
        arrowLbl.BackgroundTransparency = 1; arrowLbl.BorderSizePixel = 0
        arrowLbl.Size = UDim2.new(0, 16, 1, 0); arrowLbl.Position = UDim2.new(0, 5, 0, 0)
        arrowLbl.Text = "▸"
        arrowLbl.TextColor3 = C.textSub; arrowLbl.Font = Enum.Font.GothamBold
        arrowLbl.TextSize = 12; arrowLbl.TextXAlignment = Enum.TextXAlignment.Center
        arrowLbl.TextYAlignment = Enum.TextYAlignment.Center; arrowLbl.Parent = folderBtn

        local artistLbl = newLabel(
            folderBtn, artistName,
            UDim2.new(1, -(FAV_SZ + 46), 1, 0), UDim2.new(0, 24, 0, 0),
            nil, isFavArtist and C.favActive or C.text, IS_MOBILE and 12 or 11
        )
        artistLbl.Font = Enum.Font.GothamSemibold
        artistLbl.TextTruncate = Enum.TextTruncate.None
        artistLbl.TextWrapped = true
        artistLbl.TextYAlignment = Enum.TextYAlignment.Center

        local countLbl = newLabel(folderBtn, tostring(#indices), UDim2.new(0, 22, 1, 0), UDim2.new(1, -(FAV_SZ + 26), 0, 0), nil, C.textSub, IS_MOBILE and 10 or 9)
        countLbl.TextXAlignment = Enum.TextXAlignment.Center; countLbl.TextYAlignment = Enum.TextYAlignment.Center

        local artFavBtn = Instance.new("TextButton")
        artFavBtn.Size = UDim2.new(0, FAV_SZ, 0, FAV_SZ)
        artFavBtn.Position = UDim2.new(1, -(FAV_SZ + 4), 0.5, -math.floor(FAV_SZ/2))
        artFavBtn.BackgroundTransparency = 1; artFavBtn.BorderSizePixel = 0
        artFavBtn.Text = ""; artFavBtn.ZIndex = 10
        artFavBtn.AutoButtonColor = false; artFavBtn.Parent = folderBtn
        local AFI_SZ  = IS_MOBILE and 12 or 10
        local AFI_OFF = math.floor((FAV_SZ - AFI_SZ) / 2)
        makeFavIcon(artFavBtn, AFI_SZ, AFI_OFF, AFI_OFF, isFavArtist and C.favActive or C.textSub, isFavArtist)

        local capturedArtist = artistName
        artFavBtn.Activated:Connect(function()
            favorites.artists[capturedArtist] = not favorites.artists[capturedArtist]
            rebuildLibrary(parent); updateGUI()
        end)

        -- Click en carpeta → drill-down
        folderBtn.Activated:Connect(function()
            currentArtistView = capturedArtist
            rebuildLibrary(parent)
        end)

        if not IS_MOBILE then
            folderBtn.MouseEnter:Connect(function() tweenObject(folderBtn, {BackgroundColor3 = C.hover}, 0.1) end)
            folderBtn.MouseLeave:Connect(function() tweenObject(folderBtn, {BackgroundColor3 = isFavArtist and Color3.fromRGB(64,70,84) or C.bg3}, 0.1) end)
        end
    end

    task.defer(function()
        local ly = parent:FindFirstChildOfClass("UIListLayout")
        if ly then parent.CanvasSize = UDim2.new(0, 0, 0, ly.AbsoluteContentSize.Y + 8) end
    end)
end

local function createSettingRow(parent, titleText, descText, getFn, setFn)
    local ROW_H = IS_MOBILE and 70 or 64
    local row = newFrame(parent, UDim2.new(1, 0, 0, ROW_H), UDim2.new(), C.card, 12)
    row.BackgroundTransparency = 0.08
    local stroke = addStroke(row, C.border, 1, 0.5)

    local title = newLabel(row, titleText, UDim2.new(1, -90, 0, 22), UDim2.new(0, 14, 0, IS_MOBILE and 12 or 10), nil, C.text, IS_MOBILE and 13 or 13)
    title.Font = Enum.Font.GothamSemibold; title.TextWrapped = false; title.TextTruncate = Enum.TextTruncate.AtEnd

    local desc = newLabel(row, descText, UDim2.new(1, -100, 0, IS_MOBILE and 20 or 18), UDim2.new(0, 14, 0, IS_MOBILE and 36 or 34), nil, C.textSub, 10)
    desc.TextWrapped = true; desc.TextTruncate = Enum.TextTruncate.AtEnd

    local track = newFrame(row, UDim2.new(0, 46, 0, 24), UDim2.new(1, -62, 0.5, -12), C.bg4, 99)
    track.BackgroundTransparency = 0.2; addStroke(track, C.border, 1, 0.55)

    local knob = newFrame(track, UDim2.new(0, 18, 0, 18), UDim2.new(0, 3, 0.5, -9), C.text, 99)
    knob.BackgroundTransparency = 0

    local clickZone = Instance.new("TextButton")
    clickZone.BackgroundTransparency = 1; clickZone.Text = ""; clickZone.AutoButtonColor = false
    clickZone.Size = UDim2.new(1, 0, 1, 0); clickZone.Parent = row
    clickZone.Activated:Connect(function() setFn(not getFn()); updateGUI() end)

    local entry = { row=row, track=track, knob=knob, title=title, stroke=stroke, get=getFn }
    table.insert(toggleRows, entry); refreshToggleRow(entry)
    return entry
end
