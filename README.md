# sMidiX

sMidiX is a Roblox MIDI piano autoplayer script designed for script executors. It simulates keyboard input via Roblox's `VirtualInputManager` to play MIDI note sequences automatically in supported Roblox piano games.

---

## What is sMidiX?

sMidiX reads MIDI song data (stored as Lua tables) and translates it into precise, timed keystrokes that simulate a real player performing the piece inside a Roblox game. It ships with a polished in-game GUI, full hotkey support, and a range of playback options to make the output sound as natural — or as perfect — as you want.

---

## Convert MIDI to Lua

Use [**NoteSmith**](https://bit.ly/Notesmith-smidix) to convert any `.mid` file into the Lua format compatible with sMidiX

---

## Features

- **MIDI Playback Engine** — Accurate note-on/note-off event processing with configurable speed, pitch offset, and transpose.
- **88-Key Mapping** — Extends the keyboard note map across the full piano range, including high and low registers.
- **No Doubles Mode** — Prevents duplicate base notes when playing sharps/flats.
- **Sustain Support** — Processes sustain pedal messages from MIDI data.
- **Velocity Dynamics** — Uses ALT velocity keys to add musical dynamics to playback.
- **Random Fail** — Introduces subtle imperfections so playback sounds less robotic.
- **Custom Hold Length** — Applies a fixed note duration when holding notes.
- **Loop Mode** — Automatically repeats the song when it ends.
- **Release On Pause** — Releases all held keys when playback is paused.
- **External Song Loading** — Load your own `.lua` song files at runtime from the `sMidiX/` folder in your executor workspace.
- **Mobile Support** — Detects Android/iOS and adjusts the GUI layout accordingly.
- **Built-in Console** — Logs playback events, errors, and status messages in real time.

---

## Hotkeys

| Key | Action    |
|-----|-----------|
| F1  | Play      |
| F2  | Pause     |
| F3  | Stop      |
| F4  | Speed Up  |
| F5  | Slow Down |

---

## Included Songs

The repository ships with three built-in songs to demonstrate the format:

| Song            | Artist               |
|-----------------|----------------------|
| Für Elise       | Ludwig van Beethoven |
| Ode to Joy      | Ludwig van Beethoven |
| Twinkle Twinkle | Traditional          |

---

## Adding Your Own Songs

Place `.lua` song files inside a folder named `sMidiX` in your executor's workspace. The script will automatically detect and load them at runtime.

Each song file must return a Lua table in the following format:

```lua
return {
    title  = "Song Title",
    artist = "Artist Name",
    events = {
        { type = "note_on",  note = 69, velocity = 75, time = 0.000 },
        { type = "note_off", note = 69, velocity = 0,  time = 0.208 },
        -- ...
    }
}
```

- `note` — MIDI note number (0–127)
- `velocity` — Note velocity (0–127)
- `time` — Duration in seconds before the next event

You can generate these files automatically using **NoteSmith** from any standard `.mid` file.

---

## Supported Languages

The interface is fully translated into 20 languages:

`English` · `Español` · `Português` · `Français` · `Deutsch` · `Italiano` · `日本語` · `한국어` · `中文` · `Русский` · `العربية` · `Polski` · `Türkçe` · `Dansk` · `Tiếng Việt` · `Čeština` · `हिन्दी` · `Ελληνικά` · `Українська` · `Magyar`

Language can be switched at any time from the **Languages** tab in the GUI.

---


## Usage

This script is intended to be executed inside Roblox using a script executor that supports `VirtualInputManager`, `readfile`, `listfiles`, and `loadstring`. Standard Roblox clients cannot run this script on their own.

> Please make sure to ask for permission before using, modifying, or distributing this code.

---

*Copyright (C) 2025 sMidiX*

*LICENSE: GPLv3 applies to all files in this repository.*
