# -*- coding: utf-8 -*-

import cv2
import numpy as np

def grabcut(img, roi, iters=5):
    """Wrapper for OpenCV's grabCut function.

    Runs the GrabCut algorithm for segmentation. Returns an 8-bit single-channel
    mask. Its elements may have the following values:

    * ``cv2.GC_BGD`` defines an obvious background pixel
    * ``cv2.GC_FGD`` defines an obvious foreground pixel
    * ``cv2.GC_PR_BGD`` defines a possible background pixel
    * ``cv2.GC_PR_FGD`` defines a possible foreground pixel

    The GrabCut algorithm is executed with `iters` iterations. The region of
    interest `roi` can be a 4-tuple ``(x,y,width,height)``.
    """
    mask = np.zeros(img.shape[:2], np.uint8)
    bgdmodel = np.zeros((1,65), np.float64)
    fgdmodel = np.zeros((1,65), np.float64)
    cv2.grabCut(img, mask, roi, bgdmodel, fgdmodel, iters, cv2.GC_INIT_WITH_RECT)
    return mask

def scale_max_perimeter(img, m):
    perim = sum(img.shape[:2])
    if m and perim > m:
        rf = float(m) / perim
        img = cv2.resize(img, None, fx=rf, fy=rf)
    return img
