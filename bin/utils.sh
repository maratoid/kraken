#!/bin/bash -
#title           :utils.sh
#description     :utils
#author          :Samsung SDSRA
#==============================================================================
ALL_OPTS=( "$@" )

while [[ $# > 1 ]]
do
key="$1"

case $key in
  --clustertype)
  KRAKEN_CLUSTER_TYPE="$2"
  shift
  ;;
  *)
    # unknown option
  ;;
esac
shift # past argument or value
done