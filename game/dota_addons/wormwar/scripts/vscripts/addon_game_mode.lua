BASE_MODULES = {
	'util',
	'timers',
	'physics',
	'lib.statcollection',
	'abilities',
	'popups',
	'flashutil',
	'wormwar',
}

function Precache( context )
	print("[WORMWAR] Performing pre-load precache")

	-- Particles can be precached individually or by folder
	-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
	PrecacheResource("particle_folder", "particles/spikes", context)
	PrecacheResource("particle_folder", "particles/infest_icon", context)
	--PrecacheResource("particle_folder", "particles/econ/events/killbanners", context)
	--particles/econ/events/killbanners

	PrecacheResource("particle", "particles/items_fx/blademail.vpcf", context)
	PrecacheResource("particle", "particles/custom/courier_international_2013_se.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_huskar_temp/huskar_lifebreak_bloodyend.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bristleback/bristleback_loadout.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/lina/lina_head_headflame/lina_flame_hand_dual_headflame.vpcf", context)

	PrecacheResource("particle", "particles/legion_duel_start_text.vpcf", context)
	PrecacheResource("particle", "particles/legion_duel_start_text_b.vpcf", context)
	PrecacheResource("particle", "particles/legion_duel_start_text_b_glow.vpcf", context)
	PrecacheResource("particle", "particles/legion_duel_start_text_burst.vpcf", context)
	PrecacheResource("particle", "particles/legion_duel_start_text_burst_edge.vpcf", context)
	PrecacheResource("particle", "particles/legion_duel_start_text_burst_flare.vpcf", context)
	PrecacheResource("particle", "particles/legion_duel_start_text_glow.vpcf", context)

	PrecacheResource("particle", "particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace_hit_blood.vpcf", context)

	PrecacheResource("particle", "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf", context)

	PrecacheResource("particle", "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", context)

	--particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf
	PrecacheResource("particle", "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf", context)
	--particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_blood.vpcf
	PrecacheResource("particle", "particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_blood.vpcf", context)
	--particles/units/heroes/hero_life_stealer/life_stealer_infested_unit_icon.vpcf
	PrecacheResource("particle", "particles/units/heroes/hero_life_stealer/life_stealer_infested_unit_icon.vpcf", context)

	PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_forge_spirit_ambient.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_forge_spirit_death.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_forge_spirit_dlight.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_forge_spirit_ambient.vpcf.vpcf", context)

	-- Models can also be precached by folder or individually
	--PrecacheModel should generally used over PrecacheResource for individual models
	--PrecacheResource("model_folder", "particles/heroes/antimage", context)
	--PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
	PrecacheModel("models/props_wildlife/wildlife_hercules_beetle001.vmdl", context)
	PrecacheModel("models/heroes/weaver/weaver_bug.vmdl", context)
	PrecacheModel("models/heroes/invoker/forge_spirit.vmdl", context)
	PrecacheModel("models/props_gameplay/rune_illusion01.vmdl", context)
	PrecacheModel("models/items/hex/sheep_hex/sheep_hex.vmdl", context)
	PrecacheModel("models/items/hex/sheep_hex/sheep_hex_gold.vmdl", context)
	PrecacheModel("models/props_wildlife/wildlife_millipede001.vmdl", context)

	-- Sounds can precached here like anything else
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_weaver.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tinker.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_treant.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_creeps.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/soundevents_custom.vsndevts", context)
	--Hero_Pugna.LifeDrain.Loop
	--Hero_Invoker.ForgeSpirit

	-- Entire items can be precached by name
	-- Abilities can also be precached in this way despite the name
	PrecacheItemByNameSync("example_ability", context)
	PrecacheItemByNameSync("item_example_item", context)

	-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
	-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way

	PrecacheUnitByNameSync("npc_dota_hero_nyx_assassin", context)
end

--MODULE LOADER STUFF by Adynathos
BASE_LOG_PREFIX = '[WW]'


LOG_FILE = "log/WormWar.txt"

InitLogFile(LOG_FILE, "[[ WormWar ]]")

function log(msg)
	print(BASE_LOG_PREFIX .. msg)
	AppendToLogFile(LOG_FILE, msg .. '\n')
end

function err(msg)
	display('[X] '..msg, COLOR_RED)
end

function warning(msg)
	display('[W] '..msg, COLOR_DYELLOW)
end

function display(text, color)
	color = color or COLOR_LGREEN

	log('> '..text)

	Say(nil, color..text, false)
end

local function load_module(mod_name)
	-- load the module in a monitored environment
	local status, err_msg = pcall(function()
		require(mod_name)
	end)

	if status then
		log(' module ' .. mod_name .. ' OK')
	else
		err(' module ' .. mod_name .. ' FAILED: '..err_msg)
	end
end

-- Load all modules
for i, mod_name in pairs(BASE_MODULES) do
	load_module(mod_name)
end
--END OF MODULE LOADER STUFF

-- Create the game mode when we activate
function Activate()
	GameRules.WormWar = WormWar()
	GameRules.WormWar:InitWormWar()
end
