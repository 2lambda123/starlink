      SUBROUTINE KPG1_GHSTI ( BAD, DIM, ARRAY, NUMBIN,
     :                         VALMAX, VALMIN, HIST, STATUS )
*+
*  Name:
*     KPG1_GHSTx
 
*  Purpose:
*     Calculates the histogram of an array of data.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation
*     CALL KPG1_GHSTx( BAD, DIM, ARRAY, NUMBIN, VALMAX, VALMIN, HIST,
*    :                 STATUS )
 
*  Description:
*     This routine calculates the truncated histogram of an array of
*     data between defined limits and in a defined number of bins.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*        If .TRUE., bad pixels will be processed.  This should not be
*        set to false unless the input array contains no bad pixels.
*     DIM = INTEGER (Given)
*        The dimension of the array whose histogram is required.
*     ARRAY( DIM ) = ? (Given)
*        The input data array.
*     NUMBIN = INTEGER (Given)
*        Number of bins used in the histogram.  For integer data types
*        this should result in a bin width of at least one unit.  So for
*        example, byte data should never have more than 256 bins.
*     VALMAX = ? (Given)
*        Maximum data value included in the array.
*     VALMIN = ? (Given)
*        Minimum data value included in the array.
*     HIST( NUMBIN ) = INTEGER (Returned)
*        Array containing the histogram.
*     STATUS = INTEGER (Given and Returned)
*        Global status value.
 
*  Algorithm:
*     - Compute the scale factor
*     - For all array elements, check whether the value is within the
*     range of the histogram, and if it is compute its bin number. Check
*     for bad pixels if requested.
 
*  Notes:
*     -  There is a routine for all numeric data types: replace "x" in
*     the routine name by B, D, R, I, UB, UW, or W as appropriate.  The
*     arguments ARRAY, VALMAX, and VALMIN must have the data type
*     specified.
 
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1990 July 19 (MJC):
*        Original version.
*     1991 September 17 (MJC):
*        Fixed overflow bug.
*     1991 November 13 (MJC):
*        Fixed a bug converting NUMBIN for calculations.
*     1996 March 25 (MJC):
*        Better check that the bin width is valid.
*     1996 July 3 (MJC):
*        Made to cope with unsigned integer types.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_new_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT  NONE             ! No default typing allowed
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT primitive data constants
 
*  Arguments Given:
      INTEGER DIM
      INTEGER NUMBIN
 
      LOGICAL BAD
 
      INTEGER ARRAY( DIM )
      INTEGER VALMAX
      INTEGER VALMIN
 
*  Arguments Returned:
      INTEGER HIST( NUMBIN )
 
*  Status:
      INTEGER STATUS
 
*  Local Variables:
      INTEGER DUMMY              ! Dummy used in histogram calculation
      DOUBLE PRECISION DVMAX     ! Maximum value
      DOUBLE PRECISION DVMIN     ! Minimum value
      INTEGER I                  ! Counter
      INTEGER K                  ! Counter
      DOUBLE PRECISION SCALE     ! Scale factor used for choosing
                                 ! correct bin
      DOUBLE PRECISION TEMP      ! Work variable
      DOUBLE PRECISION THRESH    ! Threshold for identical-limits test
      DOUBLE PRECISION TNUMB     ! Number of bins
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
 
*.
 
*  Check the global inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  First set the bins of the histogram to zero.
      DO  K = 1, NUMBIN
         HIST( K ) = 0
      END DO
 
*  Assign some useful variables.
      DVMIN = NUM_ITOD( VALMIN )
      DVMAX = NUM_ITOD( VALMAX )
      TNUMB = DBLE( NUMBIN )
 
*  Set the minimum separation allowed for the data limits such that
*  each of the histogram bins is resolvable.  The halving prevents
*  arithmetic overflow for data with a very large dynamic range.
      IF ( VAL__EPSI .LT. 1 ) THEN
         THRESH = ( ABS( DVMAX ) / 2.0D0 + ABS( DVMIN ) / 2.0D0 ) *
     :            NUM_ITOD( VAL__EPSI ) * TNUMB
 
*  For integer data the bin size must be at least one.  Again the
*  threshold is halved for the subsequent test.
      ELSE
         THRESH = 0.5D0
      END IF
 
*  Next set the scaling factor, provided the bins are resolvable.
*  Again the halving prevents arithmetic overflow for data with a very
*  large dynamic range.  Thus both sides of the comparison have been
*  halved.
      IF ( ABS( DVMAX / 2.0D0 - DVMIN / 2.0D0 ) .GE. THRESH ) THEN
         SCALE  =  DVMAX - DVMIN
      ELSE
         STATUS = SAI__ERROR
         CALL ERR_REP( 'KPG1_GHSTx_LIMITS',
     :     'Maximum and minimum are identical or almost '/
     :     /'the same.  No histogram formed', STATUS )
         GOTO 999
      END IF
 
*  Calculate the histogram.
*  ========================
 
*  For processing efficiency deal with the various cases separately.
*  These are with and without bad pixels, and unsigned integer types
*  versus other types.  The latter difference is needed because Fortran
*  does not support unsigned integer types, and numerical comparisons
*  will use the signed types, and hence give the wrong answers.  Thus
*  the comparisons are performed in floating-point.
 
*  Bad-pixel testing to be undertaken on Fortran data types.
*  ---------------------------------------------------------
      IF ( 'I' .NE. 'UB' .AND. 'I' .NE. 'UW' ) THEN
         IF ( BAD ) THEN
 
*  Loop round all the elements.
            DO I = 1, DIM
 
*  Test for bad pixel or pixel value outside the histogram range.
               IF ( ARRAY( I ) .NE. VAL__BADI .AND.
     :              ARRAY( I ) .GE. VALMIN .AND.
     :              ARRAY( I ) .LE. VALMAX ) THEN
 
*  Find bin number for particular point.  MIN is to allow for pixel
*  value to equal maximum.
                  DUMMY = MIN( NUMBIN, 1 + INT( TNUMB *
     :                    ( NUM_ITOD( ARRAY( I ) ) - DVMIN )
     :                    / SCALE ) )
 
*  Increment the number of data in the bin by one.
                  HIST( DUMMY )  =  HIST( DUMMY ) + 1
               END IF
 
*  End of loop round elements.
            END DO
 
*  No bad-pixel testing... on Fortran data types.
*  ----------------------------------------------
         ELSE
 
*  Loop round all the elements.
            DO I = 1, DIM
 
*  Test for pixel value outside the histogram range.
               IF ( ARRAY( I ) .GE. VALMIN .AND.
     :              ARRAY( I ) .LE. VALMAX ) THEN
 
*  Find bin number for particular point.  MIN is to allow for pixel
*  value to equal maximum.
                  DUMMY = MIN( NUMBIN, 1 + INT( TNUMB *
     :                    ( NUM_ITOD( ARRAY( I ) ) - DVMIN )
     :                    / SCALE ) )
 
*  Increment the number of data in the bin by one.
                  HIST( DUMMY )  =  HIST( DUMMY ) + 1
               END IF
 
*  End of loop round elements.
            END DO
 
*  End of main bad-pixels-present check
         END IF
 
      ELSE
 
*  Bad-pixel testing to be undertaken on unsigned integer data types.
*  ------------------------------------------------------------------
         IF ( BAD ) THEN
 
*  Loop round all the elements.
            DO I = 1, DIM
 
*  Test for bad pixel or pixel value outside the histogram range.
               TEMP = NUM_ITOD( ARRAY( I ) )
               IF ( ARRAY( I ) .NE. VAL__BADI .AND.
     :              TEMP .GE. DVMIN .AND. TEMP .LE. DVMAX ) THEN
 
*  Find bin number for particular point.  MIN is to allow for pixel
*  value to equal maximum.
                  DUMMY = MIN( NUMBIN, 1 + INT( TNUMB *
     :                    ( TEMP - DVMIN ) / SCALE ) )
 
*  Increment the number of data in the bin by one.
                  HIST( DUMMY )  =  HIST( DUMMY ) + 1
               END IF
 
*  End of loop round elements.
            END DO
 
*  No bad-pixel testing... on unsigned integer data types.
*  -------------------------------------------------------
         ELSE
 
*  Loop round all the elements.
            DO I = 1, DIM
 
*  Test for pixel value outside the histogram range.
               TEMP = NUM_ITOD( ARRAY( I ) )
               IF ( TEMP .GE. DVMIN .AND. TEMP .LE. DVMAX ) THEN
 
*  Find bin number for particular point.  MIN is to allow for pixel
*  value to equal maximum.
                  DUMMY = MIN( NUMBIN, 1 + INT( TNUMB *
     :                    ( TEMP - DVMIN ) / SCALE ) )
 
*  Increment the number of data in the bin by one.
                  HIST( DUMMY )  =  HIST( DUMMY ) + 1
               END IF
 
*  End of loop round elements.
            END DO
 
*  End of main bad-pixels-present check
         END IF
 
      END IF
 
 999  CONTINUE
 
*  End and return.
      END
