@echo off

REM 定义镜像名称和标签
set IMAGE_NAME=body_tracking
set IMAGE_TAG=latest

REM 检查镜像是否存在
docker images --format "table {{.Repository}}:{{.Tag}}" | findstr "%IMAGE_NAME%:%IMAGE_TAG%" >nul
if %errorlevel% neq 0 (
    echo Docker 镜像 %IMAGE_NAME%:%IMAGE_TAG% 不存在，开始构建...
    call build_image.sh
    if %errorlevel% neq 0 (
        echo 镜像构建失败，退出。
        pause
        exit /b 1
    )
)

echo 启动 Docker 容器...

REM 检查设备文件是否存在（Windows 环境下通常不存在）
set DEVICE_MAPPINGS=

REM 在 Windows 环境下，这些 Linux 设备文件通常不存在
REM 但我们仍然尝试构建命令，让 Docker 来处理错误

echo 注意: 在 Windows 环境下运行，RKNN 硬件加速功能可能不可用
echo 如果需要在 ARM64 设备上使用完整功能，请在目标设备上运行 run_container_smart.sh

REM 运行容器，支持挂载本地模型文件和配置
docker run --platform linux/arm64 ^
    -it ^
    --rm ^
    --name body_tracking_container ^
    -v %cd%\app\models:/app/app/models ^
    -v %cd%\output:/app/output ^
    %DEVICE_MAPPINGS% ^
    %IMAGE_NAME%:%IMAGE_TAG%

echo 容器已退出。
pause
