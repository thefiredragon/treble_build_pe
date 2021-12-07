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

if [ ! -d .repo ]
then
    echo "Initializing PE workspace"
    repo init -u https://github.com/PixelExperience/manifest -b twelve
    echo ""

    echo "Preparing local manifest"
    mkdir -p .repo/local_manifests
    cp $BL/manifest.xml .repo/local_manifests/pixel.xml
    echo ""
fi

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Cloning dependency repos"
[ ! -d sas-creator ] && git clone https://github.com/ponces/sas-creator
rm -rf treble_app && git clone https://github.com/phhusson/treble_app

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

echo "Applying PHH patches"
cd device/phh/treble
cp $BL/pe.mk .
bash generate.sh pe
cd ../../..
bash $BL/apply-patches.sh $BL phh
echo ""

echo "Applying personal patches"
bash $BL/apply-patches.sh $BL personal
echo ""

echo "Applying device specific patches"
bash $BL/apply-patches.sh $BL a40
echo ""

export WITHOUT_CHECK_API=true
mkdir -p ~/builds

buildTrebleApp() {
    cd treble_app
    bash build.sh release
    cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
    cd ..
}

buildVariant() {
    lunch ${1}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    make vndk-test-sepolicy
    mv $OUT/system.img ~/builds/system-"$1".img
    rm -rf out/target/product/phhgsi*
}

buildSasImages() {
    cd sas-creator
    BASE_IMAGE=~/builds/system-treble_a64_bvN.img
    if [ -f $BASE_IMAGE ]
    then
        sudo bash lite-adapter.sh 32 $BASE_IMAGE
        xz -c s.img -T0 > ~/builds/PixelExperience_arm32_binder64-ab-vndklite-12.0-$BUILD_DATE-UNOFFICIAL.img.xz
        xz -c $BASE_IMAGE -T0 > ~/builds/PixelExperience_arm32_binder64-ab-12.0-$BUILD_DATE-UNOFFICIAL.img.xz
        rm -rf $BASE_IMAGE
    fi
    BASE_IMAGE=~/builds/system-treble_arm64_bvN.img
    if [ -f $BASE_IMAGE ]
    then
        sudo bash lite-adapter.sh 64 $BASE_IMAGE
        xz -c s.img -T0 > ~/builds/PixelExperience_arm64-ab-vndklite-12.0-$BUILD_DATE-UNOFFICIAL.img.xz
        xz -c $BASE_IMAGE -T0 > ~/builds/PixelExperience_arm64-ab-12.0-$BUILD_DATE-UNOFFICIAL.img.xz
        rm -rf $BASE_IMAGE
    fi
    cd ..
}

buildTrebleApp
buildVariant treble_a64_bvN
buildVariant treble_arm64_bvN
buildSasImages
ls ~/builds | grep PixelExperience

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
