if getgenv().GhostHubAAS_Running then
    getgenv().GhostHubAAS_Running = false   
end

if getgenv().GhostHubAAS_Window then
    pcall(function() getgenv().GhostHubAAS_Window:Destroy() end)
    getgenv().GhostHubAAS_Window = nil
end

local Players_ = game:GetService("Players")
local CoreGui_ = game:GetService("CoreGui")
pcall(function()
    local old = CoreGui_:FindFirstChild("AASToggleGui")
    if old then old:Destroy() end
end)
pcall(function()
    local old = Players_.LocalPlayer.PlayerGui:FindFirstChild("AASToggleGui")
    if old then old:Destroy() end
end)

task.wait(0.2)

getgenv().GhostHubAAS_Running = true

local function isRunning()
    return getgenv().GhostHubAAS_Running == true
end

if game.PlaceId ~= 113236157544232 then
    warn("Failed to load: This script only supports Anime Astral Simulator")
    return
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then
    warn("Failed to load UI! Please check your internet or try restarting your Executor")
    return
end

WindUI:SetNotificationLower(true)

WindUI:AddTheme({
    Name                          = "GhostHub",
    Accent                        = Color3.fromHex("#1a0a0a"),
    Background                    = Color3.fromHex("#0d0d0d"),
    BackgroundTransparency        = 0,
    Outline                       = Color3.fromHex("#c0392b"),
    Text                          = Color3.fromHex("#f0f0f0"),
    Placeholder                   = Color3.fromHex("#7a3030"),
    Button                        = Color3.fromHex("#7f1d1d"),
    Icon                          = Color3.fromHex("#e87070"),
    Hover                         = Color3.fromHex("#f0f0f0"),
    WindowBackground              = Color3.fromHex("#0d0d0d"),
    WindowShadow                  = Color3.fromHex("#000000"),
    DialogBackground              = Color3.fromHex("#0d0d0d"),
    DialogBackgroundTransparency  = 0,
    DialogTitle                   = Color3.fromHex("#f0f0f0"),
    DialogContent                 = Color3.fromHex("#cccccc"),
    DialogIcon                    = Color3.fromHex("#e87070"),
    WindowTopbarButtonIcon        = Color3.fromHex("#e87070"),
    WindowTopbarTitle             = Color3.fromHex("#f0f0f0"),
    WindowTopbarAuthor            = Color3.fromHex("#cccccc"),
    WindowTopbarIcon              = Color3.fromHex("#f0f0f0"),
    TabBackground                 = Color3.fromHex("#1a0a0a"),
    TabTitle                      = Color3.fromHex("#f0f0f0"),
    TabIcon                       = Color3.fromHex("#e87070"),
    ElementBackground             = Color3.fromHex("#1f0d0d"),
    ElementTitle                  = Color3.fromHex("#f0f0f0"),
    ElementDesc                   = Color3.fromHex("#aaaaaa"),
    ElementIcon                   = Color3.fromHex("#e87070"),
    PopupBackground               = Color3.fromHex("#0d0d0d"),
    PopupBackgroundTransparency   = 0,
    PopupTitle                    = Color3.fromHex("#f0f0f0"),
    PopupContent                  = Color3.fromHex("#cccccc"),
    PopupIcon                     = Color3.fromHex("#e87070"),
    Toggle                        = Color3.fromHex("#7f1d1d"),
    ToggleBar                     = Color3.fromHex("#e84040"),
    Checkbox                      = Color3.fromHex("#7f1d1d"),
    CheckboxIcon                  = Color3.fromHex("#f0f0f0"),
    Slider                        = Color3.fromHex("#7f1d1d"),
    SliderThumb                   = Color3.fromHex("#e84040"),
})

local Window = WindUI:CreateWindow({
    Title                       = "Anime Astral Simulator — Ghost Hub",
    Icon                        = "rbxassetid://110552700896064",
    Author                      = "GhostHub",
    Folder                      = "GhostHub/AAS",
    Size                        = UDim2.fromOffset(620, 500),
    MinSize                     = Vector2.new(560, 380),
    MaxSize                     = Vector2.new(860, 580),
    Transparent                 = true,
    Theme                       = "GhostHub",
    AccentColor                 = Color3.fromHex("#c0392b"),
    Resizable                   = true,
    SideBarWidth                = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar               = true,
    ScrollBarEnabled            = false,
})
getgenv().GhostHubAAS_Window = Window

Window:Tag({ Title = "Free",    Icon = "key-square", Color = Color3.fromHex("#0011ff"), Radius = 6 })
Window:Tag({ Title = "v.1.0.6", Icon = "",           Color = Color3.fromHex("#30ff6a"), Radius = 6 })

-- ============================================================
--  SERVICES
-- ============================================================
local Players         = game:GetService("Players")
local RS              = game:GetService("ReplicatedStorage")
local player          = Players.LocalPlayer

-- ============================================================
--  REMOTE  (BridgeNet2)
-- ============================================================
local dataRemoteEvent = nil
task.spawn(function()
    dataRemoteEvent = RS:WaitForChild("BridgeNet2", 15)
                       :WaitForChild("dataRemoteEvent", 15)
end)

local function fireRemote(args)
    if dataRemoteEvent then
        pcall(function()
            dataRemoteEvent:FireServer(unpack(args))
        end)
    end
end

-- ============================================================
--  CONFIG
-- ============================================================
local HttpService = game:GetService("HttpService")
local Options     = {}

local function GetConfigPath()
    return "AAS_GH/" .. tostring(player.UserId) .. "_AAS.json"
end

local lastSave = 0
local function SaveConfig()
    lastSave = tick()
    local snap = lastSave
    task.delay(1, function()
        if lastSave ~= snap then return end
        if not (writefile and makefolder) then return end
        local path   = GetConfigPath()
        local folder = path:match("(.+)/")
        if not isfolder(folder) then
            local cur = ""
            for _, p in ipairs(folder:split("/")) do
                cur = cur .. p
                if not isfolder(cur) then makefolder(cur) end
                cur = cur .. "/"
            end
        end
        writefile(path, HttpService:JSONEncode(Options))
    end)
end

local function LoadConfig()
    if not (readfile and isfile) then return end
    local path = GetConfigPath()
    if isfile(path) then
        local ok, res = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if ok and res then
            for k, v in pairs(res) do Options[k] = v end
        end
    end
end
LoadConfig()

-- ============================================================
--  HELPERS
-- ============================================================

local function normalizeMultiValue(v)
    local result = {}
    if type(v) == "table" then
        if #v > 0 then
            for _, val in ipairs(v) do
                if type(val) == "string" then table.insert(result, val) end
            end
        else
            for k, val in pairs(v) do
                if type(k) == "string" and val == true then table.insert(result, k) end
            end
        end
    elseif type(v) == "string" and v ~= "" then
        table.insert(result, v)
    end
    return result
end

local function getEnemyFolder(worldFolderName)
    local worlds = workspace:FindFirstChild("Worlds")
    if not worlds then return nil end
    local wf = worlds:FindFirstChild(tostring(worldFolderName))
    if not wf then return nil end
    return wf:FindFirstChild("Enemies")
end

local function getEnemyNamesFromWorkspace(worldFolderName)
    local folder = getEnemyFolder(worldFolderName)
    if not folder then return {} end
    local seen  = {}
    local names = {}
    for _, model in ipairs(folder:GetChildren()) do
        local n = model.Name
        if not seen[n] then
            seen[n] = true
            table.insert(names, n)
        end
    end
    table.sort(names)
    return names
end

local function isEnemyDead(model)
    if not model or not model.Parent then return true end
    if model:GetAttribute("EnemyDead") == true then return true end
    local hum = model:FindFirstChildOfClass("Humanoid")
    return not hum or hum.Health <= 0
end

local function findNearest(enemyFolder, allowSet)
    local myPos = (player.Character
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character.HumanoidRootPart.Position) or Vector3.zero

    local bestModel, bestDist = nil, math.huge
    for _, model in ipairs(enemyFolder:GetChildren()) do
        if allowSet and not allowSet[model.Name] then continue end
        if isEnemyDead(model) then continue end
        local tHRP = model:FindFirstChild("HumanoidRootPart")
        if tHRP then
            local d = (tHRP.Position - myPos).Magnitude
            if d < bestDist then
                bestDist  = d
                bestModel = model
            end
        end
    end
    return bestModel
end

local function teleportTo(model)
    local hrp  = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local tHRP = model and model:FindFirstChild("HumanoidRootPart")
    if hrp and tHRP then
        hrp.CFrame = tHRP.CFrame * CFrame.new(0, 3, 0)
    end
end

local function stayNear(model)
    local hrp  = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local tHRP = model and model:FindFirstChild("HumanoidRootPart")
    if hrp and tHRP and (hrp.Position - tHRP.Position).Magnitude > 8 then
        hrp.CFrame = tHRP.CFrame * CFrame.new(0, 3, 0)
    end
end

-- ============================================================
--  STATE FLAGS
-- ============================================================
local isAutoFarm      = false
local isAutoTrial     = false
local isAutoRaid      = false
local selectedWorld   = Options.SelectedWorld or "1"
local selectedEnemies = normalizeMultiValue(Options.SelectedEnemies or {})


local currentActivity = nil  

local function tryAcquireActivity(name)
    if currentActivity == nil or currentActivity == name then
        currentActivity = name
        return true
    end
    return false
end

local function releaseActivity(name)
    if currentActivity == name then
        currentActivity = nil
    end
end

-- ============================================================
--  TABS
-- ============================================================
local FarmTab     = Window:Tab({ Title = "Farming",  Icon = "swords"   })
local GamemodeTab = Window:Tab({ Title = "Gamemode", Icon = "gamepad-2" })
local MiscTab     = Window:Tab({ Title = "Misc",     Icon = "gift"     })
local SettingTab  = Window:Tab({ Title = "Settings", Icon = "cog"      })

task.spawn(function()
    task.wait(1)
    WindUI:Notify({ Title = "Ghost Hub v1.0.6", Content = "Anime Astral Simulator loaded!", Duration = 4 })
end)
task.defer(function() Window:SetToggleKey(Enum.KeyCode.LeftControl) end)

-- ============================================================
--  TAB: FARMING
-- ============================================================
FarmTab:Section({ Title = "World & Enemy Selection" })

local worldFolderNames = { "1", "2", "3", "4", "5", "6", "7" }
local EnemyDropdown

local function refreshEnemyDropdown()
    local names = getEnemyNamesFromWorkspace(selectedWorld)
    if EnemyDropdown then
        EnemyDropdown:Refresh(names)
        local nameSet = {}
        for _, n in ipairs(names) do nameSet[n] = true end
        local filtered = {}
        for _, n in ipairs(selectedEnemies) do
            if nameSet[n] then table.insert(filtered, n) end
        end
        selectedEnemies = filtered
        Options.SelectedEnemies = selectedEnemies
        SaveConfig()
    end
    return names
end

FarmTab:Dropdown({
    Title    = "Select World",
    Icon     = "globe",
    Values   = worldFolderNames,
    Value    = selectedWorld,
    Callback = function(v)
        selectedWorld = tostring(v)
        Options.SelectedWorld = selectedWorld
        SaveConfig()
        selectedEnemies = {}
        Options.SelectedEnemies = {}
        SaveConfig()
        refreshEnemyDropdown()
    end
})

local initNames = getEnemyNamesFromWorkspace(selectedWorld)
if #initNames == 0 then initNames = { "— Click Refresh —" } end

EnemyDropdown = FarmTab:Dropdown({
    Title     = "Select Enemies (optional)",
    Icon      = "target",
    Values    = initNames,
    Value     = selectedEnemies,
    Multi     = true,
    AllowNone = true,
    Callback  = function(v)
        selectedEnemies = normalizeMultiValue(v)
        Options.SelectedEnemies = selectedEnemies
        SaveConfig()
    end
})

FarmTab:Button({
    Title    = "Refresh Enemy List",
    Icon     = "refresh-cw",
    Callback = function()
        local names = refreshEnemyDropdown()
        WindUI:Notify({
            Title   = "Refresh",
            Content = string.format("World %s — found %d enemy types", selectedWorld, #names),
            Duration = 3
        })
    end
})

FarmTab:Divider()
FarmTab:Section({ Title = "Auto Actions" })

FarmTab:Toggle({
    Title    = "Auto Farm",
    Icon     = "crosshair",
    Desc     = "Farm only the enemies selected above",
    Type     = "Checkbox",
    Value    = Options.AutoFarm or false,
    Callback = function(v)
        if v and #selectedEnemies == 0 then
            WindUI:Notify({
                Title   = "Auto Farm",
                Content = "Please select at least one enemy in the dropdown first!",
                Duration = 4
            })
            return
        end

        isAutoFarm = v
        Options.AutoFarm = v
        SaveConfig()
        if not isAutoFarm then return end

        task.spawn(function()
            while isAutoFarm and isRunning() do
                if #selectedEnemies == 0 then
                    WindUI:Notify({
                        Title   = "Auto Farm",
                        Content = "No enemy selected — stopping Auto Farm.",
                        Duration = 4
                    })
                    isAutoFarm = false
                    Options.AutoFarm = false
                    SaveConfig()
                    break
                end

                -- Don't move/teleport while Trial or Raid owns the activity lock
                if not tryAcquireActivity("Farm") then
                    task.wait(0.5)
                    continue
                end

                local enemyFolder = getEnemyFolder(selectedWorld)
                if not enemyFolder then releaseActivity("Farm") task.wait(0.5) continue end

                local allowSet = {}
                for _, name in ipairs(selectedEnemies) do allowSet[name] = true end

                local target = findNearest(enemyFolder, allowSet)
                if not target then releaseActivity("Farm") task.wait(0.5) continue end

                teleportTo(target)

                while isAutoFarm and isRunning() do
                    if isEnemyDead(target) then break end
                    -- another higher-priority activity may steal the lock externally; if so, stop moving
                    if currentActivity ~= "Farm" then break end
                    stayNear(target)
                    task.wait(0.1)
                end

                releaseActivity("Farm")
                task.wait(0.05)
            end
            releaseActivity("Farm")
        end)
    end
})

-- ============================================================
--  TAB: GAMEMODE — TIME TRIAL EASY
-- ============================================================
GamemodeTab:Section({ Title = "Time Trial" })

local function joinTrialEasy()
    pcall(function()
        RS:WaitForChild("BridgeNet2", 10):WaitForChild("dataRemoteEvent", 10)
          :FireServer({ { __BridgeTuplePayload__ = true, Payload = { "Join", "Easy", n = 2 } }, "\207" })
    end)
end

local function leaveTrialEasy()
    pcall(function()
        RS:WaitForChild("BridgeNet2", 10):WaitForChild("dataRemoteEvent", 10)
          :FireServer({ { [2] = "\208" } })
    end)
end

local function getTrialEnemyFolder()
    local ta = workspace:FindFirstChild("TimeTrialArenas")
    if not ta then return nil end
    local easy = ta:FindFirstChild("Easy")
    if not easy then return nil end
    return easy:FindFirstChild("Enemies")
end

local function secondsUntilNextTrial()
    local sec = os.time() % 1800
    return 1800 - sec
end

GamemodeTab:Toggle({
    Title    = "Auto Trial Easy",
    Icon     = "timer",
    Desc     = "Join Trial Easy every xx:00 / xx:30 and farm enemies in the Arena",
    Type     = "Checkbox",
    Value    = Options.AutoTrial or false,
    Callback = function(v)
        isAutoTrial = v
        Options.AutoTrial = v
        SaveConfig()
        if not isAutoTrial then return end

        task.spawn(function()
            while isAutoTrial and isRunning() do
                local wait = secondsUntilNextTrial()
                if wait < 5 then wait = wait + 1800 end

                WindUI:Notify({
                    Title   = "Auto Trial Easy",
                    Content = string.format("Waiting %d min %d sec for next Trial", math.floor((wait-1)/60), (wait-1)%60),
                    Duration = 5
                })

                task.wait(wait - 3)
                if not isAutoTrial or not isRunning() then break end

                -- wait until Farm/Raid release the activity lock before joining
                while not tryAcquireActivity("Trial") and isAutoTrial and isRunning() do
                    task.wait(0.5)
                end
                if not isAutoTrial or not isRunning() then break end

                joinTrialEasy()
                WindUI:Notify({ Title = "Auto Trial Easy", Content = "Joining Trial Easy...", Duration = 3 })

                local trialEnemyFolder = nil
                local waited = 0
                repeat
                    task.wait(1) waited = waited + 1
                    trialEnemyFolder = getTrialEnemyFolder()
                until (trialEnemyFolder and #trialEnemyFolder:GetChildren() > 0) or waited > 20

                if not trialEnemyFolder or #trialEnemyFolder:GetChildren() == 0 then
                    WindUI:Notify({ Title = "Auto Trial Easy", Content = "No enemies found in Arena — skipping this round", Duration = 4 })
                    leaveTrialEasy()
                    releaseActivity("Trial")
                    continue
                end

                WindUI:Notify({ Title = "Auto Trial Easy", Content = "Starting to farm Trial Easy!", Duration = 3 })

                while isAutoTrial and isRunning() do
                    local target = findNearest(trialEnemyFolder, nil)
                    if not target then break end
                    teleportTo(target)
                    while isAutoTrial and isRunning() do
                        if isEnemyDead(target) then break end
                        stayNear(target)
                        task.wait(0.1)
                    end
                    task.wait(0.05)
                end

                leaveTrialEasy()
                releaseActivity("Trial")

                WindUI:Notify({ Title = "Auto Trial Easy", Content = "Trial complete! Waiting for next round...", Duration = 5 })
                task.wait(10)
            end
            releaseActivity("Trial")
        end)
    end
})

-- ============================================================
--  TAB: GAMEMODE — NARUTO RAID  (World1 only, fixed)
-- ============================================================
GamemodeTab:Divider()
GamemodeTab:Section({ Title = "Naruto Raid (World1)" })

local RAID_WORLD    = "World1"   -- ล็อกใช้แค่ World1 เท่านั้น
local raidLeaveWave = Options.RaidLeaveWave or 100

local function fireJoinRaid()
    pcall(function()
        local remote = RS:WaitForChild("BridgeNet2", 10)
                          :WaitForChild("dataRemoteEvent", 10)
        remote:FireServer({
            {
                __BridgeTuplePayload__ = true,
                Payload = { "Create", RAID_WORLD, n = 2 }
            },
            "\149"
        })
    end)
end

local function fireLeaveRaid()
    pcall(function()
        local remote = RS:WaitForChild("BridgeNet2", 10)
                          :WaitForChild("dataRemoteEvent", 10)
        remote:FireServer({ { [2] = "\151" } })
    end)
end

local function getRaidEnemyFolder()
    local arenas = workspace:FindFirstChild("RaidArenas")
    if not arenas then return nil end
    local wf = arenas:FindFirstChild(RAID_WORLD)
    if not wf then return nil end
    return wf:FindFirstChild("Enemies")
end

-- อ่าน Wave จาก PlayerGui.RaidGui.Main.Wave (Text = "Wave X/100")
local function getCurrentWave()
    local cur, max = 0, 0
    pcall(function()
        local raidGui   = player.PlayerGui:FindFirstChild("RaidGui")
        local waveLabel = raidGui
            and raidGui:FindFirstChild("Main")
            and raidGui.Main:FindFirstChild("Wave")
        if waveLabel then
            local c, m = waveLabel.Text:match("Wave%s+(%d+)/(%d+)")
            cur = tonumber(c) or 0
            max = tonumber(m) or 0
        end
    end)
    return cur, max
end

local function isInRaid()
    local ok, result = pcall(function()
        local gui = player.PlayerGui:FindFirstChild("RaidGui")
        return gui ~= nil and gui.Enabled == true
    end)
    return ok and result
end

GamemodeTab:Slider({
    Title    = "Leave at Wave",
    Icon     = "flag",
    Desc     = "Automatically leave Raid at this Wave (1 - 100)",
    Value    = { Min=1, Max=100, Default=raidLeaveWave },
    Rounding = 0,
    Callback = function(v)
        raidLeaveWave = v
        Options.RaidLeaveWave = v
        SaveConfig()
    end
})

GamemodeTab:Toggle({
    Title    = "Auto Raid (World1)",
    Icon     = "sword",
    Desc     = "Join -> Kill enemies -> Leave at target Wave -> repeat",
    Type     = "Checkbox",
    Value    = Options.AutoRaid or false,
    Callback = function(v)
        isAutoRaid = v
        Options.AutoRaid = v
        SaveConfig()
        if not isAutoRaid then return end

        task.spawn(function()
            while isAutoRaid and isRunning() do

                -- wait until Farm/Trial release the activity lock before joining
                while not tryAcquireActivity("Raid") and isAutoRaid and isRunning() do
                    task.wait(0.5)
                end
                if not isAutoRaid or not isRunning() then break end

                -- ── Step 1: Join Raid ──────────────────────────────────
                fireJoinRaid()
                WindUI:Notify({
                    Title   = "Auto Raid",
                    Content = "Joining Raid: " .. RAID_WORLD .. "...",
                    Duration = 3
                })

                -- ── Step 2: รอ RaidGui Enabled (ยืนยันเข้าได้แล้ว) ────
                local joinWait = 0
                repeat
                    task.wait(1)
                    joinWait = joinWait + 1
                until isInRaid() or joinWait > 20

                if not isInRaid() then
                    WindUI:Notify({
                        Title   = "Auto Raid",
                        Content = "Failed to join Raid — retrying...",
                        Duration = 4
                    })
                    releaseActivity("Raid")
                    task.wait(5)
                    continue
                end

                -- ── Step 3: รอ Enemies folder มีมอน ──────────────────
                local raidEnemyFolder = nil
                local waited = 0
                repeat
                    task.wait(1)
                    waited = waited + 1
                    raidEnemyFolder = getRaidEnemyFolder()
                until (raidEnemyFolder and #raidEnemyFolder:GetChildren() > 0) or waited > 20

                if not raidEnemyFolder or #raidEnemyFolder:GetChildren() == 0 then
                    WindUI:Notify({
                        Title   = "Auto Raid",
                        Content = "Enemy folder not found — leaving & retrying...",
                        Duration = 4
                    })
                    fireLeaveRaid()
                    releaseActivity("Raid")
                    task.wait(5)
                    continue
                end

                WindUI:Notify({
                    Title   = "Auto Raid",
                    Content = string.format("Joined Raid! Will leave at Wave %d", raidLeaveWave),
                    Duration = 3
                })

                -- ── Step 4: ฆ่ามอน + ตรวจ Wave ──────────────────────
                local shouldLeave = false

                while isAutoRaid and isRunning() and not shouldLeave do

                    local curWave, maxWave = getCurrentWave()
                    if curWave >= raidLeaveWave then
                        WindUI:Notify({
                            Title   = "Auto Raid",
                            Content = string.format("Wave %d/%d — Leaving now!", curWave, maxWave),
                            Duration = 4
                        })
                        shouldLeave = true
                        break
                    end

                    if not isInRaid() then
                        WindUI:Notify({
                            Title   = "Auto Raid",
                            Content = "Left Raid (by server) — rejoining...",
                            Duration = 4
                        })
                        break
                    end

                    local target = findNearest(raidEnemyFolder, nil)
                    if not target then
                        task.wait(0.3)
                        continue
                    end

                    teleportTo(target)

                    while isAutoRaid and isRunning() do
                        if isEnemyDead(target) then break end

                        local cw = getCurrentWave()
                        if cw >= raidLeaveWave then
                            shouldLeave = true
                            break
                        end

                        if not isInRaid() then
                            shouldLeave = false
                            break
                        end

                        stayNear(target)
                        task.wait(0.1)
                    end

                    task.wait(0.05)
                end

                -- ── Step 5: Leave ถ้าถึง wave ───────────────────────
                if shouldLeave then
                    fireLeaveRaid()
                    WindUI:Notify({
                        Title   = "Auto Raid",
                        Content = "Left Raid — waiting 5s before rejoining...",
                        Duration = 5
                    })
                    task.wait(5)
                end

                releaseActivity("Raid")

                if isAutoRaid and isRunning() then
                    task.wait(3)
                end
            end
            releaseActivity("Raid")
        end)
    end
})

-- ============================================================
--  TAB: MISC — REWARDS
-- ============================================================
MiscTab:Section({ Title = "Rewards" })

MiscTab:Toggle({
    Title    = "Auto Claim Daily Reward",
    Icon     = "calendar",
    Type     = "Checkbox",
    Value    = Options.AutoDailyReward or false,
    Callback = function(v)
        Options.AutoDailyReward = v
        SaveConfig()
        if not v then return end
        task.spawn(function()
            while Options.AutoDailyReward and isRunning() do
                pcall(function()
                    for i = 1, 7 do
                        fireRemote({ { [2] = "\028", [1] = {"General","DailyRewards","Claim", i} } })
                        task.wait(0.3)
                    end
                end)
                task.wait(60)
            end
        end)
    end
})

MiscTab:Divider()
MiscTab:Section({ Title = "Character" })

local savedWalkSpeed = Options.WalkSpeed or 16

local function applyWalkSpeed(speed)
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = speed end
end

MiscTab:Slider({
    Title    = "WalkSpeed",
    Icon     = "footprints",
    Desc     = "Adjust your character's movement speed",
    Value    = { Min = 16, Max = 200, Default = savedWalkSpeed },
    Rounding = 0,
    Callback = function(v)
        savedWalkSpeed = v
        Options.WalkSpeed = v
        SaveConfig()
        applyWalkSpeed(v)
    end
})

-- Re-apply WalkSpeed whenever character (re)spawns
player.CharacterAdded:Connect(function(char)
    if not isRunning() then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        task.wait(0.2)
        hum.WalkSpeed = savedWalkSpeed
    end
end)

task.defer(function()
    if player.Character then
        applyWalkSpeed(savedWalkSpeed)
    end
end)

MiscTab:Divider()
MiscTab:Section({ Title = "Performance" })

MiscTab:Toggle({
    Title    = "Wipe VFX (Anti-Lag)",
    Icon     = "eye-off",
    Desc     = "Disables particles, trails, beams, etc.",
    Type     = "Checkbox",
    Value    = Options.WipeVFX or false,
    Callback = function(v)
        Options.WipeVFX = v
        SaveConfig()
        if not v then return end
        task.spawn(function()
            while Options.WipeVFX and isRunning() do
                pcall(function()
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
                        or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Smoke") then
                            obj.Enabled = false
                        end
                    end
                end)
                task.wait(30)
            end
        end)
    end
})

-- ============================================================
--  TAB: SETTINGS
-- ============================================================
SettingTab:Section({ Title = "General" })

SettingTab:Keybind({
    Title    = "Toggle UI Key",
    Desc     = "Keybind to show/hide the window",
    Value    = Options.ToggleUIKey or "LeftControl",
    Callback = function(v)
        Options.ToggleUIKey = tostring(v)
        SaveConfig()
        local key = typeof(v) == "EnumItem" and v or Enum.KeyCode[v]
        Window:SetToggleKey(key)
    end
})

SettingTab:Toggle({
    Title    = "Anti AFK",
    Icon     = "shield",
    Type     = "Checkbox",
    Value    = Options.AntiAFK or false,
    Callback = function(v) Options.AntiAFK = v SaveConfig() end
})

SettingTab:Toggle({
    Title    = "Auto Rejoin",
    Icon     = "plug",
    Desc     = "Reconnect automatically on disconnect",
    Type     = "Checkbox",
    Value    = Options.AutoRejoin or false,
    Callback = function(v)
        Options.AutoRejoin = v
        SaveConfig()
        if not v then return end
        task.spawn(function()
            local CoreGui2        = game:GetService("CoreGui")
            local TeleportService = game:GetService("TeleportService")
            local promptOverlay   = CoreGui2:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
            if not getgenv().RejoinConnection then
                getgenv().RejoinConnection = promptOverlay.ChildAdded:Connect(function(child)
                    if Options.AutoRejoin and child.Name == "ErrorPrompt" then
                        task.wait(5)
                        TeleportService:Teleport(game.PlaceId, player)
                    end
                end)
            end
        end)
    end
})

-- ============================================================
--  ANTI-AFK BACKGROUND
-- ============================================================
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    local VIM         = game:GetService("VirtualInputManager")
    while isRunning() do
        task.wait(120)
        if Options.AntiAFK then
            pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
            pcall(function()
                VIM:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
        end
    end
end)

-- ============================================================
--  DRAGGABLE TOGGLE BUTTON
-- ============================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AASToggleGui"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local targetGui = (gethui and gethui())
    or (pcall(function() return CoreGui.Name end) and CoreGui)
    or player.PlayerGui
ScreenGui.Parent = targetGui

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name                   = "ToggleButton"
ToggleBtn.Parent                 = ScreenGui
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Position               = UDim2.new(0.5, 0, 0, 40)
ToggleBtn.Size                   = UDim2.new(0, 50, 0, 50)
ToggleBtn.Image                  = "rbxassetid://110552700896064"
ToggleBtn.AnchorPoint            = Vector2.new(0.5, 0.5)

local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(1, 0) UICorner2.Parent = ToggleBtn

local UIStroke2 = Instance.new("UIStroke")
UIStroke2.Parent = ToggleBtn UIStroke2.Thickness = 2
UIStroke2.Color  = Color3.fromRGB(124, 58, 237)
UIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local dragging, dragStart, startPos

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = ToggleBtn.Position
        TweenService:Create(ToggleBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size=UDim2.new(0,42,0,42)}):Play()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            dragging = false
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size=UDim2.new(0,50,0,50)}):Play()
            if dragStart and (input.Position - dragStart).Magnitude < 10 then
                local vim    = game:GetService("VirtualInputManager")
                local keyStr = Options.ToggleUIKey or "LeftControl"
                local key    = typeof(keyStr) == "EnumItem" and keyStr or Enum.KeyCode[keyStr]
                if not key then key = Enum.KeyCode.LeftControl end
                vim:SendKeyEvent(true,  key, false, game) task.wait(0.05)
                vim:SendKeyEvent(false, key, false, game)
            end
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement
    or  input.UserInputType == Enum.UserInputType.Touch) and dragging then
        local delta = input.Position - dragStart
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)

FarmTab:Select()
