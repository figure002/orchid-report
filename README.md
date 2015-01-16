# OrchiD report

This repository contains the LaTeX source files for the automated slipper orchid
identification project report.

## Requirements

* GNU Make
* TeX Live
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

Source distributions of [ImgPheno][1] and [NBClassify][2] can be installed via PIP:

	pip install nbclassify-x.x.x.tar.gz
	pip install imgpheno-x.x.x.tar.gz

## Building

Build the report with the command `make`. The report will be called
`report.pdf`. Run `make report.clean` to clean up intermediate files after a
build.

Other build options:

* `make report.html` builds the report in HTML format. Requires `htlatex`.
* `make report.rtf` builds the report in RTF format. Requires `latex2rtf`.
* `make report.odt` builds the report in ODT format. Requires `htlatex` and
  `libreoffice`.


[1]: https://github.com/naturalis/imgpheno
[2]: https://github.com/naturalis/nbclassify/tree/master/nbclassify
