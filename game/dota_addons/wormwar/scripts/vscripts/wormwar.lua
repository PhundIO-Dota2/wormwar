print ('[WORMWAR] wormwar.lua' )

NEXT_FRAME = .01
Testing = true
OutOfWorldVector = Vector(5000, 5000, -200)
DrawDebug = false

SheepDeathEffect = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_spiked_carapace_hit_blood.vpcf"
SheepDeathSound = ""

SEGMENTS_TO_WIN = 60
Bounds = {center = Vector(0,0,0), max = 6000, min = -6000}

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
  statcollection.addStats({
    modID = 'XXXXXXXXXXXXXXXXXXX'
  })
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

	for i=0,9 do
		local ply = PlayerResource:GetPlayer(i)
		if ply and ply:GetAssignedHero() == nil then
			CreateHeroForPlayer("npc_dota_hero_nyx_assassin", ply)
		end
	end
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
			self.gameOver = true
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

		local ents = Entities:FindAllInSphere(hero:GetAbsOrigin(), 300)
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
									hero2.lastSquishTime = currTime
									-- get 5% of segments
									local numSegments = #hero.body-1
									local percent = math.ceil(numSegments*.05)
									AddSegments(hero2, percent)
								end
							end
							if not hero.dontKill then
								KillWorm(hero, hero2)
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
									ColorIt("inferno!", "red"), 0, 0)
								KillWorm(hero, hero)
							else
								AddSegments(hero, 4)
								ent.isInferno = false
								ent:EmitSound("n_creep_blackdrake.Death")
								ent:ForceKill(true)
							end
						end

					-- these ents are always safe
					elseif ent.isFood then
						ent.isFood = false;
						AddSegments(hero, ent.foodAmount)
						-- create blood splatter
						--particles/spikes/nyx_assassin_spiked_carapace_hit_blood.vpcf
						ParticleManager:CreateParticle(SheepDeathEffect, PATTACH_ABSORIGIN_FOLLOW, ent)
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
						hero:RemoveAbility("wormwar_empty1")
						hero:AddAbility(runeType)
						hero:FindAbilityByName(runeType):SetLevel(1)
						hero.currentRune = runeType

						-- set underground
						--local entPos = ent:GetAbsOrigin()
						--ent:SetAbsOrigin(Vector(entPos.x, entPos.y, entPos.z-300))
						ent.isRune = false;
						ent:RemoveSelf()
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
		Timers:CreateTimer(1, function()
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

	-- generic stuff for worms when they're in the game for the first time, OR they respawn
	hero.isWorm = true;
	hero.score = 0
	hero.rad = 60 -- lil below ring radius
	hero.body = {[1] = hero}
	hero.lastForwardVect = hero:GetForwardVector()
	hero.lastCameraUpdateTime = GameRules:GetGameTime()
	hero.lastSquishTime = -10
	hero.killer = nil
	--ero.firstOrder = false

	local wormHeadDummy = CreateUnitByName("segment", hero:GetAbsOrigin(), false, nil, hero, hero:GetTeam())
	wormHeadDummy.isWormHeadDummy = true
	wormHeadDummy.hero = hero
	wormHeadDummy.makesWormDie = true
	wormHeadDummy.isSegment = true
	wormHeadDummy:SetOriginalModel("models/development/invisiblebox.vmdl")
	wormHeadDummy:SetModel("models/development/invisiblebox.vmdl")
	hero.wormHeadDummy = wormHeadDummy

	-- Store a reference to the player handle inside this hero handle.
	hero.player = PlayerResource:GetPlayer(hero:GetPlayerID())
	local ply = hero.player -- alias
	self:MakeLabelForPlayer(ply)

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
		
		AddSegments(hero, 1)

		FireGameEvent("cgm_scoreboard_update_user", {playerID = hero:GetPlayerID(), playerName = hero.playerName})

	    --print("hero:GetPlayerID(): " .. hero:GetPlayerID())
	    FireGameEvent("show_main_ability", {pID = hero:GetPlayerID()})

		local spikeParticle = ParticleManager:CreateParticle("particles/spikes/nyx_assassin_spiked_carapace_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
		ParticleManager:SetParticleControlEnt(spikeParticle, 1, hero, 1, "follow_origin", hero:GetAbsOrigin(), true)

		--setup cursor stream
		ply.cursorStream = FlashUtil:RequestDataStream( "cursor_position_world", .01, hero:GetPlayerID(), function(playerID, cursorPos)
			if not hero.orderDetected or not hero:IsAlive() then
				return
			elseif hero.justUsedAbility then
				hero.justUsedAbility = false
				hero.orderDetected = false
				return
			elseif hero.lastAutoMoveTime and GameRules:GetGameTime() - hero.lastAutoMoveTime < .07 then
				hero.orderDetected = false
				return
			elseif hero.firstMoveOrder then
				hero.firstMoveOrder = false
				print("firstMoveOrder")
				hero.orderDetected = false
				return
			end
			hero.orderDetected = false
			--print("moveOrderDetected")


			local validPos = true
			if cursorPos.x > 30000 or cursorPos.y > 30000 or cursorPos.z > 30000 then
				validPos = false
			end
			if validPos then
				hero.currMoveDir = (cursorPos - hero:GetAbsOrigin()):Normalized()
				hero.nextPos = cursorPos

				Timers:RemoveTimer(hero.movementTimer)
				hero.movementTimer = Timers:CreateTimer(function()
					if not hero:IsAlive() then return nil end
					local currPos = hero:GetAbsOrigin()
					if IsPointWithinSquare(currPos, hero.nextPos, 10) or hero:IsIdle() then
						hero.nextPos = currPos + hero.currMoveDir*500
						if not GridNav:IsTraversable(hero.nextPos) then
							--hero.nextPos = currPos + hero.currMoveDir*100
						end
						hero.lastAutoMoveTime = GameRules:GetGameTime()
						ExecuteOrderFromTable({ UnitIndex = hero:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
							Position = hero.nextPos, Queue = false})
						--print("moving.`")
					end
					return NEXT_FRAME
				end)
			end
		end)

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
	for i,segment in ipairs(hero.body) do
		if segment ~= hero then
			ParticleManager:CreateParticle(SheepDeathEffect, PATTACH_ABSORIGIN_FOLLOW, segment)
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

function KillWorm( hero, killer )
	hero:SetTimeUntilRespawn(4)
	ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_blood.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	--particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_blood.vpcf

	if hero.followParticle then
		ParticleManager:DestroyParticle(hero.followParticle, true);
		hero.followParticle = nil
	end

	if hero.almostWon and not GlobalKillSoundPlayed then
		EmitGlobalSound("Denied01")
	end
	GlobalKillSoundPlayed = false
	hero.lastAutoMoveTime = GameRules:GetGameTime()
	hero:Stop()

	-- remove the worm head segment dummy
	hero.wormHeadDummy.makesWormDie = false
	hero.wormHeadDummy.isSegment = false
	hero.wormHeadDummy:ForceKill(true)

	-- remove abil if has
	if not hero:HasAbility("wormwar_empty1") then
		local abilName = hero:GetAbilityByIndex(0):GetAbilityName()
		ReplaceAbility( hero, abilName, "wormwar_empty1" )
	end
	hero:ForceKill(true)
	--[[if hero == killer then
		hero.killer = killer
		hero:ForceKill(true)
	else
		ApplyDamage({ victim = hero, attacker = killer, damage = hero:GetHealth(), damage_type = DAMAGE_TYPE_PURE })
	end]]

	ClearWormBody(hero)
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

		segment.spikeParticle = ParticleManager:CreateParticle("particles/spikes/nyx_assassin_spiked_carapace_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, segment)
		ParticleManager:SetParticleControlEnt(segment.spikeParticle, 1, segment, 1, "follow_origin", segment:GetAbsOrigin(), true)	

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
			Say(nil, hero.colHex .. hero.playerName .. COLOR_NONE .. "needs only 10 segments to win!", false)

		end

	end
	PopupHealing(hero, foodAmount)
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

	--[[ The Unit that was Killed
	local killedUnit = EntIndexToHScript( keys.entindex_killed )
	-- The Killing entity
	local killerEntity = nil

	if keys.entindex_attacker ~= nil then
		killerEntity = EntIndexToHScript( keys.entindex_attacker )
	end

	if killedUnit.killer ~= nil then
		killerEntity = killedUnit.killer
	end

	if killerEntity == nil then return end

	if killedUnit:IsRealHero() then
		--print ("KILLEDKILLER: " .. killedUnit:GetName() .. " -- " .. killerEntity:GetName())
		if killedUnit:GetTeam() == DOTA_TEAM_BADGUYS and killerEntity:GetTeam() == DOTA_TEAM_GOODGUYS then
			self.nRadiantKills = self.nRadiantKills + 1
			if END_GAME_ON_KILLS and self.nRadiantKills >= KILLS_TO_END_GAME_FOR_TEAM then
				GameRules:SetSafeToLeave( true )
				GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
			end
		elseif killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS and killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
			self.nDireKills = self.nDireKills + 1
			if END_GAME_ON_KILLS and self.nDireKills >= KILLS_TO_END_GAME_FOR_TEAM then
				GameRules:SetSafeToLeave( true )
				GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
			end
		end

		if SHOW_KILLS_ON_TOPBAR then
			GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.nDireKills )
			GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.nRadiantKills )
		end
	end]]

	-- Put code here to handle when an entity gets killed
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
	GameRules:SetHideKillMessageHeaders(false)
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

	-- PLAYER COLORS
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

	GlobalDummy = CreateUnitByName("dummy", OutOfWorldVector, false, nil, nil, DOTA_TEAM_GOODGUYS)
	if Testing then
		local center = GetGroundPosition(Vector(0,0,0), GlobalDummy)
		DebugDrawBox(center, Vector(Bounds.min,Bounds.min,0), Vector(Bounds.max,Bounds.max,30), 255, 0, 0, 0, 4000)
	end

	-- spawn the units
	for i=1,200 do
		local pos = GetRandomPos()
		local unitName = GetRandomUnit()
		if unitName == "rune" then
			spawn_rune(pos)
		else
			Creep:Init(unitName, pos)
		end

	end



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

	if RECOMMENDED_BUILDS_DISABLED then
		GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_SHOP_SUGGESTEDITEMS, false )
	end

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
		mode:SetTopBarTeamValuesVisible( false )
		mode:SetFogOfWarDisabled(true)
		mode:SetGoldSoundDisabled( true )
		--mode:SetRemoveIllusionsOnDeath( true )

		-- Hide some HUD elements
		--mode:SetHUDVisible(0, false) --Clock
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
function WormWar:MakeLabelForPlayer( player )
	local hero = player.hero
	if not hero then return end

	local color = self:ColorForPlayer( hero:GetPlayerID() )
	--print("SetCustomHealthLabel")
	hero:SetCustomHealthLabel( hero.playerName, color[1], color[2], color[3] )
end

Creep = {}

function Creep:Init(name, loc)
	local unit = CreateUnitByName(name, loc, true, nil, nil, DOTA_TEAM_NEUTRALS)
	unit.rad = unit:GetPaddedCollisionRadius()
	unit.pos = unit:GetAbsOrigin()

	if name == "pig" then
		unit.isFood = true;
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
		unit:MoveToPosition(unit:GetAbsOrigin() + RandomVector(500))

		return RandomFloat(4, 8);
	end)

	-- TODO: write thing that just takes into acct ring radius for collision detection.
	-- use loadkeyvalues and just search for ringradius. makes shit easier.
	function unit:OnThink(  )
		if DrawDebug then
			DebugDrawCircle(unit:GetAbsOrigin(), Vector(255,0,0), 60, unit.rad, true, .03)
		end
		local unitPos = unit:GetAbsOrigin()
		if unitPos.x > Bounds.max or unitPos.x < Bounds.min or unitPos.y > Bounds.max or unitPos.y < Bounds.min then
			-- TODO
		end

		if unit.isInferno then
			-- if inferno collides with a segment he dies.
			for i2,ent in ipairs(Entities:FindAllInSphere(unit:GetAbsOrigin(), 300)) do
				if IsValidEntity(ent) then
					if ent.isSegment and ent:IsAlive() then
						if circle_circle_collision(unit:GetAbsOrigin(), ent:GetAbsOrigin(), 50, ent:GetPaddedCollisionRadius()) then
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
	rune.isRune = true
	rune.runeType = WormWar.runeTypes[RandomInt(1,#WormWar.runeTypes)]
end

function GetRandomPos(  )
	local spawn_x = RandomInt(Bounds.min, Bounds.max)
	local spawn_y = RandomInt(Bounds.min, Bounds.max)
	local pos = Vector(spawn_x, spawn_y, 0)
	pos = GetGroundPosition(pos, GlobalDummy)
	return pos
end

function GetRandomUnit(  )
	local roll = RandomInt(1, 100)
	local unit = "pig"
	--print("roll is " .. roll)
	-- 10% inferno
	if roll <= 10 then
		unit = "inferno"
	-- 20% chance to spawn pig
	elseif roll <= 30 then
		unit = "pig"
	--10% chance to spawn rune
	elseif roll <= 40 then
		unit = "rune"
	else
		unit = "sheep"
	end
	return unit
end

function OnHeroOutOfBounds( hero )
	hero:EmitSound("Hero_Zuus.ArcLightning.Cast")
	for i=#hero.body, 1, -1 do
		if i ~= 1 then
			local segment = hero.body[i]
			local nextSegment = hero.body[i-1]
			local bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_OVERHEAD_FOLLOW, segment) 
			ParticleManager:SetParticleControl(bolt, 1, nextSegment:GetAbsOrigin())
			nextSegment:EmitSound("Hero_Zuus.ArcLightning.Target")
		end
	end
	EmitGlobalSound("Noob01")
	GlobalKillSoundPlayed = true
	KillWorm(hero, hero)
	GameRules:SendCustomMessage(ColorIt(hero.playerName, hero.colStr) .. " just ran into a wall!", 0, 0)
end