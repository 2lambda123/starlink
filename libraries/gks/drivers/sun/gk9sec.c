/*
 * gk9sec.c --- Module for opening and closing the echo area.
 *
 * METHOD
 * ------
 *
 * gk9soe - Open echo area
 *
 *	Various WW parameters are saved, viz., Line mode, font, current pos.
 *	A new window is created which is used for echoing. 
 *
 * gk9sce - Close echo area
 *
 *	The reverse of the above is performed.
 *
 * Written by: A C Arnold, University of Manchester Computer Graphics Unit,
 * Oxford Road, Manchester M13 9PL Tel: 061-273 7121 x 5405 
 *
 * Modification History
 * --------------------
 *
 *     02/03/87 ACA  Module created.
 *     18/03/87 TAW  Changed names to gk9soe and gk9sce.
 *     28/04/87 PJWR Modified so that saved area isn't cleared.
 *     29/04/87 PJWR Added flag for optional clearing of echo area.
 *     12/10/87 ACA  Modified to create a sub-window. Removed flag, added title
 *                   argument.
 *     10/12/87 PJWR Made a number of modifications for integration:
 *                     Colour save/set/restore code added.
 *                     Cursor setting code added to avoid problems with ww
 *                     default cursor on colour displays.
 *                     Adjustment of echoarea modified to allow for workstation
 *                     window position.
 */
 
#include "./varinc/wwinfo.h"
#include "../../system/include/f77_type.h"
#include "../../system/include/gkdt.h"
#include "../../system/include/gkwca.h"
#include "../../system/include/gkwdt.h"

static int line_mode;				/* Saved line mode */
static int fg_colour;				/* Saved foreground colour */

void gk9soe(echoarea, title)			/* Open echo area */
  box echoarea;
  char *title;
{
  static char					/* Default cursor */
    gks_cursor[] = 
    {
      WWXOR, 0, 0, 0, 0,
      0, 16, 0, 16, 
      0377, 0200, 0377,    0, 0376,    0, 0374,    0,
      0376,    0, 0377,    0, 0357, 0200, 0307, 0300,
      0203, 0340,   01, 0360,    0, 0370,    0, 0174,
	 0,  076,    0,  037,    0,  016,    0,   04
    }; /* ww style */

  f77_integer
    gk9scc_(),					/* To map colours */
    one = 1;					/* Constant for the above */

  cursor
    *cudecode();				/* To decode for custack() */

  winstack(WWPUSH);				/* Save window */
  bmstack(WWPUSH);				/* Save bitmap */
  lnstack(WWPUSH);				/* Save current pen position */
  ftstack(WWPUSH);				/* Save current font info */
  line_mode = dd->d_line;			/* Save line mode */
  fg_colour = dd->d_fore;			/* Save foreground colour */

  ddfont = ftload(NULLPTR(char));		/* Load the default font */
  dd->d_line = WWXOR;				/* Set XOR mode */
  dd->d_fore = gk9scc_(&one);			/* Set foreground colour */

  /*
   * Adjust echo area to allow for frame size and put into parent frame
   * coordinates.  This puts the echo windows bitmap where the echo area
   * should be.
   */

  echoarea.b_left += ddwin->w_xrel;
  echoarea.b_right += ddwin->w_xrel + 10;
  echoarea.b_top += ddwin->w_yrel;
  echoarea.b_bottom += ddwin->w_yrel + ddfont->f_height + 7;

  ddwin=wwxget(echoarea,2,title,0);		/* Create a window */
  ddbm=ddwin->w_bm;				/* Set default bitmap */
  if(gkywdt_.kpci[gkywca_.kwkix - 1] > 2)	/* Set up cursor */
    gks_cursor[0] = WWOR;
  custack(cudecode(gks_cursor, ENWWSTYLE), WWSET);
}
 
void gk9sce()					/* Close echo area */
{
  dd->d_fore = fg_colour;			/* Restore foreground colour */
  dd->d_line = line_mode;			/* Restore line mode */
  wwfree(ddwin);				/* Free the window */
  ftstack(WWPOP);				/* Restore font info */
  lnstack(WWPOP);				/* Restore pen position */
  bmstack(WWPOP);				/* Restore default bitmap */
  winstack(WWPOP);				/* Restore default window */
}
