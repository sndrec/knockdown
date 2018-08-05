
ENT.Type 			= "anim"
ENT.PrintName		= "Turret"
ENT.Author			= "Upset"

ENT.Spawnable		= true

ENT.RenderGroup		= RENDERGROUP_BOTH

function ENT:SetupDataTables()

	self:NetworkVar( "Float", 0, "BuildingHealth" )
	self:NetworkVar( "Float", 1, "BuildingMaxHealth" )
	self:NetworkVar( "Float", 2, "StandLengthModifier" )
	self:NetworkVar( "Vector", 0, "DesiredColor")

end