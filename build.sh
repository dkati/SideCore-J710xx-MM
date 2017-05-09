#!/bin/bash
# kernel build script by Tkkg1994 v0.4 (optimized from apq8084 kernel source)
# Modified by Siddhant / XDA Developers

# ---------
# VARIABLES
# ---------
BUILD_SCRIPT=1.2
VERSION_NUMBER=$(<build/version)

ARCH=arm64
BUILD_CROSS_COMPILE=toolchain/bin/aarch64-linux-android-
TC=stock 
#stock/linaro/uber

BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
RDIR=$(pwd)
OUTDIR=$RDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTCTOOL=$RDIR/scripts/dtc/dtc
INCDIR=$RDIR/include
PAGE_SIZE=2048
DTB_PADDING=0
KERNELNAME=SideCore
KERNELCONFIG=SideCore
ZIPLOC=zip
RAMDISKLOC=ramdisk

# ---------
# FUNCTIONS
# ---------
FUNC_CLEAN()
{


ccache -c
ccache -C
make clean
make ARCH=arm64 distclean
rm -f $RDIR/build/build.log
rm -f $RDIR/build/build-J710x.log
rm -rf $RDIR/arch/arm64/boot/dtb
rm -f $RDIR/arch/$ARCH/boot/dts/*.dtb
rm -f $RDIR/arch/$ARCH/boot/boot.img-zImage
rm -f $RDIR/build/boot.img
rm -f $RDIR/build/*.zip
rm -f $RDIR/build/$RAMDISKLOC/J710x/ramdisk-new.cpio.gz
rm -f $RDIR/build/$RAMDISKLOC/J710x/split_img/boot.img-zImage
rm -f $RDIR/build/$ZIPLOC/J710x/*.zip
rm -f $RDIR/build/$ZIPLOC/J710x/*.img
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/acct/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/cache/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/data/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/dev/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/lib/modules/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/mnt/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/proc/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/storage/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/sys/.placeholder
echo "" > $RDIR/build/$RAMDISKLOC/J710x/ramdisk/system/.placeholder

echo "Copying toolchain..."
if [ ! -d "toolchain" ]; then
	mkdir toolchain
fi
cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain

}

FUNC_DELETE_PLACEHOLDERS()
{
find . -name \.placeholder -type f -delete
echo "Placeholders Deleted from Ramdisk"
echo ""
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

if [ ! -f "$RDIR/build/ramdisk/G610x/ramdisk/config" ]; then
	mkdir $RDIR/build/ramdisk/G610x/ramdisk/config
	chmod 500 $RDIR/build/ramdisk/G610x/ramdisk/config
fi
if [ ! -f "$RDIR/build/ramdisk/J710x/ramdisk/config" ]; then
	mkdir $RDIR/build/ramdisk/J710x/ramdisk/config
	chmod 500 $RDIR/build/ramdisk/J710x/ramdisk/config
fi

mv $RDIR/arch/$ARCH/boot/Image $RDIR/arch/$ARCH/boot/boot.img-zImage
case $MODEL in
on7xelte)
	rm -f $RDIR/build/ramdisk/G610x/split_img/boot.img-zImage
	mv -f $RDIR/arch/$ARCH/boot/boot.img-zImage $RDIR/build/ramdisk/G610x/split_img/boot.img-zImage
	cd $RDIR/build/ramdisk/G610x
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	;;
j7xelte)
	rm -f $RDIR/build/ramdisk/J710x/split_img/boot.img-zImage
	mv -f $RDIR/arch/$ARCH/boot/boot.img-zImage $RDIR/build/ramdisk/J710x/split_img/boot.img-zImage
	cd $RDIR/build/ramdisk/J710x
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	;;
*)
	echo "Unknown device: $MODEL"
	exit 1
	;;
esac
}

FUNC_BUILD_BOOTIMG()
{
	(
	FUNC_BUILD_ZIMAGE
	FUNC_BUILD_RAMDISK
	) 2>&1	 | tee -a $RDIR/build/build.log
}

FUNC_BUILD_ZIP()
{
echo ""
echo "Building Zip File"
cd $ZIP_FILE_DIR
zip -gq $ZIP_NAME -r META-INF/ -x "*~"
zip -gq $ZIP_NAME -r system/ -x "*~" 
[ -f "$RDIR/build/$ZIPLOC/G610x/boot.img" ] && zip -gq $ZIP_NAME boot.img -x "*~"
[ -f "$RDIR/build/$ZIPLOC/J710x/boot.img" ] && zip -gq $ZIP_NAME boot.img -x "*~"
if [ -n `which java` ]; then
	echo "Java Detected, Signing Zip File"
	mv $ZIP_NAME old$ZIP_NAME
	java -Xmx1024m -jar $RDIR/build/signapk/signapk.jar -w $RDIR/build/signapk/testkey.x509.pem $RDIR/build/signapk/testkey.pk8 old$ZIP_NAME $ZIP_NAME
	rm old$ZIP_NAME
fi
chmod a+r $ZIP_NAME
mv -f $ZIP_FILE_TARGET $RDIR/build/$ZIP_NAME
cd $RDIR
}





OPTION_5()
{
if [ ! -d "toolchain" ]; then
	mkdir toolchain
	fi
	
	cp -r ../toolchains/$TC/aarch64-linux-android-4.9/* toolchain
rm -f $RDIR/build/build.log
MODEL=j7xelte
KERNEL_DEFCONFIG=Lazer_Kernel_j7xelte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/ramdisk/J710x/image-new.img $RDIR/build/$ZIPLOC/J710x/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-J710x.log
ZIP_DATE=`date +%Y%m%d`
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/J710x
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
}



OPTION_0()
{
echo "Cleaning Workspace"
FUNC_CLEAN
}



# -------------
# PROGRAM START
# -------------
rm -rf ./build/build.log
clear
echo "Lazer_Kernel J7 Build Script v$BUILD_SCRIPT -- Kernel Version: v$VERSION_NUMBER"
echo ""
echo " 0) Clean Workspace"
echo ""
echo " 5) Build Lazer_Kernel boot.img and .zip for J7 2016"
echo ""
echo " 9) Exit"
echo ""
read -p "Please select an option " prompt
echo ""
if [ $prompt == "0" ]; then
	OPTION_0
	echo ""
	echo ""
	echo ""
	echo ""
	./build.sh
elif [ $prompt == "5" ]; then
	OPTION_5
	echo ""
	echo ""
	echo ""
	echo ""
	read -n 1 -s -p "Press any key to continue"
elif [ $prompt == "9" ]; then
	exit
fi

