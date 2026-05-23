-- ═══════════════════════════════════════════════════════════════════════════
-- LOG
-- ═══════════════════════════════════════════════════════════════════════════
local function log(msg)
    print("[sMidiX] " .. msg)
    table.insert(logLines, string.format("[%.1f] %s", os.clock() % 1000, msg))
    if #logLines > MAX_LOG then table.remove(logLines, 1) end
    if guiLogLabel then
        guiLogLabel.Text = table.concat(logLines, "\n")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- KEYBOARD PRIMITIVES
-- ═══════════════════════════════════════════════════════════════════════════
local function pressKey(kc)
    VIM(true, kc, false)
    heldKeys[kc.Name] = kc
end

local function releaseKey(kc)
    VIM(false, kc, false)
    heldKeys[kc.Name] = nil
end

local function releaseAllHeldKeys()
    for _, kc in pairs(heldKeys) do
        VIM(false, kc, false)
    end
    table.clear(heldKeys)
    -- Release all special keys
    VIM(false, KeyMap.SPECIAL_KEYS.shift, false)
    VIM(false, KeyMap.SPECIAL_KEYS.ctrl,  false)
    VIM(false, KeyMap.SPECIAL_KEYS.alt,   false)
    VIM(false, KeyMap.SPECIAL_KEYS.space, false)
    heldNoteCount = 0
    sustainActive = false
end

local function pressAndMaybeRelease(kc)
    local limit = Config.fingerLimit
    if limit <= 10 and heldNoteCount >= limit then
        log(string.format("[finger limit] %d/%d — note skipped", heldNoteCount, limit))
        return
    end
    heldNoteCount = heldNoteCount + 1
    pressKey(kc)
    if Config.customHoldLength.enabled then
        local gen     = generationId
        local noteLen = Config.customHoldLength.noteLength
        task.delay(noteLen, function()
            if generationId ~= gen then return end
            releaseKey(kc)
            heldNoteCount = math.max(0, heldNoteCount - 1)
        end)
    end
end

local function simulateKey(msgType, rawNote, velocity)
    local note = rawNote + Config.pitchOffset + Config.transposeOffset
    local key, is88 = nil, false

    if KeyMap.keyMap61[note] then
        key = KeyMap.keyMap61[note]
    elseif Config.use88Keys and KeyMap.keyMapLow[note] then
        key = KeyMap.keyMapLow[note]; is88 = true
    elseif Config.use88Keys and KeyMap.keyMapHigh[note] then
        key = KeyMap.keyMapHigh[note]; is88 = true
    else
        log(string.format("[out of range] note %d (raw %d) skipped", note, rawNote))
        return
    end

    local isSharp = KeyMap.isSharpChar(key)
    local isUpper = KeyMap.isUpperChar(key)

    if msgType == "note_on" then
        if Config.velocity then
            local vk = KeyMap.findVelocityKey(velocity)
            local vc = KeyMap.charToKeyCode(vk)
            if vc then
                pressKey(KeyMap.SPECIAL_KEYS.alt); pressKey(vc)
                releaseKey(vc); releaseKey(KeyMap.SPECIAL_KEYS.alt)
            end
        end

        if not is88 then
            if Config.noDoubles then
                local baseChar = isSharp and KeyMap.keyMap61[note - 1] or key:lower()
                if baseChar then
                    local bc = KeyMap.charToKeyCode(baseChar)
                    if bc then releaseKey(bc) end
                end
            end
            if isSharp then
                local baseChar = KeyMap.keyMap61[note - 1]
                if baseChar then
                    local bc = KeyMap.charToKeyCode(baseChar)
                    if bc then
                        pressKey(KeyMap.SPECIAL_KEYS.shift)
                        pressAndMaybeRelease(bc)
                        releaseKey(KeyMap.SPECIAL_KEYS.shift)
                    end
                end
            elseif isUpper then
                local bc = KeyMap.charToKeyCode(key:lower())
                if bc then
                    pressKey(KeyMap.SPECIAL_KEYS.shift)
                    pressAndMaybeRelease(bc)
                    releaseKey(KeyMap.SPECIAL_KEYS.shift)
                end
            else
                local bc = KeyMap.charToKeyCode(key)
                if bc then pressAndMaybeRelease(bc) end
            end
        else
            -- 88-key extension notes: use Ctrl modifier
            local bc = KeyMap.charToKeyCode(key:lower())
            if bc then
                releaseKey(bc)
                pressKey(KeyMap.SPECIAL_KEYS.ctrl)
                pressAndMaybeRelease(bc)
                releaseKey(KeyMap.SPECIAL_KEYS.ctrl)
            end
        end

    elseif msgType == "note_off" then
        local releaseChar
        if not is88 and isSharp then
            releaseChar = KeyMap.keyMap61[note - 1]
        else
            releaseChar = key:lower()
        end
        if releaseChar then
            local bc = KeyMap.charToKeyCode(releaseChar)
            if bc then releaseKey(bc) end
        end
        heldNoteCount = math.max(0, heldNoteCount - 1)
    end
end

local function applySustainCC(value)
    -- Standard MIDI: CC64 >= 64 = pedal on, CC64 < 64 = pedal off.
    -- sustainCutoff default is 63, so: on when value > 63, off when value <= 63.
    if not sustainActive and value > Config.sustainCutoff then
        sustainActive = true
        pressKey(KeyMap.SPECIAL_KEYS.space)
    elseif sustainActive and value <= Config.sustainCutoff then
        sustainActive = false
        releaseKey(KeyMap.SPECIAL_KEYS.space)
    end
end

local function parseMidi(msg)
    if msg.type == "control_change" and Config.sustain and msg.control == 64 then
        applySustainCC(msg.value)
    elseif msg.type == "note_on" or msg.type == "note_off" then
        pcall(function()
            local mtype = (msg.velocity == 0) and "note_off" or msg.type
            simulateKey(mtype, msg.note, msg.velocity)
        end)
    end
end
