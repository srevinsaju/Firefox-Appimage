#!/bin/bash
# MIT License
#
# Copyright (c) 2020 Srevin Saju
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.




set -eu

rm -rf build/AppDir
rm -rf build/firefox*
mkdir -p build/src

if [[ ! -f "build/src/$FIREFOX_PRODUCT.tar.bz2" ]]; then
    echo "==> Downloading $FIREFOX_PRODUCT"
    wget "https://download.mozilla.org/?product=$FIREFOX_PRODUCT-latest-ssl&os=$FIREFOX_OS&lang=$FIREFOX_LANG" -O "build/src/$FIREFOX_PRODUCT.tar.bz2" 
fi

tar -xvf "build/src/$FIREFOX_PRODUCT.tar.bz2" -C build
mv build/firefox* build/AppDir

echo "==> Copying AppRun"
cat AppRun | sed "s,FIREFOX_BIN_FILE,$( basename build/AppDir/firefox*-bin ),g" > build/AppDir/AppRun
chmod 755 build/AppDir/AppRun

echo "==> Copying Firefox Desktop file"
cp desktop/$FIREFOX_PRODUCT.desktop build/AppDir/.

echo "==> Disable Auto Updates"
cp -r distribution build/AppDir/.

FIREFOX_ICON_NAME="$( cat desktop/$FIREFOX_PRODUCT.desktop | grep 'Icon=' | sed 's,Icon=,,g' )"
echo "==> Copying icon :: $FIREFOX_ICON_NAME"
ln -sr build/AppDir/browser/chrome/icons/default/default128.png build/AppDir/$FIREFOX_ICON_NAME.png

echo "==> Downloading appimagetool" 
wget "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$(uname -m).AppImage" -O build/appimagetool
chmod +x build/appimagetool

echo "==> Generating AppImage"
GH_USER="$( echo $GITHUB_REPOSITORY | grep -o ".*/" | head -c-2 )"
GH_REPO="$( echo $GITHUB_REPOSITORY | grep -o "/.*" | cut -c2- )"

export FIREFOX_VERSION="$(cat build/AppDir/application.ini | grep -E 'Version' | head -n 1 | grep -E -o '[0-9]+.[0-9]+')"
export FIREFOX_BUILD_ID="$(cat build/AppDir/application.ini | grep -E 'BuildID' | head -n 1 | grep -E -o '[0-9]+')"

./build/appimagetool -n --comp gzip \
    build/AppDir \
    --updateinformation "gh-releases-zsync|$GH_USER|$GH_REPO|$FIREFOX_PRODUCT|$FIREFOX_PRODUCT*.AppImage.zsync" \
    $FIREFOX_PRODUCT-$FIREFOX_VERSION.r$FIREFOX_BUILD_ID-$( uname -m ).AppImage


mkdir -p dist
mv $FIREFOX_PRODUCT*.AppImage* dist/.
echo "==> Done, saved $( realpath dist/$FIREFOX_PRODUCT*.AppImage)"


