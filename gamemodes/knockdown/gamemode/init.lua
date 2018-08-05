--[[---------------------------------------------------------

  Sandbox Gamemode

  This is GMod's default gamemode

-----------------------------------------------------------]]
util.AddNetworkString("RunServerCommand")
util.AddNetworkString("PlayClientSound")
util.AddNetworkString("PlayClientLocalSound")
util.AddNetworkString("stopsound")
util.AddNetworkString("CreateClientText")
util.AddNetworkString("KDHelper")

-- These files get sent to the client

AddCSLuaFile( "cl_hints.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_notice.lua" )
AddCSLuaFile( "cl_search_models.lua" )
AddCSLuaFile( "cl_spawnmenu.lua" )
AddCSLuaFile( "cl_worldtips.lua" )
AddCSLuaFile( "persistence.lua" )
AddCSLuaFile( "player_extension.lua" )
AddCSLuaFile( "save_load.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "gui/IconEditor.lua" )

include( "shared.lua" )
include( "commands.lua" )
include( "player.lua" )
include( "spawnmenu/init.lua" )
include( "proptablecreator.lua" )

resource.AddFile( "resource/fonts/DeterminationMono.ttf" )
resource.AddFile( "resource/fonts/DeterminationSans.ttf" )
resource.AddFile( "materials/jumpbox1.vmt" )
resource.AddFile( "materials/jumpbox2.vmt" )
resource.AddFile( "materials/jumpbox3.vmt" )
resource.AddFile( "materials/jumpbox4.vmt" )
resource.AddFile( "materials/knockdown/blackhole.png" )
resource.AddFile( "materials/knockdown/disintegrator.png" )
resource.AddFile( "materials/knockdown/grenade.png" )
resource.AddFile( "materials/knockdown/impulserifle.png" )
resource.AddFile( "materials/knockdown/hookshot.png" )
resource.AddFile( "maps/" .. game.GetMap() .. ".bsp" )
resource.AddWorkshop("999854920")

--
-- Make BaseClass available
--
DEFINE_BASECLASS( "gamemode_base" )

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawn( )
   Desc: Called when a player spawns
-----------------------------------------------------------]]

function CreateClientText(pl, text, time, font, posx, posy, color)
	net.Start("CreateClientText")
	net.WriteString(text)
	net.WriteFloat(CurTime() + time)
	net.WriteString(font)
	net.WriteFloat(posx)
	net.WriteFloat(posy)
	net.WriteColor(color)
	if pl == "all" then
		net.Send(player.GetAll())
	else
		net.Send(pl)
	end
end

CreateClientText("all", "And we begin anew.", 3, "DTMMono", 0.5, 0.1, Color(255,255,255))

function GM:PlayerInitialSpawn( pl )
	local plyspeed = 400
	pl:SetWalkSpeed(plyspeed)
	pl:SetRunSpeed(plyspeed / 2)
	pl:SetJumpPower(270)
	pl:SetStepSize(18)
	pl:SetViewOffsetDucked(Vector(0,0,36))
	pl:SetCrouchedWalkSpeed(.2)
	pl:SetDuckSpeed(.15)
	pl:SetUnDuckSpeed(.15)
end


function ExplodePos(pos)
	local e = EffectData()
	e:SetOrigin(pos) 
	util.Effect( "Explosion", e)
end

function GM:GetFallDamage( pl, speed )
	return 0
end

GAMESTATE = {}
GAMESTATE.curState = STATE_WAITINGFORPLAYERS
GAMESTATE.nextRoundTime = CurTime() + GAMETIMES[GAMESTATE.curState]

function attemptBlockSpawn(curPlane, curFloor)
	for n = 1, 100, 1 do
		local foundValidPos = false
		local checkPos = Vector(math.random(-1800,1800), math.random(-1800,1800), curPlane + math.random(-32, 32))
		local tr = util.TraceLine({
			start = checkPos,
			endpos = checkPos + Vector(0,0,1),
			filter = self
		})
		if not tr.Hit then
			foundValidPos = true
		end
		if foundValidPos then 
			local newBlock = ents.Create("jump_block")
			newBlock:SetPos(checkPos)
			newBlock.plane = curPlane
			newBlock.floor = curFloor
			newBlock:Spawn()
			break 
		end
	end
end

SetGlobalInt("numalive", 0)

function RestartRound()
	SetGlobalInt("numalive", 0)
	CreateClientText("all", "The round will begin shortly.", 3, "DTMMono", 0.5, 0.25, Color(255,255,255))
	GAMESTATE.curState = STATE_ROUNDSTARTING
	GAMESTATE.nextRoundTime = CurTime() + GAMETIMES[GAMESTATE.curState]
	for i, v in ipairs(ents.FindByClass("weapon_q3_base")) do
		v:Remove()
	end

	for i, v in ipairs(ents.FindByClass("jump_block")) do
		v:Remove()
	end

	numFloors = 4
	floorTop = 0
	floorBottom = -3800
	local numBlocksPerFloor = 150
	local bottomFloorBlockNumScaleFactor = 0.2
	local numBlocksSpawned = 0

	for i = 1, numFloors, 1 do
		local ratio = (i - 1) / (numFloors - 1)
		local curPlane = Lerp(ratio,floorTop,floorBottom)
		local curDesiredNumBlocks = math.Round(numBlocksPerFloor * Lerp(ratio, 1, bottomFloorBlockNumScaleFactor), 0)
		for b = 1, curDesiredNumBlocks, 1 do
			attemptBlockSpawn(curPlane, i)
		end
	end
	for i, v in ipairs(player.GetAll()) do
		v:Spawn()
		v:StripWeapons()
		v:AddFlags(FL_ATCONTROLS)
	end
end

function GM:ShowHelp(pl)
	if not pl.helpTime then 
		pl.helpTime = 0 
	end
	if pl.helpTime and CurTime() > pl.helpTime then
		pl.helpTime = CurTime() + 20
		CreateClientText(pl, "The game rules are simple!", 3.8, "DTMMono", 0.5, 0.7, Color(255,255,255))
		timer.Simple(3.5, function()
			CreateClientText(pl, "Everybody starts on the top floor.", 3.8, "DTMMono", 0.5, 0.7, Color(255,255,255))
		end)
		timer.Simple(7, function()
			CreateClientText(pl, "Blocks slowly break", 4.8, "DTMMono", 0.5, 0.7, Color(255,255,255))
			CreateClientText(pl, "when they're stood on.", 4.8, "DTMMono", 0.5, 0.735, Color(255,255,255))
		end)
		timer.Simple(11.5, function()
			CreateClientText(pl, "Items spawn that you can use", 4.8, "DTMMono", 0.5, 0.7, Color(255,255,255))
			CreateClientText(pl, "to knock other players down.", 4.8, "DTMMono", 0.5, 0.735, Color(255,255,255))
		end)
		timer.Simple(16, function()
			CreateClientText(pl, "You die when you fall", 4.8, "DTMMono", 0.5, 0.7, Color(255,255,255))
			CreateClientText(pl, "past the bottom floor.", 4.8, "DTMMono", 0.5, 0.735, Color(255,255,255))
		end)
		timer.Simple(20.5, function()
			CreateClientText(pl, "You win if you're", 4.8, "DTMMono", 0.5, 0.7, Color(255,255,255))
			CreateClientText(pl, "the last player standing!", 4.8, "DTMMono", 0.5, 0.735, Color(255,255,255))
		end)
	end
end

function BeginRound()
	CreateClientText("all", "Round START!", 5, "DTMMono", 0.5, 0.25, Color(255,255,255))
	CreateClientText("all", "Don't fall down!", 5, "DTMMono", 0.5, 0.30, Color(255,100,100))
	GAMESTATE.curState = STATE_ROUNDACTIVE
	GAMESTATE.nextRoundTime = CurTime() + GAMETIMES[GAMESTATE.curState]
	nextItemSpawn = CurTime()
	for i, v in ipairs(player.GetAll()) do
		if v:Active() then
			v:Give("weapon_kd_fists")
			v:RemoveFlags(FL_ATCONTROLS)
		end
	end
end

function RoundTick(pls)

	local numAlive = 0
	for i, v in ipairs(pls) do
		if v:Active() then
			numAlive = numAlive + 1
		end
	end
	SetGlobalInt("numalive", numAlive)
	
	if numAlive <= 1 then
		local winner = nil
		for i, v in ipairs(player.GetAll()) do
			if v:Active() then
				winner = v
			end
			v:StripWeapons()
		end
		for i, v in ipairs(ents.FindByClass("weapon_q3_base")) do
			v:Remove()
		end
		if winner then
			CreateClientText("all", winner:Nick() .. " wins!", 3, "DTMMono", 0.5, 0.4, Color(255,255,255))
		end
		GAMESTATE.curState = STATE_ROUNDOVER
		GAMESTATE.nextRoundTime = CurTime() + GAMETIMES[GAMESTATE.curState]
	end

	for i = 1, numFloors, 1 do
		local ratio = (i - 1) / (numFloors - 1)
		local curPlane = Lerp(ratio,floorTop,floorBottom)
		local numAbove = 0
		for n, v in ipairs(pls) do
			if v:Active() and v:GetPos().z > curPlane - 100 then
				numAbove = numAbove + 1
			end
		end
		if numAbove == 1 then
			for f, v in ipairs(ents.FindByClass("jump_block")) do
				if v.floor == i then
					v:ChangeBlockHealth(-(math.random()))
				end
			end
		elseif numAbove == 0 then
			for f, v in ipairs(ents.FindByClass("jump_block")) do
				if v.floor == i then
					v:ChangeBlockHealth(-(math.random() * 5))
				end
			end
		end
	end

	if CurTime() > nextItemSpawn then
		TrySpawnItem()
	end

end

function EndRound()
	CreateClientText("all", "Round over", 3, "DTMMono", 0.5, 0.25, Color(255,255,255))
	GAMESTATE.curState = STATE_ROUNDOVER
	GAMESTATE.nextRoundTime = CurTime() + GAMETIMES[GAMESTATE.curState]
end

function GM:Tick()
	local pls = player.GetAll()
	if CurTime() > GAMESTATE.nextRoundTime then
		if GAMESTATE.curState == STATE_WAITINGFORPLAYERS then
			RestartRound()
		elseif GAMESTATE.curState == STATE_ROUNDSTARTING then
			BeginRound()
		elseif GAMESTATE.curState == STATE_ROUNDACTIVE then
			EndRound()
		elseif GAMESTATE.curState == STATE_ROUNDOVER then
			RestartRound()
		end
	end

	if GAMESTATE.curState == STATE_ROUNDACTIVE then
		RoundTick(pls)
	end
	for i, v in ipairs(ents.FindByClass("weapon_q3_base")) do
		v:Think()
	end
end

function TrySpawnItem()
	local tryPos = Vector(math.random(-1800, 1800),math.random(-1800, 1800),math.random(floorBottom,800))
	local trace = util.TraceLine({
		start = tryPos,
		endpos = tryPos - Vector(0,0,4000),
		filter = player.GetAll()
	})
	if trace.StartSolid then return end
	if trace.Hit then
		local traceHull = util.TraceHull({
			start = tryPos,
			endpos = tryPos - Vector(0,0,4000),
			filter = player.GetAll(),
			mins = Vector(-32,-32,-32),
			maxs = Vector(32,32,32)
		})

		if traceHull.StartSolid then return end
		if traceHull.Hit then
			local newItem = ents.Create("weapon_q3_base")
			newItem:SetPos(traceHull.HitPos + Vector(0,0,32))
			newItem:Spawn()
			nextItemSpawn = CurTime() + 0.5
		else
		end
	end
end

function GM:PlayerTick( pl, mv )
	if pl:Active() and pl:GetPos().z < -5000 then
		pl:Kill()
	end
	local gent = pl:GetGroundEntity()
	if GAMESTATE.curState == STATE_ROUNDACTIVE and gent:IsValid() and gent:GetClass() == "jump_block" then
		if CurTime() > gent.lastStood + 1 then
			gent:SetStandLengthModifier(1)
		end
		if math.abs(pl.oldVel.z) > math.abs(mv:GetVelocity().z) then
			local sub = math.min(math.abs(pl.oldVel.z * 0.3), 500)
			local curHealth = gent:GetBuildingHealth()
			if curHealth > 20 then
				local desHealth = math.max(curHealth - sub, 20)
				gent:SetBuildingHealth(desHealth)
				gent:ChangeBlockHealth(-10)
			end
		end
		gent.lastStood = CurTime()
		gent:ChangeBlockHealth( -(0.15 * gent:GetStandLengthModifier()))
		gent:SetStandLengthModifier(gent:GetStandLengthModifier() + 0.06)
	end
	pl.oldVel = mv:GetVelocity()
end

function GM:PlayerSpawnedProp( pl, model, ent )
	if string.sub( model, 1, 21 ) == "models/platformmaster" then
		ent:SetColor(Color(180,180,180))
		ent:SetMaterial("jumpbox")
	end
end

function GM:CanPlayerSuicide( pl )
	return pl:Active()
end

function GM:PlayerSpawn( pl )

	if pl.initialSpawn then
		pl.initialSpawn = false
		self:PlayerSpawnAsSpectator( pl )
		return
	end

	player_manager.SetPlayerClass( pl, "player_sandbox" )
	
	BaseClass.PlayerSpawn( self, pl )
	pl:SetTeam(1)
	pl:SetCustomCollisionCheck( true )
	pl:CollisionRulesChanged()
	pl:SetHealth(1000)
	pl:SetCanZoom(false)
	pl:SetGroundEntity(game.GetWorld())
	local plyspeed = 400
	pl:SetWalkSpeed(plyspeed)
	pl:SetRunSpeed(plyspeed / 2)
	pl:SetJumpPower(270)
	pl:SetStepSize(18)
	pl:SetViewOffsetDucked(Vector(0,0,36))
	pl:SetCrouchedWalkSpeed(.2)
	pl:SetDuckSpeed(.15)
	pl:SetUnDuckSpeed(.15)
	pl.lastHit = 0

	local spawnHeightMax = 800
	local spawnHeightMin = -200
	for i = 1, 100, 1 do
		local spawnTestPos = Vector(math.random(-1300,1300), math.random(-1300,1300), 0)
		local spawnTrace = util.TraceLine({
			start = spawnTestPos + Vector(0,0,spawnHeightMax),
			endpos = spawnTestPos + Vector(0,0,spawnHeightMin)
		})
		if spawnTrace.StartSolid then return end
		if spawnTrace.Hit then
			local spawnTraceHull = util.TraceHull({
				start = spawnTestPos + Vector(0,0,spawnHeightMax),
				endpos = spawnTestPos + Vector(0,0,spawnHeightMin),
				mins = Vector(-16,-16,0),
				maxs = Vector(16,16,72)
			})
			if spawnTraceHull.StartSolid then return end
			if spawnTraceHull.Hit and spawnTraceHull.HitPos.z > -100 and spawnTraceHull.HitPos.z < 200 then
				pl:SetPos(spawnTraceHull.HitPos + Vector(0,0,1))
				break
			end
		end
	end
end

function EverybodyGetsOne()
	for i, v in ipairs(player.GetAll()) do
		v:Give("weapon_q3_base")
	end
end

function GM:OnPhysgunFreeze( weapon, phys, ent, ply )
	
	-- Don't freeze persistent props (should already be froze)
	if ( ent:GetPersistent() ) then return false end

	BaseClass.OnPhysgunFreeze( self, weapon, phys, ent, ply )

	ply:SendHint( "PhysgunUnfreeze", 0.3 )
	ply:SuppressHint( "PhysgunFreeze" )
	
end

function GM:OnPhysgunReload( weapon, ply )

	local num = ply:PhysgunUnfreeze()
	
	if ( num > 0 ) then
		ply:SendLua( "GAMEMODE:UnfrozeObjects("..num..")" )
	end

	ply:SuppressHint( "PhysgunReload" )

end


function GM:PlayerShouldTakeDamage( ply, attacker )

	return true

end

function GM:PlayerInitialSpawn( pl )

	pl.initialSpawn = true
	
end

function GM:CreateEntityRagdoll( entity, ragdoll )

	-- Replace the entity with the ragdoll in cleanups etc
	undo.ReplaceEntity( entity, ragdoll )
	cleanup.ReplaceEntity( entity, ragdoll )
	
end

function GM:EntityTakeDamage(ent, dmginfo)

	local attacker = dmginfo:GetAttacker()
	local damage = dmginfo:GetDamage()
	local dir = dmginfo:GetDamageForce()
	dir:Normalize()
	local knockback = math.min(damage, 200)
	
	if ent:IsPlayer() and ent:Active() then
		ent.lastHit = CurTime()
		if !attacker:IsWorld() and attacker:GetClass() != "trigger_hurt" then
			local g_knockback = 1000

			local mass = 200

			local kvel = dir * (g_knockback * knockback / mass)
			ent.knockbackVel = kvel
		end
		
		if attacker:IsPlayer() and attacker != ent and damage > 0 then
			local pitch = 114 - dmginfo:GetDamage() * .35
			pitch = math.Clamp(math.floor(pitch), 80, 112)
		end
		
		if ent:HasGodMode() then return true end
	end
	
	local function CheckArmor(ent, damage, dflags)
		local ARMOR_PROTECTION = 0.66

		if !damage or !ent or !ent:IsPlayer() then
			return 0
		end

		//if (dflags & DAMAGE_NO_ARMOR) then
			//return 0
		//end

		// armor
		local count = ent:Armor()
		local save = math.ceil( damage * ARMOR_PROTECTION )
		if (save >= count) then
			save = count
		end

		if (!save) then
			return 0
		end

		ent:SetArmor(ent:Armor() - save)

		return save
	end

	if ent == attacker then
		damage = damage * .5
	end

	if damage < 1 then
		damage = 1
	end
	local take = damage
	local save = 0

	local asave = CheckArmor(ent, take) //, dflags)
	take = take - asave	
	
	if ent:IsPlayer() and ent:Active() then
		if !attacker:IsWorld() then
			local vpunch = dir:Angle() * .01
			vpunch[2] = 0
			vpunch[3] = 0
			ent:SetViewPunchAngles(-vpunch)
			ent:ScreenFade(SCREENFADE.IN, Color(120, 0, 0, 40), damage / 80, 0)
		end
	end
	
	return true
end

function GM:PlayerUnfrozeObject( ply, entity, physobject )

	local effectdata = EffectData()
		effectdata:SetOrigin( physobject:GetPos() )
		effectdata:SetEntity( entity )
	util.Effect( "phys_unfreeze", effectdata, true, true )	
	
end

function GM:PlayerFrozeObject( ply, entity, physobject )

	if ( DisablePropCreateEffect ) then return end
	
	local effectdata = EffectData()
		effectdata:SetOrigin( physobject:GetPos() )
		effectdata:SetEntity( entity )
	util.Effect( "phys_freeze", effectdata, true, true )	
	
end

function GM:PlayerNoClip( pl, desiredState )
	return false
end

function GM:PlayerSpawnAsSpectator(pl)
	pl:Spawn()
	pl:SetPos(Vector(0,0,0))
	pl:Spectate(OBS_MODE_ROAMING)
	pl:StripWeapons()
end

function GM:PlayerDeathThink(pl)

	if CurTime() > pl.spawnTime then
		self:PlayerSpawnAsSpectator(pl)
	end

end
	

function GM:PlayerDeath(victim, inflictor, attacker)

	victim.spawnTime = CurTime() + 3

end

function GM:PlayerCanPickupWeapon( pl, wep )
	print(wep:GetClass())
	if wep:GetClass() == "weapon_q3_base" then
		if pl:HasWeapon("weapon_q3_base") then
			return false
		end
		if CurTime() > wep.dropTime + 1 then
			CreateClientText(pl, "Acquired " .. wep.weapon.weaponName, 3, "DermaLarge", 0.5, 0.6, Color(255,255,255))
			return true
		end
	end
	if wep:GetClass() == "weapon_kd_fists" then
		return true
	end
	return false
end