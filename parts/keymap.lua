-- ═══════════════════════════════════════════════════════════════════════════
-- KEYMAP
-- ═══════════════════════════════════════════════════════════════════════════
local KeyMap = {}

KeyMap.keyMap61 = {
    [36]="1",  [37]="!",  [38]="2",  [39]="@",  [40]="3",
    [41]="4",  [42]="$",  [43]="5",  [44]="%",  [45]="6",
    [46]="^",  [47]="7",  [48]="8",  [49]="*",  [50]="9",
    [51]="(",  [52]="0",  [53]="q",  [54]="Q",  [55]="w",
    [56]="W",  [57]="e",  [58]="E",  [59]="r",  [60]="t",
    [61]="T",  [62]="y",  [63]="Y",  [64]="u",  [65]="i",
    [66]="I",  [67]="o",  [68]="O",  [69]="p",  [70]="P",
    [71]="a",  [72]="s",  [73]="S",  [74]="d",  [75]="D",
    [76]="f",  [77]="g",  [78]="G",  [79]="h",  [80]="H",
    [81]="j",  [82]="J",  [83]="k",  [84]="l",  [85]="L",
    [86]="z",  [87]="Z",  [88]="x",  [89]="c",  [90]="C",
    [91]="v",  [92]="V",  [93]="b",  [94]="B",  [95]="n",
    [96]="m",
}
KeyMap.keyMapLow = {
    [21]="1",[22]="2",[23]="3",[24]="4",[25]="5",
    [26]="6",[27]="7",[28]="8",[29]="9",[30]="0",
    [31]="q",[32]="w",[33]="e",[34]="r",[35]="t",
}
KeyMap.keyMapHigh = {
    [97]="y", [98]="u", [99]="i",[100]="o",[101]="p",
    [102]="a",[103]="s",[104]="d",[105]="f",[106]="g",
    [107]="h",[108]="j",
}

KeyMap.velocityChars = {
    [0]="1",  [4]="2",  [8]="3",  [12]="4", [16]="5", [20]="6",
    [24]="7", [28]="8", [32]="9", [36]="0", [40]="q", [44]="w",
    [48]="e", [52]="r", [56]="t", [60]="y", [64]="u", [68]="i",
    [72]="o", [76]="p", [80]="a", [84]="s", [88]="d", [92]="f",
    [96]="g",[100]="h",[104]="j",[108]="k",[112]="l",[116]="z",
    [120]="x",[124]="c",
}
KeyMap.CHAR_TO_KEYCODE = {
    ["0"]=Enum.KeyCode.Zero,  ["1"]=Enum.KeyCode.One,   ["2"]=Enum.KeyCode.Two,
    ["3"]=Enum.KeyCode.Three, ["4"]=Enum.KeyCode.Four,  ["5"]=Enum.KeyCode.Five,
    ["6"]=Enum.KeyCode.Six,   ["7"]=Enum.KeyCode.Seven, ["8"]=Enum.KeyCode.Eight,
    ["9"]=Enum.KeyCode.Nine,
    ["a"]=Enum.KeyCode.A,["b"]=Enum.KeyCode.B,["c"]=Enum.KeyCode.C,
    ["d"]=Enum.KeyCode.D,["e"]=Enum.KeyCode.E,["f"]=Enum.KeyCode.F,
    ["g"]=Enum.KeyCode.G,["h"]=Enum.KeyCode.H,["i"]=Enum.KeyCode.I,
    ["j"]=Enum.KeyCode.J,["k"]=Enum.KeyCode.K,["l"]=Enum.KeyCode.L,
    ["m"]=Enum.KeyCode.M,["n"]=Enum.KeyCode.N,["o"]=Enum.KeyCode.O,
    ["p"]=Enum.KeyCode.P,["q"]=Enum.KeyCode.Q,["r"]=Enum.KeyCode.R,
    ["s"]=Enum.KeyCode.S,["t"]=Enum.KeyCode.T,["u"]=Enum.KeyCode.U,
    ["v"]=Enum.KeyCode.V,["w"]=Enum.KeyCode.W,["x"]=Enum.KeyCode.X,
    ["y"]=Enum.KeyCode.Y,["z"]=Enum.KeyCode.Z,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SPECIAL KEYS
-- Maps friendly string names → Roblox Enum.KeyCode, used by log_keyboard.lua
-- so modifier keys are never hardcoded in multiple places.
-- ═══════════════════════════════════════════════════════════════════════════
KeyMap.SPECIAL_KEYS = {
    shift = Enum.KeyCode.LeftShift,
    ctrl  = Enum.KeyCode.LeftControl,
    alt   = Enum.KeyCode.LeftAlt,
    space = Enum.KeyCode.Space,
}

function KeyMap.isSharpChar(k)
    return k=="!" or k=="@" or k=="$" or k=="%" or k=="^" or k=="*" or k=="("
end
function KeyMap.isUpperChar(k)
    if KeyMap.isSharpChar(k) then return false end
    return k:lower() ~= k and #k == 1
end
function KeyMap.charToKeyCode(c)
    return KeyMap.CHAR_TO_KEYCODE[c:lower()]
end
function KeyMap.findVelocityKey(velocity)
    -- Thresholds are uniform steps of 4 (0,4,8,...,124): compute bucket directly O(1)
    local threshold = math.min(math.floor(velocity / 4) * 4, 124)
    return KeyMap.velocityChars[threshold]
end

