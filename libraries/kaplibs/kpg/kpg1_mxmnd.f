      SUBROUTINE KPG1_MXMND( BAD, EL, ARRAY, NINVAL, MAXMUM, MINMUM,
     :                         MAXPOS, MINPOS, STATUS )
*+
*  Name:
*     KPG1_MXMNx
 
*  Purpose:
*     Returns the maximum and minimum values of an array.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation
*     CALL KPG1_MXMNx( BAD, EL, ARRAY, NINVAL, MAXMUM,
*    :                 MINMUM, MAXPOS, MINPOS, STATUS )
 
*  Description:
*     This routine returns the maximum and minimum values of an input
*     array, where it found the maximum and minimum, and the number of
*     good and bad pixels in the array.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        If true there may be bad pixels present in the array.  If false
*        it is safe not to check for bad values.
*     EL = INTEGER (Given)
*        The dimension of the input array.
*     ARRAY( EL ) = ? (Given)
*        Input array of data.
*     NINVAL = INTEGER (Returned)
*        Number of bad pixels in the array.
*     MAXMUM = ? (Returned)
*        Maximum value found in the array.
*     MINMUM = ? (Returned)
*        Minimum value found in the array.
*     MAXPOS = INTEGER (Returned)
*        Index of the pixel where the maximum value is (first) found.
*     MINPOS = INTEGER (Returned)
*        Index of the pixel where the minimum value is (first) found.
*     STATUS = INTEGER  (Given)
*        Global status value
 
*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate.  The
*     ARRAY, MAXMUM, and MINMUM arguments supplied to the routine must
*     have the data type specified.
 
*  Algorithm:
*     - Initialise extreme values to opposite extremes, and positions
*     to the first array element.
*     - Loop for all pixels comparing current value with the current
*     minimum and maximum.  Use separate loops with and without bad-
*     element checks.  In the former count the number of bad elements.
 
*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1990 July 19 (MJC):
*        Original version.
*     1991 March 14 (MJC):
*        Fixed initialisation bug by using first array value instead
*        of extreme values (as per the existing commentary).
*     1991 May 21 (MJC):
*        Previous fix introduced a bug which occurs when the first pixel
*        is bad.  Modified to search for the first non-bad value to
*        initialise the extreme values.
*     1996 July 3 (MJC):
*        Made to cope with unsigned integer types.  Standardised
*        declarations layout and commenting.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT  NONE              ! no default typing allowed
 
*  Global Constants:
      INCLUDE  'SAE_PAR'          ! SSE global definitions
      INCLUDE  'PRM_PAR'          ! Magic-value definitions
 
*  Arguments Given:
      LOGICAL BAD
      INTEGER EL
      DOUBLE PRECISION ARRAY( EL )
 
*  Arguments Returned:
      INTEGER NINVAL
      DOUBLE PRECISION MAXMUM
      DOUBLE PRECISION MINMUM
      INTEGER MAXPOS
      INTEGER MINPOS
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER I                  ! Counter
      INTEGER IMAX               ! A unsigned-integer maximum
      INTEGER IMIN               ! A unsigned-integer minimum
      INTEGER TEMP               ! A unsigned-integer data value
 
*  Internal References:
      INCLUDE 'NUM_DEC'          ! NUM declarations
      INCLUDE 'NUM_DEF'          ! NUM definitions
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Initialise the returned values.
*  ===============================
 
*  Initialise maximum and minimum variables to be equal to the value of
*  the first element of the array, and the positions of each to be
*  there.
      MINMUM = ARRAY( 1 )
      MAXMUM = ARRAY( 1 )
      MAXPOS = 1
      MINPOS = 1
 
*  Initialise the bad value count.
      IF ( BAD ) THEN
 
*  Watch for a bad first value.
         IF ( ARRAY( 1 ) .EQ. VAL__BADD ) THEN
 
*  Search for the first non-bad value.
            I = 2
            DO WHILE ( I .LE. EL  .AND.
     :                 ARRAY( MIN( I, EL ) ) .EQ. VAL__BADD )
               I = I + 1
            END DO
            NINVAL = I - 1
 
*  Check to see if all pixels are undefined.
            IF ( NINVAL .EQ. EL ) THEN
               STATUS = SAI__ERROR
               CALL ERR_REP( 'KPG1_MXMNX_ARINV',
     :           'All pixels in the array are bad.', STATUS )
               GOTO 999
            END IF
 
*  Set the initial values.
            MINMUM = ARRAY( I )
            MAXMUM = ARRAY( I )
            MAXPOS = I
            MINPOS = I
 
*  The first value is not bad, so proceed normally.
         ELSE
            NINVAL = 0
         END IF
      END IF
 
*  That's all that needs to be done if there is but one pixel.
      IF ( EL .EQ. 1 ) GOTO 999
 
*  Find the extreme values.
*  ========================
 
*  For processing efficiency deal with the various cases separately.
*  These are with and without bad pixels, and unsigned integer types
*  versus other types.  The latter difference is needed because Fortran
*  does not support unsigned integer types, and numerical comparisons
*  will use the signed types, and hence give the wrong answers.  Thus
*  the comparisons are performed in floating-point.
 
*  Bad-pixel testing to be undertaken on Fortran data types.
*  ---------------------------------------------------------
      IF ( 'D' .NE. 'UB' .AND. 'D' .NE. 'UW' ) THEN
         IF ( BAD ) THEN
 
*  Loop round all the elements of the array.
            DO I = MIN( NINVAL + 2, EL ), EL
 
*  Test for valid pixel.
               IF ( ARRAY( I ) .NE. VAL__BADD ) THEN
 
*  Check current maximum against current pixel value.
                  IF ( ARRAY( I ) .GT. MAXMUM ) THEN
                     MAXMUM = ARRAY( I )
                     MAXPOS = I
 
*  Check current minimum against current pixel value.
                  ELSE IF ( ARRAY( I ) .LT. MINMUM ) THEN
                     MINMUM = ARRAY( I )
                     MINPOS = I
                  END IF
               ELSE
 
*  One more bad pixel to the count.
                  NINVAL = NINVAL + 1
               END IF
 
*  End of loop round the array elements.
            END DO
 
*  No bad-pixel testing... on Fortran data types.
*  ----------------------------------------------
         ELSE
 
*  No bad pixels by definition.
            NINVAL = 0
 
*  Loop round all the elements of the array.
            DO I = 2, EL
 
*  Check current maximum against current pixel value.
               IF ( ARRAY( I ) .GT. MAXMUM ) THEN
                  MAXMUM = ARRAY( I )
                  MAXPOS = I
 
*  Check current minimum against current pixel value.
               ELSE IF ( ARRAY( I ) .LT. MINMUM ) THEN
                  MINMUM = ARRAY( I )
                  MINPOS = I
               END IF
 
*  End of loop round the array elements.
            END DO
         END IF
 
      ELSE
 
*  Bad-pixel testing to be undertaken on unsigned integer data types.
*  ------------------------------------------------------------------
 
*  Use signed integers for the comparisons.
         IMAX = NUM_DTOI( MAXMUM )
         IMIN = NUM_DTOI( MINMUM )
 
         IF ( BAD ) THEN
 
*  Loop round all the elements of the array.
            DO I = MIN( NINVAL + 2, EL ), EL
 
*  Test for valid pixel.
               IF ( ARRAY( I ) .NE. VAL__BADD ) THEN
 
*  Convert to integer for the comparisons.
                  TEMP = NUM_DTOI( ARRAY( I ) )
 
*  Check current maximum against current pixel value.
                  IF ( TEMP .GT. IMAX ) THEN
                     IMAX = TEMP
                     MAXPOS = I
 
*  Check current minimum against current pixel value.
                  ELSE IF ( TEMP .LT. IMIN ) THEN
                     IMIN = TEMP
                     MINPOS = I
                  END IF
               ELSE
 
*  One more bad pixel to the count.
                  NINVAL = NINVAL + 1
               END IF
 
*  End of loop round the array elements.
            END DO
 
*  No bad-pixel testing... on unsigned integer data types.
*  -------------------------------------------------------
         ELSE
 
*  No bad pixels by definition.
            NINVAL = 0
 
*  Loop round all the elements of the array.
            DO I = 2, EL
 
*  Convert to integer for the comparisons.
               TEMP = NUM_DTOI( ARRAY( I ) )
 
*  Check current maximum against current pixel value.
               IF ( TEMP .GT. IMAX ) THEN
                  IMAX = TEMP
                  MAXPOS = I
 
*  Check current minimum against current pixel value.
               ELSE IF ( TEMP .LT. IMIN ) THEN
                  IMIN = TEMP
                  MINPOS = I
               END IF
 
*  End of loop round the array elements.
            END DO
         END IF
 
*  Convert the integers back to the unsigned-integer type for export.
         MAXMUM = NUM_ITOD( IMAX )
         MINMUM = NUM_ITOD( IMIN )
      END IF
 
  999 CONTINUE
 
*  Return and end.
      END
