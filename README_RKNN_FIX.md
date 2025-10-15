# RKNN ģ�����������

## ��������
����ʱ���� `ModuleNotFoundError: No module named 'rknn'` ����

## ����ԭ��
RKNN (Rockchip Neural Network) ���߰�ֻ���� Linux aarch64 �ܹ������У�����ֱ���� Windows �������ܹ��ϰ�װ��

## �������

### ���� 1��ʹ�� Docker �������Ƽ���

#### ǰ������
1. ��װ������ Docker Desktop
2. ȷ������ϵͳ֧������ ARM64 ����

#### ����
1. **���� Docker ����**��
   ```bash
   # �� Windows ��
   build_image.sh
   
   # ����ʹ�� PowerShell
   docker build --platform linux/arm64 -t body_tracking:latest .
   ```

2. **��������**��
   ```bash
   # Windows ������ű�
   run_container.bat
   
   # �����ֶ�����
   docker run --platform linux/arm64 -it --rm ^
     -v %cd%\app\models:/app/app/models ^
     -v %cd%\output:/app/output ^
     body_tracking:latest
   ```

### ���� 2���ֶ���װ���������� Linux aarch64��

������� RK3566 ��������ֱ�����У�

```bash
# ��װ RKNN toolkit
pip install rknn_toolkit_lite2-1.6.0-cp311-cp311-linux_aarch64.whl

# ���ߴ�Դ�밲װ�������Դ�룩
# pip install rknn_toolkit_lite2
```

### ���� 3���޸Ĵ�����֧��ģ�⻷�������������ã�

�����ֻ������Դ����߼�������Ҫʵ�ʵ� RKNN ����

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
            # ����ģ������
            import numpy as np
            return [np.zeros((1, 56, 8, 8)), np.zeros((1, 56, 16, 16)), np.zeros((1, 56, 32, 32)), np.zeros((1, 51, 17, 17))]
        def release(self):
            if self.verbose:
                print("Mock releasing RKNN")
```

## ��֤��װ

### �� Docker ��������֤
```bash
# ��������
docker run --platform linux/arm64 -it body_tracking:latest /bin/bash

# ��� RKNN ģ��
python -c "from rknn.api import RKNN; print('RKNN module imported successfully')"
```

### ���ϵͳ�ܹ�
```bash
# ��鵱ǰϵͳ�ܹ�
uname -m

# ��� Python �汾
python --version
```

## ��������

### Q: Ϊʲô����ֱ���� Windows �ϰ�װ RKNN��
A: RKNN �� Rockchip ��˾Ϊ�� ARM ������������ר�������߰���ֻ���� Linux aarch64 ���������С�

### Q: Docker ����ʧ����ô�죿
A: ȷ����
1. Docker Desktop ��������
2. ֧�� `--platform linux/arm64` ����
3. ����������������������������

### Q: ��������ʱ��Ȼ��ʾ�Ҳ��� RKNN ģ�飿
A: ��飺
1. �Ƿ�ʹ������ȷ��ƽ̨���� `--platform linux/arm64`
2. wheel �ļ��Ƿ���ȷ���Ƶ�������
3. �����������Ƿ��д�����Ϣ

## ��Ŀ�ļ�˵��

- `Dockerfile`: ���� RKNN ģ�鰲װ����
- `rknn_toolkit_lite2-1.6.0-cp311-cp311-linux_aarch64.whl`: RKNN ���߰���װ�ļ�
- `build_image.sh`: Docker ���񹹽��ű�
- `run_container.bat`: Windows ���������ű�
- `run_container.sh`: Linux/Mac ���������ű�

## ��ϵ֧��

���������Ȼ���ڣ����飺
1. Docker Desktop ��־
2. ����������־
3. ϵͳ�ܹ�������
