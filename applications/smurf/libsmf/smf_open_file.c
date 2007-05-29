/*
*+
*  Name:
*     smf_open_file

*  Purpose:
*     Low-level file access function

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     Library routine

*  Invocation:
*     smf_open_file( Grp * ingrp, int index, char * mode, int withHdr,
*                    smfData ** data, int *status);

*  Arguments:
*     ingrp = const Grp * (Given)
*        NDG group identifier
*     index = int (Given)
*        Index corresponding to required file in group
*     mode = char * (Given)
*        File access mode
*     withHdr = int (Given)
*        If true, populate the smfHead component. Otherwise leave null.
*        Mainly required to work around sc2store problems.
*     data = smfData ** (Returned)
*        Pointer to pointer smfData struct to be filled with file info and data
*        Should be freed using smf_close_file.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is the main routine to open data files. The routine finds
*     the filename from the input Grp and index, and opens the
*     file. The smfData struct is populated, along with the associated
*     smfFile, smfHead and smfDA & smfDream (if necessary). The
*     history is read and stored for future reference.

*  Notes:
*     - If a file has no FITS header then a warning is issued
*     - JCMTState is NULL for non-time series data

*  Authors:
*     Andy Gibb (UBC)
*     Tim Jenness (JAC, Hawaii)
*     Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2005-11-03 (AGG):
*        Initial test version
*     2005-11-07 (TIMJ):
*        Need to cache locator to FRAMEDATA
*     2005-11-23 (TIMJ):
*        Use HDSLoc for locator
*     2005-11-28 (TIMJ):
*        Malloc sc2head
*     2005-12-01 (EC):
*        Fixed up error determining data types
*     2005-12-05 (TIMJ):
*        Store isTstream flag for smf_close_file
*     2005-12-05 (AGG):
*        Add status check on retrieving FITS hdr
*     2005-12-14 (TIMJ):
*        Now sets a reference counter
*     2006-01-26 (TIMJ):
*        Use smf_create_smfData
*        Use smf_dtype_fromstring
*     2006-01-27 (TIMJ):
*        - Open raw data read only
*        - Read in full time series headers into smfHead during sc2store
*        - Copy flatfield information into struct and close raw file
*        - read all time series headers into struct even when not sc2store
*        - No longer need to store xloc locator
*     2006-02-17 (AGG):
*        Add reading of SCANFIT coefficients
*     2006-03-03 (AGG):
*        Return a NULL pointer if the group is undefined
*     2006-03-23 (AGG);
*        Store the number of frames (timeslices) in the smfData struct
*     2006-03-24 (TIMJ):
*        Fix bug where allsc2heads wasn't being set
*     2006-04-21 (AGG):
*        Add history read
*     2006-05-16 (AGG):
*        Change msgOut to msgOutif
*     2006-05-19 (EC):
*        Map Q&V if not present before when mode is WRITE
*     2006-05-24 (AGG):
*        Add status check in case SCANFIT extension doesn't exist
*     2006-06-08 (AGG):
*        Set correct data type for QUALITY to fix HDS error
*     2006-06-12 (EC):
*        NULL pointers associated with .SMURF.MAPCOORD extension
*     2006-06-30 (EC):
*        Now NULL pointers in smf_create_smf*, changed to .SCU2RED.MAPCOORD
*     2006-07-26 (TIMJ):
*        sc2head no longer used. Use JCMTState instead.
*     2006-07-28 (TIMJ):
*        Use new API for sc2store_headrmap. Read cube WCS into tswcs.
*     2006-07-31 (TIMJ):
*        Use SC2STORE__MAXFITS.
*        Calculate "instrument".
*    2006-08-24 (AGG):
*        Read and store DREAM parameters (from RAW data only at present)
*     2006-09-05 (JB):
*        Check to make sure file exists
*     2006-09-05 (EC):
*        Call aztec_fill_smfHead, smf_telpos_get
*     2006-09-07 (EC):
*        Added code to isNDF=0 case to handle compressed AzTEC data
*     2006-09-15 (AGG):
*        Insert code for opening and storing DREAM parameters
*     2006-09-21 (AGG):
*        Check that we have a DREAM extension before attempting to access it
*     2006-09-21 (AGG):
*        Move the instrument-specific stuff until after hdr->nframes has
*        been assigned (nframes is needed by acs_fill_smfHead).
*     2006-12-20 (TIMJ):
*        Clean up some error handling.
*     2007-02-07 (EC):
*        - renamed isNDF to isFlat to be less confusing
*        - only issue a warning if data not 2d or 3d to handle iterative
*          map-maker model containers.
*     2007-03028 (TIMJ):
*        - Annul SCU2RED locator even if SCANFIT is not present
*        - Noting Ed's comment that isFlat is less confusing, I disagree
*          because isNDF applied to non-SCUBA2 data
*     2007-05-29 (AGG):
*        Check if data type is _REAL and map as _DOUBLE
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
*     University of British Columbia.
*     All Rights Reserved.

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
#include <stdlib.h>
#include <stdio.h>

/* Starlink includes */
#include "sae_par.h"
#include "star/ndg.h"
#include "ndf.h"
#include "ast.h"
#include "smf.h"
#include "smf_typ.h"
#include "smf_err.h"
#include "mers.h"
#include "star/kaplibs.h"
#include "kpg_err.h"

/* SC2DA includes */
#include "sc2da/sc2store.h"
#include "sc2da/sc2ast.h"

/* SMURF includes */
#include "libacsis/acsis.h"
#include "libaztec/aztec.h"

#define FUNC_NAME "smf_open_file"

void smf_open_file( Grp * igrp, int index, char * mode, int withHdr,
		    smfData ** data, int *status) {

  char dtype[NDF__SZTYP+1];  /* String for DATA type */
  int indf;                  /* NDF identified for input file */
  int ndfdims[NDF__MXDIM];   /* Array containing size of each axis of array */
  int ndims;                 /* Number of dimensions in data */
  int qexists;               /* Boolean for presence of QUALITY component */
  int vexists;               /* Boolean for presence of VARIANCE component */
  int itexists;              /* Boolean for presence of other components */
  char filename[GRP__SZNAM+1]; /* Input filename, derived from GRP */
  char *pname;               /* Pointer to input filename */
  void *outdata[] = { NULL, NULL, NULL }; /* Array of pointers to
					     output data components:
					     one each for DATA,
					     QUALITY and VARIANCE */
  int isFlat = 1;            /* Flag to indicate if file flatfielded */
  int isTseries = 0;         /* Flag to specify whether the data are
				in time series format */
  int itype = SMF__NULL;     /* Data type for DATA (and VARIANCE) array(s) */
  int i;                     /* Loop counter */
  int nout;                  /* Number of output pixels */
  int *tdata;                /* Pointer to raw time series data (DATA cpt) */

  smfFile *file = NULL;      /* pointer to smfFile struct */
  smfHead *hdr = NULL;       /* pointer to smfHead struct */
  smfDA *da = NULL;          /* pointer to smfDA struct, initialize to NULL */

  HDSLoc *xloc = NULL;       /* Locator to time series headers,
				SCANFIT coeffs and DREAM parameters*/

  /* Flatfield parameters */
  double * flatcal = NULL;
  double * flatpar = NULL;
  int * dksquid = NULL;
  JCMTState *tmpState = NULL;

  /* DREAM parameters */
  int *jigvert = NULL;       /* Pointer to jiggle vertices in DREAM pattern */
  double *jigpath = NULL;    /* Pointer to jiggle path */
  smfDream *dream = NULL;    /* Pointer to DREAM parameters */
  int nsampcycle;            /* Number of positions in jiggle path */
  int nvert;                 /* Number of vertices in DREAM pattern */
  int jigvndf;               /* NDF identifier for jiggle vertices */
  int jigpndf;               /* NDF identifier for SMU path */
  smfData *jigvdata = NULL;  /* Jiggle vertex data */
  smfData *jigpdata = NULL;  /* SMU path data */

  /* Pasted from readsc2ndf */
  int colsize;               /* number of pixels in column */
  char headrec[SC2STORE__MAXFITS][81];      /* FITS headers read from sc2store */
  int maxlen = 81;           /* maximum length of a FITS header */
  int nfits;                 /* number of FITS headers */
  int nframes;               /* number of frames */
  int rowsize;               /* number of pixels in row (returned) */
  char *phead = NULL;        /* Pointer to FITS headers */
  int flags = 0;             /* Flags for smf_create_smfData */

  int gndf;                  /* General purpose NDF identifier (SCU2RED & DREAM) */
  int place;                 /* NDF placeholder for SCANFIT extension */
  int npoly;                 /* Number points in polynomial coeff array */
  double *poly;              /* Pointer to array of polynomial coefficients */
  double *opoly;             /* Pointer to store in output struct */
  int npdims;                /* Number of dimensions in the polynomial array */
  int pdims[NDF__MXDIM];     /* Size of each dimension */

  if ( *status != SAI__OK ) return;

  /* Return a null pointer to the smfData if the input grp is null */
  if ( igrp == NULL ) {
    *data = NULL;
    return;
  }

  /* Get filename from the group */
  pname = filename;
  grpGet( igrp, index, 1, &pname, SMF_PATH_MAX, status);

  /* Return the NDF identifier */
  if (*status == SAI__OK) {
    ndgNdfas( igrp, index, mode, &indf, status );
    if ( indf == NDF__NOID ) {
      if (*status == SAI__OK) *status = SAI__ERROR;
      msgSetc( "FILE", filename );
      errRep(FUNC_NAME, "Could not locate file ^FILE", status);
      return;
    }
  }

  /* Determine the dimensions of the DATA component */
  ndfDim( indf, NDF__MXDIM, ndfdims, &ndims, status );

  /* Check type of DATA and VARIANCE arrays (they should both be the same!) */
  ndfType( indf, "DATA,VARIANCE", dtype, NDF__SZTYP+1, status);

  /* Check dimensionality: 2D is a .In image, 3D is a time series */
  if (ndims == 2) {
    if (strncmp(dtype, "_REAL", 5) == 0) {
      /* Change _REAL to _DOUBLE */
      msgOutif( MSG__VERB, "", 
		"Input file is _REAL, will map as _DOUBLE for internal handling", 
		status );
      strncpy( dtype, "_DOUBLE", NDF__SZTYP+1 );
    }
    isFlat = 1;    /* Data have been flat-fielded */
    isTseries = 0; /* Data are not in time series format */
  } else if (ndims == 3) { /* Time series data */
    /* Check if raw timeseries */
    if (strncmp(dtype, "_UWORD", 6) == 0) {
      isFlat = 0;  /* Data have not been flatfielded */
    } else {
      /* Note that the data should be of type _DOUBLE here */
      isFlat = 1;  /* Data have been flatfielded */
    }
    isTseries = 1; /* Data are in time series format */
  } else {
    /* Report a warning due to non-standard dimensions for file */
    if ( *status == SAI__OK) {

      msgSeti( "NDIMS", ndims);

      /*
      *status = SAI__ERROR;
      errRep( FUNC_NAME, 
      "Number of dimensions in output, ^NDIMS, is not equal to 2 or 3",
      status);
      */
      
      msgOutif(MSG__VERB," ", 
	       "Number of dimensions in output, ^NDIMS is not equal to 2 or 3",
	       status);

      /* Data is neither flat-fielded nor standard time-series data. However
         in this context "flat" data is really just data that doesn't
         need to be de-compressed using the sc2store library, so we set 
         isFlat to true */
      isTseries = 0;
      isFlat = 1;

    }
  }

  /* Now we need to create some structures */
  if (!withHdr) flags |= SMF__NOCREATE_HEAD;
  if (isFlat)   flags |= SMF__NOCREATE_DA;

  /* Allocate memory for the smfData */
  *data = smf_create_smfData( flags, status );

  /* If all's well, proceed */
  if ( *status == SAI__OK) {
    file = (*data)->file;
    hdr = (*data)->hdr;

    /* If we have timeseries data then look for and read polynomial
       scan fit coefficients */
    if ( isTseries ) {
      ndfXstat( indf, "SCU2RED", &itexists, status );
      if ( itexists) {
	ndfXloc( indf, "SCU2RED", "READ", &xloc, status );
	if ( xloc == NULL ) {
	  if ( *status == SAI__OK) {
	    *status = SAI__ERROR;
	    errRep(FUNC_NAME, "Unable to obtain an HDS locator to the SCU2RED extension, despite its existence", status);
	  }
	}
	ndfOpen( xloc, "SCANFIT", "READ", "OLD", &gndf, &place, status );
	/* Check status here in case not able to open NDF */
	if ( *status == SAI__OK ) {
	  if ( gndf == NDF__NOID ) {
	    *status = SAI__ERROR;
	    errRep(FUNC_NAME, "Unable to obtain an NDF identifier for the SCANFIT coefficients", status);
	  }

	  /* Read and store the polynomial coefficients */
	  ndfMap( gndf, "DATA", "_DOUBLE", "READ", &poly, &npoly, status );
	  ndfDim( gndf, NDF__MXDIM, pdims, &npdims, status );
	  (*data)->ncoeff = pdims[2];
	  /* Allocate memory for poly coeffs & copy over */
	  opoly = smf_malloc( npoly, sizeof( double ), 0, status);
	  memcpy( opoly, poly, npoly*sizeof( double ) );
	  (*data)->poly = opoly;

	  /* Release these resources immediately as they're not needed */
	  ndfAnnul( &gndf, status );
	} else {
	  errAnnul(status);
	  msgOutif(MSG__VERB," ", 
		   "SCU2RED exists, but not SCANFIT: we probably have STARE or DREAM data", status);
	}
	/* Annul the locator */
	datAnnul( &xloc, status );

      } else {
	msgOutif(MSG__VERB," ", 
		 "File has no SCU2RED extension. ", status);
      }
    }

    if (isFlat) {

      ndfState( indf, "QUALITY", &qexists, status);
      ndfState( indf, "VARIANCE", &vexists, status);

      /* Map each component as necessary */
      ndfMap( indf, "DATA", dtype, mode, &outdata[0], &nout, status );
      if (qexists) {
	ndfMap( indf, "QUALITY", "_UBYTE", mode, &outdata[2], &nout, status );
      }
      if (vexists) {
	ndfMap( indf, "VARIANCE", dtype, mode, &outdata[1], &nout, status );
      }

      if (withHdr) {

	/* Read the FITS headers */
	kpgGtfts( indf, &(hdr->fitshdr), status );
	/* Just continue if there are no FITS headers */
	if ( *status == KPG__NOFTS ) {
	  errRep(FUNC_NAME, "File has no FITS header - continuing but this may cause problems later", status );
	  errAnnul( status );
	}

	/* Determine and store the telescope location in hdr->telpos */
	smf_telpos_get( hdr, status );

	/* Store the INSTAP values */
	smf_instap_get( hdr, status );

	/* If not time series, then we can retrieve the stored WCS
	   info. Note that the JCMTState parameter is filled ONLY for
	   time series data */
	if ( !isTseries ) {
	  ndfGtwcs( indf, &(hdr->wcs), status);
	  hdr->nframes = 1;
	} else {
	  /* Get the time series WCS */
	  ndfGtwcs( indf, &(hdr->tswcs), status );

	  /* Need to get the location of the extension for STATE parsing */
	  ndfXloc( indf, JCMT__EXTNAME, "READ", &xloc, status );
	  /* And need to map the header making sure we have the right components
	     for this instrument. */
	  sc2store_headrmap( xloc, ndfdims[2], hdr->instrument, status );

	  /* Malloc some memory to hold all the time series data */
	  hdr->allState = smf_malloc( ndfdims[2], sizeof(JCMTState),
					 1, status );

	  /* Loop over each element, reading in the information */
	  tmpState = hdr->allState;
	  for (i=0; i<ndfdims[2]; i++) {
	    sc2store_headget(i, &(tmpState[i]), status);
	  }
	  hdr->nframes = ndfdims[2];
	  /* Unmap the headers */
	  sc2store_headunmap( status );

	  /* Annul the locator */
	  datAnnul( &xloc, status );
	}

	/* Determine the instrument */
	hdr->instrument = smf_inst_get( hdr, status );

	/* On the basis of the instrument, we know need to fill in some
	   additional header parameters. Some of these may be constants,
	   whereas others may involve more file access. Currently we use
	   a simple switch statement. We could modify this step to use
	   vtables of function pointers.
	*/
	switch ( hdr->instrument ) {
	case INST__ACSIS:
	  acs_fill_smfHead( hdr, indf, status );
	  break;
	case INST__AZTEC:
	  aztec_fill_smfHead( hdr, NDF__NOID, status );
	  break;
	default:
	  break;
	  /* SCUBA-2 has nothing special here because the focal plane
	     coordinates are derived using an AST polyMap */
	}

      }
      /* Establish the data type */
      itype = smf_dtype_fromstring( dtype, status );

      /* Store NDF identifier and set isSc2store to false */
      if (*status == SAI__OK) {
	file->ndfid = indf;
	file->isSc2store = 0;
	file->isTstream = isTseries;
      }
    } else {
      /* OK, we have raw data. Close the NDF because
	 sc2store_rdtstream will open it again */
      ndfAnnul( &indf, status );

      /* Read time series data from file */
      da = (*data)->da;
      if (*status == SAI__OK && da == NULL) {
	*status = SAI__ERROR;
	errRep(FUNC_NAME, "Internal programming error. Status good but no DA struct allocated", status);
      }

      /* decide if we are storing header information */
      tmpState = NULL;

      /* Read time series data from file */
      sc2store_rdtstream( pname, "READ", SC2STORE_FLATLEN, maxlen,
			  SC2STORE__MAXFITS, 
			  &nfits, headrec, &colsize, &rowsize, 
			  &nframes, &(da->nflat), da->flatname,
			  &tmpState, &tdata, &dksquid, 
			  &flatcal, &flatpar, &jigvert, &nvert, &jigpath, 
			  &nsampcycle, status);

      if (*status == SAI__OK) {
	/* Free header info if no longer needed */
	if (!withHdr && tmpState != NULL) {
	  /* can not use smf_free */
	  free( tmpState );
	  tmpState = NULL;
	} else {
	  hdr->allState = tmpState;
	}

	/* Tdata is malloced by rdtstream for our use */
	outdata[0] = tdata;
	phead = &(headrec[0][0]);

	/* Malloc local copies of the flatfield information.
	   This allows us to close the file immediately so that
	   we do not need to worry about sc2store only allowing
	   a single file at a time */
	da->flatcal = smf_malloc( colsize * rowsize * da->nflat, 
				  sizeof(double), 0, status );
	da->flatpar = smf_malloc( da->nflat, sizeof(double), 0, status );

	/* Now copy across from the mapped version */
	if (da->flatcal != NULL) memcpy(da->flatcal, flatcal,
					sizeof(double)*colsize*
					rowsize* da->nflat);
	if (da->flatpar != NULL) memcpy(da->flatpar, flatpar,
					sizeof(double)* da->nflat);

	/* Create a FitsChan from the FITS headers */
	if (withHdr) {
	  smf_fits_crchan( nfits, phead, &(hdr->fitshdr), status); 

	  /* Instrument must be SCUBA-2 */
	  /* hdr->instrument = INST__SCUBA2; */

	  /* ---------------------------------------------------------------*/
	  /* WARNING: This has been duplicated from the "isFlat" case to
	     accomodate AzTEC data that was written using sc2sim_ndfwrdata.
	     In principle AzTEC data should not be compressed, in which case
	     the above assertion "Instrument must be SCUBA-2" would be 
	     correct, and the following code is unnecessary. */

	  /* Determine and store the telescope location in hdr->telpos */
	  smf_telpos_get( hdr, status );

   	  /* Store the INSTAP values */
	  smf_instap_get( hdr, status );

	  /* Determine the instrument */
	  hdr->instrument = smf_inst_get( hdr, status );
	  
	  /* On the basis of the instrument, we know need to fill in some
	     additional header parameters. Some of these may be constants,
	     whereas others may involve more file access. Currently we use
	     a simple switch statement. We could modify this step to use
	     vtables of function pointers.
	  */
	  switch ( hdr->instrument ) {
	  case INST__ACSIS:
	    acs_fill_smfHead( hdr, indf, status );
	    break;
	  case INST__AZTEC:
	    aztec_fill_smfHead( hdr, NDF__NOID, status );
	    break;
	  default:
	    break;
	    /* SCUBA-2 has nothing special here because the focal plane
	       coordinates are derived using an AST polyMap */
	  }

	  /* ---------------------------------------------------------------*/
	}

	/* Raw data type is integer */
	itype = SMF__INTEGER;

	/* Verify that ndfdims matches row, col, nframes */
	/* Should probably inform user of the filename too */
	if (ndfdims[0] != colsize) {
	  msgSeti( "NC", colsize);
	  msgSeti( "DIMS", ndfdims[0]);
	  *status = SAI__ERROR;
	  errRep( "smf_open_file", "Number of input columns not equal to the number of output columns (^NC != ^DIMS)",status);
	}
	if (ndfdims[1] != rowsize) {
	  msgSeti( "NR", rowsize);
	  msgSeti( "DIMS", ndfdims[1]);
	  *status = SAI__ERROR;
	  errRep( "smf_open_file", "Number of input rows not equal to the number of output rows (^NR != ^DIMS)",status);
	}
	if (ndfdims[2] != nframes) {
	  msgSeti( "NF", nframes);
	  msgSeti( "DIMS", ndfdims[2]);
	  *status = SAI__ERROR;
	  errRep( "smf_open_file", "Number of input timeslices not equal to the number of output timeslices (^NF != ^DIMS)",status);
	} else {
	  hdr->nframes = nframes;
	}

	/* Set flag to indicate data read by sc2store_() */
	file->isSc2store = 1;

	/* and it is a time series */
	file->isTstream = 1;

	/* Store DREAM parameters */
	dream = smf_construct_smfDream( *data, nvert, nsampcycle, jigvert, jigpath, 
					status );
	(*data)->dream = dream;
      }

      /* Close the file */
      sc2store_free( status );

    }
    /* Store info in smfData struct */
    if (*status == SAI__OK) {
      (*data)->dtype = itype;
      strncpy(file->name, pname, SMF_PATH_MAX);

      /* Store the data in the smfData struct */
      for (i=0; i<3; i++) {
	((*data)->pntr)[i] = outdata[i];
      }
      /* Store the dimensions and the size of each axis */
      (*data)->ndims = ndims;
      for (i=0; i<ndims; i++) {
	((*data)->dims)[i] = (dim_t)ndfdims[i];
      }
    }
    /* Store DREAM parameters for flatfielded data if they exist. This
       has to be done here as these methods rely on information in the
       main smfData struct. First retrieve jigvert and jigpath from
       file */ 
    if ( isTseries && isFlat ) {
      /* Obtain locator to DREAM extension if we have DREAM data */
      xloc = smf_get_xloc( *data, "DREAM", "DREAM_PAR", "READ", 0, 0, status );
      /* If it's NULL then we don't have dream data */
      if ( xloc != NULL ) {
	jigvndf = smf_get_ndfid( xloc, "JIGVERT", "READ", "OLD", "", 0, NULL, 
				 NULL, status);
	if ( jigvndf == NDF__NOID) {
	  if (*status == SAI__OK ) {
	    *status = SAI__ERROR;
	    errRep(FUNC_NAME, "Unable to obtain NDF ID for JIGVERT", status);
	  }
	} else {
	  smf_open_ndf( jigvndf, "READ", filename, SMF__INTEGER, &jigvdata, status);
	}
	jigpndf = smf_get_ndfid( xloc, "JIGPATH", "READ", "OLD", "", 0, NULL, 
				 NULL, status);
	if ( jigpndf == NDF__NOID) {
	  if (*status == SAI__OK ) {
	    *status = SAI__ERROR;
	    errRep(FUNC_NAME, "Unable to obtain NDF ID for JIGPATH", status);
	  }
	} else {
	  smf_open_ndf( jigpndf, "READ", filename, SMF__DOUBLE, &jigpdata, status);
	}
	if ( jigvdata != NULL ) {
	  jigvert = (jigvdata->pntr)[0];
	  nvert = (int)(jigvdata->dims)[0];
	} else {
	  if (*status == SAI__OK ) {
	    *status = SAI__ERROR;
	    errRep(FUNC_NAME, "smfData for jiggle vertices is NULL", status);
	  }
	}
	if ( jigpdata != NULL ) {
	  jigpath = (jigpdata->pntr)[0];
	  nsampcycle = (int)(jigpdata->dims)[0];
	} else {
	  if (*status == SAI__OK ) {
	    *status = SAI__ERROR;
	    errRep(FUNC_NAME, "smfData for SMU path is NULL", status);
	  }
	}
	dream = smf_construct_smfDream( *data, nvert, nsampcycle, jigvert, jigpath, 
					status );
	(*data)->dream = dream;
    
	/* Free up the smfDatas for jigvert and jigpath */
	if ( jigvert != NULL ) {
	  smf_close_file( &jigvdata, status );
	}
	if ( jigpath != NULL ) {
	  smf_close_file( &jigpdata, status );
	}
	datAnnul( &xloc, status );
      }
    }
  }
  /* Read and store history */
  smf_history_read( *data, status );

}

