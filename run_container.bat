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

REM 运行容器，支持挂载本地模型文件和配置
docker run --platform linux/arm64 ^
    -it ^
    --rm ^
    --name body_tracking_container ^
    -v %cd%\app\models:/app/app/models ^
    -v %cd%\output:/app/output ^
    %IMAGE_NAME%:%IMAGE_TAG%

echo 容器已退出。
pause
