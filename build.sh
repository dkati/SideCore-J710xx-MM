#!/bin/bash
# kernel build script by Tkkg1994 v0.4 (optimized from apq8084 kernel source)
# Modified by side / XDA Developers

VERSION_NUMBER=$(<build/version)

TOOLCHAIN_DIR=toolchain/bin/aarch64-linux-android-
TC=stock 
#stock/linaro/uber
THISDIR=`readlink -f .`;

KERNELNAME=SideCore

OPTION_2()
{
	echo "Copying toolchain..."
	if [ ! -d "toolchain" ]; then
		mkdir toolchain
	fi
	cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain
	
	#Build pure zImage
	export CROSS_COMPILE=$TOOLCHAIN_DIR
	export ARCH=arm64
	make j7_2016_defconfig
	make -j4
	
	PRODUCTIMAGE="arch/arm64/boot/Image"
	if [ ! -f "$PRODUCTIMAGE" ]; then
		echo "build failed" 
		exit 0;
	fi
	
	cp -r arch/arm64/boot/Image build/proprietary/carliv/boot/boot.img-kernel
	
	cd build/proprietary/carliv
	./carliv_executable.sh
	cd ../../..
	cp -r build/proprietary/carliv/output/boot.img build/zip/boot.img
	cd build/zip
	FILENAME=SideCore-${VERSION_NUMBER}-`date +"[%H-%M]-[%d-%m]-J710xx-STOCK-MM"`.zip
	zip -r $FILENAME .;
	cd ../..
	
	
}

OPTION_1()
{

	echo "Cleaning custom kernel files..."
	rm -rf build/proprietary/kernel_stats/boot.img-kernel
	rm -rf build/zip/boot.img
	rm -rf build/zip/*.zip
	rm -rf build/proprietary/carliv/output/*
	rm -rf build/proprietary/carliv/boot-dummy/*
	rm -rf build/proprietary/carliv/boot/boot.img-kernel
	make clean
	make ARCH=arm64 distclean
	ccache -c 
	ccache -C
	rm -rf toolchain/*
	if [ ! -d "toolchain" ]; then
	mkdir toolchain
	fi
	
	cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain
	
}
rerun()
{
	bash build.sh;
}
echo ""
echo "SideCore kernel for J710xx"
echo "1) Clean Workspace"
echo "2) Build kernel"
echo "3) Exit"
echo ""
read -p "Please select an option " prompt
echo ""
if [ $prompt == "1" ]; then
	OPTION_1; 
	rerun;
elif [ $prompt == "2" ]; then
	OPTION_2; 
elif [ $prompt == "3" ]; then
	exit
fi


