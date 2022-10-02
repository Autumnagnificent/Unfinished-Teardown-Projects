--[[
#include Automatic.lua
#include Helper.lua
]]

CameraLocation = FindLocation('CameraLocation', true)
CarSpawns = FindLocations('CarSpawn', true)
CarControl = FindTrigger('CarControl', true)

function tick(dt)
	SetPlayerTransform(Transform(AutoVecOne(500)))
	SetPlayerVelocity(Vec())
	SetCameraTransform(GetLocationTransform(CameraLocation), 90)

	if not Current_Vehicle then
		CreateVehicle()
	end

	CurrentVehicleUpdate()
end

function draw()
	if Current_Vehicle then
		local body = GetVehicleBody(Current_Vehicle.id)
		DrawBodyOutline(body)
	end
end