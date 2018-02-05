#!/bin/bash

# The MIT License (MIT)
 
# Copyright (c) 2018 Marlon Tornes & JMCJSoftware, Inc <marlon@jmjcsoftware.com>
 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


## Script to fully install ffmpeg WITHOUT HEVC_QSV support.

echo "Checking for root access..."
###################################
if [ "$EUID" -ne 0 ]
  then echo "This is script must run only as root, not even with sudoers will work ok."
  exit
fi
###################################

echo "Updating system"
yum update -y

echo "Installing dependencies"
####################################################################
yum install -y install git wget hg install epel-release

curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
yum -y install nodejs
yum -y install gcc-c++ make

#####################################################################

echo "Configuring installation to /opt/trtmp"
################################################
mkdir /opt/trtmp
mkdir /opt/trtmp/ffsources
mkdir /opt/trtmp/ffbuild

cd /opt/trtmp

echo 'Setting $USER in video group'
usermod -a -G video $USER

yum install -y install autoconf automake bzip2 cmake freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel

cd /opt/trtmp

echo "Compiling ffpmeg"

#nasm
cd /opt/trtmp/ffsources
curl -O -L http://www.nasm.us/pub/nasm/releasebuilds/2.13.02/nasm-2.13.02.tar.bz2
tar xjvf nasm-2.13.02.tar.bz2
cd nasm-2.13.02
./autogen.sh
./configure --prefix="/opt/trtmp/ffbuild" --bindir="/bin"
make
make install

#yasm
cd /opt/trtmp/ffsources
curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
tar xzvf yasm-1.3.0.tar.gz
cd yasm-1.3.0
./configure --prefix="/opt/trtmp/ffbuild" --bindir="/bin"
make
make install

#avc
cd /opt/trtmp/ffsources
git clone --depth 1 http://git.videolan.org/git/x264
cd x264
PKG_CONFIG_PATH="/opt/trtmp/ffbuild/lib/pkgconfig" ./configure --prefix="/opt/trtmp/ffbuild" --bindir="/opt/ffmpeg_qsv/bin/" --enable-static
make
make install

#hevc
cd /opt/trtmp/ffsources
hg clone https://bitbucket.org/multicoreware/x265
cd /opt/trtmp/ffsources/x265/build/linux
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/opt/trtmp/ffbuild" -DENABLE_SHARED:bool=off ../../source
make
make install

#libfdk_aac
cd /opt/trtmp/ffsources
git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix="/opt/trtmp/ffbuild" --disable-shared
make
make install

#libmp3lame
cd /opt/trtmp/ffsources
curl -O -L http://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
tar xzvf lame-3.100.tar.gz
cd lame-3.100
./configure --prefix="/opt/trtmp/ffbuild" --bindir="/opt/ffmpeg_qsv/bin/" --disable-shared --enable-nasm
make
make install

#libopus
cd /opt/trtmp/ffsources
curl -O -L https://archive.mozilla.org/pub/opus/opus-1.2.1.tar.gz
tar xzvf opus-1.2.1.tar.gz
cd opus-1.2.1
./configure --prefix="/opt/trtmp/ffbuild" --disable-shared
make
make install

#libogg
cd /opt/trtmp/ffsources
curl -O -L http://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.gz
tar xzvf libogg-1.3.3.tar.gz
cd libogg-1.3.3
./configure --prefix="/opt/trtmp/ffbuild" --disable-shared
make
make install

#libvorbis
cd /opt/trtmp/ffsources
curl -O -L http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.gz
tar xzvf libvorbis-1.3.5.tar.gz
cd libvorbis-1.3.5
./configure --prefix="/opt/trtmp/ffbuild" --with-ogg="/opt/trtmp/ffbuild" --disable-shared
make
make install

#libvpx
cd /opt/trtmp/ffsources
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx
./configure --prefix="/opt/trtmp/ffbuild" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm
make
make install

#Compile

cd /opt/trtmp/ffsources

curl -O -L https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg

PATH="/opt/ffmpeg_qsv/bin:$PATH" PKG_CONFIG_PATH="/opt/trtmp/ffbuild/lib/pkgconfig" ./configure   --prefix="/opt/trtmp/ffbuild"   --pkg-config-flags="--static"   --extra-cflags="-I/opt/trtmp/ffbuild/include"   --extra-ldflags="-L/opt/trtmp/ffbuild/lib" --extra-libs=-lpthread   --extra-libs=-lm   --bindir="/opt/ffmpeg_qsv/bin"   --enable-gpl   --enable-libfdk_aac   --enable-libfreetype   --enable-libmp3lame   --enable-libopus   --enable-libvorbis   --enable-libvpx   --enable-libx264   --enable-libx265   --enable-nonfree
make
make install
hash -r

rm -Rf /opt/trtmp
