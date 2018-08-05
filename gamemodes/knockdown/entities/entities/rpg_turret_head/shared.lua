
ENT.Type 			= "anim"
ENT.PrintName		= "Turret Head"
ENT.Author			= "Upset"

ENT.Spawnable		= false

ENT.RenderGroup		= RENDERGROUP_BOTH


function ENT:SetupDataTables()

	self:NetworkVar( "Int", 0, "BuildingHealth" )
	self:NetworkVar( "Int", 1, "BuildingMaxHealth" )


	self:NetworkVar( "Float", 0, "TurretDamage" )
	self:NetworkVar( "Float", 1, "ProjectileSpeed" )
	self:NetworkVar( "Float", 2, "ProjectileSplash" )
	self:NetworkVar( "Float", 3, "Firerate" )
	self:NetworkVar( "Float", 4, "TargetRange" )
	self:NetworkVar( "Float", 5, "TrackSpeed" )

end