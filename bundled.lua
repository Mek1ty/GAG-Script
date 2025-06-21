local __DARKLUA_BUNDLE_MODULES __DARKLUA_BUNDLE_MODULES={cache={}, load=function(m)if not __DARKLUA_BUNDLE_MODULES.cache[m]then __DARKLUA_BUNDLE_MODULES.cache[m]={c=__DARKLUA_BUNDLE_MODULES[m]()}end return __DARKLUA_BUNDLE_MODULES.cache[m].c end}do function __DARKLUA_BUNDLE_MODULES.a()local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local AutoStart = {}

function AutoStart.WaitAndStart()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 30)
    if not playerGui then
        warn("[AutoStart] PlayerGui не найден")
        return
    end

    local loadedValue
    local maxWaitTime = 30
    local startTime = tick()

    
    while tick() - startTime < maxWaitTime do
        local loadedCandidate = playerGui:FindFirstChild("Intro_SCREEN", true)
            and playerGui.Intro_SCREEN:FindFirstChild("Frame", true)
            and playerGui.Intro_SCREEN.Frame:FindFirstChild("Loaded")

        if loadedCandidate and loadedCandidate:IsA("Value") then
            loadedValue = loadedCandidate
            break
        end
        task.wait(0.3)
    end

    if not loadedValue then
        warn("[AutoStart] Loaded объект не найден")
        return
    end

    print("[AutoStart] Найден Loaded, отслеживаем значение...")

    
    while loadedValue.Value < 50 do
        task.wait(0.1)
    end

    print("[AutoStart] Loaded > 50, эмуляция нажатия клавиши...")

    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
end

return AutoStart
end end
local Starter = __DARKLUA_BUNDLE_MODULES.load('a')

Starter.WaitAndStart()
