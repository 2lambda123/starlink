/*
*class++
*  Name:
*     CmpMap

*  Purpose:
*     Compound Mapping.

*  Constructor Function:
c     astCmpMap
f     AST_CMPMAP

*  Description:
*     A CmpMap is a compound Mapping which allows two component
*     Mappings (of any class) to be connected together to form a more
*     complex Mapping. This connection may either be "in series"
*     (where the first Mapping is used to transform the coordinates of
*     each point and the second mapping is then applied to the
*     result), or "in parallel" (where one Mapping transforms the
*     earlier coordinates for each point and the second Mapping
*     simultaneously transforms the later coordinates).
*
*     Since a CmpMap is itself a Mapping, it can be used as a
*     component in forming further CmpMaps. Mappings of arbitrary
*     complexity may be built from simple individual Mappings in this
*     way.

*  Inheritance:
*     The CmpMap class inherits from the Mapping class.

*  Attributes:
*     The CmpMap class does not define any new attributes beyond those
*     which are applicable to all Mappings.

*  Functions:
c     The CmpMap class does not define any new functions beyond those
f     The CmpMap class does not define any new routines beyond those
*     which are applicable to all Mappings.

*  Copyright:
*     <COPYRIGHT_STATEMENT>

*  Authors:
*     RFWS: R.F. Warren-Smith (Starlink)

*  History:
*     1-FEB-1996 (RFWS):
*        Original version.
*     25-SEP-1996 (RFWS):
*        Implemented external interface and I/O facilities.
*     12-DEC-1996 (RFWS):
*        Over-ride the astMapList method.
*     13-DEC-1996 (RFWS):
*        Over-ride the astSimplify method.
*     4-JUN-1997 (RFWS):
*        Eliminate any simplification when MapList is used. Instead,
*        over-ride the MapMerge method and implement all
*        simplification in this.
*     24-MAR-1998 (RFWS):
*        Fixed bug in testing of simplified invert flag in Simplify.
*     15-APR-1998 (RFWS):
*        Improved the MapMerge method to allow parallel combinations
*        of series CmpMaps to be replaced by series combinations of
*        parallel CmpMaps, and vice versa.
*     26-SEP-2001 (DSB):
*        Over-ride the astDecompose method.
*     8-JAN-2003 (DSB):
*        - Changed private InitVtab method to protected astInitCmpMapVtab
*        method.
*     8-JAN-2003 (DSB):
*        - Modified MapMerge so that a parallel CmpMap can swap with a
*        suitable PermMap lower neighbour.
*     23-APR-2004 (DSB):
*        - Modified Simplify to avoid infinite loops.
*     27-APR-2004 (DSB):
*        - Correction to MapMerge to prevent segvio if CmpMap and PermMap
*        cannot be swapped.
*     4-OCT-2004 (DSB):
*        Modify astMapList to return flag indicating presence of inverted
*        CmpMaps in supplied Mapping.
*class--
*/

/* Module Macros. */
/* ============== */
/* Set the name of the class we are implementing. This indicates to
   the header files that define class interfaces that they should make
   "protected" symbols available. */
#define astCLASS CmpMap

/* Include files. */
/* ============== */
/* Interface definitions. */
/* ---------------------- */
#include "error.h"               /* Error reporting facilities */
#include "memory.h"              /* Memory allocation facilities */
#include "object.h"              /* Base Object class */
#include "pointset.h"            /* Sets of points/coordinates */
#include "mapping.h"             /* Coordinate Mappings (parent class) */
#include "channel.h"             /* I/O channels */
#include "permmap.h"             /* Coordinate permutation Mappings */
#include "cmpmap.h"              /* Interface definition for this class */

/* Error code definitions. */
/* ----------------------- */
#include "ast_err.h"             /* AST error codes */

/* C header files. */
/* --------------- */
#include <stdarg.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>

/* Module Variables. */
/* ================= */
/* Define the class virtual function table and its initialisation flag
   as static variables. */
static AstCmpMapVtab class_vtab; /* Virtual function table */
static int class_init = 0;       /* Virtual function table initialised? */

/* Pointers to parent class methods which are extended by this class. */
static AstPointSet *(* parent_transform)( AstMapping *, AstPointSet *, int, AstPointSet * );
static int (* parent_maplist)( AstMapping *, int, int, int *, AstMapping ***, int ** );

/* External Interface Function Prototypes. */
/* ======================================= */
/* The following functions have public prototypes only (i.e. no
   protected prototypes), so we must provide local prototypes for use
   within this module. */
AstCmpMap *astCmpMapId_( void *, void *, int, const char *, ... );

/* Prototypes for Private Member Functions. */
/* ======================================== */
static AstMapping *CombineMaps( AstMapping *, int, AstMapping *, int, int );
static AstMapping *Simplify( AstMapping * );
static AstPointSet *Transform( AstMapping *, AstPointSet *, int, AstPointSet * );
static double Rate( AstMapping *, double *, int, int );
static int CountMappings( AstMapping * );
static int PatternCheck( int, int, int **, int * );
static int MapMerge( AstMapping *, int, int, int *, AstMapping ***, int ** );
static void Copy( const AstObject *, AstObject * );
static void Decompose( AstMapping *, AstMapping **, AstMapping **, int *, int *, int * );
static void Delete( AstObject * );
static void Dump( AstObject *, AstChannel * );
static int MapList( AstMapping *, int, int, int *, AstMapping ***, int ** );

/* Member functions. */
/* ================= */
static AstMapping *CombineMaps( AstMapping *mapping1, int invert1,
                                AstMapping *mapping2, int invert2,
                                int series ) {
/*
*  Name:
*     CombineMaps

*  Purpose:
*     Combine two Mappings with specified Invert flags into a CmpMap.

*  Type:
*     Private function.

*  Synopsis:
*     #include "cmpmap.h"
*     AstMapping *CombineMaps( AstMapping *mapping1, int invert1,
*                              AstMapping *mapping2, int invert2,
*                              int series )

*  Class Membership:
*     CmpMap member function.

*  Description:
*     This function combines two Mappings into a CmpMap (compound
*     Mapping) as if their Invert flags were set to specified values
*     when the CmpMap is created. However, the individual Mappings are
*     returned with their Invert flag values unchanged from their
*     original state.

*  Parameters:
*     mapping1
*        Pointer to the first Mapping.
*     invert1
*        The (boolean) Invert flag value required for the first Mapping.
*     mapping2
*        Pointer to the second Mapping.
*     invert2
*        The (boolean) Invert flag value required for the second Mapping.
*     series
*        Whether the Mappings are to be combined in series (as opposed to
*        in parallel).

*  Returned Value:
*     A pointer to the resulting compound Mapping (a CmpMap).

*  Notes:
*     - This function is a wrap-up for the astCmpMap constructor and
*     temporarily assigns the required Invert flag values while
*     creating the required CmpMap. However, it also takes account of
*     the possibility that the two Mapping pointers supplied may point
*     at the same Mapping.
*     - A null Object pointer (AST__NULL) will be returned if this
*     function is invoked with the AST error status set, or if it
*     should fail for any reason.
*/

/* Local Variables: */
   AstMapping *map1;             /* First temporary Mapping pointer */
   AstMapping *map2;             /* Second temporary Mapping pointer */
   AstMapping *result;           /* Pointer to result Mapping */
   int copy;                     /* Copy needed? */
   int inv1;                     /* First original Invert flag value */
   int inv2;                     /* Second original Invert flag value */
   int set1;                     /* First Invert flag originally set? */
   int set2;                     /* Second Invert flag originally set? */

/* Initialise */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Limit incoming values to 0 or 1. */
   invert1 = ( invert1 != 0 );
   invert2 = ( invert2 != 0 );

/* Obtain the Invert flag values for each Mapping. */
   inv1 = astGetInvert( mapping1 );
   inv2 = astGetInvert( mapping2 );

/* Also determine if these values are explicitly set. */
   set1 = astTestInvert( mapping1 );
   set2 = astTestInvert( mapping2 );

/* If both Mappings are actually the same but we need different Invert
   flag values to be set, then this can only be achieved by making a
   copy. Note if this is necessary. */
   copy = ( ( mapping1 == mapping2 ) && ( invert1 != invert2 ) );

/* Clone the first Mapping pointer. Do likewise for the second but
   make a copy instead if necessary. */
   map1 = astClone( mapping1 );
   map2 = copy ? astCopy( mapping2 ) : astClone( mapping2 );

/* If the Invert value for the first Mapping needs changing, make the
   change. */
   if ( invert1 != inv1 ) {
      if ( invert1 ) {
         astSetInvert( map1, 1 );
      } else {
         astClearInvert( map1 );
      }
   }

/* Similarly, change the Invert flag for the second Mapping if
   necessary. */
   if ( invert2 != inv2 ) {
      if ( invert2 ) {
         astSetInvert( map2, 1 );
      } else {
         astClearInvert( map2 );
      }
   }

/* Combine the two Mappings into a CmpMap. */
   result = (AstMapping *) astCmpMap( map1, map2, series, "" );
   
/* If the first Mapping's Invert value was changed, restore it to its
   original state. */
   if ( invert1 != inv1 ) {
      if ( set1 ) {
         astSetInvert( map1, inv1 );
      } else {
         astClearInvert( map1 );
      }
   }

/* Similarly, restore the second Mapping's Invert value if
   necessary. This step is not needed, however, if a copy was made. */
   if ( ( invert2 != inv2 ) && !copy ) {
      if ( set2 ) {
         astSetInvert( map2, inv2 );
      } else {
         astClearInvert( map2 );
      }
   }

/* Annul the temporary Mapping pointers. */
   map1 = astAnnul( map1 );
   map2 = astAnnul( map2 );

/* If an error occurred, then annul the result pointer. */
   if ( !astOK ) result = astAnnul( result );

/* Return the result. */
   return result;
}

static void Decompose( AstMapping *this_mapping, AstMapping **map1, 
                       AstMapping **map2, int *series, int *invert1, 
                       int *invert2 ) {
/*
*
*  Name:
*     Decompose

*  Purpose:
*     Decompose a Mapping into two component Mappings.

*  Type:
*     Private function.

*  Synopsis:
*     #include "mapping.h"
*     void Decompose( AstMapping *this, AstMapping **map1, 
*                     AstMapping **map2, int *series,
*                     int *invert1, int *invert2 )

*  Class Membership:
*     CmpMap member function (over-rides the protected astDecompose
*     method inherited from the Mapping class).

*  Description:
*     This function returns pointers to two Mappings which, when applied
*     either in series or parallel, are equivalent to the supplied Mapping.
*
*     Since the Frame class inherits from the Mapping class, Frames can
*     be considered as special types of Mappings and so this method can
*     be used to decompose either CmpMaps or CmpFrames.

*  Parameters:
*     this
*        Pointer to the Mapping.
*     map1
*        Address of a location to receive a pointer to first component
*        Mapping. 
*     map2
*        Address of a location to receive a pointer to second component
*        Mapping. 
*     series
*        Address of a location to receive a value indicating if the
*        component Mappings are applied in series or parallel. A non-zero
*        value means that the supplied Mapping is equivalent to applying map1 
*        followed by map2 in series. A zero value means that the supplied
*        Mapping is equivalent to applying map1 to the lower numbered axes
*        and map2 to the higher numbered axes, in parallel.
*     invert1
*        The value of the Invert attribute to be used with map1. 
*     invert2
*        The value of the Invert attribute to be used with map2. 

*  Notes:
*     - Any changes made to the component Mappings using the returned
*     pointers will be reflected in the supplied Mapping.

*-
*/


/* Local Variables: */
   AstCmpMap *this;              /* Pointer to CmpMap structure */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the CmpMap structure. */
   this = (AstCmpMap *) this_mapping;

/* First deal with series mappings. */
   if( this->series ) {
      if( series ) *series = 1;

/* If the CmpMap has been inverted, return the Mappings in reverse
   order with inverted Invert falgs. */
      if( astGetInvert( this ) ) {
         if( map1 ) *map1 = astClone( this->map2 );
         if( map2 ) *map2 = astClone( this->map1 );
         if( invert1 ) *invert1 = this->invert2 ? 0 : 1;
         if( invert2 ) *invert2 = this->invert1 ? 0 : 1;

/* If the CmpMap has not been inverted, return the Mappings in their
   original order with their original Invert flags. */
      } else {
         if( map1 ) *map1 = astClone( this->map1 );
         if( map2 ) *map2 = astClone( this->map2 );
         if( invert1 ) *invert1 = this->invert1;
         if( invert2 ) *invert2 = this->invert2;
      }

/* Now deal with parallel mappings. */
   } else {
      if( series ) *series = 0;

/* The mappings are returned in their original order whether or not the
   CmpMap has been inverted. */
      if( map1 ) *map1 = astClone( this->map1 );
      if( map2 ) *map2 = astClone( this->map2 );

/* If the CmpMap has been inverted, return inverted Invert flags. */
      if( astGetInvert( this ) ) {
         if( invert1 ) *invert1 = this->invert1 ? 0 : 1;
         if( invert2 ) *invert2 = this->invert2 ? 0 : 1;

/* If the CmpMap has not been inverted, return the original Invert flags. */
      } else {
         if( invert1 ) *invert1 = this->invert1;
         if( invert2 ) *invert2 = this->invert2;
      }
      
   }
}

void astInitCmpMapVtab_(  AstCmpMapVtab *vtab, const char *name ) {
/*
*+
*  Name:
*     astInitCmpMapVtab

*  Purpose:
*     Initialise a virtual function table for a CmpMap.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "cmpmap.h"
*     void astInitCmpMapVtab( AstCmpMapVtab *vtab, const char *name )

*  Class Membership:
*     CmpMap vtab initialiser.

*  Description:
*     This function initialises the component of a virtual function
*     table which is used by the CmpMap class.

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
   AstMappingVtab *mapping;      /* Pointer to Mapping component of Vtab */

/* Check the local error status. */
   if ( !astOK ) return;

/* Initialize the component of the virtual function table used by the
   parent class. */
   astInitMappingVtab( (AstMappingVtab *) vtab, name );

/* Store a unique "magic" value in the virtual function table. This
   will be used (by astIsACmpMap) to determine if an object belongs to
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
   mapping = (AstMappingVtab *) vtab;

   parent_maplist = mapping->MapList;
   mapping->MapList = MapList;
   parent_transform = mapping->Transform;
   mapping->Transform = Transform;

/* Store replacement pointers for methods which will be over-ridden by
   new member functions implemented here. */
   mapping->Decompose = Decompose;
   mapping->MapMerge = MapMerge;
   mapping->Simplify = Simplify;
   mapping->Rate = Rate;

/* Declare the copy constructor, destructor and class dump function. */
   astSetCopy( vtab, Copy );
   astSetDelete( vtab, Delete );
   astSetDump( vtab, Dump, "CmpMap", "Compound Mapping" );
}

static int MapList( AstMapping *this_mapping, int series, int invert,
                     int *nmap, AstMapping ***map_list, int **invert_list ) {
/*
*  Name:
*     MapList

*  Purpose:
*     Decompose a CmpMap into a sequence of simpler Mappings.

*  Type:
*     Private function.

*  Synopsis:
*     #include "mapping.h"
*     int MapList( AstMapping *this, int series, int invert, int *nmap,
*                  AstMapping ***map_list, int **invert_list )

*  Class Membership:
*     CmpMap member function (over-rides the protected astMapList
*     method inherited from the Maping class).

*  Description:
*     This function decomposes a CmpMap into a sequence of simpler
*     Mappings which may be applied in sequence to achieve the same
*     effect. The CmpMap is decomposed as far as possible, but it is
*     not guaranteed that this will necessarily yield any more than
*     one Mapping, which may actually be the original CmpMap supplied.
*
*     This function is provided to support both the simplification of
*     CmpMaps, and the analysis of CmpMap structure so that particular
*     forms can be recognised.

*  Parameters:
*     this
*        Pointer to the CmpMap to be decomposed (the CmpMap is not
*        actually modified by this function).
*     series
*        If this value is non-zero, an attempt will be made to
*        decompose the CmpMap into a sequence of equivalent Mappings
*        which can be applied in series (i.e. one after the other). If
*        it is zero, the decomposition will instead yield Mappings
*        which can be applied in parallel (i.e. on successive sub-sets
*        of the input/output coordinates).
*     invert
*        The value to which the CmpMap's Invert attribute is to be
*        (notionally) set before performing the
*        decomposition. Normally, the value supplied here will be the
*        actual Invert value obtained from the CmpMap (e.g. using
*        astGetInvert).  Sometimes, however, when a CmpMap is
*        encapsulated within another structure, that structure may
*        retain an Invert value (in order to prevent external
*        interference) which should be used instead.
*
*        Note that the actual Invert value of the CmpMap supplied is
*        not used (or modified) by this function.
*     nmap
*        The address of an int which holds a count of the number of
*        individual Mappings in the decomposition. On entry, this
*        should count the number of Mappings already in the
*        "*map_list" array (below). On exit, it is updated to include
*        any new Mappings appended by this function.
*     map_list
*        Address of a pointer to an array of Mapping pointers. On
*        entry, this array pointer should either be NULL (if no
*        Mappings have yet been obtained) or should point at a
*        dynamically allocated array containing Mapping pointers
*        ("*nmap" in number) which have been obtained from a previous
*        invocation of this function.
*
*        On exit, the dynamic array will be enlarged to contain any
*        new Mapping pointers that result from the decomposition
*        requested. These pointers will be appended to any previously
*        present, and the array pointer will be updated as necessary
*        to refer to the enlarged array (any space released by the
*        original array will be freed automatically).
*
*        The new Mapping pointers returned will identify a sequence of
*        Mappings which, when applied in order, will perform a forward
*        transformation equivalent to that of the original CmpMap
*        (after its Invert flag has first been set to the value
*        requested above). The Mappings should be applied in series or
*        in parallel according to the type of decomposition requested.
*
*        All the Mapping pointers returned by this function should be
*        annulled by the caller, using astAnnul, when no longer
*        required. The dynamic array holding these pointers should
*        also be freed, using astFree.
*     invert_list
*        Address of a pointer to an array of int. On entry, this array
*        pointer should either be NULL (if no Mappings have yet been
*        obtained) or should point at a dynamically allocated array
*        containing Invert attribute values ("*nmap" in number) which
*        have been obtained from a previous invocation of this
*        function.
*
*        On exit, the dynamic array will be enlarged to contain any
*        new Invert attribute values that result from the
*        decomposition requested. These values will be appended to any
*        previously present, and the array pointer will be updated as
*        necessary to refer to the enlarged array (any space released
*        by the original array will be freed automatically).
*
*        The new Invert values returned identify the values which must
*        be assigned to the Invert attributes of the corresponding
*        Mappings (whose pointers are in the "*map_list" array) before
*        they are applied. Note that these values may differ from the
*        actual Invert attribute values of these Mappings, which are
*        not relevant.
*
*        The dynamic array holding these values should be freed by the
*        caller, using astFree, when no longer required.

*  Returned Value:
*     A non-zero value is returned if the supplied Mapping contained any
*     inverted CmpMaps.

*  Notes:
*     - It is unspecified to what extent the original CmpMap and the
*     individual (decomposed) Mappings are
*     inter-dependent. Consequently, the individual Mappings cannot be
*     modified without risking modification of the original CmpMap.
*     - If this function is invoked with the global error status set,
*     or if it should fail for any reason, then the *nmap value, the
*     list of Mapping pointers and the list of Invert values will all
*     be returned unchanged.
*/

/* Local Variables: */
   AstCmpMap *this;              /* Pointer to CmpMap structure */
   int invert1;                  /* Invert flag for first component Mapping */
   int invert2;                  /* Invert flag for second component Mapping */
   int r1;                       /* Value returned from first map list */
   int r2;                       /* Value returned from second map list */
   int result;                   /* Returned value */

/* Check the global error status. */
   if ( !astOK ) return 0;

/* Obtain a pointer to the CmpMap structure. */
   this = (AstCmpMap *) this_mapping;

/* Check if the CmpMap combines its component Mappings in the same way
   (series or parallel) as the decomposition requires. */
   if ( this->series == series ) {

/* If so, obtain the Invert attribute values to be applied to each
   component Mapping. */
      invert1 = this->invert1;
      invert2 = this->invert2;

/* If the CmpMap itself is inverted, also invert the Invert values to be
   applied to its components. */
      if ( invert ) {
         invert1 = !invert1;
         invert2 = !invert2;
      }

/* If the component Mappings are applied in series, then concatenate
   the Mapping lists obtained from each of them. Do this in reverse
   order if the CmpMap is inverted, since the second Mapping would be
   applied first in this case. */
      if ( series ) {
         if ( !invert ) {
            r1 = astMapList( this->map1, series, invert1,
                             nmap, map_list, invert_list );
            r2 = astMapList( this->map2, series, invert2,
                             nmap, map_list, invert_list );
         } else {
            r1 = astMapList( this->map2, series, invert2,
                             nmap, map_list, invert_list );
            r2 = astMapList( this->map1, series, invert1,
                             nmap, map_list, invert_list );
         }

/* If the component Mappings are applied in parallel, then concatenate
   the Mapping lists obtained from each of them. In this case,
   inverting the CmpMap has no effect on the order in which they are
   applied. */
      } else {
         r1 = astMapList( this->map1, series, invert1,
                          nmap, map_list, invert_list );
         r2 = astMapList( this->map2, series, invert2,
                          nmap, map_list, invert_list );
      }

/* Did we find any inverted CmpMaps? */
      result = invert || r1 || r2;

/* If the CmpMap does not combine its components in the way required
   by the decomposition (series or parallel), then we cannot decompose
   it. In this case it must be appended to the Mapping list as a
   single entity. We can use the parent class method to do this. */
   } else {
      result = ( *parent_maplist )( this_mapping, series, invert, nmap,
                                    map_list, invert_list );
   }

   return result;
}

static int MapMerge( AstMapping *this, int where, int series, int *nmap,
                     AstMapping ***map_list, int **invert_list ) {
/*
*  Name:
*     MapMerge

*  Purpose:
*     Simplify a sequence of Mappings containing a CmpMap.

*  Type:
*     Private function.

*  Synopsis:
*     #include "mapping.h"
*     int MapMerge( AstMapping *this, int where, int series, int *nmap,
*                   AstMapping ***map_list, int **invert_list )

*  Class Membership:
*     CmpMap method (over-rides the protected astMapMerge method
*     inherited from the Mapping class).

*  Description:
*     This function attempts to simplify a sequence of Mappings by
*     merging a nominated CmpMap in the sequence with its neighbours,
*     so as to shorten the sequence if possible.
*
*     In many cases, simplification will not be possible and the
*     function will return -1 to indicate this, without further
*     action.
*
*     In most cases of interest, however, this function will either
*     attempt to replace the nominated CmpMap with one which it
*     considers simpler, or to merge it with the Mappings which
*     immediately precede it or follow it in the sequence (both will
*     normally be considered). This is sufficient to ensure the
*     eventual simplification of most Mapping sequences by repeated
*     application of this function.
*
*     In some cases, the function may attempt more elaborate
*     simplification, involving any number of other Mappings in the
*     sequence. It is not restricted in the type or scope of
*     simplification it may perform, but will normally only attempt
*     elaborate simplification in cases where a more straightforward
*     approach is not adequate.

*  Parameters:
*     this
*        Pointer to the nominated CmpMap which is to be merged with
*        its neighbours. This should be a cloned copy of the CmpMap
*        pointer contained in the array element "(*map_list)[where]"
*        (see below). This pointer will not be annulled, and the
*        CmpMap it identifies will not be modified by this function.
*     where
*        Index in the "*map_list" array (below) at which the pointer
*        to the nominated CmpMap resides.
*     series
*        A non-zero value indicates that the sequence of Mappings to
*        be simplified will be applied in series (i.e. one after the
*        other), whereas a zero value indicates that they will be
*        applied in parallel (i.e. on successive sub-sets of the
*        input/output coordinates).
*     nmap
*        Address of an int which counts the number of Mappings in the
*        sequence. On entry this should be set to the initial number
*        of Mappings. On exit it will be updated to record the number
*        of Mappings remaining after simplification.
*     map_list
*        Address of a pointer to a dynamically allocated array of
*        Mapping pointers (produced, for example, by the astMapList
*        method) which identifies the sequence of Mappings. On entry,
*        the initial sequence of Mappings to be simplified should be
*        supplied.
*
*        On exit, the contents of this array will be modified to
*        reflect any simplification carried out. Any form of
*        simplification may be performed. This may involve any of: (a)
*        removing Mappings by annulling any of the pointers supplied,
*        (b) replacing them with pointers to new Mappings, (c)
*        inserting additional Mappings and (d) changing their order.
*
*        The intention is to reduce the number of Mappings in the
*        sequence, if possible, and any reduction will be reflected in
*        the value of "*nmap" returned. However, simplifications which
*        do not reduce the length of the sequence (but improve its
*        execution time, for example) may also be performed, and the
*        sequence might conceivably increase in length (but normally
*        only in order to split up a Mapping into pieces that can be
*        more easily merged with their neighbours on subsequent
*        invocations of this function).
*
*        If Mappings are removed from the sequence, any gaps that
*        remain will be closed up, by moving subsequent Mapping
*        pointers along in the array, so that vacated elements occur
*        at the end. If the sequence increases in length, the array
*        will be extended (and its pointer updated) if necessary to
*        accommodate any new elements.
*
*        Note that any (or all) of the Mapping pointers supplied in
*        this array may be annulled by this function, but the Mappings
*        to which they refer are not modified in any way (although
*        they may, of course, be deleted if the annulled pointer is
*        the final one).
*     invert_list
*        Address of a pointer to a dynamically allocated array which,
*        on entry, should contain values to be assigned to the Invert
*        attributes of the Mappings identified in the "*map_list"
*        array before they are applied (this array might have been
*        produced, for example, by the astMapList method). These
*        values will be used by this function instead of the actual
*        Invert attributes of the Mappings supplied, which are
*        ignored.
*
*        On exit, the contents of this array will be updated to
*        correspond with the possibly modified contents of the
*        "*map_list" array.  If the Mapping sequence increases in
*        length, the "*invert_list" array will be extended (and its
*        pointer updated) if necessary to accommodate any new
*        elements.

*  Returned Value:
*     If simplification was possible, the function returns the index
*     in the "map_list" array of the first element which was
*     modified. Otherwise, it returns -1 (and makes no changes to the
*     arrays supplied).

*  Notes:
*     - A value of -1 will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*/

/* Local Variables: */
   AstCmpMap *cmpmap1;           /* Pointer to first CmpMap */
   AstCmpMap *cmpmap2;           /* Pointer to second CmpMap */
   AstMapping *map;              /* Pointer to nominated CmpMap */
   AstMapping *new1;             /* Pointer to new CmpMap */
   AstMapping *new2;             /* Pointer to new CmpMap */
   AstMapping *new;              /* Pointer to replacement Mapping */
   AstMapping *simp1;            /* Pointer to simplified Mapping */
   AstMapping *simp2;            /* Pointer to simplified Mapping */
   AstPermMap *permmap1;         /* Pointer to first PermMap */
   AstPermMap *new_pm;           /* Pointer to new PermMap */
   AstCmpMap *new_cm;            /* Pointer to new CmpMap */
   const char *class;            /* Pointer to Mapping class string */
   int *inperm;                  /* Pointer to copy of PermMap inperm array */
   int *outperm;                 /* Pointer to copy of PermMap outperm array */
   int canswap;                  /* Can nominated Mapping swap with lower neighbour? */
   int i;                        /* Coordinate index */
   int imap1;                    /* Index of first Mapping */
   int imap2;                    /* Index of second Mapping */
   int imap;                     /* Loop counter for Mappings */
   int invert1;                  /* Invert flag for first CmpMap */
   int invert1a;                 /* Invert flag for sub-Mapping */
   int invert1b;                 /* Invert flag for sub-Mapping */
   int invert2;                  /* Invert flag for second CmpMap */
   int invert2a;                 /* Invert flag for sub-Mapping */
   int invert2b;                 /* Invert flag for sub-Mapping */
   int invert;                   /* Invert attribute value */
   int j;                        /* Coordinate index */
   int new_invert;               /* New Invert attribute value */
   int nin2a;                    /* No. input coordinates for sub-Mapping */
   int nin2b;                    /* No. input coordinates for sub-Mapping */
   int nout1a;                   /* No. output coordinates for sub-Mapping */
   int nout1b;                   /* No. output coordinates for sub-Mapping */
   int result;                   /* Result value to return */
   int set;                      /* Invert attribute set? */
   int simpler;                  /* Simplification possible? */

   int npout;                    /* No. of outputs for original PermMap */
   int npin;                     /* No. of inputs for original PermMap */
   int nout2a;                   /* No. of outputs for 1st component Mapping */
   int nout2b;                   /* No. of outputs for 2nd component Mapping */
   int aconstants;               /* Are all 1st component outputs constant? */
   int bconstants;               /* Are all 2nd component outputs constant? */
   double *p;                    /* Pointer to PermMap input position */
   double *q;                    /* Pointer to PermMap output position */
   double *qa;                   /* Pointer to 1st component output position */
   double *qb;                   /* Pointer to 2nd component output position */
   int npin_new;                 /* No. of inputs for new PermMap */
   int npout_new;                /* No. of outputs for new PermMap */
   int *inperm_new;              /* Pointer to new PermMap inperm array */
   int *outperm_new;             /* Pointer to new PermMap outperm array */
   double *const_new;            /* Pointer to new PermMap constants array */

/* Initialise.*/
   result = -1;

/* Check the inherited status. */
   if ( !astOK ) return result;

/* Simplify the CmpMap on its own. */
/* =============================== */
/* Obtain a pointer to the nominated Mapping (which is a CmpMap). */
   map = ( *map_list )[ where ];

/* Determine if the Mapping's Invert attribute is set and obtain its
   value. */
   set = astTestInvert( map );
   invert = astGetInvert( map );

/* If necessary, change the Invert attribute to the value we want. We
   do this so that simplification (below) has a chance to absorb a
   non-zero Invert value into the implementation of the simplified
   Mapping (the preference being to have an Invert value of zero after
   simplification, if possible). */
   if ( invert != ( *invert_list )[ where ] ) {
      astSetInvert( map, ( *invert_list )[ where ] );
   }

/* Simplify the Mapping and obtain the new Invert value. */
   new = astSimplify( map );
   new_invert = astGetInvert( new );

/* If necessary, restore the original Mapping's Invert attribute to
   its initial state. */
   if ( invert != ( *invert_list )[ where ] ) {
      if ( set ) {
         astSetInvert( map, invert );
      } else {
         astClearInvert( map );
      }
   }

/* We must now determine if simplification has occurred. Since this is
   internal code, we can compare the two Mapping pointers directly to
   see whether "astSimplify" just cloned the pointer we gave it. If it
   did, then simplification was probably not possible, but check to
   see if the Invert attribute has changed to be sure. */
   if ( astOK ) {
      simpler = ( new != map ) || ( new_invert != ( *invert_list )[ where ] );

/* If simplification was successful, annul the original pointer in the
   Mapping list and replace it with the new one, together with its
   invert flag. */
      if ( simpler ) {
         (void) astAnnul( ( *map_list )[ where ] );
         ( *map_list )[ where ] = new;
         ( *invert_list )[ where ] = new_invert;

/* Return the result. */
         result = where;

/* Otherwise, annul the new Mapping pointer. */
      } else {
         new = astAnnul( new );

/* Merge adjacent CmpMaps. */
/* ======================= */
/* If the CmpMap would not simplify on its own, we now look for a
   neighbouring CmpMap with which it might merge. We use the previous
   Mapping, if suitable, since this will normally also have been fully
   simplified on its own. Check if a previous Mapping exists. */
         if ( astOK && ( where > 0 ) ) {

/* Obtain the indices of the two potential Mappings to be merged. */
            imap1 = where - 1;
            imap2 = where;

/* Obtain the Class string of the first (previous) Mapping and
   determine if it is a CmpMap. */
            class = astGetClass( ( *map_list )[ imap1 ] );
            if ( astOK && !strcmp( class, "CmpMap" ) ) {

/* If suitable, obtain pointers to the two CmpMaps. */
               cmpmap1 = (AstCmpMap *) ( *map_list )[ imap1 ];
               cmpmap2 = (AstCmpMap *) ( *map_list )[ imap2 ];

/* Obtain the associated invert flag values. */
               invert1 = ( *invert_list )[ imap1 ];
               invert2 = ( *invert_list )[ imap2 ];

/* Extract the invert flags associated with each CmpMap sub-Mapping
   and combine these with the flag values obtained above so as to give
   the invert flag to be used with each individual sub-Mapping. */
               invert1a = cmpmap1->invert1;
               invert1b = cmpmap1->invert2;
               if ( invert1 ) {
                  invert1a = !invert1a;
                  invert1b = !invert1b;
               }
               invert2a = cmpmap2->invert1;
               invert2b = cmpmap2->invert2;
               if ( invert2 ) {
                  invert2a = !invert2a;
                  invert2b = !invert2b;
               }

/* Series CmpMaps in parallel. */
/* =========================== */
/* Now check if the CmpMaps can be merged. This may be possible if we
   are examining a list of Mappings combined in parallel and the two
   adjacent CmpMaps both combine their sub-Mappings in series. */
               if ( !series && cmpmap1->series && cmpmap2->series ) {

/* Form two new parallel CmpMaps with the sub-Mappings re-arranged so
   that when combined in series these new CmpMaps are equivalent to
   the original ones. In doing this, we must take account of the
   invert flags which apply to each sub-Mapping and also of the fact
   that the order in which the sub-Mappings are applied depends on the
   invert flags of the original CmpMaps. */
                  new1 = CombineMaps( invert1 ? cmpmap1->map2 : cmpmap1->map1,
                                      invert1 ? invert1b      : invert1a,
                                      invert2 ? cmpmap2->map2 : cmpmap2->map1,
                                      invert2 ? invert2b      : invert2a, 0 );
                  new2 = CombineMaps( invert1 ? cmpmap1->map1 : cmpmap1->map2,
                                      invert1 ? invert1a      : invert1b,
                                      invert2 ? cmpmap2->map1 : cmpmap2->map2,
                                      invert2 ? invert2a      : invert2b, 0 );

/* Having converted the parallel combination of series CmpMaps into a
   pair of equivalent parallel CmpMaps that can be combined in series,
   try and simplify each of these new CmpMaps. */
                  simp1 = astSimplify( new1 );
                  simp2 = astSimplify( new2 );

/* Test if either could be simplified by checking if its pointer value
   has changed. Also check if the Invert attribute has changed (not
   strictly necessary, but a useful safety feature in case of any
   rogue code which just changes this attribute instead of issuing a
   new pointer). */
                  simpler = ( simp1 != new1 ) || ( simp2 != new2 ) ||
                            astGetInvert( simp1 ) || astGetInvert( simp2 );

/* If either CmpMap was simplified, then combine the resulting
   Mappings in series to give the replacement CmpMap. */
                  if ( simpler ) new =
                               (AstMapping *) astCmpMap( simp1, simp2, 1, "" );

/* Annul the temporary Mapping pointers. */
                  new1 = astAnnul( new1 );
                  new2 = astAnnul( new2 );
                  simp1 = astAnnul( simp1 );
                  simp2 = astAnnul( simp2 );

/* Parallel CmpMaps in series. */
/* =========================== */
/* A pair of adjacent CmpMaps can also potentially be merged if we are
   examining a list of Mappings combined in series and the two
   adjacent CmpMaps both combine their sub-Mappings in parallel. */
               } else if ( series && !cmpmap1->series && !cmpmap2->series ) {

/* In this case, we must check that the number of input and output
   coordinates associated with the sub-Mappings are
   compatible. Determine the effective number of output coordinates
   produced by each sub-Mapping of the first CmpMap. Take account of
   the invert flags to be applied and the current setting of the
   Invert attributes. */
                  if ( astGetInvert( cmpmap1->map1 ) ) {
                     nout1a = invert1a ? astGetNout( cmpmap1->map1 ) :
                                         astGetNin( cmpmap1->map1 );
                  } else {
                     nout1a = invert1a ? astGetNin( cmpmap1->map1 ) :
                                         astGetNout( cmpmap1->map1 );
                  }
                  if ( astGetInvert( cmpmap1->map2 ) ) {
                     nout1b = invert1b ? astGetNout( cmpmap1->map2 ) :
                                         astGetNin( cmpmap1->map2 );
                  } else {
                     nout1b = invert1b ? astGetNin( cmpmap1->map2 ) :
                                         astGetNout( cmpmap1->map2 );
                  }

/* Repeat this to obtain the effective number of input coordinates for
   each sub-Mapping of the second CmpMap. */
                  if ( astGetInvert( cmpmap2->map1 ) ) {
                     nin2a = invert2a ? astGetNin( cmpmap2->map1 ) :
                                        astGetNout( cmpmap2->map1 );
                  } else {
                     nin2a = invert2a ? astGetNout( cmpmap2->map1 ) :
                                        astGetNin( cmpmap2->map1 );
                  }
                  if ( astGetInvert( cmpmap2->map2 ) ) {
                     nin2b = invert2b ? astGetNin( cmpmap2->map2 ) :
                                        astGetNout( cmpmap2->map2 );
                  } else {
                     nin2b = invert2b ? astGetNout( cmpmap2->map2 ) :
                                        astGetNin( cmpmap2->map2 );
                  }

/* Check if the numbers of coordinates are compatible. */
                  if ( astOK && ( nout1a == nin2a ) && ( nout1b == nin2b ) ) {

/* If so, combine the sub-Mappings into a pair of series CmpMaps
   which, when combined in parallel, are equivalent to the original
   ones. */
                     new1 = CombineMaps( cmpmap1->map1, invert1a,
                                         cmpmap2->map1, invert2a, 1 );
                     new2 = CombineMaps( cmpmap1->map2, invert1b,
                                         cmpmap2->map2, invert2b, 1 );

/* Having converted the series combination of parallel CmpMaps into a
   pair of equivalent series CmpMaps that can be combined in parallel,
   try and simplify each of these new CmpMaps. */
                     simp1 = astSimplify( new1 );
                     simp2 = astSimplify( new2 );

/* Test if either could be simplified by checking if its pointer value
   has changed. Also check if the Invert attribute has changed. */
                     simpler = ( simp1 != new1 ) || ( simp2 != new2 ) ||
                               astGetInvert( simp1 ) || astGetInvert( simp2 );

/* If either CmpMap was simplified, then combine the resulting
   Mappings in parallel to give the replacement CmpMap. */
                     if ( simpler ) new =
                               (AstMapping *) astCmpMap( simp1, simp2, 0, "" );

/* Annul the temporary Mapping pointers. */
                     new1 = astAnnul( new1 );
                     new2 = astAnnul( new2 );
                     simp1 = astAnnul( simp1 );
                     simp2 = astAnnul( simp2 );
                  }
               }
            }

/* Update Mapping list. */
/* ==================== */
/* If adjacent CmpMaps can be combined, then annul the original pointers. */
            if ( astOK && simpler ) {
               ( *map_list )[ imap1 ] = astAnnul( ( *map_list )[ imap1 ] );
               ( *map_list )[ imap2 ] = astAnnul( ( *map_list )[ imap2 ] );

/* Insert the pointer to the replacement CmpMap and initialise its
   invert flag. */
               ( *map_list )[ imap1 ] = new;
               ( *invert_list )[ imap1 ] = 0;

/* Loop to close the resulting gap by moving subsequent elements down
   in the arrays. */
               for ( imap = imap2 + 1; imap < *nmap; imap++ ) {
                  ( *map_list )[ imap - 1 ] = ( *map_list )[ imap ];
                  ( *invert_list )[ imap - 1 ] = ( *invert_list )[ imap ];
               }
                        
/* Clear the vacated elements at the end. */
               ( *map_list )[ *nmap - 1 ] = NULL;
               ( *invert_list )[ *nmap - 1 ] = 0;

/* Decrement the Mapping count and return the index of the first
   modified element. */
               ( *nmap )--;
               result = imap1;
            }
         }
      }
   }

/* If we are merging the Mappings in series, and if the nominated CmpMap 
   is a parallel CmpMap, and if the lower neighbour is a PermMap, it may 
   be possible to swap the PermMap and the CmpMap. This may allow one of 
   the two swapped Mappings to merge with its new neighbour. 
   ==================================================================== */

/* Only do this if no simplification occurred above, and if the Mappings
   are being merged in series, and if the nominated Mapping is not the
   first in the list. */
   if( result == -1 && where > 0 ){

/* Obtain the indices of the two potential Mappings to be swapped. */
      imap1 = where - 1;
      imap2 = where;

/* Obtain a pointer to the CmpMap. */
      cmpmap2 = (AstCmpMap *) ( *map_list )[ imap2 ];

/* Obtain the Class string of the first (previous) Mapping and
   determine if it is a PermMap. Also check that the nominated Mapping is 
   a parallel CmpMap. */
      class = astGetClass( ( *map_list )[ imap1 ] );
      if ( astOK && !strcmp( class, "PermMap" ) && !cmpmap2->series) {

/* Indicate we have no new Mapping to store. */
         new = NULL;

/* If suitable, obtain a pointer to the PermMap. */
         permmap1 = (AstPermMap *) ( *map_list )[ imap1 ];

/* Obtain the current values of the Invert attribute in the Mappings. */
         invert1 = astGetInvert( permmap1 );
         invert2 = astGetInvert( cmpmap2 );

/* Temporarily set the Invert attributes of both Mappings to the values 
   supplied in the "invert_list" parameter. */
         astSetInvert( permmap1, ( *invert_list )[ imap1 ] );     
         astSetInvert( cmpmap2, ( *invert_list )[ imap2 ] );     

/* Get the number of inputs and outputs for the PermMap.*/
         npout = astGetNout( permmap1 );
         npin = astGetNin( permmap1 );

/* Get the number of inputs and outputs for the two components of the 
   nominated parallel CmpMap. */
         nin2a = astGetNin( cmpmap2->map1 );
         nin2b = astGetNin( cmpmap2->map2 );
         nout2a = astGetNout( cmpmap2->map1 );
         nout2b = astGetNout( cmpmap2->map2 );

/* Get the input and output axis permutation arrays from the PermMap */
         inperm =astGetInPerm( permmap1 );
         outperm =astGetOutPerm( permmap1 );

/* In order to swap the Mappings, the PermMap outputs which feed the
   inputs of the first component of the parallel CmpMap must be copied
   from a contiguous block at the end of the list of PermMap inputs, or
   must all be assigned constant values. Likewise, the PermMap outputs which 
   feed the inputs of the second component of the parallel CmpMap must be 
   copied from a contiguous block at the beggining of the list of PermMap 
   inputs or must be assigned constant values. Also, there must be a
   one-to-one correspondance between inputs and outputs in the PermMap.
   Check that the first block of nin2a PermMap outputs are copied from
   the last block of nin2a PermMap inputs (and vica-versa) or are constant. */
         canswap = 1;
         aconstants = ( outperm[ 0 ] < 0 );

         for( i = 0, j = npin - nin2a; i < nin2a; i++, j++ ) {
            if( aconstants ) {
               if( outperm[ i ] >= 0 ) {
                  canswap = 0;
                  break;
               }

            } else if( outperm[ i ] != j || inperm[ j ] != i ) {
               canswap = 0;
               break;
            }
         }

/* Check that the first block of nin2b PermMap inputs are copied from
   the last block of nin2b PermMap outputs, and vica-versa. */
         bconstants = ( outperm[ nin2a ] < 0 );
         for( i = 0, j = npout - nin2b; i < nin2b; i++, j++ ) {
            if( bconstants ) {
               if( outperm[ j ] >= 0 ) {
                  canswap = 0;
                  break;
               }
            } else if( inperm[ i ] != j || outperm[ j ] != i ) {
               canswap = 0;
               break;
            }
         }

/* If the Mappings can be swapped.. */
         new_pm = NULL;
         new_cm = NULL;
         qa = NULL;
         qb = NULL;
         if( canswap ) {

/* Temporarily set the Invert attributes of the component Mappings to the 
   values they had when the CmpMap was created. */
            invert2a = astGetInvert( cmpmap2->map1 );
            invert2b = astGetInvert( cmpmap2->map2 );
            astSetInvert( cmpmap2->map1, cmpmap2->invert1 );
            astSetInvert( cmpmap2->map2, cmpmap2->invert2 );

/* If any PermMap outputs are constant, we will need the results of
   transforming these constants using the CmpMap which follows. */
            if( aconstants || bconstants ) {

/* Transform a set of bad inputs using the PermMap. This will assign the
   PermMap constant to any fixed outputs. */
               p = astMalloc( sizeof( double )*(size_t) npin );
               q = astMalloc( sizeof( double )*(size_t) npout );
               qa = astMalloc( sizeof( double )*(size_t) nout2a );
               qb = astMalloc( sizeof( double )*(size_t) nout2b );
               if( astOK ) {
                  for( i = 0; i < npin; i++ ) p[ i ] = AST__BAD;
                  astTranN( permmap1, 1, npin, 1, p, 1, npout, 1, q );

/* Transform the PermMap outputs using the two component Mappings in the
   CmpMap. */
                  astTranN( cmpmap2->map1, 1, nin2a, 1, q, 1, nout2a, 1, qa );
                  astTranN( cmpmap2->map2, 1, nin2b, 1, q + nin2a, 1, nout2b, 1, qb );

               }
               p = astFree( p );
               q = astFree( q );
            }

/* Determine the number of inputs and outputs for the resulting PermMap
   and allocate memory for their permutation arrays. */
            npin_new = 0;
            if( !aconstants ) npin_new += nout2a;
            if( !bconstants ) npin_new += nout2b;
            npout_new = nout2a + nout2b;
            outperm_new = astMalloc( sizeof( int )*(size_t) npout_new );
            inperm_new = astMalloc( sizeof( int )*(size_t) npin_new );
            const_new = astMalloc( sizeof( double )*(size_t) npout_new );
            if( astOK ) {

/* First assign permutations for the second component Mapping, if used. */
               if( !bconstants ) {
                  for( i = 0, j = npout_new - nout2b; i < nout2b; i++,j++ ) {
                     inperm_new[ i ] = j;
                     outperm_new[ j ] = i;
                  }

/* Otherwise, store constants */
               } else {
                  for( i = 0, j = npout_new - nout2b; i < nout2b; i++,j++ ) {
                     outperm_new[ j ] = -( i + 1 );
                     const_new[ i ] = qb[ i ];
                  }
               }

/* Now assign permutations for the first component Mapping, if used. */
               if( !aconstants ) {
                  for( i = 0, j = npin_new - nout2a; i < nout2a; i++,j++ ) {
                     inperm_new[ j ] = i;
                     outperm_new[ i ] = j;
                  }

/* Otherwise, store constants */
               } else {
                  for( i = 0; i < nout2a; i++ ) {
                     outperm_new[ i ] = -( i + 1 );
                     const_new[ i ] = qa[ i ];
                  }
               }

/* Create the new PermMap */
               new_pm = astPermMap( npin_new, inperm_new, npout_new,
                                    outperm_new, const_new, "" );

/* Create the new CmpMap.*/
               if( aconstants ) {
                  new_cm = astCopy( cmpmap2->map2 );

               } else if( bconstants ) {
                  new_cm = astCopy( cmpmap2->map1 );

               } else{
                  new_cm = astCmpMap( cmpmap2->map2, cmpmap2->map1, 0, "" );
               }

            }

/* Free Memory. */
            outperm_new = astFree( outperm_new );
            inperm_new = astFree( inperm_new );
            const_new = astFree( const_new );
            if( aconstants || bconstants ) {
               qa = astFree( qa );
               qb = astFree( qb );
            }

/* Re-instate the original Invert attributes in the component Mappings. */
            astSetInvert( cmpmap2->map1, invert2a );
            astSetInvert( cmpmap2->map2, invert2b );

         }

/* Release the arrays holding the input and output permutation arrays
   copied from the PermMap. */
         inperm = astFree( inperm );
         outperm = astFree( outperm );

/* Re-instate the original values of the Invert attributes of both
   Mappings. */
         astSetInvert( permmap1, invert1 );     
         astSetInvert( cmpmap2, invert2 );     

/* If the Mappings can be swapped... */
         if( astOK && canswap ) {

/* Annul the supplied pointer to the two Mappings. */
            ( *map_list )[ imap1 ] = astAnnul( ( *map_list )[ imap1 ] );
            ( *map_list )[ imap2 ] = astAnnul( ( *map_list )[ imap2 ] );

/* Store the new PermMap pointer in the slot previously occupied by the
   nominated CmpMap pointer. Likewise, store the invert flag. */
            ( *map_list )[ imap2 ] = (AstMapping *) new_pm;
            ( *invert_list )[ imap2 ] = astGetInvert( new_pm );

/* Store the new PermMap pointer in the slot previously occupied by the
   nominated CmpMap pointer. Likewise, store the invert flag. */
            ( *map_list )[ imap1 ] = (AstMapping *) new_cm;
            ( *invert_list )[ imap1 ] = astGetInvert( new_cm );

/* Return the index of the first modified element. */
            result = imap1;

         }
      }
   }

/* If an error occurred, clear the result value. */
   if ( !astOK ) result = -1;

/* Return the result. */
   return result;
}

static double Rate( AstMapping *this, double *at, int ax1, int ax2 ){
/*
*  Name:
*     Rate

*  Purpose:
*     Calculate the rate of change of a Mapping output.

*  Type:
*     Private function.

*  Synopsis:
*     #include "cmpmap.h"
*     result = Rate( AstMapping *this, double *at, int ax1, int ax2 )

*  Class Membership:
*     CmpMap member function (overrides the astRate method inherited
*     from the Mapping class ).

*  Description:
*     This function returns the rate of change of a specified output of 
*     the supplied Mapping with respect to a specified input, at a 
*     specified input position. 

*  Parameters:
*     this
*        Pointer to the Mapping to be applied.
*     at
*        The address of an array holding the axis values at the position 
*        at which the rate of change is to be evaluated. The number of 
*        elements in this array should equal the number of inputs to the 
*        Mapping.
*     ax1
*        The index of the Mapping output for which the rate of change is to 
*        be found (output numbering starts at 0 for the first output).
*     ax2
*        The index of the Mapping input which is to be varied in order to
*        find the rate of change (input numbering starts at 0 for the first 
*        input).

*  Returned Value:
*     The rate of change of Mapping output "ax1" with respect to input 
*     "ax2", evaluated at "at", or AST__BAD if the value cannot be 
*     calculated.

*/

/* Local Variables: */
   AstMapping *c1;
   AstMapping *c2;
   AstCmpMap *map;
   double result;
   int old_inv1;
   int old_inv2;
   int nin1;
   int nin2;
   double *at2;
   double r1;
   double r2;
   int nout1;
   int i;

/* Check inherited status */
   if( !astOK ) return AST__BAD;

/* Get a pointer to the CmpMap structure. */
   map = (AstCmpMap *) this;

/* Note the current Invert flags of the two component Mappings. */
   old_inv1 = astGetInvert( map->map1 );
   old_inv2 = astGetInvert( map->map2 );

/* Temporarily reset them to the values they had when the CmpMap was 
   created. */
   astSetInvert( map->map1, map->invert1 );
   astSetInvert( map->map2, map->invert2 );

/* If the CmpMap itself has been inverted, invert the component Mappings.
   Also note the order in which the Mappings should be applied if in series. */
   if( !astGetInvert( this ) ) {
      c1 = map->map1;
      c2 = map->map2;
   } else {
      c1 = map->map2;
      c2 = map->map1;
      astInvert( c1 );
      astInvert( c2 );
   }

/* First deal with Mappings in series. */
   if( map->series ) {

/* Get the number of inputs to the two component Mappings. */
      nin1 = astGetNin( c1 );
      nin2 = astGetNin( c2 );

/* Allocate workspace to hold the result of transforming the supplied "at" 
   position using the first component. */
      at2 = astMalloc( sizeof( double )*(size_t) nin2 );

/* Transform the supplied "at" position using the first component. */
      astTranN( c1, 1, nin1, 1, at, 1, nin2, 1, at2 );

/* The required rate of change is the sum of the products of the rate of
   changes of the two component mappings, summed over all the output axes
   of the first componment. */
      result = 0.0;
      for( i = 0; i < nin2; i++ ) {

/* Find the rate of change of output "i" of the first component with
   respect to input "ax2" at the supplied "at" position. */
         r1 = astRate( c1, at, i, ax2 );

/* Find the rate of change of output "ax1" of the second component with
   respect to input "i" at the transformed "at2" position. */
         r2 = astRate( c2, at2, ax1, i );

/* If both are good, increment the ryunning total by the product of the
   two rates. Otherwise, break. */
         if( r1 != AST__BAD && r2 != AST__BAD ) {
            result += r1*r2;
         } else {
            result = AST__BAD;
            break;
         }
      }

/* Free the workspace. */
      at2 = astFree( at2 );

/* Now deal with Mappings in parallel. */
   } else {

/* Get the number of inputs and outputs for the lower component Mappings. */
      nin1 = astGetNin( map->map1 );
      nout1 = astGetNout( map->map1 );

/* If both input and output relate to the lower component Mappings, use its
   astRate method. */
      if( ax1 < nout1 && ax2 < nin1 ) {
         result = astRate( map->map1, at, ax1, ax2 );
         
/* If both input and output relate to the upper component Mappings, use its
   astRate method. */
      } else if( ax1 >= nout1 && ax2 >= nin1 ) {
         result = astRate( map->map2, at + nin1, ax1 - nout1, ax2 - nin1 );
         
/* If input and output relate to different component Mappings, return
   zero. */
      } else {
         result = 0.0;
      }         
   }

/* Reinstate the original Invert flags of the component Mappings .*/
   astSetInvert( map->map1, old_inv1 );
   astSetInvert( map->map2, old_inv2 );

/* Return the result. */
   return result;
}

static AstMapping *Simplify( AstMapping *this_mapping ) {
/*
*  Name:
*     Simplify

*  Purpose:
*     Simplify a Mapping.

*  Type:
*     Private function.

*  Synopsis:
*     #include "mapping.h"
*     AstMapping *Simplify( AstMapping *this )

*  Class Membership:
*     CmpMap method (over-rides the astSimplify method inherited from
*     the Mapping class).

*  Description:
*     This function simplifies a CmpMap to eliminate redundant
*     computational steps, or to merge separate steps which can be
*     performed more efficiently in a single operation.

*  Parameters:
*     this
*        Pointer to the original Mapping.

*  Returned Value:
*     A new pointer to the (possibly simplified) Mapping.

*  Notes:
*     - A NULL pointer value will be returned if this function is
*     invoked with the AST error status set, or if it should fail for
*     any reason.
*/

/* Local Variables: */
   AstCmpMap *this;              /* Pointer to CmpMap structure */
   AstMapping **map_list;        /* Mapping array pointer */
   AstMapping *map;              /* Pointer to cloned Mapping pointer */
   AstMapping *result;           /* Result pointer to return */
   AstMapping *tmp;              /* Temporary Mapping pointer */
   int *invert_list;             /* Invert array pointer */
   int *mlist;                   /* Point to list of modified Mapping indices */
   int *nlist;                   /* Point to list of Mapping counts */
   int i;                        /* Loop counter for Mappings */
   int improved;                 /* Simplification achieved? */
   int invert;                   /* Invert attribute value */
   int invert_n;                 /* Invert value for final Mapping */
   int mlist_len;                /* No. of entries in mlist */
   int nlist_len;                /* No. of entries in nlist */
   int modified;                 /* Index of first modified Mapping */
   int nmap;                     /* Mapping count */
   int nominated;                /* Index of nominated Mapping */
   int set;                      /* Invert attribute set? */
   int set_n;                    /* Invert set for final Mapping? */
   int simpler;                  /* Simplification possible? */
   int t;                        /* Temporary storage */
   int wlen1;                    /* Pattern wavelength for "modified" values */
   int wlen2;                    /* Pattern wavelength for "nmap" values */

   static int depth = 0;         /* Depth of recursive nesting */
   static int *clist = NULL;     /* Pointer to  list holding atomic mapping counts */
   static int clist_len = 0;     /* Length of clist list */

/* Initialise. */
   result = NULL;

/* Check the global error status. */
   if ( !astOK ) return result;

/* Obtain a pointer to the CmpMap structure. */
   this = (AstCmpMap *) this_mapping;

/* Increment the number of recursive entries into this function. */
   depth++;

/* If this is a top-level entry, initialise a pointer to a dynamic list
   used to hold the number of atomic Mappings in the CmpMap supplied at
   each entry. */
   if( depth == 1 ) clist = NULL;

/* Count the total number of atomic Mappings contained in this CmpMap.
   Add this number onto the end of the list initialised above. If there
   is evidence of repeating patterns in the list, this probably means we
   are in infinite recursive loop. In this case, we just returned the
   supplied pointer in order to break out of the loop. We also remove the
   value added to the list since it will disrupt any pattern occuring at
   a higher level. */
   if( PatternCheck( CountMappings( this_mapping ), 1, &clist, &clist_len ) ){
      result = astClone( this_mapping );
      clist_len--;

/* If there is no evidence of looping in the recursive invocations of
   this function, continue to simplify the supplied Mapping */
   } else {

/* Initialise dynamic arrays of Mapping pointers and associated Invert
   flags. */
      nmap = 0;
      map_list = NULL;
      invert_list = NULL;

/* Decompose the CmpMap into a sequence of Mappings to be applied in
   series or parallel, as appropriate, and an associated list of
   Invert flags. If any inverted CmpMaps are found in the Mapping, then
   we can at least simplify the returned Mapping by swapping and
   inverting the components. Set "simpler" to indicate this. */
      simpler = astMapList( this_mapping, this->series, astGetInvert( this ), &nmap,
                            &map_list, &invert_list );

/* Initialise pointers to memory used to hold lists of the modified
   Mapping index and the number of mappings after each call of
   astMapMerge. */
      mlist = NULL;
      nlist = NULL;

/* Loop to simplify the sequence until a complete pass through it has
   been made without producing any improvement. */
      improved = 1;
      while ( astOK && improved ) {
         improved = 0;

/* Loop to nominate each Mapping in the sequence in turn. */
         nominated = 0;
         while ( astOK && ( nominated < nmap ) ) {

/* Clone a pointer to the nominated Mapping and attempt to merge it
   with its neighbours. Annul the cloned pointer afterwards. */
            map = astClone( map_list[ nominated ] );
            modified = astMapMerge( map, nominated, this->series,
                                    &nmap, &map_list, &invert_list );
            map = astAnnul( map );

/* Move on to nominate the next Mapping in the sequence. */
            nominated++;

/* Note if any simplification occurred above. */
            if( modified >= 0 ) {

/* Append the index of the first modified Mapping in the list and and check 
   that there is no repreating pattern in the list. If there is, we are 
   probably in a loop where one mapping class is making a change, and another 
   is undoing the change. The Looping function returns the "wavelength"
   of any pattern found. If a pattern was discovered, we ignore it unless 
   there is also a pattern in the "nmap" values - the wavelengths of the
   two patterns must be related by a integer factor. */
               wlen1 = PatternCheck( modified, 1, &mlist, &mlist_len );
               wlen2 = PatternCheck( nmap, wlen1, &nlist, &nlist_len );
               if( wlen1 && wlen2 ) {

/* Ensure wlen2 is larger tnan or equal to wlen1. */
                  if( wlen1 > wlen2 ) {
                     t = wlen1;
                     wlen1 = wlen2;
                     wlen2 = wlen1;
                  }

/* See if wlen2 is an integer multiple of wlen1. If not, ignore the
   patterns. */
                  if( ( wlen2 % wlen1 ) != 0 ) wlen1 = 0;
               }

/* Ignore the simplication if a repeating pattern is occurring. */
               if( wlen1 == 0 ) {
                  improved = 1;
                  simpler = 1;

/* If the simplification resulted in modification of an earlier
   Mapping than would normally be considered next, then go back to
   consider the modified one first. */
                  if ( modified < nominated ) nominated = modified;
               }
            }
         }
      }

/* Free resources */
      if( mlist ) mlist = astFree( mlist );
      if( nlist ) nlist = astFree( nlist );

/* Construct the output Mapping. */
/* ============================= */
/* If no simplification occurred above, then simply clone a pointer to
   the original Mapping. */
      if ( astOK ) {
         if ( !simpler ) {
            result = astClone( this );

/* Otherwise, we must construct the result from the contents of the
   Mapping list. */
         } else {

/* If the simplified Mapping list has only a single element, then the
   output Mapping will not be a CmpMap. In this case, we cannot
   necessarily set the Invert flag of the Mapping to the value we want
   (because we must not modify the Mapping itself. */
            if ( nmap == 1 ) {

/* Test if the Mapping already has the Invert attribute value we
   want. If so, we are lucky and can simply clone a pointer to it. */
               if ( invert_list[ 0 ] == astGetInvert( map_list[ 0 ] ) ) {
                  result = astClone( map_list[ 0 ] );

/* If not, we must make a copy. */
               } else {
                  result = astCopy( map_list[ 0 ] );

/* Either clear the copy's Invert attribute, or set it to 1, as
   required. */
                  if ( invert_list[ 0 ] ) {
                     astSetInvert( result, 1 );
                  } else {
                     astClearInvert( result );
                  }
               }

/* If the simplified Mapping sequence has more than one element, the
   output Mapping will be a CmpMap. In this case, we can set each
   individual Mapping element to have the Invert attribute value we
   want, so long as we return these attribute values to their original
   state again afterwards (once a Mapping is encapsulated inside a
   CmpMap, further external changes to its Invert attribute do not
   affect the behaviour of the CmpMap). */
            } else {

/* Determine if the Invert attribute for the last Mapping is set, and
   obtain its value. */
               set_n = astTestInvert( map_list[ nmap - 1 ] );
               invert_n = astGetInvert( map_list[ nmap - 1 ] );

/* Set this attribute to the value we want. */
               astSetInvert( map_list[ nmap - 1 ], invert_list[ nmap - 1 ] );

/* Loop through the Mapping sequence in reverse to merge it into an
   equivalent CmpMap. */
               for ( i = nmap - 1; i >= 0; i-- ) {

/* Simply clone the pointer to the last Mapping in the sequence (which
   will be encountered first). */
                  if ( !result ) {
                     result = astClone( map_list[ i ] );

/* For subsequent Mappings, test if the Invert attribute is set and
   save its value. */
                  } else {
                     set = astTestInvert( map_list[ i ] );
                     invert = astGetInvert( map_list[ i ] );

/* Set this attribute to the value required. */
                     astSetInvert( map_list[ i ], invert_list[ i ] );
               
/* Combine the Mapping with the CmpMap formed so far and replace the
   result pointer with the new pointer this produces, annulling the
   previous pointer. */
                     tmp = (AstMapping *) astCmpMap( map_list[ i ], result,
                                                     this->series, "" );
                     (void) astAnnul( result );
                     result = tmp;

/* Restore the Invert attribute of the Mapping to its original
   state. */
                     if ( !set ) {
                        astClearInvert( map_list[ i ] );
                     } else {
                        astSetInvert( map_list[ i ], invert );
                     }
                  }
               }

/* When all the Mappings have been merged into the CmpMap, restore the
   state of the Invert attribute for the final Mapping in the
   sequence. */
               if ( !set_n ) {
                  astClearInvert( map_list[ nmap - 1  ] );
               } else {
                  astSetInvert( map_list[ nmap - 1 ], invert_n );
               }
            }
         }
      }

/* Clean up. */
/* ========= */
/* Loop to annul all the Mapping pointers in the simplified list. */
      for ( i = 0; i < nmap; i++ ) map_list[ i ] = astAnnul( map_list[ i ] );

/* Free the dynamic arrays. */
      map_list = astFree( map_list );
      invert_list = astFree( invert_list );
   }

/* If an error occurred, annul the returned Mapping. */
   if ( !astOK ) result = astAnnul( result );

/* If this is a top-level entry, free the pointer to the dynamic list
   used to hold the number of atomic Mappings in the CmpMap supplied at
   each entry. */
   if( depth == 1 ) clist = astFree( clist );

/* Decrement the number of recursive entries into this function. */
   depth--;

/* Return the result. */
   return result;
}

static AstPointSet *Transform( AstMapping *this, AstPointSet *in,
                               int forward, AstPointSet *out ) {
/*
*  Name:
*     Transform

*  Purpose:
*     Apply a CmpMap to transform a set of points.

*  Type:
*     Private function.

*  Synopsis:
*     #include "cmpmap.h"
*     AstPointSet *Transform( AstMapping *this, AstPointSet *in,
*                             int forward, AstPointSet *out )

*  Class Membership:
*     CmpMap member function (over-rides the astTransform method inherited
*     from the Mapping class).

*  Description:
*     This function takes a CmpMap and a set of points encapsulated in a
*     PointSet and transforms the points so as to apply the required Mapping.
*     This implies applying each of the CmpMap's component Mappings in turn,
*     either in series or in parallel.

*  Parameters:
*     this
*        Pointer to the CmpMap.
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
*     match the number of coordinates for the CmpMap being applied.
*     -  If an output PointSet is supplied, it must have space for sufficient
*     number of points and coordinate values per point to accommodate the
*     result. Any excess space will be ignored.
*/

/* Local Variables: */
   AstCmpMap *map;               /* Pointer to CmpMap to be applied */
   AstPointSet *result;          /* Pointer to output PointSet */
   AstPointSet *temp1;           /* Pointer to temporary PointSet */
   AstPointSet *temp2;           /* Pointer to temporary PointSet */
   AstPointSet *temp;            /* Pointer to temporary PointSet */
   int forward1;                 /* Use forward direction for Mapping 1? */
   int forward2;                 /* Use forward direction for Mapping 2? */
   int ipoint1;                  /* Index of first point in batch */
   int ipoint2;                  /* Index of last point in batch */
   int nin1;                     /* No. input coordinates for Mapping 1 */
   int nin2;                     /* No. input coordinates for Mapping 2 */
   int nin;                      /* No. input coordinates supplied */
   int nout1;                    /* No. output coordinates for Mapping 1 */
   int nout2;                    /* No. output coordinates for Mapping 2 */
   int nout;                     /* No. output coordinates supplied */
   int np;                       /* Number of points in batch */
   int npoint;                   /* Number of points to be transformed */

/* Local Constants: */
   const int nbatch = 2048;      /* Maximum points in a batch */

/* Check the global error status. */
   if ( !astOK ) return NULL;

/* Obtain a pointer to the CmpMap. */
   map = (AstCmpMap *) this;

/* Apply the parent Mapping using the stored pointer to the Transform member
   function inherited from the parent Mapping class. This function validates
   all arguments and generates an output PointSet if necessary, but does not
   actually transform any coordinate values. */
   result = (*parent_transform)( this, in, forward, out );

/* We now extend the parent astTransform method by applying the component
   Mappings of the CmpMap to generate the output coordinate values. */

/* Determine whether to apply the forward or inverse Mapping, according to the
   direction specified and whether the Mapping has been inverted. */
   if ( astGetInvert( map ) ) forward = !forward;

/* Check if either component Mapping's inversion flag has changed since it was
   used to construct the CmpMap. Set a "forward" flag for each Mapping to
   change the direction we will use, to compensate if necessary. (Such changes
   may have occurred if other pointers to the component Mappings are in
   circulation). */
   forward1 = forward;
   forward2 = forward;
   if ( map->invert1 != astGetInvert( map->map1 ) ) forward1 = !forward1;
   if ( map->invert2 != astGetInvert( map->map2 ) ) forward2 = !forward2;

/* Determine the number of points being transformed. */
   npoint = astGetNpoint( in );

/* Mappings in series. */
/* ------------------- */
/* If required, use the two component Mappings in series. To do this, we must
   apply one Mapping followed by the other, which means storing an intermediate
   result. Since this function may be invoked recursively and have to store an
   intermediate result on each occasion, the memory required may become
   excessive when transforming large numbers of points. To overcome this, we
   split the points up into smaller batches. */
   if ( astOK ) {
      if ( map->series ) {

/* Obtain the numbers of input and output coordinates. */
         nin = astGetNcoord( in );
         nout = astGetNcoord( result );

/* Loop to process all the points in batches, of maximum size nbatch points. */
         for ( ipoint1 = 0; ipoint1 < npoint; ipoint1 += nbatch ) {

/* Calculate the index of the final point in the batch and deduce the number of
   points (np) to be processed in this batch. */
            ipoint2 = ipoint1 + nbatch - 1;
            if ( ipoint2 > npoint - 1 ) ipoint2 = npoint - 1;
            np = ipoint2 - ipoint1 + 1;

/* Create temporary PointSets to describe the input and output points for this
   batch. */
            temp1 = astPointSet( np, nin, "" );
            temp2 = astPointSet( np, nout, "" );

/* Associate the required subsets of the input and output coordinates with the
   two PointSets. */
            astSetSubPoints( in, ipoint1, 0, temp1 );
            astSetSubPoints( result, ipoint1, 0, temp2 );

/* Apply the two Mappings in sequence and in the required order and direction.
   Store the intermediate result in a temporary PointSet (temp) which is
   created by the first Mapping applied. */
            if ( forward ) {
               temp = astTransform( map->map1, temp1, forward1, NULL );
               (void) astTransform( map->map2, temp, forward2, temp2 );
            } else {
               temp = astTransform( map->map2, temp1, forward2, NULL );
               (void) astTransform( map->map1, temp, forward1, temp2 );
            }

/* Delete the temporary PointSets after processing each batch of points. */
            temp = astDelete( temp );
            temp1 = astDelete( temp1 );
            temp2 = astDelete( temp2 );

/* Quit processing batches if an error occurs. */
            if ( !astOK ) break;
         }

/* Mappings in parallel. */
/* --------------------- */
/* If required, use the two component Mappings in parallel. Since we do not
   need to allocate any memory to hold intermediate coordinate values here,
   there is no need to process the points in batches. */
      } else {

/* Get the effective number of input and output coordinates per point for each
   Mapping (taking account of the direction in which each will be used to
   transform points). */
         nin1 = forward1 ? astGetNin( map->map1 ) : astGetNout( map->map1 );
         nout1 = forward1 ? astGetNout( map->map1 ) : astGetNin( map->map1 );
         nin2 = forward2 ? astGetNin( map->map2 ) : astGetNout( map->map2 );
         nout2 = forward2 ? astGetNout( map->map2 ) : astGetNin( map->map2 );

/* Create temporary PointSets to describe the input and output coordinates for
   the first Mapping. */
         temp1 = astPointSet( npoint, nin1, "" );
         temp2 = astPointSet( npoint, nout1, "" );

/* Associate the required subsets of the input and output coordinates with
   these PointSets. */
         astSetSubPoints( in, 0, 0, temp1 );
         astSetSubPoints( result, 0, 0, temp2 );

/* Use the astTransform method to apply the coordinate transformation described
   by the first Mapping. */
         (void) astTransform( map->map1, temp1, forward1, temp2 );

/* Delete the temporary PointSets. */
         temp1 = astDelete( temp1 );
         temp2 = astDelete( temp2 );

/* Create a new pair of temporary PointSets to describe the input and output
   coordinates for the second Mapping, and associate the required subsets of
   the input and output coordinates with these PointSets. */
         temp1 = astPointSet( npoint, nin2, "" );
         temp2 = astPointSet( npoint, nout2, "" );
         astSetSubPoints( in, 0, nin1, temp1 );
         astSetSubPoints( result, 0, nout1, temp2 );

/* Apply the coordinate transformation described by the second Mapping. */
         (void) astTransform( map->map2, temp1, forward2, temp2 );

/* Delete the two temporary PointSets. */
         temp1 = astDelete( temp1 );
         temp2 = astDelete( temp2 );
      }
   }

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
*     Copy constructor for CmpMap objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Copy( const AstObject *objin, AstObject *objout )

*  Description:
*     This function implements the copy constructor for CmpMap objects.

*  Parameters:
*     objin
*        Pointer to the object to be copied.
*     objout
*        Pointer to the object being constructed.

*  Returned Value:
*     void

*  Notes:
*     -  This constructor makes a deep copy, including a copy of the component
*     Mappings within the CmpMap.
*/

/* Local Variables: */
   AstCmpMap *in;                /* Pointer to input CmpMap */
   AstCmpMap *out;               /* Pointer to output CmpMap */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain pointers to the input and output CmpMaps. */
   in = (AstCmpMap *) objin;
   out = (AstCmpMap *) objout;

/* For safety, start by clearing any references to the input component
   Mappings from the output CmpMap. */
   out->map1 = NULL;
   out->map2 = NULL;

/* Make copies of these Mappings and store pointers to them in the output
   CmpMap structure. */
   out->map1 = astCopy( in->map1 );
   out->map2 = astCopy( in->map2 );
}

/* Destructor. */
/* ----------- */
static void Delete( AstObject *obj ) {
/*
*  Name:
*     Delete

*  Purpose:
*     Destructor for CmpMap objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Delete( AstObject *obj )

*  Description:
*     This function implements the destructor for CmpMap objects.

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
   AstCmpMap *this;              /* Pointer to CmpMap */

/* Obtain a pointer to the CmpMap structure. */
   this = (AstCmpMap *) obj;

/* Annul the pointers to the component Mappings. */
   this->map1 = astAnnul( this->map1 );
   this->map2 = astAnnul( this->map2 );

/* Clear the remaining CmpMap variables. */
   this->invert1 = 0;
   this->invert2 = 0;
   this->series = 0;
}

/* Dump function. */
/* -------------- */
static void Dump( AstObject *this_object, AstChannel *channel ) {
/*
*  Name:
*     Dump

*  Purpose:
*     Dump function for CmpMap objects.

*  Type:
*     Private function.

*  Synopsis:
*     void Dump( AstObject *this, AstChannel *channel )

*  Description:
*     This function implements the Dump function which writes out data
*     for the CmpMap class to an output Channel.

*  Parameters:
*     this
*        Pointer to the CmpMap whose data are being written.
*     channel
*        Pointer to the Channel to which the data are being written.
*/

/* Local Variables: */
   AstCmpMap *this;              /* Pointer to the CmpMap structure */
   int ival;                     /* Integer value */
   int set;                      /* Attribute value set? */

/* Check the global error status. */
   if ( !astOK ) return;

/* Obtain a pointer to the CmpMap structure. */
   this = (AstCmpMap *) this_object;

/* Write out values representing the instance variables for the CmpMap
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

/* Series. */
/* ------- */
   ival = this->series;
   set = ( ival == 0 );
   astWriteInt( channel, "Series", set, 0, ival,
                ival ? "Component Mappings applied in series" :
                       "Component Mappings applied in parallel" );

/* First Invert flag. */
/* ------------------ */
   ival = this->invert1;
   set = ( ival != 0 );
   astWriteInt( channel, "InvA", set, 0, ival,
                ival ? "First Mapping used in inverse direction" :
                       "First Mapping used in forward direction" );

/* Second Invert flag. */
/* ------------------- */
   ival = this->invert2;
   set = ( ival != 0 );
   astWriteInt( channel, "InvB", set, 0, ival,
                ival ? "Second Mapping used in inverse direction" :
                       "Second Mapping used in forward direction" );

/* First Mapping. */
/* -------------- */
   astWriteObject( channel, "MapA", 1, 1, this->map1,
                   "First component Mapping" );

/* Second Mapping. */
/* --------------- */
   astWriteObject( channel, "MapB", 1, 1, this->map2,
                   "Second component Mapping" );
}

/* Standard class functions. */
/* ========================= */
/* Implement the astIsACmpMap and astCheckCmpMap functions using the
   macros defined for this purpose in the "object.h" header file. */
astMAKE_ISA(CmpMap,Mapping,check,&class_init)
astMAKE_CHECK(CmpMap)

AstCmpMap *astCmpMap_( void *map1_void, void *map2_void, int series,
                       const char *options, ... ) {
/*
*+
*  Name:
*     astCmpMap

*  Purpose:
*     Create a CmpMap.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "cmpmap.h"
*     AstCmpMap *astCmpMap( AstMapping *map1, AstMapping *map2, int series,
*                           const char *options, ... )

*  Class Membership:
*     CmpMap constructor.

*  Description:
*     This function creates a new CmpMap and optionally initialises its
*     attributes.

*  Parameters:
*     map1
*        Pointer to the first Mapping.
*     map2
*        Pointer to the second Mapping.
*     series
*        If a non-zero value is given, the two Mappings will be connected
*        together in series. A zero value requests that they be connected in
*        parallel.
*     options
*        Pointer to a null terminated string containing an optional
*        comma-separated list of attribute assignments to be used for
*        initialising the new CmpMap. The syntax used is the same as for the
*        astSet method and may include "printf" format specifiers identified
*        by "%" symbols in the normal way.
*     ...
*        If the "options" string contains "%" format specifiers, then an
*        optional list of arguments may follow it in order to supply values to
*        be substituted for these specifiers. The rules for supplying these
*        are identical to those for the astSet method (and for the C "printf"
*        function).

*  Returned Value:
*     A pointer to the new CmpMap.

*  Notes:
*     - A null pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*-

*  Implementation Notes:
*     - This function implements the basic CmpMap constructor which is
*     available via the protected interface to the CmpMap class.  A
*     public interface is provided by the astCmpMapId_ function.
*     - Because this function has a variable argument list, it is
*     invoked by a macro that evaluates to a function pointer (not a
*     function invocation) and no checking or casting of arguments is
*     performed before the function is invoked. Because of this, the
*     "map1" and "map2" parameters are of type (void *) and are
*     converted and validated within the function itself.
*/

/* Local Variables: */
   AstCmpMap *new;               /* Pointer to new CmpMap */
   AstMapping *map1;             /* Pointer to first Mapping structure */
   AstMapping *map2;             /* Pointer to second Mapping structure */
   va_list args;                 /* Variable argument list */

/* Initialise. */
   new = NULL;

/* Check the global status. */
   if ( !astOK ) return new;

/* Obtain and validate pointers to the Mapping structures provided. */
   map1 = astCheckMapping( map1_void );
   map2 = astCheckMapping( map2_void );
   if ( astOK ) {

/* Initialise the CmpMap, allocating memory and initialising the
   virtual function table as well if necessary. */
      new = astInitCmpMap( NULL, sizeof( AstCmpMap ), !class_init, &class_vtab,
                           "CmpMap", map1, map2, series );

/* If successful, note that the virtual function table has been
   initialised. */
      if ( astOK ) {
         class_init = 1;

/* Obtain the variable argument list and pass it along with the
   options string to the astVSet method to initialise the new CmpMap's
   attributes. */
         va_start( args, options );
         astVSet( new, options, args );
         va_end( args );

/* If an error occurred, clean up by deleting the new object. */
         if ( !astOK ) new = astDelete( new );
      }
   }

/* Return a pointer to the new CmpMap. */
   return new;
}

AstCmpMap *astCmpMapId_( void *map1_void, void *map2_void, int series,
                         const char *options, ... ) {
/*
*++
*  Name:
c     astCmpMap
f     AST_CMPMAP

*  Purpose:
*     Create a CmpMap.

*  Type:
*     Public function.

*  Synopsis:
c     #include "cmpmap.h"
c     AstCmpMap *astCmpMap( AstMapping *map1, AstMapping *map2, int series,
c                           const char *options, ... )
f     RESULT = AST_CMPMAP( MAP1, MAP2, SERIES, OPTIONS, STATUS )

*  Class Membership:
*     CmpMap constructor.

*  Description:
*     This function creates a new CmpMap and optionally initialises
*     its attributes.
*
*     A CmpMap is a compound Mapping which allows two component
*     Mappings (of any class) to be connected together to form a more
*     complex Mapping. This connection may either be "in series"
*     (where the first Mapping is used to transform the coordinates of
*     each point and the second mapping is then applied to the
*     result), or "in parallel" (where one Mapping transforms the
*     earlier coordinates for each point and the second Mapping
*     simultaneously transforms the later coordinates).
*
*     Since a CmpMap is itself a Mapping, it can be used as a
*     component in forming further CmpMaps. Mappings of arbitrary
*     complexity may be built from simple individual Mappings in this
*     way.

*  Parameters:
c     map1
f     MAP1 = INTEGER (Given)
*        Pointer to the first component Mapping.
c     map2
f     MAP2 = INTEGER (Given)
*        Pointer to the second component Mapping.
c     series
f     SERIES = LOGICAL (Given)
c        If a non-zero value is given for this parameter, the two
c        component Mappings will be connected in series. A zero
c        value requests that they are connected in parallel.
f        If a .TRUE. value is given for this argument, the two
f        component Mappings will be connected in series. A
f        .FALSE. value requests that they are connected in parallel.
c     options
f     OPTIONS = CHARACTER * ( * ) (Given)
c        Pointer to a null-terminated string containing an optional
c        comma-separated list of attribute assignments to be used for
c        initialising the new CmpMap. The syntax used is identical to
c        that for the astSet function and may include "printf" format
c        specifiers identified by "%" symbols in the normal way.
f        A character string containing an optional comma-separated
f        list of attribute assignments to be used for initialising the
f        new CmpMap. The syntax used is identical to that for the
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
c     astCmpMap()
f     AST_CMPMAP = INTEGER
*        A pointer to the new CmpMap.

*  Notes:
*     - If the component Mappings are connected in series, then using
*     the resulting CmpMap to transform coordinates will cause the
*     first Mapping to be applied, followed by the second Mapping. If
*     the inverse CmpMap transformation is requested, the two
*     component Mappings will be applied in both the reverse order and
*     the reverse direction.
*     - When connecting two component Mappings in series, the number
*     of output coordinates generated by the first Mapping (its Nout
*     attribute) must equal the number of input coordinates accepted
*     by the second Mapping (its Nin attribute).
*     - If the component Mappings of a CmpMap are connected in
*     parallel, then the first Mapping will be used to transform the
*     earlier input coordinates for each point (and to produce the
*     earlier output coordinates) and the second Mapping will be used
*     simultaneously to transform the remaining input coordinates (to
*     produce the remaining output coordinates for each point). If the
*     inverse transformation is requested, each Mapping will still be
*     applied to the same coordinates, but in the reverse direction.
*     - When connecting two component Mappings in parallel, there is
*     no restriction on the number of input and output coordinates for
*     each Mapping.
c     - Note that the component Mappings supplied are not copied by
c     astCmpMap (the new CmpMap simply retains a reference to
c     them). They may continue to be used for other purposes, but
c     should not be deleted. If a CmpMap containing a copy of its
c     component Mappings is required, then a copy of the CmpMap should
c     be made using astCopy.
f     - Note that the component Mappings supplied are not copied by
f     AST_CMPMAP (the new CmpMap simply retains a reference to
f     them). They may continue to be used for other purposes, but
f     should not be deleted. If a CmpMap containing a copy of its
f     component Mappings is required, then a copy of the CmpMap should
f     be made using AST_COPY.
*     - A null Object pointer (AST__NULL) will be returned if this
c     function is invoked with the AST error status set, or if it
f     function is invoked with STATUS set to an error value, or if it
*     should fail for any reason.
*--

*  Implementation Notes:
*     - This function implements the external (public) interface to
*     the astCmpMap constructor function. It returns an ID value
*     (instead of a true C pointer) to external users, and must be
*     provided because astCmpMap_ has a variable argument list which
*     cannot be encapsulated in a macro (where this conversion would
*     otherwise occur).
*     - Because no checking or casting of arguments is performed
*     before the function is invoked, the "map1" and "map2" parameters
*     are of type (void *) and are converted from an ID value to a
*     pointer and validated within the function itself.
*     - The variable argument list also prevents this function from
*     invoking astCmpMap_ directly, so it must be a re-implementation
*     of it in all respects, except for the conversions between IDs
*     and pointers on input/output of Objects.
*/

/* Local Variables: */
   AstCmpMap *new;               /* Pointer to new CmpMap */
   AstMapping *map1;             /* Pointer to first Mapping structure */
   AstMapping *map2;             /* Pointer to second Mapping structure */
   va_list args;                 /* Variable argument list */

/* Initialise. */
   new = NULL;

/* Check the global status. */
   if ( !astOK ) return new;

/* Obtain the Mapping pointers from the ID's supplied and validate the
   pointers to ensure they identify valid Mappings. */
   map1 = astCheckMapping( astMakePointer( map1_void ) );
   map2 = astCheckMapping( astMakePointer( map2_void ) );
   if ( astOK ) {

/* Initialise the CmpMap, allocating memory and initialising the
   virtual function table as well if necessary. */
      new = astInitCmpMap( NULL, sizeof( AstCmpMap ), !class_init, &class_vtab,
                           "CmpMap", map1, map2, series );

/* If successful, note that the virtual function table has been initialised. */
      if ( astOK ) {
         class_init = 1;

/* Obtain the variable argument list and pass it along with the
   options string to the astVSet method to initialise the new CmpMap's
   attributes. */
         va_start( args, options );
         astVSet( new, options, args );
         va_end( args );

/* If an error occurred, clean up by deleting the new object. */
         if ( !astOK ) new = astDelete( new );
      }
   }

/* Return an ID value for the new CmpMap. */
   return astMakeId( new );
}

AstCmpMap *astInitCmpMap_( void *mem, size_t size, int init,
                           AstCmpMapVtab *vtab, const char *name,
                           AstMapping *map1, AstMapping *map2, int series ) {
/*
*+
*  Name:
*     astInitCmpMap

*  Purpose:
*     Initialise a CmpMap.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "cmpmap.h"
*     AstCmpMap *astInitCmpMap( void *mem, size_t size, int init,
*                               AstCmpMapVtab *vtab, const char *name,
*                               AstMapping *map1, AstMapping *map2,
*                               int series )

*  Class Membership:
*     CmpMap initialiser.

*  Description:
*     This function is provided for use by class implementations to initialise
*     a new CmpMap object. It allocates memory (if necessary) to
*     accommodate the CmpMap plus any additional data associated with the
*     derived class. It then initialises a CmpMap structure at the start
*     of this memory. If the "init" flag is set, it also initialises the
*     contents of a virtual function table for a CmpMap at the start of
*     the memory passed via the "vtab" parameter.

*  Parameters:
*     mem
*        A pointer to the memory in which the CmpMap is to be initialised.
*        This must be of sufficient size to accommodate the CmpMap data
*        (sizeof(CmpMap)) plus any data used by the derived class. If a
*        value of NULL is given, this function will allocate the memory itself
*        using the "size" parameter to determine its size.
*     size
*        The amount of memory used by the CmpMap (plus derived class
*        data). This will be used to allocate memory if a value of NULL is
*        given for the "mem" parameter. This value is also stored in the
*        CmpMap structure, so a valid value must be supplied even if not
*        required for allocating memory.
*     init
*        A logical flag indicating if the CmpMap's virtual function table
*        is to be initialised. If this value is non-zero, the virtual function
*        table will be initialised by this function.
*     vtab
*        Pointer to the start of the virtual function table to be associated
*        with the new CmpMap.
*     name
*        Pointer to a constant null-terminated character string which contains
*        the name of the class to which the new object belongs (it is this
*        pointer value that will subsequently be returned by the Object
*        astClass function).
*     map1
*        Pointer to the first Mapping.
*     map2
*        Pointer to the second Mapping.
*     series
*        If a non-zero value is given, the two Mappings will be connected
*        together in series. A zero value requests that they be connected in
*        parallel.

*  Returned Value:
*     A pointer to the new CmpMap.

*  Notes:
*     -  A null pointer will be returned if this function is invoked with the
*     global error status set, or if it should fail for any reason.
*-
*/

/* Local Variables: */
   AstCmpMap *new;               /* Pointer to new CmpMap */
   int map_f;                    /* Forward transformation defined? */
   int map_i;                    /* Inverse transformation defined? */
   int nin2;                     /* No. input coordinates for Mapping 2 */
   int nin;                      /* No. input coordinates for CmpMap */
   int nout1;                    /* No. output coordinates for Mapping 1 */
   int nout;                     /* No. output coordinates for CmpMap */

/* Check the global status. */
   if ( !astOK ) return NULL;

/* If necessary, initialise the virtual function table. */
   if ( init ) astInitCmpMapVtab( vtab, name );

/* Initialise. */
   new = NULL;

/* Determine in which directions each component Mapping is able to transform
   coordinates. Combine these results to obtain a result for the overall
   CmpMap. If neither transformation direction is available, then report an
   error. */
   map_f = astGetTranForward( map1 ) && astGetTranForward( map2 );
   map_i = astGetTranInverse( map1 ) && astGetTranInverse( map2 );
   if ( astOK ) {
      if ( !map_f && !map_i ) {
         astError( AST__INTRD, "astInitCmpMap(%s): The two Mappings supplied "
                   "are not able to transform coordinates in either the "
                   "forward or inverse direction once connected together.",
                   name );

/* If connecting the Mappings in series, check that the number of coordinates
   are compatible and report an error if they are not. */
      } else if ( series ) {
         nout1 = astGetNout( map1 );
         nin2 = astGetNin( map2 );
         if ( astOK && ( nout1 != nin2 ) ) {
            astError( AST__INNCO, "astInitCmpMap(%s): The number of output "
                      "coordinates per point (%d) for the first Mapping "
                      "supplied does not match the number of input "
                      "coordinates (%d) for the second Mapping.", name, nout1,
                      nin2 );
         }
      }
   }

/* If OK, determine the total number of input and output coordinates per point
   for the CmpMap. */
   if ( astOK ) {
      if ( series ) {
         nin = astGetNin( map1 );
         nout = astGetNout( map2 );
      } else {
         nin = astGetNin( map1 ) + astGetNin( map2 );
         nout = astGetNout( map1 ) + astGetNout( map2 );
      }

   } else {
      nin = 0;
      nout = 0;
   }

/* Initialise a Mapping structure (the parent class) as the first component
   within the CmpMap structure, allocating memory if necessary. Specify
   the number of input and output coordinates and in which directions the
   Mapping should be defined. */
   if ( astOK ) {
      new = (AstCmpMap *) astInitMapping( mem, size, 0,
                                          (AstMappingVtab *) vtab, name,
                                          nin, nout, map_f, map_i );

      if ( astOK ) {

/* Initialise the CmpMap data. */
/* --------------------------- */
/* Store pointers to the component Mappings. */
         new->map1 = astClone( map1 );
         new->map2 = astClone( map2 );

/* Save the initial values of the inversion flags for these Mappings. */
         new->invert1 = astGetInvert( map1 );
         new->invert2 = astGetInvert( map2 );

/* Note whether the Mappings are joined in series (instead of in parallel),
   constraining this flag to be 0 or 1. */
         new->series = ( series != 0 );

/* If an error occurred, clean up by annulling the Mapping pointers and
   deleting the new object. */
         if ( !astOK ) {
            new->map1 = astAnnul( new->map1 );
            new->map2 = astAnnul( new->map2 );
            new = astDelete( new );
         }
      }
   }

/* Return a pointer to the new object. */
   return new;
}

AstCmpMap *astLoadCmpMap_( void *mem, size_t size,
                           AstCmpMapVtab *vtab, const char *name,
                           AstChannel *channel ) {
/*
*+
*  Name:
*     astLoadCmpMap

*  Purpose:
*     Load a CmpMap.

*  Type:
*     Protected function.

*  Synopsis:
*     #include "cmpmap.h"
*     AstCmpMap *astLoadCmpMap( void *mem, size_t size,
*                               AstCmpMapVtab *vtab, const char *name,
*                               AstChannel *channel )

*  Class Membership:
*     CmpMap loader.

*  Description:
*     This function is provided to load a new CmpMap using data read
*     from a Channel. It first loads the data used by the parent class
*     (which allocates memory if necessary) and then initialises a
*     CmpMap structure in this memory, using data read from the input
*     Channel.
*
*     If the "init" flag is set, it also initialises the contents of a
*     virtual function table for a CmpMap at the start of the memory
*     passed via the "vtab" parameter.


*  Parameters:
*     mem
*        A pointer to the memory into which the CmpMap is to be
*        loaded.  This must be of sufficient size to accommodate the
*        CmpMap data (sizeof(CmpMap)) plus any data used by derived
*        classes. If a value of NULL is given, this function will
*        allocate the memory itself using the "size" parameter to
*        determine its size.
*     size
*        The amount of memory used by the CmpMap (plus derived class
*        data).  This will be used to allocate memory if a value of
*        NULL is given for the "mem" parameter. This value is also
*        stored in the CmpMap structure, so a valid value must be
*        supplied even if not required for allocating memory.
*
*        If the "vtab" parameter is NULL, the "size" value is ignored
*        and sizeof(AstCmpMap) is used instead.
*     vtab
*        Pointer to the start of the virtual function table to be
*        associated with the new CmpMap. If this is NULL, a pointer to
*        the (static) virtual function table for the CmpMap class is
*        used instead.
*     name
*        Pointer to a constant null-terminated character string which
*        contains the name of the class to which the new object
*        belongs (it is this pointer value that will subsequently be
*        returned by the astGetClass method).
*
*        If the "vtab" parameter is NULL, the "name" value is ignored
*        and a pointer to the string "CmpMap" is used instead.

*  Returned Value:
*     A pointer to the new CmpMap.

*  Notes:
*     - A null pointer will be returned if this function is invoked
*     with the global error status set, or if it should fail for any
*     reason.
*-
*/

/* Local Variables: */
   AstCmpMap *new;               /* Pointer to the new CmpMap */

/* Initialise. */
   new = NULL;

/* Check the global error status. */
   if ( !astOK ) return new;

/* If a NULL virtual function table has been supplied, then this is
   the first loader to be invoked for this CmpMap. In this case the
   CmpMap belongs to this class, so supply appropriate values to be
   passed to the parent class loader (and its parent, etc.). */
   if ( !vtab ) {
      size = sizeof( AstCmpMap );
      vtab = &class_vtab;
      name = "CmpMap";

/* If required, initialise the virtual function table for this class. */
      if ( !class_init ) {
         astInitCmpMapVtab( vtab, name );
         class_init = 1;
      }
   }

/* Invoke the parent class loader to load data for all the ancestral
   classes of the current one, returning a pointer to the resulting
   partly-built CmpMap. */
   new = astLoadMapping( mem, size, (AstMappingVtab *) vtab, name,
                         channel );

   if ( astOK ) {

/* Read input data. */
/* ================ */
/* Request the input Channel to read all the input data appropriate to
   this class into the internal "values list". */
      astReadClassData( channel, "CmpMap" );

/* Now read each individual data item from this list and use it to
   initialise the appropriate instance variable(s) for this class. */

/* In the case of attributes, we first read the "raw" input value,
   supplying the "unset" value as the default. If a "set" value is
   obtained, we then use the appropriate (private) Set... member
   function to validate and set the value properly. */

/* Series. */
/* ------- */
      new->series = astReadInt( channel, "series", 1 );
      new->series = ( new->series != 0 );

/* First Invert flag. */
/* ------------------ */
      new->invert1 = astReadInt( channel, "inva", 0 );
      new->invert1 = ( new->invert1 != 0 );

/* Second Invert flag. */
/* ------------------- */
      new->invert2 = astReadInt( channel, "invb", 0 );
      new->invert2 = ( new->invert2 != 0 );

/* First Mapping. */
/* -------------- */
      new->map1 = astReadObject( channel, "mapa", NULL );

/* Second Mapping. */
/* --------------- */
      new->map2 = astReadObject( channel, "mapb", NULL );

/* If an error occurred, clean up by deleting the new CmpMap. */
      if ( !astOK ) new = astDelete( new );
   }

/* Return the new CmpMap pointer. */
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



static int PatternCheck( int val, int check, int **list, int *list_len ){
/*
*  Name:
*     Looping

*  Purpose:
*     Check for repeating patterns in a set of integer values.

*  Type:
*     Private function.

*  Synopsis:
*     #include "cmpmap.h"
*     int PatternCheck( int val, int nmap, int **mlist, int **nlist, int *list_len )

*  Class Membership:
*     CmpMap member function.

*  Description:
*     This function appends a supplied integer to a dynamic list, creating 
*     or expanding the list if necessary.It then optionally, check the
*     list for evidence of repeating patterns. If such a pattern is
*     found, its wavelength is returned.

*  Parameters:
*     val
*        The integer value to add to the list.
*     check
*        Should a check for reating patterns be performed?
*     list
*        Address of a location at which is stored a pointer to an array
*        holding the values supplied on previous invocations of this 
*        function. If a NULL pointer is supplied a new array is allocated.
*        On exit, the supplied value is appended to the end of the array. The 
*        array is extended as necessary. The returned pointer should be
*        freed using astFree when no longer needed.
*     list_len
*        Address of a location at which is stored the number of elements
*        in the "list" array.

*  Returned Value:
*     A non-zero "wavelength" value is returned if there is a repeating
*     pattern is found in the "list" array. Otherwise, zero is returned.
*     The "wavelength" is the number of integer values which constitute a
*     single instance of the pattern.

*  Notes:
*     - A value of 1 is returned if this function is invoked with the AST 
*     error status set, or if it should fail for any reason.
*/

/* Local Variables: */
   int *wave[ 30 ];          /* Pointers to start of waves */
   int iat;                  /* Index of elements added by this invocation */
   int jat;                  /* Index of element condiered next */
   int jlo;                  /* Earliest "mlist" entry to consider */
   int k;                    /* Index of element within pattern */
   int mxwave;               /* Max pattern length to consider */
   int iwave;                /* Index of current wave */
   int nwave;                /* Number of waves required to mark a pattern */
   int result;               /* Returned flag */
   int wavelen;              /* Current pattern length */

/* Check the global status. */
   if ( !astOK ) return 1;

/* Initialise */
   result = 0;

/* If no array has been supplied, create a new array. */
   if( !(*list) ) {
      *list = astMalloc( 100*sizeof( int ) );
      *list_len = 0;
   }

/* Store the new value in the array, extending it if necessary. */
   iat = (*list_len)++;
   *list = astGrow( *list, *list_len, sizeof( int ) );
   if( astOK ) {
      (*list)[ iat ] = val;

/* If required, determine the maximum "wavelength" for looping patterns to be 
   checked, and store the earliest list entry to consider. We take 3 complete 
   patterns as evidence of looping. */
      if( check ){
         mxwave = iat/3;
         if( mxwave > 50 ) mxwave = 50;
         jlo = iat - 3*mxwave;

/* Search backwards from the end of "list" looking for the most recent
   occurence of the supplied "val" value. Limit the search to
   wavelengths of no more than the above limit. */
         jat = iat - 1;
         while( jat >= jlo ) {
            if( (*list)[ jat ] == val ) {

/* When an earlier occurrence of "val" is found, see if the values
   which preceed it are the same as the values which preceed the new
   element if "list" added by this invocation. We use 3 complete
   patterns as evidence of looping, unless the wavelength is 1 in which
   case we use 30 patterns (this is because wavelengths of 1 can occur
   in short sequences legitamately). */
               wavelen = iat - jat;

               if( wavelen == 1 ) {
                  nwave = 30;
                  if( nwave > iat ) nwave = iat;
               } else {
                  nwave = 3;
               }

               if( nwave*wavelen <= *list_len ) {
                  result = wavelen;
                  wave[ 0 ] = *list + *list_len - wavelen;
                  for( iwave = 1; iwave < nwave; iwave++ ) {
                     wave[ iwave ] = wave[ iwave - 1 ] - wavelen;
                  }

                  for( k = 0; k < wavelen; k++ ) {
                     for( iwave = 1; iwave < nwave; iwave++ ) {
                        if( *wave[ iwave ] != *wave[ 0 ] ) {
                           result = 0;
                           break;
                        }
                        wave[ iwave ]++;
                     }
                     wave[ 0 ]++;
                  }   
               }

/* Break if we have found a repeating pattern. */
               if( result ) break;

            }
            jat--;
         }
      }
   }

   if( !astOK ) result= 1;

/* Return the result.*/
   return result;
}



static int CountMappings( AstMapping *this_mapping ){
/*
*  Name:
*     CountMappings

*  Purpose:
*     Count the total number of atomic Mappings in a given Mapping.

*  Type:
*     Private function.

*  Synopsis:
*     #include "cmpmap.h"
*     int CountMappings( AstMapping *this_mapping )

*  Class Membership:
*     CmpMap member function.

*  Description:
*     This function returns the number of atomic Mappings in the given
*     Mapping. This will be one unless the supplied Mapping is a CmpMap.

*  Parameters:
*     this_mapping
*        Pointer to the Mapping.

*  Returned Value:
*     The Mapping count. Zero if an error has occurred.

*/

/* Local Variables: */
   AstCmpMap *this;  /* Pointer to the CmpMap structure */
   int result;       /* Returned value */

/* Check the global status. */
   if ( !astOK ) return 0;

   if( astIsACmpMap( this_mapping ) ) {
      this = (AstCmpMap *) this_mapping;
      result = CountMappings( this->map1 ) + CountMappings( this->map2 );
   } else {
      result = 1;
   }

   return result;
}
