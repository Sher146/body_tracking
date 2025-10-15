#!/bin/bash

# ���徵�����ƺͱ�ǩ
IMAGE_NAME="body_tracking"
IMAGE_TAG="latest"

# ��龵���Ƿ����
if ! docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "${IMAGE_NAME}:${IMAGE_TAG}"; then
    echo "Docker ���� ${IMAGE_NAME}:${IMAGE_TAG} �����ڣ���ʼ����..."
    chmod +x build_image.sh
    ./build_image.sh
    if [ $? -ne 0 ]; then
        echo "���񹹽�ʧ�ܣ��˳���"
        exit 1
    fi
fi

echo "���� Docker ����..."

# ����������֧�ֹ��ر���ģ���ļ�������
docker run --platform linux/arm64 \
    -it \
    --rm \
    --name body_tracking_container \
    -v $(pwd)/app/models:/app/app/models \
    -v $(pwd)/output:/app/output \
    ${IMAGE_NAME}:${IMAGE_TAG}

echo "�������˳���"
