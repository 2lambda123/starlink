      SUBROUTINE KPG1_MONOD( BAD, EL, ARRAY, MONOTO, STATUS )
*+
*  Name:
*     KPG1_MONOx
 
*  Purpose:
*     Determines whether an array's values increase or decrease
*     monotonically.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_MONOx( BAD, EL, ARRAY, MONOTO, STATUS )
 
*  Description:
*     This routine determines whether or not a vector of values
*     increase or decrease monotonically.  This is most useful
*     for axes.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        If BAD=.TRUE., there may be bad values present in the
*        array, and it instructs this routine to test for the
*        presence of bad values.
*     EL = INTEGER (Given)
*        The number of elements in the array.
*     ARRAY( EL ) = ? (Given)
*        The array to be tested.
*     MONOTO = LOGICAL (Returned)
*        If MONOTO is .TRUE., the array values are monotonic.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for the each of the numeric data types.
*     replace "x" in the routine name by B, D, I, R, W, UB, or UB as
*     as appropriate.  The array should have the data type specified.
 
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1992 November 27 (MJC):
*        Original version.
*     {enter_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants
 
*  Arguments Given:
      LOGICAL BAD
      INTEGER EL
      DOUBLE PRECISION ARRAY( EL )
 
*  Arguments Returned:
      LOGICAL MONOTO
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER HIGH               ! Index of second initial value
      INTEGER I                  ! Loop counter
      LOGICAL INCREA             ! True if the values are increasing
      INTEGER LOW                ! Index of current value
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Must have at least 3 elements.
      IF ( EL .LT. 2 ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'N', EL )
         CALL ERR_REP( 'KPG1_MONOx_TOOFEW',
     :     'There are too few elements ^N to determine whether an '/
     :     /'array is monotonic.', STATUS )
         GOTO 999
      END IF
 
*  Initialise the monotonicity flag.
      MONOTO = .TRUE.
 
*  Work with bad values.
      IF ( BAD ) THEN
 
*  Find the first two non-bad values.  Exclude any bad data.
         LOW = 1
         DO WHILE ( ARRAY( LOW ) .EQ. VAL__BADD .AND. LOW .LT. EL )
            LOW = LOW + 1
         END DO
         HIGH = MIN( LOW + 1, EL )
         DO WHILE ( ARRAY( HIGH ) .EQ. VAL__BADD .AND. HIGH .LT. EL )
            HIGH = HIGH + 1
         END DO
 
*  Test for no pair of good values.
         IF ( HIGH .GT. EL ) THEN
            MONOTO = .FALSE.
         ELSE
 
*  Find the initial sign.
            INCREA = ARRAY( HIGH ) .GT. ARRAY( LOW )
 
*  Watch for zero increase, and flag as non-monotonic.
            IF ( .NOT. INCREA ) THEN
               MONOTO = ABS( ARRAY( HIGH ) - ARRAY( LOW ) ) .GT.
     :                  VAL__EPSD
            END IF
 
 
*  Initialise the index counters.
            I = HIGH
            LOW = HIGH
 
*  Only need to loop through the other array values when the array may
*  still be monotonic.  Loop through the values.
            DO WHILE ( MONOTO .AND. I .LT. EL )
 
*  Compare the next value with the current one.  Perform the
*  appropriate test for monotonicity depending on the polarity.
               IF ( ARRAY ( I + 1 ) .NE. VAL__BADD ) THEN
                  IF ( INCREA ) THEN
                     MONOTO = ARRAY( I + 1 ) .GT. ARRAY( LOW )
                  ELSE
                     MONOTO = ARRAY( I + 1 ) .LT. ARRAY( LOW )
                  END IF
                  LOW = I + 1
               END IF
 
*  Loop to the next value.
               I = I + 1
            END DO
         END IF
 
*  The array does not have bad values.
      ELSE
 
*  Find the initial sign.
         INCREA = ARRAY( 2 ) .GT. ARRAY( 1 )
 
*  Watch for zero increase, and flag as non-monotonic.
         IF ( .NOT. INCREA ) THEN
            MONOTO = ABS( ARRAY( 2 ) - ARRAY( 1 ) ) .GT. VAL__EPSD
         END IF
 
*  Initialise the index counter.
         I = 2
 
*  Only need to loop through the other array values when the array may
*  still be monotonic.  Loop through the values.
         DO WHILE ( MONOTO .AND. I .LT. EL )
 
*  Compare the next value with the current one.  Perform the
*  appropriate test for monotonicity depending on the polarity.
            IF ( INCREA ) THEN
               MONOTO = ARRAY( I + 1 ) .GT. ARRAY( I )
            ELSE
               MONOTO = ARRAY( I + 1 ) .LT. ARRAY( I )
            END IF
 
*  Loop to the next value.
            I = I + 1
         END DO
      END IF
 
  999 CONTINUE
 
      END
