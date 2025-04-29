package require kissb.builder.podman
package require kissb.docker
package require kissb.builder.rclone

builder.selectDockerRuntime



rclone.init ../../rclone.conf

set version 4.0.0


@ download {

    set url https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${::version}.tar.gz

    files.inDirectory .kb/build {
        
        files.require libressl-${::version}/README.md {
            files.require libressl-${::version}.tar.gz {
                files.download $url 
            }
            files.extract libressl-${::version}.tar.gz
        }

    }

}
@ build-linux {

    > download
    
    set outDir libressl-x86_64-linux-rhel8-${::version}
    files.inDirectory .kb/build {
        
        files.requireOrRefresh $outDir/lib/libcrypto.so LINUX {

            builder.image.run rleys/builder:rocky8 {
                pushd libressl-${::version}
                mkdir -p /build/$outDir
                ./configure --prefix=/build/$outDir
                make clean
                make -j8 
                make check
                make install
            }  

        }
    }
    

}

@ build-windows {

    > download
    
    set outDir libressl-x86_64-w64-mingw32-${::version}
    files.inDirectory .kb/build {
        
        files.requireOrRefresh $outDir/lib/libcrypto.a WINDOWS {
            builder.image.run rleys/builder:rocky8 {
                pushd libressl-${::version}
                mkdir -p /build/$outDir
                CC=x86_64-w64-mingw32-gcc ./configure --prefix=/build/$outDir --host=x86_64-w64-mingw32
                make clean
                make -j8 
                make check
                make install
            }  
        }
        
    }
    

}

@ release {

    > build-linux
    > build-windows

    files.inDirectory .kb/build {

        files.require libressl-x86_64-linux-rhel8-${::version}.tar.gz {
             files.tarDir libressl-x86_64-linux-rhel8-${::version} ${__f}
        }
        files.require libressl-x86_64-w64-mingw32-${::version}.tar.gz {
             files.tarDir libressl-x86_64-w64-mingw32-${::version} ${__f}
        }
    
        rclone.run copy -P --s3-acl=public-read libressl-x86_64-linux-rhel8-${::version}.tar.gz ovhs3:kissb/libs/libressl/${::version}/
        rclone.run copy -P --s3-acl=public-read libressl-x86_64-w64-mingw32-${::version}.tar.gz ovhs3:kissb/libs/libressl/${::version}/
    }
}