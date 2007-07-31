/*
*+
*  Name:
*     smf_close_related

*  Purpose:
*     Close a group of related files

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     SMURF subroutine

*  Invocation:
*     smf_close_related( smfArray **relfiles, int *status );

*  Arguments:
*     relfiles = smfArray** (Given and Returned)
*        Pointer to smfArray containing files to be closed
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:

*     This routine retrieves all of the smfDatas stored in the given
*     smfArray and frees up the resources for each one in turn. The
*     input smfArray is set to NULL on success.

*  Notes:
*      - This is the companion routine to smf_open_related.c

*  Authors:
*     Andy Gibb (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-07-07 (AGG):
*        Initial version

*  Copyright:
*     Copyright (C) 2006 University of British Columbia.  All Rights
*     Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
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

#if HAVE_CONFIG_H
#include <config.h>
#endif

/* System includes */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "msg_par.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_close_related"

void smf_close_related ( smfArray **relfiles, int *status ) {

  /* Local variables */
  int i;                    /* Loop counter */
  int nrelated;
  smfData *data;

  if ( *status != SAI__OK ) return;

  /* Number of data files */
  nrelated = (*relfiles)->ndat;

  /* Loop over the number of files and close each smfData */
  for (i=0; i<nrelated; i++) {
    data = ((*relfiles)->sdata)[i];
    if ( data != NULL ) {
      smf_close_file( &data, status );
    }
  }
  smf_free( *relfiles, status );
  /* Just to be safe - set it to NULL */
  *relfiles = NULL;
}
