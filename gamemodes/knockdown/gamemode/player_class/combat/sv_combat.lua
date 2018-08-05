util.AddNetworkString("AWARD_SPRITE")
util.AddNetworkString("AWARD_SPRITE_DRAW")
local PLAYER = FindMetaTable( "Player" )
if (!PLAYER) then return end 

function PLAYER:SetFlagCount( flag, count )

	self:SetVar( "FLAG_" .. flag, count )

end

function PLAYER:GetFlagCount( flag )

	return self:GetVar( "FLAG_" .. flag, 0 )

end

function PLAYER:SetLastKill( ctime )

	self:SetVar( "RTime", math.Round( ctime ) )

end

function PLAYER:GetLastKill( )

	return tonumber( self:GetVar( "RTime", 0 ))

end

function PAuthed( ply )

	ply.RailHits = 0
	ply:SetLastKill( 0 )

end

hook.Add("PlayerSpawn", "combat_init", PAuthed)

function SendSound( pl, snd )
	
	net.Start("AnnouncerVoice")
	net.WriteString(snd)
	net.Send(pl)

end

function SendAward( pl, amount, flag, time )

    net.Start( "AWARD_SPRITE" )
	net.WriteTable( { amount = amount, flag = flag } )
	net.Send( pl )
	
	net.Start( "AWARD_SPRITE_DRAW" )
	net.WriteTable( { player = pl, flag = flag, time = CurTime() } )
	net.Broadcast( )

end

--[[---------------------------------------------------------
NAME: CombatRanks
desc:  Calls AWARDS
-----------------------------------------------------------]]
function CombatRanks( victim, attacker, dmginfo )
	local inflictor = dmginfo:GetInflictor()
	if( attacker:IsValid() and attacker:IsPlayer() and attacker != victim ) then	
		local att_t, att_w = attacker:GetLastKill(), inflictor:IsWeapon() and inflictor:GetClass()
		
		if GAMEMODE.TeamBased and attacker:Team() == victim:Team() then return end

		--EXCELLENT
		if( CurTime() - att_t < CARNAGE_REWARD_TIME ) then
			local att_c = attacker:GetFlagCount( EF_AWARD_EXCELLENT )
			att_c = att_c + 1 
			attacker:SetFlagCount( EF_AWARD_EXCELLENT, att_c )
			SendAward( attacker, att_c, EF_AWARD_EXCELLENT )
		end
		--Gauntlet
		if( att_w == "weapon_q3_gauntlet" ) then
			local att_c = attacker:GetFlagCount( EF_AWARD_GAUNTLET )
			att_c = att_c + 1 
			attacker:SetFlagCount( EF_AWARD_GAUNTLET, att_c )
			SendAward( attacker, att_c, EF_AWARD_GAUNTLET )
			SendSound( victim, "humiliation" )
		end
		
		attacker:SetLastKill( math.Round( CurTime() ) )
	end
end

hook.Add("DoPlayerDeath", "combat_kills", CombatRanks)
 
hook.Add("EntityTakeDamage", "a_impressive", function(ent, dmginfo)
	local attacker = dmginfo:GetAttacker()
	local inflictor = dmginfo:GetInflictor()
	local wep = inflictor:IsWeapon() and inflictor:GetClass()
	
	if IsValid(attacker) and attacker:IsPlayer() and wep == "weapon_q3_railgun" and IsValid(ent) and ent:IsPlayer() then
		
		if GAMEMODE.TeamBased and attacker:Team() == ent:Team() then return end
		
		if attacker.RailHits < 2 then
			attacker.RailHits = attacker.RailHits + 1
		else
			attacker.RailHits = 1
		end
		
		if attacker.RailHits > 1 then
			local att_c = attacker:GetFlagCount( EF_AWARD_IMPRESSIVE )
			att_c = att_c + 1
			attacker:SetFlagCount( EF_AWARD_IMPRESSIVE, att_c )
			SendAward( attacker, att_c, EF_AWARD_IMPRESSIVE )
		end
	
	end
end)