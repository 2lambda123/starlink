      SUBROUTINE KPG1_HSTFD( NUMBIN, HISTOG, MAXMUM, MINMUM, NFRAC,
     :                         FRAC, VALUES, STATUS )
*+
*  Name:
*     KPG1_HSTFx
 
*  Purpose:
*     Finds values corresponding to specified fractions of an histogram.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL KPG1_HSTFx( NUMBIN, HISTOG, MAXMUM, MINMUM, NFRAC, FRAC,
*                      VALUES, STATUS )
 
*  Description:
*     This routine finds the values at defined fractions of an
*     histogram.  Thus to find the lower-quartile value, the fraction
*     would be 0.25.  Since an histogram technique is used rather than
*     sorting the whole array, the result may not be exactly correct.
*     An histogram with a large number of bins, and the use of linear
*     interpolation between bins in the routine reduce the error.
 
*  Arguments:
*     NUMBIN = INTEGER (Given)
*        The number of histogram bins.  The larger the number of bins
*        the greater the accuracy of the results.  1000 to 10000 is
*        recommended.
*     HISTOG( NUMBIN ) = INTEGER (Given)
*        The histogram.
*     MAXMUM = ? (Given)
*        The maximum value used to evaluate the histogram.
*     MINMUM = ? (Given)
*        The minimum value used to evaluate the histogram.
*     NFRAC = INTEGER (Given)
*        Number of fractional positions.
*     FRAC( NFRAC ) = REAL (Given and Returned)
*        Fractional positions in the histogram in the range 0.0--1.0.
*        On exit they are arranged into ascending order.
*     VALUES( NFRAC ) = ? (Returned)
*        Values corresponding to the ordered fractional positions in
*        the histogram.
*     STATUS = INTEGER (Given & Returned)
*        Global status value.
 
*  Notes:
*     -  There is a routine for real and double-prcision data types:
*     replace "x" in the routine name by R or D as appropriate.  The
*     arguments MAXMUM, MINMUM, and VALUES must have the data type
*     specified.
 
*  Algorithm:
*     -  Compute number of points forming the histogram.  Sort the
*     fractions. Decide whether to forward or reverse search.
*     -  For all fractions of the histogram supplied:
*        o  Calculate the number of data points corresponding to the
*        current fraction, counting up or down depending on the search
*        direction.
*        o  Count through the histogram until the current point is just
*        past; at the same time store the number of pixels summed up to
*        previous histogram bin
*        o Interpolate in the current bin using previous and current
*        pixel sum.
*        o Value corresponding to current point is stored in output
*        array by evaluation of the histogram
 
*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1991 November 13 (MJC):
*        Original version based on HSTFR.  Uses double precision limits
*        and values so that it may be used in conjunction with generic
*        routines.
*     1992 June 3 (MJC):
*        Replaced NAG routine by KAPPA sorting routine.  Although the
*        latter is slower it is available on Unix.
*     1992 July 30 (MJC):
*        Fixed bug that occurred when lowest fraction is greater than
*        0.8 and a fraction was equivalent to the maximum data value.
*        Added handling for zero and one fractions to eliminate any
*        rounding for these special cases.
*     1994 September 27 (MJC):
*        Sorted variables and used modern comment indentation.
*     1995 May 2 (MJC):
*        Made generic and renamed from KPG1_HSTFR.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! Machine-precision constants
 
*  Arguments Given:
      DOUBLE PRECISION MAXMUM              ! Maximum value used to evaluate the
                                 ! histogram
      DOUBLE PRECISION MINMUM              ! Maximum value used to evaluate the
                                 ! histogram
      INTEGER NFRAC              ! Number of fractions to be estimated
      INTEGER NUMBIN             ! Number of bins in histogram
      INTEGER HISTOG( NUMBIN )   ! Histogram
 
*  Arguments Given and Returned:
      REAL FRAC( NFRAC )         ! The fractions of the histogram
 
*  Arguments Returned:
      DOUBLE PRECISION VALUES( NFRAC )     ! The data values at the
                                 ! given fractions of the histogram
*  Status:
      INTEGER  STATUS            ! Global status
 
*  Local Variables:
      DOUBLE PRECISION BIN                ! Histogram bin width
      INTEGER I                  ! Counter
      REAL INTFRA                ! Interpolation fraction within last
                                 ! histogram bin
      INTEGER J                  ! Counter
      INTEGER LIMIT              ! Number in data values equivalent to
                                 ! the fraction
      INTEGER LIMITU             ! Complement of LIMIT
      INTEGER N                  ! Number of pixels summed so far
      INTEGER NVALUE             ! Number of values in the histogram
      INTEGER PREV               ! Number of pixels summed up to previous
                                 ! histogram bin
      DOUBLE PRECISION THRESH             ! Threshold for identical-limits test
      REAL TOTAL                 ! Total number of values in the histogram
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions
 
*.
 
*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Set the minimum separation allowed for the data limits such that
*  each of the histogram bins is resolvable.  The halving prevents
*  arithmetic overflow for data with a very large dynamic range.
      THRESH = ( ABS( MAXMUM ) / 2.0D0 + ABS( MINMUM ) / 2.0D0 ) *
     :         VAL__EPSD * NUM_ITOD( NUMBIN )
 
*  If the maximum effectively equals minimum, o ordered statistics are
*  meaningless, so abort.
      IF ( ABS( MAXMUM / 2.0D0 - MINMUM / 2.0D0 ) .LT. THRESH )
     :  THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'KPG1_HSTFx_MXEQMN',
     :     'Maximum value equals minimum.  Ordered statistics cannot '/
     :     /'be computed.', STATUS )
         GOTO 999
      END IF
 
*  Get the number of values used to form the histogram.
      NVALUE = 0
      DO  I = 1, NUMBIN
         NVALUE = NVALUE + HISTOG( I )
      END DO
 
*  Need at least three values before even a median has any sense.
      IF ( NVALUE .LT. 3 ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'KPG1_HSTFx_TOOFEW',
     :     'There are too few values to compute ordered statistics.',
     :     STATUS )
         GOTO 999
      END IF
 
*  Compute the binsize.
      BIN = ( MAXMUM - MINMUM ) / NUM_ITOD( NUMBIN )
      TOTAL = REAL( NVALUE )
 
*  Sort the fractions into ascending order.
      CALL KPG1_QSRTR( NFRAC, 1, NFRAC, FRAC, STATUS )
      IF ( STATUS .NE. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL ERR_REP( 'HSTFR__SORT',
     :     'Unable to find values corresponding to specified '/
     :     /'fractions of the histogrammed data.', STATUS )
         GOTO 999
      END IF
 
*  Decide whether to go forwards or backwards.  The two cases are used
*  for efficiency.  The search is always to the 80 percentile.  This
*  assumes most astronomical data, particularly images, are positively
*  skewed.
 
*  Forwards...
      IF ( FRAC( 1 ) .LT. 0.8 ) THEN
 
*  Initialise the counters.
         J = 0
         N = 0
 
*  Consider each fractional value in the histogram.
         DO  I = 1, NFRAC
 
*  Look for the special case of zero fraction, i.e. the minimum value.
            IF ( FRAC( I ) .LT. VAL__EPSR ) THEN
               VALUES( I ) = MINMUM
 
*  Look for the special case of no fraction, i.e. the minimum value.
            ELSE IF ( ( 1.0 - FRAC( I ) ) .LT. VAL__EPSR ) THEN
               VALUES( I ) = MAXMUM
 
*  Calculate the number of data points corresponding to the required
*  fraction.  There must be at least one count.
            ELSE
               LIMIT = MAX( 1, NINT( TOTAL * FRAC( I ) ) )
 
*  Count through the histogram to find this point.
               DO WHILE ( N .LT. LIMIT )
                  J = J + 1
                  PREV = N
                  N = N + HISTOG( J )
               END DO
 
*  Interpolate to obtain a more-accurate pixel value.
               INTFRA = REAL( LIMIT - PREV ) / REAL( N - PREV )
               VALUES( I ) = MINMUM + BIN *
     :                       NUM_RTOD( REAL( J - 1 ) + INTFRA )
            END IF
         END DO
      ELSE
 
*  Initialise the counters.
         J = NUMBIN + 1
         N = NVALUE
 
*  Consider each fractional value in the histogram.
         DO  I = NFRAC, 1, -1
 
*  Look for the special case of no fraction, i.e. the minimum value.
            IF ( ( 1.0 - FRAC( I ) ) .LT. VAL__EPSR ) THEN
               VALUES( I ) = MAXMUM
 
*  Calculate the number of data points corresponding to the required
*  fraction.
            ELSE
               LIMIT = NINT( TOTAL * FRAC( I ) )
               LIMITU = NVALUE - LIMIT
 
*  Count backwards through the histogram to find this point.
               DO WHILE ( N .GE. LIMIT )
                  J = J - 1
                  PREV = N
                  N = N - HISTOG( J )
               END DO
 
*  Interpolate to obtain a more-accurate pixel value.
               INTFRA = 1.0 - ( REAL( LIMITU - ( NVALUE - PREV ) ) ) /
     :                  REAL( HISTOG( J ) )
 
               VALUES( I ) = MINMUM + BIN *
     :                       NUM_RTOD( REAL( J - 1 ) + INTFRA )
            END IF
         END DO
      END IF
 
  999 CONTINUE
 
      END
