#!@csh@
#+
#  Name:
#     fluxnow.csh
#
#  Purpose:
#     Start the FLUXES system from Unix shell in such
#     a way that the current values are used.
#
#  Type of Module:
#     C shell script.
#
#  Invocation:
#     fluxnow.csh
#
#  Description:
#     This procedure starts the FLUXES system for use from Unix by 
#     defining some environmental variables appropriately and then 
#     setting the parameters to those that generate the current values.
#
#  Notes:
#     The file JPLEPH is *required* as name for ephemeris file.
#
#  Authors:
#     GJP: G.J. Privett (Starlink, Cardiff)
#     ACC: A.C. Charles (Starlink, RAL)
#     BLY: M.J. Bly (Starlink, RAL)
#     TIMJ: Tim Jenness (JACH)
#
#  History:
#     13-DEC-1996 (GJP):
#       Original Version
#     03-FEB-1997 (ACC/BLY):
#       Changed definition of FLUXES to INSTALL_BIN.
#       Modified startup to use link to JPL ephemeris instead of
#          requiring to be run from ephemeris directory.
#     07-FEB-1997 (BLY):
#       Modified setting of FLUXPWD since $PWD not guranteed on Dec-Unix.
#     14-JUL-2004 (TIMJ):
#       Uses @bindir@ rather than INSTALL_BIN
#       Uses FLUXES_DIR and JPL_DIR environment variable if set
#-

# Flag an interrupt for bugging out.
onintr goto quit

# Set up the environmental variables.
 
# Define the location of fluxes and its data files.
# This is edited into this script during installation.
if ($?FLUXES_DIR) then
  if (-d $FLUXES_DIR) then
    setenv FLUXES $FLUXES_DIR
  else
    echo FLUXES_DIR environment variable not set to a directory.
    echo Using default fluxes location
    setenv FLUXES @bindir@
  endif
else
  setenv FLUXES @bindir@
endif

# Define a link to the jpleph.dat file in the current directory.
if ( -f JPLEPH ) then
   echo \
"File JPLEPH already exists - assuming it is, or points to, the JPL ephemeris."
   set jpl_ok = "no"
else
   # Location of JPL ephemeris. JPL_DIR takes precedence
   # Note that staretcdir refers to $STARLINK/etc/fluxes
   # but the JPL files are in $STARLINK/etc
   set jpl_dir = @staretcdir@/../
   if ($?JPL_DIR) then
     if (-d $JPL_DIR) then
       set jpl_dir = $JPL_DIR
     endif
   endif

   if (! -e $jpl_dir/jpleph.dat) then
     echo Unable to locate ephemeris in directory $jpl_dir
     exit
   endif

   ln -s $jpl_dir/jpleph.dat JPLEPH
   set jpl_ok = "yes"
endif

# Find out working directory and set FLUXPWD to it, so
# that the code works in JACH style without change.
unalias pwd
setenv FLUXPWD `pwd`

# Run the main program.
$FLUXES/fluxes pos=y flu=y screen=y ofl=y outfile=fluxes.dat now=y apass=n planet=all

# Exit
quit:
if ( ${jpl_ok} == "yes" ) then
   rm -f JPLEPH
endif

exit

# end
#.
