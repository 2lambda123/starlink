#+
#  Name:
#     GaiaAstTransfer

#  Type of Module:
#     [incr Tk] class

#  Purpose:
#     Aids the "transfer" of astrometric reference positions between
#     images.

#  Description:
#     This class creates a toplevel window with controls for selecting
#     X,Y positions on an associated image and for selecting the
#     corresponding RA,Dec positions on any other image that is displayed
#     (in another clone). The positions may be "centroided" and a list of
#     them is displayed in a text window. When completed these positions
#     may be used to update a StarAstTable object.

#  Invocations:
#
#        GaiaAstTransfer object_name [configuration options]
#
#     This creates an instance of a GaiaAstTransfer object. The return is
#     the name of the object.
#
#        object_name configure -configuration_options value
#
#     Applies any of the configuration options (after the instance has
#     been created).
#
#        object_name method arguments
#
#     Performs the given method on this object.

#  Configuration options:
#     See itk_define statements below.

#  Methods:
#     See method declarations below.

#  Inheritance:
#     util::TopLevelWidget

#  Authors:
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     05-MAR-1999 (PDRAPER):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itcl::class gaia::GaiaAstTransfer {

   #  Inheritances:
   #  -------------
   inherit util::TopLevelWidget

   #  Nothing

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Evaluate any options [incr Tk].
      eval itk_initialize $args

      #  Set the top-level window title.
      wm title $w_ "GAIA: Transfer coordinates ($itk_option(-number))"

      #  Add short help window.
      make_short_help

      #  Add the File menu.
      add_menubar
      set File [add_menubutton "File" left]
      configure_menubutton File -underline 0
      add_short_help $itk_component(menubar).file {File menu: close window}

      #  Set the exit menu items.
      $File add command -label {Cancel changes and close window} \
         -command [code $this cancel] \
         -accelerator {Control-c}
      bind $w_ <Control-c> [code $this cancel]
      $File add command -label {Accept changes and close window} \
         -command [code $this accept] \
         -accelerator {Control-a}
      bind $w_ <Control-a> [code $this accept]

      #  Markers menu
      set Markers [add_menubutton Markers]

      #  Add window help.
      global gaia_dir
      add_help_button $gaia_dir/StarAst.hlp "Astrometry Overview..."
      add_help_button $gaia_dir/StarAstTransfer.hlp "On Window..."
      add_short_help $itk_component(menubar).help \
         {Help menu: get some help about this window}

      #  Add table for displaying coordinates.
      itk_component add table {
         gaia::GaiaAstTransferTable $w_.table \
            -markmenu $Markers \
            -rtdimage $itk_option(-rtdimage) \
            -canvas $itk_option(-canvas) \
            -image $itk_option(-image)
      }

      #  Override short help for Table window.
      add_short_help $itk_component(table) \
         {Reference positions and their associated X,Y coordinates}
      pack $itk_component(table) -side top -fill both -expand 1

      #  Add frame for holding the window control action buttons.
      itk_component add frame2 {
         frame $w_.frame2
      }

      #  Add a frame of buttons for Accepting and Cancelling the table
      #  of values.
      itk_component add accept {
         button $itk_component(frame2).accept -text Accept \
            -command [code $this accept]
      }
      add_short_help $itk_component(accept) \
         {Accept new positions, updating reference table and close window}
      pack $itk_component(accept) -side left -expand 1 -pady 2 -padx 2

      itk_component add cancel {
         button $itk_component(frame2).cancel -text Cancel \
            -command [code $this cancel]
      }
      add_short_help $itk_component(cancel) \
         {Close window without updating reference table}
      pack $itk_component(cancel) -side left -expand 1 -pady 2 -padx 2

      #  Pack button frame.
      pack $itk_component(frame2) -fill x -expand 1 -side top -pady 2 -padx 2 -anchor w
   }

   #  Destructor:
   #  -----------
   destructor  {
   }

   #  Methods:
   #  --------

   #  Accept the new table of values and close window.
   public method accept {} {

      #  Invoke the "update" command.
      if { $itk_option(-update_cmd) != {} } {
         eval $itk_option(-update_cmd) [$itk_component(table) get_contents]
      }

      #  Clear table (to remove the markers) and withdraw.
      $itk_component(table) clear_table
      wm withdraw $w_
   }

   #  Just close the window, do not invoke the update command.
   public method cancel {} {

      #  Invoke the "update" command with no content
      if { $itk_option(-update_cmd) != {} } {
         $itk_option(-update_cmd) {}
      }

      #  Clear table (to remove the markers) and withdraw.
      $itk_component(table) clear_table
      wm withdraw $w_
   }

   #  Set the contents of the table (appended to any existing content).
   public method set_contents {args} {
      eval $itk_component(table) set_contents $args
      $itk_component(table) redraw
   }

   #  Clear the table.
   public method clear_table {} {
      $itk_component(table) clear_table
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  Name of rtdimage widget.
   itk_option define -rtdimage rtdimage RtdImage {}

   #  Name of the canvas holding the starrtdimage widget.
   itk_option define -canvas canvas Canvas {}

   #  Name of the RtdImage widget or derived class.
   itk_option define -image image Image {}

   #  Identifying number for toolbox (shown in () in window title).
   itk_option define -number number Number 0

   #  Command to invoke when the accept button is pressed. This has
   #  the contents of the table appended to it.
   itk_option define -update_cmd update_cmd Update_Cmd {}

   #  Width of the table (in characters).
   itk_option define -width width Width 40

   #  Protected variables: (available to instance)
   #  --------------------

   #  Common variables: (shared by all instances)
   #  -----------------

#  End of class definition.
}
