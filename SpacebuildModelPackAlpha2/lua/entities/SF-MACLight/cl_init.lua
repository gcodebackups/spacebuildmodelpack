
include('shared.lua')
--killicon.AddFont("seeker_missile", "CSKillIcons", "C", Color(255,80,0,255))


function ENT:Initialize()

end

function ENT:Draw()
	
	self.Entity:DrawModel()

end

function ENT:Think()

	local dlight = DynamicLight( 0 )
	if ( dlight ) then
		--local r, g, b, a = self:GetColor()
		dlight.Pos = self:GetPos() + (self.Entity:GetForward() * 160) + (self.Entity:GetUp() * 30) 
		dlight.r = 50
		dlight.g = 50
		dlight.b = 200
		dlight.Brightness = self:GetBrightness()
		dlight.Decay = 900 * 5
		dlight.Size = 900
		dlight.DieTime = CurTime() + 0.2
	end
	
	local dlight = DynamicLight( 0 )
	if ( dlight ) then
		--local r, g, b, a = self:GetColor()
		dlight.Pos = self:GetPos() + (self.Entity:GetForward() * 175) + (self.Entity:GetUp() * -20) 
		dlight.r = 50
		dlight.g = 50
		dlight.b = 200
		dlight.Brightness = self:GetBrightness()
		dlight.Decay = 900 * 5
		dlight.Size = 900
		dlight.DieTime = CurTime() + 0.2
	end
	
	local Charging = self.Entity:GetNetworkedBool( "Charging" ) or false
	local Charge = self.Entity:GetNetworkedInt("Charge") or 0
	self.WInfo = "Light MAC - "..(Charging and "" or "Not ").."Charging, Charge:"..Charge
	self.Entity:NextThink( CurTime() + 0.1 ) 
	return true
end