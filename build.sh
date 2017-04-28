#!/bin/bash
# kernel build script by Tkkg1994 v0.4 (optimized from apq8084 kernel source)
# Modified by side / XDA Developers

VERSION_NUMBER=$(<build/version)

TOOLCHAIN_DIR=toolchain/bin/aarch64-linux-android-
TC=stock 
#stock/linaro/uber
THISDIR=`readlink -f .`;
OUTDIR=arch/$ARCH/boot
DTSDIR=arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=scripts/dtc/dtc
INCDIR=include
PAGE_SIZE=2048
DTB_PADDING=0
KERNELNAME=SideCore
ZIPLOC=zip
RAMDISKLOC=ramdisk

CLEAN()
{
ccache -c && ccache -C
make clean
make ARCH=arm64 distclean
rm -rf arch/arm64/boot/dtb
rm -f arch/arm64/boot/dts/*.dtb
rm -f arch/arm64/boot/boot.img-zImage
rm -f build/boot.img
rm -f build/*.zip
rm -f build/$RAMDISKLOC/J710x/ramdisk-new.cpio.gz
rm -f build/$RAMDISKLOC/J710x/split_img/boot.img-zImage
rm -f build/$ZIPLOC/J710x/*.zip
rm -f build/$ZIPLOC/J710x/*.img
rm -rf toolchain/*
echo "Copying toolchain"
if [ ! -d "toolchain" ]; then
	mkdir toolchain
fi
cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain
}

BUILD_ZIMAGE()
{
export CROSS_COMPILE=$TOOLCHAIN_DIR
export ARCH=arm64
make j7_2016_defconfig
make -j4
}

BUILD_RAMDISK()
{
mv arch/$ARCH/boot/Image arch/$ARCH/boot/boot.img-zImage
rm -f build/ramdisk/J710x/split_img/boot.img-zImage
mv -f arch/$ARCH/boot/boot.img-zImage build/ramdisk/J710x/split_img/boot.img-zImage
cd build/ramdisk/J710x
./repackimg.sh
echo SEANDROIDENFORCE >> image-new.img
}

BUILD_BOOTIMG()
{
	BUILD_ZIMAGE
	BUILD_RAMDISK
}

OPTION_2()
{
echo "Copying toolchain"
if [ ! -d "toolchain" ]; then
	mkdir toolchain
fi
cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain

MODEL=j7xelte
KERNEL_DEFCONFIG=j7_2016_defconfig
BUILD_BOOTIMG

cd $THISDIR
mv -f build/ramdisk/J710x/image-new.img build/$ZIPLOC/J710x/boot.img
cd build/zip/J710x

FILENAME=SideCore-$VERSION_NUMBER-`date +"[%H-%M]-[%d-%m]-MM-EUR"`.zip
zip -r $FILENAME .;

END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the build folder"
echo ""
exit
}


OPTION_1()
{
echo "Cleaning..."
CLEAN
exit
}


# -------------
# PROGRAM START
# -------------
echo "SideCore kernel for J170xx"
echo "1) Clean Workspace"
echo "2) Build kernel"
echo "3) Exit"
echo ""
read -p "Please select an option " prompt
echo ""
if [ $prompt == "1" ]; then
	OPTION_1
elif [ $prompt == "2" ]; then
	OPTION_2
elif [ $prompt == "3" ]; then
	exit
fi

