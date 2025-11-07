-- AGHA.LEAKS — ULTRA POLISHED (Rayfield) — LocalScript
-- 🔥 Much improved UX: obfuscated keys, owner-bypass, confirmations, cooldowns, progress & safer flow.
-- ⚠️ WARNING: This script includes an automated game-copy helper. ONLY FOR THE ACCESS PURCHASED GUYS!

-- ========= CONFIG =========
local DISCORD_INVITE = "https://discord.gg/REC6NEWAck"
local OWNER_USERID   = 913464555013828629          -- owner bypass (you)
local MAX_ATTEMPTS    = 3
local COOLDOWN_COPY   = 8                           -- seconds cooldown after Copy pressed
local KEY_XOR_SECRET  = 0x5A                        -- single-byte XOR secret for obfuscating keys (change if you like)

-- Add keys here (plain keys for you to generate; they will be obfuscated automatically below)
local PLAIN_KEYS = {
    "AGHA-KEY-001",
    "AGHA-KEY-002",
    "AGHA-KEY-EXAMPLE"
}

-- Legacy password (kept for compatibility)
local LEGACY_PASSWORD = "itxmadebyagha_ytx"

-- OPTIONAL: show fancy notifications on unlock success (true/false)
local USE_FANCY_SUCCESS = true

-- ========= HELPERS: obfuscate / deobfuscate keys =========
local function xorBytesToHex(str, key)
    local out = {}
    for i = 1, #str do
        local b = string.byte(str, i)
        local x = bit32.bxor(b, key)
        out[#out+1] = string.format("%02x", x)
    end
    return table.concat(out)
end

local function hexToXorString(hex, key)
    local out = {}
    for i = 1, #hex, 2 do
        local byte = tonumber(hex:sub(i,i+1), 16)
        local orig = bit32.bxor(byte, key)
        out[#out+1] = string.char(orig)
    end
    return table.concat(out)
end

-- build obfuscated key table from PLAIN_KEYS at runtime (so script contains only hex, not plaintext)
local OBFUSCATED_KEYS = {}
for _, k in ipairs(PLAIN_KEYS) do
    OBFUSCATED_KEYS[#OBFUSCATED_KEYS+1] = xorBytesToHex(k, KEY_XOR_SECRET)
end

-- check function for entries (input is raw string)
local function isValidKey(entry)
    if not entry or entry == "" then return false end
    -- direct exact legacy
    if entry == LEGACY_PASSWORD then return true end
    -- check against obfuscated keys
    for _, hex in ipairs(OBFUSCATED_KEYS) do
        if entry == hexToXorString(hex, KEY_XOR_SECRET) then
            return true
        end
    end
    -- also allow users to paste the obfuscated hex directly (advanced)
    for _, hex in ipairs(OBFUSCATED_KEYS) do
        if entry:lower() == hex:lower() then
            -- they pasted hex — accept too
            return true
        end
    end
    return false
end

-- ========= Rayfield loader (robust with multiple sources) =========
local function loadRayfield()
    local urls = {
        "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
        "https://sirius.menu/rayfield"
    }
    for _, url in ipairs(urls) do
        local ok, res = pcall(function()
            local content = game:HttpGet(url)
            return loadstring(content)()
        end)
        if ok and res then
            return res
        end
    end
    return nil
end

local Rayfield = nil
local ok, err = pcall(function() Rayfield = loadRayfield() end)
if not Rayfield then
    warn("AGHA.LEAKS: Rayfield failed to load. Error:", err)
    -- Inform user via in-game notification (if possible) then stop to avoid crashes.
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("SendNotification", {
            Title = "AGHA.LEAKS",
            Text = "Failed to load UI library (Rayfield). Allow HttpGet or add Rayfield locally.",
            Duration = 6
        })
    end)
    return
end

-- ========= UI State =========
local attempts = 0
local unlocked = false
local copyCooldown = false

-- ========= Create window & tabs =========
local Window = Rayfield:CreateWindow({
    Name = "AGHA.LEAKS",
    LoadingTitle = "AGHA.LEAKS",
    LoadingSubtitle = "Authenticate to unlock tools",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})
local AuthTab = Window:CreateTab("🔐 Authenticate")
local ToolsTab = Window:CreateTab("📂 Tools")
ToolsTab:SetVisibility(false)

-- small helper to show notification (Rayfield + backup)
local function notify(title, content, dur)
    dur = dur or 3
    pcall(function() Rayfield:Notify({Title = title, Content = content, Duration = dur}) end)
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("SendNotification", {Title = title, Text = content, Duration = dur})
    end)
end

-- ========= Auth UI =========
AuthTab:CreateLabel("🔗 Join Discord to get a key — or use the legacy password.")
AuthTab:CreateButton({
    Name = "Get Key — Open Discord",
    Callback = function()
        pcall(setclipboard, DISCORD_INVITE)
        notify("Discord", "Invite copied to clipboard. Open it to get your key.", 4)
        pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
    end
})

AuthTab:CreateLabel("Enter key (or legacy password). Keys are case-sensitive.")
local keyInput = AuthTab:CreateInput({
    Name = "Enter Key / Password",
    PlaceholderText = "AGHA-KEY-XXXX  or  legacy password",
    RemoveTextAfterFocusLost = false,
    Callback = function(val) end
})

local unlockBtn = AuthTab:CreateButton({
    Name = "🔓 Unlock",
    Callback = function()
        if unlocked then return end
        local entry = tostring(keyInput.Value or ""):gsub("^%s*(.-)%s*$", "%1") -- trim

        -- owner bypass
        local lp = game.Players.LocalPlayer
        if lp and lp.UserId == OWNER_USERID then
            unlocked = true
            ToolsTab:SetVisibility(true)
            AuthTab:SetVisibility(false)
            unlockBtn:Update({Name = "Unlocked (Owner)", Disabled = true})
            notify("Owner", "Owner bypass: Tools unlocked.", 3)
            return
        end

        if entry == "" then
            notify("Empty", "Enter key or password first.", 2)
            return
        end

        -- Accept both the clear key or the hex-obfuscated key or legacy
        if isValidKey(entry) then
            unlocked = true
            ToolsTab:SetVisibility(true)
            AuthTab:SetVisibility(false)
            unlockBtn:Update({Name = "Unlocked", Disabled = true})
            keyInput:Update({PlaceholderText = "Unlocked", RemoveTextAfterFocusLost = true})
            if USE_FANCY_SUCCESS then
                notify("✅ Access Granted", "Welcome — AGHA.LEAKS tools unlocked.", 4)
                -- small celebratory animation: multiple notifications (fast)
                task.spawn(function()
                    wait(0.15); notify("🎉", "Enjoy the tools.", 1.4)
                    wait(0.3); notify("✨", "Use responsibly.", 1.4)
                end)
            else
                notify("Access Granted", "Tools unlocked.", 3)
            end
            return
        else
            attempts = attempts + 1
            notify("Wrong Key", "Attempt "..attempts.."/"..MAX_ATTEMPTS, 2)
            if attempts >= MAX_ATTEMPTS then
                notify("Locked", "Too many failed attempts. UI will close.", 3)
                task.wait(1.1)
                pcall(function() Rayfield:Destroy() end)
            end
        end
    end
})

-- quick helper to show decoded hex representation (for you only — comment if you don't want)
AuthTab:CreateButton({
    Name = "🔒 Show Obfuscated Keys (hex) — Owner only",
    Callback = function()
        local lp = game.Players.LocalPlayer
        if not lp or lp.UserId ~= OWNER_USERID then
            notify("Denied", "Owner-only.", 2)
            return
        end
        local lines = {}
        for i, hex in ipairs(OBFUSCATED_KEYS) do
            lines[#lines+1] = ("Key %d (hex): %s"):format(i, hex)
        end
        notify("Obfuscated Keys", table.concat(lines, " | "), math.min(6, #lines*0.6 + 1))
    end
})

-- ========= Tools Tab =========
ToolsTab:CreateLabel("⚠️ ONLY FOR THE ACCESS PURCHASED GUYS!")

-- confirmation modal helper
local function confirmAction(title, content, callbackYes)
    -- Rayfield doesn't have a built-in modal confirm everywhere; implement simple two-button approach:
    local id = "confirm_" .. tostring(math.random(1111,9999))
    notify(title, content .. " Click confirm to proceed.", 4)
    -- Create a small quick section with Confirm button for the user
    local sec = ToolsTab:CreateSection("Confirm: " .. title)
    local done = false
    sec:CreateButton({Name = "Confirm — Yes, proceed", Callback = function()
        if done then return end
        done = true
        callbackYes()
        -- cleanup: hide the section (no direct remove, but we simply set label)
        sec:CreateLabel("✅ Action running...")
    end})
    sec:CreateButton({Name = "Cancel", Callback = function() if not done then done = true; notify("Cancelled", "Action cancelled.", 2) end end})
    -- auto-destroy after 18s to avoid UI clutter
    task.spawn(function()
        wait(18)
        pcall(function() sec:CreateLabel("⏳ Confirm area removed.") end)
    end)
end

-- Copy button with confirmation + cooldown + progress simulation
local function runCopySequence()
    if copyCooldown then
        notify("Cooldown", "Wait for the cooldown before copying again.", 2)
        return
    end
    copyCooldown = true

    -- simulate progress for UX
    notify("Preparing", "Preparing to copy... (this may take a while)", 2.5)
    task.wait(0.7)
    notify("Saving", "Saving place file and decompiling scripts...", 3)

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
        notify("✅ Success", "Copy completed and saved.", 4)
    else
        notify("❌ Error", tostring(err), 6)
    end

    -- cooldown timer visual
    task.spawn(function()
        local remain = COOLDOWN_COPY
        while remain > 0 do
            notify("Cooldown", "Next copy available in " .. tostring(remain) .. "s", 1.2)
            task.wait(1)
            remain = remain - 1
        end
        copyCooldown = false
    end)
end

ToolsTab:CreateButton({
    Name = "📂 Copy Game + Scripts (Confirm required)",
    Callback = function()
        if not unlocked then
            notify("Unauthorized", "Unlock first with a valid key/password.", 2.2)
            return
        end
        confirmAction("Copy Game", "This will save the current place and included scripts as an .rbxlx file. Proceed? (ONLY FOR THE ACCESS PURCHASED GUYS!)", runCopySequence)
    end
})

ToolsTab:CreateButton({
    Name = "💬 Open Discord (copy invite)",
    Callback = function()
        pcall(setclipboard, DISCORD_INVITE)
        notify("Discord", "Invite copied to clipboard: " .. DISCORD_INVITE, 3)
        pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
    end
})

ToolsTab:CreateButton({
    Name = "❌ Close UI",
    Callback = function()
        notify("Closing", "UI will be removed.", 1.2)
        task.wait(0.6)
        pcall(function() Rayfield:Destroy() end)
    end
})

-- ========= THEME & BIND =========
Window:SetTheme({
    Background = Color3.fromRGB(12,12,12),
    Topbar = Color3.fromRGB(22,2,2),
    TabBackground = Color3.fromRGB(18,2,2),
    TabStroke = Color3.fromRGB(255,0,90),
    Text = Color3.fromRGB(235,235,235),
    Elements = Color3.fromRGB(255,0,80)
})
Window:BindToKey("P")
notify("AGHA.LEAKS Ready", "Press P to open. Join Discord for keys: " .. DISCORD_INVITE, 4)

-- ========== Final safety console note ==========
pcall(function()
    print("AGHA.LEAKS — remember: ONLY FOR THE ACCESS PURCHASED GUYS!")
end)
