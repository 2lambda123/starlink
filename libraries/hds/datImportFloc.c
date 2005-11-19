
#if HAVE_CONFIG_H
#  include <config.h>
#endif

#include <stdlib.h>
#include <string.h>

#include "ems.h"

#include "hds1.h"
#include "rec.h"
#include "dat1.h"
#include "hds_types.h"
#include "dat_err.h"

#include "hds_fortran.h"

/*
 *+
 *  Name:
 *    datImportFloc

 *  Purpose:
 *    Import a Fortran HDS locator buffer into C with malloc

 *  Invocation:
 *    datImportFloc( char flocator[DAT__SZLOC], int loc_length, HDSLoc **clocator, int * status);

 *  Description:
 *    This function should be used to convert a Fortran HDS locator 
 *    (implemented as a string buffer) to a C locator struct. The C locator
 *    is malloced by this routine. The memory will be freed when datAnnul
 *    is called. This function is also available via the 
 *    HDS_IMPORT_FLOCATOR macro defined in hds_fortran.h.

 *  Arguments
 *    char flocator[DAT__SZLOC] = Given
 *       Fortran character string buffer. Should be at least DAT__SZLOC
 *       characters long.
 *    int loc_length = Given
 *       Size of Fortran character buffer. Sanity check.
 *    HDSLoc ** clocator = Returned
 *       Fills the HDSLoc struct with the contents of the fortran buffer.
 *       Locator struct is malloced by this routine and should be freed
 *       either with dat1_free_hdsloc or dat1_export_loc. *clocator must
 *       be NULL on entry. If status is set by this routine, the struct
 *       will not be malloced on return.
 *    int *status = Given and Returned
 *       Inherited status. Returns without action if status is not SAI__OK.

 *  Authors:
 *    Tim Jenness (JAC, Hawaii)

 *  History:
 *    16-NOV-2005 (TIMJ):
 *      Initial version
 *    18-NOV-2004 (TIMJ):
 *      Rename from dat1_import_floc so that it can be made public for
 *      fortran wrappers.

 *  Notes:
 *    - Does not check the contents of the locator for validity.
 *    - The expectation is that this routine is used solely for C
 *      interfaces to Fortran library routines.

 *  See Also:
 *    - datExportFloc

 *  Copyright:
 *    Copyright (C) 2005 Particle Physics and Astronomy Research Council.
 *    All Rights Reserved.

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

void datImportFloc ( char flocator[DAT__SZLOC], int loc_length, HDSLoc ** clocator, int * status) {

  if (*status != DAT__OK) return;

  /* Check that we have a null pointer for HDSLoc */
  if ( *clocator != NULL ) {
    *status = DAT__WEIRD;
    emsRep( "datImportFloc", "datImportFloc: Supplied C locator is non-NULL",
	    status);
    return;
  }

  /* See if we need to allocate memory for the locator struct */
  /* Allocate some memory to hold the C structure */

  *clocator = malloc( sizeof( struct LOC ) );

  if (*clocator == NULL ) {
    *status = DAT__NOMEM;
    emsRep( "datImportFloc", "datImportFloc: No memory for C locator struct",
	    status);
    return;
  }

  /* Now import the Fortran locator */
  dat1_import_floc( flocator, loc_length, *clocator, status);

  /* Clean up on error */
  if ( *status != DAT__OK ) {
    dat1_free_hdsloc( clocator );
  }

  return;
}
