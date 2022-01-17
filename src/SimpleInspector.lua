--
-- Mod: FS22_SimpleInspector
--
-- Author: JTSage
-- source: https://github.com/jtsage/FS22_Simple_Inspector

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
	self.gameInfoDisplay   = mission.hud.gameInfoDisplay
	self.speedMeterDisplay = mission.hud.speedMeter

	self.settingsDirectory = getUserProfileAppPath() .. "modSettings/"
	self.confDirectory     = self.settingsDirectory .."FS22_SimpleInspector/"
	self.confFile          = self.confDirectory .. "FS22_SimpleInspectorSettings.xml"

	self.settings = {
		displayMode    = 2, -- 1: top left, 2: top right, 3: bot left, 4: bot right
		debugMode      = false,
		showAll        = false,
		showPercent    = true,
		maxDepth       = 5,
		timerFrequency = 15,
		textMarginX    = 15,
		textMarginY    = 10,
		textSize       = 12,
		colorNormal    = "1, 1, 1, 1",
		colorFillFull  = "1, 0, 0, 1",
		colorFillHalf  = "1, 1, 0, 1",
		colorFillLow   = "0, 1, 0, 1",
		colorFillType  = "0.7, 0.7, 0.7, 1",
		colorUser      = "0, 1, 0, 1",
		colorAI        = "0, 0.77, 1, 1",
		colorAIMark    = "0, .5, 1, 1",
		colorSep       = "1, 1, 1, 1",
		colorSpeed     = "0, 0.5, 1, 1",
		textHelper     = "_AI_ ",
		textSep        = " | "
	}

	self.debugTimerRuns = 0
	self.inspectText    = {}
	self.boxBGColor     = { 544, 20, 200, 44 }
	self.bgName         = 'dataS/menu/blank.png'

	local modDesc       = loadXMLFile("modDesc", modDirectory .. "modDesc.xml");
	self.version        = getXMLString(modDesc, "modDesc.version");

	self.display_data = { }

	return self
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
	-- Borrowed heavily from older versions of similar plugins, ignores unknonw fill types
	local spec_fillUnit = vehicle.spec_fillUnit

	if spec_fillUnit ~= nil and spec_fillUnit.fillUnits ~= nil then
		for i = 1, #spec_fillUnit.fillUnits do
			local goodFillType = false
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
					if ( theseFills[fillType] ~= nil ) then
						theseFills[fillType][1] = theseFills[fillType][1] + fillLevel
						theseFills[fillType][2] = theseFills[fillType][2] + capacity
					else
						theseFills[fillType] = { fillLevel, capacity }
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
				local isRidable = SpecializationUtil.hasSpecialization(Rideable, thisVeh.specializations)
				if ( not isTrain and not isRidable) then
					local isRunning = thisVeh.getIsMotorStarted ~= nil and thisVeh:getIsMotorStarted()
					local isOnAI    = thisVeh.getIsAIActive ~= nil and thisVeh:getIsAIActive()
					local isConned  = thisVeh.getIsControlled ~= nil and thisVeh:getIsControlled()

					if ( self.settings.showAll or isConned or isRunning or isOnAI) then
						local thisName  = thisVeh:getName()
						local thisBrand = g_brandManager:getBrandByIndex(thisVeh:getBrand())
						local speed     = self:getSpeed(thisVeh)
						local fills     = {}
						local status    = 0
						local isAI      = false

						if isOnAI then
							status = 1
							isAI = true
						end
						if thisVeh:getIsControlled() then
							status = 2
						end

						self:getAllFills(thisVeh, fills, 0)
						table.insert(new_data_table, {
							status,
							isAI,
							thisBrand.title .. " " .. thisName,
							tostring(speed),
							fills
						})
					end
				end
			end
		end
	end

	self.display_data = {unpack(new_data_table)}
end

function SimpleInspector:update(dt)
	if not self.isClient then
		return
	end

	if self:shouldNotBeShown() then
		self.inspectBox:setVisible(false)
		return
	end

	if g_updateLoopIndex % self.settings.timerFrequency == 0 then
		-- Lets not be rediculous, only update the vehicles "infrequently"
		self:updateVehicles()
		if ( self.settings.debugMode ) then
			self.debugTimerRuns = self.debugTimerRuns + 1
			print("~~" .. self.myName .." :: update (" .. self.debugTimerRuns .. ")")
		end
	end

	if self.inspectBox ~= nil then
		local hideBox   = true
		local info_text = self.display_data
		local deltaY    = 0

		if g_currentMission.hud.sideNotifications ~= nil then
			if #g_currentMission.hud.sideNotifications.notificationQueue > 0 then
				deltaY = g_currentMission.hud.sideNotifications:getHeight()
			end
		end

		setTextAlignment(RenderText.ALIGN_RIGHT)
		setTextBold(true)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)

		local x = self.inspectText.posX - self.inspectText.marginHeight
		local y = self.inspectText.posY - self.inspectText.marginHeight - deltaY
		local _w, _h = 0, self.inspectText.marginHeight * 2

		for _, txt in pairs(info_text) do
			-- Data structure for each vehicle is:
			-- (new_data_table, {
			-- 	status, (0 no special status, 1 = AI, 2 = user controlled)
			-- 	isAI, (true / false - if status is 1 & 2)
			-- 	thisBrand.title .. " " .. thisName,
			-- 	tostring(speed), (in the users units)
			-- 	fills (table - index is fillType, contents are 1:level, 2:capacity)
			-- })

			-- At least one entry, show the box.
			hideBox = false

			local thisTextLine = {}
			local fullTextSoFar = ""

			-- AI Tag, if needed
			if txt[2] then
				table.insert(thisTextLine, {"colorAIMark", self.settings.textHelper, false})
			end

			-- Vehicle speed
			if g_gameSettings:getValue('useMiles') then
				table.insert(thisTextLine, {"colorSpeed", txt[4] .. "mph", false})
			else
				table.insert(thisTextLine, {"colorSpeed", txt[4] .. "kph", false})
			end

			-- Seperator after speed
			table.insert(thisTextLine, {false, false, true})

			-- Vehicle name
			if txt[1] == 0 then
				table.insert(thisTextLine, {"colorNormal", txt[3], false})
			elseif txt[1] == 1 then
				table.insert(thisTextLine, {"colorAI", txt[3], false})
			else 
				table.insert(thisTextLine, {"colorUser", txt[3], false})
			end

			for idx, thisFill in pairs(txt[5]) do
				-- Seperator between fill types / vehicle
				table.insert(thisTextLine, {false, false, true})

				local thisFillType = g_fillTypeManager:getFillTypeByIndex(idx)
				local thisPerc = math.ceil((thisFill[1] / thisFill[2]) * 100 )
				local fillColor = nil

				-- For some fill types, we want the color reversed (consumables)
				if idx == 16 or idx == 41 then thisPerc = 100 - thisPerc
				elseif idx > 72 and idx < 79 then thisPerc = 100 - thisPerc
				elseif idx > 79 and idx < 84 then thisPerc = 100 - thisPerc
				end

				table.insert(thisTextLine, {"colorFillType", thisFillType.title:lower() .. ":"})

				if thisPerc < 50     then fillColor = "colorFillLow"
				elseif thisPerc < 85 then fillColor = "colorFillHalf"
				else                      fillColor = "colorFillFull"
				end

				table.insert(thisTextLine, {fillColor, tostring(thisFill[1]), false})
				if self.settings.showPercent then
					table.insert(thisTextLine, {fillColor, " (" .. tostring(thisPerc) ..  "%)", false})
				end
			end

			if ( self.settings.displayMode % 2 ~= 0 ) then
				for _, thisLine in ipairs(thisTextLine) do
					if thisLine[3] then
						fullTextSoFar = self:renderSep(x, y, fullTextSoFar)
					else
						self:renderColor(thisLine[1])
						fullTextSoFar = self:renderText(x, y, fullTextSoFar, thisLine[2])
					end
				end
			else
				for i = #thisTextLine, 1, -1 do
					if thisTextLine[i][3] then
						fullTextSoFar = self:renderSep(x, y, fullTextSoFar)
					else
						self:renderColor(thisTextLine[i][1])
						fullTextSoFar = self:renderText(x, y, fullTextSoFar, thisTextLine[i][2])
					end
				end
			end

			y = y - self.inspectText.size
			_h = _h + self.inspectText.size
			local tmp = getTextWidth(self.inspectText.size, fullTextSoFar)

			if tmp > _w then _w = tmp end
		end

		if hideBox then
			self.inspectBox:setVisible(false)
		else
			self.inspectBox:setVisible(true)
		end

		-- update overlay background
		self.inspectBox.overlay:setPosition(x - _w - self.inspectText.marginWidth, y - self.inspectText.marginHeight)
		self.inspectBox.overlay:setDimension(_w + self.inspectText.marginHeight + self.inspectText.marginWidth, _h)

		-- reset text render to "defaults" to be kind
		setTextColor(1,1,1,1)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		setTextBold(false)
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

	renderText(x - getTextWidth(self.inspectText.size, fullTextSoFar), y, self.inspectText.size, text)
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

function SimpleInspector:createTextBox()
	-- make the box we live in.
	if ( self.settings.debugMode ) then
		print("~~" .. self.myName .." :: createTextBox")
	end

	local baseX, baseY = self.gameInfoDisplay:getPosition()
	self.marginWidth, self.marginHeight = self.gameInfoDisplay:scalePixelToScreenVector({ 8, 8 })

	local boxOverlay = Overlay.new(self.bgName, 1, baseY - self.marginHeight, 1, 1)
	local boxElement = HUDElement.new(boxOverlay)
	self.inspectBox = boxElement
	
	self.inspectBox:setUVs(GuiUtils.getUVs(self.boxBGColor))
	self.inspectBox:setColor(unpack(SpeedMeterDisplay.COLOR.GEARS_BG))
	self.inspectBox:setVisible(false)
	self.gameInfoDisplay:addChild(boxElement)

	self.inspectText.posX = 1
	self.inspectText.posY = baseY - self.marginHeight
	self.inspectText.marginWidth, self.inspectText.marginHeight = self.gameInfoDisplay:scalePixelToScreenVector({self.settings.textMarginX, self.settings.textMarginY})
	self.inspectText.size = self.gameInfoDisplay:scalePixelToScreenHeight(self.settings.textSize)
end

function SimpleInspector:shouldNotBeShown()
	-- hide when menu open or paused or gui off
	if g_currentMission.paused or
		g_gui:getIsGuiVisible() or
		g_currentMission.inGameMenu.paused or
		g_currentMission.inGameMenu.isOpen or
		g_currentMission.physicsPaused or
		not g_currentMission.hud.isVisible then

			if g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission.manualPaused then return false end

			return true
		end
		return false
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
			setXMLInt(xml, groupNameTag .. "#int", defaults[idx])
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
			settings[idx] = Utils.getNoNil(getXMLInt(xml, groupNameTag .. "#int"), value)
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


local modDirectory = g_currentModDirectory or ""
local modName = g_currentModName or "unknown"
local modEnvironment

---Fix for registering the savegame schema (perhaps this can be better).
-- g_simpleInspectorModName = modName

local function load(mission)
	assert(g_simpleInspector == nil)

	modEnvironment = SimpleInspector:new(mission, g_i18n, modDirectory, modName)

	getfenv(0)["g_simpleInspector"] = modEnvironment

	addModEventListener(modEnvironment)
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
