# Usage
The repository AccurateGenomicElements provides a R script called AccurateGenomicElements.R to calculate sensitivity, specificity and accuracy between two groups of samples presenting binary (e.g. presence/absence of genes or kmers) and/or categorical (e.g. profiles of alleles or variants) genomic profiles.
# Dependencies
The R script GenomicBasedMachineLearning.R was prepared and tested with R version 4.2.3.
- require(remotes) # version 2.4.2
- library(optparse) # version 1.7.3
- library(benchmarkme) # version 1.0.8
- library(doParallel) # version 1.0.17
- library(data.table) # version 1.14.8
- library(dplyr) # version 1.1.1
- library(fastDummies) # version 1.6.3
# Expected Input
## 1/ Input group file (tsv) with labels encoded "A" or "B" (e.g. GroupLabels-100-samples.tsv)
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
## 2/ Input mutation file (tsv) with potential empty cells for missing data (e.g. GenomicProfiles-100-samples.tsv)
```
sample			L1	L2	L3	L4	L5	L6	L7	L8
2015.TE.14784.1.19.1	A0	A0	A1	A1	A0	A0	A1	A1
2016.TE.28410.1.48.1	A0	A0	A1	A1	A0	A0	A0	A1
2016.TE.3350.1.18.1	A1	A1	A0	A0		A1	A0	A0
2016.TE.4440.1.41.1	A1	A1	A0	A0	A1	A1	A1	A0
2018.TE.15762.1.12.1	A0	A0	A1	A1	A0	A0	A1	A1
2019.TE.1226.1.3.1	A0	A0	A1	A1	A0	A0	A0	A1
```
# Options
```
Options:
	-g CHARACTER, --groups=CHARACTER
		Input group file with an absolute or relative path (tab-separated values). First column: sample identifiers identical to the mutation input file (header: 'sample'). Second column: Group labels 'A' or 'B' for each sample (header: 'group'). [MANDATORY]
	-m CHARACTER, --mutations=CHARACTER
		Input mutation file with an absolute or relative path (tab-separated values). First column: sample identifiers identical to the group input file (header: 'sample'). Other columns: binary (e.g. presence/absence of genes or kmers) or categorical (e.g. profiles of alleles or variants) profiles of mutations for each sample (header: labels of genomic profiles). [MANDATORY]
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
# Install Docker (Ubuntu 20.04 LTS Focal Fossa)
## 1/ Switch from user to administrator
```
sudo su
```
## 2/ Install Docker through snap
```
snap install docker
```
## 3/ Switch from administrator to user
```
exit
```
## 4/ Create a docker group called docker
```
sudo groupadd docker
```
## 5/ Add your user to the docker group
```
sudo usermod -aG docker n.radomski
```
## 6/ Activate the modifications of groups
```
newgrp docker
```
## 7/ Check the proper installation
```
docker run hello-world
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
install_version("data.table", version = "1.14.8", repos = "https://cloud.r-project.org")
install_version("dplyr", version = "1.1.1", repos = "https://cloud.r-project.org")
install_version("fastDummies", version = "1.6.3", repos = "https://cloud.r-project.org")
quit()
```
## 2/ Launch with Rscript
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
Rscript --max-ppsize=500000 AccurateGenomicElements.R -g GroupLabels-100-samples.tsv -m GenomicProfiles-100-samples.tsv -o test-100-samples-Rscript_
```
# Install Docker image and launch with Docker
## 1/ Pull Docker image from Docker Hub
```
docker pull nicolasradomski/accurategenomicelements:1.3
```
## 2/ Launch with Docker
### Call usage
```
docker run --name nicolas --rm -u `id -u`:`id -g` nicolasradomski/accurategenomicelements:1.3
```
### Call help
```
docker run --name nicolas --rm -u `id -u`:`id -g` nicolasradomski/accurategenomicelements:1.3 -h
```
### Command examples
```
docker run --name nicolas --rm -v $(pwd):/wk -w /wk --ulimit stack=100000000 -e R_MAX_VSIZE=25G nicolasradomski/accurategenomicelements:1.3 -g GroupLabels-100-samples.tsv -m GenomicProfiles-100-samples.tsv -o test-100-samples-dockerhub_
```
# Expected output
- summary.txt
- results.tsv
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
