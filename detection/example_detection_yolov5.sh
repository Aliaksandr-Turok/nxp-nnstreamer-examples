#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2022-2023 NXP

set -x

REALPATH="$(readlink -e "$0")"
BASEDIR="$(dirname "${REALPATH}")/.."
MODELS_DIR="${HOME}/models"

source "${BASEDIR}/common/common_utils.sh"
source "${BASEDIR}/detection/detection_utils.sh"

setup_env

# model and framework dependant variables 
MODEL="${MODELS_DIR}/yolov5n.tflite"

# XXX: remove this latency for i.MX93 NPU

declare -A MODEL_LATENCY_NS
MODEL_LATENCY_NS[CPU]="300000000"
MODEL_LATENCY_NS[GPU]="500000000"
MODEL_LATENCY_NS[NPU]="0"
MODEL_LATENCY=${MODEL_LATENCY_NS[${BACKEND}]}

MODEL_WIDTH=640
MODEL_HEIGHT=640
MODEL_LABELS="${MODELS_DIR}/yolov5n.txt"

FRAMEWORK="tensorflow-lite"

# tensor filter configuration
FILTER_COMMON="tensor_filter framework=${FRAMEWORK} model=${MODEL}"

declare -A FILTER_BACKEND
FILTER_BACKEND[CPU]="${FILTER_COMMON}"
FILTER_BACKEND[CPU]+=" custom=Delegate:XNNPACK,NumThreads:$(nproc --all) !"
FILTER_BACKEND[GPU]="${FILTER_COMMON}"
FILTER_BACKEND[GPU]+=" custom=Delegate:External,ExtDelegateLib:libvx_delegate.so ! "
FILTER_BACKEND[NPU]="${FILTER_COMMON}"
FILTER_BACKEND[NPU]+=" custom=Delegate:External,ExtDelegateLib:libvx_delegate.so ! "
TENSOR_FILTER=${FILTER_BACKEND[${BACKEND}]}

# tensor preprocessing configuration: normalize video for float input models
declare -A PREPROCESS_BACKEND
PREPROCESS_BACKEND[CPU]=""
PREPROCESS_BACKEND[GPU]=""
PREPROCESS_BACKEND[NPU]=""
TENSOR_PREPROCESS=${PREPROCESS_BACKEND[${BACKEND}]}

# tensor decoder configuration: mobilenet ssd without post processing
TENSOR_DECODER="tensor_decoder mode=bounding_boxes"
TENSOR_DECODER+=" option1=yolov5"
TENSOR_DECODER+=" option2=${MODEL_LABELS}"
TENSOR_DECODER+=" option3=0"
TENSOR_DECODER+=" option4=${CAMERA_WIDTH}:${CAMERA_HEIGHT}"
TENSOR_DECODER+=" option5=${MODEL_WIDTH}:${MODEL_HEIGHT} ! "

gst_exec_detection

