-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════════════════
local Config = {
    baseSpeed        = 1.0,  -- global timing multiplier (compensates Roblox task.wait overhead)
    playbackSpeed    = 1.0,
    pitchOffset      = 0,
    transposeOffset  = 0,
    noDoubles        = true,
    use88Keys        = true,
    sustain          = false,
    sustainCutoff    = 63,
    velocity         = false,
    loopSong         = false,
    releaseOnPause   = true,
    fingerLimit      = 11,
    customHoldLength = { enabled=false, noteLength=0.1 },
    randomFail       = { enabled=false, speed=5.0, transpose=5.0 },
    decreaseSize     = 0.05,
    hotkeys = {
        play     = Enum.KeyCode.F1,
        pause    = Enum.KeyCode.F2,
        stop     = Enum.KeyCode.F3,
        speedUp  = Enum.KeyCode.F4,
        slowDown = Enum.KeyCode.F5,
    },
}
