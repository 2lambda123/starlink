/*
*+
*  Name:
*     UTIL_RENAME

*  Purpose:
*     Rename a file

*  Language:
*     Starlink ANSI C

*  Invocation:
*     CALL UTIL_RENAME( INFIL, OUTFIL, STATUS )

*  Description:
*     Provides a Fortran interface to rename files. The file with the
*     name specified by the first argument is renamed to the second
*     name.

*  Arguments:
*     INFIL = CHARACTER*(*) (given)
*        The name of the file to rename
*     OUTFIL = CHARACTER*(*) (given)
*        The new name of the file 
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  {machine}-specific features used:
*     {routine_machine_specifics}...

*  References:
*     util Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/util.html

*  Keywords:
*     package:util, usage:public

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     AJC: Alan J. Chipperfield (Starlink, RAL)
*     {enter_new_authors_here}

*  History:
*     22 Jan 1993 (RDS):
*        Original version.
*     14 Dec 1993 (DJA):
*        Error handling improved.
*      5-Dec-2001 (AJC):
*        New form of EMS and CNF routine name
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*/
      
/*
 *  Include files
 */
#include "sae_par.h"
#include "f77.h"
#include "cnf.h"
#include "ems.h"          /* Error handling */
#include <errno.h>

/*
 * Prototype the rename function in VMS
 */
#if defined(VAX)
F77_INTEGER_FUNCTION(lib$rename_file)( CHARACTER(arg1), CHARACTER(arg2) 
                                       TRAIL(arg1) TRAIL(arg2) );
#endif



/*
 *  Body of code
 */
F77_SUBROUTINE(util_rename)( CHARACTER(infil), CHARACTER(outfil),
                             INTEGER(status) TRAIL(infil) TRAIL(outfil) )
  {
  GENPTR_CHARACTER(infil)
  GENPTR_CHARACTER(outfil)
  GENPTR_INTEGER(status)

  char          *instr, *outstr;	/* CNF temporary strings */
  int  		lstat;			/* Status from system routine */

/* Check inherited global stratus on entry */
  if ( *status != SAI__OK )
    return;

#if defined(VAX)
  lstat = F77_EXTERNAL_NAME(lib$rename_file)( CHARACTER_ARG(infil),
                  CHARACTER_ARG(outfil) 
                  TRAIL_ARG(infil) TRAIL_ARG(outfil) );

  if ( lstat != 1 ) {
    emsSyser( "REASON", lstat );
    *status = SAI__ERROR;
    }
#else

/* Import Fortran strings to C */
  instr = cnfCreim( infil, infil_length);
  outstr = cnfCreim( outfil, outfil_length);

/* Status renaming file */
  if ( rename(instr,outstr) ) {
    emsSyser( "REASON", errno );
    *status = SAI__ERROR;
    }

  if ( instr )				/* Free temporary strings */
    cnfFree( instr );
  if ( outstr )
    cnfFree( outstr );
#endif

/* Output message if rename failed */
  if ( *status != SAI__OK ) {
    emsSetnc( "INP", infil, infil_length );
    emsSetnc( "OUT", outfil, outfil_length );
    emsRep(" ","Rename of ^INP to ^OUT failed - ^REASON", status);
    }
  }
