--
-- Mod: FS22_SimpleInspector
--
-- Author: JTSage
-- source: https://github.com/jtsage/FS22_Simple_Inspector
-- credits: HappyLooser/VehicleInspector for the isOnField logic, and some pointers on where to find info

SimpleInspector= {}

local SimpleInspector_mt = Class(SimpleInspector)

function SimpleInspector:new(mission, modDirectory, modName, logger)
	local self = setmetatable({}, SimpleInspector_mt)

	self.myName            = "SimpleInspector"
	self.logger            = logger
	self.isServer          = mission:getIsServer()
	self.isClient          = mission:getIsClient()
	self.isMPGame          = g_currentMission.missionDynamicInfo.isMultiplayer
	self.mission           = mission
	self.modDirectory      = modDirectory
	self.modName           = modName
	self.gameInfoDisplay   = mission.hud.gameInfoDisplay
	self.inputHelpDisplay  = mission.hud.inputHelp
	self.speedMeterDisplay = mission.hud.speedMeter
	self.ingameMap         = mission.hud.ingameMap

	source(modDirectory .. 'lib/fs22ModPrefSaver.lua')
	source(modDirectory .. 'lib/fs22FSGUnitConvert.lua')

	self.convert  = FS22FSGUnits:new(self.logger)

	self.settings = FS22PrefSaver:new(
		"FS22_SimpleInspector",
		"simpleInspector.xml",
		true,
		{
			displayOrder    = "SPD_SEP_GAS_SEP_DAM*_FLD*_AIT*_USR-_VEH_FIL",
			displayMode     = {3, "int" },
			displayMode5X   = 0.2,
			displayMode5Y   = 0.2,

			isEnabledVisible         = true,
			isEnabledWhenHUDHidden   = false,
			isEnabledSolidUnit       = { 1, "int" },
			isEnabledLiquidUnit      = { 1, "int" },
			isEnabledAlphaSort       = true,
			isEnabledShowPlayer      = true,
			isEnabledShowAll         = false,
			isEnabledShowUnowned     = false,
			isEnabledShowFillPercent = true,
			isEnabledShowFuel        = true,
			isEnabledShowBeacon      = true,
			isEnabledShowDef         = false,
			isEnabledShowSpeed       = true,
			isEnabledShowFills       = true,
			isEnabledShowField       = true,
			isEnabledShowFieldNum    = true,
			isEnabledPadFieldNum     = true,
			isEnabledShowDamage      = true,
			setValueDamageThreshold  = 0.8, -- 20% Damaged
			isEnabledShowCPWaypoints = true,
			isEnabledShowADTime      = true,
			isEnabledShowCPTime      = true,

			setValueMaxDepth        = {5, "int"},

			setValueTextMarginX     = {15, "int"},
			setValueTextMarginY     = {10, "int"},
			setValueTextSize        = {12, "int"},
			isEnabledTextBold       = false,

			colorNormal     = {{1.000, 1.000, 1.000, 1}, "color"},
			colorFillType   = {{0.700, 0.700, 0.700, 1}, "color"},
			colorUser       = {{0.000, 0.777, 1.000, 1}, "color"},
			colorAI         = {{0.956, 0.462, 0.644, 1}, "color"},
			colorRunning    = {{0.871, 0.956, 0.423, 1}, "color"},
			colorAIMark     = {{1.000, 0.082, 0.314, 1}, "color"},
			colorSep        = {{1.000, 1.000, 1.000, 1}, "color"},
			colorSpeed      = {{1.000, 0.400, 0.000, 1}, "color"},
			colorDiesel     = {{0.434, 0.314, 0.000, 1}, "color"},
			colorDEF        = {{0.162, 0.440, 0.880, 1}, "color"},
			colorMethane    = {{1.000, 0.930, 0.000, 1}, "color"},
			colorElectric   = {{0.031, 0.578, 0.314, 1}, "color"},
			colorField      = {{0.423, 0.956, 0.624, 1}, "color"},
			colorDamaged    = {{0.830, 0.019, 0.033, 1}, "color"},

			setStringTextHelper      = "_AI_",
			setStringTextADHelper    = "_AD_",
			setStringTextADWaypoint  = "_AD:",
			setStringTextCPHelper    = "_CP_",
			setStringTextCPWaypoint  = "_CP:",
			setStringTextDEF         = "DEF:",
			setStringTextDiesel      = "D:",
			setStringTextMethane     = "M:",
			setStringTextElectric    = "E:",
			setStringTextField       = "F-",
			setStringTextFieldNoNum  = "-F-",
			setStringTextDamaged     = "-!!-",
			setStringTextSep         = " | ",
		},
		function ()
			self.inspectText.size = self.gameInfoDisplay:scalePixelToScreenHeight(self.settings:getValue("setValueTextSize"))
		end,
		nil,
		self.logger
	)

	self.debugTimerRuns         = 0
	self.setValueTimerFrequency = 15
	self.inspectText            = {}
	self.boxBGColor             = { 544, 20, 200, 44 }
	self.bgName                 = 'dataS/menu/blank.png'
	self.menuTextSizes          = { 8, 10, 12, 14, 16, 18, 20 }

	local modDesc       = loadXMLFile("modDesc", modDirectory .. "modDesc.xml");
	self.version        = getXMLString(modDesc, "modDesc.version");
	delete(modDesc)

	self.display_data = { }

	self.shown_farms_mp = 0

	self.fill_invert_all = {
		fertilizingcultivatorroller    = true,
		manuretrailer                  = true,
		manurebarrel                   = true,
		selfpropelledmanurebarrel      = true,
		watertrailer                   = true,
		weederfertilizing              = true,
		saltspreader                   = true,
		fertilizingcultivator          = true,
		weedersowingmachine            = true,
		fertilizingsowingmachine       = true,
		treeplanter                    = true,
		weederfertilizingsowingmachine = true,
		spreader                       = true,
		sprayer                        = true,
		sowingmachine                  = true,
		manurespreader                 = true,
		cultivatingsowingmachine       = true,
		strawblower                    = true,
		fueltrailer                    = true,
		seedingroller                  = true,
		selfpropelledsprayer           = true,
	}
	self.fill_invert_types = {
		[FillType.SEEDS]            = true,
		[FillType.ROADSALT]         = true,
		[FillType.FERTILIZER]       = true,
		[FillType.LIME]             = true,
		[FillType.SILAGE_ADDITIVE]  = true,
		[FillType.LIQUIDFERTILIZER] = true,
		[FillType.HERBICIDE]        = true
	}

	self.STATUS            = {}
	self.STATUS.RUNNING    = 3
	self.STATUS.CONTROLLED = 2
	self.STATUS.AI         = 1
	self.STATUS.OFF        = 0

	self.STATUS_COLOR = {
		[self.STATUS.RUNNING]    = "colorRunning",
		[self.STATUS.CONTROLLED] = "colorUser",
		[self.STATUS.AI]         = "colorAI",
		[self.STATUS.OFF]        = "colorNormal"
	}

	self.BEACON_PERC = {
		[0] = 100,
		[1] = 98,
		[2] = 96,
		[3] = 94,
		[4] = 92,
		[5] = 92,
		[6] = 94,
		[7] = 96,
		[8] = 98,
		[9] = 100
	}
	self.COMPASS = {
		[0] = g_i18n:getText('unit_fsgDirection_N'),
		[1] = g_i18n:getText('unit_fsgDirection_NE'),
		[2] = g_i18n:getText('unit_fsgDirection_E'),
		[3] = g_i18n:getText('unit_fsgDirection_SE'),
		[4] = g_i18n:getText('unit_fsgDirection_S'),
		[5] = g_i18n:getText('unit_fsgDirection_SW'),
		[6] = g_i18n:getText('unit_fsgDirection_W'),
		[7] = g_i18n:getText('unit_fsgDirection_NW'),
		[8] = g_i18n:getText('unit_fsgDirection_N'),
	}

	self.logger:print(":new() Initialized", FS22Log.LOG_LEVEL.VERBOSE, "method_track")

	return self
end

function SimpleInspector:save()
	self.settings:saveSettings()
end

function SimpleInspector:openConstructionScreen()
	-- hack for construction screen showing blank box.
	g_simpleInspector.inspectBox:setVisible(false)
end

function SimpleInspector:getAllDamage(vehicle )
	-- This is not recusive.  It checks the tractor, and immediate implements only.
	-- Shortcut method, first damage above threshold returns true.
	if self:getDamageBad(vehicle) then return true end

	if vehicle.getAttachedImplements ~= nil then
		local attachedImplements = vehicle:getAttachedImplements();
		for _, implement in pairs(attachedImplements) do
			if implement.object ~= nil then
				if self:getDamageBad(implement.object) then return true end
			end
		end
	end

	return false
end

function SimpleInspector:getDamageBad(vehicle)
	if vehicle.getDamageAmount == nil then return false end

	local damageLevel = math.min(1, 1 - vehicle:getDamageAmount())

	if damageLevel == nil then return false end

	return vehicle.isBroken or damageLevel < self.settings:getValue("setValueDamageThreshold")
end

function SimpleInspector:getIsOnField(vehicle)
	local fieldNumber = 0
	local isField     = false
	local wx, wy, wz  = 0, 0, 0

	local function getIsOnField()
		if vehicle.components == nil then return false end

		for _, component in pairs(vehicle.components) do
			wx, wy, wz = localToWorld(component.node, getCenterOfMass(component.node))

			local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz)

			if h-1 > wy then -- 1m threshold since ground tools are working slightly under the ground
				break
			end

			local isOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(wx, wy, wz)
			if isOnField then
				isField = true
				return true
			end
		end
		return false
	end
	if getIsOnField() then
		if ( not self.settings:getValue("isEnabledShowFieldNum") ) then
			-- short cut field number detection if we won't display it anyways.
			return { fieldOn = isField, fieldNum = 0 }
		end

		local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(wx, wz)
		if farmlandId ~= nil then

			local foundField = false

			for f=1, #g_fieldManager.fields do

				if foundField then break end

				local field = g_fieldManager.fields[f]

				if field ~= nil and field.farmland ~= nil and field.farmland.id == farmlandId then
					local fieldId = field.fieldId

					-- set this as a "fall back" if we don't get a "real" field number below
					-- this is likely to happen on any enlarged fields, and at the borders of a lot
					-- of the base game maps.
					fieldNumber = fieldId

					for a=1, #field.setFieldStatusPartitions do
						local b                    = field.setFieldStatusPartitions[a]
						local x, z, wX, wZ, hX, hZ = b.x0, b.z0, b.widthX, b.widthZ, b.heightX, b.heightZ
						local distanceMax          = math.max(wX,wZ,hX,hZ)
						local distance             = MathUtil.vector2Length(wx-x,wz-z);
						if distance <= distanceMax then
							fieldNumber = fieldId
							foundField  = true
							break
						end
					end
				end
			end
		end
	end
	return { fieldOn = isField, fieldNum = fieldNumber }
end

function SimpleInspector:getFuel(vehicle)
	local defLevel
	local fuelTypeList = {
		{
			FillType.DIESEL,
			"colorDiesel",
			self.settings:getValue("setStringTextDiesel")
		}, {
			FillType.ELECTRICCHARGE,
			"colorElectric",
			self.settings:getValue("setStringTextElectric")
		}, {
			FillType.METHANE,
			"colorMethane",
			self.settings:getValue("setStringTextMethane")
		}
	}

	if vehicle.getConsumerFillUnitIndex ~= nil then
		-- This should always pass, unless it's a very odd custom vehicle type.
		local defFillUnitIndex = vehicle:getConsumerFillUnitIndex(FillType.DEF)

		if defFillUnitIndex ~= nil then
			defLevel = JTSUtil.calcPercent(
				vehicle:getFillUnitFillLevel(defFillUnitIndex),
				vehicle:getFillUnitCapacity(defFillUnitIndex),
				false
			)
		end

		for _, fuelType in pairs(fuelTypeList) do
			local fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType[1])
			if ( fillUnitIndex ~= nil ) then
				return {
					color     = fuelType[2],
					text      = fuelType[3],
					fuelLevel = JTSUtil.calcPercent(
						vehicle:getFillUnitFillLevel(fillUnitIndex),
						vehicle:getFillUnitCapacity(fillUnitIndex),
						false
					),
					defLevel  = defLevel
				}
			end
		end
	end
	return nil -- unknown fuel type, should not be possible.
end

function SimpleInspector:getSpeed(vehicle)
	-- Get the current speed of the vehicle
	local speedMulti = g_gameSettings:getValue('useMiles') and 0.621371 or 1
	local speed = math.max(Utils.getNoNil(vehicle.lastSpeed, 0) * 3600 * speedMulti, 0)

	return string.format("%1.0f", speed)
end

function SimpleInspector:getDirection(vehicle)
	-- local posX, posY, posZ = getTranslation(vehicle.rootNode)
	local dx, _, dz = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
	local yRot = nil

	if vehicle.spec_drivable ~= nil and vehicle.spec_drivable.reverserDirection == -1 then
		yRot = MathUtil.getYRotationFromDirection(dx, dz)
	else
		yRot = MathUtil.getYRotationFromDirection(dx, dz) + math.pi
	end

	local realRotation     = math.deg(-yRot % (2 * math.pi))
	local realRotationIdx  = MathUtil.round(realRotation / 45)
	local realRotationText = self.COMPASS[realRotationIdx]
	local realDirection    = vehicle:getDrivingDirection()
	local driveDirection   = realDirection == -1 and "↓" or realDirection == 1 and "↑" or "" -- forawrd = 1, reverse = -1, not moving = 0

	return realRotationText .. driveDirection
end

function SimpleInspector:getSingleFill(vehicle, theseFills)
	-- This is the single run at the fill type, for the current vehicle only.
	-- Borrowed heavily from older versions of similar plugins, ignores unknown fill types

	local spec_fillUnit = vehicle.spec_fillUnit

	if spec_fillUnit ~= nil and spec_fillUnit.fillUnits ~= nil then
		local vehicleTypeName = Utils.getNoNil(vehicle.typeName, "unknown"):lower()
		local isInverted      = self.fill_invert_all[vehicleTypeName] ~= nil
		local checkInvert     = not isInverted

		for i = 1, #spec_fillUnit.fillUnits do
			local fillUnit = spec_fillUnit.fillUnits[i]
			if fillUnit.capacity > 0 and fillUnit.showOnHud then
				local fillType = fillUnit.fillType;
				if fillType == FillType.UNKNOWN and table.size(fillUnit.supportedFillTypes) == 1 then
					fillType = next(fillUnit.supportedFillTypes)
				end
				if fillUnit.fillTypeToDisplay ~= FillType.UNKNOWN then
					isInverted  = self.fill_invert_types[fillType] ~= nil
					checkInvert = false
					fillType    = fillUnit.fillTypeToDisplay
				end

				local fillLevel = fillUnit.fillLevel;
				if fillUnit.fillLevelToDisplay ~= nil then
					fillLevel = fillUnit.fillLevelToDisplay
				end

				fillLevel = math.ceil(fillLevel)

				local capacity = fillUnit.capacity
				if fillUnit.parentUnitOnHud ~= nil then
					if fillType == FillType.UNKNOWN then
						fillType = spec_fillUnit.fillUnits[fillUnit.parentUnitOnHud].fillType;
					end
					capacity = 0
				elseif fillUnit.childUnitOnHud ~= nil and fillType == FillType.UNKNOWN then
					fillType = spec_fillUnit.fillUnits[fillUnit.childUnitOnHud].fillType
				end

				local maxMatters = fillUnit.updateMass and not fillUnit.ignoreFillLimit and g_currentMission.missionInfo.trailerFillLimit
				local maxReached = maxMatters and vehicle.getMaxComponentMassReached ~= nil and vehicle:getMaxComponentMassReached();

				if maxReached then
					-- We be full, do no more math.
					capacity = fillLevel
				elseif maxMatters and fillLevel > 0 then
					-- adjust capacity for max weight (must have a fillLevel)
					if ( math.huge ~= vehicle.maxComponentMass ) then
						-- if max is infinity, just use stated capactiy
						local fillTypeDesc  = g_fillTypeManager:getFillTypeByIndex(fillType)

						-- get the weight available to fill
						local vehCapacityByWeight = vehicle.maxComponentMass - vehicle:getDefaultMass()
						-- divide that by the mass of our filltype to get max available liters
						local vehCapacityByWeightLiters = math.ceil(vehCapacityByWeight / fillTypeDesc.massPerLiter)

						-- take the smaller number of allowed mass or stated cap limit
						capacity = math.min(capacity, vehCapacityByWeightLiters)
					end
				end

				if fillLevel > 0 then
					if checkInvert then isInverted = self.fill_invert_types[fillType] ~= nil end

					if ( theseFills[fillType] ~= nil ) then
						theseFills[fillType]["level"]    = theseFills[fillType]["level"] + fillLevel
						theseFills[fillType]["capacity"] = theseFills[fillType]["capacity"] + capacity
					else
						theseFills[fillType] = { level = fillLevel, capacity = capacity, reverse = isInverted }
					end
				end
			end
		end
	end
	return theseFills
end

function SimpleInspector:getAllFills(vehicle, fillLevels, depth)
	-- This is the recursive function, to a max depth of `maxDepth` (default 5)
	-- That's 5 levels of attachments, so 5 trailers, #6 gets ignored.
	self:getSingleFill(vehicle, fillLevels)

	if vehicle.getAttachedImplements ~= nil and depth < self.settings:getValue("setValueMaxDepth") then
		local attachedImplements = vehicle:getAttachedImplements();
		for _, implement in pairs(attachedImplements) do
			if implement.object ~= nil then
				local newDepth = depth + 1
				self:getAllFills(implement.object, fillLevels, newDepth)
			end
		end
	end
end

function SimpleInspector:updateVehicles()
	local new_data_table = {}
	local myFarmID       = self.mission:getFarmId()

	self.shown_farms_mp  = 0

	if g_currentMission ~= nil and g_currentMission.vehicles ~= nil then

		local sortOrder = {}

		for v=1, #g_currentMission.vehicles do
			local thisVeh    = g_currentMission.vehicles[v]
			local thisFarmID = 0

			if ( self.isMPGame ) then
				thisFarmID = thisVeh.ownerFarmId
			end

			if ( not self.isMPGame or myFarmID == thisFarmID or (self.settings:getValue("isEnabledShowUnowned") and thisFarmID ~= 0 ) ) then
				table.insert(sortOrder, {
					idx    = v,
					name   = thisVeh:getFullName(),
					farmID = thisFarmID
				})
			end
		end

		if self.settings:getValue("isEnabledAlphaSort") then
			-- Alpha sort vehicles (tab order otherwise)
			JTSUtil.sortTableByKey(sortOrder, "name")
		end

		if self.isMPGame then
			-- We need to sort by farmID last - also controls how many headings we see later.
			JTSUtil.sortTableByKey(sortOrder, "farmID")
		end

		local lastFarmID = -1

		for _, sortEntry in ipairs(sortOrder) do
			local thisVeh     = g_currentMission.vehicles[sortEntry.idx]
			local thisVehFarm = g_farmManager:getFarmById(sortEntry.farmID)

			if thisVeh ~= nil and thisVeh.getIsControlled ~= nil then
				local typeName         = Utils.getNoNil(thisVeh.typeName, "unknown")
				local isTrain          = typeName == "locomotive"
				local isBelt           = typeName == "conveyorBelt" or typeName == "pickupConveyorBelt"
				local isRidable        = SpecializationUtil.hasSpecialization(Rideable, thisVeh.specializations)
				local isSteerImplement = thisVeh.spec_attachable ~= nil

				if ( not isTrain and not isRidable and not isBelt and not isSteerImplement ) then
					local isRunning = thisVeh.getIsMotorStarted ~= nil and thisVeh:getIsMotorStarted()
					local isOnAI    = thisVeh.getIsAIActive ~= nil     and thisVeh:getIsAIActive()
					local isConned  = thisVeh.getIsControlled ~= nil   and thisVeh:getIsControlled()

					if ( self.settings:getValue("isEnabledShowAll") or isConned or isRunning or isOnAI ) then
						local plyrName  = self.isMPGame and self.settings:getValue("isEnabledShowPlayer") and isConned and thisVeh.getControllerName ~= nil and thisVeh:getControllerName() or nil
						local AFMHotKey = thisVeh.getHotKeyVehicleState ~= nil and thisVeh:getHotKeyVehicleState() or 0
						local fullName  = thisVeh:getFullName()
						local speed     = self:getSpeed(thisVeh)
						local direction = self:getDirection(thisVeh)
						local fills     = {}
						local status    = self.STATUS.OFF
						local isAI      = {aiActive = false, aiText = ""}
						local isOnField = {fieldOn = false, fieldNum = 0}
						local isBroken  = self.settings:getValue("isEnabledShowDamage") and self:getAllDamage(thisVeh)
						local vehLights = thisVeh.spec_lights
						local vehBeacon = false

						if self.settings:getValue("isEnabledShowBeacon") and vehLights ~= nil then
							vehBeacon = vehLights.beaconLightsActive
						end

						if AFMHotKey > 0 then
							fullName = JTSUtil.qConcat("[", AFMHotKey, "] ", fullName)
						end

						if self.settings:getValue("isEnabledShowField") then
							-- This may be compute heavy, only do it when wanted.
							isOnField = self:getIsOnField(thisVeh)
						end

						if self.settings:getValue("isEnabledShowAll") and isRunning then
							-- If we show all, use "colorRunning", otherwise just the normal one
							-- AI and user control take precedence, in that order
							status = self.STATUS.RUNNING
						end
						if isOnAI then
							-- second highest precendence
							status = self.STATUS.AI

							-- default text, override for AD & CP below.
							isAI.aiActive = true
							isAI.aiText   = self.settings:getValue("setStringTextHelper")

							-- is AD driving
							if thisVeh.ad ~= nil and thisVeh.ad.stateModule ~= nil and thisVeh.ad.stateModule:isActive() then
								local adTimeRemain = thisVeh.ad.stateModule:getRemainingDriveTime()
								local adMin = math.floor(adTimeRemain / 60)
								local adSec = math.floor(adTimeRemain - ( adMin * 60))
								local adTimeString = JTSUtil.qConcat(adSec, 's')
								if ( adMin > 0 ) then
									adTimeString = JTSUtil.qConcat(adMin, 'm:', adTimeString)
								end
								if adTimeRemain > 0 and self.settings:getValue("isEnabledShowADTime") then
									isAI.aiText = JTSUtil.qConcat(self.settings:getValue("setStringTextADWaypoint"), adTimeString)
								else
									isAI.aiText = self.settings:getValue("setStringTextADHelper")
								end
							end

							-- is CP driving, and should we show waypoints?
							if thisVeh.getCpStatus ~= nil then
								local cpStatus = thisVeh:getCpStatus()
								local mayUseBoth = false
								if cpStatus:getIsActive() then
									isAI.aiText = self.settings:getValue("setStringTextCPHelper")
									if ( self.settings:getValue("isEnabledShowCPWaypoints") ) then
										mayUseBoth  = true
										isAI.aiText = JTSUtil.qConcat(self.settings:getValue("setStringTextCPWaypoint"), cpStatus:getWaypointText() , "_")
									end
									if self.settings:getValue("isEnabledShowCPTime") then
										local cpTimeRemain = cpStatus:getTimeRemainingText()
										if cpTimeRemain ~= "" then
											if mayUseBoth then
												isAI.aiText = JTSUtil.qConcat(isAI.aiText, cpTimeRemain, "_")
											else
												isAI.aiText = JTSUtil.qConcat(self.settings:getValue("setStringTextCPWaypoint"), cpTimeRemain, "_")
											end
										end
									end
								end
							end
						end
						if isConned then
							-- highest precendence
							status = self.STATUS.CONTROLLED
						end

						self:getAllFills(thisVeh, fills, 0)

						if self.isMPGame and sortEntry.farmID ~= lastFarmID then
							-- this counts how many farms we have active in the display
							lastFarmID = sortEntry.farmID
							self.shown_farms_mp = self.shown_farms_mp + 1
						end

						table.insert(new_data_table, {
							beacon    = vehBeacon,
							status    = status,
							isAI      = isAI,
							fullName  = fullName,
							speed     = tostring(speed),
							direction = direction,
							fuelLevel = self:getFuel(thisVeh),
							fills     = fills,
							isOnField = isOnField,
							isBroken  = isBroken,
							plyrName  = plyrName,
							farmInfo  = { farmID = sortEntry.farmID, farmName = thisVehFarm.name, farmColor = Farm.COLORS[thisVehFarm.color]}
						})
					end
				end
			end
		end
	end

	self.logger:printVariable(new_data_table, FS22Log.LOG_LEVEL.VERBOSE, "display_data", 3)

	self.display_data = {unpack(new_data_table)}
end

function SimpleInspector:draw()
	if not self.isClient then
		return
	end

	if self.inspectBox ~= nil then
		local info_text = self.display_data
		local overlayH, dispTextH, dispTextW = 0, 0, 0
		local outputTextLines = {}

		if #info_text == 0 or not self.settings:getValue("isEnabledVisible") or g_sleepManager:getIsSleeping() then
			-- we have no entries, hide the overlay and leave
			self.inspectBox:setVisible(false)
			return
		elseif not self.settings:getValue("isEnabledWhenHUDHidden") and ( g_noHudModeEnabled or not g_currentMission.hud.isVisible ) then
			-- HUD is hidden, and we respect that
			self.inspectBox:setVisible(false)
			return
		elseif g_gameSettings:getValue("ingameMapState") == 4 and self.settings:getValue("displayMode") % 2 ~= 0 and g_currentMission.inGameMenu.hud.inputHelp.overlay.visible then
			-- Left side display hide on big map with help open
			self.inspectBox:setVisible(false)
			return
		elseif self.settings:getValue("displayMode") == 3 and g_currentMission.hud.chatWindow.overlay.visible then
			-- Over map display and chat is visible, so hide.
			self.inspectBox:setVisible(false)
			return
		else
			-- we have entries, lets get the overall height of the box and unhide
			self.inspectBox:setVisible(true)
			dispTextH = (self.inspectText.size * #info_text) + (self.inspectText.size * self.shown_farms_mp)
			overlayH  = dispTextH + ( 2 * self.inspectText.marginHeight)
		end

		setTextBold(self.settings:getValue("isEnabledTextBold"))
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)

		-- overlayX/Y is where the box starts
		local overlayX, overlayY = self:findOrigin()
		-- dispTextX/Y is where the text starts (sort of)
		local dispTextX, dispTextY = self:findOrigin()

		if ( self.settings:getValue("displayMode") == 2 ) then
			-- top right (subtract both margins)
			dispTextX = dispTextX - self.marginWidth
			dispTextY = dispTextY - self.marginHeight
			overlayY  = overlayY - overlayH
		elseif ( self.settings:getValue("displayMode") == 3 ) then
			-- bottom left (add x width, add Y height)
			dispTextX = dispTextX + self.marginWidth
			dispTextY = dispTextY - self.marginHeight + overlayH
		elseif ( self.settings:getValue("displayMode") == 4 ) then
			-- bottom right (subtract x width, add Y height)
			dispTextX = dispTextX - self.marginWidth
			dispTextY = dispTextY - self.marginHeight + overlayH
		else
			-- top left (add X width, subtract Y height)
			dispTextX = dispTextX + self.marginWidth
			dispTextY = dispTextY - self.marginHeight
			overlayY  = overlayY - overlayH
		end

		if ( self.settings:getValue("displayMode") % 2 == 0 ) then
			setTextAlignment(RenderText.ALIGN_RIGHT)
		else
			setTextAlignment(RenderText.ALIGN_LEFT)
		end

		if g_currentMission.hud.sideNotifications ~= nil and self.settings:getValue("displayMode") == 2 then
			if #g_currentMission.hud.sideNotifications.notificationQueue > 0 then
				local deltaY = g_currentMission.hud.sideNotifications:getHeight()
				dispTextY = dispTextY - deltaY
				overlayY  = overlayY - deltaY
			end
		end

		self.inspectText.posX = dispTextX
		self.inspectText.posY = dispTextY

		local displayOrderTable = JTSUtil.stringSplit(self.settings:getValue("displayOrder"), "_")

		local lastFarmID = -1
		local beaconFrame = g_updateLoopIndex % 10
		local beaconColor = JTSUtil.colorPercent(self.BEACON_PERC[beaconFrame], true)

		for _, thisEntry in pairs(info_text) do

			if self.isMPGame and lastFarmID ~= thisEntry.farmInfo.farmID then
				-- Show the farm name, it's different from the last entry
				lastFarmID = thisEntry.farmInfo.farmID

				JTSUtil.dispStackAdd(outputTextLines, thisEntry.farmInfo.farmName, thisEntry.farmInfo.farmColor, true)
			end

			JTSUtil.stackNewRow(outputTextLines)

			if self.settings:getValue("isEnabledShowBeacon") and thisEntry.beacon then
				JTSUtil.dispStackAdd(
					outputTextLines,
					"@ ",
					beaconColor
				)
			end

			for _, dispElement in pairs(displayOrderTable) do
				local doAddSeperator = false

				if dispElement:sub(1,3) == "SPD" and self.settings:getValue("isEnabledShowSpeed") then
					-- Vehicle speed
					doAddSeperator = true

					JTSUtil.dispStackAdd(
						outputTextLines,
						JTSUtil.qConcatS(
							thisEntry.speed,
							g_i18n:getText(g_gameSettings:getValue('useMiles') and "text_simpleInspector_mph" or "text_simpleInspector_kph"),
							thisEntry.direction
						),
						self:getNamedColor("colorSpeed")
					)
				end

				if dispElement:sub(1,3) == "GAS" and self.settings:getValue("isEnabledShowFuel") and thisEntry.fuelLevel ~= nil then
					-- Vehicle fuel { color, text, fuelLevel, defLevel }
					doAddSeperator = true

					JTSUtil.dispStackAdd(
						outputTextLines,
						thisEntry.fuelLevel.text,
						self:getNamedColor(thisEntry.fuelLevel.color)
					)
					JTSUtil.dispStackAdd(
						outputTextLines,
						JTSUtil.qConcat(thisEntry.fuelLevel.fuelLevel, "%"),
						JTSUtil.colorPercent(thisEntry.fuelLevel.fuelLevel)
					)

					if self.settings:getValue("isEnabledShowDef") and thisEntry.fuelLevel.defLevel then
						JTSUtil.dispStackAdd(
							outputTextLines,
							self.settings:getValue("setStringTextSep"),
							self:getNamedColor("colorSep")
						)
						JTSUtil.dispStackAdd(
							outputTextLines,
							self.settings:getValue("setStringTextDEF"),
							self:getNamedColor("colorDEF")
						)
						JTSUtil.dispStackAdd(
							outputTextLines,
							JTSUtil.qConcat(thisEntry.fuelLevel.defLevel, "%"),
							JTSUtil.colorPercent(thisEntry.fuelLevel.defLevel)
						)
					end

				end

				if dispElement:sub(1,3) == "DAM" and self.settings:getValue("isEnabledShowDamage") and thisEntry.isBroken then
					-- Damage marker tag
					doAddSeperator = true
					JTSUtil.dispStackAdd(
						outputTextLines,
						self.settings:getValue("setStringTextDamaged"),
						self:getNamedColor("colorDamaged")
					)
				end

				if dispElement:sub(1,3) == "FLD" and self.settings:getValue("isEnabledShowField") and thisEntry.isOnField.fieldOn then
					-- Field mark isOnField.{fieldOn = false, fieldNum = 0}
					doAddSeperator = true

					local fieldNum = self.settings:getValue("isEnabledPadFieldNum") and string.format('%02d', thisEntry.isOnField.fieldNum) or thisEntry.isOnField.fieldNum

					JTSUtil.dispStackAdd(
						outputTextLines,
						thisEntry.isOnField.fieldNum == 0 and self.settings:getValue("setStringTextFieldNoNum") or JTSUtil.qConcat(self.settings:getValue("setStringTextField"), fieldNum),
						self:getNamedColor("colorField")
					)
				end

				if dispElement:sub(1,3) == "AIT" and thisEntry.isAI.aiActive then
					-- AI Tag isAI.{aiActive = false, aiText = ""}
					doAddSeperator = true
					JTSUtil.dispStackAdd(
						outputTextLines,
						thisEntry.isAI.aiText,
						self:getNamedColor("colorAIMark")
					)
				end

				if dispElement:sub(1,3) == "USR" and thisEntry.plyrName then
					-- User name
					doAddSeperator = true
					JTSUtil.dispStackAdd(
						outputTextLines,
						JTSUtil.qConcat("[", thisEntry.plyrName, "]"),
						self:getNamedColor("colorUser")
					)
				end

				-- Vehicle name
				if dispElement:sub(1,3) == "VEH" then
					doAddSeperator = true
					JTSUtil.dispStackAdd(
						outputTextLines,
						thisEntry.fullName,
						self:getNamedColor(self.STATUS_COLOR[thisEntry.status])
					)
				end

				if dispElement:sub(1,3) == "FIL" and self.settings:getValue("isEnabledShowFills") then
					for fillTypeIndex, fillTypeInfo in pairs(thisEntry.fills) do
						-- fillTypeInfo.{ level = fillLevel, capacity = capacity, reverse = isInverted }

						doAddSeperator = true

						-- Seperator between fill types / vehicle
						JTSUtil.dispStackAdd(
							outputTextLines,
							self.settings:getValue("setStringTextSep"),
							self:getNamedColor("colorSep")
						)

						local thisFillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
						local thisPercent  = JTSUtil.calcPercent(fillTypeInfo.level, fillTypeInfo.capacity)
						local fillColor    = JTSUtil.colorPercent(thisPercent, not fillTypeInfo.reverse)

						JTSUtil.dispStackAdd(
							outputTextLines,
							thisFillType.title .. ":",
							self:getNamedColor("colorFillType")
						)
						JTSUtil.dispStackAdd(
							outputTextLines,
							self.convert:scaleFillTypeLevel(
								fillTypeIndex,
								fillTypeInfo.level,
								self.settings:getValue("isEnabledSolidUnit"),
								self.settings:getValue("isEnabledLiquidUnit")
							),
							fillColor
						)

						if self.settings:getValue("isEnabledShowFillPercent") then
							JTSUtil.dispStackAdd(
								outputTextLines,
								JTSUtil.qConcat(" (", thisPercent, "%)"),
								fillColor
							)
						end
					end
				end

				if dispElement == "SEP" or ( dispElement:sub(-1) == "*" and doAddSeperator ) then
					-- Seperator (or Element with star)
					JTSUtil.dispStackAdd(
						outputTextLines,
						self.settings:getValue("setStringTextSep"),
						self:getNamedColor("colorSep")
					)
				end

				if dispElement:sub(-1) == "-" and doAddSeperator then
					-- Extra space
					JTSUtil.dispStackAdd(
						outputTextLines,
						" ",
						{1,1,1,1}
					)
				end
			end
		end

		self.logger:printVariable(outputTextLines, FS22Log.LOG_LEVEL.VERBOSE, "outputTextLines", 3)

		for dispLineNum=1, #outputTextLines do
			local thisLinePlainText = ""

			for _, dispElement in ipairs(JTSUtil.dispGetLine(outputTextLines, dispLineNum, (self.settings:getValue("displayMode") % 2 == 0) )) do
				if ( type(dispElement.color) == "table" ) then
					setTextColor(unpack(dispElement.color))
				else
					setTextColor(0.8,0.8,0.8,1)
				end

				thisLinePlainText = self:renderText(
					dispTextX,
					dispTextY,
					thisLinePlainText,
					dispElement.text)
			end

			dispTextY = dispTextY - self.inspectText.size

			local tmpW = getTextWidth(self.inspectText.size, thisLinePlainText)

			if tmpW > dispTextW then dispTextW = tmpW end
		end

		-- update overlay background
		if self.settings:getValue("displayMode") % 2 == 0 then
			self.inspectBox.overlay:setPosition(overlayX - ( dispTextW + ( 2 * self.inspectText.marginWidth ) ), overlayY)
		else
			self.inspectBox.overlay:setPosition(overlayX, overlayY)
		end

		self.inspectBox.overlay:setDimension(dispTextW + (self.inspectText.marginWidth * 2), overlayH)

		-- reset text render to "defaults" to be kind
		setTextColor(1,1,1,1)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		setTextBold(false)
	end
end

function SimpleInspector:update(dt)
	if not self.isClient then
		return
	end

	if g_updateLoopIndex % self.setValueTimerFrequency == 0 then
		-- Lets not be rediculous, only update the vehicles "infrequently"
		self:updateVehicles()
	end
end

function SimpleInspector:getNamedColor(name)
	return Utils.getNoNil(self.settings:getValue(name), {1,1,1,1})
end

function SimpleInspector:renderText(x, y, fullTextSoFar, text)
	local newX = x

	if self.settings:getValue("displayMode") % 2 == 0 then
		newX = newX - getTextWidth(self.inspectText.size, fullTextSoFar)
	else
		newX = newX + getTextWidth(self.inspectText.size, fullTextSoFar)
	end

	renderText(newX, y, self.inspectText.size, text)
	return text .. fullTextSoFar
end

function SimpleInspector:onStartMission(mission)
	-- Load the mod, make the box that info lives in.

	self.logger:print(JTSUtil.qConcat("Loaded - version : ", self.version), FS22Log.LOG_LEVEL.INFO, "user_info")

	if not self.isClient then
		return
	end

	-- Just call both, load fails gracefully if it doesn't exists.
	self.settings:loadSettings()
	self.settings:saveSettings()

	self.logger:print(":onStartMission()", FS22Log.LOG_LEVEL.VERBOSE, "method_track")

	self:createTextBox()
end

function SimpleInspector:findOrigin()
	local tmpX = 0
	local tmpY = 0

	if ( self.settings:getValue("displayMode") == 2 ) then
		-- top right display
		tmpX, tmpY = self.gameInfoDisplay:getPosition()
		tmpX = 1
		tmpY = tmpY - 0.012
	elseif ( self.settings:getValue("displayMode") == 3 ) then
		-- Bottom left, correct origin.
		tmpX = 0.01622
		tmpY = 0 + self.ingameMap:getHeight() + 0.01622
		if g_gameSettings:getValue("ingameMapState") > 1 then
			tmpY = tmpY + 0.032
		end
	elseif ( self.settings:getValue("displayMode") == 4 ) then
		-- bottom right display
		tmpX = 1
		tmpY = 0.01622
		if g_currentMission.inGameMenu.hud.speedMeter.overlay.visible then
			tmpY = tmpY + self.speedMeterDisplay:getHeight() + 0.032
			if g_modIsLoaded["FS22_EnhancedVehicle"] or g_modIsLoaded["FS22_guidanceSteering"] then
				tmpY = tmpY + 0.03
			end
		end
	elseif ( self.settings:getValue("displayMode") == 5 ) then
		tmpX = self.settings:getValue("displayMode5X")
		tmpY = self.settings:getValue("displayMode5Y")
	else
		-- top left display
		tmpX = 0.014
		tmpY = 0.945
		if g_currentMission.inGameMenu.hud.inputHelp.overlay.visible then
			tmpY = tmpY - self.inputHelpDisplay:getHeight() - 0.012
		else
			if g_currentMission.controlledVehicle ~= nil and _G['FS22_precisionFarming'] ~= nil then
				for idx, extension in ipairs(self.mission.hud.inputHelp.vehicleHudExtensions) do
					if extension.extendedSowingMachine ~= nil then
						tmpY = tmpY - (Utils.getNoNil(extension.displayHeight , 0) + 0.012)
					elseif extension.extendedSprayer ~= nil then
						tmpY = tmpY - (Utils.getNoNil(extension.displayHeight , 0) - 0.012)
					end
				end
			end
		end
	end

	return tmpX, tmpY
end

function SimpleInspector:createTextBox()
	-- make the box we live in.
	self.logger:print(":createTextBox()", FS22Log.LOG_LEVEL.VERBOSE, "method_track")

	local baseX, baseY = self:findOrigin()

	local boxOverlay = nil

	self.marginWidth, self.marginHeight = self.gameInfoDisplay:scalePixelToScreenVector({ 8, 8 })

	if ( self.settings:getValue("displayMode") % 2 == 0 ) then -- top right
		boxOverlay = Overlay.new(self.bgName, baseX, baseY - self.marginHeight, 1, 1)
	else -- default to 1
		boxOverlay = Overlay.new(self.bgName, baseX, baseY + self.marginHeight, 1, 1)
	end

	local boxElement = HUDElement.new(boxOverlay)

	self.inspectBox = boxElement

	self.inspectBox:setUVs(GuiUtils.getUVs(self.boxBGColor))
	self.inspectBox:setColor(unpack(SpeedMeterDisplay.COLOR.GEARS_BG))
	self.inspectBox:setVisible(false)
	self.gameInfoDisplay:addChild(boxElement)

	self.inspectText.marginWidth, self.inspectText.marginHeight = self.gameInfoDisplay:scalePixelToScreenVector({self.settings:getValue("setValueTextMarginX"), self.settings:getValue("setValueTextMarginY")})
	self.inspectText.size = self.gameInfoDisplay:scalePixelToScreenHeight(self.settings:getValue("setValueTextSize"))
end

function SimpleInspector:delete()
	-- clean up on remove
	if self.inspectBox ~= nil then
		self.inspectBox:delete()
	end
end

function SimpleInspector:registerActionEvents()
	local _, reloadConfig = g_inputBinding:registerActionEvent('SimpleInspector_reload_config', self,
		SimpleInspector.actionReloadConfig, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(reloadConfig, false)
	local _, toggleVisible = g_inputBinding:registerActionEvent('SimpleInspector_toggle_visible', self,
		SimpleInspector.actionToggleVisible, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(toggleVisible, false)
	local _, toggleAllFarms = g_inputBinding:registerActionEvent('SimpleInspector_toggle_allfarms', self,
		SimpleInspector.actionToggleAllFarms, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(toggleAllFarms, false)
end

function SimpleInspector:actionReloadConfig()
	local thisModEnviroment = getfenv(0)["g_simpleInspector"]

	thisModEnviroment.logger:print("force reload settings", FS22Log.LOG_LEVEL.INFO, "user_info")

	thisModEnviroment.settings:loadSettings()
end

function SimpleInspector:actionToggleAllFarms()
	local thisModEnviroment = getfenv(0)["g_simpleInspector"]

	thisModEnviroment.logger:print("toggle all farms", FS22Log.LOG_LEVEL.INFO, "user_info")

	thisModEnviroment.settings:setValue("isEnabledShowUnowned", not thisModEnviroment.settings:getValue("isEnabledShowUnowned"))
	thisModEnviroment.settings:saveSettings()
end

function SimpleInspector:actionToggleVisible()
	local thisModEnviroment = getfenv(0)["g_simpleInspector"]
	thisModEnviroment.logger:print("toggle display", FS22Log.LOG_LEVEL.INFO, "user_info")

	thisModEnviroment.settings:setValue("isEnabledVisible", not thisModEnviroment.settings:getValue("isEnabledVisible"))
	thisModEnviroment.settings:saveSettings()
end


function SimpleInspector.addMenuOption(original, target, id, i18n_title, i18n_tooltip, options, callback)
	local menuOption = original:clone()

	menuOption.target = target
	menuOption.id     = id

	menuOption:setCallback("onClickCallback", callback)
	menuOption:setDisabled(false)

	local settingTitle = menuOption.elements[4]
	local toolTip      = menuOption.elements[6]

	menuOption:setTexts({unpack(options)})
	settingTitle:setText(g_i18n:getText(i18n_title))
	toolTip:setText(g_i18n:getText(i18n_tooltip))

	return menuOption
end

function SimpleInspector.initGui(self)

	local boolMenuOptions = {
		"Visible", "WhenHUDHidden", "AlphaSort", "ShowAll", "ShowUnowned", "ShowPlayer", "ShowBeacon", "ShowFuel", "ShowDef", "ShowSpeed", "ShowDamage",
		"ShowFills", "ShowFillPercent", "ShowField", "ShowFieldNum", "PadFieldNum",
		"ShowCPWaypoints", "ShowADTime", "ShowCPTime","TextBold"
	}
	local unitOptions = {
		"SolidUnit", "LiquidUnit"
	}

	if not g_simpleInspector.createdGUI then
		-- Create controls -- Skip if we've already done this once
		g_simpleInspector.createdGUI = true

		local title = TextElement.new()
		title:applyProfile("settingsMenuSubtitle", true)
		title:setText(g_i18n:getText("title_simpleInspector"))
		self.boxLayout:addElement(title)

		self.menuOption_DisplayMode = SimpleInspector.addMenuOption(
			self.checkInvertYLook,
			g_simpleInspector,
			"simpleInspector_DisplayMode",
			"setting_simpleInspector_DisplayMode",
			"toolTip_simpleInspector_DisplayMode",
			{
				g_i18n:getText("setting_simpleInspector_DisplayMode1"),
				g_i18n:getText("setting_simpleInspector_DisplayMode2"),
				g_i18n:getText("setting_simpleInspector_DisplayMode3"),
				g_i18n:getText("setting_simpleInspector_DisplayMode4")
			},
			"onMenuOptionChanged_DisplayMode"
		)
		self.boxLayout:addElement(self.menuOption_DisplayMode)

		for _, thisOptionName in ipairs(unitOptions) do
			-- Boolean style options
			local thisFullOptName = "menuOption_" .. thisOptionName
			local unitType        = g_simpleInspector.convert.unit_types.SOLID

			if thisOptionName == "LiquidUnit" then
				unitType = g_simpleInspector.convert.unit_types.LIQUID
			end
			
			local theseOptions    = g_simpleInspector.convert:getSettingsTexts(unitType)

			self[thisFullOptName] = SimpleInspector.addMenuOption(
				self.checkInvertYLook,
				g_simpleInspector,
				"simpleInspector_" .. thisOptionName,
				"setting_simpleInspector_" .. thisOptionName,
				"toolTip_simpleInspector_" .. thisOptionName,
				theseOptions,
				"onMenuOptionChanged_unitOpt"
			)
			self.boxLayout:addElement(self[thisFullOptName])
		end


		for _, thisOptionName in ipairs(boolMenuOptions) do
			-- Boolean style options
			local thisFullOptName = "menuOption_" .. thisOptionName
			self[thisFullOptName] = SimpleInspector.addMenuOption(
				self.checkInvertYLook,
				g_simpleInspector,
				"simpleInspector_" .. thisOptionName,
				"setting_simpleInspector_" .. thisOptionName,
				"toolTip_simpleInspector_" .. thisOptionName,
				{
					g_i18n:getText("ui_no"),
					g_i18n:getText("ui_yes")
				},
				"onMenuOptionChanged_boolOpt"
			)
			self.boxLayout:addElement(self[thisFullOptName])
		end

		local textSizeTexts = {}
		for _, size in ipairs(g_simpleInspector.menuTextSizes) do
			table.insert(textSizeTexts, tostring(size) .. " px")
		end

		self.menuOption_TextSize = SimpleInspector.addMenuOption(
			self.checkInvertYLook,
			g_simpleInspector,
			"simpleInspector_setValueTextSize",
			"setting_simpleInspector_TextSize",
			"toolTip_simpleInspector_TextSize",
			textSizeTexts,
			"onMenuOptionChanged_setValueTextSize"
		)
		self.boxLayout:addElement(self.menuOption_TextSize)
	end

	-- Set Current Values
	self.menuOption_DisplayMode:setState(g_simpleInspector.settings:getValue("displayMode"))
	self.menuOption_SolidUnit:setState(g_simpleInspector.settings:getValue("isEnabledSolidUnit"))
	self.menuOption_LiquidUnit:setState(g_simpleInspector.settings:getValue("isEnabledLiquidUnit"))

	for _, thisOption in ipairs(boolMenuOptions) do
		local thisMenuOption = "menuOption_" .. thisOption
		local thisRealOption = "isEnabled" .. thisOption
		self[thisMenuOption]:setIsChecked(g_simpleInspector.settings:getValue(thisRealOption))
	end

	local textSizeState = 3 -- backup value for it set odd in the xml.
	for idx, textSize in ipairs(g_simpleInspector.menuTextSizes) do
		if g_simpleInspector.settings:getValue("setValueTextSize") == textSize then
			textSizeState = idx
		end
	end
	self.menuOption_TextSize:setState(textSizeState)
end

function SimpleInspector:onMenuOptionChanged_setValueTextSize(state)
	self.settings:setValue("setValueTextSize", g_simpleInspector.menuTextSizes[state])
	self.inspectText.size = self.gameInfoDisplay:scalePixelToScreenHeight(self.settings:getValue("setValueTextSize"))
	self.settings:saveSettings()
end

function SimpleInspector:onMenuOptionChanged_DisplayMode(state)
	self.settings:setValue("displayMode", state)
	self.settings:saveSettings()
end

function SimpleInspector:onMenuOptionChanged_boolOpt(state, info)
	self.settings:setValue(
		"isEnabled" .. string.sub(info.id, (#"simpleInspector_"+1)),
		state == CheckedOptionElement.STATE_CHECKED
	)
	self.settings:saveSettings()
end

function SimpleInspector:onMenuOptionChanged_unitOpt(state, info)
	self.settings:setValue(
		"isEnabled" .. string.sub(info.id, (#"simpleInspector_"+1)),
		state
	)
	self.settings:saveSettings()
end