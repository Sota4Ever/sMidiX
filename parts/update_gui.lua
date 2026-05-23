-- ═══════════════════════════════════════════════════════════════════════════
-- updateGUI
-- ═══════════════════════════════════════════════════════════════════════════
updateGUI = function()
    local songs = SongData.songs
    local song  = songs[currentSongIndex]
    local statusColor = getStatusColor()

    if guiSongLabel then
        guiSongLabel.Text = song and (song.title or "...") or T("no_songs")
    end
    if guiSongMetaLabel then
        if song then
            guiSongMetaLabel.Text = string.format("%s  •  %s  •  %s",
                normalizeArtist(song.artist),
                formatDuration(getSongDuration(song)),
                string.format(T("events_fmt"), #(song.events or {}))
            )
        else
            guiSongMetaLabel.Text = T("no_song_meta")
        end
    end
    if guiLibraryLabel then
        if song then
            guiLibraryLabel.Text = string.format(T("lib_active"),
                song.title or "?", normalizeArtist(song.artist),
                formatDuration(getSongDuration(song)), #(song.events or {})
            )
        else
            guiLibraryLabel.Text = T("lib_no_songs")
        end
    end
    if guiPlayerSummaryLabel then
        guiPlayerSummaryLabel.Text = string.format(T("player_summary"),
            getStatusText(), playbackSpeed * 100,
            Config.loopSong and "ON" or "OFF", Config.use88Keys and "ON" or "OFF",
            Config.sustain and "ON" or "OFF", Config.noDoubles and "ON" or "OFF",
            Config.velocity and "ON" or "OFF"
        )
    end
    if guiSpeedLabel then
        guiSpeedLabel.Text = string.format("%s  %.0f%%", T("speed"), playbackSpeed * 100)
    end
    if guiStatusLabel then
        guiStatusLabel.Text = getStatusText()
        guiStatusLabel.TextColor3 = getStatusTextColor()
    end
    if windowRefs.statusBadge then
        windowRefs.statusBadge.BackgroundColor3 = statusColor
    end
    if windowRefs.selContent then
        local hasSong = (SongData.songs[currentSongIndex] ~= nil)
        windowRefs.selContent.Visible = hasSong
        if windowRefs.noSelHint then windowRefs.noSelHint.Visible = not hasSong end
    end
    if guiDockSongLabel then
        guiDockSongLabel.Text = song and (song.title or "...") or T("no_songs")
    end
    if guiDockStateLabel then
        guiDockStateLabel.Text = string.format("%s  •  %.0f%%", getStatusText(), playbackSpeed * 100)
    end
    if windowRefs.libraryStats then
        windowRefs.libraryStats.Text = string.format("%d %s", #songs, T("songs_count"))
    end

    if btnPlay then
        btnPlay:SetAttribute("Locked", true)
        if isRunning and not paused then
            btnPlay.Text = IS_MOBILE and "II" or ("II  " .. T("pause"))
            btnPlay.BackgroundColor3 = C.pause; btnPlay.TextColor3 = C.selectedText
        elseif paused then
            btnPlay.Text = IS_MOBILE and "▶" or ("▶  " .. T("resume"))
            btnPlay.BackgroundColor3 = C.accentBlue; btnPlay.TextColor3 = C.text
        else
            btnPlay.Text = IS_MOBILE and "▶" or ("▶  " .. T("play"))
            btnPlay.BackgroundColor3 = C.play; btnPlay.TextColor3 = C.selectedText
        end
        btnPlay:SetAttribute("Locked", false)
    end
    if dockPlayButton then
        dockPlayButton:SetAttribute("Locked", true)
        dockPlayButton.Text = (isRunning and not paused) and "II" or "▶"
        dockPlayButton.BackgroundColor3 = (isRunning and not paused) and C.pause or C.play
        dockPlayButton.TextColor3 = C.selectedText
        dockPlayButton:SetAttribute("Locked", false)
    end

    for i, entry in pairs(songButtons) do refreshSongButton(entry, i == currentSongIndex) end
    for _, row in ipairs(toggleRows) do refreshToggleRow(row) end
    for name in pairs(sectionButtons) do refreshSectionButton(name) end
end
