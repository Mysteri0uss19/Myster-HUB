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

-- ตัวแปรสำหรับเก็บค่า Plot Number
local plotNumber = "2"

-------------------------------------------------------------------
-- [ Tab: Auto (ระบบเก็บเงินอัตโนมัติ) ]
-------------------------------------------------------------------
Tabs.Main:AddParagraph({
    Title = "Farm Management",
    Content = "ระบบช่วยฟาร์มอัตโนมัติ"
})

-- เพิ่ม Input สำหรับเลือก Plot Number
Tabs.Main:AddInput("PlotNumberInput", {
    Title = "Plot Number",
    Default = "2",
    Placeholder = "ใส่เลขหมายเลข Plot (1-100)",
    Numeric = true
}):OnChanged(function(Value)
    if Value and Value ~= "" then
        plotNumber = tostring(Value)
    end
end)

Tabs.Main:AddToggle("AutoCollectSmartLoop", { Title = "Auto Collect (Zig-Zag)", Default = false }):OnChanged(function(Value)
    _G.AutoCollect = Value
    if Value then
        task.spawn(function()
            local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Card")
            
            local currentPage = 1
            local maxPages = 14
            local direction = "RightArrow"
            local collectCount = 0
            
            while _G.AutoCollect do
                local myPlot = workspace.Plots:FindFirstChild(plotNumber)
                if myPlot and myPlot:FindFirstChild("Map") and myPlot.Map:FindFirstChild("Display") then
                    local display = myPlot.Map.Display
                    
                    -- 1. กวาดเก็บเงินหน้าปัจจุบัน
                    for _, side in ipairs(display:GetChildren()) do
                        for _, cardSlot in ipairs(side:GetChildren()) do
                            if not _G.AutoCollect then break end
                            pcall(function()
                                remote:FireServer("Collect", cardSlot)
                                collectCount = collectCount + 1
                            end)
                        end
                    end
                    
                    -- 2. ระบบสลับทิศทาง
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
                    
                    -- 3. สั่งเปลี่ยนหน้าตามทิศทางปัจจุบัน
                    pcall(function()
                        remote:FireServer("Page", direction)
                    end)
                    
                    task.wait(0.4) 
                else
                    task.wait(1)
                end
            end
            print("✓ Auto Collect หยุดแล้ว - เก็บทั้งหมด " .. collectCount .. " ใบ")
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
        if not next(selectedPacks) then
            Window:ShowNotification({
                Title = "⚠️ แจ้งเตือน",
                Content = "โปรดเลือก Pack ก่อน",
                Duration = 3
            })
            return
        end
        
        task.spawn(function()
            local buyCount = 0
            while _G.AutoBuy do
                local allPacks = packsFolder:GetChildren()
                for _, pack in ipairs(allPacks) do
                    if not _G.AutoBuy then break end
                    
                    -- แก้: เปรียบเทียบ pack.Name แทน pack.PrimaryPart.Name
                    if selectedPacks[pack.Name] then
                        pcall(function()
                            packRemote:FireServer("BuyPack", pack.Name)
                            buyCount = buyCount + 1
                            task.wait(0.2) -- เพิ่ม delay เพื่อหลีกเลี่ยงการโหลดเกินไป
                        end)
                    end
                end
                task.wait(0.5)
            end
            print("✓ Auto Buy Pack หยุดแล้ว - ซื้อทั้งหมด " .. buyCount .. " ครั้ง")
        end)
    end
end)

-------------------------------------------------------------------
-- [ Tab: Market (วนซื้อทุก 10 วินาที) ]
-------------------------------------------------------------------
Tabs.Market:AddSlider("MarketDelaySlider", {
    Title = "Delay Between Buys (ms)",
    Min = 50,
    Max = 1000,
    Default = 200,
    Rounding = 50
}):OnChanged(function(Value)
    _G.MarketDelay = Value
end)

_G.MarketDelay = 200

Tabs.Market:AddToggle("AutoMarketAll", { Title = "Auto Market (Every 10s)", Default = false }):OnChanged(function(Value)
    _G.AutoMarket = Value
    if Value then
        task.spawn(function()
            local buyCount = 0
            local function buyEverything()
                for _, cardName in ipairs(marketList) do
                    if not _G.AutoMarket then break end
                    pcall(function()
                        marketRemote:FireServer("Buy", cardName)
                        buyCount = buyCount + 1
                        -- เพิ่ม delay ป้องกัน rate-limit
                        task.wait(_G.MarketDelay / 1000)
                    end)
                end
            end
            
            while _G.AutoMarket do
                buyEverything()
                task.wait(10)
            end
            print("✓ Auto Market หยุดแล้ว - ซื้อทั้งหมด " .. buyCount .. " ใบ")
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