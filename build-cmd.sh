#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

version=$( cd breakpad && git describe --always )

if [ -z "$AUTOBUILD" ] ; then
    exit 1
fi

# load autobuild provided shell functions and variables
# first remap the autobuild env to fix the path for sickwin
if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

stage="$(pwd)/stage"

source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

LIBRARY_DIRECTORY_RELEASE="$stage/lib/release"
BINARY_DIRECTORY="$stage/bin"
INCLUDE_DIRECTORY="$stage/include/google_breakpad"
mkdir -p "$LIBRARY_DIRECTORY_RELEASE"
mkdir -p "$BINARY_DIRECTORY"

mkdir -p "$stage/LICENSES"

case "$AUTOBUILD_PLATFORM" in
    # ------------------------------- windows --------------------------------
    windows*)
    ;;

    darwin*)
    ;;

    # -------------------------------- linux ---------------------------------
    linux*)
		pushd breakpad
		mkdir -p third_party/lss/
		mkdir -p src/third_party/lss/
		cp ../linux-syscall-support/*.h third_party/lss/
		cp ../linux-syscall-support/*.h src/third_party/lss/
        VIEWER_FLAGS="-m$AUTOBUILD_ADDRSIZE -fno-stack-protector $LL_BUILD_RELEASE"

        ./configure --prefix="$stage" CFLAGS="$VIEWER_FLAGS" CXXFLAGS="$VIEWER_FLAGS" LDFLAGS="$VIEWER_FLAGS"
        make -j6
		make install
		mkdir -p "${stage}/lib/release"
		cp -a ${stage}/lib/*.a "${stage}/lib/release/"
		cp LICENSE "$stage/LICENSES/google_breakpad.txt"
    ;;
esac

echo "${version}" > "${stage}/version.txt"

