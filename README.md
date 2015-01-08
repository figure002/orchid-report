# OrchiD report

This repository contains the LaTeX source files for the automated slipper orchid
identification project report.

## Requirements

* R
	* GPArotation
	* psych
	* gplots
* Python
	* OpenCV
	* NumPy
	* SQLAlchemy
	* [ImgPheno][1]
	* [NBClassify][2]

## Building

Steps to make the PDF report:

* Create a `build` directory in the project root.
* Run `make` to compile the PDF report in `build/report.pdf`.


[1]: https://github.com/naturalis/imgpheno
[2]: https://github.com/naturalis/nbclassify/tree/master/nbclassify
