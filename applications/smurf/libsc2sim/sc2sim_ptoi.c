/*
*+
*  Name:
*     sc2sim_ptoi

*  Purpose:
*     Convert input pW to bolometer current

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     sc2sim_ptoi ( double flux, int ncoeffs, double coeffs[], 
*                   double pzero, double *current, int *status )

*  Arguments:
*     flux = double (Given)
*        Input flux in pW
*     ncoeffs = int (Given)
*        Numbe rof coefficients describing response curve
*     coeffs = double[] (Given)
*        Array to hold response curve coefficients
*     pzero = calibratio noffset in pW
*        Calibration offset in pW
*     current = double* (Returned)
*        Signal from bolometer in amps
*     status = int* (Given and Returned)
*        Pointer to global status.  

*  Description:
*     Given a flux in pW, apply the bolometer response curve with the
*     bolometer-specific shift.
*     The coefficients represent a numerical model of the bolometer
*     response by Damian Audley which he fitted to a 5th order polynomial 
*     so that
*     I = a0 + a1*P +a2*P^2 + a3*P^3 + a4*P^4 + a5*P^5
*     where I is the current in amps and P is the input power in picowatts.
* 
*     This is valid for powers between 0 and 50 pW at 850.

*  Authors:
*     B.D.Kelly (ROE)
*     {enter_new_authors_here}

*  History :
*     2001-07-26 (BDK):
*        Original
*     2002-08-21 (BDK)
*        C version
*     2005-08-11 (BDK)
*        Trap obviously out of range values
*     2006-07-21 (JB):
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

void sc2sim_ptoi
( 
double flux,       /* input flux in pW (given) */
int ncoeffs,       /* number of coefficients describing response curve
                      (given) */
double coeffs[],   /* array to hold response curve coefficients (given) */
double pzero,      /* calibration offset in pW (given) */
double *current,   /* signal from bolometer in amps (returned) */
int *status        /* global status (given and returned) */
)

{
   /* Local variables */
   double p;

   /* Check status */
   if ( !StatusOkP(status) ) return;

   p = flux + pzero;

   if ( ( p > 0.0 ) && ( p < 200.0 ) ) {
      *current = coeffs[0] + coeffs[1] * p + coeffs[2] * p*p + 
        coeffs[3] * p*p*p + coeffs[4] * p*p*p*p + coeffs[5] * p*p*p*p*p;
   } else {
      *status = DITS__APP_ERROR;
      printf ( "sc2sim_ptoi: flux value, %g, outside bolometer range (0-200)\n", p );
   }

}
