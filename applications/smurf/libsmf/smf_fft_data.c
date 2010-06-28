/*
*+
*  Name:
*     smf_fft_data

*  Purpose:
*     Calculate the forward or inverse FFT of a smfData

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     pntr = smf_fft_data( smfWorkForce *wf, const smfData *indata, int inverse,
*                          smf_qual_t *quality, size_t len, int *status );

*  Arguments:
*     wf = smfWorkForce * (Given)
*        Pointer to a pool of worker threads (can be NULL)
*     indata = smfData * (Given)
*        Pointer to the input smfData
*     inverse = int (Given)
*        If set perform inverse transformation. Otherwise forward.
*     quality = smf_qual_t * (Given)
*        If set, use this buffer instead of QUALITY associated with indata.
*        If NULL, use the QUALITY associated with indata.
*     len = size_t (Given)
*        Number of samples over which to apply apodization. Can be set to
*        SMF__MAXAPLEN in which case the routine will automatically apodize
*        the entire data stream (maximum valid value of len). Set it to
*        zero to prevent apodisation (e.g. if the data has already been
*        apodised).
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Return Value:
*     Pointer to newly created smfData containing the forward or inverse
*     transformed data.

*  Description:

*     Perform the forward or inverse FFT of a smfData. In the time
*     domain the data are 3-d (either x,y,time or time,x,y depending
*     on isTordered flag). The frequency domain representation of the
*     data is 4-d (always frequency,x,y,component --
*     i.e. bolo-ordered). Component is an axis of length 2 containing
*     the real and imaginary parts.  Inverse transforms always leave
*     the data in bolo-ordered format. If the data are already
*     transformed, this routine returns a NULL pointer.  If a non-null
*     pointer wf is supplied, tell FFW to use multiple threads.

*  Notes:

*  Authors:
*     Ed Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2008-07-09 (EC):
*        Initial version
*     2008-07-23 (EC):
*        Forward transformations now seem to work.
*     2008-07-28 (EC):
*        -Calculate correct ntslice for inverse.
*        -Code stub for generation of 4-d WCS of forward transformation.
*     2008-07-29 (EC):
*        Calculate WCS for 4-d transformed data.
*     2008-07-29 (TIMJ):
*        Steptime is now in smfHead.
*     2008-10-17 (AGG):
*        Set NaN and Inf to VAL__BADD when normalizing
*     2008-11-03 (EC):
*        Move conversion of NaN/Inf-->VAL__BADD to smf_convert_bad.c
*     2008-11-20 (TIMJ):
*        "Close" the smfData instead of "free".
*     2009-10-8 (DSB):
*         Use a smf job context to ensure that smf_wait only waits for the jobs
*         submitted within this function.
*     2009-10-28 (DSB):
*         Use sc2ast_make_bolo_frame.
*     2010-06-28 (DSB):
*         Added arguments qyality and len (needed since with the new
*         filtering scheme, the data may not have been apodised on entry
*         to this function).
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2008-2009 Science and Technology Facilities Council.
*     Copyright (C) 2008 University of British Columbia.
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

/* System includes */
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

/* Starlink includes */
#include "ast.h"
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"
#include "prm_par.h"
#include "fftw3.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

/* Data Acquisition Includes */
#include "sc2da/sc2ast.h"

/* ------------------------------------------------------------------------ */
/* Local variables and functions */

pthread_mutex_t smf_fft_data_mutex = PTHREAD_MUTEX_INITIALIZER;

/* Structure containing information about blocks of bolos to be
   FFT'd by each thread. All threads read/write to/from mutually
   exclusive parts of data and retdata so we don't need to make
   local copies of entire smfDatas. */
typedef struct smfFFTData {
  size_t b1;                    /* Index of first bolometer to be FFT'd */
  size_t b2;                    /* Index of last bolometer to be FFT'd */
  smfData *data;                /* Pointer to input data */
  int ijob;                     /* Job identifier */
  int inverse;                  /* Set if this is inverse transformation */
  dim_t nbolo;                  /* Number of detectors  */
  dim_t nf;                     /* Number of frequencies in FFT */
  dim_t ntslice;                /* Number of time slices */
  fftw_plan plan;               /* FFTW plan */
  smfData *retdata;             /* Pointer to returned FFT'd data */
} smfFFTData;

/* Function to be executed in thread: FFT all of the bolos from b1 to b2 */

void smfFFTDataParallel( void *job_data_ptr, int *status );

void smfFFTDataParallel( void *job_data_ptr, int *status ) {
  smfFFTData *pdata = NULL;     /* Pointer to job data */
  double *baseR=NULL;           /* base pointer to real part of transform */
  double *baseI=NULL;           /* base pointer to imag part of transform */
  double *baseB=NULL;           /* base pointer to bolo in time domain */
  dim_t i;                      /* Loop counter */

   if( *status != SAI__OK ) return;

  /* Pointer to the data that this thread will process */
  pdata = job_data_ptr;

  /* Check for valid inputs */
  if( !pdata ) {
    *status = SAI__ERROR;
    errRep( "", "smfFFTDataParallel: No job data supplied", status );
    return;
  }

  if( !pdata->data || !pdata->retdata ) {
    *status = SAI__ERROR;
    errRep( "", "smfFFTDataParallel: Invalid smfData pointers", status );
    return;
  }

  /* Debugging message indicating thread started work */
  msgOutiff( MSG__DEBUG, "",
             "smfFFTDataParallel: thread starting on bolos %zu -- %zu",
             status, pdata->b1, pdata->b2 );


  /* if b1 past end of the work, nothing to do so we return */
  if( pdata->b1 >= pdata->nbolo ) {
    msgOutif( MSG__DEBUG, "",
              "smfFFTDataParallel: nothing for thread to do, returning",
              status);
    return;
  }

   if( pdata->inverse ) {        /* Perform inverse fft */

     for( i=pdata->b1; i<=pdata->b2; i++ ) {
       /* Transform bolometers one at a time */
       baseR = pdata->data->pntr[0];
       baseR += i*pdata->nf;

       baseI = baseR + pdata->nf*pdata->nbolo;

       baseB = pdata->retdata->pntr[0];
       baseB += i*pdata->ntslice;

       fftw_execute_split_dft_c2r( pdata->plan, baseR, baseI, baseB );
     }
   } else {                      /* Perform forward fft */
     for( i=pdata->b1; i<=pdata->b2; i++ ) {
       /* Transform bolometers one at a time */
       baseB = pdata->data->pntr[0];
       baseB += i*pdata->ntslice;

       baseR = pdata->retdata->pntr[0];
       baseR += i*pdata->nf;

       baseI = baseR + pdata->nf*pdata->nbolo;
       fftw_execute_split_dft_r2c( pdata->plan, baseB, baseR, baseI );
     }
   }

   /* Debugging message indicating thread finished work */
   msgOutiff( MSG__DEBUG, "",
              "smfFFTDataParallel: thread finishing bolos %zu -- %zu",
              status, pdata->b1, pdata->b2 );

}

/* ------------------------------------------------------------------------ */


#define FUNC_NAME "smf_fft_data"

smfData *smf_fft_data( smfWorkForce *wf, const smfData *indata, int inverse,
                       smf_qual_t *quality, size_t len, int *status ) {
  double *baseR=NULL;           /* base pointer to real part of transform */
  double *baseI=NULL;           /* base pointer to imag part of transform */
  double *baseB=NULL;           /* base pointer to bolo in time domain */
  AstUnitMap *cmapping=NULL;    /* Mapping from grid to curframe3d */
  AstFrame *curframe1d=NULL;    /* Current 1d frame (real/imag coeff) */
  AstFrame *curframe2d=NULL;    /* Current 2d frame (bolo x,y) */
  AstCmpFrame *curframe3d=NULL; /* Current 3d frame (x,y,coeff) */
  AstCmpFrame *curframe4d=NULL; /* Current Frame for 4-d FFT */
  smfData *data=NULL;           /* pointer to bolo-ordered data */
  double df=0;                  /* Frequency step size in Hz */
  fftw_iodim dims;              /* I/O dimensions for transformations */
  AstCmpMap *fftmapping=NULL;   /* Mapping from GRID to curframe2d */
  int i;                        /* Loop counter */
  int isFFT=0;                  /* Are the input data freq. domain? */
  size_t j;                     /* Loop counter */
  smfFFTData *job_data=NULL;    /* Array of job data for each thread */
  AstCmpMap *mapping3d=NULL;    /* Mapping from 3d GRID to FREQ, X, Y */
  dim_t nbolo=0;                /* Number of detectors  */
  dim_t ndata=0;                /* Number of elements in new array */
  dim_t nf=0;                   /* Number of frequencies in FFT */
  int njobs=0;                  /* Number of jobs to be processed */
  double norm=1.;               /* Normalization factor for the FFT */
  dim_t ntslice=0;              /* Number of time slices */
  int nw;                       /* Number of worker threads */
  smfFFTData *pdata=NULL;       /* Pointer to current job data */
  smfData *retdata=NULL;        /* Pointer to new transformed smfData */
  AstZoomMap *scalemapping=NULL;/* Scale grid coordinates by df */
  AstSpecFrame *specframe=NULL; /* Current Frame of 1-D spectrum */
  AstCmpMap *specmapping=NULL;  /* Mapping from GRID to FREQ */
  size_t step;                  /* step size for dividing up work */
  double steptime;              /* Length of a sample in seconds */
  AstFrameSet *tswcs=NULL;      /* WCS for 4d FFT data */
  double *val=NULL;             /* Element of data to be normalized */
  double zshift;                /* Amount by which to shift freq. origin */
  AstShiftMap *zshiftmapping=NULL;  /* Map to shift origin of freq. GRID */
  AstMapping *zshiftmapping2=NULL; /* Map to shift origin of bolo GRID */

  if (*status != SAI__OK) return NULL;

  /* How many threads do we get to play with */
  nw = wf ? wf->nworker : 1;

  /* Check for NULL pointer */
  if( indata == NULL ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": smfData pointer is NULL", status );
    return NULL;
  }

  /* Check for double-precision data */
  if( indata->dtype != SMF__DOUBLE ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": Data are not double precision", status );
    return NULL;
  }

  /* Create a copy of the input data since FFT operations often do
     calculations in-place */
  data = smf_deepcopy_smfData( indata, 0, SMF__NOCREATE_VARIANCE |
                               SMF__NOCREATE_QUALITY |
                               SMF__NOCREATE_FILE |
                               SMF__NOCREATE_DA, status );

  /* Re-order a time-domain cube if needed */
  if( indata->isTordered && (indata->ndims == 3) ) {
    smf_dataOrder( data, 0, status );
  }

  /* Apodise the data if required. */
  if( len ) smf_apodize( data, quality, len, status );

  /* Data dimensions. Time dimensions are either 1-d or 3-d. Frequency
     dimensions are either 2- or 4-d to store the real and imaginary
     parts along the last index. */

  if( data->ndims == 3 ) {
    nbolo = data->dims[1]*data->dims[2];
    ntslice = data->dims[0];
    nf = ntslice/2 + 1;
    isFFT = 0;
  } else if( (data->ndims==4) && (data->dims[3]==2) ) {
    /* 3-d FFT of entire subarray */
    isFFT = smf_isfft( data, &ntslice, &nbolo, &nf, status );
  } else {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": smfData has strange dimensions", status );
  }

  /* If the data are already transformed to the requested domain return
     a NULL pointer */

  if( (*status==SAI__OK) && (isFFT != inverse) ) {
    retdata = NULL;
    goto CLEANUP;
  }

  /* Create a new smfData, copying over everything except for the bolo
     data itself */

  retdata = smf_deepcopy_smfData( data, 0, SMF__NOCREATE_DATA |
                                  SMF__NOCREATE_VARIANCE |
                                  SMF__NOCREATE_QUALITY |
                                  SMF__NOCREATE_FILE |
                                  SMF__NOCREATE_DA, status );

  if( *status == SAI__OK ) {

    /* Allocate space for the transformed data */

    if( inverse ) {
      /* Doing an inverse FFT to the time domain */
        retdata->ndims = 3;
        retdata->dims[0] = ntslice;
        retdata->dims[1] = data->dims[1];
        retdata->dims[2] = data->dims[2];
    } else {
      /* Doing a forward FFT to the frequency domain */
      retdata->ndims = 4;
      retdata->dims[0] = nf;
      retdata->dims[1] = data->dims[1];
      retdata->dims[2] = data->dims[2];
      retdata->dims[3] = 2;
    }

    /* Returned data is always bolo-ordered */
    retdata->isTordered=0;

    ndata=1;
    for( j=0; j<retdata->ndims; j++ ) {
      ndata *= retdata->dims[j];
    }

    retdata->pntr[0] = astCalloc( ndata, smf_dtype_sz(retdata->dtype,status), 1 );

    /* Describe the array dimensions for FFTW guru interface
       - dims describes the length and stepsize of time slices within bolometer
    */

    dims.n = ntslice;
    dims.is = 1;
    dims.os = 1;

    /* Set up the job data */

    if( nw > (int) nbolo ) {
      step = 1;
    } else {
      step = nbolo/nw;
      if( !step ) {
        step = 1;
      }
    }

    job_data = astCalloc( nw, sizeof(*job_data), 1 );

    for( i=0; (*status==SAI__OK)&&i<nw; i++ ) {
      pdata = job_data + i;

      pdata->b1 = i*step;
      pdata->b2 = (i+1)*step-1;

      /* if b1 is greater than the number of bolometers, we've run out
         of jobs... */
      if( pdata->b1 >= nbolo ) {
        break;
      }

      /* increase the jobs counter */
      njobs++;

      /* Ensure that the last thread picks up any left-over bolometers */
      if( (i==(nw-1)) && (pdata->b1<(nbolo-1)) ) {
        pdata->b2=nbolo-1;
      }

      pdata->data = data;
      pdata->ijob = -1;   /* Flag job as ready to start */
      pdata->inverse = inverse;
      pdata->nbolo = nbolo;
      pdata->nf = nf;
      pdata->ntslice = ntslice;
      pdata->retdata = retdata;

      if( inverse ) {        /* Performing inverse fft */
        /* Setup inverse FFT plan using guru interface */
        baseR = data->pntr[0];
        baseI = baseR + nf*nbolo;
        baseB = retdata->pntr[0];

        smf_mutex_lock( &smf_fft_data_mutex, status );
        pdata->plan = fftw_plan_guru_split_dft_c2r( 1, &dims, 0, NULL,
                                                    baseR, baseI,
                                                    baseB,
                                                    FFTW_ESTIMATE |
                                                    FFTW_UNALIGNED);
        smf_mutex_unlock( &smf_fft_data_mutex, status );
      } else {               /* Performing forward fft */
        /* Setup forward FFT plan using guru interface */
        baseB = data->pntr[0];
        baseR = retdata->pntr[0];
        baseI = baseR + nf*nbolo;

        smf_mutex_lock( &smf_fft_data_mutex, status );
        pdata->plan = fftw_plan_guru_split_dft_r2c( 1, &dims, 0, NULL,
                                                    baseB,
                                                    baseR, baseI,
                                                    FFTW_ESTIMATE |
                                                    FFTW_UNALIGNED);
        smf_mutex_unlock( &smf_fft_data_mutex, status );

        /* If doing a forward transformation, and we are handling a 3d
         data cube, create WCS information here. */

        if( indata->hdr && retdata->hdr && (retdata->ndims==4) ) {
          steptime = retdata->hdr->steptime;
          if( steptime < VAL__SMLD ) {
            *status = SAI__ERROR;
            errRep( "", FUNC_NAME
                    ": FITS header error: STEPTIME must be > 0",
                    status);
          }

          if( *status == SAI__OK ) {
            /* Frequency steps in the FFT */
            df = 1. / (steptime * (double) ntslice );

            /* Start an AST context */
            astBegin;

            /* Create a new astFrameSet containing a 4d base GRID frame */
            tswcs = astFrameSet( astFrame( 4, "Domain=GRID" ), " " );

            /* Get a Frame describing bolometer rows and columns, and a
               Mapping from 2D GRID coords to this BOLO Frame. */
            sc2ast_make_bolo_frame( &curframe2d, &zshiftmapping2, status );

            /* The current frame will have frequency along the first axis,
               x, y bolo coordinates along the second and third axes,
               and the component along a fourth axis of length two (real,
               imaginary coefficients). */

            specframe = astSpecFrame( "System=freq,Unit=Hz,"
                                      "StdOfRest=Topocentric" );



            curframe3d = astCmpFrame( specframe, curframe2d, " " );
            curframe1d = astFrame( 1, "Domain=COEFF,label=Real/Imag component"); /* real/imag component*/
            curframe4d = astCmpFrame( curframe3d, curframe1d, " " );

            /* The mapping from 4d grid coordinates to (frequency, x,
               y, coeff) is accomplished with a shift and a zoommap
               for the 1st dimension, and a shift for the others */

            zshift = -1;
            zshiftmapping = astShiftMap( 1, &zshift, " " );
            scalemapping = astZoomMap( 1, df, " " );
            specmapping = astCmpMap( zshiftmapping, scalemapping, 1, " " );

            mapping3d = astCmpMap( specmapping, zshiftmapping2, 0, " " );

            cmapping = astUnitMap( 1, " " );
            fftmapping = astCmpMap( mapping3d, cmapping, 0, " " );

            /* Add the curframe4d with the fftmapping to the frameset */
            astAddFrame( tswcs, AST__BASE, fftmapping, curframe4d );

            /* Export the frameset before ending the AST context */
            astExport( tswcs );
            astEnd;

            /* Free the old TSWCS if it exists, and insert the new TSWCS */
            if( retdata->hdr->tswcs ) {
              retdata->hdr->tswcs = astAnnul(retdata->hdr->tswcs);
            }
            retdata->hdr->tswcs = tswcs;
          }
        }
      }

      if( !pdata->plan ) {
        *status = SAI__ERROR;
        errRep("", FUNC_NAME
               ": FFTW3 could not create plan for transformation",
               status);
      }
    }
  }

  /* Do the FFTs */
  smf_begin_job_context( wf, status );
  for( i=0; (*status==SAI__OK)&&i<njobs; i++ ) {
    pdata = job_data + i;
    pdata->ijob = smf_add_job( wf, SMF__REPORT_JOB, pdata,
                               smfFFTDataParallel, NULL, status );
  }

  /* Wait until all of the submitted jobs have completed */
  smf_wait( wf, status );
  smf_end_job_context( wf, status );

  /* Each sample needs to have a normalization applied if forward FFT */
  if( (*status==SAI__OK) && !inverse ) {
    norm = 1. / (double) ntslice;

    val = retdata->pntr[0];

    for( j=0; j<nf*nbolo*2; j++ ) {
      *val *= norm;
      if (*val == 0.0) *val = VAL__BADD;
      val++;
    }
  }


 CLEANUP:
  if( data ) smf_close_file( &data, status );

  /* Clean up the job data array */
  if( job_data ) {
    for( i=0; i<njobs; i++ ) {
      pdata = job_data + i;
      /* Destroy the plans */
      smf_mutex_lock( &smf_fft_data_mutex, status );
      fftw_destroy_plan( pdata->plan);
      smf_mutex_unlock( &smf_fft_data_mutex, status );
    }
    job_data = astFree( job_data );
  }

  return retdata;

}
