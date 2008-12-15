/*
*+
*  Name:
*     smf_clean_dksquid

*  Purpose:
*     Clean raw smfData by removing a scaled, offset version of the dark squid

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     smf_clean_dksquid( smfData *indata, unsigned char *quality, 
*                        unsigned char mask, size_t window, smfData *model, 
*                        int calcdk, int nofit, int *status ) {

*  Arguments:
*     indata = smfData * (Given)
*        Pointer to the input smfData. Should be raw, un-flatfielded.
*     quality = unsigned char * (Given)
*        Override quality inside indata
*     mask = unsigned char (Given)
*        Use to define which bits in quality are relevant to ignore indata
*     window = size_t (Given)
*        Width of boxcar smooth for squid before fitting and removing
*     model = smfData * (Given)
*        If supplied, dark squids stored in model created by smf_model_create
*     calcdk = int (Given)
*        If set, calc & store dark squids in model along with fit coefficients
*     nofit = int (Given)
*        If set, just obtain smoothed dark squid signals and don't fit/remove
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Return Value:

*  Description: 
*     Columns of SCUBA-2 detectors exhibit a strong correlated signal
*     which is shown clearly in the dark squids. As the dark squids do
*     not see astronomical or atmospheric signal they can be used as a
*     template to remove this correlated noise. The dark squids are
*     smoothed to avoid increasing the white noise level of detectors
*     once they are subtracted. They are fit to the raw
*     (un-flatfielded) detector by solving for a gain and offset using
*     the explicit least-squares solution. If a dark squid is constant
*     this routine flags every detector in the column as SMF__Q_BADB.
* 
*     If a model smfData created with smf_model_create (SMF__DKS) is
*     supplied, it can be used to override obtaining the dark squid
*     signals from the DA extension of indata (calcdk=0 case), or
*     alternatively it can be used to store the smoothed dark squid
*     signals for future use (calcdk=1 case). In either case, if it is
*     supplied the fitted gain and offset coefficients for each
*     detector in the columns are stored. The step of fitting /
*     removing templates can also be skipped for the purpose of
*     initializing models only by setting the nofit flag.

*  Notes:

*  Authors:
*     Ed Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2008-08-27 (EC):
*        Initial version
*     2008-09-11 (EC):
*        -flag SMF__Q_BADB all bolos in column if dark squid is dead
*        -fixed array index bug
*     2008-10-01 (EC):
*        -fixed logic bugs
*        -added mask for quality
*        -flag bolo as bad if fit failed

*  Copyright:
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

/* Starlink includes */
#include "ast.h"
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"
#include "prm_par.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_clean_dksquid"

void smf_clean_dksquid( smfData *indata, unsigned char *quality, 
                        unsigned char mask, size_t window, smfData *model, 
                        int calcdk, int nofit, int *status ) {

  size_t arrayoff;        /* Array offset */
  double corr;            /* Linear correlation coefficient */
  double *corrbuf=NULL;   /* Array of correlation coeffs all bolos this col */
  int curlevel;           /* Current messaging level */
  int needDA=0;           /* Do we need dksquids from the DA? */ 
  int dkgood;             /* Flag for non-constant dark squid */ 
  double *dksquid=NULL;   /* Buffer for smoothed dark squid */
  int firstdk;            /* First value in dksquid signal */
  double gain;            /* Gain parameter from template fit */
  double *gainbuf=NULL;   /* Array of gains for all bolos in this col */
  size_t i;               /* Loop counter */
  dim_t index;            /* index into buffer */
  int isTordered;         /* Data order */
  size_t j;               /* Loop counter */
  size_t k;               /* Loop counter */
  dim_t nbolo;            /* Number of bolometers */
  dim_t ncol;             /* Number of columns */
  dim_t ndata;            /* Number of data points */
  dim_t nrow;             /* Number of rows */
  dim_t ntslice;          /* Number of time slices */
  double offset;          /* Offset parameter from template fit */
  double *offsetbuf=NULL; /* Array of offsets for all bolos in this col */
  unsigned char *qua=NULL;/* Pointer to quality array */
  dim_t stride;           /* Distance between bolo samples in array */

  if (*status != SAI__OK) return;

  /* Check for NULL smfData pointer */
  if( !indata ) {
    *status = SAI__ERROR;
    errRep( " ", FUNC_NAME 
            ": possible programming error, smfData pointer is NULL", status );
    return;
  }

  /* Decide if we need the DA extension or not */
  if( (!model) || (model && calcdk) ) {
    needDA = 1;
    if( !indata->da) {
      /* Check for NULL smfDA */
      *status = SAI__ERROR;
      errRep( " ", FUNC_NAME 
              ": possible programming error, no smfDA struct in smfData", 
              status);
      return;
    } else if( !indata->da->dksquid) {
      /* Check for NULL dksquid */
        *status = SAI__ERROR;
        errRep( " ", FUNC_NAME 
                ": possible programming error, no dksquid array in smfData", 
                status);
        return;
    }
  }

  /* Check for 3-d data and get dimensions */
  smf_get_dims( indata,  NULL, NULL, &nbolo, &ntslice, &ndata, NULL, NULL, status );

  /* Obtain the number of rows and columns */
  isTordered = indata->isTordered;
  if( isTordered ) {
    ncol = indata->dims[SMF__COL_INDEX];    /* x, y, t */
    nrow = indata->dims[SMF__ROW_INDEX];
  } else {
    ncol = indata->dims[1+SMF__COL_INDEX];  /* t, x, y */
    nrow = indata->dims[1+SMF__ROW_INDEX];
  }

  if( model ) {
    /* Check for valid model dimensions if supplied */
    if( model->dtype != SMF__DOUBLE ) {
      msgSetc("DT", smf_dtype_str(model->dtype, status) );
      *status = SAI__ERROR;
      errRep(" ", FUNC_NAME ": Data type ^DT for model not supported.", 
             status );
      return;
    }

    if( (model->ndims != 2) ||
        (model->dims[0] != ntslice+nrow*3) ||
        (model->dims[1] != ncol) ) {
      *status = SAI__ERROR;
      errRep(" ", FUNC_NAME ": model has incorrect dimensions", status );
      return;
    }
  } else {
    /* Otherwise allocate space for local dksquid buffer */
    dksquid = smf_malloc( ntslice, sizeof(*dksquid), 0, status );
  }

  /* Pointer to quality */
  if( quality ) qua = quality;
  else qua = indata->pntr[2];

  /* Loop over columns */
  for( i=0; (*status==SAI__OK)&&(i<ncol); i++ ) {

    /* Point dksquid, gainbuf, offsetbuf and corrbuf to the right
       place in model if supplied. Initialize fit coeffs to
       VAL__BADD */
    if( model ) {
      dksquid = model->pntr[0];
      dksquid += i*(ntslice+nrow*3);
      gainbuf = dksquid + ntslice;
      offsetbuf = gainbuf + nrow;
      corrbuf = offsetbuf + nrow;

      for( j=0; j<nrow; j++ ) {
        gainbuf[j] = VAL__BADD;
        offsetbuf[j] = VAL__BADD;
        corrbuf[j] = VAL__BADD;
      }
    }

    if( needDA ) {
      /* Copy dark squids from the DA extension into dksquid */
      index = i;
      for( j=0; j<ntslice; j++ ) {
        dksquid[j] = indata->da->dksquid[index];
        index += ncol;
      }
    }

    /* Check for a good dark squid by seeing if it ever changes */
    dkgood = 0;
    firstdk = dksquid[0];
    for( j=0; j<ntslice; j++ ) {
      if( dksquid[j] != firstdk ) dkgood=1;
    }

    if( needDA && dkgood ) {
      /* Smooth the dark squid template */
      smf_boxcar1D( dksquid, ntslice, window, NULL, 0, status );
    }

    /* Loop over rows, removing the fitted dksquid template. */
    for( j=0; (!nofit) && (*status==SAI__OK) && (j<nrow); j++ ) {

      /* Calculate index of first sample for this bolometer, and the stride */
      if( SMF__COL_INDEX ) {
        index = i*nrow + j;
      } else {
        index = i + j*ncol;
      }

      if( isTordered ) {
        stride = nbolo;
      } else {
        stride = 1;
        index *= ntslice;
      }

      /* If dark squid is bad, flag entire bolo as bad if it isn't already */
      if( !dkgood && qua && !(qua[index]&SMF__Q_BADB) ) {
        arrayoff = index;
        for( k=0; k<ntslice; k++ ) {
          qua[arrayoff] |= SMF__Q_BADB;
          arrayoff += stride;
        }
      }

      /* Try to fit if we think we have a good dark squid and bolo */

      if( (!qua && dkgood) || (qua && dkgood && !(qua[index]&SMF__Q_BADB)) ) {

        switch( indata->dtype ) {
        case SMF__DOUBLE:
          smf_templateFit1D( &( ((double *)indata->pntr[0])[index] ), 
                             &qua[index], mask,
                             ntslice, stride, dksquid, 1, &gain, &offset, 
                             &corr, status );
          break;
          
        case SMF__INTEGER:
          smf_templateFit1I( &( ((int *)indata->pntr[0])[index] ), 
                             &qua[index], mask, 
                             ntslice, stride, dksquid, 1, &gain, &offset, 
                             &corr, status );
          break;
          
        default:
          msgSetc( "DT", smf_dtype_string( indata, status ));
          *status = SAI__ERROR;
          errRep( " ", FUNC_NAME 
                  ": Unsupported data type for dksquid cleaning (^DT)",
                  status );
        }
       
        msgIflev( &curlevel );
        if( *status == SMF__INSMP ) {
          /* Annul SMF__INSMP as it was probably due to a bad bolometer */
          errAnnul( status );
          if( curlevel >= MSG__DEBUG ) {
            msgSeti( "COL", i );
            msgSeti( "ROW", j );
            msgOutif( MSG__DEBUG, "", FUNC_NAME
                      ": ROW,COL (^ROW,^COL) insufficient good samples", 
                      status );
          }
          
          /* Flag entire bolo as bad if it isn't already */
          if( qua && !(qua[index]&SMF__Q_BADB) ) {
            arrayoff = index;
            for( k=0; k<ntslice; k++ ) {
              qua[arrayoff] |= SMF__Q_BADB;
              arrayoff += stride;
            }
          }
        } else {
          /* Store gain and offset in model */
          if( model ) {
            gainbuf[j] = gain;
            offsetbuf[j] = offset;
            corrbuf[j] = corr;
          }

          if( curlevel >= MSG__DEBUG ) {
            msgSeti( "COL", i );
            msgSeti( "ROW", j );
            msgSetd( "GAI", gain );
            msgSetd( "OFF", offset );
            msgSetd( "CORR", corr );
            msgOutif( MSG__DEBUG, "", FUNC_NAME
                      ": ROW,COL (^ROW,^COL) GAIN,OFFSET,CORR " 
                      "(^GAI,^OFF,^CORR)", status );
          }
        }
      }
    }
  }

  /* Free dksquid only if it was a local buffer */
  if( !model && dksquid ) dksquid = smf_free( dksquid, status );
}
