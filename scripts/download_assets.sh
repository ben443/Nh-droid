#!/bin/bash

set -e

ASSETS_DIR="$1"
TEMP_DIR="/tmp/kali-assets"

echo "=== Downloading Kali Assets ==="

# Create directories
mkdir -p "$ASSETS_DIR"
mkdir -p "$TEMP_DIR"

# Download Kali Linux official assets
echo "Downloading Kali Linux branding assets..."

# Kali Linux logo (official)
wget -q -O "$ASSETS_DIR/kali-logo.png" \
  "https://www.kali.org/images/kali-logo.png" || \
  curl -s -o "$ASSETS_DIR/kali-logo.png" \
  "https://gitlab.com/kalilinux/documentation/kali-docs/-/raw/master/images/kali-logo.png"

# Kali Linux wallpaper (official)
wget -q -O "$ASSETS_DIR/kali-wallpaper.jpg" \
  "https://www.kali.org/images/kali-wallpaper-2021.jpg" || \
  curl -s -o "$ASSETS_DIR/kali-wallpaper.jpg" \
  "https://gitlab.com/kalilinux/build-scripts/kali-wallpapers/-/raw/master/kali-wallpaper-2021.jpg"

# Download additional Kali wallpapers
echo "Downloading additional Kali wallpapers..."
mkdir -p "$ASSETS_DIR/wallpapers"

# Multiple wallpaper options
wallpapers=(
  "https://www.kali.org/images/kali-wallpaper-2022.jpg"
  "https://www.kali.org/images/kali-wallpaper-dark.jpg"
  "https://gitlab.com/kalilinux/build-scripts/kali-wallpapers/-/raw/master/kali-dragon-wallpaper.jpg"
)

for wallpaper in "${wallpapers[@]}"; do
  filename=$(basename "$wallpaper")
  wget -q -O "$ASSETS_DIR/wallpapers/$filename" "$wallpaper" || \
    curl -s -o "$ASSETS_DIR/wallpapers/$filename" "$wallpaper" || \
    echo "Warning: Failed to download $wallpaper"
done

# Download Kali Linux icon theme
echo "Downloading Kali icon theme..."
if ! wget -q -O "$TEMP_DIR/kali-icon-theme.tar.gz" \
  "https://gitlab.com/kalilinux/packages/kali-themes/-/archive/master/kali-themes-master.tar.gz"; then
  echo "Warning: Failed to download Kali icon theme, using fallback"
  # Create a minimal icon theme structure
  mkdir -p "$ASSETS_DIR/icons/kali"
  echo "[Icon Theme]" > "$ASSETS_DIR/icons/kali/index.theme"
  echo "Name=Kali" >> "$ASSETS_DIR/icons/kali/index.theme"
  echo "Comment=Kali Linux Icon Theme" >> "$ASSETS_DIR/icons/kali/index.theme"
  echo "Inherits=Adwaita" >> "$ASSETS_DIR/icons/kali/index.theme"
else
  cd "$TEMP_DIR"
  tar -xzf kali-icon-theme.tar.gz
  if [ -d "kali-themes-master" ]; then
    cp -r kali-themes-master/usr/share/icons/* "$ASSETS_DIR/icons/" 2>/dev/null || true
  fi
fi

# Download NetHunter Pro theme components
echo "Downloading NetHunter Pro theme components..."
mkdir -p "$ASSETS_DIR/nethunter-pro"

# Try to get NetHunter assets from official repository
if wget -q -O "$TEMP_DIR/nethunter-assets.tar.gz" \
  "https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project/-/archive/master/kali-nethunter-project-master.tar.gz"; then
  cd "$TEMP_DIR"
  tar -xzf nethunter-assets.tar.gz
  
  # Extract theme assets if they exist
  find . -name "*.png" -o -name "*.jpg" -o -name "*.svg" | while read -r file; do
    if [[ "$file" =~ (logo|wallpaper|icon|theme) ]]; then
      cp "$file" "$ASSETS_DIR/nethunter-pro/" 2>/dev/null || true
    fi
  done
fi

# Download GTK theme components
echo "Downloading GTK theme components..."
mkdir -p "$ASSETS_DIR/gtk-themes"

# Try to get Kali GTK themes
if wget -q -O "$TEMP_DIR/kali-gtk-themes.tar.gz" \
  "https://gitlab.com/kalilinux/packages/kali-themes/-/archive/master/kali-themes-master.tar.gz"; then
  cd "$TEMP_DIR"
  tar -xzf kali-gtk-themes.tar.gz
  
  # Extract GTK themes
  if [ -d "kali-themes-master/usr/share/themes" ]; then
    cp -r kali-themes-master/usr/share/themes/* "$ASSETS_DIR/gtk-themes/" 2>/dev/null || true
  fi
fi

# Download fonts
echo "Downloading Kali fonts..."
mkdir -p "$ASSETS_DIR/fonts"

# Download some common fonts used in Kali
fonts=(
  "https://github.com/google/fonts/raw/main/ofl/sourcecodepro/SourceCodePro-Regular.ttf"
  "https://github.com/google/fonts/raw/main/ofl/roboto/Roboto-Regular.ttf"
  "https://github.com/google/fonts/raw/main/ofl/robotomono/RobotoMono-Regular.ttf"
)

for font in "${fonts[@]}"; do
  filename=$(basename "$font")
  wget -q -O "$ASSETS_DIR/fonts/$filename" "$font" || \
    curl -s -o "$ASSETS_DIR/fonts/$filename" "$font" || \
    echo "Warning: Failed to download $font"
done

# Create Plymouth theme (boot splash)
echo "Creating Plymouth boot splash theme..."
mkdir -p "$ASSETS_DIR/plymouth/kali"

cat > "$ASSETS_DIR/plymouth/kali/kali.plymouth" << 'EOF'
[Plymouth Theme]
Name=Kali Linux
Description=Kali Linux boot splash theme
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/kali
ScriptFile=/usr/share/plymouth/themes/kali/kali.script
EOF

# Create Plymouth script
cat > "$ASSETS_DIR/plymouth/kali/kali.script" << 'EOF'
# Kali Linux Plymouth Theme Script
Window.SetBackgroundTopColor(0.0, 0.0, 0.0);
Window.SetBackgroundBottomColor(0.0, 0.0, 0.0);

logo.image = Image("kali-logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);

# Progress bar
progress_box.image = Image("progress_box.png");
progress_box.sprite = Sprite(progress_box.image);
progress_box.sprite.SetX(Window.GetWidth() / 2 - progress_box.image.GetWidth() / 2);
progress_box.sprite.SetY(Window.GetHeight() * 0.75);

progress_bar.original_image = Image("progress_bar.png");
progress_bar.sprite = Sprite();
progress_bar.sprite.SetX(Window.GetWidth() / 2 - progress_bar.original_image.GetWidth() / 2);
progress_bar.sprite.SetY(Window.GetHeight() * 0.75);

fun progress_callback(duration, progress) {
    if (progress_bar.original_image.GetWidth() > 0) {
        progress_bar.image = progress_bar.original_image.Scale(progress_bar.original_image.GetWidth() * progress, progress_bar.original_image.GetHeight());
        progress_bar.sprite.SetImage(progress_bar.image);
    }
}

Plymouth.SetBootProgressFunction(progress_callback);
EOF

# Create simple progress bar images if not downloaded
if [ ! -f "$ASSETS_DIR/plymouth/kali/progress_box.png" ]; then
  # Create a simple progress box (this would need actual image creation tools)
  echo "Creating fallback progress bar graphics..."
  # In a real implementation, you'd use ImageMagick or similar
  touch "$ASSETS_DIR/plymouth/kali/progress_box.png"
  touch "$ASSETS_DIR/plymouth/kali/progress_bar.png"
fi

# Copy logo for Plymouth
cp "$ASSETS_DIR/kali-logo.png" "$ASSETS_DIR/plymouth/kali/" 2>/dev/null || true

# Download GRUB theme
echo "Downloading GRUB theme..."
mkdir -p "$ASSETS_DIR/grub-theme"

if wget -q -O "$TEMP_DIR/grub-theme.tar.gz" \
  "https://github.com/vinceliuice/grub2-themes/archive/master.tar.gz"; then
  cd "$TEMP_DIR"
  tar -xzf grub-theme.tar.gz
  
  # Look for a dark theme suitable for Kali
  find . -name "*dark*" -type d | head -1 | while read -r theme_dir; do
    if [ -n "$theme_dir" ]; then
      cp -r "$theme_dir"/* "$ASSETS_DIR/grub-theme/" 2>/dev/null || true
    fi
  done
fi

# Verify downloads
echo "Verifying downloaded assets..."
required_files=(
  "$ASSETS_DIR/kali-logo.png"
  "$ASSETS_DIR/kali-wallpaper.jpg"
)

missing_files=()
for file in "${required_files[@]}"; do
  if [ ! -f "$file" ] || [ ! -s "$file" ]; then
    missing_files+=("$file")
  fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
  echo "Warning: Some required files are missing or empty:"
  printf '%s\n' "${missing_files[@]}"
  echo "Build may not have complete theming."
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "Asset download completed!"
echo "Downloaded assets to: $ASSETS_DIR"
echo "Available themes and assets:"
find "$ASSETS_DIR" -type f -name "*.png" -o -name "*.jpg" -o -name "*.svg" | head -10
