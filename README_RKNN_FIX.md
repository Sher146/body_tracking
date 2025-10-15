# RKNN 模块错误解决方案

## 问题描述
运行时出现 `ModuleNotFoundError: No module named 'rknn'` 错误。

## 根本原因
1. RKNN (Rockchip Neural Network) 工具包只能在 Linux aarch64 架构上运行，不能直接在 Windows 或其他架构上安装。
2. 安装的 RKNN toolkit lite2 包使用的是 `rknnlite.api.RKNNLite` 类，而不是 `rknn.api.RKNN`。
3. Python 模块导入路径问题。

## 已实施的解决方案

### 修复内容
1. **Dockerfile 修复**：
   - 添加了 `--platform=linux/arm64` 参数确保使用正确的架构
   - 移除了 RKNN 安装的容错机制，确保安装失败时能及时发现问题

2. **代码导入修复**：
   - 将 `from rknn.api import RKNN` 改为 `from rknnlite.api import RKNNLite as RKNN`
   - 将 `from app.utils.detection_utils import` 改为 `from utils.detection_utils import`

3. **验证结果**：
   - RKNN 模块现在可以正确导入和初始化
   - 应用程序可以正常启动并显示帮助信息

## 解决方案

### 方法 1：使用 Docker 容器（推荐）

#### 前提条件
1. 安装并启动 Docker Desktop
2. 确保您的系统支持运行 ARM64 容器

#### 步骤
1. **构建 Docker 镜像**：
   ```bash
   # 在 Windows 上
   build_image.sh
   
   # 或者使用 PowerShell
   docker build --platform linux/arm64 -t body_tracking:latest .
   ```

2. **运行容器**：
   ```bash
   # Windows 批处理脚本
   run_container.bat
   
   # 或者手动运行
   docker run --platform linux/arm64 -it --rm ^
     -v %cd%\app\models:/app/app/models ^
     -v %cd%\output:/app/output ^
     body_tracking:latest
   ```

### 方法 2：手动安装（仅适用于 Linux aarch64）

如果您在 RK3566 开发板上直接运行：

```bash
# 安装 RKNN toolkit
pip install rknn_toolkit_lite2-1.6.0-cp311-cp311-linux_aarch64.whl

# 或者从源码安装（如果有源码）
# pip install rknn_toolkit_lite2
```

### 方法 3：修改代码以支持模拟环境（开发测试用）

如果您只是想测试代码逻辑而不需要实际的 RKNN 推理：

```python
try:
    from rknn.api import RKNN
except ImportError:
    print("Warning: RKNN not available, using mock implementation")
    class RKNN:
        def __init__(self, verbose=False):
            self.verbose = verbose
        def load_rknn(self, path):
            if self.verbose:
                print(f"Mock loading RKNN model: {path}")
            return 0
        def init_runtime(self, target=None, device_id=None):
            if self.verbose:
                print(f"Mock initializing runtime for target: {target}")
            return 0
        def inference(self, inputs):
            # 返回模拟数据
            import numpy as np
            return [np.zeros((1, 56, 8, 8)), np.zeros((1, 56, 16, 16)), np.zeros((1, 56, 32, 32)), np.zeros((1, 51, 17, 17))]
        def release(self):
            if self.verbose:
                print("Mock releasing RKNN")
```

## 验证安装

### 在 Docker 容器中验证
```bash
# 进入容器
docker run --platform linux/arm64 -it body_tracking:latest /bin/bash

# 检查 RKNN 模块
python -c "from rknn.api import RKNN; print('RKNN module imported successfully')"
```

### 检查系统架构
```bash
# 检查当前系统架构
uname -m

# 检查 Python 版本
python --version
```

## 常见问题

### Q: 为什么不能直接在 Windows 上安装 RKNN？
A: RKNN 是 Rockchip 公司为其 ARM 处理器开发的专用推理工具包，只能在 Linux aarch64 环境中运行。

### Q: Docker 构建失败怎么办？
A: 确保：
1. Docker Desktop 正在运行
2. 支持 `--platform linux/arm64` 参数
3. 网络连接正常（用于下载依赖）

### Q: 容器运行时仍然提示找不到 RKNN 模块？
A: 检查：
1. 是否使用了正确的平台参数 `--platform linux/arm64`
2. wheel 文件是否正确复制到容器中
3. 构建过程中是否有错误信息

## 项目文件说明

- `Dockerfile`: 包含 RKNN 模块安装配置
- `rknn_toolkit_lite2-1.6.0-cp311-cp311-linux_aarch64.whl`: RKNN 工具包安装文件
- `build_image.sh`: Docker 镜像构建脚本
- `run_container.bat`: Windows 容器启动脚本
- `run_container.sh`: Linux/Mac 容器启动脚本

## 联系支持

如果问题仍然存在，请检查：
1. Docker Desktop 日志
2. 容器构建日志
3. 系统架构兼容性
