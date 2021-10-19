#!/bin/bash
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
BL=$PWD/treble_build_pe

echo "Preparing local manifest"
mkdir -p .repo/local_manifests
cp $BL/manifest.xml .repo/local_manifests/pixel.xml
echo ""

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Cloning Treble App repo"
rm -rf treble_app && git clone https://github.com/phhusson/treble_app

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

echo "Applying PHH patches"
rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
cp $BL/pe.mk .
bash generate.sh pe
cd ../../..
bash $BL/apply-patches.sh $BL phh
echo ""

echo "Applying personal patches"
bash $BL/apply-patches.sh $BL personal
echo ""

echo "CHECK PATCH STATUS NOW!"
sleep 5
echo ""

export WITHOUT_CHECK_API=true
mkdir -p ~/builds

buildTrebleApp() {
    cd treble_app
    bash build.sh
    cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
    cd ..
}

buildVariant() {
    lunch ${1}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    make vndk-test-sepolicy
    xz -c $OUT/system.img -T0 > ~/builds/PixelExperience_arm64-ab-12.0-$BUILD_DATE-UNOFFICIAL.img.xz
}

buildTrebleApp
buildVariant treble_arm64_bvN
ls ~/builds | grep PixelExperience

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
