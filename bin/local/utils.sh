#!/bin/bash -
#title           :utils.sh
#description     :utils
#author          :Samsung SDSRA
#==============================================================================
my_dir=$(dirname "${BASH_SOURCE}")
source "${my_dir}/../common.sh"
KRAKEN_CLUSTER_TYPE="local"

# verify requirements
while read req || [[ -n $req ]]; do
  command -v "$req" >/dev/null 2>&1 || { error "I require $req but it's not installed.  Aborting."; exit 1; }
done <${my_dir}/requirements.txt
