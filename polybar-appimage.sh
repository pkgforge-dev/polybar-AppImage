#!/bin/sh

APP=polybar
APPDIR="$APP".AppDir
REPO="https://github.com/polybar/polybar"
LIB="https://github.com/MusicPlayerDaemon/libmpdclient.git"
ICON="https://user-images.githubusercontent.com/36028424/39958898-230ddeec-563c-11e8-8318-d658c63ddf22.png"

# CREATE DIRECTORIES
if [ -z "$APP" ]; then exit 1; fi
mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# DOWNLOAD AND BUILD POLYBAR STATICALLY
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
CXXFLAGS='-static -O3' 
LDFLAGS="-static"

git clone --recursive "$REPO" && cd polybar && mkdir build && cd build && cmake -DENABLE_ALSA=ON .. \
&& make -j$(nproc) && make install DESTDIR="$CURRENTDIR" && cd ../.. || exit 1

git clone "$LIB" && cd libmpdclient && meson setup build -Dprefix="$CURRENTDIR/usr" \
&& ninja -C build && ninja -C build install && cd .. || exit 1

mv ./usr/* ./ && rm -rf ./polybar ./libmpdclient ./usr || exit 1
mv ./lib/x*/* ./lib # For some reason in the ubuntu runner the lib gets installed inside another directory

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/bash

CURRENTDIR="$(readlink -f "$(dirname "$0")")"
export LD_LIBRARY_PATH="$CURRENTDIR/lib:$LD_LIBRARY_PATH"

if [ "$1" = "msg" ]; then
	"$CURRENTDIR/bin/polybar-msg" "${@:2}"
else
	"$CURRENTDIR/bin/polybar" "$@"
fi
EOF
chmod a+x ./AppRun

APPVERSION=$(polybar --version | awk 'FNR == 1 {print $2}')

# Desktop
cat >> ./"$APP.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=polybar
Icon=polybar
Exec=polybar
Categories=System
Hidden=true
EOF

# Icon
wget "$ICON" -O ./polybar.png || touch ./polybar.png
ln -s ./polybar.png ./.DirIcon

# MAKE APPIMAGE
cd ..
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')
wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./appimagetool

# Do the thing!
ARCH=x86_64 VERSION="$APPVERSION" ./appimagetool -s ./"$APPDIR"
ls ./*.AppImage || { echo "appimagetool failed to make the appimage"; exit 1; }
if [ -z "$APP" ]; then exit 1; fi # Being extra safe lol
mv ./*.AppImage .. && cd .. && rm -rf ./"$APP"
echo "All Done!"
