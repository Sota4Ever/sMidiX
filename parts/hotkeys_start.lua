-- ═══════════════════════════════════════════════════════════════════════════
-- HOTKEYS — ONLY PC
-- ═══════════════════════════════════════════════════════════════════════════
if not IS_MOBILE then
    UserInputService.InputBegan:Connect(function(inp, gameProcessed)
        if gameProcessed then return end
        local kc = inp.KeyCode
        if     kc == Config.hotkeys.play      then if not isRunning then startPlayback() else pausePlayback() end
        elseif kc == Config.hotkeys.pause     then pausePlayback()
        elseif kc == Config.hotkeys.stop      then stopPlayback()
        elseif kc == Config.hotkeys.speedUp   then changeSpeed( Config.decreaseSize)
        elseif kc == Config.hotkeys.slowDown  then changeSpeed(-Config.decreaseSize)
        end
    end)
end

buildGUI()
updateGUI()
log(T("console_ready"))
log(string.format(T("console_ready_fmt"), #SongData.songs - externalSongs, externalSongs))
