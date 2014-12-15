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

report.pdf: images/BGR_means_plots.pdf images/PCA_genus_plot.pdf \
	images/PCA_Paph_sect_plot.pdf images/PCA_Paph_parv_spp_plot.pdf \
	images/Meta_database_diagram.pdf

images/BGR_means_plots.pdf: data/bgr-means.tsv
	Rscript make-plots.r bgr_means $< $@

data/bgr-means.tsv: images/grabcut_output.png
	python bgr-means.py $< > $@

images/PCA_genus_plot.pdf: data/genus.tsv
	Rscript make-plots.r pca_genus $< $@

images/PCA_Paph_sect_plot.pdf: data/Paphiopedilum.section.tsv
	Rscript make-plots.r pca_paph_sect $< $@

images/PCA_Paph_parv_spp_plot.pdf: data/Paphiopedilum.Parvisepalum.species.tsv
	Rscript make-plots.r pca_paph_parv_spp $< $@

images/PCA_plots.pdf: data/genus.tsv data/Paphiopedilum.section.tsv \
	data/Paphiopedilum.Parvisepalum.species.tsv
	Rscript make-plots.r pca_all $^ $@

images/Meta_database_diagram.pdf: data/meta.db
	java -classpath schemacrawler/lib/*:. schemacrawler.tools.sqlite.Main \
	-database=$< -password= -infolevel=standard -command=graph \
	-noinfo=true -portablenames=true -outputformat=pdf -outputfile=$@
	echo Database diagram is in $@

clean:
	@rm -f $(OUTDIR)/*.aux  $(OUTDIR)/*.log $(OUTDIR)/*.out
.PHONY: clean
