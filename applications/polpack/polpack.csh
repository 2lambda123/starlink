#+          
#  Name:
#     polpack.csh

#  Purpose:
#     Set up aliases for the POLPACK package.

#  Type of Module:
#     C shell script.

#  Invocation:
#     source polpack.csh

#  Description:
#     This procedure defines an alias for each POLPACK command. The string
#     INSTALL_BIN is replaced by the path of the directory containing the 
#     package executable files when the package is installed. The string
#     HELP_DIR is likewise replaced by the path to the directory containing 
#     help libraries.

#  Copyright:
#     Copyright (C) 1998 Central Laboratory of the Research Councils
 
#  Authors:
#     DSB: D.S. Berry (STARLINK)
#     {enter_new_authors_here}

#  History:
#     29-JUN-1997 (DSB):
#       Original Version.
#     25-MAR-1999 (DSB):
#       Added POLSIM. Alternative names corrected.
#     {enter_changes_here}

#-

#  Prepare to run ADAM applications if this has not been done already.
#  ===================================================================
#
#  Here look to see if there is an ADAM_USER directory.  If there is not
#  check whether or not there is an adam file that is not a directory.
#  If there is, issue a warning and exit.  Otherwise create the required
#  directory.
#
      if (-d $HOME/adam) then
         echo -n
      else
         if (-f $HOME/adam) then
            echo "You have a file called adam in your home directory.  Please rename "
            echo "since adam must be a directory for ADAM files."
            exit
         else
            mkdir $HOME/adam
         endif
      endif
#
#
#  Set up an environment variable pointing to the help library. This is refered
#  to within the appliation interface files.
      setenv POLPACK_HELP INSTALL_HELP/polpack
#
#  Define symbols for the applications and scripts.
#  ===============================================
#
      alias polbin    INSTALL_BIN/polbin
      alias polcal    INSTALL_BIN/polcal
      alias polexp    INSTALL_BIN/polexp
      alias polext    INSTALL_BIN/polext
      alias polhelp   INSTALL_BIN/polhelp 
      alias polimage  INSTALL_BIN/polimage
      alias polimp    INSTALL_BIN/polimp
      alias polka     INSTALL_BIN/polka
      alias polmap    INSTALL_BIN/polmap
      alias polplot   INSTALL_BIN/polplot
      alias polsim    INSTALL_BIN/polsim
      alias polstack  INSTALL_BIN/polstack
      alias polvec    INSTALL_BIN/polvec
      alias version   INSTALL_BIN/version 
      alias makecube  INSTALL_BIN/makecube.csh
#
#  Now do the same with alternative names.
#
      alias pol_polbin    INSTALL_BIN/polbin
      alias pol_polcal    INSTALL_BIN/polcal
      alias pol_polexp    INSTALL_BIN/polexp
      alias pol_polhelp   INSTALL_BIN/polhelp 
      alias pol_polimage  INSTALL_BIN/polimage
      alias pol_polimp    INSTALL_BIN/polimp
      alias pol_polka     INSTALL_BIN/polka
      alias pol_polmap    INSTALL_BIN/polmap
      alias pol_polplot   INSTALL_BIN/polplot
      alias pol_polsim    INSTALL_BIN/polsim
      alias pol_polstack  INSTALL_BIN/polstack
      alias pol_polvec    INSTALL_BIN/polvec
      alias pol_version   INSTALL_BIN/version
      alias pol_makecube  INSTALL_BIN/makecube.csh
#
#
#  Set up the commands and environment variables needed to export and
#  import POLPACK extension information to and from foreign data formats.
#
      if ( $?NDF_XTN ) then
         switch ($NDF_XTN)
            case *POLPACK*:
               breaksw
            default:
               setenv NDF_XTN ${NDF_XTN},POLPACK
         endsw
      else
         setenv NDF_XTN POLPACK
      endif

      setenv NDF_IMP_POLPACK 'INSTALL_BIN/polimp.csh ^ndf'
      setenv NDF_EXP_POLPACK 'INSTALL_BIN/polexp.csh ^ndf'
      setenv NDF_IMP_POLPACK_COMPRESSED ' '
      setenv NDF_EXP_POLPACK_COMPRESSED ' '
      setenv NDF_IMP_POLPACK_GZIP ' '
      setenv NDF_EXP_POLPACK_GZIP ' '
#
#
# Tell the user that POLPACK commands are now available.
#
      echo ""
      echo "   POLPACK commands are now available -- (Version PKG_VERS)"
      echo " "
      echo "   Type polhelp for help on POLPACK commands"
      echo "   Type 'showme sun223' to browse the hypertext documentation"
      echo " "
#
# end
