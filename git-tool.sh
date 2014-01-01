#!/bin/bash

# git-tool.sh
# Manage multiple git repos quicker and easier than doing it by hand ;)

# Copyright (c)2013 Brian Manning <brian at xaoc dot org>
# License: GPL v2 (see licence blurb at the bottom of the file)

# - Clone the script repo with:
#   - git clone https://github.com/spicyjack/git-tool.git
# - Script also can be obtained from:
#   - https://github.com/spicyjack/git-tool/blob/master/git-tool.sh
# - Get support and more info about this script at:
#   - https://github.com/spicyjack/git-tool/issues

# This is somewhat similar to what the 'repo' (http://tinyurl.com/6pblfg4)
# tool does, sans the messy XML bits needed to make 'repo' work

# what's my name?
SCRIPTNAME=$(basename $0)

# assume everything will go well
EXIT_STATUS=0

# set quiet mode by default, needs to be set prior to the getops call
QUIET=0

# colorize? yes please (1=yes, colorize, 0=no, don't colorize)
COLORIZE=1
# always colorize?  set via --colorize
ALWAYS_COLORIZE=0

# dry-run, i.e. show commands, don't run them? (0 = no, 1 = yes)
DRY_RUN=0
# global variable for measuring how many directories deep we currently are
RECURSION_DEPTH=0

# What paths to exclude from searching; none by default
EXCLUDED_PATHS=""

### OUTPUT COLORIZATION VARIABLES ###
START="\x1b["
END="m"

# text attributes
NONE=0; BOLD=1; NORM=2; BLINK=5; INVERSE=7; CONCEALED=8

# background colors
B_BLK=40; B_RED=41; B_GRN=42; B_YLW=43
B_BLU=44; B_MAG=45; B_CYN=46; B_WHT=47

# foreground colors
F_BLK=30; F_RED=31; F_GRN=32; F_YLW=33
F_BLU=34; F_MAG=35; F_CYN=36; F_WHT=37

# some shortcuts
MSG_FAIL="${BOLD};${F_YLW};${B_RED}"
MSG_WARN="${F_YLW};${B_BLK}"
MSG_DRYRUN="${BOLD};${F_CYN};${B_BLU}"
MSG_OK="${BOLD};${F_WHT};${B_GRN}"
MSG_REMOTE="${F_CYN};${B_BLK}"
MSG_INFO="${BOLD};${F_WHI};${B_BLU}"
MSG_FLUFF="${BOLD};${F_BLU};${B_BLK}"

### FUNCTIONS ###
# wrap text inside of ANSI tags, unless --nocolor is set
colorize () {
    local COLOR="$1"
    local TEXT="$2"

    if [ $COLORIZE -eq 1 ]; then
        COLORIZE_OUT="${COLORIZE_OUT}${START}${COLOR}${END}${TEXT}"
        COLORIZE_OUT="${COLORIZE_OUT}${START};${NONE}${END}"
    else
        COLORIZE_OUT="${COLORIZE_OUT}${TEXT}"
    fi
}

# clear the COLORIZE_OUT variable
colorize_clear () {
    COLORIZE_OUT=""
}

# check the exit status of a sub-process that was run
check_exit_status() {
    local ERROR=$1
    local CMD_RUN="$2"
    local CMD_OUT="$3"

    # check for errors from the script
    if [ $ERROR -ne 0 ] ; then
        if [ $QUIET -eq 0 ]; then
            colorize_clear
            colorize $MSG_FAIL "${CMD_RUN} exited with error: $ERROR"
            $ECHO_CMD $COLORIZE_OUT
            colorize_clear
            colorize $MSG_FAIL "${CMD_RUN} output: "
            $ECHO_CMD $COLORIZE_OUT
            colorize_clear
            colorize $MSG_WARN "${CMD_OUT}"
            $ECHO_CMD $COLORIZE_OUT
            colorize_clear
        fi
        EXIT_STATUS=1
    fi
} # check_exit_status

rungitcmd() {
    local GIT_CMD="$1"
    local GIT_NOTIFY_PATTERN="$2"

    OLD_IFS=$IFS
    IFS=$' \t'
    CMD_OUT=$(eval ${GIT_CMD} 2>&1)
    GIT_CMD_EXIT_STATUS=$?
    check_exit_status $GIT_CMD_EXIT_STATUS "${GIT_CMD}" "${CMD_OUT}"
    if [ $GIT_CMD_EXIT_STATUS -eq 0 ]; then
        if [ $(echo ${CMD_OUT} | grep -c "${GIT_NOTIFY_PATTERN}") -gt 0 ];
        then
            colorize $MSG_REMOTE "${CMD_OUT}"
            $ECHO_CMD $COLORIZE_OUT
        fi
    fi
    IFS=$OLD_IFS

}

# check the status in git directories
repostat() {
    local SHORT_DIR="$1"

    echo "- $SHORT_DIR"
    if [ $COLORIZE -eq 1 ]; then
        GIT_CMD="git -c color.status=always status --short"
    else
        GIT_CMD="git status --short"
    fi
    $GIT_CMD
}

pullorigin() {
    local SHORT_DIR="$1"

    echo "- $SHORT_DIR"
    GIT_CMD="git pull origin"
    GIT_NOTIFY_PATTERN="From"
    rungitcmd "$GIT_CMD" "$GIT_NOTIFY_PATTERN"
}

pullgithub() {
    local SHORT_DIR="$1"

    echo "- $SHORT_DIR"
    GIT_CMD="git pull github"
    GIT_NOTIFY_PATTERN="From"
    rungitcmd "$GIT_CMD" "$GIT_NOTIFY_PATTERN"
}

pullall() {
    local SHORT_DIR="$1"

    echo "- $SHORT_DIR"
    GIT_CMD="git pull --all"
    GIT_NOTIFY_PATTERN="From"
    rungitcmd "$GIT_CMD" "$GIT_NOTIFY_PATTERN"
}

updatechk() {
    local SHORT_DIR="$1"
    local CHECK_DATE="$2"

    echo "- $SHORT_DIR";
    #cd $DIR
    OLD_IFS=$IFS
    IFS=$' \t'
    GIT_CMD="git log --pretty=format:\"%h %ci %an %s\" \
        --after=\"${CHECK_DATE}\" | cut -c -80"
    GIT_NOTIFY_PATTERN="git"
    CMD_OUT=$(eval ${GIT_CMD} 2>&1)
    GIT_CMD_EXIT_STATUS=$?
    check_exit_status $GIT_CMD_EXIT_STATUS "${GIT_CMD}" "${CMD_OUT}"
    if [ $GIT_CMD_EXIT_STATUS -eq 0 ]; then
        if [ $(echo ${CMD_OUT} | wc -c) -gt 1 ];
        then
            colorize $MSG_REMOTE "${CMD_OUT}"
            $ECHO_CMD $COLORIZE_OUT
        fi
    fi
    IFS=$OLD_IFS
}

# check for inbound changes to git directories
inchk() {
    local SHORT_DIR="$1"

    echo "- $SHORT_DIR";
    GIT_CMD="git pull --dry-run"
    GIT_NOTIFY_PATTERN="From"
    rungitcmd "$GIT_CMD" "$GIT_NOTIFY_PATTERN"
}

# check for outbound changes in git directories
outchk() {
    local SHORT_DIR="$1"

    echo "- $SHORT_DIR";
    GIT_CMD="git push --dry-run"
    GIT_NOTIFY_PATTERN="To"
    rungitcmd "$GIT_CMD" "$GIT_NOTIFY_PATTERN"
}

# check for outbound changes in git directories
refchk() {
    local SHORT_DIR="$1"

    echo "- $SHORT_DIR";
    if [ $COLORIZE -eq 1 ]; then
        GIT_CMD="git -c color.status=always status"
    else
        GIT_CMD="git status"
    fi
    GIT_NOTIFY_PATTERN="Your branch is ahead"
    rungitcmd "$GIT_CMD" "$GIT_NOTIFY_PATTERN"
}

# recurse a path, looking for directories to either run git commands in, or to
# enter to look for more directories
recurse_path() {
    local RECURSE_PATH="$1"
    local GIT_TOOL_CMD="$2"
    local GIT_UPDATE_DATE="$3"
    # use find to find directories, use \0 as the delimiter in the output
    find "${RECURSE_PATH}" -maxdepth 1 -type d -name "[a-zA-Z0-9_]*" -print0 \
        | sort -z | while IFS= read -d $'\0' CURR_PATH;
    do
        colorize_clear
        # skip the original path
        if [ "x${CURR_PATH}" = "x${RECURSE_PATH}" ]; then
            continue
        fi
        # check to see if we skip this directory
        if [ -n "$EXCLUDED_PATHS" -a $(echo ${CURR_PATH} \
            | egrep -c "$EXCLUDED_PATHS") -gt 0 ];
        then
            if [ $QUIET -eq 0 ]; then
                colorize "$MSG_FLUFF" "--> Skipping ${CURR_PATH} <--"
                $ECHO_CMD $COLORIZE_OUT
            fi
            continue
        fi
        # is CURR_PATH a *.git directory?
        if [ $(echo "${CURR_PATH}" | grep -c "\.git$") -gt 0 ]; then
            # yes, run the specified git command
            START_PATH="$PWD"
            cd "${CURR_PATH}"
            #colorize $MSG_FLUFF "${RECURSION_DEPTH}:${CURR_PATH}"
            #colorize $MSG_FLUFF ": Running 'git ${GIT_TOOL_CMD}'"
            #$ECHO_CMD $COLORIZE_OUT
            SHORT_DIR=$(echo "${CURR_PATH}" | sed "s!${REPO_PATH}!!g; s!^/!!;")
            # for 'updatechk'
            if [ $GIT_TOOL_CMD = 'updatechk' ]; then
                if [ -z $GIT_UPDATE_DATE ]; then
                    echo "ERROR: need a date to check;"
                    echo "date format is YYYY-MM-DD"
                    exit 1
                fi
                if [ $DRY_RUN -gt 0 ]; then
                    echo "dry-run: ${GIT_TOOL_CMD}/${GIT_UPDATE_DATE}"
                    echo "dry-run: Running command in '${SHORT_DIR}'"
                else
                    $GIT_TOOL_CMD "${SHORT_DIR}" "${GIT_UPDATE_DATE}"
                fi
            else
                # for all other commands
                if [ $DRY_RUN -gt 0 ]; then
                    echo "dry-run: Running ${GIT_TOOL_CMD} in '${SHORT_DIR}'"
                else
                    $GIT_TOOL_CMD "${SHORT_DIR}"
                fi
            fi
            cd "$START_PATH"
        else
            # no, found another directory, recurse into it
            # bump the counter so it can be used for formatting and the like
            RECURSION_DEPTH=$(($RECURSION_DEPTH + 1))
            #colorize $MSG_INFO "Recursing into: ${CURR_PATH}"
            #$ECHO_CMD $COLORIZE_OUT
            recurse_path "${CURR_PATH}" "${GIT_TOOL_CMD}"
            # take the counter back to where it started
            RECURSION_DEPTH=$(($RECURSION_DEPTH - 1))
        fi
    done
} # recurse_path

show_examples() {
# show script usage examples
cat <<-EOE

==== ${SCRIPTNAME} Examples ====

  # get the status of all *.git dirs in /path/to/src/tree,
  # exclude /path/to/tree/dirA, /path/to/src/tree/dirB
  ${SCRIPTNAME} --path=/path/to/src/tree --exclude="dirA|dirB" repostat

  # check to see if you've forgotten to push to a remote repo
  # does not need to access the network, so faster than 'git push --dry-run'
  ${SCRIPTNAME} --path=/path/to/src/tree --exclude="dirA|dirB" refchk

  # check to see if you need to pull from remote repos to local repos
  # ** needs network access **
  ${SCRIPTNAME} --path=/path/to/src/tree --exclude="dirA|dirB" inchk

  # check to see if you need to push to remote repos from local repos
  # ** needs network access **
  ${SCRIPTNAME} --path=/path/to/src/tree --exclude="dirA|dirB" outchk

EOE

}

show_help() {
# show script options
cat <<-EOH

${SCRIPTNAME} [options] <command>

    GENERAL SCRIPT OPTIONS
    -h|--help       Displays this help message
    -e|--examples   Show examples of script usage
    -q|--quiet      No script output (unless an error occurs)
    -n|--dry-run    Explain what will be done, don't actually do it
    -c|--colorize   Always colorize output, ignore '-t' test

    OPTIONS FOR DIRECTORY PATHS
    -p|--path       Starting path for searching for Git repos
    -x|--exclude    Exclude these paths from the search

    SCRIPT COMMANDS
    stat            Run 'git status --short' in all repos found
    pullall         Run 'git pull' in all repos found
    refchk          Run 'git status', can show files not synced with remote
    outchk          Run 'git push --dry-run'; shows commits needing pushing
    inchk           Run 'git pull --dry-run'; shows commits needing pulling
    updatechk       Shows all repos that have been updated since 'YYYY-MM-DD'

NOTES:
- Long switches (GNU extension) do not work with BSD 'getopt'
- Colorization is disabled when script outputs to pipe (-t set on filehandle)

EOH

}

### SCRIPT SETUP ###
# BSD's getopt is simpler than the GNU getopt; we need to detect it
if [ -x /usr/bin/uname ]; then
    OSDETECT=$(/usr/bin/uname -s)
elif [ -x /bin/uname ]; then
    OSDETECT=$(/bin/uname -s)
else
    echo "ERROR: can't run 'uname -s' command to determine system type"
    exit 1
fi

if [ $OSDETECT = "Darwin" ]; then
    ECHO_CMD="builtin echo"
elif [ $OSDETECT = "Linux" ]; then
    ECHO_CMD="builtin echo -e"
else
    ECHO_CMD="echo"
fi

# these paths cover a majority of my test machines
for GETOPT_CHECK in "/opt/local/bin/getopt" "/usr/local/bin/getopt" \
    "/usr/bin/getopt";
do
    if [ -x "${GETOPT_CHECK}" ]; then
        GETOPT_BIN=$GETOPT_CHECK
        break
    fi
done

# did we find an actual binary out of the list above?
if [ -z "${GETOPT_BIN}" ]; then
    echo "ERROR: getopt binary not found; exiting...."
    exit 1
fi

# Use short options if we're using Darwin's getopt
if [ $OSDETECT = "Darwin" -a $GETOPT_BIN = "/usr/bin/getopt" ]; then
    GETOPT_TEMP=$(${GETOPT_BIN} heqncp:x: $*)
else
# Use short and long options with GNU's getopt
    GETOPT_TEMP=$(${GETOPT_BIN} -o heqncp:x: \
        --long help,examples,quiet,dry-run,colorize,path:,exclude: \
        -n "${SCRIPTNAME}" -- "$@")
fi

# if getopts exited with an error code, then exit the script
#if [ $? -ne 0 -o $# -eq 0 ] ; then
if [ $? != 0 ] ; then
    echo "Run '${SCRIPTNAME} --help' to see script options" >&2
    if [ $OSDETECT = "Darwin" -a $GETOPT_BIN = "/usr/bin/getopt" ]; then
        echo "WARNING: 'Darwin' OS and system '/usr/bin/getopt' detected;" >&2
        echo "WARNING: Only short options (-h, -e, etc.) will work" >&2
        echo "WARNING: with system '/usr/bin/getopt' under 'Darwin' OS" >&2
    fi
    exit 1
fi

# Note the quotes around `$GETOPT_TEMP': they are essential!
# read in the $GETOPT_TEMP variable
eval set -- "$GETOPT_TEMP"

# read in command line options and set appropriate environment variables
# if you change the below switches to something else, make sure you change the
# getopts call(s) above
while true ; do
    case "$1" in
        -h|--help) # show the script options
            show_help
            exit 0;;
        -e|--examples)
            show_examples
            exit 0;;
        # Don't output anything (unless there's an error)
        -q|--quiet)
            QUIET=1
            shift;;
        # Don't use color in the output
        -c|--colorize)
            ALWAYS_COLORIZE=1
            shift;;
        # Explain what will be done, don't actually do
        -n|--dry-run|--explain)
            DRY_RUN=1
            shift;;
        # Path to the directory with one or more git repos
        -p|--path|--dir)
            REPO_PATH=$2;
            shift 2;;
        # Paths to exclude
        -x|--exclude)
            EXCLUDED_PATHS=$2;
            shift 2;;
        # everything else
        --)
            shift;
            break;;
        # we shouldn't get here; die gracefully
        *)
            echo "ERROR: unknown option '$1'" >&2
            echo "ERROR: use --help to see all script options" >&2
            exit 1
            ;;
    esac
done

### SCRIPT MAIN LOOP ###
# if we're outputting to a pipe, don't colorize, unless ALWAYS_COLORIZE is set
if [ ! -t 1 ]; then
    if [ $ALWAYS_COLORIZE -eq 0 ]; then
        COLORIZE=0
    fi
fi

# do some error checking; we need at a minimum '--path' and a <command> to run
if [ -z $REPO_PATH ]; then
    colorize "$MSG_FAIL" "ERROR: missing repo path as --path"
    $ECHO_CMD $COLORIZE_OUT
    exit 1
fi

# Tell the rest of the script what command the user asked for
if [ $# -gt 1 ]; then
    # the 'updatechk' command takes an argument, all other commands just need
    # the name of the command
    GIT_TOOL_CMD=$1
    GIT_UPDATE_DATE=$2
else
    GIT_TOOL_CMD=$1
fi
#GIT_TOOL_CMD="$*"
if [ -z $GIT_TOOL_CMD ]; then
    colorize "$MSG_FAIL" "ERROR: missing 'command' to run"
    $ECHO_CMD $COLORIZE_OUT
    colorize_clear
    echo " - Use ${SCRIPTNAME} --help for script options"
    echo " - Use ${SCRIPTNAME} --examples for usage examples"
    exit 1
fi

colorize_clear
if [ $QUIET -eq 0 ]; then
    colorize "$MSG_FLUFF" "=-=-=-=-=-=-=-= "
    colorize "$MSG_INFO" "$SCRIPTNAME"
    colorize "$MSG_FLUFF" " =-=-=-=-=-=-=-="
    $ECHO_CMD $COLORIZE_OUT
    colorize_clear
    colorize "$MSG_FLUFF" "--- Repo path: "
    colorize "$MSG_INFO" "${REPO_PATH}"
    colorize "$MSG_FLUFF" " ---"
    $ECHO_CMD $COLORIZE_OUT
    colorize_clear
fi

recurse_path "$REPO_PATH" "$GIT_TOOL_CMD" "$GIT_UPDATE_DATE"

# exit cleanly if we reach here
#if [ $QUIET -eq 0 ]; then
#    echo "Hit <ENTER> to exit"
#    read ANSWER
#fi

exit ${EXIT_STATUS}

# ### begin license blurb ###
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; version 2 dated June, 1991.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program;  if not, write to the Free Software
#   Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

# vi: set filetype=sh shiftwidth=4 tabstop=4
# end of line
