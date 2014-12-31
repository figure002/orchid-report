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
    parser.add_argument('--roi', action='store_const', const=True, help="Output original image with ROI drawn.")
    args = parser.parse_args()

    img = cv2.imread(args.i)
    if img == None or img.size == 0:
        sys.stderr.write("Failed to read %s\n" % args.i)
        return 1

    roi = (args.margin, args.margin, img.shape[1]-args.margin*2, img.shape[0]-args.margin*2)

    if args.roi:
        # Image with ROI.
        p1 = (args.margin, args.margin)
        p2 = (args.margin + roi[2] - 1, args.margin + roi[3] - 1)
        cv2.rectangle(img, p1, p2, (0,0,255), 1)
    else:
        # Perform segmentation.
        sys.stderr.write("Segmenting...\n")
        mask = grabcut(img, roi, args.iters)

        # Create a binary mask. Foreground is made white, background black.
        bin_mask = np.where((mask==cv2.GC_FGD) + (mask==cv2.GC_PR_FGD), 255, 0).astype('uint8')

        # Merge the binary mask with the image.
        img = cv2.bitwise_and(img, img, mask=bin_mask)

    sys.stderr.write("Saving image to %s\n" % args.o)
    cv2.imwrite(args.o, img)

    return 0

if __name__ == "__main__":
    main()
