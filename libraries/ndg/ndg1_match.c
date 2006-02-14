#include <stdlib.h>
#include <fnmatch.h>
#include "f77.h"
#include "cnf.h"
#include "sae_par.h"

F77_LOGICAL_FUNCTION(ndg1_match)( CHARACTER(template), CHARACTER(test),
                                  INTEGER(status ) TRAIL(template) 
                                  TRAIL(test) ) {
/*
*  Routine:
*     NDG1_MATCH

*  Purpose:
*     See if a given string matches a wild-card template.

*  Language:
*     C, designed to be called from Fortran.

*  Invocation:
*     MATCH = NDG1_MATCH( TEMPLT, TEST, STATUS )

*  Description:
*     This routine returns .TRUE. if the supplied test string matches the
*     supplied wild-card template. Posix globbing is used.

*  Arguments:
*     TEMPLT = CHARACTER*(*) (Given)
*        The wild-card template. 
*     TEST = CHARACTER*(*) (Given)
*        The test string to be compared to the template.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Returned Value:
*     NDG1_MATCH = LOGICAL 
*        .TRUE. if the test string matches the template.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     28-FEB-2001 (DSB):
*        - First version.
*     20-SEP-2005 (TIMJ):
*        Update cnf usage. Use free not cnfFree to free temp storage.
*     13-FEB-2006 (TIMJ):
*        Use cnfFree again since this is easier to control when changing
*        malloc library.

*/
   GENPTR_CHARACTER(template) 
   GENPTR_CHARACTER(test) 
   GENPTR_INTEGER(status)


/* Local Variables */
   int match;             /* Does the test string match the template? */
   char *tmplt;           /* Local copy of template */
   char *tst;             /* Local copy of test */

/* Initialize */
   match = F77_FALSE;

/* Check the global status. */
   if( *status != SAI__OK ) return match;

/* Import the template string */
   tmplt = cnfCreim( template, template_length );

/* Import the test string */
   tst = cnfCreim( test, test_length );

/* Use the fnmatch posix routine to do the matching. */
   if( fnmatch( tmplt, tst, FNM_PERIOD ) ){
      match = F77_FALSE;
   } else {
      match = F77_TRUE;
   }

/* Free the memory used to hold local copies of the supplied strings */
   cnfFree( tmplt );
   cnfFree( tst );

/* Return the answer */
   return match;

}
