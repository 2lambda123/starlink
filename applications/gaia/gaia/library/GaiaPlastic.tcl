#+
#  Name:
#     GaiaPlastic

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#     GAIA-specific implementation of PLASTIC messages.

#  Description:
#     An instance of this class does the actual work for responding to
#     PLASTIC messages.  It should be supplied to the constructor of
#     a plastic::PlasticApp, and it should contain a method for each
#     message that it implements.  The name of each method is the actual
#     PLASTIC message ID, and the argument list is the PLASTIC ID of
#     the sender application, followed by all the other arguments which
#     have been passed as message parameters.
#
#     See http://plastic.sourceforge.net/ for listing of the standard
#     PLASTIC messages, their argument lists, and their semantics.

#  Copyright:
#     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
#     All Rights Reserved.

#  Licence:
#     This program is free software; you can redistribute it and/or
#     modify it under the terms of the GNU General Public License as
#     published by the Free Software Foundation; either version 2 of the
#     License, or (at your option) any later version.
#
#     This program is distributed in the hope that it will be
#     useful, but WITHOUT ANY WARRANTY; without even the implied warranty
#     of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
#     02111-1307, USA

#  Authors:
#     MBT: Mark Taylor
#     {enter_new_authors_here}

#  History:
#     13-JUL-2006 (MBT):
#        Original version.
#     {enter_further_changes_here}

#-

package require rpcvar
namespace import -force rpcvar::*

itcl::class gaia::GaiaPlastic {

   #  PLASTIC message implementations.
   #  --------------------------------

   #  Echo text.
   public method ivo://votech.org/test/echo {sender_id text args} {
      return [rpcvar string $text]
   }

   #  Return application name.
   public method ivo://votech.org/info/getName {sender_id args} {
      return "gaia"
   }

   #  Return application description.
   public method ivo://votech.org/info/getDescription {sender_id args} {
      return "Graphical Astronomy and Image Analysis Tool"
   }

   #  Return version of PLASTIC supported.
   public method ivo://votech.org/info/getVersion {sender_id args} {
      return [rpcvar string 0.4]
   }

   #  Return URL of an icon representing this application.
   public method ivo://votech.org/info/getIconURL {sender_id args} {
      return "http://star-www.dur.ac.uk/~pdraper/gaia/gaialogo.gif"
   }

   #  Load a FITS file specified as a URL into the display.
   public method ivo://votech.org/fits/image/loadFromURL {sender_id img_url
                                                          args} {
      set basegaia [get_gaia_]
      if { $basegaia != {} } {
         set fname [get_file_ $img_url]
         if { $fname != {} } {
            $basegaia open $fname
            return $TRUE
         } else {
            #  Remote file, arrange to download this in the background.
            set urlget_ \
               [GaiaUrlGet .\#auto -notify_cmd [code $this display_file_]]
            $urlget_ get $img_url
            return $TRUE
         }
      }
      return $FALSE
   }

   #  Point at a coordinate by drawing an identifier graphic, ra and dec
   #  are both in decimal degrees.
   public method ivo://votech.org/sky/pointAtCoords {sender_id ra dec args} {
      set basegaia [get_gaia_]
      if { $basegaia != {} } {
         if { ![catch {$basegaia position_of_interest $ra $dec "deg J2000"}]} {
            return $TRUE
         }
      }
      return $FALSE
   }

   #  Execute a GAIA command.
   #
   #  Nice idea, but at the current PLASTIC version (v0.5), which 
   #  basically lacks any security measures, it would be dangerous 
   #  to allow any registered application to execute arbitrary Tcl code.
#  public method ivo://plastic.starlink.ac.uk/gaia/execute {sender_id args} {
#     eval $args
#  }

   #  Load a VOTable as a catalogue.
   public method ivo://votech.org/votable/loadFromURL {sender_id url args} {

      #  Second argument, if present, is a tag for the table.  If not 
      #  present, use the URL.
      if {$args == ""} {
         set table_id $url
      } else {
         set table_id [lindex $args 0]
      }

      #  Convert the VOTable to TST format and display it.
      set failure [catch {
         set tst_file [get_temp_file_ .TAB]
         [get_stilts_] execute tpipe \
                       ifmt=votable ofmt=tst in=$url out=$tst_file \
                       "cmd=setparam symbol '[next_symbol_spec_]'"
         set window [display_table_ $tst_file $table_id]
         set cat_windows_($table_id) $window
      } msg]

      #  Return as appropriate.
      if { ! $failure } {
         return $TRUE
      } else {
         error_dialog "Failed to load catalogue from PLASTIC:\n$msg"
         return $FALSE
      }
   }

   #  Display only a selection of the rows from a previously loaded catalogue.
   public method ivo://votech.org/votable/showObjects {sender_id table_id
                                                       idx_list args} {
      if {[info exists cat_windows_($table_id)]} {
         $cat_windows_($table_id) select_indices $idx_list
         return $TRUE
      } else {
         return $FALSE
      }
   }

   #  Highlight a single row from a previously loaded catalaogue.
   public method ivo://votech.org/votable/highlightObject {sender_id table_id
                                                           idx args} {
      if {[info exists cat_windows_($table_id)]} {
         $cat_windows_($table_id) highlight_index $idx
         return $TRUE
      } else {
         return $FALSE
      }
   }

   #  Protected methods:
   #  ------------------

   #  Download and display a file.
   protected method display_file_ {filename type} {
      set basegaia [get_gaia_]
      if { $basegaia != {} } {
         $basegaia open $filename
      }
      delete object $urlget_
      set urlget_ {}
   }

   #  Displays a catalogue in TST format.
   #  Returns the GaiaSearch widget which displays the catalogue.
   protected method display_table_ {filename table_id} {
      set images [skycat::SkyCat::get_skycat_images]
      set ctrlwidget [lindex $images 0]
      set gaia [winfo parent $ctrlwidget]
      set window [::cat::AstroCat::open_catalog_window \
                    $filename $ctrlwidget ::gaia::PlasticSearch 0 $gaia]
      $window configure -table_id $table_id
      return $window
   }

   #  Return a Stilts instance belonging to this object.
   protected method get_stilts_ {} {
      if {$stilts_ == ""} {
         set stilts_ [gaia::Stilts #auto -debug 0]
      }
      return $stilts_
   }


   #  Utility procs:
   #  --------------

   #  Locate an instance of Gaia for displaying images.
   private proc get_gaia_ {} {
      foreach image [::skycat::SkyCat::get_skycat_images] {
         return [winfo parent $image]
      }
      return ""
   }

   #  Tries to turn a URL into a file name.  If the URL uses the file:
   #  protocol (in either its correct RFC1738 "file://host/..." or its
   #  incorrect but common "file:..." form) then the corresponding
   #  local filename is returned.  Otherwise an empty string is returned.
   private proc get_file_ {url} {
      if {[regsub ^file://(localhost|[info host]|)/ $url "" fname]} {
         return /$fname
      } elseif {[regsub ^file: $url "" fname]} {
         return $fname
      } else {
         return ""
      }
   }

   #  Get the name of a file it's OK to use for scratch space.
   #  The exten argument gives a file extension (e.g. ".fits").
   protected proc get_temp_file_ {exten} {
      set tmpdir ""
      foreach trydir {/tmp /usr/tmp .} {
         if {[file isdirectory $trydir] && [file writable $trydir]} {
            set tmpdir $trydir
            break
         }
      }
      if { $tmpdir == "" } {
         error "No temporary directory"
      }

      set basefile "${tmpdir}/gaia_temp_"
      for { set ix 1 } { $ix < 100 } { incr ix } {
         set tryfile "$tmpdir/gaia_temp_$ix$exten"
         if {! [file exists $tryfile] } {
            return $tryfile
         }
      }
      error "No free files with name like $tryfile"
   }

   #  Provides a suitable value for the "symbol_id" column in a TST table.
   #  This is what determines how plotted symbols will appear on the
   #  image (unless changed).  This function endeavours to return a 
   #  different symbol each time it is called (though may repeat eventually).
   protected proc next_symbol_spec_ {} {
      set shapes {circle square plus cross diamond}
      set colors {cyan yellow blue red grey50 green magenta}
      set shape [lindex $shapes [expr $symbol_idx_ % [llength $shapes]]]
      set color [lindex $colors [expr $symbol_idx_ % [llength $colors]]]
      set size 6
      incr symbol_idx_
      return [list {} \
                   [list $shape $color {} {} {} {}] \
                   [list $size {}]]
   }


   #  Instance variables:
   #  -------------------

   #  Name of the active instance of GaiaUrlGet.
   protected variable urlget_ {}

   #  Stilts object for executing STILTS commands.
   protected variable stilts_ {}


   #  Class variables:
   #  ----------------

   #  Array of GaiaSearch windows which have been opened to display 
   #  PLASTIC-acquired tables.  The array is indexed by table_id.
   protected common cat_windows_

   #  Constants for returning from boolean-declared XML-RPC methods.
   protected common FALSE [rpcvar boolean 0]
   protected common TRUE [rpcvar boolean 1]

   #  Index of the last new symbol type used.
   protected common symbol_idx_ 0
}
