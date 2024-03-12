#!/usr/bin/env Rscript

library(argparse)
library(data.table)
library(stringr)
library(dplyr)
library(Rcpp)

# Source C++  files to speed up computation
cpp_path <- "/well/lindgren-ukbb/projects/ukbb-11867/flassen/projects/KO/wes_ko_ukbb_nexus/scripts/counts/gene_hwe/01_gene_hwe.cpp"
Rcpp::sourceCpp(cpp_path)

sum_probability_of_M_pairs <- function(N, K, M, midp=TRUE)
{

  # N - individuals in population
  # K - total mutated gene copies
  # M - the number of samples that have a biallelic variant in the gene
  stopifnot(is.numeric(N))
  stopifnot(is.numeric(K))
  stopifnot(is.numeric(M))
  stopifnot(is.logical(midp))

  if (K>(N*2)) stop("Mutated haplotypes (K) cannot exceed total number of haplotypes in population (N*2)!")
  if ((2*M)>K) stop("Bi-allelic haplotypes (2*M) cannot exceed number of mutated haplotypes (K)!" )

  probs_midp <- NULL

  if (M > N/2) {
    probs <- rep(0, length(seq(M+1, min(N, floor(K/2)))))
    for(i in seq(M+1, min(N, floor(K/2)))) {
      probs[i-M] <- probability_of_M_pairs(N, K, i)
    }

    if (midp && length(probs) > 0) {
      probs_midp <- probs
      probs_midp[1] <- probs_midp[1] + log(1/2)
    }

    return(list(gt=TRUE, prob=probs, prob_midp=probs_midp))

  } else {
    probs <- rep(0, M+1)
    for(i in seq(0, M)) {
      probs[i+1] <- probability_of_M_pairs(N, K, i)

    }
    if (midp && length(probs) > 0){
      probs_midp <- probs
      probs_midp[i+1] <- probability_of_M_pairs(N, K, i)+log(1/2)
    }
    return(list(gt=FALSE, prob=probs, prob_midp=probs_midp))
  }
}




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
    prob_midp <- rep(NA, nrow(dt))
    for (row in seq(1,nrow(dt))) {
        
        print(paste(row, "of", nrow(dt)))
        N_samples <- as.integer(dt$AN[row]/2)
        p <- sum_probability_of_M_pairs(N_samples, dt$hom_alt_het[row], dt$hom_alt[row])
        prob[row] <- ifelse(p$gt, 1-sum(exp(p$prob)), sum(exp(p$prob)))
        prob_midp[row] <- ifelse(p$gt, 1-sum(exp(p$prob_midp)), sum(exp(p$prob_midp)))
        
        cat(prob[row],' ')
        current_min <- min(current_min, prob[row])
        cat("min prob (CH+Homs): ", min(prob, na.rm=TRUE), "\n")
        
    }
      
    # make out file
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
parser$add_argument("--idx_start", default=NULL, help = "?")
parser$add_argument("--idx_end", default=NULL, help = "?")
args <- parser$parse_args()

main(args)
