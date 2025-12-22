-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- DATA TABLES
local Games = {
    {
        Name = "Last Letter",
        PlaceId = 129866685202296, -- make sure this is accessible
        Loadstring = "print('Loaded Game Script')"
    }
}

local Global = {
    -- leave empty to hide tab
}

-- CONTACT INFO
local CONTACT_GMAIL = "rbxintegratestudio@gmail.com"
local DISCORD_INVITE = "https://discord.gg/sjW4DkYp"

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "PixelGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(400, 500)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(30,30,30)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(120,120,120)
main.Parent = gui

-- Title Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.Text = "Integrate Studio"
title.Font = Enum.Font.Code
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Center
title.BackgroundColor3 = Color3.fromRGB(40,40,40)
title.BorderSizePixel = 0
title.Parent = main

-- Drag
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
    end
end)
title.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

-- Close Button
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(24,24)
close.Position = UDim2.new(1,-4,0,3)
close.AnchorPoint = Vector2.new(1,0)
close.Text = "X"
close.Font = Enum.Font.Code
close.TextSize = 14
close.BackgroundColor3 = Color3.fromRGB(180,40,40)
close.TextColor3 = Color3.new(1,1,1)
close.BorderSizePixel = 2
close.Parent = title
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Tabs Bar
local tabsBar = Instance.new("Frame")
tabsBar.Size = UDim2.new(1,-10,0,30)
tabsBar.Position = UDim2.fromOffset(5,35)
tabsBar.BackgroundTransparency = 1
tabsBar.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0,6)
tabLayout.Parent = tabsBar

-- Search
local search = Instance.new("TextBox")
search.Size = UDim2.new(1,-10,0,32)
search.Position = UDim2.fromOffset(5,70)
search.PlaceholderText = "Search..."
search.Text = ""
search.ClearTextOnFocus = false
search.Font = Enum.Font.Code
search.TextSize = 14
search.TextColor3 = Color3.new(1,1,1)
search.BackgroundColor3 = Color3.fromRGB(45,45,45)
search.BorderSizePixel = 2
search.Parent = main

-- List
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1,-10,1,-115)
list.Position = UDim2.fromOffset(5,110)
list.ScrollBarThickness = 6
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.Parent = main

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0,6)
pad.PaddingBottom = UDim.new(0,6)
pad.PaddingLeft = UDim.new(0,4)
pad.PaddingRight = UDim.new(0,4)
pad.Parent = list

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,6)
layout.Parent = list

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 6)
end)

-- Button State
local activeButtons = {}

local function clearButtons()
    for _,v in ipairs(activeButtons) do
        v.Button:Destroy()
    end
    table.clear(activeButtons)
end

local function makeButton(text, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,height or 40)
    btn.Text = text
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.BorderSizePixel = 2
    btn.Parent = list

    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0,8)
    p.Parent = btn

    table.insert(activeButtons,{Button=btn,Name=text:lower()})
    return btn
end

-- === Notification system (side notifications with vertical progress bar) ===
local NOTIF_WIDTH = 250
local NOTIF_HEIGHT = 50
local NOTIF_GAP = 8
local NOTIF_DURATION = 4 -- seconds until progress completes

local activeNotifs = {}

local function repositionNotifications()
    for i, nf in ipairs(activeNotifs) do
        local targetY = 10 + (i - 1) * (NOTIF_HEIGHT + NOTIF_GAP)
        TweenService:Create(nf, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(1, -10, 0, targetY)}):Play()
    end
end

local function createNotification(message)
    local y = 10 + #activeNotifs * (NOTIF_HEIGHT + NOTIF_GAP)

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT)
    notif.Position = UDim2.new(1, NOTIF_WIDTH + 10, 0, y)
    notif.AnchorPoint = Vector2.new(1, 0)
    notif.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notif.BorderSizePixel = 2
    notif.BorderColor3 = Color3.fromRGB(100,100,100)
    notif.ZIndex = 10
    notif.Parent = gui

    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, -10, 1, 0)
    lab.Position = UDim2.new(0,5,0,0)
    lab.BackgroundTransparency = 1
    lab.Font = Enum.Font.Code
    lab.TextSize = 14
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.TextYAlignment = Enum.TextYAlignment.Center
    lab.TextColor3 = Color3.new(1,1,1)
    lab.Text = message
    lab.ZIndex = 11
    lab.Parent = notif

    local progressHolder = Instance.new("Frame")
	progressHolder.Size = UDim2.new(0.03,0,1,-4)
	progressHolder.Position = UDim2.new(1,-6,0,2)
    progressHolder.AnchorPoint = Vector2.new(1,0)
    progressHolder.BackgroundColor3 = Color3.fromRGB(65,65,65)
    progressHolder.BorderSizePixel = 0
    progressHolder.ZIndex = 11
    progressHolder.Parent = notif

    local progress = Instance.new("Frame")
    progress.AnchorPoint = Vector2.new(0,1)
    progress.Position = UDim2.new(0,0,1,0)
    progress.Size = UDim2.new(1,0,0,0)
    progress.BackgroundColor3 = Color3.fromRGB(255,255,255)
    progress.BorderSizePixel = 0
    progress.ZIndex = 12
    progress.Parent = progressHolder

    table.insert(activeNotifs, notif)
    repositionNotifications()

    TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(1,-10,0,y)}):Play()
    
    local tween = TweenService:Create(progress, TweenInfo.new(NOTIF_DURATION, Enum.EasingStyle.Linear), {Size = UDim2.new(1,0,1,0)})
    tween:Play()
    tween.Completed:Connect(function()
        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.new(1, NOTIF_WIDTH+10, 0, notif.Position.Y.Offset)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            for i,v in ipairs(activeNotifs) do
                if v == notif then table.remove(activeNotifs,i); break end
            end
            notif:Destroy()
            repositionNotifications()
        end)
    end)
end

-- Tabs Loaders
local function loadGames()
    clearButtons()
    search.Visible = true
    list.Position = UDim2.fromOffset(5,110)
    list.Size = UDim2.new(1,-10,1,-115)
    for _,info in ipairs(Games) do
        local btn = makeButton(info.Name)
        btn.MouseButton1Click:Connect(function()
            if game.PlaceId == info.PlaceId then
                local ok,err = pcall(function() loadstring(info.Loadstring)() end)
                if not ok then createNotification("Error running script for "..info.Name) end
            else
                createNotification("You are not in "..info.Name)
            end
        end)
    end
end

local function loadGlobal()
    clearButtons()
    search.Visible = true
    list.Position = UDim2.fromOffset(5,110)
    list.Size = UDim2.new(1,-10,1,-115)
    for _,info in ipairs(Global) do
        local btn = makeButton(info.Name)
        btn.MouseButton1Click:Connect(function()
            local ok,err = pcall(function() loadstring(info.Loadstring)() end)
            if not ok then createNotification("Error running global script") end
        end)
    end
end

local function loadContact()
    clearButtons()
    search.Visible = false
    list.Position = UDim2.fromOffset(5,70)
    list.Size = UDim2.new(1,-10,1,-100)

    local gmail = makeButton("Gmail: "..CONTACT_GMAIL,50)
    local gHint = Instance.new("TextLabel")
    gHint.Size = UDim2.new(1,-14,0,12)
    gHint.Position = UDim2.new(0,7,1,-14)
    gHint.BackgroundTransparency = 1
    gHint.Text = "Click to copy"
    gHint.Font = Enum.Font.Code
    gHint.TextSize = 11
    gHint.TextColor3 = Color3.fromRGB(170,170,170)
    gHint.TextXAlignment = Enum.TextXAlignment.Right
    gHint.Parent = gmail

    gmail.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(CONTACT_GMAIL) end
        createNotification("Copied Gmail")
    end)

    local discord = makeButton("Discord: "..DISCORD_INVITE,50)
    local dHint = Instance.new("TextLabel")
    dHint.Size = UDim2.new(1,-14,0,12)
    dHint.Position = UDim2.new(0,7,1,-14)
    dHint.BackgroundTransparency = 1
    dHint.Text = "Click to copy"
    dHint.Font = Enum.Font.Code
    dHint.TextSize = 11
    dHint.TextColor3 = Color3.fromRGB(170,170,170)
    dHint.TextXAlignment = Enum.TextXAlignment.Right
    dHint.Parent = discord

    discord.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(DISCORD_INVITE) end
        createNotification("Copied Discord invite")
    end)
end

-- Create Tabs
local first = true
local function makeTab(name, callback)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.fromOffset(90,28)
    tab.Text = name
    tab.Font = Enum.Font.Code
    tab.TextSize = 14
    tab.TextColor3 = Color3.new(1,1,1)
    tab.BackgroundColor3 = Color3.fromRGB(45,45,45)
    tab.BorderSizePixel = 2
    tab.Parent = tabsBar
    tab.MouseButton1Click:Connect(callback)

    if first then
        callback()
        first = false
    end
end

if #Games > 0 then makeTab("Games", loadGames) end
if #Global > 0 then makeTab("Global", loadGlobal) end
makeTab("Contact", loadContact)

-- Search functionality
search:GetPropertyChangedSignal("Text"):Connect(function()
    local t = search.Text:lower()
    for _,v in ipairs(activeButtons) do
        v.Button.Visible = v.Name:find(t) ~= nil
    end
end)
