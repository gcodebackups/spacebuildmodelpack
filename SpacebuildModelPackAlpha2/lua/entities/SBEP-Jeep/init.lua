AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

--util.PrecacheSound( "SB/SteamEngine.wav" )

function ENT:Initialize()
	
	self.Entity:SetModel( "models/Spacebuild/medbridge2_doublehull_elevatorclamp.mdl" ) 
	self.Entity:SetName("Jalopy")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	--self.Entity:SetMaterial("models/props_wasteland/tugboat02")
	--self.Inputs = Wire_CreateInputs( self.Entity, { "Activate" } )

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableGravity(false)
		phys:EnableDrag(false)
		phys:EnableCollisions(false)
	end
	self.Entity:StartMotionController()
	self.PhysObj = self.Entity:GetPhysicsObject()


	self.Speed = 0
	self.TSpeed = 150
	self.Active = false
	self.Skewed = false
	self.HSpeed = 0
		
	self.HPC			= 4
	self.HP				= {}
	self.HP[1]			= {}
	self.HP[1]["Ent"]	= nil
	self.HP[1]["Type"]	= "Tiny"
	self.HP[1]["Pos"]	= Vector(-20,54,15)
	self.HP[1]["Angle"]	= Angle(0,90,0)
	self.HP[2]			= {}
	self.HP[2]["Ent"]	= nil
	self.HP[2]["Type"]	= "Tiny"
	self.HP[2]["Pos"]	= Vector(20,54,15)
	self.HP[2]["Angle"]	= Angle(0,90,0)
	self.HP[3]			= {}
	self.HP[3]["Ent"]	= nil
	self.HP[3]["Type"]	= "Small"
	self.HP[3]["Pos"]	= Vector(-23,-75,50)
	self.HP[3]["Angle"]	= Angle(0,90,-90)
	self.HP[4]			= {}
	self.HP[4]["Ent"]	= nil
	self.HP[4]["Type"]	= "Small"
	self.HP[4]["Pos"]	= Vector(23,-75,50)
	self.HP[4]["Angle"]	= Angle(0,90,90)
	
	self.MCDown = CurTime() + 2
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	
	local ent = ents.Create( "SBEP-Jeep" )
	ent:SetPos( Vector( 100000,100000,100000 ) )
	ent:Spawn()
	ent:Initialize()
	ent:Activate()
	ent.SPL = ply
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,50)
	
	local ent2 = ents.Create( "prop_vehicle_jeep_old" )
	ent2:SetModel( "models/buggy.mdl" ) 
	ent2:SetPos( SpawnPos )
	ent2:SetKeyValue("vehiclescript", "scripts/vehicles/jeep_test.txt")
	ent2:SetKeyValue("limitview", 0)
	ent2.HasHardpoints = true
	ent2:Spawn()
	ent2:Activate()
	--local TB = ent2:GetTable()
	--TB.HandleAnimation = function (vec, ply)
	--	return ply:LookupSequence( "drive_jeep" ) --:SelectWeightedSequence( ACT_HL2MP_SIT ) 
	--end 
	--ent2:SetTable(TB)
	ent2.SPL = ply
	ent2:SetNetworkedInt( "HPC", ent.HPC )
	ent2.HPType = "Vehicle"
	ent2.APPos = Vector(0,60,-66)
	ent2.APAng = Angle(0,90,180)
	
	ent.Pod = ent2
	ent:SetNetworkedEntity( "Pod1", ent2 )
	ent2:SetNetworkedString( "WInfo", "Jeep", true )
	ent2.Cont = ent
	--constraint so controller is duped
	constraint.NoCollide( ent, ent2, 0, 0 )
	
	return ent
	
end


function ENT:Think()
	if self.Pod and self.Pod:IsValid() then
		self.CPL = self.Pod:GetPassenger()
		if (self.CPL && self.CPL:IsValid()) then
			--self.CPL:SetLocalPos(Vector(-6,0,10))
			local trace = {}
			trace.start = self.CPL:GetShootPos()
			trace.endpos = self.CPL:GetShootPos() + self.CPL:GetAimVector() * 10000
			trace.filter = self.Pod
			self.Pod.Trace = util.TraceLine( trace )
			self.Active = true
			
			if (self.CPL:KeyDown( IN_ATTACK )) then
				for i = 1, self.HPC do
					local HPC = self.CPL:GetInfo( "SBHP_"..i )
					if self.HP[i]["Ent"] && self.HP[i]["Ent"]:IsValid() && (HPC == "1.00" || HPC == "1" || HPC == 1) then
						self.HP[i]["Ent"].Entity:HPFire()
					end
				end
			end
			
			if (self.CPL:KeyDown( IN_ATTACK2 )) then
				for i = 1, self.HPC do
					local HPC = self.CPL:GetInfo( "SBHP_"..i.."a" )
					if self.HP[i]["Ent"] && self.HP[i]["Ent"]:IsValid() && (HPC == "1.00" || HPC == "1" || HPC == 1) then
						self.HP[i]["Ent"].Entity:HPFire()
					end
				end
			end
			
			if self.CPL:KeyDown( IN_JUMP ) then
				if self.Pod.Pod && self.Pod.Pod:IsValid() then
					self.Entity:HPRelease()
				end
			end
					
			
		else
			self.Pod.Trace = nil
		end
		
		if !self.Pod.Mounted && CurTime() > self.MCDown then
			local mn, mx = self.Pod:WorldSpaceAABB()
			mn = mn - Vector(2, 2, 2)
			mx = mx + Vector(2, 2, 2)
			local T = ents.FindInBox(mn, mx)
			for _,i in pairs( T ) do
				if( i.Entity && i.Entity:IsValid() && i.Entity != self.Pod ) then
					if i.HasHardpoints then
						if i.Cont && i.Cont:IsValid() then 
							HPLink( i.Cont, i.Entity, self.Pod )
							--print("Linking")
						end
					end
				end
			end
		end
		
	else
		self.Entity:Remove()
	end
	
	self.Entity:NextThink( CurTime() + 0.01 ) 
	return true
end

function ENT:PhysicsCollide( data, physobj )

end

function ENT:OnTakeDamage( dmginfo )
	
end

function ENT:Touch( ent )
	if self.Linking && ent:IsValid()then
		self.CCObj = ent
	end
end

function ENT:OnRemove()
	if self.Pod && self.Pod:IsValid() then
		self.Pod:Remove()
	end
end

function ENT:HPFire()
	if !self.CPL || !self.CPL:IsValid() then
		local ECPL = self.Pod.Pod:GetPassenger()
		if ECPL && ECPL:IsValid() then
			ECPL:ExitVehicle()
			ECPL:EnterVehicle( self.Pod )	
		end
	elseif !self.CPL2 || !self.CPL2:IsValid() then
		local ECPL = self.Pod.Pod:GetPassenger()
		if ECPL && ECPL:IsValid() then
			ECPL:ExitVehicle()
			ECPL:EnterVehicle( self.PassPod )
		end
	end
	
	self.Entity:HPRelease()
end

function ENT:HPRelease()
	self.Pod:SetParent()
	if self.Pod.HPWeld && self.Pod.HPWeld:IsValid() then
		self.Pod.HPWeld:Remove()
		self.Pod.HPWeld = nil
	end
	if self.Pod.Pod && self.Pod.Pod:IsValid() then
		self.Pod.Pod:SetNetworkedEntity( "HPW_"..self.Pod.HPN, self.Pod.Pod )
		self.Pod.Pod.Cont.HP[self.Pod.HPN]["Ent"] = nil
		local NC = constraint.NoCollide(self.Pod, self.Pod.Pod, 0, 0, 0, true)
	end
	self.Pod.Pod = nil
	local phys = self.Pod:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableGravity(true)
		phys:EnableDrag(true)
		phys:EnableCollisions(true)
	end
	self.Pod.Mounted = false
	self.MCDown = CurTime() + 2
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	--print("Building Rover Dupe Info")
	if (self.Pod) and (self.Pod:IsValid()) then
		info.Pod = self.Pod:EntIndex()
	end
	info.guns = {}
	for k,v in pairs(self.HP) do
		if (v["Ent"]) and (v["Ent"]:IsValid()) then
			info.guns[k] = v["Ent"]:EntIndex()
		end
	end
	--PrintTable(info)
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	--print("Applying Rover Dupe Info")
	if (info.guns) then
		for k,v in pairs(info.guns) do
			local gun = GetEntByID(v)
			self.HP[k]["Ent"] = gun
			if (!self.HP[k]["Ent"]) then
				gun = ents.GetByIndex(v)
				self.HP[k]["Ent"] = gun
			end
		end
	end
	if (info.Pod) then
		self.Pod = GetEntByID(info.Pod)
		if (!self.Pod) then
			self.Pod = ents.GetByIndex(info.Pod)
		end
		local ent2 = self.Pod
		ent2.Cont = ent
		ent2:SetKeyValue("limitview", 0)
		ent2.HasHardpoints = true
		ent2.HasWheels = true
		local TB = ent2:GetTable()
		TB.HandleAnimation = function (vec, ply)
			return ply:SelectWeightedSequence( ACT_HL2MP_SIT ) 
		end 
		ent2:SetTable(TB)
		ent2.SPL = ply
		ent2:SetNetworkedInt( "HPC", ent.HPC )
		ent2.HPType = "Vehicle"
		ent2.APPos = Vector(0,50,-66)
		ent2.APAng = Angle(0,90,180)
	end
	self.SPL = ply
end