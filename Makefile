# See: http://amath.colorado.edu/documentation/LaTeX/reference/faq/bibstyles.html

BIBTEX=bibtex
OUTDIR=build
TEX2PDF=pdflatex
TEX2PDF_OPTS=-file-line-error -output-directory $(OUTDIR)

%.pdf: %.tex $(OUTDIR)/%.aux
	$(BIBTEX) $(OUTDIR)/$*.aux
	$(TEX2PDF) $(TEX2PDF_OPTS) $<
	$(TEX2PDF) $(TEX2PDF_OPTS) $<

$(OUTDIR)/%.aux: %.tex
	$(TEX2PDF) $(TEX2PDF_OPTS) $<

images/%_pca_plot.pdf: data/%.tsv
	Rscript make-plots.r $< $@

report.pdf: table-taxa.inc \
			images/BGR_means_plots.pdf images/genus_pca_plot.pdf \
			images/Cypripedium.section_pca_plot.pdf \
			images/Paphiopedilum.section_pca_plot.pdf \
			images/Paphiopedilum.Parvisepalum.species_pca_plot.pdf \
			images/Meta_database_diagram.pdf

table-taxa.inc: data/meta.db
	python stats-tex.py $< taxa --col 3 > $@

images/BGR_means_plots.pdf: data/bgr-means.tsv
	Rscript make-plots.r $< $@

data/bgr-means.tsv: images/grabcut_output.png
	python bgr-means.py $< > $@

images/Meta_database_diagram.pdf: data/meta.db
	java -classpath schemacrawler/lib/*:. schemacrawler.tools.sqlite.Main \
	-database=$< -password= -infolevel=standard -command=graph \
	-noinfo=true -portablenames=true -outputformat=pdf -outputfile=$@
	echo Database diagram is in $@

clean:
	@rm -f $(OUTDIR)/*.aux  $(OUTDIR)/*.log $(OUTDIR)/*.out
.PHONY: clean
