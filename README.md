# Usage
The repository AccurateGenomicElements provides a R script called AccurateGenomicElements.R to calculate sensitivity, specificity and accuracy between two groups of samples presenting binary (e.g. presence/absence of genes or kmers) and/or categorical (e.g. profiles of alleles or variants) genomic profiles.
# Dependencies
The R script GenomicBasedMachineLearning.R was prepared and tested with R version 4.2.3.
- require(remotes) # version 2.4.2
- library(optparse) # version 1.7.3
- library(benchmarkme) # version 1.0.8
- library(doParallel) # version 1.0.17
- library(data.table) # version 1.14.2
- library(fastDummies) # version 1.6.3
- library(dplyr) # version 1.0.9
# Expected Input
## 1/ Input mutation file (tsv) with potential empty cells for missing data (GenomicProfiles-100-samples.tsv)
```
Locus	2015.TE.14784.1.19.1	2016.TE.28410.1.48.1	2016.TE.3350.1.18.1	2016.TE.4440.1.41.1
L1	A0			A0			A1			A1
L2	A0			A0			A1			A1
L3	A1			A1			A0			A0
L4	A1			A1			A0			A0
L5	A0			A0			A1			A1
L6	A0			A0			A1			A1
L7	A1						A0			A0
L8	A1			A1			A0			A0
```
## 2/ Input group file (tsv) with labels encoded "A" or "B"
```
sample			group
2015.TE.14784.1.19.1	A
2019.TE.1226.1.3.1	A
2016.TE.28410.1.48.1	A
2019.TE.1367.1.9.1	B
2016.TE.3350.1.18.1	A
2019.TE.602.1.8.1	B
2016.TE.4440.1.41.1	A
```
# Options
```
Usage: /context/AccurateGenomicElements.R [options]
Options:
	-g CHARACTER, --groups=CHARACTER
		Input group file with an absolute or relative path (tab-separated values). First column: sample identifiers identical to the mutation input file (header: 'sample'). Second column: Group labels 'A' or 'B' for each sample (header: 'group'). [MANDATORY]
	-m CHARACTER, --mutations=CHARACTER
		Input mutation file with an absolute or relative path (tab-separated values). First column: loci, positions or names of mutations (header: whatever). Other columns: binary (e.g. presence/absence of genes or kmers) or categorical (e.g. profiles of alleles or variants) profiles of mutations for each sample (header: sample identifiers identical to the group input file). [MANDATORY]
	-c INTEGER, --cpu=INTEGER
		Number of central processing units (CPUs). [OPTIONAL, default = all]
	-t NUMERIC, --sensitivity=NUMERIC
		Sensitivity (%) above which the genomic elements will be retained. [OPTIONAL, default = 0]
	-f NUMERIC, --specificity=NUMERIC
		Specificity (%) above which the genomic elements will be retained. [OPTIONAL, default = 0]
	-a NUMERIC, --accuracy=NUMERIC
		Accuracy (%) above which the genomic elements will be retained. [OPTIONAL, default = 0]
	-r LOGICAL, --rdata=LOGICAL
		Save an external representation of R objects (i.e. saved_data.RData) and a short-cut of the current workspace (i.e. saved_images.RData)’. [OPTIONAL, default = FALSE]
	-o CHARACTER, --prefix=CHARACTER
		Absolute or relative output path with or without output file prefix. [OPTIONAL, default = output_]
	-h, --help
		Show this help message and exit
```
# Install R (Ubuntu 20.04 LTS Focal Fossa)
## 1/ Install additional Ubuntu libraries
```
sudo apt-get update \
    && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev
```
## 2/ Install specific R version (4.2.3)
```
export R_VERSION=4.2.3
apt install -y --no-install-recommends \
  r-base-core=${R_VERSION} \
  r-base-html=${R_VERSION} \
  r-doc-html=${R_VERSION} \
  r-base-dev=${R_VERSION}
```
## 3/ Check installed R version
```
R --version
```
# Unpack GitHub repository and move inside
```
git clone https://github.com/Nicolas-Radomski/AccurateGenomicElements.git
cd AccurateGenomicElements
```
# Install R dependencies and launch with Rscript
## 1/ Install R libraries
```
R
install.packages("remotes") # version 2.4.2
require(remotes)
install_version("optparse", version = "1.7.3", repos = "https://cloud.r-project.org")
install_version("benchmarkme", version = "1.0.8", repos = "https://cloud.r-project.org")
install_version("doParallel", version = "1.0.17", repos = "https://cloud.r-project.org")
install_version("data.table", version = "1.14.2", repos = "https://cloud.r-project.org")
install_version("fastDummies", version = "1.6.3", repos = "https://cloud.r-project.org")
install_version("dplyr", version = "1.0.9", repos = "https://cloud.r-project.org")
quit()
```
## 3/ Launch with Rscript and provided input files
### Call usage
```
Rscript AccurateGenomicElements.R
```
### Call help
```
Rscript AccurateGenomicElements.R -h
```
### Command examples
```
Rscript --max-ppsize=500000 AccurateGenomicElements.R -g GroupLabels-100-samples.tsv -m GenomicProfiles-100-samples.tsv -o test-100-samples_
```
# Install Docker image and launch with Docker
## 1/ Install Docker
### Switch from user to administrator
```
sudo su
```
### Install Docker through snap
```
snap install docker
```
### Switch from administrator to user
```
exit
```
### Create a docker group called docker
```
sudo groupadd docker
```
### Add your user to the docker group
```
sudo usermod -aG docker n.radomski
```
### Activate the modifications of groups
```
newgrp docker
```
### Check the proper installation
```
docker run hello-world
```
## 2/ Pull Docker image from Docker Hub
```
docker pull nicolasradomski/accurategenomicelements:1.0
```
## 2/ Launch with Docker and different input files and options
### Call usage
```
docker run --name nicolas --rm -u `id -u`:`id -g` nicolasradomski/accurategenomicelements:1.0
```
### Call help
```
docker run --name nicolas --rm -u `id -u`:`id -g` nicolasradomski/accurategenomicelements:1.0 -h
```
### Command examples
```
docker run --name nicolas --rm -v $(pwd):/wk -w /wk --ulimit stack=100000000 -e R_MAX_VSIZE=25G nicolasradomski/accurategenomicelements:1.0 -g GroupLabels-100-samples.tsv -m GenomicProfiles-100-samples.tsv -o test-100-samples-dockerhub_
```
# Expected output
- summary_workflow.txt
- results.AversusB.tsv
- results.BversusA.tsv
- saved_data.RData (optional)
- saved_images.RData (optional)
# Illustration
![PCA figure](https://github.com/Nicolas-Radomski/AccurateGenomicElements/blob/main/illustration.png)
# Reference
- GitHub: https://github.com/Nicolas-Radomski/AccurateGenomicElements 
- Docker: https://hub.docker.com/r/nicolasradomski/accurategenomicelements
# Acknowledgment
My GENPAT IZSAM colleagues Adriano Di Pasquale and Andrea De Ruvo for our discussions aiming at managing dummy variables
# Author
Nicolas Radomski
