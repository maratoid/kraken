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

# Defaults for optional arguments
TERRAFORM_RETRIES=${TERRAFORM_RETRIES:-0}

# now build the docker container
if docker inspect ${KRAKEN_CONTAINER_NAME} &> /dev/null; then
  is_running=$(docker inspect -f '{{ .State.Running }}' ${KRAKEN_CONTAINER_NAME})
  if [ ${is_running} == "true" ];  then
    error "Cluster build already running:\n Run\n  \
      'docker logs --follow ${KRAKEN_CONTAINER_NAME}'\n to see logs."
    exit 1
  fi

  run_command "docker rm -f ${KRAKEN_CONTAINER_NAME}"
fi

# Create container which will manage kubernetes cluster infrastructure.
run_command "docker build -t ${KRAKEN_CONTAINER_IMAGE_NAME} -f '${KRAKEN_ROOT}/bin/build/Dockerfile' '${KRAKEN_ROOT}'"

# Copy credentials to kubernetes cluster manager.
if [ "${KRAKEN_NATIVE_DOCKER}" = false ] ; then
  run_command "docker-machine ssh ${KRAKEN_DOCKER_MACHINE_NAME} 'rm -rf ${KRAKEN_AWS_CREDENTIAL_DIRECTORY}'" || true
  run_command "docker-machine ssh ${KRAKEN_DOCKER_MACHINE_NAME} 'mkdir -p ${KRAKEN_AWS_CREDENTIAL_DIRECTORY}'" || true
  run_command "docker-machine ssh ${KRAKEN_DOCKER_MACHINE_NAME} 'chmod +x ${KRAKEN_AWS_CREDENTIAL_DIRECTORY}'" || true
  run_command "docker-machine scp ${AWS_CREDENTIAL_DIRECTORY}/config ${KRAKEN_DOCKER_MACHINE_NAME}:${KRAKEN_AWS_CREDENTIAL_DIRECTORY}" || true
  run_command "docker-machine scp ${AWS_CREDENTIAL_DIRECTORY}/credentials ${KRAKEN_DOCKER_MACHINE_NAME}:${KRAKEN_AWS_CREDENTIAL_DIRECTORY}" || true
fi

# Run a container to create kubernetes cluster infrastructure.
run_command "docker run -d --name ${KRAKEN_CONTAINER_NAME} \
        -v "${KRAKEN_AWS_CREDENTIAL_DIRECTORY}":/root/.aws \
        -v /var/run:/ansible \
        --volumes-from kraken_data ${KRAKEN_CONTAINER_IMAGE_NAME} \
  bash -c \"/opt/kraken/terraform-up.sh \
        --clustertype ${KRAKEN_CLUSTER_TYPE} \
        --clustername ${KRAKEN_CLUSTER_NAME} \
        --terraform-retries ${TERRAFORM_RETRIES}\""

follow ${KRAKEN_CONTAINER_NAME}

kraken_error_code=$(docker inspect -f {{.State.ExitCode}} ${KRAKEN_CONTAINER_NAME})
if [ ${kraken_error_code} -eq 0 ]; then
  inf "Exiting with ${kraken_error_code}"
else
  error "Exiting with ${kraken_error_code}"
fi

exit ${kraken_error_code}
