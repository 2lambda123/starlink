/*
*+
*  Name:
*     smf_fft_cart2pol

*  Purpose:
*     Convert between cartesian and polar representations of fft'd data

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     SMURF subroutine

*  Invocation:
*     void smf_fft_cart2pol( smfData *data, int inverse, int *status );

*  Arguments:
*     data = smfData * (Given)
*        smfData to convert
*     inverse = int (Given)
*        If set convert polar --> cartesian. Otherwise cartesian --> polar.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Returned Value:

*  Description:
*     Convert between cartesian representation of the transform (real, 
*     imaginary) and polar form (amplitude, argument). The argument is
*     stored in radians in the range (-PI,PI). 

*  Authors:
*     Ed Chapin (UBC)
*     {enter_new_authors_here}

*  Notes:
*     Currently the only check for a valid input storage form is on the
*     range of the argument (-pi,pi) in the case of polar-->cartesian
*     conversion. Otherwise it is up to the caller to know what form
*     their data is stored in.

*  History:
*     2008-09-18 (EC):
*        Initial version.

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

#if HAVE_CONFIG_H
#include <config.h>
#endif

/* System includes */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "msg_par.h"
#include "star/one.h"

/* SMURF routines */
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"

#define FUNC_NAME "smf_fft_cart2pol"

void smf_fft_cart2pol( smfData *data, int inverse, int *status ) {

  double amp;                   /* Amplitude coeff */
  double *baseR=NULL;           /* base pointer to real/amplitude coeff */
  double *baseI=NULL;           /* base pointer to imag/argument coeff */
  size_t i;                     /* Loop counter */
  double imag;                  /* Imaginary coeff */
  size_t j;                     /* Loop counter */
  dim_t nbolo=0;                /* Number of detectors  */
  dim_t nf=0;                   /* Number of frequencies in FFT */
  dim_t ntslice;                /* Number of time slices in data */
  double real;                  /* Real coeff */
  double theta;                 /* Argument */

  if( *status != SAI__OK ) return;

  if( data == NULL ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": NULL smfData pointer provided"
            " (possible programming error)", status);
  }

  if( !smf_isfft(data, &ntslice, &nbolo, &nf, status) ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": smfData provided is not FFT data"
            " (possible programming error)", status);
  }

  if( *status != SAI__OK ) return;

  /* Loop over bolometer */

  for( i=0; (*status==SAI__OK)&&(i<nbolo); i++ ) {
    /* Pointers to components of this bolo */
    baseR = data->pntr[0];
    baseR += i*nf;
    baseI = baseR + nf*nbolo;


    if( inverse ) {
      for( j=0; (*status==SAI__OK)&&(j<nf); j++ ) {
        if( fabs(baseI[j]) > AST__DPI ) {
          /* Check for valid argument */
          *status = SAI__ERROR;
          errRep( "", FUNC_NAME 
                  ": abs(argument) > PI. FFT data may not be in polar form.", 
                  status);
          
        } else {
          /* Convert polar --> cartesian */
          real = baseR[j]*cos(baseI[j]);
          imag = baseR[j]*sin(baseI[j]);
          //printf( "%d %d %d %d\n", baseR, baseI, real, imag); 
          baseR[j] = real;
          baseI[j] = imag;
        }
      }
    } else {
      for( j=0; j<nf; j++ ) {
        /* Convert cartesian --> polar */
        amp = sqrt( baseR[j]*baseR[j] + baseI[j]*baseI[j] );
        theta = atan2( baseI[j], baseR[j] );
        baseR[j] = amp;
        baseI[j] = theta;
      }
    }
    
  }

}
