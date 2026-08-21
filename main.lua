-- ============================================================
-- Blox Fruits Hub — Fruit ESP + Status | AutoFish | AutoRepair | M1 Aura
-- UI: Wabi Sabi (Matcha)
-- ============================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera


local SEA1_ID = 2753915549
local SEA2_ID = 4442272183
local SEA3_ID = 7449423635
local currentPlaceId = game.PlaceId


pcall(function()
    setrobloxinput(true)
end)


local Library = nil         
_G.FE_Unloaded = false      


local function feEnabled(id)
    if not Library or not Library.Options then return true end

    local okMaster, master = pcall(function()
        return Library.Options.fe_master.Value
    end)
    if okMaster and master == false then return false end

    local okVal, v = pcall(function()
        return Library.Options[id].Value
    end)
    if not okVal or v == nil then return true end
    return v ~= false
end


local FishConfig = {
    CastTarget = 0.96,
    DeadZone = 0.35,
    BiteTimeout = 20,
    ResetDelay = 2,
}

local FishState = {
    Running = false,
    LoopActive = false,
    IsHolding = false,
    CastComplete = false,
    FishDetected = false,
    ReelingStarted = false,
    FishCaught = 0,
    LastCastTime = 0,
    BiteClickTime = 0,
}

local LocalPlayer = player
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function SafeClick()
    pcall(function()
        mouse1click()
    end)
end

local function FishHold()
    if not FishState.IsHolding then
        FishState.IsHolding = true
        pcall(function() mouse1press() end)
    end
end

local function FishRelease()
    if FishState.IsHolding then
        FishState.IsHolding = false
        pcall(function() mouse1release() end)
    end
end

local function FishFullReset(reason)
    FishRelease()
    FishState.CastComplete = false
    FishState.FishDetected = false
    FishState.ReelingStarted = false
    FishState.LastCastTime = 0
    FishState.BiteClickTime = 0
    print("[AutoFish] Reset:", reason)
    task.wait(FishConfig.ResetDelay)
end

local function HasCastMeter()
    local char = LocalPlayer.Character
    if not char then return false end
    return char:FindFirstChild("Fishing_Cast Meter") ~= nil
end

local function GetCastFill()
    local char = LocalPlayer.Character
    if not char then return 0 end

    local part = char:FindFirstChild("Fishing_Cast Meter")
    if not part then return 0 end
    local meter = part:FindFirstChild("CastMeter")
    if not meter then return 0 end
    local bar = meter:FindFirstChild("Bar")
    if not bar then return 0 end
    local frame = bar:FindFirstChild("Frame")
    if not frame then return 0 end

    local ok1, size = pcall(function() return frame.AbsoluteSize.Y end)
    local ok2, max = pcall(function() return frame.Parent.AbsoluteSize.Y end)
    if ok1 and ok2 and max and max > 0 then
        return size / max
    end
    return 0
end

local function IsFishBiting()
    local char = LocalPlayer.Character
    if not char then return false end

    if char:FindFirstChild("FishOnLine", true) then
        return true
    end

    for _, obj in ipairs(char:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("fishonline") or name:find("fish on line") then
            return true
        end
    end
    return false
end

local function GetReelUI()
    local ui = PlayerGui:FindFirstChild("Fishing_Reeling")
    if not ui then return nil end
    local mini = ui:FindFirstChild("Minigame") or ui:FindFirstChild("MiniGame")
    if not mini then return nil end
    local container = mini:FindFirstChild("Container")
    if not container then return nil end

    local treasure = container:FindFirstChild("Treasure")
    local treasureIcon = nil

    if treasure then
        local unopened = treasure:FindFirstChild("UnopenedIcon")
        local opened = treasure:FindFirstChild("OpenedIcon")

        if unopened and unopened.Visible and unopened.AbsoluteSize.X > 10 then
            treasureIcon = unopened
        elseif opened and opened.Visible and opened.AbsoluteSize.X > 10 then
            treasureIcon = opened
        end
    end

    return {
        Fish = container:FindFirstChild("Fish"),
        Treasure = treasureIcon,
        Zone = container:FindFirstChild("ReelZone") or container:FindFirstChild("Zone"),
    }
end

local function IsReelOpen()
    return PlayerGui:FindFirstChild("Fishing_Reeling") ~= nil
end

local function GetCenter(obj)
    if not obj then return 0 end
    local ok1, x = pcall(function() return obj.AbsolutePosition.X end)
    local ok2, w = pcall(function() return obj.AbsoluteSize.X end)
    if ok1 and ok2 then
        return x + w / 2
    end
    return 0
end

local function ShouldHold(ui)
    if not ui or not ui.Zone then return false end

    local target = nil

 
    if ui.Treasure then
        target = ui.Treasure
    elseif ui.Fish then
        target = ui.Fish
    end

    if not target then return false end

    local targetCenter = GetCenter(target)
    local zoneCenter = GetCenter(ui.Zone)

    if targetCenter == 0 or zoneCenter == 0 then return false end

    return zoneCenter < targetCenter - FishConfig.DeadZone
end

local function FishMainLoop()
    local wasOpen = false

    while FishState.Running do
        task.wait(0.04)

        if not FishState.CastComplete then
            if HasCastMeter() then
                local fill = GetCastFill()
                FishHold()

                if fill >= FishConfig.CastTarget then
                    FishRelease()
                    task.wait(0.2)

                    FishState.CastComplete = true
                    FishState.FishDetected = false
                    FishState.ReelingStarted = false
                    FishState.LastCastTime = os.clock()
                    wasOpen = false
                    print("[AutoFish] Cast done, waiting bite...")
                end
            else
                FishRelease()
                task.wait(0.2)
                SafeClick()
                task.wait(0.3)
            end
            continue
        end

        if FishState.CastComplete and not FishState.FishDetected then
            if os.clock() - FishState.LastCastTime > FishConfig.BiteTimeout then
                FishFullReset("Too long without bite (" .. FishConfig.BiteTimeout .. "s)")
                continue
            end

            if IsFishBiting() then
                print("[AutoFish] Bite detected! Clicking...")
                FishState.FishDetected = true
                FishState.BiteClickTime = os.clock()
                SafeClick()
                task.wait(0.14)
                SafeClick()
                task.wait(0.14)
                SafeClick()
            end
            continue
        end

        if FishState.FishDetected then
            if IsReelOpen() then
                wasOpen = true
                local ui = GetReelUI()
                if ui then
                    if not FishState.ReelingStarted then
                        FishState.ReelingStarted = true
                        print("[AutoFish] Reeling started")
                    end

                    if ShouldHold(ui) then
                        FishHold()
                    else
                        FishRelease()
                    end
                end
            else
                if wasOpen then
                    FishState.FishCaught += 1
                    FishRelease()
                    print("[AutoFish] Caught! Total:", FishState.FishCaught)
                    pcall(function()
                        notify("Fish caught! (" .. FishState.FishCaught .. ")", "AutoFish", 2)
                    end)

                    FishState.CastComplete = false
                    FishState.FishDetected = false
                    FishState.ReelingStarted = false
                    wasOpen = false
                    task.wait(0.5)
                else
                    if os.clock() - FishState.BiteClickTime > 3 then
                        FishFullReset("Reeling UI did not open")
                    end
                end
            end
        end
    end
end

local function FishStart()
    if FishState.Running then return end
    FishState.Running = true
    FishState.CastComplete = false
    FishState.FishDetected = false
    FishState.ReelingStarted = false
    FishState.LastCastTime = 0
    FishState.BiteClickTime = 0
    task.spawn(function()
        FishState.LoopActive = true
        FishMainLoop()
        FishState.LoopActive = false
    end)
    print("[AutoFish] Started")
end

local function FishStop()
    FishState.Running = false
    FishRelease()
    print("[AutoFish] Stopped. Total:", FishState.FishCaught)
end


local RepState = {
    Running = false,
    IsHolding = false,
}

local function getBarInfo()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end

    local mini = pg:FindFirstChild("Main")
        and pg.Main:FindFirstChild("BottomHUDList")
        and pg.Main.BottomHUDList:FindFirstChild("RepairMiniGame")
    if not mini then return nil end

    local progress = mini:FindFirstChild("ProgressBar")
    if not progress then return nil end

    local fill = progress:FindFirstChild("Fill")
    local goal = progress:FindFirstChild("Goal")
    if not fill or not goal then return nil end

    return {
        Fill = fill,
        Goal = goal
    }
end

local function isInGreenZone(info)
    if not info then return false end

    local fillRight = info.Fill.AbsolutePosition.X + info.Fill.AbsoluteSize.X
    local goalLeft  = info.Goal.AbsolutePosition.X
    local goalRight = info.Goal.AbsolutePosition.X + info.Goal.AbsoluteSize.X

    return fillRight >= (goalLeft - 8) and fillRight <= (goalRight + 14)
end

local function RepHold()
    if not RepState.IsHolding then
        RepState.IsHolding = true
        pcall(mouse1press)
    end
end

local function RepRelease()
    if RepState.IsHolding then
        RepState.IsHolding = false
        pcall(mouse1release)
    end
end

local function RepMainLoop()
    print("[AutoRepair] Started")

    while RepState.Running do
        local info = getBarInfo()

        if info then
            RepHold()

            if isInGreenZone(info) then
                RepRelease()
                print("[AutoRepair] Released in green")
                task.wait(0.35)
            end
        else
            RepRelease()
        end

        task.wait(0.02)
    end

    RepRelease()
    print("[AutoRepair] Stopped")
end

local function RepStart()
    if RepState.Running then return end
    RepState.Running = true
    task.spawn(RepMainLoop)
    print("[AutoRepair] ON")
end

local function RepStop()
    RepState.Running = false
    RepRelease()
    print("[AutoRepair] OFF")
end



local AuraConfig = {
    MAX_DISTANCE = 100,
    MIN_DISTANCE = 1,
    SESSION_ID = "32501259",
}

local AuraEnabled = false
local AuraTargetCount = 0
local AuraFirstTargetName = "None"

local RegisterAttack, RegisterHit
do
    local Net = ReplicatedStorage:FindFirstChild("Modules")
    if Net then Net = Net:FindFirstChild("Net") end
    if Net then
        RegisterAttack = Net:FindFirstChild("RE/RegisterAttack")
        RegisterHit = Net:FindFirstChild("RE/RegisterHit")
    end
end
if not RegisterAttack or not RegisterHit then
    print("[M1 Aura] Remote events not found — module inactive")
end

local hudText = Drawing.new("Text")
hudText.Size = 18
hudText.Font = Drawing.Fonts.SystemBold
hudText.Color = Color3.fromRGB(255, 255, 255)
hudText.Outline = true
hudText.Center = false
hudText.Position = Vector2.new(10, 50)
hudText.Visible = false
hudText.Text = "Targets: 0 | OFF"

local function updateHUD()
    local statusStr = AuraEnabled and "ON" or "OFF"
    hudText.Text = string.format("Targets: %d (%s) | %s", AuraTargetCount, AuraFirstTargetName, statusStr)
    pcall(function() hudText.Visible = AuraEnabled end)
end

local function getTargetPart(enemy)
    if not enemy or not enemy.Parent then return nil end
    local part = enemy:FindFirstChild("LeftLowerLeg")
    if part and part:IsA("BasePart") then return part end
    part = enemy:FindFirstChild("Head")
    if part and part:IsA("BasePart") then return part end
    part = enemy:FindFirstChild("HumanoidRootPart")
    if part and part:IsA("BasePart") then return part end
    for _, child in ipairs(enemy:GetChildren()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

local function getEnemiesInRange()
    local character = LocalPlayer.Character
    if not character then return {} end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    local myPos = hrp.Position

    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return {} end

    local results = {}
    local enemyList = enemiesFolder:GetChildren()
    for _, enemy in ipairs(enemyList) do
        if enemy and enemy.Parent then  
            local humanoid = enemy:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health and humanoid.Health > 0 then
                local part = getTargetPart(enemy)
                if part and part.Parent then  
                    local ok, pos = pcall(function() return part.Position end)
                    if ok and pos then
                        local dist = (pos - myPos).Magnitude
                        if dist <= AuraConfig.MAX_DISTANCE and dist >= AuraConfig.MIN_DISTANCE then
                            table.insert(results, {enemy = enemy, part = part, dist = dist})
                        end
                    end
                end
            end
        end
    end
    return results
end

local function AttackMultiple(enemyList)
    if not AuraEnabled or #enemyList == 0 then return end
    if not RegisterAttack or not RegisterHit then return end

    local hitTable = {}
    local primaryPart = nil
    for _, entry in ipairs(enemyList) do
        if entry.enemy and entry.enemy.Parent and entry.part and entry.part.Parent then
            table.insert(hitTable, {entry.enemy, entry.part})
            if not primaryPart then
                primaryPart = entry.part
            end
        end
    end

    if #hitTable == 0 then return end

    RegisterAttack:FireServer(0.5)
    task.wait()
    RegisterHit:FireServer(primaryPart, hitTable, nil, AuraConfig.SESSION_ID)
end


local FirstSeaIslands = {
    {Name = "Starter Island", Position = Vector3.new(1014.48, 15.83, 1462.93)},
    {Name = "Jungle", Position = Vector3.new(-1419.21, -3.78, -76.86)},
    {Name = "Pirate Village", Position = Vector3.new(-1133.21, -3.78, 4176.14)},
    {Name = "Desert", Position = Vector3.new(1193.79, -13.78, 4430.14)},
    {Name = "Frozen Village", Position = Vector3.new(1276.79, -13.78, -1472.86)},
    {Name = "Marine Fortress", Position = Vector3.new(-4935.21, -13.78, 4318.14)},
    {Name = "Starter Marine", Position = Vector3.new(-2964.51, 41.08, 2122.72)},
    {Name = "Skylands", Position = Vector3.new(-5024.21, 794.4, -2618.69)},
    {Name = "Prison", Position = Vector3.new(5277.79, -13.78, 743.14)},
    {Name = "Colosseum", Position = Vector3.new(-1685.21, -13.78, -3200.86)},
    {Name = "Magma Village", Position = Vector3.new(-5528.21, -13.78, 8691.14)},
    {Name = "Underwater City", Position = Vector3.new(61379.79, -13.78, 1473.14)},
    {Name = "Fountain City", Position = Vector3.new(5717.79, -13.78, 4356.14)},
}


local SecondSeaIslands = {
    {Name = "Kingdom of Rose", Position = Vector3.new(-195.1, 155.3, 279.9)},
    {Name = "Green Zone", Position = Vector3.new(-2340.8, 155.3, -3396.3)},
    {Name = "Graveyard", Position = Vector3.new(-5929.64, 87.55, -1188.64)},
    {Name = "Snow Mountain", Position = Vector3.new(856.2, 50.3, -5278.3)},
    {Name = "Hot and Cold", Position = Vector3.new(-5296.24, 214.96, -5518.59)},
    {Name = "Haunted Ship", Position = Vector3.new(900.94, 143.97, 33072.64)},
    {Name = "Winter Castle", Position = Vector3.new(6062.26, 155.3, -6880.86)},
    {Name = "Skull", Position = Vector3.new(-3194.24, 155.3, -10795.26)},
    {Name = "Remote", Position = Vector3.new(4762.69, 8.38, 2853.69)},
    {Name = "Dark Arena", Position = Vector3.new(3807.1, 11.8, -3452.2)},
}


local ThirdSeaIslands = {
    {Name = "Castle on the Sea", Position = Vector3.new(-5436.61, 815.64, -2701.66)},
    {Name = "Turtle Mansion", Position = Vector3.new(-12547.71, 290.14, -7487.07)},
    {Name = "Turtle Entrance", Position = Vector3.new(-10159.20, 331.83, -8338.58)},
    {Name = "Turtle Mountain", Position = Vector3.new(-12851.91, 844.43, -10732.79)},
    {Name = "Turtle Center", Position = Vector3.new(-12003.31, 331.79, -9196.02)},
    {Name = "Port Town", Position = Vector3.new(-610.37, 57.83, 6436.34)},
    {Name = "Hydra Town", Position = Vector3.new(5275.71, 1005.42, 404.14)},
    {Name = "Hydra Arena", Position = Vector3.new(6473.16, 52.34, -1231.78)},
    {Name = "Great Tree", Position = Vector3.new(3036.29, 815.64, -7149.86)},
    {Name = "Floating Turtle", Position = Vector3.new(-12164.61, -548.86, -8454.87)},
    {Name = "Haunted Castle", Position = Vector3.new(-9530.61, -132.86, 5763.14)},
    {Name = "Tiki Outpost", Position = Vector3.new(-16641.51, 213.31, 435.38)},
    {Name = "Ice Cream Land", Position = Vector3.new(-819.38, 62.26, -10967.28)},
    {Name = "Peanut Land", Position = Vector3.new(-2105.53, 34.49, -10195.51)},
    {Name = "Chocolate Land", Position = Vector3.new(297.76, 28.37, -12724.31)},
    {Name = "Cake Land", Position = Vector3.new(-2022.3, 34.17, -12030.98)},
}


local IslandsBySea = {
    [SEA1_ID] = FirstSeaIslands,
    [SEA2_ID] = SecondSeaIslands,
    [SEA3_ID] = ThirdSeaIslands,
}


local Islands = IslandsBySea[currentPlaceId] or {}


local function getIslandName(pos)
    local closest = "Unknown"
    local minDist = math.huge


    for _, island in ipairs(Islands) do
        local dist = (pos - island.Position).Magnitude
        if dist < minDist then
            minDist = dist
            closest = island.Name
        end
    end


    if minDist > 10000 then
        return "Sea"
    end


    return closest
end


_G.FruitStatusDrawings = _G.FruitStatusDrawings or {}
for _, d in pairs(_G.FruitStatusDrawings) do
    pcall(function() d:Remove() end)
end
_G.FruitStatusDrawings = {}


_G.FruitESP = _G.FruitESP or {}
for _, d in pairs(_G.FruitESP) do
    pcall(function() d.Text:Remove() end)
end
_G.FruitESP = {}


local function createText(text, size, color, center)
    local t = Drawing.new("Text")
    t.Text = text or ""
    t.Size = size or 15
    t.Color = color or Color3.fromRGB(255, 255, 255)
    t.Center = center or false
    t.Outline = true
    t.Visible = true
    table.insert(_G.FruitStatusDrawings, t)
    return t
end


local UI_X = 2250
local UI_Y = 400


local title = createText("SERVER STATUS", 17)
title.Position = Vector2.new(UI_X, UI_Y)


local dealer = createText("", 14)
dealer.Position = Vector2.new(UI_X, UI_Y + 24)


local fruitLine1 = createText("", 14, Color3.fromRGB(80, 255, 100))
fruitLine1.Position = Vector2.new(UI_X, UI_Y + 48)


local fruitLine2 = createText("", 14, Color3.fromRGB(80, 255, 100))
fruitLine2.Position = Vector2.new(UI_X, UI_Y + 66)


local fruitLine3 = createText("", 14, Color3.fromRGB(80, 255, 100))
fruitLine3.Position = Vector2.new(UI_X, UI_Y + 84)


local distance = createText("", 14, Color3.fromRGB(255, 220, 80))
distance.Position = Vector2.new(UI_X, UI_Y + 108)


local count = createText("", 14, Color3.fromRGB(180, 200, 255))
count.Position = Vector2.new(UI_X, UI_Y + 128)


if currentPlaceId == SEA3_ID then
    dealer.Visible = false
end


local function applyPanelPos()
    local x, y = UI_X, UI_Y
    if Library and Library.Options then
        pcall(function()
            x = Library.Options.fe_pos_x.Value or UI_X
            y = Library.Options.fe_pos_y.Value or UI_Y
        end)
    end
    title.Position    = Vector2.new(x, y)
    dealer.Position   = Vector2.new(x, y + 24)
    fruitLine1.Position = Vector2.new(x, y + 48)
    fruitLine2.Position = Vector2.new(x, y + 66)
    fruitLine3.Position = Vector2.new(x, y + 84)
    distance.Position = Vector2.new(x, y + 108)
    count.Position    = Vector2.new(x, y + 128)
end


local function applyPanelSize()
    if not (Library and Library.Options) then return end
    pcall(function()
        local s = Library.Options.fe_text_size.Value or 14
        title.Size = s + 3
        dealer.Size = s
        fruitLine1.Size = s
        fruitLine2.Size = s
        fruitLine3.Size = s
        distance.Size = s
        count.Size = s
    end)
end


local function isFruit(obj)
    if not obj:IsA("Tool") then return false end
    local handle = obj:FindFirstChild("Handle")
    return handle and handle:IsA("BasePart")
end


local function getFruitName(obj)
    if not obj then return "Fruit" end
    local name = obj.Name
    if name and name ~= "" and name ~= "Fruit" and name ~= "Handle" then
        return name
    end
    return "Fruit"
end


local function createESP(obj, name)
    local handle = obj:FindFirstChild("Handle")
    if not handle then return end


    local text = Drawing.new("Text")
    text.Text = name
    text.Size = 14
    text.Color = Color3.fromRGB(0, 255, 120)
    text.Center = true
    text.Outline = true
    text.Visible = false


    _G.FruitESP[obj] = {
        Text = text,
        Handle = handle,
        Name = name
    }
end


local function removeESP(obj)
    local data = _G.FruitESP[obj]
    if data and data.Text then
        pcall(function() data.Text:Remove() end)
    end
    _G.FruitESP[obj] = nil
end


local function updateESP()
    if not feEnabled("fe_esp") then
        for _, data in pairs(_G.FruitESP) do
            if data.Text then data.Text.Visible = false end
        end
        return
    end

    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")


    for obj, data in pairs(_G.FruitESP) do
        if not obj or not obj.Parent or not data.Handle or not data.Handle.Parent then
            removeESP(obj)
            continue
        end


        local worldPos = data.Handle.Position + Vector3.new(0, 3.5, 0)


        local ok, r1, r2 = pcall(WorldToScreen, worldPos)


        if ok and r1 then
            local x, y, onScreen


            if type(r1) == "table" then
                x, y, onScreen = r1.X, r1.Y, r1.OnScreen
            else
                x, y = r1.X, r1.Y
                onScreen = r2
            end


            if onScreen == nil then onScreen = true end


            if onScreen and x and y then
                local distText = ""
                if root then
                    local dist = (root.Position - data.Handle.Position).Magnitude
                    local meters = math.floor(dist / 10)
                    distText = " (" .. meters .. "m)"
                end


                data.Text.Text = tostring(data.Name or "Fruit") .. distText
                data.Text.Position = Vector2.new(x, y)
                data.Text.Visible = true
            else
                data.Text.Visible = false
            end
        else
            data.Text.Visible = false
        end
    end
end


local fruitCache = {}


local function refreshFruits()
    local found = {}
    local current = {}


    for _, obj in ipairs(Workspace:GetChildren()) do
        if isFruit(obj) then
            local handle = obj:FindFirstChild("Handle")
            if handle then
                local name = getFruitName(obj)
                local island = getIslandName(handle.Position)


                found[#found + 1] = {
                    Object = obj,
                    Position = handle.Position,
                    Name = name,
                    Island = island
                }
                current[obj] = true


                if _G.FruitESP[obj] then
                    _G.FruitESP[obj].Name = name
                else
                    createESP(obj, name)
                end
            end
        end
    end


    for obj, _ in pairs(_G.FruitESP) do
        if not current[obj] then
            removeESP(obj)
        end
    end


    fruitCache = found
end


local dealerObject = nil


local function refreshDealer()
    if currentPlaceId == SEA3_ID then
        dealerObject = nil
        return
    end


    dealerObject = nil
    local npcFolder = Workspace:FindFirstChild("NPCs")
    if npcFolder then
        for _, obj in ipairs(npcFolder:GetChildren()) do
            if obj.Name == "Legendary Sword Dealer" then
                dealerObject = obj
                return
            end
        end
    end
end


local function getRoot()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end


refreshFruits()
refreshDealer()


task.spawn(function()
    while not _G.FE_Unloaded do
        refreshFruits()
        refreshDealer()
        task.wait(0.35)
    end
end)


local espConn = RunService.RenderStepped:Connect(updateESP)


task.spawn(function()
    while not _G.FE_Unloaded do
        local root = getRoot()


        if currentPlaceId == SEA2_ID then
            if dealerObject and dealerObject.Parent then
                dealer.Text = "Legendary Sword Dealer: SPAWNED"
                dealer.Color = Color3.fromRGB(80, 255, 100)
            else
                dealer.Text = "Legendary Sword Dealer: NOT SPAWNED"
                dealer.Color = Color3.fromRGB(255, 90, 90)
            end
            dealer.Visible = true
        else
            dealer.Visible = false
            dealer.Text = ""
        end


        count.Text = "Spawned Fruits: " .. #fruitCache


        if #fruitCache > 0 then
            local names = {}
            local nearest = nil
            local nearestDist = math.huge


            for _, item in ipairs(fruitCache) do
                local display = item.Name .. " (" .. item.Island .. ")"
                table.insert(names, display)


                if root and item.Object and item.Object.Parent then
                    local handle = item.Object:FindFirstChild("Handle")
                    if handle then
                        local d = (root.Position - handle.Position).Magnitude
                        if d < nearestDist then
                            nearestDist = d
                            nearest = item
                        end
                    end
                end
            end


            local maxLen = 42
            local lines = {"", "", ""}
            local lineIndex = 1
            local currentLine = "Fruits: "


            for i, name in ipairs(names) do
                local add = (currentLine == "Fruits: ") and name or (", " .. name)


                if #currentLine + #add <= maxLen then
                    currentLine = currentLine .. add
                else
                    lines[lineIndex] = currentLine
                    lineIndex = lineIndex + 1
                    if lineIndex > 3 then
                        lines[3] = lines[3] .. "..."
                        break
                    end
                    currentLine = name
                end
            end


            if lineIndex <= 3 then
                lines[lineIndex] = currentLine
            end


            fruitLine1.Text = lines[1]
            fruitLine2.Text = lines[2]
            fruitLine3.Text = lines[3]


            fruitLine1.Color = Color3.fromRGB(80, 255, 100)
            fruitLine2.Color = Color3.fromRGB(80, 255, 100)
            fruitLine3.Color = Color3.fromRGB(80, 255, 100)


            if nearest then
                local meters = math.floor(nearestDist / 10)
                distance.Text = "Nearest: " .. nearest.Name .. " (" .. nearest.Island .. ") [" .. meters .. "m]"
                distance.Color = Color3.fromRGB(255, 220, 80)
            else
                distance.Text = "Nearest: --"
            end
        else
            fruitLine1.Text = "Fruits: NONE"
            fruitLine2.Text = ""
            fruitLine3.Text = ""
            fruitLine1.Color = Color3.fromRGB(255, 90, 90)
            distance.Text = "Nearest: --"
            distance.Color = Color3.fromRGB(180, 180, 180)
        end


        if not feEnabled("fe_panel") then
            for _, d in pairs(_G.FruitStatusDrawings) do
                d.Visible = false
            end
        else
            for _, d in pairs(_G.FruitStatusDrawings) do
                if d ~= dealer then
                    d.Visible = true
                end
            end
        end


        task.wait(0.07)
    end
end)


task.spawn(function()
    while not _G.FE_Unloaded do
        local enemies = getEnemiesInRange()
        AuraTargetCount = #enemies
        if AuraTargetCount > 0 then
            table.sort(enemies, function(a, b) return a.dist < b.dist end)
            AuraFirstTargetName = enemies[1].enemy.Name or "Unknown"
        else
            AuraFirstTargetName = "None"
        end
        updateHUD()

        if AuraEnabled and AuraTargetCount > 0 then
            AttackMultiple(enemies)
        end

        task.wait(0.05)
    end
    pcall(function() hudText:Remove() end)
end)


task.spawn(function()
    local okLib = pcall(function()
        loadstring(game:HttpGet("https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua"))()
    end)

    if not okLib or type(WabiSabi) ~= "table" then
        warn("[Hub] Wabi Sabi UI lib not loaded — running without menu")
        return
    end

    Library = WabiSabi

    local Window = Library:CreateWindow({
        Title = "BF Hub",
        SubTitle = "blox fruits",
        Size = Vector2.new(560, 420),
        Resize = true,
    })

    local EspTab = Window:AddTab({ Title = "ESP", Icon = "eye" })
    local MainSec = EspTab:AddSection("Main")

    MainSec:AddToggle({
        Id = "fe_master",
        Title = "Enabled",
        Description = "Master switch (F1)",
        Default = true,
        Keybind = "F1",
    })

    MainSec:AddToggle({
        Id = "fe_esp",
        Title = "Fruit ESP",
        Description = "Labels above fruits",
        Default = true,
    })

    MainSec:AddToggle({
        Id = "fe_panel",
        Title = "Status Panel",
        Description = "Server status overlay",
        Default = true,
    })

    local PanelTab = Window:AddTab({ Title = "Panel", Icon = "map" })
    local PosSec = PanelTab:AddSection("Position")

    PosSec:AddSlider({
        Id = "fe_pos_x",
        Title = "Panel X",
        Min = 0,
        Max = 3000,
        Default = UI_X,
        Callback = function() applyPanelPos() end,
    })

    PosSec:AddSlider({
        Id = "fe_pos_y",
        Title = "Panel Y",
        Min = 0,
        Max = 1500,
        Default = UI_Y,
        Callback = function() applyPanelPos() end,
    })

    local StyleSec = PanelTab:AddSection("Style")

    StyleSec:AddSlider({
        Id = "fe_text_size",
        Title = "Text size",
        Min = 10,
        Max = 20,
        Default = 14,
        Callback = function() applyPanelSize() end,
    })

    local FishTab = Window:AddTab({ Title = "Fish", Icon = "fish" })
    local FishSec = FishTab:AddSection("Auto Fish")

    FishSec:AddToggle({
        Id = "mod_fish",
        Title = "Auto Fish",
        Description = "Full fishing cycle (F5)",
        Default = false,
        Keybind = "F5",
        Callback = function(value)
            if value then FishStart() else FishStop() end
        end,
    })

    local FishTuneSec = FishTab:AddSection("Tuning")

    FishTuneSec:AddSlider({
        Id = "fish_cast_target",
        Title = "Cast power",
        Min = 0.5,
        Max = 1,
        Default = FishConfig.CastTarget,
        Rounding = 2,
        Callback = function(v) FishConfig.CastTarget = v end,
    })

    FishTuneSec:AddSlider({
        Id = "fish_dead_zone",
        Title = "Reel dead zone",
        Min = 0,
        Max = 2,
        Default = FishConfig.DeadZone,
        Rounding = 2,
        Callback = function(v) FishConfig.DeadZone = v end,
    })

    FishTuneSec:AddSlider({
        Id = "fish_bite_timeout",
        Title = "Bite timeout (s)",
        Min = 5,
        Max = 60,
        Default = FishConfig.BiteTimeout,
        Callback = function(v) FishConfig.BiteTimeout = v end,
    })

    local BoatTab = Window:AddTab({ Title = "Boat", Icon = "anchor" })
    local BoatSec = BoatTab:AddSection("Auto Repair")

    BoatSec:AddToggle({
        Id = "mod_repair",
        Title = "Auto Repair",
        Description = "Repair minigame (G)",
        Default = false,
        Keybind = "G",
        Callback = function(value)
            if value then RepStart() else RepStop() end
        end,
    })

    local CombatTab = Window:AddTab({ Title = "Combat", Icon = "swords" })
    local CombatSec = CombatTab:AddSection("M1 NPC Aura")

    CombatSec:AddToggle({
        Id = "mod_aura",
        Title = "M1 Aura",
        Description = "Multi-target M1 via remotes (F6)",
        Default = false,
        Keybind = "F6",
        Callback = function(value)
            AuraEnabled = value
            updateHUD()
        end,
    })

    CombatSec:AddSlider({
        Id = "aura_distance",
        Title = "Range",
        Min = 10,
        Max = 500,
        Default = AuraConfig.MAX_DISTANCE,
        Callback = function(v) AuraConfig.MAX_DISTANCE = v end,
    })

    local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

    Window:BuildInterfaceSection(SettingsTab)
    Window:BuildConfigSection(SettingsTab)

    local UnloadSec = SettingsTab:AddSection("Unload")

    UnloadSec:AddButton({
        Title = "Unload",
        Description = "Stops all modules, removes overlays and menu",
        Callback = function()
            Window:Dialog({
                Title = "Unload?",
                Content = "This stops all modules, removes overlays and closes the menu.",
                Buttons = {
                    {
                        Title = "Unload",
                        Callback = function()
                            _G.FE_Unloaded = true

                            FishStop()
                            RepStop()
                            AuraEnabled = false

                            if espConn then
                                pcall(function() espConn:Disconnect() end)
                            end
                            for _, d in pairs(_G.FruitStatusDrawings) do
                                pcall(function() d:Remove() end)
                            end
                            _G.FruitStatusDrawings = {}
                            for obj, data in pairs(_G.FruitESP) do
                                pcall(function() data.Text:Remove() end)
                                _G.FruitESP[obj] = nil
                            end

                            pcall(function() mouse1release() end)

                            pcall(function() Library:Destroy() end)
                        end,
                    },
                    { Title = "Cancel" },
                },
            })
        end,
    })

    pcall(function() Library:LoadAutoloadConfig() end)

    Library:Notify({
        Title = "BF Hub",
        Content = "Loaded.",
        SubContent = "press End to minimize menu",
        Duration = 4,
    })
end)


print("[BF Hub] Loaded: Fruit ESP + AutoFish + AutoRepair + M1 Aura")