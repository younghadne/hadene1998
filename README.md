# Mac Pro 6,1 (2013) Custom Kernel for Ubuntu

This repository contains scripts to build a custom Linux kernel optimized for the Mac Pro 6,1 (2013 "Trash Can") running Ubuntu.

## Hardware Support

This kernel is configured specifically for Mac Pro 6,1 hardware:

- **CPU**: Intel Xeon E5 v2 (Ivy Bridge-EP) - E5-1620, E5-1650, E5-2667, E5-2687W, E5-2697
- **GPU**: AMD FirePro D300, D500, D700 (Tahiti/Hawaii-based GPUs)
- **Chipset**: Intel C600/X79
- **Audio**: Cirrus Logic CS4208 (Mac audio)
- **WiFi**: Broadcom BCM4360
- **Ports**: Thunderbolt 2, USB 3.0
- **Storage**: SATA AHCI, NVMe support

## Quick Start

```bash
# 1. Install dependencies
chmod +x install-deps.sh
./install-deps.sh

# 2. Build the kernel
chmod +x build-macpro61-kernel.sh
./build-macpro61-kernel.sh

# 3. Install the kernel packages
cd ~/kernel-build
sudo dpkg -i linux-image-6.8*.deb
sudo dpkg -i linux-headers-6.8*.deb

# 4. Reboot
sudo reboot
```

## Kernel Features

### AMD GPU Support
- Full `amdgpu` driver support with CIK (Sea Islands) support enabled
- Legacy `radeon` driver as fallback
- HSA/ROCm compute support for GPU compute workloads

### CPU Optimizations
- NUMA support for Xeon processors
- Intel P-State driver for power management
- Preemptive kernel for better responsiveness
- 1000Hz timer for low-latency audio/pro audio work

### Mac-Specific Hardware
- Apple EFI/Properties support
- Apple SMC (System Management Controller) sensor support
- Thunderbolt 2 and USB4 networking
- Mac audio codec support (Cirrus Logic)
- Broadcom WiFi driver support

## Customization

To modify the kernel configuration before building:

```bash
cd ~/kernel-build/linux-6.8
make menuconfig  # Interactive configuration
# or
make xconfig     # GUI configuration (requires Qt)
```

Then continue the build process from step 5 in the build script.

## Troubleshooting

### GPU not detected
Check that the amdgpu driver is loaded:
```bash
lspci -k | grep -A 2 VGA
```

If using `radeon` instead of `amdgpu`, you may need to add kernel parameter:
```
amdgpu.cik_support=1 radeon.cik_support=0
```

### No WiFi
The BCM4360 requires proprietary firmware. Install:
```bash
sudo apt install bcmwl-kernel-source
```

Or use the open source b43 driver with firmware:
```bash
sudo apt install firmware-b43-installer
```

### Audio not working
Ensure the Cirrus Logic codec is detected:
```bash
cat /proc/asound/cards
```

## Build Options

The build script creates `.deb` packages that can be installed on any Ubuntu system. This is cleaner than manual installation and allows easy removal via `apt`.

## Kernel Version

Default kernel version is 6.8. Edit the `KERNEL_VERSION` variable in `build-macpro61-kernel.sh` to use a different version.

## References

- [Ubuntu Kernel Build Guide](https://wiki.ubuntu.com/KernelTeam/KernelTeamBugPolicies)
- [Mac Pro 6,1 Linux Guide](https://github.com/linux-on-mac/Mac-Pro-6-1)
- [AMDGPU Documentation](https://dri.freedesktop.org/wiki/AMDgpu/)

## License

The kernel build scripts are provided as-is. The Linux kernel is licensed under GPL v2.
