      SUBROUTINE CCG1_CM1DD( STACK, NPIX, NLINES, VARS, IMETH, MINPIX,
     :                         NITER, NSIGMA, ALPHA, RMIN, RMAX, RESULT,
     :                         RESVAR, WRK1, WRK2, PP, COVEC, NMAT,
     :                         NCON, POINT, USED, STATUS )
*+
*  Name:
*     CCG1_CM1DD

*  Purpose:
*     To combine a stack of array lines into one line, using a variety
*     of methods. DOUBLE PRECISION version.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_CM1DD( STACK, NPIX, NLINES, VARS, IMETH, MINPIX,
*                        NITER, NSIGMA, ALPHA, RMIN, RMAX, RESULT,
*                        RESVAR, WRK1, WRK2, PP, COVEC, NMAT, NCON,
*                        POINT, USED, STATUS )

*  Description:
*     The routine works along each line of the input stack of lines,
*     combining the data. This variant uses a variance array and
*     propagates them for each input value .  All work is done in
*     double precision Note that the output arrays are in the
*     processing precision.  The array NCON holds the actual numbers of
*     pixels which were used in deriving the output value plus any
*     values already present in the array - thus a cumilative sum of
*     contributing pixel numbers may be kept.

*  Arguments:
*     STACK( NPIX, NLINES ) = DOUBLE PRECISION (Given)
*        The array of lines which are to be combined into a single line.
*     NPIX = INTEGER (Given)
*        The number of pixels in a line of data.
*     NLINES = INTEGER (Given)
*        The number of lines of data in the stack.
*     VARS( NPIX, NLINES ) = DOUBLE PRECISION (Given)
*        The data variances.
*     IMETH = INTEGER (Given)
*        The method to use in combining the lines. Has a code of 2 to 10
*        which represent.
*        1  = UNWEIGHTED MEAN
*        2  = WEIGHTED MEAN
*        3  = MEDIAN
*        4  = TRIMMED MEAN
*        5  = MODE
*        6  = SIGMA CLIPPED MEAN
*        7  = THRESHOLD EXCLUSION MEAN
*        8  = MINMAX MEAN
*        9  = BROADENED MEDIAN
*        10 = SIGMA CLIPPED MEDIAN
*        300 = Median, but estimating variance from mean variance.
*     MINPIX = INTEGER (Given)
*        The minimum number of pixels required to contribute to an
*        output pixel.
*     NITER = INTEGER (Given)
*        The maximum number of iterations (IMETH = 5).
*     NSIGMA = REAL (Given)
*        The number of sigmas to clip the data at (IMETH = 5, 6 and 10 ).
*     ALPHA = REAL (Given)
*        The fraction of data values to remove from data (IMETH = 4).
*     RMIN = REAL (Given)
*        The minimum allowed data value (IMETH = 7).
*     RMAX = REAL (Given)
*        The maximum allowed data value (IMETH = 7).
*     RESULT( NPIX ) = DOUBLE PRECISION (Returned)
*        The output line of data.
*     RESVAR( NPIX ) = DOUBLE PRECISION (Returned)
*        The output variances.
*     WRK1( NLINES ) = DOUBLE PRECISION (Given and Returned)
*        Workspace for calculations.
*     WRK2( NLINES ) = DOUBLE PRECISION (Given and Returned)
*        Workspace for calculations.
*     PP( NLINES ) = DOUBLE PRECISION (Given and Returned)
*        Workspace for order statistics calculations.
*     COVEC( NMAT, NLINES ) = DOUBLE PRECISION (Given and Returned)
*        Workspace for storing ordered statistics variace-covariance
*        matrix. Not used for IMETHs 1, 2 or 300.
*     NCON( NLINES ) = DOUBLE PRECISION (Given and Returned)
*        The actual number of contributing pixels from each input line
*        to the output line.
*     POINT( NLINES ) = INTEGER (Given and Returned)
*        Workspace to hold pointers to the original positions of the
*        data before extraction and conversion in to the WRK1 array.
*     USED( NLINES ) = LOGICAL (Given and Returned)
*        Workspace used to indicate which values have been used in
*        estimating a resultant value.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - Various of the options are simply variations on a theme. The
*     Broadened median is just a trimmed mean with a variable trimming
*     fraction. The Mode is an iteratively carried out version of the
*     sigma clipping (or more precisely the reverse). The minmax and
*     threshold mean are also just trimmed means, but require their own
*     mechanisms.
*
*     - The 'propagation' of the input variances assumes that the input
*     data are fairly represented by a normal distribution. This fact
*     is used together with the 'order statistics' of a normal
*     population to form a new variance estimate. The order statistics
*     are not independent so have non-zero covariances (off diagonal
*     components of the variance-covariance matrix). All 'trimmed
*     means' of any description use the order of the values to
*     estimate which values are corrupt. This applies to all the
*     methods supported here except the mean which rejects no data. The
*     variance used to represent the input normal population is the
*     reciprocal of the sum of the reciprocal variances. We have no
*     other estimate of this value except from the population itself.
*
*     - NMAT = NLINES * ( NLINES + 1 )/ 2 at least.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     21-MAY-1992 (PDRAPER):
*        Original version. Revamping of routine structure to increase
*        efficiency and keep in line with new routines.
*     30-JAN-1998 (PDRAPER):
*        Added MEDCLIP method.
*     16-NOV-1998 (PDRAPER):
*        Added fast median.
*     14-DEC-2001 (DSB):
*        Added unweighted mean method.
*     1-NOV-2002 (DSB):
*        Added workspace argument to CCD1_ORVAR.
*     27-AUG-2003 (DSB):
*        Added IMETH 300 to provide a means of estimating the output
*        variances for large samples, for which the memory requirements
*        for the COVEC array would be too large.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*  Arguments Given:
      INTEGER NPIX
      INTEGER NLINES
      INTEGER IMETH
      INTEGER MINPIX
      INTEGER NMAT
      DOUBLE PRECISION STACK( NPIX, NLINES )
      DOUBLE PRECISION VARS( NPIX, NLINES )
      DOUBLE PRECISION PP( NLINES )
      INTEGER NITER
      REAL NSIGMA
      REAL ALPHA
      REAL RMIN
      REAL RMAX

*  Arguments Given and Returned:
      DOUBLE PRECISION COVEC( NMAT, NLINES )
      DOUBLE PRECISION NCON( NLINES )
      INTEGER POINT( NLINES )
      LOGICAL USED( NLINES )
      DOUBLE PRECISION WRK1( NLINES )
      DOUBLE PRECISION WRK2( NLINES )

*  Arguments Returned:
      DOUBLE PRECISION RESULT( NPIX )
      DOUBLE PRECISION RESVAR( NPIX )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER IPW1               ! Work space pointer
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If we're doing a trimmed mean derive the variance-covariance matrix
*  for the order statistics of a normal popl with up to NLINE members.
*  This also sets up the scale factor for converting mean variances to
*  median variances.
      IF( IMETH .NE. 1 .AND. IMETH .NE. 2 .AND. IMETH .NE. 300 ) THEN
          CALL PSX_CALLOC( NLINES*NLINES, '_DOUBLE', IPW1, STATUS )
          CALL CCD1_ORVAR( NLINES, NMAT, PP, COVEC, 
     :                     %VAL( CNF_PVAL( IPW1 ) ),
     :                     STATUS )
          CALL PSX_FREE( IPW1, STATUS )
      END IF

*  Now branch for each method.
      IF ( IMETH .EQ. 1 ) THEN

*  Forming the unweighted mean.
         CALL CCG1_UMD1D( STACK, NPIX, NLINES, VARS, MINPIX,
     :                      RESULT, RESVAR, NCON, STATUS )

      ELSE IF ( IMETH .EQ. 2 ) THEN

*  Forming the weighted mean.
         CALL CCG1_MED1D( STACK, NPIX, NLINES, VARS, MINPIX,
     :                      RESULT, RESVAR, NCON, STATUS )

      ELSE IF ( IMETH .EQ. 3 .OR. IMETH .EQ. 300 ) THEN

*  Forming the weighted median.
         CALL CCG1_MDD1D( ( IMETH .EQ. 3 ), STACK, NPIX, NLINES, VARS,
     :                     MINPIX, COVEC, NMAT, RESULT, RESVAR, WRK1, 
     :                     WRK2, NCON, POINT, USED, STATUS )

      ELSE IF ( IMETH .EQ. 4 ) THEN

*  Forming trimmed mean.
          CALL CCG1_TMD1D( ALPHA, STACK, NPIX, NLINES, VARS, MINPIX,
     :                       COVEC, NMAT, RESULT, RESVAR, WRK1, NCON,
     :                       POINT, USED, STATUS )

      ELSE IF ( IMETH .EQ. 5 ) THEN

*  Forming the mode.
         CALL CCG1_MOD1D( NSIGMA, NITER, STACK, NPIX, NLINES,
     :                      VARS, MINPIX, COVEC, NMAT, RESULT, RESVAR,
     :                      WRK1, WRK2, NCON, POINT, USED, STATUS )

      ELSE IF ( IMETH .EQ. 6 ) THEN

*  Forming sigma clipped mean.
         CALL CCG1_SCD1D( NSIGMA, STACK, NPIX, NLINES, VARS, MINPIX,
     :                      COVEC, NMAT, RESULT, RESVAR, WRK1, WRK2,
     :                      NCON, POINT, USED, STATUS )

      ELSE IF ( IMETH .EQ. 7 ) THEN

*  Forming threshold trimmed mean.
          CALL CCG1_TCD1D( RMIN, RMAX, STACK, NPIX, NLINES, VARS,
     :                       MINPIX, COVEC, NMAT, RESULT, RESVAR,
     :                       WRK1, WRK2, NCON, POINT, USED, STATUS )

      ELSE IF ( IMETH .EQ. 8 ) THEN

*  Forming Min-Max exclusion mean.
        CALL CCG1_MMD1D( STACK, NPIX, NLINES, VARS, MINPIX, COVEC,
     :                     NMAT, RESULT, RESVAR, WRK1, NCON, POINT,
     :                     USED, STATUS )

      ELSE IF ( IMETH .EQ. 9 ) THEN

*  Forming broadened median,
         CALL CCG1_BMD1D( STACK, NPIX, NLINES, VARS, MINPIX, COVEC,
     :                      NMAT, RESULT, RESVAR, WRK1, NCON, POINT,
     :                      USED, STATUS )

      ELSE IF ( IMETH .EQ. 10 ) THEN

*  Forming sigma clipped median.
         CALL CCG1_SMD1D( NSIGMA, STACK, NPIX, NLINES, VARS, MINPIX,
     :                      COVEC, NMAT, RESULT, RESVAR, WRK1, WRK2,
     :                      NCON, POINT, USED, STATUS )

      ELSE IF ( IMETH .EQ. 11 ) THEN

*  Forming fast median.
         CALL CCG1_FMD1D( STACK, NPIX, NLINES, VARS, MINPIX, COVEC,
     :                      NMAT, RESULT, RESVAR, WRK1, WRK2, NCON,
     :                      POINT, USED, STATUS )
      ELSE

*  Invalid method report error
         STATUS = SAI__ERROR
         CALL ERR_REP( 'BAD_METH',
     :                 'Bad method specified for image combination'//
     :                 ' ( invalid or not implemented )', STATUS )
      END IF

      END
* $Id$
