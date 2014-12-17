#!/usr/bin/env Rscript
# Usage: Rscript make-plots.r {bgr_means|pca_all|...} [arg ..]

# Returns a color string for a `codeword` (vector of integers). An `on` bit in
# the codeword returns the element at the same position from the color vector.
codeword_color <- function(codeword, colors, on=1) {
	if (length(colors) < length(codeword)) {
		stop(sprintf("The color vector must have at least length(codeword)=",
			"%s elements, found %s", length(codeword), length(colors)))
	}
	for (i in 1:length(codeword)) {
		if (codeword[i] == 1) {
			return(colors[i])
		}
	}
	stop(sprintf("Codeword did not contain an on=%s bit", on))
}

plot.bgr.means <- function(bgr_means_tsv) {
	bgr.means = read.delim(bgr_means_tsv)
	n = nrow(bgr.means)
	bgr = c("blue","dark green","red")
	hor = data.frame(b=bgr.means$h[seq(1, n, 3)], g=bgr.means$h[seq(2, n, 3)], r=bgr.means$h[seq(3, n, 3)])
	ver = data.frame(b=bgr.means$v[seq(1, n, 3)], g=bgr.means$v[seq(2, n, 3)], r=bgr.means$v[seq(3, n, 3)])

	par(mfrow=c(1,2))
	matplot(hor, type=c("b"), pch=21, lwd=2, col=bgr, bg=bgr, xlab="Horizontal bin", ylab="Mean Colour Intensity", ylim=c(0,255))
	matplot(ver, type=c("b"), pch=21, lwd=2, col=bgr, bg=bgr, xlab="Vertical bin", ylab="Mean Colour Intensity", ylim=c(0,255))
}

plot_pca_single <- function(data_tsv, output.labels, nfactors, exclude=NULL,
							compare=c(1,2), legend.pos="topright") {
	library('GPArotation')
	library('psych')

	# Read the data file.
	data = read.delim(data_tsv)

	# Get the column names.
	if ( is.null(exclude) ) {
		cols = names(data)
	} else {
		cols = names(data)[-exclude]
	}

	# Get input and output column names.
	cols.in = head(cols, -length(output.labels))
	cols.out = tail(cols, length(output.labels))

	# Set colors for output labels.
	if ( require('gplots') ) {
		data.colors = rich.colors(length(output.labels))
	} else {
		data.colors = rainbow(length(output.labels))
	}

	# Add a color column to the data frame.
	data$col = apply(data[cols.out], 1, codeword_color, data.colors)

	# Principal components analysis.
	data.pc = principal(data[cols.in], nfactors=nfactors, rotate='varimax')

	# Plot component compare[1] against component compare[2].
	plot(data.pc$scores[,compare[1]], data.pc$scores[,compare[2]],
		col=data$col, bg=data$col, pch=21, xlab=sprintf("PC%d", compare[1]),
		ylab=sprintf("PC%d", compare[2]))
	legend(legend.pos, legend=output.labels, col=data.colors,
		pt.bg=data.colors, pch=21, inset=.02)
}

plot_pca_pairs <- function(data_tsv, output.labels, nfactors, exclude=NULL,
						   components=seq(1,3), legend.pos="topright") {
	if (length(components) > nfactors) {
		stop(sprintf("The number of components to plot (%s) cannot be more ",
			"than the number of factors to extract (%s)",
			length(components), nfactors))
	}

	# Read the data file.
	data = read.delim(data_tsv)

	# Get the column names minus the columns to be excluded.
	if ( is.null(exclude) ) {
		cols = names(data)
	} else {
		cols = names(data)[-exclude]
	}

	# Get input and output column names.
	cols.in = head(cols, -length(output.labels))
	cols.out = tail(cols, length(output.labels))

	# Set colors for output labels.
	if ( require('gplots') ) {
		data.colors = rich.colors(length(cols.out))
	} else {
		data.colors = rainbow(length(cols.out))
	}

	# Add a color column to the data frame.
	data$col = apply(data[cols.out], 1, codeword_color, data.colors)

	# Principal components analysis.
	data.pc = principal(data[cols.in], nfactors=nfactors, rotate='varimax')

	# Plot component compare[1] against component compare[2].
	pairs(data.pc$scores[,components], col=data$col, bg=data$col, pch=21, cex.axis=1.5, cex.main=1.5, upper.panel = NULL)
	par(xpd=TRUE)
	legend(legend.pos, legend=output.labels, col=data.colors, pt.bg=data.colors, pch=21, inset=.02, cex=1.5)
}

plot.pca.genus <- function(data_tsv) {
	plot_pca_single(data_tsv,
		output.labels=c("Cypripedium","Mexipedium","Paphiopedilum",
			"Phragmipedium","Selenipedium"),
		nfactors=3, exclude=c(1))
}

plot.pca.Cypripedium.section <- function(data_tsv) {
	plot_pca_single(data_tsv,
		output.labels=c("Acaulia","Arietinum","Bifolia","Cypripedium",
			"Enantiopedilum","Flabellinervia","Macrantha","Obtusipetala",
			"Sinopedilum","Subtropica","Trigonopedia"),
		nfactors=8, exclude=c(1), legend.pos="topleft")
}

plot.pca.Paphiopedilum.section <- function(data_tsv) {
	plot_pca_single(data_tsv,
		output.labels=c("Barbata","Brachypetalum","Cochlopetalum",
			"Coryopedilum","Paphiopedilum","Pardalopetalum","Parvisepalum"),
		nfactors=6, exclude=c(1))
}

plot.pca.Paphiopedilum.Parvisepalum.species <- function(data_tsv) {
	plot_pca_single(data_tsv,
		output.labels=c("P. armeniacum","P. delenatii","P. emersonii",
			"P. malipoense","P. micranthum","P. vietnamense"),
		nfactors=6, exclude=c(1), legend.pos="bottomright")
}

main <- function(args) {
	file_in = args[1]
	file_out = args[2]

	if (grepl("BGR_means_plots\\.pdf", file_out)) {
		pdf(file_out, width=14, height=7)
		plot.bgr.means(file_in)
		dev.off()
	} else if (grepl("genus_pca_plot\\.pdf", file_out)) {
		pdf(file_out, width=7, height=7)
		plot.pca.genus(file_in)
		dev.off()
	} else if (grepl("Cypripedium\\.section_pca_plot\\.pdf", file_out)) {
		pdf(file_out, width=7, height=7)
		plot.pca.Cypripedium.section(file_in)
		dev.off()
	} else if (grepl("Paphiopedilum\\.section_pca_plot\\.pdf", file_out)) {
		pdf(file_out, width=7, height=7)
		plot.pca.Paphiopedilum.section(file_in)
		dev.off()
	} else if (grepl("Paphiopedilum\\.Parvisepalum\\.species_pca_plot\\.pdf", file_out)) {
		pdf(file_out, width=7, height=7)
		plot.pca.Paphiopedilum.Parvisepalum.species(file_in)
		dev.off()
	} else {
		stop(sprintf("Don't know how to make %s", file_out))
	}
}

main( commandArgs(TRUE) )
