/*
*+
*  Name:
*     smf_get_xloc

*  Purpose:
*     Return an HDS locator for an NDF extension

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     SMURF subroutine

*  Invocation:
*     xloc = smf_get_xloc( const smfData *data, const char *extname, 
*			const char *extype, const char *accmode, 
*			const int ndims, const int *dims, int *status );

*  Arguments:
*     data = const smfData* (Given)
*        smfData struct
*     extname = const char* (Given)
*        Name of extension
*     extype = const char* (Given)
*        Descriptor for locator
*     accmode = const char* (Given)
*        Access mode for locator (READ, WRITE or UPDATE)
*     ndims = const int (Given)
*        Number of dimensions in new locator
*     dims = const int* (Given)
*        Pointer to array containing size of each axis
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Check the existence of the specified HDS locator. A new locator
*     will be created if it does not exist provided the file is open
*     for WRITE (or UPDATE) access. Returns a pointer to an HDS
*     locator. If an error occurs a NULL pointer is returned,
*     including the case that the file is not open for write access if
*     a new extension has to be created.
*
*     For returning locators to existing extensions the ndims and dims
*     can all be left blank (i.e. 0, 0 or NULL respectively). Accmode
*     can be left blank as well but it's probably a good idea to
*     specify it.

*  Notes:
*     - It is up to the caller to define the context of the return value

*  Authors:
*     Andy Gibb (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-05-09 (AGG):
*        Initial version
*     2006-07-17 (AGG):
*        Check that the file is open for write access if a new
*        extension is needed
*     2006-07-24 (AGG):
*        Update prologue for dealing with existing extensions
*     2006-08-02 (AGG):
*        Minor changes to user feedback from msgOutif
*     2006-09-21 (AGG):
*        Check that the caller has requested WRITE or UPDATE access
*        before attempting to create a new extension
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 University of British Columbia. All Rights
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

/* Standard includs */
#include <string.h>
#include <stdio.h>

/* Starlink includes */
#include "sae_par.h"
#include "star/ndg.h"
#include "ndf.h"
#include "ast.h"
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"
#include "mers.h"
#include "star/kaplibs.h"
#include "kpg_err.h"

/* SMURF includes */
#include "smf.h"
#include "smurf_par.h"
#include "libsmurf/smurflib.h"
#include "smf_err.h"

/* SC2DA includes */
#include "sc2da/sc2store.h"
#include "sc2da/sc2math.h"

#define FUNC_NAME "smf_get_xloc"

HDSLoc * smf_get_xloc ( const smfData *data, const char *extname, 
			const char *extype, const char *accmode, 
			const int ndims, const int *dims, int *status ) {

  smfFile *file;            /* Pointer to input file struct */
  int indf;                 /* NDF identifier for input file */
  HDSLoc *loc = NULL;       /* Locator to return */
  int itexists;             /* Flag to denote whether extension exists */
  int isacc = 0;            /* Flag to denote whether the file is open
			       for write access */

  if ( *status != SAI__OK ) return NULL;

  /* Retrieve NDF identifier from smfFile */
  if ( data == NULL ) {
    *status = SAI__ERROR;
    errRep( FUNC_NAME,
	    "Supplied smfData is a NULL pointer. Possible programming error.",
	    status);
    return NULL;
  }
  file = data->file;
  if ( file == NULL ) {
    *status = SAI__ERROR;
    errRep(FUNC_NAME, "Supplied smfData is not associated with a file, unable to create a locator", status);
    return NULL;
  }
  indf = file->ndfid;
  if ( indf == NDF__NOID ) {
    *status = SAI__ERROR;
    errRep(FUNC_NAME, "Supplied smfData is associated with a file but it isn't an NDF", status);
    return NULL;
  }

  /* See if desired extension exists */
  ndfXstat( indf, extname, &itexists, status );
  if ( itexists ) {
    /* OK, get a locator for it */
    ndfXloc( indf, extname, accmode, &loc, status );
    if ( loc == NULL ) {
      if ( *status == SAI__OK) {
	msgSetc("E", extname);
	*status = SAI__ERROR;
	errRep(FUNC_NAME, "Unable to obtain an HDS locator to the ^E extension, despite its existence", status);
      }
    } else {
      msgSetc("E", extname);
      msgOutif(MSG__VERB," ", 
	       "Found extension named ^E", status);
    }
  } else {
    msgSetc("E", extname);
    msgOutif(MSG__VERB," ", 
	     "Warning: no extension named ^E", status);
    /* Extension doesn't exist - do we want to create a new one? */
    if ( strncmp ( accmode, "WRITE", 5) == 0 || 
	 strncmp ( accmode, "UPDATE", 6) == 0) {
      /* If we want to create new extension we first have to check
	 that the NDF is open for WRITE or UPDATE access */
      ndfIsacc( indf, "WRITE", &isacc, status );
      if (isacc) {
	msgSetc("E", extname);
	msgOutif(MSG__VERB," ", "Creating new extension, ^E", status );
	ndfXnew( indf, extname, extype, ndims, dims, &loc, status );
      } else {
	/* OK not open for WRITE access, try UPDATE */
	ndfIsacc( indf, "UPDATE", &isacc, status );
	if (isacc) {
	  msgSetc("E", extname);
	  msgOutif(MSG__VERB," ", "Creating new extension, ^E", status );
	  ndfXnew( indf, extname, extype, ndims, dims, &loc, status );
	} else {
	  /* OK file cannot be written to despite the fact we want a
	     new extension - time to let the user know */
	  if ( *status == SAI__OK ) {
	    *status = SAI__ERROR;
	    msgSetc("A", accmode );
	    errRep(FUNC_NAME, 
		   "Unable to create new extension: file is not open for ^A access", 
		   status);
	    loc = NULL;
	  }
	}
      }
    } else {
      msgOutif(MSG__VERB," ", 
	       "That's OK: we don't to create a new one", status);
    }
  }

  return loc;
}
