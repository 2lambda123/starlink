   proc CCDRecordDirectoryinMenu { menubar menu directory entry
                                   choicebar button } { 
#+
#  Name:
#     CCDRecordDirectoryinMenu

#  Type of Module:
#     Tcl/Tk procedure.

#  Purpose:
#     Creates a command in a menu to return to the current directory.

#  Description:
#     This procedure creates a command in a menu (which is part of a
#     menubar) which will return to the current directory when invoked.
#     The procedure assumes that a labelled entry widget exists which
#     needs the current directory written into it and that a button of
#     a choice bar exists which when invoked will change the directory
#     to the menu name. Directories which have been visited previously
#     are not re-entered.

#  Arguments:
#     menubar = window (read)
#        The name of (CCDPACK) menubar which is to have the command
#	 added to one of its menus.
#     menu = string (read)
#        The name of the menubar menu which is to have the command
#	 added.
#     directory = string (read)
#        The name of the directory which is to be entered.
#     entry = window (read)
#        The name of a labelled entry widget to recieve the name of the
#	 directory when the menu command is invoked.
#     choicebar = window (read)
#        The name of the choice bar which contains the button as a named
#	 option.
#     button = window (read)
#	 The name of a button in a choice bar which when invoked
#	 will perform the actual change of directory.

#  Global variables:
#     CCDmenudirs$menu() = array (write)
#        The list of directories associated with the menu. This is
#	 indexed by the directory name.

#  Authors:
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     {enter_new_authors_here}

#  History:
#     8-MAR-1994 (PDRAPER):
#     	 Original version.
#     29-MAR-1994 (PDRAPER):
#     	 Modified to use mega-widgets.
#     {enter_further_changes_here}

#-

#  Global variables:
      global CCDmenudirs${menu}

#.

#  Check that the directory hasn't already been visited.
      if { ! [ info exists CCDmenudirs${menu}($directory) ] } {

#  Directory not present in menu add an command.
         $menubar addcommand $menu \
            "cd $directory" \
            "$entry clear 0 end
	     $entry insert 0 $directory
             $choicebar invoke $button
            "

#  And set the directory in array.
         set CCDmenudirs${menu}($directory) 1
      }

#  End of procedure
   }
# $Id$
