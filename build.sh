#!/bin/bash
echo ""
echo "Pixel Experience 11 Treble Buildbot"
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
BRANCH=$1
[ "$BRANCH" == "" ] && BRANCH="eleven"
[ "$BRANCH" == "eleven" ] && BUILD="PixelExperience" || BUILD="PixelExperience_Plus"

echo "Preparing local manifest"
mkdir -p .repo/local_manifests
cp $BL/manifest.xml .repo/local_manifests/pixel.xml
echo ""

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Cloning dependecy repos"
[ ! -d ./sas-creator ] && git clone https://github.com/AndyCGYan/sas-creator
rm -rf treble_app && git clone https://github.com/phhusson/treble_app

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

echo "Applying prerequisite patches"
bash $BL/apply-patches.sh $BL prerequisite $BRANCH
echo ""

echo "Applying PHH patches"
rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
cp $BL/pe.mk .
bash generate.sh pe
cd ../../..
bash $BL/apply-patches.sh $BL phh $BRANCH
echo ""

echo "Applying personal patches"
bash $BL/apply-patches.sh $BL personal $BRANCH
echo ""

echo "Applying GSI-specific fixes"
mkdir -p device/generic/common/nfc
curl "https://android.googlesource.com/device/generic/common/+/refs/tags/android-11.0.0_r35/nfc/libnfc-nci.conf?format=TEXT"| base64 --decode > device/generic/common/nfc/libnfc-nci.conf
mkdir -p device/sample/etc
cp vendor/aosp/prebuilt/common/etc/apns-conf.xml device/sample/etc/apns-full-conf.xml
echo ""

echo "CHECK PATCH STATUS NOW!"
sleep 5
echo ""

export WITHOUT_CHECK_API=true
mkdir -p ~/builds

buildVariant() {
    lunch ${1}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    make vndk-test-sepolicy
    buildSasImage $1
}

buildSasImage() {
    cd sas-creator
    case $1 in
    "treble_a64_bvN")
        bash lite-adapter.sh 32 $OUT/system.img
        xz -c s.img -T0 > ~/builds/"$BUILD"_arm32_binder64-ab-vndklite-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        xz -c $OUT/system.img -T0 > ~/builds/"$BUILD"_arm32_binder64-ab-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        ;;
    "treble_arm_bvN")
        bash run.sh 32 $OUT/system.img
        xz -c s.img -T0 > ~/builds/"$BUILD"_arm-aonly-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        xz -c $OUT/system.img -T0 > ~/builds/"$BUILD"_arm-ab-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        ;;
    "treble_arm64_bvN")
        bash run.sh 64 $OUT/system.img
        xz -c s.img -T0 > ~/builds/"$BUILD"_arm64-aonly-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        bash lite-adapter.sh 64 $OUT/system.img
        xz -c s.img -T0 > ~/builds/"$BUILD"_arm64-ab-vndklite-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        xz -c $OUT/system.img -T0 > ~/builds/"$BUILD"_arm64-ab-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        ;;
    esac
    rm -rf s.img
    cd ..
}

buildTrebleApp() {
    cd treble_app
    bash build.sh
    cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
    cd ..
}

buildTrebleApp
buildVariant treble_arm_bvN
buildVariant treble_a64_bvN
buildVariant treble_arm64_bvN
ls ~/builds | grep $BUILD

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
