#!/bin/sh

set -ex
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel             \
	cmake                  \
	curl                   \
	git                    \
	hicolor-icon-theme     \
	i3-wm                  \
	libpulse               \
	libx11                 \
	libxrandr              \
	libxss                 \
	pulseaudio             \
	pulseaudio-alsa        \
	wget                   \
	xorg-server-xvfb       \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh libxml2-mini opus-mini

echo "Building polybar..."
echo "---------------------------------------------------------------"
sed -i -e 's|EUID == 0|EUID == 69|g' /usr/bin/makepkg
sed -i \
	-e 's|-O2|-O3|'                              \
	-e 's|MAKEFLAGS=.*|MAKEFLAGS="-j$(nproc)"|'  \
	-e 's|#MAKEFLAGS|MAKEFLAGS|'                 \
	/etc/makepkg.conf
cat /etc/makepkg.conf

git clone https://aur.archlinux.org/polybar-git.git ./polybar && (
	cd ./polybar
	sed -i -e "s|x86_64|$ARCH|" ./PKGBUILD
	makepkg -fs --noconfirm --skippgpcheck
	ls -la .
	pacman --noconfirm -U ./*.pkg.tar.*
)

pacman -Q polybar-git | awk '{print $2; exit}' > ~/version
