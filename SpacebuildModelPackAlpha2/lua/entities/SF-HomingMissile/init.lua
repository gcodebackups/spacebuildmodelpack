
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

util.PrecacheSound( "explode_9" )
util.PrecacheSound( "explode_8" )
util.PrecacheSound( "explode_5" )

function ENT:Initialize()

	self.Entity:SetModel( "models/weapons/w_missile_launch.mdl" )
	self.Entity:SetName("HomingMissile")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	--self.Entity:SetMaterial("models/props_combine/combinethumper002")
	--self.Inputs = Wire_CreateInputs( self.Entity, { "Arm" } )
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableGravity(false)
		phys:EnableDrag(false)
		phys:EnableCollisions(true)
		phys:SetMass( 1 )
	end

	gcombat.registerent( self.Entity, 10, 4 )
	self.Armed = true
	
    --self.Entity:SetKeyValue("rendercolor", "0 0 0")
	self.PhysObj = self.Entity:GetPhysicsObject()
	self.CAng = self.Entity:GetAngles()
	
	self.XCo = 0
	self.YCo = 0
	self.ZCo = 0
	
	self.TSClamp = 100
	
	self.Yaw = 0
	self.Pitch = 0
	
	self.hasdamagecase = true
	
end

function ENT:TriggerInput(iname, value)		
	
	if (iname == "Arm") then
		if (value > 0) then
			self.Entity:Arm()
		end
		
	elseif (iname == "Detonate") then	
		if (value > 0) then
			self.Entity:Splode()
		end
	end
	
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,50)
	
	local ent = ents.Create( "SF-HomingMissile" )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Initialize()
	ent:Activate()
	ent.SPL = ply
	
	return ent
	
end

function ENT:Think()
	local TVec = nil
	if self.GType == 1 then
		TVec = Vector(self.XCo, self.YCo, self.ZCo)
		
	elseif self.GType == 2 then
		if self.ParL && self.ParL:IsValid() then
			self.XCo = self.ParL.XCo
			self.YCo = self.ParL.YCo
			self.ZCo = self.ParL.ZCo
		end
		TVec = Vector(self.XCo, self.YCo, self.ZCo)
		
	elseif self.GType == 4 then
		if self.TEnt && self.TEnt:IsValid() then
			TVec = self.TEnt:GetPos()
		end
		
	elseif self.GType == 3 then
		if self.Target && self.Target:IsValid() then
			TVec = self.Target:GetPos()
		else
			local targets = ents.FindInCone( self.Entity:GetPos(), self.Entity:GetForward(), 5000, 65)
	
			local CMass = 0
			local CT = nil
						
			for _,i in pairs(targets) do
				if i:GetPhysicsObject() && i:GetPhysicsObject():IsValid() && !i.Autospawned then
					local IMass = i:GetPhysicsObject():GetMass()
					local IDist = (self.Entity:GetPos() - i:GetPos()):Length()
					if i.IsFlare == true then IMass = 5000 end
					local TVal = (IMass * 3) - IDist
					if TVal > CMass then
						CT = i
					end
				end
			end
			self.Target = CT
		end
	elseif self.GType == 5 then --This will not work.
		if self.Pod and self.Pod:IsValid() && self.Pod:IsVehicle() then
			self.CPL = self.Pod:GetPassenger()
			if self.CPL && self.CPL:IsValid() then
				self.Yaw = math.Clamp(self.CPL.SBEPYaw * -0.1, -self.TSClamp, self.TSClamp)
				self.Pitch = math.Clamp(self.CPL.SBEPPitch * 0.1, -self.TSClamp, self.TSClamp)
			end
		end
	end
	
	if self.GType > 0 && self.GType < 5 then
		if TVec then
			local FDist = TVec:Distance( self.Entity:GetPos() + self.Entity:GetUp() * 100 )
			local BDist = TVec:Distance( self.Entity:GetPos() + self.Entity:GetUp() * -100 )
			self.Pitch = math.Clamp((FDist - BDist) * 0.75, -self.TSClamp, self.TSClamp)
			FDist = TVec:Distance( self.Entity:GetPos() + self.Entity:GetRight() * 100 )
			BDist = TVec:Distance( self.Entity:GetPos() + self.Entity:GetRight() * -100 )
			self.Yaw = math.Clamp((BDist - FDist) * -0.75, -self.TSClamp, self.TSClamp)
			--print(self.Pitch .. ", " .. self.Yaw)
		else
			self.Pitch = 0
			self.Yaw = 0
		end
	end
	
	if self.GType > 0 then
		local physi = self.Entity:GetPhysicsObject()
		physi:AddAngleVelocity((physi:GetAngleVelocity() * -1) + Angle(0,self.Pitch,self.Yaw))
		physi:SetVelocity( self.Entity:GetForward() * 1000 )
	end
	
	local trace = {}
	trace.start = self.Entity:GetPos()
	trace.endpos = self.Entity:GetPos() + (self.Entity:GetVelocity())
	trace.filter = self.Entity
	local tr = util.TraceLine( trace )
	if tr.Hit and tr.HitSky then
		self.Entity:Remove()
	end
	
	self.Entity:NextThink( CurTime() + 0.1 )
	return true
end

function ENT:PhysicsCollide( data, physobj )
	if (!self.Exploded && self.Armed) then
		self:Splode()
	end
	self.Exploded = true
end

function ENT:OnTakeDamage( dmginfo )
	if (!self.Exploded && self.Armed) then
		--self:Splode()
	end
	--self.Exploded = true
end

function ENT:Use( activator, caller )
	--self.Entity:Arm()
end

function ENT:Splode()
	if(!self.Exploded) then
		self.Exploded = true
		util.BlastDamage(self.Entity, self.Entity, self.Entity:GetPos(), 150, 150)
		SBGCSplash( self.Entity:GetPos(), 100, math.Rand(200, 500), 6, { self.Entity:GetClass() } )
		
		--targets = ents.FindInSphere( self.Entity:GetPos(), 2000)
		
		self.Entity:EmitSound("explode_9")
		
		local effectdata = EffectData()
		effectdata:SetOrigin(self.Entity:GetPos())
		effectdata:SetStart(self.Entity:GetPos())
		util.Effect( "explosion", effectdata )
		self.Exploded = true
		
		local ShakeIt = ents.Create( "env_shake" )
		ShakeIt:SetName("Shaker")
		ShakeIt:SetKeyValue("amplitude", "200" )
		ShakeIt:SetKeyValue("radius", "200" )
		ShakeIt:SetKeyValue("duration", "5" )
		ShakeIt:SetKeyValue("frequency", "255" )
		ShakeIt:SetPos( self.Entity:GetPos() )
		ShakeIt:Fire("StartShake", "", 0);
		ShakeIt:Spawn()
		ShakeIt:Activate()
		
		ShakeIt:Fire("kill", "", 6)
	end
	self.Exploded = true
	self.Entity:Remove()
end

function ENT:Touch( ent )
	if ent.HasHardpoints && !self.Armed then
		--if ent.Cont && ent.Cont:IsValid() then HPLink( ent.Cont, ent.Entity, self.Entity ) end
	end
end

function ENT:OnRemove()
	--self.CPL:SetViewEntity()
end

function ENT:gcbt_breakactions( damage, pierce )
	if !self.Exploded then
		self.Entity:Splode()
	end
	self.Exploded = true
end