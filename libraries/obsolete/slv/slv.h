/*
*+
*  Name:
*     slv.h

*  Purpose:
*     Public SLV definitions.

*  Copyright:
*     Copyright (C) 1997 Central Laboratory of the Research Councils.
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
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     8-MAY-1997 (RFWS):
*        Original version.
*     {enter_changes_here}

*-
*/

#if !defined( SLV_INCLUDED )
#define SLV_INCLUDED 1

#include <sys/types.h>

void SlvKill( pid_t, int * );
void SlvKillW( pid_t, int * );
void SlvWaitK( pid_t, int, int * );
#endif
