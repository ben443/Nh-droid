#!/bin/bash

set -e

ROOTFS_DIR="$1"
ASSETS_DIR="$2"

echo "=== Installing NetHunter Pro Phosh Theme ==="

# Create theme directories
mkdir -p "$ROOTFS_DIR/usr/share/themes/NetHunter-Pro"
mkdir -p "$ROOTFS_DIR/usr/share/icons/NetHunter-Pro"
mkdir -p "$ROOTFS_DIR/usr/share/backgrounds/nethunter"

# Install GTK theme
echo "Installing GTK theme..."
if [ -d "$ASSETS_DIR/gtk-themes" ]; then
  # Look for NetHunter or dark themes
  find "$ASSETS_DIR/gtk-themes" -maxdepth 1 -type d | while read -r theme_dir; do
    theme_name=$(basename "$theme_dir")
    if [[ "$theme_name" =~ (nethunter|kali|dark) ]]; then
      echo "Installing theme: $theme_name"
      cp -r "$theme_dir" "$ROOTFS_DIR/usr/share/themes/NetHunter-Pro-$theme_name"
    fi
  done
else
  # Create a basic NetHunter Pro theme
  echo "Creating basic NetHunter Pro theme..."
  mkdir -p "$ROOTFS_DIR/usr/share/themes/NetHunter-Pro/gtk-3.0"
  mkdir -p "$ROOTFS_DIR/usr/share/themes/NetHunter-Pro/gtk-2.0"
  
  # Create basic GTK3 theme
  cat > "$ROOTFS_DIR/usr/share/themes/NetHunter-Pro/gtk-3.0/gtk.css" << 'EOF'
/* NetHunter Pro GTK3 Theme */
@import url("/usr/share/themes/Adwaita-dark/gtk-3.0/gtk.css");

/* Override with NetHunter colors */
@define-color theme_bg_color #1a1a1a;
@define-color theme_fg_color #ffffff;
@define-color theme_selected_bg_color #ff6b35;
@define-color theme_selected_fg_color #ffffff;
@define-color theme_base_color #2d2d2d;
@define-color theme_text_color #ffffff;

/* Header bars */
headerbar {
  background: linear-gradient(to bottom, #2d2d2d, #1a1a1a);
  color: #ffffff;
}

/* Windows */
window {
  background-color: #1a1a1a;
  color: #ffffff;
}

/* Buttons */
button {
  background: linear-gradient(to bottom, #404040, #2d2d2d);
  border: 1px solid #555555;
  color: #ffffff;
}

button:hover {
  background: linear-gradient(to bottom, #505050, #3d3d3d);
}

button:active {
  background: linear-gradient(to bottom, #ff6b35, #e55a2b);
}
EOF

  # Create theme index
  cat > "$ROOTFS_DIR/usr/share/themes/NetHunter-Pro/index.theme" << 'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=NetHunter Pro
Comment=NetHunter Pro theme for Phosh
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=NetHunter-Pro
IconTheme=NetHunter-Pro
CursorTheme=Adwaita
ButtonLayout=close,minimize,maximize:menu
EOF
fi

# Install icon theme
echo "Installing icon theme..."
if [ -d "$ASSETS_DIR/icons" ]; then
  cp -r "$ASSETS_DIR/icons"/* "$ROOTFS_DIR/usr/share/icons/" 2>/dev/null || true
fi

# Create NetHunter Pro icon theme
cat > "$ROOTFS_DIR/usr/share/icons/NetHunter-Pro/index.theme" << 'EOF'
[Icon Theme]
Name=NetHunter Pro
Comment=NetHunter Pro icon theme
Inherits=Adwaita,hicolor
Directories=16x16/apps,22x22/apps,24x24/apps,32x32/apps,48x48/apps,64x64/apps,128x128/apps,256x256/apps

[16x16/apps]
Size=16
Context=Applications
Type=Fixed

[22x22/apps]
Size=22
Context=Applications
Type=Fixed

[24x24/apps]
Size=24
Context=Applications
Type=Fixed

[32x32/apps]
Size=32
Context=Applications
Type=Fixed

[48x48/apps]
Size=48
Context=Applications
Type=Fixed

[64x64/apps]
Size=64
Context=Applications
Type=Fixed

[128x128/apps]
Size=128
Context=Applications
Type=Fixed

[256x256/apps]
Size=256
Context=Applications
Type=Fixed
EOF

# Install wallpapers
echo "Installing wallpapers..."
if [ -f "$ASSETS_DIR/kali-wallpaper.jpg" ]; then
  cp "$ASSETS_DIR/kali-wallpaper.jpg" "$ROOTFS_DIR/usr/share/backgrounds/nethunter/"
fi

if [ -d "$ASSETS_DIR/wallpapers" ]; then
  cp "$ASSETS_DIR/wallpapers"/* "$ROOTFS_DIR/usr/share/backgrounds/nethunter/" 2>/dev/null || true
fi

# Configure Phosh to use NetHunter theme
echo "Configuring Phosh theme settings..."

# Create GSettings overrides for system-wide theme
mkdir -p "$ROOTFS_DIR/usr/share/glib-2.0/schemas"

cat > "$ROOTFS_DIR/usr/share/glib-2.0/schemas/99-nethunter-theme.gschema.override" << 'EOF'
[org.gnome.desktop.interface]
gtk-theme='NetHunter-Pro'
icon-theme='NetHunter-Pro'
cursor-theme='Adwaita'
font-name='Roboto 11'
document-font-name='Roboto 11'
monospace-font-name='Source Code Pro 10'

[org.gnome.desktop.wm.preferences]
theme='NetHunter-Pro'
titlebar-font='Roboto Bold 11'

[org.gnome.desktop.background]
picture-uri='file:///usr/share/backgrounds/nethunter/kali-wallpaper.jpg'
picture-options='zoom'
primary-color='#1a1a1a'
secondary-color='#2d2d2d'

[org.gnome.desktop.screensaver]
picture-uri='file:///usr/share/backgrounds/nethunter/kali-wallpaper.jpg'
picture-options='zoom'
primary-color='#1a1a1a'
secondary-color='#2d2d2d'

[sm.puri.phosh]
gtk-theme='NetHunter-Pro'
icon-theme='NetHunter-Pro'
EOF

# Compile GSettings schemas
chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
if command -v glib-compile-schemas >/dev/null 2>&1; then
  glib-compile-schemas /usr/share/glib-2.0/schemas/
fi
EOF

# Install fonts if available
if [ -d "$ASSETS_DIR/fonts" ]; then
  echo "Installing fonts..."
  mkdir -p "$ROOTFS_DIR/usr/share/fonts/truetype/nethunter"
  cp "$ASSETS_DIR/fonts"/* "$ROOTFS_DIR/usr/share/fonts/truetype/nethunter/" 2>/dev/null || true
  
  # Update font cache
  chroot "$ROOTFS_DIR" /bin/bash << 'EOF'
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f -v
fi
EOF
fi

# Create desktop entry for theme switcher
cat > "$ROOTFS_DIR/usr/share/applications/nethunter-theme-switcher.desktop" << 'EOF'
[Desktop Entry]
Name=NetHunter Theme Manager
Comment=Switch between NetHunter themes
Exec=gsettings set org.gnome.desktop.interface gtk-theme NetHunter-Pro
Icon=preferences-desktop-theme
Terminal=false
Type=Application
Categories=Settings;DesktopSettings;
Keywords=theme;appearance;gtk;
EOF

# Set up theme persistence
echo "Setting up theme persistence..."
mkdir -p "$ROOTFS_DIR/etc/skel/.config"

# Create default user configuration
cat > "$ROOTFS_DIR/etc/skel/.config/gtk-3.0.ini" << 'EOF'
[Settings]
gtk-theme-name=NetHunter-Pro
gtk-icon-theme-name=NetHunter-Pro
gtk-font-name=Roboto 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF

echo "NetHunter Pro theme installation completed!"