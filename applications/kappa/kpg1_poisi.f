      SUBROUTINE KPG1_POISI( EL, VALUES, SEED, STATUS )
*+
*  Name:
*     KPG1_POISx
 
*  Purpose:
*     Takes values and returns them with Poisson noise added.
 
*  Language:
*     Starlin Fortran 77
 
*  Invocation:
*     CALL KPG1_POISx( EL, VALUES, SEED, STATUS )
 
*  Description:
*     This routine adds or subtracts pseudo-random Poissonian (shot)
*     noise to a series of values.  It uses a Box-Mueller algorithm to
*     generate a fairly good normal distribution.
 
*  Arguments:
*     EL = INTEGER (Given)
*        The number of values to which to add Poisson noise.
*     VALUES( EL )  =  ? (Given and Returned)
*        On input these are the value to which noise is to be applied.
*        On return the values have the noise applied.
*     SEED  =  REAL (Given & Returned)
*        The seed for random number generator; updated by the
*        random-number generator.
*     STATUS = INTEGER (Given)
*        Global status value.
 
*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate. The
*     array supplied to the routine must have the data type specified.
*     -  There is no checking for overflows.
*     -  Bad values remain bad in the returned array.
 
*  Algorithm:
*     -  Loop until a suitable random number (in range 0-1) is found).
*     Get two uncorrelated random numbers from the seed.  Get another
*     from these that lies in the range 0--1.  If it lies in the range
*     add it to input value.
 
*  Implementation Deficiencies:
*     Has to overcome the bug that odd and even random numbers
*     generated are correlated when using the Vax-specific RAN (called
*     by SLA_RANDOM).
 
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     1991 May 28 (MJC):
*        Original version based on POISSN.
*     1992 April 1 (MJC):
*        Made to work on an array in situ.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_new_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT  NONE            ! No implicit typing allowed
 
*  Global Constants:
      INCLUDE  'SAE_PAR'        ! SSE global definitions
      INCLUDE  'PRM_PAR'        ! PRIMDAT public constants
 
*  Arguments Given:
      INTEGER EL
 
*  Arguments Given and Returned:
      INTEGER VALUES( EL )
 
      INTEGER SEED
 
*  Status:
      INTEGER  STATUS           ! Global status
 
*  External References:
      REAL SLA_RANDOM
 
*  Local Variables:
      DOUBLE PRECISION NOISE    ! Noise to be added.
 
      INTEGER I                 ! Loop counter
 
                                ! True if:
      LOGICAL FINSHD            ! Flag variable used to check that a
                                ! valid random number has been
                                ! generated
      REAL R                    ! Random number used by algorithm
      REAL RA                   ! Random number used by algorithm
      REAL RB                   ! Random number used by algorithm
      REAL RR                   ! Random number used by algorithm
 
*  Internal References:
      INCLUDE 'NUM_DEC_CVT'     ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'     ! NUM definitions for conversions
 
*.
 
*  Check the inherited status.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Loop for all values.
      DO I = 1, EL
 
*  Noise cannot be added to bad data.
         IF ( VALUES( I ) .NE. VAL__BADI ) THEN
 
*  Initialise completion flag.
            FINSHD  =  .FALSE.
 
*  Loop until a valid random number has been generated.
            DO WHILE ( .NOT. FINSHD )
 
*  Generate two uncorrelated random numbers between -1 and 1.
               RA  =  -1.0 + 2.0 * SLA_RANDOM( SEED )
               RA  =  -1.0 + 2.0 * SLA_RANDOM( SEED )
               RB  =  -1.0 + 2.0 * SLA_RANDOM( SEED )
               RB  =  -1.0 + 2.0 * SLA_RANDOM( SEED )
 
*  Obtain another from these that will lie between 0 and 2.
               RR  =  RA * RA + RB * RB
 
*  Accept only those that lie between 0 and 1, otherwise start again.
               IF ( RR. GT. 0.0 .AND. RR .LT. 1.0 ) THEN
 
*  Generate the Box-Mueller transform.  Assume the noise is the square
*  root the value. Have to convert the numbers to floating-point for
*  square root.
                  R  =  SQRT( -2.0  *  ALOG( RR ) / RR )
                  NOISE = DBLE( RA ) * DBLE( R ) *
     :                    SQRT( NUM_ITOD( VALUES( I ) ) )
                  VALUES( I )  =  NUM_DTOI( NOISE ) + VALUES( I )
 
* Set the finished flag to exit now.
                  FINSHD  =  .TRUE.
 
               END IF
            END DO
 
         END IF
      END DO
 
      END
