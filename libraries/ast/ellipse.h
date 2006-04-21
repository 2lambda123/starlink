#if !defined( ELLIPSE_INCLUDED ) /* Include this file only once */
#define ELLIPSE_INCLUDED
/*
*+
*  Name:
*     ellipse.h

*  Type:
*     C include file.

*  Purpose:
*     Define the interface to the Ellipse class.

*  Invocation:
*     #include "ellipse.h"

*  Description:
*     This include file defines the interface to the Ellipse class and
*     provides the type definitions, function prototypes and macros,
*     etc.  needed to use this class.
*
*     The Ellipse class implement a Region which represents a simple interval
*     on each axis of the encapsulated Frame

*  Inheritance:
*     The Ellipse class inherits from the Region class.

*  Feature Test Macros:
*     astCLASS
*        If the astCLASS macro is undefined, only public symbols are
*        made available, otherwise protected symbols (for use in other
*        class implementations) are defined. This macro also affects
*        the reporting of error context information, which is only
*        provided for external calls to the AST library.

*  Copyright:
*     Copyright (C) 1997-2006 Council for the Central Laboratory of the
*     Research Councils

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public Licence as
*     published by the Free Software Foundation; either version 2 of
*     the Licence, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public Licence for more details.
*     
*     You should have received a copy of the GNU General Public Licence
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David S. Berry (Starlink)

*  History:
*     7-SEP-2004 (DSB):
*        Original version.
*-
*/

/* Include files. */
/* ============== */
/* Interface definitions. */
/* ---------------------- */
#include "region.h"              /* Coordinate regions (parent class) */

#if defined(astCLASS)            /* Protected */
#include "channel.h"             /* I/O channels */
#endif

/* C header files. */
/* --------------- */
#if defined(astCLASS)            /* Protected */
#include <stddef.h>
#endif

/* Type Definitions. */
/* ================= */
/* Ellipse structure. */
/* ------------------ */
/* This structure contains all information that is unique to each object in
   the class (e.g. its instance variables). */
typedef struct AstEllipse {

/* Attributes inherited from the parent class. */
   AstRegion region;             /* Parent class structure */

/* Attributes specific to objects in this class. */
   double *centre;               /* Ellipse centre coords */
   double *point1;               /* Point at end of primary axis */
   double angle;                 /* Orientation of primary axis */
   double a;                     /* Half-length of primary axis */
   double b;                     /* Half-length of secondary axis */
   double lbx;                   /* Lower x limit of mesh bounding box */
   double ubx;                   /* Upper y limit of mesh bounding box */
   double lby;                   /* Lower x limit of mesh bounding box */
   double uby;                   /* Upper y limit of mesh bounding box */
   int stale;                    /* Is cached information stale? */

} AstEllipse;

/* Virtual function table. */
/* ----------------------- */
/* This table contains all information that is the same for all
   objects in the class (e.g. pointers to its virtual functions). */
#if defined(astCLASS)            /* Protected */
typedef struct AstEllipseVtab {

/* Properties (e.g. methods) inherited from the parent class. */
   AstRegionVtab region_vtab;    /* Parent class virtual function table */

/* Unique flag value to determine class membership. */
   int *check;                   /* Check value */

/* Properties (e.g. methods) specific to this class. */
} AstEllipseVtab;
#endif

/* Function prototypes. */
/* ==================== */
/* Prototypes for standard class functions. */
/* ---------------------------------------- */
astPROTO_CHECK(Ellipse)          /* Check class membership */
astPROTO_ISA(Ellipse)            /* Test class membership */

/* Constructor. */
#if defined(astCLASS)            /* Protected. */
AstEllipse *astEllipse_( void *, int, const double[2], const double[2], const double[2], AstRegion *, const char *, ... );
#else
AstEllipse *astEllipseId_( void *, int, const double[2], const double[2], const double[2], AstRegion *, const char *, ... );
#endif

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
AstEllipse *astInitEllipse_( void *, size_t, int, AstEllipseVtab *,
                           const char *, AstFrame *, int, const double[2],
                           const double[2], const double[2], AstRegion * );

/* Vtab initialiser. */
void astInitEllipseVtab_( AstEllipseVtab *, const char * );

/* Loader. */
AstEllipse *astLoadEllipse_( void *, size_t, AstEllipseVtab *,
                             const char *, AstChannel * );

#endif

/* Prototypes for member functions. */
/* -------------------------------- */
# if defined(astCLASS)           /* Protected */
AstRegion *astBestEllipse_( AstPointSet *, double *, AstRegion * );
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
#define astCheckEllipse(this) astINVOKE_CHECK(Ellipse,this)

/* Test class membership. */
#define astIsAEllipse(this) astINVOKE_ISA(Ellipse,this)

/* Constructor. */
#if defined(astCLASS)            /* Protected. */
#define astEllipse astINVOKE(F,astEllipse_)
#else
#define astEllipse astINVOKE(F,astEllipseId_)
#endif

#if defined(astCLASS)            /* Protected */

/* Initialiser. */
#define astInitEllipse(mem,size,init,vtab,name,frame,form,p1,p2,p3,unc) \
astINVOKE(O,astInitEllipse_(mem,size,init,vtab,name,frame,form,p1,p2,p3,unc))

/* Vtab Initialiser. */
#define astInitEllipseVtab(vtab,name) astINVOKE(V,astInitEllipseVtab_(vtab,name))
/* Loader. */
#define astLoadEllipse(mem,size,vtab,name,channel) \
astINVOKE(O,astLoadEllipse_(mem,size,vtab,name,astCheckChannel(channel)))
#endif

/* Interfaces to public member functions. */
/* -------------------------------------- */
/* Here we make use of astCheckEllipse to validate Ellipse pointers
   before use.  This provides a contextual error report if a pointer
   to the wrong sort of Object is supplied. */

#if defined(astCLASS)            /* Protected */
#define astBestEllipse(pset,cen,unc) astBestEllipse_(pset,cen,unc)
#endif
#endif
