#!/bin/csh -f
#+
#  Name:
#     datacube.csh
#
#  Purpose:
#     Start the DATACUBE system from Unix shell.
#
#  Type of Module:
#     C shell script.
#
#  Usage:
#     source datacube.csh
#
#  Description:
#     This procedure defines the aliases needed to run 
#     each application monolith.
#
#
#  Authors:
#     BLY: M.J.Bly (Starlink, RAL)
#     PDRAPER: Peter W. Draper (Starlink, Durham University)
#     AALLAN: Alasdair Allan (Starlink, Keele University)
#     {enter_new_authors_here}
#
#  History:
#     13-OCT-1994 (BLY);
#       Original for PHOTOM
#     06-NOV-1996 (PDRAPER):
#       Added AUTOPHOTOM application.
#     09-FEB-1999 (AALLAN):
#       Added optional -quiet parameter
#     15-NOV-1999 (AALLAN):
#       -quiet parameter broke some scripts, removed
#     05-JUN-2000 (AALLAN):
#       Modified for use by DATACUBE.
#     19-SEP-2000 (AALLAN):
#       Tweaked
#     09-NOV-2000 (AALLAN):
#       Added links to KAPPA, FIGARO and CONVERT external appliactions
#     20-NOV-2000 (AALLAN):
#       Incorporated changes made to source at ADASS
#     29-DEC-2000 (AALLAN):
#       Added test script
#     08-JAN-2001 (AALLAN):
#       Added XDialog scripts
#     {enter_changes_here}
#
#  Copyright:
#     Copyright (C) 2000 Central Laboratory of the Research Councils
#-
#

#  Define aliases for the scripts.

alias ripper          source ${DATACUBE_DIR}/ripper.csh
alias dat_ripper      source ${DATACUBE_DIR}/ripper.csh
alias squash          source ${DATACUBE_DIR}/squash.csh
alias dat_squash      source ${DATACUBE_DIR}/squash.csh
alias step            source ${DATACUBE_DIR}/step.csh
alias dat_step        source ${DATACUBE_DIR}/step.csh
alias velmap          source ${DATACUBE_DIR}/velmap.csh
alias dat_velmap      source ${DATACUBE_DIR}/velmap.csh
alias peakmap         source ${DATACUBE_DIR}/peakmap.csh
alias dat_peakmap     source ${DATACUBE_DIR}/peakmap.csh
alias compare         source ${DATACUBE_DIR}/compare.csh
alias dat_compare     source ${DATACUBE_DIR}/compare.csh
alias passband        source ${DATACUBE_DIR}/passband.csh
alias dat_passband    source ${DATACUBE_DIR}/passband.csh
alias peakmap         source ${DATACUBE_DIR}/peakmap.csh
alias dat_pealmap     source ${DATACUBE_DIR}/peakmap.csh
alias stacker         source ${DATACUBE_DIR}/stacker.csh
alias dat_stacker     source ${DATACUBE_DIR}/stacker.csh
alias multistack      source ${DATACUBE_DIR}/multistack.csh
alias dat_multistack  source ${DATACUBE_DIR}/multistack.csh

#  Define aliases for scripts dependant on XDialog an GTK+

alias xcompare        source ${DATACUBE_DIR}/compare_x.csh

#  Define aliases for the applications.

alias getbound        ${DATACUBE_DIR}/getbound
alias dat_getbound    ${DATACUBE_DIR}/getbound
alias putaxis         ${DATACUBE_DIR}/putaxis
alias dat_putaxis     ${DATACUBE_DIR}/putaxis
alias copyaxis        ${DATACUBE_DIR}/copyaxis
alias dat_copyaxis    ${DATACUBE_DIR}/copyaxis
alias putsky          ${DATACUBE_DIR}/putsky
alias dat_putsky      ${DATACUBE_DIR}/putsky

#  Define alias for the DATACUBE test script

alias datacube_demo   source ${DATACUBE_DIR}/datacube_demo.csh
alias datacube_test   source ${DATACUBE_DIR}/datacube_demo.csh

#  Define aliases for external applications used by the scripts

alias add             ${KAPPA_DIR}/add
alias calc            ${KAPPA_DIR}/calc
alias cadd            ${KAPPA_DIR}/cadd
alias cdiv            ${KAPPA_DIR}/cdiv 
alias chpix           ${KAPPA_DIR}/chpix
alias cursor          ${KAPPA_DIR}/cursor
alias contour         ${KAPPA_DIR}/contour
alias display         ${KAPPA_DIR}/display 
alias linplot         ${KAPPA_DIR}/linplot 
alias ndfcopy         ${KAPPA_DIR}/ndfcopy
alias ndftrace        ${KAPPA_DIR}/ndftrace 
alias parget          ${KAPPA_DIR}/parget
alias wcscopy         ${KAPPA_DIR}/wcscopy
alias collapse        ${KAPPA_DIR}/collapse
alias setorigin       ${KAPPA_DIR}/setorigin
alias setmagic        ${KAPPA_DIR}/setmagic  
alias settitle        ${KAPPA_DIR}/settitle
alias lutgrey         ${KAPPA_DIR}/lutable mapping=linear coltab=grey
alias lutcol          ${KAPPA_DIR}/lutable mapping=linear coltab=colour
alias gdclear         ${KAPPA_DIR}/gdclear
alias paldef          ${KAPPA_DIR}/paldef
alias picbase         ${KAPPA_DIR}/piclist picnum=1
alias picdef          ${KAPPA_DIR}/picdef
alias piclabel        ${KAPPA_DIR}/piclabel
alias picsel          ${KAPPA_DIR}/picsel
alias stats           ${KAPPA_DIR}/stats

alias fitgauss        ${FIG_DIR}/fitgauss
alias specplot        ${FIG_DIR}/specplot

alias ascii2ndf       ${CONVERT_DIR}/ascii2ndf

#  Define alias for help application

alias cubehelp        ${DATACUBE_DIR}/datacube_help

#  Set DATACUBE_HLP

setenv DATACUBE_HLP   ${DATACUBE_DIR}/../../help/datacube/datacube

#if ($#argv == 0 || $1 != "-quiet") then  
      echo " "
      echo "   DATACUBE applications are now available -- (Version PKG_VERS)"
      echo "    Support is available by emailing datacube@star.rl.ac.uk"
      echo " "
      echo "        Type cubehelp for help on DATACUBE commands."
      echo "   Type 'showme sun237' to browse the hypertext documentation"
      echo "   or 'showme sc16' to consult the IFU data product cookbook."
      echo " "
#endif

#
# end
#

