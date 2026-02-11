print("By: ainh01")


local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local TimeService = require(ReplicatedStorage.Shared.Framework.Utilities.Math.Time)
local LocalDataBubbleGame = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local PlaytimeData = require(ReplicatedStorage.Shared.Data.Playtime)

local ShopUtil = require(ReplicatedStorage.Shared.Utils.ShopUtil)

local screenGuiClaw = game:GetService('Players').LocalPlayer:WaitForChild(
    'PlayerGui'
).ScreenGui

local playerGui = player:WaitForChild("PlayerGui")
local mainColor = Color3.fromRGB(41, 74, 122)  
local secondaryColor = Color3.fromRGB(33, 34, 36)  
local textColor = Color3.fromRGB(255, 255, 255)  

local config = {
    autoBubble = false,
    autoClaw = false,
    autoBoard = false,
    autoCard = false,
    autoCart = false,
    autoClose = false,
    autoSell = false,
    autoSellDelay = 15,
    autoCollect = false,
    collectionRange = 55,
    collectionDelay = 0.15,
    
    autoGiantChest = false,
    autoVoidChest = false,
    autoFreeSpin = false,
    autoDogJump = false,
    autoPlaytime = false,
    
    autoAlienMerchant = false,
    autoBackMerchant = false,
    
    guiTransparency = 0,
    windowPosition = UDim2.new(0.5, -250, 0.5, -250),
    minimized = false,
    
    selectedIsland = nil,
    isFlying = false
}

local threads = {
    autoBubble = nil,
    autoClaw = nil,
    autoBoard = nil,
    autoCard = nil,
    autoCart = nil,
    autoClose = nil,
    autoSell = nil,
    autoCollect = nil,
    autoGiantChest = nil,
    autoVoidChest = nil,
    autoFreeSpin = nil,
    autoDogJump = nil,
    autoPlaytime = nil,
    autoAlienMerchant = nil,
    autoBackMerchant = nil,
    islandUpdater = nil
}

local function click(button)
    if not button then return end
    button:SetAttribute('Pressed', true)
    task.wait(0.1)
    button:SetAttribute('Pressed', false)
end

local function safeClickButton()
    
    local Players = game:GetService("Players")
    
    
    if not Players then
        return false
    end
    
    
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        return false
    end
    
    
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then
        return false
    end
    
    
    local ScreenGui = PlayerGui:FindFirstChild("ScreenGui")
    if not ScreenGui then
        return false
    end
    
    
    local Prompt = ScreenGui:FindFirstChild("Prompt")
    if not Prompt then
        return false
    end
    
    
    local Frame = Prompt:FindFirstChild("Frame")
    if not Frame then
        return false
    end
    
    
    local Main = Frame:FindFirstChild("Main")
    if not Main then
        return false
    end
    
    
    local Buttons = Main:FindFirstChild("Buttons")
    if not Buttons then
        return false
    end
    
    
    local Template = Buttons:FindFirstChild("Template")
    if not Template then
        return false
    end
    
    
    local Button = Template:FindFirstChild("Button")
    if not Button then
        return false
    end
    
    
    click(Button)
    return true
end




local function saveConfig()
    local success, errorMsg = pcall(function()
        if writefile then
            writefile("bubbleSimConfig.json", game:GetService("HttpService"):JSONEncode(config))
        end
    end)
    
    if not success then
    end
end

local function loadConfig()
    local success, result = pcall(function()
        if readfile and isfile and isfile("bubbleSimConfig.json") then
            return game:GetService("HttpService"):JSONDecode(readfile("bubbleSimConfig.json"))
        end
        return nil
    end)
    
    if success and result then
        for key, value in pairs(result) do
            if key == "collectionDelay" then
                config[key] = math.clamp(value, 0.1, 1.0)
            else
                config[key] = value
            end
        end
    end
    config.isFlying = false
end

loadConfig()

local function formatIslandName(name)
    local formatted = name:gsub("%-", " ")
    
    formatted = formatted:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest
    end)
    
    return formatted
end

local function extractLuckMultiplier(luckText)
    local multiplier = luckText:match("x(%d+)")
    return multiplier and tonumber(multiplier) or 0
end

local function extractTimeInSeconds(timeText)
    if not timeText or timeText == "" then
        return 0
    end
    
    local minutes = timeText:match("(%d+)%s*m")
    local seconds = timeText:match("(%d+)%s*s")
    
    local totalSeconds = 0
    if minutes then
        totalSeconds = totalSeconds + tonumber(minutes) * 60
    end
    if seconds then
        totalSeconds = totalSeconds + tonumber(seconds)
    end
    
    return totalSeconds
end

function TeleportRemoteFunction(world)
    local remote = ReplicatedStorage:WaitForChild('Shared'):WaitForChild('Framework'):WaitForChild('Network'):WaitForChild('Remote'):WaitForChild('Event')
    local args = {
        'Teleport',
        world,
    }
    return remote:FireServer(unpack(args))
end

local function getSpecialIslands()
    local islands = {}
    local rifts = workspace:FindFirstChild("Rendered"):FindFirstChild("Rifts")
    
    if not rifts then
        return islands
    end
    
    for i, island in ipairs(rifts:GetChildren()) do
        if island:IsA("Model") then
            local uniqueId = island.Name .. "_" .. tostring(math.floor(island:GetPivot().Position.X)) .. 
                             "_" .. tostring(math.floor(island:GetPivot().Position.Z))
            
            local islandData = {
                name = island.Name,
                uniqueId = uniqueId,
                instance = island,
                position = island:GetPivot().Position,
                displayName = formatIslandName(island.Name),
                path = "Rendered.Rifts." .. island.Name,
                luckMultiplier = 0,
                timeInSeconds = 0
            }
            
            if island.Name:match("%-egg$") then
                local timeLeft = ""
                local luckLevel = ""
                
                pcall(function()
                    timeLeft = island.Display.SurfaceGui.Timer.ContentText
                    islandData.timeInSeconds = extractTimeInSeconds(timeLeft)
                end)
                
                pcall(function()
                    luckLevel = island.Display.SurfaceGui.Icon.Luck.ContentText
                    islandData.luckMultiplier = extractLuckMultiplier(luckLevel)
                end)
                
                islandData.displayName = formatIslandName(island.Name) .. " " .. timeLeft .. " " .. luckLevel
            end
            
            table.insert(islands, islandData)
        end
    end
    
    table.sort(islands, function(a, b)
        if a.luckMultiplier ~= b.luckMultiplier then
            return a.luckMultiplier > b.luckMultiplier 
        end
        
        if a.timeInSeconds ~= b.timeInSeconds then
            return a.timeInSeconds > b.timeInSeconds  
        end
        
        return a.displayName < b.displayName
    end)
    
    return islands
end

local function createMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BubbleSimGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = playerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 750, 0, 540)
    mainFrame.Position = config.windowPosition
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = false  
    mainFrame.Parent = screenGui
    
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 6)
    cornerRadius.Parent = mainFrame
    
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = mainColor
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 6)
    titleCorner.Parent = titleBar
    
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Name = "BottomFrame"
    bottomFrame.Size = UDim2.new(1, 0, 0.5, 0)
    bottomFrame.Position = UDim2.new(0, 0, 0.5, 0)
    bottomFrame.BackgroundColor3 = mainColor
    bottomFrame.BorderSizePixel = 0
    bottomFrame.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "VN Bubble Simulator INFINITY"
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 16
    titleText.TextColor3 = textColor
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.TextColor3 = textColor
    closeButton.Parent = titleBar
    
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(1, -60, 0, 0)
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.Text = "−"
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.TextSize = 20
    minimizeButton.TextColor3 = textColor
    minimizeButton.Parent = titleBar
    
    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.Size = UDim2.new(1, 0, 0, 40)
    tabButtons.Position = UDim2.new(0, 0, 0, 30)
    tabButtons.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabButtons.BorderSizePixel = 0
    tabButtons.Parent = mainFrame
    
    local tabContent = Instance.new("Frame")
    tabContent.Name = "TabContent"
    tabContent.Size = UDim2.new(1, 0, 1, -70)
    tabContent.Position = UDim2.new(0, 0, 0, 70)
    tabContent.BackgroundTransparency = 1
    tabContent.Parent = mainFrame
    
    local function createTabButton(name, position)
        local tabButton = Instance.new("TextButton")
        tabButton.Name = name .. "Button"
        tabButton.Size = UDim2.new(0, 120, 1, 0)
        tabButton.Position = UDim2.new(0, position, 0, 0)
        tabButton.BackgroundTransparency = 1
        tabButton.Text = name
        tabButton.Font = Enum.Font.GothamSemibold
        tabButton.TextSize = 14
        tabButton.TextColor3 = textColor
        tabButton.TextXAlignment = Enum.TextXAlignment.Left
        tabButton.Parent = tabButtons
        
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(1, 0, 0, 2)
        indicator.Position = UDim2.new(0, 0, 1, -2)
        indicator.BackgroundColor3 = mainColor
        indicator.BorderSizePixel = 0
        indicator.Visible = false
        indicator.Parent = tabButton
        
        return tabButton
    end
    
    local function createTabPage(name)
        local tabPage = Instance.new("ScrollingFrame")
        tabPage.Name = name .. "Tab"
        tabPage.Size = UDim2.new(1, 0, 1, 0)
        tabPage.BackgroundTransparency = 1
        tabPage.BorderSizePixel = 0
        tabPage.ScrollBarThickness = 8
        tabPage.ScrollingDirection = Enum.ScrollingDirection.Y
        tabPage.CanvasSize = UDim2.new(0, 0, 4, 0)
        tabPage.Visible = false
        tabPage.Parent = tabContent
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 20)
        padding.PaddingRight = UDim.new(0, 20)
        padding.PaddingTop = UDim.new(0, 20)
        padding.PaddingBottom = UDim.new(0, 20)
        padding.Parent = tabPage
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 15)
        listLayout.Parent = tabPage
        
        return tabPage
    end
    
    local tab1Button = createTabButton("Farming", 0)
    local tab2Button = createTabButton("Rewards", 120)
    local tab3Button = createTabButton("Shopping", 240)
    local tab4Button = createTabButton("Settings", 360)
    local tab5Button = createTabButton("Teleport", 480)
    local tab6Button = createTabButton("Season 2", 600)
    
    local tab1Page = createTabPage("Farming")
    local tab2Page = createTabPage("Rewards")
    local tab3Page = createTabPage("Shopping")
    local tab4Page = createTabPage("Settings")
    local tab5Page = createTabPage("Teleport")
    local tab6Page = createTabPage("Season 2")
    
    local function switchTab(tabName)
        
        tab1Page.Visible = false
        tab2Page.Visible = false
        tab3Page.Visible = false
        tab4Page.Visible = false
        tab5Page.Visible = false
        tab6Page.Visible = false
        
        tab1Button.Indicator.Visible = false
        tab2Button.Indicator.Visible = false
        tab3Button.Indicator.Visible = false
        tab4Button.Indicator.Visible = false
        tab5Button.Indicator.Visible = false
        tab6Button.Indicator.Visible = false
        
        if tabName == "Farming" then
            tab1Page.Visible = true
            tab1Button.Indicator.Visible = true
        elseif tabName == "Rewards" then
            tab2Page.Visible = true
            tab2Button.Indicator.Visible = true
        elseif tabName == "Shopping" then
            tab3Page.Visible = true
            tab3Button.Indicator.Visible = true
        elseif tabName == "Settings" then
            tab4Page.Visible = true
            tab4Button.Indicator.Visible = true
        elseif tabName == "Teleport" then
            tab5Page.Visible = true
            tab5Button.Indicator.Visible = true
        elseif tabName == "Season 2" then
                tab6Page.Visible = true
                tab6Button.Indicator.Visible = true
            end
    end
    
    tab1Button.MouseButton1Click:Connect(function()
        switchTab("Farming")
    end)
    
    tab2Button.MouseButton1Click:Connect(function()
        switchTab("Rewards")
    end)
    
    tab3Button.MouseButton1Click:Connect(function()
        switchTab("Shopping")
    end)
    
    tab4Button.MouseButton1Click:Connect(function()
        switchTab("Settings")
    end)
    tab5Button.MouseButton1Click:Connect(function()
        switchTab("Teleport")
    end)
    tab6Button.MouseButton1Click:Connect(function()
        switchTab("Season 2")
    end)
    
    local function createSectionHeader(parent, text, layoutOrder)
        local header = Instance.new("TextLabel")
        header.Name = text .. "Header"
        header.Size = UDim2.new(1, 0, 0, 30)
        header.BackgroundTransparency = 1
        header.Text = text
        header.Font = Enum.Font.GothamBold
        header.TextSize = 18
        header.TextColor3 = mainColor
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.LayoutOrder = layoutOrder or 0
        header.Parent = parent
        
        return header
    end
    
    local function createToggle(parent, name, description, initialState, callback, layoutOrder)
        local container = Instance.new("Frame")
        container.Name = name .. "Container"
        container.Size = UDim2.new(1, 0, 0, 60)
        container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        container.BorderSizePixel = 0
        container.LayoutOrder = layoutOrder or 0
        container.Parent = parent
        
        local cornerRadius = Instance.new("UICorner")
        cornerRadius.CornerRadius = UDim.new(0, 6)
        cornerRadius.Parent = container
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -80, 0, 25)
        title.Position = UDim2.new(0, 15, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = name
        title.Font = Enum.Font.GothamSemibold
        title.TextSize = 16
        title.TextColor3 = textColor
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container
        
        local desc = Instance.new("TextLabel")
        desc.Name = "Description"
        desc.Size = UDim2.new(1, -80, 0, 20)
        desc.Position = UDim2.new(0, 15, 0, 30)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextColor3 = Color3.fromRGB(180, 180, 180)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = container
        
        local toggleButton = Instance.new("Frame")
        toggleButton.Name = "ToggleButton"
        toggleButton.Size = UDim2.new(0, 50, 0, 30)
        toggleButton.Position = UDim2.new(1, -65, 0.5, -15)
        toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        toggleButton.BorderSizePixel = 0
        toggleButton.Parent = container
        
        local toggleButtonCorner = Instance.new("UICorner")
        toggleButtonCorner.CornerRadius = UDim.new(1, 0)
        toggleButtonCorner.Parent = toggleButton
        
        local toggleIndicator = Instance.new("Frame")
        toggleIndicator.Name = "Indicator"
        toggleIndicator.Size = UDim2.new(0, 24, 0, 24)
        toggleIndicator.Position = initialState and 
            UDim2.new(0, 23, 0.5, -12) or 
            UDim2.new(0, 3, 0.5, -12)
        toggleIndicator.BackgroundColor3 = initialState and 
            mainColor or 
            Color3.fromRGB(200, 200, 200)
        toggleIndicator.BorderSizePixel = 0
        toggleIndicator.Parent = toggleButton
        
        local toggleIndicatorCorner = Instance.new("UICorner")
        toggleIndicatorCorner.CornerRadius = UDim.new(1, 0)
        toggleIndicatorCorner.Parent = toggleIndicator
        
        toggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                initialState = not initialState
                
                local targetPosition = initialState and 
                    UDim2.new(0, 23, 0.5, -12) or 
                    UDim2.new(0, 3, 0.5, -12)
                local targetColor = initialState and 
                    mainColor or 
                    Color3.fromRGB(200, 200, 200)
                
                TweenService:Create(toggleIndicator, TweenInfo.new(0.2), {
                    Position = targetPosition,
                    BackgroundColor3 = targetColor
                }):Play()
                
                if callback then
                    callback(initialState)
                end
            end
        end)
        
        return {
            Container = container,
            Toggle = toggleButton,
            Indicator = toggleIndicator,
            SetState = function(state)
                initialState = state
                
                local targetPosition = initialState and 
                    UDim2.new(0, 23, 0.5, -12) or 
                    UDim2.new(0, 3, 0.5, -12)
                local targetColor = initialState and 
                    mainColor or 
                    Color3.fromRGB(200, 200, 200)
                
                toggleIndicator.Position = targetPosition
                toggleIndicator.BackgroundColor3 = targetColor
                
                if callback then
                    callback(initialState)
                end
            end,
            GetState = function()
                return initialState
            end
        }
    end
    
    local function createSlider(parent, name, description, min, max, initialValue, suffix, callback, layoutOrder, isDecimal)
        local container = Instance.new("Frame")
        container.Name = name .. "Container"
        container.Size = UDim2.new(1, 0, 0, 80)
        container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        container.BorderSizePixel = 0
        container.LayoutOrder = layoutOrder or 0
        container.Parent = parent
        
        local cornerRadius = Instance.new("UICorner")
        cornerRadius.CornerRadius = UDim.new(0, 6)
        cornerRadius.Parent = container
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -30, 0, 25)
        title.Position = UDim2.new(0, 15, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = name
        title.Font = Enum.Font.GothamSemibold
        title.TextSize = 16
        title.TextColor3 = textColor
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container
        
        local desc = Instance.new("TextLabel")
        desc.Name = "Description"
        desc.Size = UDim2.new(1, -30, 0, 20)
        desc.Position = UDim2.new(0, 15, 0, 30)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextColor3 = Color3.fromRGB(180, 180, 180)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = container
        
        local sliderBar = Instance.new("Frame")
        sliderBar.Name = "SliderBar"
        sliderBar.Size = UDim2.new(1, -30, 0, 10)
        sliderBar.Position = UDim2.new(0, 15, 0, 55)
        sliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        sliderBar.BorderSizePixel = 0
        sliderBar.Parent = container
        
        local sliderBarCorner = Instance.new("UICorner")
        sliderBarCorner.CornerRadius = UDim.new(1, 0)
        sliderBarCorner.Parent = sliderBar
        
        local percentage = (initialValue - min) / (max - min)
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "SliderFill"
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        sliderFill.BackgroundColor3 = mainColor
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBar
        
        local sliderFillCorner = Instance.new("UICorner")
        sliderFillCorner.CornerRadius = UDim.new(1, 0)
        sliderFillCorner.Parent = sliderFill
        
        local sliderValue = Instance.new("TextLabel")
        sliderValue.Name = "Value"
        sliderValue.Size = UDim2.new(0, 50, 0, 20)
        sliderValue.Position = UDim2.new(1, -65, 0, 5)
        sliderValue.BackgroundTransparency = 1
        sliderValue.Text = tostring(initialValue) .. (suffix or "")
        sliderValue.Font = Enum.Font.GothamSemibold
        sliderValue.TextSize = 14
        sliderValue.TextColor3 = textColor
        sliderValue.TextXAlignment = Enum.TextXAlignment.Right
        sliderValue.Parent = container
        
        local dragging = false
        
        sliderBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = UserInputService:GetMouseLocation()
                local relativePos = mousePos.X - sliderBar.AbsolutePosition.X
                local percentage = math.clamp(relativePos / sliderBar.AbsoluteSize.X, 0, 1)
                
                sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                
                local value = min + (percentage * (max - min))
                if isDecimal then
                    value = math.floor(value * 10) / 10  
                    sliderValue.Text = string.format("%.1f", value) .. (suffix or "")
                else
                    value = math.floor(value + 0.5)
                    sliderValue.Text = tostring(value) .. (suffix or "")
                end
                
                if callback then
                    callback(value)
                end
            end
        end)
        
        return {
            Container = container,
            SliderBar = sliderBar,
            SliderFill = sliderFill,
            ValueLabel = sliderValue,
            SetValue = function(value)
                value = math.clamp(value, min, max)
                local percentage = (value - min) / (max - min)
                
                sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                
                if min < 1 and max <= 1 then
                    sliderValue.Text = string.format("%.1f", value) .. (suffix or "")
                else
                    sliderValue.Text = tostring(math.floor(value + 0.5)) .. (suffix or "")
                end
                
                if callback then
                    callback(value)
                end
            end,
            GetValue = function()
                local percentage = sliderFill.Size.X.Scale
                local value = min + (percentage * (max - min))
                
                if min < 1 and max <= 1 then
                    return math.floor(value * 10) / 10
                else
                    return math.floor(value + 0.5)
                end
            end
        }
    end
    local function createStatusIndicator(parent, name, layoutOrder)
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = name .. "Status"
        statusLabel.Size = UDim2.new(1, 0, 0, 30)
        statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        statusLabel.BorderSizePixel = 0
        statusLabel.Text = name .. ": Inactive"
        statusLabel.Font = Enum.Font.GothamSemibold
        statusLabel.TextSize = 14
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.LayoutOrder = layoutOrder or 0
        statusLabel.Parent = parent
        
        local cornerRadius = Instance.new("UICorner")
        cornerRadius.CornerRadius = UDim.new(0, 6)
        cornerRadius.Parent = statusLabel
        
        return {
            Label = statusLabel,
            SetStatus = function(active, customText)
                statusLabel.Text = name .. ": " .. (customText or (active and "Active" or "Inactive"))
                statusLabel.TextColor3 = active and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 200, 200)
            end
        }
    end
    
    local function createDropdown(parent, name, description, options, initialValue, callback, layoutOrder)
        local container = Instance.new("Frame")
        container.Name = name .. "Container"
        container.Size = UDim2.new(1, 0, 0, 80)
        container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        container.BorderSizePixel = 0
        container.LayoutOrder = layoutOrder or 0
        container.Parent = parent
        
        local cornerRadius = Instance.new("UICorner")
        cornerRadius.CornerRadius = UDim.new(0, 6)
        cornerRadius.Parent = container
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -30, 0, 25)
        title.Position = UDim2.new(0, 15, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = name
        title.Font = Enum.Font.GothamSemibold
        title.TextSize = 16
        title.TextColor3 = textColor
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container
        
        local desc = Instance.new("TextLabel")
        desc.Name = "Description"
        desc.Size = UDim2.new(1, -30, 0, 20)
        desc.Position = UDim2.new(0, 15, 0, 30)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextColor3 = Color3.fromRGB(180, 180, 180)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = container
        
        local selectedDisplay = Instance.new("TextButton")
        selectedDisplay.Name = "SelectedDisplay"
        selectedDisplay.Size = UDim2.new(1, -30, 0, 30)
        selectedDisplay.Position = UDim2.new(0, 15, 0, 50)
        selectedDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        selectedDisplay.BorderSizePixel = 0
        selectedDisplay.Text = initialValue or "Select an option..."
        selectedDisplay.Font = Enum.Font.Gotham
        selectedDisplay.TextSize = 14
        selectedDisplay.TextColor3 = textColor
        selectedDisplay.TextXAlignment = Enum.TextXAlignment.Left
        selectedDisplay.TextTruncate = Enum.TextTruncate.AtEnd
        selectedDisplay.AutoButtonColor = false
        selectedDisplay.Parent = container
        
        local selectedDisplayPadding = Instance.new("UIPadding")
        selectedDisplayPadding.PaddingLeft = UDim.new(0, 10)
        selectedDisplayPadding.Parent = selectedDisplay
        
        local selectedDisplayCorner = Instance.new("UICorner")
        selectedDisplayCorner.CornerRadius = UDim.new(0, 4)
        selectedDisplayCorner.Parent = selectedDisplay
        
        local dropdownArrow = Instance.new("TextLabel")
        dropdownArrow.Name = "DropdownArrow"
        dropdownArrow.Size = UDim2.new(0, 30, 0, 30)
        dropdownArrow.Position = UDim2.new(1, -30, 0, 0)
        dropdownArrow.BackgroundTransparency = 1
        dropdownArrow.Text = "▼"
        dropdownArrow.Font = Enum.Font.Gotham
        dropdownArrow.TextSize = 14
        dropdownArrow.TextColor3 = Color3.fromRGB(150, 150, 150)
        dropdownArrow.Parent = selectedDisplay
        
        local dropdownMenu = Instance.new("ScrollingFrame")
        dropdownMenu.Name = "DropdownMenu"
        dropdownMenu.Size = UDim2.new(1, -30, 0, 0)
        dropdownMenu.Position = UDim2.new(0, 15, 0, 85)
        dropdownMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        dropdownMenu.BorderSizePixel = 0
        dropdownMenu.ScrollBarThickness = 4
        dropdownMenu.Visible = false
        dropdownMenu.Parent = container
        dropdownMenu.Active = true
        
        local dropdownMenuCorner = Instance.new("UICorner")
        dropdownMenuCorner.CornerRadius = UDim.new(0, 4)
        dropdownMenuCorner.Parent = dropdownMenu
        
        local dropdownLayout = Instance.new("UIListLayout")
        dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
        dropdownLayout.Parent = dropdownMenu
        
        
        local dropdownOpen = false
        
        local function toggleDropdown()
            dropdownOpen = not dropdownOpen
            
            if dropdownOpen then
                local optionCount = #options
                local visibleOptions = math.min(optionCount, 6) 
                local menuHeight = visibleOptions * 30
                
                dropdownMenu.Size = UDim2.new(1, -30, 0, menuHeight)
                dropdownMenu.CanvasSize = UDim2.new(0, 0, 0, optionCount * 30)
                dropdownMenu.Visible = true
                dropdownMenu.ZIndex = 9999
                for _, child in pairs(dropdownMenu:GetChildren()) do
            if child:IsA("GuiObject") then
                child.ZIndex = 10001
            end
        end
                
                dropdownArrow.Text = "▲"
            else
                dropdownMenu.Visible = false
                dropdownArrow.Text = "▼"
            end
        end
        
        selectedDisplay.MouseButton1Click:Connect(toggleDropdown)
        
        local function populateOptions(newOptions)
            for _, child in pairs(dropdownMenu:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            for i, option in ipairs(newOptions) do
                local optionButton = Instance.new("TextButton")
                optionButton.Name = "Option_" .. i
                optionButton.Size = UDim2.new(1, 0, 0, 30)
                optionButton.BackgroundTransparency = 1
                optionButton.Text = option.displayName or option.name or tostring(option)
                optionButton.Font = Enum.Font.Gotham
                optionButton.TextSize = 14
                optionButton.TextColor3 = textColor
                optionButton.TextXAlignment = Enum.TextXAlignment.Left
                optionButton.ZIndex = 104
                optionButton.Parent = dropdownMenu
                local optionPadding = Instance.new("UIPadding")
                optionPadding.PaddingLeft = UDim.new(0, 10)
                optionPadding.Parent = optionButton
                optionButton.MouseButton1Click:Connect(function()
                    local displayText = option.displayName or option.name or tostring(option)
                    selectedDisplay.Text = displayText
                    toggleDropdown()
                    if callback then
                        callback(option)
                    end
                end)
                
                optionButton.MouseEnter:Connect(function()
                    optionButton.BackgroundTransparency = 0.8
                    optionButton.BackgroundColor3 = mainColor
                end)
                
                optionButton.MouseLeave:Connect(function()
                    optionButton.BackgroundTransparency = 1
                end)
            end
            
            options = newOptions
        end
        populateOptions(options)
        return {
            Container = container,
            SelectedDisplay = selectedDisplay,
            DropdownMenu = dropdownMenu,
            SetOptions = populateOptions,
            SetValue = function(value)
                for _, option in ipairs(options) do
                    if option == value or option.name == value then
                        selectedDisplay.Text = option.displayName or option.name or tostring(option)
                        if callback then
                            callback(option)
                        end
                        
                        break
                    end
                end
            end,
            GetValue = function()
                local selectedText = selectedDisplay.Text
                for _, option in ipairs(options) do
                    if (option.displayName or option.name or tostring(option)) == selectedText then
                        return option
                    end
                end
                return nil
            end
        }
    end
    local function createButton(parent, name, description, callback, layoutOrder)
        local container = Instance.new("Frame")
        container.Name = name .. "Container"
        container.Size = UDim2.new(1, 0, 0, 60)
        container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        container.BorderSizePixel = 0
        container.LayoutOrder = layoutOrder or 0
        container.Parent = parent
        
        local cornerRadius = Instance.new("UICorner")
        cornerRadius.CornerRadius = UDim.new(0, 6)
        cornerRadius.Parent = container
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -130, 0, 25)
        title.Position = UDim2.new(0, 15, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = name
        title.Font = Enum.Font.GothamSemibold
        title.TextSize = 16
        title.TextColor3 = textColor
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container
        
        local desc = Instance.new("TextLabel")
        desc.Name = "Description"
        desc.Size = UDim2.new(1, -130, 0, 20)
        desc.Position = UDim2.new(0, 15, 0, 30)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextColor3 = Color3.fromRGB(180, 180, 180)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = container
        
        local button = Instance.new("TextButton")
        button.Name = "ActionButton"
        button.Size = UDim2.new(0, 100, 0, 30)
        button.Position = UDim2.new(1, -115, 0.5, -15)
        button.BackgroundColor3 = mainColor
        button.BorderSizePixel = 0
        button.Text = name
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 14
        button.TextColor3 = textColor
        button.Parent = container
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            if callback then
                callback()
            end
        end)
        
        return {
            Container = container,
            Button = button,
            SetEnabled = function(enabled)
                button.Active = enabled
                button.AutoButtonColor = enabled
                button.BackgroundColor3 = enabled and mainColor or Color3.fromRGB(80, 80, 80)
                button.TextColor3 = enabled and textColor or Color3.fromRGB(150, 150, 150)
            end
        }
    end
    
    local autoBubbleStatus = createStatusIndicator(tab1Page, "Auto Bubble", 30)
    local autoClawStatus = createStatusIndicator(tab6Page, "Auto Claw", 35)
    local autoCloseStatus = createStatusIndicator(tab6Page, "Auto Close", 60)
    local autoBoardStatus = createStatusIndicator(tab6Page, "Auto Board Dice", 90)
    local autoCardStatus = createStatusIndicator(tab6Page, "Auto Card game", 120)
    local autoCartStatus = createStatusIndicator(tab6Page, "Auto Doggy Cart game", 150)

    local autoSellBubbleStatus = createStatusIndicator(tab1Page, "Auto Sell Bubble", 60)
    local autoCollectStatus = createStatusIndicator(tab1Page, "Auto Collect", 100)
    local autoGiantChestStatus = createStatusIndicator(tab2Page, "Giant Chest", 30)
    local autoVoidChestStatus = createStatusIndicator(tab2Page, "Void Chest", 50)
    local autoFreeSpinStatus = createStatusIndicator(tab2Page, "Free Spin", 80)
    local autoDogJumpStatus = createStatusIndicator(tab2Page, "Dog Jump", 100)
    local autoPlaytimeStatus = createStatusIndicator(tab2Page, "Playtime", 120)
    local autoAlienMerchantStatus = createStatusIndicator(tab3Page, "Alien Merchant", 30)
    local autoBackMerchantStatus = createStatusIndicator(tab3Page, "Black Merchant", 50)
    local islandFlyStatus = createStatusIndicator(tab1Page, "Island Teleport", 130)


    createSectionHeader(tab1Page, "Special Islands", 105)
    local specialIslands = getSpecialIslands()
    local islandDropdown = createDropdown(
        tab1Page,
        "Special Island",
        "Choose an island to teleport to",
        specialIslands,
        "Select an island...",
        function(selectedIsland)
            config.selectedIsland = selectedIsland
        end,
        110
    )

    local configFlight = {
        verticalSpeed = 3000,     
        horizontalSpeed = 30,     
        arrivalDistance = 5       
    }
    local isFlying = false
    local noClipConnection = nil
    local flightLoop = nil
    local bodyVelocity = nil
    local originalGravity = workspace.Gravity
    local activeTween = nil
    local characterRemovedConnection = nil
    local originalHipHeight = humanoid.HipHeight
    local originalJumpPower = humanoid.JumpPower
    local originalCollisionState = {}
    
    local function storeOriginalProperties()
        originalCollisionState = {}
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCollisionState[part] = part.CanCollide
            end
        end
        
        originalHipHeight = humanoid.HipHeight
        originalJumpPower = humanoid.JumpPower
    end
    
    local function cleanupFlight()
        
        if activeTween then
            activeTween:Cancel()
            activeTween = nil
        end
        
        if noClipConnection then
            noClipConnection:Disconnect()
            noClipConnection = nil
        end
        
        if flightLoop then
            flightLoop:Disconnect()
            flightLoop = nil
        end
        
        if characterRemovedConnection then
            characterRemovedConnection:Disconnect()
            characterRemovedConnection = nil
        end
        
        task.wait(0.1)
        
        
        workspace.Gravity = originalGravity
        
        task.wait(0.2)
        
        
        if bodyVelocity and bodyVelocity.Parent then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        
        for _, v in pairs(rootPart:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyGyro") then
                v:Destroy()
            end
        end
        task.wait(0.2)
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {character}
        
        local rayResult = workspace:Raycast(
            rootPart.Position, 
            Vector3.new(0, -100, 0), 
            raycastParams
        )
        
        local groundPos
        if rayResult and rayResult.Position then
            groundPos = rayResult.Position + Vector3.new(0, humanoid.HipHeight + 0.1, 0)
            
        else
            
        end
        
        
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
        humanoid.HipHeight = originalHipHeight
        humanoid.JumpPower = originalJumpPower
        
        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        task.wait(0.15)
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.wait(0.15)
        
        if next(originalCollisionState) then
            for part, originalState in pairs(originalCollisionState) do
                if part and part:IsDescendantOf(workspace) then
                    part.CanCollide = originalState
                end
            end
        else
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        task.wait(0.15)
        
        if groundPos then
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.RotVelocity = Vector3.new(0, 0, 0)
            
            rootPart.CFrame = CFrame.new(groundPos)
            
            task.wait(0.15)
            
            local bodyVelocityDown = Instance.new("BodyVelocity")
            bodyVelocityDown.Name = "GroundingForce"
            bodyVelocityDown.MaxForce = Vector3.new(0, 9000, 0)
            bodyVelocityDown.Velocity = Vector3.new(0, -10, 0)
            bodyVelocityDown.Parent = rootPart
            
            task.wait(0.25)
            
            if bodyVelocityDown and bodyVelocityDown.Parent then
                bodyVelocityDown:Destroy()
            end
        end
        
        
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        
        task.delay(0.2, function()
            if rootPart and rootPart.Parent then
                rootPart.AssemblyLinearVelocity = Vector3.new(0, 0.1, 0)
            end
        end)
        task.wait(0.2)
        
        isFlying = false
        
        RunService.Heartbeat:Wait()
        RunService.Stepped:Wait()
        
    end


    local teleportLocations = {
        {
            path = "Workspace.Worlds.The Overworld.FastTravel.Spawn",
            position = Vector3.new(-0.8327484, 9.3463125, -21.4608002)
        },
        {
            path = "Workspace.Worlds.The Overworld.Islands.Floating Island.Island.Portal.Spawn",
            position = Vector3.new(-15.8544874, 423.2066650, 143.4181519)
        },
        {
            path = "Workspace.Worlds.The Overworld.Islands.Outer Space.Island.Portal.Spawn",
            position = Vector3.new(41.5017853, 2663.3161621, -6.3985291)
        },
        {
            path = "Workspace.Worlds.The Overworld.Islands.Twilight.Island.Portal.Spawn",
            position = Vector3.new(-77.9364624, 6862.6323242, 88.3281555)
        },
        {
            path = "Workspace.Worlds.The Overworld.Islands.The Void.Island.Portal.Spawn",
            position = Vector3.new(15.9753952, 10146.1494141, 151.7153625)
        },
        {
            path = "Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn",
            position = Vector3.new(36.2971840, 15971.8750000, 41.8721008)
        },
        {
            path = "Workspace.Worlds.Minigame Paradise.FastTravel.Spawn",
            position = Vector3.new(9981.6269531, 26.7997684, 172.1031036)
        },
        {
            path = "Workspace.Worlds.Minigame Paradise.Islands.Minecart Forest.Island.Portal.Spawn",
            position = Vector3.new(9882.3798828, 7682.2915039, 203.5670319)
        },
        {
            path = "Workspace.Worlds.Minigame Paradise.Islands.Robot Factory.Island.Portal.Spawn",
            position = Vector3.new(9887.7968750, 13409.6992188, 227.1578217)
        }
    }

    local function calculateXZDistance(pos1, pos2)
        return math.sqrt((pos1.X - pos2.X)^2 + (pos1.Z - pos2.Z)^2)
    end

    local function getCharacterPosition()
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character
        
        if not character then
            return nil
        end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return nil
        end
        
        return humanoidRootPart.Position
    end


    local function teleportToLocation(locationPath)
        local remote = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("Event")
        
        local args = {
            "Teleport",
            locationPath
        }
        
        remote:FireServer(unpack(args))
        
        wait(0.2)
        
        return true
    end
    
    local function findNearestLocationXZ(targetPosition)
        local nearestLocation = nil
        local shortestDistance = math.huge
        
        for _, location in ipairs(teleportLocations) do
            local xzDistance = math.sqrt(
                (location.position.X - targetPosition.X)^2 + 
                (location.position.Z - targetPosition.Z)^2
            )
            
            if xzDistance < shortestDistance then
                shortestDistance = xzDistance
                nearestLocation = location
            end
        end
        
        return nearestLocation, shortestDistance
    end
    

    local function teleportRemoteNear(targetPosition)
        local currentPosition = getCharacterPosition()
        if not currentPosition then
            return false
        end
        
        local currentDistance = calculateXZDistance(currentPosition, targetPosition)
        
        local nearestLocation, nearestDistance = findNearestLocationXZ(targetPosition)
        
        if not nearestLocation then
            return false
        end
        
        if currentDistance <= nearestDistance then
            return true
        end
        
        return teleportToLocation(nearestLocation.path)
    end

    local function findClawItems()
        local items = {}
        for _, child in pairs(screenGuiClaw:GetChildren()) do
            if string.sub(child.Name, 1, 8) == 'ClawItem' then
                local itemId = string.sub(child.Name, 9)
                local adornee = child.Adornee
                if adornee then
                    table.insert(items, {
                        id = itemId,
                        gui = child,
                        position = adornee.Position,
                        model = adornee.Parent,
                    })
                end
            end
        end
        return items
    end
    
    local function finishClaw()
    
        task.wait(0.1)
        local args = {
            'FinishMinigame',
        }
        ReplicatedStorage
            :WaitForChild('Shared')
            :WaitForChild('Framework')
            :WaitForChild('Network')
            :WaitForChild('Remote')
            :WaitForChild('Event')
            :FireServer(unpack(args))
    end

    local function processClaimsWithDelay()
        task.wait(0.1)
        local args = {
            'SkipMinigameCooldown',
            'Robot Claw',
        }
        ReplicatedStorage
            :WaitForChild('Shared')
            :WaitForChild('Framework')
            :WaitForChild('Network')
            :WaitForChild('Remote')
            :WaitForChild('Event')
            :FireServer(unpack(args))
    
        task.wait(1)
        local args = {
            'StartMinigame',
            'Robot Claw',
            'Insane',
        }
        ReplicatedStorage
            :WaitForChild('Shared')
            :WaitForChild('Framework')
            :WaitForChild('Network')
            :WaitForChild('Remote')
            :WaitForChild('Event')
            :FireServer(unpack(args))
        task.wait(7)
        safeClickButton()
        local items = findClawItems()
    
        for i, item in ipairs(items) do
            
    
            if item.model and not item.model:GetAttribute('wasCollected') then
                local args = {
                    'GrabMinigameItem',
                    item.id,
                }
    
                ReplicatedStorage
                    :WaitForChild('Shared')
                    :WaitForChild('Framework')
                    :WaitForChild('Network')
                    :WaitForChild('Remote')
                    :WaitForChild('Event')
                    :FireServer(unpack(args))
    
    
                task.wait(3.1)
            end
        end
    
        finishClaw()
    end

    local function hardcodedFunction(currentTile, tickets, infi, gDice)
        for i, ticket in ipairs(tickets) do
            if currentTile == ticket - 1 then
                return 'Golden Dice'
            end
        end
    
        for i, inf in ipairs(infi) do
            if inf and currentTile == inf - 1 then
                return 'Golden Dice'
            end
        end
    
        for i, ticket in ipairs(tickets) do
            if currentTile >= ticket - 6 and currentTile < ticket then
                return 'Dice'
            end
        end
    
        for i, inf in ipairs(infi) do
            if inf and currentTile >= inf - 6 and currentTile < inf then
                return 'Dice'
            end
        end
    
        for i, g in ipairs(gDice) do
            if currentTile >= g - 6 and currentTile < g then
                return 'Dice'
            end
        end
    
        return 'Giant Dice'
    end

    
local function isCartEscapeAvailable()
    

    local playerData = LocalDataBubbleGame:Get()
    if not playerData then
        return false
    end
    local currentTime = TimeService.now()
    local cartEscapeCooldown = playerData.Cooldowns
            and playerData.Cooldowns['Cart Escape']
        or 0
    local isAvailable = cartEscapeCooldown <= currentTime
    return isAvailable
end

local function isCardGameAvailable()
    local playerData = LocalDataBubbleGame:Get()
    if not playerData then
        return false
    end
    local currentTime = TimeService.now()
    local cardGameCooldown = playerData.Cooldowns
            and playerData.Cooldowns['Card Game']
        or 0
    local isAvailable = cardGameCooldown <= currentTime
    return isAvailable
end

    
    
    local function flyTo(target)
        if isFlying then
            cleanupFlight()
            task.wait(0.5)  
        end

        local targetPosition
            
        if typeof(target) == "Vector3" then
            targetPosition = target
        elseif typeof(target) == "Instance" then
            if target:IsA("BasePart") then
                targetPosition = target.Position
            elseif target:IsA("Model") and target.PrimaryPart then
                targetPosition = target.PrimaryPart.Position
            else
                for _, child in pairs(target:GetDescendants()) do
                    if child:IsA("BasePart") then
                        targetPosition = child.Position
                        break
                    end
                end
            end
        end

        if not targetPosition then
            return false
        end

        local success = teleportRemoteNear(targetPosition)

        if not success then
            return false
        end
        
        if not character or not character:FindFirstChild("HumanoidRootPart") or not humanoid then
            character = player.Character
            if not character then return false end
            
            humanoid = character:FindFirstChild("Humanoid")
            rootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoid or not rootPart then return false end
        end
        
        storeOriginalProperties()
        local targetPos
        if typeof(target) == "Vector3" then
            targetPos = target
        elseif typeof(target) == "CFrame" then
            targetPos = target.Position
        elseif typeof(target) == "Instance" then
            if target:IsA("BasePart") then
                targetPos = target.Position
            elseif target:IsA("Model") and target:FindFirstChild("HumanoidRootPart") then
                targetPos = target.HumanoidRootPart.Position
            else
                local part = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
                if part then
                    targetPos = part.Position
                else
                    warn("Target has no valid position")
                    return false
                end
            end
        else
            warn("Invalid target type")
            return false
        end
        
        originalGravity = workspace.Gravity
        
        isFlying = true
        
        targetPos = Vector3.new(targetPos.X + 5, targetPos.Y + 12, targetPos.Z + 5)
        
        noClipConnection = RunService.Stepped:Connect(function()
            if character and character:IsDescendantOf(workspace) then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            else
                cleanupFlight()
            end
        end)
        
        workspace.Gravity = 0
        
        if rootPart then
            for _, v in pairs(rootPart:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyGyro") then
                    v:Destroy()
                end
            end
            
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVelocity.Name = "FlyingBodyVelocity"
            bodyVelocity.Parent = rootPart
        end
        
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end
        
        local lastUpdate = tick()
        
        if flightLoop then
            flightLoop:Disconnect()
        end
        
        flightLoop = RunService.Heartbeat:Connect(function()
            if not isFlying or not character or not character:FindFirstChild("HumanoidRootPart") or not humanoid then
                cleanupFlight()
                return
            end
            local currentPos = rootPart.Position
            local deltaTime = tick() - lastUpdate
            lastUpdate = tick()
            
            local horizontalDist = Vector2.new(
                targetPos.X - currentPos.X, 
                targetPos.Z - currentPos.Z
            ).Magnitude
            
            local verticalDist = targetPos.Y - currentPos.Y
            local totalDist = (targetPos - currentPos).Magnitude
            if totalDist < configFlight.arrivalDistance then
                if activeTween then
                    activeTween:Cancel()
                end
                
                activeTween = TweenService:Create(
                    rootPart, 
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {CFrame = CFrame.new(targetPos)}
                )
                
                activeTween.Completed:Connect(function()
                    activeTween = nil
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    raycastParams.FilterDescendantsInstances = {character}
                    
                    local rayResult = workspace:Raycast(
                        targetPos, 
                        Vector3.new(0, -50, 0), 
                        raycastParams
                    )
                    
                    if rayResult and rayResult.Position then
                        rootPart.CFrame = CFrame.new(rayResult.Position + Vector3.new(0, humanoid.HipHeight + 0.1, 0))
                    end
                    cleanupFlight()
                end)
                
                activeTween:Play()
                return
            end
            if tick() % 0.5 < 0.1 and humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            end
            local distanceRatio = math.min(1, totalDist / 50)
            local currentVerticalSpeed = configFlight.verticalSpeed * distanceRatio
            local currentHorizontalSpeed = configFlight.horizontalSpeed * distanceRatio
            local verticalMove = math.clamp(
                verticalDist, 
                -currentVerticalSpeed * deltaTime, 
                currentVerticalSpeed * deltaTime
            )
            
            local horizontalDir = Vector3.new(
                targetPos.X - currentPos.X,
                0,
                targetPos.Z - currentPos.Z
            )
            
            if horizontalDir.Magnitude > 0.01 then
                horizontalDir = horizontalDir.Unit
            else
                horizontalDir = Vector3.new(0, 0, 0)
            end
            local horizontalMove = Vector3.new(0, 0, 0)
            if horizontalDist > 0.01 then
                horizontalMove = horizontalDir * math.min(horizontalDist, currentHorizontalSpeed * deltaTime)
            end
            
            local newPos = currentPos + Vector3.new(
                horizontalMove.X,
                verticalMove,
                horizontalMove.Z
            )
            local lookDirection = horizontalDir.Magnitude > 0.01 
                and CFrame.lookAt(newPos, newPos + horizontalDir) 
                or CFrame.new(newPos)
                
            rootPart.CFrame = lookDirection
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
        if characterRemovedConnection then
            characterRemovedConnection:Disconnect()
        end
        
        characterRemovedConnection = player.CharacterRemoving:Connect(function()
            cleanupFlight()
        end)
        
        return true
    end
local flyToIslandButton = createButton(
    tab1Page,
    "Fly to Island",
    "Teleport to the selected island",
    function()
        if isFlying then
            islandFlyStatus.SetStatus(false, "Already flying - please wait")
            return
        end
        if not config.selectedIsland then
            islandFlyStatus.SetStatus(false, "No island selected")
            return
        end
        
        if flyToIslandButton and flyToIslandButton.Button then
            flyToIslandButton.Button.Active = false
            flyToIslandButton.Button.AutoButtonColor = false
            flyToIslandButton.Button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            flyToIslandButton.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
islandFlyStatus.SetStatus(true, "Flying to " .. config.selectedIsland.displayName)

local target = config.selectedIsland.instance

if config.selectedIsland.name:match("%-egg$") and target then
    local eggPlatform = target:FindFirstChild("EggPlatformSpawn")
    if eggPlatform then
        target = eggPlatform
    end
end

if not target then
    islandFlyStatus.SetStatus(false, "Could not find target island")
    
    if flyToIslandButton and flyToIslandButton.Button then
        flyToIslandButton.Button.Active = true
        flyToIslandButton.Button.AutoButtonColor = true
        flyToIslandButton.Button.BackgroundColor3 = mainColor
        flyToIslandButton.Button.TextColor3 = textColor
    end
    return
end

        
        if not target then
            islandFlyStatus.SetStatus(false, "Could not find target: " .. targetPath)
            
            if flyToIslandButton and flyToIslandButton.Button then
                flyToIslandButton.Button.Active = true
                flyToIslandButton.Button.AutoButtonColor = true
                flyToIslandButton.Button.BackgroundColor3 = mainColor
                flyToIslandButton.Button.TextColor3 = textColor
            end
            return
        end
        
        local success = flyTo(target)
        
        if success then
            task.spawn(function()
                task.wait(1)
                while isFlying do
                    task.wait(0.5)
                end
                
                islandFlyStatus.SetStatus(false, "Arrived at " .. config.selectedIsland.displayName)
                
                if flyToIslandButton and flyToIslandButton.Button then
                    flyToIslandButton.Button.Active = true
                    flyToIslandButton.Button.AutoButtonColor = true
                    flyToIslandButton.Button.BackgroundColor3 = mainColor
                    flyToIslandButton.Button.TextColor3 = textColor
                end
            end)
        else
            islandFlyStatus.SetStatus(false, "Failed to start flight")
            
            if flyToIslandButton and flyToIslandButton.Button then
                flyToIslandButton.Button.Active = true
                flyToIslandButton.Button.AutoButtonColor = true
                flyToIslandButton.Button.BackgroundColor3 = mainColor
                flyToIslandButton.Button.TextColor3 = textColor
            end
        end
    end,
    120
)
    
    threads.islandUpdater = task.spawn(function()
    while true do
        local currentIslands = getSpecialIslands()
        
        local currentIslandMap = {}
        for _, island in ipairs(currentIslands) do
            currentIslandMap[island.uniqueId] = island
        end
        
        local existingIslandMap = {}
        for _, island in ipairs(specialIslands) do
            if island.uniqueId then 
                existingIslandMap[island.uniqueId] = island
            end
        end
        
        local structuralChange = false
        
        if #currentIslands ~= #specialIslands then
            structuralChange = true
        else
            for id, _ in pairs(currentIslandMap) do
                if not existingIslandMap[id] then
                    structuralChange = true
                    break
                end
            end
            
            if not structuralChange then
                for id, _ in pairs(existingIslandMap) do
                    if not currentIslandMap[id] then
                        structuralChange = true
                        break
                    end
                end
            end
        end
        
        if structuralChange then
            specialIslands = currentIslands
            islandDropdown.SetOptions(specialIslands)
            
            if config.selectedIsland and not currentIslandMap[config.selectedIsland.uniqueId] then
                config.selectedIsland = nil
                islandDropdown.SetValue("Select an island...")
            end
        else
            for i, island in ipairs(specialIslands) do
                if currentIslandMap[island.uniqueId] then
                    specialIslands[i].displayName = currentIslandMap[island.uniqueId].displayName
                end
            end
            
            local dropdownMenu = islandDropdown.DropdownMenu
            if dropdownMenu and dropdownMenu.Visible then
                for _, button in pairs(dropdownMenu:GetChildren()) do
                    if button:IsA("TextButton") then
                        for _, island in ipairs(specialIslands) do
                            if button:GetAttribute("IslandUniqueId") == island.uniqueId then
                                button.Text = island.displayName
                                break
                            end
                        end
                    end
                end
            end
            if config.selectedIsland and currentIslandMap[config.selectedIsland.uniqueId] then
                config.selectedIsland.displayName = currentIslandMap[config.selectedIsland.uniqueId].displayName
                islandDropdown.SelectedDisplay.Text = config.selectedIsland.displayName
            end
        end
        
        task.wait(1)
    end
end)

    createSectionHeader(tab1Page, "Auto Bubble", 10)
    
    local autoBubbleToggle = createToggle(
        tab1Page, 
        "Auto Bubble", 
        "Automatically blow bubbles", 
        config.autoBubble,
        function(state)
            config.autoBubble = state
            if autoBubbleStatus then
                autoBubbleStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoBubble then
                    task.cancel(threads.autoBubble)
                end
                
                threads.autoBubble = task.spawn(function()
                    while config.autoBubble do
                        local args = {
                            [1] = "BlowBubble"
                        }
                        
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Shared")
                                :WaitForChild("Framework")
                                :WaitForChild("Network")
                                :WaitForChild("Remote")
                                :WaitForChild("Event")
                                :FireServer(unpack(args))
                        end)
                        
                        task.wait(0.5)
                    end
                end)
            else
                if threads.autoBubble then
                    task.cancel(threads.autoBubble)
                    threads.autoBubble = nil
                end
            end
        end,
        20
    )


    local autoClawToggle = createToggle(
        tab6Page, 
        "Auto Claw", 
        "Automatically Claw Game", 
        config.autoClaw,
        function(state)
            config.autoClaw = state
            if autoClawStatus then
                autoClawStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoClaw then
                    task.cancel(threads.autoClaw)
                end
                
                threads.autoClaw = task.spawn(function()
                    while config.autoClaw do
                        processClaimsWithDelay()
                        
                        task.wait(0.5)
                    end
                end)
            else
                if threads.autoClaw then
                    finishClaw()
                    task.cancel(threads.autoClaw)
                    threads.autoClaw = nil
                end
            end
        end,
        20
    )



    local autoCloseToggle = createToggle(
        tab6Page, 
        "Auto Close", 
        "Automatically Close Notificate", 
        config.autoClose,
        function(state)
            config.autoClose = state
            if autoCloseStatus then
                autoCloseStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoClose then
                    task.cancel(threads.autoClose)
                end
                
                threads.autoClose = task.spawn(function()
                    
                    while config.autoClose do
                        safeClickButton()
                        task.wait(0.1)
                    end
                end)
            else
                if threads.autoClose then
                    task.cancel(threads.autoClose)
                    threads.autoClose = nil
                end
            end
        end,
        40
    )


    local autoBoardToggle = createToggle(
        tab6Page, 
        "Auto Board Dice", 
        "Automatically Board Dice game", 
        config.autoBoard,
        function(state)
            config.autoBoard = state
            if autoBoardStatus then
                autoBoardStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoBoard then
                    task.cancel(threads.autoBoard)
                end
                
                threads.autoBoard = task.spawn(function()
                    local tickets = { 8, 11, 18, 51, 52, 65, 66 }
                    local infi = { 17, 64, 85, nil, nil, nil, nil }
                    local gDice = { 10, 20, 26, 28, 45, 49, 75 }
                    while config.autoBoard do
                        if LocalDataBubbleGame.IsReady() then
                            local data = LocalDataBubbleGame.Get()
                            local currentTile = data['Board']['Tile']
                
                            local diceType = hardcodedFunction(
                                currentTile,
                                tickets,
                                infi,
                                gDice
                            )
                
                            click(
                                game:GetService('Players').LocalPlayer.PlayerGui.ScreenGui.BoardHUD.Dice.Inventory[diceType].Button
                            )
                
                            task.wait(0.2)
                            click(
                                game:GetService('Players').LocalPlayer.PlayerGui.ScreenGui.BoardHUD.Dice.Actions.Roll.Button
                            )
                        else
                        end
                        task.wait(1)
                    end
                end)
            else
                if threads.autoBoard then
                    task.cancel(threads.autoBoard)
                    threads.autoBoard = nil
                end
            end
        end,
        60
    )

    local autoCardToggle = createToggle(
        tab6Page, 
        "Auto Card game", 
        "Automatically play Card game", 
        config.autoCard,
        function(state)
            config.autoCard = state
            if autoCardStatus then
                autoCardStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoCard then
                    task.cancel(threads.autoCard)
                end
                
                threads.autoCard = task.spawn(function()
                    while config.autoCard do
                        if isCardGameAvailable() then
                            local args = {
                                'StartMinigame',
                                'Pet Match',
                                'Insane',
                            }
                            game
                                :GetService('ReplicatedStorage')
                                :WaitForChild('Shared')
                                :WaitForChild('Framework')
                                :WaitForChild('Network')
                                :WaitForChild('Remote')
                                :WaitForChild('Event')
                                :FireServer(unpack(args))
                                task.wait(1)
                                 args = {
                                    'FinishMinigame',
                                }
                                game
                                    :GetService('ReplicatedStorage')
                                    :WaitForChild('Shared')
                                    :WaitForChild('Framework')
                                    :WaitForChild('Network')
                                    :WaitForChild('Remote')
                                    :WaitForChild('Event')
                                    :FireServer(unpack(args))
                                
                        end
                        task.wait(1)
                    end
                end)
            else
                if threads.autoCard then
                    task.cancel(threads.autoCard)
                    threads.autoCard = nil
                end
            end
        end,
        100
    )

    local autoCartToggle = createToggle(
        tab6Page, 
        "Auto Doggy Cart game", 
        "Automatically Doggy Cart game", 
        config.autoCart,
        function(state)
            config.autoCart = state
            if autoCartStatus then
                autoCartStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoCart then
                    task.cancel(threads.autoCart)
                end
                
                threads.autoCart = task.spawn(function()
                    while config.autoCart do
                        if isCartEscapeAvailable() then
                            local args = {
                                'StartMinigame',
                                'Cart Escape',
                                'Insane',
                            }
                            game
                                :GetService('ReplicatedStorage')
                                :WaitForChild('Shared')
                                :WaitForChild('Framework')
                                :WaitForChild('Network')
                                :WaitForChild('Remote')
                                :WaitForChild('Event')
                                :FireServer(unpack(args))
                                task.wait(20)
                                 args = {
                                    'FinishMinigame',
                                }
                                game
                                    :GetService('ReplicatedStorage')
                                    :WaitForChild('Shared')
                                    :WaitForChild('Framework')
                                    :WaitForChild('Network')
                                    :WaitForChild('Remote')
                                    :WaitForChild('Event')
                                    :FireServer(unpack(args))
                                
                        end
                        task.wait(1)
                    end
                end)
            else
                if threads.autoCart then
                    task.cancel(threads.autoCart)
                    threads.autoCart = nil
                end
            end
        end,
        120
    )

    
    createSectionHeader(tab1Page, "Auto Sell", 30)
    
    local autoSellToggle = createToggle(
        tab1Page, 
        "Auto Sell Bubble", 
        "Automatically sell bubbles ONLY IF you stand near the sell position", 
        config.autoSell,
        function(state)
            config.autoSell = state
            if autoSellBubbleStatus then
                autoSellBubbleStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoSell then
                    task.cancel(threads.autoSell)
                end
                
                threads.autoSell = task.spawn(function()
                    while config.autoSell do
                        local args = {
                            [1] = "SellBubble"
                        }
                        
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Shared")
                                :WaitForChild("Framework")
                                :WaitForChild("Network")
                                :WaitForChild("Remote")
                                :WaitForChild("Event")
                                :FireServer(unpack(args))
                        end)
                        
                        task.wait(config.autoSellDelay)
                    end
                end)
            else
                if threads.autoSell then
                    task.cancel(threads.autoSell)
                    threads.autoSell = nil
                end
            end
        end,
        40
    )
    
    local autoSellDelaySlider = createSlider(
        tab1Page,
        "Sell Delay",
        "Time between selling bubbles",
        1,
        60,
        config.autoSellDelay,
        "s",
        function(value)
            config.autoSellDelay = value
        end,
        50
    )
    
    createSectionHeader(tab1Page, "Auto Collect", 60)
    
    local autoCollectToggle = createToggle(
        tab1Page, 
        "Auto Collect", 
        "Automatically collect items", 
        config.autoCollect,
        function(state)
            config.autoCollect = state

            if autoCollectStatus then
                autoCollectStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoCollect then
                    task.cancel(threads.autoCollect)
                end
                
                threads.autoCollect = task.spawn(function()
                    local character
                    
                    if player.Character then
                        character = player.Character
                    else
                        character = player.CharacterAdded:Wait()
                    end
                    
                    while config.autoCollect do
                        if not character or not character:FindFirstChild("HumanoidRootPart") then
                            if player.Character then
                                character = player.Character
                            else
                                character = player.CharacterAdded:Wait()
                            end
                            task.wait(config.collectionDelay)
                            continue
                        end
                        
                        local hrp = character:WaitForChild("HumanoidRootPart")
                        
                        local container

                        
                        pcall(function()
                            container = workspace.Rendered:GetChildren()[13]
                        end)
                        
                        if not container or not container:IsDescendantOf(workspace) then
                            task.wait(config.collectionDelay)
                            continue
                        end
                        
                        local modelsToProcess = {}
                        
                        for _, model in pairs(container:GetChildren()) do
                            pcall(function()
                                local distance = (model:GetPivot().Position - hrp.Position).Magnitude
                                if distance <= config.collectionRange then
                                    table.insert(modelsToProcess, {
                                        id = model.Name,
                                        ref = model
                                    })
                                end
                            end)
                        end
                        
                        autoCollectStatus.SetStatus(true, "Active - Found " .. #modelsToProcess .. " items")
                        
                        for _, modelData in ipairs(modelsToProcess) do
                            pcall(function()
                                modelData.ref.Parent = nil
                                ReplicatedStorage:WaitForChild("Remotes")
                                    :WaitForChild("Pickups"):WaitForChild("CollectPickup")
                                    :FireServer(modelData.id)
                            end)
                        end
                        
                        for _, modelData in ipairs(modelsToProcess) do
                            pcall(function()
                                if modelData.ref and modelData.ref:IsDescendantOf(workspace) then
                                    pcall(function()
                                        
                                        modelData.ref:Destroy()
                                    end)
                                end
                            end)
                        end
                        
                        task.wait(config.collectionDelay)
                    end
                end)
            else
                if threads.autoCollect then
                    task.cancel(threads.autoCollect)
                    threads.autoCollect = nil
                end
            end
        end,
        70
    )
    
    local collectionRangeSlider = createSlider(
        tab1Page,
        "Collection Range",
        "Distance to collect items",
        10,
        99,
        config.collectionRange,
        "",
        function(value)
            config.collectionRange = value
        end,
        80
    )
    
    local collectionDelaySlider = createSlider(
        tab1Page,
        "Collection Delay",
        "Time between collection attempts",
        0.1,
        1.0,
        config.collectionDelay,
        "s",
        function(value)
            config.collectionDelay = value
        end,
        90,
        true  
    )
    createSectionHeader(tab2Page, "Chest Rewards", 10)
    
    local autoGiantChestToggle = createToggle(
        tab2Page, 
        "Auto Giant Chest", 
        "Automatically claim Giant Chest rewards", 
        config.autoGiantChest,
        function(state)
            config.autoGiantChest = state
            if autoGiantChestStatus then
                autoGiantChestStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoGiantChest then
                    task.cancel(threads.autoGiantChest)
                end
                
                threads.autoGiantChest = task.spawn(function()
                    while config.autoGiantChest do
                        local LocalDataBubble = require(game:GetService('ReplicatedStorage').Client.Framework.Services.LocalData)
                        
                        local nextBubble = 0.0
                        if LocalDataBubble.IsReady() then
                            local data = LocalDataBubble.Get()
                            nextBubble = data['Cooldowns']['Giant Chest']
                        end

                        if (nextBubble < TimeService.now()) then
                            local args = {
                                [1] = "ClaimChest",
                                [2] = "Giant Chest",
                                [3] = true
                            }
                            
                            pcall(function()
                                ReplicatedStorage:WaitForChild("Shared")
                                    :WaitForChild("Framework")
                                    :WaitForChild("Network")
                                    :WaitForChild("Remote")
                                    :WaitForChild("Event")
                                    :FireServer(unpack(args))
                            end)
                        end
                        
                        task.wait(0.5)
                    end
                end)
            else
                if threads.autoGiantChest then
                    task.cancel(threads.autoGiantChest)
                    threads.autoGiantChest = nil
                end
            end
        end,
        20
    )
    
    
    local autoVoidChestToggle = createToggle(
        tab2Page, 
        "Auto Void Chest", 
        "Automatically claim Void Chest rewards", 
        config.autoVoidChest,
        function(state)
            config.autoVoidChest = state
            if autoVoidChestStatus then
                autoVoidChestStatus.SetStatus(state)
            end
            
            if state then
                if threads.autoVoidChest then
                    task.cancel(threads.autoVoidChest)
                end
                
                threads.autoVoidChest = task.spawn(function()
                    while config.autoVoidChest do
                        local LocalDataBubble = require(game:GetService('ReplicatedStorage').Client.Framework.Services.LocalData)
                        
                        local nextBubble = 0.0
                        if LocalDataBubble.IsReady() then
                            local data = LocalDataBubble.Get()
                            nextBubble = data['Cooldowns']['Void Chest']
                        end

                        if (nextBubble < TimeService.now()) then
                            local args = {
                                [1] = "ClaimChest",
                                [2] = "Void Chest",
                                [3] = true
                            }
                            
                            pcall(function()
                                ReplicatedStorage:WaitForChild("Shared")
                                    :WaitForChild("Framework")
                                    :WaitForChild("Network")
                                    :WaitForChild("Remote")
                                    :WaitForChild("Event")
                                    :FireServer(unpack(args))
                            end)
                        end
                        
                        task.wait(0.5)
                    end
                end)
            else
                if threads.autoVoidChest then
                    task.cancel(threads.autoVoidChest)
                    threads.autoVoidChest = nil
                end
            end
        end,
        40
    )
    createSectionHeader(tab2Page, "Free Rewards", 60)
    
    local autoFreeSpinToggle = createToggle(
        tab2Page, 
        "Auto Free Spin", 
        "Automatically collect free wheel spins", 
        config.autoFreeSpin,
        function(state)
            config.autoFreeSpin = state
            autoFreeSpinStatus.SetStatus(state)
            
            if state then
                if threads.autoFreeSpin then
                    task.cancel(threads.autoFreeSpin)
                end
                
                threads.autoFreeSpin = task.spawn(function()
                    while config.autoFreeSpin do
                        local LocalDataBubble = require(game:GetService('ReplicatedStorage').Client.Framework.Services.LocalData)
                        
                        local nextBubble = 0.0
                        if LocalDataBubble.IsReady() then
                            local data = LocalDataBubble.Get()
                            nextBubble = data['NextWheelSpin']
                        end

                        if (nextBubble < TimeService.now()) then
                            local args = {
                                [1] = "ClaimFreeWheelSpin"
                            }
                            
                            pcall(function()
                                ReplicatedStorage:WaitForChild("Shared")
                                    :WaitForChild("Framework")
                                    :WaitForChild("Network")
                                    :WaitForChild("Remote")
                                    :WaitForChild("Event")
                                    :FireServer(unpack(args))
                            end)
                        end
                        
                        task.wait(0.5)
                    end
                end)
            else
                if threads.autoFreeSpin then
                    task.cancel(threads.autoFreeSpin)
                    threads.autoFreeSpin = nil
                end
            end
        end,
        70
    )
    
    
    local autoDogJumpToggle = createToggle(
        tab2Page, 
        "Auto Dog Jump", 
        "Automatically collect dog jump rewards", 
        config.autoDogJump,
        function(state)
            config.autoDogJump = state
            autoDogJumpStatus.SetStatus(state)
            
            if state then
                if threads.autoDogJump then
                    task.cancel(threads.autoDogJump)
                end
                
                threads.autoDogJump = task.spawn(function()
                    while config.autoDogJump do
                        local LocalDataBubble = require(game:GetService('ReplicatedStorage').Client.Framework.Services.LocalData)
                        
                        local nextBubble = 0.0
                        if LocalDataBubble.IsReady() then
                            local data = LocalDataBubble.Get()
                            nextBubble = data['DoggyJump']['Claimed']
                        end

                        if (nextBubble < 3) then
                            local args = {
                                [1] = "DoggyJumpWin",
                                [2] = 3
                            }
                            
                            pcall(function()
                                ReplicatedStorage:WaitForChild("Shared")
                                    :WaitForChild("Framework")
                                    :WaitForChild("Network")
                                    :WaitForChild("Remote")
                                    :WaitForChild("Event")
                                    :FireServer(unpack(args))
                            end)
                        end
                        
                        task.wait(0.5)
                    end
                end)
            else
                if threads.autoDogJump then
                    task.cancel(threads.autoDogJump)
                    threads.autoDogJump = nil
                end
            end
        end,
        90
    )
    
    
    local autoPlaytimeToggle = createToggle(
        tab2Page, 
        "Auto Playtime", 
        "Automatically collect playtime rewards", 
        config.autoPlaytime,
        function(state)
            config.autoPlaytime = state
            autoPlaytimeStatus.SetStatus(state)
            
            if state then
                if threads.autoPlaytime then
                    task.cancel(threads.autoPlaytime)
                end
                
                threads.autoPlaytime = task.spawn(function()
                    
                    while config.autoPlaytime do

                        
                        local playerData = LocalDataBubbleGame:Get()
                        if not playerData then
                            return
                        end
                    
                        local elapsedTime = TimeService.now() - playerData.PlaytimeRewards.Start
                    
                    
                        local claimedRewards = playerData.PlaytimeRewards.Claimed

                        for rewardId, rewardData in pairs(PlaytimeData.Gifts) do
                            if not claimedRewards[rewardId] and not claimedRewards[tostring(rewardId)] then
                                if rewardData.Time <= elapsedTime then
                                        ReplicatedStorage
                                            :WaitForChild('Shared')
                                            :WaitForChild('Framework')
                                            :WaitForChild('Network')
                                            :WaitForChild('Remote')
                                            :WaitForChild('Function')
                                            :InvokeServer('ClaimPlaytime', rewardId)
                                        task.wait(2)
                                end
                            end
                        end
                        
                        task.wait(1)
                    end
                end)
            else
                if threads.autoPlaytime then
                    task.cancel(threads.autoPlaytime)
                    threads.autoPlaytime = nil
                end
            end
        end,
        110
    )
    
    createSectionHeader(tab3Page, "Auto Merchants", 10)
    
    local autoAlienMerchantToggle = createToggle(
        tab3Page, 
        "Auto Alien Merchant", 
        "Automatically buy from Alien Merchant", 
        config.autoAlienMerchant,
        function(state)
            config.autoAlienMerchant = state
            autoAlienMerchantStatus.SetStatus(state)
            
            if state then
                if threads.autoAlienMerchant then
                    task.cancel(threads.autoAlienMerchant)
                end
                
                threads.autoAlienMerchant = task.spawn(function()
                    while config.autoAlienMerchant do
                            local currentShop = 'alien-shop' 
                        
                            local playerData = LocalDataBubbleGame:Get()
                            if not playerData then
                                return
                            end
                        
                            local items, stocks = ShopUtil:GetItemsData(
                                currentShop,
                                game:GetService('Players').LocalPlayer,
                                playerData
                            )
                        
                            local shopState = playerData.Shops[currentShop]
                        
                            for index, itemData in pairs(items) do
                                local purchased = shopState.Bought[index] or 0
                                local stock = stocks[index] or 0
                                local remaining = math.max(0, stock - purchased)
                        
                                if remaining > 0 then
                                    local args = {
                                        'BuyShopItem',
                                        currentShop,
                                        index,
                                    }
                                    game
                                        :GetService('ReplicatedStorage')
                                        :WaitForChild('Shared')
                                        :WaitForChild('Framework')
                                        :WaitForChild('Network')
                                        :WaitForChild('Remote')
                                        :WaitForChild('Event')
                                        :FireServer(unpack(args))
                                    task.wait(1.5)
                                end
                                task.wait(0.01)
                            end
                            task.wait(0.5)
                    end
                end)
            else
                if threads.autoAlienMerchant then
                    task.cancel(threads.autoAlienMerchant)
                    threads.autoAlienMerchant = nil
                end
            end
        end,
        20
    )
    
    
    local autoBackMerchantToggle = createToggle(
        tab3Page, 
        "Auto Black Merchant", 
        "Automatically buy from Black Merchant", 
        config.autoBackMerchant,
        function(state)
            config.autoBackMerchant = state
            autoBackMerchantStatus.SetStatus(state)
            
            if state then
                if threads.autoBackMerchant then
                    task.cancel(threads.autoBackMerchant)
                end
                
                threads.autoBackMerchant = task.spawn(function()
                    while config.autoBackMerchant do
                        local currentShop = 'shard-shop' 
                        
                            local playerData = LocalDataBubbleGame:Get()
                            if not playerData then
                                return
                            end
                        
                            local items, stocks = ShopUtil:GetItemsData(
                                currentShop,
                                game:GetService('Players').LocalPlayer,
                                playerData
                            )
                        
                            local shopState = playerData.Shops[currentShop]
                        
                            for index, itemData in pairs(items) do
                                local purchased = shopState.Bought[index] or 0
                                local stock = stocks[index] or 0
                                local remaining = math.max(0, stock - purchased)
                        
                                if remaining > 0 then
                                    local args = {
                                        'BuyShopItem',
                                        currentShop,
                                        index,
                                    }
                                    game
                                        :GetService('ReplicatedStorage')
                                        :WaitForChild('Shared')
                                        :WaitForChild('Framework')
                                        :WaitForChild('Network')
                                        :WaitForChild('Remote')
                                        :WaitForChild('Event')
                                        :FireServer(unpack(args))
                                    task.wait(1.5)
                                end
                                task.wait(0.01)
                            end
                            task.wait(0.5)
                    end
                end)
            else
                if threads.autoBackMerchant then
                    task.cancel(threads.autoBackMerchant)
                    threads.autoBackMerchant = nil
                end
            end
        end,
        40
    )
    createSectionHeader(tab4Page, "GUI Settings", 10)
    
    local transparencySlider = createSlider(
        tab4Page,
        "GUI Transparency",
        "Adjust the transparency of the GUI",
        0,
        100,
        config.guiTransparency * 100,
        "%",
        function(value)
            config.guiTransparency = value / 100
            mainFrame.BackgroundTransparency = config.guiTransparency * 0.7
            titleBar.BackgroundTransparency = config.guiTransparency * 0.7
            bottomFrame.BackgroundTransparency = config.guiTransparency * 0.7
            tabButtons.BackgroundTransparency = config.guiTransparency * 0.7
            local function applyTransparencyToDescendants(parent)
                for _, child in pairs(parent:GetDescendants()) do
                    if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                        child.BackgroundTransparency = math.min(child.BackgroundTransparency + config.guiTransparency * 0.7, 0.95)
                    elseif child:IsA("TextLabel") or child:IsA("TextButton") then
                        if child.BackgroundTransparency < 1 then
                            child.BackgroundTransparency = math.min(child.BackgroundTransparency + config.guiTransparency * 0.7, 0.95)
                        end
                        child.TextTransparency = config.guiTransparency * 0.5
                    elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                        child.ImageTransparency = math.min(child.ImageTransparency + config.guiTransparency * 0.7, 0.95)
                    end
                end
            end
            applyTransparencyToDescendants(tab1Page)
            applyTransparencyToDescendants(tab2Page)
            applyTransparencyToDescendants(tab3Page)
            applyTransparencyToDescendants(tab4Page)
            
            for _, container in pairs(mainFrame:GetDescendants()) do
                if container.Name:match("Container$") then
                    container.BackgroundTransparency = config.guiTransparency * 0.7
                end
            end
        end,
        20
    )
    
    local resetPositionContainer = Instance.new("Frame")
    resetPositionContainer.Name = "ResetPositionContainer"
    resetPositionContainer.Size = UDim2.new(1, 0, 0, 60)
    resetPositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    resetPositionContainer.BorderSizePixel = 0
    resetPositionContainer.LayoutOrder = 30
    resetPositionContainer.Parent = tab4Page
    
    local resetPositionCorner = Instance.new("UICorner")
    resetPositionCorner.CornerRadius = UDim.new(0, 6)
    resetPositionCorner.Parent = resetPositionContainer
    
    local resetPositionTitle = Instance.new("TextLabel")
    resetPositionTitle.Name = "Title"
    resetPositionTitle.Size = UDim2.new(1, -30, 0, 25)
    resetPositionTitle.Position = UDim2.new(0, 15, 0, 5)
    resetPositionTitle.BackgroundTransparency = 1
    resetPositionTitle.Text = "Window Position"
    resetPositionTitle.Font = Enum.Font.GothamSemibold
    resetPositionTitle.TextSize = 16
    resetPositionTitle.TextColor3 = textColor
    resetPositionTitle.TextXAlignment = Enum.TextXAlignment.Left
    resetPositionTitle.Parent = resetPositionContainer
    
    local resetPositionDesc = Instance.new("TextLabel")
    resetPositionDesc.Name = "Description"
    resetPositionDesc.Size = UDim2.new(1, -30, 0, 20)
    resetPositionDesc.Position = UDim2.new(0, 15, 0, 30)
    resetPositionDesc.BackgroundTransparency = 1
    resetPositionDesc.Text = "Reset the GUI position to center of screen"
    resetPositionDesc.Font = Enum.Font.Gotham
    resetPositionDesc.TextSize = 12
    resetPositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
    resetPositionDesc.TextXAlignment = Enum.TextXAlignment.Left
    resetPositionDesc.Parent = resetPositionContainer
    
    local resetPositionButton = Instance.new("TextButton")
    resetPositionButton.Name = "ResetButton"
    resetPositionButton.Size = UDim2.new(0, 100, 0, 30)
    resetPositionButton.Position = UDim2.new(1, -115, 0.5, -15)
    resetPositionButton.BackgroundColor3 = mainColor
    resetPositionButton.BorderSizePixel = 0
    resetPositionButton.Text = "Reset"
    resetPositionButton.Font = Enum.Font.GothamSemibold
    resetPositionButton.TextSize = 14
    resetPositionButton.TextColor3 = textColor
    resetPositionButton.Parent = resetPositionContainer




    ---------------
    createSectionHeader(tab5Page, "World 1", 0)

------------------
local world1_0_PositionContainer = Instance.new("Frame")  
world1_0_PositionContainer.Name = "ResetPositionContainer"  
world1_0_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world1_0_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world1_0_PositionContainer.BorderSizePixel = 0  
world1_0_PositionContainer.LayoutOrder = 30  
world1_0_PositionContainer.Parent = tab5Page  

local world1_0_PositionCorner = Instance.new("UICorner")  
world1_0_PositionCorner.CornerRadius = UDim.new(0, 6)  
world1_0_PositionCorner.Parent = world1_0_PositionContainer  

local world1_0_PositionTitle = Instance.new("TextLabel")  
world1_0_PositionTitle.Name = "Title"  
world1_0_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world1_0_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world1_0_PositionTitle.BackgroundTransparency = 1  
world1_0_PositionTitle.Text = "Spawn"  
world1_0_PositionTitle.Font = Enum.Font.GothamSemibold  
world1_0_PositionTitle.TextSize = 16  
world1_0_PositionTitle.TextColor3 = textColor  
world1_0_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world1_0_PositionTitle.Parent = world1_0_PositionContainer  

local world1_0_PositionDesc = Instance.new("TextLabel")  
world1_0_PositionDesc.Name = "Description"  
world1_0_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world1_0_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world1_0_PositionDesc.BackgroundTransparency = 1  
world1_0_PositionDesc.Text = "The Overworld, where you spawn"  
world1_0_PositionDesc.Font = Enum.Font.Gotham  
world1_0_PositionDesc.TextSize = 12  
world1_0_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world1_0_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world1_0_PositionDesc.Parent = world1_0_PositionContainer  

local world1_0_PositionButton = Instance.new("TextButton")  
world1_0_PositionButton.Name = "ResetButton"  
world1_0_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world1_0_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world1_0_PositionButton.BackgroundColor3 = mainColor  
world1_0_PositionButton.BorderSizePixel = 0  
world1_0_PositionButton.Text = "Teleport"  
world1_0_PositionButton.Font = Enum.Font.GothamSemibold  
world1_0_PositionButton.TextSize = 14  
world1_0_PositionButton.TextColor3 = textColor  
world1_0_PositionButton.Parent = world1_0_PositionContainer  


------------------
local world1_1_PositionContainer = Instance.new("Frame")  
world1_1_PositionContainer.Name = "ResetPositionContainer"  
world1_1_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world1_1_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world1_1_PositionContainer.BorderSizePixel = 0  
world1_1_PositionContainer.LayoutOrder = 30  
world1_1_PositionContainer.Parent = tab5Page  

local world1_1_PositionCorner = Instance.new("UICorner")  
world1_1_PositionCorner.CornerRadius = UDim.new(0, 6)  
world1_1_PositionCorner.Parent = world1_1_PositionContainer  

local world1_1_PositionTitle = Instance.new("TextLabel")  
world1_1_PositionTitle.Name = "Title"  
world1_1_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world1_1_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world1_1_PositionTitle.BackgroundTransparency = 1  
world1_1_PositionTitle.Text = "Island 1: Floating island"  
world1_1_PositionTitle.Font = Enum.Font.GothamSemibold  
world1_1_PositionTitle.TextSize = 16  
world1_1_PositionTitle.TextColor3 = textColor  
world1_1_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world1_1_PositionTitle.Parent = world1_1_PositionContainer  

local world1_1_PositionDesc = Instance.new("TextLabel")  
world1_1_PositionDesc.Name = "Description"  
world1_1_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world1_1_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world1_1_PositionDesc.BackgroundTransparency = 1  
world1_1_PositionDesc.Text = "Spin and a Gold chest"  
world1_1_PositionDesc.Font = Enum.Font.Gotham  
world1_1_PositionDesc.TextSize = 12  
world1_1_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world1_1_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world1_1_PositionDesc.Parent = world1_1_PositionContainer  

local world1_1_PositionButton = Instance.new("TextButton")  
world1_1_PositionButton.Name = "ResetButton"  
world1_1_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world1_1_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world1_1_PositionButton.BackgroundColor3 = mainColor  
world1_1_PositionButton.BorderSizePixel = 0  
world1_1_PositionButton.Text = "Teleport"  
world1_1_PositionButton.Font = Enum.Font.GothamSemibold  
world1_1_PositionButton.TextSize = 14  
world1_1_PositionButton.TextColor3 = textColor  
world1_1_PositionButton.Parent = world1_1_PositionContainer  
------------------


local world1_2_PositionContainer = Instance.new("Frame")  
world1_2_PositionContainer.Name = "ResetPositionContainer"  
world1_2_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world1_2_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world1_2_PositionContainer.BorderSizePixel = 0  
world1_2_PositionContainer.LayoutOrder = 30  
world1_2_PositionContainer.Parent = tab5Page  

local world1_2_PositionCorner = Instance.new("UICorner")  
world1_2_PositionCorner.CornerRadius = UDim.new(0, 6)  
world1_2_PositionCorner.Parent = world1_2_PositionContainer  

local world1_2_PositionTitle = Instance.new("TextLabel")  
world1_2_PositionTitle.Name = "Title"  
world1_2_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world1_2_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world1_2_PositionTitle.BackgroundTransparency = 1  
world1_2_PositionTitle.Text = "Island 2: Outer Space"  
world1_2_PositionTitle.Font = Enum.Font.GothamSemibold  
world1_2_PositionTitle.TextSize = 16  
world1_2_PositionTitle.TextColor3 = textColor  
world1_2_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world1_2_PositionTitle.Parent = world1_2_PositionContainer  

local world1_2_PositionDesc = Instance.new("TextLabel")  
world1_2_PositionDesc.Name = "Description"  
world1_2_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world1_2_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world1_2_PositionDesc.BackgroundTransparency = 1  
world1_2_PositionDesc.Text = "Not much you can do here"  
world1_2_PositionDesc.Font = Enum.Font.Gotham  
world1_2_PositionDesc.TextSize = 12  
world1_2_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world1_2_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world1_2_PositionDesc.Parent = world1_2_PositionContainer  

local world1_2_PositionButton = Instance.new("TextButton")  
world1_2_PositionButton.Name = "ResetButton"  
world1_2_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world1_2_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world1_2_PositionButton.BackgroundColor3 = mainColor  
world1_2_PositionButton.BorderSizePixel = 0  
world1_2_PositionButton.Text = "Teleport"  
world1_2_PositionButton.Font = Enum.Font.GothamSemibold  
world1_2_PositionButton.TextSize = 14  
world1_2_PositionButton.TextColor3 = textColor  
world1_2_PositionButton.Parent = world1_2_PositionContainer  

----------------

local world1_3_PositionContainer = Instance.new("Frame")  
world1_3_PositionContainer.Name = "ResetPositionContainer"  
world1_3_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world1_3_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world1_3_PositionContainer.BorderSizePixel = 0  
world1_3_PositionContainer.LayoutOrder = 30  
world1_3_PositionContainer.Parent = tab5Page  

local world1_3_PositionCorner = Instance.new("UICorner")  
world1_3_PositionCorner.CornerRadius = UDim.new(0, 6)  
world1_3_PositionCorner.Parent = world1_3_PositionContainer  

local world1_3_PositionTitle = Instance.new("TextLabel")  
world1_3_PositionTitle.Name = "Title"  
world1_3_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world1_3_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world1_3_PositionTitle.BackgroundTransparency = 1  
world1_3_PositionTitle.Text = "Island 3: Twilight"  
world1_3_PositionTitle.Font = Enum.Font.GothamSemibold  
world1_3_PositionTitle.TextSize = 16  
world1_3_PositionTitle.TextColor3 = textColor  
world1_3_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world1_3_PositionTitle.Parent = world1_3_PositionContainer  

local world1_3_PositionDesc = Instance.new("TextLabel")  
world1_3_PositionDesc.Name = "Description"  
world1_3_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world1_3_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world1_3_PositionDesc.BackgroundTransparency = 1  
world1_3_PositionDesc.Text = "Sell for more normal coins"  
world1_3_PositionDesc.Font = Enum.Font.Gotham  
world1_3_PositionDesc.TextSize = 12  
world1_3_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world1_3_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world1_3_PositionDesc.Parent = world1_3_PositionContainer  

local world1_3_PositionButton = Instance.new("TextButton")  
world1_3_PositionButton.Name = "ResetButton"  
world1_3_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world1_3_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world1_3_PositionButton.BackgroundColor3 = mainColor  
world1_3_PositionButton.BorderSizePixel = 0  
world1_3_PositionButton.Text = "Teleport"  
world1_3_PositionButton.Font = Enum.Font.GothamSemibold  
world1_3_PositionButton.TextSize = 14  
world1_3_PositionButton.TextColor3 = textColor  
world1_3_PositionButton.Parent = world1_3_PositionContainer  

------------------------

local world1_4_PositionContainer = Instance.new("Frame")  
world1_4_PositionContainer.Name = "ResetPositionContainer"  
world1_4_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world1_4_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world1_4_PositionContainer.BorderSizePixel = 0  
world1_4_PositionContainer.LayoutOrder = 30  
world1_4_PositionContainer.Parent = tab5Page  

local world1_4_PositionCorner = Instance.new("UICorner")  
world1_4_PositionCorner.CornerRadius = UDim.new(0, 6)  
world1_4_PositionCorner.Parent = world1_4_PositionContainer  

local world1_4_PositionTitle = Instance.new("TextLabel")  
world1_4_PositionTitle.Name = "Title"  
world1_4_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world1_4_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world1_4_PositionTitle.BackgroundTransparency = 1  
world1_4_PositionTitle.Text = "Island 4: The Void"  
world1_4_PositionTitle.Font = Enum.Font.GothamSemibold  
world1_4_PositionTitle.TextSize = 16  
world1_4_PositionTitle.TextColor3 = textColor  
world1_4_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world1_4_PositionTitle.Parent = world1_4_PositionContainer  

local world1_4_PositionDesc = Instance.new("TextLabel")  
world1_4_PositionDesc.Name = "Description"  
world1_4_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world1_4_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world1_4_PositionDesc.BackgroundTransparency = 1  
world1_4_PositionDesc.Text = "Enchant here, there are Black market and Void chest too"  
world1_4_PositionDesc.Font = Enum.Font.Gotham  
world1_4_PositionDesc.TextSize = 12  
world1_4_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world1_4_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world1_4_PositionDesc.Parent = world1_4_PositionContainer  

local world1_4_PositionButton = Instance.new("TextButton")  
world1_4_PositionButton.Name = "ResetButton"  
world1_4_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world1_4_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world1_4_PositionButton.BackgroundColor3 = mainColor  
world1_4_PositionButton.BorderSizePixel = 0  
world1_4_PositionButton.Text = "Teleport"  
world1_4_PositionButton.Font = Enum.Font.GothamSemibold  
world1_4_PositionButton.TextSize = 14  
world1_4_PositionButton.TextColor3 = textColor  
world1_4_PositionButton.Parent = world1_4_PositionContainer  


---------------------



local world1_5_PositionContainer = Instance.new("Frame")  
world1_5_PositionContainer.Name = "ResetPositionContainer"  
world1_5_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world1_5_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world1_5_PositionContainer.BorderSizePixel = 0  
world1_5_PositionContainer.LayoutOrder = 30  
world1_5_PositionContainer.Parent = tab5Page  

local world1_5_PositionCorner = Instance.new("UICorner")  
world1_5_PositionCorner.CornerRadius = UDim.new(0, 6)  
world1_5_PositionCorner.Parent = world1_5_PositionContainer  

local world1_5_PositionTitle = Instance.new("TextLabel")  
world1_5_PositionTitle.Name = "Title"  
world1_5_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world1_5_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world1_5_PositionTitle.BackgroundTransparency = 1  
world1_5_PositionTitle.Text = "Island 5: Zen"  
world1_5_PositionTitle.Font = Enum.Font.GothamSemibold  
world1_5_PositionTitle.TextSize = 16  
world1_5_PositionTitle.TextColor3 = textColor  
world1_5_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world1_5_PositionTitle.Parent = world1_5_PositionContainer  

local world1_5_PositionDesc = Instance.new("TextLabel")  
world1_5_PositionDesc.Name = "Description"  
world1_5_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world1_5_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world1_5_PositionDesc.BackgroundTransparency = 1  
world1_5_PositionDesc.Text = "Unlock World 2 (the door near alien merchant), upgrade potion"  
world1_5_PositionDesc.Font = Enum.Font.Gotham  
world1_5_PositionDesc.TextSize = 12  
world1_5_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world1_5_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world1_5_PositionDesc.Parent = world1_5_PositionContainer  

local world1_5_PositionButton = Instance.new("TextButton")  
world1_5_PositionButton.Name = "ResetButton"  
world1_5_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world1_5_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world1_5_PositionButton.BackgroundColor3 = mainColor  
world1_5_PositionButton.BorderSizePixel = 0  
world1_5_PositionButton.Text = "Teleport"  
world1_5_PositionButton.Font = Enum.Font.GothamSemibold  
world1_5_PositionButton.TextSize = 14  
world1_5_PositionButton.TextColor3 = textColor  
world1_5_PositionButton.Parent = world1_5_PositionContainer  

---------------
createSectionHeader(tab5Page, "World 2", 30)

---------------------------


local world2_0_PositionContainer = Instance.new("Frame")  
world2_0_PositionContainer.Name = "ResetPositionContainer"  
world2_0_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world2_0_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world2_0_PositionContainer.BorderSizePixel = 0  
world2_0_PositionContainer.LayoutOrder = 30  
world2_0_PositionContainer.Parent = tab5Page  

local world2_0_PositionCorner = Instance.new("UICorner")  
world2_0_PositionCorner.CornerRadius = UDim.new(0, 6)  
world2_0_PositionCorner.Parent = world2_0_PositionContainer  

local world2_0_PositionTitle = Instance.new("TextLabel")  
world2_0_PositionTitle.Name = "Title"  
world2_0_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world2_0_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world2_0_PositionTitle.BackgroundTransparency = 1  
world2_0_PositionTitle.Text = "Spawn"  
world2_0_PositionTitle.Font = Enum.Font.GothamSemibold  
world2_0_PositionTitle.TextSize = 16  
world2_0_PositionTitle.TextColor3 = textColor  
world2_0_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world2_0_PositionTitle.Parent = world2_0_PositionContainer  

local world2_0_PositionDesc = Instance.new("TextLabel")  
world2_0_PositionDesc.Name = "Description"  
world2_0_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world2_0_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world2_0_PositionDesc.BackgroundTransparency = 1  
world2_0_PositionDesc.Text = "Board Game, Merchant here"  
world2_0_PositionDesc.Font = Enum.Font.Gotham  
world2_0_PositionDesc.TextSize = 12  
world2_0_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world2_0_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world2_0_PositionDesc.Parent = world2_0_PositionContainer  

local world2_0_PositionButton = Instance.new("TextButton")  
world2_0_PositionButton.Name = "ResetButton"  
world2_0_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world2_0_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world2_0_PositionButton.BackgroundColor3 = mainColor  
world2_0_PositionButton.BorderSizePixel = 0  
world2_0_PositionButton.Text = "Teleport"  
world2_0_PositionButton.Font = Enum.Font.GothamSemibold  
world2_0_PositionButton.TextSize = 14  
world2_0_PositionButton.TextColor3 = textColor  
world2_0_PositionButton.Parent = world2_0_PositionContainer  

---------------------------


local world2_1_PositionContainer = Instance.new("Frame")  
world2_1_PositionContainer.Name = "ResetPositionContainer"  
world2_1_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world2_1_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world2_1_PositionContainer.BorderSizePixel = 0  
world2_1_PositionContainer.LayoutOrder = 30  
world2_1_PositionContainer.Parent = tab5Page  

local world2_1_PositionCorner = Instance.new("UICorner")  
world2_1_PositionCorner.CornerRadius = UDim.new(0, 6)  
world2_1_PositionCorner.Parent = world2_1_PositionContainer  

local world2_1_PositionTitle = Instance.new("TextLabel")  
world2_1_PositionTitle.Name = "Title"  
world2_1_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world2_1_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world2_1_PositionTitle.BackgroundTransparency = 1  
world2_1_PositionTitle.Text = "Island 1: Dice island"  
world2_1_PositionTitle.Font = Enum.Font.GothamSemibold  
world2_1_PositionTitle.TextSize = 16  
world2_1_PositionTitle.TextColor3 = textColor  
world2_1_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world2_1_PositionTitle.Parent = world2_1_PositionContainer  

local world2_1_PositionDesc = Instance.new("TextLabel")  
world2_1_PositionDesc.Name = "Description"  
world2_1_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world2_1_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world2_1_PositionDesc.BackgroundTransparency = 1  
world2_1_PositionDesc.Text = "Card minigame here"  
world2_1_PositionDesc.Font = Enum.Font.Gotham  
world2_1_PositionDesc.TextSize = 12  
world2_1_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world2_1_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world2_1_PositionDesc.Parent = world2_1_PositionContainer  

local world2_1_PositionButton = Instance.new("TextButton")  
world2_1_PositionButton.Name = "ResetButton"  
world2_1_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world2_1_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world2_1_PositionButton.BackgroundColor3 = mainColor  
world2_1_PositionButton.BorderSizePixel = 0  
world2_1_PositionButton.Text = "Teleport"  
world2_1_PositionButton.Font = Enum.Font.GothamSemibold  
world2_1_PositionButton.TextSize = 14  
world2_1_PositionButton.TextColor3 = textColor  
world2_1_PositionButton.Parent = world2_1_PositionContainer  

---------------------------


local world2_2_PositionContainer = Instance.new("Frame")  
world2_2_PositionContainer.Name = "ResetPositionContainer"  
world2_2_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world2_2_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world2_2_PositionContainer.BorderSizePixel = 0  
world2_2_PositionContainer.LayoutOrder = 30  
world2_2_PositionContainer.Parent = tab5Page  

local world2_2_PositionCorner = Instance.new("UICorner")  
world2_2_PositionCorner.CornerRadius = UDim.new(0, 6)  
world2_2_PositionCorner.Parent = world2_2_PositionContainer  

local world2_2_PositionTitle = Instance.new("TextLabel")  
world2_2_PositionTitle.Name = "Title"  
world2_2_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world2_2_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world2_2_PositionTitle.BackgroundTransparency = 1  
world2_2_PositionTitle.Text = "Island 2: Minecart forest"  
world2_2_PositionTitle.Font = Enum.Font.GothamSemibold  
world2_2_PositionTitle.TextSize = 16  
world2_2_PositionTitle.TextColor3 = textColor  
world2_2_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world2_2_PositionTitle.Parent = world2_2_PositionContainer  

local world2_2_PositionDesc = Instance.new("TextLabel")  
world2_2_PositionDesc.Name = "Description"  
world2_2_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world2_2_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world2_2_PositionDesc.BackgroundTransparency = 1  
world2_2_PositionDesc.Text = "Cart minigame here"  
world2_2_PositionDesc.Font = Enum.Font.Gotham  
world2_2_PositionDesc.TextSize = 12  
world2_2_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world2_2_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world2_2_PositionDesc.Parent = world2_2_PositionContainer  

local world2_2_PositionButton = Instance.new("TextButton")  
world2_2_PositionButton.Name = "ResetButton"  
world2_2_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world2_2_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world2_2_PositionButton.BackgroundColor3 = mainColor  
world2_2_PositionButton.BorderSizePixel = 0  
world2_2_PositionButton.Text = "Teleport"  
world2_2_PositionButton.Font = Enum.Font.GothamSemibold  
world2_2_PositionButton.TextSize = 14  
world2_2_PositionButton.TextColor3 = textColor  
world2_2_PositionButton.Parent = world2_2_PositionContainer  

---------------------------


local world2_3_PositionContainer = Instance.new("Frame")  
world2_3_PositionContainer.Name = "ResetPositionContainer"  
world2_3_PositionContainer.Size = UDim2.new(1, 0, 0, 35)  
world2_3_PositionContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
world2_3_PositionContainer.BorderSizePixel = 0  
world2_3_PositionContainer.LayoutOrder = 30  
world2_3_PositionContainer.Parent = tab5Page  

local world2_3_PositionCorner = Instance.new("UICorner")  
world2_3_PositionCorner.CornerRadius = UDim.new(0, 6)  
world2_3_PositionCorner.Parent = world2_3_PositionContainer  

local world2_3_PositionTitle = Instance.new("TextLabel")  
world2_3_PositionTitle.Name = "Title"  
world2_3_PositionTitle.Size = UDim2.new(1, -30, 0, 15)  
world2_3_PositionTitle.Position = UDim2.new(0, 15, 0, 5)  
world2_3_PositionTitle.BackgroundTransparency = 1  
world2_3_PositionTitle.Text = "Island 3: Robot factory"  
world2_3_PositionTitle.Font = Enum.Font.GothamSemibold  
world2_3_PositionTitle.TextSize = 16  
world2_3_PositionTitle.TextColor3 = textColor  
world2_3_PositionTitle.TextXAlignment = Enum.TextXAlignment.Left  
world2_3_PositionTitle.Parent = world2_3_PositionContainer  

local world2_3_PositionDesc = Instance.new("TextLabel")  
world2_3_PositionDesc.Name = "Description"  
world2_3_PositionDesc.Size = UDim2.new(1, -30, 0, 10)  
world2_3_PositionDesc.Position = UDim2.new(0, 15, 0, 20)  
world2_3_PositionDesc.BackgroundTransparency = 1  
world2_3_PositionDesc.Text = "Here Claw minigame"  
world2_3_PositionDesc.Font = Enum.Font.Gotham  
world2_3_PositionDesc.TextSize = 12  
world2_3_PositionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)  
world2_3_PositionDesc.TextXAlignment = Enum.TextXAlignment.Left  
world2_3_PositionDesc.Parent = world2_3_PositionContainer  

local world2_3_PositionButton = Instance.new("TextButton")  
world2_3_PositionButton.Name = "ResetButton"  
world2_3_PositionButton.Size = UDim2.new(0, 100, 0, 30)  
world2_3_PositionButton.Position = UDim2.new(1, -115, 0.5, -15)  
world2_3_PositionButton.BackgroundColor3 = mainColor  
world2_3_PositionButton.BorderSizePixel = 0  
world2_3_PositionButton.Text = "Teleport"  
world2_3_PositionButton.Font = Enum.Font.GothamSemibold  
world2_3_PositionButton.TextSize = 14  
world2_3_PositionButton.TextColor3 = textColor  
world2_3_PositionButton.Parent = world2_3_PositionContainer  

---------------------------




    
    local resetPositionButtonCorner = Instance.new("UICorner")
    resetPositionButtonCorner.CornerRadius = UDim.new(0, 4)
    resetPositionButtonCorner.Parent = resetPositionButton
    
    local saveConfigContainer = Instance.new("Frame")
    saveConfigContainer.Name = "SaveConfigContainer"
    saveConfigContainer.Size = UDim2.new(1, 0, 0, 60)
    saveConfigContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    saveConfigContainer.BorderSizePixel = 0
    saveConfigContainer.LayoutOrder = 40
    saveConfigContainer.Parent = tab4Page
    
    local saveConfigCorner = Instance.new("UICorner")
    saveConfigCorner.CornerRadius = UDim.new(0, 6)
    saveConfigCorner.Parent = saveConfigContainer
    
    local saveConfigTitle = Instance.new("TextLabel")
    saveConfigTitle.Name = "Title"
    saveConfigTitle.Size = UDim2.new(1, -30, 0, 25)
    saveConfigTitle.Position = UDim2.new(0, 15, 0, 5)
    saveConfigTitle.BackgroundTransparency = 1
    saveConfigTitle.Text = "Save Configuration"
    saveConfigTitle.Font = Enum.Font.GothamSemibold
    saveConfigTitle.TextSize = 16
    saveConfigTitle.TextColor3 = textColor
    saveConfigTitle.TextXAlignment = Enum.TextXAlignment.Left
    saveConfigTitle.Parent = saveConfigContainer
    
    local saveConfigDesc = Instance.new("TextLabel")
    saveConfigDesc.Name = "Description"
    saveConfigDesc.Size = UDim2.new(1, -30, 0, 20)
    saveConfigDesc.Position = UDim2.new(0, 15, 0, 30)
    saveConfigDesc.BackgroundTransparency = 1
    saveConfigDesc.Text = "Save your current settings for future use"
    saveConfigDesc.Font = Enum.Font.Gotham
    saveConfigDesc.TextSize = 12
    saveConfigDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
    saveConfigDesc.TextXAlignment = Enum.TextXAlignment.Left
    saveConfigDesc.Parent = saveConfigContainer
    
    local saveConfigButton = Instance.new("TextButton")
    saveConfigButton.Name = "SaveButton"
    saveConfigButton.Size = UDim2.new(0, 100, 0, 30)
    saveConfigButton.Position = UDim2.new(1, -115, 0.5, -15)
    saveConfigButton.BackgroundColor3 = mainColor
    saveConfigButton.BorderSizePixel = 0
    saveConfigButton.Text = "Save"
    saveConfigButton.Font = Enum.Font.GothamSemibold
    saveConfigButton.TextSize = 14
    saveConfigButton.TextColor3 = textColor
    saveConfigButton.Parent = saveConfigContainer
    
    local saveConfigButtonCorner = Instance.new("UICorner")
    saveConfigButtonCorner.CornerRadius = UDim.new(0, 4)
    saveConfigButtonCorner.Parent = saveConfigButton
    
    local creditsLabel = Instance.new("TextLabel")
    creditsLabel.Name = "CreditsLabel"
    creditsLabel.Size = UDim2.new(1, 0, 0, 40)
    creditsLabel.Position = UDim2.new(0, 0, 0, 0)
    creditsLabel.BackgroundTransparency = 1
    creditsLabel.Text = "VN Bubble Simulator INFINITY by _ainh01"
    creditsLabel.Font = Enum.Font.GothamSemibold
    creditsLabel.TextSize = 14
    creditsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    creditsLabel.LayoutOrder = 100
    creditsLabel.Parent = tab4Page
    
    resetPositionButton.MouseButton1Click:Connect(function()
        config.windowPosition = UDim2.new(0.5, -250, 0.5, -250)
        mainFrame.Position = config.windowPosition
    end)
    
    saveConfigButton.MouseButton1Click:Connect(function()
        saveConfig()
        
        local oldText = saveConfigButton.Text
        saveConfigButton.Text = "Saved!"
        
        task.delay(1, function()
            saveConfigButton.Text = oldText
        end)
    end)

    

    world1_0_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.The Overworld.FastTravel.Spawn')
    end)

    world1_1_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.The Overworld.Islands.Floating Island.Island.Portal.Spawn')
    end)

    world1_2_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.The Overworld.Islands.Outer Space.Island.Portal.Spawn')
    end)

    world1_3_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.The Overworld.Islands.Twilight.Island.Portal.Spawn')
    end)

    world1_4_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.The Overworld.Islands.The Void.Island.Portal.Spawn')
    end)

    world1_5_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn')
    end)


    world2_0_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.Minigame Paradise.FastTravel.Spawn')
    end)

    world2_1_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.Minigame Paradise.Islands.Dice Island.Island.Portal.Spawn')
    end)

    world2_2_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.Minigame Paradise.Islands.Minecart Forest.Island.Portal.Spawn')
    end)

    world2_3_PositionButton.MouseButton1Click:Connect(function()
        TeleportRemoteFunction('Workspace.Worlds.Minigame Paradise.Islands.Robot Factory.Island.Portal.Spawn')
    end)


    
    
    closeButton.MouseButton1Click:Connect(function()
        config.windowPosition = mainFrame.Position
        saveConfig()
        
        for _, thread in pairs(threads) do
            if thread then
                task.cancel(thread)
            end
        end
        
        screenGui:Destroy()
    end)
    
    minimizeButton.MouseButton1Click:Connect(function()
        config.minimized = not config.minimized
        
        if config.minimized then
            tabContent.Visible = false
            tabButtons.Visible = false
            
            TweenService:Create(mainFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 320, 0, 30)
            }):Play()
            
            minimizeButton.Text = "□"
        else
            tabContent.Visible = true
            tabButtons.Visible = true
            
            TweenService:Create(mainFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 750, 0, 1000)
            }):Play()
            
            minimizeButton.Text = "−"
        end
    end)
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
            startPos = nil
            
            config.windowPosition = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    switchTab("Farming")
    
    autoBubbleToggle.SetState(config.autoBubble)
    autoClawToggle.SetState(config.autoClaw)
    autoBoardToggle.SetState(config.autoBoard)
    autoCardToggle.SetState(config.autoCard)
    autoCartToggle.SetState(config.autoCart)
    autoSellToggle.SetState(config.autoSell)
    autoSellDelaySlider.SetValue(config.autoSellDelay)
    autoCollectToggle.SetState(config.autoCollect)
    collectionRangeSlider.SetValue(config.collectionRange)
    collectionDelaySlider.SetValue(config.collectionDelay)
    autoGiantChestToggle.SetState(config.autoGiantChest)
    autoVoidChestToggle.SetState(config.autoVoidChest)
    autoFreeSpinToggle.SetState(config.autoFreeSpin)
    autoDogJumpToggle.SetState(config.autoDogJump)
    autoPlaytimeToggle.SetState(config.autoPlaytime)
    autoAlienMerchantToggle.SetState(config.autoAlienMerchant)
    autoBackMerchantToggle.SetState(config.autoBackMerchant)
    transparencySlider.SetValue(config.guiTransparency * 100)
    
    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        Toggles = {
            AutoBubble = autoBubbleToggle,
            AutoClaw = autoClawToggle,
            AutoClose = autoCloseToggle,
            AutoBoard = autoBoardToggle,
            AutoCard = autoCardToggle,
            AutoCart = autoCartToggle,
            AutoSell = autoSellToggle,
            AutoCollect = autoCollectToggle,
            AutoGiantChest = autoGiantChestToggle,
            AutoVoidChest = autoVoidChestToggle,
            AutoFreeSpin = autoFreeSpinToggle,
            AutoDogJump = autoDogJumpToggle,
            AutoPlaytime = autoPlaytimeToggle,
            AutoAlienMerchant = autoAlienMerchantToggle,
            AutoBackMerchant = autoBackMerchantToggle
        },
        Sliders = {
            AutoSellDelay = autoSellDelaySlider,
            CollectionRange = collectionRangeSlider,
            CollectionDelay = collectionDelaySlider,
            Transparency = transparencySlider
        },
        Status = {
            AutoCollect = autoCollectStatus,
            AutoGiantChest = autoGiantChestStatus,
            AutoVoidChest = autoVoidChestStatus,
            AutoFreeSpin = autoFreeSpinStatus,
            AutoDogJump = autoDogJumpStatus,
            AutoPlaytime = autoPlaytimeStatus,
            AutoAlienMerchant = autoAlienMerchantStatus,
            AutoBackMerchant = autoBackMerchantStatus,
            IslandFly = islandFlyStatus
        },
        Dropdowns = {
            IslandDropdown = islandDropdown
        },
        Buttons = {
            FlyToIsland = flyToIslandButton
        }
    }
end



local gui = createMainGUI()

local BubbleSimGUI = {}

function BubbleSimGUI:SetEnabled(feature, enabled)
    if config[feature] ~= nil then
        config[feature] = enabled
        
        if gui and gui.Toggles and gui.Toggles[feature] then
            gui.Toggles[feature].SetState(enabled)
        end
    end
end

function BubbleSimGUI:SetValue(feature, value)
    if config[feature] ~= nil then
        config[feature] = value
        
        if gui and gui.Sliders and gui.Sliders[feature] then
            gui.Sliders[feature].SetValue(value)
        end
    end
end

function BubbleSimGUI:GetConfig()
    return config
end

function BubbleSimGUI:SaveConfig()
    saveConfig()
end

function BubbleSimGUI:Destroy()
    for _, thread in pairs(threads) do
        if thread then
            task.cancel(thread)
        end
    end
    
    if gui and gui.ScreenGui then
        gui.ScreenGui:Destroy()
    end
end

return BubbleSimGUI
