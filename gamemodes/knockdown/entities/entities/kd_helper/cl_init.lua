include('shared.lua')

function ENT:Initialize()
	self.firstDraw = true
	self:SetRenderBoundsWS(Vector(-10000,-10000,-10000),Vector(10000,10000,10000))
end

function ENT:Draw()
	render.OverrideDepthEnable(true, true)
	if self:GetDrawModel() then
		self:DrawModel()
	end
	if self:GetBeam() then
		if self.firstDraw then
			self.beamMat = Material(self:GetString1(), "unlitgeneric")
			self.deathTime = CurTime() + self:GetFloat2()
			self.lifeTime = self:GetFloat2()
		end
		render.SetMaterial(self.beamMat)
		local ratio = math.Clamp((self.deathTime - CurTime()), 0, 1)
		render.DrawBeam( self:GetVector1(), self:GetVector2(), self:GetFloat1() * ratio, 0, 1, Color(255,255,255,255) )
	end
	self.firstDraw = false
	render.OverrideDepthEnable(true, false)
end