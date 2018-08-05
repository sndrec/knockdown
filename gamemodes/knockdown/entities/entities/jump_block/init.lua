
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--[[
"models/platformmaster/1x1half.mdl"
"models/platformmaster/1x1halfcyl.mdl"
"models/platformmaster/1x1x1.mdl"
"models/platformmaster/1x1x1cyl.mdl"
"models/platformmaster/1x1x1spike.mdl"
"models/platformmaster/1x1x1tri.mdl"
"models/platformmaster/1x1x2tri.mdl"
"models/platformmaster/1x1x4tri.mdl"
"models/platformmaster/2x1x1.mdl"
"models/platformmaster/2x1x1spike.mdl"
"models/platformmaster/2x2x1tri.mdl"
"models/platformmaster/2x2x2cyl.mdl"
"models/platformmaster/2x2x2l.mdl"
"models/platformmaster/2x2x2tri.mdl"
"models/platformmaster/2x2x2tun.mdl"
"models/platformmaster/2x2x4tri.mdl"
"models/platformmaster/2x2xhalfcyl.mdl"
"models/platformmaster/2x4x2tun.mdl"
"models/platformmaster/3x2x1l.mdl"
"models/platformmaster/3x2x1t.mdl"
"models/platformmaster/3x2x1z.mdl"
"models/platformmaster/3x2x2l.mdl"
"models/platformmaster/3x2x2t.mdl"
"models/platformmaster/3x2x2z.mdl"
"models/platformmaster/3x3x1c.mdl"
"models/platformmaster/3x3x2c.mdl"
"models/platformmaster/4x1x1.mdl"
"models/platformmaster/4x2x2.mdl"
"models/platformmaster/4x2x2tun.mdl"
"models/platformmaster/4x2x4bracket.mdl"
"models/platformmaster/4x2x4tunnel.mdl"
"models/platformmaster/4x4x1.mdl"
"models/platformmaster/4x4x1cyl.mdl"
"models/platformmaster/4x4x1l.mdl"
"models/platformmaster/4x4x1tri.mdl"
"models/platformmaster/4x4x2.mdl"
"models/platformmaster/4x4x2cyl.mdl"
"models/platformmaster/4x4x2l.mdl"
"models/platformmaster/4x4x2tri.mdl"
"models/platformmaster/4x4x2tun.mdl"
"models/platformmaster/4x4x4benis.mdl"
"models/platformmaster/4x4x4bracket.mdl"
"models/platformmaster/4x4x4corner.mdl"
"models/platformmaster/4x4x4tri.mdl"
"models/platformmaster/4x4x4tun.mdl"
"models/platformmaster/4x4x4tunnel.mdl"
"models/platformmaster/6x4x1l.mdl"
"models/platformmaster/6x4x1t.mdl"
"models/platformmaster/6x4x1z.mdl"
"models/platformmaster/6x4x2l.mdl"
"models/platformmaster/6x4x2t.mdl"
"models/platformmaster/6x4x2z.mdl"
"models/platformmaster/6x6x1c.mdl"
"models/platformmaster/6x6x2c.mdl"
"models/platformmaster/8x1x1.mdl"
"models/platformmaster/8x2x1.mdl"
"models/platformmaster/8x2x2.mdl"
"models/platformmaster/8x8x1.mdl"
]]--


function ENT:DefineNewBlockType(blockModel, blockAngles, posOffsets, blockWeight, blockHealth, desiredColor)
	local tempTable = {}
	tempTable.model = blockModel
	tempTable.angles = blockAngles
	tempTable.offset = posOffsets
	tempTable.weight = blockWeight
	tempTable.health = blockHealth
	if desiredColor then
		self:SetDesiredColor(Vector(desiredColor.r,desiredColor.g,desiredColor.b))
	else
		self:SetDesiredColor(Vector(0,0,0))
	end
	table.insert(self.blockTable, tempTable)
end

function ENT:ChangeBlockHealth(num)
	self:SetBuildingHealth(self:GetBuildingHealth() + num)
	if self:GetBuildingHealth() <= 0 then
		self:EmitSound("physics/concrete/boulder_impact_hard" .. math.random(1,4) .. ".wav",85,math.random(110,130))
		self:Remove()
	end
	local healthratio = self:GetBuildingHealth() / self:GetBuildingMaxHealth()
	if healthratio < 0.75 and self.curMat == 1 then
		self.curMat = 2
		self:SetMaterial("jumpbox2")
		self:EmitSound("physics/concrete/boulder_impact_hard" .. math.random(1,4) .. ".wav",60,math.random(220,240))
	elseif healthratio < 0.5 and self.curMat == 2 then
		self.curMat = 3
		self:SetMaterial("jumpbox3")
		self:EmitSound("physics/concrete/boulder_impact_hard" .. math.random(1,4) .. ".wav",65,math.random(180,200))
	elseif healthratio < 0.25 and self.curMat == 3 then
		self.curMat = 4
		self:SetMaterial("jumpbox4")
		self:EmitSound("physics/concrete/boulder_impact_hard" .. math.random(1,4) .. ".wav",70,math.random(160,180))
	end
end

function ENT:DefineBlocks()
	self.blockTable = {}
	self:DefineNewBlockType("models/platformmaster/8x8x1.mdl", {Angle(0,0,0)}, 
		function(ent)
			local pos = ent:GetPos()
			pos.x = math.Round(pos.x / 64, 0) * 64
			pos.y = math.Round(pos.y / 64, 0) * 64
			pos.z = ent.plane - ((math.abs(pos.x) + math.abs(pos.y * 2)) * 0.004)
			return pos
		end, 200, 800, Color(200,200,200))
	self:DefineNewBlockType("models/platformmaster/8x8x1.mdl", {Angle(0,0,90), Angle(0,45,90), Angle(0,90,90), Angle(0,135,90)}, {Vector(0,0,256)}, 40, 400)
	self:DefineNewBlockType("models/platformmaster/8x8x1.mdl", {Angle(0,0,0), Angle(0,45,0)}, {Vector(0,0,256 + 128)}, 50, 400)
	self:DefineNewBlockType("models/platformmaster/4x4x1cyl.mdl", {Angle(0,0,0)}, {Vector(0,0,0)}, 40, 250)
	
	self:DefineNewBlockType("models/platformmaster/8x2x2.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 20, 250)
	self:DefineNewBlockType("models/platformmaster/8x2x1.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 20, 250)
	self:DefineNewBlockType("models/platformmaster/8x1x1.mdl",
		function(ent)
			local pos = ent:GetPos()
			pos.z = 0
			return pos:Angle()
		end, {Vector(0,0,0)}, 20, 250)
	
	self:DefineNewBlockType("models/platformmaster/6x4x1l.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 10, 500)
	self:DefineNewBlockType("models/platformmaster/6x4x1t.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 10, 500)
	self:DefineNewBlockType("models/platformmaster/6x4x1z.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 10, 500)
	self:DefineNewBlockType("models/platformmaster/6x4x2l.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 10, 500)
	self:DefineNewBlockType("models/platformmaster/6x4x2t.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 10, 500)
	self:DefineNewBlockType("models/platformmaster/6x4x2z.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 10, 500)
	self:DefineNewBlockType("models/platformmaster/6x6x1c.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 10, 500)
	self:DefineNewBlockType("models/platformmaster/6x6x2c.mdl", {Angle(0,0,0), Angle(0,45,0), Angle(0,90,0), Angle(0,135,0)}, {Vector(0,0,0)}, 10, 500)
end

function ENT:Initialize()
	self:DefineBlocks()
	self.curMat = 1
	self.lastStood = 0
	local blockType = WeightedRandom(self.blockTable)
	self:SetModel(blockType.model)
	if type(blockType.angles) == "table" then
		self:SetAngles(table.Random(blockType.angles))
	else
		local newAngle = blockType.angles(self)
		self:SetAngles(newAngle)
	end
	if type(blockType.offset) == "table" then
		self:SetPos(self:GetPos() + table.Random(blockType.offset))
	else
		local newOffset = blockType.offset(self)
		self:SetPos(newOffset)
	end
	self:PhysicsInitShadow( false, false )
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMaterial("jumpbox1")
	self.firstThink = true
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetBuildingMaxHealth(blockType.health)
	self:SetBuildingHealth(blockType.health)
end

function ENT:Think()
end