      SUBROUTINE POL1_SUBST( INSTR, OLD, NEW, ALL, OUTSTR, NSUB, 
     :                       STATUS )
*+
*  Name:
*     POL1_SUBST

*  Purpose:
*     Substitute one substring for another.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL POL1_SUBST( INSTR, OLD, NEW, ALL, OUTSTR, NSUB, STATUS )

*  Description:
*     This routine copies the input string to the output string,
*     replacing occurrences of a given substring with another given
*     string. The substitution is case sensitive.

*  Arguments:
*     INSTR = CHARACTER*(*) (Given)
*        The input string.
*     OLD = CHARACTER*(*) (Given)
*        The substring which is to be replaced. All blanks (including
*        trailing blanks) must be matched for a substitution to be made.
*     NEW = CHARACTER*(*) (Given)
*        The string which is to replace the substring specified by OLD.
*        NEW an OLD need not be the same length. Any trailing blanks
*        are included in the substitution.
*     ALL = LOGICAL (Given)
*        If true, then all occurrences of OLD will be replaced.
*        Otherwise, only the first occurrence will be replaced.
*     OUTSTR = CHARACTER*(*) (Returned)
*        The output string. A copy of INSTR, but with the required
*        substitutions made.
*     NSUB = INTEGER (Returned)
*        The number of substitutions actually made. If OUTSTR is filled
*        before the end of INSTR has been reached, then NSUB may be less
*        than the total number of occurrences of OLD within INSTR. If ALL
*        is false, then NSUB will always be less than or equal to one.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     6-JAN-1997 (DSB):
*        Original version (copied from iras90:irm_subst.f).
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER * ( * ) INSTR
      CHARACTER * ( * ) OLD
      CHARACTER * ( * ) NEW
      LOGICAL ALL

*  Arguments Returned:
      CHARACTER * ( * ) OUTSTR
      INTEGER NSUB

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER INLEN              ! Declared length of argument INSTR.
      LOGICAL MORE               ! .True. if further searches need to be
                                 ! made for the old substring.
      INTEGER NEWLEN             ! Declared length of argument NEW.
      INTEGER OLDLEN             ! Declared length of argument OLD.
      INTEGER OLDPOS             ! Index within the remaining part of
                                 ! INSTR at which the next occurrence of
                                 ! OLD starts.
      INTEGER OUTLEN             ! Declared length of argument OUTSTR.
      INTEGER OUTNXT             ! The index within OUTSTR at which the
                                 ! next character will be put.
      INTEGER START              ! The index within INSTR at which the
                                 ! search for the next occurrence of OLD
                                 ! will commence.

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Save the declared lengths of the strings and substrings.
      OUTLEN = LEN( OUTSTR )
      INLEN = LEN( INSTR )
      OLDLEN = LEN( OLD )
      NEWLEN = LEN( NEW )

*  Initialise things.
      START = 1
      NSUB = 0
      OUTNXT = 1
      MORE = .TRUE.

*  Start a "DO WHILE" loop.
 10   CONTINUE
      IF( MORE ) THEN

*  Find the start of the next occurrence of the old substring within the
*  remaining input string.
         OLDPOS = INDEX( INSTR( START : ), OLD )

*  If the old substring was found...
         IF( OLDPOS .GT. 0 ) THEN

*  Incremenent the number of times the old substring has been replaced.
            NSUB = NSUB + 1

*  ...copy the section of the input string which lies between this
*  occurrence of the old substring amd the previous occurrence, to the
*  end of the output string. If there was no gap between the two
*  occurrences, leave the output string as it is.
            IF( OLDPOS .GT. 1 ) THEN
               OUTSTR( OUTNXT :  ) = INSTR( START : START + OLDPOS - 2 )
               OUTNXT = OUTNXT + OLDPOS - 1

*  If the output string has been filled, return without further action.
               IF( OUTNXT .GT. OUTLEN ) GO TO 999

            END IF

*  Append the new substring to the end of the output string.
            OUTSTR( OUTNXT : ) = NEW
            OUTNXT = OUTNXT + NEWLEN

*  If the output string has been filled, return without further action.
            IF( OUTNXT .GT. OUTLEN ) GO TO 999

*  Update the position at which the search for the next occurrence of the
*  old substring within the input string will commence.
            START = START + OLDLEN + OLDPOS - 1

*  If the whole input string has been checked, flag that the job is
*  finished.
            IF( START .GT. INLEN ) MORE = .FALSE.

*  If the old substring was not found, copy the remainder of the input
*  string to the output string, and flag that the job is finished.
         ELSE
            OUTSTR( OUTNXT : ) = INSTR( START : )
            MORE = .FALSE.

         END IF

*  If only the first occurrence is to be replaced, copy the remainder of
*  the input string to the output string, and flag that the job is
*  finished.
         IF( .NOT. ALL ) then
            OUTSTR( OUTNXT : ) = INSTR( START : )
            MORE = .FALSE.

         END IF

*  End the "DO WHILE" loop.
         GO TO 10
      END IF

 999  CONTINUE

      END
