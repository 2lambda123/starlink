#include "sae_par.h"
#include "mers.h"
#include "cupid.h"
#include "ast.h"
#include "star/hds.h"
#include "prm_par.h"

HDSLoc *cupidClumpFind( int type, int ndim, int *slbnd, int *subnd, void *ipd,
                        double *ipv, double rms, AstKeyMap *config, int velax,
                        int ilevel, double beamcorr[ 3 ]  ){
/*
*  Name:
*     cupidClumpFind

*  Purpose:
*     Identify clumps of emission within a 1, 2 or 3 dimensional NDF using
*     the CLUMPFIND algorithm.

*  Synopsis:
*     HDSLoc *cupidClumpFind( int type, int ndim, int *slbnd, int *subnd, 
*                             void *ipd, double *ipv, double rms, 
*                             AstKeyMap *config, int velax, int ilevel,
*                             double beamcorr[ 3 ]  )

*  Description:
*     This function identifies clumps within a 1, 2 or 3 dimensional data
*     array using the CLUMPFIND algorithm, described by Williams et al 
*     (1994, ApJ 428, 693). This algorithm works by first contouring the 
*     data at a multiple of the noise, then searches for peaks of emission 
*     which locate the clumps, and then follows them down to lower 
*     intensities. No a priori clump profile is assumed. In this algorithm, 
*     clumps never overlap.

*  Parameters:
*     type
*        An integer identifying the data type of the array values pointed to 
*        by "ipd". Must be either CUPID__DOUBLE or CUPID__FLOAT (defined in
*        cupid.h).
*     ndim
*        The number of dimensions in the data array. Must be 1, 2 or 3.
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
*        Amount of screen information to display.
*     beamcorr
*        An array in which is returned the FWHM (in pixels) describing the
*        instrumental smoothing along each pixel axis. The clump widths
*        stored in the output catalogue are reduced to correct for this
*        smoothing.

*  Retured Value:
*     A locator for a new HDS object which is an array of NDF structures.
*     Each NDF will hold the data values associated with a single clump 
*     and will be the smallest possible NDF that completely contains the 
*     corresponding clump. Pixels not in the clump will be set bad. The 
*     pixel origin is set to the same value as the supplied NDF.

*  Authors:
*     DSB: David S. Berry
*     {enter_new_authors_here}

*  History:
*     29-SEP-2005 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}
*/      

/* Local Variables: */
   AstKeyMap *cfconfig; /* Configuration parameters for this algorithm */
   CupidPixelSet **clumps;/* Pointer to list of PixelSet pointers */
   CupidPixelSet *ps;   /* Pointer to PixelSet */
   HDSLoc *ret;         /* Locator for the returned array of NDFs */
   double *levels;      /* Pointer to array of contour levels */
   double clevel;       /* Current data level */
   double dd;           /* Data value */   
   double maxd;         /* Maximum value in data array */
   double maxrem;       /* Maximum of remaining unassigned pixel values */
   double mind;         /* Minimum value in data array */
   float fd;            /* Data value */   
   int *ipa;            /* Pointer to pixel assignment array */
   int dims[3];         /* Pointer to array of array dimensions */
   int el;              /* Number of elements in array */
   int i;               /* Loop count */
   int ii;              /* Significant clump index */
   int ilev;            /* Contour index */
   int index;           /* Next PixelSet index to use */
   int j;               /* Loop index */
   int minpix;          /* Minimum number of pixels in a clump */
   int more;            /* Any remaining unsorted elements/ */
   int naxis;           /* Defines whether two pixels are neighbours or not */
   int nclump;          /* Number of clumps found */
   int nedge;           /* Number of clumps with edge pixels */
   int nthin;           /* Number of clumps that span only a single pixel */
   int nlevels;         /* Number of values in "levels" */
   int nminpix;         /* Number of clumps with < MinPix pixels */
   int skip[3];         /* Pointer to array of axis skips */

/* Initialise */
   ret = NULL;

/* Abort if an error has already occurred. */
   if( *status != SAI__OK ) return ret;

/* Say which method is being used. */
   if( ilevel > 0 ) {
      msgBlank( status );
      msgOut( "", "ClumpFind:", status );
      if( ilevel > 1 ) msgBlank( status );
   }

/* Get the AST KeyMap holding the configuration parameters for this
   algorithm. */
   if( !astMapGet0A( config, "CLUMPFIND", &cfconfig ) ) {     
      cfconfig = astKeyMap( "" );
      astMapPut0A( config, "CLUMPFIND", cfconfig, "" );
   }

/* The configuration file can optionally omit the algorithm name. In this
   case the "config" KeyMap may contain values which should really be in
   the "cfconfig" KeyMap. Add a copy of the "config" KeyMap into "cfconfig" 
   so that it can be searched for any value which cannot be found in the
   "cfconfig" KeyMap. */
   astMapPut0A( cfconfig, CUPID__CONFIG, astCopy( config ), NULL );

/* Return the instrumental smoothing FWHMs */
   beamcorr[ 0 ] = cupidConfigD( cfconfig, "FWHMBEAM", 2.0 );
   beamcorr[ 1 ] = beamcorr[ 0 ];
   if( ndim == 3 ) {
      beamcorr[ 2 ] = beamcorr[ 0 ];
      beamcorr[ velax ]= cupidConfigD( cfconfig, "VELORES", 2.0 );
   }

/* Get the value which defines whether two pixels are neighbours or not.
   The default value is equalto the number of axes in the data array. */
   naxis = cupidConfigI( cfconfig, "NAXIS", ndim );

/* Get the RMS noise level to use. */
   rms = cupidConfigD( cfconfig, "RMS", rms );

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

/* Allocate work array to hold an index value for each pixel in the
   data array. Each different index value corresponds to one of the 
   clumps returned by cupidCFScan. */
   ipa = astMalloc( sizeof( int )*el );
   if( ipa ) {

/* Initialise the index assignment array to indicate that no pixels have
   yet been assigned to any PixelSet. */
      for( i = 0; i < el; i++ ) ipa[ i ] = CUPID__CFNULL;

/* Initialise an array to hold the pointers to the PixelSet structures which 
   describe the clumps. */
      clumps = astMalloc( sizeof( CupidPixelSet *) );
      if( clumps ) clumps[ 0 ] = NULL;

/* Initialise the index used to identify the next contiguous set of
   pixels found. */
      index = 1;

/* Find the largest and mallest good data values in the supplied array. */
      maxd = VAL__MIND;
      mind = VAL__MAXD;

      if( type == CUPID__DOUBLE ) {
         for( i = 0; i < el; i++ ) {
            dd = ((double *)ipd)[ i ];
            if( dd != VAL__BADD ) {
               if( dd > maxd ) maxd = dd;
               if( dd < mind ) mind = dd;
            }
         }

      } else {
         for( i = 0; i < el; i++ ) {
            fd = ((float *)ipd)[ i ];
            if( fd != VAL__BADR ) {
               if( fd > maxd ) maxd = fd;
               if( fd < mind ) mind = fd;
            }
         }

      }

/* Get the contour levels at which to check for clumps. */
      levels = cupidCFLevels( cfconfig, maxd, mind, rms, &nlevels );

/* Initialise the largest data value in the remaining unassigned pixels. */
      maxrem = maxd;

/* Loop round all contour levels. */
      for( ilev = 0; ilev < nlevels; ilev++ ) {
         clevel = levels[ ilev ];

/* Tell the user the current contour level. */
         if( ilevel > 1 ) {
            msgSetd( "C", clevel );
            msgOut( "", "Contour level ^C:", status );
         }

/* Scan the data array at a new contour level. This extends clumps found
   at a higher contour level, and adds any new clumps found at this contour
   level. New clumps are stored at the end of the returned array. If the
   current contour level is higher than the maximum of the remaining
   unassigned pixel values, there is no point in doing this scan since it 
   will find no pixels. */
         if( clevel <= maxrem ) {
            clumps = cupidCFScan( type, ipd, ipa, el, ndim, dims, skip, 
                                  clumps, clevel, &index, naxis, ilevel,
                                  ilev < nlevels - 1, slbnd, &maxrem );

         } else if( ilevel > 2 ) {
            msgOut( "", "   No pixels found at this contour level.", status );
         }
      }

/* Mark end of contour levels. */
      if( ilevel > 1 ) msgBlank( status );

/* Get the minimum number of pixels allowed in a clump.*/
      minpix = cupidDefMinPix( ndim, beamcorr, levels[ nlevels - 1 ],
                                               levels[ nlevels - 2 ] );
      minpix = cupidConfigI( cfconfig, "MINPIX", minpix );

/* Loop round each clump */
      nminpix = 0;
      nedge = 0;
      nclump = 0;
      nthin = 0;
      for( ii = 0; ii < index; ii++ ) {
         ps = clumps[ ii ];

/* Free and count clumps which contain less than MinPix pixels, or touch an 
   edge, or have any degenerate axes. */
         if( ps ){
            if( ps->pop < minpix ){
               nminpix++;
               clumps[ ii ] = cupidCFFreePS( ps, NULL, 0 );

            } else if( ps->edge ){
               nedge++; 
               clumps[ ii ] = cupidCFFreePS( ps, NULL, 0 );

            } else if( ps->lbnd[ 0 ] == ps->ubnd[ 0 ] || 
                       ( ps->lbnd[ 1 ] == ps->ubnd[ 1 ] && ndim > 1 ) || 
                       ( ps->lbnd[ 2 ] == ps->ubnd[ 2 ] && ndim > 2 ) ) {
               nthin++;           
               clumps[ ii ] = cupidCFFreePS( ps, NULL, 0 );

            } else {
               nclump++;
            }
         }
      }

/* Tell the user how clumps are being returned. */
      if( ilevel > 0 ) {
         if( nclump == 0 ) msgOut( "", "No usable clumps found.", status );

         if( ilevel > 1 ) {
            msgSeti( "M", minpix );
            if( nminpix == 1 ) {
               msgOut( "", "1 clump rejected because it contains fewer "
                       "than MinPix (^M) pixels.", status );
            } else if( nminpix > 1 ) {
               msgSeti( "N", nminpix );
               msgOut( "", "^N clumps rejected because they contain fewer "
                       "than MinPix (^M) pixels.", status );
            }
   
            if( nedge == 1 ) {
               msgOut( "", "1 clump rejected because it touches an edge of "
                       "the data array.", status );
            } else if( nedge > 1 ) {
               msgSeti( "N", nedge );
               msgOut( "", "^N clumps rejected because they touch an edge of "
                       "the data array.", status );
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

/* Shuffle non-null clump pointers to the start of the "clumps" array,
   and count them. */
      j = 0;
      for( i = 0; i < index; i++ ) {
         if( clumps[ i ] ) {
            if( j < i ) {
               clumps[ j ] = clumps[ i ];
               clumps[ i ] = NULL;
            }
            j++;
         }
      }
      nclump = j;

/* Sort them into descending peak value order using a bubble sort algorithm. */
      more = 1;
      while( more ) {
         j--;
         more = 0;
         for( i = 0; i < j; i++ ) {
            if( clumps[ i ]->vpeak < clumps[ i + 1 ]->vpeak ) {
               ps = clumps[ i + 1 ];
               clumps[ i + 1 ] = clumps[ i ];
               clumps[ i ] = ps;
               more = 1;
            }
         }
      }

/* Loop round each clump, creating an NDF to describe the clump. These are
   stored in the returned HDS object. */
      for( ii = 0; ii < nclump; ii++ ) {
         ps = clumps[ ii ];
         ret = cupidNdfClump( type, ipd, ipa, el, ndim, dims,
                              skip, slbnd, ps->index, ps->lbnd,
                              ps->ubnd, NULL, ret, 
                              cupidConfigI( cfconfig, "MAXBAD", 4 ) );
      }

/* Free resources */
      for( i = 0; i < index; i++ ) {
         if( clumps[ i ] ) clumps[ i ] = cupidCFFreePS( clumps[ i ], NULL, 0 );
      }
      clumps = astFree( clumps );
      levels = astFree( levels );

   }

/* Remove the secondary KeyMap added to the KeyMap containing configuration 
   parameters for this algorithm. This prevents the values in the secondary 
   KeyMap being written out to the CUPID extension when cupidStoreConfig is 
   called. */
   astMapRemove( cfconfig, CUPID__CONFIG );

/* Free resources */
   ipa = astFree( ipa );
   cfconfig = astAnnul( cfconfig );

   for( i = 0; i < cupid_ps_cache_size; i++ ) {
      cupid_ps_cache[ i ] = cupidCFDeletePS( cupid_ps_cache[ i ] );
   }
   cupid_ps_cache = astFree( cupid_ps_cache );
   cupid_ps_cache_size = 0;

/* Return the list of clump NDFs. */
   return ret;

}

