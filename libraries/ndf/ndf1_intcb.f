      SUBROUTINE NDF1_INTCB( STATUS )
*+
*  Name:
*     NDF1_INTCB

*  Purpose:
*     Initialise the NDF_ system Tuning Control Block.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_INTCB( STATUS )

*  Description:
*     The routine initialises values in the NDF_ system Tuning Control
*     Block (TCB) which affect the behaviour of the system as a whole.
*     It should be invoked before any of the values in the TCB are
*     used.

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     This routine will only execute once. If it is invoked again after
*     a previous successful invocation, it will return without further
*     action.

*  Copyright:
*     Copyright (C) 1993 Science & Engineering Research Council

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK, RAL)
*     {enter_new_authors_here}

*  History:
*     13-OCT-1993 (RFWS):
*        Original version.
*     4-MAY-1994 (RFWS):
*        Removed call to NDF1_TRACE to avoid possible recursion.
*     4-MAY-1994 (RFWS):
*        Only set tuning parameter values if the value read from an
*        environment variable is within the valid range for each
*        parameter.
*     11-MAR-1997 (RFWS):
*        Added NDF_DOCVT flag.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_CONST'        ! NDF_ private constants

*  Global Variables:
      INCLUDE 'NDF_TCB'          ! NDF_ Tuning Control Block
*        TCB_DOCVT = LOGICAL (Write)
*           Do format conversions flag.
*        TCB_ETFLG = LOGICAL (Write)
*           Error tracing flag.
*        TCB_FNFMT = INTEGER (Write)
*           Host operating system file name format code.
*        TCB_KEEP = LOGICAL (Write)
*           Keep NDF data objects flag.
*        TCB_SHCVT = LOGICAL (Write)
*           Show format conversions flag.
*        TCB_WARN = LOGICAL (Write)
*           Warning message flag.

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER * ( 1 ) DUM1     ! Dummy argument
      CHARACTER * ( 1 ) DUM2     ! Dummy argument
      CHARACTER * ( 1 ) DUM3     ! Dummy argument
      CHARACTER * ( 1 ) DUM4     ! Dummy argument
      CHARACTER * ( 30 ) SYSNAM  ! Name of operating system
      INTEGER IVAL               ! Integer environment variable value
      LOGICAL FIRST              ! First invocation of this routine?

      SAVE FIRST                 ! Remember if previously invoked

*  Local Data:
      DATA FIRST / .TRUE. /      ! Initially never invoked

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Check if this is the first invocation of this routine. Otherwise
*  there is nothing to do.
      IF ( FIRST ) THEN

*  Error tracing flag.
*  ==================
*  Read the error tracing flag value from its environment variable (if
*  present) and set the TCB flag accordingly.
         CALL NDF1_RDTUN( 'NDF_TRACE', 0, IVAL, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN
            TCB_ETFLG = ( IVAL .EQ. 1 )
         END IF

*  File name format.
*  ================
*  Obtain the name of the host operating system and convert it to upper
*  case.
         CALL PSX_UNAME( SYSNAM, DUM1, DUM2, DUM3, DUM4, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN
            CALL CHR_UCASE( SYSNAM )

*  Check to see whether we are running on VMS and must use VMS file
*  name format.
            IF ( INDEX( SYSNAM, 'VMS' ) .NE. 0 ) THEN
               TCB_FNFMT = NDF__VMS

*  If not, then assume POSIX file name format.
            ELSE
               TCB_FNFMT = NDF__POSIX
            END IF
         END IF

*  Do format conversions flag.
*  ==========================
*  Read the do format conversions flag value from its environment
*  variable (if present) and set the TCB flag accordingly.
         CALL NDF1_RDTUN( 'NDF_DOCVT', 1, IVAL, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN
            TCB_DOCVT = ( IVAL .NE. 0 )
         END IF
         
*  Keep NDF objects flag.
*  =====================
*  Read the keep NDF objects flag value from its environment variable
*  (if present) and set the TCB flag accordingly.
         CALL NDF1_RDTUN( 'NDF_KEEP', 0, IVAL, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN
            TCB_KEEP = ( IVAL .EQ. 1 )
         END IF
         
*  Show data conversions flag.
*  ==========================
*  Read the show data conversions flag value from its environment
*  variable (if present) and set the TCB flag accordingly.
         CALL NDF1_RDTUN( 'NDF_SHCVT', 0, IVAL, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN
            TCB_SHCVT = ( IVAL .EQ. 1 )
         END IF
         
*  Warning message flag.
*  ====================
*  Read the warning message flag value from its environment variable
*  (if present) and set the TCB flag accordingly.
         CALL NDF1_RDTUN( 'NDF_WARN', 0, IVAL, STATUS )
         IF ( STATUS .EQ. SAI__OK ) THEN
            TCB_WARN = ( IVAL .EQ. 1 )
         END IF
         
*  Note when the first successful invocation of this routine has
*  completed.
         IF ( STATUS .EQ. SAI__OK ) FIRST = .FALSE.
      END IF

*  Exit the routine (note we do not call the NDF1_TRACE error tracing
*  routine here, as this could result in recursion).
      END
