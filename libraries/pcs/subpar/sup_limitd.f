      SUBROUTINE SUBPAR_LIMITD ( NAMECODE, VALUE, ACCEPTED, STATUS )
*+
*  Name:
*     SUBPAR_LIMITD

*  Purpose:
*     Checks a value against a parameter's constraints.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SUBPAR_LIMITD ( NAMECODE, VALUE, ACCEPTED, STATUS )

*  Description:
*     The given value is checked against the declared constraints on the
*     indicated parameter, and the logical variable ACCEPTED set to
*     indicate whether the constraints are violated.

*  Arguments:
*     NAMECODE=INTEGER (given)
*        pointer to parameter
*     VALUE=DOUBLE PRECISION (given)
*        value to be tested against the range or set constraints
*     ACCEPTED=LOGICAL (returned)
*        returned as .TRUE. unless the value violates any given
*        constraints
*     STATUS=INTEGER
*        Returned as SUBPAR__OUTRANGE if any constraint is violated.

*  Algorithm:
*     If there are no constraints on the parameter, ACCEPTED = .TRUE.
*     otherwise, if a range is specified check against the range, or
*     if a set is specified, compare with each value.

*  Authors:
*     BDK: B D Kelly (ROE)
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*     01-OCT-1984 (BDK):
*        Original
*     26-JUL-1991 (AJC):
*        Report failures
*     24-SEP-1991 (AJC):
*        Prefix messages with 'SUBPAR:'
*     09-OCT-1991 (AJC):
*        Use correct type/list in error message
*      1-MAR-1993 (AJC):
*        Add INCLUDE DAT_PAR
*     10-MAR-1993 (AJC):
*        Revise for MIN/MAX 
*     31-OCT-1994 (AJC):
*        Set STATUS on 'one of a set' failure.
*        Improve error report
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'SUBPAR_PAR'
      INCLUDE 'SUBPAR_ERR'

*  Arguments Given:
      INTEGER NAMECODE                   ! pointer to parameter

      DOUBLE PRECISION VALUE             ! value to be tested against
                                         ! the range or set constraints

*  Arguments Returned:
      LOGICAL ACCEPTED                   ! .TRUE. unless the value
                                         ! violates any given
                                         ! constraints

*  Status:
      INTEGER STATUS

*  Global Variables:
      INCLUDE 'SUBPAR_CMN'

*  Local Variables:
      INTEGER J                          ! loop counter
*.
      IF ( STATUS .NE. SAI__OK ) RETURN

*   Initialise ACCEPTED flag
       ACCEPTED = .FALSE.

*   Check if there is a 'one of a set' constraint.
      IF (( PARLIMS(3,NAMECODE) .EQ. SUBPAR__DOUBLE ) .AND.
     :      .NOT. PARCONT(NAMECODE) ) THEN

*      There is - apply it
         DO J = PARLIMS(1,NAMECODE), PARLIMS(2,NAMECODE)
            IF ( VALUE .EQ. DOUBLELIST(J) ) THEN
               ACCEPTED = .TRUE.
            ENDIF
         ENDDO

*      If value was not in set, report problem
         IF ( .NOT. ACCEPTED ) THEN
            STATUS = SUBPAR__OUTRANGE
            CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
            CALL EMS_SETD( 'VAL', VALUE )
            CALL EMS_REP ( 'SUP_LIMIT1', 'SUBPAR: '//
     :      'Value ^VAL is not in the allowed set for ' //
     :      'parameter ^NAME.', STATUS )
            CALL EMS_SETD( 'VALS', DOUBLELIST(PARLIMS(1,NAMECODE)) )
            IF ( PARLIMS(2,NAMECODE) .GT. PARLIMS(1,NAMECODE) ) THEN
               DO J = PARLIMS(1,NAMECODE)+1, PARLIMS(2,NAMECODE)
                  CALL EMS_SETC( 'VALS', ',' )
                  CALL EMS_SETC( 'VALS', ' ' )
                  CALL EMS_SETD( 'VALS', DOUBLELIST(J) )
               ENDDO
            END IF
            CALL EMS_REP( 'SUP_LIMIT2', '  Allowed set is: ^VALS', 
     :       STATUS )
         ENDIF

      ELSE
*      If there is a constraint, it is a range or MIN/MAX
         CALL SUBPAR_RANGED( NAMECODE, VALUE, .TRUE.,
     :                       ACCEPTED, STATUS )

      ENDIF

      IF ( STATUS .NE. SAI__OK ) THEN
         CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
         CALL EMS_REP( 'SUP_LIMIT3', 
     :   'SUBPAR: Failed constraints check for parameter ^NAME', 
     :    STATUS )
      END IF

      END
