#!/bin/bash

function ctr_preinstall() {
    #check mlc image exist?
    exist=$(ctr image ls | grep mlc)
    if [ -z "${exist}" ]; then
        ctr image import mlc.tar
    fi
}

function ctr_run_a_mlc_case() {
    mlc_cmd=$1
    
    sync
    echo 3 > /proc/sys/vm/drop_caches
    output=`ctr run --runtime io.containerd.run.kata.v2 --rm docker.io/library/mlc:v1 mlc /bin/bash -c "${mlc_cmd}"`
    sleep 10
    
    echo ${output}
}

k8s_check_pod_status() {
    pod_name=$1
    ret=0
    cnt=0
    while [ $cnt -lt 6 ]; do
        status=`kubectl get pods | grep $pod_name | awk '{print $3}'`
        if [[ "${status}" == "Running" ]]; then
            ret=1
            break
        else
            cnt=$cnt + 1
            sleep 10
        fi
    done

    echo $ret
}

k8s_create_pod() {
    echo "$# $@"
    pod_name=$1
    yaml_file=$2

    is_exist=`check_pod_status $pod_name`
    echo "check $is_exist"

    if [ $is_exist == 1 ];
    then
        echo "Pod $pod_name is already created."
    else
        kubectl create -f $yaml_file
        check_pod_status $pod_name
    fi

    echo  "kubectl cp $local_mlc $pod_name:/usr/bin/"
    #copy mlc to /usr/bin/
    kubectl cp $local_mlc $pod_name:/usr/bin/
}

function k8s_run_a_mlc_case() {
    mlc_cmd=$1
    
    sync
    echo 3 > /proc/sys/vm/drop_caches
    output=$(kubectl exec ubuntu -- /bin/bash -c "${mlc_cmd}")
    sleep 10
    
    echo ${output}
}

function handle_mlc_output() {
    output=$1
    data=${output#*==========================}
    data1=${data:1}
    data2=$(echo $data1 | sed 's/\t/ /g')
    IFS='[  \t]' read -r -a array <<< "$data2"
    echo ${array[@]}
}

save_config() {
    metrics_json_start_array

    local json="$(cat << EOF
    {
        "testname": "${TEST_NAME}",
		"payload": "${PAYLOAD}",
		"payload_args": "${PAYLOAD_ARGS}",
		"payload_runtime_args": "${PAYLOAD_RUNTIME_ARGS}",
		"payload_sleep": ${PAYLOAD_SLEEP},
		"max_containers": ${MAX_NUM_CONTAINERS},
		"max_memory_consumed": "${MAX_MEMORY_CONSUMED}",
		"min_memory_free": "${MIN_MEMORY_FREE}",
		"dump_caches": "${DUMP_CACHES}"
    }
EOF
)"
    metrics_json_add_array_element "$json"
    metrics_json_end_array "Config"
}