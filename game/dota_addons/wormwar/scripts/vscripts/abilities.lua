function OnSegmentSummoned( keys )
	local segmentCasterDummy = keys.caster
	local worm = segmentCasterDummy.worm
	local hero = worm
	local segment = keys.target
	GlobalDummy.segmentPassive:ApplyDataDrivenModifier(GlobalDummy, segment, "modifier_segment_passive", {})

	segment:SetOwner(hero)
	InitAbilities(segment)
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
		--Say(nil, hero.colHex .. hero.playerName .. COLOR_NONE .. "only needs " .. COLOR_LGREEN .. "10 segments to win! " .. COLOR_RED .. "SQUISH HIM!!" .. COLOR_NONE, false)
		Say(nil, hero.playerName .. " only needs " .. COLOR_LGREEN .. "10 segments to win! " .. COLOR_RED .. "SQUISH HIM!!" .. COLOR_NONE, false)
	end

end

function OnSegmentCasterDummySummoned( keys )
	--print("OnSegmentCasterDummySummoned")
	--DeepPrintTable(keys)
	if keys.target:GetUnitName() == "segment_caster_dummy" then
		--print("Found segment_caster_dummy")
		keys.target.makesWormDie = false
		keys.target.isSegment = false
		keys.target.worm = keys.caster
		keys.caster.segmentCasterDummy = keys.target
		print("P" .. keys.caster:GetPlayerID() .. "OnSegmentCasterDummySummoned")
		GlobalDummy.dummyPassive:ApplyDataDrivenModifier(GlobalDummy, keys.target, "modifier_dummy_passive", {})
	end
end

function worm_on_order( keys )
	-- wait a frame to detect if it was an ability cast order
	keys.caster.orderDetected = true
	if not keys.caster.firstOrder then
		keys.caster.firstOrder = true
	elseif keys.caster.firstOrder and not keys.caster.secondOrder then
		keys.caster.secondOrder = true
	end
end

-- RUNE ACTIVATION ABILS

function Goo_Bomb( keys )
	local caster = keys.caster
	local ability = keys.ability
	local duration = ability:GetSpecialValueFor("duration")

	EmitGlobalSound("Hero_Treant.Overgrowth.Cast")

	--Say(nil, caster.colHex .. caster.playerName .. COLOR_NONE .. "casted a " .. COLOR_GREEN .. "Goo Bomb!" .. COLOR_NONE, false)
	Say(nil, caster.playerName .. COLOR_NONE .. "casted a " .. COLOR_GREEN .. "Goo Bomb!" .. COLOR_NONE, false)

	for _,hero in pairs(WormWar.vHeroes) do
		if hero ~= caster then
			if not hero.underGooBomb then
				hero.underGooBomb = true
				hero:SetBaseMoveSpeed(.25*BASE_WORM_MOVE_SPEED)
				
				-- create goo effect
				ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_loadout.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				hero.gooParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf",
					PATTACH_ABSORIGIN_FOLLOW, hero)

			end

			hero.timeTillRemoveGooBomb = GameRules:GetGameTime() + duration
		end
	end

	ReplaceAbility( caster, "Goo_Bomb", "wormwar_empty1" )
end

function Fiery_Jaw( keys )
	local caster = keys.caster
	local hero = caster
	local ability = keys.ability
	local duration = ability:GetSpecialValueFor("duration")
	--print("Fiery_Jaw casted by P" .. caster:GetPlayerID())

	--Say(nil, caster.colHex .. caster.playerName .. COLOR_NONE .. "activated " .. COLOR_GOLD .. "Fiery Jaw!" .. COLOR_NONE, false)
	Say(nil, caster.playerName .. " activated " .. COLOR_GOLD .. "Fiery Jaw!" .. COLOR_NONE, false)

	-- play effects
	if not hero.fieryJawParticle then
		--hero.fieryJawParticle = ParticleManager:CreateParticle("particles/econ/items/lina/lina_head_headflame/lina_flame_hand_dual_headflame.vpcf", 
		--	PATTACH_OVERHEAD_FOLLOW, hero)
		hero.fieryJawParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_battle_hunger.vpcf", PATTACH_OVERHEAD_FOLLOW, hero)
		hero:EmitSound("DOTA_Item.SoulRing.Activate")
	end

	caster.hasFieryJaw = true
	Timers:RemoveTimer(caster.fieryJawTimer)
	local tick = 0
	caster.fieryJawTimer = Timers:CreateTimer(function()
		if tick == duration then
			caster.hasFieryJaw = false
			-- remove effect
			ParticleManager:DestroyParticle(caster.fieryJawParticle, false);
			--hero:EmitSound("DOTA_Item.Armlet.DeActivate")
			caster.fieryJawParticle = nil
			return nil
			--PopupDamageOverTime(target, amount)
		else
			PopupDamageOverTime(caster, duration-tick)
		end
		tick = tick+1
		return 1
	end)

	ReplaceAbility( caster, "Fiery_Jaw", "wormwar_empty1" )
end

function Segment_Bomb( keys )
	local caster = keys.caster
	local ability = keys.ability

	--Say(nil, caster.colHex .. caster.playerName .. COLOR_NONE .. "casted a " .. COLOR_RED .. "Segment Bomb!" .. COLOR_NONE, false)
	Say(nil, caster.playerName .. " casted a" .. COLOR_RED .. "Segment Bomb!" .. COLOR_NONE, false)

	-- play cast sound
	--caster:EmitSound("Hero_Tinker.Heat-Seeking_Missile")
	EmitGlobalSound("Hero_Gyrocopter.CallDown.Damage")

	for _,hero in ipairs(WormWar.vHeroes) do
		if caster ~= hero then
			local numSegments = #hero.body-1
			local percent = math.ceil(numSegments*.15)
			for i=1,percent do
				local segment = hero.body[1]
				table.remove(hero.body, 1)
				PopupMinus(hero, 1)
				ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, segment)
				Timers:CreateTimer(.3, function()
					ParticleManager:CreateParticle("particles/dire_fx/bad_barracks_destruction_fire2.vpcf", PATTACH_ABSORIGIN_FOLLOW, segment)
				end)
				--ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast.vpcf", PATTACH_ABSORIGIN_FOLLOW, segment)
				KillSegment(segment)
			end
			-- play impact sound
			--hero:EmitSound("Hero_Tinker.Heat-Seeking_Missile.Impact")
		end

	end

	ReplaceAbility( caster, "Segment_Bomb", "wormwar_empty1" )
end

function Crypt_Craving( keys )
	local caster = keys.caster
	local hero = caster
	local ability = keys.ability
	local radius = ability:GetSpecialValueFor("radius")
	--print("Crypt_Craving casted by P" .. caster:GetPlayerID())
	hero.playCryptDeath = false

	--Say(nil, caster.colHex .. caster.playerName .. COLOR_NONE .. "casted " .. COLOR_SPINK .. "Crypt Craving!" .. COLOR_NONE, false)
	Say(nil, caster.playerName .. " casted " .. COLOR_SPINK .. "Crypt Craving!" .. COLOR_NONE, false)

	local foodEnts = {}
	for _,ent in ipairs(Entities:FindAllInSphere(caster:GetAbsOrigin(), radius)) do
		if IsValidEntity(ent) and ent.isFood then
			ent.isFood = false
			--ent.uniqueID = DoUniqueString("uniqueID")
			table.insert(foodEnts, ent)

			-- setup physics
			Physics:Unit(ent)

			-- attach particle effect
			local craveParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", PATTACH_OVERHEAD_FOLLOW, hero)
			ParticleManager:SetParticleControl(craveParticle, 1, ent:GetAbsOrigin())
			ParticleManager:SetParticleControlEnt(craveParticle, 1, ent, 1, "follow_origin", ent:GetAbsOrigin(), true)

			--ent:EmitSound("Hero_Pugna.LifeDrain.Target")

			ent.craveParticle = craveParticle
		end
	end

	if foodEnts == {} then
		return
	end

	--hero:EmitSound("Hero_Pugna.LifeDrain.Cast")
	hero:EmitSound("LifeDrain")

	local entsKilled = 0
	Timers:CreateTimer(function()
		--print("#foodEnts: " .. #foodEnts)
		for _,ent in ipairs(foodEnts) do
			if IsValidEntity(ent) and ent.foodAmount then
				local heroPos = hero:GetAbsOrigin()
				local entPos = ent:GetAbsOrigin()

				-- update pos
				local dir = (heroPos-entPos):Normalized()
				ent:SetPhysicsVelocity(dir*1400)

				if not hero:IsAlive() or circle_circle_collision(heroPos, entPos, hero:GetPaddedCollisionRadius(), ent:GetPaddedCollisionRadius()) then
					entsKilled = entsKilled + 1
					if hero:IsAlive() then
						AddSegments(hero, ent.foodAmount)
					end
					ent.foodAmount = nil
					ParticleManager:DestroyParticle(ent.craveParticle, true);
					-- create blood pool
					ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_open_wounds_blood_lastpool.vpcf", PATTACH_ABSORIGIN, ent)
					-- death effect
					if not hero.playCryptDeath then
						ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
						hero.playCryptDeath = true;
					end

					ent:StopPhysicsSimulation() -- prevent further movement
					ent:ForceKill(true)
				end
			end

		end
		if entsKilled == #foodEnts then
			return nil
		else
			return .03
		end
	end)

	ReplaceAbility( caster, "Crypt_Craving", "wormwar_empty1" )
end

function Reverse( keys )
	local caster = keys.caster
	local hero = caster
	local ability = keys.ability
	--print("Reverse casted by P" .. hero:GetPlayerID())
	local body = hero.body
	local newBody = {}
	local bodyLen = #body

	-- play sound
	hero:EmitSound("Hero_Weaver.TimeLapse")

	-- ensure worm has segments
	if not (bodyLen >= 2) then
		ReplaceAbility( caster, "Reverse", "wormwar_empty1" )
		-- just make him face the opposite direction.
		hero:SetForwardVector(-1*hero:GetForwardVector())
		hero.nextPos = hero:GetAbsOrigin() + hero:GetForwardVector()*500
		hero.currMoveDir = hero:GetForwardVector()
		hero:Stop()
		return
	end

	--hero.reverseCast = true
	--Say(nil, caster.colHex .. caster.playerName .. COLOR_NONE .. "has " .. COLOR_PURPLE .. "reversed " .. COLOR_NONE .. "himself!", false)
	Say(nil, caster.playerName .. " has " .. COLOR_PURPLE .. "reversed " .. COLOR_NONE .. "himself!", false)

	-- determine new facing dir
	local p1 = body[1]:GetAbsOrigin()
	local p2 = body[2]:GetAbsOrigin()
	local newDir = (p1-p2):Normalized()

	local ptr = 1
	for i=bodyLen-1,1,-1 do
		newBody[ptr] = body[i]
		ptr = ptr + 1
	end
	-- last slot is always hero
	newBody[bodyLen] = hero
	hero.body = newBody

	-- teleport hero
	local newPos = p1+newDir*150
	hero:SetAbsOrigin(newPos)
	hero:Stop()
	hero:SetForwardVector(newDir)
	hero.justUsedReverse = true
	hero.currMoveDir = newDir
	hero.nextPos = hero:GetAbsOrigin() + newDir*500

	Timers:CreateTimer(.03, function()
		hero.justUsedReverse = false
	end)

	Timers:CreateTimer(.07, function()
		-- update camera
		caster:AddNewModifier(caster, nil, "modifier_camera_follow", {})
	end)

	ReplaceAbility( caster, "Reverse", "wormwar_empty1" )
end