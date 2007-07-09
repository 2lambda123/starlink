/*
*+
*  Name:
*     sc2sim_simstats

*  Purpose:
*     Report statistics of the current simulation

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     sc2sim_simstats ( int npoints, double samptime, int maxwrite, int nbol, 
*                       int narray, int nboly, int *status )

*  Arguments:
*     npoints = int (Given)
*        Total number of sky positions sample in simulation
*     samptime = double (Given)
*        Integration time per sample in seconds
*     maxwrite = int (Given)
*        Number of samples to write out to the current file
*     nbol = int (Given)
*        Number of bolometers in a subarray
*     narray = int (Given)
*        Number of sub-arrays to be simulated
*     nboly = int (Given)
*        Number of bolometers along Y direction of sub-array
*     status = int* (Given and Returned)
*        Pointer to global status.  

*  Description:
*     This subroutine makes an estimate of the properties of the
*     current simulation and reports them to the user (stdout). From
*     the parameters give, estimates are made of:
*
*     - total integration time on source
*     - likely running time (based on a 1.6 GHz Opteron)
*     - the amount of data generated (storage requirements)
*     - the memory usage (RAM)
*
*     Note that largely these are just estimates and the actual
*     numbers may vary.

*  Authors:
*     A.G. Gibb (UBC)
*     Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History :
*     2007-03-01 (AGG):
*        Original version
*     2007-03-08 (AGG):
*        Minor change to units reported
*     2007-03-20 (TIMJ):
*        Make sure strings are terminated.
*     2007-05-22 (AGG):
*        Units of samptime are now SECONDS!
*     2007-07-09 (AGG):
*        Refactor usage calculations so short simulations don't report
*        0 MB usage

*  Copyright:
*     Copyright (C) 2007 University of British Columbia and Particle Physics and
*     Astronomy Research Council. All Rights Reserved.

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

/* Standard includes */
#include <string.h>

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"

/* SC2SIM includes */
#include "sc2sim.h"

/* SMURF includes */
#include "smurf_par.h"
#include "libsmf/smf.h"

#define SZTEMP 4

void sc2sim_simstats ( int npoints, double samptime, int maxwrite, int nbol, 
		       int narray, int nboly, int *status ) {

  /* Local variables */
  double simlength;              /* Length of simulation */
  char temp[SZTEMP];             /* temporary character string */
  JCMTState *head;               /* Pointer to a JCMTState struct */

  if ( *status != SAI__OK ) return;

  printf("\n ---- Reporting simulation statistics: ---- \n\n");
  /* Report length of time covered by simulation */
  simlength = npoints * samptime;
  if ( simlength > 60 && simlength < 3600 ) {
    simlength /= 60.0;
    strncpy( temp, "min", SZTEMP );
  } else if ( simlength > 3600 ) {
    simlength /= 3600.0;
    strncpy( temp, "hrs", SZTEMP);
  } else {
    strncpy( temp, "sec", SZTEMP);
  }
  printf( "  Simulation represents an observation of %5.2f %s\n", simlength,temp);

  /* Now estimate how long it will take : 142 s of data takes
     about 400 sec to run on a 1.6 GHz Opteron */
  simlength = 400.0 * (npoints * samptime) / 142.0;
  if ( simlength > 60 && simlength < 3600 ) {
    simlength /= 60.0;
    strncpy( temp, "min", SZTEMP );
  } else if ( simlength > 3600 ) {
    simlength /= 3600.0;
    strncpy( temp, "hrs", SZTEMP);
  } else {
    strncpy( temp, "sec", SZTEMP);
  }
  printf("  ...and will take ~ %5.2f *(1.6GHz/CPU) %s to run\n", simlength,temp);
  
  /* And finally tell user how much data this will generate (not
     including headers) */
  printf( "  ...and will generate ~ %4.1f MB of raw data\n", 
	  ( ( (double)(npoints*nbol*narray*sizeof(double)) ) / 3.1e6) );
  
  /* Report memory usage if desired: this adds up all the sizes of the
     smf_mallocs below as well as the allocation for posptr */
  printf("  ...and needs at least %d MB of memory\n", 
	 (int)(( maxwrite*( ( 12 + nbol*narray)*sizeof(double) 
			    + sizeof(*head) + (nbol + nboly)*sizeof(int) ) 
		 + 2*npoints*sizeof(double) ) /1e6 ));

  printf("\n ---- You have been warned! ----\n");
}
