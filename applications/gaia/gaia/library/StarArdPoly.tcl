#+
#  Name:
#     StarArdPoly

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#     Defines a class of object for controlling an ARD polygon drawn
#     using a StarCanvasDraw object.

#  Description:
#     This class provides the basic functionality for controlling an
#     ARD polygon region. It provides the basic draw facilities and
#     returns an ARD description of the region. Note this uses ths
#     point editable version of a polygon not the scalable version.

#  Invocations:
#
#        StarArdPoly object_name [configuration options]
#
#     This creates an instance of a StarArdPoly object. The return is
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
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     8-MAY-1996 (PDRAPER):
#        Original version.
#     5-JUL-1996 (PDRAPER):
#        Converted to itcl2.0.
#     {enter_further_changes_here}

#-

#.

itcl::class gaia::StarArdPoly {

   #  Inheritances:
   #  -------------

   inherit gaia::StarArdPrim

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Set the type of canvas object.
      configure -mode pointpoly
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
      process_coords_ $coords
      set two 0
      set desc "POLYGON("
      foreach coord $vertices {
         append desc "$coord,"
         incr two
         if { $two == 2 } { 
            append desc "\n"
            set two 0
         } 
      }
      set desc "[string trim $desc ",\n"])"
      return "$desc"
   }

   #  Set the properties of the object to those of an ARD description
   #  of an object of this type.
   method setard {desc} {
      if {$desc != "" } {
         set failed 1
         if { [check_description polygon $desc] } {
            if { [llength $qualifiers_] > 5 } {
               process_verts_ $qualifiers_
            }
            configure -coords "$coords"
            set failed 0
         }
         if { $failed } {
            error "Failed to interpret \"$desc\" as an ARD polygon"
         }
      }
   }

   #  Create a new polygon using an ARD description.
   method createard {desc {cmd {}}} {
      setard "$desc"
      create_no_resize $cmd $coords
   }

   #  Process vertices into pairs of coordinates and assign the
   #  result to the public variables, vertices and coords in the
   #  correct system.
   method process_verts_ {imagecoords} {
      set newverts ""
      set newcoords ""
      set nvalues [llength $imagecoords]
      if { $nvalues > 5 } {
         for {set i 0} {$i < $nvalues} {incr i} {
            set x [lindex $imagecoords $i]
            incr i
            set y [lindex $imagecoords $i]
            append newverts " $x $y"
            append newcoords " [canvas_coord $x $y]"
         }
      }
      set vertices $newverts
      set coords $newcoords
   }

   #  Process coordinates into pairs of vertices and assign the
   #  result to the public variables, vertices and coords in the
   #  correct system.
   method process_coords_ {canvcoords} {
      set newverts ""
      set newcoords ""
      set nvalues [llength $canvcoords]
      if { $nvalues > 5 } {
         for {set i 0} {$i < $nvalues} {incr i} {
            set x [lindex $canvcoords $i]
            incr i
            set y [lindex $canvcoords $i]
            append newcoords " $x $y"
            append newverts " [image_coord $x $y]"
         }
      }
      set vertices $newverts
      set coords $newcoords
   }

   #  Create a top-level window that describes the current object and
   #  allows its values to be changed.
   method show_properties {{name ""}} {
      if { $name == {} } {
         set name ".poly$canvas_id_"
      }
      if { ! [create_properties_window $name] } {

         #  Now add the entry  for the description.
         set Vertices_ [ETable $Frame_.table -columns 2 -rows 4\
                           -action [code $this update_from_table]]
         $Vertices_ setlabel 0 X
         $Vertices_ setlabel 1 Y
         pack $Vertices_ -side top -fill both -expand true
      }

      #  Update the information to be current.
      update_properties
   }

   #  Update all properties.
   method update_properties {} {

      #  Make sure record of canvas item values is up todate.
      update $canvas_id_ resize
      process_coords_ $coords

      #  Update the properties box if it exists (Note -1 removes
      #  repeat value from end of list).
      if { [winfo exists $Vertices_] } {
         set currows [$Vertices_ size]
         set nvertices [expr [llength $vertices]/2-1]
         for { set i 0; set n 0 } { $i < $nvertices } { incr i; incr n} {
            $Vertices_ insert $i \
               [lindex $vertices $n] [lindex $vertices [incr n]]
         }
         if { $i < $currows } {
            $Vertices_ clear $i end
         }
      }
   }

   #  Update coords from the table.
   method update_from_table {} {
      if { [winfo exists $Vertices_] } {
         set nrows [$Vertices_ size]
         set newverts ""
         for { set i 0 } { $i < $nrows } { incr i } {
            append newverts " [$Vertices_ get $i]"
         }
         process_verts_ $newverts
         redraw
      }
   }

   #  Procedures: (access common values)
   #  -----------

   #  Configuration options: (public variables)
   #  ----------------------

   #  Coordinates of polygon vertices in image coordinates. Process
   #  values as pairs and throw away any extras.
   public variable vertices {} {
      if { $vertices != {} } {
         process_verts_ $vertices
         redraw
      }
   }

   #  Protected variables: (available to instance)
   #  --------------------

   #  Widget for displaying/changing polygon vertices.
   protected variable Vertices_ {}

   #  Common variables: (shared by all instances)
   #  -----------------

#  End of class definition.
}
