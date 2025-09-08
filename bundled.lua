local __DARKLUA_BUNDLE_MODULES __DARKLUA_BUNDLE_MODULES={cache={}, load=function(m)if not __DARKLUA_BUNDLE_MODULES.cache[m]then __DARKLUA_BUNDLE_MODULES.cache[m]={c=__DARKLUA_BUNDLE_MODULES[m]()}end return __DARKLUA_BUNDLE_MODULES.cache[m].c end}do function __DARKLUA_BUNDLE_MODULES.a()

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Starter = {}

function Starter:WaitForFullLoadAndClick()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
    local loaded

    
    while not loaded do
        loaded = playerGui:FindFirstChild("Intro_SCREEN", true)
        and playerGui.Intro_SCREEN:FindFirstChild("Frame", true)
        and playerGui.Intro_SCREEN.Frame:FindFirstChild("Loaded")

        if loaded and loaded.Value > 200 then
            break
        end

        task.wait(0.2)
    end

    task.wait(1)
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)

    print("[Starter] Loading completed")
end

return Starter

end function __DARKLUA_BUNDLE_MODULES.b()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local PetGiftingModule = require(ReplicatedStorage.Modules.PetServices.PetGiftingService)
local NotificationEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Notification")

local GiftSender = {}

function GiftSender:Start()
    local petNames = _G.PetNamesToSend or {}
    local sendForWeigth = _G.SendForWeigth or {} 
    if type(_G.SendForWeight) == "table" then
        for n, w in pairs(_G.SendForWeight) do
            if sendForWeigth[n] == nil then
                sendForWeigth[n] = w
            end
        end
    end

    
    local receiverPetMap = _G.ReceiverPetMap or {}

    
    local recipientNames = _G.GiftRecipients or {}

    
    local function extractCleanName(name)
        return name:split(" [")[1]
    end

    local function extractWeight(tool)
        local attr = tool:GetAttribute("Weight")
        if typeof(attr) == "number" then
            return attr
        end
        local numStr = string.match(tool.Name, "%[(%d+%.?%d*)%]")
        if numStr then
            local n = tonumber(numStr)
            if n then return n end
        end
        return 0
    end

    local function toolPassesFilters(tool)
        if tool:GetAttribute("ItemType") ~= "Pet" then
            return false
        end
        local cleanName = extractCleanName(tool.Name)

        
        for i = 1, #petNames do
            if petNames[i] == cleanName then
                return true, cleanName, nil, extractWeight(tool)
            end
        end

        
        local minWeight = sendForWeigth[cleanName]
        if typeof(minWeight) == "number" then
            local w = extractWeight(tool)
            if w >= minWeight then
                return true, cleanName, minWeight, w
            end
        end

        return false
    end

    
    local activeRecipients = {}
    do
        local wantFilterList = {}
        for i = 1, #recipientNames do
            wantFilterList[recipientNames[i] ] = true
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local name = player.Name
                local mappedPet = receiverPetMap[name]
                local allowedByFilter = (next(wantFilterList) == nil) or (wantFilterList[name] == true)

                if mappedPet and allowedByFilter then
                    table.insert(activeRecipients, player)
                end
            end
        end
    end

    if #activeRecipients == 0 then
        warn("[GiftSender] Получатели не найдены на сервере (или отсутствуют в ReceiverPetMap).")
        LocalPlayer:Kick("No mapped recipients on server")
        return
    end

    print("[GiftSender] Start. Recipients:",
        table.concat((function(list)
            local t = {}
            for i = 1, #list do t[#t + 1] = list[i].Name end
            return t
        end)(activeRecipients), ", ")
    )

    
    local function collectPetBuckets()
        local buckets = {}

        local function put(tool)
            local ok, cleanName, minW, w = toolPassesFilters(tool)
            if not ok then return end

            
            local hasRecipient = false
            for i = 1, #activeRecipients do
                local r = activeRecipients[i]
                if receiverPetMap[r.Name] == cleanName then
                    hasRecipient = true
                    break
                end
            end
            if not hasRecipient then
                return
            end

            local b = buckets[cleanName]
            if b == nil then
                b = {}
                buckets[cleanName] = b
            end
            b[#b + 1] = tool
        end

        for _, tool in ipairs(Backpack:GetChildren()) do
            put(tool)
        end
        for _, tool in ipairs(Character:GetChildren()) do
            put(tool)
        end

        return buckets
    end

    local NotificationEvent = NotificationEvent 
    local function sendPetWithConfirmation(petTool, recipient)
        local sent = false
        local toolError = false

        local connection = NotificationEvent.OnClientEvent:Connect(function(msg)
            if msg == "Sent gift request!" then
                sent = true
            elseif msg == "You are not holding a tool!" then
                toolError = true
            end
        end)

        local timeout = 5
        local start = tick()
        repeat
            petTool.Parent = Character
            task.wait(0.1)

            if Character:FindFirstChild(petTool.Name) then
                PetGiftingModule:GivePet(recipient)
            end

            local waitStart = tick()
            repeat
                task.wait()
            until sent or toolError or (tick() - waitStart > 1.5)

        until sent or (tick() - start > timeout)

        connection:Disconnect()

        if sent then
            print("[GiftSender] ✅", petTool.Name, "→", recipient.Name)
            
            if petTool.Parent ~= nil then
                petTool.Parent = Backpack
            end
            return true
        else
            warn("[GiftSender] ❌ Не удалось отправить:", petTool.Name)
            return false
        end
    end

    
    local attempt = 0
    while true do
        attempt = attempt + 1
        print(string.format("[GiftSender] Attempt #%d — scanning inventory", attempt))

        local buckets = collectPetBuckets()

        
        local any = false
        for i = 1, #activeRecipients do
            local r = activeRecipients[i]
            local want = receiverPetMap[r.Name]
            if buckets[want] and #buckets[want] > 0 then
                any = true
                break
            end
        end

        if not any then
            print("[GiftSender] Все подходящие питомцы отправлены по маппингу. Выход.")
            LocalPlayer:Kick("All mapped pets sent.")
            return
        end

        
        for i = 1, #activeRecipients do
            local r = activeRecipients[i]
            local want = receiverPetMap[r.Name]
            local pack = buckets[want]

            if pack and #pack > 0 then
                print(string.format("[GiftSender] → %s (expects: %s) — %d pet(s) queued",
                    r.Name, want, #pack))

                
                local toSend = pack
                buckets[want] = {}

                for j = 1, #toSend do
                    local tool = toSend[j]
                    if tool and tool.Parent ~= nil then
                        pcall(function()
                            sendPetWithConfirmation(tool, r)
                        end)
                    end
                end
            end
        end

        task.wait(10)
    end
end


return GiftSender
end function __DARKLUA_BUNDLE_MODULES.c()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GiftReceiver = {}

function GiftReceiver:Start()
    print("[GiftReceiver] Waiting gifts...")

    local giftEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("GiftPet")
    local acceptEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("AcceptPetGift")
    local LocalPlayer = Players.LocalPlayer

    local Backpack = LocalPlayer:WaitForChild("Backpack")
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    
    local function getPetCount()
        local count = 0

        for _, tool in ipairs(Backpack:GetChildren()) do
            if tool:GetAttribute("ItemType") == "Pet" then
                count += 1
            end
        end

        for _, tool in ipairs(Character:GetChildren()) do
            if tool:GetAttribute("ItemType") == "Pet" then
                count += 1
            end
        end

        return count
    end

    
    task.spawn(function()
        while true do
            if getPetCount() >= 60 then
                warn("[GiftReceiver] Too many pets. Kicking...")
                LocalPlayer:Kick("Inventory full (60 pets)")
                break
            end
            task.wait(30)
        end
    end)

    
    local giftQueue = {}
    local isProcessing = false

    local function processQueue()
        if isProcessing then return end
        isProcessing = true

        while #giftQueue > 0 do
            local petId = table.remove(giftQueue, 1)

            if typeof(petId) == "string" then
                local args = { true, petId }
                pcall(function()
                    acceptEvent:FireServer(unpack(args))
                    print("[GiftReceiver] Gift received:", petId)
                end)
            else
                warn("[GiftReceiver] Invalid petId in queue.")
            end

            task.wait(1) 
        end

        isProcessing = false
    end

    
    giftEvent.OnClientEvent:Connect(function(petId, _, _)
        table.insert(giftQueue, petId)
        processQueue()
    end)
end

return GiftReceiver
end end





local GameStarter = __DARKLUA_BUNDLE_MODULES.load('a')
local GiftSender = __DARKLUA_BUNDLE_MODULES.load('b')
local GiftReceiver = __DARKLUA_BUNDLE_MODULES.load('c')


GameStarter:WaitForFullLoadAndClick()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- SAFE role detection: from explicit list OR from ReceiverPetMap
local function isReceiver()
    local recipients = _G.GiftRecipients
    if type(recipients) == "table" and table.find(recipients, LocalPlayer.Name) then
        return true
    end
    local map = _G.ReceiverPetMap
    if type(map) == "table" and map[LocalPlayer.Name] ~= nil then
        return true
    end
    return false
end

if isReceiver() then
    print("[Main] Обнаружен как получатель. Активируем GiftReceiver.")
    GiftReceiver:Start()
else
    print("[Main] Обнаружен как отправитель. Активируем GiftSender.")
    GiftSender:Start()
end


