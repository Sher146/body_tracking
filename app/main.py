# -*- coding: utf-8 -*-
import os
import sys
import time
import numpy as np
import argparse
import cv2

from rknn.api import RKNN
from app.utils.detection_utils import DetectBox, IOU, NMS, sigmoid, softmax, process

CLASSES = ['person']

def letterbox_resize(image, size, bg_color):
    """
    letterbox_resize the image according to the specified size
    :param image: input image, which can be a NumPy array or file path
    :param size: target size (width, height)
    :param bg_color: background filling data 
    :return: processed image
    """
    # ȷ��������ͼ�����飬�������ļ�·������Ƶģʽ���Ѿ���֡���飩
    if image is None:
        print("Error: Input image (frame) is None.")
        sys.exit(1)

    target_width, target_height = size
    image_height, image_width, _ = image.shape

    # Calculate the adjusted image size
    aspect_ratio = min(target_width / image_width, target_height / image_height)
    new_width = int(image_width * aspect_ratio)
    new_height = int(image_height * aspect_ratio)

    # Use cv2.resize() for proportional scaling
    image = cv2.resize(image, (new_width, new_height), interpolation=cv2.INTER_AREA)

    # Create a new canvas and fill it
    result_image = np.ones((target_height, target_width, 3), dtype=np.uint8) * bg_color
    offset_x = (target_width - new_width) // 2
    offset_y = (target_height - new_height) // 2
    result_image[offset_y:offset_y + new_height, offset_x:offset_x + new_width] = image
    return result_image, aspect_ratio, offset_x, offset_y

# ��̬���Ƶ�ɫ�壬���ڹؼ���͹Ǽܵ���ɫ
pose_palette = np.array([[255, 128, 0], [255, 153, 51], [255, 178, 102], [230, 230, 0], [255, 153, 255],
                         [153, 204, 255], [255, 102, 255], [255, 51, 255], [102, 178, 255], [51, 153, 255],
                         [255, 153, 153], [255, 102, 102], [255, 51, 51], [153, 255, 153], [102, 255, 102],
                         [51, 255, 51], [0, 255, 0], [0, 0, 255], [255, 0, 0], [255, 255, 255]],dtype=np.uint8)
# 17���ؼ������ɫ
kpt_color  = pose_palette[[16, 16, 16, 16, 16, 0, 0, 0, 0, 0, 0, 9, 9, 9, 9, 9, 9]]
# �Ǽ����ӹ�ϵ (COCO��ʽ��17���ؼ�����������1��ʼ)
skeleton = [[16, 14], [14, 12], [17, 15], [15, 13], [12, 13], [6, 12], [7, 13], [6, 7], [6, 8], 
            [7, 9], [8, 10], [9, 11], [2, 3], [1, 2], [1, 3], [2, 4], [3, 5], [4, 6], [5, 7]]
# �Ǽ����ߵ���ɫ
limb_color = pose_palette[[9, 9, 9, 9, 7, 7, 7, 0, 0, 0, 0, 0, 16, 16, 16, 16, 16, 16, 16]]

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Yolov8 Pose Python Demo (Video/Camera Stream)', add_help=True)
    # basic params
    parser.add_argument('--model_path', type=str, required=True,
                        help='RKNN model path (.rknn file)')
    parser.add_argument('--video_source', type=str, required=True,
                        help='Video file path (e.g., input.mp4) or camera index (e.g., 0 for default camera).')
    parser.add_argument('--target', type=str,
                        default='rk3566', help='Target RKNPU platform (e.g., rk3588)')
    parser.add_argument('--device_id', type=str,
                        default=None, help='Device ID for RKNPU')
    parser.add_argument('--output_video_path', type=str,
                        default=None, help='Optional: Path to save the output video file (e.g., output.mp4).')
    parser.add_argument('--input_size', type=str, default='640,640',
                        help='Input image size for the model, format: width,height (e.g., 640,640).')
    parser.add_argument('--bg_color', type=int, default=56,
                        help='Background color for letterbox resize (0-255).')
    parser.add_argument('--nms_threshold', type=float, default=0.4,
                        help='Non-Maximum Suppression (NMS) threshold.')
    parser.add_argument('--obj_threshold', type=float, default=0.5,
                        help='Object confidence threshold for detection.')
    parser.add_argument('--kpt_threshold', type=float, default=0.3,
                        help='Keypoint confidence threshold for drawing.')
    args = parser.parse_args()

    # ��������ߴ�
    input_size = tuple(map(int, args.input_size.split(',')))
    if len(input_size) != 2:
        print("Error: --input_size must be in format 'width,height'.")
        sys.exit(1)

    # --- RKNN ��ʼ���ͼ��� ---
    rknn = RKNN(verbose=True)

    # Load RKNN model
    print(f'--> Loading RKNN model: {args.model_path}')
    ret = rknn.load_rknn(args.model_path)
    if ret != 0:
        print(f'Load RKNN model "{args.model_path}" failed!')
        exit(ret)
    print('Model loaded successfully.')

    # Init runtime environment
    print('--> Initializing runtime environment')
    ret = rknn.init_runtime(target=args.target, device_id=args.device_id)
    if ret != 0:
        print('Init runtime environment failed!')
        exit(ret)
    print('Runtime initialized successfully.')

    # --- ��Ƶ����ʼ�� ---
    try:
        # ���Խ��������Ϊ���� (����ͷ����) ���ַ��� (��Ƶ�ļ�·��)
        source = int(args.video_source)
    except ValueError:
        source = args.video_source
        
    cap = cv2.VideoCapture(source)
    if not cap.isOpened():
        print(f"Error: Cannot open video source: {args.video_source}")
        rknn.release()
        sys.exit(1)
    
    # ��ȡ��Ƶ����
    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS) or 30 # Ĭ�� 30 FPS
    
    # ��ʼ����Ƶд����� (�����Ҫ������Ƶ)
    out_writer = None
    if args.output_video_path:
        fourcc = cv2.VideoWriter_fourcc(*'mp4v') # ʹ�� mp4v ������
        out_writer = cv2.VideoWriter(args.output_video_path, fourcc, fps, (frame_width, frame_height))
        print(f"Output video will be saved to {args.output_video_path}")

    # --- ��Ƶ����ѭ�� ---
    print('--> Starting video stream processing. Press "q" to exit.')
    
    frame_count = 0
    start_time = time.time()
    
    while cap.isOpened():
        ret, img = cap.read()
        if not ret:
            print("End of video stream or error reading frame.")
            break
        
        # Ԥ����letterbox���� (ע�⣺����ʹ��img��Ϊ���룬��Ϊ���Ѿ���BGR��ʽ��֡)
        letterbox_img, aspect_ratio, offset_x, offset_y = letterbox_resize(img, input_size, args.bg_color)
        infer_img = letterbox_img[..., ::-1]  # BGR2RGB (RKNNģ��ͨ����ҪRGB����)

        # Inference
        results = rknn.inference(inputs=[infer_img]) 

        # --- �����NMS ---
        outputs=[]
        keypoints_raw=results[3] # �ؼ���ԭʼ���
        
        # ��������͹ؼ���
        for x in results[:3]:
            index,stride=0,0
            # ��������ͼ��Сȷ������������
            if x.shape[2]==20: # 32x32 feature map, stride=32
                stride=32
                # ���������������Ϊ��ƥ��YOLOv8-Poseģ�������˳��
                index=20*4*20*4+20*2*20*2
            if x.shape[2]==40: # 16x16 feature map, stride=16
                stride=16
                index=20*4*20*4
            if x.shape[2]==80: # 8x8 feature map, stride=8
                stride=8
                index=0
            feature=x.reshape(1,65,-1)
            output=process(feature,keypoints_raw,index,x.shape[3],x.shape[2],stride, objectThresh=args.obj_threshold)
            outputs=outputs+output
        
        # NMS (�Ǽ���ֵ����)
        predbox = NMS(outputs, nmsThresh=args.nms_threshold)

        # --- ���ƹؼ���͹Ǽ� ---
        for i in range(len(predbox)):
            # 1. �ָ��߽��ԭʼͼ��ߴ�
            xmin = int((predbox[i].xmin-offset_x)/aspect_ratio)
            ymin = int((predbox[i].ymin-offset_y)/aspect_ratio)
            xmax = int((predbox[i].xmax-offset_x)/aspect_ratio)
            ymax = int((predbox[i].ymax-offset_y)/aspect_ratio)
            classId = predbox[i].classId
            score = predbox[i].score
            
            # ���Ʊ߽��
            cv2.rectangle(img, (xmin, ymin), (xmax, ymax), (0, 255, 0), 2)
            title= CLASSES[classId] + f" {score:.2f}"
            cv2.putText(img, title, (xmin, ymin - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2, cv2.LINE_AA)
            
            # 2. �ָ��ؼ������굽ԭʼͼ��ߴ�
            keypoints =predbox[i].keypoint.reshape(-1, 3) # keypoint [x, y, conf]
            keypoints[...,0]=(keypoints[...,0]-offset_x)/aspect_ratio
            keypoints[...,1]=(keypoints[...,1]-offset_y)/aspect_ratio

            # 3. ���ƹؼ���
            for k, keypoint in enumerate(keypoints):
                x, y, conf = keypoint
                # �ؼ�����ɫ
                color_k = [int(c) for c in kpt_color[k]] 
                # �����ƿɼ��Ĺؼ��� (�����0)
                if x > 0 and y > 0 and conf > args.kpt_threshold: # ʹ�������в���
                    cv2.circle(img, (int(x), int(y)), 5, color_k, -1, lineType=cv2.LINE_AA)
            
            # 4. ���ƹǼ�����
            for k, sk in enumerate(skeleton):
                    # sk[0]-1 �� sk[1]-1 �ǹؼ�����keypoints�����е����� (��ΪCOCO�ؼ����1��ʼ)
                    pos1 = (int(keypoints[(sk[0] - 1), 0]), int(keypoints[(sk[0] - 1), 1]))
                    pos2 = (int(keypoints[(sk[1] - 1), 0]), int(keypoints[(sk[1] - 1), 1]))

                    conf1 = keypoints[(sk[0] - 1), 2]
                    conf2 = keypoints[(sk[1] - 1), 2]

                    # ���������ؼ��㶼��Ч�������0�����Ŷȸߣ�ʱ��������
                    if pos1[0] <= 0 or pos1[1] <= 0 or pos2[0] <= 0 or pos2[1] <= 0:
                        continue
                    if conf1 < args.kpt_threshold or conf2 < args.kpt_threshold: # ʹ�������в���
                        continue
                    
                    # ������ɫ
                    limb_c = [int(c) for c in limb_color[k]]
                    cv2.line(img, pos1, pos2, limb_c, thickness=2, lineType=cv2.LINE_AA)

        # ͳ�� FPS (ÿ 10 ֡����һ��)
        frame_count += 1
        if frame_count % 10 == 0:
            end_time = time.time()
            current_fps = 10 / (end_time - start_time)
            fps_text = f"FPS: {current_fps:.2f}"
            cv2.putText(img, fps_text, (20, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)
            start_time = end_time # ��FPS����
            frame_count = 0 # ����֡����

        # ʵʱ��ʾ���
        cv2.imshow("RKNN YOLOv8 Pose Demo", img)
        
        # д����Ƶ�ļ� (���������)
        if out_writer:
            out_writer.write(img)

        # ���� 'q' ���˳�
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    # --- �ͷ���Դ ---
    cap.release()
    if out_writer:
        out_writer.release()
    cv2.destroyAllWindows()
    rknn.release()
    print("Video stream processing finished. Resources released.")
