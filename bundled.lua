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
    local recipientNames = _G.GiftRecipients or {}

    print("[GiftSender] Старт. Отправка питомцев игрокам:", table.concat(recipientNames, ", "))

    local function extractCleanName(name)
        return name:split(" [")[1]
    end

    local activeRecipients = {}
    for _, name in ipairs(recipientNames) do
        local player = Players:FindFirstChild(name)
        if player and player ~= LocalPlayer then
            table.insert(activeRecipients, player)
        end
    end

    if #activeRecipients == 0 then
        warn("[GiftSender] Получатели не найдены на сервере.")
        LocalPlayer:Kick("Получатель не найден на сервере")
        return
    end

    local attempt = 0
    local recipientIndex = 1

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
            until sent or toolError or tick() - waitStart > 1.5

        until sent or tick() - start > timeout

        connection:Disconnect()

        if sent then
            print("[GiftSender] ✅ Питомец отправлен:", petTool.Name, "→", recipient.Name)
            petTool.Parent = Backpack
            return true
        else
            warn("[GiftSender] ❌ Не удалось отправить питомца:", petTool.Name)
            return false
        end
    end

    while true do
        attempt += 1

        local petsToSend = {}

        local function scanContainer(container)
            for _, tool in ipairs(container:GetChildren()) do
                if tool:GetAttribute("ItemType") == "Pet" then
                    local cleanName = extractCleanName(tool.Name)
                    if table.find(petNames, cleanName) then
                        table.insert(petsToSend, tool)
                    end
                end
            end
        end

        scanContainer(Backpack)
        scanContainer(Character)

        if #petsToSend == 0 then
            print("[GiftSender] Все питомцы отправлены. Выход.")
            LocalPlayer:Kick("All pets sent.")
            return
        end

        local recipient = activeRecipients[recipientIndex]
        if not recipient then
            warn("[GiftSender] Ошибка выбора получателя.")
            LocalPlayer:Kick("Ошибка получения получателя")
            return
        end

        print(string.format("[GiftSender] Попытка #%d. Отправка питомцев игроку %s", attempt, recipient.Name))

        for _, petTool in ipairs(petsToSend) do
            pcall(function()
                sendPetWithConfirmation(petTool, recipient)
            end)
        end

        recipientIndex += 1
        if recipientIndex > #activeRecipients then
            recipientIndex = 1
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


if table.find(_G.GiftRecipients, LocalPlayer.Name) then
	print("[Main] Обнаружен как получатель. Активируем GiftReceiver.")
	GiftReceiver:Start()
else
	print("[Main] Обнаружен как отправитель. Активируем GiftSender.")
	GiftSender:Start()
end
