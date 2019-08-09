#!/usr/bin/env bash
#
# Script runs batch git cloner tasks
#
# @author demmonico <demmonico@gmail.com> <https://github.com/demmonico>
#
# ./pilferer.sh [PARAMS]
# @params
# -c|--cloner-script
# -s|--source-list
# -d|--destination-repo
#
#######################################

RED='\033[0;31m'
NC='\033[0m' # No Color

while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -c|--cloner-script)
            if [[ ! -z "$2" ]]; then
                CLONER="$2"
            fi
            shift
            ;;
        -s|--source-list)
            if [[ ! -z "$2" ]]; then
                SOURCE_LIST="$2"
            fi
            shift
            ;;
        -d|--destination-repo)
            if [[ ! -z "$2" ]]; then
                DESTINATION_REPO_URL="$2"
            fi
            shift
            ;;
        *)
            echo -e "${RED}Error:${NC} invalid option -$1"
            exit 1;
            ;;
    esac
        shift
done

REQUIRED_PARAMS=("CLONER" "SOURCE_LIST" "DESTINATION_REPO_URL")
for param in "${!REQUIRED_PARAMS[@]}"; do
    if [[ -z "${!REQUIRED_PARAMS[param]}" ]]; then
        echo "${REQUIRED_PARAMS[param]} param is required"
        exit 1;
    fi
done

if [[ ${CLONER} != /* ]]; then
    CLONER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/${CLONER}"
fi

if [[ ${SOURCE_LIST} != /* ]]; then
    SOURCE_LIST="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/${SOURCE_LIST}"
fi



echo "------------------------------"
echo "Processing ${SOURCE_LIST} ..."
while IFS= read -r line; do
    sources=(${line//;/ })
    SOURCE_REPO="${sources[0]}"
    DESTINATION_BRANCH="${sources[1]}"
    if [[ -z "${SOURCE_REPO}" ]] || [[ -z "${DESTINATION_BRANCH}" ]]; then
        echo -e "${RED}Error:${NC} bad source line '${line}'"
        exit 1;
    fi

    source ${CLONER} \
        --source-repo ${SOURCE_REPO} \
        --destination-repo ${DESTINATION_REPO_URL} \
        --destination-branch ${DESTINATION_BRANCH}

    PROCESSED=$((PROCESSED+1))
done < ${SOURCE_LIST}

echo "------------------------------"
echo "Processed ${PROCESSED} sources"
