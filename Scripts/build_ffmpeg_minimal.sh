#!/usr/bin/env bash
set -euo pipefail

FFMPEG_VERSION="6.1.1"
PREFIX="$(pwd)/ThirdParty/ffmpeg"
BUILD_DIR="$(mktemp -d /tmp/bql-ffmpeg.XXXX)"

mkdir -p "$PREFIX/bin"

pushd "$BUILD_DIR"
curl -LO "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz"
tar xf "ffmpeg-$FFMPEG_VERSION.tar.xz"
cd "ffmpeg-$FFMPEG_VERSION"

./configure \
  --prefix="$PREFIX" \
  --disable-everything \
  --enable-ffmpeg \
  --enable-avcodec \
  --enable-avformat \
  --enable-avutil \
  --enable-swresample \
  --enable-swscale \
  --enable-parser=h264,hevc,vp9,opus,vorbis,aac,flac,av1,mpeg4video,mpegvideo \
  --enable-decoder=h264,hevc,vp9,vp8,av1,aac,mp3,vorbis,opus,flac,mpeg4,mpeg1video,mpeg2video \
  --enable-demuxer=mov,mp4,m4a,matroska,avi,webm,flv,mpegts,mpegps \
  --enable-protocol=file \
  --enable-static \
  --disable-shared \
  --disable-doc \
  --disable-debug \
  --enable-small

make -j"$(sysctl -n hw.ncpu)"
make install

popd
rm -rf "$BUILD_DIR"

echo "ffmpeg built at $PREFIX/bin/ffmpeg"
echo "Copy it into Sources/VideoPreview/Resources/ffmpeg/ffmpeg and re-run swift build."
