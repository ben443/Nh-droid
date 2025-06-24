#!/bin/bash

set -e

# Kali-Droidian Build Script
# Enhanced version with automatic asset downloading

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
ASSETS_DIR="${PROJECT_ROOT}/assets"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
ROOTFS_DIR="${BUILD_DIR}/rootfs"

# Configuration
DEVICE_CODENAME="${DEVICE_CODENAME:-generic}"
KALI_SUITE="${KALI_SUITE:-kali-rolling}"
ARCH="${ARCH:-arm64}"
BUILD_TYPE="${BUILD_TYPE:-full}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
  log_info "Checking build dependencies..."
  
  local deps=(
    "debootstrap"
    "qemu-user-static"
    "binfmt-support"
    "wget"
    "curl"
    "git"
    "rsync"
    "squashfs-tools"
    "genisoimage"
    "syslinux-utils"
    "parted"
    "kpartx"
  )
  
  local missing_deps=()

  log_success "All dependencies are installed"
}

# Download all required assets automatically
download_assets() {
  log_info "Downloading Kali assets and themes..."
  
  if [ ! -x "$SCRIPTS_DIR/download_assets.sh" ]; then
    log_error "Download assets script not found or not executable"
    exit 1
  fi
  
  "$SCRIPTS_DIR/download_assets.sh" "$ASSETS_DIR"
  
  log_success "Asset download completed"
}

# Verify assets
verify_assets() {
  log_info "Verifying downloaded assets..."
  
  local required_assets=(
    "$ASSETS_DIR/kali-logo.png"
    "$ASSETS_DIR/kali-wallpaper.jpg"
  )
  
  local missing_assets=()
  
  for asset in "${required_assets[@]}"; do
    if [ ! -f "$asset" ] || [ ! -s "$asset" ]; then
      missing_assets+=("$asset")
    fi
  done
  
  if [ ${#missing_assets[@]} -gt 0 ]; then
    log_warning "Some assets are missing or empty:"
    printf '%s\n' "${missing_assets[@]}"
    log_warning "Build will continue but theming may be incomplete"
  else
    log_success "All essential assets verified"
  fi
}

# Create base rootfs
create_base_rootfs() {
  log_info "Creating base rootfs..."
  
  # Clean previous build
  if [ -d "$ROOTFS_DIR" ]; then
    log_info "Cleaning previous build..."
    sudo rm -rf "$ROOTFS_DIR"
  fi
  
  mkdir -p "$ROOTFS_DIR"
  
  # Create base Debian system
  sudo debootstrap \
    --arch="$ARCH" \
    --variant=minbase \
    --include=systemd,dbus,network-manager,wget,curl,gnupg2,ca-certificates \
    bullseye \
    "$ROOTFS_DIR" \
    http://deb.debian.org/debian/
  
  log_success "Base rootfs created"
}

# Setup chroot environment
setup_chroot() {
  log_info "Setting up chroot environment..."
  
  # Copy qemu static
  sudo cp /usr/bin/qemu-aarch64-static "$ROOTFS_DIR/usr/bin/" 2>/dev/null || \
  sudo cp /usr/bin/qemu-arm-static "$ROOTFS_DIR/usr/bin/" 2>/dev/null || true
  
  # Mount necessary filesystems
  sudo mount -t proc proc "$ROOTFS_DIR/proc"
  sudo mount -t sysfs sysfs "$ROOTFS_DIR/sys"
  sudo mount -o bind /dev "$ROOTFS_DIR/dev"
  sudo mount -o bind /dev/pts "$ROOTFS_DIR/dev/pts"
  
  log_success "Chroot environment ready"
}

# Install Droidian components
install_droidian() {
  log_info "Installing Droidian components..."
  
  # Add Droidian repository
  sudo chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
export DEBIAN_FRONTEND=noninteractive

# Add Droidian repository
wget -qO- https://repo.droidian.org/droidian.gpg.key | apt-key add -
echo "deb https://repo.droidian.org/droidian bullseye main" > /etc/apt/sources.list.d/droidian.list

# Update package lists
apt-get update

# Install Droidian core
apt-get install -y --no-install-recommends \
  droidian-phosh \
  droidian-configs \
  phosh \
  squeekboard \
  calls \
  chatty \
  gnome-contacts \
  gnome-calculator \
  gnome-clocks \
  gnome-weather \
  firefox-esr

# Install additional mobile-friendly packages
apt-get install -y --no-install-recommends \
  mobile-broadband-provider-info \
  modemmanager \
  ofono \
  pulseaudio \
  bluez \
  wpa-supplicant

# Clean up
apt-get autoremove -y
apt-get autoclean
EOF
  
  log_success "Droidian components installed"
}

# Setup Kali repositories and install packages
setup_kali_repos() {
  log_info "Setting up Kali Linux repositories..."
  
  if [ ! -x "$SCRIPTS_DIR/setup_repositories.sh" ]; then
    log_error "Repository setup script not found or not executable"
    exit 1
  fi
  
  sudo "$SCRIPTS_DIR/setup_repositories.sh" "$ROOTFS_DIR"
  
  log_success "Kali repositories configured"
}

# Install NetHunter theme
install_nethunter_theme() {
  log_info "Installing NetHunter Pro theme..."
  
  if [ ! -x "$SCRIPTS_DIR/install_nethunter_theme.sh" ]; then
    log_error "NetHunter theme installation script not found or not executable"
    exit 1
  fi
  
  sudo "$SCRIPTS_DIR/install_nethunter_theme.sh" "$ROOTFS_DIR" "$ASSETS_DIR"
  
  log_success "NetHunter Pro theme installed"
}

# Configure system
configure_system() {
  log_info "Configuring Kali-Droidian system..."
  
  # Set hostname
  echo "kali-droidian" | sudo tee "$ROOTFS_DIR/etc/hostname" > /dev/null
  
  # Configure hosts
  sudo tee "$ROOTFS_DIR/etc/hosts" > /dev/null << EOF
127.0.0.1   localhost
127.0.1.1   kali-droidian
::1         localhost ip6-localhost ip6-loopback
EOF
  
  # Configure locales
  sudo chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
export DEBIAN_FRONTEND=noninteractive

# Install locales
apt-get install -y locales

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
EOF
  
  # Set up users
  sudo chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
# Create kali user
useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev kali
echo "kali:kali" | chpasswd

# Set root password
echo "root:root" | chpasswd

# Enable password-less sudo for kali user
echo "kali ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/kali
EOF
  
  # Enable services
  sudo chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable phosh
systemctl enable gdm3
EOF
  
  log_success "System configuration completed"
}

# Install additional tools
install_tools() {
  log_info "Installing additional Kali tools..."
  
  if [ "$BUILD_TYPE" == "full" ]; then
    sudo chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
export DEBIAN_FRONTEND=noninteractive

# Install essential penetration testing tools
apt-get install -y --no-install-recommends \
  aircrack-ng \
  nmap \
  wireshark \
  tcpdump \
  ettercap-text-only \
  dnsrecon \
  fierce \
  nikto \
  dirb \
  gobuster \
  hydra \
  john \
  hashcat \
  sqlmap \
  wpscan \
  binwalk \
  foremost \
  volatility \
  yara \
  radare2 \
  gdb \
  strace \
  ltrace \
  hexedit

# Clean up
apt-get autoremove -y
apt-get autoclean
EOF
  fi
  
  log_success "Additional tools installed"
}

# Create boot splash
install_boot_splash() {
  log_info "Installing Plymouth boot splash..."
  
  sudo chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
export DEBIAN_FRONTEND=noninteractive

# Install Plymouth
apt-get install -y plymouth plymouth-themes

# Install custom theme if available
if [ -d /usr/share/plymouth/themes/kali ]; then
  plymouth-set-default-theme kali
  update-initramfs -u
fi
EOF
  
  # Copy Plymouth theme
  if [ -d "$ASSETS_DIR/plymouth/kali" ]; then
    sudo cp -r "$ASSETS_DIR/plymouth/kali" "$ROOTFS_DIR/usr/share/plymouth/themes/"
  fi
  
  log_success "Boot splash installed"
}

# Create image
create_image() {
  log_info "Creating system image..."
  
  local image_name="kali-droidian-${DEVICE_CODENAME}-$(date +%Y%m%d).img"
  local image_path="${BUILD_DIR}/${image_name}"
  
  # Calculate rootfs size (add 1GB for safety)
  local rootfs_size=$(sudo du -sm "$ROOTFS_DIR" | cut -f1)
  local image_size=$((rootfs_size + 1024))
  
  log_info "Creating ${image_size}MB image..."
  
  # Create image file
  dd if=/dev/zero of="$image_path" bs=1M count="$image_size"
  
  # Create partitions
  parted -s "$image_path" mklabel gpt
  parted -s "$image_path" mkpart primary ext4 1MiB 100%
  parted -s "$image_path" set 1 boot on
  
  # Setup loop device
  local loop_device
  loop_device=$(sudo losetup -fP --show "$image_path")
  
  # Format partition
  sudo mkfs.ext4 -L "kali-droidian" "${loop_device}p1"
  
  # Mount and copy files
  local mount_point="/tmp/kali-droidian-mount"
  sudo mkdir -p "$mount_point"
  sudo mount "${loop_device}p1" "$mount_point"
  
  log_info "Copying rootfs to image..."
  sudo rsync -av --progress "$ROOTFS_DIR/" "$mount_point/"
  
  # Sync and unmount
  sync
  sudo umount "$mount_point"
  sudo rmdir "$mount_point"
  sudo losetup -d "$loop_device"
  
  # Compress image
  log_info "Compressing image..."
  gzip -9 "$image_path"
  
  log_success "Image created: ${image_path}.gz"
}

# Cleanup
cleanup() {
  log_info "Cleaning up..."
  
  # Unmount chroot filesystems
  sudo umount "$ROOTFS_DIR/proc" 2>/dev/null || true
  sudo umount "$ROOTFS_DIR/sys" 2>/dev/null || true
  sudo umount "$ROOTFS_DIR/dev/pts" 2>/dev/null || true
  sudo umount "$ROOTFS_DIR/dev" 2>/dev/null || true
  
  log_success "Cleanup completed"
}

# Main build process
main() {
  log_info "Starting Kali-Droidian build process..."
  log_info "Device: $DEVICE_CODENAME, Architecture: $ARCH, Build Type: $BUILD_TYPE"
  
  # Set up trap for cleanup
  trap cleanup EXIT
  
  # Create build directory
  mkdir -p "$BUILD_DIR"
  
  # Check dependencies
  check_dependencies
  
  # Download assets
  download_assets
  
  # Verify assets
  verify_assets
  
  # Create base system
  create_base_rootfs
  
  # Setup chroot
  setup_chroot
  
  # Install components
  install_droidian
  setup_kali_repos
  install_nethunter_theme
  configure_system
  install_tools
  install_boot_splash
  
  # Create final image
  create_image
  
  log_success "Kali-Droidian build completed successfully!"
  log_info "Image location: ${BUILD_DIR}/kali-droidian-${DEVICE_CODENAME}-$(date +%Y%m%d).img.gz"
}

# Handle command line arguments
case "${1:-}" in
  --help|-h)
    echo "Kali-Droidian Build Script"
    echo "Usage: $0 [options]"
    echo ""
    echo "Environment variables:"
    echo "  DEVICE_CODENAME   Target device codename (default: generic)"
    echo "  ARCH             Target architecture (default: arm64)"
    echo "  BUILD_TYPE       Build type: minimal or full (default: full)"
    echo ""
    echo "Examples:"
    echo "  $0                           # Build for generic device"
    echo "  DEVICE_CODENAME=oneplus6 $0  # Build for OnePlus 6"
    echo "  BUILD_TYPE=minimal $0        # Minimal build"
    exit 0
    ;;
  --clean)
    log_info "Cleaning build directory..."
    sudo rm -rf "$BUILD_DIR"
    log_success "Build directory cleaned"
    exit 0
    ;;
  --assets-only)
    download_assets
    verify_assets
    exit 0
    ;;
  *)
    main "$@"
    ;;
esac
