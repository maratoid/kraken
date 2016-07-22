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


while [[ $# > 1 ]]
do
key="$1"

case $key in
  --clustername)
  KRAKEN_CLUSTER_NAME="$2"
  shift
  ;;
  *)
    # unknown option
  ;;
esac
shift # past argument or value
done