rmdir /S /Q %~dp0\output
mkdir %~dp0\output

docker build - -t ffmpeg-prepare < Dockerfile-prepare
docker build - -t ffmpeg-windows < Dockerfile-windows
docker build - -t ffmpeg-linux < Dockerfile-linux

docker run -v %~dp0\output:/output --name ffmpeg-win --rm -it ffmpeg-windows
docker run -v %~dp0\output:/output --name ffmpeg-lin --rm -it ffmpeg-linux
   
   
