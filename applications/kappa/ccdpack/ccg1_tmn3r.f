      SUBROUTINE CCG1_TMN3R( IGNORE, ORDDAT, NSET, USED, TMEAN,
     :                         STATUS )
*+
*  Name:
*     CCG1_TMN3R

*  Purpose:
*     To form the n-trimmed mean of the given set of ordered data.
*     This variant does not process variances.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_TMN2R( IGNORE, ORDDAT, NSET, USED, TMEAN, STATUS )

*  Description:
*     The routine forms the trimmed mean of the given dataset. The
*     IGNORE upper and lower ordered values are removed from
*     consideration.  Then the remaining values are added and averaged.
*     The values not rejected are indicated by setting the flags
*     in array used.

*  Arguments:
*     IGNORE = INTEGER (Given)
*        The number of values to ignore from the upper and lower orders.
*     ORDDAT( NSET ) = REAL (Given)
*        The set of ordered data for which a trimmed mean is required.
*     NSET = INTEGER (Given)
*        The number of entries in ORDDAT.
*     USED( NSET ) = LOGICAL (Returned)
*        Flags showing which values have not been rejected.
*     TMEAN = DOUBLE PRECISION (Returned)
*        The trimmed mean.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     28-MAR-1991 (PDRAPER):
*        Original version.
*     4-APR-1991 (PDRAPER):
*        Changed to remove n values from upper and lower orders
*        instead of a given fraction.
*     30-MAY-1991 (PDRAPER):
*        Added used array.
*     20-AUG-1991 (PDRAPER):
*        Variant of CCG1_TMN2 - variance analysis removed.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants

*  Arguments Given:
      INTEGER IGNORE
      INTEGER NSET
      REAL ORDDAT( NSET )

*  Arguments Returned:
      DOUBLE PRECISION TMEAN
      LOGICAL USED( NSET )

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER I                  ! Loop variables
      INTEGER NLEFT              ! Number of values left to process
      INTEGER LBND               ! Lower index of used values
      INTEGER UBND               ! Upper index of used values

*  Local references:
      INCLUDE 'NUM_DEC_CVT'
      INCLUDE 'NUM_DEF_CVT'      ! Primdat conversion definition
                                 ! functions
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Make sure that there are enough variables left after ignoring the
*  outer ones. If there are not set output values bad and set used to
*  all false.
      NLEFT = NSET - 2 * IGNORE
      IF ( NLEFT .LE. 0 ) THEN
         TMEAN = VAL__BADD
         DO 4 I = 1, NSET
            USED( I ) = .FALSE.
 4       CONTINUE
      ELSE

*  Set the bounds
         LBND = IGNORE + 1
         UBND = NSET - IGNORE

*  Loop over all values forming the sum of values for trimmed mean.
*  Set used flags
         TMEAN = 0.0D0
         DO 1 I = 1, NSET
            IF( I .GE. LBND .AND. I .LE. UBND ) THEN
               TMEAN = NUM_RTOD( ORDDAT( I ) ) + TMEAN
               USED( I ) = .TRUE.
            ELSE
               USED( I ) = .FALSE.
            END IF
 1       CONTINUE
         TMEAN = TMEAN / DBLE( NLEFT )

      END IF
99    END
* $Id$
