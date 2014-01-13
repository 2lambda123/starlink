/*
*+
*  Name:
*     smf_diag

*  Purpose:
*     Dump diagnostics to disk for a single tinme stream.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_diag( ThrWorkForce *wf, HDSLoc *loc, int *ibolo, int irow,
*               int power, int time, int isub, smfDIMMData *dat,
*               smf_modeltype type, smfArray *model, int res,
*               const char *root, int mask, double mingood, int cube,
*               int addqual, int *status )

*  Arguments:
*     wf = ThrWorkForce * (Given)
*        Pointer to a pool of worker threads
*     HDSLoc = *loc (Given)
*        Locator for the HDS container file to which the diagniostic
*        info should be appended.
*     ibolo = int * (Given and Returned)
*        On entry: If larger than or equal to zero, this is the zero based
*        index of the bolometer to dump. If -1, dump the mean of all
*        bolometers. If -2 dump the weighted mean of all bolometers. If -3
*        dump an automatically chosen typical bolometer.
*        On exit: the zero-based index of the chosen detector if ibolo
*        was -3 on entry. Otherwise, ibolo is returned unchanged.
*     irow = int (Given)
*        The zero-based row number within each NDF at which to store
*        the line of diagnostic info.
*     power = int (Given)
*        If non-zero, store the power spectrum for the data.
*     time = int (Given)
*        If non-zero, store the time series for the data.
*     isub = int (Given)
*        The zero-based index of the smfData within the supplied smfArray
*        to dump.
*     dat = smfDIMMData * (Given)
*        Struct of pointers to information required by model calculation
*     type = smf_modeltype (Given)
*        Indicates which model is to be dumped.
*     model = smfArray ** (Returned)
*        A smfArray holding the model data to be dumped. If NULL, then
*        the residuals are dumped.
*     res = int (Given)
*        If non-zero dump the residuals. Otherwise dump the model.
*     root = const char * (Given)
*        The root name for the NDFs to hold the data within the container
*        file. The string "_time" and/or "_power" (depending on arguments
*        power and time) will be added to this root to created the full name.
*     mask = int (Given)
*        If non-zero, then the AST model will be masked using the current
*        mask before being dumped. Otherwise, the AST model will not be
*        masked before being dumped.
*     mingood = double (Given)
*        The minimum fraction of good values in a time stream for which
*        data should be dumped. An error is reported if the required minimum
*        value is not met.
*     cube = int (Given)
*        Is a full cube containing time ordered data for all bolometers
*        required? If so, it will be stored in an NDF with name
*        "<root>_cube_<irow>".
*     addqual = int (Given)
*        If non-zero, the output NDFs will include a quality array.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Dumps diagnostic information for a single (real or mean)
*     bolometer.

*  Authors:
*     David Berry (JAC)
*     {enter_new_authors_here}

*  History:
*     25-JAN-2013 (DSB):
*        Original version.
*     21-OCT-2013 (DSB):
*        Added argument "addqual".

*  Copyright:
*     Copyright (C) 2013 Science and Technology Facilities Council.
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
#include "star/thr.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

/* Prototypes for local static functions. */
static void smf1_diag( void *job_data_ptr, int *status );

/* Local data types */
typedef struct smfDiagData {
   const double *in;
   dim_t nbolo;
   dim_t ntslice;
   dim_t s1;
   dim_t s2;
   dim_t t1;
   dim_t t2;
   dim_t b1;
   dim_t b2;
   smfData *data;
   double *map;
   double *out;
   double *var;
   int *lut;
   int mask;
   int oper;
   size_t bstride;
   size_t tstride;
   smf_qual_t *mapqual;
   smf_qual_t *qua;
   smf_qual_t *qua_out;
} SmfDiagData;

void smf_diag( ThrWorkForce *wf, HDSLoc *loc, int *ibolo, int irow,
               int power, int time, int isub, smfDIMMData *dat,
               smf_modeltype type, smfArray *model, int res,
               const char *root, int mask, double mingood, int cube,
               int addqual, int *status ){

/* Local Variables: */
   AstCmpFrame *totfrm;
   AstCmpMap *totmap;
   AstFrame *ffrm;
   AstFrameSet *wcs = NULL;
   AstMapping *fmap;
   SmfDiagData *job_data = NULL;
   SmfDiagData *pdata;
   char *name;
   char attr[ 50 ];
   const char *dom;
   const char *mode;
   dim_t dsize;
   dim_t fdims[2];
   dim_t itime;
   dim_t jbolo;
   dim_t nbolo;
   dim_t nbolor;
   dim_t ndata;
   dim_t ngood;
   dim_t ntslice;
   double *buffer;
   double *ip;
   double *oldcom;
   double *oldres = NULL;
   double *pd;
   double *var;
   int *index;
   int bolostep;
   int el;
   int fax;
   int i;
   int iax;
   int indf;
   int iw;
   int lbnd[ 2 ];
   int nax;
   int nc;
   int ndim;
   int nw;
   int place;
   int sorted;
   int timestep;
   int ubnd[ 2 ];
   int usebolo;
   size_t bstride;
   size_t tstride;
   size_t bstrider;
   size_t tstrider;
   size_t nmap;
   smfArray *array;
   smfData *data = NULL;
   smfData *data_tmp;
   smfData *pow;
   smf_qual_t *oldcomq;
   smf_qual_t *pqr;
   smf_qual_t *pq;
   smf_qual_t *qua = NULL;
   smf_qual_t *qual;
   smf_qual_t *qbuffer = NULL;
   smf_qual_t qval;
   smfData *sidequal;

/* Check inherited status. */
   if( *status != SAI__OK ) return;

/* Start an AST context. */
   astBegin;

/* How many threads do we get to play with */
   nw = wf ? wf->nworker : 1;

/* Allocate job data for threads. */
   job_data = astCalloc( nw, sizeof(*job_data) );

/* Get a pointer to the smfArray containing the data to be dumped. */
   array = NULL;
   if( res || type == SMF__RES ) {
      array = dat->res[ 0 ];
   } else if( model ) {
      array = model;
   } else if( type != SMF__AST && *status == SAI__OK ){
      *status = SAI__ERROR;
      errRepf( "", "smf_diag: Bad value (%d) for argument \"type\".",
               status, type );
   }

/* Get a pointer to the smfData containing the data to be dumped. Deal
   with cases where we are dumping the AST model first (we need to
   generate AST from the current map since it is not stored explicitly). */
   if( ! array ) {

/* Ensure we use the RES model ordering */
      smf_model_dataOrder( wf, dat, NULL, 0, SMF__RES|SMF__LUT|SMF__QUA,
                           dat->res[0]->sdata[0]->isTordered, status );

/* We temporarily hijack the RES smfData to hold the AST model. */
      data = dat->res[ 0 ]->sdata[ isub ];
      smf_get_dims( data, NULL, NULL, NULL, NULL, &dsize, NULL, NULL, status );
      oldres = data->pntr[0];
      data->pntr[0] = astMalloc( dsize*sizeof( *oldres ) );

/* Number of samples per thread. */
      size_t sampstep = dsize/nw;
      if( sampstep == 0 ) sampstep = 1;

/* Set up info for each worker thread. */
      for( iw = 0; iw < nw; iw++ ) {
         pdata = job_data + iw;
         pdata->s1 = iw*sampstep;
         if( iw < nw - 1 ) {
           pdata->s2 = pdata->s1 + sampstep - 1;
         } else {
           pdata->s2 = dsize - 1 ;
         }

         pdata->qua = dat->qua[0]->sdata[isub]->pntr[0];
         pdata->out = data->pntr[0];
         pdata->lut = dat->lut[0]->sdata[isub]->pntr[0];
         pdata->map = dat->map;
         pdata->mapqual = dat->mapqual;
         pdata->mask = mask;
         pdata->oper = 0;

/* Submit the job to the workforce. */
         thrAddJob( wf, 0, pdata, smf1_diag, 0, NULL, status );
      }

/* Wait for all jobs to complete. */
      thrWait( wf, status );

/* Some models (e.g. COM) may have only one smfData for all subarrays. */
   } else if( array->ndat == 1 ) {
      data = array->sdata[ 0 ];

   } else if( isub >= 0 && isub < (int) array->ndat ) {
      data = array->sdata[ isub ];

   } else if( *status == SAI__OK ) {
      data = NULL;
      *status = SAI__ERROR;
      errRepf( "", "smf_diag: requested subarray index (%d) is invalid - %d "
               "subarrays are available.", status, isub, (int) array->ndat );
   }

/* Get a pointer to the quality array. */
   qual = smf_select_qualpntr( data, NULL, status );

/* Get dimensions and strides for the smfData. */
   smf_get_dims( data, NULL, NULL, &nbolo, &ntslice, NULL,
                 &bstride, &tstride, status );

/* Prepare the worker data for later submission of jobs. Find how many time
   slices and bolometers to process in each worker thread. */
   if( *status == SAI__OK ) {
      timestep = ntslice/nw;
      if( timestep == 0 ) timestep = 1;

      bolostep = nbolo/nw;
      if( bolostep == 0 ) bolostep = 1;

/* Store the range of times slices, etc, to be processed by each thread.
   Ensure that the last thread picks up any left-over time slices.  */
      for( iw = 0; iw < nw; iw++ ) {
         pdata = job_data + iw;
         pdata->t1 = iw*timestep;
         if( iw < nw - 1 ) {
            pdata->t2 = pdata->t1 + timestep - 1;
         } else {
            pdata->t2 = ntslice - 1 ;
         }

         pdata->b1 = iw*bolostep;
         if( iw < nw - 1 ) {
            pdata->b2 = pdata->b1 + bolostep - 1;
         } else {
            pdata->b2 = nbolo - 1 ;
         }

/* Store other values common to all jobs. */
         pdata->nbolo = nbolo;
         pdata->ntslice = ntslice;
         pdata->bstride = bstride;
         pdata->tstride = tstride;
      }
   }

/* Allocate space for the time stream to dump. */
   buffer = astMalloc( ntslice*sizeof( *buffer ) );

/* Get the time stream containing the data to be dumped. If it contains
   only one time-stream (e.g COM), use it. */
   usebolo = *ibolo;
   if( nbolo == 1 ) usebolo = 0;

/* If a specified single bolometer was requested, copy it into
   the buffer, replacing flagged samples with VAL__BADD. */
   if( usebolo >= 0 && *status == SAI__OK ) {

      pd = ((double *) data->pntr[0]) + usebolo*bstride;
      pq = qual ? qual + usebolo*bstride : NULL;
      if( pq && addqual ) qbuffer = astMalloc( ntslice*sizeof( *qbuffer ) );

      ngood = 0;
      for( itime = 0; itime < ntslice; itime++ ){
         if( qbuffer ) qbuffer[ itime ] = *pq;
         if( ( qbuffer || ( !pq || *pq == 0 ) ) && *pd != VAL__BADD ) {
            buffer[ itime ] = *pd;
            ngood++;
         } else {
            buffer[ itime ] = VAL__BADD;
         }
         pd += tstride;
         if( pq ) pq += tstride;
      }

      if( ngood < mingood*ntslice && *status == SAI__OK ) {
         *status = SAI__ERROR;
         errRep( "", "smf_diag: Failed to dump diagnostic data since "
                 "selected bolometer has too few good values.", status );
      }

/* If the mean or weighted mean bolometer, or a typical bolometer, is
   required, find it. */
   } else if( *status == SAI__OK ) {

/* Get the variances for each bolometer if needed. */
      var = NULL;
      if( usebolo == -2 || usebolo == -3 ) {
         var = astMalloc( nbolo*sizeof( *var ) );
         for( iw = 0; iw < nw; iw++ ) {
            pdata = job_data + iw;
            pdata->oper = 2;
            pdata->out = var;
            pdata->data = data;
            thrAddJob( wf, 0, pdata, smf1_diag, 0, NULL, status );
         }
         thrWait( wf, status );
      }

/* If required, find a typical bolometer... Get a list of bolometer
   indices, sorted by variance value, and select the bolometer with the
   most good samples that is within the central 40% to 60% quartiles. */
      if( usebolo == -3 ) {
         index = smf_sortD( nbolo, var, &sorted, status );
         if( *status == SAI__OK ) {
            dim_t maxgood, itest;
            maxgood = 0;
            for( itest = 0.4*nbolo; itest <= 0.6*nbolo; itest++ ) {
               jbolo = index[ itest ];

               pd = ((double *) data->pntr[0]) + jbolo*bstride;
               pq = qual ? qual + jbolo*bstride : NULL;
               ngood = 0;
               for( itime = 0; itime < ntslice; itime++ ){
                  if( ( !pq || *pq == 0 ) && *pd != VAL__BADD ) ngood++;
                  pd += tstride;
                  if( pq ) pq += tstride;
               }

               if( ngood > maxgood ) {
                  maxgood = ngood;
                  usebolo = jbolo;
               }
            }

/* Copy the data from the selected bolometer into the buffer. */
            pd = ((double *) data->pntr[0]) + usebolo*bstride;
            pq = qual ? qual + usebolo*bstride : NULL;

            if( pq && addqual ) qbuffer = astMalloc( ntslice*sizeof( *qbuffer ) );

            ngood = 0;
            for( itime = 0; itime < ntslice; itime++ ){
               if( qbuffer ) qbuffer[ itime ] = *pq;
               if( ( qbuffer || ( !pq || *pq == 0 ) ) && *pd != VAL__BADD ) {
                  buffer[ itime ] = *pd;
                  ngood++;
               } else {
                  buffer[ itime ] = VAL__BADD;
               }
               pd += tstride;
               if( pq ) pq += tstride;
            }

            if( ngood < mingood*ntslice && *status == SAI__OK ) {
               *status = SAI__ERROR;
               errRep( "", "smf_diag: Failed to dump diagnostic data since "
                       "selected bolometer has too few good values.", status );
            }
         }
         index = astFree( index );

/* Otherwise, calculate the mean or weighted mean bolometer time series. */
      } else {
         for( iw = 0; iw < nw; iw++ ) {
            pdata = job_data + iw;
            pdata->in = data->pntr[ 0 ];
            pdata->out = buffer;
            pdata->qua = qual;
            pdata->oper = usebolo;
            pdata->var = var;
            thrAddJob( wf, 0, pdata, smf1_diag, 0, NULL, status );
         }
         thrWait( wf, status );
      }

      var = astFree( var );

   }

/* Loop over the two possible outputs - time and power */
   for( i = 0; i < 2; i++ ) {

/* Continue if the current output is not needed. */
      if( ( i == 0 && !time ) || ( i == 1 && !power ) ) continue;

/* If we are dumping the power spectrum, replace the time series with the
   power spectrum within "buffer". Temporarily hijack the COM model for
   this (we choose COM since it has only one bolometer). */
      if( i == 1 ) {
         if( dat->com ) {
            data_tmp = dat->com[ 0 ]->sdata[ isub ];

/* Check COM is a single bolo time stream. */
            if( data_tmp->ndims != 3 ||
                data_tmp->dims[ 0 ] != ntslice ||
                data_tmp->dims[ 1 ] != 1 ||
                data_tmp->dims[ 2 ] != 1 ) {
               if( *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  errRep( "", "smf_diag: COM has unexpected dimensions.",
                          status );
               }

            } else {

/* Save the original COM data pointer, and use the local buffer instead. */
               oldcom = data_tmp->pntr[ 0 ];
               data_tmp->pntr[ 0 ] = buffer;

/* Create a temporary quality array that flags the VAL__BADD values in
   buffer. We base it on a copy of the quality array for a used bolometer
   in the residuals, so that the new quality array inherits padding and apodisation flags. */
               oldcomq = data_tmp->qual;
               sidequal = data_tmp->sidequal;
               data_tmp->qual = astMalloc( ntslice*sizeof( *data_tmp->qual ));
               data_tmp->sidequal = NULL;

/* Examine the residuals quality array to find a bolometer that has not
   been completey rejected. Then copy the bolometer's quality values into
   the temporary array created above, retaining PAD and APOD flags but
   removing all others. Set SPIKE quality (a convenient bad value) for any
   values that are bad in the time series being dumped (the "buffer" array). */
               smf_get_dims( dat->res[ 0 ]->sdata[isub], NULL, NULL,
                             &nbolor, NULL, NULL, &bstrider, &tstrider, status );
               pqr = smf_select_qualpntr( dat->res[ 0 ]->sdata[isub], NULL, status );
               pq = data_tmp->qual;
               ngood = 0;
               for( jbolo = 0; jbolo < nbolor; jbolo++ ) {
                  if( !( *pqr & SMF__Q_BADB ) ) {
                     for( itime = 0; itime < ntslice; itime++ ) {
                        qval = *pqr & ( SMF__Q_APOD | SMF__Q_PAD );
                        if( buffer[ itime ] == VAL__BADD ) {
                           if( !(qval & SMF__Q_PAD) ) qval = SMF__Q_SPIKE;
                           buffer[ itime ] = 0.0; /* Bad values cause grief in smf_fft_data */
                        } else {
                           ngood++;
                        }
                        *(pq++) = qval;
                        pqr += tstrider;
                     }
                     break;
                  }
                  pqr += bstrider;
               }

/* If too few good values, just take the FFT of a load of zerso. */
               if( ngood < mingood*ntslice ) {
                  for( itime = 0; itime < ntslice; itime++ ){
                     buffer[ itime ] = 0.0;
                  }
               }

/* Now do the fft */
               pow = smf_fft_data( wf, data_tmp, NULL, 0, SMF__BADSZT,
                                   status );
               smf_convert_bad( wf, pow, status );

/* Convert to power */
               smf_fft_cart2pol( wf, pow, 0, 1, status );
               smf_isfft( pow, NULL, NULL, fdims, NULL, NULL, status );

/* Get the WCS and copy the power spectrum to the buffer. */
               ndata = fdims[ 0 ];
               if( *status == SAI__OK ) {
                  if( pow->hdr->tswcs ) {
                     wcs = astClone( pow->hdr->tswcs );
                  } else if( pow->hdr->wcs ) {
                     wcs = astClone( pow->hdr->wcs );
                  }
                  memcpy( buffer, pow->pntr[ 0 ], ndata*sizeof( buffer ) );
                  smf_close_file( wf, &pow, status );

/* If too few good values, store a set of bad values in place of the
   power spectrum. */
                  if( ngood < mingood*ntslice ) {
                     for( itime = 0; itime < ndata; itime++ ){
                        buffer[ itime ] = VAL__BADD;
                     }
                  }
               }

               data_tmp->pntr[ 0 ] = oldcom;
               (void) astFree( data_tmp->qual );
               data_tmp->qual = oldcomq;
               data_tmp->sidequal = sidequal;
            }

         } else if( *status == SAI__OK ) {
            *status = SAI__ERROR;
            errRepf( "", "smf_diag: Cannot dump power spectra since "
                     "no COM model is being used.", status );
         }

      } else {
         ndata = ntslice;
      }

/* Form the name of the NDF to receive the data. */
      name = NULL;
      nc = 0;
      name = astAppendString( name, &nc, root );
      name = astAppendString( name, &nc, i ? "_power" : "_time" );

/* Open the NDF, creating it if necesary. Ensure its bounds encompass the
   requested row. */
      ndfOpen( loc, name, "UPDATE", "UNKNOWN", &indf, &place, status );
      if( place != NDF__NOPL ) {
         lbnd[ 0 ] = 1;
         ubnd[ 0 ] = ndata;
         lbnd[ 1 ] = irow + 1;
         ubnd[ 1 ] = irow + 1;
         ndfNew( "_DOUBLE", 2, lbnd, ubnd, &place, &indf, status );
         mode = "Write";

/* Since a new NDF was created, add WCS if available. */
         if( wcs ) {

/* If storing power spectra, the FrameSet created by smf_fft_data is for a
   4D NDF, so we need to modify it for out 2D NDFs.  */
            if( i == 1 ) {

/* Search for the frequency axis. */
               nax = astGetI( wcs, "NAXES" );
               for( iax = 1; iax <= nax; iax++ ) {
                  sprintf( attr, "Domain(%d)", iax );
                  dom = astGetC( wcs, attr );
                  if( astChrMatch( dom, "SPECTRUM" ) ) {

/* Frequency axis found. Extract the grid->freq mapping, and get the
   SpecFrame. */
                     astMapSplit( wcs, 1, &iax, &fax, &fmap );
                     if( fmap ) {
                        ffrm = astPickAxes( wcs, 1, &fax, NULL );

/* Create a 2D WCS by combining the above frequency axis with a simple 1D
   axis describing iteration number. */
                        (void) astAnnul( wcs );
                        wcs = astFrameSet( astFrame( 2, "Domain=GRID" ), " " );
                        totmap = astCmpMap( fmap, astUnitMap( 1, " " ), 0, " " );
                        totfrm = astCmpFrame( ffrm, astFrame( 1, "Domain=ITERATION"
                          ",Label(1)=Iteration number,Symbol(1)=Iter" ), " " );
                        astAddFrame( wcs, AST__BASE, totmap, totfrm );

                     } else if( *status == SAI__OK ) {
                        *status = SAI__ERROR;
                        errRep( "", "smf_diag: Cannot extract the frequency axis "
                                "from the power spectrum wcs.", status );
                     }

/* Do not need to check any more axes so break. */
                     break;
                  }
               }

/* Report an error if no frequency axis was found. */
               if( iax == nax && *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  errRep( "", "smf_diag: No frequency axis found in the "
                          "power spectrum wcs.", status );
               }
            }
            ndfPtwcs( wcs, indf, status );
            wcs = astAnnul( wcs );
         }

/* If using an existing NDF, modify its bounds to encompass the new row
   and indicate it should be opened in update mode. */
      } else {
         ndfBound( indf, 2, lbnd, ubnd, &ndim, status );
         lbnd[ 0 ] = 1;
         ubnd[ 0 ] = ndata;
         if( lbnd[ 1 ] > irow + 1 ) lbnd[ 1 ] = irow + 1;
         if( ubnd[ 1 ] < irow + 1 ) ubnd[ 1 ] = irow + 1;
         ndfSbnd( 2, lbnd, ubnd, indf, status );
         mode = "Update";
      }

/* Map the data array and copy the values. */
      ndfMap( indf, "DATA", "_DOUBLE", mode, (void **) &ip, &el,
              status );
      if( *status == SAI__OK ) memcpy( ip + ( irow + 1 - lbnd[1] )*ndata,
                                       buffer, sizeof(double)*ndata );

/* If required, map the Quality array and copy the values, then unmap it. */
      if( qbuffer ) {
         qua = smf_qual_map( wf, indf, mode, NULL, &nmap, status );
         if( *status == SAI__OK ) memcpy( qua + ( irow + 1 - lbnd[1] )*ndata,
                                          qbuffer, sizeof(*qua)*ndata );
         smf_qual_unmap( wf, indf, SMF__QFAM_TSERIES, qua, status );

/* Set the bad bits mask so that the data array will not be masked when
   it is mapped when dumping diagnostics for the next iteration. */
         ndfSbb( 0, indf, status );
      }

/* Free resources. */
      ndfAnnul( &indf, status );
      name = astFree( name );
   }

/* Return the used bolometer, if required. */
   if( *ibolo == -3 ) *ibolo = usebolo;

/* If required, dump the time series for all bolometers to a new cube. */
   if( cube && data->ndims == 3 && (data->pntr)[0] ) {

/* Get the name of the NDF to hold the cube. */
      name = NULL;
      nc = 0;
      name = astAppendString( name, &nc, root );
      name = astAppendString( name, &nc, "_cube_" );
      sprintf( attr, "%d", irow );
      name = astAppendString( name, &nc, attr );

/* Get its pixel bounds. */
      for( i = 0; i < 3; i++ ) {
         lbnd[ i ] = (data->lbnd)[ i ];
         ubnd[ i ] = lbnd[ i ] + (data->dims)[ i ] - 1;
      }

/* Create it and map the Data component. */
      ndfPlace( loc, name, &place, status );
      ndfNew( "_DOUBLE", 3, lbnd, ubnd, &place, &indf, status );
      ndfMap( indf, "DATA", "_DOUBLE", "WRITE", (void **) &ip, &el,
              status );

/* If required, map the quality array. */
      if( addqual ) qua = smf_qual_map( wf, indf, "wRITE", NULL, &nmap, status );

/* Copy the data values from the smfData to the NDF Data component,
   setting flagged values to VAL__BADD if required. */
      for( iw = 0; iw < nw; iw++ ) {
         pdata = job_data + iw;
         if( pdata->b1 < nbolo ) {
            pdata->oper = 3;
            pdata->out = ip;
            pdata->in = (data->pntr)[0];
            pdata->qua = qual;
            pdata->qua_out = qua;
            thrAddJob( wf, 0, pdata, smf1_diag, 0, NULL, status );
         }
      }
      thrWait( wf, status );

/* If required, unmap the quality array. */
      if( addqual ) smf_qual_unmap( wf, indf, SMF__QFAM_TSERIES, qua, status );

/* Annul the NDF identifier. */
      ndfAnnul( &indf, status );

   }

/* Free the array holding the AST model and re-instate the original RES
   values if required. */
   if( oldres ) {
      (void) astFree( dat->res[0]->sdata[isub]->pntr[0] );
      dat->res[0]->sdata[isub]->pntr[0] = oldres;
   }

/* Free remaining resources. */
   buffer = astFree( buffer );
   qbuffer = astFree( qbuffer );
   job_data = astFree( job_data );

/* End the AST context. */
   astEnd;
}


static void smf1_diag( void *job_data_ptr, int *status ) {
/*
*  Name:
*     smf1_diag

*  Purpose:
*     Executed in a worker thread to do various calculations for
*     smf_diag.

*  Invocation:
*     smf1_diag( void *job_data_ptr, int *status )

*  Arguments:
*     job_data_ptr = SmfDiagData * (Given)
*        Data structure describing the job to be performed by the worker
*        thread.
*     status = int * (Given and Returned)
*        Inherited status.

*/

/* Local Variables: */
   SmfDiagData *pdata;
   dim_t ibolo;
   dim_t idata;
   dim_t itime;
   dim_t nbolo;
   int oper;
   dim_t t1;
   dim_t t2;
   double *var;
   double *out;
   size_t bstride;
   size_t tstride;
   smf_qual_t *qua;
   smf_qual_t *qua_out;
   const double *in;
   double sum;
   double wsum;
   double w;
   int n;
   const double *pd;
   smf_qual_t *pq;
   smf_qual_t *pq2;
   double *po;
   int *pl;

/* Check inherited status */
   if( *status != SAI__OK ) return;

/* Get a pointer that can be used for accessing the required items in the
   supplied structure. */
   pdata = (SmfDiagData *) job_data_ptr;

/* Copy stuff into local variables for easier access. */
   nbolo = pdata->nbolo;
   in = pdata->in;
   out = pdata->out;
   qua = pdata->qua;
   qua_out = pdata->qua_out;
   var = pdata->var;
   bstride = pdata->bstride;
   tstride = pdata->tstride;
   oper = pdata->oper;
   t1 = pdata->t1;
   t2 = pdata->t2;

/* Sample the map to form the AST signal. */
   if( oper == 0 ) {
      po = pdata->out +  pdata->s1;
      pq = pdata->qua +  pdata->s1;
      pl = pdata->lut +  pdata->s1;
      for( idata = pdata->s1; idata <= pdata->s2; idata++,pq++,pl++,po++ ) {
         if( !( *pq & SMF__Q_MOD ) && *pl != VAL__BADI ) {
            double ast_data = pdata->map[ *pl ];
            if( ast_data != VAL__BADD &&
                ( !(pdata->mapqual[ *pl ] & SMF__MAPQ_AST ) || !pdata->mask ) ) {
               *po = ast_data;
            } else {
               *po = VAL__BADD;
            }
         } else {
            *po = VAL__BADD;
         }
      }

/* Get the variances of a range of bolometers. */
   } else if( oper == 2 ) {
      out = pdata->out + pdata->b1;
      for( ibolo = pdata->b1; ibolo <= pdata->b2; ibolo++ ) {
         w = smf_quick_noise( pdata->data, ibolo, 20, 50, SMF__Q_GOOD, status );
         if( *status == SMF__INSMP ) {
            errAnnul( status );
            w = VAL__BADD;
         }
         *(out++) = w;
      }

/* Copy full cube of data values, masking them in the process. */
   } else if( oper == 3 ) {
      for( ibolo = pdata->b1; ibolo <= pdata->b2; ibolo++ ) {
         out = pdata->out + ibolo*bstride;
         in = pdata->in + ibolo*bstride;
         pq = qua ? qua + ibolo*bstride : NULL;
         pq2 = qua_out ? qua_out + ibolo*bstride : NULL;
         for( itime = 0; itime < pdata->ntslice; itime++) {
            if( !pq || *pq == 0 || pq2 ) {
               *out = *in;
            } else {
               *out = VAL__BADD;
            }

            if( pq && pq2 ) *pq2 = *pq;

            in += tstride;
            out += tstride;
            if( pq ) pq += tstride;
            if( pq2 ) pq2 += tstride;
         }
      }

/* Form unweighted mean of all good bolos. */
   } else if( oper == -1 ) {
      for( itime = t1; itime <= t2; itime++ ) {
         sum = 0.0;
         n = 0;
         pd = in + itime*tstride;
         pq = qua ? qua + itime*tstride : NULL;
         for( ibolo = 0; ibolo < nbolo; ibolo++ ) {
            if( *pd != VAL__BADD && ( !pq || *pq == 0 ) ) {
               sum += *pd;
               n++;
            }
            pd += bstride;
            if( pq ) pq += bstride;
         }
         if( n > 0 ) {
            out[ itime ] = sum/n;
         } else {
            out[ itime ] = VAL__BADD;
         }
      }

/* Form weighted mean of all good bolos. */
   } else if( oper == -2 ) {
      for( itime = t1; itime <= t2; itime++ ) {
         sum = 0.0;
         wsum = 0.0;
         pd = in + itime*tstride;
         pq = qua ? qua + itime*tstride : NULL;
         for( ibolo = 0; ibolo < nbolo; ibolo++ ) {
            w = var[ ibolo ];
            if( *pd != VAL__BADD && ( !pq || *pq == 0 ) &&
                w != VAL__BADD && w > 0.0 ) {
               w = 1/w;
               sum += w*(*pd);
               wsum += w;
            }
            pd += bstride;
            if( pq ) pq += bstride;
         }
         if( wsum > 0 ) {
            out[ itime ] = sum/wsum;
         } else {
            out[ itime ] = VAL__BADD;
         }
      }

   } else if( *status == SAI__OK ) {
      *status = SAI__ERROR;
      errRepf( "", "smf1_diag: Illegal operation %d requested.",
               status, oper );
   }
}




