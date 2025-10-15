# 使用官方 Python 镜像作为基础镜像，更新为 Debian Bullseye
FROM python:3.11-slim
# 设置工作目录
WORKDIR /app

# 更换 Debian 镜像源为阿里云，以解决下载问题
# RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
#     echo "deb http://mirrors.aliyun.com/debian/ bullseye main contrib non-free" > /etc/apt/sources.list && \
#     echo "deb http://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
#     echo "deb http://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list && \
    # 移除了 bullseye-backports 仓库
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libsm6 \
    libxext6 \
    libxrender1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 复制 requirements.txt 并安装 Python 依赖
COPY rknn_whl/ ./rknn_whl/
COPY requirements.txt .

# 先安装 requirements.txt 中的依赖
RUN pip install --no-cache-dir -r requirements.txt

# 然后安装 RKNN toolkit
RUN pip install --no-cache-dir rknn_whl/rknn_toolkit_lite2-1.6.0-cp311-cp311-linux_aarch64.whl || echo "RKNN toolkit installation failed - this is expected if not on aarch64 platform"

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

# 设置环境变量（可选的默认值）
ENV MODEL_PATH=/app/app/models/yolov8_pose.rknn
ENV VIDEO_SOURCE=rtsp://admin:123456@192.168.1.102:554/h265/ch1/main/av_stream
ENV TARGET=rk3566
ENV INPUT_SIZE=640,640
ENV NMS_THRESHOLD=0.4
ENV OBJ_THRESHOLD=0.5
ENV KPT_THRESHOLD=0.3

# 定义容器启动时执行的命令
# 使用环境变量作为默认参数，用户可以通过 docker run -e 覆盖
CMD python app/main.py \
    --model_path=${MODEL_PATH} \
    --video_source=${VIDEO_SOURCE} \
    --target=${TARGET} \
    --input_size=${INPUT_SIZE} \
    --nms_threshold=${NMS_THRESHOLD} \
    --obj_threshold=${OBJ_THRESHOLD} \
    --kpt_threshold=${KPT_THRESHOLD}
