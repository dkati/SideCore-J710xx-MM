#!/bin/bash
# kernel build script by Tkkg1994 v0.4 (optimized from apq8084 kernel source)
# Modified by side / XDA Developers

VERSION_NUMBER=$(<build/version)

TOOLCHAIN_DIR=toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-
TC=stock 
#stock/linaro/uber

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
rm -f build/build.log
rm -f build/build-J710x.log
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
cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain
}

BUILD_ZIMAGE()
{
export CROSS_COMPILE=$TOOLCHAIN_DIR
export ARCH=arm64
make exynos7870-j7xelte_eur_open_defconfig
make -j4
}

BUILD_RAMDISK()
{
if [ ! -f "build/ramdisk/J710x/ramdisk/config" ]; then
	mkdir build/ramdisk/J710x/ramdisk/config
	chmod 500 build/ramdisk/J710x/ramdisk/config
fi

mv arch/$ARCH/boot/Image arch/$ARCH/boot/boot.img-zImage
rm -f build/ramdisk/J710x/split_img/boot.img-zImage
mv -f arch/$ARCH/boot/boot.img-zImage build/ramdisk/J710x/split_img/boot.img-zImage
cd build/ramdisk/J710x
./repackimg.sh
echo SEANDROIDENFORCE >> image-new.img
	
}

BUILD_BOOTIMG()
{
	(
	rm -f build/build.log
	rm -f build/build-J710x.log
	BUILD_ZIMAGE
	BUILD_RAMDISK
	) 2>&1	 | tee -a build/build.log
}

BUILD_ZIP()
{
echo ""
echo "Building Zip File"
cd $ZIP_FILE_DIR
zip -gq $ZIP_NAME -r META-INF/ -x "*~"
zip -gq $ZIP_NAME -r system/ -x "*~" 
[ -f "build/$ZIPLOC/J710x/boot.img" ] && zip -gq $ZIP_NAME boot.img -x "*~"
if [ -n `which java` ]; then
	echo "Java Detected, Signing Zip File"
	mv $ZIP_NAME old$ZIP_NAME
	java -Xmx1024m -jar build/signapk/signapk.jar -w build/signapk/testkey.x509.pem build/signapk/testkey.pk8 old$ZIP_NAME $ZIP_NAME
	rm old$ZIP_NAME
fi
chmod a+r $ZIP_NAME
mv -f $ZIP_FILE_TARGET build/$ZIP_NAME
}


OPTION_2()
{
rm -f build/build.log
MODEL=j7xelte
KERNEL_DEFCONFIG=j7_2016_defconfig
START_TIME=`date +%s`
	(
	BUILD_BOOTIMG
	) 2>&1	 | tee -a build/build.log
mv -f build/ramdisk/J710x/image-new.img build/$ZIPLOC/J710x/boot.img
mv -f build/build.log build/build-J710x.log
ZIP_DATE=`date +%Y%m%d`
ZIP_FILE_DIR=build/$ZIPLOC/J710x
ZIP_NAME=$KERNELNAME.J710x.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
BUILD_ZIP
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the build folder"
echo "You can now find your build-J710x.log file in the build folder"
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
rm -rf ./build/build.log
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

