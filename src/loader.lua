
local modDirectory = g_currentModDirectory or ""
local modName = g_currentModName or "unknown"
local modEnvironment

source(g_currentModDirectory .. 'SimpleInspector.lua')

local function load(mission)
	assert(g_simpleInspector == nil)

	modEnvironment = SimpleInspector:new(mission, g_i18n, modDirectory, modName)

	getfenv(0)["g_simpleInspector"] = modEnvironment

	if mission:getIsClient() then
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

	InGameMenuGameSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameOpen, SimpleInspector.initGui)

	FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, SimpleInspector.saveSettings) -- Settings are saved live, but we need to do it here too, since the old save directory (with our xml) is now a backup
end

init()