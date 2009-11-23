/*
*+
*  Name:
*     smf_calcmodel_flt

*  Purpose:
*     Calculate the frequency domain FiLTered data model

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_calcmodel_flt( smfWorkForce *wf, smfDIMMData *dat, int
*			 chunk, AstKeyMap *keymap, smfArray
*			 **allmodel, int flags, int *status)

*  Arguments:
*     wf = smfWorkForce * (Given)
*        Pointer to a pool of worker threads
*     dat = smfDIMMData * (Given)
*        Struct of pointers to information required by model calculation
*     chunk = int (Given)
*        Index of time chunk in allmodel to be calculated
*     keymap = AstKeyMap * (Given)
*        Parameters that control the iterative map-maker
*     allmodel = smfArray ** (Returned)
*        Array of smfArrays (each time chunk) to hold result of model calc
*     flags = int (Given )
*        Control flags: not used
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Execute a frequency domain filter, but store what was removed with a
*     time-domain representation for easy visualization. The data should
*     already have been padded/apodized in a pre-processing step.

*  Notes:

*  Authors:
*     Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2009-03-10 (EC):
*        Initial Version
*     2009-04-17 (EC)
*        - switch to subkeymap notation in config file
*     2009-04-27 (EC)
*        Enable multiple threads in call to smf_filter_execute
*     2009-09-30 (EC)
*        Measure normalized change in model between iterations (dchisq)
*     {enter_further_changes_here}


*  Copyright:
*     Copyright (C) 2009 University of British Columbia.
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

#define FUNC_NAME "smf_calcmodel_flt"

void smf_calcmodel_flt( smfWorkForce *wf, smfDIMMData *dat, int chunk,
                        AstKeyMap *keymap, smfArray **allmodel,
                        int flags __attribute__((unused)),
                        int *status) {

  /* Local Variables */
  size_t bstride;               /* bolo stride */
  double dchisq=0;              /* this - last model residual chi^2 */
  int dofft;                    /* flag if we will actually do any filtering */
  smfFilter *filt=NULL;         /* Pointer to filter struct */
  size_t i;                     /* Loop counter */
  dim_t ii;                     /* Array index */
  dim_t idx=0;                  /* Index within subgroup */
  size_t j;                     /* Loop counter */
  AstKeyMap *kmap=NULL;         /* Pointer to FLT-specific keys */
  smfArray *model=NULL;         /* Pointer to model at chunk */
  double *model_data=NULL;      /* Pointer to DATA component of model */
  double *model_data_copy=NULL; /* Copy of model_data for one bolo */
  dim_t nbolo=0;                /* Number of bolometers */
  dim_t ndata=0;                /* Total number of data points */
  size_t ndchisq=0;             /* number of elements contributing to dchisq */
  smfArray *noi=NULL;           /* Pointer to NOI at chunk */
  double *noi_data=NULL;        /* Pointer to DATA component of model */
  size_t noibstride;            /* bolo stride for noise */
  dim_t nointslice;             /* number of time slices for noise */
  size_t noitstride;            /* Time stride for noise */
  dim_t ntslice=0;              /* Number of time slices */
  smfArray *qua=NULL;           /* Pointer to QUA at chunk */
  unsigned char *qua_data=NULL; /* Pointer to quality data */
  smfArray *res=NULL;           /* Pointer to RES at chunk */
  double *res_data=NULL;        /* Pointer to DATA component of res */
  size_t tstride;               /* Time slice stride in data array */

  /* Main routine */
  if (*status != SAI__OK) return;

  /* Obtain pointer to sub-keymap containing FLT filter parameters */
  if( !astMapGet0A( keymap, "FLT", &kmap ) ) {
    msgOutif( MSG__VERB, " ", FUNC_NAME ": FLT model requested, "
              "but no parameters specified.", status );
    return;
  }

  /* Obtain pointers to relevant smfArrays for this chunk */
  res = dat->res[chunk];
  qua = dat->qua[chunk];

  smf_get_dims( res->sdata[0],  NULL, NULL, NULL, NULL,
                &ndata, NULL, NULL, status);

  if(dat->noi) {
    noi = dat->noi[chunk];
    model_data_copy = smf_malloc( ndata, sizeof(*model_data_copy), 1, status);
  }
  model = allmodel[chunk];

  /* Assert bolo-ordered data */
  for( idx=0; idx<res->ndat; idx++ ) if (*status == SAI__OK ) {
    smf_dataOrder( res->sdata[idx], 0, status );
    smf_dataOrder( qua->sdata[idx], 0, status );
    smf_dataOrder( model->sdata[idx], 0, status );
  }

  /* Loop over index in subgrp (subarray) and put the previous iteration
     of the filtered component back into the residual before calculating
     and removing the new filtered component */
  for( idx=0; (*status==SAI__OK)&&(idx<res->ndat); idx++ ) {
    /* Obtain dimensions of the data */
    smf_get_dims( res->sdata[idx],  NULL, NULL, &nbolo, &ntslice,
                  &ndata, &bstride, &tstride, status);

    /* Get pointers to data/quality/model */
    res_data = (res->sdata[idx]->pntr)[0];
    qua_data = (qua->sdata[idx]->pntr)[0];
    model_data = (model->sdata[idx]->pntr)[0];

    if( noi ) {
      smf_get_dims( noi->sdata[idx],  NULL, NULL, NULL, &nointslice,
                    NULL, &noibstride, &noitstride, status);
      noi_data = (double *)(noi->sdata[idx]->pntr)[0];
    }

    if( (res_data == NULL) || (model_data == NULL) || (qua_data == NULL) ) {
      *status = SAI__ERROR;
      errRep( "", FUNC_NAME ": Null data in inputs", status);
    } else {

      /* Create a filter */
      filt = smf_create_smfFilter( res->sdata[idx], status );
      smf_filter_fromkeymap( filt, kmap, &dofft, status );

      if( *status == SMF__INFREQ ) {
        /* If a bad frequency was specified just annul the error and
           skip the FLT model component */
        dofft = 0;
        errAnnul( status );
        msgOut( "", FUNC_NAME ": invalid frequency for filter specified. "
                "Skipping FLT model component.", status );
      } else {
        if( !dofft ) {
          msgOutif( MSG__VERB, " ", FUNC_NAME
                    ": No valid filter specifiers for FLT given", status );
        }
      }

      if( *status == SAI__OK ) {
        /* Place last iteration of filtered signal back into residual */
        for( i=0; i<nbolo; i++ ) if( !(qua_data[i*bstride]&SMF__Q_BADB) ) {
          for( j=0; j<ntslice; j++ ) {
            res_data[i*bstride+j*tstride] += model_data[i*bstride+j*tstride];
          }
        }

        /* Make a copy of the last model if calculating dchisq */
        if( noi ) {
          memcpy( model_data_copy, model_data,
                  ndata*smf_dtype_size(res->sdata[idx], status ) );
        }

        /* Copy the residual+old model into model_data where it will be
           filtered again in this iteration. */
        memcpy( model_data, res_data,
                ndata*smf_dtype_size(res->sdata[idx],status) );
      }

      /* Apply the filter to the residual */
      if( dofft ) {
        smf_filter_execute( wf, res->sdata[idx], filt, status );
      }

      /* Store the difference between the filtered signal and the residual
         in the model container */
      if( *status == SAI__OK ) {
        for( i=0; i<nbolo; i++ ) if( !(qua_data[i*bstride]&SMF__Q_BADB) ) {
          for( j=0; j<ntslice; j++ ) {

            ii = i*bstride+j*tstride;
            model_data[ii] -= res_data[ii];

            /* also measure contribution to dchisq */
            if( noi && !(qua_data[i*bstride]&SMF__Q_GOOD) ) {
              dchisq += (model_data[ii] - model_data_copy[ii]) *
                (model_data[ii] - model_data_copy[ii]) /
                noi_data[i*noibstride + (j%nointslice)*noitstride];
              ndchisq++;
            }
          }
        }
      }

      /* Free the filter */
      filt = smf_free_smfFilter( filt, status );
    }
  }

  /* Print normalized residual chisq for this model */
  if( (*status==SAI__OK) && noi && (ndchisq>0) ) {
    dchisq /= (double) ndchisq;
    msgOutiff( MSG__VERB, "", "    normalized change in model: %lf", status,
               dchisq );
  }

  if( kmap ) kmap = astAnnul( kmap );
  if( model_data_copy ) model_data_copy = smf_free(model_data_copy, status);
}
