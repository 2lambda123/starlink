   class Marknumcontrol {
#+
#  Name:
#     Marknumcontrol

#  Type of Module:
#     [incr Tk] Mega-Widget

#  Purpose:
#     Control widget for selecting a marker number.

#  Description:
#     This control provides an interface using which the user may select
#     the index of the next marker to be plotted.

#  Public Methods:
#
#     clear
#        Resets all marker indices to the unused state.
#
#     next
#        Returns the index of the next unused marker.  This will normally
#        be the one displayed in the widget.  If there are no unused
#        markers left, it will return -1.
#
#     unuse index
#        Set the given marker index to the unused state.
#
#     use index
#        Set the given marker index to the used state.
#

#  Public Variables (Configuration Options):
#
#     max
#        The maximum index that the value variable may take.  If set to
#        zero, there is no upper limit.
#
#     value
#        The value which will be returned by the 'next' method.
#        On the whole it is not a good idea to access this directly; 
#        the 'next' method should be used instead.
#
#     Marknumcontrol also inherits all the public variables of the Control
#     widget.

#-

#  Inheritance:
      inherit Control


########################################################################
#  Constructor.
########################################################################
      constructor { args } {
         itk_component add control {
            frame [ childsite ].control
         }
         itk_component add marknum {
            iwidgets::spinint $itk_component(control).marknum \
               -wrap false \
               -textvariable [ scope value ]
         }
         pack $itk_component(marknum) -fill y
         pack $itk_component(control) -fill y
         eval itk_initialize $args
         clear
      }


########################################################################
#  Public methods.
########################################################################

#-----------------------------------------------------------------------
      public method clear { } {
#-----------------------------------------------------------------------
         set value 1
         catch { unset used }
      }


#-----------------------------------------------------------------------
      public method next { } {
#-----------------------------------------------------------------------
         return $value
      }


#-----------------------------------------------------------------------
      public method use { index } {
#-----------------------------------------------------------------------

#  Set the given index to the used state.
         set used($index) 1

#  Now we need to set value to an unused index.  First look for the next
#  largest value in the given range which is not already used.
         set value -1
         for { set i [ expr $index + 1 ] } { $i <= $imax } { incr i } {
            if { [ catch { set used($i) } ] } {
               set value $i
               break
            }
         }

#  If that was no good, start at the bottom and find the lowest index which
#  has not already been used.  If this fails, then value will be left
#  as -1, which is the no-unused-indices-left value.
         if { $value < 0 } {
            for { set i 1 } { $i < $index } { incr i } {
               if { [ catch { set used($i) } ] } {
                  set value $i
                  break
               }
            }
         }
      }


#-----------------------------------------------------------------------
      public method unuse { index } {
#-----------------------------------------------------------------------

#  Set the given index to the unused state.  If it was the highest used
#  index, set the next value to the one after the new highest.
#  Otherwise, set the next value to the one we've just unused.
         if { ! [ catch { unset used($index) } ] } {
            set highest [ eval max 0 [ array names used ] ]
            if { $index > $highest } {
               set value [ expr $highest + 1 ]
            } else {
               set value $index
            }
         }
      }



########################################################################
#  Public variables.
########################################################################

#-----------------------------------------------------------------------
      public variable max { 99 } {
#-----------------------------------------------------------------------
         if { $max == 0 } {
            set imax 99999
            $itk_component(marknum) configure \
                -range "1 $imax" \
                -width 4
         } else {
            set imax $max
            $itk_component(marknum) configure \
                -range "1 $max" \
                -width [ string length $max ]
         }
      }


#-----------------------------------------------------------------------
      public variable state { normal } {
#-----------------------------------------------------------------------
         if { $state == "normal" } {
            $itk_component(marknum) configure -state "normal"
         } elseif { $state == "disabled" } {
            $itk_component(marknum) configure -state "disabled"
         }
      }


#-----------------------------------------------------------------------
      public variable value { 1 } {
#-----------------------------------------------------------------------
      }



########################################################################
#  Private methods.
########################################################################


########################################################################
#  Private variables.
########################################################################

      private variable imax      ;# Actual maximum number of indices
      private variable used      ;# Array holding used indices

   }


########################################################################
#  Widget resource management
########################################################################

   itk::usual Marknumcontrol {
      keep -background -cursor -foreground
   }


########################################################################
#  Constructor alias
########################################################################

   proc marknumcontrol { pathname args } {
      uplevel Marknumcontrol $pathname $args
   }


# $Id$
