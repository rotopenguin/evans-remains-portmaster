#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
GAMEDIR="/$directory/ports/evansremains"

# CD and set logging
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Setup permissions
$ESUDO chmod +xwr "$GAMEDIR/gmloadernext.aarch64"
$ESUDO chmod +xr "$GAMEDIR/tools/splash"
$ESUDO chmod +xr "$GAMEDIR/tools/patchscript"


# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Check if we need to patch the game
if [ ! -f patchlog.txt ] || [ -f "$GAMEDIR/assets/data.win" ]; then
    if [ -f "$GAMEDIR/assets/menues01 - 01.csv" ] ; then
        mv "$GAMEDIR/assets/menues01 - 01.csv" 		"$GAMEDIR/assets/menues01_-_01.csv"
        mv "$GAMEDIR/assets/script01 - 01.csv" 		"$GAMEDIR/assets/script01_-_01.csv"
        mv "$GAMEDIR/assets/backersNames01 - 01.csv" 	"$GAMEDIR/assets/backersNames01_-_01.csv"
        mv "$GAMEDIR/assets/credits01 - 01.csv" 	"$GAMEDIR/assets/credits01_-_01.csv"
    fi
    if [ -f "$GAMEDIR/steam_api.dll" ] ; then
        mv "$GAMEDIR/wrapper/2.2.2.302 - 17.apk" "$GAMEDIR/game.port"
    else
        mv "$GAMEDIR/wrapper/2.3 - 17.apk" "$GAMEDIR/game.port"
    fi
    rm -r "$GAMEDIR/wrapper/"
    if [ -f "$controlfolder/utils/patcher.txt" ]; then
        export PATCHER_FILE="$GAMEDIR/tools/patchscript"
        export PATCHER_GAME="$(basename "${0%.*}")"
        export PATCHER_TIME="2 to 5 minutes"
        export controlfolder
        export ESUDO
        source "$controlfolder/utils/patcher.txt"
        $ESUDO kill -9 $(pidof gptokeyb)
    else
        echo "This port requires the latest version of PortMaster."
    fi
fi

# Display loading splash
if [ -f "$GAMEDIR/patchlog.txt" ]; then
    [ "$CFW_NAME" == "muOS" ] && $ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 1
    $ESUDO "$GAMEDIR/tools/splash" "$GAMEDIR/splash.png" 8000 & 
fi

# Assign gptokeyb and load the game
$GPTOKEYB "gmloadernext.aarch64" -c "portname.gptk" &
pm_platform_helper "$GAMEDIR/gmloadernext.aarch64" >/dev/null
./gmloadernext.aarch64 -c gmloader.json

# Cleanup
pm_finish
