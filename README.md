# Clock Chimes

## Read Me

https://anotherguywithacomputer.com/clock_chimes/


## Introduction

With Clock Chimes, your computer can simulate the hourly chiming of a clock tower.

Clock Chimes is a service for *nix based computers which simulates the chiming of a clock tower. I first experienced this functionality with the menu bar clock found in Mac OS versions 7.5 through version 9.2.2. The menu bar clock included options to play sounds under specific conditions such as:

    * Playing a sound on the hour
    * Playing a sound the number of times as the current hour
    * Playing a sound at 30 minutes after the hour and/or at 15 minutes and/or 45 minutes after the hour

With the introduction of Mac OS 10, these options were removed. 

After a flash of nostalgia and inspiration, I decided to create the missing functionality utilizing a shell script paired with a systemd timer and service.


## System Requirements

Clock Chimes has three dependencies: bash, a scheduler and a media player.

    * bash
      Clock Chimes is a bash script. The bash command interpreter is required to run it.

    * Scheduler
      A scheduler such as a systemd timer or cron is required to activate the script at the necessary times.

      If using systemd, version 242 or higher is required. Version 242 was released in 2019 making it likely most Linux distributions using systemd already meet this requirement. In the unlikely event an older version of systemd is in use, with modification, the clock_chimes service file could be made to work with systemd versions back to version 209 (which was released in 2014). Versions of systemd prior to 209 will not work because the timer functionality was not available. Computers using a version of systemd prior to version 209 will need to use cron as a scheduler.

    * Media Player
      A command line application which plays media files. The default player is cvlc (the command line version of VLC), however, you can change this to an application of your preference.


## Installation & Removal

Installation is performed by running "bash ./install.sh install".
Removal can be performed by running "bash ./install.sh uninstall".


## File manifest

The installer places the following items on your computer:

    * ~/bin/clock_chimes.sh
    * ~/.config/chimes/clock_chimes.config
    * ~/.config/chimes/clock_chimes.config.dist
    * ~/.local/share/sounds/chimes/chime.mp3
    * ~/.local/share/sounds/chimes/chime-final.mp3
    * ~/.local/share/sounds/chimes/Westminister_Half.mp3
    * ~/.local/share/sounds/chimes/Westminister_Hour.mp3
    * ~/.local/share/sounds/chimes/Westminister_Quarter.mp3
    * ~/.local/share/sounds/chimes/Westminister_Three_Quarter.mp3

Installations using systemd will include the following additional files:
    * ~/.config/systemd/user/clock_chimes.service
    * ~/.config/systemd/user/clock_chimes.timer

Installations using cron will include the following additional file:
    * /etc/cron.d/clock_chimes.cron

If uninstalling manually, make sure to run:

    systemctl --user stop clock_chimes.timer
    systemctl --user disable clock_chimes.timer clock_chimes.service
    systemctl --user daemon-reload


## Additional Installation Notes

The installation script defaults to using a systemd timer for scheduling.

The clock_chimes.sh script is written in bash and with minimal calls out to other applications. Under default conditions, the script uses:
    - date (usually at /usr/bin/date)
    - sed (usually at /usr/bin/sed)
    - the chosen media player which by default is cvlc (usually at /usr/bin/cvlc)
    - your PAGER application which typically is less (usually at /usr/bin/less)

The install script is written in bash and calls the following programs which should be present on most computers:
    - echo (typically a shell builtin or /usr/bin/echo)
    - install (usually at /usr/bin/install)
    - mkdir (usually at /usr/bin/mkdir)
    - rm (usually at /usr/bin/rm)
    - sed (usually at /usr/bin/sed)
    - which (usually at /usr/bin/which)

Depending on whether scheduling systemd or cron is used, systemctl or sudo will also be called.
    - systemctl (usually at /usr/bin/systemctl)
    - sudo (usually at /usr/bin/sudo)


## Configuration Information

The information which follows is regarding variables contained within clock_chimes.sh.

   * configFile file path
       Path to configuration file necessary to populate variables.
       Default value is: $HOME/.config/chimes/clock_chimes.config

       A config file can be supplied by specifying the -c option.

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

       Note that when this value is configured, with each run of Clock Chimes, the value will decrement by one until reaching zero. Upon reaching zero, chimes will sound again. The length of time required to reach zero depends on the frequency with which Clock Chimes is activated. If activating hourly, a value of three would mute for three hours. Similarly, if activating every thirty minutes (such as at the beginning of the hour and 30 minutes past), a setting of 3 would mute for 90 minutes.

       Additionally note, if a computer is placed in sleep mode or shutdown while this value is configured, it will resume decrementing with the next run of Clock Chimes. Note that on computers with systemd, upon waking the computer from sleep mode, the script will run once. See notes in Known Issues.txt and Question 15 in Read Me.txt.

   * additionalChimeMinutes array
       Set the array additionalChimeMinutes with a list of minutes when a chime should be played. Accepted values are 00 - 59 and the word "all". Note that at this time, when triggered in this manner, only a simple chime is played.

   * singleChimeSoundFile file path
   * singleChimeFinalSoundFile file path
   * hourSoundFile file path
   * quarterSoundFile file path
   * halfSoundFile file path
   * threequarterSoundFile file path
       Set the variables to point to appropriate sound files. If using a single chime, singleChimeSoundFile should be a single chime while singleChimeFinalSoundFile contains a chime with a longer fade out. If customizing to use only a single sound file, simply set both variables to the same value or set singleChimeFinalSoundFile to:

       singleChimeFinalSoundFile="$singleChimeSoundFile"

   * ringChimeWithHourCount boolean with expected values "yes" or "no"
       Set ringChimeWithHourCount whether the chime should ring a number of times corresponding to the hour of day.

       Example:
           ringChimeWithHourCount="yes"

       Result: At 3:00 p.m. / 15:00, the chime would ring three times

   * player path
       Set player to the path of the media player application which will play
       the sound files. Full path is only necessary if the application does
       not reside within your $PATH.

       Examples:
           player=cvlc
           player=/usr/bin/cvlc

   * player_config string
       Any additional arguments necessary for the player to run.

       Examples:
           player_config="--play-and-exit"
           player_config=""


## Known Issues

See the file Known Issues.txt for information relating to known issues and possible work arounds.


## Questions and Answers

See the file Questions and Answers.txt for answers to common questions.
