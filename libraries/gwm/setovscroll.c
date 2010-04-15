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

int GWM_SetOvScroll( Display *display, Window win_id, int xoffset, int yoffset)
{
/*
*+
*  Name:
*     GWM_SetOvScroll
*
*  Purpose:
*     Set overlay scroll offset
*
*  Language:
*     C
*
*  Invocation:
*     status = GWM_SetOvScroll( display, win_id, xoffset, yoffset);
*
*  Description:
*     The values of the GWM_x_ov_offset and GWM_y_ov_offset window
*     properties are replaced by the new values.
*
*  Arguments:
*     display = *Display (given)
*        Display id
*     win_id = Window (given)
*        Window id
*     xoffset = int (given)
*        New overlay scroll value in x
*     yoffset = int (given)
*        New overlay scroll value in y
*
*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DLT: David Terrett (Starlink RAL)
*     {enter_new_authors_here}
*
*  History:
*      19-NOV-1991 (DLT):
*        Orignal version
*     {enter_changes_here}
*
*  Bugs:
*     {note_any_bugs_here}
*-
*/
    Atom atom;
    long local_offset;

    atom = XInternAtom(display, "GWM_x_ov_offset", False );
    if (!atom) return GWM_NO_OVOFFSET;

    local_offset = (long)xoffset;
    XChangeProperty( display, win_id, atom, XA_INTEGER, 32, PropModeReplace,
        (unsigned char*)(&local_offset), 1 );

    atom = XInternAtom(display, "GWM_y_ov_offset", False );
    if (!atom) return GWM_NO_OVOFFSET;

    local_offset = (long)yoffset;
    XChangeProperty( display, win_id, atom, XA_INTEGER, 32, PropModeReplace,
        (unsigned char*)(&local_offset), 1 );

    return GWM_SUCCESS;
}
