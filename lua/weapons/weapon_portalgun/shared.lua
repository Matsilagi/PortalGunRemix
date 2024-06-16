
TYPE_BLUE = 1
TYPE_ORANGE = 2

PORTAL_HEIGHT = 110
PORTAL_WIDTH = 68

local limitPickups = CreateConVar("portal_limitcarry", 0, {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE,FCVAR_REPLICATED}, "Whether to limit the Portalgun to pickup certain props from the Portal game.")
local cleanportals = CreateClientConVar("portal_cleanportals","1",true,false)
local hitentity = CreateClientConVar("portal_hitentity","0",true,false)
local hitprop = CreateClientConVar("portal_hitprop","0",true,false)
local allsurfaces = CreateClientConVar("portal_allsurfaces","0",true,false)
local location = CreateClientConVar("portal_location","1",true,false)
local snd_portal2 = CreateClientConVar("portal_sound","0",true,false)
local autoFSB = CreateClientConVar("portal_autoFSB","1",true,false)
local tryhard = CreateClientConVar("portal_tryhard","0",true,false)
local CarryAnim_P1 = CreateClientConVar("portal_carryanim_p1","0",true,false)

local ballSpeed, useInstant
if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	SWEP.Weight                     = 4
	SWEP.AutoSwitchTo               = false
	SWEP.AutoSwitchFrom             = false
	ballSpeed = CreateConVar("portal_projectile_speed", 3500, {FCVAR_ARCHIVE,FCVAR_REPLICATED,FCVAR_SERVER_CAN_EXECUTE}, "The speed that portal projectiles travel.")
	useInstant = CreateConVar("portal_instant", 0, {FCVAR_ARCHIVE,FCVAR_REPLICATED,FCVAR_SERVER_CAN_EXECUTE}, "Make portals create instantly and don't use the projectile.")
end

if ( CLIENT ) then
	SWEP.PrintName          = "Portal Gun"
	SWEP.Author             = "CnicK / Bobblehead / Matsilagi"
	SWEP.Contact            = "kaisd@mail.ru"
	SWEP.Purpose            = "Shoot Linked Portals"
	SWEP.ViewModelFOV       = "60"
	SWEP.Instructions       = ""
	SWEP.Slot = 0
	SWEP.Slotpos = 0
	SWEP.CSMuzzleFlashes    = false

	-- function SWEP:DrawWorldModel()
	--	if ( RENDERING_PORTAL or RENDERING_MIRROR or GetViewEntity() ~= LocalPlayer() ) then
	--		self:DrawModel()
	--	end
	-- end
end

SWEP.HoldType = "crossbow"

SWEP.EnableIdle = false

SWEP.AdminOnly = true
SWEP.HoldenProp			= false
SWEP.NextAllowedPickup	= 0
SWEP.UseReleased		= true
SWEP.PickupSound		= nil
local pickable 			= {
	"models/props/metal_box.mdl",
	"models/props/futbol.mdl",
	"models/props/sphere.mdl",
	"models/props/metal_box_fx_fizzler.mdl",
	"models/props/turret_01.mdl",
	"models/props/reflection_cube.mdl",
	"npc_turret_floor",
	"npc_manhack",
	"models/props/radio_reference.mdl",
	"models/props/security_camera.mdl",
	"models/props/security_camera_prop_reference.mdl",
	"models/props_bts/bts_chair.mdl",
	"models/props_bts/bts_clipboard.mdl",
	"models/props_underground/underground_weighted_cube.mdl",
	"models/XQM/panel360.mdl",
	"models/props_bts/glados_ball_reference.mdl"
}

SWEP.Category = "Other"

SWEP.Spawnable                  = true
SWEP.AdminSpawnable             = true

SWEP.ViewModel                  = "models/weapons/portalgun/c_portalgun.mdl"
SWEP.WorldModel                 = "models/weapons/portalgun/w_portalgun.mdl"

if not hitprop:GetBool() then
	SWEP.UseHands			= true
else
	SWEP.UseHands			= false
end

SWEP.ViewModelFlip              = false

SWEP.Drawammo = false
SWEP.DrawCrosshair = true

SWEP.Delay                      = .5

SWEP.Primary.ClipSize           = -1
SWEP.Primary.DefaultClip        = -1
SWEP.Primary.Automatic          = true
SWEP.Primary.Ammo                       = "none"

SWEP.Secondary.ClipSize         = -1
SWEP.Secondary.DefaultClip      = -1
SWEP.Secondary.Automatic        = true
SWEP.Secondary.Ammo                     = "none"

SWEP.HasOrangePortal = false
SWEP.HasBluePortal = false

SWEP.AnimPrefix		= "crossbow"

SWEP.Holster_Fire				= false
SWEP.SoonestAttack	= 0

SWEP.LastAttackTime			= 0.0
SWEP.viewPunch					= Angle( 0, 0, 0 )

SWEP.Primary.FastestDelay	= .17

SWEP.BobScale = 0
SWEP.SwayScale = 0

BobTime = 0
BobTimeLast = CurTime()

SwayAng = nil
SwayOldAng = Angle()
SwayDelta = Angle()

function SWEP:GetBulletSpread()

end

/*---------------------------------------------------------
   Name: SWEP:Initialize( )
   Desc: Called when the weapon is first loaded
---------------------------------------------------------*/
function SWEP:Initialize()
	local owner = self:GetOwner()

	self:SetNetworkedInt("LastPortal",0,true)
	self:SetWeaponHoldType( self.HoldType )

	if CLIENT then
		-- Create a new table for every weapon instance
		self.VElements = table.FullCopy( VElements )
		self.WElements = table.FullCopy( WElements )

		-- init view model bone build function
		if owner:IsValid() then
			local vm = owner:GetViewModel()
			if vm:IsValid() then
				self:ResetBonePositions(vm)
			end
		end
	end
end

if SERVER then
	util.AddNetworkString( "PORTALGUN_PICKUP_PROP" )

	hook.Add( "AllowPlayerPickup", "PortalPickup", function( ply, ent )
		if IsValid( ply:GetActiveWeapon() ) and IsValid( ent ) and ply:GetActiveWeapon():GetClass() == "weapon_portalgun" then --and (table.HasValue( pickable, ent:GetModel() ) or table.HasValue( pickable, ent:GetClass() )) then
			return false
		end
	end)
end

hook.Add("Think", "Portalgun Holding Item", function()
	for k,v in pairs(player.GetAll())do
		if v:KeyDown(IN_USE) then
			if v:GetActiveWeapon().NextAllowedPickup and v:GetActiveWeapon().NextAllowedPickup < CurTime() then
				if v:GetActiveWeapon().UseReleased then
					v:GetActiveWeapon().UseReleased = false
					if IsValid( v:GetActiveWeapon().HoldenProp ) then
						v:GetActiveWeapon():OnDroppedProp()
					end
				end
			end
		else
			v:GetActiveWeapon().UseReleased = true
		end
	end
end)

function SWEP:Think()
	if not tryhard:GetBool() then
		self.Holster_Fire = true
	else
		self.Holster_Fire = false
	end

	if autoFSB:GetBool() then
		RunConsoleCommand("portal_texFSB", "0")
	end

	local owner = self:GetOwner()

	-- HOLDING FUNC
	if SERVER then
		if IsValid(self.HoldenProp) and (not self.HoldenProp:IsPlayerHolding() or self.HoldenProp.Holder ~= owner) then
			self:OnDroppedProp()
		elseif self.HoldenProp and not IsValid(self.HoldenProp) then
			self:OnDroppedProp()
		end

		if owner:KeyDown( IN_USE ) and self.UseReleased then
			self.UseReleased = false
			if self.NextAllowedPickup < CurTime() and not IsValid(self.HoldenProp) then
				self.NextAllowedPickup = CurTime() + 0.4

				local tr = util.TraceLine( {
					start = owner:EyePos(),
					endpos = owner:EyePos() + owner:GetForward() * 150,
					filter = owner
				})

				--PICKUP FUNC
				if IsValid( tr.Entity ) then
					if tr.Entity.isClone then tr.Entity = tr.Entity.daddyEnt end
					local entsize = ( tr.Entity:OBBMaxs() - tr.Entity:OBBMins() ):Length() / 2
					if entsize > 45 then return end
					if not IsValid( self.HoldenProp ) and tr.Entity:GetMoveType() ~= 2 then
						if not self:PickupProp( tr.Entity ) then
							-- ?
						end
					end
				end

				--TODO: PICKUP THROUGH PORTAL FUNC
			end
		end
	end

	if CLIENT and self.EnableIdle then return end
	if self.idledelay and CurTime() > self.idledelay then
		self.idledelay = nil
		self:SendWeaponAnim(ACT_VM_IDLE)
	end

	if owner:IsValid() then
		return
	end

	if not owner:KeyDown( IN_ATTACK ) and not owner:KeyDown( IN_ATTACK2 ) and self.SoonestAttack < CurTime() and not self.Holster_Fire then
		self:SetNextPrimaryFire( CurTime() - .5 )
		self:SetNextSecondaryFire( CurTime() - .5 )
	end
end

function SWEP:PickupProp( ent )
	local owner = self:GetOwner()

	if not limitPickups:GetBool() or ( table.HasValue( pickable, ent:GetModel() ) or table.HasValue( pickable, ent:GetClass() ) ) then
		if owner:GetGroundEntity() == ent then return false end

		--Take it from other players.
		if ent:IsPlayerHolding() and ent.Holder and ent.Holder:IsValid() then
			ent.Holder:GetActiveWeapon():OnDroppedProp()
		end

		self.HoldenProp = ent
		ent.Holder = owner

		--Rotate it first
		local angOffset = owner:GetPreferredCarryAngles(ent) --hook.Call("GetPreferredCarryAngles",GAMEMODE,ent) 
		if angOffset then
			ent:SetAngles(owner:EyeAngles() + angOffset)
		end

		--Pick it up.
		owner:PickupObject(ent)

		self:SendWeaponAnim( ACT_VM_DEPLOY )

		if SERVER then
			net.Start( "PORTALGUN_PICKUP_PROP" )
				net.WriteEntity( self )
				net.WriteEntity( ent )
			net.Send( owner )
		end
		return true
	end
	return false
end

function SWEP:OnDroppedProp()

end


function SWEP:GetViewModelPosition( pos, ang )
	self.SwayScale  = self.RunSway
	self.BobScale   = self.RunBob

	return pos, ang
end

local function VectorAngle( vec1, vec2 ) -- Returns the angle between two vectors
	local costheta = vec1:Dot( vec2 ) / ( vec1:Length() *  vec2:Length() )
	return math.deg( math.acos( costheta ) )
end

function SWEP:MakeTrace( start, off, normAng )
	local owner = self:GetOwner()

	local tr = util.TraceLine({
		start = start,
		endpos = start + off,
		filter = owner,
		mask = MASK_SOLID_BRUSHONLY,
	})

	if not tr.Hit then
		local newPos = start + off
		local tr2 = util.TraceLine({
			start = newPos,
			endpos = newPos + normAng:Forward() * -2,
			filter = owner,
			mask = MASK_SOLID_BRUSHONLY,

			--output = tr
		})

		if not tr2.Hit then
			local tr3 = util.TraceLine({
				start = start + off + normAng:Forward() * -2,
				endpos = start + normAng:Forward() * -2,
				filter = owner,
				mask = MASK_SOLID_BRUSHONLY,

				--output = tr
			})

			if tr3.Hit then
				tr.Hit = true
				tr.Fraction = 1 - tr3.Fraction
			end
		end
	end

	return tr
end

function SWEP:IsPosionValid( pos, normal, minwallhits, dosecondcheck )
	local owner = self:GetOwner()

	local noPortal = false
	local normAng = normal:Angle()
	local BetterPos = pos

	local elevationangle = VectorAngle( vector_up, normal )

	if elevationangle <= 15 or ( elevationangle >= 175 and elevationangle <= 185 )  then --If the degree of elevation is less than 15 degrees, use the players yaw to place the portal
		normAng.y = owner:EyeAngles().y + 180
	end

	local VHits = 0
	local HHits = 0

	if not location:GetBool() then
		local tr = self:MakeTrace( pos, normAng:Up() * -PORTAL_HEIGHT * 0, normAng )

		if tr.Hit then -- Down
			local length = tr.Fraction * -PORTAL_HEIGHT * 0
			BetterPos = BetterPos + normAng:Up() * ( length + ( PORTAL_HEIGHT * 0 ) )
			VHits = VHits + 1
		end

		local tr = self:MakeTrace( pos, normAng:Up() * PORTAL_HEIGHT * 0, normAng )

		if tr.Hit then -- Up
			local length = tr.Fraction * PORTAL_HEIGHT * 0
			BetterPos = BetterPos + normAng:Up() * ( length - ( PORTAL_HEIGHT * 0 ) )
			VHits = VHits + 1
		end

		local tr = self:MakeTrace( pos, normAng:Right() * -PORTAL_WIDTH * 0, normAng )

		if tr.Hit then -- Right
			local length = tr.Fraction * -PORTAL_WIDTH * 0
			BetterPos = BetterPos + normAng:Right() * ( length + ( PORTAL_WIDTH * 0 ) )
			HHits = HHits + 1
		end

		local tr = self:MakeTrace( pos, normAng:Right() * PORTAL_WIDTH * 0, normAng )

		if tr.Hit then -- Left
			local length = tr.Fraction * PORTAL_WIDTH * 0
			BetterPos = BetterPos + normAng:Right() * ( length - ( PORTAL_WIDTH * 0 ) )
			HHits = HHits + 1
		end
	else
		local tr = self:MakeTrace( pos, normAng:Up() * -PORTAL_HEIGHT * 0.5, normAng )

		if tr.Hit then -- Down
			local length = tr.Fraction * -PORTAL_HEIGHT * 0.5
			BetterPos = BetterPos + normAng:Up() * ( length + ( PORTAL_HEIGHT * 0.533 ) )
			VHits = VHits + 1
		end

		local tr = self:MakeTrace( pos, normAng:Up() * PORTAL_HEIGHT * 0.5, normAng )

		if tr.Hit then -- Up
			local length = tr.Fraction * PORTAL_HEIGHT * 0.5
			BetterPos = BetterPos + normAng:Up() * ( length - ( PORTAL_HEIGHT * 0.52 ) )
			VHits = VHits + 1
		end

		local tr = self:MakeTrace( pos, normAng:Right() * -PORTAL_WIDTH * 0.5, normAng )

		if tr.Hit then -- Right
			local length = tr.Fraction * -PORTAL_WIDTH * 0.5
			BetterPos = BetterPos + normAng:Right() * ( length + ( PORTAL_WIDTH * 0.5 ) )
			HHits = HHits + 1
		end

		local tr = self:MakeTrace( pos, normAng:Right() * PORTAL_WIDTH * 0.5, normAng )

		if tr.Hit then -- Left
			local length = tr.Fraction * PORTAL_WIDTH * 0.5
			BetterPos = BetterPos + normAng:Right() * ( length - ( PORTAL_WIDTH * 0.5 ) )
			HHits = HHits + 1
		end
	end

	if dosecondcheck then
		return self:IsPosionValid( BetterPos, normal, 2, false )
	elseif ( HHits >= minwallhits or VHits >= minwallhits ) then
		return false, false
	else
		return BetterPos, normAng
	end
end

function SWEP:ShootBall(type,startpos,endpos,dir)
	local proj = ents.Create("projectile_portal_ball")
	local origin = startpos -Vector(0,0,10) + self:GetOwner():GetRight() * 8 -- +dir*100

	proj:SetPos(origin)
	proj:SetAngles(dir:Angle())
	proj:SetGun(self)
	proj:SetEffects(type)
	proj:Spawn()
	proj:Activate()
	proj:SetOwner(self:GetOwner())

	if not useInstant:GetBool() then
		speed = ballSpeed:GetInt()
	else
		speed = 75 * 2500
	end

	local phys = proj:GetPhysicsObject()
	if phys:IsValid() then
		phys:ApplyForceCenter((endpos-origin):GetNormal() * speed)
	end

	return proj
end

function SWEP:ShootPortal( type )

	self:SetNextPrimaryFire( CurTime() + self.Delay )
	self:SetNextSecondaryFire( CurTime() + self.Delay )

	local owner = self:GetOwner()

	local OrangePortalEnt = owner:GetNWEntity( "Portal:Orange", nil )
	local BluePortalEnt = owner:GetNWEntity( "Portal:Blue", nil )

	local EntToUse = type == TYPE_BLUE and BluePortalEnt or OrangePortalEnt
	local OtherEnt = type == TYPE_BLUE and OrangePortalEnt or BluePortalEnt

	local tr = {
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + ( owner:GetAimVector() * 2048 * 1000 ),
		filter = { owner, EntToUse, EntToUse.Sides },
		mask = MASK_SHOT,
	}

	if not hitprop:GetBool() then
		for k,v in pairs(ents.FindByClass( "prop_physics" )) do
			table.insert( tr.filter, v )
		end
	else
		--
	end

	for k,v in pairs( ents.FindByClass( "npc_turret_floor" ) ) do
		table.insert( tr.filter, v )
	end

	local trace = util.TraceLine( tr )

	--shoot a ball.
	if SERVER and IsFirstTimePredicted() and owner:IsValid() then --Predict that motha' fucka'
		local ball = self:ShootBall(type,tr.start,tr.endpos,trace.Normal)

		if not hitentity:GetBool() then 
			HitSelection = ( trace.Hit and trace.HitWorld )
		else
			HitSelection = ( trace.Hit or trace.HitWorld )
		end

		if HitSelection then
			if not useInstant:GetBool() then
				hitDelay_Instant = ((trace.Fraction * 2048 * 1000))/ballSpeed:GetInt()
			else
				hitDelay_Instant = 0
			end

			if not allsurfaces:GetBool() then 
				All_Surfaces = ( not trace.HitNoDraw and not trace.HitSky and ( trace.MatType ~= MAT_METAL and trace.MatType ~= MAT_GLASS or ( trace.MatType == MAT_CONCRETE or trace.MatType == MAT_DIRT ) ) )
			else
				All_Surfaces = 0
			end

			hitDelay = ((trace.Fraction * 2048 * 1000)) / ballSpeed:GetInt()

			local validpos, validnormang = self:IsPosionValid( trace.HitPos, trace.HitNormal, 2, true )

			timer.Simple( hitDelay, function()
				if ball and ball:IsValid() then 
					ball:Remove()

				end
			end )

			if All_Surfaces and validpos and validnormang then
				--Wait until our ball lands, if it's enabled.

				timer.Simple( hitDelay_Instant, function()
					if ball and ball:IsValid() then
						local OrangePortalEnt = owner:GetNWEntity( "Portal:Orange", nil )
						local BluePortalEnt = owner:GetNWEntity( "Portal:Blue", nil )

						local EntToUse = type == TYPE_BLUE and BluePortalEnt or OrangePortalEnt
						local OtherEnt = type == TYPE_BLUE and OrangePortalEnt or BluePortalEnt
						if not IsValid( EntToUse ) then
							local Portal = ents.Create( "prop_portal" )
							Portal:SetPos( validpos )
							Portal:SetAngles( validnormang )
							Portal:Spawn()
							Portal:Activate()
							Portal:SetMoveType( MOVETYPE_NONE )
							Portal:SetActivatedState(true)
							Portal:SetType( type )
							Portal:SuccessEffect()

							if type == TYPE_BLUE then
								owner:SetNWEntity( "Portal:Blue", Portal )
								Portal:SetNetworkedBool("blue",true,true)
							else
								owner:SetNWEntity( "Portal:Orange", Portal )
								Portal:SetNetworkedBool("blue",false,true)
							end

							EntToUse = Portal

							if IsValid( OtherEnt ) then
									EntToUse:LinkPortals( OtherEnt )
							end
						else
							EntToUse:MoveToNewPos( validpos, validnormang )
							EntToUse:SuccessEffect()
						end
					end
				end)
			else
				timer.Simple( hitDelay_Instant, function()
					if ball and ball:IsValid() then
						local ang = trace.HitNormal:Angle()

						ang:RotateAroundAxis( ang:Right(), -90 )
						ang:RotateAroundAxis( ang:Forward(), 0 )
						ang:RotateAroundAxis( ang:Up(), 90 )
						local ent = ents.Create( "info_particle_system" )
						ent:SetPos( trace.HitPos + trace.HitNormal * 0.1 )
						ent:SetAngles( ang )
						--TODO: Different fail effects.

						if type == TYPE_BLUE then
							if GetConVarNumber("portal_color_1") >=14 then
								ent:SetKeyValue( "effect_name", "portal_gray_badsurface")
							elseif GetConVarNumber("portal_color_1") >=13 then
								ent:SetKeyValue( "effect_name", "portal_gray_badsurface")
							elseif GetConVarNumber("portal_color_1") >=12 then
								ent:SetKeyValue( "effect_name", "portal_gray_badsurface")
							elseif GetConVarNumber("portal_color_1") >=11 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_pbody")
							elseif GetConVarNumber("portal_color_1") >=10 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_1") >=9 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_1") >=8 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_atlas")
							elseif GetConVarNumber("portal_color_1") >=7 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface")
							elseif GetConVarNumber("portal_color_1") >=6 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_atlas")
							elseif GetConVarNumber("portal_color_1") >=5 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_1") >=4 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_1") >=3 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_1") >=2 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_pbody")
							elseif GetConVarNumber("portal_color_1") >=1 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface")
							else
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_pbody")
							end
						elseif type == TYPE_ORANGE then
							if GetConVarNumber("portal_color_2") >=14 then
								ent:SetKeyValue( "effect_name", "portal_gray_badsurface")
							elseif GetConVarNumber("portal_color_2") >=13 then
								ent:SetKeyValue( "effect_name", "portal_gray_badsurface")
							elseif GetConVarNumber("portal_color_2") >=12 then
								ent:SetKeyValue( "effect_name", "portal_gray_badsurface")
							elseif GetConVarNumber("portal_color_2") >=11 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_pbody")
							elseif GetConVarNumber("portal_color_2") >=10 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_2") >=9 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_2") >=8 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_atlas")
							elseif GetConVarNumber("portal_color_2") >=7 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface")
							elseif GetConVarNumber("portal_color_2") >=6 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_atlas")
							elseif GetConVarNumber("portal_color_2") >=5 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_2") >=4 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_2") >=3 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_pink_green")
							elseif GetConVarNumber("portal_color_2") >=2 then
								ent:SetKeyValue( "effect_name", "portal_1_badsurface_pbody")
							elseif GetConVarNumber("portal_color_2") >=1 then
								ent:SetKeyValue( "effect_name", "portal_2_badsurface")
							else
								ent:SetKeyValue( "effect_name", "portal_2_badsurface_pbody")
							end
						end

						ent:SetKeyValue( "start_active", "1")
						ent:Spawn()
						ent:Activate()
						timer.Simple( 5, function()
							if IsValid( ent ) then
								ent:Remove()
							end 
						end)

						if not snd_portal2:GetBool() then 
							ent:EmitSound( "weapons/portalgun/portal_invalid_surface3.wav")
						else
							ent:EmitSound( "weapons/portalgun/portal2/portal_invalid_surface"..math.random(1,4)..".wav")
						end
					end
				end)
			end
		end
	end
end


function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	local owner = self:GetOwner()

	if GetConVarNumber("portal_portalonly") >= 2 then
		-- nothing
	elseif GetConVarNumber("portal_portalonly") >= 1 then
		self:ShootPortal( TYPE_BLUE )
		self:SetNetworkedInt("LastPortal",1)
		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

		if not snd_portal2:GetBool() then 
			self:EmitSound( "weapons/portalgun/portalgun_shoot_blue1.wav", 70, 100, .7, CHAN_WEAPON )
		else
			self:EmitSound( "weapons/portalgun/portal2/portalgun_shoot_blue"..math.random(1,3)..".wav", 70, 100, .7, CHAN_WEAPON )
		end

		owner:SetAnimation(PLAYER_ATTACK1)
		self:IdleStuff()
	else
		self:ShootPortal( TYPE_BLUE )
		self:SetNetworkedInt("LastPortal",1)
		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		if not snd_portal2:GetBool() then 
			self:EmitSound( "weapons/portalgun/portalgun_shoot_blue1.wav", 70, 100, .7, CHAN_WEAPON )
		else
			self:EmitSound( "weapons/portalgun/portal2/portalgun_shoot_blue" .. math.random(1,3) .. ".wav", 70, 100, .7, CHAN_WEAPON )
		end
		owner:SetAnimation(PLAYER_ATTACK1)
		self:IdleStuff()
	end

	self.LastAttackTime = CurTime()
	self.SoonestAttack = CurTime() + self.Primary.FastestDelay

	local fireRate = self.Delay

	self:SetNextPrimaryFire( CurTime() + fireRate )
	self:SetNextSecondaryFire( CurTime() + fireRate )

	if not owner:IsNPC() then
		self:AddViewKick()
	end
end

function SWEP:SecondaryAttack()
	if GetConVarNumber("portal_portalonly") >= 2 then
		self:ShootPortal( TYPE_ORANGE )
		self:SetNetworkedInt("LastPortal",2)
		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		if not snd_portal2:GetBool() then 
			self:EmitSound( "weapons/portalgun/portalgun_shoot_red1.wav", 70, 100, .7, CHAN_WEAPON )
		else
			self:EmitSound( "weapons/portalgun/portal2/portalgun_shoot_red"..math.random(1,3)..".wav", 70, 100, .7, CHAN_WEAPON )
		end
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		self:IdleStuff()
	elseif GetConVarNumber("portal_portalonly") >=1 then
		-- nothing
	else
		self:ShootPortal( TYPE_ORANGE )
		self:SetNetworkedInt("LastPortal",2)
		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		if not snd_portal2:GetBool() then 
			self:EmitSound( "weapons/portalgun/portalgun_shoot_red1.wav", 70, 100, .7, CHAN_WEAPON )
		else
			self:EmitSound( "weapons/portalgun/portal2/portalgun_shoot_red"..math.random(1,3)..".wav", 70, 100, .7, CHAN_WEAPON )
		end
		self.Owner:SetAnimation(PLAYER_ATTACK1)
		self:IdleStuff()
	end

	if ( not self:CanSecondaryAttack() ) then return end

	self.LastAttackTime = CurTime()
	self.SoonestAttack = CurTime() + self.Primary.FastestDelay

	local pOwner = self.Owner

	local pPlayer = self.Owner
	if (not pPlayer) then
		return
	end

	local iBulletsToFire = 0
	local fireRate = self.Delay

	self:SetNextPrimaryFire( CurTime() + fireRate )
	self:SetNextSecondaryFire( CurTime() + fireRate )

	if ( not pPlayer:IsNPC() ) then
		self:AddViewKick()
	end
end

function SWEP:CleanPortals()
	local blueportal = self.Owner:GetNWEntity( "Portal:Blue" )
	local orangeportal = self.Owner:GetNWEntity( "Portal:Orange" )
	local cleaned = false

	for k,v in ipairs( ents.FindByClass( "prop_portal" ) ) do
		if v == blueportal or v == orangeportal and v.CleanMeUp then
			if SERVER then
				v:CleanMeUp()
			end

			cleaned = true
		end
	end

	if cleaned then
		self:SendWeaponAnim( ACT_VM_FIZZLE )
		self:SetNetworkedInt("LastPortal",0)
		if not snd_portal2:GetBool() then

			self:EmitSound( "weapons/portalgun/portal_fizzle2.wav", 45, 100, .5, CHAN_WEAPON )
		else
			self:EmitSound( "weapons/portalgun/portal2/portal_fizzle2.wav", 45, 100, .5, CHAN_WEAPON )
		end

		self:IdleStuff()
	end
end

function SWEP:Reload()
	if not cleanportals:GetBool() then return end

	self:CleanPortals()
	self:IdleStuff()
end

function SWEP:OnRestore()
	self:SendWeaponAnim( ACT_VM_DEPLOY )
end

/*---------------------------------------------------------
   Name: IdleStuff
   Desc: Helpers for the Idle function.
---------------------------------------------------------*/
function SWEP:IdleStuff()
	if self.EnableIdle then return end
	self.idledelay = CurTime() + self:SequenceDuration()

	timer.Create( "Hold", 0.005, 1, function()
		if not self.HoldenProp then return end

		if CarryAnim_P1:GetBool() then
			self:SendWeaponAnim(ACT_VM_FIDGET)
				else
			self:SendWeaponAnim(ACT_VM_RELEASE)
		end

		if SERVER then
			self.Owner:DropObject()
		end

		self.HoldenProp.Holder = nil
		self.HoldenProp = nil

		if SERVER then
			net.Start( "PORTALGUN_PICKUP_PROP" )
				net.WriteEntity( self )
				net.WriteEntity( NULL )
			net.Send( self.Owner )
		end
	end)
end

function SWEP:CheckExisting()
	if blueportal ~= nil and blueportal ~= nil then return end
	for _,v in pairs(ents.FindByClass("prop_portal")) do
		local own = v.Ownr
		if v ~= nil and own == self.Owner then
			if v.type == TYPE_BLUE and self.blueportal == nil then
				self.blueportal = v
			elseif v.type == TYPE_ORANGE and self.orangeportal == nil then
				self.orangeportal = v
			end
		end
	end
end

function SWEP:AddViewKick()

	local pPlayer  = self.Owner

	if ( pPlayer == NULL ) then
		return
	end

	self.viewPunch = Angle( 0, 0, 0 )

	self.viewPunch.x = math.Rand( 0.25, 0.5 )
	self.viewPunch.y = math.Rand( -.6, .6 )
	self.viewPunch.z = 0.0

	pPlayer:ViewPunch( self.viewPunch )

end

function SWEP:Holster( wep )

	if not tryhard:GetBool() then
		self.Holster_Fire = true
	else
		self.Holster_Fire = false
	end

	return true

end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DEPLOY )
	self:CheckExisting()
	self:IdleStuff()

	return true
end

function SWEP:CanPrimaryAttack()
	return true
end

function SWEP:CanSecondaryAttack()
	return true
end


function SWEP:IdleStuff()
	if self.EnableIdle then return end

	self.idledelay = CurTime() + self:SequenceDuration()

	timer.Create( "Hold", 0.005, 1, function()
		if not self.HoldenProp then return end

		if CarryAnim_P1:GetBool() then
			self:SendWeaponAnim(ACT_VM_FIDGET)
				else
			self:SendWeaponAnim(ACT_VM_RELEASE)
		end

		if SERVER then
			self.Owner:DropObject()
		end

		self.HoldenProp.Holder = nil
		self.HoldenProp = nil

		if SERVER then
			net.Start( "PORTALGUN_PICKUP_PROP" )
				net.WriteEntity( self )
				net.WriteEntity( NULL )
			net.Send( self.Owner )
		end
	end)
end

function SWEP:CheckExisting()
	if blueportal ~= nil and blueportal ~= nil then return end
	for _,v in pairs(ents.FindByClass("prop_portal")) do
		local own = v.Ownr
		if v ~= nil and own == self.Owner then
			if v.type == TYPE_BLUE and self.blueportal == nil then
				self.blueportal = v
			elseif v.type == TYPE_ORANGE and self.orangeportal == nil then
				self.orangeportal = v
			end
		end
	end
end