/*
*+
*  Name:
*     ccd1_linflt
*
*  Purpose:
*     If running under Linux then set the FPU into double precision mode.
* 
*  Description:
*     (From g77 info file, we're trying to avoid -ffloat-store) 
*     If your program depends on exact IEEE 754 floating-point
*     handling it may help on some systems--specifically x86 or m68k
*     hardware--to use the `-ffloat-store' option or to reset the
*     precision flag on the floating-point unit.
*
*     However, it might be better simply to put the FPU into double
*     precision mode and not take the performance hit of
*     `-ffloat-store'.  On x86 and m68k GNU systems you can do this
*     with a technique similar to that for turning on floating-point
*     exceptions. The control word could be set to double precision
*     by replacing the `__setfpucw' call with one like this: 
*
*      __setfpucw ((_FPU_DEFAULT & ~_FPU_EXTENDED) | _FPU_DOUBLE);
*
*     (It is not clear whether this has any effect on the operation
*     of the GNU maths library, but we have no evidence of it
*     causing trouble.) 
*
*     On systems other than GNU/linux, this routine is defined as a
*     no-operation.
*
*  Notes:
*     This routine is invoked on linux, since at RedHat 7, there 
*     appears to be a serious numerical bug which turns up when the
*     -O and -ffloat-store flags are used together.  If only -O is
*     used, numerics are still not very good (i.e. they diverge from
*     the sun and alpha results).  Using this routine as well as
*     -O, but without -ffloat-store, seems to restore linux numerical
*     results to about right.
*
*   Arguments:
*      none
*
*   Authors:
*      PWD: P.W. Draper (STARLINK - Durham University)
*      MBT: Mark Taylor (Starlink)
*
*   History:
*      07-DEC-2001 (PWD):
*         Original version.
*      10-DEC-2001 (MBT):
*         Modified the invocation to avoid __setfpucw function withdrawn
*         in glibc 2.1.
*-
*/
#include "cnf.h"
#include "f77.h"
#ifdef __GNUC__ && #cpu (i386)

#include <fpu_control.h>

F77_SUBROUTINE(ccd1_linflt)() 
{
   fpu_control_t cw = (_FPU_DEFAULT & ~_FPU_EXTENDED) | _FPU_DOUBLE;
   _FPU_SETCW(cw);
}
#else
F77_SUBROUTINE(ccd1_linflt)()
{
}
#endif
/* $Id$ */
