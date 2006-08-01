/*
*+
*  Name:
*     sc2sim_getinvf

*  Purpose:
*     Return a compressed form of 1/f noise

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     sc2sim_getinvf ( double sigma, double corner, double samptime, 
                       double nterms, double *noisecoeffs, int *status )

*  Arguments:
*     sigma = double (Given)
*        Dispersion of broad-band noise
*     corner = double (Given)
*        Corner frequency, where 1/f dispersion=sigma
*     samptime = double (Given)
*        Time per data sample
*     nterms = double (Given)
*        Number of frequencies calculated
*     noisecoeffs = double* (Returned)
*        1/f spectrum 
*     status = int* (Given and Returned)
*        Pointer to global status.  

*  Description:
*    The lowest few Fourier components of a 1/f noise simulation are calculated
*    and returned.
*    Each component is described by its period and its cosine and sine
*    amplitudes.

*  Authors:
*     B.D.Kelly (ROE)
*     {enter_new_authors_here}

*  History :
*     2004-01-23 (BDK):
*        Original
*     2005-06-29 (BDK)
*        Extend up to twice the corner frequency
*     2006-07- (JB):
*        Split from dsim.c

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research
*     Council. University of British Columbia. All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
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

/* SC2SIM includes */
#include "sc2sim.h"

void sc2sim_getinvf 
( 
double sigma,        /* dispersion of broad-band noise (given) */ 
double corner,       /* corner frequency, where 1/f dispersion=sigma (given)*/
double samptime,     /* time per data sample (given) */
double nterms,       /* number of frequencies calculated (given) */
double *noisecoeffs, /* 1/f spectrum (returned) */
int *status          /* global status (given and returned) */
)

{

   /* Local variables */
   double deltanu;    /* frequency interval */
   int j;             /* LOOP COUNTER */
   double noise;      /* dispersion at a frequency */
   double nu;         /* frequency */

   /* Check status */
   if ( !StatusOkP(status) ) return;

   /* Calculate noise amplitudes at even frequency intervals up to twice the
      corner frequency, ignoring zero frequency */

   deltanu = 2.0 * corner / (double)nterms;
   for ( j=0; j<nterms; j++ ) {
      nu = deltanu * (double)( 1 + j );
      noise = sigma * corner / nu;
      noisecoeffs[3*j] = 1.0 / nu;
      noisecoeffs[3*j+1] = sc2sim_drand ( noise );
      noisecoeffs[3*j+2] = sc2sim_drand ( noise );
   }//for

}//sc2sim_getinvf


