/*
*+
*  Name:
*     smf_import_array

*  Purpose:
*     Import the data array from an NDF.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     void smf_import_array( ThrWorkForce *wf, smfData *refdata,
*                            const char *name, int bad, int expand,
*                            smf_dtype type, void *dataptr, int *status )

*  Arguments:
*     wf = ThrWorkForce * (Given)
*        Pointer to a pool of worker threads
*     refdata = smfData * (Given)
*        Pointer to a smfData that defines the data ordering and dimensions
*        required of the imported NDF.
*     name = const char * (Given)
*        The name of the NDF to be imported.
*     bad = int (Given)
*        Indicates how bad values within the input NDF should be handled:
*        0 - Retain them
*        1 - Replace them with zero.
*        2 - Replace them with the mean value in the time-slice, or with the
*            most recent valid mean time-slice value, if the time-slice has
*            no good values.
*     expand = int (Given)
*        If non-zero, then expand 1D arrays into 3D arrays.
*     type = smf_dtype (Given)
*        Data type of the "dataptr" array. Currently, only SMF__DOUBLE
*        and SMF__INTEGER arrays are supported.
*     dataptr = void * (Given)
*        The array in which to store the imported NDF data values. Must
*        have the same dimensions as "refdata" (butmay have a different
*        data type).
*     status = int * (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function imports the data array from a specified NDF into a
*     supplied array, checking that the data ordering and dimensions are the
*     same as for a specified reference smfData. If the data ordering is
*     incorrect, it is changed to the required data ordering, before checking
*     the dimensions. Any bad values in the imported array are replaced by
*     the value indicated by "bad".

*  Authors:
*     David S Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     22-OCT-2012 (DSB):
*        Original version.
*     6-DEC-2012 (DSB):
*        - Improve error messages.
*        - Correct ordering of pixel axes when replacing bad values with
*        time-slice mean values.
*     22-JAN-2013 (DSB):
*        Add argument expand.
*     7-JAN-2014 (DSB):
*        Added support for SMF__INTEGER arrays.
*     10-JAN-2014 (DSB):
*        Added argument wf (needed by smf_open_file).
*     14-JAN-2014 (DSB):
*        Multi-thread.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2012-2014 Science & Technology Facilities Council.
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
*     Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
*     MA 02110-1301, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* Starlink includes */
#include "mers.h"
#include "sae_par.h"
#include "star/grp.h"
#include "star/thr.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_typ.h"

/* Prototypes for local static functions. */
static void smf1_import_array( void *job_data_ptr, int *status );

/* Local data types */
typedef struct smfImportArrayData {
   const char *name;
   int operation;
   size_t i1;
   size_t i2;
   size_t t1;
   size_t t2;
   size_t bstride;
   size_t tstride;
   dim_t nbolo;
   smf_dtype type;
   void *din;
   void *dout;
} SmfImportArrayData;

void smf_import_array( ThrWorkForce *wf, smfData *refdata, const char *name, int bad,
                       int expand, smf_dtype type, void *dataptr,
                       int *status ){

/* Local Variables: */
   Grp *igrp;                  /* Group holding NDF name */
   SmfImportArrayData *job_data = NULL;
   SmfImportArrayData *pdata;
   dim_t nbolo;                /* Number of bolometers */
   dim_t nel;                  /* Number of elements in array */
   dim_t ntslice;              /* Number of time slices */
   int iw;
   int nw;
   size_t bstride;             /* Stride between bolometer values */
   size_t i;                   /* Loop count */
   size_t istep;
   size_t tstep;
   size_t tstride;             /* Stride between time slices */
   smfData *data;              /* Model for one sub-array */

/* Check inherited status. */
   if( *status != SAI__OK ) return;

/* Attempt to open the NDF. */
   igrp = grpNew( " ", status );
   grpPut1( igrp, name, 0, status );
   smf_open_file( wf, igrp, 1, "READ", SMF__NOTTSERIES, &data, status );
   grpDelet( &igrp, status );

/* Ensure the smfData read from the NDF uses the same data ordering as the
   reference smfData. */
   smf_dataOrder( wf, data, refdata->isTordered, status );
   if( *status == SAI__OK ) {

/* Check the data type and dimensions of the NDF are the same as the
   reference NDF. */
      if( data->dtype != type ) {
         const char *stype = smf_dtype_str( type, status );
         *status = SAI__ERROR;
         errRepf( " ", "NDF '%s' has incorrect data type - should be "
                  "%s.", status, name, stype );

      } else if( data->ndims != refdata->ndims ) {
         *status = SAI__ERROR;
         errRepf( " ", "NDF '%s' is %zu dimensional - must be %zu "
                  "dimensional.", status, name, data->ndims, refdata->ndims );

      } else if( !expand || refdata->ndims != 3 ) {
         expand = 0;

         for( i = 0; i < refdata->ndims; i++ ) {
            if( data->dims[i] != refdata->dims[i] &&
                *status == SAI__OK ){
               *status = SAI__ERROR;
               errRepf( " ", "NDF '%s' has incorrect dimension %zu on "
                        "pixel axis %zu - should be %zu.", status,
                        name, data->dims[i], i + 1, refdata->dims[i] );
            } else if( data->lbnd[i] != refdata->lbnd[i] &&
                *status == SAI__OK ){
               *status = SAI__ERROR;
               errRepf( " ", "NDF '%s' has incorrect lower bound %d on "
                        "pixel axis %zu - should be %d.", status,
                        name, data->lbnd[i], i + 1, refdata->lbnd[i] );
            }
         }

      } else {
         for( i = 0; i < refdata->ndims; i++ ) {

            if( data->dims[i] == 1 ) {

            } else if( data->dims[i] != refdata->dims[i] &&
                *status == SAI__OK ){
               *status = SAI__ERROR;
               errRepf( " ", "NDF '%s' has incorrect dimension %zu on "
                        "pixel axis %zu - should be %zu.", status,
                        name, data->dims[i], i + 1, refdata->dims[i] );
            } else if( data->lbnd[i] != refdata->lbnd[i] &&
                *status == SAI__OK ){
               *status = SAI__ERROR;
               errRepf( " ", "NDF '%s' has incorrect lower bound %d on "
                        "pixel axis %zu - should be %d.", status,
                        name, data->lbnd[i], i + 1, refdata->lbnd[i] );
            }
         }
      }

/* Get the smfData dimensions and strides. */
      smf_get_dims( refdata, NULL, NULL, &nbolo, &ntslice, &nel, &bstride,
                    &tstride, status );

/* How many threads do we get to play with */
      nw = wf ? wf->nworker : 1;

/* Find how many elements and time slices to process in each worker thread. */
      istep = nel/nw;
      if( istep == 0 ) istep = 1;
      tstep = ntslice/nw;
      if( tstep == 0 ) tstep = 1;

/* Allocate job data for threads, and store common values. Ensure that the
   last thread picks up any left-over elements or time slices.  */
      job_data = astCalloc( nw, sizeof(*job_data) );
      if( *status == SAI__OK ) {
         for( iw = 0; iw < nw; iw++ ) {
            pdata = job_data + iw;
            pdata->i1 = iw*istep;
            pdata->t1 = iw*tstep;
            if( iw < nw - 1 ) {
               pdata->i2 = pdata->i1 + istep - 1;
               pdata->t2 = pdata->t1 + tstep - 1;
            } else {
               pdata->i2 = nel - 1;
               pdata->t2 = ntslice - 1;
            }

            pdata->din = data->pntr[0];
            pdata->dout = dataptr;
            pdata->type = type;
            pdata->bstride = bstride;
            pdata->tstride = tstride;
            pdata->nbolo = nbolo;
            pdata->name = name;
         }
      }

/* Copy the values into the model array, replacing bad values as required. */
      if( *status == SAI__OK ) {
         if( data->ndims < 3 ) data->dims[2] = 1;
         if( data->ndims < 2 ) data->dims[1] = 1;

/* First copy the data into the returned array unchanged. */
         if( expand ) {
            for( iw = 0; iw < nw; iw++ ) {
               pdata = job_data + iw;
               pdata->operation = 1;
               thrAddJob( wf, 0, pdata, smf1_import_array, 0, NULL, status );
            }
            thrWait( wf, status );

         } else {
            memcpy(  dataptr, data->pntr[0], nel*smf_dtype_sz( type, status ) );
         }

/* Retain bad values. */
         if( bad == 0 )  {

/* Replace bad values with zero. */
         } else if( bad == 1 )  {
            for( iw = 0; iw < nw; iw++ ) {
               pdata = job_data + iw;
               pdata->operation = 2;
               thrAddJob( wf, 0, pdata, smf1_import_array, 0, NULL, status );
            }
            thrWait( wf, status );

/* Replace bad values with the mean value in the time slice. */
         } else if( bad == 2 )  {
            for( iw = 0; iw < nw; iw++ ) {
               pdata = job_data + iw;
               pdata->operation = 3;
               thrAddJob( wf, 0, pdata, smf1_import_array, 0, NULL, status );
            }
            thrWait( wf, status );
         }
      }

/* Free resources. */
      job_data = astFree( job_data );
      smf_close_file( wf, &data, status );
   }
}

static void smf1_import_array( void *job_data_ptr, int *status ) {
/*
*  Name:
*     smf1_import_array

*  Purpose:
*     Executed in a worker thread to do various calculations for
*     smf_import_array.

*  Invocation:
*     smf1_import_array( void *job_data_ptr, int *status )

*  Arguments:
*     job_data_ptr = SmfImportArrayData * (Given)
*        Data structure describing the job to be performed by the worker
*        thread.
*     status = int * (Given and Returned)
*        Inherited status.

*/

/* Local Variables: */
   SmfImportArrayData *pdata;
   dim_t nbolo;
   double *pin;
   double *pout;
   int *ipin;
   int *ipout;
   size_t bstride;
   size_t i1;
   size_t i2;
   size_t i;
   size_t j;
   size_t t1;
   size_t t2;
   size_t tstride;

/* Check inherited status */
   if( *status != SAI__OK ) return;

/* Get a pointer that can be used for accessing the required items in the
   supplied structure. */
   pdata = (SmfImportArrayData *) job_data_ptr;

   i1 = pdata->i1;
   i2 = pdata->i2;
   t1 = pdata->t1;
   t2 = pdata->t2;
   tstride = pdata->tstride;
   bstride = pdata->bstride;
   nbolo = pdata->nbolo;

   if( pdata->operation == 1 ){
      if( pdata->type == SMF__DOUBLE ) {
         pin = (double *) pdata->din + t1;
         for( i = t1; i <= t2; i++,pin++ ) {
            pout = (double *) pdata->dout + i*tstride;
            for( j = 0; j < nbolo; j++ ) {
               if( *pin != VAL__BADD ) {
                  *pout = *pin;
               } else {
                  *pout = VAL__BADD;
               }
               pout += bstride;
            }
         }

      } else if( pdata->type == SMF__INTEGER ) {
         ipin = (int *) pdata->din + t1;
         for( i = t1; i <= t2; i++,pin++ ) {
            ipout = (int *) pdata->dout + i*tstride;
            for( j = 0; j < nbolo; j++ ) {
               if( *ipin != VAL__BADI ) {
                  *ipout = *ipin;
               } else {
                  *ipout = VAL__BADI;
               }
               pout += bstride;
            }
         }

      } else if( *status == SAI__OK ) {
         const char *stype = smf_dtype_str( pdata->type, status );
         *status = SAI__ERROR;
         errRepf( " ", "smf_import_array: Data type '%s' not supported "
                  "(programming error).", status, stype );
      }

   } else if( pdata->operation == 2 ){
      if( pdata->type == SMF__DOUBLE ) {
         pout = (double *) pdata->dout + i1;
         for( i = i1; i <= i2; i++,pout++ ) {
            if( *pout == VAL__BADD ) *pout = 0.0;
         }

      } else if( pdata->type == SMF__INTEGER ) {
         ipout = (int *) pdata->dout + i1;
         for( i = i1; i <= i2; i++,ipout++ ) {
            if( *ipout == VAL__BADI ) *ipout = 0.0;
         }

      } else if( *status == SAI__OK ) {
         const char *stype = smf_dtype_str( pdata->type, status );
         *status = SAI__ERROR;
         errRepf( " ", "smf_import_array: Data type '%s' not supported "
                  "(programming error).", status, stype );
      }

   } else if( pdata->operation == 3 ){
      double mean = VAL__BADD;
      double vsum;
      size_t ngood;
      size_t nbad;

      if( pdata->type == SMF__DOUBLE ) {
         for( i = t1; i <= t2; i++ ) {
            vsum = 0.0;
            ngood = 0;
            nbad = 0;
            pout = (double *) pdata->dout + i*tstride;

            for( j = 0; j < nbolo; j++ ) {
               if( *pout != VAL__BADD ) {
                  vsum += *pout;
                  ngood++;
               } else {
                  nbad++;
               }
               pout += bstride;
            }

            if( ngood > 0 ) mean = vsum/ngood;

            if( nbad > 0 ) {
               if( mean != VAL__BADD ) {
                  pout = (double *) pdata->dout + i*tstride;
                  for( j = 0; j < nbolo; j++ ) {
                     if( *pout == VAL__BADD ) *pout = mean;
                     pout += bstride;
                  }
               } else {
                  *status = SAI__ERROR;
                  errRepf( " ", "NDF '%s' has no good values in plane "
                           "%zu.", status, pdata->name, i );
                  break;
               }
            }
         }

      } else if( pdata->type == SMF__INTEGER ) {
         for( i = t1; i <= t2; i++ ) {
            vsum = 0.0;
            ngood = 0;
            nbad = 0;
            ipout = (int *) pdata->dout + i*tstride;

            for( j = 0; j < nbolo; j++ ) {
               if( *ipout != VAL__BADI ) {
                  vsum += *ipout;
                  ngood++;
               } else {
                  nbad++;
               }
               ipout += bstride;
            }

            if( ngood > 0 ) mean = vsum/ngood;

            if( nbad > 0 ) {
               if( mean != VAL__BADD ) {
                  ipout = (int *) pdata->dout + i*tstride;
                  for( j = 0; j < nbolo; j++ ) {
                     if( *ipout == VAL__BADI ) *ipout = mean;
                     ipout += bstride;
                  }
               } else {
                  *status = SAI__ERROR;
                  errRepf( " ", "NDF '%s' has no good values in plane "
                           "%zu.", status, pdata->name, i );
                  break;
               }
            }
         }

      } else if( *status == SAI__OK ) {
         const char *stype = smf_dtype_str( pdata->type, status );
         *status = SAI__ERROR;
         errRepf( " ", "smf_import_array: Data type '%s' not supported "
                  "(programming error).", status, stype );
      }

   } else {
      *status = SAI__ERROR;
      errRepf( "", "smf1_import_array: Invalid operation (%d) supplied.",
               status, pdata->operation );
   }
}



