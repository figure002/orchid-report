# See: http://amath.colorado.edu/documentation/LaTeX/reference/faq/bibstyles.html

BIBTEX=bibtex
TEX2PDF=pdflatex
TEX2PDF_OPTS=-file-line-error

# Convert LaTeX to PDF.
%.pdf: %.tex %.aux %.bbl
	$(TEX2PDF) $(TEX2PDF_OPTS) $<
	$(TEX2PDF) $(TEX2PDF_OPTS) $<

# Convert LaTeX to RTF. Requires latex2rtf.
%.rtf: %.tex %.aux %.bbl
	latex2rtf -a $*.aux -b $*.bbl -o $@ $<

# Convert HTML to ODT.
%.odt: %.html
	libreoffice --headless --convert-to odt $<

# Convert LaTeX to HTML. Requires tex4ht.
%.html: %.tex
	htlatex $<

%.bbl: %.aux %.tex %.bib
	$(BIBTEX) $<

%.aux: %.tex
	$(TEX2PDF) $(TEX2PDF_OPTS) $<

images/%_pca_plot.pdf: data/%.tsv
	Rscript scripts/make-plots.r $< $@

all: report.pdf

report.pdf: db-stats.inc table-taxa.inc table-taxa-summary.inc \
			images/bgr_means_plots.pdf images/genus_pca_plot.pdf \
			images/Cypripedium_section_pca_plot.pdf \
			images/Paphiopedilum_section_pca_plot.pdf \
			images/Paphiopedilum_Parvisepalum_species_pca_plot.pdf \
			images/meta_database_diagram.pdf \
			images/grabcut_output.png \
			images/grabcut_output_roi.png \
			images/bgr_means_sections.png

db-stats.inc: data/meta.db
	python scripts/stats-tex.py $< db_stats > $@

table-taxa.inc: data/meta.db
	python scripts/stats-tex.py $< taxa --col 3 > $@

table-taxa-summary.inc: data/meta.db
	python scripts/stats-tex.py $< taxa_summary > $@

images/bgr_means_plots.pdf: data/bgr-means.tsv
	Rscript scripts/make-plots.r $< $@

data/bgr-means.tsv: images/grabcut_output.png
	python scripts/bgr-means.py tsv $< > $@

images/meta_database_diagram.pdf: data/meta.db
	java -classpath schemacrawler/lib/*:. schemacrawler.tools.sqlite.Main \
	-database=$< -password= -infolevel=standard -command=graph \
	-noinfo=true -portablenames=true -outputformat=pdf -outputfile=$@
	echo Database diagram is in $@

images/grabcut_output.png: images/P_druryi.jpg
	python scripts/grabcut.py -i $< -o $@ --margin 5

images/grabcut_output_roi.png: images/P_druryi.jpg
	python scripts/grabcut.py -i $< -o $@ --margin 5 --roi

images/bgr_means_sections.png: images/P_druryi.jpg
	python scripts/bgr-means.py draw -o $@ $<

%.clean:
	@rm -f $*.aux $*.log $*.out $*.bbl $*.blg $*.spl $*.4ct $*.4tc $*.tmp \
	$*.xref $*.dvi $*.idv $*.lg
.PHONY: %.clean
