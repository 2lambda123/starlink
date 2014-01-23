/*
*+
*  Name:
*     smf_get_mask

*  Purpose:
*     Get a pointer to a boolean map mask

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     unsigned char *smf_get_mask( ThrWorkForce *wf, smf_modeltype mtype,
*                                  AstKeyMap *config, smfDIMMData *dat,
*                                  int flags, int *status )

*  Arguments:
*     wf = ThrWorkForce * (Given)
*        Pointer to a pool of worker threads (can be NULL)
*     mtype = (Given)
*        The type of model (COM, FLT or AST) for which the mask is required.
*     config = AstKeyMap * (Given)
*        Configuration parameters that control the map-maker.
*     dat = smfDIMMData * (Given)
*        Struct of pointers to information required by model calculation.
*     flags = int (Given)
*        Control flags.
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Returned Value:
*     A pointer to the boolean mask, or NULL if no masking is to be
*     performed or if an error occurs. Note, the returned pointer should
*     not be freed by the calling routine.
*
*     The mask value is zero for pixels designated as "source" pixels
*     and non-zero for "background" pixels.

*  Description:
*     This function returns a mask of boolean flags, one for each pixel
*     in the map, if any of the zero masking options for the specified
*     DIMM model are set in the supplied configuration. A non-zero mask
*     value indicates "background" pixels, and zero represents "source"
*     pixels. A NULL pointer is returned if no masking is requested in the
*     supplied configuration, or if the requested masking is not possible
*     (for instance, it is not possible to mask COM on the first iteration
*     using an SNR or low-hits mask since the map data needed to create
*     the mask is not known until the end of the first iteration).
*
*     If multiple masks are specified (e.g. ZERO_MASK and ZERO_CIRCLE),
*     they are combined into a single mask. How this is done depends on
*     the value of the "ZERO_UNION" parameter. If it is non-zero, then
*     the combined mask is the union of the individual masks (i.e. a mask
*     pixel is "source" (zero) iff one or more of the indivudal mask pixels
*     are source). If ZERO_UNION is zero, the combined mask is the
*     intersection of the individual masks (i.e. a mask pixel is "source"
*     (zero) iff all the mask pixels are source).

*  Authors:
*     David S Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     23-FEB-2012 (DSB):
*        Original version.
*     16-MAR-2012 (DSB):
*        Add FLT model, and ZERO_NITER parameter.
*     31-MAY-2012 (DSB):
*        Add ZERO_FREEZE parameter.
*     18-OCT-2012 (DSB):
*        Allow multiple masks to be used.
*     11-DEC-2012 (DSB):
*        Change zero_freeze so that negative values cause permanent
*        freeze, even on iteration zero (for the benefit of the skyloop.py
*        command). Also, initialise the new mask to hold the values implied
*        by the quality array associated with the current map.
*     15-FEB-2013 (DSB):
*        - Allow union or intersection of multiple masks to be used.
*        - Report an error if the mask contains fewer than 5 source pixels.
*     4-APR-2013 (DSB):
*        - Use VAL__BADD, not VAL__BADI, for checking for bad map and
*        vartiance values. This bug will have had no effect since an
*        additional check was made that mapvar is positive, and so caught
*        bad variances (since VAL__BADD is negative).
*        - When checking that the mask has significant size, do not
*        include bad map pixels (eg the map corners, etc) in the count of
*        source pixels.
*     10-APR-2013 (DSB):
*        When checking that the mask encloses a significant number of source
*        pixels, do not require source pixels to have a defined variance
*        since variances are usually not available on the first iteration.
*     9-JUL-2013 (DSB):
*        The ZERO_NITER and ZERO_FREEZE values should count the iterations 
*        perfomed *after* any initial iterations for which the AST model was
*        skipped.
*     23-JAN-2014 (DSB):
*        When creating a mask from a quality array imported from an initial 
*        sky NDF, only check the quality bit relevant to the mask being created.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2012 Science & Technology Facilities Council.
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
*     Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
*     MA 02110-1301, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "sae_par.h"
#include "dat_par.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_typ.h"

/* Local Constants: */
#define NONE       0  /* No masking to be done */
#define LOWHITS    1  /* Mask areas with low hits */
#define CIRCLE     2  /* Mask areas in a given circle */
#define REFNDF     3  /* Mask areas specified by a reference NDF */
#define SNR        4  /* Mask areas with low SNR */
#define PREDEFINED 5  /* Use a mask created on an earlier run of smf_iteratemap */
#define NTYPE      6  /* No. of different mask types */


unsigned char *smf_get_mask( ThrWorkForce *wf, smf_modeltype mtype,
                             AstKeyMap *config, smfDIMMData *dat, int flags,
                             int *status ) {

/* Local Variables: */
   AstCircle *circle;         /* AST Region used to mask a circular area */
   AstKeyMap *akm;            /* KeyMap holding AST config values */
   AstKeyMap *subkm;          /* KeyMap holding model config values */
   char refparam[ DAT__SZNAM ];/* Name for reference NDF parameter */
   char words[100];           /* Buffer for variable message words */
   const char *cval;          /* The ZERO_MASK string value */
   const char *modname;       /* The name of the model  being masked */
   const char *skyrefis;      /* Pointer to SkyRefIs attribute value */
   dim_t i;                   /* Pixel index */
   double *pd;                /* Pointer to next element of map data */
   double *predef;            /* Pointer to mask defined by previous run */
   double *ptr;               /* Pointer to NDF  Data array */
   double *pv;                /* Pointer to next element of map variance */
   double centre[ 2 ];        /* Coords of circle centre in radians */
   double meanhits;           /* Mean hits in the map */
   double radius[ 1 ];        /* Radius of circle in radians */
   double zero_circle[ 3 ];   /* LON/LAT/Radius of circular mask */
   double zero_lowhits;       /* Fraction of mean hits at which to threshold */
   double zero_snr;           /* Higher SNR at which to threshold */
   double zero_snrlo;         /* Lower SNR at which to threshold */
   int *ph;                   /* Pointer to next hits value */
   int have_mask;             /* Did a mask already exist on entry? */
   int imask;                 /* Index of next mask type */
   int indf1;                 /* Id. for supplied reference NDF */
   int indf2;                 /* Id. for used section of reference NDF */
   int isstatic;              /* Are all used masks static? */
   int lbnd_grid[ 2 ];        /* Lower bounds of map in GRID coords */
   int mask_types[ NTYPE ];   /* Identifier for the types of mask to use */
   int munion;                /* Use union of supplied masks */
   int nel;                   /* Number of mapped NDF pixels */
   int nmask;                 /* The number of masks to be combined */
   int nsource;               /* No. of source pixels in final mask */
   int skip;                  /* No. of iters for which AST is not subtracted */
   int thresh;                /* Absolute threshold on hits */
   int ubnd_grid[ 2 ];        /* Upper bounds of map in GRID coords */
   int zero_c_n;              /* Number of zero circle parameters read */
   int zero_mask;             /* Use the reference NDF as a mask? */
   int zero_niter;            /* Only mask for the first "niter" iterations. */
   int zero_notlast;          /* Don't zero on last iteration? */
   size_t ngood;              /* Number good samples for stats */
   smf_qual_t *pq;            /* Pinter to map quality */
   smf_qual_t qv;             /* Map quality value to use */
   unsigned char **mask;      /* Address of model's mask pointer */
   unsigned char *newmask;    /* Individual mask work space */
   unsigned char *pm;         /* Pointer to next returned mask pixel */
   unsigned char *pn;         /* Pointer to next new mask pixel */
   unsigned char *result;     /* Returned mask pointer */

/* Initialise returned values */
   result = NULL;

/* Check inherited status. Also check that a map is being created.  */
   if( *status != SAI__OK || !dat || !dat->map ) return result;

/* Begin an AST context. */
   astBegin;

/* Get the sub-keymap containing the configuration parameters for the
   requested model. Also get a pointer to the mask array to use (there is
   one for each maskable model)*/
   if( mtype == SMF__COM ) {
      modname = "COM";
      mask = &(dat->com_mask);
      qv = SMF__MAPQ_COM;
   } else if( mtype == SMF__AST ) {
      modname = "AST";
      mask = &(dat->ast_mask);
      qv = SMF__MAPQ_AST;
   } else if( mtype == SMF__FLT ) {
      modname = "FLT";
      mask = &(dat->flt_mask);
      qv = SMF__MAPQ_FLT;
   } else {
      modname = NULL;
      mask = NULL;
      qv = 0;
      *status = SAI__ERROR;
      errRepf( " ", "smf_get_mask: Unsupported model type %d supplied - "
               "must be COM, FLT or AST.", status, mtype );
   }
   subkm = NULL;
   astMapGet0A( config, modname, &subkm );

/* Get the "ast.skip" value - when considering "zero_niter" and
   "zero_freeze", we only count iterations for which the AST model
   is subtracted (i.e. the ones following the initial "ast.skip"
   iterations). */
   astMapGet0A( config, "AST", &akm );
   astMapGet0I( akm, "SKIP", &skip );
   akm = astAnnul( akm );

/* Get the number of iterations over which the mask is to be applied. Zero
   means all. Return with no mask if this number of iterations has
   already been performed. */
   zero_niter = 0;
   astMapGet0I( subkm, "ZERO_NITER", &zero_niter );
   if( zero_niter == 0 || dat->iter < zero_niter + skip ) {

/* Only return a mask if this is not the last iteration, or if ZERO_NOTLAST
   is unset. */
      zero_notlast = 0;
      astMapGet0I( subkm, "ZERO_NOTLAST", &zero_notlast );
      if( !( flags & SMF__DIMM_LASTITER ) || !zero_notlast ) {

/* Create a list of the mask types to be combined to get the final mask by
   looking for non-default values for the corresponding configuration
   parameters in the supplied KeyMap. Static masks (predefined, circles
   or external NDFs) may be used on any iteration, but dynamic masks
   (lowhits, snr) will only be avialable once the map has been determined
   at the end of the first iteration. This means that when masking anything
   but the AST model (which is determined after the map), the dynamic masks
   cannot be used on the first iteration. Make a note if all masks being
   used are static. */

         isstatic = 1;
         nmask = 0;

         zero_lowhits = 0.0;
         astMapGet0D( subkm, "ZERO_LOWHITS", &zero_lowhits );
         if( zero_lowhits > 0.0 ) {
            if( mtype == SMF__AST || !( flags & SMF__DIMM_FIRSTITER ) ) {
               mask_types[ nmask++] = LOWHITS;
               isstatic = 0;
            }
         } else if( zero_lowhits <  0.0 && *status == SAI__OK ) {
            *status = SAI__ERROR;
            errRepf( " ", "Bad value for config parameter %s.ZERO_LOWHITS (%g) - "
                     "it must not be negative.", status, modname, zero_lowhits );
         }

         if( astMapGet1D( subkm, "ZERO_CIRCLE", 3, &zero_c_n, zero_circle ) ) {
            if( zero_c_n == 1 || zero_c_n == 3 ) {
               mask_types[ nmask++] = CIRCLE;
            } else if( *status == SAI__OK ) {
               *status = SAI__ERROR;
               errRepf( " ", "Bad number of values (%d) for config parameter "
                        "%s.ZERO_CIRCLE - must be 1 or 3.", status, zero_c_n,
                        modname );
            }
         }

         cval = NULL;
         astMapGet0C( subkm, "ZERO_MASK", &cval );
         if( cval ) {
            if( !astChrMatch( cval, "REF" ) &&
                !astChrMatch( cval, "MASK2" ) &&
                !astChrMatch( cval, "MASK3" ) ) {
               astMapGet0I( subkm, "ZERO_MASK", &zero_mask );
               cval = ( zero_mask > 0 ) ? "REF" : NULL;
            }
            if( cval ) {
               strcpy( refparam, cval );
               astChrCase( NULL, refparam, 1, 0 );
               mask_types[ nmask++] = REFNDF;
            }
         }

         zero_snr = 0.0;
         astMapGet0D( subkm, "ZERO_SNR", &zero_snr );
         if( zero_snr > 0.0 ) {
            if( mtype == SMF__AST || !( flags & SMF__DIMM_FIRSTITER ) ) {
               mask_types[ nmask++] = SNR;
               isstatic = 0;
            }
         } else if( zero_snr <  0.0 && *status == SAI__OK ) {
            *status = SAI__ERROR;
            errRepf( " ", "Bad value for config parameter %s.ZERO_SNR (%g) - "
                     "it must not be negative.", status, modname, zero_snr );
         }

         if( astMapHasKey( subkm, "ZERO_MASK_POINTER" ) ) {
            astMapGet0P( subkm, "ZERO_MASK_POINTER", (void **) &predef );
            if( predef ) mask_types[ nmask++] = PREDEFINED;
         }

/* No need to create a mask if no masking was requested or possible. */
         if( nmask > 0 ) {

/* Decide if we are using the union or intersection of the masks. */
            astMapGet0I( subkm, "ZERO_UNION", &munion );

/* Note if a mask existed on entry. If not, create a mask now, and
   initialise it to hold the mask defined by the initial sky map. */
            if( *mask == NULL ) {
               have_mask = 0;
               if( dat->initqual ) {
                  *mask = astMalloc( dat->msize*sizeof( **mask ) );
                  if( *mask ) {
                     pm = *mask;
                     pq = dat->initqual;
                     for( i = 0; i < dat->msize; i++ ) {
                        *(pm++) = ( *(pq++) & qv );
                     }
                  }
               } else{
                  *mask = astCalloc( dat->msize, sizeof( **mask ) );
               }
            } else {
               have_mask = 1;
            }

/* If we are combining more than one mask, we need work space to hold
   an individual mask independently of the total mask. If we are using
   only one mask, then just use the main mask array. */
            if( nmask > 1 ) {
               newmask = astMalloc( dat->msize*sizeof( *newmask ) );
            } else {
               newmask = *mask;
            }

/* Get the number of iterations after which the mask is to be frozen.
   Zero means "never freeze the mask". */
            int zero_freeze = 0;
            astMapGet0I( subkm, "ZERO_FREEZE", &zero_freeze );

/* Loop round each type of mask to be used. */
            for( imask = 0; imask < nmask && *status == SAI__OK; imask++ ){

/* If the mask is now frozen, we just return the existing mask. So leave the
   loop. */
               if( zero_freeze != 0 && dat->iter > zero_freeze + skip ) {
                  break;

/* Low hits masking... */
               } else if( mask_types[ imask ] == LOWHITS ) {

/* Set hits pixels with 0 hits to VAL__BADI so that stats1 ignores them */
                  ph = dat->hitsmap;
                  for( i = 0; i < dat->msize; i++,ph++ ) {
                     if( *ph == 0 ) *ph = VAL__BADI;
                  }

/* Find the mean hits in the map */
                  smf_stats1I( dat->hitsmap, 1, dat->msize, NULL, 0, 0, &meanhits,
                               NULL, NULL, &ngood, status );
                  msgOutiff( MSG__DEBUG, " ", "smf_get_mask: mean hits = %lf, ngood "
                             "= %zd", status, meanhits, ngood );

/* Create the mask */
                  thresh = meanhits*zero_lowhits;
                  ph = dat->hitsmap;
                  pn = newmask;
                  for( i = 0; i < dat->msize; i++,ph++ ) {
                     *(pn++) = ( *ph != VAL__BADI && *ph < thresh ) ? 1 : 0;
                  }

/* Report masking info. */
                  msgOutiff( MSG__DEBUG, " ", "smf_get_mask: masking %s "
                             "model at hits = %d.", status, modname, thresh );

/* Circle masking... */
               } else if( mask_types[ imask ] == CIRCLE ) {

/* If we had a mask on entry, then there is no need to create a new one
   since it will not have changed. But we need to recalculate the circle
   mask if are combining it with any non-static masks. */
                  if( ! have_mask || ! isstatic ) {

/* If only one parameter supplied it is radius, assume reference
   LON/LAT from the frameset to get the centre. If the SkyFrame
   represents offsets from the reference position (i.e. the source is
   moving), assume the circle is to be centred on the origin.  */
                     if( zero_c_n == 1 ) {
                        zero_circle[ 2 ] = zero_circle[ 0 ];

                        skyrefis = astGetC( dat->outfset, "SkyRefIs" );
                        if( skyrefis && !strcmp( skyrefis, "Origin" ) ) {
                           zero_circle[ 0 ] = 0.0;
                           zero_circle[ 1 ] = 0.0;
                        } else {
                           zero_circle[ 0 ] = astGetD( dat->outfset, "SkyRef(1)" );
                           zero_circle[ 1 ] = astGetD( dat->outfset, "SkyRef(2)" );
                        }

                        zero_circle[ 0 ] *= AST__DR2D;
                        zero_circle[ 1 ] *= AST__DR2D;
                     }

/* The supplied bounds are for pixel coordinates... we need bounds for grid
    coordinates which have an offset */
                     lbnd_grid[ 0 ] = 1;
                     lbnd_grid[ 1 ] = 1;
                     ubnd_grid[ 0 ] = dat->ubnd_out[ 0 ] - dat->lbnd_out[ 0 ] + 1;
                     ubnd_grid[ 1 ] = dat->ubnd_out[ 1 ] - dat->lbnd_out[ 1 ] + 1;

/* Coordinates & radius of the circular region converted from degrees
   to radians */
                     centre[ 0 ] = zero_circle[ 0 ]*AST__DD2R;
                     centre[ 1 ] = zero_circle[ 1 ]*AST__DD2R;
                     radius[ 0 ] = zero_circle[ 2 ]*AST__DD2R;

/* Create the Circle, defined in the current Frame of the FrameSet (i.e.
   the sky frame). */
                     circle = astCircle( astGetFrame( dat->outfset, AST__CURRENT), 1,
                                         centre, radius, NULL, " " );

/* Fill the mask with zeros. */
                     memset( newmask, 0, sizeof( *newmask )*dat->msize );

/* Get the mapping from the sky frame (current) to the grid frame (base),
   and then set the mask to 1 for all of the values outside this circle */
                     astMaskUB( circle, astGetMapping( dat->outfset, AST__CURRENT,
                                                       AST__BASE ),
                                0, 2, lbnd_grid, ubnd_grid, newmask, 1 );

/* Report masking info. */
                     if( zero_niter == 0 ) {
                        sprintf( words, "on each iteration" );
                     } else {
                        sprintf( words, "for %d iterations", zero_niter );
                     }

                     msgOutiff( MSG__DEBUG, " ", "smf_get_mask: The %s model will"
                                " be masked %s using a circle of "
                                "radius %g arc-secs, centred at %s=%s, %s=%s.",
                                status, modname, words, radius[0]*AST__DR2D*3600,
                                astGetC( dat->outfset, "Symbol(1)" ),
                                astFormat( dat->outfset, 1, centre[ 0 ] ),
                                astGetC( dat->outfset, "Symbol(2)" ),
                                astFormat( dat->outfset, 2, centre[ 1 ] ) );
                  }

/* Reference NDF masking... */
               } else if( mask_types[ imask ] == REFNDF ) {

/* If we had a mask on entry, then there is no need to create a new one
   since it will not have changed. But we need to recalculate the NDF
   mask if are combining it with any non-static masks. */
                  if( ! have_mask || ! isstatic ) {

/* Begin an NDF context. */
                     ndfBegin();

/* Get an identifier for the NDF using the associated ADAM parameter. */
                     ndfAssoc( refparam, "READ", &indf1, status );

/* Get a section from this NDF that matches the bounds of the map. */
                     ndfSect( indf1, 2, dat->lbnd_out, dat->ubnd_out, &indf2,
                              status );

/* Map the section. */
                     ndfMap( indf2, "DATA", "_DOUBLE", "READ", (void **) &ptr,
                             &nel, status );

/* Check we can use the pointer safely. */
                     if( *status == SAI__OK ) {

/* Find bad pixels in the NDF and set those pixels to 1 in the mask. */
                        pn = newmask;
                        for( i = 0; i < dat->msize; i++ ) {
                           *(pn++) = ( *(ptr++) == VAL__BADD ) ? 1 : 0;
                        }

/* Report masking info. */
                        ndfMsg( "N", indf2 );
                        msgSetc( "M", modname );
                        if( zero_niter == 0 ) {
                           msgOutiff( MSG__DEBUG, " ", "smf_get_mask: The ^M "
                                      "model will be masked on each iteration "
                                      "using the bad pixels in NDF '^N'.",
                                      status );
                        } else {
                           msgSeti( "I", zero_niter );
                           msgOutiff( MSG__DEBUG, " ", "smf_get_mask: The ^M "
                                      "model will be masked for ^I iterations "
                                      "using the bad pixels in NDF '^N'.",
                                      status );
                        }
                     }

/* End the NDF context. */
                     ndfEnd( status );
                  }

/* SNR masking... */
               } else if( mask_types[ imask ] == SNR ) {

/* Get the lower SNR limit. */
                  zero_snrlo = 0.0;
                  astMapGet0D( subkm, "ZERO_SNRLO", &zero_snrlo );
                  if( zero_snrlo <= 0.0 ) {
                     zero_snrlo = zero_snr;
                  } else if( zero_snrlo > zero_snr && *status == SAI__OK ) {
                     *status = SAI__ERROR;
                     errRepf( " ", "Bad value for config parameter "
                              "%s.ZERO_SNRLO (%g) - it must not be higher "
                              "than %s.ZERO_SNR (%g).", status, modname,
                              zero_snrlo, modname, zero_snr );
                  }

/* If the higher and lower SNR limits are equal, just do a simple
   threshold on the SNR values to get the mask. */
                  if( zero_snr == zero_snrlo ) {
                     pd = dat->map;
                     pv = dat->mapvar;
                     pn = newmask;
                     for( i = 0; i < dat->msize; i++,pd++,pv++ ) {
                        *(pn++) = ( *pd != VAL__BADD && *pv != VAL__BADD &&
                                    *pv >= 0.0 && *pd < zero_snr*sqrt( *pv ) ) ? 1 : 0;
                     }

/* Report masking info. */
                     if( !have_mask ) {
                        if( zero_niter == 0 ) {
                           sprintf( words, "on each iteration" );
                        } else {
                           sprintf( words, "for %d iterations", zero_niter );
                        }
                        msgOutiff( MSG__DEBUG, " ", "smf_get_mask: The %s model "
                                   "will be masked %s using an SNR limit of %g.",
                                   status, modname, words, zero_snr );
                     }

/* If the higher and lower SNR limits are different, create an initial
   mask by thresholding at the ZERO_SNR value, and then extend the source
   areas within the mask down to an SNR limit of ZERO_SNRLO. */
                  } else {
                     smf_snrmask( wf, dat->map, dat->mapvar, dat->mdims,
                                  zero_snr, zero_snrlo, newmask, status );

/* Report masking info. */
                     if( !have_mask ) {
                        if( zero_niter == 0 ) {
                           sprintf( words, "on each iteration" );
                        } else {
                           sprintf( words, "for %d iterations", zero_niter );
                        }
                        msgOutiff( MSG__DEBUG, " ", "smf_get_mask: The %s model "
                                   "will be masked %s using an SNR limit of %g "
                                   "extended down to %g.", status, modname,
                                   words, zero_snr, zero_snrlo );
                     }
                  }

/* Predefined masking... */
               } else if( mask_types[ imask ] == PREDEFINED ) {

/* If we had a mask on entry, then there is no need to create a new one
   since it will not have changed. But we need to recalculate the
   mask if are combining it with any non-static masks. */
                  if( ! have_mask || ! isstatic ) {

/* Find bad pixels in the predefined array and set those pixels to 1 in
   the mask. */
                     pn = newmask;
                     for( i = 0; i < dat->msize; i++ ) {
                        *(pn++) = ( *(predef++) == VAL__BADD ) ? 1 : 0;
                     }

/* Report masking info. */
                     if( zero_niter == 0 ) {
                        sprintf( words, "on each iteration" );
                     } else {
                        sprintf( words, "for %d iterations", zero_niter );
                     }
                     msgOutiff( MSG__DEBUG, " ", "smf_get_mask: The %s model "
                                "will be masked %s using a smoothed form of "
                                "the final mask created with the previous map.",
                                status, modname, words );
                  }
               }

/* If required, add the new mask into the returned mask. If this is the
   first mask, we just copy the new mask to form the returned mask.
   Otherwise, we combine it with the existing returned mask. */
               if( ! have_mask || ! isstatic ) {
                  if( nmask > 1 ) {
                     if( imask == 0 ) {
                        memcpy( *mask, newmask, dat->msize*sizeof(*newmask));
                     } else {
                        pm = *mask;
                        pn = newmask;
                        if( munion ) {
                           for( i = 0; i < dat->msize; i++,pm++ ) {
                              if( *(pn++) == 0 ) *pm = 0;
                           }
                        } else {
                           for( i = 0; i < dat->msize; i++,pm++ ) {
                              if( *(pn++) == 1 ) *pm = 1;
                           }
                        }
                     }
                  }
               }
            }

/* Free the individual mask work array if it was used. */
            if( nmask > 1 ) newmask = astFree( newmask );

/* Check that the mask has some source pixels (i.e. pixels that have non-bad data values -
   we do not also check variance values since they are not available until the second
   iteration). */
            if( *status == SAI__OK ) {
               nsource = 0;
               pm = *mask;
               pd = dat->map;
               for( i = 0; i < dat->msize; i++,pd++,pv++,pm++ ) {
                  if( *pd != VAL__BADD && *pm == 0 ) nsource++;
               }
               if( nsource < 5 && *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  errRepf( "", "The %s mask being used has fewer than 5 "
                           "source pixels.", status, modname );
                  if( zero_snr > 0.0 ) {
                     errRepf( "", "Maybe your zero_snr value (%g) is too high?",
                              status, zero_snr );
                  }
               }
            }

/* Return the mask pointer if all has gone well. */
            if( *status == SAI__OK ) result = *mask;
         }
      }
   }

/* End the AST context, annulling all AST Objects created in the context. */
   astEnd;

/* Return the pointer to the boolean mask. */
   return result;
}

