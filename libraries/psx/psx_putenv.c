/*
 *+
 *  Name:
 *    PSX_PUTENV

 *  Purpose:
 *    Set a new environment variable value

 *  Invocation:
 *    CALL PSX_PUTENV( NAME, VALUE, STATUS )

 *  Description:
 *    The routine sets the specified environment variable to the 
 *    supplied value. If it fails it sets STATUS to SAI__ERROR.

 *  Arguments:
 *     NAME = CHARACTER * ( * ) (Given)
 *        Name of the environment variable to be modified
 *     VALUE = CHARACTER * ( * ) (Given)
 *        The new value of the environment variable.
 *     STATUS = INTEGER (Given and Returned)
 *        The global status.

 *  Examples:
 *    CALL PSX_PUTENV( 'DATADIR', DIR, STATUS )
 *       Set the DATADIR environment variable to the value stored
 *       in the DIR character string.

 *  External Routines Used:
 *    cnf: cndCreim, cnfFree

 *  References:
 *    POSIX
 *    SVID 3
 *    BSD 4.3

 *  Copyright:
 *    Copyright (C) 2003 Particle Physics and Astronomy Research Council

 *  Authors:
 *    TIMJ: Tim Jenness (JAC, Hilo)
 *    AJC: Alan Chipperfield (Starlink)

 *  History
 *    04-MAR-2003 (TIMJ):
 *      First version.
 *    10-APR-2003 (AJC):
 *      Cosmetic changes
 *      Improved error reporting - PSX status etc

 *  Notes:
 *    Uses the setenv() function where available. If setenv()
 *    is not available defaults to using the putenv() function.
 *    Use of putenv() will result in memory leaks since the putenv
 *    string is not freed by the system and can not be freed
 *    by the call to PSX_PUTENV. 

 *  CPP Flags:
 *    Recognizes the HAVE_SETENV CPP definition.

*/


#include <stdlib.h>
#include "sae_par.h"   /* SSE Constants */
#include "f77.h"       /* CNF macros and prototypes */
#include "psx_err.h"   /* PSX errors */
#include "psx1.h"	     /* Internal PSX routines		    */

F77_SUBROUTINE(psx_putenv)( CHARACTER(name),
			    CHARACTER(value),
			    INTEGER(status)
			    TRAIL(name)
			    TRAIL(value)
			    )
{

  /* Pointers to Arguments */
   GENPTR_CHARACTER(name)
   GENPTR_CHARACTER(trans)
   GENPTR_INTEGER(status)

  /* Local variables */
   char *temp_name;
   char *temp_value;
   char *envstr;
   char *oldstr;
   char errmsg[100];    /* Adequate space for constructed error message */ 
   int putstat;

  /* Check inherited global status. */
   if( *status != SAI__OK ) return;

  /* Import name into the C string temp_name. */
   temp_name = cnfCreim( name, name_length );
   temp_value = cnfCreim( value, value_length );
   if( ( temp_name!=NULL) && (temp_value!=NULL) ) {

# if defined( HAVE_SETENV )
      putstat = setenv(temp_name, temp_value, 1);

# else 
  /* If we have to use putenv we must worry about memory
     leaks. Currently ignore it. */

  /* First need to create a string buffer because the
     putenv routine requires   VARNAME=VALUE
     string */

  /* Allocate memory for environment string - this must not be freed
     whilst the variable is required */
  /* Include space for equals sign and trailing null */
  /* Assumes a character is one byte */
      envstr = malloc( strlen(temp_name) + strlen(temp_value) + 2);
 
  /* Copy in the string */
      strcpy( envstr, temp_name );
      strcat( envstr, "=");
      strcat( envstr, temp_value );

  /*  printf( "Temp value: %s --\n", temp_value);  */
  /* printf("Updating environment: %s --\n", envstr); */

  /* Update the environment */
      putstat = putenv( envstr );

  /* Note that we can not free the environment string since
     that is used directly by environ */

# endif

  /* Did not complete successfully */
      if ( putstat != 0 ) {
    /* Only documented error is ENOMEM */
         *status = PSX__NOMEM;
      }

  /* Free temp storage */
      cnfFree( temp_name );
      cnfFree( temp_value );
  
   } else {
  /* No memory for input arguments */
      *status = PSX__NOMEM;
   }
   
   if( *status != SAI__OK ) {
      strcpy( errmsg, "Error setting environment variable " );
      strcat( errmsg, name );
      psx1_rep_c( "PSX_PUTENV_NOENV", errmsg, status );
   }     

}
