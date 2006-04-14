/*
*+
*  Name:
*     EMS1KTOK

*  Purpose:
*     Clear the message token table.

*  Language:
*     Starlink ANSI C

*  Invokation:
*     ems1Ktok()

*  Description:
*     Clear all the message tokens at the current context level.

*  Algorithm:
*     -  Set the token count to that of previous context level.

*  Copyright:
*     Copyright (C) 1982 Science & Engineering Research Council.
*     Copyright (C) 2001 Central Laboratory of the Research Councils.
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
*     JRG: Jack Giddings (UCL)
*     SLW: Sid Wright (UCL)
*     PCTR: P.C.T. Rees (STARLINK)
*     RTP: R.T. Platon (STARLINK)
*     AJC: A.J.Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     3-JAN-1982 (JRG):
*        Original FORTRAN version.
*     14-FEB-2001 (RTP):
*        Rewritten in C based on the Fortran routine EMS1_PFORM
*      1-OCT-2001 (AJC):
*        Remove setting high-water mark (it's already set by ems1Stok)
*        - this allow emsRenew to work properly.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/

#include "ems1.h"                    /* EMS1_ Internal functions */
#include "ems_par.h"                 /* EMS_ public constants */
#include "ems_sys.h"                 /* EMS_ private constants */

/*  Global Variables: */
#include "ems_toktb.h"               /* Message token table */

void ems1Ktok ( void ) {

   TRACE("ems1Ktok");

/*  Clear the token table at the current context. */
   if ( tokmrk > 1 ) {
      tokcnt[ tokmrk ] = tokcnt[ tokmrk - 1 ];
   } else {
      tokcnt[ tokmrk ] = 0;
   }
   return;
}
