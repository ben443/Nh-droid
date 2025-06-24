#!/bin/bash

set -e

ROOTFS_DIR="$1"
CONFIG_DIR="$(dirname "$0")/../config"

if [[ -z "$ROOTFS_DIR" ]]; then
    echo "Usage: $0 <rootfs_directory>"
    exit 1
fi

log() {
    echo "[SYSTEM-CONFIG] $1"
}

log "Configuring system in $ROOTFS_DIR"

# Create kali user
log "Creating kali user..."
chroot "$ROOTFS_DIR" /bin/bash -c "
    useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev kali
    echo 'kali:kali' | chpasswd
    usermod -aG sudo kali
"

# Configure sudo
log "Configuring sudo..."
cat > "$ROOTFS_DIR/etc/sudoers.d/kali" << 'EOF'
kali ALL=(ALL:ALL) NOPASSWD: ALL
EOF

# Configure NetworkManager
log "Configuring NetworkManager..."
mkdir -p "$ROOTFS_DIR/etc/NetworkManager/conf.d"
cat > "$ROOTFS_DIR/etc/NetworkManager/conf.d/10-globally-managed-devices.conf" << 'EOF'
[keyfile]
unmanaged-devices=none
EOF

# Configure systemd services
log "Configuring systemd services..."
chroot "$ROOTFS_DIR" /bin/bash -c "
    systemctl enable NetworkManager
    systemctl enable bluetooth
    systemctl enable gdm3
    systemctl enable phosh
    systemctl disable ModemManager
"

# Configure locales
log "Configuring locales..."
chroot "$ROOTFS_DIR" /bin/bash -c "
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
    locale-gen
    update-locale LANG=en_US.UTF-8
"

# Configure timezone
log "Configuring timezone..."
chroot "$ROOTFS_DIR" /bin/bash -c "
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    dpkg-reconfigure -f noninteractive tzdata
"

# Configure keyboard
log "Configuring keyboard..."
cat > "$ROOTFS_DIR/etc/default/keyboard" << 'EOF'
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF

# Configure Phosh
log "Configuring Phosh..."
mkdir -p "$ROOTFS_DIR/etc/phosh"
cat > "$ROOTFS_DIR/etc/phosh/phoc.ini" << 'EOF'
[core]
# Phoc configuration for mobile devices
xwayland=true

[output:*]
# Default output configuration
scale=1.5
mode=720x1440@60
EOF

# Create Phosh session
mkdir -p "$ROOTFS_DIR/usr/share/wayland-sessions"
cat > "$ROOTFS_DIR/usr/share/wayland-sessions/phosh.desktop" << 'EOF'
[Desktop Entry]
Name=Phosh
Comment=Phone Shell
Exec=phosh
Type=Application
DesktopNames=Phosh:GNOME
EOF

# Configure GDM for Phosh
log "Configuring GDM for mobile..."
mkdir -p "$ROOTFS_DIR/etc/gdm3"
cat > "$ROOTFS_DIR/etc/gdm3/custom.conf" << 'EOF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=kali
DefaultSession=phosh
WaylandEnable=true

[security]
DisallowTCP=true

[xdmcp]
Enable=false

[chooser]

[debug]
Enable=false
EOF

# Configure environment
log "Configuring environment..."
cat > "$ROOTFS_DIR/etc/environment" << 'EOF'
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
LANG="en_US.UTF-8"
LANGUAGE="en_US:en"
LC_ALL="en_US.UTF-8"
XDG_CURRENT_DESKTOP="Phosh:GNOME"
XDG_SESSION_TYPE="wayland"
WAYLAND_DISPLAY="wayland-0"
GDK_BACKEND="wayland"
QT_QPA_PLATFORM="wayland"
MOZ_ENABLE_WAYLAND="1"
KALI_ROLLING="1"
EOF

# Configure user directories
log "Configuring user directories..."
mkdir -p "$ROOTFS_DIR/home/kali/.config"
mkdir -p "$ROOTFS_DIR/home/kali/Desktop"
mkdir -p "$ROOTFS_DIR/home/kali/Downloads"
mkdir -p "$ROOTFS_DIR/home/kali/Documents"
mkdir -p "$ROOTFS_DIR/home/kali/Pictures"
mkdir -p "$ROOTFS_DIR/home/kali/Videos"
mkdir -p "$ROOTFS_DIR/home/kali/Music"

# Create desktop entries for Kali tools
log "Creating desktop entries..."
mkdir -p "$ROOTFS_DIR/usr/share/applications"

cat > "$ROOTFS_DIR/usr/share/applications/kali-tools.desktop" << 'EOF'
[Desktop Entry]
Name=Kali Tools
Comment=Access to Kali Linux penetration testing tools
Exec=gnome-terminal -- bash -c "echo 'Kali Linux Mobile - Penetration Testing Tools'; echo ''; echo 'Available tools:'; echo '- nmap: Network discovery and security auditing'; echo '- nikto: Web server scanner'; echo '- sqlmap: SQL injection testing'; echo '- metasploit: Penetration testing framework'; echo '- aircrack-ng: Wireless network security tools'; echo '- john: Password cracking tool'; echo '- hashcat: Advanced password recovery'; echo '- wireshark: Network protocol analyzer'; echo '- burpsuite: Web application security testing'; echo '- gobuster: Directory/file enumeration'; echo ''; echo 'Type any tool name to start or use --help for options'; echo ''; bash"
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;Security;
EOF

cat > "$ROOTFS_DIR/usr/share/applications/kali-nethunter.desktop" << 'EOF'
[Desktop Entry]
Name=Kali NetHunter
Comment=Mobile penetration testing suite
Exec=gnome-terminal -- bash -c "echo 'Kali NetHunter Mobile'; echo ''; echo 'Mobile-optimized penetration testing environment'; echo ''; echo 'Features:'; echo '- Wireless auditing tools'; echo '- Network reconnaissance'; echo '- Web application testing'; echo '- Bluetooth testing'; echo '- USB HID attacks'; echo '- Social engineering toolkit'; echo ''; echo 'This is a mobile-optimized environment for security testing'; echo ''; bash"
Icon=security-high
Terminal=false
Type=Application
Categories=System;Security;
EOF

# Configure bash for kali user
log "Configuring bash for kali user..."
cat > "$ROOTFS_DIR/home/kali/.bashrc" << 'EOF'
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# Append to the history file, don't overwrite it
shopt -s histappend

# For setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Kali-specific aliases
alias kali-tools='echo "Available Kali tools: nmap, nikto, sqlmap, metasploit, aircrack-ng, john, hashcat, wireshark, burpsuite, gobuster"'
alias update-kali='sudo apt update && sudo apt upgrade'
alias kali-info='echo "Kali Linux Mobile - Penetration Testing Distribution"'

# Custom PS1 with Kali branding
PS1='\[\033[01;32m\]┌──(\[\033[01;34m\]\u\[\033[01;32m\]@\[\033[01;34m\]\h\[\033[01;32m\])-[\[\033[01;37m\]\w\[\033[01;32m\]]\n\[\033[01;32m\]└─\[\033[01;34m\]\$\[\033[00m\] '

# Welcome message
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃Welcome to Kali Linux Mobile - Penetration Testing Distribution                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ┃
┃Type 'kali-tools' to see available penetration testing tools                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
EOF

# Set proper permissions
chroot "$ROOTFS_DIR" /bin/bash -c "chown -R kali:kali /home/kali"

# Configure default applications
log "Configuring default applications..."
mkdir -p "$ROOTFS_DIR/home/kali/.config"
cat > "$ROOTFS_DIR/home/kali/.config/mimeapps.list" << 'EOF'
[Default Applications]
text/plain=org.gnome.gedit.desktop
text/html=firefox-esr.desktop
application/xhtml+xml=firefox-esr.desktop
image/jpeg=org.gnome.eog.desktop
image/png=org.gnome.eog.desktop
image/gif=org.gnome.eog.desktop
video/mp4=org.gnome.Totem.desktop
video/x-msvideo=org.gnome.Totem.desktop
audio/mpeg=org.gnome.Rhythmbox3.desktop
audio/ogg=org.gnome.Rhythmbox3.desktop
inode/directory=org.gnome.Nautilus.desktop

[Added Associations]
text/plain=org.gnome.gedit.desktop;
text/html=firefox-esr.desktop;
application/xhtml+xml=firefox-esr.desktop;
image/jpeg=org.gnome.eog.desktop;
image/png=org.gnome.eog.desktop;
image/gif=org.gnome.eog.desktop;
video/mp4=org.gnome.Totem.desktop;
video/x-msvideo=org.gnome.Totem.desktop;
audio/mpeg=org.gnome.Rhythmbox3.desktop;
audio/ogg=org.gnome.Rhythmbox3.desktop;
inode/directory=org.gnome.Nautilus.desktop;
EOF

# Configure Firefox for mobile
log "Configuring Firefox for mobile..."
mkdir -p "$ROOTFS_DIR/home/kali/.mozilla/firefox"
cat > "$ROOTFS_DIR/home/kali/.mozilla/firefox/profiles.ini" << 'EOF'
[Profile0]
Name=default
IsRelative=1
Path=kali-mobile.default
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF

mkdir -p "$ROOTFS_DIR/home/kali/.mozilla/firefox/kali-mobile.default"
cat > "$ROOTFS_DIR/home/kali/.mozilla/firefox/kali-mobile.default/user.js" << 'EOF'
// Firefox mobile optimization for Kali Linux Mobile
user_pref("browser.startup.homepage", "https://www.kali.org");
user_pref("browser.newtabpage.enabled", true);
user_pref("browser.newtabpage.activity-stream.showSearch", true);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", true);
user_pref("browser.newtabpage.activity-stream.topSitesRows", 2);
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("dom.security.https_only_mode", true);
user_pref("network.cookie.cookieBehavior", 1);
user_pref("browser.cache.disk.enable", true);
user_pref("browser.cache.memory.enable", true);
user_pref("browser.sessionhistory.max_entries", 10);
user_pref("toolkit.telemetry.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("browser.shopping.experience2023.enabled", false);
user_pref("dom.push.enabled", false);
user_pref("geo.enabled", false);
user_pref("media.navigator.enabled", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.prefetch-next", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.formfill.enable", false);
user_pref("signon.rememberSignons", false);
user_pref("browser.fixup.alternate.enabled", false);
user_pref("browser.urlbar.trimURLs", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("keyword.enabled", false);
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.tabs.closeWindowWithLastTab", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.download.useDownloadDir", true);
user_pref("browser.download.dir", "/home/kali/Downloads");
user_pref("browser.helperApps.deleteTempFileOnExit", true);
user_pref("browser.pagethumbnails.capturing_disabled", true);
user_pref("media.eme.enabled", false);
user_pref("media.gmp-widevinecdm.enabled", false);
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.downloads", false);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.history", false);
user_pref("privacy.clearOnShutdown.sessions", true);
user_pref("privacy.resistFingerprinting", true);
user_pref("webgl.disabled", true);
user_pref("dom.event.clipboardevents.enabled", false);
user_pref("media.autoplay.default", 5);
user_pref("browser.pocket.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("identity.fxaccounts.enabled", false);
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.tabs.firefox-view-next", false);
EOF

# Configure power management
log "Configuring power management..."
mkdir -p "$ROOTFS_DIR/etc/UPower"
cat > "$ROOTFS_DIR/etc/UPower/UPower.conf" << 'EOF'
[UPower]
EnableWattsUpPro=true
NoPollBatteries=false
IgnoreLid=false
UsePercentageForPolicy=true
PercentageLow=15
PercentageCritical=5
PercentageAction=2
TimeLow=1200
TimeCritical=300
TimeAction=120
CriticalPowerAction=PowerOff
EOF

# Configure bluetooth
log "Configuring Bluetooth..."
mkdir -p "$ROOTFS_DIR/etc/bluetooth"
cat > "$ROOTFS_DIR/etc/bluetooth/main.conf" << 'EOF'
[General]
Name = Kali-Mobile
Class = 0x000100
DiscoverableTimeout = 0
AlwaysPairable = false
PairableTimeout = 0
DeviceID = bluetooth:1d6b:0246:0532
ReverseServiceDiscovery = true
NameResolving = true
DebugKeys = true
ControllerMode = dual
MultiProfile = multiple
FastConnectable = false

[Policy]
AutoEnable=true
EOF

# Configure audio
log "Configuring audio..."
mkdir -p "$ROOTFS_DIR/etc/pulse"
cat > "$ROOTFS_DIR/etc/pulse/daemon.conf" << 'EOF'
; PulseAudio daemon configuration for mobile devices
daemonize = no
fail = yes
allow-module-loading = yes
allow-exit = yes
use-pid-file = yes
system-instance = no
local-server-type = user
enable-shm = yes
shm-size-bytes = 0
lock-memory = no
cpu-limit = no
high-priority = yes
nice-level = -11
realtime-scheduling = yes
realtime-priority = 5
exit-idle-time = 20
scache-idle-time = 20
dl-search-path = (depends on architecture)
load-default-script-file = yes
default-script-file = /etc/pulse/default.pa
log-target = auto
log-level = notice
log-meta = no
log-time = no
log-backtrace = 0
resample-method = speex-float-1
avoid-resampling = false
enable-remixing = yes
remixing-use-all-sink-channels = yes
enable-lfe-remixing = no
lfe-crossover-freq = 0
default-sample-format = s16le
default-sample-rate = 44100
alternate-sample-rate = 48000
default-sample-channels = 2
default-channel-map = front-left,front-right
default-fragments = 4
default-fragment-size-msec = 25
enable-deferred-volume = yes
deferred-volume-safety-margin-usec = 8000
deferred-volume-extra-delay-usec = 0
flat-volumes = no
rescue-streams = yes
EOF

# Final system cleanup
log "Performing final system cleanup..."
chroot "$ROOTFS_DIR" /bin/bash -c "
    apt-get autoremove -y
    apt-get autoclean
    rm -rf /var/lib/apt/lists/*
    rm -rf /tmp/*
    rm -rf /var/tmp/*
    find /var/log -type f -exec truncate -s 0 {} \;
"

# Set final permissions
chroot "$ROOTFS_DIR" /bin/bash -c "
    chown -R kali:kali /home/kali
    chmod 755 /home/kali
    chmod -R 755 /home/kali/.config
    chmod -R 755 /home/kali/.mozilla
"

log "System configuration completed successfully"