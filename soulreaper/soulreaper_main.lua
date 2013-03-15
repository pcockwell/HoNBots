-- SoulReaperBot v1.0.4

--####################################################################
--####################################################################
--#                                                                 ##
--#                       Bot Initiation                            ##
--#                                                                 ##
--####################################################################
--####################################################################


local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic         = true
object.bRunBehaviors    = true
object.bUpdates         = true
object.bUseShop         = true

object.bRunCommands     = true 
object.bMoveCommands     = true
object.bAttackCommands     = true
object.bAbilityCommands = true
object.bOtherCommands     = true

object.bReportBehavior = false
object.bDebugUtility = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core         = {}
object.eventsLib    = {}
object.metadata     = {}
object.behaviorLib  = {}
object.skills       = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventslib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorlib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random, sqrt
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random, _G.math.sqrt

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading soulreaper_main...')

--####################################################################
--####################################################################
--#                                                                 ##
--#                  bot constant definitions                       ##
--#                                                                 ##
--####################################################################
--####################################################################

-- hero_<hero>  to reference the internal hon name of a hero, Hero_Yogi ==wildsoul
object.heroName = 'Hero_HellDemon'


--   item buy order. internal names  
behaviorLib.StartingItems  = {"3 Item_MinorTotem", "Item_MarkOfTheNovice", "Item_RunesOfTheBlight", "Item_GuardianRing"}
behaviorLib.LaneItems  = {"Item_ManaRegen3", "Item_Marchers", "Item_Intelligence5", "Item_Replenish"}
behaviorLib.MidItems  = {"Item_Steamboots", "Item_HealthMana2", "Item_Morph"}
behaviorLib.LateItems  = {"Item_FrostfieldPlate", "Item_BehemothsHeart"}


--####################################################################
--####################################################################
--#                                                                 ##
--#   bot function overrides                                        ##
--#                                                                 ##
--####################################################################
--####################################################################

------------------------------
--     skills               --
------------------------------
-- @param: none
-- @return: none
function object:SkillBuild()
	core.VerboseLog("SkillBuild()")

	local unitSelf = self.core.unitSelf
	if  skills.abilJudgement == nil then
		skills.abilJudgement = unitSelf:GetAbility(0)
		skills.abilWitheringPresence = unitSelf:GetAbility(1)
		skills.abilInhumanNature = unitSelf:GetAbility(2)
		skills.abilDemonicExecution = unitSelf:GetAbility(3)
		skills.abilAttributeBoost = unitSelf:GetAbility(4)
	end
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	
	-- automatically levels stats in the end
	-- stats have to be leveld manually if needed inbetween
	tSkills ={
				0, 2, 0, 2, 0,
				3, 0, 2, 2, 1, 
				3, 1, 1, 1, 4,
				3
			}
	
	local nLev = unitSelf:GetLevel()
	local nLevPts = unitSelf:GetAbilityPointsAvailable()
	--BotEcho(tostring(nLev + nLevPts))
	for i = nLev, nLev+nLevPts do
		local nSkill = tSkills[i]
		if nSkill == nil then nSkill = 4 end
		
		unitSelf:GetAbility(nSkill):LevelUp()
	end
end

-- These are bonus agression points if a skill/item is available for use
object.nHealUp = 5
object.nExecute1Up = 10 
object.nExecute2Up = 15 
object.nExecute3Up = 20
object.nSheepUp = 18
object.nFrostfieldUp = 12

-- These are bonus agression points that are applied to the bot upon successfully using a skill/item
object.nHealUse = 5
object.nExecute1Use = 30
object.nExecute2Use = 40
object.nExecute3Use = 50
object.nSheepUse = 18
object.nFrostfieldUse = 10

--These are thresholds of aggression the bot must reach to use these abilities
object.nHealThreshold = 12
object.nExecute1Threshold = 30
object.nExecute2Threshold = 25
object.nExecute3Threshold = 20
object.nSheepThreshold = 20
object.nFrostfieldThreshold = 12


----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	local nAddBonus = 0
	 if EventData.Type == "Ability" then
		if EventData.InflictorName == "Ability_HellDemon1" then
			nAddBonus = nAddBonus + object.nHealUse
		elseif EventData.InflictorName == "Ability_HellDemon4" then

			--Get appropriate Demonic Execution bonus
			local nExecutionLevel = skills.abilDemonicExecution:GetLevel()
			local nExecuteUseBonus = object.nExecute1Use
			if nExecutionLevel == 2 then
				nExecuteUseBonus = object.nExecute2Use
			elseif nExecutionLevel == 3 then
				nExecuteUseBonus = object.nExecute3Use
			end
			nAddBonus = nAddBonus + nExecuteUseBonus
		end

	elseif EventData.Type == "Item" then
		local nSelfUniqueId = core.unitSelf:GetUniqueID()
		if core.itemSheepstick ~= nil and EventData.SourceUnit == nSelfUniqueId and EventData.InflictorName == core.itemSheepstick:GetName() then
			nAddBonus = nAddBonus + self.nSheepUse
		end
		if core.itemFrostfieldPlate ~= nil and EventData.SourceUnit == nSelfUniqueId and EventData.InflictorName == core.itemFrostfieldPlate:GetName() then
			nAddBonus = nAddBonus + self.nFrostfieldUse
		end
	end

  if nAddBonus > 0 then
		core.DecayBonus(self)
		core.nHarassBonus = core.nHarassBonus + nAddBonus
	end
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent     = object.oncombateventOverride



local function funcFindItemsOverride(botBrain)
	local bUpdated = object.FindItemsOld(botBrain)

	if core.itemRoT ~= nil and not core.itemRoT:IsValid() then
		core.itemRoT = nil
	end
	if core.itemRoS ~= nil and not core.itemRoS:IsValid() then
		core.itemRoS = nil
	end
	if core.itemSheepstick ~= nil and not core.itemSheepstick:IsValid() then
		core.itemSheepstick = nil
	end
	if core.itemFrostfieldPlate ~= nil and not core.itemFrostfieldPlate:IsValid() then
		core.itemFrostfieldPlate = nil
	end

	if bUpdated then
		if core.itemRoT and core.itemRoS and core.itemSheepstick and core.itemFrostfieldPlate then
			return
		end

		local inventory = core.unitSelf:GetInventory(true)
		for slot = 1, 12, 1 do
			local curItem = inventory[slot]
			if curItem then
				if core.itemRoT == nil and curItem:GetName() == "Item_ManaRegen3" then
					core.itemRoT = core.WrapInTable(curItem)
				elseif core.itemRoS == nil and curItem:GetName() == "Item_Replenish" then
					core.itemRoS = core.WrapInTable(curItem)
				elseif core.itemSheepstick == nil and curItem:GetName() == "Item_Morph" then
					core.itemSheepstick = core.WrapInTable(curItem)
				elseif core.itemFrostfieldPlate == nil and curItem:GetName() == "Item_FrostfieldPlate" then
					core.itemFrostfieldPlate = core.WrapInTable(curItem)
				end
			end
		end
	end
end
object.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

------------------------------------------------------
--            customharassutility override          --
-- change utility according to usable spells here   --
------------------------------------------------------
-- @param: iunitentity hero
-- @return: number
local function CustomHarassUtilityOverride(unitTargetEnemyHero) --how much to harrass, doesn't change combo order or anything
	local nUtil = 0
	local bDebugEchos = true
	
	--BotEcho("Rethinking hass")
	
	local unitSelf = core.unitSelf

	--Judgement up bonus
	if skills.abilJudgement:CanActivate() then
		nUtil = nUtil + object.nHealUp
	end

	--Demonic Execution up bonus
	if skills.abilDemonicExecution:CanActivate() then
		local nExecutionLevel = skills.abilDemonicExecution:GetLevel()
		local nExecuteUpBonus = object.nExecute1Up
		if nExecutionLevel == 2 then
			nExecuteUseBonus = object.nExecute2Up
		elseif nExecutionLevel == 3 then
			nExecuteUseBonus = object.nExecute3Up
		end
		nUtil = nUtil + nExecuteUpBonus
	end
	
	--Sheepstick and Frostfield Plate up bonuses
	if object.itemSheepstick and object.itemSheepstick:CanActivate() then
		nUtil = nUtil + object.nSheepUp
	end
	
	if object.itemFrostfieldPlate and object.itemFrostfieldPlate:CanActivate() then
		nUtil = nUtil + object.nFrostfieldUp
	end

	--[Difficulty: Easy] Don't do advanced harrass bonuses
	if core.nDifficulty == core.nEASY_DIFFICULTY then
		return nUtil;
	end

	--Advanced harrass utils

	--Determine lane setup
	local tNearbyAllyHeroes = core.localUnits['AllyHeroes']
	local nNearbyAllyHeroes = 1
	local tNearbyEnemyHeroes = core.localUnits['EnemyHeroes']
	local nNearbyEnemyHeroes = 0
	local nMeleeEnemies = 0

	local nTargetEnemyHeroUniqueId = unitTargetEnemyHero:GetUniqueID()
	local bFoundEnemyHero = false

	for nNearbyEnemyHeroId, unitEnemyHero in pairs(tNearbyEnemyHeroes) do
		nNearbyEnemyHeroes = nNearbyEnemyHeroes + 1
		if unitEnemyHero:GetAttackType() == "melee" then
			nMeleeEnemies = nMeleeEnemies + 1
		end
		if nNearbyEnemyHeroId == nTargetEnemyHeroUniqueId then
			bFoundEnemyHero = true
		end
	end

	if not bFoundEnemyHero then
		if bDebugEchos then BotEcho("Can't find enemyHero in tNearbyEnemyHeroes - unit must have just gone out of sight. Returning skill and item nUtil value.") end
		return nUtil
	end
	
	for _, unitAllyHero in pairs(tNearbyAllyHeroes) do
		nNearbyAllyHeroes = nNearbyAllyHeroes + 1
	end

	--Get info about self
	local nSelfHealthPercent = unitSelf:GetHealthPercent()
	local nSelfManaPercent = unitSelf:GetManaPercent()
	local nSelfLevel = unitSelf:GetLevel()
	local tSelfInventory = unitSelf:GetInventory()
	
	--Check regen
	local tRunes = core.InventoryContains(tSelfInventory, "Item_RunesOfTheBlight")
	local tHealthPots = core.InventoryContains(tSelfInventory, "Item_HealthPotion")
	local nSelfCountRegenItems = 0

	for _, itemRunes in pairs(tRunes) do
		local nRunes = itemRunes:GetCharges()
		nSelfCountRegenItems = nSelfCountRegenItems + nRunes/3
	end

	for _, itemPots in pairs(tHealthPots) do
		local nPots = itemPots:GetCharges()
		nSelfCountRegenItems = nSelfCountRegenItems + nPots
	end

	--2v1 (or more) for them
	if nNearbyEnemyHeroes > nNearbyAllyHeroes then
		nUtil = nUtil - 5

		--2v1, start with a disadvantage for level bonus
		-- so we don't go crazy
		local nLevelAdvantageBonus = -3
		local nHealthBonuses = 0

		for _, unitEnemyHero in pairs(tNearbyEnemyHeroes) do
			if unitEnemyHero:GetAttackType() == "ranged" then
				--For every ranged hero they have, become more passive
				nUtil = nUtil - 5
			end

			local nEnemyLevel = unitEnemyHero:GetLevel()
			local nEnemyHealthPercent = unitEnemyHero:GetHealthPercent()

			--Take advantage of being higher level, but dont go crazy
			if nSelfLevel > nEnemyLevel then
				nLevelAdvantageBonus = nLevelAdvantageBonus + (nSelfLevel - nEnemyLevel)
			end

			--0.5 Harass utility point per 10% difference in health (plus or minus)
			nHealthBonuses = nHealthBonuses + 5 * (nSelfHealthPercent - nEnemyHealthPercent)

			--Penalty if we are somewhat low
			if nSelfHealthPercent < 0.6 then
				nHealthBonuses = nHealthBonuses - 5
			end
		end

		--Include level bonuses and health bonuses
		nUtil = nUtil + nLevelAdvantageBonus + nHealthBonuses

		--If we have very little regen, be more passive
		if nSelfLevel <= 6 then
			nUtil = nUtil - (2 - math.floor(nSelfCountRegenItems)) * 2
		end

		--Harass a melee hero if possible
		if unitTargetEnemyHero and unitTargetEnemyHero:GetAttackType() == "melee" then
			--Position and range information
			local vecMyPosition = unitSelf:GetPosition()
			local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTargetEnemyHero)
			nAttackRangeSq = nAttackRangeSq * nAttackRangeSq
			
			local vecTargetPosition = unitTargetEnemyHero:GetPosition()
			local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)

			--But only if in current range
			-- Don't run at them
			if nAttackRangeSq > nTargetDistanceSq then
				nUtil = nUtil + 5
			end
		end

	--2v1 (or more) for us, and there is actually an enemy hero nearby
	elseif nNearbyAllyHeroes > nNearbyEnemyHeroes and nNearbyEnemyHeroes > 0 then
		nUtil = nUtil + 5

		--Add up to 5 harass utility, depending on the makeup of enemies
		-- The higher percent melee heroes they have, the more agressive
		nUtil = nUtil + 5 * (nMeleeEnemies / nNearbyEnemyHeroes)

		local nHealthBonuses = 0
		for _, unitEnemyHero in pairs(tNearbyEnemyHeroes) do

			local nEnemyHealthPercent = unitEnemyHero:GetHealthPercent()

			--1 Harass utility point per 10% difference in health (plus or minus)
			nHealthBonuses = nHealthBonuses + 10 * (nSelfHealthPercent - nEnemyHealthPercent)

			--Extra bonus if they are low
			if nEnemyHealthPercent < 0.4 then
				nHealthBonuses = nHealthBonuses + 5
			end
		end

		--Include health bonuses
		nUtil = nUtil + nHealthBonuses

		--Increase harass utility by 5 for every hero more that we have over them
		nUtil = nUtil + 5 * (nNearbyAllyHeroes - nNearbyEnemyHeroes)

		local tNearbyEnemyTowers = core.localUnits['EnemyTowers']
		for _, unitTower in pairs(tNearbyEnemyTowers) do
			--Lower harass increase if it might aggro tower
			nUtil = nUtil - 5
		end

	--1v1
	elseif nNearbyEnemyHeroes == 1 and unitTargetEnemyHero then
		local nSelfMinDamage = unitSelf:GetFinalAttackDamageMin()

		--Get enemy info from the enemyHero passed in to function
		local unitEnemyHero = unitTargetEnemyHero
		local sEnemyAttackType = unitEnemyHero:GetAttackType()
		local nEnemyHealthPercent = unitEnemyHero:GetHealthPercent()
		local nEnemyManaPercent = unitEnemyHero:GetManaPercent()
		local nEnemyHealth = unitEnemyHero:GetHealth()
		local nEnemyMana = unitEnemyHero:GetMana()
		local nEnemyLevel = unitEnemyHero:GetLevel()
		local tEnemyInventory = unitEnemyHero:GetInventory()
		local nEnemyMinDamage = unitEnemyHero:GetFinalAttackDamageMin()
		local bCheckRegen = false
		
		--Check regen
		local nEnemyCountRegenItems = 0
		local tEnemyRunes = {}
		local tEnemyHealthPots = {}
		if tEnemyInventory == nil then
			if bDebugEchos then BotEcho("tEnemyInventory is nil - unit must have just gone out of sight. Won't check regen") end
		else
			tEnemyRunes = core.InventoryContains(tEnemyInventory, "Item_RunesOfTheBlight")
			tEnemyHealthPots = core.InventoryContains(tEnemyInventory, "Item_HealthPotion")

			for _, itemRunes in pairs(tEnemyRunes) do
				local nRunes = itemRunes:GetCharges()
				nEnemyCountRegenItems = nEnemyCountRegenItems + nRunes/3
			end

			for _, itemPots in pairs(tEnemyHealthPots) do
				local nPots = itemPots:GetCharges()
				nEnemyCountRegenItems = nEnemyCountRegenItems + nPots
			end
			bCheckRegen = true
		end

		--We have higher damage
		if nSelfMinDamage > nEnemyMinDamage then
			--Add a bonus for higher damage
			nUtil = nUtil + math.min((nSelfMinDamage - nEnemyMinDamage), 30)

			--Adjust utilities based on regen, health, mana, and enemy attack type
			if bCheckRegen and nSelfLevel <= 6 then
				local nRegenDiff = math.floor(nSelfCountRegenItems - nEnemyCountRegenItems)
				if nRegenDiff >= 1 then
					nUtil = nUtil + 4
				end
			end

			--1 Harass utility point per 10% difference in health (plus or minus)
			nUtil = nUtil + 10 * (nSelfHealthPercent - nEnemyHealthPercent)

			--0.5 Harass utility point per 10% difference in mana (plus or minus)
			nUtil = nUtil + 5 * (nSelfManaPercent - nEnemyManaPercent)

			--We have higher damage and enemy is melee
			if sEnemyAttackType == "melee" then
				nUtil = nUtil + 5
			end

		--They have higher damage - don't trade hits
		else
			--Ranged hero with higher attack damage - be careful
			if sEnemyAttackType == "ranged" then
				--Penalty for ranged hero with higher damage
				nUtil = nUtil + math.max((nSelfMinDamage - nEnemyMinDamage) * 0.2, -5)
			--Melee hero with higher damage
			else
				--Level dependent bonus for melee heroes
				if nEnemyLevel < 6 then
					nUtil = nUtil + 4
				else
					nUtil = nUtil + 2
				end
			end

			--Adjust utilities based on regen, health, mana, and enemy attack type
			if bCheckRegen and nSelfLevel <= 6 and nSelfCountRegenItems > nEnemyCountRegenItems then
				nUtil = nUtil + 4
			end

			--1 Harass utility point per 10% difference in mana (plus or minus)
			nUtil = nUtil + 5 * (nSelfManaPercent - nEnemyManaPercent)
		end

		--Take advantage of being higher level, but dont go crazy
		local nLevelAdvantageBonus = 2 * (nSelfLevel - nEnemyLevel)
		nLevelAdvantageBonus = math.min(nLevelAdvantageBonus, 10)

		nUtil = nUtil + nLevelAdvantageBonus
	end

	return nUtil -- no desire to attack AT ALL if 0.
end
-- assisgn custom Harrass function to the behaviourLib object
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride  

--[[
	Assumes 1 cast of Judgement and 1 (or more) auto attacks can be hit after
	Demonic Execution is cast.

	bExecutionFirst = true means that the bot thinks it can't get a cast of
	Judgement to hit before casting Demonic Execution
]]--
local function GetPotentialDamage(unitTarget, bExecutionFirst)
	--BotEcho("Calculating potential damage")

	if bExecutionFirst == nil then bExecutionFirst = true end
	local unitSelf = core.unitSelf
	
	--Position and range information
	local vecMyPosition = unitSelf:GetPosition()
	local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
	nAttackRangeSq = nAttackRangeSq * nAttackRangeSq
	
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)

	local nSelfMana = unitSelf:GetMana()

	--Skills
	local abilJudgement = skills.abilJudgement
	local abilDemonicExecution = skills.abilDemonicExecution

	--Get mana costs
	local nJudgementManaCost = abilJudgement:GetManaCost()
	local nExecutionManaCost = abilDemonicExecution:GetManaCost()

	--Get skill ranges
	local nExecutionRangeSq = abilDemonicExecution:GetRange()
	nExecutionRangeSq = nExecutionRangeSq * nExecutionRangeSq
	local nJudgementRangeSq = abilJudgement:GetTargetRadius()
	nJudgementRangeSq = nJudgementRangeSq * nJudgementRangeSq

	--Determine what the Demonic Execution damage multiplier is
	local nExecutionLevel = abilDemonicExecution:GetLevel()
	local nExecuteLevelDamageMultiplier = 0.4
	if nExecutionLevel == 2 then
		nExecuteLevelDamageMultiplier = 0.6
	elseif nExecutionLevel == 3 then
		nExecuteLevelDamageMultiplier = 0.9
	end

	--Get resistances, adjusted attack damage, and target's missing health
	local nTargetMagicResistance = unitTarget:GetMagicResistance()
	local nTargetPhysResistance = unitTarget:GetPhysicalResistance()
	local nAttackDamage = unitSelf:GetFinalAttackDamageMin() * (1 - nTargetPhysResistance)
	local nTargetMissingHealth = unitTarget:GetMaxHealth() - unitTarget:GetHealth()

	local nPotentialDamage = 0
	local nPotentialAttacks = 1

	--Determine what the Judgement damage is
	local nJudgementLevel = abilJudgement:GetLevel()
	local nJudgementDamage = nJudgementLevel * 70 * (1 - nTargetMagicResistance)

	if not bExecutionFirst and abilJudgement:CanActivate() and nTargetDistanceSq < nJudgementRangeSq and nSelfMana > nJudgementManaCost then
		--If we aren't opening with Execution, assume we can cast a heal and apply an auto attack
		nPotentialDamage = nPotentialDamage + nJudgementDamage

		--Adjust the targets missing health for the damage we just did
		nTargetMissingHealth = nTargetMissingHealth + nJudgementDamage

		--Adjust for mana just used
		nSelfMana = nSelfMana - nJudgementManaCost
	end

	if abilDemonicExecution:CanActivate() and nTargetDistanceSq < nExecutionRangeSq and nSelfMana > nExecutionManaCost then
		--Calculate the amount of damage that can be dealt by casting Demonic Execution
		nPotentialDamage = (1 - nTargetMagicResistance) * nExecuteLevelDamageMultiplier * nTargetMissingHealth

		--Adjust for mana just used
		nSelfMana = nSelfMana - nExecutionManaCost
	end

	--If we are within 40% of our attack range, assume 2 more attacks
	if nAttackRangeSq * 0.16 > nTargetDistanceSq then
		nPotentialAttacks = nPotentialAttacks + 2
	--If we are within 70% of our attack range, assume 1 more attack
	elseif nAttackRangeSq * 0.50 > nTargetDistanceSq then
		nPotentialAttacks = nPotentialAttacks + 1
	end

	--Get damage dealt by attack
	nPotentialDamage = nPotentialDamage + nPotentialAttacks * nAttackDamage  

	--DistanceWalkingSq is MoveSpeed (units/second) * number of seconds walking (1 second)
	local nDistanceWalkingSq = unitSelf:GetMoveSpeed()
	nDistanceWalkingSq = nDistanceWalkingSq * nDistanceWalkingSq

	--Put in another heal if we can walk in range in 1 second just for good measure
	if abilJudgement:CanActivate() and nTargetDistanceSq - nDistanceWalkingSq < nJudgementRangeSq and nSelfMana > nJudgementManaCost then
		nPotentialDamage = nPotentialDamage + nJudgementDamage
	end

	return nPotentialDamage
end

--------------------------------------------------------------
--                    Harass Behavior                       --
-- All code how to use abilities against enemies goes here  --
--------------------------------------------------------------
-- @param botBrain: CBotBrain
-- @return: none
--
local function HarassHeroExecuteOverride(botBrain)
	local bDebugEchos = false
	local bDebugHarassUtility = false and bDebugEchos
	
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil then
		return false --can not execute, move on to the next behavior
	end
	
	local unitSelf = core.unitSelf
	
	--Positioning and distance info
	local vecMyPosition = unitSelf:GetPosition()
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
	
	local nLastHarassUtility = behaviorLib.lastHarassUtil
	
	--Skills
	local abilJudgement = skills.abilJudgement
	local abilDemonicExecution = skills.abilDemonicExecution
	
	if bDebugHarassUtility then BotEcho("SoulReaper HarassHero at "..nLastHarassUtility) end

	--Used to keep track of whether something has been used
	-- If so, any other action that would have taken place
	-- gets queued instead of instantly ordered
	local bActionTaken = false

	--If we can see the target
	if core.CanSeeUnit(botBrain, unitTarget) then
		local bTargetVuln = unitTarget:IsStunned() or unitTarget:IsImmobilized()
		core.FindItems()
	
		--Sheepstick
		if not bTargetVuln then 
			local itemSheepstick = core.itemSheepstick
			if itemSheepstick then
				local nRange = itemSheepstick:GetRange()
				if itemSheepstick:CanActivate() and nLastHarassUtility > botBrain.nSheepThreshold then
					if nTargetDistanceSq < (nRange * nRange) then
						if bDebugEchos then BotEcho("Using sheepstick") end
						--If bActionTaken = true, this will queue the order
						bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemSheepstick, unitTarget, false, bActionTaken)
					end
				end
			end
	
			--Frostfield
			local itemFrostfieldPlate = core.itemFrostfieldPlate
			if itemFrostfieldPlate then
				local nRange = itemFrostfieldPlate:GetTargetRadius()
				if itemFrostfieldPlate:CanActivate() and nLastHarassUtility > botBrain.nFrostfieldThreshold then
					if nTargetDistanceSq < (nRange * nRange) * 0.9 then
						if bDebugEchos then BotEcho("Using frostfield") end
						--If bActionTaken = true, this will queue the order
						bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemFrostfieldPlate, false, bActionTaken)
					end
				end
			end
		end

		--Demonic Execution info
		local nExecutionLevel = abilDemonicExecution:GetLevel()
		local nExecuteLevelThreshold = botBrain.nExecute1Threshold
		local nExecuteLevelUseHarassBonus = botBrain.nExecute1Use
		if nExecutionLevel == 2 then
			nExecuteLevelThreshold = botBrain.nExecute2Threshold
			nExecuteLevelUseHarassBonus = botBrain.nExecute2Use
		elseif nExecutionLevel == 3 then
			nExecuteLevelThreshold = botBrain.nExecute3Threshold
			nExecuteLevelUseHarassBonus = botBrain.nExecute3Use
		end

		--Demonic Execution
		if nLastHarassUtility > nExecuteLevelThreshold then

			--Only do calcs if in range
			local nRange = abilDemonicExecution:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				local nPotentialDamage = GetPotentialDamage(unitTarget, true)
				if bDebugHarassUtility then 
					BotEcho("Potential damage: " .. nPotentialDamage)
					BotEcho("Target Health: " .. unitTarget:GetHealth())
				end

				if abilDemonicExecution:CanActivate() and unitTarget:GetHealth() < nPotentialDamage then
					if bDebugEchos then BotEcho("USING SKILL DEMONIC EXECUTION!!!!") end
				   
					--If bActionTaken = true, this will queue the order
					bActionTaken = core.OrderAbilityEntity(botBrain, abilDemonicExecution, unitTarget, bActionTaken)

					--Just used demonic execution, so up the HarassUtility as needed,
					-- and move towards the target, but still attack while doing so
					nLastHarassUtility = nLastHarassUtility + nExecuteLevelUseHarassBonus

					if unitSelf:IsAttackReady() then
						--If bActionTaken = true, this will queue the order
						core.OrderAttackClamp(botBrain, unitSelf, unitTarget, bActionTaken)
					end

					--If bActionTaken = true, this will queue the order
					core.OrderMoveToPosClamp(botBrain, unitSelf, vecTargetPosition, false, bActionTaken)
				end
			end
		end
	end

	--Judgement damage info
	local nJudgementDamage = abilJudgement:GetLevel() * 70
	local nTargetMagicResistance = unitTarget:GetMagicResistance()
	if unitTarget and nTargetMagicResistance then
		nJudgementDamage = nJudgementDamage * (1 - nTargetMagicResistance)
	end 

	--Judgement
	if nLastHarassUtility > botBrain.nHealThreshold or nJudgementDamage > unitTarget:GetHealth() then
		local nRange = abilJudgement:GetTargetRadius()
		--Apply a 20% handicap to this skill's range 
		-- since it seems to sometimes incorrectly
		-- estimate if a target is in range
		nRange = nRange * 0.8

		if abilJudgement:CanActivate() and nTargetDistanceSq < (nRange * nRange) then
			if bDebugEchos then BotEcho("USING SKILL JUDGEMENT!!!!") end
			--If bActionTaken = true, this will queue the order
			bActionTaken = core.OrderAbility(botBrain, abilJudgement, true, bActionTaken)
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end
-- overload the behaviour stock function with custom 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

----------------------------------
--  Soul Reaper's Help behavior
--  
--  Utility: 
--  Execute: Use Astrolabe
--
--  Taken and modified from the
--  GlaciusBot
----------------------------------
behaviorLib.nHealUtilityMul = 0.8
behaviorLib.nHealHealthUtilityMul = 1.0
behaviorLib.nHealTimeToLiveUtilityMul = 0.5

function behaviorLib.HealHealthUtilityFn(unitHero)
	local nUtility = 0
	
	local nYIntercept = 100
	local nXIntercept = 100
	local nOrder = 2

	nUtility = core.ExpDecay(unitHero:GetHealthPercent() * 100, nYIntercept, nXIntercept, nOrder)
	
	return nUtility
end

function behaviorLib.TimeToLiveUtilityFn(unitHero)
	--Increases as your time to live based on your damage velocity decreases
	local nUtility = 0
	
	local nHealthVelocity = unitHero:GetHealthVelocity()
	local nHealth = unitHero:GetHealth()
	local nTimeToLive = 9999
	if nHealthVelocity < 0 then
		nTimeToLive = nHealth / (-1 * nHealthVelocity)
		
		local nYIntercept = 100
		local nXIntercept = 20
		local nOrder = 2
		nUtility = core.ExpDecay(nTimeToLive, nYIntercept, nXIntercept, nOrder)
	end
	
	nUtility = Clamp(nUtility, 0, 100)
	
	return nUtility, nTimeToLive
end

behaviorLib.unitHealTarget = nil
behaviorLib.nHealTimeToLive = nil
function behaviorLib.HealUtility(botBrain)
	local bDebugEchos = false
	
	local nUtility = 0

	local unitSelf = core.unitSelf
	behaviorLib.unitHealTarget = nil
	
	local abilJudgement = skills.abilJudgement
	
	local nHighestUtility = 0
	local unitTarget = nil
	local nTargetTimeToLive = nil
	if abilJudgement and abilJudgement:CanActivate() then
		local tTargets = core.CopyTable(core.localUnits["AllyHeroes"])
		local nOwnID = unitSelf:GetUniqueID()
		local bHealthLow = unitSelf:GetHealthPercent() < 0.20
		local bHealAtWell = core.GetCurrentBehaviorName(botBrain) ~= "HealAtWell"

		tTargets[nOwnID] = unitSelf --I am also a target
		for key, hero in pairs(tTargets) do
			--Don't heal ourself if we are going to head back to the well anyway,
			-- as it could cause us to retrace half a walkback,
			-- unless it our health is below 20%
			if hero:GetUniqueID() ~= nOwnID or bHealthLow or bHealAtWell then
				local nCurrentUtility = 0
				
				local nHealthUtility = behaviorLib.HealHealthUtilityFn(hero) * behaviorLib.nHealHealthUtilityMul
				local nTimeToLiveUtility = nil
				local nCurrentTimeToLive = nil
				nTimeToLiveUtility, nCurrentTimeToLive = behaviorLib.TimeToLiveUtilityFn(hero)
				nTimeToLiveUtility = nTimeToLiveUtility * behaviorLib.nHealTimeToLiveUtilityMul
				nCurrentUtility = nHealthUtility + nTimeToLiveUtility
				
				if nCurrentUtility > nHighestUtility then
					nHighestUtility = nCurrentUtility
					nTargetTimeToLive = nCurrentTimeToLive
					unitTarget = hero
				end
			end
		end

		if unitTarget then
			nUtility = nHighestUtility              
			sAbilName = "Judgement"
		
			behaviorLib.unitHealTarget = unitTarget
			behaviorLib.nHealTimeToLive = nTargetTimeToLive
		end
	end
	
	nUtility = nUtility * behaviorLib.nHealUtilityMul
	
	if botBrain.bDebugUtility == true and nUtility ~= 0 then
		BotEcho(format("  HelpUtility: %g", nUtility))
	end
	
	return nUtility
end

function behaviorLib.HealExecute(botBrain)
	local abilJudgement = skills.abilJudgement

	if not abilJudgement then BotEcho("Can't find abilJudgement") end
	
	local unitHealTarget = behaviorLib.unitHealTarget
	local nHealTimeToLive = behaviorLib.nHealTimeToLive
	
	if unitHealTarget and abilJudgement and abilJudgement:CanActivate() then 
		local unitSelf = core.unitSelf
		local vecTargetPosition = unitHealTarget:GetPosition()
		local nDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecTargetPosition)
		local nJudgementRangeSq = abilJudgement:GetTargetRadius()
		nJudgementRangeSq = nJudgementRangeSq * nJudgementRangeSq
		
		if nDistanceSq < nJudgementRangeSq then
			core.OrderAbility(botBrain, abilJudgement)
		else
			core.OrderMoveToUnitClamp(botBrain, unitSelf, unitHealTarget)
		end
	else
		return false
	end
	
	return true
end

behaviorLib.HealBehavior = {}
behaviorLib.HealBehavior["Utility"] = behaviorLib.HealUtility
behaviorLib.HealBehavior["Execute"] = behaviorLib.HealExecute
behaviorLib.HealBehavior["Name"] = "Heal"
tinsert(behaviorLib.tBehaviors, behaviorLib.HealBehavior)

----------------------------------
--    SoulReapers's Help behavior
--    
--    Utility: 
--    Execute: Use Ring of Sorcery
--
--    Taken from Djulio's BeheBot
----------------------------------

behaviorLib.nReplenishUtilityMul = 1.3
behaviorLib.nReplenishManaUtilityMul = 1.0
behaviorLib.nReplenishTimeToLiveUtilityMul = 0.5

function behaviorLib.ReplenishManaUtilityFn(unitHero)
	local nUtility = 0
	 
	local nYIntercept = 100
	local nXIntercept = 100
	local nOrder = 2

	nUtility = core.ExpDecay(unitHero:GetManaPercent() * 100, nYIntercept, nXIntercept, nOrder)
	 
	return nUtility
end

function behaviorLib.ManaVelocityUtilityFn(unitHero)
	--Increases as your time to live based on your damage velocity decreases
	local nUtility = 0
	 
	local nManaVelocity = unitHero:GetManaRegen()    -- Get mana regen
	local nMana = unitHero:GetMana()                -- Get mana
	local nTimeToLive = 9999
	if nManaVelocity < 0 then
		nTimeToLive = nMana / (-1 * nManaVelocity)
		 
		local nYIntercept = 100
		local nXIntercept = 20
		local nOrder = 2
		nUtility = core.ExpDecay(nTimeToLive, nYIntercept, nXIntercept, nOrder)
	end
	 
	nUtility = Clamp(nUtility, 0, 100)
	 
	return nUtility, nTimeToLive
end

behaviorLib.unitReplenishTarget = nil
behaviorLib.nReplenishTimeToLive = nil
function behaviorLib.ReplenishUtility(botBrain)
	local bDebugEchos = false
	 
	if bDebugEchos then BotEcho("ReplenishUtility") end
	 
	local nUtility = 0

	local unitSelf = core.unitSelf
	behaviorLib.unitReplenishTarget = nil
	 
	core.FindItems()
	local itemRoS = core.itemRoS
	 
	local nHighestUtility = 0
	local unitTarget = nil
	local nTargetTimeToLive = nil
	local sAbilName = ""
	if itemRoS and itemRoS:CanActivate() then
		local tTargets = core.CopyTable(core.localUnits["AllyHeroes"])
		local nOwnID = unitSelf:GetUniqueID()
		local bHealAtWell = core.GetCurrentBehaviorName(botBrain) ~= "HealAtWell"
		tTargets[nOwnID] = unitSelf --I am also a target
		for key, hero in pairs(tTargets) do

			--Don't heal ourself if we are going to head back to the well anyway,
			-- as it could cause us to retrace half a walkback
			if hero:GetUniqueID() ~= nOwnID or bHealAtWell then
				local nCurrentUtility = 0
				 
				local nManaUtility = behaviorLib.ReplenishManaUtilityFn(hero) * behaviorLib.nReplenishManaUtilityMul
				local nTimeToLiveUtility = nil
				local nCurrentTimeToLive = nil
				nTimeToLiveUtility, nCurrentTimeToLive = behaviorLib.ManaVelocityUtilityFn(hero)
				nTimeToLiveUtility = nTimeToLiveUtility * behaviorLib.nReplenishTimeToLiveUtilityMul
				nCurrentUtility = nManaUtility + nTimeToLiveUtility
				 
				if nCurrentUtility > nHighestUtility then
					nHighestUtility = nCurrentUtility
					nTargetTimeToLive = nCurrentTimeToLive
					unitTarget = hero
					if bDebugEchos then BotEcho(format("%s Replenish util: %d  health: %d  ttl:%d", hero:GetTypeName(), nCurrentUtility, nReplenishUtility, nTimeToLiveUtility)) end
				end
			end
		end

		if unitTarget then
			nUtility = nHighestUtility                
			sAbilName = "Replenish"
		 
			behaviorLib.unitReplenishTarget = unitTarget
			behaviorLib.nReplenishTimeToLive = nTargetTimeToLive
		end       
	end
	 
	if bDebugEchos then BotEcho(format("    abil: %s util: %d", sAbilName, nUtility)) end
	 
	nUtility = nUtility * behaviorLib.nReplenishUtilityMul
	 
	if botBrain.bDebugUtility == true and nUtility ~= 0 then
		BotEcho(format("  HelpUtility: %g", nUtility))
	end
	 
	return nUtility
end

-- Executing the behavior to use the Ring of Sorcery
function behaviorLib.ReplenishExecute(botBrain)
	core.FindItems()
	local itemRoS = core.itemRoS
	 
	local unitReplenishTarget = behaviorLib.unitReplenishTarget
	local nReplenishTimeToLive = behaviorLib.nReplenishTimeToLive
	 
	if unitReplenishTarget and itemRoS and itemRoS:CanActivate() then
		local unitSelf = core.unitSelf                                                    -- Get bot's position
		local vecTargetPosition = unitReplenishTarget:GetPosition()                        -- Get target's position
		local nDistance = Vector3.Distance2D(unitSelf:GetPosition(), vecTargetPosition)    -- Get distance between bot and target
		if nDistance < itemRoS:GetTargetRadius() then
			core.OrderItemClamp(botBrain, unitSelf, itemRoS) -- Use Ring of Sorcery, if in range
		else
			core.OrderMoveToUnitClamp(botBrain, unitSelf, unitReplenishTarget) -- Move closer to target
		end
	else
		return false
	end
	 
	return true
end

behaviorLib.ReplenishBehavior = {}
behaviorLib.ReplenishBehavior["Utility"] = behaviorLib.ReplenishUtility
behaviorLib.ReplenishBehavior["Execute"] = behaviorLib.ReplenishExecute
behaviorLib.ReplenishBehavior["Name"] = "Replenish"
tinsert(behaviorLib.tBehaviors, behaviorLib.ReplenishBehavior)

--[[
Commenting out for now as it may be used later

function GetClosestEnemyHero(botBrain)
	local unitClosestHero = nil
	local nClosestHeroDistSq = nil
	local vecSelfPosition = core.unitSelf:GetPosition()
	--core.printGetTypeNameTable(HoN.GetHeroes(core.enemyTeam))
	for id, unitHero in pairs(HoN.GetHeroes(core.enemyTeam)) do
		if unitHero ~= nil then
			if core.CanSeeUnit(botBrain, unitHero) then
		
				local nDistanceSq = Vector3.Distance2DSq(unitHero:GetPosition(), vecSelfPosition)
				if nClosestHeroDistSq == nil or nDistanceSq < nClosestHeroDistSq then
					nClosestHeroDistSq = nDistanceSq
					unitClosestHero = unitHero
				end
			end
		end
	end
	
	return unitClosestHero
end

function IsTowerThreateningUnit(unit)
	local vecPosition = unit:GetPosition()
	local nUnitTeam = unit:GetTeam()
	--TODO: switch to just iterate through the enemy towers instead of calling GetUnitsInRadius
	
	local nTowerRange = 821.6 --700 + (86 * sqrtTwo)
	local tBuildings = HoN.GetUnitsInRadius(vecPosition, nTowerRange, core.UNIT_MASK_ALIVE + core.UNIT_MASK_BUILDING)
	for key, unitBuilding in pairs(tBuildings) do
		if unitBuilding:IsTower() and unitBuilding:GetCanAttack() and unitBuilding:GetTeam() ~= nUnitTeam then
			return true
		end
	end
	
	return false
end
]]

--------------------------------------------------
--    SoulReapers's Predictive Last Hitting Helper
--    
--    Assumes that you have vision on the creep
--    passed in to the function
--
--    Developed by paradox870
--------------------------------------------------
local function GetAttackDamageOnCreep(botBrain, unitCreepTarget)

	if not unitCreepTarget or not core.CanSeeUnit(botBrain, unitCreepTarget) then
		return nil
	end

	local unitSelf = core.unitSelf

	--Get positioning information
	local vecSelfPos = unitSelf:GetPosition()
	local vecTargetPos = unitCreepTarget:GetPosition() 

	--Get projectile info
	local nProjectileSpeed = unitSelf:GetAttackProjectileSpeed() 
	local nProjectileTravelTime = Vector3.Distance2D(vecSelfPos, vecTargetPos) / nProjectileSpeed
	if bDebugEchos then BotEcho ("Projectile travel time: " .. nProjectileTravelTime ) end 
	
	local nExpectedCreepDamage = 0
	local nExpectedTowerDamage = 0
	local tNearbyAttackingCreeps = nil
	local tNearbyAttackingTowers = nil

	--Get the creeps and towers on the opposite team
	-- of our target
	if unitCreepTarget:GetTeam() == unitSelf:GetTeam() then
		tNearbyAttackingCreeps = core.localUnits['EnemyCreeps']
		tNearbyAttackingTowers = core.localUnits['EnemyTowers']
	else
		tNearbyAttackingCreeps = core.localUnits['AllyCreeps']
		tNearbyAttackingTowers = core.localUnits['AllyTowers']
	end

	--Determine the damage expected on the creep by other creeps
	for i, unitCreep in pairs(tNearbyAttackingCreeps) do
		if unitCreep:GetAttackTarget() == unitCreepTarget then
			local nCreepAttacks = 1 + math.floor(unitCreep:GetAttackSpeed() * nProjectileTravelTime)
			nExpectedCreepDamage = nExpectedCreepDamage + unitCreep:GetFinalAttackDamageMin() * nCreepAttacks
		end
	end

	--Determine the damage expected on the creep by other towers
	for i, unitTower in pairs(tNearbyAttackingTowers) do
		if unitTower:GetAttackTarget() == unitCreepTarget then
			local nTowerAttacks = 1 + math.floor(unitTower:GetAttackSpeed() * nProjectileTravelTime)
			nExpectedTowerDamage = nExpectedTowerDamage + unitTower:GetFinalAttackDamageMin() * nTowerAttacks
		end
	end

	return nExpectedCreepDamage + nExpectedTowerDamage
end

function GetCreepAttackTargetOverride(botBrain, unitEnemyCreep, unitAllyCreep) --called pretty much constantly
	local bDebugEchos = false

	--Get info about self
	local unitSelf = core.unitSelf
	local nDamageMin = unitSelf:GetFinalAttackDamageMin()

	if unitEnemyCreep and core.CanSeeUnit(botBrain, unitEnemyCreep) then
		local nTargetHealth = unitEnemyCreep:GetHealth()
		--Only attack if, by the time our attack reaches the target
		-- the damage done by other sources brings the target's health
		-- below our minimum damage
		if nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitEnemyCreep)) then
			if bDebugEchos then BotEcho("Returning an enemy") end
			return unitEnemyCreep
		end
	end

	if unitAllyCreep then
		local nTargetHealth = unitAllyCreep:GetHealth()

		--Only attack if, by the time our attack reaches the target
		-- the damage done by other sources brings the target's health
		-- below our minimum damage
		if nDamageMin >= (nTargetHealth - GetAttackDamageOnCreep(botBrain, unitAllyCreep)) then
			local bActuallyDeny = true
			
			--[Difficulty: Easy] Don't deny
			if core.nDifficulty == core.nEASY_DIFFICULTY then
				bActuallyDeny = false
			end         
			
			-- [Tutorial] Hellbourne *will* deny creeps after shit gets real
			if core.bIsTutorial and core.bTutorialBehaviorReset == true and core.myTeam == HoN.GetHellbourneTeam() then
				bActuallyDeny = true
			end
			
			if bActuallyDeny then
				if bDebugEchos then BotEcho("Returning an ally") end
				return unitAllyCreep
			end
		end
	end

	return nil
end
-- overload the behaviour stock function with custom 
object.getCreepAttackTargetOld = behaviorLib.GetCreepAttackTarget
behaviorLib.GetCreepAttackTarget = GetCreepAttackTargetOverride

function AttackCreepsExecuteOverride(botBrain)
	local unitSelf = core.unitSelf
	local unitCreepTarget = core.unitCreepTarget

	if unitCreepTarget and core.CanSeeUnit(botBrain, unitCreepTarget) then      
		--Get info about the target we are about to attack
		local vecSelfPos = unitSelf:GetPosition()
		local vecTargetPos = unitCreepTarget:GetPosition()
		local nDistSq = Vector3.Distance2DSq(vecSelfPos, vecTargetPos)
		local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, currentTarget, true)
	
		--Only attack if, by the time our attack reaches the target
		-- the damage done by other sources brings the target's health
		-- below our minimum damage, and we are in range and can attack right now
		if nDistSq < nAttackRangeSq and unitSelf:IsAttackReady() then
			core.OrderAttackClamp(botBrain, unitSelf, unitCreepTarget)

		--Otherwise get within 70% of attack range if not already
		-- This will decrease travel time for the projectile
		elseif (nDistSq > nAttackRangeSq * 0.5) then 
			local vecDesiredPos = core.AdjustMovementForTowerLogic(vecTargetPos)
			core.OrderMoveToPosClamp(botBrain, unitSelf, vecDesiredPos, false)

		--If within a good range, just hold tight
		else
			core.OrderHoldClamp(botBrain, unitSelf, false)
		end
	else
		return false
	end
end
object.AttackCreepsExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.AttackCreepsBehavior["Execute"] = AttackCreepsExecuteOverride

-- This function allowes soul reaper to use his ability while pushing
-- Has prediction, however it might need some repositioning so he is in correct range more often
local function abilityPush(botBrain, unitSelf)
	local debugAbilityPush = false

	local abilJudgement = skills.abilJudgement
	
	--Only cast it if we have enough mana to activate a second time afterwards - aka don't waste while pushing
	if  abilJudgement:CanActivate() and unitSelf:GetMana() > abilJudgement:GetManaCost() * 2 then 
		--Get judgement info
		local nJudgementRangeSq = abilJudgement:GetTargetRadius()
		nJudgementRangeSq = nJudgementRangeSq * nJudgementRangeSq

		--Get info about surroundings
		local myPos = unitSelf:GetPosition()
		local tNearbyEnemyCreeps = core.localUnits["EnemyCreeps"]
		local tNearbyEnemyTowers = core.localUnits["EnemyTowers"]

		--Determine information about nearby creeps
		local nLowHealthCreepsInRange = 0
		local nCreepsInRange = 0
		for i, unitCreep in pairs(tNearbyEnemyCreeps) do
			nTargetDistanceSq = Vector3.Distance2DSq(myPos, unitCreep:GetPosition())
			if nTargetDistanceSq < nJudgementRangeSq then
				nCreepsInRange = nCreepsInRange + 1
				if unitCreep:GetHealth() < abilJudgement:GetLevel() * 70 then
					nLowHealthCreepsInRange = nLowHealthCreepsInRange + 1
				end
			end
		end
		
		--Check for nearby towers
		local bNearTower = false
		for i, unitTower in pairs(tNearbyEnemyTowers) do
			if unitTower then
				bNearTower = true
			end
		end

		--Only cast if one of these conditions is met
		-- There are 2 or more creeps that would be killed by doing so
		-- There are 4 or more creeps and we are near a tower
		-- There are 7 or more creeps
		local bShouldCast = nLowHealthCreepsInRange > 1 or (nCreepsInRange > 3 and bNearTower) or nCreepsInRange > 7

		--Cast judgement if a condition is met
		if bShouldCast then
			return core.OrderAbility(botBrain, abilJudgement)
		end
	end
	
	return false
end


function object.CreepPush(botBrain)
	VerboseLog("PushExecute("..tostring(botBrain)..")")
	local debugPushLines = false
	if debugPushLines then BotEcho('^yGotta execute em *greedy*') end
	
	local bSuccess = false
		
	local unitSelf = core.unitSelf
	if unitSelf:IsChanneling() then 
		return
	end

	local unitTarget = core.unitEnemyCreepTarget
	if unitTarget then
		bSuccess = abilityPush(botBrain, unitSelf)
		if debugPushLines then 
			BotEcho('^p-----------------------------Got em')
			if bSuccess then BotEcho('Gotemhard') else BotEcho('at least i tried') end
		end
	end
	
	return bSuccess
end

-- both functions below call for the creep push, however 
function object.PushExecuteOverride(botBrain)
	if not object.CreepPush(botBrain) then 
		object.PushExecuteOld(botBrain)
	end
end
object.PushExecuteOld = behaviorLib.PushBehavior["Execute"]
behaviorLib.PushBehavior["Execute"] = object.PushExecuteOverride


local function TeamGroupBehaviorOverride(botBrain)
	object.TeamGroupBehaviorOld(botBrain)
	object.CreepPush(botBrain)
end
object.TeamGroupBehaviorOld = behaviorLib.TeamGroupBehavior["Execute"]
behaviorLib.TeamGroupBehavior["Execute"] = TeamGroupBehaviorOverride

BotEcho('finished loading soulreaper_main')
