local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local AutoSkipToggle

local lp = Players.LocalPlayer

local UI_URL = "https://raw.githubusercontent.com/xLiqua/CustomUI/refs/heads/main/CustomUI.lua"
local Library = loadstring(game:HttpGet(UI_URL))()()

local Window = Library.CreateWindow({
    Name = "Peanut Physical Farm",
    Theme = "Crimson"
})

Window:SetTheme("Crimson")

local Knit = require(ReplicatedStorage.Packages.knit)
local EggsService = Knit.GetService("EggsService")

local RollRemote = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("050fe8d5a6a97a361fe7d0bd")
    :WaitForChild("1320")
    :WaitForChild("1309e7dc948f6d25")

local Settings = {
    AutoClick = false,

    AutoEgg = false,
    AutoClosestEgg = false,
    SelectedEgg = "Toy",
    MaxHatch = nil,

    AutoRoll = false,
    SelectedDice = nil,

    AutoFarm = false,
    AntiFling = false,
    AutoSkipWaves = false,
    AntiAFK = false,

    TargetMode = "Path Progress",
    TP_Offset = Vector3.new(0, 2, 0),
    SelectedDungeon = "Space",

    Locations = {
        Forest = CFrame.new(-1707.29688, 237.287125, 2868.65527),
        Desert = CFrame.new(-1707.078, 237.287125, 2841.67847, -0.0157781448, 1.00458173e-07, 0.999875546, 8.65464311e-10, 1, -1.00457022e-07, -0.999875546, -7.1966888e-10, -0.0157781448),
        Space = CFrame.new(-1706.82764, 238.224487, 2814.32129, 0.193366438, -5.47239551e-08, 0.981126606, -2.34872335e-08, 1, 6.04056538e-08, -0.981126606, -3.47243763e-08, 0.193366438)
    }
}

local MaxHatchConnection

local AutoSkipThread = nil
local AutoSkipRunId = 0
local AutoSkipRunning = false

local function getMaxHatchAmountObject()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return nil end

    local ok, amount = pcall(function()
        return pg.ToolTips.ToolTips.EggUI.Container.Buttons.HatchMax.Amount
    end)

    if ok and amount and amount:IsA("TextLabel") then
        return amount
    end

    return nil
end

local function updateMaxHatch()
    local amount = getMaxHatchAmountObject()
    if not amount then return Settings.MaxHatch end

    local n = tonumber(tostring(amount.Text):match("%d+"))
    if n and n > 0 then
        Settings.MaxHatch = n
        return n
    end

    return Settings.MaxHatch
end

local function hookMaxHatchLive()
    task.spawn(function()
        while true do
            local amount = getMaxHatchAmountObject()

            if amount then
                updateMaxHatch()

                if MaxHatchConnection then
                    MaxHatchConnection:Disconnect()
                    MaxHatchConnection = nil
                end

                MaxHatchConnection = amount:GetPropertyChangedSignal("Text"):Connect(updateMaxHatch)
                break
            end

            task.wait(0.5)
        end
    end)
end

hookMaxHatchLive()

local function getLiveMaxHatch()
    return updateMaxHatch()
end

local function getClickButton()
    local pg = lp:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("Main")
    local hud = main and main:FindFirstChild("HUD")
    local bottom = hud and hud:FindFirstChild("Bottom")
    local clickers = bottom and bottom:FindFirstChild("Clickers")
    return clickers and clickers:FindFirstChild("ClickButton")
end

local function runAutoClick()
    while Settings.AutoClick do
        local btn = getClickButton()

        if btn then
            for _, conn in ipairs(getconnections(btn.Activated)) do
                pcall(function()
                    conn:Fire()
                end)
            end
        end

        RunService.Heartbeat:Wait()
    end
end

local function getEggList()
    local eggs = {}
    local main = workspace:FindFirstChild("__Main")
    local folder = main and main:FindFirstChild("__Eggs")

    if folder then
        for _, egg in ipairs(folder:GetChildren()) do
            if egg:IsA("Model") then
                table.insert(eggs, egg.Name)
            end
        end
    end

    table.sort(eggs)

    if #eggs == 0 then
        table.insert(eggs, "Toy")
    end

    return eggs
end

local function getClosestEgg()
    local char = lp.Character or lp.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local main = workspace:FindFirstChild("__Main")
    local folder = main and main:FindFirstChild("__Eggs")
    if not folder then return nil end

    local closestEgg
    local closestDist = math.huge

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model") then
            local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)

            if part then
                local dist = (part.Position - root.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestEgg = egg
                end
            end
        end
    end

    return closestEgg
end

local function runAutoEgg()
    while Settings.AutoEgg do
        local max = getLiveMaxHatch()

        if Settings.SelectedEgg and max then
            EggsService.HatchEggs:Fire(Settings.SelectedEgg, max)
        end

        task.wait(0.1)
    end
end

local function runAutoClosestEgg()
    while Settings.AutoClosestEgg do
        local egg = getClosestEgg()
        local max = getLiveMaxHatch()

        if egg and max then
            Settings.SelectedEgg = egg.Name
            EggsService.HatchEggs:Fire(egg.Name, max)
        end

        task.wait(0.1)
    end
end

local function getDiceList()
    local dices = {}

    local ok, folder = pcall(function()
        return lp.PlayerGui.OtherGuis.AuraRoll.Frames.AuraRoll.Dices
    end)

    if ok and folder then
        for _, child in ipairs(folder:GetChildren()) do
            table.insert(dices, child.Name)
        end
    end

    table.sort(dices)

    if #dices == 0 then
        table.insert(dices, "None")
    end

    return dices
end

local function runAutoRoll()
    while Settings.AutoRoll do
        if Settings.SelectedDice and Settings.SelectedDice ~= "None" then
            pcall(function()
                RollRemote:InvokeServer(Settings.SelectedDice, 3)
            end)
        end

        task.wait(0.1)
    end
end

local function runAntiAFK()
    while Settings.AntiAFK do
        VIM:SendMouseMoveEvent(1, 1, game)
        task.wait(0.1)
        VIM:SendMouseMoveEvent(0, 0, game)

        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)

        task.wait(180)
    end
end

local function physicalClick(obj)
    if not obj then return end

    local absPos = obj.AbsolutePosition
    local absSize = obj.AbsoluteSize
    local inset = GuiService:GetGuiInset()

    local x = absPos.X + (absSize.X / 2) + inset.X
    local y = absPos.Y + (absSize.Y / 2) + inset.Y

    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

local function handleDungeonEnd()
    local hud = lp.PlayerGui.Main.HUD:FindFirstChild("DungeonEnd")
    if hud and hud.Visible then
        local btn = hud:FindFirstChild("Accept")
            and hud.Accept:FindFirstChild("Container")
            and hud.Accept.Container:FindFirstChild("Design")

        if btn then
            physicalClick(btn)
            return true
        end
    end

    return false
end

local function adjustDungeonSpeed()
    local hud = lp.PlayerGui.Main.HUD:FindFirstChild("Dungeon")
    local speedBtn = hud and hud:FindFirstChild("AdjustSpeed")

    if speedBtn and speedBtn.Visible then
        physicalClick(speedBtn)
        task.wait(0.1)

        local fastChild = speedBtn:FindFirstChild("Fast")
        if fastChild then
            physicalClick(fastChild)
        end
    end
end

local function startDungeonPhysical()
    local startUI = lp.PlayerGui:FindFirstChild("OtherGuis")
        and lp.PlayerGui.OtherGuis:FindFirstChild("StartDungeon")

    if startUI then
        local btn = startUI:FindFirstChild("Start", true)
        if btn and btn.Visible then
            physicalClick(btn)
            return true
        end
    end

    return false
end

local function clickSkipWave()
    local btn = lp.PlayerGui
        and lp.PlayerGui:FindFirstChild("Main")
        and lp.PlayerGui.Main:FindFirstChild("HUD")
        and lp.PlayerGui.Main.HUD:FindFirstChild("Dungeon")
        and lp.PlayerGui.Main.HUD.Dungeon:FindFirstChild("SkipWave")

    if btn and btn.Visible then
        local inset = GuiService:GetGuiInset()
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize

        local x = pos.X + size.X / 2 + inset.X
        local y = pos.Y + size.Y / 2 + inset.Y

        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end
end

local function isFastVisible()
    local ok, fast = pcall(function()
        return lp.PlayerGui.Main.HUD.Dungeon.AdjustSpeed.Fast
    end)

    return ok and fast and fast.Visible == true
end

local function runAutoSkipWaves()
    if AutoSkipRunning then return end
    AutoSkipRunning = true

    while true do
        if not Settings.AutoSkipWaves then break end

        local dungeon = workspace.__Main.__DungeonRuns:FindFirstChild(tostring(lp.UserId))

        if dungeon then
            if isFastVisible() then
                adjustDungeonSpeed()
            else
                clickSkipWave()
            end
        end

        task.wait(0.10)
    end

    AutoSkipRunning = false
end

local function getBestTarget(myDungeon)
    local petsFolder = myDungeon:FindFirstChild("ClientDungeonPets")
    local waypointsFolder = myDungeon:FindFirstChild("Waypoints")

    if not petsFolder or not waypointsFolder then return nil end

    local pets = {}

    for _, p in ipairs(petsFolder:GetDescendants()) do
        if p:IsA("Model") or (p:IsA("BasePart") and p.Parent == petsFolder) then
            table.insert(pets, p)
        end
    end

    if #pets == 0 then return nil end

    if Settings.TargetMode == "Path Progress" then
        local waypoints = {}

        for i = 1, 11 do
            local wp = waypointsFolder:FindFirstChild(tostring(i))
            if wp then
                table.insert(waypoints, {
                    Part = wp,
                    Index = i
                })
            end
        end

        local bestPet
        local highestAssumedWp = -1

        for _, pet in ipairs(pets) do
            local petPos = pet:IsA("Model") and pet:GetPivot().Position or pet.Position
            local closestWpIndex = 0
            local minDist = math.huge

            for _, wp in ipairs(waypoints) do
                local dist = (petPos - wp.Part.Position).Magnitude

                if dist < minDist then
                    minDist = dist
                    closestWpIndex = wp.Index
                end
            end

            local assumedWp = math.min(closestWpIndex + 1, 11)

            if assumedWp > highestAssumedWp then
                highestAssumedWp = assumedWp
                bestPet = pet
            end
        end

        return bestPet or pets[1]
    end

    return pets[1]
end

local function runDungeonLoop()
    local dungeonRuns = workspace:WaitForChild("__Main"):WaitForChild("__DungeonRuns")
    local wasInDungeon = false
    local speedAdjusted = false

    while Settings.AutoFarm do
        local myDungeon = dungeonRuns:FindFirstChild(tostring(lp.UserId))

        if not myDungeon then
            if wasInDungeon then
                repeat
                    handleDungeonEnd()
                    task.wait(0.5)
                until not lp.PlayerGui.Main.HUD.DungeonEnd.Visible or not Settings.AutoFarm

                task.wait(3)
                wasInDungeon = false
                speedAdjusted = false
            end

            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = Settings.Locations[Settings.SelectedDungeon]
                task.wait(1)
            end

            local started = startDungeonPhysical()

            if started then
                task.wait(6.5)
            else
                task.wait(1)
            end
        else
            wasInDungeon = true

            if not Settings.AutoSkipWaves then
                if not isFastVisible() then
                    adjustDungeonSpeed()
                end
            end

            local currentTarget = getBestTarget(myDungeon)

            if currentTarget then
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                local tPos = currentTarget:IsA("Model") and currentTarget:GetPivot().Position or currentTarget.Position

                if hrp and tPos then
                    hrp.CFrame = CFrame.new(tPos + Settings.TP_Offset)
                end
            end
        end

        task.wait()
    end
end

RunService.Stepped:Connect(function()
    if Settings.AntiFling and lp.Character then
        for _, v in pairs(lp.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
                v.Velocity = Vector3.zero
                v.RotVelocity = Vector3.zero
            end
        end
    end
end)

local AutomationTab = Window:CreateTab("Automation")
local AutoEggTab = Window:CreateTab("Auto Egg")
local AutoRollTab = Window:CreateTab("Auto Roll")
local MainTab = Window:CreateTab("Autofarm")
local SettingsTab = Window:CreateTab("Settings")

AutomationTab:CreateToggle({
    Name = "Auto Click Button",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoClick = v
        if v then
            task.spawn(runAutoClick)
        end
    end
})

AutoEggTab:CreateDropdown({
    Name = "Select Egg",
    Options = getEggList(),
    CurrentOption = Settings.SelectedEgg,
    Callback = function(Value)
        Settings.SelectedEgg = Value
    end
})

AutoEggTab:CreateToggle({
    Name = "Auto Hatch Selected Egg",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoEgg = v

        if v then
            Settings.AutoClosestEgg = false
            task.spawn(runAutoEgg)
        end
    end
})

AutoEggTab:CreateToggle({
    Name = "Auto Open Closest Egg",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoClosestEgg = v

        if v then
            Settings.AutoEgg = false
            task.spawn(runAutoClosestEgg)
        end
    end
})

local diceOptions = getDiceList()
Settings.SelectedDice = diceOptions[1]

AutoRollTab:CreateDropdown({
    Name = "Select Dice",
    Options = diceOptions,
    CurrentOption = Settings.SelectedDice,
    Callback = function(Value)
        Settings.SelectedDice = Value
    end
})

AutoRollTab:CreateToggle({
    Name = "Auto Roll Selected Dice",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoRoll = v

        if v then
            task.spawn(runAutoRoll)
        end
    end
})

MainTab:CreateToggle({
    Name = "Enable Physical Farm",
    CurrentValue = false,
    Callback = function(v)
        Settings.AutoFarm = v

        if v then
            task.spawn(runDungeonLoop)
        end
    end
})

MainTab:CreateDropdown({
    Name = "Target Mode",
    Options = { "Normal", "Path Progress" },
    CurrentOption = "Path Progress",
    Callback = function(Value)
        Settings.TargetMode = Value
    end
})

MainTab:CreateDropdown({
    Name = "Select Dungeon",
    Options = { "Forest", "Desert", "Space" },
    CurrentOption = "Space",
    Callback = function(Value)
        Settings.SelectedDungeon = Value
    end
})

MainTab:CreateSlider({
    Name = "TP Height",
    Range = { 0, 15 },
    Increment = 1,
    CurrentValue = 2,
    Callback = function(v)
        Settings.TP_Offset = Vector3.new(0, v, 0)
    end
})

local UpdatingAutoSkipUI = false

local function setAutoSkip(state, fromUI)
    Settings.AutoSkipWaves = state
    AutoSkipRunId += 1

    if not fromUI and AutoSkipToggle then
        UpdatingAutoSkipUI = true
        if AutoSkipToggle.Set then
            AutoSkipToggle:Set(state)
        elseif AutoSkipToggle.SetValue then
            AutoSkipToggle:SetValue(state)
        end
        UpdatingAutoSkipUI = false
    end

    if state then
        local thisRun = AutoSkipRunId
        AutoSkipThread = task.spawn(function()
            runAutoSkipWaves(thisRun)
        end)
    end
end

AutoSkipToggle = MainTab:CreateToggle({
    Name = "Auto Skip Waves",
    CurrentValue = false,
    Callback = function(v)
        if UpdatingAutoSkipUI then return end
        setAutoSkip(v, true)
    end
})

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.LeftBracket then
        setAutoSkip(not Settings.AutoSkipWaves, false)
    end
end)

SettingsTab:CreateToggle({
    Name = "Anti-Fling (No Collide)",
    CurrentValue = false,
    Callback = function(v)
        Settings.AntiFling = v
    end
})

SettingsTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Callback = function(v)
        Settings.AntiAFK = v

        if v then
            task.spawn(runAntiAFK)
        end
    end
})

SettingsTab:CreateSlider({
    Name = "UI Scale",
    Range = { 0.5, 2 },
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(Value)
        local targets = {
            game:GetService("CoreGui"),
            lp.PlayerGui
        }

        for _, parent in ipairs(targets) do
            for _, gui in ipairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") and (gui.Name:find("CustomUI") or gui.Name:find("Library")) then
                    local mainFrame = gui:FindFirstChildWhichIsA("Frame")

                    if mainFrame then
                        local scaler = mainFrame:FindFirstChild("UIScale") or Instance.new("UIScale", mainFrame)
                        scaler.Scale = Value
                    end
                end
            end
        end
    end
})

SettingsTab:CreateDropdown({
    Name = "UI Theme",
    Options = Window:GetThemes(),
    CurrentOption = "Nebula",
    Callback = function(Value)
        Window:SetTheme(Value)
    end
})

SettingsTab:CreateButton({
    Name = "Unload UI",
    Callback = function()
        Settings.AutoClick = false
        Settings.AutoEgg = false
        Settings.AutoClosestEgg = false
        Settings.AutoRoll = false
        Settings.AutoFarm = false
        Settings.AntiFling = false
        Settings.AntiAFK = false
        Settings.AutoSkipWaves = false

        if MaxHatchConnection then
            MaxHatchConnection:Disconnect()
            MaxHatchConnection = nil
        end

        local targets = {
            game:GetService("CoreGui"),
            lp.PlayerGui
        }

        for _, parent in ipairs(targets) do
            for _, gui in ipairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") and (gui.Name:find("CustomUI") or gui.Name:find("Library")) then
                    gui:Destroy()
                end
            end
        end
    end
})
