/*+
 *  Name:
 *     emsBegin

 *  Purpose:
 *     Begin a new error reporting environment.

 *  Language:
 *     Starlink ANSI C

 *  Invocation:
 *     emsBegin( status )

 *  Description:
 *     This function provides a C interface for the Error Message 
 *     Service routine EMS_BEGIN (written in Fortran).

 *  Arguments:
 *     status = int * (Returned)
 *        The global status value.

*  Copyright:
*     Copyright (C) 1990 Science & Engineering Research Council.
*     Copyright (C) 1999, 2001 Central Laboratory of the Research Councils.
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
 *     PCTR: P.C.T. Rees (STARLINK)
 *     AJC: A.J. Chipperfield (STARLINK)
 *     RTP: R.T.Platon (STARLINK)
 *     {enter_new_authors_here}

 *  History:
 *     8-NOV-1990 (PCTR):
 *        Original version.
 *     13-MAY-1999 (AJC):
 *        Renamed from ems_begin_c
 *     14-FEB-2001 (RTP):
 *        Rewritten in C from Fortran routine EMS_BEGIN
 *     19-MAR-2001 (AJC):
 *        Correct testing and resetting of status - and comment.
 *     {enter_further_changes_here}

 *  Bugs:
 *     {note_any_bugs_here}

 *-
 */

/* Include Statements: */
#include "sae_par.h"
#include "ems_par.h"                   /* ems_ public constant definitions */
#include "ems.h"                       /* ems_ function prototypes */
#include "ems_sys.h"                   /* ems_ private macro definitions */
#include "ems_msgtb.h"                 /* Message token table */

/* Function Definitions: */
void emsBegin( int *status ){

   int istat, lstat;

   TRACE("emsBegin");
   DEBUG("emsBegin","msglev = %d", msglev );

   if (*status != SAI__OK ) {
/*  If status is not OK,    
*   Check if there are any error messages pending output */
      emsStat( &istat );

/*  If the last reported status is SAI__OK, then no error messages are pending
*   so report an error to this effect */
      if ( istat == SAI__OK ) {
          emsMark();
          lstat = *status;
          emsRep( "EMS_BEGIN_NOREP",
            "ERR_/EMS_BEGIN: "
            "STATUS set with no error report (improper use of EMS).",
            &lstat );
          emsRlse();
      }
   }
   if ( msglev <= EMS__MXLEV ) msgbgs[ msglev ] = *status;
   emsMark();
   *status = SAI__OK;

   return;
}
