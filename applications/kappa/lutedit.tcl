#!/star/bin/awish
#+
#  Name:
#     LutEdit.tcl
#
#  Purpose:
#     The Tcl script which implements the bulk of the LUTEDIT command.
#
#  Type of module:
#     Tk/Tcl script.
#
#  Description:
#     This script displays an image using a specified lut and then allows
#     the user to interactively edit the colour table in various ways.
#     The modified colour table may be saved in an NDF which can later be
#     used by LUTABLE, etc.
#     
#     The LUTABLE a-task should normally be used to execute this script.
#
#  Usage:
#     lutedit.tcl lut image
#
#  Arguments:
#     lut 
#        The file containing the initial lookup table.  The supplied string
#        is not validated. If not supplied on the command line, the
#        current colour table used by KAPPA for GWM xwindows devices is
#        used.
#     image 
#        The image to be displayed. If not supplied, $KAPPA_DIR/m31 is
#        used.
#
#  Authors:
#     DSB: David Berry (STARLINK)
#     {enter_new_authors_here}
#
#  History:
#     16-NOV-2001 (DSB):
#	 Original version.
#     {enter_further_changes_here}
#
#-

# Define procedures...

proc addHelp {helpmenu} {
#
#  Add items to the help menu.
#
   global KAPPA_DIR
   global HELPTEXT

#  Add elements to the HELPTEXT global array with names equal tot he help
#  topics, and values equal tot he associated text.
   set f [open $KAPPA_DIR/lutedit.help]
   set name ""
   while { [gets $f tx] != -1 } {   
      if { [regexp {^o (.*):$} $tx match ttl] } {
         set name $ttl
         set HELPTEXT($name) ""
      } else {
         if { $tx == "" } { set tx "\n\n" }
         lappend HELPTEXT($name) $tx
      }
   }
   close $f

#  Add sorted items to the help menu
   foreach topic [lsort [array names HELPTEXT]] {
      $helpmenu add command -label $topic -command "showHelp \"$topic\"" 
   }

}

proc showHelp {topic} {
#
#  Display help information
#
   global HELPTEXT
   global HTEXT

# If necessary, create the top level window for the dialogue box.
   set top .helpwin
   if { ![winfo exists $top] } {
      set topf [MakeDialog $top "LutEdit help" 0]

#  Create a text widget tot display the text, with a scroll bar.
      set scroll "$topf.scroll"
      set HTEXT [text $topf.help -relief flat -wrap word -highlightthickness 0 -yscrollcommand "$scroll set"]
      scrollbar $scroll -command "$HTEXT yview"
      pack $scroll -side right -fill y
      pack $HTEXT -side left -fill both -expand 1 -padx 5m -pady 5m
   }

#  Empty the text widget.
   $HTEXT delete 1.0 end

#  Add a title
   $HTEXT insert end "\n"
   $HTEXT insert end $topic
   $HTEXT tag add topic 2.0 2.end
   $HTEXT tag configure topic -underline 1 
   $HTEXT insert end "\n"

#  Load in the requested help.
   foreach line $HELPTEXT($topic) {
      $HTEXT insert end "$line "
   }
}

proc saveOpts {} {
#
# Save the current settings in the options menu.
#
   global INITRC 
   global AUTOUP
   global CSYS 
   global CSYSNOW 
   global NN
   global AUTOCUT
   global NEGIMAGE
   global HISTXLAB
   global LOGPOP

   set rc [open $INITRC "w"]
   puts $rc "set AUTOUP $AUTOUP"
   puts $rc "set CSYS $CSYS"
   puts $rc "set CSYSNOW $CSYS"
   puts $rc "set NN $NN"
   puts $rc "set AUTOCUT $AUTOCUT"
   puts $rc "set NEGIMAGE $NEGIMAGE"
   puts $rc "set HISTXLAB $HISTXLAB"
   puts $rc "set LOGPOP $LOGPOP"
   puts $rc "newCsys"
   puts $rc "histStyle 0"
   close $rc
}

proc resample {} {
# 
#  Change the number of entries in the table.
#
   global CAN2
   global CPEN
   global CTRL
   global CURX 
   global EX0 
   global HENTRY
   global LP
   global LUT
   global MENT
   global NENT
   global NENTM1
   global NN
   global PPENT 
   global RSENT
   global RSINT
   global UP

   set type(RSENT) "_INTEGER"
   set type(RSINT) "_CHOICE"
   set lab(RSENT) "Number of entries in new colour table"
   set lab(RSINT) "Interpolation method"
   set lim(RSENT) [list 2 256]
   set lim(RSINT) [list "Linear" "Nearest Neighbour"]

   if { ![info exists RSENT] } { set RSENT $NENT }
   if { ![info exists RSINT] } { 
      if { $NN == "NO" } {
         set RSINT "Linear"
      } else {
         set RSINT "Nearest Neighbour"
      }
   }

   if { [GetPars [list RSENT RSINT] type lab lim "LUTEDIT - Resample" "" "Specify the parameters for the resampling operation" ] } {

#  For an new fractional entry value of EXnew, the corresponding old
#  fractional entry value is EXold = EXnew*delta.
      set delta [expr double($NENTM1)/double($RSENT - 1.0)]

      set nr ""
      set ng ""
      set nb ""

#  Nearest neighbour interpolation...
      if { $RSINT == "Nearest Neighbour" } {
         for { set i 0} {$i < $RSENT} {incr i} {
            set j [expr round($i*$delta)]
            lappend nr [lindex $LUT(red) $j]
            lappend ng [lindex $LUT(green) $j]
            lappend nb [lindex $LUT(blue) $j]
         }

#  Linear interpolation...
      } else {
         for { set i 0} {$i < $RSENT} {incr i} {
            set fe [expr $i*$delta]
            if { $fe > $NENTM1 } {
               set fe $NENTM1
            } elseif { $fe < 0 } {
               set fe 0
            }
            set j [expr round($fe)]
            set d [expr $fe - $j]

            if { ($j != $NENTM1 && $d > 0 ) || $j == 0 } {
               set elo $j
            } else {
               set elo [expr $j - 1]
            }
            set ehi [expr $elo + 1]

            set clo [lindex $LUT(red) $elo]
            set chi [lindex $LUT(red) $ehi]
            lappend nr [expr abs(($chi-$clo)*($fe-$elo)+$clo)]

            set clo [lindex $LUT(green) $elo]
            set chi [lindex $LUT(green) $ehi]
            lappend ng [expr abs(($chi-$clo)*($fe-$elo)+$clo)]

            set clo [lindex $LUT(blue) $elo]
            set chi [lindex $LUT(blue) $ehi]
            lappend nb [expr abs(($chi-$clo)*($fe-$elo)+$clo)]
         }
      }

#  The marked and selected entries, and the control points are deifned in
#  terms of entry numbers and so cannot be retained, so clear them.
      set MENT ""
      updateMark 1

      set HENTRY ""
      select

      set CTRL(red) ""
      set CTRL(blue) ""
      set CTRL(green) ""

#  The cursor position is defined as a pen number and so can be retained. Save
#  the current cursor position before deleting it.
      set cpen $CPEN
      set CPEN ""
      updateCursor 1

#  Clear the editor canvas
      $CAN2 delete all

#  Store new globals.
      set NENT $RSENT
      set NENTM1 [expr $RSENT-1]
      set PPENT [format "%.2f" [expr double($UP-$LP+1)/double($NENT)]]
      set LUT(red) $nr
      set LUT(green) $ng
      set LUT(blue) $nb

#  Calculate new transformations.
      set EX0 ""
      set CURX ""
      setTrans

#  Restore the original cursor position.
      set CPEN $cpen
      updateCursor 1

#  Update the editor to display the new colour table.
      updateDisplay 0

#  Record the changes on the undo stack.
      record

   }
}

proc select {} {
#
#  Create a rectangle marking the currently selected entries.
#
   global CAN2
   global SELID
   global LENTRY
   global HENTRY
   global XE0
   global XE1
   global CURY1
   global CURY2
   global BACKCOL

   if { $LENTRY == "" || $HENTRY == "" } {
      $CAN2 delete $SELID

   } else {
      set cxl [expr $XE0+$XE1*($LENTRY-0.5)]
      set cxh [expr $XE0+$XE1*($HENTRY+0.5)]

      if { $SELID != "" } {
         $CAN2 coords $SELID $cxl $CURY1 $cxh $CURY2
      } else {
         set SELID [$CAN2 create rectangle $cxl $CURY1 $cxh $CURY2 -outline "" -fill $BACKCOL]
         $CAN2 lower $SELID
      }
   }
}

proc rotate {} {
#
#  Shift the selected entries left or right by a given number of pens.
#  Entries which are shifted out of the selected range are fed back in
#  at the other end of the selected range. If there is currently no
#  selection, use the whole table.
#
   global LENTRY
   global HENTRY
   global RGBNOW
   global LUT
   global NENTM1
   global SHIFT
   global PPENT

   set type(SHIFT) "_INTEGER"
   set lab(SHIFT) "Number of pens by which to to rotate (+ve or -ve)"
   set lim(SHIFT) [list -256 256]
   if { ![info exists SHIFT] } { set SHIFT 0 }

   if { [GetPars [list SHIFT] type lab lim "LUTEDIT - Rotate" "" "Specify the parameters for the rotate operation" ] } {

      if { $HENTRY == "" } {
         set hi $NENTM1
      } else {
         set hi $HENTRY
      }

      if { $LENTRY == "" } {
         set lo 0
      } else {
         set lo $LENTRY
      }

#  Find the equivalent positive number of entries by which to shift.
      set ne [expr $hi-$lo+1]
      set s [expr round(fmod(round($SHIFT/$PPENT),$ne))]
      if { $s < 0 } { incr s $ne }
      
#  Find the original index for the new top entry.
      if { $s > 0 } {
         set l [expr $hi-$s]

#  Split the original entries into two groups, swap them round and join
#  them together again.
         set loents [lrange $LUT($RGBNOW) $lo $l]
         set hients [lrange $LUT($RGBNOW) [expr $l+1] $hi] 
         set newents [join [concat $hients $loents]]
         set LUT($RGBNOW) [eval lreplace {$LUT($RGBNOW)} $lo $hi  $newents]
         updateCurrent
         record
      }
   }
}

proc bridge {} {
#
#  Replace the currently selected pens by joining the first and the last
#  with a straight line.
#
   global LENTRY
   global HENTRY
   global RGBNOW
   global LUT

   if { $HENTRY == "" || $LENTRY == "" } {
      Message "No pens are currently selected. Drag the cursor to select pens."

   } else {
      set vl [lindex $LUT($RGBNOW) $LENTRY]
      set d [expr ([lindex $LUT($RGBNOW) $HENTRY] - $vl)/($HENTRY-$LENTRY)]

      set f [expr $LENTRY+1]
      set l [expr $HENTRY-1]
      set new ""
      for {set i $f } {$i <= $l} {incr i} {
         set vl [expr $vl + $d]
         append new "$vl "
      }
      if { $new != "" } {
         set LUT($RGBNOW) [eval lreplace {$LUT($RGBNOW)} $f $l $new]
      }

      updateCurrent
      record

   }
}

proc flip {all} {
#
#  Flip the selected pens horizontally. If there is currently no
#  selection, use the whole table. If $all is zero, just flip the current
#  curve. Otherwise flip all curves.
#
   global LENTRY
   global HENTRY
   global RGBNOW
   global LUT
   global NENTM1
   global SHIFT
   global PPENT

   if { $HENTRY == "" } {
      set hi $NENTM1
   } else {
      set hi $HENTRY
   }

   if { $LENTRY == "" } {
      set lo 0
   } else {
      set lo $LENTRY
   }

   if { $all } {
      set newr ""
      set newg ""
      set newb ""
      for { set i $hi } { $i >= $lo } { incr i -1 } {
         append newr "[lindex $LUT(red) $i] "
         append newg "[lindex $LUT(green) $i] "
         append newb "[lindex $LUT(blue) $i] "
      }
      set LUT(red) [eval lreplace {$LUT($RGBNOW)} $lo $hi  $newr]
      set LUT(green) [eval lreplace {$LUT($RGBNOW)} $lo $hi  $newg]
      set LUT(blue) [eval lreplace {$LUT($RGBNOW)} $lo $hi  $newb]
      updateDisplay 0

   } else {
      set new ""
      for { set i $hi } { $i >= $lo } { incr i -1 } {
         append new "[lindex $LUT($RGBNOW) $i] "
      }
      set LUT($RGBNOW) [eval lreplace {$LUT($RGBNOW)} $lo $hi  $new]
      updateCurrent

   }

   record
}


proc setCon {} {
#
#  Set the currently selected pens to a user-specified constant value.
#
   global LENTRY
   global HENTRY
   global RGBNOW
   global LUT
   global CONST
 
   set type(CONST) "_REAL"
   set lab(CONST) "The constant value"
   set lim(CONST) [list 0.0 1.0]
   if { ![info exists CONST] } { set CONST 0.0 }

   if { $HENTRY == "" || $LENTRY == "" } {
      Message "No pens are currently selected. Drag the cursor to select pens."

   } elseif { [GetPars [list CONST] type lab lim "LUTEDIT - Set Constant" "" "Specify the parameters for the operation" ] } {
      set new ""
      for {set i $LENTRY} {$i <= $HENTRY} {incr i} {
         append new "$CONST "
      }
      if { $new != "" } {
         set LUT($RGBNOW) [eval lreplace {$LUT($RGBNOW)} $LENTRY $HENTRY $new]
      }

      updateCurrent
      record

   }
}
proc smooth {} {
#
#  Smooths the currently selected pens using a box filter of a specified
#  width.
#
   global LENTRY
   global HENTRY
   global RGBNOW
   global LUT
   global WID
   global PPENT
   global NENT
   global NENTM1
 
   set type(WID) "_INTEGER"
   set lab(WID) "The number of pens across the filter box"
   set lim(WID) [list [expr round($PPENT)+1] $NENT]
   if { ![info exists WID] } { set WID [expr 5*$PPENT] }

   if { $HENTRY == "" || $LENTRY == "" } {
      Message "No pens are currently selected. Drag the cursor to select pens."

   } elseif { [GetPars [list WID] type lab lim "LUTEDIT - Smooth" "" "Specify the parameters for the operation" ] } {

#  Find the half width of the filter as a number of entries.
      set hw [expr round($WID/$PPENT)/2]
      if { $hw > 0 } { 

         set lp [expr $LENTRY-$hw]
         set up [expr $LENTRY+$hw]
         if { $lp < 0 } { set lp 0 } elseif { $lp > $NENTM1 } { set $lp $NENTM1 }
         if { $up < $lp } { set up $lp } elseif { $up > $NENTM1 } { set $up $NENTM1 }

         set sm 0.0
         set nm 0
         for {set i $lp} { $i <= $up } {incr i} {
            if { $i >= $LENTRY && $i <= $HENTRY } {
               set sm [expr $sm + [lindex $LUT($RGBNOW) $i]]
               incr nm
            }
         }

         set new "[expr $sm/$nm] "
         for {set i [expr $LENTRY +1] } {$i <= $HENTRY} {incr i} {
            if { $lp >= $LENTRY && $lp <= $HENTRY } {
               set sm [expr $sm - [lindex $LUT($RGBNOW) $lp]]
               incr nm -1
            }
            incr lp

            incr up
            if { $up >= $LENTRY && $up <= $HENTRY } {
               set sm [expr $sm + [lindex $LUT($RGBNOW) $up]]
               incr nm
            }

            if { $nm > 0 } {
               append new "[expr $sm/$nm] "
            } else {
               append new "[lindex $LUT($RGBNOW) $i] "
            }
         }

         if { $new != "" } {
            set LUT($RGBNOW) [eval lreplace {$LUT($RGBNOW)} $LENTRY $HENTRY $new]
            updateCurrent
            record
         }
      }
   }
}

proc newCsys {} {
#
#  Arrange for the editor to show colours using either RGB, MONO or HSV values.
#  CSYS=MONO is like using HSV with S==0.
#
   global CSYS
   global CTRL
   global CSYSNOW
   global RB
   global GB
   global BB
   global LUT
   
   if { $CSYS == "RGB" } {
      $RB configure -text Red -state normal
      SetHelp $RB "Press to edit the red intensity curve..." LUTEDIT_RB
      SetHelp c-red "A curve showing the red intensity at each pen."
      $GB configure -text Green -state normal
      SetHelp $GB "Press to edit the green intensity curve..." LUTEDIT_RB
      SetHelp c-green "A curve showing the green intensity at each pen."
      $BB configure -text Blue -state normal
      SetHelp $BB "Press to edit the blue intensity curve..." LUTEDIT_RB
      SetHelp c-blue "A curve showing the blue intensity at each pen."
   } elseif { $CSYS == "HSV" } {
      $RB configure -text Hue -state normal
      SetHelp $RB "Press to edit the hue curve (0.0=red 0.33=green 0.67=blue)..." LUTEDIT_RB
      SetHelp c-red "A curve showing the hue at each pen (0.0=red 0.33=green 0.67=blue)."
      $GB configure -text Saturation -state normal
      SetHelp $GB "Press to edit the saturation curve (0.0=grey 1.0=full colour)..." LUTEDIT_GB
      SetHelp c-green "A curve showing the saturation at each pen (0.0=grey 1.0=full colour)."
      $BB configure -text Value -state normal
      SetHelp $BB "Press to edit the value curve..." LUTEDIT_BB
      SetHelp c-blue "A curve showing the value (roughly equivalent to the brightness) at each pen."
   } elseif { $CSYS == "MONO" } {
      $RB configure -text "" -state disabled
      SetHelp $RB "Unused in monochrome mode" LUTEDIT_GB
      SetHelp c-red "A curve showing the monochrome value at each pen."
      $GB configure -text "" -state disabled
      SetHelp $GB "Unused in monochrome mode" LUTEDIT_GB
      SetHelp c-green ""
      $BB configure -text "" -state disabled
      SetHelp $BB "Unused in monochrome mode" LUTEDIT_BB
      SetHelp c-blue ""

   }

   if { $CSYS != $CSYSNOW } {
      toCSYS LUT $CSYSNOW 
      set CSYSNOW $CSYS
      if { $CSYS == "MONO" } {
         set CTRL(green) ""
         set CTRL(blue) ""
      }
      updateEditor
      if { $CSYS == "MONO" } { gwmUpdate 0 }
   }
}

proc toRGB {a now} {
#
#  $a is the name of a global array with three elements named "red",
#  "green" and "blue". On exit, they are changed so that
#  (red) holds red intensity, (green) holds green intensity and (blue)
#  holds blue intensity. All these intensities are in the range 0 to 1.
#
#  $now is one of RGB, HSV or MONO and gives the system in which $a is
#  supplied.
#

   upvar $a lut

   if { $now == "MONO" } { 
      set lut(green) $lut(red)
      set lut(blue) $lut(red)

   } elseif { $now == "HSV" } { 
      set red ""
      set green ""
      set blue ""
      set n [llength $lut(red)]
      for {set j 0} {$j < $n} {incr j} {
         set h [expr [lindex $lut(red) $j]*6.0]
         set s [lindex $lut(green) $j]
         set v [lindex $lut(blue) $j]
   
         if { $s == 0 } {
            set r $v
            set g $v
            set b $v
   
         } else {
            set i [expr int($h)]
            set f [expr $h - $i]
            set p [expr $v*(1-$s)]
            set q [expr $v*(1-$s*$f)]
            set t [expr $v*(1-$s*(1-$f))]
            if { $i == 0 } {
               set r $v
               set g $t
               set b $p
   
            } elseif { $i == 1 } {
               set r $q
               set g $v
               set b $p
   
            } elseif { $i == 2 } {
               set r $p
               set g $v
               set b $t
   
            } elseif { $i == 3 } {
               set r $p
               set g $q
               set b $v
   
            } elseif { $i == 4 } {
               set r $t
               set g $p
               set b $v
   
            } else {
               set r $v
               set g $p
               set b $q
            }
         }         
   
         if { $r < 0.0 } { set r 0.0 } elseif { $r > 1.0 } { set r 1.0 }
         if { $g < 0.0 } { set g 0.0 } elseif { $g > 1.0 } { set g 1.0 }
         if { $b < 0.0 } { set b 0.0 } elseif { $b > 1.0 } { set b 1.0 }
   
         lappend red $r
         lappend green $g
         lappend blue $b
      }
      set lut(red) $red
      set lut(green) $green
      set lut(blue) $blue
   }
}

proc toHSV {a now} {
#
#  $a is the name of a global array with three elements named "red",
#  "green" and "blue". On exit, they are changed so that
#  (red) holds hue values, (green) holds saturation values and (blue)
#  holds intensity values. All these HSV are in the range 0 to 1.
#  Hue is represented by a value in the range 0 to 1.0, with red at 
#  0 (or 1), green at 0.3333, and blue at 0.6667.
#
#  $now is one of RGB, HSV or MONO and gives the system in which $a is
#  supplied.
#
   upvar $a lut
   if { $now == "MONO" } {
      set lut(blue) $lut(red)
      set lut(green) ""
      set lut(red) ""

      set n [llength $lut(blue)]
      for {set j 0} {$j < $n} {incr j} {
         lappend lut(red) 0.0
         lappend lut(green) 0.0
      }

   } elseif { $now == "RGB" } {
      set hue ""
      set sat ""
      set int ""
      set n [llength $lut(red)]
      for {set j 0} {$j < $n} {incr j} {
         set r [lindex $lut(red) $j]
         set g [lindex $lut(green) $j]
         set b [lindex $lut(blue) $j]
   
         set sr [lsort -real [list $r $g $b]]
         set ma [lindex $sr 2]
         set mi [lindex $sr 0]
   
         set v $ma
   
         set delta [expr $ma - $mi]
         if { $ma > 0 } {
            set s [expr $delta/$ma]
   
            if { $delta > 0 } {
   
               if { $r == $ma } {
                  set h [expr (($g-$b)/$delta)/6.0]
               } elseif { $g == $ma } {
                  set h [expr (2+($b-$r)/$delta)/6.0]
               } else {
                  set h [expr (4+($r-$g)/$delta)/6.0]
               }
   
               if { $h < 0.0 } { set h [expr $h+1.0] }
   
            } else {
               set h 0 
            }
   
         } else {
            set s 0
            set h 0
         }
   
         lappend hue $h
         lappend sat $s
         lappend int $v
      }
   
      set lut(red) $hue
      set lut(green) $sat
      set lut(blue) $int
   }
}

proc toMONO {a now} {
#
#  $a is the name of a global array with three elements named "red",
#  "green" and "blue". On exit, they are changed so that (red) holds 
#  monochrome value, (green) and (blue) hold 0.
#
#  $now is one of RGB, HSV or MONO and gives the system in which $a is
#  supplied.
#
   upvar $a lut
   if { $now == "RGB" } {
      set v ""
      set dummy ""
      set n [llength $lut(red)]
      for {set j 0} {$j < $n} {incr j} {
         set r [lindex $lut(red) $j]
         set g [lindex $lut(green) $j]
         set b [lindex $lut(blue) $j]
         lappend v [expr ($r+$g+$b)/3.0]
         lappend dummy 0.0
      }
      set lut(red) $v
      set lut(green) $dummy
      set lut(blue) $dummy
   
   } elseif { $now == "HSV" } {
      set dummy ""
      set n [llength $lut(red)]
      for {set j 0} {$j < $n} {incr j} {
         lappend dummy 0.0
      }
      set lut(red) $lut(blue)
      set lut(green) $dummy
      set lut(blue) $dummy
   }
}

proc toCSYS {a now} {
#
#  $a is the name of a global array with three elements named "red",
#  "green" and "blue". On exit, they are changed to the system specified
#  by global $CSYS.
#
#  $now is one of RGB, HSV or MONO and gives the system in which $a is
#  supplied.
#
   global CSYS
   upvar $a lut

   if { $CSYS == "MONO" } {
      toMONO lut $now
   } elseif { $CSYS == "RGB" } {
      toRGB lut $now
   } elseif { $CSYS == "HSV" } {
      toHSV lut $now
   }
}

proc setCursor {} {
#  
#  Set up the correct cursor whenever a new item is entered 
#  in the editor window.
#
   global CAN2
   global CURTAGS
   global CURSORS
   global CFREEZE

   if { ! $CFREEZE } {
      set cur ""
      foreach tag [$CAN2 gettags current] {
         set i [lsearch -exact $CURTAGS $tag]
         if { $i != -1 } {
            set cur [lindex $CURSORS $i]
            break
         }
      }
      $CAN2 config -cursor $cur
   }
}


proc dpoint {all} {
#
#  Delete 1, or all control points for the current curve.
#

   global CAN2
   global CTRL
   global CENT
   global RGBNOW
   global CPIM
   global EVAL
   global XE0
   global XE1
   global YOFF
   global YSCALE

   if { $all } {
      $CAN2 delete cp-$RGBNOW
      set CTRL($RGBNOW) ""

   } elseif { $CTRL($RGBNOW) != "" } {

      set i 0
      set errl 1000000
      foreach e $CTRL($RGBNOW) {
         set err [expr abs($e - $CENT)]
         if { $err > $errl } {
            break
         } 
         set errl $err
         incr i
         set el $e
      }
      incr i -1
      set CTRL($RGBNOW) [lreplace $CTRL($RGBNOW) $i $i]
      $CAN2 delete cp-$RGBNOW-$el
   }

}

proc cpoint {} {
#
#  Add a control point to the current curve at the entry closest to the
#  cursor.
#
   global CAN2
   global CTRL
   global CENT
   global RGBNOW
   global CPIM
   global EVAL
   global XE0
   global XE1
   global YOFF
   global YSCALE

   if { [lsearch -exact $CTRL($RGBNOW) $CENT] == -1 } {
      lappend CTRL($RGBNOW) $CENT
      set CTRL($RGBNOW) [lsort -integer $CTRL($RGBNOW)]
      $CAN2 create image [expr $XE0+$XE1*$CENT] [expr $YOFF-$EVAL*$YSCALE] -image $CPIM -tags [list cp cp-$RGBNOW cp-$RGBNOW-$CENT ]
      updateCursor 2
   } else {
      Message "There is already a control point at this position."
   }
}

proc Read {conf} {
#
#  Read the current GWM colour table into the editor.
#
   global LUTFILE
   global KEEPFILE
   global UWIN

   if { !$conf || [Saver] } { 
      set tfile [UniqueFile]
      Obey kapview lutsave "lut=\! logfile=$tfile" 1
      textLut $tfile
      file delete -force $tfile   
      if { !$KEEPFILE } { 
         set LUTFILE ""
         set KEEPFILE 0
         wm  title $UWIN "LutEdit <untitled>"
      } else {
         wm  title $UWIN "LutEdit $LUTFILE"
      }
      orig
      updateDisplay -1
   }
}

proc linesplit {a l} {
#
#  Add newlines to a string so that no single line is longer than $l
#  characters.
#
   set r ""
   set s 0
   foreach n [split $a] {
      set w [string trim $n]
      if { $w != "" } {
         append w " "
         set len [string length $w]
         if { $s + $len > $l } {
            append r "\n"
            set s 0
         }            
         append r $w
         incr s $len
      }         
   }
   return $r
}

proc updateZoom {} {
#
#  Sets the current transformations using the current zoom factors, and
#  then redraws the editor using the new zoom factors.
#
   setTrans
   updateEditor
}

proc updateMark {useent} {
#
#  Ensure the mark is displayed correctly. If $useent is non-zero,
#  then the current value of global MENT (marked entry index) is used to 
#  set the other mark parameters, and the mark is re-drawn. If $useent
#  is zero, then the coordinates of currently drawn mark is used to set the 
#  other mark parameters, and the mark is NOT re-drawn. 
#
   global CAN2
   global MENT
   global XE0
   global XE1
   global YOFF
   global YSCALE
   global LUT
   global RGBNOW   
   global MARKID
   global CXL
   global CXH

   if { $useent } {

#  If the marked entry is blank, ensure no mark is displayed.
      if { $MENT == "" } {
         $CAN2 delete mark
         set MARKID ""
      } else {

#  Get the canvas X values at the ends of the marked entry.
         set cx1 [expr $XE0 +$XE1*($MENT-0.5)]
         set cx2 [expr $XE0 +$XE1*($MENT+0.5)]
         if { $cx1 < $CXL } { set cx1 $CXL }
         if { $cx2 > $CXH } { set cx2 $CXH }

#  Find the canvas Y value for this segment.
         set cy [expr $YOFF - $YSCALE*[lindex $LUT($RGBNOW) $MENT]]
 
#  Create or move the marker.
         if { $MARKID == "" } {
            set MARKID [$CAN2 create line $cx1 $cy $cx2 $cy -width 3 -fill black -tags mark]
         } else {
            $CAN2 coords $MARKID $cx1 $cy $cx2 $cy 
            $CAN2 raise $MARKID
         }
     
      }        

#  Otherwise, find the index of the currently marked entry from the
#  displayed mark.
   } else {
      if { $MARKID == "" } {
         set MENT ""
      } else {
         set co [$CAN2 coords $MARKID] 
         set x [expr 0.5*( [lindex $co 0] + [lindex $co 2] )]
         set MENT [expr round( $EX0+$EX1*$x )]
      }
   }
}

proc updateCursor {usepen} {
#
#  Ensure the cursor is displayed correctly. If $usepen is 1, then the 
#  current value of global CPEN (current pen index) is used to set the 
#  other cursor parameters, and the cursor is re-drawn. If $usepen is 2,
#  then the current value of global CENT (current entry index) is used to 
#  set the other cursor parameters, and the cursor is re-drawn. If $usepen 
#  is zero, then the current value of global CURX (canvas X position of 
#  the cursor line) is used to set the other cursor parameters, and the 
#  cursor is NOT re-drawn. 
#
   global CAN2
   global CENT
   global CPEN
   global CURSID
   global CURX
   global CURY1
   global CURY2
   global EVAL
   global EX0
   global EX1
   global LP
   global LUT
   global MARKID
   global MENT
   global PPENT
   global PVAL
   global PX0
   global PX1
   global RGBNOW
   global UP
   global XE0
   global XE1
   global XP0
   global XP1

   set oldcent $CENT

#  Set the other globals from CPEN or CENT and redraw the cursor...
   if { $usepen } {

#  If no pen or entry is defined, erase any cursor.
      if { ( $CPEN == "" && $usepen == 1 ) || ( $CENT == "" && $usepen == 2 ) } {
         $CAN2 delete pcurs
         set CURSID ""
         set CURX ""
         set CENT ""
         set CPEN ""
         set PVAL ""
         set EVAL ""
        
      } else {

#  If using the current entry, find the corresponding cursor x value.
         if { $usepen == 2 } {
            set x [expr $XE0+$XE1*$CENT]

#  If using the current pen, find the corresponding cursor x value.
         } else {
            set x [expr $XP0+$XP1*$CPEN]
         }

#  Calculate the pen and entry number and intensity from the cursor X position.
         cintCent $x

#  Calculate the new cursor X position from the updated pen index
         set CURX [expr $XP0+$XP1*$CPEN]

#  Either create or reconfigure the cursor to have these values.
         if { $CURSID != "" } {
            $CAN2 coords $CURSID $CURX $CURY1 $CURX $CURY2
            $CAN2 raise $CURSID
         } else {
            set CURSID [$CAN2 create line $CURX $CURY1 $CURX $CURY2 -fill white -tags pcurs]
         }
      }

#  Set the other globals from CURX and do not redraw the cursor...
   } else {
      if { $CURX == "" } {
         $CAN2 delete pcurs
         set CURSID ""
         set CPEN ""
         set CENT ""
         set PVAL ""
         set EVAL ""
      } else {
         cintCent $CURX
      }
   }

   if { $CENT != $oldcent } {
      set MENT $CENT
      updateMark 1
   } else {
      $CAN2 raise $MARKID
   }
   
}

proc updateCurrent {} {
# 
#  Ensure changes to the currently selected curve are correctly reflected
#  in the editor and the GWM items.
#
   global RGBNOW 
   global AUTOUP

   drawCurve $RGBNOW
   rgbSel
   updateCursor 1
   updateMark 1
   if { $AUTOUP } { gwmUpdate 0 }

}

proc cintCent {x} {
#
#  Set the index of the current table entry (CENT), pen (CPEN, and the 
#  current intensity (PVAL and EVAL), using the specified X canvas coord.
#
   global CENT
   global CPEN
   global PVAL
   global EVAL
   global EX0
   global EX1
   global PX0
   global PX1
   global XP0
   global XP1
   global XE0
   global XE1
   global LUT
   global PPENT
   global RGBNOW
   global NENT
   global NENTM1
   global NN
   global LP
   global UP

   if { $x != "" } {

#  Find the fractional entry, and then find the corresponding integer
#  (i.e. nearest) entry.
      set fe [expr $EX0+$EX1*$x]
      if { $fe < 0 } { 
         set fe 0
      } elseif { $fe > $NENTM1 } {
         set fe $NENTM1
      }
      set CENT [expr round($fe)]       

#  If there are more entries than pens, find the fractional pen value
#  which corresponds to the entry centre.
      if { $PPENT < 1.0 } {
         set CPEN [format "%.2f" [expr $PX0+$PX1*($XE0+$XE1*$CENT)]]

#  Otherwise (i.e. more pens than entries), find the nearest pen centre to the
#  supplied X value.
      } else {
         set CPEN [expr round($PX0+$PX1*$x)]
      }

#  Limit the pen to legal values.
      if { $CPEN < $LP } {
         set CPEN $LP
      } elseif { $CPEN > $UP } {
         set CPEN $UP
      }

#  Find the value of the current entry.
      set EVAL [format "%.3f" [lindex $LUT($RGBNOW) $CENT]]

#  For nearest neighbour interpolation, the pen value is the same as the
#  entry value.
      if { $NN != "NO" } {
         set PVAL $EVAL

#  Otherwise use linear interpolation between the table entries.
      } else {
         set d [expr $fe - $CENT]

         if { ($CENT != $NENTM1 && $d > 0 ) || $CENT == 0 } {
            set elo $CENT
         } else {
            set elo [expr $CENT - 1]
         }
         set ehi [expr $elo + 1]
         set clo [lindex $LUT($RGBNOW) $elo]
         set chi [lindex $LUT($RGBNOW) $ehi]

         set PVAL [format "%.3f" [expr abs(($chi-$clo)*($fe-$elo)+$clo)]]
      }
   }
}

proc Saver {} {
#
#  If the current LUT has not been saved, allow the user to save it.
#  Returns zero if the following operation should be cancelled.
# 
   set ok 1
   if { [changed] } {

# Display the dialog box and get the user's response.
      set but [dialog .confirm "LutEdit Confirmation" "Current LUT has not been saved. Save it now?" {} 0 Yes No Cancel]

# "YES" - just save it and return 1.
      if { $but == 0 } {
         Save 0

# "Cancel" - return 0.
      } elseif { $but == 2 } {
         set ok 0
      }
   }
   return $ok
}

proc orig {} {
#
#  Save the current LUT arrays as the "originals". When the editor is
#  closed, the final LUT arrays are compared with these originals to see if
#  there are any changes to save. Also initializes the undo stack.
#
   global ROLD
   global GOLD
   global BOLD
   global SOLD
   global LUT
   global NOLD
   global NEW
   global CSYSNOW

   set NEW 0

   catch {unset ROLD}
   catch {unset GOLD}
   catch {unset BOLD}

   set ROLD(orig) $LUT(red) 
   set GOLD(orig) $LUT(green) 
   set BOLD(orig) $LUT(blue) 
   set SOLD(orig) $CSYSNOW

   set NOLD 0
   record
}

proc changed {} {
#
#  Returns 1 if the current LUT arrays differ from the "originals".
#
   global ROLD
   global GOLD
   global BOLD
   global SOLD
   global LUT
   global NEW
   global CSYSNOW
   global NENT

   if { $NEW } {
      set changed 1

   } elseif { $NENT != [llength $ROLD(orig)] } {
      set changed 1

   } else {
      set orig(red) $ROLD(orig)
      set orig(green) $GOLD(orig)
      set orig(blue) $BOLD(orig)

      toCSYS orig $SOLD(orig) 

      if { $orig(red) != $LUT(red) ||
           $orig(green) != $LUT(green) ||
           $orig(blue) != $LUT(blue) } {
         set changed 1

      } else {
         set changed 0
      }

   }

   return $changed
}


proc record {} {
#
#  Called after a change has been made to the LUT arrays.
#  The new LUT arrays are stored on the top of the undo stack.
#
   global ROLD
   global GOLD
   global BOLD
   global NOLD
   global SOLD
   global LUT
   global CSYSNOW

   incr NOLD
   set ROLD($NOLD) $LUT(red)
   set GOLD($NOLD) $LUT(green)
   set BOLD($NOLD) $LUT(blue)
   set SOLD($NOLD) $CSYSNOW

   set rid [expr $NOLD - 10]
   catch { unset ROLD($rid) GOLD($rid) BOLD($rid) SOLD($rid)}

}

proc undo {} {
#
#  If possible, remove the top entry from the undo stack, and update the
#  display to reflect the new top entry.
#
   global BOLD
   global CAN2
   global CPEN
   global CSYSNOW
   global CTRL
   global CURX
   global EX0
   global GOLD
   global HENTRY
   global LP
   global LUT
   global MENT
   global NENTM1
   global NENT
   global NOLD
   global PPENT
   global ROLD
   global SOLD
   global UP

   set rid $NOLD 
   incr NOLD -1
   if { [info exists ROLD($NOLD)] } {
      catch { unset ROLD($rid) GOLD($rid) BOLD($rid) SOLD($rid)}
      set LUT(red) $ROLD($NOLD)
      set LUT(green) $GOLD($NOLD)
      set LUT(blue) $BOLD($NOLD)

#  If the arrays being restored have a different number of entries to the
#  current ones (due to a resampling having been performed), then change the
#  appropriate globals to describe the restored arrays.
      set nent [llength $ROLD($NOLD)]
      if { $nent != $NENT } {

#  The marked and selected entries, and the control points are defined in
#  terms of entry numbers and so cannot be retained, so clear them.
         set MENT ""
         updateMark 1
   
         set HENTRY ""
         select
   
         set CTRL(red) ""
         set CTRL(blue) ""
         set CTRL(green) ""

#  The cursor position is defined as a pen number and so can be retained. Save
#  the current cursor position before deleting it.
         set cpen $CPEN
         set CPEN ""
         updateCursor 1

#  Clear the editor canvas
         $CAN2 delete all

#  Store new globals.
         set NENT $nent
         set NENTM1 [expr $NENT-1]
         set PPENT [format "%.2f" [expr double($UP-$LP+1)/double($NENT)]]

#  Calculate new transformations.
         set EX0 ""
         set CURX ""
         setTrans

#  Restore the original cursor position.
         set CPEN $cpen
         updateCursor 1
      }

#  If the colour system in which the arrays were stored is different to the
#  current colour system, convert the arrays to the current system.
      toCSYS LUT $SOLD($NOLD)

#  Update the editor and GWM items.
      updateDisplay 0

   } { 
      Message "Nothing left to undo"
      set NOLD $rid
   }      

}

proc imageDisp { } {
#
#  Display the image and histogram.
#
   global IMAGE
   global LUTEDIT_SCRATCH
   global AUTOCUT
   global NEGIMAGE

   if { $NEGIMAGE } {
      set per "\[$AUTOCUT,[expr 100-$AUTOCUT]\]"
   } else {
      set per "\[[expr 100-$AUTOCUT],$AUTOCUT\]"
   }

   Obey kapview picsel "label=image" 1
   Obey kapview display "in=$IMAGE axes=no mode=perc margin=0.05 percentiles=$per " 1

#  Update the histogram to ensure it reflects the new image display.
   histDisp

}

proc histDisp { } {
#
#  Display the histogram.
#
   global IMAGE
   global LUTEDIT_SCRATCH
   global SCALOW
   global SCAHIGH

   set SCALOW [format "%.6g" [GetParamED kapview display:scalow]]
   set SCAHIGH [format "%.5g" [GetParamED kapview display:scahigh]]

   Obey kapview picsel "label=hist" 1
   Obey kapview gdclear "current=yes" 1
   Obey kapview picsel "label=hist2" 1
   Obey kapview lutview "mode=pic low=$SCALOW high=$SCAHIGH ndf=$IMAGE style=^$LUTEDIT_SCRATCH/hstyle" 1
}

proc histStyle { update } {
#
#  Create a new style file for the the histogram, and optionally redisplay 
#  the histogram.
#
   global LUTEDIT_SCRATCH
   global HISTXLAB
   global HISTTSIZ
   global LOGPOP
   global IMAGE

   set f [open $LUTEDIT_SCRATCH/hstyle w]
   puts $f "form=hist"
   puts $f "edge1=bottom,edge2=left"
   puts $f "majticklen=0.03,minticklen=0.015"
   puts $f "textlabgap=0.02,numlabgap=0.02"

   if { $HISTXLAB == "pen" } {
      puts $f "pennums=1"
   } else {
      puts $f "pennums=0"
   }

   if { $LOGPOP } {
      puts $f "logpop=1"
   } else {
      puts $f "logpop=0"
   }

   puts $f "size=[expr $HISTTSIZ*1.75]"

   close $f

   if { $update } { histDisp }
}

proc unzoom {} {
#
#  Reset the zoom factors to one, and redraw the editor.
#
   global ZOOMX
   global ZOOMY
   global XSCROLL
   global YSCROLL

   set ZOOMX 1
   set ZOOMY 1

   $XSCROLL set 0 1
   $YSCROLL set 0 1

   updateZoom
}

proc setTrans {} {
#
#  Set up the coefficients of the transformations between canvas
#  coord in the editor canvas, pen number, table entry, and intensity.
#
   global CAN2
   global PVAL
   global EVAL
   global EX0 
   global EX1 
   global LP
   global NENT
   global NENTM1
   global PX0 
   global PX1 
   global UP
   global XE0 
   global XE1
   global XP0 
   global XP1 
   global YOFF
   global YSCALE
   global ZOOMX
   global ZOOMY
   global CXL
   global CXH
   global CYL
   global CYH
   global CURX

   if { $CAN2 != "" } {
      update idletasks
      set h [winfo height $CAN2]
      set w [winfo width $CAN2]

#  Set the X bounds of the region of canvas coords to be used.
      set lcx [expr 0.05*$w]
      set hcx [expr 0.95*$w]

#  Find the X value to zoom about, and the fractional pen and entry values 
#  at this X.
      if { $CURX != "" && $EX0 != "" } {
         set cxt $CURX
         set cet [expr $EX0+$EX1*$cxt]
         set cpt [expr $PX0+$PX1*$cxt]
      } else {
         set cxt [$CAN2 canvasx [expr 0.5*( $lcx + $hcx )]]
         set cet [expr $NENTM1*0.5]
         set cpt [expr ($LP+$UP)*0.5]
      }

#  CX = Fractional canvas X in range 0 to $w
#  EX = Fractional table entry number (ZERO BASED) in range 0.0 to $NENT-1.0 
#  PX = Fractional pen number number (ONE BASED) in range $LP to $UP.
#
#  Fractional pen and entry values have an integer value at the *centre* of
#  each pen or entry. Thus the lower half of the first entry, and the
#  upper half of the last entry, fall outside the range fo usable canvas X.
#  The same applies to the first and last pen.
#
#  At ZOOM=1.0...
#
#     EX=0.0 -> CX=$lcx
#     EX=$NENT-1.0 -> CX=$hcx
#
#     PX=$LP -> CX=$lcx
#     PX=$UP -> CX=$hcx

#  EX = EX0 + EX1*CX and CX = XE0 + XE1*EX
      set EX1 [expr $NENTM1/($ZOOMX*($hcx-$lcx))]
      set EX0 [expr $cet-$EX1*$cxt]
      set XE0 [expr -$EX0/$EX1]
      set XE1 [expr 1.0/$EX1]

#  PX = PX0 + PX1*CX and CX = XP0 + XP1*PX
      set PX1 [expr ($UP-$LP)/($ZOOMX*($hcx-$lcx))]
      set PX0 [expr $cpt-$PX1*$cxt]
      set XP0 [expr -$PX0/$PX1]
      set XP1 [expr 1.0/$PX1]

#  Store the canvas X corresponding to the lowest and highest pens.
      set CXL [expr $XP0+$XP1*$LP]
      set CXH [expr $XP0+$XP1*$UP]

#  canvas Y = YOFF - intensity*YSCALE   (intensity in range [0,1]).
#
#  Set The Y axis scaling, retaining the current Y position of the
#  current pen intensity $PVAL, (if any).
      if { $CURX != "" } {
         set cyold [expr $YOFF - $PVAL*$YSCALE]
         set YSCALE [expr $ZOOMY*$h*0.8 ]
         set YOFF [expr $cyold + $PVAL*$YSCALE]
      } else {
         set YSCALE [expr $ZOOMY*$h*0.8 ]
         set YOFF [expr 0.5*($h+$YSCALE)]
      }

#  Store the canvas Y corresponding to the lowest and highest intensity.
#  Note, CYL will be greater than CYH because canvas Y increases downwards.
      set CYL $YOFF
      set CYH [expr $YOFF - $YSCALE]
   }
}

proc Zoom {xy plus} {
#
#  Zoom the editor window.
#
   global ZOOMX
   global ZOOMY

#  Increase or decrease the zoom factors.
   if { $xy == "x" } {
      if { $plus } {
         if { $ZOOMX < 10 } { set ZOOMX [expr $ZOOMX*1.6] }
      } else {
         if { $ZOOMX >  0.2 } { set ZOOMX [expr $ZOOMX/1.6] }
      }
   } else {
      if { $plus } {
         if { $ZOOMY < 10 } { set ZOOMY [expr $ZOOMY*1.6] }
      } else {
         if { $ZOOMY >  0.2 } { set ZOOMY [expr $ZOOMY/1.6] }
      }
   }

#  Redraw the editor using the new zoom factors.
   updateZoom
}

proc centreWin {w} {
#
#  Center the supplied toplevel window on the screen
#

   if { $w == "." } {
      set p $w
   } else {
      set p [winfo parent $w]
   }

# Withdraw the window, then update all the geometry information
# so we know how big it wants to be, then center the window in the
# display and de-iconify it.
    wm withdraw $w
    update idletasks
    set x [expr [winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
	    - [winfo vrootx $p]]
    set y [expr [winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
	    - [winfo vrooty $p]]
    wm geom $w +$x+$y
    wm deiconify $w
}

proc emptyEditor {} {
#  
#  Clear the editor canvas and remove the global data defining the
#  editor contents.
#
   global CAN2
   global LUT
   global CTRL
   global MENT
   global CPEN
   global EX0
   global HENTRY
   global LENTRY
   
   unzoom 

   set HENTRY ""
   set LENTRY ""

   set MENT ""
   updateMark 1

   set CPEN ""
   updateCursor 1

   $CAN2 delete all

   unset LUT(red)
   unset LUT(green)
   unset LUT(blue)

   set CTRL(red) ""
   set CTRL(blue) ""
   set CTRL(green) ""

   set EX0 ""
}

proc rgbSel {} {
#  
#  Raise the curve for the colour given by global RGBSEL, and reconfigure
#  the cursor and mark. Assign the tag ccrv to the current curve in the
#  editor.
#
   global RGBSEL
   global RGBNOW
   global CAN2

   if { $RGBSEL != $RGBNOW } {

      $CAN2 delete cp-$RGBNOW 

      $CAN2 itemconfigure c-$RGBNOW -width 1
      $CAN2 itemconfigure c-$RGBSEL -width 2
      $CAN2 raise c-$RGBSEL
      set RGBNOW $RGBSEL

      drawCPoint

      $CAN2 dtag [$CAN2 find withtag ccrv] ccrv
      $CAN2 addtag ccrv withtag "c-$RGBSEL"

      set CRVTAG "c-$RGBSEL"
      updateCursor 1
      updateMark 1
   }

}

proc Open {} {
#  
#  Open and display a new colour table, specified by the user.
#
   global LUTFILE
   global UWIN

# If required, save the current colour table.
   if { [Saver] } {
      set LUTFILE ""
      set file [tk_getOpenFile -defaultextension ".sdf" -filetypes {{SDF {.sdf}} {All {*}}}]

#  If ok, open the NDF.
      if { $file != "" } { openNamed $file 0} 

   }
}

proc openNamed {file force} {
#  
#  Open and display a new colour table, specified by the caller.
#
   global LUTFILE
   global UWIN

   set ret 1

#  Check it exists.
   set ndf [file rootname $file]
   if { ![file exists "$ndf.sdf"] } { return 0 }

#  Check the NDF is suitable.
   Obey ndfpack ndftrace "ndf=$ndf" 
   set dims [GetParamED ndfpack ndftrace:dims]
   regexp {\[([-+0-9]+),([-+0-9]+)\]} $dims a xd yd
   if { $xd != 3 } {
      if { $xd > 3 } {
         set w "more"
      } elseif { $xd < 3 } {
         set w "less"
      }
      Message "$file contains $w than 3 columns and so\ncannot be used as a colour table."
      set ret 0

#  If ok, save the path to the NDF containing the current colour table.
   } else {
      set LUTFILE $file

#  Empty the editor.
      emptyEditor

#  Set the name of the top level window.
      wm  title $UWIN "LutEdit $file"

#  Copy the NDF contents into a text file and read the text file contents
#  into the global LUT arrays.
      set tfile [UniqueFile]
      Obey kappa look "ndf=$ndf mode=bounds format=region ubound=\! lbound=\! logfile=$tfile" 1
      textLut $tfile
      file delete -force $tfile   

#  Save the current LUT arrays as the originals.
      orig

#  Update the editor to display the new colour table.
      updateDisplay $force
   }

   return $ret
}

proc Strut {w h} {
   set ret [frame $w.strut -width 0 -height $h]
   pack propagate $ret 0
   pack $ret -side left
   return $ret 
}

proc clearCurve {col} {
#  
#  Clears the canvas of items related to the specified intensity curve.
#
   global CAN2
   $CAN2 delete c-$col cp-$col
}

proc drawCPoint {} {
#  
#  Draws the control points for the currently selected curve.
#
   global CAN2
   global CTRL
   global RGBNOW
   global CPIM
   global LUT
   global XE0
   global XE1
   global YOFF
   global YSCALE

   foreach ent $CTRL($RGBNOW) {
      set v [lindex $LUT($RGBNOW) $ent]
      $CAN2 create image [expr $XE0+$XE1*$ent] [expr $YOFF-$v*$YSCALE] -image $CPIM -tags [list cp cp-$RGBNOW cp-$RGBNOW-$ent]
   } 
}

proc drawCurve {col} {
#  
#  Draws the intensity curve for the colour specified by argument
#  $col ("red", "green" or "blue").
#
   global YSCALE
   global CAN2
   global CXL
   global CXH
   global LUT
   global XE0
   global XE1
   global EX0
   global YOFF
   global RGBNOW
   global NN
   global NENT
   global CSYSNOW

#  erase any existing curve
   clearCurve $col

#  Check a curve is defined.
   if { [info exists LUT($col)] } {

#  Set the fill colour to invisible for G and B curves in MONO mode.
      if { $CSYSNOW == "MONO" && $col != "red" } {
         set fill "\"\""
      } else {
         set fill $col
      }         

#  Ensure the transformations between the various coordinate systems
#  are set up.
      if { $EX0  == "" } { setTrans }

#  Create a list of the canvas coords at the vertices of the poly line.  
#  A join-the-dots plot is used for linear interpolation.
      if { $NN == "NO" } {

         lappend xy $CXL
         lappend xy [expr $YOFF-[lindex $LUT($col) 0]*$YSCALE]

         set x $XE0
         for {set ent 1} {$ent < $NENT} {incr ent} {
            set x [expr $x + $XE1]
            lappend xy $x
            lappend xy [expr $YOFF-[lindex $LUT($col) $ent]*$YSCALE]
         }

#  For nearest-neighbour interpolation (or if entry numbers are being
#  displayed), a histogram-style plot is used. 
      } else {    
         set xl [expr $XE0-0.5*$XE1]
         foreach val $LUT($col) {
            set y [expr $YOFF-$val*$YSCALE]
            lappend xy $xl
            lappend xy $y
            set xl [expr $xl + $XE1]
            lappend xy $xl
            lappend xy $y
         }

#  Truncate the first and last entries (which are half as wide as the
#  others)
         set xy [lreplace $xy 0 0 $CXL]
         set i [expr [llength $xy] - 2 ]
         set xy [lreplace $xy $i $i $CXH]

      }

#  Create the line.
      eval $CAN2 create line $xy -fill $fill -tags \{$col c-$col c\}

#  Indicate that the current colour is no longer at the top.
      set RGBNOW ""
   }
}


proc B1MotionBind {x y} {
#+
#  Name:
#    B1MotionBind
#
#  Purpose:
#    Process pointer motion over the editor with button 1 pressed.
#
#  Arguments:
#    x
#       The screen X coord.
#    y
#       The screen Y coord.
#
#  Globals:
#     CAN2 (Read)
#        The name of the canvas widget holding the editor.
#     MODE (Read)
#        The interaction mode determining how to process button clicks
#        and motion in the editor. Modes are:
#           "" - Nothing
#           "curs" - The cursor ie being dragged.
#     ROOTX (Read)
#        The canvas X coordinate at which the button was pressed.
#     ROOTY (Read)
#        The canvas Y coordinate at which the button was pressed.
#-
   global CAN2
   global BACKCOL
   global MODE
   global ROOTX
   global ROOTY
   global CURSID
   global CURY1
   global CURY2
   global CURX
   global CXL
   global CXH
   global CYL
   global CYH
   global SEG
   global YOFF
   global YSCALE
   global PVAL
   global MX0
   global MX1
   global CPL1
   global CPL2
   global CP2
   global CP1
   global CPX1
   global CPX2
   global CPY1
   global CPY2
   global SELID

# Convert the screen coords to canvas coords.
   set cx [$CAN2 canvasx $x]
   set cy [$CAN2 canvasy $y]

#  Limit to the usable area. (Note $CYH < $CYL since Y increases
#  downwards).
   if { $cy < $CYH } {
      set cy $CYH
   } elseif { $cy > $CYL } {
      set cy $CYL
   }
   if { $cx > $CXH } {
      set cx $CXH
   } elseif { $cx < $CXL } {
      set cx $CXL
   }

# The global variable MODE determines how events over the canvas are 
# processed. 

# Dragging a control point
   if { $MODE == "cp" } {
      set cp [$CAN2 find withtag current]
      set PVAL [format "%.3f" [expr ($YOFF - $cy)/$YSCALE]]
      $CAN2 coords current $ROOTX $cy

#  Drag the ends of the two lines which were drawn when the button was
#  clicked.
      set cx $ROOTX
      if { $CP1 == "" } { set CPY1 $cy }
      if { $CP2 == "" } { set CPY2 $cy }
      $CAN2 coords $CPL1 $CPX1 $CPY1 $cx $cy
      $CAN2 coords $CPL2 $cx $cy $CPX2 $CPY2 

# Dragging the marker up and down...
   } elseif { $MODE == "seg" } {
      set PVAL [format "%.3f" [expr ($YOFF - $cy)/$YSCALE]]
      $CAN2 coords mark $MX0 $cy $MX1 $cy 

# Dragging the cursor...
   } else { 

# Move the cursor line to the current pointer position.
      if { $CURSID != "" } {
         set CURX $cx
         $CAN2 coords $CURSID $CURX $CURY1 $CURX $CURY2
         updateCursor 0
      }

# Extend the selection box
      if { $SELID != "" } {
         $CAN2 coords $SELID $ROOTX $CURY1 $CURX $CURY2
      } else {
         set SELID [$CAN2 create rectangle $ROOTX $CURY1 $CURX $CURY2 -outline "" -fill $BACKCOL]
         $CAN2 lower $SELID
      }
   }
}

proc CheckMsg {action val} {
#+
#  Name:
#    CheckMsg
#
#  Purpose:
#    Checks messages created by an ADAM action for error messages. If an
#    error message is found, it is added to a global list of error messages.
#
#  Arguments:
#    action
#       The current action.
#    val
#       The value of the ADAM error message.
#
#  Globals:
#    ADAM_ERRORS (Read and Write)
#       The current list of ADAM error messages.
#    ATASK_OUTPUT (Read and Write)
#       Any non-error messages are appended to this list. Each
#       message is stored as a new element in the list.
#    LOGFILE_ID (Read)
#       The file id for any logfile to which all messages should be
#       written.
#-
   global ADAM_ERRORS
   global ATASK_OUTPUT
   global LOGFILE_ID

# Write all messages to the log file if there is one.
   if { $LOGFILE_ID == "stdio" } {
      puts "$action: $val"
   } elseif { $LOGFILE_ID != "" } {
      puts $LOGFILE_ID "$action: $val"
   }

# Error messages are distinguished from other informational messages
# by starting with one or more exclamation marks. Ignore the supplied
# message if it does not start with an exclamation mark. Otherwise,
# add it to the list (on a new line), and indicate an error has occurred.
   if { [regexp {^!+(.*)} $val match mess] } {
      if { [info exists ADAM_ERRORS] } {
         if { [string length $mess] > 30 } { 
            set ADAM_ERRORS "$ADAM_ERRORS\n$mess"
         } {
            set ADAM_ERRORS "$ADAM_ERRORS $mess"
         }
      } {
         set ADAM_ERRORS $mess
      }

# If the message is not an error message, append it as a new element to
# the list stored in ATASK_OUTPUT.
   } { 
      lappend ATASK_OUTPUT $val
   }
}

proc CheckRF {task} {
#+
#  Name:
#     CheckRF
#
#  Purpose:
#     Check that the AMS rendevous file for a task still exists. If it
#     does not (for some reason it seems to be occasionally deleted by
#     the StarTcl system, turning the process into a zombie), then the 
#     task is killed and re-loaded.
#
#  Arguments:
#     The task to be checked (previously loaded using LoadTask).
#
#  Returned Value:
#     Returns 1 if the rendevous file still exists, and zero if it 
#     did not exist (in which case the task will have been re-loaded).
#
#  Globals:
#     RENDEVOUS (Read)
#        A 1-d array, indexed by task name, storing the path to the
#        task's rendevous file.
#     TASK_FILE
#        A 1-d array, indexed by task name, storing the path to the
#        task's executable binary file (as supplied to LoadTask).
#-
   global RENDEVOUS
   global TASK_FILE

   if { ![file exists $RENDEVOUS($task)] } {
      $task kill
      Message "$task rendevous file ($RENDEVOUS($task)) has dissappeared! Re-loading the task."
      LoadTask $task $TASK_FILE($task)
      set ret 0
   } {
      set ret 1
   }

   return $ret   

}

proc Confirm {message} {
#+
#  Name:
#    Confirm
#
#  Purpose:
#    Get the user to confirm an operation. The supplied text is displayed
#    and the user presses one of two buttons. An indication of which
#    button was pressed is returned.
#
#  Arguments:
#    message
#       The message to display. 
#
#  Returned Value:
#   Zero is returned if the operation should be cancelled, one is
#   returned if it is ok to proceed.
#
#-

# Display the dialog box and get the user's response.
   set but [dialog .confirm "LutEdit Confirmation" $message {} 0 OK Cancel]

# Return the answer.
   return [expr 1 - $but]
}

proc dialog {w title text bitmap default args} {
#+
#  Name:
#     dialog
#
#  Purpose:
#     This procedure displays a dialog box, waits for a button in the dialog
#     to be invoked, then returns the index of the selected button.
#
#  Arguments:
#     w 
#        Window to use for dialog top-level.
#     title 
#        Title to display in dialog's decorative frame.
#     text 
#        Text to display in dialog.
#     bitmap 
#        Bitmap to display in dialog (empty string means none).
#     default 
#        Index of button that is to display the default ring
#     	 (-1 means none).
#     args 
#        One or more strings to display in buttons across the
#	 bottom of the dialog box.
#-
    global tk_priv
    global TOP

# 1. Create the top-level window and divide it into top
# and bottom parts.

    catch {destroy $w}
    toplevel $w -class Dialog -colormap $TOP
    wm title $w $title
    wm iconname $w Dialog
    frame $w.top -relief raised -bd 1
    pack $w.top -side top -fill both
    frame $w.bot -relief raised -bd 1
    pack $w.bot -side bottom -fill both

# 2. Fill the top part with bitmap and label.

    message $w.msg -text $text -width 7i
    pack $w.msg -in $w.top -side right -expand 1 -fill both -padx 5m -pady 5m
    if {$bitmap != ""} {
	label $w.bitmap -bitmap $bitmap
	pack $w.bitmap -in $w.top -side left -padx 5m -pady 5m
    }

# 3. Create a row of buttons at the bottom of the dialog.

    set i 0
    foreach but $args {
	button $w.button$i -text $but -command "set tk_priv(button) $i"
	if {$i == $default} {
	    frame $w.default -relief sunken -bd 1
	    raise $w.button$i $w.default
	    pack $w.default -in $w.bot -side left -expand 1 -padx 3m -pady 2m
	    pack $w.button$i -in $w.default -padx 2m -pady 2m \
		    -ipadx 2m -ipady 1m
	    bind $w <Return> "$w.button$i flash; set tk_priv(button) $i"
	} else {
	    pack $w.button$i -in $w.bot -side left -expand 1 \
		    -padx 3m -pady 3m -ipadx 2m -ipady 1m
	}
	incr i
    }

# 4. Withdraw the window, then update all the geometry information
# so we know how big it wants to be, then center the window in the
# display and de-iconify it.
    centreWin $w

# 5. Set a grab and claim the focus too.

    set oldFocus [focus]
    grab $w
    focus $w

# 6. Wait for the user to respond, then restore the focus and
# return the index of the selected button.

    tkwait variable tk_priv(button)
    destroy $w
    focus $oldFocus
    return $tk_priv(button)
}

proc Finish {} {
#+
#  Name:
#     Finish
#
#  Purpose:
#     Exit lutedit, warning the user if the colour table has not yet
#     been saved.
#
#  Arguments:
#     None
#-

# If required, save the colour table.
   if { [Saver] } { exit } 
}

proc GetParam {task param} {
#+
#  Name:
#    GetParam
#
#  Purpose:
#    Get a parameter value from an ADAM task.
#
#  Arguments:
#    task
#       The name of the task (eg "kapview").
#    param
#       The name of the parameter in the form "action:param" 
#       (eg "datapic:ncx1").
#
#  Returned Value:
#    The parameter value.
#
#  Globals:
#    PAR_VALUE (Write)
#       The most recently acquired parameter value.
#
#  Notes:
#    - This procedure does not return until the parameter value has been
#    obtained.
#
#-
   global PAR_VALUE
   global PAR_GOT

# Issue the request for the parameter value.
   set PAR_GOT 0
   $task get $param -getresponse {set PAR_VALUE %V;set PAR_GOT 1}

# Wait until the request has been fulfilled.
   WaitFor PAR_GOT

# Return the parameter value.
   return $PAR_VALUE
}

proc GetParamED {task param} {
#+
#  Name:
#     GetParamED
#
#  Purpose:
#     Returns the value of an ATASK parameter substituing "E" exponents for 
#     "D" exponents.
#
#  Arguments:
#     task
#        The name of the task
#     param
#        The name of the parameter, in the form "<application>:<parameter>"
#
#  Returned Value:
#     The parameter value.
#
#-
   regsub -nocase -all D [GetParam $task $param] E res
   return $res
}
    
proc GetPars {vars ntypes nlabels nlimits title help dhelp} {
#+
#  Name:
#     GetPars
#
#  Purpose:
#     Obtain a set of values of various data types from the user.
#     A dialog box is displayed, containing a set of labeled entry
#     widgets, check buttons and radio buttons. Checks are made that 
#     the supplied values are acceptable.
#
#  Arguments:
#     vars
#        A list of the names of the global variable which are to recieve
#        the entered values. The initial values of these variables are 
#        displayed in the entry boxes. NB, these variables must be GLOBAL.
#     ntypes
#        The name of a 1-D array indexed by variable name, holding the data 
#        type for the the variable. This must be one of:
#        _REAL - A floating point value.
#        _INTEGER - An integer value.
#        _LOGICAL - A boolean value. True is returned as 1 and false as 0.
#        _CHAR[*length] - A string. If the supplied, the length determines
#                         the width of the associated entry box.
#        _CHOICE - A choice from the strings supplied in the variable's
#                  entry in the "limits" array.
#     nlabels
#        The name of a 1-D array indexed by variable name, holding the labels 
#        to display next to each entry box. These may be blank if no label is required.
#     nlimits
#        The name of a 1-D array indexed by variable name. Each element is a 
#        list holding values which restrict the values which can be taken by
#        the corresponding variable. For _REAL and _INEGER, the first item 
#        in the list is the minimum allowed value, and the second is the 
#        maximum allowed value. If not supplied, no limits are imposed. For
#        _CHOICE, the items in the list are the allowed string values for the
#        variable.
#     title
#        A title for the dialog box window.
#     help
#        An htx cross-reference label into the hypertext documentation to be 
#        followed if the Help button is pressed. If this is blank then no Help
#        button is created.
#     dhelp
#        The dynamic help string to display while the pointer is over the
#        dialog box.
#
#  Returned Value:
#     One if the "OK" button is pressed, and zero if the "Cancel" button
#     is pressed.
#
#  Globals:
#     B_FONT (Read)
#        The default font used for buttons.
#     INPUTS_BUTTON (Write)
#        Used to communicate with the buttons in the dialog box. It holds
#        the label of the most recently pressed button.
#-
   global tcl_precision
   global B_FONT
   global INPUTS_BUTTON

# Create the empty dialog box.
   set top .inputs
   set topf [MakeDialog $top $title 1]

# Store the dynamic help text.
   SetHelp $top $dhelp

# Access the arrays declared in the calling procedure.
   upvar $ntypes types
   upvar $nlabels labels
   upvar $nlimits limits

# Create a frame to hold the variable controls.
   set cf [frame $topf.cf -relief flat -bd 2]
   pack $cf -padx 2m -pady 2m -fill x -expand 1

# Loop round every supplied variable.
   set nent 0
   set n [llength $vars]
   for {set i 0} {$i < $n} {incr i} {

# Access the variable using the local variable "var"
      set varname [lindex $vars $i]
      upvar #0 $varname var

# Store the supplied values, so that they can be restored if required.
      lappend olds $var

# Get a lower case version of the variable name.
      set lvar [string tolower $varname]

# Create a frame with this name.
      set lvar [string tolower $varname]
      set f1 [frame $cf.$lvar]
      pack $f1 -side top -pady 2m -padx 1m -anchor w -fill y -expand 1

# Get the type for this variable.
      set type $types($varname)

# Get the limits list, and the length of the limits list.
      if { [info exists limits($varname)] } {
         set lims $limits($varname)
         set nlims [llength $lims]
      } {
         set lims ""
         set nlims 0
      }

# Get the label (if supplied).
      if { [info exists labels($varname)] } {
         set label $labels($varname)
      } {
         set label ""
      }

# Create the textual label (if supplied, and except for _LOGICALs).
      if { $label != "" && $type != "_LOGICAL" } {
         set lb [label $f1.lb -text $label -font $B_FONT]
         pack $lb -side left -anchor n
      }

# Deal with each type in turn...

# _REAL...
      if { $type == "_REAL" } {
         incr nent

# Set the width for the data entry boxes.
         set wid [expr $tcl_precision + 6]

# Extract the min and max values from the limits list.
         if { $nlims > 0 } { 
            set min [lindex $lims 0]
            if { $nlims > 1 } { 
               set max [lindex $lims 1]
            } {
               set max {\"\"}
            }
         } {
            set min {\"\"}
            set max {\"\"}
         }

# Create the data entry box, limiting the value to the supplied max and
# min (if any).
         set com "if { $max != \\\"\\\" && \\\$$varname > $max } { 
                     set $varname $max
                  } elseif { $min != \\\"\\\" && \\\$$varname < $min } { 
                     set $varname $min
                  }"
         set vl [RealValue $f1.vl $wid $varname $com]
         pack $vl -side left 

# _INTEGER...
      } elseif { $type == "_INTEGER" } {
         incr nent

# Extract the min and max values from the limits list.
         if { $nlims > 0 } { 
            set min [lindex $lims 0]
            if { $nlims > 1 } { 
               set max [lindex $lims 1]
            } {
               set max {\"\"}
            }
         } {
            set min {\"\"}
         }

# Ensure they are integer.
         if { $min != {\"\"} } { set min [expr round( $min )] }
         if { $max != {\"\"} } { set max [expr round( $max )] }

# Create the data entry box, limiting the value to integer values between the 
# supplied max and min (if any).
         set com "set $varname \\\[expr round( \\\$$varname ) \\\]
                  if { $max != \\\"\\\" && \\\$$varname > $max } { 
                     set $varname $max
                  } elseif { $min != \\\"\\\" && \\\$$varname < $min } { 
                     set $varname $min
                  }"
         set vl [RealValue $f1.vl 12 $varname $com]
         pack $vl -side left 

# _LOGICAL
      } elseif { $type == "_LOGICAL" } {
         set cb [checkbutton $f1.cb -text $label -variable $varname \
                             -font $B_FONT]
         pack $cb -side left 

# _CHAR
      } elseif { [regexp {^_CHAR} $type] } {
         incr nent

# Extract the character length from the supplied type. Use 30 if no
# length was supplied.
         if { ![regexp {^_CHAR\*([0-9]+)} $type match wid] } {
            set wid 30
         }

# Create the string entry box.
         set vl [StringValue $f1.vl $wid $varname "" -font $B_FONT]
         pack $vl -side left 

# _CHOICE
      } elseif { $type == "_CHOICE" } {

# Create a frame to hold the radio-buttons.
         set rbf [frame $f1.rbf]
         pack $rbf -side left 

# Create a radiobutton for each option.
         set ii 0
         foreach string $lims {
            set rb [radiobutton $rbf.$ii -text $string -value $string \
                                -variable $varname]
            pack $rb -side top -anchor w 
            incr ii
         }

      }

   }

# Create the button bar.
   set butfrm [frame $topf.butfrm]
   pack $butfrm -fill both -expand 1

   set b1 [button $butfrm.ok -text "OK" -command "set INPUTS_BUTTON ok"]
   set b2 [button $butfrm.cancel -text "Cancel" -command "set INPUTS_BUTTON cancel"]
#   set b3 [button $butfrm.restore -text "Restore" -command "set INPUTS_BUTTON  restore"]

   SetHelp $b1 "Press to close the dialog box, adopting the currently displayed values."
   SetHelp $b2 "Press to close the dialog box, cancelling the operation."
#   SetHelp $b3 "Press to restore the original values."

#   pack $b1 $b2 $b3 -side left -expand 1 -padx 2m   
   pack $b1 $b2 -side left -expand 1 -fill x -padx 2m   

   if { $help != "" } {
      set b4 [button $butfrm.help -text "Help" -command "set INPUTS_BUTTON help"]
      SetHelp $b4 "Press to display more detailed help information."
      pack $b4 -side left -expand 1 -padx 2m
   }

# If there is only one variable being obtained through an entry, then create a 
# binding so that pressing the <Return> key behaves like clicking the OK 
# button.
   if { $nent == 1 } { bind $top <Return> "set INPUTS_BUTTON ok" }

# Ensure that closing the window from the window manager is like pressing
# the Cancel button.
   wm protocol $top WM_DELETE_WINDOW "set INPUTS_BUTTON cancel"

# Loop until an exit button is pressed.
   set exit 0
   while { !$exit } {

# Wait for the user to press a button.
      tkwait variable INPUTS_BUTTON

# If the cancel button was pressed, re-instate the original values, and
# exit, returning 0.
      if { $INPUTS_BUTTON == "cancel" } {
         set ret 0
         set exit 1
         for {set i 0} {$i < $n} {incr i} {
            upvar #0 [lindex $vars $i] var
            set var [lindex $olds $i]
         }

# If the OK button was pressed, exit with the current values, returning 1.
      } elseif { $INPUTS_BUTTON == "ok" } {
         set ret 1
         set exit 1

# If the Restore button was pressed, restore the original values but do
# not exit.
      } elseif { $INPUTS_BUTTON == "restore" } {
         for {set i 0} {$i < $n} {incr i} {
            upvar #0 [lindex $vars $i] var
            set var [lindex $olds $i]
         }

# If the Help button was pressed, display help.
      } elseif { $INPUTS_BUTTON == "help" } {
         ShowHelp $help 
      }
   }

# Destroy the dialog box.
   destroy $top

   return $ret

}

proc greyCurves {nent} {
#+
#  Name:
#     greyCurves
#
#  Purpose:
#     Set each of the three colour curves to a linear ramp from zero to
#     one, and delete all control points.
#
#  Arguments:
#     nent
#        The number of entries to create it the colour table
#-
   global NENT
   global CTRL
   global PPENT
   global LUT
   global CTRL
   global CPEN
   global CURX
   global CENT
   global LP
   global UP
   global NENTM1
   global CSYSNOW

#  Set each colour curve to a straight line through the origin.
   set NENT $nent
   set NENTM1 [expr $nent-1]
   set PPENT [format "%.2f" [expr double($UP-$LP+1)/double($nent)]]

   set delta [expr 1.0/( $NENTM1 )]
   set int 0

   set CTRL(red) ""
   set CTRL(green) ""
   set CTRL(blue) ""

   set LUT(red) ""
   set LUT(green) ""
   set LUT(blue) ""

   if { $CSYSNOW == "RGB" } {
      for {set i 0} {$i < $NENT} {incr i} {
         lappend LUT(red) $int
         lappend LUT(green) $int
         lappend LUT(blue) $int
         set int [expr $int + $delta]
      }

   } elseif { $CSYSNOW == "MONO" } { 
      for {set i 0} {$i < $NENT} {incr i} {
         lappend LUT(red) $int
         lappend LUT(green) -1.0
         lappend LUT(blue) -1.0
         set int [expr $int + $delta]
      }

   } elseif { $CSYSNOW == "HSV" } { 
      for {set i 0} {$i < $NENT} {incr i} {
         lappend LUT(red) 0.0
         lappend LUT(green) 0.0
         lappend LUT(blue) $int
         set int [expr $int + $delta]
      }
   }

#  Reset the cursor and mark.
   set MENT "" 
   set CPEN [expr round( 0.5*($LP+$UP))]

#  Calculate new transformations.
   set CURX ""
   setTrans

}

proc updateDisplay {force} {
#
#  Redraws all items on the editor canvas, and recreate the GWM items.
#  If force is zero, then the GWM items are only updated if auto-update
#  is selected. If force is -1, then the GWM items are not updated even
#  if auto-update is on.
#-
   global AUTOUP
   updateEditor
   if { ( $force == 1 ) || ( $force == 0 && $AUTOUP ) } {
      gwmUpdate 0
   }
}

proc updateEditor {} {
#
#  Redraws all items on the editor canvas. The GWM items are not redrawn.
#-
   global CTRL
   global LUT
   global CAN2
   global RGBNOW
   global LUTFILE
   global SELID

#  Delete any background rectangle.
   $CAN2 delete bkgrnd

#  Delete any selection marker
   if { $SELID != "" } {
      $CAN2 delete $SELID
      set SELID ""
   }

#  Display the new curves.
   drawCurve red
   drawCurve green
   drawCurve blue

#  Raise the currently selected curve.
   rgbSel

#  Set up the scrolling region for the editor.
   set bbox [$CAN2 bbox c]
   set xl [lindex $bbox 0] 
   set xh [lindex $bbox 2] 
   set yl [lindex $bbox 1] 
   set yh [lindex $bbox 3] 
   set dw [expr 0.02*($xh - $xl)]
   set dh [expr 0.05*($yh - $yl)]
   set xl [expr $xl - $dw]
   set xh [expr $xh + $dw]
   set yl [expr $yl - $dh]
   set yh [expr $yh + $dh]

   $CAN2 configure -scrollregion [list $xl $yl $xh $yh]

#  Create a transparent background rectangle covering the scroll region
   $CAN2 create rectangle $xl $yl $xh $yh -outline "" -tags bkgrnd
   $CAN2 lower bkgrnd

#  If there is a selection, update the selection rectangle.
   select 

#  Update the cursor line.
   updateCursor 1

}

proc gwmDisplay {} {
#+
#  Name:
#     gwmDisplay
#
#  Purpose:
#     Re-display the image and histogram colour table key.
#
#  Arguments:
#     None

#  Returned Value:
#     None
#-
   global IMAGE
   global LUTEDIT_SCRATCH
   global GWMNEW

#  Empty all pictures without deleting the pictures from the AGI database.
   Obey kapview piclist "picnum=1" 1
   Obey kapview gdclear "current=yes" 1

#  Create the image display and histogram.
   imageDisp

#  Indicate we now have a complete GWM display.
   set GWMNEW 0
}

proc gwmUpdate {force} {
#+
#  Name:
#     gwmUpdate
#
#  Purpose:
#     Save the current colour table into a temporary file, and
#     re-initialize the gwm display using the saved LUT.
#
#  Arguments:
#     force
#        update the GWM items even if they may not need it.
#
#-
   global CAN
   global GWMNEW
   global LUT
   global NN

#  Check that a colour table exists in the editor.
   if { [info exists LUT(red)] } { 

#  Get the name for a new temporary NDF.
      set tfile [UniqueFile]

#  Save the current colour table to this NDF.
      saveLUT $tfile 1

#  Load this colour table into the GWM items.
      Obey kapview lutable "mapping=linear nn=$NN coltab=external lut=$tfile"

#  If the GWM items have a pseudoColor visual, the above lutable will
#  have caused the display to change to show the new LUT. Otherwise we
#  need to re-display the image etc in order for the LUT change to be visible.
#  Even if we have a pseudocolour visual, we still display the items if
#  they have never been displayed before, or if the user has forced an
#  update.
      if { $force || $GWMNEW || [winfo visual $CAN] != "pseudocolor" } { gwmDisplay }

#  Delete the NDF.
      file delete -force $tfile   
   }
}

proc gwmMake {} {
#+
#  Name:
#     gwmMake
#
#  Purpose:
#     Create a GWM canvas item which fills the existing canvas widget.
#     If this fails (e.g. due to lack of colours), an error message 
#     is returned and GWM is set to "". If succesful, a blank string is
#     returned.
#
#  Arguments:
#     None
#
#  Returned Value:
#     An error message, or a blank string.
#-
   global CAN
   global CAN2
   global GWM
   global GWM_NAME
   global GWM_NCOL
   global CANWID
   global CANHGT
   global GWMWID
   global GWMHGT
   global GWMNEW
   global GWMBASX
   global GWMBASY
   global DEVICE
   global NP
   global LP
   global UP
   global PPENT
   global NENT

# Indicate that as yet no new GWM canvas item has been created.
   set GWMNEW 0

# If no GWM canvas item yet exists, set its desired initial size equal to
# the initial size of the canvas.
   if { [$CAN type $GWM] == "" } {
      set wid $CANWID
      set hgt $CANHGT

# If a GWM canvas item already exists...
   } else {

# Set the desired size of the GWM canvas item equal to slighlty less than
# the current size of the canvas (it may have been resized).
      update idletasks
      set wid [expr [winfo width $CAN] - 4]
      set hgt [expr [winfo height $CAN] - 4]

# If the existing GWM canvas item is (badly) of the wrong size, delete it.
      if { abs( $wid - $GWMWID ) > 20 || abs( $hgt - $GWMHGT ) > 20 } { 
         $CAN delete $GWM
      }
   }

#  If no GWM canvas item now exists, create one with the desired size.
   set mess ""
   if { [$CAN type $GWM] == "" } {

# Attempt to create a GWM canvas item.
      if { [catch {set GWM [$CAN create gwm 1 1 -height $hgt \
                              -width $wid -name $GWM_NAME \
                              -mincolours $GWM_NCOL -tags gwm]} mess] } {

#  If it failed, ensure no GWM canvas item exists.
         if { [$CAN type $GWM] != "" } {
            $CAN delete $GWM
         }
         set GWM ""

#  If succesfull, set the current GWM dimensions, and return blank.
      } else {
         set GWMWID $wid
         set GWMHGT $hgt
         if { $hgt < $wid } {
            set GWMBASX [expr double($wid)/double($hgt)]
            set GWMBASY 1
         } else {
            set GWMBASX 1
            set GWMBASY [expr double($hgt)/double($wid)]
         }
         set GWMNEW 1
         set mess ""

#  On the first invocation, determine the number of colours in the display 
#  by saving the colour table into an NDF and getting its dimensions.
         if { $NP == "" } {
            set ndf [UniqueFile]
            Obey kapview lutsave "lut=$ndf device=$DEVICE" 1
            Obey ndfpack ndftrace "ndf=$ndf" 
            set dims [GetParamED ndfpack ndftrace:dims]
            regexp {\[([-+0-9]+),([-+0-9]+)\]} $dims a xd yd
            set NP $yd
            set UP [expr $LP + $NP - 1]
            set PPENT [format "%.2f" [expr double($NP)/double($NENT)]]
            file delete -force "$ndf.sdf"
         }

#  Set up the coefficients of the transformations between canvas X
#  coord in the editor canvas, pen number and table entry.
         setTrans
      }
   }

   return $mess
}

proc HelpArea {} {
#+
#  Name:
#     HelpArea
#
#  Purpose:
#     Create or destroy the frame displaying help information at the
#     bottom of the main window.
#
#  Arguments:
#     None.
#
#  Globals:
#     FHELP (Read and Write)
#        The name of the frame to contain help information.
#     HAREA (Read)
#        Is help information to be displayed?
#     HLP_FONT (Read)
#        The font in which to display help information.
#-
   global FHELP
   global HAREA
   global HLP_FONT
   global TOP
   global HSTRUT
   global HLAB
   global FONT
   global UWIN

# If required, create the help frame (if it has not already been created).
   if { $HAREA } {
      if { $FHELP == "" } {

# Find the pixels in 3 characters.
         set height [expr 3*[font metrics $HLP_FONT -linespace]]

# Create the frame to enclose the help text.
         set FHELP [frame $TOP.help -relief groove -bd 2]
         pack $FHELP -fill x -side bottom -anchor s -padx 1m -pady 1m

# Create a dummy frame with height but no width to act as a vertical strut.
# Geometry propagation is turn off for this frame so that its requested
# size will be retained even though nothing is put in the frame. This
# strut is used to keep the help area the same size even if the message text 
# within it requires a narrower area.
         set HSTRUT [Strut $FHELP $height]

# The width is the requested width of the whole window.
         update idletasks
         set width [expr 0.9*[winfo width $UWIN]]

# Create a message widget to display dynamic help information about 
# the widget underneath the pointer.
         set HLAB [message $FHELP.lab -justify left -textvariable HELP \
                            -anchor w -font $HLP_FONT -width $width]
         pack $HLAB -side left -fill x -expand 1

# Set up the help for the help area.
         SetHelp $FHELP  "An area which shows brief help on the object under the pointer." LUTEDIT_HELP_AREA
      }

# If required, destroy the help frame (if it has not already been destroyed).
   } {
      if { $FHELP != "" } {
         destroy $FHELP
         set FHELP ""
      }
   }
}

proc Helper { blank } {
#+
#  Name:
#     Helper
#
#  Purpose:
#     Selects the text to display in the help area. 
#
#  Arguments:
#     blank
#        If non-zero set the help blank. Otherwise, set the help
#        according to the current widget/tag.
#
#  Globals:
#     HELPS (Read)
#        An array holding the help messages for all widgets and canvas tags, 
#        indexed by widget name or canvas tag.
#     HELP (Write)
#        The text to be displayed in the help area.
#-

   global HELPS
   global HELP
   global FHELP
   global HSTRUT
   global HLAB
   global HAREA

   if { ![winfo exists $HLAB] } { return }

#  Set the help blank is required.
   if { $blank } { 
      set HELP ""
      return 
   }

# This function is usually invoked when the pointer enters or leaves a
# widget. The identification of the widget is not reliable if the pointer
# is on the boundary, so pause for 10 milliseconds to allow the pointer
# to get away from the boundary.
   after 10

# Find the lowest level widget under the pointer.
   set x [winfo pointerx .] 
   set y [winfo pointery .]
   set w [winfo containing $x $y]

# If the widget is a canvas, see if there is help associated with any of
# the tags of the current canvas item.
   set got 0
   if { $w != "" && [winfo class $w] == "Canvas" } {
      foreach tag [$w gettags current] {
         if { [info exists HELPS($tag)] } {
            set HELP $HELPS($tag)
            set got 1
            break
         }
      }
   }

# Check all the ancestors of this widget. This loop will be broken out of when
# a widget is found which has an associated help message.
   if { !$got } {
      while { $w != "" } {
         if { [info exists HELPS($w)] } {
            set HELP $HELPS($w)
            set got 1
            break
         }
         set w [winfo parent $w]
      }
   }

# If no suitable help was found, store a null help string.
   if { !$got } { 
      set HELP "" 

# If the vertical strut which stops the help area collapsing when the
# the number of lines in the help area reduces, is smaller than the
# current height of the help area, extend it.
   } elseif { $FHELP != "" && $HAREA } {
      set whgt [winfo height $HLAB]
      set shgt [winfo height $HSTRUT]
      if { $shgt < $whgt } {
         $HSTRUT configure -height $whgt
      }
   }

}

proc LoadTask {task file} {
#+
#  Name:
#    LoadTask
#
#  Purpose:
#    Load an ADAM task so that it can be used.
#
#  Arguments:
#    task
#      The name by which the task is to be known 
#      (eg "kapview").
#    file
#      The file containing the executable image 
#      (eg "/star/bin/kappa/kapview_mon").
#
#  Notes:
#    -  This procedure shuts down the whole application if the task 
#    cannot be loaded.
#
#  Globals:
#    ADAM_TASKS (Write)
#       A list of the names of the ADAM tasks started up by Polka.

#-
   global ADAM_TASKS
   global ADAM_USER
   global RENDEVOUS
   global TASK_FILE

# Load the task.
   set taskload [list adamtask $task $file ]
   if {[catch $taskload error] != 0} {
      puts "Error loading task $task (file $file): \"$error\". Aborting..."
      Message "Error loading task $task (file $file): \"$error\". Aborting..."
      exit 1
   }

# Poll for the task to attach to the message system.
   set count 0
   while {[$task path] == 0} {
      after 100
      incr count
      if {$count > 100} {
         puts "Timed out waiting for task \"$task\" (file $file) to start. Aborting..." 
         Message "Timed out waiting for task \"$task\" (file $file) to start. Aborting..." 
         $task kill
         exit 1
      }
   }

# Append the name of the task to the list of tasks started up so far.
   lappend ADAM_TASKS $task

# Save the name of the rendevous file.
   foreach rfile [glob -nocomplain $ADAM_USER/${task}_*] {
      if { [regexp "${task}_\[0-9\]+\$" $rfile] } {
         set RENDEVOUS($task) $rfile
         break
      }
   }

   if { ![info exists RENDEVOUS($task)] } {
      puts "Cannot find the rendevous file for $task."
      Message "Cannot find the rendevous file for $task."
      exit 1
   }
   set TASK_FILE($task) $file

}

proc MakeDialog {w title grab} {
#+
#  Name:
#     MakeDialog
#
#  Purpose:
#     Create an empty dialog box. It should be destroyed using
#     "destroy $w" when no longer needed.
#
#  Arguments:
#     w
#        The name of the toplevel window to create.
#     title
#        The title to display above the toplevel window.
#     grab
#        Should the toplevel window grab all X events?
#
#  Returned Value:
#     The path to a frame in which the dialog box components can be packed.
#
#  Globals:
#     TOP (Read)
#        The path to the main application window.
#-
   global TOP

# Create the top level window for the dialogue box, and set its title.
# It inherits the (potentially private) colour map used by the main
# application window.
   set top [toplevel $w -colormap $TOP]
   wm title $top "LutEdit - $title"

# Attempt put a grab on this window, so that other windows become
# inactive. This is a bit fragile so put the grab inside a catch so that
# an error in grab will not abort the application.
   if { $grab } { catch "grab $top" }

# Create a frame to hold everything else so that we can have a blank
# border round the other widgets.
   set topf0 [frame $top.f0 -bd 3 -relief raised]
   set topf [frame $topf0.f ]

# Pack the frame holding everything else.
   pack $topf -fill both -expand 1 -ipadx 2m -ipady 2m
   pack $topf0 -padx 2m -pady 2m -ipadx 2m -ipady 2m -fill both -expand 1

# Return the name of the frame to contain everything else.
   return $topf
}

proc MenuHelp {win label text} {
#+
#  Name:
#     MenuHelp
#
#  Purpose:
#     Establish the help text to display when the pointer is over
#     a specified entry in a specified menu.
#
#  Arguments:
#     win
#        The name of the menu.
#     label
#        The textual label for the menu entry.
#     text
#        The help information to display.
#
#  Globals:
#     MENUHELPS (Write)
#        A 2d array indexed by widget path and entry label, holding
#        the help text strings for all menu entries.
#-
   global MENUHELPS

# Store the supplied help text.
   set MENUHELPS($win,$label) $text

# Arrange for a blank help string to be displayed when the pointer
# initially enters the menu. This will be changed by the MenuMotionBind
# procedure.
   SetHelp $win ""
}

proc MenuMotionBind {win y} {
#+
#  Name:
#     MenuMotionBind
#
#  Purpose:
#     Displays help as the pointer moves over a menu. It should be bound
#     to motion over all menus.
#
#  Arguments:
#     win
#        The name of the window currently under the pointer.
#     y
#        The y coordinate of the pointer.
#
#  Globals:
#     HELP (Write)
#        The current help text to display.
#     MENUHELPS (Read)
#        The help text for each entry of each menu.
#-
   global HELP
   global MENUHELPS
   global FHELP 
   global HAREA
   global HLAB
   global HSTRUT

# Ignore separators and tearoffs
   set mty [$win type @$y] 
   if { $mty != "separator" && $mty != "tearoff" } {

# Get the label from the menu entry under the pointer.
      set label [$win entrycget @$y -label]

# Get the help text associated with this menu entry
      if { [info exists MENUHELPS($win,$label)] } {
         set HELP $MENUHELPS($win,$label)

# If the vertical strut which stops the help area collapsing when the
# the number of lines in the help area reduces, is smaller than the
# current height of the help area, extend it.
         if { $FHELP != "" && $HAREA } {
            set whgt [winfo height $HLAB]
            set shgt [winfo height $HSTRUT]
            if { $shgt < $whgt } {
               $HSTRUT configure -height $whgt
            }
         }

      } {
         set HELP ""
      }
   } {
      set HELP ""
   }
}

proc Message {message} {
#+
#  Name:
#    Message
#
#  Purpose:
#    Display a dialogue box displaying a message, and wait for the
#    user to press the "OK" button.
#
#  Arguments:
#    message
#       The message to display. 
#
#  Globals:
#    TOP (Read)
#        The path to the main application window.
#-
   global TOP
   global env

# If the top level window has not yet been created, message to standard 
# output 
   if { ![info exists TOP] } {
      puts $message

# Otherwise, display the message in a dialog box.
   } {

# Display the dialog box.
      dialog .msg "LutEdit - Message..." $message {} 0 OK

   }
}

proc MotionBind {x y} {
#+
#  Name:
#    MotionBind
#
#  Purpose:
#    Process pointer motion over the editor with no buttons pressed.
#
#  Arguments:
#    x
#       The screen X coord.
#    y
#       The screen Y coord.
#
#-

}

proc my_exit {args} {
#+
#  Name:
#    my_exit
#
#  Purpose:
#    Shutdown the tcl script, cleaning up in the process.
#
#  Arguments:
#    args
#       The exit integer status value.
#
#  Globals:
#    ADAM_TASKS (Read)
#       A list of the names of the ADAM tasks started up by LutEdit.
#    ADAM_USER (Read)
#       The path to the temporary ADAM_USER directory used by LutEdit.
#    OLD_ADAM_USER (Read)
#       The original value of the ADAM_USER environment variable, or a null
#       string if ADAM_USER was not defined.
#    LUTEDIT_SCRATCH (Read)
#       The path to the directory used by LutEdit to store temporary NDFs.
#
#  Notes:
#    - This command replaces the built-in Tcl "exit" command, which should
#    have been renamed as "tcl_exit".
#-
   global ADAM_TASKS
   global ADAM_USER
   global env
   global LOGFILE_ID
   global OLD_ADAM_USER
   global OLD_AGI_USER
   global LUTEDIT_SCRATCH

# Re-instate the original exit command in case anything goes wrong in
# this procedure.
   rename exit {}
   rename tcl_exit exit

# Close any log file.
   if { $LOGFILE_ID != "" && $LOGFILE_ID != "stdio" } { close $LOGFILE_ID }

# Kill all the ADAM tasks started up by LutEdit.
   foreach task $ADAM_TASKS {
      if { [info commands $task] != "" } {
         catch {$task kill}
      }
   }

# Delete the temporary ADAM_USER directory created at the start.
   catch "exec rm -rf $ADAM_USER"

# Delete the LUTEDIT_SCRATCH directory created at the start.
   catch "exec rm -rf $LUTEDIT_SCRATCH"

# Re-instate the original ADAM_USER and AGI_USER environment variables.
   if { $OLD_ADAM_USER != "" } {
      set env(ADAM_USER) $OLD_ADAM_USER
   } {
      unset env(ADAM_USER)
   }

   if { $OLD_AGI_USER != "" } {
      set env(AGI_USER) $OLD_AGI_USER
   } {
      unset env(AGI_USER)
   }

# Finally, kill the current process.
   exit
}

proc New {} {
#+
#  Name:
#     New
#
#  Purpose:
#     Close the current colour table and load a new greyscale colour table.
#
#  Arguments:
#     none
#-
   global LUTFILE
   global UP
   global LP
   global NEW
   global NENT
   global NEWNENT
   global UWIN

#  If there are changes, give the user the chance to save them.
   if { [Saver] } { 

#  Only proceed if it is ok to erase the current LUT, and if a value is
#  given for the number of entries in the new LUT.
      set type(NEWNENT) "_INTEGER"
      set lab(NEWNENT) "Number of entries in new colour table"
      set lim(NEWNENT) [list 2 256]
      if { ![info exists NEWNENT] } { set NEWNENT $NENT }

      if { [GetPars [list NEWNENT] type lab lim "LUTEDIT - New" "" "Specify the properties of the new colour table" ] } {

#  Indicate that the current LUT has no associated file, and that it there
#  are changes to be saved.
         set LUTFILE ""

#  Empty the editor.
         emptyEditor

# Set the name of the top level window.
         wm  title $UWIN "LutEdit <untitled>"

#  Load grey curves into the editor and update the GWM items.
         greyCurves $NEWNENT

#  Save the current LUT arrays as the originals.
         orig

#  Update the editor to display the new colour table.
         updateDisplay 0

#  Indicate that a new colour table has been started.
         set NEW 1

      }
   }
}

proc Obey {task action params args} {
#+
#  Name:
#    Obey
#
#  Purpose:
#    Executes an ADAM application. 
#
#  Arguments:
#    task
#       The name of the task containing the application (eg "kapview").
#    action
#       The name of the application (eg "display").
#    params
#       Any command line parameter assignments to pass to the 
#       application. A blank string must be supplied if no 
#       command line parameter assignments are needed.
#    args
#       o  If the optional string "noreport" is supplied, then any error
#       messages generated by the action are not displayed. 
#       o  If the name of a currently defined global variable is supplied, 
#       then the variable is assumed to be a 1-D array, indexed by A-task
#       parameter name. The associated values are the values to supply for 
#       the A-task's parameters if they are prompted for. 
#       o  The presence of any other non-blank value after "params" causes
#       the whole TCL application to abort if the specified action
#       does not complete succesfully.
#
#  Returned Value:
#    If the application completes succesfully, then 1 is returned.
#    Otherwise, 0 is returned.
#
#  Globals:
#    ACTION (Write)
#      Name of current action in the form "task:action".
#    ADAM_ERRORS (Write)
#      The messages from the most recent ADAM application to fail.
#    ATASK_OUTPUT (Write)
#       Any non-error messages generated by the action are appended to 
#       this list. Each message is stored as a new element in the list.
#    STATUS (Write)
#      The status string returned by the action.
#
#  Notes:
#    - The Task must already have been loaded using LoadTask.
#    - Any error messages created by the action are displayed in a dialog
#    box, unless the optional argument "args" has the value "noreport".
#    - This procedure does not return until the application has finished.
#    In the mean time, the display is "frozen" so that no further actions
#    can be initiated.
#-
   global ACTION
   global ADAM_ERRORS
   global ATASK_OUTPUT
   global CANCEL_OP
   global LOGFILE_ID
   global STATUS

# Return without action if the opoeration was canceleed.
   if { $CANCEL_OP } { return 0 }

# Store the current action being performed in global.
   set ACTION "$task:$action"

# Classify the optional argument (if supplied). By default, parameter
# requests are replied to be sending a PAR__NULL (!) value, errors do
# not cause the application to abort, and errors are reported.
   set param_req "$task paramreply %R \!"
   set abort 0
   set report 1

   if { $args != "" } {

# See if an array of parameter values has been supplied.
      upvar #0 $args plist
      if { [info exists plist] } {
         set param_req "if { \[info exists ${args}(%n)\] } {
                           $task paramreply %R \$${args}(%n)
                        } {
                           $task paramreply %R \!
                        }"

# Otherwise, see if error reports are to be ignored.
      } elseif { $args == "noreport" } {
         set report 0

# Otherwise, abort on an error.         
      } elseif { [lindex $args 0] != "" } { 
         set abort 1
      }
   }

# Check that the AMS rendevous file still exists. If it doesn,t kill the
# task and reload it.
   CheckRF $task

# Clear any current ADAM messages.
   set ADAM_ERRORS {}
   set ATASK_OUTPUT {}

# Write the command we are to obey to the log file if there is one.
   if { $LOGFILE_ID == "stdio" } {
      puts "\n$task $action $params..."
   } elseif { $LOGFILE_ID != "" } {
      puts $LOGFILE_ID "\n$task $action $params..."
   }

# Start the action. Any messages generated by the action are processed
# by procedure CheckMsg. Error messages are appended to ADAM_ERRORS, other
# messages are thrown away. Parameter requests are responded to by
# sending a null (!) value. The variable STATUS is set when the
# action completes.
   set STATUS ""   
   $task obey $action $params -inform "CheckMsg $action %V" \
                      -endmsg {set STATUS "%S"} \
                      -paramreq $param_req

# Wait until the action is finished. Check that the Rendevous file exists
# every 200 milliseconds. If the WaitFor command aborts early, try
# re-executing the obey command. Do not re-execute the command if it was
# terminated due to a user requested cancel (indicated by CANCEL_OP being
# non-zero).
   if { ![WaitFor STATUS [list CheckRF $task] 200] && !$CANCEL_OP } {
      set ADAM_ERRORS {}
      set ATASK_OUTPUT {}

      if { $LOGFILE_ID == "stdio" } {
         puts "\n$task $action $params..."
      } elseif { $LOGFILE_ID != "" } {
         puts $LOGFILE_ID "\n$task $action $params..."
      }

      set STATUS ""   
      $task obey $action $params -inform "CheckMsg $action %V" \
                         -endmsg {set STATUS "%S"} \
                         -paramreq $param_req

      if { ![WaitFor STATUS [list CheckRF $task] 200] && !$CANCEL_OP } {
         Message "Problems with rendevous file! Aborting..."
         exit 1
      }
   }

# Set the return status. If the final status does not contain the string
# DTASK__ACTCOMPLET, assume the action failed.
   if { ![regexp {DTASK__ACTCOMPLET} $STATUS] } {
      set ok 0
   } {
      set ok 1
   }

# Display any error messages.
   if { $report && $ADAM_ERRORS != "" } {
      Message "$task action \"$action\" reported:\n$ADAM_ERRORS"
   }

# If failure is fatal, shut down.
   if { !$ok && $abort } {exit 1}

# Indicate that we are no longer executing an ADAM action.
   set ACTION ""

# Return the status. Return zero if the operation was cancelled by the
# user.
   if { $CANCEL_OP } { set ok 0 }

   return $ok
}

proc Pop {stack args} {
#+
#  Name:
#    Pop
#
#  Purpose:
#    Returns and removes the top value in the supplied FILO stack.
#
#  Arguments:
#    stack
#       The name (NOT the value) of a global list variable holding the stack. 
#       On exit, the list holds one less element than on entry.
#    args
#        An optional argument giving the number of levels to pop off the
#        stack. It defaults to 1. If it is supplied as -1, then the 
#        the first (bottom) entry is returned and the stack is emptied. If it
#        is supplied as 0, then the top entry on the stack is returned, but 
#        it is not removed from the stack.
#
#  Returned Value:
#    The required stack element, or an empty string if the supplied stack 
#    was empty.
#-

   upvar #0 $stack stk

   if { $args == "" } {
      set levels 1
   } { 
      set levels $args
   }

   if { $levels == -1 } {
      set ret [lindex $stk end]
      set stk ""

   } elseif { $levels == 0 } {
      set ret [lindex $stk 0]

   } {
      set ret [lindex $stk [expr $levels - 1] ]
      set stk [lrange $stk $levels end]
   } 

   return $ret
}

proc Push {stack value} {
#+
#  Name:
#    Push
#
#  Purpose:
#    Enter a new value onto the top of the supplied FILO stack.
#
#  Arguments:
#    stack
#       The name (NOT the value) of a global list variable holding the stack. 
#       On exit, the list holds one more element than on entry.
#    value
#       The value to be pushed onto stack.
#
#  Returned Value:
#    The supplied value.
#
#  Notes:
#    - The new entry is stored at index 0 in the list, and existing entries
#    are moved up to make room for it.
#-
   upvar #0 $stack stk
   set stk [linsert $stk 0 $value]
   return $value
}

proc RealValue {name width value command args} {
#+
#  Name:
#    RealValue
#
#  Purpose:
#    Create a simple numerical value entry "widget". 
#
#  Arguments:
#    name
#      The name of the "entry" to create (eg ".wm.maxval")
#    width
#      The number of characters in the text entry widget.
#    value
#      The name (NOT the value) of the global variable to receive the 
#      numerical value. Note, this must be a *global* variable.
#    command
#      A command to execute after a valid value has been assigned to the
#      variable.
#    args 
#      Any further options to pass to the command which creates the
#      "entry" widget (optional).
#
#  Returned Value:
#    The name of the entry widget.
#
#  Globals:
#    OLD_VAL (Write)
#      The previous (valid) value displayed in the text entry widget.
#-
   global OLD_VAL
   global $value
   upvar #0 $value varr

# Create the text entry widget. The text in this widget mirrors the value in
# the supplied global variable.
   eval entry $name -width $width -relief sunken -bd 2 -textvariable $value \
          -justify center $args
   $name select from 0
   $name select to end
   focus $name

# Save the current value of the variable.
   set OLD_VAL $varr

# When the pointer enters the text entry area, select the entire current
# contents of the widget so that typing a single character will delete it.
# Also take the focus, and save the current numerical value so that it
# can be re-instated if the user enters a duff value
   bind $name <Enter> \
      "if { \[$name cget -state\] == \"normal\" } {
          $name select from 0
          $name select to end

          set OLD_VAL \$$value
       }"

# When <Return> is pressed or the focus leaves the current entry, check that 
# the current text represents a valid value (if not, the old value will be 
# re-instated). 
   set check "if { \[$name cget -state\] == \"normal\" } {
                set $value \[string trim \$$value\]
                if { \[scan \$$value \"%%g\" $value\] < 1 } { 
                   set $value \$OLD_VAL 
                } elseif { \$OLD_VAL != \$$value } {
                   eval \"$command\"
                }
             }"
   bind $name <Return> $check
   bind $name <FocusOut> $check

# Store a command to process termination of data entry. Clear the current 
# selection, pass the focus back to the window which had it before, and 
# check that the current text represents a valid value (if not, the old 
# value will be re-instated).
   set done "if { \[$name cget -state\] == \"normal\" } {
                $name select clear
                set $value \[string trim \$$value\]
                if { \[scan \$$value \"%%g\" $value\] < 1 } { 
                   set $value \$OLD_VAL 
                } elseif { \$OLD_VAL != \$$value } {
                   eval \"$command\"
                }
             }"

# Execute this command when the pointer leaves the text entry area, when
# <Tab> is pressed.
   bind $name <Leave> $done
   bind $name <Tab> $done

# Return the name of the created entry widget.
   return $name
}

proc ReleaseBind {x y} {
#+
#  Name:
#    ReleaseBind
#
#  Purpose:
#    Process button-1 releases over the editor. 
#
#  Arguments:
#    x
#       The screen X coord.
#    y
#       The screen Y coord.
#
#  Globals:
#     CAN2 (Read)
#        The name of the canvas widget holding the editor.
#     MODE (Read and Write)
#        The interaction mode determining how to process button clicks
#        and motion in the GWM canvas item. 
#     ROOTX (Read)
#        The canvas X coordinate at which the button was pressed.
#     ROOTY (Read)
#        The canvas Y coordinate at which the button was pressed.
#-
   global CAN2
   global CFREEZE
   global CP0
   global CP1
   global CP2
   global CPL1 
   global CPL2 
   global CURSID
   global CURX
   global CURY1
   global CURY2
   global CXH
   global CXH
   global CXL
   global CXL
   global CYH
   global CYL
   global DOUBLE
   global EX0
   global EX1
   global EVAL
   global HENTRY
   global LENTRY
   global LUT
   global MENT
   global MODE
   global PVAL
   global PX0
   global PX1
   global RGBNOW
   global ROOTX
   global ROOTY
   global SEG 
   global SELID
   global XE0
   global XE1
   global YOFF
   global YSCALE

# Convert the screen coords to canvas coords.
   set cx [$CAN2 canvasx $x]
   set cy [$CAN2 canvasy $y]

#  Limit to the usable area. (Note $CYH < $CYL since Y increases
#  downwards).
   if { $cy < $CYH } {
      set cy $CYH
   } elseif { $cy > $CYL } {
      set cy $CYL
   }
   if { $cx > $CXH } {
      set cx $CXH
   } elseif { $cx < $CXL } {
      set cx $CXL
   }

# The global variable MODE determines how events over the canvas are 
# processed. 

# Dragging a control point
   if { $MODE == "cp" } {
      set cx $ROOTX

#  Delete the two lines which were drawn when the button was clicked.
      $CAN2 delete $CPL1 $CPL2 

#  find the change in intensity at the control point.
      set incy [expr ($YOFF-$cy)/$YSCALE - [lindex $LUT($RGBNOW) $CP0] ]

#  Move all the entries between CP1 and CP0 up a bit.
      if { $CP1 != "" } {
         set dy [expr $incy/($CP0 - $CP1) ]
         set inc 0
      } else {
         set dy 0
         set inc $incy
         set CP1 0
      }

      set new ""
      for {set i $CP1} {$i <= $CP0} {incr i} {
         set nv [expr [lindex $LUT($RGBNOW) $i] + $inc]
         if { $nv > 1.0 } { set nv 1.0 } elseif { $nv < 0.0 } { set nv 0.0 }
         append new "$nv "
         set inc [expr $inc + $dy]
      }
        
#  Move all the entries between CP0 and CP2 up a bit.
      set inc $incy
      if { $CP2 != "" } {
         set dy [expr $incy/($CP2 - $CP0) ]
      } else {
         set dy 0
         set CP2 [expr [llength $LUT($RGBNOW)] -1 ]
      }

      for {} {$i <= $CP2} {incr i} {
         set inc [expr $inc - $dy]
         set nv [expr [lindex $LUT($RGBNOW) $i] + $inc]
         if { $nv > 1.0 } { set nv 1.0 } elseif { $nv < 0.0 } { set nv 0.0 }
         append new "$nv "
      }
        
      set LUT($RGBNOW) [eval lreplace {$LUT($RGBNOW)} $CP1 $CP2 $new]

      updateCurrent 
      record

# Moving a curve segment vertically: change the LUT and update the current 
# curve. Set the cursor position to the centre of the mark.
   } elseif { $MODE == "seg" } {
      set nv [expr ($YOFF-$cy)/$YSCALE]
      if { $nv != [lindex $LUT($RGBNOW) $MENT] } {
         set LUT($RGBNOW) [lreplace $LUT($RGBNOW) $MENT $MENT $nv]
         updateCurrent 
         record
      }

# Selecting pens: Store the high and low selected entry numbers. Do not
# do this if a double click binding has just selected all pens.
   } elseif { $SELID != "" && !$DOUBLE } {
      if { $CURX >= $ROOTX } {
         set HENTRY [expr round( $EX0+$EX1*$CURX )]
         set LENTRY [expr round( $EX0+$EX1*$ROOTX )]
      } else {
         set LENTRY [expr round( $EX0+$EX1*$CURX )]
         set HENTRY [expr round( $EX0+$EX1*$ROOTX )]
      }
      select
   } 

#  Any double click is now finished with.
   set DOUBLE 0

#  Unfreeze the cursor shape
   set CFREEZE 0

# Move the cursor line to the current pointer position.
   if { $CURSID != "" } {
      $CAN2 coords $CURSID $CURX $CURY1 $CURX $CURY2
      updateCursor 0
   }


}

proc Resize {} {
#+
#  Name:
#     Resize
#
#  Purpose:
#     Respond to an interactive re-size of the window.
#
#  Arguments:
#     None
#
#  Returned Value:
#     None
#-
   global TKT

#  We do not want to continually update the GWM items if the interface is
#  slowly resized by the user (causing a series of continual calls to ths
#  procedure), because each GWM update takes ages. We just want to
#  respond to the final resize. So... Issue a ticket to the current resize, 
#  and then tell it to wait for a second. If no other tickets have been 
#  taken at the end of 1 second, then go ahead and resize the display 
#  (resetting the ticket number for the next resize).
   incr TKT
   after 1000 "
      if { \$TKT == $TKT } {
          doResize
          set TKT 0
      }
   "
}

proc doResize {} {
#+
#  Name:
#     doResize
#
#  Purpose:
#     Replace the GWM canvas item with a new one with an appropriate new size.
#
#  Arguments:
#     None
#
#  Returned Value:
#     None
#-
   global CAN
   global CAN2
   global KEEPFILE
   global GWMNEW
   global CURY1
   global CURY2
   global LUT
   global DEVICE
   global UWIN
   global INITLUT
   global LUTFILE
   global TKT

#  Cancel the binding for Configure so that the configuration changes 
#  produced by this procedure do not cause an infinite loop.
   set com [bind $UWIN <Configure>]
   bind $UWIN <Configure> ""

#  Make a new GWM canvas item, if required (i.e. if the canvas has
#  changed size).
   gwmMake 

#  If the GWM canvas item has changed size, or has not yet been used...
   if { ![info exists CURY1] } { set GWMNEW 1 }
   if { $GWMNEW || ![info exists CURY1] } { 

# Establish the graphics and image display devices.
      Obey kapview paldef "device=$DEVICE" 1
      Obey kapview gdclear "device=$DEVICE" 1
      Obey kapview gdset "device=$DEVICE" 1
      Obey kapview idset "device=$DEVICE" 1

#  Create the pictures to hold an image and a histogram-style key.
      Obey kapview picdef "current=no mode=cl fraction=\[0.4,1.0\] outline=no" 1
      Obey kapview piclabel "label=image" 1
      Obey kapview picdef "current=no mode=cr fraction=\[0.6,0.9\] outline=no" 1
      Obey kapview piclabel "label=hist" 1
      Obey kapview picdef "current=yes mode=cc fraction=\[0.8,1.0\] outline=no" 1
      Obey kapview piclabel "label=hist2" 1

#  Create transparent rectangle canvas items corresponding to each of the
#  display and histogram pictures. These are just used as handles to which
#  dynamic help strings can be attached.
      set c [$CAN bbox gwm]
      set x1 [lindex $c 0]
      set y1 [lindex $c 1]
      set x2 [lindex $c 2]
      set y2 [lindex $c 3]
      set dw [expr 0.05*($y2 - $y1 )]
      set y1 [expr $y1 + $dw]
      set y2 [expr $y2 - $dw]
      set rx [expr $x2 - $x1]
      $CAN create rectangle [expr 0.05*$rx + $x1] $y1 [expr 0.35*$rx + $x1] $y2 -outline "" -tags disp 
      $CAN create rectangle [expr 0.45*$rx + $x1] $y1 [expr 0.9*$rx + $x1] $y2 -outline "" -tags hist 

#  Determine the canvas y value at which to place the top and bottom of the 
#  cursor. Make sure the cursor extends across the entire scrollable area of 
#  the widget window.
      update idletasks
      set sy [winfo y $CAN2]
      set sh [winfo height $CAN2]
      set CURY1 [$CAN2 canvasy [expr $sy - $sh]]
      set CURY2 [$CAN2 canvasy [expr $sy + 2*$sh]]
      set bbox [$CAN2 cget -scrollregion]
      if { $bbox != "" } {
         set cy1 [lindex $bbox 1]
         set cy2 [lindex $bbox 3]
         if { $cy1 < $CURY1 } { set CURY1 $cy1 }
         if { $cy2 > $CURY2 } { set CURY2 $cy2 }
      }

#  If this is the first time an image has been displayed, load the
#  specified initial LUT if any.
      if { $INITLUT != "" } {
         set done [openNamed $INITLUT 1]
         if { !$done } { 
            set LUTFILE $INITLUT 
            set KEEPFILE 1 
         }
         set INITLUT ""
      } else {
         set done 0      
      }

#  If no colour table has yet been loaded, save the current kappa colour 
#  table into a text file, and initialize the editor to use it.
      if { !$done } { 
         Read 0
         updateDisplay 1
      }
   }

#  Re-instate the original binding for Configure.
   bind $UWIN <Configure> $com

}

proc Save {conf} {
#+
#  Name:
#     Save
#
#  Purpose:
#     Save the current colour table.
#
#  Arguments:
#     conf
#        If non-zero, then user must confirm that it is OK to replace
#        an existing file. If zero, then existing files are replaced
#        without needing confirmation.
#
#  Returned Value:
#     One for success, zero for failure.
#
#  Globals:
#
#-
   global LUTFILE
   set ok 0

   if { $LUTFILE == "" } {
      set ok [SaveAs]
   } else {
      saveLUT $LUTFILE $conf
      orig
   }
   return $ok

}

proc SaveAs {} {
#+
#  Name:
#     SaveAs
#
#  Purpose:
#     Save the current colour table to a new file.
#
#  Arguments:
#     None.
#
#  Returned Value:
#     One for success, zero for failure.
#
#  Globals:
#
#-
   global LUTFILE
   global UWIN

   set ok 0

# Get the name of the NDF in which to save the LUT.
   set file [tk_getSaveFile -defaultextension ".sdf" -filetypes {{SDF {.sdf}} {All {*}}}]

#  If ok, store the name of the NDF and use the Save proc.
   if { $file != "" } { 
      set LUTFILE $file
      set ok [Save 1]

# Set the name of the top level window.
      if { $ok } { 
         wm  title $UWIN "LutEdit $file"
      }

   }

   return $ok

}

proc saveLUT {file conf} {
#+
#  Name:
#     saveLUT
#
#  Purpose:
#     Save the current colour table into a named file.
#
#  Arguments:
#     file
#        The name of the NDF to create.
#     conf 
#        If 1, then confirm that it is OK to replace an existing file.
#
#  Returned:
#     One if the file was created, and zero otherwise.
#
#-
   global NENT
   global LUT
   global CSYSNOW

   set ndf [file rootname $file]
   set file "$ndf.sdf"

#  If the file exists check that it can be over-written.
   if { [file exists $file] } {
      if { $conf } {
         set ok [Confirm "The file $file already exists.\n\nOver-write it?"]
      } else {
         set ok 1
      }

#  Attempt to remove any existing file.
      if { $ok && ![file writable $file] } {
         Message "The existing file $file is write-protected."
         set ok 0
      } else {
         file delete -force $file
      }

   } else {
      set ok 1
   }

#  If OK...
   if { $ok } {

#  If required, changed values to RGB values.
      set lut(red) $LUT(red)
      set lut(green) $LUT(green)
      set lut(blue) $LUT(blue)
      toRGB lut $CSYSNOW 

#  Open a temporary text file 
      set tfile [UniqueFile]
      set id [open $tfile "w"]

#  Write out the contents of the colour curves.
      for {set i 0} {$i < $NENT} {incr i} {
         puts $id "[lindex $lut(red) $i] [lindex $lut(green) $i] [lindex $lut(blue) $i]"
      }

#  Close the file.
      close $id

#  Convert this text file into an NDF with the same name.
      Obey kappa trandat "freename=$tfile ndf=$ndf auto=yes shape=\[3,$NENT\]"

#  Delete the text file.
      file delete -force $tfile
   }
}

proc SetHelp {widgets help args} {
#+
#  Name:
#    SetHelp
#
#  Purpose:
#    Set the text to appear at the bottom of the screen when the pointer
#    passes over a specified widgets, or over a canvas item with a
#    specified tag.
#
#  Arguments:
#    widgets
#       A list of widget names (eg ".fr1.button"), or canvas tags.
#    help
#       The text to display. 
#    args
#       An optional htx cross-reference label to be associated with the
#       widget.
#
#  Globals:
#    HELP_LABELS (Write)
#       A 1-D array index by widget name or canvas tag. Each element is an htx
#       cross-reference label to be displayed if the widget is selected
#       using "Help on pointer".
#    HELPS (Write)
#       An array holding the current help text for each widget or canvas tag.
#
#-
   global HELPS
   global HELP_LABELS

#  Loop round all supplied widgets/tags.
   foreach wid $widgets {

# Store the supplied text.
#      set HELPS($wid) [linesplit $help 70]
      set HELPS($wid) $help
 
# Store the htx label for the widget (if any).
      if { $args != "" } {
         set HELP_LABELS($wid) $args
      }
   }

# Ensure that the displayed help text is up-to-date. 
   Helper 0
   
}

proc SingleBind {x y shift} {
#+
#  Name:
#    SingleBind
#
#  Purpose:
#    Process single clicks of button 1 over the editor.
#
#  Arguments:
#    x
#       The screen X coord.
#    y
#       The screen Y coord.
#    shift
#       Was the shift key pressed when the button was clicked?

#-
   global CAN2
   global CP0
   global CPL1
   global CP1
   global CPL2
   global CP2
   global CPX1
   global CPX2
   global CPY1
   global CPY2
   global CTRL
   global CURSID 
   global CURX 
   global CURY1 
   global CURY2
   global CXH
   global CXL
   global CYH
   global CYL
   global EX0
   global EX1
   global MODE
   global MX0
   global MX1
   global PVAL
   global RGBNOW
   global ROOTX
   global ROOTY
   global YOFF
   global YSCALE
   global BACKCOL
   global CFREEZE
   global SELID
   global HENTRY
   global LENTRY

#  Freeze the cursor shape
   set CFREEZE 1

#  Delete any selection box.
   if { $SELID != "" } {
      $CAN2 delete $SELID  
      set SELID ""
      set HENTRY ""
      set LENTRY ""
   }

# Convert the screen coords to canvas coords, and record this position as
# the "root" position which is available for use by other procedures.
   set ROOTX [$CAN2 canvasx $x]
   set ROOTY [$CAN2 canvasy $y]

   if { $ROOTX > $CXH } {
      set ROOTX $CXH
   } elseif { $ROOTX < $CXL } { 
      set ROOTX $CXL
   }

   if { $ROOTY < $CYH } {
      set ROOTY $CYH
   } elseif { $ROOTY > $CYL } {
      set ROOTY $CYL
   }

#  Get the tags associated with the current canvas item.
   set curtags [$CAN2 gettags current]

#  If the click occurred over a control point.
   if { [lsearch -exact $curtags cp] != -1 } {

#  Pretent the click occurred at the centre of the control point.
      set c [$CAN2 coords current] 
      set ROOTX [lindex $c 0]
      set ROOTY [lindex $c 1]

#  Find the index of the control point within the list of control points
#  for the current colour. Only proceed if found...
      set CP0 [expr round( $EX0 + $EX1*$ROOTX )]
      set i [lsearch -exact $CTRL($RGBNOW) $CP0]
      if { $i != -1 } {

#  indicate we are dragging a control point, and set the current cursor 
#  intensity value.
         set MODE cp 
         set PVAL [format "%.3f" [expr ($YOFF - $ROOTY)/$YSCALE]]

#  Draw a line from the selected control point to the previous control point.
#  If this is the first control point, draw a horizontal line to the left
#  edge of the editor.
         if { $i > 0 } {
            set CP1 [lindex $CTRL($RGBNOW) [expr $i-1] ]
            set c [$CAN2 coords cp-$RGBNOW-$CP1]
            set CPX1 [lindex $c 0]
            set CPY1 [lindex $c 1]
         } else {
            set CPX1 $CXL
            set CPY1 $ROOTY
            set CP1 ""
         }

         set CPL1 [$CAN2 create line $CPX1 $CPY1 $ROOTX $ROOTY -fill $BACKCOL]

#  Draw a line from the selected control point to the next control point.
#  If this is the last control point, draw a horizontal line to the right
#  edge of the editor.
         set j [expr $i+1]
         if { $j < [llength $CTRL($RGBNOW)] } {
            set CP2 [lindex $CTRL($RGBNOW) $j]
            set c [$CAN2 coords cp-$RGBNOW-$CP2]
            set CPX2 [lindex $c 0]
            set CPY2 [lindex $c 1]
         } else {
            set CPX2 $CXH
            set CPY2 $ROOTY
            set CP2 ""
         }

         set CPL2 [$CAN2 create line $ROOTX $ROOTY $CPX2 $CPY2 -fill $BACKCOL]

      }

#  If the click occurred over the marker, drag the marker vertically...
   } elseif { [lsearch -exact $curtags mark] != -1 } {
      set c [$CAN2 coords mark]
      set MX0 [lindex $c 0]
      set MX1 [lindex $c 2]
      set MODE seg

   } else {
      set MODE ""
   }

   if { $CURSID != "" } {
      set CURX $ROOTX 
      $CAN2 coords $CURSID $CURX $CURY1 $CURX $CURY2
      updateCursor 0
   }
}

proc textLut {file} {
#+
#  Name:
#     textLut
#
#  Purpose:
#     Loads a new LUT from a text file. The data is placed in the global
#     LUT arrays. Other globals are initialized, but the editor and GWM 
#     items are not redrawn.

#  Arguments:
#     file
#        The name of the text file containing the LUT.
#
#-
   global CTRL
   global CPEN
   global CURX
   global LP
   global LUT
   global MENT
   global NENT
   global PPENT
   global UP
   global CSYSNOW
   global NENTM1

#  Open the file.
   if { [catch { set id [open $file "r"] } mess] } {
      Message "Failed to load a colour table from a text file: $mess"

#  If succesful, read the file contents into lists rr, gg and bb.
   } else {

      set ok 1
      set lnum 1
      set rr ""
      set gg ""
      set bb ""

      while { [gets $id line] != -1 } {
         if { [scan $line "%f %f %f" r g b] != 3 } {
            Message "Failed to read 3 colour values from line $lnum of file $file:\n\"$line\""
            set ok 0
            break
         } else {
            lappend rr $r
            lappend gg $g
            lappend bb $b
         }
         incr lnum
      }

#  Close the text file.
      close $id

#  If the file was read succesfully...
      if { $ok } {

#  Clear control points
         set CTRL(red) ""
         set CTRL(green) ""
         set CTRL(blue) ""

#  Store the colour tables.
         set LUT(red) $rr
         set LUT(green) $gg
         set LUT(blue) $bb

# Convert the RGB values in the current colour system.
         toCSYS LUT RGB

#  Set the number of LUT entries.
         set NENT [incr lnum -1] 
         set NENTM1 [expr $NENT-1]
         set PPENT [format "%.2f" [expr double($UP-$LP+1)/double($NENT)]]

#  Reset the cursor and mark.
         set MENT "" 
         set CPEN [expr round( 0.5*($LP+$UP))]

#  Calculate new transformations.
         set CURX ""
         setTrans

      }

   }

}

proc UniqueFile {} {
#+
#  Name:
#     UniqueFile
#
#  Purpose:
#     Returns a unique file name for which no file currently exists.
#     These files are created in the LUTEDIT_SCRATCH directory
#     created by LutEdit, and so do not need to be deleted when finished
#     with as they will all be deleted when the temporary ADAM_USER
#     directory is deleted when LutEdit exits.
#
#  Arguments:
#     None.
#
#  Returned Value:
#     The file name.
#
#  Globals:
#     LUTEDIT_SCRATCH (Read)
#        The path to the LUTEDIT_SCRATCH directory.
#     IFILE (Read and Write)
#        File names have a name of the form lutedit<i> where <i> is an 
#        integer, which is different for each file. IFILE
#        records the value of i used in the previous call to this
#        function. The first value of i considered is one greater than
#        that used last time.
#
#-
   global LUTEDIT_SCRATCH
   global IFILE

   incr IFILE
   set file "$LUTEDIT_SCRATCH/lutedit$IFILE"

   while { [llength [glob -nocomplain ${file}.*] ] != 0 } {
      incr IFILE
      set file "$LUTEDIT_SCRATCH/lutedit$IFILE"
   }

   return $file
}

proc WaitFor {name args} {
#+
#  Name:
#     WaitFor
#
#  Purpose:
#     Pause the caller until a named global variable changes its value.
#     Meanwhile, events are directed to a nominated "safe" window. This
#     "freezes" the display so that further actions cannot be initiated by 
#     the user
#
#  Arguments:
#     name
#        The name (NOT the value) of the global variable to be watched.
#     args
#        An optional list argument. If supplied, the first element should
#        be a command and the second element should be a time in milliseconds. 
#        The supplied command will be executed after each period of the 
#        specified time, until the variable is changed. If the delay time
#        is not supplied it defaults to 100 milliseconds. If the suppleid
#        command returns a zero value, then the loop is aborted prematurely.
#
#  Returned Value:
#     Zero if a supplied command returned a zero value or the
#     CANCEL_OP variable was set to a non-zero value (in which
#     case the delay is aborted prematurely), and one otherwise.
#
#  Globals:
#     SAFE (Read)
#        The path to a window which can receive notifivcation of all events
#        while we are waiting. This should be a window which ignores all 
#        events.
#
#  Notes:
#    - This procedure should be used in place of tkwait, which should NOT
#    be used.
#-
   global CAN
   global SAFE
   global CANCEL_OP
   global UWIN

# Access the supplied variable using the local name "VAR".
   upvar #0 $name VAR

# Save the original value of the global variable being watched.
   set orig $VAR

# Save the old cursors and switch on a "clock" cursor.
   set old_cursor [$UWIN cget -cursor]
   $UWIN config -cursor watch

   if { [info exists CAN] && [winfo exists $CAN] } {
      set old_cancur [$CAN cget -cursor]
      $CAN config -cursor watch
      set cancur 1
   } else {
      set cancur 0
   }

# Indicate that no gran has yet been made by this procedure.
   set grabset 0

# See if any command has been supplied.
   set nargs [llength $args]
   if { $nargs > 0 } {
      set com [lindex $args 0]
      if { $nargs > 1 } {
         set delay [lindex $args 1]
      } {
         set delay 100
      }
   } {
      set com ""
      set delay 100
   }

# Wait until the variable changes value, or the operation is cancelled ...
   set ret 1
   while { $VAR == $orig } {

# Attempt to set a grab on a "safe" window so that all button
# presses and mouse movements will be ignored. If succesful, note
# that we will need to release the grab.
      if { !$grabset } {
         if { ![catch "grab set $SAFE"] } {
            set grabset 1
         }
      }

# Execute any supplied command.
      if { $com != "" } {
         set ret [eval "$com"]
         if { !$ret } { break }
      }

# Break out of the loop if CANCEL_OP was set to a non-zero value.
      if { $CANCEL_OP } { break }

# Pause and then repeat.
      after $delay {set a 1}
      tkwait variable a

   }

# Release the grab set above (if any).
   if { $grabset } {
      grab release $SAFE
   }

# Revert to the previous cursors.
   $UWIN config -cursor $old_cursor

   if { $cancur } {
      $CAN config -cursor $old_cancur
   }

# Return zero if the operation has been cancelled.
   if { $CANCEL_OP } { set ret 0 }

   return $ret
}



# ==============================================================
# Main entry point...
#.

#  Display a "wait" message in a temporary toplevel.
   set wait [toplevel .wait]
   pack [label $wait.label -text "Please wait..."] -padx 10m -pady 10m
   centreWin $wait

# Initialise LutEdit global constants.
   set BACKCOL "#c0c0c0"
   set MENUBACK "#b0b0b0"
   set GWM_NCOL 64
   set CANWID 650
   set CANHGT 250
   set LP 16
   set UP [expr $GWM_NCOL - 1 ]
   set NP ""

#  Initialise LutEdit global variables.
   set ACTION ""
   set ADAM_ERRORS ""
   set ADAM_TASKS ""
   set ADAM_USER ""
   set ATASK_OUTPUT ""
   set AUTOCUT "95"
   set AUTOUP 1
   set CAN ""
   set CAN2 ""
   set CANCEL_OP 0
   set CENT ""
   set CFREEZE 0
   set CPEN ""
   set CPVIS 0
   set CSYS RGB
   set CSYSNOW RGB
   set CURSID ""
   set CURX ""
   set DOUBLE 0
   set EVAL ""
   set EX0 "" 
   set FHELP ""
   set GWM ""
   set HAREA 1 
   set HELP ""
   set HENTRY ""
   set HISTTSIZ "1.0"
   set HISTXLAB "pen"
   set HLAB ""
   set IFILE 0
   set LENTRY ""
   set LOGFILE_ID ""
   set LOGPOP 0
   set LUTFILE ""
   set MARKID ""
   set MENT ""
   set NEGIMAGE 0
   set NENT [expr $UP-$LP+1]
   set NENTM1 [expr $NENT-1]
   set NN "NO"
   set NOLD 0
   set KEEPFILE 0
   set PPENT 1
   set PVAL ""
   set RGBNOW ""
   set RGBSEL red
   set SAFE ""
   set SCAHIGH ""
   set SCALOW ""
   set SELID ""
   set STATUS ""
   set TOP ""
   set ZOOMX 1
   set ZOOMY 1
   set TKT 0

#   set LOGFILE_ID stdio

#  Name this application (for xresources etc.)
   tk appname lutedit

# Rename the "exit" command so that it calls a procedure which cleans up,
# and then calls the built-in shut-down commands. This new exit command is 
# called even if an exceptional exit occurs.
   rename exit tcl_exit
   rename my_exit exit

# Exit when control-c or Q is pressed.
   bind all <Control-c> {Finish}
   bind all <q> {Finish}
   bind all <Q> {Finish}

# Get the pixels per inch on the screen.
   if { ![info exists dpi] } {
      set dpi [winfo fpixels . "1i"]
   }       

# Set the size of the canvas widget.
   set CANWID [expr round( ( $CANWID * $dpi ) / 88.0 ) ]
   set CANHGT [expr round( ( $CANHGT * $dpi ) / 88.0 ) ]

# Get the process id for the current process.
   set PID [pid]

# Set the name to use for the GWM window, and a pgplot device
# specification which can be used to refer to it.
   set GWM_NAME "LutEdit_$PID"
   set DEVICE "$GWM_NAME/GWM"

# Set the default colour for all backgrounds.
   . configure -background $BACKCOL
   option add *background $BACKCOL

# Try to stop problems with the AMS (ADAM Message System) rendevous files 
# by creating a new directory as ADAM_USER.
   if { [info exists env(ADAM_USER)] } {
      set OLD_ADAM_USER $env(ADAM_USER)
      set ADAM_USER "$OLD_ADAM_USER/LutEdit_[pid]"
      set oldadam $OLD_ADAM_USER
   } {
      set OLD_ADAM_USER ""
      set ADAM_USER "$env(HOME)/adam/LutEdit_[pid]"
      set oldadam "$env(HOME)/adam"
   }
   set env(ADAM_USER) $ADAM_USER

# Make sure this new directory exists (delete any existing version).
   if { [file exists $ADAM_USER] } {
      catch {exec rm -r -f $ADAM_USER}
   }
   catch {exec mkdir -p $ADAM_USER}

#  Copy any existing KAPPA lut and pallete files into the new
#  adam user directory.
   if { [file exists $oldadam/kappa_lut.sdf] } {
      file copy $oldadam/kappa_lut.sdf $ADAM_USER/kappa_lut.sdf
   }

   if { [file exists $oldadam/kappa_palette.sdf] } {
      file copy $oldadam/kappa_palette.sdf $ADAM_USER/kappa_palette.sdf
   }

# Avoid messing up the main AGI database by using a new AGI database.
# Create it in the ADAM_USER directory created above.
   if { [info exists env(AGI_USER)] } {
      set OLD_AGI_USER $env(AGI_USER)
   } {
      set OLD_AGI_USER ""
   }
   set env(AGI_USER) $ADAM_USER

#  Create a directory in which LutEdit can keep the temporary files it
#  creates. This directory will be deleted on exit. Try to put it in
#  HDS_SCRATCH, if defined, and in the current directory otherwise.
   if { [info exists env(HDS_SCRATCH)] } {
      set dir $env(HDS_SCRATCH)
   } {
      set dir [pwd]
   }
   set LUTEDIT_SCRATCH "$dir/lutedit_temp_[pid]"

# Make sure this new directory exists (delete any existing version).
   if { [file exists $LUTEDIT_SCRATCH] } {
      catch {exec rm -r -f $LUTEDIT_SCRATCH}
   }
   catch {exec mkdir -p $LUTEDIT_SCRATCH}

# Get the KAPPA directory.
   if { [info exists env(KAPPA_DIR)] } {
      set KAPPA_DIR $env(KAPPA_DIR)
   } {
      set KAPPA_DIR /star/bin/kappa
   }

# Get the image to display and initial lut from the command line.
   if { $argc >= 2 } { 
      set IMAGE [lindex $argv 1] 
   } else {
      set IMAGE $KAPPA_DIR/m31
   }
   if { $argc >= 1 } { 
      set INITLUT [lindex $argv 0] 
   } else {
      set INITLUT ""
   }

# Define Startcl procedures (this must be done after the ADAM_USER
# directory has been set up).
   set env(ADAM_MESSAGE_RELAY) $KAPPA_DIR/adamMessageRelay
   source $KAPPA_DIR/adamtask.tcl

# The adamtask.tcl file creates a binding which causes the application to
# terminate whenever any window is destroyed. Do away with it.
   bind . <Destroy> ""

# Load the required ADAM monoliths. 
   LoadTask kapview  $KAPPA_DIR/kapview_mon
   LoadTask kappa $KAPPA_DIR/kappa_mon
   LoadTask ndfpack $KAPPA_DIR/ndfpack_mon

# Create a style file defining the style for the histogram in the GWM
# canvas.
   histStyle 0

# Create the required fonts.
   set BIG_FONT [font create -weight bold -slant italic -size 18]
   set FONT [font create -weight bold -slant roman -size 14]
   set COM_FONT [font create -weight bold -slant roman -size 18]
   set HLP_FONT [font create -weight normal -slant roman -size 12]
   set B_FONT [font create -weight bold -slant roman -size 12]
   set RB_FONT [font create -weight normal -slant roman -size 12]
   set S_BFONT [font create -weight bold -slant roman -size 12]
   set S_FONT [font create -weight normal -slant roman -size 12]
   set IT_FONT [font create -weight bold -slant italic -size 18]
   set TT_FONT [font create -family helvetica -weight normal -slant roman -size 14]

# Loop round until we have succesully create a gwm canvas item. The first
# pass round this loop attempts to manage without a private colour map.
# If the gwm canvas item cannot be created, then a second pass occurs in
# which a private colour map is used. If this also fails, then the
# application exists.
   set gotgwm 0
   set usingnewcmap 0
   while { !$gotgwm } {

#  Use a new colour map if requested.
      if { $usingnewcmap } {

#  There seems to be problems with some window manegers colormap focus
#  policy, which results in failure to load a private colormap when the
#  focus is given to a frame created with the "-colormap new" option.
#  One way to get round this seems to be for the user interface to be
#  created in a separate toplevel rather than in the main window. First,
#  create a frame in the main window with a private colour map, and then
#  create a toplevel to contain the user interface, with the same private 
#  colour map as the first frame.
         frame .hold -colormap new
         wm withdraw .
         set UWIN [toplevel .lutedit -colormap .hold]
         centreWin $UWIN

#  If we do not need a private colour map, put the user interface in the 
#  main window 
      } {
         set UWIN .
      }

# Set the name of the top level window.
      wm  title $UWIN "LutEdit <untitled>"

#  Create an all encompassing frame. 
      set TOP [frame $UWIN.top -relief raised -bd 2]

# Create a frame which goes at the top of the screen but contains nothing. 
# X events will be directed to this window during any pauses
# (see procedure WaitFor). The window has no user controls and so is
# "safe" (i.e. it will just ignore any button presses, mouse movements, etc). 
# This ensures that new commands cannot be initiated by the user before 
# previous ones have finished.
      set SAFE [frame $TOP.dummy]
      pack $SAFE

# Make the menu bar, a Frame containing info,  and the frame containing
# the GWM canvas.
      set F1 [frame $TOP.menubar -relief raised -bd 2 -background $MENUBACK]
      pack $F1 -padx 1m -pady 1m -fill x
      set F2 [frame $TOP.info]
      pack $F2 -padx 1m -pady 1m -anchor nw -fill x
      set F3 [frame $TOP.main]
      pack $F3 -padx 1m -pady 1m -fill both -expand 1

# Make the menu buttons for the menu bar.
      set file [menubutton $F1.file -text File -padx 1m -pady 1 -menu $F1.file.menu -background $MENUBACK ]
      set filemenu [menu $file.menu]
      SetHelp $file "Menu of commands for exiting, saving, opening, etc..." LUTEDIT_FILE_MENU

      set edit [menubutton $F1.edit -text Edit -menu $F1.edit.menu -background $MENUBACK ]
      set editmenu [menu $edit.menu]
      SetHelp $edit "Menu of commands to undo, etc..." LUTEDIT_EDIT_MENU

      set opts [menubutton $F1.opts -text Options -menu $F1.opts.menu -background $MENUBACK ]
      set optsmenu [menu $opts.menu]
      SetHelp $opts "Menu of commands to set up various options..." LUTEDIT_OPTIONS_MENU

      set help [menubutton $F1.help -text Help -menu $F1.help.menu -background $MENUBACK ]
      set helpmenu [menu $help.menu]
      SetHelp $help ".  Display further help information..." LUTEDIT_HELP_MENU
      addHelp $helpmenu

# Add menu items to the File menu.
      $filemenu add command -label "Open        " -command {Open} -accelerator "Ctrl-o"
      $filemenu add command -label "Read Current" -command {Read 1} -accelerator "Ctrl-r"
      $filemenu add command -label "New         " -command {New} -accelerator "Ctrl-n"
      $filemenu add command -label "Save        " -command {Save 0} -accelerator "Ctrl-s"
      $filemenu add command -label "Save As     " -command {SaveAs} -accelerator "Ctrl-a"
      $filemenu add command -label "Exit        " -command {Finish} -accelerator "Ctrl-e"
   
      MenuHelp $filemenu "Open        " "Use a colour table contained in an existing NDF."
      MenuHelp $filemenu "Read Current" "Read colour table currently in use by the image display."
      MenuHelp $filemenu "New         " "Create a new greyscale colour table."
      MenuHelp $filemenu "Save        " "Save the current colour table."
      MenuHelp $filemenu "Save As     " "Save the current colour table to a new file."
      MenuHelp $filemenu "Exit        " "Exit the application."
   
      bind $UWIN <Control-o> {Open}
      bind $UWIN <Control-r> {Read 1}
      bind $UWIN <Control-n> {New}
      bind $UWIN <Control-s> {Save 0}
      bind $UWIN <Control-a> {SaveAs}
      bind $UWIN <Control-e> {Finish}

# Add menu items to the Edit menu.
      $editmenu add command -label "Undo        " -command {undo} -accelerator "Ctrl-u"
      MenuHelp $editmenu "Undo        " "Undo up to 10 previous changes to the colour table."
      bind $UWIN <Control-u> {undo}

      $editmenu add command -label "Bridge      " -command {bridge}
      MenuHelp $editmenu "Bridge      " "Replace the currently selected pens by joining the first and the last with a straight line."

      $editmenu add command -label "Resample    " -command {resample}
      MenuHelp $editmenu "Resample    " "Change the number of entries in the colour table by resampling the existing entries."

      $editmenu add command -label "Rotate      " -command {rotate}
      MenuHelp $editmenu "Rotate      " "Rotate the selected pens left or right by a given number of pens (rotates whole table if no pens are selected)."

      $editmenu add command -label "Set constant" -command {setCon}
      MenuHelp $editmenu "Set constant" "Set the selected pens to a specified constant value."

      $editmenu add command -label "Smooth      " -command {smooth}
      MenuHelp $editmenu "Smooth      " "Smooth the currently selected pens using a box filter of specified width."

      $editmenu add command -label "Flip current" -command {flip 0}
      MenuHelp $editmenu "Smooth      " "Flip the current curve horizontally."

      $editmenu add command -label "Flip all" -command {flip 1}
      MenuHelp $editmenu "Smooth      " "Flip all curves horizontally."

# Add menu items to the Options menu.
      $optsmenu add checkbutton -label "Auto-update" -variable AUTOUP 
      MenuHelp $optsmenu "Auto-update" "Update the image display and histogram automatically whenever any change is mad to the colour table?"

      set csysmenu "$optsmenu.csys"
      MenuHelp $optsmenu "Colour system" "Specifies how colours are represented within the colour editor"
      $optsmenu add cascade -label "Colour system" -menu $csysmenu
         menu $csysmenu 
         $csysmenu add radiobutton -label "RGB" -variable CSYS -value RGB -command newCsys
         MenuHelp $csysmenu "RGB" "Colours are represented by red, green and blue intensities."
         $csysmenu add radiobutton -label "HSV" -variable CSYS -value HSV -command newCsys
         MenuHelp $csysmenu "HSV" "Colours are represented by hue, saturation and value."
         $csysmenu add radiobutton -label "Greyscale" -variable CSYS -value MONO -command newCsys
         MenuHelp $csysmenu "Greyscale" "All colours are shades of grey."
   
      set intermenu "$optsmenu.inter"
      MenuHelp $optsmenu "Interpolation" "Specifies how to interpolate the table entries to get individual pen value"
      $optsmenu add cascade -label "Interpolation" -menu $intermenu
         menu $intermenu 
         $intermenu add radiobutton -label "Linear" -variable NN -value NO -command "updateDisplay 0"
         $intermenu add radiobutton -label "Nearest neighbour" -variable NN -value YES -command "updateDisplay 1"
   
      set imagemenu "$optsmenu.image"
      $optsmenu add cascade -label "Image display" -menu $imagemenu
      MenuHelp $optsmenu "Image display" "Options related to the image display"
         menu $imagemenu 

         set imagecutmenu "$imagemenu.cut"
         $imagemenu add cascade -label "Auto-cut" -menu $imagecutmenu
         MenuHelp $imagemenu "Auto-cut" "Set the displayed data limits by specifying the percentage of pure white and pure black pixels."
            menu $imagecutmenu
            $imagecutmenu add radiobutton -label "0.1%" -variable AUTOCUT -value 99.9 -command imageDisp
            $imagecutmenu add radiobutton -label "0.5%" -variable AUTOCUT -value 99.5 -command imageDisp
            $imagecutmenu add radiobutton -label "1%" -variable AUTOCUT -value 99 -command imageDisp
            $imagecutmenu add radiobutton -label "5%" -variable AUTOCUT -value 95 -command imageDisp
            $imagecutmenu add radiobutton -label "10%" -variable AUTOCUT -value 90 -command imageDisp
            $imagecutmenu add radiobutton -label "15%" -variable AUTOCUT -value 85 -command imageDisp
            $imagecutmenu add radiobutton -label "20%" -variable AUTOCUT -value 80 -command imageDisp
            $imagecutmenu add radiobutton -label "30%" -variable AUTOCUT -value 70 -command imageDisp

         $imagemenu add checkbutton -label "Negative" -variable NEGIMAGE -command imageDisp
         MenuHelp $imagemenu "Negative" "Display a negative image (i.e. map the lowest pen onto the upper data limit, and vice-versa)"

      set histmenu "$optsmenu.hist"
      $optsmenu add cascade -label "Histogram" -menu $histmenu
      MenuHelp $optsmenu "Histogram" "Options related to the histogram."
         menu $histmenu 

         set histlabmenu "$histmenu.lab"
         $histmenu add cascade -label "X axis labels" -menu $histlabmenu
         MenuHelp $histmenu "X axis labels" "Set the quantity to display along the horizontal axis of the histogram."
            menu $histlabmenu 
            $histlabmenu add radiobutton -label "Pen number" -variable HISTXLAB -value pen -command "histStyle 1"
            $histlabmenu add radiobutton -label "Data value" -variable HISTXLAB -value data -command "histStyle 1"
   
         set histtsizmenu "$histmenu.tsiz"
         $histmenu add cascade -label "Text size" -menu $histtsizmenu
         MenuHelp $histmenu "Text size" "Scale factor for histogram text."
            menu $histtsizmenu 
            $histtsizmenu add radiobutton -label "0.25" -variable HISTTSIZ -value 0.25 -command "histStyle 1"
            $histtsizmenu add radiobutton -label "0.5" -variable HISTTSIZ -value 0.5 -command "histStyle 1"
            $histtsizmenu add radiobutton -label "0.85" -variable HISTTSIZ -value 0.85 -command "histStyle 1"
            $histtsizmenu add radiobutton -label "1.0" -variable HISTTSIZ -value 1.0 -command "histStyle 1"
            $histtsizmenu add radiobutton -label "1.25" -variable HISTTSIZ -value 1.25 -command "histStyle 1"
            $histtsizmenu add radiobutton -label "1.5" -variable HISTTSIZ -value 1.5 -command "histStyle 1"
            $histtsizmenu add radiobutton -label "1.75" -variable HISTTSIZ -value 1.75 -command "histStyle 1"
            $histtsizmenu add radiobutton -label "2.0" -variable HISTTSIZ -value 2.0 -command "histStyle 1"
            $histtsizmenu add radiobutton -label "2.5" -variable HISTTSIZ -value 2.5 -command "histStyle 1"
            $histtsizmenu add radiobutton -label "3.0" -variable HISTTSIZ -value 3.0 -command "histStyle 1"
   
         $histmenu add checkbutton -label "Logarithmic Y axis" -variable LOGPOP -command "histStyle 1"
         MenuHelp $histmenu "Logarithmic Y axis" "Display the log base 10 of the bin populations on the vertical axis of the histogram?."
   
      $optsmenu add separator 
      $optsmenu add command -label "Save options" -command {saveOpts} -accelerator "Ctrl-p"
      MenuHelp $optsmenu "Save options" "Save the current options settings so that they become the default settings in future."
      bind $UWIN <Control-p> {saveOpts}
      

#  Pack the menu buttons.
      pack $file $edit $opts -side left 
      pack $help -side right

#  Create and pack the canvas widget.
      set CAN [canvas $F3.can -background black -height $CANHGT -width $CANWID]
      pack $CAN  -side top -anchor e -fill both -expand 1

#  Atemmpt to create the GWM canvas item.
      set mess [gwmMake]

# If this failed, prepare to try again with a private colour map. Destroy
# the all--encompassing frame, and set a flag to indicate that a private
# colour map should be used.
      if { $mess != "" } {
         if { !$usingnewcmap } {
            destroy $TOP
            set usingnewcmap 1 

# If we failed while using a private colour map, give up.
         } {
            Message "Failed to create the image display.\n\n$mess"
            exit
         }

      } else {
         set gotgwm 1
      }
   }

   wm deiconify $UWIN

#  The info panel above the GWM canvas.
   grid columnconfigure $F2 [list 0 1 2 3 4 5] -weight 1
   grid [label $F2.l1 -text "Lowest pen index: "]  -column 0 -row 0 -sticky ne
   grid [label $F2.l2 -textvariable LP] -column 1 -row 0 -sticky nw
   SetHelp [list $F2.l1 $F2.l2] "The lowest pen index reserved for the colour table." LUTEDIT_LP

   grid [label $F2.l3 -text "  No. of table entries: "]  -column 2 -row 0 -sticky ne
   grid [label $F2.l4 -textvariable NENT] -column 3 -row 0 -sticky nw
   SetHelp [list $F2.l3 $F2.l4] "The number of entries in the colour table (spread evenly amongst the available pens)." LUTEDIT_NENT

   grid [label $F2.l5 -text "  Low display value: "]  -column 4 -row 0 -sticky ne
   grid [label $F2.l6 -textvariable SCALOW] -column 5 -row 0 -sticky nw
   SetHelp [list $F2.l5 $F2.l6] "The displayed image data value corresponding to the lowest pen index." LUTEDIT_NENT

   grid [label $F2.l7 -text "Highest pen index: "]  -column 0 -row 1 -sticky ne
   grid [label $F2.l8 -textvariable UP] -column 1 -row 1 -sticky nw
   SetHelp [list $F2.l7 $F2.l8] "The highest pen index available on the image display." LUTEDIT_LP

   grid [label $F2.l9 -text "  Pens per table entry: "]  -column 2 -row 1 -sticky ne
   grid [label $F2.l10 -textvariable PPENT] -column 3 -row 1 -sticky nw
   SetHelp [list $F2.l9 $F2.l10] "The number of pens in each table entry." LUTEDIT_PPENT

   grid [label $F2.l11 -text "  High display value: "]  -column 4 -row 1 -sticky ne
   grid [label $F2.l12 -textvariable SCAHIGH] -column 5 -row 1 -sticky nw
   SetHelp [list $F2.l11 $F2.l12] "The displayed image data value corresponding to the highest pen index." LUTEDIT_NENT

#  Create and pack the second canvas widget.
   set F4 [frame $F3.editor]

   set cframe [frame $F4.cframe -relief sunken -bd 3 -bg $MENUBACK]
   set YSCROLL $cframe.yscroll
   set XSCROLL $cframe.xscroll
   
   set CAN2 [canvas $cframe.can2 -highlightthickness 0 -height 200 -bg $MENUBACK -yscrollcommand "$YSCROLL set" -xscrollcommand "$XSCROLL set"]
   scrollbar $YSCROLL -command "$CAN2 yview" -orient vertical -highlightthickness 0
   scrollbar $XSCROLL -command "$CAN2 xview" -orient horizontal -highlightthickness 0

   grid $CAN2 -column 0 -row 0 -sticky "nsew"
   grid $YSCROLL -column 1 -row 0 -sticky "ns"
   grid $XSCROLL -column 0 -row 1 -sticky "ew"

   grid columnconfigure $cframe 0 -weight 1
   grid columnconfigure $cframe 1 -weight 0
   grid rowconfigure $cframe 0 -weight 1
   grid rowconfigure $cframe 1 -weight 0

   pack $cframe -side left -fill both -expand 1 -pady 1m

   set rhs [frame $F4.rhs]

   set upbut [button $rhs.up -bitmap @$KAPPA_DIR/uparrow.bit -command "gwmUpdate 0"]
   SetHelp $upbut "Click to force the image and histogram to be re-displayed with the current colour table." LUTEDIT_UPBUT
   pack $upbut -side top 

   set fyzoom [frame $rhs.yzoom]
   set yplus [button $fyzoom.plus -bitmap @$KAPPA_DIR/plus.bit -command {Zoom y 1}]
   SetHelp $yplus "Press to expand vertical scale..." LUTEDIT_YPLUS
   set yminus [button $fyzoom.minus -bitmap @$KAPPA_DIR/minus.bit -command {Zoom y 0}]
   SetHelp $yminus "Press to compress vertical scale..." LUTEDIT_YMINUS
   pack $yplus $yminus -side top
   pack $fyzoom -side left -expand 1 

   pack $rhs -side left -padx 3m -pady 2m -fill y

   set F5 [frame $F3.rgbsel]
   set RB [radiobutton $F5.r -text "Red" -selectcolor red -highlightbackground red -command rgbSel -variable RGBSEL -value red -anchor w]
   set GB [radiobutton $F5.g -text "Green" -selectcolor green -highlightbackground green -command rgbSel -variable RGBSEL -value green -anchor w]
   set BB [radiobutton $F5.b -text "Blue" -selectcolor blue -highlightbackground blue -command rgbSel -variable RGBSEL -value blue -anchor w]
   pack $RB $GB $BB -side left -padx 4m -pady 1m -anchor nw
   newCsys   

   set unzoom [button $F5.unzoom -bitmap @$KAPPA_DIR/unzoom.bit -command {unzoom}]
   SetHelp $unzoom "Press to reset zoom factors..." LUTEDIT_UNZOOM
   pack $unzoom -side right -padx 3m -anchor ne

   set fxzoom [frame $F5.xzoom ]
   set xplus [button $fxzoom.plus -bitmap @$KAPPA_DIR/plus.bit -command {Zoom x 1}]
   SetHelp $xplus "Press to expand horizontal scale..." LUTEDIT_XPLUS
   set xminus [button $fxzoom.minus -bitmap @$KAPPA_DIR/minus.bit -command {Zoom x 0}]
   SetHelp $xminus "Press to compress horizontal scale..." LUTEDIT_XMINUS

   pack $xplus $xminus -side left
   pack $fxzoom -side left -padx 4m -pady 1m -anchor n -expand 1

   set F6 [frame $F3.current]

   grid [label $F6.l1 -text "Current pen index: "]  -column 0 -row 0 -sticky "nw"
   grid [entry $F6.v1 -width 6 -relief sunken -bd 2 -textvariable CPEN] -column 1 -row 0 -sticky "nw"
   bind $F6.v1 <Return> "updateCursor 1"
   SetHelp [list $F6.l1 $F6.v1] "The current pen index (type a new value to move the cursor)..." LUTEDIT_RB

   grid [label $F6.l0 -text "       "]  -column 2 -row 0 -sticky nw

   grid [label $F6.l2 -text "Current pen value: "]  -column 3 -row 0 -sticky "nw"
   grid [label $F6.v2 -width 6 -relief sunken -bd 2 -textvariable PVAL] -column 4 -row 0 -sticky "nw"
   SetHelp [list $F6.l2 $F6.v2] "The current pen value." LUTEDIT_RB

   grid columnconfigure $F6 5 -weight 10
   grid [button $F6.b1 -bitmap "@$KAPPA_DIR/cpoint.bit" -command cpoint] -column 5 -row 0 -sticky ne
   SetHelp $F6.b1 "Click to add a control point to the current curve at the table entry nearest to the cursor position." LUTEDIT_CPADD

   grid [button $F6.b2 -bitmap "@$KAPPA_DIR/dpoint.bit" -command "dpoint 0"] -column 6 -row 0 -sticky ne
   SetHelp $F6.b2 "Click to delete the control point nearest to the cursor in the current curve (shift-click to delete all control points)." LUTEDIT_CPDEL
   bind $F6.b2 <Shift-ButtonPress-1> "dpoint 1"

#  Pack the controls frames.
   pack $F4 -side top -anchor e -fill both -expand 1
   pack $F5 -side top -anchor e -fill x
   pack $F6 -side top -anchor nw -padx 3m -pady 2m -fill x

# Execute procedure SingleBind when button 1 is clicked over the canvas.
   bind $CAN2 <Button-1> "SingleBind %x %y 0"

# If a double click occurs, select all pens, setting a flag to prevent
# the single click binding from later selecting a single entry.
   bind $CAN2 <Double-Button-1> "set LENTRY 0
                                 set HENTRY \$NENTM1
                                 set DOUBLE 1
                                 select"

# Execute procedure ReleaseBind when button 1 is released over the canvas.
   bind $CAN2 <ButtonRelease-1> "ReleaseBind %x %y"

# Execute procedure B1MotionBind when the pointer is moved over the canvas 
# with button 1 pressed.
   bind $CAN2 <B1-Motion> "B1MotionBind %x %y"

# Execute procedure MotionBind when the pointer is moved over the canvas 
# with no buttons pressed.
#   bind $CAN2 <Motion> "MotionBind %x %y"

# Re-size the image display if the top-level window is resized.
   bind $UWIN <Configure> {Resize}

# Create binding which result in the Helper procedure being called
# whenever a widget is entered, left, or destroyed. Helper stores
# the appropriate message for display in the dynamic help area.
   bind all <Enter> "+Helper 0"
   bind all <Leave> "+Helper 0"
   bind all <Destroy> "+Helper 0"

   $CAN2 bind current <Enter> "+Helper 0"
   $CAN2 bind current <Leave> "+Helper 1"

   $CAN2 bind all <Enter> "+setCursor"

   $CAN bind current <Enter> "+Helper 0"
   $CAN bind current <Leave> "+Helper 1"

# Create a binding which calls MenuMotionBind whenever the pointer moves
# over any menu. This is used to determine the help information to display.
   bind Menu <Motion> {+MenuMotionBind %W %y}

#  Set up help for the main editor items.
   SetHelp $CAN2 "The colour editor... click to re-position the cursor, or use the arrow keys" LUTEDIT_EDITOR
   SetHelp pcurs "The cursor... Drag to select a range of pens" LUTEDIT_PCURS
   SetHelp mark "A marker indicating the extent and value of the table entry under the pointer.. Drag vertically to change the value of the entry." LUTEDIT_MARK
   SetHelp cp "A control point... click and drag to bend the current colour curve."
   SetHelp disp "$IMAGE displayed with the current colour table."
   SetHelp hist "A histogram of the pen numbers used within the neighbouring image display, with each bin coloured using its own pen colour."

#  Keyboard left and right arrow keys move the cursor by one pen.
   bind $UWIN <Left> {set CPEN [expr $CPEN-1.0];updateCursor 1}
   bind $UWIN <Right> {set CPEN [expr $CPEN+1.0];updateCursor 1}

#  Set cursors to use when pointer is over a canvas item with various tags.
   set CURTAGS [list mark pcurs cp bkgrnd]
   set CURSORS [list hand1 hand2 hand1 ""]

# Source any initialization script in the users main ADAM directory.
   set INITRC $oldadam/luteditrc
   if { [file exists $INITRC] } { source $INITRC }

# Pack the top level frame. This will cause a "Configure" event, which
# will cause the Resize procedure to be called which will set up the
# image display, etc.
   pack $TOP -padx 1m -pady 1m -ipadx 1m -ipady 1m -fill both -expand 1

# Create the help area.
   HelpArea
   centreWin $UWIN

#  Warn about private colour maps.
   if { $usingnewcmap } {
      Message "Less than $GWM_NCOL colours are available, so a private\ncolour map is being used. To avoid this, try\nstopping other applications before re-running LutEdit."
   }

#  Create a bitmap image for use as a control poitn canvas item.
   set CPIM [image create bitmap -file $KAPPA_DIR/cpoint.bit]

# Ensure that closing the window from the window manager is like pressing
# the Quit button in the File menu.
   wm protocol $UWIN WM_DELETE_WINDOW {Finish}

   destroy $wait
