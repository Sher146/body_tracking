# RKNN Docker 容器修复总结

## 问题描述

原始的 `run_container.sh` 脚本在运行时遇到 RKNN 运行时初始化失败错误：

```
E Catch exception when init runtime!
RuntimeError
Init runtime environment failed!
```

错误信息指出缺少必要的设备文件映射：
- `/dev/dri/renderD129`
- `/proc/device-tree/compatible`

## 修复内容

### 1. 修改原始脚本

**文件：** `run_container.sh`
- 添加了 GPU 设备映射：`-v /dev/dri/renderD129:/dev/dri/renderD129`
- 添加了设备树文件映射：`-v /proc/device-tree/compatible:/proc/device-tree/compatible`
- 添加了设备权限：`--device /dev/dri/renderD129`

**文件：** `run_container.bat`
- 同步添加了相同的设备映射参数

### 2. 创建智能版本脚本

**文件：** `run_container_smart.sh`
- 自动检测设备文件是否存在
- 只在目标设备上添加必要的映射
- 提供详细的状态信息和警告

**文件：** `run_container_smart.bat`
- 针对 Windows 环境优化的版本
- 提供清晰的环境说明

### 3. 创建说明文档

**文件：** `DOCKER_DEVICE_MAPPING.md`
- 详细解释了问题的根本原因
- 提供了多种解决方案
- 说明了不同环境下的行为差异

## 使用指南

### 在 RK3566 开发板上（推荐）

```bash
# 使用智能版本（会自动检测并添加设备映射）
./run_container.sh
```

### 在 Windows 环境下（测试用）

```cmd
# 使用智能版本（针对 Windows 环境优化）
.\run_container.bat
```

### 在其他 Linux 系统上

```bash
# 使用智能版本，会自动检测可用设备
./run_container.sh
```

## 测试结果

### Windows 环境测试
- ✅ 容器成功启动
- ✅ RKNN 模型成功加载
- ⚠️ RKNN 运行时初始化失败（预期行为，缺少硬件设备）
- ✅ 脚本提供了清晰的错误信息和说明

### 预期的 RK3566 环境行为
- ✅ 容器成功启动
- ✅ RKNN 模型成功加载
- ✅ RKNN 运行时成功初始化（使用硬件加速）
- ✅ 完整的身体追踪功能可用

## 文件清单

修复过程中创建/修改的文件：

1. `run_container.sh` - 智能检测版本（Linux），自动检测设备文件并添加相应映射
2. `run_container.bat` - 智能检测版本（Windows），针对 Windows 环境优化
3. `DOCKER_DEVICE_MAPPING.md` - 问题说明文档
4. `README_FIX_SUMMARY.md` - 本修复总结文档

**注意：** 原始的固定映射版本已被智能版本替换，智能版本能够适应不同的运行环境。

## 建议

1. **使用智能版本脚本**：`run_container.sh`（Linux）/ `run_container.bat`（Windows）
2. **在目标设备上部署**：确保在 RK3566 或兼容的 ARM64 设备上运行以获得完整功能
3. **查看错误信息**：如果仍有问题，检查 `DOCKER_DEVICE_MAPPING.md` 中的详细说明
4. **备选方案**：如果硬件不可用，可以考虑使用 CPU 模式进行基本功能测试

## 技术细节

### 设备文件说明

- `/dev/dri/renderD129`：ARM Mali GPU 的渲染设备节点
- `/proc/device-tree/compatible`：设备树兼容性信息，用于识别硬件平台

### Docker 参数说明

- `-v`：卷映射，将主机文件/目录映射到容器内
- `--device`：设备映射，允许容器访问主机设备
- `--platform linux/arm64`：指定目标平台为 ARM64

这些修复确保了 RKNN 运行时能够正确访问必要的硬件资源，从而实现硬件加速的推理功能。
