#!/usr/bin/env Rscript

library(data.table)
library(argparse)

main <- function(args){
    
    print(args)
    
    input_path <- args$input_path
    out_prefix <- args$out_prefix

    # Load the data table from the input path
    dt <- fread(input_path)
    
    # filter to well sequenced sites
    dt <- dt[dt$median_approx>=10,]

    # filter to sites where the majority has well-sequenced 
    dt <- dt[dt$over_15>0.9,]

    # get final sites and positions
    dt <- dt[, c("chr", "pos") := tstrsplit(locus, ":", type.convert = TRUE)][, .(chr, pos)]

    # write output
    outfile <- paste0(out_prefix,".txt.gz")
    fwrite(dt, outfile, sep="\t")
}

# add arguments
parser <- ArgumentParser()
parser$add_argument("--input_path", default=NULL, required = TRUE, help = "path to input file")
parser$add_argument("--out_prefix", default=NULL, required = TRUE, help = "Path where the results should be written")
args <- parser$parse_args()

main(args)



