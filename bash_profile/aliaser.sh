#!/usr/bin/env bash
#
# Script adds/removes aliases to bash profile file
#
# @author demmonico <demmonico@gmail.com> <https://github.com/demmonico>
#
# ./aliaser.sh [-a|--add|-r|--remove|-h|--help] <full_script_path_to_target_file>
# @examples
# 1) add alias
#    ./aliaser.sh [<no_flags>|-a|--add] <full_script_path_to_target_file>
# 2) remove alias
#    ./aliaser.sh [-r|--remove] <full_script_path_to_target_file>
#
#######################################

# set colors
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_GREEN='\033[0;32m'
COLOR_DEFAULT='\033[0m' # No Color

function setFileBashProfile()
{
    FILE_BASH_PROFILE=".bashrc"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        FILE_BASH_PROFILE=".bash_profile"
        echo "MacOS was detected"
    fi

    FILE_BASH_PROFILE="${HOME}/${FILE_BASH_PROFILE}"

    read -p "Pls, check you file BASH_PROFILE [${FILE_BASH_PROFILE}]: " FILE_BASH_PROFILE_INPUT
    FILE_BASH_PROFILE="${FILE_BASH_PROFILE_INPUT:-"${FILE_BASH_PROFILE}"}"
}

function addAlias()
{
    local TARGET_SCRIPT_PATH=$1
    local FILE_BASH_PROFILE=$2

    if [[ ! -f "${TARGET_SCRIPT_PATH}" ]]; then
        echo -e "${COLOR_RED}Error: File '${TARGET_SCRIPT_PATH}' doesn't exists!${COLOR_DEFAULT}"
        exit 1;
    fi

    local TARGET_SCRIPT_FILENAME=`basename "${TARGET_SCRIPT_PATH}"`

    local DEFAULT_ALIAS="${TARGET_SCRIPT_FILENAME%.*}"
    read -p "Pls, check alias you wanted to link with [${DEFAULT_ALIAS}]: " ALIAS
    local ALIAS=${ALIAS:-${DEFAULT_ALIAS}}

    local LABEL_START="### auto-registered ${TARGET_SCRIPT_FILENAME} >>>"
    local LABEL_END="### auto-registered ${TARGET_SCRIPT_FILENAME} <<<"

    if grep -Fxq "${LABEL_START}" "${FILE_BASH_PROFILE}" && grep -Fxq "${LABEL_END}" "${FILE_BASH_PROFILE}"; then
        echo -e "${COLOR_YELLOW}Auto-registered sections already exist!${COLOR_DEFAULT}"
        exit 0;
    else
        sh -c "cat >> ${FILE_BASH_PROFILE}" <<EOT

${LABEL_START}
alias ${ALIAS}="${TARGET_SCRIPT_PATH}"
${LABEL_END}
EOT
    fi
}

function removeAlias()
{
    local TARGET_SCRIPT_PATH=$1
    local FILE_BASH_PROFILE=$2

    local TARGET_SCRIPT_FILENAME=`basename "${TARGET_SCRIPT_PATH}"`
    local LABEL_START="### auto-registered ${TARGET_SCRIPT_FILENAME} >>>"
    local LABEL_END="### auto-registered ${TARGET_SCRIPT_FILENAME} <<<"

    sed -i -e "/${LABEL_START}/,/${LABEL_END}/d" "${FILE_BASH_PROFILE}"
}



########## Main

if [[ -z "${BASH_VERSION}" ]]; then
    echo -e "${COLOR_RED}Error: Bash version is empty!${COLOR_DEFAULT}"
    exit 1;
fi

if [[ $# -eq 1 ]] && [[ $1 != -* ]]; then
    MODE="-a"
    TARGET_SCRIPT_PATH=$1
else
    MODE=$1
    TARGET_SCRIPT_PATH=$2
fi

if [[ "${MODE}" == '-h' ]] || [[ "${MODE}" == '-help' ]]; then
    sh -c "cat" <<EOT
Aliaser help:

Format: ./aliaser.sh [-a|--add|-r|--remove|-h|--help] <full_script_path_to_target_file>

Short format: ./aliaser.sh <full_script_path_to_target_file>
is equal with ./aliaser.sh -a <full_script_path_to_target_file>

Options:
-h|--help       Show help
-a|--add        Add alias to <full_script_path_to_target_file>
-r|--remove     Remove aliased <full_script_path_to_target_file>
EOT
    exit 0;
fi

if [[ -z "${TARGET_SCRIPT_PATH}" ]]; then
    echo -e "${COLOR_RED}Error: Target script path param is required param!${COLOR_DEFAULT}"
    exit 1;
fi

case "${MODE}" in
    -a|--add)
        setFileBashProfile
        if [[ ! -f "${FILE_BASH_PROFILE}" ]]; then
            touch "${FILE_BASH_PROFILE}"
        fi

        addAlias "${TARGET_SCRIPT_PATH}" "${FILE_BASH_PROFILE}"
        echo -e "${COLOR_GREEN}Aliasing via file '${FILE_BASH_PROFILE}' has been completed!\nDon't forget to reload shell e.g. '. ${FILE_BASH_PROFILE}'${COLOR_DEFAULT}"
        exec bash -l
        shift
        ;;
    -r|--remove)
        setFileBashProfile
        if [[ ! -f "${FILE_BASH_PROFILE}" ]]; then
            echo -e "${COLOR_RED}Error: File '${FILE_BASH_PROFILE}' doesn't exists!${COLOR_DEFAULT}"
            exit 1;
        fi

        removeAlias "${TARGET_SCRIPT_PATH}" "${FILE_BASH_PROFILE}"
        echo -e "${COLOR_GREEN}Unaliasing via file '${FILE_BASH_PROFILE}' has been completed!${COLOR_DEFAULT}"
        shift
        ;;
    *)
        echo -e "${COLOR_RED}Error: Invalid mode '${MODE}'${COLOR_DEFAULT}"
        exit 1;
        ;;
esac

exit 0;
