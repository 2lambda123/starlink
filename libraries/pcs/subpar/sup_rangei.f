      SUBROUTINE SUBPAR_RANGEI( NAMECODE, VALUE, MNMX, OK, STATUS )
*+
*  Name:
*     SUBPAR_RANGEI

*  Purpose:
*     To test the given VALUE against any minimum or maximum values
*     for the parameter.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SUBPAR_RANGEI( NAMECODE, VALUE, MNMX, OK, STATUS )

*  Description:
*     STATUS has the normal effect on entry but cannot be set by
*     this routine.
*     The value is first checked against any RANGE values which have
*     been specified in the interface file.
*     If the value is within the RANGE and the MNMX argument is set
*     TRUE, the value is then tested against any MIN or MAX values set
*     for the parameter.
*     Argument OK is set FALSE, STATUS is set to SUBPAR_OUTRANGE and
*     an error report made if the value is outside the liimits, otherwise
*     OK is set to TRUE.
*     The minimum value is the value below which is excluded.
*     The maximum value is the value above which is excluded.
*     These definitions permit minimum > maximum. The effect of this
*     is to exclude values between the limits. The limits themselves
*     are always permitted.

*  Arguments:
*     NAMECODE = INTEGER (Given)
*        The parameter index of the parameter
*     VALUE = INTEGER (Given)
*        The value to be tested
*     MNMX = LOGICAL (Given)
*        Whether to use MIN and MAX values
*     OK = LOGICAL (Returned)
*        If VALUE is outside the limits, this returns FALSE,
*        otherwise TRUE.
*     STATUS = INTEGER (Given)
*        The global status.

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  Copyright:
*     Copyright (C) 1990, 1992, 1993, 1994 Science & Engineering Research Council.
*     Copyright (C) 1995 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}

*  History:
*      9-OCT-1990 (AJC):
*        Original version.
*     17-NOV-1992 (AJC):
*        Report if outside range
*        Check list pointer OK
*     10-MAR-1993 (AJC):
*        Add DAT_PAR for SUBPAR_CMN
*     11-JUN-1993 (AJC):
*        Allow exclusive limits
*      8-NOV-1994 (AJC):
*        Improve error reports
*     22-MAY-1995 (AJC):
*        Correct bug on EMS_REP call SUP_RANGE4
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'
      INCLUDE 'SUBPAR_PAR'       ! Parameter system constants
      INCLUDE 'SUBPAR_ERR'       ! Parameter system status values

*  Global Variables:
      INCLUDE 'SUBPAR_CMN'       ! SUBPAR common blocks
*        PARMIN( 2, SUBPAR__MAXPAR ) = INTEGER (Read)
*           Pointer and type of MIN value
*        PARMAX( 2, SUBPAR__MAXPAR ) = INTEGER (Read)
*           Pointer and type of MAX value
*        PARLIMS( 3, SUBPAR__MAXPAR ) = INTEGER (Read)
*           Pointers and type of contraints values
*        PARCONT( SUBPAR__MAXPAR ) = LOGICAL (Read)
*           Whether constraint is RANGE or IN.
*        INTLIST( SUBPAR__MAXLIMS ) = INTEGER (Read)
*           The actual limiting values.

*  Arguments Given:
      INTEGER NAMECODE
      INTEGER VALUE
      LOGICAL MNMX

*  Arguments Returned:
      LOGICAL OK

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER MINVAL                ! Lower value in RANGE
      INTEGER MAXVAL                ! Upper value in RANGE
      LOGICAL EXCLUSIVE          ! TRUE if range is exclusive
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Set default of acceptance
      OK = .TRUE.

*  First check value is within interface file RANGE
*  If there is a range, both values must be set although they can
*  (probably illegally) point to the same value
      IF ( ( PARLIMS(3,NAMECODE) .EQ. SUBPAR__INTEGER )
     :.AND. PARCONT(NAMECODE) ) THEN

*     Check against any RANGE values

*     Get min and max in right order
         IF ( INTLIST(PARLIMS(1,NAMECODE))
     :   .LE. INTLIST(PARLIMS(2,NAMECODE)) ) THEN
            EXCLUSIVE = .FALSE.
            MINVAL = INTLIST(PARLIMS(1,NAMECODE))
            MAXVAL = INTLIST(PARLIMS(2,NAMECODE))
            IF ( ( VALUE .LT. MINVAL )
     :      .OR. ( VALUE .GT. MAXVAL ) ) OK = .FALSE.

         ELSE
            EXCLUSIVE = .TRUE.
            MINVAL = INTLIST(PARLIMS(2,NAMECODE))
            MAXVAL = INTLIST(PARLIMS(1,NAMECODE))
            IF ( ( VALUE .GT. MINVAL )
     :      .AND.( VALUE .LT. MAXVAL ) ) OK = .FALSE.
         END IF

         IF ( .NOT. OK ) THEN
            STATUS = SUBPAR__OUTRANGE
            CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
            CALL EMS_SETI ( 'VAL', VALUE )
            CALL EMS_SETI ( 'L1',  MINVAL )
            CALL EMS_SETI ( 'L2',  MAXVAL )
            IF ( EXCLUSIVE ) THEN
               CALL EMS_REP ( 'SUP_RANGE1', 'SUBPAR: ' //
     :         '^VAL is in the excluded RANGE, between ^L1 ' //
     :         'and ^L2, for parameter ^NAME.', STATUS )
            ELSE
               CALL EMS_REP ( 'SUP_RANGE2', 'SUBPAR: ' //
     :         '^VAL is outside the permitted RANGE, ^L1 to '//
     :         '^L2, for parameter ^NAME.', STATUS )
            END IF

         END IF

      END IF

*  If there was no Interface File RANGE or the value was within RANGE
*  and MNMX is TRUE, check against any MIN/MAX values
      IF ( OK .AND. MNMX ) THEN

*     Find if it is an exclusive range
         EXCLUSIVE = .FALSE.
         IF ( ( PARMIN(2,NAMECODE) .EQ. SUBPAR__INTEGER )
     :   .AND. ( PARMIN(1,NAMECODE) .GT. 0 ) ) THEN
*        A minimum value is specified
*        Check if there is also a maximum
            IF ( ( PARMAX(2,NAMECODE) .EQ. SUBPAR__INTEGER )
     :      .AND. ( PARMAX(1,NAMECODE) .GT. 0 ) ) THEN
*           There is both a min and max - check if it's an exclusive range
               IF ( INTLIST(PARMAX(1,NAMECODE)) .LT.
     :              INTLIST(PARMIN(1,NAMECODE)) ) EXCLUSIVE = .TRUE.
            END IF
         END IF

*     Check against MIN value if any
         IF ( ( PARMIN(2,NAMECODE) .EQ. SUBPAR__INTEGER )
     :   .AND. ( PARMIN(1,NAMECODE) .GT. 0 ) ) THEN

            IF ( VALUE .LT. INTLIST(PARMIN(1,NAMECODE)) ) THEN

*           Unless exclusive and value also < or = MAX
               IF ( EXCLUSIVE ) THEN
                  IF ( VALUE .GT. INTLIST(PARMAX(1,NAMECODE)) ) THEN
*                 Error in exclusive min/max
                     OK = .FALSE.
                     STATUS = SUBPAR__OUTRANGE
                     CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
                     CALL EMS_SETI ( 'VAL', VALUE )
                     CALL EMS_SETI
     :                ( 'L1',  INTLIST(PARMIN(1,NAMECODE) ) )
                     CALL EMS_SETI
     :                ( 'L2',  INTLIST(PARMAX(1,NAMECODE) ) )
                     CALL EMS_REP ( 'SUP_RANGE3', 'SUBPAR: '//
     :               '^VAL is in the excluded MIN/MAX range, ' //
     :               'between ^L2 and ^L1, ' //
     :               'for parameter ^NAME.', STATUS )
                  END IF

               ELSE
                  OK = .FALSE.
                  STATUS = SUBPAR__OUTRANGE
                  CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
                  CALL EMS_SETI ( 'VAL', VALUE )
                  CALL EMS_SETI ( 'L1',  INTLIST(PARMIN(1,NAMECODE) ) )
                  CALL EMS_REP ( 'SUP_RANGE4', 'SUBPAR: '//
     :            '^VAL is less than the MINIMUM value, ^L1, '//
     :            'for parameter ^NAME.', STATUS )
               END IF
            END IF
         END IF

*     If still OK, check against MAX value if any
         IF ( OK .AND. ( PARMAX(2,NAMECODE) .EQ. SUBPAR__INTEGER )
     :   .AND. ( PARMAX(1,NAMECODE) .GT. 0 ) ) THEN

            IF ( VALUE .GT. INTLIST(PARMAX(1,NAMECODE)) ) THEN

*           It's an error unless exclusive and value also > or = MIN
               IF ( EXCLUSIVE ) THEN
                  IF ( VALUE .LT. INTLIST(PARMIN(1,NAMECODE)) ) THEN
*                 Error in exclusive min/max
                     OK = .FALSE.
                     STATUS = SUBPAR__OUTRANGE
                     CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
                     CALL EMS_SETI ( 'VAL', VALUE )
                     CALL EMS_SETI
     :                ( 'L1',  INTLIST(PARMIN(1,NAMECODE) ) )
                     CALL EMS_SETI
     :                ( 'L2',  INTLIST(PARMAX(1,NAMECODE) ) )
                     CALL EMS_REP ( 'SUP_RANGE5', 'SUBPAR: '//
     :               '^VAL is in the excluded MIN/MAX range, ' //
     :               'between ^L2 and ^L1, ' //
     :               'for parameter ^NAME.', STATUS )
                   END IF

               ELSE

                  OK = .FALSE.
                  STATUS = SUBPAR__OUTRANGE
                  CALL EMS_SETC ( 'NAME', PARKEY(NAMECODE) )
                  CALL EMS_SETI ( 'VAL', VALUE )
                  CALL EMS_SETI ( 'L1',  INTLIST(PARMAX(1,NAMECODE) ) )
                  CALL EMS_REP ( 'SUP_RANGE6', 'SUBPAR: '//
     :            '^VAL is greater than the MAXIMUM value, ' //
     :            '^L1, for parameter ^NAME.', STATUS )
               END IF
            END IF
         END IF
      ENDIF

      END
