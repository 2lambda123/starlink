      SUBROUTINE KPS1_NOM1UB( EL, INARR, OLDVAL, MEAN, SIGMA, DATMIN,
     :                         DATMAX, OUTARR, NREP, STATUS )
*+
*  Name:
*     KPS1_NOM1x

*  Purpose:
*     Replaces all occurrences of a value in an array with a random
*     value.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_NOM1x( EL, INARR, OLDVAL, MEAN, SIGMA, DATMIN, DATMAX,
*                      OUTARR, NREP, STATUS )

*  Description:
*     This routine copies the input array to the output array, except
*     where a specified value occurs, and this is replaced with a
*     random sample taken from a Normal distribution with the specified
*     mean and sigma.  Samples are rejected if they fall outside the
*     numeric range of the data type, and replacement samples are
*     obtained until one is found which can be used.

*  Arguments:
*     EL = INTEGER (Given)
*        The dimension of the input and output arrays.
*     INARR( EL ) = ? (Given)
*        The input array.
*     OLDVAL = ? (Given)
*        Value to be replaced.
*     MEAN = DOUBLE PRECISION (Given)
*        Mean of the new values to be substituted for the old value.
*     SIGMA = DOUBLE PRECISION (Given)
*        Standard deviation of the new values to be substituted for the 
*        old value.
*     DATMIN = DOUBLE PRECISION (Given)
*        The minimum new value allowed.
*     DATMAX = DOUBLE PRECISION (Given)
*        The maximum new value allowed.
*     OUTARR( EL ) = ? (Returned)
*        The output array containing the modified values.
*     NREP = INTEGER (Returned)
*        The number of replacements made.
*     STATUS  =  INTEGER (Given and Returned)
*        Global status value.

*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate.  The
*     arrays and values supplied to the routine must have the data type
*     specified.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     14-DEC-1994 (DSB):
*        Original version.
*     1997 January 10 (MJC):
*        Replaced NAG calls.
*     {enter_further_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT  NONE           ! No default typing allowed

*  Global Constants:
      INCLUDE  'SAE_PAR'       ! Global SSE definitions
      INCLUDE  'PRM_PAR'       ! VAL__ constants

*  Arguments Given:
      INTEGER EL
      BYTE INARR( EL )
      BYTE OLDVAL
      DOUBLE PRECISION MEAN
      DOUBLE PRECISION SIGMA
      DOUBLE PRECISION DATMIN
      DOUBLE PRECISION DATMAX

*  Arguments Returned:
      BYTE OUTARR( EL )
      INTEGER NREP

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL PDA_RNNOR
      REAL PDA_RNNOR             ! PDA random-number generator with
                                 ! Normal distribution for one value

*  Local Constants:
      INTEGER MAXTRY
      PARAMETER ( MAXTRY = 50 )  ! Maximum number of samples to be tried

*  Local Variables:
      DOUBLE PRECISION DIFF      ! Normalised maximum difference between
                                 ! the data value and the value to change
                                 ! for them to be regarded as identical
      DOUBLE PRECISION DVAL      ! Random sample value
      DOUBLE PRECISION FPOLD     ! Floating-point value to be replaced
      DOUBLE PRECISION HILIM     ! Upper limit of output data range
      INTEGER I                  ! Loop counter
      DOUBLE PRECISION LOLIM     ! Lower limit of output data range
      INTEGER NRETRY             ! Total number of re-tries
      INTEGER NTRY               ! No. of re-tries for current pixel
      INTEGER SEED               ! Random-number seed
      INTEGER TICKS              ! Clock ticks to randomize initial seed

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! Declarations of conversion routines
      INCLUDE 'NUM_DEF_CVT'      ! Definitions of conversion routines

*.

*  Check the inherited status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Find the maximum and minimum allowable output values.
      HILIM = MIN( NUM_UBTOD( VAL__MAXUB ), DATMAX )
      LOLIM = MAX( NUM_UBTOD( VAL__MINUB ), DATMIN )

*  Report an error and abort if the high limit is less than or equal to
*  the low limit. 
      IF ( HILIM .LE. LOLIM ) THEN
         STATUS = SAI__ERROR

         IF ( 'UB' .EQ. 'B' .OR. 'UB' .EQ. 'W' .OR.
     :        'UB' .EQ. 'UB' .OR. 'UB' .EQ. 'UW' .OR.
     :        'UB' .EQ. 'I' ) THEN
            CALL MSG_SETI( 'HI', NUM_DTOI( HILIM ) )
            CALL MSG_SETI( 'LO', NUM_DTOI( LOLIM ) )

         ELSE IF ( 'UB' .EQ. 'R' ) THEN
            CALL MSG_SETR( 'HI', NUM_DTOR( HILIM ) )
            CALL MSG_SETR( 'LO', NUM_DTOR( LOLIM ) )

         ELSE 
            CALL MSG_SETD( 'HI', HILIM )
            CALL MSG_SETD( 'LO', LOLIM )

         END IF

         CALL ERR_REP( 'KPS1_NOM1x_ERR1', 'Upper limit for new values'/
     :     /'(^LO) (programming error in KPS1_NOM1x.GEN).', STATUS )
         GOTO 999

      END IF

*  Initialise the random number generator seed to a non-repeatable
*  value.
      CALL PSX_TIME( TICKS, STATUS )
      SEED = ( TICKS / 4 ) * 4 + 1
      CALL PDA_RNSED( SEED )

*  To avoid testing two floating-point values for equality, they are
*  tested to be different by less than a small fraction of the value to
*  be replaced.  The machine precision defines the minimum detectable
*  difference.
      FPOLD = 0.5 * NUM_UBTOD( OLDVAL )
      DIFF = ABS( FPOLD * VAL__EPSD )

*  Initialise the number of replacements made so far, and the total
*  number of re-tries.
      NREP = 0
      NRETRY = 0

*  Loop through all the pixels.
      DO I = 1, EL

*  The halving is done to prevent overflows.
         IF ( ABS( ( NUM_UBTOD( INARR( I ) ) * 0.5 )
     :        - FPOLD ) .LE. DIFF ) THEN

*  A match has been found.  Get a random sample from a normal
*  distribution to replace it.
            DVAL = DBLE( PDA_RNNOR( MEAN, SIGMA ) )

*  Check that this sample is within the allowed data range.  If it is
*  not, get a new one.  Quit after MAXTRY attempts have been made to
*  get a value within the allowed range.
            NTRY = 1
            DO WHILE ( ( DVAL .GE. HILIM .OR. DVAL .LE. LOLIM ) .AND.
     :                 NTRY .LT. MAXTRY )
               NTRY = NTRY + 1            
               DVAL = DBLE( PDA_RNNOR( MEAN, SIGMA ) )
            END DO

*  Report an error an abort if too many attempts have been made to get
*  a usable value.
            IF ( NTRY .EQ. MAXTRY ) THEN
               STATUS = SAI__ERROR
               CALL MSG_SETI( 'NTRY', NTRY )
               CALL ERR_REP( 'KPS1_NOM1x_ERR2', 'Cannot find a random'/
     :           /' value within the allowed data range.  '/
     :           /'Giving up after ^NTRY attempts.', STATUS )
               GO TO 999
            END IF

*  Increment the total number of re-tries.
            NRETRY = NRETRY + NTRY - 1

*  Store the sample value, and increment the count of replaced pixels.
            OUTARR( I ) = NUM_DTOUB( DVAL )
            NREP = NREP + 1

*  If there is no match, copy the value to the output array.
         ELSE
            OUTARR( I ) = INARR( I )

         END IF

      END DO

*  Tell the user how many re-tries were done.
      IF ( NRETRY .EQ. 1 ) THEN
         CALL MSG_BLANK( STATUS )
         CALL MSG_OUT( 'KPS1_NOM1X_MSG1', '  1 re-try made to '/
     :                 /'obtain a random value within the allowable '/
     :                 /'data range.', STATUS )

      ELSE IF ( NRETRY .GT. 1 ) THEN
         CALL MSG_BLANK( STATUS )
         CALL MSG_SETI( 'N', NRETRY )
         CALL MSG_OUT( 'KPS1_NOM1X_MSG1', '  ^N re-tries made to'/
     :                 /' obtain random values within the allowable '/
     :                 /'data range.', STATUS )

      END IF

 999  CONTINUE

      END
