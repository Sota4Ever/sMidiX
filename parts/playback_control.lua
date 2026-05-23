-- ═══════════════════════════════════════════════════════════════════════════
-- PLAYBACK CONTROLS
-- ═══════════════════════════════════════════════════════════════════════════
local function startPlaybackFrom(startIndex, startRatio)
    if isRunning then log(T("log_already_playing")); return end
    local songs = SongData.songs
    if currentSongIndex < 1 or currentSongIndex > #songs then
        log(T("log_invalid_index")); return
    end
    local song = songs[currentSongIndex]
    if not song or not song.events then log(T("log_no_events")); return end

    stopFlag  = false; paused    = false; isRunning = true
    heldNoteCount = 0; generationId = generationId + 1
    table.clear(activeTransposedNotes)
    table.clear(heldKeys)
    sustainActive = false

    local rawDur = 0
    for _, ev in ipairs(song.events) do rawDur = rawDur + (ev.time or 0) end
    songTotalDuration = rawDur
    local ratio = startRatio or 0
    local scaledOffset = ratio * rawDur / (playbackSpeed * Config.baseSpeed)
    playbackRealStart  = os.clock() - scaledOffset
    playbackPauseTotal = 0
    playbackPauseBegin = 0

    updateGUI()

    local myGen = generationId
    task.spawn(function()
        local function fmtTime(s)
            s = math.floor(math.max(0, s))
            return string.format("%d:%02d", math.floor(s / 60), s % 60)
        end
        while isRunning and generationId == myGen do
            task.wait(0.05)
            if not paused and guiProgressFill and songTotalDuration > 0 then
                local scaledDur = songTotalDuration / (playbackSpeed * Config.baseSpeed)
                local elapsed   = os.clock() - playbackRealStart - playbackPauseTotal
                local pct = math.clamp(elapsed / scaledDur, 0, 1)
                tweenObject(guiProgressFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.08)
                if guiProgressTimeLabel then
                    guiProgressTimeLabel.Text = fmtTime(elapsed) .. " / " .. fmtTime(scaledDur)
                end
            end
            if not paused and windowRefs.eqBars then
                local numBars  = #windowRefs.eqBars
                local base     = math.min(heldNoteCount, 10) / 10
                local activity = math.max(base, 0.06)
                local maxH     = windowRefs.eqBarMaxH or 56
                local t        = os.clock()
		-- "peak" interaction (click/touch/drag) drives the viewer
                if windowRefs.interactionSpikeEnd and t < windowRefs.interactionSpikeEnd then
                    local k = math.clamp((windowRefs.interactionSpikeEnd - t) / 0.28, 0, 1)
                    activity = activity + 0.55 * k
                end
                local barFrac  = 1 / numBars
                local denom    = math.max(numBars - 1, 1)
                for bi, bar in ipairs(windowRefs.eqBars) do
                    local pos   = (bi - 1) / denom
                    -- Traveling ocean wave: swell moves left-to-right over time
                    local swell = math.sin(t * 1.1 - pos * math.pi * 2.4) * 0.5 + 0.5
                    local chop  = math.sin(t * 2.7 - pos * math.pi * 5.0) * 0.18 + 0.18
                    local drift = math.sin(t * 0.45 + pos * math.pi * 1.3) * 0.10 + 0.10
                    local wave  = swell * 0.62 + chop * 0.25 + drift * 0.13
                    local h     = math.max(4, maxH * activity * wave)
                    -- Direct lerp instead of TweenService (~640 tween objects/sec saved)
                    local curH  = bar.Size.Y.Offset
                    bar.Size    = UDim2.new(barFrac, -2, 0, curH + (h - curH) * 0.50)
                    -- Foam cap tracks crest
                    if windowRefs.eqFoam and windowRefs.eqFoam[bi] then
                        local fm = windowRefs.eqFoam[bi]
                        fm.Position = UDim2.new((bi-1)*barFrac, 1, 1, -3 - h)
                        fm.BackgroundTransparency = math.max(0.08, 0.9 - wave * activity * 0.8)
                    end
                end
            end
        end
        if guiProgressFill then
            tweenObject(guiProgressFill, {Size = UDim2.new(0, 0, 1, 0)}, 0.35)
        end
        if guiProgressTimeLabel then guiProgressTimeLabel.Text = "0:00" end
        if windowRefs.eqBars then
            local numBars = #windowRefs.eqBars
            local barFrac = 1 / numBars
            for bi, bar in ipairs(windowRefs.eqBars) do
                tweenObject(bar, {Size = UDim2.new(barFrac, -2, 0, 5)}, 0.5)
                if windowRefs.eqFoam and windowRefs.eqFoam[bi] then
                    windowRefs.eqFoam[bi].BackgroundTransparency = 0.9
                end
            end
        end
    end)

    task.spawn(function() playMidiFile(song.events, song.title, startIndex) end)
end

local function startPlayback()
    startPlaybackFrom(nil, 0)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- seekPlayback — searches for a (0–1) ratio of the current song without crashing
-- Preserves the paused state: if paused, jumps to the position
-- but does NOT automatically resume playback.
-- ═══════════════════════════════════════════════════════════════════════════
local function seekPlayback(ratio)
    local song = SongData.songs[currentSongIndex]
    if not song or not song.events then return end
    ratio = math.clamp(ratio, 0, 1)

    local wasRunning = isRunning
    local wasPaused  = paused

    stopFlag     = true
    paused       = false
    generationId = generationId + 1
    releaseAllHeldKeys()
    table.clear(activeTransposedNotes)
    isRunning = false

    local rawDur = 0
    for _, ev in ipairs(song.events) do rawDur = rawDur + (ev.time or 0) end
    local targetRaw = ratio * rawDur

    local accumulated = 0
    local seekIdx = #song.events
    for i, ev in ipairs(song.events) do
        accumulated = accumulated + (ev.time or 0)
        if accumulated >= targetRaw then
            seekIdx = i
            break
        end
    end

    task.wait(0.06)

    if wasRunning or wasPaused then
        startPlaybackFrom(seekIdx, ratio)
        if wasPaused then
            paused             = true
            playbackPauseBegin = os.clock()
            updateGUI()
        end
    else
        if guiProgressFill then
            guiProgressFill.Size = UDim2.new(ratio, 0, 1, 0)
        end
    end
end

local function pausePlayback()
    if not isRunning then return end
    paused = not paused
    if paused then
        playbackPauseBegin = os.clock()
    else
        playbackPauseTotal = playbackPauseTotal + (os.clock() - playbackPauseBegin)
    end
    log(paused and T("log_paused") or T("log_resumed"))
    updateGUI()
end

local function stopPlayback()
    if not isRunning and not paused then return end
    stopFlag  = true; paused    = false; isRunning = false
    generationId = generationId + 1
    releaseAllHeldKeys()
    table.clear(activeTransposedNotes)
    log(T("log_stopped"))
    updateGUI()
end

local function changeSpeed(delta)
    playbackSpeed = math.clamp(playbackSpeed + delta, 0.1, 5.0)
    Config.playbackSpeed = playbackSpeed
    log(string.format(T("log_speed_fmt"), playbackSpeed * 100))
    updateGUI()
end

