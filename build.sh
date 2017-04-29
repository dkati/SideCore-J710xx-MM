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
	rm -rf PRODUCT/Side*
	rm -rf arch/arm64/boot/dtb
	rm -f arch/arm64/boot/dts/*.dtb
	rm -f arch/arm64/boot/boot.img-zImage
	rm -f build/boot.img
	rm -f build/*.zip
	rm -f build/ramdisk/J710x/ramdisk-new.cpio.gz
	rm -f build/ramdisk/J710x/split_img/boot.img-zImage
	rm -f build/ramdisk/J710x/split_img/boot.img-Image
	rm -f build/ramdisk/J710x/split_img/boot.img
	rm -f build/zip/J710x/*.zip
	rm -f build/zip/J710x/*.img
	rm -rf toolchain/*
	rm -rf build/ramdisk/J710x/split_img/boot.img-kernel
	rm -rf build/ramdisk/J710x/split_img/boot.img-ramdisk.gz
	rm -rf build/ramdisk/J710x/split_img/myboot.img
	rm -rf build/ramdisk/J710x/boot.img-ramdisk.gz
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

	cp -r arch/arm64/boot/Image build/ramdisk/J710x/split_img/boot.img-kernel
	cd build/ramdisk/J710x
	
	chmod -R 755 bin/*
	minigzipbin=bin/minigzip
	mkbootfs=bin/mkbootfs;
	mkbootimgdir=../bin/mkbootimg

	./$mkbootfs ramdisk | ./$minigzipbin -c -9 > boot.img-ramdisk.gz;
	cp -r *.gz split_img/boot.img-ramdisk.gz
	
	cd split_img
	second=
	dtb=boot.img-dt
	
	./$mkbootimgdir --kernel boot.img-kernel --ramdisk boot.img-ramdisk.gz --pagesize 2048 --cmdline "" --board SRPOL10A000KU --base 0x10000000 --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 --dt boot.img-dt -o myboot.img;
	echo SEANDROIDENFORCE >> build/ramdisk/J710x/split_img/myboot.img


	cd $THISDIR
	mv -f build/ramdisk/J710x/split_img/myboot.img build/zip/J710x/boot.img
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

