#!/bin/sh

CPU_JOB_NUM=`grep 'processor' /proc/cpuinfo | wc -l`
# https://sourcery.mentor.com/public/gnu_toolchain/arm-none-linux-gnueabi/arm-2012.03-57-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
TOOLCHAIN=$HOME/dev/arm-2012.03/bin
TOOLCHAIN_PREFIX=arm-none-linux-gnueabi-

if [ $3 ]; then
  suffix="test$3"
else
  suffix=""
fi

sed -i s/CONFIG_LOCALVERSION=\"-imoseyon-.*\"/CONFIG_LOCALVERSION=\"-imoseyon-${2}AOSP\"/ .config

if [ $1 -eq 2 ]; then
  sed -i "s/^.*UNLOCK_184.*$/CONFIG_UNLOCK_184MHZ=n/" .config
  zipfile="imoseyon_leanKernel_v${2}AOSP${suffix}.zip"
else
  sed -i "s/^.*UNLOCK_184.*$/CONFIG_UNLOCK_184MHZ=y/" .config
  zipfile="imoseyon_leanKernel_184Mhz_v${2}AOSP${suffix}.zip"
fi

make -j$CPU_JOB_NUM ARCH=arm CROSS_COMPILE=$TOOLCHAIN/$TOOLCHAIN_PREFIX
if [ $? -ne 0 ]; then
	# Don't continue, if make fails...
	echo -ne "\n\nWARNING: Make failed, stopping...\n\n"
	exit;
fi
# make nsio module here for now
cd nsio*
make
cd ..

find . -name "*.ko" | xargs $TOOLCHAIN/${TOOLCHAIN_PREFIX}strip --strip-unneeded

rm zip.aosp/system/lib/modules/*.ko
cp drivers/net/wireless/bcm4329/bcm4329.ko zip.aosp/system/lib/modules
cp drivers/net/tun.ko zip.aosp/system/lib/modules
cp drivers/staging/zram/zram.ko zip.aosp/system/lib/modules
cp lib/lzo/lzo_decompress.ko zip.aosp/system/lib/modules
cp lib/lzo/lzo_compress.ko zip.aosp/system/lib/modules
cp nsio*/*.ko zip.aosp/system/lib/modules
cp fs/cifs/cifs.ko zip.aosp/system/lib/modules
cp arch/arm/boot/zImage mkboot.aosp/
cp .config arch/arm/configs/lean_aosp_defconfig
cp .config .config.aosp

cd mkboot.aosp
echo "making boot image"
./img.sh

if [ ! $4 ]; then
	echo "making zip file"
	cp boot.img ../zip.aosp
	cd ../zip.aosp
	rm *.zip
	zip -r $zipfile *
	rm /tmp/*.zip
	cp *.zip /tmp
fi
