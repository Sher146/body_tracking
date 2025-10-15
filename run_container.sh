#!/bin/bash

# 定义镜像名称和标签
IMAGE_NAME="body_tracking"
IMAGE_TAG="latest"

# 检查镜像是否存在
if ! docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "${IMAGE_NAME}:${IMAGE_TAG}"; then
    echo "Docker 镜像 ${IMAGE_NAME}:${IMAGE_TAG} 不存在，开始构建..."
    chmod +x build_image.sh
    ./build_image.sh
    if [ $? -ne 0 ]; then
        echo "镜像构建失败，退出。"
        exit 1
    fi
fi

echo "启动 Docker 容器..."

# 初始化设备映射变量
DEVICE_MAPPINGS=""

# 检查并添加 GPU 设备映射
if [ -e /dev/dri/renderD129 ]; then
    echo "检测到 GPU 设备: /dev/dri/renderD129"
    DEVICE_MAPPINGS="$DEVICE_MAPPINGS -v /dev/dri/renderD129:/dev/dri/renderD129 --device /dev/dri/renderD129"
else
    echo "警告: 未检测到 GPU 设备 /dev/dri/renderD129，RKNN 可能无法使用硬件加速"
fi

# 检查并添加设备树文件映射
if [ -e /proc/device-tree/compatible ]; then
    echo "检测到设备树文件: /proc/device-tree/compatible"
    DEVICE_MAPPINGS="$DEVICE_MAPPINGS -v /proc/device-tree/compatible:/proc/device-tree/compatible"
else
    echo "警告: 未检测到设备树文件 /proc/device-tree/compatible"
fi

# 构建完整的 docker run 命令
DOCKER_CMD="docker run --platform linux/arm64 \
    -it \
    --rm \
    --name body_tracking_container \
    -v \$(pwd)/app/models:/app/app/models \
    -v \$(pwd)/output:/app/output \
    $DEVICE_MAPPINGS \
    ${IMAGE_NAME}:${IMAGE_TAG}"

echo "执行命令: $DOCKER_CMD"
eval $DOCKER_CMD

echo "容器已退出。"
