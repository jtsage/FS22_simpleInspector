-- Loader for SimpleInspector

local debug        = false
local modDirectory = g_currentModDirectory or ""
local modName      = g_currentModName or "unknown"
local modEnvironment

source(g_currentModDirectory .. 'SimpleInspector.lua')
source(g_currentModDirectory .. 'lib/fs22Logger.lua')
source(g_currentModDirectory .. 'lib/fs22SimpleUtils.lua')

local function load(mission)
	assert(g_simpleInspector == nil)

	local siLoggeer = FS22Log:new(
		"simpleInspector",
		debug and FS22Log.DEBUG_MODE.VERBOSE or FS22Log.DEBUG_MODE.WARNINGS,
		{
			"getValue",
			"setValue",
			"display_data",
			"outputTextLines"
		}
	)

	modEnvironment = SimpleInspector:new(mission, modDirectory, modName, siLoggeer)

	getfenv(0)["g_simpleInspector"] = modEnvironment

	if mission:getIsClient() then
		addModEventListener(modEnvironment)
		FSBaseMission.registerActionEvents       = Utils.appendedFunction(FSBaseMission.registerActionEvents, SimpleInspector.registerActionEvents);
		FSBaseMission.onToggleConstructionScreen = Utils.prependedFunction(FSBaseMission.onToggleConstructionScreen, SimpleInspector.openConstructionScreen)
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

local function save()
	modEnvironment:save()
end

local function init()
	FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)

	Mission00.load           = Utils.prependedFunction(Mission00.load, load)
	Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, startMission)

	InGameMenuGeneralSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGeneralSettingsFrame.onFrameOpen, SimpleInspector.initGui)

	FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, save)
end

init()