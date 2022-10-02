--[[
#include ../Automatic.lua
#include ../Assist.lua
]]

------------------------------------------------------------------------------------------------------------------------------------------------------

local Params = {
	Invert = GetBoolParam('Invert', false),

	Sight = GetBoolParam('Sight', true),
	Eyes = GetBoolParam('Eyes', true),
	Proximity = GetFloatParam('Proximity', math.huge),
	MinGlitchs = GetIntParam('MinGlitches', 0),

	Spawn = GetStringParam('Spawn', ''),
	SpawnVel = GetStringParam('SpawnVel', ''),

	Resolution = AutoXMLToVec(GetStringParam('Resolution', '5 5 5')),
	RayCastError = GetFloatParam('RayCastError', 0.25),

	Function = GetStringParam('Function', ''),
	FunctionDelay = GetFloatParam('FunctionDelay', 0),

	Sound = GetBoolParam('Sound', true),
	Debug = GetBoolParam('Debug', false)
}

------------------------------------------------------------------------------------------------------------------------------------------------------

local Enabled = true
local TimeAlive = 0

local Object = {}

Object.body = FindBody()
Object.sightTrigger = FindTrigger('Sight')
Object.cameraTrigger = FindTrigger('Camera')
Object.spawnLocation = FindLocation('Spawn')
Object.bounds = {}

local Viewpoints = {}

if Object.sightTrigger ~= 0 then
	local ot = GetTriggerTransform(Object.sightTrigger)
	SetTriggerTransform(Object.sightTrigger, Transform(ot.pos, QuatEuler(0, 0, 0)))

	Object.bounds.aa, Object.bounds.bb = GetTriggerBounds(Object.sightTrigger)
	SetTriggerTransform(Object.sightTrigger, ot)

	Viewpoints = BoundsToPointArray(Object.bounds.aa, Object.bounds.bb, GetTriggerTransform(Object.sightTrigger), Params.Resolution)
else
	local ot = GetBodyTransform(Object.body)
	SetBodyTransform(Object.body, Transform(ot.pos, QuatEuler(0, 0, 0)))

	Object.bounds.aa, Object.bounds.bb = GetBodyBounds(Object.body)
	SetBodyTransform(Object.body, ot)

	Viewpoints = BoundsToPointArray(Object.bounds.aa, Object.bounds.bb, GetBodyTransform(Object.body), Params.Resolution)
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function tick(dt)
	if not Enabled then return end
	if Params.MinGlitchs > GetInt('level.wetfloors.glitches', 0) then return end
	if TimeAlive < 0.1 then TimeAlive = TimeAlive + dt return end

	local camera = GetCameraTransform()

	local trans = Object.sightTrigger == 0 and GetBodyTransform(Object.body) or GetTriggerTransform(Object.sightTrigger)
	local list = ConvertLocalPointArray(Viewpoints, trans)

	evaluate = true
	if Object.body ~= 0 then
		local _, closestpoint = GetBodyClosestPoint(Object.body, camera.pos)
		evaluate = AutoVecDist(camera.pos, closestpoint) < Params.Proximity
		table.insert(list, 1, closestpoint)
	end
	if Object.cameraTrigger ~= 0 then
		if not IsPointInTrigger(Object.cameraTrigger, camera.pos) then
			evaluate = false
		end
	end

	if evaluate then
		local TriggerEffect = CheckForSight(list, Params)
		local activate = (TriggerEffect ~= Params.Invert)
	
		if activate and not Params.Debug then
			if Params.Sound then PlayRandomSound(SndBank.Glitches) end
				
			if Params.Spawn ~= '' then
				local t = Object.sightTrigger == 0 and GetBodyTransform(Object.body) or GetLocationTransform(Object.spawnLocation)
				if Object.spawnLocation == 0 then t.rot = QuatEuler(0, math.random() * 360, 0) end

				local entities = Spawn(Params.Spawn, t, true)
				AddLevelEntities(entities)

				local mainbody = 0
				for _, e in pairs(entities) do
					if GetEntityType(e) == 'body' then
						mainbody = e
						break
					end
				end
				
				if Params.SpawnVel == '' then
					if Object.body ~= 0 then
						SetBodyVelocity(mainbody, GetBodyVelocity(Object.body))
						SetBodyAngularVelocity(mainbody, VecScale(GetBodyAngularVelocity(Object.body), 0.25))
					end
				else
					SetBodyVelocity(mainbody, TransformToParentVec(t, AutoXMLToVec(Params.SpawnVel)))
				end
			end

			if Object.body ~= 0 then Delete(Object.body) end
			if Object.sightTrigger ~= 0 then Delete(Object.sightTrigger) end
			if Object.cameraTrigger ~= 0 then Delete(Object.cameraTrigger) end
			if Object.spawnLocation ~= 0 then Delete(Object.spawnLocation) end

			SetInt('level.wetfloors.glitches', GetInt('level.wetfloors.glitches', 0) + 1)
			if Params.Function ~= '' then
				QueFunction(Params.Function, Params.FunctionDelay)
			end

			Enabled = false
		end
	end
end