---
title: TCL9 distributions
description:  Download optimized TCL 9 binary builds, single-file executables (TclKit), and Docker images. Includes static and shared builds for easy deployment on Linux systems.
---

# TCL 9 

## About

These Tcl 9 builds are provided to offer convenient and optimized Tcl 9 distributions for various deployment scenarios.

Our goal is to provide the TCL community with reproducable builds for various TCL packages.

Additionally, we are building a TCL distribution with some popular libraries like tcllib or tcltls, alongside some useful utilities for users to run legacy TCL scripts or write new TCL apps even faster.

## TCL Binary Archives 

TCL archives can be downloaded and extracted, they provide a folder with a TCL installation (bin/, lib/ etc..).

Static or Shared builds are available, static build can for example be used to build a single file application using a statically linked tclsh.

TCL/TK is build in a Rocky Linux 8 (Red Hat 8) environment, the binaries should thus be compatible with most user's linux distributions.

| Package | Version | Minimum OS | Download |
|----|-- |----|--------|
|TCL9 shared    |9.0.1  | RHEL8 | <https://kissb.s3.de.io.cloud.ovh.net/tcl9/9.0.1/tcl9.0.1-bin-shared.tar.gz>|
|TCL9 static    |9.0.1  | RHEL8 | <https://kissb.s3.de.io.cloud.ovh.net/tcl9/9.0.1/tcl9.0.1-bin-static.tar.gz>|
|TCL KIT        | 9.0.1 | RHEL8 | <https://kissb.s3.de.io.cloud.ovh.net/tcl9/9.0.1/tclkit-9.0.1> |

### Archive Installation 

To install a binary archive, just unpack the tarball in a folder and setup your environment:

~~~bash
$ wget https://kissb.s3.de.io.cloud.ovh.net/tcl9/9.0.1/tcl9.0.1-bin-shared.tar.gz
$ tar xvaf tcl9.0.1-bin-shared.tar.gz
$ export PATH=$(pwd)/tcl9.0.1-bin-shared/bin:$PATH 
$ export LD_LIBRARY_PATH=$(pwd)/tcl9.0.1-bin-shared/lib # Optional for static package
$ tclsh9.0 # Run TCLSH interpreter
~~~

By default the **tclsh** interpreter is not present in the **bin/** folder, you can add it if you want to make tclsh by default tclsh9:

~~~bash
$ ln -s tcl9.0.1-bin-shared/bin/tclsh9.0 tcl9.0.1-bin-shared/bin/tlsh
~~~

## TCL9 Single File (TclKit)

An alternative way to quickly use TCL9 is to run a single file application which contains the whole TCL environment. 

The TCL Kit is a statically build TCL interpreter, it can be used to produce new single file applications with the user's application or libraries: 

~~~bash
$ wget https://kissb.s3.de.io.cloud.ovh.net/tcl9/9.0.1/tclkit-9.0.1
$ chmod +x tclkit-9.0.1
$ ./tclkit-9.0.1 # Run TCLSH interpreter
~~~


## TCL Docker Image 

Our TCL Build system uses docker as build environment and also provides runtime images. 
The TCL archives as extracted from the docker images.

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