/*
**
**  INCLUDE FILES
**
*/

#include <string.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include "gwm_err.h"
#include "gwm.h"

int GWM_SetFgCol( Display *display, Window win_id, char *fg)
/*
*+
*  Name :
*     GWM_SetFgCol
*
*  Purpose :
*     Set foreground colour property
*
*  Language :
*     C
*
*  Invocation :
*     status = GWM_SetFgCol(display, win_id, fg);
*
*  Description :
*     The value of the GWM_foreground property is set on the window.
*
*  Arguments :
*     display = *Display (given)
*        Display id
*     win_id = Window (given)
*        Window id
*     fg = char (given)
*        Foreground colour specification
*
*  Authors :
*     DLT: David Terrett (Starlink RAL)
*     {enter_new_authors_here}
*
*  History :
*      3-APR-1992 (DLT):
*        Orignal version
*     {enter_changes_here}
*
*  Bugs:
*     {note_any_bugs_here}
*-
*/
{
    int status;
    Atom atom;
    XColor color;
        
/*
**  Check that the colour specification is understood by the server
*/
    status = XParseColor( display, DefaultColormapOfScreen(
        DefaultScreenOfDisplay( display ) ), fg, &color);
    if (!status) return GWM_BAD_COLOUR;
 
/*	  
**  Foreground Colour
*/	  
    atom = XInternAtom(display, "GWM_foreground", False );
    if (!atom) return GWM_NO_FOREGROUND;

    XChangeProperty( display, win_id, atom, XA_STRING, 8, PropModeReplace,
        (unsigned char*)fg, strlen(fg) );
 
    return GWM_SUCCESS;
}
