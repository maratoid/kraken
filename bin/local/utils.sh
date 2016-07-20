#!/bin/bash -
#title           :utils.sh
#description     :utils
#author          :Samsung SDSRA
#==============================================================================

my_dir=$(dirname "${BASH_SOURCE}")

# set KRAKEN_ROOT to absolute path for use in other scripts
readonly KRAKEN_ROOT=$(cd "${my_dir}/../.."; pwd)
KRAKEN_VERBOSE=${KRAKEN_VERBOSE:-false}
KRAKEN_CLUSTER_TYPE="local"

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
    eval $1 &> /dev/null
  fi
}

# verify requirements
while read req || [[ -n $req ]]; do
  command -v "$req" >/dev/null 2>&1 || { error "I require $req but it's not installed.  Aborting."; exit 1; }
done <${my_dir}/requirements.txt
