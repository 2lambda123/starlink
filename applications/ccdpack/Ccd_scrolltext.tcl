   itcl_class Ccd_scrolltext {

#+
#  Name:
#     Ccd_scrolltext

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#    Defines a class of "text widget with scrollbars".

#  Description:
#    This class description defines methods and configurations for
#    creating a text widget with scrollbars. The scrolltext widget may
#    have scrollbars positioned either at the left or right, top or bottom. 
#    The scrollbars are arranged to give a Motif-like look (with spaces in 
#    the corners) and may be reconfigured at any time.

#  Invocations:
#
#        Ccd_scrolltext window [-option value]...
#
#     This command create an instance of a scrolltext and returns a
#     command "window" for manipulating it via the methods and
#     configuration options described below. Configuration options may
#     be appended to the command.
#
#        window configure -configuration_options value
#
#     Applies any of the configuration options (after the widget
#     instance has been created).
#
#        window method arguments
#
#     Performs the given method on this widget.

#  Configuration options:
#
#        -scrollbarplaces "(right|left)" "(top|bottom)"
#
#     This option configures the placing of the scrollbars. These may
#     be either "left" or "right" or "top" or bottom. The default is 
#     "right bottom"
#
#        -exportselect boolean
#
#     This option configues the text widget so that the selection is the X11
#     selection or not. If a selection is to be made in more than one
#     place then this will require setting to false.
#
#        -height  value
#
#     The height of the text widget. If no qualifiers are given to the value
#     then this will be in characters (see Tk_GetPixels).
#
#        -width value
#
#     The width of the text widget. If no qualifiers are given to the value
#     then this will be in characters (see Tk_GetPixels).
#
#         -label "text"
#
#     Adds a label over at top of the text widget. This is anchored west.

#  Methods:
#     constructor [-option value]...
#        This method is invoked automatically by the class command and
#	 creates the scrolltext widget with a default configuration,
#	 except when overridden by command line options.
#     destructor
#        Destroys the scrolltext, invoked by the "delete" method.
#     configure [-option value]...
#        Activates the configuration options. If no configuration value
#	 is given then the current value of any known option is returned
#	 in a form similar (but not identical to) the Tk widget command.
#     insert index text
#        Inserts a line of text with the given index. "index" can
#	 be 0 or end which inserts at the beginning and at the end.
#     clear first [last]
#        Clears a range of items from the text widget. If first is "all"
#	 then all lines are deleted. If only first is given then this
#	 clears a single line. "last" may be set as end.
#     get index1 [index2]
#        Gets the item with the given indices from the text widget.
#     _repack place
#        Repacks the scrolltext (used by configuration option
#	 scrollbarplace). This is really an internal method and
#	 shouldn't be used.
#     textname
#        Returns the name of the text widget.
#     scrollbarnames
#        Returns the name of the scrollbars.

#  Inheritance:
#     This class inherits Ccd_base and its methods and configuration
#     options, which are not directly occluded by those specified here.

#  Authors:
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     MBT: Mark Taylor (STARLINK)
#     {enter_new_authors_here}

#  History:
#     14-MAR-1995 (PDRAPER):
#     	 Original version.
#     4-MAY-1995 (PDRAPER):
#        Started move to Tk4. Commented out ::rename in destructor, no
#        longer needed.
#     11-AUG-1995 (PDRAPER):
#        Added option for horizontal scrollbar (Tk 4 enhancement).
#     15-MAY-2000 (MBT):
#        Upgraded for Tcl8.
#     {enter_further_changes_here}

#-

#  Inheritances:
      inherit Ccd_base

#.

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Construction creates a instance of the Ccd_scrolltext class and
#  configures it with the default and command-line options.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      constructor { config } {

#  Create a frame widget. This must have the same name as the class
#  command.
         Ccd_base::constructor

#  Create text widget.
         CCDTkWidget Text text text $oldthis.text

#  Define sub-component widgets for configuration via the wconfig
#  and focus method.
         set widgetnames($Oldthis:text) $Text
         set widgetfocus($Oldthis:text) $Text

#  Check options database for values to override widget defaults. Look for more
#  specific option of having a class specified, if this fails try for less
#  specific class.
         set wid [ _getoption "width Width"]
         if { $wid != {} } { set width $wid }
         set hei [ _getoption "height Height"]
         if { $hei != {} } { set relief $hei }
         set scr [ _getoption \
            "scrollbarplaces scrollbarPlaces ScrollbarPlaces ScrollBarPlaces"]
         if { $scr != {} } { set scrollbarplace $scr }

#  Set default configurations. Scrollbar placements also packs the widgets.
         configure -height          $height
         configure -width           $width
         configure -label           $label
         configure -scrollbarplaces $scrollbarplaces
      }

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Methods.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Insert line of text method.
      method insert { index args } {
         eval $Text insert $index $args
	 
#  Make sure that the text is visible.
         set textlen [expr int([$Text index end])]
         $Text see $index
#         update idletasks
      }
      
#  Clear range of lines of text method.
      method clear { args } {
         if { [lindex $args 0 ] != "all" } {
            eval $Text delete $args
         } else {
            $Text delete 0 end
         }
      }

#  Get information back from the text widget.
      method get { index } {
         set contents ""
         if { $index != "all" } {
            set contents [$Text get $index]
         } else {
            set size [$Text size]
            for { set i 0 } { $i < $size } { incr i } {
               lappend contents [$Text get $i]
            }
         }
         return $contents
      }

#  Internal method for creating and or re-packing scrollbars
      method _repack places  {

#  First remove all scrollbars and packing frames, make the text widget
#  forget any scrolling commands.
         foreach side "left right" {
            if { [ info exists Scrolls($side) ] } {
               set scroll [CCDPathOf $Scrolls($side)]
               pack forget $scroll
               destroy $scroll
               unset Scrolls($side)
               $Text configure -yscrollcommand {}
            }
         }
         foreach side "top bottom" {
            if { [ info exists Scrolls($side) ] } {
               set scroll [CCDPathOf $Scrolls($side)]
               pack forget $scroll
               destroy $scroll
               destroy [CCDPathOf $Frames($side)]
               unset Scrolls($side)
               unset Frames($side)
               $Text configure -xscrollcommand {}
            }

#  Destroy any packing frames.
            if { [ info exists Frames($side.left) ] } {
               set frame [CCDPathOf $Frames($side.left)]
               pack forget $frame
               destroy $frame
               unset Frames($side.left)
            }
            if { [ info exists Frames($side.right) ] } {
               set frame [CCDPathOf $Frames($side.right)]
               pack forget $frame
               destroy $frame
               unset Frames($side.left)
            }
         }

#  And unpack the text widget itself (so that rearrangement is easy).
         pack forget $text

#  Find out if any packing frames are required (this fill the corners of
#  the base frame so that scrollbars look natural).
         set haveleft   [string match *left*   $places]
         set haveright  [string match *right*  $places]
         set havetop    [string match *top*    $places]
         set havebottom [string match *bottom* $places]

#  Create the necessary scrollbars. Append any names etc. to the
#  sub-widget control variables.
         if { $haveleft } {
            CCDTkWidget Scroll scroll \
               scrollbar $oldthis.scrollleft \
                  -orient vertical \
                  -command "$Text yview"
            $Text configure -yscrollcommand "$Scroll set"
            set widgetnames($Oldthis:scrollleft) $Scroll
            set Scrolls(left) $Scroll
         }

         if { $haveright } {
            CCDTkWidget Scroll scroll \
               scrollbar $oldthis.scrollright \
                  -orient vertical \
                  -command "$Text yview"
            $Text configure -yscrollcommand "$Scroll set"
            set widgetnames($Oldthis:scrollright) $Scroll
            set Scrolls(right) $Scroll
         }

         if { $havetop } { 
            CCDTkWidget Frame frame frame $oldthis.top -borderwidth 0
            if { $haveleft } {
               CCDTkWidget Frame1 frame1 \
                  frame $frame.left \
                         -width [winfo reqwidth [CCDPathOf $Scrolls(left)]]
               pack $frame1 -side left
               set Frames(top.left) $Frame1
            }
            CCDTkWidget Scroll scroll \
               scrollbar $frame.scrolltop \
                  -orient horizontal \
                  -command "$Text xview"
            pack $scroll -side left -fill x -expand true
            $Text configure -xscrollcommand "$Scroll set"
            set widgetnames($Oldthis:scrolltop) $Scroll
            set Scrolls(top) $Scroll
            if { $haveright } {
               CCDTkWidget Frame1 frame1 \
                  frame $oldthis.top.right \
                         -width [winfo reqwidth [CCDPathOf $Scrolls(right)]]
               pack $frame1 -side left
               set Frames(top.right) $Frame1
            }
         }

         if { $havebottom } { 
            CCDTkWidget Frame frame frame $oldthis.bottom -borderwidth 0
            if { $haveleft } {
               CCDTkWidget Frame1 frame1 \
                  frame $frame.left \
                         -width [winfo reqwidth [CCDPathOf $Scrolls(left)]]
               pack $frame1 -side left
               set Frames(bottom.left) $Frame1
            }
            CCDTkWidget Scroll scroll \
               scrollbar $frame.scrollbottom \
                  -orient horizontal \
                  -command "$Text xview"
            pack $scroll -side left -fill x -expand true
            $Text configure -xscrollcommand "$Scroll set"
            set widgetnames($Oldthis:scrollbottom) $Scroll
            if { $haveright } {
               CCDTkWidget Frame1 frame1 \
                  frame $frame.right \
                         -width [winfo reqwidth [CCDPathOf $Scrolls(right)]]
               pack $frame1 -side left
               set Frames(bottom.right) $Frame1
            }
         }

#  Perform packing of main elements (need to do this now to get into
#  correct places.
         if { $havetop && $haveleft } { 
            pack [CCDPathOf $Frames(top.left)]     -side top    -fill x 
         }
         if { $havetop && $haveright } {
            pack [CCDPathOf $Frames(top.right)]    -side top    -fill x
         }
         if { $havebottom && $haveleft } { 
            pack [CCDPathOf $Frames(bottom.left)]  -side bottom -fill x
         }
         if { $havebottom && $haveright } {
            pack [CCDPathOf $Frames(bottom.right)] -side bottom -fill x 
         }
         if { $haveleft }   { 
            pack [CCDPathOf $Scrolls(left)]       -side left   -fill y 
         }
         if { $haveright }  { 
            pack [CCDPathOf $Scrolls(right)]      -side right  -fill y 
         }
         pack $oldthis.text -expand true -fill both
      }

#  Method to return the name of the text widget.
      method textname {} {
         return $Text
      }
   
#  Method to return the names of the scrollbar widgets
      method scrollbarnames { places } {
         foreach side $places {
            if { ! [ regexp (left|right|top|bottom) $side ] } { 
               error "Unknown scrollbar placement \"$side\", should be top bottom left or right"
            }
         }
         foreach side $places {
            if { [ info exists Scrolls($side) ] } {
               lappend barnames $Scrolls($side)
            }
         }
         if { [ info exists barnames ] } { 
            return "$barnames"
         } else {
            return {}
         }
      }

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Configuration options:
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Insert and pack the required scrollbars. Remove existing scrollbars first.
      public scrollbarplaces { right bottom } {
         foreach side $scrollbarplaces {
            if { ! [ regexp (left|right|top|bottom) $side ] } { 
               error "Unknown scrollbar placement \"$side\", should be top bottom left or right"
            }
         }

#  Only proceed if the object exists (this means that constructor has
#  been invoked).
         if $exists { 
            _repack $scrollbarplaces
         }
      }

#  If a label has been requested then add one.
      public label {} {
         if { $label != {} } {
            if $exists {
               CCDTkWidget Labelwidget labelwidget \
                  label $oldthis.label -text "$label"
               pack $labelwidget -side top -anchor w
               _repack $scrollbarplaces
            }
         } else {

#  Remove existing label.
            if { [ winfo exists $labelwidget ] } {
               pack forget $labelwidget
	       destroy $labelwidget
	    }
         }
      }

#  Is the selection exportable? If not may have more than one selection
#  (one for each instance), otherwise the selection is the X11 one.
      public exportselect 1 {
         if { [ winfo exists $text ] } {
            $Text configure -exportselection $exportselect
         }
      }

#  Height of text widget.
      public height 20 {
         if $exists {
            $Text configure -width $width -height $height
         }
      }

#  Width of text widget.
      public width 80 {
         if $exists {
            $Text configure -width $width -height $height
         }
      }

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Protected variables: visible to only this instance.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  Names of widgets
      protected Text
      protected text ""
      protected Labelwidget
      protected labelwidget ""
      protected Frames
      protected Scrolls

      protected lastupdate 0

#  End of class defintion.
   }


# $Id$
