FROM ubuntu:18.04
MAINTAINER Matt Godbolt <matt@godbolt.org>

ARG DEBIAN_FRONTEND=noninteractive

# Annoyingly crosstool whinges if it's run as root.
RUN mkdir -p /opt && mkdir -p /home/gcc-user && useradd gcc-user && chown gcc-user /opt /home/gcc-user

RUN apt-get clean -y && apt-get check -y

RUN apt-get update -y -q && apt-get upgrade -y -q && apt-get upgrade -y -q && \
    apt-get install -y -q \
    autoconf \
    automake \
    libtool \
    bison \
    bzip2 \
    curl \
    file \
    flex \
    git \
    gawk \
    binutils-multiarch \
    gperf \
    help2man \
    libc6-dev-i386 \
    libncurses5-dev \
    libtool-bin \
    linux-libc-dev \
    make \
    patch \
    rsync \
    s3cmd \
    sed \
    subversion \
    texinfo \
    wget \
    unzip \
    autopoint \
    gettext \
    vim \
    zlib1g-dev \
    software-properties-common \
    xz-utils && \
    cd /tmp && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws*

# Install GCC 11 from the Ubuntu test repository
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update && \
    apt-get install -y -q gcc-11 g++-11 gnat-11 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 60 --slave /usr/bin/g++ g++ /usr/bin/g++-11 && \
    update-alternatives --config gcc

WORKDIR /opt
COPY build/patches/cross-tool-ng/cross-tool-ng-1.22.0.patch ./
COPY build/patches/cross-tool-ng/cross-tool-ng-1.24.0.patch ./
RUN curl -sL http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.22.0.tar.xz | tar Jxf - && \
    mv crosstool-ng crosstool-ng-1.22.0 && \
    cd crosstool-ng-1.22.0 && \
    patch -p1 < ../cross-tool-ng-1.22.0.patch && \
    ./configure --enable-local && \
    make -j$(nproc)

RUN curl -sL http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.23.0.tar.xz | tar Jxf - && \
    cd crosstool-ng-1.23.0 && \
    ./configure --enable-local && \
    make -j$(nproc)

RUN TAG=db6f703f52e33a5791c5c2728fa1e3a330a08e98 && \
    curl -sL https://github.com/crosstool-ng/crosstool-ng/archive/${TAG}.zip --output crosstool-ng-master.zip  && \
    unzip crosstool-ng-master.zip && \
    cd crosstool-ng-${TAG} && \
    ./bootstrap && \
    ./configure --prefix=/opt/crosstool-ng-latest && \
    make -j$(nproc) && \
    make install

RUN curl -sL http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.24.0.tar.xz | tar Jxf - && \
    cd crosstool-ng-1.24.0 && \
    patch -p1 < ../cross-tool-ng-1.24.0.patch && \
    ./bootstrap && \
    ./configure --enable-local && \
    make -j$(nproc)

RUN mkdir -p /opt/.build/tarballs
COPY build /opt/
RUN chown -R gcc-user /opt
USER gcc-user
