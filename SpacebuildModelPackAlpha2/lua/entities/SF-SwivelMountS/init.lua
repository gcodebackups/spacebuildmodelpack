
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('entities/base_wire_entity/init.lua')
include( 'shared.lua' )
util.PrecacheSound( "SB/Gattling2.wav" )

function ENT:Initialize()

	--self.Entity:SetModel( "models/Slyfo/smlturrettop.mdl" ) 
	self.Entity:SetName("SmallMachineGun")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	local inNames = {"Active", "Fire", "X", "Y", "Z","Vector"}
	local inTypes = {"NORMAL","NORMAL","NORMAL","NORMAL","NORMAL","VECTOR"}
	self.Inputs = WireLib.CreateSpecialInputs( self.Entity,inNames,inTypes)
	
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
	self.Firing = false
	self.Active = false
	
	self.XCo = 0
	self.YCo = 0
	self.ZCo = 0
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,70)
	
	local ent = ents.Create( "SF-SwivelMountS" )
	ent:SetPos( SpawnPos )
	ent:SetModel( "models/Slyfo/smlturrettop.mdl" ) 
	ent:Spawn()
	ent:Initialize()
	ent:Activate()
	ent.SPL = ply
	
	ent.HPC				= 1
	ent.HP				= {}
	ent.HP[1]			= {}
	ent.HP[1]["Ent"]	= nil
	ent.HP[1]["Type"]	= "Small"
	ent.HP[1]["Pos"]	= Vector(0,0,12)
	
	SpawnPos2 = SpawnPos + Vector(3,-3,-30)
	
	ent2 = ents.Create( "prop_physics" )
	ent2:SetModel( "models/Slyfo/smlturretbase.mdl" ) 
	ent2:SetPos( SpawnPos2 )
	ent2:Spawn()
	ent2:Activate()
	ent.Base = ent2
	
	local LPos = ent:WorldToLocal(ent:GetPos() + ent:GetUp() * 10)
	local Cons = constraint.Ballsocket( ent2, ent, 0, 0, LPos, 0, 0, 1)
	LPos = ent:WorldToLocal(ent:GetPos() + ent:GetUp() * -10)
	Cons = constraint.Ballsocket( ent2, ent, 0, 0, LPos, 0, 0, 1)
	
	return ent
	
end

function ENT:TriggerInput(iname, value)		
	if (iname == "Active") then
		if (value > 0) then
			self.Active = true
		else
			self.Active = false
		end
		
	elseif (iname == "Fire") then
		if (value > 0) then
			self.Firing = true
		else
			self.Firing = false
		end
		
	elseif (iname == "X") then
		self.XCo = value
	
	elseif (iname == "Y") then
		self.YCo = value
	
	elseif (iname == "Z") then
		self.ZCo = value
	
	elseif (iname == "Vector") then
		self.XCo = value.x
		self.YCo = value.y
		self.ZCo = value.z
				
	end
end

function ENT:Think()
	local Weap = self.HP[1]["Ent"]
	
	if Weap && Weap:IsValid() then
	
		if !Weap.Swivved then
			local LPos = Vector(0,0,0)
			LPos = Weap:WorldToLocal(Weap:GetPos() + (Weap:GetForward() * -Weap.APPos.x) + (Weap:GetRight() * (-Weap.APPos.y + 10)) + (Weap:GetUp() * -Weap.APPos.z ) )
			self.WSock1 = constraint.Ballsocket( self.Entity, Weap, 0, 0, LPos, 0, 0, 1)
			LPos = Weap:WorldToLocal(Weap:GetPos() + (Weap:GetForward() * -Weap.APPos.x) + (Weap:GetRight() * (-Weap.APPos.y + -10)) + (Weap:GetUp() * -Weap.APPos.z ) )
			self.WSock2 = constraint.Ballsocket( self.Entity, Weap, 0, 0, LPos, 0, 0, 1)
			
			constraint.RemoveConstraints( Weap, "Weld" )
			Weap:SetParent()
			Weap.Swivved = true
		end
		
		local TargPos = nil
		if self.CPod && self.CPod:IsValid() then
			self.CPL = self.CPod:GetPassenger()
			if (self.CPL && self.CPL:IsValid()) then
							
				if (self.CPL:KeyDown( IN_ATTACK )) then
					--for i = 1, self.HPC do
					--	local HPC = self.CPL:GetInfo( "SBHP_"..i )
					--	if self.HP[i]["Ent"] && self.HP[i]["Ent"]:IsValid() && (HPC == "1.00" || HPC == "1" || HPC == 1) then
							self.HP[1]["Ent"].Entity:HPFire()
					--	end
					--end
				end
				
				self.CPL:CrosshairEnable()
				
				TargPos = self.CPL:GetEyeTrace().HitPos				
			end
		end
		if self.Active then
			TargPos = Vector(self.XCo,self.YCo,self.ZCo)
		end
		if TargPos then
			local FDist = TargPos:Distance( Weap:GetPos() + Weap:GetUp() * 200 )
			local BDist = TargPos:Distance( Weap:GetPos() + Weap:GetUp() * -200 )
			local Pitch = math.Clamp((FDist - BDist) * 6.75, -1050, 1050)
			FDist = TargPos:Distance( Weap:GetPos() + Weap:GetRight() * 200 )
			BDist = TargPos:Distance( Weap:GetPos() + Weap:GetRight() * -200 )
			local Yaw = math.Clamp((BDist - FDist) * 6.75, -1050, 1050)
			
			local physi = self.Entity:GetPhysicsObject()
			local physi2 = Weap:GetPhysicsObject()
			
			physi:AddAngleVelocity((physi:GetAngleVelocity() * -1) + Angle(0,0,-Yaw))
			physi2:AddAngleVelocity((physi2:GetAngleVelocity() * -1) + Angle(0,Pitch,0))
		end
	end
	
	self.Entity:NextThink( CurTime() + 0.01 ) 
	return true	
end

function ENT:OnRemove( ) 
	self.Base:Remove()
end

function ENT:PhysicsCollide( data, physobj )
	
end

function ENT:OnTakeDamage( dmginfo )
	
end

function ENT:Use( activator, caller )

end

function ENT:Touch( ent )
	if ent && ent:IsValid() && ent:IsVehicle() then
		self.CPod = ent
	end
end

function ENT:HPFire()
	if self.HP[1]["Ent"] && self.HP[1]["Ent"]:IsValid() then
		self.HP[1]["Ent"]:HPFire()
	end
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if (self.CPod) and (self.CPod:IsValid()) then
	    info.cpod = self.CPod:EntIndex()
	end
	if (self.HP[1]["Ent"]) and (self.HP[1]["Ent"]:IsValid()) then
	    info.gun = self.HP[1]["Ent"]:EntIndex()
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.HPC				= 1
	self.HP				= {}
	self.HP[1]			= {}
	self.HP[1]["Ent"]	= nil
	self.HP[1]["Type"]	= "Small"
	self.HP[1]["Pos"]	= Vector(0,0,12)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if (info.cpod) then
		self.CPod = GetEntByID(info.cpod)
		if (!self.CPod) then
			self.CPod = ents.GetByIndex(info.cpod)
		end
	end
	if (info.gun) then
		self.HP[1]["Ent"] = GetEntByID(info.gun)
		if (!self.HP[1]["Ent"]) then
			self.HP[1]["Ent"] = ents.GetByIndex(info.gun)
		end
	end
end
