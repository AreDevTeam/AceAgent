-- ==========================================
-- ACE - STUDIO LITE v1.0 (Powered by ApexLib & Vercel AI)
-- ==========================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local userId = tostring(player.UserId)
local STUDIO_LITE_ID = 10959918411

-- ==========================================
-- [ PRESERVATION SYSTEM (Anti-Dupe) ]
-- ==========================================
if getgenv().Ace_Studio_Loaded then
    warn("[ACE] Script is already running. Reloading interface...")
    if getgenv().Ace_UI_Instance then
        getgenv().Ace_UI_Instance:Destroy()
    end
end
getgenv().Ace_Studio_Loaded = true

-- ==========================================
-- [ KICK / TELEPORT SYSTEM (Game Lock) ]
-- ==========================================
if game.PlaceId ~= STUDIO_LITE_ID then
    local warningMsg = "Ace: Invalid Place. Redirecting to Studio Lite..."
    warn(warningMsg)
    
    local success = pcall(function()
        TeleportService:Teleport(STUDIO_LITE_ID, player)
    end)
    if not success then
        player:Kick("Failed to teleport to Studio Lite. Please join manually.")
    end
    return 
end

-- ==========================================
-- [ LOAD APEXLIB ]
-- ==========================================
local ApexLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Teapokk/ApexLib/refs/heads/main/ApexLib.lua"))()

-- ==========================================
-- [ FILE SYSTEM SETUP (Save/Load) ]
-- ==========================================
local folderName = "AceStudioLite"
local fileName = folderName .. "/configs.json"

if isfolder and not isfolder(folderName) then
    makefolder(folderName)
end

local Settings = {
    AutoSave = false,
    DevMode = false
}

local function SaveSettings()
    if writefile then
        local json = HttpService:JSONEncode(Settings)
        writefile(fileName, json)
    end
end

local function LoadSettings()
    if isfile and isfile(fileName) and readfile then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(fileName))
        end)
        if success and type(decoded) == "table" then
            Settings = decoded
        end
    end
end
LoadSettings()

-- ==========================================
-- [ FETCH NETWORK INFO ]
-- ==========================================
local clientIP = "Fetching..."
task.spawn(function()
    local success, response = pcall(function()
        return game:HttpGet("https://api.ipify.org")
    end)
    clientIP = success and response or "Failed to fetch IP"
end)
local executorName = identifyexecutor and identifyexecutor() or "Unknown Executor"

-- ==========================================
-- [ INITIALIZE WINDOW ]
-- ==========================================
local Win = ApexLib:CreateWindow({
    Title = "ACE - Studio Lite v1.0",
    Size = UDim2.new(0, 600, 0, 420),
    Theme = "Dark",
    Draggable = true
})

getgenv().Ace_UI_Instance = CoreGui:FindFirstChild("ApexLib_UI") or CoreGui:FindFirstChildWhichIsA("ScreenGui") 

-- Tabs
local TabWelcome = Win:AddTab("Welcome")
local TabAgent = Win:AddTab("Agent")
local TabInfo = Win:AddTab("Information")
local TabConfig = Win:AddTab("Settings")

-- ==========================================
-- [ WELCOME TAB ]
-- ==========================================
TabWelcome:AddLabel({
    Title = "Welcome to ACE Studio Lite!",
    Text = "Thank you for using the most advanced utility suite powered by AI.",
    Color = "Info"
})

TabWelcome:AddLabel({
    Title = "How to use ACE:",
    Text = "1. Agent Tab: Talk to the Ace AI to process game commands natively.\n" ..
           "2. Information: Check your security, IP, and local player statistics.\n" ..
           "3. Settings: Toggle Developer mode and manage your configuration files.",
    Color = "White"
})

-- ==========================================
-- [ ACTION INTERPRETER (The Brain) ]
-- ==========================================
local function ExecuteGameCommand(action)
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:FindFirstChild("Humanoid")
    
    if not hum then return "Failed: Humanoid not found." end

    if action == "speed" then
        hum.WalkSpeed = 50
        return "Speed boosted to 50."
    elseif action == "normalspeed" then
        hum.WalkSpeed = 16
        return "Speed normalized."
    elseif action == "jump" then
        hum.JumpPower = 100
        hum.UseJumpPower = true
        return "Jump power increased."
    elseif action == "heal" then
        hum.Health = hum.MaxHealth
        return "Health fully restored."
    end
    
    return "Action [" .. action .. "] recognized, but not programmed yet."
end

-- ==========================================
-- [ AGENT TAB (AI Connection) ]
-- ==========================================
local chatHistory = ""
local ChatDisplay = TabAgent:AddLabel({
    Title = "Agent Terminal",
    Text = "Ace: Hello, " .. player.Name .. "! How can I assist you today?",
    Color = "White"
})

local ChatInput = TabAgent:AddInput({
    Title = "", 
    Placeholder = "Ask Ace to do something (e.g., 'Make me fast')...",
    Height = 40
})

TabAgent:AddButton({
    Title = "Send Message",
    Color = "Success",
    Callback = function()
        local msg = ChatInput.Text
        if msg == "" then return end
        
        chatHistory = chatHistory .. "\n[You]: " .. msg
        ChatDisplay:SetText(chatHistory .. "\n[Ace]: Processing via Vercel...")
        ChatInput.Text = "" 
        
        task.spawn(function()
            local success, response = pcall(function()
                return HttpService:PostAsync(
                    "https://antro-proxy.vercel.app/api/v1/index.js",
                    HttpService:JSONEncode({
                        userId = userId,
                        mensagem = msg
                    }),
                    Enum.HttpContentType.ApplicationJson
                )
            end)
            
            if success then
                local data = HttpService:JSONDecode(response)
                if data.sucesso then
                    local aiText = data.resposta
                    
                    -- Extract command if AI sends [ACTION: command]
                    local actionMatch = string.match(aiText, "%[ACTION:%s*(%a+)%]")
                    if actionMatch then
                        local actionResult = ExecuteGameCommand(string.lower(actionMatch))
                        aiText = aiText .. "\n[System Exec]: " .. actionResult
                    end
                    
                    chatHistory = chatHistory .. "\n[Ace]: " .. aiText
                else
                    chatHistory = chatHistory .. "\n[Ace]: Server Error: " .. (data.erro or "Unknown")
                end
            else
                chatHistory = chatHistory .. "\n[Ace]: Connection to Vercel Proxy failed."
            end
            
            ChatDisplay:SetText(chatHistory)
        end)
    end
})

TabAgent:AddButton({
    Title = "Clear Terminal",
    Color = "Danger",
    Callback = function()
        chatHistory = ""
        ChatDisplay:SetText("[Ace]: Terminal cleared.")
    end
})

-- ==========================================
-- [ INFORMATION TAB ]
-- ==========================================
TabInfo:AddLabel({
    Title = "Network Information",
    Text = "Client IP: " .. clientIP .. "\nExecutor: " .. executorName,
    Color = "Warning"
})

TabInfo:AddLabel({
    Title = "Player Data",
    Text = "Username: " .. player.Name .. 
           "\nUser ID: " .. userId .. 
           "\nAccount Age: " .. tostring(player.AccountAge) .. " days",
    Color = "White"
})

TabInfo:AddLabel({
    Title = "Game Data",
    Text = "Game ID: " .. tostring(game.PlaceId) .. 
           "\nJob ID: " .. tostring(game.JobId),
    Color = "White"
})

-- ==========================================
-- [ SETTINGS TAB ]
-- ==========================================
TabConfig:AddToggle({
    Title = "Developer Mode",
    Default = Settings.DevMode,
    Callback = function(state)
        Settings.DevMode = state
        if Settings.AutoSave then SaveSettings() end
    end
})

TabConfig:AddToggle({
    Title = "Auto-Save Configurations",
    Default = Settings.AutoSave,
    Callback = function(state)
        Settings.AutoSave = state
        SaveSettings()
    end
})

TabConfig:AddButton({
    Title = "Force Save Config",
    Color = "Success",
    Callback = function()
        SaveSettings()
        warn("[ACE] Configuration forcefully saved.")
    end
})

print("[ACE] Studio Lite AI System Loaded! Awaiting commands.")
