#!/usr/bin/env Rscript
# Usage: Rscript make-plots.r {bgr_means|pca_all|...} [arg ..]

source('scripts/functions.r')

plot.bgr.means <- function(bgr_means_tsv) {
    bgr.means = read.delim(bgr_means_tsv)
    n = nrow(bgr.means)
    bgr = c("blue","dark green","red")
    hor = data.frame(b=bgr.means$h[seq(1, n, 3)], g=bgr.means$h[seq(2, n, 3)], r=bgr.means$h[seq(3, n, 3)])
    ver = data.frame(b=bgr.means$v[seq(1, n, 3)], g=bgr.means$v[seq(2, n, 3)], r=bgr.means$v[seq(3, n, 3)])

    par(mfrow=c(1,2))
    #matplot(hor, type=c("b"), pch=21, lwd=2, col=bgr, bg=bgr, xlab="Horizontal bin", ylab="Mean Colour Intensity", ylim=c(0,255))
    #matplot(ver, type=c("b"), pch=21, lwd=2, col=bgr, bg=bgr, xlab="Vertical bin", ylab="Mean Colour Intensity", ylim=c(0,255))
    barplot(t(as.matrix(hor)), pch=21, lwd=2, col=bgr, bg=bgr, xlab="Horizontal bin", ylab="Mean Colour Intensity", ylim=c(0,255), cex.axis=1.2, cex.lab=1.2, beside=TRUE)
    barplot(t(as.matrix(ver)), pch=21, lwd=2, col=bgr, bg=bgr, xlab="Horizontal bin", ylab="Mean Colour Intensity", ylim=c(0,255), cex.axis=1.2, cex.lab=1.2, beside=TRUE)
}

plot.pca.genus <- function(data_tsv) {
	plot.pca.single(data_tsv,
		output.labels=c("Cypripedium","Mexipedium","Paphiopedilum",
			"Phragmipedium","Selenipedium"),
		nfactors=3, exclude=c(1))
	title(main=expression(paste("Genera")))
}

plot.pca.Cypripedium.section <- function(data_tsv) {
	plot.pca.single(data_tsv,
		output.labels=c("Acaulia","Arietinum","Bifolia","Cypripedium",
			"Enantiopedilum","Flabellinervia","Macrantha","Obtusipetala",
			"Sinopedilum","Subtropica","Trigonopedia"),
		nfactors=8, exclude=c(1), legend.pos="topleft")
	title(main=expression(paste(italic("Cypripedium"), " sections")))
}

plot.pca.Paphiopedilum.section <- function(data_tsv) {
	plot.pca.single(data_tsv,
		output.labels=c("Barbata","Brachypetalum","Cochlopetalum",
			"Coryopedilum","Paphiopedilum","Pardalopetalum","Parvisepalum"),
		nfactors=6, exclude=c(1))
	title(main=expression(paste(italic("Paphiopedilum"), " sections")))
}

plot.pca.Paphiopedilum.Parvisepalum.species <- function(data_tsv) {
	plot.pca.single(data_tsv,
		output.labels=c("P. armeniacum","P. delenatii","P. emersonii",
			"P. malipoense","P. micranthum","P. vietnamense"),
		nfactors=6, exclude=c(1), legend.pos="bottomright")
	title(main=expression(paste(italic("Paphiopedilum"), " section ", italic("Parvisepalum"), " species")))
}

main <- function(args) {
	file.in = args[1]
	file.out = args[2]

	if (grepl("bgr_means_plots\\.pdf", file.out)) {
		pdf(file.out, width=14, height=7)
		plot.bgr.means(file.in)
		dev.off()
	} else if (grepl("genus_pca_plot\\.pdf", file.out)) {
		pdf(file.out, width=7, height=7)
		plot.pca.genus(file.in)
		dev.off()
	} else if (grepl("Cypripedium\\.section_pca_plot\\.pdf", file.out)) {
		pdf(file.out, width=7, height=7)
		plot.pca.Cypripedium.section(file.in)
		dev.off()
	} else if (grepl("Paphiopedilum\\.section_pca_plot\\.pdf", file.out)) {
		pdf(file.out, width=7, height=7)
		plot.pca.Paphiopedilum.section(file.in)
		dev.off()
	} else if (grepl("Paphiopedilum\\.Parvisepalum\\.species_pca_plot\\.pdf", file.out)) {
		pdf(file.out, width=7, height=7)
		plot.pca.Paphiopedilum.Parvisepalum.species(file.in)
		dev.off()
	} else {
		stop(sprintf("Don't know how to make %s", file.out))
	}
}

main( commandArgs(TRUE) )
