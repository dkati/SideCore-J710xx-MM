#!/bin/bash
# kernel build script by Tkkg1994 v0.4 (optimized from apq8084 kernel source)
# Modified by side / XDA Developers

# ---------
# VARIABLES
# ---------
VERSION_NUMBER=$(<build/version)
ARCH=arm64
STOCK_TOOLCHAIN=stock_tc/aarch64-linux-android-4.9/bin/aarch64-linux-android-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
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

# ---------
# FUNCTIONS
# ---------
FUNC_CLEAN()
{
make clean
make ARCH=arm64 distclean
rm -f build/build.log
rm -f build/build-J710x.log
rm -rf arch/arm64/boot/dtb
rm -f arch/$ARCH/boot/dts/*.dtb
rm -f arch/$ARCH/boot/boot.img-zImage
rm -f build/boot.img
rm -f build/*.zip
rm -f build/$RAMDISKLOC/J710x/ramdisk-new.cpio.gz
rm -f build/$RAMDISKLOC/J710x/split_img/boot.img-zImage
rm -f build/$ZIPLOC/J710x/*.zip
rm -f /build/$ZIPLOC/J710x/*.img
}

FUNC_BUILD_ZIMAGE()
{
echo ""
echo "build common config="$KERNEL_DEFCONFIG ""
echo "build variant config="$MODEL ""
make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE \
	$KERNEL_DEFCONFIG || exit -1
make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
echo ""
}

FUNC_BUILD_RAMDISK()
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

FUNC_BUILD_BOOTIMG()
{
	(
	rm -f build/build.log
	rm -f build/build-J710x.log
	FUNC_BUILD_ZIMAGE
	FUNC_BUILD_RAMDISK
	) 2>&1	 | tee -a build/build.log
}

FUNC_BUILD_ZIP()
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


OPTION_5()
{
rm -f build/build.log
MODEL=j7xelte
KERNEL_DEFCONFIG=j7_2016_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a build/build.log
mv -f build/ramdisk/J710x/image-new.img build/$ZIPLOC/J710x/boot.img
mv -f build/build.log build/build-J710x.log
ZIP_DATE=`date +%Y%m%d`
ZIP_FILE_DIR=build/$ZIPLOC/J710x
ZIP_NAME=$KERNELNAME.J710x.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
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


OPTION_0()
{
echo "Cleaning Workspace"
FUNC_CLEAN
exit
}


# -------------
# PROGRAM START
# -------------
rm -rf ./build/build.log
clear
echo ""
echo " 1) Clean Workspace"
echo ""
echo " 2) Build kernel"
echo ""
echo " 3) Exit"
echo ""
read -p "Please select an option " prompt
echo ""
if [ $prompt == "1" ]; then
	OPTION_0
elif [ $prompt == "2" ]; then
	OPTION_5
elif [ $prompt == "3" ]; then
	exit
fi

