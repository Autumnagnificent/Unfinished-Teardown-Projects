--[[
#include ../Automatic.lua
]]

function init()
    Body = FindBody()
    Shapes = FindShapes()
    Offset = Vec(-0.1, -0.1, -0.1)
    Range = 0.05

    BumpForce = 1.25
    BumpForceAngle = 15

    BumpTime = 0.75
    _bt = BumpTime
end

function tick(dt)
    for i, s in pairs(Shapes) do
        local t = Transform(VecAdd(Offset, AutoRndVec(Range / 2)))
        SetShapeLocalTransform(s, t)

        QueryRejectShape(s)
    end

    -- SetBodyTransform(Body, Transform(GetBodyTransform(Body).pos, QuatEuler(unpack(AutoRndVec(360)))))

    SetBodyActive(Body, true)

    _bt = _bt - dt
    if _bt <= 0 then
        local v = VecAdd(Vec(0, BumpForce, 0), AutoRndVec(BumpForce))
        local va = VecAdd(AutoRndVec(BumpForceAngle))
        SetBodyVelocity(Body, v)
        SetBodyAngularVelocity(Body, va)
        
        _bt = BumpTime
    end
end