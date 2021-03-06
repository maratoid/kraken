#!/bin/bash -
#title           :kraken-up.sh
#description     :use docker-machine to bring up a kraken cluster manager instance.
#author          :Samsung SDSRA
#==============================================================================
set -o errexit
set -o nounset
set -o pipefail

# pull in utils
my_dir=$(dirname "${BASH_SOURCE}")
source "${my_dir}/utils.sh"

${my_dir}/${KRAKEN_CLUSTER_TYPE}/kraken-up.sh "${ALL_OPTS[@]}"
