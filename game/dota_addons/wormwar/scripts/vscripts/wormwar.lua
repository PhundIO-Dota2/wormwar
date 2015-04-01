-- Dota 2 Worm War
-- Developer: Myll
-- Credits to: BMD (Timers/Physics/Barebones), Blizzard Entertainment (Various Assets, WC3 Worm War)
-- ... Noya (code snippets taken from Courier Madness), a_dizzle (Flash Scoreboard), zedor (Flash stuff)
-- If you feel like you should be in the credits let me know.
-- Thanks to everybody who helps spread modding information through moddota.com, Github, IRC, etc.

print ('[WORMWAR] wormwar.lua' )

NEXT_FRAME = .01
Testing = true
TestMoreAbilities = false
OutOfWorldVector = Vector(5000, 5000, -200)
DrawDebug = false
UseCursorStream = false

SEGMENTS_TO_WIN = 60
Bounds = {center = Vector(0,0,0), max = 4000, min = -4000}

ColorStr = 
{	-- This is plyID+1
	[1] = "blue",
	[2] = "cyan",
	[3] = "purple",
	[4] = "yellow",
	[5] = "orange",
	[6] = "pink",
	[7] = "light_green",
	[8] = "sky_blue",
	[9] = "dark_green",
	[10] = "brown",
}

ColorHex = 
{	-- This is plyID+1
	[1] = COLOR_BLUE,
	[2] = COLOR_RED,
	[3] = COLOR_PURPLE,
	[4] = COLOR_DYELLOW,
	[5] = COLOR_ORANGE,
	[6] = COLOR_PINK,
	[7] = COLOR_GREEN,
	[8] = COLOR_SBLUE,
	[9] = COLOR_DGREEN,
	[10] = COLOR_GOLD,
}

if not Testing then
	statcollection.addStats({ modID = 'XXXXXXXXXXXXXXXXXXX' })
	SEGMENTS_TO_WIN = 60
else
	SEGMENTS_TO_WIN = 20
end

-- Generated from template
if WormWar == nil then
	--print ( '[WORMWAR] creating wormwar game mode' )
	WormWar = class({})
end

function WormWar:PostLoadPrecache()
	--print("[WORMWAR] Performing Post-Load precache")

	PrecacheUnitByNameAsync("npc_precache_everything", function(...) end)
end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitWormWar() but needs to be done before everyone loads in.
]]
function WormWar:OnFirstPlayerLoaded()
	--print("[WORMWAR] First Player has loaded")
end

--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function WormWar:OnAllPlayersLoaded()
	--print("[WORMWAR] All Players have loaded into the game")

	PlayerCount = 0
	for i=0,9 do
		local ply = PlayerResource:GetPlayer(i)
		if ply and ply:GetAssignedHero() == nil then
			PlayerCount = PlayerCount + 1
			self.vPlayers[i] = ply
			--local hero = CreateHeroForPlayer("npc_dota_hero_nyx_assassin", ply)
		end
	end

	InitMap()
end

function WormWar:OnWormInGame(hero)
	function hero:OnThink(  )
		-- in this function the hero is definitely a worm.
		if not hero:IsAlive() or self.gameOver then return end
		local currTime = GameRules:GetGameTime()

		-- update score
		hero.score = #hero.body-1
		if hero.score >= SEGMENTS_TO_WIN and not self.gameOver and not Testing then
			ShowCenterMsg(hero.playerName .. " WINS!", 3)
			local lines = 
			{
				[1] = ColorIt("Thank you for playing ", "green") .. ColorIt("Worm War", "orange") .. "!",
				[2] = "Please submit bugs and feedback on the " .. ColorIt("Workshop Forums at www.goo.gl/", "green"),
				[3] =  ColorIt(" ", "green")
			}
			EmitGlobalSound("Wormtastic01")
			local winnerParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_duel_victory.vpcf", PATTACH_OVERHEAD_FOLLOW, hero)

			self.gameOver = true
			Winner = hero
			PlayEndingCinematic()
			return
		end
		if SEGMENTS_TO_WIN-hero.score > 10 and hero.followParticle then
			ParticleManager:DestroyParticle(hero.followParticle, true);
			hero.followParticle = nil
			hero.almostWon = false
		end

		local heroPos = hero:GetAbsOrigin()

		-- check if hero went past the map bounds
		if heroPos.x > Bounds.max or heroPos.x < Bounds.min or heroPos.y > Bounds.max or heroPos.y < Bounds.min then
			OnHeroOutOfBounds(hero)
		end

		local ents = Entities:FindAllInSphere(hero:GetAbsOrigin(), 200)
		--print("num ents: " .. #ents)
		for i2,ent in ipairs(ents) do
			if IsValidEntity(ent) then
				local entPos = ent:GetAbsOrigin()
				local collided = false
				if ent.GetPaddedCollisionRadius ~= nil then
					collided = circle_circle_collision(heroPos, entPos, hero.rad, ent:GetPaddedCollisionRadius())
				end

				if collided then
					if ent.makesWormDie then
						local entOwner = ent:GetOwner()
						-- check if hero ran into a segment
						if ent.isSegment then
							local segment = ent
							local hero2 = segment.hero
							if entOwner == hero then
								local total = #hero.body
								-- the first few segments won't harm the hero if it's his own.
								if segment.isWormHeadDummy or segment == hero.body[total-1] or segment == hero.body[total-2]
									or segment == hero.body[total-3] or segment == hero.body[total-4] then
									--print("not killing.")
									hero.dontKill = true
								end
								if not hero.dontKill then
									-- humiliation sound
									EmitGlobalSound("Humiliation01")
									GlobalKillSoundPlayed = true
									GameRules:SendCustomMessage(ColorIt(hero.playerName, hero.colStr) .. " ran into himself!", 0, 0)
								end
							else
								-- hero got killed by another hero's segment.
								if not hero.dontKill then
									if currTime-hero2.lastSquishTime <= 5 then
										EmitGlobalSound("Multisquish01")
										GlobalKillSoundPlayed = true

									else
										if not hero.almostWon then
											EmitGlobalSound("Squish01")
										end
									end
									GameRules:SendCustomMessage(ColorIt(hero2.playerName, hero2.colStr) .. " just squished " .. 
										ColorIt(hero.playerName, hero.colStr) .. "!", 0, 0)
									hero2.killStreak = hero2.killStreak + 1
									local hero2Pos = hero2:GetAbsOrigin()
									local squishParticle = ParticleManager:CreateParticle("particles/squish_text/tusk_walruspunch_txt_ult.vpcf", PATTACH_ABSORIGIN, hero)
									ParticleManager:SetParticleControl( squishParticle, 2, hero:GetAbsOrigin() )
									--tusk_walruspunch_txt_ult.vpcf
									--PerformKillBanner(hero2.killStreak)

									hero2.lastSquishTime = currTime
									-- get % of segments
									local numSegments = #hero.body-1
									local percent = math.ceil(numSegments*.1)
									AddSegments(hero2, percent)
								end
							end
							if not hero.dontKill then
								KillWorm(hero)
								if not self.firstBlood then
									--PopupKillbanner(hero2, "firstblood")
									self.firstBlood = true
								end
							else
								hero.dontKill = false
							end
						end -- end of ent being a segment
						-- check if ran into head of another worm
						if ent.isWorm then

						end
						if ent.isInferno then
							if not hero.hasFieryJaw then
								EmitGlobalSound("Whoopsie01")
								GlobalKillSoundPlayed = true
								GameRules:SendCustomMessage(ColorIt(hero.playerName, hero.colStr) .. " ran into an " ..
									ColorIt("Inferno!", "red"), 0, 0)
								KillWorm(hero)
							else
								AddSegments(hero, 4)
								ent.isInferno = false
								--ent:EmitSound("n_creep_blackdrake.Death")
								ent:EmitSound("FireSpawnDeath1")
								ent:ForceKill(true)
							end
						end

					-- these ents are always safe
					elseif ent.isFood then
						ent.isFood = false;
						AddSegments(hero, ent.foodAmount)
						-- create blood splatter
						PlayCentaurBloodEffect(ent)
						ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_open_wounds_blood_lastpool.vpcf", PATTACH_ABSORIGIN, ent)
						--ent:CastAbilityImmediately(ent:FindAbilityByName("sheep_death_effect"), 0)

						-- play sound effect
						local unitName = ent:GetUnitName()
						if unitName == "pig" then
							ent:EmitSound("PigDeath")
						elseif unitName == "sheep" or unitName == "golden_sheep" then
							ent:EmitSound("SheepDeath")
						end

						ent:ForceKill(true)
					elseif ent.isRune and hero:HasAbility("wormwar_empty1") then
						local runeType = ent.runeType
						if ForceNextRune and Testing then
							runeType = ForceNextRune
						end
						hero:RemoveAbility("wormwar_empty1")
						hero:AddAbility(runeType)
						hero:FindAbilityByName(runeType):SetLevel(1)
						hero.currentRune = runeType
						hero:EmitSound("Bottle.Cork")
						--EmitSoundOnClient("Bottle.Cork", hero.player)
						ent.isRune = false;
						if RandomInt(1, 100) <= 33 then
							SpawnWormWarUnit(true, "rune") -- helps maintain rune count.
						else
							SpawnWormWarUnit(true, nil)
						end
						ent:RemoveSelf()
						-- set it underground
						--[[local p = ent:GetAbsOrigin()
						ent:SetAbsOrigin(Vector(p.x,p.y,p.z-300))
						ent:ForceKill(true)]]
					end
				end
			end -- endfor
		end 

		-- check if under goo bomb
		if hero.underGooBomb and currTime >= hero.timeTillRemoveGooBomb then
			hero:SetBaseMoveSpeed(BASE_WORM_MOVE_SPEED)
			ParticleManager:DestroyParticle(hero.gooParticle, true);
			hero.underGooBomb = false
		end

		if DrawDebug then
			DebugDrawCircle(heroPos, Vector(0,255,0), 60, hero:GetPaddedCollisionRadius(), true, NEXT_FRAME)
		end

		-- update body positions.
		--if not hero.reverseCast then
		for i,segment in ipairs(hero.body) do
			if i == #hero.body then
				break
			end

			local nextSegment = hero.body[i+1]
			local p1 = segment:GetAbsOrigin()
			local p2 = nextSegment:GetAbsOrigin()
			local sub = p2-p1
			local dir = sub:Normalized()
			local dist = (p2-p1):Length2D()
			--local newPos = p1 + dir*210
			if dist > 130 then
				segment:SetForwardVector(dir)
				segment:SetPhysicsVelocity(hero:GetBaseMoveSpeed()*dir)
				--ExecuteOrderFromTable({ UnitIndex = segment:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = newPos, Queue = false})
			else
				segment:SetPhysicsVelocity(Vector(0,0,0))
			end
		end

		-- update wormheaddummy pos
		if hero.wormHeadDummy then
			hero.wormHeadDummy:SetAbsOrigin(hero.wormHeadDummy.hero:GetAbsOrigin())
		end
	end

	function hero:MovementThink(  )
		local timesDeltaWasZero = 0
		local timesDeltaWasNotZero = 0
		local moveMagnitude = 1000
		hero.movementTimer = Timers:CreateTimer(function()
			if not hero:IsAlive() then return end

			local currPos = hero:GetAbsOrigin()
			local currForward = hero:GetForwardVector()
			if not hero.lastForward then
				hero.lastForward = currForward
			end
			local lastForward = hero.lastForward
			local delta = math.abs(RotationDelta(VectorToAngles(currForward), VectorToAngles(lastForward)).y)
			--print("delta: " .. delta)
			if delta < .001 then
				timesDeltaWasZero = timesDeltaWasZero + 1 -- lets wait a bit before we're sure this unit should be in continuous movement.
				if not hero.inContinuousMovement and timesDeltaWasZero > 2 and hero.secondOrder then
					timesDeltaWasNotZero = 0
					--print("hero.inContinuousMovement")
					hero.nextPos = currPos + currForward*moveMagnitude
					hero.inContinuousMovement = true
				end
			else
				timesDeltaWasNotZero = timesDeltaWasNotZero + 1
				if hero.inContinuousMovement and timesDeltaWasNotZero > 2 then
					timesDeltaWasZero = 0
					hero.inContinuousMovement = false
				end
				if not hero.firstForwardChange and timesDeltaWasNotZero > 2 then
					--print("hero.firstForwardChange")
					hero.firstForwardChange = true
				end
			end

			if hero.inContinuousMovement then
				if hero.firstForwardChange and (hero:IsIdle() or IsPointWithinSquare(currPos, hero.nextPos, 10)) then
					hero.nextPos = currPos + moveMagnitude*currForward
					ExecuteOrderFromTable({ UnitIndex = hero:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
						Position = hero.nextPos, Queue = false})
				end
			end

			hero.lastForward = currForward
			return .03
		end)
	end

	function hero:AutoUpdateCamera(  )
		hero.autoCameraTimer = Timers:CreateTimer(function()
			if hero.inContinuousMovement then
				-- keep moving the cam ahead
				local newCamPos = hero:GetAbsOrigin() + hero:GetForwardVector() * 300
				MovePlayerCameraToPos( hero, newCamPos, false )
			else
				MovePlayerCameraToPos( hero, hero:GetAbsOrigin(), false )
			end

			return .3
		end)
	end

	local lines = {
		ColorIt("Welcome to ", "green") .. ColorIt("Worm War! ", "magenta") .. ColorIt("v0.1", "blue"),
		ColorIt("Developer: ", "green") .. ColorIt("Myll", "orange"),

	}

	if not self.greetPlayers then
		hero:EmitSound("Burrow")

		Timers:CreateTimer(1.2, function()
			EmitGlobalSound("WelcometoWormWar01")
			ShowCenterMsg("WORM WAR", 3)
		end)

		Timers:CreateTimer(4, function()
			for i,line in ipairs(lines) do
				GameRules:SendCustomMessage(line, 0, 0)
			end
		end)

		if Testing then
			Say(nil, "Testing is on.", false)
		end

		-- setup scoreboard timer
		self.scoreboardTimer = Timers:CreateTimer(function()
			for _,hero in ipairs(self.vHeroes) do
				FireGameEvent("cgm_scoreboard_update_score", {playerID=hero:GetPlayerID(), playerScore=hero.score})
			end
			return .25
		end)

		self.greetPlayers = true
	end

	-- Store a reference to the player handle inside this hero handle.
	hero.player = PlayerResource:GetPlayer(hero:GetPlayerID())
	local ply = hero.player -- alias
	-- generic stuff for worms when they're in the game for the first time, OR they respawn
	hero.isWorm = true;
	hero.score = 0
	hero.rad = 60 -- lil below ring radius
	hero.body = {[1] = hero}
	hero.lastCameraUpdateTime = GameRules:GetGameTime()
	hero.lastSquishTime = -50
	hero.firstForwardChange = false
	hero.killStreak = 0
	hero:MovementThink()

	local wormHeadDummy = CreateUnitByName("segment", hero:GetAbsOrigin(), false, nil, hero, hero:GetTeam())
	wormHeadDummy.isWormHeadDummy = true
	wormHeadDummy.hero = hero
	wormHeadDummy.makesWormDie = true
	wormHeadDummy.isSegment = true
	wormHeadDummy:SetOriginalModel("models/development/invisiblebox.vmdl")
	wormHeadDummy:SetModel("models/development/invisiblebox.vmdl")
	hero.wormHeadDummy = wormHeadDummy

	-- Do first time stuff for this player.
	if not ply.firstTime then
		hero.firstMoveOrder = true
		hero.plyID = hero:GetPlayerID()
		hero.colHex = ColorHex[hero.plyID+1]
		hero.colStr = ColorStr[hero.plyID+1]
		-- Store the player's name inside this hero handle.
		hero.playerName = PlayerResource:GetPlayerName(hero.plyID)
		if hero.playerName == nil or hero.playerName == "" then
			hero.playerName = "Bob"
		end
		self:MakeLabelForPlayer(hero)
		-- Store this hero handle in this table.
		table.insert(self.vHeroes, hero)
		ply.worm = hero

		-- Whitespace for scoreboard alignment.
		local whitespace = ""
		for i=1, 24-string.len(hero.playerName) do
			whitespace = whitespace .. " "
		end
		self.whitespace[hero.playerName] = whitespace

		-- set auto camera up
		--hero:AutoUpdateCamera()

		-- Show a popup with game instructions.
	    ShowGenericPopupToPlayer(hero.player, "#wormwar_instructions_title", "#wormwar_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
		
		Timers:CreateTimer(NEXT_FRAME, function()
			AddSegments(hero, 1)
		end)

		FireGameEvent("cgm_scoreboard_update_user", {playerID = hero:GetPlayerID(), playerName = hero.playerName})

	    --print("hero:GetPlayerID(): " .. hero:GetPlayerID())
		if not TestMoreAbilities then
			FireGameEvent("show_main_ability", {pID = hero:GetPlayerID()})
		end
		--local spikeParticle = ParticleManager:CreateParticle("particles/spikes/nyx_assassin_spiked_carapace.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
		--ParticleManager:SetParticleControlEnt(spikeParticle, 1, hero, 1, "follow_origin", hero:GetAbsOrigin(), true)
	    InitAbilities(hero)
		ply.firstTime = true
	end
end

--[[
	This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
	gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
	is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function WormWar:OnGameInProgress()
	--print("[WORMWAR] The game has officially begun")


end

function ClearWormBody( hero )
	PopupMinus(hero, #hero.body-1)
	for i,segment in ipairs(hero.body) do
		if segment ~= hero then
			--local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, segment)
			--ParticleManager:SetParticleControlEnt(particle, 1, segment, 1, "follow_origin", segment:GetAbsOrigin(), true)
			PlayCentaurBloodEffect(segment)
			ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_open_wounds_blood_lastpool.vpcf", PATTACH_ABSORIGIN, segment)
			--ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_dismember.vpcf", PATTACH_ABSORIGIN, segment)
			KillSegment(segment)
		end
	end
	hero.body = {[1] = hero}
end

function KillSegment( segment )
	-- destroy spike particle
	ParticleManager:DestroyParticle(segment.spikeParticle, true);
	-- TODO play blood effect, sounds, etc
	segment.makesWormDie = false
	segment.isSegment = false
	segment:StopPhysicsSimulation()
	segment:ForceKill(true)
end

function KillWorm( hero )
	if not Testing then
		hero:SetTimeUntilRespawn(5)
	else
		hero:SetTimeUntilRespawn(2)
	end

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControlEnt(particle, 1, hero, 1, "follow_origin", hero:GetAbsOrigin(), true)

	if hero.followParticle then
		ParticleManager:DestroyParticle(hero.followParticle, true);
		hero.followParticle = nil
	end

	if hero.almostWon and not GlobalKillSoundPlayed then
		EmitGlobalSound("Denied01")
	end

	hero.almostWon = false
	GlobalKillSoundPlayed = false
	Timers:RemoveTimer(hero.movementTimer)

	-- remove the worm head segment dummy
	hero.wormHeadDummy.makesWormDie = false
	hero.wormHeadDummy.isSegment = false
	hero.wormHeadDummy:ForceKill(true)

	-- remove abil if has
	if not hero:HasAbility("wormwar_empty1") then
		local abilName = hero:GetAbilityByIndex(0):GetAbilityName()
		ReplaceAbility( hero, abilName, "wormwar_empty1" )
	end

	-- play the critter death sounds
	-- store positions for sound dummies.
	local positions = {}
	for i=#hero.body-1, 1, -1 do
		table.insert(positions, 1, hero.body[i]:GetAbsOrigin())
	end

	local ptr = 1
	Timers:CreateTimer(function()
		--print("emitting sound.")
		if ptr > #positions then
			return
		end
		local soundDummy = CreateUnitByName("dummy", positions[ptr], false, nil, nil, DOTA_TEAM_GOODGUYS)
		soundDummy:EmitSound("ScarabDeath1")
		soundDummy:ForceKill(true)
		-- this helps to reduce too many sounds.
		--ptr = ptr + math.ceil(.2*#positions)
		ptr = ptr + 4
		return .05
	end)

	hero:SetRespawnPosition(FindGoodPosition("worm"))

	hero:ForceKill(true)
	ClearWormBody(hero)
	hero.outOfBounds = false
	hero.score = 0

end

function AddSegments( hero, foodAmount )
	for i=1, foodAmount do
		-- add more to the body of the worm
		--models/props_wildlife/wildlife_hercules_beetle001.vmdl
		-- rememeber: head of the body == hero, is at the end of the hero.body table.
		local lastSegment = hero.body[1]
		local pos = lastSegment:GetAbsOrigin() + lastSegment:GetForwardVector()*-160
		local segment = CreateUnitByName("segment", pos, false, nil, hero, hero:GetTeam())
		segment.makesWormDie = true
		segment.isSegment = true
		segment.hero = hero

		segment.spikeParticle = ParticleManager:CreateParticle("particles/spikes/nyx_assassin_spiked_carapace_b.vpcf", PATTACH_ABSORIGIN_FOLLOW, segment)
		ParticleManager:SetParticleControlEnt(segment.spikeParticle, 1, segment, 1, "follow_origin", segment:GetAbsOrigin(), true)

		local col = WormWar:ColorForPlayer(hero.plyID)
		segment:SetRenderColor(col[1], col[2], col[3])

		Physics:Unit(segment)
		segment:SetBaseMoveSpeed(hero:GetBaseMoveSpeed())
		table.insert(hero.body, 1, segment)

		local numSegments = #hero.body-1
		if SEGMENTS_TO_WIN-10 == numSegments then
			EmitGlobalSound("Warning10SegmentsRemaining01")
			hero.followParticle = ParticleManager:CreateParticle("particles/infest_icon/life_stealer_infested_unit.vpcf", PATTACH_OVERHEAD_FOLLOW, hero)
			hero.almostWon = true
			local pos = hero:GetAbsOrigin()
			--ShowCenterMsg(hero.playerName .. " needs only 10 segments to win!", 2)
			Say(nil, hero.colHex .. hero.playerName .. COLOR_NONE .. "needs only " .. COLOR_ORANGE .. "10 segments to win! " ..
				COLOR_RED .. "SQUISH HIM!!", false)

		end

	end
	PopupGoldGain(hero, foodAmount)
end

function WormWar:PlayerSay( keys )
	local ply = keys.ply
	local hero = ply:GetAssignedHero()
	local txt = keys.text

	if keys.teamOnly then
		-- This text was team-only.
	end

	if txt == nil or txt == "" then
		return
	end
	--print("txt: " .. txt)
  	-- At this point we have valid text from a player.
	if txt == "-showbanner" then
		FireGameEvent("show_banner", {})
	end
end

-- Cleanup a player when they leave
function WormWar:OnDisconnect(keys)
	--print('[WORMWAR] Player Disconnected ' .. tostring(keys.userid))
	--PrintTable(keys)

	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid
end

-- The overall game state has changed
function WormWar:OnGameRulesStateChange(keys)
	--print("[WORMWAR] GameRules State Changed")
	--PrintTable(keys)

	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local et = 1
		if self.bSeenWaitForPlayers then
			et = .01
		end
		Timers:CreateTimer("alljointimer", {
			useGameTime = true,
			endTime = et,
			callback = function()
				if PlayerResource:HaveAllPlayersJoined() then
					WormWar:PostLoadPrecache()
					WormWar:OnAllPlayersLoaded()
					return
				end
				return .1 -- Check again later in case more players spawn
			end})
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		WormWar:OnGameInProgress()
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function WormWar:OnNPCSpawned(keys)
	--print("[WORMWAR] NPC Spawned")
	--PrintTable(keys)
	local npc = EntIndexToHScript(keys.entindex)

	if npc:IsRealHero() then
		if npc:GetClassname() == "npc_dota_hero_nyx_assassin" then
			WormWar:OnWormInGame(npc)
		end
	end
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function WormWar:OnEntityHurt(keys)
	--print("[WORMWAR] Entity Hurt")
	--PrintTable(keys)
	local attacker = EntIndexToHScript(keys.entindex_attacker)
	local victim = EntIndexToHScript(keys.entindex_killed)
end

-- An item was picked up off the ground
function WormWar:OnItemPickedUp(keys)
	--print ( '[WORMWAR] OnItemPurchased' )
	--PrintTable(keys)

	local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function WormWar:OnPlayerReconnect(keys)
	--print ( '[WORMWAR] OnPlayerReconnect' )
	--PrintTable(keys)
end

-- An item was purchased by a player
function WormWar:OnItemPurchased( keys )
	--print ( '[WORMWAR] OnItemPurchased' )
	--PrintTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname

	-- The cost of the item purchased
	local itemcost = keys.itemcost

end

-- An ability was used by a player
function WormWar:OnAbilityUsed(keys)
	--print('[WORMWAR] AbilityUsed')
	--PrintTable(keys)
	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
	local hero = player:GetAssignedHero()
	hero.justUsedAbility = true
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function WormWar:OnNonPlayerUsedAbility(keys)
	--print('[WORMWAR] OnNonPlayerUsedAbility')
	--PrintTable(keys)

	local abilityname=  keys.abilityname
end

-- A player changed their name
function WormWar:OnPlayerChangedName(keys)
	--print('[WORMWAR] OnPlayerChangedName')
	--PrintTable(keys)

	local newName = keys.newname
	local oldName = keys.oldName
end

-- A player leveled up an ability
function WormWar:OnPlayerLearnedAbility( keys)
	--print ('[WORMWAR] OnPlayerLearnedAbility')
	--PrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function WormWar:OnAbilityChannelFinished(keys)
	--print ('[WORMWAR] OnAbilityChannelFinished')
	--PrintTable(keys)

	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

-- A player leveled up
function WormWar:OnPlayerLevelUp(keys)
	--print ('[WORMWAR] OnPlayerLevelUp')
	--PrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local level = keys.level
end

-- A player last hit a creep, a tower, or a hero
function WormWar:OnLastHit(keys)
	--print ('[WORMWAR] OnLastHit')
	--PrintTable(keys)

	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
end

-- A tree was cut down by tango, quelling blade, etc
function WormWar:OnTreeCut(keys)
	--print ('[WORMWAR] OnTreeCut')
	--PrintTable(keys)

	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A player took damage from a tower
function WormWar:OnPlayerTakeTowerDamage(keys)
	--print ('[WORMWAR] OnPlayerTakeTowerDamage')
	--PrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function WormWar:OnPlayerPickHero(keys)
	--print ('[WORMWAR] OnPlayerPickHero')
	--PrintTable(keys)

	local heroClass = keys.hero
	local heroEntity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
end

-- A player killed another player in a multi-team context
function WormWar:OnTeamKillCredit(keys)
	--print ('[WORMWAR] OnTeamKillCredit')
	--PrintTable(keys)

	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	local numKills = keys.herokills
	local killerTeamNumber = keys.teamnumber
end


-- An entity died
function WormWar:OnEntityKilled( keys )
	--print( '[WORMWAR] OnEntityKilled Called' )
	--PrintTable( keys )

	local killed = EntIndexToHScript( keys.entindex_killed )
	
	local killer = nil
	if keys.entindex_attacker ~= nil then
		killer = EntIndexToHScript( keys.entindex_attacker )
	end

	if killed.wormWarUnit then
		if killed:GetUnitName() == "inferno" and RandomInt(1, 100) <= 33 then -- helps maintain inferno count.
			SpawnWormWarUnit(true, "inferno")
		else
			SpawnWormWarUnit(true, nil)
		end
	end

	if killed:IsRealHero() then
		
	end

	-- Put code here to handle when an entity gets killed
end

function SpawnWormWarUnit( waitTillSpawn, unitName )
	WormWarUnitCount = WormWarUnitCount - 1
	--print("in entitykilled, WormWarUnitCount: " .. WormWarUnitCount)
	-- spawn another unit a bit after.
	local timeTillSpawn = RandomFloat(3, 6)
	if not waitTillSpawn then
		timeTillSpawn = 0
	end
	Timers:CreateTimer(timeTillSpawn, function()
		local pos = GetRandomPos()
		if not unitName then
			unitName = GetRandomUnit()
		end
		if unitName == "rune" then
			spawn_rune(pos)
		elseif unitName == "inferno" then
			pos = FindGoodPosition("inferno")
			Creep:Init("inferno", pos)
		else
			Creep:Init(unitName, pos)
		end
	end)
end

function FindGoodPosition(unitName)
	local pointNotGood = true
	local offset = 0
	if unitName == "worm" or unitName == "info_player_start" then
		offset = 500 -- dont spawn worms right next to border.
	end
	local pos = GetRandomPos({[1]=offset})
	while pointNotGood do
		--print("pos: " .. VectorString(pos))
		pointNotGood = false
		for i,ent in ipairs(Entities:FindAllInSphere(pos, 160)) do
			if unitName == "worm" then
				-- dont spawn the worm on any other units
				if ent.wormWarUnit or ent.isWorm then
					print("pointNotGood, worm")
					pointNotGood = true
				end
			elseif unitName == "inferno" then
				-- don't spawn infernos on worm heads.
				if ent.isWorm then
					print("pointNotGood, inferno")
					pointNotGood = true
				end
			elseif unitName == "info_player_start" then
				if ent.wormWarUnit or ent:GetClassname() == "info_player_start_*" then
					--print("pointNotGood, info_player_start")
					pointNotGood = true
				end
			end
		end
		pos = GetRandomPos({[1]=offset})
	end
	if unitName == "worm" then
		--print("new pos for worm: " .. VectorString(pos))
	end
	return pos
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function WormWar:InitWormWar()
	WormWar = self
	print('[WORMWAR] Starting to load WormWar gamemode...')

	-- Setup rules
	GameRules:SetHeroRespawnEnabled( true )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetSameHeroSelectionEnabled( true )
	GameRules:SetHeroSelectionTime( 1 )
	GameRules:SetPreGameTime( 0)
	GameRules:SetPostGameTime( 30 )
	GameRules:SetUseBaseGoldBountyOnHeroes(false)
	--GameRules:SetHideKillMessageHeaders(false)
	--print('[WORMWAR] GameRules set')

	InitLogFile( "log/wormwar.txt","")

	-- Event Hooks
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(WormWar, 'OnPlayerLevelUp'), self)
	ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(WormWar, 'OnAbilityChannelFinished'), self)
	ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(WormWar, 'OnPlayerLearnedAbility'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(WormWar, 'OnEntityKilled'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(WormWar, 'OnConnectFull'), self)
	ListenToGameEvent('player_disconnect', Dynamic_Wrap(WormWar, 'OnDisconnect'), self)
	ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(WormWar, 'OnItemPurchased'), self)
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(WormWar, 'OnItemPickedUp'), self)
	ListenToGameEvent('last_hit', Dynamic_Wrap(WormWar, 'OnLastHit'), self)
	ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(WormWar, 'OnNonPlayerUsedAbility'), self)
	ListenToGameEvent('player_changename', Dynamic_Wrap(WormWar, 'OnPlayerChangedName'), self)
	--ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(WormWar, 'OnRuneActivated'), self)
	ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(WormWar, 'OnPlayerTakeTowerDamage'), self)
	ListenToGameEvent('tree_cut', Dynamic_Wrap(WormWar, 'OnTreeCut'), self)
	ListenToGameEvent('entity_hurt', Dynamic_Wrap(WormWar, 'OnEntityHurt'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(WormWar, 'PlayerConnect'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(WormWar, 'OnAbilityUsed'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(WormWar, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(WormWar, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(WormWar, 'OnPlayerPickHero'), self)
	ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(WormWar, 'OnTeamKillCredit'), self)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(WormWar, 'OnPlayerReconnect'), self)

	-- Commands can be registered for debugging purposes or as functions that can be called by the custom Scaleform UI
	Convars:RegisterCommand( "command_example", Dynamic_Wrap(WormWar, 'ExampleConsoleCommand'), "A console command example", 0 )
	Convars:RegisterCommand('force_next_rune', function(...)
		local args = {...}
		table.remove(args,1)
		local cmdPlayer = Convars:GetCommandClient()
		ForceNextRune = args[1]
		print("ForceNextRune: " .. ForceNextRune)
	end, 'Goo_Bomb,Fiery_Jaw,Segment_Bomb,Crypt_Craving,Reverse', 0)

	Convars:RegisterCommand('show_banner', function(...)
		local args = {...}
		table.remove(args,1)
		local cmdPlayer = Convars:GetCommandClient()
		FireGameEvent("show_banner", {})
	end, '', 0)

	Convars:RegisterCommand('test_worm_spawns', function(...)
		local args = {...}
		table.remove(args,1)
		local cmdPlayer = Convars:GetCommandClient()
		for i=1,400 do
			local pos = FindGoodPosition("worm")
			DebugDrawCircle(pos, Vector(0,255,0), 60, 10, true, 4000)
		end

	end, 'Goo_Bomb,Fiery_Jaw,Segment_Bomb,Crypt_Craving,Reverse', 0)

	Convars:RegisterCommand('unload_and_restart', function(...)
		SendToServerConsole("restart")
	end, 'unload and restart', 0)

	Convars:RegisterCommand('player_say', function(...)
		local arg = {...}
		table.remove(arg,1)
		local sayType = arg[1]
		table.remove(arg,1)

		local cmdPlayer = Convars:GetCommandClient()
		keys = {}
		keys.ply = cmdPlayer
		keys.teamOnly = false
		keys.text = table.concat(arg, " ")

		if (sayType == 4) then
			-- Student messages
		elseif (sayType == 3) then
			-- Coach messages
		elseif (sayType == 2) then
			-- Team only
			keys.teamOnly = true
			-- Call your player_say function here like
			self:PlayerSay(keys)
		else
			-- All chat
			-- Call your player_say function here like
			self:PlayerSay(keys)
		end
	end, 'player say', 0)

	-- Fill server with fake clients
	-- Fake clients don't use the default bot AI for buying items or moving down lanes and are sometimes necessary for debugging
	Convars:RegisterCommand('fake', function()
		-- Check if the server ran it
		if not Convars:GetCommandClient() then
			-- Create fake Players
			SendToServerConsole('dota_create_fake_clients')

			Timers:CreateTimer('assign_fakes', {
				useGameTime = false,
				endTime = Time(),
				callback = function(wormwar, args)
					local userID = 20
					for i=0, 9 do
						userID = userID + 1
						-- Check if this player is a fake one
						if PlayerResource:IsFakeClient(i) then
							-- Grab player instance
							local ply = PlayerResource:GetPlayer(i)
							-- Make sure we actually found a player instance
							if ply then
								CreateHeroForPlayer('npc_dota_hero_axe', ply)
								self:OnConnectFull({
									userid = userID,
									index = ply:entindex()-1
								})

								ply:GetAssignedHero():SetControllableByPlayer(0, true)
							end
						end
					end
				end})
		end
	end, 'Connects and assigns fake Players.', 0)

	-- Change random seed
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	--DeepPrintTable(LoadKeyValues("scripts/npc/npc_abilities_custom.txt"))

	-- PLAYER COLORS in RGB
	self.m_TeamColors = {}
	self.m_TeamColors[0] = { 50, 100, 220 } -- 49:100:218
	self.m_TeamColors[1] = { 90, 225, 155 } -- 87:224:154
	self.m_TeamColors[2] = { 170, 0, 160 } -- 171:0:156
	self.m_TeamColors[3] = { 210, 200, 20 } -- 211:203:16
	self.m_TeamColors[4] = { 215, 90, 5 } -- 214:87:8
	self.m_TeamColors[5] = { 210, 100, 150 } -- 210:97:153
	self.m_TeamColors[6] = { 130, 150, 80 } -- 130:154:80
	self.m_TeamColors[7] = { 100, 190, 200 } -- 99:188:206
	self.m_TeamColors[8] = { 5, 110, 50 } -- 7:109:44
	self.m_TeamColors[9] = { 130, 80, 5 } -- 124:75:6

	self.whitespace = {}

	self.m_VictoryMessages = {}
	self.m_VictoryMessages[DOTA_TEAM_GOODGUYS] = "#VictoryMessage_GoodGuys"
	self.m_VictoryMessages[DOTA_TEAM_BADGUYS] = "#VictoryMessage_BadGuys"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_1] = "#VictoryMessage_Custom1"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_2] = "#VictoryMessage_Custom2"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_3] = "#VictoryMessage_Custom3"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_4] = "#VictoryMessage_Custom4"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_5] = "#VictoryMessage_Custom5"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_6] = "#VictoryMessage_Custom6"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_7] = "#VictoryMessage_Custom7"
	self.m_VictoryMessages[DOTA_TEAM_CUSTOM_8] = "#VictoryMessage_Custom8"

	self.m_GatheredShuffledTeams = {}
	self.m_PlayerTeamAssignments = {}
	self.m_NumAssignedPlayers = 0

	self.TEAM_KILLS_TO_WIN = 15

	self.runeTypes =
	{
		[1] = "Goo_Bomb",
		[2] = "Fiery_Jaw", 
		[3] = "Segment_Bomb",
		[4] = "Crypt_Craving",
		[5] = "Reverse",
	}

	GlobalDummy = CreateUnitByName("dummy", Vector(0,0,0), false, nil, nil, DOTA_TEAM_GOODGUYS)
	print("GlobalDummy pos: " .. VectorString(GlobalDummy:GetAbsOrigin()))


	-- Show the ending scoreboard immediately
	GameRules:SetCustomGameEndDelay( 0 )
	GameRules:SetCustomVictoryMessageDuration( 0 )

	-- Main thinker
	Timers:CreateTimer(function()
		for i,hero in ipairs(self.vHeroes) do
			hero:OnThink()
		end

		return NEXT_FRAME
	end)

	self.HeroesKV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	BASE_WORM_MOVE_SPEED = self.HeroesKV["worm"]["MovementSpeed"]

	-- Initialized tables for tracking state
	self.vUserIds = {}
	self.vSteamIds = {}
	self.vBots = {}
	self.vBroadcasters = {}

	self.vPlayers = {}
	self.vHeroes = {}
	self.vRadiant = {}
	self.vDire = {}

	self.nRadiantKills = 0
	self.nDireKills = 0

	self.bSeenWaitForPlayers = false

	--print('[WORMWAR] Done loading WormWar gamemode!\n\n')
end

mode = nil

-- This function is called as the first player loads and sets up the WormWar parameters
function WormWar:CaptureWormWar()
	if mode == nil then
		-- Set WormWar parameters
		mode = GameRules:GetGameModeEntity()
		mode:SetRecommendedItemsDisabled( true )
		--mode:SetCameraDistanceOverride( 1134 )
		mode:SetBuybackEnabled( false )
		mode:SetTopBarTeamValuesOverride ( true )
		mode:SetTopBarTeamValuesVisible( true ) -- this needed for kill banners?
		--mode:SetFogOfWarDisabled(true)
		mode:SetGoldSoundDisabled( true )
		--mode:SetRemoveIllusionsOnDeath( true )

		-- Hide some HUD elements
		--mode:SetHUDVisible(0, false) --Clock

		if not TestMoreAbilities then
			mode:SetHUDVisible(1, false)
			mode:SetHUDVisible(2, false)
			mode:SetHUDVisible(6, false)
			mode:SetHUDVisible(7, false) 
			mode:SetHUDVisible(8, false) 
			mode:SetHUDVisible(9, false)
			mode:SetHUDVisible(11, false)
			mode:SetHUDVisible(12, false)
			mode:SetHUDVisible(5, false) --Inventory
			Convars:SetInt("dota_render_crop_height", 0) -- Renders the bottom part of the screen
			Convars:SetInt("dota_draw_portrait", 0)
			mode:SetHUDVisible( DOTA_HUD_VISIBILITY_SHOP_SUGGESTEDITEMS, false )
		end

		self:OnFirstPlayerLoaded()
	end
end

-- This function is called 1 to 2 times as the player connects initially but before they
-- have completely connected
function WormWar:PlayerConnect(keys)
	--print('[WORMWAR] PlayerConnect')
	--PrintTable(keys)

	if keys.bot == 1 then
		-- This user is a Bot, so add it to the bots table
		self.vBots[keys.userid] = 1
	end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function WormWar:OnConnectFull(keys)
	--print ('[WORMWAR] OnConnectFull')
	--PrintTable(keys)
	WormWar:CaptureWormWar()

	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)

	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	-- Update the user ID table with this user
	self.vUserIds[keys.userid] = ply

	-- Update the Steam ID table
	self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply

	-- If the player is a broadcaster flag it in the Broadcasters table
	if PlayerResource:IsBroadcaster(playerID) then
		self.vBroadcasters[keys.userid] = 1
		return
	end

	if playerID >= 0 and playerID < 10 then
		--CreateHeroForPlayer("npc_dota_hero_nyx_assassin", ply)
	end

end

-- This is an example console command
function WormWar:ExampleConsoleCommand()
	--print( '******* Example Console Command ***************' )
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			-- Do something here for the player who called this command
			PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_viper", 1000, 1000)
		end
	end
	--print( '*********************************************' )
end

---------------------------------------------------------------------------
-- Get the color associated with a given teamID
---------------------------------------------------------------------------
function WormWar:ColorForPlayer( plyID )
	local color = self.m_TeamColors[ plyID ]
	if color == nil then
		color = { 255, 255, 255 } -- default to white
	end
	return color
end

---------------------------------------------------------------------------
-- Put a label over a player's hero so people know who is on what team
---------------------------------------------------------------------------
function WormWar:MakeLabelForPlayer( hero )

	local color = self:ColorForPlayer( hero:GetPlayerID() )
	hero:SetCustomHealthLabel( hero.playerName, color[1], color[2], color[3] )
end

Creep = {}

function Creep:Init(name, loc)
	local unit = CreateUnitByName(name, loc, true, nil, nil, DOTA_TEAM_NEUTRALS)
	unit.rad = unit:GetPaddedCollisionRadius()
	unit.pos = unit:GetAbsOrigin()
	unit.nextPos = unit:GetAbsOrigin()
	unit.wormWarUnit = true
	WormWarUnitCount = WormWarUnitCount + 1
	--print("in creep:init, WormWarUnitCount: " .. WormWarUnitCount)

	if name == "pig" then
		unit.isFood = true
		unit.foodAmount = 2;
	elseif name == "sheep" then
		unit.isSheep = true
		unit.isFood = true
		unit.foodAmount = 1
		--unit.goldenParticle = ParticleManager:CreateParticle("particles/golden_sheep/courier_international_2013_se.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
		--ParticleManager:SetParticleControlEnt(unit.goldenParticle, 1, unit, 1, "follow_origin", unit:GetAbsOrigin(), true)
	elseif name == "inferno" then
		unit.makesWormDie = true
		unit.isInferno = true
		unit:FindAbilityByName("inferno_passive"):SetLevel(1)
		unit:EmitSound("Hero_Invoker.ForgeSpirit")
	end

	Timers:CreateTimer(function()
		if not IsValidEntity(unit) or not unit:IsAlive() then return end
		local nextPos = unit:GetAbsOrigin() + RandomVector(RandomInt(200, 500))
		if unit.isInferno then
			nextPos = unit:GetAbsOrigin() + RandomVector(2000)
		end
		unit.nextPos = nextPos
		unit:MoveToPosition(nextPos)
		if unit.isInferno then
			return RandomFloat(.5, 3)
		end
		return RandomFloat(3, 5);
	end)

	-- TODO: write thing that just takes into acct ring radius for collision detection.
	-- use loadkeyvalues and just search for ringradius. makes shit easier.
	function unit:OnThink(  )
		if DrawDebug then
			DebugDrawCircle(unit:GetAbsOrigin(), Vector(255,0,0), 60, unit.rad, true, .03)
		end
		local unitPos = unit:GetAbsOrigin()
		-- unit dies if he goes out of bounds.
		if unitPos.x > Bounds.max or unitPos.x < Bounds.min or unitPos.y > Bounds.max or unitPos.y < Bounds.min then
			if unit.isInferno then
				unit:EmitSound("FireSpawnDeath1")
				unit.isInferno = false
				unit.makesWormDie = false
			else
				PlayCentaurBloodEffect(unit)
				unit.isFood = false
			end
			ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_OVERHEAD_FOLLOW, unit)
			local bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start_bolt_parent.vpcf", PATTACH_ABSORIGIN, unit)
			ParticleManager:SetParticleControlEnt(bolt, 1, unit, 1, "follow_origin", unit:GetAbsOrigin(), true)

			unit:EmitSound("Hero_Zuus.ArcLightning.Target")
			unit:ForceKill(true)
			return
		end

		if unit.isInferno then
			-- if inferno collides with a segment he dies.
			for i2,ent in ipairs(Entities:FindAllInSphere(unit:GetAbsOrigin(), 300)) do
				if IsValidEntity(ent) then
					if ent.isSegment and ent:IsAlive() then
						if circle_circle_collision(unit:GetAbsOrigin(), ent:GetAbsOrigin(), 50, ent:GetPaddedCollisionRadius()) then
							unit:EmitSound("FireSpawnDeath1")
							unit.isInferno = false
							unit.makesWormDie = false
							unit:ForceKill(true)
						end
					end
				end
			end
		end
		-- we have to handle the sheep animation
		if unit.isSheep then
			if unit:IsIdle() and unit:HasAbility("sheep_run") then
				if unit:HasModifier("modifier_sheep_run") then
					unit:RemoveModifierByName("modifier_sheep_run")
				end
				unit:RemoveAbility("sheep_run")
			elseif not unit:IsIdle() and not unit:HasAbility("sheep_run") then
				unit:AddAbility("sheep_run")
				unit:FindAbilityByName("sheep_run"):SetLevel(1)
			end
		end
	end

	Timers:CreateTimer(function()
		if IsValidEntity(unit) and unit:IsAlive() then
			unit:OnThink()
		else
			--print("removing unit think.")
			return
		end
		return .03
	end)
end

function MovePlayerCameraToPos( hero, pos, force )
	local currTime = GameRules:GetGameTime()
	local diff = currTime-hero.lastCameraUpdateTime
	if diff < 1 and not force then
		return
	end

	if IsValidEntity(hero.cameraDummy) then
		hero.cameraDummy:RemoveSelf()
	end
	hero.cameraDummy = CreateUnitByName("dummy", pos, false, nil, nil, DOTA_TEAM_GOODGUYS)

	PlayerResource:SetCameraTarget(0, hero.cameraDummy)
	hero.lastCameraUpdateTime = currTime

end

function spawn_rune( point )

	local rune = CreateUnitByName("rune", point, true, nil, nil, DOTA_TEAM_NEUTRALS)
	local runeParticle = ParticleManager:CreateParticle("particles/generic_gameplay/rune_illusion.vpcf", PATTACH_CUSTOMORIGIN, rune)
	local runePos = rune:GetAbsOrigin()
	ParticleManager:SetParticleControl(runeParticle, 0, Vector(runePos.x, runePos.y, runePos.z+20))
	rune.isRune = true
	rune.wormWarUnit = true
	rune.runeType = WormWar.runeTypes[RandomInt(1,#WormWar.runeTypes)]
	WormWarUnitCount = WormWarUnitCount + 1
	Timers:CreateTimer(.05, function() rune:EmitSound("General.Illusion.Create") end)
end

function GetRandomPos(...)
	-- ... is just a table.
	local offset = 0
	if ... then
		offset = (...)[1]
	end
	--print("offset is " .. offset)
	local spawn_x = RandomInt(Bounds.min+offset, Bounds.max-offset)
	local spawn_y = RandomInt(Bounds.min+offset, Bounds.max-offset)
	local pos = Vector(spawn_x, spawn_y, 0)
	pos = GetGroundPosition(pos, GlobalDummy)
	return pos
end

function GetRandomUnit(  )
	local roll = RandomInt(1, 80)
	local unit = "pig"
	--print("roll is " .. roll)
	-- 10% inferno
	if roll <= 10 then
		unit = "inferno"
	-- 20% chance to spawn pig
	elseif roll <= 30 then
		unit = "pig"
	elseif roll <= 36 then
		unit = "rune"
	else
		unit = "sheep"
	end
	return unit
end

function OnHeroOutOfBounds( hero )
	hero:EmitSound("Hero_Zuus.ArcLightning.Target")
	EmitGlobalSound("Noob01")
	GlobalKillSoundPlayed = true

	local bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start_bolt_parent.vpcf", PATTACH_ABSORIGIN, hero)
	ParticleManager:SetParticleControlEnt(bolt, 1, hero, 1, "follow_origin", hero:GetAbsOrigin(), true)

	for i=#hero.body, 1, -1 do
		if i ~= 1 then
			local segment = hero.body[i]
			local nextSegment = hero.body[i-1]
			local bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_OVERHEAD_FOLLOW, segment)
			ParticleManager:SetParticleControl(bolt, 1, nextSegment:GetAbsOrigin())
		end
	end

	hero.outOfBounds = true

	KillWorm(hero)

	GameRules:SendCustomMessage(ColorIt(hero.playerName, hero.colStr) .. " just ran into a wall!", 0, 0)
end

function InitMap(  )
	--total map is 8064 (reserve a 64 tile for whatever)
	-- 4 intervals spaced out 2016 units apart.

	-- determine the bounds for the map
	DarkSeerWallIndex = 1
	if Testing then PlayerCount = 6 end
	NumUnits = 30 -- increase by 35 each interval?
	if PlayerCount <= 3 then
		Bounds = {max = 2016}
	elseif PlayerCount <= 6 then
		Bounds = {max = 4032}
		DarkSeerWallIndex = 2
		NumUnits = 60
	elseif PlayerCount <= 9 then
		Bounds = {max = 6048}
		DarkSeerWallIndex = 3
		NumUnits = 90
	elseif PlayerCount <= 12 then
		Bounds = {max = 8064}
		DarkSeerWallIndex = 4
		NumUnits = 120
	end
	Bounds.min = -1*Bounds.max
	WormWarUnitCount = 0

	Pillars = {}
	PillarParticles = {}
	-- move the pillars in the correct pos based off PlayerCount
	for i=1,4 do
		table.insert(Pillars, Entities:FindByName(nil, "pillar_" .. i))
		table.insert(PillarParticles, Entities:FindByName(nil, "pillar_" .. i .. "_particle"))
		local z = GetGroundPosition(Pillars[1]:GetAbsOrigin(), Pillars[1]).z

		-- spawn them, start from top right, go counter-cw
		local offset = 40
		if i == 1 then
			Pillars[1]:SetAbsOrigin(Vector(Bounds.max+offset, Bounds.max+offset,z))
		elseif i == 2 then
			Pillars[2]:SetAbsOrigin(Vector(Bounds.min-offset, Bounds.max+offset,z))
		elseif i == 3 then
			Pillars[3]:SetAbsOrigin(Vector(Bounds.min-offset, Bounds.min-offset,z))
		else
			Pillars[4]:SetAbsOrigin(Vector(Bounds.max+offset, Bounds.min-offset,z))
		end
		local newPos = Pillars[i]:GetAbsOrigin()
		PillarParticles[i]:SetAbsOrigin(Vector(newPos.x, newPos.y, newPos.z+200))
	end

	VisionDummies = {GoodGuys = {}, BadGuys = {}}
	local timeOffset = .03
	-- CREATE vision dummies
	local offset = 1800 --528
	for y=Bounds.max, Bounds.min-1000, -1*offset do
		for x=Bounds.min, Bounds.max+1000, offset do
			Timers:CreateTimer(timeOffset, function()
				--if GridNav:IsTraversable(Vector(x,y,GlobalDummy.z)) and not GridNav:IsBlocked(Vector(x,y,GlobalDummy.z)) then
				local goodguy = CreateUnitByName("vision_dummy", Vector(x,y,GlobalDummy.z), false, nil, nil, DOTA_TEAM_GOODGUYS)
				local badguy = CreateUnitByName("vision_dummy", Vector(x,y,GlobalDummy.z), false, nil, nil, DOTA_TEAM_BADGUYS)
				goodguy.isVisionDummy = true
				badguy.isVisionDummy = true
				table.insert(VisionDummies.GoodGuys, goodguy)
				table.insert(VisionDummies.BadGuys, badguy)
				--DebugDrawCircle(Vector(x,y,GlobalDummy.z), Vector(0,0,255), 10, 1800, true, 4000)
				--end
			end)
			timeOffset = timeOffset + .03
		end
	end


	if Testing then
		local center = GetGroundPosition(Vector(0,0,0), GlobalDummy)
		DebugDrawBox(center, Vector(Bounds.min,Bounds.min,0), Vector(Bounds.max,Bounds.max,30), 255, 0, 0, 0, 4000)
	end

	-- DARK SEER WALL SPAWNS
	BasicForwardVects = 
	{
		[1] = Vector(0,1,0), --up
		[2] = Vector(1,0,0), --right
		[3] = Vector(-1,0,0), -- left
		[4] = Vector(0,-1,0) --down
	}

	GlobalDummy:AddAbility("dark_seer_wall_of_discord_" .. DarkSeerWallIndex)
	local abil = GlobalDummy:FindAbilityByName("dark_seer_wall_of_discord_" .. DarkSeerWallIndex)
	abil:SetLevel(1)

	local ptr = 1
	Timers:CreateTimer(.3, function()
		if ptr > #BasicForwardVects then return end
		GlobalDummy:SetAbsOrigin(Vector(0,0,GlobalDummy.z))
		GlobalDummy:SetForwardVector(BasicForwardVects[ptr])
		if ptr == 1 then
			GlobalDummy:CastAbilityOnPosition(Vector(0,Bounds.max,GlobalDummy.z), abil, 0)
			--DebugDrawBox(Vector(0,Bounds.max,GlobalDummy.z), Vector(-64,-64,0), Vector(64,64,30), 0, 255, 0, 100, 4000)
		elseif ptr == 2 then
			GlobalDummy:CastAbilityOnPosition(Vector(Bounds.max,0,GlobalDummy.z), abil, 0)
			--DebugDrawBox(Vector(0,-1*Bounds.max,GlobalDummy.z), Vector(-64,-64,0), Vector(64,64,30), 0, 0, 255, 100, 4000)
		elseif ptr == 3 then
			--GlobalDummy:CastAbilityOnPosition(Vector(0,-1*Bounds.max,GlobalDummy.z), abil, 0)
			GlobalDummy:CastAbilityOnPosition(Vector(Bounds.min,0,GlobalDummy.z), abil, 0)
		elseif ptr == 4 then
			GlobalDummy:SetForwardVector(BasicForwardVects[4])
			GlobalDummy:SetAbsOrigin(GlobalDummy:GetAbsOrigin() + GlobalDummy:GetForwardVector()*2000)
			--DebugDrawBox(Vector(Bounds.max,0,GlobalDummy.z), Vector(-64,-64,0), Vector(64,64,30), 255, 0, 0, 100, 4000)
			GlobalDummy:CastAbilityOnPosition(Vector(0,Bounds.min,GlobalDummy.z), abil, 0)
		end
		ptr = ptr + 1
		return .3
	end)

	-- spawn the units
	for i=1,NumUnits do
		local pos = GetRandomPos()
		local unitName = GetRandomUnit()
		if unitName == "rune" then
			spawn_rune(pos)
		else
			Creep:Init(unitName, pos)
		end
	end


	for i,ent in ipairs(Entities:FindAllByClassname("info_player_start_*")) do
		local pos = FindGoodPosition("info_player_start")
		ent:SetAbsOrigin(pos)
	end

	--Timers:CreateTimer(1, function()
		for k,ply in pairs(WormWar.vPlayers) do
			if ply ~= nil then
				local hero = CreateHeroForPlayer("npc_dota_hero_nyx_assassin", ply)
			end
		end
		print("initMap complete.")
	--end)

	WormWar.initMap = true
end

-- ty noya
function PlayCentaurBloodEffect( unit )
	local centaur_blood_fx = "particles/units/heroes/hero_centaur/centaur_double_edge_bloodspray_src.vpcf"
	local targetLoc = unit:GetAbsOrigin()
	local blood = ParticleManager:CreateParticle(centaur_blood_fx, PATTACH_CUSTOMORIGIN, unit)
	ParticleManager:SetParticleControl(blood, 0, targetLoc)
	ParticleManager:SetParticleControl(blood, 2, targetLoc+RandomVector(RandomInt(20,100)))
	ParticleManager:SetParticleControl(blood, 4, targetLoc+RandomVector(RandomInt(20,100)))
	ParticleManager:SetParticleControl(blood, 5, targetLoc+RandomVector(RandomInt(20,100)))
end

function PlayEndingCinematic(  )
	-- dota_camera_pitch_max default = 50
	-- dota_camera_yaw default = 90
	-- CAMERA_DISTANCE_OVERRIDE = 1400
	local camera_loop = {}
	camera_loop.pitch_max = 50 --{-100 to 100}, 
	camera_loop.yaw = 90 --{0 to 360}, 
	camera_loop.distance = 1400
	SendToConsole("r_farz 5000")

	for i=1,100 do

		Timers:CreateTimer(i*0.03, function()

			camera_loop.pitch_max = camera_loop.pitch_max - 0.2 --up to 10
			camera_loop.yaw = camera_loop.yaw + 1.8 --up to 270
			camera_loop.distance = camera_loop.distance - 6 --1400 to 800

			SendToConsole("dota_camera_pitch_max "..camera_loop.pitch_max)
			SendToConsole("dota_camera_yaw "..camera_loop.yaw)
			mode:SetCameraDistanceOverride( camera_loop.distance )

		end)
	end

	-- 10 sec later, rotate another 180, from 270 to 450
	Timers:CreateTimer(10.0, function() 
		for i=1,100 do
			Timers:CreateTimer(i*0.03, function()

				camera_loop.yaw = camera_loop.yaw + 1.8
				camera_loop.distance = camera_loop.distance + 6 --1400 to 800

				--SendToConsole("dota_camera_pitch_max "..camera_loop.pitch_max)
				SendToConsole("dota_camera_yaw "..camera_loop.yaw)
				mode:SetCameraDistanceOverride( camera_loop.distance )
			end)
		end		
	end)
end

function PerformKillBanner( streak )
	

end