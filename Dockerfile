FROM ubuntu:bionic

ARG eqemu_release_tag=latest
ENV EQEMU_RELEASE_TAG=$eqemu_release_tag

USER root

ENV EQEMU_HOME=/home/eqemu
ENV EQEMU_BUILD_DIR=/home/eqemu/build
ENV EQEMU_SRC_DIR=/home/eqemu/src

ENV DEBIAN_FRONTEND=noninteractive

# Install build prereqs
RUN apt-get update -y && \
    apt-get install -y wget software-properties-common apt-transport-https lsb-release && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
    apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" && \
    apt-get update -y && \
    apt-get install -y curl bash vim build-essential cmake cpp debconf-utils gcc-10 g++-10 libstdc++6 \
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
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100

# Set eqemu user
RUN groupadd eqemu && \
    useradd -g eqemu -d $EQEMU_HOME eqemu && \
    mkdir -p $EQEMU_HOME && \
    mkdir -p $EQEMU_BUILD_DIR

# Prep folders and clone source
RUN git clone https://github.com/EQEmu/Server.git $EQEMU_SRC_DIR
RUN if [ "$EQEMU_RELEASE_TAG" != "latest" ]; then cd $EQEMU_SRC_DIR; git fetch --all --tags --prune; git checkout tags/$EQEMU_RELEASE_TAG; fi;
RUN cd $EQEMU_SRC_DIR && \
    git submodule init && \
    git submodule update

# Compile eqemu
RUN cd $EQEMU_BUILD_DIR && \
    cmake $EQEMU_SRC_DIR && \
    make -j `grep -P '^core id\t' /proc/cpuinfo | sort -u | wc -l` LDFLAGS="-all-static" && \
    make install

# Move files into fresh container to ditch all the cruft:
FROM ubuntu:focal

USER root

ENV EQEMU_HOME=/home/eqemu
ENV EQEMU_BUILD_DIR=/home/eqemu/build
ENV EQEMU_SRC_DIR=/home/eqemu/src

ENV DEBIAN_FRONTEND=noninteractive

# Add Xenial/Bionic for older packages
RUN echo 'deb http://dk.archive.ubuntu.com/ubuntu/ xenial main' > /etc/apt/sources.list.d/xenial.list && \
    echo 'deb http://dk.archive.ubuntu.com/ubuntu/ xenial universe' >>  /etc/apt/sources.list.d/xenial.list && \
    echo 'deb http://dk.archive.ubuntu.com/ubuntu/ xenial-updates universe' >> /etc/apt/sources.list.d/xenial.list && \
    echo 'deb http://dk.archive.ubuntu.com/ubuntu/ bionic main' > /etc/apt/sources.list.d/bionic.list && \
    echo 'deb http://dk.archive.ubuntu.com/ubuntu/ bionic universe' >> /etc/apt/sources.list.d/bionic.list && \
    echo 'deb http://dk.archive.ubuntu.com/ubuntu/ bionic-updates universe' >> /etc/apt/sources.list.d/bionic.list

# Install minimal packages
RUN apt-get update -y && \
    apt-get install -y bash wget curl vim iputils-ping && \
    apt-get install -y software-properties-common apt-transport-https lsb-release && \
    apt-get install -y liblua5.1 debconf-utils mariadb-client perl perlbrew cpanminus patch unzip minizip \
                        libio-stringy-perl libjson-perl libperl-dev libperl5i-perl libmysqlclient20 libperl5.26 && \
    wget http://ftp.us.debian.org/debian/pool/main/libs/libsodium/libsodium-dev_1.0.11-2_amd64.deb -O /tmp/libsodium-dev.deb && \
    wget http://ftp.us.debian.org/debian/pool/main/libs/libsodium/libsodium18_1.0.11-2_amd64.deb -O /tmp/libsodium18.deb && \
    dpkg -i /tmp/libsodium*.deb && \
    rm -rf /tmp/* && \
    apt-get clean cache

# Set eqemu user
RUN groupadd eqemu && \
    useradd -g eqemu -d $EQEMU_HOME eqemu && \
    mkdir -p $EQEMU_HOME && \
    mkdir -p $EQEMU_BUILD_DIR

COPY --from=0 /usr/local /usr/local
COPY --from=0 /home/eqemu/src/loginserver/login_util/* /home/eqemu/
COPY --from=0 /home/eqemu/src/utils/defaults/log.ini /home/eqemu
COPY --from=0 /home/eqemu/src/utils/defaults/mime.types /home/eqemu
COPY --from=0 /home/eqemu/src/utils/patches/* /home/eqemu/
COPY --from=0 /home/eqemu/src/utils /home/eqemu/utils

RUN ln -s /usr/local/bin /home/eqemu/bin && \
    chown -R eqemu:eqemu /home/eqemu

WORKDIR /home/eqemu
USER eqemu

# One test fails in perl5i install, and google isn't being helpful. We'll see if it breaks anything? :D
# Downgraded Devel-Declare to avoid a bug in v0.006020+
RUN perlbrew init && \
    perlbrew -v install-patchperl && \
    perlbrew -v install 5.12.5 && \
    perlbrew switch perl-5.12.5 && \
    perlbrew -v install-cpanm
    
USER root

RUN mv /usr/bin/perl /usr/bin/perl-old && \
    ln -s /home/eqemu/perl5/perlbrew/perls/perl-5.12.5/bin/perl /usr/bin/perl

USER eqemu

RUN /home/eqemu/perl5/perlbrew/bin/cpanm IO::Stringy && \
    /home/eqemu/perl5/perlbrew/bin/cpanm JSON && \
    /home/eqemu/perl5/perlbrew/bin/cpanm ETHER/Devel-Declare-0.006019.tar.gz && \
    /home/eqemu/perl5/perlbrew/bin/cpanm -n perl5i

ENTRYPOINT /bin/bash
