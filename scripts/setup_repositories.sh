#!/bin/bash

set -e

ROOTFS_DIR="$1"

echo "=== Setting up Kali Linux repositories ==="

# Backup original sources.list
if [ -f "$ROOTFS_DIR/etc/apt/sources.list" ]; then
  cp "$ROOTFS_DIR/etc/apt/sources.list" "$ROOTFS_DIR/etc/apt/sources.list.backup"
fi

# Add Kali Linux repository with proper key handling
echo "Adding Kali Linux repository..."

# Download and add Kali GPG key
chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
export DEBIAN_FRONTEND=noninteractive

# Install required packages for key management
apt-get update
apt-get install -y wget gnupg2 ca-certificates

# Add Kali Linux GPG key
wget -q -O - https://archive.kali.org/archive-key.asc | apt-key add -

# Alternative method if the above fails
if ! apt-key list | grep -q "Kali Linux Repository"; then
  wget -q -O /tmp/kali-archive-key.asc https://archive.kali.org/archive-key.asc
  apt-key add /tmp/kali-archive-key.asc
  rm /tmp/kali-archive-key.asc
fi
EOF

# Add Kali repository to sources.list.d
cat > "$ROOTFS_DIR/etc/apt/sources.list.d/kali.list" << 'EOF'
# Kali Linux Repository
deb http://http.kali.org/kali kali-rolling main contrib non-free
# deb-src http://http.kali.org/kali kali-rolling main contrib non-free

# Alternative mirrors (uncomment if needed)
# deb http://kali.download/kali kali-rolling main contrib non-free
# deb http://mirror.kali.org/kali kali-rolling main contrib non-free
EOF

# Create package preferences to avoid conflicts
cat > "$ROOTFS_DIR/etc/apt/preferences.d/kali-pin" << 'EOF'
# Pin Kali packages to lower priority to avoid conflicts with Debian/Droidian
Package: *
Pin: release o=Kali
Pin-Priority: 100

# Allow specific Kali tools to be installed
Package: kali-themes kali-wallpapers nethunter-* kali-menu kali-desktop-*
Pin: release o=Kali
Pin-Priority: 500

# High priority for essential pentesting tools
Package: aircrack-ng wireshark nmap metasploit-framework burpsuite sqlmap
Pin: release o=Kali
Pin-Priority: 600
EOF

# Add NetHunter repository if available
echo "Adding NetHunter repository..."
cat >> "$ROOTFS_DIR/etc/apt/sources.list.d/kali.list" << 'EOF'

# NetHunter Repository (if available)
# deb https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project kali-rolling main
EOF

# Update package lists
echo "Updating package lists..."
chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
export DEBIAN_FRONTEND=noninteractive
apt-get update || {
  echo "Warning: Some repositories may be unavailable"
  # Continue with available repositories
  apt-get update --allow-releaseinfo-change || true
}
EOF

# Install essential Kali packages
echo "Installing essential Kali packages..."
chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
export DEBIAN_FRONTEND=noninteractive

# Essential Kali branding and themes
apt-get install -y --no-install-recommends \
  kali-themes || echo "Warning: kali-themes not available"

# Try to install kali-wallpapers
apt-get install -y --no-install-recommends \
  kali-wallpapers || echo "Warning: kali-wallpapers not available"

# Install desktop environment enhancements
apt-get install -y --no-install-recommends \
  kali-desktop-core || echo "Warning: kali-desktop-core not available"

# Install some essential tools (optional, comment out if not needed)
apt-get install -y --no-install-recommends \
  kali-linux-core \
  kali-tools-top10 || echo "Warning: Some Kali tools not available"

# Clean up
apt-get autoremove -y
apt-get autoclean
EOF

echo "Repository setup completed!"