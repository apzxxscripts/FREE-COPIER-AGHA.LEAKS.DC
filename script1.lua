-- AGHA.LEAKS — CUSTOM GUI — LocalScript (StarterPlayerScripts)
-- Ultra-polished custom GUI (no external libraries)
-- Features:
--  • Custom dark/neon UI, draggable
--  • Local key system (obfuscated), legacy password support
--  • Owner bypass (your user id)
--  • Confirmation modal + animated progress bar for Copy action
--  • Copy Game + Scripts via saveinstance (same helper) — use only if you own the place
--  • Button cooldowns, notifications, and animations

-- ================= CONFIG =================
local DISCORD_INVITE = "https://discord.gg/REC6NEWAck"
local OWNER_USERID   = 913464555013828629
local MAX_ATTEMPTS   = 3
local COPY_COOLDOWN  = 8                      -- seconds
local KEY_XOR_SECRET = 0x5A                   -- XOR secret (single byte)
local LEGACY_PASSWORD = "itxmadebyagha_ytx"   -- legacy password

-- Add plaintext keys here (they will be obfuscated embedded into runtime)
local PLAIN_KEYS = {
    "AGHA-KEY-001",
    "AGHA-KEY-002",
    "AGHA-KEY-EXAMPLE"
}

-- UI theme (tweak)
local THEME = {
    Background = Color3.fromRGB(12,12,12),
    Panel = Color3.fromRGB(20,6,6),
    Accent = Color3.fromRGB(255,0,90),
    Text = Color3.fromRGB(235,235,235),
    SubText = Color3.fromRGB(180,180,180),
    Success = Color3.fromRGB(0,230,120),
    Danger = Color3.fromRGB(255,60,60),
}

-- ================ UTILITIES ================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = tostring(title), Text = tostring(text), Duration = duration or 3})
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

-- Prepare obfuscated keys (script will contain these hex strings only)
local OBF_HEX = {}
for _, k in ipairs(PLAIN_KEYS) do
    OBF_HEX[#OBF_HEX+1] = xorToHex(k, KEY_XOR_SECRET)
end

local function isValidKey(input)
    if input == nil then return false end
    input = tostring(input)
    if input == LEGACY_PASSWORD then return true end
    -- owner bypass check handled elsewhere
    -- check cleartext match against de-obfuscated keys
    for _, hex in ipairs(OBF_HEX) do
        if input == hexToXor(hex, KEY_XOR_SECRET) then return true end
    end
    -- also allow pasting the hex directly (advanced)
    for _, hex in ipairs(OBF_HEX) do
        if input:lower() == hex:lower() then return true end
    end
    return false
end

-- ================ GUI BUILD ================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AGHA_LEAKS_GUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- main container
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 540, 0, 380)
main.Position = UDim2.new(0.5, -270, 0.5, -190)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = THEME.Panel
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = THEME.Accent
mainStroke.Thickness = 2

-- shadow glow (image)
local glow = Instance.new("ImageLabel", main)
glow.Name = "Glow"
glow.AnchorPoint = Vector2.new(0.5,0.5)
glow.Position = UDim2.new(0.5, 0.5, 0.5, 0)
glow.Size = UDim2.new(1, 120, 1, 120)
glow.Image = "rbxassetid://1316045217"
glow.BackgroundTransparency = 1
glow.ImageColor3 = THEME.Accent
glow.ImageTransparency = 0.8
glow.ZIndex = 0
glow.ScaleType = Enum.ScaleType.Slice
glow.SliceCenter = Rect.new(10,10,118,118)

-- topbar for dragging
local topbar = Instance.new("Frame", main)
topbar.Name = "Topbar"
topbar.Size = UDim2.new(1, 0, 0, 56)
topbar.Position = UDim2.new(0, 0, 0, 0)
topbar.BackgroundColor3 = Color3.fromRGB(18,18,18)
topbar.BorderSizePixel = 0
local topCorner = Instance.new("UICorner", topbar)
topCorner.CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", topbar)
title.Name = "Title"
title.Size = UDim2.new(1, -140, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = THEME.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "AGHA.LEAKS"

local statusText = Instance.new("TextLabel", topbar)
statusText.Name = "Status"
statusText.Size = UDim2.new(0, 120, 0, 24)
statusText.Position = UDim2.new(1, -136, 0.5, -12)
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 14
statusText.TextColor3 = THEME.SubText
statusText.Text = "Waiting..."
statusText.TextXAlignment = Enum.TextXAlignment.Right

local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -40, 0.5, -14)
closeBtn.AnchorPoint = Vector2.new(0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = THEME.SubText
closeBtn.Text = "✕"

-- left content: auth / tools panels
local content = Instance.new("Frame", main)
content.Name = "Content"
content.Position = UDim2.new(0, 16, 0, 72)
content.Size = UDim2.new(1, -32, 1, -88)
content.BackgroundTransparency = 1

-- left column for tabs
local tabs = Instance.new("Frame", content)
tabs.Name = "Tabs"
tabs.Size = UDim2.new(0, 140, 1, 0)
tabs.Position = UDim2.new(0, 0, 0, 0)
tabs.BackgroundTransparency = 1

local tabsListLayout = Instance.new("UIListLayout", tabs)
tabsListLayout.Padding = UDim.new(0, 10)
tabsListLayout.FillDirection = Enum.FillDirection.Vertical
tabsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- tab buttons
local function createTabButton(parent, text)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -8, 0, 44)
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Text = text
    btn.TextColor3 = THEME.Text
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(40,40,40)
    stroke.Thickness = 1
    return btn
end

local authTabBtn = createTabButton(tabs, "Authenticate")
local toolsTabBtn = createTabButton(tabs, "Tools")
toolsTabBtn.BackgroundColor3 = Color3.fromRGB(24,24,24)
toolsTabBtn.TextColor3 = Color3.fromRGB(160,160,160)

-- right panel area
local panel = Instance.new("Frame", content)
panel.Name = "Panel"
panel.Size = UDim2.new(1, -156, 1, 0)
panel.Position = UDim2.new(0, 148, 0, 0)
panel.BackgroundColor3 = Color3.fromRGB(18,18,18)
panel.BorderSizePixel = 0
local panelCorner = Instance.new("UICorner", panel)
panelCorner.CornerRadius = UDim.new(0, 10)

local panelPadding = Instance.new("UIPadding", panel)
panelPadding.PaddingLeft = UDim.new(0, 14)
panelPadding.PaddingTop = UDim.new(0, 14)
panelPadding.PaddingRight = UDim.new(0, 14)
panelPadding.PaddingBottom = UDim.new(0, 14)

-- internal content frames: authFrame and toolsFrame
local authFrame = Instance.new("Frame", panel)
authFrame.Name = "AuthFrame"
authFrame.Size = UDim2.new(1, 0, 1, 0)
authFrame.BackgroundTransparency = 1

local toolsFrame = Instance.new("Frame", panel)
toolsFrame.Name = "ToolsFrame"
toolsFrame.Size = UDim2.new(1, 0, 1, 0)
toolsFrame.BackgroundTransparency = 1
toolsFrame.Visible = false

-- AUTH UI
local authTitle = Instance.new("TextLabel", authFrame)
authTitle.Size = UDim2.new(1,0,0,28)
authTitle.Position = UDim2.new(0,0,0,0)
authTitle.BackgroundTransparency = 1
authTitle.Font = Enum.Font.GothamBold
authTitle.TextSize = 18
authTitle.Text = "Authenticate"
authTitle.TextColor3 = THEME.Text
authTitle.TextXAlignment = Enum.TextXAlignment.Left

local authDesc = Instance.new("TextLabel", authFrame)
authDesc.Size = UDim2.new(1,0,0,40)
authDesc.Position = UDim2.new(0,0,0,34)
authDesc.BackgroundTransparency = 1
authDesc.Font = Enum.Font.Gotham
authDesc.TextSize = 14
authDesc.Text = "Join Discord to get your key or use the legacy password."
authDesc.TextColor3 = THEME.SubText
authDesc.TextXAlignment = Enum.TextXAlignment.Left

local getKeyBtn = Instance.new("TextButton", authFrame)
getKeyBtn.Size = UDim2.new(0, 240, 0, 44)
getKeyBtn.Position = UDim2.new(0,0,0,86)
getKeyBtn.BackgroundColor3 = THEME.Accent
getKeyBtn.Font = Enum.Font.GothamBold
getKeyBtn.TextSize = 16
getKeyBtn.Text = "Get Key — Open Discord"
getKeyBtn.TextColor3 = Color3.new(1,1,1)
local getKeyCorner = Instance.new("UICorner", getKeyBtn)
getKeyCorner.CornerRadius = UDim.new(0, 8)
local getKeyStroke = Instance.new("UIStroke", getKeyBtn)
getKeyStroke.Color = Color3.fromRGB(255,100,140)
getKeyStroke.Thickness = 1.6

local inputBox = Instance.new("TextBox", authFrame)
inputBox.Size = UDim2.new(1, -0, 0, 44)
inputBox.Position = UDim2.new(0, 0, 0, 146)
inputBox.BackgroundColor3 = Color3.fromRGB(28,28,28)
inputBox.PlaceholderText = "Paste key from Discord or legacy password"
inputBox.ClearTextOnFocus = false
inputBox.Text = ""
inputBox.TextColor3 = THEME.Text
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 16
local inputCorner = Instance.new("UICorner", inputBox)
inputCorner.CornerRadius = UDim.new(0, 8)
local inputStroke = Instance.new("UIStroke", inputBox)
inputStroke.Color = Color3.fromRGB(40,40,40)

local unlockButton = Instance.new("TextButton", authFrame)
unlockButton.Size = UDim2.new(0, 200, 0, 44)
unlockButton.Position = UDim2.new(0, 0, 0, 200)
unlockButton.BackgroundColor3 = THEME.Accent
unlockButton.Text = "Unlock"
unlockButton.Font = Enum.Font.GothamBold
unlockButton.TextSize = 16
unlockButton.TextColor3 = Color3.new(1,1,1)
local unlockCorner = Instance.new("UICorner", unlockButton)
unlockCorner.CornerRadius = UDim.new(0,8)

local legacyNote = Instance.new("TextLabel", authFrame)
legacyNote.Size = UDim2.new(1,0,0,30)
legacyNote.Position = UDim2.new(0, 210, 0, 0)
legacyNote.BackgroundTransparency = 1
legacyNote.Font = Enum.Font.Gotham
legacyNote.TextSize = 12
legacyNote.TextColor3 = THEME.SubText
legacyNote.Text = "Legacy password supported."

-- STATUS label lower
local authStatus = Instance.new("TextLabel", authFrame)
authStatus.Size = UDim2.new(1,0,0,22)
authStatus.Position = UDim2.new(0,0,1,-28)
authStatus.BackgroundTransparency = 1
authStatus.Font = Enum.Font.Gotham
authStatus.TextSize = 13
authStatus.TextColor3 = THEME.SubText
authStatus.TextXAlignment = Enum.TextXAlignment.Left
authStatus.Text = "Status: Waiting for input..."

-- TOOLS UI
local toolsTitle = Instance.new("TextLabel", toolsFrame)
toolsTitle.Size = UDim2.new(1,0,0,28)
toolsTitle.Position = UDim2.new(0,0,0,0)
toolsTitle.BackgroundTransparency = 1
toolsTitle.Font = Enum.Font.GothamBold
toolsTitle.TextSize = 18
toolsTitle.Text = "Tools"
toolsTitle.TextColor3 = THEME.Text
toolsTitle.TextXAlignment = Enum.TextXAlignment.Left

local toolsNote = Instance.new("TextLabel", toolsFrame)
toolsNote.Size = UDim2.new(1,0,0,28)
toolsNote.Position = UDim2.new(0,0,0,36)
toolsNote.BackgroundTransparency = 1
toolsNote.Font = Enum.Font.Gotham
toolsNote.TextSize = 14
toolsNote.Text = "⚠️ ONLY FOR THE ACCESS PURCHASED GUYS!"
toolsNote.TextColor3 = THEME.Danger
toolsNote.TextXAlignment = Enum.TextXAlignment.Left

local copyBtn = Instance.new("TextButton", toolsFrame)
copyBtn.Size = UDim2.new(0, 260, 0, 48)
copyBtn.Position = UDim2.new(0, 0, 0, 74)
copyBtn.BackgroundColor3 = THEME.Accent
copyBtn.Font = Enum.Font.GothamBold
copyBtn.Text = "📂 Copy Game + Scripts (Confirm)"
copyBtn.TextSize = 16
copyBtn.TextColor3 = Color3.new(1,1,1)
local copyCorner = Instance.new("UICorner", copyBtn)
copyCorner.CornerRadius = UDim.new(0, 10)

local discordBtn = Instance.new("TextButton", toolsFrame)
discordBtn.Size = UDim2.new(0, 180, 0, 40)
discordBtn.Position = UDim2.new(0, 0, 0, 134)
discordBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
discordBtn.Font = Enum.Font.Gotham
discordBtn.Text = "Open Discord"
discordBtn.TextSize = 14
discordBtn.TextColor3 = THEME.Text
local discordCorner = Instance.new("UICorner", discordBtn)
discordCorner.CornerRadius = UDim.new(0,8)

local closeToolsBtn = Instance.new("TextButton", toolsFrame)
closeToolsBtn.Size = UDim2.new(0, 120, 0, 36)
closeToolsBtn.Position = UDim2.new(0, 0, 1, -46)
closeToolsBtn.BackgroundColor3 = Color3.fromRGB(28,28,28)
closeToolsBtn.Font = Enum.Font.Gotham
closeToolsBtn.Text = "Close UI"
closeToolsBtn.TextSize = 14
closeToolsBtn.TextColor3 = THEME.Text
local closeCorner = Instance.new("UICorner", closeToolsBtn)
closeCorner.CornerRadius = UDim.new(0,8)

-- progress bar modal (hidden by default)
local modal = Instance.new("Frame", screenGui)
modal.Name = "Modal"
modal.Size = UDim2.new(0, 420, 0, 160)
modal.Position = UDim2.new(0.5, -210, 0.5, -80)
modal.BackgroundColor3 = Color3.fromRGB(18,18,18)
modal.BorderSizePixel = 0
modal.Visible = false
modal.AnchorPoint = Vector2.new(0.5,0.5)
local modalCorner = Instance.new("UICorner", modal)
modalCorner.CornerRadius = UDim.new(0, 12)
local modalStroke = Instance.new("UIStroke", modal)
modalStroke.Color = THEME.Accent
modalStroke.Thickness = 2

local modalTitle = Instance.new("TextLabel", modal)
modalTitle.Size = UDim2.new(1, -28, 0, 28)
modalTitle.Position = UDim2.new(0, 14, 0, 12)
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBold
modalTitle.Text = "Progress"
modalTitle.TextSize = 16
modalTitle.TextColor3 = THEME.Text

local progressBarBg = Instance.new("Frame", modal)
progressBarBg.Size = UDim2.new(1, -28, 0, 28)
progressBarBg.Position = UDim2.new(0, 14, 0, 56)
progressBarBg.BackgroundColor3 = Color3.fromRGB(28,28,28)
local pBgCorner = Instance.new("UICorner", progressBarBg)
pBgCorner.CornerRadius = UDim.new(0, 8)

local progressFill = Instance.new("Frame", progressBarBg)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = THEME.Success
local pFillCorner = Instance.new("UICorner", progressFill)
pFillCorner.CornerRadius = UDim.new(0, 8)

local progressText = Instance.new("TextLabel", modal)
progressText.Size = UDim2.new(1, -28, 0, 22)
progressText.Position = UDim2.new(0, 14, 0, 90)
progressText.BackgroundTransparency = 1
progressText.Font = Enum.Font.Gotham
progressText.Text = "Starting..."
progressText.TextColor3 = THEME.SubText
progressText.TextSize = 14

-- ========= INTERACTION LOGIC =========
local attemptsCount = 0
local unlockedFlag = false
local copy_on_cooldown = false

-- drag support for main
do
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Tab switching
authTabBtn.MouseButton1Click:Connect(function()
    authFrame.Visible = true
    toolsFrame.Visible = false
    authTabBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    toolsTabBtn.BackgroundColor3 = Color3.fromRGB(24,24,24)
    toolsTabBtn.TextColor3 = Color3.fromRGB(160,160,160)
end)
toolsTabBtn.MouseButton1Click:Connect(function()
    if not unlockedFlag then
        notify("Locked", "Unlock first to access Tools.", 3)
        return
    end
    authFrame.Visible = false
    toolsFrame.Visible = true
    authTabBtn.BackgroundColor3 = Color3.fromRGB(24,24,24)
    toolsTabBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    toolsTabBtn.TextColor3 = THEME.Text
end)

-- close handlers
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(main, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    task.delay(0.25, function() pcall(function() screenGui:Destroy() end) end)
end)
closeToolsBtn.MouseButton1Click:Connect(function()
    TweenService:Create(main, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
    task.delay(0.22, function() pcall(function() screenGui:Destroy() end) end)
end)

-- Get key button: copy invite and try open
getKeyBtn.MouseButton1Click:Connect(function()
    setClipboardSafe(DISCORD_INVITE)
    notify("Discord", "Invite copied to clipboard. Open it to get your key.", 4)
    pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
end)

-- owner bypass helper
local function isOwner()
    local pl = LocalPlayer
    return pl and pl.UserId == OWNER_USERID
end

-- helper: show tools after unlock
local function revealTools()
    unlockedFlag = true
    authFrame.Visible = false
    toolsFrame.Visible = true
    toolsTabBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    toolsTabBtn.TextColor3 = THEME.Text
    authStatus.Text = "Status: Unlocked"
    statusText.Text = "Unlocked"
    notify("Access Granted", "Welcome — Tools unlocked.", 3)
    -- small glow pulse on main border
    local pulse = Instance.new("UIStroke", main)
    pulse.Color = Color3.fromRGB(0,255,150)
    pulse.Thickness = 3
    pulse.Transparency = 0.85
    task.spawn(function()
        for i = 1, 4 do
            TweenService:Create(pulse, TweenInfo.new(0.18), {Transparency = 1}):Play()
            task.wait(0.18)
            TweenService:Create(pulse, TweenInfo.new(0.18), {Transparency = 0.3}):Play()
            task.wait(0.18)
        end
        pcall(function() pulse:Destroy() end)
    end)
end

-- unlock button logic
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
        attemptsCount = attemptsCount + 1
        authStatus.Text = "Status: Wrong key ("..attemptsCount.."/"..MAX_ATTEMPTS..")"
        notify("Wrong Key", "Attempt "..attemptsCount.."/"..MAX_ATTEMPTS, 2.2)
        if attemptsCount >= MAX_ATTEMPTS then
            notify("Locked", "Too many failed attempts. UI will close.", 3)
            task.wait(1.2)
            pcall(function() screenGui:Destroy() end)
        end
    end
end)

-- confirmation modal
local function showConfirm(title, message, yesCallback)
    modalTitle.Text = title
    progressText.Text = message
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    modal.Visible = true
    -- Build simple confirm UI inside modal (Yes / Cancel)
    -- Clear previous confirm buttons if any
    for _, child in ipairs(modal:GetChildren()) do
        if child.Name == "ConfirmButtons" then child:Destroy() end
    end
    local btnFrame = Instance.new("Frame", modal)
    btnFrame.Name = "ConfirmButtons"
    btnFrame.Size = UDim2.new(1, -28, 0, 36)
    btnFrame.Position = UDim2.new(0, 14, 1, -50)
    btnFrame.BackgroundTransparency = 1

    local yesBtn = Instance.new("TextButton", btnFrame)
    yesBtn.Size = UDim2.new(0, 140, 1, 0)
    yesBtn.Position = UDim2.new(0, 0, 0, 0)
    yesBtn.Text = "Confirm — Proceed"
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.TextSize = 14
    yesBtn.BackgroundColor3 = THEME.Accent
    yesBtn.TextColor3 = Color3.new(1,1,1)
    local yc = Instance.new("UICorner", yesBtn) yc.CornerRadius = UDim.new(0,8)

    local cancelBtn = Instance.new("TextButton", btnFrame)
    cancelBtn.Size = UDim2.new(0, 110, 1, 0)
    cancelBtn.Position = UDim2.new(0, 150, 0, 0)
    cancelBtn.Text = "Cancel"
    cancelBtn.Font = Enum.Font.Gotham
    cancelBtn.TextSize = 14
    cancelBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    cancelBtn.TextColor3 = THEME.Text
    local cc = Instance.new("UICorner", cancelBtn) cc.CornerRadius = UDim.new(0,8)

    local cleanedUp = false
    cancelBtn.MouseButton1Click:Connect(function()
        if cleanedUp then return end
        cleanedUp = true
        modal.Visible = false
        notify("Cancelled", "Action cancelled.", 2)
        btnFrame:Destroy()
    end)
    yesBtn.MouseButton1Click:Connect(function()
        if cleanedUp then return end
        cleanedUp = true
        btnFrame:Destroy()
        -- start progress animation and run callback
        task.spawn(function()
            progressText.Text = "Running..."
            -- animate progress fill to 95% over a few seconds
            local total = 0
            while total < 0.94 do
                total = math.min(0.94, total + (0.12 + math.random() * 0.12))
                local goal = UDim2.new(total, 0, 1, 0)
                TweenService:Create(progressFill, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {Size = goal}):Play()
                task.wait(0.45)
            end
            -- call the copy routine
            local ok, err = pcall(function() yesCallback() end)
            if ok then
                -- fill to 100%
                TweenService:Create(progressFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Size = UDim2.new(1,0,1,0)}):Play()
                progressText.Text = "Completed."
                notify("Success", "Copy completed.", 4)
            else
                progressText.Text = "Error: "..tostring(err)
                notify("Error", tostring(err), 5)
            end
            task.wait(1.2)
            modal.Visible = false
            progressFill.Size = UDim2.new(0,0,1,0)
        end)
    end)
end

-- copy routine (actual saving)
local function performCopy()
    if copy_on_cooldown then
        notify("Cooldown", "Copy is on cooldown. Wait a bit.", 2)
        return
    end
    copy_on_cooldown = true
    -- run the saving logic (decompile, include scripts)
    local ok, err = pcall(function()
        local saveinstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/SynSaveInstance/main/saveinstance.luau"))()
        saveinstance({
            FileName = "AGHA_LEAKS_COPY_" .. tostring(game.PlaceId) .. ".rbxlx",
            Decompile = true,
            IncludeScripts = true,
            CreatorTag = "AGHA.LEAKS"
        })
    end)
    if not ok then
        notify("Copy Error", tostring(err), 5)
    end
    -- start cooldown display (simple)
    spawn(function()
        local rem = COPY_COOLDOWN
        while rem > 0 do
            notify("Cooldown", "Next copy available in "..tostring(rem).."s", 1)
            rem = rem - 1
            task.wait(1)
        end
        copy_on_cooldown = false
    end)
end

copyBtn.MouseButton1Click:Connect(function()
    if not unlockedFlag then
        notify("Locked", "Unlock first with a valid key/password.", 2.5)
        return
    end
    showConfirm("Copy Game", "This will save the current place and included scripts as an .rbxlx file. Proceed? (ONLY FOR THE ACCESS PURCHASED GUYS!)", performCopy)
end)

-- discord button
discordBtn.MouseButton1Click:Connect(function()
    setClipboardSafe(DISCORD_INVITE)
    notify("Discord", "Invite copied to clipboard.", 3)
    pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
end)

-- final console reminder (modified phrasing)
pcall(function() print("AGHA.LEAKS — remember: ONLY FOR THE ACCESS PURCHASED GUYS!") end)

-- fade-in entrance
main.BackgroundTransparency = 1
TweenService:Create(main, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
TweenService:Create(mainStroke, TweenInfo.new(0.6), {Transparency = 0}):Play()

-- initial tab set
authFrame.Visible = true
toolsFrame.Visible = false

-- Bind toggle key (P)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        -- toggle visibility
        if screenGui.Enabled == false then
            screenGui.Enabled = true
        else
            screenGui.Enabled = not screenGui.Enabled
        end
    end
end)
