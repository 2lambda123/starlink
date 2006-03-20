#+
#  Name:
#     GaiaCanvasPrint

#  Type of Module:
#     [incr Tk] class

#  Purpose:
#     Extends util::CanvasPrint to add facilities required by GAIA.

#  Description:
#     This class adds then facility to set the background to the
#     colour shown on the canvas (rather than always being clear).

#  Invocations:
#
#        GaiaCanvasPrint object_name [configuration options]
#
#     This creates an instance of a GaiaCanvasPrint object. The return is
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
#     rtd::RtdCanvasPrint

#  Authors:
#     PWD: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     20-MAR-2006 (PWD):
#        Original version.
#     {enter_further_changes_here}

#-

#.

itk::usual GaiaCanvasPrint {}

itcl::class gaia::GaiaCanvasPrint {

   #  Inheritances:
   #  -------------
   inherit util::CanvasPrint

   #  Constructor:
   #  ------------
   constructor {args} {
      eval itk_initialize $args
   }

   #  Destructor:
   #  -----------
   destructor  {
   }

   #  Methods:
   #  --------

   #  This method is called after all options have been evaluated.

    protected method init {} {
       util::CanvasPrint::init
       wm title $w_ "GAIA postscript print ($itk_option(-number))"
    }

   #  Print the contents of the canvas to the open file descriptor.
   protected method print {fd} {
      #  The background needs to be same as the defined colour, not the
      #  default of clear.
      lassign [$itk_option(-canvas) bbox all] x0 y0 x1 y1
      set fakeid [$itk_option(-canvas) create rectangle $x0 $y0 $x1 $y1 \
                     -fill [$itk_option(-canvas) cget -background]]
      $itk_option(-canvas) lower $fakeid all

      util::CanvasPrint::print $fd

      $itk_option(-canvas) delete $fakeid
   }
}
