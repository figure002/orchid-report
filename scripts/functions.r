library('GPArotation')
library('psych')

# Returns a color string for a `codeword` (vector of integers). An `on` bit in
# the codeword returns the element at the same position from the color vector.
codeword.color <- function(codeword, colors, on=1) {
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

plot.pca.single <- function(data_tsv, output.labels, nfactors, exclude=NULL,
                            compare=c(1,2), legend.pos="topright") {
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
    data$col = apply(data[cols.out], 1, codeword.color, data.colors)

    # Principal components analysis.
    data.pc = principal(data[cols.in], nfactors=nfactors, rotate='varimax')

    # Plot component compare[1] against component compare[2].
    plot(data.pc$scores[,compare[1]], data.pc$scores[,compare[2]],
        col=data$col, bg=data$col, pch=21, xlab=sprintf("PC%d", compare[1]),
        ylab=sprintf("PC%d", compare[2]))
    legend(legend.pos, legend=output.labels, col=data.colors,
        pt.bg=data.colors, pch=21, inset=.02, text.font=3)
}

plot.pca.pairs <- function(data_tsv, output.labels, nfactors, exclude=NULL,
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
    data$col = apply(data[cols.out], 1, codeword.color, data.colors)

    # Principal components analysis.
    data.pc = principal(data[cols.in], nfactors=nfactors, rotate='varimax')

    # Plot component compare[1] against component compare[2].
    pairs(data.pc$scores[,components], col=data$col, bg=data$col, pch=21,
        cex.axis=1.5, cex.main=1.5, upper.panel = NULL)
    par(xpd=TRUE)
    legend(legend.pos, legend=output.labels, col=data.colors, pt.bg=data.colors,
        pch=21, inset=.02, cex=1.5, text.font=3)
}

plot.pca.3d <- function(data_tsv, nclasses, nfactors, components=seq(1,3),
                        exclude=NULL) {
    library(rgl);

    # Read the data file.
    data = read.delim(data_tsv)

    # Get the column names minus the columns to be excluded.
    if ( is.null(exclude) ) {
        cols = names(data)
    } else {
        cols = names(data)[-exclude]
    }

    # Get input and output column names.
    cols.in = head(cols, -nclasses)
    cols.out = tail(cols, nclasses)

    # Set colors for output labels.
    if ( require('gplots') ) {
        data.colors = rich.colors(nclasses)
    } else {
        data.colors = rainbow(nclasses)
    }

    # Add a color column to the data frame.
    data$col = apply(data[cols.out], 1, codeword.color, data.colors)

    # Principal components analysis.
    data.pc = principal(data[cols.in], nfactors=nfactors, rotate='varimax')

    rgl.open(); offset <- 50; par3d(windowRect=c(offset, offset, 640+offset,
        640+offset)); rm(offset); rgl.clear()
    rgl.viewpoint(theta=45, phi=30, fov=60, zoom=1)
    spheres3d(data.pc$scores[,components[1]], data.pc$scores[,components[2]],
        data.pc$scores[,components[3]],
        radius=0.1, color=data$col, alpha=1, shininess=20)
    aspect3d(1, 1, 1)
    axes3d(col='black')
    title3d("", "",
        sprintf("PC%d", components[1]),
        sprintf("PC%d", components[2]),
        sprintf("PC%d", components[3]),
        col='black')
    bg3d("white")
}
