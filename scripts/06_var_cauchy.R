#!/usr/bin/env Rscript

library(argparse)
library(data.table)


# taken from https://rdrr.io/github/xihaoli/STAAR/src/R/CCT.R
CCT <- function(pvals, weights=NULL){
  #### check if there is NA
  if(sum(is.na(pvals)) > 0){
    stop("Cannot have NAs in the p-values!")
  }

  #### check if all p-values are between 0 and 1
  if((sum(pvals<0) + sum(pvals>1)) > 0){
    stop("All p-values must be between 0 and 1!")
  }

  #### check if there are p-values that are either exactly 0 or 1.
  is.zero <- (sum(pvals==0)>=1)
  is.one <- (sum(pvals==1)>=1)
  if(is.zero && is.one){
    stop("Cannot have both 0 and 1 p-values!")
  }
  if(is.zero){
    return(0)
  }
  if(is.one){
    warning("There are p-values that are exactly 1!")
    return(1)
  }

  #### check the validity of weights (default: equal weights) and standardize them.
  if(is.null(weights)){
    weights <- rep(1/length(pvals),length(pvals))
  }else if(length(weights)!=length(pvals)){
    stop("The length of weights should be the same as that of the p-values!")
  }else if(sum(weights < 0) > 0){
    stop("All the weights must be positive!")
  }else{
    weights <- weights/sum(weights)
  }

  #### check if there are very small non-zero p-values
  is.small <- (pvals < 1e-16)
  if (sum(is.small) == 0){
    cct.stat <- sum(weights*tan((0.5-pvals)*pi))
  }else{
    cct.stat <- sum((weights[is.small]/pvals[is.small])/pi)
    cct.stat <- cct.stat + sum(weights[!is.small]*tan((0.5-pvals[!is.small])*pi))
  }

  #### check if the test statistic is very large.
  if(cct.stat > 1e+15){
    pval <- (1/cct.stat)/pi
  }else{
    pval <- 1-pcauchy(cct.stat)
  }
  return(pval)
}


main <- function(args){

    print(args)

    input_path <- args$input_path
    out_prefix <- args$out_prefix
    pvalue_column <- args$pvalue_column
    dt <- fread(input_path)
    stopifnot(pvalue_column %in% colnames(dt))
    stopifnot("gene_id" %in% colnames(dt))
    stopifnot("N" %in% colnames(dt))

    # remove p-values greater to one because of numerical imprecision
    dt <- dt[dt[[pvalue_column]]<=1,]
    
    genes <- unique(dt$gene_id) 
    # we weight by samples
    out <- do.call(rbind, lapply(genes, function(g){
        dt_gene <- dt[dt$gene_id %in% g, ]
        p_values <- dt_gene[[pvalue_column]]
        weights_by_samples <- dt_gene$N
        cauchy_p <- CCT(p_values, weights_by_samples)
        dt_out <- data.table(
            gene_id=g,
            cauchy_p=cauchy_p,
            n_variants=nrow(dt_gene)
        )
        return(dt_out)
    }))
 

    out <- out[order(out$cauchy_p),]
    outfile <- paste0(out_prefix,".txt")
    fwrite(out, outfile)

}

# add arguments
parser <- ArgumentParser()
parser$add_argument("--input_path", default=NULL, help = "?")
parser$add_argument("--pvalue_column", required=TRUE, default=NULL, help = "?")
parser$add_argument("--out_prefix", default=NULL, help = "?")
args <- parser$parse_args()

main(args)
