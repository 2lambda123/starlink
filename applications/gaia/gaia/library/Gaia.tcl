#+
#  Name:
#     Gaia.tcl

#  Purpose:
#     Defines a class for creating a GAIA window.

#  Type of Module:
#     [incr Tk] class

#  Description:
#     This is the class that creates the GAIA display tool.

#  Invocation:
#     Gaia name [configuration options]

#  Notes:
#     This will only run with the gaia_wish installed as part
#     of the GAIA package with a Starlink extended RTD.

#  Authors:
#     PWD: Peter Draper (STARLINK)
#     ALLAN: Allan Brighton (ESO)
#     {enter_new_authors_here}

#  Copyright:
#     Copyright (C) 1998-2000 Central Laboratory of the Research Councils

#  Inherits:
#     Methods and configuration options of SkyCat (and Rtd).

#  History:
#     24-SEP-1997 (PWD):
#        Original version
#     10-MAR-1998 (PWD):
#        Clone method now accepts a file name and additional options.
#     06-APR-1998 (PWD):
#        Added demo toolbox.
#     07-APR-1998 (PWD):
#        Moved temporary code to GaiaImageCtrl.
#     09-APR-1998 (PWD):
#        Changed clone method to not use TopLevelWidget::start.
#        This simplifies passing on new options and makes it
#        possible to wait for the window to appear (start blocks
#        with a tkwait which means that it is impossible to
#        work out when the clone is running).
#     10-JUL-1998 (PWD):
#        Added changes to support cloning of toolboxes.
#     10-SEP-1998 (PWD):
#        Added SExtractor toolbox.
#     10-MAR-1999 (PWD):
#        Attempt merge of Allan's GAIA plugin differences...
#     01-MAY-1999 (PWD):
#        Added contouring photometry toolbox.
#     28-MAY-1999 (PWD):
#        Added optimal photometry toolbox.
#     28-JUN-1999 (PWD):
#        Added ramp printing changes, hidden development code for now.
#     22-NOV-1999 (PWD):
#        Added focus_follows_mouse option to stop funny effects
#        with click-to-focus + autoraise under CDE.
#     06-DEC-1999 (PWD):
#        Added Norman Gray's ESP toolbox. Commented out as not ready.
#     05-MAY-2000 (PWD):
#        Changed so that CATLIB_CONFIG is used in preference to
#        all other configuration files when set (otherwise need
#        to delete ~/.skycat/skycat.cfg before can use another 
#        configuration file).
#     12-MAY-2000 (PWD):
#        Added positions toolbox.
#     {enter_changes_here}

#-

#  Version.
set gaia_version [gaia_version]

#  Make a local copy of about_skycat so we can divert bug reports.
set about_gaia "\

GAIA version $gaia_version

Copyright (C) 1997-2000 Central Laboratory of the Research Councils (U.K.)

Authors:
Peter W. Draper (P.W.Draper@durham.ac.uk)
Norman Gray (norman@astro.gla.ac.uk)

GAIA is derived from SkyCat version [skycat_version]
Copyright (C) 1996-1999 ESO - European Southern Observatory

Authors:
Allan Brighton (abrighto@eso.org)
Thomas Herlin (therlin@eso.org)
Miguel Albrecht (malbrech@eso.org)
Daniel Durand (durand@dao.nrc.ca)
Peter Biereichel (pbiereic@eso.org)

Bug reports and suggestions to: gaia@star.rl.ac.uk

"

set about_skycat ""

set gaia_usage {
Usage: gaia ?NDF/fitsFile? ?-option value ...?

Options:
 -cat <bool>              - Include ESO/Archive catalog extensions (default).
 -catalog <name>          - Open a window for the given catalog on startup.
 -colorramp_height <n>    - height of colorramp window (default: 12).
 -component <component>   - NDF component to display (one of: data, variance)
 -debug <bool>            - debug flag: run bg processes in fg.
 -default_cmap <cmap>     - default colormap.
 -default_itt <itt>       - default intensity transfer table.
 -file <file>             - image file to load.
 -float_panel <bool>      - put info panel in a popup window (default: 0).
 -focus_follows_mouse <bool> - entry focus follows mouse (default: 0)
 -max_scale <n>           - maximum scale for magnification menu (default: 20).
 -min_scale <n>           - minimum scale for magnification menu (default: -10).
 -panel_layout <layout>   - panel layout, one of: "saoimage", "reverse" or "default" .
 -pickobjectorient <v>    - orientation for pick object win: "horizontal", "vertical"
 -port <port>             - Listen for remote cmds on port (default: 0 = choose port).
 -remote <bool>           - Use existing skycat process, if available, with Tk send.
 -rtd <bool>              - Include ESO/VLT Real-Time Features.
 -scrollbars <bool>       - Display scrollbars (not displayed by default).
 -shm_data <bool>         - Put image data in sysV shared memory.
 -shm_header <bool>       - Put image header in sysV shared memory.
 -use_zoom_view <bool>    - Use a "view" of the image for the zoom window (default).
 -usexshm <bool>          - Use X shared mem, if available (default).
 -verbose <bool>          - Print diagnostic messages.
 -with_colorramp <bool>   - Display the color bar (default).
 -with_pan_window <bool>  - Display the pan window (default).
 -with_warp <bool>        - add bindings to move mouse ptr with arrow keys (default: 1).
 -with_zoom_window <bool> - Display the zoom window (default).
 -zoom_factor <n>         - zooming factor (default: 4).
}

itk::usual Gaia {}

#  Create a class for the application.
itcl::class gaia::Gaia {
   inherit ::skycat::SkyCat

   #  Constructor: create a toplevel window.
   constructor {args} {

      #  And start things going.
      configure -center 0

      #  Remove any options we're overriding and evaluate all
      #  options.
      itk_option remove rtd::Rtd::scrollbars
      itk_option remove rtd::Rtd::panel_layout
      eval itk_initialize $args

      #  Override about_skycat message.
      global about_skycat about_gaia
      set about_skycat $about_gaia
   }

   #  Destructor:
   destructor {
      #  Clear up the images list (this isn't done correctly in
      #  SkyCat, it uses $w_ instead of $image_).
      global ::skycat_images
      if {[info exists skycat_images]} {
         set tmp {}
         foreach w $skycat_images {
            if {[winfo exists $w] && "$w" != "$image_"} {
               lappend tmp $w
            }
         }
         set skycat_images $tmp
      }
   }

   #  Quit the application. Really.... Rtd doesn't have the exit.
   #  If being paranoid then ask for confirmation.
   public method quit {} {
      if { ! $itk_option(-quiet_exit) } { 
         if { ! [confirm_dialog \
                    "Are you sure you want to exit the application?" $w_]} {
            return
         }
      }
      
      #  Permission supplied so continue with exit.
      delete object $w_
      after idle exit
   }

   #  Called after the options have been evaluated. Add GAIA menu and
   #  extra items for other menus.
   public method init {} {

      #  If not first window then show splash screen (better than no feedback).
      if { $itk_option(-number) != 1 } {
         make_init_window 1
      }

      #  Do base class inits. Note stop creation of cat menu so we can
      #  override use of SkySearch class.
      set curval $itk_option(-cat)
      set itk_option(-cat) 0
      SkyCat::init
      set itk_option(-cat) $curval

      #  Get the clone number for this window.
      set clone_ $itk_option(-number)

      #  On openwindows iconwindows are displayed but do not
      #  redirect events, so add a fake deiconify binding.
      if {$itk_option(-disp_image_icon)} {
	 bind $itk_component(icon) <Double-1> "wm deiconify $w_"
      }

      #  Add the GAIA menubar.
      feedback "GAIA toolboxes..."
      if { $itk_option(-gaia) } {
         add_gaia_menu
      }

      #  Add the filters menu if required (not used at present).
      feedback "filters..."
      if { $itk_option(-filters) } {
         make_filters_menu
      }

      #  Add the catalogue menu.
      if {$itk_option(-cat)} {
         cat::AstroCat::add_catalog_menu \
            $w_ [code $image_] ::gaia::GaiaSearch $itk_option(-debug)
      }

      #  Add the SkyCat graphics features (really a plugin, but we're
      #  not using these yet).
      add_graphics_features $w_

      #  And the other changes to menus that we require.
      make_menu_changes

      #  Center image first time.
      after 0 [code $image_ center]
   }

   #  Set/get X defaults - can be overridden in subclass and/or
   #  in user's .Xdefaults file.
   protected method setXdefaults {} {
      util::setXdefaults
      SkyCat::setXdefaults
      gaia::setXdefaults
   }

   #  Display a window while the application is starting up, overriden
   #  to remove skycat logo and add plain option for showing
   #  minimalist stuff when creating a clone.
   protected method make_init_window {{plain 0}} {
      global ::about_skycat ::gaia_dir
      set w [util::TopLevelWidget $w_.init -center 1 -cursor watch]
      rtd_set_cmap $w
      wm title $w "GAIA::SkyCat loading..."
      wm withdraw $w_
      if { ! $plain } {
         set gaia_logo [image create pixmap -id gaia_logo]
         pack \
            [label $w.logo -image $gaia_logo -borderwidth 2 -relief groove] \
            -side top -padx 1m -pady 1m
         pack \
            [message $w.msg -text $about_skycat \
                -justify center \
                -borderwidth 2 -relief groove] \
            [ProgressBar $w.progress \
                -from 0 -to 10 -value 0 \
                -borderwidth 2 -relief groove] \
            -side top -fill x -padx 1m -pady 2m -expand 1
      } else {
         pack \
            [ProgressBar $w.progress \
                -from 0 -to 10 -value 0 \
                -borderwidth 2 -relief groove] \
            -side top -fill x -padx 1m -pady 2m -expand 1
      }
      tkwait visibility $w
   }

   #  Add help for GAIA and SkyCat.
   public method add_help_menu {} {
      global ::gaia_dir
      set m [add_help_button $gaia_dir/Gaia.hlp "On Window..." \
                {Display help on this window and general features}   ]

      add_menuitem $m command "About GAIA::SkyCat..." \
         {Display a window with information about this GAIA/SkyCat version} \
         -command [code $itk_component(image) about]

      add_menuitem $m command "SkyCat..." \
         {Display information about SkyCat in netscape (if netscape is available)} \
         -command [code $itk_component(image) send_to_netscape $itk_option(-help_url)]

      add_short_help $itk_component(menubar).help \
         {Help menu: display information about this application}
   }

   #  Create the rtd image widget with the extended RTD functionality
   #  needed by GAIA.
   public method make_rtdimage {} {
      set image_ $w_.image
      itk_component add image {
         GaiaImageCtrl $image_ \
            -file $itk_option(-file) \
            -file_change_cmd [code $this configure -file] \
            -file_types $itk_option(-file_types) \
            -usexshm $itk_option(-usexshm) \
            -verbose $itk_option(-verbose) \
            -shm_header $itk_option(-shm_header) \
            -shm_data $itk_option(-shm_data) \
            -min_colors $itk_option(-min_colors) \
            -max_colors $itk_option(-max_colors) \
            -drag_scroll $itk_option(-drag_scroll) \
            -scrollbars $itk_option(-scrollbars) \
            -subsample $itk_option(-subsample) \
            -use_zoom_view $itk_option(-use_zoom_view) \
            -zoom_view_propagate $itk_option(-zoom_view_propagate) \
            -with_zoom_window $itk_option(-with_zoom_window) \
            -dozoom $itk_option(-dozoom) \
            -with_pan_window $itk_option(-with_pan_window) \
            -zoom_factor $itk_option(-zoom_factor) \
            -zoom_width $itk_option(-zoom_width) \
            -zoom_height $itk_option(-zoom_height) \
            -pan_width $itk_option(-pan_width) \
            -pan_height $itk_option(-pan_height) \
            -colorramp_height $itk_option(-colorramp_height) \
            -default_cmap $itk_option(-default_cmap) \
            -default_itt $itk_option(-default_itt) \
            -with_colorramp $itk_option(-with_colorramp) \
            -feedback [code $this feedback] \
            -port $itk_option(-port) \
            -shorthelpwin $this \
            -debug $itk_option(-debug) \
            -float_panel $itk_option(-float_panel) \
            -newimagecmd [code $this cleared] \
            -temporary $itk_option(-temporary) \
            -ast_tag $ast_tag_ \
            -grid_command [code $this redraw_specials_] \
            -with_warp 1 \
            -panel_layout $itk_option(-panel_layout) \
            -regioncommand [code $this select_region] \
            -component $itk_option(-component) \
            -min_scale $itk_option(-min_scale) \
            -max_scale $itk_option(-max_scale) \
            -pickobjectorient $itk_option(-pickobjectorient)
      }

      #  Keep a list of SkyCat/GAIA instances.
      global ::skycat_images
      lappend skycat_images $itk_component(image)
   }
   
   #  Delete a this object.
   public method delete_window {} {
      delete object $w_
   }

   #  Make changes to Skycat menus that we require.
   public method make_menu_changes {} {

      #  Note bindings are not really needed, unless working with
      #  plugin (GAIA version of TopLevelWidget is fixed).

      #  File menu. This needs the bindings changing to work with the
      #  keyboard shortcuts and the "save region" removing.
      set m [get_menu File]
      bind $w_  <Control-o> [code $image_ open]
      bind $w_  <Control-v> [code $image_ reopen]
      bind $w_  <Control-s> [code $image_ save_as]
      catch {$m delete "Save region as..."}
      
      #  Close also needs the command changing to delete the object.
      $m entryconfigure "Close" \
	 -label "Close Window" \
	 -accelerator {Control-d} \
	 -command [code $this delete_window]
      bind $w_  <Control-d> [code $this delete_window]
      add_menu_short_help $m "Close Window" \
         {Close this window, exit application if last}
      add_menu_short_help $m "New Window" \
         {Create a new main window}
      $m entryconfigure "Print..." -accelerator {Control-p}
      bind $w_  <Control-p> [code $image_ print]
      bind $w_  <Control-n> [code $this clone]
      bind $w_  <Control-q> [code $this quit]

      #  View menu. Add new items, rename "Cuts..." to Slice, add
      #  bindings for accelerators.
      set m [get_menu View]
      bind $w_  <Control-c> [code $image_ set_colors]
      bind $w_  <Control-l> [code $image_ component info cut_level_dialog]
      $m entryconfigure "Cuts..." -label "Slice..." -accelerator {Control-a}
      bind $w_  <Control-a> [code $image_ spectrum 0]
      $m entryconfigure "Pick Object..." -accelerator {Control-i}
      bind $w_  <Control-i> [code $image_ pick_dialog]
      bind $w_  <Control-f> [code $image_ view_fits_header]

      #  HDUs are for NDFs too.
      $m entryconfigure "Select FITS HDU..." \
         -label "Select FITS HDU/NDF..."
      add_menu_short_help $m "Select FITS HDU/NDF..." \
         {Display the available FITS HDUs and NDFs}

      #  Change background and blank pixel colours.
      set index [$m index "Magnification"]
      incr index
      insert_menuitem $m $index cascade "Blank pixel color" \
         {Change the colour of blank pixels} \
         -menu [menu $m.blank]
      foreach colour $colours_ {
         $m.blank add radiobutton \
            -background $colour \
            -variable $w_.blank \
            -value $colour \
            -label {    } \
            -command [code $this set_blankcolour_ $colour]
      }

      insert_menuitem $m $index cascade "Image background" \
         {Change the background colour of the main window} \
         -menu [menu $m.back]
      foreach colour $colours_ {
         $m.back add radiobutton \
            -background $colour \
            -variable $w_.back \
            -value $colour \
            -label {    } \
            -command [code $this set_background_ $colour]
      }
   }

   #  Add a menubutton with the GAIA options.
   public method add_gaia_menu {} {

      set m [add_menubutton Image-Analysis]
      configure_menubutton Image-Analysis -underline 0
      add_short_help $itk_component(menubar).image-analysis \
         {Image analysis menu: do astronomy with image}

      add_menuitem $m cascade "Aperture photometry" \
         {Perform aperture photometry on image} \
         -menu [menu $m.photom]

      add_menuitem $m.photom command "Results in magnitudes..." \
         {Display aperture photometry toolbox (results in magnitudes)} \
         -command [code $this make_toolbox magphotom] \
         -accelerator {Control-m}
      bind $w_ <Control-m> [code $this make_toolbox magphotom]

      add_menuitem $m.photom command "Results in data counts..." \
         {Display aperture photometry toolbox (results in image data units)} \
         -command [code $this make_toolbox countphotom] \
         -accelerator {Control-g}
      bind $w_ <Control-g> [code $this make_toolbox countphotom]

      add_menuitem $m cascade "Optimal photometry" \
         {Perform optimal photometry on image} \
         -menu [menu $m.optphotom]

      add_menuitem $m.optphotom command "Results in magnitudes..." \
         {Display optimal photometry toolbox (results in magnitudes)} \
         -command [code $this make_toolbox magoptphotom]

      add_menuitem $m.optphotom command "Results in data counts..." \
         {Display optimal photometry toolbox (results in image data units)} \
         -command [code $this make_toolbox countoptphotom]

      add_menuitem $m command "Image regions..." \
         {Perform operations on regions of image} \
         -command [code $this make_toolbox ard] \
         -accelerator {Control-r}
      bind $w_ <Control-r> [code $this make_toolbox ard]

      add_menuitem $m command "Patch image..." \
         {Realistically replace parts of image} \
         -command [code $this make_toolbox patch] \
         -accelerator {Control-u}
      bind $w_ <Control-u> [code $this make_toolbox patch]

      add_menuitem $m command "Blink images..." \
         {Blink compare all the displayed images} \
         -command [code $this make_toolbox blink] \
         -accelerator {Control-b}
      bind $w_ <Control-b> [code $this make_toolbox blink]

      add_menuitem $m command "Overlay axes grid..." \
         {Draw axes over image } \
         -command [code $this make_toolbox astgrid] \
         -accelerator {Control-t}
      bind $w_ <Control-t> [code $this make_toolbox astgrid]

      add_menuitem $m cascade "Astrometry calibration" \
         {Create and manipulate astrometry information} \
         -menu [menu $m.astrom]

      add_menuitem $m.astrom command "Fit to star positions..." \
         {Create a WCS for image using reference positions} \
         -command [code $this make_toolbox astreference] \
         -accelerator {Control-k}
      bind $w_ <Control-k> [code $this make_toolbox astreference]

      add_menuitem $m.astrom command "Tweak an existing calibration..." \
         {Use linear transforms to refine the WCS associated with this image} \
         -command [code $this make_toolbox astrefine] \
         -accelerator {Control-z}
      bind $w_ <Control-z> [code $this make_toolbox astrefine]

      add_menuitem $m.astrom command "Copy from another image..." \
         {Copy a WCS from another image} \
         -command [code $this make_toolbox astcopy] \
         -accelerator {Control-y}
      bind $w_ <Control-y> [code $this make_toolbox astcopy]

      add_menuitem $m.astrom command "Type in known calibration..." \
         {Define a WCS for image using FITS-like description} \
         -command [code $this make_toolbox astdefine] \
         -accelerator {Control-w}
      bind $w_ <Control-w> [code $this make_toolbox astdefine]

      add_menuitem $m command "Celestial coordinates...  " \
         {Change the image celestial coordinate system} \
	 -command [code $this make_toolbox astsystem] \
	 -accelerator {Control-e}
      bind $w_ <Control-e> [code $this make_toolbox astsystem]

      add_menuitem $m command "Object detection...  " \
         {Automatically detect and parameterize objects} \
	 -command [code $this make_toolbox sextractor] \
	 -accelerator {Control-j}
      bind $w_ <Control-j> [code $this make_toolbox sextractor]

      add_menuitem $m command "Contouring...  " \
         {Contour this or another image over the displayed image...} \
	 -command [code $this make_toolbox contour] \
	 -accelerator {Control-h}
      bind $w_ <Control-h> [code $this make_toolbox contour]

      add_menuitem $m command "Surface photometry...  " \
         {Perform interactive galaxy surface photometry} \
         -command [code $this make_toolbox esp] \

      add_menuitem $m command "Select positions...  " \
         {Select or identify object positions and properties} \
         -command [code $this make_toolbox positions] \

      if { $itk_option(-demo_mode) } {
	 add_menuitem $m command "Demonstration mode..." \
	       {See a demonstration of GAIA (needs an empty directory)} \
	       -command [code $this make_toolbox demo]
      }
      if { $itk_option(-ramp_print) && $itk_option(-with_colorramp) } { 
	 add_menuitem $m command "Print color ramp..." \
	    {Print a labelled copy of color ramp to postscript} \
	    -command [code $this print_ramp_]
      }
   }

   #  Saving graphics with the image doesn't work so disable it.
   protected method add_graphics_save_menu_item {} {
   }

   #  Make or clone a GAIA toolbox.
   public method make_toolbox {type {clone 0} } {
      #  Do nothing if no image is displayed.
      if { [$image_ cget -file] != "" || $type == "demo" } {
         set basename $type
         if { $clone } {
            #  Request to create a clone (i.e. another) toolbox. Make
            #  extended name for this.
            set basename "$basename[incr tool_clones_]"
         }

         #  If the window exists then just raise it.
         if { [info exists itk_component($basename) ] &&
              [winfo exists $itk_component($basename) ] } {
            wm deiconify $itk_component($basename)
            raise $itk_component($basename)
         } else {
            busy {
               make_${type}_toolbox $basename $clone
            }
         }
      }
   }

   #  Make a magnitude aperture photometry toolbox.
   public method make_magphotom_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaApPhotom $w_.\#auto 1 \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox magphotom 1]
      }
   }

   #  Make a counts aperture photometry toolbox.
   public method make_countphotom_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaApPhotom $w_.\#auto 0 \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox countphotom 1]
      }
   }

   #  Make a magnitude optimal photometry toolbox.
   public method make_magoptphotom_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaOptPhotom $w_.\#auto 1 \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox magoptphotom 1]
      }
   }

   #  Make a counts optimal photometry toolbox.
   public method make_countoptphotom_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaOptPhotom $w_.\#auto 0 \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox countoptphotom 1]
      }
   }

   #  Make an ARD toolbox.
   public method make_ard_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaArd $w_.\#auto \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image] \
            -gaia $w_ \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox ard 1]
      }
   }

   #  Make an AST grid toolbox.
   public method make_astgrid_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaAstGrid $w_.\#auto \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -ast_tag $ast_tag_ \
            -clone_cmd [code $this make_toolbox astgrid 1] \
            -really_die $cloned
      }
   }

   #  Make an AST reference WCS toolbox.
   public method make_astreference_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaAstReference $w_.\#auto \
            -image $image_ \
            -rtdimage [$image_ get_image] \
            -canvas [$image_ get_canvas] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -notify_cmd [code $this redraw_specials_ 1] \
            -clone_cmd [code $this make_toolbox astreference 1] \
            -really_die $cloned
      }
   }

   #  Make an AST define WCS toolbox.
   public method make_astdefine_toolbox {name {cloned 0}} {
      itk_component add $name {
         StarAstDefine $w_.\#auto \
            -rtdimage [$image_ get_image] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -notify_cmd [code $this redraw_specials_ 1] \
            -clone_cmd [code $this make_toolbox astdefine 1] \
            -really_die $cloned
      }
   }

   #  Make an AST copy WCS toolbox.
   public method make_astcopy_toolbox {name {cloned 0}} {
      itk_component add $name {
         StarAstCopy $w_.\#auto \
            -rtdimage [$image_ get_image] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -filter_types $itk_option(-file_types) \
            -notify_cmd [code $this redraw_specials_ 1] \
            -clone_cmd [code $this make_toolbox astcopy 1] \
            -really_die $cloned
      }
   }

   #  Make an AST refine WCS toolbox or make it visible.
   public method make_astrefine_toolbox {name {cloned 0}} {
      itk_component add $name {
         StarAstRefine $w_.\#auto \
            -image $image_ \
            -rtdimage [$image_ get_image] \
            -canvas [$image_ get_canvas] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -notify_cmd [code $this redraw_specials_ 1] \
            -clone_cmd [code $this make_toolbox astrefine 1] \
            -really_die $cloned
      }
   }

   #  Make an AST set celestial coordinates system toolbox.
   public method make_astsystem_toolbox {name {cloned 0}} {
      itk_component add $name {
         StarAstSystem $w_.\#auto \
            -rtdimage [$image_ get_image] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -notify_cmd [code $this redraw_specials_ 1] \
            -clone_cmd [code $this make_toolbox astsystem 1] \
            -really_die $cloned
      }
   }


   #  Make a patch toolbox.
   public method make_patch_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaPatch $w_.\#auto \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox patch 1]
      }
   }

   #  Blink any displayed images.
   public method make_blink_toolbox {name {cloned 0}} {
      if { [llength [SkyCat::get_skycat_images] ] > 1 } {
         itk_component add $name {
            StarBlink $w_.\#auto \
               -transient $itk_option(-transient_tools) \
               -number $clone_ \
               -clone_cmd [code $this make_toolbox blink 1]
         }
      } else {
         error_dialog "Not enough images are displayed to blink."
      }
   }

   #  Make a SExtractor toolbox.
   public method make_sextractor_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaSextractor $w_.\#auto \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image]\
            -image $image_ \
            -filter_types $itk_option(-file_types) \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox sextractor 1] \
            -really_die $cloned
      }
   }

   #  Make a contour toolbox.
   public method make_contour_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaContour $w_.\#auto \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image]\
            -ast_tag ast_tag_ \
            -image $image_ \
            -filter_types $itk_option(-file_types) \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox contour 1] \
            -really_die $cloned
      }
   }

   #  Make an ESP toolbox.
   public method make_esp_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaEsp $w_.\#auto \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -rtdimage [$image_ get_image]\
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox esp 1] \
            -really_die $cloned
      }
   }

   #  Make positions toolbox.
   public method make_positions_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaPositions $w_.\#auto \
            -image $image_ \
            -rtdimage [$image_ get_image] \
            -canvas [$image_ get_canvas] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox astreference 1] \
            -really_die $cloned
      }
   }

   #  Start the demonstration toolbox.
   public method make_demo_toolbox {name {cloned 0}} {
      itk_component add $name {
         GaiaDemo $w_.\#auto \
            -gaiamain $w_ \
            -rtdimage [$image_ get_image] \
            -gaiactrl $image_ \
            -canvasdraw [$image_ component draw] \
            -canvas [$image_ get_canvas] \
            -transient $itk_option(-transient_tools) \
            -number $clone_ \
            -clone_cmd [code $this make_toolbox demo 1] \
            -really_die $cloned
      }
   }

   #  When image is flipped etc. we may want to redraw some items that
   #  are too expensive to flip via Tcl commands.  If auto is set 1
   #  then the grid is only redrawn if automatic redraws are on.
   protected method redraw_specials_ { {auto 0} } {
      if { [info exists itk_component(astgrid) ] &&
           [winfo exists $itk_component(astgrid) ] } {

         #  Check that window isn't withdrawn
         if { [wm state $itk_component(astgrid)] != "withdrawn" } {
            $itk_component(astgrid) draw_grid 0 $auto
         }
      }

      if { [info exists itk_component(contour) ] &&
           [winfo exists $itk_component(contour) ] } {

         #  Check that window isn't withdrawn
         if { [wm state $itk_component(contour)] != "withdrawn" } {
            $itk_component(contour) redraw 0
         }
      }

      if { [info exists itk_component(positions) ] &&
           [winfo exists $itk_component(positions) ] } {
         $itk_component(positions) redraw
      }
   }

   #  Image has been cleared so reset any toolboxes that require it
   #  (note most just have canvas objects which are deleted when
   #  a new image is drawn and do not require any other information).
   public method cleared {} {
      if { [info exists itk_component(astgrid) ] } {
         if { [winfo exists $itk_component(astgrid) ] } {
            $itk_component(astgrid) remove_grid
         }
      }
      if { [info exists itk_component(astsystem) ] } {
         if { [winfo exists $itk_component(astsystem) ] } {
            $itk_component(astsystem) image_changed
         }
      }
      if { [info exists itk_component(contour) ] } {
         if { [winfo exists $itk_component(contour) ] } {
            $itk_component(contour) remove_contours
         }
      }
   }

   #  Make the "Filters" menu.
   public method make_filters_menu {} {
      StarAppFilter \#auto $w_
   }

   #  Open a new file without a filebrowser, or return the name of the
   #  displayed file. Always use an absolute name (for matching etc.)
   public method open {args} {
      if { "$args" != "" } {
         set imagename [lindex $args 0]
	 set namer [GaiaImageName \#auto -imagename $imagename]
	 if { [$namer exists] } { 
	    $namer absolute
	    configure -file [$namer fullname]

            #  Make sure image exists before using it.
            $image_ configure -file [$namer fullname]

            #  Lower the image on the canvas so that any existing
            #  graphics are revealed.
            [$image_ get_canvas] lower [$image_ get_image]
         } else {
            error_dialog "There is no file named '$imagename'" $w_
         }
	 delete object $namer
      } else {
         return $itk_option(-file)
      }
   }

   #  Make a new main window with the given name, or the next in
   #  sequence name. This version can stop the TopLevelWidget::start
   #  command from blocking (stopping the possibility of remotely
   #  determining when the clone has been created). It also provides
   #  the ability to specify the file name directly (thus replacing
   #  the command-line version) and to gain access to an existing
   #  clone (by number). Used for demo/remote control.
   public method noblock_clone {number {file ""} {block 0} args} {
      global ::argv ::argc ::gaia_usage

      #  Append any new args.
      set argv [concat $argv $args]
      set argc [llength $argv]

      #  If given the file replaces the one in the command-line args or
      #  is added to the list.
      if { $file != "" } {
	 replace_image_ $file
      }

      #  If a clone number was given construct the related name.
      if { $number != "" } { 
	 set name ".gaia$number"
      } else {
	 set name ""
      }

      #  If named window already exists, just configure file and return.
      if { [winfo exists $name] } {
          if { $file != "" } {
              $name open $file
          }
          if { $args != "" } {
              eval $name configure $args
          }
          return $name
      }

      #  If name is "" then create a new name.
      if { $name == "" } {
	 set name "$prefix_[expr $clone_cnt_+1]"
	 while { [winfo exists $name] } {
	    set name "$prefix_[incr $clone_cnt_]"
	 }
      }

      #  Start a new clone, block the tkwait if asked.
      if { ! $block } { 
	 rename ::tkwait ::real_tkwait
	 rename ::false_tkwait ::tkwait
      }
      util::TopLevelWidget::start gaia::Gaia "-file" "$gaia_usage" "$name"

      #  Actually we only arrive here if not blocking, except when
      #  application is exiting, so clone number is wrong.
      if { ! $block } { 
	 rename ::tkwait ::false_tkwait
	 rename ::real_tkwait ::tkwait
	 tkwait visibility $name
	 if { $number != {} } { 

	    #  Number given, so update the title and make sure next
	    #  clone doesn't try to have same name.
	    $name configure -number $number
	    $name.image update_title
	    catch {set clone_cnt_ [max $clone_cnt_ $number]}
	 }
      }
      return $name
   }

   #  Make a window clone, but display a new image.
   public method newimage_clone {filename args} {
      global ::argv ::argc ::gaia_usage
      if { $args != {} } {
         set argv [concat $argv $args]
         set argc [llength $argv]
      }

      #  Add the image name to replace the existing one.
      replace_image_ $filename

      #  And create the new clone.
      after 0 [code util::TopLevelWidget::start gaia::Gaia "-file" "$gaia_usage"]
      return $prefix_[expr $clone_cnt_+1]
   }

   #  Standard clone method. Make a new main window, named either the
   #  next in sequence or using a given name.
   public method clone {args} {
      global ::argv ::argc ::gaia_usage
      if { $args != {} } {
         set argv [concat $argv $args]
         set argc [llength $argv]
      }

      #  Use the -noop option to avoid reloading the main image (part
      #  of $argv list).
      after 0 [code util::TopLevelWidget::start gaia::Gaia "-noop" "$gaia_usage"]
      return $prefix_[expr $clone_cnt_+1]
   }

   #  Replace the existing image in the default args lists.
   protected method replace_image_ {filename} {
      global ::argv ::argc
      set index [lsearch -exact $argv "-file"]
      if { $index == -1 } {

	 #  Filename may be unpaired with -file, so look for it.
	 set newargv ""
	 set seenfile 0
	 for {set i 0} {$i < $argc} {incr i} {
	    set opt [lindex $argv $i]
	    if {"[string index $opt 0]" == "-" && "$opt" != "-"} {
	       set arg [lindex $argv [incr i]]
	    } else {
	       set seenfile 1
	       set arg "$filename"
	       set opt "-file"
	    }
	    lappend newargv $opt $arg
	 }
	 if { ! $seenfile } { 

	    #  No -file and no unpaired options.
	    lappend newargv "-file" "$filename"
	 }
	 set argv $newargv
	 set argc [llength $argv]
      } else {

	 #  Has "-file" so just replace associated value.
	 incr index
	 set argv [lreplace $argv $index $index $filename]
      }
   }

   #  Return the name of the GaiaImageCtrl so that other external
   #  routines may talk to it.
   public method get_image {} { return $image_ }

   #  Set the colour of the main canvas background.
   protected method set_background_ {colour} {
      [$image_ get_canvas] configure -background $colour
   }

   #  Set the colour of the any blank pixels.
   protected method set_blankcolour_ {colour} {
      [$image_ get_image] blankcolor $colour
   }

   #  Start a process to load the ESO config file. Need this in case
   #  local version becomes horribly out of date.
   public method load_eso_config {} {

      #  Attempt to get the default config file using a batch process
      #  to avoid nasty blocking.
      Batch $w_.bg_proc -command [code $this loaded_eso_config_]
      blt::busy hold $w_
      $w_.bg_proc bg_eval [code $this get_eso_config_]

      #  Query times out after 10 seconds.
      set after_id_ [after 10000 [code $this loaded_eso_config_ 1 "timed out"]]
   }

   #  Start the application with the above class as the main window.
   #  This proc is called from tkAppInit.c when we are running the single
   #  binary version.
   #
   #  Note that the binary version doesn't need to set auto_path or look for
   #  Tcl sources or colormaps at run-time, since they are already loaded in
   #  the binary.
   public proc startGaia {} {
      global ::rtd_library ::skycat_library ::gaia_usage ::tk_strictMotif \
         ::argv0 ::argv ::argc ::env
      if {! [info exists rtd_library]} {
         set rtd_library .
      }

      #  Check for a plugin or binary installation, third option is
      #  GAIA running in a proper Starlink distribution. Need to
      #  detect this and act appropriately (environment is established
      #  by script that creates this application).
      if { ! [ info exists env(NATIVE_GAIA)] } {
         set native 0
      } else {
         set native 1
      }

      #  Where to look for catalog config file:
      #    use CATLIB_CONFIG, if set (assume this is deliberate)
      #    next use ~/.skycat/skycat.cfg if it exists (this contains
      #    the user's preferences), finally use $SKYCAT_CONFIG if set
      #    (note native implimentation ignores SKYCAT_CONFIG as this 
      #    may be set by CURSA, which is bad).
      if { ! [info exists env(CATLIB_CONFIG)] } {

         #  Make sure ~/.skycat exists.
         set config_file [utilGetConfigFilename .skycat skycat.cfg]
         if {[file exists $config_file]} {
            set env(CATLIB_CONFIG) "file:$config_file"
         } elseif {[info exists env(SKYCAT_CONFIG)]  && ! $native} {
            set env(CATLIB_CONFIG) $env(SKYCAT_CONFIG)
         }
      }
      if { ! $native } {
         setup_starlink_env [file dirname [info nameofexecutable]]
      }

      #  Set some application options
      tk appname GAIA
      set tk_strictMotif 1
      set tcl_precision 17

      #  Insert some default options
      set argv [linsert $argv 0 -disp_image_icon 1]
      set argc [llength $argv]

      #  Start the application
      util::TopLevelWidget::start gaia::Gaia "-file" "$gaia_usage"
   }

   #  Set up the STARLINK environment based on the given
   #  directory. PLUGIN SPECIFIC.
   public proc setup_starlink_env {dir} {
      global ::tcl_version ::env ::argv ::argc ::gaia_dir

      # we need this for the local atclsh binary for running external tcl commands
      if {[file isdirectory $dir/tcl$tcl_version]} {
         set env(TCL_LIBRARY) $dir/tcl$tcl_version
      }

      if {! [file isdirectory $gaia_dir]} {
         set $gaia_library $gaia_dir
      }

      # Check if using local Starlink binaries
      if {[file exists $dir/autophotom]} {
         set env(PHOTOM_DIR) $dir
      }

      if {[file exists $dir/ardmask]} {
         set env(KAPPA_DIR) $dir
      }

      # use given dir for STARLINK, unless another value is defined
      if {! [info exists env(STARLINK)]} {
         set env(STARLINK) $dir
      } else {
         set dir $env(STARLINK)
      }

      if {![info exists env(PHOTOM_DIR)] && [file exists $dir/bin/photom/autophotom]} {
         set env(PHOTOM_DIR) $dir/bin/photom
      }
      if {![info exists env(KAPPA_DIR)] && [file exists $dir/bin/kappa/ardmask]} {
         set env(KAPPA_DIR) $dir/bin/kappa
      }
      # alternate dirs
      if {[file exists $dir/bin/gaiapack/ardmask]} {
         set env(KAPPA_DIR) $dir/bin/gaiapack
      }
      if {[file exists $dir/bin/gaiapack/autophotom]} {
         set env(PHOTOM_DIR) $dir/bin/gaiapack
      }
      if {![info exists env(CONVERT_DIR)] && [file exists $dir/bin/convert/ndf2fits]} {
         set env(CONVERT_DIR) $dir/bin/convert
         set env(CONVERT_HELP) $dir/bin/convert
      }

      # add the plugin bin dir to the path
      set env(PATH) "${dir}/bin:$env(PATH)"

      # See if the user already sourced convert.csh
      if {! [info exists env(NDF_FORMATS_IN)] && [info exists env(CONVERT_DIR)]} {
         # Define environment variables (normally done in convert.csh)
         setup_convert
      }
      # Set up CONVERT to work for .fits file as well as .fit.
      if {[info exists env(NDF_FORMATS_IN)]} {
         append env(NDF_FORMATS_IN) ",FITS(.fits),FITS(.fit)"
         append env(NDF_FORMATS_OUT) ",FITS(.fits),FITS(.fit)"
      }

      #  Extract the known file types and set these up as defaults. These
      #  are entered as if command-line arguments so that they propagate
      #  to clone windows.
      set file_types {{any *} {NDF(.sdf) *.sdf} {FIT(.fit) *.fit} {FITS(fits) *.fits}}
      if { [info exists env(NDF_FORMATS_IN)] } {
         set new_types [split $env(NDF_FORMATS_IN) ","]
         foreach pair $new_types {
            regexp {([^\(]*).([^\)]*)} $pair dummy name type
            if { $name != "NDF" && $type != ".fits" && $type != ".fit" } {
               lappend file_types [list $name\($type\) *${type}]
            }
         }
      }
      lappend argv "-file_types"
      lappend argv $file_types
      incr argc 2

      # need this for library/StarApp.tcl  to find adamtask.tcl
      if {! [info exists env(TCLADAM_DIR)]} {
         set env(TCLADAM_DIR) $gaia_dir/demos
      }
      # XXX should use ~/adam/gaia-[pid] here, but not sure about cleanup...
      if {! [info exists env(ADAM_USER)]} {
         set env(ADAM_USER) $env(HOME)/adam/gaia
      }
      if {[file isdirectory $env(ADAM_USER)]} {
         exec rm -rf $env(ADAM_USER)
      }
   }

   #  Retrieve the ESO config file, returning its content as the result.
   protected method get_eso_config_ {} {
      return [[$image_ get_image] urlget $itk_option(-eso_config_file)]
   }

   #  Attempt to load ESO config file is completed. If succeeded in
   #  contact them overwrite the local ~/.skycat/skycat.cfg file and
   #  force a local reload.
   protected method loaded_eso_config_ {status msg} {
      blt::busy release $w_
      if { $status } {
         error_dialog "Failed to get ESO config file: $msg"
      } else {

         #  msg is file contents, need to make this the local file.
         global ::env
         set file $env(HOME)/.skycat/skycat.cfg
         if {[file exists $file]} {
            if {[catch {::file rename -force $file $file.BAK} error]} {
               error_dialog $error
               return
            }
         }
         set fd [::open $file w]
         puts $fd $msg
         ::close $fd

         #  Finally force this to be loaded.
         AstroCat::reload_config_file $w_
      }
      delete object $w_.bg_proc
      if { $after_id_ != {} } {
         catch [after cancel $after_id_]
         set after_id_ {}
      }
   }

   #  Print a copy of the colorramp to postscript.
   private method print_ramp_ {} {
      utilReUseWidget gaia::GaiaRampPrint $w_.printramp \
	 -image $image_.colorramp.image \
	 -show_footer 0 \
	 -whole_canvas 1 \
	 -transient 1 \
	 -mainimage [$image_ get_image] \
	 -maincanvas [$image_ get_canvas]
   }

   # -- public variables (also program options) --

   #  Mark displayed image as temporary, these are deleted on exit
   #  (after a request to save it is made), try to disable options
   #  database configuring this.
   itk_option define -temporary teMpoRaRy TeMpoRaRy 0 {
      if { [info exists image_] } {
         if { [winfo exists $image_] } {
            $image_ configure -temporary $itk_option(-temporary)
         }
      }
   }

   #  Whether toolboxes are transient (iconize with main window).
   itk_option define -transient_tools transient_tools Transient_Tools 0

   #  The known file types.
   itk_option define -file_types file_types File_Types {{any *}}

   #  Whether to reveal the GAIA menu or not.
   itk_option define -gaia gaia Gaia 1

   #  Whether to reveal the filters menu or not.
   itk_option define -filters filters Filters 0

   #  Redefine scrollbars to be true.
   itk_option define -scrollbars scrollbars ScrollBars 1

   #  The NDF component to display.
   itk_option define -component component Component data

   #  Switch on demo mode (this makes an additional class available
   #  for running GAIA and making it show off/test some of its
   #  capabilities).
   itk_option define -demo_mode demo_mode Demo_Mode 1

   #  Name of ESO catalogue config file.
   itk_option define -eso_config_file eso_config_file Eso_config_file \
      {http://archive.eso.org/skycat/skycat2.0.cfg}

   #  Redefine panel_layout to GAIA default
   itk_option define -panel_layout panel_layout Panel_layout reverse

   #  Show the print colorramp code.
   itk_option define -ramp_print ramp_print Ramp_Print 0
   
   #  Set focus following policy (can only set once, then stuck with it).
   itk_option define -focus_follows_mouse focus_follows_mouse \
      Focus_Follows_Mouse 0 {
         if { $itk_option(-focus_follows_mouse) } {
            tk_focusFollowsMouse
         }
      }

   #  Option to inhibit the display of the exit application dialog.
   #  UKIRT requested this for 14,000 ft anoxia cases!
   itk_option define -quiet_exit quiet_exit Quiet_Exit 1

   # -- Protected variables --

   #  Clone number of this window.
   protected variable clone_ 0

   #  Initialization progress count.
   protected variable sofar_ 0

   #  Initialization windows.
   protected variable Init_
   protected variable Progress_

   #  Colours of the main background.
   protected variable colours_ {
      white
      grey90 grey80 grey70 grey60 grey50 grey40 grey30 grey20 grey10
      black
      red green blue cyan magenta yellow
   }

   #  Id of after command for reading ESO config file.
   protected variable after_id_ {}

   #  Number for creating toolbox clones.
   protected variable tool_clones_ 0

   #  Unique identifier for items to be ignored when drawn on canvas.
   protected variable ast_tag_ ast_element

   # -- Common variables --

   # maximum clone number so far
   common clone_max_ 0

   # prefix to use to create new main windows.
   common prefix_ ".gaia"
}

#  Procedure to stop tkwait from working...
proc false_tkwait {args} {
}

#  XXX redefine the body of AstroCat::new_catalog, as this contains a
#  reference to an astrocat instance that is never deleted (leaving a
#  temporary file around at exit). Need to do this here to make sure
#  that this code is used.
itcl::body ::cat::AstroCat::new_catalog {name {id ""}
   {classname AstroCat} {debug 0} {tcs_flag 0} {type "catalog"}
   {w ""}} {
   if {[check_local_catalog $name $id $classname $debug $tcs_flag $type $w] != 0} {
      return
   }
   set i "$name,$id"
   if {[info exists instances_($i)] && [winfo exists $instances_($i)]} {
      utilRaiseWindow $instances_($i)
      if {"[$instances_($i).cat servtype]" == "local"} {
	 $instances_($i) search
      }
      return
   }
   if {[winfo exists $w]} {
      set instname $w.ac[incr n_instances_]
   } else {
      set instname .ac[incr n_instances_]
   }
   set instances_($i) \
      [$classname $instname \
	  -id $id \
	  -debug $debug \
	  -catalog $name \
	  -catalogtype $type \
	  -tcs $tcs_flag \
	  -transient 0 \
	  -center 0]
}

#  XXX redefine the body of SkySearch add_history proc. This doesn't
#  deal with images without a WCS system well (i.e. it reports an
#  error about converting "" to an RA and gives up).
itcl::body ::skycat::SkySearch::add_history {skycat filename} {
   set catalog $history_catalog_
   set image [$skycat get_image]

   # make sure at least an empty catalog exists
   if {! [file exists $catalog] || [file size $catalog] == 0} {
      # If it doesn't exist yet, create an empty catalog file
      if {[catch {set fd [::open $catalog w]} msg]} {
	 error_dialog "can't create image history catalog: %msg"
	 return
      }
      puts $fd "Skycat History Catalog v1.0"
      puts $fd ""
      puts $fd "ra_col: -1"
      puts $fd "dec_col: -1"
      puts $fd "x_col: -1"
      puts $fd "y_col: -1"
      puts $fd "show_cols: file ra dec object NAXIS NAXIS1 NAXIS2 NAXIS3"
      puts $fd "sort_cols: timestamp"
      puts $fd "sort_order: decreasing"
      puts $fd ""
      puts $fd [join $history_cols_ "\t"]
      puts $fd "----"
      ::close $fd
      # get the catalog into the list of known catalogs
      $astrocat_ open $catalog
   }

   if {"$filename" == "" || [string first /tmp $filename] == 0 \
	  || ! [file exists $filename]} {
      # ignore temporary and non-existant files
      return
   }

   # add an entry for the given image and filename
   set id [file tail $filename]
   lassign [$image wcscenter] ra dec equinox
   if { $ra == "" } {
      set ra "00:00:00"
      set dec "00:00:00"
   }
   set object [$image fits get OBJECT]
   set naxis [$image fits get NAXIS]
   set naxis1 [$image fits get NAXIS1]
   set naxis2 [$image fits get NAXIS2]
   set naxis3 [$image fits get NAXIS3]
   lassign [$image cut] lowcut highcut
   set colormap [$image cmap file]
   set itt [$image itt file]
   set colorscale [$image colorscale]
   set zoom [lindex [$image scale] 0]
   if {"$zoom" == ""} {
      set zoom 1
   }
   set timestamp [clock seconds]

   # get full path name of file for preview URL
   if {"[string index $filename 0]" == "/"} {
      set fullpath $filename
   } else {
      set fullpath [pwd]/$filename
   }
   set preview file:$fullpath

   set data [list [list $id $ra $dec $object $naxis $naxis1 $naxis2 $naxis3\
		      $lowcut $highcut $colormap $itt $colorscale $zoom \
		      $timestamp $preview]]

   $astrocat_ open $catalog
   catch {
      $astrocat_ save $catalog 1 $data $equinox
   }

   # update history catalog window, if it is showing
   set w [cat::AstroCat::get_instance [file tail $catalog]]
   if {"$w" != "" && [winfo viewable $w]} {
      $w search
   }
}

