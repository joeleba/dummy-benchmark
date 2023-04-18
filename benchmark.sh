#!/bin/bash

RUNS=5
DATA_DIR=/tmp/benchmark

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
	echo "[bazel] res: $(tail -n 1 $data_file)"

        echo "[buck2] Run $i/$runs: ${@}"
        buck2_single_run $data_file $log $@ &> /dev/null
	echo "[buck2] res: $(tail -n 1 $data_file)"
    done

    echo "FINAL RESULT:"
    cat $data_file
}

function bazel_single_run() {
    data_file=$1
    shift
    log=$1
    shift
    # Warmup
    bazel build $@

    # Clean
    bazel clean --expunge

    # Actual run
    /usr/bin/time -f 'wall=%e, cpu=%U, system=%S, max_res_size_mb=%M, ' bazel build $@ > $log 2>&1
    exit_code=$?
    tail -n -1 $log | awk 'match($4, /[0-9]+/, arr) { print $1, $2, $3, "max_res_size_mb=" arr[0]/1024 ", "}' >> $data_file
    # remove the \n
    truncate -s -1 $data_file
    printf "exit_code=$exit_code, " >> $data_file

    PID=$(bazel info server_pid)
    printf "retained_mem_pmap_mb=$(pmap ${PID} | grep total | awk 'match($0, /[0-9]+/, arr) { print arr[0]/1024 ", " }')" >> $data_file

    for j in {1..3}
    do
        bazel info used-heap-size-after-gc
    done
    printf "retained_mem_mb_jvm=$(bazel info used-heap-size-after-gc | awk 'match($0, /[0-9]+/, arr) { print arr[0] }')\n" >> $data_file
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
    /usr/bin/time -f 'wall=%e, cpu=%U, system=%S, max_res_size_mb=%M, ' buck2 build $@ > $log 2>&1
    exit_code=$?
    tail -n -1 $log | awk 'match($4, /[0-9]+/, arr) { print $1, $2, $3, "max_res_size_mb=" arr[0]/1024 ", "}' >> $data_file
    # remove the \n
    truncate -s -1 $data_file
    printf "exit_code=$exit_code, " >> $data_file

    PID=$(buck2 status | grep pid | awk 'match($0, /[0-9]+/, arr) { print arr[0] }')
    
    printf "retained_mem_pmap_mb=$(pmap ${PID} | grep total | awk 'match($0, /[0-9]+/, arr) { print arr[0]/1024 }')\n" >> $data_file
}

(benchmark genrule-project 5 flat //:flat)
(benchmark genrule-project 5 chain //:chain)
(benchmark genrule-project 5 longwide //:longwide)
(benchmark genrule-project 5 longtail //:flat //:chain)
