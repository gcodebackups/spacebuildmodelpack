AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	
	self.Entity:SetModel( "models/SmallBridge/Ship Parts/sblandurampdwdh.mdl" ) 
	self.Entity:SetName("DWDHA")
	self.BaseClass:Initialize(self)
	self.CompatibleLocks = {}
	self.CompatibleLocks[1] = "DWDHA"
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	
	local ent = ents.Create( "AL_DWDHB" )
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,200)
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Initialize()
	ent:Activate()
	ent.SPL = ply
		
	return ent
end
