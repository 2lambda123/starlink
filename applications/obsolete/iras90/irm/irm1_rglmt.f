      SUBROUTINE IRM1_RGLMT( RNGSTR, RNGWRD, BERNG, BELG, EDRNG, EDLG,
     :                       STATUS )
*+
*  Name:
*     IRM1_RGLMT

*  Purpose:
*     Get the range limits of a range specification.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRM1_RGLMT( RNGSCT, RNGWRD, BERNG, BELG, EDRNG, EDLG,
*                      STATUS )

*  Description:
*     This routine returns begin and end limits of a range specified by
*     a range word.

*  Arguments:
*     RNGSTR = CHARACTER*(*) (Given)
*        String which specifies a range with the range word specified
*        by argument RNGWRD.
*     RNAWRD = CHARACTER*(*) (Given)
*        Gives a range word, such as "TO", "-", etc, which is used in
*        range specification.
*     BERNG = INTEGER (Returned)
*        Begin limit of the range.
*     BELG = LOGICAL (Returned)
*        If the begin limit of the range has been omitted. it equals
*        true, otherwise, false.
*     EDRNG = INTEGER (Returned)
*        End limit of the range.
*     EDLG = LOGICAL (Returned)
*        If the end limit of the range has been omitted, it equals true,
*        otherwise, false.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     WG: Wei Gong (IPMAF)
*     {enter_new_authors_here}

*  History:
*     9-JAN-1991 (WG):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER*(*) RNGSTR
      CHARACTER*(*) RNGWRD

*  Arguments Returned:
      INTEGER BERNG
      LOGICAL BELG
      INTEGER EDRNG
      LOGICAL EDLG

*  Status:
      INTEGER STATUS             ! Global status

*  External Reference:
      INTEGER CHR_LEN            ! Find used length of a string.

*  Local Variables:
      CHARACTER*(10) BERNGC      ! Begin number string of the range.
      CHARACTER*(10) EDRNGC      ! End number string of the range.
      INTEGER LNSCT              ! Used length of input string.
      INTEGER LNWRD              ! Length of the range word.
      CHARACTER*( 80 ) SCT       ! String which specifies the range
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If the string does not contain the range word specified by RNGWRD,
*  set status error and return.
      SCT = RNGSTR
      IF ( INDEX( SCT, RNGWRD ) .EQ. 0 ) THEN
         STATUS = SAI__ERROR
         GOTO 999
      END IF

*  Conver all lower-case letter in SCT to upper case.
      CALL CHR_UCASE( SCT )

*  Strip the leading bland of the string SCT.
      CALL CHR_LDBLK( SCT )

*  Get the used length of the string SCT.
      LNSCT = CHR_LEN( SCT )

*  Get the length of range word.
      LNWRD = CHR_LEN( RNGWRD )

*  Get the begin limit.
      IF( INDEX( SCT, RNGWRD ) .GT. 1 ) THEN
         BELG = .FALSE.
         BERNGC = SCT( : INDEX( SCT, RNGWRD ) - 1 )
         CALL CHR_CTOI( BERNGC, BERNG, STATUS )

*  Check, if error, exit.
         IF( STATUS .NE. SAI__OK ) GOTO 999

*  If begin limit is omitted, set its flag.
      ELSE
         BELG = .TRUE.
      END IF

*  Get the end limit.
      IF( INDEX( SCT, RNGWRD ) + LNWRD -1 .LT. LNSCT ) THEN
         EDLG = .FALSE.
         EDRNGC = SCT( INDEX( SCT, RNGWRD ) + LNWRD : )
         CALL CHR_CTOI( EDRNGC, EDRNG, STATUS )

*  Check, if error, exit.
         IF( STATUS .NE. SAI__OK ) GOTO 999

*  If end limit is omitted, set its flag.
      ELSE
         EDLG = .TRUE.
      END IF

 999  CONTINUE

      END
