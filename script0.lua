-- AGHA.LEAKS — ULTIMATE ROUNDED GUI (White Neon) — LocalScript
-- Place as a LocalScript in StarterPlayerScripts
-- WARNING: Includes automated copy helper. ONLY FOR THE ACCESS PURCHASED GUYS!

-- ================= CONFIG =================
local DISCORD_INVITE = "https://discord.gg/REC6NEWAck"
local OWNER_USERID = 913464555013828629
local MAX_ATTEMPTS = 3
local COPY_COOLDOWN = 8            -- seconds between copies
local KEY_XOR_SECRET = 0x5A        -- xor obfuscation key
local LEGACY_PASSWORD = "itxmadebyagha_ytx"

-- local keys you hand out (these will be obfuscated automatically)
local PLAIN_KEYS = {
    "AGHA-KEY-001",
    "AGHA-KEY-002",
    "AGHA-KEY-EXAMPLE"
}

local TITLE_TEXT = "💎 AGHA.LEAKS ACCESS PANEL"
local USE_BLUR = true              -- cinematic blur behind GUI
local MIN_SCALE_W, MIN_SCALE_H = 0.42, 0.42 -- smallest on tiny screens
local MAX_SCALE_W, MAX_SCALE_H = 0.95, 0.9  -- largest on huge screens

-- ================= SERVICES =================
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
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = dur})
    end)
end
local function safeClipboard(text) pcall(function() setclipboard(text) end) end

local function xorToHex(str, key)
    local t = {}
    for i=1,#str do t[#t+1] = string.format("%02x", bit32.bxor(string.byte(str,i), key)) end
    return table.concat(t)
end
local function hexToXor(hex, key)
    local t = {}
    for i = 1, #hex, 2 do
        local b = tonumber(hex:sub(i,i+1), 16)
        t[#t+1] = string.char(bit32.bxor(b, key))
    end
    return table.concat(t)
end

-- build obfuscated hex table
local OBF_HEX = {}
for _,k in ipairs(PLAIN_KEYS) do OBF_HEX[#OBF_HEX+1] = xorToHex(k, KEY_XOR_SECRET) end

local function isValidKey(input)
    if not input then return false end
    input = tostring(input)
    if input == LEGACY_PASSWORD then return true end
    for _,hex in ipairs(OBF_HEX) do
        if input == hexToXor(hex, KEY_XOR_SECRET) then return true end
        if input:lower() == hex:lower() then return true end
    end
    return false
end

local function isOwner() local pl = LocalPlayer return pl and pl.UserId == OWNER_USERID end

-- center/alignment helper using scale so responsive
local function computeScale()
    local sx = math.clamp(0.72, MIN_SCALE_W, MAX_SCALE_W)
    local sy = math.clamp(0.58, MIN_SCALE_H, MAX_SCALE_H)
    -- We can tweak per-device, but static scale works across devices; UI uses Scale values.
    return sx, sy
end

-- ================= CLEANUP OLD GUI =================
local existing = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("AGHA_LEAKS_GUI")
if existing then existing:Destroy() end

-- ================= BUILD UI =================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AGHA_LEAKS_GUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true

-- optional blur via Lighting (safe, removed on close)
local blurEffect
if USE_BLUR and game:GetService("Lighting") then
    blurEffect = Instance.new("BlurEffect", game:GetService("Lighting"))
    blurEffect.Size = 0
end

-- responsive main frame using Scale values
local sx, sy = computeScale()
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(sx, 0, sy, 0)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = Color3.fromRGB(10,10,10)
main.BorderSizePixel = 0
main.Parent = screenGui

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(255,255,255)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.9

-- rim glow image (subtle)
local rim = Instance.new("ImageLabel", main)
rim.AnchorPoint = Vector2.new(0.5,0.5)
rim.Position = UDim2.new(0.5, 0, 0.5, 0)
rim.Size = UDim2.new(1, 80, 1, 80)
rim.Image = "rbxassetid://1316045217"
rim.BackgroundTransparency = 1
rim.ImageColor3 = Color3.fromRGB(255,255,255)
rim.ImageTransparency = 0.95
rim.ScaleType = Enum.ScaleType.Slice
rim.SliceCenter = Rect.new(10,10,118,118)
rim.ZIndex = 0

-- TOPBAR (move area)
local topbar = Instance.new("Frame", main)
topbar.Name = "Topbar"
topbar.Size = UDim2.new(1, 0, 0, 56)
topbar.Position = UDim2.new(0, 0, 0, 0)
topbar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", topbar)
title.Name = "Title"
title.Size = UDim2.new(1, -160, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.Text = TITLE_TEXT
title.TextXAlignment = Enum.TextXAlignment.Left

local sub = Instance.new("TextLabel", topbar)
sub.Name = "Sub"
sub.Size = UDim2.new(0, 220, 0, 22)
sub.Position = UDim2.new(1, -236, 0.5, -11)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Gotham
sub.TextSize = 13
sub.TextColor3 = Color3.fromRGB(220,220,220)
sub.Text = "ONLY FOR THE ACCESS PURCHASED GUYS!"
sub.TextXAlignment = Enum.TextXAlignment.Right

local moveBar = Instance.new("Frame", topbar)
moveBar.Name = "MoveBar"
moveBar.Size = UDim2.new(0, 120, 0, 34)
moveBar.AnchorPoint = Vector2.new(1,0.5)
moveBar.Position = UDim2.new(1, -12, 0.5, 0)
moveBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
moveBar.BorderSizePixel = 0
local moveCorner = Instance.new("UICorner", moveBar)
moveCorner.CornerRadius = UDim.new(0, 8)

local moveLabel = Instance.new("TextLabel", moveBar)
moveLabel.Size = UDim2.new(1, -6, 1, 0)
moveLabel.Position = UDim2.new(0, 6, 0, 0)
moveLabel.BackgroundTransparency = 1
moveLabel.Font = Enum.Font.GothamSemibold
moveLabel.TextSize = 13
moveLabel.Text = "MOVE"
moveLabel.TextColor3 = Color3.fromRGB(6,6,6)
moveLabel.TextXAlignment = Enum.TextXAlignment.Left

-- CONTENT wrapper
local content = Instance.new("Frame", main)
content.Name = "Content"
content.Position = UDim2.new(0, 18, 0, 70)
content.Size = UDim2.new(1, -36, 1, -86)
content.BackgroundTransparency = 1

-- TABS (left)
local tabs = Instance.new("Frame", content)
tabs.Name = "Tabs"
tabs.Size = UDim2.new(0, 160, 1, 0)
tabs.BackgroundTransparency = 1

local tabsLayout = Instance.new("UIListLayout", tabs)
tabsLayout.FillDirection = Enum.FillDirection.Vertical
tabsLayout.Padding = UDim.new(0, 12)
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function makeTabBtn(parent, text)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -6, 0, 46)
    b.BackgroundColor3 = Color3.fromRGB(18,18,18)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.Text = text
    b.TextColor3 = Color3.fromRGB(245,245,245)
    local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0,10)
    local st = Instance.new("UIStroke", b); st.Color = Color3.fromRGB(255,255,255); st.Thickness = 1; st.Transparency = 0.9
    return b
end

local authBtn = makeTabBtn(tabs, "Authenticate")
local toolsBtn = makeTabBtn(tabs, "Tools")
toolsBtn.BackgroundColor3 = Color3.fromRGB(14,14,14)
toolsBtn.TextColor3 = Color3.fromRGB(160,160,160)

-- PANEL
local panel = Instance.new("Frame", content)
panel.Name = "Panel"
panel.Position = UDim2.new(0, 172, 0, 0)
panel.Size = UDim2.new(1, -176, 1, 0)
panel.BackgroundColor3 = Color3.fromRGB(12,12,12)
local panelCorner = Instance.new("UICorner", panel); panelCorner.CornerRadius = UDim.new(0, 10)
local panelStroke = Instance.new("UIStroke", panel); panelStroke.Color = Color3.fromRGB(255,255,255); panelStroke.Thickness = 1; panelStroke.Transparency = 0.9

-- AUTH FRAME
local authFrame = Instance.new("Frame", panel)
authFrame.Size = UDim2.new(1,0,1,0)
authFrame.BackgroundTransparency = 1

local authTitle = Instance.new("TextLabel", authFrame)
authTitle.Size = UDim2.new(1,0,0,28)
authTitle.BackgroundTransparency = 1
authTitle.Font = Enum.Font.GothamBold
authTitle.TextSize = 18
authTitle.Text = "Authenticate"
authTitle.TextColor3 = Color3.fromRGB(255,255,255)
authTitle.TextXAlignment = Enum.TextXAlignment.Left

local authDesc = Instance.new("TextLabel", authFrame)
authDesc.Position = UDim2.new(0,0,0,34)
authDesc.Size = UDim2.new(1,0,0,38)
authDesc.BackgroundTransparency = 1
authDesc.Font = Enum.Font.Gotham
authDesc.TextSize = 14
authDesc.Text = "Get a key from Discord or use the legacy password."
authDesc.TextColor3 = Color3.fromRGB(200,200,200)
authDesc.TextXAlignment = Enum.TextXAlignment.Left

local getKey = Instance.new("TextButton", authFrame)
getKey.Size = UDim2.new(0, 240, 0, 44)
getKey.Position = UDim2.new(0, 0, 0, 86)
getKey.BackgroundColor3 = Color3.fromRGB(255,255,255)
getKey.Font = Enum.Font.GothamBold
getKey.TextSize = 15
getKey.Text = "Get Key — Open Discord"
getKey.TextColor3 = Color3.fromRGB(6,6,6)
local getKeyCorner = Instance.new("UICorner", getKey); getKeyCorner.CornerRadius = UDim.new(0,8)

local inputBox = Instance.new("TextBox", authFrame)
inputBox.Size = UDim2.new(1, 0, 0, 44)
inputBox.Position = UDim2.new(0, 0, 0, 146)
inputBox.BackgroundColor3 = Color3.fromRGB(18,18,18)
inputBox.PlaceholderText = "Paste key or legacy password"
inputBox.Text = ""
inputBox.TextColor3 = Color3.new(1,1,1)
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 16
local inputCorner = Instance.new("UICorner", inputBox); inputCorner.CornerRadius = UDim.new(0,8)

local unlockBtn = Instance.new("TextButton", authFrame)
unlockBtn.Size = UDim2.new(0, 200, 0, 44)
unlockBtn.Position = UDim2.new(0, 0, 0, 208)
unlockBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
unlockBtn.Text = "Unlock"
unlockBtn.Font = Enum.Font.GothamBold
unlockBtn.TextSize = 16
unlockBtn.TextColor3 = Color3.fromRGB(6,6,6)
local unlockCorner = Instance.new("UICorner", unlockBtn); unlockCorner.CornerRadius = UDim.new(0,8)

local authStatus = Instance.new("TextLabel", authFrame)
authStatus.Size = UDim2.new(1, 0, 0, 20)
authStatus.Position = UDim2.new(0, 0, 1, -26)
authStatus.BackgroundTransparency = 1
authStatus.Font = Enum.Font.Gotham
authStatus.TextSize = 13
authStatus.TextColor3 = Color3.fromRGB(200,200,200)
authStatus.Text = "Status: Waiting..."

-- TOOLS FRAME
local toolsFrame = Instance.new("Frame", panel)
toolsFrame.Size = UDim2.new(1,0,1,0)
toolsFrame.BackgroundTransparency = 1
toolsFrame.Visible = false

local toolsTitle = Instance.new("TextLabel", toolsFrame)
toolsTitle.Size = UDim2.new(1,0,0,28)
toolsTitle.BackgroundTransparency = 1
toolsTitle.Font = Enum.Font.GothamBold
toolsTitle.TextSize = 18
toolsTitle.Text = "Tools"
toolsTitle.TextColor3 = Color3.fromRGB(255,255,255)
toolsTitle.TextXAlignment = Enum.TextXAlignment.Left

local toolsNote = Instance.new("TextLabel", toolsFrame)
toolsNote.Position = UDim2.new(0,0,0,34)
toolsNote.Size = UDim2.new(1,0,0,24)
toolsNote.BackgroundTransparency = 1
toolsNote.Font = Enum.Font.Gotham
toolsNote.TextSize = 13
toolsNote.Text = "⚠️ ONLY FOR THE ACCESS PURCHASED GUYS!"
toolsNote.TextColor3 = Color3.fromRGB(255,220,220)

local copyBtn = Instance.new("TextButton", toolsFrame)
copyBtn.Size = UDim2.new(0, 260, 0, 48)
copyBtn.Position = UDim2.new(0, 0, 0, 72)
copyBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.Text = "📂 Copy Game + Scripts (Confirm)"
copyBtn.TextSize = 16
copyBtn.TextColor3 = Color3.fromRGB(6,6,6)
local copyCorner = Instance.new("UICorner", copyBtn); copyCorner.CornerRadius = UDim.new(0,10)

local openDisc = Instance.new("TextButton", toolsFrame)
openDisc.Size = UDim2.new(0, 180, 0, 40)
openDisc.Position = UDim2.new(0, 0, 0, 136)
openDisc.BackgroundColor3 = Color3.fromRGB(18,18,18)
openDisc.Font = Enum.Font.Gotham
openDisc.Text = "Open Discord"
openDisc.TextSize = 14
openDisc.TextColor3 = Color3.fromRGB(240,240,240)
local openDiscCorner = Instance.new("UICorner", openDisc); openDiscCorner.CornerRadius = UDim.new(0,8)

local closeBtn = Instance.new("TextButton", toolsFrame)
closeBtn.Size = UDim2.new(0, 120, 0, 36)
closeBtn.Position = UDim2.new(0, 0, 1, -46)
closeBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
closeBtn.Font = Enum.Font.Gotham
closeBtn.Text = "Close UI"
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(240,240,240)
local closeCorner = Instance.new("UICorner", closeBtn); closeCorner.CornerRadius = UDim.new(0,8)

-- RESIZE HANDLE (small)
local resize = Instance.new("Frame", main)
resize.Size = UDim2.new(0, 20, 0, 20)
resize.AnchorPoint = Vector2.new(1,1)
resize.Position = UDim2.new(1, -8, 1, -8)
resize.BackgroundTransparency = 0.9
local resizeCorner = Instance.new("UICorner", resize); resizeCorner.CornerRadius = UDim.new(0,6)

-- MODAL (progress)
local modal = Instance.new("Frame", screenGui)
modal.Name = "Modal"
modal.Size = UDim2.new(0, 460, 0, 160)
modal.AnchorPoint = Vector2.new(0.5,0.5)
modal.Position = UDim2.new(0.5, 0, 0.5, 0)
modal.BackgroundColor3 = Color3.fromRGB(8,8,8)
modal.BorderSizePixel = 0
modal.Visible = false
local modalCorner = Instance.new("UICorner", modal); modalCorner.CornerRadius = UDim.new(0, 12)
local modalStroke = Instance.new("UIStroke", modal); modalStroke.Color = Color3.fromRGB(255,255,255); modalStroke.Thickness = 1; modalStroke.Transparency = 0.9

local modalTitle = Instance.new("TextLabel", modal)
modalTitle.Size = UDim2.new(1, -28, 0, 28)
modalTitle.Position = UDim2.new(0, 14, 0, 12)
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBold
modalTitle.TextSize = 16
modalTitle.Text = "Progress"
modalTitle.TextColor3 = Color3.fromRGB(255,255,255)

local progBg = Instance.new("Frame", modal)
progBg.Size = UDim2.new(1, -28, 0, 28)
progBg.Position = UDim2.new(0, 14, 0, 56)
progBg.BackgroundColor3 = Color3.fromRGB(18,18,18)
local progBgCorner = Instance.new("UICorner", progBg); progBgCorner.CornerRadius = UDim.new(0,8)

local progFill = Instance.new("Frame", progBg)
progFill.Size = UDim2.new(0,0,1,0)
progFill.BackgroundColor3 = Color3.fromRGB(255,255,255)
local progFillCorner = Instance.new("UICorner", progFill); progFillCorner.CornerRadius = UDim.new(0,8)

local progText = Instance.new("TextLabel", modal)
progText.Size = UDim2.new(1, -28, 0, 22)
progText.Position = UDim2.new(0, 14, 0, 92)
progText.BackgroundTransparency = 1
progText.Font = Enum.Font.Gotham
progText.Text = "Ready..."
progText.TextColor3 = Color3.fromRGB(220,220,220)

-- ================= INTERACTION STATE =================
local attemptCount = 0
local unlockedFlag = false
local copyCooldown = false
local dragging = false
local dragStart = nil
local startPos = nil
local resizing = false
local resizeStart = nil
local startSize = nil

-- ================ DRAG (MOVE BAR) ================
local function startDrag(input)
    dragging = true
    dragStart = input.Position
    startPos = main.Position
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then dragging = false end
    end)
end
local function updateDrag(input)
    if not dragging then return end
    local delta = input.Position - dragStart
    local newX = startPos.X.Offset + delta.X
    local newY = startPos.Y.Offset + delta.Y
    main.Position = UDim2.new(0, newX, 0, newY)
end

moveBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        startDrag(input)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local cur = input.Position
        local dx = cur.X - resizeStart.X
        local dy = cur.Y - resizeStart.Y
        local newW = math.clamp(startSize.X.Offset + dx, 360, 1000)
        local newH = math.clamp(startSize.Y.Offset + dy, 260, 900)
        main.Size = UDim2.new(0, newW, 0, newH)
        main.Position = UDim2.new(0.5, -newW/2, 0.5, -newH/2)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if dragging and input.UserInputState == Enum.UserInputState.End then dragging = false end
    if resizing and input.UserInputState == Enum.UserInputState.End then resizing = false end
end)

resize.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        startSize = Vector2.new(main.AbsoluteSize.X, main.AbsoluteSize.Y)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then resizing = false end
        end)
    end
end)

-- ================ TAB SWITCH ================
authBtn.MouseButton1Click:Connect(function()
    authFrame.Visible = true
    toolsFrame.Visible = false
    authBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
    toolsBtn.BackgroundColor3 = Color3.fromRGB(14,14,14)
    toolsBtn.TextColor3 = Color3.fromRGB(160,160,160)
end)
toolsBtn.MouseButton1Click:Connect(function()
    if not unlockedFlag then notify("Locked","Unlock first.",2) return end
    authFrame.Visible = false
    toolsFrame.Visible = true
    toolsBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
    authBtn.BackgroundColor3 = Color3.fromRGB(14,14,14)
    toolsBtn.TextColor3 = Color3.fromRGB(255,255,255)
end)

-- ================ CLOSE UI ================
local function closeUI()
    if blurEffect then
        pcall(function() TweenService:Create(blurEffect, TweenInfo.new(0.28), {Size = 0}):Play() end)
    end
    pcall(function() screenGui:Destroy() end)
end

closeBtn.MouseButton1Click:Connect(closeUI)
-- also top-right small X
local xBtn = Instance.new("TextButton", topbar)
xBtn.Size = UDim2.new(0, 28, 0, 28)
xBtn.Position = UDim2.new(1, -44, 0.5, -14)
xBtn.BackgroundTransparency = 1
xBtn.Font = Enum.Font.GothamBold
xBtn.Text = "✕"
xBtn.TextSize = 18
xBtn.TextColor3 = Color3.fromRGB(220,220,220)
xBtn.MouseButton1Click:Connect(closeUI)

-- ================ AUTH FLOW ================
getKey.MouseButton1Click:Connect(function()
    safeClipboard(DISCORD_INVITE)
    notify("Discord", "Invite copied to clipboard. Open it to get your key.", 4)
    pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
end)

local function revealTools()
    unlockedFlag = true
    authFrame.Visible = false
    toolsFrame.Visible = true
    authStatus.Text = "Status: Unlocked"
    sub.Text = "Unlocked"
    notify("Access Granted", "Tools unlocked.", 3)
    -- small pulse
    local pulse = Instance.new("UIStroke", main)
    pulse.Color = Color3.fromRGB(255,255,255)
    pulse.Thickness = 3
    pulse.Transparency = 0.9
    task.spawn(function()
        for i=1,3 do TweenService:Create(pulse, TweenInfo.new(0.15), {Transparency = 1}):Play(); wait(0.15); TweenService:Create(pulse, TweenInfo.new(0.15), {Transparency = 0.25}):Play(); wait(0.15) end
        pcall(function() pulse:Destroy() end)
    end)
end

unlockBtn.MouseButton1Click:Connect(function()
    if unlockedFlag then return end
    local entry = tostring(inputBox.Text or ""):gsub("^%s*(.-)%s*$","%1")
    if isOwner() then revealTools(); return end
    if entry == "" then notify("Empty","Enter key or password.",2); return end
    if isValidKey(entry) then revealTools(); return end
    attemptCount = attemptCount + 1
    authStatus.Text = "Status: Wrong key ("..attemptCount.."/"..MAX_ATTEMPTS..")"
    notify("Wrong Key","Attempt "..attemptCount.."/"..MAX_ATTEMPTS,2)
    if attemptCount >= MAX_ATTEMPTS then notify("Locked","Too many attempts. Closing UI.",3); wait(1.1); pcall(function() screenGui:Destroy() end) end
end)

-- optional owner helper: show obf keys (create small button)
local showBtn = Instance.new("TextButton", authFrame)
showBtn.Size = UDim2.new(0, 200, 0, 34)
showBtn.Position = UDim2.new(0, 0, 0, 264)
showBtn.BackgroundColor3 = Color3.fromRGB(18,18,18)
showBtn.Font = Enum.Font.Gotham
showBtn.Text = "Owner: Show Obf Keys"
showBtn.TextColor3 = Color3.fromRGB(240,240,240)
local showCorner = Instance.new("UICorner", showBtn); showCorner.CornerRadius = UDim.new(0,8)
showBtn.MouseButton1Click:Connect(function()
    if not isOwner() then notify("Denied","Owner only.",2); return end
    local lines = {}
    for i,h in ipairs(OBF_HEX) do lines[#lines+1] = ("Key%d:%s"):format(i,h) end
    notify("Obfuscated Keys", table.concat(lines," | "), math.min(6,#lines*0.6 + 1))
end)

-- ================ CONFIRM & COPY ================
local function doCopy()
    if copyCooldown then notify("Cooldown","Wait before copying again.",2); return end
    copyCooldown = true
    local ok, err = pcall(function()
        local saveinstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/SynSaveInstance/main/saveinstance.luau"))()
        saveinstance({
            FileName = "AGHA_LEAKS_COPY_" .. tostring(game.PlaceId) .. ".rbxlx",
            Decompile = true,
            IncludeScripts = true,
            CreatorTag = "AGHA.LEAKS"
        })
    end)
    if ok then notify("Success","Copy completed.",4) else notify("Error", tostring(err),6) end
    -- cooldown ticker
    task.spawn(function()
        local t = COPY_COOLDOWN
        while t > 0 do
            notify("Cooldown","Next copy in "..t.."s",1)
            t = t - 1
            wait(1)
        end
        copyCooldown = false
    end)
end

local function showConfirm()
    modal.Visible = true
    progFill.Size = UDim2.new(0,0,1,0)
    progText.Text = "Ready..."
    modalTitle.Text = "Confirm Copy"
    -- cleanup previous
    for _,v in ipairs(modal:GetChildren()) do if v.Name == "ConfirmBtns" then v:Destroy() end end
    local f = Instance.new("Frame", modal); f.Name = "ConfirmBtns"; f.Size = UDim2.new(1, -28, 0, 44); f.Position = UDim2.new(0,14,1,-56); f.BackgroundTransparency = 1
    local yes = Instance.new("TextButton", f); yes.Size = UDim2.new(0, 180, 1, 0); yes.Position = UDim2.new(0,0,0,0); yes.Text = "Confirm — Proceed"; yes.Font = Enum.Font.GothamBold; yes.TextSize = 14; yes.BackgroundColor3 = Color3.fromRGB(255,255,255); yes.TextColor3 = Color3.fromRGB(6,6,6); local yc = Instance.new("UICorner", yes); yc.CornerRadius = UDim.new(0,8)
    local cancel = Instance.new("TextButton", f); cancel.Size = UDim2.new(0, 120, 1, 0); cancel.Position = UDim2.new(0, 200, 0, 0); cancel.Text = "Cancel"; cancel.Font = Enum.Font.Gotham; cancel.TextSize = 14; cancel.BackgroundColor3 = Color3.fromRGB(18,18,18); cancel.TextColor3 = Color3.fromRGB(240,240,240); local cc = Instance.new("UICorner", cancel); cc.CornerRadius = UDim.new(0,8)
    local running = false
    cancel.MouseButton1Click:Connect(function() if running then return end modal.Visible=false; f:Destroy(); notify("Cancelled","Action cancelled.",2) end)
    yes.MouseButton1Click:Connect(function()
        if running then return end
        running = true
        f:Destroy()
        progText.Text = "Running..."
        -- simulate progressive fill then call doCopy
        task.spawn(function()
            local p = 0
            while p < 0.92 do
                p = math.min(0.92, p + (0.12 + math.random()*0.12))
                TweenService:Create(progFill, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {Size = UDim2.new(p,0,1,0)}):Play()
                wait(0.45)
            end
            local ok, err = pcall(doCopy)
            if ok then TweenService:Create(progFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Size = UDim2.new(1,0,1,0)}):Play(); progText.Text="Completed." else progText.Text="Error: "..tostring(err) end
            wait(1.1)
            modal.Visible = false
            progFill.Size = UDim2.new(0,0,1,0)
        end)
    end)
end

copyBtn.MouseButton1Click:Connect(function()
    if not unlockedFlag then notify("Locked","Unlock first.",2); return end
    showConfirm()
end)

openDisc.MouseButton1Click:Connect(function()
    safeClipboard(DISCORD_INVITE)
    notify("Discord","Invite copied to clipboard.",3)
    pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
end)

-- initial show animation + blur
main.BackgroundTransparency = 1
main.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(main, TweenInfo.new(0.38, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
if blurEffect then TweenService:Create(blurEffect, TweenInfo.new(0.45), {Size = 8}):Play() end

-- bind P toggle (PC)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.P then screenGui.Enabled = not screenGui.Enabled end
end)

-- final console line
pcall(function() print("AGHA.LEAKS — remember: ONLY FOR THE ACCESS PURCHASED GUYS!") end)
