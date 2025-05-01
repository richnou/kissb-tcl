## This script runs without external libraries to ease usage when starting from standard shared lib tcl but running with static tcl to make
## a standalone kit
proc getEnv {name default} {

    try {
        set argsIndex [lsearch -exact $::argv --[string tolower $name]]
        if {$argsIndex>=0} {
            return [lindex $::argv [expr $argsIndex + 1]]
        } else {
            return $::env($name)
        }
        
    } on error {msg options} {
        return $default 
    }
    
    
}

proc hasArg name {

    return [expr {[lsearch -exact $::argv --[string tolower $name]] != -1  } ]
}

###################
## Parameters #####
###################
set tcl.version [info patchlevel]

set out.dir ./[getEnv OUTDIR "dist"]
set app.bin ./[getEnv NAME "tclkit-${tcl.version}"]

set libs.stdTcl true

set mode.extract [hasArg extract]
set mode.continue [hasArg continue]

set exe_path [zipfs mount //zipfs:/app]



if {[file extension $exe_path]==".exe"} {
    set app.bin ${app.bin}.exe
}

puts "TCL Kit name=${app.bin}"
puts "TCL Kit version=${tcl.version}"
puts "Extract Mode=${mode.extract}"
puts "Continue Mode=${mode.continue}"
puts "Base Exe=$exe_path"

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
if {!${mode.continue}} {
    file delete -force ${out.dir}
}
if {![file exists ${out.dir}]} {
    file mkdir ${out.dir}
}

file copy -force $tcl_library [file join ${out.dir} tcl_library]
if {![catch {set tk_library}]} {
    file copy -force $tk_library [file join ${out.dir} tk_library]
}

## Add TCL standard libraries
if {${libs.stdTcl}} {

     puts "- Adding TCL Standard libraries from ${tcl.home}"
    foreach libDir [glob -type d ${tcl.home}/lib/*] {
        puts "-- Adding TCL Standard library [file tail $libDir]"
        set targetDir [file join ${out.dir}]/[file tail $libDir]
        # IF target dir exists, copy source content into target dir to avoid errors
        if {[file exists $targetDir]} {
            foreach __f [glob -types {d f l} $libDir/*] {
                puts "-- Copying ${__f} to $targetDir"
                file copy  -force ${__f} $targetDir/
            }
        } else {
            file copy  -force $libDir $targetDir
        }
        #file copy $libDir [file join ${out.dir} tcl_library]
        
    }
}

#file mkdir [file join${out.dir} lib]
#file copy $inpDir [file join $outDir lib $appName]


#####################
## Package ############
######################
if {!${mode.extract}} {
    zipfs mkimg ${app.bin} ${out.dir} ${out.dir} "" $exe_path
    puts "TCL Kit created: ${app.bin} in [pwd]"
}
