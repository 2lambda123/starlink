/*
*+
*  Name:
*     smf_history_add

*  Purpose:
*     Add a history comment

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_history_add(  smfData * data, const char * appl,
*                        const char * text, int * status );

*  Arguments:
*     data = const smfData* (Given)
*        Data struct to obtain file identifier from.
*     appl = const char * (Given)
*        Name of "application" to store in file. If NULL, the 
*        default application name will be used.
*     text = const char * (Given)
*        Descriptive text to write to the file. MERS message tokens
*        can be included. Text will be truncated at NDF__SZHMX characters.
*     status = int* (Given and Returned)
*        Pointer to global status. Will be bad on return if this smfData
*        is not associated with a file.

*  Description:
*     This function stores additional history information to a file.
*     It should be used primarily to tag activities that have been
*     performed on the data which can not be derived from the application
*     name. For example, since extinction correction may be performed
*     by both EXTINCTION and MAKEMAP it is important that a flag
*     can be written to the file to indicate that the data have been
*     extinction corrected.

*  Authors:
*     Andy Gibb (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-04-21 (AGG):
*        Initial version, copied from smf_history_write
*     2006-07-06 (AGG):
*        Check for presence of HISTORY component in NDF before
*        attempting to write

*  Notes:
*     - SMURF subroutines should choose history "application" names
*       that are distinct from actual application names but describe
*       functionality. eg SMF_EXTINCTION, SMF_FLATFIELD rather than
*       "EXTINCTION" and "FLATFIELD".
*     - Calls smf_history_write for writing history to a file
*     - See also smf_history_write

*  Copyright:
*     Copyright (C) 2006 Particle Physics and Astronomy Research
*     Council and the University of British Columbia. All Rights
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

/* System includes */
#include <string.h>

/* Starlink includes */
#include "ast.h"
#include "sae_par.h"
#include "mers.h"

/* SMURF includes */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

/* Simple default string for errRep */
#define FUNC_NAME "smf_history_add"

void smf_history_add(  smfData* data, const char * appl, 
			const char * text, int *status) {

  smfFile *file = NULL; /* data->file */
  int done;             /* Flag to denote whether history entry has been added */
  AstKeyMap *history;   /* AstKeyMap storing history information */
  int state = 0;        /* Flag to denote whether history component exists in NDF */

  /* Check entry status */
  if (*status != SAI__OK) return;

  /* Check that we have a smfData */
  if ( data == NULL ) {
    *status = SAI__ERROR;
    errRep( FUNC_NAME,
	    "Supplied smfData is a NULL pointer. Possible programming error.",
	    status);
    return;
  }

  /* If we have a file, write the history entry into the file ONLY if
     the history component already exists.  */
  file = data->file;
  if ( file !=NULL ) {
    ndfState( file->ndfid, "HISTORY", &state, status );
    if ( state == 1 ) {
      smf_history_write( data, appl, text, status);
    }
  }

  /* Now add entry to the history AstKeyMap if not already present */
  if ( data->history == NULL ) {
    history = astKeyMap("");
    data->history = history;
    astMapPut0I( data->history, appl, 1, "" );
  } else if ( !astMapGet0I( data->history, appl, &done ) ) {
    astMapPut0I( data->history, appl, 1, "" );
  }

}
