      SUBROUTINE SST_HTMLP( INDENT, FIRST, LAST, STATUS )
*+
*  Name:
*     SST_HTMLP

*  Purpose:
*     Output the body of a section formatted in "paragraph" mode as
*     html.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SST_HTMLP( INDENT, FIRST, LAST, STATUS )

*  Description:
*     The routine sends all the lines in the body of a prologue section
*     formatted in paragraph mode to the output file as html source,
*     with indentation adjusted to the specified amount. The body of
*     the section is identified by its first and last line numbers in
*     the internal source code buffer. Relative indentation within the
*     section is preserved, but the "base" level is set by the routine
*     argument INDENT, which specifies the number of leading blanks to
*     be inserted. Output indentation is further adjusted to reflect the
*     logical structure of the html produced (which may include
*     itemised lists, for instance).

*  Arguments:
*     INDENT = INTEGER (Given)
*        Level of indentation required.
*     FIRST = INTEGER (Given)
*        First line number.
*     LAST = INTEGER (Given)
*        Last line number.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     21-DEC-1989 (RFWS):
*        Original version.
*     5-DEC-1994 (PDRAPER):
*        Added double \ for UNIX port.
*     6-DEC-1994 (PDRAPER):
*        Converted to html format. Routine was SST_LATP.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'SST_PAR'          ! SST_ constants

*  Global Variables:
      INCLUDE 'SST_SCB'          ! SST_ Source Code Buffer

*  Arguments Given:
      INTEGER INDENT
      INTEGER FIRST
      INTEGER LAST

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER BASE               ! Base level of indentation
      INTEGER F                  ! First character of line to be output
      INTEGER I                  ! Loop counter for output lines
      INTEGER IND                ! Current output indentation
      LOGICAL ITEMS              ! Whether within an item list
      LOGICAL PREVBL             ! Previous output line was blank?

*  Internal References:
      LOGICAL BLANK              ! Whether line is blank
      INTEGER LINE               ! Dummy argument for BLANK
      BLANK( LINE ) = SCB_FC( LINE ) .GT. SCB_LC( LINE )

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the base level of input indentation and the current level
*  of output indentation.
      BASE = SST__SZLIN
      IND = INDENT

*  Find the minimum level of input indentation within the body of the
*  section.
      DO 1 I = FIRST, LAST
         IF ( .NOT. BLANK( I ) ) THEN
            BASE = MIN( BASE, SCB_FC( I ) )
         END IF
1     CONTINUE

*  Initialise flags indicating whether the previous line was blank and
*  whether we are within an itemised list.
      PREVBL = .TRUE.
      ITEMS = .FALSE.

*  Loop to output the lines in the section.  A blank input line simply
*  causes a blank output line (unless the previous line was also
*  blank).
      DO 2 I = FIRST, LAST
         IF ( BLANK( I ) ) THEN
            IF ( .NOT. PREVBL ) THEN
               CALL SST_PUT( 0, '<P>', STATUS )
               PREVBL = .TRUE.
            END IF

*  If the line begins with a '-', then this is the start of an item
*  within an itemised list. Start this list if it has not already been
*  started and increase the output indentation level.
         ELSE
            F = SCB_FC( I )
            IF ( ( SCB_LINE( I )( F : F ) .EQ. '-' ) ) THEN
               IF ( .NOT. ITEMS ) THEN
                  ITEMS = .TRUE.
                  CALL SST_PUT( IND, '<UL>', STATUS )
                  PREVBL = .FALSE.
                  IND = IND + 3
               END IF
               CALL SST_PUT( IND, '<LI>', STATUS )

*  Note where to start the line so as to skip the '-'.
               F = F + 1

*  If the next line is not blank and does not begin with '-', but the
*  previous line was blank, then this marks the end of any itemised
*  list.  Terminate the current itemised list if it exists.
            ELSE IF ( PREVBL .AND. ITEMS ) THEN
               ITEMS = .FALSE.
               IND = IND - 3
               CALL SST_PUT( IND, '</UL>', STATUS )
            END IF

*  Output lines with the base level of indentation adjusted to equal
*  IND.
            IF ( F .LE. SCB_LC( I ) ) THEN
               CALL SST_HTML( IND + SCB_FC( I ) - BASE,
     :                        SCB_LINE( I )( F : SCB_LC( I ) ), STATUS )
            END IF
            PREVBL = .FALSE.
         END IF
2     CONTINUE

*  Finally, terminate any current itemised list.
      IF ( ITEMS ) THEN
         CALL SST_PUT( IND - 3, '</UL>', STATUS )
      END IF

* @(#)sst_htmlp.f   1.6   95/03/06 10:56:46   96/07/05 10:27:33
      END
