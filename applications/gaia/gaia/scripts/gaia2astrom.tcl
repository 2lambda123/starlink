#!/bin/sh    
# The next line is executed by /bin/sh, but not Tcl \
TCL_LIBRARY=$GAIA_DIR; \
TCLX_LIBRARY=$GAIA_DIR; \
TK_LIBRARY=$GAIA_DIR; \
TKX_LIBRARY=$GAIA_DIR; \
ITCL_LIBRARY=$GAIA_DIR; \
ITK_LIBRARY=$GAIA_DIR; \
IWIDGETS_LIBRARY=$GAIA_DIR; \
RTD_LIBRARY=$GAIA_DIR; \
TCLADAM_DIR=$GAIA_DIR; \
TIX_LIBRARY=$GAIA_DIR; \
export TCL_LIBRARY; \
export TCLX_LIBRARY; \
export TK_LIBRARY; \
export TKX_LIBRARY; \
export ITCL_LIBRARY; \
export ITK_LIBRARY; \
export IWIDGETS_LIBRARY; \
export RTD_LIBRARY; \
export TCLADAM_DIR; \
export TIX_LIBRARY; \
exec $GAIA_DIR/gaia_wish $0 ${1+"$@"}
#+
#   Name:
#      gaia2astrom
#
#   Purpose:
#      Convert a GAIA WCS catalogue into an astrom file
#
#   Usage:
#      gaia2astrom input output
#
#   Description:
#      This commands converts a plain text file of the type produced
#      by the astrometry toolboxes in GAIA, into a file suitable 
#      for giving to ASTROM (SUN/5) to perform a "plate" solution.

#   Authors:
#      Peter W. Draper (PDRAPER):
#
#   History:
#      03-MAR-1999 (PDRAPER):
#         Original version.
#-
#.

#  Do not show the main window.
wm withdraw .

global argc
global argv

#  Get names of files.
if { $argc == 0 } { 
   puts -nonewline "Input file: "
   flush stdout
   gets stdin infile
} else {
   set infile [lindex $argv 0]
}
if { ! [file exists $infile] } { 
   puts stderr "Sorry file: $infile, does not exist"
   exit 1
}

if { $argc <= 1 } {
   puts -nonewline "Output file: "
   flush stdout
   gets stdin outfile
} else {
   set outfile [lindex $argv 1]
}

#  Open the files.
if { [catch "open $infile r" instr] } { 
   puts stderr "Failed to open input file: $infile ($instr)"
}
if { [catch "open $outfile w" outstr] } { 
   puts stderr "Failed to open output file: $infile ($outstr)"
}

#  Get the telescope type and the plate centre.
puts -nonewline "Telescope type (ASTR, SCHM, GENE etc):"
flush stdout
gets stdin telescope_type
set telescope_type [string toupper $telescope_type]
switch -exact $telescope_type {
   ASTR -
   SCHM -
   AAT2 -
   AAT3 -
   AAT8 -
   JKT8 -
   GENE {
   }
   default: {
      puts stderr "Unknown telescope type : $telescope_type"
      exit
   }
}
puts -nonewline "Plate centre (RA and Dec, J2000):"
flush stdout
gets stdin telescope_centre


#  Add the initialising commands to the output file. 
puts $outstr "J2000                               *Results in Fk5"
puts $outstr "$telescope_type                     *Telescope type"
puts $outstr "~ $telescope_centre J2000  2000     *Plate center"

#  Loop over the input file reading all the elements and writing them
#  back out as required. Keep a list of the RA and Decs to append as
#  results.
set coords ""
while { [gets $instr line] > -1 } { 
   set nitems [llength $line]
   if { $nitems > 0 } {
      foreach {id ra dec x y} $line {
         regsub -all {:} $ra { } ra
         regsub -all {:} $dec { } dec
         puts $outstr "$ra $dec J2000 2000"
         puts $outstr "$x $y"
         append coords "$ra $dec J2000 $id\n"
      }
   }
}
#  Add X and Y's
puts $outstr "$coords"
puts $outstr "END"
close $instr
close $outstr
exit
