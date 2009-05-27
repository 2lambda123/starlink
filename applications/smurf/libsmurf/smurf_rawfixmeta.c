/*
*+
*  Name:
*     RAWFIXMETA

*  Purpose:
*     Fix meta data associated with a raw data file.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_rawfixmeta( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Fix metadata associated with a partocular raw data file. Not all problems can be
*     fixed but attempts to correct for date-related problems and uses heuristics or
*     configuration XML whenever possible.

*  Notes:
*     * Supports ACSIS raw data files

*  ADAM Parameters:
*     IN = NDF (Read)
*          Input files to be checked.
*     OUTDIR = NDF (Read)
*          Directory to receive modified files. "." indicates that the file will be modified
*          in place.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2009-05-18 (TIMJ):
*        Original version

*  Copyright:
*     Copyright (C) 2009 Science and Technology Facilities Council.
*     All Rights Reserved.

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

#include "star/grp.h"
#include "star/kaplibs.h"
#include "sae_par.h"
#include "mers.h"

#include "smurf_par.h"
#include "libsmf/smf.h"
#include "smurflib.h"

void smurf_rawfixmeta( int * status ) {

  smfData *data=NULL;        /* Data file to be tested */
  int fixed;                 /* Was the metadata updated */
  size_t i;
  Grp *igrp = NULL;          /* Input group */
  size_t size;               /* Number of files in input group */


  if (*status != SAI__OK) return;

  ndfBegin();

  /* Read the input file group */
  kpg1Rgndf( "IN", 0, 1, "", &igrp, &size, status );

  for (i=1; i<=size && ( *status == SAI__OK ); i++) {

    /* First open the file for READ to see whether we need to modify it */
    smf_open_file( igrp, i, "READ", SMF__NOCREATE_DATA, &data, status );

    /* see if things need fixing */
    fixed = smf_fix_metadata( MSG__NORM, data, status );

    /* if we have modified the smfData we need to write out the results.
       Might be handy to know which bit has been changed (FitsChan,
       JCMTState, ACSIS extension).

       Also need to know whether to update in place or to create a new file.
       We do not know how many output files we need so may need to do this in two
       loops.
     */


    smf_close_file( &data, status );
  }

  /* Cleanup */
  grpDelet( &igrp, status);
  ndfEnd( status );
}
