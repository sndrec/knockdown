EF_AWARD_NONE = 0
EF_AWARD_EXCELLENT = 1 --
EF_AWARD_IMPRESSIVE = 2 --
EF_AWARD_GAUNTLET = 3 --

PERS_IMPRESSIVE_COUNT = 0			-- two railgun hits in a row
PERS_EXCELLENT_COUNT = 0			-- two successive kills in a short amount of time

REWARD_SPRITE_TIME = 2 -- time in seconds to hide the AWARD Sprite
CARNAGE_REWARD_TIME = 3


if SERVER then
	AddCSLuaFile()	
	AddCSLuaFile("combat/cl_combat.lua")
	include("combat/sv_combat.lua")
else
	include("combat/cl_combat.lua")
end
