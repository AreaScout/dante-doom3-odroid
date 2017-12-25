#!/bin/bash

LINK_PATH="/usr/share/applications/doom3.desktop"
CONFIG_URL="https://github.com/AreaScout/dante-doom3-odroid/raw/gh-pages/config/DoomConfig.cfg"
SHADER_URL="https://github.com/AreaScout/gl2progs.git"
FFMPEG_URL="https://github.com/FFmpeg/FFmpeg.git"
GAME_DATA=$HOME"/.doom3"
CUR_DIR=$PWD

set -e

old_head=`git log | head -n1 | cut -d " " -f2`
git pull
new_head=`git log | head -n1 | cut -d " " -f2`

if [ $old_head != $new_head ]; then
	echo -e "\nNew changes available -> restarting the script ..."
	$CUR_DIR/odroid.sh
	exit
fi

export PATH=/usr/bin:$PATH
export ARCH=arm-linux-gnueabihf
if [ ! -f /usr/bin/g++-4.9 ] && [ ! -f /usr/bin/gcc-4.9 ]; then
	export CXX=g++
	export CC=gcc
else
	export CXX=g++-4.9
	export CC=gcc-4.9
fi

read -p "Do you wish to build doom3 to play video with ffmpeg support ?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    export USE_FFMPEG=1
	if [ ! -d $CUR_DIR/FFmpeg ]; then
		echo 'neo/FFmpeg' >> ../.gitignore
		git clone -b "release/3.1" $FFMPEG_URL
		cd $CUR_DIR/FFmpeg
		git reset --hard "4275b27"
		echo -e "\nBuilding FFmpeg, this can take a while"
		./configure --disable-programs --disable-vaapi --enable-pthreads
		make -j5 V=0
		if [ $? = "0" ]; then
			echo -e "\nBuild successfully finished"
		else
			echo -e "\nBuild error detected, disable FFmpeg support"
			export USE_FFMPEG=0
		fi
		cd ..
	fi
else
	export USE_FFMPEG=0
fi

scons -j5 \
	ARCH='arm' \
	BUILD='release' \
	\
	CC=$CC \
	CXX=$CXX \
	\
	NOCURL=1 \
	TARGET_ANDROID=0 \
	TARGET_D3XP=1 \
	TARGET_DEMO=0 \
	USE_FFMPEG=$USE_FFMPEG \
	\
	BASEFLAGS='-I/usr/include/arm-linux-gnueabihf -I/usr/include -I/usr/local/include -L/usr/local/lib' \
	$*
	
# Don't care if the directories still exist or not
mkdir -p $GAME_DATA/{base,demo,d3xp}

strip doom.arm gamearm-base.so gamearm-d3xp.so 

cp gamearm-base.so $GAME_DATA/base/gamearm.so
cp gamearm-d3xp.so $GAME_DATA/d3xp/gamearm.so
if [ TARGET_DEMO == 1 ]; then
	cp gamearm-demo.so $GAME_DATA/demo/gamearm.so
fi

cd $GAME_DATA/base

if [ ! -f $GAME_DATA/base/DoomConfig.cfg ]; then
	echo -e "\nDownload initial DoomConfig.cfg"
	if  ! wget --quiet $CONFIG_URL ; then
		echo "error: can't get DoomConfig.cfg"
	fi
	cp DoomConfig.cfg ../d3xp/.
	cp DoomConfig.cfg ../demo/.
	echo "Installed it in ~/.doom3/base, ~/.doom3/d3xp and ~/.doom3/demo"
fi

if [ ! -d $GAME_DATA/base/gl2progs ]; then
	echo "Install shaders in ~/.doom3/base/gl2progs"
	git clone --quiet --depth 1 $SHADER_URL
else
	cd $GAME_DATA/base/gl2progs
	git pull
fi

echo -e "\nExecutable (doom.arm) is now available in "$CUR_DIR"\nYou should now copy your *.pk4 files to "$GAME_DATA"/base, "$GAME_DATA"/d3xp or "$GAME_DATA"/demo\n" 

read -p "Do you wish to install and create desktop menu ? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

cd /usr/share/pixmaps
su -c "wget --quiet -N https://github.com/AreaScout/dante-doom3-odroid/raw/gh-pages/images/doom_3.png | cp $CUR_DIR/doom.arm /usr/local/bin/. | cat <<EOM >$LINK_PATH
[Desktop Entry]
Name=Doom3
Version=1.3
Exec=doom.arm
Comment=Doom3
Icon=doom_3
Type=Application
Terminal=false
StartupNotify=true
Encoding=UTF-8
Categories=Game;ActionGame;
EOM"

echo -e "\nFinish, have fun !"

exit
