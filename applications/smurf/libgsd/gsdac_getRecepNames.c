/*
*+
*  Name:
*     gsdac_getRecepNames

*  Purpose:
*     Return the names of the receptors used in this observation.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     gsdac_getRecepNames ( const gsdVars *gsdVars, char *recepNames[], 
*                           int recepFlags[], int *status );

*  Arguments:
*     gsdVars = const gsdVars* (Given)
*        GSD headers and arrays
*     recepNames = char*[] (Given and Returned)
*        Receptor names
*     recepFlags = int[] (Given and Returned)
*        Flags for which receptors were used
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Determines which receiver and receptors were in use during this
*     observation.

*  Authors:
*     Jen Balfour (JAC, UBC)
*     {enter_new_authors_here}

*  History:
*     2008-03-27 (JB):
*        Original.
*     2008-03-31 (JB):
*        Check for how many receptors for each receiver. 

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* Standard includes */
#include <string.h>
#include <stdio.h>

/* STARLINK includes */
#include "sae_par.h"
#include "mers.h"

/* SMURF includes */
#include "gsdac.h"

#define FUNC_NAME "gsdac_getRecepNames"

void gsdac_getRecepNames ( const gsdVars *gsdVars, char *recepNames[], 
                           int recepFlags[], int *status )
{

  /* Local variables */
  int i = 0;
  char frontendLetter;

  /* Check inherited status */
  if ( *status != SAI__OK ) return;

  /* Check to see which receptors were actually used. */
  recepFlags[0] = 0;
  recepFlags[1] = 0;
  for ( i = 0; i < gsdVars->nBESections; i++ ) {
    if ( gsdVars->mixNums[i] == 1 )
      recepFlags[0] = 1;
    else if ( gsdVars->mixNums[i] == 2 )
      recepFlags[1] = 1;
    else {
      *status = SAI__ERROR;
      errRep ( FUNC_NAME, "Couldn't obtain receptor names.", 
                 status ); 
      return; 
    }
  }

  /* First get the letter of the frontend. */
  frontendLetter = gsdVars->frontend[2];

  /* If this is receiver W, check if this is C band or
     D band. */
  if ( frontendLetter == 'W' ) {

    if ( gsdVars->centreFreqs[0] < 600.0 )
      frontendLetter = 'C';
    else
      frontendLetter = 'D';

  }

  /* Get the names of the receptors for this frontend. */
  if ( recepFlags[0] == 1 ) {

    sprintf ( recepNames[0], "%cA", frontendLetter );

    if ( recepFlags[1] == 1 )
      sprintf ( recepNames[1], "%cB", frontendLetter );
    
  } else {

    if ( recepFlags[1] = 1 ) {

      sprintf ( recepNames[0], "%cB", frontendLetter );

    }

  }

}

