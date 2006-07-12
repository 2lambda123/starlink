#+
#  Name:
#     GaiaCubeCollapse

#  Type of Module:
#     [incr Tk] class

#  Purpose:
#     Controls for the collapse of a cube displayed by a GaiaCube.

#  Description:
#     This class creates a panel of controls for collapsing a range of planes
#     of a cube into a "white-light" image. The image is then displayed in the
#     main GAIA window.

#  Invocations:
#
#        GaiaCubeCollapse object_name [configuration options]
#
#     This creates an instance of a GaiaCubeCollapse object. The return is
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
#     See itk_option definitions below.

#  Methods:
#     See individual method declarations below.

#  Inheritance:
#     gaia::GaiaCubeApps

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
#     PWD: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     31-MAY-2006 (PWD):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itk::usual GaiaCubeCollapse {}

itcl::class gaia::GaiaCubeCollapse {

   #  Inheritances:
   #  -------------
   inherit gaia::GaiaCubeApps

   #  Nothing

   #  Constructor:
   #  ------------
   constructor {args} {
      eval gaia::GaiaCubeApps::constructor $args
   } {
      #  Evaluate any options [incr Tk].
      eval itk_initialize $args
   }

   #  Destructor:
   #  -----------
   destructor  {
      #  Nothing to do, accept GaiaCubeApps default.
   }

   #  Methods:
   #  --------

   #  Collapse image.
   protected method run_main_app_ {ndfname axis lb ub} {

      #  Start up the COLLAPSE application, if not already done.
      if { $maintask_ == {} } {
         global env
         set maintask_ [GaiaApp \#auto -application \
                           $env(KAPPA_DIR)/collapse \
                           -notify [code $this app_completed_]]
      }

      #  Create a temporary file name.
      set tmpimage_ "GaiaTempCollapse${count_}"
      incr count_

      $maintask_ runwiths "in=$ndfname out=$tmpimage_ axis=$axis \
                           low=$lb high=$ub estimator=$combination_type_ \
                           accept"

      #  Tell cube to use these limits for spectral extraction.
      $itk_option(-gaiacube) set_extraction_range \
         $itk_option(-lower_limit) $itk_option(-upper_limit)
   }

   #  Display a collapsed image.
   protected method app_do_present_ {} {
      set file {}
      if { ! [file readable $tmpimage_] } {
         if { ! [file readable ${tmpimage_}.sdf] } {
            blt::busy release $w_
            return
         }
         set file ${tmpimage_}.sdf
      } else {
         set file $tmpimage_
      }
      if { $file != {} } {
         $itk_option(-gaiacube) display $file 1
      }
   }

   #  Configuration options: (public variables)
   #  ----------------------

   #  Protected variables: (available to instance)
   #  --------------------

   #  Common variables: (shared by all instances)
   #  -----------------

#  End of class definition.
}
