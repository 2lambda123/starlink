# $Id$
#
# LabelCommandMenu.tcl - Itcl widget for displaying a label and a
#                        command menu
#
# who             when       what
# --------------  ---------  ----------------------------------------
# Peter.W.Draper  04 Feb 99  Created, based on LabelMenu

itk::usual LabelCommandMenu {}

# This widget displays a label and a menubutton with a list of
# associated commands. This can be used as a means of providing access 
# to many commands from a single button.

class util::LabelCommandMenu {
   inherit FrameWidget

   #  Constructor:
   constructor {args} {
      set menu $w_.mb.m
      itk_component add mb {
         menubutton $w_.mb -menu $menu
      } {
         keep -indicatoron -relief -borderwidth -state \
            -text -anchor -width
         rename -font -labelfont labelFont Font
         ignore -disabledforeground
      }
      pack $itk_component(mb) \
         -side left -fill x -expand 1 -padx 1m -ipadx 1m
      
      itk_component add menu {
         menu $menu
      } {
         ignore -disabledforeground
         rename -font -valuefont valueFont ValueFont
      }
      set default_bg_ [$itk_component(mb) cget -background]
      eval itk_initialize $args
   }
   
   #  Destructor:
   destructor {
   }
   
   #  Remove all of the items in the menu
   method clear {} {
      $itk_component(menu) delete 0 end
   }

   #  Add a separator item to the menu
   method add_separator {} {
      $itk_component(menu) add separator
   }


   #  Add a command item to the menu.
   #  The args may be the options:
   #     -command <the cmd to execute when item is selected>
   #     -label <label for menuitem and menubutton when chosen>
   #     -bitmap <bitmap for menuitem and menubutton when chosen>
   #     -background <color of menu item and button when chosen>
   #     -font <font of menu item and button when chosen>
   #
   #  The -command option should always be supplied (otherwise nothing 
   #  will happen).
   method add {args} {

      # Command to add menu item
      set cmd "$itk_component(menu) add command"

      set id ""
      set n [llength $args]
      for {set i 0} {$i < $n} {incr i 2} {
         lassign [lrange $args $i end] opt arg
         switch -exact [string range $opt 1 end] {
            label {
               lappend cmd -label $arg
               set id $arg
            }
            bitmap {
               lappend cmd -bitmap $arg
               set id $arg
            }
            command {
               lappend cmd -command $arg
            }
            bg -
            background {
               if {"$arg" == ""} {
                  set mb_color $default_bg_
               } else {
                  set mb_color $arg
               }
               lappend value -background $mb_color -activebackground $mb_color
               lappend cmd -background $arg -activebackground $arg
            }
            font {
               lappend cmd -font $arg
            }
         }
      }
      eval $cmd
	
      #  Save label or bitmap name for later reference
      set names_($id) 1
   }
   
   #  Return true if the LabelMenu contains the given item
   #  (specified by the label or bitmap name).
   method contains {name} {
      return [info exists names_($name)]
   }

   #  Options:

   #  Label.
   itk_option define -text text Text {}

   #  Protected variables:

   #  Default background color
   protected variable default_bg_

   #  Array of names for existing command buttons.
   protected variable names_

}


