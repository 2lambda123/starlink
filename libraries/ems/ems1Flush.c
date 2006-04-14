/*
*+
*  Name:
*     EMS1FLUSH

*  Purpose:
*     Flush the current error context.

*  Language:
*     Starlink ANSI C

*  Invocation:
*     ems1Flush( status )

*  Description:
*     This subroutien ensures that all pending error messages in the 
*     current error context have been output to the user. The status 
*     argument is reset to SAI__OK.

*  Arguments:
*     status = int* (Returned)
*        The global status value: it is set to SAI__OK on return if the error
*        message output is successful; if not, it is set to EMS_OPTER.

*  Algorithm:
*     -  Call EMS1PRERR, which is guaranteed to get to user.
*     -  Call EMSANNUL to annul the error table.

*  Copyright:
*     Copyright (C) 1983 Science & Engineering Research Council.
*     Copyright (C) 2001 Central Laboratory of the Research Councls.
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
*     BDK: Dennis Kelly (ROE)
*     RFWS: R.F. Warren-Smith (STARLINK)
*     PCTR: P.C.T. Rees (STARLINK)
*     RTP: R.T. Platon (STARLINK)
*     AJC: A.J.Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     3-JAN-1983 (JRG):
*        Original FORTRAN version.
*     14-FEB-2001 (RTP)
*        Rewritten in C based on the Fortran routine EMS1_PFORM
*      5-MAR-2001 (AJC):
*        Correct loop test to '<= iend'
*        Use strcat not ems1Putc
*        Remove trailing blanks from blank mes
*     13-AUG-2001 (AJC):
*        #include ems.h, ems1.h
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/

#include "sae_par.h"              /* Standard SAE constants */
#include "ems.h"                  /* EMS function prototypes */
#include "ems1.h"                 /* EMS1 function prototypes */
#include "ems_par.h"              /* EMS_ public constants */
#include "ems_sys.h"              /* EMS_ private constants */

#include "ems_msgtb.h"            /* Error message table */

/*  Local Constants: */
#define MAXTAB 3                  /* Maximum tab index */

void ems1Flush( int *status ) {
   char line[ EMS__SZMSG + MAXTAB + 1];  /*  Constructed output line */
   char tabs[MAXTAB + 1 ];               /* Tab string */

   int i;                         /* Loop index */
   int iend;                      /* Ending loop value */
   int istart;                    /* Starting loop value */
   int istat = SAI__OK;           /* Local status */
   int lstat = SAI__OK;           /* Local status */
   short tmprvl;                  /* Temporary storage for MSGRVL */

   TRACE("ems1Flush");

/*  Find the first message to flush. */
   if ( msgmrk > EMS__BASE ) {
      istart = msgcnt[ msgmrk - 1 ] + 1;
   } else {
      istart = 1;
   }

/*  Find the last message. */
   iend = msgcnt[ msgmrk ];

/*  If there are messages to flush, then loop through them. */
   strcpy( tabs, "!! " );

   if ( iend >= istart ) {
      for ( i = istart; i <= iend; i++ ) {
         strcpy( line, tabs );

/*        Construct the output line and send it. */
         if ( msglen[i] > 0 ) {
            strncat( line, msgstr[ i ], EMS__SZMSG );
         } else {
/*        For compatibility with Fortran version,
*         remove blank from tabs if blank message. */
            line[2] = '\0';
         }
         ems1Prerr( line, &istat );

/*        Check the returned status. */
         if ( istat != SAI__OK ) lstat = istat;

/*        Only the first message gets the '!! ' prefix. */
         strcpy( tabs, "!  " );
      }

   } else {

/*     If there are no messages to flush, then deliver a warning. */
         strcpy( line, tabs );
         sprintf( line, "%s No error to report (EMS fault).", line );
         ems1Prerr( line, &lstat );
   }

/*  If there are no errors, annul the error table at the current context 
*  level; if the error context is at the base level (i.e. level 1), 
*  annul the current context but return the status value; else return
*  the status value. Switch off MSGRVL whilst doing it to avoid re-flushing
*  in ANNUL. */
   tmprvl = msgrvl;
   msgrvl = FALSE;
   if ( lstat == SAI__OK ) {
      emsAnnul( status );
   } else {
      if ( msgmrk == EMS__BASE ) {
         *status = lstat;
         emsAnnul( &lstat );
      } else {
         *status = lstat;
      }
   }
   msgrvl = tmprvl;
    
   return;
}
