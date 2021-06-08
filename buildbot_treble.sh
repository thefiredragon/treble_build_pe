#!/bin/bash
echo ""
echo "Pixel Experience 11 Treble Buildbot"
echo "ATTENTION: this script syncs repo on each run"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
sleep 5

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

echo "Cloning dependecy repos"
[ ! -d ./treble_patches ] && git clone https://github.com/ponces/treble_patches -b eleven
[ ! -d ./sas-creator ] && git clone https://github.com/AndyCGYan/sas-creator
rm -rf treble_app && git clone https://github.com/phhusson/treble_app

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

echo "Reverting LOS FOD implementation"
cd frameworks/base
git am $BL/patches/0001-Squashed-revert-of-LOS-FOD-implementation.patch
cd ../..
cd frameworks/native
git revert 542069c3aa6d003887b4abba3c0f494e8271085f --no-edit # surfaceflinger: Add support for extension lib
cd ../..
echo ""

echo "Applying PHH patches"
rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
git clean -fdx
cp $BL/pe.mk .
bash generate.sh pe
cd ../../..
bash ~/treble_experimentations/apply-patches.sh treble_patches
echo ""

echo "Applying universal patches"
cd build/make
git am $BL/patches/0001-Make-broken-copy-headers-the-default.patch
cd ../..
cd frameworks/base
git am $BL/patches/0001-UI-Disable-wallpaper-zoom.patch
git am $BL/patches/0001-Disable-vendor-mismatch-warning.patch
cd ../..
cd vendor/aosp
git am $BL/patches/0001-vendor_lineage-Log-privapp-permissions-whitelist-vio.patch
cd ../..
echo ""

echo "Applying GSI-specific patches"
cd bootable/recovery
git revert c9a3611b0bab1744b3c4321e728c917fcdc2abc3 --no-edit # recovery: Allow custom bootloader msg offset in block misc
cd ../..
cd build/make
git am $BL/patches/0001-build-fix-device-name.patch
cd ../..
cd device/phh/treble
git am $BL/patches/0001-Remove-fsck-SELinux-labels.patch
git am $BL/patches/0001-base-provide-libnfc-nci.patch
git am $BL/patches/0001-base-remove-securize-script.patch
git am $BL/patches/0001-board-add-broken-duplicate-rules-flag.patch
git am $BL/patches/0001-rw-system-set-fingerprint-props.patch
git am $BL/patches/0001-add-offline-charger-sepolicy.patch
cd ../../..
cd frameworks/av
git revert 72fb8d96c85fd45e85516b4023cd5116b5d5a8eb --no-edit # camera: Allow devices to load custom CameraParameter code
cd ../..
cd frameworks/native
git revert 581c22f979af05e48ad4843cdfa9605186d286da --no-edit # Add suspend_resume trace events to the atrace 'freq' category.
cd ../..
cd packages/apps/Bluetooth
git revert bba4192627ca9987c0128f9774d79ffb17ece2f5 --no-edit # Bluetooth: Reset packages/apps/Bluetooth to upstream
cd ../../..
cd system/core
git am $BL/patches/0001-Revert-init-Add-vendor-specific-initialization-hooks.patch
git am $BL/patches/0001-Panic-into-recovery-rather-than-bootloader.patch
git am $BL/patches/0001-Restore-sbin.patch
git am $BL/patches/0001-fix-offline-charger-v7.patch
cd ../..
cd system/hardware/interfaces
git am $BL/patches/0001-Revert-system_suspend-start-early.patch
cd ../../..
cd system/sepolicy
git am $BL/patches/0001-Revert-sepolicy-Relabel-wifi.-properties-as-wifi_pro.patch
cd ../..
cd treble_app
git am $BL/patches/0001-Remove-securize-preference.patch
git am $BL/patches/0001-Remove-Customization-page.patch
cd ..
cd vendor/aosp
git am $BL/patches/0001-build_soong-Disable-generated_kernel_headers.patch
git am $BL/patches/0001-build-fix-build-number.patch
cd ../..
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
        xz -c s.img -T0 > ~/builds/PixelExperience_arm32_binder64-ab-vndklite-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        xz -c $OUT/system.img -T0 > ~/builds/PixelExperience_arm32_binder64-ab-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        ;;
    "treble_arm_bvN")
        bash run.sh 32 $OUT/system.img
        xz -c s.img -T0 > ~/builds/PixelExperience_arm-aonly-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        xz -c $OUT/system.img -T0 > ~/builds/PixelExperience_arm-ab-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        ;;
    "treble_arm64_bvN")
        bash run.sh 64 $OUT/system.img
        xz -c s.img -T0 > ~/builds/PixelExperience_arm64-aonly-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        bash lite-adapter.sh 64 $OUT/system.img
        xz -c s.img -T0 > ~/builds/PixelExperience_arm64-ab-vndklite-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        xz -c $OUT/system.img -T0 > ~/builds/PixelExperience_arm64-ab-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
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
ls ~/builds | grep 'PixelExperience'

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
