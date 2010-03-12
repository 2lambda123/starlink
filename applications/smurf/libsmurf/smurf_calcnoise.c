/*
*+
*  Name:
*     CALCNOISE

*  Purpose:
*     Calculate noise image

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_calcnoise( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine calculates the white noise on the array by performing
*     an FFT to generate a power spectrum and then extracting the
*     data between two frequency ranges. It additionally calculates an
*     NEP image and an image of the ratio of the power at a specified
*     frequency to the whitenoise.

*  ADAM Parameters:
*     FLOW = _DOUBLE (Given)
*          Frequency to use when determining noise ratio image. The noise
*          ratio image is determined by dividing the power at this frequency
*          by the white noise [0.5]
*     FREQ = _DOUBLE (Given)
*          Frequency range (Hz) to use to calculate the white noise [2,10]
*     IN = NDF (Read)
*          Input files to be transformed. Files from the same sequence
*          will be combined.
*     MSG_FILTER = _CHAR (Read)
*          Control the verbosity of the application. Values can be
*          NONE (no messages), QUIET (minimal messages), NORMAL,
*          VERBOSE, DEBUG or ALL. [NORMAL]
*     OUT = NDF (Write)
*          Output files (either noise or NEP images depending on the NEP
*          parameter). Number of output files may differ from the
*          number of input files. These will be 2 dimensional.
*     OUTFILES = LITERAL (Write)
*          The name of text file to create, in which to put the names of
*          all the output NDFs created by this application (one per
*          line) from the OUT parameter. If a null (!) value is supplied
*          no file is created. [!]
*     POWER = NDF (Write)
*          Output files to contain the power spectra for each processed
*          chunk. There will be the same number of output files as
*          created for the OUT parameter. If a null (!) value
*          is supplied no files will be created. [!]

*  Notes:
*     - NEP and NOISERATIO images are stored in the .MORE.SMURF extension
*     - NEP image is only created for raw, unflatfielded data.
*     - If the data have flatfield information available the noise and
*     NOISERATIO images will be masked by the flatfield bad bolometer mask.
*     The mask can be removed using SETQUAL or SETBB (clear the bad bits mask).

*  Related Applications:
*     SMURF: SC2CONCAT, SC2CLEAN, SC2FFT

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     2009-10-01 (TIMJ):
*        Initial version - based on sc2fft task
*     2009-10-07 (TIMJ):
*        Add NEP
*     2009-10-08 (TIMJ):
*        Remove NEP parameter. Write NEP and noise ratio image to extension.
*     2009-10-13 (TIMJ):
*        Add POWER and FLOW parameters.
*     2009-10-21 (TIMJ):
*        Propagate units properly if we do not have raw data.
*     2009-11-30 (TIMJ):
*        Add quality mask so that bolometers known to be masked by
*        bad responsivity will be masked in the noise data.
*     2010-01-28 (TIMJ):
*        Flatfield routines now use smfData
*     2010-02-03 (TIMJ):
*        Update smf_flat_responsivity API
*     2010-02-04 (TIMJ):
*        New smf_flat_responsibity and smf_flat_smfData API to support
*        flatfield method.
*     2010-03-09 (TIMJ):
*        Change type of flatfield method in smfDA
*     2010-03-11 (TIMJ):
*        Support flatfield ramps.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2009-2010 Science and Technology Facilities Council.
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
#include "star/one.h"

#include "smurf_par.h"
#include "libsmf/smf.h"
#include "smurflib.h"
#include "libsmf/smf_err.h"
#include "sc2da/sc2store.h"

#define FUNC_NAME "smurf_calcnoise"
#define TASK_NAME "CALCNOISE"
#define CREATOR PACKAGE_UPCASE ":" TASK_NAME

static smfData *
smf__create_bolfile_extension( const Grp * ogrp, size_t gcount,
                               const smfData *refdata, const char hdspath[], 
                               const char datalabel[], const char units[],
                               int * status );


void smurf_calcnoise( int *status ) {

  Grp * basegrp = NULL;     /* Basis group for output filenames */
  smfArray *concat=NULL;     /* Pointer to a smfArray */
  size_t contchunk;          /* Continuous chunk counter */
  Grp *dkgrp = NULL;        /* Group of dark frames */
  size_t dksize = 0;        /* Number of darks found */
  Grp *fgrp = NULL;         /* Filtered group, no darks */
  smfArray * flatramps = NULL; /* Flatfield ramps */
  size_t gcount=0;           /* Grp index counter */
  size_t i=0;               /* Counter, index */
  Grp *igrp = NULL;         /* Input group of files */
  smfGroup *igroup=NULL;     /* smfGroup corresponding to igrp */
  dim_t maxconcat=0;         /* Longest continuous chunk length in samples */
  size_t ncontchunks=0;      /* Number continuous chunks outside iter loop */
  Grp *ogrp = NULL;         /* Output group of files */
  size_t outsize;           /* Total number of NDF names in the output group */
  Grp *powgrp = NULL;       /* Group for output power spectra */
  size_t size;              /* Number of files in input group */
  smfWorkForce *wf = NULL;  /* Pointer to a pool of worker threads */
  double f_low = 0.5;       /* Frequency to use for noise ratio image */
  double freqdef[] = { SMF__F_WHITELO,
                       SMF__F_WHITEHI }; /* Default values for frequency range */
  double freqs[2];          /* Frequencies to use for white noise */

  if (*status != SAI__OK) return;

  /* Main routine */
  ndfBegin();

  /* Find the number of cores/processors available and create a pool of
     threads of the same size. */
  wf = smf_create_workforce( smf_get_nthread( status ), status );

  /* Get frequency range of interest for white noise measurement */
  parGdr1d( "FREQ", 2, freqdef, 0.0, 50.0, 1, freqs, status );
  /* Get the low frequency to use for the noise ratio */
  parGdr0d( "FLOW", f_low, 0.0, 50.0, 1, &f_low, status );

  msgOutf( "", "Calculating noise between %g and %g Hz and noise ratio for %g Hz", status,
           freqs[0], freqs[1], f_low);


  /* Get input file(s) */
  kpg1Rgndf( "IN", 0, 1, "", &igrp, &size, status );

  /* Filter out darks */
  smf_find_science( igrp, &fgrp, &dkgrp, NULL, 1, 1, SMF__NULL, NULL, &flatramps, status );

  /* input group is now the filtered group so we can use that and
     free the old input group */
  size = grpGrpsz( fgrp, status );
  dksize = grpGrpsz( dkgrp, status );
  grpDelet( &igrp, status );

  /* If we have all darks then we assume it's the dark files
     that we are actually wanting to use for the noise. Otherwise
     assume that the darks are to be ignored. */
  if (size > 0) {
    igrp = fgrp;
    fgrp = NULL;
    grpDelet( &dkgrp, status ); /* no longer needed */
  } else {
    msgOutif( MSG__NORM, " ", TASK_NAME ": Calculating noise properties of darks",
              status );
    size = dksize;
    igrp = dkgrp;
    dkgrp = NULL;
    grpDelet( &fgrp, status );
  }

  /* We now need to combine files from the same subarray and same sequence
     to form a continuous time series */
  smf_grp_related( igrp, size, 1, 0, &maxconcat, NULL, &igroup,
                   &basegrp, status );

  /* Get output file(s) */
  size = grpGrpsz( basegrp, status );
  kpg1Wgndf( "OUT", basegrp, size, size, "More output files required...",
             &ogrp, &outsize, status );

  /* and see if we want power spectra */
  if (*status == SAI__OK) {
    kpg1Wgndf( "POWER", basegrp, size, size, "More output files required...",
               &powgrp, &outsize, status );
    if (*status == PAR__NULL) {
      errAnnul( status );
    }
  }

  /* Obtain the number of continuous chunks and subarrays */
  if( *status == SAI__OK ) {
    ncontchunks = igroup->chunk[igroup->ngroups-1]+1;
  }
  msgOutiff( MSG__NORM, "", "Found %zu continuous chunk%s", status, ncontchunks,
             (ncontchunks > 1 ? "s" : "") );

  /* Loop over input data as contiguous chunks */
  gcount = 1;
  for( contchunk=0;(*status==SAI__OK)&&contchunk<ncontchunks; contchunk++ ) {
    size_t idx;

    /* Concatenate this continuous chunk but forcing a raw data read.
       We will need quality. */
    smf_concat_smfGroup( wf, igroup, NULL, NULL, flatramps, contchunk, 0, 1, NULL, 0, NULL,
                         NULL, 0, 0, 0, 1, &concat, status );

    /* Now loop over each subarray */
    /* Export concatenated data for each subarray to NDF file */
    for( idx=0; (*status==SAI__OK)&&idx<concat->ndat; idx++ ) {
      if( concat->sdata[idx] ) {
        smfData *thedata = concat->sdata[idx];
        smfData *outdata = NULL;
        smfData *ratdata = NULL;
        smfData *powdata = NULL;
        int do_nep = 1;
        char noiseunits[SMF__CHARLABEL];

        if ( ! thedata || !thedata->hdr ) {
          *status = SAI__ERROR;
          errRepf( "", "Concatenated data set %zu is missing a header. Should not be possible",
                   status, idx);
          break;
        }

        /* Convert the data to amps if we have DAC units. Else leave them
           alone. */
        if ( strncmp(thedata->hdr->units, "DAC", 3) == 0) {
          msgOutiff( MSG__VERB, "", "Scaling data from '%s' to amps",
                     status, thedata->hdr->units );
          smf_scalar_multiply( thedata, RAW2CURRENT, status );
          smf_set_clabels( NULL, NULL, SIPREFIX "A", thedata->hdr, status );
        } else {
          do_nep = 0;
          msgOutiff( MSG__VERB, "",
                     "Data in units of '%s' and not raw, so not generating NEP image",
                     status, strlen(thedata->hdr->units) ? thedata->hdr->units : "<none>" );
        }

        one_strlcpy( noiseunits, thedata->hdr->units, sizeof(noiseunits), status );
        if (strlen(noiseunits)) one_strlcat( noiseunits, " ", sizeof(noiseunits), status );
        one_strlcat( noiseunits, "Hz**-0.5", sizeof(noiseunits), status );

        /* Apodize */
        smf_apodize(thedata, NULL, SMF__MAXAPLEN, status );

        /* Create the output file if required, else a malloced smfData */
        smf_create_bolfile( ogrp, gcount, thedata, "Noise",
                            noiseunits, 1, &outdata, status );

        /* Create groups to handle the NEP and ratio images */
        ratdata = smf__create_bolfile_extension( ogrp, gcount, thedata,
                                                 ".MORE.SMURF.NOISERATIO",
                                                 "Noise Ratio", NULL, status );

        if (*status == SAI__OK) {
          double * od = (outdata->pntr)[0];
          smf_bolonoise( wf, thedata, NULL, 0, f_low, freqs[0], freqs[1], 10.0, 1,
                         (outdata->pntr)[0], (ratdata->pntr)[0],
                         (powgrp ? &powdata : NULL), status );

          /* Bolonoise gives us a variance - we want square root */
          for (i = 0; i < (outdata->dims)[0]*(outdata->dims)[1]; i++) {
            if ( od[i] != VAL__BADD ) od[i] = sqrt( od[i] );
          }

          if (powdata) {
            int provid = NDF__NOID;
            /* open a reference input file for provenance propagation */
            ndgNdfas( basegrp, gcount, "READ", &provid, status );
            smf_write_smfData( powdata, NULL, NULL, NULL, powgrp, gcount, provid, status );
            smf_close_file( &powdata, status );
            ndfAnnul( &provid, status );
          }

        }

        /* we want to use a quality mask derived from the flatfield
           and apply it to the NOISE and NOISERATIO data so that we can
           give people the option of looking at all the data or all
           the data with working bolometers */
        if (*status == SAI__OK) {
          smfDA *da = thedata->da;
          size_t ngood = 0;
          smfData * respmap = NULL;

          if (da) {
            smf_create_bolfile( NULL, 1, thedata, "Responsivity", "A/W",
                                0, &respmap, status );
            if (*status == SAI__OK) {
              /* use a snr of 5 since we don't mind if we get a lot of
                 bolometers that are a bit dodgy since the point is the NEP */
              smfData * powval;
              smfData * bolval;
              smf_flatmeth flatmethod;
              smf_flat_smfData( thedata, &flatmethod, &powval, &bolval, status );
              ngood = smf_flat_responsivity( flatmethod, respmap, 5.0, 1, powval, bolval, NULL, status);
              if (powval) smf_close_file( &powval, status );
              if (bolval) smf_close_file( &bolval, status );
            }
          } else {
            if (do_nep) {
              *status = SAI__ERROR;
              errRep( " ", "Attempting to calculate NEP image but no"
                      " flatfield information available", status);
            } else {
              /* we might simply be running calcnoise on data
                 that already have been flatfielded */
              msgOutif( MSG__VERB, " ", "Unable to add bad bolometer mask since"
                        " no flatfield information avaialable", status);
            }
          }

          if (do_nep) {
            smfData * nepdata = NULL;

            if (*status == SAI__OK && ngood == 0) {
              *status = SAI__ERROR;
              errRep( "", "No good responsivities found in flatfield."
                      " Unable to calculate NEP", status );
            }

            /* now create the output image for NEP data */
            nepdata = smf__create_bolfile_extension( ogrp, gcount, thedata,
                                                     ".MORE.SMURF.NEP", "NEP",
                                                     "W Hz**-0.5", status );

            /* and divide the noise data by the responsivity
               correcting for SIMULT */
            if (*status == SAI__OK) {
              for (i = 0; i < (nepdata->dims)[0]*(nepdata->dims)[1]; i++) {
                /* ignore variance since noise will not have any */
                double * noise = (outdata->pntr)[0];
                double * resp = (respmap->pntr)[0];
                double * nep  = (nepdata->pntr)[0];
                if (noise[i] == VAL__BADD || resp[i] == VAL__BADD) {
                  nep[i] = VAL__BADD;
                } else {
                  nep[i] = (noise[i] / SIMULT) / resp[i];
                }
              }
            }
            if (*status == SAI__OK && nepdata->file) {
              smf_accumulate_prov( NULL, basegrp, 1, nepdata->file->ndfid,
                                   CREATOR, status );
            }
            if (nepdata) smf_close_file( &nepdata, status );
          }

          /* now mask the noise and ratio data */
          if (respmap) {
            double * rdata = (respmap->pntr)[0];
            unsigned char * outq = (outdata->pntr)[2];
            unsigned char * ratq = NULL;

            if (ratdata) ratq = (ratdata->pntr)[2];

            /* set the quality mask */
            for (i = 0; i < (outdata->dims)[0]*(outdata->dims)[1]; i++) {
              if ( rdata[i] == VAL__BADD) {
                outq[i] |= SMF__Q_BADB;
                if (ratq) ratq[i] |= SMF__Q_BADB;
              }
            }

            /* by default we enable the mask */
            if (outdata && outdata->file) {
              ndfSbb( SMF__Q_BADB, outdata->file->ndfid, status );
            }
            if (ratdata && ratdata->file) {
              ndfSbb( SMF__Q_BADB, ratdata->file->ndfid, status );
            }

          }

          if (respmap) smf_close_file( &respmap, status );
        }

        if (*status == SAI__OK && outdata->file) {
          smf_accumulate_prov( NULL, basegrp, 1, outdata->file->ndfid,
                               CREATOR, status );
        }
        if (outdata) smf_close_file( &outdata, status );
        if (*status == SAI__OK && ratdata && ratdata->file) {
          smf_accumulate_prov( NULL, basegrp, 1, ratdata->file->ndfid,
                               CREATOR, status );
        }
        if (ratdata) smf_close_file( &ratdata, status );

      } else {
        *status = SAI__ERROR;
        errRepf( FUNC_NAME,
                "Internal error obtaining concatenated data set for chunk %zu",
                 status, contchunk );
      }

      /* Increment the group index counter */
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
  if (igrp) grpDelet( &igrp, status);
  if (ogrp) grpDelet( &ogrp, status);
  if (powgrp) grpDelet( &powgrp, status );
  if (basegrp) grpDelet( &basegrp, status );
  if( igroup ) smf_close_smfGroup( &igroup, status );
  if( flatramps ) smf_close_related( &flatramps, status );
  if( wf ) wf = smf_destroy_workforce( wf );

  ndfEnd( status );

  /* Ensure that FFTW doesn't have any used memory kicking around */
  fftw_cleanup();
}

static smfData *
smf__create_bolfile_extension( const Grp * ogrp, size_t gcount,
                               const smfData *refdata, const char hdspath[],
                               const char datalabel[], const char units[],
                               int * status ) {
  char tempfile[SMF_PATH_MAX];
  char * pname;
  Grp * tempgrp = NULL;
  smfData *newdata = NULL;

  if (*status != SAI__OK) return newdata;

  pname = tempfile;
  grpGet( ogrp, gcount, 1, &pname, SMF_PATH_MAX, status );
  one_strlcat( tempfile, hdspath, sizeof(tempfile), status);
  tempgrp = grpNew( "Ratio", status );
  grpPut1( tempgrp, tempfile, 0, status );
  smf_create_bolfile( tempgrp, 1, refdata, datalabel, units, 1,
                      &newdata, status );
  if (tempgrp) grpDelet( &tempgrp, status );
  return newdata;

}
