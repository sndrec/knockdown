 include('shared.lua')

function ENT:Initialize()
	self:DestroyShadow()
	self.blockCol = Color(190 + (math.sin(self:GetPos().x * 0.001) * 64), 
		190 + (math.sin(self:GetPos().y * 0.001) * 64), 
		190 + (math.cos(((self:GetPos().y + self:GetPos().z) * 0.001) + ((self:GetPos().x - self:GetPos().z) * 0.001)) * 64))
	if self:GetDesiredColor() ~= Vector(0,0,0) then
		self.blockCol = Color(self:GetDesiredColor().x, self:GetDesiredColor().y, self:GetDesiredColor().z)
	end
	self.blockCol.r = self.blockCol.r * 0.85
	self.blockCol.g = self.blockCol.g * 0.85
	self.blockCol.b = self.blockCol.b * 0.85
	self:SetColor(self.blockCol)
	self.drawZ = self:GetPos().z
end

function ENT:Draw()
	local drawFactor = math.abs(self.drawZ - EyePos().z)
	if drawFactor < 2000 then
		render.SetModelLighting( BOX_FRONT, 0.35, 0.35, 0.35 )
		render.SetModelLighting( BOX_BACK, 0.35, 0.35, 0.35 )
		render.SetModelLighting( BOX_RIGHT, 0.35, 0.35, 0.35 )
		render.SetModelLighting( BOX_LEFT, 0.35, 0.35, 0.35 )
		render.SetModelLighting( BOX_TOP, 0.8, 0.8, 0.8 )
		render.SetModelLighting( BOX_BOTTOM, 0.5, 0.5, 0.5 )
		self:DrawModel()
	end
	local alpha = math.Clamp(2000 - drawFactor, 1, 255)
	self:SetColor(Color(self.blockCol.r, self.blockCol.g, self.blockCol.b, alpha))
end

function ENT:Think()

end