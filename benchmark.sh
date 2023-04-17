#!/bin/bash

RUNS=5
DATA_DIR=/tmp/benchmark/

mkdir -p $DATA_DIR

function bazel_benchmark() {
    runs=$1
    shift
    data_file=$1
    shift
    log=$1
    shift

    echo "Data file: ${data_file}"
    echo "Bazel log: ${log}"

    for i in $(seq $runs) 
    do
        echo "Running bazel build ${i}/${runs}: ${@}"
        bazel_single_run $data_file $@ &>> $log
	echo "Result: $(tail -n 5 $data_file)"
    done
}

function bazel_single_run() {
    data_file=$1
    shift
    # Warmup
    bazel build $@

    # Clean
    bazel clean --expunge

    # Actual run
    { time -p bazel build $@ ; } 2>> $data_file
    echo -e "exit_code\t$?" >> $data_file

    for i in 1..3
    do
        bazel info used-heap-size-after-gc
    done
    echo -e "mem\t$(bazel info used-heap-size-after-gc)" >> $data_file
}

bazel_benchmark $RUNS $DATA_DIR/bazel.data $DATA_DIR/bazel.log //:flat
