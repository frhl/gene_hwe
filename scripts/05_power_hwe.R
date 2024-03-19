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
    current_k <- as.numeric(args$current_k)
    sample_size <- as.numeric(args$sample_size)
    input_path <- args$input_path
    out_prefix <- args$out_prefix
    
    N <- sample_size
    K <- current_k

    dt <- data.table(
        N = N,
        K = K,
        pA = K/(N*2),
        M_seq = seq(0, (K/2), 1)
    )
      
    # calc thetas
    dt$hets <- dt$K-2*dt$M_seq
    dt$homs <- dt$M_seq
    dt$hets_per_hom <- dt$hets/dt$homs
    dt <- dt[dt$hets_per_hom>1,]
    dt <- dt[dt$hets_per_hom<10001]
    dt$thetas <- unlist(lapply(dt$M_seq, function(M_cur) calc_theta(N, K, M_cur)))
    dt$power <- 0
      
    # only evaluate as long as there is some power
    i <- 0
    cur_power <- 1
    while (cur_power > 0.0001){
        i <- i + 1
        theta_cur <- dt$thetas[i]
        cur_power <- hwe_exact_power(N, K, theta=theta_cur, alternative = alternative, sig.level=sig_level)
        dt$power[i] <- cur_power
    }

    out <- dt
    out$N_label <- factor(sprintf("%sK", out$N / 1000))
    out$F_label <- factor(sprintf("F=%.2f", out$f))
    outfile <- paste0(out_prefix, ".txt")
    write(paste("writing to", outfile), stdout())
    fwrite(out, outfile) 

}

# add arguments
parser <- ArgumentParser()
parser$add_argument("--alternative", default=NULL, help = "?")
parser$add_argument("--current_k", default=NULL, help = "?")
parser$add_argument("--sample_size", default=NULL, help = "?")
parser$add_argument("--sig_level", default=NULL, help = "?")
parser$add_argument("--input_path", default=NULL, help = "?")
parser$add_argument("--out_prefix", default=NULL, help = "?")
args <- parser$parse_args()

main(args)
