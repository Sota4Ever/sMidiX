-- ═══════════════════════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local GuiService       = game:GetService("GuiService")

local __RT = getgenv().__sMidiX_runtime
local VIM  = __RT and __RT.send or nil

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════════════════
-- DETECT PLATFORM
-- ═══════════════════════════════════════════════════════════════════════════

local function detectMobile()
    if not UserInputService.TouchEnabled then return false end
    local platform = UserInputService:GetPlatform()
    if platform == Enum.Platform.Android or platform == Enum.Platform.IOS then
        return true
    end
    local lastInput = UserInputService:GetLastInputType()
    if lastInput == Enum.UserInputType.Touch then return true end
    return not UserInputService.KeyboardEnabled
end

local IS_MOBILE = detectMobile()

local SONGS_FOLDER = "sMidiX"
