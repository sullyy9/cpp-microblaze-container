FROM archlinux:latest

RUN pacman-key --init
RUN pacman --noconfirm -Sy
RUN pacman --noconfirm -S archlinux-keyring 

# Install basic programs and custom glibc
RUN pacman --noconfirm -Syu && \
    pacman --noconfirm -S \
    git \
    gcc \
    wget \
    make \
    cmake \
    unzip \
    sudo \
    flex \
    bison \
    gperf \
    patch \
    libtool \
    diffutils \
    automake \
    gmp \
    libmpc \
    mpfr \
    base-devel \
    meson \
    openocd \
    usbutils && \
    pacman --noconfirm -Scc

RUN wget https://muon.build/releases/edge/muon-edge-amd64-linux-static -O /usr/bin/muon && \
    chmod 775 /usr/bin/muon

# Install clangd
ENV CLANGD_URL=https://github.com/clangd/clangd/releases/download/16.0.2/clangd-linux-16.0.2.zip
RUN wget $CLANGD_URL -O ~/clangd.zip && \
    unzip ~/clangd.zip -d ~/clangd && \
    cp ~/clangd/*/bin/clangd /usr/local/bin/ && \ 
    cp -r ~/clangd/*/lib/* /usr/local/lib/ && \
    rm ~/clangd.zip && rm -R ~/clangd

COPY 60-openocd.rules /etc/udev/rules.d/

# Setup default user
ENV USER=dev
RUN useradd --create-home -s /bin/bash -m $USER && \
    echo "$USER:archlinux" | chpasswd && \
    usermod -aG wheel $USER && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/$USER
USER $USER

RUN cd ~ && \
    git clone https://github.com/bminor/binutils-gdb.git && \
    git clone --branch releases/gcc-13.1.0 --single-branch https://github.com/gcc-mirror/gcc.git && \
    cd ~/gcc && \
    ./contrib/download_prerequisites && \
    cd ~ && \
    mkdir ~/build-binutils && \
    mkdir ~/build-gcc && \
    export PREFIX="/usr/local" && \
    export TARGET=microblaze-xilinx-elf && \
    export PATH="$PREFIX/bin:$PATH" && \
    cd ~/build-binutils && \
    ../binutils-gdb/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror && \
    make -j4 && \
    sudo make install && \
    cd ~/build-gcc && \
    ../gcc/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers && \
    make -j4 all-gcc && \
    make -j4 all-target-libgcc && \
    sudo make install-gcc && \
    sudo make install-target-libgcc && \
    sudo rm -r ~/*
