#+
#  Name:
#     GaiaContour

#  Type of Module:
#     [incr Tk] class

#  Purpose:
#     Defines a class for image contouring

#  Description:
#     This class privides a toolbox for drawing contours over an
#     image. The contours can be of the image itself, or of another
#     image (which can be stored on disk, or displayed in another
#     clone).
#
#     The toolbox provides interactive control of the levels, the
#     colour that each level is drawn in and its line width. Drawing
#     of contours can be done all at once, or one-by-one (this is
#     achieved by pressing <Return> in the entry widget showing the
#     value.
#
#     A key of contour levels (showing those drawn and which have some
#     values plotted) is added to the display. The part of the image
#     that is  contoured can be mapped onto the region of the
#     displayed image. Contour levels can be generated using a range
#     of techniques (such as magnitude intervals).

#  Invocations:
#
#        GaiaContour object_name [configuration options]
#
#     This creates an instance of a GaiaContour object. The
#     return is the name of the object.
#
#        object_name configure -configuration_options value
#
#     Applies any of the configuration options (after the instance has
#     been created).
#
#        object_name method arguments
#
#     Performs the given method on this widget.

#  Configuration options:
#     See the "itk_option define" declarations below.

#  Methods:
#     See the method declarations below.

#  Inheritance:
#     TopLevelWidget

#  Copyright:
#     Copyright (C) 1999 Central Laboratory of the Research Councils

#  Authors:
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     15-APR-1999 (PDRAPER):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itk::usual GaiaContour {}

itcl::class gaia::GaiaContour {

   #  Inheritances:
   #  -------------
   inherit util::TopLevelWidget

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Evaluate any options.
      eval itk_initialize $args

      #  Set the top-level window title.
      wm title $w_ "GAIA: Contouring ($itk_option(-number))"

      #  Add short help window.
      make_short_help

      #  Add the File menu.
      add_menubar
      set File [add_menubutton "File" left]
      configure_menubutton File -underline 0

      #  Add the options menu
      set Options [add_menubutton "Options" left]
      configure_menubutton Options -underline 0

      #  Add window help.
      global gaia_dir
      add_help_button $gaia_dir/GaiaContour.hlp "On Window..."
      add_short_help $itk_component(menubar).help \
         {Help menu: get some help about this window}

      #  Add option to create a new window.
      $File add command -label {New window} \
         -command [code $this clone_me_] \
         -accelerator {Control-n}
      bind $w_ <Control-n> [code $this clone_me_]
      $short_help_win_ add_menu_short_help $File \
         {New window} {Create a new toolbox}

      #  Save configuration to a file.
      $File add command \
         -label {Save configuration...} \
         -command [code $this write_config_file] \
         -accelerator {Control-s}
      bind $w_ <Control-s> [code $this write_config_file]
      $short_help_win_ add_menu_short_help $File \
         {Save configuration...}\
         {Write the current configuration to a text file}

      #  Read configuration from a file.
      $File add command \
         -label {Read configuration...} \
         -command [code $this read_config_file] \
         -accelerator {Control-r}
      bind $w_ <Control-r> [code $this read_config_file]
      $short_help_win_ add_menu_short_help $File \
         {Read configuration...}\
         {Read previous configuration back from a text file}

      #  Set the exit menu item.
      $File add command -label Exit \
         -command [code $this close] \
         -accelerator {Control-c}
      bind $w_ <Control-c> [code $this close]

      #  Add an option to plot carefully, or not.
      $Options add checkbutton \
         -label {Draw contours using geodesics} \
         -variable [scope careful_] \
         -onvalue 1 \
         -offvalue 0
      $short_help_win_ add_menu_short_help $Options \
         {Draw contours using geodesics} \
         {Use for complex astrometries (slow but precise)}

      #  Add an option to plot smooth polyline.
      $Options add checkbutton \
         -label {Draw smooth contours} \
         -variable [scope smooth_] \
         -onvalue 1 \
         -offvalue 0
      $short_help_win_ add_menu_short_help $Options \
         {Draw smooth contours} \
         {Use splines to join adjacent contour points}

      #  Add an option to use same colour for all lines.
      $Options add checkbutton \
         -label {Use single colour} \
         -variable [scope single_colour_] \
         -onvalue 1 \
         -offvalue 0
      $short_help_win_ add_menu_short_help $Options \
         {Use single colour} \
         {Draw all contours with the same colour}

      #  Add an option to use same width for all lines.
      $Options add checkbutton \
         -label {Use single width} \
         -variable [scope single_width_] \
         -onvalue 1 \
         -offvalue 0
      $short_help_win_ add_menu_short_help $Options \
         {Use single width} \
         {Draw all contours with the same width}

      #  Allow selection of the contoured image.
      add_image_controls_

      #  Add tab table to contain the various controls (too many for a
      #  single pane).
      itk_component add tab {
         ::iwidgets::tabnotebook $w_.tab \
            -angle 30 -tabpos w -width 370 -height 400
      }

      #  Get pane for levels and attributes.
      $itk_component(tab) add -label Levels
      set child_(levels) [$itk_component(tab) childsite 0]

      #  Add controls for line attributes.
      add_att_controls_ $child_(levels)

      #  Get pane for levels generation controls.
      $itk_component(tab) add -label Generate
      set child_(gener) [$itk_component(tab) childsite 1]

      #  Add controls for level generation.
      add_gen_controls_ $child_(gener)

      #  Get pane for region to contour.
      $itk_component(tab) add -label Region
      set child_(region) [$itk_component(tab) childsite 2]

      #  Add controls for choosing whether to contour the whole image,
      #  or just the displayed part
      add_whole_controls_ $child_(region)

      #  Get pane for contour key configuration.
      $itk_component(tab) add -label Key
      set child_(key) [$itk_component(tab) childsite 3]

      #  Add controls for choosing whether to contour the whole image,
      #  or just the displayed part
      add_key_controls_ $child_(key)

      #  Create the button bar
      itk_component add actionframe {frame $w_.action}

      #  Add a button to close window.
      itk_component add close {
         button $itk_component(actionframe).close -text Close \
            -command [code $this close]
      }
      add_short_help $itk_component(close) {Close window}

      #  Add a button to clear all contour levels.
      itk_component add clear {
         button $itk_component(actionframe).clear -text {Clear contours} \
            -command [code $this clear_contours]
      }
      add_short_help $itk_component(clear) {Clear all contour levels}

      #  Draw the contours.
      itk_component add draw {
         button $itk_component(actionframe).draw -text {Draw Contours} \
            -command [code $this draw 1]
      }
      add_short_help $itk_component(draw) {Draw all contours}

      #  Pack all the components into place.
      pack $itk_component(actionframe) -side bottom -fill x -pady 5 -padx 5
      pack $itk_component(tab) -side top -fill both -expand 1
      pack $itk_component(close) -side right -expand 1 -pady 3 -padx 3
      pack $itk_component(clear) -side right -expand 1 -pady 3 -padx 3
      pack $itk_component(draw) -side left -expand 1 -pady 3 -padx 3

      #  Set the canvas level tags and record no contours are drawn.
      for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
         set leveltags_($i) cont[incr unique_]
         set drawn_($i) 0
      }

      #  Initialise the key tag.
      set keytag_ "ckey[incr unique_]"
      set texttag_ "ckey[incr unique_]"

      #  Display a window pane.
      $itk_component(tab) select 0
   }

   #  Destructor:
   #  -----------
   destructor  {

      #  Release the rtdimage used to access image files.
      if { $image_rtd_ != {} } {
	 catch {image delete $image_rtd_}
      }
   }

   #  Methods:
   #  --------

   #  Create a new instance of this object.
   protected method clone_me_ {} {
      if { $itk_option(-clone_cmd) != {} } {
         eval $itk_option(-clone_cmd)
      }
   }

   #  Close this window, kill it if needed, otherwise withdraw. Also
   #  remove the contours.
   public method close {} {

      #  Remove the contours.
      catch {remove_contours}

      if { $itk_option(-really_die) } {
         delete object $this
      } else {
         wm withdraw $w_
      }
   }

   #  Public redraw method. Only used externally to this class, which
   #  means we can decline to draw the contours unless they have already
   #  been drawn using the button.
   public method redraw { {override 0} } {
      if { $contoured_ || $override } {
         draw 1
      }
   }

   #  Save the current configuration to a file.
   public method write_config_file {} {
      set w [FileSelect .\#auto -title "Save configuration to a file"]
      if {[$w activate]} {
         save_config [$w get]
      }
      destroy $w
   }

   #  Restore configuration from a file.
   public method read_config_file {} {
      set w [FileSelect .\#auto -title "Read configuration from a file"]
      if {[$w activate]} {
         read_config [$w get]
      }
      destroy $w
   }

   #  Write the current configuration to a named file. This is written
   #  in a the format:
   #
   #     level  colour width
   #     level  colour width
   #     ...
   #
   #     parameter = value
   #
   #  We avoid a sourceable format as the widgets themselves tend to
   #  have the current values (rather than a list of variables), which
   #  would expose the internal formatting (and may cause
   #  incompatibilities with future rewrites).
   public method save_config {filename} {
      if { $filename != {} } {
         busy {
            #  Open the output file.
            set fid [::open $filename w]
            puts $fid "\# GAIA Contours configuration file."
            puts $fid "\#"

            #  Get the level attributes.
            set levatts [get_levels_and_atts_]

            puts $fid [format "\# %-26s %-10s %-10s" level colour width]
            foreach line $levatts {
               lassign $line level colour width
               puts $fid [format "  %-26s %-10s %-10s" $level $colour $width]
            }

            #  Add the contour image name (use the disk file, not the
            #  rtdimage).
            set image [get_diskimage_]
            if { $image != {} } {
               puts $fid "\#  Image name"
               puts $fid "image = $image"
            }

            #  Add the contouring speed.
            puts $fid "\#  Contouring speed"
            puts $fid "careful = $careful_"
            puts $fid "smooth = $smooth_"

            #  Add the parameters describing the image region.
            puts $fid "\#  Image region"
            puts $fid "whole = $whole_"
            puts $fid "xfrac = [$itk_component(xfrac) get]"
            puts $fid "yfrac = [$itk_component(yfrac) get]"

            #  Add the parameters describing the level key.
            puts $fid "\#  Key parameters"
            puts $fid "drawkey = $itk_option(-drawkey)"
            puts $fid "keytitle = \{[$itk_component(keytitle) get]\}"
            puts $fid "xkeypos = [$itk_component(xkeypos) get]"
            puts $fid "ykeypos = [$itk_component(ykeypos) get]"
            puts $fid "keyfont = [$itk_component(keyfont) get]"
            set colour [gaia::ColourMenu::lookup_index [$itk_component(keycolour) get]]
            puts $fid "keycolour = $colour"
            puts $fid "keylength = [$itk_component(keylength) get]"
            puts $fid "keywidth = [$itk_component(keywidth) get]"
            ::close $fid
         }
      }
   }

   #  Read in configuration from a file.
   public method read_config {filename} {
      if { [file readable $filename] } {
         busy {
            #  Open the file.
            set fid [open $filename r]

            #  Clear existing contours.
            catch {clear_contours}

            #  Loop over the file skipping comments and blank
            #  lines.
            set ok 1
            set count 0
            while { $ok  } {
               set llen [gets $fid line]
               if { $llen > 0 } {
                  switch -glob $line {
                     *=* {
                        eval set_parameter_ $line
                     }
                     \#* {
                        #  Comment do nothing.
                     }
                     default {
                        if { [llength $line] == 3 } {
                           eval add_contour_ $count $line
                           incr count
                        } else {
                           warning_dialog \
                              "unrecognised line in configuration file: $line"
                        }
                     }
                  }
               } elseif { $llen < 0 } {

                  # End of file.
                  set ok 0
               }
            }
            ::close $fid

            #  Toggle disabled widgets to correct state.
            set_whole_
            toggle_drawkey_
         }
      }
   }

   #  Add a new contour at a given position.
   protected method add_contour_ {ncont value colour width} {
      $itk_component(value$ncont) configure -value $value
      $itk_component(width$ncont) configure -value $width
      #$itk_component(colour$ncont) configure -value $indexcol_($colour)
      $itk_component(colour$ncont) \
         configure -value [gaia::ColourMenu::lookup_index $colour]
   }

   #  Assign a parameter value read back from a configuration file.
   #  The equals parameter is ignored.
   protected method set_parameter_ {param equals value} {
      switch -exact $param {
         image {
            $itk_component(conimg) configure -value $value
         }
         careful {
            set careful_ $value
         }
         smooth {
            set smooth_ $value
         }
         whole {
            set whole_ $value
         }
         drawkey {
            configure -drawkey $value
         }
         xfrac -
         yfrac {
            $itk_component($param) configure -value $value
         }
         keycolour {
            set orig $itk_option(-drawkey)
            set itk_option(-drawkey) 0
            #$itk_component($param) configure -value $indexcol_($value)
            $itk_component($param) configure \
               -value [gaia::ColourMenu::lookup_colour $value]
            set itk_option(-drawkey) $orig
         }
         keytitle -
         xkeypos -
         ykeypos -
         keyfont -
         keylength -
         keywidth {
            set orig $itk_option(-drawkey)
            set itk_option(-drawkey) 0
            $itk_component($param) configure -value $value
            set itk_option(-drawkey) $orig
         }
         default {
            warning_dialog "unrecognised configuration parameter: $param"
         }
      }
   }

   #  Add controls for selecting the image to be contoured. This can
   #  an image displayed in another window, or retained in a file.
   protected method add_image_controls_ {} {

      #  Separator.
      itk_component add namerule {
         LabelRule $w_.namerule -text "Contour image:"
      }
      pack $itk_component(namerule) -side top -fill x

      #  Menu button for selection from displayed images.
      itk_component add targets {
         LabelMenu $w_.targets \
            -labelwidth 14 \
            -valuewidth 20 \
            -valueanchor e \
            -text "Displayed image:"
      }
      pack $itk_component(targets) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(targets) \
         {Displayed image that will be contoured}

      #  Add a binding to update the menu item whenever it is pressed.
      #  XXX bit of a cheat to get menubutton name.
      set menu [$itk_component(targets) component mb]
      bind $menu <ButtonPress-1> "+[code $this update_targets_]"

      #  Add the menu items.
      update_targets_

      #  Add a control for selecting a image stored in disk file.
      itk_component add conimg {
         LabelFileChooser $w_.conimg \
            -labelwidth 14 \
            -text "Other image:" \
            -filter_types $itk_option(-filter_types) \
            -textvariable [scope imagefile_]
      }
      pack $itk_component(conimg) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(conimg) \
         {File name of undisplayed image to contour}
   }

   #  Add the controls for the contour levels and attributes.
   protected method add_att_controls_ {w} {

      itk_component add attrule {
         LabelRule $w.attrule -text "Contour levels & attributes:"
      }
      pack $itk_component(attrule) -side top -fill x

      #  Use a scrolled frame to get all these in a small amount of
      #  real estate.
      itk_component add atframe {
         scrolledframe $w.atframe -width 75 -height 250
      }
      pack $itk_component(atframe) -fill both -expand 1
      set parent [$itk_component(atframe) childsite]

      #  Add headings.
      itk_component add athead1 {
         label $parent.value -text "Level"
      }
      itk_component add athead2 {
         label $parent.colour -text "Colour"
      }
      itk_component add athead3 {
         label $parent.width -text "Width"
      }

      grid $itk_component(athead1) $itk_component(athead2) \
         $itk_component(athead3)

      #  Set up the default colours (wrapped at maximum number).
      for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
         set index [expr int(fmod($i,15))]
         set coldefault_($i) [gaia::ColourMenu::lookup_colour $index]
      }

      #  Now add the controls for the actual values.
      for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {

         #  Entry widget for the contour values.
         itk_component add value$i {
            LabelEntry $parent.value$i \
               -validate real \
               -text "$i:" \
               -labelwidth 3 \
               -command [code $this draw 0 $i]
         }

         #  Menu for selecting the colour.
         itk_component add colour$i {
            util::LabelMenu $parent.colour$i \
               -relief raised
         }

         #  Now add all the colours to it.
         gaia::ColourMenu \#auto $itk_component(colour$i) \
            -change_cmd [code $this set_colour_ $i] \
            -image $itk_option(-rtdimage) 
         
         #  Set to next colour in list.
         $itk_component(colour$i) configure -value $coldefault_($i)

         #  Add menu for selecting the width.
         itk_component add width$i {
            util::LabelMenu $parent.width$i \
               -relief raised
         }

         #  Now add the range of widths to it.
         for {set j 1} {$j <= $itk_option(-maxwidth)} {incr j} {
            $itk_component(width$i) add \
               -label $j \
               -value $j \
               -command [code $this set_width_ $i]
         }
         $itk_component(width$i) configure -value 1

         #  Need to make geometries up to date, otherwise a user define
         #  BorderWidth property seems to leave all widgets size 1.
         update idletasks 

         #  Add these to the grid.
         grid $itk_component(value$i) $itk_component(colour$i) \
              $itk_component(width$i)
      }
   }

   #  Update (or initialise) the possible target images.
   protected method update_targets_ {} {

      #  Remove any existing menu items.
      $itk_component(targets) clear

      #  Locate and add all images. The current image is "$target_".
      set images [skycat::SkyCat::get_skycat_images]

      #  Add the local rtdimage, this needs to be selected
      #  first.
      set name [$itk_option(-rtdimage) fullname]
      $itk_component(targets) add \
         -label "$name ($itk_option(-number))" \
         -value "$itk_option(-image)" \
         -command [code $this set_target_ "$itk_option(-image)"]

      #  And add to the menu.
      foreach w $images {
         if { $w != $itk_option(-image) } {
            if { [winfo exists $w] } {
               set name [[$w get_image] fullname]
               set clone [[winfo toplevel $w] cget -number]
               $itk_component(targets) add \
                  -label "$name ($clone)" \
                  -value "$w" \
                  -command [code $this set_target_ "$w"]
            }
         }
      }

      #  Contour self first.
      set_target_ $itk_option(-image)
   }

   #  Set the "target" image.
   protected method set_target_ {name} {
      set target_ $name
   }

   #  Draw either all the contours or just one which is identified by
   #  its index.
   public method draw { {all 1} {index 0} args} {
      busy {

         #  Check the image to be contoured.
         set rtdimage [get_rtdimage_]
         if { $rtdimage == 0 } {
            return
         }

         #  Clear existing contours.
         if { $all } {
            remove_contours
            update
         } elseif { ! $all } {
            remove_contour_ $index
            update
         }

         #  Get the levels.
         if { $all } {
            set levels [get_levels_]
         } else {
            set levels [$itk_component(value$index) get]
         }

         #  Get the attributes.
         if { $all } {
            set atts [get_ast_atts_]
         } else {
            set atts [get_ast_att_ $index]
         }

         #  If requested just display over the visible canvas +/- a little.
         if { ! $whole_ } {
            set bounds [calc_bounds_]
         } else {
            set bounds ""
         }

         #  Draw the contours. Do this one at a time so that we can
         #  update the interface.
         if { $all } {
            set ncont 0
            foreach value "$levels" {
               set att [lindex $atts $ncont]

               #  Set the tag used to control clear etc.
               $itk_option(-rtdimage) configure -ast_tag \
                  "$itk_option(-ast_tag) $leveltags_($ncont)"

               #  Draw the contour (return value is number of points).
               set drawn_($ncont) \
                  [$itk_option(-rtdimage) contour \
                      $value $rtdimage $careful_ $smooth_ \
                      $att $bounds]

               #  Add/update the key.
               draw_key_
               update idletasks
               incr ncont
            }
         } else {
            #  Set the tag used to control clear etc.
            $itk_option(-rtdimage) configure -ast_tag \
               "$itk_option(-ast_tag) $leveltags_($index)"

            #  Draw the contour.
            set drawn_($index) \
               [$itk_option(-rtdimage) contour \
                   $levels $rtdimage $careful_ $smooth_ \
                   $atts $bounds]

            #  Add/update the key.
            draw_key_
            update idletasks
         }
      }

      #  Some contours are now drawn.
      set contoured_ 1
   }

   #  Get the contour levels from the appropriate entry fields.
   protected method get_levels_ {{ignore 0}} {
      set levels {}
      for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
         set value [$itk_component(value$i) get]
         if { $value != {} } {
            lappend levels $value
         }
      }
      if { $levels != {} } {
         return $levels
      } else {
         if { ! $ignore } {
            info_dialog "You must give some valid contour levels"
         }
         return {}
      }
   }

   #  Get the attributes from the colour and width widgets.
   protected method get_ast_atts_ {} {
      set atts {}
      for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
         set value [$itk_component(value$i) get]
         if { $value != {} } {
            set colour [$itk_component(colour$i) get]
            set colour [gaia::ColourMenu::lookup_index $colour]
            #set colour $colindex_($colour)
            set width [expr [$itk_component(width$i) get]*0.005]
            lappend atts "colour(curve)=$colour,width(curve)=$width"
         }
      }
      return $atts
   }

   #  Get the attributes from the colour and width widgets for a
   #  single contour.
   protected method get_ast_att_ {index} {
      set atts {}
      set value [$itk_component(value$index) get]
      if { $value != {} } {
         set colour [$itk_component(colour$index) get]
         set colour [gaia::ColourMenu::lookup_index $colour]
         #set colour $colindex_($colour)
         set width [expr [$itk_component(width$index) get]*0.005]
         set atts "colour(curve)=$colour,width(curve)=$width"
      }
      return $atts
   }

   #  Get the plain attributes for a contour (without AST formatting).
   protected method get_att_ {index} {
      set atts {}
      set value [$itk_component(value$index) get]
      if { $value != {} } {
         set colour [$itk_component(colour$index) get]
         set width [$itk_component(width$index) get]
         set atts "$colour $width"
      }
      return $atts
   }

   #  Get the levels and attributes as a single string.
   protected method get_levels_and_atts_ {} {
      set atts {}
      for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
         set value [$itk_component(value$i) get]
         if { $value != {} } {
            set colour [$itk_component(colour$i) get]
            set colour [gaia::ColourMenu::lookup_index $colour]
            #set colour $colindex_($colour)
            set width [$itk_component(width$i) get]
            lappend atts "$value $colour $width"
         }
      }
      return $atts
   }

   #  Calculate the bounds of the visible image (canvas
   #  coordinates). This uses the xfrac_ and yfrac_ limits.
   protected method calc_bounds_ {} {
      set xf [expr 0.5*(1.0-$xfrac_)]
      set yf [expr 0.5*(1.0-$yfrac_)]
      set w [winfo width $itk_option(-canvas)]
      set h [winfo height $itk_option(-canvas)]
      set x0 [$itk_option(-canvas) canvasx 0]
      set y0 [$itk_option(-canvas) canvasy 0]
      set dw [expr $w*$xf]
      set dh [expr $h*$yf]
      set x1 [expr $x0+$w-$dw]
      set y1 [expr $y0+$h-$dh]
      set x0 [expr $x0+$dw]
      set y0 [expr $y0+$dh]
      return [list $x0 $y0 $x1 $y1]
   }

   #  Clear the contours levels and attributes, or just the levels.
   public method clear_contours { {all 1} } {
      if { $all } {
         for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
            $itk_component(value$i) configure -value {}
            $itk_component(colour$i) configure -value $coldefault_($i)
            $itk_component(width$i) configure -value 1
         }
      } else {
         for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
            $itk_component(value$i) configure -value {}
         }
      }
      remove_contours
   }

   #  Get the rtdimage that is needed for contouring. This can be the
   #  current image, a one displayed elsewhere or an image in a disk
   #  file. A filename takes preference over a one displayed
   #  already. If an error occurs then rtdimage is set to 0.
   protected method get_rtdimage_ {} {
      if { $imagefile_ != {} } {

	 set rtdimage {}
	 #  Remove the existing external image, if not using same file.
	 if { $image_rtd_ != {} } {
	    if { "[$image_rtd_ cget -file]" == "$imagefile_" } {
	       set rtdimage $image_rtd_
	    } else {
	       catch {image delete $image_rtd_}
	    }
	 }

	 if { $rtdimage == {} } {
	    #  Displayed on disk, create an rtdimage and return this.
	    if {[catch {image create rtdimage -file $imagefile_} rtdimage] != 0} {
	       error "Failed to access image: $imagefile_, for contouring"
	       set rtdimage 0
	    }
	    #  Record so we can tidy up.
	    set image_rtd_ $rtdimage
	 }
      } else {

         #  Name of an rtdimage, just check that this isn't the
         #  current one and that it exists.
         if { [catch {$target_ get_image} rtdimage] != 0 }  {
            error_dialog "Failed to locate the displayed image for contouring"
            set rtdimage 0
         } else {
            if { $rtdimage == $itk_option(-rtdimage) } {
               set rtdimage {}
            }
         }
      }
      return $rtdimage
   }

   #  Get the name of the disk file that has the image we're
   #  contouring.
   protected method get_diskimage_ {} {
      set image {}
      if { $imagefile_ != {} } {

         #  Have disk file name already, just return this.
         set image $imagefile_
      } else {

         #  Name of an rtdimage, if this is the current image return
         #  blank.
         if { [catch {$target_ get_image} rtdimage] == 0 }  {
            set image [$rtdimage cget -file]
         }
      }
      return $image
   }

   #  Remove all contours. Do it one-by-one so we don't interfere with
   #  other contour objects.
   public method remove_contours {} {
      for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
         $itk_option(-canvas) delete $leveltags_($i)
         set drawn_($i) 0
      }

      #  Remove the key.
      $itk_option(-canvas) delete $keytag_

      #  No contours are now drawn.
      set contoured_ 0
   }

   #  Remove a contour by index.
   protected method remove_contour_ {index} {
      $itk_option(-canvas) delete $leveltags_($index)
      set drawn_($index) 0

      #  Delete key and redraw it.
      $itk_option(-canvas) delete $keytag_
      draw_key_
   }

   #  Level generation commands.
   protected method add_gen_controls_ {w} {

      #  Add section header.
      itk_component add genrule {
         LabelRule $w.genrule -text "Contour level generation:"
      }
      pack $itk_component(genrule) -side top -fill x

      #  Number of contours to generate.
      itk_component add ncont {
         LabelEntryScale $w.ncont \
            -text "Number:" \
            -labelwidth 14 \
            -valuewidth 3 \
            -increment 1  \
            -resolution 1 \
            -anchor w \
            -show_arrows 1 \
            -show_scale 1 \
            -from 1 \
            -to $itk_option(-maxcnt) \
            -fix_range 1 \
            -validate integer \
            -value 5
      }
      pack $itk_component(ncont) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(ncont) \
         {Number of contour levels to generate}

      #  Type of generation.
      itk_component add ctype {
         util::LabelMenu $w.ctype \
            -relief raised \
            -text {Algorithm:} \
            -labelwidth 14 \
            -valuewidth 20 \
      }
      pack $itk_component(ctype) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(ctype) \
         {Algorithm to use for contour generation}
      foreach type {automatic linear magnitude percentiles} {
         $itk_component(ctype) add \
            -label $type \
            -value $type \
            -command [code $this ctype_changed_]
      }

      #  Starting value.
      itk_component add start {
         LabelEntry $w.start \
            -validate real \
            -text "Start:" \
            -labelwidth 14 \
            -valuewidth 20
      }
      pack $itk_component(start) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(start) \
         {Starting point for level generation}

      #  Increment.
      itk_component add incre {
         LabelEntry $w.incre \
            -validate real \
            -text "Increment:" \
            -labelwidth 14 \
            -valuewidth 20 \
            -command [code $this generate_contours_]
      }
      pack $itk_component(incre) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(incre) \
         {Increment between generated levels}

      #  Percentile list.
      itk_component add percent {
         LabelEntry $w.percent \
            -text "Percentiles:" \
            -labelwidth 14 \
            -valuewidth 20 \
            -command [code $this generate_contours_]
      }
      pack $itk_component(percent) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(percent) \
         {List of percentiles (space separated)}

      #  Set initial state.
      $itk_component(ctype) configure -value automatic
      ctype_changed_

      #  Button to generate contours.
      itk_component add generate {
         button $w.gen \
            -text "Generate" \
            -command [code $this generate_contours_]
      }
      pack $itk_component(generate) -side top -ipadx 1m -ipady 1m -pady 4m
      add_short_help $itk_component(generate) \
         {Generate contours}
   }

   #  Configure entry fields when the generation type changes.
   protected method ctype_changed_ {} {
      set method [$itk_component(ctype) get]
      if { $method == "automatic" || $method == "percentiles" } {
         set state disabled
      } else {
         set state normal
      }
      $itk_component(start) configure -state $state
      $itk_component(incre) configure -state $state
      if { $method == "percentiles" } {
	 $itk_component(percent) configure -state normal
	 $itk_component(ncont) configure -state disabled
      } else {
	 $itk_component(percent) configure -state disabled
	 $itk_component(ncont) configure -state normal
      }
   }

   #  Generate contours levels.
   protected method generate_contours_ {args} {
      set method [$itk_component(ctype) get]
      set ncont [$itk_component(ncont) get]
      set ncont [min $itk_option(-maxcnt) $ncont]
      set start [$itk_component(start) get]
      set incre [$itk_component(incre) get]
      set percent [$itk_component(percent) get]
      if { $method != "automatic" && $method != "percentiles" &&
           ( $start == {} || $incre == {} ) } {
         info_dialog "Please enter values for start and increment"
         return
      } elseif { $method == "percentiles" && $percent == {} } {
         info_dialog "Please enter values for percentiles"
         return
      }
      clear_contours 0
      if { $method == "magnitude" } {
         for {set i 0} {$i < $ncont} {incr i} {
            $itk_component(value$i) configure -value \
               [expr $start*pow(10.0,-0.4*$i*$incre)]
         }
      } elseif { $method == "linear" } {
         for {set i 0} {$i < $ncont} {incr i} {
            $itk_component(value$i) configure -value \
               [expr $start+$i*$incre]
         }
      } else {

	 #  Automatic, or percentiles. Need to use the data of the
	 #  image to be contoured.
	 set rtdimage [get_rtdimage_]
	 if { $rtdimage == {} || $rtdimage == 0 } {
	    set rtdimage $itk_option(-rtdimage)
	 }
	 if { $method == "automatic" } {
	    set min [$rtdimage min]
	    set max [$rtdimage max]
	    set incre [expr double($max-$min)/double($ncont)]
	    set start [expr $min+$incre*0.5]
	    for {set i 0} {$i < $ncont} {incr i} {
	       $itk_component(value$i) configure -value \
		  [expr $start+$i*$incre]
	    }
	 } else {

	    #  Percentiles.
	    set i 0
	    foreach level [$rtdimage percentiles $percent] {
	       $itk_component(value$i) configure -value $level
	       incr i
	       if { $i >= $itk_option(-maxcnt) } {
		  break
	       }
	    }
	 }
      }

      #  Switch to the levels pane.
      $itk_component(tab) select 0
   }

   #  Set the colour of a contour (if it is drawn), or all contours if
   #  using a single colour.
   protected method set_colour_ {level colindex} {
      set colour [gaia::ColourMenu::lookup_colour $colindex]
      if { $single_colour_ } {
         for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
            $itk_component(colour$i) configure -value $colour
            $itk_option(-canvas) itemconfigure $leveltags_($i) -fill $colour
         }
      } else {
         $itk_option(-canvas) itemconfigure $leveltags_($level) -fill $colour
      }
   }

   #  Set the width of a contour (if it is drawn), or all contours if
   #  using a single width.
   protected method set_width_ {index} {
      set width [$itk_component(width$index) get]
      if { $single_width_ } {
         for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
            if { $i != $index } {
               $itk_component(width$i) configure -value $width
            }
            $itk_option(-canvas) itemconfigure $leveltags_($i) -width $width
         }
      } else {
         $itk_option(-canvas) itemconfigure $leveltags_($index) -width $width
      }

      #  Text of key is special case, keep width 0.
      $itk_option(-canvas) itemconfigure $texttag_ -width 0
   }

   #  Add controls for configuring the contour key.
   protected method add_key_controls_ {w} {

      #  Add section header.
      itk_component add keyrule {
         LabelRule $w.keyrule -text "Key configuration:"
      }
      pack $itk_component(keyrule) -side top -fill x

      #  Whether to draw key or not.
      itk_component add drawkey {
         StarLabelCheck $w.drawkey \
            -text "Display key:" \
            -onvalue 1 \
            -offvalue 0 \
            -labelwidth 15 \
	    -variable [scope itk_option(-drawkey)] \
            -command [code $this toggle_drawkey_]
      }
      pack $itk_component(drawkey) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(drawkey) \
	  {Toggle if a contour level key is to be displayed}

      #  Title for key.
      itk_component add keytitle {
         LabelEntry $w.keytitle \
            -text "Title:" \
            -labelwidth 15 \
            -value "Contour key" \
            -command [code $this draw_key_]
      }
      pack $itk_component(keytitle) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(keytitle) \
	  {Title for contour key}

      #  Position of key relative to top right hand corner.
      itk_component add xkeypos {
         LabelEntryScale $w.xkeypos \
            -text "X offset:" \
            -labelwidth 15 \
            -valuewidth 5 \
            -from -200 \
            -to 200 \
            -increment 1  \
            -resolution 1 \
            -show_arrows 1 \
            -anchor w \
            -value 0 \
            -command [code $this draw_key_]
      }
      pack $itk_component(xkeypos) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(xkeypos) \
         {X offset of key from top right hand corner}

      itk_component add ykeypos {
         LabelEntryScale $w.ykeypos \
            -text "Y offset:" \
            -labelwidth 15 \
            -valuewidth 5 \
            -from -200 \
            -to 200 \
            -increment 1  \
            -resolution 1 \
            -show_arrows 1 \
            -anchor w \
            -value 0 \
            -command [code $this draw_key_]
      }
      pack $itk_component(ykeypos) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(ykeypos) \
         {Y offset of key from top right hand corner}

      #  Menu for selecting colour of key title.
      itk_component add keycolour {
         util::LabelMenu $w.keycolour \
            -relief raised \
            -text "Title colour:" \
            -labelwidth 15
      }
      pack $itk_component(keycolour) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(keycolour) \
         {Colour of key title}

      #  Now add all the colours to it.
      foreach {index xname} $colourmap_ {
         $itk_component(keycolour) add \
            -label {    } \
            -value $xname \
            -background $xname \
            -command [code $this draw_key_]
      }

      #  Menu for selecting fonts of key text.
      itk_component add keyfont {
         util::LabelMenu $w.keyfont \
            -relief raised \
            -text "Font:" \
            -labelwidth 15
      }
      pack $itk_component(keyfont) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(keyfont) \
         {Font of all text in key}

      #  Now add all the fonts.
      foreach {font sname} $fontmap_ {
         $itk_component(keyfont) add \
            -label $sname \
            -value $font \
            -font $font \
            -command [code $this draw_key_]
     }

      #  Key line lengths.
      itk_component add keylength {
         LabelEntryScale $w.keylength \
            -text "Bar length:" \
            -labelwidth 15 \
            -valuewidth 5 \
            -from 2 \
            -to 100 \
            -increment 1  \
            -resolution 1 \
            -show_arrows 1 \
            -anchor w \
            -value 20 \
            -command [code $this draw_key_]
      }
      pack $itk_component(keylength) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(keylength) \
         {Length of bars shown in key}

      #  Surround box line width.
      itk_component add keywidth {
         LabelEntryScale $w.keywidth \
            -text "Surround width:" \
            -labelwidth 15 \
            -valuewidth 5 \
            -from 1 \
            -to 10 \
            -increment 1  \
            -resolution 1 \
            -show_arrows 1 \
            -anchor w \
            -value 1 \
            -command [code $this draw_key_]
      }
      pack $itk_component(keywidth) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(keywidth) \
         {Width of box around key}
   }

   #  Set whether key is to be drawn or not.
   protected method toggle_drawkey_ {} {
       if { $itk_option(-drawkey) } {
	   set state normal
       } else {
	   set state disabled
       }
       $itk_component(keytitle) configure -state $state
       $itk_component(xkeypos) configure -state $state
       $itk_component(ykeypos) configure -state $state
       $itk_component(keycolour) configure -state $state
       $itk_component(keyfont) configure -state $state
       $itk_component(keylength) configure -state $state
       $itk_component(keywidth) configure -state $state
       draw_key_
   }

   #  Add a level key to the image. The key consists of the level and
   #  a coloured line. Any args are ignored.
   protected method draw_key_ {args} {

      #  Delete the current key.
      $itk_option(-canvas) delete $keytag_

      #  Stop now if not drawing.
      if { ! $itk_option(-drawkey) } {
	  return
      }

      #  Get current levels.
      set levels [get_levels_ 1]
      if { $levels == {} } {
         return
      }

      #  Get the bounds of the displayed contours and work out a
      #  suitable position for the key.
      lassign [calc_bounds_] x0 y x y1
      set xori [expr $x+[$itk_component(xkeypos) get]]
      set yori [expr $y+[$itk_component(ykeypos) get]]
      set x [expr $xori+10.0]
      set y [expr $yori+10.0]

      #  Get various configuration values.
      set font [$itk_component(keyfont) get]
      set keycol [$itk_component(keycolour) get]
      set keywid [$itk_component(keywidth) get]
      set dx [$itk_component(keylength) get]
      set dy 15.0

      #  Title.
      lassign [get_att_ 0] colour width
      set title [$itk_component(keytitle) get]
      if { $title != {} } {
         $itk_option(-canvas) create text [expr $x+$dx] $y \
            -text "$title" \
            -anchor w \
            -fill $keycol \
            -tags "$itk_option(-ast_tag) $keytag_ $texttag_" \
            -width 0 \
            -font $font
         set y [expr $y+$dy]
      }

      #  Now add each line and level.
      for {set i 0} {$i < $itk_option(-maxcnt)} {incr i} {
         if { $drawn_($i) } {
            set value [lindex $levels $i]
            lassign [get_att_ $i] colour width
            $itk_option(-canvas) create line $x $y [expr $x+$dx] $y \
               -fill $colour \
               -width $width \
               -tags "$itk_option(-ast_tag) $keytag_ $leveltags_($i)"
            $itk_option(-canvas) create text [expr $x+$dx+5] $y \
               -text "$value" \
               -anchor w \
               -fill $colour \
               -tags "$itk_option(-ast_tag) $keytag_ $leveltags_($i) $texttag_" \
               -width 0 \
               -font $font
            set y [expr $y+$dy]
         }
      }

      #  Finally add the surround box (also used as control for
      #  repositioning whole of key).
      set bbox [$itk_option(-canvas) bbox $keytag_]
      if { $bbox != {} } {
         set x1 [expr [lindex $bbox 2] +5.0]
         set y1 [expr [lindex $bbox 3] +5.0]
         set keyid [$itk_option(-canvas) create rectangle $xori $yori $x1 $y1\
                       -outline $keycol \
                       -tags "$itk_option(-ast_tag) $keytag_" \
                       -width $keywid \
                       -stipple pat7 \
                       -fill white]

         #  Add bindings to move this (and the other elements of the
         #  key) about.
         $itk_option(-canvas) bind $keyid <1> \
            [code eval $this record_mark_ %x %y]
         $itk_option(-canvas) bind $keyid <B1-Motion> \
            [code eval $this move_key_ %x %y]
         $itk_option(-canvas) bind $keyid <ButtonRelease-1> \
            [code eval $this update_key_]
      }
   }

   #  Record the position of the key when <1> is pressed.
   protected method record_mark_ {x y} {
      set xref_ [$itk_option(-canvas) canvasx $x]
      set yref_ [$itk_option(-canvas) canvasy $y]
   }

   #  Move all the elements of the key.
   protected method move_key_ {x y} {
      set x [$itk_option(-canvas) canvasx $x]
      set y [$itk_option(-canvas) canvasy $y]
      set dx [expr $x-$xref_]
      set dy [expr $y-$yref_]
      $itk_option(-canvas) move $keytag_ $dx $dy
      set xref_ $x
      set yref_ $y
   }

   #  Update key position when move is complete.
   protected method update_key_ {} {
      lassign [$itk_option(-canvas) bbox $keytag_] bx0 by0 bx1 by1
      lassign [calc_bounds_] ix0 iy0 ix1 iy1
      set newx [expr $bx0-$ix1+0.5]
      set newy [expr $by0-$iy0+1.0]
      set orig $itk_option(-drawkey)
      set itk_option(-drawkey) 0
      $itk_component(xkeypos) configure -value $newx
      $itk_component(ykeypos) configure -value $newy
      set itk_option(-drawkey) $orig
      draw_key_
   }

   #  Add controls for choosing which part of the image to contour.
   protected method add_whole_controls_ {w} {

      #  Control what area the plot covers. This can be the whole just
      #  or just the part that is displayed.
      itk_component add regionrule {
         LabelRule $w.region -text "Contour region:"
      }
      pack $itk_component(regionrule) -fill x -ipadx 1m
      itk_component add whole {
         StarLabelCheck $w.whole \
            -text "Whole of image:" \
            -onvalue 1 \
            -offvalue 0 \
            -labelwidth 15 \
            -variable [scope whole_] \
            -command [code $this set_whole_]
      }
      set whole_ 0
      pack $itk_component(whole) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(whole) \
         {Toggle if whole image is to be contoured}

      #  Control the fraction of the display that the contouringh
      #  covers.
      set xfrac_ 0.7
      itk_component add xfrac {
         LabelEntryScale $w.xfrac \
            -text "X display fraction:" \
            -labelwidth 15 \
            -valuewidth 5 \
            -from 0.01 \
            -to 0.99 \
            -increment 0.01  \
            -resolution 0.01 \
            -show_arrows 1 \
            -anchor w \
            -value $xfrac_ \
            -command [code $this set_display_frac_ xfrac_]
      }
      pack $itk_component(xfrac) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(xfrac) \
         {X fraction of visible region to contour}

      set yfrac_ 0.7
      itk_component add yfrac {
         LabelEntryScale $w.yfrac \
            -text "Y display fraction:" \
            -labelwidth 15 \
            -valuewidth 5 \
            -from 0.01 \
            -to 0.99 \
            -increment 0.01  \
            -resolution 0.01 \
            -show_arrows 1 \
            -anchor w \
            -value $yfrac_ \
            -command [code $this set_display_frac_ yfrac_]
      }
      pack $itk_component(yfrac) -side top -fill x -ipadx 1m -ipady 1m
      add_short_help $itk_component(xfrac) \
         {Y fraction of visible region to contour}

      #  Do the initialisation of the fraction widget states.
      set_whole_
   }

   #  Toggle fraction sliders according to whether whole of image is
   #  being contoured.
   protected method set_whole_ {args} {
      if { $whole_ } {
         $itk_component(xfrac) configure -state disabled
         $itk_component(yfrac) configure -state disabled
      } else {
         $itk_component(xfrac) configure -state normal
         $itk_component(yfrac) configure -state normal
      }
   }

   #  Set the displayed fractions.
   protected method set_display_frac_ {which value} {
      set $which $value
   }

   #  Configuration options: (public variables)
   #  ----------------------
   #  Name of canvas.
   itk_option define -canvas canvas Canvas {} {}

   #  Name of rtdimage widget.
   itk_option define -rtdimage rtdimage RtdImage {} {}

   #  Name of RtdImageCtrl widget or a derived class.
   itk_option define -image image Image {} {}

   #  Name of CanvasDraw widget.
   itk_option define -canvasdraw canvasdraw CanvasDraw {} {}

   #  Identifying number for toolbox (shown in () in window title).
   itk_option define -number number Number 0 {}

   #  Command to execute to create a new instance of this object.
   itk_option define -clone_cmd clone_cmd Clone_Cmd {}

   #  If this is a clone, then it should die rather than be withdrawn.
   itk_option define -really_die really_die Really_Die 0

   #  The filter types of images.
   itk_option define -filter_types filter_types Filter_Types {} {}

   #  Whether contours are plotted carefully (slow, but precise) or not.
   itk_option define -careful careful Careful 0 {
      set careful_ $itk_option(-careful)
   }

   #  Whether contours are plotted using smooth polylines.
   itk_option define -smooth smooth Smooth 0 {
      set smooth_ $itk_option(-smooth)
   }

   #  Global tag used to control redraws etc. Individual tags are used
   #  within this class.
   itk_option define -ast_tag ast_tag Ast_Tag {} {
      if { $itk_option(-ast_tag) == {} } {
         set itk_option(-ast_tag) "ast_element"
      }
   }

   #  Maximum number of contours, only works once.
   itk_option define -maxcnt maxcnt Maxcnt 30

   #  Maximum width of contour line (as multiple of 0.005).
   itk_option define -maxwidth maxwidth Maxwidth 10

   #  Whether to draw the key or not.
   itk_option define -drawkey drawkey Drawkey 1

   #  Protected variables: (available to instance)
   #  --------------------
   #  Whether contours are plotted carefully.
   protected variable careful_ 0

   #  Whether contours are smoothed.
   protected variable smooth_ 0

   #  Name of rtdimage that we are contouring or the filename to use.
   protected variable target_ {}
   protected variable imagefile_ {}

   #  Which contours are drawn (needed to keep key free of undrawn
   #  levels).
   protected variable drawn_

   #  Whether any contours are drawn (controls redraw).
   protected variable contoured_ 0

   #  Names of the possible colours and their AST index equivalents.
   protected variable colourmap_ {
      0 "#fff" 1 "#000" 2 "#f00" 3 "#0f0" 4 "#00f" 5 "#0ff" 6 "#f0f"
      7 "#ff0" 8 "#f80" 9 "#8f0" 10 "#0f8" 11 "#08f" 12 "#80f"
      13 "#f08" 14 "#512751275127" 15 "#a8b4a8b4a8b4" 16 "#0f0" }

   #  Default colours.
   protected variable coldefault_

   #  Tags used for configuring each contour levels.
   protected variable leveltags_

   #  Tags for elements of key (needs to be unique for each object).
   #  Text is different as need to disable width attributes.
   protected variable keytag_
   protected variable texttag_

   #  Reference position for moving key.
   protected variable xref_ 1
   protected variable yref_ 1

   #  Which part of image is to be contoured.
   protected variable whole_ 0
   protected variable xfrac_ 0.7
   protected variable yfrac_ 0.7

   #  Window names of the tab notebook childsites.
   protected variable child_

   #  Fonts for text in key, plus short description.
   protected variable fontmap_ {
      "-adobe-helvetica-medium-r-normal--*-140-*-*-*-*-*-*" "medium"
      "-adobe-helvetica-medium-o-normal--*-140-*-*-*-*-*-*" "medium"
      "-adobe-helvetica-bold-r-normal--*-140-*-*-*-*-*-*"   "bold"
      "-adobe-helvetica-bold-o-normal--*-140-*-*-*-*-*-*"   "bold"
      "-adobe-helvetica-medium-r-normal--*-120-*-*-*-*-*-*" "medium"
      "-adobe-helvetica-medium-o-normal--*-120-*-*-*-*-*-*" "medium"
      "-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*"   "bold"
      "-adobe-helvetica-bold-o-normal--*-120-*-*-*-*-*-*"   "bold"
      "-adobe-times-medium-r-normal--*-120-*-*-*-*-*-*"     "medium"
      "-adobe-times-medium-i-normal--*-120-*-*-*-*-*-*"     "medium"
      "-adobe-times-bold-r-normal--*-120-*-*-*-*-*-*"       "bold"
      "-adobe-times-bold-i-normal--*-120-*-*-*-*-*-*"       "bold"
      "-adobe-courier-medium-r-*-*-*-120-*-*-*-*-*-*"       "fixed-width"
      "-adobe-courier-medium-o-*-*-*-120-*-*-*-*-*-*"       "fixed-width"
      "-adobe-courier-bold-r-*-*-*-120-*-*-*-*-*-*"         "fixed-width"
      "-adobe-courier-bold-o-*-*-*-120-*-*-*-*-*-*"         "fixed-width"
      "-adobe-helvetica-bold-r-*-*-20-120-*-*-*-*-*-*"      "large screen"
   }

   #  Name of rtdimage used to access external files.
   protected variable image_rtd_ {}

   #  Whether to use a single colour for all lines.
   protected variable single_colour_ 0

   #  Whether to use a single width for all lines.
   protected variable single_width_ 0

   #  Common variables: (shared by all instances)
   #  -----------------

   #  Number of potential contours drawn.
   common unique_ 0


#  End of class definition.
}
