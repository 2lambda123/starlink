      SUBROUTINE IRA_CONVT( NVAL, AIN, BIN, SCSIN, SCSOUT, EPOCH, AOUT,
     :                      BOUT, STATUS )
*+
*  Name:
*     IRA_CONVT

*  Purpose:
*     Convert sky coordinates from one system to another.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRA_CONVT( NVAL, AIN, BIN, SCSIN, SCSOUT, EPOCH, AOUT, BOUT,
*                     STATUS )

*  Description:
*     This routine use SLALIB to convert a list of sky coordinates from
*     one supported Sky Coordinate System (SCS) to any other supported
*     system.  It is assumed that the observations were made at the
*     date given by the Julian epoch supplied.  If the input and output
*     coordinates are referred to different mean equinox, then
*     precession is applied to convert the input coordinates to the
*     output system.  No correction for nutation is included. If any of
*     the input coordinate values are equal to the Starlink "BAD" value
*     (VAL__BADD) then the corresponding output values will both be set
*     to the bad value.

*  Arguments:
*     NVAL = INTEGER (Given)
*        The number of sky coordinate pairs to be converted.
*     AIN( NVAL ) = DOUBLE PRECISION (Given)
*        A list of sky longitude coordinate values to be converted, in
*        radians.
*     BIN( NVAL ) = DOUBLE PRECISION (Given)
*        A list of sky latitude coordinate values to be converted, in
*        radians.
*     SCSIN = CHARACTER * ( * ) (Given)
*        A string holding the name of the sky coordinate system of the
*        input list. Any unambiguous abbreviation will do. An optional
*        equinox specifier may be included in the name (see ID2 section
*        "Sky Coordinates").
*     SCSOUT = CHARACTER * ( * ) (Given)
*        A string holding the name of the sky coordinate system
*        required for the output list. Any unambiguous abbreviation
*        will do.An optional equinox specifier may be included in the
*        name.
*     EPOCH = DOUBLE PRECISION (Given)
*        The Julian epoch at which the observations were made. When
*        dealing with IRAS data, the global constant IRA__IRJEP should
*        be specified. This constant is a Julian epoch suitable for all
*        IRAS data.
*     AOUT( NVAL ) = DOUBLE PRECISION (Returned)
*        The list of converted sky longitude coordinate values, in
*        radians.
*     BOUT( NVAL ) = DOUBLE PRECISION (Returned)
*        The list of converted sky latitude coordinate values, in
*        radians.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     14-JAN-1991 (DSB):
*        Original version.
*     26-APR-1991 (DSB):
*        Changed for second version of IRA
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT constants
      INCLUDE 'IRA_PAR'          ! IRA constants.

*  Arguments Given:
      INTEGER          NVAL
      DOUBLE PRECISION AIN( NVAL )
      DOUBLE PRECISION BIN( NVAL )
      CHARACTER        SCSIN*(*)
      CHARACTER        SCSOUT*(*)
      DOUBLE PRECISION EPOCH

*  Arguments Returned:
      DOUBLE PRECISION AOUT( NVAL )
      DOUBLE PRECISION BOUT( NVAL )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER BJI*1              ! The type of epoch (Besselian or
                                   ! Julian) held by variable EQUI.
      CHARACTER BJO*1              ! The type of epoch (Besselian or
                                   ! Julian) held by variable EQUO.
      DOUBLE PRECISION EQUI        ! The epoch of the reference equinox
                                   ! specified in argument SCSIN.
      DOUBLE PRECISION EQUO        ! The epoch of the reference equinox
                                   ! specified in argument SCSOUT.
      CHARACTER NAMEI*(IRA__SZSCS)! Full input SCS name with no
                                   ! equinox specifier.
      CHARACTER NAMEO*(IRA__SZSCS)! Full output SCS name with no
                                   ! equinox specifier.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Identify the input SCS.
      CALL IRA1_CHSCS( SCSIN, NAMEI, EQUI, BJI, STATUS )

*  Identify the output SCS.
      CALL IRA1_CHSCS( SCSOUT, NAMEO, EQUO, BJO, STATUS )
      IF( STATUS .NE. SAI__OK ) GO TO 999

*  Call IRA1_ICONV to do the work.
      CALL IRA1_ICONV( NVAL, AIN, BIN, NAMEI, EQUI, BJI, NAMEO, EQUO,
     :                 BJO, EPOCH, AOUT, BOUT, STATUS )

*  If an error occurred, give appropriate messages.
 999  CONTINUE

      IF ( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'IRA_CONVT_ERR1',
     :          'IRA_CONVT: Unable to convert a position from one '//
     :          'sky coordinate system to another.',
     :                 STATUS )
      END IF

      END
