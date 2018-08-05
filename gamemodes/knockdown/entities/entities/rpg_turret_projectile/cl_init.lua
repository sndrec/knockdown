include('shared.lua')

function ENT:Initialize()
	self.Ang = self:GetAngles()
	self.Spin = 0
end

function ENT:Draw()
	if self:GetVelocity():Length() == 0 and (CurTime() - self:GetCreationTime()) < 1 then return end
	self.Spin = self.Spin + FrameTime()*130
	self:SetRenderAngles(self.Ang + Angle(0,0,self.Spin))
	self:DrawModel()
end