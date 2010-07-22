/*
*+
*  Name:
*     smf_clean_smfData

*  Purpose:
*     Perform basic data cleaning operations on a 3-d smfData

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_clean_smfData( smfWorkForce *wf, smfData *data,
*                        AstKeyMap *keymap, int *status )

*  Arguments:
*     wf = smfWorkForce * (Given)
*        Pointer to a pool of worker threads. Can be NULL.
*     data = smfData * (Given and Returned)
*        The data that will be flagged
*     keymap = AstKeyMap* (Given)
*        keymap containing parameters to control cleaning
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine is a wrapper for a number of basic data cleaning
*     operations which are controlled by parameters stored in the
*     AstKeyMap. The keywords that are understood, the general cleaning
*     procedures to which they apply, and the order in which they are
*     executed are listed here (for a full description of their
*     meaning and defaults values see documentation in
*     dimmconfig.lis):
*
*     Sync Quality : BADFRAC
*     DC steps     : DCFITBOX, DCMAXSTEPS, DCTHRESH, DCMEDIANWIDTH, DCLIMCOR
*     Flag spikes  : SPIKETHRESH, SPIKEITER
*     Slew speed   : FLAGSTAT
*     Dark squids  : DKCLEAN
*     Gap filling  : FILLGAPS
*     Baselines    : ORDER
*     Filtering    : FILT_EDGELOW, FILT_EDGEHIGH, FILT_NOTCHLOW, FILT_NOTCHHIGH,
*                    APOD, FILT_WLIM
*     Noisy Bolos  : NOISECLIP

*  Notes:
*     The resulting dataOrder of the cube is not guaranteed, so smf_dataOrder
*     should be called upon return if it is important. smf_get_cleanpar does
*     all of the parsing of the key/value pairs in the AstKeyMap.

*  Authors:
*     Edward Chapin (UBC)
*     David S Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2010-05-31 (EC):
*        Initial Version factored out of smurf_sc2clean and smf_iteratemap
*     2010-06-25 (DSB):
*        Move apodisation to smf_filter_execute.

*  Copyright:
*     Copyright (C) 2010 Univeristy of British Columbia.
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

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

#define FUNC_NAME "smf_clean_smfData"

void smf_clean_smfData( smfWorkForce *wf, smfData *data,
                        AstKeyMap *keymap, int *status ) {

  /* Local Variables */
  size_t aiter;             /* Actual iterations of sigma clipper */
  double badfrac;           /* Fraction of bad samples to flag bad bolo */
  dim_t dcfitbox;           /* width of box for measuring DC steps */
  int dclimcorr;            /* Min. no. of bolos for a correlated step */
  int dcmaxsteps;           /* number of DC steps/min. to flag bolo bad */
  dim_t dcmedianwidth;      /* median filter width before finding DC steps */
  double dcthresh;          /* n-sigma threshold for primary DC steps */
  int dofft;                /* are we doing a freq.-domain filter? */
  int dkclean;              /* Flag for dark squid cleaning */
  int fillgaps;             /* Flag to do gap filling */
  smfFilter *filt=NULL;     /* Frequency domain filter */
  double flagstat;          /* Threshold for flagging stationary regions */
  size_t nflag;             /* Number of elements flagged */
  double noiseclip = 0;     /* Sigma clipping based on noise */
  int order;                /* Order of polynomial for baseline fitting */
  double spikethresh;       /* Threshold for finding spikes */
  size_t spikeiter=0;       /* Number of iterations for spike finder */

  /* Main routine */
  if (*status != SAI__OK) return;

  /* Check for valid inputs */

  if( data->ndims != 3 ) {
    *status = SMF__WDIM;
    errRepf( "", FUNC_NAME ": Supplied smfData has %zu dims, needs 3", status,
             data->ndims );
    return;
  }

  if( !keymap ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": NULL AstKeyMap supplied", status );
    return;
  }

  /* Get cleaning parameters */
  smf_get_cleanpar( keymap, &badfrac, &dcfitbox, &dcmaxsteps,
                    &dcthresh, &dcmedianwidth, &dclimcorr, &dkclean,
                    &fillgaps, NULL, NULL, NULL, NULL, NULL, NULL,
                    &flagstat, &order, &spikethresh, &spikeiter, &noiseclip,
                    status );

  /* Update quality by synchronizing to the data array VAL__BADD values */
  msgOutif(MSG__VERB,"", FUNC_NAME ": update quality", status);
  smf_update_quality( data, 1, NULL, 0, badfrac, status );

  /* Fix DC steps */
  if( dcthresh && dcfitbox ) {
    msgOutiff(MSG__VERB, "", FUNC_NAME
              ": Flagging bolos with %lf-sigma DC steps in %" DIM_T_FMT " "
              "samples as bad, using %" DIM_T_FMT "-sample median filter and max %d "
              "DC steps per min before flagging entire bolo bad...", status,
              dcthresh, dcfitbox, dcmedianwidth, dcmaxsteps);

    smf_fix_steps( wf, data, dcthresh, dcmedianwidth, dcfitbox, dcmaxsteps,
                   dclimcorr, &nflag, NULL, NULL, status );

    msgOutiff(MSG__VERB, "", FUNC_NAME": ...%zd flagged\n", status, nflag);
  }

  /* Flag Spikes */
  if( spikethresh ) {
    msgOutif(MSG__VERB," ", FUNC_NAME ": flag spikes...", status);
    smf_flag_spikes( data, NULL, SMF__Q_FIT, spikethresh, spikeiter,
                     100, &aiter, &nflag, status );
    msgOutiff(MSG__VERB,"", FUNC_NAME ": ...found %zd in %zd iterations",
              status, nflag, aiter );
  }

  /*  Flag periods of stationary pointing */
  if( flagstat ) {
    if( data->hdr && data->hdr->allState ) {
      msgOutiff( MSG__VERB, "", FUNC_NAME
                 ": Flagging regions with slew speeds < %lf arcsec/sec", status,
                 flagstat );
      smf_flag_stationary( data, flagstat, &nflag, status );
      msgOutiff( MSG__VERB,"", "%zu new time slices flagged", status, nflag);
    } else {
      msgOutif( MSG__DEBUG, "", FUNC_NAME
                ": Skipping flagstat because no header present", status );
    }
  }

  /* Clean out the dark squid signal */
  if( dkclean ) {
    msgOutif(MSG__VERB, "", FUNC_NAME ": Cleaning dark squid signals from data.",
             status);
    smf_clean_dksquid( data, 0, 100, NULL, 0, 0, 0, status );
  }

  /* Gap filling */
  if( fillgaps ) {
    msgOutif(MSG__VERB, "", FUNC_NAME ": Gap filling.", status);
    smf_fillgaps( wf, data, SMF__Q_GAP, status );
  }

  /* Remove baselines */
  if( order >= 0 ) {
    msgOutiff( MSG__VERB,"", FUNC_NAME
               ": Fitting and removing %i-order polynomial baselines",
               status, order );
    smf_scanfit( data, order, status );
    smf_subtract_poly( data, 0, status );
  }

  /* filter the data */
  filt = smf_create_smfFilter( data, status );
  smf_filter_fromkeymap( filt, keymap, &dofft, status );
  if( dofft ) {
    msgOutif( MSG__VERB, "", FUNC_NAME ": frequency domain filter", status );
    smf_filter_execute( wf, data, filt, status );
  }
  filt = smf_free_smfFilter( filt, status );

  /* Noise mask */
  if (noiseclip > 0.0) smf_mask_noisy( wf, data, noiseclip, status );

}
