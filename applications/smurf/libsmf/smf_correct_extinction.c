/*
*+
*  Name:
*     smf_correct_extinction

*  Purpose:
*     Low-level EXTINCTION correction function

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     smf_correct_extinction(smfData *data, smf_tausrc tausrc,
*                            smf_extmeth method, double tau, double *allextcorr, 
*                            int *status) {

*  Arguments:
*     data = smfData* (Given)
*        smfData struct
*     tausrc = smf_tausrc (Given)
*        Source of opacity value. Options are:
*          SMF__TAUSRC_AUTO: Use WVM if available, else use CSO tau.
*          SMF__TAUSRC_CSOTAU: Use the supplied "tau" argument as if it is CSO tau.
*          SMF__TAUSRC_WVMRAW: Use the WVM time series data.
*          SMF__TAUSRC_TAU: Use the tau value as if it is for this filter.
*     method = smf_extmeth (Given)
*        Flag to denote which method to use for calculating the airmass of a bolometer.
*          SMF__EXTMETH_SINGLE: Use single airmass for each time slice.
*          SMF__EXTMETH_FULL: Calculate airmass for each bolometer.
*          SMF__EXTMETH_ADAPT: Use FULL only if warranted. Else use FAST.
*     tau = double (Given)
*        Optical depth at 225 GHz. Only used if tausrc is AUTO, TAU or CSOTAU. If
*        the bad value is used a default value will be used from the header.
*     allextcorr = double* (Given and Returned)
*        If given, store calculated corrections for each bolo/time slice. Must
*        have same dimensions as bolos in *data
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is the main low-level routine implementing the EXTINCTION
*     task. If allextcorr is specified, no correction is applied to
*     the data (the correction factors are just stored).
*
*     The adaptive method looks at the combination of Airmass and Tau to determine
*     whether a full per-bolometer calculation is required or whether a single
*     airmass is sufficient (as read from the telescope tracking position).

*  Notes:
*     In WVM mode the adaptive mode checking occurs at each time slice. This is done because
*     tau can change from time slice to time slice, which could lead to a change
*     significant enough to cross the threshold. This is not important if a static
*     correction method (eg CSO tau) is in use. For CSOTAU and TAU modes the check is
*     performed once based on either the start or end airmass (since the tau is not changing).
*
*     If the wvm values are bad then the previous tau value is used. This should only occur
*     when the data acquisition has failed and many JCMTSTATE entries are missing.

*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (TIMJ)
*     Ed Chapin (UBC))
*     {enter_new_authors_here}

*  History:
*     2005-09-27 (AGG):
*        Initial test version
*     2005-11-14 (AGG):
*        Update API to accept a smfData struct
*     2005-12-20 (AGG):
*        Store the current coordinate system on entry and reset on return.
*     2005-12-21 (AGG):
*        Use the curslice as a frame offset into the timeseries data
*     2005-12-22 (AGG):
*        Deprecate use of curslice, make use of virtual flag instead
*     2006-01-11 (AGG):
*        API updated: tau no longer needed as it is retrieved from the
*        header. For now, image data uses the MEANWVM keyword from the
*        FITS header
*     2006-01-12 (AGG):
*        API update again: tau will be needed in the case the user
*        supplies it at the command line
*     2006-01-24 (AGG):
*        Floats to doubles
*     2006-01-25 (AGG):
*        Code factorization to simplify logic. Also corrects variance
*        if present.
*     2006-01-25 (TIMJ):
*        1-at-a-time astTran2 is not fast. Rewrite to do the astTran2
*        a frame at a time. Speed up from 85 seconds to 2 seconds.
*     2006-02-03 (AGG):
*        Add the quick flag. Not pretty but it gives a factor of 2 speed up
*     2006-02-07 (AGG):
*        Can now use the WVMRAW mode for getting the optical
*        depth. Also calculate the filter tau from the CSO tau in the
*        CSOTAU method
*     2006-02-17 (AGG):
*        Store and monitor all three WVM temperatures
*     2006-04-21 (AGG):
*        Check and update history if routine successful
*     2006-07-04 (AGG):
*        Update calls to slaAirmas to reflect new C interface
*     2006-07-26 (TIMJ):
*        sc2head no longer used. Use JCMTState instead.
*     2007-03-05 (EC):
*        Return allextcorr.
*        Check for existence of header.
*     2007-03-22 (AGG):
*        Check for incompatible combinations of data and parameters
*     2007-12-18 (AGG):
*        Update to use new smf_free behaviour
*     2008-04-03 (EC):
*        Assert time-ordered (ICD compliant) data
*     2008-04-29 (AGG):
*        Code reorg to ensure correct status handling
*     2008-04-30 (EC):
*        - Extra valid pointer checks
*        - Removed time-ordered data assertion. Handle bolo-ordered case.
*     2008-05-03 (EC):
*        - Only write history if applying extinction (!allextcorr case)
*     2008-06-12 (TIMJ):
*        - fix compiler warnings. origsystem must be copied in case
*        another call to astGetC is inserted in the code without thought.
*     2008-12-08 (TIMJ):
*        simplify smf_tslice_ast call logic
*        use sizeof(*var)
*     2008-12-09 (TIMJ):
*        - Use astTranGrid rather than astTran2
*        - Do not set system in frameset if it is already AZEL
*        - Do not bother resetting system on a frameset that is about to be
*          annulled.
*     2008-12-15 (TIMJ):
*        - use smf_get_dims. Tidy up isTordered handling and index handling.
*        - outline of adaptive mode.
*     2008-12-16 (TIMJ):
*        - new API using integer constants rather than strings.
*        - adaptive mode now working (inside and outside loop).
*     2009-11-04 (TIMJ):
*        Sometimes the DA drops TCS packets so we have to deal with
*        this by picking a recent airmass. Won't be completely accurate
*        but will be good enough for extinction correction of points that
*        will not be gridded into a map.
*     2010-01-18 (TIMJ):
*        Trap for bad WVM values and reuse the previous tau. The WVM C code
*        does not trap for this itself and so returns Inf.
*     2010-02-12 (TIMJ):
*        - Handle bad telescope data in "full" mode.
*        - Take control of our default cso tau for WVM mode and initialise
*          the "old" wvm array to bads rather than zero because the WVM
*          uses zero itself.
*     2010-02-16 (TIMJ):
*        Add auto mode to use WVM if available else CSO.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2008-2010 Science and Technology Facilities Council.
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research
*     Council. Copyright (C) 2005-2008 University of British
*     Columbia. All Rights Reserved.

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

/* Standard includes */
#include <stdio.h>
#include <string.h>

/* Starlink includes */
#include "sae_par.h"
#include "ast.h"
#include "mers.h"
#include "msg_par.h"
#include "prm_par.h"
#include "star/slalib.h"
#include "star/one.h"

/* SMURF includes */
#include "smf.h"
#include "smurf_par.h"
#include "smurf_typ.h"

/* internal prototype */
static int is_large_delta_atau ( double airmass1, double elevation1, double tau, int *status);

/* Simple default string for errRep */
#define FUNC_NAME "smf_correct_extinction"

void smf_correct_extinction(smfData *data, smf_tausrc tausrc, smf_extmeth method,
                            double tau, double *allextcorr, int *status) {

  /* Local variables */
  double airmass;          /* Airmass */
  double amstart = VAL__BADD; /* Airmass at start */
  double amend = VAL__BADD;   /* Airmass at end */
  double amprev;           /* Previous airmass in loop */
  double *azel = NULL;     /* AZEL coordinates */
  size_t base;             /* Offset into 3d data array */
  double elstart = VAL__BADD; /* Elevation at start (radians) */
  double elend = VAL__BADD; /* Elevation at end (radians) */
  double extcorr = 1.0;    /* Extinction correction factor */
  smfHead *hdr = NULL;     /* Pointer to full header struct */
  dim_t i;                 /* Loop counter */
  double *indata = NULL;   /* Pointer to data array */
  int isTordered;          /* data order of input data */
  dim_t k;                 /* Loop counter */
  int lbnd[2];             /* Lower bound */
  size_t ndims;            /* Number of dimensions in input data */
  size_t newtau = 0;       /* Flag to denote whether to calculate a
                              new tau from the WVM data */
  double newtwvm[3];       /* Array of WVM temperatures */
  dim_t nframes = 0;       /* Number of frames */
  dim_t npts = 0;          /* Number of data points */
  dim_t nx = 0;            /* # pixels in x-direction */
  dim_t ny = 0;            /* # pixels in y-direction */
  float oldtwvm[3] = {VAL__BADR, VAL__BADR, VAL__BADR}; /* Cached value of WVM temperatures */
  int ubnd[2];             /* Upper bound */
  double *vardata = NULL;  /* Pointer to variance array */
  AstFrameSet *wcs = NULL; /* Pointer to AST WCS frameset */
  double zd = 0;           /* Zenith distance */

  /* Check status */
  if (*status != SAI__OK) return;

  /* If no correction requested, return */
  if( method==SMF__EXTMETH_NONE ) {
    msgOutif(MSG__VERB, "", FUNC_NAME ": Extinction method=none, returning",
             status );
    return;
  }

  /* If no opacity monitor specified generate bad status */
  if( tausrc==SMF__TAUSRC_NULL ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": No extinction monitor specified", 
            status ); 
    return;
  }

  if( smf_history_check( data, FUNC_NAME, status) ) {
    /* If caller not requesting allextcorr fail here */
    if( !allextcorr ) {
      msgSetc("F", FUNC_NAME);
      msgOutif(MSG__VERB," ", 
               "^F has already been run on these data, returning to caller", 
               status);
      return;
    }
  }

  /* Acquire the data order */
  isTordered = data->isTordered;

  /* make sure we have a header */
  hdr = data->hdr;
  if( hdr == NULL ) {
    *status = SAI__ERROR;
    errRep( FUNC_NAME, "Input data has no header", status);
    return;
  }

  /* Do we have 2-D image data? */
  ndims = data->ndims;
  if (ndims == 2) {
    nframes = 1;
    nx = (data->dims)[0];
    ny = (data->dims)[1];
    npts = nx*ny;
  } else {
    /* this routine will also check for dimensionality */
    smf_get_dims( data, &nx, &ny, &npts, &nframes, NULL, NULL, NULL, status );
  }

  /* Tell user we're correcting for extinction */
  msgOutif(MSG__VERB," ", 
           "Correcting for extinction.", status);

  /* Should check data type for double if not allextcorr case */
  if( !allextcorr ) {
    if (!smf_dtype_check_fatal( data, NULL, SMF__DOUBLE, status)) return;
  }

  /* Check that we're not trying to use the WVM for 2-D data */
  if ( ndims == 2 && tausrc == SMF__TAUSRC_WVMRAW ) {
    if ( *status == SAI__OK ) {
      *status = SAI__ERROR;
      errRep( FUNC_NAME, "Method WVMRaw can not be used on 2-D image data", status );
      return;
    }
  } else if (ndims != 3) {
    if (*status == SAI__OK) {
      *status = SAI__ERROR;
      errRepf( FUNC_NAME, "Can not extinction correct data with %zd dimension(s)", status,
              ndims );
      return;
    }
  }

  /* Check auto mode */
  if (tausrc == SMF__TAUSRC_AUTO && *status == SAI__OK) {
    if (data && data->file && data->file->name) {
      msgSetc( "FILE", data->file->name );
    } else {
      msgSetc( "FILE", "<unknown>" );
    }
    if (ndims == 2) {
      /* have to use CSO mode */
      tausrc = SMF__TAUSRC_CSOTAU;
    } else if (ndims == 3) {
      /* check first and last WVM reading. At least one should be good */
      JCMTState * curstate = hdr->allState;
      JCMTState * endstate = &((hdr->allState)[nframes-1]);
      if (curstate->wvm_time != VAL__BADR && curstate->wvm_time > 0) {
        tausrc = SMF__TAUSRC_WVMRAW;
      } else if ( endstate->wvm_time != VAL__BADR && endstate->wvm_time > 0.0) {
        tausrc = SMF__TAUSRC_WVMRAW;
      } else {
        tausrc = SMF__TAUSRC_CSOTAU;
      }
    }
    if (tausrc == SMF__TAUSRC_CSOTAU) {
      msgOutiff( MSG__VERB, "", "Selecting CSO mode for extinction correction of ^FILE", status );
    } else if (tausrc == SMF__TAUSRC_WVMRAW) {
      msgOutiff( MSG__VERB, "", "Selecting WVM mode for extinction correction of ^FILE", status );
    } else {
      /* oops. Fall back position */
      tausrc = SMF__TAUSRC_CSOTAU;
      msgOutiff( MSG__VERB, "", "Selecting CSO mode as unexpected fallback for extinction correction of ^FILE", status );
    }
  }

  /* If we have a CSO Tau then convert it to the current filter. This will also
     convert bad values to a value derived from the header if appropriate. */
  if ( tausrc == SMF__TAUSRC_CSOTAU ) {
    tau = smf_cso2filt_tau( hdr, tau, status );
    /* The tau source is now a real tau */
    tausrc = SMF__TAUSRC_TAU;
  }

  /* it is possible to have gaps in the TCS part of jcmtstate which causes
     difficulties in determining telescope elevation for extinction correction.
     We can not necessarily assume that first and last airmasses are known so
     we find them as a reference.
  */
  if (ndims == 3) {
    JCMTState * curstate = hdr->allState;
    for ( k=0; k<nframes && (*status == SAI__OK) ; k++) {
      amstart = curstate->tcs_airmass;
      elstart = curstate->tcs_az_ac2;
      if (amstart != VAL__BADD && elstart != VAL__BADD) {
        break;
      }
      curstate++;
    }
    /* reset and start from end */
    curstate = &((hdr->allState)[nframes-1]);
    for ( k=nframes; k>0 && (*status == SAI__OK) ; k--) {
      amend = curstate->tcs_airmass;
      elend = curstate->tcs_az_ac2;
      if (amend != VAL__BADD && elend != VAL__BADD) {
        break;
      }
      curstate--;
    }
  } else {
    smf_getfitsd( hdr, "AMSTART", &amstart, status );
    smf_getfitsd( hdr, "ELSTART", &elstart, status );
    smf_getfitsd( hdr, "AMEND", &amend, status );
    smf_getfitsd( hdr, "ELEND", &elend, status );
    if (elstart != VAL__BADD) elstart *= DD2R;
    if (elend != VAL__BADD) elend *= DD2R;

  }

  if (*status == SAI__OK && (amstart == VAL__BADD || amend == VAL__BADD)) {
    *status = SAI__ERROR;
    errRep( "", "No good airmass values found in JCMTSTATE structure for these data",
            status );
  }

  /* if we are not doing WVM correction but are in adaptive mode we can determine
     whether or not we will have to use full or single mode just by looking at the
     airmass data. */
  if (ndims == 3 && tausrc != SMF__TAUSRC_WVMRAW && method == SMF__EXTMETH_ADAPT) {
    /* first and last is a good approximation given that most SCUBA-2 files will only
       be a minute duration. */
    double refel;
    double refam;

    /* only need to examine the largest airmass */
    if (amstart > amend) {
      refam = amstart;
      refel = elstart;
    } else {
      refam = amend;
      refel = elend;
    }

    /* and choose a correction method */
    if (is_large_delta_atau( refam, refel, tau, status) ) {
      method = SMF__EXTMETH_FULL;
      msgOutiff(MSG__DEBUG, " ",
               "Adaptive extinction algorithm selected per-bolometer airmass value "
               "per time slice (am=%g, tau=%g)", status, refam, tau);
    } else {
      msgOutiff(MSG__DEBUG, " ",
               "Adaptive extinction algorithm selected single airmass value per time slice"
               " (am=%g, tau=%g)", status, refam, tau);
      method = SMF__EXTMETH_SINGLE;
    }

  }

  /* Assign pointer to input data array if status is good */
  if ( *status == SAI__OK ) {
    indata = (data->pntr)[0]; 
    vardata = (data->pntr)[1];
  }
  /* It is more efficient to call astTranGrid than astTran2
     Allocate memory in adaptive mode just in case. */
  if (method == SMF__EXTMETH_FULL || method == SMF__EXTMETH_ADAPT ) {
    azel = smf_malloc( 2*npts, sizeof(*azel), 0, status );
  }

  /* Jump to the cleanup section if status is bad by this point
     since we need to free memory */
  if (*status != SAI__OK) goto CLEANUP;

  /* Array bounds for astTranGrid call */
  lbnd[0] = 1;
  lbnd[1] = 1;
  ubnd[0] = nx;
  ubnd[1] = ny;

  /* Store the previous good airmass if we need it for a gap */
  amprev = amstart;

  /* initialise the tau if we are in WVM mode. Use an intelligent
     default in case we have some bad wvm data at the start.*/
  if (tausrc == SMF__TAUSRC_WVMRAW) {
    tau = smf_cso2filt_tau( hdr, VAL__BADD, status );
  }

  /* Loop over number of time slices/frames */

  for ( k=0; k<nframes && (*status == SAI__OK) ; k++) {
    /* Flags to indicate which mode we are using for this time slice */
    int quick = 0;  /* use single airmass */
    int adaptive = 0; /* switch from quick to full if required */
    if (method == SMF__EXTMETH_SINGLE) {
      quick = 1;
    } else if (method == SMF__EXTMETH_ADAPT) {
      quick = 1;
      adaptive = 1;
    }

    /* Call tslice_ast to update the header for the particular
       timeslice. If we're in QUICK mode then we don't need the WCS */
    smf_tslice_ast( data, k, !quick, status );

    /* See if we have a new WVM value */
    if (tausrc == SMF__TAUSRC_WVMRAW) {
      newtwvm[0] = hdr->state->wvm_t12;
      newtwvm[1] = hdr->state->wvm_t42;
      newtwvm[2] = hdr->state->wvm_t78;
      /* Have any of the temperatures changed? Are any of the new
         temperatures bad? If bad we'll just reuse the previous value. */
      if ( newtwvm[0] == VAL__BADR ||
           newtwvm[1] == VAL__BADR ||
           newtwvm[2] == VAL__BADR ) {
        newtau = 0;
      } else if ( (newtwvm[0] != oldtwvm[0]) ||
                  (newtwvm[1] != oldtwvm[1]) ||
                  (newtwvm[2] != oldtwvm[2]) ) {
        newtau = 1;
        oldtwvm[0] = newtwvm[0];
        oldtwvm[1] = newtwvm[1];
        oldtwvm[2] = newtwvm[2];
      } else {
        newtau = 0;
      }
      if (newtau) {
        tau = smf_calc_wvm( hdr, amprev, status );
        newtau = 0;
        /* Check status and/or value of tau */
        if ( tau == VAL__BADD ) {
          if ( *status == SAI__OK ) {
            *status = SAI__ERROR;
            errRep("", "Error calculating tau from WVM temperatures", 
                   status);
          }
        }
      }
    }

    /* in all modes we need to keep track of the previous airmass in case
       we need to gap fill bad telescope data */
    if ( quick && ndims == 2 ) {
      /* for 2-D we use the FITS header directly */
      /* This may change depending on exact FITS keyword */
      airmass = amstart;

      /* speed is not an issue for a 2d image */
      adaptive = 0;

    } else {
      /* Else use airmass value in state structure */
      airmass = hdr->state->tcs_airmass;

      /* if things have gone bad use the previous value else store
         this value. We also need to switch to quick mode and disable adaptive. */
      if (airmass == VAL__BADD) {
        airmass = amprev;
        quick = 1;
        adaptive = 0;
      } else {
        amprev = airmass;
      }
    }

    /* If we're using the FAST application method, we assume a single
       airmass and tau for the whole array but we have to consider adaptive mode */
    if (quick) {
      /* we have an airmass, see if we need to provide per-pixel correction */
      if (adaptive) {
        if (is_large_delta_atau( airmass, hdr->state->tcs_az_ac2, tau, status) ) {
          /* we need WCS if we disable fast mode */
          quick = 0;
          smf_tslice_ast( data, k, 1, status );
        }
      }

      if (quick) extcorr = exp(airmass*tau);
    }

    if (!quick) {
      /* Not using quick so retrieve WCS to obtain elevation info */
      wcs = hdr->wcs;
      /* Check current frame, store it and then select the AZEL
         coordinate system */
      if (wcs != NULL) {
        if (strcmp(astGetC(wcs,"SYSTEM"), "AZEL") != 0) {
          astSet( wcs, "SYSTEM=AZEL"  );
        }
        /* Transfrom from pixels to AZEL */
        astTranGrid( wcs, 2, lbnd, ubnd, 0.1, 1000000, 1, 2, npts, azel );
        if (!astOK) {
          if (*status == SAI__OK) {
            *status = SAI__ERROR;
            errRep( FUNC_NAME, "Error from AST when attempting to set SYSTEM to AZEL: WCS is NULL", status);
          }
        }
      } else {
        /* this time slice may have bad telescope data so we trap for this and re-enable
           "quick" with a default value. We'll only get here if airmass was good but
           SMU was bad so we use the good airmass. The map-maker won't be using this
           data but we need to use something plausible so that we do not throw off the FFTs */
        quick = 1;
        extcorr = exp(airmass*tau);
      }
    } 
    /* Loop over data in time slice. Start counting at 1 since this is
       the GRID coordinate frame */
    base = npts * k;  /* Offset into 3d data array (time-ordered) */

    for (i=0; i < npts && ( *status == SAI__OK ); i++ ) {
      /* calculate array indices - assumes that astTranGrid fills up
         azel[] array in same order as bolometer data are aligned */
      size_t index;
      if ( isTordered ) {
        index = base + i;
      } else {
        index = k + (nframes * i);
      }

      if (!quick) {
        zd = M_PI_2 - azel[npts+i];
        airmass = slaAirmas( zd );
        extcorr = exp(airmass*tau);
      }
	
      if( allextcorr ) {
        /* Store extinction correction factor */
        allextcorr[index] = extcorr;
      } else {
        /* Otherwise Correct the data */
        if (extcorr != VAL__BADD) {
          if( indata && (indata[index] != VAL__BADD) ) {
            indata[index] *= extcorr;
          }

          /* Correct the variance */
          if( vardata && (vardata[index] != VAL__BADD) ) {
            vardata[index] *= extcorr * extcorr;
          }
        } else {
          indata[index] = VAL__BADD;
          vardata[index] = VAL__BADD;
        }
      }

    }
    
    /* Note that we do not need to free "wcs" or revert its SYSTEM
       since smf_tslice_ast will replace the object immediately. */
  } /* End loop over timeslice */

  /* Add history entry if !allextcorr */
  if( (*status == SAI__OK) && !allextcorr ) {
    smf_history_add( data, FUNC_NAME, status);
  }

 CLEANUP:
  if (azel) azel = smf_free(azel,status);

}

/* Add footprint to the reference elevation and compare it to the reference airmass.
   Combine with tau and return true if some threshold is exceeded. */

static int is_large_delta_atau ( double airmass1, double elevation1, double tau,
                                 int *status) {
  double elevation2; /* elevation at edge of array */
  double airmass2;   /* airmass at edge of array */
  double delta;      /* difference between airmass1 and airmass2 times the tau  */
  const double footprint = 10.0 * DD2R / 60.0;  /* 10 arcmin */
  const double corrthresh = 0.01; /* threshold to switch from quick to slow as fraction */
  
  if (*status != SAI__OK) return 0;

  /* short circuit if tau is extremely small */
  if (tau < 0.000001) return 0;

  /* Bad telescope information */
  if (elevation1 == VAL__BADD) return 0;

  /* get the elevation and add on the array footprint. Calculate the airmass
     at the new location and find the difference to the reference airmass.
     The fractional error in exp(Atau) is (delta Airmass)*tau.
  */

  elevation2 = elevation1 - footprint;  /* want smaller el for larger am */
  airmass2 = slaAirmas( M_PI_2 - elevation2 );
  delta = fabs(airmass1-airmass2) * tau;
  if (delta > corrthresh) {
    return 1;
  } else {
    return 0;
  }
}
