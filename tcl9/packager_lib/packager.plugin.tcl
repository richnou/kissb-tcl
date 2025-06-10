package provide kissb.tcl9.packager
package require kissb
package require kissb.docker

namespace eval kissb::packager {

    vars.set tcl9.packager.home [files.getScriptDirectory]

    kissb.extension kit9 {


        ## This Method prepares a base kit, arguments used to add code to the package an startup app
        make args {

            log.info "Making TCL9 Kit"

            set outFile kit9

            set addITCL true


            ## Prepare Work
            files.inDirectory .kb/build/kit9 {
    
                ## Run TCL9 from image
                files.cp [vars.get tcl9.packager.home]/packager_run.tcl packager_run.tcl
                docker.image.run rleys/kissb-tclsh9-static-full:latest -imgArgs packager_run.tcl
            }
            

        }

    }

}