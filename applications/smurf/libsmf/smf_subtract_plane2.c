/*
*+
*  Name:
*     smf_subtract_plane2

*  Purpose:
*     Low-level sky fitting and removal routine which related files

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Subroutine

*  Invocation:
*     smf_subtract_plane2( smfArray *array, const char *fittype, int *status ) 

*  Arguments:
*     array = smfArray* (Given and Returned)
*        Pointer to input array of related data structs
*     fittype = char* (Given)
*        Fit-type for PLANE sky-removal method
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This routine performs the bulk sky removal task for the case
*     when the PLANE method is specified in smurf_remsky. Three
*     methods of removing the sky are offered: mean, slope and
*     plane. In the first method, the mean sky power is calculated and
*     subtracted from each data point. In the second method, a linear
*     gradient in the sky emission is calculated and subtracted. The
*     third method offers a full 2-D plane-fitting procedure to allow
*     for azimuthal variations as well.
*
*     The 1-D and 2-D fits require a transformation to the AzEl
*     coordinate system. This is done using the astTranGrid function
*     for speed since this transformation must be done at every time
*     step. The gradient is calculated using the GSL multifit method
*     and subtracted from the data values.

*  Notes: 
*     - There is a lot of duplicated code between this routine and
*       smf_correct_extinction as they both work in the AzEl coordinate
*       system
*     - See also smf_subtract_plane1.c

*  Authors:
*     Andy Gibb (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-09-18 (AGG):
*        Initial version, copied from the original version of
*        smf_subtract_plane
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006 University of British Columbia.
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

/* Standard includes */
#include <stdio.h>
#include <string.h>

/* GSL includes */
#include <gsl/gsl_multifit.h>

/* Starlink includes */
#include "sae_par.h"
#include "ast.h"
#include "mers.h"
#include "msg_par.h"
#include "prm_par.h"

/* SMURF includes */
#include "smf.h"
#include "smurf_par.h"
#include "smurf_typ.h"

/* Simple default string for errRep */
#define FUNC_NAME "smf_subtract_plane2"

void smf_subtract_plane2( smfArray *array, const char *fittype, int *status ) {

  /* Local variables */
  smfHead *hdr;            /* Pointer to full header struct */
  int i;                   /* Loop counter */
  int j;                   /* Loop counter */
  const char *origsystem = '\0';  /* Character string to store the coordinate
			      system on entry */
  AstFrameSet *wcs = NULL; /* Pointer to AST WCS frameset */
  double *indata = NULL;   /* Pointer to data array */
  dim_t index;             /* index into vectorized data array */
  dim_t k;                 /* Loop counter */
  size_t *indices = NULL;  /* Array of indices for data points within
			      a given smfData */

  size_t nframes = 0;      /* Number of frames/timeslices */
  int npts = 0;            /* Total Number of data points */
  size_t base;             /* Starting point for index into arrays */
  int z;                   /* Counter */
  double sky0 = 0;         /* Sky power fit - intercept */
  double dskyel;           /* Sky power fit - elev gradient */
  double dskyaz;           /* Sky power fit - azimuth gradient */
  double chisq;            /* Chi-squared from the linear regression fit */

  gsl_matrix *azelmatx = NULL; /* Matrix of input positions */
  gsl_vector *psky = NULL; /* Vector containing sky brightness */
  gsl_vector *weight = NULL; /* Weights for sky brightness vector */
  gsl_vector *skyfit = NULL; /* Solution vector */
  gsl_matrix *mcov = NULL;  /* Covariance matrix */
  gsl_multifit_linear_workspace *work = NULL; /* Workspace */
  size_t ncoeff = 2;       /* Number of coefficients to fit for; default straight line */

  size_t needast = 0;      /* Flag to specify if astrometry is needed for fit */
  size_t fitmean = 0;      /* Flag to specify if the fit type is mean */
  size_t fitslope = 0;     /* Flag to specify if the fit is a 1-D elev slope */
  size_t fitplane = 0;     /* Flag to specify if the fit is a 2-D plane */

  smfData *data = NULL;    /* Pointer to current smfData */
  int kk;
  int ndat;                /* Number of related data files in the smfArray */
  int nptsdat = 0;         /* Number of points per data file */

  double *azel = NULL;     /* Array of AzEl coordinates */
  int lbnd[2];             /* Lower bound */
  int ubnd[2];             /* Upper bound */
  int offset;              /* Offset into azelmatx array */
  int ioff;                /* Index into azelmatx array */

  /* Check status */
  if (*status != SAI__OK) return;

  /* Set some flags depending on desired FIT type */
  if ( strncmp( fittype, "MEAN", 4 ) == 0 ) {
    needast = 0;
    fitmean = 1;
    ncoeff = 1; /* Not needed :-) */
  } else if ( strncmp( fittype, "SLOP", 4 ) == 0 )  {
    needast = 1;
    fitslope = 1;
    ncoeff = 2;
  } else  if ( strncmp( fittype, "PLAN", 4 ) == 0 ) {
    needast = 1;
    fitplane = 1;
    ncoeff = 3;
  } else {
    *status = SAI__ERROR;
    msgSetc("F", fittype);
    errRep(FUNC_NAME, "Unknown FIT type, ^F: programming error?", status);
  }

  /* Tell user we're removing the sky */
  msgSetc("F", fittype);
  msgOutif(MSG__VERB," ", "Removing sky with method ^F", status);

  /* Calculate the total number of data points and the number of data
     files in the smfArray */
  ndat = 0;
  if ( *status == SAI__OK ) {
    for ( i=0; i<array->ndat; i++ ) {
      data = (array->sdata)[i];
      if ( data != NULL ) {
	/* If this has been run before just return to caller and allow
	   to continue to next set of related data files */
	if ( smf_history_check( data, FUNC_NAME, status) ) {
	  msgSetc("F", FUNC_NAME);
	  msgOutif(MSG__VERB," ", 
		    "^F has already been run on these data, returning to caller", 
		    status);
	  return;
	}
	nptsdat = (data->dims)[0] * (data->dims)[1];
	npts += nptsdat;
	nframes = (data->dims)[2];
	ndat++;
      }
    }
  }

  if ( fitmean ) {
    /* Loop over timeslice index */
    for ( k=0; k<nframes; k++) {
      sky0 = 0.0;
      /* Loop over smfDatas in smfArray */
      for ( kk=0; kk<ndat; kk++) {
	data = (array->sdata)[kk];
	/* Retrieve data array */
	indata = (data->pntr)[0];
	/* Offset into 3d data array */
	base = nptsdat * k; 
	/* Calculate sum of all pixels in current timeslice */
	for (i=0; i < nptsdat; i++ ) {
	  index = base + i;
	  if (indata[index] != VAL__BADD) {
	    sky0 += indata[index];
	  }
	}
      }
      /* Calculate mean sky level across all related data for this
	 timeslice */
      sky0 /= npts;
      /* Now to subtract fitted sky from data. Loop over the smfDatas in
	 the smfArray, select each one in turn and subtract sky */
      for ( kk=0; kk<ndat; kk++) {
	data = (array->sdata)[kk];
	indata = (data->pntr)[0];
	/* Subtract fit from timeslice */
	base = nptsdat * k; 
	for (i=0; i < nptsdat; i++ ) {
	  index = i + base;
	  if (indata[index] != VAL__BADD) {
	    /* Subtract sky value; no need to update variance */
	    indata[index] -= sky0;
	  }
	}
      }
      /* Debugging info */
      msgSeti("K",k+1);
      msgSetc("F",fittype);
      msgOutif(MSG__VERB," ", 
		" Fit results for timeslice ^K (fit type = ^F)", status );
      msgSetd("DS",sky0);
      msgOutif(MSG__VERB," ", 
		"              Sky0   = ^DS, ", status );
    }
  } else if ( needast ) {
    /* Everything in this block is done for data which must be placed
       on a common coordinate frame to carry out the appropriate
       fit */

    /* First, allocate space for the AzEl array */
    azel = smf_malloc( 2*npts, sizeof(double), 0, status );
    /* Bolometer indices */
    indices = smf_malloc( nptsdat, sizeof(size_t), 0, status );
    /* Free resources if status is bad after trying to allocate
       memory */
    if ( *status != SAI__OK ) goto CLEANUP;
   
    /* Calculate the indices into the data arrays. Note that this
       assumes that all of the related files have exactly the
       same-sized data arrays - but the input smfArray will only
       contain files for which this is true so this is a safe
       assumption. We also need access to the data by the time we get
       here - just grab the first one in the smfArray */
    data = (array->sdata)[0];
    z = 0;
    for (j = 0; j < (data->dims)[1]; j++) {
      base = j *(data->dims)[0];
      for (i = 0; i < (data->dims)[0]; i++) {
	indices[z] = base + i; /* Index into data array */
	z++;
      }
    }
    /* Array bounds for astTranGrid call */
    lbnd[0] = 1;
    lbnd[1] = 1;
    ubnd[0] = (data->dims)[0];
    ubnd[1] = (data->dims)[1];

    /* Allocate GSL workspace */
    work = gsl_multifit_linear_alloc( npts, ncoeff );
    azelmatx = gsl_matrix_alloc( npts, ncoeff );
    psky = gsl_vector_alloc( npts );
    weight = gsl_vector_alloc( npts );
    skyfit = gsl_vector_alloc( ncoeff );
    mcov = gsl_matrix_alloc( ncoeff, ncoeff );

    /* Loop over timeslice index */
    for ( k=0; k<nframes; k++) {
      /* Loop over smfDatas in smfArray */
      for ( kk=0; kk<ndat; kk++) {
	data = (array->sdata)[kk];
	/* Build WCS and set to AzEl */
	smf_tslice_ast( data, k, 1, status );
	hdr = data->hdr;
	wcs = hdr->wcs;
	origsystem = astGetC( wcs, "SYSTEM");
	if (wcs != NULL) {
	  astSetC( wcs, "SYSTEM", "AZEL" );
	} else {
	  if ( *status == SAI__OK ) {
	    *status = SAI__ERROR;
	    errRep( FUNC_NAME, 
		    "Plane removal method requires WCS but input is NULL", 
		    status);
	  }
	}
	/* Transform pixels to AzEl frame */
	astTranGrid( wcs, 2, lbnd, ubnd, 0.1, 1000000, 1, 2, nptsdat, azel );
	/* Retrieve data array */
	indata = (data->pntr)[0];
	/* Offset into 3d data array */
	base = nptsdat * k; 
	/* Offset into azelmatx array */
	offset = kk*nptsdat;
	/* Copy new AzEl elements into GSL arrays */
	for ( i=0; i<nptsdat; i++) {
	  index = indices[i] + base;
	  /* Calculate index into azelmatx array */
	  ioff = i + offset;
	  gsl_matrix_set( azelmatx, ioff, 0, 1.0 );
	  gsl_matrix_set( azelmatx, ioff, 1, azel[i+nptsdat] );
	  if ( fitplane ) {
	    gsl_matrix_set( azelmatx, ioff, 2, azel[i] );
	  }
	  gsl_vector_set( psky, ioff, indata[index] );
	  /* Set weights - currently only a switch if data
	     good/bad. Future versions should probably use the
	     variance. */
	  if (indata[index] != VAL__BADD) {
	    gsl_vector_set( weight, ioff, 1.0);
	  } else {
	    gsl_vector_set( weight, ioff, 0.0);
	  }
	}
      } /* End loop over smfDatas */

      /* Carry out fit */
      gsl_multifit_wlinear( azelmatx, weight, psky, skyfit, mcov, &chisq, work);

      /* Retrieve solution: first sky offset */
      sky0 = gsl_vector_get(skyfit, 0);
      /* Slope in El */
      dskyel = gsl_vector_get(skyfit, 1);
      if ( ncoeff == 3 ) {
	/* Slope in Az */
	dskyaz = gsl_vector_get(skyfit, 2);
      } else {
	dskyaz = 0.0;
      }

      /* Now to subtract fitted sky from data. Loop over the smfDatas in
	 the smfArray, select each one in turn and subtract sky */
      for ( kk=0; kk<ndat; kk++) {
	data = (array->sdata)[kk];
	indata = (data->pntr)[0];
	/* Subtract fit from timeslice */
	base = nptsdat * k; 
	for (i=0; i < nptsdat; i++ ) {
	  index = i + base;
	  if (indata[index] != VAL__BADD) {
	    /* Subtract sky value; no need to update variance */
	    indata[index] -= (sky0 + dskyel*azel[i+nptsdat] + dskyaz*azel[i]);
	  }
	}
	/* Reset coordinates to original system on entry */
	astSetC( wcs, "SYSTEM", origsystem );
      }
      /* Debugging info */
      msgSeti("K",k+1);
      msgSetc("F",fittype);
      msgOutif(MSG__VERB," ", 
		" Fit results for timeslice ^K (fit type = ^F)", status );
      msgSetd("DS",sky0);
      msgOutif(MSG__VERB," ", 
		"              Sky0   = ^DS, ", status );
      msgSetd("DE",dskyel);
      msgOutif(MSG__VERB," ", 
		"              Dskyel = ^DE, ", status );
      if ( dskyaz != 0 ) {
	msgSetd("DA",dskyaz);
	msgOutif(MSG__VERB," ", 
		  "              Dskyaz = ^DA", status );
      }
      msgSetd("X",chisq);
      msgOutif(MSG__VERB," ", 
		"              X^2 = ^X", status );
      
    } /* End of loop over timeslice frame */

    /* Free up GSL workspace */
    gsl_multifit_linear_free( work );
    gsl_matrix_free( azelmatx );
    gsl_vector_free( psky );
    gsl_vector_free( weight );
    gsl_vector_free( skyfit );
    gsl_matrix_free( mcov );

  CLEANUP:
    if ( needast ) {
      smf_free(azel, status);
    }
    smf_free(indices, status);
  }

  /* Write history entry if we finish with good status. */
  for ( kk=0; kk<ndat; kk++) {
    data = (array->sdata)[kk];
    smf_history_add( data, FUNC_NAME, 
		     "Plane sky subtraction successful", status);
  }
}
