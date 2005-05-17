/*
*class++
*  Name:
*     Prism

*  Purpose:
*     An extrusion of a region into higher dimensions.

*  Constructor Function:
c     astPrism
f     AST_PRISM

*  Description:
*     A Prism is a Region which represents an extrusion of an existing Region 
*     into one or more orthogonal dimensions (specified by an Interval or
*     Box). If the Region to be extruded has N axes, and the Interval or Box 
*     defining the extrusion has M axes, then the resulting Prism will have 
*     (M+N) axes. A point is inside the Prism if the first N axis values 
*     correspond to a point which is inside the Region being extruded, and the 
*     remaining M axis values correspond to a point which inside the supplied 
*     Interval or Box.
*
*     As an example, a cylinder can be represented by extruding an existing 
*     Circle. In this case the supplied Interval would have a single axis and 
*     would specify the upper and lower limits of the cylinder along its 
*     length.

*  Inheritance:
*     The Prism class inherits from the Region class.

*  Attributes:
*     The Prism class does not define any new attributes beyond those
*     which are applicable to all Regions.

*  Functions:
c     The Prism class does not define any new functions beyond those
f     The Prism class does not define any new routines beyond those
*     which are applicable to all Regions.

*  Copyright:
*     <COPYRIGHT_STATEMENT>

*  Authors:
*     DSB: David S. Berry (Starlink)

*  History:
*     17-DEC-2004 (DSB):
*        Original version.
*     11-MAY-2005 (DSB):
*        Overlap modified to allow testing of overlap between prisms and
*        intervals.
*class--
*/

/* Module Macros. */
/* ============== */
/* Set the name of the class we are implementing. This indicates to
   the header files that define class interfaces that they should make
   "protected" symbols available. */
#define astCLASS Prism

/* Macros which return the maximum and minimum of two values. */
#define MAX(aa,bb) ((aa)>(bb)?(aa):(bb))
#define MIN(aa,bb) ((aa)<(bb)?(aa):(bb))

/* Macro to check for equality of floating point values. We cannot
   compare bad values directory because of the danger of floating point
   exceptions, so bad values are dealt with explicitly. */
#define EQUAL(aa,bb) (((aa)==(bb))?1:(((aa)==AST__BAD||(bb)==AST__BAD)?0:(fabs((aa)-(bb))<=1.0E9*MAX((fabs(aa)+fabs(bb))*DBL_EPSILON,DBL_MIN))))

/* Include files. */
/* ============== */
/* Interface definitions. */
/* ---------------------- */
#include "error.h"               /* Error reporting facilities */
#include "memory.h"              /* Memory allocation facilities */
#include "object.h"              /* Base Object class */
#include "pointset.h"            /* Sets of points/coordinates */
#include "region.h"              /* Regions (parent class) */
#include "channel.h"             /* I/O channels */
#include "prism.h"               /* Interface definition for this class */
#include "cmpmap.h"              /* Compound Mappings */
#include "cmpframe.h"            /* Compound Frames */
#include "unitmap.h"             /* Unit Mappings */
#include "interval.h"            /* Axis intervals */
#include "pointlist.h"           /* Points within Frames */
#include "permmap.h"             /* Axis permutations */

/* Error code definitions. */
/* ----------------------- */
#include "ast_err.h"             /* AST error codes */

/* C header files. */
/* --------------- */
#include <stdarg.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <limits.h>

/* Module Variables. */
/* ================= */
/* Define the class virtual function table and its initialisation flag
   as static variables. */
static AstPrismVtab class_vtab; /* Virtual function table */
static int class_init = 0;          /* Virtual function table initialised? */

/* Pointers to parent class methods which are extended by this class. */
static AstPointSet *(* parent_transform)( AstMapping *, AstPointSet *, int, AstPointSet * );
static AstRegion *(* parent_getuncfrm)( AstRegion *, int );
static void (* parent_clearunc)( AstRegion * );
static int (* parent_testunc)( AstRegion * );
static void (* parent_setregfs)( AstRegion *, AstFrame * );
static AstMapping *(* parent_simplify)( AstMapping * );
static int (* parent_equal)( AstObject *, AstObject * );
static void (* parent_setclosed)( AstRegion *, int );
static void (* parent_setmeshsize)( AstRegion *, int );
static void (* parent_clearclosed)( AstRegion * );
static void (* parent_clearmeshsize)( AstRegion * );
static double (*parent_getfillfactor)( AstRegion * );
static int (* parent_overlap)( AstRegion *, AstRegion * );
static void (*parent_regsetattrib)( AstRegion *, const char *, char ** );
static void (*parent_regclearattrib)( AstRegion *, const char *, char ** );

/* External Interface Function Prototypes. */
/* ======================================= */
/* The following functions have public prototypes only (i.e. no
   protected prototypes), so we must provide local prototypes for use
   within this module. */
AstPrism *astPrismId_( void *, void *, const char *, ... );

/* Prototypes for Private Member Functions. */
/* ======================================== */
static AstMapping *Simplify( AstMapping * );
static AstPointSet *RegBaseMesh( AstRegion * );
static AstPointSet *Transform( AstMapping *, AstPointSet *, int, AstPointSet * );
static AstRegion *EquivPrism( AstPrism *, AstRegion * );
static AstRegion *GetUncFrm( AstRegion *, int );
static double *RegCentre( AstRegion *this, double *, double **, int, int );
static double GetFillFactor( AstRegion * );
static int Equal( AstObject *, AstObject * );
static int GetBounded( AstRegion * );
static int Overlap( AstRegion *, AstRegion * );
static int OverlapX( AstRegion *, AstRegion * );
static int RegPins( AstRegion *, AstPointSet *, AstRegion *, int ** );
static int TestUnc( AstRegion * );
static void ClearClosed( AstRegion * );
static void ClearMeshSize( AstRegion * );
static void ClearUnc( AstRegion * );
static void Copy( const AstObject *, AstObject * );
static void Delete( AstObject * );
static void Dump( AstObject *, AstChannel * );
static void GetRegions( AstPrism *, AstRegion **, AstRegion **, int * );
static void RegBaseBox( AstRegion *, double *, double * );
static void RegClearAttrib( AstRegion *, const char *, char ** );
static void RegSetAttrib( AstRegion *, const char *, char ** );
static void SetClosed( AstRegion *, int );
static void SetMeshSize( AstRegion *, int );
static void SetRegFS( AstRegion *, AstFrame * );


/* Member functions. */
/* ================= */
static void ClearUnc( AstRegion *this_region ){
/*
*  Name:
*     ClearUnc

*  Purpose:
*     Erase any uncertainty information in a Region.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     void ClearUnc( AstRegion *this )

*  Class Membership:
*     Prism member function (over-rides the astClearUnc protected
*     method inherited from the Region class).

*  Description:
*     This function erases all uncertainty information, whether default
*     or not, from a Region.

*  Parameters:
*     this
*        Pointer to the Region.

*/

/* Local Variables: */
   AstPrism *this;

/* Check the inherited status. */
   if( !astOK ) return;

/* Invoke the implementation inherited form the parent Region class to 
   clear any default uncertainty information. */
   (* parent_clearunc)( this_region );

/* Get a pointer to the Prism structure. */
   this = (AstPrism *) this_region;

/* Clear any uncertainty information in the component Regions. */
   astClearUnc( this->region1 );
   astClearUnc( this->region2 );

}

static int Equal( AstObject *this_object, AstObject *that_object ) {
/*
*  Name:
*     Equal

*  Purpose:
*     Test if two Objects are equivalent.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     int Equal( AstObject *this_object, AstObject *that_object ) 

*  Class Membership:
*     Prism member function (over-rides the astEqual protected
*     method inherited from the Region class).

*  Description:
*     This function returns a boolean result (0 or 1) to indicate whether
*     two Prisms are equivalent. 

*  Parameters:
*     this
*        Pointer to the first Prism.
*     that
*        Pointer to the second Prism.

*  Returned Value:
*     One if the Prisms are equivalent, zero otherwise.

*  Notes:
*     - The Prisms are equivalent if their component Regions are
*     equivalent and if they have the same boolean operation, negation
*     and closed flags.
*     - A value of zero will be returned if this function is invoked
*     with the global status set, or if it should fail for any reason.
*/

/* Local Variables: */
   AstPrism *that;              
   AstPrism *this;              
   int result;                   

/* Initialise. */
   result = 0;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Invoke the Equal method inherited from the parent Region class. This checks
   that the Objects are both of the same class, and have the same Negated
   and Closed flags (amongst other things). */
   if( (*parent_equal)( this_object, that_object ) ) {

/* Obtain pointers to the two Prism structures. */
      this = (AstPrism *) this_object;
      that = (AstPrism *) that_object;

/* Test their first component Regions for equality. */
      if( astEqual( this->region1, that->region1 ) ) {

/* Test their second component Regions for equality. */
         if( astEqual( this->region2, that->region2 ) ) result = 1;
      }
   }

/* If an error occurred, clear the result value. */
   if ( !astOK ) result = 0;

/* Return the result, */
   return result;
}

static AstRegion *EquivPrism( AstPrism *this, AstRegion *region ) {
/*
*  Name:
*     EquivPrism

*  Purpose:
*     Obtain a pointer to a Prism equivalent to the supplied Region.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     AstRegion *EquivPrism( AstPrism *this, AstRegion *region )

*  Class Membership:
*     Prism method 

*  Description:
*     This function returns a pointer to a Region which is equivalent to
*     the supplied Region, and which is if possible a Prism with the same
*     structure as "this". If there is no equivalent Prism, then a clone of 
*     the supplied pointer is returned.
*
*     Only Boxes and Intervals have equivalent Prisms.

*  Parameters:
*     this
*        Pointer to a Prism.
*     region
*        Pointer to the Region.

*  Returned Value:
*     A pointer to the equivalent Prism or a a clone of the supplied
*     pointer. This should be annulled (using astAnnul) when no longer 
*     needed.

*  Notes:
*     - A NULL pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Variables: */
   AstFrame *bfrm;
   AstFrame *cfrm;
   AstFrame *sfrm1;
   AstFrame *sfrm2;
   AstFrameSet *fs;
   AstInterval *sreg1;
   AstInterval *sreg2;
   AstMapping *emap2;
   AstMapping *map1;
   AstMapping *map2;
   AstMapping *map3;
   AstMapping *map4;
   AstMapping *map5;
   AstMapping *map6;
   AstMapping *map7;
   AstMapping *map;
   AstPermMap *pmap;
   AstPrism *prism;
   AstRegion *result;         
   AstRegion *unc;      
   double *lbnd;
   double *lbndt;
   double *ubnd;
   double *ubndt;
   int *inax2;
   int *inperm;
   int *outax1;
   int *outax2;
   int i;               
   int j;
   int nax1;
   int nax2;
   int naxb;
   int nbase;
   int next;                 

/* Initialise */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* If the supplied Region is a Box or Interval, we can create an
   equivalent Prism. */
   if( astIsABox( region ) || astIsAInterval( region ) ) {

/* Get the Mapping from the Frame represented by "this" to the Frame
   represented by "region". */
      fs = astConvert( this, region, "" );
      if( fs ) {
         map2 = astGetMapping( fs, AST__BASE, AST__CURRENT );

/* Use this to construct the Mapping from the base Frame in "this" to the 
   base Frame in "region". */
         map1 = astGetMapping( ((AstRegion *) this)->frameset, AST__BASE,
                               AST__CURRENT );
         map3 = astGetMapping( region->frameset, AST__CURRENT, AST__BASE );

         map4 = (AstMapping *) astCmpMap( map1, map2, 1, "" );
         map5 = (AstMapping *) astCmpMap( map4, map3, 1, "" );
         map = astSimplify( map5 );

/* Get pointers to the base and current Frames in the Box or Interval. */
         bfrm = astGetFrame( region->frameset, AST__BASE );
         cfrm = astGetFrame( region->frameset, AST__CURRENT );

/* Get the base Frame bounds of the Box or Interval, plus some extra
   workspace. */
         naxb = astGetNaxes( bfrm );
         lbndt = astMalloc( sizeof( double )*(size_t) naxb );
         ubndt = astMalloc( sizeof( double )*(size_t) naxb );
         lbnd = astMalloc( sizeof( double )*(size_t) naxb );
         ubnd = astMalloc( sizeof( double )*(size_t) naxb );
         astRegBaseBox( region, lbnd, ubnd );

/* Determine which outputs from the Mapping found above correspond to the 
   extrusion axes of the supplied Prism. */
         nbase = astGetNaxes( this->region1 );
         next = astGetNaxes( this->region2 );
         inax2 = astMalloc( sizeof(int)*(size_t)next );
         if( inax2  ) {
            for( i = 0; i < next; i++ ) inax2[ i ] = nbase + i;
         }
         outax2 = astMapSplit( map, next, inax2, &emap2 );

/* The inputs of the Mapping returned by astMapSplit correspond to the
   extrusion axes of the supplied Prism. The outputs of this Mapping 
   define the axes of "region" which are to be used as the extrusion axes
   in the equivalent Prism. Find out how many of them there are, and copy
   the bounds for these axes into the temporary "lbndt" and "ubndt" arrays. */
         if( outax2 ) {
            nax2 = astGetNout( emap2 );
            for( i = 0; i < nax2; i++ ) {
               lbndt[ i ] = lbnd[ outax2[ i ] ];
               if( lbndt[ i ] == -DBL_MAX ) lbndt[ i ] = AST__BAD;
               ubndt[ i ] = ubnd[ outax2[ i ] ];
               if( ubndt[ i ] == DBL_MAX ) ubndt[ i ] = AST__BAD;
            }

/* Pick these axes from the base Frame of the Box or Interval. */
            sfrm2 = astPickAxes( bfrm, nax2, outax2, NULL );

/* Create an Interval describing the extrusion axes. */
            sreg2 = astInterval( sfrm2, lbndt, ubndt, NULL, "" );

/* Determine which outputs from this Mapping correspond to the base
   axes of the supplied Prism. These are just the axes which are *not*
   included in "inax2". */
            outax1 = astMalloc( sizeof(int)*(size_t)naxb );
            if( outax1 ) {
               for( i = 0; i < naxb; i++ ) outax1[ i ] = i;
               for( i = 0; i < nax2; i++ ) outax1[ inax2[ i ] ] = -1;
               j = 0;
               for( i = 0; i < naxb; i++ ) {
                  if( outax1[ i ] != -1 ) outax1[ j++ ] = outax1[ i ];
               }
   
/* Copy the base Frame bounds for these axes. */
               nax1 = naxb - nax2;
               for( i = 0; i < nax1; i++ ) {
                  lbndt[ i ] = lbnd[ outax1[ i ] ];
                  if( lbndt[ i ] == -DBL_MAX ) lbndt[ i ] = AST__BAD;
                  ubndt[ i ] = ubnd[ outax1[ i ] ];
                  if( ubndt[ i ] == DBL_MAX ) ubndt[ i ] = AST__BAD;
               }
   
/* Pick these axes from the base Frame of the Box or Interval. */
               sfrm1 = astPickAxes( bfrm, nax1, outax1, NULL );
   
/* Create an Interval describing the base axes. */
               sreg1 = astInterval( sfrm1, lbndt, ubndt, NULL, "" );
   
/* Create a Prism from these two regions. */
               prism = astPrism( sreg1, sreg2, "" );
   
/* The axes in this Prism are in the order defined by the structure of
      the suppied Prism (all the base axes followed by all the extrusion axes).
      This may be different from the order of the base Frame axes in the
      supplied Box or Interval. Get a PermMap which will remap the prism so its 
      axes are in the same order as the original Region's base Frame. */
               inperm = astMalloc( sizeof( int )*(size_t)naxb );
               if( inperm ) {
                  for( i = 0; i < nax1; i++ ) inperm[ i ] = outax1[ i ];
                  for( i = 0; i < nax2; i++ ) inperm[ i + nax1 ] = outax2[ i ];
                  pmap = astPermMap( naxb, inperm, naxb, NULL, NULL, "" );
   
/* Combine this with the Mapping from the original base Frame to the
      original current Frame, and simplify it. */
                  astInvert( map3 );
                  map6 = (AstMapping *) astCmpMap( pmap, map3, 1, "" );
                  map7 = astSimplify( map6 );            
   
/* If this is not a UnitMap, use it to remap the prism into the Region's 
      original current Frame. We do not simplify the result since this could
      turn the final prism back into a Box or Interval! */
                  if( !astIsAUnitMap( map7 ) ) {
                     result = astMapRegion( prism, map7, cfrm );
                  } else {               
                     result= astClone( prism );
                  }
   
/* If the original Region has any non-default uncertainty, get it, and
      set it in the re-ordered, re-mapped Prism. */
                  if( astTestUnc( region ) ){
                     unc = astGetUncFrm( region, AST__CURRENT );
                     astSetUnc( result, unc );
                     unc = astAnnul( unc );
                  }
   
/* Copy Region attributes from the original Region to the new Prism. */
                  astRegOverlay( result, region );
   
/* Free resources */
                  inperm = astFree( inperm );
                  pmap = astAnnul( pmap );
                  map6 = astAnnul( map6 );
                  map7 = astAnnul( map7 );
               }

               outax1 = astFree( outax1 );
               sfrm1 = astAnnul( sfrm1 );
               sreg1 = astAnnul( sreg1 );
               prism = astAnnul( prism );
            }

            outax2 = astFree( outax2 );
            sfrm2 = astAnnul( sfrm2 );
            emap2 = astAnnul( emap2 );
            sreg2 = astAnnul( sreg2 );
         }

         inax2 = astFree( inax2 );
         ubnd = astFree( ubnd );
         lbnd = astFree( lbnd );
         ubndt = astFree( ubndt );
         lbndt = astFree( lbndt );
         bfrm = astAnnul( bfrm );
         cfrm = astAnnul( cfrm );
         map1 = astAnnul( map1 );
         map2 = astAnnul( map2 );
         map3 = astAnnul( map3 );
         map4 = astAnnul( map4 );
         map5 = astAnnul( map5 );
         map = astAnnul( map );
         fs = astAnnul( fs );
      }
   }

/* If no equivalent Prism was created, return a clone of the supplied
   pointer. */
   if( !result ) result = astClone( region );

/* Return NULL if an error occurred. */
   if( !astOK ) result = astAnnul( result );

/* Return the required pointer. */
   return result;
}

/*
*  Name:
*     MAKE_SET

*  Purpose:
*     Define a function to set an attribute value for a Prism.

*  Type:
*     Private macro.

*  Synopsis:
*     #include "prism.h"
*     MAKE_SET(attribute,lattribute,type)

*  Class Membership:
*     Defined by the Prism class.

*  Description:
*     This macro expands to an implementation of a private member function
*     of the form:
*
*        static void Set<Attribute>( AstRegion *this, <Type> value )
*
*     that sets the value of a specified Region attribute in the parent
*     Region structure and also in the component Regions.

*  Parameters:
*     attribute
*        Name of the attribute, as it appears in the function name.
*     lattribute
*        Name of the attribute, all in lower case.
*     type
*        The C type of the attribute.
*/

/* Define the macro. */
#define MAKE_SET(attribute,lattribute,type) \
static void Set##attribute( AstRegion *this_region, type value ) { \
\
/* Local Variables: */ \
   AstPrism *this;         /* Pointer to the Prism structure */ \
\
/* Check the global error status. */ \
   if ( !astOK ) return; \
\
/* Use the parent method to set the value in the parent Region structure. */ \
   (*parent_set##lattribute)( this_region, value ); \
\
/* Also set the value in the two component Regions. */ \
   this = (AstPrism *) this_region; \
   astSet##attribute( this->region1, value ); \
   astSet##attribute( this->region2, value ); \
}

/* Use the above macro to create accessors for the MeshSize and Closed 
   attributes. */
MAKE_SET(MeshSize,meshsize,int)
MAKE_SET(Closed,closed,int)

/* Undefine the macro. */
#undef MAKE_SET

/*
*  Name:
*     MAKE_CLEAR

*  Purpose:
*     Define a function to clear an attribute value for a Prism.

*  Type:
*     Private macro.

*  Synopsis:
*     #include "prism.h"
*     MAKE_CLEAR(attribute,lattribute)

*  Class Membership:
*     Defined by the Prism class.

*  Description:
*     This macro expands to an implementation of a private member function
*     of the form:
*
*        static void Clear<Attribute>( AstRegion *this )
*
*     that sets the value of a specified Region attribute in the parent
*     Region structure and also in the component Regions.

*  Parameters:
*     attribute
*        Name of the attribute, as it appears in the function name.
*     lattribute
*        Name of the attribute, all in lower case.
*/

/* Define the macro. */
#define MAKE_CLEAR(attribute,lattribute) \
static void Clear##attribute( AstRegion *this_region ) { \
\
/* Local Variables: */ \
   AstPrism *this;         /* Pointer to the Prism structure */ \
\
/* Check the global error status. */ \
   if ( !astOK ) return; \
\
/* Use the parent method to clear the value in the parent Region structure. */ \
   (*parent_clear##lattribute)( this_region ); \
\
/* Also clear the value in the two component Regions. */ \
   this = (AstPrism *) this_region; \
   astClear##attribute( this->region1 ); \
   astClear##attribute( this->region2 ); \
}

/* Use the above macro to create accessors for the MeshSize and Closed 
   attributes. */
MAKE_CLEAR(MeshSize,meshsize)
MAKE_CLEAR(Closed,closed)

/* Undefine the macro. */
#undef MAKE_CLEAR

static int GetBounded( AstRegion *this_region ) {
/*
*  Name:
*     GetBounded

*  Purpose:
*     Is the Region bounded?

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     int GetBounded( AstRegion *this ) 

*  Class Membership:
*     Prism method (over-rides the astGetBounded method inherited from
*     the Region class).

*  Description:
*     This function returns a flag indicating if the Region is bounded.
*     The implementation provided by the base Region class is suitable
*     for Region sub-classes representing the inside of a single closed 
*     curve (e.g. Circle, Ellipse, Box, etc). Other sub-classes (such as
*     Prism, PointList, etc ) may need to provide their own
*     implementations.

*  Parameters:
*     this
*        Pointer to the Region.

*  Returned Value:
*     Non-zero if the Region is bounded. Zero otherwise.

*/

/* Local Variables: */
   AstPrism *this;            /* Pointer to Prism structure */
   AstRegion *reg1;           /* Pointer to first component Region */
   AstRegion *reg2;           /* Pointer to second component Region */
   int neg;                   /* Negated flag to use with the Prism */
   int reg1b;                 /* Is the first component Region bounded?*/
   int reg2b;                 /* Is the second component Region bounded?*/
   int result;                /* Returned result */

/* Initialise */
   result = 0;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Get a pointer to the Prism structure. */
   this = (AstPrism *) this_region;   

/* Get the component Regions, and the Negated value for the Prism. The 
   returned Regions represent a region within the base Frame of the FrameSet 
   encapsulated by the parent Region structure. */
   GetRegions( this, &reg1, &reg2, &neg );

/* If the Prism has been inverted, temporarily invert the components. */
   if( neg ) {
      astNegate( reg1 );
      astNegate( reg2 );
   }

/* See if either of the component Regions is bounded. */
   reg1b = astGetBounded( reg1 );
   reg2b = astGetBounded( reg2 );

/* If the Prism has been inverted, re-invert the components to bring them
   back to their original states. */
   if( neg ) {
      astNegate( reg1 );
      astNegate( reg2 );
   }

/* The Prism is bounded only if both of the component Regions are bounded. */
   result = ( reg1b && reg2b );
   
/* Free resources. */
   reg1 = astAnnul( reg1 );
   reg2 = astAnnul( reg2 );

/* Return zero if an error occurred. */
   if( !astOK ) result = 0;

/* Return the required pointer. */
   return result;
}

static double GetFillFactor( AstRegion *this_region ) {
/*
*  Name:
*     GetFillFactor

*  Purpose:
*     Obtain the value of the FillFactor attribute for a Prism.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     double GetFillFactor( AstRegion *this )

*  Class Membership:
*     Prism member function (over-rides the astGetFillFactor method inherited
*     from the Region class).

*  Description:
*     This function returns the value of the FillFactor attribute for a
*     Prism.  A suitable default value is returned if no value has
*     previously been set.

*  Parameters:
*     this
*        Pointer to the Prism.

*  Returned Value:
*     The FillFactor value to use.

*/

/* Local Variables: */
   AstPrism *this;
   double f1;
   double f2;
   double result; 

/* Check the global error status. */
   if ( !astOK ) return AST__BAD;

/* Initialise. */
   result = AST__BAD;

/* Obtain a pointer to the Prism structure. */
   this = (AstPrism *) this_region;

/* See if a FillFactor value has been set. If so, use the parent
   astGetFillFactor  method to obtain it. */
   if ( astTestFillFactor( this ) ) {
      result = (*parent_getfillfactor)( this_region );

/* Otherwise, we will generate a default value equal to the product of
   the FillFactor values of the two component Regions. */
   } else {
      f1 = astGetFillFactor( this->region1 );
      f2 = astGetFillFactor( this->region2 );
      if( f1 != AST__BAD && f2 != AST__BAD ) result = f1*f2;
   }

/* If an error occurred, clear the returned value. */
   if ( !astOK ) result = AST__BAD;

/* Return the result. */
   return result;
}

static void GetRegions( AstPrism *this, AstRegion **reg1, AstRegion **reg2,
                        int *neg ) {
/*
*
*  Name:
*     GetRegions

*  Purpose:
*     Get the component Regions of a Prism.

*  Type:
*     Private function.

*  Synopsis:
*     #include "region.h"
*     void GetRegions( AstPrism *this, AstRegion **reg1, AstRegion **reg2,
*                      int *neg )

*  Class Membership:
*     Prism member function 

*  Description:
*     This function returns pointers to the two Regions in a Prism, together 
*     with the Negated flag for the Prism.
*
*     The current Frames in both the returned component Regions will be 
*     equivalent to componets of the base Frame in the FrameSet encapsulated 
*     by the parent Region structure.

*  Parameters:
*     this
*        Pointer to the Prism.
*     reg1
*        Address of a location to receive a pointer to first component
*        Region. This is the region which is to be extruded. 
*     reg2
*        Address of a location to receive a pointer to second component
*        Region. This will be an Interval defining the axes along which
*        the first Region is to be extruded.
*     neg
*        Pointer to an int in which to return the value of the Negated 
*        attribute of the Prism.

*  Notes:
*     - The returned pointers should be annuled using astAnnul when no
*     longer needed.
*     - The Frames represented by the returned Regions (that is, the
*     current Frames in their encapsulated FrameSets) are equivalent to the 
*     base Frame in the FrameSet encapsulated within the parent Region.
*     - Any changes made to the component Regions using the returned
*     pointers will be reflected in the supplied Prism.

*-
*/

/* Initialise */
   if( reg1 ) *reg1 = NULL;
   if( reg2 ) *reg2 = NULL;

/* Check the global error status. */
   if ( !astOK ) return;

/* Store the required values.*/
   *reg1 = astClone( this->region1 );
   *reg2 = astClone( this->region2 );
   *neg = astGetNegated( (AstRegion *) this );
}

static AstRegion *GetUncFrm( AstRegion *this_region, int ifrm ) {
/*
*  Name:
*     GetUncFrm

*  Purpose:
*     Obtain a pointer to the uncertainty Region for a given Region.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     AstRegion *GetUncFrm( AstRegion *this, int ifrm ) 

*  Class Membership:
*     Prism method (over-rides the astGetUncFrm method inherited from
*     the Region class).

*  Description:
*     This function returns a pointer to a Region which represents the
*     uncertainty associated with a position on the boundary of the given 
*     Region. The returned Region can refer to the either the base or 
*     the current Frame within the FrameSet encapsulated by the supplied 
*     Region as specified by the "ifrm" parameter. If the returned Region is 
*     re-centred at some point on the boundary of the supplied Region, then 
*     the re-centred Region will represent the region in which the true 
*     boundary position could be.

*  Parameters:
*     this
*        Pointer to the Region.
*     ifrm
*        The index of a Frame within the FrameSet encapsulated by "this".
*        The returned Region will refer to the requested Frame. It should
*        be either AST__CURRENT or AST__BASE.

*  Returned Value:
*     A pointer to the Region. This should be annulled (using astAnnul)
*     when no longer needed.

*  Notes:
*     - A default uncertainty Region will be created if the supplied Region 
*     does not have an uncertainty Region.
*     - A NULL pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Variables: */
   AstPrism *this;            /* Pointer to Prism structure */
   AstFrame *frm;             /* Current Frame from supplied Region */
   AstMapping *map;           /* Supplied to uncertainty Mapping */
   AstRegion *bunc;           /* Uncertainty Region in base Frame of "this" */
   AstRegion *bunc1;          /* Uncertainty Region for 1st component */
   AstRegion *bunc2;          /* Uncertainty Region for 2nd component */
   AstRegion *result;         /* Returned pointer */

/* Initialise */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Get a pointer to the Prism structure. */
   this = (AstPrism *) this_region;   

/* If the parent Region structure contains explicit uncertainty information, 
   use it in preference to any uncertainty Region stored in the component 
   Regions. */
   if( (* parent_testunc)( this_region ) ) {
      bunc = (* parent_getuncfrm)( this_region, AST__BASE );

/* Otherwise construct an uncertainty Region from the uncertainty Regions
   in the two component Regions. The current Frames in the component
   Regions are equivalent to the base Frame in the parent Region structure. 
   So we may need to map the component uncertainty into the current Region of 
   the parent if required later on. */
   } else {
      bunc1 = astGetUncFrm( this->region1, AST__CURRENT );
      bunc2 = astGetUncFrm( this->region2, AST__CURRENT );

/* Combine them into a Prism. */
      bunc = (AstRegion *) astPrism( bunc1, bunc2, "" );

/* Free resources. */
      bunc1 = astAnnul( bunc1 );
      bunc2 = astAnnul( bunc2 );
   }

/* The above code obtains an uncertainty Region in the base Frame of the
   parent Region (equal to the current Frame of the component Regions).
   If this is what is required, return a clone of the above Region. */
   if( ifrm == AST__BASE ) {
      result = astClone( bunc );

/* Otherwise, map it into the current Region of the parent.  */
   } else {

/* Get a Mapping from the Frame represented by the uncertainty Region
   (the parent Region base Frame) to the parent Region current Frame. */
      map = astGetMapping( this_region->frameset, AST__BASE, AST__CURRENT );

/* If it is a UnitMap, the uncertainty Region is already in the correct 
   Frame, so just return the stored pointer. */
      if( astIsAUnitMap( map ) ) {
         result= astClone( bunc );

/* Otherwise, use this Mapping to map the uncertainty Region into the current
   Frame. */
      } else {
         frm = astGetFrame( this_region->frameset, AST__CURRENT );
         result = astMapRegion( bunc, map, frm );

/* Free resources. */
         frm = astAnnul( frm );
      }
      map = astAnnul( map );
   }
   bunc = astAnnul( bunc );

/* Return NULL if an error occurred. */
   if( !astOK ) result = astAnnul( result );

/* Return the required pointer. */
   return result;
}

void astInitPrismVtab_(  AstPrismVtab *vtab, const char *name ) {
/*
*+
*  Name:
*     astInitPrismVtab

*  Purpose:
*     Initialise a virtual function table for a Prism.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "prism.h"
*     void astInitPrismVtab( AstPrismVtab *vtab, const char *name )

*  Class Membership:
*     Prism vtab initialiser.

*  Description:
*     This function initialises the component of a virtual function
*     table which is used by the Prism class.

*  Parameters:
*     vtab
*        Pointer to the virtual function table. The components used by
*        all ancestral classes will be initialised if they have not already
*        been initialised.
*     name
*        Pointer to a constant null-terminated character string which contains
*        the name of the class to which the virtual function table belongs (it 
*        is this pointer value that will subsequently be returned by the Object
*        astClass function).
*-
*/

/* Local Variables: */
   AstFrameVtab *frame;          /* Pointer to Frame component of Vtab */
   AstMappingVtab *mapping;      /* Pointer to Mapping component of Vtab */
   AstObjectVtab *object;        /* Pointer to Object component of Vtab */
   AstRegionVtab *region;        /* Pointer to Region component of Vtab */

/* Check the local error status. */
   if ( !astOK ) return;

/* Initialize the component of the virtual function table used by the
   parent class. */
   astInitRegionVtab( (AstRegionVtab *) vtab, name );

/* Store a unique "magic" value in the virtual function table. This
   will be used (by astIsAPrism) to determine if an object belongs to
   this class.  We can conveniently use the address of the (static)
   class_init variable to generate this unique value. */
   vtab->check = &class_init;

/* Initialise member function pointers. */
/* ------------------------------------ */
/* Store pointers to the member functions (implemented here) that
   provide virtual methods for this class. */

/* None. */

/* Save the inherited pointers to methods that will be extended, and
   replace them with pointers to the new member functions. */
   object = (AstObjectVtab *) vtab;
   mapping = (AstMappingVtab *) vtab;
   region = (AstRegionVtab *) vtab;
   frame = (AstFrameVtab *) vtab;

   parent_transform = mapping->Transform;
   mapping->Transform = Transform;

   parent_simplify = mapping->Simplify;
   mapping->Simplify = Simplify;

   parent_getuncfrm = region->GetUncFrm;
   region->GetUncFrm = GetUncFrm;

   parent_clearunc = region->ClearUnc;
   region->ClearUnc = ClearUnc;

   parent_testunc = region->TestUnc;
   region->TestUnc = TestUnc;

   parent_setregfs = region->SetRegFS;
   region->SetRegFS = SetRegFS;

   parent_equal = object->Equal;
   object->Equal = Equal;

   parent_clearclosed = region->ClearClosed;
   region->ClearClosed = ClearClosed;

   parent_clearmeshsize = region->ClearMeshSize;
   region->ClearMeshSize = ClearMeshSize;

   parent_setclosed = region->SetClosed;
   region->SetClosed = SetClosed;

   parent_setmeshsize = region->SetMeshSize;
   region->SetMeshSize = SetMeshSize;

   parent_getfillfactor = region->GetFillFactor;
   region->GetFillFactor = GetFillFactor;

   parent_overlap = region->Overlap;
   region->Overlap = Overlap;

   parent_regsetattrib = region->RegSetAttrib;
   region->RegSetAttrib = RegSetAttrib;

   parent_regclearattrib = region->RegClearAttrib;
   region->RegClearAttrib = RegClearAttrib;

/* Store replacement pointers for methods which will be over-ridden by
   new member functions implemented here. */
   region->RegBaseBox = RegBaseBox;
   region->RegBaseMesh = RegBaseMesh;
   region->RegPins = RegPins;
   region->GetBounded = GetBounded;
   region->RegCentre = RegCentre;
   region->OverlapX = OverlapX;

/* Declare the copy constructor, destructor and class dump function. */
   astSetCopy( vtab, Copy );
   astSetDelete( vtab, Delete );
   astSetDump( vtab, Dump, "Prism", "Region extrusion into higher dimensions" );
}

static int Overlap( AstRegion *this, AstRegion *that ){
/*
*  Name:
*     Overlap

*  Purpose:
*     Test if two regions overlap each other.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     int Overlap( AstRegion *this, AstRegion *that ) 

*  Class Membership:
*     Prism member function (over-rides the astOverlap method inherited 
*     from the Region class).

*  Description:
*     This function returns an integer value indicating if the two
*     supplied Regions overlap. The two Regions are converted to a commnon
*     coordinate system before performing the check. If this conversion is 
*     not possible (for instance because the two Regions represent areas in
*     different domains), then the check cannot be performed and a zero value 
*     is returned to indicate this.

*  Parameters:
*     this
*        Pointer to the first Region.
*     that
*        Pointer to the second Region.

*  Returned Value:
*     astOverlap()
*        A value indicating if there is any overlap between the two Regions.
*        Possible values are:
*
*        0 - The check could not be performed because the second Region
*            could not be mapped into the coordinate system of the first 
*            Region.
*
*        1 - There is no overlap between the two Regions.
*
*        2 - The first Region is completely inside the second Region.
*
*        3 - The second Region is completely inside the first Region.
*
*        4 - There is partial overlap between the two Regions.
*
*        5 - The Regions are identical.
*
*        6 - The second Region is the negation of the first Region.

*  Notes:
*     - The returned values 5 and 6 do not check the value of the Closed 
*     attribute in the two Regions. 
*     - A value of zero will be returned if this function is invoked with the 
*     AST error status set, or if it should fail for any reason.

*/

/* Local Variables: */
   AstFrameSet *fs;
   AstMapping *emap;
   AstMapping *map1;
   AstMapping *map2;
   AstMapping *map3;
   AstMapping *map;
   AstMapping *smap;
   AstMapping *tmap;
   AstRegion *that_reg1;
   AstRegion *that_reg2;
   AstRegion *this_reg1;
   AstRegion *this_reg2;
   AstRegion *that_prism;
   int *inax;
   int *outax;
   int i;
   int nbase;
   int next;
   int ok;
   int rbase;
   int result;     
   int rext;            
   int that_neg;
   int this_neg;

/* A table indicating how to combine together the overlap state of the 
   extrusion Regions with the overlap state of the other (base) Region.
   The first index represents the value returned by the astOverlap method
   when used to determine the overlap of the base Regions in the two
   supplied Prisms. The second index represents the value returned by the 
   astOverlap method when used to determine the overlap of the extrusion 
   Regions in the two supplied Prisms. The integer values stored in the 
   array represent the astOverlap value describing the overlap of the two
   Prisms. */
   static int rtable[ 7 ][ 7 ] = { { 0, 0, 0, 0, 0, 0, 0 },
                                   { 0, 1, 1, 1, 1, 1, 1 },
                                   { 0, 1, 2, 4, 4, 2, 1 },
                                   { 0, 1, 4, 3, 4, 3, 1 },
                                   { 0, 1, 4, 4, 4, 4, 1 },
                                   { 0, 1, 2, 3, 4, 5, 1 },
                                   { 0, 1, 1, 1, 1, 1, 6 } };

/* Initialise */
   result = 0;

/* Check the inherited status. */
   if ( !astOK ) return result;

/* We know that "this" is a Prism. See if we can find a prism equivalent
   to "that". If not, a clone of "that" is returned. */
   that_prism = EquivPrism( (AstPrism *) this, that );

/* If both Regions are Prisms, we provide a specialised implementation.
   The implementation in the parent Region class assumes that at least one of 
   the two Regions can be represented using a finite mesh of points on the 
   boundary which is not the case with some Prisms. The implementation in this 
   class sees if the Mapping between the base Frames of the Prisms allows 
   the axis limits to be transferred from one Frame ot the other. */
   if( astIsAPrism( this ) && astIsAPrism( that_prism ) ) {

/* Get the component Regions, and the Negated value for the two Prisms. The 
   returned Regions represent a region within the base Frame of the FrameSet 
   encapsulated by the parent Region structure. */
      GetRegions( (AstPrism *) this, &this_reg1, &this_reg2, &this_neg );
      GetRegions( (AstPrism *) that_prism, &that_reg1, &that_reg2, &that_neg );

/* Check that the component Regions have the same number of axes in both 
   Prisms. */
      nbase = astGetNaxes( this_reg1 );
      next = astGetNaxes( this_reg2 );
      if( astGetNaxes( that_reg1 ) == nbase &&
          astGetNaxes( that_reg2 ) == next ) {

/* Get a FrameSet which connects the Frame represented by the second Prism
   to the Frame represented by the first Prism. Check that the conection is 
   defined. */
         fs = astConvert( that_prism, this, "" );
         if( fs ) {

/* Get a pointer to the Mapping from base to current Frame in the second 
   Prism */
            map1 = astGetMapping( that_prism->frameset, AST__BASE, AST__CURRENT );

/* Get the Mapping from the current Frame of the second Prism to the
   current Frame of the first Prism. */
            map2 = astGetMapping( fs, AST__BASE, AST__CURRENT );

/* Get a pointer to the Mapping from current to base Frame in the first
   Prism. */
            map3 = astGetMapping( this->frameset, AST__CURRENT, AST__BASE );

/* Combine these Mappings to get the Mapping from the base Frame of the
   second Prism to the base Frame of the first Prism. */
            tmap = (AstMapping *) astCmpMap( map1, map2, 1, "" );
            map = (AstMapping *) astCmpMap( tmap, map3, 1, "" );

/* Simplify this Mapping. */
            smap = astSimplify( map );

/* See if the mapping between the extrusion axes of the Prisms is
   independent of the other axes. We can only test the overlap using this
   algorithm is this is the case. The extrusion axes are the trailing
   "next" axes. */
            inax = astMalloc( sizeof(int)*(size_t)next );
            for( i = 0; i < next; i++ ) inax[ i ] = nbase + i;
            outax = astMapSplit( smap, next, inax, &emap );
            if( outax ) {

/* The inputs of the Mapping returned by astMapSplit correspond to the
   extrusion axes of the second Prism. Check that the outputs of this
   Mapping correspond to the extrusion axes of the first Prism. */
               ok = 1;
               for( i = 0; i < next; i++ ) {
                  if( outax[ i ] < nbase ) {
                     ok = 0;
                     break;
                  }
               }

               if( ok ) {

/* We now know that the extrusion axes correspond in the base Frames of the 
   two Prisms. So we can test separately for overlap of the two extrusion 
   Regions, and for overlap of the two extruded Regions,and then combine
   the returned flags to represent overlap of the whole Prism. */
                  rbase = astOverlap( this_reg1, that_reg1 );
                  rext = astOverlap( this_reg2, that_reg2 );
                  result = rtable[ rbase ][ rext ];

/* The values in the rtable array assume that neither of the supplied
   Prisms have been negated. Modify the value obtained from rtable to
   take account of negation of either or both of the supplied Prisms. */
                  if( this_neg ) {
                     if( that_neg ) {
                        if( result == 1 ) {
                           result = 4;
                        } else if( result == 2 ) {
                           result = 3;
                        } else if( result == 3 ) {
                           result = 2;
                        }
                     } else {
                        if( result == 1 ) {
                           result = 3;
                        } else if( result == 2 ) {
                           result = 4;
                        } else if( result == 3 ) {
                           result = 1;
                        } else if( result == 5 ) {
                           result = 6;
                        } else if( result == 6 ) {
                           result = 5;
                        }
                     }
                  } else if( that_neg ){
                     if( result == 1 ) {
                        result = 2;
                     } else if( result == 2 ) {
                        result = 1;
                     } else if( result == 3 ) {
                        result = 4;
                     } else if( result == 5 ) {
                        result = 6;
                     } else if( result == 6 ) {
                        result = 5;
                     }
                  }
               }

/* Free resources. */
               outax = astFree( outax );
               emap = astAnnul( emap );
            }
            inax = astFree( inax );
            smap = astAnnul( smap );
            map = astAnnul( map );
            tmap = astAnnul( tmap );
            map3 = astAnnul( map3 );
            map2 = astAnnul( map2 );
            map1 = astAnnul( map1 );
            fs = astAnnul( fs );
         }
      }
      this_reg1 = astAnnul( this_reg1 );
      that_reg1 = astAnnul( that_reg1 );
      this_reg2 = astAnnul( this_reg2 );
      that_reg2 = astAnnul( that_reg2 );
   }

   that_prism = astAnnul( that_prism );

/* If overlap could not be determined using the above implementation, try 
   using the implementation inherited from the parent Region class. */
   if( !result ) result = (*parent_overlap)( this, that );

/* If not OK, return zero. */
   if( !astOK ) result = 0;

/* Return the result. */
   return result;
}

static int OverlapX( AstRegion *that, AstRegion *this ){
/*
*  Name:
*     OverlapX

*  Purpose:
*     Test if two regions overlap each other.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     int OverlapX( AstRegion *that, AstRegion *this ) 

*  Class Membership:
*     Prism member function (over-rides the astOverlapX method inherited 
*     from the Region class).

*  Description:
*     This function performs the processing for the public astOverlap
*     method and has exactly the same interface except that the order
*     of the two arguments is swapped. This is a trick to allow
*     the astOverlap method to be over-ridden by derived classes on
*     the basis of the class of either of its two arguments.
*
*     See the astOverlap method for details of the interface.
*/

/* Local Variables; */
   int result;

/* Check the global error status. */
   if ( !astOK ) return 0;

/* We know that "that" is a Prism, so call the private Overlap method,
   and then modify the returned value to take account of the fact that the
   two Regions are swapped. */
   result = Overlap( that, this );

   if( result == 2 ){
      result = 3;
   } else if( result == 3 ){
      result = 2;
   }

   return result;
}


static void RegBaseBox( AstRegion *this_region, double *lbnd, double *ubnd ){
/*
*  Name:
*     RegBaseBox

*  Purpose:
*     Returns the bounding box of an un-negated Region in the base Frame of 
*     the encapsulated FrameSet.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     void RegBaseBox( AstRegion *this, double *lbnd, double *ubnd )

*  Class Membership:
*     Prism member function (over-rides the astRegBaseBox protected
*     method inherited from the Region class).

*  Description:
*     This function returns the upper and lower axis bounds of a Region in 
*     the base Frame of the encapsulated FrameSet, assuming the Region
*     has not been negated. That is, the value of the Negated attribute
*     is ignored.

*  Parameters:
*     this
*        Pointer to the Region.
*     lbnd
*        Pointer to an array in which to return the lower axis bounds
*        covered by the Region in the base Frame of the encpauslated
*        FrameSet. It should have at least as many elements as there are 
*        axes in the base Frame.
*     ubnd
*        Pointer to an array in which to return the upper axis bounds
*        covered by the Region in the base Frame of the encapsulated
*        FrameSet. It should have at least as many elements as there are 
*        axes in the base Frame.

*/

/* Local Variables: */
   AstPrism *this;              /* Pointer to Prism structure */
   AstRegion *reg1;             /* Pointer to first component Region */
   AstRegion *reg2;             /* Pointer to second component Region */
   int nax;                     /* Number of axes in Frame */
   int neg;                     /* Negated flag for Prism */

/* Check the global error status. */
   if ( !astOK ) return;

/* Get a pointer to the Prism structure */
   this = (AstPrism *) this_region;

/* Get pointers to the component Regions. */
   GetRegions( this, &reg1, &reg2, &neg );

/* The base Frame of the parent Region structure is equivalent to a
   CmpFrame containing the current Frames of the component Regions. 
   Get the no. of axes in the first component Frame. */
   nax = astGetNaxes( reg1 );

/* Get the bounding boxes of the component Regions in these Frame,
   storing the values in the supplied arrays. */
   astGetRegionBounds( reg1, lbnd, ubnd ); 
   astGetRegionBounds( reg2, lbnd + nax, ubnd + nax ); 

/* Free resources.*/
   reg1 = astAnnul( reg1 );
   reg2 = astAnnul( reg2 );
}

static AstPointSet *RegBaseMesh( AstRegion *this_region ){
/*
*  Name:
*     RegBaseMesh

*  Purpose:
*     Return a PointSet containing a mesh of points on the boundary of a 
*     Region in its base Frame.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     AstPointSet *astRegBaseMesh( AstRegion *this )

*  Class Membership:
*     Prism member function (over-rides the astRegBaseMesh protected
*     method inherited from the Region class).

*  Description:
*     This function returns a PointSet containing a mesh of points on the
*     boundary of the Region. The points refer to the base Frame of
*     the encapsulated FrameSet.

*  Parameters:
*     this
*        Pointer to the Region.

*  Returned Value:
*     Pointer to the PointSet. Annul the pointer using astAnnul when it 
*     is no longer needed.

*  Notes:
*    - A NULL pointer is returned if an error has already occurred, or if
*    this function should fail for any reason.

*/


/* Local Variables: */
   AstPointSet *grid1;            /* PointSet holding grid for region1 */
   AstPointSet *grid2;            /* PointSet holding grid for region2 */
   AstPointSet *mesh1;            /* PointSet holding mesh for region1 */
   AstPointSet *mesh2;            /* PointSet holding mesh for region2 */
   AstPointSet *result;           /* Returned pointer */
   AstPrism *this;                /* The Prism structure */
   AstRegion *reg1;               /* Pointer to first component Region */
   AstRegion *reg2;               /* Pointer to second component Region */
   double **pg1;                  /* Pointer to grid1 arrays */
   double **pg2;                  /* Pointer to grid2 arrays */
   double **pm1;                  /* Pointer to mesh1 arrays */
   double **pm2;                  /* Pointer to mesh2 arrays */
   double **ptr;                  /* Pointer to returned mesh arrays */
   int gsz1;                      /* Preferred grid size for region1 */
   int gsz2;                      /* Preferred grid size for region2 */
   int hasMesh1;                  /* Does 1st component Region have a mesh? */
   int hasMesh2;                  /* Does 2nd component Region have a mesh? */
   int i;                         /* Index of next mesh position */
   int ii;                        /* Index of next results position */
   int j;                         /* Index of next grid position */
   int jc;                        /* Axis index */
   int msz1;                      /* Preferred mesh size for region1 */
   int msz2;                      /* Preferred mesh size for region2 */
   int msz;                       /* Original MeshSize */
   int mszp;                      /* MeshSize value for Prism */
   int nax1;                      /* Number of axes in region1 */
   int nax2;                      /* Number of axes in region2 */
   int nax;                       /* Number of axes in Prism */

/* Initialise */
   result= NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Get a pointer to the Prism structure. */
   this = (AstPrism *) this_region;

/* If the Region structure contains a pointer to a PointSet holding 
   a previously created mesh, return it. */
   if( this_region->basemesh ) {
      result = astClone( this_region->basemesh );

/* Otherwise, create a new mesh. */
   } else {

/* Get pointers to the component regions. */
      reg1 = this->region1;
      reg2 = this->region2;

/* A mesh can only be produced for a Region if it is bounded when either
   negated or un-negated. See if meshes can be produced for the component
   Regions. */
      hasMesh1 = astGetBounded( reg1 );
      if( !hasMesh1 ){
         astNegate( reg1 );
         hasMesh1 = astGetBounded( reg1 );
         astNegate( reg1 );
      }

      hasMesh2 = astGetBounded( reg2 );
      if( !hasMesh2 ){
         astNegate( reg2 );
         hasMesh2 = astGetBounded( reg2 );
         astNegate( reg2 );
      }

/* If either Region does not have a mesh we cannot produce a mesh for the
   Prism. */
      if( !hasMesh1 || !hasMesh2 ) {
         if( astOK ) astError( AST__INTER, "astRegBaseMesh(%s): No mesh "
                   "can be produced for the %s bacause one of its component "
                   "Regions is unbounded.", astGetClass( this ), astGetClass( this ) );

/* Otherwise we can create a mesh for the Prism. */
      } else {

/* Determine the grid sizes and mesh sizes to use for the two components. 
   This aims to produce a total number of points in the returned Prism
   mesh roughly equal to the MeshSize attribute of the Prism. It also
   aims to divide the mesh points equally between the end faces of the
   prism, and the side walls. We remember that the grid used to represent
   any 1-D region always has a size of 2, regardless of the setting of
   MeshSize. */
         mszp = astGetMeshSize( this );
         msz1 = ( astGetNaxes( reg1 ) == 1 ) ? 2 : sqrt( 0.5*mszp );
         gsz2 = 0.5*mszp/msz1;
         msz2 = ( astGetNaxes( reg2 ) == 1 ) ? 2 : sqrt( 0.5*mszp );
         gsz1 = 0.5*mszp/msz2;

/* First, get a boundary mesh for the Prism (second region ) defining the 
   prism extrusion. For instance, if the Prism is 1-dimensional, this mesh 
   will consist of the two values on the Prism axis: the lower and upper 
   bounds of the Prism. */
         msz = astTestMeshSize( reg2 ) ? astGetMeshSize( reg2 ) : -1;
         astSetMeshSize( reg2, msz2 );
         mesh2 = astRegMesh( reg2 );

/* Also get a grid of points spread throughout the extent (i.e. not
   merely on the boundary) of the Prism. */
         astSetMeshSize( reg2, gsz2 );
         grid2 = astRegGrid( reg2 );

/* Re-instate the original MeshSize for the second Region. */
         if( msz == -1 ) {
            astClearMeshSize( reg2 );
         } else {
            astSetMeshSize( reg2, msz );
         }

/* Similarly, get a boundary mesh and a volume grid for the first Region. */
         msz = astTestMeshSize( reg1 ) ? astGetMeshSize( reg1 ) : -1;
         astSetMeshSize( reg1, msz1 );
         mesh1 = astRegMesh( reg1 );

         astSetMeshSize( reg1, gsz1 );
         grid1 = astRegGrid( reg1 );

         if( msz == -1 ) {
            astClearMeshSize( reg1 );
         } else {
            astSetMeshSize( reg1, msz );
         }

/* Note ht enumber of axes in the two component Regions. */
         nax1 = astGetNcoord( mesh1 );
         nax2 = astGetNcoord( mesh2 );

/* The above mesh and grid sizes are only approximate. Find the values
   actually used. */
         msz1 = astGetNpoint( mesh1 );
         gsz1 = astGetNpoint( grid1 );
         msz2 = astGetNpoint( mesh2 );
         gsz2 = astGetNpoint( grid2 );

/* Create the returned PointSet. */
         msz = gsz1*msz2 + msz1*gsz2;
         nax= astGetNaxes( this );
         result = astPointSet( msz, nax, "" );

/* Get pointers to the data in all 5 PointSets. */
         ptr = astGetPoints( result );
         pm1 = astGetPoints( mesh1 );
         pg1 = astGetPoints( grid1 );
         pm2 = astGetPoints( mesh2 );
         pg2 = astGetPoints( grid2 );

/* Check pointers can be de-referenced safely. */
         if( astOK ) {         

/* Initialise the index of the next point to be written to the results
   array. */
            ii = 0;

/* First, replicate the volume grid covering the first region at every
   point in the boundary mesh covering the second Region. */
            for( i = 0; i < msz2; i++ ) {
               for( j = 0; j < gsz1; j++, ii++ ) {
                  for( jc = 0; jc < nax1; jc++ ) {
                     ptr[ jc ][ ii ] = pg1[ jc ][ j ];
                  }
                  for( ; jc < nax; jc++ ) {
                     ptr[ jc ][ ii ] = pm2[ jc - nax1 ][ i ];
                  }
               }
            }

/* Now, replicate the volume grid covering the second region at every
   point in the boundary mesh covering the first Region. */
            for( i = 0; i < msz1; i++ ) {
               for( j = 0; j < gsz2; j++, ii++ ) {
                  for( jc = 0; jc < nax1; jc++ ) {
                     ptr[ jc ][ ii ] = pm1[ jc ][ i ];
                  }
                  for( ; jc < nax; jc++ ) {
                     ptr[ jc ][ ii ] = pg2[ jc -nax1 ][ j ];
                  }
               }
            }
         }

/* Free resources. */
         mesh1 = astAnnul( mesh1 );
         mesh2 = astAnnul( mesh2 );
         grid1 = astAnnul( grid1 );
         grid2 = astAnnul( grid2 );
      }

/* Save the returned pointer in the Region structure so that it does not
   need to be created again next time this function is called. */
      if( astOK && result ) this_region->basemesh = astClone( result );
   }

/* Annul the result if an error has occurred. */
   if( !astOK ) result = astAnnul( result );

/* Return a pointer to the output PointSet. */
   return result;
}

static double *RegCentre( AstRegion *this_region, double *cen, double **ptr, 
                          int index, int ifrm ){
/*
*  Name:
*     RegCentre

*  Purpose:
*     Re-centre a Region.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     double *RegCentre( AstRegion *this, double *cen, double **ptr, 
*                        int index, int ifrm )

*  Class Membership:
*     Prism member function (over-rides the astRegCentre protected
*     method inherited from the Region class).

*  Description:
*     This function shifts the centre of the supplied Region to a
*     specified position, or returns the current centre of the Region.

*  Parameters:
*     this
*        Pointer to the Region.
*     cen
*        Pointer to an array of axis values, giving the new centre.
*        Supply a NULL value for this in order to use "ptr" and "index" to 
*        specify the new centre.
*     ptr
*        Pointer to an array of points, one for each axis in the Region.
*        Each pointer locates an array of axis values. This is the format
*        returned by the PointSet method astGetPoints. Only used if "cen"
*        is NULL.
*     index
*        The index of the point within the arrays identified by "ptr" at
*        which is stored the coords for the new centre position. Only used 
*        if "cen" is NULL.
*     ifrm
*        Should be AST__BASE or AST__CURRENT. Indicates whether the centre 
*        position is supplied and returned in the base or current Frame of 
*        the FrameSet encapsulated within "this".

*  Returned Value:
*     If both "cen" and "ptr" are NULL then a pointer to a newly
*     allocated dynamic array is returned which contains the centre
*     coords of the Region. This array should be freed using astFree when
*     no longer needed. If either of "ptr" or "cen" is not NULL, then a
*     NULL pointer is returned.

*  Notes:
*    - Some Region sub-classes do not have a centre. Such classes will report 
*    an AST__INTER error code if this method is called with either "ptr" or 
*    "cen" not NULL. If "ptr" and "cen" are both NULL, then no error is
*    reported if this method is invoked on a Region of an unsuitable class,
*    but NULL is always returned.
*/

/* Local Variables: */
   AstPrism *this;     /* Pointer to Prism structure */
   AstRegion *reg1;    /* Pointer to first component Region */
   AstRegion *reg2;    /* Pointer to second component Region */
   double *bc;         /* Base Frame centre position */
   double *cen1;       /* Centre of first component Region */
   double *cen2;       /* Centre of second component Region */
   double *result;     /* Returned pointer */
   double *tmp;        /* Temporary array pointer */
   double *total;      /* Pointer to total base Frame centre array */
   int i;              /* Coordinate index */
   int nax1;           /* Number of axes in first component Region */
   int nax2;           /* Number of axes in second component Region */
   int ncb;            /* Number of base frame coordinate values per point */
   int ncc;            /* Number of current frame coordinate values per point */
   int neg;            /* Prism negated flag */

/* Initialise */
   result = NULL;

/* Check the local error status. */
   if ( !astOK ) return result;

/* Get a pointer to the Prism structure. */
   this = (AstPrism *) this_region;

/* Get the component Regions, and the Negated flag for the Prism. */
   GetRegions( this, &reg1, &reg2, &neg );

/* Get the number of current Frame axes in each component Region. The sum
   of these will equal the number of base Frame axes in the parent Region
   structure. */
   nax1 = astGetNaxes( reg1 );
   nax2 = astGetNaxes( reg2 );
   ncb = nax1 + nax2;

/* If we are getting (not setting) the current centre... */
   if( !ptr && !cen ) {

/* Get the centre from the two component Regions in their current Frames. */
      cen1 = astRegCentre( reg1, NULL, NULL, 0, AST__CURRENT );
      cen2 = astRegCentre( reg2, NULL, NULL, 0, AST__CURRENT );

/* If both component regions are re-centerable, join the two centre
   arrays together into a single array. */      
      if( cen1 && cen2 ) {
         total = astMalloc( sizeof(double)*(size_t)ncb );
         if( total ) {
            for( i = 0; i < nax1; i++ ) total[ i ] = cen1[ i ];
            for( i = 0; i < nax2; i++ ) total[ i + nax1 ] = cen2[ i ];

/* The current Frames of the component Regions correspond to the base
   Frame of the parent Region structure. If the original centre is
   required in the current Frame, transform it using the base->current
   Mapping from the parent Region structure. */
            if( ifrm == AST__CURRENT ) {
               result = astRegTranPoint( this_region, total, 1, 1 );
               total = astFree( total );
            } else {
               result = total;
            }
         }
      }

/* Free the individual centre arrays. */
      cen1 = astFree( cen1 );
      cen2 = astFree( cen2 );

/* If we are setting a new centre... */
   } else {

/* If the new centre is supplied in the current Frame of the parent
   Region structure, transform it into the base Frame (i.e. the Frames
   represented by the component Regions). */
      if( ifrm == AST__CURRENT ) {
         if( cen ) {
            bc = astRegTranPoint( this_region, cen, 1, 0 );
         } else {
            ncc = astGetNaxes( this_region );
            tmp = astMalloc( sizeof( double)*(size_t)ncc );
            if( astOK ) {
               for( i = 0; i < ncc; i++ ) tmp[ i ] = ptr[ i ][ index ];
            }
            bc = astRegTranPoint( this_region, tmp, 1, 0 );
            tmp = astFree( tmp );
         }
 
      } else {
         if( cen ) {
            bc = cen;
         } else {
            bc = astMalloc( sizeof( double)*(size_t)ncb );
            if( astOK ) {
               for( i = 0; i < ncb; i++ ) bc[ i ] = ptr[ i ][ index ];
            }
         }
      }

/* Set the centre in the two component Regions in their current Frames. */
      astRegCentre( reg1, bc, NULL, 0, AST__CURRENT );
      astRegCentre( reg2, bc + nax1, NULL, 0, AST__CURRENT );

/* Free resources. */
     if( bc != cen ) bc = astFree( bc );       
   }

   reg1 = astAnnul( reg1 );
   reg2 = astAnnul( reg2 );

/* Return the result. */
   return result;
}

static int RegPins( AstRegion *this_region, AstPointSet *pset, AstRegion *unc,
                    int **mask ){
/*
*  Name:
*     RegPins

*  Purpose:
*     Check if a set of points fall on the boundary of a given Prism.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     int RegPins( AstRegion *this, AstPointSet *pset, AstRegion *unc,
*                  int **mask )

*  Class Membership:
*     Prism member function (over-rides the astRegPins protected
*     method inherited from the Region class).

*  Description:
*     This function returns a flag indicating if the supplied set of
*     points all fall on the boundary of the given Prism. 
*
*     Some tolerance is allowed, as specified by the uncertainty Region
*     stored in the supplied Prism "this", and the supplied uncertainty
*     Region "unc" which describes the uncertainty of the supplied points.

*  Parameters:
*     this
*        Pointer to the Prism.
*     pset
*        Pointer to the PointSet. The points are assumed to refer to the 
*        base Frame of the FrameSet encapsulated by "this".
*     unc
*        Pointer to a Region representing the uncertainties in the points
*        given by "pset". The Region is assumed to represent the base Frame 
*        of the FrameSet encapsulated by "this". Zero uncertainity is assumed 
*        if NULL is supplied.
*     mask
*        Pointer to location at which to return a pointer to a newly
*        allocated dynamic array of ints. The number of elements in this
*        array is equal to the value of the Npoint attribute of "pset".
*        Each element in the returned array is set to 1 if the
*        corresponding position in "pset" is on the boundary of the Region
*        and is set to zero otherwise. A NULL value may be supplied
*        in which case no array is created. If created, the array should
*        be freed using astFree when no longer needed.

*  Returned Value:
*     Non-zero if the points all fall on the boundary of the given
*     Region, to within the tolerance specified. Zero otherwise.

*/

/* Local variables: */
   AstPointSet *ps1;            /* Points projected into 1st component Region */
   AstPointSet *ps1b;           /* "ps1" in base Frame of 1st component Region */
   AstPointSet *ps1b2;          /* "ps1b" transformed using 1st Region */
   AstPointSet *ps2b2;          /* "ps2b" transformed using 2nd Region */
   AstPointSet *ps2;            /* Points projected into 2nd component Region */
   AstPointSet *ps2b;           /* "ps2" in base Frame of 2nd component Region */
   AstPrism *this;              /* Pointer to the Prism structure. */
   AstRegion *reg1;             /* Pointer to first component Region */
   AstRegion *reg2;             /* Pointer to second component Region */
   AstRegion *unc1;             /* Base Frame uncertainty in 1st component Region */
   AstRegion *unc2;             /* Base Frame uncertainty in 2nd component Region */
   double **ptr1b2;             /* Pointer to axis values in "ps1b2" */
   double **ptr2b2;             /* Pointer to axis values in "ps2b2" */
   int *mask1;                  /* Mask for first component boundary */
   int *mask2;                  /* Mask for second component boundary */
   int cl1;                     /* Original Closed flag for reg1 */
   int cl2;                     /* Original Closed flag for reg2 */
   int i;                       /* Point index */
   int j;                       /* Axis index */
   int nax1;                    /* Number of axes in first component Region */
   int nax2;                    /* Number of axes in second component Region */
   int np;                      /* Number of points in supplied PointSet */
   int on;                      /* Is this point on the Prism boundary? */
   int result;                  /* Returned flag */

/* Initialise */
   result = 0;
   if( mask ) *mask = NULL;

/* Check the inherited status. */
   if( !astOK ) return result;

/* Get a pointer to the Prism structure. */
   this = (AstPrism *) this_region;

/* Get pointers to the two component Regions. */
   reg1 = this->region1;
   reg2 = this->region2;

/* Temporarily ensure the components are closed. */
   cl1 = astTestClosed( reg1 ) ? astGetClosed( reg1 ) : INT_MAX;
   cl2 = astTestClosed( reg2 ) ? astGetClosed( reg2 ) : INT_MAX;
   astSetClosed( reg1, cl1 );
   astSetClosed( reg2, cl2 );

/* A point in the coordinate system represented by the Prism is on the 
   boundary of the Prism if:
   1) it is on the boundary of one of the coomponent Regions AND
   2) it is on or within the boundary of the other component Region.

   First look for points on the boundary of the first component Region. 
   Create a PointSet holding just the axes from the supplied PointSet
   which relate to the first component Region. */
   np = astGetNpoint( pset );
   nax1 = astGetNaxes( reg1 );
   ps1 = astPointSet( np, nax1, "" );
   astSetSubPoints( pset, 0, 0, ps1 );

/* Get a mask which indicates if each supplied point is on or off the 
   boundary of the first component Region. astRegPins expects its "pset"
   argument to contain positions in the base Frame of the Region, so
   we must first transform the supplied points into the base Frame of
   "reg1". We must also get the uncertainty in the base Frame of the
   component Region. */
   ps1b = astRegTransform( reg1, ps1, 0, NULL, NULL );
   unc1 = astGetUncFrm( reg1, AST__BASE );
   astRegPins( reg1, ps1b, unc1, &mask1 );

/* Also determine which of the points are on or in theboundary by using
   "reg1" as a Mapping to transform the supplied points. */
   ps1b2 = astTransform( reg1, ps1b, 1, NULL );

/* Do the same for the second component Region */
   nax2 = astGetNaxes( reg2 );
   ps2 = astPointSet( np, nax2, "" );
   astSetSubPoints( pset, 0, nax1, ps2 );
   ps2b = astRegTransform( reg2, ps2, 0, NULL, NULL );
   unc2 = astGetUncFrm( reg2, AST__BASE );
   astRegPins( reg2, ps2b, unc2, &mask2 );
   ps2b2 = astTransform( reg2, ps2b, 1, NULL );

/* Get pointers to the data in all the relevant PointSets. */
   ptr1b2 = astGetPoints( ps1b2 );
   ptr2b2 = astGetPoints( ps2b2 );

/* Check pointers can be dereferenced safely. */
   if( astOK ) {

/* Assume all points are on the boundary of the Prism. */
      result = 1;

/* Check each point. */
      for( i = 0; i < np; i++ ) {

/* Assume this point is on the boundary of the Prism. */
         on = 1;

/* If this point is on the boundary of both component Regions, it is on
   the boundary of the Prism. If it is on the boundary of the first
   component Region but not on the boundary of the second, then it is
   still on the boundary of the Prism if it is within the volume
   reporesented by the second. */
         if( mask1[ i ] ) {
            if( !mask2[ i ] ) {
               for( j = 0; j < nax2; j++ ) {
                  if( ptr2b2[ j ][ i ] == AST__BAD ) {
                     on = 0;
                     break;
                  }
               }
            }
                  
/* If this point is on the boundary of the second component Region but
   not the first, it is on the boundary of the Prism if it is within the 
   volume reporesented by the first. */
         } else {
            if( mask2[ i ] ) {
               for( j = 0; j < nax1; j++ ) {
                  if( ptr1b2[ j ][ i ] == AST__BAD ) {
                     on = 0;
                     break;
                  }
               }

/* If this point is on the boundary of neither component Region, it is not
   on the boundary of the Prism. */
            } else {
               on = 0;
            }
         }

/* Use "mask1" to return the Prism's mask. Clear the returned flag if
   this point is not on the boundary of the Prism. */
         mask1[ i ] = on;
         if( !on ) result = 0;
      }
   }

/* Re-instate the original values of the Closed attribute for the
   component Regions. */
   if( cl1 == INT_MAX ) {
      astClearClosed( reg1 );
   } else {
      astSetClosed( reg1, cl1 );
   }
   if( cl2 == INT_MAX ) {
      astClearClosed( reg2 );
   } else {
      astSetClosed( reg2, cl2 );
   }

/* Return "mask1" as the Prism's mask if required. Otherwise free it. */
   if( mask ) {
      *mask = mask1;
   } else {
      mask1 = astFree( mask1 );
   }

/* Free other resources */
   mask2 = astFree( mask2 );
   ps1 = astAnnul( ps1 );
   ps1b = astAnnul( ps1b );
   ps1b2 = astAnnul( ps1b2 );
   ps2 = astAnnul( ps2 );
   unc1 = astAnnul( unc1 );
   ps2b = astAnnul( ps2b );
   ps2b2 = astAnnul( ps2b2 );
   unc2 = astAnnul( unc2 );

/* If an error has occurred, return zero. */
   if( !astOK ) {
      result = 0;
      if( mask ) *mask = astAnnul( *mask );
   }

/* Return the result. */
   return result;
}

static void RegClearAttrib( AstRegion *this_region, const char *attrib, 
                            char **base_attrib ) {
/*
*  Name:
*     RegClearAttrib

*  Purpose:
*     Clear an attribute value for a Region.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     void RegClearAttrib( AstRegion *this, const char *attrib, 
*                          char **base_attrib ) 

*  Class Membership:
*     CmpRegion member function (over-rides the astRegClearAttrib method 
*     inherited from the Region class).

*  Description:
*     This function clears the value of a named attribute in both the base 
*     and current Frame in the FrameSet encapsulated within a Region, without
*     remapping either Frame. 
*
*     No error is reported if the attribute is not recognised by the base 
*     Frame.

*  Parameters:
*     this
*        Pointer to the Region.
*     attrib
*        Pointer to a null terminated string holding the attribute name.
*        NOTE, IT SHOULD BE ENTIRELY LOWER CASE. 
*     base_attrib
*        Address of a location at which to return a pointer to the null 
*        terminated string holding the attribute name which was cleared in 
*        the base Frame of the encapsulated FrameSet. This may differ from
*        the supplied attribute if the supplied attribute contains an axis 
*        index and the current->base Mapping in the FrameSet produces an
*        axis permutation. The returned pointer should be freed using
*        astFree when no longer needed. A NULL pointer may be supplied in 
*        which case no pointer is returned.

*/

/* Local Variables: */
   AstPrism *this; 
   AstRegion *creg;
   char *batt;
   char buf1[ 100 ];
   char buf2[ 255 ];
   int axis;
   int len;
   int nax1;
   int nc;
   int rep;

/* Check the global error status. */
   if ( !astOK ) return;

/* Get a pointer to the Prism structure. */
   this = (AstPrism *) this_region;

/* Use the RegClearAttrib method inherited from the parent class to clear the 
   attribute in the current and base Frames in the FrameSet encapsulated by 
   the parent Region structure. */
   (*parent_regclearattrib)( this_region, attrib, &batt );

/* We now propagate the setting down to the component Regions. The current 
   Frames in the component Regions together form a CmpFrame which is 
   equivalent to the base Frame in the parent FrameSet. Switch off error 
   reporting whilst we apply the setting to the component Regions. */
   rep = astReporting( 0 );

/* If the setting which was applied to the base Frame of the parent FrameSet
   is qualified by an axis index, modify the axis index to refer to component 
   Region which defines the axis. First parse the base Frame attribute setting 
   to locate any axis index. */
   len = strlen( batt );
   if( nc = 0, ( 2 == astSscanf( batt, "%[^(](%d) %n", buf1, &axis, 
                                 &nc ) ) && ( nc >= len ) ) {

/* If found, convert the axis index from one-based to zero-based. */
      axis--;

/* Get a pointer to the component Region containing the specified axis, and
   create a new setting with the same attribute name but with the axis index
   appropriate to the component Region which defines the axis. */
      nax1 = astGetNaxes( this->region1 );
      if( axis < nax1 ) {
         creg = this->region1;
      } else {
         creg = this->region2;
         axis -= nax1;
      }
      sprintf( buf2, "%s(%d)", buf1, axis + 1 );

/* Apply the setting to the relevant component Region. */
      astRegClearAttrib( creg, buf2, NULL );

/* If the setting is not qualified by an axis index, apply it to both
   component Regions. */
   } else {
      astRegClearAttrib( this->region1, batt, NULL );
      astRegClearAttrib( this->region2, batt, NULL );
   }

/* Annul the error if the attribute was not recognised by the component
   Regions. Then switch error reporting back on. */
   if( astStatus == AST__BADAT ) astClearStatus;
   astReporting( rep );

/* If required, return the base Frame setting string. Otherwise free it. */
   if( base_attrib ) {
      *base_attrib = batt;
   } else {
      batt = astFree( batt );
   }

}

static void RegSetAttrib( AstRegion *this_region, const char *setting, 
                          char **base_setting ) {
/*
*  Name:
*     RegSetAttrib

*  Purpose:
*     Set an attribute value for a Region.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     void RegSetAttrib( AstRegion *this, const char *setting, 
*                        char **base_setting )

*  Class Membership:
*     Prism method (over-rides the astRegSetAttrib method inherited from
*     the Region class).

*  Description:
*     This function assigns an attribute value to both the base and
*     current Frame in the FrameSet encapsulated within a Region, without
*     remapping either Frame. 
*
*     No error is reported if the attribute is not recognised by the base 
*     Frame.

*  Parameters:
*     this
*        Pointer to the Region.
*     setting
*        Pointer to a null terminated attribute setting string. NOTE, IT 
*        SHOULD BE ENTIRELY LOWER CASE. The supplied string will be 
*        interpreted using the public interpretation implemented by
*        astSetAttrib. This can be different to the interpretation of the 
*        protected accessor functions. For instance, the public
*        interpretation of an unqualified floating point value for the 
*        Epoch attribute is to interpet the value as a gregorian year,
*        but the protected interpretation is to interpret the value as an 
*        MJD.
*     base_setting
*        Address of a location at which to return a pointer to the null 
*        terminated attribute setting string which was applied to the
*        base Frame of the encapsulated FrameSet. This may differ from
*        the supplied setting if the supplied setting contains an axis 
*        index and the current->base Mapping in the FrameSet produces an
*        axis permutation. The returned pointer should be freed using
*        astFree when no longer needed. A NULL pointer may be supplied in 
*        which case no pointer is returned.

*/

/* Local Variables: */
   AstPrism *this; 
   AstRegion *creg;
   char *bset;
   char buf1[ 100 ];
   char buf2[ 255 ];
   int axis;
   int len;
   int nax1;
   int nc;
   int rep;
   int value;

/* Check the global error status. */
   if ( !astOK ) return;

/* Get a pointer to the Prism structure. */
   this = (AstPrism *) this_region;

/* Use the RegSetAttrib method inherited from the parent class to apply the 
   setting to the current and base Frames in the FrameSet encapsulated by the 
   parent Region structure. */
   (*parent_regsetattrib)( this_region, setting, &bset );

/* We now propagate the setting down to the component Regions. The current 
   Frames in the component Regions together form a CmpFrame which is 
   equivalent to the base Frame in the parent FrameSet. Switch off error 
   reporting whilst we apply the setting to the component Regions. */
   rep = astReporting( 0 );

/* If the setting which was applied to the base Frame of the parent FrameSet
   is qualified by an axis index, modify the axis index to refer to component 
   Region which defines the axis. First parse the base Frame attribute setting 
   to locate any axis index. */
   len = strlen( bset );
   if( nc = 0, ( 2 == astSscanf( bset, "%[^(](%d)= %n%*s %n", buf1, &axis, 
                                 &value, &nc ) ) && ( nc >= len ) ) {

/* If found, convert the axis index from one-based to zero-based. */
      axis--;

/* Get a pointer to the component Region containing the specified axis, and
   create a new setting with the same attribute name but with the axis index
   appropriate to the component Region which defines the axis. */
      nax1 = astGetNaxes( this->region1 );
      if( axis < nax1 ) {
         creg = this->region1;
      } else {
         creg = this->region2;
         axis -= nax1;
      }
      sprintf( buf2, "%s(%d)=%s", buf1, axis + 1, bset + value );

/* Apply the setting to the relevant component Region. */
      astRegSetAttrib( creg, buf2, NULL );

/* If the setting is not qualified by an axis index, apply it to both
   component Regions. */
   } else {
      astRegSetAttrib( this->region1, bset, NULL );
      astRegSetAttrib( this->region2, bset, NULL );
   }

/* Annul the error if the attribute was not recognised by the component
   Regions. Then switch error reporting back on. */
   if( astStatus == AST__BADAT ) astClearStatus;
   astReporting( rep );

/* If required, return the base Frame setting string. Otherwise free it. */
   if( base_setting ) {
      *base_setting = bset;
   } else {
      bset = astFree( bset );
   }

}

static void SetRegFS( AstRegion *this_region, AstFrame *frm ) {
/*
*  Name:
*     SetRegFS

*  Purpose:
*     Stores a new FrameSet in a Region

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     void SetRegFS( AstRegion *this_region, AstFrame *frm )

*  Class Membership:
*     Prism method (over-rides the astSetRegFS method inherited from
*     the Region class).

*  Description:
*     This function creates a new FrameSet and stores it in the supplied
*     Region. The new FrameSet contains two copies of the supplied
*     Frame, connected by a UnitMap.

*  Parameters:
*     this
*        Pointer to the Region.
*     frm
*        The Frame to use.

*/

/* Local Variables: */
   AstFrame *cfrm;         /* Frame containing required axes */
   AstRegion *creg;        /* Pointer to component Region structure */
   int *axes;              /* Pointer to array of axis indices */
   int i;                  /* Loop count */
   int nax1;               /* No.of axes in 1st component Frame */
   int nax2;               /* No.of axes in 2nd component Frame */

/* Check the global error status. */
   if ( !astOK ) return;

/* Invoke the parent method to store the FrameSet in the parent Region
   structure. */
   (* parent_setregfs)( this_region, frm );

/* If either component Region has a dummy FrameSet use this method
   recursively to give them a FrameSet containing the corresponding axes
   from the supplied Frame. */
   creg = ((AstPrism *) this_region )->region1;
   if( creg ) {
      nax1 = astGetNaxes( creg );
      if( !astGetRegionFS( creg ) ) {
         axes = astMalloc( sizeof( int )*(size_t) nax1 );
         if( astOK ) for( i = 0; i < nax1; i++ ) axes[ i ] = i;
         cfrm = astPickAxes( frm, nax1, axes, NULL );
         astSetRegFS( creg, cfrm );
         axes = astFree( axes );
         cfrm = astAnnul( cfrm );
      }

   } else {
      nax1 = 0;
   }

   creg = ((AstPrism *) this_region )->region2;
   if( creg && !astGetRegionFS( creg ) ) {
      nax2 = astGetNaxes( creg );
      axes = astMalloc( sizeof( int )*(size_t) nax2 );
      if( astOK ) for( i = 0; i < nax2; i++ ) axes[ i ] = nax1 + i;
      cfrm = astPickAxes( frm, nax2, axes, NULL );
      astSetRegFS( creg, cfrm );
      axes = astFree( axes );
      cfrm = astAnnul( cfrm );
   }

}

static AstMapping *Simplify( AstMapping *this_mapping ) {
/*
*  Name:
*     Simplify

*  Purpose:
*     Simplify a Region.

*  Type:
*     Private function.

*  Synopsis:
*     #include "region.h"
*     AstMapping *Simplify( AstMapping *this )

*  Class Membership:
*     Prism method (over-rides the astSimplify method inherited from
*     the Region class).

*  Description:
*     This function simplifies a Prism to eliminate redundant
*     computational steps, or to merge separate steps which can be
*     performed more efficiently in a single operation.

*  Parameters:
*     this
*        Pointer to the original Region.

*  Returned Value:
*     A new pointer to the (possibly simplified) Region.

*  Notes:
*     - A NULL pointer value will be returned if this function is
*     invoked with the AST error status set, or if it should fail for
*     any reason.

*  Deficiencies:
*     - Currently, this function does not attempt to map the component
*     Regions into the current Frame of the parent Region structure.

*/

/* Local Variables: */
   AstFrame *bfrm;               /* Base Frame */
   AstFrame *cfrm;               /* Current Frame */
   AstFrame *newfrm1;            /* Current Frame axes for reg1 */
   AstFrame *newfrm2;            /* Current Frame axes for reg2 */
   AstFrameSet *fs;              /* Parent FrameSet */
   AstMapping *bcmap;            /* Base->current Mapping */
   AstMapping *nmap1;            /* Reg1->current Mapping */
   AstMapping *nmap2;            /* Reg2->current Mapping */
   AstMapping *result;           /* Result pointer to return */
   AstPointList *newpl;          /* New PointList */
   AstPointList *ps1;            /* PointList PointSet */
   AstPrism *cpr;                /* Component Prism */
   AstPrism *new;                /* New Prism */
   AstRegion *new2;              /* New Interval or Box */
   AstRegion *newpl2;            /* Remapped new PointList */
   AstRegion *newreg1;           /* Reg1 mapped into current Frame */
   AstRegion *newreg2;           /* Reg2 mapped into current Frame */
   AstRegion *reg1;              /* First component Region */
   AstRegion *reg2;              /* Second component Region */
   AstRegion *reg;               /* This Region */
   AstRegion *snewreg1;          /* Simplified newreg1 */
   AstRegion *snewreg2;          /* Simplified newreg2 */
   AstRegion *unc;               /* Uncertainty Region */
   double **ptr1;                /* PointList axis values */
   double *lbnd;                 /* Lower bounds of Interval subregion */
   double *p1;                   /* Pointer to next old axis value */
   double *p;                    /* Pointer to next new axis value */
   double *points;               /* Work space holding PointList axis values */
   double *ubnd;                 /* Upper bounds of Interval subregion */
   int *axin;                    /* Indices of Mapping inputs to use */
   int *axout1;                  /* Indices of cfrm axes corresponding to reg1 */
   int *axout2;                  /* Indices of cfrm axes corresponding to reg2 */
   int *perm;                    /* Axis permutation array */
   int i;                        /* Loop count */
   int j;                        /* Loop count */
   int nax1;                     /* Number of axes in first component Region */
   int nax2;                     /* Number of axes in second component Region */
   int naxt;                     /* Total number of axes in current Frame */
   int naxout1;                  /* Number of current axes for reg1 */
   int naxout2;                  /* Number of current axes for reg2 */
   int neg;                      /* Negated flag for supplied Prism */
   int np;                       /* Number of points in PointList */
   int ok;                       /* Can PointList and Interval be combined? */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Get a pointer to the Region structure */
   reg = (AstRegion *) this_mapping;

/* Get the component Regions, and the Negated flag for the Prism. */
   GetRegions( (AstPrism *) this_mapping, &reg1, &reg2, &neg );

/* Get the number of axes in each component Region. */
   nax1 = astGetNaxes( reg1 );
   nax2 = astGetNaxes( reg2 );

/* The above Regions describe areas within the base Frame of the FrameSet 
   encapsulated by the parent Region structure. Get the current Frame in
   this FrameSet and the base->current Mapping. */
   fs = reg->frameset;
   cfrm = astGetFrame( fs, AST__CURRENT );
   bcmap = astGetMapping( fs, AST__BASE, AST__CURRENT );

/* Special Case: If the extruded region is a PointList and the extrusion
   Region is a non-negated, closed, Interval with zero length on every axis 
   (i.e. a point), then the two Regions can be combined into a single
   PointList. Check the Region classes are right. */
   if( astIsAPointList( reg1 ) && astIsAInterval( reg2 ) ) {

/* Check the Negated and Closed values are right. */
      if( astGetClosed( reg2 ) && !astGetNegated( reg2 ) && 
          astGetClosed( reg1 ) && !astGetNegated( reg1 ) ) {

/* Get the bounds of the Interval in its current Frame */
         lbnd = astMalloc( sizeof( double )*(size_t) nax2 );
         ubnd = astMalloc( sizeof( double )*(size_t) nax2 );
         if( ubnd ) {
            astGetRegionBounds( reg2, lbnd, ubnd );

/* See if the bounds cover a single value. */
            ok = 1;
            for( i = 0; i < nax2; i++ ) {
               if( !EQUAL( lbnd[i], ubnd[i] ) ) {
                  ok = 0;
                  break;
               }
            }

/* If so, get the axis values from the PointList in its current Frame,
   and allocate workspace for a PointList with the same number of points
   but with the extra axes inherited form the Interval. */
            if( ok ) {
               ps1 = astRegTransform( reg1, NULL, 1, NULL, NULL );
               ptr1 = astGetPoints( ps1 );
               np = astGetNpoint( ps1 );
               points = astMalloc( sizeof( double )*(size_t)( np*( nax1 + nax2 ) ) );
               if( points ) {

/* Copy the axis values form the old PointList to the first nax1 axes of
   the new PointList. */
                  p = points;
                  for( i = 0; i < nax1; i++) {
                     p1 = ptr1[ i ];
                     for( j = 0; j < np; j++ ) *(p++) = *(p1++);
                  }

/* Fill up the remaining nax2 axes of the new PointList by copying the 
   axis values covered by the Interval. */
                  for( i = 0; i < nax2; i++) {
                     for( j = 0; j < np; j++ ) *(p++) = lbnd[ i ];
                  }

/* We create a new PointList within the base Frame of "this" prism, using
   the base Frame uncertainty from "this" (if set). */
                  bfrm = astGetFrame( fs, AST__BASE );
                  unc = astTestUnc( reg ) ? astGetUncFrm( reg, AST__BASE ) : NULL;
                  newpl = astPointList( bfrm, np, nax1 + nax2, np, points, 
                                        unc, "" );

/* Finally map it into the current Frame of "this" and simplify it. */
                  newpl2 = astMapRegion( newpl, bcmap, cfrm );
                  result = astSimplify( newpl2 );

/* Free resources */
                  newpl = astAnnul( newpl );
                  newpl2 = astAnnul( newpl2 );
                  if( unc ) unc = astAnnul( unc );
                  bfrm = astAnnul( bfrm );
                  points = astFree( points );                  
               }
               ps1 = astAnnul( ps1 );
            }
         }
         ubnd = astFree( ubnd );
         lbnd = astFree( lbnd );
      }
   }

/* If the special case above produced a result, skip the rest */
   if( !result ) {

/* Use astMapSplit to see if the axes of the first component Region correspond
   to a distinct set of axes within the current Frame. If this is the case, 
   then a Mapping is returned by astMapSplit which  maps the axes of the first 
   component Region into the corresponding current Frame axes. Also returned 
   is a list of the axes within the current Frame which correspnd to the
   axes of the first component Region. */
      nmap1 = NULL;
      axout1 = NULL;
      axin = astMalloc( sizeof( int )*(size_t)nax1 );
      if( astOK ) {
         for( i = 0; i < nax1; i++ ) axin[ i ] = i;
         axout1 = astMapSplit( bcmap, nax1, axin, &nmap1 );
         axin = astFree( axin );
      }
   
/* Do the same for the second component. */
      nmap2 = NULL;
      axout2 = NULL;
      axin = astMalloc( sizeof( int )*(size_t)nax2 );
      if( astOK ) {
         for( i = 0; i < nax2; i++ ) axin[ i ] = i + nax1;
         axout2 = astMapSplit( bcmap, nax2, axin, &nmap2 );
         axin = astFree( axin );
      }
   
/* Assume for the moment that the component Regions cannot be simplified.
   In this case we will use a clone of the supplied Prism. */
      new = astClone( this_mapping );

/* Determine the number of outputs from these Mappings. */
      if( nmap1 ){
         naxout1 = astGetNout( nmap1 );
      } else {
         naxout1 = 0;
      }
      if( nmap2 ){
         naxout2 = astGetNout( nmap2 );
      } else {
         naxout2 = 0;
      }

/* Determine the number of axes in the current Frame of the Prism. */
      naxt = astGetNout( bcmap );

/* If the second component does not contribute any axes to the total
   Prism, we can ignore it. */
      if( naxout1 == naxt && naxout2 == 0 ) {
         newfrm1 = astPickAxes( cfrm, naxout1, axout1, NULL );
         newreg1 = astMapRegion( reg1, nmap1, newfrm1 );
         astAnnul( new );
         new = astSimplify( newreg1 );      
         if( neg ) astNegate( new );
         perm = astMalloc( sizeof( int )*(size_t) ( naxout1 ) );
         if( astOK ) {
            for( i = 0; i < naxout1; i++ ) perm[ i ] = axout1[ i ];
            astPermAxes( new, perm );
            perm = astFree( perm );
         }
         newfrm1 = astAnnul( newfrm1 );
         newreg1 = astAnnul( newreg1 );

/* If the first component does not contribute any axes to the total
   Prism, we can ignore it. */
      } else if( naxout1 == 0 && naxout2 == naxt ) {
         newfrm2 = astPickAxes( cfrm, naxout2, axout2, NULL );
         newreg2 = astMapRegion( reg2, nmap2, newfrm2 );
         astAnnul( new );
         new = astSimplify( newreg2 );      
         if( neg ) astNegate( new );
         perm = astMalloc( sizeof( int )*(size_t) ( naxout2 ) );
         if( astOK ) {
            for( i = 0; i < naxout2; i++ ) perm[ i ] = axout2[ i ];
            astPermAxes( new, perm );
            perm = astFree( perm );
         }
         newfrm2 = astAnnul( newfrm2 );
         newreg2 = astAnnul( newreg2 );
   
/* If both component Regions correspond to a distinct subspace within the
   current Frame, then we can try to express each component Region within
   the current Frame. */
      } else if( nmap1 && nmap2 ) {
   
/* Create a Frame representing the subspace of the current Frame which
   corresponds to the axes of the first component Region. */
         newfrm1 = astPickAxes( cfrm, naxout1, axout1, NULL );
   
/* Remap the first component Region so that it represents an area in this
   subspace. */
         newreg1 = astMapRegion( reg1, nmap1, newfrm1 );
   
/* Attempt to simplify the remapped Region. */
         snewreg1 = astSimplify( newreg1 );      
   
/* Do the same for the second component Region. */
         naxout2 = astGetNout( nmap2 );
         newfrm2 = astPickAxes( cfrm, naxout2, axout2, NULL );
         newreg2 = astMapRegion( reg2, nmap2, newfrm2 );
         snewreg2 = astSimplify( newreg2 );      
   
/* If the simplified second component is no longer an Interval or Box, revert 
   to the original Interval. */
         if( !astIsAInterval( snewreg2 ) && !astIsABox( snewreg2 ) ) {
            astAnnul( snewreg2 );
            snewreg2 = astClone( newreg2 );
         }
   
/* If either component Region was simplified, create a new Prism from the 
   simplified Regions. */
         if( snewreg1 != newreg1 || snewreg2 != newreg2 ) {
            astAnnul( new );
            new = astPrism( snewreg1, snewreg2, "" );
   
/* Ensure the new Prism has the same Negated attribute as the original. */
            if( neg ) astNegate( new );
   
/* Ensure that the new Prism has the same axis order as the original
   current Frame. */
            perm = astMalloc( sizeof( int )*(size_t) ( naxout1 + naxout2 ) );
            if( astOK ) {
               for( i = 0; i < naxout1; i++ ) perm[ i ] = axout1[ i ];
               for( ; i < naxout1 + naxout2; i++ ) perm[ i ] = axout2[ i - naxout1 ];
               astPermAxes( new, perm );
               perm = astFree( perm );
            }
         }
   
/* Free resources. */
         newfrm1 = astAnnul( newfrm1 );
         newfrm2 = astAnnul( newfrm2 );
         newreg1 = astAnnul( newreg1 );
         newreg2 = astAnnul( newreg2 );
         snewreg1 = astAnnul( snewreg1 );
         snewreg2 = astAnnul( snewreg2 );
      }
   
/* The second component Region in the Prism is known to be an Interval. 
   If the first component Region is also an Interval, a Box, or a NullRegion 
   we can replace the Prism by a single Interval defined within a CmpFrame.
   Attempt to do this. If succesful, attempt to simplify the new Region
   and use it in place of the original. */
      if( new && astIsAPrism( new ) ) {
         new2 = astMergeInterval( new->region2, new->region1 );
         if( new2 ) {
            astAnnul( new );
            new = astSimplify( new2 );
            new2 = astAnnul( new2 );
   
/* If not succesful, see if the first component Region is a Prism. If so
   we can merge the two extrusion Regions into a single Interval. */
         } else if( astIsAPrism( new->region1 ) ) {
            cpr = ( AstPrism *) ( new->region1 );
            newreg1 = cpr->region1;
            newreg2 = astMergeInterval( new->region2, cpr->region2 );
            if( newreg2 ) {
               new2 = (AstRegion *) astPrism( newreg1, newreg2, "" );
               astAnnul( new );
               new = astSimplify( new2 );
               new2 = astAnnul( new2 );
            }
            newreg2 = astAnnul( newreg2 );
         }      
      }
   
/* Now invoke the parent Simplify method inherited from the Region class. 
   This will simplify the encapsulated FrameSet and uncertainty Region. */
      result = (*parent_simplify)( (AstMapping *) new );
   
/* Free resources. */
      new = astAnnul( new );
      if( axout1 ) axout1 = astFree( axout1 );
      if( axout2 ) axout2 = astFree( axout2 );
      if( nmap1 ) nmap1 = astAnnul( nmap1 );
      if( nmap2 ) nmap2 = astAnnul( nmap2 );
   }

   reg1 = astAnnul( reg1 );
   reg2 = astAnnul( reg2 );
   cfrm = astAnnul( cfrm );
   bcmap = astAnnul( bcmap );

/* If any simplification could be performed, copy Region attributes from 
   the supplied Region to the returned Region, and return a pointer to it.
   Otherwise, return a clone of the supplied pointer. */
   if( result != this_mapping ) astRegOverlay( result, (AstRegion *) this_mapping );

/* If an error occurred, annul the returned Mapping. */
   if ( !astOK ) result = astAnnul( result );

/* Return the result. */
   return result;
}

static int TestUnc( AstRegion *this_region ) {
/*
*  Name:
*     TestUnc

*  Purpose:
*     Does the Region contain non-default uncertainty information?

*  Type:
*     Private function.

*  Synopsis:
*     include "prism.h"
*     int astTestUnc( AstRegion *this )

*  Class Membership:
*     Prism member function (over-rides the astTestUnc protected
*     method inherited from the Region class).

*  Description:
*     This function returns a flag indicating if the uncertainty Region in 
*     the supplied Region was supplied explicit (i.e. is not a default 
*     uncertainty Region).

*  Parameters:
*     this
*        Pointer to the Region.

*  Returned Value:
*     Non-zero if the uncertainty Region was supplied explicitly.
*     Zero otherwise.

*/

/* Local Variables; */
   AstPrism *this;
   int result;

/* Check the global error status. */
   if ( !astOK ) return 0;

/* Get a pointer to the Prism structure. */
   this = (AstPrism *) this_region;

/* See if the parent Region structure contains explicit uncertainty
   information. If so this will be used in preference to any uncertainty
   info in the component Regions. */
   result = (* parent_testunc)( this_region );

/* If not see if either of the two component Regions contains explicit 
   uncertainty information. */
   if( !result ) {
      this = (AstPrism *) this_region;
      result = astTestUnc( this->region1 ) || astTestUnc( this->region2 );
   }

/* Return the result */
   return result;
}

static AstPointSet *Transform( AstMapping *this_mapping, AstPointSet *in,
                               int forward, AstPointSet *out ) {
/*
*  Name:
*     Transform

*  Purpose:
*     Apply a Prism to transform a set of points.

*  Type:
*     Private function.

*  Synopsis:
*     #include "prism.h"
*     AstPointSet *Transform( AstMapping *this, AstPointSet *in,
*                             int forward, AstPointSet *out )

*  Class Membership:
*     Prism member function (over-rides the astTransform method inherited
*     from the Region class).

*  Description:
*     This function takes a Prism and a set of points encapsulated in a
*     PointSet and transforms the points so as to apply the required Region.
*     This implies applying each of the Prism's component Regions in turn,
*     either in series or in parallel.

*  Parameters:
*     this
*        Pointer to the Prism.
*     in
*        Pointer to the PointSet associated with the input coordinate values.
*     forward
*        A non-zero value indicates that the forward coordinate transformation
*        should be applied, while a zero value requests the inverse
*        transformation.
*     out
*        Pointer to a PointSet which will hold the transformed (output)
*        coordinate values. A NULL value may also be given, in which case a
*        new PointSet will be created by this function.

*  Returned Value:
*     Pointer to the output (possibly new) PointSet.

*  Notes:
*     -  A null pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*     -  The number of coordinate values per point in the input PointSet must
*     match the number of coordinates for the Prism being applied.
*     -  If an output PointSet is supplied, it must have space for sufficient
*     number of points and coordinate values per point to accommodate the
*     result. Any excess space will be ignored.
*/

/* Local Variables: */
   AstCmpMap *map;               /* CmpMap containing component Regions */
   AstPointSet *psb;             /* Pointer to base Frame PointSet */
   AstPointSet *pset_tmp;        /* Pointer to PointSet holding base Frame positions*/
   AstPointSet *result;          /* Pointer to output PointSet */
   AstPrism *this;               /* Pointer to the Prism structure */
   AstRegion *reg1;              /* Pointer to first component Region */
   AstRegion *reg2;              /* Pointer to second component Region */
   double **ptr_out;             /* Pointer to output coordinate data */
   double **ptrb;                /* Pointer to base Frame axis values */
   int coord;                    /* Zero-based index for coordinates */
   int good;                     /* Is the point inside the Prism? */
   int ncoord_out;               /* No. of coordinates per output point */
   int ncoord_tmp;               /* No. of coordinates per base Frame point */
   int neg;                      /* Has Prism been negated? */
   int npoint;                   /* No. of points */
   int point;                    /* Loop counter for points */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Get a Pointer to the Prism structure */
   this = (AstPrism *) this_mapping;

/* Get the component Regions, and the Negated value for the Prism. */
   GetRegions( this, &reg1, &reg2, &neg );

/* Apply the parent mapping using the stored pointer to the Transform member
   function inherited from the parent Region class. This function validates
   all arguments and generates an output PointSet if necessary, containing 
   a copy of the input PointSet. */
   result = (*parent_transform)( this_mapping, in, forward, out );

/* We will now extend the parent astTransform method by performing the
   calculations needed to generate the output coordinate values. */

/* First use the encapsulated FrameSet in the parent Region structure to 
   transform the supplied positions from the current Frame in the 
   encapsulated FrameSet (the Frame represented by the Prism), to the 
   base Frame (the Frame in which the component Regions are defined). Note,
   the returned pointer may be a clone of the "in" pointer, and so we 
   must be carefull not to modify the contents of the returned PointSet. */
   pset_tmp = astRegTransform( this, in, 0, NULL, NULL );

/* Form a parallel CmpMap from the two component Regions. */
   map = astCmpMap( reg1, reg2, 0, "" );

/* Apply the Mapping to the PointSet containing positions in the base Frame 
   of the parent Region structure (which is the same as the combination of
   the current Frames of the component Regions). */
   psb = astTransform( map, pset_tmp, 1, NULL );

/* Annul the Mapping pointer. */
   map = astAnnul( map );

/* Determine the numbers of points and coordinates per point for these base
   Frame PointSets and obtain pointers for accessing the base Frame and output 
   coordinate values. */
   npoint = astGetNpoint( pset_tmp );
   ncoord_tmp = astGetNcoord( pset_tmp );
   ptrb = astGetPoints( psb );      
   ncoord_out = astGetNcoord( result );
   ptr_out = astGetPoints( result );

/* Perform coordinate arithmetic. */
/* ------------------------------ */
   if ( astOK ) {
      for ( point = 0; point < npoint; point++ ) {
         good = 1;

         for ( coord = 0; coord < ncoord_tmp; coord++ ) {
            if( ptrb[ coord ][ point ] == AST__BAD ){
               good = 0;
               break;
            }
         }      

         if( good == neg ) {
            for ( coord = 0; coord < ncoord_out; coord++ ) {
               ptr_out[ coord ][ point ] = AST__BAD;
            }
         }      
      }
   }

/* Free resources. */
   reg1 = astAnnul( reg1 );
   reg2 = astAnnul( reg2 );
   psb = astAnnul( psb );
   pset_tmp = astAnnul( pset_tmp );

/* If an error occurred, clean up by deleting the output PointSet (if
   allocated by this function) and setting a NULL result pointer. */
   if ( !astOK ) {
      if ( !out ) result = astDelete( result );
      result = NULL;
   }

/* Return a pointer to the output PointSet. */
   return result;
}

/* Copy constructor. */
/* ----------------- */
static void Copy( const AstObject *objin, AstObject *objout ) {
/*
*  Name:
*     Copy

*  Purpose:
*     Copy constructor for Prism objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Copy( const AstObject *objin, AstObject *objout )

*  Description:
*     This function implements the copy constructor for Prism objects.

*  Parameters:
*     objin
*        Pointer to the object to be copied.
*     objout
*        Pointer to the object being constructed.

*  Returned Value:
*     void

*  Notes:
*     -  This constructor makes a deep copy, including a copy of the component
*     Regions within the Prism.
*/

/* Local Variables: */
   AstPrism *in;                /* Pointer to input Prism */
   AstPrism *out;               /* Pointer to output Prism */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain pointers to the input and output Prisms. */
   in = (AstPrism *) objin;
   out = (AstPrism *) objout;

/* For safety, start by clearing any references to the input component
   Regions from the output Prism. */
   out->region1 = NULL;
   out->region2 = NULL;

/* Make copies of these Regions and store pointers to them in the output
   Prism structure. */
   out->region1 = astCopy( in->region1 );
   out->region2 = astCopy( in->region2 );
}

/* Destructor. */
/* ----------- */
static void Delete( AstObject *obj ) {
/*
*  Name:
*     Delete

*  Purpose:
*     Destructor for Prism objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Delete( AstObject *obj )

*  Description:
*     This function implements the destructor for Prism objects.

*  Parameters:
*     obj
*        Pointer to the object to be deleted.

*  Returned Value:
*     void

*  Notes:
*     This function attempts to execute even if the global error status is
*     set.
*/

/* Local Variables: */
   AstPrism *this;              /* Pointer to Prism */

/* Obtain a pointer to the Prism structure. */
   this = (AstPrism *) obj;

/* Annul the pointers to the component Regions. */
   this->region1 = astAnnul( this->region1 );
   this->region2 = astAnnul( this->region2 );
}

/* Dump function. */
/* -------------- */
static void Dump( AstObject *this_object, AstChannel *channel ) {
/*
*  Name:
*     Dump

*  Purpose:
*     Dump function for Prism objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Dump( AstObject *this, AstChannel *channel )

*  Description:
*     This function implements the Dump function which writes out data
*     for the Prism class to an output Channel.

*  Parameters:
*     this
*        Pointer to the Prism whose data are being written.
*     channel
*        Pointer to the Channel to which the data are being written.
*/

/* Local Variables: */
   AstPrism *this;               /* Pointer to the Prism structure */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the Prism structure. */
   this = (AstPrism *) this_object;

/* Write out values representing the instance variables for the Prism
   class.  Accompany these with appropriate comment strings, possibly
   depending on the values being written.*/

/* In the case of attributes, we first use the appropriate (private)
   Test...  member function to see if they are set. If so, we then use
   the (private) Get... function to obtain the value to be written
   out.

   For attributes which are not set, we use the astGet... method to
   obtain the value instead. This will supply a default value
   (possibly provided by a derived class which over-rides this method)
   which is more useful to a human reader as it corresponds to the
   actual default attribute value.  Since "set" will be zero, these
   values are for information only and will not be read back. */

/* First Region. */
/* -------------- */
   astWriteObject( channel, "RegionA", 1, 1, this->region1,
                   "First component Region" );

/* Second Region. */
/* --------------- */
   astWriteObject( channel, "RegionB", 1, 1, this->region2,
                   "Second component Region" );
}

/* Standard class functions. */
/* ========================= */
/* Implement the astIsAPrism and astCheckPrism functions using the
   macros defined for this purpose in the "object.h" header file. */
astMAKE_ISA(Prism,Region,check,&class_init)
astMAKE_CHECK(Prism)

AstPrism *astPrism_( void *region1_void, void *region2_void, 
                     const char *options, ... ) {
/*
*+
*  Name:
*     astPrism

*  Purpose:
*     Create a Prism.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "prism.h"
*     AstPrism *astPrism( AstRegion *region1, AstInterval *region2, 
*                         const char *options, ... )

*  Class Membership:
*     Prism constructor.

*  Description:
*     This function creates a new Prism and optionally initialises its
*     attributes.

*  Parameters:
*     region1
*        Pointer to the Region to be extruded.
*     region2
*        Pointer to the Interval defining the extent of the extrusion.
*     options
*        Pointer to a null terminated string containing an optional
*        comma-separated list of attribute assignments to be used for
*        initialising the new Prism. The syntax used is the same as for the
*        astSet method and may include "printf" format specifiers identified
*        by "%" symbols in the normal way.
*     ...
*        If the "options" string contains "%" format specifiers, then an
*        optional list of arguments may follow it in order to supply values to
*        be substituted for these specifiers. The rules for supplying these
*        are identical to those for the astSet method (and for the C "printf"
*        function).

*  Returned Value:
*     A pointer to the new Prism.

*  Notes:
*     - A null pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*-

*  Implementation Notes:
*     - This function implements the basic Prism constructor which is
*     available via the protected interface to the Prism class.  A
*     public interface is provided by the astPrismId_ function.
*     - Because this function has a variable argument list, it is
*     invoked by a macro that evaluates to a function pointer (not a
*     function invocation) and no checking or casting of arguments is
*     performed before the function is invoked. Because of this, the
*     "region1" and "region2" parameters are of type (void *) and are
*     converted and validated within the function itself.
*/

/* Local Variables: */
   AstPrism *new;                  /* Pointer to new Prism */
   AstRegion *region1;             /* Pointer to first Region structure */
   AstRegion *region2;             /* Pointer to second Region structure */
   va_list args;                   /* Variable argument list */

/* Initialise. */
   new = NULL;

/* Check the global status. */
   if ( !astOK ) return new;

/* Obtain and validate pointers to the Region structures provided. */
   region1 = astCheckRegion( region1_void );
   region2 = astCheckRegion( region2_void );
   if ( astOK ) {

/* Initialise the Prism, allocating memory and initialising the
   virtual function table as well if necessary. */
      new = astInitPrism( NULL, sizeof( AstPrism ), !class_init, 
                          &class_vtab, "Prism", region1, region2 );

/* If successful, note that the virtual function table has been
   initialised. */
      if ( astOK ) {
         class_init = 1;

/* Obtain the variable argument list and pass it along with the
   options string to the astVSet method to initialise the new Prism's
   attributes. */
         va_start( args, options );
         astVSet( new, options, args );
         va_end( args );

/* If an error occurred, clean up by deleting the new object. */
         if ( !astOK ) new = astDelete( new );
      }
   }

/* Return a pointer to the new Prism. */
   return new;
}

AstPrism *astPrismId_( void *region1_void, void *region2_void, 
                       const char *options, ... ) {
/*
*++
*  Name:
c     astPrism
f     AST_PRISM

*  Purpose:
*     Create a Prism.

*  Type:
*     Public function.

*  Synopsis:
c     #include "prism.h"
c     AstPrism *astPrism( AstRegion *region1, AstRegion *region2, 
c                         const char *options, ... )
f     RESULT = AST_PRISM( REGION1, REGION2, OPTIONS, STATUS )

*  Class Membership:
*     Prism constructor.

*  Description:
*     This function creates a new Prism and optionally initialises
*     its attributes.
*
*     A Prism is a Region which represents an extrusion of an existing Region 
*     into one or more orthogonal dimensions (specified by an Interval or
*     Box). If the Region to be extruded has N axes, and the Interval or Box 
*     defining the extrusion has M axes, then the resulting Prism will have 
*     (M+N) axes. A point is inside the Prism if the first N axis values 
*     correspond to a point which is inside the Region being extruded, and the 
*     remaining M axis values correspond to a point which inside the supplied 
*     Interval or Box.
*
*     As an example, a cylinder can be represented by extruding an existing 
*     Circle. In this case the supplied Interval would have a single axis and 
*     would specify the upper and lower limits of the cylinder along its 
*     length.

*  Parameters:
c     region1
f     REGION1 = INTEGER (Given)
*        Pointer to the Region to be extruded.
c     region2
f     REGION2 = INTEGER (Given)
*        Pointer to the Interval or Box defining the extent of the extrusion.
c     options
f     OPTIONS = CHARACTER * ( * ) (Given)
c        Pointer to a null-terminated string containing an optional
c        comma-separated list of attribute assignments to be used for
c        initialising the new Prism. The syntax used is identical to
c        that for the astSet function and may include "printf" format
c        specifiers identified by "%" symbols in the normal way.
f        A character string containing an optional comma-separated
f        list of attribute assignments to be used for initialising the
f        new Prism. The syntax used is identical to that for the
f        AST_SET routine.
c     ...
c        If the "options" string contains "%" format specifiers, then
c        an optional list of additional arguments may follow it in
c        order to supply values to be substituted for these
c        specifiers. The rules for supplying these are identical to
c        those for the astSet function (and for the C "printf"
c        function).
f     STATUS = INTEGER (Given and Returned)
f        The global status.

*  Returned Value:
c     astPrism()
f     AST_PRISM = INTEGER
*        A pointer to the new Prism.

*  Notes:
*     - Deep copies are taken of the supplied Regions. This means that
*     any subsequent changes made to the component Regions using the 
*     supplied pointers will have no effect on the Prism.
*     - A null Object pointer (AST__NULL) will be returned if this
c     function is invoked with the AST error status set, or if it
f     function is invoked with STATUS set to an error value, or if it
*     should fail for any reason.
*--

*  Implementation Notes:
*     - This function implements the external (public) interface to
*     the astPrism constructor function. It returns an ID value
*     (instead of a true C pointer) to external users, and must be
*     provided because astPrism_ has a variable argument list which
*     cannot be encapsulated in a macro (where this conversion would
*     otherwise occur).
*     - Because no checking or casting of arguments is performed
*     before the function is invoked, the "region1" and "region2" parameters
*     are of type (void *) and are converted from an ID value to a
*     pointer and validated within the function itself.
*     - The variable argument list also prevents this function from
*     invoking astPrism_ directly, so it must be a re-implementation
*     of it in all respects, except for the conversions between IDs
*     and pointers on input/output of Objects.
*/

/* Local Variables: */
   AstPrism *new;                  /* Pointer to new Prism */
   AstRegion *region1;             /* Pointer to first Region structure */
   AstRegion *region2;             /* Pointer to second Region structure */
   va_list args;                   /* Variable argument list */

/* Initialise. */
   new = NULL;

/* Check the global status. */
   if ( !astOK ) return new;

/* Obtain the Region pointers from the ID's supplied and validate the
   pointers to ensure they identify valid Regions. */
   region1 = astCheckRegion( astMakePointer( region1_void ) );
   region2 = astCheckRegion( astMakePointer( region2_void ) );
   if ( astOK ) {

/* Initialise the Prism, allocating memory and initialising the
   virtual function table as well if necessary. */
      new = astInitPrism( NULL, sizeof( AstPrism ), !class_init, 
                          &class_vtab, "Prism", region1, region2 );

/* If successful, note that the virtual function table has been initialised. */
      if ( astOK ) {
         class_init = 1;

/* Obtain the variable argument list and pass it along with the
   options string to the astVSet method to initialise the new Prism's
   attributes. */
         va_start( args, options );
         astVSet( new, options, args );
         va_end( args );

/* If an error occurred, clean up by deleting the new object. */
         if ( !astOK ) new = astDelete( new );
      }
   }

/* Return an ID value for the new Prism. */
   return astMakeId( new );
}

AstPrism *astInitPrism_( void *mem, size_t size, int init,
                         AstPrismVtab *vtab, const char *name,
                         AstRegion *region1, AstRegion *region2 ) {
/*
*+
*  Name:
*     astInitPrism

*  Purpose:
*     Initialise a Prism.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "prism.h"
*     AstPrism *astInitPrism_( void *mem, size_t size, int init,
*                              AstPrismVtab *vtab, const char *name,
*                              AstRegion *region1, AstRegion *region2 )

*  Class Membership:
*     Prism initialiser.

*  Description:
*     This function is provided for use by class implementations to initialise
*     a new Prism object. It allocates memory (if necessary) to
*     accommodate the Prism plus any additional data associated with the
*     derived class. It then initialises a Prism structure at the start
*     of this memory. If the "init" flag is set, it also initialises the
*     contents of a virtual function table for a Prism at the start of
*     the memory passed via the "vtab" parameter.

*  Parameters:
*     mem
*        A pointer to the memory in which the Prism is to be initialised.
*        This must be of sufficient size to accommodate the Prism data
*        (sizeof(Prism)) plus any data used by the derived class. If a
*        value of NULL is given, this function will allocate the memory itself
*        using the "size" parameter to determine its size.
*     size
*        The amount of memory used by the Prism (plus derived class
*        data). This will be used to allocate memory if a value of NULL is
*        given for the "mem" parameter. This value is also stored in the
*        Prism structure, so a valid value must be supplied even if not
*        required for allocating memory.
*     init
*        A logical flag indicating if the Prism's virtual function table
*        is to be initialised. If this value is non-zero, the virtual function
*        table will be initialised by this function.
*     vtab
*        Pointer to the start of the virtual function table to be associated
*        with the new Prism.
*     name
*        Pointer to a constant null-terminated character string which contains
*        the name of the class to which the new object belongs (it is this
*        pointer value that will subsequently be returned by the Object
*        astClass function).
*     region1
*        Pointer to the first Region.
*     region2
*        Pointer to the second Region (must be an Box or Interval).

*  Returned Value:
*     A pointer to the new Prism.

*  Notes:
*     -  A null pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*-
*/

/* Local Variables: */
   AstPrism *new;                /* Pointer to new Prism */
   AstFrame *frm1;               /* Frame encapsulated by 1st Region */
   AstFrame *frm2;               /* Frame encapsulated by 2nd Region */
   AstFrame *frm;                /* CmpFrame formed from frm1 and frm2 */
   AstMapping *map;              /* Mapping between two supplied Regions */
   AstRegion *reg1;              /* Copy of first supplied Region */
   AstRegion *reg2;              /* Copy of second supplied Region */

/* Check the global status. */
   if ( !astOK ) return NULL;

/* If necessary, initialise the virtual function table. */
   if ( init ) astInitPrismVtab( vtab, name );

/* Initialise. */
   new = NULL;
   reg2 = NULL;

/* Take a copy of the first supplied Region. */
   reg1 = astCopy( region1 );
   
/* If the second Region is Box, create a corresponding Interval from it. */
   if( astIsABox( region2 ) ) {
      reg2 = astBoxInterval( region2 );

/* If the second Region is an Interval, use a copy of it. */
   } else if( astIsAInterval( region2 ) ) {
      reg2 = astCopy( region2 );

/* Otherwise, report an error. */
   } else if( astOK ) {
      astError( AST__BADIN, "astInitPrism(%s): Bad extrusion Region "
                "class (%s) supplied.", name, astGetClass( region2 ) );
      astError( AST__NCPIN, "The extrusion Region must be a Box or "
                "Interval." );
   }

/* Form a CmpFrame representing the combined Frame of these two Regions. */
   frm1 = astRegFrame( reg1 );
   frm2 = astRegFrame( reg2 );
   frm = (AstFrame *) astCmpFrame( frm1, frm2, "" );
   
/* Initialise a Region structure (the parent class) as the first component
   within the Prism structure, allocating memory if necessary. A NULL
   PointSet is suppled as the two component Regions will perform the function
   of defining the Region shape. The base Frame of the FrameSet in the
   parent Region structure will be the CmpFrame formed from the two component 
   Regions. */
   if ( astOK ) {
      new = (AstPrism *) astInitRegion( mem, size, 0, (AstRegionVtab *) vtab, 
                                        name, frm, NULL, NULL );

/* Initialise the Prism data. */
/* --------------------------- */
/* Store pointers to the component Regions. */
      new->region1 = reg1;
      new->region2 = reg2;

/* If the base->current Mapping in the FrameSet within a component Region 
   is a UnitMap, then the FrameSet does not need to be included in the
   Dump of the new Prism. Set the RegionFS attribute of the component
   Region to zero to flag this. */
      map = astGetMapping( reg1->frameset, AST__BASE, AST__CURRENT );
      if( astIsAUnitMap( map ) ) astSetRegionFS( reg1, 0 );
      map = astAnnul( map );

      map = astGetMapping( reg2->frameset, AST__BASE, AST__CURRENT );
      if( astIsAUnitMap( map ) ) astSetRegionFS( reg2, 0 );
      map = astAnnul( map );

/* If an error occurred, clean up by annulling the Region pointers and
   deleting the new object. */
      if ( !astOK ) {
         new->region1 = astAnnul( new->region1 );
         new->region2 = astAnnul( new->region2 );
         new = astDelete( new );
      }
   }

/* Free resources */
   frm = astAnnul( frm );
   frm1 = astAnnul( frm1 );
   frm2 = astAnnul( frm2 );

/* Return a pointer to the new object. */
   return new;
}

AstPrism *astLoadPrism_( void *mem, size_t size, AstPrismVtab *vtab, 
                         const char *name, AstChannel *channel ) {
/*
*+
*  Name:
*     astLoadPrism

*  Purpose:
*     Load a Prism.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "prism.h"
*     AstPrism *astLoadPrism( void *mem, size_t size, AstPrismVtab *vtab, 
*                             const char *name, AstChannel *channel )

*  Class Membership:
*     Prism loader.

*  Description:
*     This function is provided to load a new Prism using data read
*     from a Channel. It first loads the data used by the parent class
*     (which allocates memory if necessary) and then initialises a
*     Prism structure in this memory, using data read from the input
*     Channel.
*
*     If the "init" flag is set, it also initialises the contents of a
*     virtual function table for a Prism at the start of the memory
*     passed via the "vtab" parameter.


*  Parameters:
*     mem
*        A pointer to the memory into which the Prism is to be
*        loaded.  This must be of sufficient size to accommodate the
*        Prism data (sizeof(Prism)) plus any data used by derived
*        classes. If a value of NULL is given, this function will
*        allocate the memory itself using the "size" parameter to
*        determine its size.
*     size
*        The amount of memory used by the Prism (plus derived class
*        data).  This will be used to allocate memory if a value of
*        NULL is given for the "mem" parameter. This value is also
*        stored in the Prism structure, so a valid value must be
*        supplied even if not required for allocating memory.
*
*        If the "vtab" parameter is NULL, the "size" value is ignored
*        and sizeof(AstPrism) is used instead.
*     vtab
*        Pointer to the start of the virtual function table to be
*        associated with the new Prism. If this is NULL, a pointer to
*        the (static) virtual function table for the Prism class is
*        used instead.
*     name
*        Pointer to a constant null-terminated character string which
*        contains the name of the class to which the new object
*        belongs (it is this pointer value that will subsequently be
*        returned by the astGetClass method).
*
*        If the "vtab" parameter is NULL, the "name" value is ignored
*        and a pointer to the string "Prism" is used instead.

*  Returned Value:
*     A pointer to the new Prism.

*  Notes:
*     - A null pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*-
*/

/* Local Variables: */
   AstFrame *cfrm;         /* Frame containing required axes */
   AstFrame *f1;           /* Base Frame in parent Region */
   AstPrism *new;          /* Pointer to the new Prism */
   AstRegion *creg;        /* Pointer to component Region */
   int *axes;              /* Pointer to array of axis indices */
   int i;                  /* Loop count */
   int nax1;               /* No.of axes in 1st component Frame */
   int nax2;               /* No.of axes in 2nd component Frame */

/* Initialise. */
   new = NULL;

/* Check the global error status. */
   if ( !astOK ) return new;

/* If a NULL virtual function table has been supplied, then this is
   the first loader to be invoked for this Prism. In this case the
   Prism belongs to this class, so supply appropriate values to be
   passed to the parent class loader (and its parent, etc.). */
   if ( !vtab ) {
      size = sizeof( AstPrism );
      vtab = &class_vtab;
      name = "Prism";

/* If required, initialise the virtual function table for this class. */
      if ( !class_init ) {
         astInitPrismVtab( vtab, name );
         class_init = 1;
      }
   }

/* Invoke the parent class loader to load data for all the ancestral
   classes of the current one, returning a pointer to the resulting
   partly-built Prism. */
   new = astLoadRegion( mem, size, (AstRegionVtab *) vtab, name,
                         channel );

   if ( astOK ) {

/* Read input data. */
/* ================ */
/* Request the input Channel to read all the input data appropriate to
   this class into the internal "values list". */
      astReadClassData( channel, "Prism" );

/* Now read each individual data item from this list and use it to
   initialise the appropriate instance variable(s) for this class. */

/* In the case of attributes, we first read the "raw" input value,
   supplying the "unset" value as the default. If a "set" value is
   obtained, we then use the appropriate (private) Set... member
   function to validate and set the value properly. */

/* First Region. */
/* -------------- */
      new->region1 = astReadObject( channel, "regiona", NULL );

/* Second Region. */
/* --------------- */
      new->region2 = astReadObject( channel, "regionb", NULL );

/* Either component Region may currently contain a dummy FrameSet rather than 
   the correct FrameSet (see the Dump function for this class). In this case, 
   the correct FrameSet will have copies of selected axes from the base Frame 
   of the new Prism as both its current and base Frames, and these are 
   connected by a UnitMap (this is equivalent to a FrameSet containing a 
   single Frame). However if the new Prism being loaded has itself got a dummy 
   FrameSet, then we do not do this since we do not yet know what the correct 
   FrameSet is. In this case we wait until the parent Region invokes the 
   astSetRegFS method on the new Prism. */
      if( !astRegDummyFS( new ) ) {
         f1 = astGetFrame( ((AstRegion *) new)->frameset, AST__BASE );

         creg = new->region1;
         nax1 = astGetNaxes( creg );
         if( astRegDummyFS( creg ) ) {
            axes = astMalloc( sizeof( int )*(size_t) nax1 );
            if( astOK ) for( i = 0; i < nax1; i++ ) axes[ i ] = i;
            cfrm = astPickAxes( f1, nax1, axes, NULL );
            astSetRegFS( creg, cfrm );
            axes = astFree( axes );
            cfrm = astAnnul( cfrm );
         }

         creg = new->region2;
         if( astRegDummyFS( creg ) ) {
            nax2 = astGetNaxes( creg );
            axes = astMalloc( sizeof( int )*(size_t) nax2 );
            if( astOK ) for( i = 0; i < nax2; i++ ) axes[ i ] = nax1 + i;
            cfrm = astPickAxes( f1, nax2, axes, NULL );
            astSetRegFS( creg, cfrm );
            axes = astFree( axes );
            cfrm = astAnnul( cfrm );
         }

         f1 = astAnnul( f1 );
      }

/* If an error occurred, clean up by deleting the new Prism. */
      if ( !astOK ) new = astDelete( new );
   }

/* Return the new Prism pointer. */
   return new;
}

/* Virtual function interfaces. */
/* ============================ */
/* These provide the external interface to the virtual functions defined by
   this class. Each simply checks the global error status and then locates and
   executes the appropriate member function, using the function pointer stored
   in the object's virtual function table (this pointer is located using the
   astMEMBER macro defined in "object.h").

   Note that the member function may not be the one defined here, as it may
   have been over-ridden by a derived class. However, it should still have the
   same interface. */

/* None. */

