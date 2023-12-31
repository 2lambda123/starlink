#include "sae_par.h"
#include "dat_par.h"
#include "ndf1.h"
#include "ndf_err.h"
#include "ndf.h"
#include "mers.h"

void ndfNewp_( const char *ftype, int ndim, const hdsdim ubnd[], int *place,
              int *indf, int *status ){
/*
*+
*  Name:
*     ndfNewp

*  Purpose:
*     Create a new primitive NDF.

*  Synopsis:
*     void ndfNewp( const char *ftype, int ndim, const hdsdim ubnd[],
*                   int *place, int *indf, int *status )

*  Description:
*     This function creates a new primitive NDF and returns an identifier
*     for it. The NDF may subsequently be manipulated with the NDF_
*     functions.

*  Parameters:
*     ftype
*        Pointer to a null terminated string holding the data type of the
*        NDF's DATA component (e.g. "_REAL"). Note that complex types are
*        not permitted when creating a primitive NDF.
*     ndim
*        Number of NDF dimensions.
*     ubnd
*        Upper pixel-index bounds of the NDF (the lower bound of each
*        dimension is taken to be 1).
*     *place
*        An NDF placeholder (e.g. generated by the ndfPlace function) which
*        indicates the position in the data system where the new NDF will
*        reside. The placeholder is annulled by this function, and a value
*        of NDF__NOPL will be returned (as defined in the include file
*        "ndf.h").
*     *indf
*        Returned holding the identifier for the new NDF.
*     *status
*        The global status.

*  Notes:
*     -  This function creates a "primitive" NDF, i.e. one whose array
*     components are stored in "primitive" form by default (see SGP/38).
*     -  The full type of the DATA component is specified via the "ftype"
*     parameter and the type of the VARIANCE component defaults to the same
*     value. These types may be set individually with the ndfStype function
*     if required.
*     -  If this function is called with "status" set, then a value of
*     NDF__NOID will be returned for the "indf" parameter, although no
*     further processing will occur. The same value will also be returned
*     if the function should fail for any reason. In either event, the
*     placeholder will still be annulled. The NDF__NOID constant is defined
*     in the header file "ndf.h".

*  Copyright:
*     Copyright (C) 2018 East Asian Observatory
*     All rights reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or modify
*     it under the terms of the GNU General Public License as published by
*     the Free Software Foundation; either version 2 of the License, or (at
*     your option) any later version.
*
*     This program is distributed in the hope that it will be useful,but
*     WITHOUT ANY WARRANTY; without even the implied warranty of
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*     General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     DSB: David S. Berry (EAO)

*  History:
*     3-APR-2019 (DSB):
*        Original version, based on equivalent Fortran function by RFWS.

*-
*/

/* Local Variables: */
   NdfACB *acb;          /* Pointer to NDF entry in the ACB */
   NdfPCB *pcb;          /* Pointer to placeholder entry in the PCB */
   char type[ NDF__SZTYP + 1 ];    /* Numeric data type */
   hdsdim lbnd[ NDF__MXDIM ];      /* Lower bounds of NDF */
   int cmplx;            /* Whether the data type is complex */
   int erase;            /* Whether to erase placeholder object */
   int i;                /* Loop counter for dimensions */
   int tstat;            /* Temporary status variable */

/* Ensure the NDF library has been initialised. */
   NDF_INIT( status );

/* Set an initial value for the "indf" parameter. */
   *indf = NDF__NOID;

/* Save the "status" value and mark the error stack. */
   tstat = *status;
   errMark();

/* Import the NDF placeholder, converting it to a PCB index. */
   *status = SAI__OK;
   pcb = NULL;
   ndf1Imppl( *place, &pcb, status );

/* If there has been no error at all so far, then check the data type
   for validity. Report an error if a complex data type has been
   specified. */
   if( ( *status == SAI__OK ) && ( tstat == SAI__OK ) ) {
      ndf1Chftp( ftype, type, sizeof( type ), &cmplx, status );
      if( cmplx ) {
         *status = NDF__FTPIN;
         msgSetc( "BADTYPE", ftype );
         errRep( " ", "The complex type '^BADTYPE' is not valid for a "
                 "primitive NDF (possible programming error).", status );
      }

/* Check the NDF upper bounds for validity. */
      if( *status == SAI__OK ) {
         for( i = 0; i < NDF_MIN( ndim, NDF__MXDIM ); i++ ){
            lbnd[ i ] = 1;
         }
         ndf1Vbnd( ndim, lbnd, ubnd, status );
      }

/* Create a new primitive NDF in place of the placeholder object,
   obtaining an ACB entry which refers to it. */
      if( *status == SAI__OK ) {
         NDF__DCB_LOCK_MUTEX;
         ndf1Dcrep( ftype, ndim, ubnd, pcb, &acb, status );
         NDF__DCB_UNLOCK_MUTEX;

/* Export an identifier for the NDF. */
         *indf = ndf1Expid( ( NdfObject * ) acb, status );

/* If an error occurred, then annul any ACB entry which may have been
   acquired. */
         if( *status != SAI__OK ) ndf1Anl( &acb, status );
      }
   }

/* Annul the placeholder, erasing the associated object if any error has
   occurred. */
   if( pcb ) {
      erase = ( ( *status != SAI__OK ) || ( tstat != SAI__OK ) );
      NDF__PCB_LOCK_MUTEX;
      ndf1Annpl( erase, &pcb, status );
      NDF__PCB_UNLOCK_MUTEX;
   }

/* Reset the "place" parameter. */
   *place = NDF__NOPL;

/* Annul any error if "status" was previously bad, otherwise let the new
   error report stand. */
   if( *status != SAI__OK ) {
      if( tstat != SAI__OK ) {
         errAnnul( status );
         *status = tstat;

/* If appropriate, report the error context and call the error tracing
   function. */
      } else {
         *indf = NDF__NOID;
         errRep( " ", "ndfNewp: Error creating a new primitive NDF.", status );
         ndf1Trace( "ndfNewp", status );
      }
   } else {
      *status = tstat;
   }

/* Release error stack. */
   errRlse();

/* Restablish the original AST status pointer */
   NDF_FINAL

}

