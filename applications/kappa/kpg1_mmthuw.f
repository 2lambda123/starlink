      SUBROUTINE KPG1_MMTHUW( BAD, EL, ARRAY, THRESH, NINVAL, MAXMUM,
     :                         MINMUM, MAXPOS, MINPOS, STATUS )
*+
*  Name:
*     KPG1_MXMNx
 
*  Purpose:
*     Returns the maximum and minimum values of an array within
*     thresholds.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation
*     CALL KPG1_MXMNx( BAD, EL, ARRAY, THRESH, NINVAL, MAXMUM,
*    :                 MINMUM, MAXPOS, MINPOS, STATUS )
 
*  Description:
*     This routine returns the maximum and minimum values of an input
*     array, where it found the maximum and minimum, and the number of
*     good and bad pixels in the array.  The extreme values can be
*     constrained to lie between two thresholds, where values outside
*     the thresholds are ignored.  So for example this routine might be
*     used to find the smallest positive value or the largest negative
*     value.
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
*     THRESH( 2 ) = ? (Given)
*        The thresholds between which the extreme values are to be
*        found (lower then upper).  Values equal to the thresholds are
*        excluded.  To find the extreme values across the full range,
*        set the thresholds to VAL__MINx and VAL__MAXx or use routine
*        KPG_MXMNx.
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
*     ARRAY, THRESH, MAXMUM, and MINMUM arguments supplied to the
*     routine must have the data type specified.
 
*  Algorithm:
*     - Initialise extreme values to the thresholds, and positions
*     to the first array element.
*     - Loop for all pixels comparing current value with the current
*     minimum and maximum.  Use separate loops with and without bad-
*     element checks.  In the former count the number of bad elements.
 
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
      IMPLICIT  NONE             ! no default typing allowed
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SSE global definitions
      INCLUDE 'PRM_PAR'          ! Magic-value definitions
 
*  Arguments Given:
      LOGICAL BAD
      INTEGER EL
      INTEGER*2 ARRAY( EL )
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
      OTHRES( 1 ) = NUM_MINUW( THRESH( 1 ), THRESH( 2 ) )
      OTHRES( 2 ) = NUM_MAXUW( THRESH( 1 ), THRESH( 2 ) )
 
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
 
*  Bad-pixel testing.
*  ------------------
      IF ( BAD ) THEN
 
*  Loop round all the elements of the array.
         DO I = 1, EL
 
*  Test for valid pixel.
            IF ( ARRAY( I ) .NE. VAL__BADUW .AND.
     :           NUM_GTUW( ARRAY( I ), OTHRES( 1 ) ) .AND.
     :           NUM_LTUW( ARRAY( I ), OTHRES( 2 ) ) ) THEN
 
*  Check current maximum against current pixel value.
               IF ( NUM_GTUW( ARRAY( I ), MAXMUM ) ) THEN
                  MAXMUM = ARRAY( I )
                  MAXPOS = I
               END IF
 
*  Check current minimum against current pixel value.
               IF ( NUM_LTUW( ARRAY( I ), MINMUM ) ) THEN
                  MINMUM = ARRAY( I )
                  MINPOS = I
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
 
            IF ( NUM_GTUW( ARRAY( I ), OTHRES( 1 ) ) .AND.
     :           NUM_GTUW( ARRAY( I ), OTHRES( 2 ) ) ) THEN
 
*  Check current maximum against current pixel value.
               IF ( NUM_GTUW( ARRAY( I ), MAXMUM ) ) THEN
                  MAXMUM = ARRAY( I )
                  MAXPOS = I
               END IF
 
*  Check current minimum against current pixel value.
               IF ( NUM_LTUW( ARRAY( I ), MINMUM ) ) THEN
                  MINMUM = ARRAY( I )
                  MINPOS = I
               END IF
            ELSE
 
*  Increment the number of invalid values.
               NINVAL = NINVAL + 1
            END IF
 
*  End of loop round the array elements.
         END DO
      END IF
 
*  Check to see if all pixels are undefined.
      IF ( NINVAL .EQ. EL ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'KPG1_MXMNX_ARINV',
     :     'All pixels in the array are bad.', STATUS )
      END IF
 
  999 CONTINUE
 
*  Return and end.
      END
