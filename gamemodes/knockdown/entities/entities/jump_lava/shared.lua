
ENT.Type 			= "anim"
ENT.PrintName		= "Turret"
ENT.Author			= "Upset"

ENT.Spawnable		= true

ENT.RenderGroup		= RENDERGROUP_BOTH

function ENT:SetupDataTables()

	self:NetworkVar( "Float", 0, "LavaHeight" )

end