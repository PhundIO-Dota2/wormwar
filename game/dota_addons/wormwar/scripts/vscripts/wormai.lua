WormBot = {}

function WormBot:Init(worm)
	--print("WormBot:Init")
	worm.isBot = true

	function worm:OnTargetNotFound(  )
		-- do some move logic
		worm.nextMovePos = nil
		local currTime = GameRules:GetGameTime()
		local wormPos = worm:GetAbsOrigin()
		if #worm.nearbyBadGuys > 0 then
			local someBadGuy = worm.nearbyBadGuys[RandomInt(1, #worm.nearbyBadGuys)]
			local dir = (wormPos-someBadGuy:GetAbsOrigin()):Normalized()
			worm.nextMovePos = wormPos + dir*300
		else
			-- move to some random pos.
			if not worm.nextMoveTime or currTime > worm.nextMoveTime then
				worm.nextMovePos = wormPos + RandomVector(RandomFloat(100, 300))
				-- ensure good bounds
				while not WithinBounds(worm.nextMovePos, 200) do
					worm.nextMovePos = wormPos + RandomVector(RandomFloat(100, 300))
				end

				worm.nextMoveTime = currTime + RandomFloat(.4, 4.2)
			end
		end
		if worm.nextMovePos then
			if worm:GetPlayerID() == 1 then
				print("worm.nextMovePos")
			end
			ExecuteOrderFromTable({ UnitIndex = worm:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
				Position = worm.nextMovePos, Queue = false})
		end
	end

	function worm:DoAbilityLogic( abil )
		local abilName = abil:GetAbilityName()
		for _,ent in ipairs(worm.nearbyEnts) do
			if not ent.makesWormDie and ent.isFood then
				if abilName == "Crypt_Craving" then
					worm:CastAbilityNoTarget(abil, 0)
					return
				end
			elseif abilName == "Fiery_Jaw" and ent.makesWormDie and ent.isInferno and worm.hasFieryJaw then
				local inferno = Entities:FindByClassnameNearest("npc_dota_invoker_forged_spirit", worm:GetAbsOrigin(), 1400)
				if inferno then
					worm.hasTarget = true
					worm.target = inferno
					worm:CastAbilityNoTarget(abil, 0)
					return
				end
			end
		end
		if abilName == "Reverse" or abilName == "Segment_Bomb" or abilName == "Goo_Bomb" then
			worm:CastAbilityNoTarget(abil, 0)
		end

	end

	function worm:OnBotThink(  )
		if not worm:IsAlive() and not worm.cleanedUp then
			worm.hasTarget = false
			worm.target = nil
			worm.nearbyBadGuys = {}
			worm.nextMovePos = nil
			worm.cleanedUp = true
			return
		elseif worm:IsAlive() and worm.cleanedUp then
			worm.cleanedUp = false
		end

		local wormPos = worm:GetAbsOrigin()
		local fv = worm:GetForwardVector()

		if not worm.hasTarget then
			worm.nearbyEnts = Entities:FindAllInSphere(worm:GetAbsOrigin(), 300)
			worm.nearbyBadGuys = {}
			for _,ent in ipairs(worm.nearbyEnts) do
				if not ent.makesWormDie and ent.wormWarUnit then
					-- if worm already has rune, and he's found a rune, ignore
					if ent.isRune and worm:GetAbilityByIndex(0):GetAbilityName() ~= "wormwar_empty1" then

					else
						worm.target = ent
						worm.hasTarget = true
						break
					end
				elseif ent.makesWormDie then
					-- ensure worm isn't being confused by its own worm head dummy.
					if worm.wormHeadDummy ~= ent then
						table.insert(worm.nearbyBadGuys, ent)
					end
				end
			end
			if not worm.hasTarget then
				worm:OnTargetNotFound()
			end
		else
			if not IsValidEntity(worm.target) or not worm.target:IsAlive() then
				worm.hasTarget = false
				worm.target = nil
				worm.seekingTarget = false
			else
				-- seek it
				--if not worm.seekingTarget then
					ExecuteOrderFromTable({ UnitIndex = worm:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
						Position = worm.target:GetAbsOrigin(), Queue = false})
				--	worm.seekingTarget = true
				--end
			end
		end
		local abil = worm:GetAbilityByIndex(0)
		local abilName = abil:GetAbilityName()
		if abilName ~= "wormwar_empty1" then
			worm:DoAbilityLogic(abil)
		end
		-- check if worm is about to run into wall
		local point = wormPos + fv*160
		if not WithinBounds(point, 100) then
			worm.hasTarget = false
			worm.target = nil
			--local newPoint = Vector(RandomInt(Bounds.min, Bounds.max), RandomInt(Bounds.min, Bounds.max),GlobalDummy:GetAbsOrigin().z)
			local newPoint = Vector(0,0,GlobalDummy:GetAbsOrigin().z)
			--DebugDrawCircle(newPoint, Vector(255,0,0), 100, 20, false, 100)
			worm.nextMovePos = newPoint
			worm.nextMoveTime = GameRules:GetGameTime() + RandomFloat(.4, 4.2)
			ExecuteOrderFromTable({ UnitIndex = worm:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
				Position = newPoint, Queue = false})

		end


	end

	Timers:CreateTimer(function()
		worm:OnBotThink()
		return .06
	end)

end

function WithinBounds( v, offset )
	return (v.x < Bounds.max-offset and v.x > Bounds.min+offset and v.y < Bounds.max-offset and v.y > Bounds.min+offset)
end