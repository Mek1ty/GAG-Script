local __DARKLUA_BUNDLE_MODULES __DARKLUA_BUNDLE_MODULES={cache={}, load=function(m)if not __DARKLUA_BUNDLE_MODULES.cache[m]then __DARKLUA_BUNDLE_MODULES.cache[m]={c=__DARKLUA_BUNDLE_MODULES[m]()}end return __DARKLUA_BUNDLE_MODULES.cache[m].c end}do function __DARKLUA_BUNDLE_MODULES.a()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

local Start = {}

local TARGET_PLACE_ID = 99703032952567 

function Start.WaitForGameLoad()
	while not LocalPlayer or not LocalPlayer.Character or not LocalPlayer:FindFirstChild("PlayerGui") do
		task.wait()
	end
end

function Start.IsInTargetPlace(): boolean
	return game.PlaceId == TARGET_PLACE_ID
end

function Start.TeleportToTargetPlace()
	TeleportService:Teleport(TARGET_PLACE_ID, LocalPlayer)
end


function Start.Run(): boolean
	Start.WaitForGameLoad()

	if not Start.IsInTargetPlace() then
		warn("[Startup] Не в нужном плейсе. Телепортируемся...")
		Start.TeleportToTargetPlace()
		return false 
	end

	return true 
end

return Start
end function __DARKLUA_BUNDLE_MODULES.b()

local UIUtils = {}

local Save = require(game:GetService("ReplicatedStorage").Library.Client.Save).Get()
local WORLD_NAME = "Happy Castle"
local MAX_LEVEL = 6

function UIUtils.StartNext()
	local completedLevels = Save and Save.TowerCompleted and Save.TowerCompleted[WORLD_NAME]

	local maxCompleted = 0
	if typeof(completedLevels) == "table" then
		for level, completed in pairs(completedLevels) do
			if completed == 1 and typeof(level) == "number" and level > maxCompleted then
				maxCompleted = level
			end
		end
	end

	if maxCompleted < MAX_LEVEL then
		local nextLevel = (maxCompleted > 0 and maxCompleted + 1) or 1
		print("[UIUtils] Запуск уровня:", nextLevel)
		
	else
		print("[UIUtils] Все уровни завершены. Запуск Infinity.")
		
	end
end

return UIUtils
end end
Start = __DARKLUA_BUNDLE_MODULES.load('a')
UIUtils = __DARKLUA_BUNDLE_MODULES.load('b')

Start.Run()
UIUtils.StartNext()
