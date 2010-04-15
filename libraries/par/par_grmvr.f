      SUBROUTINE PAR_GRMVR( PARAM, MAXVAL, VMIN, VMAX, VALUES,
     :                        ACTVAL, STATUS )

*+
*  Name:
*     PAR_GRMVx

*  Purpose:
*     Obtains from a parameter a vector of values each within a given
*     range.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL PAR_GRMVx( PARAM, MAXVAL, VMIN, VMAX, VALUES, ACTVAL,
*                     STATUS )

*  Description:
*     This routine obtains from a parameter up to a given number of
*     values.  Each value must be within its own range of acceptable
*     values supplied to the routine.

*     This routine is particularly useful for obtaining values that
*     apply to n-dimensional array where each value is constrained by
*     the size or bounds of the array, and where the number of values
*     need not equal n.  For example, the size of a smoothing kernel
*     could be defined by one value that applies to all dimensions, or
*     as individual sizes along each dimension.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The name of the parameter.
*     MAXVAL = INTEGER (Given)
*        The maximum number of values required.  A PAR__ERROR status is
*        returned when the number of values requested is less than one.
*     VMIN( MAXVAL ) = ? (Given)
*        The values immediately above a range wherein each obtained
*        value cannot lie.  Thus if VMAX is greater than VMIN, VMIN
*        is the minimum allowed for the corresponding obtained value.
*        However, should VMAX be less than VMIN, all values are
*        acceptable except those between VMAX and VMIN exclusive.
*     VMAX( MAXVAL ) = ? (Given)
*        The values immediately below a range wherein each obtained
*        value cannot lie.  Thus if VMAX is greater than VMIN, VMAX
*        is the maximum allowed for the corresponding obtained value.
*        However, should VMAX be less than VMIN, all values are
*        acceptable except those between VMAX and VMIN exclusive.
*     VALUES( MAXVAL ) = ? (Returned)
*        The values associated with the parameter.  They will only be
*        valid if STATUS is not set to an error value.
*     ACTVAL = INTEGER (Returned)
*        The actual number of values obtained.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  There is a routine for each of the data types double precision,
*     integer, and real: replace "x" in the routine name by D, I, or R
*     respectively as appropriate.  The VMIN, VMAX, and VALUES arguments
*     must have the corresponding data type.
*     -  Should too many values be obtained, the parameter system will
*     repeat the get in order to obtain a permitted number of values.
*     -  If any of the values violates the constraints, the user is
*     informed of the constraints and prompted for another vector of
*     values.  This is not achieved through the MIN/MAX system.

*  Algorithm:
*     -  If the number of values is not positive then report the error
*     and exit.
*     -  Loop until acceptable values are obtained or an error occurs.
*     Get up to the maximum number of values from the parameter system.
*     Test that each value supplied lies within within the acceptable
*     limits.  If they do not, report the fact and the limits.

*  Copyright:
*     Copyright (C) 1991, 1992 Science & Engineering Research Council.
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
*     MJC: Malcolm J. Currie  (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1991 November 27 (MJC):
*        Original based upon PAR_GDRV.
*     1992 November 18 (MJC):
*        Permitted the limits to be reversed in order to specify an
*        exclusion range.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE            ! Switch off default typing

*  Global Constants:
      INCLUDE 'SAE_PAR'        ! Environment constants
      INCLUDE 'PAR_ERR'        ! Parameter-system error constants

*  Arguments Given:
      CHARACTER * ( * )
     :  PARAM                  ! Parameter name associated with value
                               ! to be obtained
      INTEGER
     :  MAXVAL                 ! Maximum number of values to obtain

      REAL
     :  VMIN( MAXVAL ),        ! Minimum acceptable value for elements
                               ! of VALUES
     :  VMAX( MAXVAL )         ! Maximum acceptable value for elements
                               ! of VALUES

*  Arguments Returned:
      REAL
     :  VALUES( MAXVAL )       ! Values---only valid if STATUS does not
                               ! have an error

      INTEGER
     :  ACTVAL                 ! Number of values obtained

*  Status:
      INTEGER STATUS           ! Global status

*  Local Variables:
      LOGICAL                  ! True if:
     :  EXCLUD,                ! The range is an exclusion zone
     :  NOTOK                  ! Unacceptable values obtained

      INTEGER
     :  I                      ! Loop counter

*.

*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Ensure that the number of values needed is positive.
      IF ( MAXVAL .LT. 1 ) THEN

*  Report the error.
         STATUS = PAR__ERROR
         CALL MSG_SETC( 'PARAM', PARAM )

*  Too few values requested.
         CALL ERR_REP( 'PAR_GRMVx_TOOFEW',
     :     'A non-positive maximum number of values was requested for '/
     :     /'parameter ^PARAM. (Probable programming error.)', STATUS )

*  Exit the routine.
         GOTO 999

      END IF

*  Start a new error context.
      CALL ERR_MARK

*  Loop to obtain the values of the parameter.
*  ===========================================

*  Initialise NOTOK to start off the loop.
      NOTOK = .TRUE.

  120 CONTINUE

*  The loop will keep going as long as suitable values have not be
*  read and there is no error.
         IF ( .NOT. NOTOK .OR. ( STATUS .NE. SAI__OK ) ) GOTO 160

*  Get up to MAXVAL values from the parameter system.
         CALL PAR_GETVR( PARAM, MAXVAL, VALUES, ACTVAL, STATUS )

*  Check for an error.
         IF ( STATUS .EQ. SAI__OK ) THEN

*  Check that the values are within the specified range.
            DO 140 I = 1, ACTVAL

*  Test whether the current range is an include or exclude.
               EXCLUD = VMIN( I ) .GT. VMAX( I )

*  Check that the values are within the specified include or exclude
*  range.
               IF ( EXCLUD ) THEN
                  NOTOK = ( VALUES( I ) .LT. VMIN( I ) ) .AND.
     :                    ( VALUES( I ) .GT. VMAX( I ) )
               ELSE
                  NOTOK = ( VALUES( I ) .LT. VMIN( I ) ) .OR.
     :                    ( VALUES( I ) .GT. VMAX( I ) )
               END IF

*  The value is not within the constraints, so report as an error,
*  including full information using tokens.
               IF ( NOTOK ) THEN
                  STATUS = PAR__ERROR
                  CALL MSG_SETC( 'PARAM', PARAM )
                  CALL MSG_SETI( 'EN', I )
                  CALL MSG_SETR( 'MIN', VMIN( I ) )
                  CALL MSG_SETR( 'MAX', VMAX( I ) )
                  IF ( EXCLUD ) THEN
                     CALL MSG_SETC( 'XCLD', 'outside' )
                  ELSE
                     CALL MSG_SETC( 'XCLD', 'in' )
                  END IF

                  CALL ERR_REP( 'PAR_GRMVx_OUTR',
     :              'Value ^EN given is outside the allowed range for '/
     :              /'parameter ^PARAM.  Give a value ^XCLD the range '/
     :              /'^MIN to ^MAX please.', STATUS )
               END IF
  140       CONTINUE

*  Flush any errors as we are in loop, and they must be seen before the
*  re-attempt to read the values.
            IF ( STATUS .NE. SAI__OK ) THEN
               CALL ERR_FLUSH( STATUS )

*  Cancel the parameter to enable a retry to get all values within the
*  range.
               CALL PAR_CANCL( PARAM, STATUS )

*  Initialise NOTOK to loop for more values as one or more the current
*  values are out of range.
               NOTOK = .TRUE.
            ELSE

*  STATUS is OK, hence all values must be lie within their respective
*  permitted ranges so terminate the loop.
               NOTOK = .FALSE.
            END IF
         END IF

*  Go to the head of the main loop.
         GOTO 120

*  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

*  Come here when the main loop has been exited.
  160 CONTINUE

*  Release the new error context.
      CALL ERR_RLSE

  999 CONTINUE

      END
