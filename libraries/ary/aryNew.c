#include "sae_par.h"
#include "ary1.h"
#include "mers.h"
#include "dat_par.h"

void aryNew( const char *ftype, int ndim, const hdsdim *lbnd, const hdsdim *ubnd,
             AryPlace **place, Ary **ary, int *status ) {
/*
*+
*  Name:
*     aryNew

*  Purpose:
*     Create a new simple array.

*  Synopsis:
*     void aryNew( const char *ftype, int ndim, const hdsdim *lbnd, const hdsdim *ubnd,
*                  AryPlace **place, Ary **ary, int *status )

*  Description:
*     This function creates a new simple array and returns an identifier
*     for it. The array may subsequently be manipulated with other Ary
*     functions.

*  Parameters:
*     ftype
*        Full data type of the array.
*     ndim
*        Number of array dimensions.
*     lbnd
*        Lower pixel-index bounds of the array.
*     ubnd
*        Upper pixel-index bounds of the array.
*     place
*        On entry, holds an array placeholder (e.g. generated by the
*        aryPlace function) which indicates the position in the data
*        system where the new array will reside. The placeholder is
*        annulled by this function, and a value of NULL will be returned
*        on exit.
*     ary
*        Returned holding an identifier for the new array.
*     status
*        The global status.

*  Notes:
*     -  If this routine is called with "status" set, then a value of
*     NULL will be returned for the "ary" argument, although no
*     further processing will occur. The same value will also be
*     returned if the routine should fail for any reason. In either
*     event, the placeholder will still be annulled.

*  Copyright:
*      Copyright (C) 2017 East Asian Observatory
*      All rights reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     DSB: David S. Berry (EAO)

*  History:
*     03-JUL-2017 (DSB):
*        Original version, based on equivalent Fortran routine by RFWS.

*-
*/

/* Local variables: */
   char type[DAT__SZTYP+1];   /* Numeric type of the array */
   AryACB *acb;               /* Pointer to the ACB */
   AryDCB *dcb = NULL;        /* Pointer to the DCB */
   AryPCB *pcb;               /* Pointer to the PCB */
   int tstat;                 /* Temporary status variable */
   int cmplx;                 /* Whether a complex array is required */
   int erase;                 /* Whether to erase placeholder object */

/* Set an initial value for the returned "ary" argument. */
   *ary = NULL;

/* Save the "status" value and mark the error stack. */
   tstat = *status;
   errMark();

/* Import the array placeholder, converting it to a PCB pointer. */
   *status = SAI__OK;
   pcb = (AryPCB *) ary1Impid( *place, 0, 0, 0, status );

   ARY__DCB_LOCK_MUTEX;

/* If there has been no error at all so far, then check the full type
   specification and the array bounds information for validity. */
   if( ( *status == SAI__OK ) && ( tstat == SAI__OK ) ){
      ary1Vftp( ftype, sizeof(type), type, &cmplx, status );
      ary1Vbnd( ndim, lbnd, ubnd, status );

/* Create a new simple array structure in place of the placeholder object,
   obtaining a DCB entry which refers to it. */
      if( *status == SAI__OK ){
         ary1Dcre( 0, type, cmplx, ndim, lbnd, ubnd, pcb->tmp,
                   pcb->loc, &dcb, status );
      }

/* Create a base array entry in the ACB to refer to the DCB entry. */
      ary1Crnba( dcb, &acb, status );

/* Export an identifier for the array. */
      *ary = ary1Expid( (AryObject *) acb, status );
   }

   ARY__DCB_UNLOCK_MUTEX;

/* Annul the placeholder, erasing the associated object if any error has
   occurred. */
   if( pcb ){
      erase = ( *status != SAI__OK ) || ( tstat != SAI__OK );
      ary1Annpl( erase, &pcb, status );
   }

/* Reset the PLACE argument. */
   *place = NULL;

/* Annul any error if STATUS was previously bad, otherwise let the new
   error report stand. */
   if( *status != SAI__OK ){
      if( tstat != SAI__OK ){
         errAnnul( status );
         *status = tstat;

/* If appropriate, report the error context and call the error tracing
   routine. */
      } else {
         *ary = NULL;
         errRep( " ", "aryNew: Error creating a new simple array.", status );
         ary1Trace( "aryNew", status );
      }
   } else {
      *status = tstat;
   }

/* Release error stack. */
   errRlse();

}
