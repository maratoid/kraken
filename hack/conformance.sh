#!/bin/bash
set -x

KUBE_CONFORMANCE_KUBECONFIG=${KUBE_CONFORMANCE_KUBECONFIG:-"$HOME/.kube/config"}
KUBE_ROOT=${KUBE_ROOT:-"$GOPATH/src/k8s.io/kubernetes"}
KUBE_CONFORMANCE_NUM_NODES=${KUBE_CONFORMANCE_NUM_NODES:-"10"} # TODO: lock to 4? auto-detect?
KUBE_CONFORMANCE_OUTPUT_DIR=${KUBE_CONFORMANCE_OUTPUT_DIR:-"$(pwd)/output/conformance"}
KUBE_CONFORMANCE_SEED="1436380640"
# TODO: external build-or-download script instead
KUBE_CONFORMANCE_REBUILD_TESTS=${KUBE_CONFORMANCE_REBUILD_TESTS:-false}
KUBE_SSH_USER=${KUBE_SSH_USER:-"core"}
KUBE_SSH_KEY=${KUBE_SSH_KEY:-"${AWS_SSH_KEY}"}

if [[ $# < 1 ]]; then
  echo "Usage: $0 conformance_branch"
  echo "Runs kubernetes conformance tests from the given branch"
  echo "  eg: $0 release-1.1"
  exit 1
fi

KUBE_CONFORMANCE_BRANCH=$1

pushd "${KUBE_ROOT}"
# XXX: this is destructive, bad idea to use with repo under active development
git checkout -f ${KUBE_CONFORMANCE_BRANCH}
KUBE_CONFORMANCE_SHA=$(git rev-parse HEAD)

echo
echo "Conformance test run start date: $(date -u)"
echo "Conformance test branch: ${KUBE_CONFORMANCE_BRANCH}"
echo "Conformance test SHA: ${KUBE_CONFORMANCE_SHA}"
echo "Conformance test cluster size: ${KUBE_CONFORMANCE_NUM_NODES}"
echo "Conformance test kubeconfig: ${KUBE_CONFORMANCE_KUBECONFIG}"

if ${KUBE_CONFORMANCE_REBUILD_TESTS}; then
  echo
  # TODO: build just the conformance tests for our platform instead of a cross-platform release?
  echo "Building conformance tests..."
  build/make-clean.sh
  build/run.sh hack/build-cross.sh
fi

# Unrolling hack/ginkgo-e2e.sh
function hack_ginkgo_e2e() {
  # use glue from k8s for now
  source "${KUBE_ROOT}/cluster/common.sh"
  source "${KUBE_ROOT}/hack/lib/init.sh"
  kube::golang::setup_env
  ginkgo=$(kube::util::find-binary "ginkgo")
  e2e_test=$(kube::util::find-binary "e2e.test")
  echo "Conformance test: not doing test setup."
  KUBERNETES_PROVIDER=""
  KUBECONFIG="${KUBE_CONFORMANCE_KUBECONFIG}"
  # detect-master-from-kubeconfig

  export AWS_SSH_KEY="${KUBE_SSH_KEY}"

  e2e_test_args=()
  # standard args
  e2e_test_args+=("--repo-root=${KUBE_ROOT}")
  e2e_test_args+=("--kubeconfig=${KUBE_CONFORMANCE_KUBECONFIG}")
  e2e_test_args+=("--e2e-output-dir=${KUBE_CONFORMANCE_OUTPUT_DIR}")
  e2e_test_args+=("--report-dir=${KUBE_CONFORMANCE_OUTPUT_DIR}")
  e2e_test_args+=("--prefix=e2e")

  # Provider specific args are currently required for SSH access. Note that
  # https://github.com/kubernetes/kubernetes/issues/20919 suggests that we
  # would like to fix kubernetes so that --provider is no longer necessary.
  e2e_test_args+=("--provider=aws")
  e2e_test_args+=("--gce-zone=us-west-2")
  e2e_test_args+=("--cluster-tag=kraken-node")

  # TODO: (for which branches) are these necessary?
  e2e_test_args+=("--num-nodes=${KUBE_CONFORMANCE_NUM_NODES}")
  if [[ ${KUBE_CONFORMANCE_BRANCH} == "conformance-test-v1" ]]; then
    echo "additional e2e test args for ${KUBE_CONFORMANCE_BRANCH} branch"
    # TODO: backport [Conformance] tags to conformance-test-v1?
    export CONFORMANCE_TEST_SKIP_REGEX="Cadvisor|MasterCerts|Density|Cluster\slevel\slogging.*|Etcd\sfailure.*|Load\sCapacity|Monitoring|Namespaces.*seconds|Pod\sdisks|Reboot|Restart|Nodes|Scale|Services.*load\sbalancer|Services.*NodePort|Shell|SSH|Volumes"
  elif [[ ${KUBE_CONFORMANCE_BRANCH} == "release-1.0" ]]; then
    echo "additional e2e test args for ${KUBE_CONFORMANCE_BRANCH} branch"
    # TODO: backport [Conformance] tags to release-1.0
    export CONFORMANCE_TEST_SKIP_REGEX="Cadvisor|MasterCerts|Density|Cluster\slevel\slogging.*|Etcd\sfailure.*|Load\sCapacity|Monitoring|Namespaces.*seconds|Pod\sdisks|Reboot|Restart|Nodes|Scale|Services.*load\sbalancer|Services.*NodePort|Shell|SSH|Volumes"
  elif [[ ${KUBE_CONFORMANCE_BRANCH} == "release-1.1" ]]; then
    echo "additional e2e test args for ${KUBE_CONFORMANCE_BRANCH} branch"
    e2e_test_args+=("--ginkgo.focus=\[Conformance\]")
  else
    echo "additional e2e test args for ${KUBE_CONFORMANCE_BRANCH} branch"
    e2e_test_args+=("--ginkgo.focus=\[Conformance\]")
  fi

  # ginkgo args
  e2e_test_args+=("--ginkgo.noColor=true")
  e2e_test_args+=("--ginkgo.v=true")

  # ginkgo args for conformance
  e2e_test_args+=("--ginkgo.seed=${KUBE_CONFORMANCE_SEED}")
  if [[ -n "${CONFORMANCE_TEST_SKIP_REGEX:-}" ]]; then
    e2e_test_args+=("--ginkgo.skip=${CONFORMANCE_TEST_SKIP_REGEX}")
  fi

  # Add path for things like running kubectl binary.
  export PATH=$(dirname "${e2e_test}"):"${PATH}"

  "${ginkgo}" "${e2e_test}" -- \
    ${e2e_test_args[@]:+${e2e_test_args[@]}} \
    "${@:-}"

}

echo
echo "Running conformance tests..."
if [[ "${KUBE_CONFORMANCE_BRANCH}" == "conformance-test-v1" ]]; then
  export CONFORMANCE_TEST_SKIP_REGEX="Cadvisor|MasterCerts|Density|Cluster\slevel\slogging|Etcd\sfailure|Load\sCapacity|Monitoring|Namespaces.*seconds|Pod\sdisks|Reboot|Restart|Nodes|Scale|Services.*load\sbalancer|Services.*NodePort|Services.*nodeport|Shell|SSH|Addon\supdate|Volumes|Clean\sup\spods\son\snode|Skipped|skipped|MaxPods\slimit\snumber\sof\spods|Kubectl\sclient\sSimple\spod|DNS"
fi
hack_ginkgo_e2e
conformance_result=$?

# restore the previous HEAD
git checkout -
popd

echo
echo "Conformance test run stop date: $(date -u)"
exit $conformance_result
