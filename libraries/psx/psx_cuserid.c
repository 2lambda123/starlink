/* Subroutine:  psx_cuserid( user, status )
*+
*  Name:
*     PSX_CUSERID

*  Purpose:
*     Get the username

*  Language:
*     ANSI C

*  Invocation:
*     CALL PSX_CUSERID( USER, STATUS )

*  Description:
*     This routine will get a username associated with the effective
*     user ID of the current process. If the username cannot be found,
*     a blank string is returned.

*  Arguments:
*     NAME = CHARACTER * ( * ) (Returned)
*        The username
*     STATUS = INTEGER (Given)
*        The global status.

*  Notes:
*     -  On a Unix system the translation from effective user ID to
*        username is performed. Since there can be several usernames
*        associated with a user ID, there is no guarantee that the value
*        returned will be unique.
*     -  The Unix function cuserid is no longer in the IEEE 1003.1-1990
*        standard, so an alternative to this routine is used if available.
*        with getpwuid being preferred over getlogin over cuserid.
*     -  If the system call can not obtain a user ID, the value of LOGNAME
*        environment variable is returned as a last resort. And if that is
*        not there we use $USER. Only relevant currently if getenv() function
*        exists.
*     -  If the first attempt to get the username fails, one more attempt
*        is made. This overcomes an occasional (timing?) problem on Linux.
*
*     -  Under MinGW (Windows) the GetUserName function is used.

*  External Routines Used:
*     cnf: cnfExprt

*  References:
*     -  POSIX standard (1988), section 4.2.4
*     -  POSIX standard (1990), section B.4.2.4

*  Copyright:
*     Copyright (C) 1992 Science & Engineering Research Council

*  Authors:
*     PMA: Peter Allan (Starlink, RAL)
*     AJC: Alan Chipperfield (Starlink, RAL)
*     TIMJ: Tim Jenness (JAC)
*     PWD: Peter W. Draper (Starlink, Durham University)
*     {enter_new_authors_here}

*  History:
*     28-FEB-1991 (PMA):
*        Original version.
*     27-JUN-1991 (PMA):
*        Changed IMPORT and EXPORT macros to GENPTR.
*        Added workaround for bug in stdio.h file on the DECstation.
*     30-JUN-1992 (PMA):
*        Add inclusion of unistd.h for DEC OSF/1 as cuserid is no longer
*        in the IEEE 1003.1-1990 standard.
*     14-APR-1993 (PMA):
*        Change the test of whether or not to include the file
*        unistd.h to use my own macro _needs_cuserid.
*     16-JUN-2000 (AJC):
*        Trap NULL pointer returned by cuserid - try twice to overcome known
*        occasional problem on Linux. On second failure return a null string
*        for inter-platform consistency
*     23-JUN-2000 (AJC):
*        Tidy refs to CNF routines
*      9-JAN-2002 (AJC):
*        #define cuserid directly if defined _needs_cuserid
*        (formerly #included <unistd.h> but that didn't define it).
*     22-APR-2004 (TIMJ):
*        Use configure to decide which low level routine to use to obtain
*        the userid. Prefer getpwuid over getlogin over cuserid.
*        Use LOGNAME and USER env vars if we can not get a value.
*     20-JUL-2004 (PWD):
*        Add check for GetUserName function. This is the equivalent
*        for Windows and MinGW. Should only try to use this when all others
*        have failed.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
------------------------------------------------------------------------------
*/


/* Global Constants:							    */

#include <config.h>
#include <stdlib.h>
#include <stdio.h>		 /* Standard I/O routines		    */
#include "f77.h"		 /* C - Fortran interface		    */
#include "sae_par.h"		 /* ADAM constants			    */

/* Prefer getpwuid */

#if HAVE_GETPWUID && HAVE_GETEUID
#   define USE_GETPWUID
#   include <pwd.h>
#   include <unistd.h>
#   include <sys/types.h>
#else
#  if HAVE_GETLOGIN
#     define USE_GETLOGIN
#     include <unistd.h>
#  else
#     if HAVE_CUSERID
#        define USE_CUSERID
#        if !HAVE_DECL_CUSERID
            /* cuserid is no longer in 1003.1-1990 */
extern char *cuserid( const char *);
#        endif
#     else
         /* We may be trying to build under MinGW, in which case we use the
            Windows function GetUserName */
#        if defined HAVE_DECL_GETUSERNAME && HAVE_DECL_GETUSERNAME
#           define USE_GETUSERNAME
#           include <windows.h>
#           define L_cuserid MAX_PATH
#        else
#           error "No supported cuserid equivalent on this system"
#        endif
#     endif
#  endif
#endif

F77_SUBROUTINE(psx_cuserid)( CHARACTER(user), INTEGER(status) TRAIL(user) )
{

/* Pointers to Arguments:						    */

   GENPTR_CHARACTER(user)
   GENPTR_INTEGER(status)

/* Local Variables:							    */

#ifdef USE_CUSERID
   char tempuser[L_cuserid];	 /* Array to hold username		    */
#else 
#ifdef USE_GETUSERNAME
   char tempuser[L_cuserid];	 /* Array to hold username		    */
   DWORD len = L_cuserid;        /* Maximum length of username */
#else
   char tempuser[2];             /* Array to hold defaulted string */
#endif
#endif
   char *p_tempuser = NULL;	 /* Return value of calling cuserid	    */
#ifdef USE_GETPWUID
   struct passwd * pw;
#endif


/* Check the inherited global status.					    */

   if( *status != SAI__OK ) return;

/* Get the username.							    */

/* Use getpwuid(geteuid) if we have it, else use getlogin, else use cuserid.
   Try using LOGNAME environment variable as last resort.
 */

#ifdef USE_GETPWUID
   pw = getpwuid( geteuid() );
   p_tempuser = pw->pw_name;
#endif

#ifdef USE_GETLOGIN
   p_tempuser = getlogin();
#endif

#ifdef USE_CUSERID
/* Try twice with cuserid since on some linux system uses NIS+ there
   can be a delay which will cause an initial failure */
   p_tempuser = cuserid( tempuser );
   if ( p_tempuser == NULL ) {
      p_tempuser = cuserid( tempuser );
   }
#endif

#ifdef USE_GETUSERNAME
   /* Use Windows function when operating under MinGW */
   p_tempuser = tempuser;
   if ( ! GetUserName( tempuser, &len ) ) {
       p_tempuser = NULL;
   }
#endif

#if HAVE_GETENV
   /* Use LOGNAME then USER env var if we do not have a string */
   if (p_tempuser == NULL) {
     /* do not use PSX_GETENV since we only want to use a simple
	command without lots of temp char arrays */
     p_tempuser = getenv( "LOGNAME");
     if (p_tempuser == NULL) {
       p_tempuser = getenv( "USER" );
     }
   }
#endif

   /* Last gasp protection from NULL pointer */
   /* If we got a NULL value, just copy in empty string */
   if (p_tempuser == NULL ) {
     tempuser[0] = '\0';
     p_tempuser = tempuser;
   }

/* Export the username to the Fortran string user.
   if we have a value.
*/

   cnfExprt( p_tempuser, user, user_length );

}
