#+
#  Name:
#     StarArdPixel

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#     Defines a class of object for controlling an ARD pixel drawn
#     using a StarCanvasDraw object.

#  Description:
#     This class provides the basic functionality for controlling an
#     ARD pixel region. It provides the basic draw facilities and
#     returns an ARD description of the region.


#  Invocations:
#
#        StarArdPixel object_name [configuration options]
#
#     This creates an instance of a StarArdPixel object. The return is
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
#     See public variable defintions.

#  Methods:
#     See method definitions.

#  Inheritance:
#     This class inherits StarArdPrim.

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils

#  Authors:
#     PWD: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     8-MAY-1996 (PWD):
#        Original version.
#     6-JUL-1996 (PWD):
#        Converted to itcl2.0.
#     {enter_further_changes_here}

#-

#.

itcl::class gaia::StarArdPixel {

   #  Inheritances:
   #  -------------

   inherit gaia::StarArdPrim

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Set the type of canvas object.
      configure -mode pixel
      eval configure $args
   }

   #  Destructor:
   #  -----------
   destructor  {
   }

   #  Methods:
   #  --------

   #  Return the ARD description of the object.
   method getard {{do_update 1}} {

      #  Make sure that the coords are up to date, if allowed.
      if { $do_update} { update $canvas_id_ resize }
      lassign $coords x0 y0 x1 y1
      lassign [image_coord $x0 $y0] x y

      # Pixels should really be specified in pixel indices.
      set x [expr round($x+0.5)]
      set y [expr round($y+0.5)]
      return "PIXEL($x,$y)"
   }

   #  Set the properties of the object to those of an ARD description
   #  of an object of this type.
   method setard {desc} {
      if {$desc != "" } {
         set failed 1
         if { [check_description pixel $desc] } {
            if { [llength $qualifiers_] == 2 } {
               lassign $qualifiers_ x y

               #  Pixel indices to coordinates before transformation.
               set x [expr $x-0.5]
               set y [expr $y-0.5]
               lassign [canvas_coord $x $y] xs ys
               configure -coords "$xs $ys $xs $ys"
               set failed 0
            }
         }
         if { $failed } {
            error "Failed to interpret \"$desc\" as an ARD pixel"
         }
      }
   }

   #  Create a new pixel using an ARD description.
   method createard {desc {cmd ""}} {
      setard "$desc"
      create_no_resize $cmd $coords
   }

   #  Create a top-level window that describes the current object and
   #  allows its values to be changed.
   method show_properties {{name ""}} {
      if { $name == {} } {
         set name ".pixel$canvas_id_"
      }
      if { ! [create_properties_window $name] } {

         #  Now add the buttons for the description.
         set X_ [LabelEntry $Frame_.x \
                    -text {X:} \
                    -command [code $this configure -x]]
         set Y_ [LabelEntry $Frame_.y \
                    -text {Y:} \
                    -command [code $this configure -y]]
         pack $X_ $Y_ -side top -fill x
      }

      #  Update the information to be current.
      update_properties
   }

   #  Update all properties.
   method update_properties {} {

      #  Make sure record of canvas item values is up todate.
      update $canvas_id_ resize
      lassign $coords x0 y0 x1 y1
      lassign [image_coord $x0 $y0] x y
      set x [expr round($x+0.5)]
      set y [expr round($y+0.5)]

      #  Update the properties box if it exists.
      if { [winfo exists $Properties_] } {
         $X_ configure -value $x
         $Y_ configure -value $y
      }
   }

   #  Procedures: (access common values)
   #  -----------

   #  X position in image coordinates.
   public variable x {0} {
      if { [winfo exists $X_] } {
         $X_ configure -value $x
         lassign [canvas_coord $x $y] xs ys
         set coords "$xs $ys $xs $ys"
         redraw
      }
   }

   #  Y position in image coordinates.
   public variable y {0} {
      if { [winfo exists $Y_] } {
         $Y_ configure -value $y
         lassign [canvas_coord $x $y] xs ys
         set coords "$xs $ys $xs $ys"
         redraw
      }
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  Protected variables: (available to instance)
   #  --------------------

   #  Names of various widgets.
   protected variable X_ {}
   protected variable Y_ {}

   #  Common variables: (shared by all instances)
   #  -----------------

#  End of class definition.
}
