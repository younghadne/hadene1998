#!/bin/bash
# Install all dependencies for Mac Pro 6.1 kernel build on Ubuntu

set -e

echo "Installing dependencies for Mac Pro 6.1 kernel build..."

# Update package list
sudo apt update

# Install build-essential and basic tools
sudo apt install -y build-essential git fakeroot bc liblz4-tool

# Install kernel build dependencies
sudo apt install -y \
    libncurses-dev \
    gawk \
    flex \
    bison \
    openssl \
    libssl-dev \
    dkms \
    libelf-dev \
    libudev-dev \
    libpci-dev \
    libiberty-dev \
    autoconf \
    llvm \
    lld \
    clang \
    kernel-wedge \
    makedumpfile \
    libncurses5-dev \
    libncursesw5-dev \
    dwarves \
    zstd

# Install additional tools
sudo apt install -y wget curl xz-utils

# Enable source repositories for build-dep
echo ""
echo "Note: If 'apt build-dep' fails, ensure deb-src lines are in /etc/apt/sources.list"
echo "Add these lines if missing:"
echo "  deb-src http://archive.ubuntu.com/ubuntu \$(lsb_release -cs) main"
echo "  deb-src http://archive.ubuntu.com/ubuntu \$(lsb_release -cs)-updates main"
echo ""

# Try to install build-deps for current kernel
sudo apt build-dep -y linux-image-unsigned-$(uname -r) 2>/dev/null || {
    echo "Warning: Could not install build dependencies from current kernel"
    echo "Dependencies listed above should be sufficient"
}

echo ""
echo "Dependencies installed successfully!"
echo "Run ./build-macpro61-kernel.sh to build the kernel"
