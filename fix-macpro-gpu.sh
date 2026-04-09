#!/bin/bash
# Fix GPU driver for Mac Pro 6.1 (FirePro D300/D500/D700)
# Run this AFTER installing the custom kernel

echo "=== Mac Pro 6.1 GPU Fix ==="
echo ""

# 1. Check current GPU status
echo "Current GPU status:"
lspci -k | grep -EA3 'VGA|3D|Display'
echo ""

# 2. Create modprobe config to enable amdgpu for FirePro
echo "Configuring AMDGPU driver for FirePro D300/D500/D700..."
sudo tee /etc/modprobe.d/amdgpu-macpro.conf << 'EOF'
# Enable CIK (Sea Islands) support for AMDGPU
# Required for FirePro D300/D500/D700 in Mac Pro 6,1
options amdgpu cik_support=1
options amdgpu si_support=1

# Disable Radeon driver for CIK GPUs
options radeon cik_support=0
options radeon si_support=0
EOF

# 3. Blacklist radeon if it's loading
echo "Blacklisting legacy radeon driver..."
sudo tee /etc/modprobe.d/blacklist-radeon.conf << 'EOF'
# Blacklist radeon - use amdgpu instead
blacklist radeon
EOF

# 4. Update initramfs
echo "Updating initramfs..."
sudo update-initramfs -u

# 5. Check for missing firmware
echo ""
echo "Checking for firmware..."
if [ -d /lib/firmware/amdgpu ]; then
    echo "AMDGPU firmware directory exists"
    ls /lib/firmware/amdgpu/ | grep -E 'tahiti|hawaii|pitcairn' | head -5
else
    echo "WARNING: AMDGPU firmware not found! Install:"
    echo "  sudo apt install linux-firmware"
fi

# 6. Add kernel parameter if needed
GRUB_CMD="amdgpu.cik_support=1 radeon.cik_support=0"
echo ""
echo "Adding kernel parameters to GRUB..."
if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub; then
    # Check if already added
    if ! grep -q "amdgpu.cik_support" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="amdgpu.cik_support=1 radeon.cik_support=0 /' /etc/default/grub
        echo "Updated GRUB config"
        sudo update-grub
    else
        echo "Kernel parameters already set"
    fi
fi

echo ""
echo "=== Fix Applied ==="
echo "Reboot now: sudo reboot"
echo ""
echo "After reboot, verify with:"
echo "  lspci -k | grep -A3 VGA"
echo "  glxinfo | grep renderer"
echo ""
echo "If still not working, check dmesg:"
echo "  dmesg | grep -i amdgpu"
