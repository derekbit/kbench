#!/bin/bash

set -e

CURRENT_DIR="$(dirname "$(readlink -f "$0")")"

TEST_FILE=$1
cd /temp

# cmdline overrides the environment variable
if [ -z "$TEST_FILE" ]; then
    TEST_FILE=$FILE_NAME
fi

if [ -z "$TEST_FILE" ]; then
    echo Require test file name
    exit 1
fi

if [ x"$CPU_IDLE_PROF" = x"enabled" ]; then
    IDLE_PROF="--idle-prof=percpu"
fi

echo TEST_FILE: $TEST_FILE

TEST_OUTPUT=$2
if [ -z "$TEST_OUTPUT" ]; then
    TEST_OUTPUT=$OUTPUT
fi
if [ -z $TEST_OUTPUT ]; then
    TEST_OUTPUT="./test_device"
fi
echo TEST_OUTPUT_PREFIX: $TEST_OUTPUT

TEST_SIZE=$3
if [ -z "$TEST_SIZE" ]; then
    TEST_SIZE=$SIZE
fi
if [ -z "$TEST_SIZE" ]; then
    TEST_SIZE="10g"
fi
echo TEST_SIZE: $TEST_SIZE

if [ -n "$QUICK_MODE" ]; then
    echo "WARN: QUICK_MODE is being deprecated. Use MODE=\"quick\" instead"
    MODE="quick"
fi
if [ -z "$MODE" ]; then
    MODE="full"
fi
echo MODE: $MODE

case $MODE in
    "quick")
        IOPS_FIO="iops-quick.fio"
        BW_FIO="bandwidth-quick.fio"
        LAT_FIO="latency-quick.fio"
        ;;
    "random-read-iops")
        IOPS_FIO="iops-random-read.fio"
        BW_FIO=""
        LAT_FIO=""
        ;;
    "sequential-read-bandwidth")
        IOPS_FIO=""
        BW_FIO="bandwidth-sequential-read.fio"
        LAT_FIO=""
        ;;
    "random-read-latency")
        IOPS_FIO=""
        BW_FIO=""
        LAT_FIO="latency-random-read.fio"
        ;;
    "random-write-iops")
        IOPS_FIO="iops-random-write.fio"
        BW_FIO=""
        LAT_FIO=""
        ;;
    "sequential-write-bandwidth")
        IOPS_FIO=""
        BW_FIO="bandwidth-sequential-write.fio"
        LAT_FIO=""
        ;;
    "random-write-latency")
        IOPS_FIO=""
        BW_FIO=""
        LAT_FIO="latency-random-write.fio"
        ;;
    "full" | "")
        IOPS_FIO="iops.fio"
        BW_FIO="bandwidth.fio"
        LAT_FIO="latency.fio"
        ;;

    *)
        echo "ERROR: unknown mode"
        exit 1
        ;;
esac

if [ -n "$RATE_IOPS" ]; then
    rate_iops_flag="--rate_iops=$RATE_IOPS"
else
    rate_iops_flag=""
fi

if [ -n "$RATE" ]; then
    rate_flag="--rate=$RATE"
else
    rate_flag=""
fi

# Apply per-category workload parameter overrides (bs / iodepth / numjobs)
# by rewriting the corresponding include file in place. Only lines that
# already exist are updated; missing keys are left untouched.
#
# Env vars:
#   IOPS_BS / IOPS_IODEPTH / IOPS_NUMJOBS   -> iops-include.fio
#   BW_BS   / BW_IODEPTH   / BW_NUMJOBS     -> bandwidth-include.fio
#   LAT_BS  / LAT_IODEPTH  / LAT_NUMJOBS    -> lat-include.fio
apply_override() {
    local include_file=$1
    local bs_val=$2
    local iodepth_val=$3
    local numjobs_val=$4

    if [ -n "$bs_val" ]; then
        sed -i "s|^bs=.*|bs=$bs_val|" "$include_file"
        echo "Override: $(basename "$include_file") bs=$bs_val"
    fi
    if [ -n "$iodepth_val" ]; then
        sed -i "s|^iodepth=.*|iodepth=$iodepth_val|" "$include_file"
        echo "Override: $(basename "$include_file") iodepth=$iodepth_val"
    fi
    if [ -n "$numjobs_val" ]; then
        sed -i "s|^numjobs=.*|numjobs=$numjobs_val|" "$include_file"
        echo "Override: $(basename "$include_file") numjobs=$numjobs_val"
    fi
}

apply_override "$CURRENT_DIR/iops-include.fio"      "$IOPS_BS" "$IOPS_IODEPTH" "$IOPS_NUMJOBS"
apply_override "$CURRENT_DIR/bandwidth-include.fio" "$BW_BS"   "$BW_IODEPTH"   "$BW_NUMJOBS"
apply_override "$CURRENT_DIR/lat-include.fio"       "$LAT_BS"  "$LAT_IODEPTH"  "$LAT_NUMJOBS"


TEMP=./temp
OUTPUT_READ_IOPS=${TEST_OUTPUT}-read-iops.json
OUTPUT_WRITE_IOPS=${TEST_OUTPUT}-write-iops.json
OUTPUT_READ_BW=${TEST_OUTPUT}-read-bandwidth.json
OUTPUT_WRITE_BW=${TEST_OUTPUT}-write-bandwidth.json
OUTPUT_READ_LAT=${TEST_OUTPUT}-read-latency.json
OUTPUT_WRITE_LAT=${TEST_OUTPUT}-write-latency.json

keep_running="true"
while [ "$keep_running" == "true" ]; do
    if [ -n "$IOPS_FIO" ]; then
        rm -rf $TEST_FILE

        echo Benchmarking random read iops
        fio $CURRENT_DIR/$IOPS_FIO $IDLE_PROF --section=rand-read-iops --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_READ_IOPS $rate_iops_flag $rate_flag

        echo Benchmarking random write iops
        fio $CURRENT_DIR/$IOPS_FIO $IDLE_PROF --section=rand-write-iops --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_WRITE_IOPS $rate_iops_flag $rate_flag
    fi

    if [ -n "$BW_FIO" ]; then
        rm -rf $TEST_FILE

        echo Benchmarking sequential read bandwidth
        fio $CURRENT_DIR/$BW_FIO $IDLE_PROF --section=seq-read-bandwidth --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_READ_BW $rate_iops_flag $rate_flag
 
        echo Benchmarking sequential write bandwidth
        fio $CURRENT_DIR/$BW_FIO $IDLE_PROF --section=seq-write-bandwidth --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_WRITE_BW $rate_iops_flag $rate_flag
    fi

    if [ -n "$LAT_FIO" ]; then
        rm -rf $TEST_FILE

        echo Benchmarking random read latency
        fio $CURRENT_DIR/$LAT_FIO $IDLE_PROF --section=rand-read-lat --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_READ_LAT $rate_iops_flag $rate_flag

        echo Benchmarking random write latency
        fio $CURRENT_DIR/$LAT_FIO $IDLE_PROF --section=rand-write-lat --filename=$TEST_FILE --size=$TEST_SIZE --output-format=json --output=$OUTPUT_WRITE_LAT $rate_iops_flag $rate_flag
    fi

    if [ -z "$SKIP_PARSE" ]; then
            $CURRENT_DIR/parse.sh $TEST_OUTPUT
    fi

    sleep 1

    if [ "$LONG_RUN" != "true" ]; then
        keep_running="false"
    fi
done

