#if !defined( POLYMAP_INCLUDED ) /* Include this file only once */
#define POLYMAP_INCLUDED
/*
*+
*  Name:
*     polymap.h

*  Type:
*     C include file.

*  Purpose:
*     Define the interface to the PolyMap class.

*  Invocation:
*     #include "polymap.h"

*  Description:
*     This include file defines the interface to the PolyMap class and
*     provides the type definitions, function prototypes and macros,
*     etc.  needed to use this class.
*
*     A PolyMap is a form of Mapping which performs a general polynomial
*     transformation.  Each output coordinate is a polynomial function of
*     all the input coordinates. The coefficients are specified separately 
*     for each output coordinate. The forward and inverse transformations
*     are defined independantly by separate sets of coefficients.

*  Inheritance:
*     The PolyMap class inherits from the Mapping class.

*  Attributes Over-Ridden:
*     None.

*  New Attributes Defined:
*     None.

*  Methods Over-Ridden:
*     Public:
*        None.
*
*     Protected:
*        astTransform
*           Apply a PolyMap to transform a set of points.

*  New Methods Defined:
*     Public:
*        None.
*
*     Protected:
*        None.

*  Other Class Functions:
*     Public:
*        astIsAPolyMap
*           Test class membership.
*        astPolyMap
*           Create a PolyMap.
*
*     Protected:
*        astCheckPolyMap
*           Validate class membership.
*        astInitPolyMap
*           Initialise a PolyMap.
*        astInitPolyMapVtab
*           Initialise the virtual function table for the PolyMap class.
*        astLoadPolyMap
*           Load a PolyMap.

*  Macros:
*     None.

*  Type Definitions:
*     Public:
*        AstPolyMap
*           PolyMap object type.
*
*     Protected:
*        AstPolyMapVtab
*           PolyMap virtual function table type.

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
*     DSB: D.S. Berry (Starlink)

*  History:
*     28-SEP-2003 (DSB):
*        Original version.
*-
*/

/* Include files. */
/* ============== */
/* Interface definitions. */
/* ---------------------- */
#include "mapping.h"             /* Coordinate mappings (parent class) */

#if defined(astCLASS)            /* Protected */
#include "pointset.h"            /* Sets of points/coordinates */
#include "channel.h"             /* I/O channels */
#endif

/* C header files. */
/* --------------- */
#if defined(astCLASS)            /* Protected */
#include <stddef.h>
#endif

/* Type Definitions. */
/* ================= */
/* PolyMap structure. */
/* ------------------ */
/* This structure contains all information that is unique to each object in
   the class (e.g. its instance variables). */
typedef struct AstPolyMap {

/* Attributes inherited from the parent class. */
   AstMapping mapping;           /* Parent class structure */

/* Attributes specific to objects in this class. */
   int *ncoeff_f;             /* No. of coeffs for each forward polynomial */
   int *mxpow_f;              /* Max power of each i/p axis for each forward polynomial */
   int ***power_f;            /* Pointer to i/p powers for all forward coefficients */
   double **coeff_f;          /* Pointer to values of all forward coefficients */
   int *ncoeff_i;             /* No. of coeffs for each inverse polynomial */
   int *mxpow_i;              /* Max power of each i/p axis for each inverse polynomial */
   int ***power_i;            /* Pointer to i/p powers for all inverse coefficients */
   double **coeff_i;          /* Pointer to values of all inverse coefficients */
} AstPolyMap;

/* Virtual function table. */
/* ----------------------- */
/* This table contains all information that is the same for all
   objects in the class (e.g. pointers to its virtual functions). */
#if defined(astCLASS)            /* Protected */
typedef struct AstPolyMapVtab {

/* Properties (e.g. methods) inherited from the parent class. */
   AstMappingVtab mapping_vtab;  /* Parent class virtual function table */

/* Unique flag value to determine class membership. */
   int *check;                   /* Check value */

/* Properties (e.g. methods) specific to this class. */

} AstPolyMapVtab;
#endif

/* Function prototypes. */
/* ==================== */
/* Prototypes for standard class functions. */
/* ---------------------------------------- */
astPROTO_CHECK(PolyMap)          /* Check class membership */
astPROTO_ISA(PolyMap)            /* Test class membership */

/* Constructor. */
#if defined(astCLASS)            /* Protected. */
AstPolyMap *astPolyMap_( int, int, int, const double[], int, const double[], const char *, ... );
#else
AstPolyMap *astPolyMapId_( int, int, int, const double[], int, const double[], const char *, ... );
#endif

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
AstPolyMap *astInitPolyMap_( void *, size_t, int, AstPolyMapVtab *, const char *, int, int, int, const double[], int, const double[] );

/* Vtab initialiser. */
void astInitPolyMapVtab_( AstPolyMapVtab *, const char * );

/* Loader. */
AstPolyMap *astLoadPolyMap_( void *, size_t, AstPolyMapVtab *,
                                 const char *, AstChannel * );
#endif

/* Prototypes for member functions. */
/* -------------------------------- */
# if defined(astCLASS)           /* Protected */
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
#define astCheckPolyMap(this) astINVOKE_CHECK(PolyMap,this)

/* Test class membership. */
#define astIsAPolyMap(this) astINVOKE_ISA(PolyMap,this)

/* Constructor. */
#if defined(astCLASS)            /* Protected. */
#define astPolyMap astINVOKE(F,astPolyMap_)
#else
#define astPolyMap astINVOKE(F,astPolyMapId_)
#endif

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
#define astInitPolyMap(mem,size,init,vtab,name,nin,nout,ncoeff_f,coeff_f,ncoeff_i,coeff_i) \
astINVOKE(O,astInitPolyMap_(mem,size,init,vtab,name,nin,nout,ncoeff_f,coeff_f,ncoeff_i,coeff_i))

/* Vtab Initialiser. */
#define astInitPolyMapVtab(vtab,name) astINVOKE(V,astInitPolyMapVtab_(vtab,name))
/* Loader. */
#define astLoadPolyMap(mem,size,vtab,name,channel) \
astINVOKE(O,astLoadPolyMap_(mem,size,vtab,name,astCheckChannel(channel)))
#endif

/* Interfaces to public member functions. */
/* -------------------------------------- */
/* Here we make use of astCheckPolyMap to validate PolyMap pointers
   before use.  This provides a contextual error report if a pointer
   to the wrong sort of Object is supplied. */

#if defined(astCLASS)            /* Protected */
#endif
#endif
