
FS22FSGUnits = {}

local FS22FSGUnits_mt = Class(FS22FSGUnits)

function FS22FSGUnits:new(logger)
	local self = setmetatable({}, FS22FSGUnits_mt)

	self.logger = logger

	self.unit_types = {}
	self.unit_types.SOLID  = 1
	self.unit_types.LIQUID = 2
	self.unit_types.NONE   = 3

	self.unit_type_liguid = {
		[FillType.SILAGE_ADDITIVE]  = true,
		[FillType.LIQUIDFERTILIZER] = true,
		[FillType.HERBICIDE]        = true,
		[FillType.MILK]             = true,
		[FillType.WATER]            = true,
		[FillType.DEF]              = true,
		[FillType.SUNFLOWER_OIL]    = true,
		[FillType.DIESEL]           = true,
		[FillType.CANOLA_OIL]       = true,
		[FillType.OLIVE_OIL]        = true,
		[FillType.GRAPEJUICE]       = true,
		[FillType.LIQUIDMANURE]     = true,
		[FillType.DIGESTATE]        = true,
	}

	self.unit_type_bales = {
		[FillType.ROUNDBALE]           = true,
		[FillType.ROUNDBALE_GRASS]     = true,
		[FillType.ROUNDBALE_DRYGRASS]  = true,
		[FillType.ROUNDBALE_COTTON]    = true,
		[FillType.ROUNDBALE_WOOD]      = true,
		[FillType.SQUAREBALE]          = true,
		[FillType.SQUAREBALE_COTTON]   = true,
		[FillType.SQUAREBALE_WOOD]     = true,
		[FillType.SQUAREBALE_DRYGRASS] = true,
		[FillType.SQUAREBALE_GRASS]    = true,
	}

	self.unitsToIndex = {
		LITER   = 1,
		BUSHEL  = 2,
		C_METER = 3,
		C_FOOT  = 4,
		C_YARD  = 5,
		KG      = 6,
		OZ      = 7,
		LBS     = 8,
		CWT     = 9,
		MT      = 10,
		T       = 11,
		F_OZ    = 12,
		GAL     = 13,
	}

	self.units = {
		[self.unitsToIndex.LITER]   = { precision = 0, isWeight = false, text = "l",     factor = 1 },
		[self.unitsToIndex.BUSHEL]  = { precision = 2, isWeight = false, text = "bu",    factor = 0.028378 },
		[self.unitsToIndex.C_METER] = { precision = 3, isWeight = false, text = "m³",    factor = 0.001 },
		[self.unitsToIndex.C_FOOT]  = { precision = 2, isWeight = false, text = "ft³",   factor = 0.035315 },
		[self.unitsToIndex.C_YARD]  = { precision = 2, isWeight = false, text = "yd³",   factor = 0.001308},
		[self.unitsToIndex.KG]      = { precision = 0, isWeight = true,  text = "kg",    factor = 1 },
		[self.unitsToIndex.OZ]      = { precision = 0, isWeight = true,  text = "oz",    factor = 35.27396 },
		[self.unitsToIndex.LBS]     = { precision = 0, isWeight = true,  text = "lbs",   factor = 2.204623 },
		[self.unitsToIndex.CWT]     = { precision = 2, isWeight = true,  text = "cwt",   factor = 0.022046 },
		[self.unitsToIndex.MT]      = { precision = 3, isWeight = true,  text = "mt",    factor = 0.001 },
		[self.unitsToIndex.T]       = { precision = 3, isWeight = true,  text = "t",     factor = 0.0011023 },
		[self.unitsToIndex.F_OZ]    = { precision = 0, isWeight = false, text = "fl.oz", factor = 33.814023 },
		[self.unitsToIndex.GAL]     = { precision = 2, isWeight = false, text = "gal",   factor = 0.264172},
	}

	self.unit_select = {
		[self.unit_types.SOLID] = {
			self.unitsToIndex.LITER,
			self.unitsToIndex.BUSHEL,
			self.unitsToIndex.C_METER,
			self.unitsToIndex.C_FOOT,
			self.unitsToIndex.C_YARD,
			self.unitsToIndex.KG,
			self.unitsToIndex.OZ,
			self.unitsToIndex.LBS,
			self.unitsToIndex.CWT,
			self.unitsToIndex.MT,
			self.unitsToIndex.T,
		},
		[self.unit_types.LIQUID] = {
			self.unitsToIndex.LITER,
			self.unitsToIndex.F_OZ,
			self.unitsToIndex.GAL,
			self.unitsToIndex.KG,
			self.unitsToIndex.OZ,
			self.unitsToIndex.LBS,
			self.unitsToIndex.CWT,
			self.unitsToIndex.MT,
			self.unitsToIndex.T,
		}
	}

	--self.logger:printVariable(self.unit_select, FS22Log.LOG_LEVEL.VERBOSE, "units:unit_select")

	return self
end

function FS22FSGUnits:getSettingsTexts(unitType)
	-- Args:
	--  - unitType : FS22FSGUnits.unit_types.SOLID or FS22FSGUnits.unit_types.LIQUID
	local settingsTable = {}

	if self.unit_select[unitType] == nil then
		return settingsTable
	end

	for _, typeIdx in ipairs(self.unit_select[unitType]) do
		table.insert(settingsTable, self.units[typeIdx].text)
	end

	return settingsTable
end

function FS22FSGUnits:getUnitType(fillTypeIdx)
	-- Args:
	--  - fillTypeIdx : fillType index.  Same as to g_fillTypeManager:getFillTypeByIndex()
	if self.unit_type_bales[fillTypeIdx] ~= nil then
		return self.unit_types.NONE
	end

	if self.unit_type_liguid[fillTypeIdx] ~= nil then
		return self.unit_types.LIQUID
	end

	if g_fillTypeManager:getIsFillTypeInCategory(fillTypeIdx, 'ANIMAL') or g_fillTypeManager:getIsFillTypeInCategory(fillTypeIdx, 'HORSE') then
		return self.unit_types.NONE
	end

	return self.unit_types.SOLID
end

function FS22FSGUnits:scaleFillTypeLevel(fillTypeIdx, fillLevel, unitIdxSolid, unitIdxLiquid, showUnit)
	-- Args :
	--  - fillTypeIdx :  fillType index.  Same as to g_fillTypeManager:getFillTypeByIndex()
	--  - fillLevel : Numeric fill level
	--  - unitIdxSolid : Unit to use for solids, from FS22FSGUnits.unit_select[<unit type>]
	--  - unitIdxLiquid : Unit to use for liquids, from FS22FSGUnits.unit_select[<unit type>]
	--  - showUnit : append unit to returned value, default true
	local showTheUnit  = Utils.getNoNil(showUnit, true)
	local fillType     = g_fillTypeManager:getFillTypeByIndex(fillTypeIdx)
	local massPerLiter = Utils.getNoNil(fillType.massPerLiter, 1)
	local unitType     = self:getUnitType(fillTypeIdx)
	local realUnitIdx  = 1

	if unitType == self.unit_types.NONE then
		return fillLevel
	end

	if unitType == self.unit_types.LIQUID then
		realUnitIdx = self.unit_select[unitType][unitIdxLiquid]
	end
	if unitType == self.unit_types.SOLID then
		realUnitIdx = self.unit_select[unitType][unitIdxSolid]
	end

	local unitData        = self.units[realUnitIdx]
	local returnFillLevel = fillLevel

	if unitData.isWeight then
		returnFillLevel = fillLevel * massPerLiter * 1000
	end

	local convertedFillLevel = MathUtil.round(returnFillLevel * unitData.factor, unitData.precision)

	if showTheUnit then
		return tostring(convertedFillLevel) .. " " .. unitData.text
	else
		return tostring(convertedFillLevel)
	end
end

