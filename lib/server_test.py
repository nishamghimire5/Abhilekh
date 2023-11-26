from flask import Flask, request, send_file
from werkzeug.utils import secure_filename
from itertools import combinations
import numpy as np
from io import open
import os
from PIL import Image
import pathlib
import glob
import cv2
import json
import base64

def sauvola_threshold(image):
    window_size=15
    k=0.1
    R=128
    if len(image.shape) > 2:
        image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    dir_path = "C:/temp"
    image = image.astype(np.float32)
    mean = cv2.blur(image, (window_size, window_size))
    mean_square = cv2.blur(image**2, (window_size, window_size))
    standard_deviation = np.sqrt(mean_square - mean**2)
    threshold = mean * (1 + k * ((standard_deviation / R) - 1))
    binary_image = (image > threshold).astype(np.uint8) * 255
    cv2.imwrite(os.path.join(dir_path,'sauvola_output.jpg'), binary_image)

def niblack_manual(image):
    window_size=15
    k = 0.2
    h, w = image.shape
    output_image = np.zeros((h, w), dtype=np.uint8)
    padded_image = np.pad(image, pad_width=window_size // 2, mode='reflect')
    dir_path = "C:/temp"
    for i in range(h):
        for j in range(w):
            window = padded_image[i:i+window_size, j:j+window_size]
            mean = np.mean(window)
            std = np.std(window)
            threshold = mean - k * std
            if image[i, j] > threshold:
                output_image[i, j] = 255
            else:
                output_image[i, j] = 0
    cv2.imwrite(os.path.join(dir_path,'niblack_output.jpg'), output_image)

def niblack_optimized(image):
    window_size=15
    k = 0.2
    if len(image.shape) > 2:
        image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    dir_path = "C:/temp"
    image = image.astype(np.float32)
    mean = cv2.blur(image, (window_size, window_size))
    mean_square = cv2.blur(image**2, (window_size, window_size))
    standard_deviation = np.sqrt(mean_square - mean**2)
    threshold = mean + k * standard_deviation
    binary_image = (image > threshold).astype(np.uint8) * 255
    cv2.imwrite(os.path.join(dir_path,'niblack_optimized.jpg'), binary_image)

def otsu(image):
    dir_path = "C:/temp"
    im_gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    th, im_gray_th_otsu = cv2.threshold(im_gray, 128, 192, cv2.THRESH_OTSU)
    cv2.imwrite(os.path.join(dir_path,'temp_otsu.jpg'), im_gray_th_otsu)

def regional_entropy(hist, cum_hist, thresholds):
    total_entropy = 0
    for i in range(len(thresholds) - 1):
        t1 = thresholds[i] + 1
        t2 = thresholds[i + 1]
        cum_val = cum_hist[t2] - cum_hist[t1 - 1]
        norm_val = hist[t1:t2 + 1] / cum_val if cum_val > 0 else 1
        entropy = -(norm_val * np.log(norm_val + (norm_val <= 0))).sum()
        total_entropy += entropy
    return total_entropy

def thres_holds(hist, cum_hist, nthrs):
    thr_combinations = combinations(range(255), nthrs)
    max_entropy = 0
    opt_thresholds = None
    cum_hist = np.append(cum_hist, [0])
    for thresholds in thr_combinations:
        ext_thresholds = [-1]
        ext_thresholds.extend(thresholds)
        ext_thresholds.extend([len(hist) - 1])
        regions_entropy = regional_entropy(hist, cum_hist, ext_thresholds)
        if regions_entropy > max_entropy:
            max_entropy = regions_entropy
            opt_thresholds = thresholds
    return opt_thresholds

def Entropy_MT(image, nthrs):
    hist, bin_val = np.histogram(image, bins=range(256), density=True)
    cum_hist = hist.cumsum()
    return thres_holds(hist, cum_hist, nthrs)

def apply_multithresholding(img, thresholds):
    ext_thresholds = [-1]
    ext_thresholds.extend(thresholds)
    thres_image = np.zeros_like(img)
    for i in range(1, len(ext_thresholds)):
        thres_image[img >= ext_thresholds[i]] = i
    wp_val = 255 // len(thresholds)
    return thres_image * wp_val   

def feat(image):
    dir_path = "C:/temp"
    th = Entropy_MT(image, 3)
    cv2.imwrite(os.path.join(dir_path,'feat_output.jpg'),apply_multithresholding(image, th))

app = Flask(__name__)

@app.route('/sauvola_process', methods=['POST'])
def blu_process():
    file = request.files['balls']
    filename = secure_filename(file.filename)
    dir_path = "C:/temp"
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    file.save(os.path.join(dir_path, filename))
    temp_real_image = cv2.imread(os.path.join(dir_path, filename),0)
    sauvola_threshold(temp_real_image)
    return send_file(os.path.join(dir_path,'sauvola_output.jpg'), mimetype='image/jpeg')

@app.route('/otsu_process', methods=['POST'])
def otsu_process():
    file = request.files['balls']
    filename = secure_filename(file.filename)
    dir_path = "C:/temp"
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    file.save(os.path.join(dir_path, filename))
    temp_real_image = cv2.imread(os.path.join(dir_path, filename))
    otsu(temp_real_image)
    return send_file(os.path.join(dir_path,'temp_otsu.jpg'), mimetype='image/jpeg')

@app.route('/FEAT_process', methods=['POST'])
def FEAT_process():
    file = request.files['balls']
    filename = secure_filename(file.filename)
    dir_path = "C:/temp"
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    file.save(os.path.join(dir_path, filename))
    temp_real_image = cv2.imread(os.path.join(dir_path, filename),0)
    feat(temp_real_image)
    return send_file(os.path.join(dir_path,'feat_output.jpg'), mimetype='image/jpeg')

@app.route('/niblack_m', methods=['POST'])
def niblack_m():
    file = request.files['balls']
    filename = secure_filename(file.filename)
    dir_path = "C:/temp"
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    file.save(os.path.join(dir_path, filename))
    temp_real_image = cv2.imread(os.path.join(dir_path, filename),0)
    niblack_manual(temp_real_image)
    return send_file(os.path.join(dir_path,'niblack_output.jpg'), mimetype='image/jpeg')

@app.route('/niblack_o', methods=['POST'])
def niblack_o():
    file = request.files['balls']
    filename = secure_filename(file.filename)
    dir_path = "C:/temp"
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    file.save(os.path.join(dir_path, filename))
    temp_real_image = cv2.imread(os.path.join(dir_path, filename),0)
    niblack_optimized(temp_real_image)
    return send_file(os.path.join(dir_path,'niblack_optimized.jpg'), mimetype='image/jpeg')

if __name__ == '__main__':
    app.run()

