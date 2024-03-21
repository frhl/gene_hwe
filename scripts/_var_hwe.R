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
    idx_start <- args$idx_start
    idx_end <- args$idx_end

    dt <- fread(input_path)

    # subset if need be
    if ((!is.null(idx_start) & (!is.null(idx_end)))){
        idx_start <- as.numeric(idx_start)
        idx_end <- min(as.numeric(idx_end), nrow(dt))
        dt <- dt[idx_start:idx_end,]
    }

    stopifnot("hom_alt" %in% colnames(dt))
    stopifnot("hom_alt_het" %in% colnames(dt))
    stopifnot("AN" %in% colnames(dt))

    # get probs
    current_min <- 1
    prob <- rep(NA, nrow(dt))
    prob_midp_greater <- rep(NA, nrow(dt))
    prob_midp_less <- rep(NA, nrow(dt))
    thetas <- rep(NA, nrow(dt))
    N_values <- rep(NA, nrow(dt))
    K_values <- rep(NA, nrow(dt))
    M_values <- rep(NA, nrow(dt))
    
    for (row in seq(1,nrow(dt))) {
       
        print(paste(row, "of", nrow(dt)))
        N <- as.integer(dt$AN[row]/2)
        K <- dt$MAC[row]
        M <- dt$hom_alt[row]
     
        N_values[row] <- N
        K_values[row] <- K
        M_values[row] <- M
        thetas[row] <- calc_theta(N, K, M)
        
        mid_p_greater <- hwe_exact_test(N, K, M, theta=4, alternative="greater", use_mid_p=TRUE)
        prob_midp_greater[row] <- mid_p_greater 
    }
      
    # make out file
    dt$hwe_mid_p <- prob_midp_greater 
    dt$theta <- thetas
    dt$N <- N_values
    dt$K <- K_values
    dt$M <- M_values
    dt$pA <- dt$K / (dt$N * 2)

    # export all
    outfile <- paste0(out_prefix,".txt.gz")
    fwrite(dt, outfile)

}

# add arguments
parser <- ArgumentParser()
parser$add_argument("--input_path", default=NULL, help = "?")
parser$add_argument("--out_prefix", default=NULL, help = "?")
parser$add_argument("--idx_start", default=NULL, help = "?")
parser$add_argument("--idx_end", default=NULL, help = "?")
args <- parser$parse_args()

main(args)
