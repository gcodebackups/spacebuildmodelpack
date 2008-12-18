AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

--util.PrecacheSound( "SB/SteamEngine.wav" )

function ENT:Initialize()
	
	self.Entity:SetModel( "models/Spacebuild/medbridge2_doublehull_elevatorclamp.mdl" ) 
	self.Entity:SetName("AssaultPod")
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
		phys:SetMass(20)
	end
	self.Entity:StartMotionController()
	self.PhysObj = self.Entity:GetPhysicsObject()


	self.Speed = 0
	self.TSpeed = 150
	self.Active = false
	self.Skewed = true
	
	self.HPC			= 1
	self.HP				= {}
	self.HP[1]			= {}
	self.HP[1]["Ent"]	= nil
	self.HP[1]["Type"]	= "Small"
	self.HP[1]["Pos"]	= Vector(-40,0,110)
	
	
end

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end
	
	
	local ent = ents.Create( "BoardingPod" )
	ent:SetPos( Vector( 100000,100000,100000 ) )
	ent:Spawn()
	ent:Initialize()
	ent:Activate()
	ent.SPL = ply
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16 + Vector(0,0,50)
	
	local ent2 = ents.Create( "prop_vehicle_prisoner_pod" )
	ent2:SetModel( "models/Slyfo/clunker.mdl" ) 
	ent2:SetPos( SpawnPos )
	ent2:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
	ent2:SetKeyValue("limitview", 0)
	ent2.HasHardpoints = true
	ent2:Spawn()
	ent2:Activate()
	local TB = ent2:GetTable()
	TB.HandleAnimation = function (vec, ply)
		return ply:SelectWeightedSequence( ACT_HL2MP_SIT ) 
	end 
	ent2:SetTable(TB)
	ent2.SPL = ply
	ent2:SetNetworkedInt( "HPC", ent.HPC )
	
	ent.Pod = ent2
	ent2.Cont = ent
	
	return ent
	
end

function ENT:Think()
	if self.Pod and self.Pod:IsValid() then
		self.CPL = self.Pod:GetPassenger()
		if (self.CPL && self.CPL:IsValid()) then
			if !self.CPL.CamCon then
				self.CPL.CamCon = true
				if !self.CamC || !self.CamC:IsValid() then
					self.CamC = ents.Create( "prop_physics" )
					self.CamC:SetModel( "models/props_junk/PopCan01a.mdl" )
					self.CamC:SetPos( self.Pod:GetPos() + self.Pod:GetUp() * 55 + self.Pod:GetForward() * 30 ) 
					self.CamC:SetAngles( self.Pod:GetAngles() )
					self.CamC:Spawn()
					--self.CamC:Initialize()
					self.CamC:Activate()
					self.CamC:SetParent( self.Pod )
					self.CamC:SetColor(0,0,0,1)
				end
				self.CPL:SetViewEntity( self.CamC )	
			end
			
			if (self.CPL:KeyDown( IN_JUMP )) then
				if !self.Active then
					self.Active = true
					
					self.RockTrail = ents.Create("env_rockettrail")
					self.RockTrail:SetAngles( self.Pod:GetAngles()  )
					self.RockTrail:SetPos( self.Pod:GetPos() + self.Pod:GetUp() * 55 + self.Pod:GetForward() * - 105 )
					self.RockTrail:SetParent(self.Pod)
					self.RockTrail:Spawn()
					self.RockTrail:Activate()
					
					self.ShakeIt = ents.Create( "env_shake" )
					self.ShakeIt:SetName("Shaker")
					self.ShakeIt:SetKeyValue("amplitude", "8" )
					self.ShakeIt:SetKeyValue("radius", "500" )
					self.ShakeIt:SetKeyValue("duration", "5" )
					self.ShakeIt:SetKeyValue("frequency", "255" )
					self.ShakeIt:SetPos( self.Pod:GetPos() + self.Pod:GetUp() * 55 )
					self.ShakeIt:Fire("StartShake", "", 0);
					self.ShakeIt:SetParent(self.Pod)
					self.ShakeIt:Spawn()
					self.ShakeIt:Activate()
				end
			end
			
			if self.Active then
				self.CPL:ViewPunch( Angle(10,10,0) )
			end
	
			if (self.CPL:KeyDown( IN_MOVERIGHT )) then
				self.Roll = self.TSpeed
			elseif (self.CPL:KeyDown( IN_MOVELEFT )) then
				self.Roll = -self.TSpeed
			else
				self.Roll = 0
			end
			
			self.Yaw = self.CPL.SBEPYaw * -0.01
			self.Pitch = self.CPL.SBEPPitch * 0.01
	
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
						
			
		else
			self.Yaw = 0
			self.Roll = 0
			self.Pitch = 0
		end
	else
		self.Entity:Remove()
	end
	
	if (self.Active && !self.Impact) then
				
		local physi = self.Pod:GetPhysicsObject()
		physi:SetVelocity( ( physi:GetVelocity() * 0.75 ) + ( self.Pod:GetRight() * 6000 ) )
		physi:AddAngleVelocity((physi:GetAngleVelocity() * -0.9) + Angle(self.Roll,self.Pitch,self.Yaw))
		physi:EnableGravity(false)
		
		local trace = {}
		trace.start = self.Pod:GetPos() + self.Pod:GetUp() * 55 + self.Pod:GetRight() * 80
		trace.endpos = self.Pod:GetPos() + self.Pod:GetUp() * 55 + self.Pod:GetRight() * 120
		trace.filter = self.Pod
		local tr = util.TraceLine( trace )
		if tr.HitNonWorld && tr.Entity && tr.Entity:IsValid() then
			self.Impact = true
			self.Active = false
			self.Pod:SetPos(self.Pod:GetPos() + self.Pod:GetRight() * 500)
			self.CPL:ExitVehicle()
			self.CPL:SetPos(self.Pod:GetPos() + self.Pod:GetUp() * 55 + self.Pod:GetRight() * 100)
			local Vel = self.Pod:GetPhysicsObject():GetVelocity()
			self.CPL:SetVelocity( Vel )
			
			self.Pod:Fire("kill", "", 20)
			self.RockTrail:Remove()
			local Weld = constraint.Weld(self.Pod, tr.Entity, 0, 0, 0, true)
		elseif tr.HitWorld then
			local Vel = self.Pod:GetPhysicsObject():GetVelocity()
			self.Pod:Remove()
			self.CPL:SetVelocity( Vel )
		end
	else
		--self.Speed = 0
		self.Yaw = 0
		self.Roll = 0
		self.Pitch = 0
		--local physi = self.Pod:GetPhysicsObject()
		--physi:EnableGravity(true)
	end

	self.Entity:NextThink( CurTime() + 0.01 ) 
	return true
end

function ENT:PhysicsCollide( data, physobj )

end

function ENT:OnTakeDamage( dmginfo )
	
end

function ENT:Touch( ent )

end

function ENT:OnRemove()
	if self.Pod:IsValid() then
		self.Pod:Remove()
	end
end