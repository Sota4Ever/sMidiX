-- ═══════════════════════════════════════════════════════════════════════════
-- UPLOADING SONGS FROM THE EXECUTOR'S WORKSPACE
-- ═══════════════════════════════════════════════════════════════════════════
local function loadSongsFromWorkspace()
    if not (type(listfiles) == "function" and type(readfile) == "function") then
        warn("[sMidiX] readfile/listfiles not available in this executor.")
        return 0
    end
    if type(isfolder) == "function" and type(makefolder) == "function" then
        if not isfolder(SONGS_FOLDER) then
            pcall(makefolder, SONGS_FOLDER)
        end
    end
    local ok, files = pcall(listfiles, SONGS_FOLDER)
    if not ok or type(files) ~= "table" then
        warn("[sMidiX] Could not read folder '" .. SONGS_FOLDER .. "'")
        return 0
    end
    local loaded = 0
    for _, path in ipairs(files) do
        local pathStr = tostring(path)
        if pathStr:lower():match("%.lua$") then
            local ok2, content = pcall(readfile, pathStr)
            if ok2 and type(content) == "string" and #content > 10 then
                local fn, err = loadstring(content)
                if fn then
                    local ok3, song = pcall(fn)
                    if ok3 and type(song) == "table" and type(song.events) == "table" then
                        song.title  = song.title  or pathStr:match("([^/\\]+)%.lua$") or "Unknown"
                        song.artist = song.artist or "Unknown"
                        song._external = true
                        table.insert(SongData.songs, song)
                        loaded = loaded + 1
                        print("[sMidiX] Loaded: " .. song.title)
                    else
                        warn("[sMidiX] Invalid table in: " .. pathStr)
                    end
                else
                    warn("[sMidiX] Syntax error in: " .. pathStr .. " | " .. tostring(err))
                end
            end
        end
    end
    return loaded
end

local externalSongs = loadSongsFromWorkspace()

