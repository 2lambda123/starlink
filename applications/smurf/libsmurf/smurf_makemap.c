/*
*+
*  Name:
*     smurf_makemap

*  Purpose:
*     Top-level MAKEMAP implementation

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_makemap( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is the main routine implementing the MAKEMAP task.

*  ADAM Parameters:
*     IN = NDF (Read)
*          Input file(s)
*     PIXSIZE = REAL (Read)
*          Pixel size in output image, in arcsec
*     OUT = NDF (Write)
*          Output file

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     Andy Gibb (UBC)
*     Edward Chapin (UBC)
*     David Berry (JAC, UCLan)
*     {enter_new_authors_here}

*  History:
*     2005-09-27 (EC):
*        Clone from smurf_extinction
*     2005-12-16 (EC):
*        Working for simple test case with astRebinSeq 
*     2006-01-04 (EC):
*        Properly setting rebinflags
*     2006-01-13 (EC):
*        Automatically determine map size
*        Use VAL__BADD for pixels with no data in output map
*     2006-01-25 (TIMJ):
*        Replace malloc with smf_malloc.
*     2006-01-25 (TIMJ):
*        sc2head is now embedded in smfHead.
*     2006-01-27 (TIMJ):
*        - Try to jump out of loop if status bad.
*        - sc2head is now a pointer again
*     2006-02-02 (EC):
*        - Broke up mapbounds/regridding into subroutines smf_mapbounds and
*          smf_rebinmap
*        - fits header written to output using ndfputwcs
*     2006-03-23 (AGG):
*        Update to take account of new API for rebinmap
*     2006-03-23 (DSB):
*        Guard against null pointer when reporting error.
*     2006-04-21 (AGG):
*        Now calls sky removal and extinction correction routines.
*     2006-05-24 (AGG):
*        Check that the weights array pointer is not NULL
*     2006-05-25 (EC):
*        Add iterative map-maker + associated command line parameters
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research
*     Council and the University of British Columbia. All Rights
*     Reserved.

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
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place,Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include <stdio.h>

/* STARLINK includes */
#include "ast.h"
#include "mers.h"
#include "par.h"
#include "par_par.h"
#include "prm_par.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/hds.h"
#include "star/ndg.h"
#include "star/grp.h"

/* SMURF includes */
#include "smurf_par.h"
#include "smurflib.h"
#include "libsmf/smf.h"

#include "sc2da/sc2store_par.h"
#include "sc2da/sc2store_struct.h"
#include "sc2da/sc2math.h"
#include "sc2da/sc2store.h"
#include "sc2da/sc2ast.h"

#define FUNC_NAME "smurf_makemap"
#define TASK_NAME "MAKEMAP"
#define LEN__METHOD 20

void smurf_makemap( int *status ) {

  /* Local Variables */
  Grp *astgrp = GRP__NOID;   /* Group of astronomical signal files */
  Grp *atmgrp = GRP__NOID;   /* Group of atmospheric signal files */
  void *data_index[1];       /* Array of pointers to mapped arrays in ndf */
  smfData *data=NULL;        /* pointer to  SCUBA2 data struct */
  int flag;                  /* Flag */
  dim_t i;                   /* Loop counter */
  Grp *igrp = GRP__NOID;     /* Group of input files */
  int lbnd_out[2];           /* Lower pixel bounds for output map */
  void *map=NULL;            /* Pointer to the rebinned map data */
  char method[LEN__METHOD];  /* String for map-making method */
  int n;                     /* # elements in the output map */
  Grp *ngrp = NULL;          /* Group of noise signal files */
  int ondf;                  /* output NDF identifier */
  AstFrameSet *outfset=NULL; /* Frameset containing sky->output mapping */
  float pixsize=3;           /* Size of an output map pixel in arcsec */
  int size;                  /* Number of files in input group */
  int ubnd_out[2];           /* Upper pixel bounds for output map */
  void *variance=NULL;       /* Pointer to the variance map */
  void *weights=NULL;        /* Pointer to the weights map */

  /* Test variables */
  int coordndf=NDF__NOID;      /* NDF identifier for coordinates */
  dim_t j;                     /* Loop counter */
  int *lut;                    /* The lookup table */
  int nmap;                    /* Number of mapped elements */
  int place=NDF__NOPL;         /* NDF place holder */
  int there;
  double *bolodata;
  int parstate;              /* State of ADAM parameters */

  /* Main routine */
  ndfBegin();
  
  /* Get group of input files */
  ndgAssoc( "IN", 1, &igrp, &size, &flag, status );

  /* Create groups containing model components if defined */
  parState( "ASTMODEL", &parstate, status );
  if( parstate == PAR__ACTIVE ) {
    ndgCreat( "ASTMODEL", igrp, &astgrp, &size, &flag, status );
  }

  parState( "ATMMODEL", &parstate, status );
  if( parstate == PAR__ACTIVE ) {
    ndgCreat( "ATMMODEL", igrp, &atmgrp, &size, &flag, status );
  }

  parState( "NOISEMODEL", &parstate, status );
  if( parstate == PAR__ACTIVE ) {
    ndgCreat( "NOISEMODEL", igrp, &ngrp, &size, &flag, status );
  }

  /* Get the user defined pixel size */
  parGet0r( "PIXSIZE", &pixsize, status );
  if( pixsize <= 0 ) {
    msgSetr("PIXSIZE", pixsize);
    *status = SAI__ERROR;
    errRep(FUNC_NAME, 
	   "Pixel size ^PIXSIZE is < 0.", status);
  }

  /* Get METHOD */
  parChoic( "METHOD", "REBIN", 
	    "REBIN, ITERATE.", 1,
	    method, LEN__METHOD, status);
  
  /* Calculate the map bounds */
  msgOutif(MSG__VERB, " ", "SMURF_MAKEMAP: Determine map bounds", status);
  smf_mapbounds( igrp, size, "icrs", 0, 0, 1, pixsize, lbnd_out, ubnd_out, 
		 &outfset, status );
  if (*status != SAI__OK) {
    errRep(FUNC_NAME, "Unable to determine map bounds", status);
  }

  /* Create the output NDF for the image and map arrays */
  ndfCreat( "OUT", "_DOUBLE", 2, lbnd_out, ubnd_out, &ondf, status );
  ndfMap( ondf, "DATA", "_DOUBLE", "WRITE", data_index, &n, status);
  map = data_index[0];
  ndfMap( ondf, "VARIANCE", "_DOUBLE", "WRITE", data_index, &n, status);
  variance = data_index[0];

  /* Allocate memory for weights and initialise to zero */
  weights = smf_malloc( (ubnd_out[0]-lbnd_out[0]+1) *
			(ubnd_out[1]-lbnd_out[1]+1), sizeof(double),
			1, status );
  if ( weights == NULL ) {
    *status = SAI__ERROR;
    errRep(FUNC_NAME, "Unable to allocate memory for the weights array", status);
  }

  /* Create the map using the chosen METHOD */
  if( strncmp( method, "REBIN", 5 ) == 0 ) {
    /* Simple Regrid of the data */
    msgOutif(MSG__VERB, " ", "SMURF_MAKEMAP: Make map using REBIN method", 
	     status);

    for(i=1; i<=size; i++ ) {
      /* Read data from the ith input file in the group */      
      smf_open_and_flatfield( igrp, NULL, i, &data, status );
      
      /* Remove sky - assume MEAN is good enough for now */
      smf_subtract_plane(data, "MEAN", status);

      /* Use raw WVM data to make the extinction correction */
      smf_correct_extinction(data, "WVMR", 0, 0, status);
      
      /* Check that the data dimensions are 3 (for time ordered data) */
      if( *status == SAI__OK ) {
	if( data->ndims != 3 ) {
	  msgSeti("I",i);
	  msgSeti("THEDIMS", data->ndims);
	  *status = SAI__ERROR;
	  errRep(FUNC_NAME, 
		 "File ^I data has ^THEDIMS dimensions, should be 3.", 
		 status);
	}
      }
      
      /* Check that the input data type is double precision */
      if( *status == SAI__OK ) 
	if( data->dtype != SMF__DOUBLE) {
	  msgSeti("I",i);
	  msgSetc("DTYPE", smf_dtype_string( data, status ));
	  *status = SAI__ERROR;
	  errRep(FUNC_NAME, 
		 "File ^I has ^DTYPE data type, should be DOUBLE.",
		 status);
	}
      
      /* Rebin the data onto the output grid */
      smf_rebinmap(data, i, size, outfset, lbnd_out, ubnd_out, 
		   map, variance, weights, status );
      
      /* Close the data file */
      if( data != NULL ) {
	smf_close_file( &data, status);
	data = NULL;
      }
      
      /* Break out of loop over data files if bad status */
      if (*status != SAI__OK) {
	errRep(FUNC_NAME, "Rebinning step failed", status);
	break;
      }
    }
  } else if( strncmp( method, "ITERATE", 5 ) == 0 ) {
    /* Iterative map-maker */
    msgOutif(MSG__VERB, " ", "SMURF_MAKEMAP: Make map using ITERATE method", 
	     status);
    
    /* Check the groups corresponding to each model component */

    /* Loop over all input data files to put in the pointing extension */
    if( *status == SAI__OK ) {
      for(i=1; i<=size; i++ ) {
	smf_open_file( igrp, i, "UPDATE", 1, &data, status );
	smf_mapcoord( data, outfset, lbnd_out, ubnd_out, status );
	smf_close_file( &data, status );
      }
    }

    /* Call the low-level iterative map-maker */
    smf_iteratemap( igrp, astgrp, atmgrp, ngrp, size, map, variance, weights,
		    (ubnd_out[0]-lbnd_out[0]+1)*(ubnd_out[1]-lbnd_out[1]+1),
		    status );

  }

  /* Write FITS header */
  ndfPtwcs( outfset, ondf, status );
  
  if( outfset != NULL ) {
    astAnnul( outfset );
    outfset = NULL;
  }
  
  ndfUnmap( ondf, "DATA", status);
  ndfUnmap( ondf, "VARIANCE", status);
  ndfAnnul( &ondf, status );

  smf_free( weights, status );
  
  if( igrp != GRP__NOID ) grpDelet( &igrp, status);
  if( astgrp != GRP__NOID ) grpDelet( &astgrp, status );
  if( atmgrp != GRP__NOID ) grpDelet( &atmgrp, status );
  if( ngrp != GRP__NOID ) grpDelet( &ngrp, status );
  
  ndfEnd( status );
  
  msgOutif(MSG__VERB," ","Map written.", status);
}
