AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

--util.PrecacheSound( "SB/SteamEngine.wav" )

function ENT:Initialize()
	
	self.Entity:SetModel( "models/Spacebuild/medbridge2_doublehull_elevatorclamp.mdl" ) 
	self.Entity:SetName("Rover")
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
	self.Skewed = true
	self.HSpeed = 0
		
	self.HPC			= 3
	self.HP				= {}
	self.HP[1]			= {}
	self.HP[1]["Ent"]	= nil
	self.HP[1]["Type"]	= "RLeftPanel"
	self.HP[1]["Pos"]	= Vector(-29,33,63)
	self.HP[2]			= {}
	self.HP[2]["Ent"]	= nil
	self.HP[2]["Type"]	= "RRightPanel"
	self.HP[2]["Pos"]	= Vector(29,33,63)
	self.HP[3]			= {}
	self.HP[3]["Ent"]	= nil
	self.HP[3]["Type"]	= "RBackPanel"
	self.HP[3]["Pos"]	= Vector(0,-29,74)
	
	self.WhC = 4
	self.Wh = {}
	self.Wh[1] = {}
	self.Wh[1]["Ent"]	= nil
	self.Wh[1]["Pos"]	= Vector(34,93,-6)
	self.Wh[1]["Side"]	= "Left"
	self.Wh[2] = {}
	self.Wh[2]["Ent"]	= nil
	self.Wh[2]["Pos"]	= Vector(-34,93,-6)
	self.Wh[2]["Side"]	= "Right"
	self.Wh[3] = {}
	self.Wh[3]["Ent"]	= nil
	self.Wh[3]["Pos"]	= Vector(34,-24,-6)
	self.Wh[3]["Side"]	= "Left"
	self.Wh[4] = {}
	self.Wh[4]["Ent"]	= nil
	self.Wh[4]["Pos"]	= Vector(-34,-24,-6)
	self.Wh[4]["Side"]	= "Right"
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	
	local ent = ents.Create( "Rover" )
	ent:SetPos( Vector( 100000,100000,100000 ) )
	ent:Spawn()
	ent:Initialize()
	ent:Activate()
	ent.SPL = ply
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,50)
	
	local ent2 = ents.Create( "prop_vehicle_prisoner_pod" )
	ent2:SetModel( "models/Slyfo/rover1_chassis.mdl" ) 
	ent2:SetPos( SpawnPos )
	ent2:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
	ent2:SetKeyValue("limitview", 0)
	ent2.HasHardpoints = true
	ent2.HasWheels = true
	ent2:Spawn()
	ent2:Activate()
	local TB = ent2:GetTable()
	TB.HandleAnimation = function (vec, ply)
		return ply:SelectWeightedSequence( ACT_HL2MP_SIT ) 
	end 
	ent2:SetTable(TB)
	ent2.SPL = ply
	ent2:SetNetworkedInt( "HPC", ent.HPC )
	ent2.HPType = "Vehicle"
	ent2.APPos = Vector(-20,0,-86)
	ent2.APAng = Angle(0,0,180)
	
	ent.Pod = ent2
	ent2.Cont = ent
	--constraint so controller is duped
	constraint.NoCollide( ent, ent2, 0, 0 )
	
	return ent
	
end

local Roverjcon = {}	
local RoverJoystickControl = function()
	--Joystick control stuff
	
	Roverjcon.turn = jcon.register{
		uid = "rover_turn",
		type = "analog",
		description = "Turning",
		category = "Rover",
	}
	Roverjcon.accelerate = jcon.register{
		uid = "rover_accelerate",
		type = "analog",
		description = "Accelerate/Decelerate",
		category = "Rover",
	}
	Roverjcon.strafe = jcon.register{
		uid = "rover_strafe",
		type = "analog",
		description = "Strafe",
		category = "Rover",
	}
	Roverjcon.right = jcon.register{
		uid = "rover_strafe_right",
		type = "digital",
		description = "Strafe Right",
		category = "Rover",
	}
	Roverjcon.left = jcon.register{
		uid = "rover_strafe_left",
		type = "digital",
		description = "Strafe Left",
		category = "Rover",
	}
	Roverjcon.jump = jcon.register{
		uid = "rover_launch",
		type = "digital",
		description = "Jump",
		category = "Rover",
	}
	Roverjcon.fire1 = jcon.register{
		uid = "rover_fire1",
		type = "digital",
		description = "Fire 1",
		category = "Rover",
	}
	Roverjcon.fire2 = jcon.register{
		uid = "rover_fire2",
		type = "digital",
		description = "Fire 2",
		category = "Rover",
	}
	
end

hook.Add("JoystickInitialize","RoverJoystickControl",RoverJoystickControl)

function ENT:Think()
	if self.Pod and self.Pod:IsValid() then
		self.CPL = self.Pod:GetPassenger()
		if (self.CPL && self.CPL:IsValid()) then
			local trace = {}
			trace.start = self.CPL:GetShootPos()
			trace.endpos = self.CPL:GetShootPos() + self.CPL:GetAimVector() * 10000
			trace.filter = self.Pod
			self.Pod.Trace = util.TraceLine( trace )
			self.Active = true
			
			if (self.CPL:KeyDown( IN_ATTACK ) || (joystick && joystick.Get(self.CPL, "rover_fire1"))) then
				for i = 1, self.HPC do
					local HPC = self.CPL:GetInfo( "SBHP_"..i )
					if self.HP[i]["Ent"] && self.HP[i]["Ent"]:IsValid() && (HPC == "1.00" || HPC == "1" || HPC == 1) then
						self.HP[i]["Ent"].Entity:HPFire()
					end
				end
			end
			
			if (self.CPL:KeyDown( IN_ATTACK2 ) || (joystick && joystick.Get(self.CPL, "rover_fire2"))) then
				for i = 1, self.HPC do
					local HPC = self.CPL:GetInfo( "SBHP_"..i.."a" )
					if self.HP[i]["Ent"] && self.HP[i]["Ent"]:IsValid() && (HPC == "1.00" || HPC == "1" || HPC == 1) then
						self.HP[i]["Ent"].Entity:HPFire()
					end
				end
			end
			
		else
			self.Speed = 0
			self.Yaw = 0
			self.Roll = 0
			self.Pitch = 0
			self.Pod.Trace = nil
		end
		
		if !self.Mounted then
			local mn, mx = self.Pod:WorldSpaceAABB()
			mn = mn - Vector(2, 2, 2)
			mx = mx + Vector(2, 2, 2)
			local T = ents.FindInBox(mn, mx)
			for _,i in pairs( T ) do
				if( i.Entity && i.Entity:IsValid() && i.Entity != self.Pod ) then
					if i.HasHardpoints then
						if i.Cont && i.Cont:IsValid() then HPLink( i.Cont, i.Entity, self.Pod ) end
						self.Mounted = true
						--self.Pod:SetParent()
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
	end
	if self.Pod.HPWeld && self.Pod.HPWeld:IsValid() then
		self.Pod.HPWeld:Remove()
		self.Pod.HPWeld = nil
	end
	self.Pod:SetParent()
	if self.Pod.Pod && self.Pod.Pod:IsValid() then
		self.Pod.Pod.Cont.HP[self.Pod.HPN]["Ent"] = nil
		local NC = constraint.NoCollide(self.Pod, self.Pod.Pod, 0, 0, 0, true)
	end
	local phys = self.Pod:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableGravity(true)
		phys:EnableDrag(true)
		phys:EnableCollisions(true)
	end
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
	info.wheels = {}
	for k,v in pairs(self.Wh) do
		if (v["Ent"]) and (v["Ent"]:IsValid()) then
			info.wheels[k] = v["Ent"]:EntIndex()
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
	if (info.wheels) then
		for k,v in pairs(info.wheels) do
			local gun = GetEntByID(v)
			self.Wh[k]["Ent"] = gun
			if (!self.Wh[k]["Ent"]) then
				gun = ents.GetByIndex(v)
				self.Wh[k]["Ent"] = gun
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
		ent2.APPos = Vector(-20,0,-86)
		ent2.APAng = Angle(0,0,180)
	end
	self.SPL = ply
end