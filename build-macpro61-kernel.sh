#!/bin/bash
# Mac Pro 6,1 (2013) Custom Kernel Build Script for Ubuntu
# Supports: AMD FirePro D300/D500/D700, Xeon E5 v2, Thunderbolt, Mac audio

set -e

# Configuration
KERNEL_VERSION="6.8"  # Update this to match latest Ubuntu kernel
LOCAL_VERSION="+macpro61"
BUILD_DIR="$HOME/kernel-build"
JOBS=$(nproc)

echo "=== Mac Pro 6,1 Kernel Build Script ==="
echo "Target: Ubuntu with Mac Pro 6,1 hardware support"
echo ""

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo "WARNING: This script is designed for Ubuntu"
fi

# Step 1: Install build dependencies
echo "[1/7] Installing build dependencies..."
sudo apt update
sudo apt install -y build-dep linux linux-image-unsigned-$(uname -r) 2>/dev/null || true
sudo apt install -y \
    libncurses-dev gawk flex bison openssl libssl-dev dkms \
    libelf-dev libudev-dev libpci-dev libiberty-dev autoconf llvm \
    git fakeroot bc liblz4-tool kernel-wedge makedumpfile \
    libncurses5-dev libncursesw5-dev dwarves

# Step 2: Get kernel source
echo "[2/7] Downloading kernel source..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Download latest Ubuntu kernel source
if [ ! -d "linux-${KERNEL_VERSION}" ]; then
    wget "https://git.kernel.org/torvalds/t/linux-${KERNEL_VERSION}.tar.gz" -O "linux-${KERNEL_VERSION}.tar.gz" || \
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" -O "linux-${KERNEL_VERSION}.tar.xz"
    
    if [ -f "linux-${KERNEL_VERSION}.tar.gz" ]; then
        tar -xzf "linux-${KERNEL_VERSION}.tar.gz"
    else
        tar -xf "linux-${KERNEL_VERSION}.tar.xz"
    fi
fi

cd "linux-${KERNEL_VERSION}"

# Step 3: Apply Mac Pro 6,1 specific configurations
echo "[3/7] Applying Mac Pro 6,1 kernel configuration..."

# Start with Ubuntu's default config if available, or x86_64_defconfig
if [ -f "/boot/config-$(uname -r)" ]; then
    cp "/boot/config-$(uname -r)" .config
else
    make x86_64_defconfig
fi

# Apply Mac Pro 6,1 specific config options
./scripts/config --set-str CONFIG_LOCALVERSION "${LOCAL_VERSION}"

# Enable AMD GPU support (FirePro D300/D500/D700 - Tahiti/Hawaii)
./scripts/config --enable CONFIG_DRM_AMDGPU
./scripts/config --enable CONFIG_DRM_AMDGPU_CIK  # For older AMD GPUs
./scripts/config --enable CONFIG_DRM_RADEON
./scripts/config --enable CONFIG_DRM_RADEON_CIK
./scripts/config --enable CONFIG_HSA_AMD

# Intel Xeon E5 v2 (Ivy Bridge-EP) support
./scripts/config --enable CONFIG_X86_INTEL_MPIC
./scripts/config --enable CONFIG_SMP
./scripts/config --enable CONFIG_X86_64
./scripts/config --enable CONFIG_NUMA
./scripts/config --enable CONFIG_X86_INTEL_PSTATE

# Mac Pro specific hardware
./scripts/config --enable CONFIG_APPLE_PROPERTIES
./scripts/config --enable CONFIG_EFI  
./scripts/config --enable CONFIG_EFI_STUB
./scripts/config --enable CONFIG_EFI_MIXED
./scripts/config --enable CONFIG_EFI_VARS

# Thunderbolt 2 support
./scripts/config --enable CONFIG_THUNDERBOLT
./scripts/config --enable CONFIG_USB4
./scripts/config --enable CONFIG_THUNDERBOLT_NET

# USB and PCIe
./scripts/config --enable CONFIG_USB_XHCI_HCD
./scripts/config --enable CONFIG_PCI
./scripts/config --enable CONFIG_HOTPLUG_PCI
./scripts/config --enable CONFIG_PCIEPORTBUS

# Mac audio (Cirrus Logic CS4208)
./scripts/config --enable CONFIG_SND_HDA_CODEC_CS4208
./scripts/config --enable CONFIG_SND_HDA_CODEC_CS4210
./scripts/config --enable CONFIG_SND_HDA_CODEC_CS4213
./scripts/config --enable CONFIG_SND_HDA_INTEL
./scripts/config --enable CONFIG_SND_USB_AUDIO

# Broadcom WiFi (BCM4360)
./scripts/config --enable CONFIG_B43
./scripts/config --enable CONFIG_B43_SDIO
./scripts/config --enable CONFIG_B43LEGACY
./scripts/config --enable CONFIG_BRCMFMAC
./scripts/config --enable CONFIG_BRCMFMAC_USB
./scripts/config --enable CONFIG_BRCMFMAC_PCIE
./scripts/config --enable CONFIG_BRCMUTIL
./scripts/config --module CONFIG_WL  # Broadcom proprietary driver as module

# Bluetooth
./scripts/config --enable CONFIG_BT_BCM
./scripts/config --enable CONFIG_BT_RTL

# Storage - C600/X79 chipset
./scripts/config --enable CONFIG_SATA_AHCI
./scripts/config --enable CONFIG_SATA_AHCI_PLATFORM
./scripts/config --enable CONFIG_MD_RAID456
./scripts/config --enable CONFIG_BLK_DEV_NVME
./scripts/config --enable CONFIG_NVME_FABRICS
./scripts/config --enable CONFIG_NVME_FC
./scripts/config --enable CONFIG_NVME_TCP

# Mac SMC (System Management Controller)
./scripts/config --enable CONFIG_SENSORS_APPLESMC

# Power management
./scripts/config --enable CONFIG_CPU_FREQ
./scripts/config --enable CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL
./scripts/config --enable CONFIG_CPU_FREQ_GOV_PERFORMANCE
./scripts/config --enable CONFIG_CPU_FREQ_GOV_POWERSAVE
./scripts/config --enable CONFIG_CPU_FREQ_GOV_USERSPACE
./scripts/config --enable CONFIG_CPU_FREQ_GOV_ONDEMAND
./scripts/config --enable CONFIG_CPU_FREQ_GOV_CONSERVATIVE
./scripts/config --enable CONFIG_CPU_FREQ_GOV_SCHEDUTIL
./scripts/config --enable CONFIG_INTEL_IDLE

# Performance optimizations for workstation
./scripts/config --enable CONFIG_PREEMPT
./scripts/config --enable CONFIG_HZ_1000
./scripts/config --set-val CONFIG_HZ 1000
./scripts/config --enable CONFIG_SCHED_OMIT_FRAME_POINTER

# Update config
make olddefconfig

# Step 4: Modify changelog to add local version
echo "[4/7] Updating changelog..."
if [ -f "debian.master/changelog" ]; then
    # Ubuntu-style kernel
    sed -i "1s/.*/linux (${KERNEL_VERSION}-1.0${LOCAL_VERSION}) unstable; urgency=medium/" debian.master/changelog
else
    # Create simple version marker
    echo "${KERNEL_VERSION}${LOCAL_VERSION}" > .kernel_version
fi

# Step 5: Build the kernel
echo "[5/7] Building kernel (this will take a while)..."
echo "Using ${JOBS} parallel jobs"
make clean
make -j"${JOBS}"

# Step 6: Build kernel modules
echo "[6/7] Building kernel modules..."
make -j"${JOBS}" modules

# Step 7: Create deb packages
echo "[7/7] Creating kernel packages..."
make -j"${JOBS}" bindeb-pkg

echo ""
echo "=== Build Complete! ==="
echo "Kernel packages are in: ${BUILD_DIR}"
echo ""
echo "To install:"
echo "  cd ${BUILD_DIR}"
echo "  sudo dpkg -i linux-image-${KERNEL_VERSION}*.deb"
echo "  sudo dpkg -i linux-headers-${KERNEL_VERSION}*.deb"
echo "  sudo reboot"
echo ""
echo "Note: This kernel is optimized for Mac Pro 6,1 with:"
echo "  - AMD FirePro D300/D500/D700 GPU support"
echo "  - Intel Xeon E5 v2 (Ivy Bridge-EP) optimizations"
echo "  - Thunderbolt 2 support"
echo "  - Mac audio (Cirrus Logic) support"
echo "  - Broadcom WiFi (BCM4360) support"
