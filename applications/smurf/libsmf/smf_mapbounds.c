/*
*+
*  Name:
*     smf_mapbounds

*  Purpose:
*     Automatically calculate the pixel bounds and FrameSet for a map
*     given a projection

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     smf_mapbounds( int fast, Grp *igrp,  int size, const char *system,
*                   const AstFrameSet *refwcs,
*                   int alignsys, int *lbnd_out, int *ubnd_out, 
*                   AstFrameSet **outframeset, int *moving, smfBox ** boxes,
*                   int *status );

*  Arguments:
*     fast = int (Given)
*        If true and if the input map is not a scan, the bounds will only be
*        calculated by looking at the first and last timeslice. For DREAM/STARE
*        this is usually sufficient.
*     igrp = Grp* (Given)
*        Group of timestream NDF data files to retrieve pointing
*     size = int (Given)
*        Number of elements in igrp
*     system = const char* (Given)
*        String indicating the type of projection (e.g. "icrs")
*     spacerefwcs = const AstFrameSet * (Given)
*        Frameset corresponding to a reference WCS that should be
*        used to define the output pixel grid. Can be NULL.
*     alignsys = int (Given)
*        If non-zero, then the input data will be aligned in the coordinate 
*        system specified by "system" rather than in the default system
*        (ICRS).
*     lbnd_out = double* (Returned)
*        2-element array pixel coord. for the lower bounds of the output map 
*     ubnd_out = double* (Returned)
*        2-element array pixel coord. for the upper bounds of the output map 
*     outframeset = AstFrameSet** (Returned)
*        Frameset containing the sky->output map mapping
*     moving = int* (Returned)
*        Flag to denote whether the source is moving
*     boxes = smfBox ** (Returned)
*        Location at which to returned a pointer to an array of smfBox 
*        structures. The length of this array is equal to the number of input 
*        files in group "igrp". Each element of the array holds the bounds 
*        of the spatial coverage of the corresponding input file, given as 
*        pixel indices within the output cube. The array should be freed 
*        using astFree when no longer needed.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function steps over a list of input files and calculates the
*     bolometer->output map pixel transformation for the corner bolometers
*     of the subarray in order to automatically determine the extent 
*     of the map.

*  Authors:
*     Edward Chapin (UBC)
*     Tim Jenness (JAC, Hawaii)
*     Andy Gibb (UBC)
*     David Berry 
*     {enter_new_authors_here}

*  History:
*     2006-02-02 (EC):
*        Initial version.
*     2006-02-13 (TIMJ):
*        Use astSetC rather than astSet
*        Avoid an additional dereference
*        Use sc2ast_makefitschan
*     2006-02-23 (EC):
*        Fixed bug in frameset generation - tangent point in pixel coordinates
*        was not getting set properly.
*     2006-07-26 (TIMJ):
*        sc2head no longer used. Use JCMTState instead.
*     2006-07-27 (TIMJ):
*        Do not use bare constant for rad to deg conversion.
*     2006-08-15 (EC):
*        Fixed off-by-one errors in GRID coordinates
*     2006-09-12 (EC):
*        Added ability to calculate mapbounds for AzTEC
*     2007-01-25 (AGG):
*        Rewrite to check for and take account of moving objects,
*        largely borrowed from smf_cubegrid & smf_cubebounds
*     2007-02-20 (DSB):
*        Modify check for object movement to take account of the
*        difference in epoch between the first and last time slices.
*     2007-03-07 (AGG):
*        Annul relevant AST objects every time slice to minimize
*        memory usage
*     2007-07-12 (EC):
*        -Replaced calculation of bolo2map with a call to smf_rebincube_totmap
*        -Changed name of smf_rebincube_totmap to smf_rebin_totmap
*     2007-10-29 (EC):
*        Modified interface to smf_open_file.
*     2007-12-14 (EC):
*        Call smf_open_file with SMF__NOCREATE_DATA
*     2008-02-29 (AGG):
*        Explicitly set SkyRef position, ensure SkyRefIs and
*        AlignOffset attributes are also set accordingly
*     08-APR-2008 (TIMJ):
*      	 Use tcs_tai instead of	rts_end	for position calculations.
*     2008-04-18 (AGG):
*        Set lbnd to 1,1
*     2008-05-14 (EC):
*        - Modified to use projection parameters in the same style as makecube
*        - use astSetFits instead of sc2ast_makefitschan
*     2008-05-15 (EC):
*        Moved user query of lbnd/ubnd into smurf_makemap. Here just set the
*        ?bound_out values, and set dynamic defaults for LBND/UBND
*     2008-05-20 (EC):
*        Set intelligent dynamic default for CROTA like smf_cubegrid
*     2008-06-03 (TIMJ):
*        Add smfBox support similar to smf_cubebounds.
*        Change API of smf_get_projpar
*        Return pixel bounds rather than grid bounds
*        Prompt for bounds here rather than in caller.
*     2008-06-04 (TIMJ):
*        - Add alignsys flag. Replaces "int flag" that was unused.
*        - Fix -Wall warnings.
*        - use smf_calc_skyframe
*     2008-06-05 (TIMJ):
*        - par[] does not need to be an argument.
*        - replace par[] with reference spatial frameset.
*     2008-07-28 (TIMJ):
*        Use smf_makefitschan.
*     2008-07-29 (TIMJ):
*        Tweak the logic to make it clear that skyin is only needed
*        to determine the projection.
*     2008-07-30 (TIMJ):
*        Significant (eg 0.6s vs 13s) improvement in the speed of this
*        routine in FAST mode. Now work out the maximum excursion of the
*        telescope relative to BASE and only ask the transformation code
*        to look at those 4 time slices.
*     {enter_further_changes_here}

*  Notes:
*     The par[7] array used in this routine is documented in smf_get_projpar.c

*  Copyright:
*     Copyright (C) 2008 Science and Technology Facilities Council.
*     Copyright (C) 2005-2007 Particle Physics and Astronomy Research Council.
*     Copyright (C) 2005-2008 University of British Columbia.
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

#include <stdio.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "prm_par.h"
#include "sae_par.h"
#include "par.h"
#include "star/ndg.h"
#include "star/slalib.h"

/* SMURF includes */
#include "smurf_par.h"
#include "libsmf/smf.h"
#include "sc2da/sc2ast.h"

#define FUNC_NAME "smf_mapbounds"

void smf_mapbounds( int fast, Grp *igrp,  int size, const char *system,
                    const AstFrameSet *spacerefwcs,
                    int alignsys, int *lbnd_out, int *ubnd_out, 
                    AstFrameSet **outframeset, int *moving,
                    smfBox ** boxes, int *status ) {

  /* Local Variables */
  AstSkyFrame *abskyframe = NULL; /* Output Absolute SkyFrame */
  int actval;           /* Number of parameter values supplied */
  AstMapping *bolo2map = NULL; /* Combined mapping bolo->map
                                  coordinates, WCS->GRID Mapping from
                                  input WCS FrameSet */
  smfBox *box = NULL;          /* smfBox for current file */
  smfData *data = NULL;        /* pointer to  SCUBA2 data struct */
  double dlbnd[ 2 ];    /* Floating point lower bounds for output map */
  double dubnd[ 2 ];    /* Floating point upper bounds for output map */
  smfFile *file = NULL;        /* SCUBA2 data file information */
  AstFitsChan *fitschan = NULL;/* Fits channels to construct WCS header */
  AstFrameSet *fs = NULL;      /* A general purpose FrameSet pointer */
  smfHead *hdr = NULL;         /* Pointer to data header this time slice */
  int i;                       /* Loop counter */
  dim_t j;                     /* Loop counter */
  dim_t k;                     /* Loop counter */
  int lbnd0[ 2 ];              /* Defaults for LBND parameter */
  double map_pa=0;             /* Map PA in output coord system (rads) */ 
  dim_t maxloop;               /* Number of times to go round the time slice loop */
  double par[7];               /* Projection parameters */
  char *pname = NULL;          /* Name of currently opened data file */
  double shift[ 2 ];           /* Shifts from PIXEL to GRID coords */
  AstMapping *oskymap = NULL;  /* Mapping celestial->map coordinates,
                                  Sky <> PIXEL mapping in output
                                  FrameSet */
  AstSkyFrame *oskyframe = NULL;/* Output SkyFrame */
  dim_t textreme[4];           /* Time index corresponding to minmax TCS posn */
  AstFrame *skyin = NULL;      /* Sky Frame in input FrameSet */
  double skyref[ 2 ];          /* Values for output SkyFrame SkyRef attribute */
  int ubnd0[ 2 ];              /* Defaults for UBND parameter */
  double x_array_corners[4];   /* X-Indices for corner bolos in array */ 
  double x_map[4];             /* Projected X-coordinates of corner bolos */ 
  double y_array_corners[4];   /* Y-Indices for corner pixels in array */ 
  double y_map[4];             /* Projected X-coordinates of corner bolos */ 

  /* Main routine */
  if (*status != SAI__OK) return;

  /* Initialize pointer to output FrameSet and moving-source flag */
  *outframeset = NULL;
  *moving = 0;

  /* initialize double precision output bounds and the proj pars */
  for( i = 0; i < 7; i++ ) par[ i ] = AST__BAD;
  dlbnd[ 0 ] = VAL__MAXD;
  dlbnd[ 1 ] = VAL__MAXD;
  dubnd[ 0 ] = VAL__MIND;
  dubnd[ 1 ] = VAL__MIND;

  /* If we have a supplied reference WCS we can use that directly
     without having to calculate it from the data */
  if (spacerefwcs) oskyframe = astGetFrame( spacerefwcs, AST__CURRENT );

  /* Create array of returned smfBox structures and store a pointer
     to the next one to be initialised. */
  *boxes = astMalloc( sizeof( smfBox ) * size );
  box = *boxes;

  astBegin;

  /* Loop over all files in the Grp */
  for( i=1; i<=size; i++, box++ ) {

    /* Initialise the spatial bounds of section of the the output cube that is
       contributed to by the current ionput file. */
    box->lbnd[ 0 ] = VAL__MAXD;
    box->lbnd[ 1 ] = VAL__MAXD;
    box->ubnd[ 0 ] = VAL__MIND;
    box->ubnd[ 1 ] = VAL__MIND;

    /* Read data from the ith input file in the group */      
    smf_open_file( igrp, i, "READ", SMF__NOCREATE_DATA, &data, status );

    if (*status != SAI__OK) {
      msgSeti( "I", i );
      errRep( "smf_mapbounds", "Couldn ot open data file no ^I.", status );
      break;
    } else {
      if( *status == SAI__OK ) {
        if( data->file == NULL ) {
          *status = SAI__ERROR;
          errRep( FUNC_NAME, "No smfFile associated with smfData.", 
                  status );
          break;

        } else if( data->hdr == NULL ) {
          *status = SAI__ERROR;
          errRep( FUNC_NAME, "No smfHead associated with smfData.", 
                  status );
          break;

        } else if( data->hdr->fitshdr == NULL ) {
          *status = SAI__ERROR;
          errRep( FUNC_NAME, "No FITS header associated with smfHead.", 
                  status );
          break;

        } 
      }
    }

    /* convenience pointers */
    file = data->file;
    hdr = data->hdr;

    /* report name of the input file */
    pname =  file->name;
    msgSetc("FILE", pname);
    msgSeti("I", i);
    msgSeti("N", size);
    msgOutif(MSG__VERB, " ", 
             "SMF_MAPBOUNDS: Processing ^I/^N ^FILE",
             status);

/* Check that there are 3 pixel axes. */
    if( data->ndims != 3 ) {
      msgSetc( "FILE", pname );
      msgSeti( "NDIMS", data->ndims );
      *status = SAI__ERROR;
      errRep( FUNC_NAME, "^FILE has ^NDIMS pixel axes, should be 3.", 
              status );
      break;
    }

    /* Check that the data dimensions are 3 (for time ordered data) */
    if( *status == SAI__OK ) {

      /* If OK Decide which detectors (GRID coord) to use for
         checking bounds, depending on the instrument in use. */

      switch( hdr->instrument ) {
	  
      case INST__SCUBA2:
        /* 4 corner bolometers of the subarray */
        x_array_corners[0] = 1;
        x_array_corners[1] = 1;
        x_array_corners[2] = (data->dims)[0];
        x_array_corners[3] = (data->dims)[0];
	  
        y_array_corners[0] = 1;
        y_array_corners[1] = (data->dims)[1];
        y_array_corners[2] = 1;
        y_array_corners[3] = (data->dims)[1];
        break;
	  
      case INST__AZTEC:
        /* Rough guess for extreme bolometers around the edge */
        x_array_corners[0] = 22;
        x_array_corners[1] = 65;
        x_array_corners[2] = 73;
        x_array_corners[3] = 98;
	  
        y_array_corners[0] = 1; /* Always 1 for AzTEC */
        y_array_corners[1] = 1;
        y_array_corners[2] = 1;
        y_array_corners[3] = 1;
        break;
	  
      default:
        *status = SAI__ERROR;
        errRep(FUNC_NAME, "Don't know how to calculate mapbounds for data created with this instrument", status);	  
      }
    }

    if( *status == SAI__OK) {

      /* Create output SkyFrame if it has not come from a reference */
      if ( oskyframe == NULL ) {

        /* smf_tslice_ast only needs to get called once to set up framesets */
        if( data->hdr->wcs == NULL ) {
          smf_tslice_ast( data, 0, 1, status);
        }

        /* Retrieve input SkyFrame */
        skyin = astGetFrame( hdr->wcs, AST__CURRENT );

        smf_calc_skyframe( skyin, system, hdr, alignsys, &oskyframe, skyref,
                           moving, status );

        /* Get the orientation of the map vertical within the output celestial
           coordinate system. This is derived form the MAP_PA FITS header, which
           gives the orientation of the map vertical within the tracking system. */
        map_pa = smf_calc_mappa( hdr, system, skyin, status );

        /* Calculate the projection parameters. We do not enable autogrid determination
           for SCUBA-2 so we do not need to obtain all the data before calculating
           projection parameters. */
        smf_get_projpar( oskyframe, skyref, *moving, 0, 0, NULL, 0,
                         map_pa, par, NULL, NULL, status );

        if (skyin) skyin = astAnnul( skyin );

      } /* End oskyframe construction */

      if ( *outframeset == NULL && oskyframe != NULL && (*status == SAI__OK)){
        /* Now created a spatial Mapping. Use the supplied reference frameset
           if supplied */
        if (spacerefwcs) {
          oskymap = astGetMapping( spacerefwcs, AST__BASE, AST__CURRENT );
        } else {
          /* Now populate a FitsChan with FITS-WCS headers describing
             the required tan plane projection. The longitude and
             latitude axis types are set to either (RA,Dec) or (AZ,EL)
             to get the correct handedness. */
          fitschan = astFitsChan ( NULL, NULL, "" );
          smf_makefitschan( astGetC( oskyframe, "System"), &(par[0]),
                            &(par[2]), &(par[4]), par[6], fitschan, status ); 
          astClear( fitschan, "Card" );
          fs = astRead( fitschan );
            
          /* Extract the output PIXEL->SKY Mapping. */
          oskymap = astGetMapping( fs, AST__BASE, AST__CURRENT );
          /* Tidy up */
          fs = astAnnul( fs );
        }
        /* Get a copy of the output SkyFrame and ensure it represents
           absolute coords rather than offset coords. */
        abskyframe = astCopy( oskyframe );
        astClear( abskyframe, "SkyRefIs" );
        astClear( abskyframe, "AlignOffset" );

        /* Create the output FrameSet */
        *outframeset = astFrameSet( astFrame(2, "Domain=GRID"), "");

        /* Now add the SkyFrame to it */
        astAddFrame( *outframeset, AST__BASE, oskymap, oskyframe );
        /* Invert the oskymap mapping */
        astInvert( oskymap );

      } /* End WCS FrameSet construction */

      maxloop = (data->dims)[2];
      if (fast) {
        /* For scan map we scan through looking for largest telescope moves.
           For dream/stare we just look at the start and end time slices to
           account for sky rotation. */

        if (data->hdr->obsmode != SMF__OBS_SCAN) {
          textreme[0] = 0;
          textreme[1] = (data->dims)[2] - 1;
          maxloop = 2;
        } else {
          const char * tracksys;
          double flbnd[2], fubnd[2];
          int usefixedbase = 0;
          double bc1 = 0.0;
          double bc2 = 0.0;

          /* initialise */
          flbnd[ 0 ] = VAL__MAXD;
          flbnd[ 1 ] = VAL__MAXD;
          fubnd[ 0 ] = VAL__MIND;
          fubnd[ 1 ] = VAL__MIND;
          for (j=0; j<4; j++) { textreme[i] = (dim_t)VAL__BADI; }

          /* see if the input frame is moving but the output is not */
          tracksys = sc2ast_convert_system( (hdr->allState)[0].tcs_tr_sys,
                                            status );
          if (strcmp(tracksys, "GAPPT") == 0 ||
              strcmp(tracksys, "AZEL") == 0) {
            if (strcmp(system, "APP") != 0 &&
                strcmp(system, "AZEL") != 0) {
              usefixedbase = 1;
              bc1 = (hdr->allState)[0].tcs_tr_bc1;
              bc2 = (hdr->allState)[0].tcs_tr_bc2;
            }
          }

          /* Loop over each time slice to calculate the maximum
             excursion */
          for (j=0; j<(data->dims)[2]; j++) {
            JCMTState state = (hdr->allState)[j];
            double ac1 = state.tcs_tr_ac1;
            double ac2 = state.tcs_tr_ac2;
            double offx, offy;
            int jstat = 0;

            if (!usefixedbase) {
              bc1 = state.tcs_tr_bc1;
              bc2 = state.tcs_tr_bc2;
            }

            /* calculate the separation of ACTUAL from BASE */
            slaDs2tp(ac1,ac2,bc1,bc2, &offx, &offy, &jstat );

            if ( offx < flbnd[0] ) { flbnd[0] = offx; textreme[0] = j; }
            if ( offy < flbnd[1] ) { flbnd[1] = offy; textreme[1] = j; }
            if ( offx > fubnd[0] ) { fubnd[0] = offx; textreme[2] = j; }
            if ( offy > fubnd[1] ) { fubnd[1] = offy; textreme[3] = j; }
          }
          maxloop = 4;
          msgSetd("X1", textreme[0]);
          msgSetd("X2", textreme[1]);
          msgSetd("X3", textreme[2]);
          msgSetd("X4", textreme[3]);
          msgOutif( MSG__DEBUG, " ",
                    "Extrema time slices are ^X1, ^X2, ^X3 and ^X4",
                    status);
        }
      }

      /* Get the astrometry for all the relevant time slices in this data file */
      for( j=0; j<maxloop; j++ ) {
        dim_t ts;  /* Actual time slice to use */

        /* if we are doing the fast loop, we need to read the time slice 
           index from textreme. Else we just use the index */
        if (fast) {
          /* get the index but make sure it is good */
          ts = textreme[j];
          if (ts == (dim_t)VAL__BADI) continue;
        } else {
          ts = j;
        }
        /* printf("Accessing time slice %d\n", (int)ts);*/
        /* Calculate the bolo to map-pixel transformation for this tslice */
        bolo2map = smf_rebin_totmap( data, ts, abskyframe, oskymap, 
                                     *moving, status );

        if ( *status == SAI__OK ) {
          /* Check corner pixels in the array for their projected extent
             on the sky to set the pixel bounds */
          astTran2( bolo2map, 4, x_array_corners, y_array_corners, 1,
                    x_map, y_map );

          /* Update min/max for this time slice */
          for( k=0; k<4; k++ ) {
            if( x_map[k] < dlbnd[0] ) dlbnd[0] = x_map[k];
            if( y_map[k] < dlbnd[1] ) dlbnd[1] = y_map[k];
            if( x_map[k] > dubnd[0] ) dubnd[0] = x_map[k];
            if( y_map[k] > dubnd[1] ) dubnd[1] = y_map[k];

            if( x_map[k] < box->lbnd[0] ) box->lbnd[0] = x_map[k];
            if( y_map[k] < box->lbnd[1] ) box->lbnd[1] = y_map[k];
            if( x_map[k] > box->ubnd[0] ) box->ubnd[0] = x_map[k];
            if( y_map[k] > box->ubnd[1] ) box->ubnd[1] = y_map[k];

          }
        }
        /* Explicitly annul these mappings each time slice for reduced
           memory usage */
        if (bolo2map) bolo2map = astAnnul( bolo2map );
        if (fs) fs = astAnnul( fs );

        /* Break out of loop over time slices if bad status */
        if (*status != SAI__OK) goto CLEANUP;
      }

      /* Annul any remaining Ast objects before moving on to the next file */
      if (fs) fs = astAnnul( fs );
      if (bolo2map) bolo2map = astAnnul( bolo2map );
    }

    /* Close the data file */
    smf_close_file( &data, status);

    /* Break out of loop over data files if bad status */
    if (*status != SAI__OK) goto CLEANUP;
  }

  /* make sure we got values - should not be possible with good status */
  if (dlbnd[0] == VAL__MAXD || dlbnd[1] == VAL__MAXD) {
    if (*status == SAI__OK) {
      *status = SAI__ERROR;
      errRep( " ", "Unable to find any valid map bounds", status );
    }
  }

  /* If spatial reference wcs was supplied, store par values that result in
     no change to the pixel origin. */
  if( spacerefwcs ){
    par[ 0 ] = 0.5;
    par[ 1 ] = 0.5;
  }

  /* Need to re-align with the interim GRID coordinates */
  lbnd_out[0] = ceil( dlbnd[0] - par[0] + 0.5 );
  ubnd_out[0] = ceil( dubnd[0] - par[0] + 0.5 );
  lbnd_out[1] = ceil( dlbnd[1] - par[1] + 0.5 );
  ubnd_out[1] = ceil( dubnd[1] - par[1] + 0.5 );

  /* Do the same with the individual input file bounding boxes */
  box = *boxes;
  for (i = 1; i <= size; i++, box++) {
    box->lbnd[0] = ceil( box->lbnd[0] - par[0] + 0.5);
    box->ubnd[0] = ceil( box->ubnd[0] - par[0] + 0.5);
    box->lbnd[1] = ceil( box->lbnd[1] - par[1] + 0.5);
    box->ubnd[1] = ceil( box->ubnd[1] - par[1] + 0.5);
  }

  /* Apply a ShiftMap to the output FrameSet to re-align the GRID
     coordinates */
  shift[0] = 2.0 - par[0] - lbnd_out[0];
  shift[1] = 2.0 - par[1] - lbnd_out[1];
  astRemapFrame( *outframeset, AST__BASE, astShiftMap( 2, shift, "") );

  /* Set the dynamic defaults for lbnd/ubnd */
  lbnd0[ 0 ] = lbnd_out[ 0 ];
  lbnd0[ 1 ] = lbnd_out[ 1 ];
  parDef1i( "LBND", 2, lbnd0, status );
  
  ubnd0[ 0 ] = ubnd_out[ 0 ];
  ubnd0[ 1 ] = ubnd_out[ 1 ];
  parDef1i( "UBND", 2, ubnd0, status );

  parGet1i( "LBND", 2, lbnd_out, &actval, status );
  if( actval == 1 ) lbnd_out[ 1 ] = lbnd_out[ 0 ];
    
  parGet1i( "UBND", 2, ubnd_out, &actval, status );
  if( actval == 1 ) ubnd_out[ 1 ] = ubnd_out[ 0 ];
    
  /* Ensure the bounds are the right way round. */
  if( lbnd_out[ 0 ] > ubnd_out[ 0 ] ) { 
    int itmp = lbnd_out[ 0 ];
    lbnd_out[ 0 ] = ubnd_out[ 0 ];
    ubnd_out[ 0 ] = itmp;
  }      
    
  if( lbnd_out[ 1 ] > ubnd_out[ 1 ] ) { 
    int itmp = lbnd_out[ 1 ];
    lbnd_out[ 1 ] = ubnd_out[ 1 ];
    ubnd_out[ 1 ] = itmp;
  }

  /* Modify the returned FrameSet to take account of the new pixel origin. */
  shift[ 0 ] = lbnd0[ 0 ] - lbnd_out[ 0 ];
  shift[ 1 ] = lbnd0[ 1 ] - lbnd_out[ 1 ];
  if( shift[ 0 ] != 0.0 || shift[ 1 ] != 0.0 ) {
    astRemapFrame( *outframeset, AST__BASE, astShiftMap( 2, shift, "" ) );
  }

/* Report the pixel bounds of the cube. */
   if( *status == SAI__OK ) {
      msgOutif( MSG__NORM, " ", " ", status );
      msgSeti( "XL", lbnd_out[ 0 ] );
      msgSeti( "YL", lbnd_out[ 1 ] );
      msgSeti( "XU", ubnd_out[ 0 ] );
      msgSeti( "YU", ubnd_out[ 1 ] );
      msgOutif( MSG__NORM, " ", "   Output map pixel bounds: ( ^XL:^XU, ^YL:^YU )", 
                status );
   }

  /* If no error has occurred, export the returned FrameSet pointer from the 
     current AST context so that it will not be annulled when the AST
     context is ended. Otherwise, ensure a null pointer is returned. */
  if( *status == SAI__OK ) {
    astExport( *outframeset );
  } else {
    *outframeset = astAnnul( *outframeset );
  }

  /* Clean Up */ 
 CLEANUP:
  if (*status != SAI__OK) {
    errRep(FUNC_NAME, "Unable to determine map bounds", status);
  }
  if (oskymap) oskymap  = astAnnul( oskymap );
  if (bolo2map) bolo2map = astAnnul( bolo2map );
  if (fitschan) fitschan = astAnnul( fitschan );

  if( data != NULL )
    smf_close_file( &data, status );

  astEnd;

}
