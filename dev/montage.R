args <- commandArgs(TRUE); out <- args[1]; files <- args[-1]
png(out, width = 3000, height = 1900 * ceiling(length(files) / 3) / 3, res = 100)
op <- par(mfrow = c(ceiling(length(files) / 3), 3), mar = c(0.2, 0.2, 1.6, 0.2))
for (f in files) { img <- png::readPNG(f); plot.new(); plot.window(c(0, 1), c(0, 1), asp = dim(img)[1] / dim(img)[2]); rasterImage(img, 0, 0, 1, 1); title(basename(f), cex.main = 1.3) }
dev.off()
