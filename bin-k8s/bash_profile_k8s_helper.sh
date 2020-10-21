#!/usr/bin/env bash
#
# Kubectl helper
# @use add to file `.bash_profile` line `source ~/.bash_profile_k8s_helper.sh`
# @example ks [params] CMD
# @example ks use [params] OR ks use
# @author demmonico <demmonico@gmail.com> <https://github.com/demmonico>

COLOR_RED='\033[0;91m'
COLOR_YELLOW='\033[1;93m'
COLOR_DEFAULT='\033[00m'

# persistent
K8S_NAMESPACE=''
K8S_ENV=''

# one-time resources
K8S_LABEL=''
K8S_REQUEST_RES_ID=''

ksHelperFetchResourceFromList() {
  local REQUEST_LIST_CMD=$1
  local K8S_SPACE=''

  [ -n "${K8S_LABEL}" ] && K8S_SPACE="--label ${K8S_LABEL}"

  if [ -z "$2" ]; then
    echo -e "${COLOR_RED}Resourse ID is required${COLOR_DEFAULT}"
    return 1;
  elif [ "$2" == 'first' ]; then
    K8S_REQUEST_RES_ID="$( eval "ks -q ${K8S_SPACE} ${REQUEST_LIST_CMD}" | grep -v '^NAME' | awk 'NR==1 {print $1; exit}' )"
  elif [ "$2" == 'last' ]; then
    K8S_REQUEST_RES_ID="$( eval "ks -q ${K8S_SPACE} ${REQUEST_LIST_CMD}" | grep -v '^NAME' | awk 'END{print $1}' )"
  else
    K8S_REQUEST_RES_ID=$2
  fi

  if [ -z "${K8S_REQUEST_RES_ID}" ]; then
    echo -e "${COLOR_RED}No resourses to describe${COLOR_DEFAULT}"
    return 1;
  fi
}

ksHelperCleanUp() {
  K8S_LABEL=''
  K8S_REQUEST_RES_ID=''
}


### shortcuts
ks() {
  local CMD=''
  local CMD_PARAMS=''
  local IS_QUITE_MODE=''
  local IS_LABEL_APPLICABEL=''
  local K8S_SPACE=''

  local RUNNER="docker run --rm -it -v ${PWD}:/app -w /app deployer.azurecr.io/helm-az:<<ENV>>"
  local RUNNER_VOLUME=''

  ksHelperCleanUp

  #  init
  while [[ $# -gt 0 ]]; do
      key="$1"
      case $key in

          # params
          -q|--quite) IS_QUITE_MODE="1";;
          -n|--namespace) K8S_NAMESPACE="$2";
              shift
              ;;
          -e|--env) if [ -n "$2" ]; then K8S_ENV="$2"; fi
              shift
              ;;
          --label) if [ -n "$2" ]; then K8S_LABEL="$2"; fi
              shift
              ;;
          -p|--params) if [ -n "$2" ]; then CMD_PARAMS="$2"; fi
              shift
              ;;

          # commands
          gj)
              CMD='get jobs';
              IS_LABEL_APPLICABEL="1";
              ;;
          gcj)
              CMD='get cronjobs';
              IS_LABEL_APPLICABEL="1";
              ;;
          gp)
              CMD='get pods';
              IS_LABEL_APPLICABEL="1";
              ;;
          dp) ksHelperFetchResourceFromList 'gp' $2 || return 1;
              CMD="describe pod ${K8S_REQUEST_RES_ID}";
              shift
              ;;
          dj) ksHelperFetchResourceFromList 'gj' $2 || return 1;
              CMD="describe job ${K8S_REQUEST_RES_ID}";
              shift
              ;;
          dcj) ksHelperFetchResourceFromList 'gcj' $2 || return 1;
              CMD="describe cronjob ${K8S_REQUEST_RES_ID}";
              shift
              ;;
          logs) CMD='logs';
              IS_LABEL_APPLICABEL="1";
              shift
              ;;
          # special
          runner) CMD='runner';
              shift
              ;;
          use) CMD='use';;

          *)  echo -e "${COLOR_RED}Error:${COLOR_DEFAULT} invalid option -$1"
              return 1;
              ;;
      esac
          shift
  done

  ###
  # commands should be here bc options could goes AFTER commands declaration

  # setup
  if [ "${CMD}" == 'use' ]; then
    echo -e "Using ENV: ${COLOR_YELLOW}${K8S_ENV}${COLOR_DEFAULT}, NAMESPACE: ${COLOR_YELLOW}${K8S_NAMESPACE}${COLOR_DEFAULT}"
    return;
  fi

  ###
  if [ -z "${K8S_ENV}" ]; then
    echo -e "${COLOR_RED}Env couldn't be empty${COLOR_DEFAULT}"
    return 1;
  fi

  # exec runner
  if [ "${CMD}" == 'runner' ]; then
    CMD="${RUNNER//<<ENV>>/${K8S_ENV}} sh"

    [ -z "${IS_QUITE_MODE}" ] && echo -e "KS: Calling >>> ${COLOR_YELLOW}${CMD}${COLOR_DEFAULT}"
    eval "${CMD}"

    ksHelperCleanUp
    return;
  fi

  # run
  [ -n "${K8S_NAMESPACE}" ] && K8S_SPACE="-n ${K8S_NAMESPACE}" || K8S_SPACE='--all-namespaces'
  if [ -n "${IS_LABEL_APPLICABEL}" ] && [ -n "${K8S_LABEL}" ]; then
    K8S_SPACE="-l${K8S_LABEL} ${K8S_SPACE}"
  fi

  CMD="${RUNNER//<<ENV>>/${K8S_ENV}} kubectl ${CMD} ${CMD_PARAMS} ${K8S_SPACE}"

  [ -z "${IS_QUITE_MODE}" ] && echo -e "KS: Calling >>> ${COLOR_YELLOW}${CMD//kubectl/${COLOR_RED}kubectl}${COLOR_DEFAULT}"
  eval "${CMD}"

  ksHelperCleanUp
  return;
}
