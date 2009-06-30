#+
#  Name:
#     Gaia3dRectPrism

#  Type of Module:
#     [incr Tcl] class

#  Purpose:
#     Create and manipulate a rectangular prism.

#  Description:
#     Class that extends Gaia3dVtkPrism to support rectangular shapes.
#     A rectangle is axis aligned.

#  Copyright:
#     Copyright (C) 2009 Science and Technology Facilities Council
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
#     27-APR-2009 (PWD):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itcl::class ::gaia3d::Gaia3dVtkRectPrism {

   #  Inheritances:
   #  -------------
   inherit gaia3d::Gaia3dVtkPrism

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

   #  Create the polygon for the rectangle locus. Note -1 correction to
   #  VTK grid coords.
   protected method create_polygon_ {} {

      $points_ Reset
      $cells_ Reset
      $cells_ InsertNextCell 4

      set x0v [expr $x0-1]
      set x1v [expr $x1-1]
      set y0v [expr $y0-1]
      set y1v [expr $y1-1]

      if { $axis == 1 } {
         $points_ InsertPoint 0 $zlow $x0v $y0v
         $points_ InsertPoint 1 $zlow $x0v $y1v
         $points_ InsertPoint 2 $zlow $x1v $y1v
         $points_ InsertPoint 3 $zlow $x1v $y0v
      } elseif { $axis == 2 } {
         $points_ InsertPoint 0 $x0v $zlow $y0v
         $points_ InsertPoint 1 $x0v $zlow $y1v
         $points_ InsertPoint 2 $x1v $zlow $y1v
         $points_ InsertPoint 3 $x1v $zlow $y0v
      } else {
         $points_ InsertPoint 0 $x0v $y0v $zlow
         $points_ InsertPoint 1 $x0v $y1v $zlow
         $points_ InsertPoint 2 $x1v $y1v $zlow
         $points_ InsertPoint 3 $x1v $y0v $zlow
      }
      $cells_ InsertCellPoint 0
      $cells_ InsertCellPoint 1
      $cells_ InsertCellPoint 2
      $cells_ InsertCellPoint 3

      $polydata_ SetPoints $points_
      $polydata_ SetPolys $cells_
   }

   #  Apply a shift to the corners.
   protected method apply_shift_ {sx sy} {
      configure -x0 [expr $x0+$sx] -x1 [expr $x1+$sx] \
                -y0 [expr $y0+$sy] -y1 [expr $y1+$sy]      
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  X coordinate, lower left.
   public variable x0 0.0

   #  Y coordinate, lower left.
   public variable y0 0.0

   #  X coordinate, upper right.
   public variable x1 1.0

   #  Y coordinate, upper right.
   public variable y1 1.0

   #  Protected variables: (available to instance)
   #  --------------------

   #  Common variables: (shared by all instances)
   #  -----------------

#  End of class definition.
}
