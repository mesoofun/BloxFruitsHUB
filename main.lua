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
local SEA2_ID   = 4442272183
local SEA3_ID_A = 7449423635
local SEA3_ID_B = 100117331123089
local currentPlaceId = game.PlaceId
local function isSea1() return currentPlaceId == SEA1_ID end
local function isSea2() return currentPlaceId == SEA2_ID end
local function isSea3() return currentPlaceId == SEA3_ID_A or currentPlaceId == SEA3_ID_B end
local SEA_NAMES = {
    [SEA1_ID] = "First Sea", [SEA2_ID] = "Second Sea",
    [SEA3_ID_A] = "Third Sea", [SEA3_ID_B] = "Third Sea",
}
pcall(function() setrobloxinput(true) end)
_G.FE_Unloaded = false
local Features = { master=true, esp=true, panel=true, fish=false, repair=false, aura=false }
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
local function getBindKey(handle)
    if not handle then return nil end
    local ok,v = pcall(function() return handle:Get() end)
    if not ok or v==nil then return nil end
    if type(v)=="table" then return normKey(v.Key or v.key or v[1] or v.Value or v.value) end
    return normKey(v)
end
local K, H = {}, {}
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
    print("[AutoFish] Reset:", reason)
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
                    wasOpen=false; print("[AutoFish] Cast done, waiting bite...")
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
                print("[AutoFish] Bite detected!")
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
                        FishState.ReelingStarted=true; print("[AutoFish] Reeling started")
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
    task.spawn(FishMainLoop); print("[AutoFish] Started")
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
    print("[AutoRepair] Started")
    while RepState.Running do
        local info=getBarInfo()
        if info then
            RepHold()
            if isInGreenZone(info) then
                RepRelease(); print("[AutoRepair] Released in green"); task.wait(0.35)
            end
        else RepRelease() end
        task.wait(0.02)
    end
    RepRelease(); print("[AutoRepair] Stopped")
end
local function RepStart()
    if RepState.Running then return end
    RepState.Running=true; task.spawn(RepMainLoop)
end
local function RepStop()
    RepState.Running=false; RepRelease()
end
local AuraConfig={MAX_DISTANCE=100, MIN_DISTANCE=1, SESSION_ID="32501259"}
local AuraEnabled=false
local AuraTargetCount=0
local AuraFirstTargetName="None"
local RegisterAttack, RegisterHit
do
    local Net=ReplicatedStorage:FindFirstChild("Modules")
    if Net then Net=Net:FindFirstChild("Net") end
    if Net then
        RegisterAttack=Net:FindFirstChild("RE/RegisterAttack")
        RegisterHit=Net:FindFirstChild("RE/RegisterHit")
    end
end
local hudText=Drawing.new("Text")
hudText.Size=18; hudText.Font=Drawing.Fonts.SystemBold or 2
hudText.Color=Color3.fromRGB(255,255,255); hudText.Outline=true
hudText.Position=Vector2.new(10,50); hudText.Visible=false; hudText.Text="Targets: 0 | OFF"
local function updateHUD()
    hudText.Text=string.format("Targets: %d (%s) | %s", AuraTargetCount, AuraFirstTargetName, AuraEnabled and "ON" or "OFF")
    pcall(function() hudText.Visible=AuraEnabled end)
end
local function getTargetPart(enemy)
    if not enemy or not enemy.Parent then return nil end
    for _,name in ipairs({"LeftLowerLeg","Head","HumanoidRootPart"}) do
        local p=enemy:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    for _,c in ipairs(enemy:GetChildren()) do
        if c:IsA("BasePart") then return c end
    end
    return nil
end
local function getEnemiesInRange()
    local character=LocalPlayer.Character; if not character then return {} end
    local hrp=character:FindFirstChild("HumanoidRootPart"); if not hrp then return {} end
    local folder=workspace:FindFirstChild("Enemies"); if not folder then return {} end
    local results={}
    for _,enemy in ipairs(folder:GetChildren()) do
        if enemy and enemy.Parent then
            local hum=enemy:FindFirstChild("Humanoid")
            if hum and hum.Health and hum.Health>0 then
                local part=getTargetPart(enemy)
                if part and part.Parent then
                    local ok,pos=pcall(function() return part.Position end)
                    if ok and pos then
                        local d=(pos-hrp.Position).Magnitude
                        if d<=AuraConfig.MAX_DISTANCE and d>=AuraConfig.MIN_DISTANCE then
                            table.insert(results,{enemy=enemy,part=part,dist=d})
                        end
                    end
                end
            end
        end
    end
    return results
end
local function AttackMultiple(list)
    if not AuraEnabled or not list or #list == 0 then return end
    if not RegisterAttack or not RegisterHit then
        local net = ReplicatedStorage:FindFirstChild("Modules")
        if net then net = net:FindFirstChild("Net") end
        if net then
            RegisterAttack = net:FindFirstChild("RE/RegisterAttack")
            RegisterHit = net:FindFirstChild("RE/RegisterHit")
        end
    end
    if not RegisterAttack or not RegisterHit then return end
    local hitTable, primaryPart = {}, nil
    for _, e in ipairs(list) do
        local enemy, part = e.enemy, e.part
        if enemy and enemy.Parent and part and part.Parent then
            table.insert(hitTable, { enemy, part })
            if not primaryPart then primaryPart = part end
        end
    end
    if #hitTable == 0 or not primaryPart then return end
    pcall(function() RegisterAttack:FireServer(0.5) end)
    task.wait()
    pcall(function()
        RegisterHit:FireServer(primaryPart, hitTable, nil, AuraConfig.SESSION_ID)
    end)
end
task.spawn(function()
    while not _G.FE_Unloaded do
        local enemies=getEnemiesInRange()
        AuraTargetCount=#enemies
        if AuraTargetCount>0 then
            table.sort(enemies,function(a,b) return a.dist<b.dist end)
            AuraFirstTargetName=enemies[1].enemy.Name or "Unknown"
        else AuraFirstTargetName="None" end
        updateHUD()
        if AuraEnabled and AuraTargetCount>0 then
            if type(remoteAttack) == "function" and type(S) == "table" then
                local prev = S.remoteMode
                remoteAttack()
            else
                AttackMultiple(enemies)
            end
        end
        task.wait(0.05)
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
    {Name="Skylands",Position=Vector3.new(-5024.21,794.4,-2618.69)},
    {Name="Prison",Position=Vector3.new(5277.79,-13.78,743.14)},
    {Name="Colosseum",Position=Vector3.new(-1685.21,-13.78,-3200.86)},
    {Name="Magma Village",Position=Vector3.new(-5528.21,-13.78,8691.14)},
    {Name="Underwater City",Position=Vector3.new(61379.79,-13.78,1473.14)},
    {Name="Fountain City",Position=Vector3.new(5717.79,-13.78,4356.14)},
}
local SecondSeaIslands={
    {Name="Kingdom of Rose",Position=Vector3.new(-195.1,155.3,279.9)},
    {Name="Green Zone",Position=Vector3.new(-2340.8,155.3,-3396.3)},
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
local IslandsBySea={[SEA1_ID]=FirstSeaIslands,[SEA2_ID]=SecondSeaIslands,[SEA3_ID_A]=ThirdSeaIslands,[SEA3_ID_B]=ThirdSeaIslands}
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
local FRUIT_LINES,LIST_START_Y,LINE_STEP=10,48,18
local panelShown=0
local layoutPanel
local seaLabel=SEA_NAMES[currentPlaceId]
local title=createText("SERVER STATUS"..(seaLabel and (" ["..seaLabel.."]") or " [sea?]"),16)
local dealer=createText("",13)
local fruitLines={}
for i=1,FRUIT_LINES do fruitLines[i]=createText("",13,Color3.fromRGB(80,255,100)) end
local distance=createText("",13,Color3.fromRGB(255,220,80))
local count=createText("",13,Color3.fromRGB(180,200,255))
if isSea3() then dealer.Visible=false end
local function applyPanelSize()
    title.Size=panelTextSize+3; dealer.Size=panelTextSize
    for i=1,FRUIT_LINES do fruitLines[i].Size=panelTextSize end
    distance.Size=panelTextSize; count.Size=panelTextSize
end
layoutPanel=function(shown)
    local x,y=panelPosX,panelPosY
    title.Position=Vector2.new(x,y); dealer.Position=Vector2.new(x,y+24)
    for i=1,FRUIT_LINES do
        fruitLines[i].Position=Vector2.new(x,y+LIST_START_Y+(i-1)*LINE_STEP)
    end
    local gap=(shown>0) and 6 or 4
    local distY=LIST_START_Y+shown*LINE_STEP+gap
    distance.Position=Vector2.new(x,y+distY); count.Position=Vector2.new(x,y+distY+20)
end
applyPanelSize(); layoutPanel(0)
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
local function createESP(obj,name)
    local handle=obj:FindFirstChild("Handle"); if not handle then return end
    local text=Drawing.new("Text")
    text.Text=name; text.Size=14; text.Color=Color3.fromRGB(0,255,120)
    text.Center=true; text.Outline=true; text.Visible=false
    _G.FruitESP[obj]={Text=text,Handle=handle,Name=name}
end
local function removeESP(obj)
    local data=_G.FruitESP[obj]
    if data and data.Text then pcall(function() data.Text:Remove() end) end
    _G.FruitESP[obj]=nil
end
local function updateESP()
    if not feEnabled("esp") then
        for _,data in pairs(_G.FruitESP) do if data.Text then data.Text.Visible=false end end
        return
    end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for obj,data in pairs(_G.FruitESP) do
        if not obj or not obj.Parent or not data.Handle or not data.Handle.Parent then
            removeESP(obj); continue
        end
        local worldPos=data.Handle.Position+Vector3.new(0,3.5,0)
        local ok,r1,r2=pcall(WorldToScreen,worldPos)
        if ok and r1 then
            local x,y,onScreen
            if type(r1)=="table" then x,y,onScreen=r1.X,r1.Y,r1.OnScreen
            else x,y=r1.X,r1.Y; onScreen=r2 end
            if onScreen==nil then onScreen=true end
            if onScreen and x and y then
                local distText=""
                if root then distText=" ("..math.floor((root.Position-data.Handle.Position).Magnitude/10).."m)" end
                data.Text.Text=tostring(data.Name or "Fruit")..distText
                data.Text.Position=Vector2.new(x,y); data.Text.Visible=true
            else data.Text.Visible=false end
        else data.Text.Visible=false end
    end
end
local fruitCache={}
local function refreshFruits()
    local found,current={},{}
    for _,obj in ipairs(Workspace:GetChildren()) do
        if isFruit(obj) then
            local handle=obj:FindFirstChild("Handle")
            if handle then
                local name=getFruitName(obj)
                local island=getIslandName(handle.Position)
                found[#found+1]={Object=obj,Position=handle.Position,Name=name,Island=island}
                current[obj]=true
                if _G.FruitESP[obj] then _G.FruitESP[obj].Name=name else createESP(obj,name) end
            end
        end
    end
    for obj in pairs(_G.FruitESP) do if not current[obj] then removeESP(obj) end end
    fruitCache=found
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
refreshFruits(); refreshDealer()
task.spawn(function()
    while not _G.FE_Unloaded do refreshFruits(); refreshDealer(); task.wait(0.35) end
end)
local espConn=RunService.RenderStepped:Connect(updateESP)
task.spawn(function()
    while not _G.FE_Unloaded do
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
        layoutPanel(panelShown)
        task.wait(0.07)
    end
end)
_pvpAuraEnabled = false
_pvpAuraAltPart = false
_pvpAuraMaxDist = 100
function notify(...) end
Players = game:GetService("Players")
LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat wait(0.1); LocalPlayer = Players.LocalPlayer until LocalPlayer
end
S = {
    autoFarming     = false,
    fruitEsp        = false, 
    chamEsp         = false,
    autoFruits      = false,
    autoTpFruit     = false,
    autoFarmNearest = false,
    autoNpcFarm     = false,
    autoFarmLevel   = false,
    bigHitbox       = false,
    pullEnemies     = false,
    autoKen         = false,
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
    boatFlyEnabled  = false,
    boatTweening    = false,
    remoteMode      = false,   
    customPullX    = 0,
    customPullY    = -10,
    customPullZ    = 0,
    boatFlySpeed   = 5,
    FARM_SPEED     = 250,
    CHEST_SPEED    = 310,
    FRUIT_SPEED    = 210,
    NPC_TWEEN_SPEED = 250,
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
if game.PlaceId == 2753915549 then
    AFL.currentSea = 1; AFL.npcToFarm = "Sea1First"
elseif game.PlaceId == 4442272183 then
    AFL.currentSea = 2; AFL.npcToFarm = "RoseKingdom1"
elseif game.PlaceId == 7449423635 or game.PlaceId == 100117331123089 then
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
        task.wait()
        if not S.boatFlyEnabled or S.boatTweening then continue end
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
        primary.Position=Vector3.new(primary.Position.X+mx, primary.Position.Y+my, primary.Position.Z+mz)
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
                    if d<bestDist and d<=500 then bestDist=d; nearest=model end
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
                local count=#children
                if count~=lastChestCount then S.chestIndex=1; lastChestCount=count end
                if count>0 then
                    if S.chestIndex>count then S.chestIndex=1 end
                    local model=children[S.chestIndex]
                    if model then
                        local tp=model:FindFirstChild("RootPart")
                        if tp then
                            notify("Going to chest "..S.chestIndex.."/"..count,"redacted",2)
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
        return Vector2.new(p.X+s.X/2, p.Y+s.Y/1.25)
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
        local v=Vector2.new(p.X+s.X/2, p.Y+s.Y/1.25)
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
                    local folder=game.Workspace:FindFirstChild("Enemies")
                    if folder then
                        for _, model in pairs(folder:GetChildren()) do
                            if model:IsA("Model") then
                                task.spawn(function()
                                    local hrp=model:FindFirstChild("HumanoidRootPart")
                                    if hrp then hrp.CanCollide=false; hrp.Position=pullPoint end
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
            if hrp then hrp.Position=Vector3.new(hrp.Position.X,100000,hrp.Position.Z); hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0) end
        end
        task.wait()
    end
end)
task.spawn(function()
    while true do
        if S.skyPull then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Position=Vector3.new(hrp.Position.X,1000,hrp.Position.Z); hrp.Velocity=Vector3.new(0,0,0); hrp.AssemblyLinearVelocity=Vector3.new(0,0,0) end
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
    local aura = {
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
        local last = false
        while true do
            local pressed = iskeypressed(0x74)
            if pressed and not last then
                aura.enabled = not aura.enabled
                notify("NPC Aura " .. (aura.enabled and "ON" or "OFF"), "redacted", 2)
            end
            last = pressed
            task.wait(0.05)
        end
    end)
    task.spawn(function()
        while true do
            if aura.enabled then
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
        local last = false
        while true do
            local pressed = iskeypressed(0x73)
            if pressed and not last then
                _pvpAuraAltPart = not _pvpAuraAltPart
                notify("Hit part: " .. (_pvpAuraAltPart and "ModelHitbox" or "Head"), "redacted", 2)
            end
            last = pressed
            task.wait(0.05)
        end
    end)
    task.spawn(function()
        while true do
            if _pvpAuraEnabled then
                if pvp_ensureRemotes() then
                    local player, part = pvp_getTarget()
                    pvp_attack(part)
                end
                task.wait(0.05)
            else
                task.wait(0.1)
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
task.spawn(function()
    local okLib, Lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua"))() or INSUI
    end)
    if not okLib or type(Lib) ~= "table" then
        warn("[Hub] INS UI not loaded")
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
        subtitle = "auto",
        size = Vector2.new(720, 520),
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
    H.panel = tip(espSec:Toggle("Status Panel", true, function(on) Features.panel = on end, "server status overlay"), "server status overlay")
    local panelTab = win:Tab("Panel", "map")
    local posSec = panelTab:Section("Position", "Left")
    tip(posSec:Slider("Panel X", 50, 50, 0, 3000, "", function(v) panelPosX = v; layoutPanel(panelShown) end), "horizontal position of status panel")
    tip(posSec:Slider("Panel Y", 400, 20, 0, 1500, "", function(v) panelPosY = v; layoutPanel(panelShown) end), "vertical position of status panel")
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
    Lib:Category("COMBAT")
    local combatTab = win:Tab("Combat", "swords")
    local combatSec = combatTab:Section("Combat", "Left")
    tip(combatSec:Toggle("Big Hitbox", false, function(v) setMyth("bigHitbox", v) end, "Enlarge enemy hitboxes while farming"), "Enlarge enemy hitboxes while farming")
    tip(combatSec:Toggle("Pull Enemies", false, function(v) setMyth("pullEnemies", v) end, "Pull nearby enemies toward you"), "Pull nearby enemies toward you")
    tip(combatSec:Toggle("Buddha Pull", false, function(v) setMyth("buddhaPull", v) end, "Buddha fruit pull variant"), "Buddha fruit pull variant")
    tip(combatSec:Toggle("Auto Ken", false, function(v) setMyth("autoKen", v) end, "Auto Observation Haki"), "Auto Observation Haki")
    tip(combatSec:Toggle("Freeze Position", false, function(v) setMyth("freezePos", v) end, "Lock your character position"), "Lock your character position")
    tip(combatSec:Toggle("Freeze Enemies", false, function(v) setMyth("freezeEnemies", v) end, "Freeze enemy positions"), "Freeze enemy positions")
    tip(combatSec:Toggle("Auto TP Ember", false, function(v) setMyth("teleportEmber", v) end, "Teleport to Ember template"), "Teleport to Ember template")
    tip(combatSec:Toggle("Goto Kitsune Island", false, function(v) setMyth("teleportKitsune", v) end, "Teleport to Kitsune island"), "Teleport to Kitsune island")
    local pullSec = combatTab:Section("Custom Pull", "Right")
    tip(pullSec:Toggle("Custom Pull", false, function(v) setMyth("customPull", v) end, "Use custom pull offsets"), "Use custom pull offsets")
    tip(pullSec:Slider("Pull X Offset", 0, 1, -100, 100, "", function(v) setMyth("customPullX", v) end), "Custom pull X")
    tip(pullSec:Slider("Pull Y Offset", -10, 1, -100, 100, "", function(v) setMyth("customPullY", v) end), "Custom pull Y")
    tip(pullSec:Slider("Pull Z Offset", 0, 1, -100, 100, "", function(v) setMyth("customPullZ", v) end), "Custom pull Z")
    local m1Sec = combatTab:Section("M1 Aura", "Left")
    H.aura = tip(m1Sec:Toggle("M1 Aura", false, function(on)
        Features.aura = on
        AuraEnabled = on
        if type(S) == "table" and on then
        end
        updateHUD()
        print("[M1 Aura]", on and "ON" or "OFF", "remotes:", RegisterAttack ~= nil, RegisterHit ~= nil)
    end, "Fires RegisterAttack/RegisterHit on nearby NPCs"), "Fires RegisterAttack/RegisterHit on nearby NPCs")
    K.aura = m1Sec:Keybind("Aura key", nil, function() end)
    tip(m1Sec:Slider("M1 Range", AuraConfig.MAX_DISTANCE, 5, 10, 500, "studs", function(v)
        AuraConfig.MAX_DISTANCE = v
    end), "Max distance to hit NPCs")
    Lib:Category("SEA")
    local seaTab = win:Tab("Sea", "waves")
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
    local raidSec = seaTab:Section("Games", "Right")
    tip(raidSec:Toggle("Auto Raid", false, function(v) setMyth("autoRaid", v) end, "Scans for RaidMap, teleports to center and pulls enemies"), "Scans for RaidMap, teleports to center and pulls enemies")
    Lib:Category("PVP")
    local pvpTab = win:Tab("PvP", "skull")
    local pvpSec = pvpTab:Section("Pull / Aura", "Left")
    tip(pvpSec:Toggle("Escape (risky)", false, function(v) setMyth("voidPull", v) end, "Sends you to Y=100000"), "Sends you to Y=100000")
    tip(pvpSec:Toggle("Go Back Down (risky)", false, function(v) setMyth("skyPull", v) end, "Brings you back to Y=100"), "Brings you back to Y=100")
    tip(pvpSec:Toggle("PvP Aura", false, function(v) _pvpAuraEnabled = v end, "Fires RegisterHit on the nearest player"), "Fires RegisterHit on the nearest player")
    tip(pvpSec:Toggle("Use ModelHitbox", false, function(v) _pvpAuraAltPart = v end, "Toggle between Head and ModelHitbox hit part"), "Toggle between Head and ModelHitbox hit part")
    tip(pvpSec:Slider("PvP Range", 100, 10, 10, 300, "studs", function(v) _pvpAuraMaxDist = v end), "Max distance to target players")
    Lib:Category("AUTOMATION")
    local fishTab = win:Tab("Fish", "fish")
    local fishSec = fishTab:Section("Auto Fish", "Left")
    H.fish = tip(fishSec:Toggle("Auto Fish", false, function(on)
        Features.fish = on
        if on then FishStart() else FishStop() end
    end, "Automatically casts, detects bite, reels (treasure priority)"), "Automatically casts, detects bite, reels (treasure priority)")
    K.fish = fishSec:Keybind("Fish key", nil, function() end)
    local fishTune = fishTab:Section("Tuning", "Right")
    tip(fishTune:Slider("Cast power", FishConfig.CastTarget * 100, 1, 50, 100, "%", function(v) FishConfig.CastTarget = v / 100 end), "Release cast when bar reaches this fill")
    tip(fishTune:Slider("Reel dead zone", FishConfig.DeadZone * 100, 1, 0, 200, "%", function(v) FishConfig.DeadZone = v / 100 end), "Hold/release threshold vs fish/treasure")
    tip(fishTune:Slider("Bite timeout", FishConfig.BiteTimeout, 1, 5, 60, "s", function(v) FishConfig.BiteTimeout = v end), "Reset if no bite within this time")
    local repairTab = win:Tab("Repair", "wrench")
    local repairSec = repairTab:Section("Auto Repair", "Left")
    H.repair = tip(repairSec:Toggle("Auto Repair", false, function(on)
        Features.repair = on
        if on then RepStart() else RepStop() end
    end, "Auto hold/release ship repair minigame on green zone"), "Auto hold/release ship repair minigame on green zone")
    K.repair = repairSec:Keybind("Repair key", nil, function() end)
    win:AddSettingsTab("gear")
    pcall(function()
        local menuSec = win:SettingsSection("Menu Bind", "Right")
        if menuSec then
            K.menu = menuSec:Keybind("Menu key", "F1", function() end)
        end
    end)
    if not K.menu then
        local sTab = win:Tab("Settings", "gear")
        local sSec = sTab:Section("Menu", "Left")
        K.menu = sSec:Keybind("Menu key", "F1", function() end)
    end
    pcall(function()
        if K.menu and K.menu.Set then K.menu:Set("F1") end
    end)
    if WinRef and WinRef.SetMenuKey then
        pcall(function() WinRef:SetMenuKey("f1") end)
    end
    if LibRef and LibRef.SetMenuKey then
        pcall(function() LibRef:SetMenuKey("f1") end)
    end
    local unloadSec = win:Tab("Unload", "trash"):Section("Danger", "Full")
    unloadSec:Button("Unload Hub", function()
        Lib:Dialog({
            title = "Unload?",
            text = "Stop all modules?",
            confirm = "Unload",
            onConfirm = function()
                _G.FE_Unloaded = true
                FishStop(); RepStop(); AuraEnabled = false
                if type(S) == "table" then
                    for k, v in pairs(S) do
                        if type(v) == "boolean" then S[k] = false end
                    end
                end
                _pvpAuraEnabled = false
                if espConn then pcall(function() espConn:Disconnect() end) end
                for _, d in pairs(_G.FruitStatusDrawings) do pcall(function() d:Remove() end) end
                _G.FruitStatusDrawings = {}
                for obj, data in pairs(_G.FruitESP) do
                    pcall(function() data.Text:Remove() end)
                    _G.FruitESP[obj] = nil
                end
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
                local down = isDown(key)
                if down and not lastDown.fish then
                    toggleFeature("fish", function(on) if on then FishStart() else FishStop() end end)
                end
                lastDown.fish = down
            end
            do
                local key = getBindKey(K.repair)
                local down = isDown(key)
                if down and not lastDown.repair then
                    toggleFeature("repair", function(on) if on then RepStart() else RepStop() end end)
                end
                lastDown.repair = down
            end
            do
                local key = getBindKey(K.aura)
                local down = isDown(key)
                if down and not lastDown.aura then
                    toggleFeature("aura", function(on) AuraEnabled = on; updateHUD() end)
                end
                lastDown.aura = down
            end
            task.wait(0.03)
        end
    end)
    pcall(function()
        if Lib.SetKeybindOverlay then Lib:SetKeybindOverlay(false) end
        if Lib.SetMenuKey then Lib:SetMenuKey("f1") end
        if WinRef and WinRef.SetMenuKey then WinRef:SetMenuKey("f1") end
    end)
    pcall(function()
        local f1Held = false
        UIS.InputBegan:Connect(function(input, gp)
            if input.KeyCode ~= Enum.KeyCode.F1 then return end
            if f1Held then return end
            f1Held = true
            menuOpen = not menuOpen
            pcall(function()
                if WinRef then
                    if WinRef.SetOpen then WinRef:SetOpen(menuOpen)
                    elseif WinRef.Toggle then WinRef:Toggle()
                    end
                end
                if LibRef and LibRef.SetOpen then LibRef:SetOpen(menuOpen) end
            end)
        end)
        UIS.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.F1 then f1Held = false end
        end)
    end)
    pcall(function()
        task.spawn(function()
            local last = false
            while not _G.FE_Unloaded do
                local down = false
                pcall(function() down = iskeypressed(0x70) end)
                if not down then
                    pcall(function() down = UIS:IsKeyDown(Enum.KeyCode.F1) end)
                end
                if down and not last then
                    menuOpen = not menuOpen
                    pcall(function()
                        if WinRef and WinRef.SetOpen then WinRef:SetOpen(menuOpen) end
                    end)
                end
                last = down
                task.wait(0.03)
            end
        end)
    end)
    Lib:Notify("BF Hub", "Dropdowns fixed | tooltips | M1 Aura only", 4, "success")
end)
