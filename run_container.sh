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

# 运行容器，支持挂载本地模型文件和配置
docker run --platform linux/arm64 \
    -it \
    --rm \
    --name body_tracking_container \
    -v $(pwd)/app/models:/app/app/models \
    -v $(pwd)/output:/app/output \
    ${IMAGE_NAME}:${IMAGE_TAG}

echo "容器已退出。"
