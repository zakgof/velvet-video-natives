FROM ubuntu:18.04

RUN apt-get -y update && apt-get install -y apt-utils
RUN apt-get install -y --fix-missing mc mingw-w64 yasm nasm gcc make cmake git pkg-config wget
    
###########

ENV BASE /FFmpeg
RUN mkdir $BASE
WORKDIR $BASE    

RUN git clone https://github.com/FFmpeg/FFmpeg.git && cd FFmpeg && git checkout tags/n4.1.4
RUN git clone https://chromium.googlesource.com/webm/libvpx && cd libvpx && git checkout tags/v1.8.1
RUN git clone https://github.com/mirror/x264.git && cp -r $BASE/x264 $BASE/x264linux
RUN git clone https://github.com/videolan/x265.git && cd x265 && git checkout tags/3.1.1 && cp -r $BASE/x265 $BASE/x265linux
RUN git clone https://aomedia.googlesource.com/aom && cd aom && git checkout tags/v1.0.0 && cp -r $BASE/aom $BASE/aomlinux
RUN wget -nv http://downloads.xiph.org/releases/ogg/libogg-1.3.0.tar.gz && tar xzvf libogg-1.3.0.tar.gz
RUN wget -nv http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz && tar xzvf libvorbis-1.3.3.tar.gz

ENV REL $BASE/release
ENV FREE_CONFIG --disable-all --enable-libvorbis --enable-libvpx --enable-libaom --enable-decoder=vp8,vp9,libaom_av1 --enable-encoder=libvpx_vp8,libvpx_vp9,libaom_av1 --enable-muxer=ogg,webm,matroska --enable-demuxer=ogg,webm,matroska
ENV FULL_CONFIG --enable-gpl --enable-libx264 --enable-libx265 --enable-libvpx --enable-libvorbis --enable-libaom
ENV COMMON_CONFIG="--disable-static --enable-shared --disable-doc --enable-pic \
   --disable-programs \
   --disable-postproc --disable-avdevice --disable-swresample --disable-avfilter \
   --enable-version3 --enable-avcodec --enable-avformat --enable-swscale \
   --pkg-config-flags=--static \
   --pkg-config=pkg-config"

###########

ENV DEST $BASE/ffmpeg-build-windows
ENV PREFIX --prefix=$DEST
ENV HOST --host=x86_64-w64-mingw32
ENV CROSSPREFIX --cross-prefix=x86_64-w64-mingw32- 
ENV PKG_CONFIG_PATH $DEST/lib/pkgconfig

RUN cd libogg-1.3.0    && ./configure $PREFIX $HOST --disable-shared --enable-static && make && make install
RUN cd libvorbis-1.3.3 && ./configure $PREFIX $HOST --disable-shared --enable-static && make && make install
RUN mkdir -p vpx-build-windows && cd vpx-build-windows && CROSS=x86_64-w64-mingw32- ../libvpx/configure --target=x86_64-win64-gcc $PREFIX \
 --enable-static --disable-shared --disable-debug --enable-experimental --enable-static-msvcrt \
 --disable-examples --disable-tools --disable-docs --disable-unit-tests \
 --enable-pic --enable-small \
 && make && make install

RUN cd x264 && ./configure $HOST $PREFIX $CROSSPREFIX --disable-cli --enable-static --enable-strip --enable-pic --disable-lavf --disable-swscale && make && make install && make clean

RUN cd x265/build/linux && \
echo "SET(CMAKE_SYSTEM_NAME Windows)" >> build.cmake && \
echo "SET(CMAKE_C_COMPILER   x86_64-w64-mingw32-gcc) " >> build.cmake && \
echo "SET(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++) " >> build.cmake && \
echo "SET(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres) " >> build.cmake && \
echo "SET(CMAKE_RANLIB x86_64-w64-mingw32-ranlib) " >> build.cmake && \
echo "SET(CMAKE_ASM_YASM_COMPILER yasm) " >> build.cmake && \
echo "option(ENABLE_SHARED OFF) " >> build.cmake && \
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$DEST -DENABLE_SHARED=off -DCMAKE_TOOLCHAIN_FILE=build.cmake ../../source
RUN cd x265/build/linux && make && make install && make clean

RUN cd aom/build && cmake $BASE/aom -DENABLE_TESTS=0 -DENABLE_DOCS=0 -DCMAKE_INSTALL_PREFIX=$DEST -DCMAKE_TOOLCHAIN_FILE=$BASE/aom/build/cmake/toolchains/x86_64-mingw-gcc.cmake && make && make install

ENV WINDOWS_CONFIG --extra-cflags=-I$DEST/include --extra-ldflags=-L$DEST/lib --arch=x86_64 --target-os=mingw32 $CROSSPREFIX $PREFIX --disable-dxva2

RUN mkdir -p $REL/windows64/free && cd FFmpeg && ./configure $FREE_CONFIG $COMMON_CONFIG $WINDOWS_CONFIG && make && make install && cp $DEST/bin/*.dll $REL/windows64/free
RUN mkdir -p $REL/windows64/full && cd FFmpeg && ./configure $FULL_CONFIG $COMMON_CONFIG $WINDOWS_CONFIG && make && make install && cp $DEST/bin/*.dll $REL/windows64/full

###########

ENV DEST $BASE/ffmpeg-build-linux
ENV PREFIX --prefix=$DEST
ENV PKG_CONFIG_PATH $DEST/lib/pkgconfig
ENV LINUX_CONFIG --extra-cflags=-I$DEST/include --extra-ldflags=-L$DEST/lib $PREFIX

RUN cd libogg-1.3.0    && ./configure $PREFIX --disable-shared --enable-static && make clean && make && make install
RUN cd libvorbis-1.3.3 && ./configure $PREFIX --disable-shared --enable-static && make clean && make && make install
RUN mkdir -p vpx-build-linux && cd vpx-build-linux && ../libvpx/configure $PREFIX \
 --enable-static --disable-shared --disable-debug --enable-experimental \
 --disable-examples --disable-tools --disable-docs --disable-unit-tests \
 --enable-pic --enable-small \
 && make && make install

RUN cd x264linux && ./configure $PREFIX --disable-cli --enable-static --enable-pic --enable-strip --disable-lavf --disable-swscale && make && make install
RUN cd x265linux/build/linux && cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$DEST -DENABLE_SHARED=off ../../source && make && make install
RUN cd aomlinux/build && cmake -G "Unix Makefiles" -DENABLE_TESTS=0 -DENABLE_DOCS=0 -DCMAKE_INSTALL_PREFIX=$DEST .. && make && make install

RUN mkdir -p $REL/linux64/free && cd FFmpeg && ./configure $FREE_CONFIG $COMMON_CONFIG $LINUX_CONFIG  && make && make install && cp $DEST/lib/*.so $REL/linux64/free
RUN mkdir -p $REL/linux64/full && cd FFmpeg && ./configure $FULL_CONFIG $COMMON_CONFIG $LINUX_CONFIG --extra-libs=-lpthread && make && make install && cp $DEST/lib/*.so $REL/linux64/full

ENTRYPOINT cp -r $REL /output