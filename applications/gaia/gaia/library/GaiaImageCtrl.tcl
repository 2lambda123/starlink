#+
#  Name:
#     GaiaImageCtrl.tcl

#  Purpose:
#     Defines a class for controlling an RtdImage class by adding
#     a control panel, zoom and panning windows.

#  Type of Module:
#     [incr Tk] class

#  Description:
#     This module defines a class that adds to the options defined by
#     the SkyCatCtrl class that are required for use by GAIA. See the
#     individual method and options for details.

#  Invocation:
#     GaiaImageCtrl name [configuration options]

#  Notes:
#     This will only run with the gaia_wish installed as part of the
#     GAIA package.

#  Authors:
#     PWD: Peter Draper (STARLINK)
#     {enter_new_authors_here}

#  Inherits:
#     Methods and configuration options of SkyCatCtrl.

#  Copyright:
#     Copyright (C) 1998-1999 Central Laboratory of the Research Councils

#  History:
#     24-SEP-1997 (PWD):
#        Original version
#     15-NOV-1997 (PWD):
#        Commented out code relating to grid control. This is now
#        replaced by the AST grid (the code is left in place in case a
#        comparison of the two methods is helpful).
#     05-FEB-1998 (PWD):
#        Removed commented out sections, added -with_warp override.
#     07-APR-1998 (PWD):
#        Added code to control temporary status of image (this was
#        previously performed at the Gaia level, which proved to be
#        problematic).
#     26-FEB-1999 (PWD):
#        Merged GaiaImage into this class. This removes the need to
#        modify RtdImageCtrl. All code relating to float_panel is
#        removed as are changes for with_warp.
#     24-NOV-1999 (PWD):
#        Added zoom to selected region changes (bound to Shift-1 and
#        Shift-2).
#     28-JAN-2000 (PWD):
#        Override focus_ method to control default CDE window manager
#        behaviour somewhat better.
#     10-APR-2001 (PWD):
#        Added selected_area method as SkyCatCtrl version assumed
#        images could have no dimension greater than width (tall
#        2000x4000 break with this arrangement).
#     23-JUL-2001 (PWD):
#        Added UKIRT quick look facility changes.
#     {enter_changes_here}

#-

itk::usual GaiaImageCtrl {}

itcl::class gaia::GaiaImageCtrl {
   inherit skycat::SkyCatCtrl

   #  Constructor: create a new instance of this class.
   constructor {args} {

      #  Record toplevel window name.
      set top_ [winfo toplevel $w_]

      #  Add a bindtag to the canvas so we can add bindings that will
      #  not be changed by others.
      set tags [bindtags $canvas_]
      lappend tags mytag$this
      bindtags $canvas_ $tags

      #  Add bindings to zoom the main window about the cursor position.
      $canvas_ bind $imageId_ <Shift-1> [code eval $this zoomin]
      $canvas_ bind $imageId_ <Shift-2> [code eval $this zoomout]

      #  Create an object for handling image names.
      set namer_ [GaiaImageName \#auto]

      #  Remove options we're overriding from base classes.
      itk_option remove rtd::RtdImage::show_object_menu
      itk_option remove rtd::RtdImage::drag_scroll
      itk_option remove rtd::RtdImage::file

      #  Initialise all options.
      eval itk_initialize $args
   }

   #  Destructor. Remove temporary image if necessary. Withdraw
   #  toplevel containing this window to stop view of partially
   #  destroyed windows. Note when "." is destroyed we must just
   #  accept an exit without prompting (this is what all the catches
   #  achieve).
   destructor {
      #  The FITS chooser needs to release any temporary files used for
      #  storing in-line compressed images.
      gaia::GaiaHduChooser::release_temporary_files

      if { ![catch {wm withdraw $top_}] } {
         catch {maybe_delete_}
      }
      delete_temporary_

      if { $after_id_ != {} } {
         catch {after cancel $after_id_}
      }

      if { $namer_ != {} } {
	 catch {delete object $namer_}
      }

   }

   #  This method is called from the base class (TopLevelWidget) after all
   #  the options have been evaluated
   protected method init {} {
      skycat::SkyCatCtrl::init

      #  Add image band control (overrides Rtd version by resetting
      #  the image bindings).
      gaia::GaiaImageMBand $w_.newmband \
         -image $this \
         -defaultcursor $itk_option(-cursor)

      #  Clicking in main window gives it focus.
      $canvas_ bind $image_ <1> +[code $this focus_ in]

      #  Pass on UKIRT quick look config.
      $image_ configure -ukirt_ql $itk_option(-ukirt_ql)
   }

   #  Make the panel info subwindow. Override to use GaiaImagePanel,
   #  rather than RtdImagePanel. Also remove the make_grid_item capability.
   protected method make_panel_info {panel} {
      #  Add info panel
      feedback "info panel..."

      # Info panel, GaiaImagePanel object used to display image controls
      itk_component add info {
         gaia::GaiaImagePanel $panel.info \
            -image $this \
            -state disabled \
            -min_scale $itk_option(-min_scale) \
            -max_scale $itk_option(-max_scale) \
            -shorthelpwin $itk_option(-shorthelpwin) \
            -borderwidth 3 -relief groove \
            -ukirt_ql $itk_option(-ukirt_ql)
      }
      if { $itk_option(-float_panel) } {
         set side bottom
      } else {
         set side left
      }
      pack $itk_component(info)  \
         -side $side -fill both -expand 1

      #  Take opportunity to stop floating panel from being destroyed.
      #  Using {} as command isn't enough.
      if { $itk_option(-float_panel) } {
         wm protocol $panel WM_DELETE_WINDOW [code $this do_nothing_]
      }

      #  Make sure that the $panel.zoom.dozoom variable is always set
      #  (if switched off as a option then this isn't the case which
      #  causes problems with hide_control_panel).
      global ::$itk_component(panel).zoom.dozoom
      set $itk_component(panel).zoom.dozoom $itk_option(-dozoom)
   }
   private method do_nothing_ {} {
   }

   #  Display the graphics toolbox window (override to use
   #  StarCanvasDraw, instead of CanvasDraw).
   protected method make_toolbox {} {
      itk_component add draw {
         gaia::StarCanvasDraw $w_.draw \
            -canvas $canvas_ \
            -transient 1 \
            -center 0 \
            -withdraw 1 \
            -clipping 0 \
            -shorthelpwin $itk_option(-shorthelpwin) \
            -withtoolbox $itk_option(-withtoolbox) \
            -defaultcursor $itk_option(-cursor) \
            -show_object_menu $itk_option(-show_object_menu) \
            -rtdimage $image_ \
            -lowestitem $imageId_ \
            -regioncommand $itk_option(-regioncommand) \
            -ignore_tag $itk_option(-ast_tag)
      }

      set_drawing_area

      # Clicking on the image or image background deselects other objects.
      $canvas_ bind $image_ <1> +[code $itk_component(draw) deselect_objects]
   }

   # Control the focussing of the canvas. Only take focus if the
   # top-level window associated with this canvas has the focus
   # (i.e. it's not in another toplevel somewhere). If this isn't
   # done then mysterious raises of the main image window can occur
   # with some window managers (mainly CDE, with click-to-focus &
   # autoraise).
   #
   # allan: 19.6.98: disabled the above behavior, since it causes
   # problems with mouse warping and confuses people. Can't verify
   # the CDE behavior...
   #
   # PWD: back again the CDE window manager is really naff at
   # controlling transients, which allows the main window to
   # autoraise above them! Add <1> binding to get focus back to image.
   protected method focus_ {way} {
      global ::$w_.focus
      set top [winfo toplevel $w_]
      set focus [focus -displayof $top]
      if { $focus != {} } {
         if {[winfo toplevel $focus] == "$top" } {

            #  This toplevel has the focus (or at least a child of it
            #  has), so it's ok to proceed.
            if { $way == "in" } {
               set $w_.focus [focus -displayof .]
               catch {focus $canvas_}
            } else {
               catch {focus [set $w_.focus]}
            }
         }
      }
   }

   #  This method is redefined here to also rescale pixel-width
   #  objects correctly.
   public method scale {x y} {
      rtd::RtdImageCtrl::scale $x $y
      $itk_component(draw) pixel_width_changed
   }

   #  Toggle rotation of the image and canvas items. Extended to add
   #  astrometry grid update.
   public method rotate {bool} {
      if {$bool != [$image_ rotate]} {
         rtd::RtdImage::rotate $bool

         #  Notify the astrometry grid to re-display itself if
         #  asked.
         if { $itk_option(-grid_command) != {} } {
            eval $itk_option(-grid_command)
         }
      }
   }

   #  Flip or unflip the image and canvas items about the
   #  x or y axis, as given by $xy. Extended to add astrometry grid
   #  update.
   public method flip {xy bool} {
      if {$bool != [$image_ flip $xy]} {
         rtd::RtdImage::flip $xy $bool

         #  Notify the astrometry grid to re-display itself if
         #  asked.
         if { $itk_option(-grid_command) != {} } {
            eval $itk_option(-grid_command)
         }
      }
   }

   #  Arrange to interactively create a spectrum line to display
   #  a graph of the image values along a given line. Changed to not
   #  prompt when wanted.
   public method spectrum {{showinfo 1}} {
      if {[$image_ isclear]} {
         warning_dialog "No image is currently loaded" $w_
         return
      }

      if {[winfo exists $w_.spectrum]} {
         $w_.spectrum quit
      }

      if { $showinfo} {
         set ok [action_dialog \
                    "Press OK and then drag out a line over the image with button 1" \
                    $w_]
      } else {
         set ok 1
      }
      if { $ok } {
         $itk_component(draw) set_drawing_mode line [code $this make_spectrum]
      }
   }

   #  Display a dialog for selecting objects in the image and
   #  displaying information about the selected area of the
   #  image. Override to use GaiaImagePick, which adds the ability to
   #  save the information into a disk file (GaiaPick.dat).
   public method pick_dialog {{command ""}} {
      if {[$image_ isclear]} {
         warning_dialog "No image is currently loaded" $w_
         return
      }
      utilReUseWidget gaia::GaiaImagePick $w_.pick \
         -target_image $this \
         -command $command \
         -verbose $itk_option(-verbose) \
         -orient $itk_option(-pickobjectorient) \
         -debug $itk_option(-debug) \
         -shorthelpwin $itk_option(-shorthelpwin)
      $w_.pick pick_object
   }

   #  Make a hard copy of the image display, just override use
   #  GaiaImagePrint, remove ESO references and reduce the page width
   #  slightly (not A4?).
   public method print {} {
        if {[$image_ isclear]} {
            warning_dialog "No image is currently loaded" $w_
            return
        }
        set object [$image_ object]
        set file [file tail $itk_option(-file)]
        set center [$image_ wcscenter]
        set user [id user]
        set app [lindex [winfo name .] 0]
        set date [clock format [clock seconds] -format {%b %d, %Y at %H:%M:%S}]
        utilReUseWidget gaia::GaiaImagePrint $w_.print \
           -image $this \
           -show_footer 1 \
           -whole_canvas 0 \
           -transient 1 \
           -pagewidth 7.5i \
           -top_left  "$itk_option(-appname)\n$object" \
           -top_right "$file\n$center" \
           -bot_left  "$user" \
           -bot_right "$date"
   }

   #  Create a graph to display the image data values along the line
   #  just created.
   #     "line_id" is the canvas id of the line.
   #  Extended to call derived class that also saves slice as an
   #  image.
   public method make_spectrum {line_id x0 y0 x1 y1} {
      if {[winfo exists $w_.spectrum]} {
         $w_.spectrum quit
      }
      gaia::GaiaImageSpectrum $w_.spectrum \
         -x0 [expr int($x0)] \
         -y0 [expr int($y0)] \
         -x1 [expr int($x1)] \
         -y1 [expr int($y1)] \
         -image $this \
         -transient 1 \
         -shorthelpwin $itk_option(-shorthelpwin) \
         -line_id $line_id
   }

   #  Methods to deal with the autoscroll when dragging off canvas.
   protected method start_autoscan_ {x y} {
      set movex 0
      set movey 0
      if { $y >= [winfo height $canvas_]} {
         set movey 10
      } elseif {$y < 0} {
         set movey -10
      } elseif { $x >= [winfo width $canvas_]} {
         set movex 10
      } elseif {$x < 0} {
         set movex -10
      }
      autoscan_ $movex $movey
   }
   protected method autoscan_ {movex movey} {
      $canvas_ yview scroll $movey units
      $canvas_ xview scroll $movex units
      set after_id_ [after 50 [code $this autoscan_ $movex $movey]]
   }
   protected method cancelrepeat_ {} {
      after cancel $after_id_
      set after_id_ {}
   }

   #  Update the toplevel window header and icon name to include the name
   #  of the file being displayed.
   public method update_title {} {
      set file "[file tail [$image_ fullname]]"
      set w [winfo toplevel $w_]
      wm title $w "$itk_option(-appname): $file ([$w cget -number])"
      wm iconname $w $file
   }

   #  Add a generated image to display the colors in the colormap
   #  (this is packed differently from the main method so the colour
   #  map remains visible more often).
   public method make_colorramp {} {
      if { $itk_option(-with_colorramp) } {
         itk_component add colorramp {
            rtd::RtdImageColorRamp $w_.colorramp \
               -height $itk_option(-colorramp_height) \
               -usexshm $itk_option(-usexshm) \
               -viewmaster $image_
         }
         pack $itk_component(colorramp) -side bottom -fill x \
            -before $itk_component(imagef)
      }
   }

   #  This method is called by the image code whenever a new image is loaded.
   public method new_image_cmd {} {
      skycat::SkyCatCtrl::new_image_cmd

      #  Remove old temporary file, if not already done.
      maybe_delete_
      delete_temporary_

      #  Record this name, until another new image is set.
      set last_file_ $itk_option(-file)

      #  Set the default precision used for coordinate readouts.
      set_readout_precision_

      #  Set the default for CAR projections.
      set_linear_cartesian_

      #  Set the default for merging headers.
      set_always_merge_
   }

   #  Set the precision used to display RA/Dec coordinates. By default
   #  these show two decimal places for arcsecs, but if requested can
   #  show three (for milli arcsecs).
   protected method set_readout_precision_ {} {
      if { $image_ != {} } {
         catch {
            $image_ astmilli $itk_option(-extended_precision)
         }
      }
   }

   #  Set the default for reading CAR projections. Do this each time
   #  so that it's always up to date.
   protected method set_linear_cartesian_ {} {
      if { $image_ != {} } {
         catch {
            $image_ astcarlin $itk_option(-linear_cartesian)
         }
      }
   }

   #  Set the default for merging headers.
   protected method set_always_merge_ {} {
      if { $image_ != {} } {
         catch {
            $image_ astalwaysmerge $itk_option(-always_merge)
         }
      }
   }

   #  Issue a warning containing any AST messages about WCS.
   public method display_astwarn {} {
      set warn [$image_ astwarnings]
      if { $warn != {} } {
         set message \
            "Reading your image produced the following messages:\n\n$warn"
      }
      set existed [winfo exists $w_.astwarn]
      utilReUseWidget util::TextDialog $w_.astwarn \
         -bitmap {} \
         -textwidth 80 \
         -textheight 20 \
         -buttons "Close" \
         -modal 0 \
         -text "Astrometry warnings" \
         -title "Astrometry warnings" \
         -contents "$message"
      if { ! $existed } {
         $w_.astwarn activate
      }
   }

   #  Open and load a new image file via file name dialog. Added the
   #  ability to deal with a list of possible file extensions and a
   #  possible image slice to this method.
   public method open {{dir "."} {pattern "*.*"}} {
      set file [get_file_ $dir $pattern $itk_option(-file_types)]
      if {"$file" != ""} {
         if { $last_file_ != "" } {
            #  Already have a displayed image. Check that we do
            #  not need to delete it, before accepting the new one.
            maybe_delete_
            delete_temporary_
         }

	 #  Parse name as we may need to also configure the HDU number.
	 $namer_ configure -imagename $file
         configure -hdu [$namer_ fitshdunum]
         configure -file [$namer_ fullname 0]

         #  Notify that an image has been opened to any listeners.
         if { $itk_option(-file_open_cmd) != {} } {
            eval $itk_option(-file_open_cmd) [list $itk_option(-file)]
         }
      }
   }

   #  Reload the image file, if there is one (redefined from parent
   #  class, since we use different mmap flags here that cause the
   #  inherited version to not work).
   public method reopen {} {
       set file [$image_ cget -file]
       if {"$file" != ""} {
	   $image_ configure -file $file
       } else {
	   $image_ update
       }
   }

   #  Save the current image to a file chosen from a file name dialog
   #  (added file patterns and .fit as default extension and update to
   #  temporary status).
   public method save_as {{dir "."} {pattern "*.*"}} {
      if {[$image_ isclear]} {
         warning_dialog "No image is currently loaded" $w_
         return
      }

      #  Special case: if input file is a FITS file then we can only
      #  save it as a fits file. NDFs may be saved as other formats.
      if { [$image_ isfits] } {
         set file [get_file_ $dir $pattern {{any * } {FITS *.fits} {FIT *.fit}}]
      } else {
         set file [get_file_ $dir $pattern $itk_option(-file_types)]
      }
      if {"$file" != ""} {
	 $namer_ configure -imagename $file
         if {[$namer_ exists]} {
            if {![confirm_dialog "$file exists - Do you want to overwrite it ?" $w_]} {
               return
            }
            if {[file isdir [$namer_ diskfile]]} {
               error_dialog "$file is a directory" $w_
               return
            }
         }

	 #  The WCS system will be saved as well. Try to match the
	 #  type against that of the image (a projection starting with
	 #  "digit" is taken to be a DSS map).
	 set proj [$image_ astget projection]
         set msg ""
	 if { [string match {digit*} $proj] } {
            catch { $image_ dump $file DSS } msg
	 } else {
            catch { $image_ dump $file FITS-WCS } msg
	 }
         if { $msg != "" } {
            info_dialog $msg
         }
      }
   }

   #  Get filename using fileselection dialog. This is created once and
   #  retains the current name and filters when repeatably accessed.
   protected method get_file_ {dir pattern types} {
      if { ! [winfo exists $fileselect_] } {
         set fileselect_ [FileSelect $w_.select -dir $dir -filter $pattern \
                             -transient 1 -withdraw 1 -filter_types $types]
         wm transient $fileselect_ [winfo toplevel $w_]
      } else {

         #  Now a transient of this window, not one that created it.
         wm transient $fileselect_ [winfo toplevel $w_]

         #  Also deiconfy and raise in case previous parent is iconised.
         wm deiconify $fileselect_
         raise $fileselect_
      }
      if {[$fileselect_ activate]} {
         return [$fileselect_ get]
      }
   }

   #  Set the cut levels.
   public method set_cut_levels {} {
      if {[$image_ isclear]} {
         warning_dialog "No image is currently loaded" $w_
         return
      }
      utilReUseWidget gaia::GaiaImageCut $w_.cut \
         -image $this \
         -transient 1 \
         -shorthelpwin $itk_option(-shorthelpwin) \
         -command [code $itk_component(info) updateValues]
   }

   #  Clear the current image display and remove an windows that
   #  access it (extend parent class version to also deal with
   #  temporary images).
   public method clear {} {

      #  If this window this previously displayed a temporary image
      #  then delete it.
      maybe_delete_
      delete_temporary_

      #  Really clear.
      skycat::SkyCatCtrl::clear
   }

   #  Load an image (internal version: use -file option/public
   #  variable), modified to deal with NDF image names.
   protected method load_fits_ {} {

      #  See if the image should be saved (image server types).
      check_save

      #  Parse filename.
      $namer_ configure -imagename $itk_option(-file)
      if { [$namer_ exists] } {
         set old_width [$image_ width]
         set old_height [$image_ height]
         busy {
            set center_ok_ 0
            if {[catch {$image_ config -file [$namer_ fullname 0] \
                           -component $itk_option(-component)} msg]} {

               #  If component isn't "data" then try that.
               if { $itk_option(-component) != "data" } {
                  if {[catch {$image_ config -file [$namer_ fullname 0] \
                                 -component "data"} msg]} {
                     error_dialog $msg $w_
                     clear
                  } else {
                     configure -component "data"
                  }
               } else {
                  error_dialog $msg $w_
                  clear
               }
            }
            set center_ok_ 1
         }
         #  Center if image has changed size.
         if { $old_width != [$image_ width] ||
              $old_height != [$image_ height] } {
            center
         }
         set w [$image_ dispwidth]
         set h [$image_ dispheight]
         set_scrollregion 0 0 $w $h

         #  Set the initial FITS HDU.
         if { $itk_option(-hdu) != 0 } {
            $image_ hdu $itk_option(-hdu)
         }

      } else {

         #  File cannot be open for display in GAIA. This could be
         #  because of a bad name (such as too many periods), so check
         #  for file existence to qualify the error message.
         if { [file exists [$namer_ ndfname]] } {
            error_dialog \
               "Cannot open the file [$namer_ ndfname] (bad filename format)" $w_
         } else {
            error_dialog "[$namer_ fullname] does not exist" $w_
         }
         set file ""
         clear
      }
      update_title
      apply_history $itk_option(-file)
      if { $itk_option(-with_colorramp) } {
         component colorramp update_colors
      }
   }

   # Check if the given filename is in the history catalog, and if so,
   # apply the cut levels and color settings for the file. Overriden
   # so that we can apply a default cut by usingh GaiaSearch instead of
   # SkySearch.
   public method apply_history {filename} {
      gaia::GaiaSearch::apply_history $this $filename $itk_option(-default_cut)
   }

   #  Check if any other instance of this class is displaying the
   #  current image (used when deciding to delete file, shared
   #  temporary files are retained until all instances are released).
   private method only_user_ {} {
      global ::tcl_version
      foreach inst [itcl::find objects "*" -isa "GaiaImageCtrl"] {
         if { $inst != $this } {
            if { $last_file_ == [$inst cget -file] } {
               return 0
            }
         }
      }
      return 1
   }

   #  See if user wants to change the temporary status of image
   #  before exit etc.
   private method maybe_delete_ {} {
      if { $itk_option(-temporary) && $last_file_ != {} } {

         #  Last displayed File is temporary, need to check that no
         #  other window has an interest in it.
         if { [only_user_] } {
            raise $w_
            regsub {\.gaia} $top_ {} clone
            set d [DialogWidget .#auto \
                      -title {Temporary image} \
                      -text "The image ($last_file_) that was displayed in \
                             window $itk_option(-appname): ($clone) is marked \
                             temporary.\n\Are you sure you want to delete it?"\
                      -buttons [list Yes No]]
            set answer [$d activate]
            if { $answer } {
               configure -temporary 0
               info_dialog "The image is stored in file $last_file_. \
                            You should rename this immediately."
            }
         }
      }
   }

   #  Delete the image if temporary. Done at exit, or when image is replaced.
   private method delete_temporary_ {} {
      if { $itk_option(-temporary) && $last_file_ != {} } {
         if { [only_user_] } {
            puts stderr "Information: deleting $last_file_"
            catch { file delete $last_file_ }
            set last_file_ {}
            configure -temporary 0
         }
      }
   }

   #  Display a popup window with information about this application,
   #  override to remove SkyCat splash logo.
   public method about {} {
      global ::about_skycat
      DialogWidget $w_.about \
         -messagewidth 6.5i \
         -justify center \
         -text $about_skycat
      $w_.about activate
   }

   #  Center the image in the canvas window. Override to switch off
   #  when attempting to load a new image (preserves scroll position,
   #  which is often what is really required).
   public method center {} {
      if { $center_ok_ } {
         rtd::RtdImage::center
      }
   }

   #  Select a region of the image and zoom to show as much of it as
   #  possible.
   public method zoomin {} {
      #  Record current zoom.
      save_zoom_

      #  Now start drawing out the region.
      $itk_component(draw) set_drawing_mode region [code $this zoom_to_region_]
   }

   #  Zoom to a displayed region.
   protected method zoom_to_region_ {canvas_id x0 y0 x1 y1} {
      set dw [$image_ dispwidth]
      set dh [$image_ dispheight]
      set cw [winfo width $canvas_]
      set ch [winfo height $canvas_]
      if {$cw != 1 && $dw && $dh} {

         #  Zoom image to fit the marked region.
         set rw [expr abs($x1-$x0)]
         set rh [expr abs($y1-$y0)]
         set tw [max $dw $cw]
         set th [max $dh $ch]
         set xinc [expr int(double($tw)/double($rw)) -1]
         set yinc [expr int(double($th)/double($rh)) -1]
         lassign [$image_ scale] xs ys
         incr xs $xinc
         incr ys $yinc
         set scale [max $itk_option(-min_scale) [min $xs $ys $itk_option(-max_scale)]]
         scale $scale $scale

         #  Now scroll to new position. Re-get bbox of item.
         lassign [$canvas_ bbox $canvas_id] x0 y0 x1 y1
         set x [expr ($x1+$x0)/2.0]
         set y [expr ($y1+$y0)/2.0]
         set dw [$image_ dispwidth]
         set dh [$image_ dispheight]
         $canvas_ xview moveto [expr (($x-$cw/2.0)/$dw)]
         $canvas_ yview moveto [expr (($y-$ch/2.0)/$dh)]
      }

      #  Remove region item.
      $itk_component(draw) delete_object $canvas_id
   }

   #  Reset zoom and scroll to value set by last zoomin.
   public method zoomout {} {
      if { [info exists lastzoom_] } {
         incr nlastzoom_ -1
         set nlastzoom_ [max 0 $nlastzoom_]
         scale $lastzoom_($nlastzoom_,Z) $lastzoom_($nlastzoom_,Z)
         $canvas_ xview moveto $lastzoom_($nlastzoom_,XS)
         $canvas_ yview moveto $lastzoom_($nlastzoom_,YS)
         maybe_center
         if { $nlastzoom_ != 0 } {
            unset lastzoom_($nlastzoom_,Z)
            unset lastzoom_($nlastzoom_,XS)
            unset lastzoom_($nlastzoom_,YS)
         }
      }
   }

   #  Save zoom and scroll for reseting.
   protected method save_zoom_ {} {
      lassign [$image_ scale] lastzoom_($nlastzoom_,Z) dummy
      lassign [$canvas_ xview] lastzoom_($nlastzoom_,XS) dummy
      lassign [$canvas_ yview] lastzoom_($nlastzoom_,YS) dummy
      incr nlastzoom_
   }

   #  Display a popup window listing the HDUs in the current image.
   public method display_fits_hdus {} {
      if { [$image_ isfits] } {
         utilReUseWidget gaia::GaiaHduChooser $w_.hdu \
            -image $this \
            -center 0 \
            -transient 0
      } else {
         utilReUseWidget gaia::GaiaNDFChooser $w_.ndfhdu \
            -image $this \
            -center 0 \
            -transient 0
      }
   }

   #  Update the popup window listing the HDUs in the current image
   #  Override to select between the FITS and NDF versions of this
   #  window and to allow for this window to be not shown (useful for
   #  remote control).
   public method update_fits_hdus {} {

      if { ! $itk_option(-show_hdu_chooser) } {

         # Only need control if created already by the user.
         if { ! [winfo exists $w_.ndfhdu] && ! [winfo exists $w_.hdu] } {
            return
         }
      }
      if { [$image_ isfits] } {

         #  Displaying FITS now, if NDF last time remove popup.
         if { [winfo exists $w_.ndfhdu] } {
            after idle [code destroy $w_.ndfhdu]
         }
         SkyCatCtrl::update_fits_hdus
      } else {

         #  Displaying NDF now, if FITS last time remove popup.
         if { [winfo exists $w_.hdu] } {
            after idle [code destroy $w_.hdu]
         }

         #  Get number of HDUs.
         if { [catch { set n [$image_ hdu count] } ] } {
            set n 0
         }

         #  Display and hide window automatically as needed.
         if { [winfo exists $w_.ndfhdu] } {
            if { $n > 1 } {
               after idle [code $w_.ndfhdu show_hdu_list]
            } else {
               after idle [code destroy $w_.ndfhdu]
            }
         } else {
            #  If there is more than one HDU, display the HDU select
            #  window.
            if { $n > 1 } {
                display_fits_hdus
            }
         }
      }
   }

   #  Override of SkyCatCtrl method as it trims all dimensions to w,
   #  which doesn't work for long images.
   #  This method is called when the user has selected an area of the
   #  image.  The results are in canvas coordinates, clipped to the
   #  area of the image.
   public method selected_area {id x0 y0 x1 y1} {
      global ::$w_.select_area

      # PWD: Make sure the coordinates don't go off the image
      if { "$x0" != "" } {
         $image_ convert coords $x0 $y0 canvas x0 y0 image
         $image_ convert coords $x1 $y1 canvas x1 y1 image
         set w [$image_ width]
         set x0 [expr min($w,max(1,$x0))]
         set x1 [expr min($w,max(1,$x1))]
         set h [$image_ height]
         set y0 [expr min($h,max(1,$y0))]
         set y1 [expr min($h,max(1,$y1))]
         $image_ convert coords $x0 $y0 image x0 y0 canvas
         $image_ convert coords $x1 $y1 image x1 y1 canvas
      }
      set $w_.select_area "$x0 $y0 $x1 $y1"
      after 0 [code $w_.draw delete_object $id]
   }

   #  Camera post command. This method is called whenever a new image
   #  has been received from the camera and displayed.  Update the
   #  widgets that need to display new values The frameid will be 0 for
   #  the main image and non-zero for a rapid frame. Override so that
   #  GAIA tools may be informed of these events.
   protected method camera_post_command {frameid} {
      RtdImage::camera_post_command $frameid
      if { $frameid == 0 } {
         if { $itk_option(-real_time_command) != {} } {
            eval $itk_option(-real_time_command)
         }
      }
   }

   #  Configuration options.
   #  ======================

   #  Fits image file to display. Added file change call back and
   #  initialisation of temporary status.
   itk_option define -file file File {} {
      if { $last_file_ != {} } {
         maybe_delete_
         delete_temporary_
      }
      if {"$itk_option(-file)" != ""} {

         #  This code makes it easier to center the image on startup.
         if {[winfo width $w_] <= 1} {
            after 0 [code $this load_fits_]
         } else {
            load_fits_
         }
         if { $itk_option(-file_change_cmd) != "" } {
            eval $itk_option(-file_change_cmd) [list $itk_option(-file)]
         }
      }
      set $itk_option(-temporary) 0
   }

   #  Commands for callbacks when the file is changed and when a file is
   #  opened using the file selection dialog. Changes happen whenever 
   #  -file is configured.
   itk_option define -file_change_cmd file_change_cmd File_Change_Cmd {}
   itk_option define -file_open_cmd file_open_cmd File_Open_Cmd {}

   #  Is image temporary. If set after image is displayed/configured
   #  then the associated file will be deleted when replaced or when this
   #  object is deleted.
   itk_option define -temporary teMpoRaRy TeMpoRaRy 0

   #  Names and extensions of known data types.
   itk_option define -file_types file_types File_Types \
      {{any *} {ndf *.sdf} {fits *.fit*}}

   #  Flag: if true, set bindings to scroll with the middle mouse
   #  button and make a depressed mouse button drag scroll the image.
   #  Note we use the mytag$this level tag for the cancel event as
   #  ButtonRelease-1 is used in other places.
   itk_option define -drag_scroll drag_scroll Drag_scroll 0 {
      if {$itk_option(-drag_scroll)} {
         bind $canvas_ <2> [code $canvas_ scan mark %x %y]
         bind $canvas_ <B2-Motion> [code $canvas_ scan dragto %x %y]
         set after_id_ {}
         bind mytag$this <ButtonRelease-1> [code $this cancelrepeat_]
         bind $canvas_ <B1-Leave> [code $this start_autoscan_ %x %y]
         bind $canvas_ <B1-Enter> [code $this cancelrepeat_]
      } else {
         bind $canvas_ <2> {}
         bind $canvas_ <B2-Motion> {}
         bind $canvas_ <B1-Leave> {}
         bind $canvas_ <B1-Enter> {}
      }
   }

   #  Flag: if true, display menus over graphic objects when selected with <3>
   itk_option define -show_object_menu show_object_menu Show_object_menu 1

   #  Canvas tag for AST graphics items. This is set to the global
   #  value and shouldn't normally be changed.
   itk_option define -ast_tag ast_tag Ast_Tag "ast_element"

   #  Command to re-draw the astrometry grid.
   itk_option define -grid_command grid_command Grid_Command {}

   #  Command to that can be used to get notification of a real-time event.
   itk_option define -real_time_command real_time_command Real_Time_Command {}

   #  Component of the NDF that is displayed.
   itk_option define -component component Component data

   #  Define the HDU initially displayed from each FITS file that is loaded.
   itk_option define -hdu hdu Hdu 0

   #  Whether to enable the UKIRT quick look parts of the interface.
   itk_option define -ukirt_ql ukirt_ql UKIRT_QL 0

   #  The application name as used in window titles (can be changed
   #  for UKIRT mods).
   itk_option define -appname appname AppName GAIA::Skycat

   #  Whether to display coordinates using extended precision. This
   #  displays at milli arc-second resolution.
   itk_option define -extended_precision extended_precision \
      Extended_Precision 0 {
         set_readout_precision_
      }

   #  Whether CAR projections should be interpreted as a linear mapping.
   itk_option define -linear_cartesian linear_cartesian Linear_Cartesian 1 {
      set_linear_cartesian_
   }

   #  How to merge FITS headers from primary and extension images.
   itk_option define -always_merge always_merge Always_Merge 0 {
      set_always_merge_
   }

   #  Default percentage cut applied when displaying images for the
   #  first time (or when not in history).
   itk_option define -default_cut default_cut Default_Cut 100.0

   #  Whether to attempt to show and control the HDU chooser. If 0
   #  then control is only attempted when the HDU already exists.
   itk_option define -show_hdu_chooser show_hdu_chooser Show_Hdu_Chooser 1

   #  Protected variables:
   #  ====================

   #  State of zoom.
   protected variable zoom_state_ 0

   #  Name of last file.
   protected variable last_file_ {}

   #  Name of toplevel window (recorded for times when not otherwise available).
   protected variable top_ {}

   #  Control use of center method by sub-classes.
   protected variable center_ok_ 1

   #  Id of after event (used to autoscroll image).
   protected variable after_id_ {}

   #  Name of image names handler.
   protected variable namer_ {}

   #  Last zoom factor stack.
   protected variable lastzoom_
   protected variable nlastzoom_ 0

   #  Common variables:
   #  =================

   #  Name of fileselection dialog window. Shared between all instances.
   common fileselect_ .imagectrlfs
}
