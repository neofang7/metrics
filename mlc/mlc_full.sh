#!/bin/bash
set -e

# General env
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
source "${SCRIPT_PATH}/../lib/common.bash"
source "${SCRIPT_PATH}/mlc_lib.sh"

duration=$1
cpuset="0-6"
latency_core=7

TEST_NAME="${TEST_NAME:-mlc-full}"
PAYLOAD="mlc.tar"
PAYLOAD_ARGS="${PAYLOAD_ARGS:-tail -f /dev/null}"
PAYLOAD_RUNTIME_ARGS="${PAYLOAD_RUNTIME_ARGS:-5120}"
PAYLOAD_SLEEP="${PAYLOAD_SLEEP:-10}"
MAX_NUM_CONTAINERS="${MAX_NUM_CONTAINERS:-1}"
MAX_MEMORY_CONSUMED="${MAX_MEMORY_CONSUMED:-32*1024*1024*1024}"
MIN_MEMORY_FREE="${MIN_MEMORY_FREE:-2*1024*1024*1024}"
DUMP_CACHES="${DUMP_CACHES:-1}"

function run_mlc_ctr() {
    restart_containerd_service
    ctr_preinstall

    init_env
    metrics_json_init
    save_config

    #Run mlc command:
    #idle latency: mlc --idle_latency -b2g -t10 -c0 -i0 -e -r -l128
    cmd_idle_latency="mlc --idle_latency -b2g -t10 -c0 -i0 -e -r -l128"
    output=$(ctr_run_a_mlc_case "$cmd_idle_latency")
    data=${output#*base frequency clocks \(}
    idle_latency_ns=$(echo $data | awk '{print $1}')
    echo "idle latency: $idle_latency_ns"

    #loaded-latency-R (ns): mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -r -K1 -R
    cmd_loaded_latency_R="mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -r -K1 -R"
    output=$(ctr_run_a_mlc_case "$cmd_loaded_latency_R")
    data=$(handle_mlc_output "${output}")
    echo "loaded latency R: $data"
    loaded_latency_R_ns=$(echo $data | awk '{print $2}')
    loaded_latency_R_bw=$(echo $data | awk '{print $3}')

    #loaded-latency-W2 (ns)	mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -K1 -W2
    cmd_loaded_latency_W2="mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -r -K1 -W2"
    output=$(ctr_run_a_mlc_case "$cmd_loaded_latency_W2")
    data=$(handle_mlc_output "${output}")
    echo "loaded latency W2: $data"
    loaded_latency_W2_ns=$(echo $data | awk '{print $2}')
    loaded_latency_W2_bw=$(echo $data | awk '{print $3}')

    #loaded-latency-W3 (ns)	mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -K1 -W3
    cmd_loaded_latency_W3="mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -r -K1 -W3"
    output=$(ctr_run_a_mlc_case "$cmd_loaded_latency_W3")
    data=$(handle_mlc_output "${output}")
    echo "loaded latency W3: $data"
    loaded_latency_W3_ns=$(echo $data | awk '{print $2}')
    loaded_latency_W3_bw=$(echo $data | awk '{print $3}')
    
    #loaded-latency-W5 (ns)	mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -K1 -W5
    cmd_loaded_latency_W5="mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -r -K1 -W5"
    output=$(ctr_run_a_mlc_case "$cmd_loaded_latency_W5")
    data=$(handle_mlc_output "${output}")
    echo "loaded latency W5: $data"
    loaded_latency_W5_ns=$(echo $data | awk '{print $2}')
    loaded_latency_W5_bw=$(echo $data | awk '{print $3}')

    #loaded-latency-W6 (ns)	mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -K1 -W6
    cmd_loaded_latency_W6="mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -r -K1 -W6"
    output=$(ctr_run_a_mlc_case "$cmd_loaded_latency_W6")
    data=$(handle_mlc_output "${output}")
    echo "loaded latency W6: $data"
    loaded_latency_W6_ns=$(echo $data | awk '{print $2}')
    loaded_latency_W6_bw=$(echo $data | awk '{print $3}')

    #loaded-latency-W7 (ns)	mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -K1 -W7
    cmd_loaded_latency_W7="mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -r -K1 -W7"
    output=$(ctr_run_a_mlc_case "$cmd_loaded_latency_W7")
    data=$(handle_mlc_output "${output}")
    echo "loaded latency W7: $data"
    loaded_latency_W7_ns=$(echo $data | awk '{print $2}')
    loaded_latency_W7_bw=$(echo $data | awk '{print $3}')

    #loaded-latency-W8 (ns)	mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -K1 -W8
    cmd_loaded_latency_W8="mlc --loaded_latency -d0 -b1g -t30 -k1-3 -c0 -e -r -K1 -W8"
    output=$(ctr_run_a_mlc_case "$cmd_loaded_latency_W8")
    data=$(handle_mlc_output "${output}")
    echo "loaded latency W8: $data"
    loaded_latency_W8_ns=$(echo $data | awk '{print $2}')
    loaded_latency_W8_bw=$(echo $data | awk '{print $3}')

    #max-bandwidth	mlc --max_bandwidth -d0 -b1g -t30 -k1-3 -c0 -e -R
    # cmd_bandwidth="mlc --max_bandwidth -d0 -b1g -t30 -k1-3 -c0 -e -R"
    # output=$(ctr_run_a_mlc_case "$cmd_bandwidth")
    # data=$(handle_mlc_output "${output}")
    # echo "max-bandwidth: $data"
    # max_bandwidth=$(echo $data | awk '{print $3}')

    #peak-bandwidth	mlc --peak_injection_bandwidth -K1 -e
    # Measuring Peak Injection Memory Bandwidths for the system
    # Bandwidths are in MB/sec (1 MB/sec = 1,000,000 Bytes/sec)
    # Using all the threads from each core if Hyper-threading is enabled
    # Using traffic with the following read-write ratios
    # ALL Reads        :      236436.6
    # 3:1 Reads-Writes :      204784.6
    # 2:1 Reads-Writes :      195782.1
    # 1:1 Reads-Writes :      180993.0
    # Stream-triad like:      202882.4
    cmd_peak_bandwidth="mlc --peak_injection_bandwidth -K1 -e"
    output=$(ctr_run_a_mlc_case "$cmd_peak_bandwidth")
    output1=${output#*Using traffic with the following read-write ratios}

    #data=$(handle_mlc_output "${output}")
    peak_all_reads=$(echo $output1 | awk {'print $4'})
    peak_rw_3_1=$(echo $output1 | awk {'print $8'})
    peak_rw_2_1=$(echo $output1 | awk {'print $12'})
    peak_rw_1_1=$(echo $output1 | awk {'print $16'})
    peak_stream_traid=$(echo $output1 | awk {'print $19'})
    echo "Peak: ${peak_all_reads} ${peak_rw_3_1} ${peak_rw_2_1} ${peak_rw_1_1} ${peak_stream_traid}"

    metrics_json_start_array
    local result_json="$(cat << EOF
    {
        "latency_R_ns": {
            "Result" : $loaded_latency_R_ns,
            "Units"  : "ns"
        },
        "latency_W2_ns": {
            "Result" : $loaded_latency_W2_ns,
            "Units"  : "ns"
        },
        "latency_W3_ns": {
            "Result" : $loaded_latency_W3_ns,
            "Units"  : "ns"
        },
        "latency_W5_ns": {
            "Result" : $loaded_latency_W5_ns,
            "Units"  : "ns"
        },
        "latency_W6_ns": {
            "Result" : $loaded_latency_W6_ns,
            "Units"  : "ns"
        },
        "latency_W7_ns": {
            "Result" : $loaded_latency_W7_ns,
            "Units"  : "ns"
        },
        "latency_W8_ns": {
            "Result" : $loaded_latency_W8_ns,
            "Units"  : "ns"
        },
        "latency_R_bw": {
            "Result" : $loaded_latency_R_bw,
            "Units"  : "MB/s"
        },
        "latency_W2_bw": {
            "Result" : $loaded_latency_W2_bw,
            "Units"  : "MB/s"
        },
        "latency_W3_bw": {
            "Result" : $loaded_latency_W3_bw,
            "Units"  : "MB/s"
        },
        "latency_W5_bw": {
            "Result" : $loaded_latency_W5_bw,
            "Units"  : "MB/s"
        },
        "latency_W6_bw": {
            "Result" : $loaded_latency_W6_bw,
            "Units"  : "MB/s"
        },
        "latency_W7_bw": {
            "Result" : $loaded_latency_W7_bw,
            "Units"  : "MB/s"
        },
        "latency_W8_bw": {
            "Result" : $loaded_latency_W8_bw,
            "Units"  : "MB/s"
        },
        "peak_all_reads": {
            "Result" : $peak_all_reads,
            "Units"  : "MB/s"
        },
        "peak_rw_3_1": {
            "Result" : $peak_rw_3_1,
            "Units"  : "MB/s"
        },
        "peak_rw_2_1": {
            "Result" : $peak_rw_2_1,
            "Units"  : "MB/s"
        },
        "peak_rw_1_1": {
            "Result" : $peak_rw_1_1,
            "Units"  : "MB/s"
        },
        "peak_stream_traid": {
            "Result" : $peak_stream_traid,
            "Units"  : "MB/s"
        }
    }
EOF
)"
    metrics_json_add_array_element "$result_json"
    metrics_json_end_array "Results"
    metrics_json_save
    clean_env_ctr
}

run_mlc_ctr