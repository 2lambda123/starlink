/*
*+
*  Name:
*     gsdac_putJCMTStateC

*  Purpose:
*     Fill the subsystem-independent JCMTState headers.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     gsdac_putJCMTStateC ( const gsdVars *gsdVars, const unsigned int stepNum,
*                           const char *backend, const dasFlag dasFlag,
*                           struct JCMTState *record, int *status );

*  Arguments:
*     gsdVars = const gsdVars* (Given)
*        GSD headers and arrays
*     stepNum = const unsigned int (Given)
*        Time step of this spectrum
*     backend = const char* (Given)
*        Name of the backend
*     dasFlag = const dasFlag (Given)
*        DAS file structure type
*     record = JCMTState* (Given and returned)
*        JCMTState headers
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Determines the headers required for a JCMTState header
*     in an ACSIS format file from a GSD file.  This routine determines
*     the values of the JCMTState elements which are common to all
*     subsystems.

*  Authors:
*     Jen Balfour (JAC, UBC)
*     {enter_new_authors_here}

*  History:
*     2008-01-29 (JB):
*        Original.
*     2008-02-14 (JB):
*        Use gsdVars struct to store headers/arrays.
*     2008-02-18 (JB):
*        Get values from gsdWCS.
*     2008-02-22 (JB):
*        Move fe_doppler calc to getJCMTStateS.
*     2008-02-26 (JB):
*        Make gsdac_getWCS per-subsystem.
*     2008-02-28 (JB):
*        Code cleanup.
*     2008-03-25 (JB):
*        Get tracking coordinate frame.
*     2008-04-02 (JB):
*        Get TCS_TR_SYS.
*     2008-04-08 (JB):
*        Don't convert PAMB, it is already in mbar.
*     2008-04-30 (JB):
*        Allow for MPI frontend.

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
*-
*/

/* Standard includes */
#include <string.h>
#include <stdio.h>
#include <math.h>

/* Starlink includes */
#include "ast.h"
#include "sae_par.h"
#include "prm_par.h"
#include "mers.h"

/* SMURF includes */
#include "gsdac.h"
#include "jcmt/state.h"

#define FUNC_NAME "gsdac_putJCMTStateC"

void gsdac_putJCMTStateC ( const gsdVars *gsdVars, const unsigned int stepNum,
                           const char *backend, const dasFlag dasFlag,
                           struct JCMTState *record, int *status )
{

  /* Check inherited status */
  if ( *status != SAI__OK ) return;

  /* Fill the JCMTState. */

  record->rts_num = stepNum + 1;

  /* Check the frontend name to determine tasklist. */
  if ( strncmp ( gsdVars->frontend, "MPI", 3 ) == 0 ) {
    strncpy ( record->rts_tasks, "PTCS FE_E ", 11 );
  } else {
    sprintf ( record->rts_tasks, "PTCS FE_%c %s",  gsdVars->frontend[2], backend );
  }

  record->smu_x = 0.0;

  record->smu_y = 0.0;

  record->smu_z = 0.0;

  strncpy( record->smu_chop_phase, "M", 2 );

  record->smu_jig_index = VAL__BADI;

  record->smu_az_jig_x = 0.0;

  record->smu_az_jig_y = 0.0;

  record->smu_az_chop_x = 0.0;

  record->smu_az_chop_y = 0.0;

  record->smu_tr_jig_x = 0.0;

  record->smu_tr_jig_y = 0.0;

  record->smu_tr_chop_x = 0.0;

  record->smu_tr_chop_y = 0.0;

  strncpy( record->tcs_beam, "M", 2 );

  strncpy( record->tcs_source, "SCIENCE", 8 );

  /* Get the tracking coordinate system. */
  switch ( gsdVars->centreCode ) {

    case COORD_AZ:
      strcpy ( record->tcs_tr_sys, "AZEL" );
      break;
    case COORD_EQ:
      *status = SAI__ERROR;
      errRep ( FUNC_NAME, "Equatorial coordinates not supported", status );
      return;
      /*strcpy ( record->tcs_tr_sys, "HADEC" ); */
      break;
    case COORD_RD:
      strcpy ( record->tcs_tr_sys, "APP" );
      break;
    case COORD_RB:
      strcpy ( record->tcs_tr_sys, "B1950" );
      break;
    case COORD_RJ:
      strcpy ( record->tcs_tr_sys, "J2000" );
      break;
    case COORD_GA:
      strcpy ( record->tcs_tr_sys, "GAL" );
      break;
    default:
      strcpy ( record->tcs_tr_sys, "" );
      msgOutif(MSG__VERB," ",
               "Couldn't identify tracking coordinates, continuing anyway", status);
      break;

  }

  record->jos_drcontrol = 0;

  record->enviro_rel_hum = gsdVars->hamb;

  record->enviro_pressure = gsdVars->pamb;

  /* If this is a raster, the on-source integration time is
     the scan time divided by the number of points in the scan,
     and the off-source time is the square root of the
     number of points in the scan times the on-source time.
     For non-rasters use the values stored in the INTGRN_TIME
     array for both on- and off-exposure times. */
  if ( gsdVars->obsContinuous ) {
    record->acs_exposure = (double)(gsdVars->scanTime) /
                           (double)(gsdVars->nScanPts);
    record->acs_offexposure = record->acs_exposure *
                              sqrt(gsdVars->nScanPts);
  } else {
    record->acs_exposure = gsdVars->intTimes[stepNum];
    record->acs_offexposure = record->acs_exposure;
  }

  record->acs_no_prev_ref = VAL__BADI;

  record->acs_no_next_ref = VAL__BADI;

  record->acs_no_ons = VAL__BADI;

  strncpy( record->acs_source_ro, "SPECTRUM_RESULT", 16 );

  record->pol_ang = VAL__BADD;

}
