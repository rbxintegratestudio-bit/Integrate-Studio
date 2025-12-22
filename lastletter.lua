-- ============================================
-- INTEGRATE STUDIO - UNIVERSAL AUTHENTICATION
-- ============================================
local SCRIPT_NAME = "Last Letter Auto Fill"
local AUTH_TOKEN = _G.IntegrateStudioAuth
local VALID_TIMEOUT = 10

if not AUTH_TOKEN then
    warn(string.format("[%s] UNAUTHORIZED: No authentication token found!", SCRIPT_NAME))
    warn(string.format("[%s] This script can only be launched from Integrate Studio Hub.", SCRIPT_NAME))
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚠️ Authentication Failed",
        Text = SCRIPT_NAME .. " can only be launched from Integrate Studio Hub",
        Duration = 10
    })
    return
end

if type(AUTH_TOKEN) ~= "table" or not AUTH_TOKEN.timestamp or not AUTH_TOKEN.secret then
    warn(string.format("[%s] UNAUTHORIZED: Invalid authentication token!", SCRIPT_NAME))
    _G.IntegrateStudioAuth = nil
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚠️ Authentication Failed",
        Text = "Invalid authentication token",
        Duration = 10
    })
    return
end

local currentTime = os.time()
if (currentTime - AUTH_TOKEN.timestamp) > VALID_TIMEOUT then
    warn(string.format("[%s] UNAUTHORIZED: Authentication token expired!", SCRIPT_NAME))
    _G.IntegrateStudioAuth = nil
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚠️ Authentication Failed",
        Text = "Authentication token expired",
        Duration = 10
    })
    return
end

local EXPECTED_SECRET = "IntegrateStudio_v1_" .. tostring(game.PlaceId)
if AUTH_TOKEN.secret ~= EXPECTED_SECRET then
    warn(string.format("[%s] UNAUTHORIZED: Invalid secret!", SCRIPT_NAME))
    _G.IntegrateStudioAuth = nil
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚠️ Authentication Failed",
        Text = "Invalid authentication secret",
        Duration = 10
    })
    return
end

print(string.format("[%s] ✓ Authentication successful", SCRIPT_NAME))
_G.IntegrateStudioAuth = nil

-- ============================================
-- LAST LETTER AUTO FILL SCRIPT
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Dictionary
local dictionary = {}
local dictionaryLoaded = false

-- Auto fill settings
local autoFillEnabled = false
local isTyping = false

-- Load Dictionary
local function loadDictionary()
    print("[Last Letter] Loading dictionary...")
    
    local success, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words.txt")
    end)
    
    if success then
        for word in result:gmatch("[^\r\n]+") do
            word = word:lower():gsub("%s+", "")
            if #word >= 4 then
                table.insert(dictionary, word)
            end
        end
        
        dictionaryLoaded = true
        print(string.format("[Last Letter] Dictionary loaded: %d words", #dictionary))
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "✅ Dictionary Loaded",
            Text = string.format("%d words available", #dictionary),
            Duration = 3
        })
    else
        warn("[Last Letter] Failed to load dictionary:", result)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "❌ Dictionary Failed",
            Text = "Could not load word dictionary",
            Duration = 5
        })
    end
end

-- Get current letters
local function getCurrentLetters()
    local success, result = pcall(function()
        local inGame = playerGui:FindFirstChild("InGame")
        if not inGame then return nil end
        
        local frame = inGame:FindFirstChild("Frame")
        if not frame then return nil end
        
        local currentWord = frame:FindFirstChild("CurrentWord")
        if not currentWord then return nil end
        
        local letters = {}
        local children = currentWord:GetChildren()
        
        -- Sort by name (numerical)
        table.sort(children, function(a, b)
            local numA = tonumber(a.Name)
            local numB = tonumber(b.Name)
            if numA and numB then
                return numA < numB
            end
            return false
        end)
        
        for _, child in ipairs(children) do
            if child.Name ~= "Extra" and tonumber(child.Name) then
                local letter = child:FindFirstChild("Letter")
                if letter and letter:IsA("TextLabel") then
                    local letterText = letter.Text:lower()
                    if letterText ~= "" and letterText ~= " " then
                        table.insert(letters, letterText)
                    end
                end
            end
        end
        
        return table.concat(letters, "")
    end)
    
    if success then
        return result
    else
        warn("[Last Letter] Error getting letters:", result)
        return nil
    end
end

-- Find word
local function findWord(startsWith)
    if not dictionaryLoaded or #dictionary == 0 then
        return nil
    end
    
    local minLength = math.max(4, #startsWith)
    local validWords = {}
    
    for _, word in ipairs(dictionary) do
        if #word >= minLength then
            local wordStart = word:sub(1, #startsWith):lower()
            if wordStart == startsWith:lower() then
                table.insert(validWords, word)
            end
        end
    end
    
    if #validWords > 0 then
        return validWords[math.random(1, #validWords)]
    end
    
    return nil
end

-- Type text
local function typeText(text)
    if isTyping then return end
    isTyping = true
    
    local MAX_TIME = 15
    local TARGET_TIME_LEFT = math.random(5, 7)
    local timeToType = MAX_TIME - TARGET_TIME_LEFT
    local charDelay = timeToType / #text
    
    -- Add slight randomness to typing speed
    for i = 1, #text do
        local char = text:sub(i, i)
        
        -- Type the character
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[char:upper()] or char, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[char:upper()] or char, false, game)
        
        -- Wait with slight variation
        local variation = (math.random() - 0.5) * 0.1
        task.wait(charDelay + variation)
    end
    
    isTyping = false
end

-- Auto fill loop
local function autoFillLoop()
    while task.wait(0.5) do
        if autoFillEnabled and not isTyping and dictionaryLoaded then
            local letters = getCurrentLetters()
            
            if letters and #letters >= 1 then
                local word = findWord(letters)
                
                if word then
                    print(string.format("[Last Letter] Found word: %s (starts with '%s')", word, letters))
                    typeText(word)
                else
                    warn(string.format("[Last Letter] No word found starting with '%s'", letters))
                end
            end
        end
    end
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "LastLetterAutoFill"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 180)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(30,30,30)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(120,120,120)
main.Parent = gui

-- Drag functionality
local dragging, dragStart, startPos
local function setupDrag(dragHandle)
    dragHandle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)
    
    dragHandle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.Text = "Last Letter - Auto Fill"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundColor3 = Color3.fromRGB(40,40,40)
title.BorderSizePixel = 0
title.Parent = main
setupDrag(title)

-- Close button
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(24,24)
close.Position = UDim2.new(1,-8,0,5.5)
close.AnchorPoint = Vector2.new(1,0)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.BackgroundColor3 = Color3.fromRGB(180,40,40)
close.TextColor3 = Color3.new(1,1,1)
close.BorderSizePixel = 2
close.Parent = title

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Tab (Main)
local mainTab = Instance.new("Frame")
mainTab.Size = UDim2.new(1,-10,1,-45)
mainTab.Position = UDim2.fromOffset(5,40)
mainTab.BackgroundTransparency = 1
mainTab.Parent = main

-- Toggle Container
local toggleContainer = Instance.new("Frame")
toggleContainer.Size = UDim2.new(1,0,0,40)
toggleContainer.Position = UDim2.fromOffset(0,10)
toggleContainer.BackgroundTransparency = 1
toggleContainer.Parent = mainTab

-- Toggle Label
local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(0.7,0,1,0)
toggleLabel.Position = UDim2.fromOffset(10,0)
toggleLabel.Text = "Auto Fill Word"
toggleLabel.Font = Enum.Font.Gotham
toggleLabel.TextSize = 14
toggleLabel.TextColor3 = Color3.fromRGB(220,220,220)
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.BackgroundTransparency = 1
toggleLabel.Parent = toggleContainer

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(60,30)
toggleBtn.Position = UDim2.new(1,-10,0.5,0)
toggleBtn.AnchorPoint = Vector2.new(1,0.5)
toggleBtn.Text = "OFF"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
toggleBtn.BorderSizePixel = 2
toggleBtn.BorderColor3 = Color3.fromRGB(150,40,40)
toggleBtn.Parent = toggleContainer

toggleBtn.MouseButton1Click:Connect(function()
    autoFillEnabled = not autoFillEnabled
    
    if autoFillEnabled then
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50,180,50)
        toggleBtn.BorderColor3 = Color3.fromRGB(40,150,40)
    else
        toggleBtn.Text = "OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
        toggleBtn.BorderColor3 = Color3.fromRGB(150,40,40)
    end
end)

-- Current Letters Display
local displayLabel = Instance.new("TextLabel")
displayLabel.Size = UDim2.new(1,-20,0,80)
displayLabel.Position = UDim2.fromOffset(10,60)
displayLabel.Text = "Current Letters: [Waiting...]"
displayLabel.Font = Enum.Font.Code
displayLabel.TextSize = 13
displayLabel.TextColor3 = Color3.fromRGB(240,240,240)
displayLabel.TextWrapped = true
displayLabel.TextXAlignment = Enum.TextXAlignment.Left
displayLabel.TextYAlignment = Enum.TextYAlignment.Top
displayLabel.BackgroundColor3 = Color3.fromRGB(45,45,45)
displayLabel.BorderSizePixel = 2
displayLabel.BorderColor3 = Color3.fromRGB(70,70,70)
displayLabel.Parent = mainTab

local displayPad = Instance.new("UIPadding")
displayPad.PaddingTop = UDim.new(0,8)
displayPad.PaddingLeft = UDim.new(0,8)
displayPad.PaddingRight = UDim.new(0,8)
displayPad.Parent = displayLabel

-- Update display
task.spawn(function()
    while task.wait(0.5) do
        local letters = getCurrentLetters()
        
        if letters and #letters > 0 then
            displayLabel.Text = string.format("Current Letters: %s\n\nLength: %d characters", 
                letters:upper(), #letters)
        else
            displayLabel.Text = "Current Letters: [Waiting for game...]"
        end
    end
end)

-- Load dictionary and start
loadDictionary()
task.spawn(autoFillLoop)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "✅ Last Letter Loaded",
    Text = "Toggle Auto Fill to start",
    Duration = 5
})
