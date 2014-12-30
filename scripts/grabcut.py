#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import sys

import cv2
import numpy as np

from common import grabcut

def main():
    parser = argparse.ArgumentParser(description='Test image segmentation')
    parser.add_argument('-i', metavar='FILE', required=True, help="Input image")
    parser.add_argument('-o', metavar='FILE', default='grabcut_output.png', help="Output image")
    parser.add_argument('--iters', metavar='N', type=int, default=5, help="The number of GrabCut iterations. Defaults to 5.")
    parser.add_argument('--margin', metavar='N', type=int, default=5, help="The margin of the foreground rectangle from the edges. Defaults to 5.")
    parser.add_argument('--roi', action='store_const', const=True, help="Draw the ROI in the output.")
    args = parser.parse_args()

    img = cv2.imread(args.i)
    if img == None or img.size == 0:
        sys.stderr.write("Failed to read %s\n" % args.i)
        return 1

    # Perform segmentation.
    sys.stderr.write("Segmenting...\n")
    roi = (args.margin, args.margin, img.shape[1]-args.margin*2, img.shape[0]-args.margin*2)
    mask = grabcut(img, roi, args.iters)

    # Image with ROI.
    img_roi = img.copy()
    cv2.rectangle(img_roi, roi[:2], roi[2:], (0,0,255), 1)

    # Create a binary mask. Foreground is made white, background black.
    bin_mask = np.where((mask==cv2.GC_FGD) + (mask==cv2.GC_PR_FGD), 255, 0).astype('uint8')

    # Merge the binary mask with the image.
    img_masked = cv2.bitwise_and(img, img, mask=bin_mask)

    sys.stderr.write("Saving image to %s\n" % args.o)
    if args.roi:
        res = np.hstack((img_roi, img_masked))
        cv2.imwrite(args.o, res)
    else:
        cv2.imwrite(args.o, img_masked)

    return 0

if __name__ == "__main__":
    main()
