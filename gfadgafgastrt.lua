local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local API = ReplicatedStorage:WaitForChild("API")
local Utils = API:WaitForChild("Utils")
local network = require(Utils:WaitForChild("network"))
local story = require(API:WaitForChild("Gamemode"):WaitForChild("story"))
local worlds = require(API:WaitForChild("worlds"))
local codes_api = require(API:WaitForChild("codes"))
local challenges = require(API:WaitForChild("Gamemode"):WaitForChild("challenges"))

local RemoteEvent = Utils:WaitForChild("network"):WaitForChild("RemoteEvent")
local RemoteFunction = Utils:WaitForChild("network"):WaitForChild("RemoteFunction")

local function GetPlayerManager()
    local PS = LocalPlayer:WaitForChild("PlayerScripts")
    local NestedPS = PS:WaitForChild("PlayerScripts", 5) or PS
    return NestedPS:WaitForChild("player_manager")
end

local player_manager_module = GetPlayerManager()
local player_manager = require(player_manager_module)
local Data = player_manager.Data
local UIHandler = player_manager.UIHandler
local PlayerAPIs = player_manager.APIs
local MainGui = player_manager.MainGui

local battle_data = require(player_manager_module:WaitForChild("Battle"):WaitForChild("battle_data"))

local cascade = loadstring(game:HttpGet("https://raw.githubusercontent.com/maimearaikub/yaajfv/refs/heads/main/bvhkarbkf.lua"))()

local Config = {
    AutoFarm = false,
    AutoReplay = false,
    AutoLeave = false,
    AutoStartPortal = false,
    AutoChallengeDaily = false,
    AutoChallengeSemi = false,
    AutoRaid = false,
    SelectedRaid = "",
    SelectedRaidFloor = 1,
    SelectedWorld = "Green Planet",
    SelectedStage = 1,
    SelectedDifficulty = "Normal"
}

local PreviousTask = nil
local IsDoingChallenge = false
local IsDoingRaid = false
local PortalIsProcessing = false

local LastChallengeIndex = {
    Daily = -1,
    ["Semi-Hourly"] = -1
}

local worldNames = {}
local worldCount = 0
for _ in pairs(worlds.Worlds) do worldCount = worldCount + 1 end
for i = 1, worldCount do
    local w = worlds.Worlds[i]
    if w and w.Name ~= "Lobby" then table.insert(worldNames, w.Name) end
end

local app = cascade.New({ Theme = cascade.Themes.Dark, Accent = cascade.Accents.Purple })
local window = app:Window({ Title = "ANIME STORY 2", Subtitle = "Ghost Hub" })

local farmSection = window:Section({ Title = "Automation" })
local miscSection = window:Section({ Title = "Others" })

local farmTab = farmSection:Tab({ Title = "Auto Farm", Icon = cascade.Symbols.bolt, Selected = true })
local farmForm = farmTab:Form()
local stagePopUp = nil

local function UpdateStageList(worldName)
    if not stagePopUp then return end
    local currentCount = #stagePopUp.Options
    for i = currentCount, 1, -1 do stagePopUp:Remove(i) end
    local worldData = story.Worlds[worldName]
    if worldData then
        for i = 1, #worldData do stagePopUp:Option(tostring(i)) end
        stagePopUp.Value = 1
        Config.SelectedStage = 1
    else
        stagePopUp:Option("1")
        stagePopUp.Value = 1
    end
end

local worldRow = farmForm:Row()
worldRow:Left():ImageSurface({ Image = cascade.Symbols.map, SurfaceColor = Color3.fromRGB(120, 100, 255) })
worldRow:Left():TitleStack({ Title = "Target Area", Subtitle = "Sorted by progression" })
worldRow:Right():PopUpButton({
    Options = worldNames,
    Value = 1,
    ValueChanged = function(self, value)
        local world = self.Options[value]
        Config.SelectedWorld = world
        UpdateStageList(world)
    end
})

local stageRow = farmForm:Row()
stageRow:Left():ImageSurface({ Image = cascade.Symbols.listNumber, SurfaceColor = Color3.fromRGB(80, 200, 120) })
stageRow:Left():TitleStack({ Title = "Target Stage", Subtitle = "Select specific mission" })
stagePopUp = stageRow:Right():PopUpButton({
    Options = {"1"},
    Value = 1,
    ValueChanged = function(self, value) Config.SelectedStage = value end
})

task.spawn(function()
    task.wait(0.5)
    UpdateStageList(Config.SelectedWorld)
end)

local diffRow = farmForm:Row()
diffRow:Left():ImageSurface({ Image = cascade.Symbols.shield, SurfaceColor = Color3.fromRGB(255, 80, 80) })
diffRow:Left():TitleStack({ Title = "Difficulty", Subtitle = "Select mission grade" })
diffRow:Right():PopUpButton({
    Options = {"Normal", "Hard", "Nightmare"},
    Value = 1,
    ValueChanged = function(self, value)
        Config.SelectedDifficulty = self.Options[value]
    end
})

local toggleForm = farmTab:Form()
local function AddToggle(title, subtitle, configKey)
    local row = toggleForm:Row()
    row:Left():TitleStack({ Title = title, Subtitle = subtitle })
    row:Right():Toggle({
        Value = false,
        ValueChanged = function(self, val)
            Config[configKey] = val
            if configKey == "AutoFarm" and val and LocalPlayer:GetAttribute("World") == "Lobby" then
                JoinBattle()
            end
        end
    })
end

AddToggle("Execute Auto-Join", "Starts battle when in Lobby", "AutoFarm")
AddToggle("Global Auto Replay", "Restarts mission (All Modes)", "AutoReplay")
AddToggle("Global Auto Leave", "Instant return to Lobby (All Modes)", "AutoLeave")

local portalTab = farmSection:Tab({ Title = "Portal", Icon = cascade.Symbols.sparkles, Selected = false })
local portalForm = portalTab:Form()

local portalRow = portalForm:Row()
portalRow:Left():ImageSurface({ Image = cascade.Symbols.bolt, SurfaceColor = Color3.fromRGB(255, 200, 50) })
portalRow:Left():TitleStack({ Title = "Slime Apocalypse Portal", Subtitle = "Starts & warps to match" })
portalRow:Right():Toggle({
    Value = false,
    ValueChanged = function(self, val)
        Config.AutoStartPortal = val
        if not val then
            PortalIsProcessing = false
            RemoteEvent:FireServer("portal_exit")
        end
    end
})

local challengeTab = farmSection:Tab({ Title = "Challenge", Icon = cascade.Symbols.trophy, Selected = false })
local challengeForm = challengeTab:Form()

local challengeToggleRow = challengeForm:Row()
challengeToggleRow:Left():ImageSurface({ Image = cascade.Symbols.shield, SurfaceColor = Color3.fromRGB(200, 80, 255) })
challengeToggleRow:Left():TitleStack({ Title = "Auto Daily Challenge", Subtitle = "Joins when Daily resets (every 24h)" })
challengeToggleRow:Right():Toggle({
    Value = false,
    ValueChanged = function(self, val)
        Config.AutoChallengeDaily = val
    end
})

local semiToggleRow = challengeForm:Row()
semiToggleRow:Left():ImageSurface({ Image = cascade.Symbols.bolt, SurfaceColor = Color3.fromRGB(100, 180, 255) })
semiToggleRow:Left():TitleStack({ Title = "Auto Semi-Hourly Challenge", Subtitle = "Joins when Semi-Hourly resets (every 30min)" })
semiToggleRow:Right():Toggle({
    Value = false,
    ValueChanged = function(self, val)
        Config.AutoChallengeSemi = val
    end
})

local raidTab = farmSection:Tab({ Title = "Raid", Icon = cascade.Symbols.bolt, Selected = false })
local raidForm = raidTab:Form()

local raidNames = {"Vastora Realm", "Ember Village", "Power Arena"}
local raidFloorPopUp = nil

local function UpdateRaidFloors(raidName)
    if not raidFloorPopUp then return end
    local floorCounts = {
        ["Vastora Realm"] = 6,
        ["Ember Village"] = 6,
        ["Power Arena"]   = 6,
    }
    local count = floorCounts[raidName] or 6
    local cur = #raidFloorPopUp.Options
    for i = cur, 1, -1 do raidFloorPopUp:Remove(i) end
    for i = 1, count do raidFloorPopUp:Option(tostring(i)) end
    raidFloorPopUp.Value = count
    Config.SelectedRaidFloor = count
end

local raidSelectRow = raidForm:Row()
raidSelectRow:Left():ImageSurface({ Image = cascade.Symbols.map, SurfaceColor = Color3.fromRGB(255, 100, 80) })
raidSelectRow:Left():TitleStack({ Title = "Raid Zone", Subtitle = "Select which raid to farm" })
raidSelectRow:Right():PopUpButton({
    Options = raidNames,
    Value = 1,
    ValueChanged = function(self, value)
        Config.SelectedRaid = self.Options[value]
        UpdateRaidFloors(Config.SelectedRaid)
    end
})

local raidFloorRow = raidForm:Row()
raidFloorRow:Left():ImageSurface({ Image = cascade.Symbols.listNumber, SurfaceColor = Color3.fromRGB(255, 160, 40) })
raidFloorRow:Left():TitleStack({ Title = "Raid Floor", Subtitle = "Which floor to battle" })
raidFloorPopUp = raidFloorRow:Right():PopUpButton({
    Options = {"1","2","3","4","5","6"},
    Value = 6,
    ValueChanged = function(self, value)
        Config.SelectedRaidFloor = value
    end
})

task.spawn(function()
    task.wait(0.5)
    UpdateRaidFloors(Config.SelectedRaid)
end)

local raidToggleRow = raidForm:Row()
raidToggleRow:Left():TitleStack({ Title = "Auto Raid", Subtitle = "Farms selected raid continuously" })
raidToggleRow:Right():Toggle({
    Value = false,
    ValueChanged = function(self, val)
        Config.AutoRaid = val
    end
})

local miscTab = miscSection:Tab({ Title = "Misc", Icon = cascade.Symbols.ellipsisHorizontal, Selected = false })
local miscForm = miscTab:Form()

local function AutoRedeemCodes()
    local ColorsList = { Purple = Color3.fromRGB(150, 100, 255), Green = Color3.fromRGB(80, 220, 120) }
    local success, err = pcall(function()
        local currentTime = os.time()
        UIHandler.Notify("Checking codes...", ColorsList.Purple)
        for code, info in pairs(codes_api.Codes) do
            local codeStr = tostring(code):lower()
            if not (currentTime > info.Expires) and not Data.Codes[codeStr] then
                RemoteEvent:FireServer("codes", codeStr)
                UIHandler.Notify("Redeemed: " .. codeStr, ColorsList.Green)
                UIHandler.Confetti()
                task.wait(1.5)
            end
        end
        UIHandler.Notify("Done!", ColorsList.Purple)
    end)
    if not success then warn("[AS2 Farm] Redeem Fail: " .. tostring(err)) end
end

local redeemRow = miscForm:Row()
redeemRow:Left():ImageSurface({ Image = cascade.Symbols.ticket, SurfaceColor = Color3.fromRGB(240, 180, 40) })
redeemRow:Left():TitleStack({ Title = "Auto Redeem All", Subtitle = "Claims all valid codes" })
redeemRow:Right():Button({ Label = "Redeem Now", State = "Primary", Pushed = function(self) AutoRedeemCodes() end })

local achievementRow = miscForm:Row()
achievementRow:Left():ImageSurface({ Image = cascade.Symbols.trophy, SurfaceColor = Color3.fromRGB(80, 180, 255) })
achievementRow:Left():TitleStack({ Title = "Claim Achievements", Subtitle = "Collects all completed rewards" })
achievementRow:Right():Button({
    Label = "Claim All",
    State = "Primary",
    Pushed = function()
        RemoteEvent:FireServer("achievement_claimall")
        UIHandler.Notify("Achievements Claimed!", Color3.fromRGB(80, 180, 255))
    end
})

local function TeleportToLobby()
    RemoteEvent:FireServer("teleport", "Lobby")
    task.wait(1.5)
    LocalPlayer:SetAttribute("World", "Lobby")
end

local function WaitForLobby(timeout)
    timeout = timeout or 15
    local start = os.time()
    repeat task.wait(0.5) until LocalPlayer:GetAttribute("World") == "Lobby" or (os.time() - start > timeout)
end

local function WaitForBattleStart(timeout)
    timeout = timeout or 15
    local start = os.time()
    repeat task.wait(0.5) until LocalPlayer:GetAttribute("World") ~= "Lobby" or (os.time() - start > timeout)
end

local function WaitForBattleEnd(timeout)
    timeout = timeout or 300
    local ResultUI = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("battle"):WaitForChild("Result")
    local start = os.time()
    repeat task.wait(1) until ResultUI:GetAttribute("Open") or os.time() > start + timeout or LocalPlayer:GetAttribute("World") == "Lobby"
end

local function LeaveBattle()
    local currentBattleData = battle_data.Battle
    local owner = (currentBattleData and currentBattleData.Owner) or LocalPlayer
    RemoteEvent:FireServer("battle_request_leave", owner)
    RemoteEvent:FireServer("portal_exit")
    pcall(function()
        UIHandler.CloseAllUI()
        player_manager.ShowUI()
        if PlayerAPIs.topbar then PlayerAPIs.topbar.Hide("Leave") end
    end)
    pcall(function()
        LocalPlayer.PlayerGui:WaitForChild("battle").Enabled = false
    end)
    TeleportToLobby()
    WaitForLobby()
    if battle_data.Clear then battle_data.Clear() end
end

local function ExecuteSlimePortalStart()
    if LocalPlayer:GetAttribute("World") ~= "Lobby" then
        TeleportToLobby()
        WaitForLobby()
        task.wait(1)
    end

    local Char = LocalPlayer.Character
    if not (Char and Char.PrimaryPart) then
        warn("[Portal] No character or PrimaryPart")
        PortalIsProcessing = false
        return
    end

    local targetCFrame = CFrame.new(
        1297.68213, 45.2738342, -1228.9574,
        -0.481051326, 0,  0.876692414,
         0,           1,  0,
        -0.876692414, 0, -0.481051326
    )
    Char:SetPrimaryPartCFrame(targetCFrame)
    task.wait(1.5)

    local prompt
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local part = v.Parent
            if part and part:IsA("BasePart") then
                local dist = (part.Position - Char.PrimaryPart.Position).Magnitude
                if dist < 20 then
                    prompt = v
                    break
                end
            end
        end
    end

    if prompt then
        warn("[Portal] Found prompt, firing: " .. prompt.Parent.Name)
        fireproximityprompt(prompt)
        task.wait(1)
    else
        warn("[Portal] No ProximityPrompt found near position, firing portal_start anyway")
    end

    RemoteEvent:FireServer("portal_start")
end

task.spawn(function()
    local PortalHUD = MainGui:WaitForChild("Portal")
    local StartBtn = PortalHUD:WaitForChild("StartBtn")
    while true do
        task.wait(0.5)
        if Config.AutoStartPortal and not IsDoingChallenge then
            if LocalPlayer:GetAttribute("World") == "Lobby" and not PortalIsProcessing then
                PortalIsProcessing = true
                task.spawn(ExecuteSlimePortalStart)
                task.wait(8)
                PortalIsProcessing = false
            elseif PortalHUD.Visible and StartBtn.Visible and not PortalIsProcessing then
                PortalIsProcessing = true
                RemoteEvent:FireServer("portal_start")
                task.wait(5)
                PortalIsProcessing = false
            elseif not PortalHUD.Visible and not (LocalPlayer:GetAttribute("World") == "Lobby") then
                PortalIsProcessing = false
            end
        end
    end
end)

function JoinBattle()
    if Config.AutoFarm and LocalPlayer:GetAttribute("World") == "Lobby" and not IsDoingChallenge and not IsDoingRaid then
        network.SendServer("battle_start", "story", Config.SelectedWorld, Config.SelectedStage, Config.SelectedDifficulty)
    end
end

LocalPlayer:GetAttributeChangedSignal("World"):Connect(JoinBattle)

local function GetCurrentChallengeIndex(cType)
    local data = challenges.Data(cType)
    if data then return data.Index end
    return -1
end

local function IsNewChallenge(cType)
    return GetCurrentChallengeIndex(cType) ~= LastChallengeIndex[cType]
end

local function DoAutoChallenge(cType)
    if IsDoingChallenge then return end
    if not IsNewChallenge(cType) then return end

    local data = challenges.Data(cType)
    if not data then return end

    if challenges.IsComplete(Data, cType) then
        LastChallengeIndex[cType] = data.Index
        return
    end

    IsDoingChallenge = true

    local wasPortal = Config.AutoStartPortal
    local wasRaid   = Config.AutoRaid
    local wasFarm   = Config.AutoFarm

    if wasPortal then
        PreviousTask = "portal"
        Config.AutoStartPortal = false
        PortalIsProcessing = false
        RemoteEvent:FireServer("portal_exit")
    elseif wasRaid then
        PreviousTask = "raid"
        Config.AutoRaid = false
    elseif wasFarm then
        PreviousTask = "story"
    end

    local ok, err = pcall(function()
        if LocalPlayer:GetAttribute("World") ~= "Lobby" then
            UIHandler.Notify("[Auto Challenge] Leaving current battle...", Color3.fromRGB(200, 80, 255))
            LeaveBattle()
            task.wait(2)
        end

        UIHandler.Notify("[Auto Challenge] Joining " .. cType .. " | " .. data.World .. " | " .. data.Debuff, Color3.fromRGB(200, 80, 255))

        local ChallengeFolder = workspace:WaitForChild("Rooms", 10):WaitForChild("challenges", 10)
        local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local Root = Char:WaitForChild("HumanoidRootPart", 10)

        if ChallengeFolder and Root then
            local targetModel = ChallengeFolder:FindFirstChildOfClass("Model")
            if targetModel then
                local TouchPart = targetModel:FindFirstChild("Touch")
                if TouchPart and TouchPart:IsA("BasePart") then
                    Root.CFrame = TouchPart.CFrame * CFrame.new(0, 3, 0)
                    task.wait(0.5)
                else
                    warn("[Auto Challenge] Touch part not found, falling back to model pivot")
                    Root.CFrame = targetModel:GetPivot() * CFrame.new(0, 5, 0)
                    task.wait(0.5)
                end
            end
        end

        task.wait(1)
        RemoteEvent:FireServer("room_select", data.World, 7, {
            ChallengeType = cType,
            Debuff = data.Debuff
        })
        task.wait(3)

        local started = false
        for i = 1, 5 do
            warn("[Auto Challenge] room_start attempt " .. i)
            RemoteEvent:FireServer("room_start")
            task.wait(2)
            if LocalPlayer:GetAttribute("World") ~= "Lobby" then
                started = true
                warn("[Auto Challenge] Battle started successfully")
                break
            end
        end

        if not started then
            warn("[Auto Challenge] room_start failed after 5 attempts")
            IsDoingChallenge = false
            return
        end

        LastChallengeIndex[cType] = data.Index

        WaitForBattleEnd(180)
        task.wait(1)

        -- [FIX] Leave challenge อย่างถูกต้อง
        RemoteEvent:FireServer("battle_request_leave", LocalPlayer)
        pcall(function()
            UIHandler.CloseAllUI()
            player_manager.ShowUI()
            if PlayerAPIs.topbar then PlayerAPIs.topbar.Hide("Leave") end
        end)
        pcall(function()
            LocalPlayer.PlayerGui:WaitForChild("battle").Enabled = false
        end)
        TeleportToLobby()
        WaitForLobby(15)
        if battle_data.Clear then battle_data.Clear() end
        task.wait(2)
    end)

    if not ok then warn("[Challenge] Error: " .. tostring(err)) end

    UIHandler.Notify("[Auto Challenge] Done! Restoring previous task...", Color3.fromRGB(80, 220, 120))

    if PreviousTask == "portal" then
        Config.AutoStartPortal = true
    elseif PreviousTask == "raid" then
        Config.AutoRaid = true
    elseif PreviousTask == "story" then
        Config.AutoFarm = true
        if LocalPlayer:GetAttribute("World") == "Lobby" then
            JoinBattle()
        end
    end

    PreviousTask = nil
    IsDoingChallenge = false
end

local function DoAutoRaid()
    if IsDoingRaid or IsDoingChallenge then return end
    if LocalPlayer:GetAttribute("World") ~= "Lobby" then return end

    IsDoingRaid = true

    local ok, err = pcall(function()
        UIHandler.Notify("[Auto Raid] Joining " .. Config.SelectedRaid .. " Floor " .. Config.SelectedRaidFloor, Color3.fromRGB(255, 100, 80))

        local RaidFolder = workspace:WaitForChild("Rooms", 10):WaitForChild("raid", 10)
        local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local Root = Char:WaitForChild("HumanoidRootPart", 10)

        if RaidFolder and Root then
            local targetModel = RaidFolder:GetChildren()[2]
            if targetModel then
                local TouchPart = targetModel:FindFirstChild("Touch")
                if TouchPart and TouchPart:IsA("BasePart") then
                    Root.CFrame = TouchPart.CFrame * CFrame.new(0, 3, 0)
                    task.wait(0.5)
                else
                    warn("[Auto Raid] Touch part not found, falling back to model pivot")
                    Root.CFrame = targetModel:GetPivot() * CFrame.new(0, 5, 0)
                    task.wait(0.5)
                end
            end
        end

        task.wait(1)
        RemoteEvent:FireServer("room_select", Config.SelectedRaid, Config.SelectedRaidFloor)
        task.wait(3)

        local started = false
        for i = 1, 5 do
            warn("[Auto Raid] room_start attempt " .. i)
            RemoteEvent:FireServer("room_start")
            task.wait(2)
            if LocalPlayer:GetAttribute("World") ~= "Lobby" then
                started = true
                warn("[Auto Raid] Battle started successfully")
                break
            end
        end

        if not started then
            warn("[Auto Raid] room_start failed after 5 attempts")
            IsDoingRaid = false
            return
        end

        WaitForBattleEnd(300)
        task.wait(1)
    end)

    if not ok then warn("[Raid] Error: " .. tostring(err)) end
    IsDoingRaid = false
end

local ResultUI = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("battle"):WaitForChild("Result")

local function ProcessFinalResult()
    if not ResultUI:GetAttribute("Open") then return end
    task.wait(0.5)

    if IsDoingChallenge or IsDoingRaid then return end

    if Config.AutoReplay then
        network.SendServer("battle_replay")
    elseif Config.AutoLeave then
        local currentBattleData = battle_data.Battle
        local owner = (currentBattleData and currentBattleData.Owner) or LocalPlayer

        RemoteEvent:FireServer("battle_request_leave", owner)
        RemoteEvent:FireServer("portal_exit")

        pcall(function()
            UIHandler.CloseAllUI()
            player_manager.ShowUI()
            if PlayerAPIs.topbar then PlayerAPIs.topbar.Hide("Leave") end
        end)

        LocalPlayer.PlayerGui:WaitForChild("battle").Enabled = false
        TeleportToLobby()

        if currentBattleData and currentBattleData.Position then
            worlds.Teleport(LocalPlayer, currentBattleData.Position.Position, currentBattleData.Position)
        else
            RemoteFunction:InvokeServer("teleport_player_cs", {X = 1561.4616699219, Y = 50.511741638184, Z = -1186.0816650391})
        end
        if battle_data.Clear then battle_data.Clear() end
    end
end

ResultUI:GetAttributeChangedSignal("Open"):Connect(ProcessFinalResult)

task.spawn(function()
    local PortalHUD = MainGui:WaitForChild("Portal")
    local StartBtn = PortalHUD:WaitForChild("StartBtn")
    while true do
        task.wait(0.5)
        if Config.AutoStartPortal and not IsDoingChallenge then
            local isVisible = PortalHUD.Visible and StartBtn.Visible
            if isVisible and not PortalIsProcessing then
                PortalIsProcessing = true
                ExecuteSlimePortalStart()
                task.wait(5)
            elseif not isVisible and PortalIsProcessing then
                PortalIsProcessing = false
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        if not IsDoingChallenge then
            if Config.AutoChallengeDaily and IsNewChallenge("Daily") then
                DoAutoChallenge("Daily")
            elseif Config.AutoChallengeSemi and IsNewChallenge("Semi-Hourly") then
                DoAutoChallenge("Semi-Hourly")
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(3)
        if Config.AutoRaid and not IsDoingChallenge and not IsDoingRaid then
            if LocalPlayer:GetAttribute("World") == "Lobby" then
                DoAutoRaid()
            end
        end
    end
end)
