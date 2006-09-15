/*
*+
*  Name:
*     smf_close_smfDream

*  Purpose:
*     Free all resources associated with a smfDream structure

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     smf_close_smfDream( smfDream **dream, int * status );

*  Arguments:
*     dream = smfDream ** (Given and Returned)
*        Pointer to smfDream struct to be freed
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function frees all resources associated with a given
*     smfDream, analagous to smf_close_file.

*  Notes:

*  Authors:
*     Andy Gibb (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-07-28 (AGG):
*        Initial version
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 University of British Columbia. All Rights
*     Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* System includes */
#include <stdlib.h>
#include <string.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_close_smfDream"

void smf_close_smfDream( smfDream **dream, int * status ) {

  if (*status != SAI__OK) return;

  if ( *dream != NULL ) {
    /* Free the pointers associated with the smfDream */
    smf_free( (*dream)->gridwts, status );
    smf_free( (*dream)->invmatx, status );
    smf_free( *dream, status );
    
    *dream = NULL;
  } else {
    if ( *status == SAI__OK ) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Attempt to free a NULL smfDream (possible programming error)", status);
    }
  }
}
