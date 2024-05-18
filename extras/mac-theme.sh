#!/bin/bash

# Update package lists
sudo apt-get update

# Install necessary dependencies for GTK theme, icon theme, and wallpapers
sudo apt-get install -y git gnome-tweaks gnome-shell-extensions chrome-gnome-shell

# Clone and install WhiteSur-gtk-theme
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
cd WhiteSur-gtk-theme
./install.sh
./tweaks.sh -F
sudo ./tweaks.sh -g
cd ..

# Clone and install WhiteSur-icon-theme
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
cd WhiteSur-icon-theme
./install.sh
cd ..

# Clone and install WhiteSur-wallpapers
git clone https://github.com/vinceliuice/WhiteSur-wallpapers.git --depth=1
cd WhiteSur-wallpapers
sudo ./install-gnome-backgrounds.sh  # For Gnome Backgrounds
./install-wallpapers.sh
cd ..

echo "WhiteSur GTK theme, icon theme, and wallpapers installed successfully!"