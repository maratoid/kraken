#!/bin/bash -
#title           :utils.sh
#description     :utils
#author          :Samsung SDSRA
#==============================================================================
ALL_OPTS=""

while [[ $# > 1 ]]
do
key="$1"

case $key in
  --clustertype)
  KRAKEN_CLUSTER_TYPE="$2"
  shift
  ;;
  --clustername)
  ALL_OPTS="${ALL_OPTS}--clustername $2 "
  shift
  ;;
  --dmopts)
  ALL_OPTS="${ALL_OPTS}--dmopts $2 "
  shift
  ;;
  --dmname)
  ALL_OPTS="${ALL_OPTS}--dmname $2 "
  shift
  ;;
  --dmshell)
  ALL_OPTS="${ALL_OPTS}--dmshell $2 "
  shift
  ;;
  --terraform-retries)
  ALL_OPTS="${ALL_OPTS}--terraform-retries $2 "
  shift
  ;;
  --aws-credential-directory)
  ALL_OPTS="${ALL_OPTS}--aws-credential-directory $2 "
  shift
  ;;
  *)
    # unknown option
  ;;
esac
shift # past argument or value
done