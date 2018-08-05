AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.

include("shared.lua")

function ENT:Initialize( )
	self:SetModel("models/vinrax/props/scp035/035_mask.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	if self.Owner:IsValid() then
		self.Owner:SetObserverMode(OBS_MODE_CHASE)
		self.Owner:SpectateEntity(self)
		self.Owner:StripWeapons()
	end
end

function ENT:Use( activator, caller )
	if caller:IsValid() and caller:IsPlayer() and self.Owner:IsValid() and self.Owner:IsPlayer() and caller ~= self.Owner then
		local tempAng = caller:EyeAngles()
		local tempPos = caller:GetPos()
		caller.scp037SpawnAsSpec = true
		self.Owner.scp037HasMask = true
		self.Owner:Spawn()
		self.Owner:SetObserverMode(OBS_MODE_NONE)
		self.Owner:SetModel(caller:GetModel())
		self.Owner:SetColor(caller:GetColor())
		local weaponList = caller:GetWeapons()
		PrintTable(weaponList)
		for i, v in ipairs(weaponList) do
			self.Owner:Give(v:GetClass())
		end
		caller:Spawn()
		caller:SetObserverMode(OBS_MODE_CHASE)
		caller:SpectateEntity(self.Owner)
		caller:StripWeapons()
		self.Owner:SetAngles(tempAng)
		self.Owner:SetPos(tempPos)
		self:Remove()
	end
end

function ENT:Think()

end