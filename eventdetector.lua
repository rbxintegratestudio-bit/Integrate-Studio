-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Check for required functions
local hasClipboard = pcall(function() return setclipboard end) and setclipboard ~= nil
local hasHookMeta = pcall(function() return hookmetamethod end) and hookmetamethod ~= nil

-- Data Storage
local eventData = {}
local allEvents = {}
local eventConnections = {}
local selectedEventKey = nil

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "EventMonitor"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(700, 550)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(30,30,30)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(120,120,120)
main.Parent = gui

-- Title Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.Text = "Event Monitor"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Center
title.BackgroundColor3 = Color3.fromRGB(40,40,40)
title.BorderSizePixel = 0
title.Parent = main

-- Drag functionality
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

-- Hub Button
local hubBtn = Instance.new("TextButton")
hubBtn.Size = UDim2.fromOffset(120,28)
hubBtn.Position = UDim2.new(1,-40,0,3.5)
hubBtn.AnchorPoint = Vector2.new(1,0)
hubBtn.Text = "Return to Hub"
hubBtn.Font = Enum.Font.GothamBold
hubBtn.TextSize = 13
hubBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
hubBtn.TextColor3 = Color3.new(1,1,1)
hubBtn.BorderSizePixel = 2
hubBtn.BorderColor3 = Color3.fromRGB(80,80,80)
hubBtn.Parent = title

-- Close Button
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28,28)
close.Position = UDim2.new(1,-6,0,3.5)
close.AnchorPoint = Vector2.new(1,0)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.BackgroundColor3 = Color3.fromRGB(180,40,40)
close.TextColor3 = Color3.new(1,1,1)
close.BorderSizePixel = 2
close.Parent = title
close.MouseButton1Click:Connect(function()
    for _, conn in pairs(eventConnections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    gui:Destroy()
end)

-- Tabs Bar
local tabsBar = Instance.new("Frame")
tabsBar.Size = UDim2.new(1,-10,0,35)
tabsBar.Position = UDim2.fromOffset(5,40)
tabsBar.BackgroundTransparency = 1
tabsBar.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0,6)
tabLayout.Parent = tabsBar

-- Search
local search = Instance.new("TextBox")
search.Size = UDim2.new(1,-10,0,35)
search.Position = UDim2.fromOffset(5,80)
search.PlaceholderText = "Search..."
search.Text = ""
search.ClearTextOnFocus = false
search.Font = Enum.Font.Gotham
search.TextSize = 14
search.TextColor3 = Color3.new(1,1,1)
search.PlaceholderColor3 = Color3.fromRGB(150,150,150)
search.BackgroundColor3 = Color3.fromRGB(45,45,45)
search.BorderSizePixel = 2
search.BorderColor3 = Color3.fromRGB(70,70,70)
search.Parent = main

-- Event List (Left Side)
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(0.52,-10,1,-125)
list.Position = UDim2.fromOffset(5,120)
list.ScrollBarThickness = 6
list.BackgroundColor3 = Color3.fromRGB(40,40,40)
list.BorderSizePixel = 2
list.BorderColor3 = Color3.fromRGB(70,70,70)
list.Parent = main

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0,6)
listPad.PaddingBottom = UDim.new(0,6)
listPad.PaddingLeft = UDim.new(0,4)
listPad.PaddingRight = UDim.new(0,4)
listPad.Parent = list

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,6)
layout.Parent = list

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 6)
end)

-- Details Panel (Right Side)
local detailsFrame = Instance.new("Frame")
detailsFrame.Size = UDim2.new(0.46,-10,0,225)
detailsFrame.Position = UDim2.new(0.54,5,0,120)
detailsFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
detailsFrame.BorderSizePixel = 2
detailsFrame.BorderColor3 = Color3.fromRGB(70,70,70)
detailsFrame.Parent = main

local detailsTitle = Instance.new("TextLabel")
detailsTitle.Size = UDim2.new(1,0,0,30)
detailsTitle.Text = "Event Details"
detailsTitle.Font = Enum.Font.GothamBold
detailsTitle.TextSize = 14
detailsTitle.TextColor3 = Color3.fromRGB(220,220,220)
detailsTitle.BackgroundTransparency = 1
detailsTitle.TextXAlignment = Enum.TextXAlignment.Left
detailsTitle.Parent = detailsFrame

local detailsTitlePad = Instance.new("UIPadding")
detailsTitlePad.PaddingLeft = UDim.new(0,10)
detailsTitlePad.Parent = detailsTitle

local detailsText = Instance.new("TextBox")
detailsText.Size = UDim2.new(1,-10,1,-35)
detailsText.Position = UDim2.fromOffset(5,30)
detailsText.BackgroundColor3 = Color3.fromRGB(50,50,50)
detailsText.TextColor3 = Color3.fromRGB(240,240,240)
detailsText.TextSize = 12
detailsText.Font = Enum.Font.Code
detailsText.Text = "Select an event to view details..."
detailsText.TextWrapped = true
detailsText.TextXAlignment = Enum.TextXAlignment.Left
detailsText.TextYAlignment = Enum.TextYAlignment.Top
detailsText.ClearTextOnFocus = false
detailsText.MultiLine = true
detailsText.BorderSizePixel = 0
detailsText.Parent = detailsFrame

local detailsPad = Instance.new("UIPadding")
detailsPad.PaddingTop = UDim.new(0,4)
detailsPad.PaddingLeft = UDim.new(0,6)
detailsPad.PaddingRight = UDim.new(0,6)
detailsPad.Parent = detailsText

-- Action Buttons
local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(0.46,-10,0,165)
btnFrame.Position = UDim2.new(0.54,5,0,355)
btnFrame.BackgroundTransparency = 1
btnFrame.Parent = main

local btnLayout = Instance.new("UIListLayout")
btnLayout.Padding = UDim.new(0,9)
btnLayout.Parent = btnFrame

local function makeActionButton(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,32)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = Color3.fromRGB(100,100,100)
    btn.Parent = btnFrame
    return btn
end

local copyArgsBtn = makeActionButton("📋 Copy Arguments")
local executeBtn = makeActionButton("▶️ Execute Event")
local copyPathBtn = makeActionButton("📍 Copy Path")
local genLoopBtn = makeActionButton("🔄 Generate Loop")

-- Active buttons tracking
local activeButtons = {}

local function clearButtons()
    for _,v in ipairs(activeButtons) do
        v.Button:Destroy()
    end
    table.clear(activeButtons)
end

local function makeEventButton(text, key, count)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,45)
    btn.Text = string.format("(%d) %s", count or 0, text)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(240,240,240)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = Color3.fromRGB(70,70,70)
    btn.Parent = list

    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0,10)
    p.Parent = btn

    table.insert(activeButtons, {Button=btn, Name=text:lower(), Key=key})
    return btn
end

-- Notification system
local NOTIF_WIDTH = 250
local NOTIF_HEIGHT = 50
local NOTIF_GAP = 8
local NOTIF_DURATION = 4

local activeNotifs = {}

local function repositionNotifications()
    for i, nf in ipairs(activeNotifs) do
        local targetY = 10 + (i - 1) * (NOTIF_HEIGHT + NOTIF_GAP)
        TweenService:Create(nf, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
            {Position = UDim2.new(1, -10, 0, targetY)}):Play()
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
    lab.Font = Enum.Font.Gotham
    lab.TextSize = 13
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.TextYAlignment = Enum.TextYAlignment.Center
    lab.TextColor3 = Color3.fromRGB(240,240,240)
    lab.Text = message
    lab.TextWrapped = true
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

    TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
        {Position = UDim2.new(1,-10,0,y)}):Play()
    
    local tween = TweenService:Create(progress, TweenInfo.new(NOTIF_DURATION, Enum.EasingStyle.Linear), 
        {Size = UDim2.new(1,0,1,0)})
    tween:Play()
    tween.Completed:Connect(function()
        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), 
            {Position = UDim2.new(1, NOTIF_WIDTH+10, 0, notif.Position.Y.Offset)})
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

-- Confirmation Dialog
local function showConfirmation(message, onConfirm, onCancel)
    -- Create darkened overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "ConfirmOverlay"
    overlay.Size = UDim2.new(1,0,1,0)
    overlay.Position = UDim2.new(0,0,0,0)
    overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 100
    overlay.Parent = gui

    -- Create confirmation box
    local confirmBox = Instance.new("Frame")
    confirmBox.Size = UDim2.fromOffset(350, 150)
    confirmBox.Position = UDim2.fromScale(0.5, 0.5)
    confirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
    confirmBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    confirmBox.BorderSizePixel = 2
    confirmBox.BorderColor3 = Color3.fromRGB(120,120,120)
    confirmBox.ZIndex = 101
    confirmBox.Parent = overlay

    -- Title
    local confirmTitle = Instance.new("TextLabel")
    confirmTitle.Size = UDim2.new(1,0,0,40)
    confirmTitle.Text = "⚠️ Confirmation"
    confirmTitle.Font = Enum.Font.GothamBold
    confirmTitle.TextSize = 16
    confirmTitle.TextColor3 = Color3.fromRGB(255,255,255)
    confirmTitle.BackgroundColor3 = Color3.fromRGB(50,50,50)
    confirmTitle.BorderSizePixel = 0
    confirmTitle.ZIndex = 102
    confirmTitle.Parent = confirmBox

    -- Message
    local confirmMsg = Instance.new("TextLabel")
    confirmMsg.Size = UDim2.new(1,-20,0,50)
    confirmMsg.Position = UDim2.fromOffset(10,50)
    confirmMsg.Text = message
    confirmMsg.Font = Enum.Font.Gotham
    confirmMsg.TextSize = 14
    confirmMsg.TextColor3 = Color3.fromRGB(220,220,220)
    confirmMsg.TextWrapped = true
    confirmMsg.BackgroundTransparency = 1
    confirmMsg.ZIndex = 102
    confirmMsg.Parent = confirmBox

    -- Buttons container
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1,-20,0,40)
    btnContainer.Position = UDim2.fromOffset(10,100)
    btnContainer.BackgroundTransparency = 1
    btnContainer.ZIndex = 102
    btnContainer.Parent = confirmBox

    -- Yes button
    local yesBtn = Instance.new("TextButton")
    yesBtn.Size = UDim2.new(0.48,0,1,0)
    yesBtn.Position = UDim2.new(0,0,0,0)
    yesBtn.Text = "✓ Yes"
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.TextSize = 14
    yesBtn.TextColor3 = Color3.new(1,1,1)
    yesBtn.BackgroundColor3 = Color3.fromRGB(50,180,50)
    yesBtn.BorderSizePixel = 2
    yesBtn.BorderColor3 = Color3.fromRGB(70,200,70)
    yesBtn.ZIndex = 103
    yesBtn.Parent = btnContainer

    -- No button
    local noBtn = Instance.new("TextButton")
    noBtn.Size = UDim2.new(0.48,0,1,0)
    noBtn.Position = UDim2.new(0.52,0,0,0)
    noBtn.Text = "✗ No"
    noBtn.Font = Enum.Font.GothamBold
    noBtn.TextSize = 14
    noBtn.TextColor3 = Color3.new(1,1,1)
    noBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
    noBtn.BorderSizePixel = 2
    noBtn.BorderColor3 = Color3.fromRGB(200,70,70)
    noBtn.ZIndex = 103
    noBtn.Parent = btnContainer

    yesBtn.MouseButton1Click:Connect(function()
        overlay:Destroy()
        if onConfirm then onConfirm() end
    end)

    noBtn.MouseButton1Click:Connect(function()
        overlay:Destroy()
        if onCancel then onCancel() end
    end)
end

-- Utility Functions
local function safeCopy(text)
    if hasClipboard then
        local success = pcall(function()
            setclipboard(text)
        end)
        return success
    end
    return false
end

local function serializeValue(v, depth)
    depth = depth or 0
    if depth > 5 then return "..." end

    local t = typeof(v)

    if t == "string" then
        return string.format("%q", v)
    elseif t == "number" then
        return tostring(v)
    elseif t == "boolean" or t == "nil" then
        return tostring(v)
    elseif t == "table" then
        local items = {}
        local count = 0
        for key, val in pairs(v) do
            count = count + 1
            if count > 10 then
                table.insert(items, "...")
                break
            end
            table.insert(items, string.format("[%s]=%s", serializeValue(key, depth+1), serializeValue(val, depth+1)))
        end
        return "{" .. table.concat(items, ", ") .. "}"
    elseif t == "Instance" then
        local success, name = pcall(function() return v.Name end)
        local className = pcall(function() return v.ClassName end) and v.ClassName or "Instance"
        if success and name then
            return string.format("%s (%s)", name, className)
        else
            return string.format("<%s>", className)
        end
    elseif t == "Vector3" then
        return string.format("Vector3.new(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
    elseif t == "Vector2" then
        return string.format("Vector2.new(%.2f, %.2f)", v.X, v.Y)
    elseif t == "CFrame" then
        local pos = v.Position
        return string.format("CFrame.new(%.2f, %.2f, %.2f, ...)", pos.X, pos.Y, pos.Z)
    elseif t == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)", 
            math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255))
    elseif t == "EnumItem" then
        return tostring(v)
    else
        return string.format("<%s>", t)
    end
end

local function serializeArgs(args)
    if not args or #args == 0 then return "No arguments" end

    local serialized = {}
    for i, arg in ipairs(args) do
        local success, result = pcall(function()
            return serializeValue(arg)
        end)
        if success then
            table.insert(serialized, string.format("[%d]: %s", i, result))
        else
            table.insert(serialized, string.format("[%d]: <error>", i))
        end
    end
    return table.concat(serialized, "\n")
end

local function findEventByPath(path)
    if not path then return nil end

    local success, obj = pcall(function()
        local parts = {}
        for part in string.gmatch(path, "[^%.]+") do
            table.insert(parts, part)
        end

        local current = game
        for _, part in ipairs(parts) do
            if part ~= "game" then
                current = current:FindFirstChild(part)
                if not current then return nil end
            end
        end
        return current
    end)

    return success and obj or nil
end

-- Event Tracking
local function trackEvent(eventName, eventPath, args, direction)
    local uniqueKey = eventPath or eventName

    if not eventData[uniqueKey] then
        eventData[uniqueKey] = {
            name = eventName,
            count = 0,
            path = eventPath,
            lastArgs = {},
            directions = {},
            lastTime = os.clock()
        }
    end

    local data = eventData[uniqueKey]
    data.count = data.count + 1
    data.lastArgs = args or {}
    data.lastTime = os.clock()

    if direction then
        if not data.directions[direction] then
            data.directions[direction] = 0
        end
        data.directions[direction] = data.directions[direction] + 1
    end

    -- Update button if exists
    for _, v in ipairs(activeButtons) do
        if v.Key == uniqueKey then
            v.Button.Text = string.format("(%d) %s", data.count, data.name)
            break
        end
    end
end

-- Tab Loaders
local function loadEventDetection()
    clearButtons()
    
    if next(eventData) == nil then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1,0,0,100)
        emptyLabel.Text = "Waiting for events...\nEvents will appear here\nwhen they are triggered."
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 14
        emptyLabel.TextColor3 = Color3.fromRGB(180,180,180)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.TextYAlignment = Enum.TextYAlignment.Top
        emptyLabel.Parent = list
        table.insert(activeButtons, {Button=emptyLabel, Name="", Key=""})
        return
    end

    for key, data in pairs(eventData) do
        local btn = makeEventButton(data.name, key, data.count)
        
        btn.MouseButton1Click:Connect(function()
            selectedEventKey = key
            
            local dirInfo = ""
            for dir, cnt in pairs(data.directions) do
                dirInfo = dirInfo .. string.format("\n%s: %d times", dir, cnt)
            end

            detailsText.Text = string.format(
                "Event: %s\n\nPath: %s\n\nFired: %d times%s\n\nLast Arguments:\n%s",
                data.name, data.path, data.count, dirInfo, serializeArgs(data.lastArgs)
            )

            for _, v in ipairs(activeButtons) do
                v.Button.BackgroundColor3 = Color3.fromRGB(50,50,50)
            end
            btn.BackgroundColor3 = Color3.fromRGB(70,130,180)
        end)
    end
end

local function loadEventList()
    clearButtons()
    
    -- Collect all events
    allEvents = {}
    for _, desc in pairs(game:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") or desc:IsA("BindableEvent") then
            table.insert(allEvents, desc)
        end
    end

    if #allEvents == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1,0,0,100)
        emptyLabel.Text = "No events found in the game."
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 14
        emptyLabel.TextColor3 = Color3.fromRGB(180,180,180)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Parent = list
        table.insert(activeButtons, {Button=emptyLabel, Name="", Key=""})
        return
    end

    for _, event in ipairs(allEvents) do
        local success, name, path = pcall(function()
            return event.Name, event:GetFullName()
        end)
        
        if success then
            local count = 0
            if eventData[path] then
                count = eventData[path].count
            end
            
            local btn = makeEventButton(name, path, count)
            
            btn.MouseButton1Click:Connect(function()
                selectedEventKey = path
                
                local countText = count > 0 and string.format("\n\nFired: %d times", count) or "\n\nNot fired yet"
                local argsText = "No arguments captured"
                local dirInfo = ""
                
                if eventData[path] then
                    argsText = serializeArgs(eventData[path].lastArgs)
                    for dir, cnt in pairs(eventData[path].directions) do
                        dirInfo = dirInfo .. string.format("\n%s: %d times", dir, cnt)
                    end
                end

                detailsText.Text = string.format(
                    "Event: %s\n\nPath: %s\n\nType: %s%s%s\n\nLast Arguments:\n%s",
                    name, path, event.ClassName, countText, dirInfo, argsText
                )

                for _, v in ipairs(activeButtons) do
                    v.Button.BackgroundColor3 = Color3.fromRGB(50,50,50)
                end
                btn.BackgroundColor3 = Color3.fromRGB(70,130,180)
            end)
        end
    end
end

-- Create Tabs
local currentTab = nil

local function makeTab(name, callback)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.fromOffset(130,32)
    tab.Text = name
    tab.Font = Enum.Font.GothamBold
    tab.TextSize = 14
    tab.TextColor3 = Color3.new(1,1,1)
    tab.BackgroundColor3 = Color3.fromRGB(45,45,45)
    tab.BorderSizePixel = 2
    tab.BorderColor3 = Color3.fromRGB(70,70,70)
    tab.Parent = tabsBar
    
    tab.MouseButton1Click:Connect(function()
        currentTab = name
        callback()
        
        for _, v in ipairs(tabsBar:GetChildren()) do
            if v:IsA("TextButton") then
                v.BackgroundColor3 = Color3.fromRGB(45,45,45)
            end
        end
        tab.BackgroundColor3 = Color3.fromRGB(60,100,140)
    end)
    
    if not currentTab then
        currentTab = name
        callback()
        tab.BackgroundColor3 = Color3.fromRGB(60,100,140)
    end
end

makeTab("Event Detection", loadEventDetection)
makeTab("Event List", loadEventList)

-- Search functionality
search:GetPropertyChangedSignal("Text"):Connect(function()
    local t = search.Text:lower()
    for _, v in ipairs(activeButtons) do
        if v.Button and v.Button:IsA("TextButton") then
            v.Button.Visible = v.Name:find(t, 1, true) ~= nil
        end
    end
end)

-- Button Actions
copyArgsBtn.MouseButton1Click:Connect(function()
    if not selectedEventKey or not eventData[selectedEventKey] then
        createNotification("No event selected or no data")
        return
    end

    local argText = serializeArgs(eventData[selectedEventKey].lastArgs)
    if safeCopy(argText) then
        createNotification("Copied arguments!")
    else
        createNotification("Clipboard not available")
    end
end)

executeBtn.MouseButton1Click:Connect(function()
    if not selectedEventKey then
        createNotification("No event selected")
        return
    end

    local obj = findEventByPath(selectedEventKey)
    if not obj then
        createNotification("Could not find event object")
        return
    end

    local args = eventData[selectedEventKey] and eventData[selectedEventKey].lastArgs or {}
    
    local success, err = pcall(function()
        if obj:IsA("RemoteEvent") then
            obj:FireServer(table.unpack(args))
            createNotification("Executed RemoteEvent")
        elseif obj:IsA("RemoteFunction") then
            obj:InvokeServer(table.unpack(args))
            createNotification("Invoked RemoteFunction")
        elseif obj:IsA("BindableEvent") then
            obj:Fire(table.unpack(args))
            createNotification("Fired BindableEvent")
        else
            createNotification("Not a valid event type")
        end
    end)

    if not success then
        createNotification("Execution failed: " .. tostring(err))
    end
end)

copyPathBtn.MouseButton1Click:Connect(function()
    if not selectedEventKey then
        createNotification("No event selected")
        return
    end

    if safeCopy(selectedEventKey) then
        createNotification("Copied path!")
    else
        createNotification("Clipboard not available")
    end
end)

genLoopBtn.MouseButton1Click:Connect(function()
    if not selectedEventKey then
        createNotification("No event selected")
        return
    end

    local data = eventData[selectedEventKey]
    local eventName = data and data.name or selectedEventKey
    local args = data and data.lastArgs or {}

    local argsStr = ""
    if #args > 0 then
        local serializedArgs = {}
        for _, arg in ipairs(args) do
            local success, result = pcall(function()
                return serializeValue(arg)
            end)
            if success then
                table.insert(serializedArgs, result)
            end
        end
        argsStr = table.concat(serializedArgs, ", ")
    end

    local obj = findEventByPath(selectedEventKey)
    local eventType = obj and obj.ClassName or "RemoteEvent"

    local scriptText = string.format([[-- Loop for %s
local path = "%s"
local event = game:FindFirstChild(path, true)

if not event then
    warn("Event not found:", path)
    return
end

while task.wait(1) do
    pcall(function()
        if event:IsA("RemoteEvent") then
            event:FireServer(%s)
        elseif event:IsA("RemoteFunction") then
            event:InvokeServer(%s)
        elseif event:IsA("BindableEvent") then
            event:Fire(%s)
        end
        print("Fired:", event.Name)
    end)
end]], eventName, selectedEventKey, argsStr, argsStr, argsStr)

    if safeCopy(scriptText) then
        createNotification("Loop script copied!")
    else
        createNotification("Clipboard not available")
    end
end)

hubBtn.MouseButton1Click:Connect(function()
    showConfirmation("Are you sure you want to return to the hub?\nThis will close the Event Monitor.", function()
        -- User confirmed
        for _, conn in pairs(eventConnections) do
            if conn and conn.Disconnect then
                pcall(function() conn:Disconnect() end)
            end
        end
        
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/rbxintegratestudio-bit/Integrate-Studio/refs/heads/main/mainhub.lua"))()
        end)
        
        if not success then
            createNotification("Failed to load hub")
            warn("[EventMonitor] Hub load error:", err)
        end
        
        gui:Destroy()
    end, function()
        -- User cancelled
        createNotification("Cancelled return to hub")
    end)
end)

-- Hook Events
local function hookEvent(obj)
    if not obj then return end

    local success = pcall(function()
        if obj:IsA("RemoteEvent") then
            local conn = obj.OnClientEvent:Connect(function(...)
                trackEvent(obj.Name, obj:GetFullName(), {...}, "Server→Client")
                if currentTab == "Event Detection" then
                    task.defer(loadEventDetection)
                end
            end)
            table.insert(eventConnections, conn)

        elseif obj:IsA("BindableEvent") then
            local conn = obj.Event:Connect(function(...)
                trackEvent(obj.Name, obj:GetFullName(), {...}, "Internal")
                if currentTab == "Event Detection" then
                    task.defer(loadEventDetection)
                end
            end)
            table.insert(eventConnections, conn)
        end
    end)
end

-- Hook existing events
print("[EventMonitor] Hooking events...")
local hookedCount = 0
for _, desc in pairs(game:GetDescendants()) do
    if desc:IsA("RemoteEvent") or desc:IsA("BindableEvent") then
        hookEvent(desc)
        hookedCount = hookedCount + 1
    end
end
print(string.format("[EventMonitor] Hooked %d events", hookedCount))

-- Hook future events
game.DescendantAdded:Connect(function(desc)
    if desc:IsA("RemoteEvent") or desc:IsA("BindableEvent") then
        task.wait()
        hookEvent(desc)
    end
end)

-- Namecall hook
if hasHookMeta then
    print("[EventMonitor] Setting up namecall hook...")
    local success = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if method == "FireServer" and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
                pcall(function()
                    trackEvent(self.Name, self:GetFullName(), args, "Client→Server")
                    if currentTab == "Event Detection" then
                        task.defer(loadEventDetection)
                    end
                end)
            elseif method == "InvokeServer" and typeof(self) == "Instance" and self:IsA("RemoteFunction") then
                pcall(function()
                    trackEvent(self.Name, self:GetFullName(), args, "Client→Server (Invoke)")
                    if currentTab == "Event Detection" then
                        task.defer(loadEventDetection)
                    end
                end)
            elseif method == "Fire" and typeof(self) == "Instance" and self:IsA("BindableEvent") then
                pcall(function()
                    trackEvent(self.Name, self:GetFullName(), args, "Internal Fire")
                    if currentTab == "Event Detection" then
                        task.defer(loadEventDetection)
                    end
                end)
            end

            return oldNamecall(self, ...)
        end)
    end)

    if success then
        print("[EventMonitor] Namecall hook active")
    else
        warn("[EventMonitor] Failed to setup namecall hook")
    end
else
    warn("[EventMonitor] hookmetamethod not available")
end

if not hasClipboard then
    warn("[EventMonitor] Clipboard not available")
end
