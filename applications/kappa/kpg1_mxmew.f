      SUBROUTINE KPG1_MXMEW( BAD, EL, ARRAY, ERROR, NSIGMA, THRESH,
     :                         NINVAL, MAXMUM, MINMUM, MAXPOS, MINPOS,
     :                         STATUS )
*+
*  Name:
*     KPG1_MXMEx
 
*  Purpose:
*     Returns the maximum and minimum values between thresholds of an
*     array including its errors.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation
*     CALL KPG1_MXMEx( BAD, EL, ARRAY, ERROR, NSIGMA, THRESH, NINVAL,
*                      MAXMUM, MINMUM, MAXPOS, MINPOS, STATUS )
 
*  Description:
*     This routine returns the maximum and minimum values of an input
*     array when combined with its associated error array.  The extreme
*     values can be constrained to lie between two thresholds, where
*     values outside the thresholds are ignored.  So for example this
*     routine might be used to find the smallest positive value or the
*     largest negative value.  The number of multiples of each error
*     that should be added to and subtracted from the primary array to
*     find the extreme values is adjustable.  The routine also returns
*     where it found the maximum and minimum, and the number of elements
*     where either or both of the array values is bad.
*
*     An error report is made if all the values are bad or lie outside
*     of the thresholds.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        If .TRUE., there may be bad pixels present in the array.  If
*        .FALSE., it is safe not to check for bad values.
*     EL = INTEGER (Given)
*        The dimension of the input array.
*     ARRAY( EL ) = ? (Given)
*        Input array of data.
*     ERROR( EL ) = ? (Given)
*        Error array associated with the data array.
*     NSIGMA = REAL (Given)
*        Number of multiples of the error.
*     THRESH( 2 ) = ? (Given)
*        The thresholds between which the extreme values are to be
*        found (lower then upper).  Values equal to the thresholds are
*        excluded.  To find the extreme values across the full range,
*        set the thresholds to VAL__MINx and VAL__MAXx.
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
*     ARRAY, ERROR, THRESH, MAXMUM, and MINMUM arguments supplied to
*     the routine must have the data type specified.
 
*  Algorithm:
*     - Initialise extreme values to thresholds, and positions
*     to the first array element.
*     - Loop for all valid pixels comparing current value with the
*     current minimum and maximum.  Use separate loops with and without
*     bad-element checks.  In the former count the number of bad
*     elements.
 
*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1996 October 2 (MJC):
*        Original version based upon KPG1_MXMNx.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! no default typing allowed
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SSE global definitions
      INCLUDE 'PRM_PAR'          ! Magic-value (VAL__BADx) definitions
 
*  Arguments Given:
      LOGICAL BAD
      INTEGER EL
      INTEGER*2 ARRAY( EL )
      INTEGER*2 ERROR( EL )
      REAL NSIGMA
      INTEGER*2 THRESH( 2 )
 
*  Arguments Returned:
      INTEGER NINVAL
      INTEGER*2 MAXMUM
      INTEGER*2 MINMUM
      INTEGER MAXPOS
      INTEGER MINPOS
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER*2 AMINUS             ! Data value less error
      INTEGER*2 APLUS              ! Data value plus error
      INTEGER*2 DELTA              ! Error-bar offsets
      INTEGER I                  ! Counter
      INTEGER*2 OTHRES( 2 )        ! Thresholds where first element is the
                                 ! lower, and second is upper
 
*  Internal References:
      INCLUDE 'NUM_DEC'          ! NUM declarations
      INCLUDE 'NUM_DEF'          ! NUM definitions
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Initialise the returned values.
*  ===============================
 
*  Add some defensive code in case the thresholds are reversed.
      OTHRES( 1 ) = NUM_MINW( THRESH( 1 ), THRESH( 2 ) )
      OTHRES( 2 ) = NUM_MAXW( THRESH( 1 ), THRESH( 2 ) )
 
*  Initialise maximum and minimum variables to be equal to the value of
*  the thresholds.
      MINMUM = OTHRES( 2 )
      MAXMUM = OTHRES( 1 )
 
*  Initialise the positions of each to be the first element of the
*  array.
      MAXPOS = 1
      MINPOS = 1
 
*  Initialise the invalid-value count.  This can comprise bad pixels
*  or values outside the thresholds.
      NINVAL = 0
 
*  Find the extreme values.
*  ========================
 
*  For processing efficiency deal with the various cases separately.
*  These are with and without bad pixels.
 
*  Bad-pixel testing to be undertaken on Fortran data types.
*  ---------------------------------------------------------
      IF ( BAD ) THEN
 
*  Loop round all the elements of the array.
         DO I = 1, EL
 
*  Test for valid pixel.
            IF ( ARRAY( I ) .NE. VAL__BADW .AND.
     :           ERROR( I ) .NE. VAL__BADW ) THEN
 
*  Compute the size of the error multiple required converting back to
*  the generic type.  Strictly one should use VAL routines to find DELTA
*  and apply the offsets, but these are very slow.  Perform sums and
*  comparisons using functions so that they apply to all numeric data
*  types.
               DELTA = NUM_RTOW( ABS( NUM_WTOR( ERROR( I ) ) *
     :                 NSIGMA ) )
               APLUS = NUM_ADDW( ARRAY( I ), DELTA )
               AMINUS = NUM_SUBW( ARRAY( I ), DELTA )
 
*  Test that the value is between the thresholds.
               IF ( NUM_GTW( AMINUS, OTHRES( 1 ) ) .AND.
     :              NUM_LTW( APLUS, OTHRES( 2 ) ) ) THEN
 
*  Check current maximum against current pixel value.
                  IF ( NUM_GTW( APLUS, MAXMUM ) ) THEN
                     MAXMUM = APLUS
                     MAXPOS = I
                  END IF
 
*  Check current minimum against current pixel value.
                  IF ( NUM_LTW( AMINUS, MINMUM ) ) THEN
                     MINMUM = AMINUS
                     MINPOS = I
                  END IF
 
               ELSE
 
*  Count the invalid pixel.
                  NINVAL = NINVAL + 1
               END IF
            ELSE
 
*  One more bad pixel to the count.
               NINVAL = NINVAL + 1
            END IF
 
*  End of loop round the array elements.
         END DO
 
*  No bad-pixel testing...
*  -----------------------
      ELSE
 
*  Loop round all the elements of the array.
         DO I = 1, EL
 
*  Compute the size of the error multiple required converting back to
*  the generic type.
            DELTA = NUM_RTOW( ABS( NUM_WTOR( ERROR( I ) ) *
     :              NSIGMA ) )
            APLUS = NUM_ADDW( ARRAY( I ), DELTA )
            AMINUS = NUM_SUBW( ARRAY( I ), DELTA )
 
*  Test that the value is between the thresholds.
            IF ( NUM_GTW( AMINUS, OTHRES( 1 ) ) .AND.
     :           NUM_LTW( APLUS, OTHRES( 2 ) ) ) THEN
 
*  Check current maximum against current pixel value.
               IF ( NUM_GTW( APLUS, MAXMUM ) ) THEN
                  MAXMUM = APLUS
                  MAXPOS = I
               END IF
 
*  Check current minimum against current pixel value.
               IF ( NUM_LTW( AMINUS, MINMUM ) ) THEN
                  MINMUM = AMINUS
                  MINPOS = I
               END IF
 
            ELSE
 
*  Count the invalid pixel.
               NINVAL = NINVAL + 1
            END IF
 
*  End of loop round the array elements.
         END DO
      END IF
 
*  Check to see if all pixels are undefined.
      IF ( NINVAL .EQ. EL ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'KPG1_MXMEX_ARINV',
     :     'All data values or their errors are bad, and/or when '/
     :     /'combined they are all outside the allowed thresholds.',
     :     STATUS )
      END IF
 
  999 CONTINUE
 
*  Return and end.
      END
