#!/bin/bash


mkdir kernel && cd kernel

echo $PWD

wget https://github.com/oras-project/oras/releases/download/v1.3.1/oras_1.3.1_linux_arm64.tar.gz
tar -xzvf oras_1.3.1_linux_arm64.tar.gz
chmod +x ./oras

# ghcr.io=ghcr.nju.edu.cn、ghcr.m.daocloud.io、mirror.ghcr.io
KERNELTAG=$(./oras repo tags ghcr.io/armbian/os/kernel-rockchip64-edge | grep "7.0" | tail -n 1)
./oras pull ghcr.io/armbian/os/kernel-rockchip64-edge:$KERNELTAG

tar -xf kernel-rockchip64-edge_*.tar

cp global/linux-image-edge-rockchip64_*.deb .
cp global/linux-headers-edge-rockchip64_*.deb .
cp global/linux-libc-dev-edge-rockchip64_*.deb .