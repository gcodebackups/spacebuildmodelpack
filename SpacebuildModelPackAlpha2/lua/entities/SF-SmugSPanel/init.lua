
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )
util.PrecacheSound( "SB/Gattling2.wav" )

function ENT:Initialize()

	self.Entity:SetModel( "models/Slyfo/smuggler_side.mdl" ) 
	self.Entity:SetName("SmallMachineGun")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs( self.Entity, { "Open", "OpenMode" } )
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableGravity(true)
		phys:EnableDrag(true)
		phys:EnableCollisions(true)
	end
	self.Entity:SetKeyValue("rendercolor", "255 255 255")
	self.PhysObj = self.Entity:GetPhysicsObject()
	
	--self.val1 = 0
	--RD_AddResource(self.Entity, "Munitions", 0)
	
	self.Cont = self.Entity
	self.COp = false
	self.Mode = 0
	
	self.OTime = 0
	self.BTime = 0
	self.RTime = 0
	self.CHeight = 0
	self.CRotate = 0
	self.TogC = 0
	self.AutoCT = 0
	self.AutoC = false
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,100)
	
	local ent = ents.Create( "SF-SmugSPanel" )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()
	ent.SPL = ply
	
	return ent
	
end

function ENT:TriggerInput(iname, value)		
	if (iname == "Open") then
		if (value > 0) then
			if !self.COp && self.Pod && self.Pod:IsValid() then
				self.Entity:Open(self.Mode)
			end
		else
			if self.COp && self.Pod && self.Pod:IsValid() then
				self.Entity:Close(self.Mode)
			end
		end
		
	elseif (iname == "OpenMode") then
		self.Mode = value
			
	end
end

function ENT:PhysicsUpdate()

end

function ENT:Think()
	
	if self.AutoC && CurTime() > self.AutoCT then
		self.Entity:Close(self.Mode)
		self.AutoC = false
	end
	
	if self.Mode == 1 || self.Mode == 2 then
		local A = math.Clamp( self.OTime - CurTime(), 0, 1 )
		local F = 0
		local S = 0
		if self.COp then
			F = 0
			S = 255
		else
			F = 255
			S = 0
		end
		local Alph = Lerp(A,F,S)
		self.Entity:SetColor(255,255,255,Alph)
		
		if self.Mode == 2 && self.BTime > CurTime() then
			if self.Panel && self.Panel:IsValid() then
				self.Panel:GetPhysicsObject():SetVelocity(self.Entity:GetRight() * 5000)
			end
		end
	elseif self.Mode == 3 then
		if self.COp && self.CHeight < 185 then
			self.CHeight = self.CHeight + 1
		end
		if !self.COp && self.CHeight > 0 then
			self.CHeight = self.CHeight - 1
		end
		
		local Offset = self.Pod.HP[self.HPN]["Pos"]
		local X = Offset.x
		local Y = Offset.y
		local Z = Offset.z - self.CHeight
		self.Entity:SetLocalPos( Vector(X,-Y,Z) )
	elseif self.Mode == 4 then
		if self.COp && self.CRotate < 360 then
			self.CRotate = self.CRotate + 4
		end
		if !self.COp && self.CRotate > 0 then
			self.CRotate = self.CRotate - 4
		end
		
		local NAng = self.Pod:GetAngles()
		local Offset = self.Pod.HP[self.HPN]["Pos"]
		local PAngle = self.Pod.HP[self.HPN]["Angle"]
		local AOffset = 0
		local Inv = false
		if PAngle then
			Inv = true
			AOffset = PAngle.y
		end
		
		
		local YOffset = (self.CRotate - ( math.Clamp(self.CRotate - 180,0,180) * 2 )) * 0.5
		
		local X = Offset.x
		local Y = Offset.y
		local Z = Offset.z
						
		NAng:RotateAroundAxis( NAng:Up(), AOffset )
		if Inv then
			NAng:RotateAroundAxis( NAng:Forward(), -self.CRotate )
			Y = Y - YOffset
		else
			NAng:RotateAroundAxis( NAng:Forward(), self.CRotate )
			Y = Y + YOffset
		end
		self.Entity:SetLocalPos( Vector(X,-Y,Z) )
		self.Entity:SetLocalAngles( self.Entity:WorldToLocalAngles(NAng) )
	end
	
	if self.Panel && self.Panel:IsValid() && !self.Panel.Blasted then
		self.Panel:GetPhysicsObject():SetVelocity(self.Entity:GetRight() * 5000)
		self.Panel.Blasted = true
	end

	self.Entity:NextThink( CurTime() + 0.01 ) 
	return true
end

function ENT:PhysicsCollide( data, physobj )
	
end

function ENT:OnTakeDamage( dmginfo )
	
end

function ENT:Use( activator, caller )
	if CurTime() > self.TogC then
		if self.COp then
			self.Entity:Close(self.Mode)
		else
			self.Entity:Open(self.Mode)
			self.AutoCT = CurTime() + 15
			self.AutoC = true
		end
		self.TogC = CurTime() + 4
	end

end

function ENT:Touch( ent )
	if ent.HasHardpoints then
		if ent.Cont && ent.Cont:IsValid() then HPLink( ent.Cont, ent.Entity, self.Entity ) end
		self.Entity:GetPhysicsObject():EnableCollisions(true)
	end
end

function ENT:HPFire()
	if !self.COp && self.Pod && self.Pod:IsValid() then
		self.Entity:Open(self.Mode)
	else
		self.Entity:Close(self.Mode)
	end
end

--Modes: 0 = fade, 1 = slow fade, 2 = blast, 3 = slide, 4 = rotate
function ENT:Open( mode )
	if mode == 0 then
		self.Entity:SetColor(255,255,255,50)
		--self.Entity:SetParent(self.Pod)
		self.Entity:SetNotSolid( true )
		self.Entity:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		self.COp = true
	elseif mode == 1 then
		self.OTime = CurTime() + 1	
		--self.Entity:SetParent(self.Pod)
		self.Entity:SetNotSolid( true )
		self.Entity:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		self.COp = true
	elseif mode == 2 then
		self.Entity:SetColor(255,255,255,0)
		self.Entity:SetNotSolid( true )
		self.Entity:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		self.COp = true
		
		local effectdata = EffectData()
		effectdata:SetOrigin( self.Entity:GetPos() + self.Entity:GetUp() * 95 + self.Entity:GetForward() * 255 )
		effectdata:SetAngle( self.Entity:GetRight() )
		effectdata:SetMagnitude( 5 )
		effectdata:SetScale( 5 )
		effectdata:SetRadius( 5 )
		util.Effect( "GlassImpact", effectdata )
		
		effectdata = EffectData()
		effectdata:SetOrigin( self.Entity:GetPos() + self.Entity:GetUp() * 95 + self.Entity:GetForward() * -255 )
		effectdata:SetAngle( self.Entity:GetRight() )
		effectdata:SetMagnitude( 5 )
		effectdata:SetScale( 5 )
		effectdata:SetRadius( 5 )
		util.Effect( "GlassImpact", effectdata )
		
		effectdata = EffectData()
		effectdata:SetOrigin( self.Entity:GetPos() + self.Entity:GetUp() * -95 + self.Entity:GetForward() * 255 )
		effectdata:SetAngle( self.Entity:GetRight() )
		effectdata:SetMagnitude( 5 )
		effectdata:SetScale( 5 )
		effectdata:SetRadius( 5 )
		util.Effect( "GlassImpact", effectdata )
		
		effectdata = EffectData()
		effectdata:SetOrigin( self.Entity:GetPos() + self.Entity:GetUp() * -95 + self.Entity:GetForward() * -255 )
		effectdata:SetAngle( self.Entity:GetRight() )
		effectdata:SetMagnitude( 5 )
		effectdata:SetScale( 5 )
		effectdata:SetRadius( 5 )
		util.Effect( "GlassImpact", effectdata )
		
		if self.Panel && self.Panel:IsValid() then
			self.Panel:Remove()
		end
		
		local Panel = ents.Create( "prop_physics" )
		
		Panel:SetModel( "models/Slyfo/smuggler_side.mdl" )
		Panel:SetPos( self.Entity:GetPos() + self.Entity:GetRight() * 10 ) 
		Panel:SetAngles( self.Entity:GetAngles() )
		Panel:Spawn()
		--self.CamC:Initialize()
		Panel:Activate()
		Panel:GetPhysicsObject():SetVelocity(self.Entity:GetRight() * 5000)
		Panel:GetPhysicsObject():EnableDrag(false)
		Panel:Fire("kill", "", 20)
		Panel.Blasted = false
		
		self.Panel = Panel
		
		self.BTime = CurTime() + 0.1
	
	elseif mode == 3 then
		self.COp = true
		
	elseif mode == 4 then
		self.COp = true
		
	end

end

function ENT:Close( mode )
	self.AutoC = false
	--self.Entity:SetParent(self.Pod)
	if mode == 0 then
		self.Entity:SetColor(255,255,255,255)
		self.Entity:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
		self.Entity:SetNotSolid( false )
		self.COp = false
	elseif mode == 1 then
		self.OTime = CurTime() + 1	
		self.Entity:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
		self.Entity:SetNotSolid( false )
		self.COp = false
	elseif mode == 2 then
		self.OTime = CurTime() + 1
		self.Entity:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
		self.Entity:SetNotSolid( false )
		self.COp = false
	elseif mode == 3 then
		self.COp = false
	elseif mode == 4 then
		self.COp = false
	end
end