#!/usr/bin/env bash
#
# Script clones git repo
#
# @author demmonico <demmonico@gmail.com> <https://github.com/demmonico>
#
# ./git-cloner.sh [PARAMS]
# @params
# -s|--source-repo
# -d|--destination-repo
# -b|--destination-branch
#
#######################################

RED='\033[0;31m'
NC='\033[0m' # No Color

while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -s|--source-repo)
            if [[ ! -z "$2" ]]; then
                SOURCE_REPO_URL="$2"
            fi
            shift
            ;;
        -d|--destination-repo)
            if [[ ! -z "$2" ]]; then
                DESTINATION_REPO_URL="$2"
            fi
            shift
            ;;
        -b|--destination-branch)
            if [[ ! -z "$2" ]]; then
                DESTINATION_BRANCH="$2"
            fi
            shift
            ;;
        *)
            echo -e "${RED}Error:${NC} invalid option -$1"
            exit
            ;;
    esac
        shift
done

REQUIRED_PARAMS=("SOURCE_REPO_URL" "DESTINATION_REPO_URL" "DESTINATION_BRANCH")
for param in "${!REQUIRED_PARAMS[@]}"; do
    if [[ -z "${!REQUIRED_PARAMS[param]}" ]]; then
        echo "${REQUIRED_PARAMS[param]} param is required"
        exit 1;
    fi
done

DESTINATION_REPO_NAME='storage'
FOLDER=$( date +"%Y%m%d_%H%M%S_$RANDOM" )



echo "Cloning ${SOURCE_REPO_URL} -> ${DESTINATION_BRANCH} ... " && \
    git clone ${SOURCE_REPO_URL} ${FOLDER} > /dev/null 2>&1 && \
    cd ${FOLDER} && \
    git remote add ${DESTINATION_REPO_NAME} ${DESTINATION_REPO_URL} && \
    FROM_BRANCH="$(git branch | grep \* | cut -d ' ' -f2)" && \
    git push ${DESTINATION_REPO_NAME} ${FROM_BRANCH}:${DESTINATION_BRANCH} > /dev/null 2>&1 && \
    cd .. && \
    rm -rf ${FOLDER} && \
    echo "Done"
