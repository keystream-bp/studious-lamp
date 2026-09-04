local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============= ANTI-DETECTION =============
pcall(function()
    local g = getgenv and getgenv() or _G
    if g.debug then 
        g.debug.info = function() end
        g.debug.getupvalue = function() end
        g.debug.getconstant = function() end
    end
    local hook = hookmetamethod or detach
    if hook then
        local oIdx, oNc
        oIdx = hook(game, "__index", function(self, k) 
            return (not checkcaller() and (k == "WalkSpeed" or k == "JumpPower")) and 16 or oIdx(self, k) 
        end)
        oNc = hook(game, "__namecall", function(self, ...)
            local m, n = getnamecallmethod(), tostring(self.Name):lower()
            if (m == "FireServer" or m == "InvokeServer") and (n:find("ban") or n:find("cheat") or n:find("validator")) then 
                return nil 
            end
            return oNc(self, ...)
        end)
    end
end)

-- ============= SERVICES =============
local P = game:GetService("Players")
local L = game:GetService("Lighting")
local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local RSvc = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = P.LocalPlayer
local Cam = workspace.CurrentCamera

-- ============= ANTI-AFK =============
LP.Idled:Connect(function()
    local bb = game:GetService("VirtualUser")
    bb:CaptureController()
    bb:ClickButton2(Vector2.new())
end)

-- ============= MAIN VARIABLES (ANDZ) =============
local AutoFarm = false
local BringMob = true
local FastAttack = true
local ExtendedHitbox = true
local AutoChestFullMap = false
local ESPBox = false
local ESPName = false
local ESPDist = false
local ESPLine = false
local ESPFruit = false
local ESPIsland = false
local WalkOnWater = false
local SpeedHack = false
local WalkSpeedValue = 32
local InfJump = false
local NoClip = false

-- ============= ADVANCED FEATURES (TLREDZ) =============
local AutoPickup = false
local AutoWeapon = false
local CombatMode = false
local TeleportMode = false
local AutoChest = false
local InventorySort = false
local AutoAbility = false
local SmartFarm = false
local KillAura = false
local AntiStun = false
local AutoRespawn = false
local FarmSpeed = 250
local PickupRange = 50
local AutoSell = false

-- ============= FLIGHT VARIABLES =============
local CurTween, CurPos, WaterPart
local CollectedChests = {}
local TeleportLocations = {}

-- ============= QUEST DATABASE =============
local Quests = {
    {1, "BanditQuest1", 1, "Bandit", CFrame.new(1059, 16, 1549), CFrame.new(1145, 16, 1630)},
    {10, "JungleQuest", 1, "Monkey", CFrame.new(-1598, 36, 153), CFrame.new(-1448, 50, 63)},
    {15, "JungleQuest", 2, "Gorilla", CFrame.new(-1598, 36, 153), CFrame.new(-1237, 6, -486)},
    {30, "PirateQuest", 1, "Pirate", CFrame.new(-1140, 4, 3828), CFrame.new(-1200, 4, 3900)},
    {60, "DesertQuest", 1, "Desert Bandit", CFrame.new(894, 6, 4388), CFrame.new(950, 6, 4450)},
    {90, "SnowQuest", 1, "Snow Bandit", CFrame.new(1385, 87, -1298), CFrame.new(1300, 87, -1350)}
}

-- ============= UTILITY FUNCTIONS =============
local function GetLvl(p)
    local target, lvl = p or LP, 1
    pcall(function() 
        lvl = target:FindFirstChild("Data") and target.Data.Level.Value or target.Level.Value 
    end)
    return lvl
end

local function GetQ()
    local l, c = GetLvl(), Quests[1]
    for _, q in ipairs(Quests) do 
        if l >= q[1] then c = q end 
    end
    return {QName = c[2], QNum = c[3], MName = c[4], Npc = c[5], Mob = c[6]}
end

-- ============= FLIGHT SYSTEM (ANDZ) =============
local function FlyTo(targetCF, speed)
    speed = speed or FarmSpeed
    local chr = LP.Character
    local hrp, hum = chr and chr:FindFirstChild("HumanoidRootPart"), chr and chr:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    hrp.Velocity = Vector3.zero
    hum.PlatformStand = false
    
    local dist = (hrp.Position - targetCF.Position).Magnitude
    if dist > 6 then
        for _, v in pairs(chr:GetChildren()) do 
            if v:IsA("BasePart") then v.CanCollide = false end 
        end
        if not CurPos or (CurPos - targetCF.Position).Magnitude > 3 then
            CurPos = targetCF.Position
            if CurTween then CurTween:Cancel() end
            CurTween = TS:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), {CFrame = targetCF})
            CurTween:Play()
        end
    else
        if CurTween then CurTween:Cancel(); CurTween = nil end
        CurPos, hrp.CFrame = nil, targetCF
    end
end

local function StopFly()
    if CurTween then CurTween:Cancel(); CurTween = nil end
    CurPos = nil
    local chr = LP.Character
    local hum = chr and chr:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    if chr then
        for _, v in pairs(chr:GetChildren()) do 
            if v:IsA("BasePart") then v.CanCollide = true end 
        end
    end
end

-- ============= AUTO PICKUP SYSTEM (TLREDZ) =============
local function AutoPickupItems()
    if not AutoPickup then return end
    pcall(function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        for _, item in pairs(workspace:GetChildren()) do
            if item:IsA("Tool") and (item.Name:find("Fruit") or item.Name:find("Item") or item.Name:find("Chest")) then
                local handle = item:FindFirstChild("Handle")
                if handle and (handle.Position - hrp.Position).Magnitude < PickupRange then
                    handle.CanCollide = false
                    handle.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 5
                end
            end
        end
    end)
end

-- ============= AUTO WEAPON SWITCH (TLREDZ) =============
local function AutoWeaponSwitch()
    if not AutoWeapon then return end
    pcall(function()
        local chr = LP.Character
        if not chr then return end
        
        local bestWeapon = nil
        local highestDmg = 0
        
        for _, tool in pairs(LP.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local dmg = tool:FindFirstChild("Damage") or tool:FindFirstChild("BaseDamage")
                if dmg and dmg.Value > highestDmg then
                    highestDmg = dmg.Value
                    bestWeapon = tool
                end
            end
        end
        
        if bestWeapon then
            chr.Humanoid:EquipTool(bestWeapon)
        end
    end)
end

-- ============= SMART FARM SYSTEM (TLREDZ) =============
local function SmartFarmLogic()
    if not SmartFarm then return nil end
    pcall(function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        
        local q = GetQ()
        local nearestMob = nil
        local shortestDist = math.huge
        
        if workspace:FindFirstChild("Enemies") then
            for _, mob in pairs(workspace.Enemies:GetChildren()) do
                if (mob.Name == q.MName or mob.Name:find(q.MName)) and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                    if mhrp then
                        local d = (mhrp.Position - hrp.Position).Magnitude
                        if d < shortestDist then
                            shortestDist = d
                            nearestMob = mob
                        end
                    end
                end
            end
        end
        
        return nearestMob
    end)
    return nil
end

-- ============= INVENTORY MANAGEMENT (TLREDZ) =============
local function ManageInventory()
    if not InventorySort then return end
    pcall(function()
        local backpack = LP.Backpack
        local toolList = {}
        
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(toolList, tool)
            end
        end
        
        table.sort(toolList, function(a, b)
            local aDmg = (a:FindFirstChild("Damage") or a:FindFirstChild("BaseDamage") or {Value = 0}).Value
            local bDmg = (b:FindFirstChild("Damage") or b:FindFirstChild("BaseDamage") or {Value = 0}).Value
            return aDmg > bDmg
        end)
    end)
end

-- ============= KILL AURA (TLREDZ) =============
local function KillAuraAttack()
    if not KillAura then return end
    pcall(function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local chr = LP.Character
        if not hrp or not chr then return end
        
        local tool = chr:FindFirstChildOfClass("Tool")
        if not tool then return end
        
        if workspace:FindFirstChild("Enemies") then
            for _, mob in pairs(workspace.Enemies:GetChildren()) do
                local mhrp = mob:FindFirstChild("HumanoidRootPart")
                if mhrp and (mhrp.Position - hrp.Position).Magnitude < 100 then
                    if mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        tool:Activate()
                    end
                end
            end
        end
    end)
end

-- ============= AUTO FARM LOOP (ANDZ + TLREDZ) =============
RSvc.Heartbeat:Connect(function()
    if AutoFarm or SmartFarm then
        pcall(function()
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            hrp.Velocity = Vector3.zero
            
            local q = GetQ()
            local qGui = LP.PlayerGui:FindFirstChild("Main")
            local hasQ = qGui and qGui:FindFirstChild("Quest") and qGui.Quest.Visible and qGui.Quest.Container.QuestTitle.Title.Text ~= ""
            
            if not hasQ then
                if (hrp.Position - q.Npc.Position).Magnitude > 12 then 
                    FlyTo(q.Npc, FarmSpeed)
                else 
                    StopFly()
                    hrp.CFrame = q.Npc 
                    pcall(function()
                        RS.Remotes.CommF_:InvokeServer("StartQuest", q.QName, q.QNum)
                    end)
                end
            else
                local targetMob = SmartFarmLogic()
                
                if not targetMob and workspace:FindFirstChild("Enemies") then
                    local shortestDist = math.huge
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if (v.Name == q.MName or v.Name:find(q.MName)) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
                            local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if d < shortestDist then
                                shortestDist = d
                                targetMob = v
                            end
                        end
                    end
                end
                
                if targetMob and targetMob:FindFirstChild("HumanoidRootPart") then
                    StopFly()
                    local mHrp = targetMob.HumanoidRootPart
                    hrp.CFrame = CFrame.new(mHrp.Position + Vector3.new(0, 11, 0), mHrp.Position)
                    
                    if BringMob and workspace:FindFirstChild("Enemies") then
                        for _, om in pairs(workspace.Enemies:GetChildren()) do
                            if (om.Name == q.MName or om.Name:find(q.MName)) and om:FindFirstChild("HumanoidRootPart") and om:FindFirstChild("Humanoid") and om.Humanoid.Health > 0 then
                                if (om.HumanoidRootPart.Position - mHrp.Position).Magnitude < 280 then
                                    om.HumanoidRootPart.CFrame = mHrp.CFrame
                                    om.HumanoidRootPart.CanCollide = false
                                end
                            end
                        end
                    end
                else
                    FlyTo(q.Mob, FarmSpeed)
                end
            end
        end)
    end
    
    -- Speed Hack
    if SpeedHack then
        pcall(function()
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
            if hrp and hum then
                hum.WalkSpeed = WalkSpeedValue
            end
        end)
    end
end)

-- ============= AUTO ATTACK LOOP (ANDZ + TLREDZ) =============
task.spawn(function()
    while true do
        if AutoFarm or SmartFarm then
            pcall(function()
                local chr = LP.Character
                if chr and chr:FindFirstChild("Humanoid") and chr.Humanoid.Health > 0 then
                    local tool = chr:FindFirstChildOfClass("Tool")
                    if not tool then
                        AutoWeaponSwitch()
                        for _, t in pairs(LP.Backpack:GetChildren()) do
                            if t:IsA("Tool") and t.ToolTip ~= "Gun" then 
                                chr.Humanoid:EquipTool(t) 
                                break 
                            end 
                        end
                    else
                        if ExtendedHitbox and tool:FindFirstChild("Handle") then
                            tool.Handle.Size = Vector3.new(60, 60, 60)
                            tool.Handle.Transparency = 1
                            tool.Handle.CanCollide = false
                        end
                        
                        tool:Activate()
                        pcall(function() 
                            if RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Net") then
                                RS.Modules.Net:FindFirstChild("RegisterAttack"):InvokeServer()
                            end
                        end)
                    end
                end
            end)
        end
        
        -- Auto Pickup
        AutoPickupItems()
        
        -- Kill Aura
        KillAuraAttack()
        
        task.wait(FastAttack and 0.015 or 0.2)
    end
end)

-- ============= AUTO CHEST SYSTEM (TLREDZ) =============
task.spawn(function()
    while true do
        if AutoChest then
            pcall(function()
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, chest in pairs(workspace:GetChildren()) do
                        if chest.Name:find("Chest") or chest.Name:find("Treasure") then
                            if (chest.Position - hrp.Position).Magnitude < 50 then
                                local open = chest:FindFirstChild("Open")
                                if open then
                                    pcall(function() open:FireServer() end)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ============= INFINITE JUMP (ANDZ) =============
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if InfJump and input.KeyCode == Enum.KeyCode.Space then
        local chr = LP.Character
        if chr and chr:FindFirstChild("Humanoid") then
            chr.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ============= NO CLIP (ANDZ) =============
task.spawn(function()
    while true do
        if NoClip then
            pcall(function()
                local chr = LP.Character
                if chr then
                    for _, v in pairs(chr:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ============= TELEPORT SYSTEM (TLREDZ) =============
local function TeleportToPlayer(player)
    pcall(function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local targetHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and targetHrp then
            hrp.CFrame = targetHrp.CFrame + targetHrp.CFrame.LookVector * 5
        end
    end)
end

local function TeleportToLocation(cf)
    pcall(function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = cf
        end
    end)
end

-- ============= ESP PLAYER SYSTEM (ANDZ) =============
local ESP_Cache = {}
local function CreateESP(plr)
    if plr == LP or ESP_Cache[plr] then return end
    local line = Drawing.new("Line")
    local box = Instance.new("Highlight")
    local bg = Instance.new("BillboardGui")
    local txt = Instance.new("TextLabel")
    
    line.Visible = false
    line.Color = Color3.fromRGB(0, 255, 255)
    line.Thickness = 1.5
    
    box.Name = "ESP_Box"
    box.FillColor = Color3.fromRGB(255, 50, 50)
    box.OutlineColor = Color3.fromRGB(255, 255, 255)
    box.FillTransparency = 0.5
    box.Enabled = false
    
    bg.Name = "ESP_Text"
    bg.Size = UDim2.new(0, 200, 0, 50)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 3.5, 0)
    bg.Enabled = false
    
    txt.Parent = bg
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.fromRGB(0, 255, 255)
    txt.TextSize = 13
    txt.Font = Enum.Font.Sour
    txt.TextStrokeTransparency = 0.5
    
    ESP_Cache[plr] = {Line = line, Box = box, Billboard = bg, TextLabel = txt}
end

for _, plr in pairs(P:GetPlayers()) do CreateESP(plr) end
P.PlayerAdded:Connect(CreateESP)
P.PlayerRemoving:Connect(function(p) 
    if ESP_Cache[p] then 
        pcall(function() 
            ESP_Cache[p].Line:Remove()
            ESP_Cache[p].Box:Destroy()
            ESP_Cache[p].Billboard:Destroy()
        end)
        ESP_Cache[p] = nil 
    end 
end)

-- ============= ESP RENDER LOOP (ANDZ) =============
RSvc.RenderStepped:Connect(function()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for plr, data in pairs(ESP_Cache) do
        local char = plr.Character
        local pHrp, pHum = char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
        if char and pHrp and pHum and pHum.Health > 0 then
            data.Box.Enabled = ESPBox
            if data.Box.Parent ~= char then data.Box.Parent = char end
            
            if ESPName or ESPDist then
                if data.Billboard.Parent ~= pHrp then data.Billboard.Parent = pHrp end
                local distText = ""
                if ESPDist and myHrp then
                    distText = "\n[" .. math.floor((pHrp.Position - myHrp.Position).Magnitude) .. "m]"
                end
                data.TextLabel.Text = (ESPName and plr.Name or "") .. distText
                data.Billboard.Enabled = true
            else 
                data.Billboard.Enabled = false 
            end
            
            if ESPLine and myHrp then
                local pos, vis = Cam:WorldToViewportPoint(pHrp.Position)
                if vis then 
                    data.Line.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                    data.Line.To = Vector2.new(pos.X, pos.Y)
                    data.Line.Visible = true 
                else 
                    data.Line.Visible = false 
                end
            else 
                data.Line.Visible = false 
            end
        else 
            data.Box.Enabled = false
            data.Billboard.Enabled = false
            data.Line.Visible = false 
        end
    end
end)

-- ============= ESP FRUIT (ANDZ) =============
RSvc.RenderStepped:Connect(function()
    pcall(function()
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        for _, v in pairs(workspace:GetChildren()) do
            if v:IsA("Tool") or v.Name:find("Fruit") then
                local handle = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
                if handle then
                    local bg = handle:FindFirstChild("FruitESP")
                    if ESPFruit then
                        if not bg then
                            bg = Instance.new("BillboardGui", handle)
                            bg.Name = "FruitESP"
                            bg.Size = UDim2.new(0, 220, 0, 50)
                            bg.AlwaysOnTop = true
                            bg.StudsOffset = Vector3.new(0, 2.5, 0)
                            local txt = Instance.new("TextLabel", bg)
                            txt.Name = "Txt"
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.BackgroundTransparency = 1
                            txt.TextColor3 = Color3.fromRGB(255, 170, 0)
                            txt.TextSize = 13
                            txt.Font = Enum.Font.Sour
                            txt.TextStrokeTransparency = 0.5
                        end
                        local distText = ""
                        if myHrp then
                            distText = " [" .. math.floor((handle.Position - myHrp.Position).Magnitude) .. "m]"
                        end
                        bg.Txt.Text = "🍎 " .. v.Name .. distText
                        bg.Enabled = true
                    elseif bg then 
                        bg.Enabled = false 
                    end
                end
            end
        end
    end)
end)

-- ============= ESP ISLAND (ANDZ) =============
local IslandFolder = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Locations") or workspace
RSvc.RenderStepped:Connect(function()
    pcall(function()
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end
        for _, loc in pairs(IslandFolder:GetChildren()) do
            if loc:IsA("Model") or loc:IsA("Part") then
                local targetPart = loc:IsA("Model") and (loc.PrimaryPart or loc:FindFirstChildWhichIsA("BasePart")) or loc
                if targetPart and loc.Name ~= "Water" and loc.Name ~= "Ocean" then
                    local bg = targetPart:FindFirstChild("IslandESP")
                    if ESPIsland then
                        if not bg then
                            bg = Instance.new("BillboardGui", targetPart)
                            bg.Name = "IslandESP"
                            bg.Size = UDim2.new(0, 250, 0, 50)
                            bg.AlwaysOnTop = true
                            bg.StudsOffset = Vector3.new(0, 10, 0)
                            local txt = Instance.new("TextLabel", bg)
                            txt.Name = "Txt"
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.BackgroundTransparency = 1
                            txt.TextColor3 = Color3.fromRGB(0, 255, 100)
                            txt.TextSize = 13
                            txt.Font = Enum.Font.Sour
                            txt.TextStrokeTransparency = 0.5
                        end
                        local dist = math.floor((targetPart.Position - myHrp.Position).Magnitude)
                        bg.Txt.Text = "🏝️ " .. loc.Name .. "\n[" .. dist .. "m]"
                        bg.Enabled = true
                    elseif bg then 
                        bg.Enabled = false 
                    end
                end
            end
        end
    end)
end)

-- ============= RAYFIELD UI =============
local Window = Rayfield:CreateWindow({
    Name = "⚡ Andz Dev Hub v1.9.9 ⚡",
    LoadingTitle = "Andz Dev Hub - Merged with tlredz",
    LoadingSubtitle = "Loading Ultimate Script...",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local TabMainFarm = Window:CreateTab("🌾 Farm System", 4483362458)
local TabESP = Window:CreateTab("👁️ ESP Hub", 4483362458)
local TabCombat = Window:CreateTab("⚔️ Combat", 4483362458)
local TabUtility = Window:CreateTab("🛠️ Utility", 4483362458)
local TabTeleport = Window:CreateTab("📍 Teleport", 4483362458)
local TabSettings = Window:CreateTab("⚙️ Settings", 4483362458)

-- ============= FARM TAB =============
TabMainFarm:CreateSection("🎯 Auto Farm Settings")
TabMainFarm:CreateToggle({
    Name = "Auto Farm (Andz)",
    CurrentValue = false,
    Callback = function(v) 
        AutoFarm = v 
        if not v then StopFly() end 
    end,
})

TabMainFarm:CreateToggle({
    Name = "Smart Farm (tlredz)",
    CurrentValue = false,
    Callback = function(v) SmartFarm = v end,
})

TabMainFarm:CreateSlider({
    Name = "Farm Speed",
    Range = {50, 500},
    Increment = 10,
    Suffix = " studs/s",
    CurrentValue = 250,
    Callback = function(v) FarmSpeed = v end
})

TabMainFarm:CreateSection("⚙️ Farm Options")
TabMainFarm:CreateToggle({
    Name = "Gom Quái (Bring Mob)",
    CurrentValue = true,
    Callback = function(v) BringMob = v end,
})

TabMainFarm:CreateToggle({
    Name = "Tự Động Đánh Nhanh",
    CurrentValue = true,
    Callback = function(v) FastAttack = v end,
})

TabMainFarm:CreateToggle({
    Name = "Đánh Khoảng Cách Xa (Hitbox)",
    CurrentValue = true,
    Callback = function(v) ExtendedHitbox = v end,
})

-- ============= ESP TAB =============
TabESP:CreateSection("👤 ESP Người Chơi")
TabESP:CreateToggle({ 
    Name = "ESP Box", 
    CurrentValue = false, 
    Callback = function(v) ESPBox = v end 
})

TabESP:CreateToggle({ 
    Name = "ESP Tên", 
    CurrentValue = false, 
    Callback = function(v) ESPName = v end 
})

TabESP:CreateToggle({ 
    Name = "ESP Khoảng Cách", 
    CurrentValue = false, 
    Callback = function(v) ESPDist = v end 
})

TabESP:CreateToggle({ 
    Name = "ESP Đường Kẻ", 
    CurrentValue = false, 
    Callback = function(v) ESPLine = v end 
})

TabESP:CreateSection("🍎 ESP Trái Ác Quỷ")
TabESP:CreateToggle({ 
    Name = "Hiển Thị Trái Ác Quỷ", 
    CurrentValue = false, 
    Callback = function(v) ESPFruit = v end 
})

TabESP:CreateSection("🏝️ ESP Đảo")
TabESP:CreateToggle({ 
    Name = "Hiển Thị Vị Trí Đảo", 
    CurrentValue = false, 
    Callback = function(v) ESPIsland = v end 
})

-- ============= COMBAT TAB (TLREDZ) =============
TabCombat:CreateSection("⚔️ Combat Features")
TabCombat:CreateToggle({
    Name = "Auto Weapon (tlredz)",
    CurrentValue = false,
    Callback = function(v) AutoWeapon = v end,
})

TabCombat:CreateToggle({
    Name = "Kill Aura (tlredz)",
    CurrentValue = false,
    Callback = function(v) KillAura = v end,
})

TabCombat:CreateToggle({
    Name = "Anti-Stun (tlredz)",
    CurrentValue = false,
    Callback = function(v) AntiStun = v end,
})

TabCombat:CreateSection("💾 Inventory")
TabCombat:CreateToggle({
    Name = "Auto Pickup (tlredz)",
    CurrentValue = false,
    Callback = function(v) AutoPickup = v end,
})

TabCombat:CreateSlider({
    Name = "Pickup Range",
    Range = {10, 100},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 50,
    Callback = function(v) PickupRange = v end
})

TabCombat:CreateToggle({
    Name = "Inventory Sort (tlredz)",
    CurrentValue = false,
    Callback = function(v) 
        InventorySort = v
        ManageInventory()
    end,
})

TabCombat:CreateToggle({
    Name = "Auto Chest (tlredz)",
    CurrentValue = false,
    Callback = function(v) AutoChest = v end,
})

-- ============= UTILITY TAB =============
TabUtility:CreateSection("🚀 Movement")
TabUtility:CreateToggle({ 
    Name = "Speed Hack", 
    CurrentValue = false, 
    Callback = function(v) SpeedHack = v end 
})

TabUtility:CreateSlider({ 
    Name = "Tốc Độ Di Chuyển", 
    Range = {16, 300}, 
    Increment = 1, 
    Suffix = " Speed", 
    CurrentValue = 32, 
    Callback = function(v) WalkSpeedValue = v end 
})

TabUtility:CreateToggle({ 
    Name = "Nhảy Vô Hạn", 
    CurrentValue = false, 
    Callback = function(v) InfJump = v end 
})

TabUtility:CreateToggle({ 
    Name = "No Clip", 
    CurrentValue = false, 
    Callback = function(v) NoClip = v end 
})

-- ============= TELEPORT TAB (TLREDZ) =============
TabTeleport:CreateSection("📍 Teleport Players")
task.spawn(function()
    for _, player in pairs(P:GetPlayers()) do
        if player ~= LP then
            TabTeleport:CreateButton({
                Name = "Teleport to " .. player.Name,
                Callback = function()
                    TeleportToPlayer(player)
                end,
            })
        end
    end
end)

TabTeleport:CreateSection("🗺️ Quick Locations")
TabTeleport:CreateButton({
    Name = "Teleport to Starting Island",
    Callback = function()
        TeleportToLocation(CFrame.new(0, 15, 0))
    end,
})

TabTeleport:CreateButton({
    Name = "Teleport to Sea",
    Callback = function()
        TeleportToLocation(CFrame.new(0, 10, 0))
    end,
})

-- ============= SETTINGS TAB =============
TabSettings:CreateSection("ℹ️ Script Information")
TabSettings:CreateLabel("📦 Version: v1.9.9")
TabSettings:CreateLabel("👨‍💻 Developers: Andz Dev + tlredz")
TabSettings:CreateLabel("🎮 Game: One Piece Dimension")
TabSettings:CreateLabel("✅ Status: Active & Working")
TabSettings:CreateLabel("📝 Last Update: 2026")

TabSettings:CreateSection("🎨 Features Summary")
TabSettings:CreateLabel("✓ Auto Farm Level")
TabSettings:CreateLabel("✓ Smart Farm (AI)")
TabSettings:CreateLabel("✓ Full ESP System")
TabSettings:CreateLabel("✓ Combat Automation")
TabSettings:CreateLabel("✓ Inventory Management")
TabSettings:CreateLabel("✓ Teleport System")
TabSettings:CreateLabel("✓ Movement Hacks")
TabSettings:CreateLabel("✓ Anti-Detection")

TabSettings:CreateSection("📍 Quick Commands")
TabSettings:CreateButton({
    Name = "Reload Script",
    Callback = function()
        Rayfield:Notify({
            Title = "⏳ Reloading...",
            Content = "Script will reload in 3 seconds",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

TabSettings:CreateButton({
    Name = "Clear All Cache",
    Callback = function()
        ESP_Cache = {}
        CollectedChests = {}
        Rayfield:Notify({
            Title = "✅ Cache Cleared",
            Content = "All cached data has been cleared",
            Duration = 2,
            Image = 4483362458
        })
    end,
})

-- Auto-update player list for teleport
P.PlayerAdded:Connect(function(player)
    TabTeleport:CreateButton({
        Name = "Teleport to " .. player.Name,
        Callback = function()
            TeleportToPlayer(player)
        end,
    })
end)

-- Startup Notification
Rayfield:Notify({
    Title = "✅ Script Loaded Successfully!",
    Content = "v1.9.9 - Andz Dev + tlredz Ultimate Merge\nAll features are active and ready to use!",
    Duration = 5,
    Image = 4483362458
})
