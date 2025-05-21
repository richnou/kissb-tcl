# TCL Builds

This repository provides scripts to build TCL 8.6 and TCL 9 with TCL Kits, and some commonly required libraries.

TCL9 builds are generated from the tcl9 folder, and TCL 8.6 from the tclkit folder.

**As of today, Documentation is focussing on the TCL9 builds, TCL 8.6 will follow**

## Building TCL9

Go to the tcl9 folder, and use the KISSB wrapper script to download and run build targets:

- run ./kissbw without arguments to get the targets listed
- run ./kissbw tcl9.build.all to build all tcl9 packages for linux and windows using mingw
