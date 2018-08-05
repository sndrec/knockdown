
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube1x1x1.mdl")
	self:PhysicsInitShadow( false, false )
	self:SetSolid(SOLID_VPHYSICS)
	self.firstThink = true
	self:SetLavaHeight(-12500)
	jumpGameLava = self
end

function ENT:Think()
	for i, v in ipairs(player.GetAll()) do
		if v:GetPos().z <= self:GetLavaHeight() then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(30)
			dmginfo:SetDamageType(DMG_BURN)
			dmginfo:SetInflictor(self)
			dmginfo:SetAttacker(self)
			v:TakeDamageInfo(dmginfo)
		end
	end
	self:NextThink(CurTime() + 0.5)
	return true
end