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
}

OPTION_1()
{
	make clean
	ccache -c 
	ccache -C
	rm -rf toolchain/*
	if [ ! -d "toolchain" ]; then
	mkdir toolchain
	fi
	
	cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain
	
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
	OPTION_1
elif [ $prompt == "2" ]; then
	OPTION_2
elif [ $prompt == "3" ]; then
	exit
fi


