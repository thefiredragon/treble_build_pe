#!/bin/bash
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_SIZE=100G
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=/mnt/cache


echo ""
echo "Pixel Experience 12 Treble Buildbot"
echo "ATTENTION: this script syncs repo on each run"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
sleep 5

# Abort early on error
set -eE
trap '(\
echo;\
echo \!\!\! An error happened during script execution;\
echo \!\!\! Please check console output for bad sync,;\
echo \!\!\! failed patch application, etc.;\
echo\
)' ERR

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"
WITHOUT_CHECK_API=true
BL=$PWD/treble_build_pe
BD=$HOME/builds
VERSION="v401"

if [ ! -d .repo ]
then
    echo "Initializing PE workspace"
    repo init -u https://github.com/thefiredragon/manifest -b twelve-plus
    echo ""

    echo "Preparing local manifest"
    mkdir -p .repo/local_manifests
    cp $BL/manifest.xml .repo/local_manifests/pixel.xml
    echo ""
fi

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo "Syncing finished, take snapshot"