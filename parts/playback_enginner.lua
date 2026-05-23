-- ═══════════════════════════════════════════════════════════════════════════
-- playMidiOnce — accepts optional startIndex for secure seek
-- ═══════════════════════════════════════════════════════════════════════════
local function playMidiOnce(events, startIndex)
    local startTime   = os.clock()
    local currentTime = 0.0
    local wasPaused   = false
    local firstIdx    = startIndex or 1

    -- Pre-accumulate elapsed time if seek is done midway
    if firstIdx > 1 then
        for i = 1, firstIdx - 1 do
            currentTime = currentTime + (events[i].time or 0) / (playbackSpeed * Config.baseSpeed)
        end
        startTime = os.clock() - currentTime
    end

    for i = firstIdx, #events do
        if stopFlag then return false end

        local msg   = events[i]
        local delay = msg.time / (playbackSpeed * Config.baseSpeed)

        if Config.randomFail.enabled and msg.type ~= "meta" then
            if math.random() < Config.randomFail.speed / 100 then
                delay = delay * (math.random() + 0.5)
            end
        end

        currentTime = currentTime + delay
        local target = startTime + currentTime

        local keepWaiting = true
        while keepWaiting do
            if stopFlag then return false end

            if paused and not wasPaused then
                wasPaused = true
                if Config.releaseOnPause then
                    releaseAllHeldKeys()
                end
            end
            if not paused and wasPaused then
                wasPaused = false
                -- Only restore Space if releaseOnPause actually released it.
                -- If releaseOnPause is false, Space is still held and must not be re-pressed.
                if Config.releaseOnPause and Config.sustain and sustainActive then
                    pressKey(KeyMap.SPECIAL_KEYS.space)
                end
            end
            while paused and not stopFlag do
                local ps = os.clock()
                task.wait(0.05)
                local pd = os.clock() - ps
                startTime  = startTime  + pd
                target     = target     + pd
            end
            if stopFlag then return false end

            local remaining = target - os.clock()
            if remaining <= 0 then
                keepWaiting = false
            else
                task.wait(math.min(remaining, 0.016))
            end
        end

        if stopFlag then return false end

        -- Skip meta events entirely (tempo changes, markers, etc.) — nothing to dispatch.
        if msg.type ~= "meta" then
            if paused then
                -- While paused, only track sustain state — do NOT send key events.
                -- applySustainCC would press/release Space immediately, which causes
                -- a double-press when the resume block re-presses Space on sustainActive.
                if msg.type == "control_change" and msg.control == 64 and Config.sustain then
                    if msg.value > Config.sustainCutoff then
                        sustainActive = true
                    else
                        sustainActive = false
                    end
                end
            else
                local dispatched = false
                if msg.type == "note_on" and msg.velocity > 0 and Config.randomFail.enabled then
                    if math.random() < Config.randomFail.transpose / 100 then
                        local newNote = msg.note + math.random(-12, 12)
                        if not activeTransposedNotes[msg.note] then
                            activeTransposedNotes[msg.note] = {}
                        end
                        table.insert(activeTransposedNotes[msg.note], newNote)
                        parseMidi({type="note_on", note=newNote, velocity=msg.velocity, time=0})
                        dispatched = true
                    end
                end

                if not dispatched then
                    local isOff = (msg.type == "note_off") or (msg.type == "note_on" and msg.velocity == 0)
                    if isOff then
                        local q = activeTransposedNotes[msg.note]
                        if q and #q > 0 then
                            local tn = table.remove(q, 1)
                            if #q == 0 then activeTransposedNotes[msg.note] = nil end
                            parseMidi({type="note_off", note=tn, velocity=0, time=0})
                            dispatched = true
                        end
                    end
                end

                if not dispatched then
                    parseMidi(msg)
                end
            end
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- playMidiFile — accepts optional startIndex
-- ═══════════════════════════════════════════════════════════════════════════
local function playMidiFile(events, title, startIndex)
    log(T("log_playing") .. title)
    local isFirst = true
    while not stopFlag do
        local idx = (isFirst and startIndex) or nil
        isFirst = false
        local finished = playMidiOnce(events, idx)
        if not Config.loopSong or not finished or stopFlag then break end
        releaseAllHeldKeys()
        log(T("log_restarting"))
    end
    if not Config.loopSong then
        local completed = not stopFlag
        -- If external stopPlayback() already cleaned up (isRunning=false, stopFlag=true),
        -- skip to avoid overwriting state of a new playback that may have started.
        if isRunning or completed then
            stopFlag  = false
            isRunning = false
            releaseAllHeldKeys()
            if completed then
                log(T("log_complete"))
            end
            task.defer(function() updateGUI() end)
        end
    end
end

