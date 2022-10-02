--[[
#include Automatic.lua
#include Assist.lua
]]

------------------------------------------------------------------------------------------------------------------------------------------------------

FOV = {
	Normal = 75,
	Zoom = 25,
	Paranoid = 135,
	Bay = 50
}

LvlBank = {
	'Intro',
}

SndBank = {
	Drone = LoadLoop('MOD/snd/Drone.ogg', 5),
	Bay = LoadLoop('MOD/snd/Bay.ogg'),
	Glitches = {
		LoadSound('MOD/snd/Glitches/Glitch01', 10),
		LoadSound('MOD/snd/Glitches/Glitch02', 10),
		LoadSound('MOD/snd/Glitches/Glitch03', 10),
		LoadSound('MOD/snd/Glitches/Glitch04', 10),
		LoadSound('MOD/snd/Glitches/Glitch05', 10),
		LoadSound('MOD/snd/Glitches/Glitch06', 10),
		LoadSound('MOD/snd/Glitches/Glitch07', 10),
		LoadSound('MOD/snd/Glitches/Glitch08', 10),
	}
}

SprBank = {
	Select = LoadSprite('ui/hud/crosshair-ring.png'),
	Hand = LoadSprite('ui/hud/crosshair-hand.png'),
}

-- MEMORY

CurrentFov = FOV.Normal

Eyes = 0
EyesShut = true
BayView = 0
BayViewMaxTime = 5

AllLights = {}
SightLights = {}

BayViewLocation = FindLocation('BayCamera', true)

------------------------------------------------------------------------------------------------------------------------------------------------------

function init()
	QueFunction("DisableTools()", 0.0125)
	
	if false then
		InitializeLevel(1)
	else
		QueFunction("SetPlayerTransform(GetLocationTransform(FindLocation('Player', true)), true)", 0.0125)

		AllLights = FindLights(nil, true)
		for _, v in pairs(AllLights) do
			if HasTag(v, 'sight') then
				SightLights[#SightLights + 1] = {
					light = v,
					intensity = 0,
					seen = 0
				}
			end
		end
	end

	RemoveFlashLight()

	RegisterTool('reality house', 'REALITY HOUSE')
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function tick(dt)
	ProccesFunctionQue()
	
	DisableTools()
	-- SetBool('hud.disable', true)

	CurrentFov = AutoLerpUnclamped(CurrentFov, InputDown('shift') and FOV.Zoom or FOV.Normal, 8 * dt)
	SetFloat('level.wetfloors.fov', CurrentFov)
	SetCameraFov(CurrentFov)

	-- Handle Eyes
	do
		-- if InputPressed('lmb') then EyesShut = not EyesShut end
		EyesShut = InputDown('lmb')

		local shutting = EyesShut and BayView <= 0 and GetPlayerGrabBody() == 0
		Eyes = Eyes + ((shutting and -1 or 1) * dt * 5)
		if shutting then
			Eyes = math.min(Eyes, 1)
		else
			Eyes = math.max(Eyes, 0)
		end

		SetFloat('level.wetfloors.eyes', Eyes)
		SetBool('level.wetfloors.eyesinput', EyesShut)
	end

	-- Handle Lights
	do
		if BayView <= 0 then
			for _, sl in pairs(SightLights) do
				local trans = GetLightTransform(sl.light)
				
				if sl.seen < 1 then
					local visible = AutoPointInView(trans.pos, nil, CurrentFov, true, 0.1) and AutoVecDist(trans.pos, GetCameraTransform().pos) < 20
					sl.seen = AutoClamp(sl.seen + (visible and 1 or 0) * 4 * dt, 0, 1)
				end
				if sl.seen == 1 then
					sl.intensity = math.min(15, sl.intensity + 10 * dt)
				end
				SetLightIntensity(sl.light, sl.intensity)
			end
			
			local soundloc = GetLightTransform(AllLights[ClosestLight()])
			PlayLoop(SndBank.Drone, soundloc.pos, 1)
		end
	end

	-- Bay
	do
		local lastbayview = BayView
		
		if BayView > 0 then
			BayView = math.max(BayView + dt, 0)
			
			if AnyKeyPressed() then
				BayView = BayView - 0.25
				PlayRandomSound(SndBank.Glitches)
			end
		end

		if (BayView == 0 or lastbayview == 0) and (BayView ~= lastbayview) then PlayRandomSound(SndBank.Glitches) end
		
		if BayView > 0 then
			local t = GetLocationTransform(BayViewLocation)
			local c = GetCameraTransform()

			-- SetCameraFov(FOV.Bay)
			t.pos[2] = math.sin(GetTime()) / 4 + 3
			SetCameraTransform(t)

			PlayLoop(SndBank.Bay)
		end

		if BayView > 5 then
			BayView = 0
		end
	end
end

function draw()
	local camera = GetCameraTransform()
	local camfwd = AutoTransformFwd(camera)

	-- Hand
	-- do
	-- 	QueryRequire('physical dynamic')
	-- 	local hit, dist = QueryRaycast(camera.pos, camfwd, 3)
	-- 	local hitpos = VecAdd(camera.pos, VecScale(camfwd, dist))

	-- 	local grabbing = GetPlayerGrabBody() ~= 0
	-- 	if hit or grabbing then
	-- 		DrawSprite(grabbing and SprBank.Hand or SprBank.Select, Transform(hitpos, QuatLookAt(hitpos, camera.pos)), grabbing and 0.1 or 0.045, grabbing and 0.1 or 0.045, 1, 1, 1, 1, false, false)
	-- 	end
	-- end
	
	
	-- Draw Eyes
	do
		UiPush()
			UiPush()
				local a = AutoLogisticScaled(GetFloat('level.wetfloors.eyes'), 1, 5, 1, 0, 1)
				UiColor(0, 0, 0, 1)

				UiPush()
					UiTranslate(0, a * -UiHeight() * 2)
					UiRect(UiWidth(), UiMiddle())
				UiPop()

				UiPush()
					UiTranslate(0, a * UiHeight() + UiMiddle())
					UiRect(UiWidth(), UiMiddle())
				UiPop()
			UiPop()
			
			local increment = 32
			local base = (360 / (increment - 1))
			for x=1, increment - 1 do
				for y=1, increment - 1 do
					UiPush()
						local pos = VecAdd(camera.pos, QuatRotateVec(QuatEuler(y * base, x * base), Vec(0, 0, -1)))

						local px, py, pdist = UiWorldToPixel(pos)
						if pdist > 0 then
							UiTranslate(px, py)
							
							UiAlign('center middle')
							UiScale(0.08)
							UiRotate(math.sin((GetTime() + x*1.5 + y*1.5) * math.pi) * 8)
							local a = (GetTime() + x * 1.25 + y * 1.25) * math.pi
							UiTranslate(math.cos(a) * 64, math.sin(a) * 64)
							UiRotate(InputValue('camerax') * -125)
							
							local a = (math.sin((GetTime() + x * 4.1 + (x+y) * 4.1) * math.pi) + 1) / 2 * 0.1 + 0.05
							UiColor(1, 1, 1, AutoLogisticScaled(GetFloat('level.wetfloors.eyes'), 1, 10, 0.5, 1, 0) * a)
							UiImage('MOD/spr/eyeclosed.png')
						end
					UiPop()
				end
			end
		UiPop()
	end
end
