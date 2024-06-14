AddCSLuaFile("shared.lua")

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Portal Ball"
ENT.Author = "Mahalis"
ENT.Spawnable = false
ENT.AdminSpawnable = false

useInstant = CreateConVar("portal_instant", 0, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Make portals create instantly and don't use the projectile.")
ballEnable = CreateConVar("portal_projectile_ball", "1", 1, "If the ball is enabled")

function ENT:SetupDataTables()
	self:NetworkVar("Int", "Kind")
	self:NetworkVar("Entity", "Weapon")

	self:NetworkVar("Int", "Color1")
	self:NetworkVar("Int", "Color2")
end

function ENT:Initialize()
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetModel("models/hunter/misc/sphere025x025.mdl")

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:PhysicsInitSphere(1, "Metal")

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableGravity(false)
			phys:EnableDrag(false)
			phys:EnableCollisions(false)
		end
	else
		self:SetEffects(self:GetKind())
	end

	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:DrawShadow(false)
	--self:SetNoDraw(false)
	--timer.Simple(.01, function() if self:IsValid() then self:SetNoDraw(true) end end)
end

local SWITCH_PARTICLE_FORMATSTR = {
	[14] = "portal_gray_projectile_%s",
	[13] = "portal_gray_projectile_%s",
	[12] = "portal_gray_projectile_%s",
	[11] = "portal_2_projectile_%s_pbody",
	[10] = "portal_2_projectile_%s_pink_green",
	[9] = "portal_2_projectile_%s_pink_green",
	[8] = "portal_2_projectile_%s_atlas",
	[7] = "portal_1_projectile_%s",
	[6] = "portal_1_projectile_%s_atlas",
	[5] = "portal_1_projectile_%s_pink_green",
	[4] = "portal_1_projectile_%s_pink_green",
	[3] = "portal_1_projectile_%s_pink_green",
	[2] = "portal_1_projectile_%s_pbody",
	[1] = "portal_2_projectile_%s",
	[0] = "portal_2_projectile_%s_pbody"
}

function ENT:SetEffects(type)
	self:SetKind(type)

	if ballEnable:GetBool() then
		local owner, iPortalColor1, iPortalColor2 = NULL, self:GetColor1(), self:GetColor2()
		if SERVER and self:GetWeapon():IsValid() then
			owner = self:GetWeapon():GetOwner()

			if owner:IsValid() then
				iPortalColor1 = owner:GetInfoNum("portal_color_1", 7)
				iPortalColor2 = owner:GetInfoNum("portal_color_2", 1)
			end
		end

		self:SetColor1(iPortalColor1)
		self:SetColor2(iPortalColor2)

		if not useInstant:GetBool() then
			if type == TYPE_BLUE then
				local formatStr = SWITCH_PARTICLE_FORMATSTR[iPortalColor1] or SWITCH_PARTICLE_FORMATSTR[0]

				ParticleEffectAttach(string.format(formatStr, "ball"), PATTACH_ABSORIGIN_FOLLOW, self, 1)
			elseif type == TYPE_ORANGE then
				local formatStr = SWITCH_PARTICLE_FORMATSTR[iPortalColor2] or SWITCH_PARTICLE_FORMATSTR[0]

				ParticleEffectAttach(string.format(formatStr, "ball"), PATTACH_ABSORIGIN_FOLLOW, self, 1)
			end
		end

		if type == TYPE_BLUE then
			local formatStr = SWITCH_PARTICLE_FORMATSTR[iPortalColor1] or SWITCH_PARTICLE_FORMATSTR[0]

			ParticleEffectAttach(string.format(formatStr, "fiber"), PATTACH_ABSORIGIN_FOLLOW, self, 1)
		elseif type == TYPE_ORANGE then
			local formatStr = SWITCH_PARTICLE_FORMATSTR[iPortalColor2] or SWITCH_PARTICLE_FORMATSTR[0]

			ParticleEffectAttach(string.format(formatStr, "fiber"), PATTACH_ABSORIGIN_FOLLOW, self, 1)
		end
	end
end

function ENT:SetGun(ent)
	self:SetWeapon(ent)
end

function ENT:GetGun()
	return self:GetWeapon()
end

function ENT:PhysicsCollide(data, phy)
	-- self:Remove()
	-- print("Create Portal!")
end

function ENT:Draw()
	--self:DrawModel()
end