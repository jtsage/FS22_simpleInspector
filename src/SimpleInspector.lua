--
-- Mod: FS22_SimpleInspector
--
-- Author: JTSage
-- source: https://github.com/jtsage/FS22_Simple_Inspector
-- credits: HappyLooser/VehicleInspector for the isOnField logic, and some pointers on where to find info

--[[
CHANGELOG
	v1.0.0.0
		- First version.  not compatible with EnhancedVehicle new damage/paint/fuel display (set to mode 1!)
]]--
SimpleInspector= {}

local SimpleInspector_mt = Class(SimpleInspector)


-- default options
SimpleInspector.displayMode     = 2 -- 1: top left, 2: top right (default), 3: bot left, 4: bot right, 5: custom
SimpleInspector.displayMode5X   = 0.2
SimpleInspector.displayMode5Y   = 0.2

SimpleInspector.debugMode       = false

SimpleInspector.isEnabledShowPlayer      = true
SimpleInspector.isEnabledShowAll         = false
SimpleInspector.isEnabledShowFillPercent = true
SimpleInspector.isEnabledShowFuel        = true
SimpleInspector.isEnabledShowSpeed       = true
SimpleInspector.isEnabledShowFills       = true
SimpleInspector.isEnabledShowField       = true
SimpleInspector.isEnabledShowFieldNum    = true
SimpleInspector.isEnabledPadFieldNum     = false
SimpleInspector.isEnabledShowDamage      = true
SimpleInspector.setValueDamageThreshold  = 0.2 -- a.k.a. 80% damaged
SimpleInspector.isEnabledShowCPWaypoints = true

SimpleInspector.setValueMaxDepth        = 5
SimpleInspector.setValueTimerFrequency  = 15
SimpleInspector.setValueTextMarginX     = 15
SimpleInspector.setValueTextMarginY     = 10
SimpleInspector.setValueTextSize        = 12
SimpleInspector.isEnabledTextBold       = false

SimpleInspector.colorNormal     = {1.000, 1.000, 1.000, 1}
SimpleInspector.colorFillType   = {0.700, 0.700, 0.700, 1}
SimpleInspector.colorUser       = {0.000, 0.777, 1.000, 1}
SimpleInspector.colorAI         = {0.956, 0.462, 0.644, 1}
SimpleInspector.colorRunning    = {0.871, 0.956, 0.423, 1}
SimpleInspector.colorAIMark     = {1.000, 0.082, 0.314, 1}
SimpleInspector.colorSep        = {1.000, 1.000, 1.000, 1}
SimpleInspector.colorSpeed      = {1.000, 0.400, 0.000, 1}
SimpleInspector.colorDiesel     = {0.434, 0.314, 0.000, 1}
SimpleInspector.colorMethane    = {1.000, 0.930, 0.000, 1}
SimpleInspector.colorElectric   = {0.031, 0.578, 0.314, 1}
SimpleInspector.colorField      = {0.423, 0.956, 0.624, 1}
SimpleInspector.colorDamaged    = {0.830, 0.019, 0.033, 1}

SimpleInspector.setStringTextHelper      = "_AI_ "
SimpleInspector.setStringTextADHelper    = "_AD_ "
SimpleInspector.setStringTextCPHelper    = "_CP_ "
SimpleInspector.setStringTextCPWaypoint  = "_CP:"
SimpleInspector.setStringTextDiesel      = "D:"
SimpleInspector.setStringTextMethane     = "M:"
SimpleInspector.setStringTextElectric    = "E:"
SimpleInspector.setStringTextField       = "F-"
SimpleInspector.setStringTextFieldNoNum  = "-F-"
SimpleInspector.setStringTextDamaged     = "-!!- "
SimpleInspector.setStringTextSep         = " | "

function SimpleInspector:new(mission, i18n, modDirectory, modName)
	local self = setmetatable({}, SimpleInspector_mt)

	self.myName            = "SimpleInspector"
	self.isServer          = mission:getIsServer()
	self.isClient          = mission:getIsClient()
	self.isMPGame          = g_currentMission.missionDynamicInfo.isMultiplayer
	self.mission           = mission
	self.i18n              = i18n
	self.modDirectory      = modDirectory
	self.modName           = modName
	self.gameInfoDisplay   = mission.hud.gameInfoDisplay
	self.inputHelpDisplay  = mission.hud.inputHelp
	self.speedMeterDisplay = mission.hud.speedMeter
	self.ingameMap         = mission.hud.ingameMap

	self.debugTimerRuns = 0
	self.inspectText    = {}
	self.boxBGColor     = { 544, 20, 200, 44 }
	self.bgName         = 'dataS/menu/blank.png'

	local modDesc       = loadXMLFile("modDesc", modDirectory .. "modDesc.xml");
	self.version        = getXMLString(modDesc, "modDesc.version");
	delete(modDesc)

	self.display_data = { }

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
	self.fill_invert_some = {
		tippingaugerwagon = true,
		augerwagon        = true,
	}
	self.fill_invert_types = {
		FillType.SEEDS,
		FillType.ROADSALT,
		FillType.FERTILIZER,
		FillType.LIME,
	}
	self.fill_color_CB = {
		{ 1.00, 0.76, 0.04, 1 },
		{ 0.98, 0.75, 0.15, 1 },
		{ 0.96, 0.73, 0.20, 1 },
		{ 0.94, 0.72, 0.25, 1 },
		{ 0.92, 0.71, 0.29, 1 },
		{ 0.90, 0.69, 0.33, 1 },
		{ 0.87, 0.68, 0.37, 1 },
		{ 0.85, 0.67, 0.40, 1 },
		{ 0.83, 0.66, 0.43, 1 },
		{ 0.81, 0.65, 0.46, 1 },
		{ 0.78, 0.64, 0.49, 1 },
		{ 0.76, 0.62, 0.52, 1 },
		{ 0.73, 0.61, 0.55, 1 },
		{ 0.70, 0.60, 0.57, 1 },
		{ 0.67, 0.59, 0.60, 1 },
		{ 0.64, 0.58, 0.63, 1 },
		{ 0.61, 0.56, 0.65, 1 },
		{ 0.57, 0.55, 0.68, 1 },
		{ 0.53, 0.54, 0.71, 1 },
		{ 0.49, 0.53, 0.73, 1 },
		{ 0.45, 0.52, 0.76, 1 },
		{ 0.39, 0.51, 0.78, 1 },
		{ 0.33, 0.50, 0.81, 1 },
		{ 0.24, 0.49, 0.84, 1 },
		{ 0.05, 0.48, 0.86, 1 }
	}
	self.fill_color = {
		{ 1.00, 0.00, 0.00, 1 },
		{ 1.00, 0.15, 0.00, 1 },
		{ 1.00, 0.22, 0.00, 1 },
		{ 0.99, 0.29, 0.00, 1 },
		{ 0.98, 0.34, 0.00, 1 },
		{ 0.98, 0.38, 0.00, 1 },
		{ 0.96, 0.43, 0.00, 1 },
		{ 0.95, 0.47, 0.00, 1 },
		{ 0.93, 0.51, 0.00, 1 },
		{ 0.91, 0.55, 0.00, 1 },
		{ 0.89, 0.58, 0.00, 1 },
		{ 0.87, 0.62, 0.00, 1 },
		{ 0.84, 0.65, 0.00, 1 },
		{ 0.81, 0.69, 0.00, 1 },
		{ 0.78, 0.72, 0.00, 1 },
		{ 0.75, 0.75, 0.00, 1 },
		{ 0.71, 0.78, 0.00, 1 },
		{ 0.67, 0.81, 0.00, 1 },
		{ 0.63, 0.84, 0.00, 1 },
		{ 0.58, 0.87, 0.00, 1 },
		{ 0.53, 0.89, 0.00, 1 },
		{ 0.46, 0.92, 0.00, 1 },
		{ 0.38, 0.95, 0.00, 1 },
		{ 0.27, 0.98, 0.00, 1 },
		{ 0.00, 1.00, 0.00, 1 }
	}

	self.settingsNames = {
		{"displayMode", "int" },
		{"displayMode5X", "float"},
		{"displayMode5Y", "float"},
		{"debugMode", "bool"},
		{"isEnabledShowPlayer", "bool"},
		{"isEnabledShowAll", "bool"},
		{"isEnabledShowFillPercent", "bool"},
		{"isEnabledShowFuel", "bool"},
		{"isEnabledShowSpeed", "bool"},
		{"isEnabledShowFills", "bool"},
		{"isEnabledShowField", "bool"},
		{"isEnabledShowFieldNum", "bool"},
		{"isEnabledPadFieldNum", "bool"},
		{"isEnabledShowDamage", "bool"},
		{"setValueDamageThreshold", "float"},
		{"isEnabledShowCPWaypoints", "bool"},
		{"setValueMaxDepth", "int" },
		{"setValueTimerFrequency", "int" },
		{"setValueTextMarginX", "int" },
		{"setValueTextMarginY", "int" },
		{"setValueTextSize", "int" },
		{"isEnabledTextBold", "bool" },
		{"colorNormal", "color"},
		{"colorFillType", "color"},
		{"colorUser", "color"},
		{"colorAI", "color"},
		{"colorRunning", "color"},
		{"colorAIMark", "color"},
		{"colorSep", "color"},
		{"colorSpeed", "color"},
		{"colorDiesel", "color"},
		{"colorMethane", "color"},
		{"colorElectric", "color"},
		{"colorField", "color"},
		{"colorDamaged", "color"},
		{"setStringTextHelper", "string"},
		{"setStringTextADHelper", "string"},
		{"setStringTextCPHelper", "string"},
		{"setStringTextCPWaypoint", "string"},
		{"setStringTextDiesel", "string"},
		{"setStringTextMethane", "string"},
		{"setStringTextElectric", "string"},
		{"setStringTextField", "string"},
		{"setStringTextFieldNoNum", "string"},
		{"setStringTextDamaged", "string"},
		{"setStringTextSep", "string"}
	}

	return self
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

	return vehicle.isBroken or damageLevel < SimpleInspector.setValueDamageThreshold
end

function SimpleInspector:makeFillColor(percentage, flip)
	local colorIndex = math.floor(percentage/4) + 1
	local colorTab = nil

	if percentage == 100 then colorIndex = 25 end

	if not flip then colorIndex = 26 - colorIndex end

	if g_gameSettings:getValue('useColorblindMode') then
		colorTab = self.fill_color_CB[colorIndex]
	else
		colorTab = self.fill_color[colorIndex]
	end

	if colorTab ~= nil then
		return colorTab
	else
		return {1,1,1,1}
	end
end

function SimpleInspector:getIsTypeInverted(fillTypeID)
	for i = 1, #self.fill_invert_types do
		if self.fill_invert_types[i] == fillTypeID then return true end
	end
	return false
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
		if ( not g_simpleInspector.isEnabledShowFieldNum ) then
			-- short cut field number detection if we won't display it anyways.
			return { isField, 0 }
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
	return { isField, fieldNumber }
end

function SimpleInspector:getFuel(vehicle)
	local fuelTypeList = {
		{
			FillType.DIESEL,
			"colorDiesel",
			g_simpleInspector.setStringTextDiesel
		}, {
			FillType.ELECTRICCHARGE,
			"colorElectric",
			g_simpleInspector.setStringTextElectric
		}, {
			FillType.METHANE,
			"colorMethane",
			g_simpleInspector.setStringTextMethane
		}
	}
	for _, fuelType in pairs(fuelTypeList) do
		local fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType[1])
		if ( fillUnitIndex ~= nil ) then
			local fuelLevel = vehicle:getFillUnitFillLevel(fillUnitIndex)
			local capacity  = vehicle:getFillUnitCapacity(fillUnitIndex)
			local percentage = math.floor((fuelLevel / capacity) * 100)
			return { fuelType[2], fuelType[3], percentage }
		end
	end
	return { false } -- unknown fuel type, should not be possible.
end

function SimpleInspector:getSpeed(vehicle)
	-- Get the current speed of the vehicle
	local speed = Utils.getNoNil(vehicle.lastSpeed, 0) * 3600
	if g_gameSettings:getValue('useMiles') then
		speed = speed * 0.621371
	end
	return string.format("%1.0f", "".. Utils.getNoNil(speed, 0))
end

function SimpleInspector:getSingleFill(vehicle, theseFills)
	-- This is the single run at the fill type, for the current vehicle only.
	-- Borrowed heavily from older versions of similar plugins, ignores unknown fill types

	local spec_fillUnit = vehicle.spec_fillUnit

	if spec_fillUnit ~= nil and spec_fillUnit.fillUnits ~= nil then
		local vehicleTypeName = Utils.getNoNil(vehicle.typeName, "unknown"):lower()
		local isInverted      = self.fill_invert_all[vehicleTypeName] ~= nil
		local checkInvert     = self.fill_invert_some[vehicleTypeName] ~= nil

		for i = 1, #spec_fillUnit.fillUnits do
			local fillUnit = spec_fillUnit.fillUnits[i]
			if fillUnit.capacity > 0 and fillUnit.showOnHud then
				local fillType = fillUnit.fillType;
				if fillType == FillType.UNKNOWN and table.size(fillUnit.supportedFillTypes) == 1 then
					fillType = next(fillUnit.supportedFillTypes)
				end
				if fillUnit.fillTypeToDisplay ~= FillType.UNKNOWN then
					fillType = fillUnit.fillTypeToDisplay
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

				local maxReached = not fillUnit.ignoreFillLimit and g_currentMission.missionInfo.trailerFillLimit and vehicle.getMaxComponentMassReached ~= nil and vehicle:getMaxComponentMassReached();

				if maxReached then
					capacity = fillLevel
				end

				if fillLevel > 0 then
					if checkInvert then isInverted =  self:getIsTypeInverted(fillType) end

					if ( theseFills[fillType] ~= nil ) then
						theseFills[fillType][1] = theseFills[fillType][1] + fillLevel
						theseFills[fillType][2] = theseFills[fillType][2] + capacity
					else
						theseFills[fillType] = { fillLevel, capacity, isInverted }
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

	if vehicle.getAttachedImplements ~= nil and depth < g_simpleInspector.setValueMaxDepth then
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
	if g_currentMission ~= nil and g_currentMission.vehicles ~= nil then
		for v=1, #g_currentMission.vehicles do
			local thisVeh = g_currentMission.vehicles[v]
			if thisVeh ~= nil and thisVeh.getIsControlled ~= nil then
				local typeName = Utils.getNoNil(thisVeh.typeName, "unknown")
				local isTrain = typeName == "locomotive"
				local isBelt = typeName == "conveyorBelt" or typeName == "pickupConveyorBelt"
				local isRidable = SpecializationUtil.hasSpecialization(Rideable, thisVeh.specializations)
				if ( not isTrain and not isRidable and not isBelt) then
					local plyrName = nil
					local isRunning = thisVeh.getIsMotorStarted ~= nil and thisVeh:getIsMotorStarted()
					local isOnAI    = thisVeh.getIsAIActive ~= nil and thisVeh:getIsAIActive()
					local isConned  = thisVeh.getIsControlled ~= nil and thisVeh:getIsControlled()

					if ( g_simpleInspector.isEnabledShowAll or isConned or isRunning or isOnAI) then
						local thisName  = thisVeh:getName()
						local thisBrand = g_brandManager:getBrandByIndex(thisVeh:getBrand())
						local speed     = self:getSpeed(thisVeh)
						local fills     = {}
						local status    = 0
						local isAI      = {false, false}
						local fuelLevel = self:getFuel(thisVeh)
						local isOnField = {false, false}
						local isBroken  = false

						if self.isMPGame and g_simpleInspector.isEnabledShowPlayer and isConned and thisVeh.getControllerName ~= nil then
							plyrName = thisVeh:getControllerName()
						end

						if g_simpleInspector.isEnabledShowField then
							-- This may be compute heavy, only do it when wanted.
							isOnField = self:getIsOnField(thisVeh)
						end

						if g_simpleInspector.isEnabledShowDamage then
							-- If we don't care to see damage, don't look it up
							isBroken = self:getAllDamage(thisVeh)
						end

						if g_simpleInspector.isEnabledShowAll and isRunning then
							-- If we show all, use "colorRunning", otherwise just the normal one
							-- AI and user control take precedence, in that order
							status = 3
						end
						if isOnAI then
							-- second highest precendence
							status = 1

							-- default text, override for AD & CP below.
							isAI = {true, g_simpleInspector.setStringTextHelper}

							-- is AD driving
							if thisVeh.ad ~= nil and thisVeh.ad.stateModule ~= nil and thisVeh.ad.stateModule:isActive() then
								isAI[2] = g_simpleInspector.setStringTextADHelper
							end

							-- is CP driving, and should we show waypoints?
							if thisVeh.getCpStatus ~= nil then
								local cpStatus = thisVeh:getCpStatus()
								if cpStatus:getIsActive() then
									isAI[2] = g_simpleInspector.setStringTextCPHelper
									if ( g_simpleInspector.isEnabledShowCPWaypoints ) then
										isAI[2] = g_simpleInspector.setStringTextCPWaypoint .. cpStatus:getWaypointText() .. "_ "
									end
								end
							end
						end
						if isConned then
							-- highest precendence
							status = 2
						end

						self:getAllFills(thisVeh, fills, 0)
						table.insert(new_data_table, {
							status,
							isAI,
							thisBrand.title .. " " .. thisName,
							tostring(speed),
							fuelLevel,
							fills,
							isOnField,
							isBroken,
							plyrName
						})
					end
				end
			end
		end
	end

	self.display_data = {unpack(new_data_table)}
end

function SimpleInspector:draw()
	if not self.isClient then
		return
	end

	if self.inspectBox ~= nil then
		local info_text = self.display_data
		local overlayH, dispTextH, dispTextW = 0, 0, 0

		if #info_text == 0 then
			-- we have no entries, hide the overlay and leave
			self.inspectBox:setVisible(false)
			return
		elseif g_gameSettings:getValue("ingameMapState") == 4 and g_simpleInspector.displayMode % 2 ~= 0 and g_currentMission.inGameMenu.hud.inputHelp.overlay.visible then
			-- Left side display hide on big map with help open
			self.inspectBox:setVisible(false)
			return
		else
			-- we have entries, lets get the overall height of the box and unhide
			self.inspectBox:setVisible(true)
			dispTextH = self.inspectText.size * #info_text
			overlayH = dispTextH + ( 2 * self.inspectText.marginHeight)
		end

		setTextBold(g_simpleInspector.isEnabledTextBold)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)

		-- overlayX/Y is where the box starts
		local overlayX, overlayY = self:findOrigin()
		-- dispTextX/Y is where the text starts (sort of)
		local dispTextX, dispTextY = self:findOrigin()

		if ( g_simpleInspector.displayMode == 2 ) then
			-- top right (subtract both margins)
			dispTextX = dispTextX - self.marginWidth
			dispTextY = dispTextY - self.marginHeight
			overlayY  = overlayY - overlayH
		elseif ( g_simpleInspector.displayMode == 3 ) then
			-- bottom left (add x width, add Y height)
			dispTextX = dispTextX + self.marginWidth
			dispTextY = dispTextY - self.marginHeight + overlayH
		elseif ( g_simpleInspector.displayMode == 4 ) then
			-- bottom right (subtract x width, add Y height)
			dispTextX = dispTextX - self.marginWidth
			dispTextY = dispTextY - self.marginHeight + overlayH
		else
			-- top left (add X width, subtract Y height)
			dispTextX = dispTextX + self.marginWidth
			dispTextY = dispTextY - self.marginHeight
			overlayY  = overlayY - overlayH
		end

		if ( g_simpleInspector.displayMode % 2 == 0 ) then
			setTextAlignment(RenderText.ALIGN_RIGHT)
		else
			setTextAlignment(RenderText.ALIGN_LEFT)
		end

		if g_currentMission.hud.sideNotifications ~= nil and g_simpleInspector.displayMode == 2 then
			if #g_currentMission.hud.sideNotifications.notificationQueue > 0 then
				local deltaY = g_currentMission.hud.sideNotifications:getHeight()
				dispTextY = dispTextY - deltaY
				overlayY  = overlayY - deltaY
			end
		end

		self.inspectText.posX = dispTextX
		self.inspectText.posY = dispTextY

		for _, txt in pairs(info_text) do

			local thisTextLine  = {}
			local fullTextSoFar = ""

			if g_simpleInspector.isEnabledShowSpeed then
				-- Vehicle speed
				if g_gameSettings:getValue('useMiles') then
					table.insert(thisTextLine, {"colorSpeed", txt[4] .. " mph", false})
				else
					table.insert(thisTextLine, {"colorSpeed", txt[4] .. " kph", false})
				end

				-- Seperator after speed
				table.insert(thisTextLine, {false, false, false})
			end

			if g_simpleInspector.isEnabledShowFuel and txt[5][1] ~= false then
				-- Vehicle fuel color[1], text[2], percentage[3]
				table.insert(thisTextLine, { txt[5][1], txt[5][2], false})
				table.insert(thisTextLine, { "colorFillType", tostring(txt[5][3]) .. "%", false})

				-- Seperator after speed
				table.insert(thisTextLine, {false, false, false})
			end

			-- Damage marker Tag, if needed
			if g_simpleInspector.isEnabledShowDamage and txt[8] then
				table.insert(thisTextLine, {"colorDamaged", g_simpleInspector.setStringTextDamaged, false})
			end

			-- Field Mark, if needed / wanted
			if g_simpleInspector.isEnabledShowField and txt[7][1] == true then
				if txt[7][2] == 0 then
					table.insert(thisTextLine, {"colorField", g_simpleInspector.setStringTextFieldNoNum .. " ", false})
				else
					if g_simpleInspector.isEnabledPadFieldNum and txt[7][2] < 10 then
						table.insert(thisTextLine, {"colorField", g_simpleInspector.setStringTextField .. "0" .. txt[7][2] .. " ", false})
					else
						table.insert(thisTextLine, {"colorField", g_simpleInspector.setStringTextField .. txt[7][2] .. " ", false})
					end
				end
			end

			-- AI Tag, if needed
			if txt[2][1] then
				table.insert(thisTextLine, {"colorAIMark", txt[2][2], false})
			end

			-- User name
			if txt[9] ~= nil then
				table.insert(thisTextLine, {"colorUser", "[" .. txt[9] .. "] ", false})
			end

			-- Vehicle name
			if txt[1] == 0 then
				table.insert(thisTextLine, {"colorNormal", txt[3], false})
			elseif txt[1] == 1 then
				table.insert(thisTextLine, {"colorAI", txt[3], false})
			elseif txt[1] == 3 then
				table.insert(thisTextLine, {"colorRunning", txt[3], false})
			else
				table.insert(thisTextLine, {"colorUser", txt[3], false})
			end

			if g_simpleInspector.isEnabledShowFills then
				for idx, thisFill in pairs(txt[6]) do
					-- Seperator between fill types / vehicle
					table.insert(thisTextLine, {false, false, false})

					local thisFillType = g_fillTypeManager:getFillTypeByIndex(idx)
					local dispPerc     = math.ceil((thisFill[1] / thisFill[2]) * 100 )
					local fillColor    = self:makeFillColor(dispPerc, thisFill[3])

					table.insert(thisTextLine, {"colorFillType", thisFillType.title .. ":", false})

					table.insert(thisTextLine, {"rawFillColor", tostring(thisFill[1]), fillColor})
					if g_simpleInspector.isEnabledShowFillPercent then
						table.insert(thisTextLine, {"rawFillColor", " (" .. tostring(dispPerc) ..  "%)", fillColor})
					end
				end
			end

			if ( g_simpleInspector.displayMode % 2 ~= 0 ) then
				for _, thisLine in ipairs(thisTextLine) do
					if thisLine[1] == false then
						fullTextSoFar = self:renderSep(dispTextX, dispTextY, fullTextSoFar)
					elseif thisLine[1] == "rawFillColor" then
						setTextColor(unpack(thisLine[3]))
						fullTextSoFar = self:renderText(dispTextX, dispTextY, fullTextSoFar, thisLine[2])
					else
						self:renderColor(thisLine[1])
						fullTextSoFar = self:renderText(dispTextX, dispTextY, fullTextSoFar, thisLine[2])
					end
				end
			else
				for i = #thisTextLine, 1, -1 do
					if thisTextLine[i][1] == false then
						fullTextSoFar = self:renderSep(dispTextX, dispTextY, fullTextSoFar)
					elseif thisTextLine[i][1] == "rawFillColor" then
						setTextColor(unpack(thisTextLine[i][3]))
						fullTextSoFar = self:renderText(dispTextX, dispTextY, fullTextSoFar, thisTextLine[i][2])
					else
						self:renderColor(thisTextLine[i][1])
						fullTextSoFar = self:renderText(dispTextX, dispTextY, fullTextSoFar, thisTextLine[i][2])
					end
				end
			end

			dispTextY = dispTextY - self.inspectText.size

			local tmpW = getTextWidth(self.inspectText.size, fullTextSoFar)

			if tmpW > dispTextW then dispTextW = tmpW end
		end

		-- update overlay background
		if g_simpleInspector.displayMode % 2 == 0 then
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

	if g_updateLoopIndex % g_simpleInspector.setValueTimerFrequency == 0 then
		-- Lets not be rediculous, only update the vehicles "infrequently"
		self:updateVehicles()
	end
end

function SimpleInspector:renderColor(name)
	-- fall back to white if it's not known
	local colorString = Utils.getNoNil(g_simpleInspector[name], {1,1,1,1})

	setTextColor(unpack(colorString))
end

function SimpleInspector:renderText(x, y, fullTextSoFar, text)
	local newX = x

	if g_simpleInspector.displayMode % 2 == 0 then
		newX = newX - getTextWidth(self.inspectText.size, fullTextSoFar)
	else
		newX = newX + getTextWidth(self.inspectText.size, fullTextSoFar)
	end

	renderText(newX, y, self.inspectText.size, text)
	return text .. fullTextSoFar
end

function SimpleInspector:renderSep(x, y, fullTextSoFar)
	self:renderColor("colorSep")
	return self:renderText(x, y, fullTextSoFar, g_simpleInspector.setStringTextSep)
end

function SimpleInspector:onStartMission(mission)
	-- Load the mod, make the box that info lives in.
	print("~~" .. self.myName .." :: version " .. self.version .. " loaded.")
	if not self.isClient then
		return
	end

	self:loadSettings()
	self:saveSettings()
	-- if fileExists(self.confFile) then
	-- 	self:readSettingsFile()
	-- else
	-- 	self:createSettingsFile()
	-- end

	if ( g_simpleInspector.debugMode ) then
		print("~~" .. self.myName .." :: onStartMission")
	end

	self:createTextBox()
end

function SimpleInspector:findOrigin()
	local tmpX = 0
	local tmpY = 0

	if ( g_simpleInspector.displayMode == 2 ) then
		-- top right display
		tmpX, tmpY = self.gameInfoDisplay:getPosition()
		tmpX = 1
		tmpY = tmpY - 0.012
	elseif ( g_simpleInspector.displayMode == 3 ) then
		-- Bottom left, correct origin.
		tmpX = 0.01622
		tmpY = 0 + self.ingameMap:getHeight() + 0.01622
		if g_gameSettings:getValue("ingameMapState") > 1 then
			tmpY = tmpY + 0.032
		end
	elseif ( g_simpleInspector.displayMode == 4 ) then
		-- bottom right display
		tmpX = 1
		tmpY = 0.01622
		if g_currentMission.inGameMenu.hud.speedMeter.overlay.visible then
			tmpY = tmpY + self.speedMeterDisplay:getHeight() + 0.032
			if g_modIsLoaded["FS22_EnhancedVehicle"] then
				tmpY = tmpY + 0.03
			end
		end
	elseif ( g_simpleInspector.displayMode == 5 ) then
		tmpX = g_simpleInspector.displayMode5X
		tmpY = g_simpleInspector.displayMode5Y
	else
		-- top left display
		tmpX = 0.014
		tmpY = 0.945
		if g_currentMission.inGameMenu.hud.inputHelp.overlay.visible then
			tmpY = tmpY - self.inputHelpDisplay:getHeight() - 0.012
		end
	end

	return tmpX, tmpY
end

function SimpleInspector:createTextBox()
	-- make the box we live in.
	if ( g_simpleInspector.debugMode ) then
		print("~~" .. self.myName .." :: createTextBox")
	end

	local baseX, baseY = self:findOrigin()

	local boxOverlay = nil

	self.marginWidth, self.marginHeight = self.gameInfoDisplay:scalePixelToScreenVector({ 8, 8 })

	if ( g_simpleInspector.displayMode % 2 == 0 ) then -- top right
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

	self.inspectText.marginWidth, self.inspectText.marginHeight = self.gameInfoDisplay:scalePixelToScreenVector({g_simpleInspector.setValueTextMarginX, g_simpleInspector.setValueTextMarginY})
	self.inspectText.size = self.gameInfoDisplay:scalePixelToScreenHeight(g_simpleInspector.setValueTextSize)
end

function SimpleInspector:delete()
	-- clean up on remove
	if self.inspectBox ~= nil then
		self.inspectBox:delete()
	end
end

function SimpleInspector:saveSettings()
	local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory
	if savegameFolderPath == nil then
		savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex)
	end
	local key = "simpleInspector"
	local xmlFile = createXMLFile(key, savegameFolderPath .. "/simpleInspector.xml", key)

	for _, setting in pairs(g_simpleInspector.settingsNames) do
		if ( setting[2] == "bool" ) then
			setXMLBool(xmlFile, key .. "." .. setting[1] .. "#value", g_simpleInspector[setting[1]])
		elseif ( setting[2] == "string" ) then
			setXMLString(xmlFile, key .. "." .. setting[1] .. "#value", g_simpleInspector[setting[1]])
		elseif ( setting[2] == "int" ) then
			setXMLInt(xmlFile, key .. "." .. setting[1] .. "#value", g_simpleInspector[setting[1]])
		elseif ( setting[2] == "float" ) then
			setXMLFloat(xmlFile, key .. "." .. setting[1] .. "#value", g_simpleInspector[setting[1]])
		elseif ( setting[2] == "color" ) then
			local r, g, b, a = unpack(g_simpleInspector[setting[1]])
			setXMLFloat(xmlFile, key .. "." .. setting[1] .. "#r", r)
			setXMLFloat(xmlFile, key .. "." .. setting[1] .. "#g", g)
			setXMLFloat(xmlFile, key .. "." .. setting[1] .. "#b", b)
			setXMLFloat(xmlFile, key .. "." .. setting[1] .. "#a", a)
		end
	end

	saveXMLFile(xmlFile)
	print("~~" .. g_simpleInspector.myName .." :: saved config file")
end

function SimpleInspector:loadSettings()
	local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory
	if savegameFolderPath == nil then
		savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex)
	end
	local key = "simpleInspector"

	if fileExists(savegameFolderPath .. "/simpleInspector.xml") then
		print("~~" .. self.myName .." :: loading config file")
		local xmlFile = loadXMLFile(key, savegameFolderPath .. "/simpleInspector.xml")

		for _, setting in pairs(self.settingsNames) do
			if ( setting[2] == "bool" ) then
				g_simpleInspector[setting[1]] = Utils.getNoNil(getXMLBool(xmlFile, key .. "." .. setting[1] .. "#value"), g_simpleInspector[setting[1]])
			elseif ( setting[2] == "string" ) then
				g_simpleInspector[setting[1]] = Utils.getNoNil(getXMLString(xmlFile, key .. "." .. setting[1] .. "#value"), g_simpleInspector[setting[1]])
			elseif ( setting[2] == "int" ) then
				g_simpleInspector[setting[1]] = Utils.getNoNil(getXMLInt(xmlFile, key .. "." .. setting[1] .. "#value"), g_simpleInspector[setting[1]])
			elseif ( setting[2] == "float" ) then
				g_simpleInspector[setting[1]] = Utils.getNoNil(getXMLFloat(xmlFile, key .. "." .. setting[1] .. "#value"), g_simpleInspector[setting[1]])
			elseif ( setting[2] == "color" ) then
				local r, g, b, a = unpack(g_simpleInspector[setting[1]])
				r = Utils.getNoNil(getXMLFloat(xmlFile, key .. "." .. setting[1] .. "#r"), r)
				g = Utils.getNoNil(getXMLFloat(xmlFile, key .. "." .. setting[1] .. "#g"), g)
				b = Utils.getNoNil(getXMLFloat(xmlFile, key .. "." .. setting[1] .. "#b"), b)
				a = Utils.getNoNil(getXMLFloat(xmlFile, key .. "." .. setting[1] .. "#a"), a)
				g_simpleInspector[setting[1]] = {r, g, b, a}
			end
		end

		delete(xmlFile)
	end
end

function SimpleInspector:registerActionEvents()
	local _, reloadConfig = g_inputBinding:registerActionEvent('SimpleInspector_reload_config', self,
		SimpleInspector.actionReloadConfig, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(reloadConfig, false)
end

function SimpleInspector:actionReloadConfig()
	local thisModEnviroment = getfenv(0)["g_simpleInspector"]
	if ( thisModEnviroment.debugMode ) then
		print("~~" .. thisModEnviroment.myName .." :: reload settings from disk")
	end
	thisModEnviroment:loadSettings()
end

function SimpleInspector.initGui(self)
	local boolMenuOptions = {
		"ShowAll", "ShowPlayer", "ShowFillPercent", "ShowFuel", "ShowSpeed",
		"ShowFills", "ShowField", "ShowFieldNum", "PadFieldNum", "ShowDamage",
		"ShowCPWaypoints", "TextBold"
	}

	if not g_simpleInspector.createdGUI then -- Skip if we've already done this once
		self.menuOption_DisplayMode = self.checkAutoMotorStart:clone()
		self.menuOption_DisplayMode.target = g_simpleInspector
		self.menuOption_DisplayMode.id = "simpleInspector_DisplayMode"
		self.menuOption_DisplayMode:setCallback("onClickCallback", "onMenuOptionChanged_DisplayMode")

		local settingTitle = self.menuOption_DisplayMode.elements[4]
		local toolTip = self.menuOption_DisplayMode.elements[6]

		self.menuOption_DisplayMode:setTexts({
			g_i18n:getText("setting_simpleInspector_DisplayMode1"),
			g_i18n:getText("setting_simpleInspector_DisplayMode2"),
			g_i18n:getText("setting_simpleInspector_DisplayMode3"),
			g_i18n:getText("setting_simpleInspector_DisplayMode4")
		})

		settingTitle:setText(g_i18n:getText("setting_simpleInspector_DisplayMode"))
		toolTip:setText(g_i18n:getText("toolTip_simpleInspector_DisplayMode"))


		for _, optName in pairs(boolMenuOptions) do
			local fullName = "menuOption_" .. optName

			self[fullName]           = self.checkAutoMotorStart:clone()
			self[fullName]["target"] = g_simpleInspector
			self[fullName]["id"]     = "simpleInspector_" .. optName
			self[fullName]:setCallback("onClickCallback", "onMenuOptionChanged_boolOpt")

			local settingTitle = self[fullName]["elements"][4]
			local toolTip      = self[fullName]["elements"][6]

			self[fullName]:setTexts({g_i18n:getText("ui_no"), g_i18n:getText("ui_yes")})

			settingTitle:setText(g_i18n:getText("setting_simpleInspector_" .. optName))
			toolTip:setText(g_i18n:getText("toolTip_simpleInspector_" .. optName))
		end

		local title = TextElement.new()
		title:applyProfile("settingsMenuSubtitle", true)
		title:setText(g_i18n:getText("title_simpleInspector"))

		self.boxLayout:addElement(title)
		self.boxLayout:addElement(self.menuOption_DisplayMode)
		for _, value in ipairs(boolMenuOptions) do
			local thisOption = "menuOption_" .. value
			self.boxLayout:addElement(self[thisOption])
		end
	end

	self.menuOption_DisplayMode:setState(g_simpleInspector.displayMode)
	for _, value in ipairs(boolMenuOptions) do
		local thisMenuOption = "menuOption_" .. value
		local thisRealOption = "isEnabled" .. value
		self[thisMenuOption]:setIsChecked(g_simpleInspector[thisRealOption])
	end
end

function SimpleInspector:onMenuOptionChanged_DisplayMode(state)
	self.displayMode = state
	SimpleInspector:saveSettings()
end

function SimpleInspector:onMenuOptionChanged_boolOpt(state, info)
	local thisOption = "isEnabled" .. string.sub(info.id,17)
	self[thisOption] = state == CheckedOptionElement.STATE_CHECKED
	SimpleInspector:saveSettings()
end