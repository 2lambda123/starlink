#include "sae_par.h"
#include "mers.h"
#include "cupid.h"
#include "ast.h"
#include "ndf.h"
#include "prm_par.h"
#include "star/hds.h"
#include <math.h>

HDSLoc *cupidFellWalker( int type, int ndim, int *slbnd, int *subnd, void *ipd,
                         double *ipv, double rms, AstKeyMap *config, int velax,
                         int ilevel, double beamcorr[ 3 ], int *status ){
/*
*+
*  Name:
*     cupidFellWalker

*  Purpose:
*     Identify clumps of emission within a 1, 2 or 3 dimensional NDF using
*     the FELLWALKER algorithm.

*  Language:
*     Starlink C

*  Synopsis:
*     HDSLoc *cupidFellWalker( int type, int ndim, int *slbnd, int *subnd, 
*                              void *ipd, double *ipv, double rms, 
*                              AstKeyMap *config, int velax, int ilevel,
*                              double beamcorr[ 3 ], int *status )

*  Description:
*     This function identifies clumps within a 1, 2 or 3 dimensional data
*     array using the FELLWALKER algorithm. This algorithm loops over
*     every data pixel above the threshold which has not already been
*     assigned to a clump. For each such pixel, a route to the nearest
*     peak in the data value is found by moving from pixel to pixel along
*     the line of greatest gradient. When this route arrives at a peak, all
*     pixels within some small neighbourhood are checked to see if there
*     is a higher data value. If there is, the route recommences from the
*     highest pixel in the neighbourhood, again moving up the line of
*     greatest gradient. When a peak is reached which is the highest data
*     value within its neighbourhood, a check is made to see if this peak
*     pixel has already been assigned to a clump. If it has, then all
*     pixels which were traversed in following the route to this peak are 
*     assigned to the same clump. If the peak has not yet been assigned to a
*     clump, then it, and all the traversed pixels, are assigned to a new
*     clump. If the route commences at "sea level" and starts with a low 
*     gradient section (average gradient lower than a given value) then 
*     the initial section of the route (up to the point where the gradient 
*     exceeds the low gradient limit) is not assigned to the clump, but is 
*     instead given a special value which prevents the pixels being re-used 
*     as the start point for a new "walk".
*
*     If the high data values in a clump form a plateau with slight
*     undulations, then the above algorithm may create a separate clump
*     for each undulation. This is probably inappropriate, especially if
*     the  dips between the undulations are less than or are comparable to 
*     the noise level in the data. This situation can arise for instance
*     if the pixel-to-pixel noise is correlated on a scale equal to or
*     larger than the value of the MaxJump configuration parameter. To
*     avoid this, adjoining clumps are merged together if the dip between
*     them is less than a specified value. Specifically, if two clumps
*     with peak values PEAK1 and PEAK2, where PEAK1 is less than PEAK2, 
*     are adjacent to each other, and if the pixels along the interface 
*     between the two clumps all have data values which are larger than 
*     "PEAK1 - MinDip" (where MinDip is the value of the MinDip
*     configuration parameter), then the two clumps are merged together.

*  Parameters:
*     type
*        An integer identifying the data type of the array values pointed to 
*        by "ipd". Must be either CUPID__DOUBLE or CUPID__FLOAT (defined in
*        cupid.h).
*     ndim
*        The number of dimensions in the data array. Must be 2 or 3.
*     slbnd
*        Pointer to an array holding the lower pixel index bound of the
*        data array on each axis.
*     subnd
*        Pointer to an array holding the upper pixel index bound of the
*        data array on each axis.
*     ipd
*        Pointer to the data array. The elements should be stored in
*        Fortran order. The data type of this array is given by "itype".
*     ipv
*        Pointer to the input Variance array, or NULL if there is no Variance
*        array. The elements should be stored in Fortran order. The data 
*        type of this array is "double".
*     rms
*        The default value for the global RMS error in the data array.
*     config
*        An AST KeyMap holding tuning parameters for the algorithm.
*     velax
*        The index of the velocity axis in the data array (if any). Only
*        used if "ndim" is 3. 
*     ilevel
*        Amount of screen information to display (in range zero to 6).
*     beamcorr
*        An array in which is returned the FWHM (in pixels) describing the
*        instrumental smoothing along each pixel axis. The clump widths
*        stored in the output catalogue are reduced to correct for this
*        smoothing.
*     status
*        Pointer to the inherited status value.

*  Returned Value:
*     A locator for a new HDS object which is an array of NDF structures.
*     Each NDF will hold the data values associated with a single clump 
*     and will be the smallest possible NDF that completely contains the 
*     corresponding clump. Pixels not in the clump will be set bad. The 
*     pixel origin is set to the same value as the supplied NDF.

*  Copyright:
*     Copyright (C) 2006 Particle Physics & Astronomy Research Council.
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
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David S. Berry
*     {enter_new_authors_here}

*  History:
*     16-JAN-2006 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/

/* Local Variables: */

   AstKeyMap *fwconfig; /* Configuration parameters for this algorithm */
   HDSLoc *ret;         /* Locator for the returned array of NDFs */
   double *pd;          /* Pointer to next element of data array */
   double *peakvals;    /* Pointer to array holding clump peak values */
   double mindip;       /* Minimum dip between distinct peaks */
   double minhgt;       /* Min allowed height for a clump peak */
   double noise;        /* Background data value */
   double pv;           /* Pixel value */
   float *pf;           /* Pointer to next element of data array */
   int *clbnd;          /* Array holding lower axis bounds of all clumps */
   int *cubnd;          /* Array holding upper axis bounds of all clumps */
   int *igood;          /* Pointer to array holding usable clump indices */
   int *ipa;            /* Pointer to clump assignment array */
   int *nrem;           /* Pointer to array holding clump populations */
   int *pa;             /* Pointer to next element of the ipa array */
   int dims[3];         /* Pointer to array of array dimensions */
   int el;              /* Number of elements in array */
   int i;               /* Loop count */
   int ii;              /* Temp storage */
   int ix;              /* Grid index on 1st axis */
   int iy;              /* Grid index on 2nd axis */
   int iz;              /* Grid index on 3rd axis */
   int j;               /* Loop count */
   int maxid;           /* Largest id for any peak (smallest is zero) */
   int minpix;          /* Minimum total size of a clump in pixels */
   int more;            /* Continue looping? */
   int ngood;           /* Number of good clumps */
   int nlow;            /* Number of clumps with low peaks */
   int nthin;           /* Number of clumps that span only a single pixel */
   int nsmall;          /* Number of clumps with too few pixels */
   int skip[3];         /* Pointer to array of axis skips */

/* Initialise */
   ret = NULL;

/* Abort if an error has already occurred. */
   if( *status != SAI__OK ) return ret;

/* Initialise things to avoid compiler warnings. */
   peakvals = NULL;
   nrem = NULL;

/* Say which method is being used. */
   if( ilevel > 0 ) {
      msgBlank( status );
      msgOut( "", "FellWalker:", status );
      if( ilevel > 1 ) msgBlank( status );
   }

/* Get the AST KeyMap holding the configuration parameters for this
   algorithm. */
   if( !astMapGet0A( config, "FELLWALKER", (AstObject *) &fwconfig ) ) {     
      fwconfig = astKeyMap( "" );
      astMapPut0A( config, "FELLWALKER", fwconfig, "" );
   }

/* The configuration file can optionally omit the algorithm name. In this
   case the "config" KeyMap may contain values which should really be in
   the "fwconfig" KeyMap. Add a copy of the "config" KeyMap into "fwconfig" 
   so that it can be searched for any value which cannot be found in the
   "fwconfig" KeyMap. */
   astMapPut0A( fwconfig, CUPID__CONFIG, astCopy( config ), NULL );

/* Return the instrumental smoothing FWHMs */
   beamcorr[ 0 ] = cupidConfigD( fwconfig, "FWHMBEAM", 2.0, status );
   beamcorr[ 1 ] = beamcorr[ 0 ];
   if( ndim == 3 ) {
      beamcorr[ 2 ] = beamcorr[ 0 ];
      beamcorr[ velax ]= cupidConfigD( fwconfig, "VELORES", 2.0, status );
   }

/* Find the size of each dimension of the data array, and the total number
   of elements in the array, and the skip in 1D vector index needed to
   move by pixel along an axis. We use the memory management functions of the 
   AST library since they provide greater security and functionality than 
   direct use of malloc, etc. */
   el = 1;
   for( i = 0; i < ndim; i++ ) {
      dims[ i ] = subnd[ i ] - slbnd[ i ] + 1;
      el *= dims[ i ];
      skip[ i ] = ( i == 0 ) ? 1 : skip[ i - 1 ]*dims[ i - 1 ];
   }
   for( ; i < 3; i++ ) {
      dims[ i ] = 1;
      skip[ i ] = 0;
   }

/* Assign work array to hold the clump assignments. */
   ipa = astMalloc( sizeof( int )*el );

/* Get the RMS noise level to use. */
   rms = cupidConfigD( fwconfig, "RMS", rms, status );

/* Assign every data pixel to a clump and stores the clumps index in the
   corresponding pixel in "ipa". */
   maxid = cupidFWMain( type, ipd, el, ndim, dims, skip, slbnd, rms, fwconfig,
                        ipa, ilevel, status );

/* Abort if no clumps found. */
   if( maxid < 0 ) {
      if( ilevel > 0 ) {
         msgOut( "", "No usable clumps found.", status );
         msgBlank( status );
      }
      goto L10;
   }

/* Allocate an array used to store the number of pixels remaining in each 
   clump. */
   nrem = astMalloc( sizeof( int )*( maxid + 1 ) );

/* Allocate an array used to store the peak value in every clump. */
   peakvals = astMalloc( sizeof( double )*( maxid + 1 ) );

/* Determine the bounding box of every clump. First allocate memory to
   hold the bounding boxes, etc. */
   clbnd = astMalloc( sizeof( int )*( maxid + 1 )*3 );
   cubnd = astMalloc( sizeof( int )*( maxid + 1 )*3 );
   igood = astMalloc( sizeof( int )*( maxid + 1 ) );
   if( cubnd ) {

/* Get the lowest data value to be considered. */
      noise = cupidConfigRMS( config, "NOISE", rms, 2.0*rms, status );

/* Get the minimum dip between two adjoining peaks necessary for the two
   peaks to be considered distinct. */
      mindip = cupidConfigRMS( config, "MINDIP", rms, 3.0*rms, status );

/* Get the lowest allowed clump peak value. */
      minhgt = cupidConfigRMS( fwconfig, "MINHEIGHT", rms, mindip + noise, status );

/* Get the minimum allowed number of pixels in a clump. */
      minpix = cupidDefMinPix( ndim, beamcorr, noise, minhgt, status );
      minpix = cupidConfigI( fwconfig, "MINPIX", minpix, status );

/* Initialise a list to hold zero for every clump id. These values are
   used to count the number of pixels remaining in each clump. Also
   initialise the peak values to a very negative value. */
      for( i = 0; i <= maxid; i++ ) {
         nrem[ i ] = 0;
         peakvals[ i ] = VAL__MIND;
      }

/* Initialise the bounding boxes. */
      for( i = 0; i < 3*( maxid + 1 ); i++ ) {
         clbnd[ i ] = VAL__MAXI;
         cubnd[ i ] = VAL__MINI;
      }

/* Loop round every pixel in the final pixel assignment array. */
      if( type == CUPID__DOUBLE ) {
         pd = (double *) ipd;
         pf = NULL;
      } else {
         pf = (float *) ipd;
         pd = NULL;
      }
      pa = ipa;
      for( iz = 1; iz <= dims[ 2 ]; iz++ ){
         for( iy = 1; iy <= dims[ 1 ]; iy++ ){
            for( ix = 1; ix <= dims[ 0 ]; ix++, pa++ ){

/* Get the data value at this pixel */
               if( type == CUPID__DOUBLE ) {
                  pv = *(pd++);
               } else {
                  pv = (double) *(pf++);
               }

/* Skip pixels which are not in any clump. */
               if( *pa >= 0 ) {

/* Increment the number of pixels in this clump. */
                  ++( nrem[ *pa ] );

/* If this pixel value is larger than the current peak value for this
   clump, record it. */
                  if( pv > (double) peakvals[ *pa ] ) peakvals[ *pa ] = pv;

/* Get the index within the clbnd and cubnd arrays of the current bounds
   on the x axis for this clump. */
                  i = 3*( *pa );

/* Update the bounds for the x axis, then increment to get the index of the y
   axis bounds. */
                  if( ix < clbnd[ i ] ) clbnd[ i ] = ix;
                  if( ix > cubnd[ i ] ) cubnd[ i ] = ix;
                  i++;

/* Update the bounds for the y axis, then increment to get the index of the z
   axis bounds. */
                  if( iy < clbnd[ i ] ) clbnd[ i ] = iy;
                  if( iy > cubnd[ i ] ) cubnd[ i ] = iy;
                  i++;

/* Update the bounds for the z axis. */
                  if( iz < clbnd[ i ] ) clbnd[ i ] = iz;
                  if( iz > cubnd[ i ] ) cubnd[ i ] = iz;
               }
            }
         }
      }

/* Loop round counting the clumps which are too small or too low. Put the
   indices of usable clumps into another array. */
      nsmall = 0;
      nlow = 0;
      ngood = 0;
      nthin = 0;
      for( i = 0; i <= maxid; i++ ) {
         j = 3*i;
         if( nrem[ i ] <= minpix ) {
            nsmall++;

         } else if( peakvals[ i ] < minhgt ) {
            nlow++;

         } else if( clbnd[ j ] == cubnd[ j ] || 
                  ( clbnd[ j + 1 ] == cubnd[ j + 1 ] && ndim > 1 ) || 
                  ( clbnd[ j + 2 ] == cubnd[ j + 2 ] && ndim > 2 ) ) {
            nthin++;           

         } else {
            igood[ ngood++ ] = i;
         }
      }

      if( ilevel > 0 ) {
         if( ngood == 0 ) msgOut( "", "No usable clumps found.", status );
         if( ilevel > 0 ) {
            if( nsmall == 1 ){
               msgOut( "", "One clump rejected because it contains too few pixels.", status );
            } else if( nsmall > 0 ){
               msgSeti( "N", nsmall );
               msgOut( "", "^N clumps rejected because they contain too few pixels.", status );
            }
            if( nlow == 1 ){
               msgOut( "", "One clump rejected because its peak is too low.", status );
            } else if( nlow > 0 ){
               msgSeti( "N", nlow );
               msgOut( "", "^N clumps rejected because the peaks are too low.", status );
            }
            if( nthin == 1 ) {
               msgOut( "", "1 clump rejected because it spans only a single "
                       "pixel along one or more axes.", status );

            } else if( nthin > 1 ) {
               msgSeti( "N", nthin );
               msgOut( "", "^N clumps rejected because they spans only a single "
                       "pixel along one or more axes.", status );
            }
         }        
      }         

/* Sort the clump indices into descending order of peak value. */
      j = ngood;
      more = 1;
      while( more ) {
         j--;
         more = 0;
         for( i = 0; i < j; i++ ) {
            if( peakvals[ igood[ i ] ] < peakvals[ igood[ i + 1 ] ] ) {
               ii = igood[ i + 1 ];
               igood[ i + 1 ] = igood[ i ];
               igood[ i ] = ii;
               more = 1;
            }
         }
      }

/* Loop round creating an NDF describing each usable clump. */
      for( j = 0; j < ngood; j++ ) {
         i = igood[ j ];
         ret = cupidNdfClump( type, ipd, ipa, el, ndim, dims, skip, slbnd, 
                              i, clbnd + 3*i, cubnd + 3*i, NULL, ret,
                              cupidConfigI( fwconfig, "MAXBAD", 4, status ), status );
      }

/* Free resources */
      clbnd = astFree( clbnd );
      cubnd = astFree( cubnd );
      igood = astFree( igood );
   }

L10:;

/* Remove the secondary KeyMap added to the KeyMap containing configuration 
   parameters for this algorithm. This prevents the values in the secondary 
   KeyMap being written out to the CUPID extension when cupidStoreConfig is 
   called. */
   astMapRemove( fwconfig, CUPID__CONFIG );

/* Free resources */
   fwconfig = astAnnul( fwconfig );
   ipa = astFree( ipa );
   nrem = astFree( nrem );
   peakvals = astFree( peakvals );

/* Return the list of clump NDFs. */
   return ret;

}
