      SUBROUTINE CCG1_SCR3R( NSIGMA, STACK, NPIX, NLINES, VARS,
     :                         MINPIX, RESULT, WRK1, WRK2, NCON, POINT,
     :                         USED, STATUS )
*+
*  Name:
*     CCG1_SCR3

*  Purpose:
*     Combines data lines using a sigma clipped mean.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_SCR3( NSIGMA, STACK, NPIX, NLINES, VARS, MINPIX,
*                     RESULT, WRK1, WRK2, NCON, POINT, USED, STATUS )

*  Description:
*     This routine accepts an array consisting a series of
*     (vectorised) lines of data. The weighted mean and standard
*     deviation of each input column in STACK is then used to estimate
*     the range of values which represent the required sigma
*     clipping. The standard deviation is derived from the population
*     of values at each position along the lines (c.f. each image
*     pixel). Values outside of this range are then rejected and the
*     resulting output mean values are returned in the array RESULT.
*
*     Note that clipping will not be used when only two or three
*     values are available (unless in the case of 3 values NSIGMA
*     is less than 1.0).

*  Arguments:
*     NSIGMA = REAL (Given)
*        The number of sigma at which to reject data values.
*     STACK( NPIX, NLINES ) = REAL (Given)
*        The array of lines which are to be combined into a single line.
*     NPIX = INTEGER (Given)
*        The number of pixels in a line of data.
*     NLINES = INTEGER (Given)
*        The number of lines of data in the stack.
*     VARS( NLINES ) = DOUBLE PRECISION (Given)
*        The variance to to used for each line of data. These are
*        used as inverse weights when forming the mean and do not
*        need to be real variances, as they are not propagated.
*     MINPIX = INTEGER (Given)
*        The minimum number of pixels required to contribute to an
*        output pixel.
*     RESULT( NPIX ) = REAL (Returned)
*        The output line of data.
*     WRK1( NLINES ) = REAL (Given and Returned)
*        Workspace for calculations.
*     WRK2( NLINES ) = REAL (Given and Returned)
*        Workspace for calculations.
*     NCON( NLINES ) = DOUBLE PRECISION (Given and Returned)
*        The actual number of contributing pixels.
*     POINT( NLINES ) = INTEGER (Given and Returned)
*        Workspace to hold pointers to the original positions of the
*        data before extraction and conversion in to the WRK1 array.
*     USED( NLINES ) = LOGICAL (Given and Returned)
*        Workspace used to indicate which values have been used in
*        estimating a resultant value.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     19-MAY-1992 (PDRAPER):
*        Original version.
*     31-JAN-1998 (PDRAPER):
*        Modified to derive a standard deviation estimate from the
*        data values rather than assuming that the input "variances"
*        are typical for each line. This was never the case.
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
      REAL NSIGMA
      INTEGER NPIX
      INTEGER NLINES
      INTEGER MINPIX
      REAL STACK( NPIX, NLINES )
      DOUBLE PRECISION VARS( NLINES )

*  Arguments Given and Returned:
      DOUBLE PRECISION NCON( NLINES )
      REAL WRK1( NLINES )
      REAL WRK2( NLINES )

*  Arguments Returned:
      REAL RESULT( NPIX )
      LOGICAL USED( NLINES )
      INTEGER POINT( NLINES )

*  Status:
      INTEGER STATUS             ! Global status

*  Global Variables:
      INCLUDE 'NUM_CMN'          ! Numerical error flag

*  External References:
      EXTERNAL NUM_TRAP
      INTEGER NUM_TRAP           ! Numerical error handler

*  Local Variables:
      INTEGER I                  ! Loop variable
      INTEGER J                  ! Loop variable
      DOUBLE PRECISION VAL       ! Weighted mean
      DOUBLE PRECISION VAR       ! Population variance before rejection
      DOUBLE PRECISION SUM1      ! Weight sums
      DOUBLE PRECISION SUM2      ! Weighted value sums
      REAL RVAL1                 ! Dummy REAL value
      REAL RVAL2                 ! Dummy REAL value
      INTEGER NGOOD              ! Number of good pixels
      INTEGER IGOOD              ! Number of unrejected pixels

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM_ type conversion functions
      INCLUDE 'NUM_DEF_CVT'      ! Define functions...

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Set the numeric error and set error flag value.
      CALL NUM_HANDL( NUM_TRAP )

*  Loop over for all possible output pixels.
      DO 1 I = 1, NPIX
         NGOOD = 0
         NUM_ERROR = SAI__OK
         SUM1 = 0.0D0
         SUM2 = 0.0D0

*  Loop over all possible contributing pixels.
         DO 2 J = 1, NLINES
            IF( STACK( I, J ) .NE. VAL__BADR ) THEN

*  Increment good value counter.
               NGOOD = NGOOD + 1

*  Update the pointers to the positions of the unextracted data.
               POINT( NGOOD ) = J

*  Convert input type to floating point value.
               RVAL1 = NUM_RTOR( STACK( I, J ) )

*  Change variance to weight.
               VAR = 1.0D0 / VARS( J )

*  Increment sums.
               SUM2 = SUM2 + DBLE( RVAL1 ) * VAR
               SUM1 = SUM1 + VAR

*  Transfer values to working buffers.
               WRK1( NGOOD ) = RVAL1
               WRK2( NGOOD ) = REAL( VAR )

*  Set USED buffer in case no values are rejected.
               USED( NGOOD ) = .TRUE.

*  Finally trap numeric errors by rejecting all values.
               IF ( NUM_ERROR .NE. SAI__OK ) THEN

*  Decrement NGOOD, do not let it go below zero.
                  NGOOD = MAX( 0, NGOOD - 1 )
                  NUM_ERROR = SAI__OK
               END IF
            END IF
 2       CONTINUE

*  Continue if more than one good value.
         IF ( NGOOD .GT. 0 ) THEN
            IF ( NGOOD .EQ. 1 ) THEN 
               VAL = WRK1( 1 ) 
            ELSE

*  Form the weighted mean and population variance.
               VAL = SUM2 / SUM1
               SUM1 = 0.0D0
               DO 5 J = 1, NGOOD 
                  RVAL1 = REAL( VAL ) - WRK1( J )
                  SUM1 = SUM1 + DBLE( RVAL1 * RVAL1 )
 5             CONTINUE
               VAR = SUM1 / DBLE( NGOOD - 1 )

*  Clipping range.
               RVAL1 = REAL( VAL - DBLE( NSIGMA ) * SQRT( VAR ) )
               RVAL2 = REAL( VAL + DBLE( NSIGMA ) * SQRT( VAR ) )

*  Clip unwanted data.
               CALL CCG1_CLIPR( WRK1, NGOOD, RVAL1, RVAL2, IGOOD, STATUS
     : )

*  If any values have been rejected then form new mean.
               IF ( IGOOD .GT. 0 ) THEN
                  IF ( NGOOD .NE. IGOOD ) THEN

*  New mean required.
                     SUM1 = 0.0D0
                     SUM2 = 0.0D0
                     DO 3 J = 1, NGOOD
                        IF( WRK1( J ) .NE. VAL__BADR ) THEN
                           
*  Increment sums.
                           SUM2 = SUM2 + DBLE( WRK1( J ) * WRK2( J ) )
                           SUM1 = SUM1 + DBLE( WRK2( J ) )
                           USED( J ) = .TRUE.
                        ELSE
                           USED( J ) = .FALSE.
                        END IF
 3                   CONTINUE

*  New mean.
                     VAL = SUM2 / SUM1
                  END IF

*  Increment line used buffer.
                  DO 4 J = 1, NGOOD
                     IF ( USED ( J ) ) THEN
                        NCON( POINT( J ) ) = NCON( POINT( J ) ) + 1.0D0
                     END IF
 4                CONTINUE

*  Trap occasions when all values are rejected.
               ELSE
                  NGOOD = 0
               END IF
            END IF
         END IF

*  If there are sufficient good pixels output the result.
         IF ( NGOOD .GE. MINPIX ) THEN
            RESULT( I ) = REAL( VAL )

*  Trap numeric errors.
            IF ( NUM_ERROR .NE. SAI__OK ) THEN
               RESULT( I ) = VAL__BADR
            END IF
         ELSE

*  Not enough contributing pixels, set output invalid.
            RESULT( I ) = VAL__BADR
         END IF
 1    CONTINUE

*  Remove the numerical error handler.
      CALL NUM_REVRT

      END
* $Id$
