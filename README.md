
## Building PHH-based Pixel Experience GSIs ##

To get started with building Pixel Experience GSI, you'll need to get familiar with [Git and Repo](https://source.android.com/source/using-repo.html) as well as [How to build a GSI](https://github.com/phhusson/treble_experimentations/wiki/How-to-build-a-GSI%3F).

First, open a new Terminal window, which defaults to your home directory.  Clone the modified treble_experimentations repo there:

    git clone https://github.com/ponces/treble_experimentations

Create a new working directory for your Pixel Experience build and navigate to it:

    mkdir pixel; cd pixel

Initialize your Pixel Experience workspace:

    repo init -u https://github.com/PixelExperience/manifest -b eleven-plus

Clone the modified treble patches and this repo:

    git clone https://github.com/ponces/treble_patches -b eleven-plus
    git clone https://github.com/ponces/treble_build_pe -b eleven-plus

Finally, start the build script:

    bash treble_build_pe/buildbot_treble.sh

Be sure to update the cloned repos from time to time!

---

Note: A-only and VNDKLite targets are now generated from AB images - refer to [sas-creator](https://github.com/phhusson/sas-creator).
