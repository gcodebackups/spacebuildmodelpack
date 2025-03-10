
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('entities/base_wire_entity/init.lua')
include( 'shared.lua' )
util.PrecacheSound( "SB/Gattling2.wav" )

function ENT:Initialize()

	self.Entity:SetModel( "models/Slyfo/rover1_backgun.mdl" ) 
	self.Entity:SetName("SmallMachineGun")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs( self.Entity, { "Fire" } )
	
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


end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,50)
	
	local ent = ents.Create( "SF-SmallMG" )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()
	ent.SPL = ply
	
	return ent
	
end

function ENT:TriggerInput(iname, value)		
	if (iname == "Fire") then
		if (value > 0) then
			self.Active = true
		else
			self.Active = false
		end
			
	end
end

function ENT:PhysicsUpdate()

end

function ENT:Think()
	
	if (self.Active == true || self.FTime > CurTime() ) then	
	
		local vStart = self.Entity:GetPos()-- + (self.Entity:GetForward() * 20) + (self.Entity:GetUp() * BUp) + (self.Entity:GetRight() * BRi)
		local vForward = self.Entity:GetForward()
		
		local Bullet = {}
		Bullet.Num = 1
		Bullet.Src = self.Entity:GetPos()
		Bullet.Dir = self.Entity:GetForward() --Position * -1
		Bullet.Spread = Vector( 0.01, 0.01, 0.01 )
		Bullet.Tracer = 1
		Bullet.Force = 100
		Bullet.TracerName = "Tracer"
		Bullet.Attacker = self.SPL
		Bullet.Damage = 100
		Bullet.Callback = function (attacker, tr, dmginfo)
			if (tr.Entity and tr.Entity:IsValid()) then
				local  gdmg = math.random(50,100)
				attack = cbt_dealdevhit(tr.Entity, gdmg, 5)
				if (attack != nil) then
					if (attack == 2) then
						local wreck = ents.Create( "wreckedstuff" )
						wreck:SetModel( tr.Entity:GetModel() )
						wreck:SetAngles( tr.Entity:GetAngles() )
						wreck:SetPos( tr.Entity:GetPos() )
						wreck:Spawn()
						wreck:Activate()
						tr.Entity:Remove()
						local effectdata1 = EffectData()
						effectdata1:SetOrigin(tr.Entity:GetPos())
						effectdata1:SetStart(tr.Entity:GetPos())
						effectdata1:SetScale( 10 )
						effectdata1:SetRadius( 100 )
						util.Effect( "Explosion", effectdata1 )
					end
				end
			end
		end
			
				
		self:FireBullets(Bullet)
				
		self.Entity:EmitSound("SB/Gattling2.wav", 400)
		
	end
	self.Entity:NextThink( CurTime() + 0.25 )
	return true
end

function ENT:PhysicsCollide( data, physobj )
	
end

function ENT:OnTakeDamage( dmginfo )
	
end

function ENT:Use( activator, caller )

end

function ENT:Touch( ent )
	if ent.HasHardpoints then
		if ent.Cont && ent.Cont:IsValid() then HPLink( ent.Cont, ent.Entity, self.Entity ) end
	end
end

function ENT:HPFire()
	self.FTime = CurTime() + 0.1
end
