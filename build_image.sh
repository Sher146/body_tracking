#!/bin/bash

# ���徵�����ƺͱ�ǩ
IMAGE_NAME="body_tracking"
IMAGE_TAG="latest"

# ���� Docker ����
echo "��ʼ���� Docker ����: ${IMAGE_NAME}:${IMAGE_TAG}"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
    echo "Docker ���񹹽��ɹ�: ${IMAGE_NAME}:${IMAGE_TAG}"
else
    echo "Docker ���񹹽�ʧ�ܡ�"
    exit 1
fi
