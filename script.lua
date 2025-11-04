-- AGHA.LEAKS — Local Key + Legacy Password (Rayfield UI)
-- Place as a LocalScript (StarterPlayerScripts).
-- WARNING: This includes an automated game-copy function. Use only on games you own or have permission to copy.

-- ========== CONFIG ==========
local DISCORD_INVITE = "https://discord.gg/REC6NEWAck"
local MAX_ATTEMPTS = 3

-- Local keys (optional)
local VALID_KEYS = {
    "AGHA-KEY-001",
    "AGHA-KEY-002",
    "AGHA-KEY-EXAMPLE"
}

-- Legacy password (set by you)
local LEGACY_PASSWORD = "itxmadebyagha_ytx"

-- Encoded password kept for compatibility (not required)
local encoded_password_hex = "a589dba0d3c1a9e4d588dbb6cface6cb"
local _secret_key = "sUp3rS4lt!"

-- ========== helpers ==========
local function hexToBytes(hex)
    local bytes = {}
    for i = 1, #hex, 2 do
        table.insert(bytes, tonumber(hex:sub(i, i+1), 16))
    end
    return bytes
end

local function decode_password(hex, key)
    local bytes = hexToBytes(hex)
    local out = {}
    for i = 1, #bytes do
        local k = string.byte(key, ((i-1) % #key) + 1)
        local b = (bytes[i] - k) % 256
        table.insert(out, string.char(b))
    end
    return table.concat(out)
end

-- Attempt to decode (kept but not required)
local successDecode, decoded_password = pcall(function()
    return decode_password(encoded_password_hex, _secret_key)
end)
if not successDecode then
    decoded_password = ""
end

local function tableContains(tbl, val)
    for _, v in ipairs(tbl) do if v == val then return true end end
    return false
end

-- ========== Rayfield loader (try primary then fallback) ==========
local function safeLoad(urls)
    for _, url in ipairs(urls) do
        local ok, lib = pcall(function()
            local s = game:HttpGet(url)
            return loadstring(s)()
        end)
        if ok and lib then
            return lib
        end
    end
    return nil
end

local rayfieldUrls = {
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
    "https://sirius.menu/rayfield"
}

local Rayfield = safeLoad(rayfieldUrls)
if not Rayfield then
    warn("Rayfield failed to load. Ensure HttpGet is allowed or paste Rayfield locally.")
    return
end

-- ========== UI & State ==========
local attempts = 0
local unlocked = false

local Window = Rayfield:CreateWindow({
    Name = "AGHA.LEAKS",
    LoadingTitle = "AGHA.LEAKS",
    LoadingSubtitle = "Access",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

local AuthTab = Window:CreateTab("Authenticate")
local ToolsTab = Window:CreateTab("Tools")
ToolsTab:SetVisibility(false) -- hidden until unlocked

AuthTab:CreateLabel("Join Discord to get a key or use the legacy password.")
local getKeyBtn = AuthTab:CreateButton({
    Name = "Get Key — Open Discord",
    Callback = function()
        pcall(function() setclipboard(DISCORD_INVITE) end)
        Rayfield:Notify({
            Title = "Discord",
            Content = "Discord invite copied to clipboard.",
            Duration = 4
        })
        pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
    end
})

AuthTab:CreateLabel("Enter key from Discord or legacy password:")

local keyInput = AuthTab:CreateInput({
    Name = "Enter Key / Password",
    PlaceholderText = "AGHA-KEY-XXXX or legacy password",
    RemoveTextAfterFocusLost = false,
    Callback = function(val) end
})

local unlockBtn = AuthTab:CreateButton({
    Name = "Unlock",
    Callback = function()
        local entry = tostring(keyInput.Value or "")
        if entry == "" then
            Rayfield:Notify({Title = "Empty", Content = "Enter a key or password first.", Duration = 3})
            return
        end

        -- Check local keys first
        if tableContains(VALID_KEYS, entry) then
            unlocked = true
            ToolsTab:SetVisibility(true)
            AuthTab:SetVisibility(false)
            Rayfield:Notify({Title = "Access Granted", Content = "Welcome.", Duration = 4})
            return
        end

        -- Check legacy password
        if entry == LEGACY_PASSWORD then
            unlocked = true
            ToolsTab:SetVisibility(true)
            AuthTab:SetVisibility(false)
            Rayfield:Notify({Title = "Access Granted", Content = "Welcome.", Duration = 4})
            return
        end

        -- optional: check decoded obfuscated password (if matches)
        if entry == decoded_password and decoded_password ~= "" then
            unlocked = true
            ToolsTab:SetVisibility(true)
            AuthTab:SetVisibility(false)
            Rayfield:Notify({Title = "Access Granted", Content = "Welcome.", Duration = 4})
            return
        end

        -- wrong entry
        attempts = attempts + 1
        Rayfield:Notify({Title = "Wrong", Content = "Attempt "..attempts.."/"..MAX_ATTEMPTS, Duration = 3})
        if attempts >= MAX_ATTEMPTS then
            Rayfield:Notify({Title = "Locked", Content = "Too many failed attempts. Closing.", Duration = 4})
            task.wait(1.2)
            pcall(function() Rayfield:Destroy() end)
        end
    end
})

-- ========== Tools (unlocked) ==========
local toolsSection = ToolsTab:CreateSection("Copy Tools")
ToolsTab:CreateLabel("Use copy only on games you own or have permission to copy.")

local copyBtn = ToolsTab:CreateButton({
    Name = "Copy Game + Scripts",
    Callback = function()
        if not unlocked then
            Rayfield:Notify({Title = "Unauthorized", Content = "Unlock first.", Duration = 3})
            return
        end

        Rayfield:Notify({Title = "Copy Started", Content = "Attempting to save game + scripts...", Duration = 4})
        task.spawn(function()
            local success, err = pcall(function()
                local saveinstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/SynSaveInstance/main/saveinstance.luau"))()
                saveinstance({
                    FileName = "AGHA_LEAKS_COPY_" .. tostring(game.PlaceId) .. ".rbxlx",
                    Decompile = true,
                    IncludeScripts = true,
                    CreatorTag = "AGHA.LEAKS"
                })
            end)
            if success then
                Rayfield:Notify({Title = "Copy Success", Content = "Saved successfully.", Duration = 5})
            else
                Rayfield:Notify({Title = "Copy Error", Content = tostring(err), Duration = 6})
            end
        end)
    end
})

ToolsTab:CreateButton({
    Name = "Open Discord",
    Callback = function()
        pcall(function() setclipboard(DISCORD_INVITE) end)
        Rayfield:Notify({Title = "Discord", Content = "Discord invite copied to clipboard.", Duration = 3})
        pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_INVITE) end)
    end
})

ToolsTab:CreateButton({
    Name = "Close UI",
    Callback = function()
        Rayfield:Notify({Title = "Closing", Content = "UI will be removed.", Duration = 2})
        task.wait(0.8)
        pcall(function() Rayfield:Destroy() end)
    end
})

-- ========== Theme ==========
Window:SetTheme({
    Background = Color3.fromRGB(12,12,12),
    Topbar = Color3.fromRGB(20,0,0),
    TabBackground = Color3.fromRGB(22,2,2),
    TabStroke = Color3.fromRGB(255,0,90),
    Text = Color3.fromRGB(230,230,230),
    Elements = Color3.fromRGB(255,0,80)
})

-- ========== Bind key (toggle) ==========
Window:BindToKey("P") -- press P to toggle

-- ========== Ready ==========
Rayfield:Notify({Title = "AGHA.LEAKS Ready", Content = "Join Discord for keys: "..DISCORD_INVITE, Duration = 5})
