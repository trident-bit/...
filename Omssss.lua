--Module 3: The Dumb Display)
--v2 Architecture

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local UI = {} -- Exposing the module table

-- ============================================================
-- COLORS & CONSTANTS
-- ============================================================
local C = {
    TitleBar  = Color3.fromHex("272222"),
    Toolbar   = Color3.fromHex("c0622a"),
    EditorBg  = Color3.fromHex("f5dfc8"),
    ButtonBg  = Color3.fromHex("d4743a"),
    ButtonHov = Color3.fromHex("b85e2a"),
    DupeName  = Color3.fromHex("4ecb71"),
    Text      = Color3.fromHex("1a0a00"),
    Border    = Color3.fromHex("8b3a1a"),
    Pink      = Color3.fromHex("f0b2d5"),
    TabActive = Color3.fromHex("d4743a"),
    TabInact  = Color3.fromHex("b85e2a"),
    BoxOn     = Color3.fromHex("c0622a"),
    BoxOff    = Color3.fromHex("a07060"),
    White     = Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- HELPERS
-- ============================================================
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function makeButton(text, parent, bgColor)
    local btn = make("TextButton", {
        Text              = text,
        Font              = Enum.Font.Code,
        TextSize          = 11,
        TextColor3        = C.White,
        BackgroundColor3  = bgColor or C.ButtonBg,
        BorderColor3      = C.Border,
        BorderSizePixel   = 1,
        AutomaticSize     = Enum.AutomaticSize.XY,
        BackgroundTransparency = 0,
    }, parent)

    local pad = make("UIPadding", {
        PaddingTop    = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft   = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10),
    }, btn)

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.ButtonHov end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = bgColor or C.ButtonBg end)
    return btn
end

-- ============================================================
-- INITIALIZATION (V2 ENTRY POINT)
-- ============================================================
function UI:Init(State)
    self.State = State
    self.Elements = {} -- Store references for Actions.lua
    self.SettingToggles = {} -- Store references for visual updates
    
    self:BuildUI()
    self:SubscribeToSignals()
end

function UI:BuildUI()
    local ScreenGui = make("ScreenGui", {
        Name           = "AlphaSpy",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, LocalPlayer.PlayerGui)

    self.Elements.MainGui = ScreenGui

    -- Main Window
    local Main = make("Frame", {
        Name             = "Main",
        Size             = UDim2.new(0, 620, 0, 380),
        Position         = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = C.EditorBg,
        BorderColor3     = C.Border,
        BorderSizePixel  = 1,
        ClipsDescendants = true,
    }, ScreenGui)
    self.Elements.MainWindow = Main
    make("UICorner", { CornerRadius = UDim.new(0, 4) }, Main)

    -- Body
    local Body = make("Frame", {
        Name             = "Body",
        Size             = UDim2.new(1, 0, 1, -26),
        Position         = UDim2.new(0, 0, 0, 26),
        BackgroundTransparency = 1,
    }, Main)

    -- ============================================================
    -- THE MATH FIX (Panels size Y is -44 instead of -32)
    -- ============================================================
    local LeftPanel = make("Frame", {
        Name             = "LeftPanel",
        Size             = UDim2.new(0, 155, 1, -44), 
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = C.Toolbar,
        BorderColor3     = C.Border,
        BorderSizePixel  = 1,
    }, Body)

    self.Elements.RemoteScroll = make("ScrollingFrame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 4,
        ScrollBarImageColor3   = C.Border,
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
    }, LeftPanel)
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, self.Elements.RemoteScroll)

    local RightPanel = make("Frame", {
        Name             = "RightPanel",
        Size             = UDim2.new(1, -155, 1, -44),
        Position         = UDim2.new(0, 155, 0, 0),
        BackgroundColor3 = C.EditorBg,
    }, Body)

    self.Elements.EditorBox = make("TextBox", {
        Name             = "EditorBox",
        Text             = "-- Waiting for logs...",
        Font             = Enum.Font.Code,
        TextSize         = 11,
        TextColor3       = C.Text,
        BackgroundColor3 = C.EditorBg,
        Size             = UDim2.new(1, 0, 1, -24),
        Position         = UDim2.new(0, 0, 0, 24),
        MultiLine        = true,
        ClearTextOnFocus = false,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextYAlignment   = Enum.TextYAlignment.Top,
    }, RightPanel)

    -- ============================================================
    -- THE MATH FIX (BottomBar Position Y is -44 instead of -32)
    -- ============================================================
    self.Elements.BottomBar = make("Frame", {
        Name             = "BottomBar",
        Size             = UDim2.new(1, 0, 0, 28),
        Position         = UDim2.new(0, 0, 1, -44),
        BackgroundColor3 = C.Toolbar,
        BorderColor3     = C.Border,
        BorderSizePixel  = 1,
    }, Body)
    make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center }, self.Elements.BottomBar)

    -- Action Buttons (Exposed for Actions.lua to bind clicks to)
    self.Elements.Buttons = {}
    local ACTIONS = {"Copy", "Repeat call", "Get return", "Generate info", "Decompile script", "Build"}
    for i, action in ipairs(ACTIONS) do
        local btn = makeButton(action, self.Elements.BottomBar)
        btn.LayoutOrder = i
        self.Elements.Buttons[action] = btn
    end

    -- Status Bar (Stays at -16, now sits perfectly under BottomBar)
    local StatusBar = make("Frame", {
        Size             = UDim2.new(1, 0, 0, 16),
        Position         = UDim2.new(0, 0, 1, -16),
        BackgroundColor3 = C.TitleBar,
        BorderSizePixel  = 0,
    }, Main)
    
    make("TextLabel", {
        Text           = "-- welcome to alpha spy v2",
        Font           = Enum.Font.Code,
        TextSize       = 10,
        TextColor3     = Color3.fromRGB(136, 136, 136),
        BackgroundTransparency = 1,
        AnchorPoint    = Vector2.new(0, 0.5),
        Size           = UDim2.new(0, 160, 1, 0),
        Position       = UDim2.new(0, 8, 0.5, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, StatusBar)
end

-- ============================================================
-- V2 SIGNAL SUBSCRIPTIONS
-- ============================================================
function UI:SubscribeToSignals()
    -- 1. Incremental Update
    self.State.Signals.OnLogAdded.Event:Connect(function(packet, groupNode)
        self:AppendLogToTree(packet, groupNode)
    end)
    
    -- 2. Full Rebuild
    self.State.Signals.OnStateRefreshed.Event:Connect(function()
        self:RebuildTreeFromState()
    end)
    
    -- 3. Selection Changed
    self.State.Signals.OnSelectionChanged.Event:Connect(function(newId, oldId)
        -- UI expects Actions.lua to update EditorBox text based on cache, 
        -- but UI can handle highlighting the tree item here.
        self:HighlightSelectedNode(newId)
    end)
    
    -- 4. Settings Changed
    self.State.Signals.OnSettingsChanged.Event:Connect(function(key, oldValue, newValue)
        self:UpdateSettingToggle(key, newValue)
        
        -- Special case logic delegated from blueprint
        if key == "No grouping" and newValue == false then
            self.State:RegroupAllLogs()
        end
        if key == "UI Visible (P)" then
            self.Elements.MainWindow.Visible = newValue
        end
    end)
end

-- ============================================================
-- PASSIVE RENDERING METHODS
-- ============================================================
function UI:AppendLogToTree(packet, groupNode)
    -- If grouping is off, just render a flat child row
    if self.State.Settings["No grouping"] then
        self:CreateChildRow(packet, self.Elements.RemoteScroll)
        return
    end

    -- If grouping is on, check if parent node exists in UI
    local parentId = "Parent_" .. groupNode.RemotePath
    local parentUi = self.Elements.RemoteScroll:FindFirstChild(parentId)

    if not parentUi then
        self:CreateParentRow(groupNode)
    else
        -- Parent exists, update count and append to its container if expanded
        parentUi.Text = "\u{25B6} " .. packet.RemoteName .. " (" .. groupNode.Count .. ")"
        local container = self.Elements.RemoteScroll:FindFirstChild("Container_" .. groupNode.RemotePath)
        if container and groupNode.IsExpanded then
            self:CreateChildRow(packet, container)
        end
    end
end

function UI:RebuildTreeFromState()
    -- Clear current UI tree
    for _, child in ipairs(self.Elements.RemoteScroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    if self.State.Settings["No grouping"] then
        for _, packet in ipairs(self.State.RawLogs) do
            self:CreateChildRow(packet, self.Elements.RemoteScroll)
        end
    else
        for path, node in pairs(self.State.GroupedLogs) do
            self:CreateParentRow(node)
            if node.IsExpanded then
                local container = self.Elements.RemoteScroll:FindFirstChild("Container_" .. node.RemotePath)
                for _, childPacket in ipairs(node.Children) do
                    self:CreateChildRow(childPacket, container)
                end
            end
        end
    end
end

function UI:CreateParentRow(node)
    local parentBtn = make("TextButton", {
        Name             = "Parent_" .. node.RemotePath,
        Text             = "\u{25B6} " .. node.RemoteName .. " (" .. node.Count .. ")",
        Font             = Enum.Font.Code,
        TextSize         = 11,
        TextColor3       = C.White,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 22),
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, self.Elements.RemoteScroll)
    make("UIPadding", { PaddingLeft = UDim.new(0, 4) }, parentBtn)

    local container = make("Frame", {
        Name             = "Container_" .. node.RemotePath,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible          = node.IsExpanded,
    }, self.Elements.RemoteScroll)
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, container)

    -- Inform Actions.lua to handle the click (UI holds no logic)
    parentBtn.MouseButton1Click:Connect(function()
        -- In a real setup, you'd route this via an exposed callback or BindableEvent 
        -- so Actions.lua can toggle node.IsExpanded in State and trigger a rebuild
    end)
end

function UI:CreateChildRow(packet, parentContainer)
    local btn = make("TextButton", {
        Name             = "Child_" .. packet.Id,
        Text             = "\u{25B6} " .. packet.Method,
        Font             = Enum.Font.Code,
        TextSize         = 11,
        TextColor3       = C.DupeName,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 22),
        TextXAlignment   = Enum.TextXAlignment.Left,
    }, parentContainer)
    make("UIPadding", { PaddingLeft = UDim.new(0, 18) }, btn)
    
    -- Expose for Actions.lua binding
    btn.MouseButton1Click:Connect(function()
        -- Actions.lua will handle this by calling State:SetSelectedLog(packet.Id)
    end)
end

function UI:HighlightSelectedNode(logId)
    -- Reset all backgrounds, highlight the current logId
end

function UI:UpdateSettingToggle(key, newValue)
    -- Visually update the specific toggle button in the Options tab
end

function UI:ShowNotification(message, duration)
    -- Renders a temporary text box
end

return UI
