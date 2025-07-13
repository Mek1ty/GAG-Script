local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local GiftReceiver = {}

function GiftReceiver:Start()
    print("[GiftReceiver] Ожидание подарков...")

    local giftEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("GiftPet")
    local acceptEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("AcceptPetGift")

    -- Подсчёт питомцев
    local function countPets()
        local count = 0

        local function scan(container)
            for _, item in ipairs(container:GetChildren()) do
                if item:GetAttribute("ItemType") == "Pet" then
                    count += 1
                end
            end
        end

        scan(Backpack)
        scan(Character)

        return count
    end

    giftEvent.OnClientEvent:Connect(function(petId, _, _)
        if typeof(petId) == "string" then
            local petCount = countPets()
            if petCount >= 60 then
                warn("[GiftReceiver] ⚠ Превышен лимит питомцев: ", petCount)
                LocalPlayer:Kick("Inventory full (60 pets)")
                return
            end

            local args = { true, petId }
            pcall(function()
                acceptEvent:FireServer(unpack(args))
                print("[GiftReceiver] ✅ Принят подарок:", petId)
            end)
        else
            warn("[GiftReceiver] ❌ Неверный petId")
        end
    end)
end

return GiftReceiver
