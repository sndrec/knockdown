
ENT.Type 			= "anim"
ENT.Base 			= "q3_proj_base"
ENT.PrintName		= "Rocket"
ENT.Author			= "Upset"

ENT.Spawnable		= false

ENT.RenderGroup		= RENDERGROUP_BOTH


function ENT:SetupDataTables()

	self:NetworkVar( "Int", 0, "ProjectileTeam" )

	self:NetworkVar( "Float", 0, "ProjectileDamage" )
	self:NetworkVar( "Float", 1, "ProjectileSpeed" )
	self:NetworkVar( "Float", 2, "ProjectileSplashRadius" )

end