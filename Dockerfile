FROM ubuntu:18.04

USER root

ENV eqemu_server_directory=/home/eqemu
ENV EMUBUILDDIR=~/home/eqemu/build
ENV EMUSRCDIR=/home/eqemu/src

RUN apt-get update -y && \
    apt-get install -y software-properties-common apt-transport-https lsb-release && \
    add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe restricted     multiverse" && \
    apt-get update -y && \
    apt-get install -y curl bash build-essential cmake cpp debconf-utils g++ gcc \
                       git git-core libio-stringy-perl liblua5.1 liblua5.1-dev \
                       libluabind-dev libmysql++ libperl-dev libperl5i-perl \
                       libwtdbomysql-dev libmysqlclient-dev minizip lua5.1 \
                       make mariadb-client open-vm-tools unzip uuid-dev wget zlib-bin \
                       zlibc libsodium-dev libsodium18 libjson-perl libssl-dev
RUN wget http://ftp.us.debian.org/debian/pool/main/libs/libsodium/libsodium-dev_1.0.11-2_amd64.deb -O /tmp/libsodium-dev.deb && \
    wget http://ftp.us.debian.org/debian/pool/main/libs/libsodium/libsodium18_1.0.11-2_amd64.deb -O /tmp/libsodium18.deb && \
    dpkg -i /tmp/libsodium*.deb && \
    rm -f /tmp/libsodium*.deb

RUN groupadd eqemu && \
    useradd -g eqemu -d $eqemu_server_directory eqemu && \
    mkdir -p $eqemu_server_directory

RUN mkdir -p $eqemu_server_directory/src && \
    mkdir -p $eqemu_server_directory/build && \
    mkdir -p $eqemu_server_directory/server && \
    mkdir -p $eqemu_server_directory/server/export && \
    mkdir -p $eqemu_server_directory/server/logs && \
    mkdir -p $eqemu_server_directory/server/shared && \
    mkdir -p $eqemu_server_directory/server/maps && \
    ln -s $eqemu_server_directory/maps $eqemu_server_directory/Maps && \
    git clone https://github.com/EQEmu/Server.git $EMUSRCDIR && \
    cd $EMUBUILDDIR && \
    cmake $EMUSRCDIR && \
    make && \
    chown eqemu:eqemu $eqemu_server_directory/ -R && \
    chmod 755 $eqemu_server_directory/server/*.pl && \
    chmod 755 $eqemu_server_directory/server/*.sh 

ENTRYPOINT /bin/bash
