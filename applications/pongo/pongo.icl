{+
{  Name:
{     PONGO.ICL

{  Purpose:
{     PONGO start-up procedure.

{  Language:
{     ADAM ICL

{  Type of module:
{     ICL file

{  Arguments:

{  Invocation:
{     LOAD PONGO

{  Description:
{     The PONGO commands are defined.
{     The PONGO help library is defined.

{  Authors:
{     PAH: Paul Harrison (JBVAD::PAH):
{     PCTR: P.C.T. Rees (STARLINK)
{     PDRAPER: P.W. Draper (STARLINK)

{  History:
{     APR-1990 (JBVAD::PAH):
{        Original version.
{     22-SEP-1992 (PCTR):
{        Starlink release.
{     2-FEB-1993 (PCTR):
{        Added DEFHELP commands.
{     10-JUN-1994 (PDRAPER):
{        Changed to UNIX format with INSTALL targets for installation.
{        Added various ACCEPTS to control behaviour more precisely.

{  Bugs:

{-

{  Basic Command definitions.
define ann(otate)  $PONGO_BIN/pongo_mon
define arc	   $PONGO_BIN/pongo_mon
define avedat      $PONGO_BIN/pongo_mon
define begpongo    $PONGO_BIN/pongo_mon
define box(frame)  $PONGO_BIN/pongo_mon
define ccmath      $PONGO_BIN/pongo_mon
define change      $PONGO_BIN/pongo_mon
define clear       $PONGO_BIN/pongo_mon
define clog        $PONGO_BIN/pongo_mon cllog
define curse       $PONGO_BIN/pongo_mon
define drawp(oly)  $PONGO_BIN/pongo_mon
define ellipses    $PONGO_BIN/pongo_mon
define endpongo    $PONGO_BIN/pongo_mon
define errorbar    $PONGO_BIN/pongo_mon
define fitc(urve)  $PONGO_BIN/pongo_mon
define fitl(ine)   $PONGO_BIN/pongo_mon
define getp(oint)  $PONGO_BIN/pongo_mon
define gpoints     $PONGO_BIN/pongo_mon
define grid        $PONGO_BIN/pongo_mon
define gt_circle   $PONGO_BIN/pongo_mon
define inq(uire)   $PONGO_BIN/pongo_mon
define lab(el)     $PONGO_BIN/pongo_mon
define palet(te)   $PONGO_BIN/pongo_mon
define paper       $PONGO_BIN/pongo_mon
define plotf(un)   $PONGO_BIN/pongo_mon
define ploth(ist)  $PONGO_BIN/pongo_mon
define prim        $PONGO_BIN/pongo_mon
define pvect       $PONGO_BIN/pongo_mon
define readf       $PONGO_BIN/pongo_mon
define vect        $PONGO_BIN/pongo_mon
define viewport    $PONGO_BIN/pongo_mon
define world       $PONGO_BIN/pongo_mon
define write(i)    $PONGO_BIN/pongo_mon
define wtext       $PONGO_BIN/pongo_mon

{  Aliases for commands.
defstring adv(ance)     clear screen accept
defstring bin           plothist b
defstring conn(ect)     gpoints c
defstring device        begplot
defstring dlim(its)     world data
defstring draw          prim d
defstring erase         clear screen accept
defstring errx          errorbar symerr x
defstring erry          errorbar symerr y
defstring hist(ogram)   plothist h
defstring lim(its)      world given
defstring mark          prim k
defstring move          prim m
defstring poi(nts)      gpoints p
defstring size(plot)    gpoints s
defstring text          wtext s
defstring xerr          errorbar symerr x
defstring xlin(ear)     ccmath x=index accept
defstring xlog(arithm)  clog x accept
defstring yerr          errorbar symerr y
defstring ylin(ear)     ccmath y=index accept
defstring ylog(arithm)  clog y accept

{  change ALIASES.
defstring expa(nd)   change accept cheight=
defstring font       change accept font=
defstring lt(ype)    change accept linesty=
defstring lwe(ight)  change accept linewid=
defstring pen        change accept colour=
defproc   fillsty    $PONGO_BIN/pongo_proc.icl fillsty

{  Column setting aliases.
defstring data             setglobal pongo_data
defstring exc(olumn)       setglobal pongo_excol
defstring eyc(olumn)       setglobal pongo_eycol
defstring labc(olumn)      setglobal pongo_labcol
defstring pcol(umn)        setglobal pongo_symcol
defstring symc(olumn)      setglobal pongo_symcol
defproc resetp(ongo)       $PONGO_BIN/pongo_proc.icl rpglobals
defproc showp(ongo)        $PONGO_BIN/pongo_proc.icl spglobals
defstring xc(olumn)        setglobal pongo_xcol
defstring yc(olumn)        setglobal pongo_ycol
defstring zc(olumn)        setglobal pongo_zcol

{  Projection control commands
defproc   setproj          $PONGO_BIN/pongo_proc.icl setproj


{  Viewport setting aliases.
defstring vport   viewport ndc
defstring vsize   viewport inches
defstring vstand  viewport standard
defstring wnad    viewport adjust

{  Some standard viewports.
defproc vp_bh   $PONGO_BIN/pongo_proc.icl
defproc vp_bl   $PONGO_BIN/pongo_proc.icl
defproc vp_br   $PONGO_BIN/pongo_proc.icl
defproc vp_th   $PONGO_BIN/pongo_proc.icl
defproc vp_tl   $PONGO_BIN/pongo_proc.icl
defproc vp_tr   $PONGO_BIN/pongo_proc.icl

{  WWW help
defstring pongowww !$PONGO_BIN/pongowww

{  BEGPLOT and ENDPLOT procedure definitions.
defproc begp(lot)  $PONGO_BIN/pongo_proc.icl begplot
defproc endp(lot)  $PONGO_BIN/pongo_proc.icl endplot

{  Some procedures to make ADAM PONGO look more like stand-alone PONGO.
defproc degtor     $PONGO_BIN/pongo_proc.icl
defproc mtext      $PONGO_BIN/pongo_proc.icl
defproc ptext      $PONGO_BIN/pongo_proc.icl
defproc ptinfo     $PONGO_BIN/pongo_proc.icl
defproc radiate    $PONGO_BIN/pongo_proc.icl
defproc rtodeg     $PONGO_BIN/pongo_proc.icl
defproc xoff(set)  $PONGO_BIN/pongo_proc.icl xoffset
defproc xscale     $PONGO_BIN/pongo_proc.icl
defproc yoff(set)  $PONGO_BIN/pongo_proc.icl yoffset
defproc yscale     $PONGO_BIN/pongo_proc.icl
defproc zscale     $PONGO_BIN/pongo_proc.icl

{  Pivate PONGO procedures.
defproc setponglob    $PONGO_BIN/pongo_proc.icl

{  The PONGO help library.
defhelp pongo        $PONGO_HELP pongo
defhelp classified   $PONGO_HELP Classified
defhelp examples     $PONGO_HELP Examples
defhelp introduction $PONGO_HELP Introduction
defhelp procedures   $PONGO_HELP Procedures
defhelp advance      $PONGO_HELP advance
defhelp annotate     $PONGO_HELP annotate
defhelp arc          $PONGO_HELP arc
defhelp avedat       $PONGO_HELP avedat
defhelp begplot      $PONGO_HELP begplot
defhelp bin          $PONGO_HELP bin
defhelp boxframe     $PONGO_HELP boxframe
defhelp ccmath       $PONGO_HELP ccmath
defhelp change       $PONGO_HELP change
defhelp clear        $PONGO_HELP clear
defhelp clog         $PONGO_HELP clog
defhelp connect      $PONGO_HELP connect
defhelp curse        $PONGO_HELP curse
defhelp data         $PONGO_HELP data
defhelp degtor       $PONGO_HELP degtor
defhelp device       $PONGO_HELP device
defhelp dlimits      $PONGO_HELP dlimits
defhelp draw         $PONGO_HELP draw
defhelp drawpoly     $PONGO_HELP drawpoly
defhelp ellipses     $PONGO_HELP ellipses
defhelp endplot      $PONGO_HELP endplot
defhelp erase        $PONGO_HELP erase
defhelp errorbar     $PONGO_HELP errorbar
defhelp errx         $PONGO_HELP errx
defhelp erry         $PONGO_HELP erry
defhelp excolumn     $PONGO_HELP excolumn
defhelp expand       $PONGO_HELP expand
defhelp eycolumn     $PONGO_HELP eycolumn
defhelp fillsty      $PONGO_HELP fillsty
defhelp fitcurve     $PONGO_HELP fitcurve
defhelp fitline      $PONGO_HELP fitline
defhelp font         $PONGO_HELP font
defhelp getpoint     $PONGO_HELP getpoint
defhelp gpoints      $PONGO_HELP gpoints
defhelp grid         $PONGO_HELP grid
defhelp gt_circle    $PONGO_HELP gt_circle
defhelp histogram    $PONGO_HELP histogram
defhelp inquire      $PONGO_HELP inquire
defhelp labcolumn    $PONGO_HELP labcolumn
defhelp label        $PONGO_HELP label
defhelp limits       $PONGO_HELP limits
defhelp ltype        $PONGO_HELP ltype
defhelp lweight      $PONGO_HELP lweight
defhelp mark         $PONGO_HELP mark
defhelp move         $PONGO_HELP move
defhelp mtext        $PONGO_HELP mtext
defhelp palette      $PONGO_HELP palette
defhelp paper        $PONGO_HELP paper
defhelp pcolumn      $PONGO_HELP pcolumn
defhelp pen          $PONGO_HELP pen
defhelp plotfun      $PONGO_HELP plotfun
defhelp plothist     $PONGO_HELP plothist
defhelp points       $PONGO_HELP points
defhelp prim         $PONGO_HELP prim
defhelp ptext        $PONGO_HELP ptext
defhelp ptinfo       $PONGO_HELP ptinfo
defhelp pvect        $PONGO_HELP pvect
defhelp radiate      $PONGO_HELP radiate
defhelp readf        $PONGO_HELP readf
defhelp resetpongo   $PONGO_HELP resetpongo
defhelp rtodeg       $PONGO_HELP rtodeg
defhelp showpongo    $PONGO_HELP showpongo
defhelp sizeplot     $PONGO_HELP sizeplot
defhelp symcolumn    $PONGO_HELP symcolumn
defhelp text         $PONGO_HELP text
defhelp vect         $PONGO_HELP vect
defhelp viewport     $PONGO_HELP viewport
defhelp vport        $PONGO_HELP vport
defhelp vp_bh        $PONGO_HELP vp_bh
defhelp vp_bl        $PONGO_HELP vp_bl
defhelp vp_br        $PONGO_HELP vp_br
defhelp vp_th        $PONGO_HELP vp_th
defhelp vp_tl        $PONGO_HELP vp_tl
defhelp vp_tr        $PONGO_HELP vp_tr
defhelp vsize        $PONGO_HELP vsize
defhelp vstand       $PONGO_HELP vstand
defhelp wnad         $PONGO_HELP wnad
defhelp world        $PONGO_HELP world
defhelp writei       $PONGO_HELP writei
defhelp wtext        $PONGO_HELP wtext
defhelp xcolumn      $PONGO_HELP xcolumn
defhelp xerr         $PONGO_HELP xerr
defhelp xlinear      $PONGO_HELP xlinear
defhelp xlogarithm   $PONGO_HELP xlogarithm
defhelp xoffset      $PONGO_HELP xoffset
defhelp xscale       $PONGO_HELP xscale
defhelp ycolumn      $PONGO_HELP ycolumn
defhelp yerr         $PONGO_HELP yerr
defhelp ylinear      $PONGO_HELP ylinear
defhelp ylogarithm   $PONGO_HELP ylogarithm
defhelp yoffset      $PONGO_HELP yoffset
defhelp yscale       $PONGO_HELP yscale
defhelp zcolumn      $PONGO_HELP zcolumn
defhelp zscale       $PONGO_HELP zscale

{  Switch off ICL procedure parameter checking.
SET NOCHECKPARS

{  Name of the tutorial dataset.
TUTORIAL_DATA="INSTALL_EXAMPLES/tutorial.dat"
{  Name of the dor.sdf dataset
DOR_DATA="INSTALL_EXAMPLES/dor"
{  SWP dataset
SWP_DATA="INSTALL_EXAMPLES/swp3196.lap"

{  PONGO login banner.
PRINT ""
PRINT "   PONGO version PKG_VERS available."
PRINT ""
PRINT "   Use HELP PONGO or pongowww for help"
{ $Id$
