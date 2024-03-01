#!/usr/bin/env Rscript

library(argparse)
library(data.table)
library(stringr)


log_n_choose_k <- function(n, k) {
  log_sum <- function(i) {
    if (i==0) {
      return(0)
    } else {
      return(sum(log(seq(1,i))))
    }
  }
  return(log_sum(n) - log_sum(k) - log_sum(n-k))
}

probability_of_M_pairs <- function(N, K, M)
{
  prob <- log_n_choose_k(N, M) +
    log_n_choose_k(N-M, K-2*M) -
    log_n_choose_k(2*N, K) +
    (K - 2*M) * log(2)
  return(prob)
}

sum_probability_of_M_pairs <- function(N, K, M)
{
  if (M > N/2) {
    probs <- rep(0, length(seq(M+1, min(N, floor(K/2)))))
    for(i in seq(M+1, min(N, floor(K/2)))) {
      probs[i-M] <- probability_of_M_pairs(N, K, i)
    }
    return(list(gt=TRUE, prob=probs))
  } else {
    probs <- rep(0, M+1)
    for(i in seq(0, M)) {
      probs[i+1] <- probability_of_M_pairs(N, K, i)
    }
    return(list(gt=FALSE, prob=probs))
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
    for (row in seq(1,nrow(dt))) {
        
        print(paste(row, "of", nrow(dt)))
        N_samples <- as.integer(dt$AN[row]/2)
        p <- sum_probability_of_M_pairs(N_samples, dt$hom_alt_het[row], dt$hom_alt[row])
        prob[row] <- ifelse(p$gt, 1-sum(exp(p$prob)), sum(exp(p$prob)))
        
        cat(prob[row],' ')
        current_min <- min(current_min, prob[row])
        cat("min prob (CH+Homs): ", min(prob, na.rm=TRUE), "\n")
        
    }
      
    # make out file
    dt$hwe_p <- prob
        
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