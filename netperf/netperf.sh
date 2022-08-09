#!/bin/bash
#
# Copyright (c) 2021 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#
# This test measures the following network essentials:
# - bandwith simplex
# - jitter
#
# These metrics/results will be got from the interconnection between
# a client and a server using iperf3 tool.
# The following cases are covered:
#
# case 1:
#  container-server <----> container-client
#
# case 2"
#  container-server <----> host-client

set -e

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")

source "${SCRIPT_PATH}/../../.ci/lib.sh"
source "${SCRIPT_PATH}/../lib/common.bash"
iperf_file=$(mktemp iperfresults.XXXXXXXXXX)
TEST_NAME="${TEST_NAME:-network-iperf3}"
COLLECT_ALL="${COLLECT_ALL:-false}"
CI_JOB="${CI_JOB:-}"
test_repo="${test_repo:-github.com/kata-containers/tests}"

function remove_tmp_file() {
	rm -rf "${iperf_file}"
}

trap remove_tmp_file EXIT

function iperf3_deployment_cleanup() {
        kubectl delete deployment "$deployment"
        kubectl delete service "$deployment"
        end_kubernetes
        check_processes
}

function start_kubernetes() {
        info "Start k8s"
        pushd "${GOPATH}/src/${test_repo}/integration/kubernetes"
        bash ./init.sh
        popd
}

function end_kubernetes() {
        info "End k8s"
        pushd "${GOPATH}/src/${test_repo}/integration/kubernetes"
        bash ./cleanup_env.sh
        popd
}

function iperf3_all_collect_results() {
	metrics_json_init
	metrics_json_start_array
	local json="$(cat << EOF
	{
		"bandwidth": {
			"Result" : $bandwidth_result,
			"Units" : "$bandwidth_units"
		},
		"jitter": {
			"Result" : $jitter_result,
			"Units" : "$jitter_units"
		},
		"cpu": {
			"Result" : $cpu_result,
			"Units"  : "$cpu_units"
		},
		"parallel": {
			"Result" : $parallel_result,
			"Units" : "$parallel_units"
		}
	}
EOF
)"
	metrics_json_add_array_element "$json"
	metrics_json_end_array "Results"
}

function pod_2_pod_bandwidth() {
	echo "${bandwidth_result}"
}

function iperf3_bandwidth() {
	# Start server
	local transmit_timeout="60"
	metrics_json_init
 	metrics_json_start_array

	for iosize in 64 256 1024 4k 
	do
		echo "kubectl exec -i "$client_pod_name" -- iperf3 -c ${server_ip_add} -f M -t ${transmit_timeout} -l "${iosize}" | jq '.end.sum_received.bits_per_second' > "${iperf_file}""
		kubectl exec -i "$client_pod_name" -- iperf3 -c ${server_ip_add} -t ${transmit_timeout} -l "${iosize}" | jq '.end.sum_received.bits_per_second' > "${iperf_file}"
		bandwidth_result=$(cat "${iperf_file}")
		echo "${iosize}_${bandwidth_result} bps"
		local json="$(cat << EOF
 		{
 			"bandwidth": {
 				"Result" : $bandwidth_result,
 				"Units" : "${iosize}"
 			}
 		}
EOF
)"

	done
	echo ${json}
 	metrics_json_add_array_element "$json"
 	metrics_json_end_array "Results"
}

function iperf3_start_deployment() {
	#cmds=("bc" "jq")
	#check_cmds "${cmds[@]}"

	# Check no processes are left behind
	echo "check processes iperf3_start_deployment"
	check_processes

	if [ -z "${CI_JOB}" ]; then
		# Start kubernetes
		start_kubernetes
	fi

	export KUBECONFIG="$HOME/.kube/config"
	export service="iperf3-server"
	export deployment="iperf3-server-deployment"

	wait_time=20
	sleep_time=2

	# Create deployment
	export server_pod_name=$(kubectl get pods -o name | grep server | cut -d '/' -f2)
	echo "server_pod_name $server_pod_name"
	if [ -z "${server_pod_name}" ]; then
		echo "create server pod."
		kubectl create -f "${SCRIPT_PATH}/runtimeclass_workloads/iperf3-deployment.yaml"
		local cmd="kubectl wait --for=condition=Available deployment/${deployment}"
		waitForProcess "$wait_time" "$sleep_time" "$cmd"
		# Get the names of the server pod
		export server_pod_name=$(kubectl get pods -o name | grep server | cut -d '/' -f2)

		# Verify the server pod is working
		local cmd="kubectl get pod $server_pod_name -o yaml | grep 'phase: Running'"
		waitForProcess "$wait_time" "$sleep_time" "$cmd"
	else
		echo "${server_pod_name} exists."
	fi
	echo "client pod name: ${client_pod_name}"
	# Check deployment creation
	# Create DaemonSet
	export client_pod_name=$(kubectl get pods -o name | grep client | cut -d '/' -f2)
	if [ -z "${client_pod_name}" ]; then
		kubectl create -f "${SCRIPT_PATH}/runtimeclass_workloads/iperf3-daemonset.yaml"

		# Expose deployment
		kubectl expose deployment/"${deployment}"

		# Get the names of client pod
		export client_pod_name=$(kubectl get pods -o name | grep client | cut -d '/' -f2)

		# Verify the client pod is working
		local cmd="kubectl get pod $client_pod_name -o yaml | grep 'phase: Running'"
		waitForProcess "$wait_time" "$sleep_time" "$cmd"
	fi
	echo "client pod name: ${client_pod_name}"

	# Get the ip address of the server pod
	export server_ip_add=$(kubectl get pod "$server_pod_name" -o jsonpath='{.status.podIP}')
	echo ${server_ip_add}
}

function iperf3_deployment_cleanup() {
	kubectl delete deployment "$deployment"
	kubectl delete service "$deployment"
	if [ -z "${CI_JOB}" ]; then
		end_kubernetes
		check_processes
	fi
}

function help() {
echo "$(cat << EOF
Usage: $0 "[options]"
	Description:
		This script implements a number of network metrics
		using iperf3.

	Options:
		-a	Run all tests
		-b 	Run bandwidth tests
		-c	Run cpu metrics tests
		-h	Help
		-j	Run jitter tests
EOF
)"
}

function main() {
	init_env
	iperf3_start_deployment

	iperf3_bandwidth

	#metrics_json_save
	iperf3_deployment_cleanup
}

main "$@"
