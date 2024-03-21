#!/usr/bin/env Rscript

library(data.table)
library(argparse)

main <- function(args){
    
    print(args)
    
    input_path <- args$input_path
    vep_path <- args$vep_path
    qc_path <- args$qc_path
    pop <- args$population
    out_prefix <- args$out_prefix
    an_cutoff <- as.integer(args$AN_cutoff) # Ensure AN_cutoff is treated as an integer
    ac_cutoff <- as.integer(args$AC_cutoff) # Ensure AN_cutoff is treated as an integer
    max_MAF_cutoff <- as.numeric(args$max_MAF_cutoff)

    # Load the data table from the input path
    qc <- fread(qc_path)
    dt <- fread(input_path)
    vep <- fread(vep_path)
    vep <- vep[vep$canonical == 1,]
    vep <- vep[vep$biotype == "protein_coding",]
    

    gene_map <- vep$gene_id
    names(gene_map) <- vep$varid

    # Construct column names based on the specified population
    ac_col <- paste("AC", pop, sep="_")
    an_col <- paste("AN", pop, sep="_")
    nhomalt_col <- paste("nhomalt", pop, sep="_")
    columns_to_keep <- c("SNPID", ac_col, an_col, nhomalt_col)
    
    # Filter the data table to keep only the specified columns
    dt_filtered <- dt[, ..columns_to_keep]

    # Remove rows where AN value for the population is below the AN_cutoff
    dt_filtered <- dt_filtered[get(an_col) > 0]
    dt_filtered <- dt_filtered[get(an_col) >= an_cutoff]
    dt_filtered <- dt_filtered[get(ac_col) >= ac_cutoff]

    # do some filtering and caulate counts needed
    colnames(dt_filtered) <- c("SNPID", "AC", "AN", "hom_alt")
    dt_filtered$gene_id <- gene_map[dt_filtered$SNPID]
    dt_filtered[, het := AC - (2*hom_alt) ]
    dt_filtered[, hom_ref := (AN/2) - hom_alt - het ]
    dt_filtered[, hom_alt_het := (2*hom_alt) + het ]
    dt_filtered[, MAC := pmin(AC, AN-AC)] 
    dt_filtered[, MAF := MAC / AN] 

    # only keep those where MAC is AAC (alternate allele count)
    dt_filtered <- dt_filtered[dt_filtered$AC == dt_filtered$MAC,]

    # remove based on MAF cutoff
    dt_filtered <- dt_filtered[dt_filtered$MAF < max_MAF_cutoff]

    # get chromosome and position
    dt_filtered <- dt_filtered[, c("chr", "pos") := tstrsplit(SNPID, ":", fixed = TRUE, keep = 1:2)]
    chromosome <- unique(dt_filtered$chr)
    print(nrow(dt_filtered)) 
    
    qc <- qc[qc$chr %in% chromosome,]
    dt_filtered <- dt_filtered[dt_filtered$pos %in% qc$pos,]
    stopifnot(nrow(dt_filtered)>0)
    print(nrow(dt_filtered)) 
    

    # split by vep consequence
    # Write the filtered data table to the output path
    annotations <- na.omit(unique(vep$brava_csqs))
    print(paste("Total annotations to process:", length(annotations)))
    for (anno in annotations) {
        snps_to_keep <- vep$varid[vep$brava_csqs %in% anno]
        dt_filtered_out <- dt_filtered[dt_filtered$SNPID %in% snps_to_keep,]
        out_file <- paste0(out_prefix, ".", anno, ".txt.gz")
        print(paste("Processing annotation:", anno, "with", nrow(dt_filtered_out), "rows"))
        fwrite(dt_filtered_out, out_file, sep="\t")
    }

    # also do pLoF + damaging missense
    snps_to_keep <- vep$varid[vep$brava_csqs %in% c("pLoF", "damaging_missense")]
    dt_filtered_out <- dt_filtered[dt_filtered$SNPID %in% snps_to_keep,]
    out_file <- paste0(out_prefix, ".pLoF_damaging_missense.txt.gz")
    print(paste("Processing annotation:", "pLoF_damaging_missense", "with", nrow(dt_filtered_out), "rows"))
    fwrite(dt_filtered_out, out_file, sep="\t")

}

# add arguments
parser <- ArgumentParser()
parser$add_argument("--input_path", default=NULL, required = TRUE, help = "path to input file")
parser$add_argument("--vep_path", default=NULL, required = TRUE, help = "path to input file")
parser$add_argument("--qc_path", default=NULL, required = TRUE, help = "path to qc file")
parser$add_argument("--population", default=NULL, required = TRUE, help = "Population code to filter columns by (e.g., nfe, afr, eas)")
parser$add_argument("--out_prefix", default=NULL, required = TRUE, help = "Path where the results should be written")
parser$add_argument("--AN_cutoff", type="integer", default=0, required = TRUE, help = "AN cutoff below which rows will be removed")
parser$add_argument("--AC_cutoff", type="integer", default=0, required = TRUE, help = "AC cutoff below which rows will be removed")
parser$add_argument("--max_MAF_cutoff", type="double", default=0.5, required = FALSE, help = "MAF cutoff for which to remove variants")
args <- parser$parse_args()

main(args)



