#!/bin/bash

export TIMEFORMAT="%R,%U,%S"
RUNS=5

function bazel_benchmark() {
    runs=$1
    shift
    data_file=$1
    shift
    log=$1
    shift

    echo "Data file: ${data_file}"
    echo "Bazel log: ${log}"

    for i in 1..$runs
    do
        echo "Running bazel build ${i}/${runs}: ${@}"
        bazel_single_run $data_file $@ 2>&1 >> $log
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
    { time bazel build $@ ; } 2>> $data_file

    for i in 1..3
    do
        bazel info used-heap-size-after-gc
    done
    bazel info used-heap-size-after-gc >> $data_file
}

bazel_benchmark $RUNS /tmp/bazel.data /tmp/bazel.log build //:flat