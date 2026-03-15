local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-------------------------------------------------------------------
-- [ ระบบ Anti-AFK ]
-------------------------------------------------------------------
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- ทำงานอัตโนมัติเมื่อผู้เล่นนิ่งเกินเวลาที่กำหนด
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
    print("Anti-AFK: Player Successfully UnIdled.")
end)

local Window = Fluent:CreateWindow({
    Title = "Auto Buy - Smart Market Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Auto", Icon = "home" }),
    Purchase = Window:AddTab({ Title = "Packs", Icon = "shopping-cart" }),
    Market = Window:AddTab({ Title = "Market", Icon = "shopping-bag" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-------------------------------------------------------------------
-- [ ตั้งค่า Remote และตำแหน่ง ]
-------------------------------------------------------------------
local packRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Card")
local marketRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Stock")
local packsFolder = workspace:WaitForChild("Client"):WaitForChild("Packs")

local marketList = { "Soul", "Soul-Gold", "Soul-Emerald", "Soul-Void", "Soul-Diamond", "Soul-Rainbow", "Pirate",
    "Pirate-Gold", "Pirate-Emerald", "Pirate-Void", "Pirate-Diamond", "Pirate-Rainbow", "Ninja", "Ninja-Gold",
    "Ninja-Emerald", "Ninja-Void", "Ninja-Diamond", "Ninja-Rainbow", "Slayer", "Slayer-Gold", "Slayer-Emerald",
    "Slayer-Void", "Slayer-Diamond", "Slayer-Rainbow", "Sorcerer", "Sorcerer-Gold", "Sorcerer-Emerald", "Sorcerer-Void",
    "Sorcerer-Diamond", "Sorcerer-Rainbow", "Dragon", "Dragon-Gold", "Dragon-Emerald", "Dragon-Void", "Dragon-Diamond",
    "Dragon-Rainbow", "Fire", "Fire-Gold", "Fire-Emerald", "Fire-Void", "Fire-Diamond", "Fire-Rainbow" }

-------------------------------------------------------------------
-- [ Tab: Auto (ระบบเก็บเงินอัตโนมัติ) ]
-------------------------------------------------------------------
Tabs.Main:AddParagraph({
    Title = "Farm Management",
    Content = "Anti-AFK Status: Active (Always On)"
})

Tabs.Main:AddToggle("AutoCollectSmartLoop", { Title = "Auto Collect (Zig-Zag)", Default = false }):OnChanged(function(Value)
    _G.AutoCollect = Value
    if Value then
        task.spawn(function()
            local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Card")
            local plotNum = "2" -- แก้เป็นเลข Plot ของคุณ
            
            local currentPage = 1
            local maxPages = 14 -- ปรับเป็น 14 ตามที่คุณบอกก่อนหน้านี้
            local direction = "RightArrow"
            
            while _G.AutoCollect do
                local myPlot = workspace.Plots:FindFirstChild(plotNum)
                if myPlot and myPlot:FindFirstChild("Map") and myPlot.Map:FindFirstChild("Display") then
                    local display = myPlot.Map.Display
                    
                    -- 1. กวาดเก็บเงินหน้าปัจจุบัน
                    for _, side in ipairs(display:GetChildren()) do
                        for _, cardSlot in ipairs(side:GetChildren()) do
                            if not _G.AutoCollect then break end
                            remote:FireServer("Collect", cardSlot)
                        end
                    end
                    
                    -- 2. ระบบสลับทิศทาง (Zig-Zag)
                    if direction == "RightArrow" then
                        currentPage = currentPage + 1
                        if currentPage >= maxPages then
                            direction = "LeftArrow"
                        end
                    else
                        currentPage = currentPage - 1
                        if currentPage <= 1 then
                            direction = "RightArrow"
                        end
                    end
                    
                    -- 3. สั่งเปลี่ยนหน้า
                    remote:FireServer("Page", direction)
                    task.wait(0.5) -- ปรับเวลารอโหลดให้เร็วขึ้นพอประมาณ
                else
                    task.wait(1)
                end
            end
        end)
    end
end)

-------------------------------------------------------------------
-- [ Tab: Packs (ซองบนราง) ]
-------------------------------------------------------------------
local selectedPacks = {}
Tabs.Purchase:AddDropdown("PackSelector", {
    Title = "Select Packs",
    Values = { "Soul", "Pirate", "Ninja", "Slayer", "Sorcerer", "Dragon", "Fire" },
    Multi = true,
    Default = {},
}):OnChanged(function(Value) selectedPacks = Value end)

Tabs.Purchase:AddToggle("AutoBuyPacks", { Title = "Auto Buy Selected Packs", Default = false }):OnChanged(function(Value)
    _G.AutoBuy = Value
    if Value then
        task.spawn(function()
            while _G.AutoBuy do
                for _, pack in ipairs(packsFolder:GetChildren()) do
                    if not _G.AutoBuy then break end
                    if pack.PrimaryPart and selectedPacks[pack.PrimaryPart.Name] then
                        packRemote:FireServer("BuyPack", pack.Name)
                        task.wait(0.1)
                    end
                end
                task.wait(0.3)
            end
        end)
    end
end)

-------------------------------------------------------------------
-- [ Tab: Market (วนซื้อทุก 10 วินาที) ]
-------------------------------------------------------------------
Tabs.Market:AddToggle("AutoMarketAll", { Title = "Auto Market (Every 10s)", Default = false }):OnChanged(function(Value)
    _G.AutoMarket = Value
    if Value then
        task.spawn(function()
            while _G.AutoMarket do
                for _, cardName in ipairs(marketList) do
                    if not _G.AutoMarket then break end
                    marketRemote:FireServer("Buy", cardName)
                end
                task.wait(30)
            end
        end)
    end
end)

-------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/game-1")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
