ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Tetris Attack"
ENT.Author = "BENIS TEAM"
ENT.Contact = "Benis"
ENT.Purpose = "to benis"
ENT.Instructions = "Use wisely."
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "PlayField1" )
	self:NetworkVar( "String", 1, "PlayField2" )
	self:NetworkVar( "Vector", 0, "CursorPos1" )
	self:NetworkVar( "Vector", 1, "CursorPos2" )
	self:NetworkVar( "Float", 0, "BoardOffset1" )
	self:NetworkVar( "Float", 1, "BoardOffset2" )
	self:NetworkVar( "Float", 2, "ScrollSpeed1" )
	self:NetworkVar( "Float", 3, "ScrollSpeed2" )
	self:NetworkVar( "Int", 0, "SwapTime" )
	self:NetworkVar( "Int", 1, "PlayField1Length" )
	self:NetworkVar( "Int", 2, "PlayField2Length" )
	self:NetworkVar( "Int", 3, "PL1Chain" )
	self:NetworkVar( "Int", 4, "PL2Chain" )
	self:NetworkVar( "Int", 5, "PL1Score" )
	self:NetworkVar( "Int", 6, "PL2Score" )
	self:NetworkVar( "Int", 5, "CurFrame" )
	self:NetworkVar( "Entity", 0, "Player1" )
	self:NetworkVar( "Entity", 1, "Player2" )

end