# Kali-Droidian Build System (Enhanced with Auto-Theming)

A comprehensive build system that creates a Kali Linux-based mobile operating system running on Droidian (Debian for Android devices) with **automatic asset downloading** and **NetHunter Pro theming**.

## Features

### 🚀 **Automatic Asset Retrieval**
- **Automatically downloads** all Kali Linux branding assets (logos, wallpapers, themes)
- **Fetches NetHunter Pro theme** components from official sources
- **Retrieves GTK themes**, icon sets, and fonts
- **Downloads Plymouth boot splash** themes
- **Gets GRUB themes** for proper boot experience

### 🎨 **Complete Theming Integration**
- **NetHunter Pro Phosh theme** with dark UI optimized for mobile
- **Kali Linux branding** throughout the system
- **Custom boot splash** with Kali logo
- **Themed lock screen** and wallpapers
- **Consistent icon theme** across applications

### 📱 **Mobile-Optimized**
- **Phosh desktop environment** designed for touch interfaces
- **Mobile-friendly applications** (Calls, Chatty, Contacts)
- **Touch keyboard support** with Squeekboard
- **Network management** with ModemManager and ofono
- **Bluetooth and WiFi** support

### 🛠 **Penetration Testing Tools**
- **Essential Kali tools** pre-installed
- **Aircrack-ng, Nmap, Wireshark** and more
- **Metasploit Framework** for advanced testing
- **Mobile-specific security tools**

## Quick Start

### Prerequisites

Install required dependencies on Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y \
  debootstrap qemu-user-static binfmt-support \
  wget curl git rsync squashfs-tools \
  genisoimage syslinux-utils parted kpartx
```

### Basic Build

```bash
# Clone the repository
git clone <repository-url>
cd kali-droidian-build

# Make scripts executable
chmod +x build.sh scripts/*.sh

# Build for generic device
./build.sh
```

### Device-Specific Build

```bash
# Build for specific device (e.g., OnePlus 6)
DEVICE_CODENAME=oneplus6 ./build.sh

# Build minimal version (fewer tools)
BUILD_TYPE=minimal ./build.sh

# Build for different architecture
ARCH=armhf ./build.sh
```

## Build Options

| Environment Variable | Description | Default | Options |
|---------------------|-------------|---------|---------|
| `DEVICE_CODENAME` | Target device codename | `generic` | `oneplus6`, `pixel3a`, etc. |
| `ARCH` | Target architecture | `arm64` | `arm64`, `armhf` |
| `BUILD_TYPE` | Build complexity | `full` | `full`, `minimal` |
| `KALI_SUITE` | Kali Linux version | `kali-rolling` | `kali-rolling` |

## Asset Management

### Automatic Downloads

The build system automatically downloads:

- **Kali Linux Assets**
  - Official Kali logo (PNG format)
  - Kali wallpapers (multiple variants)
  - Kali icon themes
  - GTK themes from official repository

- **NetHunter Components**
  - NetHunter Pro theme elements
  - Mobile-optimized UI components
  - Custom Phosh configurations

- **System Themes**
  - Plymouth boot splash themes
  - GRUB boot themes
  - Font collections (Roboto, Source Code Pro)

### Manual Asset Override

To use custom assets, place them in the `assets/` directory before building:

```
assets/
├── kali-logo.png           # Custom Kali logo
├── kali-wallpaper.jpg      # Main wallpaper
├── wallpapers/             # Additional wallpapers
├── icons/                  # Icon themes
├── gtk-themes/             # GTK themes
├── fonts/                  # Custom fonts
└── nethunter-pro/          # NetHunter theme assets
```

### Asset Verification

Check downloaded assets:

```bash
# Download assets only
./build.sh --assets-only

# Verify asset integrity
find assets/ -name "*.png" -o -name "*.jpg" | xargs file
```

## Build Commands

| Command | Description |
|---------|-------------|
| `./build.sh` | Full build process |
| `./build.sh --help` | Show help and options |
| `./build.sh --clean` | Clean build directory |
| `./build.sh --assets-only` | Download assets only |

## Repository Management

### Kali Linux Repository

The build system automatically:
- Adds Kali Linux GPG keys
- Configures package repositories
- Sets up package pinning to avoid conflicts
- Installs essential Kali packages

### Package Priorities

| Package Type | Priority | Description |
|--------------|----------|-------------|
| Debian/Droidian base | 500 | Standard priority |
| Kali tools | 600 | High priority for essential tools |
| Kali themes | 500 | Normal priority for theming |
| Other Kali packages | 100 | Low priority to avoid conflicts |

## Theming Details

### NetHunter Pro Theme

The NetHunter Pro theme includes:

- **Dark UI optimized for mobile devices**
- **Orange accent colors** (`#ff6b35`) matching Kali branding
- **Touch-friendly button sizes**
- **High contrast text** for outdoor visibility
- **Consistent iconography** across applications

### Theme Components

1. **GTK3/GTK4 Theme**
   - Dark background with orange accents
   - Mobile-optimized widget sizes
   - Touch-friendly controls

2. **Icon Theme**
   - Consistent with Kali Linux branding
   - Mobile-sized icons (16px to 256px)
   - Security tool specific icons

3. **Wallpapers**
   - Multiple Kali-themed wallpapers
   - Mobile-optimized resolutions
   - Lock screen variants

4. **Fonts**
   - Roboto for UI text
   - Source Code Pro for terminal
   - Optimized for small screens

## Troubleshooting

### Common Issues

**Asset Download Failures**
```bash
# Check internet connection
ping -c 4 archive.kali.org

# Manual asset download
scripts/download_assets.sh assets/

# Verify downloads
ls -la assets/
```

**Build Failures**
```bash
# Check available disk space (needs ~8GB)
df -h

# Clean previous builds
./build.sh --clean

# Check dependencies
dpkg -l | grep -E "(debootstrap|qemu-user-static)"
```

**Repository Issues**
```bash
# Update package lists
sudo apt-get update

# Add Kali GPG key manually
wget -q -O - https://archive.kali.org/archive-key.asc | sudo apt-key add -
```

### Log Analysis

Build logs are created in `build/logs/`:
- `build.log` - Main build log
- `download.log` - Asset download log
- `chroot.log` - Package installation log

### Missing Assets

If some assets fail to download:
1. Check the `assets/` directory for missing files
2. Download manually from official sources
3. Place in appropriate subdirectories
4. Re-run the build

## Advanced Configuration

### Custom Repositories

Add custom repositories in `scripts/setup_repositories.sh`:

```bash
# Add custom repository
echo "deb https://example.com/repo stable main" > /etc/apt/sources.list.d/custom.list
```

### Theme Customization

Modify theme settings in `scripts/install_nethunter_theme.sh`:

```bash
# Change accent color
sed -i 's/#ff6b35/#your-color/g' gtk.css
```

### Tool Selection

Customize installed tools in `build.sh`:

```bash
# Add your tools to the installation list
apt-get install -y your-custom-tool
```

## Output

The build process creates:

- **Compressed system image**: `kali-droidian-{device}-{date}.img.gz`
- **Build logs** in `build/logs/`
- **Asset cache** in `assets/`

## Installation

Flash the resulting image to your Android device using:

- **Fastboot**: `fastboot flash system kali-droidian-*.img`
- **Recovery tools**: TWRP, CWM
- **dd command**: For direct block device writing

## Security Notes

- Default credentials: `kali:kali` and `root:root`
- Change passwords after first boot
- SSH is disabled by default
- Firewall rules may need configuration

## Contributing

1. Fork the repository
2. Create feature branch
3. Add your improvements
4. Test thoroughly
5. Submit pull request

## License

This project builds upon:
- **Debian** (GPL/LGPL)
- **Kali Linux** (GPL)
- **Droidian** (GPL)

Individual components retain their original licenses.

## Support

- **Issues**: Use GitHub issues for bug reports
- **Documentation**: Check the wiki for detailed guides
- **Community**: Join the Droidian/Kali communities

---

**Note**: This is an unofficial build system. Always verify downloads and builds from trusted sources.