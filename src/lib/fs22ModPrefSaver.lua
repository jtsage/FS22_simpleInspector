FS22PrefSaver = {}

FS22PrefSaver.typeMap = {
	boolean = "bool",
	number  = "float",
	string  = "string"
}

local FS22PrefSaver_mt = Class(FS22PrefSaver)


function FS22PrefSaver:new(modName, fileName, perSaveSlot, defaults, loadHookFunction, saveHookFunction, debugger)
	local self = setmetatable({}, FS22PrefSaver_mt)

	self.modName     = modName
	self.fileName    = fileName
	self.perSaveSlot = perSaveSlot or false
	self.settings    = {}
	self.defaults    = {}

	self:addDefaults(defaults)

	self.loadHookFunction = loadHookFunction
	self.saveHookFunction = saveHookFunction

	if debugger ~= nil and debugger.printVariable ~= nil and type(debugger.printVariable) == "function" then
		self.debugger = debugger
	else
		self.debugger = { print = function() return end, printVariable = function() return end }
	end

	if self.fileName:sub(-4) ~= ".xml" then
		self.fileName = self.fileName .. ".xml"
	end

	return self
end

function FS22PrefSaver:addDefaults(defaults)
	if type(defaults) == "table" then
		for defName, defSetting in pairs(defaults) do
			if type(defSetting) == "table" then
				self.defaults[defName] = defSetting
			else
				self.defaults[defName] = {
					defSetting,
					FS22PrefSaver.typeMap[type(defSetting)]
				}
			end
		end
	end
end

function FS22PrefSaver:dumpSettings()
	self.debugger:printVariable(self.settings, nil, "settings_current")
end

function FS22PrefSaver:dumpDefaults()
	self.debugger:printVariable(self.defaults, nil, "settings_default")
end

function FS22PrefSaver:getValue(name)
	if self.settings[name] == nil then
		if self.defaults[name] == nil or self.defaults[name][1] == nil then
			self.debugger:print("UnKnown Setting: " .. name, FS22Log.LOG_LEVEL.VERBOSE, "getValue")
			return nil
		else
			self.debugger:print("UnSet Setting (return default): " .. name, FS22Log.LOG_LEVEL.VERBOSE, "getValue")
			return self.defaults[name][1]
		end
	else
		self.debugger:print("Found Setting (return): " .. name, FS22Log.LOG_LEVEL.VERBOSE, "getValue")
		return self.settings[name]
	end
end

function FS22PrefSaver:setValue(name, newValue)
	if self.settings[name] == nil and self.defaults[name] == nil then
		self.debugger:print("Unknown Setting (return nil): " .. name, FS22Log.LOG_LEVEL.VERBOSE, "setValue")
		return nil
	end

	self.settings[name] = newValue

	self.debugger:print("Set Setting: " .. name, FS22Log.LOG_LEVEL.VERBOSE, "setValue")

	return self:getValue(name)
end


function FS22PrefSaver:createSavePath()
	local saveFolder = ('%smodSettings/%s'):format(
		getUserProfileAppPath(),
		self.modName
	)
	if ( not fileExists(saveFolder) ) then createFolder(saveFolder) end

	if self.perSaveSlot then
		saveFolder = ('%smodSettings/%s/savegame%d'):format(
			getUserProfileAppPath(),
			self.modName,
			g_currentMission.missionInfo.savegameIndex
		)
		if ( not fileExists(saveFolder) ) then createFolder(saveFolder) end
	end
end

function FS22PrefSaver:getXMLFileName()
	local name = self.perSaveSlot and
		('%smodSettings/%s/savegame%d/%s'):format(
			getUserProfileAppPath(),
			self.modName,
			g_currentMission.missionInfo.savegameIndex,
			self.fileName
		) or ('%smodSettings/%s/%s'):format(
			getUserProfileAppPath(),
			self.modName,
			self.fileName
		)

	self.debugger:print("XML File Name: " .. name, FS22Log.LOG_LEVEL.VERBOSE, "getXMLFileName")
	return name
end

function FS22PrefSaver:xmlPathMaker(key, element, attrib)
	return key .. "." .. element .. "#" .. attrib
end

function FS22PrefSaver:saveSettings()
	self:createSavePath()

	local key     = "prefSaver"
	local xmlFile = createXMLFile(key, self:getXMLFileName(), key)

	for thisSettingName, thisSettingVal in pairs(self.defaults) do
		if thisSettingVal[2] == "bool" then
			setXMLBool(
				xmlFile,
				self:xmlPathMaker(key, thisSettingName, "value"),
				self:getValue(thisSettingName)
			)
		elseif thisSettingVal[2] == "string" then
			setXMLString(
				xmlFile,
				self:xmlPathMaker(key, thisSettingName, "value"),
				self:getValue(thisSettingName)
			)
		elseif thisSettingVal[2] == "int" then
			setXMLInt(
				xmlFile,
				self:xmlPathMaker(key, thisSettingName, "value"),
				self:getValue(thisSettingName)
			)
		elseif thisSettingVal[2] == "float" then
			setXMLFloat(
				xmlFile,
				self:xmlPathMaker(key, thisSettingName, "value"),
				self:getValue(thisSettingName)
			)
		elseif thisSettingVal[2] == "color" then
			local r, g, b, a = unpack(Utils.getNoNil(self:getValue(thisSettingName), thisSettingVal[1]))
			setXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "r"), r)
			setXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "g"), g)
			setXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "b"), b)
			setXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "a"), a)
		end
	end

	saveXMLFile(xmlFile)

	self.debugger:print("Saved Settings", FS22Log.LOG_LEVEL.DEVEL, "settingsFile")

	if type(self.saveHookFunction) =="function" then
		self.saveHookFunction()
	end
end

function FS22PrefSaver:loadSettings()
	local key     = "prefSaver"

	if fileExists(self:getXMLFileName()) then
		local xmlFile = loadXMLFile(key, self:getXMLFileName())

		for thisSettingName, thisSettingVal in pairs(self.defaults) do
			if thisSettingVal[2] == "bool" then
				self:setValue(
					thisSettingName, 
					Utils.getNoNil(getXMLBool(
						xmlFile,
						self:xmlPathMaker(key, thisSettingName, "value")
					), thisSettingVal[1])
				)
			elseif thisSettingVal[2] == "string" then
				self:setValue(
					thisSettingName, 
					Utils.getNoNil(getXMLString(
						xmlFile,
						self:xmlPathMaker(key, thisSettingName, "value")
					), thisSettingVal[1])
				)
			elseif thisSettingVal[2] == "int" then
				self:setValue(
					thisSettingName, 
					Utils.getNoNil(getXMLInt(
						xmlFile,
						self:xmlPathMaker(key, thisSettingName, "value")
					), thisSettingVal[1])
				)
			elseif thisSettingVal[2] == "float" then
				self:setValue(
					thisSettingName, 
					Utils.getNoNil(getXMLFloat(
						xmlFile,
						self:xmlPathMaker(key, thisSettingName, "value")
					), thisSettingVal[1])
				)
			elseif thisSettingVal[2] == "color" then
				local r, g, b, a = unpack(thisSettingVal[1])
				r = Utils.getNoNil(getXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "r")), r)
				g = Utils.getNoNil(getXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "g")), g)
				b = Utils.getNoNil(getXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "b")), b)
				a = Utils.getNoNil(getXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "a")), a)
				self:setValue(thisSettingName, {r, g, b, a})
			end
		end

		delete(xmlFile)
	end

	self.debugger:print("Loaded Settings", FS22Log.LOG_LEVEL.DEVEL, "settingsFile")

	if type(self.loadHookFunction) =="function" then
		self.loadHookFunction()
	end
end