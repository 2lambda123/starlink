   proc CCDReduceExtras { Topwin } {
#+
#  Name:
#     CCDReduceExtras
   
#  Type of Module:
#     Tcl/Tk procedure.
   
#  Purpose:
#     Allows "extra" parameters to be set.
   
#  Description:
#     This procedure allows "extra" parameters to do with controlling a
#     reduction to be changed. These parameters are less relevant
#     parameters such as the extensions to give to NDF names the name of
#     the script to use and its type.

#  Arguments:
#     Topwin = window (read)
#        The name of the top-level window for this form.

#  Global parameters:
#     CCDglobalpars = array (read and write)
#        The values of the parameters to be set. 
   
#  Authors:
#     PDRAPER: Peter Draper (STARLINK - Durham University)
#     MBT: Mark Taylor (STARLINK)
#     {enter_new_authors_here}

#  Notes:
#     Choice of type of script to run removed as ICL will not run 
#     run a non-tty.
   
#  History:
#     18-MAY-1994 (PDRAPER):
#        Original version.
#     27-MAR-1995 (PDRAPER):
#        Added logfile.
#     1-JUN-1995 (PDRAPER):
#        Removed built-in keyboard traversal.
#     23-AUG-1995 (PDRAPER):
#        Converted to coding style.
#     16-MAY-2000 (MBT):
#        Upgraded for Tcl8.
#     {enter_changes_here}
   
#-
   
#  Global parameters:
      global CCDglobalpars
#.

#----------------------------------------------------------------------------
#  Widget creation.
#----------------------------------------------------------------------------
   
#  Create a top-level window.
      CCDCcdWidget Top top \
         Ccd_toplevel $Topwin -title "Reduce additional parameters"

#  Add a menubar.
      CCDCcdWidget Menu menu Ccd_helpmenubar $Top.menubar


#  Intermediary frame extensions. Extension to debiassed NDF names.
      CCDCcdWidget Debext debext \
         Ccd_labent $Top.debext \
                     -text "Extension of debiassed frames:" \
                     -textvariable CCDglobalpars(DEBIASEXT)

#  Extension to dark corrected NDF names.
      CCDCcdWidget Darkext darkext \
         Ccd_labent $Top.darkext \
                      -text "Extension of dark corrected frames:" \
                      -textvariable CCDglobalpars(DARKEXT)

#  Extension to flash corrected NDF names.
      CCDCcdWidget Flashext flashext \
         Ccd_labent $Top.flashext \
                       -text "Extension of flash corrected frames:" \
                       -textvariable CCDglobalpars(FLASHEXT)

#  Extension to flatfielded NDF names.
      CCDCcdWidget Flatext flatext \
         Ccd_labent $Top.flatext \
                      -text "Extension of flatfielded frames:" \
                      -textvariable CCDglobalpars(FLATEXT)

#  Names of the master NDFs: Bias.
      CCDCcdWidget Masterbias masterbias \
         Ccd_labent $Top.masterbias \
                         -text "Name of master bias:" \
                         -textvariable CCDglobalpars(MASTERBIAS)

#  Dark
      CCDCcdWidget Masterdark masterdark \
         Ccd_labent $Top.masterdark \
                         -text "Name of master dark:" \
                         -textvariable CCDglobalpars(MASTERDARK)

#  Flash.
      CCDCcdWidget Masterflash masterflash \
         Ccd_labent $Top.masterflash \
                          -text "Name of master flash:" \
                          -textvariable CCDglobalpars(MASTERFLASH)

#  Flat prefix.
      CCDCcdWidget Masterflat masterflat \
         Ccd_labent $Top.masterflat \
                         -text "Prefix name for master flatfields:" \
                         -textvariable CCDglobalpars(MASTERFLAT)

#  Get the name of the script.
      CCDCcdWidget Scriptname scriptname \
         Ccd_labent $Top.scriptname \
                         -text "Name of script:" \
                         -textvariable CCDglobalpars(SCRIPTNAME)

#  Get the type of script.
      CCDCcdWidget Scripttype scripttype \
         Ccd_radioarray $Top.scripttype \
                         -label "Script type:" \
                         -variable CCDglobalpars(SCRIPTTYPE)

#  Get the name of the logfile for the reduce job.
      CCDCcdWidget Exelogfile exelogfile \
         Ccd_labent $Top.exelogfile \
                         -text "Name of log file for background job:" \
                         -textvariable CCDglobalpars(EXELOGFILE)

#  Add choice bar for getting out.
      CCDCcdWidget Choice choice Ccd_choice $Top.choice -standard 0

#----------------------------------------------------------------------------
#  Widget configuration.
#----------------------------------------------------------------------------

#  Menu.
#  File items to accept window and exit interface.
      $Menu addcommand File {Accept Window} "$Choice invoke OK"
      $Menu addcommand File {Exit} CCDExit

#  Add an option to view the names of the NDFs to be processed.
      $Menu addcommand Options {View frames...} \
         "global CCDallndfs 
          CCDViewLists $Top.view {All available frames} CCDallndfs
         "

#  Scripttype.
#  Add known options for script type.
#      $Scripttype addbutton {C-shell} {CSH}
#      $Scripttype addbutton {ICL} {ICL}

#  Choice.
#  Ok button and just proceeds.
      $Choice addbutton {OK} "$Top kill $Top"

#----------------------------------------------------------------------------
#  Associate help.
#----------------------------------------------------------------------------
      $Top sethelp ccdpack CCDReduceExtrasWindow
      $Menu sethelpitem {On Window} ccdpack CCDReduceExtrasWindow
      $Menu sethelp all ccdpack CCDReduceExtrasMenu

#----------------------------------------------------------------------------
#  Pack all widgets.
#----------------------------------------------------------------------------
      pack $menu -fill x
      pack $choice -side bottom -fill x
      pack $debext $darkext $flashext $flatext -fill x
      pack $masterbias $masterdark $masterflash $masterflat -fill x
#      pack $scriptname $scripttype $exelogfile -fill x
      pack $scriptname $exelogfile -fill x

#  End of procedure.
   }
# $Id$
