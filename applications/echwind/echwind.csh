#!/bin/csh -f
#+
#  Name:
#     echwind.csh
#
#  Purpose:
#     Startup and run ECHWIND for Starlink installation.
#
#  Authors:
#     BLY: M.J.Bly (Starlink, RAL)
#     ACC: A.C.Charles (Starlink, RAL)
#
#  History:
#     22-MAR-1995 (BLY):
#        Original version.
#     16-JUL-1996 (BLY):
#        Version to use with Native PGPLOT, shipped with ECHWIND.
#     25-SEP-1996 (ACC):
#        Commented out ECHWIND_DETECTORS definition - not used.
#     26-SEP-1996 (BLY):
#        Added version banner.
#     07-FEB-1997 (BLY):
#        Set default graphics device to /XWIN if not already set.
#     09-OCT-1998 (BLY):
#        Adapted for use with Starlink installation of Native PGPLOT.
#-

echo ""
echo "    Echwind version PKG_VERS"
echo ""

onintr goto exit

#  Define location of Echwind files.
setenv ECHWIND_HOME INSTALL_BIN/

#  Define location of Pgplot files if not already defined.
if ( ! ${?PGPLOT_DIR} ) then
   setenv PGPLOT_DIR STAR_BIN/
   set set_dir = "yes"
else
   set set_dir = "no"
endif

#  Set default pgplot device if not already set.
if ( ! ${?PGPLOT_DEV} ) then
   setenv PGPLOT_DEV /XWIN
   set set_device = "yes"
else
   set set_device = "no"
endif

#  Define file that holds list of spectrographs.
setenv ECHWIND_SPECTROGRAPHS ${ECHWIND_HOME}spectrographs.dat
 
# The following line looks good, but it is not used.
# The default value for the system detectors file is
# 'detsystem' in the file 'echwind.ifl'. -- 25 Sep 1996, ACC
#
#setenv ECHWIND_DETECTORS     ${ECHWIND_HOME}detectors.dat

${ECHWIND_HOME}echwind

# Tidy up exit handling if interrupt is invoked.

exit:

unsetenv ECHWIND_HOME PGPLOT_DIR  ECHWIND_SPECTROGRAPHS ECHWIND_DETECTORS
if ( ${set_dir} == "yes" ) then
   unsetenv PGPLOT_DIR
   unset set_dir
endif
if ( ${set_device} == "yes" ) then
   unsetenv PGPLOT_DEV
   unset set_device
endif

exit

#.
