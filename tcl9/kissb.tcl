# SPDX-FileCopyrightText: 2025 KISSB-TCL
#
# SPDX-License-Identifier: Apache-2.0

package require kissb.builder.container
package require kissb.docker
package require kissb.builder.rclone

# Inits
rclone.init
builder.container.init


set tclConfigureArgs {}
set tkConfigureArgs {}


vars.define variants  {static shared}
vars.define buildDir .kb/build

vars.define tcl.version.major 9.0
vars.define tcl.version.minor 9.0.1

vars.define tcl.variants {static shared}

# Build parameters and helpers
vars.define build.host x86_64-redhat-linux
vars.define build.cc   ${::build.host}-gcc
vars.define build.os   rhel8

vars.define build.targetString ${::build.host}-${::build.os}

proc buildSetMingw args {
    # Windows Build
    vars.set build.host         x86_64-w64-mingw32
    vars.set build.cc           ${::build.host}-gcc
    vars.set build.os           win64
    vars.set build.targetString ${::build.host}-${::build.os}
}

proc buildReset args {
    vars.revert build.host build.cc build.os build.targetString
}


# If release requested, ensure the release tag was set
vars.define release.tag -doc "Release Number like a date in format YYMMdd to sort uploaded files in S3" 0
kissb.args.contains --release {

    if {${::release.tag}==0} {
        log.fatal "Requesting a release without a release tag, please set RELEASE_TAG env to something in format YYMMdd"
    }
}



# S3 upload helper
vars.define s3.dryRun -doc "Dry run S3, set to S3_DRYRUN to 0 to upload" 1
proc s3copy {local remote args} {
    set s3args {}
    if {${::s3.dryRun}} {
        lappend s3args --dry-run
        log.warn "S3 is in dry run mode, nothing is uploaded, remote path is $remote"
    }

    rclone.run copy {*}$s3args -P --s3-acl=public-read {*}$args $local ovhs3:kissb/$remote
}

proc s3List {remote args} {

    return [lmap {size name} [rclone.call ls --fast-list  ovhs3:kissb/$remote {*}$args] { string trim $name } ]

}

# Prepare builder image
builder.container.image.build Dockerfile.builder rleys/kissb-tcl9builder:latest

proc getSourceFromTar {req tar url} {

    files.require $req {
        files.require $tar {
            files.download $url $tar

        }
        files.extract $tar
    }

}

proc packageFolder {folder refresh} {

    log.info "Packing ${folder}"
    set archName [file tail $folder]
    set archType [expr  {[string match *x86_64-w64-mingw32* $archName] ? "zip": "tar.gz"}]
    set archFile ${archName}.${archType}

    files.requireOrRefresh $archFile $refresh {
        files.delete $archFile
        files.compressDir $folder $archFile
    }
}


@ tcl9.build {


    files.inDirectory $::buildDir {

        # get source
        getSourceFromTar tcl${::tcl.version.minor}/unix tcl${::tcl.version.minor}-src.tar.gz \
                        http://prdownloads.sourceforge.net/tcl/tcl${::tcl.version.minor}-src.tar.gz

        # Build static and shared variants
        foreach variant ${::tcl.variants} {

            set installPrefix   install/tcl9-${::build.targetString}-${variant}-${::tcl.version.minor}
            set configArgs      --host=${::build.host}
            set sharedLibName   [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "libtcl90.dll.a": "libtcl${::tcl.version.major}.so"}]
            set staticLibName   [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "libtcl90.a": "libtcl${::tcl.version.major}.a"}]

            switch $variant {
                static {
                    set reqOutput ${installPrefix}/lib/$staticLibName
                    lappend configArgs --disable-shared
                }
                shared {
                    set reqOutput ${installPrefix}/lib/$sharedLibName
                }
            }

            # If CC to windows, compile from win not unix directory
            set compileDir [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "win": "unix"}]

            files.requireOrRefresh $reqOutput tcl {

                log.warn "Building TCL $reqOutput"

                files.delete ${installPrefix}

                #puts "TCL recompiling $installPrefix because $reqOutput $staticLibName on ${::build.host}"
                #return
                #make distclean
                builder.image.run rleys/kissb-tcl9builder {
                    pushd tcl${::tcl.version.minor}/$compileDir
                    mkdir -p /build/${installPrefix}
                    make distclean
                    CC=${::build.cc} ./configure --prefix=/build/${installPrefix} $configArgs
                    make install -j8

                }
            }

        }

    }
}

@ {tcl9.build.all "Build TCL9 for Linux and Win64 Platforms (Mingw)"} {

    # Unix Build
    > tcl9.build

    # Windows Build
    vars.set build.host         x86_64-w64-mingw32
    vars.set build.cc           ${::build.host}-gcc
    vars.set build.os           win64
    vars.set build.targetString ${::build.host}-${::build.os}

    > tcl9.build

    vars.revert build.host build.cc build.os build.targetString

}

@ tk9.build {

    #make distclean
    files.inDirectory $::buildDir {

        # get source
        getSourceFromTar tk${::tcl.version.minor}/unix tk${::tcl.version.minor}-src.tar.gz \
                        http://prdownloads.sourceforge.net/tcl/tk${::tcl.version.minor}-src.tar.gz

        # Build static and shared variants
        foreach variant ${::tcl.variants} {

            set configArgs --host=${::build.host}
            set installPrefix install/tk9-${::build.targetString}-${variant}-${::tcl.version.minor}
            set tclPrefix     install/tcl9-${::build.targetString}-${variant}-${::tcl.version.minor}
            set sharedLibName   [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "libtcl9tk90.dll.a": "libtcl9tk${::tcl.version.major}.so"}]
            set staticLibName   [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "libtcl9tk90.a": "libtcl9tk${::tcl.version.major}.a"}]

            switch $variant {
                static {
                    set reqOutput $installPrefix/lib/$staticLibName
                    lappend configArgs --disable-shared
                }
                shared {
                    set reqOutput $installPrefix/lib/$sharedLibName
                }
            }

            set compileDir [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "win": "unix"}]


            files.requireOrRefresh $reqOutput tk9 {
                builder.image.run rleys/kissb-tcl9builder {
                    pushd tk${::tcl.version.minor}/$compileDir
                    mkdir -p /build/$installPrefix
                    make distclean
                    CC=${::build.cc}  ./configure --enable-64bit --prefix=/build/$installPrefix --with-tcl=/build/$tclPrefix/lib $configArgs
                    make install -j8
                }
            }
        }



    }




}

@ tk9.build.all {

    # Unix Build
    > tk9.build

    # Windows Build
    vars.set build.host         x86_64-w64-mingw32
    vars.set build.cc           ${::build.host}-gcc
    vars.set build.os           win64
    vars.set build.targetString ${::build.host}-${::build.os}

    > tk9.build

    vars.revert build.host build.cc build.os build.targetString
}








@ {tcl9.package "Creates tarball and images for tcl9"}  {


    # Build all platforms
    > tcl9.build.all

    ## Make Packages
    files.inDirectory $::buildDir/dist/tcl9 {

        refresh.with tcl9-package { files.delete *}

        # tar ball or zip all produced installs
        files.withGlobAll ../../install/tcl9-* {

            log.info "Packing ${file}"
            set archName [string map {install- "" tcl tcl9} [file tail $file]]
            set archName [file tail $file]
            set archType [expr  {[string match *x86_64-w64-mingw32* $archName] ? "zip": "tar.gz"}]
            set archFile ${archName}.${archType}

            files.requireOrRefresh $archFile tcl9-package {
                files.delete $archFile
                files.compressDir [file normalize $file] $archFile
            }
        }

        # Release
        kissb.args.contains --release {
            files.withGlobFiles [list tcl*.tar.gz  tcl*.zip] {
                log.info "Uploading [file tail $file] to S3..."
                s3copy $file tcl9/${::tcl.version.minor}/${::release.tag}
                #rclone.run copy -P --s3-acl=public-read $file ovhs3:kissb/tcl9/${::tcl.version.minor}/
            }
        }
    }

}


@ {tcl9.images "makes shared and static images for runtime and development"} {

    > tcl9.build.all

    files.inDirectory $::buildDir {

        # Require CriTCL to add to dev image
        getSourceFromTar ./critcl-3.3.1/build.tcl critcl-3.3.1.tar.gz https://github.com/andreas-kupries/critcl/archive/refs/tags/3.3.1.tar.gz

        foreach variant $::variants {
            builder.container.image.build ${::kissb.projectFolder}/Dockerfile.tclsh9-$variant      rleys/kissb-tclsh9-$variant:latest
            #docker.image.build ${::kissb.projectFolder}/Dockerfile.tclsh9-$variant-dev  rleys/kissb-tclsh9-${::tcl.version.minor}-$variant-rocky8-dev:${::tcl.version.minor}
        }
    }

    ## Push to docker
    kissb.args.contains --release {

        builder.container.image.push  rleys/kissb-tclsh9-static:latest docker.io/rleys/kissb-tclsh9-static:latest
        builder.container.image.push  rleys/kissb-tclsh9-shared:latest docker.io/rleys/kissb-tclsh9-shared:latest

        builder.container.image.push  rleys/kissb-tclsh9-static:latest docker.io/rleys/kissb-tclsh9-static:${::tcl.version.minor}-${::release.tag}
        builder.container.image.push  rleys/kissb-tclsh9-shared:latest docker.io/rleys/kissb-tclsh9-shared:${::tcl.version.minor}-${::release.tag}

        return
        docker.push  rleys/kissb-tclsh9-static:${::tcl.version.minor}
        docker.push  rleys/kissb-tclsh9-shared:${::tcl.version.minor}
        docker.push  rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor}
        docker.push  rleys/kissb-tclsh9-shared-rocky8-dev:${::tcl.version.minor}
    }

}



@ {tcl9.kits "Makes TCL9 Kits"} {

    > tcl9.package

    log.info "Args $args"

    ## Make TCL Kits for all static installations
    files.inDirectory $::buildDir/dist/tcl9-kit {

        refresh.with tcl9-kit { files.delete *}

        files.withGlobAll ../../install/tcl9-*static* {

            log.info "Creating KIT for: ${file}"
            set kitName [string map {tcl9 tclkit9 -static ""} [file tail $file]]

            if {[string match *x86_64-w64-mingw32* $file] && [os.isLinuxWSL]} {
                log.info "Creating Win64 KIT"

                files.requireOrRefresh ${kitName}.exe tcl9-kit {
                   exec.run ${file}/bin/tclsh90s.exe ${::kissb.projectFolder}/kit_creator.tcl --name ${kitName}
                }

            } else {
                log.warn "Creating Linux Kit"
                files.requireOrRefresh ${kitName} tcl9-kit {
                   exec.run ${file}/bin/tclsh9.0 ${::kissb.projectFolder}/kit_creator.tcl --name ${kitName}
                }
            }

        }

        ## Release
        kissb.args.contains --release {
            files.withGlobFiles [list *kit*] {
                log.info "Uploading [file tail $file] to S3..."
                s3copy $file tcl9/${::tcl.version.minor}/${::release.tag}
                #rclone.run copy --dry-run -v -P --s3-acl=public-read $file ovhs3:kissb/
            }
        }
    }
}



@ {tk9.package "Package TK9 as image and tarball"} {

    # Unix Build
    > tk9.build.all

    ## Make Packages
    files.inDirectory $::buildDir/dist/tk9 {

        refresh.with tk9-package { files.delete *}

        # tar ball or zip all produced installs
        files.withGlobAll ../../install/tk9-* {

            log.info "Packing ${file}"
            set archName [string map {install- "" tk tk9} [file tail $file]]
            set archName [file tail $file]
            set archType [expr  {[string match *x86_64-w64-mingw32* $archName] ? "zip": "tar.gz"}]
            set archFile ${archName}.${archType}

            files.requireOrRefresh $archFile tk9-package {
                files.delete $archFile
                files.compressDir $file $archFile
            }



        }

        ## Release
        kissb.args.contains --release {
            files.withGlobFiles [list tk*.tar.gz  tk*.zip] {
                log.info "Uploading [file tail $file] to S3..."
                s3copy $file tcl9/${::tcl.version.minor}/${::release.tag}
                #rclone.run copy -P --s3-acl=public-read $file ovhs3:kissb/tcl9/${::tcl.version.minor}/
            }
        }
    }

}

@ {tk9.images "Make TK images for runtime and development"} {


    > tk9.build.all


    files.inDirectory $::buildDir {

        # Require CriTCL to add to dev image
        getSourceFromTar ./critcl-3.3.1/build.tcl critcl-3.3.1.tar.gz https://github.com/andreas-kupries/critcl/archive/refs/tags/3.3.1.tar.gz

        foreach variant $::variants {
            builder.container.image.build ${::kissb.projectFolder}/Dockerfile.wish9-$variant  rleys/kissb-wish9-$variant:latest
            #docker.image.build ${::kissb.projectFolder}/Dockerfile.wish9-$variant-dev  rleys/kissb-wish9-$variant-rocky8-dev:${::tcl.version.minor}
        }



        ## Push to docker
        kissb.args.contains --release {
            builder.container.image.push  rleys/kissb-wish9-static:latest docker.io/rleys/kissb-wish9-static:latest
            builder.container.image.push  rleys/kissb-wish9-shared:latest docker.io/rleys/kissb-wish9-shared:latest

            builder.container.image.push  rleys/kissb-wish9-static:latest docker.io/rleys/kissb-wish9-static:${::tcl.version.minor}-${::release.tag}
            builder.container.image.push  rleys/kissb-wish9-shared:latest docker.io/rleys/kissb-wish9-shared:${::tcl.version.minor}-${::release.tag}

            #builder.container.image.push  rleys/kissb-tclsh9-static:${::tcl.version.minor}
            #builder.container.image.push  rleys/kissb-tclsh9-shared:${::tcl.version.minor}
            #builder.container.image.push  rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor}
            #builder.container.image.push  rleys/kissb-tclsh9-shared-rocky8-dev:${::tcl.version.minor}
        }
    }

}

@ {tk9.kits "Make a basic TK9 Kit"} {

    > tk9.package

    ## Make TK9 Kits for all static installations
    files.inDirectory $::buildDir/dist/tk9-kit {

        refresh.with tk9-kit { files.delete * }

        files.withGlobAll ../../install/tk9-*static* {

            log.info "Creating KIT for: ${file}"


            if {[string match *x86_64-w64-mingw32* $file] && [os.isLinuxWSL]} {
                log.info "Creating Win64 KIT"


                set kitName [string map {tk9 tkkit9 -static "-light"} [file tail $file]]
                files.requireOrRefresh ${kitName}.exe tk9-kit {
                    exec.run ${file}/bin/wish90s.exe ${::kissb.projectFolder}/kit_creator.tcl --outdir dist-tklight-win64 --name $kitName
                }

                set kitName [string map {tk9 tkkit9 -static ""} [file tail $file]]
                set tclInstallName [string map {tk9 tcl9} $file]
                files.requireOrRefresh ${kitName}.exe tk9-kit {
                    exec.run ${tclInstallName}/bin/tclsh90s.exe ${::kissb.projectFolder}/kit_creator.tcl --outdir dist-tk-win64 --extract
                    exec.run ${file}/bin/wish90s.exe ${::kissb.projectFolder}/kit_creator.tcl --outdir dist-tk-win64 --continue  --name $kitName
                }



            } else {
                log.warn "Creating Linux Kit"

                set kitName [string map {tk9 tkkit9 -static "-light"} [file tail $file]]
                files.requireOrRefresh ${kitName} tk9-kit {
                    exec.run ${file}/bin/wish9.0 ${::kissb.projectFolder}/kit_creator.tcl --outdir dist-tklight-linux --name $kitName
                }

                set kitName [string map {tk9 tkkit9 -static ""} [file tail $file]]
                set tclInstallName [string map {tk9 tcl9} $file]
                files.requireOrRefresh ${kitName} tk9-kit {
                    exec.run ${tclInstallName}/bin/tclsh9.0 ${::kissb.projectFolder}/kit_creator.tcl --outdir dist-tk-linux --extract
                    exec.run ${file}/bin/wish9.0 ${::kissb.projectFolder}/kit_creator.tcl --outdir dist-tk-linux --continue  --name $kitName
                }


            }

        }

        ## Release
        kissb.args.contains --release {
            files.withGlobFiles [list *kit*] {
                log.info "Uploading [file tail $file] to S3..."
                s3copy $file tcl9/${::tcl.version.minor}/${::release.tag}
                #rclone.run copy --dry-run -v -P --s3-acl=public-read $file ovhs3:kissb/
            }
        }

    }


    return
    package require kissb.tcl9.kit

    files.inDirectory $::buildDir/dist/tcl9 {
        files.requireOrRefresh tclkit-${::tcl.version.minor} TCLKIT {
            tcl9.kit.make -image rleys/kissb-wish9-static:${::tcl.version.minor}
        }

    }
}


####################################
####################################$


@ {dist1.tcllib.build "Build TCL Lib"} {

    ## Download
    files.inDirectory ${::buildDir} {

        set configArgs      --host=${::build.host}
        set installPrefix   install/tcllib-${::build.targetString}-tcl${::tcl.version.minor}-2.0
        set tclPrefix       install/tcl9-${::build.targetString}-shared-${::tcl.version.minor}
        set tclSh           [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "tclsh90.exe": "tclsh9.0"}]

        #set buildImage
        files.requireOrRefresh $installPrefix/lib/tcllib2.0/pkgIndex.tcl tcllib {

            files.delete $installPrefix/
            getSourceFromTar ./tcllib-2.0/configure tcllib-2.0.tar.gz https://core.tcl-lang.org/tcllib/uv/tcllib-2.0.tar.gz


            builder.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
                pushd tcllib-2.0/
                mkdir -p /build/$installPrefix
                CC=${::build.cc} ./configure --prefix=/build/$installPrefix --with-tclsh=/build/$tclPrefix/bin/$tclSh $configArgs
                make clean
                make install -j8
            }

            #builder.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
            #    pushd tcllib-2.0/
            #    mkdir -p /build/$installPrefix
            #    ./configure --help
            #    CC=${::build.cc} ./configure --prefix=/build/$installPrefix --with-tclsh=/install-tcl/bin/tclsh9.0 $configArgs
            #    make clean
            #    make install -j8
            #}

        }

    }
}

@ {dist1.tcllib.packages "Build TCL Lib"} {

    >> dist1.tcllib.build

    #buildSetMingw

    #>> tcllib.build

    #buildReset
}

@ {dist1.tklib.build "Build Tk Lib"} {

    ## Download
    files.inDirectory ${::buildDir} {

        set configArgs      --host=${::build.host}
        set installPrefix   install/tklib-${::build.targetString}-tcl${::tcl.version.minor}-0.9
        set tclPrefix       install/tcl9-${::build.targetString}-shared-${::tcl.version.minor}
        set tclSh           [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "tclsh90.exe": "tclsh9.0"}]

        #set buildImage
        files.requireOrRefresh $installPrefix/lib/tklib0.9/pkgIndex.tcl tcllib {

            files.delete $installPrefix/
            getSourceFromTar ./tklib-0.9/configure tklib-0.9.tar.xz "https://core.tcl-lang.org/tklib/attachdownload/tklib-0.9.tar.xz?page=Downloads&file=tklib-0.9.tar.xz"


            builder.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
                pushd tklib-0.9/
                mkdir -p /build/$installPrefix
                CC=${::build.cc} ./configure --prefix=/build/$installPrefix --with-tclsh=/build/$tclPrefix/bin/$tclSh $configArgs
                make clean
                make install -j8
            }
        }
    }
}



@ {dist1.tclx.build "Build for TCLX Library"} {

    files.inDirectory ${::buildDir} {

        set configArgs      --host=${::build.host}
        set installPrefix   install/tclx-${::build.targetString}-tcl${::tcl.version.minor}-8.6.3
        set tclPrefix       install/tcl9-${::build.targetString}-shared-${::tcl.version.minor}
        set tclSh           [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "tclsh90.exe": "tclsh9.0"}]

        files.requireOrRefresh $installPrefix/lib/tclx8.6/autoload.tcl tclx {
            files.delete $installPrefix
            files.require tclx-8.6.3/CHANGES {
                exec.run git clone https://github.com/opendesignflow/tclx.git tclx-8.6.3
            }

            builder.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
                pushd tclx-8.6.3/
                mkdir -p /build/$installPrefix
                autoconf
                make distclean
                # --disable-shared
                ./configure --help
                ./configure --prefix=/build/$installPrefix \
                            --exec-prefix=/build/$installPrefix \
                            --with-tcl=/build/$tclPrefix/lib \
                            --with-tclinclude=/build/$tclPrefix/include \
                            $configArgs

                make -j8
                make install
            }
        }

    }


}

@ {dist1.tclx.package "Package TCLX Library"} {

    >> dist1.tclx.build

    buildSetMingw

    >> dist1.tclx.build

    #buildReset
}


@ {dist1.tcltls.build "Build for TCLLS library"} {


    set tlcTLSVersion 1.7.22
    set tclTLSChecking e19f6b3f18
    set baseName tcltls-${tclTLSChecking}

    files.inDirectory ${::buildDir} {


        set installPrefix   install/tcltls-${::build.targetString}-tcl${::tcl.version.minor}-2.0b1
        set tclPrefix       install/tcl9-${::build.targetString}-shared-${::tcl.version.minor}
        set tclSh           [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "tclsh90.exe": "tclsh9.0"}]

        #set buildImage
        files.requireOrRefresh install-tcltls/lib/tls2.0b1/libtcl9tls2.0b1.so TCLTLS {

            files.delete $installPrefix/
            getSourceFromTar ${baseName}/ChangeLog ${baseName}.tar.gz "https://core.tcl-lang.org/tcltls/tarball/e19f6b3f18/${baseName}.tar.gz"

            # Get LibreSSL
            #files.require libressl-x86_64-linux-rhel8-4.0.0/lib/libssl.so {
            #    files.require libressl-x86_64-linux-rhel8-4.0.0.tar.gz {
            #        files.download https://kissb.s3.de.io.cloud.ovh.net/libs/libressl/4.0.0/libressl-x86_64-linux-rhel8-4.0.0.tar.gz libressl-x86_64-linux-rhel8-4.0.0.tar.gz
            #    }
            #    files.extract libressl-x86_64-linux-rhel8-4.0.0.tar.gz
            #
            #}

            #builder.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
            #    pushd ${baseName}/
            #    mkdir -p /build/install-tcltls
            #    ./configure --help
            #    ./configure  --with-openssl-pkgconfig=/build/libressl-x86_64-linux-rhel8-4.0.0/lib/pkgconfig/ --prefix=/build/install-tcltls --enable-64bit --enable-static-ssl  --exec-prefix=/build/install-tcltls --with-tcl=/install-tcl/lib --with-tclinclude=/install-tcl/include
            #    make clean
            #    make -j8
            #    make install
            #}


            files.delete patches
            files.cp ${::kissb.projectFolder}/patches .
            #  rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor}
            builder.image.run rleys/kissb-tcl9builder  {
                pushd ${baseName}/
                mkdir -p /build/$installPrefix
                patch -u acinclude.m4 -i ../patches/tcltls-acinclude.m4
                autoconf
                TCLTLS_SSL_LIBS="-lssl -lz -lcrypto -pthread" \
                ./configure --prefix=/build/$installPrefix \
                            --enable-64bit \
                            --enable-static-ssl  \
                            --exec-prefix=/build/$installPrefix \
                            --with-tcl=/build/$tclPrefix/lib \
                            --with-tclinclude=/build/$tclPrefix/include
                make clean
                make -j8
                make install
            }
        }

    }


}


@ {dist1.tcltls.package "Build for TCLLS library"} {

    >> dist1.tcltls.build


    files.inDirectory $::buildDir/dist/tcltls {

        files.withGlobAll {
            ../../install/tcltls-*linux*
        } {

            #log.info "Copying $file into work"
            #exec.run cp -Rf $file work/
            packageFolder $file tcltls-package
        }

    }

}

@ {dist1.build "Build DIST1 Packages"} {

    > tcl9.build
    > tk9.build
    > dist1.tcllib.build
    > dist1.tklib.build
    > dist1.tcltls.build
    > dist1.tclx.build

}

vars.define dist1.release 250501

@ {dist1.package "Create a DIST1 Package"} {

    > dist1.build


    ## Create an archive folder with all libraries in
    ## For Dist Kit, use the archive folder lib/ as source of additional libraries
    files.inDirectory ${::buildDir}/dist/tcl9-dist1 {




        set distinstallPrefix tcl9-dist1-${::build.targetString}-${::tcl.version.minor}-${::dist1.release}
        files.requireOrRefresh [file tail $distinstallPrefix].tar.gz  dist1-package {

            files.delete *.tar.gz
            files.delete $distinstallPrefix
            files.mkdir $distinstallPrefix

            files.withGlobAll {
            ../../install/tcl9-*linux*static*/*
            ../../install/tk9-*linux*static*/*
            ../../install/tcllib-*linux*/*
            ../../install/tklib-*linux*/*
            ../../install/tcltls-*linux*/*
            ../../install/tclx-*linux*/*} {
                log.info "Copying $file into $distinstallPrefix"
                exec.run cp -Rf $file $distinstallPrefix/

            }
            files.compressDir $distinstallPrefix [file tail $distinstallPrefix].tar.gz
        }


        buildSetMingw

        set distinstallPrefix tcl9-dist1-${::build.targetString}-${::tcl.version.minor}-${::dist1.release}
        files.requireOrRefresh [file tail $distinstallPrefix].zip   dist1-package {

            files.delete *.zip
            files.delete $distinstallPrefix
            files.mkdir $distinstallPrefix

            files.withGlobAll {
            ../../install/tcl9-*mingw*static*/*
            ../../install/tk9-*mingw*static*/*
            ../../install/tcllib-*linux*/*
            ../../install/tklib-*linux*/*
            ../../install/tclx-*mingw*/*} {
                log.info "Copying $file into $distinstallPrefix"
                exec.run cp -Rf $file $distinstallPrefix/

            }
            files.compressDir $distinstallPrefix [file tail $distinstallPrefix].zip
        }


        buildReset


        kissb.args.contains --release {
            files.withGlobAll {*.tar.gz *.zip} {
                log.info "Uploading $file to S3..."
                s3copy $file tcl9/dist1/${::dist1.release}/
            }
        }
    }




}

@ {dist1.kit "Create Kit KISSB DIST1 TCL"} {

    > dist1.package

    files.inDirectory ${::buildDir}/dist/tcl9-dist1 {

        ## Linux Kit
        set distFolder tcl9-dist1-${::build.targetString}-${::tcl.version.minor}-${::dist1.release}
        set kitName tcl9-dist1kit-${::build.targetString}-${::tcl.version.minor}-${::dist1.release}

        files.requireOrRefresh $kitName dist1-tclkit {

            exec.run $distFolder/bin/tclsh9.0 ${::kissb.projectFolder}/kit_creator.tcl --name $kitName
            #tcl9.kit.make -name tclkit-dist1 -image rleys/kissb-tclsh9-static-dist1:${::tcl.version.minor}
        }

        ## Win Kit
        buildSetMingw

        set distFolder tcl9-dist1-${::build.targetString}-${::tcl.version.minor}-${::dist1.release}
        set kitName tcl9-dist1kit-${::build.targetString}-${::tcl.version.minor}-${::dist1.release}
        files.requireOrRefresh ${kitName}.exe dist1-tclkit {

            exec.run $distFolder/bin/tclsh90s.exe ${::kissb.projectFolder}/kit_creator.tcl --name $kitName
            #tcl9.kit.make -name tclkit-dist1 -image rleys/kissb-tclsh9-static-dist1:${::tcl.version.minor}
        }

        buildReset

        ## Release
        kissb.args.contains --release {
            files.withGlobAll {tcl9-dist1kit*} {
                log.info "Uploading $file to S3..."
                s3copy $file tcl9/dist1/${::dist1.release}/
            }
        }
    }
}

@ {dist1.image "Create Image for KISSB DIST1 TCL"} {

    > images-tcl
    > build-tcllib
    > build-tclx
    > build-tcltls


    files.inDirectory $::buildDir {
        docker.image.build ${::kissb.projectFolder}/Dockerfile.tclsh9-static-full rleys/kissb-tclsh9-static-dist1:${::tcl.version.minor}
    }
}

###############
## Signing ####

vars.define sign.defaultKey "E24253BA23A2452F"

proc signSha256File file {

    exec.run sha256sum -b $file > ${file}.sha256
    return ${file}.sha256
}

@ {sign.tcl9 "Sign TCL9 Released files"} {

    files.inDirectory ${::buildDir}/sign {

        set basePath tcl9/9.0.1/250501
        set baseUrl https://kissb.s3.de.io.cloud.ovh.net/$basePath
        foreach file [s3List $basePath --exclude *.sha256*] {
            log.info "Signing $file"

            files.requireOrRefresh ${file}.sha256.asc sign-tcl9 {

                    ## Get Package
                set downloadedFile [files.downloadOrRefresh $baseUrl/$file sign]

                ## Sign
                set checksumFile [signSha256File ${downloadedFile}]
                files.delete ${checksumFile}.asc
                exec.run gpg --batch --local-user 0x${::sign.defaultKey} --output ${checksumFile}.asc --detach-sig $checksumFile
                exec.run gpg --verify ${checksumFile}.asc $checksumFile
            }

            ## Upload
            kissb.args.contains --publish {
                s3copy ${checksumFile}.asc $basePath
                s3copy ${checksumFile} $basePath
            }

        }

    }


}

@ {sign.dist1 "Sign TCL9 Released files"} {

    files.inDirectory ${::buildDir}/sign {

        set basePath tcl9/dist1/250501
        set baseUrl https://kissb.s3.de.io.cloud.ovh.net/$basePath
        foreach file [s3List $basePath --exclude *.sha256*] {
            log.info "Signing $file"

            files.requireOrRefresh ${file}.sha256.asc sign-tcl9 {

                    ## Get Package
                set downloadedFile [files.downloadOrRefresh $baseUrl/$file sign]

                ## Sign
                set checksumFile [signSha256File ${downloadedFile}]
                files.delete ${checksumFile}.asc
                exec.run gpg --batch --local-user 0x${::sign.defaultKey} --output ${checksumFile}.asc --detach-sig $checksumFile
                exec.run gpg --verify ${checksumFile}.asc $checksumFile
            }

            ## Upload
            kissb.args.contains --publish {
                s3copy ${checksumFile}.asc $basePath
                s3copy ${checksumFile} $basePath
            }

        }

    }


}
