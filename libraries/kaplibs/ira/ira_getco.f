      SUBROUTINE IRA_GETCO( APAR, BPAR, PRMAPP, SCS, DEFLT, A, B,
     :                      STATUS )
*+
*  Name:
*     IRA_GETCO

*  Purpose:
*     Obtain a pair of sky coordinates from the ADAM environment.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRA_GETCO( APAR, BPAR, PRMAPP, SCS, DEFLT, A, B, STATUS )

*  Description:
*     The ADAM parameters specified by arguments APAR and BPAR are used
*     to acquire values for the first and second sky coordinates
*     respectively, in the sky coordinate system specified by argument
*     SCS. The parameters are obtained as literal character strings and
*     decoded into floating point values. See routine IRA_CTOD for a
*     description of the allowed formats of the strings associated with
*     these parameters. The input values of arguments A and B can
*     optionally be supplied to the user as default parameter values.
*     The parameter prompt strings contained in the application's
*     interface file can be overridden by giving a non-blank value for
*     argument PRMAPP. In this case, the prompts are formed by
*     appending the value of PRMAPP to the coordinate descriptions
*     returned by routine IRA_SCNAM. For instance, if PRMAPP = " of the
*     field centre", and an equatorial sky coordinate system is in use,
*     then the prompt for APAR will be "Right Ascension of the field
*     centre", and the prompt for BPAR will be "Declination of the
*     field centre". Note, the total length of the prompt strings is
*     limited to 80 characters. If PRMAPP is blank, then the current
*     prompt strings are used (initially equal to the values in the
*     interface file).

*  Arguments:
*     CHARACTER = APAR (Given)
*        The name of the ADAM parameter (type LITERAL) to use
*        for the sky longitude value.
*     CHARACTER = BPAR (Given)
*        The name of the ADAM parameter (type LITERAL) to use
*        for the sky latitude value.
*     PRMAPP = CHARACTER * ( * ) (Given)
*        A string to append to each axis description to form the
*        parameter prompt strings. If this is blank then the current
*        prompt strings are used (i.e. initially set to the values in
*        the interface file).
*     SCS = CHARACTER * ( * ) (Given)
*        The name of the sky coordinate system to use. Any unambiguous
*        abbreviation will do (see ID2 section "Sky Coordinates").
*     DEFLT = LOGICAL (Given)
*        True if the input values of A and B are to be communicated to
*        the environment as run-time defaults for the parameters
*        specified by APAR and BPAR. If A or B is "BAD" on entry
*        (i.e. equal to VAL__BADD ) then no default is set up for the
*        corresponding parameter.
*     A = DOUBLE PRECISION (Given and Returned)
*        The value of the first sky coordinate. In radians.
*     B = DOUBLE PRECISION (Given and Returned)
*        The value of the second sky coordinate. In radians.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     23-JAN-1991 (DSB):
*        Original version.
*     26-APR-1991 (DSB):
*        Modified for IRA second version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT constants
      INCLUDE 'IRA_PAR'          ! IRA constants

*  Arguments Given:
      CHARACTER APAR*(*)
      CHARACTER BPAR*(*)
      CHARACTER PRMAPP*(*)
      CHARACTER SCS*(*)
      LOGICAL   DEFLT

*  Arguments Given and Returned:
      DOUBLE PRECISION A
      DOUBLE PRECISION B

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER ABB*(IRA__SZSCA)! Coordinate abbreviation.
      CHARACTER APRMPT*80        ! A prompt string.
      CHARACTER BJ*1             ! The type of epoch (Besselian or
                                 ! Julian) held by variable EQU.
      CHARACTER BPRMPT*80        ! B prompt string.
      DOUBLE PRECISION EQU       ! The epoch of the reference equinox
                                 ! specified in argument SCS.
      CHARACTER DESC*(IRA__SZSCD)! Coordinate description.
      INTEGER   LABB             ! No. of used characters in ABB.
      INTEGER   LDESC            ! No. of used characters in DESC.
      CHARACTER NAME*(IRA__SZSCS)! Full SCS name (with no equinox
                                  ! specifier).
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Identify the sky coordinate system.
      CALL IRA1_CHSCS( SCS, NAME, EQU, BJ, STATUS )

*  Set up the parameter prompt strings.
      IF( PRMAPP .NE. ' ' ) THEN
         CALL IRA1_ISCNM( SCS, 1, DESC, LDESC, ABB, LABB, STATUS )
         APRMPT = DESC(:LDESC)//PRMAPP

         CALL IRA1_ISCNM( SCS, 2, DESC, LDESC, ABB, LABB, STATUS )
         BPRMPT = DESC(:LDESC)//PRMAPP

      ELSE
         APRMPT = ' '
         BPRMPT = ' '

      END IF

*  If the input values are being used as defaults, shift them into the
*  first order ranges.
      IF( DEFLT ) CALL IRA_NORM( A, B, STATUS )

*  Get the first sky coordinate.
      CALL IRA1_IGTC1( APAR, APRMPT, NAME, 1, DEFLT, A, STATUS )

*  Get the second sky coordinate.
      CALL IRA1_IGTC1( BPAR, BPRMPT, NAME, 2, DEFLT, B, STATUS )

*  If an error occurred give the context.
 999  CONTINUE

      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'IRA_GETCO_ERR1',
     :                 'IRA_GETCO: Error obtaining a sky position',
     :                  STATUS )
      END IF

      END
