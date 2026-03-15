local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

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
    Content = "ระบบช่วยฟาร์มอัตโนมัติ"
})

Tabs.Main:AddToggle("AutoCollectMoney", { Title = "Auto Collect Money (All Pages)", Default = false }):OnChanged(function(Value)
    _G.AutoCollect = Value
    if Value then
        task.spawn(function()
            -- ค้นหา Plot ของคุณ (ใช้เลข 2 ตามข้อมูลเดิม)
            local myPlot = workspace:WaitForChild("Plots"):WaitForChild("2")
            local display = myPlot:WaitForChild("Map"):WaitForChild("Display")
            local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Card")

            while _G.AutoCollect do
                -- กวาดทุกด้าน (Left, Right, Middle)
                for _, side in ipairs(display:GetChildren()) do
                    if not _G.AutoCollect then break end
                    
                    -- กวาดทุก Slot ที่อยู่ในด้านนั้นๆ (มันจะพยายามเก็บแม้เราจะไม่ได้เปิดหน้านั้นอยู่)
                    local slots = side:GetChildren()
                    for i = 1, #slots do
                        local cardSlot = slots[i]
                        
                        -- ส่ง Remote Collect ไปที่ Object โดยตรง
                        remote:FireServer("Collect", cardSlot)
                        
                        -- ใส่ wait เล็กน้อยเพื่อไม่ให้ Remote ทำงานหนักเกินไปจนโดนเตะ
                        if i % 10 == 0 then task.wait(0.05) end 
                    end
                end
                
                -- พัก 1 วินาทีก่อนเริ่มกวาดใหม่รอบถัดไป
                task.wait(1)
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
                local allPacks = packsFolder:GetChildren()
                for _, pack in ipairs(allPacks) do
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
            local function buyEverything()
                for _, cardName in ipairs(marketList) do
                    if not _G.AutoMarket then break end
                    marketRemote:FireServer("Buy", cardName)
                end
            end
            
            while _G.AutoMarket do
                buyEverything()
                task.wait(10)
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
