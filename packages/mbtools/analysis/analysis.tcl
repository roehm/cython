
package require ::mmsg 1.0.0
package require ::mbtools::utils 1.0.0
package provide ::mbtools::analysis 1.0.0

namespace eval ::mbtools::analysis {

    # Global arguments
    variable iotype
    variable docommands
    variable suffix
    variable topology
    variable time 
    variable haveimportedchildren 0
    variable mgrid
    variable stray_cut_off
#    variable switches
    variable this [namespace current]
    variable known_flags " possible flags are: \n cluster_calc \n pik1_calc \n pressure_calc \n box_len_calc \n fluctuation_calc \n energy_calc \n stray_lipids_calc \n orient_order_calc \n flipflop_calc \n density_profile_calc \n localheights_calc \n localorients \n distance_calc \n tiltangle_calc \n "

    namespace export do_analysis
    namespace export setup_analysis
    namespace export print_averages
}

source [file join [file dirname [info script]] flipflop.tcl]
source [file join [file dirname [info script]] boxl.tcl]
source [file join [file dirname [info script]] clusters.tcl]
source [file join [file dirname [info script]] energy.tcl]
source [file join [file dirname [info script]] pressure.tcl]
source [file join [file dirname [info script]] pik1.tcl]
source [file join [file dirname [info script]] oop.tcl]
source [file join [file dirname [info script]] fluctuations.tcl]
source [file join [file dirname [info script]] stray.tcl]
source [file join [file dirname [info script]] density_profile.tcl]
source [file join [file dirname [info script]] localheights.tcl]
source [file join [file dirname [info script]] localorients.tcl]
source [file join [file dirname [info script]] distance.tcl]
source [file join [file dirname [info script]] tiltangle.tcl]


# ::mbtools::analysis::print_averages --
#
# Calculate averages for all analyzed quantities and put them to the
# appropriate file streams
#
proc ::mbtools::analysis::print_averages { } {

    ::mmsg::debug [namespace current] "printing averages"
    variable docommands
    variable time
    set time [setmd time]
    # Now run the setup commands for each of the required analysis commands
    set printavprefix "printav_"
    foreach command $docommands {
	set command [lindex [split $command " "] 0]
	# Construct the name of the printav command
	set printavcommand "$printavprefix$command"
	::mmsg::debug [namespace current] "executing $printavcommand"
	eval $printavcommand
    }

    reset_averages
    flush stdout
}


# ::mbtools::analysis::reset_averages --
#
# Reset all of the average storage variables and counters to zero
#   
#
# Note: Power analysis and densityprofiles are not reset since they
# generally require averages over the entire simulation. Flip-flop is
# also not reset since it should exponentially decay with time and is
# calculated from the entire simulation run.
#
proc ::mbtools::analysis::reset_averages { } {
    variable docommands

    # Now run the setup commands for each of the required analysis commands
    set resetavprefix "resetav_"
    foreach command $docommands {
	set command [lindex [split $command " "] 0]
	# Construct the name of the resetav command
	set resetavcommand "$resetavprefix$command"
	::mmsg::debug [namespace current] "executing $resetavcommand"
	eval $resetavcommand
    }
}

# ::mbtools::analysis::do_analysis --
#
# This is the routine that is typically called during the simulation
# after each integrate command.  It simply calls all of the
# appropriate analysis routines and stores the values in average
# storage variables
#
proc ::mbtools::analysis::do_analysis { } {
    variable docommands
    variable known_flags

 


    # Now run the setup commands for each of the required analysis commands
    set analyzeprefix "analyze_"
    foreach command $docommands {
	set command [lindex [split $command " "] 0]
	# Construct the name of the analyze command
	set analyzecommand "$analyzeprefix$command"
	::mmsg::debug [namespace current] "executing $analyzecommand"
	eval $analyzecommand
    }
    ::mmsg::debug [namespace current] "done"
    flush stdout
}

# ::mbtools::analysis::setup_analysis --
#
# This routine should be called  at the beginning of
# the simulation in order to setup all the appropriate variables that
# will later be used when do_analysis is called.
#
# Arguments:
#
#        commands: This argument should consist of a list of
#                    switches that determine which quantites should be
#                    analyzed 
#
proc ::mbtools::analysis::setup_analysis { commands args } {

    variable suffix
    variable iotype
    variable n_particles
    variable outputdir
    variable docommands
    variable haveimportedchildren
    variable mgrid
    variable stray_cut_off
    set docommands $commands

    ::mmsg::send [namespace current] "setting up analysis"

    set options {
	{outputdir.arg      "./"    "name of output directory " }
	{suffix.arg "tmp" "suffix to be used for outputfiles" }
	{iotype.arg "a" "the method with which to open existing analysis files"}
	{g.arg 8 "the grid size for fft dependent calculations"}
	{str.arg 4.0 "stray cut off distance"}
    }
    set usage "Usage: setup_analysis:outputdir:suffix:iotype:g:str "
    array set params [::cmdline::getoptions args $options $usage]

    set mgrid $params(g)
    set stray_cut_off $params(str)
    # Setup the grid just in case we need it
    analyze set_bilayer grid $mgrid $mgrid 0 stray $stray_cut_off


    # Calculate the total number of particles from topology
    set topo [analyze set]
    set n_particles 0
    foreach mol $topo {
	set n_particles [expr $n_particles + [llength $mol] -1]
    }

    set outputdir $params(outputdir)
    set topology $topo
    set iotype $params(iotype)
    set suffix "_$params(suffix)"

    # Import commands from all child namespaces 
    if (!$haveimportedchildren) {
	set children "[namespace children [namespace current]]"
	foreach child $children {
	    set child [namespace tail $child]
	    set setupstr "::*"
	    namespace import "$child$setupstr"
	}
    }

    # Now run the setup commands for each of the required analysis commands
    set setupprefix "setup_"
    foreach command $commands {
	# Construct the name of the setup command
	set setupcommand "$setupprefix$command"
	::mmsg::debug [namespace current] "executing $setupcommand"
	eval $setupcommand
    }

}
