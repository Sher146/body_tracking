#!/bin/bash

# 定义镜像名称和标签
IMAGE_NAME="body_tracking"
IMAGE_TAG="latest"

# 构建 Docker 镜像
echo "开始构建 Docker 镜像: ${IMAGE_NAME}:${IMAGE_TAG}"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
    echo "Docker 镜像构建成功: ${IMAGE_NAME}:${IMAGE_TAG}"
else
    echo "Docker 镜像构建失败。"
    exit 1
fi
