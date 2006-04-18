      SUBROUTINE PAR_MIXVI( PARAM, MAXVAL, VMIN, VMAX, OPTS, VALUES,
     :                        ACTVAL, STATUS )
 
*+
*  Name:
*     PAR_MIXVx
 
*  Purpose:
*     Obtains from a parameter character values from either a menu of
*     options or within a numeric range.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL PAR_MIXVx( PARAM, MAXVAL, VMIN, VMAX, OPTS, VALUES, ACTVAL,
*                     STATUS )
 
*  Description:
*     This routine obtains a vector of character values from a
*     parameter.  Each value must be either:
 
*        o  one of a supplied list of acceptable values, with
*           unambiguous abbreviations accepted; or
 
*        o  a numeric character string equivalent to a number, and the
*           number must lie within a supplied range of acceptable
*           values.
 
*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The name of the parameter.
*     MAXVAL = INTEGER (Given)
*        The maximum number of values required.  A PAR__ERROR status is
*        returned when the number of values requested is less than one.
*     VMIN = ? (Given)
*        The value immediately above a range wherein the obtained
*        numeric values cannot lie.  Thus if VMAX is greater than VMIN,
*        VMIN is the minimum numeric value allowed for the obtained
*        values.  However, should VMAX be less than VMIN, all numeric
*        values are acceptable except those between VMAX and VMIN
*        exclusive.
*     VMAX = ? (Given)
*        The value immediately below a range wherein the obtained
*        numeric values cannot lie.  Thus if VMAX is greater than VMIN,
*        VMAX is the maximum numeric value allowed for the obtained
*        values.  However, should VMAX be less than VMIN, all numeric
*        values are acceptable except those between VMAX and VMIN
*        exclusive.
*     OPTS = CHARACTER * ( * ) (Given)
*        The list of acceptable options for each value obtained from the
*        parameter.  Items should be separated by commas.  The list is
*        case-insensitive.
*     VALUES( MAXVAL ) = CHARACTER * ( * ) (Returned)
*        The selected values that are either options from the list or
*        the character form of numeric values that satisfy the range
*        constraint.  The former values are in uppercase and in full,
*        even if an abbreviation has been given for the actual
*        parameter.  Note that all values must satisfy the constraints.
*        The values will only be valid if STATUS is not set to an error
*        value.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for each of the data types double precision,
*     integer, and real: replace "x" in the routine name by D, I, or R
*     respectively as appropriate.  The VMIN and VMAX arguments must
*     have the corresponding data type.
*     -  There are two stages to identify or validate each character
*     value obtained from the parameter.
*
*     In the first the value is converted to the data type specified by
*     the "x" in the routine name.  If this is successful, the derived
*     numeric value is compared with the range of acceptable values
*     defined by VMIN and VMAX.  A value satisfying these constraints
*     is returned in the VALUES.
 
*     The second stage searches for a match of the character value with
*     an item in the menu.  This step adheres to the following rules.
*        o  The value is converted to the data type specified by the
*        "x" in the routine name.  If this is successful, the numeric
*        value is compared with the range of acceptable values defined
*        by VMIN and VMAX.  A value satisfying these constraints is
*        returned and the matching process terminates.
*        o  All comparisons are performed in uppercase.  Leading blanks
*        are ignored.
*        o  A match is found when the value equals the full name of an
*        option.  This enables an option to be the prefix of another
*        item without it being regarded as ambiguous.  For example,
*        "10,100,200" would be an acceptable list of options.
*        o  If there is no exact match, an abbreviation is acceptable.
*        A comparison is made of the value with each option for the
*        number of characters in the value.  The option that best fits
*        the value is declared a match, subject to two provisos.
*        Firstly, there must be no more than one character different
*        between the value and the start of the option.  (This allows
*        for a mistyped character.)  Secondly, there must be only one
*        best-fitting option.  Whenever these criteria are not
*        satisfied, the user is told of the error, and is presented
*        with the list of options, before being prompted for new
*        values.  This is not achieved through the MIN/MAX system.
*        If a nearest match is selected, the user is informed unless the 
*        MSG filtering level (see SUN/104) is 'quiet'.
*
*     This routine exits when all the values satisfy the criteria.
 
*  Algorithm:
*     -  If a non-positive number of values is given then report the
*     error and exit.
*     -  Find whether an inclusion or exclusion range constraint is
*     requested.
*     -  Obtain the values of the parameter.  Loop until acceptable
*     values are obtained or an error condition exists.  Acceptable
*     means that if a value is numeric, the number lies within the
*     range constraints, or failing that criterion, that a value is in
*     the menu and an unambiguous selection was given.  Report a
*     contextual error message and prompt for another value if any
*     of the values is unacceptable.
 
*  Copyright:
*     Copyright (C) 1991, 1992 Science & Engineering Research Council.
*     Copyright (C) 1999 Central Laboratory of the Research Councils.
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
*     AJC: Alan J. Chipperfield  (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1991 February 2 (MJC):
*        Original based on PAR_MIX0x.
*     1992 November 18 (MJC):
*        Permitted the limits to be reversed in order to specify an
*        exclusion range.  Allowed the menu to have numeric options.
*        Removed the restrictions on the number and length of the
*        options.
*     1999 September 20 (AJC):
*        Warn in MSG__NORM mode if nearest match adopted.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE            ! Switch off default typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'        ! Environment constants
      INCLUDE 'PAR_ERR'        ! Parameter-system error constants
      INCLUDE 'MSG_PAR'        ! Message-system constants
 
*  Arguments Given:
      CHARACTER * ( * )
     :  PARAM,                 ! Parameter name corresponding to
                               ! variable VALUES
     :  OPTS                   ! List of possible non-numeric options
                               ! for VALUES
 
      INTEGER
     :  VMIN,                  ! Minimum acceptable numeric value for
                               ! each value to be obtained
     :  VMAX                   ! Maximum acceptable numeric value for
                               ! each value to be obtained
 
      INTEGER
     :  MAXVAL                 ! Maximum number of values to obtain
 
*  Arguments Returned:
      CHARACTER * ( * )
     :  VALUES( MAXVAL )       ! Character array for which values are
                               ! to be obtained from the parameter
                               ! system
 
      INTEGER
     :  ACTVAL                 ! Number of values obtained
 
*  Status:
      INTEGER STATUS           ! Global status
 
*  Local Variables:
      LOGICAL                  ! True if:
     :  ALLOK,                 ! All values are acceptable
     :  EXCLUD,                ! The numeric range is an exclusion zone
     :  NOTOK,                 ! No acceptable value obtained
     :  NUMERC                 ! Supplied value is numeric
 
      INTEGER
     :  J,                     ! Loop counter
     :  NCV,                   ! Number of characters in the value
     :  PENALT                 ! Number of characters mismatched
 
      CHARACTER
     :  OPTION * ( 132 )       ! The selected option from the menu
 
 
      INTEGER
     :  VAL                    ! A value obtained if the input is
                               ! numeric
 
*.
 
*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Ensure the number of values needed is positive.
      IF ( MAXVAL .LT. 1 ) THEN
 
*  Too few values requested.
 
         STATUS = PAR__ERROR
         CALL MSG_SETC( 'PARAM', PARAM )
         CALL ERR_REP( 'PAR_MIXVx_TOOFEW',
     :     'A non-positive number of values was requested for '/
     :     /'parameter ^PARAM. (Probable programming error.)', STATUS )
 
*  Exit the routine.
         GOTO 999
 
      END IF
 
*  Find whether the range is inclusive or exclusive depending on the
*  polarity of the two values.
      EXCLUD = VMIN .GT. VMAX
 
*  Start a new error context.
      CALL ERR_MARK
 
*  Obtain the values of the parameter.
*  ===================================
*
*  Initialise ALLOK to start off the loop.
      ALLOK = .FALSE.
 
*  Repeat until an acceptable value is obtained or an error occurs.
  140 CONTINUE
         IF ( ALLOK .OR. ( STATUS .NE. SAI__OK ) ) GOTO 200
 
*  Get up to MAXVAL values from the parameter system.
         CALL PAR_GETVC( PARAM, MAXVAL, VALUES, ACTVAL, STATUS )
 
*  Check for an error.
         IF ( STATUS .EQ. SAI__OK ) THEN
 
*  Check if we have acceptable values.
*  =====================================
 
*  Assume that all values are now acceptable until shown otherwise.
            ALLOK = .TRUE.
 
*  Loop for each value obtained.
            DO 190 J = 1, ACTVAL
 
*  Start a new error context.
               CALL ERR_MARK
 
*  Find whether the value is numeric or not.  Try to convert the
*  dynamic default to the numeric data type.  If it fails the bad
*  status must be annulled, and there is still no suggested default.
               CALL CHR_CTOI( VALUES( J ), VAL, STATUS )
               IF ( STATUS .NE. SAI__OK ) THEN
                  CALL ERR_ANNUL( STATUS )
                  NUMERC = .FALSE.
 
*  Set the flag to indicate that the value is not acceptable yet.
                  NOTOK = .TRUE.
               ELSE
 
*  The value is numeric.  Determine whether or not it satisifies the
*  range constraint.
                  NUMERC = .TRUE.
                  IF ( EXCLUD ) THEN
                     NOTOK = ( VAL .LT. VMIN ) .AND. ( VAL .GT. VMAX )
                  ELSE
                     NOTOK = ( VAL .LT. VMIN ) .OR. ( VAL .GT. VMAX )
                  END IF
 
               END IF
 
*  Release the error context.
               CALL ERR_RLSE
 
*  Test if we already have the required value.
               IF ( NOTOK ) THEN
 
*  Permit one mistyped character in the value.
                  CALL PAR1_MENU( VALUES( J ), OPTS, ',', 1, OPTION,
     :                            NCV, PENALT, STATUS )
 
*  The value is not within the constraints, so make error reports
*  including full information using tokens.
                  IF ( STATUS .NE. SAI__OK ) THEN
 
*  Record that at least one value is not valid.
                     ALLOK = .FALSE.
 
*  Give details of the range limits for a numeric value.
                     IF ( NUMERC ) THEN
                        CALL MSG_SETC( 'PARAM', PARAM )
                        CALL MSG_SETC( 'VALUE', VALUES( J ) )
                        CALL MSG_SETI( 'MIN', VMIN )
                        CALL MSG_SETI( 'MAX', VMAX )
                        IF ( EXCLUD ) THEN
                           CALL MSG_SETC( 'XCLD', 'outside' )
                        ELSE
                           CALL MSG_SETC( 'XCLD', 'in' )
                        END IF
 
                        CALL ERR_REP( 'PAR_MIXVx_OUTR',
     :                    '^VALUE is outside the allowed range for '/
     :                    /'parameter ^PARAM.  Please give a value '/
     :                    /'^XCLD the numeric range ^MIN to ^MAX, or '/
     :                    /'an option from the menu.', STATUS )
                     END IF
 
*  Make a contextual error report.
                     CALL MSG_SETC( 'PARAM', PARAM )
                     CALL ERR_REP( 'PAR_MIXVx_INVOPT',
     :                 'Invalid selection for parameter ^PARAM.',
     :                 STATUS )
 
*  Note that the error is flushed immediately as we are in a loop.
                     CALL ERR_FLUSH( STATUS )
 
*  Try again to obtain the value, so we must cancel the incorrect
*  attempt.
                     CALL PAR_CANCL( PARAM, STATUS )
 
*  A valid option was chosen.  We can exit the loop when all values
*  have been validated.
                  ELSE
                     VALUES( J ) = OPTION( :NCV )
                     NOTOK = J .LT. ACTVAL
 
*  Warn the user that the nearest match was used.
                     IF ( PENALT .NE. 0 ) THEN
                        CALL MSG_SETC( 'VAL', VALUES( J ) )
                        CALL MSG_SETI( 'I', J )
                        CALL MSG_SETC( 'PARAM', PARAM )
                        CALL MSG_OUTIF( MSG__NORM, 'PAR_MIXVX_MISMAT',
     :                    'Selected the nearest match "^VAL" for '/
     :                    /'value number ^I of parameter ^PARAM.',
     :                    STATUS )
                     END IF
                  END IF
               END IF
 
*  End of the loop to validate the values.
  190       CONTINUE
         END IF
 
*  Go to the head of the loop.
         GOTO 140
 
*  Come here when the main loop has been exited.
  200 CONTINUE
 
*  Release the new error context.
      CALL ERR_RLSE
 
  999 CONTINUE
 
      END
