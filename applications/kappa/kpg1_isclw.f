      SUBROUTINE KPG1_ISCLW( BAD, DIM1, DIM2, INARR, INVERT, LOWER,
     :                        UPPER, LOWLIM, UPPLIM, BADVAL, OUTARR,
     :                        STATUS )
*+
*  Name:
*     KPG1_ISCLx
 
*  Purpose:
*     Scale image between limits.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation
*     CALL KPG1_ISCLx( BAD, DIM1, DIM2, INARR, INVERT, LOWER, UPPER,
*    :                 LOWLIM, UPPLIM, BADVAL, OUTARR, STATUS )
 
*  Description:
*     The input 2-d array is scaled between lower and upper limits such
*     that the lower limit and all values below it are set to a minimum
*     value, the upper limit and all values above are set to a maximum
*     value, and all valid values in between are assigned values using
*     linear interpolation between the limits. The image may or may
*     not be inverted.  The sign of the scaling can be reversed.  The
*     scaled data are written to an integer output array.
 
*  Arguments:
*     BAD = LOGICAL (Given)
*         If true there will be no checking for bad pixels.
*     DIM1 = INTEGER (Given)
*         The first dimension of the 2-d arrays.
*     DIM2 = INTEGER (Given)
*         The second dimension of the 2-d arrays.
*     INARR( DIM1, DIM2 ) = ? (Given)
*         The original, unscaled image data.
*     LOWER = ? (Given)
*         The data value that specifies the lower image-scaling limit.
*         This may be smaller than %UPPER to provide a negative scale
*         factor.
*     UPPER = ? (Given)
*         The data value that specifies the upper image-scaling limit.
*     INVERT = LOGICAL (Given)
*         True if the image is to be inverted for display.
*     LOWLIM = INTEGER (Given)
*         The lowest value to appear in the scaled array for good input
*         data.
*     UPPLIM = INTEGER (Given)
*         The highest value to appear in the scaled array for good input
*         data.
*     BADVAL = INTEGER (Given)
*         The value to be assigned to bad pixels in the scaled array.
*     OUTARR( DIM1, DIM2 ) = INTEGER (Returned)
*         The scaled version of the image.
*     STATUS = INTEGER (Given)
*         Value of the status on entering this subroutine.
 
*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate. The
*     array supplied to the routine must have the data type specified.
 
*  Algorithm:
*     - Derive the scale factor.
*     - The scaled image is produced with or without inversion.
*     - Checks are made for very large or small values beyond the range
*       of integers.
*     - Checking for bad pixels is made when requested; they are set to
*       the supplied value.
 
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1990 Jul 12 (MJC):
*        Original version.
*     1991 Mar 14 (MJC):
*        Made bad value generic.
*     1991 July 23 (MJC):
*        Added BADVAL argument.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT primitive data constants
 
*  Status:
      INTEGER STATUS
 
*  Arguments Given:
      INTEGER
     :  DIM1, DIM2,
     :  LOWLIM,
     :  UPPLIM,
     :  BADVAL
 
      LOGICAL
     :  BAD,
     :  INVERT
 
      INTEGER*2
     :  INARR( DIM1, DIM2 )
 
      INTEGER*2
     :  LOWER,
     :  UPPER
 
      INTEGER
     :  OUTARR( DIM1, DIM2 )
 
*  Local Variables:
      INTEGER
     :  I, J, K                ! General variables
 
      DOUBLE PRECISION
     :  DL,                    ! Lower scaling limit
     :  DU,                    ! Upper scaling limit
     :  LL,                    ! Lower limit of INTEGER
     :  UL,                    ! Upper limit of INTEGER
     :  W,                     ! Work variable
     :  SCALE                  ! Scaling factor
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'    ! NUM declarations for conversions
      INCLUDE 'NUM_DEC_W'    ! NUM declarations for functions
      INCLUDE 'NUM_DEF_CVT'    ! NUM definitions for conversions
      INCLUDE 'NUM_DEF_W'    ! NUM definitions for functions
 
*.
 
*    Check inherited global status.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
      UL = DBLE( VAL__MAXI )
      LL = DBLE( VAL__MINI )
      DL = NUM_WTOD( LOWER )
      DU = NUM_WTOD( UPPER )
 
*    Find the scaling factor.
*    ========================
 
*    Protect against divide-by-zero errors.  Abort with an error report
*    if the scaling cannot be performed.
 
      IF ( ABS( DU - DL ) .LT. NUM_WTOD( VAL__SMLW ) ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETD( 'LOWER', DL )
         CALL MSG_SETD( 'UPPER', DU )
         CALL ERR_REP( 'KPG1_ISCLX',
     :     'Scaling range, ^LOWER to ^UPPER, is too small to scale '/
     :     /'the image.', STATUS )
         GOTO 999
      ELSE
         SCALE = DBLE( UPPLIM - LOWLIM )/ ( DU - DL )
      END IF
 
*    Perform the scaling.
*    ====================
 
      IF ( BAD ) THEN
         IF ( INVERT ) THEN
 
*         Scale and invert the image.
 
            DO  I = 1, DIM2, 1
 
               K = ( DIM2 + 1 )-I
 
               DO  J = 1, DIM1, 1
 
*                Look for bad pixels.
 
                  IF ( INARR( J, K ) .EQ. VAL__BADW ) THEN
                     OUTARR( J, I ) = BADVAL
                  ELSE
 
*                   Check for very large or small values beyond the
*                   range of integers.  Array value is known not to
*                   be bad so VAL_ is not required.
 
                     W = ( NUM_WTOD( INARR( J, K ) ) - DL ) * SCALE
 
                     IF ( W .GT. UL ) THEN
                        OUTARR( J, I ) = UPPLIM
                     ELSE IF ( W .LT. LL ) THEN
                        OUTARR( J, I ) = LOWLIM
                     ELSE
 
*                      Scale between the limits.
 
                        OUTARR( J, I ) = LOWLIM + MIN( UPPLIM - LOWLIM,
     :                                   MAX( 0, NINT( W ) ) )
                     END IF
                  END IF
 
               END DO
            END DO
 
*       Do not invert.
 
         ELSE
 
*          Scale the image.
 
            DO  I = 1, DIM2, 1
               DO  J = 1, DIM1, 1
 
*                Look for bad pixels.
 
                  IF ( INARR( J, I ) .EQ. VAL__BADW ) THEN
                     OUTARR( J, I ) = BADVAL
                  ELSE
 
*                   Check for very large or small values beyond the
*                   range of integers.  Array value is known not to
*                   be bad so VAL_ is not required.
 
                     W = ( NUM_WTOD( INARR( J, I ) ) - DL ) * SCALE
 
                     IF ( W .GT. UL ) THEN
                        OUTARR( J, I ) = UPPLIM
                     ELSE IF ( W .LT. LL ) THEN
                        OUTARR( J, I ) = LOWLIM
                     ELSE
 
*                      Scale between the limits.
 
                        OUTARR( J, I ) = LOWLIM + MIN( UPPLIM - LOWLIM,
     :                                   MAX( 0, NINT( W ) ) )
                     END IF
                  END IF
 
               END DO
            END DO
 
         END IF
 
*    No bad pixels in the input array.
 
      ELSE
 
         IF ( INVERT ) THEN
 
*         Scale and invert the image.
 
            DO  I = 1, DIM2, 1
 
               K = ( DIM2 + 1 )-I
 
               DO  J = 1, DIM1, 1
 
*                Check for very large or small values beyond the
*                range of integers.  Array value is known not to
*                be bad so VAL_ is not required.
 
                  W = ( NUM_WTOD( INARR( J, K ) ) - DL ) * SCALE
 
                  IF ( W .GT. UL ) THEN
                     OUTARR( J, I ) = UPPLIM
                  ELSE IF ( W .LT. LL ) THEN
                     OUTARR( J, I ) = LOWLIM
                  ELSE
 
*                   Scale between the limits.
 
                     OUTARR( J, I ) = LOWLIM + MIN( UPPLIM - LOWLIM,
     :                                MAX( 0, NINT( W ) ) )
                  END IF
 
               END DO
            END DO
 
         ELSE
 
*       Scale the image.
 
            DO  I = 1, DIM2, 1
               DO  J = 1, DIM1, 1
 
*                Check for very large or small values beyond the
*                range of integers.  Array value is known not to
*                be bad so VAL_ is not required.
 
                  W = ( NUM_WTOD( INARR( J, I ) ) - DL ) * SCALE
 
                  IF ( W .GT. UL ) THEN
                     OUTARR( J, I ) = UPPLIM
                  ELSE IF ( W .LT. LL ) THEN
                     OUTARR( J, I ) = LOWLIM
                  ELSE
 
*                   Scale between the limits.
 
                     OUTARR( J, I ) = LOWLIM + MIN( UPPLIM - LOWLIM,
     :                                MAX( 0, NINT( W ) ) )
                  END IF
 
               END DO
            END DO
 
         END IF
      END IF
 
  999 CONTINUE
 
      END
