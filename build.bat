SET BINDIR=%~dp0%script\output
rd /s /q %BINDIR%
mkdir %BINDIR%

docker stop ffmpeg-lin ffmpeg-win
docker rm ffmpeg-lin ffmpeg-win

docker build - -t ffmpeg-prepare < script\Dockerfile-prepare
docker build - -t ffmpeg-windows < script\Dockerfile-windows
docker build - -t ffmpeg-linux   < script\Dockerfile-linux

docker run -v %BINDIR%:/output --name ffmpeg-win --rm -it ffmpeg-windows
pause

docker run -v %BINDIR%:/output --name ffmpeg-lin --rm -it ffmpeg-linux && timeout /t 5 && docker wait ffmpeg-lin
pause

rd /s /q natives-free\velvet-video-natives
rd /s /q natives-free\src
rd /s /q natives-full\velvet-video-natives
rd /s /q natives-full\src

mkdir natives-free\velvet-video-natives\linux64   && copy %BINDIR%\release\linux64\free\*.*   natives-free\velvet-video-natives\linux64
mkdir natives-free\velvet-video-natives\windows64 && copy %BINDIR%\release\windows64\free\*.* natives-free\velvet-video-natives\windows64
mkdir natives-full\velvet-video-natives\linux64   && copy %BINDIR%\release\linux64\full\*.*   natives-full\velvet-video-natives\linux64
mkdir natives-full\velvet-video-natives\windows64 && copy %BINDIR%\release\windows64\full\*.* natives-full\velvet-video-natives\windows64

mkdir natives-free\src && xcopy %BINDIR%\sources\*.* natives-free\src /E /Q
mkdir natives-full\src && xcopy %BINDIR%\sources\*.* natives-full\src /E /Q

rd /s /q natives-free\src\aom\.git
rd /s /q natives-free\src\aom\examples
rd /s /q natives-free\src\aom\test
rd /s /q natives-free\src\aom\tools
rd /s /q natives-free\src\FFmpeg\.git
rd /s /q natives-free\src\FFmpeg\doc
rd /s /q natives-free\src\FFmpeg\tests
rd /s /q natives-free\src\FFmpeg\tools
rd /s /q natives-free\src\FFmpeg\presets
rd /s /q natives-free\src\FFmpeg\libpostproc
rd /s /q natives-free\src\FFmpeg\libavdevice
rd /s /q natives-free\src\FFmpeg\libavcodec/mips
rd /s /q natives-free\src\libvpx\.git
rd /s /q natives-free\src\libvpx\examples
rd /s /q natives-free\src\libvpx\test
rd /s /q natives-free\src\libvpx\tools
rd /s /q natives-free\src\openh264
rd /s /q natives-free\src\x264
rd /s /q natives-free\src\x265

rd /s /q natives-full\src\aom\.git
rd /s /q natives-full\src\aom\examples
rd /s /q natives-full\src\aom\test
rd /s /q natives-full\src\aom\tools
rd /s /q natives-full\src\FFmpeg\.git
rd /s /q natives-full\src\FFmpeg\doc
rd /s /q natives-full\src\FFmpeg\tests
rd /s /q natives-full\src\FFmpeg\tools
rd /s /q natives-full\src\FFmpeg\presets
rd /s /q natives-full\src\FFmpeg\libpostproc
rd /s /q natives-full\src\FFmpeg\libavdevice
rd /s /q natives-full\src\FFmpeg\libavcodec/mips
rd /s /q natives-full\src\libvpx\.git
rd /s /q natives-full\src\libvpx\examples
rd /s /q natives-full\src\libvpx\test
rd /s /q natives-full\src\libvpx\tools
rd /s /q natives-full\src\openh264\.git
rd /s /q natives-full\src\openh264\docs
rd /s /q natives-full\src\openh264\test
rd /s /q natives-full\src\openh264\testbin
rd /s /q natives-full\src\openh264\autotest
rd /s /q natives-full\src\openh264\res
rd /s /q natives-full\src\x264\.git
rd /s /q natives-full\src\x264\doc
rd /s /q natives-full\src\x264\tools
rd /s /q natives-full\src\x265\.git
rd /s /q natives-full\src\x265\doc
rd /s /q natives-full\src\x265\source\profile
rd /s /q natives-full\src\x265\source\test

gradlew clean --no-daemon jar