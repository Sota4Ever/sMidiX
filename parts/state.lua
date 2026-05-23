-- ═══════════════════════════════════════════════════════════════════════════
-- PLAYBACK STATUS
-- ═══════════════════════════════════════════════════════════════════════════
local heldKeys              = {}
local heldNoteCount         = 0
local activeTransposedNotes = {}
local sustainActive         = false
local stopFlag              = false
local paused                = false
local playbackSpeed         = Config.playbackSpeed
local currentSongIndex      = 0
local isRunning             = false
local generationId          = 0
local currentLang           = "en"
local songTotalDuration     = 0
local playbackRealStart     = 0
local playbackPauseTotal    = 0
local playbackPauseBegin    = 0

-- ═══════════════════════════════════════════════════════════════════════════
-- FAVORITES AND LIBRARY NAVIGATION STATUS
-- ═══════════════════════════════════════════════════════════════════════════
local favorites         = { artists = {}, songs = {} }
local currentArtistView = nil

-- ═══════════════════════════════════════════════════════════════════════════
-- VARIABLES GUI
-- ═══════════════════════════════════════════════════════════════════════════
local guiLogLabel, guiSongLabel, guiSongMetaLabel, guiSpeedLabel
local guiStatusLabel, guiLibraryLabel, guiPlayerSummaryLabel
local guiDockSongLabel, guiDockStateLabel
local guiProgressFill, guiProgressTimeLabel
local btnPlay, btnStop, btnPrev, btnNext, btnSpdDn, btnSpdUp, dockPlayButton
local MAX_LOG  = 16
local logLines = {}
local songButtons    = {}
local toggleRows     = {}
local sectionButtons = {}
local contentPanels  = {}
local windowRefs     = {}
local currentSection = "library"

-- ═══════════════════════════════════════════════════════════════════════════
-- FORWARD DECLARATIONS
-- ═══════════════════════════════════════════════════════════════════════════
local updateGUI
local T
local tweenObject
local rebuildLibrary
