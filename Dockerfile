FROM ubuntu:bionic

USER root

ENV EQEMU_HOME=/home/eqemu
ENV EQEMU_BUILD_DIR=/home/eqemu/build
ENV EQEMU_SRC_DIR=/home/eqemu/src

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
    rm -rf /tmp/*

# Set eqemu user
RUN groupadd eqemu && \
    useradd -g eqemu -d $EQEMU_HOME eqemu && \
    mkdir -p $EQEMU_HOME && \
    mkdir -p $EQEMU_BUILD_DIR

# Prep folders and clone source
RUN git clone https://github.com/EQEmu/Server.git $EQEMU_SRC_DIR && \
    cd $EQEMU_SRC_DIR && \
    git submodule init && \
    git submodule update

# Compile eqemu
RUN cd $EQEMU_BUILD_DIR && \
    cmake $EQEMU_SRC_DIR && \
    make -j `grep -P '^core id\t' /proc/cpuinfo | sort -u | wc -l` LDFLAGS="-all-static" && \
    make install && \
    rm -rf $EQEMU_HOME/*

# Cleanup the image (TODO: separate build and run containers)
RUN apt-get remove -y libwtdbomysql-dev && \
    apt-add-repository --remove http://ftp.de.debian.org/debian && \
    apt-get autoremove --purge -y && \
    apt-get remove -y libssl-dev && \
    apt-get autoremove --purge -y && \
    apt-get update -y && \
    apt-get remove -y git git-core libio-stringy-perl liblua5.1 liblua5.1-dev libluabind-dev libmysql++ libperl-dev libperl5i-perl lua5.1 make mariadb-client open-vm-tools uuid-dev zlibc libjson-perl && \
    apt-get autoremove --purge -y && \
    apt-get clean cache

USER eqemu 

ENTRYPOINT /bin/bash