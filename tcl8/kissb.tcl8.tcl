# SPDX-FileCopyrightText: 2025 KISSB-TCL
#
# SPDX-License-Identifier: Apache-2.0

# Parameters and helpers for building
source ../common/build.params.tcl

package require kissb.tclkit

# Set for TCL8
vars.set tcl.version.major 8.6
vars.set tcl.version.minor 8.6.16

# Prepare builder image
builder.container.image.build ../common/Dockerfile.builder rleys/kissb-tcl9builder:latest -quiet



@ {tcl8.build.all "Build TCL for Linux/Windows (MinGW)"} {

    # Unix Build
    > tcl.build.generic

    # Windows Build
    vars.set build.host         x86_64-w64-mingw32
    vars.set build.cc           ${::build.host}-gcc
    vars.set build.os           win64
    vars.set build.targetString ${::build.host}-${::build.os}

    > tcl.build.generic

    vars.revert build.host build.cc build.os build.targetString
}

@ {tcl8.package.all "Creates TCL8 Tarballs"} {
    > tcl8.build.all

    > tcl.package.generic
}

@ {tk8.build.all "Build TK for Linux/Windows (MinGW)"} {

    # Unix Build
    > tk.build.generic

    # Windows Build
    vars.set build.host         x86_64-w64-mingw32
    vars.set build.cc           ${::build.host}-gcc
    vars.set build.os           win64
    vars.set build.targetString ${::build.host}-${::build.os}

    > tk.build.generic

    vars.revert build.host build.cc build.os build.targetString
}

@ {tk8.package.all "Creates TCL8 Tarballs"} {
    > tk8.build.all

    > tk.package.generic
}

@ {tclkit.all "Creates all config TCL Kits"} {


    set TCL_CONFS {
        8.6.16_tk       8.6.16 {tk tcllib tclx tdom} {}
        8.6.16_notk     8.6.16 {tcllib tclx tdom} {}
        8.6.16_tk_nsf   8.6.16 {tk nsf tcllib tclx tdom} {}
        8.6.16_notk_nsf 8.6.16 {nsf tcllib tclx tdom} {}
    }

    set TCL_CONFS {
        8.6.16_tk       8.6.16 {tk tcllib tclx tdom} {}
        8.6.16_notk     8.6.16 {tcllib tclx tdom} {}
        8.6.16_tk_nsf   8.6.16 {tk nsf tcllib tclx tdom} {}
        8.6.16_notk_nsf 8.6.16 {nsf tcllib tclx tdom} {}
    }

    set userLibs {}
    foreach {kitName tclVersion packages buildArgs} ${TCL_CONFS} {

        log.info "Will build KIT $kitName for $tclVersion"

        set buildKit [tclkit::buildTCLKit $kitName $tclVersion [concat $packages {zlib tclvfs tls mk4tcl}] $userLibs {*}$buildArgs]
        files.cp $buildKit tclkit-$kitName
        log.info "Available TCL Kit: tclkit-$kitName"


        #set buildCCTCLKit [tclkit::buildCCTCLKit $kitName $tclVersion tclkit-$kitName [concat $packages {zlib tclvfs tls mk4tcl}] {} {*}$buildArgs]
        #files.cp $buildCCTCLKit tclkit-${kitName}.exe
        #log.info "Available CC TCL Kit: tclkit-${kitName}.exe"

        kissb.args.contains -s3 {
            log.info "Pushing..."
            #rclone.run touch -R --s3-acl=public-read ovhs3:kissb/tclkit/${tclVersion} mk4tcl
            rclone.run copy --s3-acl=public-read tclkit-$kitName       ovhs3:kissb/tclkit/${tclVersion}/
            rclone.run copy --s3-acl=public-read tclkit-${kitName}.exe ovhs3:kissb/tclkit/${tclVersion}/
        }
        #rclone.run touch -R --s3-acl=public-read ovhs3:kissb/tclkit/${tclVersion} mk4tcl
        #rclone.run copy --s3-acl=public-read tclkit-$kitName       ovhs3:kissb/tclkit/${tclVersion}/
        #rclone.run copy --s3-acl=public-read tclkit-${kitName}.exe ovhs3:kissb/tclkit/${tclVersion}/
    }

}
