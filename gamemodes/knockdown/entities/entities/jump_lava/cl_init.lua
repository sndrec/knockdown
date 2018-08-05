include("shared.lua")

function ENT:Initialize()
end

local mat = Material("models/props_combine/tprings_globe.vtf")

function ENT:Draw()
	cam.Start3D2D(Vector(0,0,self:GetLavaHeight()),Angle(-90,0,0),1)
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(mat)
		surface.DrawTexturedRectUV( -4096, -4096, 8192, 8192, 0, 0, 512, 512 )
	cam.End3D2D()
	self:DrawModel()
end

function ENT:Think()
end