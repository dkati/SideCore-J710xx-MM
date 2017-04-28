#!/bin/bash
# kernel build script by Tkkg1994 v0.4 (optimized from apq8084 kernel source)
# Modified by side / XDA Developers

VERSION_NUMBER=$(<build/version)

TOOLCHAIN_DIR=toolchain/bin/aarch64-linux-android-
TC=stock 
#stock/linaro/uber
THISDIR=`readlink -f .`;
OUTDIR=arch/arm64/boot
DTSDIR=arch/arm64/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=scripts/dtc/dtc
INCDIR=include
PAGE_SIZE=2048
DTB_PADDING=0
KERNELNAME=SideCore

CLEAN()
{
	ccache -c && ccache -C
	make clean
	make ARCH=arm64 distclean
	rm -rf PRODUCT/*
	rm -rf arch/arm64/boot/dtb
	rm -f arch/arm64/boot/dts/*.dtb
	rm -f arch/arm64/boot/boot.img-zImage
	rm -f build/boot.img
	rm -f build/*.zip
	rm -f build/ramdisk/J710x/ramdisk-new.cpio.gz
	rm -f build/ramdisk/J710x/split_img/boot.img-zImage
	rm -f build/zip/J710x/*.zip
	rm -f build/zip/J710x/*.img
	rm -rf toolchain/*
	echo "Copying toolchain"
	
	if [ ! -d "toolchain" ]; then
	mkdir toolchain
	fi
	
	cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain
}


OPTION_2()
{
	echo "Copying toolchain"
	if [ ! -d "toolchain" ]; then
		mkdir toolchain
	fi
	cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain

	#Build pure zImage
	export CROSS_COMPILE=$TOOLCHAIN_DIR
	export ARCH=arm64
	make j7_2016_defconfig
	make -j4

	#Build Ramdisk
	mv arch/arm64/boot/Image arch/arm64/boot/boot.img-zImage
	#rm -f build/ramdisk/J710x/split_img/boot.img-zImage
	mv -f arch/arm64/boot/boot.img-zImage build/ramdisk/J710x/split_img/boot.img-kernel
	cd build/ramdisk/J710x
	./repack_img
	echo SEANDROIDENFORCE >> boot.img
	

	cd $THISDIR
	mv -f build/ramdisk/J710x/boot.img build/zip/J710x/boot.img
	cd build/zip/J710x

	FILENAME=SideCore-$VERSION_NUMBER-`date +"[%H-%M]-[%d-%m]-MM-EUR"`.zip
	zip -r $FILENAME .;
	cp -r *.zip ../../../PRODUCT
	rm -rf *.zip

	echo ""
	exit
}


OPTION_1()
{
	echo "Cleaning..."
	CLEAN
	exit
}

echo ""
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

