/*
*+
*  Name:
*     smf_write_itermap

*  Purpose:
*     Write itermap extension to NDF

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_write_itermap( const double *map, const double *mapvar, dim_t msize,
*                        const Grp *iterrootgrp, size_t contchunk, int iter,
*                        const int *lbnd_out, const int *ubnd_out,
*                        AstFrameSet *outfset, const smfHead *hdr,
*                        const smfArray *qua, int *status )

*  Arguments:
*     map = const double* (Given)
*        The output map array
*     mapvar = const double* (Given)
*        Variance of each pixel in map
*     msize = dim_t (Given)
*        Number of pixels in map/mapvar
*     iterrootgrp = const Grp* (Given)
*        Root name for iteration output maps. Can be path to HDS container.
*     contchunk = size_t (Given)
*        Continuous chunk number
*     iter = int (Given)
*        Iteration number
*     lbnd_out = const int* (Given)
*        2-element array pixel coord. for the lower bounds of the output map
*     ubnd_out = const int* (Given)
*        2-element array pixel coord. for the upper bounds of the output map
*     outfset = AstFrameSet* (Given)
*        Frameset containing the sky->output map mapping
*     hdr = smfHead *hdr (Given)
*        Header for the time-series data. Optional, can be NULL.
*     qua = const smfArray* (Given)
*        Quality smfArray corresponding to the continuous chunk. Only required
*        if hdr supplied.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Write the supplied map and variance to an NDF. The root of the
*     name is supplied by iterrootgrp, and the suffix will be CH##I##,
*     where "CH" refers to the continuous chunk, and "I" the iteration
*     number for that chunk.

*  Notes:

*  Authors:
*     EC: Ed Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2010-08-13 (EC):
*        Initial version factored out of smf_iteratemap. Also, always
*        includr CH## in name, even if only one contchunk (to make naming
*        more uniform).
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2010 University of British Columbia
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

/* Starlink includes */
#include "mers.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/ndg.h"
#include "prm_par.h"
#include "par_par.h"
#include "star/one.h"
#include "star/atl.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

#define FUNC_NAME "smf_write_itermap"

void smf_write_itermap( const double *map, const double *mapvar, dim_t msize,
                        const Grp *iterrootgrp, size_t contchunk, int iter,
                        const int *lbnd_out, const int *ubnd_out,
                        AstFrameSet *outfset, const smfHead *hdr,
                        const smfArray *qua, int *status ) {

  Grp *mgrp=NULL;             /* Temporary group to hold map name */
  smfData *imapdata=NULL;     /* smfData for this iteration map */
  char name[GRP__SZNAM+1];    /* Buffer for storing name */
  char *pname=NULL;           /* Poiner to name */
  char tmpname[GRP__SZNAM+1]; /* temp name buffer */
  char tempstr[20];

  if( *status != SAI__OK ) return;

  if( !map || !mapvar || !iterrootgrp || !lbnd_out || !ubnd_out || !outfset ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": NULL inputs supplied", status );
    return;
  }

  if( hdr && !qua ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": hdr supplied but qua is NULL", status );
    return;
  }

  /* Create a name for this iteration map, take into
     account the chunk number. Only required if we are
     using a single output container. */

  pname = tmpname;
  grpGet( iterrootgrp, 1, 1, &pname, sizeof(tmpname), status );
  one_strlcpy( name, tmpname, sizeof(name), status );
  one_strlcat( name, ".", sizeof(name), status );

  /* Continuous chunk number */
  sprintf(tempstr, "CH%02zd", contchunk);
  one_strlcat( name, tempstr, sizeof(name), status );

  /* Iteration number */
  sprintf( tempstr, "I%03i", iter+1 );
  one_strlcat( name, tempstr, sizeof(name), status );
  mgrp = grpNew( "itermap", status );
  grpPut1( mgrp, name, 0, status );

  msgOutf( "", "*** Writing map from this iteration to %s", status,
           name );

  smf_open_newfile ( mgrp, 1, SMF__DOUBLE, 2, lbnd_out,
                     ubnd_out, SMF__MAP_VAR, &imapdata, status);

  /* Copy over the signal and variance maps */
  if( *status == SAI__OK ) {
    memcpy( imapdata->pntr[0], map, msize*sizeof(*map) );
    memcpy( imapdata->pntr[1], mapvar, msize*sizeof(*mapvar) );
  }

  /* Write out a FITS header */
  if( (*status == SAI__OK) && hdr && hdr->allState ) {
    AstFitsChan *fitschan=NULL;
    JCMTState *allState = hdr->allState;
    char *obsidss=NULL;
    char obsidssbuf[SZFITSCARD+1];
    double iter_nboloeff;
    size_t nmap;
    size_t ngood_tslices;
    dim_t ntslice;                /* Number of time slices */

    fitschan = astFitsChan ( NULL, NULL, " " );

    obsidss = smf_getobsidss( hdr->fitshdr,
                              NULL, 0, obsidssbuf,
                              sizeof(obsidssbuf), status );
    if( obsidss ) {
      atlPtfts( fitschan, "OBSIDSS", obsidss,
                "Unique observation subsys identifier", status );
    }
    atlPtfti( fitschan, "SEQSTART", allState[0].rts_num,
              "RTS index number of first frame", status );

    ntslice = hdr->nframes;

    atlPtfti( fitschan, "SEQEND", allState[ntslice-1].rts_num,
              "RTS index number of last frame", status );

    /* calculate the effective number of bolometers for this
       iteration */
    smf_qualstats_model( SMF__QFAM_TSERIES, 1, qua, NULL, NULL, &nmap, NULL,
                         NULL, &ngood_tslices, NULL, NULL, status );

    iter_nboloeff = (double)nmap / (double)ngood_tslices;
    atlPtftd( fitschan, "NBOLOEFF", iter_nboloeff,
              "Effective bolometer count", status );

    kpgPtfts( imapdata->file->ndfid, fitschan, status );

    if( fitschan ) fitschan = astAnnul( fitschan );
  }

  /* Write WCS (protecting the pointer dereference) */
  smf_set_moving(outfset,status);
  if (*status == SAI__OK && imapdata) {
    ndfPtwcs( outfset, imapdata->file->ndfid, status );
  }

  /* Clean up */
  if( mgrp ) grpDelet( &mgrp, status );
  smf_close_file( &imapdata, status );
}
