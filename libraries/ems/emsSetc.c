/*+
 *  Name:
 *     emsSetc

 *  Purpose:
 *     Assign a CHARACTER value to a message token (concise).

 *  Language:
 *     Starlink ANSI C

 *  Invocation:
 *     emsSetc( token, cvalue )

 *  Description:
 *     This function sets the specified message token to the given string
 *     value, leading spaces are retained but trailing spaces removed.
 *     The string will be truncated to EMS__SZTOK characters if not null-
 *     terminated earlier.
 *     A null or blank string will be rendered as a token of one space.
 *     A Fortran interface EMS_SETC is also provided.

 *  Arguments:
 *     token = const char * (Given)
 *        The message token name.
 *     cvalue = const char * (Given)
 *        The CHARACTER value to be assigned to the message token.
 *
 *     For historical reasons, the following optional third argument may
 *     be given - in former versions of the function it could be used to
 *     restrict the size of the token, particularly if the given string
 *     was not null-terminated. It is no longer used - if restriction is
 *     required, function emsSetnc should be used instead.
 *
 *     maxchar = int (Given)
 *        The maximum desired length of the token.

 *  Authors:
 *     PCTR: P.C.T. Rees (STARLINK)
 *     AJC: A.J. Chipperfield (STARLINK)
 *     RTP: R.T.Platon (STARLINK)
 *     {enter_new_authors_here}

 *  History:
 *     6-JUN-1990 (PCTR):
 *        Original version, coded as a C macro function.
 *     10-AUG-1990 (PCTR):
 *        C function code.
 *     21-JUN-1991 (PCTR):
 *        Made all given character strings type "const".
 *     13-MAY-1999 (AJC):
 *        Renamed from ems_setc_c
 *     14-FEB-2001 (RTP):
 *        Rewritten from the Fortran routine EMS_SETC
 *     13-MAR-2001 (AJC):
 *        Properly import strings and make maxlen argument optional.
 *     20-SEP-2001 (AJC):
 *        Restrict string length to EMS__SZTOK
 *     {enter_further_changes_here}

 *  Bugs:
 *     {note_any_bugs_here}

 *-
 */

/* Include Statements: */
#include <string.h>                    /* String handling library functions */
#include "ems_par.h"                   /* ems_ public constant definitions */
#include "ems_sys.h"                   /* ems_ private macro definitions */
#include "ems.h"                       /* ems_ function prototypes */
#include "ems1.h"                      /* ems_ internal function prototypes */

/* Function Definitons: */
void emsSetc( const char *token, const char *cvalue, ... ){
   
   int vallen;
   int i;
   char valbuf[ EMS__SZTOK + 1 ];

   TRACE("emsSetc");
   DEBUG("emsSetc", "emsSetc: '%s'", token);

/*  Find the used length of the string */
   strncpy( valbuf, cvalue, EMS__SZTOK );
   valbuf[EMS__SZTOK] = '\0';

   for ( i=strlen(valbuf); i>0 ; i-- ) {
      if ( cvalue[ i-1 ] != ' ' ) break;
   }
   valbuf[i] = '\0';

/*  Ensure minimum one space */
   if ( !i ) {
      strcpy( valbuf, " " );
   }

/*  Set the token value. */
   ems1Stok( token, valbuf );
 
   return;

}
