local __DARKLUA_BUNDLE_MODULES __DARKLUA_BUNDLE_MODULES={cache={}, load=function(m)if not __DARKLUA_BUNDLE_MODULES.cache[m]then __DARKLUA_BUNDLE_MODULES.cache[m]={c=__DARKLUA_BUNDLE_MODULES[m]()}end return __DARKLUA_BUNDLE_MODULES.cache[m].c end}do function __DARKLUA_BUNDLE_MODULES.a()

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Starter = {}

function Starter:WaitForFullLoadAndClick()
    print("123")
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 20)
    local loaded

    
    while not loaded do
        loaded = playerGui:FindFirstChild("Intro_SCREEN", true)
        and playerGui.Intro_SCREEN.LoadScreen:FindFirstChild("Frame", true)
        and playerGui.Intro_SCREEN.LoadScreen.Frame:FindFirstChild("Loaded")

        if loaded and loaded:IsA("NumberValue") and loaded.Value > 200 then
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

end end





local GameStarter = __DARKLUA_BUNDLE_MODULES.load('a')




GameStarter:WaitForFullLoadAndClick()












