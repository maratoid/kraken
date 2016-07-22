#!/bin/bash -
#title           :kraken-down.sh
#description     :use docker-machine to bring down a kraken cluster manager instance.
#author          :Samsung SDSRA
#==============================================================================
set -o errexit
set -o nounset
set -o pipefail

# pull in utils
my_dir=$(dirname "${BASH_SOURCE}")
source "${my_dir}/utils.sh"

run_command "terraform destroy \
              -input=false \
              -state=${KRAKEN_ROOT}/terraform/${KRAKEN_CLUSTER_TYPE}/${KRAKEN_CLUSTER_NAME}/terraform.tfstate \
              ${KRAKEN_ROOT}/terraform/${KRAKEN_CLUSTER_TYPE}"

