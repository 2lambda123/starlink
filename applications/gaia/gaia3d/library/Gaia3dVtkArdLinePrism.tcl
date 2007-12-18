#+
#  Name:
#     Gaia3dArdLinePrism

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#     Create and manipulate a line ARD prism (a plane).

#  Description:
#     Class that extends Gaia3dVtkArdPrism to support line shapes.

#  Copyright:
#     Copyright (C) 2007 Science and Technology Facilities Council
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
#     PWD: Peter Draper (JAC, Durham University)
#     {enter_new_authors_here}

#  History:
#     07-DEC-2007 (PWD):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itcl::class ::gaia3d::Gaia3dVtkArdLinePrism {

   #  Inheritances:
   #  -------------
   inherit gaia3d::Gaia3dVtkArdPrism

   #  Constructor:
   #  ------------
   constructor {args} {

      #  Set any configuration variables.
      eval configure $args
   }

   #  Destructor:
   #  -----------
   destructor  {
   }

   #  Methods and procedures:
   #  -----------------------

   #  Create the polygon for the line locus. Should extrude into a plane.
   #  Note -1 correction to VTK grid coords.
   protected method create_polygon_ {} {

      $points_ Reset
      $cells_ Reset
      $cells_ InsertNextCell 2

      set x0v [expr $x0-1]
      set x1v [expr $x1-1]
      set y0v [expr $y0-1]
      set y1v [expr $y1-1]

      if { $axis == 1 } {
         $points_ InsertPoint 0 0.0 $x0v $y0v
         $points_ InsertPoint 1 0.0 $x1v $y1v
      } elseif { $axis == 2 } {
         $points_ InsertPoint 0 $x0v 0.0 $y0v
         $points_ InsertPoint 1 $x1v 0.0 $y1v
      } else {
         $points_ InsertPoint 0 $x0v $y0v 0.0
         $points_ InsertPoint 1 $x1v $y1v 0.0
      }
      $cells_ InsertCellPoint 0
      $cells_ InsertCellPoint 1

      $polydata_ SetPoints $points_
      $polydata_ SetPolys $cells_
   }

   #  Apply a shift to the ends.
   protected method apply_shift_ {sx sy} {
      configure -x0 [expr $x0+$sx] -x1 [expr $x1+$sx] \
                -y0 [expr $y0+$sy] -y1 [expr $y1+$sy]      
   }

   #  Get an ARD description for this shape.
   public method get_desc {} {
      return "LINE($x0,$y0,$x1,$y1)"
   }

   #  Set the properties of this object from an ARD description.
   public method set_from_desc {desc} {
      lassign [get_ard_args $desc] x0 y0 x1 y1
      configure -x0 $x0 -x1 $x1 -y0 $y0 -y1 $y1
   }

   #  See if an ARD description presents a line.
   public proc matches {desc} {
      return [string match -nocase "lin*" $desc]
   }

   #  Given an ARD description of a line create an instance of this class.
   #  Make sure this passes the matches check first.
   public proc instance {desc} {
      lassign [get_ard_args $desc] x0 y0 x1 y1
      return [uplevel \#0 gaia3d::Gaia3dVtkArdLinePrism \#auto \
                 -x0 $x0 -x1 $x1 -y0 $y0 -y1 $y1]
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  X coordinate of first end point.
   public variable x0 0.0

   #  Y coordinate of first end point.
   public variable y0 0.0

   #  X coordinate of second end point.
   public variable x1 1.0

   #  Y coordinate of second end point.
   public variable y1 1.0

   #  Protected variables: (available to instance)
   #  --------------------

   #  Common variables: (shared by all instances)
   #  -----------------

#  End of class definition.
}
