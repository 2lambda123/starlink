      SUBROUTINE KPG1_MEDUI( BAD, EL, ARRAY, MEDIAN, NELUSE, STATUS )
*+
*  Name:
*     KPG1_MEDUx
 
*  Purpose:
*     Derives the unweighted median of a vector.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_MEDUx( BAD, EL, ARRAY, MEDIAN, NELUSE, STATUS )
 
*  Description:
*     This routine derives the unweighted median of an array.  If there
*     are an even number of elements, the median is computed from the
*     mean of the two elements that straddle the median.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        If BAD is .TRUE. there may be bad pixels present in the vector
*        and so should be tested.  If BAD is .FALSE. there is no testing
*        for bad values.
*     EL = INTEGER (Given)
*        The number of elements within the array to sort.
*     ARRAY( EL ) = ? (Given and Returned)
*        The array whose median is to be found.  On exit the array is
*        partially sorted.
*     MEDIAN = ? (Returned)
*        The median of the array.
*     NELUSE = ? (Returned)
*        The number of elements actually used after bad values have been
*        excluded.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate. The
*     array supplied to the routine must have the data type specified.
 
*  Implementation Deficiencies:
*     The routine could be made more effiecient by using a partial
*     Quicksort, stopping once the median is found.  The current version
*     is an interim solution.
 
*  [optional_subroutine_items]...
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1993 February 17 (MJC):
*        Original version.
*     {enter_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT public constants
 
*  Arguments Given:
      LOGICAL BAD
 
*  Arguments Given and Returned:
      INTEGER EL
      INTEGER ARRAY( EL )
 
*  Arguments Returned:
      INTEGER MEDIAN
      INTEGER NELUSE             ! Actual number of values to find the
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER CURR               ! Index to current smallest value
                                 ! during sorting
      INTEGER CURVAL             ! Current smallest value during sorting
      INTEGER ELEM               ! Sum of weights used to locate median
                                 ! during sort
      INTEGER MEDPOS             ! The position of the median in the
                                 ! sorted array
      INTEGER INDEX              ! Index to sample elements
      INTEGER TEST               ! Index to sample element for testing
                                 ! against CURR
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  The number used is the input number elements unless the vector may
*  may contain bad values.
      NELUSE = EL
 
*  Given one value, there median is just that value.
      IF ( EL .EQ. 1 ) THEN
         MEDIAN = ARRAY( 1 )
      ELSE
 
*  Initialise running total for the sum of values of valid pixels.
         NELUSE = 0
 
*  Perform bad-pixel testing.
         IF ( BAD ) THEN
 
*  Loop through all points in the input vector.
            DO INDEX = 1, EL
 
*  If the pixel is valid then increment the number-of-values counter.
               IF ( ARRAY( INDEX ) .NE. VAL__BADI ) THEN
                  NELUSE = NELUSE + 1
 
*  Shift the value for sorting.
                  ARRAY( NELUSE ) = ARRAY( INDEX )
               END IF
            END DO
 
*  To avoid trashing the input array completely, replace the lost values
*  with the magic value.
            IF ( NELUSE .LT. EL ) THEN
               DO INDEX = NELUSE + 1, EL
                  ARRAY( INDEX ) = VAL__BADI
               END DO
            END IF
         END IF
 
*  Compute the median position, or the next element above for an even
*  number of elements.
         MEDPOS = NELUSE / 2 + 1
 
*  Sort the array.
*  ===============
 
*  Initialise the index to the array element for the comparison.
         TEST = 1
         ELEM = 0
 
*  We can terminate the sort once the position includes the median
*  position.
         DO WHILE ( ELEM .LT. MEDPOS )
 
*  Initialise index to the current element and the current value.
            CURR   = TEST
            CURVAL = ARRAY( TEST )
 
*  Compare all array elements after the test element against the
*  current value.
            DO INDEX = TEST + 1, NELUSE
               IF ( ARRAY( INDEX ) .LT. CURVAL ) THEN
 
*  We have found a value in the vector which is less than the current
*  smallest value, this element becomes new current element.
                  CURR   = INDEX
                  CURVAL = ARRAY( INDEX )
               END IF
            END DO
 
            IF ( CURR .NE. TEST ) THEN
 
*  A smaller value than the test value was found so swap the values.
               ARRAY( CURR ) = ARRAY( TEST )
               ARRAY( TEST )  = CURVAL
            END IF
 
*  Increment the sort-position index.
            ELEM = ELEM + 1
 
*  Increment index to test element
            TEST = TEST + 1
         END DO
 
*  Set up the median value.  For even numbers take the mean of the
*  two values either side.  To avoid bias and overflows for integers,
*  convert to double precision to evaluate the average.
         IF ( MOD( NELUSE, 2 ) .EQ. 0 ) THEN
            MEDIAN = NUM_DTOI( ( NUM_ITOD( ARRAY( TEST - 1 ) ) +
     :               NUM_ITOD( ARRAY( TEST -2 ) ) ) * 0.5D0 )
         ELSE
            MEDIAN = ARRAY( TEST - 1 )
         END IF
 
*  End of condition for number in sample and median position
      END IF
 
      END
