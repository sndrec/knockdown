AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.

include("shared.lua")

function ENT:Initialize( )
	self:PhysicsInit( SOLID_NONE )
	self:SetMoveType( MOVETYPE_NONE )
	self.deathTime = CurTime() + 1
	self:Think()
end

function ENT:ThinkSpecial()
end

function ENT:Think()
	if self.deathTime and CurTime() >= self.deathTime then
		self:Remove()
	end
	self:ThinkSpecial()
	self:NextThink(CurTime())
	return true
end