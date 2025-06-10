## This script runs without external libraries to ease usage when starting from standard shared lib tcl but running with static tcl to make
## a standalone kit

###################
## Parameters #####
###################
set out.dir ./dist
set app.bin ./tclkit9

set libs.stdTcl true

set exe_path [zipfs mount //zipfs:/app]
puts "Exe is now: $exe_path"
if {$exe_path eq ""} {
    puts "Please use a static wish to make single-file exes! "
    exit -1
    #pack [ttk::label .e -text "\n Please use a static wish to make single-file exes! "]
    #pack [ttk::button .b -text Exit -command exit] -pady 8
    return
}

set tcl.home [file dirname [file dirname $exe_path]]

###################
## Prepare output folder with libraries and app ############
###################

## Build Output directory with TCL and TK if necessary
###########
file delete -force ${out.dir}
file mkdir ${out.dir}
file copy $tcl_library [file join ${out.dir} tcl_library]
if {![catch {set tk_library}]} {
    file copy $tk_library [file join ${out.dir} tk_library]
}

## Add TCL standard libraries
if {${libs.stdTcl}} {

     puts "- Adding TCL Standard libraries from ${tcl.home}"
    foreach libDir [glob -type d ${tcl.home}/lib/*] {
        puts "-- Adding TCL Standard library [file tail $libDir]"
        #file copy $libDir [file join ${out.dir} tcl_library]
        file copy $libDir [file join ${out.dir}]
    }
}

#file mkdir [file join${out.dir} lib]
#file copy $inpDir [file join $outDir lib $appName]


#####################
## Package ############
######################
zipfs mkimg ${app.bin} ${out.dir} ${out.dir} "" $exe_path