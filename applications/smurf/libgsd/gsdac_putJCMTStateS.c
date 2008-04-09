/*
*+
*  Name:
*     gsdac_putJCMTStateS

*  Purpose:
*     Fill the subband-dependent JCMTState headers. 

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     gsdac_putJCMTStateS ( const gsdVars *gsdVars, 
*                           const unsigned int stepNum, const int subBandNum,
*                           const dasFlag dasFlag, const gsdWCS *wcs, 
*                           struct JCMTState *record, int *status );

*  Arguments:
*     gsdVars = const gsdVars* (Given)
*        GSD headers and arrays
*     stepNum = const unsigned int (Given)
*        time step of this spectrum
*     subBandNum = const int (Given)
*        Subband number
*     dasFlag = const dasFlag (Given)
*        DAS file structure type
*     wcs = const gsdWCS* (Given)
*        Pointing and time values
*     record = JCMTState** (Given and returned)
*        JCMTState headers
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Determines the headers required for a JCMTState header
*     in an ACSIS format file from a GSD file.  This routine determines
*     the values of the JCMTState elements which are dependent upon
*     this particular subband.  

*  Authors:
*     Jen Balfour (JAC, UBC)
*     {enter_new_authors_here}

*  History:
*     2008-01-29 (JB):
*        Original.
*     2008-02-14 (JB):
*        Use gsdVars struct to store headers/arrays.
*     2008-02-18 (JB):
*        Check dasFlag.
*     2008-02-22 (JB):
*        Calculate fe_doppler.
*     2008-02-26 (JB):
*        Make gsdac_getWCS per-subsystem.
*     2008-02-28 (JB):
*        Replace subsysNum with subBandNum.
*     2008-03-24 (JB):
*        Fix bug in getting AZ demand coordinates.
*     2008-04-08 (JB):
*        Convert sample time to days before adding to TAI.


*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     Currently kludged with default values.
*-
*/

/* Standard includes */
#include <string.h>
#include <stdio.h>

/* Starlink includes */
#include "sae_par.h"

/* SMURF includes */
#include "gsdac.h"
#include "jcmt/state.h"
#include "smurf_par.h"

void gsdac_putJCMTStateS ( const gsdVars *gsdVars, 
                           const unsigned int stepNum, const int subBandNum,
                           const dasFlag dasFlag, const gsdWCS *wcs, 
                           struct JCMTState *record, int *status )
{

  /* Local variables */
  int arrayIndex;             /* index into array for retrieving values */

  /* Check inherited status */
  if ( *status != SAI__OK ) return;

  /* Get the rts_end which is the TAI time plus half the 
     on-source integration time.  For rasters the on-source
     integration time is the scan_time divided by the 
     number of map points per scan.  For non-rasters the 
     on-source integration time is given by the scan_time. */
  if ( gsdVars->obsContinuous ) {
    record->rts_end = wcs->tai + 
                      ( gsdVars->scanTime / ( gsdVars->nScanPts * 2.0 * SPD ) );
  } else {
    record->rts_end = wcs->tai + ( gsdVars->scanTime / ( 2.0 * SPD ) );
  }

  record->tcs_tai = wcs->tai;

  record->tcs_airmass = wcs->airmass;

  record->tcs_az_ang = wcs->azAng;

  record->tcs_az_ac1 = wcs->acAz;

  record->tcs_az_ac2 = wcs->acEl;

  record->tcs_az_dc1 = record->tcs_az_ac1;

  record->tcs_az_dc2 = record->tcs_az_ac2;

  record->tcs_az_bc1 = wcs->baseAz;

  record->tcs_az_bc2 = wcs->baseEl;

  record->tcs_tr_ang = wcs->trAng;

  record->tcs_tr_ac1 = wcs->acTr1;

  record->tcs_tr_ac2 = wcs->acTr2;

  record->tcs_tr_dc1 = record->tcs_tr_ac1;

  record->tcs_tr_dc2 = record->tcs_tr_ac2;

  record->tcs_tr_bc1 = wcs->baseTr1;

  record->tcs_tr_bc2 = wcs->baseTr2;

  record->tcs_index = wcs->index;

 /* Get the frontend LO frequency. */
  record->fe_lofreq = gsdVars->LOFreqs[subBandNum]; 

  /* Use the dasFlag to determine the dimensionality/size of
     the TSKY array. */
  if ( dasFlag == DAS_CONT_CAL ) {
    arrayIndex =  ( stepNum * gsdVars->nBESections ) +
                  subBandNum;
  } else {
    arrayIndex = subBandNum;
  }

  /* Set the enviro_air_temp to the correct value from the
     TSKY array. */
  record->enviro_air_temp = gsdVars->skyTemps[arrayIndex];

  record->fe_doppler = gsdVars->restFreqs[subBandNum] / 
               ( record->fe_lofreq + gsdVars->totIFs[subBandNum] );

}
