#if !defined( POINTSET_INCLUDED ) /* Include this file only once */
#define POINTSET_INCLUDED
/*
*+
*  Name:
*     pointset.h

*  Type:
*     C include file.

*  Purpose:
*     Define the interface to the PointSet class.

*  Invocation:
*     #include "pointset.h"

*  Description:
*     This include file defines the interface to the PointSet class
*     and provides the type definitions, function prototypes and
*     macros, etc.  needed to use this class.
*
*     The PointSet class encapsulates sets of coordinate values
*     representing points in an N-dimensional space, to which
*     coordinate transformations may be applied. It also provides
*     memory allocation facilities for coordinate values.

*  Inheritance:
*     The PointSet class inherits from the Object class.

*  Attributes Over-Ridden:
*     None.

*  New Attributes Defined:
*     Ncoord (integer)
*        A read-only attribute that gives the number of coordinates
*        for each point in a PointSet (i.e. the number of dimensions
*        of the space in which the points reside). This value is
*        determined when the PointSet is created.
*     Npoint (integer)
*        A read-only attribute that gives the number of points that
*        can be stored in the PointSet. This value is determined when
*        the PointSet is created.

*  Methods Over-Ridden:
*     Public:
*        None.
*
*     Protected:
*        ClearAttrib
*           Clear an attribute value for a PointSet.
*        GetAttrib
*           Get an attribute value for a PointSet.
*        SetAttrib
*           Set an attribute value for a PointSet.
*        TestAttrib
*           Test if an attribute value has been set for a PointSet.

*  New Methods Defined:
*     Public:
*        astGetPoints
*           Get a pointer to the coordinate values associated with a PointSet.
*        astSetPoints
*           Associate coordinate values with a PointSet.
*        astSetSubPoints
*           Associate one PointSet with a subset of another.
*
*     Protected:
*        astGetNpoint
*           Get the number of points in a PointSet.
*        astGetNcoord
*           Get the number of coordinate values per point from a PointSet.

*  Other Class Functions:
*     Public:
*        astIsAPointSet
*           Test class membership.
*        astPointSet
*           Create a PointSet.
*
*     Protected:
*        astCheckPointSet
*           Validate class membership.
*        astInitPointSet
*           Initialise a PointSet.
*        astInitPointSetVtab
*           Initialise the virtual function table for the PointSet class.
*        astLoadPointSet
*           Load a PointSet.

*  Macros:
*     Public:
*        AST__BAD
*           Bad value flag for coordinate data.
*
*     Protected:
*        astISBAD
*           Check if a value is AST__BAD or NaN.
*        astISGOOD
*           Check if a value is not AST__BAD or NaN.
*        astISNAN
*           Check if a value is NaN.

*  Type Definitions:
*     Public:
*        AstPointSet
*           PointSet object type.
*
*     Protected:
*        AstPointSetVtab
*           PointSet virtual function table type.

*  Feature Test Macros:
*     astCLASS
*        If the astCLASS macro is undefined, only public symbols are
*        made available, otherwise protected symbols (for use in other
*        class implementations) are defined. This macro also affects
*        the reporting of error context information, which is only
*        provided for external calls to the AST library.

*  Copyright:
*     <COPYRIGHT_STATEMENT>

*  Authors:
*     RFWS: R.F. Warren-Smith (Starlink)

*  History:
*     30-JAN-1996 (RFWS):
*        Original version.
*     27-SEP-1996 (RFWS):
*        Added external interface and I/O facilities.
*     8-JAN-2003 (DSB):
*        Added protected astInitPointSetVtab method.
*-
*/

/* Include files. */
/* ============== */

/* Configuration results. */
/* ---------------------- */
#include <config.h>

/* Interface definitions. */
/* ---------------------- */
#include "object.h"              /* Base Object class */

/* C header files. */
/* --------------- */
#include <float.h>
#if defined(astCLASS)            /* Protected */
#include <stddef.h>
#include <math.h>

#if !HAVE_DECL_ISNAN
#  if HAVE_ISNAN
     /* Seems that math.h does not include a prototype for isnan */
     int isnan( double );
#  else
#    define isnan(x) ((x) != (x))
#  endif
#endif
#endif

/* Macros. */
/* ======= */
/*
*+
*  Name:
*     AST__BAD

*  Type:
*     Public macro.

*  Purpose:
*     Bad value flag for coordinate data.
*  Synopsis:
*     #include "pointset.h"
*     const double AST__BAD

*  Class Membership:
*     Defined by the PointSet class.

*  Description:
*     This macro expands to a const double value that is used to flag
*     coordinate values that are "bad" (i.e. undefined or
*     meaningless). Classes that implement coordinate transformations
*     should test coordinate values against this value, and
*     appropriately propagate bad values to their output.
*-
*/

/* Define AST__BAD to be the most negative (normalised) double
   value. */
#define AST__BAD (-(DBL_MAX))

#if defined(astCLASS)            /* Protected */

/*
*+
*  Name:
*     astISNAN

*  Type:
*     Protected macro.

*  Purpose:
*     Test if a double is NaN.

*  Synopsis:
*     #include "pointset.h"
*     astISNAN(value)

*  Class Membership:
*     Defined by the PointSet class.

*  Description:
*     This macro expands to a integer valued expression which is zero
*     if and only if the supplied value equals NaN ("Not a Number").

*  Parameters:
*     value
*        The value to be tested. This should be a double.

*  Examples:
*     if( astISNAN(x) ) x = AST__BAD;
*        If "x" is NaN replace it with AST__BAD.

*  Notes:
*     - To avoid problems with some compilers, you should not leave
*     any white space around the macro arguments.
*-
*/

#define astISNAN(value) isnan(value)

/*
*+
*  Name:
*     astISGOOD

*  Type:
*     Protected macro.

*  Purpose:
*     Test if a double is neither AST__BAD nor NaN.

*  Synopsis:
*     #include "pointset.h"
*     astISGOOD(value)

*  Class Membership:
*     Defined by the PointSet class.

*  Description:
*     This macro expands to a integer valued expression which is zero
*     if and only if the supplied value equals AST__BAD or is NaN ("Not a 
*     Number").

*  Parameters:
*     value
*        The value to be tested. This should be a double.

*  Examples:
*     if( astISGOOD(x) ) y = x;
*        Checks that "x" is usable before assigning it to y.

*  Notes:
*     - To avoid problems with some compilers, you should not leave
*     any white space around the macro arguments.
*-
*/

#define astISGOOD(value) ( (value) != AST__BAD && !astISNAN(value) )


/*
*+
*  Name:
*     astISBAD

*  Type:
*     Protected macro.

*  Purpose:
*     Test if a double is either AST__BAD or NaN.

*  Synopsis:
*     #include "pointset.h"
*     astISBAD(value)

*  Class Membership:
*     Defined by the PointSet class.

*  Description:
*     This macro expands to a integer valued expression which is non-zero
*     if and only if the supplied value equals AST__BAD or is NaN ("Not a 
*     Number").

*  Parameters:
*     value
*        The value to be tested. This should be a double.

*  Examples:
*     if( astISBAD(x) ) astError( ... );
*        Reports an error if "x" is bad.

*  Notes:
*     - To avoid problems with some compilers, you should not leave
*     any white space around the macro arguments.
*-
*/

#define astISBAD(value) ( (value) == AST__BAD || astISNAN(value) )

#endif


/* Type Definitions. */
/* ================= */
/* PointSet structure. */
/* ------------------- */
/* This structure contains all information that is unique to each object in
   the class (e.g. its instance variables). */
typedef struct AstPointSet {

/* Attributes inherited from the parent class. */
   AstObject object;             /* Parent class structure */

/* Attributes specific to objects in this class. */
   double **ptr;                 /* Pointer to array of pointers to values */
   double *values;               /* Pointer to array of coordinate values */
   int ncoord;                   /* Number of coordinate values per point */
   int npoint;                   /* Number of points */
} AstPointSet;

/* Virtual function table. */
/* ----------------------- */
/* This table contains all information that is the same for all
   objects in the class (e.g. pointers to its virtual functions). */
#if defined(astCLASS)            /* Protected */
typedef struct AstPointSetVtab {

/* Properties (e.g. methods) inherited from the parent class. */
   AstObjectVtab object_vtab;    /* Parent class virtual function table */

/* Unique flag value to determine class membership. */
   int *check;                   /* Check value */

/* Properties (e.g. methods) specific to this class. */
   double **(* GetPoints)( AstPointSet * );
   int (* GetNcoord)( const AstPointSet * );
   int (* GetNpoint)( const AstPointSet * );
   void (* SetPoints)( AstPointSet *, double ** );
   void (* SetSubPoints)( AstPointSet *, int, int, AstPointSet * );
} AstPointSetVtab;
#endif

/* Function prototypes. */
/* ==================== */
/* Prototypes for standard class functions. */
/* ---------------------------------------- */
astPROTO_CHECK(PointSet)         /* Check class membership */
astPROTO_ISA(PointSet)           /* Test class membership */

/* Constructor. */
#if defined(astCLASS)            /* Protected. */
AstPointSet *astPointSet_( int, int, const char *, ... );
#else
AstPointSet *astPointSetId_( int, int, const char *, ... );
#endif

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
AstPointSet *astInitPointSet_( void *, size_t, int, AstPointSetVtab *,
                               const char *, int, int );

/* Vtab initialiser. */
void astInitPointSetVtab_( AstPointSetVtab *, const char * );

/* Loader. */
AstPointSet *astLoadPointSet_( void *, size_t, AstPointSetVtab *,
                               const char *, AstChannel * );
#endif

/* Prototypes for member functions. */
/* -------------------------------- */
double **astGetPoints_( AstPointSet * );
void astSetPoints_( AstPointSet *, double ** );
void astSetSubPoints_( AstPointSet *, int, int, AstPointSet * );

# if defined(astCLASS)           /* Protected */
int astGetNcoord_( const AstPointSet * );
int astGetNpoint_( const AstPointSet * );
#endif

/* Function interfaces. */
/* ==================== */
/* These macros are wrap-ups for the functions defined by this class
   to make them easier to invoke (e.g. to avoid type mis-matches when
   passing pointers to objects from derived classes). */

/* Interfaces to standard class functions. */
/* --------------------------------------- */
/* Some of these functions provide validation, so we cannot use them
   to validate their own arguments. We must use a cast when passing
   object pointers (so that they can accept objects from derived
   classes). */

/* Check class membership. */
#define astCheckPointSet(this) astINVOKE_CHECK(PointSet,this)

/* Test class membership. */
#define astIsAPointSet(this) astINVOKE_ISA(PointSet,this)

/* Constructor. */
#if defined(astCLASS)            /* Protected. */
#define astPointSet astINVOKE(F,astPointSet_)
#else
#define astPointSet astINVOKE(F,astPointSetId_)
#endif

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
#define astInitPointSet(mem,size,init,vtab,name,npoint,ncoord) \
astINVOKE(O,astInitPointSet_(mem,size,init,vtab,name,npoint,ncoord))

/* Vtab Initialiser. */
#define astInitPointSetVtab(vtab,name) astINVOKE(V,astInitPointSetVtab_(vtab,name))
/* Loader. */
#define astLoadPointSet(mem,size,vtab,name,channel) \
astINVOKE(O,astLoadPointSet_(mem,size,vtab,name,astCheckChannel(channel)))
#endif

/* Interfaces to public member functions. */
/* -------------------------------------- */
/* Here we make use of astCheckPointSet to validate PointSet pointers
   before use.  This provides a contextual error report if a pointer
   to the wrong sort of Object is supplied. */

#define astGetPoints(this) \
astINVOKE(V,astGetPoints_(astCheckPointSet(this)))
#define astSetPoints(this,ptr) \
astINVOKE(V,astSetPoints_(astCheckPointSet(this),ptr))
#define astSetSubPoints(point1,point,coord,point2) \
astINVOKE(V,astSetSubPoints_(astCheckPointSet(point1),point,coord,astCheckPointSet(point2)))

#if defined(astCLASS)            /* Protected */
#define astGetNpoint(this) \
astINVOKE(V,astGetNpoint_(astCheckPointSet(this)))
#define astGetNcoord(this) \
astINVOKE(V,astGetNcoord_(astCheckPointSet(this)))
#endif
#endif
