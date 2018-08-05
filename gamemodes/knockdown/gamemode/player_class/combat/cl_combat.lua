
AnnouncerSoundPlayed = CurTime()
local AnnouncerDelay = 1.5

local lead = false
local tied = false
local lost = false

local THREE_FRAGS = false
local TWO_FRAGS = false
local ONE_FRAGS = false
 
local WARNING_5
local WARNING_1
//local WARNING_30

local Sprite = {}

net.Receive("ResetAnnouncer", function()
	AnnouncerSoundPlayed = CurTime()

	lead = false
	tied = false
	lost = false

	THREE_FRAGS = false
	TWO_FRAGS = false
	ONE_FRAGS = false
	
	WARNING_5 = false
	WARNING_1 = false
	//WARNING_30 = false
end)

function FragsLeft()
	fraglimit = fraglimit or 0
	if CurTime() < AnnouncerSoundPlayed or fraglimit <= 0 then return end
	
	if GAMEMODE.TeamBased then
		local t = {}
		for k,v in ipairs( team.GetAllTeams() ) do
			table.insert( t, { frags = team.TotalFrags(k) , team = k } )
		end
		table.SortByMember( t, "frags" )
		local first = t[1].team

		if( team.TotalFrags(first) == fraglimit - 3 and !THREE_FRAGS ) then
			THREE_FRAGS = true
			surface.PlaySound("feedback/3_frags.wav")
			AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		elseif( team.TotalFrags(first) == fraglimit - 2 and !TWO_FRAGS ) then
			TWO_FRAGS = true
			surface.PlaySound("feedback/2_frags.wav")
			AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		elseif( team.TotalFrags(first) == fraglimit - 1 and !ONE_FRAGS ) then
			ONE_FRAGS = true
			surface.PlaySound("feedback/1_frag.wav")
			AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		end
	else	
		local p = {}
		for k,v in ipairs( player.GetAll() ) do
			table.insert( p, { frags = v:Frags() , player = v } )
		end
		table.SortByMember( p, "frags" )
		local first = p[1].player
		
		if( first:Frags() == fraglimit - 3 and !THREE_FRAGS ) then
			THREE_FRAGS = true
			surface.PlaySound("feedback/3_frags.wav")
			AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		elseif( first:Frags() == fraglimit - 2 and !TWO_FRAGS ) then
			TWO_FRAGS = true
			surface.PlaySound("feedback/2_frags.wav")
			AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		elseif(  first:Frags() == fraglimit - 1 and !ONE_FRAGS ) then
			ONE_FRAGS = true
			surface.PlaySound("feedback/1_frag.wav")
			AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		end
	end
end
hook.Add("Think", "combat_frags", FragsLeft)

local function TimeWarning()
	local cvar_timelimit = cvars.Number("q3_timelimit", 0)
	if #player.GetAll() < 2 or GetGlobalBool("MatchEnd") or cvar_timelimit <= 0 then return end
	local timelimit = math.Round(GetGlobalFloat("Timelimit", 0) - CurTime())
	if timelimit == 300 and !WARNING_5 and cvar_timelimit > 300 then
		WARNING_5 = true
		surface.PlaySound("feedback/5_minute.wav")
		AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
	elseif timelimit == 60 and !WARNING_1 and cvar_timelimit > 60 then
		WARNING_1 = true
		surface.PlaySound("feedback/1_minute.wav")
		AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
	/*elseif timelimit == 30 and !WARNING_30 then
		WARNING_30 = true
		surface.PlaySound("feedback/30_second_warning.wav")
		AnnouncerSoundPlayed = CurTime() + AnnouncerDelay*/
	end	
end
hook.Add("Think", "combat_time", TimeWarning)

function LeadingSound()
	if CurTime() < AnnouncerSoundPlayed then return end
	if( LocalPlayer():Team() == TEAM_SPECTATOR ) then lead = false tied = false lost = false return end
	if GAMEMODE.TeamBased then
		local killer = { }
		for k,v in ipairs( team.GetAllTeams() ) do
			table.insert(killer, { frags = team.TotalFrags(k), t = k } )
		end
		table.SortByMember( killer, "frags" )
		if #team.GetPlayers(TEAM_BLUE) <= 0 or #team.GetPlayers(TEAM_RED) <= 0 then return end

		//taken
		if( !lead and killer[1].frags != killer[2].frags ) then
			lead = true 
			tied = false
			if killer[1].t == TEAM_RED then
				surface.PlaySound("feedback/redleads.wav")
			elseif killer[1].t == TEAM_BLUE then
				surface.PlaySound("feedback/blueleads.wav")
			end
			AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		//tied
		elseif( !tied and killer[1].frags == killer[2].frags ) then
			lead = false
			tied = true
			surface.PlaySound("feedback/teamstied.wav")
			AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		end
		return
	end
	
	local killer = { }
	for k,v in ipairs( player.GetAll() ) do
		table.insert(killer, { k = v:Frags(), p = v } )		
	end
	table.SortByMember( killer, "k" )
	if( #killer <= 1 ) then return end

	 //taken
	if( killer[1].p == LocalPlayer() and !lead and killer[2].p != LocalPlayer() and killer[1].k != killer[2].k ) then
		lead = true 
		tied = false
		lost = false
		surface.PlaySound("feedback/takenlead.wav")
		AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		//lost
	elseif( killer[1].p != LocalPlayer() and !lost and killer[1].k != killer[2].k and (lead or tied) ) then
		lost = true
		lead = false
		tied = false
		surface.PlaySound("feedback/lostlead.wav")
		AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		//tied
	elseif( !tied and killer[1].k == killer[2].k ) then
		if( LocalPlayer() == killer[2].p or LocalPlayer() == killer[1].p  ) then
			tied = true
			lead = false
			lost = false
			surface.PlaySound("feedback/tiedlead.wav")
			AnnouncerSoundPlayed = CurTime() + AnnouncerDelay
		end
	end
end

hook.Add("Think", "combat_sound", LeadingSound)

local medal_excellent = Material("medals/medal_excellent.png")
local medal_impressive = Material("medals/medal_impressive.png")
local medal_gauntlet = Material("medals/medal_gauntlet.png")

function DrawSprites()
	for k,v in ipairs( Sprite ) do
		cam.Start3D(EyePos(), EyeAngles())
		if( IsValid(v.player) and v.player != LocalPlayer() and v.player:Alive() ) then
			if( v.rwardtime + REWARD_SPRITE_TIME > CurTime() ) then
				if( v.flag == EF_AWARD_EXCELLENT ) then 
					render.SetMaterial(medal_excellent)
					render.DrawSprite( v.player:GetPos() + Vector(0,0,70), 16, 16, Color(255,255,255,255) )
				elseif( v.flag == EF_AWARD_IMPRESSIVE ) then  
					render.SetMaterial(medal_impressive)
					render.DrawSprite( v.player:GetPos() + Vector(0,0,70), 16, 16, Color(255,255,255,255) )
				elseif( v.flag == EF_AWARD_GAUNTLET ) then  
					render.SetMaterial(medal_gauntlet)
					render.DrawSprite( v.player:GetPos() + Vector(0,0,70), 16, 16, Color(255,255,255,255) )
				end
			end
		end
		cam.End3D()
	end
end

hook.Add("RenderScreenspaceEffects", "combat_sprite", DrawSprites)

local a

net.Receive("AWARD_SPRITE", function( len, pl )
	local t = net.ReadTable()
	local delay = awardDelay and awardDelay - CurTime() or 0
	timer.Simple(delay, function()
		if a then a:Remove() end
	    a = vgui.Create("medal_frame")
		a:SetSize(ScrW(), 300)
		a:SetPos(ScrW() / 2 - (a:GetWide() / 2), 0.0625 * ScrH())
		a:SetAmount(t.amount)
		a:SetFlag(t.flag)
	end)
	awardDelay = CurTime() + 3
end)

net.Receive("AWARD_SPRITE_DRAW", function( len, pl )
	local t = net.ReadTable()
	table.Empty(Sprite)
	table.insert(Sprite, {player = t.player, flag = t.flag, rwardtime = t.time})
end)