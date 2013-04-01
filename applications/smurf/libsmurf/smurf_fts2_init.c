/*
 * +
 *  Name:
 *     FTS2INIT
 *
 *  Purpose:
 *     Prepares the input to be processed by the FTS2 Data Reduction tasks
 *
 *  Language:
 *     Starlink ANSI C
 *
 *  Type of Module:
 *     ADAM TASK
 *
 *  Invocation:
 *     smurf_fts2_init(status);
 *
 *  Arguments:
 *     status = int* (Given and Returned)
 *        Pointer to global status.
 *
 *  Description:
 *     Prepares the input to be processed by the FTS2 Data Reduction tasks
 *
 *  ADAM Parameters:
 *     IN = NDF (Read)
 *          Input files to be transformed.
 *     OUT = NDF (Write)
 *          Output files.
 *     ZPD = NDF (Read)
 *          ZPD calibration file.
 *
 *  Authors:
 *     COBA: Coskun Oba (UoL)
 *     MSHERWOOD: Matt Sherwood (UofL)
 *
 *  History :
 *     23-NOV-2010 (COBA):
 *        Original version.
 *     2011-05-05 (COBA):
 *        - Get mirror positions via fts2_getmirrorpositions
 *        - Fixed possible memory leaks
 *        - Removed redundancies
 *     2012-12-12 (MSHERWOOD):
 *        Put back adjustment for non-centered mirror starting position.
 *     2012-12-21 (MSHERWOOD)
 *        Removed unneccessary sort (fts2_validatemirrorpositions now reverses list when needed)
 *
 *  Copyright:
 *     Copyright (C) 2008 Science and Technology Facilities Council.
 *     Copyright (C) 2008 University of Lethbridge. All Rights Reserved.
 *
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
 *
 *  Bugs:
 *     {note_any_bugs_here}
 *-
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include <stdio.h>
#include <gsl/gsl_spline.h>

/* STARLINK includes */
#include "ast.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "ndf.h"
#include "mers.h"
#include "prm_par.h"
#include "sae_par.h"
#include "msg_par.h"
#include "par_err.h"
#include "par.h"

/* SMURF includes */
#include "smurf_par.h"
#include "libsmf/smf.h"
#include "smurflib.h"
#include "libsmf/smf_err.h"
#include "sc2da/sc2store.h"
#include "libsc2fts/fts2.h"

#define FUNC_NAME "smurf_fts2_init"
#define TASK_NAME "FTS2INIT"

void smurf_fts2_init(int* status)
{
  if( *status != SAI__OK ) { return; }

  const double STAGE_CENTER = 225.0;    /* mm */
  Grp* gIn                  = NULL;     /* Input group */
  Grp* gOut                 = NULL;     /* Output group */
  Grp* gZpd                 = NULL;     /* ZPD group */
  smfData* inData           = NULL;     /* Pointer to input data */
  smfData* outData          = NULL;     /* Pointer to output data */
  smfData* zpdData          = NULL;     /* Pointer to ZPD data */
  smfData* zpd              = NULL;     /* Pointer to ZPD index data */
  smfData* fpm              = NULL;     /* Pointer polynomial fit parameters */
  smfData* sigma            = NULL;
  int nMirPos               = 0;        /* Number of frames where the mirror actually moves */
  int nStart                = 0;        /* Frame index where the mirror starts moving */
  int nStop                 = 0;        /* Frame index where the mirror stops */
  int i                     = 0;        /* Counter */
  int j                     = 0;        /* Counter */
  int k                     = 0;        /* Counter */
  double fNyquist           = 0.0;      /* Nyquist frequency */
  double dz                 = 0.0;      /* Step size in evenly spaced OPD grid */
  double dx                 = 0.0;      /* Step size in evenly spaced mirror position grid */
  double* MIRPOS            = NULL;     /* Mirror positions */
  double* IFG               = NULL;     /* Interferogram */
  double* OPD               = NULL;     /* Optical Path Difference */
  double* OPD_EVEN          = NULL;     /* Optical Path Difference, evenly spaced */
  gsl_interp_accel* ACC     = NULL;
  gsl_spline* SPLINE        = NULL;

  size_t nFiles             = 0;        /* Size of the input group */
  size_t nOutFiles          = 0;        /* Size of the output group */
  size_t nZPDFiles          = 0;        /* Size of the ZPD group */
  size_t fIndex             = 0;        /* File index */
  size_t nWidth             = 0;        /* Data cube width */
  size_t nHeight            = 0;        /* Data cube height */
  size_t nFrames            = 0;        /* Data cube depth */
  size_t nPixels            = 0;        /* Number of bolometers in the subarray */
  smfSortInfo* SORTINFO     = NULL;

  char object[SZFITSTR];
  char subarray[SZFITSTR];
  char obsID[SZFITSTR];
  char scanMode[SZFITSTR];

  double scanVel            = 0.0;      /* Mirror speed in mm/sec */
  double stepTime           = 0.0;      /* RTS sep time, average sample rate */
  double minOPD             = 0;        /* OPD minimum */
  double maxOPD             = 0;        /* OPD maximum */
  double ZPD                = 0;
  int nTmp                  = 0;
  int nMax                  = 0;
  int nOPD                  = 0;
  int bolIndex              = 0;
  int index                 = 0;
  int badPixel              = 0;
  int k0                    = 0;
  int indexZPD              = 0;
  
  /* Get Input, Output and ZPD groups */
  kpg1Rgndf("IN", 0, 1, "", &gIn, &nFiles, status);
  kpg1Wgndf("OUT", gOut, nFiles, nFiles, "Equal number of input and output files expected!", &gOut, &nOutFiles, status);
  kpg1Gtgrp("ZPD", &gZpd, &nZPDFiles, status);

  /* BEGIN NDF */
  ndfBegin();

  /* Open the ZPD calibration file */
  smf_open_file(gZpd, 1, "READ", SMF__NOCREATE_QUALITY, &zpdData, status);
  if(*status != SAI__OK) {
    *status = SAI__ERROR;
    errRep(FUNC_NAME, "Unable to open the ZPD calibration file!", status);
    goto CLEANUP;
  }
  
  /* Loop through each input file */
  for(fIndex = 1; fIndex <= nFiles; fIndex++) {
    /* Open Observation file */
    smf_open_and_flatfield(gIn, gOut, fIndex, NULL, NULL, NULL, &inData, status);
    if(*status != SAI__OK) {
      *status = SAI__ERROR;
      errRep(FUNC_NAME, "Unable to open the source file!", status);
      goto CLEANUP;
    }

    /* Data cube dimensions */
    nWidth  = inData->dims[0];
    nHeight = inData->dims[1];
    nFrames = inData->dims[2];
    nPixels = nWidth * nHeight;

    /* Mirror positions in mm */
    nTmp = nFrames;
    MIRPOS = astCalloc(nFrames, sizeof(*MIRPOS));
    fts2_getmirrorpositions(inData, MIRPOS, &nTmp, status); // (mm)
    if(*status != SAI__OK) {
      *status = SAI__ERROR;
      errRep( FUNC_NAME, "Unable to get the mirror positions!", status);
      goto CLEANUP;
    }
    fts2_validatemirrorpositions(MIRPOS, nFrames, &nStart, &nStop, inData, status);
    if(*status != SAI__OK) {
      *status = SAI__ERROR;
      errRep( FUNC_NAME, "Unable to validate the mirror positions!", status);
      goto CLEANUP;
    }

    /* THIS WILL NO LONGER NECESSARY WHEN THE FTS2 MIRROR POSITIONS ARE READ IN [-225, 225]
       Transform mirror positions from [0, 450] to [-225, 225] */
       for(k = 0; k < nFrames; k++) { MIRPOS[k] -= STAGE_CENTER; }

    /* The number of mirror positions with unique values */
    nMirPos = nStop - nStart + 1;

    /* Corresponding OPD values */
    OPD = astCalloc(nMirPos, sizeof(*OPD));
    for(k = nStart; k <=nStop; k++) { OPD[k - nStart] = 4.0 * MIRPOS[k] / 10.0; }

    scanVel   = 0.0;
    stepTime  = 0.0;
    smf_fits_getS(inData->hdr, "OBJECT", object, sizeof(object), status);
    smf_fits_getS(inData->hdr, "SUBARRAY", subarray, sizeof(subarray), status);
    smf_fits_getS(inData->hdr, "OBSID", obsID, sizeof(obsID), status);
    smf_fits_getS(inData->hdr, "FTS_MODE", scanMode, sizeof(scanMode), status);
    smf_fits_getD(inData->hdr, "SCANVEL", &scanVel, status);
    smf_fits_getD(inData->hdr, "STEPTIME", &stepTime, status);

    /* Nyquist frequency */
    fNyquist = 10.0 / (8.0 * scanVel * stepTime);
    minOPD = OPD[0];
    maxOPD = OPD[nMirPos - 1];
    if(fabs(minOPD) < fabs(maxOPD)) maxOPD = fabs(minOPD);
    minOPD = -maxOPD;
    dz = 1.0 / (2.0 * fNyquist);

    /* Evenly spaced OPD grid */
    nMax = (int) (fabs(maxOPD) / dz) + 1;
    nOPD = 2 * (nMax - 1);

    OPD_EVEN = astCalloc(nOPD, sizeof(*OPD_EVEN));
    for(k = 1; k <= nOPD; k++) {
      OPD_EVEN[k - 1] = (k < nMax) ? -(nMax - k) : (k - nMax + 1);
      OPD_EVEN[k - 1] *= dz;
    }

    /* Update FITS component */
    smf_fits_updateD(inData->hdr, "FNYQUIST", fNyquist, "Nyquist frequency (cm^-1)", status);
    smf_fits_updateI(inData->hdr, "MIRSTART", nStart, "Frame index in which the mirror starts moving", status);
    smf_fits_updateI(inData->hdr, "MIRSTOP", nStop, "Frame index in which the mirror stops moving", status);
    smf_fits_updateD(inData->hdr, "OPDMIN", OPD_EVEN[0], "Minimum OPD", status);
    smf_fits_updateD(inData->hdr, "OPDSTEP", dz, "OPD step size", status);

    /* Copy input data into output data */
    outData = smf_deepcopy_smfData(inData, 0, SMF__NOCREATE_DATA | SMF__NOCREATE_FTS, 0, 0, status);
    outData->dtype   = SMF__DOUBLE;
    outData->ndims   = 3;
    outData->dims[0] = nWidth;
    outData->dims[1] = nHeight;
    outData->dims[2] = nOPD;
    outData->pntr[0] = (double*) astMalloc((nPixels * nOPD) * sizeof(double));

    /* Create a 2D ZPD index array and store it in the file */
    zpd = smf_create_smfData(SMF__NOCREATE_DA | SMF__NOCREATE_FTS, status);
    zpd->dtype   = SMF__INTEGER;
    zpd->ndims   = 2;
    zpd->dims[0] = nWidth;
    zpd->dims[1] = nHeight;
    zpd->pntr[0] = (int*) astCalloc(nPixels,  sizeof(int));
    /* By default set ZPD indices to a bad value */
    for(i = 0; i < nWidth; i++) {
      for(j = 0; j < nHeight; j++) {
        bolIndex = i + j * nWidth;
        *((int*) (zpd->pntr[0]) + bolIndex) = VAL__BADI;
      }
    }

    /* Allocate memory for arrays */
    IFG = astCalloc(nMirPos, sizeof(*IFG));

    /* Prepare GSL interpolator */
    ACC    = gsl_interp_accel_alloc();
    SPLINE = gsl_spline_alloc(gsl_interp_cspline, nMirPos);

    /* Interpolate interferograms in each pixel onto an evenly spaced grid */
    for(i = 0; i < nWidth; i++) {
      for(j = 0; j < nHeight; j++) {
        bolIndex = i + j * nWidth;

        /* ZPD position in OPD grid */
        ZPD = *((double*) (zpdData->pntr[0]) + bolIndex);
        /* Convert from mechanical mm (x 4) to optical cm (/ 10) */
        ZPD = ZPD * 0.4;

        badPixel = 0;
        /* Read in interferogram */
        for(k = nStart; k <= nStop; k++) {
          index = bolIndex + nPixels * k;

          k0 = k - nStart;
          IFG[k0] = *((double*) (inData->pntr[0]) + index);

          /* See if this is a bad pixel */
          if(IFG[k0] == VAL__BADD) { badPixel = 1; break; }
        }
        /* If this is a bad pixel, go to next */
        if(badPixel) {
          for(k = 0; k < nOPD; k++) {
            index = bolIndex + k * nPixels;
            *((double*)(outData->pntr[0]) + index) = VAL__BADD;
          }
          continue;
        }

        /* Interpolate */
        gsl_spline_init(SPLINE, OPD, IFG, nMirPos);

        /* Update the output and OPD
           Also determine where the ZPD index is and update the 2D ZPD array */
        indexZPD = 0;
        for(k = 0; k < nOPD; k++) {
          index = bolIndex + nPixels * k;
          *((double*)(outData->pntr[0]) + index) = gsl_spline_eval(SPLINE,  OPD_EVEN[k], ACC);

          if(OPD_EVEN[k] <= ZPD) { indexZPD = k;}
        }
        *((int*) (zpd->pntr[0]) + bolIndex) = indexZPD;
      }
    }

    /* Deallocate memory used by arrays */
    if(IFG)     { IFG       = astFree(IFG); }
    if(OPD)     { OPD       = astFree(OPD); }
    if(OPD_EVEN){ OPD_EVEN  = astFree(OPD_EVEN); }
    if(MIRPOS)  { MIRPOS    = astFree(MIRPOS); }
    if(ACC)     { gsl_interp_accel_free(ACC);   ACC     = NULL; }
    if(SPLINE)  { gsl_spline_free(SPLINE);      SPLINE  = NULL; }

    /* Close the file */
    smf_close_file(&inData, status);

    /* Create a 3D empty fpm array */
    fpm = smf_create_smfData(SMF__NOCREATE_DA | SMF__NOCREATE_FTS, status);
    fpm->dtype   = SMF__DOUBLE;
    fpm->ndims   = 3;
    fpm->dims[0] = 1;
    fpm->dims[1] = 1;
    fpm->dims[2] = 1;
    fpm->pntr[0] = (double*) astCalloc(1, sizeof(double));

    /* Create a 2D empty sigma array */
    sigma = smf_create_smfData(SMF__NOCREATE_DA | SMF__NOCREATE_FTS, status);
    sigma->dtype   = SMF__DOUBLE;
    sigma->ndims   = 2;
    sigma->dims[0] = 1;
    sigma->dims[1] = 1;
    sigma->pntr[0] = (double*) astCalloc(1, sizeof(double));

    /* Write to output */
    outData->fts = smf_construct_smfFts(NULL, zpd, fpm, sigma, status);
    smf_write_smfData(outData, NULL, NULL, gOut, fIndex, 0, MSG__VERB, 0, status);
    smf_close_file(&outData, status);
  }
  CLEANUP:
  /* Deallocate memory used by arrays */
  if(IFG)     { IFG       = astFree(IFG); }
  if(OPD)     { OPD       = astFree(OPD); }
  if(OPD_EVEN){ OPD_EVEN  = astFree(OPD_EVEN); }
  if(ACC)     { gsl_interp_accel_free(ACC);   ACC     = NULL; }
  if(SPLINE)  { gsl_spline_free(SPLINE);      SPLINE  = NULL; }
  if(inData)  { smf_close_file(&inData, status); }
  if(outData) { smf_close_file(&outData, status); }

  /* END NDF */
  ndfEnd(status);

  /* Delete groups */
  if(gIn)     { grpDelet(&gIn, status); }
  if(gOut)    { grpDelet(&gOut, status); }
  if(gZpd)    { grpDelet(&gZpd, status); }
}
