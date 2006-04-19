/*
*+
*  Name:
*     ffluxframe.c

*  Purpose:
*     Define a FORTRAN 77 interface to the AST FluxFrame class.

*  Type of Module:
*     C source file.

*  Description:
*     This file defines FORTRAN 77-callable C functions which provide
*     a public FORTRAN 77 interface to the FluxFrame class.

*  Routines Defined:
*     AST_ISAFLUXFRAME
*     AST_FLUXFRAME

*  Copyright:
*     <COPYRIGHT_STATEMENT>

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
*     1-DEC-2004 (DSB):
*        Original version.
*/

/* Define the astFORTRAN77 macro which prevents error messages from
   AST C functions from reporting the file and line number where the
   error occurred (since these would refer to this file, they would
   not be useful). */
#define astFORTRAN77

/* Header files. */
/* ============= */
#include "f77.h"                 /* FORTRAN <-> C interface macros (SUN/209) */
#include "c2f77.h"               /* F77 <-> C support functions/macros */
#include "error.h"               /* Error reporting facilities */
#include "memory.h"              /* Memory handling facilities */
#include "fluxframe.h"           /* C interface to the FluxFrame class */

F77_LOGICAL_FUNCTION(ast_isafluxframe)( INTEGER(THIS),
                                        INTEGER(STATUS) ) {
   GENPTR_INTEGER(THIS)
   F77_LOGICAL_TYPE(RESULT);

   astAt( "AST_ISAFLUXFRAME", NULL, 0 );
   astWatchSTATUS(
      RESULT = astIsAFluxFrame( astI2P( *THIS ) ) ? F77_TRUE : F77_FALSE;
   )
   return RESULT;
}

F77_INTEGER_FUNCTION(ast_fluxframe)( DOUBLE(SPECVAL),
                                     INTEGER(SPECFRM),
                                     CHARACTER(OPTIONS),
                                     INTEGER(STATUS)
                                     TRAIL(OPTIONS) ) {
   GENPTR_DOUBLE(SPECVAL)
   GENPTR_INTEGER(SPECFRM)
   GENPTR_CHARACTER(OPTIONS)
   F77_INTEGER_TYPE(RESULT);
   int i;
   char *options;

   astAt( "AST_FLUXFRAME", NULL, 0 );
   astWatchSTATUS(
      options = astString( OPTIONS, OPTIONS_length );

/* Change ',' to '\n' (see AST_SET in fobject.c for why). */
      if ( astOK ) {
         for ( i = 0; options[ i ]; i++ ) {
            if ( options[ i ] == ',' ) options[ i ] = '\n';
         }
      }
      RESULT = astP2I( astFluxFrame( *SPECVAL, astI2P( *SPECFRM ), "%s", options ) );
      astFree( options );
   )
   return RESULT;
}

