export BINDIR=`pwd()`/binaries
mkdir -p $BINDIR
docker build - -t ffmpeg-prepare < travis/Dockerfile-prepare
docker build - -t ffmpeg-windows < travis/Dockerfile-windows
docker build - -t ffmpeg-linux < travis/Dockerfile-linux
docker run -v BINDIR:/output --name ffmpeg-win --rm -it ffmpeg-windows && docker wait ffmpeg-win
docker run -v BINDIR:/output --name ffmpeg-lin --rm -it ffmpeg-linux && docker wait ffmpeg-lin
mkdir -p natives-free/binaries/linux64 && mv $BINDIR/release/linux64/free/*.* $_
mkdir -p natives-free/binaries/windows64 && mv $BINDIR/release/windows64/free/*.* $_
mkdir -p natives-full/binaries/linux64 && mv $BINDIR/release/linux64/full/*.* $_
mkdir -p natives-full/binaries/windows64 && mv $BINDIR/release/windows64/full/*.* $_
./gradlew bintrayUpload