# Copyright (C) 2010,2011 The ESPResSo project
# Copyright (C) 2002,2003,2004,2005,2006,2007,2008,2009,2010 
#   Max-Planck-Institute for Polymer Research, Theory Group
#  
# This file is part of ESPResSo.
#  
# ESPResSo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  
# ESPResSo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#  
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#

# check the charge-charge P3M algorithm
source "tests_common.tcl"

require_feature "ELECTROSTATICS"
require_feature "FFTW"
require_feature "MOL_CUT" off

puts "---------------------------------------------------------------"
puts "- Testcase p3m_wall.tcl running on [format %02d [setmd n_nodes]] nodes:"
puts "---------------------------------------------------------------"

set epsilon 1e-3
thermostat off
setmd time_step 0.01
setmd skin 0.05

set file "p3m_wall_system.data"
set f [open $file "r"]

while {![eof $f]} { blockfile $f read auto}
    close $f

for { set i 0 } { $i <= [setmd max_part] } { incr i } {
  set F($i) [part $i pr f]
}

# inter coulomb n_interpol 0
invalidate_system
integrate 0

    set rmsf 0
    set mult 0
    for { set i 0 } { $i <= [setmd max_part] } { incr i } {
	set resF [part $i pr f]
	set tgtF $F($i)
	set dx [expr abs(([lindex $resF 0] - [lindex $tgtF 0]))]
	set dy [expr abs(([lindex $resF 1] - [lindex $tgtF 1]))]
	set dz [expr abs(([lindex $resF 2] - [lindex $tgtF 2]))]

        set mult [expr $mult + abs([lindex $tgtF 0] / [lindex $resF 0])]

	set rmsf [expr $rmsf + $dx*$dx + $dy*$dy + $dz*$dz]
    }

    set mult [expr $mult/300.0]
    set rmsf [expr $rmsf / 300.0]
    puts "p3m-charges: rms force deviation $rmsf (mult $mult)"
    if { $rmsf > $epsilon } {
	error "p3m-charges: force error too large"
   }

puts [analyze energy]
