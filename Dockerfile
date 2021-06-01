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
