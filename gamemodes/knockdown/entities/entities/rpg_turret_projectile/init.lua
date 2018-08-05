
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/benisassets/rocket.mdl")
	self:SetRenderMode(RENDERMODE_TRANSALPHA)

end

function ENT:PhysicsCollide(data, physobj)
	local start = data.HitPos + data.HitNormal
    local endpos = data.HitPos - data.HitNormal
	
	local tr = util.TraceLine({
		start = endpos,
		endpos = start,
		filter = self
	})
	
	if IsValid(self:GetOwner()) then
		self:RadiusDamage(tr.HitPos, self, self:GetOwner(), self:GetProjectileDamage(), self:GetProjectileSplashRadius(), data.HitEntity)
	end
	self:Remove()
end

function ENT:OnRemove()
	if self.flysound then self.flysound:Stop() end
end

function ENT:Think()
	local phys = self:GetPhysicsObject()
end