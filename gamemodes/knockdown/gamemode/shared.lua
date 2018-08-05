--[[---------------------------------------------------------

  Sandbox Gamemode

  This is GMod's default gamemode

-----------------------------------------------------------]]

STATE_WAITINGFORPLAYERS = 1
STATE_ROUNDSTARTING = 2
STATE_ROUNDACTIVE = 3
STATE_ROUNDOVER = 4

GAMETIMES = {}
GAMETIMES[STATE_WAITINGFORPLAYERS] = 5
GAMETIMES[STATE_ROUNDSTARTING] = 5
GAMETIMES[STATE_ROUNDACTIVE] = 300
GAMETIMES[STATE_ROUNDOVER] = 5


include( "player_extension.lua" )
include( "persistence.lua" )
include( "save_load.lua" )
include( "player_class/player_sandbox.lua" )
include( "drive/drive_sandbox.lua" )
include( "editor_player.lua" )

--
-- Make BaseClass available
--
DEFINE_BASECLASS( "gamemode_base" )

GM.Name 	= "Knockdown!"
GM.Author 	= "TEAM GARRY"
GM.Email 	= "teamgarry@garrysmod.com"
GM.Website 	= "www.garrysmod.com"

--[[
 Note: This is so that in addons you can do stuff like
 
 if ( !GAMEMODE.IsSandboxDerived ) then return end
 
--]]

GM.IsSandboxDerived = true

cleanup.Register( "props" )
cleanup.Register( "ragdolls" )
cleanup.Register( "effects" )
cleanup.Register( "npcs" )
cleanup.Register( "constraints" )
cleanup.Register( "ropeconstraints" )
cleanup.Register( "sents" )
cleanup.Register( "vehicles" )

local physgun_limited = CreateConVar( "physgun_limited", "0", FCVAR_REPLICATED )

function GM:CreateTeams()
	team.SetUp( 1, "Players", Color(80,80,240), true )
end

function GM:PlayerNoClip( pl, on )

	return false
	
end


hook.Add("Move", "CornerClip", function(pl, move, cmd)
	if pl.knockbackVel then
		local kvel = pl.knockbackVel
		local velocity = move:GetVelocity()
		move:SetVelocity(velocity + kvel)
		pl.knockbackVel = nil
	end
end)

function CappedAccelerate(pl, move, wishdir, wishspeed, accel)
   local playerVelocity = move:GetVelocity()
   local currentspeed = playerVelocity:Dot(wishdir)
   local addspeed = wishspeed - currentspeed
   if (addspeed <= 0) then return end
   local accelspeed = accel * FrameTime() * wishspeed
   if (accelspeed > addspeed) then
      accelspeed = addspeed
   end
   playerVelocity = playerVelocity + (wishdir * accelspeed)
   local oldVel = move:GetVelocity()
   if oldVel:Length2DSqr() > move:GetMaxSpeed() * move:GetMaxSpeed() and playerVelocity:Length2DSqr() > oldVel:Length2DSqr() then
      local newVel = Vector(0,0,playerVelocity.z)
      playerVelocity.z = 0
      local newpower = oldVel:Length2D()
      local newdir = playerVelocity:GetNormalized()
      playerVelocity = newVel + (newpower * newdir)
   end
   move:SetVelocity(playerVelocity)
end

function Accelerate(pl, move, wishdir, wishspeed, accel)
   local playerVelocity = move:GetVelocity()
   local currentspeed = playerVelocity:Dot(wishdir)
   local addspeed = wishspeed - currentspeed
   if (addspeed <= 0) then return end
   if pl:Crouching() then accel = accel / 3 end
   local accelspeed = accel * FrameTime() * wishspeed

   if (accelspeed > addspeed) then
      accelspeed = addspeed
   end
   playerVelocity = playerVelocity + (wishdir * accelspeed)
   move:SetVelocity(playerVelocity)
end

local function TestPlayerPos(pl, pos)
   local stuckTrOrig = util.TraceHull({
      start = pl:GetPos(),
      endpos = pl:GetPos() + Vector(0,0,1),
      filter = pl,
      mins = pl:OBBMins(),
      maxs = pl:OBBMaxs(),
   })
   if not stuckTrOrig.StartSolid then return true end
   local stuckTr = util.TraceHull({
      start = pl:GetPos() + pos,
      endpos = pl:GetPos(),
      filter = pl,
      mins = pl:OBBMins(),
      maxs = pl:OBBMaxs(),
   })
   if stuckTr.StartSolid or stuckTr.AllSolid then return true end
   return false, stuckTr.HitPos
end

function GM:SetupMove(pl, move, cmd)
   if not pl:Active() then return end
end

function GM:Move(pl, move)
	if move:KeyDown(IN_JUMP) and pl:OnGround() then
		pl:SetGroundEntity(nil)
		local trace = util.TraceHull({
			start = move:GetOrigin(),
			endpos = move:GetOrigin() + (move:GetVelocity() * FrameTime()) - Vector(0,0,4),
			maxs = Vector(16, 16, 1),
			mins = Vector(-16, -16, 0),
			filter = pl
		})
	
		if trace.Hit then
			move:SetVelocity(move:GetVelocity() + Vector(0,0,300))
			if CLIENT and IsFirstTimePredicted() then
				pl:EmitSound("player/footsteps/concrete" .. math.random(1, 4) .. ".wav",75,math.random(95, 105))
			end
		end
	end

  	if not pl:OnGround() then
  		local aim = move:GetMoveAngles()
  		local forward, right = aim:Forward(), aim:Right()
  		local fmove = move:GetForwardSpeed()
  		local smove = move:GetSideSpeed()
  		forward[3], right[3] = 0, 0
  		forward:Normalize()
  		right:Normalize()
  		local wishvel = forward * fmove + right * smove
  		wishvel[3] = 0
  		local wishspeed = wishvel:Length()
  	
  		local wishdir = wishvel:GetNormal()
  		Accelerate(pl, move, wishdir, math.min(wishspeed, 400), 0.75)
  	end
	if pl.knockbackVel then
		local kvel = pl.knockbackVel
		local velocity = move:GetVelocity()
		move:SetVelocity(velocity + kvel)
		pl.knockbackVel = nil
	end
	local capZ = move:GetVelocity()
	capZ.z = math.max(capZ.z, -1000)
	move:SetVelocity(capZ)
end

function DoStepup(pl, move, dist, vel, maxIts)
	if vel == nil then vel = move:GetVelocity() end
	vel.z = 0
	local dir = vel:GetNormalized()
	local trace = util.TraceHull({
		start = move:GetOrigin(),
		endpos = move:GetOrigin() + (dir * dist),
		filter = pl,
		mins = pl:OBBMins(),
		maxs = pl:OBBMaxs()
	})

	if trace.Hit == true then
		local totalMove = dist
		--local portion = totalMove * trace.Fraction
		local trace2 = util.TraceHull({
			start = trace.HitPos + dir + Vector(0,0,24),
			endpos = trace.HitPos + dir,
			filter = pl,
			mins = pl:OBBMins(),
			maxs = pl:OBBMaxs()
		})
		if not trace2.AllSolid and trace2.HitNormal.z > 0.95 then
			move:SetOrigin(trace2.HitPos)
			move:SetVelocity(vel)
				--print("stepped up")
			if maxIts > 0 and dist > 0 then
				--print("trying again... " .. maxIts)
				DoStepup(pl, move, dist - 1, vel, maxIts - 1)
			end
		else
			--print("failed step up... desired end position is in world")
		end
	else
		--print("failed step up... no surface detected")
	end
end

hook.Add("SetupMove", "AirStepUp", function(pl, move, cmd)
	if not pl:Alive() then cmd:ClearButtons() cmd:ClearMovement() return end
	if pl:OnGround() then return end
	local vel = move:GetVelocity()
	vel.z = 0
	dist = vel:Length() * FrameTime()
	DoStepup(pl, move, dist, vel, 20)
end)

function WeightedRandom(randTable)
	local total = 0
	local total2 = 0
	local choice = nil
	local choiceKey = nil
	for k, v in pairs(randTable) do
		total = total + v.weight
	end
	--print("total.. " .. total)
	local sharedrand = math.random()
	local rand = sharedrand * total
	--print("rand.. " .. rand)
	for k, v in pairs(randTable) do
		total2 = total2 + v.weight
		if rand < total2 then choice = v choiceKey = k break end
	end
	return choice, choiceKey
end

function WeightedRandomSynced(randTable)
	local total = 0
	local total2 = 0
	local choice = nil
	local choiceKey = nil
	for k, v in pairs(randTable) do
		total = total + v.weight
	end
	--print("total.. " .. total)
	local sharedrand = util.SharedRandom("sharedrand",0,1,CurTime())
	local rand = sharedrand * total
	--print("rand.. " .. rand)
	for k, v in pairs(randTable) do
		total2 = total2 + v.weight
		if rand < total2 then choice = v choiceKey = k break end
	end
	return choice, choiceKey
end

function canSee(pl, ent)
	local entPos = ent:GetPos()
	local tr = util.TraceLine({
		start = pl:GetShootPos(),
		endpos = ent:GetPos(),
		filter = {pl, ent}
	})
	return not tr.Hit
end

function GM:PlayerFootstep(pl, pos, foot, sound, volume, rf)

	if CLIENT then
		pl:EmitSound("player/footsteps/concrete" .. math.random(1, 4) .. ".wav",75,math.random(95, 105))
	end
	return true
end