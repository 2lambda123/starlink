      SUBROUTINE KPG1_PSEED( STATUS )
*+
*  Name:
*     KPG1_PSEED

*  Purpose:
*     Set the PDA Random number seed.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_PSEED( STATUS )

*  Description:
*     This routine sets the seed for the PDA random number routines to a
*     non-repeatable value, and must be called prior to using any PDA 
*     random number routine. The seed is only set once in each process, 
*     and is set to a number which combines the process id and the 
*     current time.
*
*     The process id is included because the "time" system call 
*     (implemented by PSX_TIME) returns the time in seconds. On modern 
*     machines it is possible for an application to be called several times 
*     each second, resulting in the same seed being used each time if the 
*     seed is based only on the time.

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     7-JUL-1999 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER PID                ! Process id
      INTEGER SEED               ! Random-number seed
      INTEGER TICKS              ! Clock ticks to randomize initial seed

*  Ensure the seed is set to -1 at compile time.
      DATA SEED /-1/

*  Ensure the value of seed does not change between invocations of this
*  routine.
      SAVE SEED

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the seed has already been set do not change it.
      IF( SEED .EQ. -1 ) THEN

*  Get the current system time as a number of seconds since some starting
*  time.
         CALL PSX_TIME( TICKS, STATUS )

*  Get the process ID.
         CALL PSX_GETPID( PID, STATUS )

*  The intial seed is the sum of these.
         SEED = TICKS + PID

*  PDA requires that the seed be one more than a mutiple of 4. We will
*  therefore multiply the above seed by 4. To avoid the possibility of
*  integer overflow, first find the remainder on dividing the initial 
*  seed by a quarter of the maximum integer value.
         SEED = MOD( SEED, VAL__MAXI/4 )*4 + 1

*  In addition, PDA ignores seeds over 2**28 or below zero, using a
*  constant fixed seed instead. Ensure that the seed is betwen these
*  limits.
         SEED = MOD( SEED, 2**28 )

*  Set the seed.
         CALL PDA_RNSED( SEED )

      END IF

      END
