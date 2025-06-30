
package require kissb.builder.container
package require kissb.docker
package require kissb.builder.rclone

# Inits
rclone.init
builder.container.init


vars.define variants  {static shared}
vars.define buildDir [file normalize .kb/build]

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
        log.warn "S3 is in dry run mode, nothing is uploaded, remote path is $remote - set S3_DRYRUN=0 to upload"
    }
    log.success "Uploading $local to $remote"
    rclone.run copy {*}$s3args -P --s3-acl=public-read {*}$args $local ovhs3:kissb/$remote
}

proc s3List {remote args} {

    return [lmap {size name} [rclone.call ls --fast-list  ovhs3:kissb/$remote {*}$args] { string trim $name } ]

}

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


@ {tcl.build.generic} {

    files.inDirectory $::buildDir {

        # get source
        getSourceFromTar tcl${::tcl.version.minor}/unix tcl${::tcl.version.minor}-src.tar.gz \
                        http://prdownloads.sourceforge.net/tcl/tcl${::tcl.version.minor}-src.tar.gz

        # Build static and shared variants
        foreach variant ${::tcl.variants} {

            set libBaseName     [string map {. ""} ${::tcl.version.major}]
            set installPrefix   install/tcl[lindex [split ${::tcl.version.minor} .] 0]-${::build.targetString}-${variant}-${::tcl.version.minor}
            set configArgs      --host=${::build.host}
            set sharedLibName   [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "libtcl${libBaseName}.dll.a": "libtcl${::tcl.version.major}.so"}]
            set staticLibName   [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "libtcl${libBaseName}.a": "libtcl${::tcl.version.major}.a"}]

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
                builder.container.image.run rleys/kissb-tcl9builder {
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


@ {tcl.package.generic "Creates tarball and images for tcl"}  {

    set tclBaseName tcl[lindex [split ${::tcl.version.minor} .] 0]

    ## Make Packages
    files.inDirectory $::buildDir/dist/$tclBaseName {

        refresh.with $tclBaseName-package { files.delete *}

        # tar ball or zip all produced installs
        files.withGlobAll ../../install/$tclBaseName-* {

            log.info "Packing ${file}"
            set archName [file tail $file]
            set archType [expr  {[string match *x86_64-w64-mingw32* $archName] ? "zip": "tar.gz"}]
            set archFile ${archName}.${archType}

            files.requireOrRefresh $archFile $tclBaseName-package {
                files.delete $archFile
                files.compressDir [file normalize $file] $archFile
            }
        }

        # Release
        kissb.args.contains --release {
            files.withGlobFiles [list tcl*.tar.gz  tcl*.zip] {
                log.info "Uploading [file tail $file] to S3..."
                s3copy $file $tclBaseName/${::tcl.version.minor}/${::release.tag}
                #rclone.run copy -P --s3-acl=public-read $file ovhs3:kissb/tcl9/${::tcl.version.minor}/
            }
        }
    }

}

@ {tk.build.generic} {

    files.inDirectory $::buildDir {

        # get source
        getSourceFromTar tk${::tcl.version.minor}/unix tk${::tcl.version.minor}-src.tar.gz \
                        http://prdownloads.sourceforge.net/tcl/tk${::tcl.version.minor}-src.tar.gz


        # Build static and shared variants
        foreach variant ${::tcl.variants} {

            # 9 or 8
            set tclBaseVersion  [lindex [split ${::tcl.version.minor} .] 0]
            set libBaseNameWin  [string map {. ""} ${::tcl.version.major}]
            set libNamePrefix   [expr {$tclBaseVersion == 9 ? "libtcl9tk" : "libtk" }]

            set configArgs      --host=${::build.host}
            set installPrefix   install/tk${tclBaseVersion}-${::build.targetString}-${variant}-${::tcl.version.minor}
            set tclPrefix       install/tcl${tclBaseVersion}-${::build.targetString}-${variant}-${::tcl.version.minor}

            set sharedLibName   [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "${libNamePrefix}${libBaseNameWin}.dll.a": "${libNamePrefix}${::tcl.version.major}.so"}]
            set staticLibName   [expr  {"${::build.host}" eq "x86_64-w64-mingw32" ? "${libNamePrefix}${libBaseNameWin}.a": "${libNamePrefix}${::tcl.version.major}.a"}]

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


            files.requireOrRefresh $reqOutput tk {
                builder.container.image.run rleys/kissb-tcl9builder {
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



@ {tk.package.generic "Package TK as tarball"} {


    set tkBaseName tk[lindex [split ${::tcl.version.minor} .] 0]

    ## Make Packages
    files.inDirectory $::buildDir/dist/$tkBaseName {

        refresh.with $tkBaseName-package { files.delete *}

        # tar ball or zip all produced installs
        files.withGlobAll ../../install/$tkBaseName-* {

            log.info "Packing ${file}"
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
                s3copy $file $tkBaseName/${::tcl.version.minor}/${::release.tag}
                #rclone.run copy -P --s3-acl=public-read $file ovhs3:kissb/tcl9/${::tcl.version.minor}/
            }
        }
    }

}
