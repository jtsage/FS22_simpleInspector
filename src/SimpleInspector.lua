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

function SimpleInspector:new(mission, i18n, modDirectory, modName)
	local self = {}

	setmetatable(self, SimpleInspector_mt)

	self.myName            = "SimpleInspector"
	self.isServer          = mission:getIsServer()
	self.isClient          = mission:getIsClient()
	self.mission           = mission
	self.i18n              = i18n
	self.modDirectory      = modDirectory
	self.modName           = modName
	--self.parentHUD         = mission.hud
	self.gameInfoDisplay   = mission.hud.gameInfoDisplay
	self.inputHelpDisplay  = mission.hud.inputHelp
	self.speedMeterDisplay = mission.hud.speedMeter
	self.ingameMap         = mission.hud.ingameMap

	self.settingsDirectory = getUserProfileAppPath() .. "modSettings/"
	self.confDirectory     = self.settingsDirectory .."FS22_SimpleInspector/"
	self.confFile          = self.confDirectory .. "FS22_SimpleInspectorSettings.xml"

	self.settings = {
		displayMode     = 2, -- 1: top left, 2: top right (default), 3: bot left, 4: bot right, 5: custom
		displayMode5X   = 0.2,
		displayMode5Y   = 0.2,
		debugMode       = false,

		showAll         = false,
		showFillPercent = true,
		showFuel        = true,
		showSpeed       = true,
		showFills       = true,
		showField       = true,
		showFieldNum    = true,
		padFieldNum     = false,
		showDamage      = true,
		damageThreshold = 0.2, -- a.k.a. 80% damaged
		showCPWaypoints = true,


		maxDepth        = 5,
		timerFrequency  = 15,
		textMarginX     = 15,
		textMarginY     = 10,
		textSize        = 12,
		textBold        = false,

		colorNormal     = "1.000, 1.000, 1.000, 1",
		colorFillType   = "0.700, 0.700, 0.700, 1",
		colorUser       = "0.000, 0.777, 1.000, 1",
		colorAI         = "0.956, 0.462, 0.644, 1",
		colorRunning    = "0.871, 0.956, 0.423, 1",
		colorAIMark     = "1.000, 0.082, 0.314, 1",
		colorSep        = "1.000, 1.000, 1.000, 1",
		colorSpeed      = "1.000, 0.400, 0.000, 1",
		colorDiesel     = "0.434, 0.314, 0.000, 1",
		colorMethane    = "1.000, 0.930, 0.000, 1",
		colorElectric   = "0.031, 0.578, 0.314, 1",
		colorField      = "0.423, 0.956, 0.624, 1",
		colorDamaged    = "0.830, 0.019, 0.033, 1",

		textHelper      = "_AI_ ",
		textADHelper    = "_AD_ ",
		textCPHelper    = "_CP_ ",
		textCPWaypoint  = "_CP: ",
		textDiesel      = "D:",
		textMethane     = "M:",
		textElectric    = "E:",
		textField       = "F-",
		textFieldNoNum  = "-F-",
		textDamaged     = "-!!- ",
		textSep         = " | "
	}

	self.debugTimerRuns = 0
	self.inspectText    = {}
	self.boxBGColor     = { 544, 20, 200, 44 }
	self.bgName         = 'dataS/menu/blank.png'

	local modDesc       = loadXMLFile("modDesc", modDirectory .. "modDesc.xml");
	self.version        = getXMLString(modDesc, "modDesc.version");

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

	return vehicle.isBroken or damageLevel < self.settings.damageThreshold
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
		if ( not self.settings.showFieldNum ) then
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
			self.settings.textDiesel
		}, {
			FillType.ELECTRICCHARGE,
			"colorElectric",
			self.settings.textElectric
		}, {
			FillType.METHANE,
			"colorMethane",
			self.settings.textMethane
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

	if vehicle.getAttachedImplements ~= nil and depth < self.settings.maxDepth then
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
					local isRunning = thisVeh.getIsMotorStarted ~= nil and thisVeh:getIsMotorStarted()
					local isOnAI    = thisVeh.getIsAIActive ~= nil and thisVeh:getIsAIActive()
					local isConned  = thisVeh.getIsControlled ~= nil and thisVeh:getIsControlled()

					if ( self.settings.showAll or isConned or isRunning or isOnAI) then
						local thisName  = thisVeh:getName()
						local thisBrand = g_brandManager:getBrandByIndex(thisVeh:getBrand())
						local speed     = self:getSpeed(thisVeh)
						local fills     = {}
						local status    = 0
						local isAI      = {false, false}
						local fuelLevel = self:getFuel(thisVeh)
						local isOnField = {false, false}
						local isBroken  = false

						if self.settings.showField then
							-- This may be compute heavy, only do it when wanted.
							isOnField = self:getIsOnField(thisVeh)
						end

						if self.settings.showDamage then
							-- If we don't care to see damage, don't look it up
							isBroken = self:getAllDamage(thisVeh)
						end

						if self.settings.showAll and isRunning then
							-- If we show all, use "colorRunning", otherwise just the normal one
							-- AI and user control take precedence, in that order
							status = 3
						end
						if isOnAI then
							-- second highest precendence
							status = 1

							-- default text, override for AD & CP below.
							isAI = {true, self.settings.textHelper}

							-- is AD driving
							if thisVeh.ad ~= nil and thisVeh.ad.stateModule ~= nil and thisVeh.ad.stateModule:isActive() then
								isAI[2] = self.settings.textADHelper
							end

							-- is CP driving, and should we show waypoints?
							if thisVeh.getCpStatus ~= nil then
								local cpStatus = thisVeh:getCpStatus()
								if cpStatus:getIsActive() then
									isAI[2] = self.settings.textCPHelper
									if ( self.settings.showCPWaypoints ) then
										isAI[2] = self.settings.textCPWaypoint .. cpStatus:getWaypointText() .. "_ "
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
							isBroken
						})
					end
				end
			end
		end
	end

	self.display_data = {unpack(new_data_table)}
end

function SimpleInspector:draw()
	if self.inspectBox ~= nil then
		local info_text = self.display_data
		local overlayH, dispTextH, dispTextW = 0, 0, 0

		if #info_text == 0 then
			-- we have no entries, hide the overlay and leave
			self.inspectBox:setVisible(false)
			return
		elseif g_gameSettings:getValue("ingameMapState") == 4 and self.settings.displayMode % 2 ~= 0 and g_currentMission.inGameMenu.hud.inputHelp.overlay.visible then
			-- Left side display hide on big map with help open
			self.inspectBox:setVisible(false)
			return
		else
			-- we have entries, lets get the overall height of the box and unhide
			self.inspectBox:setVisible(true)
			dispTextH = self.inspectText.size * #info_text
			overlayH = dispTextH + ( 2 * self.inspectText.marginHeight)
		end

		setTextBold(self.settings.textBold)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)

		-- overlayX/Y is where the box starts
		local overlayX, overlayY = self:findOrigin()
		-- dispTextX/Y is where the text starts (sort of)
		local dispTextX, dispTextY = self:findOrigin()

		if ( self.settings.displayMode == 2 ) then
			-- top right (subtract both margins)
			dispTextX = dispTextX - self.marginWidth
			dispTextY = dispTextY - self.marginHeight
			overlayY  = overlayY - overlayH
		elseif ( self.settings.displayMode == 3 ) then
			-- bottom left (add x width, add Y height)
			dispTextX = dispTextX + self.marginWidth
			dispTextY = dispTextY - self.marginHeight + overlayH
		elseif ( self.settings.displayMode == 4 ) then
			-- bottom right (subtract x width, add Y height)
			dispTextX = dispTextX - self.marginWidth
			dispTextY = dispTextY - self.marginHeight + overlayH
		else
			-- top left (add X width, subtract Y height)
			dispTextX = dispTextX + self.marginWidth
			dispTextY = dispTextY - self.marginHeight
			overlayY  = overlayY - overlayH
		end

		if ( self.settings.displayMode % 2 == 0 ) then
			setTextAlignment(RenderText.ALIGN_RIGHT)
		else
			setTextAlignment(RenderText.ALIGN_LEFT)
		end

		if g_currentMission.hud.sideNotifications ~= nil and self.settings.displayMode == 2 then
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

			if self.settings.showSpeed then
				-- Vehicle speed
				if g_gameSettings:getValue('useMiles') then
					table.insert(thisTextLine, {"colorSpeed", txt[4] .. " mph", false})
				else
					table.insert(thisTextLine, {"colorSpeed", txt[4] .. " kph", false})
				end

				-- Seperator after speed
				table.insert(thisTextLine, {false, false, false})
			end

			if self.settings.showFuel and txt[5][1] ~= false then
				-- Vehicle fuel color[1], text[2], percentage[3]
				table.insert(thisTextLine, { txt[5][1], txt[5][2], false})
				table.insert(thisTextLine, { "colorFillType", tostring(txt[5][3]) .. "%", false})

				-- Seperator after speed
				table.insert(thisTextLine, {false, false, false})
			end

			-- Damage marker Tag, if needed
			if self.settings.showDamage and txt[8] then
				table.insert(thisTextLine, {"colorDamaged", self.settings.textDamaged, false})
			end

			-- Field Mark, if needed / wanted
			if self.settings.showField and txt[7][1] == true then
				if txt[7][2] == 0 then
					table.insert(thisTextLine, {"colorField", self.settings.textFieldNoNum .. " ", false})
				else
					if self.settings.padFieldNum and txt[7][2] < 10 then
						table.insert(thisTextLine, {"colorField", self.settings.textField .. "0" .. txt[7][2] .. " ", false})
					else
						table.insert(thisTextLine, {"colorField", self.settings.textField .. txt[7][2] .. " ", false})
					end
				end
			end

			-- AI Tag, if needed
			if txt[2][1] then
				table.insert(thisTextLine, {"colorAIMark", txt[2][2], false})
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

			if self.settings.showFills then
				for idx, thisFill in pairs(txt[6]) do
					-- Seperator between fill types / vehicle
					table.insert(thisTextLine, {false, false, false})

					local thisFillType = g_fillTypeManager:getFillTypeByIndex(idx)
					local dispPerc     = math.ceil((thisFill[1] / thisFill[2]) * 100 )
					local fillColor    = self:makeFillColor(dispPerc, thisFill[3])

					table.insert(thisTextLine, {"colorFillType", thisFillType.title .. ":", false})

					table.insert(thisTextLine, {"rawFillColor", tostring(thisFill[1]), fillColor})
					if self.settings.showFillPercent then
						table.insert(thisTextLine, {"rawFillColor", " (" .. tostring(dispPerc) ..  "%)", fillColor})
					end
				end
			end

			if ( self.settings.displayMode % 2 ~= 0 ) then
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
		if self.settings.displayMode % 2 == 0 then
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

	if g_updateLoopIndex % self.settings.timerFrequency == 0 then
		-- Lets not be rediculous, only update the vehicles "infrequently"
		self:updateVehicles()
	end
end

function SimpleInspector:renderColor(name)
	local settings    = self.settings
	local colorString = Utils.getNoNil(settings[name], "1,1,1,1")

	local t={}
	for str in string.gmatch(colorString, "([^,]+)") do
		table.insert(t, tonumber(str))
	end

	setTextColor(unpack(t))
end

function SimpleInspector:renderText(x, y, fullTextSoFar, text)
	local newX = x

	if self.settings.displayMode % 2 == 0 then
		newX = newX - getTextWidth(self.inspectText.size, fullTextSoFar)
	else
		newX = newX + getTextWidth(self.inspectText.size, fullTextSoFar)
	end

	renderText(newX, y, self.inspectText.size, text)
	return text .. fullTextSoFar
end

function SimpleInspector:renderSep(x, y, fullTextSoFar)
	self:renderColor("colorSep")
	return self:renderText(x, y, fullTextSoFar, self.settings.textSep)
end

function SimpleInspector:onStartMission(mission)
	-- Load the mod, make the box that info lives in.
	print("~~" .. self.myName .." :: version " .. self.version .. " loaded.")
	if not self.isClient then
		return
	end

	if fileExists(self.confFile) then
		self:readSettingsFile()
	else
		self:createSettingsFile()
	end

	if ( self.settings.debugMode ) then
		print("~~" .. self.myName .." :: onStartMission")
	end

	self:createTextBox()
end

function SimpleInspector:findOrigin()
	local tmpX = 0
	local tmpY = 0

	if ( self.settings.displayMode == 2 ) then
		-- top right display
		tmpX, tmpY = self.gameInfoDisplay:getPosition()
		tmpX = 1
		tmpY = tmpY - 0.012
	elseif ( self.settings.displayMode == 3 ) then
		-- Bottom left, correct origin.
		tmpX = 0.01622
		tmpY = 0 + self.ingameMap:getHeight() + 0.01622
		if g_gameSettings:getValue("ingameMapState") > 1 then
			tmpY = tmpY + 0.032
		end
	elseif ( self.settings.displayMode == 4 ) then
		-- bottom right display
		tmpX = 1
		tmpY = 0.01622
		if g_currentMission.inGameMenu.hud.speedMeter.overlay.visible then
			tmpY = tmpY + self.speedMeterDisplay:getHeight() + 0.032
			if g_modIsLoaded["FS22_EnhancedVehicle"] then
				tmpY = tmpY + 0.03
			end
		end
	elseif ( self.settings.displayMode == 5 ) then
		tmpX = self.settings.displayMode5X
		tmpY = self.settings.displayMode5Y
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
	if ( self.settings.debugMode ) then
		print("~~" .. self.myName .." :: createTextBox")
	end

	local baseX, baseY = self:findOrigin()

	local boxOverlay = nil

	self.marginWidth, self.marginHeight = self.gameInfoDisplay:scalePixelToScreenVector({ 8, 8 })

	if ( self.settings.displayMode % 2 == 0 ) then -- top right
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

	self.inspectText.marginWidth, self.inspectText.marginHeight = self.gameInfoDisplay:scalePixelToScreenVector({self.settings.textMarginX, self.settings.textMarginY})
	self.inspectText.size = self.gameInfoDisplay:scalePixelToScreenHeight(self.settings.textSize)
end

function SimpleInspector:delete()
	-- clean up on remove
	if self.inspectBox ~= nil then
		self.inspectBox:delete()
	end
end

function SimpleInspector:createSettingsFile()
	-- Write a settings file.
	createFolder(self.settingsDirectory)
	createFolder(self.confDirectory)

	local defaults = self.settings
	local defaultsOrdered = {}

	for idx, _ in pairs(defaults) do
		table.insert(defaultsOrdered, idx)
	end

	table.sort(defaultsOrdered)

	local xml = createXMLFile(self.myName, self.confFile, self.myName)

	for _, idx in pairs(defaultsOrdered) do
		local groupNameTag = string.format("%s.%s(%d)", self.myName, idx, 0)
		if     type(defaults[idx]) == "boolean" then
			setXMLBool(xml, groupNameTag .. "#boolean", defaults[idx])
		elseif type(defaults[idx]) == "number" then
			if ( defaults[idx] % 1 == 0 ) then
				setXMLInt(xml, groupNameTag .. "#int", defaults[idx])
			else
				setXMLFloat(xml, groupNameTag .. "#float", defaults[idx])
			end
		else
			setXMLString(xml, groupNameTag .. "#string", defaults[idx])
		end
	end

	local groupNameTag = string.format("%s.%s(%d)", self.myName, "version", 0)
	setXMLString(xml, groupNameTag .. "#string", self.version)

	saveXMLFile(xml)
	print("~~" .. self.myName .." :: saved config file")
end

function SimpleInspector:readSettingsFile()
	-- Read settings from disk.
	local settings = self.settings
	local defaults = {}

	for idx, value in pairs(settings) do
		defaults[idx] = value
	end

	local xml = loadXMLFile(self.myName, self.confFile, self.myName)

	for idx, value in pairs(defaults) do
		local groupNameTag = string.format("%s.%s(%d)", self.myName, idx, 0)
		if     type(value) == "boolean" then
			settings[idx] = Utils.getNoNil(getXMLBool(xml, groupNameTag .. "#boolean"), value)
		elseif type(value) == "number" then
			if value % 1 == 0 then
				settings[idx] = Utils.getNoNil(getXMLInt(xml, groupNameTag .. "#int"), value)
			else
				settings[idx] = Utils.getNoNil(getXMLFloat(xml, groupNameTag .. "#float"), value)
			end
		else
			settings[idx] = Utils.getNoNil(getXMLString(xml, groupNameTag .. "#string"), value)
		end
	end

	print("~~" .. self.myName .." :: read config file")

	local groupNameTag = string.format("%s.%s(%d)", self.myName, "version", 0)
	local confVersion  = Utils.getNoNil(getXMLString(xml, groupNameTag .. "#string"), "unknown")

	if ( confVersion ~= self.version ) then
		print("~~" .. self.myName .." :: old config file, forcing update")
		self:createSettingsFile()
	elseif ( self.settings.debugMode ) then
		print("~~" .. self.myName .." :: debug mode, forcing update")
		self:createSettingsFile()
	end
end

function SimpleInspector:registerActionEvents()
	local _, reloadConfig = g_inputBinding:registerActionEvent('SimpleInspector_reload_config', self,
		SimpleInspector.actionReloadConfig, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(reloadConfig, false)
	local _, cycleDisplay = g_inputBinding:registerActionEvent('SimpleInspector_cycle_display', self,
		SimpleInspector.actionCycleDisplay, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(cycleDisplay, false)
end

function SimpleInspector:actionCycleDisplay()
	local thisModEnviroment = getfenv(0)["g_simpleInspector"]
	if ( thisModEnviroment.settings.debugMode ) then
		print("~~" .. thisModEnviroment.myName .." :: cycle display mode")
	end
	if ( thisModEnviroment.settings.displayMode > 3 ) then
		thisModEnviroment.settings.displayMode = 1
	else
		thisModEnviroment.settings.displayMode = thisModEnviroment.settings.displayMode + 1
	end
	thisModEnviroment:createSettingsFile()
end

function SimpleInspector:actionReloadConfig()
	local thisModEnviroment = getfenv(0)["g_simpleInspector"]
	if ( thisModEnviroment.settings.debugMode ) then
		print("~~" .. thisModEnviroment.myName .." :: reload settings from disk")
	end
	thisModEnviroment:readSettingsFile()
end

local modDirectory = g_currentModDirectory or ""
local modName = g_currentModName or "unknown"
local modEnvironment

local function load(mission)
	assert(g_simpleInspector == nil)

	modEnvironment = SimpleInspector:new(mission, g_i18n, modDirectory, modName)

	getfenv(0)["g_simpleInspector"] = modEnvironment

	if g_client then
		addModEventListener(modEnvironment)
		FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, SimpleInspector.registerActionEvents);
	end
end

local function unload()
	removeModEventListener(modEnvironment)
	modEnvironment:delete()
	modEnvironment = nil -- Allows garbage collecting
	getfenv(0)["g_simpleInspector"] = nil
end

local function startMission(mission)
	modEnvironment:onStartMission(mission)
end


local function init()
	FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)

	Mission00.load = Utils.prependedFunction(Mission00.load, load)
	Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, startMission)
end

init()
