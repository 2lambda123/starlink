#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>

#include "star/slalib.h"
#include "sae_par.h"
#include "prm_par.h"
#include "ast.h"
#include "ndf.h"
#include "Ers.h"

#include "sc2ast.h"

/* True if the data array is configured (COL, ROW) [the new way]
   Undefined or false if (ROW,COL) order.
   Should match the definition of ROW and COL index from sc2store.c
   Remove COLROW once we have finished testing.
 */
#define COLROW 1

/* The CURRENT macro specifies the index of the current Frame in the
   FrameSet returned by sc2ast_createwcs(2). This current Frame is
   re-established (in case it was changed by the calling code) each time
   sc2ast_createwcs(2) is called. */
#define CURRENT 3


static char errmess[132];              /* For DRAMA error messages */

#define MM2RAD 2.4945e-5               /* scale at array in radians */
#define MM2RAD_NEW1 MM2RAD*1.0383      /* MM2RAD for use with NEW1 distortion */
#define MM2RAD_NEW2 MM2RAD*0.9975      /* MM2RAD for use with NEW2 distortion */
#define MM2RAD_NEW3 MM2RAD*1.0084      /* MM2RAD for use with NEW3 distortion */

#define PIBY2 1.57079632679
#define PI 2*PIBY2
#define PIX2MM 1.135                   /* pixel interval in mm */
const double RAD2DEG = 90.0 / PIBY2;   /* Convert Radians to degrees */

/*+ sc2ast_createwcs - create WCS description using a static cache */

void sc2ast_createwcs
(
int subnum,             /* subarray number, 0-7 (given). If -1 is
                           supplied the cached AST objects will be freed. */
const JCMTState *state, /* Current telescope state (time, pointing etc.) */
const double instap[2], /* Offset of subarray in the focal plane */
const double telpos[3], /* Geodetic W Lon/Lat/Alt of telescope (deg/deg/ign.)*/
AstFrameSet **fset,     /* constructed frameset (returned) */
int *status             /* global status (given and returned) */
)
/* Method :
     Build an AST frameset containing mappings from the original GRID
     coordinates of the bolometers to celestial coordinates. This
     includes the rotations and reflections relevant to each subarray and
     the distortion imposed by the SCUBA-2 optics.

     This function allocates static resources (AST object pointers) which
     should be freed when no longer needed by calling this function with
     "subnum" set to -1. In this is done, the cached resources are freed
     and this function returns without further action, returning a NULL
     pointer in "*fset".

     If telescope state is NULL, a focal plane frameset will be returned.

   Notes :
     - No changes should be made to the returned FrameSet since any such
     changes could affect future use of the FrameSet by this function.
     The one exception is that the current Frame in the returned FrameSet
     may safely be changed - this function will re-instate the original
     current Frame each time it is called. If any other changes need to
     be made to the returned FrameSet, then the changes should be applied
     to a deep copy of the returned FrameSet (produced using astCopy),
     rather than to the returned FrameSet itself.

     - Because of its use of a static cache, this function should be used
     only when thread-safety is not an issue. For threaded applications,
     use sc2ast_createwcs2 instead.

     - After the first call the cached part of the frameset contains information
     specific to the SCUBA-2 instrument, observatory location etc. If you
     wish to subsequently calculate framesets for a different instrument
     or observatory location ensure that you first clear the cache by
     setting subnum=-1.

   Authors :
     B.D.Kelly (bdk@roe.ac.uk)
     Tim Jenness (timj@jach.hawaii.edu)
     D.S. Berry (dsb@ast.man.ac.uk)
     E.Chapin (echapin@phas.ubc.ca)

   History :
     01Apr2005 : original (bdk)
     21Apr2005 : update comments and add labels to some of the frames
                 (bdk)
     25Apr2005 : revise polynomials and plate scale (bdk)
     27Apr2005 : put in subarray orientations (bdk)
     10May2005 : remember xoff and yoff are in pixel units (bdk)
     10May2005 : fix syntax error in xoff and add more frame names (bdk)
     18May2005 : Check subnam range (timj)
     20Jun2005 : add zpixelframe (bdk)
     23Aug2005 : De-projection (Az,El) rather than (RA,Dec), and leave
                 final SkyFrame describing (Az,El). Also, replace supplied
                 (ra,dec) parameters by (az,el,tai). (dsb)
     07Nov2005 : Remove duplicate elevation argument (timj)
                 Remove unused parallactic angle argument (timj)
     08Nov2005 : Use RAD2DEG global rather than 90*PIBY2 (timj)
     27Jan2006 : Use ErsRep rather than printf (timj)
     28Jan2006 : Annul all the mappings/frames to fix terrible leak (timj)
     07Feb2006 : Cache Mappings which do not depend on "az", "el" or "tai".
                 Do not create extra Frames unless specifically requested.
                 Use AST contexts for handling the annulling of AST objects.
                 Avoid use of FitsChans for extra speed. (dsb)
     17Feb2006 : Combine Nasmyth->Cassegrain rotation with the rotations
                    performed after the tangent plane->spherical projection.
                 Cache the SkyFrame used to represent AzEl coords.
                 Cache the FrameSets returned for each subnum
                 Do away with the facility for including intermediate
                    Frames (dsb)
     1Mar2006  : Check for (subnum==-1) before checking inherited status (dsb)
     2Mar2006  : const constant arrays (timj)
     12Apr2006 : added jig_az_x/y, remove extra_frames from interface (ec)
     18Apr2006 : Use a ShiftMap to apply jig_az_x/y (dsb)
     19Apr2006 : Only use shiftmap if non-zero jig_az_x/y (ec)
     7Aug2006  : Correct rotation matrix in sc2ast_maketanmap (dsb)
     7Aug2006  : Removed sc2ast_createwcs_compat + related kludges (ec)
     10Aug2006 : More corrections to the rotation matrix in sc2ast_maketanmap (dsb)
     10Aug2006 : Added "rot" parameter to sc2ast_maketanmap (dsb)
     07Sep2006 : Added "telpos" and "instap" arguments
                 JCMTState now used for time/pointing (EC)
     19Dec2006 : If "state" is NULL return the focal plane frameset (TJ)
     20Feb2007 : Clear the cache if instap is changed.
     23Jul2008 : Set SkyRef (TJ)
     10Sep2008 : Renamed as sc2ast_createwcs2. This function is now just
                 a wrapper for sc2ast_createwcs2. (dsb)
*/
{
   static sc2astCache *cache = NULL;
   cache = sc2ast_createwcs2( subnum, state, 0.0, instap, telpos, fset,
                              cache, status );
}



/*+ sc2ast_createwcs2 - create WCS description using a supplied cache. */

sc2astCache *sc2ast_createwcs2
(
int subnum,             /* subarray number, 0-7 (given). If -1 is
                           supplied the cached AST objects will be freed. */
const JCMTState *state, /* Current telescope state (time, pointing etc.) */
double dut1,            /* UT1-UTC (seconds) */
const double instap[2], /* Offset of subarray in the focal plane */
const double telpos[3], /* Geodetic W Lon/Lat/Alt of telescope (deg/deg/ign.)*/
AstFrameSet **fset,     /* constructed frameset (returned) */
sc2astCache *cache,     /* A pointer to a structure holding cached info */
int *status             /* global status (given and returned) */
)
/* Method :
     Build an AST frameset containing mappings from the original GRID
     coordinates of the bolometers to celestial coordinates. This
     includes the rotations and reflections relevant to each subarray and
     the distortion imposed by the SCUBA-2 optics.

     This function uses a supplied structure to hold a cache of information
     that does not change between invocations. If "cache" is supplied as
     NULL, then memory for a new structure is allocated and initialised, and
     a pointer to it is returned. The contents of the returned structure
     should not be changed outside this function.

     The cache should be freed by calling this function with "subnum" set
     to -1. In this is done, the cached resources are freed and this
     function returns without further action, returning a NULL pointer in
     "*fset", and a NULL pointer for the function value.

     If telescope state is NULL, a focal plane frameset will be returned.

   Notes :
     - No changes should be made to the returned FrameSet since any such
     changes could affect future use of the FrameSet by this function.
     The one exception is that the current Frame in the returned FrameSet
     may safely be changed - this function will re-instate the original
     current Frame each time it is called. If any other changes need to
     be made to the returned FrameSet, then the changes should be applied
     to a deep copy of the returned FrameSet (produced using astCopy),
     rather than to the returned FrameSet itself.

     - After the first call the cached part of the frameset contains information
     specific to the SCUBA-2 instrument, observatory location etc. If you
     wish to subsequently calculate framesets for a different instrument
     or observatory location ensure that you first clear the cache by
     setting subnum=-1.

   Authors :
     B.D.Kelly (bdk@roe.ac.uk)
     Tim Jenness (timj@jach.hawaii.edu)
     D.S. Berry (dsb@ast.man.ac.uk)
     E.Chapin (echapin@phas.ubc.ca)
     P.Friberg (friberg@jach.hawaii.edu)

   History :
     01Apr2005 : original (bdk)
     21Apr2005 : update comments and add labels to some of the frames
                 (bdk)
     25Apr2005 : revise polynomials and plate scale (bdk)
     27Apr2005 : put in subarray orientations (bdk)
     10May2005 : remember xoff and yoff are in pixel units (bdk)
     10May2005 : fix syntax error in xoff and add more frame names (bdk)
     18May2005 : Check subnam range (timj)
     20Jun2005 : add zpixelframe (bdk)
     23Aug2005 : De-projection (Az,El) rather than (RA,Dec), and leave
                 final SkyFrame describing (Az,El). Also, replace supplied
                 (ra,dec) parameters by (az,el,tai). (dsb)
     07Nov2005 : Remove duplicate elevation argument (timj)
                 Remove unused parallactic angle argument (timj)
     08Nov2005 : Use RAD2DEG global rather than 90*PIBY2 (timj)
     27Jan2006 : Use ErsRep rather than printf (timj)
     28Jan2006 : Annul all the mappings/frames to fix terrible leak (timj)
     07Feb2006 : Cache Mappings which do not depend on "az", "el" or "tai".
                 Do not create extra Frames unless specifically requested.
                 Use AST contexts for handling the annulling of AST objects.
                 Avoid use of FitsChans for extra speed. (dsb)
     17Feb2006 : Combine Nasmyth->Cassegrain rotation with the rotations
                    performed after the tangent plane->spherical projection.
                 Cache the SkyFrame used to represent AzEl coords.
                 Cache the FrameSets returned for each subnum
                 Do away with the facility for including intermediate
                    Frames (dsb)
     1Mar2006  : Check for (subnum==-1) before checking inherited status (dsb)
     2Mar2006  : const constant arrays (timj)
     12Apr2006 : added jig_az_x/y, remove extra_frames from interface (ec)
     18Apr2006 : Use a ShiftMap to apply jig_az_x/y (dsb)
     19Apr2006 : Only use shiftmap if non-zero jig_az_x/y (ec)
     7Aug2006  : Correct rotation matrix in sc2ast_maketanmap (dsb)
     7Aug2006  : Removed sc2ast_createwcs_compat + related kludges (ec)
     10Aug2006 : More corrections to the rotation matrix in sc2ast_maketanmap (dsb)
     10Aug2006 : Added "rot" parameter to sc2ast_maketanmap (dsb)
     07Sep2006 : Added "telpos" and "instap" arguments
                 JCMTState now used for time/pointing (EC)
     19Dec2006 : If "state" is NULL return the focal plane frameset (TJ)
     20Feb2007 : Clear the cache if instap is changed.
     23Jul2008 : Set SkyRef (TJ)
     10Sep2008 : Original created by renaming sc2ast_createwcs (dsb)
     20081119  : Modified the conversion for in the Nasmyth coordinate
                 definitions. (PF)
     15Dec2008 : Clone the cached SkyFrame instead of deep copying it
                 (it's much faster). (DSB)
     18Dec2008 : dut1 is now an argument (TIMJ)
     28Oct2009 : Add a Frame with Domain "BOLO" to returned FrameSet (DSB)
     30Oct2009 : Report an error if the number of base or current Frame
                 axes in the cached FrameSet has been changed.
     30Oct2009 : Report an error if the number of base or current Frame
                 axes in the cached FrameSet has been changed. (DSB)
     26Nov2009 : Allow different polynomial distortions to be selected using
                 the environment variable "SMURF_DISTORTION" - set it to
                 "NEW" to get the new (experimental) correction; set it to
                 "NONE" to get no correction; set it to anything else (or
                 leave it unset) to get the original correction. (DSB)
     3Dec2009  : Move linear terms in NEW distortion from PolyMap into
                 MM2RAD. (DSB)
     4Dec2009  : Rename NEW to NEW1, and add NEW2 (improved pre-mirror-fix
                 distortion map), and NEW3 (initial post-mirror-fix
                 distortion map). "NEW" gets translated to NEW2 or NEW3
                 depending on the date (from state->tcs_tai). (DSB)
     8Dec2009  : Use "DATE" instead of "NEW" and make it the default. Add
                 ORIGINAL as an option (to get the original distortion).
                 Transfer Ed's 0.92 factor out of MM2RAD and into MM2RAD_NEW* -
                 this will leave the NEW* mappings unchanged, but will
                 change ORIGINAL. Report an error if SMURF_DISTORTION has
                 an unknown value.
     26Jan2010 : Reset the current Frame in the cached FrameSet each time
                 this function is called, in case the caller has changed
                 it. (DSB)
     09Mar2010 : Check SMU values are not VAL__BADD before using them.
*/
{

   AstMapping *azelmap;
   AstFrame *bfrm;
   AstMapping *bmap;
   AstMapping *mapping;
   AstMatrixMap *rotmap;
   AstPolyMap *polymap;
   AstShiftMap *shiftmap;
   AstZoomMap *radmap;
   AstZoomMap *zoommap;
   AstShiftMap *zshiftmap;
   double shifts[ 2 ];
   AstShiftMap *instapmap;
   AstShiftMap *jigglemap;
   const char *distortion;
   sc2astCache *result;
   int isub;
#if COLROW
   AstPermMap *permmap;
   int perm[ 2 ];
#endif
   int nin;
   int nout;
   double r;                       /* subarray angle */
   double rot[4];                  /* rotation matrix */
   const double rotangle[8] =
     { 0.0, PIBY2, 2*PIBY2, 3*PIBY2, 3*PIBY2, 2*PIBY2, PIBY2, 0.0 };
   double shift[2];
   double zshift[2];

/* Codes identifying the available optical distortion maps */
   enum distortion_codes {
      BAD_DISTORTION,      /* A bad distortion code */
      DATE_DISTORTION,     /* Appropriate distortion for date of observation */
      ORIGINAL_DISTORTION, /* Original ray-traced distortion */
      NONE_DISTORTION,     /* Assume no distortion */
      NEW1_DISTORTION,     /* First estimate prior to C2 mirror fix */
      NEW2_DISTORTION,     /* Second estimate prior to C2 mirror fix */
      NEW3_DISTORTION      /* First estimate after C2 mirror fix */
   } idistortion;

/* xoff and yoff are the distance in pixel units from the tracking centre
   to the [0][0] pixel in a subarray */

/* Original values */
   /*    s8a    s8b     s8c   s8d    s4a    s4b    s4c    s4d */
   const double xoff[8] =
      { -41.5,   33.5, 41.5, -33.5, -41.5,  33.5,  41.5, -33.5 };
   const double yoff[8] =
      { -33.5,  -41.5, 33.5,  41.5,  33.5,  41.5, -33.5, -41.5 };


/* Values modified to reduce errors implied by NEW1 distortion (initial
   pre-C2-mirror-fix distortion). */
   /*    s8a    s8b     s8c   s8d    s4a    s4b    s4c    s4d */
   const double xoff_NEW1[8] =
      { -41.5,   33.5, 41.5, -32.83, -41.54,  33.5,  41.5, -33.5 };
   const double yoff_NEW1[8] =
      { -33.5,  -41.5, 33.5,  40.48,  33.47,  41.5, -33.5, -41.5 };


/* Values modified to reduce errors implied by NEW2 distortion (improved
   pre-C2-mirror-fix distortion). */
   /*    s8a    s8b     s8c   s8d    s4a    s4b    s4c    s4d */
   const double xoff_NEW2[8] =
      { -41.5,   33.5, 41.5, -32.62, -41.45,  33.5,  41.5, -33.5 };
   const double yoff_NEW2[8] =
      { -33.5,  -41.5, 33.5,  40.73,  33.68,  41.5, -33.5, -41.5 };


/* Values modified to reduce errors implied by NEW3 distortion (initial
   post-C2-mirror-fix distortion). */
   /*    s8a    s8b     s8c   s8d    s4a    s4b    s4c    s4d */
   const double xoff_NEW3[8] =
      { -41.5,   33.5, 41.5, -31.46, -40.39,  33.5,  41.5, -33.5 };
   const double yoff_NEW3[8] =
      { -33.5,  -41.5, 33.5,  40.55,  33.5,  41.5, -33.5, -41.5 };




/* Distortion Mappings. A specific version of the distortion Mapping can
   be selected by setting a value for the SMURF_DISTORTION environment
   variable. If SMURF_DISTORTION is left unset, a distortion appropriate for
   the date of observation is used. If SMURF_DISTORTION is set to "ORIGINAL"
   the distortion used is the original least-squares fit to ray tracing
   provided by Tully:

   x = 0.30037 + 0.99216 * X - 1.4428e-4 * X^2 - 3.612e-6 * X^3
       + 9.6e-4 * Y - 8.628e-6 * Y^2 - 2.986e-7 * Y^3

   y = 0.6518 + 1.0488e-3 * X - 6.58e-5 * X^2 -1.63e-7 * X^3
       + 0.98645 * Y - 2.218e-4 * Y^2 - 1.082e-6 * Y^3

   X = -0.30461 + 1.0079 * x + 1.502e-4 * x^2 + 3.757e-6 * x^3
       - 9.73e-4 * y + 9.79e-6 * y^2 + 3.135e-7 * y^3

   Y = -0.662328 - 1.082e-3 * x + 6.956e-5 * x^2 + 1.676e-7 * x^3
       + 1.0135 * y + 2.321e-4 * y^2 + 1.221e-6 * y^3


   X and Y are in the distorted image, x and y are undistorted (Nasmyth).
   All units are mm. */

/* Forward coefficients are from FRAME850 to Nasmyth */
   const double coeff_f[] =
               {
/* x-coordinate */
               0.30037,     1.0, 0.0, 0.0,
               0.99216,     1.0, 1.0, 0.0,
               -1.4428e-4,  1.0, 2.0, 0.0,
               -3.612e-6,   1.0, 3.0, 0.0,
               9.6e-4,      1.0, 0.0, 1.0,
               -8.628e-6,   1.0, 0.0, 2.0,
               -2.986e-7,   1.0, 0.0, 3.0,
/* y-coordinate */
               0.6518,      2.0, 0.0, 0.0,
               1.0488e-3,   2.0, 1.0, 0.0,
               -6.58e-5,    2.0, 2.0, 0.0,
               -1.63e-7,    2.0, 3.0, 0.0,
               0.98645,     2.0, 0.0, 1.0,
               -2.218e-4,   2.0, 0.0, 2.0,
               -1.082e-6,   2.0, 0.0, 3.0
               };

/* Inverse coefficients are from Nasmyth to FRAME850 */

   const double coeff_i[] =
               {
/* X-coordinate */
               -0.30461,    1.0, 0.0, 0.0,
               1.0079,      1.0, 1.0, 0.0,
               1.502e-4,    1.0, 2.0, 0.0,
               3.757e-6,    1.0, 3.0, 0.0,
               -9.73e-4,    1.0, 0.0, 1.0,
               9.79e-6,     1.0, 0.0, 2.0,
               3.135e-7,    1.0, 0.0, 3.0,
/* Y-coordinate */
               -0.662328,   2.0, 0.0, 0.0,
               -1.082e-3,   2.0, 1.0, 0.0,
               6.956e-5,    2.0, 2.0, 0.0,
               1.676e-7,    2.0, 3.0, 0.0,
               1.0135,      2.0, 0.0, 1.0,
               2.321e-4,    2.0, 0.0, 2.0,
               1.221e-6,    2.0, 0.0, 3.0
               };



/* SMURF_DISTORTION = "NEW1": determined from bolomap approach, using
   s4a and s8d data from 20091027 obs 00009 and 00011 (Mars). */
/* ------------------------------------------------------------ */


/* SCUBA-2 PolyMap cooefficients. Forward coefficients are from
   FRAME850 to Nasmyth */

/* Forward transformation coefficients... */
   int ncoeff_f_NEW1 = 20;
   const double coeff_f_NEW1[] = {

/* X-coordinate */
               1.9472      ,     1.0, 0.0, 0.0,
               0.98616     ,     1.0, 1.0, 0.0,
               0.00076856  ,     1.0, 2.0, 0.0,
               2.6286e-06  ,     1.0, 3.0, 0.0,
               -0.0026423  ,     1.0, 0.0, 1.0,
               -0.0010256  ,     1.0, 1.0, 1.0,
               -8.2017e-06 ,     1.0, 2.0, 1.0,
               -0.0013418  ,     1.0, 0.0, 2.0,
               -7.2801e-06 ,     1.0, 1.0, 2.0,
               1.9304e-05  ,     1.0, 0.0, 3.0,

/* Y-coordinate */
               -1.9939     ,     2.0, 0.0, 0.0,
               -0.038042   ,     2.0, 1.0, 0.0,
               -0.0010748  ,     2.0, 2.0, 0.0,
               -1.8892e-05 ,     2.0, 3.0, 0.0,
               1.0138      ,     2.0, 0.0, 1.0,
               0.00099811  ,     2.0, 1.0, 1.0,
               -1.8696e-06 ,     2.0, 2.0, 1.0,
               -0.0023207  ,     2.0, 0.0, 2.0,
               -7.4961e-06 ,     2.0, 1.0, 2.0,
               1.7533e-05  ,     2.0, 0.0, 3.0,
            };




/* Inverse transformation coefficients... */
   int ncoeff_i_NEW1 = 42;
   const double coeff_i_NEW1[] = {

/* X-coordinate */
               -1.9741     ,     1.0, 0.0, 0.0,
               1.019       ,     1.0, 1.0, 0.0,
               -0.00075477 ,     1.0, 2.0, 0.0,
               -4.3529e-07 ,     1.0, 3.0, 0.0,
               4.0632e-08  ,     1.0, 4.0, 0.0,
               2.0397e-10  ,     1.0, 5.0, 0.0,
               0.0063957   ,     1.0, 0.0, 1.0,
               0.0011986   ,     1.0, 1.0, 1.0,
               1.1339e-05  ,     1.0, 2.0, 1.0,
               9.5836e-08  ,     1.0, 3.0, 1.0,
               7.0688e-10  ,     1.0, 4.0, 1.0,
               0.0011652   ,     1.0, 0.0, 2.0,
               9.3048e-07  ,     1.0, 1.0, 2.0,
               -1.3648e-07 ,     1.0, 2.0, 2.0,
               -2.253e-09  ,     1.0, 3.0, 2.0,
               -8.2069e-06 ,     1.0, 0.0, 3.0,
               2.4492e-07  ,     1.0, 1.0, 3.0,
               6.1949e-10  ,     1.0, 2.0, 3.0,
               -2.7475e-07 ,     1.0, 0.0, 4.0,
               -1.3959e-09 ,     1.0, 1.0, 4.0,
               1.3486e-09  ,     1.0, 0.0, 5.0,

/* Y-coordinate */
               1.9075      ,     2.0, 0.0, 0.0,
               0.032459    ,     2.0, 1.0, 0.0,
               0.0009227   ,     2.0, 2.0, 0.0,
               1.6425e-05  ,     2.0, 3.0, 0.0,
               -8.6639e-08 ,     2.0, 4.0, 0.0,
               -1.7151e-10 ,     2.0, 5.0, 0.0,
               0.99723     ,     2.0, 0.0, 1.0,
               -0.00079238 ,     2.0, 1.0, 1.0,
               1.1698e-05  ,     2.0, 2.0, 1.0,
               2.0649e-07  ,     2.0, 3.0, 1.0,
               8.2633e-10  ,     2.0, 4.0, 1.0,
               0.0021766   ,     2.0, 0.0, 2.0,
               2.2222e-06  ,     2.0, 1.0, 2.0,
               1.0451e-07  ,     2.0, 2.0, 2.0,
               -2.9258e-10 ,     2.0, 3.0, 2.0,
               -6.1572e-06 ,     2.0, 0.0, 3.0,
               7.2571e-08  ,     2.0, 1.0, 3.0,
               -2.3365e-09 ,     2.0, 2.0, 3.0,
               -2.2948e-07 ,     2.0, 0.0, 4.0,
               -5.5674e-10 ,     2.0, 1.0, 4.0,
               1.133e-09   ,     2.0, 0.0, 5.0,
            };


/* SMURF_DISTORTION = "NEW2": determined from bolomap approach, using
   s4a and s8d data from 20091027_00009, 20091027_00011, 20091201_00098
   and 20091201_00100 (with improved scripts). */
/* ------------------------------------------------------------ */


/* SCUBA-2 PolyMap cooefficients. Forward coefficients are from
   FRAME850 to Nasmyth */

/* Forward transformation coefficients... */
   int ncoeff_f_NEW2 = 20;
   const double coeff_f_NEW2[] = {

/* X-coordinate */
               1.7777      ,     1.0, 0.0, 0.0,
               0.99678     ,     1.0, 1.0, 0.0,
               0.00010172  ,     1.0, 2.0, 0.0,
               -7.0709e-07 ,     1.0, 3.0, 0.0,
               -0.0070205  ,     1.0, 0.0, 1.0,
               -0.00036612 ,     1.0, 1.0, 1.0,
               3.117e-06   ,     1.0, 2.0, 1.0,
               -0.00046285 ,     1.0, 0.0, 2.0,
               -5.0563e-06 ,     1.0, 1.0, 2.0,
               4.8072e-06  ,     1.0, 0.0, 3.0,

/* Y-coordinate */
               -1.518      ,     2.0, 0.0, 0.0,
               -0.01234    ,     2.0, 1.0, 0.0,
               6.2232e-05  ,     2.0, 2.0, 0.0,
               -3.1321e-07 ,     2.0, 3.0, 0.0,
               1.0032      ,     2.0, 0.0, 1.0,
               0.00079397  ,     2.0, 1.0, 1.0,
               7.7788e-06  ,     2.0, 2.0, 1.0,
               -0.00045257 ,     2.0, 0.0, 2.0,
               5.7306e-06  ,     2.0, 1.0, 2.0,
               -2.6759e-06 ,     2.0, 0.0, 3.0,
            };

/* Inverse transformation coefficients... */
   int ncoeff_i_NEW2 = 42;
   const double coeff_i_NEW2[] = {

/* X-coordinate */
               -1.773      ,     1.0, 0.0, 0.0,
               1.0043      ,     1.0, 1.0, 0.0,
               -0.00010866 ,     1.0, 2.0, 0.0,
               6.2202e-07  ,     1.0, 3.0, 0.0,
               -8.9563e-10 ,     1.0, 4.0, 0.0,
               -5.1578e-12 ,     1.0, 5.0, 0.0,
               0.0076309   ,     1.0, 0.0, 1.0,
               0.00039363  ,     1.0, 1.0, 1.0,
               -3.568e-06  ,     1.0, 2.0, 1.0,
               4.7332e-09  ,     1.0, 3.0, 1.0,
               5.6723e-11  ,     1.0, 4.0, 1.0,
               0.00045037  ,     1.0, 0.0, 2.0,
               4.8826e-06  ,     1.0, 1.0, 2.0,
               -1.7942e-08 ,     1.0, 2.0, 2.0,
               -3.4355e-11 ,     1.0, 3.0, 2.0,
               -4.6588e-06 ,     1.0, 0.0, 3.0,
               -6.7703e-09 ,     1.0, 1.0, 3.0,
               -2.1211e-10 ,     1.0, 2.0, 3.0,
               7.1082e-09  ,     1.0, 0.0, 4.0,
               4.322e-10   ,     1.0, 1.0, 4.0,
               -1.5486e-10 ,     1.0, 0.0, 5.0,

/* Y-coordinate */
               1.4942      ,     2.0, 0.0, 0.0,
               0.011475    ,     2.0, 1.0, 0.0,
               -8.4666e-05 ,     2.0, 2.0, 0.0,
               3.3269e-07  ,     2.0, 3.0, 0.0,
               -3.7564e-10 ,     2.0, 4.0, 0.0,
               -1.1094e-11 ,     2.0, 5.0, 0.0,
               0.99968     ,     2.0, 0.0, 1.0,
               -0.00077605 ,     2.0, 1.0, 1.0,
               -7.8063e-06 ,     2.0, 2.0, 1.0,
               9.384e-09   ,     2.0, 3.0, 1.0,
               2.3439e-11  ,     2.0, 4.0, 1.0,
               0.00046731  ,     2.0, 0.0, 2.0,
               -7.1745e-06 ,     2.0, 1.0, 2.0,
               1.3424e-08  ,     2.0, 2.0, 2.0,
               4.5287e-10  ,     2.0, 3.0, 2.0,
               3.0534e-06  ,     2.0, 0.0, 3.0,
               -2.5124e-08 ,     2.0, 1.0, 3.0,
               -9.0546e-11 ,     2.0, 2.0, 3.0,
               -3.0955e-09 ,     2.0, 0.0, 4.0,
               -3.0071e-10 ,     2.0, 1.0, 4.0,
               1.6281e-10  ,     2.0, 0.0, 5.0,
            };


/* SMURF_DISTORTION = "NEW3": determined from bolomap approach, using
   s4a and s8d data from 20091203_00092, 20091203_00038 and 20091203_00039
   (post C2 mirror fix). */
/* ------------------------------------------------------------ */

/* SCUBA-2 PolyMap cooefficients. Forward coefficients are from
   FRAME850 to Nasmyth */

/* Forward transformation coefficients... */
   int ncoeff_f_NEW3 = 20;
   const double coeff_f_NEW3[] = {

/* X-coordinate */
               2.1329      ,     1.0, 0.0, 0.0,
               0.9892      ,     1.0, 1.0, 0.0,
               0.00038764  ,     1.0, 2.0, 0.0,
               8.9905e-06  ,     1.0, 3.0, 0.0,
               -0.01555    ,     1.0, 0.0, 1.0,
               0.00045098  ,     1.0, 1.0, 1.0,
               1.2651e-05  ,     1.0, 2.0, 1.0,
               0.00020844  ,     1.0, 0.0, 2.0,
               1.8346e-07  ,     1.0, 1.0, 2.0,
               -2.5748e-06 ,     1.0, 0.0, 3.0,

/* Y-coordinate */
               -2.249      ,     2.0, 0.0, 0.0,
               -0.038506   ,     2.0, 1.0, 0.0,
               -0.00086302 ,     2.0, 2.0, 0.0,
               -7.4832e-06 ,     2.0, 3.0, 0.0,
               1.0108      ,     2.0, 0.0, 1.0,
               0.0012899   ,     2.0, 1.0, 1.0,
               2.5747e-05  ,     2.0, 2.0, 1.0,
               -0.00045431 ,     2.0, 0.0, 2.0,
               1.4096e-06  ,     2.0, 1.0, 2.0,
               2.5223e-06  ,     2.0, 0.0, 3.0,
            };



/* Inverse transformation coefficients... */
   int ncoeff_i_NEW3 = 42;
   const double coeff_i_NEW3[] = {

/* X-coordinate */
               -2.123      ,     1.0, 0.0, 0.0,
               1.0121      ,     1.0, 1.0, 0.0,
               -0.00037464 ,     1.0, 2.0, 0.0,
               -9.9457e-06 ,     1.0, 3.0, 0.0,
               5.8683e-10  ,     1.0, 4.0, 0.0,
               1.4293e-10  ,     1.0, 5.0, 0.0,
               0.015673    ,     1.0, 0.0, 1.0,
               -0.00044873 ,     1.0, 1.0, 1.0,
               -1.3223e-05 ,     1.0, 2.0, 1.0,
               6.2626e-08  ,     1.0, 3.0, 1.0,
               1.0483e-09  ,     1.0, 4.0, 1.0,
               -0.00019079 ,     1.0, 0.0, 2.0,
               2.8369e-07  ,     1.0, 1.0, 2.0,
               3.9446e-08  ,     1.0, 2.0, 2.0,
               5.4352e-10  ,     1.0, 3.0, 2.0,
               2.4257e-06  ,     1.0, 0.0, 3.0,
               -3.7609e-09 ,     1.0, 1.0, 3.0,
               -2.4672e-10 ,     1.0, 2.0, 3.0,
               3.378e-09   ,     1.0, 0.0, 4.0,
               -9.774e-11  ,     1.0, 1.0, 4.0,
               -2.1984e-11 ,     1.0, 0.0, 5.0,

/* Y-coordinate */
               2.1555      ,     2.0, 0.0, 0.0,
               0.032547    ,     2.0, 1.0, 0.0,
               0.0007184   ,     2.0, 2.0, 0.0,
               4.8141e-06  ,     2.0, 3.0, 0.0,
               -5.8353e-08 ,     2.0, 4.0, 0.0,
               -4.6928e-10 ,     2.0, 5.0, 0.0,
               0.99432     ,     2.0, 0.0, 1.0,
               -0.0011474  ,     2.0, 1.0, 1.0,
               -2.4441e-05 ,     2.0, 2.0, 1.0,
               6.6223e-08  ,     2.0, 3.0, 1.0,
               8.9367e-10  ,     2.0, 4.0, 1.0,
               0.00040726  ,     2.0, 0.0, 2.0,
               -3.8309e-06 ,     2.0, 1.0, 2.0,
               5.147e-09   ,     2.0, 2.0, 2.0,
               9.4018e-10  ,     2.0, 3.0, 2.0,
               -1.7737e-06 ,     2.0, 0.0, 3.0,
               2.5759e-08  ,     2.0, 1.0, 3.0,
               4.1244e-10  ,     2.0, 2.0, 3.0,
               -8.1515e-09 ,     2.0, 0.0, 4.0,
               -1.1878e-10 ,     2.0, 1.0, 4.0,
               9.9128e-12  ,     2.0, 0.0, 5.0,
            };








/* Check the sub-array number. If it is -1, free the cached AST objects and
   the cache structure itself, and then return. Otherwise, report an error
   if the value is illegal. We do this before checking the inherited status
   so that the memory is freed even if an error has occurred. */
   if( subnum == -1 ) {
      if( cache ) {
         for( subnum = 0; subnum < 8; subnum++ ) {
            if( cache->map[ subnum ] ) {
               cache->map[ subnum ] = astAnnul( cache->map[ subnum ] );
            }
            if( cache->frameset[ subnum ] ) {
               cache->frameset[ subnum ] = astAnnul( cache->frameset[ subnum ] );
            }
         }

         if( cache->azel[ 0 ] ) cache->azel[ 0 ] = astAnnul( cache->azel[ 0 ] );
         if( cache->azel[ 1 ] ) cache->azel[ 1 ] = astAnnul( cache->azel[ 1 ] );
         if( cache->skyframe ) cache->skyframe = astAnnul( cache->skyframe );

         cache = astFree( cache );
      }


      return NULL;

   } else if ( subnum < 0 || subnum > 7 ) {
     *status = SAI__ERROR;
     sprintf( errmess, "Sub array number '%d' out of range\n", subnum );
     ErsRep( 0, status, errmess );
     return cache;

   }

/* Now initialise the returned pointers and check the inherited status */
   *fset = AST__NULL;
   result = cache;
   if ( *status != SAI__OK ) return result;

/* Start an AST context. This means we do not need to worry about
   annulling AST objects. Note, there should be no "return" statements
   before the matching call to astEnd. */
   astBegin;

/* If no cache was supplied, allocate memory for a new cache and
   initialise it. */
   if( ! cache ) {
      cache = astMalloc( sizeof( sc2astCache ) );
      if( !cache ) return result;
      for( isub = 0; isub < 8; isub++ ) {
         cache->map[ isub ] = NULL;
         cache->frameset[ isub ] = NULL;
         cache->instap_x[ isub ] = AST__BAD;
         cache->instap_y[ isub ] = AST__BAD;
      }
      cache->azel[ 0 ] = NULL;
      cache->azel[ 1 ] = NULL;
      cache->skyframe = NULL;

/* When this function exits, return a pointer to the newly allocated cache
   structure. */
      result = cache;
   }

/* See if either of the instap values has changed. If so, clear the cache
   for the requested subarray since the cached Mapping will have the old
   instap values hard-wired into it. */
   if( ( instap && ( instap[ 0 ] != cache->instap_x[ subnum ] ||
                     instap[ 1 ] != cache->instap_y[ subnum ] ) ) ||
       ( !instap && ( 0.0 != cache->instap_x[ subnum ] ||
                      0.0 != cache->instap_y[ subnum ] ) ) ){

      if( cache->map[ subnum ] ) {
         cache->map[ subnum ] = astAnnul( cache->map[ subnum ] );
      }
      if( cache->frameset[ subnum ] ) {
         cache->frameset[ subnum ] = astAnnul( cache->frameset[ subnum ] );
      }
   }

/* The Mapping from GRID coords to AzEl coords can be thought of as divided
   into two parts; the early part which goes from GRID to Cartesian Nasmyth
   coords, and the later part which goes from Cartesian Nasmyth to spherical
   AzEl coords. The nature of the early part is fixed for each subarray and
   does not depend on any of the supplied parameters (other than sub-array
   number). Therefore we can create the early part once for each sub-array
   and cache them for later use. The later part depends on the "az", "el"
   and "tai" parameters and so cannot be cached. Create the early part of
   the required Mapping for the requested sub-array if it has not already
   been created. The cached Mapping transforms positions within the Frame
   encapsulated within the cached FrameSet into Cartesian Nasmyth coords in
   radians. */
   if( !cache->map[ subnum ] ) {

/* Create an AST frame describing GRID coordinates within the subarray
   and put it into the cached FrameSet for this subarray. The centre of
   the first pixel has coords (1.0,1.0) in the GRID Frame. */
      cache->frameset[ subnum ] = astFrameSet( astFrame ( 2, "Domain=GRID" ),
                                              " " );

/* Add a 2D Frame with Domain "BOLO" describing the bolometer rows and
   columns. */
      sc2ast_make_bolo_frame( &bfrm, &bmap, status );
      astAddFrame( cache->frameset[ subnum ], AST__BASE, bmap, bfrm );

/* We add a another 2D Frame to the FrameSet (which becomes Frame number
   3 in the FrameSet). Without this, the first call to astRemoveFrame below
   would remove the BOLO Frame we have just added. NOTE, if in future we add
   any further Frames in here, the value of the CURRENT macro (defined
   above) should be changed. */
      astAddFrame( cache->frameset[ subnum ], AST__BASE,
                   astUnitMap( 2, " " ), astFrame( 2, " " ) );

/* Start off with a PermMap that swaps the grid axes from the new
   axes ordering to the old axis ordering (AST uses 1-based axis
   numbering). This covers the recent (ROW,COL) -> (COL,ROW) change. */
#if COLROW
     perm[ 0 ] = 2;
     perm[ 1 ] = 1;
     permmap = astPermMap( 2, perm, 2, perm, NULL, " " );
     cache->map[ subnum ] = (AstMapping *) permmap;
#endif

/* The GRID domain locates the [0][0] pixel at coordinates (1,1). Shift
   these so that the [0][0] pixel is at the origin of a coordinate system */

      zshift[0] = -1.0;
      zshift[1] = -1.0;
      zshiftmap = astShiftMap ( 2, zshift, " " );
#if COLROW
      cache->map[ subnum ] = (AstMapping *) astCmpMap( cache->map[ subnum ],
                                                       zshiftmap, 1, " " );
#else
      cache->map[ subnum ] = (AstMapping *) zshiftmap;
#endif

/* The mm coords now have to be rotated through an angle approximating
   a multiple of 90 degrees */
      r = rotangle[ subnum ];
      if( subnum < 4 ) {
        /* 850 arrays */
        rot[ 0 ] =  cos( r );
        rot[ 1 ] = -sin( r );
        rot[ 2 ] =  sin( r );
        rot[ 3 ] =  cos( r );
      } else {
        /* 450 arrays */
        rot[ 0 ] = -sin( r );
        rot[ 1 ] =  cos( r );
        rot[ 2 ] =  cos( r );
        rot[ 3 ] =  sin( r );
      }
      rotmap = astMatrixMap ( 2, 2, 0, rot, " " );
      cache->map[ subnum ] = (AstMapping *) astCmpMap( cache->map[ subnum ],
                                                      rotmap, 1, " " );

/* See which version of the distortion polynomial and array reference
   points are to be used. If the environment variable is not set, use
   "DATE". Otherwise, check it is a known value. */
      distortion = getenv( "SMURF_DISTORTION" );

      idistortion = BAD_DISTORTION;
      if( ! distortion ) {
         idistortion = DATE_DISTORTION;
      } else if( !strcmp( distortion, "DATE" ) ) {
         idistortion = DATE_DISTORTION;
      } else if( !strcmp( distortion, "ORIGINAL" ) ) {
         idistortion = ORIGINAL_DISTORTION;
      } else if( !strcmp( distortion, "NONE" ) ) {
         idistortion = NONE_DISTORTION;
      } else if( !strcmp( distortion, "NEW1" ) ) {
         idistortion = NEW1_DISTORTION;
      } else if( !strcmp( distortion, "NEW2" ) ) {
         idistortion = NEW2_DISTORTION;
      } else if( !strcmp( distortion, "NEW3" ) ) {
         idistortion = NEW3_DISTORTION;
      } else if( *status == SAI__OK ) {
         *status = SAI__ERROR;
         sprintf( errmess, "Environment variable SMURF_DISTORTION has "
                  "illegal value '%s'.\n", distortion );
         ErsRep( 0, status, errmess );
         return cache;
      }

/* Translate DATE into the best estimate of the distortion for the date
   the data was obtained. MJD 55168.19 was the start of observing on 3rd
   December 2009 - the first night of observing with the corrected C2
   mirror rotation. */
      if( idistortion == DATE_DISTORTION ) {
         if( !state || state->tcs_tai > 55168.19 ) {
            idistortion = NEW3_DISTORTION;
         } else {
            idistortion = NEW2_DISTORTION;
         }
      }

/* For each 450/850 subarray, the next Mapping creates FRAME450/FRAME850
   coordinates, which are coordinates in millimetres with origin at the
   center of the focal plane. */
      if( NEW1_DISTORTION == idistortion ) {
         shift[ 0 ] = xoff_NEW1[ subnum ];
         shift[ 1 ] = yoff_NEW1[ subnum ];

      } else if( NEW2_DISTORTION == idistortion ) {
         shift[ 0 ] = xoff_NEW2[ subnum ];
         shift[ 1 ] = yoff_NEW2[ subnum ];

      } else if( NEW3_DISTORTION == idistortion ) {
         shift[ 0 ] = xoff_NEW3[ subnum ];
         shift[ 1 ] = yoff_NEW3[ subnum ];

      } else {
         shift[ 0 ] = xoff[ subnum ];
         shift[ 1 ] = yoff[ subnum ];
      }

      shiftmap = astShiftMap( 2, shift, " " );
      cache->map[ subnum ] = (AstMapping *) astCmpMap( cache->map[ subnum ],
                                                      shiftmap, 1, " " );

/* The mapping from pixel numbers to millimetres is a simple scaling,
   because the pixel separation is the same in both coordinates and is
   accurately constant. A ZoomMap can be used for this. */
      zoommap = astZoomMap ( 2, PIX2MM, " " );

      cache->map[ subnum ] = (AstMapping *) astCmpMap( cache->map[ subnum ],
						      zoommap, 1, " " );

/* Correct for polynomial distortion (as specified by the "SMURF_DISTORTION"
   environment variable). */
      if( NEW1_DISTORTION == idistortion ) {
         polymap = astPolyMap( 2, 2, ncoeff_f_NEW1, coeff_f_NEW1,
                                     ncoeff_i_NEW1, coeff_i_NEW1, " " );

      } else if( NEW2_DISTORTION == idistortion ) {
         polymap = astPolyMap( 2, 2, ncoeff_f_NEW2, coeff_f_NEW2,
                                     ncoeff_i_NEW2, coeff_i_NEW2, " " );

      } else if( NEW3_DISTORTION == idistortion ) {
         polymap = astPolyMap( 2, 2, ncoeff_f_NEW3, coeff_f_NEW3,
                                     ncoeff_i_NEW3, coeff_i_NEW3, " " );

      } else if( NONE_DISTORTION == idistortion ) {
         polymap = NULL;

      } else {
         polymap = astPolyMap( 2, 2, 14, coeff_f, 14, coeff_i, " " );
      }

      if( polymap ) {
         cache->map[ subnum ] = (AstMapping *) astCmpMap( cache->map[ subnum ],
      						          polymap, 1, " " );
      }

/* Convert from mm to radians (but these coords are still cartesian (x,y)
   (i.e. measured in the tangent plane) rather than spherical (lon,lat)
   measured on the sky. */
      if( NEW1_DISTORTION == idistortion ) {
         radmap = astZoomMap ( 2, MM2RAD_NEW1, " " );

      } else if( NEW2_DISTORTION == idistortion ) {
         radmap = astZoomMap ( 2, MM2RAD_NEW2, " " );

      } else if( NEW3_DISTORTION == idistortion ) {
         radmap = astZoomMap ( 2, MM2RAD_NEW3, " " );

      } else {
         radmap = astZoomMap ( 2, MM2RAD, " " );
      }
      cache->map[ subnum ] = (AstMapping *) astCmpMap( cache->map[ subnum ],
                                                      radmap, 1, " " );

/* Apply focal plane offsets - if supplied. Note the effective values in
   the cache so that we can spot if they are changed. */
      if (instap) {
        double totinstap[2];
        cache->instap_x[ subnum ] = instap[ 0 ];
        cache->instap_y[ subnum ] = instap[ 1 ];
        /* Should be XML X & Y and might be different
           for 850 and 450 focal plane. The offset of the instrument centre
           from centre of rotation. */
        totinstap[ 0 ] = instap[0] - 0.0;
        totinstap[ 1 ] = instap[1] - 0.0;
        instapmap = astShiftMap( 2, totinstap, " " );
        cache->map[ subnum ] = (AstMapping *) astCmpMap( cache->map[ subnum ],
                                                         instapmap, 1, " " );
      } else {
        cache->instap_x[ subnum ] = 0.0;
        cache->instap_y[ subnum ] = 0.0;
      }

/* Simplify the Cached Mapping. */
      cache->map[ subnum ] = astSimplify( cache->map[ subnum ] );

/* Exempt the cached AST objects from AST context handling. This means
   that the pointers will not be annulled as a result of calling astEnd.
   Therefore the objects need to be annulled explicitly when no longer
   needed. This is done by calling this function with "subnum" set to -1. */
      astExempt( cache->map[ subnum ] );
      astExempt( cache->frameset[ subnum ] );

/* If we already have a cached FrameSet, check that no-one has been mucking
   about with it - it should have 2D base Frame and a 2D current Frame. */
   } else {
      nin = astGetI( cache->frameset[ subnum ], "Nin" );
      nout = astGetI( cache->frameset[ subnum ], "Nout" );
      if( nin != 2 && *status == SAI__OK ) {
         *status = SAI__ERROR;
         sprintf( errmess, "sc2ast_createwcs2: cached FrameSet has been "
                  "corrupted - it now has %d base frame axes (should be 2).",
	          nin );
         ErsRep( 0, status, errmess );

      } else if( nout != 2 && *status == SAI__OK ) {
         *status = SAI__ERROR;
         sprintf( errmess, "sc2ast_createwcs2: cached FrameSet has been "
                  "corrupted - it now has %d current frame axes (should "
                  "be 2).", nout );
         ErsRep( 0, status, errmess );
      }

/* Ensure the original current Frame is still the CURRENT Frame (the caller
   may have changed the current Frame - e.g. to access the BOLO Frame). */
      astSetI( cache->frameset[ subnum ], "Current", CURRENT );
   }

   /* If state is NULL we are simply returning the focal plane coordinate
      frames */
   if (!state) {
     AstFrame * fp_pos_frame;
     *fset = astClone( cache->frameset[ subnum ] );
     astRemoveFrame( *fset, AST__CURRENT );
     fp_pos_frame = astFrame( 2,
			      "Unit(1)=rad,Unit(2)=rad,Domain=FPLANE"
			      ",label(1)=FplaneX,label(2)=FplaneY" );
     astSetActiveUnit( fp_pos_frame, 1 );
     astAddFrame( *fset, AST__BASE, cache->map[ subnum ],
		  fp_pos_frame );
     astSet( *fset, "unit(1)=arcsec,unit(2)=arcsec" );

     /* Return early rather than embed the subsequent code in a big else.
	A bit dangerous if more is added at the end */
     astExport( *fset );
     astEnd;
     return result;
   }


/* Create a Mapping from these Cartesian Nasmyth coords (in rads) to spherical
   AzEl coords (in rads). */

   azelmap = sc2ast_maketanmap( state->tcs_az_ac1, state->tcs_az_ac2,
				cache->azel, state->tcs_az_ac2, status );

/* Calculate final mapping with SMU position correction only if needed
   (i.e. ignore SMU if all four values are zero or if any single value is bad) */
   if( ( (!state->smu_az_jig_x) && (!state->smu_az_jig_y) &&
         (!state->smu_az_chop_x) && (!state->smu_az_chop_y) ) ||
       state->smu_az_jig_x == VAL__BADD || state->smu_az_jig_y == VAL__BADD ||
       state->smu_az_chop_x == VAL__BADD || state->smu_az_chop_y == VAL__BADD ){

/* Combine these with the cached Mapping (from GRID coords for subarray
   to Tanplane Nasmyth coords in rads), to get total Mapping from GRID
   coords to spherical AzEl in rads. */

      mapping = (AstMapping *) astCmpMap( cache->map[ subnum ], azelmap, 1,
					  " " );

   } else {
/* Create a ShiftMap which moves the origin of projection plane (X,Y)
   coords to take account of the small offsets of SMU jiggle pattern. */
      shifts[ 0 ] = (state->smu_az_jig_x + state->smu_az_chop_x) * AST__DD2R / 3600.0;
      shifts[ 1 ] = (state->smu_az_jig_y + state->smu_az_chop_y) * AST__DD2R / 3600.0;
      jigglemap = astShiftMap( 2, shifts, " " );

      mapping = (AstMapping *) astCmpMap( cache->map[ subnum ],
					  astCmpMap( jigglemap, azelmap, 1,
						     " " ), 1, " " );
   }

/* If not already created, create a SkyFrame describing (Az,El). Hard-wire
   the geodetic longitude and latitude of JCMT into this Frame. Note, the
   Epoch value should be TDB, but we supply TT (=TAI+32.184 sec) instead
   since the difference is only 1-2 milliseconds. We cache the created
   SkyFrame to avoid the overhead of constantly re-creating it. The Epoch
   is set every time though since this will vary from call to call. Also,
   the SkyRef is set every time even though it only changes between
   observations. We have to do this because the cache does not (yet)
   get cleared between observations, especially in the DA. Benchmarking
   indicates that there is no penalty in calling this every time for
   non-moving objects. */
   if( !cache->skyframe ) {
      cache->skyframe = astSkyFrame ( "system=AzEl" );

      /* Ast assumes longitude increases eastward, so change sign to
	 be consistent with smf_calc_telpos here */
      astSetD( cache->skyframe, "ObsLon", -telpos[0] );
      astSetD( cache->skyframe, "ObsLat", telpos[1] );

      astExempt( cache->skyframe );

/* If the cached SkyFrame already exists, ensure it has the required
   System (AZEL). This needs to be checked since it is possible that the
   System may have been changed via the FrameSet pointer returned by a
   previous invocation of this function (the returned FrameSet contains a
   clone, not a deep copy, of the cached SkyFrame pointer). */
   } else {
     /* Only do this if we know it is not AZEL already since it takes
        time for AST to change from AZEL to AZEL */
     if ( strcmp("AZEL", astGetC(cache->skyframe, "SYSTEM")) != 0 ) {
       astSet( cache->skyframe, "system=AzEl" );
     }
   }

/* Update the epoch, dut1 and sky reference. Call this every time for
   skyref and dut1 since we can not ensure that we will always have
   cleared the cache when a new observation starts */
   astSet( cache->skyframe,
           "Epoch=MJD %.*g,SkyRef(1)=%.*g, SkyRef(2)=%.*g,dut1=%.*g",
           DBL_DIG, state->tcs_tai + 32.184/SC2AST_SPD,
           DBL_DIG, state->tcs_az_bc1,
           DBL_DIG, state->tcs_az_bc2,
           DBL_DIG, dut1 );

/* Now modify the cached FrameSet to use the new Mapping and SkyFrame.
   First remove the existing current Frame and then add in the new one.
   Note, we add a copy of the SkyFrame rather than the cached SkyFrame
   itself since the SkyFrame contained in the FrameSet will be modified
   by later functions.  */
   astRemoveFrame( cache->frameset[ subnum ], AST__CURRENT );
   astAddFrame( cache->frameset[ subnum ], AST__BASE, mapping,
                astClone( cache->skyframe ) );

/* Return the final FrameSet. */
   *fset = astClone( cache->frameset[ subnum ] );

/* Export the returned FrameSet pointer, and then end the AST context. This
   will annul all AST objects created since the matching call to astBegin,
   except for those which have been exported using astExport or exempted
   using astExempt. The use of AST contexts requires that the function
   does not exit prematurely before reaching the astEnd call. Therefore
   there should usually no "return" statements within the body of the AST
   context. */
   astExport( *fset );
   astEnd;

/* Return a pointer to the cache. */
   return result;
}


/*+ sc2ast_getdomain - select a domain within a frameset */

void sc2ast_getdomain
(
const char *name,         /* AST domain name (given) */
AstFrameSet *fset,        /* modified frameset (given and returned) */
int *status               /* global status (given and returned) */
)
/* Method :
    Find the last frame within the frameset matching the given domain
    name, and make it the current frame.
   Authors :
     B.D.Kelly (bdk@roe.ac.uk)
   History :
     10May2005 : original (bdk)
*/

{
   AstFrame *frame;    /* individual frame */
   int frameno;        /* number of frame */
   int nframes;        /* number of frames in the frameset */
   int j;              /* loop counter */

   if ( *status != SAI__OK ) return;

   astBegin;

/* Search for the domain name */

   nframes = astGetI ( fset, "NFRAME" );

   frameno = 0;
   for ( j=nframes; j>0; j-- )
   {
      frame = astGetFrame ( fset, j );
      if ( strcmp ( name, astGetC ( frame, "DOMAIN" )) == 0 )
      {
         frameno = j;
         break;
      }
      frame = astAnnul ( frame );
   }

   astEnd;

   if ( frameno != 0  )
   {
      astSetI ( fset, "CURRENT", frameno );
   }
}


/*+ sc2ast_makefitschan - create a set of FITS headers in a FitsChan */

void sc2ast_makefitschan
(
double crpix1,            /* index of reference point (given) */
double crpix2,            /* index of reference point (given) */
double cd1_1,             /* data increment (given) */
double cd2_2,             /* data increment (given) */
double crval1,            /* reference coordinate (given) */
double crval2,            /* reference coordinate (given) */
const char *ctype1,       /* coordinate mapping type (given) */
const char *ctype2,       /* coordinate mapping type (given) */
AstFitsChan *fitschan,    /* FitsChan to be filled (given and returned) */
int *status               /* global status (given and returned) */
)
/* Method :
     Contruct a set of FITS headers and put them into an AST FitsChan.
   Authors :
     B.D.Kelly (bdk@roe.ac.uk)
     T.Jenness (timj@jach)
   History :
     13Apr2005 : original (bdk)
     08Nov2005 : Use astSetFits rather than intermediate strings (timj)
*/

{

   if ( *status != SAI__OK ) return;

   astSetFitsF ( fitschan, "CRPIX1", crpix1, " ", 0 );
   astSetFitsF ( fitschan, "CRPIX2", crpix2, " ", 0 );
   astSetFitsF ( fitschan, "CD1_1", cd1_1, " ", 0 );
   astSetFitsF ( fitschan, "CD2_2", cd2_2, " ", 0 );
   astSetFitsF ( fitschan, "CRVAL1", crval1, " ", 0 );
   astSetFitsF ( fitschan, "CRVAL2", crval2, " ", 0 );
   astSetFitsS ( fitschan, "CTYPE1", ctype1, " ", 0 );
   astSetFitsS ( fitschan, "CTYPE2", ctype2, " ", 0 );

   return;
}



/*+ sc2ast_moveframe - move the base frame within a frameset */

void sc2ast_moveframe
(
double x,                 /* X coordinate offset in pixels (given) */
double y,                 /* Y coordinate offset in pixels (given) */
AstFrameSet *fset,        /* modified frameset (given and returned) */
int *status               /* global status (given and returned) */
)
/* Method :
    Use astRemapFrame to shift the base frame of the frameset.
   Authors :
     B.D.Kelly (bdk@roe.ac.uk)
   History :
     26May2005 : original (bdk)
     07Jun2005 : apply shift in pixels (bdk)
*/

{
   AstShiftMap *shiftmap;
   double shift[2];

   if ( *status != SAI__OK ) return;

   astBegin;

/* Set up a shift mapping */

   shift[0] = x;
   shift[1] = y;
   shiftmap = astShiftMap ( 2, shift, " " );

/* Remap the base frame */

   astRemapFrame ( fset, AST__BASE, shiftmap );

   astEnd;

}


/*+ sc2ast_name2num - convert subarray name to id number */

void sc2ast_name2num
(
const char *name,             /* subarray name s8a-d, s4a-d (given) */
int *subnum,            /* subarray number, 0-7 (returned) */
int *status             /* global status (given and returned) */
)
/* Method :
    Convert the SCUBA-2 standard name of a subarray into its
    corresponding index number.
   Authors :
     B.D.Kelly (bdk@roe.ac.uk)
     Tim Jenness (timj@jach.hawaii.edu)
   History :
     27Apr2005 : original (bdk)
     18May2005 : force initialisation of returned value (timj)
     27Jan2006 : use strncmp rather than strcmp (timj)
                 Associate error message with error condition (timj)
     20Mar2007 : const "name" argument (timj)
*/

{

   *subnum = 0; /* force initialisation */

   if ( *status != SAI__OK ) return;


   if ( strncmp ( name, "s8a", 3 ) == 0 )
   {
      *subnum = 0;
   }
   else if ( strncmp ( name, "s8b", 3 ) == 0 )
   {
      *subnum = 1;
   }
   else if ( strncmp ( name, "s8c", 3 ) == 0 )
   {
      *subnum = 2;
   }
   else if ( strncmp ( name, "s8d", 3 ) == 0 )
   {
      *subnum = 3;
   }
   else if ( strncmp ( name, "s4a", 3 ) == 0 )
   {
      *subnum = 4;
   }
   else if ( strncmp ( name, "s4b", 3 ) == 0 )
   {
      *subnum = 5;
   }
   else if ( strncmp ( name, "s4c", 3 ) == 0 )
   {
      *subnum = 6;
   }
   else if ( strncmp ( name, "s4d", 3 ) == 0 )
   {
      *subnum = 7;
   }
   else
   {
      *status = SAI__ERROR;
      sprintf( errmess,
	       "Error converting subarray name from '%s' to number",
	       name);
      ErsRep( 0, status, errmess);
   }
}



/*+ sc2ast_polframest - create a frameset for polarimetry */

void sc2ast_polframeset
(
AstFrameSet *frameset,  /* 2-D frameset (given) */
AstFrameSet **fset,     /* constructed 3-D frameset (returned) */
int *status             /* global status (given and returned) */
)
/* Method :
    Add a unit mapping onto an existing 2-D frameset to create a 3-D
    frameset.
   Authors :
     B.D.Kelly (bdk@roe.ac.uk)
   History :
     14Jun2005 : original (bdk)
*/

{
   AstCmpMap *cmpmap;
   AstFrame *extframe;
   AstFrame *gridframe;
   AstCmpFrame *polframe;
   AstSkyFrame *skyframe;
   AstUnitMap *unitmap;


   if ( *status != SAI__OK ) return;


/* The first step creates an AST frame corresponding to the subarray */

   gridframe = astFrame ( 3, "Domain=GRID" );
   extframe = astFrame ( 1, "Domain=GRID" );

/* An AST FrameSet is initialised and will be built up as the various frames
   and the mappings between them are created */

   *fset = astFrameSet ( gridframe, " " );

   unitmap = astUnitMap ( 1, " " );
   cmpmap = astCmpMap ( frameset, unitmap, 0, " " );
   skyframe = astSkyFrame ( " " );
   polframe = astCmpFrame ( skyframe, extframe, " " );
   astAddFrame ( *fset, AST__CURRENT, cmpmap, polframe );

}

/*+ sc2ast_maketanmap - create a Mapping representing a tangent plane
                        projection */

AstMapping *sc2ast_maketanmap
(
double lon,              /* Celestial longitude at ref point (rads) */
double lat,              /* Celestial latitude at ref point (rads) */
AstMapping *cache[ 2 ],  /* Cached Mappings (supply as NULL on 1st call) */
double rot,              /* Rotation needed to align input Y axis with North */
int *status              /* global status (given and returned) */
)
/* Method :
    The forward transformation of the returned Mapping transforms
    cartesian tangent plane offsets in radians, into celestial longitude
    and latitude values, in radians. The reference point of the tangent
    plane is put at the supplied longitude and latitude position.

    The "cache" array should be filled with NULL values before the first
    call to this function. It will be returned holding AST pointers to
    Mappings which will be needed on subsequent calls (these pointers are
    exempted from AST context handling).

    If the input Cartesian coordinates represent Nasmyth (X,Y) coords,
    then the "rot" angle should be the elevation of the boresight.

   Authors :
     D.S.Berry (dsb@ast.man.ac.uk)

   History :
     10Feb2006 : original (dsb)
     1Sep2008  : Set the SphMap attribute "UnitRadius" so that SphMaps
                 can be simplified. (dsb)
*/

{
   AstMapping *result;
   AstMatrixMap *matmap;
   AstCmpMap *m1;
   AstWcsMap *wcsmap;
   double mat[ 3 ][ 3 ];

/* SLA does not use const so we have to copy from const to a temporary */
   char eul[4];

/* Check the inherited status. */
   if ( *status != SAI__OK ) return NULL;

/* If required, create a SphMap for converting spherical cartesian
   (x,y,z) positions to (lon,lat) positions. */
   if( !cache[ 0 ] ) {
      cache[ 0 ] = (AstMapping *) astSphMap( "UnitRadius=1" );
      astExempt( cache[ 0 ] );
   }

/* If required, create a CmpMap holding a WcsMap followed by an inverted
   SphMap. */
   if( !cache[ 1 ] ) {
      wcsmap = astWcsMap( 2, AST__TAN, 1, 2, " " );
      astInvert( wcsmap );
      astInvert( cache[ 0 ] );
      cache[ 1 ] = (AstMapping *) astCmpMap( wcsmap, cache[ 0 ], 1, " " );
      astInvert( cache[ 0 ] );
      wcsmap = astAnnul( wcsmap );
      astExempt( cache[ 1 ] );
   }

/* The required Mapping consists of the "cache[ 1 ]" Mapping, followed by
   a suitable MatrixMap which rotates the tangent point to the requested
   spherical (az,el) coordinates, and rotates the Caresian Y axis to
   celestial north (elevation). followed by the "cache[ 0 ]" Mapping. The
   logic follows that of FITS-WCS paper II (which is what the WcsMap
   class assumes). The reference point of the TAN projection is at the
   north pole of the "native" spherical coordinate system. The matrix map
   first rotates about the Z axis by -rot (to rotate the Cartesian Y axis to
   north), then rotates about the Y axis by -(pi/2-lat) (to rotate the
   reference point from the native north pole to the celestial north pole),
   then rotates about the Z axis by -lon (to rotate the prime native meridian
   to the prime celestial meridian). Here the Z axis points to the north
   pole, the X axis points to (lon,lat)=(0,0) and the Y axis points to
   (lon,lat) = (90 degs,0) (the slalib convention). */

   strcpy(eul, "ZYZ" );
   slaDeuler( eul, -rot, -(PIBY2-lat), -lon, mat );
   matmap = astMatrixMap( 3, 3, 0, (double *) mat, " " );

/* Create the required compound Mapping. */
   m1 = astCmpMap( cache[ 1 ], matmap, 1, " " );
   result = (AstMapping *) astCmpMap( m1, cache[ 0 ], 1, " " );
   matmap = astAnnul( matmap );
   m1 = astAnnul( m1 );

/* Return the required Mapping.*/
   return result;

}

/*+ sc2ast_set_output_system - set the output SYSTEM to match the
                              equivalent JCMT tracking system
 */

void sc2ast_set_output_system
(
 const char *trsys,      /* JCMT tracking system (given) */
 AstFrameSet *fset,      /* Frameset to update (updated) */
 int * status            /* inherited status (given & returned ) */
)

/*
 *  Purpose:
 *    Sets the SYSTEM attribute based on JCMT naming convention.

 *  Description:
 *    Sets the AST output system and also sets the SkyRefIs and
 *    AlignOffset attributes if this system is associated with
 *    a moving frame.

 *  Authors:
 *     TIMJ: Tim Jenness (JAC, Hawaii)

 *  History:
 *     23-JUL-2008 (TIMJ):
 *        Original version.
 *     11-AUG-2008 (TIMJ):
 *        Set AlignOffset and SkyRefIs if appropriate.

 */
{
  const char * astsys = NULL;

  if (*status != SAI__OK) return;

  astsys = sc2ast_convert_system( trsys, status );
  if ( *status == SAI__OK) {
    astSetC( fset, "SYSTEM", astsys );

    astsys = astGetC( fset, "SYSTEM");
    if (strcmp(astsys,"AZEL") == 0 || strcmp(astsys, "GAPPT") == 0 ) {
      astSet( fset, "SkyRefIs=Origin,AlignOffset=1" );
    }
  }

}



/*+ sc2ast_convert_system - convert JCMT coordinate system to AST coordinate
                           system
 */
const char * sc2ast_convert_system
(
 const char *label,   /* Input JCMT coordinate system (given) */
 int * status         /* Inherited status (given & returned) */
)

/*
*  Purpose:
*     Convert a JCMT label for a celestial coordinate system into the
*     corresponding AST SkyFrame System value.

*  Returned Value:
*     A point to a static string holding the equivalent AST value, or
*     "" if there is no equivalent AST value.

*  Description:
*     This function converts a JCMT label for a celestial coordinate system
*     into the corresponding AST SkyFrame System value. It reports an error
*     if the system is not supported by AST.

*  Authors:
*     DSB: David S. Berry (JAC, UCLan)
*     EC: Ed Chapin (UBC)
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     25-SEP-2006 (DSB):
*        Original version.
*     13-DEC-2007 (EC):
*        Use strncmp instead of strcmp
*     23-JUL-2008 (TIMJ):
*        Copy from smf_convert_system (now deleted) so that the
*        DA can do the conversion
*     22-JUN-2009 (TIMJ):
*        Old ACSIS data (<= 20061020) occassionally had MOUNT
*        coordinates. Assume this is identical to AZEL (which
*        is ordinarily not an issue because TCS_AZ_ACx always
*        stores AZEL numbers so you can convert).
*/

{

/* Local Variables */
   const char *result = "";   /* Returned pointer */

/* Check inherited status */
   if (*status != SAI__OK) return result;

/* Compare the supplied labelwith each known type. */
   if( !strncmp( label, "AZEL", 4 ) ||
       !strncmp( label, "MOUNT", 5 ) ) {
      result = "AZEL";

   } else if( !strncmp( label, "APP", 3 ) ) {
      result = "GAPPT";

   } else if( !strncmp( label, "GAL", 3 ) ) {
      result = "GALACTIC";

   } else if( !strncmp( label, "ICRS", 4 ) ||
              !strncmp( label, "ICRF", 4 ) ) {
      result = "ICRS";

   } else if( !strncmp( label, "B1950", 5 ) ) {
      result = "FK4";

   } else if( !strncmp( label, "J2000", 5 ) ) {
      result = "FK5";

   } else {
      *status = SAI__ERROR;
      sprintf( errmess,
               "The JCMT coordinate system %s does not "
               "have an equivalent AST System value.", label );
      ErsRep( 0, status, errmess);
   }

   return result;
}


void sc2ast_make_bolo_frame
(
 AstFrame **frm,         /* Address for new Frame pointer */
 AstMapping **map,       /* Address for new Mapping pointer */
 int * status            /* inherited status (given & returned ) */
)

/*
*  Purpose:
*    Return a Frame representing bolometer index.

*  Description:
*    Returns a Frame describing bolometer rows and columns, and a Mapping
*    from GRID coords to bolometer coords.

*  Authors:
*    David S Berry (JAC, Hawaii)

*  History:
*    28-OCT-2009 (DSB):
*       Initial version

*/

{

/* Local Variables: */
   double shift[ 2 ];

/* Check inherited status */
   if( *status != SAI__OK ) return;

/* Create the bolometer Frame */
   *frm = astFrame( 2, "Domain=BOLO,Title=Bolometer rows and columns" );

/* Set the axis symbols, depending on the current preferred order. */
#if COLROW
   astSet( *frm, "label(1)=Columns,label(2)=Rows");
#else
   astSet( *frm, "label(1)=Rows,label(2)=Columns");
#endif

/* To get bolometer coords, subtract 1.0 from the GRID coords. Do
   this using a ShiftMap. */
   shift[ 0 ] = -1;
   shift[ 1 ] = -1;
   *map = (AstMapping *) astShiftMap( 2, shift, " " );
}
