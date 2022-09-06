-- FS22Log LUA Debug Class for FS22
--
-- Class init:
--
-- yourLogger = FS22Log:new(callerName, debugMode, filterOut, filterExclusive)
--  * callerName      : Name of your mod, or logging section
--  * debugMode       : one of the DEBUG_MODEs below, .WARNINGS suggested for production mode
--  * filterOut       : names to filter **OUT** of printed output
--  * filterExclusive : names to **ONLY** print, takes precedence
--
--
-- Functions Available:
--
--
-- Print text to the log
--
-- yourLogger:print(text, logLevel, filter)
--   * text     : Text to print
--   * logLevel : Log level from LOG_LEVEL below, default is .DEVEL
--   * filter   : Text string for [filterOut] and [filterExclusive], default is "--"
--
--
-- Print variable contents to the log - recursively prints tables
--
-- yourLogger.printVariable(output, logLevel, filter, depthLimit, prefix, searchTerms)
-- yourLogger.printVariableIsTable(output, logLevel, filter, depthLimit, prefix, searchTerms)
-- 
-- The "IsTable" variant will auto-upgrade the logLevel to WARNING when the variable is not a table,
-- and ERROR if the variable is undefined or nil
--
--   * output      : Variable to print
--   * logLevel    : Log level from LOG_LEVEL below, default is .DEVEL
--   * filter      : Text string for [filterOut] and [filterExclusive], default is "--"
--   * depthLimit  : How deep to traverse tables, default is 2 levels (1 based option - e.g 2 == show 2 levels total)
--   * prefix      : Text string for name of variable, defaults to [filter]
--   * searchTerms : Terms to search - options:
--               "string"                                    : Search for "string" in KEYS only
--               { "string", SEARCH.TYPE }                   : Search for "string" using SEARCH.TYPE from below.
--               { {"table", "of", "strings"}, SEARCH.TYPE } : Search for all strings in table using SEARCH.TYPE from below.
--
--
-- Intercept function calls to print the arguments it's being called with.  This method call is similar
-- to how Utils.prependedFunction() works.
--
-- Note that if you pass an invalid function, *when in debug mode*, a valid function with an error 
-- message will be returned
--
-- originFunction = FS22LogFunction (logLevel, originMod, originFunctionName, originFunction)
--  * logLevel           : Log level from LOG_LEVEL below, has no function is set to .WARNINGS or .ERRORS or .NONE
--  * originMod          : Name of your mod for printing purposes
--  * originFunctionName : Name of the original function (string)
--  * originFunction     : Original function (literal)
--
--
-- Run Levels:
--  It is highly recommended that your store this value locally in your mod, and pass it to the
--  constructor / calls to FS22LogFunction() so you can quickly toggle the level for released mods
--  without having to remove all your logging calls.
--
--  * FS22Log.DEBUG_MODE.NONE     - Print nothing, ever
--  * FS22Log.DEBUG_MODE.ERRORS   - Print errors
--  * FS22Log.DEBUG_MODE.WARNINGS - Print warnings, suggested for "production" mode
--  * FS22Log.DEBUG_MODE.INFO     - Print information
--  * FS22Log.DEBUG_MODE.DEVEL    - Print Development information
--  * FS22Log.DEBUG_MODE.VERBOSE  - Print Verbose Development information
--
-- Log Levels:
--  * FS22Log.LOG_LEVEL.ERROR   - Errors only
--  * FS22Log.LOG_LEVEL.WARNING - Warnings, suggested for "production" mode
--  * FS22Log.LOG_LEVEL.INFO    - Information level
--  * FS22Log.LOG_LEVEL.DEVEL   - Development information
--  * FS22Log.LOG_LEVEL.VERBOSE - Verbose Development information
--
-- Search Types:
--  * FS22Log.SEARCH.KEYS            - Search keys only
--  * FS22Log.SEARCH.VALUES          - Search values only
--  * FS22Log.SEARCH.BOTH            - Search both keys and values
--  * FS22Log.SEARCH.KEYS_AND_VALUES - Search both keys and values
--
-- (c)JTSage Modding & FSG Modding.  You may reuse or alter this code to your needs as nessesary with
-- no prior permission.  No warrenty implied or otherwise.

FS22Log = {}

local FS22Log_mt = Class(FS22Log)

FS22Log.DEBUG_MODE          = {}
FS22Log.DEBUG_MODE.NONE     = 0
FS22Log.DEBUG_MODE.ERRORS   = 1
FS22Log.DEBUG_MODE.WARNINGS = 2
FS22Log.DEBUG_MODE.INFO     = 3
FS22Log.DEBUG_MODE.DEVEL    = 4
FS22Log.DEBUG_MODE.VERBOSE  = 5

FS22Log.LOG_LEVEL         = {}
FS22Log.LOG_LEVEL.ERROR   = 1
FS22Log.LOG_LEVEL.WARNING = 2
FS22Log.LOG_LEVEL.INFO    = 3
FS22Log.LOG_LEVEL.DEVEL   = 4
FS22Log.LOG_LEVEL.VERBOSE = 5

FS22Log.SEARCH                 = {}
FS22Log.SEARCH.NONE            = 0
FS22Log.SEARCH.KEYS            = 1
FS22Log.SEARCH.VALUES          = 2
FS22Log.SEARCH.BOTH            = 3
FS22Log.SEARCH.KEYS_AND_VALUES = 3
FS22Log.SEARCH.BAD_TERMS       = 4

FS22Log.SEARCH_TEXT = {
	[0] = "NONE",
	[1] = "KEYS",
	[2] = "VALUES",
	[3] = "KEYS and VALUES",
	[4] = "-ERROR-"
}

FS22Log.LOG_LEVEL_TEXT = {
	[1] = "ERROR",
	[2] = "WARNING",
	[3] = "INFO",
	[4] = "DEVEL",
	[5] = "VERBOSE"
}

function FS22Log:new(callerName, debugMode, filterOut, filterExclusive)
	local self = setmetatable({}, FS22Log_mt)

	self.calledName = callerName or "UnKnown Script"
	self.debugMode  = debugMode or FS22Log.DEBUG_MODE.ERRORS
	self.filteredOut  = {}
	self.filteredIn   = {}

	if filterOut ~= nil and type(filterOut) == "table" then
		self.filteredOut = filterOut
	end

	if filterExclusive ~= nil and type(filterExclusive) == "table" then
		self.filteredOut = {}
		self.filteredIn  = filterExclusive
	end

	return self
end

function FS22Log:isFiltered(filterOperator)
	if self.filteredIn ~= nil and #self.filteredIn > 0 then
		if filterOperator == nil then
			return true
		end
		for _, filterMe in ipairs(self.filteredIn) do
			if filterOperator == filterMe then
				return false
			end
		end
		return true
	end

	if self.filteredOut == nil or #self.filteredOut < 0 or filterOperator == nil then
		return false
	end

	for _, filterMe in ipairs(self.filteredOut) do
		if filterOperator == filterMe then
			return true
		end
	end

	return false
end

function FS22Log:cleanLogLevel(logLevel)
	local cleanLogLevel

	if logLevel ~= nil and type(logLevel) == "number" and logLevel > 0 then
		cleanLogLevel = logLevel
	else
		cleanLogLevel = FS22Log.LOG_LEVEL.DEVEL
	end

	return cleanLogLevel
end

function FS22Log:processSearchTerms(testTable, searchTerms, logLevel, filter)
	local findWords = {}
	local findType  = FS22Log.SEARCH.NONE
	if searchTerms == nil or testTable == nil or type(testTable) ~= "table" then
		return false, nil, nil
	end

	if type(searchTerms) ~= "table" then
		findType  = FS22Log.SEARCH.KEYS
		findWords = { searchTerms }
	else
		if #searchTerms ~= 2 or type(searchTerms[2]) ~= "number" then
			return true, FS22Log.SEARCH.BAD_TERMS, nil
		end

		findType = searchTerms[2]

		if type(searchTerms[1]) ~= "table" then
			findWords = { searchTerms[1] }
		else
			if #searchTerms[1] < 1 then
				return false, nil, nil
			end
			findWords = searchTerms[1]
		end
	end
	return true, findType, findWords
end

function FS22Log:searchTerm(testKey, testValue, findType, findWords)
	if findType == FS22Log.SEARCH.BAD_TERMS then
		return false
	end
	if findType == FS22Log.SEARCH.NONE then
		return true
	end
	if findType == FS22Log.SEARCH.KEYS or findType == FS22Log.SEARCH.BOTH then
		for _, lookWord in ipairs(findWords) do
			if string.find(tostring(testKey), tostring(lookWord)) then
				return true
			end
		end
	end
	if findType == FS22Log.SEARCH.VALUES or findType == FS22Log.SEARCH.BOTH then
		for _, lookWord in ipairs(findWords) do
			if string.find(tostring(testValue), tostring(lookWord)) then
				return true
			end
		end
	end
	return false
end

function FS22Log:print(text, logLevel, filter)
	local logLevel = self:cleanLogLevel(logLevel)

	if self.debugMode >= logLevel then
		if not self:isFiltered(filter) then
			local levelText  = FS22Log.LOG_LEVEL_TEXT[logLevel] or "UNKNOWN"
			local filterText = filter or "--"
			local outputText = "~~ " .. self.calledName .. ":" .. levelText .. ":" .. filterText .. " | " .. text

			if logLevel == FS22Log.LOG_LEVEL.ERROR then
				printError(outputText)
			elseif logLevel == FS22Log.LOG_LEVEL.WARNING then
				printWarning(outputText)
			else
				print(outputText)
			end
		end
	end
end


function FS22Log:printVariableIsTable(output, logLevel, filter, depthLimit, prefix, searchTerms, currentDepth)
	if output == nil then
		logLevel = FS22Log.LOG_LEVEL.ERROR
	elseif type(output) ~= "table" then
		logLevel = FS22Log.LOG_LEVEL.WARNING
	end
	self:printVariable(output, logLevel, filter, depthLimit, prefix, searchTerms, currentDepth)
end


function FS22Log:printVariable(output, logLevel, filter, depthLimit, prefix, searchTerms, currentDepth)
	local prefix       = prefix or filter or "{}"
	local logLevel     = self:cleanLogLevel(logLevel)
	local depthLimit   = depthLimit or 2
	local currentDepth = currentDepth or 0
	local maxLength    = 0

	if output == nil or type(output) ~= "table" then
		self:print(prefix .. " :: " .. tostring(output), logLevel, filter)
		return
	end

	local searchDo, searchType, searchWords = self:processSearchTerms(output, searchTerms, logLevel, filter)

	for key, _ in pairs(output) do
		local currentLength = string.len(tostring(key))
		if currentLength > maxLength then
			maxLength = currentLength
		end
	end

	if searchDo == true and currentDepth == 0 and searchType > 0 and searchType < 4 and type(searchWords) == "table" then
		self:print(
			"Searching for: {" .. table.concat(searchWords, ",") .. "} [" .. FS22Log.SEARCH_TEXT[searchType] .. "]",
			logLevel,
			filter
		)
	end

	currentDepth = currentDepth + 1

	if searchType == FS22Log.SEARCH.BAD_TERMS then
		self:print("ERROR: Incorrect search terms, see logger documentation", logLevel, filter)
		return
	end

	for key, value in pairs(output) do
		local keyString   = tostring(key)
		local spacePad    = string.rep(" ", maxLength - string.len(keyString))
		local depthPad    = string.rep("_", currentDepth - 1)
		local thisPrefix  = prefix .. "." .. keyString
		local searchFound = true

		if searchDo and searchType ~= FS22Log.SEARCH.BAD_TERMS then
			searchFound = self:searchTerm(key, value, searchType, searchWords)
		end

		if searchFound then
			self:print(
				depthPad .. thisPrefix .. spacePad .. " :: " .. tostring(value),
				logLevel,
				filter
			)
		end

		if type(value) == "table" and currentDepth < depthLimit then
			self:printVariable(
				value,
				logLevel,
				filter,
				depthLimit,
				thisPrefix,
				searchTerms,
				currentDepth
			)
		end
	end
end

function FS22LogFunction (logLevel, originMod, originFunctionName, originFunction)
	if logLevel == nil or logLevel <= FS22Log.DEBUG_MODE.WARNINGS then return originFunction end
	if originFunction ~= nil then
		return function (...)
			local argNames  = function(...) return arg end
			local argValues = argNames(...)
			if type(argValues) == "table" then
				local argListText = ""
				for idx, arggy in ipairs(argValues) do
					argListText = argListText .. (idx == 1 and "" or ", ") .. '[' .. tostring(arggy) .. ']'
				end
				print("~~ " .. originMod .. ":" .. originFunctionName .. " | Called With: " .. argListText)
			else
				print("~~ " .. originMod .. ":" .. originFunctionName .. " | Called (no arguments)")
			end
			originFunction(...)
		end
	else
		print("~~ " .. originMod .. ":" .. originFunctionName .. " | Original Function Not Found")
		return function (...) print("~~ " .. originMod .. ":" .. originFunctionName .. " | Invalid function call (no original)") end
	end
end