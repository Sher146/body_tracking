# ʹ�ùٷ� Python ������Ϊ�������񣬸���Ϊ Debian Bullseye
FROM python:3.11-slim-bullseye

# ���ù���Ŀ¼
WORKDIR /app

# ���� Debian ����ԴΪ�����ƣ��Խ����������
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
    echo "deb http://mirrors.aliyun.com/debian/ bullseye main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list
    # �Ƴ��� bullseye-backports �ֿ�

# ��װϵͳ���������� OpenCV ����Ŀ�
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libgl1-mesa-glx \
    libsm6 \
    libxext6 \
    libxrender1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# ���� requirements.txt ����װ Python ����
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --no-deps --platform linux/aarch64 --target /usr/local/lib/python3.11/site-packages

### RKNN SDK ����ʱ�⼯�� ###
# ��һ����Ҫ���ֶ��� RKNN SDK �������� RK3566 ������ʱ���ļ�
# (���� librknn_api.so, rknn_server ��) ���Ƶ�������ĿĿ¼�С�
# ��������Ŀ��Ŀ¼����һ�����ļ��У����� 'rknn_sdk_libs'��������������ļ��������С�
# Ȼ��ȡ��ע�Ͳ��޸��������Ը�����Щ�ļ��������С�
# ���磺
# COPY rknn_sdk_libs/ /usr/local/lib/
# RUN ldconfig

# ��� RKNN ����ʱ����Ҫ�ض��Ļ������������ڴ˴�����
# ���磺
# ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
### RKNN SDK ����ʱ�⼯�ɽ��� ###

# ����Ӧ�ó�������ģ���ļ�
COPY app/ ./app/

# ������������ʱִ�е�����
# Ĭ������ main.py���û�����ͨ�� Docker run ����Ǵ˲���
CMD ["python", "app/main.py"]
