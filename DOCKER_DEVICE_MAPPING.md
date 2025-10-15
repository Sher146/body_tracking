# Docker 设备映射问题说明

## 问题描述

在运行 `run_container.sh` 或 `run_container.bat` 时，遇到以下错误：

```
error while creating mount source path '/proc/device-tree/compatible': mkdir /proc/device-tree: no such file or directory
```

## 原因分析

这些设备文件（`/dev/dri/renderD129` 和 `/proc/device-tree/compatible`）是 RK3566 ARM64 开发板特有的：

1. `/dev/dri/renderD129` - GPU 渲染设备文件
2. `/proc/device-tree/compatible` - 设备树兼容性信息文件

在 Windows 主机或普通的 Linux 系统上，这些文件不存在，因此无法进行映射。

## 解决方案

### 方案 1：在目标设备上运行（推荐）

在 RK3566 开发板或支持 RKNN 的 ARM64 设备上运行容器：

```bash
# 在 ARM64 设备上运行
./run_container.sh
```

### 方案 2：修改脚本以适应不同环境

创建一个条件检查，只在目标设备上添加设备映射：

```bash
# 检查是否存在设备文件
if [ -e /dev/dri/renderD129 ]; then
    DEVICE_MAPPINGS="-v /dev/dri/renderD129:/dev/dri/renderD129 --device /dev/dri/renderD129"
fi

if [ -e /proc/device-tree/compatible ]; then
    DEVICE_MAPPINGS="$DEVICE_MAPPINGS -v /proc/device-tree/compatible:/proc/device-tree/compatible"
fi

# 在 docker run 命令中使用 $DEVICE_MAPPINGS
```

### 方案 3：使用 CPU 模式（用于测试）

如果只是想测试应用程序的基本功能，可以创建一个不依赖 GPU 的版本：

```bash
docker run --platform linux/arm64 \
    -it \
    --rm \
    --name body_tracking_container \
    -v $(pwd)/app/models:/app/app/models \
    -v $(pwd)/output:/app/output \
    ${IMAGE_NAME}:${IMAGE_TAG}
```

## 修复后的脚本行为

- 在 Windows 主机上：脚本会尝试运行但跳过不存在的设备文件
- 在 ARM64 开发板上：脚本会正确映射所有必要的设备文件
- 在其他 Linux 系统上：只映射存在的设备文件

## 注意事项

1. RKNN 模型的 GPU 加速功能只能在支持的硬件上使用
2. 在没有 GPU 支持的环境中，可能会回退到 CPU 模式，性能会降低
3. 确保目标设备已安装正确的驱动程序和内核模块
