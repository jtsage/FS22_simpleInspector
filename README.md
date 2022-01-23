# FS22_SimpleInspector

<p align="left">
  <img src="https://github.com/jtsage/FS22_simpleInspector/raw/main/modIcon.png">
</p>

Spiritual ripoff of VehicleInspector - pared down to what I need/want

## Features

* Display all (enterable) vehicles or just those with the motor running
* Show speed for vehicles
* Show is the vehicle is AI or user controlled
* Show fill level of the vehicle

## Options

All options are set via a xml file in modSettings - you can change colors, mode, and which vehicles are displayed

### displayMode

* __1__ - Top left, under the input help display (auto height under key bindings, if active). Not compatible with FS22_InfoMessageHUD (they overlap).  Hidden if large map and key bindings are visible together.
* __2__ - Top right, under the clock.  Not compatible with FS22_EnhancedVehicle new damage / fuel displays
* __3__ - Bottom left, over the map (if shown). Hidden if large map and key bindings are visible together.
* __4__ - Bottom right, over the speedometer.  Special logic added for FS22_EnhancedVehicle HUD (but not the old style damage / fuel)
* __5__ - Custom placement.  Set X/Y origin point in settings XML file as well.

### general

* __showAll__ - always show all vehicles (default no)
* __showDamage__ - show damage marker if vehicle or attachments are over threshold.
* __damageThreshold__ - damage threshold (default 0.2 == 80% damaged)
* __showField__ - show on-field status (default yes)
* __showFieldNum__ - show field number when on-field (default yes - turn off for maps like NML)
* __showFillPercent__ - show fill level percentage (default yes)
* __showFills__ - show fill levels (default yes)
* __showFuel__ - show fuel levels (default yes)
* __showSpeed__ - show vehicle speed (default yes)

### colors

Fill type levels are color coded from empty (green) to full (red) unless it is a consumable in a consuming vehicle, in which case the scale is flipped.  There is a color blind mode available (use the game setting)

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

* __textDamaged__ - text for damage marker, default "-!!- "
* __textDiesel__ - text for diesel fuel, default "D:"
* __textElectric__ - text for electric fuel, default "E:"
* __textField__ - text for on-field indicator, default "F-"
* __textFieldNoNum__ - text for on-field indicator when field number is unknown, default "-F-"
* __textHelper__ - text for AI marker, default "_AI_ "
* __textMethane__ - text for methane fuel, default "M:"
* __textSep__ - text for separators, default " | "
* __textMarginX__ - text margin height, default "15"
* __textMarginY__ - text margin width, default "10"
* __textSize__ - text size, default "12"

### dev and debug

* __timerFrequency__ - timer update frequency. We probably don't need to query every vehicle on every tick for performance reasons
* __debugMode__ - show debug output.  Mostly garbage.
* __maxDepth__ - max number of implements attached to implements to index. (i.e. trailer trains - it will get the pulling tractor and 5 trailers by default)

## Sample

<p align="center">
  <img width="650" src="https://github.com/jtsage/FS22_simpleInspector/raw/main/readme_Modes.png">
</p>
