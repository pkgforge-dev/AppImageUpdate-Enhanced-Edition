#!/bin/sh

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH=${ARCH:-"$(uname -m)"}

LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"
UPINFO="gh-releases-zsync|pkgforge-dev|AppImageUpdate|latest|*$ARCH.AppImage.zsync"

# use RAM disk if possible
TEMP_BASE=/tmp
BUILD_DIR="$(mktemp -d -p "$TEMP_BASE" AppImageUpdate-build-XXXXXX)"

cleanup () {
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
}

trap cleanup EXIT

# store repo root as variable
REPO_ROOT="$(readlink -f "$(dirname "$(dirname "$0")")")"
OLD_CWD="$(readlink -f .)"

cd "$BUILD_DIR"
cmake "$REPO_ROOT" \
    -DBUILD_QT_UI=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=MinSizeRel

# next step is to build the binaries
make -j"$(nproc)"

# set up the AppDirs initially
for appdir in appimageupdatetool.AppDir validate.AppDir; do
	make install DESTDIR="$appdir"
	mkdir -p "$appdir"/resources
	cp -v "$REPO_ROOT"/resources/*.xpm "$appdir"/resources/
done

# determine Git commit ID
# appimagetool uses this for naming the file
VERSION="$(cd "$REPO_ROOT" && git rev-parse --short HEAD)"
export VERSION
#echo "$VERSION" > ~/version

# prepend GitHub run number if possible
if [ "$GITHUB_RUN_NUMBER" != "" ]; then
	export VERSION="$GITHUB_RUN_NUMBER-$VERSION"
fi

# remove unnecessary files from AppDirs
rm appimageupdatetool.AppDir/usr/bin/AppImageUpdate || true
rm appimageupdatetool.AppDir/usr/lib/*/libappimageupdate-qt*.so* || true
rm -rf appimageupdatetool.AppDir/usr/include || true
find appimageupdatetool.AppDir -type f -iname '*.a' -delete

mv ./appimageupdatetool.AppDir ./AppDir
find ./AppDir

# bundle application
wget "$LIB4BN" -O ./AppDir/lib4bin && (
	cd ./AppDir
	chmod +x ./lib4bin
	mv ./usr ./shared

	cp -v "$REPO_ROOT"/resources/appimageupdatetool.desktop ./ 
	cp -v "$REPO_ROOT"/resources/appimage.png ./
	ln -s appimage.png ./.DirIcon

	./lib4bin -p -v -k -s ./shared/bin/*
	./sharun -g

	# We need a newer version of glibc since the current one doesn't support --argv0
	if [ "$ARCH" = x86_64 ]; then
		wget http://ftp.us.debian.org/debian/pool/main/g/glibc/libc6_2.41-12_amd64.deb
	else
		wget http://ftp.us.debian.org/debian/pool/main/g/glibc/libc6_2.41-12_arm64.deb
	fi
	ar x *.deb
	tar fx data.tar.xz
	cp -vr ./usr/lib/*/* ./shared/lib
	rm -rf ./usr *.tar.* *.deb ./shared/lib/gconv
)

echo '#!/bin/sh

CURRENTDIR="$(dirname "$(readlink -f "$0")")"
BIN="${ARGV0:-$0}"
BIN="${BIN#./}"

if [ "$1" = --help ] ||[ -z "$1" ]; then
	>&2 echo ""
	>&2 echo "    AppImageUpdate Enhanced Edition 💪"
	>&2 echo "    appimageupdatetool CLI and validate CLI in a single AppImage"
	>&2 echo ""
	>&2 echo "    Usage: "
	>&2 echo "    ${APPIMAGE:-$0} [options...] [<path to AppImage>]" to use appimageupdatetool
	>&2 echo "    ${APPIMAGE:-$0} validate [options...] [<path to AppImage>]" to use validate
	>&2 echo ""
	>&2 echo "    You can also symlink this AppImage as 'validate' to launch the validate CLI directly"
	>&2 echo ""
fi

if [ -f "$CURRENTDIR/bin/$BIN" ]; then
	exec "$CURRENTDIR/bin/$BIN" "$@"
elif [ -f "$CURRENTDIR/bin/$1" ]; then
	BIN="$1"
	shift
	exec "$CURRENTDIR/bin/$BIN" "$@"
else
	exec "$CURRENTDIR/bin/appimageupdatetool" "$@"
fi' > ./AppDir/AppRun
chmod +x ./AppDir/AppRun

# Make appimage with uruntime
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O ./uruntime-lite
chmod +x ./uruntime*

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression lzma -S24 -B8 \
	--header uruntime-lite \
	-i ./AppDir -o ./appimageupdatetool+validate-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

# move AppImage to old cwd
mv appimageupdatetool+validate*.AppImage* "$OLD_CWD"/
cd -
