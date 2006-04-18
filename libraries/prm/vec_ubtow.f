      SUBROUTINE VEC_UBTOW( BAD, N, ARGV, RESV, IERR, NERR, STATUS )
*+
*  Name:
*     VEC_UBTOW
 
*  Purpose:
*     Convert vectorised UNSIGNED BYTE values to WORD.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL VEC_UBTOW( BAD, N, ARGV, RESV, IERR, NERR, STATUS )
 
*  Description:
*     The routine performs type conversion on a vectorised array ARGV
*     of UNSIGNED BYTE values, converting them to the equivalent WORD
*     values.  If numerical errors occur, the value VAL__BADW is
*     returned in appropriate elements of the result array RESV and a
*     STATUS value is set.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether the argument values (ARGV) may be "bad".
*     N = INTEGER (Given)
*        The number of values to be processed.  If N is not positive
*        the routine returns with IERR and NERR set to zero, but
*        without converting any values.
*     ARGV( N ) = BYTE (Given)
*        A vectorised (1-dimensional) array containing the N UNSIGNED BYTE
*        values to be converted.
*     RESV( N ) = INTEGER * 2 (Returned)
*        A vectoried (1-dimensional) array with at least N elements to
*        receive the WORD results.  The value VAL__BADW will be
*        set in appropriate elements of RESV under error conditions.
*     IERR = INTEGER (Returned)
*        The index of the first input array element to generate a
*        numerical error.  Zero is returned if no errors occur.
*     NERR = INTEGER (Returned)
*        A count of the number of numerical errors which occur.
*     STATUS = INTEGER (Given & Returned)
*        This should be set to SAI__OK on entry, otherwise the routine
*        returns without action.  A STATUS value will be set by this
*        routine if any numerical errors occur.
 
*  Copyright:
*     Copyright (C) 1988, 1991, 1992 Science & Engineering Research Council.
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
*     R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     15-AUG-1988 (RFWS):
*        Original version.
*     28-OCT-1991 (RFWS):
*        Added LIB$REVERT call.
*     5-NOV-1991 (RFWS):
*        Converted to perform explicit bounds checks on the input
*        arguments in the interests of portability.
*     28-JAN-1992 (RFWS):
*        Temporarily removed adjustments to data limits to account for
*        rounding.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

      INCLUDE 'PRM_PAR'          ! PRM_ public constants

      INCLUDE 'PRM_ERR'          ! PRM_ error codes

 
*  Arguments Given:
      LOGICAL BAD                ! Bad data flag
      INTEGER N                  ! Number of elements to process
      BYTE ARGV( * )           ! Array of input values
 
*  Arguments Returned:
      INTEGER * 2 RESV( * )          ! Array of result values
      INTEGER IERR               ! Numerical error pointer
      INTEGER NERR               ! Numerical error count
 
*  Status:
      INTEGER STATUS             ! Error status
 
*  Local Variables:
      BYTE HI                  ! Upper bound on argument
      BYTE LO                  ! Lower bound on argument
      DOUBLE PRECISION DHI       ! Upper bound on data
      DOUBLE PRECISION DLO       ! Lower bound on data
      INTEGER I                  ! Loop counter
      LOGICAL FIRST              ! First invocation?
 
      SAVE FIRST
      SAVE HI
      SAVE LO
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declare NUM_ conversion functions

      INCLUDE 'NUM_DEC_UB'      ! Declare NUM_ arithmetic functions

      INCLUDE 'NUM_DEF_CVT'      ! Define NUM_ conversion functions

      INCLUDE 'NUM_DEF_UB'      ! Define NUM_ arithmetic functions

 
*  Local Data:
      DATA FIRST / .TRUE. /      ! First invocation
 
*.
 
*  Check status.
      IF( STATUS .NE. SAI__OK ) RETURN
 
*  If the conversion can potentially fail, then on the first invocation
*  set up the lower and upper bounds on the argument values.
      IF ( .FALSE. ) THEN
         IF ( FIRST ) THEN
 
*  Find the intersection of the ranges of allowed values between the
*  input and output data types. Perform this calculation in double
*  precision.
            DLO = MAX( NUM_UBTOD( NUM__MINUB ),
     :                 NUM_WTOD( NUM__MINW ) )
            DHI = MIN( NUM_UBTOD( NUM__MAXUB ),
     :                 NUM_WTOD( NUM__MAXW ) )
 
*  Adjust the resulting limits to allow for rounding of both the input
*  and output data types.
C            IF ( DLO .GT. 0.0D0 ) THEN
C               DLO = DLO - 0.5D0 * NUM_WTOD( VAL__EPSW )
C            ELSE
C               DLO = DLO - 0.5D0 * ( NUM_WTOD( VAL__EPSW ) -
C     :                               NUM_UBTOD( VAL__EPSUB ) )
C            END IF
C            IF ( DHI .GT. 0.0D0 ) THEN
C               DHI = DHI + 0.5D0 * ( NUM_WTOD( VAL__EPSW ) -
C     :                               NUM_UBTOD( VAL__EPSUB ) )
C            ELSE
C               DHI = DHI + 0.5D0 * NUM_WTOD( VAL__EPSW )
C            END IF
C
*  Convert the limits to the input data type and note they have been
*  set up.
            LO = NUM_DTOUB( DLO )
            HI = NUM_DTOUB( DHI )
            FIRST = .FALSE.
         END IF
      END IF
 
*  Initialise the numerical error pointer and the error count.
      IERR = 0
      NERR = 0
 
*  If the bad data flag is set:
*  ---------------------------
*  Loop to process each element of the input array in turn.
      IF( BAD ) THEN
         DO 1 I = 1, N
 
*  Check if the input value is bad.  If it is, then put a value of
*  VAL__BADW in the corresponding element of the result array.
            IF( ARGV( I ) .EQ. VAL__BADUB ) THEN
               RESV( I ) = VAL__BADW
 
*  If the conversion can potentially fail, then test if the argument
*  value lies within its allowed bounds.
            ELSE IF( ( .FALSE. ) .AND.
     :               ( NUM_LTUB( ARGV( I ), LO ) .OR.
     :                 NUM_GTUB( ARGV( I ), HI ) ) ) THEN
 
*  If not, then put a value of VAL__BADW in the corresponding
*  element of the result array, and increment the numerical error
*  count.
               RESV( I ) = VAL__BADW
               NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
               IF( STATUS .EQ. SAI__OK ) THEN
                  STATUS = SAI__OK
                  IERR = I
               END IF
 
*  If the input value is OK, perform type conversion.
            ELSE
               RESV( I ) = NUM_UBTOW( ARGV( I ) )
            END IF
 1       CONTINUE
 
*  If the bad data flag is not set:
*  -------------------------------
*  Loop to process each element of the input array in turn.
      ELSE
         DO 2 I = 1, N
 
*  If the conversion can potentially fail, then test if the argument
*  value lies within its allowed bounds.
            IF( ( .FALSE. ) .AND.
     :          ( NUM_LTUB( ARGV( I ), LO ) .OR.
     :            NUM_GTUB( ARGV( I ), HI ) ) ) THEN
 
*  If not, then put a value of VAL__BADW in the corresponding
*  element of the result array, and increment the numerical error
*  count.
               RESV( I ) = VAL__BADW
               NERR = NERR + 1
 
*  Set a STATUS value (if not already set) and update the error
*  pointer.
               IF( STATUS .EQ. SAI__OK ) THEN
                  STATUS = SAI__OK
                  IERR = I
               END IF
 
*  If the input argument is OK, then perform type conversion.
            ELSE
               RESV( I ) = NUM_UBTOW( ARGV( I ) )
            END IF
 2       CONTINUE
      END IF
 
*  Exit routine.
      END
