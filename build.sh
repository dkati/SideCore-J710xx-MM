#!/bin/bash
# kernel build script by Tkkg1994 v0.4 (optimized from apq8084 kernel source)
# Modified by Siddhant / XDA Developers

# ---------
# VARIABLES
# ---------
BUILD_SCRIPT=2.0
VERSION_NUMBER=$(<build/version)
ARCH=arm64
BUILD_CROSS_COMPILE=/usr/local/share/aarch64-linux-android-4.9/bin/aarch64-linux-android-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
RDIR=$(pwd)
OUTDIR=$RDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=$RDIR/scripts/dtc/dtc
INCDIR=$RDIR/include
PAGE_SIZE=2048
DTB_PADDING=0
KERNELNAME=LazerKernel
KERNELCONFIG=Lazerkernel
ZIPLOC=zip
RAMDISKLOC=ramdisk

# ---------
# FUNCTIONS
# ---------
FUNC_CLEAN()
{
make clean
make ARCH=arm64 distclean
rm -f $RDIR/build/build.log
rm -f $RDIR/build/build-G610F.log
rm -f $RDIR/build/build-J710x.log
rm -rf $RDIR/arch/arm64/boot/dtb
rm -f $RDIR/arch/$ARCH/boot/dts/*.dtb
rm -f $RDIR/arch/$ARCH/boot/boot.img-zImage
rm -f $RDIR/build/boot.img
rm -f $RDIR/build/*.zip
rm -f $RDIR/build/$RAMDISKLOC/G610x/image-new.img
rm -f $RDIR/build/$RAMDISKLOC/G610x/ramdisk-new.cpio.gz
rm -f $RDIR/build/$RAMDISKLOC/G610x/split_img/boot.img-zImage
rm -f $RDIR/build/$RAMDISKLOC/G610x/image-new.img
rm -f $RDIR/build/$RAMDISKLOC/J710x/ramdisk-new.cpio.gz
rm -f $RDIR/build/$RAMDISKLOC/J710x/split_img/boot.img-zImage
rm -f $RDIR/build/$ZIPLOC/G610x/*.zip
rm -f $RDIR/build/$ZIPLOC/G610x/*.img
rm -f $RDIR/build/$ZIPLOC/J710x/*.zip
rm -f $RDIR/build/$ZIPLOC/J710x/*.img
rm -f $RDIR/build/$ZIPLOC/g93xx/*.zip
rm -f $RDIR/build/$ZIPLOC/g93xx/*.img
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
	FUNC_CLEAN
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

OPTION_1()
{
rm -f $RDIR/build/build.log
MODEL=on7xelte
KERNEL_DEFCONFIG=on7xelteswa_00_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/ramdisk/G610x/image-new.img $RDIR/build/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-G610F.log
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your boot.img in the build folder"
echo "You can now find your build-G610F.log file in the build folder"
echo ""
exit
}

OPTION_2()
{
rm -f $RDIR/build/build.log
MODEL=j7xelte
KERNEL_DEFCONFIG=j7_2016_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/ramdisk/J710x/image-new.img $RDIR/build/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-J710x.log
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your boot.img in the build folder"
echo "You can now find your build-J710x.log file in the build folder"
echo ""
exit
}

OPTION_3()
{
rm -f $RDIR/build/build.log
MODEL=on7xelte
KERNEL_DEFCONFIG=on7xelteswa_00_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/ramdisk/G610x/image-new.img $RDIR/build/G610F.img-save
mv -f $RDIR/build/build.log $RDIR/build/build-G610F.log-save
MODEL=j7xelte
KERNEL_DEFCONFIG=j7_2016_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/G610F.img-save $RDIR/build/G610F.img
mv -f $RDIR/build/ramdisk/J710x/image-new.img $RDIR/build/J710x.img
mv -f $RDIR/build/build-G610F.log-save $RDIR/build/build-G610F.log
mv -f $RDIR/build/build.log $RDIR/build/build-J710x.log
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your G610F.img in the build folder"
echo "You can now find your J710x.img in the build folder"
echo "You can now find your build-G610F.log file in the build folder"
echo "You can now find your build-J710x.log file in the build folder"
echo ""
exit
}

OPTION_4()
{
rm -f $RDIR/build/build.log
MODEL=on7xelte
KERNEL_DEFCONFIG=on7xelteswa_00_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/ramdisk/G610x/image-new.img $RDIR/build/$ZIPLOC/G610x/boot.img
mv -f $RDIR/build/build.log $RDIR/build/build-G610F.log
ZIP_DATE=`date +%Y%m%d`
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/G610x
ZIP_NAME=$KERNELNAME.G610x.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the build folder"
echo "You can now find your build-G610F.log file in the build folder"
echo ""
exit
}

OPTION_5()
{
rm -f $RDIR/build/build.log
MODEL=j7xelte
KERNEL_DEFCONFIG=j7_2016_defconfig
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
exit
}

OPTION_6()
{
rm -f $RDIR/build/build.log
MODEL=on7xelte
KERNEL_DEFCONFIG=on7xelteswa_00_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/ramdisk/G610x/image-new.img $RDIR/build/$ZIPLOC/G610x/boot.img-save
mv -f $RDIR/build/build.log $RDIR/build/build-G610F.log-save
MODEL=j7xelte
KERNEL_DEFCONFIG=j7_2016_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/$ZIPLOC/G610x/boot.img-save $RDIR/build/$ZIPLOC/G610x/boot.img
mv -f $RDIR/build/ramdisk/J710x/image-new.img $RDIR/build/$ZIPLOC/J710x/boot.img
mv -f $RDIR/build/build-G610F.log-save $RDIR/build/build-G610F.log
mv -f $RDIR/build/build.log $RDIR/build/build-J710x.log
ZIP_DATE=`date +%Y%m%d`
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/G610x
ZIP_NAME=$KERNELNAME.G610x.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/J710x
ZIP_NAME=$KERNELNAME.J710x.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip files in the build folder"
echo "You can now find your build-G610F.log file in the build folder"
echo "You can now find your build-J710x.log file in the build folder"
echo ""
exit
}

OPTION_7()
{
rm -f $RDIR/build/build.log
MODEL=on7xelte
KERNEL_DEFCONFIG=on7xelteswa_00_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/ramdisk/G610x/image-new.img $RDIR/build/$ZIPLOC/g93xx/G610x.img-save
mv -f $RDIR/build/build.log $RDIR/build/build-G610F.log-save
MODEL=j7xelte
KERNEL_DEFCONFIG=j7_2016_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/build/build.log
mv -f $RDIR/build/$ZIPLOC/g93xx/G610x.img-save $RDIR/build/$ZIPLOC/g93xx/G610x.img
mv -f $RDIR/build/ramdisk/J710x/image-new.img $RDIR/build/$ZIPLOC/g93xx/J710x.img
mv -f $RDIR/build/build-G610F.log-save $RDIR/build/build-G610F.log
mv -f $RDIR/build/build.log $RDIR/build/build-J710x.log
ZIP_DATE=`date +%Y%m%d`
ZIP_FILE_DIR=$RDIR/build/$ZIPLOC/g93xx
ZIP_NAME=$KERNELNAME.G93xx.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the build folder"
echo "You can now find your build-G610F.log file in the build folder"
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

# ----------------------------------
# CHECK COMMAND LINE FOR ANY ENTRIES
# ----------------------------------
if [ $1 == 0 ]; then
	OPTION_0
fi
if [ $1 == 1 ]; then
	OPTION_1
fi
if [ $1 == 2 ]; then
	OPTION_2
fi
if [ $1 == 3 ]; then
	OPTION_3
fi
if [ $1 == 4 ]; then
	OPTION_4
fi
if [ $1 == 5 ]; then
	OPTION_5
fi
if [ $1 == 6 ]; then
	OPTION_6
fi
if [ $1 == 7 ]; then
	OPTION_7
fi

# -------------
# PROGRAM START
# -------------
rm -rf ./build/build.log
clear
echo "LazerKernel J7 Build Script v$BUILD_SCRIPT -- Kernel Version: v$VERSION_NUMBER"
echo ""
echo " 0) Clean Workspace"
echo ""
echo " 1) Build LazerKernel boot.img for J7 Prime"
echo " 2) Build LazerKernel boot.img for J7 2016"
echo " 3) Build LazerKernel boot.img for J7 + J7 2016"
echo " 4) Build LazerKernel boot.img and .zip for J7 Prime"
echo " 5) Build LazerKernel boot.img and .zip for J7 2016"
echo " 6) Build LazerKernel boot.img and .zip for J7 Prime + J7 2016 (Seperate)"
echo " 7) Build LazerKernel boot.img and .zip for J7 Prime + J7 2016 (All-In-One)"
echo ""
echo " 9) Exit"
echo ""
read -p "Please select an option " prompt
echo ""
if [ $prompt == "0" ]; then
	OPTION_0
elif [ $prompt == "1" ]; then
	OPTION_1
elif [ $prompt == "2" ]; then
	OPTION_2
elif [ $prompt == "3" ]; then
	OPTION_3
elif [ $prompt == "4" ]; then
	OPTION_4
elif [ $prompt == "5" ]; then
	OPTION_5
elif [ $prompt == "6" ]; then
	OPTION_6
elif [ $prompt == "7" ]; then
	OPTION_7
elif [ $prompt == "9" ]; then
	exit
fi

