#!/bin/bash
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_SIZE=100G
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=/mnt/cache

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"

BL=$PWD/treble_build_pe
BD=$HOME/builds
BRANCH=$1

[ "$BRANCH" == "" ] && BRANCH="twelve"
[ "$BRANCH" == "twelve" ] && BUILD="PixelExperience" || BUILD="PixelExperience_Plus"
[ "$BRANCH" == "twelve" ] && PEMK="$BL/pe.mk" || PEMK="$BL/peplus.mk"

set -eE
trap '(\
echo;\
echo \!\!\! An error happened during script execution;\
echo \!\!\! Please check console output for bad sync,;\
echo \!\!\! failed patch application, etc.;\
echo\
)' ERR

echo ""
[ "$BRANCH" == "twelve" ] && echo "Pixel Experience 12 Treble Buildbot" || echo "Pixel Experience Plus 12 Treble Buildbot"
echo "ATTENTION: this script syncs repo on each run"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
sleep 5

if [ ! -d .repo ]
then
    echo "Initializing PE workspace"
    repo init -u https://github.com/thefiredragon/manifest -b $BRANCH
    echo ""

    echo "Preparing local manifest"
    mkdir -p .repo/local_manifests
    cp $BL/manifest.xml .repo/local_manifests/pixel.xml
    echo ""
fi

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo "Sync finished"