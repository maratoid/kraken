#!/bin/bash -
#title           :kraken-ssh.sh
#description     :ssh to a remotely managed cluster node
#author          :Samsung SDSRA
#==============================================================================
set -o errexit
set -o nounset
set -o pipefail

# pull in utils
my_dir=$(dirname "${BASH_SOURCE}")
source "${my_dir}/utils.sh"

${my_dir}/${KRAKEN_CLUSTER_TYPE}/kraken-connect.sh ${ALL_OPTS[@]}