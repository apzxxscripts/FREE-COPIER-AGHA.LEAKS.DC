-- AGHA.LEAKS — ULTIMATE CUSTOM GUI (White Neon Theme)
-- LocalScript — place in StarterPlayerScripts
-- Features:
--  • Center spawn, animated, white/black neon theme
--  • Special MOVE button to drag (mouse + touch)
--  • Freesize (resizable via bottom-right handle) — mobile + PC
--  • Obfuscated local keys + legacy password support + owner bypass
--  • Tools unlocked instantly after correct key/password
--  • Confirmation modal with progress bar + cooldown
--  • No external libs required

-- ================= CONFIG =================
local DISCORD_INVITE = "https://discord.gg/REC6NEWAck"
local OWNER_USERID = 913464555013828629
local MAX_ATTEMPTS = 3
local COPY_COOLDOWN = 8            -- seconds cooldown after copy
local KEY_XOR_SECRET = 0x5A        -- XOR byte for obfuscation
local LEGACY_PASSWORD = "itxmadebyagha_ytx"

-- Plain keys to generate obfuscated store (put keys you give on Discord here)
local PLAIN_KEYS = {
    "AGHA-KEY-001",
    "AGHA-KEY-002",
    "AGHA-KEY-EXAMPLE",
}

-- UI settings
local TITLE_TEXT = "💎 AGHA.LEAKS ACCESS PANEL"
local USE_BLUR = true             -- blur background when GUI open
local INITIAL_WIDTH = 580
local INITIAL_HEIGHT = 380
local MIN_WIDTH = 360
local MIN_HEIGHT = 260
local MAX_WIDTH = 1000
local MAX_HEIGHT = 900

-- Fancy UX toggles
local USE_FANCY_UNLOCK_ANIM = true
local SHOW_OBF_HEX_BUTTON = true   -- owner-only helper to show hex keys

-- ================= LIBS & SERVICES =================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ================= HELPERS =================
local function notify(title, text, dur)
    dur = dur or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = tostring(title), Text = tostring(text), Duration = dur})
    end)
end

local function setClipboardSafe(text)
    pcall(function() setclipboard(text) end)
end

-- XOR obfuscation helpers
local function xorToHex(str, key)
    local out = {}
    for i = 1, #str do
        local b = string.byte(str, i)
        local x = bit32.bxor(b, key)
        out[#out+1] = string.format("%02x", x)
    end
    return table.concat(out)
end

local function hexToXor(hex, key)
    local out = {}
    for i = 1, #hex, 2 do
        local byte = tonumber(hex:sub(i,i+1), 16)
        local orig = bit32.bxor(byte, key)
        out[#out+1] = string.char(orig)
    end
    return table.concat(out)
end

-- Build obfuscated hex list (script will contain these hex strings only)
local OBF_HEX = {}
for _, k in ipairs(PLAIN_KEYS) do
    OBF_HEX[#OBF_HEX+1] = xorToHex(k, KEY_XOR_SECRET)
end

local function isValidKey(input)
    if not input then return false end
    input = tostring(input)
    if input == LEGACY_PASSWORD then return true end
    -- direct match against deobfuscated keys
    for _, hex in ipairs(OBF_HEX) do
        if input == hexToXor(hex, KEY_XOR_SECRET) then return true end
    end
    -- allow hex pasted directly
    for _, hex in ipairs(OBF_HEX) do
        if input:lower() == hex:lower() then return true end
    end
    return false
end

local function isOwner()
    local pl = LocalPlayer
    return pl and pl.UserId == OWNER_USERID
end

-- center position helper
local function centerPosForSize(size)
    return UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
end

-- clamp helper
local function clamp(val, a, b) if val < a then return a end if val > b then return b end return val end

-- ================= BUILD UI =================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- remove existing to avoid duplicates
local old = playerGui:FindFirstChild("AGHA_LEAKS_GUI")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AGHA_LEAKS_GUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true

-- optional blur
local blur = nil
if USE_BLUR then
    blur = Instance.new("BlurEffect")
    blur.Parent = game:GetService("Lighting")
    blur.Size = 0
end

-- main container
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, INITIAL_WIDTH, 0, INITIAL_HEIGHT)
main.Position = centerPosForSize(Vector2.new(INITIAL_WIDTH, INITIAL_HEIGHT))
main.AnchorPoint = Vector2.new(0, 0)
main.BackgroundColor3 = Color3.fromRGB(6,6,6)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(255,255,255)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.88

-- glowing rim (outer)
local rim = Instance.new("ImageLabel", main)
rim.AnchorPoint = Vector2.new(0.5,0.5)
rim.Position = UDim2.new(0.5,0.5,0.5,0)
rim.Size = UDim2.new(1, 60, 1, 60)
rim.Image = "rbxassetid://1316045217"
rim.BackgroundTransparency = 1
rim.ImageColor3 = Color3.fromRGB(255,255,255)
rim.ImageTransparency = 0.9
rim.ScaleType = Enum.ScaleType.Slice
rim.SliceCenter = Rect.new(10,10,118,118)
rim.ZIndex = 0

-- topbar (where title, move button live)
local topbar = Instance.new("Frame", main)
topbar.Name = "Topbar"
topbar.Size = UDim2.new(1, 0, 0, 56)
topbar.Position = UDim2.new(0, 0, 0, 0)
topbar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", topbar)
title.Name = "Title"
title.Size = UDim2.new(1, -180, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Text = TITLE_TEXT
title.TextXAlignment = Enum.TextXAlignment.Left

local miniStatus = Instance.new("TextLabel", topbar)
miniStatus.Name = "MiniStatus"
miniStatus.Size = UDim2.new(0, 160, 0, 24)
miniStatus.Position = UDim2.new(1, -180, 0.5, -12)
miniStatus.BackgroundTransparency = 1
miniStatus.Font = Enum.Font.Gotham
miniStatus.TextSize = 13
miniStatus.TextColor3 = Color3.fromRGB(235,235,235)
miniStatus.Text = "ONLY FOR THE ACCESS PURCHASED GUYS!"
miniStatus.TextXAlignment = Enum.TextXAlignment.Right

-- move button (special drag handle)
local moveBtn = Instance.new("TextButton", topbar)
moveBtn.Name = "MoveBtn"
moveBtn.Size = UDim2.new(0, 110, 0, 34)
moveBtn.Position = UDim2.new(1, -116, 0.5, -17)
moveBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
moveBtn.Text = "MOVE"
moveBtn.Font = Enum.Font.GothamBold
moveBtn.TextSize = 14
moveBtn.TextColor3 = Color3.fromRGB(6,6,6)
moveBtn.AutoButtonColor = false
local moveCorner = Instance.new("UICorner", moveBtn)
moveCorner.CornerRadius = UDim.new(0, 8)
local moveStroke = Instance.new("UIStroke", moveBtn)
moveStroke.Color = Color3.fromRGB(255,255,255)
moveStroke.Thickness = 1
moveStroke.Transparency = 0.9

-- content area
local content = Instance.new("Frame", main)
content.Name = "Content"
content.Position = UDim2.new(0, 18, 0, 64)
content.Size = UDim2.new(1, -36, 1, -82)
content.BackgroundTransparency = 1

-- left tabs column
local tabs = Instance.new("Frame", content)
tabs.Name = "Tabs"
tabs.Size = UDim2.new(0, 160, 1, 0)
tabs.Position = UDim2.new(0, 0, 0, 0)
tabs.BackgroundTransparency = 1

local tabsLayout = Instance.new("UIListLayout", tabs)
tabsLayout.Padding = UDim.new(0, 12)
tabsLayout.FillDirection = Enum.FillDirection.Vertical
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local function tabButton(parent, text)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -6, 0, 46)
    b.BackgroundColor3 = Color3.fromRGB(12,12,12)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.Text = text
    b.TextColor3 = Color3.fromRGB(220,220,220)
    local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0,10)
    local st = Instance.new("UIStroke", b); st.Color = Color3.fromRGB(255,255,255); st.Thickness = 1; st.Transparency = 0.92
    return b
end

local authTabBtn = tabButton(tabs, "Authenticate")
local toolsTabBtn = tabButton(tabs, "Tools")
toolsTabBtn.TextColor3 = Color3.fromRGB(160,160,160)
toolsTabBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)

-- panel area (dynamic)
local panel = Instance.new("Frame", content)
panel.Name = "Panel"
panel.Size = UDim2.new(1, -176, 1, 0)
panel.Position = UDim2.new(0, 172, 0, 0)
panel.BackgroundColor3 = Color3.fromRGB(12,12,12)
panel.BorderSizePixel = 0
local panelCorner = Instance.new("UICorner", panel); panelCorner.CornerRadius = UDim.new(0, 10)
local panelStroke = Instance.new("UIStroke", panel); panelStroke.Color = Color3.fromRGB(255,255,255); panelStroke.Thickness = 1; panelStroke.Transparency = 0.92

-- auth frame
local authFrame = Instance.new("Frame", panel)
authFrame.Size = UDim2.new(1,0,1,0)
authFrame.BackgroundTransparency = 1

local authTitle = Instance.new("TextLabel", authFrame)
authTitle.Size = UDim2.new(1,0,0,28)
authTitle.Position = UDim2.new(0,0,0,0)
authTitle.BackgroundTransparency = 1
authTitle.Font = Enum.Font.GothamBold
authTitle.TextSize = 18
authTitle.Text = "Authenticate"
authTitle.TextColor3 = Color3.fromRGB(255,255,255)
authTitle.TextXAlignment = Enum.TextXAlignment.Left

local authDesc = Instance.new("TextLabel", authFrame)
authDesc.Size = UDim2.new(1,0,0,44)
authDesc.Position = UDim2.new(0,0,0,34)
authDesc.BackgroundTransparency = 1
authDesc.Font = Enum.Font.Gotham
authDesc.TextSize = 14
authDesc.Text = "Get a key from Discord or use the legacy password. Keys are case-sensitive."
authDesc.TextColor3 = Color3.fromRGB(200,200,200)
authDesc.TextXAlignment = Enum.TextXAlignment.Left

local getKeyBtn = Instance.new("TextButton", authFrame)
getKeyBtn.Size = UDim2.new(0, 240, 0, 44)
getKeyBtn.Position = UDim2.new(0, 0, 0, 92)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
getKeyBtn.Font = Enum.Font.GothamBold
getKeyBtn.TextSize = 15
getKeyBtn.Text = "Get Key — Open Discord"
getKeyBtn.TextColor3 = Color3.fromRGB(6,6,6)
local getKeyCorner = Instance.new("UICorner", getKeyBtn); getKeyCorner.CornerRadius = UDim.new(0, 8)
local getKeyStroke = Instance.new("UIStroke", getKeyBtn); getKeyStroke.Color = Color3.fromRGB(230,230,230); getKeyStroke.Thickness = 1

local inputBox = Instance.new("TextBox", authFrame)
inputBox.Size = UDim2.new(1, 0, 0, 44)
inputBox.Position = UDim2.new(0, 0, 0, 156)
inputBox.BackgroundColor3 = Color3.fromRGB(18,18,18)
inputBox.PlaceholderText = "Paste key from Discord or legacy password"
inputBox.ClearTextOnFocus = false
inputBox.Text = ""
inputBox.TextColor3 = Color3.fromRGB(250,250,250)
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 16
local inputCorner = Instance.new("UICorner", inputBox); inputCorner.CornerRadius = UDim.new(0, 8)
local inputStroke = Instance.new("UIStroke", inputBox); inputStroke.Color = Color3.fromRGB(230,230,230); inputStroke.Thickness = 1; inputStroke.Transparency = 0.9

local unlockButton = Instance.new("TextButton", authFrame)
unlockButton.Size = UDim2.new(0, 200, 0, 44)
unlockButton.Position = UDim2.new(0, 0, 0, 208)
unlockButton.BackgroundColor3 = Color3.fromRGB(255,255,255)
unlockButton.Text = "Unlock"
unlockButton.Font = Enum.Font.GothamBold
unlockButton.TextSize = 16
unlockButton.TextColor3 = Color3.fromRGB(6,6,6)
local unlockCorner = Instance.new("UICorner", unlockButton); unlockCorner.CornerRadius = UDim.new(0,8)
local unlockStroke = Instance.new("UIStroke", unlockButton); unlockStroke.Color = Color3.fromRGB(230,230,230); unlockStroke.Thickness = 1

local authStatus = Instance.new("TextLabel", authFrame)
authStatus.Size = UDim2.new(1, 0, 0, 20)
authStatus.Position = UDim2.new(0, 0, 1, -26)
authStatus.BackgroundTransparency = 1
authStatus.Font = Enum.Font.Gotham
authStatus.TextSize = 13
authStatus.TextColor3 = Color3.fromRGB(200,200,200)
authStatus.TextXAlignment = Enum.TextXAlignment.Left
authStatus.Text = "Status: Waiting for input..."

-- tools frame
local toolsFrame = Instance.new("Frame", panel)
toolsFrame.Size = UDim2.new(1,0,1,0)
toolsFrame.BackgroundTransparency = 1
toolsFrame.Visible = false

local toolsTitle = Instance.new("TextLabel", toolsFrame)
toolsTitle.Size = UDim2.new(1,0,0,28)
toolsTitle.Position = UDim2.new(0,0,0,0)
toolsTitle.BackgroundTransparency = 1
toolsTitle.Font = Enum.Font.GothamBold
toolsTitle.TextSize = 18
toolsTitle.Text = "Tools"
toolsTitle.TextColor3 = Color3.fromRGB(255,255,255)
toolsTitle.TextXAlignment = Enum.TextXAlignment.Left

local toolsNote = Instance.new("TextLabel", toolsFrame)
toolsNote.Size = UDim2.new(1,0,0,22)
toolsNote.Position = UDim2.new(0,0,0,36)
toolsNote.BackgroundTransparency = 1
toolsNote.Font = Enum.Font.Gotham
toolsNote.TextSize = 13
toolsNote.Text = "⚠️ ONLY FOR THE ACCESS PURCHASED GUYS!"
toolsNote.TextColor3 = Color3.fromRGB(255,220,220)
toolsNote.TextXAlignment = Enum.TextXAlignment.Left

local copyBtn = Instance.new("TextButton", toolsFrame)
copyBtn.Size = UDim2.new(0, 260, 0, 48)
copyBtn.Position = UDim2.new(0, 0, 0, 70)
copyBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.Text = "📂 Copy Game + Scripts (Confirm)"
copyBtn.TextSize = 16
copyBtn.TextColor3 = Color3.fromRGB(6,6,6)
local copyCorner = Instance.new("UICorner", copyBtn); copyCorner.CornerRadius = UDim.new(0, 10)
local copyStroke = Instance.new("UIStroke", copyBtn); copyStroke.Color = Color3.fromRGB(230,230,230); copyStroke.Thickness = 1

local discordBtn = Instance.new("TextButton", toolsFrame)
discordBtn.Size = UDim2.new(0, 180, 0, 40)
discordBtn.Position = UDim2.new(0, 0, 0, 136)
discordBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
discordBtn.Font = Enum.Font.Gotham
discordBtn.Text = "Open Discord"
discordBtn.TextSize = 14
discordBtn.TextColor3 = Color3.fromRGB(240,240,240)
local discordCorner = Instance.new("UICorner", discordBtn); discordCorner.CornerRadius = UDim.new(0,8)

local closeToolsBtn = Instance.new("TextButton", toolsFrame)
closeToolsBtn.Size = UDim2.new(0, 120, 0, 36)
closeToolsBtn.Position = UDim2.new(0, 0, 1, -46)
closeToolsBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
closeToolsBtn.Font = Enum.Font.Gotham
closeToolsBtn.Text = "Close UI"
closeToolsBtn.TextSize = 14
closeToolsBtn.TextColor3 = Color3.fromRGB(240,240,240)
local closeCorner = Instance.new("UICorner", closeToolsBtn); closeCorner.CornerRadius = UDim.new(0,8)

-- resize handle (bottom-right)
local resizeHandle = Instance.new("Frame", main)
resizeHandle.Name = "Resize"
resizeHandle.Size = UDim2.new(0, 22, 0, 22)
resizeHandle.AnchorPoint = Vector2.new(1,1)
resizeHandle.Position = UDim2.new(1, -8, 1, -8)
resizeHandle.BackgroundColor3 = Color3.fromRGB(255,255,255)
resizeHandle.BackgroundTransparency = 0.95
resizeHandle.BorderSizePixel = 0
local resizeCorner = Instance.new("UICorner", resizeHandle); resizeCorner.CornerRadius = UDim.new(0, 6)

-- modal (progress) overlay
local modal = Instance.new("Frame", screenGui)
modal.Name = "Modal"
modal.Size = UDim2.new(0, 460, 0, 160)
modal.Position = UDim2.new(0.5, -230, 0.5, -80)
modal.AnchorPoint = Vector2.new(0.5,0.5)
modal.BackgroundColor3 = Color3.fromRGB(10,10,10)
modal.BorderSizePixel = 0
modal.Visible = false
local modalCorner = Instance.new("UICorner", modal); modalCorner.CornerRadius = UDim.new(0, 12)
local modalStroke = Instance.new("UIStroke", modal); modalStroke.Color = Color3.fromRGB(255,255,255); modalStroke.Thickness = 1; modalStroke.Transparency = 0.92

local modalTitle = Instance.new("TextLabel", modal)
modalTitle.Size = UDim2.new(1, -28, 0, 28)
modalTitle.Position = UDim2.new(0, 14, 0, 12)
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBold
modalTitle.TextSize = 16
modalTitle.Text = "Progress"
modalTitle.TextColor3 = Color3.fromRGB(255,255,255)

local progressBg = Instance.new("Frame", modal)
progressBg.Size = UDim2.new(1, -28, 0, 28)
progressBg.Position = UDim2.new(0, 14, 0, 56)
progressBg.BackgroundColor3 = Color3.fromRGB(18,18,18)
local progBgCorner = Instance.new("UICorner", progressBg); progBgCorner.CornerRadius = UDim.new(0,8)

local progressFill = Instance.new("Frame", progressBg)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(255,255,255)
local progFillCorner = Instance.new("UICorner", progressFill); progFillCorner.CornerRadius = UDim.new(0,8)

local progText = Instance.new("TextLabel", modal)
progText.Size = UDim2.new(1, -28, 0, 22)
progText.Position = UDim2.new(0, 14, 0, 92)
progText.BackgroundTransparency = 1
progText.Font = Enum.Font.Gotham
progText.Text = "Starting..."
progText.TextColor3 = Color3.fromRGB(220,220,220)
progText.TextSize = 14

-- ================= INTERACTION STATE =================
local attemptCount = 0
local unlockedFlag = false
local copyCooldown = false
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil
local resizing = false
local resizeStart = nil
local startSize = nil

-- ================= DRAGGABLE (MOVE BUTTON) =================
local function beginDrag(input)
    dragging = true
    dragInput = input
    dragStart = input.Position
    startPos = main.Position
end
local function updateDrag(input)
    if not dragging then return end
    local delta = input.Position - dragStart
    local newX = startPos.X.Offset + delta.X
    local newY = startPos.Y.Offset + delta.Y
    main.Position = UDim2.new(0, newX, 0, newY)
end
local function endDrag()
    dragging = false
    dragInput = nil
end

-- mouse + touch for moveBtn
moveBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        beginDrag(input)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then endDrag() end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local cur = input.Position
        local deltaX = cur.X - resizeStart.X
        local deltaY = cur.Y - resizeStart.Y
        local newW = clamp(startSize.X.Offset + deltaX, MIN_WIDTH, MAX_WIDTH)
        local newH = clamp(startSize.Y.Offset + deltaY, MIN_HEIGHT, MAX_HEIGHT)
        main.Size = UDim2.new(0, newW, 0, newH)
        -- recenter based on new size so it doesn't jump offscreen
        main.Position = centerPosForSize(Vector2.new(newW, newH))
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if dragging and input == dragInput then endDrag() end
    if resizing and input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = false
    end
end)

-- resize handle input
resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        startSize = Vector2.new(main.AbsoluteSize.X, main.AbsoluteSize.Y)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then resizing = false end
        end)
    end
end)

-- ================= TAB SWITCHING =================
authTabBtn.MouseButton1Click:Connect(function()
    authFrame.Visible = true
    toolsFrame.Visible = false
    authTabBtn.BackgroundColor3 = Color3.fromRGB(12,12,12)
    toolsTabBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
    toolsTabBtn.TextColor3 = Color3.fromRGB(160,160,160)
end)
toolsTabBtn.MouseButton1Click:Connect(function()
    if not unlockedFlag then
        notify("Locked", "Unlock first to access Tools.", 3)
        return
    end
    authFrame.Visible = false
    toolsFrame.Visible = true
    authTabBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
    toolsTabBtn.BackgroundColor3 = Color3.fromRGB(12,12,12)
    toolsTabBtn.TextColor3 = Color3.fromRGB(255,255,255)
end)

-- ================= CLOSE HANDLERS =================
local function closeGui()
    if USE_BLUR and blur then
        TweenService:Create(blur, TweenInfo.new(0.28), {Size = 0}):Play()
    end
    TweenService:Create(main, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
    task.delay(0.22, function() pcall(function() screenGui:Destroy() end) end)
end
topbar:GetPropertyChangedSignal("AbsolutePosition"):Connect(function() end) -- noop to keep binding sane
-- close buttons
moveBtn.MouseButton2Click:Connect(closeGui) -- right-click on move to close (pc)
closeToolsBtn.MouseButton1Click:Connect(closeGui)
-- top-right X
local xBtn = Instance.new("TextButton", topbar)
xBtn.Size = UDim2.new(0, 28, 0, 28)
xBtn.Position = UDim2.new(1, -44, 0.5, -14)
xBtn.BackgroundTransparency = 1
xBtn.Font = Enum.Font.GothamBold
xBtn.Text = "✕"
xBtn.TextSize = 18
xBtn.TextColor3 = Color3.fromRGB(220,220,220)
xBtn.MouseButton1Click:Connect(closeGui)

-- ================= AUTH FLOW =================
getKeyBtn.MouseButton1Click:Connect(function()
    setClipboardSafe(DISCORD_INVITE)
    notify("Discord", "Invite copied to clipboard. Open to get your key.", 4)
    pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
end)

local function revealTools()
    unlockedFlag = true
    authFrame.Visible = false
    toolsFrame.Visible = true
    authStatus.Text = "Status: Unlocked"
    miniStatus.Text = "Unlocked"
    notify("Access Granted", "Welcome — Tools unlocked.", 3)
    -- owner fancy unlock
    if USE_FANCY_UNLOCK_ANIM then
        local pulse = Instance.new("UIStroke", main)
        pulse.Color = Color3.fromRGB(255,255,255)
        pulse.Thickness = 3
        pulse.Transparency = 0.9
        task.spawn(function()
            for i = 1, 4 do
                TweenService:Create(pulse, TweenInfo.new(0.16), {Transparency = 1}):Play()
                task.wait(0.16)
                TweenService:Create(pulse, TweenInfo.new(0.18), {Transparency = 0.3}):Play()
                task.wait(0.18)
            end
            pcall(function() pulse:Destroy() end)
        end)
    end
end

unlockButton.MouseButton1Click:Connect(function()
    if unlockedFlag then return end
    local entry = tostring(inputBox.Text or ""):gsub("^%s*(.-)%s*$", "%1")
    if isOwner() then
        revealTools()
        return
    end
    if entry == "" then
        notify("Empty", "Enter a key or legacy password first.", 2.5)
        return
    end
    if isValidKey(entry) then
        revealTools()
        return
    else
        attemptCount = attemptCount + 1
        authStatus.Text = "Status: Wrong key ("..attemptCount.."/"..MAX_ATTEMPTS..")"
        notify("Wrong Key", "Attempt "..attemptCount.."/"..MAX_ATTEMPTS, 2.2)
        if attemptCount >= MAX_ATTEMPTS then
            notify("Locked", "Too many failed attempts. UI will close.", 3)
            task.wait(1.1)
            pcall(function() screenGui:Destroy() end)
        end
    end
end)

-- owner-only show obfuscated hex
if SHOW_OBF_HEX_BUTTON then
    local showHexBtn = Instance.new("TextButton", authFrame)
    showHexBtn.Size = UDim2.new(0, 220, 0, 36)
    showHexBtn.Position = UDim2.new(0, 0, 0, 256)
    showHexBtn.Text = "Owner: Show Obf Keys"
    showHexBtn.Font = Enum.Font.Gotham
    showHexBtn.TextSize = 13
    showHexBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
    showHexBtn.TextColor3 = Color3.fromRGB(240,240,240)
    local sc = Instance.new("UICorner", showHexBtn); sc.CornerRadius = UDim.new(0, 8)
    showHexBtn.MouseButton1Click:Connect(function()
        if not isOwner() then
            notify("Denied", "Owner only.", 2)
            return
        end
        local lines = {}
        for i, h in ipairs(OBF_HEX) do lines[#lines+1] = ("Key %d (hex): %s"):format(i, h) end
        notify("Obfuscated Keys", table.concat(lines," | "), math.min(6,#lines*0.6 + 1))
    end)
end

-- ================= CONFIRM + PROGRESS + COPY =================
local function performCopy()
    if copyCooldown then
        notify("Cooldown", "Wait before copying again.", 2)
        return
    end
    copyCooldown = true
    -- actual save routine
    local ok, err = pcall(function()
        local saveinstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/SynSaveInstance/main/saveinstance.luau"))()
        saveinstance({
            FileName = "AGHA_LEAKS_COPY_" .. tostring(game.PlaceId) .. ".rbxlx",
            Decompile = true,
            IncludeScripts = true,
            CreatorTag = "AGHA.LEAKS"
        })
    end)
    if ok then
        notify("Success", "Copy completed.", 4)
    else
        notify("Error", tostring(err), 6)
    end
    -- cooldown ticker (non-blocking)
    task.spawn(function()
        local rem = COPY_COOLDOWN
        while rem > 0 do
            notify("Cooldown", "Next copy in "..tostring(rem).."s", 1)
            rem = rem - 1
            task.wait(1)
        end
        copyCooldown = false
    end)
end

local function showConfirmModal()
    modal.Visible = true
    progressFill.Size = UDim2.new(0,0,1,0)
    progText.Text = "Ready..."
    modalTitle.Text = "Confirm Copy"
    -- create buttons if missing
    for _, c in ipairs(modal:GetChildren()) do if c.Name == "ConfirmButtons" then c:Destroy() end end
    local btnFrame = Instance.new("Frame", modal); btnFrame.Name = "ConfirmButtons"; btnFrame.Size = UDim2.new(1, -28, 0, 44); btnFrame.Position = UDim2.new(0, 14, 1, -56); btnFrame.BackgroundTransparency = 1
    local yes = Instance.new("TextButton", btnFrame); yes.Size = UDim2.new(0, 180, 1, 0); yes.Position = UDim2.new(0,0,0,0); yes.Text = "Confirm — Proceed"; yes.Font = Enum.Font.GothamBold; yes.TextSize = 14; yes.BackgroundColor3 = Color3.fromRGB(255,255,255); yes.TextColor3 = Color3.fromRGB(6,6,6); local yc = Instance.new("UICorner", yes); yc.CornerRadius = UDim.new(0,8)
    local cancel = Instance.new("TextButton", btnFrame); cancel.Size = UDim2.new(0, 120, 1, 0); cancel.Position = UDim2.new(0, 200, 0, 0); cancel.Text = "Cancel"; cancel.Font = Enum.Font.Gotham; cancel.TextSize = 14; cancel.BackgroundColor3 = Color3.fromRGB(18,18,18); cancel.TextColor3 = Color3.fromRGB(240,240,240); local cc = Instance.new("UICorner", cancel); cc.CornerRadius = UDim.new(0,8)

    local started = false
    cancel.MouseButton1Click:Connect(function()
        if started then return end
        modal.Visible = false
        btnFrame:Destroy()
        notify("Cancelled", "Action cancelled.", 2)
    end)
    yes.MouseButton1Click:Connect(function()
        if started then return end
        started = true
        btnFrame:Destroy()
        progText.Text = "Running..."
        -- simulate progress then call performCopy
        task.spawn(function()
            local progress = 0
            while progress < 0.92 do
                progress = math.min(0.92, progress + (0.12 + math.random()*0.12))
                TweenService:Create(progressFill, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {Size = UDim2.new(progress,0,1,0)}):Play()
                task.wait(0.45)
            end
            -- actually perform the copy
            local ok, err = pcall(performCopy)
            if ok then
                TweenService:Create(progressFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Size = UDim2.new(1,0,1,0)}):Play()
                progText.Text = "Completed."
            else
                progText.Text = "Error: "..tostring(err)
            end
            task.wait(1.2)
            modal.Visible = false
            progressFill.Size = UDim2.new(0,0,1,0)
        end)
    end)
end

copyBtn.MouseButton1Click:Connect(function()
    if not unlockedFlag then
        notify("Locked", "Unlock first with a valid key/password.", 2.5)
        return
    end
    showConfirmModal()
end)

discordBtn.MouseButton1Click:Connect(function()
    setClipboardSafe(DISCORD_INVITE)
    notify("Discord", "Invite copied to clipboard.", 3)
    pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
end)

-- initial animation / blur effect
main.BackgroundTransparency = 1
main.Position = centerPosForSize(Vector2.new(INITIAL_WIDTH, INITIAL_HEIGHT))
TweenService:Create(main, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
if USE_BLUR and blur then
    TweenService:Create(blur, TweenInfo.new(0.5), {Size = 8}):Play()
end

-- initial tab focus
authFrame.Visible = true
toolsFrame.Visible = false
toolsTabBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
authTabBtn.BackgroundColor3 = Color3.fromRGB(12,12,12)

-- bind P to toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

-- final console reminder (custom phrasing)
pcall(function()
    print("AGHA.LEAKS — remember: ONLY FOR THE ACCESS PURCHASED GUYS!")
end)
