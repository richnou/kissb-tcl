# SPDX-FileCopyrightText: 2025 KISSB-TCL
#
# SPDX-License-Identifier: Apache-2.0

# Parameters and helpers for building
source ../common/build.params.tcl

# Set for TCL9
vars.set tcl.version.major 9.0
vars.set tcl.version.minor 9.0.1


# Prepare builder image
builder.container.image.build Dockerfile.builder rleys/kissb-tcl9builder:latest


@ {tcl9.build.all "Build TCL9 for Linux and Win64 Platforms (Mingw)"} {

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


@ {tk9.build.all} {

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


            builder.container.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
                pushd tcllib-2.0/
                mkdir -p /build/$installPrefix
                CC=${::build.cc} ./configure --prefix=/build/$installPrefix --with-tclsh=/build/$tclPrefix/bin/$tclSh $configArgs
                make clean
                make install -j8
            }

            #builder.container.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
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


            builder.container.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
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

            builder.container.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
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

            #builder.container.image.run rleys/kissb-tclsh9-static-rocky8-dev:${::tcl.version.minor} {
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
            builder.container.image.run rleys/kissb-tcl9builder  {
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
