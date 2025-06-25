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
	Startup.WaitForGameLoad()

	if not Start.IsInTargetPlace() then
		warn("[Startup] Не в нужном плейсе. Телепортируемся...")
		Startup.TeleportToTargetPlace()
		return false 
	end

	return true 
end

return Start
end end
Start = __DARKLUA_BUNDLE_MODULES.load('a')

Start.Run()
