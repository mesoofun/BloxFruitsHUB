local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then
    repeat task.wait(0.1); player = Players.LocalPlayer until player
end
local LocalPlayer = player
local SEA1_ID   = 2753915549
local SEA1_ID_B = 85211729168715
local SEA2_ID   = 4442272183
local SEA2_ID_B = 79091703265657
local SEA3_ID_A = 7449423635
local SEA3_ID_B = 100117331123089
local currentPlaceId = game.PlaceId


local function isSea1() return currentPlaceId == SEA1_ID or currentPlaceId == SEA1_ID_B end
local function isSea2() return currentPlaceId == SEA2_ID or currentPlaceId == SEA2_ID_B end
local function isSea3() return currentPlaceId == SEA3_ID_A or currentPlaceId == SEA3_ID_B end
local SEA_NAMES = {
    [SEA1_ID] = "First Sea", [SEA1_ID_B] = "First Sea",
    [SEA2_ID] = "Second Sea", [SEA2_ID_B] = "Second Sea",
    [SEA3_ID_A] = "Third Sea", [SEA3_ID_B] = "Third Sea",
}
pcall(function() setrobloxinput(true) end)

-- Matcha may provide WorldToScreen; fallback for ESP (same contract as haunted)
if type(WorldToScreen) ~= "function" then
    function WorldToScreen(worldPos)
        local cam = Workspace.CurrentCamera
        if not cam or not worldPos then return Vector2.new(0, 0), false end
        local ok, v, on = pcall(function()
            local vv, oo = cam:WorldToViewportPoint(worldPos)
            return vv, oo
        end)
        if not ok or not v then return Vector2.new(0, 0), false end
        return Vector2.new(v.X, v.Y), (on == true) and v.Z > 0
    end
end

_G.FE_Unloaded = false
_G.FruitESP = _G.FruitESP or {}
_G.BerryESP = _G.BerryESP or {}
local Features = { master=true, esp=true, berryEsp=false, panel=true, fish=false, repair=false, aura=false }
local function feEnabled(id)
    if not Features.master then return false end
    return Features[id] ~= false
end
local VK = {}
for i=1,12 do VK["f"..i] = 0x6F+i end
for i=0,25 do VK[string.char(97+i)] = 0x41+i end
for i=0,9 do VK[tostring(i)] = 0x30+i end
VK.space=0x20; VK.tab=0x09; VK.lshift=0xA0; VK.rshift=0xA1; VK.shift=0x10
VK.lctrl=0xA2; VK.rctrl=0xA3; VK.ctrl=0x11; VK.alt=0x12
VK.left=0x25; VK.up=0x26; VK.right=0x27; VK.down=0x28
VK.home=0x24; VK["end"]=0x23; VK.insert=0x2D; VK.delete=0x2E
local ENUM_KEY = {}
for i=1,12 do ENUM_KEY["f"..i] = Enum.KeyCode["F"..i] end
for i=0,25 do
    local c = string.char(97+i)
    ENUM_KEY[c] = Enum.KeyCode[string.upper(c)]
end
ENUM_KEY.space=Enum.KeyCode.Space; ENUM_KEY.tab=Enum.KeyCode.Tab
ENUM_KEY.left=Enum.KeyCode.Left; ENUM_KEY.right=Enum.KeyCode.Right
ENUM_KEY.up=Enum.KeyCode.Up; ENUM_KEY.down=Enum.KeyCode.Down
ENUM_KEY.insert=Enum.KeyCode.Insert; ENUM_KEY.delete=Enum.KeyCode.Delete
ENUM_KEY.home=Enum.KeyCode.Home; ENUM_KEY["end"]=Enum.KeyCode.End
local function normKey(k)
    if k==nil then return nil end
    k = string.lower(tostring(k)):gsub("%s+","")
    if k=="" or k=="none" or k=="nil" then return nil end
    -- LMB / MB1 cannot be a feature bind — treat as unbound (NONE)
    if k=="mb1" or k=="mb" or k=="mouse1" or k=="mousebutton1" or k=="button1"
        or k=="leftclick" or k=="left" or k=="lmb"
        or k:find("mousebutton1", 1, true) or k:find("userinputtype.mousebutton1", 1, true) then
        return nil
    end
    return k
end
local function isDown(key)
    key = normKey(key)
    if not key then return false end
    local code = VK[key]
    if code then
        local d=false
        pcall(function() d=iskeypressed(code) end)
        if d then return true end
    end
    local ek = ENUM_KEY[key]
    if ek then
        local ok,d = pcall(function() return UIS:IsKeyDown(ek) end)
        if ok and d then return true end
    end
    return false
end
local function isMouseBind(raw)
    if raw == nil then return false end
    local s = string.lower(tostring(raw)):gsub("%s+", "")
    if s == "" or s == "nil" or s == "none" then return false end
    if s == "mb1" or s == "mb" or s == "mouse1" or s == "mousebutton1" or s == "button1"
        or s == "leftclick" or s == "lmb" or s == "left" then
        return true
    end
    if s:find("mousebutton1", 1, true) or s:find("userinputtype.mousebutton1", 1, true) then
        return true
    end
    if s:find("mouse", 1, true) and (s:find("button", 1, true) or s:find("1", 1, true) or s:find("left", 1, true)) then
        return true
    end
    return false
end
local function forceBindNone(handle)
    if not handle then return end
    pcall(function()
        if handle.Set then
            -- try common empty values so UI shows NONE instead of MB1
            handle:Set(nil)
            handle:Set("NONE")
            handle:Set("None")
            handle:Set("none")
            handle:Set("")
        end
    end)
end
local function getBindKey(handle)
    if not handle then return nil end
    local ok,v = pcall(function() return handle:Get() end)
    if not ok or v==nil or v==false then return nil end
    if type(v)=="number" and v==0 then return nil end
    local raw = v
    if type(v)=="table" then
        raw = v.Key or v.key or v[1] or v.Value or v.value or v.Name or v.Enum or v.UserInputType
    end
    if isMouseBind(raw) then
        forceBindNone(handle)
        return nil
    end
    local k = normKey(raw)
    if k == nil and raw ~= nil and isMouseBind(raw) then
        forceBindNone(handle)
    end
    return k
end
local function sanitizeKeybindCallback(cb)
    return function(v)
        if isMouseBind(v) then
            return
        end
        if type(v) == "table" then
            local raw = v.Key or v.key or v[1] or v.Value or v.value or v.Name
            if isMouseBind(raw) then return end
        end
        if cb then pcall(cb, v) end
    end
end
local K, H = {}, {}
-- Periodically clear MB1 from keybind UI so display stays NONE
task.spawn(function()
    while not _G.FE_Unloaded do
        for _, handle in pairs(K) do
            if handle then
                local ok, v = pcall(function() return handle:Get() end)
                if ok and isMouseBind(v) then
                    forceBindNone(handle)
                end
            end
        end
        task.wait(0.25)
    end
end)

local lastDown = {}
local menuOpen = true
local WinRef, LibRef = nil, nil
local function setToggle(id, value)
    Features[id] = value
    if H[id] then pcall(function() H[id]:Set(value) end) end
end
local function toggleFeature(id, apply)
    local new = not Features[id]
    setToggle(id, new)
    if apply then apply(new) end
end
local function setMyth(flag, value)
    if type(S)=="table" then S[flag]=value end
end
local FishConfig = { CastTarget=0.96, DeadZone=0.35, BiteTimeout=20, ResetDelay=2 }
local FishState = {
    Running=false, IsHolding=false, CastComplete=false, FishDetected=false,
    ReelingStarted=false, FishCaught=0, LastCastTime=0, BiteClickTime=0,
}
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local function SafeClick() pcall(mouse1click) end
local function FishHold()
    if not FishState.IsHolding then FishState.IsHolding=true; pcall(mouse1press) end
end
local function FishRelease()
    if FishState.IsHolding then FishState.IsHolding=false; pcall(mouse1release) end
end
local function FishFullReset(reason)
    FishRelease()
    FishState.CastComplete=false; FishState.FishDetected=false; FishState.ReelingStarted=false
    FishState.LastCastTime=0; FishState.BiteClickTime=0
    task.wait(FishConfig.ResetDelay)
end
local function HasCastMeter()
    local c=LocalPlayer.Character
    return c and c:FindFirstChild("Fishing_Cast Meter")~=nil
end
local function GetCastFill()
    local c=LocalPlayer.Character; if not c then return 0 end
    local part=c:FindFirstChild("Fishing_Cast Meter"); if not part then return 0 end
    local meter=part:FindFirstChild("CastMeter"); if not meter then return 0 end
    local bar=meter:FindFirstChild("Bar"); if not bar then return 0 end
    local frame=bar:FindFirstChild("Frame"); if not frame then return 0 end
    local ok1,size=pcall(function() return frame.AbsoluteSize.Y end)
    local ok2,max=pcall(function() return frame.Parent.AbsoluteSize.Y end)
    if ok1 and ok2 and max and max>0 then return size/max end
    return 0
end
local function IsFishBiting()
    local c=LocalPlayer.Character; if not c then return false end
    if c:FindFirstChild("FishOnLine", true) then return true end
    for _,o in ipairs(c:GetDescendants()) do
        local n=o.Name:lower()
        if n:find("fishonline") or n:find("fish on line") then return true end
    end
    return false
end
local function GetReelUI()
    local ui=PlayerGui:FindFirstChild("Fishing_Reeling"); if not ui then return nil end
    local mini=ui:FindFirstChild("Minigame") or ui:FindFirstChild("MiniGame"); if not mini then return nil end
    local container=mini:FindFirstChild("Container"); if not container then return nil end
    local treasure=container:FindFirstChild("Treasure")
    local treasureIcon=nil
    if treasure then
        local u=treasure:FindFirstChild("UnopenedIcon")
        local o=treasure:FindFirstChild("OpenedIcon")
        if u and u.Visible and u.AbsoluteSize.X>10 then treasureIcon=u
        elseif o and o.Visible and o.AbsoluteSize.X>10 then treasureIcon=o end
    end
    return {
        Fish=container:FindFirstChild("Fish"),
        Treasure=treasureIcon,
        Zone=container:FindFirstChild("ReelZone") or container:FindFirstChild("Zone"),
    }
end
local function IsReelOpen() return PlayerGui:FindFirstChild("Fishing_Reeling")~=nil end
local function GetCenter(obj)
    if not obj then return 0 end
    local ok1,x=pcall(function() return obj.AbsolutePosition.X end)
    local ok2,w=pcall(function() return obj.AbsoluteSize.X end)
    if ok1 and ok2 then return x+w/2 end
    return 0
end
local function ShouldHold(ui)
    if not ui or not ui.Zone then return false end
    local target=ui.Treasure or ui.Fish; if not target then return false end
    local tc,zc=GetCenter(target),GetCenter(ui.Zone)
    if tc==0 or zc==0 then return false end
    return zc < tc - FishConfig.DeadZone
end
local function FishMainLoop()
    local wasOpen=false
    while FishState.Running do
        task.wait(0.04)
        if not FishState.CastComplete then
            if HasCastMeter() then
                local fill=GetCastFill(); FishHold()
                if fill>=FishConfig.CastTarget then
                    FishRelease(); task.wait(0.2)
                    FishState.CastComplete=true; FishState.FishDetected=false
                    FishState.ReelingStarted=false; FishState.LastCastTime=os.clock()
                    wasOpen=false
                end
            else
                FishRelease(); task.wait(0.2); SafeClick(); task.wait(0.3)
            end
            continue
        end
        if FishState.CastComplete and not FishState.FishDetected then
            if os.clock()-FishState.LastCastTime > FishConfig.BiteTimeout then
                FishFullReset("Too long without bite"); continue
            end
            if IsFishBiting() then
                FishState.FishDetected=true; FishState.BiteClickTime=os.clock()
                SafeClick(); task.wait(0.14); SafeClick(); task.wait(0.14); SafeClick()
            end
            continue
        end
        if FishState.FishDetected then
            if IsReelOpen() then
                wasOpen=true
                local ui=GetReelUI()
                if ui then
                    if not FishState.ReelingStarted then
                        FishState.ReelingStarted=true
                    end
                    if ShouldHold(ui) then FishHold() else FishRelease() end
                end
            else
                if wasOpen then
                    FishState.FishCaught+=1; FishRelease()
                    print("[AutoFish] Caught! Total:", FishState.FishCaught)
                    FishState.CastComplete=false; FishState.FishDetected=false
                    FishState.ReelingStarted=false; wasOpen=false; task.wait(0.5)
                elseif os.clock()-FishState.BiteClickTime > 3 then
                    FishFullReset("Reeling UI did not open")
                end
            end
        end
    end
end
local function FishStart()
    if FishState.Running then return end
    FishState.Running=true; FishState.CastComplete=false; FishState.FishDetected=false
    FishState.ReelingStarted=false; FishState.LastCastTime=0; FishState.BiteClickTime=0
    task.spawn(FishMainLoop)
end
local function FishStop()
    FishState.Running=false; FishRelease()
    print("[AutoFish] Stopped. Total:", FishState.FishCaught)
end
local RepState={Running=false, IsHolding=false}
local function getBarInfo()
    local pg=LocalPlayer:FindFirstChild("PlayerGui"); if not pg then return nil end
    local mini=pg:FindFirstChild("Main") and pg.Main:FindFirstChild("BottomHUDList")
        and pg.Main.BottomHUDList:FindFirstChild("RepairMiniGame")
    if not mini then return nil end
    local progress=mini:FindFirstChild("ProgressBar"); if not progress then return nil end
    local fill,goal=progress:FindFirstChild("Fill"),progress:FindFirstChild("Goal")
    if not fill or not goal then return nil end
    return {Fill=fill, Goal=goal}
end
local function isInGreenZone(info)
    if not info then return false end
    local fillRight=info.Fill.AbsolutePosition.X+info.Fill.AbsoluteSize.X
    local goalLeft=info.Goal.AbsolutePosition.X
    local goalRight=info.Goal.AbsolutePosition.X+info.Goal.AbsoluteSize.X
    return fillRight>=(goalLeft-8) and fillRight<=(goalRight+14)
end
local function RepHold()
    if not RepState.IsHolding then RepState.IsHolding=true; pcall(mouse1press) end
end
local function RepRelease()
    if RepState.IsHolding then RepState.IsHolding=false; pcall(mouse1release) end
end
local function RepMainLoop()
        while RepState.Running do
        local info=getBarInfo()
        if info then
            RepHold()
            if isInGreenZone(info) then
                RepRelease(); task.wait(0.35)
            end
        else RepRelease() end
        task.wait(0.02)
    end
    RepRelease()
end
local function RepStart()
    if RepState.Running then return end
    RepState.Running=true; task.spawn(RepMainLoop)
end
local function RepStop()
    RepState.Running=false; RepRelease()
end
local AuraConfig = {
    MAX_DISTANCE = 100,
    MIN_DISTANCE = 1,
    SESSION_ID = "32501259",
}
AuraEnabled = false
aura = {
    enabled = false,
    maxDist = 100,
    minDist = 1,
    sessionId = "32501259",
    targetCount = 0,
    firstName = "None",
    regAtk = nil,
    regHit = nil,
}

local AuraTargetCount = 0
local AuraFirstTargetName = "None"

local hudText = Drawing.new("Text")
hudText.Size = 18
pcall(function() hudText.Font = Drawing.Fonts.SystemBold end)
hudText.Color = Color3.fromRGB(255, 255, 255)
hudText.Outline = true
hudText.Center = false
hudText.Position = Vector2.new(10, 50)
hudText.Visible = false
hudText.Text = "Targets: 0 | OFF"

local function updateHUD()
    local on = aura.enabled == true
    local ok = pcall(function()
        hudText.Text = string.format("Targets: %d (%s) | %s", aura.targetCount or 0, tostring(aura.firstName or "None"), on and "ON" or "OFF")
        hudText.Visible = on
    end)
end

local _auraScanPrinted = false
local _auraRemoteWarned = false

local function aura_findRemote(patterns)
    local rs = game:GetService("ReplicatedStorage")
    local function matchName(n)
        if not n or n == "" then return false end
        local low = string.lower(n)
        for _, p in ipairs(patterns) do
            local pl = string.lower(p)
            if n == p or low == pl or low:find(pl, 1, true) then
                return true
            end
        end
        return false
    end

    local modules = rs:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Net")
    if net then
        for _, c in ipairs(net:GetChildren()) do
            if (c:IsA("RemoteEvent") or c:IsA("UnreliableRemoteEvent")) and matchName(c.Name) then
                return c
            end
        end
        for _, p in ipairs(patterns) do
            local r = net:FindFirstChild(p)
            if r and (r:IsA("RemoteEvent") or r:IsA("UnreliableRemoteEvent")) then
                return r
            end
        end
    end

    for _, obj in ipairs(rs:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent")) and matchName(obj.Name) then
            return obj
        end
    end
    return nil
end

local function aura_dumpNetOnce()
    if _auraScanPrinted then return end
    _auraScanPrinted = true
    local rs = game:GetService("ReplicatedStorage")
    local modules = rs:FindFirstChild("Modules")
    if not modules then return end
    local net = modules:FindFirstChild("Net")
    if not net then
        for _, c in ipairs(modules:GetChildren()) do
        end
        return
    end
    for _, c in ipairs(net:GetChildren()) do
    end
end

local function aura_ensureRemotes()
    if aura.regAtk and aura.regHit and aura.regAtk.Parent and aura.regHit.Parent then
        return true
    end
    local atk = aura_findRemote({
        "RE/RegisterAttack",
        "RegisterAttack",
        "RE_RegisterAttack",
    })
    local hit = aura_findRemote({
        "RE/RegisterHit",
        "RegisterHit",
        "RE_RegisterHit",
    })
    if atk and hit then
        aura.regAtk = atk
        aura.regHit = hit
        return true
    end
    aura_dumpNetOnce()
    return false
end

local function aura_getTargetPart(enemy)
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

local function aura_getEnemies()
    local character = LocalPlayer.Character
    if not character then return {} end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    local myPos = hrp.Position
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return {} end
    local results = {}
    local enemyList = enemiesFolder:GetChildren()
    local maxD = tonumber(aura.maxDist) or 100
    local minD = tonumber(aura.minDist) or 1
    for _, enemy in ipairs(enemyList) do
        if enemy and enemy.Parent then
            local humanoid = enemy:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health and humanoid.Health > 0 then
                local part = aura_getTargetPart(enemy)
                if part and part.Parent then
                    local ok, pos = pcall(function() return part.Position end)
                    if ok and pos then
                        local dist = (pos - myPos).Magnitude
                        if dist <= maxD and dist >= minD then
                            table.insert(results, { enemy = enemy, part = part, dist = dist })
                        end
                    end
                end
            end
        end
    end
    return results
end

local function aura_attack(enemyList)
    if not aura.enabled or not enemyList or #enemyList == 0 then return end
    if not aura_ensureRemotes() then return end
    local hitTable = {}
    local primaryPart = nil
    for _, entry in ipairs(enemyList) do
        if entry.enemy and entry.enemy.Parent and entry.part and entry.part.Parent then
            table.insert(hitTable, { entry.enemy, entry.part })
            if not primaryPart then primaryPart = entry.part end
        end
    end
    if #hitTable == 0 or not primaryPart then return end
    pcall(function() aura.regAtk:FireServer(0.5) end)
    task.wait()
    pcall(function() aura.regHit:FireServer(primaryPart, hitTable, nil, aura.sessionId) end)
end

task.spawn(function()
    task.wait(2)
    if aura_ensureRemotes() then return end
    task.wait(3)
    aura_ensureRemotes()
end)

task.spawn(function()
    while not _G.FE_Unloaded do
        local okLoop, err = pcall(function()
            if aura.enabled then
                local enemies = aura_getEnemies()
                aura.targetCount = #enemies
                AuraTargetCount = #enemies
                if #enemies > 0 then
                    table.sort(enemies, function(a, b) return a.dist < b.dist end)
                    aura.firstName = (enemies[1].enemy and enemies[1].enemy.Name) or "Unknown"
                else
                    aura.firstName = "None"
                end
                AuraFirstTargetName = aura.firstName
                if #enemies > 0 then
                    aura_attack(enemies)
                end
                updateHUD()
                task.wait(0.2)
            else
                updateHUD()
                task.wait(0.25)
            end
        end)
        if not okLoop then
            warn("[M1 Aura] loop error:", err)
            task.wait(0.5)
        end
    end
    pcall(function() hudText:Remove() end)
end)

local FirstSeaIslands={
    {Name="Starter Island",Position=Vector3.new(1014.48,15.83,1462.93)},
    {Name="Jungle",Position=Vector3.new(-1419.21,-3.78,-76.86)},
    {Name="Pirate Village",Position=Vector3.new(-1133.21,-3.78,4176.14)},
    {Name="Desert",Position=Vector3.new(1193.79,-13.78,4430.14)},
    {Name="Frozen Village",Position=Vector3.new(1276.79,-13.78,-1472.86)},
    {Name="Marine Fortress",Position=Vector3.new(-4935.21,-13.78,4318.14)},
    {Name="Starter Marine",Position=Vector3.new(-2964.51,41.08,2122.72)},
    {Name="Sky",Position=Vector3.new(-5024.21,794.4,-2618.69)},
    {Name="Upper Sky",Position=Vector3.new(-8013.88,5814.06,-1980.80)},
    {Name="Middle Town",Position=Vector3.new(-709.62,10.08,1568.71)},
    {Name="Prison",Position=Vector3.new(5277.79,-13.78,743.14)},
    {Name="Colosseum",Position=Vector3.new(-1685.21,-13.78,-3200.86)},
    {Name="Magma Village",Position=Vector3.new(-5528.21,-13.78,8691.14)},
    {Name="Underwater City",Position=Vector3.new(61379.79,-13.78,1473.14)},
    {Name="Fountain City",Position=Vector3.new(5717.79,-13.78,4356.14)},
}
local SecondSeaIslands={
    {Name="Kingdom of Rose",Position=Vector3.new(-195.1,155.3,279.9)},
    {Name="Cafe",Position=Vector3.new(-388.57,73.08,310.95)},
    {Name="Mansion",Position=Vector3.new(-504.26,331.92,610.43)},
    {Name="Docks 2",Position=Vector3.new(-9.32,39.34,2712.37)},
    {Name="Docks 3",Position=Vector3.new(-2340.8,155.3,-3396.3)},
    {Name="Docks 4",Position=Vector3.new(-5772.25,6.65,-5012.76)},
    {Name="Colosseum",Position=Vector3.new(-1838.59,44.35,1614.46)},
    {Name="Graveyard",Position=Vector3.new(-5929.64,87.55,-1188.64)},
    {Name="Snow Mountain",Position=Vector3.new(856.2,50.3,-5278.3)},
    {Name="Hot and Cold",Position=Vector3.new(-5296.24,214.96,-5518.59)},
    {Name="Haunted Ship",Position=Vector3.new(900.94,143.97,33072.64)},
    {Name="Winter Castle",Position=Vector3.new(6062.26,155.3,-6880.86)},
    {Name="Skull",Position=Vector3.new(-3194.24,155.3,-10795.26)},
    {Name="Remote",Position=Vector3.new(4762.69,8.38,2853.69)},
    {Name="Dark Arena",Position=Vector3.new(3807.1,11.8,-3452.2)},
}
local ThirdSeaIslands={
    {Name="Castle on the Sea",Position=Vector3.new(-5436.61,815.64,-2701.66)},
    {Name="Turtle Mansion",Position=Vector3.new(-12547.71,290.14,-7487.07)},
    {Name="Turtle Entrance",Position=Vector3.new(-10159.20,331.83,-8338.58)},
    {Name="Turtle Mountain",Position=Vector3.new(-12851.91,844.43,-10732.79)},
    {Name="Turtle Center",Position=Vector3.new(-12003.31,331.79,-9196.02)},
    {Name="Port Town",Position=Vector3.new(-610.37,57.83,6436.34)},
    {Name="Hydra Town",Position=Vector3.new(5275.71,1005.42,404.14)},
    {Name="Hydra Arena",Position=Vector3.new(6473.16,52.34,-1231.78)},
    {Name="Great Tree",Position=Vector3.new(3036.29,815.64,-7149.86)},
    {Name="Floating Turtle",Position=Vector3.new(-12164.61,-548.86,-8454.87)},
    {Name="Haunted Castle",Position=Vector3.new(-9530.61,-132.86,5763.14)},
    {Name="Tiki Outpost",Position=Vector3.new(-16641.51,213.31,435.38)},
    {Name="Ice Cream Land",Position=Vector3.new(-819.38,62.26,-10967.28)},
    {Name="Peanut Land",Position=Vector3.new(-2105.53,34.49,-10195.51)},
    {Name="Chocolate Land",Position=Vector3.new(297.76,28.37,-12724.31)},
    {Name="Cake Land",Position=Vector3.new(-2022.3,34.17,-12030.98)},
}
local IslandsBySea={[SEA1_ID]=FirstSeaIslands,[SEA1_ID_B]=FirstSeaIslands,[SEA2_ID]=SecondSeaIslands,[SEA2_ID_B]=SecondSeaIslands,[SEA3_ID_A]=ThirdSeaIslands,[SEA3_ID_B]=ThirdSeaIslands}
local Islands=IslandsBySea[currentPlaceId]
if not Islands then
    if isSea3() then Islands=ThirdSeaIslands
    elseif isSea2() then Islands=SecondSeaIslands
    elseif isSea1() then Islands=FirstSeaIslands
    else
        Islands={}
        for _,list in pairs(IslandsBySea) do for _,isl in ipairs(list) do table.insert(Islands,isl) end end
    end
end
local function getIslandName(pos)
    if not pos or not Islands or #Islands==0 then return "Unknown" end
    local closest,minDist="Unknown",math.huge
    local p=Vector3.new(pos.X,0,pos.Z)
    for _,island in ipairs(Islands) do
        local ip=Vector3.new(island.Position.X,0,island.Position.Z)
        local d=(p-ip).Magnitude
        if d<minDist then minDist=d; closest=island.Name end
    end
    if minDist>25000 then return "Sea" end
    return closest
end
_G.FruitStatusDrawings=_G.FruitStatusDrawings or {}
for _,d in pairs(_G.FruitStatusDrawings) do pcall(function() d:Remove() end) end
_G.FruitStatusDrawings={}
_G.FruitESP=_G.FruitESP or {}
for _,d in pairs(_G.FruitESP) do pcall(function() d.Text:Remove() end) end
_G.FruitESP={}
local function createText(text,size,color,center)
    local t=Drawing.new("Text")
    t.Text=text or ""; t.Size=size or 15
    t.Color=color or Color3.fromRGB(255,255,255)
    t.Center=center or false; t.Outline=true; t.Visible=true
    table.insert(_G.FruitStatusDrawings,t); return t
end
local panelPosX,panelPosY=50,400
local panelTextSize=13
local FRUIT_LINES,BERRY_LINES,LIST_START_Y,LINE_STEP=10,8,48,18
local panelShown=0
local layoutPanel
local seaLabel=SEA_NAMES[currentPlaceId]
local title=createText("SERVER STATUS"..(seaLabel and (" ["..seaLabel.."]") or " [sea?]"),16)
local dealer=createText("",13)
local fruitLines={}
for i=1,FRUIT_LINES do fruitLines[i]=createText("",13,Color3.fromRGB(80,255,100)) end
local berryLines={}
for i=1,BERRY_LINES do berryLines[i]=createText("",13,Color3.fromRGB(255,90,90)) end
local distance=createText("",13,Color3.fromRGB(255,220,80))
local count=createText("",13,Color3.fromRGB(180,200,255))
if isSea3() then dealer.Visible=false end
local function applyPanelSize()
    title.Size=panelTextSize+3; dealer.Size=panelTextSize
    for i=1,FRUIT_LINES do fruitLines[i].Size=panelTextSize end
    for i=1,BERRY_LINES do berryLines[i].Size=panelTextSize end
    distance.Size=panelTextSize; count.Size=panelTextSize
end
layoutPanel = function(shown, berryShown)
    local x = tonumber(panelPosX) or 50
    local y = tonumber(panelPosY) or 400
    shown = tonumber(shown) or 0
    berryShown = tonumber(berryShown) or 0
    pcall(function()
        if title then title.Position = Vector2.new(x, y) end
        if dealer then dealer.Position = Vector2.new(x, y + 24) end
        for i = 1, FRUIT_LINES do
            local fl = fruitLines and fruitLines[i]
            if fl then fl.Position = Vector2.new(x, y + LIST_START_Y + (i - 1) * LINE_STEP) end
        end
        local berryStart = LIST_START_Y + shown * LINE_STEP + ((shown > 0) and 4 or 0)
        for i = 1, BERRY_LINES do
            local bl = berryLines and berryLines[i]
            if bl then bl.Position = Vector2.new(x, y + berryStart + (i - 1) * LINE_STEP) end
        end
        local gap = 6
        local distY = berryStart + berryShown * LINE_STEP + gap
        if distance then distance.Position = Vector2.new(x, y + distY) end
        if count then count.Position = Vector2.new(x, y + distY + 20) end
    end)
end
applyPanelSize(); layoutPanel(0, 0)
local function isFruit(obj)
    if not obj:IsA("Tool") then return false end
    local h=obj:FindFirstChild("Handle")
    return h and h:IsA("BasePart")
end
local function getFruitName(obj)
    if not obj then return "Fruit" end
    local n=obj.Name
    if n and n~="" and n~="Fruit" and n~="Handle" then return n end
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
    _G.FruitESP[obj] = { Text = text, Handle = handle, Name = name }
end

local function removeESP(obj)
    local data = _G.FruitESP[obj]
    if data and data.Text then
        pcall(function() data.Text:Remove() end)
    end
    _G.FruitESP[obj] = nil
end

local function updateESP()
    if not feEnabled("esp") then
        for _, data in pairs(_G.FruitESP) do
            if data.Text then data.Text.Visible = false end
        end
        return
    end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for obj, data in pairs(_G.BerryESP or {}) do pcall(function() if data.Text then data.Text:Remove() end end) _G.BerryESP[obj]=nil end
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
                    distText = " (" .. math.floor((root.Position - data.Handle.Position).Magnitude / 10) .. "m)"
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

local fruitCache={}
local function refreshFruits()
    local found, current = {}, {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if isFruit(obj) then
            local handle = obj:FindFirstChild("Handle")
            if handle then
                local name = getFruitName(obj)
                local island = getIslandName(handle.Position)
                found[#found + 1] = { Object = obj, Position = handle.Position, Name = name, Island = island }
                current[obj] = true
                if _G.FruitESP[obj] then
                    _G.FruitESP[obj].Name = name
                    _G.FruitESP[obj].Handle = handle
                else
                    createESP(obj, name)
                end
            end
        end
    end
    for obj in pairs(_G.FruitESP) do
        if not current[obj] then removeESP(obj) end
    end
    fruitCache = found
end

local BERRIES = {
    { name = "Green Toad Berry",   sphere = "Sphere.011" },
    { name = "Yellow Star Berry",  sphere = "Sphere.022" },
    { name = "Orange Berry",       sphere = "Sphere.007" },
    { name = "Red Cherry Berry",   sphere = "Sphere.005" },
    { name = "Purple Jelly Berry", sphere = "Sphere.004" },
    { name = "Pink Pig Berry",     sphere = "Sphere.008" },
    { name = "Blue Icicle Berry",  sphere = "Sphere.018" },
    { name = "White Cloud Berry",  sphere = "Sphere.035" },
}
local sphereToBerry = {}
for _, b in ipairs(BERRIES) do sphereToBerry[b.sphere] = b.name end

local BERRY_FULLSCAN_SEC = 12
local BERRY_ESP_MAX = 50
local _berryLastFullScan = 0
local _berryEspTick = 0
local _berryHooks = {}
local berryCache = {}

local function berryGetPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        for _, c in ipairs(obj:GetChildren()) do
            if c:IsA("BasePart") then return c.Position end
        end
    end
    local p = obj.Parent
    if p and p:IsA("BasePart") then return p.Position end
    return nil
end

local function createBerryESP(obj, name)
    if _G.BerryESP[obj] then
        _G.BerryESP[obj].Name = name
        return
    end
    if not feEnabled("berryEsp") then return end
    local n = 0
    for _ in pairs(_G.BerryESP) do n = n + 1 end
    if n >= BERRY_ESP_MAX then return end
    local text = Drawing.new("Text")
    text.Text = name
    text.Size = 14
    text.Color = Color3.fromRGB(255, 70, 70)
    text.Center = true
    text.Outline = true
    text.Visible = false
    _G.BerryESP[obj] = { Text = text, Name = name, Obj = obj }
end

local function removeBerryESP(obj)
    local data = _G.BerryESP[obj]
    if data and data.Text then pcall(function() data.Text:Remove() end) end
    _G.BerryESP[obj] = nil
end

local function rebuildBerryCache()
    local found = {}
    for obj, data in pairs(_G.BerryESP) do
        if obj and obj.Parent then
            local pos = berryGetPos(obj)
            if pos then
                found[#found + 1] = {
                    Object = obj,
                    Position = pos,
                    Name = data.Name or sphereToBerry[obj.Name] or "Berry",
                    Island = getIslandName(pos),
                }
            end
        else
            removeBerryESP(obj)
        end
    end
    berryCache = found
end

local function clearAllBerryESP()
    for obj in pairs(_G.BerryESP) do removeBerryESP(obj) end
    berryCache = {}
end

local function tryRegisterBerry(obj)
    if not obj then return end
    local bname = sphereToBerry[obj.Name]
    if not bname then return end
    if not (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Part") or obj:IsA("UnionOperation")) then
        -- still allow if named sphere under bush
        if not obj:IsA("Model") and not obj:IsA("Folder") then
            if typeof(obj) ~= "Instance" then return end
        end
    end
    createBerryESP(obj, bname)
end

local function berryFullScan()
    _berryLastFullScan = os.clock()
    local current = {}
    local ok, descendants = pcall(function()
        return Workspace:GetDescendants()
    end)
    if not ok or type(descendants) ~= "table" then
        return
    end
    local step = 0
    for _, obj in ipairs(descendants) do
        local bname = sphereToBerry[obj.Name]
        if bname then
            current[obj] = true
            createBerryESP(obj, bname)
        end
        step = step + 1
        if step % 1500 == 0 then
            task.wait()
        end
    end
    for obj in pairs(_G.BerryESP) do
        if not current[obj] then removeBerryESP(obj) end
    end
    rebuildBerryCache()
end

local function berryUnhook()
    for _, c in ipairs(_berryHooks) do
        pcall(function()
            if c and c.Disconnect then c:Disconnect() end
        end)
    end
    _berryHooks = {}
end

local function berryHook()
    -- Matcha: DescendantAdded/Removing often nil — do not Connect
    berryUnhook()
end

local function refreshBerries(force)
    if not feEnabled("berryEsp") then
        if next(_G.BerryESP) then clearAllBerryESP() end
        return
    end
    local now = os.clock()
    if force or _berryLastFullScan == 0 or (now - _berryLastFullScan) >= BERRY_FULLSCAN_SEC then
        berryFullScan()
    else
        rebuildBerryCache()
    end
end

local function updateBerryESP()
    if not feEnabled("berryEsp") then
        for _, data in pairs(_G.BerryESP) do
            if data.Text then data.Text.Visible = false end
        end
        return
    end
    _berryEspTick = _berryEspTick + 1
    if _berryEspTick % 3 ~= 0 then return end

    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for obj, data in pairs(_G.BerryESP) do
        if not obj or not obj.Parent then
            removeBerryESP(obj)
        else
            local pos = berryGetPos(obj)
            if not pos then
                if data.Text then data.Text.Visible = false end
            else
                local ok, r1, r2 = pcall(WorldToScreen, pos + Vector3.new(0, 2.5, 0))
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
                            distText = " (" .. math.floor((root.Position - pos).Magnitude / 10) .. "m)"
                        end
                        data.Text.Text = tostring(data.Name or "Berry") .. distText
                        data.Text.Position = Vector2.new(x, y)
                        data.Text.Color = Color3.fromRGB(255, 70, 70)
                        data.Text.Visible = true
                    else
                        data.Text.Visible = false
                    end
                else
                    data.Text.Visible = false
                end
            end
        end
    end
end

local function teleportNearestBerry()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    rebuildBerryCache()
    if #berryCache == 0 then
                berryFullScan()
    end
    local best, bestDist = nil, math.huge
    for _, item in ipairs(berryCache) do
        if item.Position then
            local d = (root.Position - item.Position).Magnitude
            if d < bestDist then bestDist = d; best = item end
        end
    end
    if not best or not best.Position then
                return
    end
    local dest = best.Position + Vector3.new(0, 5, 0)
    for _ = 1, 3 do
        root.CFrame = CFrame.new(dest)
        task.wait(0.08)
    end
    end

local dealerObject=nil
local function refreshDealer()
    if isSea3() then dealerObject=nil; return end
    dealerObject=nil
    local npcFolder=Workspace:FindFirstChild("NPCs")
    if npcFolder then
        for _,obj in ipairs(npcFolder:GetChildren()) do
            if obj.Name=="Legendary Sword Dealer" then dealerObject=obj; return end
        end
    end
end
refreshFruits()
        pcall(refreshBerries); refreshDealer()
task.spawn(function()
    while not _G.FE_Unloaded do refreshFruits()
        pcall(refreshBerries); refreshDealer(); task.wait(0.35) end
end)
local espConn = RunService.Heartbeat:Connect(function()
    updateESP()
    updateBerryESP()
end)
task.spawn(function()
    while not _G.FE_Unloaded do
      local okPanel,_errPanel=pcall(function()
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if isSea2() then
            if dealerObject and dealerObject.Parent then
                dealer.Text="Legendary Sword Dealer: SPAWNED"; dealer.Color=Color3.fromRGB(80,255,100)
            else
                dealer.Text="Legendary Sword Dealer: NOT SPAWNED"; dealer.Color=Color3.fromRGB(255,90,90)
            end
            dealer.Visible=true
        else dealer.Visible=false; dealer.Text="" end
        count.Text="Spawned Fruits: "..#fruitCache
        if #fruitCache>0 then
            local names={}
            local nearest,nearestDist=nil,math.huge
            for _,item in ipairs(fruitCache) do
                table.insert(names,item.Name.." ("..item.Island..")")
                if root and item.Object and item.Object.Parent then
                    local handle=item.Object:FindFirstChild("Handle")
                    if handle then
                        local d=(root.Position-handle.Position).Magnitude
                        if d<nearestDist then nearestDist=d; nearest=item end
                    end
                end
            end
            local shown=math.min(#names,FRUIT_LINES)
            for i=1,FRUIT_LINES do
                if i<=shown then
                    fruitLines[i].Text=((i==1) and "Fruits: " or "- ")..names[i]
                    fruitLines[i].Color=Color3.fromRGB(80,255,100)
                else fruitLines[i].Text="" end
            end
            if #names>FRUIT_LINES then fruitLines[FRUIT_LINES].Text=fruitLines[FRUIT_LINES].Text.." ..." end
            panelShown=shown
            if nearest then
                distance.Text="Nearest: "..nearest.Name.." ("..nearest.Island..") ["..math.floor(nearestDist/10).."m]"
                distance.Color=Color3.fromRGB(255,220,80)
            else distance.Text="Nearest: --" end
        else
            for i=1,FRUIT_LINES do fruitLines[i].Text="" end
            fruitLines[1].Text="Fruits: NONE"; fruitLines[1].Color=Color3.fromRGB(255,90,90)
            panelShown=1; distance.Text="Nearest: --"; distance.Color=Color3.fromRGB(180,180,180)
        end
        local show=feEnabled("panel")
        for _,d in pairs(_G.FruitStatusDrawings) do
            if d==dealer then d.Visible=show and isSea2() else d.Visible=show end
        end
        
        local berryShown = 0
        if feEnabled("berryEsp") then
            local bnames = {}
            for _, item in ipairs(berryCache) do
                bnames[#bnames+1] = item.Name .. " (" .. item.Island .. ")"
            end
            berryShown = math.min(#bnames, BERRY_LINES)
            for i = 1, BERRY_LINES do
                if i <= berryShown then
                    berryLines[i].Text = ((i == 1) and "Berries: " or "- ") .. bnames[i]
                    berryLines[i].Color = Color3.fromRGB(255, 90, 90)
                    berryLines[i].Visible = true
                else
                    berryLines[i].Text = ""
                end
            end
            if #bnames == 0 then
                berryLines[1].Text = "Berries: NONE"
                berryLines[1].Color = Color3.fromRGB(255, 90, 90)
                berryLines[1].Visible = true
                berryShown = 1
            elseif #bnames > BERRY_LINES then
                berryLines[BERRY_LINES].Text = berryLines[BERRY_LINES].Text .. " ..."
            end
        else
            for i = 1, BERRY_LINES do
                berryLines[i].Text = ""
                berryLines[i].Visible = false
            end
        end

        layoutPanel(panelShown, berryShown)
      end)
      if not okPanel then task.wait(0.2) end
        task.wait(0.35)
    end
end)
_pvpAuraEnabled = false
_pvpAuraAltPart = false
_pvpAuraMaxDist = 100
function notify(msg, title, dur)
    pcall(function()
        if LibRef and LibRef.Notify then
            LibRef:Notify(tostring(title or "BF Hub"), tostring(msg), dur or 3, "info")
        end
    end)
end
Players = game:GetService("Players")
LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat wait(0.1); LocalPlayer = Players.LocalPlayer until LocalPlayer
end
S = {
    autoFarming     = false,
    fruitEsp        = false, 
    chamEsp         = false,
    flowerEsp       = false,
    chestEsp        = false,
    chestEspLabels  = {},
    berryEspLabels  = {},
    boatEspEntries  = {},
    flowerEspEntries = {},
    chestEspLabelCache = {},
    berryEspLabelCache = {},
    boatEspCache    = {},
    flowerEspCache  = {},
    mirageEspLabel  = nil,
    selectedBoatSeat = nil,
    selectedBoatSeatLabel = nil,
    _espTrackSnapshots = {},

    boatEsp         = false,
    mirageEsp       = false,
    autoFruits      = false,
    autoTpFruit     = false,
    autoFarmNearest = false,
    autoNpcFarm     = false,
    autoFarmLevel   = false,
    autoMastery     = false,
    autoMaterial    = false,
    autoBoss        = false,
    autoSeaEvent    = false,
    autoMirageTween = false,
    autoMirageGear  = false,
    autoBoatSeat    = false,
    autoHaki        = false,
    autoRaceAbility = false,
    autoKen         = false,
    flameRToC       = false,
    rToX            = false,
    rToXThenZ       = false,
    sanguineZ       = false,
    dragonTalonZ    = false,
    yamaZ           = false,
    tushitaX        = false,
    foxLampX        = false,
    soulGuitarM1    = false,
    diamondM1       = false,
    flameF          = false,
    tweenEmber      = false,
    weaponAfterFruit = false,
    weaponSlot      = "Melee",
    autoStatMelee   = false,
    autoStatDefense = false,
    autoStatSword   = false,
    autoStatGun     = false,
    autoStatFruit   = false,
    statAmount      = 10,
    materialTarget  = "Leather + Scrap Metal",
    bossTarget      = "The Gorilla King",
    seaEventTarget  = "Shark",
    boatSeatTarget  = nil,
    chestPriority   = {"Diamond", "Gold", "Silver"},
    glitchTune      = "sanguine",
    glitchSettings  = {
        sanguine    = {speed=500, delay=0.1,  duration=0.3},
        dragonTalon = {speed=500, delay=0.1,  duration=0.3},
        yama        = {speed=500, delay=0.1,  duration=0.3},
        tushita     = {speed=500, delay=0.4,  duration=0.3},
        foxLamp     = {speed=500, delay=0.1,  duration=0.3},
        soulGuitar  = {speed=500, delay=0.1,  duration=0.3},
        diamond     = {speed=500, delay=0.1,  duration=0.3},
        flame       = {speed=300, delay=0.17, duration=0.15},
    },
    bigHitbox       = false,
    pullEnemies     = false,
    freezePos       = false,
    freezePosition  = nil,
    freezeEnemies   = false,
    frozenEnemies   = {},
    teleportEmber   = false,
    teleportKitsune = false,
    buddhaPull      = false,
    autoRaid        = false,
    customPull      = false,
    voidPull        = false,
    skyPull         = false,
    pvpFarmLoop     = false,
    boatFlyEnabled  = false,
    boatTweening    = false,
    remoteMode      = false,
    dungeonEnabled = false,
    dungeonFloat = false,
    dungeonAutoDoor = true,
    dungeonHitbox = false,
    dungeonM1 = true,
    dungeonBuso = true,
    dungeonHybrid = true,
    dungeonAutoEquip = true,
    dungeonWeapon = "Melee",
    dungeonDestroyObj = true,
    dungeonUseMoves = true,
    dungeonM1Radius = 60,
    dungeonFloatHeight = 12,
    dungeonFlightSpeed = 250,
    dungeonHitboxSize = 50,
    dungeonLocalRadius = 800,
    customPullX    = 0,
    customPullY    = -10,
    customPullZ    = 0,
    boatFlySpeed   = 5,
    FARM_SPEED     = 250,
    CHEST_SPEED    = 310,
    FRUIT_SPEED    = 210,
    NPC_TWEEN_SPEED = 250,
    RAID_SPEED     = 200,
    MASTERY_SPEED  = 250,
    BOAT_TWEEN_SPEED = 250,
    MIN_SPEED      = 50,
    MAX_SPEED      = 1000,
    SPEED_STEP     = 50,
    customOffset   = false,
    customOffsetX  = 0,
    customOffsetY  = 23,
    customOffsetZ  = 0,
    chamBoxes      = {},
    espLabels      = {},
    chestIndex     = 1,
    selectedIsland = 1,
    espLabelCache  = {},
    chamBoxCache   = {},
    currentBoat    = nil,
    boatTween      = nil,
    raidTweenActive   = false,
    raidLastIslandNum = 0,
    lastRaidIslandCount = 0,
}
AFL = {
    tweenSpeed       = 250,
    selectedNpc      = nil,
    currentSea       = 1,
    lastLevel        = 0,
    npcToFarm        = "Sea1First",
    autofarmByLevel  = true,
    autoV3           = false,
    autoV4           = true,
    enableGetQuest   = true,
    usePortalTeleport = true,
    activeTweens     = {},
    lastTween        = os.clock(),
    tween            = nil,
    questData        = nil,
    pos = {
        sea1First              = Vector3.new(-2711.6,24.55,2105.27),
        sea1FirstWait          = Vector3.new(-2834.22,41.8,2152.38),
        jungle                 = Vector3.new(-1602.35,36.91,150.99),
        jungleWait1            = Vector3.new(-1448.19,50.91,64.35),
        jungleWait2            = Vector3.new(-1192.02,7.83,-448.82),
        pirateVillage          = Vector3.new(-1140.03,4.81,3828.47),
        pirateVillageWait1     = Vector3.new(-1233.49,115.64,3985.23),
        pirateVillageWait2     = Vector3.new(-1142.35,84.96,4297.03),
        desert                 = Vector3.new(896.93,6.5,4388.77),
        desertWait1            = Vector3.new(1054.99,52.5,4490.5),
        desertWait2            = Vector3.new(1528.99,14.51,4395.69),
        winter                 = Vector3.new(1382.2,87.34,-1294.29),
        winterWait1            = Vector3.new(1332.85,104.47,-1313.92),
        winterWait2            = Vector3.new(1200.95,144.64,-1550.89),
        marineFortress         = Vector3.new(-5036.22,28.71,4325.45),
        marineFortressWait1    = Vector3.new(-4819.73,20.71,4359.87),
        marineFortressWait2    = Vector3.new(-4950.39,71.41,4166.69),
        sky1                   = Vector3.new(-4841.94,717.73,-2623.45),
        sky1Wait1              = Vector3.new(-4959.59,365.07,-2911.46),
        sky1Wait2              = Vector3.new(-5223.22,449.34,-2397.63),
        prison                 = Vector3.new(5305.62,1.72,474.79),
        prisonWait1            = Vector3.new(5200.82,88.71,481.99),
        prisonWait2            = Vector3.new(5426.98,88.71,988.44),
        colosseum              = Vector3.new(-1576.94,7.45,-2984.09),
        colosseumWait1         = Vector3.new(-1940.03,49.12,-2894.37),
        colosseumWait2         = Vector3.new(-1300.48,7.51,-3243.32),
        magma                  = Vector3.new(-5316.38,11.38,8510.77),
        magmaWait1             = Vector3.new(-5401.39,23.07,8506.53),
        magmaWait2             = Vector3.new(-5775.68,118.91,8802.16),
        underwater             = Vector3.new(61123.74,18.53,1567.43),
        underwaterWait1        = Vector3.new(60952.76,48.74,1532.15),
        underwaterWait2        = Vector3.new(61905.32,108.55,1556.68),
        sky3                   = Vector3.new(-4725.1,845.34,-1956.55),
        sky3Wait               = Vector3.new(-4634.47,866.97,-1938.53),
        sky4                   = Vector3.new(-7861.91,5545.56,-376.38),
        sky4Wait               = Vector3.new(-7688.82,5600.79,-441.55),
        sky5                   = Vector3.new(-7899.52,5636.03,-1409.42),
        sky5Wait1              = Vector3.new(-7638.64,5637.14,-1421.99),
        sky5Wait2              = Vector3.new(-7838.8,5680.52,-1793.07),
        fountain               = Vector3.new(5254.86,38.56,4049.82),
        fountainWait1          = Vector3.new(5633.07,103.08,4059.29),
        fountainWait2          = Vector3.new(5685.56,66.35,4825),
        roseKingdom            = Vector3.new(-424.07,73.14,1835.97),
        roseKingdomWait1       = Vector3.new(-713.92,39.31,2375.86),
        roseKingdomWait2       = Vector3.new(351.33,39.31,2327.74),
        roseKingdomWait3       = Vector3.new(-959.84,80.5,1691.61),
        roseKingdomWait4       = Vector3.new(-1096.17,80.65,1155.03),
        factory                = Vector3.new(634.46,73.29,919.02),
        factoryWait1           = Vector3.new(828.24,140.36,1182.37),
        factoryWait2           = Vector3.new(628.62,73.18,-5.86),
        factoryWait3           = Vector3.new(-45.62,149.66,-301.97),
        greenZone              = Vector3.new(-2442.94,73.24,-3219.45),
        greenZoneWait1         = Vector3.new(-2947.85,111.16,-2979.32),
        greenZoneWait2         = Vector3.new(-1846.47,90.45,-3207.15),
        graveyard              = Vector3.new(-5493.04,48.7,-794.38),
        graveyardWait1         = Vector3.new(-5722.79,126.26,-752.72),
        graveyardWait2         = Vector3.new(-6038.78,6.63,-1297.6),
        snow                   = Vector3.new(605.73,401.65,-5371.18),
        snowWait1              = Vector3.new(536.02,433.39,-5482.01),
        snowWait2              = Vector3.new(1269.49,454.57,-5143.11),
        coldSide               = Vector3.new(-6229.27,82.05,-4851.89),
        coldSideWait1          = Vector3.new(-5867.03,88.63,-4385.88),
        coldSideWait2          = Vector3.new(-6310.69,35.63,-5882.5),
        hotSide                = Vector3.new(-5400.93,29.39,-5376.38),
        hotSideWait1           = Vector3.new(-5700.74,135.59,-5696.33),
        hotSideWait2           = Vector3.new(-5227.32,79.8,-4910.44),
        hauntedShip1           = Vector3.new(1037.82,125.28,32909.95),
        hauntedShip1Wait1      = Vector3.new(1257.26,125.67,33093.13),
        hauntedShip1Wait2      = Vector3.new(612.15,125.28,33049.17),
        hauntedShip1Wait3      = Vector3.new(943.62,40.67,32827.61),
        hauntedShip2           = Vector3.new(971.4,125.28,33248.01),
        winterCastle           = Vector3.new(5670.71,28.4,-6479.92),
        winterCastleWait1      = Vector3.new(5924.53,70.64,-6202.01),
        winterCastleWait2      = Vector3.new(5431.28,75.24,-6812.18),
        wano                   = Vector3.new(-3053.98,239.87,-10147.38),
        wanoWait1              = Vector3.new(-3044.49,29.76,-9787.32),
        wanoWait2              = Vector3.new(-3435.25,275.76,-10480.77),
        hydra1                 = Vector3.new(6737.77,127.56,-715.37),
        hydra1Wait             = Vector3.new(6744.37,115.45,-792.37),
        hydra2                 = Vector3.new(6651.94,546.71,260.22),
        hydra2Wait             = Vector3.new(6753.75,565.17,263.09),
        hydra3                 = Vector3.new(5211.85,1004.13,757.35),
        hydra3Wait             = Vector3.new(4563.77,1002.4,824.84),
        port                   = Vector3.new(-449.36,108.63,5946.07),
        portWait1a             = Vector3.new(-128.02,57.04,5759.62),
        portWait1b             = Vector3.new(-646.17,57.04,5583.4),
        portWait2a             = Vector3.new(-778.57,143.02,6048.03),
        portWait2b             = Vector3.new(-232.7,152.3,6283.1),
        greatTree              = Vector3.new(2479.55,74.3,-6786.71),
        greatTreeWait1         = Vector3.new(2613.79,131.61,-7825.64),
        greatTreeWait2         = Vector3.new(3550.92,155.81,-7354.19),
        hauntedCastle1         = Vector3.new(-9484.23,142.17,5563.99),
        hauntedCastle2         = Vector3.new(-9513.78,172.17,6077.79),
        hauntedCastleWait1     = Vector3.new(-8891,223.03,6137.75),
        hauntedCastleWait2     = Vector3.new(-10079.95,237.5,5913.72),
        hauntedCastleWait3     = Vector3.new(-9502.4,172.17,6049.03),
        hauntedCastleWait4     = Vector3.new(-9545.33,60.32,6341.16),
        iceCream               = Vector3.new(-821.24,65.88,-10963.49),
        iceCreamWait           = Vector3.new(-875.19,184.15,-11124.79),
        cakeLand1              = Vector3.new(-2021.32,37.86,-12029.23),
        cakeLand1Wait1         = Vector3.new(-2299.21,112.6,-12210.75),
        cakeLand1Wait2         = Vector3.new(-1649.28,195.72,-12314.08),
        cakeLand2              = Vector3.new(-1927.75,37.86,-12842.92),
        cakeLand2Wait1         = Vector3.new(-1738.96,143.87,-12935.42),
        cakeLand2Wait2         = Vector3.new(-2248.69,53.57,-12849.23),
        chocolate1             = Vector3.new(237.92,24.8,-12201.14),
        chocolate1Wait1        = Vector3.new(80.22,73.51,-12310.81),
        chocolate1Wait2        = Vector3.new(684.82,45.34,-12421.76),
        chocolate2             = Vector3.new(147.05,24.86,-12778.49),
        chocolate2Wait1        = Vector3.new(48.8,75.13,-12763.81),
        northPole              = Vector3.new(-1159.84,61,-14495.45),
        northPoleWait1         = Vector3.new(-1357.6,83.3,-14704.45),
        northPoleWait2         = Vector3.new(-822.36,80.32,-14390.73),
        peanut                 = Vector3.new(-2104.58,38.17,-10191.75),
        peanutWait             = Vector3.new(-2049.21,165.51,-10335.04),
        tiki1                  = Vector3.new(-16543.93,55.75,-173.82),
        tiki1Wait              = Vector3.new(-16228.02,145.37,-231.54),
        tiki2                  = Vector3.new(-16538.69,55.75,1051.88),
        tiki2Wait              = Vector3.new(-16498.12,131.81,1051.74),
        tiki3                  = Vector3.new(-16665.98,105.31,1576.49),
        tiki3Wait1             = Vector3.new(-16537.67,158.94,1311.88),
        tiki3Wait2             = Vector3.new(-16847.48,122.17,1727.21),
        mansion                = Vector3.new(-13231.25,332.44,-7626.68),
        mansionWait1           = Vector3.new(-13448.1,416.3,-7780.96),
        mansionWait2           = Vector3.new(-13878.98,569.46,-7089.08),
        turtleCenter           = Vector3.new(-12683.65,390.92,-9900.57),
        turtleCenterWait1      = Vector3.new(-12055.72,428.33,-10385.56),
        turtleCenterWait2      = Vector3.new(-13294.97,520.51,-9900.41),
        turtleEntrance         = Vector3.new(-10583.8,331.83,-8757.94),
        turtleEntranceWait     = Vector3.new(-10568.57,477.29,-8832.32),
    },
}
if isSea1() then
    AFL.currentSea = 1; AFL.npcToFarm = "Sea1First"
elseif isSea2() then
    AFL.currentSea = 2; AFL.npcToFarm = "RoseKingdom1"
elseif isSea3() then
    AFL.currentSea = 3; AFL.npcToFarm = "Port1"
end
function afl_pick(a, b) return (math.random(1,2)==1) and a or b end
AFL.islandPositions = {
    Sea1First=AFL.pos.sea1First,
    Jungle1=AFL.pos.jungle, Jungle2=AFL.pos.jungle,
    PirateVillage1=AFL.pos.pirateVillage, PirateVillage2=AFL.pos.pirateVillage,
    DesertIsland1=AFL.pos.desert, DesertIsland2=AFL.pos.desert,
    WinterIsland1=AFL.pos.winter, WinterIsland2=AFL.pos.winter,
    MarineFortress=AFL.pos.marineFortress,
    SkyIsland1=AFL.pos.sky1, SkyIsland2=AFL.pos.sky1,
    PrisonIsland1=AFL.pos.prison, PrisonIsland2=AFL.pos.prison,
    ColosseumIsland1=AFL.pos.colosseum,
    MagmaIsland1=AFL.pos.magma, MagmaIsland2=AFL.pos.magma,
    UnderWaterIsland1=AFL.pos.underwater, UnderWaterIsland2=AFL.pos.underwater,
    SkyIsland3=AFL.pos.sky3, SkyIsland4=AFL.pos.sky4,
    SkyIsland5=AFL.pos.sky5, SkyIsland6=AFL.pos.sky5,
    FountainIsland1=AFL.pos.fountain, FountainIsland2=AFL.pos.fountain,
    RoseKingdom1=AFL.pos.roseKingdom, RoseKingdom2=AFL.pos.roseKingdom,
    Factory1=AFL.pos.factory, Factory2=AFL.pos.factory,
    GreenZone1=AFL.pos.greenZone, GreenZone2=AFL.pos.greenZone,
    Graveyard1=AFL.pos.graveyard, Graveyard2=AFL.pos.graveyard,
    Snow1=AFL.pos.snow, Snow2=AFL.pos.snow,
    ColdSide1=AFL.pos.coldSide, ColdSide2=AFL.pos.coldSide,
    HotSide1=AFL.pos.hotSide, HotSide2=AFL.pos.hotSide,
    HauntedShip1=AFL.pos.hauntedShip1, HauntedShip2=AFL.pos.hauntedShip1,
    WinterCastle1=AFL.pos.winterCastle, WinterCastle2=AFL.pos.winterCastle,
    Wano1=AFL.pos.wano, Wano2=AFL.pos.wano,
    Hydra1=AFL.pos.hydra1, Hydra2=AFL.pos.hydra2, Hydra3=AFL.pos.hydra3, Hydra4=AFL.pos.hydra3,
    Port1=AFL.pos.port, Port2=AFL.pos.port,
    GreatTree1=AFL.pos.greatTree, GreatTree2=AFL.pos.greatTree,
    HauntedCastle1=AFL.pos.hauntedCastle1, HauntedCastle2=AFL.pos.hauntedCastle1,
    HauntedCastle3=AFL.pos.hauntedCastle2, HauntedCastle4=AFL.pos.hauntedCastle2,
    IceCream1=AFL.pos.iceCream, IceCream2=AFL.pos.iceCream,
    CakeLand1=AFL.pos.cakeLand1, CakeLand2=AFL.pos.cakeLand1,
    CakeLand3=AFL.pos.cakeLand2, CakeLand4=AFL.pos.cakeLand2,
    Chocolate1=AFL.pos.chocolate1, Chocolate2=AFL.pos.chocolate1,
    Chocolate3=AFL.pos.chocolate2, Chocolate4=AFL.pos.chocolate2,
    NorthPole1=AFL.pos.northPole, NorthPole2=AFL.pos.northPole,
    Peanut1=AFL.pos.peanut, Peanut2=AFL.pos.peanut,
    Tiki1Quest1=AFL.pos.tiki1, Tiki1Quest2=AFL.pos.tiki1,
    Tiki2Quest1=AFL.pos.tiki2, Tiki2Quest2=AFL.pos.tiki2,
    Tiki3Quest1=AFL.pos.tiki3, Tiki3Quest2=AFL.pos.tiki3,
    Mansion1=AFL.pos.mansion, Mansion2=AFL.pos.mansion,
    TurtleCenter1=AFL.pos.turtleCenter, TurtleCenter2=AFL.pos.turtleCenter,
    TurtleEntrance1=AFL.pos.turtleEntrance, TurtleEntrance2=AFL.pos.turtleEntrance,
}
AFL.waitPositions = {
    Sea1First=AFL.pos.sea1FirstWait,
    Jungle1=AFL.pos.jungleWait1, Jungle2=AFL.pos.jungleWait2,
    PirateVillage1=AFL.pos.pirateVillageWait1, PirateVillage2=AFL.pos.pirateVillageWait2,
    DesertIsland1=AFL.pos.desertWait1, DesertIsland2=AFL.pos.desertWait2,
    WinterIsland1=AFL.pos.winterWait1, WinterIsland2=AFL.pos.winterWait2,
    MarineFortress=afl_pick(AFL.pos.marineFortressWait1, AFL.pos.marineFortressWait2),
    SkyIsland1=AFL.pos.sky1Wait1, SkyIsland2=AFL.pos.sky1Wait2,
    PrisonIsland1=AFL.pos.prisonWait1, PrisonIsland2=AFL.pos.prisonWait2,
    ColosseumIsland1=AFL.pos.colosseumWait1, ColosseumIsland2=AFL.pos.colosseumWait2,
    MagmaIsland1=AFL.pos.magmaWait1, MagmaIsland2=AFL.pos.magmaWait2,
    UnderWaterIsland1=AFL.pos.underwaterWait1, UnderWaterIsland2=AFL.pos.underwaterWait2,
    SkyIsland3=AFL.pos.sky3Wait, SkyIsland4=AFL.pos.sky4Wait,
    SkyIsland5=AFL.pos.sky5Wait1, SkyIsland6=AFL.pos.sky5Wait2,
    FountainIsland1=AFL.pos.fountainWait1, FountainIsland2=AFL.pos.fountainWait2,
    RoseKingdom1=afl_pick(AFL.pos.roseKingdomWait1, AFL.pos.roseKingdomWait2),
    RoseKingdom2=afl_pick(AFL.pos.roseKingdomWait3, AFL.pos.roseKingdomWait4),
    Factory1=AFL.pos.factoryWait1, Factory2=afl_pick(AFL.pos.factoryWait2, AFL.pos.factoryWait3),
    GreenZone1=AFL.pos.greenZoneWait1, GreenZone2=AFL.pos.greenZoneWait2,
    Graveyard1=AFL.pos.graveyardWait1, Graveyard2=AFL.pos.graveyardWait2,
    Snow1=AFL.pos.snowWait1, Snow2=AFL.pos.snowWait2,
    ColdSide1=AFL.pos.coldSideWait1, ColdSide2=AFL.pos.coldSideWait2,
    HotSide1=AFL.pos.hotSideWait1, HotSide2=AFL.pos.hotSideWait2,
    HauntedShip1=afl_pick(AFL.pos.hauntedShip1Wait1, AFL.pos.hauntedShip1Wait2),
    HauntedShip2=AFL.pos.hauntedShip1Wait3,
    WinterCastle1=AFL.pos.winterCastleWait1, WinterCastle2=AFL.pos.winterCastleWait2,
    Wano1=AFL.pos.wanoWait1, Wano2=AFL.pos.wanoWait2,
    Hydra1=AFL.pos.hydra1Wait, Hydra2=AFL.pos.hydra2Wait,
    Hydra3=AFL.pos.hydra3Wait, Hydra4=AFL.pos.hydra3Wait,
    Port1=afl_pick(AFL.pos.portWait1a, AFL.pos.portWait1b),
    Port2=afl_pick(AFL.pos.portWait2a, AFL.pos.portWait2b),
    GreatTree1=AFL.pos.greatTreeWait1, GreatTree2=AFL.pos.greatTreeWait2,
    HauntedCastle1=AFL.pos.hauntedCastleWait1, HauntedCastle2=AFL.pos.hauntedCastleWait2,
    HauntedCastle3=AFL.pos.hauntedCastleWait3, HauntedCastle4=AFL.pos.hauntedCastleWait4,
    IceCream1=AFL.pos.iceCreamWait, IceCream2=AFL.pos.iceCreamWait,
    CakeLand1=AFL.pos.cakeLand1Wait1, CakeLand2=AFL.pos.cakeLand1Wait2,
    CakeLand3=AFL.pos.cakeLand2Wait1, CakeLand4=AFL.pos.cakeLand2Wait2,
    Chocolate1=AFL.pos.chocolate1Wait1, Chocolate2=AFL.pos.chocolate1Wait2,
    Chocolate3=AFL.pos.chocolate2Wait1, Chocolate4=AFL.pos.chocolate2Wait1,
    NorthPole1=AFL.pos.northPoleWait1, NorthPole2=AFL.pos.northPoleWait2,
    Peanut1=AFL.pos.peanutWait, Peanut2=AFL.pos.peanutWait,
    Tiki1Quest1=AFL.pos.tiki1Wait, Tiki1Quest2=AFL.pos.tiki1Wait,
    Tiki2Quest1=AFL.pos.tiki2Wait, Tiki2Quest2=AFL.pos.tiki2Wait,
    Tiki3Quest1=AFL.pos.tiki3Wait1, Tiki3Quest2=AFL.pos.tiki3Wait2,
    Mansion1=AFL.pos.mansionWait1, Mansion2=AFL.pos.mansionWait2,
    TurtleCenter1=AFL.pos.turtleCenterWait1, TurtleCenter2=AFL.pos.turtleCenterWait2,
    TurtleEntrance1=AFL.pos.turtleEntranceWait, TurtleEntrance2=AFL.pos.turtleEntranceWait,
}
AFL.levelFarmTable = {
    [1]={{1,10,"Sea1First"},{10,15,"Jungle1"},{15,30,"Jungle2"},{30,40,"PirateVillage1"},{40,60,"PirateVillage2"},{60,75,"DesertIsland1"},{75,90,"DesertIsland2"},{90,105,"WinterIsland1"},{105,120,"WinterIsland2"},{120,150,"MarineFortress"},{150,175,"SkyIsland1"},{175,190,"SkyIsland2"},{190,210,"PrisonIsland1"},{210,250,"PrisonIsland2"},{250,300,"ColosseumIsland1"},{300,325,"MagmaIsland1"},{325,375,"MagmaIsland2"},{375,400,"UnderWaterIsland1"},{400,450,"UnderWaterIsland2"},{450,475,"SkyIsland3"},{475,525,"SkyIsland4"},{525,550,"SkyIsland5"},{550,600,"SkyIsland6"},{600,625,"FountainIsland1"},{625,700,"FountainIsland2"}},
    [2]={{700,725,"RoseKingdom1"},{725,775,"RoseKingdom2"},{775,800,"Factory1"},{800,875,"Factory2"},{875,900,"GreenZone1"},{900,950,"GreenZone2"},{950,975,"Graveyard1"},{975,1000,"Graveyard2"},{1000,1050,"Snow1"},{1050,1100,"Snow2"},{1100,1125,"ColdSide1"},{1125,1175,"ColdSide2"},{1175,1200,"HotSide1"},{1200,1250,"HotSide2"},{1250,1300,"HauntedShip1"},{1300,1350,"HauntedShip2"},{1350,1375,"WinterCastle1"},{1375,1425,"WinterCastle2"},{1425,1450,"Wano1"},{1450,1500,"Wano2"}},
    [3]={{1500,1525,"Port1"},{1525,1575,"Port2"},{1575,1600,"Hydra1"},{1600,1625,"Hydra2"},{1625,1650,"Hydra3"},{1650,1700,"Hydra4"},{1700,1725,"GreatTree1"},{1725,1775,"GreatTree2"},{1775,1800,"TurtleEntrance1"},{1800,1825,"TurtleEntrance2"},{1825,1850,"Mansion1"},{1850,1900,"Mansion2"},{1900,1925,"TurtleCenter1"},{1925,1975,"TurtleCenter2"},{1975,2000,"HauntedCastle1"},{2000,2025,"HauntedCastle2"},{2025,2050,"HauntedCastle3"},{2050,2075,"HauntedCastle4"},{2075,2100,"Peanut1"},{2100,2125,"Peanut2"},{2125,2150,"IceCream1"},{2150,2200,"IceCream2"},{2200,2225,"CakeLand1"},{2225,2250,"CakeLand2"},{2250,2275,"CakeLand3"},{2275,2300,"CakeLand4"},{2300,2325,"Chocolate1"},{2325,2350,"Chocolate2"},{2350,2375,"Chocolate3"},{2375,2400,"Chocolate4"},{2400,2425,"NorthPole1"},{2425,2450,"NorthPole2"},{2450,2475,"Tiki1Quest1"},{2475,2500,"Tiki1Quest2"},{2500,2525,"Tiki2Quest1"},{2525,2550,"Tiki2Quest2"},{2550,2575,"Tiki3Quest1"},{2575,2800,"Tiki3Quest2"}}
}
dangerLevels = {
    {name="Level 1", pos=Vector3.new(-22154,37,2735)},
    {name="Level 2", pos=Vector3.new(-26413,37,3671)},
    {name="Level 3", pos=Vector3.new(-30027,37,3921)},
    {name="Level 4", pos=Vector3.new(-33348,37,3704)},
    {name="Level 5", pos=Vector3.new(-38169,37,5121)},
    {name="Level 6", pos=Vector3.new(-43568,37,7018)},
}
dangerLevelNames = {}
for _, d in pairs(dangerLevels) do table.insert(dangerLevelNames, d.name) end
islandNames = {}
islandList = {
    {name="Tiki2",          pos=Vector3.new(-16577.81,107.2,1226.22)},
    {name="Tiki1",          pos=Vector3.new(-16546.72,55.87,-228.59)},
    {name="Port",           pos=Vector3.new(-706.75,85.98,5775.46)},
    {name="Hydra1",         pos=Vector3.new(6737.77,127.56,-715.37)},
    {name="Hydra2",         pos=Vector3.new(6651.94,546.71,260.22)},
    {name="Hydra3",         pos=Vector3.new(4563.77,1002.40,824.84)},
    {name="GreatTree1",     pos=Vector3.new(2976.45,74.41,-7919.18)},
    {name="GreatTree2",     pos=Vector3.new(3727.85,124.12,-7153.10)},
    {name="HauntedCastle",  pos=Vector3.new(-9558.96,172.28,6139.46)},
    {name="IceCream",       pos=Vector3.new(-836.01,65.99,-10973.16)},
    {name="CakeLand",       pos=Vector3.new(-2115.22,70.16,-12366.38)},
    {name="Chocolate",      pos=Vector3.new(314.05,24.97,-12480.51)},
    {name="Peanut",         pos=Vector3.new(-2093.83,38.28,-10204.63)},
    {name="Mansion",        pos=Vector3.new(-13330.71,450.81,-7441.45)},
    {name="TurtleCenter2",  pos=Vector3.new(-13274.77,391.72,-9791.60)},
    {name="TurtleCenter1",  pos=Vector3.new(-12019.83,331.91,-10562.06)},
    {name="TurtleEntrance", pos=Vector3.new(-10607.67,331.94,-8782.75)},
}
for _, isle in pairs(islandList) do table.insert(islandNames, isle.name) end
function getBoat()
    local char=LocalPlayer.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local boatsFolder=game.Workspace:FindFirstChild("Boats")
    if not boatsFolder then return nil end
    for _, b in pairs(boatsFolder:GetChildren()) do
        if b:IsA("Model") then
            local seat=b:FindFirstChildOfClass("VehicleSeat")
            if seat then
                local dx=seat.Position.X-hrp.Position.X
                local dy=seat.Position.Y-hrp.Position.Y
                local dz=seat.Position.Z-hrp.Position.Z
                if math.sqrt(dx*dx+dy*dy+dz*dz)<20 then return b end
            end
        end
    end
    return nil
end
function getBoatCameraVectors()
    local char=LocalPlayer.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.new(0,0,-1), Vector3.new(1,0,0) end
    local cp=game.Workspace.CurrentCamera.Position
    local hp=hrp.Position
    local fx=hp.X-cp.X; local fz=hp.Z-cp.Z
    local fl=math.sqrt(fx*fx+fz*fz)
    if fl>0.001 then fx=fx/fl; fz=fz/fl else fx=0; fz=-1 end
    return Vector3.new(fx,0,fz), Vector3.new(-fz,0,fx)
end
function boatTweenTo(targetPos)
    S.currentBoat = getBoat()
    if not S.currentBoat then notify("No boat found!","Boat Fly",2); return end
    local primary=S.currentBoat.PrimaryPart
    if not primary then return end
    S.boatTweening=true
    primary.Position=Vector3.new(primary.Position.X, primary.Position.Y+50, primary.Position.Z)
    wait(0.1)
    local fixedY=primary.Position.Y
    local startX=primary.Position.X; local startZ=primary.Position.Z
    local dx=targetPos.X-startX; local dz=targetPos.Z-startZ
    local dist=math.sqrt(dx*dx+dz*dz)
    local duration=dist/(S.boatFlySpeed*100)
    local t0=os.clock()
    while S.boatTweening do
        local alpha=math.min((os.clock()-t0)/duration,1)
        primary.Position=Vector3.new(startX+dx*alpha, fixedY, startZ+dz*alpha)
        primary.Velocity=Vector3.new(0,0,0)
        primary.AssemblyLinearVelocity=Vector3.new(0,0,0)
        if alpha>=1 then break end
        wait(0.01)
    end
    S.boatTweening=false; S.currentBoat=nil; S.boatTween=nil
    notify("Arrived!","Boat Fly",2)
end
task.spawn(function()
    while true do
        if not S.boatFlyEnabled or S.boatTweening then
            task.wait(0.15)
            continue
        end
        local boat=getBoat(); if not boat then continue end
        local primary=boat.PrimaryPart; if not primary then continue end
        local fwd, right=getBoatCameraVectors()
        local mx, my, mz=0,0,0
        if iskeypressed(0x57) then mx=mx+fwd.X*S.boatFlySpeed;   mz=mz+fwd.Z*S.boatFlySpeed   end
        if iskeypressed(0x53) then mx=mx-fwd.X*S.boatFlySpeed;   mz=mz-fwd.Z*S.boatFlySpeed   end
        if iskeypressed(0x44) then mx=mx+right.X*S.boatFlySpeed; mz=mz+right.Z*S.boatFlySpeed end
        if iskeypressed(0x41) then mx=mx-right.X*S.boatFlySpeed; mz=mz-right.Z*S.boatFlySpeed end
        if iskeypressed(0x58) then my=my+S.boatFlySpeed end
        if iskeypressed(0x10) then my=my-S.boatFlySpeed end
        primary.Velocity=Vector3.new(0,0,0)
        primary.AssemblyLinearVelocity=Vector3.new(0,0,0)
        primary.AssemblyLinearVelocity=Vector3.new(0,0,0)
        primary.Position=Vector3.new(primary.Position.X+mx, primary.Position.Y+my, primary.Position.Z+mz)
        task.wait(0.1)
    end
end)
function clearEspLabels()
    for _, entry in pairs(S.espLabels) do entry.label.Visible=false end
    S.espLabels={}
end
function clearChamBoxes()
    for _, entry in pairs(S.chamBoxes) do
        for _, line in pairs(entry.lines) do line.Visible=false end
    end
    S.chamBoxes={}
end
function buildChamBoxes()
    for _, entry in pairs(S.chamBoxCache) do
        for _, line in pairs(entry.lines) do line.Visible=false end
    end
    S.chamBoxes={}
    for _, obj in pairs(game.Workspace:GetChildren()) do
        local fruitFolder=obj:FindFirstChild("Fruit")
        if fruitFolder then
            local fruitPart=fruitFolder:FindFirstChild("Fruit")
            if fruitPart and fruitPart:IsA("BasePart") then
                local key=tostring(fruitPart)
                if not S.chamBoxCache[key] then
                    local lines={}
                    for i=1,4 do
                        local l=Drawing.new("Line")
                        l.Color=Color3.new(1,0.4,0); l.Thickness=2; l.Visible=false; l.ZIndex=9
                        table.insert(lines,l)
                    end
                    S.chamBoxCache[key]={lines=lines, part=fruitPart}
                else
                    S.chamBoxCache[key].part=fruitPart
                end
                table.insert(S.chamBoxes, S.chamBoxCache[key])
            end
        end
    end
end
function buildEspLabels()
    for _, entry in pairs(S.espLabelCache) do entry.label.Visible=false end
    S.espLabels={}
    for _, obj in pairs(game.Workspace:GetChildren()) do
        local fruitFolder=obj:FindFirstChild("Fruit")
        if fruitFolder then
            local fruitPart=fruitFolder:FindFirstChild("Fruit")
            if fruitPart and fruitPart:IsA("BasePart") then
                local fruitName=(obj.Name~="Fruit" and obj.Name) or "Spawned Fruit"
                local key=tostring(fruitPart)
                if not S.espLabelCache[key] then
                    local label=Drawing.new("Text")
                    label.Text=fruitName; label.Position=Vector2.new(0,0)
                    label.Color=Color3.new(0,1,0); label.Size=14; label.Outline=true
                    label.Visible=false; label.ZIndex=10; label.Font=Drawing.Fonts.Monospace; label.Center=true
                    S.espLabelCache[key]={label=label, part=fruitPart}
                else
                    S.espLabelCache[key].label.Text=fruitName
                    S.espLabelCache[key].part=fruitPart
                end
                table.insert(S.espLabels, S.espLabelCache[key])
            end
        end
    end
end
function tweenTo(hrp, targetPos, speed, checkFn)
    local startPos=hrp.Position
    local dx=targetPos.X-startPos.X; local dy=targetPos.Y-startPos.Y; local dz=targetPos.Z-startPos.Z
    local distance=math.sqrt(dx*dx+dy*dy+dz*dz)
    if distance<0.1 then return end
    local duration=distance/speed; local startTime=os.clock()
    while true do
        if not checkFn() then return end
        local alpha=math.min((os.clock()-startTime)/duration,1)
        hrp.Position=Vector3.new(startPos.X+dx*alpha, startPos.Y+dy*alpha, startPos.Z+dz*alpha)
        hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
        if alpha>=1 then break end
        task.wait()
    end
end
function isAlive(model)
    if not model or not model.Parent then return false end
    local hum=model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health<=0 then return false end
    return true
end
function farmAttack(hrp, checkFn, enemyName)
    local folder=game.Workspace:FindFirstChild("Enemies")
    if not folder then return end
    local nearest, bestDist=nil, math.huge
    for _, model in pairs(folder:GetChildren()) do
        if model:IsA("Model") and isAlive(model) then
            if not enemyName or model.Name==enemyName then
                local root=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildOfClass("BasePart")
                if root then
                    local dx=root.Position.X-hrp.Position.X
                    local dy=root.Position.Y-hrp.Position.Y
                    local dz=root.Position.Z-hrp.Position.Z
                    local d=math.sqrt(dx*dx+dy*dy+dz*dz)
                    if d<bestDist and d<=5000 then bestDist=d; nearest=model end
                end
            end
        end
    end
    if not nearest then return end
    task.spawn(function()
        while checkFn() and isAlive(nearest) do
            local eh=nearest:FindFirstChild("HumanoidRootPart")
            local hd=nearest:FindFirstChild("Head")
            if eh then eh.CanCollide=false end
            if hd then hd.CanCollide=false end
            task.wait()
        end
    end)
    task.spawn(function()
        while checkFn() and isAlive(nearest) do
            if not S.remoteMode then
                local head=nearest:FindFirstChild("Head")
                if head then head.Size=Vector3.new(50,50,50) end
            end
            task.wait()
        end
    end)
    local lastClick=0
    local function hasSanguineArt()
        local bp=LocalPlayer:FindFirstChild("Backpack")
        if bp then for _,i in pairs(bp:GetChildren()) do if i.Name=="Sanguine Art" then return true end end end
        local char=LocalPlayer.Character
        if char then for _,i in pairs(char:GetChildren()) do if i.Name=="Sanguine Art" then return true end end end
        return false
    end
    while checkFn() and isAlive(nearest) do
        local tr=nearest:FindFirstChild("HumanoidRootPart") or nearest:FindFirstChildOfClass("BasePart")
        if tr then
            local xOffset=hasSanguineArt() and 15 or 0
            local ox = S.customOffset and S.customOffsetX or xOffset
            local oy = S.customOffset and S.customOffsetY or 23
            local oz = S.customOffset and S.customOffsetZ or 0
            hrp.Position=Vector3.new(tr.Position.X+ox, tr.Position.Y+oy, tr.Position.Z+oz)
            hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
        end
        local now=os.clock()
        if now-lastClick>=0.06 then mouse1click(); lastClick=now end
        task.wait()
    end
end
local REMOTE_SESSION_ID = "32501259"
local REMOTE_MAX_DIST   = 60
local _remoteNet        = nil
local _remoteRegAtk     = nil
local _remoteRegHit     = nil
local _lastRemoteFire   = 0
local function ensureRemotes()
    if _remoteRegAtk and _remoteRegHit then return true end
    local net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
    if net then net = net:FindFirstChild("Net") end
    if not net then return false end
    _remoteNet    = net
    _remoteRegAtk = net:FindFirstChild("RE/RegisterAttack")
    _remoteRegHit = net:FindFirstChild("RE/RegisterHit")
    return _remoteRegAtk ~= nil and _remoteRegHit ~= nil
end
function remoteAttack()
    if not ensureRemotes() then return end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos  = hrp.Position
    local folder = game.Workspace:FindFirstChild("Enemies")
    if not folder then return end
    local hitTable   = {}
    local primaryPart = nil
    for _, enemy in ipairs(folder:GetChildren()) do
        if enemy and enemy.Parent then
            local hum  = enemy:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health and hum.Health > 0 then
                local part = enemy:FindFirstChild("LeftLowerLeg")
                          or enemy:FindFirstChild("Head")
                          or enemy:FindFirstChild("HumanoidRootPart")
                if not part then
                    for _, c in ipairs(enemy:GetChildren()) do
                        if c:IsA("BasePart") then part = c; break end
                    end
                end
                if part and part.Parent then
                    local ok, pos = pcall(function() return part.Position end)
                    if ok and pos then
                        local dx = pos.X - myPos.X
                        local dy = pos.Y - myPos.Y
                        local dz = pos.Z - myPos.Z
                        local d  = math.sqrt(dx*dx + dy*dy + dz*dz)
                        if d <= REMOTE_MAX_DIST then
                            table.insert(hitTable, {enemy, part})
                            if not primaryPart then primaryPart = part end
                        end
                    end
                end
            end
        end
    end
    if #hitTable == 0 then return end
    pcall(function() _remoteRegAtk:FireServer(0.5) end)
    task.wait()
    pcall(function() _remoteRegHit:FireServer(primaryPart, hitTable, nil, REMOTE_SESSION_ID) end)
    _lastRemoteFire = os.clock()
end
task.spawn(function()
    local lastChestCount=0
    while true do
        if S.autoFarming then
            local ChestModels=game.Workspace:FindFirstChild("ChestModels")
            if ChestModels then
                local children=ChestModels:GetChildren()
                local ranked={}
                for _, model in ipairs(children) do
                    local name=tostring(model.Name or "")
                    local rank=99
                    local pri=S.chestPriority or {"Diamond","Gold","Silver"}
                    local low=string.lower(name)
                    for i, p in ipairs(pri) do
                        if low:find(string.lower(p), 1, true) then rank=i; break end
                    end
                    ranked[#ranked+1]={model=model, rank=rank}
                end
                table.sort(ranked, function(a,b) return a.rank<b.rank end)
                local count=#ranked
                if count~=lastChestCount then S.chestIndex=1; lastChestCount=count end
                if count>0 then
                    if S.chestIndex>count then S.chestIndex=1 end
                    local entry=ranked[S.chestIndex]
                    local model=entry and entry.model
                    if model then
                        local tp=model:FindFirstChild("RootPart") or model:FindFirstChildWhichIsA("BasePart")
                        if tp then
                            notify("Going to "..model.Name.." chest","laced.club",2)
                            local char=LocalPlayer.Character
                            local hrp=char and char:FindFirstChild("HumanoidRootPart")
                            if hrp then tweenTo(hrp, Vector3.new(tp.Position.X,tp.Position.Y+3,tp.Position.Z), S.CHEST_SPEED, function() return S.autoFarming end) end
                            S.chestIndex=S.chestIndex+1
                        else S.chestIndex=S.chestIndex+1 end
                    end
                end
            else lastChestCount=0 end
            task.wait(0.5)
        else task.wait(0.1) end
    end
end)
task.spawn(function()
    while true do
        if S.autoFruits then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bestPart, bestDist=nil, math.huge
                for _, obj in pairs(game.Workspace:GetChildren()) do
                    local ff=obj:FindFirstChild("Fruit")
                    if ff then
                        local fp=ff:FindFirstChild("Fruit")
                        if fp and fp:IsA("BasePart") then
                            local dx=fp.Position.X-hrp.Position.X; local dy=fp.Position.Y-hrp.Position.Y; local dz=fp.Position.Z-hrp.Position.Z
                            local dist=math.sqrt(dx*dx+dy*dy+dz*dz)
                            if dist<bestDist then bestDist=dist; bestPart=fp end
                        end
                    end
                end
                if bestPart then
                    notify("Farming fruit...","redacted",1)
                    tweenTo(hrp, Vector3.new(bestPart.Position.X,bestPart.Position.Y+3,bestPart.Position.Z), S.FRUIT_SPEED, function() return S.autoFruits end)
                end
            end
            task.wait(1)
        else task.wait(0.1) end
    end
end)
task.spawn(function()
    while true do
        if S.autoFarmNearest then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if S.remoteMode then
                    local folder=game.Workspace:FindFirstChild("Enemies")
                    if folder then
                        local nearest, bestDist=nil, math.huge
                        for _, model in pairs(folder:GetChildren()) do
                            if model:IsA("Model") and isAlive(model) then
                                local root=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildOfClass("BasePart")
                                if root then
                                    local dx=root.Position.X-hrp.Position.X
                                    local dy=root.Position.Y-hrp.Position.Y
                                    local dz=root.Position.Z-hrp.Position.Z
                                    local d=math.sqrt(dx*dx+dy*dy+dz*dz)
                                    if d<bestDist then bestDist=d; nearest=model end
                                end
                            end
                        end
                        if nearest then
                            while S.autoFarmNearest and S.remoteMode and isAlive(nearest) do
                                local tr=nearest:FindFirstChild("HumanoidRootPart") or nearest:FindFirstChildOfClass("BasePart")
                                if not tr then break end
                                hrp.Position=Vector3.new(tr.Position.X, tr.Position.Y+30, tr.Position.Z)
                                hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                                remoteAttack()
                                task.wait(0.05)
                            end
                        end
                    end
                else
                    farmAttack(hrp, function() return S.autoFarmNearest and not S.remoteMode end, nil)
                end
            end
            task.wait(0.1)
        else task.wait(0.1) end
    end
end)
task.spawn(function()
    while true do
        if S.autoTpFruit then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bestPart, bestDist=nil, math.huge
                for _, obj in pairs(game.Workspace:GetChildren()) do
                    local ff=obj:FindFirstChild("Fruit")
                    if ff then
                        local fp=ff:FindFirstChild("Fruit")
                        if fp and fp:IsA("BasePart") then
                            local dx=fp.Position.X-hrp.Position.X; local dy=fp.Position.Y-hrp.Position.Y; local dz=fp.Position.Z-hrp.Position.Z
                            local dist=math.sqrt(dx*dx+dy*dy+dz*dz)
                            if dist<bestDist then bestDist=dist; bestPart=fp end
                        end
                    end
                end
                if bestPart then
                    hrp.Position=Vector3.new(bestPart.Position.X,bestPart.Position.Y+3,bestPart.Position.Z)
                    hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                end
            end
            task.wait(0.1)
        else task.wait(0.1) end
    end
end)
task.spawn(function()
    while true do
        if S.autoNpcFarm then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local island=islandList[S.selectedIsland]
                local ip=island.pos
                notify("NPC Farm: going to "..island.name,"redacted",2)
                tweenTo(hrp, Vector3.new(ip.X,ip.Y,ip.Z), S.NPC_TWEEN_SPEED, function() return S.autoNpcFarm end)
                task.wait(0.5)
                local char2=LocalPlayer.Character
                if char2 then for _,part in pairs(char2:GetChildren()) do if part:IsA("BasePart") then part.CanCollide=false end end end
                while S.autoNpcFarm do
                    local hrp2=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp2 then task.wait(0.1); break end
                    farmAttack(hrp2, function() return S.autoNpcFarm end, nil)
                    task.wait(0.1)
                end
            end
            task.wait(0.1)
        else task.wait(0.1) end
    end
end)
function afl_loadQuestData()
    AFL.questData={}
    if AFL.currentSea==1 then
        AFL.questData.Sea1First={enemy="Trainee",questButton=1,ammountToKill=5}
        AFL.questData.Jungle1={enemy="Monkey",questButton=1,ammountToKill=6}
        AFL.questData.Jungle2={enemy="Gorilla",questButton=2,ammountToKill=8}
        AFL.questData.PirateVillage1={enemy="Pirate",questButton=1,ammountToKill=8}
        AFL.questData.PirateVillage2={enemy="Brute",questButton=2,ammountToKill=8}
        AFL.questData.DesertIsland1={enemy="Desert Bandit",questButton=1,ammountToKill=8}
        AFL.questData.DesertIsland2={enemy="Desert Officer",questButton=2,ammountToKill=6}
        AFL.questData.WinterIsland1={enemy="Snow Bandit",questButton=1,ammountToKill=7}
        AFL.questData.WinterIsland2={enemy="Snowman",questButton=2,ammountToKill=8}
        AFL.questData.MarineFortress={enemy="Chief Petty Officer",questButton=1,ammountToKill=8}
        AFL.questData.SkyIsland1={enemy="Sky Bandit",questButton=1,ammountToKill=7}
        AFL.questData.SkyIsland2={enemy="Dark Master",questButton=2,ammountToKill=8}
        AFL.questData.PrisonIsland1={enemy="Prisoner",questButton=1,ammountToKill=8}
        AFL.questData.PrisonIsland2={enemy="Dangerous Prisoner",questButton=2,ammountToKill=8}
        AFL.questData.ColosseumIsland1={enemy="Toga Warrior",questButton=1,ammountToKill=7}
        AFL.questData.MagmaIsland1={enemy="Military Soldier",questButton=1,ammountToKill=7}
        AFL.questData.MagmaIsland2={enemy="Military Spy",questButton=2,ammountToKill=8}
        AFL.questData.UnderWaterIsland1={enemy="Fishman Warrior",questButton=1,ammountToKill=8}
        AFL.questData.UnderWaterIsland2={enemy="Fishman Commando",questButton=2,ammountToKill=7}
        AFL.questData.SkyIsland3={enemy="God's Guard",questButton=1,ammountToKill=7}
        AFL.questData.SkyIsland4={enemy="Shanda",questButton=2,ammountToKill=9}
        AFL.questData.SkyIsland5={enemy="Royal Squad",questButton=1,ammountToKill=8}
        AFL.questData.SkyIsland6={enemy="Royal Soldier",questButton=2,ammountToKill=8}
        AFL.questData.FountainIsland1={enemy="Galley Pirate",questButton=1,ammountToKill=8}
        AFL.questData.FountainIsland2={enemy="Galley Captain",questButton=2,ammountToKill=9}
    elseif AFL.currentSea==2 then
        AFL.questData.RoseKingdom1={enemy="Raider",questButton=1,ammountToKill=8}
        AFL.questData.RoseKingdom2={enemy="Mercenary",questButton=2,ammountToKill=8}
        AFL.questData.Factory1={enemy="Swan Pirate",questButton=1,ammountToKill=8}
        AFL.questData.Factory2={enemy="Factory Staff",questButton=2,ammountToKill=8}
        AFL.questData.GreenZone1={enemy="Marine Lieutenant",questButton=1,ammountToKill=8}
        AFL.questData.GreenZone2={enemy="Marine Captain",questButton=2,ammountToKill=9}
        AFL.questData.Graveyard1={enemy="Zombie",questButton=1,ammountToKill=8}
        AFL.questData.Graveyard2={enemy="Vampire",questButton=2,ammountToKill=8}
        AFL.questData.Snow1={enemy="Snow Trooper",questButton=1,ammountToKill=8}
        AFL.questData.Snow2={enemy="Winter Warrior",questButton=2,ammountToKill=9}
        AFL.questData.HauntedShip1={enemy="Ship Deckhand",questButton=1,ammountToKill=8}
        AFL.questData.HauntedShip2={enemy="Ship Engineer",questButton=2,ammountToKill=8}
        AFL.questData.WinterCastle1={enemy="Arctic Warrior",questButton=1,ammountToKill=8}
        AFL.questData.WinterCastle2={enemy="Snow Lurker",questButton=2,ammountToKill=8}
        AFL.questData.Wano1={enemy="Sea Soldier",questButton=1,ammountToKill=8}
        AFL.questData.Wano2={enemy="Water Fighter",questButton=2,ammountToKill=8}
    elseif AFL.currentSea==3 then
        AFL.questData.Port1={enemy="Pirate Millionaire",questButton=1,ammountToKill=8}
        AFL.questData.Port2={enemy="Pirate Billionaire",questButton=2,ammountToKill=8}
        AFL.questData.Hydra1={enemy="Dragon Crew Warrior",questButton=1,ammountToKill=8}
        AFL.questData.Hydra2={enemy="Dragon Crew Archer",questButton=2,ammountToKill=8}
        AFL.questData.Hydra3={enemy="Hydra Enforcer",questButton=1,ammountToKill=8}
        AFL.questData.Hydra4={enemy="Venemous Assailant",questButton=2,ammountToKill=8}
        AFL.questData.GreatTree1={enemy="Marine Commodore",questButton=1,ammountToKill=8}
        AFL.questData.GreatTree2={enemy="Marine Admiral",questButton=2,ammountToKill=8}
        AFL.questData.TurtleEntrance1={enemy="Fishman Raider",questButton=1,ammountToKill=8}
        AFL.questData.TurtleEntrance2={enemy="Fishman Captain",questButton=2,ammountToKill=8}
        AFL.questData.Mansion1={enemy="Forest Pirate",questButton=1,ammountToKill=8}
        AFL.questData.Mansion2={enemy="Mythological Pirate",questButton=2,ammountToKill=8}
        AFL.questData.TurtleCenter1={enemy="Jungle Pirate",questButton=1,ammountToKill=8}
        AFL.questData.TurtleCenter2={enemy="Musketeer Pirate",questButton=2,ammountToKill=8}
        AFL.questData.HauntedCastle1={enemy="Reborn Skeleton",questButton=1,ammountToKill=8}
        AFL.questData.HauntedCastle2={enemy="Living Zombie",questButton=2,ammountToKill=8}
        AFL.questData.HauntedCastle3={enemy="Demonic Soul",questButton=1,ammountToKill=8}
        AFL.questData.HauntedCastle4={enemy="Posessed Mummy",questButton=2,ammountToKill=8}
        AFL.questData.Peanut1={enemy="Peanut Scout",questButton=1,ammountToKill=8}
        AFL.questData.Peanut2={enemy="Peanut President",questButton=2,ammountToKill=8}
        AFL.questData.IceCream1={enemy="Ice Cream Chef",questButton=1,ammountToKill=8}
        AFL.questData.IceCream2={enemy="Ice Cream Commander",questButton=2,ammountToKill=8}
        AFL.questData.CakeLand1={enemy="Cookie Crafter",questButton=1,ammountToKill=8}
        AFL.questData.CakeLand2={enemy="Cake Guard",questButton=2,ammountToKill=8}
        AFL.questData.CakeLand3={enemy="Baking Staff",questButton=1,ammountToKill=8}
        AFL.questData.CakeLand4={enemy="Head Baker",questButton=2,ammountToKill=8}
        AFL.questData.Chocolate1={enemy="Cocoa Warrior",questButton=1,ammountToKill=8}
        AFL.questData.Chocolate2={enemy="Chocolate Bar Battler",questButton=2,ammountToKill=8}
        AFL.questData.Chocolate3={enemy="Sweet Thief",questButton=1,ammountToKill=8}
        AFL.questData.Chocolate4={enemy="Candy Rebel",questButton=2,ammountToKill=8}
        AFL.questData.NorthPole1={enemy="Candy Pirate",questButton=1,ammountToKill=8}
        AFL.questData.NorthPole2={enemy="Snow Demon",questButton=2,ammountToKill=8}
        AFL.questData.Tiki1Quest1={enemy="Isle Outlaw",questButton=1,ammountToKill=8}
        AFL.questData.Tiki1Quest2={enemy="Isle Boy",questButton=2,ammountToKill=8}
        AFL.questData.Tiki2Quest1={enemy="Sun-kissed Warrior",questButton=1,ammountToKill=8}
        AFL.questData.Tiki2Quest2={enemy="Isle Champion",questButton=2,ammountToKill=8}
        AFL.questData.Tiki3Quest1={enemy="Serpent Hunter",questButton=1,ammountToKill=8}
        AFL.questData.Tiki3Quest2={enemy="Skull Slayer",questButton=2,ammountToKill=8}
    end
end
afl_loadQuestData()
function afl_jitterClick(x, y)
    for i=1,5 do
        local ox=math.random(-3,3); local oy=math.random(-3,3)
        mousemoveabs(x+ox, y+oy); wait(0.03)
    end
end
function afl_getCharacter()
    local char=LocalPlayer.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if char and hrp then return char,hrp end
end
function afl_setCanCollide(on)
    local char=afl_getCharacter()
    if not char then return end
    for _,c in pairs(char:GetChildren()) do
        if c:IsA("BasePart") then c.CanCollide=not on end
    end
end
function afl_teleportTo(position)
    local char,hrp=afl_getCharacter()
    if not char then return end
    afl_setCanCollide(false)
    local cur=hrp.Position
    local dx=position.X-cur.X; local dy=position.Y-cur.Y; local dz=position.Z-cur.Z
    local dist=math.sqrt(dx*dx+dy*dy+dz*dz)
    local dur=dist/AFL.tweenSpeed
    local startTime=os.clock()
    while true do
        if not char.Parent then break end
        local alpha=math.min((os.clock()-startTime)/dur, 1)
        hrp.Position=Vector3.new(cur.X+dx*alpha, cur.Y+dy*alpha, cur.Z+dz*alpha)
        if alpha>=1 then break end
        wait(0.01)
    end
    if char.Parent then
        hrp.Velocity=Vector3.new(0,0,0)
        hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
    end
    afl_setCanCollide(true)
end
function afl_getLevels()
    if not AFL.autofarmByLevel then return end
    local ok,level=pcall(function() return LocalPlayer.Data.Level.Value end)
    if not ok or not level then return end
    local seaTable=AFL.levelFarmTable[AFL.currentSea]
    if not seaTable then return end
    for _,data in ipairs(seaTable) do
        if level>=data[1] and level<data[2] and AFL.questData[data[3]] then
            AFL.npcToFarm=data[3]; return
        end
    end
    for i=#seaTable,1,-1 do
        if AFL.questData[seaTable[i][3]] then AFL.npcToFarm=seaTable[i][3]; return end
    end
end
function afl_setQuest()
    if not AFL.enableGetQuest then return end
    local quest=AFL.questData and AFL.questData[AFL.npcToFarm]
    if not quest then return end
    wait(0.5); mouse1press(); mouse1release(); wait(1.1)
    local ok,dialogue=pcall(function() return LocalPlayer.PlayerGui.Main.Dialogue end)
    if not ok or not dialogue then return end
    local function getBtnCenter(name)
        local btn=dialogue:FindFirstChild(name)
        if not btn then return nil end
        local p=btn.AbsolutePosition; local s=btn.AbsoluteSize
        if not p or not s then return nil end; return Vector2.new(p.X+s.X/2, p.Y+s.Y/1.25)
    end
    local opt1=getBtnCenter("Option1"); local opt2=getBtnCenter("Option2")
    if quest.questButton==1 and opt1 then
        afl_jitterClick(opt1.X,opt1.Y); mouse1press(); mouse1release()
    elseif opt2 then
        afl_jitterClick(opt2.X,opt2.Y); mouse1press(); mouse1release()
    end
    wait(0.5)
    if opt1 then afl_jitterClick(opt1.X,opt1.Y); mouse1press(); mouse1release() end
end
function afl_getNextNpc()
    local quest=AFL.questData[AFL.npcToFarm]; if not quest then return end
    local _,root=afl_getCharacter(); if not root then return end
    local cur=root.Position; local best,bestD=nil,math.huge
    local ok,enemies=pcall(function() return workspace.Enemies:GetChildren() end)
    if not ok then return end
    for _,enemy in pairs(enemies) do
        if enemy and enemy.Parent then
            local hrp=enemy:FindFirstChild("HumanoidRootPart")
            local hum=enemy:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health>0 and string.find(enemy.Name,quest.enemy,1,true) then
                local dx=hrp.Position.X-cur.X; local dy=hrp.Position.Y-cur.Y; local dz=hrp.Position.Z-cur.Z
                local d=dx*dx+dy*dy+dz*dz
                if d<bestD then bestD=d; best=enemy end
            end
        end
    end
    return best
end
function afl_farmNpcs()
    local kills=0
    afl_getLevels()
    if not AFL.npcToFarm then wait(1); return end
    local function pressNevermind()
        local ok,dialogue=pcall(function() return LocalPlayer.PlayerGui.Main.Dialogue end)
        if not ok or not dialogue then return end
        local btn=dialogue:FindFirstChild("Option3"); if not btn then return end
        local p=btn.AbsolutePosition; local s=btn.AbsoluteSize
        if not p or not s then return end; local v=Vector2.new(p.X+s.X/2, p.Y+s.Y/1.25)
        afl_jitterClick(v.X,v.Y); mouse1press(); mouse1release()
    end
    if AFL.islandPositions[AFL.npcToFarm] and AFL.waitPositions[AFL.npcToFarm] then
        afl_teleportTo(AFL.islandPositions[AFL.npcToFarm])
        wait(0.5); afl_setQuest(); wait(0.5)
        afl_teleportTo(AFL.waitPositions[AFL.npcToFarm]); wait(0.5)
    end
    while S.autoFarmLevel do
        local ok,curLevel=pcall(function() return LocalPlayer.Data.Level.Value end)
        if ok and curLevel and curLevel~=AFL.lastLevel then
            AFL.lastLevel=curLevel; local old=AFL.npcToFarm; afl_getLevels()
            if old~=AFL.npcToFarm and AFL.npcToFarm and AFL.islandPositions[AFL.npcToFarm] then
                kills=0; afl_teleportTo(AFL.islandPositions[AFL.npcToFarm])
                wait(0.5); afl_setQuest(); wait(0.5)
                afl_teleportTo(AFL.waitPositions[AFL.npcToFarm]); wait(0.5)
                continue
            end
        end
        local quest=AFL.questData[AFL.npcToFarm]
        local maxKills=quest and quest.ammountToKill or 8
        if kills>=maxKills then
            kills=0
            afl_teleportTo(AFL.islandPositions[AFL.npcToFarm]); wait(0.5)
            afl_setQuest(); wait(0.5)
            afl_teleportTo(AFL.waitPositions[AFL.npcToFarm]); wait(0.5)
        end
        if AFL.selectedNpc and AFL.questData[AFL.npcToFarm] then
            if not string.find(AFL.selectedNpc.Name,AFL.questData[AFL.npcToFarm].enemy,1,true) then AFL.selectedNpc=nil end
        end
        if not AFL.selectedNpc or not AFL.selectedNpc.Parent then
            local attempts=0
            repeat AFL.selectedNpc=afl_getNextNpc(); attempts=attempts+1; wait(0.05) until AFL.selectedNpc or attempts>15
            if not AFL.selectedNpc then
                if AFL.waitPositions[AFL.npcToFarm] then afl_teleportTo(AFL.waitPositions[AFL.npcToFarm]) end
                wait(0.5); continue
            end
        end
        local hrp=AFL.selectedNpc:FindFirstChild("HumanoidRootPart")
        local hum=AFL.selectedNpc:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health<=0 then AFL.selectedNpc=nil; wait(0.05); continue end
        local fightStart=os.clock()
        while hum and hum.Health>0 and AFL.selectedNpc.Parent and S.autoFarmLevel do
            if not hrp or not hrp.Parent then break end
            if os.clock()-fightStart>50 then pressNevermind(); AFL.selectedNpc=nil; break end
            if not S.remoteMode and AFL.selectedNpc.Head then
                AFL.selectedNpc.Head.Size=Vector3.new(75,75,75); AFL.selectedNpc.Head.CanCollide=false
            end
            local ok2,ppos=pcall(function() return hrp.Position end)
            if ok2 and ppos and ppos.X then
                afl_teleportTo(Vector3.new(ppos.X,ppos.Y+45,ppos.Z))
            end
            if S.remoteMode then
                remoteAttack()
                wait(0.05)
            else
                mouse1press(); mouse1release()
                hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                if AFL.autoV4 then keypress(0x59); keyrelease(0x59) end
                if AFL.autoV3 then keypress(0x54); keyrelease(0x54) end
                wait(0.05)
            end
            hrp=AFL.selectedNpc:FindFirstChild("HumanoidRootPart")
            hum=AFL.selectedNpc:FindFirstChildOfClass("Humanoid")
        end
        if hum and hum.Health<=0 then kills=kills+1; AFL.selectedNpc=nil end
    end
end
task.spawn(function()
    while true do
        if S.autoFarmLevel then pcall(afl_farmNpcs) end
        wait(0.5)
    end
end)
task.spawn(function()
    while true do
        local folder=game.Workspace:FindFirstChild("Enemies")
        if folder then
            for _, model in pairs(folder:GetChildren()) do
                if model:IsA("Model") then
                    local eh=model:FindFirstChild("HumanoidRootPart")
                    local hd=model:FindFirstChild("Head")
                    if eh then eh.CanCollide=false end
                    if hd then hd.CanCollide=false end
                end
            end
        end
        task.wait(0.5)
    end
end)
task.spawn(function()
    while true do
        if S.bigHitbox then
            local folder=game.Workspace:FindFirstChild("Enemies")
            if folder then
                for _, model in pairs(folder:GetChildren()) do
                    if model:IsA("Model") then
                        local head=model:FindFirstChild("Head")
                        if head then head.Size=Vector3.new(200,200,200) end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)
local function doPullLoop(flag, getPoint)
    task.spawn(function()
        while true do
            if flag() then
                local char=LocalPlayer.Character
                local myHrp=char and char:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local pullPoint=getPoint(myHrp)
                    local folder=Workspace:FindFirstChild("Enemies") or game.Workspace:FindFirstChild("Enemies")
                    if folder then
                        for _, model in pairs(folder:GetChildren()) do
                            if model:IsA("Model") then
                                task.spawn(function()
                                    local hrp=model:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        pcall(function()
                                            hrp.CanCollide=false
                                            hrp.Position=pullPoint
                                        end)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(0.001)
        end
    end)
end
doPullLoop(function() return S.pullEnemies end,  function(h) return Vector3.new(h.Position.X, h.Position.Y-10, h.Position.Z) end)
doPullLoop(function() return S.buddhaPull end,   function(h) return Vector3.new(h.Position.X+37, h.Position.Y-3, h.Position.Z) end)
doPullLoop(function() return S.customPull end,   function(h) return Vector3.new(h.Position.X+S.customPullX, h.Position.Y+S.customPullY, h.Position.Z+S.customPullZ) end)
task.spawn(function()
    while true do
        task.wait(0.1)
        if S.autoKen then
            if not LocalPlayer:GetAttribute("KenActive") then
                keypress(0x45); task.wait(0.1); keyrelease(0x45)
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if S.freezePos and S.freezePosition then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Position=S.freezePosition
                hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if S.freezeEnemies then
            local folder=game.Workspace:FindFirstChild("Enemies")
            if folder then
                for _, model in pairs(folder:GetChildren()) do
                    if model:IsA("Model") and not S.frozenEnemies[model] then
                        local hrp=model:FindFirstChild("HumanoidRootPart")
                        if hrp then S.frozenEnemies[model]=hrp.Position end
                    end
                end
            end
            for model, frozenPos in pairs(S.frozenEnemies) do
                if model and model.Parent then
                    local hrp=model:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Position=frozenPos
                        hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                    end
                else S.frozenEnemies[model]=nil end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.5)
        if S.teleportEmber then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in pairs(game.Workspace:GetChildren()) do
                    if obj.Name=="EmberTemplate" and obj:IsA("Model") then
                        local part=obj:FindFirstChild("Part")
                        if part and part:IsA("BasePart") then
                            hrp.Position=Vector3.new(part.Position.X, part.Position.Y+3, part.Position.Z)
                            hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if S.teleportEmber then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Velocity=Vector3.new(0,1,0); hrp.AssemblyLinearVelocity=Vector3.new(0,1,0) end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(2)
        if S.teleportKitsune then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local map=game.Workspace:FindFirstChild("Map")
                if map then
                    local kitsune=map:FindFirstChild("KitsuneIsland")
                    if kitsune then
                        local lampPost=kitsune:FindFirstChild("LampPost")
                        if lampPost then
                            local part=lampPost:FindFirstChild("Part")
                            if part and part:IsA("BasePart") then
                                local startPos=hrp.Position
                                local endPos=Vector3.new(part.Position.X, part.Position.Y+3, part.Position.Z)
                                local duration=2; local startTime=os.clock()
                                while S.teleportKitsune and os.clock()-startTime<duration do
                                    local progress=(os.clock()-startTime)/duration
                                    hrp.Position=Vector3.new(
                                        startPos.X+(endPos.X-startPos.X)*progress,
                                        startPos.Y+(endPos.Y-startPos.Y)*progress,
                                        startPos.Z+(endPos.Z-startPos.Z)*progress
                                    )
                                    task.wait(0.05)
                                end
                                if S.teleportKitsune then
                                    hrp.Position=endPos
                                    hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait()
        if S.teleportKitsune then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0) end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(0.5)
        if not S.autoRaid then
            S.raidTweenActive=false
        else
            local map=game.Workspace:FindFirstChild("Map")
            local raidMap=map and map:FindFirstChild("RaidMap")
            if raidMap then
                local highestIsland=0
                for _, child in pairs(raidMap:GetChildren()) do
                    local num=tonumber(string.sub(child.Name,11))
                    if string.sub(child.Name,1,10)=="RaidIsland" and num and num>highestIsland then highestIsland=num end
                end
                if highestIsland>S.raidLastIslandNum then
                    S.raidLastIslandNum=highestIsland; S.raidTweenActive=true
                    notify("Raid Island "..highestIsland.." - Going there!","redacted",2)
                    task.spawn(function()
                        local island
                        for _=1,20 do island=raidMap:FindFirstChild("RaidIsland"..highestIsland); if island then break end; task.wait(0.2) end
                        if not island then S.raidTweenActive=false; return end
                        local cpos=nil
                        for _=1,10 do
                            local candidates={}
                            local pp=island.PrimaryPart
                            if pp then table.insert(candidates,pp) end
                            for _,p in pairs(island:GetDescendants()) do if p:IsA("BasePart") then table.insert(candidates,p) end end
                            for _,p in pairs(candidates) do
                                local ok,pos=pcall(function() return p.Position end)
                                if ok and pos and pos.X then cpos=pos; break end
                            end
                            if cpos then break end
                            task.wait(0.3)
                        end
                        if not cpos then S.raidTweenActive=false; return end
                        local myHrp
                        for _=1,30 do
                            local c=LocalPlayer.Character; myHrp=c and c:FindFirstChild("HumanoidRootPart")
                            if myHrp then break end; task.wait(0.2)
                        end
                        if not myHrp then S.raidTweenActive=false; return end
                        local tx=cpos.X; local ty=cpos.Y+100; local tz=cpos.Z
                        local startX=myHrp.Position.X; local startY=myHrp.Position.Y; local startZ=myHrp.Position.Z
                        local dx=tx-startX; local dy=ty-startY; local dz=tz-startZ
                        local dist=math.sqrt(dx*dx+dy*dy+dz*dz)
                        local duration=dist/200; local t0=os.clock(); local velTick=os.clock()
                        while S.autoRaid and S.raidTweenActive do
                            local c2=LocalPlayer.Character
                            local hrp2=c2 and c2:FindFirstChild("HumanoidRootPart")
                            if not hrp2 then task.wait(0.1); continue end
                            local alpha=math.min((os.clock()-t0)/duration,1)
                            hrp2.Position=Vector3.new(startX+dx*alpha, startY+dy*alpha, startZ+dz*alpha)
                            if os.clock()-velTick>=0.5 then
                                hrp2.Velocity=Vector3.new(0,0,0); hrp2.AssemblyLinearVelocity=Vector3.new(0,0,0)
                                velTick=os.clock()
                            end
                            if alpha>=1 then notify("Arrived!","redacted",2); break end
                            task.wait(0.01)
                        end
                        S.raidTweenActive=false
                    end)
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        if S.autoRaid and not S.raidTweenActive then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then farmAttack(hrp, function() return S.autoRaid and not S.raidTweenActive end, nil) end
            task.wait(0.1)
        else task.wait(0.1) end
    end
end)
task.spawn(function()
    while true do
        if S.voidPull then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    hrp.Position=Vector3.new(hrp.Position.X, 100000, hrp.Position.Z)
                    hrp.Velocity=Vector3.new(0,0,0)
                    hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                end)
            end
        end
        task.wait()
    end
end)
task.spawn(function()
    while true do
        if S.skyPull then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    hrp.Position=Vector3.new(hrp.Position.X, 1000, hrp.Position.Z)
                    hrp.Velocity=Vector3.new(0,0,0)
                    hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                end)
            end
        end
        task.wait()
    end
end)
function isPvpTargetDead(char)
    if not char or not char.Parent then return true end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return true end
    return false
end
task.spawn(function()
    local pvpTarget=nil
    while true do
        if S.pvpFarmLoop then
            local char=LocalPlayer.Character
            local myHrp=char and char:FindFirstChild("HumanoidRootPart")
            if myHrp then
                if isPvpTargetDead(pvpTarget) then
                    pvpTarget=nil
                    local nearest, bestDist=nil, math.huge
                    local myName=LocalPlayer.Name
                    local myTeamName=(LocalPlayer.Team and LocalPlayer.Team.Name) or ""
                    local charsFolder=game.Workspace:FindFirstChild("Characters")
                    if charsFolder then
                        for _, c in pairs(charsFolder:GetChildren()) do
                            if c:IsA("Model") and c.Name~=myName then
                                local root=c:FindFirstChild("HumanoidRootPart")
                                local hum=c:FindFirstChildOfClass("Humanoid")
                                if root and hum and hum.Health>0 then
                                    local skip=false
                                    if myTeamName=="Marines" then
                                        local tp=Players:FindFirstChild(c.Name)
                                        if tp and tp.Team and tp.Team.Name=="Marines" then skip=true end
                                    end
                                    if not skip then
                                        local dx=root.Position.X-myHrp.Position.X
                                        local dy=root.Position.Y-myHrp.Position.Y
                                        local dz=root.Position.Z-myHrp.Position.Z
                                        local d=math.sqrt(dx*dx+dy*dy+dz*dz)
                                        if d<bestDist then bestDist=d; nearest=c end
                                    end
                                end
                            end
                        end
                    end
                    if nearest then pvpTarget=nearest end
                end
                if pvpTarget and not isPvpTargetDead(pvpTarget) then
                    local enemyRoot=pvpTarget:FindFirstChild("HumanoidRootPart")
                    if enemyRoot then
                        task.spawn(function()
                            while S.pvpFarmLoop and not isPvpTargetDead(pvpTarget) do
                                local eh=pvpTarget:FindFirstChild("HumanoidRootPart")
                                local hd=pvpTarget:FindFirstChild("Head")
                                if eh then eh.CanCollide=false end
                                if hd then hd.CanCollide=false end
                                task.wait()
                            end
                        end)
                        local startX=myHrp.Position.X; local startY=myHrp.Position.Y; local startZ=myHrp.Position.Z
                        local tx=enemyRoot.Position.X+20; local ty=enemyRoot.Position.Y; local tz=enemyRoot.Position.Z
                        local dx=tx-startX; local dy=ty-startY; local dz=tz-startZ
                        local duration=math.sqrt(dx*dx+dy*dy+dz*dz)/320; local t0=os.clock()
                        while S.pvpFarmLoop and not isPvpTargetDead(pvpTarget) do
                            local alpha=math.min((os.clock()-t0)/duration,1)
                            myHrp.Position=Vector3.new(startX+dx*alpha, startY+dy*alpha, startZ+dz*alpha)
                            if alpha>=1 then break end; task.wait(0.01)
                        end
                        local lastClick=0
                        local attackStart=os.clock()
                        while os.clock()-attackStart<2 and S.pvpFarmLoop and not isPvpTargetDead(pvpTarget) do
                            local tr=pvpTarget:FindFirstChild("HumanoidRootPart")
                            if tr then
                                myHrp.Position=Vector3.new(tr.Position.X+20, tr.Position.Y, tr.Position.Z)
                                myHrp.Velocity=Vector3.new(0,0,0); myHrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                            end
                            local now=os.clock()
                            if now-lastClick>=0.06 then mouse1click(); lastClick=now end
                            task.wait()
                        end
                        if S.pvpFarmLoop then
                            local savedX=myHrp.Position.X; local savedZ=myHrp.Position.Z
                            local upStart=os.clock()
                            while os.clock()-upStart<5 and S.pvpFarmLoop and not isPvpTargetDead(pvpTarget) do
                                myHrp.Position=Vector3.new(savedX,10000000,savedZ)
                                myHrp.Velocity=Vector3.new(0,0,0); myHrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                                task.wait(0.1)
                            end
                            local dHrp=pvpTarget:FindFirstChild("HumanoidRootPart")
                            local groundY=dHrp and dHrp.Position and dHrp.Position.Y or 0
                            myHrp.Position=Vector3.new(savedX,groundY,savedZ)
                            myHrp.Velocity=Vector3.new(0,0,0); myHrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                            task.wait(0.2)
                            if S.pvpFarmLoop and not isPvpTargetDead(pvpTarget) then
                                local a2=os.clock()
                                while os.clock()-a2<0.5 and S.pvpFarmLoop and not isPvpTargetDead(pvpTarget) do
                                    local tr2=pvpTarget:FindFirstChild("HumanoidRootPart")
                                    if tr2 then
                                        myHrp.Position=Vector3.new(tr2.Position.X+20,tr2.Position.Y,tr2.Position.Z)
                                        myHrp.Velocity=Vector3.new(0,0,0); myHrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                                    end
                                    local now=os.clock()
                                    if now-lastClick>=0.06 then mouse1click(); lastClick=now end
                                    task.wait()
                                end
                            end
                        end
                    end
                else task.wait(0.5) end
            else task.wait(0.5) end
        else pvpTarget=nil; task.wait(0.5) end
    end
end)
do
    aura = aura or {
        enabled       = false,
        maxDist       = 100,
        minDist       = 1,
        sessionId     = "32501259",
        targetCount   = 0,
        firstName     = "None",
        regAtk        = nil,
        regHit        = nil,
    }
    local function aura_ensureRemotes()
        if aura.regAtk and aura.regHit then return true end
        local net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
        if net then net = net:FindFirstChild("Net") end
        if not net then return false end
        aura.regAtk = net:FindFirstChild("RE/RegisterAttack")
        aura.regHit = net:FindFirstChild("RE/RegisterHit")
        return aura.regAtk ~= nil and aura.regHit ~= nil
    end
    local function aura_getTargetPart(enemy)
        if not enemy or not enemy.Parent then return nil end
        local p = enemy:FindFirstChild("LeftLowerLeg")
        if p and p:IsA("BasePart") then return p end
        p = enemy:FindFirstChild("Head")
        if p and p:IsA("BasePart") then return p end
        p = enemy:FindFirstChild("HumanoidRootPart")
        if p and p:IsA("BasePart") then return p end
        for _, c in ipairs(enemy:GetChildren()) do
            if c:IsA("BasePart") then return c end
        end
        return nil
    end
    local function aura_getEnemies()
        local char = LocalPlayer.Character
        if not char then return {} end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return {} end
        local myPos = hrp.Position
        local folder = workspace:FindFirstChild("Enemies")
        if not folder then return {} end
        local results = {}
        for _, enemy in ipairs(folder:GetChildren()) do
            if enemy and enemy.Parent then
                local hum = enemy:FindFirstChild("Humanoid")
                if hum and hum.Health and hum.Health > 0 then
                    local part = aura_getTargetPart(enemy)
                    if part and part.Parent then
                        local ok, pos = pcall(function() return part.Position end)
                        if ok and pos then
                            local d = (pos - myPos).Magnitude
                            if d <= aura.maxDist and d >= aura.minDist then
                                table.insert(results, {enemy=enemy, part=part, dist=d})
                            end
                        end
                    end
                end
            end
        end
        return results
    end
    local function aura_attack(list)
        if #list == 0 then return end
        local hitTable = {}
        local primary = nil
        for _, entry in ipairs(list) do
            if entry.enemy and entry.enemy.Parent and entry.part and entry.part.Parent then
                table.insert(hitTable, {entry.enemy, entry.part})
                if not primary then primary = entry.part end
            end
        end
        if #hitTable == 0 then return end
        pcall(function() aura.regAtk:FireServer(0.5) end)
        task.wait()
        pcall(function() aura.regHit:FireServer(primary, hitTable, nil, aura.sessionId) end)
    end
    task.spawn(function()
        while true do
            if false and aura.enabled then
                if aura_ensureRemotes() then
                    local enemies = aura_getEnemies()
                    aura.targetCount = #enemies
                    if aura.targetCount > 0 then
                        table.sort(enemies, function(a,b) return a.dist < b.dist end)
                        aura.firstName = enemies[1].enemy.Name or "Unknown"
                    else
                        aura.firstName = "None"
                    end
                    aura_attack(enemies)
                end
                task.wait(0.05)
            else
                task.wait(0.1)
            end
        end
    end)
end
do
    local sessionId = "325bb15e"
    local minDist   = 1
    local regAtk, regHit = nil, nil
    local function pvp_ensureRemotes()
        if regAtk and regHit then return true end
        local net = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
        if net then net = net:FindFirstChild("Net") end
        if not net then return false end
        regAtk = net:FindFirstChild("RE/RegisterAttack")
        regHit = net:FindFirstChild("RE/RegisterHit")
        return regAtk ~= nil and regHit ~= nil
    end
    local function pvp_getTarget()
        local char = LocalPlayer.Character
        if not char then return nil, nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil, nil end
        local myPos = hrp.Position
        local closest, closestDist = nil, _pvpAuraMaxDist + 1
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local c = player.Character
            if c then
                local root = c:FindFirstChild("HumanoidRootPart")
                if root then
                    local d = (root.Position - myPos).Magnitude
                    if d < closestDist and d >= minDist then
                        closestDist = d; closest = player
                    end
                end
            end
        end
        if not closest then return nil, nil end
        local tc = closest.Character
        if not tc then return nil, nil end
        local partName = _pvpAuraAltPart and "ModelHitbox" or "Head"
        local part = tc:FindFirstChild(partName) or tc:FindFirstChild("Head")
        if not part or part:IsDescendantOf(LocalPlayer.Character) then return nil, nil end
        return closest, part
    end
    local function pvp_attack(part)
        if not part then return end
        pcall(function() regAtk:FireServer(0.5) end)
        task.wait()
        pcall(function() regHit:FireServer(part, {}, nil, sessionId) end)
    end
    task.spawn(function()
        while true do
            if _pvpAuraEnabled then
                if pvp_ensureRemotes() then
                    local player, part = pvp_getTarget()
                    pvp_attack(part)
                end
                task.wait(0.2)
            else
                task.wait(0.25)
            end
        end
    end)
end
pcall(function()
    if type(islandList) == "table" and (not islandNames or #islandNames == 0) then
        islandNames = {}
        for _, isle in pairs(islandList) do table.insert(islandNames, isle.name) end
    end
end)
pcall(function()
    if type(dangerLevels) == "table" and (not dangerLevelNames or #dangerLevelNames == 0) then
        dangerLevelNames = {}
        for _, d in pairs(dangerLevels) do table.insert(dangerLevelNames, d.name) end
    end
end)
-- ============================================================
-- Haunted extras (myth4c / laced.club) — Fruit ESP + AutoFish stay ours
-- ============================================================
local ExtraDraw = { flower={}, chest={}, boat={}, mirage={}, chamLast=0 }
local BoatSeats = { names={}, map={} }
local MATERIAL_MAP = {
    ["Leather + Scrap Metal"] = {"Pirate","Brute","Gladiator","Mercenary","Swan Pirate","Marine Captain","Jungle Pirate","Forest Pirate"},
    ["Angel Wings"] = {"God's Guard","Shanda","Royal Squad","Royal Soldier"},
    ["Magma Ore"] = {"Military Soldier","Military Spy","Magma Ninja","Lava Pirate"},
    ["Fish Tail"] = {"Fishman Warrior","Fishman Commando","Fishman Raider","Fishman Captain"},
    ["Radioactive Material"] = {"Factory Staff"},
    ["Ectoplasm"] = {"Ship Deckhand","Ship Engineer","Ship Steward","Ship Officer","Cursed Captain"},
    ["Mystic Droplet"] = {"Sea Soldier","Water Fighter"},
    ["Vampire Fang"] = {"Vampire"},
    ["Demonic Wisp"] = {"Demonic Soul"},
    ["Conjured Cocoa"] = {"Cocoa Warrior","Chocolate Bar Battler","Sweet Thief","Candy Rebel"},
    ["Dragon Scale"] = {"Dragon Crew Warrior","Dragon Crew Archer"},
    ["Gunpowder"] = {"Pistol Billionaire"},
    ["Mini Tusk"] = {"Mythological Pirate"},
}
local MATERIAL_NAMES = {
    "Leather + Scrap Metal","Angel Wings","Magma Ore","Fish Tail","Radioactive Material",
    "Ectoplasm","Mystic Droplet","Vampire Fang","Demonic Wisp","Conjured Cocoa",
    "Dragon Scale","Gunpowder","Mini Tusk",
}
local BOSS_NAMES_SEA1 = {
    "The Gorilla King","Bobby","The Saw","Yeti","Mob Leader","Vice Admiral","Saber Expert",
    "Warden","Chief Warden","Swan","Magma Admiral","Fishman Lord","Wysper","Thunder God",
    "Cyborg","Ice Admiral","Greybeard",
}
local BOSS_NAMES_SEA2 = {
    "Diamond","Jeremy","Orbitus","Don Swan","Smoke Admiral","Awakened Ice Admiral",
    "Tide Keeper","Darkbeard","Cursed Captain","Order","Stone",
}
local BOSS_NAMES_SEA3 = {
    "Hydra Leader","Kilo Admiral","Captain Elephant","Beautiful Pirate","Cake Queen",
    "Dough King","Longma","Soul Reaper","rip_indra True Form","Tyrant of the Skies",
}
local BOSS_NAMES = {}
for _,n in ipairs(BOSS_NAMES_SEA1) do BOSS_NAMES[#BOSS_NAMES+1]=n end
for _,n in ipairs(BOSS_NAMES_SEA2) do BOSS_NAMES[#BOSS_NAMES+1]=n end
for _,n in ipairs(BOSS_NAMES_SEA3) do BOSS_NAMES[#BOSS_NAMES+1]=n end
local function bossesForCurrentSea()
    if isSea1() then return BOSS_NAMES_SEA1 end
    if isSea2() then return BOSS_NAMES_SEA2 end
    if isSea3() then return BOSS_NAMES_SEA3 end
    return BOSS_NAMES
end
local SEA_EVENT_NAMES = {"Shark","Terrorshark","Piranha","Fish Crew Member","Haunted Crew Member"}
local GLITCH_KEYS = {
    {id="sanguine",    flag="sanguineZ",    label="Sanguine Z"},
    {id="dragonTalon", flag="dragonTalonZ", label="Dragon Talon Z"},
    {id="yama",        flag="yamaZ",        label="Yama Z"},
    {id="tushita",     flag="tushitaX",     label="Tushita X"},
    {id="foxLamp",     flag="foxLampX",     label="Fox Lamp X"},
    {id="soulGuitar",  flag="soulGuitarM1", label="Soul Guitar M1"},
    {id="diamond",     flag="diamondM1",    label="Diamond M1"},
    {id="flame",       flag="flameF",       label="Flame F"},
}

local function extraClearGroup(group)
    for key, entry in pairs(group) do
        pcall(function() if entry.label then entry.label:Remove() end end)
        if entry.lines then
            for _, l in pairs(entry.lines) do pcall(function() l:Remove() end) end
        end
        group[key] = nil
    end
end
function extraClearAllESP()
    extraClearGroup(ExtraDraw.flower)
    extraClearGroup(ExtraDraw.chest)
    extraClearGroup(ExtraDraw.boat)
    extraClearGroup(ExtraDraw.mirage)
    pcall(clearChamBoxes)
end

local function extraMakeLabel(color)
    local t = Drawing.new("Text")
    t.Size = 14
    t.Center = true
    t.Outline = true
    t.Color = color
    t.Visible = false
    t.ZIndex = 10
    pcall(function() t.Font = Drawing.Fonts.Monospace end)
    return t
end
local function extraMakeLines(n, color)
    local lines = {}
    for i = 1, n do
        local l = Drawing.new("Line")
        l.Color = color
        l.Thickness = 1.5
        l.Visible = false
        l.ZIndex = 9
        lines[i] = l
    end
    return lines
end
local function extraToScreen(pos)
    local cam = Workspace.CurrentCamera
    if not cam or not pos then return nil, false end
    local ok, v, vis = pcall(function()
        local vv, on = cam:WorldToViewportPoint(pos)
        return vv, on
    end)
    if not ok or not v then return nil, false end
    return Vector2.new(v.X, v.Y), vis and v.Z > 0
end
local function extraHideLines(lines)
    if not lines then return end
    for _, l in pairs(lines) do l.Visible = false end
end
local function extraDrawAABB(lines, part)
    if not lines or not part or not part.Parent then extraHideLines(lines); return end
    local cam = Workspace.CurrentCamera
    if not cam then extraHideLines(lines); return end
    local cf, s = part.CFrame, part.Size
    local hx, hy, hz = s.X/2, s.Y/2, s.Z/2
    local corners = {
        cf * Vector3.new(-hx,-hy,-hz), cf * Vector3.new(hx,-hy,-hz),
        cf * Vector3.new(hx,-hy, hz), cf * Vector3.new(-hx,-hy, hz),
        cf * Vector3.new(-hx, hy,-hz), cf * Vector3.new(hx, hy,-hz),
        cf * Vector3.new(hx, hy, hz), cf * Vector3.new(-hx, hy, hz),
    }
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local any = false
    for i = 1, 8 do
        local sp, vis = extraToScreen(corners[i])
        if vis and sp then
            any = true
            if sp.X < minX then minX = sp.X end
            if sp.Y < minY then minY = sp.Y end
            if sp.X > maxX then maxX = sp.X end
            if sp.Y > maxY then maxY = sp.Y end
        end
    end
    if not any or #lines < 4 then extraHideLines(lines); return end
    local pts = {
        Vector2.new(minX, minY), Vector2.new(maxX, minY),
        Vector2.new(maxX, maxY), Vector2.new(minX, maxY),
    }
    for i = 1, 4 do
        local a, b = pts[i], pts[i == 4 and 1 or i + 1]
        lines[i].From = a
        lines[i].To = b
        lines[i].Visible = true
    end
end
local function extraGetPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("HumanoidRootPart")
        or obj:FindFirstChild("RootPart")
        or obj:FindFirstChild("Part")
        or obj:FindFirstChildWhichIsA("BasePart")
end

local enhancedComm = nil
local function getCommF()
    if enhancedComm then
        local okParent, parent = pcall(function() return enhancedComm.Parent end)
        if okParent and parent then return enhancedComm end
        enhancedComm = nil
    end
    local storage = ReplicatedStorage
    local remotes = storage and storage:FindFirstChild("Remotes")
    enhancedComm = remotes and remotes:FindFirstChild("CommF_") or nil
    if not enhancedComm and storage then
        local okDesc, desc = pcall(function() return storage:GetDescendants() end)
        if okDesc and desc then
            for _, object in pairs(desc) do
                local okName, name = pcall(function() return object.Name end)
                if okName and name == "CommF_" then enhancedComm = object; break end
            end
        end
    end
    return enhancedComm
end
local function getCommE()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CommE")
end
local function invokeCommF(...)
    local remote = getCommF()
    if not remote then return false end
    local args = {...}
    local ok, result = pcall(function()
        return remote:InvokeServer(unpack(args))
    end)
    if not ok then
        enhancedComm = nil
        warn("[Automation] CommF_ failed: " .. tostring(result))
        return false
    end
    return true
end
local function commF(...)
    invokeCommF(...)
end
local function tapKey(vk)
    pcall(function()
        if keypress then
            keypress(vk)
            task.wait(0.03)
            keyrelease(vk)
        elseif keyclick then
            keyclick(vk)
        end
    end)
end
local function toolEquipped(name)
    local char = LocalPlayer.Character
    if not char then return false end
    local t = char:FindFirstChildOfClass("Tool")
    if not t then return false end
    if t.Name == name then return true end
    return string.find(t.Name, name, 1, true) ~= nil
end
local function findTool(name)
    local char = LocalPlayer.Character
    if char then
        local t = char:FindFirstChild(name)
        if t then return t end
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") and string.find(c.Name, name, 1, true) then return c end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local t = bp:FindFirstChild(name)
        if t then return t end
        for _, c in ipairs(bp:GetChildren()) do
            if c:IsA("Tool") and string.find(c.Name, name, 1, true) then return c end
        end
    end
    return nil
end
local function getMyHrp()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
-- Velocity boost (ported 1:1 from hauntedscripts blox fruits — Matcha)
function runVelocityBoost(settings, enabledFn, horizontalOnly, lockedDirection)
    if not settings then return end
    task.wait(settings.delay)
    if enabledFn and not enabledFn() then return end

    local char = LocalPlayer and LocalPlayer.Character or nil
    local hrp = char and char:FindFirstChild("HumanoidRootPart") or nil
    if not hrp then return end

    local direction = lockedDirection
    if not direction then
        pcall(function()
            local velocity = hrp.AssemblyLinearVelocity
            if not velocity then return end
            local dx, dy, dz = velocity.X, velocity.Y, velocity.Z
            if horizontalOnly then dy = 0 end
            local magnitude = math.sqrt(dx * dx + dy * dy + dz * dz)
            if magnitude > 0.1 then
                direction = Vector3.new(dx / magnitude, dy / magnitude, dz / magnitude)
            end
        end)
    end
    if not direction then return end

    local endTime = os.clock() + (settings.duration or 0.3)
    while os.clock() < endTime and (not enabledFn or enabledFn()) do
        local currentChar = LocalPlayer and LocalPlayer.Character or nil
        local currentHrp = currentChar and currentChar:FindFirstChild("HumanoidRootPart") or nil
        if not currentHrp then return end
        pcall(function()
            currentHrp.AssemblyLinearVelocity = Vector3.new(
                direction.X * settings.speed,
                horizontalOnly and 0 or direction.Y * settings.speed,
                direction.Z * settings.speed
            )
        end)
        task.wait()
    end
end

local function charHasTool(name)
    local char = LocalPlayer and LocalPlayer.Character
    return char and char:FindFirstChild(name) ~= nil
end

local function mouse1Down()
    local d = false
    pcall(function()
        if ismouse1pressed then d = ismouse1pressed()
        else d = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    end)
    return d
end

-- Sanguine Z: only when SanguineArtZFire appears on HRP (not backpack)
task.spawn(function()
    local wasZFire = false
    local boosting = false
    while not _G.FE_Unloaded do
        local char = LocalPlayer and LocalPlayer.Character or nil
        local hrp = char and char:FindFirstChild("HumanoidRootPart") or nil
        local zFire = hrp and hrp:FindFirstChild("SanguineArtZFire") ~= nil or false
        if S.sanguineZ and zFire and not wasZFire and not boosting then
            boosting = true
            task.spawn(function()
                runVelocityBoost(S.glitchSettings.sanguine, function() return S.sanguineZ end)
                boosting = false
            end)
        end
        wasZFire = zFire
        task.wait()
    end
end)

-- Dragon Talon Z — tool must be IN HANDS (character child)
task.spawn(function()
    local holdingZ = false
    local boosting = false
    while not _G.FE_Unloaded do
        local pressed = false
        pcall(function() pressed = iskeypressed(0x5A) end)
        if S.dragonTalonZ and pressed and not holdingZ then
            holdingZ = true
            if not boosting then
                boosting = true
                task.spawn(function()
                    if charHasTool("Dragon Talon") then
                        runVelocityBoost(S.glitchSettings.dragonTalon, function() return S.dragonTalonZ end)
                    end
                    boosting = false
                end)
            end
        elseif not pressed then
            holdingZ = false
        end
        task.wait()
    end
end)

-- Yama Z
task.spawn(function()
    local holdingZ = false
    local boosting = false
    while not _G.FE_Unloaded do
        local pressed = false
        pcall(function() pressed = iskeypressed(0x5A) end)
        if S.yamaZ and pressed and not holdingZ then
            holdingZ = true
            if not boosting then
                boosting = true
                task.spawn(function()
                    if charHasTool("Yama") then
                        runVelocityBoost(S.glitchSettings.yama, function() return S.yamaZ end)
                    end
                    boosting = false
                end)
            end
        elseif not pressed then
            holdingZ = false
        end
        task.wait()
    end
end)

-- Tushita X
task.spawn(function()
    local holdingX = false
    local boosting = false
    while not _G.FE_Unloaded do
        local pressed = false
        pcall(function() pressed = iskeypressed(0x58) end)
        if S.tushitaX and pressed and not holdingX then
            holdingX = true
            if not boosting then
                boosting = true
                task.spawn(function()
                    if charHasTool("Tushita") then
                        runVelocityBoost(S.glitchSettings.tushita, function() return S.tushitaX end)
                    end
                    boosting = false
                end)
            end
        elseif not pressed then
            holdingX = false
        end
        task.wait()
    end
end)

-- Fox Lamp X
task.spawn(function()
    local holdingX = false
    local boosting = false
    while not _G.FE_Unloaded do
        local pressed = false
        pcall(function() pressed = iskeypressed(0x58) end)
        if S.foxLampX and pressed and not holdingX then
            holdingX = true
            if not boosting then
                boosting = true
                task.spawn(function()
                    if charHasTool("Fox Lamp") then
                        runVelocityBoost(S.glitchSettings.foxLamp, function() return S.foxLampX end)
                    end
                    boosting = false
                end)
            end
        elseif not pressed then
            holdingX = false
        end
        task.wait()
    end
end)

-- Soul Guitar M1 (Q + M1 within 0.5s) — tool in hands only
task.spawn(function()
    local wasQPressed = false
    local wasM1Pressed = false
    local lastQPress = nil
    local lastM1Press = nil
    local boosting = false
    while not _G.FE_Unloaded do
        local qPressed = false
        pcall(function() qPressed = iskeypressed(0x51) end)
        local m1Pressed = mouse1Down()
        local now = os.clock()

        if S.soulGuitarM1 then
            if qPressed and not wasQPressed then lastQPress = now end
            if m1Pressed and not wasM1Pressed then lastM1Press = now end

            if not boosting and lastQPress and lastM1Press and math.abs(lastQPress - lastM1Press) <= 0.5 then
                lastQPress = nil
                lastM1Press = nil
                boosting = true
                task.spawn(function()
                    local char = LocalPlayer and LocalPlayer.Character or nil
                    local hasGuitar = char and (
                        char:FindFirstChild("Skull Guitar") or
                        char:FindFirstChild("Soul Guitar")
                    )
                    if hasGuitar then
                        runVelocityBoost(S.glitchSettings.soulGuitar, function() return S.soulGuitarM1 end, true)
                    end
                    boosting = false
                end)
            end
        else
            lastQPress = nil
            lastM1Press = nil
        end

        wasQPressed = qPressed
        wasM1Pressed = m1Pressed
        task.wait()
    end
end)

-- Diamond M1 release — Diamond-Diamond in hands only
task.spawn(function()
    local wasM1Pressed = false
    local boosting = false
    while not _G.FE_Unloaded do
        local m1Pressed = mouse1Down()
        if S.diamondM1 and not m1Pressed and wasM1Pressed and not boosting then
            boosting = true
            task.spawn(function()
                if charHasTool("Diamond-Diamond") then
                    runVelocityBoost(S.glitchSettings.diamond, function() return S.diamondM1 end)
                end
                boosting = false
            end)
        end
        wasM1Pressed = m1Pressed
        task.wait()
    end
end)

-- Flame F
task.spawn(function()
    local holdingF = false
    local boosting = false
    while not _G.FE_Unloaded do
        local pressed = false
        pcall(function() pressed = iskeypressed(0x46) end)
        if S.flameF and pressed and not holdingF then
            holdingF = true
            if not boosting then
                boosting = true
                task.spawn(function()
                    if charHasTool("Flame-Flame") then
                        runVelocityBoost(S.glitchSettings.flame, function() return S.flameF end)
                    end
                    boosting = false
                end)
            end
        elseif not pressed then
            holdingF = false
        end
        task.wait()
    end
end)

-- R to X (only with Portal-Portal in hands)
task.spawn(function()
    local holdingR = false
    while not _G.FE_Unloaded do
        local rPressed = false
        pcall(function() rPressed = iskeypressed(0x52) end)
        if S.rToX and rPressed and not holdingR then
            holdingR = true
            if charHasTool("Portal-Portal") then
                task.spawn(function()
                    pcall(function()
                        setrobloxinput(true)
                        keyrelease(0x58)
                        task.wait(0.02)
                        keypress(0x58)
                        task.wait(0.08)
                        keyrelease(0x58)
                    end)
                end)
            end
        elseif not rPressed then
            holdingR = false
        end
        task.wait()
    end
end)

-- R to X then Z (Portal-Portal in hands)
task.spawn(function()
    local holdingR = false
    while not _G.FE_Unloaded do
        local rPressed = false
        pcall(function() rPressed = iskeypressed(0x52) end)
        if S.rToXThenZ and rPressed and not holdingR then
            holdingR = true
            if charHasTool("Portal-Portal") then
                task.spawn(function()
                    pcall(function()
                        setrobloxinput(true)
                        keyrelease(0x58)
                        task.wait(0.02)
                        keypress(0x58)
                        task.wait(0.08)
                        keyrelease(0x58)
                        task.wait(0.025)
                        keyrelease(0x5A)
                        task.wait(0.02)
                        keypress(0x5A)
                        task.wait(0.08)
                        keyrelease(0x5A)
                    end)
                end)
            end
        elseif not rPressed then
            holdingR = false
        end
        task.wait()
    end
end)

-- Flame R to C (Flame-Flame in hands)
task.spawn(function()
    local holdingR = false
    while not _G.FE_Unloaded do
        local rPressed = false
        pcall(function() rPressed = iskeypressed(0x52) end)
        if S.flameRToC and rPressed and not holdingR then
            holdingR = true
            if charHasTool("Flame-Flame") then
                task.spawn(function()
                    pcall(function()
                        setrobloxinput(true)
                        keyrelease(0x43)
                        task.wait(0.02)
                        keypress(0x43)
                        task.wait(0.08)
                        keyrelease(0x43)
                    end)
                end)
            end
        elseif not rPressed then
            holdingR = false
        end
        task.wait()
    end
end)



-- ============================================================
-- ESP from hauntedscripts blox fruits (chest/boat/flower/berry/mirage)
-- Fruit ESP remains our Features.esp implementation
-- ============================================================
function clearChestEspLabels()
    for _,entry in pairs(S.chestEspLabels) do
        if entry and entry.label then entry.label.Visible=false end
    end
    S.chestEspLabels={}
end

function clearBerryEspLabels()
    for _,entry in pairs(S.berryEspLabels) do
        if entry and entry.label then entry.label.Visible=false end
    end
    S.berryEspLabels={}
end

function clearBoatEsp()
    for _,entry in pairs(S.boatEspEntries) do
        if entry and entry.label then entry.label.Visible=false end
        if entry and entry.lines then
            for _,line in pairs(entry.lines) do line.Visible=false end
        end
    end
    S.boatEspEntries={}
end

function clearFlowerEsp()
    for _,entry in pairs(S.flowerEspEntries) do
        if entry and entry.label then entry.label.Visible=false end
        if entry and entry.lines then
            for _,line in pairs(entry.lines) do line.Visible=false end
        end
    end
    S.flowerEspEntries={}
end

function clearMirageEsp()
    if S.mirageEspLabel then S.mirageEspLabel.Visible=false end
end

function getSafeFruitPosition(candidate)
    if not candidate then return nil end
    local okParent, parent=pcall(function() return candidate.Parent end)
    if not okParent or not parent then return nil end
    local okPos, pos=pcall(function() return candidate.Position end)
    if okPos and pos and pos.X and pos.Y and pos.Z then return pos end
    return nil
end

function getFruitInstanceKey(part)
    local okAddress, address=pcall(function() return part.Address end)
    if okAddress and address and address~=0 then return "addr:"..tostring(address) end
    local pos=getSafeFruitPosition(part)
    if pos then
        return tostring(part)..":"..tostring(pos.X)..":"..tostring(pos.Y)..":"..tostring(pos.Z)
    end
    return tostring(part)
end

local function trackedInstanceKey(instance)
    local okAddress, address=pcall(function() return instance and instance.Address end)
    if okAddress and address and address~=0 then return "addr:"..tostring(address) end
    return tostring(instance)
end

local function trackedSetChanged(snapshotName,current)
    S._espTrackSnapshots = S._espTrackSnapshots or {}
    local prev=S._espTrackSnapshots[snapshotName]
    local changed=false
    if type(prev)~="table" or #prev~=#current then
        changed=true
    else
        for i=1,#current do
            if prev[i]~=current[i] then changed=true; break end
        end
    end
    S._espTrackSnapshots[snapshotName]=current
    return changed
end

local function trackedFolderChanged(snapshotName,folder)
    local keys={}
    if folder then
        local ok,children=pcall(function() return folder:GetChildren() end)
        if ok and children then
            for _,child in pairs(children) do
                keys[#keys+1]=trackedInstanceKey(child)
            end
            table.sort(keys)
        end
    end
    return trackedSetChanged(snapshotName,keys)
end

local function trackedFlowersChanged()
    local keys={}
    local ok,children=pcall(function() return Workspace:GetChildren() end)
    if ok and children then
        for _,obj in pairs(children) do
            if obj.Name=="Flower1" or obj.Name=="Flower2" then
                keys[#keys+1]=trackedInstanceKey(obj)
            end
        end
    end
    local map=Workspace:FindFirstChild("Map")
    if map then
        for _,obj in pairs(map:GetDescendants()) do
            if obj.Name=="Flower1" or obj.Name=="Flower2" then
                keys[#keys+1]=trackedInstanceKey(obj)
            end
        end
    end
    table.sort(keys)
    return trackedSetChanged("flowers",keys)
end

function buildChestEspLabels()
    for _,entry in pairs(S.chestEspLabelCache) do
        if entry and entry.label then entry.label.Visible=false end
    end
    S.chestEspLabels={}
    local chestModels=Workspace:FindFirstChild("ChestModels")
    if not chestModels then return end
    local okChildren,children=pcall(function() return chestModels:GetChildren() end)
    if not okChildren or not children then return end
    for _,chest in pairs(children) do
        local part=chest and (chest:FindFirstChild("RootPart") or chest:FindFirstChildOfClass("BasePart")) or nil
        local okPos,pos=pcall(function() return part and part.Position end)
        if okPos and pos and pos.X and pos.Y and pos.Z then
            local key=getFruitInstanceKey(part)
            local okName,chestName=pcall(function() return chest.Name end)
            chestName=(okName and chestName and chestName~="") and chestName or "Chest"
            local chestColor=Color3.fromRGB(235,235,235)
            if chestName=="SilverChest" then chestColor=Color3.fromRGB(165,165,165)
            elseif chestName=="GoldChest" then chestColor=Color3.fromRGB(255,215,55)
            elseif chestName=="DiamondChest" then chestColor=Color3.fromRGB(85,205,255) end
            if not S.chestEspLabelCache[key] then
                local label=Drawing.new("Text")
                label.Text=chestName
                label.Position=Vector2.new(0,0)
                label.Color=chestColor
                label.Size=14
                label.Outline=true
                label.Visible=false
                label.ZIndex=10
                label.Font=Drawing.Fonts.Monospace
                label.Center=true
                S.chestEspLabelCache[key]={label=label,part=part,name=chestName}
            else
                S.chestEspLabelCache[key].part=part
                S.chestEspLabelCache[key].name=chestName
                S.chestEspLabelCache[key].label.Text=chestName
                S.chestEspLabelCache[key].label.Color=chestColor
            end
            table.insert(S.chestEspLabels, S.chestEspLabelCache[key])
        end
    end
end

local function getBoatEspKey(boat)
    local okAddress,address=pcall(function() return boat and boat.Address end)
    if okAddress and address and address~=0 then return "boat:"..tostring(address) end
    return "boat:"..tostring(boat)
end

local function getBoatEspParts(boat)
    local parts={}
    if not boat then return parts end
    local okDesc,desc=pcall(function() return boat:GetDescendants() end)
    if okDesc and desc then
        for _,obj in pairs(desc) do
            if obj:IsA("BasePart") then parts[#parts+1]=obj end
        end
    end
    return parts
end

local function getBoatEspBounds(parts)
    local minX,minY,minZ=math.huge,math.huge,math.huge
    local maxX,maxY,maxZ=-math.huge,-math.huge,-math.huge
    local any=false
    for _,part in pairs(parts) do
        local ok,pos,size=pcall(function() return part.Position, part.Size end)
        if ok and pos and size then
            any=true
            local hx,hy,hz=size.X*0.5,size.Y*0.5,size.Z*0.5
            if pos.X-hx<minX then minX=pos.X-hx end
            if pos.Y-hy<minY then minY=pos.Y-hy end
            if pos.Z-hz<minZ then minZ=pos.Z-hz end
            if pos.X+hx>maxX then maxX=pos.X+hx end
            if pos.Y+hy>maxY then maxY=pos.Y+hy end
            if pos.Z+hz>maxZ then maxZ=pos.Z+hz end
        end
    end
    if not any then return nil end
    return minX,minY,minZ,maxX,maxY,maxZ
end

function buildBoatEsp()
    for _,entry in pairs(S.boatEspCache) do
        if entry and entry.label then entry.label.Visible=false end
        if entry and entry.lines then
            for _,line in pairs(entry.lines) do line.Visible=false end
        end
    end
    S.boatEspEntries={}
    local boats=Workspace:FindFirstChild("Boats")
    if not boats then return end
    local okChildren,children=pcall(function() return boats:GetChildren() end)
    if not okChildren or not children then return end
    for _,boat in pairs(children) do
        local parts=getBoatEspParts(boat)
        if #parts>0 then
            local anchor=boat.PrimaryPart or boat:FindFirstChildOfClass("VehicleSeat") or parts[1]
            local minX,minY,minZ,maxX,maxY,maxZ=getBoatEspBounds(parts)
            local okAnchor,anchorPos=pcall(function() return anchor and anchor.Position end)
            if anchor and minX and okAnchor and anchorPos then
                local bounds={
                    minX=minX-anchorPos.X,minY=minY-anchorPos.Y,minZ=minZ-anchorPos.Z,
                    maxX=maxX-anchorPos.X,maxY=maxY-anchorPos.Y,maxZ=maxZ-anchorPos.Z,
                }
                local key=getBoatEspKey(boat)
                local entry=S.boatEspCache[key]
                if not entry then
                    local lines={}
                    for _=1,12 do
                        local line=Drawing.new("Line")
                        line.Color=Color3.fromRGB(80,180,255)
                        line.Thickness=2
                        line.Visible=false
                        line.ZIndex=10
                        table.insert(lines,line)
                    end
                    local label=Drawing.new("Text")
                    local okName,bname=pcall(function() return boat.Name end)
                    label.Text=(okName and bname) or "Boat"
                    label.Position=Vector2.new(0,0)
                    label.Color=Color3.fromRGB(80,180,255)
                    label.Size=16
                    label.Outline=true
                    label.Center=true
                    label.Font=Drawing.Fonts.Monospace
                    label.Visible=false
                    label.ZIndex=11
                    entry={boat=boat,anchor=anchor,bounds=bounds,lines=lines,label=label}
                    S.boatEspCache[key]=entry
                else
                    entry.boat=boat
                    entry.anchor=anchor
                    entry.bounds=bounds
                    local okName,bname=pcall(function() return boat.Name end)
                    entry.label.Text=(okName and bname) or "Boat"
                end
                table.insert(S.boatEspEntries, entry)
            end
        end
    end
end

local function getFlowerEspKey(flowerName,flower)
    return tostring(flowerName)..":"..trackedInstanceKey(flower)
end

function buildFlowerEsp()
    for _,entry in pairs(S.flowerEspCache) do
        if entry and entry.label then entry.label.Visible=false end
        if entry and entry.lines then
            for _,line in pairs(entry.lines) do line.Visible=false end
        end
    end
    S.flowerEspEntries={}
    local targets={
        {workspaceName="Flower1", label="Blue Flower", color=Color3.fromRGB(55,145,255)},
        {workspaceName="Flower2", label="Red Flower", color=Color3.fromRGB(255,65,65)},
    }
    local function collectFlowers(root, list)
        if not root then return end
        local ok,children=pcall(function() return root:GetChildren() end)
        if not ok or not children then return end
        for _,obj in pairs(children) do
            for _,target in pairs(targets) do
                if obj.Name==target.workspaceName then list[#list+1]={obj=obj,target=target} end
            end
        end
    end
    local found={}
    collectFlowers(Workspace, found)
    local map=Workspace:FindFirstChild("Map")
    if map then
        local okd,desc=pcall(function() return map:GetDescendants() end)
        if okd and desc then
            for _,obj in pairs(desc) do
                for _,target in pairs(targets) do
                    if obj.Name==target.workspaceName then found[#found+1]={obj=obj,target=target} end
                end
            end
        end
    end
    for _,item in pairs(found) do
        local flower,target=item.obj,item.target
        local parts={}
        if flower:IsA("BasePart") then parts[1]=flower
        else
            local okd,desc=pcall(function() return flower:GetDescendants() end)
            if okd and desc then
                for _,d in pairs(desc) do
                    if d:IsA("BasePart") then parts[#parts+1]=d end
                end
            end
        end
        if #parts>0 then
            local anchor=parts[1]
            local minX,minY,minZ,maxX,maxY,maxZ=getBoatEspBounds(parts)
            local okAnchor,anchorPos=pcall(function() return anchor and anchor.Position end)
            if anchor and minX and okAnchor and anchorPos then
                local bounds={
                    minX=minX-anchorPos.X,minY=minY-anchorPos.Y,minZ=minZ-anchorPos.Z,
                    maxX=maxX-anchorPos.X,maxY=maxY-anchorPos.Y,maxZ=maxZ-anchorPos.Z,
                }
                local key=getFlowerEspKey(target.workspaceName,flower)
                local entry=S.flowerEspCache[key]
                if not entry then
                    local lines={}
                    for _=1,12 do
                        local line=Drawing.new("Line")
                        line.Color=target.color
                        line.Thickness=2
                        line.Visible=false
                        line.ZIndex=10
                        table.insert(lines,line)
                    end
                    local label=Drawing.new("Text")
                    label.Text=target.label
                    label.Position=Vector2.new(0,0)
                    label.Color=target.color
                    label.Size=18
                    label.Outline=true
                    label.Center=true
                    label.Font=Drawing.Fonts.Monospace
                    label.Visible=false
                    label.ZIndex=11
                    entry={flower=flower,anchor=anchor,bounds=bounds,name=target.label,lines=lines,label=label}
                    S.flowerEspCache[key]=entry
                else
                    entry.flower=flower
                    entry.anchor=anchor
                    entry.bounds=bounds
                    entry.name=target.label
                    entry.label.Text=target.label
                    entry.label.Color=target.color
                    for _,line in pairs(entry.lines) do line.Color=target.color end
                end
                table.insert(S.flowerEspEntries, entry)
            end
        end
    end
end

local ESP_BOX_EDGES={
    {1,2},{2,4},{4,3},{3,1},
    {5,6},{6,8},{8,7},{7,5},
    {1,5},{2,6},{3,7},{4,8},
}

local function updateWorldBoxEntry(entry)
    local visible=false
    local okAnchor,anchorParent,anchorPos=pcall(function()
        return entry.anchor and entry.anchor.Parent, entry.anchor and entry.anchor.Position
    end)
    local bounds=entry.bounds
    if okAnchor and anchorParent and anchorPos and bounds then
        local minX=anchorPos.X+bounds.minX
        local minY=anchorPos.Y+bounds.minY
        local minZ=anchorPos.Z+bounds.minZ
        local maxX=anchorPos.X+bounds.maxX
        local maxY=anchorPos.Y+bounds.maxY
        local maxZ=anchorPos.Z+bounds.maxZ
        local corners=entry.worldCorners or {}
        entry.worldCorners=corners
        corners[1]=Vector3.new(minX,minY,minZ)
        corners[2]=Vector3.new(maxX,minY,minZ)
        corners[3]=Vector3.new(minX,maxY,minZ)
        corners[4]=Vector3.new(maxX,maxY,minZ)
        corners[5]=Vector3.new(minX,minY,maxZ)
        corners[6]=Vector3.new(maxX,minY,maxZ)
        corners[7]=Vector3.new(minX,maxY,maxZ)
        corners[8]=Vector3.new(maxX,maxY,maxZ)

        local screenPoints=entry.screenPoints or {}
        entry.screenPoints=screenPoints
        local screenMinX,screenMinY=math.huge,math.huge
        local screenMaxX=-math.huge
        local projectedCount=0
        for index=1,8 do
            local okScreen,screenPos,onScreen=pcall(function() return WorldToScreen(corners[index]) end)
            if okScreen and screenPos and onScreen==true then
                screenPoints[index]=screenPos
                projectedCount=projectedCount+1
                if screenPos.X<screenMinX then screenMinX=screenPos.X end
                if screenPos.Y<screenMinY then screenMinY=screenPos.Y end
                if screenPos.X>screenMaxX then screenMaxX=screenPos.X end
            else
                break
            end
        end

        if projectedCount==8 then
            for index,edge in ipairs(ESP_BOX_EDGES) do
                entry.lines[index].From=screenPoints[edge[1]]
                entry.lines[index].To=screenPoints[edge[2]]
            end
            entry.label.Position=Vector2.new((screenMinX+screenMaxX)/2,screenMinY-20)
            visible=true
        end
    end

    for _,line in pairs(entry.lines) do line.Visible=visible end
    entry.label.Visible=visible
end

local function safeObjectPosition(object)
    if not object then return nil end
    local okPos,pos=pcall(function()
        if object:IsA("BasePart") then return object.Position end
        local p=object:FindFirstChild("HumanoidRootPart") or object:FindFirstChildOfClass("BasePart") or object.PrimaryPart
        return p and p.Position
    end)
    if okPos and pos and pos.X then return pos end
    return nil
end

local function findMirageObject()
    local origin=Workspace:FindFirstChild("_WorldOrigin")
    local locations=origin and origin:FindFirstChild("Locations")
    local location=locations and locations:FindFirstChild("Mirage Island")
    if location then return location end
    local map=Workspace:FindFirstChild("Map")
    return map and (map:FindFirstChild("MysticIsland") or map:FindFirstChild("Mirage Island")) or nil
end

local function updateMirageEsp()
    if not S.mirageEsp then clearMirageEsp(); return end
    if not S.mirageEspLabel then
        local label=Drawing.new("Text")
        label.Text="Mirage Island"
        label.Position=Vector2.new(0,0)
        label.Color=Color3.fromRGB(100,220,255)
        label.Size=22
        label.Center=true
        label.Outline=true
        label.Font=Drawing.Fonts.Monospace
        label.Visible=false
        label.ZIndex=20
        S.mirageEspLabel=label
    end
    local mirage=findMirageObject()
    local position=safeObjectPosition(mirage)
    if not position then clearMirageEsp(); return end
    local okScreen,screen,onScreen=pcall(function() return WorldToScreen(position) end)
    if not okScreen or not screen or onScreen~=true then clearMirageEsp(); return end
    local distanceText=""
    local character=LocalPlayer.Character
    local hrp=character and character:FindFirstChild("HumanoidRootPart")
    local okPlayer,playerPosition=pcall(function() return hrp and hrp.Position end)
    if okPlayer and playerPosition then
        local dx=position.X-playerPosition.X
        local dy=position.Y-playerPosition.Y
        local dz=position.Z-playerPosition.Z
        distanceText=" ["..tostring(math.floor(math.sqrt(dx*dx+dy*dy+dz*dz))).."]"
    end
    S.mirageEspLabel.Text="Mirage Island"..distanceText
    S.mirageEspLabel.Position=screen
    S.mirageEspLabel.Visible=true
end

-- ESP render loops (haunted)
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.chestEsp then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart") or nil
            local okPlayer,playerPos=pcall(function() return hrp and hrp.Position end)
            for _,entry in pairs(S.chestEspLabels) do
                local label=entry and entry.label or nil
                local part=entry and entry.part or nil
                local okParent,parent=pcall(function() return part and part.Parent end)
                local okPos,pos=pcall(function() return part and part.Position end)
                if label and okPlayer and playerPos and okParent and parent and okPos and pos then
                    local dx=pos.X-playerPos.X
                    local dy=pos.Y-playerPos.Y
                    local dz=pos.Z-playerPos.Z
                    local distanceSq=dx*dx+dy*dy+dz*dz
                    if distanceSq<=100000000 then
                        local okScreen,screenPos,onScreen=pcall(function() return WorldToScreen(pos) end)
                        label.Visible=okScreen and onScreen or false
                        if okScreen and onScreen and screenPos then
                            label.Position=Vector2.new(screenPos.X,screenPos.Y-20)
                        end
                    else
                        label.Visible=false
                    end
                elseif label then
                    label.Visible=false
                end
            end
        end
        task.wait()
    end
end)

task.spawn(function()
    while not _G.FE_Unloaded do
        if S.boatEsp then
            for _,entry in pairs(S.boatEspEntries) do
                updateWorldBoxEntry(entry)
            end
        end
        if S.flowerEsp then
            for _,entry in pairs(S.flowerEspEntries) do
                updateWorldBoxEntry(entry)
            end
        end
        if S.mirageEsp then
            updateMirageEsp()
        end
        task.wait()
    end
end)

task.spawn(function()
    while not _G.FE_Unloaded do
        task.wait(1)
        if S.flowerEsp and trackedFlowersChanged() then buildFlowerEsp() end
    end
end)

task.spawn(function()
    while not _G.FE_Unloaded do
        task.wait(2)
        if S.chestEsp then
            local chestModels=Workspace:FindFirstChild("ChestModels")
            if trackedFolderChanged("chests",chestModels) then buildChestEspLabels() end
        end
        if S.boatEsp then
            local boats=Workspace:FindFirstChild("Boats")
            if trackedFolderChanged("boats",boats) then buildBoatEsp() end
        end
    end
end)


-- World checks (haunted — FindFirstChild only, no GetDescendants)
function showEventStatus()
    local locations=nil
    pcall(function()
        local origin=Workspace:FindFirstChild("_WorldOrigin")
        locations=origin and origin:FindFirstChild("Locations") or nil
    end)
    local map=Workspace:FindFirstChild("Map")
    local mirage=locations and locations:FindFirstChild("Mirage Island")
    local prehistoric=locations and locations:FindFirstChild("Prehistoric Island")
    local frozen=locations and locations:FindFirstChild("Frozen Dimension")
    local kitsune=map and map:FindFirstChild("KitsuneIsland")
    local message="Mirage: "..(mirage and "YES" or "NO").." | Kitsune: "..(kitsune and "YES" or "NO").." | Prehistoric: "..(prehistoric and "YES" or "NO").." | Frozen: "..(frozen and "YES" or "NO")
    -- status via notify only
    notify(message,"World Status",8)
end

function showBossStatus()
    local storage=ReplicatedStorage
    local enemies=Workspace:FindFirstChild("Enemies")
    local function present(name,alternate)
        return (enemies and (enemies:FindFirstChild(name) or (alternate and enemies:FindFirstChild(alternate))))
            or storage:FindFirstChild(name)
            or (alternate and storage:FindFirstChild(alternate))
    end
    local message="Rip Indra: "..(present("rip_indra True Form","rip_indra") and "YES" or "NO")
        .." | Dough King: "..(present("Dough King") and "YES" or "NO")
        .." | Cake Prince: "..(present("Cake Prince") and "YES" or "NO")
    -- status via notify only
    notify(message,"Boss Status",8)
end

-- aliases used by older UI callbacks
function checkEventIslands()
    showEventStatus()
end
function checkImportantBosses()
    showBossStatus()
end

-- Auto Haki + Race Ability
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.autoHaki then
            local char = LocalPlayer.Character
            if char and not char:FindFirstChild("HasBuso") then
                invokeCommF("Buso")
            end
        end
        if S.autoRaceAbility then
            local e = getCommE()
            if e then pcall(function() e:FireServer("ActivateAbility") end) end
        end
        task.wait(0.5)
    end
end)

-- Auto Stats (InvokeServer AddPoint — same as haunted)
task.spawn(function()
    local statEntries = {
        {"autoStatMelee", "Melee"},
        {"autoStatDefense", "Defense"},
        {"autoStatSword", "Sword"},
        {"autoStatGun", "Gun"},
        {"autoStatFruit", "Demon Fruit"},
    }
    while not _G.FE_Unloaded do
        for _, entry in ipairs(statEntries) do
            if S[entry[1]] then
                invokeCommF("AddPoint", entry[2], S.statAmount or 10)
                task.wait(0.12)
            end
        end
        task.wait(0.5)
    end
end)

-- Tween Ember (smooth, separate from instant TP)
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.tweenEmber then
            local hrp = getMyHrp()
            if hrp then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj.Name == "EmberTemplate" and obj:IsA("Model") then
                        local part = obj:FindFirstChild("Part") or extraGetPart(obj)
                        if part and part:IsA("BasePart") then
                            tweenTo(hrp, Vector3.new(part.Position.X, part.Position.Y + 3, part.Position.Z), S.FRUIT_SPEED, function() return S.tweenEmber end)
                            break
                        end
                    end
                end
            end
            task.wait(0.4)
        else
            task.wait(0.2)
        end
    end
end)

-- Mirage tween + gear
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.autoMirageTween then
            local m = findMirageModel()
            local hrp = getMyHrp()
            local part = m and extraGetPart(m)
            if hrp and part then
                tweenTo(hrp, Vector3.new(part.Position.X, part.Position.Y + 120, part.Position.Z), S.FARM_SPEED, function() return S.autoMirageTween end)
            end
            task.wait(1)
        else
            task.wait(0.3)
        end
    end
end)
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.autoMirageGear then
            local m = findMirageModel()
            local hrp = getMyHrp()
            if hrp and m then
                local best, bestVol = nil, 0
                for _, p in ipairs(m:GetDescendants()) do
                    if (p:IsA("MeshPart") or p:IsA("Part")) and p.Transparency < 0.4 then
                        local vol = p.Size.X * p.Size.Y * p.Size.Z
                        if vol > 2 and vol < 400 and vol > bestVol then
                            bestVol = vol; best = p
                        end
                    end
                end
                if best then
                    tweenTo(hrp, Vector3.new(best.Position.X, best.Position.Y + 4, best.Position.Z), S.FRUIT_SPEED, function() return S.autoMirageGear end)
                end
            end
            task.wait(0.8)
        else
            task.wait(0.3)
        end
    end
end)

-- Auto mastery (chocolate + buddha)
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.autoMastery then
            local hrp = getMyHrp()
            if hrp then
                local dest = AFL.pos and AFL.pos.chocolate1 or Vector3.new(237.92, 24.8, -12201.14)
                tweenTo(hrp, dest, S.MASTERY_SPEED or S.FARM_SPEED, function() return S.autoMastery end)
                local tool = findTool("Buddha-Buddha") or findTool("Buddha")
                if tool then
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and tool.Parent ~= char then pcall(function() hum:EquipTool(tool) end) end
                    task.wait(0.15)
                    tapKey(0x5A)
                end
                hrp = getMyHrp()
                if hrp then farmAttack(hrp, function() return S.autoMastery end, nil) end
            end
            task.wait(0.2)
        else
            task.wait(0.3)
        end
    end
end)

-- Material / Boss / Sea event farms (haunted-style)
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.autoBoss then
            local hrp = getMyHrp()
            local target = S.bossTarget
            local spawned = hrp and nearestNamedEnemy({target}) or nil
            if hrp and spawned then
                if S.remoteMode then
                    while S.autoBoss and S.bossTarget == target and isAlive(spawned) do
                        hrp = getMyHrp()
                        local root = spawned:FindFirstChild("HumanoidRootPart") or spawned:FindFirstChildOfClass("BasePart")
                        if not hrp or not root then break end
                        hrp.Position = Vector3.new(root.Position.X, root.Position.Y + 30, root.Position.Z)
                        hrp.Velocity = Vector3.new(0,0,0)
                        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        pcall(remoteAttack)
                        task.wait(0.05)
                    end
                else
                    farmAttack(hrp, function()
                        return S.autoBoss and S.bossTarget == target
                    end, target)
                end
            else
                task.wait(0.35)
            end
        else
            task.wait(0.1)
        end
    end
end)
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.autoMaterial and not S.autoBoss then
            local names = MATERIAL_MAP[S.materialTarget] or {S.materialTarget}
            local hrp = getMyHrp()
            local spawned = hrp and nearestNamedEnemy(names) or nil
            if hrp and spawned then
                farmAttack(hrp, function()
                    return S.autoMaterial and not S.autoBoss
                end, spawned.Name)
            else
                task.wait(0.35)
            end
        else
            task.wait(0.1)
        end
    end
end)
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.autoSeaEvent and not S.autoBoss then
            local hrp = getMyHrp()
            local target = S.seaEventTarget
            local spawned = hrp and nearestNamedEnemy({target}) or nil
            if hrp and spawned then
                farmAttack(hrp, function()
                    return S.autoSeaEvent and S.seaEventTarget == target
                end, target)
            else
                task.wait(0.35)
            end
        else
            task.wait(0.1)
        end
    end
end)


-- Boat seats (haunted method)
local boatSeatOptions={"No boats found"}
local boatSeatByLabel={}
local lastBoatSeatSignature=""
local boatSeatDropdownHandle=nil

local function findBoatVehicleSeat(boat)
    if not boat then return nil end
    local okDirect,directSeat=pcall(function() return boat:FindFirstChildOfClass("VehicleSeat") end)
    if okDirect and directSeat then return directSeat end
    local okDescendants,descendants=pcall(function() return boat:GetDescendants() end)
    if okDescendants and descendants then
        for _,object in pairs(descendants) do
            local okClass,className=pcall(function() return object.ClassName end)
            if okClass and className=="VehicleSeat" then return object end
        end
    end
    return nil
end

function refreshBoatSeats()
    local entries={}
    local boats=Workspace:FindFirstChild("Boats")
    local okChildren,children=pcall(function() return boats and boats:GetChildren() end)
    if okChildren and children then
        for _,boat in pairs(children) do
            local seat=findBoatVehicleSeat(boat)
            if seat then
                local okName,name=pcall(function() return boat.Name end)
                name=(okName and type(name)=="string" and name~="") and name or "Boat"
                local okAddress,address=pcall(function() return seat.Address end)
                local key=(okAddress and address and address~=0) and tostring(address) or tostring(seat)
                table.insert(entries,{name=name,seat=seat,key=key})
            end
        end
    end
    table.sort(entries,function(a,b)
        if a.name==b.name then return a.key<b.key end
        return a.name<b.name
    end)
    local totals={}
    for _,entry in ipairs(entries) do totals[entry.name]=(totals[entry.name] or 0)+1 end
    local used={}
    local nextLabels={}
    local nextMap={}
    local selectedLabel=nil
    for _,entry in ipairs(entries) do
        used[entry.name]=(used[entry.name] or 0)+1
        local label=entry.name
        if totals[entry.name]>1 then label=label.." #"..tostring(used[entry.name]) end
        table.insert(nextLabels,label)
        nextMap[label]=entry.seat
        if entry.seat==S.selectedBoatSeat then selectedLabel=label end
    end
    if #nextLabels==0 then
        nextLabels={"No boats found"}
        nextMap={}
    end
    boatSeatByLabel=nextMap
    local signature=table.concat(nextLabels,"|")
    if signature~=lastBoatSeatSignature then
        for index=#boatSeatOptions,1,-1 do boatSeatOptions[index]=nil end
        for _,label in ipairs(nextLabels) do table.insert(boatSeatOptions,label) end
        lastBoatSeatSignature=signature
        pcall(function()
            if boatSeatDropdownHandle and boatSeatDropdownHandle.UpdateChoices then
                boatSeatDropdownHandle:UpdateChoices(boatSeatOptions)
            end
        end)
    end
    if not selectedLabel and S.selectedBoatSeatLabel and nextMap[S.selectedBoatSeatLabel] then
        selectedLabel=S.selectedBoatSeatLabel
    end
    if not selectedLabel then selectedLabel=nextLabels[1] end
    local selectedSeat=nextMap[selectedLabel]
    if selectedLabel~=S.selectedBoatSeatLabel or selectedSeat~=S.selectedBoatSeat then
        S.selectedBoatSeatLabel=selectedLabel
        S.selectedBoatSeat=selectedSeat
        pcall(function()
            if boatSeatDropdownHandle and boatSeatDropdownHandle.Set and selectedLabel then
                boatSeatDropdownHandle:Set({ selectedLabel })
            end
        end)
    end
    return boatSeatOptions
end

local function isUsingSelectedBoatSeat(seat,char,humanoid,hrp)
    local okOccupant,occupant=pcall(function() return seat.Occupant end)
    if okOccupant and occupant then
        if occupant==humanoid then return true end
        local okParent,parent=pcall(function() return occupant.Parent end)
        return okParent and parent==char
    end
    local okSeatPart,seatPart=pcall(function() return humanoid and humanoid.SeatPart end)
    if okSeatPart and seatPart then return seatPart==seat end
    if okOccupant or okSeatPart then return false end
    local okPositions,seatPos,playerPos=pcall(function() return seat.Position,hrp.Position end)
    if not okPositions or not seatPos or not playerPos then return false end
    local dx=seatPos.X-playerPos.X
    local dy=seatPos.Y-playerPos.Y
    local dz=seatPos.Z-playerPos.Z
    return dx*dx+dy*dy+dz*dz<=25
end

task.spawn(function()
    task.wait(1)
    pcall(refreshBoatSeats)
    while not _G.FE_Unloaded do
        task.wait(1)
        pcall(refreshBoatSeats)
    end
end)

-- Auto boat seat (haunted)
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.autoBoatSeat then
            local seat=S.selectedBoatSeat
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart") or nil
            local humanoid=char and char:FindFirstChildOfClass("Humanoid") or nil
            local okSeat,seatParent,seatPos=pcall(function()
                return seat and seat.Parent,seat and seat.Position
            end)
            if seat and char and hrp and humanoid and okSeat and seatParent and seatPos
                and not isUsingSelectedBoatSeat(seat,char,humanoid,hrp) then
                pcall(function()
                    hrp.Position=Vector3.new(seatPos.X,seatPos.Y+2,seatPos.Z)
                    hrp.Velocity=Vector3.new(0,0,0)
                    hrp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                end)
            end
        end
        task.wait()
    end
end)

-- Switch weapon after picking a fruit
task.spawn(function()
    while not _G.FE_Unloaded do
        if S.weaponAfterFruit then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                local n = string.lower(tool.Name)
                if n:find("fruit") or tool:FindFirstChild("Handle") and n:find("-") then
                    local fruitLike = n:find("fruit") or n:find("-fruit") or n:find("-flame") or n:find("-ice") or n:find("-dark")
                    if n:find("fruit") then
                        local slot = (S.weaponSlot == "Sword") and 3 or 1
                        tapKey(0x30 + slot)
                    end
                end
            end
        end
        task.wait(0.4)
    end
end)

-- ============================================================
-- Dungeon (2nd sea) — no Drawing GUI; controlled via Hub Dungeon tab
-- ============================================================
local Dungeon = {
    target = nil,
    doorWaypoint = nil,
    doorStatus = "Door Not Ready",
    floorName = "Scanning...",
    status = "Idle",
    targetingObjective = false,
    originalSizes = {},
    renderConn = nil,
}

local DUNGEON_MELEE_KW = {
    "godhuman","sanguine","sharkman","electric","dragon talon","dragon breath",
    "death step","superhuman","water kung fu","dark step","electro","combat",
    "karate","claw","talon","art","human",
}
local DUNGEON_SWORD_KW = {
    "yama","tushita","cursed dual katana","true triple katana","cdk","ttk",
    "saber","pole","bisento","hallow scythe","dark blade","yoru","spikey trident",
    "shark anchor","fox lamp","gravity cane","rengoku","shisui","wando","saddi",
    "midnight blade","canvander","buddy sword","twin hooks","dragon trident",
    "sword","blade","katana","scythe","trident","dagger","cutlass",
}

local function dungeonActive()
    return S.dungeonEnabled == true and not _G.FE_Unloaded
end

local function dungeonIsSummon(obj)
    if not obj then return true end
    if obj:FindFirstChild("Summoner") or obj:FindFirstChild("Creator") or obj:FindFirstChild("Owner") then return true end
    local n = string.lower(obj.Name or "")
    if n:find("shadow") or n:find("buddy") or n:find("blank") or n:find("clone") or n:find("summon") or n:find("decoy") or n:find("dummy") then
        return true
    end
    return false
end

local function dungeonIsObjective(obj)
    if not obj or not obj.Parent or dungeonIsSummon(obj) then return false end
    local name = string.lower(obj.Name or "")
    local isProp = name == "prophitboxplaceholder"
        or name:find("placeholder")
        or name:find("gasvent")
        or name:find("vent")
        or name:find("shrine")
        or name:find("rock")
        or name:find("totem")
        or (name:find("prop") and not name:find("knight") and not name:find("boss"))
    if not isProp then return false end
    local hum = obj:FindFirstChild("Humanoid")
    local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
    return root and hum and hum.Health > 0 and hum.MaxHealth < 50000
end

local function dungeonIsEnemy(mob)
    if not mob or not mob.Parent or dungeonIsSummon(mob) then return false end
    local hum = mob:FindFirstChild("Humanoid")
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head") or mob:FindFirstChildWhichIsA("BasePart")
    return hum and root and hum.Health > 0
end

local function dungeonMatchWeapon(tool, pref)
    if not tool or tool.ClassName ~= "Tool" then return false end
    local name = string.lower(tool.Name)
    local list = (pref == "Sword") and DUNGEON_SWORD_KW or DUNGEON_MELEE_KW
    for _, k in ipairs(list) do
        if name:find(k, 1, true) then return true end
    end
    if pref == "Melee" and tool.ToolTip == "Melee" then return true end
    if pref == "Sword" and tool.ToolTip == "Sword" then return true end
    return false
end

local function dungeonTriggerHotbar(slotNum)
    local keyCode = 0x30 + slotNum
    pcall(function()
        if keyclick then keyclick(keyCode)
        elseif keypress and keyrelease then
            keypress(keyCode); task.wait(0.04); keyrelease(keyCode)
        end
    end)
end

local function dungeonAutoEquip()
    if not S.dungeonAutoEquip then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local pref = S.dungeonWeapon or "Melee"
    for _, c in ipairs(char:GetChildren()) do
        if c.ClassName == "Tool" and dungeonMatchWeapon(c, pref) then return end
    end
    dungeonTriggerHotbar((pref == "Melee") and 1 or 3)
    task.delay(0.15, function()
        if not LocalPlayer.Character then return end
        local cChar = LocalPlayer.Character
        for _, c in ipairs(cChar:GetChildren()) do
            if c.ClassName == "Tool" and dungeonMatchWeapon(c, pref) then return end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, item in ipairs(bp:GetChildren()) do
                if item.ClassName == "Tool" and dungeonMatchWeapon(item, pref) then
                    item.Parent = cChar
                    break
                end
            end
        end
    end)
end

local function dungeonActivateBuso()
    if not S.dungeonBuso then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if char:FindFirstChild("HasBuso") or char:GetAttribute("Buso") or char:GetAttribute("Haki") then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local commF = remotes and remotes:FindFirstChild("CommF_")
        if commF then commF:InvokeServer("Buso") end
    end)
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
        if net and net:FindFirstChild("RE/Buso") then net["RE/Buso"]:FireServer() end
    end)
    pcall(function()
        if keyclick then keyclick(0x4A)
        elseif keypress and keyrelease then keypress(0x4A); task.wait(0.04); keyrelease(0x4A) end
    end)
end

local function dungeonGetIsland(myPos)
    local dungeon = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Dungeon")
    if not dungeon then return nil, 0 end
    local bestIsland, bestNum, minDelta = nil, 0, 999999
    for _, isl in ipairs(dungeon:GetChildren()) do
        local num = tonumber(isl.Name)
        local rootPart = isl:FindFirstChild("Root") or isl:FindFirstChildWhichIsA("BasePart")
        if rootPart then
            local delta = (Vector3.new(myPos.X, 0, myPos.Z) - Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)).Magnitude
            if delta < minDelta then
                minDelta = delta
                bestIsland = isl
                bestNum = num or 0
            end
        end
    end
    return bestIsland, bestNum
end

local function dungeonCalcDoor(pPos)
    local currentIslandModel, currentIslandNum = dungeonGetIsland(pPos)
    Dungeon.floorName = "Island " .. tostring(currentIslandNum > 0 and currentIslandNum or "1")
    if currentIslandModel then
        local islandRootPart = currentIslandModel:FindFirstChild("Root") or currentIslandModel:FindFirstChildWhichIsA("BasePart")
        local exitTele = currentIslandModel:FindFirstChild("ExitTeleporter")
        if exitTele then
            local doorPart = exitTele:FindFirstChild("Root") or exitTele:FindFirstChildWhichIsA("BasePart")
            if doorPart then
                local doorPos = doorPart.Position
                local distXZ = (Vector3.new(doorPos.X - pPos.X, 0, doorPos.Z - pPos.Z)).Magnitude
                local islandRootY = islandRootPart and islandRootPart.Position.Y or 200
                if distXZ > 30 then
                    local safeY = math.max(pPos.Y, doorPos.Y, islandRootY) + 35
                    return Vector3.new(doorPos.X, safeY, doorPos.Z), "Sky Arc -> Door"
                else
                    return doorPos + Vector3.new(0, 3, 0), "Entering Door"
                end
            end
        end
    end
    return nil, "Door Not Ready"
end

local function dungeonRestoreHitboxes()
    for part, originalSize in pairs(Dungeon.originalSizes) do
        if part and part.Parent then pcall(function() part.Size = originalSize end) end
    end
    Dungeon.originalSizes = {}
end

local function dungeonStop()
    S.dungeonFloat = false
    Dungeon.target = nil
    Dungeon.doorWaypoint = nil
    if Dungeon.renderConn then
        pcall(function() Dungeon.renderConn:Disconnect() end)
        Dungeon.renderConn = nil
    end
    dungeonRestoreHitboxes()
end

-- scanner
task.spawn(function()
    while not _G.FE_Unloaded do
        if dungeonActive() and S.dungeonFloat then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local myPos = myRoot.Position
                local folder = Workspace:FindFirstChild("Enemies")
                local foundObjective, foundMob = nil, nil
                if folder then
                    if S.dungeonDestroyObj then
                        local best = math.huge
                        for _, e in ipairs(folder:GetChildren()) do
                            if dungeonIsObjective(e) then
                                local part = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    local d = (myPos - part.Position).Magnitude
                                    if d < best then best = d; foundObjective = e end
                                end
                            end
                        end
                    end
                    if not foundObjective then
                        local best = S.dungeonLocalRadius or 800
                        for _, e in ipairs(folder:GetChildren()) do
                            if dungeonIsEnemy(e) then
                                local part = e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("Head") or e:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    local d = (myPos - part.Position).Magnitude
                                    if d < best then best = d; foundMob = e end
                                end
                            end
                        end
                    end
                end
                if foundObjective then
                    Dungeon.target = foundObjective
                    Dungeon.targetingObjective = true
                elseif foundMob then
                    Dungeon.target = foundMob
                    Dungeon.targetingObjective = false
                else
                    Dungeon.target = nil
                    Dungeon.targetingObjective = false
                end
                if not Dungeon.target and S.dungeonAutoDoor then
                    Dungeon.doorWaypoint, Dungeon.doorStatus = dungeonCalcDoor(myPos)
                else
                    Dungeon.doorWaypoint = nil
                end
            end
        elseif not S.dungeonFloat then
            Dungeon.target = nil
        end
        task.wait(0.12)
    end
end)

-- flight RenderStepped
task.spawn(function()
    task.wait(1)
    if not RunService.RenderStepped then return end
    Dungeon.renderConn = RunService.RenderStepped:Connect(function(dt)
        if _G.FE_Unloaded then
            pcall(function() if Dungeon.renderConn then Dungeon.renderConn:Disconnect() end end)
            return
        end
        if not dungeonActive() or not S.dungeonFloat then return end
        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local myHum = char and char:FindFirstChild("Humanoid")
        if not myRoot or not myHum or myHum.Health <= 0 then return end
        pcall(function() myRoot.CanCollide = false end)
        local currentPos = myRoot.Position
        local speed = S.dungeonFlightSpeed or 250
        local height = S.dungeonFloatHeight or 12
        if Dungeon.target and Dungeon.target.Parent then
            local targetPart = Dungeon.target:FindFirstChild("HumanoidRootPart")
                or Dungeon.target:FindFirstChild("UpperTorso")
                or Dungeon.target:FindFirstChild("Head")
                or Dungeon.target:FindFirstChildWhichIsA("BasePart")
            if targetPart then
                local live = targetPart.Position
                local hover = live + Vector3.new(0, height, 0)
                local diff = hover - currentPos
                local dist = diff.Magnitude
                Dungeon.status = Dungeon.targetingObjective and "Tween to Vent" or "Magnet Lock"
                if dist <= 2.5 then
                    myRoot.CFrame = CFrame.lookAt(hover, live)
                else
                    local step = math.min(dist, speed * dt)
                    myRoot.CFrame = CFrame.lookAt(currentPos + diff.Unit * step, live)
                end
                myRoot.AssemblyLinearVelocity = Vector3.zero
            end
        elseif S.dungeonAutoDoor and Dungeon.doorWaypoint then
            Dungeon.status = Dungeon.doorStatus or "Door"
            local diff = Dungeon.doorWaypoint - currentPos
            local dist = diff.Magnitude
            local lookDir = Dungeon.doorWaypoint + Vector3.new(0, 0, 10)
            if dist <= 2 then
                myRoot.CFrame = CFrame.lookAt(Dungeon.doorWaypoint, lookDir)
            else
                local step = math.min(dist, speed * dt)
                myRoot.CFrame = CFrame.lookAt(currentPos + diff.Unit * step, lookDir)
            end
            myRoot.AssemblyLinearVelocity = Vector3.zero
        else
            Dungeon.status = "Island Cleared"
        end
    end)
end)

-- skills on objectives
task.spawn(function()
    local keys = {0x5A, 0x58, 0x43, 0x56}
    while not _G.FE_Unloaded do
        if dungeonActive() and S.dungeonFloat and S.dungeonUseMoves and Dungeon.targetingObjective and Dungeon.target then
            local tp = Dungeon.target:FindFirstChild("HumanoidRootPart") or Dungeon.target:FindFirstChildWhichIsA("BasePart")
            if tp then
                pcall(function()
                    local cam = Workspace.CurrentCamera
                    if cam then cam.CFrame = CFrame.lookAt(cam.CFrame.Position, tp.Position) end
                end)
                for _, vk in ipairs(keys) do
                    if not Dungeon.targetingObjective then break end
                    pcall(function() if keyclick then keyclick(vk) end end)
                    task.wait(0.2)
                end
            end
        end
        task.wait(0.3)
    end
end)

-- dungeon M1 (only hybrid)
task.spawn(function()
    while not _G.FE_Unloaded do
        if dungeonActive() and S.dungeonM1 then
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            local myHum = char and char:FindFirstChild("Humanoid")
            if myRoot and myHum and myHum.Health > 0 then
                local hits = {}
                local folder = Workspace:FindFirstChild("Enemies")
                local radius = S.dungeonM1Radius or 60
                if folder then
                    for _, enemy in ipairs(folder:GetChildren()) do
                        if (dungeonIsEnemy(enemy) or dungeonIsObjective(enemy)) and not dungeonIsSummon(enemy) then
                            local ep = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head") or enemy:FindFirstChildWhichIsA("BasePart")
                            if ep and (myRoot.Position - ep.Position).Magnitude <= radius then
                                hits[#hits + 1] = ep
                            end
                        end
                    end
                end
                if #hits > 0 then
                    pcall(function()
                        local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
                        if net then
                            local regAttack = net:FindFirstChild("RE/RegisterAttack") or net:FindFirstChild("RegisterAttack")
                            local regHit = net:FindFirstChild("RE/RegisterHit") or net:FindFirstChild("RegisterHit")
                            if regAttack then regAttack:FireServer(0) end
                            if regHit then
                                for _, part in ipairs(hits) do
                                    regHit:FireServer(part, {})
                                end
                            end
                        end
                    end)
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then pcall(function() tool:Activate() end) end
                end
            end
            task.wait(0.12)
        else
            task.wait(0.25)
        end
    end
end)

-- equip + buso
task.spawn(function()
    while not _G.FE_Unloaded do
        if dungeonActive() then
            pcall(dungeonAutoEquip)
            pcall(dungeonActivateBuso)
            task.wait(0.35)
        else
            task.wait(0.5)
        end
    end
end)

-- hitbox expander
task.spawn(function()
    local parts = {"HumanoidRootPart", "UpperTorso", "Torso", "Head", "LowerTorso"}
    while not _G.FE_Unloaded do
        if dungeonActive() and S.dungeonHitbox then
            local folder = Workspace:FindFirstChild("Enemies")
            local sz = S.dungeonHitboxSize or 50
            if folder then
                for _, e in ipairs(folder:GetChildren()) do
                    if (dungeonIsEnemy(e) or dungeonIsObjective(e)) and not dungeonIsSummon(e) then
                        for _, pName in ipairs(parts) do
                            local part = e:FindFirstChild(pName)
                            if part and part:IsA("BasePart") then
                                if not Dungeon.originalSizes[part] then
                                    Dungeon.originalSizes[part] = part.Size
                                end
                                pcall(function()
                                    part.Size = Vector3.new(sz, sz, sz)
                                    part.CanCollide = false
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        else
            if next(Dungeon.originalSizes) then dungeonRestoreHitboxes() end
            task.wait(0.4)
        end
    end
    dungeonRestoreHitboxes()
end)




task.spawn(function()
    local t0 = os.clock()
    while not workspace.CurrentCamera and os.clock() - t0 < 15 do
        task.wait(0.1)
    end
    local okLib, Lib = pcall(function()
        local src = game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua")
        src = src:gsub(
            "Camera = workspace%.CurrentCamera",
            "Camera = workspace.CurrentCamera\n" ..
            "local function INS_SafeViewport()\n" ..
            "  local c = workspace.CurrentCamera\n" ..
            "  if c then Camera = c end\n" ..
            "  c = Camera\n" ..
            "  if c then\n" ..
            "    local ok, vs = pcall(function() return c.ViewportSize end)\n" ..
            "    if ok and vs then return vs end\n" ..
            "  end\n" ..
            "  return Vector2.new(1920, 1080)\n" ..
            "end",
            1
        )
        src = src:gsub("Camera%.ViewportSize", "INS_SafeViewport()")
        local fn, err = loadstring(src)
        if not fn then error(err or "INS-ui compile failed") end
        return fn() or INSUI
    end)
    if not okLib or type(Lib) ~= "table" then
        warn("[Hub] INS UI not loaded", Lib)
        return
    end
    LibRef = Lib
    pcall(function()
        if Lib.SetKeybindOverlay then Lib:SetKeybindOverlay(false) end
        if Lib.SetMenuKey then Lib:SetMenuKey("f1") end
    end)
    pcall(function()
        if Lib.SetMenuKey then Lib:SetMenuKey("f1") end
    end)
    local win = Lib:CreateWindow({
        title = "BF Hub",
        subtitle = "Blox Fruits",
        size = Vector2.new(940, 700),
        menuKey = "f1",
        checkboxStyle = true,
        opacity = 0.97,
        keybindOverlay = false,
        autoSave = true,
        configName = "default",
        configFolder = "BFHub",
    })
    WinRef = win
    menuOpen = true
    local function tip(handle, text)
        if handle and text then
            pcall(function() handle:Tooltip(text) end)
        end
        return handle
    end
    Lib:Category("VISUALS")
    local espTab = win:Tab("ESP", "eye")
    local espSec = espTab:Section("Main", "Left")
    H.master = tip(espSec:Toggle("Enabled", true, function(on) Features.master = on end, "master switch for overlays"), "master switch for overlays")
    espSec:Divider("Toggles")
    H.esp = tip(espSec:Toggle("Fruit ESP", true, function(on) Features.esp = on end, "labels above fruits"), "labels above fruits")
    H.berryEsp = tip(espSec:Toggle("Berry ESP", false, function(on)
        Features.berryEsp = on
        if not on then
            clearAllBerryESP()
        else
            task.spawn(function()
                refreshBerries(true)
            end)
        end
    end, "berry spheres on bushes (red)"), "berry spheres on bushes (red)")
    tip(espSec:Toggle("Flower ESP", false, function(v)
        setMyth("flowerEsp", v)
        if v then pcall(buildFlowerEsp) else pcall(clearFlowerEsp) end
    end, "Shows a label and a 3d box around all flowers, 2ND SEA"), "Shows a label and a 3d box around all flowers, 2ND SEA")
    tip(espSec:Toggle("Chest ESP", false, function(v)
        setMyth("chestEsp", v)
        if v then pcall(buildChestEspLabels) else pcall(clearChestEspLabels) end
    end, "Shows a text label on every spawned chest"), "Shows a text label on every spawned chest")
    tip(espSec:Toggle("Boat ESP", false, function(v)
        setMyth("boatEsp", v)
        if v then pcall(buildBoatEsp) else pcall(clearBoatEsp) end
    end, "Draws a full 3D box around each on-screen boat"), "Draws a full 3D box around each on-screen boat")
    tip(espSec:Toggle("Mirage ESP", false, function(v)
        setMyth("mirageEsp", v)
        if not v then pcall(clearMirageEsp) end
    end, "Shows the Mirage Island location"), "Shows the Mirage Island location")
    H.panel = tip(espSec:Toggle("Status Panel", true, function(on) Features.panel = on end, "server status overlay"), "server status overlay")
    local panelTab = win:Tab("Panel", "map")
    local posSec = panelTab:Section("Position", "Left")
    tip(posSec:Slider("Panel X", 50, 50, 0, 3000, "", function(v) panelPosX = v; layoutPanel(panelShown, 0) end), "horizontal position of status panel")
    tip(posSec:Slider("Panel Y", 400, 20, 0, 1500, "", function(v) panelPosY = v; layoutPanel(panelShown, 0) end), "vertical position of status panel")
    local styleSec = panelTab:Section("Style", "Right")
    tip(styleSec:Slider("Text size", 13, 1, 10, 22, "", function(v) panelTextSize = v; applyPanelSize() end), "status panel text size")
    Lib:Category("FARMING")
    local farmTab = win:Tab("Farm", "sword")
    local farmSec = farmTab:Section("Farming", "Left")
    tip(farmSec:Toggle("Auto Farm Nearest", false, function(v) setMyth("autoFarmNearest", v) end, "Farms the nearest enemy (load chests/enemies first!)"), "Farms the nearest enemy (load chests/enemies first!)")
    tip(farmSec:Toggle("Remote Mode (60 studs)", false, function(v) setMyth("remoteMode", v) end, "Use RegisterHit remotes instead of mouse clicks (60 studs)"), "Use RegisterHit remotes instead of mouse clicks (60 studs)")
    tip(farmSec:Toggle("Auto Farm Chest", false, function(v)
        setMyth("autoFarming", v)
        if type(S) == "table" and v then S.chestIndex = 1 end
    end, "Tween between chest models"), "Tween between chest models")
    tip(farmSec:Toggle("Auto Farm Fruits", false, function(v) setMyth("autoFruits", v) end, "Tween to nearest spawned fruit"), "Tween to nearest spawned fruit")
    tip(farmSec:Toggle("Auto TP To Fruit", false, function(v) setMyth("autoTpFruit", v) end, "Instant teleport on top of nearest fruit"), "Instant teleport on top of nearest fruit")
    local npcSec = farmTab:Section("NPC Farm", "Right")
    tip(npcSec:Toggle("Auto NPC Farm", false, function(v) setMyth("autoNpcFarm", v) end, "Go to selected NPC Island and farm NPCs there"), "Go to selected NPC Island and farm NPCs there")
    local isleOpts = {}
    if type(islandNames) == "table" and #islandNames > 0 then
        for _, n in ipairs(islandNames) do isleOpts[#isleOpts + 1] = n end
    elseif type(islandList) == "table" then
        for _, isle in pairs(islandList) do isleOpts[#isleOpts + 1] = isle.name end
    end
    if #isleOpts == 0 then
        isleOpts = {"Tiki2", "Tiki1", "Port", "Hydra1", "Hydra2", "Hydra3", "GreatTree1", "GreatTree2", "HauntedCastle", "IceCream", "CakeLand", "Chocolate", "Peanut", "Mansion", "TurtleCenter2", "TurtleCenter1", "TurtleEntrance"}
    end
    local defaultIsle = isleOpts[1]
    local ddIsle = npcSec:Dropdown("NPC Island", { defaultIsle }, isleOpts, false, function(v)
        local name = v
        if type(v) == "table" then name = v[1] or v.Value or tostring(v) end
        name = tostring(name)
        if type(islandList) ~= "table" then return end
        for i, isle in pairs(islandList) do
            if isle.name == name then
                setMyth("selectedIsland", i)
                break
            end
        end
    end)
    tip(ddIsle, "Select which island to farm NPCs on")
    pcall(function()
        if ddIsle and ddIsle.UpdateChoices then ddIsle:UpdateChoices(isleOpts) end
        if ddIsle and ddIsle.Set then ddIsle:Set({ defaultIsle }) end
    end)
    tip(npcSec:Toggle("Auto Farm Level", false, function(v) setMyth("autoFarmLevel", v) end, "Farms mobs based on your current level (quest giver must be nearby)"), "Farms mobs based on your current level (quest giver must be nearby)")
    local offSec = farmTab:Section("Custom NPC Offset", "Left")
    tip(offSec:Toggle("Custom NPC Offset", false, function(v) setMyth("customOffset", v) end, "Use custom XYZ offset when positioning on NPCs"), "Use custom XYZ offset when positioning on NPCs")
    tip(offSec:Slider("Offset X", 0, 1, -100, 100, "", function(v) setMyth("customOffsetX", v) end), "X offset from enemy position")
    tip(offSec:Slider("Offset Y", 23, 1, -100, 100, "", function(v) setMyth("customOffsetY", v) end), "Y offset from enemy position")
    tip(offSec:Slider("Offset Z", 0, 1, -100, 100, "", function(v) setMyth("customOffsetZ", v) end), "Z offset from enemy position")
    local bossSec = farmTab:Section("Boss / Material / Sea", "Right")
    tip(bossSec:Toggle("Auto Mastery", false, function(v) setMyth("autoMastery", v) end, "Goto Chocolate Island and use Buddha transformation"), "Goto Chocolate Island and use Buddha transformation")
    tip(bossSec:Toggle("Auto Farm Material", false, function(v) setMyth("autoMaterial", v) end, "Farms enemies that drop the selected material"), "Farms enemies that drop the selected material")
    local ddMat = bossSec:Dropdown("Material", { S.materialTarget or MATERIAL_NAMES[1] }, MATERIAL_NAMES, false, function(v)
        local name = v
        if type(v) == "table" then name = v[1] or v.Value or tostring(v) end
        setMyth("materialTarget", tostring(name))
    end)
    tip(ddMat, "Material to farm")
    tip(bossSec:Toggle("Auto Farm Boss", false, function(v) setMyth("autoBoss", v) end, "Tweens to and farms the selected spawned boss"), "Tweens to and farms the selected spawned boss")
    local seaBosses = bossesForCurrentSea()
    local defaultBoss = S.bossTarget
    local inSea = false
    for _, n in ipairs(seaBosses) do if n == defaultBoss then inSea = true; break end end
    if not inSea then defaultBoss = seaBosses[1] or BOSS_NAMES[1]; setMyth("bossTarget", defaultBoss) end
    local ddBoss = bossSec:Dropdown("Boss", { defaultBoss }, seaBosses, false, function(v)
        local name = v
        if type(v) == "table" then name = v[1] or v.Value or tostring(v) end
        setMyth("bossTarget", tostring(name))
    end)
    tip(ddBoss, "Bosses for current sea only (must be spawned/loaded)")
    tip(bossSec:Toggle("Auto Farm Sea Target", false, function(v) setMyth("autoSeaEvent", v) end, "Tweens to and attacks the selected spawned sea enemy"), "Tweens to and attacks the selected spawned sea enemy")
    local ddSea = bossSec:Dropdown("Sea Target", { S.seaEventTarget or SEA_EVENT_NAMES[1] }, SEA_EVENT_NAMES, false, function(v)
        local name = v
        if type(v) == "table" then name = v[1] or v.Value or tostring(v) end
        setMyth("seaEventTarget", tostring(name))
    end)
    tip(ddSea, "Sea event enemy")
    local statSec = farmTab:Section("Stats / Weapon", "Left")
    tip(statSec:Toggle("Auto Melee", false, function(v) setMyth("autoStatMelee", v) end, "Spend points into Melee"), "Spend points into Melee")
    tip(statSec:Toggle("Auto Defense", false, function(v) setMyth("autoStatDefense", v) end, "Spend points into Defense"), "Spend points into Defense")
    tip(statSec:Toggle("Auto Sword", false, function(v) setMyth("autoStatSword", v) end, "Spend points into Sword"), "Spend points into Sword")
    tip(statSec:Toggle("Auto Gun", false, function(v) setMyth("autoStatGun", v) end, "Spend points into Gun"), "Spend points into Gun")
    tip(statSec:Toggle("Auto Fruit", false, function(v) setMyth("autoStatFruit", v) end, "Spend points into Demon Fruit"), "Spend points into Demon Fruit")
    tip(statSec:Slider("Points Per Upgrade", S.statAmount or 10, 1, 1, 50, "", function(v) setMyth("statAmount", v) end), "Points per AddPoint call")
    tip(statSec:Toggle("Weapon After Fruit", false, function(v) setMyth("weaponAfterFruit", v) end, "Switch to melee/sword after collecting a fruit"), "Switch to melee/sword after collecting a fruit")
    tip(statSec:Toggle("Weapon: Melee (off=Sword)", true, function(v)
        setMyth("weaponSlot", v and "Melee" or "Sword")
    end, "ON = Melee slot1, OFF = Sword slot3"), "ON = Melee slot1, OFF = Sword slot3")
    local speedSec = farmTab:Section("Tween Speeds", "Right")
    tip(speedSec:Slider("Farm Speed", S.FARM_SPEED or 250, 10, 50, 1000, "", function(v)
        setMyth("FARM_SPEED", v)
        if type(AFL) == "table" then AFL.tweenSpeed = v end
    end), "General farm tween speed")
    tip(speedSec:Slider("Chest Speed", S.CHEST_SPEED or 310, 10, 50, 1000, "", function(v) setMyth("CHEST_SPEED", v) end), "Chest farm tween speed")
    tip(speedSec:Slider("Fruit Speed", S.FRUIT_SPEED or 210, 10, 50, 1000, "", function(v) setMyth("FRUIT_SPEED", v) end), "Fruit farm tween speed")
    tip(speedSec:Slider("NPC Speed", S.NPC_TWEEN_SPEED or 250, 10, 50, 1000, "", function(v) setMyth("NPC_TWEEN_SPEED", v) end), "NPC travel speed")
    tip(speedSec:Slider("Raid Speed", S.RAID_SPEED or 200, 10, 50, 1000, "", function(v) setMyth("RAID_SPEED", v) end), "Raid island tween speed")
    tip(speedSec:Slider("Mastery Speed", S.MASTERY_SPEED or 250, 10, 50, 1000, "", function(v) setMyth("MASTERY_SPEED", v) end), "Mastery tween speed")
    Lib:Category("COMBAT")
    local combatTab = win:Tab("Combat", "crosshair")
    local combatSec = combatTab:Section("Combat", "Left")
    tip(combatSec:Toggle("Big Hitbox", false, function(v) setMyth("bigHitbox", v) end, "Enlarge enemy hitboxes while farming"), "Enlarge enemy hitboxes while farming")
    tip(combatSec:Toggle("Pull Enemies", false, function(v) setMyth("pullEnemies", v) end, "Pull nearby enemies toward you"), "Pull nearby enemies toward you")
    tip(combatSec:Toggle("Buddha Pull", false, function(v) setMyth("buddhaPull", v) end, "Buddha fruit pull variant"), "Buddha fruit pull variant")
    tip(combatSec:Toggle("Auto Ken", false, function(v) setMyth("autoKen", v) end, "Auto Observation Haki"), "Auto Observation Haki")
    tip(combatSec:Toggle("Auto Haki", false, function(v) setMyth("autoHaki", v) end, "Automatically keeps Armament Haki active"), "Automatically keeps Armament Haki active")
    tip(combatSec:Toggle("Auto Race Ability", false, function(v) setMyth("autoRaceAbility", v) end, "Keeps sending the race ability activation remote"), "Keeps sending the race ability activation remote")
    tip(combatSec:Toggle("Freeze Position", false, function(v) setMyth("freezePos", v) end, "Lock your character position"), "Lock your character position")
    tip(combatSec:Toggle("Freeze Enemies", false, function(v) setMyth("freezeEnemies", v) end, "Freeze enemy positions"), "Freeze enemy positions")
    tip(combatSec:Toggle("Auto TP Ember", false, function(v) setMyth("teleportEmber", v) end, "Teleport to Ember template"), "Teleport to Ember template")
    tip(combatSec:Toggle("Auto Tween Dragon Ember", false, function(v) setMyth("tweenEmber", v) end, "Smooth tween to Workspace EmberTemplate objects"), "Smooth tween to Workspace EmberTemplate objects")
    tip(combatSec:Toggle("Goto Kitsune Island", false, function(v) setMyth("teleportKitsune", v) end, "Teleport to Kitsune island"), "Teleport to Kitsune island")
    local skillSec = combatTab:Section("Skill Combos", "Right")
    tip(skillSec:Toggle("Flame R to C", false, function(v) setMyth("flameRToC", v) end, "FLAME: when you flashstep (R) = Flame C move"), "FLAME: when you flashstep (R) = Flame C move")
    tip(skillSec:Toggle("R to X", false, function(v) setMyth("rToX", v) end, "Automatically taps X when you press R"), "Automatically taps X when you press R")
    tip(skillSec:Toggle("R to X then Z", false, function(v) setMyth("rToXThenZ", v) end, "Taps X when you press R, waits 25ms, then taps Z"), "Taps X when you press R, waits 25ms, then taps Z")
    local pullSec = combatTab:Section("Custom Pull", "Right")
    tip(pullSec:Toggle("Custom Pull", false, function(v) setMyth("customPull", v) end, "Use custom pull offsets"), "Use custom pull offsets")
    tip(pullSec:Slider("Pull X Offset", 0, 1, -100, 100, "", function(v) setMyth("customPullX", v) end), "Custom pull X")
    tip(pullSec:Slider("Pull Y Offset", -10, 1, -100, 100, "", function(v) setMyth("customPullY", v) end), "Custom pull Y")
    tip(pullSec:Slider("Pull Z Offset", 0, 1, -100, 100, "", function(v) setMyth("customPullZ", v) end), "Custom pull Z")
    local m1Sec = combatTab:Section("M1 Aura", "Left")
    H.aura = tip(m1Sec:Toggle("M1 Aura", false, function(on)
        Features.aura = on
        AuraEnabled = on
        aura.enabled = on == true
        if on then
            local ok = aura_ensureRemotes()
        else
        end
        updateHUD()
    end, "crashable on Matcha"), "crashable on Matcha")
    K.aura = m1Sec:Keybind("Aura key", nil, function(v)
        if isMouseBind(v) then return end
    end)
    tip(m1Sec:Slider("M1 Range", 100, 5, 10, 500, "studs", function(v)
        AuraConfig.MAX_DISTANCE = v
        aura.maxDist = v
    end), "Max distance to hit NPCs")

    pcall(function()
        if m1Sec.Label then m1Sec:Label("  crashable on Matcha") end
    end)
    local glitchTab = win:Tab("Glitch", "zap")
    local glitchSec = glitchTab:Section("Velocity Boosts", "Left")
    tip(glitchSec:Toggle("Sanguine Z Boost", false, function(v) setMyth("sanguineZ", v) end, "Boosts current velocity during Sanguine Art Z"), "Boosts current velocity during Sanguine Art Z")
    tip(glitchSec:Toggle("Dragon Talon Z Boost", false, function(v) setMyth("dragonTalonZ", v) end, "Boosts current velocity after pressing Z"), "Boosts current velocity after pressing Z")
    tip(glitchSec:Toggle("Yama Z Boost", false, function(v) setMyth("yamaZ", v) end, "Boosts current velocity after pressing Z"), "Boosts current velocity after pressing Z")
    tip(glitchSec:Toggle("Tushita X Boost", false, function(v) setMyth("tushitaX", v) end, "Boosts current velocity after pressing X"), "Boosts current velocity after pressing X")
    tip(glitchSec:Toggle("Fox Lamp X Boost", false, function(v) setMyth("foxLampX", v) end, "Boosts current velocity after pressing X"), "Boosts current velocity after pressing X")
    tip(glitchSec:Toggle("Soul Guitar M1", false, function(v) setMyth("soulGuitarM1", v) end, "Boosts after Q + M1 within 0.5 seconds"), "Boosts after Q + M1 within 0.5 seconds")
    tip(glitchSec:Toggle("Diamond M1", false, function(v) setMyth("diamondM1", v) end, "Sanguine-style boost when M1 is released with Diamond-Diamond equipped"), "Sanguine-style boost when M1 is released with Diamond-Diamond equipped")
    tip(glitchSec:Toggle("Flame F Boost", false, function(v) setMyth("flameF", v) end, "Boosts current velocity after pressing F"), "Boosts current velocity after pressing F")
    local glitchTuneSec = glitchTab:Section("Glitch Sliders", "Right")
    local glitchTuneOpts = {"sanguine","dragonTalon","yama","tushita","foxLamp","soulGuitar","diamond","flame"}
    local glitchSliderHandles = {speed=nil, delay=nil, duration=nil}
    local function currentGlitchProfile()
        local key = S.glitchTune or "sanguine"
        return S.glitchSettings[key] or S.glitchSettings.sanguine
    end
    local function syncGlitchSliders()
        local g = currentGlitchProfile()
        if not g then return end
        pcall(function()
            if glitchSliderHandles.speed and glitchSliderHandles.speed.Set then glitchSliderHandles.speed:Set(g.speed or 500) end
            if glitchSliderHandles.delay and glitchSliderHandles.delay.Set then glitchSliderHandles.delay:Set(math.floor((g.delay or 0.1)*100 + 0.5)) end
            if glitchSliderHandles.duration and glitchSliderHandles.duration.Set then glitchSliderHandles.duration:Set(math.floor((g.duration or 0.3)*100 + 0.5)) end
        end)
    end
    local ddGlitch = glitchTuneSec:Dropdown("Glitch Target", { S.glitchTune or "sanguine" }, glitchTuneOpts, false, function(v)
        local name = v
        if type(v) == "table" then name = v[1] or v.Value or tostring(v) end
        setMyth("glitchTune", tostring(name))
        syncGlitchSliders()
    end)
    tip(ddGlitch, "Which glitch the sliders edit (each has its own speed/delay/duration)")
    glitchSliderHandles.speed = glitchTuneSec:Slider("Speed", (S.glitchSettings[S.glitchTune or "sanguine"] or {}).speed or 500, 10, 100, 1500, "", function(v)
        local g = currentGlitchProfile()
        if g then g.speed = v end
    end)
    tip(glitchSliderHandles.speed, "Velocity boost speed for selected glitch only")
    glitchSliderHandles.delay = glitchTuneSec:Slider("Start Delay", math.floor(((S.glitchSettings[S.glitchTune or "sanguine"] or {}).delay or 0.1)*100 + 0.5), 1, 0, 50, "x0.01s", function(v)
        local g = currentGlitchProfile()
        if g then g.delay = v / 100 end
    end)
    tip(glitchSliderHandles.delay, "Delay before boost starts (selected glitch only)")
    glitchSliderHandles.duration = glitchTuneSec:Slider("Duration", math.floor(((S.glitchSettings[S.glitchTune or "sanguine"] or {}).duration or 0.3)*100 + 0.5), 1, 5, 100, "x0.01s", function(v)
        local g = currentGlitchProfile()
        if g then g.duration = v / 100 end
    end)
    tip(glitchSliderHandles.duration, "How long the boost lasts (selected glitch only)")
    Lib:Category("SEA")
    local seaTab = win:Tab("Sea", "globe")
    local seaSec = seaTab:Section("Boat", "Left")
    tip(seaSec:Toggle("Boat Fly", false, function(v) setMyth("boatFlyEnabled", v) end, "Fly the boat with WASD / X / Shift"), "Fly the boat with WASD / X / Shift")
    tip(seaSec:Slider("Fly Speed", 5, 1, 1, 50, "", function(v) setMyth("boatFlySpeed", v) end), "Boat fly speed")
    local dOpts = {}
    if type(dangerLevelNames) == "table" and #dangerLevelNames > 0 then
        for _, n in ipairs(dangerLevelNames) do dOpts[#dOpts + 1] = n end
    elseif type(dangerLevels) == "table" then
        for _, d in pairs(dangerLevels) do dOpts[#dOpts + 1] = d.name end
    end
    if #dOpts == 0 then
        dOpts = {"Level 1", "Level 2", "Level 3", "Level 4", "Level 5", "Level 6"}
    end
    local defaultDanger = dOpts[1]
    local ddDanger = seaSec:Dropdown("Danger Level", { defaultDanger }, dOpts, false, function(v)
        local name = v
        if type(v) == "table" then name = v[1] or v.Value or tostring(v) end
        name = tostring(name)
        if type(dangerLevels) ~= "table" then return end
        for _, d in pairs(dangerLevels) do
            if d.name == name then
                setMyth("boatTweening", false)
                task.wait(0.05)
                task.spawn(function()
                    if type(boatTweenTo) == "function" then
                        boatTweenTo(d.pos)
                    end
                end)
                break
            end
        end
    end)
    tip(ddDanger, "Fly boat to selected danger level")
    pcall(function()
        if ddDanger and ddDanger.UpdateChoices then ddDanger:UpdateChoices(dOpts) end
        if ddDanger and ddDanger.Set then ddDanger:Set({ defaultDanger }) end
    end)
    tip(seaSec:Button("Stop Boat", function()
        setMyth("boatTweening", false)
    end), "Stop current boat tween")
    local seatSec = seaTab:Section("Boat Seat", "Right")
    tip(seatSec:Toggle("Auto Go To Seat", false, function(v)
        setMyth("autoBoatSeat", v)
        if v then pcall(refreshBoatSeats) end
        notify(v and "Auto Boat Seat ON!" or "Auto Boat Seat OFF!", "Sea", 2)
    end, "Teleports to the selected seat until you are sitting"), "Teleports to the selected seat until you are sitting")
    pcall(refreshBoatSeats)
    local seatOpts = boatSeatOptions or {"No boats found"}
    local ddSeat = seatSec:Dropdown("Boat Seat", { seatOpts[1] }, seatOpts, false, function(v)
        local name = v
        if type(v) == "table" then name = v[1] or v.Value or tostring(v) end
        name = tostring(name)
        S.selectedBoatSeatLabel = name
        S.selectedBoatSeat = boatSeatByLabel[name]
    end)
    boatSeatDropdownHandle = ddSeat
    tip(ddSeat, "Select a spawned boat seat")
    tip(seatSec:Button("Refresh Boat Seats", function()
        lastBoatSeatSignature = "" -- force UI update
        local names = refreshBoatSeats() or boatSeatOptions
        notify("Seats: " .. tostring(#names), "Sea", 2)
    end), "Rescan Workspace.Boats now")
    local raidSec = seaTab:Section("Games", "Right")
    tip(raidSec:Toggle("Auto Raid", false, function(v) setMyth("autoRaid", v) end, "Scans for RaidMap, teleports to center and pulls enemies"), "Scans for RaidMap, teleports to center and pulls enemies")
    tip(raidSec:Toggle("Tween to Mirage", false, function(v) setMyth("autoMirageTween", v) end, "Tweens above Mirage Island when it exists"), "Tweens above Mirage Island when it exists")
    tip(raidSec:Toggle("Collect Mirage Gear", false, function(v) setMyth("autoMirageGear", v) end, "Finds and tweens to the visible Mirage gear"), "Finds and tweens to the visible Mirage gear")
    local worldSec = seaTab:Section("World Checks", "Left")
    tip(worldSec:Button("Check Event Islands", function()
        task.spawn(showEventStatus)
    end), "Mirage / Kitsune / Prehistoric / Frozen")
    tip(worldSec:Button("Check Important Bosses", function()
        task.spawn(showBossStatus)
    end), "Rip Indra / Dough King / Cake Prince")
    Lib:Category("PVP")
    local pvpTab = win:Tab("PvP", "skull")
    local pvpSec = pvpTab:Section("Pull / Aura", "Left")
    tip(pvpSec:Toggle("Escape (risky)", false, function(v) setMyth("voidPull", v) end, "Sends you to Y=100000"), "Sends you to Y=100000")
    tip(pvpSec:Toggle("Go Back Down (risky)", false, function(v) setMyth("skyPull", v) end, "Brings you back to Y=100"), "Brings you back to Y=100")
    tip(pvpSec:Toggle("PvP Aura", false, function(v) _pvpAuraEnabled = v end, "Fires RegisterHit on the nearest player"), "Fires RegisterHit on the nearest player")
    tip(pvpSec:Toggle("PvP Farm Loop", false, function(v) setMyth("pvpFarmLoop", v) end, "Tween to nearest enemy player and farm"), "Tween to nearest enemy player and farm")
    tip(pvpSec:Toggle("Use ModelHitbox", false, function(v) _pvpAuraAltPart = v end, "Toggle between Head and ModelHitbox hit part"), "Toggle between Head and ModelHitbox hit part")
    tip(pvpSec:Slider("PvP Range", 100, 10, 10, 300, "studs", function(v) _pvpAuraMaxDist = v end), "Max distance to target players")
    Lib:Category("AUTOMATION")
    local fishTab = win:Tab("Fish", "zap")
    local fishSec = fishTab:Section("Auto Fish", "Left")
    H.fish = tip(fishSec:Toggle("Auto Fish", false, function(on)
        Features.fish = on
        if on then FishStart() else FishStop() end
    end, "Automatically casts, detects bite, reels (treasure priority)"), "Automatically casts, detects bite, reels (treasure priority)")
    K.fish = fishSec:Keybind("Fish key", nil, function(v)
        if isMouseBind(v) then return end
    end)
    local fishTune = fishTab:Section("Tuning", "Right")
    tip(fishTune:Slider("Cast power", FishConfig.CastTarget * 100, 1, 50, 100, "%", function(v) FishConfig.CastTarget = v / 100 end), "Release cast when bar reaches this fill")
    tip(fishTune:Slider("Reel dead zone", FishConfig.DeadZone * 100, 1, 0, 200, "%", function(v) FishConfig.DeadZone = v / 100 end), "Hold/release threshold vs fish/treasure")
    tip(fishTune:Slider("Bite timeout", FishConfig.BiteTimeout, 1, 5, 60, "s", function(v) FishConfig.BiteTimeout = v end), "Reset if no bite within this time")
    local repairTab = win:Tab("Repair", "cog")
    local repairSec = repairTab:Section("Auto Repair", "Left")
    H.repair = tip(repairSec:Toggle("Auto Repair", false, function(on)
        Features.repair = on
        if on then RepStart() else RepStop() end
    end, "Auto hold/release ship repair minigame on green zone"), "Auto hold/release ship repair minigame on green zone")
    K.repair = repairSec:Keybind("Repair key", nil, function(v)
        if isMouseBind(v) then return end
    end)
K.menu = nil

pcall(function()
    local menuSec = win:SettingsSection("Interface", "Left")
    if menuSec then
        K.menu = menuSec:Keybind("Menu key", "F1", function(v)
            if isMouseBind(v) then return end
        end)
    end
end)

if not K.menu then
    local sTab = win:Tab("Settings", "gear")
    local sSec = sTab:Section("Interface", "Left")
    K.menu = sSec:Keybind("Menu key", "F1", function(v)
        if isMouseBind(v) then return end
    end)
end

pcall(function()
    if WinRef and WinRef.SetMenuKey then WinRef:SetMenuKey("F1") end
    if LibRef and LibRef.SetMenuKey then LibRef:SetMenuKey("F1") end
end)
    
    local dungeonTab = win:Tab("Dungeon", "map")
    local dMain = dungeonTab:Section("Dungeon Farm", "Left")
    tip(dMain:Toggle("Enable Dungeon", false, function(v)
        setMyth("dungeonEnabled", v)
        if not v then
            setMyth("dungeonFloat", false)
            Dungeon.target = nil
        end
    end, "Master switch for 2nd sea dungeon module"), "Master switch for 2nd sea dungeon module")
    tip(dMain:Toggle("Magnet / Float", false, function(v)
        setMyth("dungeonFloat", v)
        if not v then Dungeon.target = nil end
    end, "Tween above target (vents/mobs)"), "Tween above target (vents/mobs)")
    tip(dMain:Toggle("Smart Door Path", true, function(v) setMyth("dungeonAutoDoor", v) end, "Fly to exit teleporter when island clear"), "Fly to exit teleporter when island clear")
    tip(dMain:Toggle("Destroy Vents First", true, function(v) setMyth("dungeonDestroyObj", v) end, "Priority: vents/shrines over mobs"), "Priority: vents/shrines over mobs")
    tip(dMain:Toggle("Skills on Vents Z/X/C/V", true, function(v) setMyth("dungeonUseMoves", v) end, "Spam skills while on objective"), "Spam skills while on objective")
    tip(dMain:Toggle("Dungeon Hitbox", false, function(v) setMyth("dungeonHitbox", v) end, "Expand enemy/objective hitboxes in dungeon"), "Expand enemy/objective hitboxes in dungeon")
    local dCombat = dungeonTab:Section("Combat", "Right")
    tip(dCombat:Toggle("Dungeon M1 Aura", true, function(v) setMyth("dungeonM1", v) end, "RegisterAttack/Hit in dungeon (Matcha hybrid/remotes)"), "RegisterAttack/Hit in dungeon")
    tip(dCombat:Toggle("Auto Buso", true, function(v) setMyth("dungeonBuso", v) end, "Auto Buso Haki"), "Auto Buso Haki")
    tip(dCombat:Toggle("Auto Equip", true, function(v) setMyth("dungeonAutoEquip", v) end, "Keep melee/sword equipped"), "Keep melee/sword equipped")
    tip(dCombat:Toggle("Weapon: Melee (off=Sword)", true, function(v)
        setMyth("dungeonWeapon", v and "Melee" or "Sword")
    end, "ON = Melee slot1, OFF = Sword slot3"), "ON = Melee slot1, OFF = Sword slot3")
    tip(dCombat:Slider("M1 Radius", 60, 5, 20, 120, "studs", function(v) setMyth("dungeonM1Radius", v) end), "Dungeon M1 reach")
    tip(dCombat:Slider("Flight Speed", 250, 50, 100, 750, "", function(v) setMyth("dungeonFlightSpeed", v) end), "Tween speed")
    tip(dCombat:Slider("Hover Height", 12, 1, 5, 30, "studs", function(v) setMyth("dungeonFloatHeight", v) end), "Height above target")
    tip(dCombat:Slider("Hitbox Size", 50, 5, 10, 120, "", function(v) setMyth("dungeonHitboxSize", v) end), "Expanded hitbox size")


    local unloadSec = win:Tab("Unload", "trash"):Section("Danger", "Full")
    unloadSec:Button("Unload Hub", function()
        Lib:Dialog({
            title = "Unload?",
            text = "Stop all modules?",
            confirm = "Unload",
            onConfirm = function()
                _G.FE_Unloaded = true
                FishStop(); RepStop(); AuraEnabled = false
                pcall(dungeonStop)
                if type(S) == "table" then
                    for k, v in pairs(S) do
                        if type(v) == "boolean" then S[k] = false end
                    end
                end
                _pvpAuraEnabled = false
                if espConn then pcall(function() espConn:Disconnect() end) end
                pcall(berryUnhook)
                for _, d in pairs(_G.FruitStatusDrawings) do pcall(function() d:Remove() end) end
                _G.FruitStatusDrawings = {}
                for obj, data in pairs(_G.FruitESP) do
                    pcall(function() data.Text:Remove() end)
                    _G.FruitESP[obj] = nil
                end
                pcall(clearChestEspLabels)
                pcall(clearBoatEsp)
                pcall(clearFlowerEsp)
                pcall(clearMirageEsp)
                pcall(clearBerryEspLabels)
                pcall(clearChamBoxes)
                pcall(clearEspLabels)
                pcall(mouse1release)
                pcall(function() Lib:Destroy() end)
            end,
        })
    end):SetRisk()
    task.spawn(function()
        while not _G.FE_Unloaded do
            do
                local key = getBindKey(K.menu)
                if not key then key = "f1" end
                local down = isDown(key) or isDown("f1")
                if key ~= "f1" then
                    down = isDown(key)
                end
                if down and not lastDown.menu then
                    menuOpen = not menuOpen
                    pcall(function()
                        if WinRef and WinRef.SetOpen then
                            WinRef:SetOpen(menuOpen)
                        elseif LibRef and LibRef.SetOpen then
                            LibRef:SetOpen(menuOpen)
                        elseif WinRef and WinRef.SetVisible then
                            WinRef:SetVisible(menuOpen)
                        end
                    end)
                end
                lastDown.menu = down
            end
            do
                local key = getBindKey(K.fish)
                local down = key ~= nil and isDown(key)
                if down and not lastDown.fish then
                    toggleFeature("fish", function(on) if on then FishStart() else FishStop() end end)
                end
                lastDown.fish = down
            end
            do
                local key = getBindKey(K.repair)
                local down = key ~= nil and isDown(key)
                if down and not lastDown.repair then
                    toggleFeature("repair", function(on) if on then RepStart() else RepStop() end end)
                end
                lastDown.repair = down
            end
            do
                local key = getBindKey(K.aura)
                local down = key ~= nil and isDown(key)
                if down and not lastDown.aura then
                    toggleFeature("aura", function(on)
                        AuraEnabled = on
                        aura.enabled = on == true
                        updateHUD()
                    end)
                end
                lastDown.aura = down
            end
            task.wait(0.03)
        end
    end)
    pcall(function()
        if Lib.SetKeybindOverlay then Lib:SetKeybindOverlay(false) end
        if Lib.SetMenuKey then Lib:SetMenuKey("F1") end
        if WinRef and WinRef.SetMenuKey then WinRef:SetMenuKey("F1") end
    end)

    pcall(function() Lib:Notify("BF Hub", "Loaded", 3, "success") end)
end)
print("[BF Hub] Loaded")
