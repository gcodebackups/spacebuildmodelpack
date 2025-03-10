AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")


function ENT:Initialize( )
	self.Entity:SetModel( "models/weapons/w_bugbait.mdl" )
 	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetColor( 000, 000, 000, 255 )
	self.Entity:GetPhysicsObject( ):SetMass( 1 )
	self.Entity:GetPhysicsObject( ):Wake( )
	self.owner = 0
	self.hit = false
	self.CDSIgnore = true
end

function ENT:SetOwner(owner)
	self.owner = owner
end


function ENT:PhysicsCollide( data, physobj )
	if data.HitEntity and not self.hit then
		self.hit = true
		local effect, snd
		if CombatDamageSystem then
			cds_damagepos(self.Entity:GetPos(), 20, 34, 100, self.owner)
		else //todo: maybe add GCombat support?
			data.HitEntity:TakeDamage( 75, self.owner)
		end
		effect = EffectData( )
			effect:SetScale( 10 )
			effect:SetMagnitude( 10 )
			effect:SetOrigin( self:GetPos( ) )
		util.Effect( "cds_plasma_distruption", effect )
		snd = math.random( 9 )
		while snd == 4 do
			snd = math.random( 9 )
		end
		WorldSound( Sound( "ambient/energy/zap" .. snd .. ".wav" ), self:GetPos( ), 100, 100 )
		
	end
end

function ENT:Think()

end

function ENT:PhysicsUpdate(PhysObj)
	PhysObj:ApplyForceCenter(self.Entity:GetForward() * -5000000)
	if self.hit then
		self.Entity:Remove()
	end
end
