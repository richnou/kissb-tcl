# TCL9 Distribution V1


The TCL9 Distribution provides a TCL9 binary build including some common lbraries.

The Distribution can be downloaded as a binary archive and installed by users as described in [TCL 9 Page](./index.md#tcl9tk9-binary-archives), or as a single file kit that can be used as an augmented **tclsh** script:

    $ wget {{s3.tcl901_dist1}}/{{s3.tcl901_dist1_current}}/tcl9-dist1kit-x86_64-redhat-linux-rhel8-9.0.1-{{s3.tcl901_dist1_current}} -O tclsh
    $ chmod +x tclsh
    $ ./tclsh # Run the interpreter



## Release 250630

This release adds [CriTCL](https://andreas-kupries.github.io/critcl/){target=_blank} and [tdom](https://tdom.org){target=_blank} packages.

Included Packages:

| Library | Version | Platform | Notes |
| ----- | ---- |------ | ---- |
| TCL9 |  9.0.1 | Linux / Win64 | TCL/TK Statically compiled  |
| TK9 |  9.0.1 | Linux / Win64 | TCL/TK Statically compiled  |
| TCL Lib | 2.0 | Linux / Win64 | Crictl accelerated functions compiled for Linux |
| Tk Lib | 0.9 | Linux / Win64 | -  |
| TCL X | 8.6.3 | Linux / Win64 | Minor Fixes for TCL9 @ <https://github.com/opendesignflow/tclx> |
| TCL TLS | 2.0b1 | Linux   | Statically Linked against openssl in RHEL8 - LibreSSL 4 integration in progress - Build from SVN e19f6b3f18  |
| AwThemes | 10.4.0 | Linux   | <https://sourceforge.net/projects/tcl-awthemes>  |
| CriTCL | 3.3.1 | Linux   | <https://andreas-kupries.github.io/critcl/>  |
| tdom | 0.9.6 | Linux  / Win64  | <https://tdom.org> (HTML5 not enabled)  |

Download Links:

| Package Type   | TCL Version | Platform | Download |
|----|------|--- | -----|
| Binary Archive    | 9.0.1   | RHEL8         | {{makeS3Links(s3.tcl901_dist1_250630+"/tcl9-dist1-x86_64-redhat-linux-rhel8-9.0.1-250630.tar.gz")}} |
| Binary Archive    | 9.0.1   | Mingw32 Win64 | {{makeS3Links(s3.tcl901_dist1_250630+"/tcl9-dist1-x86_64-w64-mingw32-win64-9.0.1-250630.zip")}}  |
| Single File Kit   | 9.0.1   | RHEL8         | {{makeS3Links(s3.tcl901_dist1_250630+"/tcl9-dist1kit-x86_64-redhat-linux-rhel8-9.0.1-250630")}}  |
| Single File Kit   | 9.0.1   | Mingw32 Win64 | {{makeS3Links(s3.tcl901_dist1_250630+"/tcl9-dist1kit-x86_64-w64-mingw32-win64-9.0.1-250630.exe")}}  |


## Release 250627

This release fixes Tk integration which was broken. Users of this Kit can load Tk using `package require Tk`.

Also includes are Themes from AwThemes, for example:

~~~tcl
package require Tk

package require awbreezedark

ttk::style theme use awbreezedark
~~~

Included Packages:

| Library | Version | Platform | Notes |
| ----- | ---- |------ | ---- |
| TCL9 |  9.0.1 | Linux / Win64 | TCL/TK Statically compiled  |
| TK9 |  9.0.1 | Linux / Win64 | TCL/TK Statically compiled  |
| TCL Lib | 2.0 | Linux / Win64 | Crictl accelerated functions compiled for Linux |
| Tk Lib | 0.9 | Linux / Win64 | -  |
| TCL X | 8.6.3 | Linux / Win64 | Minor Fixes for TCL9 @ <https://github.com/opendesignflow/tclx> |
| TCL TLS | 2.0b1 | Linux   | Statically Linked against openssl in RHEL8 - LibreSSL 4 integration in progress - Build from SVN e19f6b3f18  |
| AwThemes | 10.4.0 | Linux   | <https://sourceforge.net/projects/tcl-awthemes>  |

Download Links:

| Package Type   | TCL Version | Platform | Download |
|----|------|--- | -----|
| Binary Archive    | 9.0.1   | RHEL8         | {{makeS3Links(s3.tcl901_dist1_250627+"/tcl9-dist1-x86_64-redhat-linux-rhel8-9.0.1-250627.tar.gz")}} |
| Binary Archive    | 9.0.1   | Mingw32 Win64 | {{makeS3Links(s3.tcl901_dist1_250627+"/tcl9-dist1-x86_64-w64-mingw32-win64-9.0.1-250627.zip")}}  |
| Single File Kit   | 9.0.1   | RHEL8         | {{makeS3Links(s3.tcl901_dist1_250627+"/tcl9-dist1kit-x86_64-redhat-linux-rhel8-9.0.1-250627")}}  |
| Single File Kit   | 9.0.1   | Mingw32 Win64 | {{makeS3Links(s3.tcl901_dist1_250627+"/tcl9-dist1kit-x86_64-w64-mingw32-win64-9.0.1-250627.exe")}}  |

## Release 250501

This release includes following packages:

| Library | Version | Platform | Notes |
| ----- | ---- |------ | ---- |
| TCL9 |  9.0.1 | Linux / Win64 | TCL/TK Statically compiled  |
| TK9 |  9.0.1 | Linux / Win64 | TCL/TK Statically compiled  |
| TCL Lib | 2.0 | Linux / Win64 | Crictl accelerated functions compiled for Linux |
| Tk Lib | 0.9 | Linux / Win64 |  |
| TCL X | 8.6.3 | Linux / Win64 | Minor Fixes for TCL9 @ <https://github.com/opendesignflow/tclx> |
| TCL TLS | 2.0b1 | Linux   | Statically Linked against openssl in RHEL8 - LibreSSL 4 integration in progress - Build from SVN e19f6b3f18  |

Download Links:

| Package Type   | TCL Version | Platform | Download |
|----|------|--- | -----|
| Binary Archive    | 9.0.1   | RHEL8         | {{makeS3Links(s3.tcl901_dist1_250501+"/tcl9-dist1-x86_64-redhat-linux-rhel8-9.0.1-250501.tar.gz")}} |
| Binary Archive    | 9.0.1   | Mingw32 Win64 | {{makeS3Links(s3.tcl901_dist1_250501+"/tcl9-dist1-x86_64-w64-mingw32-win64-9.0.1-250501.zip")}}  |
| Single File Kit   | 9.0.1   | RHEL8         | {{makeS3Links(s3.tcl901_dist1_250501+"/tcl9-dist1kit-x86_64-redhat-linux-rhel8-9.0.1-250501")}}  |
| Single File Kit   | 9.0.1   | Mingw32 Win64 | {{makeS3Links(s3.tcl901_dist1_250501+"/tcl9-dist1kit-x86_64-w64-mingw32-win64-9.0.1-250501.exe")}}  |
