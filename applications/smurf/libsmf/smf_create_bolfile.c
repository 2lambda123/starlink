/*
*+
*  Name:
*     smf_create_bolfile

*  Purpose:
*     Create bolometer shaped 2D smfData, either malloced or on disk

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     void smf_create_bolfile( const Grp * bgrp, size_t index,
*               const smfData* refdata, const char * datalabel,
*               const char * units, int hasqual, smfData **bolmap,
*               int *status );

*  Arguments:
*     bgrp = const Grp * (Given)
*        Group containing the relevant file name. If NULL no file
*        is created and the smfData is malloced.
*     index = size_t (Given)
*        Index into bgrp.
*     refdata = const smfData* (Given)
*        Reference smfData. Dimensionality, sub array information and
*        FITS header are obtained from this.
*     datalabel = const char * (Given)
*        Label for the data array. Can be NULL. Title will be derived
*        from this.
*     hasqual = int (Given)
*        If true include a QUALITY component.
*     bolmap = smfData** (Returned)
*        Output smfData.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Create a smfData with the correct metadata for a 2d bolometer map.
*     The smfData will either be associated with a file and mapped for WRITE
*     access ready to receive data, or else, if no Grp is supplied it will be
*     malloced. Useful for responsivity images and noise data.

*  Authors:
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2009-03-27 (TIMJ):
*        Initial version.
*     2009-05-21 (TIMJ):
*        smf_construct_smfHead API tweak
*     2009-10-05 (TIMJ):
*        Rename to use for noise files as well as responsivity images.
*     2009-10-08 (TIMJ):
*        Use malloc if the input group is null
*     2009-11-06 (TIMJ):
*        Preferentially select BOLO frame for output WCS
*     2009-11-30 (TIMJ):
*        Add ability to enable quality.

*  Notes:
*     - Does not propogate provenance or history from refdata.

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

#include "smf_typ.h"
#include "smf.h"
#include "sc2da/sc2ast.h"

#include "sae_par.h"
#include "ndf.h"
#include "star/kaplibs.h"
#include "ast.h"
#include "star/one.h"

void smf_create_bolfile( const Grp * bgrp, size_t index,
                         const smfData* refdata, const char *datalabel,
                         const char *units, int hasqual, smfData **bolmap,
                         int *status ) {

  int lbnd[2];
  int ubnd[2];

  *bolmap = NULL;
  if (*status != SAI__OK) return;

  /* Calculate bounds */
  lbnd[SC2STORE__ROW_INDEX] = (refdata->lbnd)[SC2STORE__ROW_INDEX];
  lbnd[SC2STORE__COL_INDEX] = (refdata->lbnd)[SC2STORE__COL_INDEX];
  ubnd[SC2STORE__ROW_INDEX] = lbnd[SC2STORE__ROW_INDEX] +
          (refdata->dims)[SC2STORE__ROW_INDEX] - 1;
  ubnd[SC2STORE__COL_INDEX] = lbnd[SC2STORE__ROW_INDEX] +
          (refdata->dims)[SC2STORE__COL_INDEX] - 1;

  /* either create the file or use malloc */
  if (bgrp) {
    int flags = SMF__MAP_VAR;
    if (hasqual) flags |= SMF__MAP_QUAL;

    /* create the file for WRITE access */
    smf_open_newfile( bgrp, index, SMF__DOUBLE, 2, lbnd, ubnd,
                      flags, bolmap, status );
  } else {
    void *pntr[] = {NULL, NULL, NULL};
    dim_t mydims[2];
    int mylbnd[2];
    size_t nbols;

    mylbnd[0] = lbnd[0];
    mylbnd[1] = lbnd[1];
    mydims[0] = ubnd[0] - lbnd[0] + 1;
    mydims[1] = ubnd[1] - lbnd[1] + 1;
    nbols = mydims[0] * mydims[1];

    pntr[0] = smf_malloc( nbols, sizeof(double), 0, status );
    pntr[1] = smf_malloc( nbols, sizeof(double), 0, status );
    if (hasqual) pntr[2] = smf_malloc( nbols, sizeof(char), 0, status );

    *bolmap = smf_construct_smfData( NULL, NULL, NULL, NULL, SMF__DOUBLE,
                                     pntr, 0, mydims, mylbnd, 2, 0, 0, NULL,
                                     NULL, status );
  }

  /* add some niceties - propagate some information from the first measurement */
  if (*status == SAI__OK) {
    char subarray[9];          /* subarray name */
    int frnum = AST__NOFRAME;  /* Index of BOLO frame */
    int subnum;                /* subarray number */
    char buffer[30];
    AstFrameSet *wcs = NULL;

    /* Subarray information */
    smf_find_subarray( refdata->hdr, subarray, sizeof(subarray), &subnum, status );
    one_strlcpy( buffer, subarray, sizeof(buffer), status );
    if (datalabel) {
      one_strlcat( buffer, " Bolometer ", sizeof(buffer), status );
      one_strlcat( buffer, datalabel, sizeof(buffer), status );
    }

    /* Create output WCS. Should really extract it from the
       refdata WCS rather than attempting to reconstruct. */
    sc2ast_createwcs( subnum, NULL, NULL, NULL, &wcs, status );

    /* and switch to BOLO frame which is best for bolometer analysis */
    kpg1Asffr( wcs, "BOLO", &frnum, status );
    if (frnum != AST__NOFRAME) astSetI( wcs, "CURRENT", frnum );

    (*bolmap)->hdr = smf_construct_smfHead( NULL, refdata->hdr->instrument,
                                             wcs, astCopy( refdata->hdr->fitshdr ),
                                             NULL, NULL, 0, refdata->hdr->instap, 1,
                                             refdata->hdr->steptime, refdata->hdr->obsmode,
                                             refdata->hdr->swmode, refdata->hdr->obstype, 0, NULL, NULL,
                                             NULL, NULL, 0, NULL, buffer, datalabel,
                                             units, refdata->hdr->telpos, NULL, status );

    /* write WCS and FITS information to file and sync other information */
    if (bgrp) {
      kpgPtfts( (*bolmap)->file->ndfid, refdata->hdr->fitshdr, status );
      ndfPtwcs( wcs, (*bolmap)->file->ndfid, status );
      smf_write_clabels( *bolmap, status );
    }
  }

}
