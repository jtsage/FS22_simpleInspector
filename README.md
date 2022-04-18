# FS22_SimpleInspector

![GitHub release (latest by date)](https://img.shields.io/github/v/release/jtsage/FS22_simpleInspector) ![GitHub all releases](https://img.shields.io/github/downloads/jtsage/FS22_simpleInspector/total)

<p align="left">
  <img src="https://github.com/jtsage/FS22_simpleInspector/raw/main/modIcon.png">
</p>

Spiritual ripoff of VehicleInspector - pared down to what I need/want

## Note about the ZIP in the repo

That ZIP file, while the ?working? mod, is usually my test version.  It's updated multiple times per
version string, so be aware if you download from there, instead of the releases page, you might be
unknowingly using an old version.  For "official" releases, please use the release link to the right.

## Features

* 4 on screen placement locations - each corner of the display
* Just your vehicles or all vehicles
* Speed of vehicles
* Fuel level of vehicles
* On Field Status, optionally with Field number
* Occupation status - Vanilla AI, AutoDrive, CoursePlay, user, or noone
* CoursePlay course progression, if applicable
* Fill level of vehicle and attached implements
* Damage warning if vehicle or attached implement is over threshold

## Default Input Bindings

* `Left Ctrl` + `Left Alt` + `Num Pad 9` : Reload configuration file from disk
* `Left Alt` + `Num Pad 9` : Toggle Visibility

## Options

All options are set via a xml file in `modSettings/FS22_SimpleInspector/savegame##/simpleInspector.xml`

Most view options can be set in the in-game settings menu (scroll down)

### displayMode (configurable in the game settings menu)

* __1__ - Top left, under the input help display (auto height under key bindings, if active). Not compatible with FS22_InfoMessageHUD (they overlap).  Hidden if large map and key bindings are visible together.
* __2__ - Top right, under the clock.  Not compatible with FS22_EnhancedVehicle new damage / fuel displays
* __3__ - Bottom left, over the map (if shown). Hidden if large map and key bindings are visible together.
* __4__ - Bottom right, over the speedometer.  Special logic added for FS22_EnhancedVehicle HUD (but not the old style damage / fuel)
* __5__ - Custom placement.  Set X/Y origin point in settings XML file as well.

### in-game configurable

    
* __isEnabledShowPlayer__ - show player name for user controlled vehicles, multi-player only
* __isEnabledShowAll__ - always show all vehicles
* __isEnabledShowFillPercent__ - show fill level percentage
* __isEnabledShowFuel__ - show fuel levels
* __isEnabledShowSpeed__ - show vehicle speed
* __isEnabledShowFills__ - show fill level
* __isEnabledShowField__ - show on-field status
* __isEnabledShowFieldNum__ - show field number when on-field
* __isEnabledPadFieldNum__ - Pad field numbers less than 10 with a zero ( F-9 becomes F-09 )
* __isEnabledShowDamage__ - show damage marker if vehicle or attachments are over threshold
* __isEnabledShowCPWaypoints__ - show CoursePlay waypoint status when on a course
* __isEnabledTextBold__ - use bold font

### colors

Fill type levels are color coded from empty (green) to full (red) unless it is a consumable in a consuming vehicle, in which case the scale is flipped.  There is a color blind mode available (use the game setting).  All other colors are defined with a red, green, blue, and alpha component

* __colorAI__ - Color for vehicle name when AI controlled (second highest priority)
* __colorAIMark__ - Color for AI marker
* __colorDamaged__ - Color for the damage marker
* __colorDiesel__ - Color for diesel fuel type
* __colorElectric__ - Color for electric fuel type
* __colorField__ - Color for on field number indicator
* __colorFillType__ - Color for fill type name
* __colorMethane__ - Color for methane fuel type
* __colorNormal__ - Color for vehicle name when running (showAll == false) or not running vehicles (showAll == true)
* __colorRunning__ - Color for vehicle name when running (showAll == true)
* __colorSep__ - Color for separators
* __colorSpeed__ - Color for vehicle speed
* __colorUser__ - Color for vehicle name when user controlled (highest priority)

### text

* __setStringTextDamaged__ - text for damage marker, default "-!!- "
* __setStringTextDiesel__ - text for diesel fuel, default "D:"
* __setStringTextElectric__ - text for electric fuel, default "E:"
* __setStringTextField__ - text for on-field indicator, default "F-"
* __setStringTextFieldNoNum__ - text for on-field indicator when field number is unknown, default "-F-"
* __setStringTextHelper__ - text for AI marker, default "\_AI_ "
* __setStringTextADHelper__ - text for AutoDrive driver, default "\_AD_ "
* __setStringTextCPHelper__ - text for CoursePlayer worker, default "\_CP_ "
* __setStringTextCPWaypoint__ - text for CoursePlayer worker w/ waypoints, default "_CP:"
* __setStringTextMethane__ - text for methane fuel, default "M:"
* __setStringTextSep__ - text for separators, default " | "
* __setValueTextMarginX__ - text margin height, default "15"
* __setValueTextMarginY__ - text margin width, default "10"
* __setValueTextSize__ - text size, default "12"

### dev, debug and extras

* __setValueDamageThreshold__ - Damage threshold, 20% remaining by default
* __setValueTimerFrequency__ - timer update frequency. We probably don't need to query every vehicle on every tick for performance reasons
* __debugMode__ - show debug output.  Mostly garbage.
* __setValueMaxDepth__ - max number of implements attached to implements to index. (i.e. trailer trains - it will get the pulling tractor and 5 trailers by default)

### Custom Order

Not totally supported yet, but in the xml settings you will find __displayOrder__ - the options are

* __SPD__ - speed
* __GAS__ - fuel level
* __DAM__ - damage indicator (if applicable)
* __FLD__ - on-field status
* __AIT__ - AI worker tag
* __USR__ - User worker tag
* __VEH__ - Vehicle name
* __FIL__ - Fill Levels
* __SEP__ - Forced separator

_You must use a single underscore between terms!!_

Default: `SPD_GAS_DAM_FLD_AIT_USR_VEH_FIL`

I still need to re-work how separators work, as they might appear in odd places or not at all when
you re-order, hence the addition of __SEP__ to force one.

## Sample

<p align="center">
  <img width="650" src="https://github.com/jtsage/FS22_simpleInspector/raw/main/readme_Modes.png">
</p>
