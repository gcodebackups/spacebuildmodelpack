
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()

	self.Entity:SetModel( "models/Slyfo/hangar1.mdl" )
	self.Entity:SetName("AssaultPodLauncher")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	--self.Entity:SetMaterial("models/props_combine/combinethumper002");
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableGravity(true)
		phys:EnableDrag(true)
		phys:EnableCollisions(true)
	end
	
    self.Entity:SetKeyValue("rendercolor", "255 255 255")
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,150)
	
	local ent = ents.Create( "APodLauncher" )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Initialize()
	ent:Activate()
	ent.SPL = ply
	
	return ent
	
end

function ENT:Think()
	if (self.NPod1 == nil || !self.NPod1:IsValid() || self.NPod1.Active) then
		local ent = ents.Create( "BoardingPod" )
		ent:SetPos( Vector( 100000,100000,100000 ) )
		ent:Spawn()
		ent:Initialize()
		ent:Activate()
		ent.SPL = ply
			
		self.NPod1 = ents.Create( "prop_vehicle_prisoner_pod" )
		self.NPod1:SetModel( "models/Slyfo/assault_pod.mdl" ) 
		self.NPod1:SetAngles( self.Entity:GetAngles() )
		self.NPod1:SetPos( self.Entity:GetPos() + self.Entity:GetRight() * 350 + self.Entity:GetUp() * -50 )
		self.NPod1:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
		self.NPod1:SetKeyValue("limitview", 0)
		self.NPod1:Spawn()
		self.NPod1:Activate()
		self.NPod1.Mounted = true
		local WD = constraint.Weld(self.Entity, self.NPod1, 0, 0, 0, true)
		--self.NPod1:SetParent( self.Entity )
		local TB = self.NPod1:GetTable()
		TB.HandleAnimation = function (vec, ply)
			return ply:SelectWeightedSequence( ACT_HL2MP_SIT ) 
		end 
		self.NPod1:SetTable(TB)
		
		ent.Pod = self.NPod1
		self.NPod1.Cont = ent
	end
	
	if (self.NPod2 == nil || !self.NPod2:IsValid() || self.NPod2.Active) then
		local ent = ents.Create( "BoardingPod" )
		ent:SetPos( Vector( 100000,100000,100000 ) )
		ent:Spawn()
		ent:Initialize()
		ent:Activate()
		ent.SPL = ply
			
		self.NPod2 = ents.Create( "prop_vehicle_prisoner_pod" )
		self.NPod2:SetModel( "models/Slyfo/assault_pod.mdl" ) 
		self.NPod2:SetAngles( self.Entity:GetAngles() )
		self.NPod2:SetPos( self.Entity:GetPos() + self.Entity:GetRight() * -350 + self.Entity:GetUp() * -50 )
		self.NPod2:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
		self.NPod2:SetKeyValue("limitview", 0)
		self.NPod2:Spawn()
		self.NPod2:Activate()
		self.NPod2.Mounted = true
		local WD = constraint.Weld(self.Entity, self.NPod2, 0, 0, 0, true)
		--self.NPod2:SetParent( self.Entity )
		local TB = self.NPod2:GetTable()
		TB.HandleAnimation = function (vec, ply)
			return ply:SelectWeightedSequence( ACT_HL2MP_SIT ) 
		end 
		self.NPod2:SetTable(TB)
		
		ent.Pod = self.NPod2
		self.NPod2.Cont = ent
	end
end

function ENT:OnRemove( )
	--Remove the pods when the launcher is removed
	self.NPod1:Remove()
	self.NPod2:Remove()
end

function ENT:Use(activator)
	
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if (self.NPod1) and (self.NPod1:IsValid()) then
	    info.NPod1 = self.NPod1:EntIndex()
	end
	if (self.NPod2) and (self.NPod2:IsValid()) then
	    info.NPod2 = self.NPod2:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	--Remove old pods instead instead of storing data for new ones
	--It's easier this way and you can't tell the difference.
	GetEntByID(info.NPod1):Remove()
	GetEntByID(info.NPod2):Remove()
end
