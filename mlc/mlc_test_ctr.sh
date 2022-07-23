#!/bin/bash
set -e

# General env
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
source "${SCRIPT_PATH}/../lib/common.bash"
source "./mlc_lib.sh"

duration=$1
cpuset="0-6"
latency_core=7

TEST_NAME="${TEST_NAME:-mlc}"
PAYLOAD="mlc.tar"
PAYLOAD_ARGS="${PAYLOAD_ARGS:-tail -f /dev/null}"
PAYLOAD_RUNTIME_ARGS="${PAYLOAD_RUNTIME_ARGS:-5120}"
PAYLOAD_SLEEP="${PAYLOAD_SLEEP:-10}"
MAX_NUM_CONTAINERS="${MAX_NUM_CONTAINERS:-1}"
MAX_MEMORY_CONSUMED="${MAX_MEMORY_CONSUMED:-32*1024*1024*1024}"
MIN_MEMORY_FREE="${MIN_MEMORY_FREE:-2*1024*1024*1024}"
DUMP_CACHES="${DUMP_CACHES:-1}"

function preinstall() {
    ctr_preinstall   
}

function run_a_mlc_case() {
    mlc_cmd=$1
    output=$(ctr_run_a_mlc_case ${mlc_cmd})
    
    echo ${output}
}

function cleanup() {
    metrics_json_save
    clean_env_ctr
}

function mlc_test() {
    restart_containerd_service
    preinstall

    init_env
    metrics_json_init
    save_config

    #Start to test.
    local_100R_BW="mlc --loaded_latency -t${duration} -d0 -R && wait"
    output=$(run_a_mlc_case "$local_100R_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 100R BW: $data"
    local_100R_BW=$(echo $data | awk '{print $3}')

    local_3R1W_BW="mlc --loaded_latency -t${duration} -d0 -W3 && wait"
    output=$(run_a_mlc_case "$local_3R1W_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 3R1W BW: $data"
    local_3R1W_BW=$(echo $data | awk '{print $3}')

    local_2R1W_BW="mlc --loaded_latency -t${duration} -d0 -W2 && wait"
    output=$(run_a_mlc_case "$local_2R1W_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 2R1W BW: $data"
    local_2R1W_BW=$(echo $data | awk '{print $3}')

    local_1R1W_BW="mlc --loaded_latency -t${duration} -d0 -W5 && wait"
    output=$(run_a_mlc_case "$local_1R1W_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 1R1W BW: $data"
    local_1R1W_BW=$(echo $data | awk '{print $3}')

    local_2R1WNT_BW="mlc --loaded_latency -t${duration} -d0 -W7 && wait"
    output=$(run_a_mlc_case "$local_2R1WNT_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 2R1W-NT BW: $data"
    local_2R1WNT_BW=$(echo $data | awk '{print $3}')

    local_1R1WNT_BW="mlc --loaded_latency -t${duration} -d0 -W8 && wait"
    output=$(run_a_mlc_case "$local_1R1WNT_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 1R1W-NT BW: $data"
    local_1R1WNT_BW=$(echo $data | awk '{print $3}')

    local_100WNT_BW="mlc --loaded_latency -t${duration} -d0 -W6 && wait"
    output=$(run_a_mlc_case "$local_100WNT_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 2R1W-NT BW: $data"
    local_100WNT_BW=$(echo $data | awk '{print $3}')

    local_IDLE="mlc --idle_latency -b2g -t${duration} -c0 -j0 -l128"
    output=$(run_a_mlc_case "$local_IDLE")
    data=$(handle_mlc_output "${output}")
    echo "Local Idle Latency: $data"
    local_IDLE=$(echo $data | awk '{print $3}')

    #remote testing
    # Remote_100R_BW="mlc --loaded_latency -k$cpuset -c$latency_core -j1 -d0 -t$duration -R &&wait"
    # output=$(runc_a_mlc_case "$Remote_100R_BW")
    # data=$(handle_mlc_output "${output}")
    # echo "Remote 100R BW: $data"
    # Remote_100R_BW=$(echo $data | awk '{print $3}')

    # Remote_3R1W_BW="mlc --loaded_latency -k$cpuset -c$latency_core -j1 -d0 -t$duration -W3 &&wait"
    # output=$(runc_a_mlc_case "$Remote_3R1W_BW")
    # data=$(handle_mlc_output "${output}")
    # echo "Remote 3R1W BW: $data"
    # Remote_3R1W_BW=$(echo $data | awk '{print $3}')

    # Remote_2R1W_BW="mlc --loaded_latency -k$cpuset -c$latency_core -j1 -d0 -t$duration -W2 &&wait"
    # output=$(runc_a_mlc_case "$Remote_2R1W_BW")
    # data=$(handle_mlc_output "${output}")
    # echo "Remote 2R1W BW: $data"
    # Remote_2R1W_BW=$(echo $data | awk '{print $3}')

    # Remote_1R1W_BW="mlc --loaded_latency -k$cpuset -c$latency_core -j1 -d0 -t$duration -W5 &&wait"
    # output=$(runc_a_mlc_case "$Remote_1R1W_BW")
    # data=$(handle_mlc_output "${output}")
    # echo "Remote 1R1W BW: $data"
    # Remote_1R1W_BW=$(echo $data | awk '{print $3}')

    # Remote_2R1WNT_BW="mlc --loaded_latency -k$cpuset -c$latency_core -j1 -d0 -t$duration -W7 &&wait"
    # output=$(runc_a_mlc_case "$Remote_2R1WNT_BW")
    # data=$(handle_mlc_output "${output}")
    # echo "Remote 2R1WNT BW: $data"
    # Remote_2R1WNT_BW=$(echo $data | awk '{print $3}')

    # Remote_1R1WNT_BW="mlc --loaded_latency -k$cpuset -c$latency_core -j1 -d0 -t$duration -W8 &&wait"
    # output=$(runc_a_mlc_case "$Remote_1R1WNT_BW")
    # data=$(handle_mlc_output "${output}")
    # echo "Remote 1R1WNT BW: $data"
    # Remote_1R1WNT_BW=$(echo $data | awk '{print $3}')

    # Remote_100WNT_BW="mlc --loaded_latency -k$cpuset -c$latency_core -j1 -d0 -t$duration -W6 &&wait"
    # output=$(runc_a_mlc_case "$Remote_100WNT_BW")
    # data=$(handle_mlc_output "${output}")
    # echo "Remote 100WNT BW: $data"
    # Remote_100WNT_BW=$(echo $data | awk '{print $3}')

    metrics_json_start_array
    #save result to json
    local result_json="$(cat << EOF
    {
        "Local_100R_BW": {
            "Result" : $local_100R_BW,
            "Units"  : "MB/s"
        },
        "Local_3R1W_BW": {
            "Result" : $local_3R1W_BW,
            "Units"  : "MB/s"
        },
        "Local_2R1W_BW": {
            "Result" : $local_2R1W_BW,
            "Units"  : "MB/s"
        },
        "Local_1R1W_BW": {
            "Result" : $local_1R1W_BW,
            "Units"  : "MB/s"
        },
        "Local_2R1WNT_BW": {
            "Result" : $local_2R1WNT_BW,
            "Units"  : "MB/s"
        },
        "Local_1R1WNT_BW": {
            "Result" : $local_1R1WNT_BW,
            "Units"  : "MB/s"
        },
        "Local_100WNT_BW": {
            "Result" : $local_100WNT_BW,
            "Units"  : "MB/s"
        },
        "Local_Idle_Latency": {
            "Result" : $local_IDLE,
            "Units"  : "ns"
        },

    }
EOF
)"
    metrics_json_add_array_element "$result_json"
    metrics_json_end_array "Result"
    metrics_json_save
    clean_env_ctr
}

mlc_test
