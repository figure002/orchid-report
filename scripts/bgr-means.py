#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import sys

import cv2
import numpy as np
import imgpheno as ft

from common import grabcut, scale_max_perimeter

def main():
    parser = argparse.ArgumentParser(description='Get the rough shape from the main object')
    parser.add_argument('path', metavar='PATH', help='Path to image file')
    parser.add_argument('--max-size', metavar='N', type=float, help="Scale the input image down if its perimeter exceeds N. Default is no scaling.")
    parser.add_argument('--iters', metavar='N', type=int, default=5, help="The number of segmentation iterations. Default is 5.")
    parser.add_argument('--margin', metavar='N', type=int, default=1, help="The margin of the foreground rectangle from the edges. Default is 1.")
    parser.add_argument('-k', metavar='N', type=int, default=20, help="The number of horizontal and vertical bins. Default is 20.")
    args = parser.parse_args()
    process_image(args, args.path)
    return 0

def process_image(args, path):
    img = cv2.imread(path)
    if img == None or img.size == 0:
        sys.stderr.write("Failed to read %s\n" % path)
        exit(1)

    # Scale the image down if its perimeter exceeds the maximum (if set).
    img = scale_max_perimeter(img, args.max_size)

    # Perform segmentation.
    sys.stderr.write("Segmenting...\n")
    roi = (args.margin, args.margin, img.shape[1]-args.margin*2, img.shape[0]-args.margin*2)
    mask = grabcut(img, roi, args.iters)
    bin_mask = np.where((mask==cv2.GC_FGD) + (mask==cv2.GC_PR_FGD), 255, 0).astype('uint8')

    # Obtain contours (all points) from the mask.
    contour = ft.get_largest_contour(bin_mask.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)

    # Get the histograms.
    bgr_h, bgr_v = color_bgr_means(img, contour, args.k)

    # Print TSV data.
    print "h\tv"
    for row in zip(bgr_h.astype(str), bgr_v.astype(str)):
        print "\t".join(row)

def color_bgr_means(src, contour, bins=20):
    """Returns the histograms for BGR images along X and Y axis.

    The contour `contour` provides the region of interest in the image
    `src`. This ROI is divided into `bins` equal sections, both
    horizontally and vertically. For each horizontal and vertical section
    the mean B, G, and R are computed and returned. Each mean is in the
    range 0 to 255.

    If pixels outside the contour must be ignored, then `src` should be a
    masked image (i.e. pixels outside the ROI are black).
    """
    if len(src.shape) != 3:
        raise ValueError("Input image `src` must be in the BGR color space")
    if bins < 2:
        raise ValueError("Minimum value for `bins` is 2")

    props = ft.contour_properties([contour], 'BoundingRect')
    rect_x, rect_y, width, height = props[0]['BoundingRect']
    centroid = (width/2+rect_x, height/2+rect_y)
    longest = max([width, height])
    incr =  float(longest) / bins

    # Calculate X and Y starting points.
    x_start = centroid[0] - (longest / 2)
    y_start = centroid[1] - (longest / 2)

    # Compute the mean BGR values.
    row_x = []
    row_y = []
    for i in range(bins):
        x = (incr * i) + x_start
        y = (incr * i) + y_start

        x_incr = x + incr
        y_incr = y + incr
        x_end = x_start + longest
        y_end = y_start + longest

        # Remove negative values, which otherwise result in reverse indexing.
        if x_start < 0: x_start = 0
        if y_start < 0: y_start = 0
        if x < 0: x = 0
        if y < 0: y = 0
        if x_incr < 0: x_incr = 0
        if y_incr < 0: y_incr = 0
        if x_end < 0: x_end = 0
        if y_end < 0: y_end = 0

        # Select horizontal and vertical sections from the image.
        sample_hor = src[y:y_incr, x_start:x_end]
        sample_ver = src[y_start:y_end, x:x_incr]

        # Compute the mean B, G, and R for the sections.
        channels = cv2.split(sample_hor)

        if len(channels) == 0:
            row_x.extend([0,0,0])
            continue

        for k in range(3):
            row_x.append( np.mean(channels[k]) )

        # Compute the mean B, G, and R for the sections.
        channels = cv2.split(sample_ver)

        if len(channels) == 0:
            row_y.extend([0,0,0])
            continue

        for k in range(3):
            row_y.append( np.mean(channels[k]) )

    assert len(row_x) + len(row_y) == 2 * 3 * bins, "Return value length mismatch"
    return (np.uint16(row_x), np.uint16(row_y))

if __name__ == "__main__":
    main()
