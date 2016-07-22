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

run_command "terraform apply \
-input=false \
-state=${KRAKEN_ROOT}/terraform/${KRAKEN_CLUSTER_TYPE}/${KRAKEN_CLUSTER_NAME}/terraform.tfstate \
-var-file=${KRAKEN_ROOT}/terraform/${KRAKEN_CLUSTER_TYPE}/${KRAKEN_CLUSTER_NAME}/terraform.tfvars \
${KRAKEN_ROOT}/terraform/${KRAKEN_CLUSTER_TYPE}"