#!/usr/bin/env bash
# clock_chimes.sh
# Clock Chimes
#
# INSTALLATION
#   The recommended installation method is to run the install script.
#     ./install.sh
#
#
# USAGE
#   Configure a systemd timer or cron job to trigger clock_chimes.sh. The
#   script will determine whether and how many times to play the chime sound.
#   The systemd service file or cron job should be pointed to the
#   clock_chimes.sh script. No arguments are required.
#
# To display help, run:
#   ./clock_chimes.sh -h
#
# To display configuration information, run:
#   ./clock_chimes.sh -c
#
# To load a specific configuration file, run:
#   ./clock_chimes.sh -l /path/to/clock_chimes.config
#
# To test the configuration, run:
#   ./clock_chimes.sh -t
#
# ----------------------------------------------------------------------------
# Configuration
# All configuration for Clock Chimes should be done in a configuration file.
#
# Multiple configuration files can be created and loaded as needed.
#
# Clock Chimes reads an external config file to populate the variables below.
# Changes to the variables below will be overwritten when the config file is
# loaded.
#
# Note: While it is possible to configure the variables below such that a
# config file is not needed, certain functionality such as muteNext will not
# work.
# ----------------------------------------------------------------------------
configFile="$HOME/.config/chimes/clock_chimes.config"
useSimpleChime=""
quietTime=()
muted=""
muteNext=""
muteScript=
additionalChimeMinutes=()
singleChimeSoundFile=""
singleChimeFinalSoundFile=""
hourSoundFile=""
quarterSoundFile=""
halfSoundFile=""
threequarterSoundFile=""
ringChimeWithHourCount=""
player=""
player_config=""
# ----------------------------------------------------------------------------
# Determine whether we are using a default config file or loading a new one.
runtimeOptions=($@)
index=-1
for ((n = 0; n < "${#runtimeOptions[@]}"; n++)); do
  if [[ "${runtimeOptions[$n]}" == "-l" ]]; then
    index=$n
  fi
done

if [ "$index" -eq -1 ]; then
  # No config file specified, use default.
  # Begin nested if statement
  if [ -e "$configFile" ]; then
    # echo "Loading configuration file: $configFile"
    . "$configFile"
  else
    echo "Configuration file $configFile could not be located."
    exit
  fi
  # End nested if statement
elif [ "$index" -gt -1 ]; then
  # A config file was specified
  configFile_tmp="${runtimeOptions[$index + 1]}"
  # Begin nested if statement
  if [ -z "$configFile_tmp" ]; then
    echo "A path to a configuration file must be specified when specifying the -l option."
    echo "Example: $0 -l $HOME/.config/chimes/clock_chimes.config"
    exit
  elif [ -e "$configFile_tmp" ]; then
    configFile="$configFile_tmp"
    . "$configFile"
    unset runtimeOptions[$index] runtimeOptions[$index+1]
  else
    echo "Configuration file $configFile_tmp could not be located."
    exit
  fi
  # End nested if statement
fi

# ----------------------------------------------------------------------------
# Main Program execution begins here
# Inputs: None
# Work: Determine hours and minutes and whether program execution should
# continue. Pass to ringChime or ringChimeHours function based upon quietTime
# and ringChimeWithHourCount configuration.
# Output: None
# ----------------------------------------------------------------------------
function main() {
  hour=$(date +%H)
  minutes=$(date +%M)
  while getopts ":chl:m:n:rt-" programFunction; do
    case "$programFunction" in
    "h" | help) # help
      displayHelp
      exit
      ;;
    "c" | config) # configuration
      displayConfig
      exit
      ;;
    "m") # mute
      if [ "$OPTARG" == "yes" ]; then
        mutedCurrent=$muted
        sed -i -e "s/muted=\"$mutedCurrent\"/muted=\"yes\"/" "$configFile"
        echo "Configured muted to yes in $configFile."
      elif [ "$OPTARG" == "no" ]; then
        mutedCurrent=$muted
        sed -i -e "s/muted=\"$mutedCurrent\"/muted=\"no\"/" "$configFile"
        echo "Configured muted to no in $configFile."
      else
        echo -e "Error: An invalid value was supplied. To change the muted setting, run one of the following commands:\n"
        echo -e "\tMute Clock Chimes: $0 -m yes\n\tUnmute Clock Chimes: $0 -m no"
      fi
      exit
      ;;
    "n") # muteNext
      if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
        muteNextCurrent=$muteNext
        muteNext=$OPTARG
        sed -i -e "s/muteNext=$muteNextCurrent/muteNext=$OPTARG/" "$configFile"
        if [ "$muteNext" == 1 ]; then
          echo "Configured Clock Chimes to mute the next activation using configuration $configFile."
        elif [ "$muteNext" -gt 1 ]; then
          echo "Configured Clock Chimes to mute the next $muteNext activations in $configFile."
        elif [ "$muteNext" == 0 ]; then
          echo "Configured Clock Chimes to play with the next activation using configuration $configFile."
        fi
      else
        echo -e "Error: An invalid value was supplied. To change the muteNext setting, run a command such as:\n\n\t$0 -n 1"
      fi
      exit
      ;;
    "r") # ring the chime once
      checkForSilence
      ringChime 1
      exit
      ;;
    "t") # test config
      echo "Press control z on your keyboard to abort testing."
      sleep 1
      testConfig
      exit
      ;;
    \?)
      echo "Option -$OPTARG not found. Run '$0 -h' to find available options and usage information."
      exit
      ;;
    :)
      # Begin embedded case statement
      case "$OPTARG" in
      m)
        echo -e "Error: You must specify either 'yes' or 'no' when changing the muted setting. To change the muted setting, run one of the following commands:\n"
        echo -e "\tMute Clock Chimes: $0 -m yes\n\tUnmute Clock Chimes: $0 -m no"
        ;;
      n)
        echo -e "Error: An invalid value was supplied. To change the muteNext setting, run a command such as:\n\n\t$0 -n 1"
        ;;
      *)
        echo "Option -$OPTARG requires an arguement."
        ;;
      esac
      # End embedded case statement
      exit
      ;;
    esac
  done

  checkForSilence

  # Take action based upon the minutes value.
  case "$minutes" in
  00)
    if [ "$useSimpleChime" == "no" ]; then
      playFile "$hourSoundFile"
      ringChimeHours
    else
      ringChimeHours
    fi
    ;;
  15)
    if [ "$useSimpleChime" == "no" ]; then
      playFile "$quarterSoundFile"
    else
      ringChime 1
    fi
    ;;
  30)
    if [ "$useSimpleChime" == "no" ]; then
      playFile "$halfSoundFile"
    else
      ringChime 1
    fi
    ;;
  45)
    if [ "$useSimpleChime" == "no" ]; then
      playFile "$threequarterSoundFile"
    else
      ringChime 1
    fi
    ;;
  *)
    # Search additionalChimeMinutes array and determine if a chime should occur
    for ((k = 0; k < "${#additionalChimeMinutes[@]}"; k++)); do
      if [ "${additionalChimeMinutes[$k]}" == "all" ]; then
        ringChime 1
      elif [ "$minutes" -eq "${additionalChimeMinutes[$k]}" ]; then
        ringChime 1
      fi
    done
    ;;
  esac
}
# ----------------------------------------------------------------------------
# Function checkForSilence
# Inputs:   None
# Work:     Determine whether any mute mechanism is active and exit if sound
#           should not be played.
# Output:   None
# ----------------------------------------------------------------------------
function checkForSilence() {
  # Determine if muteNext is presently used
  if [ "$muteNext" -ne 0 ]; then
    muteNextCurrent=$muteNext
    ((muteNext--))
    sed -i -e "s/muteNext=$muteNextCurrent/muteNext=$muteNext/" "$configFile"
    exit
  fi
  # Check mute status
  if [ "$muted" == "yes" ]; then
    exit
  fi

  if [ "$muteScript" == "yes" ]; then
    exit
  fi

  # Determine if we are operating during quiet time and exit $hour is in
  # array quietTime.
  for ((i = 0; i < "${#quietTime[@]}"; i++)); do
    if [ "$hour" -eq "${quietTime[$i]}" ]; then
      exit
    fi
  done
}

# ----------------------------------------------------------------------------
# Function ringChimeHours
# Inputs:   Uses $hour defined in main()
# Work:     Determine the number of chimes to be played based on time of day.
# Output:   Sound file is played
# ----------------------------------------------------------------------------
function ringChimeHours() {
  if [ "$ringChimeWithHourCount" == "yes" ]; then
    case "$hour" in
    00 | 12 | 24) ringChime 12 ;;
    01 | 13) ringChime 1 ;;
    02 | 14) ringChime 2 ;;
    03 | 15) ringChime 3 ;;
    04 | 16) ringChime 4 ;;
    05 | 17) ringChime 5 ;;
    06 | 18) ringChime 6 ;;
    07 | 19) ringChime 7 ;;
    08 | 20) ringChime 8 ;;
    09 | 21) ringChime 9 ;;
    10 | 22) ringChime 10 ;;
    11 | 23) ringChime 11 ;;
    esac
  else
    ringChime 1
  fi
}

# ----------------------------------------------------------------------------
# Function ringChime
# Inputs:   $1 = number of chimes which need to be played
# Work:     Play $singleChimeSoundFile one or more times based on input from
#           $1. Finish by playing $singleChimeFinalSoundFile which has a longer
#           fade out.
# Output:   Sound file is played
# ----------------------------------------------------------------------------
function ringChime() {
  for ((j = 1; j <= "$1"; j++)); do
    if [ "$j" -eq "$1" ]; then
      $player $player_config "$singleChimeFinalSoundFile" >/dev/null 2>&1
    else
      $player $player_config "$singleChimeSoundFile" >/dev/null 2>&1
    fi
  done
}

# ----------------------------------------------------------------------------
# Function playFile
# Inputs:   $1 = path to file which needs to be played
# Work:     Play specified sound file.
# Output:   Sound file is played
# ----------------------------------------------------------------------------
function playFile() {
  $player $player_config "$1" >/dev/null 2>&1
}

# ----------------------------------------------------------------------------
# Function displayConfig
# Inputs:   None
# Work:     None
# Output:   Display variable configuration
# ----------------------------------------------------------------------------
function displayConfig() {
  echo -e "\n\033[1mClock Chimes Configuration\n\033[0m"
  echo -e "Current time:\t\t\t$hour:$minutes"
  echo -e "configFile:\t\t\t$configFile"
  echo -e "quietTime Hours:\t\t${quietTime[@]}"
  echo -e "muted:\t\t\t\t$muted"
  echo -e "muteNext:\t\t\t$muteNext"
  echo -e "additionalChimeMinutes:\t\t${additionalChimeMinutes[@]}"
  echo -e "useSimpleChime:\t\t\t$useSimpleChime"
  echo -e "ringChimeWithHourCount:\t\t$ringChimeWithHourCount"

  echo -e "\n\033[1mSound File Configuration\n\033[0m"
  echo -e "singleChimeSoundFile:\t\t$singleChimeSoundFile"
  echo -e "singleChimeFinalSoundFile:\t$singleChimeFinalSoundFile"
  echo -e "hourSoundFile:\t\t\t$hourSoundFile"
  echo -e "quarterSoundFile:\t\t$quarterSoundFile"
  echo -e "halfSoundFile:\t\t\t$halfSoundFile"
  echo -e "threequarterSoundFile:\t\t$threequarterSoundFile"

  echo -e "\n\n\033[1mMedia Player Configuration\n\033[0m"
  echo -e "player:\t\t\t\t$player"
  echo -e "player configuration:\t\t$player_config"
  which $player >/dev/null 2>&1
  case "$?" in
  0) echo -e "player found:\t\t\tyes" ;;
  1) echo -e "player found:\t\t\tno" ;;
  esac
  echo -e "\n\033[1mPATH variable output\033[0m\n"
  pathDirs=($(echo $PATH | sed 's/:/ /g'))
  for ((z = 0; z < "${#pathDirs[@]}"; z++)); do
    echo -e "\t\t\t\t${pathDirs[$z]}"
  done

}

# ----------------------------------------------------------------------------
# Function testConfig
# Inputs:   None
# Work:     Tests whether player application exists and play sound files
# Output:   Sound files played
# ----------------------------------------------------------------------------
function testConfig() {
  echo "Player application: $player"
  which $player >/dev/null 2>&1
  case "$?" in
  1) echo "The sound player $player was not found." ;;
  0)
    echo "Play singleChimeSoundFile" && $player $player_config $singleChimeSoundFile
    sleep 2
    echo "Play singleChimeFinalSoundFile" && $player $player_config $singleChimeFinalSoundFile
    sleep 2
    echo "Play hourSoundFile" && $player $player_config $hourSoundFile
    sleep 2
    echo "Play Chime with Hour Count. Hour count is: $hour" && ringChimeHours
    sleep 2
    echo "Play all other sound files" && $player $player_config $quarterSoundFile $halfSoundFile $threequarterSoundFile
    echo "Testing has completed"
    exit
    ;;
  esac
}

# ----------------------------------------------------------------------------
# Function displayHelp
# Inputs:   None
# Work:     None
# Output:   Display Help Menu
# ----------------------------------------------------------------------------
function displayHelp() {
  if [ -z $PAGER ]; then
    PAGER="less -IR"
  fi
  cat <<_displayHelp_ | $PAGER
$(echo -e "\e[1mClock Chimes Help\e[0m")

   To run the default configuration:
     $0

   To display help, run:
     $0 -h

   To display configuration information, run:
     $0 -c

   To load an alternate configuration, run:
     $0 -l [file path]

   To ring the chime once, run:
     $0 -r

   To test the configuration, run:
     $0 -t

   To activate the mute function, run:
     $0 -m yes

   To deactivate the mute function, run:
     $0 -m no

   To set the mutenext function, run:
     $0 -n [number]

     Example:
       $0 -n 1

$(echo -e "\e[4mINSTALLATION\e[0m")
The recommended installation method is to run the install script.
     ./install.sh

The installer will automatically place the script, sound and config files to their appropriate locations. If systemd is detected, the installer will create and register the necessary timer and service files. If systemd is not detected, a cron script will be placed on your computer instead.


$(echo -e "\e[4mUSAGE\e[0m")
The installer handles all necessary configuration. After the installer completes, no further action is required. With the default configuration, the chimes will sound at the begining of each hour and thirty minutes past the hour.

Activation occurs when a systemd timer or cron job triggers clock_chimes.sh. The clock_chimes.sh script will determine whether and how many times to play the chime sound. The systemd service file or cron job should be pointed to the clock_chimes.sh script, typically stored in ~/bin or ~/.local/bin. No arguments are required.


$(echo -e "\e[4mCONFIGURATION\e[0m")
Several variables control how Clock Chimes behaves. These variables can be altered with a config file. The default config file is at "$HOME/.config/chimes/clock_chimes.config".

* configFile file path
Path to configuration file necessary to populate variables.
Default value is: \$HOME/.config/chimes/clock_chimes.config

* useSimpleChime: Boolean with expected values "yes" or "no"
Configures whether to use a simple chime tone or melodies. When configured to yes, a simple chime is played. When configured to no, a melody is played. The default bundled melodies are the Westminster chimes melodies.

* quietTime array
Set the array quietTime with a list of hours when chimes should not play. The quietTime array requires input values in 24 hour time meaning 1 p.m. = 13, 2 p.m. = 14, 11 p.m. = 23. Midnight/12 a.m. is 0.

       Example:
           quietTime=(22 23 0 1 2 3 4 5)

       Result: Chimes will not ring between 10 p.m. and 5 a.m.

* muted: Boolean with expected values "yes" or "no"
Configures whether chimes should play or not. This behaves similarly to quietTime but is not time dependent.

* muteNext integer
When set, this number of future invocations of Clock Chimes will automatically be muted. This behaves similarly to muted and quietTime but is independent of both.

Note that when this value is configured, with each run of Clock Chimes, the value will decrement by one until reaching zero. Upon reaching zero, chimes will sound again. The length of time required to reach zero depends on the frequency with which Clock Chimes is activated. If activating hourly, a value of three would mute for three hours. Similarly, if activating every thirty minutes (such as at the begining of the hour and 30 minutes past), a setting of 3 would mute for 90 minutes.

Additionally note, if a computer is placed in sleep mode or shutdown while this value is configured, it will resume decrementing with the next run of Clock Chimes. Note that on computers with systemd, upon waking the computer from sleep mode, the script will run once. See notes in Known Issues.txt and Question 15 in Questions and Answers.txt.

* additionalChimeMinutes array
Set the array additionalChimeMinutes with a list of minutes when a chime should be played. Accepted values are 00 through 59 and the word "all". Note that at this time, when triggered in this manner, only a simple chime is played.

* singleChimeSoundFile file path
* singleChimeFinalSoundFile file path
* hourSoundFile file path
* quarterSoundFile file path
* halfSoundFile file path
* threequarterSoundFile path
Set the variables to point to appropriate sound files. If using a single chime, singleChimeSoundFile should be a single chime while singleChimeFinalSoundFile contains a chime with a longer fade out. If customizing to use only a single sound file, simply set both variables to the same value or set singleChimeFinalSoundFile to:

       singleChimeFinalSoundFile="\$singleChimeSoundFile"

* ringChimeWithHourCount boolean with expected values "yes" or "no"
Set ringChimeWithHourCount whether the chime should ring a number of times corresponding to the hour of day.

       Example:
           ringChimeWithHourCount="yes"

       Result: At 3:00 p.m. / 15:00, the chime would ring three times

* player path
Set player to the path of the media player application which will play the sound files. Full path is only necessary if the application does not reside within your \$PATH.

       Examples:
           player=cvlc
           player=/usr/bin/cvlc

* player_config string
Any additional arguments necessary for the player to run.

       Examples:
           player_config="--play-and-exit"
           player_config=""

_displayHelp_
}
# ----------------------------------------------------------------------------

main "${runtimeOptions[@]}"
