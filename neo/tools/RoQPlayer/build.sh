#!/bin/bash
SAMPLE_URL="https://samples.mplayerhq.hu/game-formats/idroq/jk02.roq"

echo -e "\nBuilding RoQplayer ..."
CFLAGS="-L/usr/local/lib -L/usr/lib -I../../FFmpeg ../../FFmpeg/libavformat/libavformat.a ../../FFmpeg/libavcodec/libavcodec.a ../../FFmpeg/libavutil/libavutil.a ../../FFmpeg/libswscale/libswscale.a ../../FFmpeg/libswresample/libswresample.a -lz -lbz2 -llzma -lGLESv1_CM -lX11 -lpthread -lm"
gcc RoQPlayer.c -o RoQPlayer $CFLAGS

echo -e "\nDownload sample video"
wget $SAMPLE_URL

if [ $? = "0" ]; then
	echo -e "\nPlaying sample"
	DISPLAY=:0.0 ./RoQPlayer jk02.roq
else
	echo -e "\nDownload failed\nUsage: RoQPlayer some_sample.roq"
fi
