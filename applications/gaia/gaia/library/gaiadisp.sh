#!/bin/sh    
# The next line is executed by /bin/sh, but not Tcl \
exec $GAIA_DIR/gaia_stcl $0 ${1+"$@"}
#+
#   Name:
#      gaiadisp
#
#   Purpose:
#      Displays an image in a GAIA tool.
#
#   Usage:
#      gaiadisp image [clone_number]
#
#   Description:
#      This command displays a given image in GAIA. The image can 
#      be directed into a specified "clone". If the clone or GAIA 
#      do not exist then they are created. 
#
#      Clones are specified by an integer number less than 1000.
#      The special number -1 indicates that a number should be generated.
#
#   Notes:
#
#   Authors:
#      Peter W. Draper (PDRAPER):
#
#   History:
#      25-NOV-1996 (PDRAPER):
#         Original version.
#      09-MAR-1998 (PDRAPER):
#         Now uses the remote control interface, rather than send
#         mechanism (less X security complaints).
#      18-MAY-1999 (PDRAPER):
#         Converted to use GAIA single binary gaia_stcl.
#-
#.

#  Check the command-line arguments.
set clone ""
if { $argc >= 1 } { 
   set image [lindex $argv 0]
   if { $argc >= 2 } {
      set clone [lindex $argv 1]
   }
} else {
   puts stderr {Usage: gaiadisp filename [clone_number]}
   exit
}

#  Add GAIA_DIR to autopath for some GAIA classes.
lappend auto_path $env(GAIA_DIR)

#  Now parse name.
set namer [::gaia::GaiaImageName .namer -imagename $image]
if { ! [$namer exists] } { 
   puts stderr "Cannot read image: $image"
   exit 1
}

#  Make it absolute (also stripping off tmp_mnt, if present).
$namer absolute

#  If it has a FITS extension then we need to protect the [].
$namer protect

#  Open a socket to a GAIA application and return the file descriptor
#  for remote commands. If a GAIA isn't found then start one up.
proc connect_to_gaia {} {
   global env

   #  Get the hostname and port info from the file ~/.rtd-remote,
   #  which is created by rtdimage when the remote subcommand is
   #  used.
   set tries 0
   while { 1 } {
      set needed 0

      #  Open the file containing the GAIA process information and read it.
      if {[catch {set fd [open $env(HOME)/.rtd-remote]} msg]} {
         set needed 1
      } else {
         lassign [read $fd] pid host port
         close $fd
      }

      #  See if the process is listening to this socket.
      if { ! $needed } {
         if {[catch {socket $host $port} msg]} {
            set needed 1
         } else {
            fconfigure $msg -buffering line
            return $msg
         }
      }

      #  If the process doesn't exist and we've not been around the
      #  loop already, then start a new GAIA.
      if { $needed && $tries == 0 } {
         puts stderr "Failed to connect to GAIA, starting new instance..."
         exec $env(GAIA_DIR)/gaia.sh &
         #exec $env(GAIA_DIR)/tgaia &
      }

      #  Now either wait and try again or give up if waited too long.
      if { $needed && $tries < 500 } {
         #  Wait for a while and then try again.
         incr tries
         after 1000
      } elseif { $needed } {
         puts stderr "Sorry timed out: failed to display image in GAIA"
         exit 1
      }
   }
}

#  Send the command to GAIA and return the results or generate an error.
proc send_to_gaia {args} {
   global gaia_fd
   puts $gaia_fd "$args"
   lassign [gets $gaia_fd] status length
   set result {}
   if {$length > 0} {
      set result [read $gaia_fd $length]
   }
   if {$status != 0} {
      error "$result"
   }
   return "$result"
}

#  Open up connection to GAIA.
set gaia_fd [connect_to_gaia]

#  Command needs to performed by Skycat or derived object. We just
#  talk to the first window on the list.
set cmd "skycat::SkyCat::get_skycat_images"
set images [send_to_gaia remotetcl $cmd]

#  Got list so select first and ask about the parent (should be 
#  top-level GAIA).
set ctrlwidget [lindex $images 0]
set cmd "winfo parent $ctrlwidget"
set gaia [send_to_gaia remotetcl $cmd]

#  Construct the command needed to display the image.
if { $clone != "" } { 
   set cmd "$gaia noblock_clone $clone [$namer fullname]"
} else {
   set cmd "$gaia open [$namer fullname]"
}
 
#  And send the command.
set ret [send_to_gaia remotetcl $cmd]
if { $ret == "" || $ret == ".gaia$clone" } { 
   puts stderr "Displayed image: $image."
} else {
   puts stderr "Failed to display image: ($ret)"
}
close $gaia_fd
exit
