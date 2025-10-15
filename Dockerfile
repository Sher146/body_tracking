# 使用官方 Python 镜像作为基础镜像，更新为 Debian Bullseye
FROM python:3.11-slim-bullseye

# 设置工作目录
WORKDIR /app

# 更换 Debian 镜像源为阿里云，以解决下载问题
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
    echo "deb http://mirrors.aliyun.com/debian/ bullseye main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list
    # 移除了 bullseye-backports 仓库

# 安装系统依赖，包括 OpenCV 所需的库
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libgl1-mesa-glx \
    libsm6 \
    libxext6 \
    libxrender1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 复制 requirements.txt 并安装 Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --no-deps --platform linux/aarch64 --target /usr/local/lib/python3.11/site-packages

### RKNN SDK 运行时库集成 ###
# 这一步需要您手动将 RKNN SDK 中适用于 RK3566 的运行时库文件
# (例如 librknn_api.so, rknn_server 等) 复制到您的项目目录中。
# 建议在项目根目录创建一个子文件夹，例如 'rknn_sdk_libs'，并将所有相关文件放入其中。
# 然后，取消注释并修改以下行以复制这些文件到容器中。
# 例如：
# COPY rknn_sdk_libs/ /usr/local/lib/
# RUN ldconfig

# 如果 RKNN 运行时库需要特定的环境变量，请在此处设置
# 例如：
# ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
### RKNN SDK 运行时库集成结束 ###

# 复制应用程序代码和模型文件
COPY app/ ./app/

# 定义容器启动时执行的命令
# 默认运行 main.py，用户可以通过 Docker run 命令覆盖此参数
CMD ["python", "app/main.py"]
