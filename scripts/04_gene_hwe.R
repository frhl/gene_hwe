#!/usr/bin/env Rscript

library(argparse)
library(data.table)
library(stringr)
library(dplyr)
library(hardyr)



main <- function(args){

    print(args)

    input_path <- args$input_path
    out_prefix <- args$out_prefix

    dt <- fread(input_path)

    dt$pA <- dt$mac/dt$AN
    # get probs
    current_min <- 1
    old_prob <- rep(NA, nrow(dt))
    prob <- rep(NA, nrow(dt))
    prob_midp <- rep(NA, nrow(dt))
    old_prob_midp <- rep(NA, nrow(dt))
    allele_flip <- rep(FALSE, nrow(dt))
    for (row in seq(1,nrow(dt))) {

        N <- as.integer(dt$N_samples[row])
        nA <- dt$mac[row]
        nAB <- dt$het[row]   
        nAA <- dt$hom_alt[row]

        print(paste(row, "of", nrow(dt), " .. N =", N, "nA =", nA, "nAB =", nAB, "nAA =", nAA))

        # check if major/minor allele has been flipped
        actual_mac <- get_mac(N, nA, nAA)
        if (actual_mac != nA) allele_flip[row] <- TRUE

        # use hardyr package to get to gene-level HWE 
        p <- hwe_exact_test(N, nA, nAA, theta=4, alternative="greater", use_mid_p=TRUE)
        mid_p <- hwe_exact_test(N, nA, nAA, theta=4, alternative="greater", use_mid_p=TRUE)
        prob[row] <- p
        prob_midp[row] <- mid_p 

        cat(prob[row],' ')
        current_min <- min(current_min, prob[row])
        cat("min prob (CH+Homs): ", min(prob, na.rm=TRUE), "\n")
        
    }
      
    # make out file
    dt$allele_flip <- allele_flip
    dt$hwe_p <- prob
    dt$hwe_mid_p <- prob_midp    

    # export all
    outfile <- paste0(out_prefix,".txt.gz")
    fwrite(dt, outfile)

}

# add arguments
parser <- ArgumentParser()
parser$add_argument("--input_path", default=NULL, help = "?")
parser$add_argument("--out_prefix", default=NULL, help = "?")
args <- parser$parse_args()

main(args)
