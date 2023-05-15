#!/usr/bin/env Rscript

#### system specifications ####
# Architecture:                    x86_64
# CPU op-mode(s):                  32-bit, 64-bit
# CPU(s):                          8
# Thread(s) per core:              2
# Core(s) per socket:              4
# Model name:                      Intel(R) Core(TM) i7-10510U CPU @ 1.80GHz
# R:                               4.2.3
# RStudio:                         2022.02.3 Build 492

# install libssl-dev and libcurl4-openssl-dev Ubuntu 20.04 libraries required for the benchmarkme R library
## sudo apt-get update && apt-get install -y libssl-dev
## sudo apt-get update && apt-get install -y libcurl4-openssl-dev

# set process limits (e.g. "--ulimit stack=100000000" as a Docker argument or "ulimit -s 100000000" through a Linux shell) for high performance computing users to prevent "Error: segfault from C stack overflow"

# set the maximum vector heap size (e.g. "-e R_MAX_VSIZE=900G" as a Docker argument or "touch ~/.Renviron | echo R_MAX_VSIZE=900GB > ~/.Renviron" through a Linux shell) for high performance computing users according to available memory ("free -g -h -t" through Linux shell) to prevent "Error: protect(): protection stack overflow"

# skip lines related to installation of libraries because there are supposed to be already installed
skip_instalation <- scan(what="character", quiet = TRUE)
# install libraries
install.packages("remotes") # version 2.4.2
require(remotes)
install_version("optparse", version = "1.7.3", repos = "https://cloud.r-project.org")
install_version("benchmarkme", version = "1.0.8", repos = "https://cloud.r-project.org")
install_version("doParallel", version = "1.0.17", repos = "https://cloud.r-project.org")
install_version("data.table", version = "1.14.8", repos = "https://cloud.r-project.org")
install_version("dplyr", version = "1.1.1", repos = "https://cloud.r-project.org")
install_version("fastDummies", version = "1.6.3", repos = "https://cloud.r-project.org")

# load packages avoiding warning messages
suppressPackageStartupMessages(library(optparse)) # version 1.7.3
suppressPackageStartupMessages(library(benchmarkme)) # version 1.0.8
suppressPackageStartupMessages(library(doParallel)) # version 1.0.17
suppressPackageStartupMessages(library(data.table)) # version 1.14.8
suppressPackageStartupMessages(library(dplyr)) # version 1.1.1
suppressPackageStartupMessages(library(fastDummies)) # version 1.6.3

# clean environment
rm(list=ls())

# clean graphical device
graphics.off()

# set a limit on the number of nested expressions together with maximum size of the pointer protection stack ("Rscript --max-ppsize=500000") to prevent "Error: protect(): protection stack overflow"
options(expressions=500000)

# use English language
invisible(capture.output(Sys.setlocale("LC_TIME", "C")))

# keep in mind start time
start.time <- Sys.time()

# keep in mind start time as human readable
start.time.readable <- format(Sys.time(), "%X %a %b %d %Y")

# identify available CPUs (benchmarkme)
allCPUs <- get_cpu()$no_of_cores

# create a opt list (optparse) that contains all the arguments sorted by order of appearance in option_list and which can be called by their names (e.g. opt$input)
option_list = list(
  make_option(c("-g", "--groups"), type="character", default=NULL, 
              help="Input group file with an absolute or relative path (tab-separated values). First column: sample identifiers identical to the mutation input file (header: 'sample'). Second column: Group labels 'A' or 'B' for each sample (header: 'group'). [MANDATORY]", metavar="character"),
  make_option(c("-m", "--mutations"), type="character", default=NULL, 
              help="Input mutation file with an absolute or relative path (tab-separated values). First column: loci, positions or names of mutations (header: whatever). Other columns: binary (e.g. presence/absence of genes or kmers) or categorical (e.g. profiles of alleles or variants) profiles of mutations for each sample (header: sample identifiers identical to the group input file). [MANDATORY]", metavar="character"),
  make_option(c("-c", "--cpu"), type="integer", default=allCPUs, 
              help="Number of central processing units (CPUs). [OPTIONAL, default = all]", metavar="integer"),
  make_option(c("-t", "--sensitivity"), type="numeric", default=0, 
              help="Sensitivity (%) above which the genomic elements will be retained. [OPTIONAL, default = %default]", metavar="numeric"),
  make_option(c("-f", "--specificity"), type="numeric", default=0, 
              help="Specificity (%) above which the genomic elements will be retained. [OPTIONAL, default = %default]", metavar="numeric"),
  make_option(c("-a", "--accuracy"), type="numeric", default=0, 
              help="Accuracy (%) above which the genomic elements will be retained. [OPTIONAL, default = %default]", metavar="numeric"),
  make_option(c("-r", "--rdata"), type="logical", default=FALSE, 
              help="Save an external representation of R objects (i.e. saved_data.RData) and a short-cut of the current workspace (i.e. saved_images.RData)’. [OPTIONAL, default = %default]", metavar="logical"),
  make_option(c("-o", "--prefix"), type="character", default="output_", 
              help="Absolute or relative output path with or without output file prefix. [OPTIONAL, default = %default]", metavar="character")
); 

# parse the opt list and get opt list as arguments (optparse)
opt_parser <- OptionParser(option_list=option_list);
opt <- suppressWarnings(parse_args(opt_parser));

# prepare a global message for help
help1 <- "Help: Rscript AccurateGenomicElements-20230515.R -h"
help2 <- "Help: Rscript AccurateGenomicElements-20230515.R --help"

# management of mandatory arguments
## arguments -g/--groups and -m/--mutations
if (((is.null(opt$groups)) || (is.null(opt$mutations))) == TRUE){
  cat("\n", 'Version: 1.2', "\n")
  cat("\n", 'Please, provide at least two input files (i.e. mandatory arguments -g and -m) and potentially other optional arguments:', "\n")
  cat("\n", 'Example 1: Rscript --max-ppsize=500000 AccurateGenomicElements-20230515.R -g GroupLabels-100-samples.tsv -m GenomicProfiles-100-samples.tsv', "\n")
  cat("\n", 'Example 2: Rscript --max-ppsize=500000 AccurateGenomicElements-20230515.R -g GroupLabels-100-samples.tsv -c 4 -m GenomicProfiles-100-samples.tsv -c 4 -t 30 -f 50 -a 80 -o MyOutput_', "\n")
  cat("\n", 'Example 3: Rscript --max-ppsize=500000 AccurateGenomicElements-20230515.R --groups GroupLabels-100-samples.tsv --mutations GenomicProfiles-100-samples.tsv --cpu 4 --sensitivity 30 --specificity 50 --accuracy 80 --prefix MyOutput_', "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}

# management of optional arguments
## argument -c/--cpu
if (!grepl("\\D",opt$cpu) == FALSE) {
  cat("\n", "The argument -c/--cpu (number of central processing units) must be an integer (NB: a number with a decimal will return the rounded down integer)", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}
if (((opt$cpu <= 0) || (opt$cpu > allCPUs)) == TRUE) {
  cat("\n", "The argument -c/--cpu (number of central processing units) must be an integer (NB: a number with a decimal will return the rounded down integer) between 1 and the maximum of available CPUs (i.e.", allCPUs, "in your case)", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}
## argument -t/--sensitivity
if (is.numeric(opt$sensitivity) == FALSE) {
  cat("\n", "The argument -t/--sensitivity must be a positive whole number or a positive number with a decimal between 0 and 100", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}
if (((opt$sensitivity < 0) || (opt$sensitivity > 100)) == TRUE) {
  cat("\n", "The argument -t/--sensitivity must be a positive whole number or a positive number with a decimal between 0 and 100", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}
## argument -f/--specificity
if (is.numeric(opt$specificity) == FALSE) {
  cat("\n", "The argument -f/--specificity must be a positive whole number or a positive number with a decimal between 0 and 100", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}
if (((opt$specificity < 0) || (opt$specificity > 100)) == TRUE) {
  cat("\n", "The argument -f/--specificity must be a positive whole number or a positive number with a decimal between 0 and 100", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}
## argument -a/--accuracy
if (is.numeric(opt$accuracy) == FALSE) {
  cat("\n", "The argument -a/--accuracy must be a positive whole number or a positive number with a decimal between 0 and 100", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}
if (((opt$accuracy < 0) || (opt$accuracy > 100)) == TRUE) {
  cat("\n", "The argument -a/--accuracy must be a positive whole number or a positive number with a decimal between 0 and 100", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}
## argument -r/--rdata
if (((isTRUE(opt$rdata)) || (isFALSE(opt$rdata))) == FALSE){
  cat("\n", "The argument -r/--rdata must be logical (TRUE or FALSE)", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}

# management of threads
## set desired CPUs and print
setDTthreads(threads = opt$cpu, restore_after_fork = TRUE, throttle = 1024)
cat("\n", "Used CPUs:", opt$cpu, ".... Please wait","\n")
## create a computing cluster and register
cluster <- makePSOCKcluster(opt$cpu)
registerDoParallel(cluster)

# step control
step1.time <- Sys.time()
step1.taken <- difftime(step1.time, start.time, units="secs")
cat(" Step 1 completed: checking of arguments, approx. ", ceiling(step1.taken), " second(s)", "\n", sep = "")

# prepare the dataframe of groups
## read the dataframe of groups preventing "X." as prefix in header variables
data_groups <- fread(opt$groups, dec = ".", header=TRUE, sep = "\t", check.names = FALSE)
## replace by "mutation" the second variable
names(data_groups)[2] <- "group"
## test if the group variable is constituted of A or B
### expected length
AB <- length(data_groups$group)
### expected length of A
A <- length(which(data_groups$group=="A"))
### expected length of B
B <- length(which(data_groups$group=="B"))
if ((AB - A - B) != 0) {
  cat("\n", "The second variable (i.e. 'group') of the input group file must only be labeled with 'A' or 'B'", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}

# prepare the dataframe of mutations
## read the dataframe of mutations preventing "X." as prefix in header variables
data_mutations <- fread(opt$mutations, dec = ".", header=TRUE, sep = "\t", check.names = FALSE)
## replace by "mutation" the first variable
names(data_mutations)[1] <- "mutation"
## replace missing data by NA
data_mutations[data_mutations == ''] <- NA
## replace missing data encoded "" with missing"
data_mutations[is.na(data_mutations)] <- "empty"
## transpose dataframe (data.table)
trans_data_mutations <- transpose(data_mutations, keep.names = "sample", make.names = "mutation")

# test equality of sample identifiers from the input group and mutation files
## sample identifiers from the input group file
IDs.groups <- sort(data_groups$sample, decreasing=FALSE)
## sample identifiers from the input group file
IDs.mutations <- sort(trans_data_mutations$sample, decreasing=FALSE)
## test equality
if (identical(IDs.groups, IDs.mutations) == FALSE) {
  cat("\n", "The sample identifiers from the input group and mutations files must be identical", "\n")
  cat("\n", help1, "\n")
  cat("\n", help2, "\n", "\n")
  stop()
}

# step control
step2.time <- Sys.time()
step2.taken <- difftime(step2.time, step1.time, units="secs")
cat(" Step 2 completed: reading, transposition and preparation of dataframes, approx. ", ceiling(step2.taken), " second(s)", "\n", sep = "")

# transform the categorical genomic profiles into binary genomic profiles (fastDummies: 1.6.3, 2020-11-29)
## retrieve sample identifiers
sample <- trans_data_mutations$sample
## keep mutations in the dataframe
col <- ncol(trans_data_mutations)
df <- trans_data_mutations[,2:col]

# identify binary variables
is.binary <- apply(df,2,function(x) {all(x %in% 0:1)})
# get dataframe of binary variable identification
df.is.binary <- as.data.frame(is.binary)
# get vector of binary variables
binary.df <- subset(df.is.binary, is.binary == "TRUE")
binary.vec <- row.names(binary.df)
# get vector of binary variables
categorical.df <- subset(df.is.binary, is.binary == "FALSE")
categorical.vec <- row.names(categorical.df)

## transformation of categorical profiles into binary profiles
if (length(categorical.vec) > 1){
  ### in case of presence of categorical variables
  binary_trans_data_mutations <- dummy_cols(df, select_columns = categorical.vec,
                                            remove_first_dummy = FALSE,
                                            remove_most_frequent_dummy = FALSE,
                                            remove_selected_columns = TRUE)
} else {
  ### in case of absence of categorical variables
  binary_trans_data_mutations <- df
}
## put back the sample identifiers
binary_trans_data_mutations <- cbind(sample, binary_trans_data_mutations)

# step control
step3.time <- Sys.time()
step3.taken <- difftime(step3.time, step2.time, units="secs")
cat(" Step 3 completed: transformation of categorical profiles into binary profiles, approx. ", ceiling(step3.taken), " second(s)", "\n", sep = "")

## joint (dplyr)
joint_binary_trans_data_mutations <- suppressWarnings(left_join(data_groups, binary_trans_data_mutations, by = "sample", keep = FALSE))

# step control
step4.time <- Sys.time()
step4.taken <- difftime(step4.time, step3.time, units="secs")
cat(" Step 4 completed: jointing of dataframes, approx. ", ceiling(step4.taken), " second(s)", "\n", sep = "")

# splitting of group labels
## for the group A
data_A <- subset(joint_binary_trans_data_mutations, group == 'A')
data_A <- data_A[,-2]
## for the group B
data_B <- subset(joint_binary_trans_data_mutations, group == 'B')
data_B <- data_B[,-2]

# step control
step5.time <- Sys.time()
step5.taken <- difftime(step5.time, step4.time, units="secs")
cat(" Step 5 completed: splitting into dataframes according to groups, approx. ", ceiling(step5.taken), " second(s)", "\n", sep = "")

# transpose dataframes of group labels (data.table)
## for the group of interest (Gi)
trans_data_A <- transpose(data_A, keep.names = "genotype", make.names = "sample")
trans_data_B <- transpose(data_B, keep.names = "genotype", make.names = "sample")

# step control
step6.time <- Sys.time()
step6.taken <- difftime(step6.time, step5.time, units="secs")
cat(" Step 6 completed: transpositon of group specific dataframes, approx. ", ceiling(step6.taken), " second(s)", "\n", sep = "")

# calculate metrics
## group A versus group B
### true positive (TP)
TP.AvB <- apply(trans_data_A, 1, function(x) length(which(x==1)))
### false negative (FN)
FN.AvB <- apply(trans_data_A, 1, function(x) length(which(x==0)))
### true negative (TN)
TN.AvB <- apply(trans_data_B, 1, function(x) length(which(x==0)))
### false positive (FP)
FP.AvB <- apply(trans_data_B, 1, function(x) length(which(x==1)))
### sensitivity (Se=TP/(TP+FN))
Se.AvB <- TP.AvB/(TP.AvB+FN.AvB)*100
### specificity (Sp=TN/(TN+FP))
Sp.AvB <- TN.AvB/(TN.AvB+FP.AvB)*100
### accuracy (Ac=(TP+TN)/(TP+TN+FP+FN))
Ac.AvB <- (TP.AvB+TN.AvB)/(TP.AvB+TN.AvB+FP.AvB+FN.AvB)*100
### retrieve genotype identifiers
genotype <- trans_data_A$genotype
### combine
results.AvB <- as.data.frame(cbind(genotype, TP.AvB, FN.AvB, TN.AvB, FP.AvB, Se.AvB, Sp.AvB, Ac.AvB))
### rename variables
names(results.AvB)[names(results.AvB) == "TP.AvB"] <- "TP"
names(results.AvB)[names(results.AvB) == "FN.AvB"] <- "FN"
names(results.AvB)[names(results.AvB) == "TN.AvB"] <- "TN"
names(results.AvB)[names(results.AvB) == "FP.AvB"] <- "FP"
names(results.AvB)[names(results.AvB) == "Se.AvB"] <- "Se"
names(results.AvB)[names(results.AvB) == "Sp.AvB"] <- "Sp"
names(results.AvB)[names(results.AvB) == "Ac.AvB"] <- "Ac"
### transform as integer
cols.int <- c("TP", "FN", "TN", "FP")
results.AvB[cols.int] <- sapply(results.AvB[cols.int],as.integer)
### transform as numeric
cols.num <- c("Se", "Sp", "Ac")
results.AvB[cols.num] <- sapply(results.AvB[cols.num],as.numeric)
## group B versus group A
### true positive (TP)
TP.BvA <- apply(trans_data_B, 1, function(x) length(which(x==1)))
### false negative (FN)
FN.BvA <- apply(trans_data_B, 1, function(x) length(which(x==0)))
### true negative (TN)
TN.BvA <- apply(trans_data_A, 1, function(x) length(which(x==0)))
### false positive (FP)
FP.BvA <- apply(trans_data_A, 1, function(x) length(which(x==1)))
### sensitivity (Se=TP/(TP+FN))
Se.BvA <- TP.BvA/(TP.BvA+FN.BvA)*100
### specificity (Sp=TN/(TN+FP))
Sp.BvA <- TN.BvA/(TN.BvA+FP.BvA)*100
### accuracy (Ac=(TP+TN)/(TP+TN+FP+FN))
Ac.BvA <- (TP.BvA+TN.BvA)/(TP.BvA+TN.BvA+FP.BvA+FN.BvA)*100
### retrieve genotype identifiers
genotype <- trans_data_A$genotype
### combine
results.BvA <- as.data.frame(cbind(genotype, TP.BvA, FN.BvA, TN.BvA, FP.BvA, Se.BvA, Sp.BvA, Ac.BvA))
### rename variables
names(results.BvA)[names(results.BvA) == "TP.BvA"] <- "TP"
names(results.BvA)[names(results.BvA) == "FN.BvA"] <- "FN"
names(results.BvA)[names(results.BvA) == "TN.BvA"] <- "TN"
names(results.BvA)[names(results.BvA) == "FP.BvA"] <- "FP"
names(results.BvA)[names(results.BvA) == "Se.BvA"] <- "Se"
names(results.BvA)[names(results.BvA) == "Sp.BvA"] <- "Sp"
names(results.BvA)[names(results.BvA) == "Ac.BvA"] <- "Ac"
### transform as integer
cols.int <- c("TP", "FN", "TN", "FP")
results.BvA[cols.int] <- sapply(results.BvA[cols.int],as.integer)
### transform as numeric
cols.num <- c("Se", "Sp", "Ac")
results.BvA[cols.num] <- sapply(results.BvA[cols.num],as.numeric)

# step control
step7.time <- Sys.time()
step7.taken <- difftime(step7.time, step6.time, units="secs")
cat(" Step 7 completed: computation of metrics, approx. ", ceiling(step7.taken), " second(s)", "\n", sep = "")

# subselect
## according to sensitivity
results.AvB.subselection <- subset(results.AvB, Se >= opt$sensitivity)
results.BvA.subselection <- subset(results.BvA, Se >= opt$sensitivity)
## according to specificity
results.AvB.subselection <- subset(results.AvB, Sp >= opt$specificity)
results.BvA.subselection <- subset(results.BvA, Sp >= opt$specificity)
## according to accuracy
results.AvB.subselection <- subset(results.AvB, Ac >= opt$accuracy)
results.BvA.subselection <- subset(results.BvA, Ac >= opt$accuracy)

# step control
step8.time <- Sys.time()
step8.taken <- difftime(step8.time, step7.time, units="secs")
cat(" Step 8 completed: selection of genomic profiles according to metric thresholds, approx. ", ceiling(step8.taken), " second(s)", "\n", sep = "")

# combine results from both comparisons "AversusB" and "BversusA"
# add column called "comparison"
results.AvB.subselection$comparison <- "AversusB"
results.BvA.subselection$comparison <- "BversusA"
# reorder columns
col_order <- c("genotype", "comparison",	"TP",	"FN",	"TN",	"FP",	"Se",	"Sp",	"Ac")
results.AvB.subselection <- results.AvB.subselection[, col_order]
results.BvA.subselection <- results.BvA.subselection[, col_order]
# combine dataframes
results.combined.subselection <- rbind(results.AvB.subselection, results.BvA.subselection)

# sort according to accuracy
results.AvB.subselection <- results.AvB.subselection[order(results.AvB.subselection$Ac, decreasing = TRUE),]
results.BvA.subselection <- results.BvA.subselection[order(results.BvA.subselection$Ac, decreasing = TRUE),]
results.combined.subselection <- results.combined.subselection[order(results.combined.subselection$Ac, decreasing = TRUE),]

# control digits
## group A versus group B
results.AvB.subselection$Se <- format(round(results.AvB.subselection$Se, 2), nsmall = 2)
results.AvB.subselection$Sp <- format(round(results.AvB.subselection$Sp, 2), nsmall = 2)
results.AvB.subselection$Ac <- format(round(results.AvB.subselection$Ac, 2), nsmall = 2)
## group B versus group A
results.BvA.subselection$Se <- format(round(results.BvA.subselection$Se, 2), nsmall = 2)
results.BvA.subselection$Sp <- format(round(results.BvA.subselection$Sp, 2), nsmall = 2)
results.BvA.subselection$Ac <- format(round(results.BvA.subselection$Ac, 2), nsmall = 2)
## combined comparisons
results.combined.subselection$Se <- format(round(results.combined.subselection$Se, 2), nsmall = 2)
results.combined.subselection$Sp <- format(round(results.combined.subselection$Sp, 2), nsmall = 2)
results.combined.subselection$Ac <- format(round(results.combined.subselection$Ac, 2), nsmall = 2)

# export results
fwrite(results.combined.subselection, file = paste(opt$prefix, "results.tsv", sep = ""), append = FALSE, quote = FALSE, sep = "\t", dec = ".", row.names = FALSE, col.names = TRUE)

# output RData
if (isTRUE(opt$rdata)){
  ## to load with load("output_saved_data.RData")
  save(list = ls(), file = paste(opt$prefix, "saved_data.RData", sep = ""))
  ## to load with load("output_saved_images.RData")
  save.image(file = paste(opt$prefix, "saved_images.RData", sep = ""))
}

# step control
step9.time <- Sys.time()
step9.taken <- difftime(step9.time, step8.time, units="secs")
cat(" Step 9 completed: merging and writting of results, approx. ", ceiling(step9.taken), " second(s)", "\n", sep = "")

# keep in mind end time
end.time <- Sys.time()

# calculate execution time
time.taken <- difftime(end.time, start.time, units="secs")

# export output log
## output in a summary.txt file
sink(paste(opt$prefix, "summary.txt", sep = ""))
## print
cat("\n", "###########################################################")
cat("\n", "####################### Information #######################")
cat("\n", "###########################################################", "\n")
cat("\n", "Running start:", start.time.readable, "\n")
cat("\n", "Running time (seconds):", time.taken, "\n")
cat("\n", " Outcomes: ", opt$prefix,"\n", sep = "")
cat("\n", "Developped by Nicolas Radomski during April 2023 with the R version", strsplit(version[['version.string']], ' ')[[1]][3], "\n")
cat("\n", "###########################################################")
cat("\n", "######################### Versions ########################")
cat("\n", "###########################################################", "\n")
cat("\n", "R:", strsplit(version[['version.string']], ' ')[[1]][3], "\n")
cat("\n", "optparse:", getNamespaceVersion("optparse"), "\n")
cat("\n", "benchmarkme:", getNamespaceVersion("benchmarkme"), "\n")
cat("\n", "doParallel:", getNamespaceVersion("doParallel"), "\n")
cat("\n", "data.table:", getNamespaceVersion("data.table"), "\n")
cat("\n", "dplyr:", getNamespaceVersion("dplyr"), "\n")
cat("\n", "fastDummies:", getNamespaceVersion("fastDummies"), "\n")
cat("\n", "###########################################################")
cat("\n", "######################## References #######################")
cat("\n", "###########################################################", "\n")
cat("\n", "Please cite:", "\n")
cat("\n", "GitHub: https://github.com/Nicolas-Radomski/AccurateGenomicElements", "\n")
cat("\n", "Docker: https://hub.docker.com/r/nicolasradomski/accurategenomicelements", "\n")
cat("\n", "###########################################################")
cat("\n", "######################### Setting #########################")
cat("\n", "###########################################################", "\n")
cat("\n", "Input group file path:", opt$groups, "\n")
cat("\n", "Input mutation file path:", opt$mutations, "\n")
cat("\n", "Number of central processing units:", opt$cpu, "\n")
cat("\n", "Sensitivity threshold (%):", opt$sensitivity, "\n")
cat("\n", "Specificity threshold (%):", opt$specificity, "\n")
cat("\n", "Accuracy threshold (%):", opt$accuracy, "\n")
cat("\n", "Output prefix:", opt$prefix, "\n")
cat("\n", "###########################################################")
cat("\n", "######################### Metrics #########################")
cat("\n", "###########################################################", "\n")
cat("\n", "Number of samples:", nrow(trans_data_mutations), "\n")
cat("\n", "Number of samples labeled group 'A':", nrow(data_A), "\n")
cat("\n", "Number of samples labeled group 'B':", nrow(data_B), "\n")
cat("\n", "Number of provided genomic profiles:", ncol(trans_data_mutations)-1, "\n")
cat("\n", "Number of provided binary genomic profiles:", length(binary.vec), "\n")
cat("\n", "Number of provided catagorical genomic profiles:", length(categorical.vec), "\n")
cat("\n", "Number of binary genomic profiles after transformation of categorical profiles into binary profiles:", ncol(joint_binary_trans_data_mutations)-2, "\n")
cat("\n", "Number of remaining binary genomic profiles after threshold-based filtration (group A versus group B):", nrow(results.AvB.subselection), "\n")
cat("\n", "Number of remaining binary genomic profiles after threshold-based filtration (group B versus group A):", nrow(results.BvA.subselection), "\n")
cat("\n", "Number of remaining binary genomic profiles after threshold-based filtration (group A versus group B and group B versus group A):", nrow(results.combined.subselection), "\n")
cat("\n", "###########################################################")
cat("\n", "####################### Output files ######################")
cat("\n", "###########################################################", "\n")
cat("\n", paste(opt$prefix, "results.tsv", sep = ""), "\n")
cat("\n", paste(opt$prefix, "summary.txt", sep = ""), "\n")
if (isTRUE(opt$rdata)){
  cat("\n", paste(opt$prefix, "saved_data.RData", sep = ""), "\n")
  cat("\n", paste(opt$prefix, "saved_images.RData", sep = ""), "\n")
}
cat("\n")

## close summary.txt
sink()

## stop the computing cluster
stopCluster(cluster)

# add messages
cat("\n", "Running time (seconds):", time.taken, "\n")
cat("\n", " Outcomes are ready: ", opt$prefix,"\n", sep = "")
cat("\n", "Developped by Nicolas Radomski during April 2023 with the R version", strsplit(version[['version.string']], ' ')[[1]][3], "\n")
cat("\n", "Please cite:", "\n")
cat("\n", "GitHub: https://github.com/Nicolas-Radomski/AccurateGenomicElements", "\n")
cat("\n", "Docker: https://hub.docker.com/r/nicolasradomski/accurategenomicelements", "\n", "\n")
