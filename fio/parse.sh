#!/bin/bash

set -e

CURRENT_DIR="$(dirname "$(readlink -f "$0")")"
source $CURRENT_DIR/func.sh

if [ -z $1 ];
then
        echo Require FIO output prefix
        exit 1
fi

PREFIX=${1}
OUTPUT_IOPS=${PREFIX}-iops.json
OUTPUT_BW=${PREFIX}-bandwidth.json
OUTPUT_LAT=${PREFIX}-latency.json

if [ ! -f "$OUTPUT_IOPS" ]; then
        echo "$OUTPUT_IOPS doesn't exist"
else
        parse_iops $OUTPUT_IOPS
fi

if [ ! -f "$OUTPUT_BW" ]; then
        echo "$OUTPUT_BW doesn't exist"
else
        parse_bw $OUTPUT_BW
fi

if [ ! -f "$OUTPUT_LAT" ]; then
        echo "$OUTPUT_LAT doesn't exist"
else
        parse_lat $OUTPUT_LAT
fi

RESULT=${1}.summary

QUICK_MODE_TEXT="QUICK MODE: DISABLED"
if [ -n "$QUICK_MODE" ]; then
	QUICK_MODE_TEXT="QUICK MODE ENABLED"
fi

SIZE_TEXT="SIZE: 10g"
if [ -n "$SIZE" ]; then
	SIZE_TEXT="SIZE: $SIZE"
fi

SUMMARY="
=====================
FIO Benchmark Summary
For: $PREFIX
$SIZE_TEXT
$QUICK_MODE_TEXT
=====================
"

printf -v cxt "IOPS\n$FMT$FMT$FMT$FMT\n" \
	"Random Read:" \
	"$(commaize $RAND_READ_IOPS) (sys/usr cpu: $SYS_CPU_PCT_RAND_READ_IOPS% / $USR_CPU_PCT_RAND_READ_IOPS%)" \
        "Random Write:" \
	"$(commaize $RAND_WRITE_IOPS) (sys/usr cpu: $SYS_CPU_PCT_RAND_WRITE_IOPS% / $USR_CPU_PCT_RAND_WRITE_IOPS%)" \
	"Sequential Read:" \
	"$(commaize $SEQ_READ_IOPS) (sys/usr cpu: $SYS_CPU_PCT_SEQ_READ_IOPS% / $USR_CPU_PCT_SEQ_READ_IOPS%)" \
        "Sequential Write:" \
	"$(commaize $SEQ_WRITE_IOPS) (sys/usr cpu: $SYS_CPU_PCT_SEQ_WRITE_IOPS% / $USR_CPU_PCT_SEQ_WRITE_IOPS%)"
SUMMARY+=$cxt

printf -v cxt "Bandwidth in KiB/sec\n$FMT$FMT$FMT$FMT\n"\
	"Random Read:" \
        "$(commaize $RAND_READ_BW) (sys/usr cpu: $SYS_CPU_PCT_RAND_READ_BW% / $USR_CPU_PCT_RAND_READ_BW%)" \
        "Random Write:" \
        "$(commaize $RAND_WRITE_BW) (sys/usr cpu: $SYS_CPU_PCT_RAND_WRITE_BW% / $USR_CPU_PCT_RAND_WRITE_BW%)" \
	"Sequential Read:" \
        "$(commaize $SEQ_READ_BW) (sys/usr cpu: $SYS_CPU_PCT_SEQ_READ_BW% / $USR_CPU_PCT_SEQ_READ_BW%)" \
        "Sequential Write:" \
        "$(commaize $SEQ_WRITE_BW) (sys/usr cpu: $SYS_CPU_PCT_SEQ_WRITE_BW% / $USR_CPU_PCT_SEQ_WRITE_BW%)"
SUMMARY+=$cxt

printf -v cxt "Latency in ns\n$FMT$FMT$FMT$FMT\n"\
	"Random Read:" \
        "$(commaize $RAND_READ_LAT) (sys/usr cpu: $SYS_CPU_PCT_RAND_READ_LAT% / $USR_CPU_PCT_RAND_READ_LAT%)" \
        "Random Write:" \
        "$(commaize $RAND_WRITE_LAT) (sys/usr cpu: $SYS_CPU_PCT_RAND_WRITE_LAT% / $USR_CPU_PCT_RAND_WRITE_LAT%)" \
	"Sequential Read:" \
        "$(commaize $SEQ_READ_LAT) (sys/usr cpu: $SYS_CPU_PCT_SEQ_READ_LAT% / $USR_CPU_PCT_SEQ_READ_LAT%)" \
        "Sequential Write:" \
        "$(commaize $SEQ_WRITE_LAT) (sys/usr cpu: $SYS_CPU_PCT_SEQ_WRITE_LAT% / $USR_CPU_PCT_SEQ_WRITE_LAT%)"
SUMMARY+=$cxt

echo "$SUMMARY" > $RESULT
cat $RESULT
