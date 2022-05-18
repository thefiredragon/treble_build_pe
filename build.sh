#!/bin/bash
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_SIZE=100G
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=/mnt/cache

set -e

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"

BL=$PWD/treble_build_pe
BD=$HOME/builds
BRANCH=$1

[ "$BRANCH" == "" ] && BRANCH="twelve"
[ "$BRANCH" == "twelve" ] && BUILD="PixelExperience" || BUILD="PixelExperience_Plus"
[ "$BRANCH" == "twelve" ] && PEMK="$BL/pe.mk" || PEMK="$BL/peplus.mk"

initRepos() {
    echo "Initializing PE workspace"
    repo init -u https://github.com/PixelExperience/manifest -b $BRANCH
    echo ""

    echo "Preparing local manifest"
    mkdir -p .repo/local_manifests
    cp $BL/manifest.xml .repo/local_manifests/pixel.xml
    echo ""
}

syncRepos() {
    echo "Syncing repos"
    repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
    echo ""
}

applyPatches() {
    echo "Applying prerequisite patches"
    bash $BL/apply-patches.sh $BL prerequisite $BRANCH
    echo ""

    echo "Applying PHH patches"
    cd device/phh/treble
    cp $PEMK .
    bash generate.sh $(echo $PEMK | sed "s#$BL/##;s#.mk##")
    cd ../../..
    bash $BL/apply-patches.sh $BL phh $BRANCH
    echo ""

    echo "Applying personal patches"
    bash $BL/apply-patches.sh $BL personal $BRANCH
    echo ""
}

setupEnv() {
    echo "Setting up build environment"
    source build/envsetup.sh &>/dev/null
    mkdir -p $BD
    echo ""
}

buildTrebleApp() {
    echo "Building treble_app"
    cd treble_app
    bash build.sh release
    cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
    cd ..
    echo ""
}

buildVariant() {
    echo "Building treble_arm64_bvN"
    lunch treble_arm64_bvN-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    mv $OUT/system.img $BD/system-treble_arm64_bvN.img
    echo ""
}

buildSlimVariant() {
    echo "Building treble_arm64_bvN-slim"
    wget https://gist.github.com/ponces/891139a70ee4fdaf1b1c3aed3a59534e/raw/slim.patch -O /tmp/slim.patch
    (cd vendor/gapps && git am /tmp/slim.patch && rm /tmp/slim.patch)
    make -j$(nproc --all) systemimage
    (cd vendor/gapps && git reset --hard HEAD~1)
    mv $OUT/system.img $BD/system-treble_arm64_bvN-slim.img
    echo ""
}

buildVndkliteVariant() {
    echo "Building treble_arm64_bvN-vndklite"
    cd sas-creator
    sudo bash lite-adapter.sh 64 $BD/system-treble_arm64_bvN.img
    cp s.img $BD/system-treble_arm64_bvN-vndklite.img
    sudo rm -rf s.img d tmp
    cd ..
    echo ""
}

generatePackages() {
    echo "Generating packages"
    xz -cv $BD/system-treble_arm64_bvN.img -T0 > $BD/"$BUILD"_arm64-ab-12.1-$BUILD_DATE-UNOFFICIAL.img.xz
  #  xz -cv $BD/system-treble_arm64_bvN-vndklite.img -T0 > $BD/"$BUILD"_arm64-ab-vndklite-12.1-$BUILD_DATE-UNOFFICIAL.img.xz
  #  xz -cv $BD/system-treble_arm64_bvN-slim.img -T0 > $BD/"$BUILD"_arm64-ab-slim-12.1-$BUILD_DATE-UNOFFICIAL.img.xz
    rm -rf $BD/system-*.img
    echo ""
}

[ ! -d .repo ] && initRepos
syncRepos
applyPatches
setupEnv
buildTrebleApp
buildVariant
#buildSlimVariant
#buildVndkliteVariant
generatePackages

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
