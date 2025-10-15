@echo off

REM ���徵�����ƺͱ�ǩ
set IMAGE_NAME=body_tracking
set IMAGE_TAG=latest

REM ��龵���Ƿ����
docker images --format "table {{.Repository}}:{{.Tag}}" | findstr "%IMAGE_NAME%:%IMAGE_TAG%" >nul
if %errorlevel% neq 0 (
    echo Docker ���� %IMAGE_NAME%:%IMAGE_TAG% �����ڣ���ʼ����...
    call build_image.sh
    if %errorlevel% neq 0 (
        echo ���񹹽�ʧ�ܣ��˳���
        pause
        exit /b 1
    )
)

echo ���� Docker ����...

REM ����������֧�ֹ��ر���ģ���ļ�������
docker run --platform linux/arm64 ^
    -it ^
    --rm ^
    --name body_tracking_container ^
    -v %cd%\app\models:/app/app/models ^
    -v %cd%\output:/app/output ^
    %IMAGE_NAME%:%IMAGE_TAG%

echo �������˳���
pause
