#!/bin/bash
# Builds out Adapta theme variants for a variety of material design colors.
# For Debian-based distros.

# Material design palette (https://www.google.com/design/spec/style/color.html)
Red300=#E57373
Red500=#F44336
RedA200=#FF5252
Pink300=#F06292
Pink500=#E91E63
Purple300=#BA68C8
Purple500=#9C27B0
DPurple300=#9575CD
DPurple500=#673AB7
Indigo300=#7986CB
Indigo500=#3F51B5
Blue300=#64B5F6
Blue500=#2196F3
BlueA400=#2979FF
LBlue300=#4FC3F7
LBlue500=#03A9F4
Cyan300=#4DD0E1
Cyan500=#00BCD4
Teal300=#4DB6AC
Teal500=#009688
Green300=#81C784
Green500=#4CAF50
LGreen300=#AED581
LGreen500=#8BC34A
Lime300=#DCE775
Lime500=#CDDC39
Lime700=#AFB42B
Yellow300=#FFF176
Yellow500=#FFEB3B
Amber300=#FFD54F
Amber500=#FFC107
Orange300=#FFB74D
Orange500=#FF9800
OrangeA200=#FFAB40
DOrange300=#FF8A65
DOrange400=#FF7043
DOrange500=#FF5722
Brown300=#A1887F
Brown500=#795548
Grey300=#E0E0E0
Grey500=#9E9E9E
BlueGrey500=#607D8B
BlueGrey300=#90A4AE

# Variants to build:  Primary      Secondary    Accent       Suggestion   Destruction
VARIANTS=(
  "Adapta-Red         $Red500      $Red300      $DOrange300  $DOrange500  $RedA200"
  "Adapta-RedGrey     $Red500      $Red300      $BlueGrey300 $BlueGrey500 $RedA200"
  "Adapta-Pink        $Pink500     $Pink300     $Red300      $Red500      $RedA200"
  "Adapta-Purple      $Purple500   $Purple300   $DPurple300  $DPurple500  $RedA200"
  "Adapta-DeepPurple  $DPurple500  $DPurple300  $Indigo300   $Indigo500   $RedA200"
  "Adapta-Indigo      $Indigo500   $Indigo300   $DPurple300  $DPurple500  $RedA200"
  "Adapta-Blue        $Blue500     $Blue300     $Indigo300   $Indigo500   $RedA200"
  "Adapta-LightBlue   $LBlue500    $LBlue300    $Indigo300   $Indigo500   $RedA200"
  "Adapta-Cyan        $Cyan500     $Cyan300     $Teal300     $Teal500     $RedA200"  # default colors
  "Adapta-Teal        $Teal500     $Teal300     $Teal300     $Teal500     $RedA200"
  "Adapta-Green       $Green500    $Green300    $Teal300     $Teal500     $RedA200"
  "Adapta-LightGreen  $LGreen500   $LGreen300   $Green300    $Green500    $RedA200"
  "Adapta-Lime        $Lime700     $Lime500     $LGreen300   $LGreen500   $RedA200"  # Lime500 is too bright
  # Yellow: too bright
  "Adapta-Amber       $Amber500    $Amber300    $Orange300   $Orange500   $RedA200"
  "Adapta-Orange      $Orange500   $Orange300   $DOrange300  $DOrange500  $RedA200"
  "Adapta-DeepOrange  $DOrange400  $DOrange300  $Brown300    $Brown500    $RedA200"  # DOrange400 close to Ambiance
  "Adapta-Brown       $Brown500    $Brown300    $Brown300    $Brown500    $RedA200"
  "Adapta-Grey        $Grey500     $Grey300     $BlueGrey300 $BlueGrey500 $RedA200"
  "Adapta-BlueGrey    $BlueGrey500 $BlueGrey300 $BlueGrey300 $BlueGrey500 $RedA200"
)

set -e -o pipefail
shopt -s extglob

install_build_deps() {
  REQUIRED="
    autoconf
    automake
    build-essential
    dpkg
    fakeroot
    git
    gnome-shell
    inkscape
    libgdk-pixbuf2.0-dev
    libglib2.0-dev
    libsass0
    libxml2-utils
    parallel
    pkg-config
    sassc
  "

  export LC_ALL=C
  NOT_INSTALLED=$(comm -13 \
      <(dpkg --get-selections | egrep -o '^[^ :[:space:]]+' | sort -u) \
      <(echo "$REQUIRED" | egrep -o '[^ ]+' | sort -u))

  if [[ "${NOT_INSTALLED}" != "" ]]; then
    echo "Build dependencies to install: ${NOT_INSTALLED}"
    sudo apt install ${NOT_INSTALLED}
  fi
}

build_variant() {
  NAME=$1
  ARGS="--with-selection_color=$2 \
    --with-second_selection_color=$3 \
    --with-accent_color=$4 \
    --with-suggestion_color=$5 \
    --with-destruction_color=$6"
  if (( ${#VARIANTS[@]} <= 10 )); then
    ARGS+=" --enable-parallel";
  fi

  ROOT="$(pwd)"
  BUILD="$ROOT/build/tmp/$NAME"
  PREFIX="$BUILD/prefix"
  LOG="$BUILD/build.log"

  echo "Building variant $NAME in $BUILD..."
  mkdir -p "$BUILD" && cp -a !(build) "$BUILD/"
  cd "$BUILD"
  (./autogen.sh --prefix="$PREFIX" $ARGS && make && make install) >"$LOG" 2>&1 ||
    (echo "$NAME: build failed, see log in $LOG"; touch $ROOT/failed; exit 1)
  cd "$PREFIX/share/themes"
  for DIR in Adapta*; do
    DST="$ROOT/build/${DIR/Adapta/$NAME}"
    mv $DIR "$DST"
    echo "Built: $DST"
  done
}

package_build() {
  cd build/
  rm -rf tmp
  mkdir -p pkg/{DEBIAN,usr/share/themes}
  cp -a Adapta* pkg/usr/share/themes
  echo "Package: adapta-gtk-theme-colorpack
Version: $(git describe)
Architecture: all
Maintainer: none
Depends: gtk2-engines-pixbuf (>= 2.24.30), gtk2-engines-murrine (>= 0.98.1), libgtk2.0-common (>= 2.24.30), libgtk-3-common (>= 3.22.11)
Section: x11
Priority: optional
Homepage: https://github.com/adapta-project/adapta-gtk-theme
Description: Adapta Gtk+ Theme" >pkg/DEBIAN/control
  PKG="adapta-gtk-theme-colorpack_$(git describe).deb"
  fakeroot dpkg-deb --build pkg $PKG || (echo "$NAME: dpkg-deb failed"; exit 1)
  rm -rf pkg
  echo "Built: $(pwd)/$PKG"
}

install_build_deps
rm -rf build/
for i in ${!VARIANTS[@]}; do
  build_variant ${VARIANTS[i]} &
done
wait
if [[ -f build/failed ]]; then exit 1; fi
package_build
