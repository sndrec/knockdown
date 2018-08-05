
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/hunter/tubes/circle2x2.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self.phys = self:GetPhysicsObject()
	self:Activate()
	self:NextThink( CurTime() )
	self.head = ents.Create("rpg_turret_head")
	self.head:SetPos(self:GetPos() + Vector(0,0,48))
	self.head:Spawn()
	self.head.base = self
	self.head.phys = self.head:GetPhysicsObject()

	self:SetTurretDamage(20)
	self:SetFirerate(2)
	self:SetProjectileSpeed(250)
	self:SetTargetRange(512)
	self:SetTrackSpeed(80)
	self:SetProjectileSplash(10)
	self.FireTimer = CurTime()
end

function ENT:OnRemove()
	if self.head ~= nil and self.head:IsValid() then
		self.head:Remove()
	end
end

function ENT:TurretFire(angle)
	if CurTime() > self.FireTimer then
		self.FireTimer = CurTime() + self:GetFirerate()
		local rocket = ents.Create("rpg_turret_projectile")
		rocket:SetPos(self.head:GetPos() + (angle:Forward() * 32))
		rocket:SetAngles(angle)
		rocket:SetProjectileDamage(self:GetTurretDamage())
		rocket:SetProjectileSpeed(self:GetProjectileSpeed())
		rocket:SetProjectileSplashRadius(self:GetProjectileSplash())
		rocket:Spawn()
		rocket:SetOwner(self)
		rocket:SetLagCompensated(true)
		rocket:SetMoveCollide(COLLISION_GROUP_PROJECTILE)
		rocket:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
		rocket:PhysicsInit(SOLID_VPHYSICS)
		rocket:SetMoveType(MOVETYPE_VPHYSICS)
		rocket:SetSolid(SOLID_CUSTOM)
		local phys = rocket:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetVelocity(angle:Forward() * self:GetProjectileSpeed())
			phys:Wake()
			phys:SetMass(1)
			phys:EnableDrag(false)
			phys:EnableGravity(false)
			phys:SetBuoyancyRatio(0)
		end
	end
end

function ENT:HealthThink()

end

function ENT:OnTakeDamage( damage )

end

function ENT:Think()

	self.head:SetPos(self:GetPos() + (self:GetAngles():Up() * 48))
	
	self:NextThink( CurTime() + 0.1)

	local targetTable = {}
	local players = player.GetAll()
	for i=1, #players, 1 do
		if self.head:GetPos():Distance(players[i]:GetPos()) < self:GetTargetRange() then
			table.insert(targetTable, players[i])
		end
	end

	local closestNum = self:GetTargetRange()
	local closest = 0

	for i=1, #targetTable, 1 do
		if self.head:GetPos():Distance(targetTable[i]:GetPos()) < closestNum then
			closestNum = self.head:GetPos():Distance(targetTable[i]:GetPos())
			closest = targetTable[i]
		end
	end

	local angle = 0
	local headangle = self.head:GetAngles()

	if closest ~= 0 then
		local visibilityTrace = util.TraceLine({
			start = self.head:GetPos(),
			endpos = closest:GetPos() + Vector(0,0,36),
			filter = self.head
			})


		if visibilityTrace.Entity:IsPlayer() then
			debugoverlay.Line( visibilityTrace.StartPos, visibilityTrace.HitPos, 0.4, Color( 128, 255, 128 ), false )
			angle = ((closest:GetPos() + Vector(0,0,36)) - self.head:GetPos()):Angle() + Angle(90,0,0)
			angle:Normalize()
	
	
			local p = math.ApproachAngle( headangle.p, angle.p, self:GetTrackSpeed() * FrameTime() )
			local y = math.ApproachAngle( headangle.y, angle.y, self:GetTrackSpeed() * FrameTime() )
			self.head:SetAngles(Angle(p,y,0))
	
			if math.abs(math.AngleDifference( angle.p, p )) < 2 and math.abs(math.AngleDifference( angle.y, y )) < 2 then
				self:TurretFire(angle - Angle(90,0,0))
			end
			self:NextThink( CurTime())
		else
			debugoverlay.Line( visibilityTrace.StartPos, visibilityTrace.HitPos, 0.4, Color( 255, 128, 128 ), true )
		end
	end


	return true
end

function ENT:HealthThink()

	local healthColour = math.ceil((self:GetBuildingHealth() / self:GetBuildingMaxHealth()) * 255)
	print(self:GetBuildingHealth())
	self:SetColor(Color(healthColour,healthColour,healthColour,255))

	if self:GetBuildingHealth() <= 0 then
		self:Explode()
	end

end

function ENT:OnTakeDamage( damage )
	if damage:GetAttacker():Team() ~= self:GetBuildingTeam() then
		self:SetBuildingHealth(self:GetBuildingHealth() - damage:GetDamage())
		self:NextThink( CurTime())
		print("took " .. damage:GetDamage() .. " damage")
		self:HealthThink()
	end
end