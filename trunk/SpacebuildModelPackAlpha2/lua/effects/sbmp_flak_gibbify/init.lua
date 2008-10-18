-- This effect is from Redead, go play it, it's awesome!

local GibList = {
					"models/props_junk/watermelon01_chunk02a.mdl",
					"models/props_junk/watermelon01_chunk02c.mdl"
				}

GibList.Number = #GibList

function EFFECT:Init(data)
	self.LifeTime = CurTime() + math.Rand(10, 15)
	
	local pos = data:GetOrigin()
	
	self:SetModel(GibList[math.random(1, GibList.Number)])
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS) 
	self:SetPos(pos + (VectorRand() * math.random(-5, 5)))
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	self:SetMaterial("models/flesh")
	
	local phys = self:GetPhysicsObject()
	
	if phys and phys:IsValid() then
		phys:Wake()
		--print(self:GetModel())
		phys:SetAngle(Angle(math.Rand(0, 359), math.Rand(0, 359), math.Rand(0, 359)))
		phys:SetVelocity(VectorRand() * 128)
		phys:AddAngleVelocity(Angle(math.random(-250, 250), math.random(-250, 250), math.random(-250, 250)))
	end
	
	if data:GetMagnitude() ~= 1 then
		local fx = EffectData()
		fx:SetMagnitude(1)
		fx:SetOrigin(pos)
		
		for i = 1, 15 do
			util.Effect("sbmp_flak_gibbify", fx)
		end
	end
end

function EFFECT:Think()
	return self.LifeTime >= CurTime()
end

function EFFECT:Render()
	self:DrawModel()
end