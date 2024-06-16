TYPE_BLUE = 1
TYPE_ORANGE = 2

ENT.Type = "anim"

ENT.PrintName = "Portal"
ENT.Author = "CnicK / Bobblehead"
ENT.Contact = ""
ENT.Purpose = "A portal"
ENT.Instructions = "Spawn portals. Look through portals. Enter portals!"

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

ENT.Spawnable			= false
ENT.AdminSpawnable		= false


local Plymeta = FindMetaTable("Player")
function Plymeta:SetHeadPos(v)
	v.z = v.z-64
	self:SetPos(v)
end
function Plymeta:GetHeadPos(v)
	-- local r = self:GetPos(v)
	-- r.z = r.z+64
	return self:EyePos()
end

local function IsBehind( posA, posB, normal )
	local Vec1 = ( posB - posA )
	Vec1:Normalize()

	return normal:Dot( Vec1 ) < 0
end


--Mahalis code..
function ENT:TransformOffset(v,a1,a2)
	return (v:Dot(a1:Right()) * a2:Right() + v:Dot(a1:Up()) * (-a2:Up()) + v:Dot(a1:Forward()) * a2:Forward())
end

function ENT:GetPortalAngleOffsets(portal,ent)
	local angles = ent:GetAngles()

	local normal = self:GetForward()
	local forward = angles:Forward()
	local up = angles:Up()

	-- reflect forward
	local dot = forward:DotProduct( normal )
	forward = forward + ( -2 * dot ) * normal

	-- reflect up		
	local dot = up:DotProduct( normal )
	up = up + ( -2 * dot ) * normal

	-- convert to angles
	angles = math.VectorAngles( forward, up )

	local LocalAngles = self:WorldToLocalAngles( angles )

	-- repair
	LocalAngles.y = -LocalAngles.y
	LocalAngles.r = -LocalAngles.r

	return portal:LocalToWorldAngles( LocalAngles )
end

function ENT:GetPortalPosOffsets(portal,ent)
	local pos
	if ent:IsPlayer() then 
		pos = ent:GetHeadPos() 
	else 
		pos = ent:GetPos()
	end
	local offset = self:WorldToLocal(pos)
	if ent:IsPlayer() then 
		offset.x = -offset.x
		offset.y = -offset.y
	else 
		offset.x = -offset.x
		offset.y = -offset.y
	end
	
	local output = portal:LocalToWorld( offset )
	if ent:IsPlayer() and SERVER then
		return output + self:GetFloorOffset(output)
	else
		return output
	end
end

function ENT:PlayerWithinBounds(ent,predicting)
	local offset = Vector(0,0,0)
	if predicting then offset = ent:GetVelocity()*FrameTime() end
	
	local pOrg = self:GetPos()
	if self:OnFloor() then
		self:SetPos(pOrg - Vector(0,0,20))
		pOrg = pOrg - Vector(0,0,20)
		offset = Vector(0,0,0)
	end
	
	local plyPos = self:WorldToLocal(ent:GetPos()+offset)
	local headPos = self:WorldToLocal(ent:GetHeadPos()+offset)
	local frontDist
	if self:IsHorizontal() then
		local OBBPos = util.ClosestPointInOBB(pOrg,ent:OBBMins(),ent:OBBMaxs(),ent:GetPos()+offset,false)
		frontDist = OBBPos:PlaneDistance(pOrg,self:GetForward())
	else
		frontDist = math.min((ent:GetPos()+offset):PlaneDistance(self:GetPos(),self:GetForward()), (ent:GetHeadPos()+offset):PlaneDistance(self:GetPos(),self:GetForward()))
	end
	
	if self:OnFloor() then
		self:SetPos(pOrg + Vector(0,0,20))
	end
	
	if frontDist > 32 then 
		return false 
	end
	if self:IsHorizontal() then
	--[[Check if the player is actually within the bounds of the portal.
		Player's feet and head must be in the portal to enter.
		portal dimensions: 64 wide, 104 tall]]
		
		--must be in the portal.
		
		
		if headPos.z > 52 then return false end
		-- print("Head is in Z.")
		if (ent:OnGround() and plyPos.z+ent:GetStepSize() or plyPos.z) < -52 then return false end
		-- print("Feet are in Z.")
		if plyPos.y > 17 then return false end
		-- print("Left is in x")
		if plyPos.y < -17 then return false end
		-- print("Right is in x")
	else
		--must be in the portal.
		
		if plyPos.z > 44 then return false end
		if plyPos.z < -44 then return false end
		if plyPos.y > 20 then return false end
		if plyPos.y < -20 then return false end
		
	end
	return true
end

function ENT:SetType( int )
	self:SetNWInt("Potal:PortalType",int)
	self.PortalType = int

	if self.Activated == true then
		if SERVER then
			self:SetUpEffects(int)
		end
	end
end

function ENT:IsLinked()
	return self:GetNWBool("Potal:Linked", false)
end

function ENT:GetOther()
	return self:GetNWEntity("Potal:Other",NULL)
end

function ENT:SetUpEffects(int)
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Right(),-90)
	ang:RotateAroundAxis(ang:Forward(),0)
	ang:RotateAroundAxis(ang:Up(),90)

	local pos = self:GetPos()
	if self:OnFloor() then pos.z = pos.z - 20 end

	local ent = ents.Create( "info_particle_system" )
	ent:SetPos(pos)
	ent:SetAngles(ang)

	if int == TYPE_BLUE then
		if GetConVarNumber("portal_color_1") >=14 then
			ent:SetKeyValue( "effect_name", "portal_gray_edge")
		elseif GetConVarNumber("portal_color_1") >=13 then
			ent:SetKeyValue( "effect_name", "portal_gray_edge")
		elseif GetConVarNumber("portal_color_1") >=12 then
			ent:SetKeyValue( "effect_name", "portal_gray_edge")
		elseif GetConVarNumber("portal_color_1") >=11 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pbody_reverse")
		elseif GetConVarNumber("portal_color_1") >=10 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pink_green_reverse")
		elseif GetConVarNumber("portal_color_1") >=9 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pink_green_reverse")
		elseif GetConVarNumber("portal_color_1") >=8 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_atlas_reverse")
		elseif GetConVarNumber("portal_color_1") >=7 then
			ent:SetKeyValue( "effect_name", "portal_1_edge")
		elseif GetConVarNumber("portal_color_1") >=6 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_atlas")
		elseif GetConVarNumber("portal_color_1") >=5 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pink_green")
		elseif GetConVarNumber("portal_color_1") >=4 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pink_green")
		elseif GetConVarNumber("portal_color_1") >=3 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pink_green")
		elseif GetConVarNumber("portal_color_1") >=2 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pbody")
		elseif GetConVarNumber("portal_color_1") >=1 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_reverse")
		else
			ent:SetKeyValue( "effect_name", "portal_1_edge_pbody_reverse")
		end
	elseif int == TYPE_ORANGE then
		if GetConVarNumber("portal_color_2") >=14 then
			ent:SetKeyValue( "effect_name", "portal_gray_edge_reverse")
		elseif GetConVarNumber("portal_color_2") >=13 then
			ent:SetKeyValue( "effect_name", "portal_gray_edge_reverse")
		elseif GetConVarNumber("portal_color_2") >=12 then
			ent:SetKeyValue( "effect_name", "portal_gray_edge_reverse")
		elseif GetConVarNumber("portal_color_2") >=11 then
			ent:SetKeyValue( "effect_name", "portal_2_edge_pbody")
		elseif GetConVarNumber("portal_color_2") >=10 then
			ent:SetKeyValue( "effect_name", "portal_2_edge_pink_green")
		elseif GetConVarNumber("portal_color_2") >=9 then
			ent:SetKeyValue( "effect_name", "portal_2_edge_pink_green")
		elseif GetConVarNumber("portal_color_2") >=8 then
			ent:SetKeyValue( "effect_name", "portal_2_edge_atlas")
		elseif GetConVarNumber("portal_color_2") >=7 then
			ent:SetKeyValue( "effect_name", "portal_2_edge_reverse")
		elseif GetConVarNumber("portal_color_2") >=6 then
			ent:SetKeyValue( "effect_name", "portal_2_edge_atlas_reverse")
		elseif GetConVarNumber("portal_color_2") >=5 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pink_green")
		elseif GetConVarNumber("portal_color_2") >=4 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pink_green")
		elseif GetConVarNumber("portal_color_2") >=3 then
			ent:SetKeyValue( "effect_name", "portal_1_edge_pink_green")
		elseif GetConVarNumber("portal_color_2") >=2 then
			ent:SetKeyValue( "effect_name", "portal_2_edge_pbody_reverse")
		elseif GetConVarNumber("portal_color_2") >=1 then
			ent:SetKeyValue( "effect_name", "portal_2_edge")
		else
			ent:SetKeyValue( "effect_name", "portal_2_edge_pbody")
		end
	end

	ent:SetKeyValue( "start_active", "1")
	ent:Spawn()
	ent:Activate()
	ent:SetParent(self)
	self.EdgeEffect = ent

	local ent = ents.Create( "info_particle_system" )
	ent:SetPos(pos)
	ent:SetAngles(ang)
	if int == TYPE_BLUE then
		if GetConVarNumber("portal_color_1") >=14 then
			ent:SetKeyValue( "effect_name", "portal_gray_vacuum")
		elseif GetConVarNumber("portal_color_1") >=13 then
			ent:SetKeyValue( "effect_name", "portal_gray_vacuum")
		elseif GetConVarNumber("portal_color_1") >=12 then
			ent:SetKeyValue( "effect_name", "portal_gray_vacuum")
		elseif GetConVarNumber("portal_color_1") >=11 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_1") >=10 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_1") >=9 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_1") >=8 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_atlas")
		elseif GetConVarNumber("portal_color_1") >=7 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum")
		elseif GetConVarNumber("portal_color_1") >=6 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_atlas")
		elseif GetConVarNumber("portal_color_1") >=5 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_1") >=4 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_1") >=3 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_1") >=2 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_pbody")
		elseif GetConVarNumber("portal_color_1") >=1 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum")
		else
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_pbody")
		end
	elseif int == TYPE_ORANGE then
		if GetConVarNumber("portal_color_2") >=14 then
			ent:SetKeyValue( "effect_name", "portal_gray_vacuum")
		elseif GetConVarNumber("portal_color_2") >=13 then
			ent:SetKeyValue( "effect_name", "portal_gray_vacuum")
		elseif GetConVarNumber("portal_color_2") >=12 then
			ent:SetKeyValue( "effect_name", "portal_gray_vacuum")
		elseif GetConVarNumber("portal_color_2") >=11 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_2") >=10 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_2") >=9 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_2") >=8 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_atlas")
		elseif GetConVarNumber("portal_color_2") >=7 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum")
		elseif GetConVarNumber("portal_color_2") >=6 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_atlas")
		elseif GetConVarNumber("portal_color_2") >=5 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_2") >=4 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_2") >=3 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_pink_green")
		elseif GetConVarNumber("portal_color_2") >=2 then
			ent:SetKeyValue( "effect_name", "portal_1_vacuum_pbody")
		elseif GetConVarNumber("portal_color_2") >=1 then
			ent:SetKeyValue( "effect_name", "portal_2_vacuum")
		else
			ent:SetKeyValue( "effect_name", "portal_2_vacuum_pbody")
		end
	end
	ent:SetKeyValue( "start_active", "1")
	ent:Spawn()
	ent:Activate()
	ent:SetParent(self)
	self.VacuumEffect = ent
end


--Returns best point to offset the player to prevent stucks.
function ENT:GetFloorOffset(pos1)
	local offset = Vector(0,0,0)
	local pos = Vector(0,0,0)
	pos:Set(pos1) --stupid pointers...
	
	pos.z = pos.z-64
	pos = self:WorldToLocal(pos)
	pos.x = pos.x+30
	for i=0,54 do
		local openspace = util.IsInWorld(self:LocalToWorld(pos+Vector(0,0,i)))
		if openspace then
			-- print("Found no floor at -"..i)
			-- umsg.Start("DebugOverlay_Cross")
				-- umsg.Vector(self:LocalToWorld(pos+offset))
				-- umsg.Bool(true)
			-- umsg.End()
			offset.z = i
			break
		else
			-- print("Found a floor at -"..i)
			-- umsg.Start("DebugOverlay_Cross")
				-- umsg.Vector(self:LocalToWorld(pos+offset))
				-- umsg.Bool(false)
			-- umsg.End()
		end
	end
	return offset
end

function ENT:GetOpposite() --Don't think this is being used..? Gets the portal type that it would need to be linked too
	if self.PortalType == TYPE_BLUE then
		return TYPE_ORANGE
	elseif self.PortalType == TYPE_ORANGE then
		return TYPE_BLUE
	end
end

function ENT:IsHorizontal()
	local p = math.Round(self:GetAngles().p)
	return p == 0
end
function ENT:OnFloor()
	local p = math.Round(self:GetAngles().p)
	return p == 0 and p == -90 -- Fixed Portals
end
function ENT:OnRoof()
	local p = math.Round(self:GetAngles().p)
	return p >= 0 and p <= 180 -- Fixed Portals
end

local function PlayerPickup( ply, ent )	
	if ent:GetClass() == "prop_portal" or ent:GetModel() == "models/blackops/portal_sides.mdl" then
		-- print("No Pickup.")
		return false
	end
	if ent:GetClass() == "prop_portal" or ent:GetModel() == "models/blackops/portal_sides_new.mdl" then
		-- print("No Pickup.")
		return false
	end
end
hook.Add( "PhysgunPickup", "NoPickupPortalssingleplayer", PlayerPickup )
hook.Add( "GravGunPickupAllowed", "NoPickupPortalssingleplayer", PlayerPickup )
hook.Add( "GravGunPunt", "NoPickupPortalssingleplayer", PlayerPickup )