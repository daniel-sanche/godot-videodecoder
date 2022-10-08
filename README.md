# Godot Video Decoder

GDNative Video Decoder library for [Godot Engine](https://godotengine.org),
using the [FFmpeg](https://ffmpeg.org) library for codecs.

**A GSoC 2018 Project**

This project is set up so that a game developer can build x11, windows and osx plugin libraries with a single script. The build enviroment has been dockerized for portability. Building has been tested on linux and windows 10 pro with WSL2.

The most difficult part of building the plugin libraries is extracting the macos sdk from the XCode download since it [can't be distributed directly](https://www.apple.com/legal/sla/docs/xcode.pdf).

**Media Support**

The current dockerized ffmpeg build supports VP9 decoding only. Support for other decoders could be added, PRs are welcome.
Patent encumbered codecs like [h264/h265](https://www.mpegla.com/wp-content/uploads/avcweb.pdf) will always be missing in the automatic builds due to copyright issues and the [cost of distributing pre-built binaries](https://jina-liu.medium.com/settle-your-questions-about-h-264-license-cost-once-and-for-all-hopefully-a058c2149256#5e65).

## Instructions to build with docker

1. Add the repository as a submodule or clone the repository somewhere and initialize submodules.
   ```
   git submodule add https://github.com/jamie-pate/godot-videodecoder.git contrib/godot-videodecoder
   git submodule update --init --recursive
   ```
   or
   ```
   git clone https://github.com/jamie-pate/godot-videodecoder.git godot-videodecoder
   cd godot-videodecoder
   git submodule update --init --recursive
   ```
1. Copy the `build_gdnative.sh.example` to your project and adjust the paths inside.
   - `cp contrib/godot-videodecoder/build_gdnative.sh.example ./build_gdnative.sh`, vi `./build_gdnative.sh`
   - `chmod +x ./build_gdnative.sh` if needed
1. [Install docker](https://docs.docker.com/get-docker/)
1. Extract MacOSX sdk from the XCode
   - For osx you must download XCode 7 and extract/generate MacOSX10.11.sdk.tar.gz and copy it to ./darwin_sdk/ by following these instructions: https://github.com/tpoechtrager/osxcross#packaging-the-sdk
     - NOTE: for darwin15 support use: https://developer.apple.com/download/more/?name=Xcode%207.3.1
   - To use a different MacOSX*.*.sdk.tar.gz sdk set the XCODE_SDK environment variable. <!-- TODO: test this -->
   - e.g. `XCODE_SDK=$PWD/darwin_sdk/MacOSX10.15.sdk.tar.gz ./build_gdnative.sh`
1. run `build_gdnative.sh` (Be sure to [add your user to the `docker` group](https://docs.docker.com/engine/install/linux-postinstall/) or you will have to run as `sudo` (which is bad))
   - you can set the platforms you want to build using the `PLATFORMS` env var: `export PLATFORMS="x11 x11_32"; build_gdnative.sh`
1. after the script is complete, you should see a set of dynamic libraries output to `target/$platform`
   

## Adding GDNative Library to your Project
1. Compile the dynaic libraries for the platforms you are interested in using the steps above
1. copy the dynamic libraries somewhere in your project (eg. `addons/videodecoder/x11`)
1. create a file called `videodecoder.gdnlib` inside your godot project with the following content (with the paths pointing to where the files exist in your project):
   ```
   [general]

   singleton=true
   load_once=true
   symbol_prefix="godot_"
   reloadable=false

   [entry]

   OSX.64="res://addons/videodecoder/osx/libgdnative_videodecoder.dylib"
   Windows.64="res://addons/videodecoder/win64/libgdnative_videodecoder.dll"
   Windows.32="res://addons/videodecoder/win32/libgdnative_videodecoder.dll"
   X11.64="res://addons/videodecoder/x11/libgdnative_videodecoder.so"
   X11.32="res://addons/videodecoder/x11_32/libgdnative_videodecoder.so"


   [dependencies]

   OSX.64=[ "res://addons/videodecoder/osx/libavformat.58.dylib", "res://addons/videodecoder/osx/libavutil.56.dylib", "res://addons/videodecoder/osx/libavcodec.58.dylib", "res://addons/videodecoder/osx/libswscale.5.dylib", "res://addons/videodecoder/osx/libswresample.3.dylib" ]
   Windows.64=[ "res://addons/videodecoder/win64/avformat-58.dll", "res://addons/videodecoder/win64/avutil-56.dll", "res://addons/videodecoder/win64/avcodec-58.dll", "res://addons/videodecoder/win64/swscale-5.dll", "res://addons/videodecoder/win64/swresample-3.dll", "res://addons/videodecoder/win64/libwinpthread-1.dll" ]
   Windows.32=[ "res://addons/videodecoder/win32/avformat-58.dll", "res://addons/videodecoder/win32/avutil-56.dll", "res://addons/videodecoder/win32/avcodec-58.dll", "res://addons/videodecoder/win64/swscale-5.dll", "res://addons/videodecoder/win32/swresample-3.dll", "res://addons/videodecoder/win32/libwinpthread-1.dll" ]
   X11.64=[ "res://addons/videodecoder/x11/libavformat.so.58", "res://addons/videodecoder/x11/libavutil.so.56", "res://addons/videodecoder/x11/libavcodec.so.58", "res://addons/videodecoder/x11/libswscale.so.5", "res://addons/videodecoder/x11/libswresample.so.3" ]
   X11.32=[ "res://addons/videodecoder/x11_32/libavformat.so.58", "res://addons/videodecoder/x11_32/libavutil.so.56", "res://addons/videodecoder/x11_32/libavcodec.so.58", "res://addons/videodecoder/x11_32/libswscale.so.5", "res://addons/videodecoder/x11_32/libswresample.so.3" ]
   ```
   
## Using with the Godot VideoPlayer Node
- Once the GDNative library has been set up, the following code can be used to set up a `VideoPlayer` node that will play a VP9 video:
  ```
  var stream = VideoStreamGDNative.new()
  stream.set_file("res://video.webm")
  
  var videoplayer = VideoPlayer.new()
  videoplayer.stream = stream
  add_child(videoplayer)
  videoplayer.play()
  ```
