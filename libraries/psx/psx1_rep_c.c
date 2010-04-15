#include "ems.h"		 /* EMS function prototypes		    */
#include "psx1.h"

void psx1_rep_c( const char *param, const char *text, int *status )

/*
*+
*  Name:
*     psx1_rep_c

*  Purpose:
*     Provide a PSX wrap up for ems_rep_c

*  Language:
*     ANSI C

*  Invocation:
*     psx1_rep_c( param, text, status )

*  Description:
*     Provide a wrap up for the C callable EMS routine ems_rep_c so that
*     error reporting can easily be replaced with calls to something
*     other than EMS should the need arise.

*  Arguments:
*     char *param (Given)
*     char *text (Given)
*     int *status (Given and Returned via Pointer)

*  External Routines Used:
*     EMS:
*        emsRep

*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council
*     Copyright (C) 2008 Science and Technology Facilities Council.
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
*     PMA: Peter Allan (Starlink, RAL)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     15-APR-1991 (PMA):
*        Original version.
*     16-SEP-2008 (TIMJ):
*        Use modern interface to emsRep
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
------------------------------------------------------------------------------
*/


{
   emsRep( param, text, status );
}
