if SERVER then
	AddCSLuaFile("shared.lua")
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= true
	SWEP.AutoSwitchFrom		= true
else
	SWEP.DrawAmmo			= true
	SWEP.DrawCrosshair		= false
	SWEP.ViewModelFOV		= 65
	SWEP.ViewModelFlip		= false
	SWEP.BobScale			= 0
	SWEP.SwayScale			= .5
end

SWEP.Author					= "Bites"
SWEP.Contact				= ""
SWEP.Purpose				= ""
SWEP.Instructions			= ""
SWEP.Category				= "Knockdown!"
SWEP.Spawnable				= false
SWEP.Primary.Automatic		= true	
SWEP.ViewModel				= ""
SWEP.WorldModel				= "models/weapons/w_357.mdl"

function SWEP:SetupDataTables()
	self:NetworkVar("Int",0,"Uses")
	self:NetworkVar("Int",1,"RandomPick")
end

function SWEP:GetWeaponID()
	self.weapon = self.itemTable[self:GetRandomPick()]
	if self.weapon == nil then
		timer.Simple(0.25,self:GetWeaponID())
	else
		self:SetUses(self.weapon.uses)
	end
end

function SWEP:Initialize()
	if SERVER then
		self:SetNPCMinBurst(30)
		self:SetNPCMaxBurst(30)
		self:SetNPCFireRate(0.01)
	end
	self:WeaponSetup()
	if SERVER then
		weapon, choiceKey = WeightedRandom(self.itemTable)
		self:SetRandomPick(choiceKey)
	end

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		self:PhysicsInitShadow(false, false)
		self.despawnTime = CurTime() + 15
		self.settled = true
		self.dropTime = CurTime()
	end
	self:GetWeaponID()
end

function SWEP:Think()
	if self:GetOwner() and self:GetOwner():IsValid() and self:GetOwner():IsPlayer() then
		self.oldOwner = self:GetOwner()
		return
	else
		if not self.settled then
			local tr = util.TraceLine({
				start = self:GetPos(),
				endpos = self:GetPos() - Vector(0,0,32),
				filter = {self, self.oldOwner}
			})
			if tr.Hit then
				self:PhysicsInitShadow(false, false)
				self.despawnTime = CurTime() + 15
				self.settled = true
			end
			self:NextThink(CurTime())
			return true
		end
		if CurTime() > self.despawnTime then
			self:Remove()
		end
		local tr = util.TraceLine({
			start = self:GetPos() + Vector(0,0,32),
			endpos = self:GetPos() + Vector(0,0,-128),
			filter = self
		})
		if not tr.Hit then
			self:Remove()
		end
		self:NextThink(CurTime() + 0.1)
		return true
	end
end

function SWEP:DestroyItem()
	if SERVER then
		self:GetOwner():SelectWeapon( "weapon_kd_fists" )
		self:Remove()
	end
end

function SWEP:CanPrimaryAttack()
	return true
end

function SWEP:CanSecondaryAttack()
	return true
end

function SWEP:SecondaryAttack()
	if SERVER then
		self:GetOwner():DropWeapon(self)
		self.settled = false
		self.dropTime = CurTime()
	end
end

function SWEP:PrimaryAttack()
	if CurTime() > self:GetNextPrimaryFire() then
		self.weapon.attackFunc()
		self:SetNextPrimaryFire(CurTime() + self.weapon.cooldown)
		if not SERVER then return end
		print(self:GetUses())
		self:SetUses(self:GetUses() - 1)
		print(self:GetUses())
		if self:GetUses() <= 0 then
			self:DestroyItem()
		end
	end
end

function SWEP:CreateHelper()
	if SERVER then
		local newHelper = ents.Create("kd_helper")
		newHelper:SetPos(Vector(0,0,0))
		newHelper:Spawn()
		return newHelper
	end
end

function SWEP:WeaponSetup()
	self.itemTable = {}
	self:DefineWeapon("materials/knockdown/grenade.png", "Impulse Grenades", function() 
		local pl = self:GetOwner()
		self:EmitSound("weapons/slam/throw.wav",75,math.random(120,130),1)
		if SERVER then
			local helper = self:CreateHelper()
			helper.owner = pl
			helper:SetPos(pl:GetShootPos())
			helper.nadeVel = (pl:GetAimVector() * 1000) + Vector(0,0,100)
			helper.deathTime = CurTime() + 5
			helper:SetModel("models/combine_helicopter/helicopter_bomb01.mdl")
			helper:SetDrawModel(true)
			helper:SetModelScale(0.2, 0)
			helper.trail = util.SpriteTrail( helper, 0, Color(255, 255, 255, 100), false, 8, 6, 0.2, 0.01, "materials/trails/smoke.vmt" )
			function helper:ThinkSpecial()
				local trace = util.TraceHull({
					start = self:GetPos(),
					endpos = self:GetPos() + (self.nadeVel * FrameTime()),
					filter = {self.owner, self},
					mins = Vector(-24,-24,-24),
					maxs = Vector(24,24,24)
				})
				self:SetPos(trace.HitPos)
				if trace.Hit then
					local radius = 256
					local orig = self:GetPos()
					for i, v in ipairs(ents.FindInBox(orig - Vector(radius,radius,radius),orig + Vector(radius,radius,radius))) do
						local pos = v:GetPos() + Vector(0,03)
						local dist = orig:Distance(pos)
						local ratio = 1 - (math.min(dist, 256) / 256)
						print(v:GetClass())
						if ratio > 0 then
							if v:IsPlayer() and v:Active() then
								pos = v:GetShootPos()
								v:SetGroundEntity(nil)
								local dir = (pos - orig):GetNormalized()
								local knockback = 1200
								if v == self.owner then
									knockback = 600
								end
								v.knockbackVel = dir * knockback * ratio
							elseif v:GetClass() == "jump_block" then
								print("nice")
								v:ChangeBlockHealth(-250)
							end
						end
					end
					local edat = EffectData()
					edat:SetOrigin(self:GetPos())
					util.Effect("HelicopterMegaBomb",edat)
					self:EmitSound("ambient/explosions/explode_9.wav",75,math.random(190,210),0.8)
					self:Remove()
				else
					self.nadeVel:Add(Vector(0,0,-600 * FrameTime()))
				end
			end
		end
	end, 
	{uses = 5, cooldown = 0.5}, 60)

	self:DefineWeapon("materials/knockdown/impulserifle.png", "Punt Rifle", function() 
		local pl = self:GetOwner()
		if SERVER then
			local tr = util.TraceHull({
				start = pl:GetShootPos(),
				endpos = pl:GetShootPos() + (pl:EyeAngles():Forward() * 4096),
				filter = pl,
				mins = Vector(-8,-8,-8),
				maxs = Vector(8,8,8)
			})
			if tr.Hit then
				if tr.Entity:IsPlayer() and tr.Entity:Active() then
					tr.Entity:SetGroundEntity(nil)
					tr.Entity.knockbackVel = (pl:EyeAngles():Forward() * 320) + Vector(0,0,120)
				elseif tr.Entity:GetClass() == "jump_block" then
					tr.Entity:ChangeBlockHealth(-25)
				end
			end
			--render.DrawBeam( self:GetVector1(), self:GetVector2(), self:GetFloat1(), 0, 1, Color(255,255,255) )
			local helper = self:CreateHelper()
			helper:SetPos(pl:GetShootPos())
			helper:SetString1("sprites/laserbeam")
			helper:SetBeam(true)
			helper:SetVector1(pl:GetShootPos() - Vector(0,0,16))
			helper:SetVector2(tr.HitPos)
			helper:SetFloat1(32)
			helper:SetFloat2(0.25)
			helper.deathTime = CurTime() + 0.25
			function helper:ThinkSpecial()
				local ratio = (helper.deathTime - CurTime()) / 0.25
			end
		end
		if IsFirstTimePredicted() then
			self:EmitSound("npc/waste_scanner/grenade_fire.wav",75,math.random(120,130),0.35)
		end
	end, 
	{uses = 40, cooldown = 0.1}, 50)

	self:DefineWeapon("materials/knockdown/blackhole.png", "Gravity Well", function()
		pl = self:GetOwner()
		if SERVER then
			local helper = self:CreateHelper()
			helper.owner = pl
			helper.players = player.GetAll()
			helper:SetPos(pl:GetShootPos())
			helper.rockVel = (pl:GetAimVector() * 2500)
			helper.deathTime = CurTime() + 5
			helper:SetModel("models/combine_helicopter/helicopter_bomb01.mdl")
			helper:SetDrawModel(true)
			helper:SetModelScale(0.2, 0)
			helper.trail = util.SpriteTrail( helper, 0, Color(255, 255, 255, 100), false, 8, 6, 0.2, 0.01, "materials/trails/smoke.vmt" )
			helper.active = false
			helper.soundTime = CurTime()
			function helper:ThinkSpecial()
				if not self.active then
					local trace = util.TraceHull({
						start = self:GetPos(),
						endpos = self:GetPos() + (self.rockVel * FrameTime()),
						filter = self.players,
						mins = Vector(-4,-4,-4),
						maxs = Vector(4,4,4)
					})
					self:SetPos(trace.HitPos)
					if trace.Hit then
						print("benis")
						print(trace.Entity)
						self.active = true
						self.deathTime = CurTime() + 3
					end
				else
					if CurTime() > self.soundTime then
						self.soundTime = CurTime() + 0.1
						self:EmitSound("buttons/button15.wav",75,40 - (math.sin(CurTime() * 5) * 2),1)
					end
					local orig = self:GetPos()
					for i, v in ipairs(self.players) do
						if v:Active() then
							local pos = v:GetPos()
							local dist = orig:Distance(pos)
							local dir = (orig - pos)
							dir.z = dir.z * 4
							dir:Normalize()
							local ratio = 1 - (math.min(dist, 600) / 600)
							if ratio > 0 then
								v.knockbackVel = dir * 3000 * math.Clamp(ratio, 0.5, 1) * FrameTime()
								v:SetGroundEntity(nil)
							end
						end
					end
				end
			end
		end
		if IsFirstTimePredicted() then
			self:EmitSound("npc/waste_scanner/grenade_fire.wav",75,math.random(240,250),0.5)
		end
	end, 
	{uses = 3, cooldown = 2}, 40)

	self:DefineWeapon("materials/knockdown/disintegrator.png", "Disintegrator", function()
		self:EmitSound("weapons/physcannon/energy_disintegrate5.wav")
		local pl = self:GetOwner()
		if SERVER then
			local tr = pl:GetEyeTrace()
			local beamHelper = self:CreateHelper()
			beamHelper:SetPos(pl:GetShootPos() - Vector(0,0,50))
			beamHelper:SetString1("effects/bluelaser1")
			beamHelper:SetBeam(true)
			beamHelper:SetVector1(pl:GetShootPos() - Vector(0,0,16))
			beamHelper:SetVector2(tr.HitPos)
			beamHelper:SetFloat1(32)
			beamHelper:SetFloat2(1)
			beamHelper.deathTime = CurTime() + 1
			function beamHelper:ThinkSpecial()
				local ratio = (beamHelper.deathTime - CurTime()) / 0.25
			end
			local edat = EffectData()
			edat:SetOrigin(tr.HitPos)
			util.Effect("HelicopterMegaBomb",edat)
			if tr.Hit and tr.Entity:GetClass() == "jump_block" then
				local block = tr.Entity
				local helper = self:CreateHelper()
				helper.effectTarget = block
				helper.deathTime = CurTime() + 2
				helper.disintegrateTime = CurTime() + 1
				local radius = 256
				local orig = tr.HitPos
				for i, v in ipairs(ents.FindInBox(orig - Vector(radius,radius,radius),orig + Vector(radius,radius,radius))) do
					local pos = v:GetPos() + Vector(0,0,3)
					local dist = orig:Distance(pos)
					local ratio = 1 - (math.min(dist, 256) / 256)
					print(v:GetClass())
					if ratio > 0 then
						if v:IsPlayer() and v:Active() then
							pos = v:GetShootPos()
							v:SetGroundEntity(nil)
							local dir = (pos - orig):GetNormalized()
							local knockback = 1000
							if v == self:GetOwner() then
								knockback = 500
							end
							v.knockbackVel = dir * knockback * ratio
						end
					end
				end
				function helper:ThinkSpecial()
					if CurTime() < self.disintegrateTime and self.effectTarget:IsValid() then
						self.effectTarget:ChangeBlockHealth(-self.effectTarget:GetBuildingMaxHealth() * FrameTime())
					else
						if self.effectTarget:IsValid() then
							self.effectTarget:ChangeBlockHealth(-10000)
						end
					end
				end
			end
		end
	end,
	{uses = 5, cooldown = 1.8}, 20)

	self:DefineWeapon("materials/knockdown/hookshot.png", "Hook Shot", 
		function()
			self:EmitSound("weapons/stinger_fire1.wav", 75, math.random(240,255), 0.6)
			local pl = self:GetOwner()
			if SERVER then
				local hookShot = self:CreateHelper()
				local beamHelper = self:CreateHelper()
				hookShot.owner = pl
				hookShot.players = player.GetAll()
				hookShot:SetPos(pl:GetShootPos())
				hookShot.rockVel = (pl:GetAimVector() * 5000)
				hookShot.deathTime = CurTime() + 5
				hookShot:SetModel("models/combine_helicopter/helicopter_bomb01.mdl")
				hookShot:SetDrawModel(true)
				hookShot:SetModelScale(0.4, 0)
				hookShot.active = false
				hookShot.soundTime = CurTime()
				hookShot.life = 1
				hookShot.playerFilter = ents.FindByClass("jump_block")
				table.insert(hookShot.playerFilter, hookShot)
				table.insert(hookShot.playerFilter, hookShot.owner)
				table.insert(hookShot.playerFilter, beamHelper)
				function hookShot:ThinkSpecial()
					local trace = util.TraceHull({
						start = self:GetPos(),
						endpos = self:GetPos() + (self.rockVel * FrameTime()),
						filter = {self.owner},
						mins = Vector(-1,-1,-1),
						maxs = Vector(1,1,1)
					})
					local tracePlayer = util.TraceHull({
						start = self:GetPos(),
						endpos = self:GetPos() + (self.rockVel * FrameTime()),
						filter = self.playerFilter,
						mins = Vector(-40,-40,-40),
						maxs = Vector(40,40,40)
					})
					self:SetPos(trace.HitPos)
					if tracePlayer.Hit then
						if tracePlayer.Entity:IsPlayer() then
							tracePlayer.Entity:SetGroundEntity(nil)
							tracePlayer.Entity:SetVelocity(-tracePlayer.Entity:GetVelocity() + (self.owner:GetShootPos() - self:GetPos()):GetNormalized() * 1200)
							self.deathTime = CurTime()
							self:GetNetEnt1().deathTime = CurTime()
							print("player")
						end
					end
					if trace.Hit and not trace.Entity:IsPlayer() then
						self.owner:SetGroundEntity(nil)
						self.owner:SetVelocity(-self.owner:GetVelocity() + (self.owner:GetShootPos() - self:GetPos()):GetNormalized() * -1200)
						self.deathTime = CurTime()
						self:GetNetEnt1().deathTime = CurTime()
						print("block")
					end
				end
				beamHelper:SetPos(pl:GetShootPos() - Vector(0,0,50))
				beamHelper:SetString1("cable/rope")
				beamHelper:SetBeam(true)
				beamHelper:SetFloat1(16)
				beamHelper:SetFloat2(100)
				beamHelper.deathTime = CurTime() + 5
				beamHelper:SetNetEnt1(hookShot)
				hookShot:SetNetEnt1(beamHelper)
				function beamHelper:ThinkSpecial()
					self:SetVector1(pl:GetShootPos() - Vector(0,0,32))
					self:SetVector2(self:GetNetEnt1():GetPos())
				end
			end
		end, {uses = 3, cooldown = 1}, 30)

end

function SWEP:DefineWeapon(itemimage, name, attackfunction, stats, weight)
	local tempTable = {}
	tempTable.itemImage = Material(itemimage)
	tempTable.attackFunc = attackfunction
	tempTable.weaponName = name
	tempTable.cooldown = stats.cooldown
	tempTable.uses = stats.uses
	tempTable.lastFire = CurTime()
	tempTable.weight = weight
	table.insert(self.itemTable, tempTable)
end

if CLIENT then
	
	function SWEP:Draw()

	end

	function SWEP:DrawWorldModel()
	end

	function SWEP:DrawHUD()
		x, y = ScrW() * 0.5, ScrH() * 0.5 -- Center of screen
		local scale = 12
		surface.SetDrawColor( 255, 255, 255, 255 ) -- Sets the color of the lines we're drawing
		surface.DrawLine( x - scale, y, x, y )
		surface.DrawLine( x + scale, y, x, y )
		surface.DrawLine( x, y - scale, x, y )
		surface.DrawLine( x, y + scale, x, y )

		surface.SetMaterial(self.weapon.itemImage)
		surface.SetDrawColor( 255, 255, 255, 255 )
		local size = ScrW() * 0.15
		surface.DrawTexturedRect( 32, ScrH() - 32 - size, size, size )
		draw.SimpleTextOutlined("Charges: " .. self:GetUses(),"DTMMono",32 + (size * 0.5),ScrH() - size - 48,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_BOTTOM,1,Color(0,0,0))
	end

	function SWEP:PreDrawViewModel(vm, weapon, pl)

	end

else

	function SWEP:Equip(owner)
		self:SetOwner(owner)
	end

end