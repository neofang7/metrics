#!/bin/bash

local_mlc=$1
duration=$2
guest_yaml=$3
guest_mlc="/usr/bin/mlc"
cpuset="0-6"

declare -A cases
cases["local_100R_BW"]="mlc --loaded_latency -t${duration} -d0 -R && wait"
cases["local_3R1W_BW"]="mlc --loaded_latency -t${duration} -d0 -W3 && wait"

check_pod_status() {
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

create_pod() {
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

run_a_mlc_case() {
    mlc_cmd=$1
    
    #echo "mlc cmd: ${mlc_cmd}"
    sync
    echo 3 > /proc/sys/vm/drop_caches
    #echo "kubectl exec ubuntu -- /bin/bash -c "${mlc_cmd}""
    output=$(kubectl exec ubuntu -- /bin/bash -c "${mlc_cmd}")
    sleep 10
    
    echo ${output}
}

handle_mlc_output() {
    output=$1
    data=${output#*==========================}
    data1=${data:1}
    data2=$(echo $data1 | sed 's/\t/ /g')
    IFS='[  \t]' read -r -a array <<< "$data2"
    echo ${array[@]}
}

mlc_test() {
    local_100R_BW="mlc --loaded_latency -t${duration} -d0 -R && wait"
    output=$(run_a_mlc_case "$local_100R_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 100R BW: $data"

    local_3R1W_BW="mlc --loaded_latency -t${duration} -d0 -W3 && wait"
    output=$(run_a_mlc_case "$local_3R1W_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 3R1W BW: $data"

    local_2R1W_BW="mlc --loaded_latency -t${duration} -d0 -W2 && wait"
    output=$(run_a_mlc_case "$local_2R1W_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 2R1W BW: $data"

    local_1R1W_BW="mlc --loaded_latency -t${duration} -d0 -W5 && wait"
    output=$(run_a_mlc_case "$local_1R1W_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 1R1W BW: $data"

    local_2R1WNT_BW="mlc --loaded_latency -t${duration} -d0 -W7 && wait"
    output=$(run_a_mlc_case "$local_2R1WNT_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 2R1W-NT BW: $data"

    local_1R1WNT_BW="mlc --loaded_latency -t${duration} -d0 -W8 && wait"
    output=$(run_a_mlc_case "$local_1R1WNT_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 1R1W-NT BW: $data"

    local_100WNT_BW="mlc --loaded_latency -t${duration} -d0 -W6 && wait"
    output=$(run_a_mlc_case "$local_100WNT_BW")
    data=$(handle_mlc_output "${output}")
    echo "Local 2R1W-NT BW: $data"
}

main() {

    if [ ! -f $guest_yaml ];
    then
        echo "$guest_yaml does not exist."
        exit -1
    fi

    echo "Start guest tdx container..."
    create_pod "ubuntu" $guest_yaml

    mlc_test
}

main
