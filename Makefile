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

images/%_pca_plot.pdf: data/%.tsv make-plots.r
	Rscript make-plots.r $< $@

report.pdf: db-stats.inc table-taxa.inc table-taxa-summary.inc \
			images/bgr_means_plots.pdf images/genus_pca_plot.pdf \
			images/Cypripedium.section_pca_plot.pdf \
			images/Paphiopedilum.section_pca_plot.pdf \
			images/Paphiopedilum.Parvisepalum.species_pca_plot.pdf \
			images/meta_database_diagram.pdf

db-stats.inc: data/meta.db
	python stats-tex.py $< db_stats > $@

table-taxa.inc: data/meta.db
	python stats-tex.py $< taxa --col 3 > $@

table-taxa-summary.inc: data/meta.db
	python stats-tex.py $< taxa_summary > $@

images/bgr_means_plots.pdf: data/bgr-means.tsv
	Rscript make-plots.r $< $@

data/bgr-means.tsv: images/grabcut_output.png
	python bgr-means.py $< > $@

images/meta_database_diagram.pdf: data/meta.db
	java -classpath schemacrawler/lib/*:. schemacrawler.tools.sqlite.Main \
	-database=$< -password= -infolevel=standard -command=graph \
	-noinfo=true -portablenames=true -outputformat=pdf -outputfile=$@
	echo Database diagram is in $@

clean:
	@rm -f $(OUTDIR)/*.aux  $(OUTDIR)/*.log $(OUTDIR)/*.out
.PHONY: clean
