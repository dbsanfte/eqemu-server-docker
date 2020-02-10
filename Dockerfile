FROM ubuntu:bionic

USER root

ENV eqemu_server_directory=/home/eqemu
ENV EMUBUILDDIR=/home/eqemu/build
ENV EMUSRCDIR=/home/eqemu/src

ENV DEBIAN_FRONTEND=noninteractive

# Install build prereqs
RUN apt-get update -y && \
    apt-get install -y wget software-properties-common apt-transport-https lsb-release && \
    apt-get install -y curl bash build-essential cmake cpp debconf-utils g++ gcc \
                       git git-core libio-stringy-perl liblua5.1 liblua5.1-dev \
                       libluabind-dev libmysql++ libperl-dev libperl5i-perl \
                       libmysqlclient-dev minizip lua5.1 \
                       make mariadb-client open-vm-tools unzip uuid-dev minizip \
                       zlibc libjson-perl libssl-dev && \
    wget -qO - https://ftp-master.debian.org/keys/archive-key-9.asc | apt-key add - && \
    add-apt-repository "deb http://ftp.de.debian.org/debian stretch main" && \
    apt-get update -y && \
    apt-get install -y libwtdbomysql-dev && \
    wget http://ftp.us.debian.org/debian/pool/main/libs/libsodium/libsodium-dev_1.0.11-2_amd64.deb -O /tmp/libsodium-dev.deb && \
    wget http://ftp.us.debian.org/debian/pool/main/libs/libsodium/libsodium18_1.0.11-2_amd64.deb -O /tmp/libsodium18.deb && \
    dpkg -i /tmp/libsodium*.deb && \
    rm -rf /tmp/* && \
    apt-get clean cache

# Set eqemu user
RUN groupadd eqemu && \
    useradd -g eqemu -d $eqemu_server_directory eqemu && \
    mkdir -p $eqemu_server_directory

# Prep folders and clone source
RUN mkdir -p $eqemu_server_directory/src && \
    mkdir -p $eqemu_server_directory/build && \
    mkdir -p $eqemu_server_directory/server && \
    mkdir -p $eqemu_server_directory/server/export && \
    mkdir -p $eqemu_server_directory/server/logs && \
    mkdir -p $eqemu_server_directory/server/shared && \
    mkdir -p $eqemu_server_directory/server/maps && \
    ln -s $eqemu_server_directory/maps $eqemu_server_directory/Maps && \
    git clone https://github.com/EQEmu/Server.git $EMUSRCDIR && \
    cd $EMUSRCDIR && \
    git submodule init && \
    git submodule update

# Compile eqemu
RUN cd $EMUBUILDDIR && \
    cmake $EMUSRCDIR && \
    make -j `grep -P '^core id\t' /proc/cpuinfo | sort -u | wc -l` LDFLAGS="-all-static" && \
    chown eqemu:eqemu $eqemu_server_directory -R

USER eqemu 

ENTRYPOINT /bin/bash
