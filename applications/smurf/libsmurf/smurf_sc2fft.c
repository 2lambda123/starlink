/*
*+
*  Name:
*     SC2FFT

*  Purpose:
*     Fourier Transform SCUBA-2 time-series data

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_sc2fft( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine performs the forward or inverse FFT of SCUBA-2
*     time-series data.  The FFT of the data are stored in a
*     4-dimensional array with dimensions frequency, xbolo, ybolo,
*     component (where component is a dimension of length 2 holding
*     the real and imaginary parts). The inverse flag is used to
*     transform back to the time domain from the frequency domain.  If
*     the data are already in the requested domain, the ouput file is
*     simply a copy of the input file.

*  Notes:
*     Transforming data loses the VARIANCE and QUALITY components.

*  ADAM Parameters:
*     AVPSPEC = _LOGICAL (Read)
*          Calculate average power spectrum over "good" bolometers
*     AVPSPECTHRESH = _DOUBLE (Read)
*          N-sigma noise threshold to define "good" bolometers for AVPSPEC
*     BBM = NDF (Read)
*          Group of files to be used as bad bolometer masks. Each data file
*          specified with the IN parameter will be masked. The corresponding
*          previous mask for a subarray will be used. If there is no previous
*          mask the closest following will be used. It is not an error for
*          no mask to match. A NULL parameter indicates no mask files to be
*          supplied. [!]
*     FLAT = _LOGICAL (Read)
*          If set ensure data are flatfielded. If not set do not scale the
*          data in any way (but convert to DOUBLE). [TRUE]
*     IN = NDF (Read)
*          Input files to be transformed.
*     INVERSE = _LOGICAL (Read)
*          Perform inverse transform. [FALSE]
*     MSG_FILTER = _CHAR (Read)
*          Control the verbosity of the application. Values can be
*          NONE (no messages), QUIET (minimal messages), NORMAL,
*          VERBOSE, DEBUG or ALL. [NORMAL]
*     NGOOD = _INTEGER (Write)
*          Number of good bolometers which contribute to average power
*          spectrum.
*     OUT = NDF (Write)
*          Output files. The number of output files can differ from
*          the number of input files due to darks being filtered out
*          and also to files from the same sequence being concatenated
*          before aplying the FFT.
*     OUTFILES = LITERAL (Write)
*          The name of text file to create, in which to put the names of
*          all the output NDFs created by this application (one per
*          line). If a null (!) value is supplied no file is created. [!]
*     POLAR = _LOGICAL (Read)
*          Use polar representation (amplitude, argument) of
*          FFT. [FALSE]
*     POWER = _LOGICAL (Read)
*          Use polar representation of FFT with squared
*          amplitudes. [FALSE]
*     ZEROBAD = _LOGICAL (Read)
*          Zero any bad values in the data before taking FFT. [TRUE]

*  Related Applications:
*     SMURF: SC2CONCAT, SC2CLEAN, CALCNOISE

*  Authors:
*     Edward Chapin (UBC)
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2008-07-22 (EC):
*        Initial version - based on sc2clean task
*     2008-07-25 (TIMJ):
*        Use kaplibs for group in/out.
*     2008-07-30 (EC):
*        Handle raw data (filter out / apply darks, flatfield)
*     2009-03-30 (TIMJ):
*        Add OUTFILES parameter.
*     2009-04-30 (EC):
*        Use threads
*     2009-10-13 (TIMJ):
*        Concatenate files from the same sequence.
*     2009-12-07 (EC):
*        Add FLAT parameter.
*     2010-02-09 (AGG):
*        - Store number of good bolometers used to create average power
*          spectrum in NGOOD parameter.
*        - Calculate lowest available frequency based on length of input
*          data stream.
*     2010-03-11 (TIMJ):
*        Support flatfield ramps.
*     2010-05-12 (EC):
*        Add zerobad option.
*     2010-06-25 (TIMJ):
*        Add BBM parameter
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2008-2010 Science and Technology Facilities Council.
*     Copyright (C) 2008-2010 University of British Columbia.
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

#include <string.h>
#include <stdio.h>

#include "star/ndg.h"
#include "star/grp.h"
#include "ndf.h"
#include "mers.h"
#include "par.h"
#include "prm_par.h"
#include "sae_par.h"
#include "msg_par.h"
#include "fftw3.h"

#include "smurf_par.h"
#include "libsmf/smf.h"
#include "smurflib.h"
#include "libsmf/smf_err.h"
#include "sc2da/sc2store.h"

#define FUNC_NAME "smurf_sc2fft"
#define TASK_NAME "SC2FFT"

void smurf_sc2fft( int *status ) {

  int avpspec=0;            /* Flag for doing average power spectrum */
  double avpspecthresh=0;   /* Threshold noise for detectors in avpspec */
  Grp * basegrp = NULL;     /* Basis group for output filenames */
  smfArray *bbms = NULL;    /* Bad bolometer masks */
  smfArray *concat=NULL;    /* Pointer to a smfArray */
  size_t contchunk;         /* Continuous chunk counter */
  smfArray *darks = NULL;   /* dark frames */
  int ensureflat;           /* Flag for flatfielding data */
  Grp *fgrp = NULL;         /* Filtered group, no darks */
  smfArray *flatramps = NULL;/* Flatfield ramps */
  size_t gcount=0;          /* Grp index counter */
  size_t i;                 /* Loop counter */
  smfGroup *igroup=NULL;    /* smfGroup corresponding to igrp */
  Grp *igrp = NULL;         /* Input group of files */
  int inverse=0;            /* If set perform inverse transform */
  int isfft=0;              /* Are data fft or real space? */
  dim_t maxconcat=0;        /* Longest continuous chunk length in samples */
  size_t ncontchunks=0;     /* Number continuous chunks outside iter loop */
  smfData *odata=NULL;      /* Pointer to output smfData to be exported */
  Grp *ogrp = NULL;         /* Output group of files */
  size_t outsize;           /* Total number of NDF names in the output group */
  int polar=0;              /* Flag for FFT in polar coordinates */
  int power=0;              /* Flag for squaring amplitude coeffs */
  size_t size;              /* Number of files in input group */
  smfData *tempdata=NULL;   /* Temporary smfData pointer */
  smfWorkForce *wf = NULL;  /* Pointer to a pool of worker threads */
  int zerobad;              /* Zero VAL__BADD before taking FFT? */

  /* Main routine */
  ndfBegin();

  /* Find the number of cores/processors available and create a pool of
     threads of the same size. */
  wf = smf_create_workforce( smf_get_nthread( status ), status );

  /* Get input file(s) */
  kpg1Rgndf( "IN", 0, 1, "", &igrp, &size, status );

  /* Filter out darks */
  smf_find_science( igrp, &fgrp, 1, NULL, NULL, 1, 1, SMF__NULL, &darks,
                    &flatramps, NULL, status );

  /* input group is now the filtered group so we can use that and
     free the old input group */
  size = grpGrpsz( fgrp, status );
  grpDelet( &igrp, status);
  igrp = fgrp;
  fgrp = NULL;

  /* We now need to combine files from the same subarray and same sequence
     to form a continuous time series */
  smf_grp_related( igrp, size, 1, 0, NULL, &maxconcat, NULL, &igroup,
                   &basegrp, NULL, status );

  /* Get output file(s) */
  size = grpGrpsz( basegrp, status );
  if( size > 0 ) {
    kpg1Wgndf( "OUT", basegrp, size, size, "More output files required...",
               &ogrp, &outsize, status );
  } else {
    msgOutif(MSG__NORM, " ", TASK_NAME ": All supplied input frames were DARK,"
             " nothing to do", status );
  }

  /* Get group of bolometer masks and read them into a smfArray */
  smf_request_mask( "BBM", &bbms, status );

  /* Obtain the number of continuous chunks and subarrays */
  if( *status == SAI__OK ) {
    ncontchunks = igroup->chunk[igroup->ngroups-1]+1;
  }
  msgOutiff( MSG__NORM, "", "Found %zu continuous chunk%s", status, ncontchunks,
             (ncontchunks > 1 ? "s" : "") );

  /* Are we flatfielding? */
  parGet0l( "FLAT", &ensureflat, status );

  /* Are we doing an inverse transform? */
  parGet0l( "INVERSE", &inverse, status );

  /* Are we using polar coordinates instead of cartesian for the FFT? */
  parGet0l( "POLAR", &polar, status );

  /* Are we going to assume amplitudes are squared? */
  parGet0l( "POWER", &power, status );

  /* Are we going to zero bad values first? */
  parGet0l( "ZEROBAD", &zerobad, status );

  /* Are we calculating the average power spectrum? */
  parGet0l( "AVPSPEC", &avpspec, status );

  if( avpspec ) {
    power = 1;
    parGet0d( "AVPSPECTHRESH", &avpspecthresh, status );
  }

  /* If power is true, we must be in polar form */
  if( power && !polar) {
    msgOutif( MSG__NORM, " ", TASK_NAME
              ": power spectrum requested so setting POLAR=TRUE", status );
    polar = 1;
  }

  gcount = 1;
  for( contchunk=0;(*status==SAI__OK)&&contchunk<ncontchunks; contchunk++ ) {
    size_t idx;

    /* Concatenate this continuous chunk but forcing a raw data read.
       We will need quality. */
    smf_concat_smfGroup( wf, igroup, darks, NULL, flatramps, contchunk, ensureflat, 1,
                         NULL, 0, NULL, NULL, 0, 0, 0, 1, &concat, status );

    /* Now loop over each subarray */
    /* Export concatenated data for each subarray to NDF file */
    for( idx=0; (*status==SAI__OK)&&idx<concat->ndat; idx++ ) {
      if( concat->sdata[idx] ) {
        smfData * idata = concat->sdata[idx];
        int provid = NDF__NOID;
        dim_t nbolo;                /* Number of detectors  */
        dim_t ndata;                /* Number of data points */

        /* Apply a mask to the quality array and data array */
        smf_apply_mask( idata, bbms, SMF__BBM_QUAL|SMF__BBM_DATA, 0, status );

        smf_get_dims( idata,  NULL, NULL, &nbolo, NULL, &ndata, NULL, NULL,
                      status );


        /* Check for double precision data */
        if( idata->dtype != SMF__DOUBLE ) {
          *status = SAI__ERROR;
          errRep( "", FUNC_NAME ": data are not double precision.", status );
        }

        /* Are we zeroing VAL__BADD? */
        if( zerobad ) {
          double *data= (double *) idata->pntr[0];

          for( i=0; i<ndata; i++ ) {
            if( data[i] == VAL__BADD ) {
              data[i] = 0;
            }
          }
        }

        /* Check whether we need to transform the data at all */
        isfft = smf_isfft(idata,NULL,NULL,NULL,status);

        if( isfft && avpspec ) {
          *status = SAI__ERROR;
          errRep( "", FUNC_NAME
                  ": to calculate average power spectrum input data cannot "
                  "be FFT", status );
        }

        if( (*status == SAI__OK) &&
            (smf_isfft(idata,NULL,NULL,NULL,status) == inverse) ) {

          if( avpspec ) {
            /* If calculating average power spectrum do the transforms with
               smf_bolonoise so that we can also measure the noise of
               each detector */

            double *whitenoise=NULL;
            smf_qual_t *bolomask=NULL;
            double mean, sig, freqlo;
            size_t ngood, newgood;

            whitenoise = astCalloc( nbolo, sizeof(*whitenoise), 1 );
            bolomask = astCalloc( nbolo, sizeof(*bolomask), 1 );

	    freqlo = 1. / (idata->hdr->steptime * idata->hdr->nframes);

            smf_bolonoise( wf, idata, 1, freqlo, SMF__F_WHITELO,
                           SMF__F_WHITEHI, 0, 1, 0, whitenoise, NULL, &odata,
                           status );

            /* Initialize quality */
            for( i=0; i<nbolo; i++ ) {
              if( whitenoise[i] == VAL__BADD ) {
                bolomask[i] = SMF__Q_BADB;
              }
            }

            ngood=-1;
            newgood=0;

            /* Iteratively cut n-sigma noisy outlier detectors */
            while( ngood != newgood ) {
              ngood = newgood;
              smf_stats1D( whitenoise, 1, nbolo, bolomask, 1, SMF__Q_BADB,
                           &mean, &sig, NULL, status );
              msgOutiff( MSG__DEBUG, "",
                         "SC2FFT: mean=%lf sig=%lf ngood=%li\n", status,
                         mean, sig, ngood);

              newgood=0;
              for( i=0; i<nbolo; i++ ) {
                if( whitenoise[i] != VAL__BADD ){
                  if( (whitenoise[i] - mean) > 3.*sig ) {
                    whitenoise[i] = VAL__BADD;
                    bolomask[i] = SMF__Q_BADB;
                  } else {
                    newgood++;
                  }
                }
              }
            }

            msgOutf( "",
                     "SC2FFT: Calculating average power spectrum of best %li "
                     " bolometers.", status, newgood);

            /* Calculate the average power spectrum of good detectors */
            tempdata = smf_fft_avpspec( odata, bolomask, 1, SMF__Q_BADB,
                                        status );
            smf_close_file( &odata, status );
            whitenoise = astFree( whitenoise );
            bolomask = astFree( bolomask );
            odata = tempdata;
            tempdata = NULL;
	    /* Store the number of good bolometers */
	    parPut0i( "NGOOD", newgood, status );
          } else {
            /* Otherwise do forward/inverse transforms here as needed */

            /* If inverse transform convert to cartesian representation first */
            if( inverse && polar ) {
              smf_fft_cart2pol( idata, 1, power, status );
            }

            /* Tranform the data */
            odata = smf_fft_data( wf, idata, inverse, 0, status );
            smf_convert_bad( odata, status );

            if( inverse ) {
              /* If output is time-domain, ensure that it is ICD bolo-ordered */
              smf_dataOrder( odata, 1, status );
            } else if( polar ) {
              /* Store FFT of data in polar form */
              smf_fft_cart2pol( odata, 0, power, status );
            }
          }

          /* open a reference input file for provenance propagation */
          ndgNdfas( basegrp, gcount, "READ", &provid, status );

          /* Export the data to a new file */
          smf_write_smfData( odata, NULL, NULL, ogrp, gcount, provid,
                             status );

          /* Free resources */
          ndfAnnul( &provid, status );
          smf_close_file( &odata, status );
        } else {
          msgOutif( MSG__NORM, " ",
                    "Data are already transformed. No output will be produced",
                    status );
        }
      }

      /* Update index into group */
      gcount++;
    }

    /* Close the smfArray */
    smf_close_related( &concat, status );
  }

  /* Write out the list of output NDF names, annulling the error if a null
     parameter value is supplied. */
  if( *status == SAI__OK ) {
    grpList( "OUTFILES", 0, 0, NULL, ogrp, status );
    if( *status == PAR__NULL ) errAnnul( status );
  }

  /* Tidy up after ourselves: release the resources used by the grp routines */
  grpDelet( &igrp, status);
  grpDelet( &ogrp, status);
  if (basegrp) grpDelet( &basegrp, status );
  if( igroup ) smf_close_smfGroup( &igroup, status );
  if( wf ) wf = smf_destroy_workforce( wf );
  if( flatramps ) smf_close_related( &flatramps, status );
  if (bbms) smf_close_related( &bbms, status );

  ndfEnd( status );

  /* Ensure that FFTW doesn't have any used memory kicking around */
  fftw_cleanup();
}
