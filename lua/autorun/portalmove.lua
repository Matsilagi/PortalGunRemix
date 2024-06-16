AddCSLuaFile()

local snd_portal2 = CreateClientConVar("portal_sound", "0", true, false)
local portal_prototype = CreateClientConVar("portal_prototype", "1", true, false)
local lastfootstep = 1
local lastfoot = 0
local function PlayFootstep(ply, level, pitch, volume)
	local sound = math.random(1, 4)
	while sound == lastfootstep do
		sound = math.random(1, 4)
	end

	lastfoot = lastfoot == 0 and 1 or 0
	local filter = SERVER and RecipientFilter():AddPVS(ply:GetPos()) or nil
	if GAMEMODE:PlayerFootstep(ply, ply:GetPos(), lastfoot, "player/footsteps/concrete" .. sound .. ".wav", .6, filter) then return end
	ply:EmitSound("player/footsteps/concrete" .. sound .. ".wav", level, pitch, volume, CHAN_BODY)
end

local function SubAxis(v, x)
	return v - (v:Dot(x) * x)
end

local function IsInFront(posA, posB, normal)
	local Vec1 = (posB - posA):GetNormalized()
	return normal:Dot(Vec1) < 0
end

local sv_gravity = GetConVar("sv_gravity")
local nextFootStepTime = CurTime()
hook.Add("Move", "hpdMoveHook", function(ply, mv)
	local portal = ply.InPortal
	if IsValid(portal) and ply:GetMoveType() == MOVETYPE_NOCLIP then --and IsInFront( ply:EyePos(), ply.InPortal:GetPos(), ply.InPortal:GetForward() ) then
		local deltaTime = FrameTime()
		local curTime = CurTime()
		local noclipSpeed = 1.75
		local noclipAccelerate = 5
		local pos = mv:GetOrigin()
		local pOrg = portal:GetPos()

		if portal:OnFloor() then pOrg = pOrg - Vector(0, 0, 20) end
		local pAng = portal:GetAngles()
		-- calculate acceleration for this frame.
		local ang = mv:GetMoveAngles()
		local acceleration = ang:Right() * mv:GetSideSpeed()
		local forward = (ang + Angle(0, 90, 0)):Right()
		acceleration = acceleration + forward * mv:GetForwardSpeed()
		-- acceleration.z = 0
		-- clamp to our max speed, and take into account noclip speed
		local flPlayerMoveSpeed = ply:GetWalkSpeed()
		if mv:KeyDown(IN_SPEED) then
			flPlayerMoveSpeed = ply:GetRunSpeed()
		elseif mv:KeyDown(IN_WALK) then
			flPlayerMoveSpeed = ply:GetSlowWalkSpeed()
		end

		if mv:KeyDown(IN_DUCK) then
			flPlayerMoveSpeed = flPlayerMoveSpeed * ply:GetCrouchedWalkSpeed()
		end

		local accelSpeed = math.min(acceleration:Length2D(), flPlayerMoveSpeed)

		--print("SPEED", accelSpeed, ply:GetGroundEntity())
		local accelDir = acceleration:GetNormal()
		acceleration = accelDir * accelSpeed-- * noclipSpeed
		if (accelSpeed > 0) and (pos.z <= pOrg.z - 55) then
			if curTime > nextFootStepTime then
				nextFootStepTime = curTime + .4
				PlayFootstep(ply, 50, 100, .4)
			end
		end

		--TODO: Gonna calculate these at some point.
		-- local plyHeight = 72 --Player height
		-- local bot, top = pOrg - pAng:Up()*55, pOrg + pAng:Up()*55 --bottom and top points of the portal
		-- local portHeight = math.abs(top.z-bot.z) --isometric portal height
		-- local gap = math.abs(portHeight-plyHeight) --max height difference
		-- local minZ, maxZ = -(portHeight/2), -(portHeight/2) + gap
		-- print(portHeight)
		-- print(minZ,maxZ)
		--Add gravity.
		local gravity = Vector(0, 0, 0)
		local g = sv_gravity:GetFloat()
		if portal:IsHorizontal() then
			if pos.z > pOrg.z - 54 then gravity.z = -g end
		else
			gravity.z = -g
		end

		-- calculate final velocity with friction
		local getvel = mv:GetVelocity()
		local newVelocity = getvel + acceleration * deltaTime * noclipAccelerate
		newVelocity = newVelocity + (gravity * deltaTime)
		newVelocity.z = math.max(newVelocity.z, -3000) --Clamp that fall speed. 
		newVelocity.z = newVelocity.z * .9999 --Correct incrementing zvelocity
		newVelocity.x = newVelocity.x * (0.98 - deltaTime * 5)
		newVelocity.y = newVelocity.y * (0.98 - deltaTime * 5)
		if mv:KeyDown(IN_JUMP) and not mv:KeyWasDown(IN_JUMP) and portal:IsHorizontal() then
			if portal:WorldToLocal(pos).z <= -54 then
				newVelocity.z = ply:GetJumpPower()
				GAMEMODE:DoAnimationEvent(ply, PLAYERANIMEVENT_JUMP)
				PlayFootstep(ply, 40, 100, .6)
			end
		end

		local frontDist
		if portal:IsHorizontal() then --Fix diagonal portal with OBB detection.
			local OBBPos = util.ClosestPointInOBB(pOrg, ply:OBBMins(), ply:OBBMaxs(), ply:GetPos(), false)
			frontDist = OBBPos:PlaneDistance(pOrg, pAng:Forward())
		else
			frontDist = math.min(pos:PlaneDistance(pOrg, pAng:Forward()), ply:GetHeadPos():PlaneDistance(pOrg, pAng:Forward()))
		end

		local localOrigin = portal:WorldToLocal(pos + newVelocity * deltaTime) --Apply movement, localize before clamping.
		local minY, maxY, minZ, maxZ
		if portal:IsHorizontal() then
			minY = -20
			maxY = 20
			minZ = -55
			maxZ = -14
		else
			minY = -20
			maxY = 20
			minZ = -50
			maxZ = 44
		end

		if not portal_prototype:GetBool() then
			frontNum = 16
		else
			frontNum = 32
		end

		if frontDist < frontNum then
			-- if frontDist < 25.29 then
			localOrigin.z = math.Clamp(localOrigin.z, minZ, maxZ)
			localOrigin.y = math.Clamp(localOrigin.y, minY, maxY)
		else
			ply:SetGroundEntity(ply.InPortal)
			--print("WHEN", ply, ply:GetGroundEntity(), ply.InPortal, ply.InPortal:GetOther())
			--			ply.PortalClone:Remove() Error Lua in Multiplayer
			ply.PortalClone = nil
			--ply.InPortal = nil

			-- Fixed Portals Roofs
			ply:SetMoveType(MOVETYPE_FLY)
			-- print("MOVETYPE_FLY")

			timer.Create( "Walk", 0.075, 1, function()
				ply:SetMoveType(MOVETYPE_WALK)
				ply:ResetHull()
				-- print("MOVETYPE_WALK")
			end)

			if not snd_portal2:GetBool() then
				ply:EmitSound("player/portal_exit" .. math.random(1, 2) .. ".wav", 80, 100 + (30 * (newVelocity:Length() - 450) / 1000))
			else
				ply:EmitSound("player/portal2/portal_exit" .. math.random(1, 2) .. ".wav", 80, 100 + (30 * (newVelocity:Length() - 450) / 1000))
			end
		end

		debugoverlay.Box(portal:LocalToWorld(localOrigin), Vector(-16, -16, 0), Vector(16, 16, 64), 0.1, Color(255, 0, 0, 16))

		local newOrigin = portal:LocalToWorld(localOrigin)
		-- Apply our velocity change
		mv:SetVelocity(newVelocity)
		--Move the player by the velocity.
		mv:SetOrigin(newOrigin)
		return true
	end
end)
local vec = FindMetaTable("Vector")
function vec:PlaneDistance(plane, normal)
	return normal:Dot(self - plane)
end

function math.YawBetweenPoints(a, b)
	local xDiff = a.x - b.x
	local yDiff = a.y - b.y
	return math.atan2(yDiff, xDiff) * (180 / math.pi)
end

-- Returns the distance between a point and an OBB, defined by mins and maxs.
-- If a center is given, it will return a distance within the OBB if the point is within the OBB.
--	Works in 2 dimensions. Ignores Z of target and center.
-- Also only works with player OBB's so far. Derp.
function util.ClosestPointInOBB(point, mins, maxs, center, Debug)
	-- local yaw = ply:GetRight():Angle().y+90
	local Debug = Debug or false
	local yaw = math.rad(math.YawBetweenPoints(point, center))
	local radius
	local abs_cos_angle = math.abs(math.cos(yaw))
	local abs_sin_angle = math.abs(math.sin(yaw))
	if 16 * abs_sin_angle <= 16 * abs_cos_angle then
		radius = 16 / abs_cos_angle
	else
		radius = 16 / abs_sin_angle
	end

	radius = math.min(radius, math.Distance(center.x, center.y, point.x, point.y))
	local x, y = math.cos(yaw) * radius, math.sin(yaw) * radius
	if Debug then
		if not CLIENT then
			umsg.Start("drawOBB")
			umsg.Vector(point)
			umsg.Vector(mins)
			umsg.Vector(maxs)
			umsg.Vector(center)
			umsg.End()
		else
			debugoverlay.Box(center, mins, maxs, FrameTime() + .01, Color(200, 30, 30, 0))
			debugoverlay.Line(center + Vector(0, 0, 0), center + Vector(x, y, 0), FrameTime() + .01, Color(200, 30, 30, 255))
			debugoverlay.Cross(center + Vector(x, y, 0), 2, 1, Color(300, 200, 30, 255))
			debugoverlay.Cross(point, 5, 1, Color(30, 200, 30, 255))
		end
	end
	return Vector(x, y, 0) + center
end

-- local lastStep = CurTime() 
-- hook.Add("PlayerFootstep", "Debug", function(ply,pos,foot,sound,volume,filter)
-- local delay = CurTime()-lastStep
-- lastStep = CurTime()
-- local speed = ply:GetVelocity():Length()
-- print("Sound: ",sound.."\nVolume: ",volume.."\nSpeed: ",speed.."\nDelay: ",delay.."\n\n")
-- end)

if SERVER then
	hook.Add( "PreCleanupMap", "Remove portals individually", function()
		for k, v in pairs(ents.FindByClass("prop_portal")) do
			v:CleanMeUp()
		end
	end)

	hook.Add("DoPlayerDeath", "Remove Portals On Death", function(victim)
		local blueportal = victim:GetNWEntity("Portal:Blue")
		local orangeportal = victim:GetNWEntity("Portal:Orange")
		for k, v in ipairs(ents.FindByClass("prop_portal")) do
			if v == blueportal or v == orangeportal and v.CleanMeUp then v:CleanMeUp() end
		end
	end)
else
	usermessage.Hook( "drawOBB", function(umsg)
		local point, mins, maxs, center = umsg:ReadVector(), umsg:ReadVector(), umsg:ReadVector(), umsg:ReadVector()
		util.ClosestPointInOBB(point, mins, maxs, center, true)
	end)
end