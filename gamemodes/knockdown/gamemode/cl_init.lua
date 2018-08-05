
--[[---------------------------------------------------------

  Sandbox Gamemode

  This is GMod's default gamemode

-----------------------------------------------------------]]

include( 'shared.lua' )
include( 'cl_spawnmenu.lua' )
include( 'cl_notice.lua' )
include( 'cl_hints.lua' )
include( 'cl_worldtips.lua' )
include( 'cl_search_models.lua' )
include( 'gui/IconEditor.lua' )

--
-- Make BaseClass available
--
DEFINE_BASECLASS( "gamemode_base" )

local physgun_halo = CreateConVar( "physgun_halo", "1", { FCVAR_ARCHIVE }, "Draw the physics gun halo?" )

function GM:Initialize()

	BaseClass.Initialize( self )
	
end


function CreateFonts()
	local textSize = 34
	if ScrW() <= 1280 then
		textSize = textSize * 0.5
	end
	surface.CreateFont( "DTMMono", {
			font = "Determination Mono", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
			extended = false,
			size = textSize,
			weight = 1000,
			blursize = 0,
			scanlines = 0,
			antialias = false,
		} )
	
	surface.CreateFont( "DTMSans", {
			font = "Determination Sans", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
			extended = false,
			size = textSize,
			weight = 1000,
			blursize = 0,
			scanlines = 0,
			antialias = false,
		} )
end

CreateFonts()

net.Receive("CreateClientText", function()

	local textTable = {}
	textTable.text = net.ReadString()
	textTable.time = net.ReadFloat()
	textTable.spawnTime = CurTime()
	textTable.font = net.ReadString()
	textTable.x = net.ReadFloat()
	textTable.y = net.ReadFloat()
	textTable.color = net.ReadColor()
	table.insert(serverClientTextTable, textTable)

end)

serverClientTextTable = {}

function GM:HUDPaint()

	BaseClass.HUDPaint( self )
	local helpSize = ScrW() * 0.1
	draw.RoundedBox(helpSize * 0.15,helpSize * 0.5,-helpSize * 0.15,helpSize,helpSize,Color(0,0,0,130))
	draw.SimpleTextOutlined("F1","DermaLarge",helpSize * 1, helpSize * 0.4,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,Color(0,0,0))
	draw.SimpleTextOutlined("Game Rules","DermaDefault",helpSize * 1, helpSize * 0.6,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,Color(0,0,0))
	
	for i = #serverClientTextTable, 1, -1 do
		local fadeIn = math.min((CurTime() - serverClientTextTable[i].spawnTime) * 30, 1)
		local fadeOut = math.max(((CurTime() + 0.333) - serverClientTextTable[i].time) * 30, 0)
		local alpha = (fadeIn - fadeOut) * 255
		--print(fadeIn, fadeOut)
		draw.SimpleTextOutlined(serverClientTextTable[i].text,serverClientTextTable[i].font,ScrW() * serverClientTextTable[i].x,ScrH() * serverClientTextTable[i].y,Color(serverClientTextTable[i].color.r, serverClientTextTable[i].color.g, serverClientTextTable[i].color.b, alpha),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,Color(0,0,0, alpha))
		if CurTime() > serverClientTextTable[i].time then table.remove(serverClientTextTable, i) end
	end
	local alive = GetGlobalInt("numalive", 0)
	if alive == 0 then return end
	if alive ~= 1 then
		draw.SimpleTextOutlined(GetGlobalInt("numalive", 0) .. " players remaining.","DermaLarge",ScrW() * 0.5, ScrH() * 0.10,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,Color(0,0,0))
	else
		draw.SimpleTextOutlined(GetGlobalInt("numalive", 0) .. " player remaining.","DermaLarge",ScrW() * 0.5, ScrH() * 0.10,Color(255,255,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,Color(0,0,0))
	end
end

function GM:LimitHit( name )

	self:AddNotify( "#SBoxLimit_"..name, NOTIFY_ERROR, 6 )
	surface.PlaySound( "buttons/button10.wav" )

end

net.Receive("PlayClientSound", function()

	sound.PlayURL(net.ReadString(), "", function(station)
	if ( IsValid( station ) ) then

		station:SetPos( LocalPlayer():GetPos() )
		station:SetVolume(0.5)

		station:Play()

	else

		LocalPlayer():ChatPrint( "Invalid URL!" )

	end end)

end)

net.Receive("PlayClientLocalSound", function()

	sound.PlayFile(net.ReadString(), "", function(station)
	if ( IsValid( station ) ) then

		station:SetPos( LocalPlayer():GetPos() )
		station:SetVolume(0.5)

		station:Play()

	else

		LocalPlayer():ChatPrint( "Invalid URL!" )

	end end)

end)

net.Receive("stopsound", function()

	RunConsoleCommand("stopsound")

end)

function GM:UnfrozeObjects( num )

	self:AddNotify( "Unfroze "..num.." Objects", NOTIFY_GENERIC, 3 )
	
	-- Find a better sound :X
	surface.PlaySound( "npc/roller/mine/rmine_chirp_answer1.wav" )

end

function GM:PostDrawTranslucentRenderables(bool, bool2)
	local items = ents.FindByClass("weapon_q3_base")
	render.OverrideDepthEnable( true, true )
	for i, v in ipairs(items) do
		local pl = v:GetOwner()
		if pl ~= LocalPlayer() then
			if pl:IsValid() and canSee(LocalPlayer(), pl) then
				local posTable = (pl:GetPos() + Vector(0,0,90)):ToScreen()
				local size = ScrW() * 0.1
				render.SetMaterial(v.weapon.itemImage)
				render.DrawSprite(pl:GetPos() + Vector(0,0,100),48,48,Color(255,255,255))
			elseif canSee(LocalPlayer(), v) then
				render.SetMaterial(v.weapon.itemImage)
				render.DrawSprite(v:GetPos() + Vector(0,0,math.sin(CurTime() * 3) * 10),64,64,Color(255,255,255))
			end
		end
	end
	render.OverrideDepthEnable( true, false )
end

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true

}

hook.Add( "HUDShouldDraw", "HideHUD", function( name )
	if ( hide[ name ] ) then return false end

	-- Don't return anything here, it may break other addons that rely on this hook.
end )


--[[---------------------------------------------------------
	Draws on top of VGUI..
-----------------------------------------------------------]]
function GM:PostRenderVGUI()

	BaseClass.PostRenderVGUI( self )

end

local bhstop = 0xFFFF - IN_JUMP
local band = bit.band
local shouldjump

function GM:CreateMove(uc)
	
	lp = LocalPlayer()
	
	if !lp:Alive() and lp:Team() != TEAM_SPECTATOR then uc:ClearMovement() end
	
	if lp:WaterLevel() < 2 and lp:Alive() then
		if !lp:InVehicle() and band(uc:GetButtons(), IN_JUMP) > 0 then
			if lp:IsOnGround() then
				shouldjump = nil
			else
				if !shouldjump then return end
				uc:SetButtons( band(uc:GetButtons(), bhstop) )
			end
		end
		
		if !lp:IsOnGround() then
			shouldjump = true
		end
	end
end

--[[---------------------------------------------------------
   Name: gamemode:NetworkEntityCreated()
   Desc: Entity is created over the network
-----------------------------------------------------------]]
function GM:NetworkEntityCreated( ent )

	--
	-- If the entity wants to use a spawn effect
	-- then create a propspawn effect if the entity was
	-- created within the last second (this function gets called
	-- on every entity when joining a server)
	--

	if ( ent:GetSpawnEffect() && ent:GetCreationTime() > (CurTime() - 1.0) ) then
	
		local ed = EffectData()
			ed:SetOrigin( ent:GetPos() )
			ed:SetEntity( ent )
		util.Effect( "propspawn", ed, true, true )

	end

end
