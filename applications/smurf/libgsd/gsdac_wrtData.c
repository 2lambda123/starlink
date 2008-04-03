/*
*+
*  Name:
*     gsdac_wrtData

*  Purpose:
*     Write out the converted GSD2ACSIS file.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     gsdac_wrtData ( const gsdVars *gsdVars, char *directory, 
*                     const unsigned int nSteps, const dasFlag dasFlag, 
*                     int *status );

*  Arguments:
*     gsdVars = const gsdVars* (Given)
*        GSD headers and arrays
*     directory = char* (Given)
*        Directory to write the file
*     nSteps = const unsigned int (Given)
*        Number of steps in the observation
*     dasFlag = const dasFlag (Given)
*        DAS file structure type
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     Initializes the ACSIS directory for writing, writes a file for
*     each subsystem, then closes the files and writes the FITS 
*     headers.

*  Authors:
*     Jen Balfour (JAC, UBC)
*     {enter_new_authors_here}

*  History:
*     2008-02-05 (JB):
*        Original.
*     2008-02-14 (JB):
*        Use gsdVars struct to store headers/arrays.
*     2008-02-19 (JB):
*        Check dasFlag, fill gsdWCS.
*     2008-02-20 (JB):
*        Set memory usage for specwrite.
*     2008-02-21 (JB):
*        Allocate enough memory for fitschans.  
*     2008-02-26 (JB):
*        Make gsdac_getWCS per-subsystem.
*     2008-02-28 (JB):
*        Send each subband's data to correct file.
*     2008-02-28 (JB):
*        Move getDateVars and getMapVars out of putFits.
*     2008-03-04 (JB):
*        Use number of scans actually completed.
*     2008-03-07 (JB):
*        Fix calculation of amStart/End, azStart/End, elStart/End.
*     2008-03-19 (JB):
*        Removed unused variables.
*     2008-03-24 (JB):
*        Check for actual number of used receptors.
*     2008-03-25 (JB):
*        Write WCSFrame to the FITSchan.
*     2008-03-28 (JB):
*        Check for number of receptors used.
*     2008-04-03 (JB):
*        Convert AZEL start/end to degrees.

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
*     {note_any_bugs_here}
*-
*/

/* Standard includes */
#include <string.h>
#include <stdio.h>

/* STARLINK includes */
#include "ast.h"
#include "sae_par.h"
#include "mers.h"
#include "par.h"

/* SMURF includes */
#include "smurf_par.h"
#include "libacsis/specwrite.h"
#include "libsmf/smf.h"
#include "gsdac.h"
#include "jcmt/state.h"

#define FUNC_NAME "gsdac_wrtData"

#define MAXRECEP 2  
#define MAXSUBSYS 16

void gsdac_wrtData ( const gsdVars *gsdVars, const char *directory, 
                     const unsigned int nSteps, const dasFlag dasFlag, 
                     int *status )
{

  /* Local variables */
  float amEnd;                /* airmass at end of observation */
  float amStart;              /* airmass at start of observation */
  double azEnd;               /* Azimuth at observation end (deg) */
  double azStart;             /* Azimuth at observation start (deg) */
  char backend[SZFITSCARD];   /* name of the backend */
  char card[81];              /* FITS card for updating headers */
  dateVars dateVars;          /* date/time variables */
  double elEnd;               /* elevation at observation end (deg) */
  double elStart;             /* elevation at observation start (deg) */
  const AstFitsChan *fitschan[nSteps * gsdVars->nBESections];  
                              /* Array of FITS headers */
  long fitsIndex;             /* current FITSchan */
  char *focalStation = NULL;  /* focal station of the instrument */
  float fPlaneX[MAXRECEP]; 
  float fPlaneY[MAXRECEP];
  int i;                      /* loop counter */
  mapVars mapVars;            /* map/chop/scan variables */
  double mem;                 /* amount of memory for spectrum */
  int nSubsys;                /* number of subsystems */
  int obsNum;                 /* current observation number */
  char obsType[SZFITSCARD];   /* type of observation */
  char *OCSConfig = NULL;     /* OCS configuration XML */
  JCMTState *record = NULL;   /* JCMT state information for the 
                                 current spectrum */
  int recepFlags[MAXRECEP];   /* flags for which receptors were used */
  char *recepNames[MAXRECEP]; /* names of the receptors */
  int recepsUsed;             /* number of used receptors */
  char samMode[SZFITSCARD];   /* sampling mode (raster or grid) */
  ACSISSpecHdr *specHdr;      /* ACSIS spectrum-specific information */
  unsigned long specIndex;    /* index into spectral data */
  long spectrumSize;          /* size of spectrum data */
  unsigned int stepNum;       /* current step */
  int subBandNum;             /* subband number of current spectrum */
  unsigned int utDate;        /* UT date in YYYYMMDD format */
  gsdWCS wcs[nSteps];         /* pointing and time values for JCMTState */
  AstFrameSet *WCSFrame;      /* WCS frameset */

  /* Check inherited status */
  if ( *status != SAI__OK ) return;

  /* Get the UTDate and convert to YYYYMMDD format. */
  msgOutif(MSG__VERB," ", 
	   "Checking UTDate to retrieve observation number", status);

  /* Get the sample mode and obs type. */
  gsdac_getSampleMode ( gsdVars, samMode, obsType, status );

  utDate = (int)( ( gsdVars->obsUT1d + 0.00001 ) * 10000.0 );

  /* If the UTDate is prior to 20030202, prompt the user for the observation
     number.  Otherwise, use the value in NOBS. */
  if ( utDate < 20030202 )
    parGet0i ( "OBSNUM", &obsNum, status ); 
  else 
    obsNum = (int)gsdVars->nObs;

  /* Get the focal station. */
  focalStation = "DIRECT";

  for ( i = 0; i < gsdVars->nFEChans; i++ ) { 
    recepNames[i] = smf_malloc ( 3, sizeof( char ), 0, status );
    fPlaneX[i] = 0.0;
    fPlaneY[i] = 0.0;
  }

  /* Find out which receptors were used. */
  gsdac_getRecepNames ( gsdVars, recepNames, recepFlags, status );

  recepsUsed = recepFlags[0] + recepFlags[1];

  /* Determine how much memory we need and set the memory
     allocation in specwrite accordingly.  acsSpecSetMem wants
     to know how many bytes to allocate. */
  mem = gsdVars->nBEChansOut * gsdVars->noScans * 
        gsdVars->nScanPts * sizeof(float);

  acsSpecSetMem ( mem, status ); 

  msgOutif(MSG__VERB," ", 
	     "Preparing file writing system", status); 

  /* Find out how many subsystems there are (number of subbands
     divided by number of receptors). */
  nSubsys = gsdVars->nBESections / recepsUsed;

  /* Truncate the name of the backend. */
  cnfImprt ( gsdVars->backend, 16, backend );

  /* Set the backendFlag. */
  if ( strncmp ( backend, "DAS", 3 ) == 0 )
    acsSpecSetBackend ( ACS__BACKEND_DAS, status );
  else if ( strncmp ( backend, "AOSC", 4 ) == 0 )
    acsSpecSetBackend ( ACS__BACKEND_AOS, status );
  else {
    *status = SAI__ERROR;
    msgSetc ( "BACKEND", backend );
    errRep ( FUNC_NAME, "Backend ^BACKEND not supported", status );
    return;
  }

  acsSpecOpenTS ( directory, utDate, obsNum, recepsUsed, 
                  nSubsys, recepNames, focalStation, 
                  fPlaneX, fPlaneY, OCSConfig, status );
  /* Allocate memory for JCMTState, and SpecHdr. */
  record = smf_malloc ( 1, sizeof ( *record ), 0, status );
  specHdr = smf_malloc ( 1, sizeof ( *specHdr ), 0, status );

  msgOutif(MSG__VERB," ", "Getting date and time values", status); 

  gsdac_getDateVars ( gsdVars, backend, obsNum, &dateVars, status );

  msgOutif(MSG__VERB," ", "Getting map, chop, and scan values", status); 

  gsdac_getMapVars ( gsdVars, samMode, obsType, &mapVars, status );

  if ( *status != SAI__OK ) {
    errRep ( FUNC_NAME, "Error getting date and map parameters", status );
    return;
  }

  /* Get the size of the data array */
  spectrumSize = gsdVars->nBEChansOut * gsdVars->nScanPts * gsdVars->nScan;
                
  /* Iterate through each time step. */
  for ( stepNum = 0; stepNum < nSteps; stepNum++ ) {

    specIndex = ( stepNum * spectrumSize ) / nSteps;

    /* Fill JCMTState. */
    gsdac_putJCMTStateC ( gsdVars, stepNum, backend, dasFlag, 
                          record, status );  

    /* For each subband, write the files. */
    for ( subBandNum = 0; subBandNum < gsdVars->nBESections; subBandNum++ ) {

      /* Get the pointing and time values. */
      gsdac_getWCS ( gsdVars, stepNum, subBandNum, dasFlag, wcs, 
                     &WCSFrame, status );

      /* If this is the first spectrum, get the amStart, 
         azStart and elStart. */
      if ( stepNum == 0 && subBandNum == 0 ) {
        amStart = wcs->airmass;
        azStart = wcs->acAz / AST__DD2R;
        elStart = wcs->acEl / AST__DD2R;
      }

      /* For each step, update the amEnd, azEnd, and elEnd, so that the 
         final values are those for the last time step. */
      if ( stepNum == nSteps-1 && subBandNum == 0 ) {
        amEnd = wcs->airmass;
        azEnd = wcs->acAz / AST__DD2R;
        elEnd = wcs->acEl / AST__DD2R;
      }      

      /* Get the subsystem-dependent JCMTState values. */
      gsdac_putJCMTStateS ( gsdVars, stepNum, subBandNum, dasFlag, 
      	                    wcs, record, status );

      /* Get the ACSIS SpecHdr. */
      gsdac_putSpecHdr ( gsdVars, nSteps, stepNum, subBandNum, recepFlags, 
                         dasFlag, record, specHdr, status );

      msgOutif(MSG__VERB," ", "Writing data", status); 

      /* Write a spectrum to the file. */
      acsSpecWriteTS( ( subBandNum % nSubsys ) + 1, 
                      gsdVars->BEChans[subBandNum], 
      	              &(gsdVars->data[specIndex]), record, 
                      specHdr, status );

      /* Initialize the astFitsChan for this file. */
      fitsIndex = ( stepNum * gsdVars->nBESections ) + subBandNum;

      fitschan[fitsIndex] = astFitsChan ( NULL, NULL, "" );

      /* Fill the FITS headers. */
      gsdac_putFits ( gsdVars, subBandNum, nSubsys, obsNum, utDate, nSteps, 
                      backend, recepsUsed, recepNames, samMode, obsType, 
                      &dateVars, &mapVars, wcs, fitschan[fitsIndex], status );

      /* Write the WCSFrame information to the fitschan. */
      astWrite ( fitschan[fitsIndex], WCSFrame );

      specIndex = specIndex + gsdVars->BEChans[subBandNum];

      astAnnul ( WCSFrame );

    }

  }

  /* Update the FITS headers for amStart, amEnd, azStart, azEnd, 
     elStart, and elEnd. */
  for ( i = 0; i < nSteps * gsdVars->nBESections; i++ ) {

    astClear( fitschan[i], "Card" );
   
    astFindFits( fitschan[i], "AMSTART", card, 0 );
    astSetFitsF( fitschan[i], "AMSTART", amStart, NULL, 1 );
    astFindFits( fitschan[i], "AMEND", card, 0 );
    astSetFitsF( fitschan[i], "AMEND", amEnd, NULL, 1 );
    astFindFits( fitschan[i], "AZSTART", card, 0 );
    astSetFitsF( fitschan[i], "AZSTART", azStart, NULL, 1 );
    astFindFits( fitschan[i], "AZEND", card, 0 );
    astSetFitsF( fitschan[i], "AZEND", azEnd, NULL, 1 );
    astFindFits( fitschan[i], "ELSTART", card, 0 );
    astSetFitsF( fitschan[i], "ELSTART", elStart, NULL, 1 );
    astFindFits( fitschan[i], "ELEND", card, 0 );
    astSetFitsF( fitschan[i], "ELEND", elEnd, NULL, 1 );

  }    

  if ( *status != SAI__OK ) {
    *status = SAI__ERROR;
    errRep ( FUNC_NAME, "Error writing data", status );
    return;
  }  

  msgOutif(MSG__VERB," ", 
	   "Closing new file(s)", status);


  /* Close the file. */
  acsSpecCloseTS ( fitschan, 0, status );

  /* Free allocated memory. */
  smf_free ( record, status );
  smf_free ( specHdr, status );

  for ( i = 0; i < gsdVars->nFEChans; i++ ) { 
    smf_free ( recepNames[i], status );
  }


}

