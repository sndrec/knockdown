
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_junk/TrafficCone001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self.phys = self:GetPhysicsObject()
	self:Activate()
	self:NextThink( CurTime() )
	self:SetBuildingMaxHealth(500)
	self:SetBuildingHealth(self:GetBuildingMaxHealth())
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

local function PlayerPickup( ply, ent )
	if ent:GetClass() == "rpg_turret_head" then
		return false
	end
end
hook.Add( "PhysgunPickup", "TurretBlock", PlayerPickup )

function ENT:OnRemove()
	if self.base:IsValid() then
		self.base:Remove()
	end
end

function ENT:Think()

	self:NextThink(CurTime() + 1)

	return true
end