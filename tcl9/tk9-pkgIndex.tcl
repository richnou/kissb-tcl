if {![package vsatisfies [package provide Tcl] 8.7-]} return
if {($::tcl_platform(platform) eq "unix") && ([info exists ::env(DISPLAY)]
	|| ([info exists ::argv] && ("-display" in $::argv)))} {
    if {[package vsatisfies [package provide Tcl] 9.0]} {
	package ifneeded tk 9.0.1 [list load [file normalize [file join $dir .. .. bin libtcl9tk9.0.dll]]]
    } else {
	package ifneeded tk 9.0.1 [list load [file normalize [file join $dir .. .. bin libtk9.0.dll]]]
    }
} else {
    if {[package vsatisfies [package provide Tcl] 9.0]} {
        puts "Loading tk from: $dir -> [file join $dir ..  bin tcl9tk90.dll]"
	package ifneeded tk 9.0.1 [list load [file normalize [file join $dir  .. bin tcl9tk90.dll]]]
    } else {
	package ifneeded tk 9.0.1 [list load [file normalize [file join $dir  .. bin tk90.dll]]]
    }
}
package ifneeded Tk 9.0.1 [list package require -exact tk 9.0.1]
