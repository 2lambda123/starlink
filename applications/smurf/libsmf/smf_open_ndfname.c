/*
*+
*  Name:
*     smf_open_ndfname

*  Purpose:
*     Low-level NDF extension access function

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_open_ndfname( HDSLoc *loc, char *accmode, char *filename, char *extname,
*		        const char *state, const char *dattype, const int ndims, 
*		        const int *lbnd, const int *ubnd, smfData **ndfdata, 
*                       int *status);

*  Arguments:
*     loc = HDSLoc * (Given)
*        HDSLocator  for the requested NDF extension
*     accmode = const char* (Given)
*        Access mode for locator (READ, WRITE or UPDATE)
*     filename = char * (Given)
*        Name of disk file which holds the requested NDF
*     extname = const char* (Given)
*        Name of extension
*     state = const char* (Given)
*        State of NDF (NEW, OLD or UNKNOWN)
*     dattype = const char* (Given)
*        Data type to be stored in NDF
*     ndims = const int (Given)
*        Number of dimensions in new locator
*     lbnd = const int* (Given)
*        Pointer to array containing lower bounds for each axis
*     ubnd = const int* (Given)
*        Pointer to array containing upper bounds for each axis
*     ndfdata = smfData** (Returned)
*        Output smfData with mapped access to requested NDF
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine opens a specified NDF extension within an already-opened file
*     associated with a smfData. A new smfData is returned with the
*     DATA array mapped. Returns a NULL smfData on error.

*  Notes:
*     - Only the DATA component of the NDF extension is mapped. Including the VARIANCE 
*       and QUALITY components is not beyond the realms of possibility.

*  Authors:
*     Andy Gibb (UBC)
*     J. Balfour (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-08-04 (JB):
*        Cloned from smf_open_ndf & smf_get_ndfid
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

/* Standard includes */
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* Starlink includes */
#include "sae_par.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "star/hds.h"
#include "ndf.h"
#include "mers.h"
#include "msg_par.h"
#include "prm_par.h"
#include "par.h"

/* SMURF includes */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_open_ndfname"

void smf_open_ndfname( const HDSLoc *loc, char *accmode, char *filename, 
                       const char *extname,
		       const char *state, const char *dattype, const int ndims, 
		       const int *lbnd, const int *ubnd, smfData **ndfdata, 
                       int *status) {

  /* Local variables */
  void *datarr[3] = { NULL, NULL, NULL }; /* Pointers for data */
  dim_t dimens[NDF__MXDIM];     /* Dimensions of image */
  int dims[NDF__MXDIM];         /* Extent of each dimension */
  smf_dtype dtype;              /* Data type */
  int flags = 0;                /* Flags for creating smfDA, smfFile and 
				   smfHead components in the output smfData */
  int ndat;                     /* Number of elements mapped in the requested NDF */
  int ndfid;                    /* NDF identifier */
  smfFile *newfile = NULL;      /* New smfFile with details of requested NDF */
  int place;                    /* Placeholder for NDF */
  int temp;                     /* Temporary integer to convert to dim_t */

  if ( *status != SAI__OK ) return;

  /* Check to see if the HDS Locator is null and retrieve the NDF id */
  if ( loc ==  NULL ) {
    errRep( FUNC_NAME, "Given HDS locator is NULL", status );
    return;
  }

  /* Note: write access clears the contents of the NDF */
  if ( strncmp( accmode, "WRITE", 5 ) == 0 ) {
    msgOutif( MSG__VERB, FUNC_NAME, "Opening NDF with WRITE access: this will clear the current contents if the NDF exists.", status);
  }
  ndfOpen( loc, extname, accmode, state, &ndfid, &place, status );
  if ( *status != SAI__OK ) {
    errRep( FUNC_NAME, 
	    "Call to ndfOpen failed: unable to obtain an NDF identifier", 
	    status );
    return;
  }

  /* No placeholder => NDF exists */
  if ( place != NDF__NOPL ) {
    /* Define properties of NDF */
    ndfNew( dattype, ndims, lbnd, ubnd, &place, &ndfid, status );
    if ( *status != SAI__OK ) {
      errRep( FUNC_NAME, "Unable to create a new NDF", status );
      return;
    }
  }
  
  /* Initialize the output smfData to NULL pointer */
  *ndfdata = NULL;

  /* Get the dtype */
  smf_string_to_dtype ( dattype, &dtype, status );

  /* First step is to create an empty smfData with no extra components */
  flags |= SMF__NOCREATE_DA;
  flags |= SMF__NOCREATE_HEAD;
  flags |= SMF__NOCREATE_FILE;
  *ndfdata = smf_create_smfData( flags, status);
  /* Set the requested data type */
  (*ndfdata)->dtype = dtype;

  /* OK, now map the data array */
  ndfMap( ndfid, "DATA", dattype, accmode, &datarr[0], &ndat, status );
  if ( *status != SAI__OK ) {
    errRep( FUNC_NAME, "Unable to map data array: invalid NDF identifier?", status );
  }
  ndfDim( ndfid, NDF__MXDIM, dims, &ndims, status );
  if ( *status != SAI__OK ) {
    errRep( FUNC_NAME, "Problem identifying dimensions of requested NDF", status );
  }

  temp = dims[0];
  dimens[0] = temp;
  temp = dims[1];
  dimens[1] = temp;  

  /* Create the smfFile */
  newfile = smf_construct_smfFile( newfile, ndfid, 0, 0, filename, status );
  if ( *status != SAI__OK ) {
    errRep( FUNC_NAME, "Unable to construct new smfFile", status );
  }

  /* And populate the new smfData */
  *ndfdata = smf_construct_smfData( *ndfdata, newfile, NULL, NULL, dtype, datarr, 
				    dimens, ndims, 0, 0, NULL, NULL, status );

}//smf_open_ndfname
