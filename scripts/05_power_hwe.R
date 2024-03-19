#!/usr/bin/env Rscript

library(argparse)
library(data.table)
library(stringr)
library(dplyr)
library(hardyr)



main <- function(args){

    print(args)

    alternative <- args$alternative
    sig_level <- as.numeric(args$sig_level)
    theta <- as.numeric(args$theta)
    sample_size <- as.numeric(args$sample_size)
    input_path <- args$input_path
    out_prefix <- args$out_prefix
    

    N <- sample_size

    nA_seq <- seq(0, (N*2)*0.1, by=100)
    out <- do.call(rbind, lapply(nA_seq, function(nA) {
      pA <- nA / (N * 2)
      power <- hwe_exact_power(N, nA, theta=theta, alternative=alternative, sig.level = sig_level)
      data.table(N, pA, nA, theta, power, alternative, alpha=sig_level)
    }))

    out$N_label <- factor(sprintf("%sK", out$N / 1000))
    out$F_label <- factor(sprintf("F=%.2f", out$f))
    outfile <- paste0(out_prefix, ".txt")
    write(paste("writing to", outfile), stdout())
    fwrite(out, outfile) 

}

# add arguments
parser <- ArgumentParser()
parser$add_argument("--alternative", default=NULL, help = "?")
parser$add_argument("--theta", default=NULL, help = "?")
parser$add_argument("--sample_size", default=NULL, help = "?")
parser$add_argument("--sig_level", default=NULL, help = "?")
parser$add_argument("--input_path", default=NULL, help = "?")
parser$add_argument("--out_prefix", default=NULL, help = "?")
args <- parser$parse_args()

main(args)
