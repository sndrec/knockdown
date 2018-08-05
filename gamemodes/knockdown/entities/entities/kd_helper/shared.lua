ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName= "Benis Ammopack"
ENT.Author= "BENIS TEAM"
ENT.Contact= "Benis"
ENT.Purpose= "to benis"
ENT.Instructions= "Use wisely."
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("Entity",0, "NetEnt1")
	self:NetworkVar("Entity",1, "NetEnt2")
	self:NetworkVar("Entity",2, "NetEnt3")
	self:NetworkVar("Entity",3, "NetEnt4")
	self:NetworkVar("Vector",0, "Vector1")
	self:NetworkVar("Vector",1, "Vector2")
	self:NetworkVar("Vector",2, "Vector3")
	self:NetworkVar("Vector",3, "Vector4")
	self:NetworkVar("Float",0, "Float1")
	self:NetworkVar("Float",1, "Float2")
	self:NetworkVar("Float",2, "Float3")
	self:NetworkVar("Float",3, "Float4")
	self:NetworkVar("String",0, "String1")
	self:NetworkVar("String",1, "String2")
	self:NetworkVar("String",2, "String3")
	self:NetworkVar("String",3, "String4")
	self:NetworkVar("Bool",0, "DrawModel")
	self:NetworkVar("Bool",1, "Beam")
end