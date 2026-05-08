local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- COLOR PALETTE (exact from original)
-- ============================================
local COLORS = {
    titleBar = Color3.fromHex("#272222"),
    toolbar = Color3.fromHex("#c0622a"),
    content = Color3.fromHex("#f0b2d5"),
    contentBg = Color3.fromHex("#e8a8c4"),
    buttonBg = Color3.fromHex("#d4743a"),
    buttonHover = Color3.fromHex("#b85e2a"),
    remoteArrow = Color3.fromHex("#c0622a"),
    dupeName = Color3.fromHex("#4ecb71"),
    text = Color3.fromHex("#1a0a00"),
    editorBg = Color3.fromHex("#f5dfc8"),
    tabActive = Color3.fromHex("#d4743a"),
    tabInactive = Color3.fromHex("#b85e2a"),
    border = Color3.fromHex("#8b3a1a"),
}

-- ============================================
-- SAMPLE DATA (exact from original)
-- ============================================
local SAMPLE_REMOTES = {
    {
        id = 1, name = "OnClientEvent", path = "RF/ChatService",
        dupes = {
            { id = 101, name = "OnClientEvent", path = "RF/ChatService" },
            { id = 102, name = "OnClientEvent", path = "RF/ChatService" },
            { id = 103, name = "OnClientEvent", path = "RF/ChatService" },
        }
    },
    { id = 2, name = "OnClientEvent", path = "RF/RodSkinServi", dupes = {} },
    {
        id = 6, name = "OnClientEvent", path = "RF/PlayerGui",
        dupes = {
            { id = 601, name = "OnClientEvent", path = "RF/PlayerGui" },
        }
    },
    { id = 7, name = "OnClientEvent", path = "RF/StarterGui", dupes = {} },
    { id = 8, name = "OnClientEvent", path = "RF/CoreGui", dupes = {} },
    { id = 9, name = "OnClientEvent", path = "RF/Backpack", dupes = {} },
    { id = 10, name = "OnClientEvent", path = "RF/Workspace", dupes = {} },
    { id = 11, name = "OnClientEvent", path = "RF/Players", dupes = {} },
    { id = 12, name = "OnClientEvent", path = "RF/ReplicatedStorage", dupes = {} },
    { id = 13, name = "OnClientEvent", path = "RF/ServerStorage", dupes = {} },
    { id = 14, name = "OnClientEvent", path = "RF/Lighting", dupes = {} },
    { id = 15, name = "OnClientEvent", path = "RF/SoundService", dupes = {} },
    { id = 16, name = "OnClientEvent", path = "RF/Teams", dupes = {} },
    { id = 17, name = "OnClientEvent", path = "RF/TextChatService", dupes = {} },
    { id = 18, name = "OnClientEvent", path = "RF/TweenService", dupes = {} },
    { id = 19, name = "OnClientEvent", path = "RF/RunService", dupes = {} },
    { id = 20, name = "OnClientEvent", path = "RF/UserInputService", dupes = {} },
    { id = 21, name = "OnClientEvent", path = "RF/HttpService", dupes = {} },
    { id = 22, name = "OnClientEvent", path = "RF/MarketplaceService", dupes = {} },
}

local DEFAULT_SCRIPT = [[-- Generated with Alpha Spy BOIIIIIIIII (+99999 AURA)
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote
local Set = ReplicatedStorage.packages._Index["ytrev_rep"]

-- This data was received from the server
firesignal(Set.OnClientEvent,
  {
    "Stats",
    "tracker_timeplayedStats",
  },
  17213.41981738427
)]]

local LOG_BUTTONS = {"Clear logs", "Clear blocks", "Clear excludes"}

local SETTINGS = {
    { label = "No parenting", toggle = false },
    { label = "No renaming", toggle = false },
    { label = "Keybinds Enabled", toggle = true },
    { label = "UI Visible", toggle = true, key = "P" },
    { label = "Ignore nil parents", toggle = true },
    { label = "Paused", toggle = false, key = "Q" },
    { label = "Ignore exploit cal", toggle = false },
    { label = "Log receives", toggle = true },
    { label = "No grouping", toggle = false },
    { label = "Find arg for name", toggle = true },
}

local INFO_LINES = {
    "Alpha Spy – Created by trident!",
    "Thank you to everyone for suggestions and testing",
    "I wish potassium wasn't so crudely produced",
    "Boiiiiiii what did you say about Alpha Spy (+99999 AURA)",
}

-- ============================================
-- STATE
-- ============================================
local state = {
    isOpen = true,
    activeTab = "Editor",
    selectedRemote = SAMPLE_REMOTES[1],
    selectedDupe = nil,
    script = DEFAULT_SCRIPT,
    remotes = SAMPLE_REMOTES,
    settings = table.clone(SETTINGS),
    notification = "",
    pos = { x = 40, y = 40 },
}

-- ============================================
-- PARSER INTEGRATION
-- ============================================
-- Expose remote data for the parser to inspect
-- The parser can call getgenv().AlphaSpyData to access all remotes
local ParserData = {
    Remotes = SAMPLE_REMOTES,
    SelectedRemote = nil,
    SelectedDupe = nil,
    ScriptSource = DEFAULT_SCRIPT,

    -- Helper for parser to get formatted remote info
    GetRemoteInfo = function(remote)
        return {
            Remote = remote.path,
            MetaMethod = "Connect",
            Method = "OnClientEvent",
            CallingScript = "CallingScript",
            CallingActor = "—",
            IsActor = false,
            Id = remote.id .. "_301174",
        }
    end,

    -- Helper for parser to get all remote paths
    GetAllPaths = function()
        local paths = {}
        for _, remote in ipairs(SAMPLE_REMOTES) do
            table.insert(paths, remote.path)
            for _, dupe in ipairs(remote.dupes) do
                table.insert(paths, dupe.path)
            end
        end
        return paths
    end,
}

-- ============================================
-- UI HELPERS
-- ============================================
local function create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop == "Parent" then
            instance.Parent = value
        elseif type(value) == "function" and string.sub(prop, 1, 2) == "On" then
            instance[prop]:Connect(value)
        else
            instance[prop] = value
        end
    end
    return instance
end

local function getLabel(remote)
    local parts = string.split(remote.path, "/")
    return parts[#parts] or remote.path
end

-- ============================================
-- MAIN UI
-- ============================================
local screenGui = create("ScreenGui", {
    Name = "AlphaSpy",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = playerGui,
})

-- Main window
local mainFrame = create("Frame", {
    Name = "MainWindow",
    Size = UDim2.new(0, 620, 0, 350),
    Position = UDim2.new(0, state.pos.x, 0, state.pos.y),
    BackgroundColor3 = COLORS.editorBg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = screenGui,
})

create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = mainFrame })
create("UIStroke", { Color = COLORS.border, Thickness = 1, Parent = mainFrame })

-- Shadow
local shadow = create("ImageLabel", {
    Name = "Shadow",
    Size = UDim2.new(1, 24, 1, 24),
    Position = UDim2.new(0, -12, 0, -12),
    BackgroundTransparency = 1,
    Image = "rbxassetid://1316045217",
    ImageColor3 = Color3.new(0, 0, 0),
    ImageTransparency = 0.3,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(10, 10, 118, 118),
    ZIndex = 0,
    Parent = mainFrame,
})

-- Notification toast
local notifFrame = create("Frame", {
    Name = "Notification",
    Size = UDim2.new(0, 200, 0, 22),
    Position = UDim2.new(0.5, -100, 1, -30),
    BackgroundColor3 = COLORS.titleBar,
    BorderSizePixel = 0,
    ZIndex = 99,
    Visible = false,
    Parent = mainFrame,
})
create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = notifFrame })
create("UIStroke", { Color = COLORS.border, Thickness = 1, Parent = notifFrame })

local notifText = create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    TextColor3 = COLORS.content,
    Font = Enum.Font.CourierNew,
    TextSize = 11,
    Text = "",
    Parent = notifFrame,
})

-- Title bar
local titleBar = create("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = COLORS.titleBar,
    BorderSizePixel = 0,
    Parent = mainFrame,
})

create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Alpha Spy",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.CourierNew,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = titleBar,
})

local closeBtn = create("TextButton", {
    Name = "CloseButton",
    Size = UDim2.new(0, 16, 0, 16),
    Position = UDim2.new(1, -22, 0.5, -8),
    BackgroundColor3 = COLORS.content,
    Text = "",
    AutoButtonColor = false,
    Parent = titleBar,
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeBtn })
create("UIStroke", { Color = Color3.fromHex("#aaaaaa"), Thickness = 1, Parent = closeBtn })

-- Content area
local contentArea = create("Frame", {
    Name = "ContentArea",
    Size = UDim2.new(1, 0, 1, -56),
    Position = UDim2.new(0, 0, 0, 28),
    BackgroundTransparency = 1,
    Parent = mainFrame,
})

-- ============================================
-- REMOTE LIST PANEL
-- ============================================
local remoteList = create("Frame", {
    Name = "RemoteList",
    Size = UDim2.new(0, 155, 1, 0),
    BackgroundColor3 = COLORS.toolbar,
    BorderSizePixel = 0,
    Parent = contentArea,
})
create("UIStroke", { Color = COLORS.border, Thickness = 2, Parent = remoteList })

local remoteScroll = create("ScrollingFrame", {
    Name = "Scroll",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = COLORS.border,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Parent = remoteList,
})

local remoteLayout = create("UIListLayout", {
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = remoteScroll,
})

-- ============================================
-- RIGHT PANEL
-- ============================================
local rightPanel = create("Frame", {
    Name = "RightPanel",
    Size = UDim2.new(1, -155, 1, 0),
    Position = UDim2.new(0, 155, 0, 0),
    BackgroundColor3 = COLORS.editorBg,
    BorderSizePixel = 0,
    Parent = contentArea,
})

-- Tabs bar
local tabsBar = create("Frame", {
    Name = "TabsBar",
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = COLORS.toolbar,
    BorderSizePixel = 0,
    Parent = rightPanel,
})
create("UIStroke", { Color = COLORS.border, Thickness = 2, Parent = tabsBar })

local tabsList = create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = tabsBar,
})

-- Tab content container
local tabContent = create("Frame", {
    Name = "TabContent",
    Size = UDim2.new(1, 0, 1, -28),
    Position = UDim2.new(0, 0, 0, 28),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = rightPanel,
})

-- Editor tab
local editorTab = create("Frame", {
    Name = "Editor",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = true,
    Parent = tabContent,
})

local scriptBox = create("TextBox", {
    Name = "ScriptBox",
    Size = UDim2.new(1, -16, 1, -16),
    Position = UDim2.new(0, 8, 0, 8),
    BackgroundTransparency = 1,
    Text = DEFAULT_SCRIPT,
    TextColor3 = COLORS.text,
    Font = Enum.Font.CourierNew,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false,
    MultiLine = true,
    TextWrapped = true,
    Parent = editorTab,
})

-- Options tab
local optionsTab = create("Frame", {
    Name = "Options",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = tabContent,
})

local optionsScroll = create("ScrollingFrame", {
    Name = "Scroll",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = COLORS.border,
    CanvasSize = UDim2.new(0, 0, 0, 400),
    Parent = optionsTab,
})

create("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = optionsScroll,
})

create("UIPadding", {
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    PaddingTop = UDim.new(0, 8),
    Parent = optionsScroll,
})

-- Remote tab
local remoteTab = create("Frame", {
    Name = "Remote",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = tabContent,
})

local remoteInfoText = create("TextLabel", {
    Name = "Info",
    Size = UDim2.new(1, -16, 1, -16),
    Position = UDim2.new(0, 8, 0, 8),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = COLORS.text,
    Font = Enum.Font.CourierNew,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Parent = remoteTab,
})

-- ============================================
-- OPTIONS TAB CONTENT
-- ============================================

-- Logs section
local logsSection = create("Frame", {
    Name = "LogsSection",
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundTransparency = 1,
    Parent = optionsScroll,
})

create("TextLabel", {
    Name = "Label",
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    Text = "-- Logs",
    TextColor3 = COLORS.text,
    Font = Enum.Font.CourierNew,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = logsSection,
})

create("Frame", {
    Name = "Divider",
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 0, 18),
    BackgroundColor3 = COLORS.border,
    BorderSizePixel = 0,
    Parent = logsSection,
})

local logsButtonsFrame = create("Frame", {
    Name = "Buttons",
    Size = UDim2.new(1, 0, 0, 26),
    Position = UDim2.new(0, 0, 0, 22),
    BackgroundTransparency = 1,
    Parent = logsSection,
})

create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 5),
    Parent = logsButtonsFrame,
})

-- Settings section
local settingsSection = create("Frame", {
    Name = "SettingsSection",
    Size = UDim2.new(1, 0, 0, 200),
    BackgroundTransparency = 1,
    Parent = optionsScroll,
})

create("TextLabel", {
    Name = "Label",
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    Text = "-- Settings",
    TextColor3 = COLORS.text,
    Font = Enum.Font.CourierNew,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = settingsSection,
})

create("Frame", {
    Name = "Divider",
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 0, 18),
    BackgroundColor3 = COLORS.border,
    BorderSizePixel = 0,
    Parent = settingsSection,
})

local settingsGrid = create("Frame", {
    Name = "Grid",
    Size = UDim2.new(1, 0, 1, -22),
    Position = UDim2.new(0, 0, 0, 22),
    BackgroundTransparency = 1,
    Parent = settingsSection,
})

-- Info section
local infoSection = create("Frame", {
    Name = "InfoSection",
    Size = UDim2.new(1, 0, 0, 120),
    BackgroundTransparency = 1,
    Parent = optionsScroll,
})

create("TextLabel", {
    Name = "Label",
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    Text = "-- Information",
    TextColor3 = COLORS.text,
    Font = Enum.Font.CourierNew,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = infoSection,
})

create("Frame", {
    Name = "Divider",
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 0, 18),
    BackgroundColor3 = COLORS.border,
    BorderSizePixel = 0,
    Parent = infoSection,
})

local infoList = create("Frame", {
    Name = "List",
    Size = UDim2.new(1, 0, 1, -22),
    Position = UDim2.new(0, 0, 0, 22),
    BackgroundTransparency = 1,
    Parent = infoSection,
})

create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = infoList,
})

-- ============================================
-- BOTTOM TOOLBAR
-- ============================================
local bottomToolbar = create("Frame", {
    Name = "BottomToolbar",
    Size = UDim2.new(1, 0, 0, 32),
    Position = UDim2.new(0, 0, 1, -52),
    BackgroundColor3 = COLORS.toolbar,
    BorderSizePixel = 0,
    Parent = mainFrame,
})
create("UIStroke", { Color = COLORS.border, Thickness = 2, Parent = bottomToolbar })

create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 2),
    Parent = bottomToolbar,
})

create("UIPadding", {
    PaddingLeft = UDim.new(0, 6),
    PaddingTop = UDim.new(0, 4),
    Parent = bottomToolbar,
})

-- Status bar
local statusBar = create("Frame", {
    Name = "StatusBar",
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 1, -20),
    BackgroundColor3 = COLORS.titleBar,
    BorderSizePixel = 0,
    Parent = mainFrame,
})

create("TextLabel", {
    Name = "Left",
    Size = UDim2.new(0.5, 0, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "-- welcome to alpha spy",
    TextColor3 = Color3.fromHex("#888888"),
    Font = Enum.Font.CourierNew,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = statusBar,
})

create("TextLabel", {
    Name = "Right",
    Size = UDim2.new(0.5, -8, 1, 0),
    Position = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "-- made by trident",
    TextColor3 = Color3.fromHex("#888888"),
    Font = Enum.Font.CourierNew,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = statusBar,
})

-- ============================================
-- MINIMIZED WINDOW
-- ============================================
local minimizedFrame = create("Frame", {
    Name = "Minimized",
    Size = UDim2.new(0, 220, 0, 28),
    Position = UDim2.new(0, state.pos.x, 0, state.pos.y),
    BackgroundColor3 = COLORS.titleBar,
    BorderSizePixel = 0,
    Visible = false,
    Parent = screenGui,
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = minimizedFrame })
create("UIStroke", { Color = COLORS.border, Thickness = 1, Parent = minimizedFrame })

create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Alpha Spy",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.CourierNew,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = minimizedFrame,
})

local openBtn = create("TextButton", {
    Name = "OpenButton",
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(1, -20, 0.5, -7),
    BackgroundColor3 = COLORS.content,
    Text = "",
    AutoButtonColor = false,
    Parent = minimizedFrame,
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = openBtn })
create("UIStroke", { Color = Color3.fromHex("#aaaaaa"), Thickness = 1, Parent = openBtn })

-- ============================================
-- FUNCTIONALITY
-- ============================================

local tabs = {"Editor", "Options", "Remote:"}
local tabButtons = {}
local tabContents = {
    Editor = editorTab,
    Options = optionsTab,
    ["Remote:"] = remoteTab,
}

-- Create tab buttons
for _, tabName in ipairs(tabs) do
    local tabBtn = create("TextButton", {
        Name = tabName,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = (tabName == state.activeTab) and COLORS.tabActive or COLORS.tabInactive,
        Text = tabName,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.CourierNew,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = tabsBar,
    })

    create("UIPadding", {
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        Parent = tabBtn,
    })

    create("UIStroke", { Color = COLORS.border, Thickness = 1, Parent = tabBtn })

    tabButtons[tabName] = tabBtn

    tabBtn.MouseEnter:Connect(function()
        if state.activeTab ~= tabName then
            tabBtn.BackgroundColor3 = COLORS.tabActive
        end
    end)

    tabBtn.MouseLeave:Connect(function()
        if state.activeTab ~= tabName then
            tabBtn.BackgroundColor3 = COLORS.tabInactive
        end
    end)

    tabBtn.MouseButton1Click:Connect(function()
        state.activeTab = tabName
        for name, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = (name == tabName) and COLORS.tabActive or COLORS.tabInactive
            btn.Font = (name == tabName) and Enum.Font.CourierNewBold or Enum.Font.CourierNew
        end
        for name, content in pairs(tabContents) do
            content.Visible = (name == tabName)
        end
    end)
end

-- Set initial fonts
for name, btn in pairs(tabButtons) do
    btn.Font = (name == state.activeTab) and Enum.Font.CourierNewBold or Enum.Font.CourierNew
end

-- Notification system
local notifTween = nil
local function showNotif(msg)
    state.notification = msg
    notifText.Text = msg
    notifFrame.Visible = true
    notifFrame.Size = UDim2.new(0, 0, 0, 22)

    if notifTween then notifTween:Cancel() end

    notifTween = TweenService:Create(notifFrame, TweenInfo.new(0.2), {
        Size = UDim2.new(0, math.max(200, #msg * 7), 0, 22)
    })
    notifTween:Play()

    task.delay(1.8, function()
        if state.notification == msg then
            notifFrame.Visible = false
            state.notification = ""
        end
    end)
end

-- Action handlers
local function handleAction(action)
    if action == "Copy" then
        showNotif("Calling script copied!")
    elseif action == "Repeat call" then
        showNotif("Repeating call...")
    elseif action == "Get return" then
        showNotif("Getting return value...")
    elseif action == "Generate info" then
        showNotif("Generating info...")
    elseif action == "Decompile script" then
        showNotif("Decompiling...")
    elseif action == "Build" then
        showNotif("Building...")
    end
end

-- Create bottom toolbar buttons
local actionButtons = {"Copy", "Repeat call", "Get return", "Generate info", "Decompile script", "Build"}
for _, action in ipairs(actionButtons) do
    local btn = create("TextButton", {
        Name = action,
        Size = UDim2.new(0, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = COLORS.buttonBg,
        Text = action,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.CourierNew,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = bottomToolbar,
    })

    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = btn })
    create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = btn })
    create("UIStroke", { Color = COLORS.border, Thickness = 1, Parent = btn })

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = COLORS.buttonHover
    end)

    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = COLORS.buttonBg
    end)

    btn.MouseButton1Click:Connect(function()
        handleAction(action)
    end)
end

-- Create log buttons
for _, btnText in ipairs(LOG_BUTTONS) do
    local btn = create("TextButton", {
        Name = btnText,
        Size = UDim2.new(0, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = COLORS.buttonBg,
        Text = btnText,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.CourierNew,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = logsButtonsFrame,
    })

    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = btn })
    create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = btn })
    create("UIStroke", { Color = COLORS.border, Thickness = 1, Parent = btn })

    btn.MouseButton1Click:Connect(function()
        showNotif(btnText .. "...")
    end)
end

-- Settings grid
local settingsFrames = {}

local function toggleSetting(index)
    state.settings[index].toggle = not state.settings[index].toggle
    local s = state.settings[index]
    local frame = settingsFrames[index]
    if frame then
        frame.BackgroundColor3 = s.toggle and Color3.fromRGB(192, 98, 42) or Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = s.toggle and 0.75 or 0.9

        local checkmark = frame:FindFirstChild("Checkmark")
        if checkmark then
            checkmark.TextColor3 = s.toggle and COLORS.toolbar or Color3.fromHex("#aaaaaa")
            checkmark.Text = s.toggle and "✓" or "✗"
        end

        local stroke = frame:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = s.toggle and COLORS.border or Color3.fromHex("#c09080")
        end
    end
end

create("UIGridLayout", {
    CellSize = UDim2.new(0.32, -3, 0, 28),
    CellPadding = UDim.new(0, 4),
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = settingsGrid,
})

for i, setting in ipairs(state.settings) do
    local frame = create("Frame", {
        Name = "Setting_" .. i,
        BackgroundColor3 = setting.toggle and Color3.fromRGB(192, 98, 42) or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = setting.toggle and 0.75 or 0.9,
        BorderSizePixel = 0,
        Parent = settingsGrid,
    })

    create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = frame })
    create("UIStroke", { Color = setting.toggle and COLORS.border or Color3.fromHex("#c09080"), Thickness = 1, Parent = frame })

    create("TextLabel", {
        Name = "Checkmark",
        Size = UDim2.new(0, 14, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text = setting.toggle and "✓" or "✗",
        TextColor3 = setting.toggle and COLORS.toolbar or Color3.fromHex("#aaaaaa"),
        Font = Enum.Font.CourierNew,
        TextSize = 10,
        Parent = frame,
    })

    create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = setting.label,
        TextColor3 = COLORS.text,
        Font = Enum.Font.CourierNew,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    if setting.key then
        local keyBadge = create("TextLabel", {
            Name = "KeyBadge",
            Size = UDim2.new(0, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            Position = UDim2.new(1, -4, 0.5, -7),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = COLORS.titleBar,
            Text = setting.key,
            TextColor3 = COLORS.content,
            Font = Enum.Font.CourierNew,
            TextSize = 9,
            Parent = frame,
        })

        create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = keyBadge })
        create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = keyBadge })
    end

    local clickArea = create("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })

    clickArea.MouseButton1Click:Connect(function()
        toggleSetting(i)
    end)

    settingsFrames[i] = frame
end

-- Info lines
for _, line in ipairs(INFO_LINES) do
    local infoFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Parent = infoList,
    })

    create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = infoFrame })
    create("UIStroke", { Color = Color3.fromHex("#c09080"), Thickness = 1, Parent = infoFrame })

    create("TextLabel", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = "• " .. line,
        TextColor3 = COLORS.text,
        Font = Enum.Font.CourierNew,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = infoFrame,
    })
end

-- ============================================
-- REMOTE LIST RENDERING
-- ============================================
local remoteItems = {}
local dupeItems = {}

local function updateParserSelection()
    ParserData.SelectedRemote = state.selectedRemote
    ParserData.SelectedDupe = state.selectedDupe
    ParserData.ScriptSource = state.script
end

local function updateRemoteInfo()
    local activeRemote = state.selectedDupe or state.selectedRemote
    if activeRemote then
        remoteInfoText.Text = string.format(
            "Remote: %s
" ..
            "MetaMethod: Connect
" ..
            "Method: OnClientEvent
" ..
            "Remote: %s
" ..
            "CallingScript: CallingScript
" ..
            "CallingActor: —
" ..
            "IsActor: false
" ..
            "Id: %d_301174",
            state.selectedRemote.path,
            state.selectedRemote.path,
            state.selectedRemote.id
        )
    end
    updateParserSelection()
end

local function renderRemoteList()
    for _, item in ipairs(remoteItems) do
        item:Destroy()
    end
    remoteItems = {}
    for _, item in ipairs(dupeItems) do
        item:Destroy()
    end
    dupeItems = {}

    for _, remote in ipairs(state.remotes) do
        local isParentSelected = state.selectedRemote and state.selectedRemote.id == remote.id
        local showDupes = isParentSelected and #remote.dupes > 0

        -- Parent row
        local parentFrame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundColor3 = isParentSelected and not state.selectedDupe and Color3.fromRGB(0, 0, 0) or Color3.new(1, 1, 1),
            BackgroundTransparency = isParentSelected and not state.selectedDupe and 0.75 or 1,
            BorderSizePixel = 0,
            Parent = remoteScroll,
        })

        create("Frame", {
            Name = "LeftBorder",
            Size = UDim2.new(0, 2, 1, 0),
            BackgroundColor3 = isParentSelected and not state.selectedDupe and COLORS.content or Color3.new(1, 1, 1),
            BackgroundTransparency = isParentSelected and not state.selectedDupe and 0 or 1,
            BorderSizePixel = 0,
            Parent = parentFrame,
        })

        create("TextLabel", {
            Name = "Arrow",
            Size = UDim2.new(0, 12, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            BackgroundTransparency = 1,
            Text = showDupes and "▼" or "▶",
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.CourierNew,
            TextSize = 9,
            Parent = parentFrame,
        })

        create("TextLabel", {
            Name = "Name",
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 16, 0, 0),
            BackgroundTransparency = 1,
            Text = getLabel(remote),
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.CourierNew,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = parentFrame,
        })

        local clickBtn = create("TextButton", {
            Name = "Click",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = parentFrame,
        })

        clickBtn.MouseButton1Click:Connect(function()
            state.selectedRemote = remote
            state.selectedDupe = nil
            renderRemoteList()
            updateRemoteInfo()
        end)

        clickBtn.MouseEnter:Connect(function()
            if not (isParentSelected and not state.selectedDupe) then
                parentFrame.BackgroundTransparency = 0.85
            end
        end)

        clickBtn.MouseLeave:Connect(function()
            if not (isParentSelected and not state.selectedDupe) then
                parentFrame.BackgroundTransparency = 1
            end
        end)

        table.insert(remoteItems, parentFrame)

        -- Dupe rows
        if showDupes then
            for _, dupe in ipairs(remote.dupes) do
                local isDupeSelected = state.selectedDupe and state.selectedDupe.id == dupe.id

                local dupeFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundColor3 = isDupeSelected and Color3.fromRGB(0, 0, 0) or Color3.new(1, 1, 1),
                    BackgroundTransparency = isDupeSelected and 0.75 or 1,
                    BorderSizePixel = 0,
                    Parent = remoteScroll,
                })

                create("Frame", {
                    Name = "LeftBorder",
                    Size = UDim2.new(0, 2, 1, 0),
                    BackgroundColor3 = isDupeSelected and COLORS.dupeName or Color3.new(1, 1, 1),
                    BackgroundTransparency = isDupeSelected and 0 or 1,
                    BorderSizePixel = 0,
                    Parent = dupeFrame,
                })

                create("TextLabel", {
                    Name = "Arrow",
                    Size = UDim2.new(0, 12, 1, 0),
                    Position = UDim2.new(0, 16, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "▶",
                    TextColor3 = COLORS.dupeName,
                    Font = Enum.Font.CourierNew,
                    TextSize = 9,
                    Parent = dupeFrame,
                })

                create("TextLabel", {
                    Name = "Name",
                    Size = UDim2.new(1, -32, 1, 0),
                    Position = UDim2.new(0, 28, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "Dupe " .. getLabel(dupe),
                    TextColor3 = COLORS.dupeName,
                    Font = Enum.Font.CourierNew,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = dupeFrame,
                })

                local dupeClick = create("TextButton", {
                    Name = "Click",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = dupeFrame,
                })

                dupeClick.MouseButton1Click:Connect(function()
                    state.selectedDupe = dupe
                    renderRemoteList()
                    updateRemoteInfo()
                end)

                dupeClick.MouseEnter:Connect(function()
                    if not isDupeSelected then
                        dupeFrame.BackgroundTransparency = 0.85
                    end
                end)

                dupeClick.MouseLeave:Connect(function()
                    if not isDupeSelected then
                        dupeFrame.BackgroundTransparency = 1
                    end
                end)

                table.insert(dupeItems, dupeFrame)
            end
        end
    end

    task.wait()
    remoteScroll.CanvasSize = UDim2.new(0, 0, 0, remoteLayout.AbsoluteContentSize.Y)
end

-- ============================================
-- CLOSE / OPEN / DRAG
-- ============================================
closeBtn.MouseButton1Click:Connect(function()
    state.isOpen = false
    mainFrame.Visible = false
    minimizedFrame.Visible = true
    minimizedFrame.Position = mainFrame.Position
end)

openBtn.MouseButton1Click:Connect(function()
    state.isOpen = true
    mainFrame.Visible = true
    minimizedFrame.Visible = false
    mainFrame.Position = minimizedFrame.Position
end)

local isDragging = false
local dragOffset = Vector2.new(0, 0)

local function startDrag(input, frame)
    isDragging = true
    dragOffset = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        startDrag(input, mainFrame)
    end
end)

minimizedFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        startDrag(input, minimizedFrame)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local newPos = UDim2.new(0, input.Position.X - dragOffset.X, 0, input.Position.Y - dragOffset.Y)
        if state.isOpen then
            mainFrame.Position = newPos
        else
            minimizedFrame.Position = newPos
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

-- Script box sync
scriptBox:GetPropertyChangedSignal("Text"):Connect(function()
    state.script = scriptBox.Text
    ParserData.ScriptSource = state.script
end)

-- ============================================
-- INITIALIZE
-- ============================================
renderRemoteList()
updateRemoteInfo()

mainFrame.Visible = state.isOpen
minimizedFrame.Visible = not state.isOpen

-- Expose parser data globally
getgenv().AlphaSpyData = ParserData

print("Alpha Spy loaded successfully")
