FROM clearlinux:latest AS builder

# Install a minimal versioned OS into /install_root, and bundled tools if any
ENV CLEAR_VERSION=33980
RUN swupd os-install --no-progress --no-boot-update --no-scripts \
    --version ${CLEAR_VERSION} \
    --path /install_root \
    --statedir /swupd-state \
    --bundles os-core-update,which

# Download and install conda into /usr/bin
ENV MINICONDA_VERSION=py37_4.9.2
RUN swupd bundle-add --no-progress curl && \
    curl -sL https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    sh /tmp/miniconda.sh -bfp /usr

# Use conda to install remaining tools/dependencies into /usr/local
ENV VEP_VERSION=102.0 \
    HTSLIB_VERSION=1.10.2 \
    BCFTOOLS_VERSION=1.10.2 \
    SAMTOOLS_VERSION=1.10 \
    LIFTOVER_VERSION=377
RUN conda create -qy -p /usr/local \
    -c conda-forge \
    -c bioconda \
    -c defaults \
    ensembl-vep==${VEP_VERSION} \
    htslib==${HTSLIB_VERSION} \
    bcftools==${BCFTOOLS_VERSION} \
    samtools==${SAMTOOLS_VERSION} \
    ucsc-liftover==${LIFTOVER_VERSION}

# Deploy the minimal OS and tools into a clean target layer
FROM scratch

LABEL maintainer="Cyriac Kandoth <ckandoth@gmail.com>"

COPY --from=builder /install_root /
COPY --from=builder /usr/local /usr/local
COPY data /opt/data
COPY *.pl /opt/
WORKDIR /opt/


RUN curl -ksSL -o tmp.tar.gz https://github.com/mskcc/vcf2maf/archive/refs/tags/v1.6.21.tar.gz && \
    tar --strip-components 1 -zxf tmp.tar.gz && \
    rm tmp.tar.gz && \
    chmod +x *.pl
    
    FROM ubuntu:20.04
MAINTAINER mongenae@its.jnj.com

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London

WORKDIR /home

RUN apt-get update && \
    apt-get upgrade -y 

RUN apt-get install -y --fix-missing zlibc zlib1g zlib1g-dev make gcc g++ wget libncurses5-dev libncursesw5-dev libbz2-dev liblzma-dev git libsafec-dev libsafec-3.5-3 curl ca-certificates

RUN apt-get update

# Compile from source
#RUN git clone https://github.com/arun-sub/bwa-mem2.git ert
#WORKDIR /home/ert

#RUN make -j2 arch=avx2

#ENV PATH /home/ert:${PATH}

RUN curl --insecure -L https://github.com/bwa-mem2/bwa-mem2/releases/download/v2.2.1/bwa-mem2-2.2.1_x64-linux.tar.bz2 --output /home/bwa-mem2-2.2.1_x64-linux.tar.bz2
RUN tar -xvjf /home/bwa-mem2-2.2.1_x64-linux.tar.bz2

ENV PATH /home/bwa-mem2-2.2.1_x64-linux:${PATH}
ENV LD_LIBRARY_PATH "/usr/local/lib:${LD_LIBRARY_PATH}"
RUN echo "export PATH=$PATH" > /etc/environment
RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" > /etc/environment

RUN curl --insecure -L curl http://ftp.ensembl.org/pub/release-104/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz --output /opt/

