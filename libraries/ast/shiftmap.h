#if !defined( SHIFTMAP_INCLUDED ) /* Include this file only once */
#define SHIFTMAP_INCLUDED
/*
*+
*  Name:
*     shiftmap.h

*  Type:
*     C include file.

*  Purpose:
*     Define the interface to the ShiftMap class.

*  Invocation:
*     #include "shiftmap.h"

*  Description:
*     This include file defines the interface to the ShiftMap class and
*     provides the type definitions, function prototypes and macros,
*     etc.  needed to use this class.
*
*     The ShiftMap class implements Mappings which shift each coordinate
*     by a fixed amount.

*  Inheritance:
*     The ShiftMap class inherits from the Mapping class.

*  Attributes Over-Ridden:
*     None.

*  New Attributes Defined:
*     None.

*  Methods Over-Ridden:
*     Public:
*        None.
*
*     Protected:
*        ClearAttrib
*           Clear an attribute value for a ShiftMap.
*        GetAttrib
*           Get an attribute value for a ShiftMap.
*        SetAttrib
*           Set an attribute value for a ShiftMap.
*        TestAttrib
*           Test if an attribute value has been set for a ShiftMap.
*        astMapMerge
*           Simplify a sequence of Mappings containing a ShiftMap.
*        astTransform
*           Apply a ShiftMap to transform a set of points.

*  New Methods Defined:
*     Public:
*        None.
*
*     Protected:
*        None.

*  Other Class Functions:
*     Public:
*        astIsAShiftMap
*           Test class membership.
*        astShiftMap
*           Create a ShiftMap.
*
*     Protected:
*        astCheckShiftMap
*           Validate class membership.
*        astInitShiftMap
*           Initialise a ShiftMap.
*        astInitShiftMapVtab
*           Initialise the virtual function table for the ShiftMap class.
*        astLoadShiftMap
*           Load a ShiftMap.

*  Macros:
*     None.

*  Type Definitions:
*     Public:
*        AstShiftMap
*           ShiftMap object type.
*
*     Protected:
*        AstShiftMapVtab
*           ShiftMap virtual function table type.

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
*     14-AUG-2003 (DSB):
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
/* ShiftMap structure. */
/* ------------------ */
/* This structure contains all information that is unique to each object in
   the class (e.g. its instance variables). */
typedef struct AstShiftMap {

/* Attributes inherited from the parent class. */
   AstMapping mapping;           /* Parent class structure */

/* Attributes specific to objects in this class. */
   double *shift;                /* Pointer to array of shifts */

} AstShiftMap;

/* Virtual function table. */
/* ----------------------- */
/* This table contains all information that is the same for all
   objects in the class (e.g. pointers to its virtual functions). */
#if defined(astCLASS)            /* Protected */
typedef struct AstShiftMapVtab {

/* Properties (e.g. methods) inherited from the parent class. */
   AstMappingVtab mapping_vtab;  /* Parent class virtual function table */

/* Unique flag value to determine class membership. */
   int *check;                   /* Check value */

/* Properties (e.g. methods) specific to this class. */

} AstShiftMapVtab;
#endif

/* Function prototypes. */
/* ==================== */
/* Prototypes for standard class functions. */
/* ---------------------------------------- */
astPROTO_CHECK(ShiftMap)          /* Check class membership */
astPROTO_ISA(ShiftMap)            /* Test class membership */

/* Constructor. */
#if defined(astCLASS)            /* Protected. */
AstShiftMap *astShiftMap_( int, const double [], const char *, ... );
#else
AstShiftMap *astShiftMapId_( int, const double [], const char *, ... );
#endif

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
AstShiftMap *astInitShiftMap_( void *, size_t, int, AstShiftMapVtab *,
                               const char *, int, const double * );

/* Vtab initialiser. */
void astInitShiftMapVtab_( AstShiftMapVtab *, const char * );

/* Loader. */
AstShiftMap *astLoadShiftMap_( void *, size_t, AstShiftMapVtab *,
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
#define astCheckShiftMap(this) astINVOKE_CHECK(ShiftMap,this)

/* Test class membership. */
#define astIsAShiftMap(this) astINVOKE_ISA(ShiftMap,this)

/* Constructor. */
#if defined(astCLASS)            /* Protected. */
#define astShiftMap astINVOKE(F,astShiftMap_)
#else
#define astShiftMap astINVOKE(F,astShiftMapId_)
#endif

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
#define \
astInitShiftMap(mem,size,init,vtab,name,ncoord,shift) \
astINVOKE(O,astInitShiftMap_(mem,size,init,vtab,name,ncoord,shift))

/* Vtab Initialiser. */
#define astInitShiftMapVtab(vtab,name) astINVOKE(V,astInitShiftMapVtab_(vtab,name))
/* Loader. */
#define astLoadShiftMap(mem,size,vtab,name,channel) \
astINVOKE(O,astLoadShiftMap_(mem,size,vtab,name,astCheckChannel(channel)))
#endif

/* Interfaces to public member functions. */
/* -------------------------------------- */
/* Here we make use of astCheckShiftMap to validate ShiftMap pointers
   before use.  This provides a contextual error report if a pointer
   to the wrong sort of Object is supplied. */

#if defined(astCLASS)            /* Protected */
#endif

#endif
