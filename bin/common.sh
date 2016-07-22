#!/bin/bash -
#title           :common.sh
#description     :common
#author          :Samsung SDSRA
#==============================================================================
# set KRAKEN_ROOT to absolute path for use in other scripts
readonly KRAKEN_ROOT=$(cd "$(dirname "${BASH_SOURCE}")/.."; pwd)
KRAKEN_VERBOSE=${KRAKEN_VERBOSE:-false}

function warn {
  echo -e "\033[1;33mWARNING: $1\033[0m"
}

function error {
  echo -e "\033[0;31mERROR: $1\033[0m"
}

function inf {
  echo -e "\033[0;32m$1\033[0m"
}

function run_command {
  inf "Running:\n $1"
  if ${KRAKEN_VERBOSE}; then
    eval $1
  else
    eval $1 1> /dev/null
  fi
}