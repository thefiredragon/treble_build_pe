#!/bin/bash

set -e

patches="$(readlink -f -- $1)"
tree="$2"
branches="$3 common"

for b in $branches;do
	for project in $(cd $patches/patches/$tree/$b; echo *);do
		p="$(tr _ / <<<$project |sed -e 's;platform/;;g')"
		[ "$p" == build ] && p=build/make
		[ "$p" == treble/app ] && p=treble_app
		pushd $p
		for patch in $patches/patches/$tree/$b/$project/*.patch;do
			#Check if patch is already applied
			if patch -f -p1 --dry-run -R < $patch > /dev/null;then
				continue
			fi

			if git apply --check $patch;then
				git am $patch
			elif patch -f -p1 --dry-run < $patch > /dev/null;then
				#This will fail
				git am $patch || true
				patch -f -p1 < $patch
				git add -u
				git am --continue
			else
				echo "Failed applying $patch"
			fi
		done
		popd
	done
done
