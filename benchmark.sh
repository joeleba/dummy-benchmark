#!/bin/bash

DATA_DIR=/tmp/benchmark
CLK_TCK=$(getconf CLK_TCK)

mkdir -p $DATA_DIR

# Should be invoke in a subshell since we're changing the working directory.
function benchmark() {
    project=$1
    shift
    runs=$1
    shift
    label=$1
    shift
    time_started=$(date '+%Y%m%d_%H%M%S')
    data_file="${DATA_DIR}/${project}-${label}-${time_started}.out"
    log="${DATA_DIR}/${project}-${label}-${time_started}.log"

    cd $project

    echo "Data file: ${data_file}"
    echo "Bazel/Buck2 log: ${log}"

    for (( i=1; i<=runs; i++ )) 
    do
        echo "[bazel] Run $i/$runs: ${@}"
        bazel_single_run $data_file $log $@ &>/dev/null
	tail -n 1 $data_file

        echo "[buck2] Run $i/$runs: ${@}"
        buck2_single_run $data_file $log $@ &> /dev/null
	tail -n 1 $data_file
    done

    echo "FINAL RESULT:"
    cat $data_file
}

function bazel_single_run() {
    data_file=$1
    shift
    log=$1
    shift

    # Clean
    bazel clean --expunge

    # Actual run
    /usr/bin/time -f '%e %M' bazel build --spawn_strategy=standalone $@ >> $log 2>&1
    exit_code=$?
    PID=$(bazel info server_pid)

    wall_time=$(tail -n -1 $log | awk '{ print $1 }')
    utime=$(cat /proc/$PID/stat | awk "{ print \$14/$CLK_TCK }")
    stime=$(cat /proc/$PID/stat | awk "{ print \$15/$CLK_TCK }")
    max_res_size_mb=$(tail -n -1 $log | awk 'match($2, /[0-9]+/, arr) { print arr[0]/1024}')
    retained_mem_pmap_mb=$(pmap ${PID} | grep total | awk 'match($0, /[0-9]+/, arr) { print arr[0]/1024 }')

    for j in {1..3}
    do
        bazel info used-heap-size-after-gc
    done
    retained_mem_jvm_mb=$(bazel info used-heap-size-after-gc | awk 'match($0, /[0-9]+/, arr) { print arr[0] }')
    
    printf "[bazel] wall=$wall_time, cpu=$utime, system=$stime, exit_code=$exit_code, max_res_size_mb=$max_res_size_mb, retained_mem_pmap_mb=$retained_mem_pmap_mb, retained_mem_jvm_mb=$retained_mem_jvm_mb\n" >> $data_file
}

function buck2_single_run() {
    data_file=$1
    shift
    log=$1
    shift

    # Clean
    buck2 clean
    buck2 killall

    # Actual run
    /usr/bin/time -f '%e %M' buck2 build $@ >> $log 2>&1
    exit_code=$?
    PID=$(buck2 status | grep pid | awk 'match($0, /[0-9]+/, arr) { print arr[0] }')

    wall_time=$(tail -n -1 $log | awk '{ print $1 }')
    utime=$(cat /proc/$PID/stat | awk "{ print \$14/$CLK_TCK }")
    stime=$(cat /proc/$PID/stat | awk "{ print \$15/$CLK_TCK }")
    max_res_size_mb=$(tail -n -1 $log | awk 'match($2, /[0-9]+/, arr) { print arr[0]/1024}')
    retained_mem_pmap_mb=$(pmap ${PID} | grep total | awk 'match($0, /[0-9]+/, arr) { print arr[0]/1024 }')

    printf "[buck2] wall=$wall_time, cpu=$utime, system=$stime, exit_code=$exit_code, max_res_size_mb=$max_res_size_mb, retained_mem_pmap_mb=$retained_mem_pmap_mb\n" >> $data_file
}

(benchmark genrule-project 10 flat //:flat)
(benchmark genrule-project 5 chain //:chain)
(benchmark genrule-project 5 longtail //:flat //:chain)
(benchmark genrule-project 3 longwide //:longwide)

(benchmark genrule-project 3 flatwide //flatwide:flatwide)
