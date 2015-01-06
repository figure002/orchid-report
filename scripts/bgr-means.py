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
    parser.add_argument('--iters', metavar='N', type=int, default=5, help="The number of segmentation iterations. Default is 5.")
    parser.add_argument('--margin', metavar='N', type=int, default=1, help="The margin of the foreground rectangle from the edges. Default is 1.")
    parser.add_argument('--bins', metavar='N', type=int, default=20, help="The number of horizontal and vertical bins. Default is 20.")

    subparsers = parser.add_subparsers(
        help="Specify which task to start.",
        dest="task"
    )

    help_tsv = "Print BGR data in TSV format."
    parser_tsv = subparsers.add_parser(
        "tsv",
        help=help_tsv,
        description=help_tsv
    )
    parser_tsv.add_argument('path', metavar='FILE', help="Path to input image")

    help_draw = "Copy the image with the first horizontal and vertical bins drawn."
    parser_draw = subparsers.add_parser(
        "draw",
        help=help_draw,
        description=help_draw
    )
    parser_draw.add_argument('path', metavar='FILE', help="Path to input image")
    parser_draw.add_argument('-o', metavar='FILE', default='out.png', help="Path for output image")

    args = parser.parse_args()

    # Load the image.
    img = cv2.imread(args.path)
    if img == None or img.size == 0:
        sys.stderr.write("Failed to read %s\n" % path)
        exit(1)

    # Perform segmentation.
    roi = (args.margin, args.margin, img.shape[1]-args.margin*2,
        img.shape[0]-args.margin*2)
    mask = grabcut(img, roi, args.iters)
    bin_mask = np.where((mask==cv2.GC_FGD) + (mask==cv2.GC_PR_FGD),
        255, 0).astype('uint8')

    # Obtain contours (all points) from the mask.
    contour = ft.get_largest_contour(bin_mask.copy(), cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_NONE)

    # Mask the image.
    img = cv2.bitwise_and(img, img, mask=bin_mask)

    # Execute the task.
    if args.task == 'tsv':
        print_tsv(img, contour, args.bins)
    elif args.task == 'draw':
        draw_bins(img, args.o, contour, args.bins)
    else:
        sys.stderr.write("Unknown task `%s`\n" % args.task)

    return 0

def print_tsv(img, contour, bins):
    """Print data in TSV format."""
    means_hor, means_ver = ft.color_bgr_means(img, contour, bins)
    print "h\tv"
    for row in zip(means_hor.astype(str), means_ver.astype(str)):
        print "\t".join(row)

def draw_bins(img, out, contour, bins):
    """Print data in TSV format."""
    draw_sections(img, contour, bins, filter_=[2])
    cv2.imwrite(out, img)

def draw_sections(img, contour, bins, filter_=None):
    """Draw bins on the image."""
    props = ft.contour_properties([contour], 'BoundingRect')
    box = props[0]['BoundingRect']

    rect_x, rect_y, width, height = box
    centroid = (width/2+rect_x, height/2+rect_y)
    longest = max([width, height])
    incr = float(longest) / bins

    # Calculate X and Y starting points.
    x_start = centroid[0] - (longest / 2)
    y_start = centroid[1] - (longest / 2)

    for i in range(bins):
        if filter_ and i not in filter_:
            continue

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

        # Convert back to integers.
        y = int(y)
        y_start = int(y_start)
        y_incr = int(y_incr)
        y_end = int(y_end)
        x = int(x)
        x_start = int(x_start)
        x_incr = int(x_incr)
        x_end = int(x_end)

        # Draw the horizontal section.
        cv2.rectangle(img, (x_start,y), (x_end,y_incr), (0,255,0), 1)

        # Draw the vertical section.
        cv2.rectangle(img, (x,y_start), (x_incr,y_end), (0,0,255), 1)

if __name__ == "__main__":
    main()
