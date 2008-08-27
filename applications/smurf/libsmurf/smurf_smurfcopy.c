/*
*+
*  Name:
*     SMURFCOPY

*  Purpose:
*     Copy a 2d image out of a time series file

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_smurfcopy( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This task can be used to extract data from a file for a particular
*     time slice. The world coordinates will be valid on this slice so 
*     the data can be used for display or image overlay (e.g. when using
*     the KAPPA OUTLINE command to determine where this slice lay in relation to
*     the reconstructed map).
*
*     KAPPA NDFCOPY will not add the specific astrometry information when
*     used to extract a slice and so can not be used when WCS is required.

*  ADAM Parameters:
*     IN = NDF (Read)
*          Input file. Can not be a DARK frame. If the input file is
*          raw data, it will not be flatfielded but will be uncompressed.
*     SLICE = _INTEGER (Read)
*          Index of time axis (GRID coordinates). 0 can be used to specify
*          the last slice in the file without having to know how many
*          slices are in the file.
*     OUT = NDF (Write)
*          Output file. Extensions are not propagated.

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2008-08-13 (TIMJ):
*        Initial version
*     {enter_further_changes_here}

*  Notes:
*     Currently, this routine can not support multiple input files
*     or multiple indices from a single input file. Once extracted the
*     output file can no longer be processed by SMURF routines.

*  Related Applications:
*     KAPPA: CONTOUR, OUTLINE
*     SMURF: jcmtstate2cat

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

/* Starlink includes */
#include "sae_par.h"
#include "merswrap.h"
#include "msg_par.h"
#include "par.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "smurflib.h"
#include "smurf_par.h"

void smurf_smurfcopy ( int * status ) {

  smfData * data = NULL;     /* input file struct */
  size_t dtypsz;             /* Number of bytes in data type */
  Grp *fgrp = NULL;          /* Filtered group, no darks */
  size_t i;                  /* Loop counter */
  smfFile * ifile = NULL;    /* Input smfFile */
  Grp *igrp = NULL;          /* Input group */
  unsigned char * inptr = NULL; /* Pointer to start of section to copy */
  int islice;                /* int time slice from parameter */
  int lbnd[2];               /* Lower coordinate bounds of output file */
  size_t nelem;              /* Number of elements to copy */
  smfData * odata = NULL;    /* output file struct */
  size_t offset;             /* offset into data array */
  smfFile * ofile = NULL;    /* output smfFile */
  Grp *ogrp = NULL;          /* Output group */
  size_t outsize;            /* Total number of NDF names in the output group */
  dim_t slice;               /* Time index to extract */
  size_t size;               /* Number of files in input group */
  int ubnd[2];               /* Upper coordinate bounds of output file */

  if (*status != SAI__OK) return;

  ndfBegin();

  /* Read the input file */
  /* As a proof of concept do not allow multiple input files */
  kpg1Rgndf( "IN", 1, 1, "", &igrp, &size, status );

  /* Filter out darks */
  smf_find_darks( igrp, &fgrp, NULL, 0, SMF__NULL, NULL, status );

  /* input group is now the filtered group so we can use that and
     free the old input group */
  size = grpGrpsz( fgrp, status );
  grpDelet( &igrp, status);
  igrp = fgrp;
  fgrp = NULL;

  if (size > 0) {
  /* Get output file(s) */
  kpg1Wgndf( "OUT", igrp, size, size, "More output files required...",
             &ogrp, &outsize, status );
  } else {
    msgOutif(MSG__NORM, " ","All supplied input frames were DARK,"
       " nothing to extract", status );
  }

  /* Use a loop so that we look like other routines and simplify
     the change if we support multiple input files */
  for (i=1; i<=size; i++) {

    /* Open the input file using standard routine */
    smf_open_file( igrp, i, "READ", 1, &data, status );

    if (*status == SAI__OK) {
      if (!data->file->isTstream  || data->ndims != 3) {
        smf_close_file( &data, status );
        *status = SAI__ERROR;
        errRep(" ", "Input data do not represent time series", status);
        break;
      }
    }

    /* get the slice position - knowing the maximum allowed
       Somewhat problematic in a loop if we want to allow
       different slices per file. Best bet is to allow multiple
       slices in a single file but only one file.
     */

    msgSeti( "MAX", (data->dims)[2] );
    msgOutif( MSG__NORM, " ", "File has ^MAX slices.", status );

    parGdr0i( "SLICE",1, 0, (data->dims)[2], 1, &islice, status);
    slice = islice;
    if (slice == 0) slice = (data->dims)[2];

    /* construct output bounds */
    lbnd[0] = 1;
    lbnd[1] = 1;
    ubnd[0] = (data->dims)[0] - lbnd[0] + 1;
    ubnd[1] = (data->dims)[1] - lbnd[1] + 1;

    /* Open an output file (losing history) but we do not want
       to propagate the full NDF size to the output file */

    smf_open_newfile( ogrp, i, data->dtype, 2, lbnd, ubnd, 0,
                      &odata, status );
    ofile = odata->file;
    ifile = data->file;

    /* protect against null pointer smfFile */
    if (*status == SAI__OK) {

      /* sort out provenance */
      smf_updateprov( ofile->ndfid, data, NDF__NOID,
                      "SMURF:SMURFCOPY", status );

      /* copy the slice in */
      dtypsz = smf_dtype_size( odata, status );
      nelem = (data->dims)[0] * (data->dims)[1];
      offset = (slice - 1) * nelem * dtypsz;
      inptr = (data->pntr)[0];
      memcpy( (odata->pntr)[0], inptr + offset, nelem * dtypsz );

      /* World coordinates - note the 0 indexing relative to GRID */
      smf_tslice_ast( data, slice-1, 1, status );
      ndfPtwcs( data->hdr->wcs, ofile->ndfid, status );

      /* Write the FITS header */
      kpgPtfts( ofile->ndfid, data->hdr->fitshdr, status );

      /* Do not currently propagate JCMTSTATE slice - sc2store_headput
         does not work without using sc2store_wrtstream first */

    }

    /* cleanup */
    smf_close_file( &data, status );
    smf_close_file( &odata, status );
                   
  }

  /* tidy */
  if (igrp) grpDelet( &igrp, status );
  if (ogrp) grpDelet( &ogrp, status );

  ndfEnd(status);

}
