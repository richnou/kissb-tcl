---
title: TCL9 distributions
description:  Download optimized TCL 9 binary builds, single-file executables (TclKit), and Docker images. Includes static and shared builds for easy deployment on Linux systems.
---

# TCL 9 

## About

These Tcl 9 builds are provided to offer convenient and optimized Tcl/Tk 9 distributions for various deployment scenarios.

Our goal is to provide the TCL community a repository with reproducable builds for various TCL packages.

Additionally, we are building a TCL distribution with some popular libraries like tcllib or tcltls, alongside some useful utilities for users to run legacy TCL scripts or write new TCL apps even faster.

The Packages provided are hosted in an S3 Object storage bucket hosted in Europe by OVH.

## TCL9/Tk9 Binary Archives 

TCL archives can be downloaded and extracted, they provide a folder with a TCL installation (bin/, lib/ etc..).

Static or Shared builds are available, static build can for example be used to build a single file application using a statically linked tclsh.

TCL/TK is build in a Rocky Linux 8 (Red Hat 8) environment, the binaries should thus be compatible with most user's linux distributions.

### TCL9 Builds

| Package | Version | Release | Platform | Download |
|----|----|------| ------|--------|
|TCL9 shared    | 9.0.1  | 250501 | RHEL8 |          <{{s3.tcl901}}/250501/tcl9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz> |
|TCL9 static    | 9.0.1  | 250501 | RHEL8 |          <{{s3.tcl901}}/250501/tcl9-x86_64-redhat-linux-rhel8-static-9.0.1.tar.gz> |
|TCL9 shared    | 9.0.1  | 250501 | Mingw32 Win64 |  <{{s3.tcl901}}/250501/tcl9-x86_64-w64-mingw32-win64-shared-9.0.1.zip> |
|TCL9 static    | 9.0.1  | 250501 | Mingw32 Win64 |  <{{s3.tcl901}}/250501/tcl9-x86_64-w64-mingw32-win64-static-9.0.1.zip> |

### Tk9 Builds

TK9 Archives are build for Linux and Windows as for Tcl9, in shared and static variants. 

!!! warning 
    When using shared variants, make sure the the TCL9 installation is available in and setup properly (see archive installation).

| Package | Version | Release | Platform | Download |
|----|----|------| ------|--------|
|TK9 shared    | 9.0.1  | 250501 | RHEL8 |          <{{s3.tcl901}}/250501/tk9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz> |
|TK9 static    | 9.0.1  | 250501 | RHEL8 |          <{{s3.tcl901}}/250501/tk9-x86_64-redhat-linux-rhel8-static-9.0.1.tar.gz> |
|TK9 shared    | 9.0.1  | 250501 | Mingw32 Win64 |  <{{s3.tcl901}}/250501/tk9-x86_64-w64-mingw32-win64-shared-9.0.1.zip> |
|TK9 static    | 9.0.1  | 250501 | Mingw32 Win64 |  <{{s3.tcl901}}/250501/tk9-x86_64-w64-mingw32-win64-static-9.0.1.zip> |

### TCL9 Archive Installation 

To install a binary archive, just unpack the tarball in a folder and setup your environment:

~~~bash
$ wget {{s3.tcl901_current}}/tcl9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz
$ tar xvaf tcl9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz
$ export PATH=$(pwd)/tcl9-x86_64-redhat-linux-rhel8-shared/bin:$PATH 
$ export LD_LIBRARY_PATH=$(pwd)/tcl9-x86_64-redhat-linux-rhel8-shared/lib # Optional for static package
$ tclsh9.0 # Run TCLSH interpreter
~~~

By default the **tclsh** interpreter is not present in the **bin/** folder, you can add it if you want to make tclsh by default tclsh9:

~~~bash
$ ln -s  tcl9-x86_64-redhat-linux-rhel8-shared/bin/tclsh9.0  tcl9-x86_64-redhat-linux-rhel8-shared/bin/tclsh
~~~

If you are using windows, download a windows archive and run the **tclsh90** or **tclsh90s** interpreters.
For example with a static archive:

~~~powershell
PS D:\> wget {{s3.tcl901_current}}/tk9-x86_64-w64-mingw32-win64-static-9.0.1.zip
PS D:\> Expand-Archive -Path tk9-x86_64-w64-mingw32-win64-shared-9.0.1.zip -DestinationPath .
~~~

### TK9 Archive Installation

To use TK9 archives, make sure that TCL9 is installed - in case you are using a shared archive, don't forget to set the **LD_LIBRARY_PATH** environment variable as described previously.

To easily get started, you can use a static build, however if TCL9 is not installed some standard libraries like Itcl won't be available:

~~~bash
$ wget {{s3.tcl901_current}}/tk9-x86_64-redhat-linux-rhel8-static-9.0.1.tar.gz
$ tar xvaf tk9-x86_64-redhat-linux-rhel8-static-9.0.1.tar.gz
$ export PATH=$(pwd)/tk9-x86_64-redhat-linux-rhel8-static-9.0.1/bin:$PATH 
$ export LD_LIBRARY_PATH=$(pwd)/tk9-x86_64-redhat-linux-rhel8-static-9.0.1/lib # Optional for static package
$ wish9.0 # Run Wish interpreter
~~~

On windows, the same applies, note that for static builds the whish interpreter is called **wish90s.exe** instead of **wish90.exe**:

~~~powershell
PS D:\> wget {{s3.tcl901_current}}/tk9-x86_64-w64-mingw32-win64-static-9.0.1.zip
PS D:\> Expand-Archive -Path tk9-x86_64-w64-mingw32-win64-static-9.0.1.zip -DestinationPath .
PS D:\> tk9-x86_64-w64-mingw32-win64-static-9.0.1\bin\wish90s.exe
~~~

## TCL9/Tk9 Single File (TclKit)

An alternative way to quickly run TCL9/Tk9 is to run a single file application which contains the whole TCL environment.

The TCL Kit is a statically build TCL interpreter, it can be used to produce new single file applications with the user's application or libraries.

For TK kits, two types of TK Kits are build: 

- Light kits marked **-light** are only produced using wish static and include the standard tcl library
- Standard kits (not light) are produced with wish static and include tcl library extra libraries like itcl

Users who want to create their own build using only the basic Tk distribution can use the light kit.

The following kits are available: 

| Package | Version | Release | Platform | Download |
|----|----|------| ------|--------|
|TCL9 KIT        | 9.0.1  | 250501 | RHEL8 |         <{{s3.tcl901_current}}/tclkit9-x86_64-redhat-linux-rhel8-9.0.1> |
|TCL9 KIT        | 9.0.1  | 250501 | Mingw32 Win64 |  <{{s3.tcl901_current}}/tclkit9-x86_64-w64-mingw32-win64-9.0.1.exe> |
|TK9 KIT       | 9.0.1  | 250501 | RHEL8 |         <{{s3.tcl901_current}}/tkkit9-x86_64-redhat-linux-rhel8-9.0.1> |
|TK9 KIT Light | 9.0.1  | 250501 | RHEL8 |         <{{s3.tcl901_current}}/tkkit9-x86_64-redhat-linux-rhel8-light-9.0.1> |
|TK9 KIT       | 9.0.1  | 250501 | Mingw32 Win64 |  <{{s3.tcl901_current}}/tkkit9-x86_64-w64-mingw32-win64-9.0.1.exe> |
|TK9 KIT Light | 9.0.1  | 250501 | Mingw32 Win64 |  <{{s3.tcl901_current}}/tkkit9-x86_64-w64-mingw32-win64-light-9.0.1.exe> |

For example on a linux system:

~~~bash
$ wget {{s3.tcl901_current}}/tclkit9-x86_64-redhat-linux-rhel8-9.0.1
$ chmod +x tclkit9-x86_64-redhat-linux-rhel8-9.0.1
$ ./tclkit9-x86_64-redhat-linux-rhel8-9.0.1 # Run TCLSH interpreter

# If you have hadded ~/.local/bin in your path, you can also name the kit "tclsh9.0"
$ wget {{s3.tcl901_current}}/tclkit9-x86_64-redhat-linux-rhel8-9.0.1 -O ~/.local/bin/tclsh9.0
$ chmod +x ~/.local/bin/tclsh9.0
$ tclsh9.0
~~~


## TCL Docker Image 

Our TCL Build system uses docker as build environment and also provides runtime images. 

For TCL scripts, users can easily run using the tclsh images.

| Image | TCL Version | Docker Hub Link |
|----|---------------|-------------------|
|rleys/kissb-tclsh9-static:9.0.1|9.0.1| <https://hub.docker.com/repository/docker/rleys/kissb-tclsh9-static/general> |
|rleys/kissb-tclsh9-shared:9.0.1|9.0.1| <https://hub.docker.com/repository/docker/rleys/kissb-tclsh9-static/general> |


**Note that the image runs script from the /app folder, therefore users must map the local folder containing the tcl scripts to the container's /app directory.**

### Interactive Example 

To quickly spin a tclsh interpreter, just run the image in interactive mode with pty allocation:

~~~bash
$ docker run -it -v .:/app rleys/kissb-tclsh9-static:9.0.1  # Run script
~~~

### Script Example 

For example to run the following hello world script:

~~~tcl
puts "Hello from tcl version [info tclversion]"
~~~

~~~bash
$ docker run -v .:/app rleys/kissb-tclsh9-static:9.0.1 helloworld.tcl # Run script
~~~


### TCL installation path

TCL is installed in the /install-tcl folder in the image, users can copy that folder out of the image if needed to extract the binaries or replace some libraries

## Feedback / Bugs 

For feedback, requests and issues please use the Github issue tracker 

<https://github.com/richnou/kissb-tcl>

## Licensing

The scripts and binaries offered by this repository are released under the Apache 2 License, which is compatible with the original BSD Like Tcl/Tk License.

The original licenses for each package still apply, and are summarized in the repository license file:

<https://github.com/richnou/kissb-tcl/blob/main/LICENSE>