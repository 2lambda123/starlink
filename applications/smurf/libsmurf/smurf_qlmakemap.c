/*
*+
*  Name:
*     QLMAKEMAP

*  Purpose:
*     Top-level QUICK-LOOK MAKEMAP implementation

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     smurf_qlmakemap( int *status );

*  Arguments:
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This is an optimized routine implementing a modified version of
*     the MAKEMAP task for the QUICK-LOOK SCUBA-2 pipeline. The
*     map-bounds are retrieved from the FITS header in the first file,
*     which are based on the specified map size. In practice, this
*     means that the output image will be much larger than
*     necessary. The bolometer drifts are removed using the fitted
*     polynomials, the sky is removed by subtracting the mean level
*     per time slice and then the data are extinction corrected using
*     the MEANWVM tau value (at 225 GHz) from the FITS header.

*  ADAM Parameters:
*     IN = NDF (Read)
*          Input file(s)
*     PARAMS( 2 ) = _DOUBLE (Read)
*          An optional array which consists of additional parameters
*          required by the Sinc, SincSinc, SincCos, SincGauss, Somb,
*          SombCos, and Gauss spreading methods (see parameter SPREAD).
*	   
*          PARAMS( 1 ) is required by all the above schemes. It is used to 
*          specify how many pixels on either side of the output position
*          (that is, the output position corresponding to the centre of the 
*          input pixel) are to receive contributions from the input pixel.
*          Typically, a value of 2 is appropriate and the minimum allowed 
*          value is 1 (i.e. one pixel on each side). A value of zero or 
*          fewer indicates that a suitable number of pixels should be 
*          calculated automatically. [0]
*	   
*          PARAMS( 2 ) is required only by the SombCos, Gauss, SincSinc, 
*          SincCos, and SincGauss schemes.  For the SombCos, SincSinc, and
*          SincCos schemes, it specifies the number of pixels at which the
*          envelope of the function goes to zero.  The minimum value is
*          1.0, and the run-time default value is 2.0.  For the Gauss and
*          SincGauss scheme, it specifies the full-width at half-maximum
*          (FWHM) of the Gaussian envelope.  The minimum value is 0.1, and
*          the run-time default is 1.0.  On astronomical images and 
*          spectra, good results are often obtained by approximately 
*          matching the FWHM of the envelope function, given by PARAMS(2),
*          to the point-spread function of the input data.  []
*     PIXSIZE = REAL (Read)
*          Pixel size in output image, in arcsec
*     SPREAD = LITERAL (Read)
*          The method to use when spreading each input pixel value out
*          between a group of neighbouring output pixels. If SPARSE is set 
*          TRUE, then SPREAD is not accessed and a value of "Nearest" is
*          always assumed. SPREAD can take the following values:
*	   
*          - "Linear" -- The input pixel value is divided bi-linearly between 
*          the four nearest output pixels.  Produces smoother output NDFs than 
*          the nearest-neighbour scheme.
*	   
*          - "Nearest" -- The input pixel value is assigned completely to the
*          single nearest output pixel. This scheme is much faster than any
*          of the others. 
*	   
*          - "Sinc" -- Uses the sinc(pi*x) kernel, where x is the pixel
*          offset from the interpolation point (resampling) or transformed
*          input pixel centre (rebinning), and sinc(z)=sin(z)/z.  Use of 
*          this scheme is not recommended.
*	   
*          - "SincSinc" -- Uses the sinc(pi*x)sinc(k*pi*x) kernel. A
*          valuable general-purpose scheme, intermediate in its visual
*          effect on NDFs between the bi-linear and nearest-neighbour
*          schemes. 
*	   
*          - "SincCos" -- Uses the sinc(pi*x)cos(k*pi*x) kernel.  Gives
*          similar results to the "Sincsinc" scheme.
*	   
*          - "SincGauss" -- Uses the sinc(pi*x)exp(-k*x*x) kernel.  Good 
*          results can be obtained by matching the FWHM of the
*          envelope function to the point-spread function of the
*          input data (see parameter PARAMS).
*	   
*          - "Somb" -- Uses the somb(pi*x) kernel, where x is the pixel
*          offset from the transformed input pixel centre, and 
*          somb(z)=2*J1(z)/z (J1 is the first-order Bessel function of the 
*          first kind.  This scheme is similar to the "Sinc" scheme.
*	   
*          - "SombCos" -- Uses the somb(pi*x)cos(k*pi*x) kernel.  This
*          scheme is similar to the "SincCos" scheme.
*	   
*          - "Gauss" -- Uses the exp(-k*x*x) kernel. The FWHM of the Gaussian 
*          is given by parameter PARAMS(2), and the point at which to truncate 
*          the Gaussian to zero is given by parameter PARAMS(1).
*	   
*          For further details of these schemes, see the descriptions of 
*          routine AST_REBINx in SUN/211. ["Nearest"]
*     SYSTEM = LITERAL (Read)
*          The celestial coordinate system for the output map
*     OUT = NDF (Write)
*          Output file

*  Authors:
*     Tim Jenness (JAC, Hawaii)
*     Andy Gibb (UBC)
*     Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2006-03-16 (AGG):
*        Clone from smurf_makemap
*     2006-03-23 (AGG):
*        Use new and updated routines to estimate map bounds, rebin
*        map. Also carry out flatfield, sky removal and extinction
*        correction.
*     2006-04-21 (AGG):
*        Now use quicker MEAN sky subtraction rather than polynomials
*     2006-07-12 (AGG):
*        Return polynomial subtraction since it removes bolometer
*        drifts, not the sky
*     26-JUL-2006 (TIMJ):
*        Remove unused sc2da includes.
*     2007-01-12 (AGG):
*        Add SYSTEM parameter for specifying output coordinate system
*     2007-01-30 (AGG):
*        Update due to API change for smf_rebinmap &
*        smf_mapbounds_approx. Also just pass in the index of the
*        first file in the input Grp to smf_mapbounds_approx
*     2007-02-27 (AGG):
*        Refactor the code to deal with global status consistently
*     2007-03-05 (EC):
*        Changed smf_correct_extinction interface
*     2007-03-20 (TIMJ):
*        Write an output FITS header
*     2007-06-22 (TIMJ):
*        Rework to handle PRV* as well as OBS*
*     2007-07-05 (TIMJ):
*        Fix provenance file name handling.
*     2007-12-18 (AGG):
*        Update to use new smf_free behaviour
*     2008-02-12 (AGG):
*        - Add USEBAD parameter (default NO)
*        - Update to reflect change in API for smf_rebinmap
*     2008-02-13 (AGG):
*        Add SPREAD and PARAMS parameters to allow choice of
*        pixel-spreading scheme, update call to smf_rebinmap
*     2008-02-15 (AGG):
*        Weights array is now written as an NDF extension
*     2008-02-19 (AGG):
*        Add EXP_TIME array to output file
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2006-2007 Particle Physics and Astronomy Research
*     Council. Copyright (C) 2006-2008 University of British Columbia.
*     Copyright (C) 2007 Science and Technology Facilities Council.
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

#if HAVE_CONFIG_H
#include <config.h>
#endif

/* Standard includes */
#include <string.h>
#include <stdio.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "par.h"
#include "prm_par.h"
#include "ndf.h"
#include "sae_par.h"
#include "star/hds.h"
#include "star/ndg.h"
#include "star/grp.h"
#include "star/kaplibs.h"

/* SMURF includes */
#include "smurf_par.h"
#include "smurflib.h"
#include "libsmf/smf.h"
#include "sc2da/sc2ast.h"

#define TASK_NAME "smurf_qlmakemap"

void smurf_qlmakemap( int *status ) {

  /* Local Variables */
  smfData *data = NULL;      /* Pointer to input SCUBA2 data struct */
  float *exp_time = NULL;    /* Exposure time array written to output file */
  AstFitsChan *fchan = NULL; /* FitsChan holding output NDF FITS extension */
  smfFile *file=NULL;        /* Pointer to SCUBA2 data file struct */
  int flag;                  /* Flag */
  dim_t i;                   /* Loop counter */
  Grp *igrp = NULL;          /* Group of input files */
  int indf = 0;              /* NDF identifier of output file */
  int lbnd_out[2];           /* Lower pixel bounds for output map */
  int lbnd_wgt[3];           /* Lower pixel bounds for weight array */
  double *map = NULL;        /* Pointer to the rebinned map data */
  size_t mapsize;            /* Number of pixels in output image */
  int moving = 0;            /* Flag to denote a moving object */
  int nparam = 0;            /* Number of extra parameters for pixel spreading scheme*/
  AstKeyMap * obsidmap = NULL; /* Map of OBSIDs from input data */
  smfData *odata=NULL;       /* Pointer to output SCUBA2 data struct */
  Grp *ogrp = NULL;          /* Group containing output file */
  int ondf = NDF__NOID;      /* output NDF identifier */
  AstFrameSet *outframeset = NULL; /* Frameset containing sky->output map mapping */
  int outsize;               /* Number of files in output group */
  char pabuf[ 10 ];          /* Text buffer for parameter value */
  double params[ 4 ];        /* astRebinSeq parameters */
  float pixsize = 3.0;       /* Size of an output map pixel in arcsec */
  AstKeyMap * prvkeymap = NULL; /* Keymap of input files for PRVxxx headers */
  int size;                  /* Number of files in input group */
  int smfflags = 0;          /* Flags for creating a new smfData */
  HDSLoc *smurfloc = NULL;   /* HDS locator of SMURF extension */
  int spread;                /* Code for pixel spreading scheme */
  double steptime;           /* Integration time per sample, from FITS header */
  char system[10];           /* Celestial coordinate system for output image */
  double tau;                /* 225 GHz optical depth */
  smfData *tdata = NULL;     /* Exposure time data */
  int ubnd_out[2];           /* Upper pixel bounds for output map */
  int ubnd_wgt[3];           /* Upper pixel bounds for weight array */
  int usebad;                /* Flag for whether to use bad bolos mask */
  void *variance = NULL;     /* Pointer to the variance map */
  smfData *wdata = NULL;     /* Pointer to SCUBA2 data struct for weights */
  double *weights = NULL;    /* Pointer to the weights map */

  /* Main routine */
  ndfBegin();
  
  /* Get group of input files */
  ndgAssoc( "IN", 1, &igrp, &size, &flag, status );

  /* Get the celestial coordinate system for the output image. */
  parChoic( "SYSTEM", "TRACKING", "TRACKING,FK5,ICRS,AZEL,GALACTIC,"
	    "GAPPT,FK4,FK4-NO-E,ECLIPTIC", 1, system, 10, status );

  /* Get the user defined pixel size */
  parGet0r( "PIXSIZE", &pixsize, status );
  if ( pixsize <= 0 || pixsize > 60. ) {
    msgSetd( "PIXSIZE", pixsize );
    *status = SAI__ERROR;
    errRep( " ", "Invalid pixel size, ^PIXSIZE (must be positive but < 60 arcsec)", 
	   status );
  }

  /* Determine whether or not to use the bad bolos mask.  If 
     unspecified, use the mask */
  parGtd0l ("USEBAD", 0, 1, &usebad, status);

  parChoic( "SPREAD", "NEAREST", "NEAREST,LINEAR,SINC,"
	    "SINCSINC,SINCCOS,SINCGAUSS,SOMB,SOMBCOS,GAUSS", 
	    1, pabuf, 10, status );

  smf_get_spread( pabuf, &spread, &nparam, status );

  /* Get an additional parameter vector if required. */
  if ( nparam > 0 ) parExacd( "PARAMS", nparam, params, status );

  /* Calculate the map bounds - from the FIRST FILE only! */
  msgOutif( MSG__VERB," ", 
	   "SMURF_QLMAKEMAP: Determine approx map bounds from first file", status );
  smf_mapbounds_approx( igrp, 1, system, pixsize, lbnd_out, ubnd_out, 
			&outframeset, &moving, status );
 

  /* Create an output smfData */
  ndgCreat( "OUT", NULL, &ogrp, &outsize, &flag, status );
  smfflags |= SMF__MAP_VAR;
  smf_open_newfile( ogrp, 1, SMF__DOUBLE, 2, lbnd_out, ubnd_out, smfflags, &odata, 
		    status );

  /* If created OK, retrieve pointers to data */
  if ( *status == SAI__OK ) {
    file = odata->file;
    ondf = file->ndfid;
    /* Map the data, variance, and weights arrays */
    map = (odata->pntr)[0];
    variance = (odata->pntr)[1];
  }

  /* Create SMURF extension in the output file */
  smurfloc = smf_get_xloc ( odata, "SMURF", "SMURF", "WRITE", 0, 0, status );

  /* Compute number of pixels in output map */
  mapsize = (ubnd_out[0] - lbnd_out[0] + 1) * (ubnd_out[1] - lbnd_out[1] + 1);

  /* Determine bounds of weights array - QLMAKEMAP always uses the
     REBIN method so the weights bounds array is 3-D to ensure
     variances are calculated */
  lbnd_wgt[0] = lbnd_out[0];
  ubnd_wgt[0] = ubnd_out[0];
  lbnd_wgt[1] = lbnd_out[1];
  ubnd_wgt[1] = ubnd_out[1];
  lbnd_wgt[2] = 0;
  ubnd_wgt[2] = 1;
  /* Create WEIGHTS component in output file */
  smf_open_ndfname ( smurfloc, "WRITE", NULL, "WEIGHTS", "NEW", "_DOUBLE",
                     3, lbnd_wgt, ubnd_wgt, &wdata, status );
  if ( wdata ) weights = (wdata->pntr)[0];
  /* Create EXP_TIME component in output file */
  smf_open_ndfname ( smurfloc, "WRITE", NULL, "EXP_TIME", "NEW", "_REAL",
		     2, lbnd_out, ubnd_out, &tdata, status );
  if ( tdata ) exp_time = (tdata->pntr)[0];

  /* Create provenance keymap */
  prvkeymap = astKeyMap( "" );

  /* Loop over each input file, subtracting bolometer drifts, a mean
     sky level (per timeslice), correcting for extinction and
     regridding the data into the output map */
  msgOutif( MSG__VERB," ", "SMURF_QLMAKEMAP: Process data", status );
  for ( i=1; i<=size && *status == SAI__OK; i++ ) {
    /* Read data from the ith input file in the group */
    smf_open_and_flatfield( igrp, NULL, i, &data, status );

    /* Store the filename in the keymap for later - the GRP would be fine
       as is but we use a keymap in order to reuse smf_fits_add_prov */
    if (*status == SAI__OK)
      smf_accumulate_prov( prvkeymap, data->file, igrp, i, status );

    /* Store steptime for calculating EXP_TIME */
    if ( i==1 ) {
      smf_fits_getD(data->hdr, "STEPTIME", &steptime, status);
    }

    /* Handle output FITS header creation */
    smf_fits_outhdr( data->hdr->fitshdr, &fchan, &obsidmap, status );

    /* Remove bolometer drifts if a fit is present */
    smf_subtract_poly( data, status );

    /* Remove a mean sky level */
    smf_subtract_plane( data, NULL, "MEAN", status );

    /* Correct for atmospheric extinction using the mean WVM-derived
       225-GHz optical depth */
    smf_fits_getD( data->hdr, "MEANWVM", &tau, status );
    smf_correct_extinction( data, "CSOTAU", 1, tau, NULL, status );

    /* Retrieve the NDF identifier for this input file to read the
       bad bolometer mask */
    if ( usebad ) {
      ndgNdfas ( igrp, i, "READ", &indf, status );
    }
    msgOutif(MSG__VERB, " ", "SMURF_QLMAKEMAP: Beginning the REBIN step", status);
    /* Rebin the data onto the output grid */
    smf_rebinmap(data, usebad, indf, i, size, outframeset, spread, params, moving, 
		 lbnd_out, ubnd_out, map, variance, weights, status );

    smf_close_file( &data, status );
  }

  /* Calculate exposure time per output pixel from weights array -
     note even if weights is a 3-D array we only use the first mapsize
     number of values which represent the `hits' per pixel */
  for (i=0; (i<mapsize) && (*status == SAI__OK); i++) {
    if ( map[i] == VAL__BADD ) {
      exp_time[i] = VAL__BADR;
    } else {
      exp_time[i] = steptime * weights[i];
    }
  }

  /* Write WCS FrameSet to output file */
  ndfPtwcs( outframeset, ondf, status );

/* Retrieve the unique OBSID keys from the KeyMap and populate the OBSnnnnn
   and PROVCNT headers from this information. */
  smf_fits_add_prov( fchan, "OBS", obsidmap, status ); 
  smf_fits_add_prov( fchan, "PRV", prvkeymap, status ); 
  
  astAnnul( prvkeymap );
  astAnnul( obsidmap );

/* If the FitsChan is not empty, store it in the FITS extension of the
   output NDF (any existing FITS extension is deleted). */
  if( astGetI( fchan, "NCard" ) > 0 ) kpgPtfts( ondf, fchan, status );

  /* Free the WCS pointer */
  if ( outframeset != NULL ) {
    astAnnul( outframeset );
    outframeset = NULL;
  }

  /* Tidy up and close the output file */  
  smf_close_file ( &odata, status );
  if ( ogrp != NULL ) grpDelet( &ogrp, status );

  /*  weights = smf_free( weights, status );*/
  grpDelet( &igrp, status );
  
  ndfEnd( status );
  
  msgOutif( MSG__VERB," ", "Output map written", status );
}
