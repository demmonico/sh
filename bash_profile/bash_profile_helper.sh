#!/usr/bin/env bash
#
# Bash profile helper
#
# @author: demmonico <demmonico@gmail.com> <https://github.com/demmonico>
#
# @use
# - put this file near with your .bashrc or .bash_profile file
# - add to the last one following line: source ./.bash_profile_helper.sh

COLOR_RED='\033[0;91m'
COLOR_YELLOW='\033[1;93m'
COLOR_DEFAULT='\033[00m'

setPrompt () {
    local LAST_EXIT_CODE=$? # Must come first!

    local TC_RED="\[${COLOR_RED}\]"
    local TC_GREEN='\[\033[0;92m\]'
    local TC_YELLOW="\[${COLOR_YELLOW}\]"
    local TC_CYAN='\[\033[0;96m\]'
    local TC="\[${COLOR_DEFAULT}\]"

    local CHECKMARK='\342\234\223'
    local XMARK='\342\234\227'

    # exit status for the last command
    if [[ ${LAST_EXIT_CODE} == 0 ]]; then
        PS1="${TC_GREEN}${CHECKMARK}${TC} "
    else
        PS1="${TC_RED}${XMARK} (${LAST_EXIT_CODE})${TC} "
    fi

    # username + hostname
    [[ $EUID == 0 ]] && HOSTCOLOR=${TC_RED} || HOSTCOLOR=${TC_GREEN}
    PS1+="${HOSTCOLOR}\u@\h${TC} "

    # working directory
    PS1+="${TC_YELLOW}\w${TC} "

    # git branch if exists
    if git branch &>/dev/null; then
        local GIT_BRANCH=$(git branch 2>/dev/null | grep \* |  cut -d " " -f 2)
        PS1+="${TC_CYAN}${GIT_BRANCH}${TC} "
    fi

    # promt symbol
    [[ $EUID == 0 ]] && PS1+='# ' || PS1+='$ '
}

printStatSystem() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        system_profiler SPHardwareDataType | awk '
            /Model Identifier/ {MODEL = $3}
            /Serial Number/ {SN = $4}
            /Hardware UUID/ {UUID = $3}
            END {
                printf ">>> Model %s, UUID %s, SN %s\n", MODEL, UUID, SN
            }'
    fi

    # TODO add other OS
}

printStatCPU() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        system_profiler SPHardwareDataType | awk '
            /Processor Name/ {NAME = substr($0, index($0,$3))}
            /Total Number of Cores/ {CORES = $5}
            /Processor Speed/ {FREQ = substr($0, index($0,$3))}
            END {
                printf ">>> CPU %s %sx%s\n", NAME, CORES, FREQ
            }'
    fi

    # TODO add other OS
}

printStatMemory() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        /usr/bin/vm_stat | sed 's/\.//' | awk '
            /page size of/ {BLOCK_SIZE = $8}
            /free/ {FREE_BLOCKS = $3}
            /Pages active/ {ACTIVE_BLOCKS = $3}
            /Pages inactive/ {INACTIVE_BLOCKS = $3}
            /speculative/ {SPECULATIVE_BLOCKS = $3}
            /wired/ {WIRED_BLOCKS = $4}
            /purgeable/ {PURGEABLE_BLOCKS = $3}
            /occupied by compressor/ {COMPRESSED_BLOCKS = $5}
            /backed/ {CACHED_FILES_BLOCKS = $3}
            /throttled/ {THROTTLED_BLOCKS = $3}
            /Swapouts/ {SWAPOUTS_BLOCKS = $2}
            END {
                WIRED=(( WIRED_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                COMPRESSED=(( COMPRESSED_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                APP=(( (ACTIVE_BLOCKS + INACTIVE_BLOCKS + SPECULATIVE_BLOCKS + THROTTLED_BLOCKS + PURGEABLE_BLOCKS) * BLOCK_SIZE / 1024 / 1024 - WIRED ))
                USED=(( APP + WIRED + COMPRESSED ))
                CACHED_FILES=(( (CACHED_FILES_BLOCKS + PURGEABLE_BLOCKS) * BLOCK_SIZE / 1024 / 1024 ))
                SWAP=(( SWAPOUTS_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                FREE=(( FREE_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                INACTIVE=(( INACTIVE_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                TOTAL_FREE_GB=(( (FREE + INACTIVE) / 1024 ))
                TOTAL_GB=(( (USED + CACHED_FILES + FREE) / 1024 ))
                printf ">>> Free RAM %.1fG of %.1fG (page size %.1fK, excl. swap %.1fG) (%.1f%%)\n", TOTAL_FREE_GB, TOTAL_GB, (( BLOCK_SIZE / 1024 )), (( SWAP / 1024 )), (( TOTAL_FREE_GB / TOTAL_GB * 100 ))
            }'
    fi

    # TODO add other OS
    #//#PROMPT_COMMAND='history -a;echo -en "\033[m\033[38;5;2m"$(( $(sed -n "s/MemFree:[\t ]\+\([0-9]\+\) kB/\1/p" /proc/meminfo)/1024))"\033[38;5;22m/"$(($(sed -nu "s/MemTotal:[\t ]\+\([0-9]\+\) kB/\1/Ip" /proc/meminfo)/1024 ))MB"\t\033[m\033[38;5;55m$(< /proc/loadavg)\033[m"'
}

printStatDisc() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        INFO=''
        DISCS=($( df -h | grep '/dev/disk' | sort -u -n -k2 | awk '{print $1}' ))
        for DISC in "${DISCS[@]}"; do
            [[ -n "${INFO}" ]] && INFO+=' | '
            INFO+="$( diskutil info ${DISC} | awk '
                /Device Identifier/ {ID = $3}
                /Volume Name/ {VOLUME = substr($0, index($0,$3))}
                /File System Personality/ {FSTYPE = substr($0, index($0,$4))}
                /Volume Free Space/ {FREE = substr($6, 2)}
                /Volume Total Space/ {TOTAL = substr($6, 2)}
                END {
                    printf "%s (%s), %s, free %.1f/%.1fG (%.1f%%)", VOLUME, ID, FSTYPE, (( FREE / 1024 / 1024 / 1024 )), (( TOTAL / 1024 / 1024 / 1024 )), (( FREE / TOTAL * 100 ))
                }' )"
        done
        echo ">>> ${INFO:-No /dev/disk* devices was found}"
    fi

    # TODO add other OS
}

initPromt() {
    echo -e "Welcome, ${COLOR_YELLOW}${USER}${COLOR_DEFAULT}!"

    printStatSystem
    printStatCPU
    printStatMemory
    printStatDisc

    [[ $EUID == 0 ]] && echo -e "${COLOR_RED}Don't forget that shell is under the root!${COLOR_DEFAULT}"
}

PROMPT_COMMAND='setPrompt'

[[ "$PS1" ]] && initPromt



#################
# aliases
#
alias ll="ls -al"
