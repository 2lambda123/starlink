      SUBROUTINE KPG1_EXPOI( BAD, EL, INARR, VAR, INVAR, BASE, OUTARR,
     :                       OUTVAR, NERR, NERRV, STATUS )
*+
*  Name:
*     KPG1_EXPOx

*  Purpose:
*     Takes the exponential to an arbitrary base of an array and its
*     variance.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_EXPOx( BAD, EL, INARR, VAR, INVAR, BASE, OUTARR,
*                      OUTVAR, NERR, NERRV, STATUS )

*  Description:
*     This routine fills the output array pixels with the results
*     of taking the exponential of the pixels of the input array
*     to the base specified, i.e. New_value = Base ** Old_value.
*     If the result is bigger than the maximum-allowed value
*     then a bad pixel value is substituted in the output array.
*
*     If variance is present it is computed as:                 2
*         New_Variance = Old_Variance * ( New_value * log Base )

*  Arguments:
*     BAD = LOGICAL (Given)
*        Whether to check for bad values in the input array.
*     EL = INTEGER (Given)
*        Number of elements in the input output arrays.
*     INARR( EL ) = ? (Given)
*        Array containing input image data.
*     VAR = LOGICAL (Given)
*        If .TRUE., there is a variance array to process.
*     INVAR( EL ) = ? (Given)
*        Array containing input variance data, when VAR = .TRUE..
*     BASE = DOUBLE PRECISION (Given)
*        Base of exponential to be used.  It must be a positive number.
*     OUTARR( EL ) = ? (Write)
*        Array containing results of processing the input data.
*     OUTVAR( EL ) = ? (Write)
*        Array containing results of processing the input variance
*        data, when VAR = .TRUE..
*     NERR = INTEGER (Returned)
*        Number of numerical errors which occurred while processing the
*        data array.
*     NERRV = INTEGER (Returned)
*        Number of numerical errors which occurred while processing the
*        variance array, when VAR = .TRUE..
*     STATUS = INTEGER (Given)
*        Global status value

*  Notes:
*     -  There is a routine for each numeric data type: replace "x" in
*     the routine name by D, R, I, W, UW, B or UB as appropriate.  The
*     arrays supplied to the routine must have the data type specified.

*  Copyright:
*     Copyright (C) 1997 Central Laboratory of the Research Councils.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     MJC: Malcolm Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1997 November 6 (MJC):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_new_bugs_here}

*-

*  Type Definitions:
      IMPLICIT  NONE             ! No implicit typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! SSE global definitions
      INCLUDE 'PRM_PAR'          ! PRIMDAT public constants

*  Arguments Given:
      LOGICAL BAD
      INTEGER EL
      INTEGER INARR( EL )
      LOGICAL VAR
      INTEGER INVAR( EL )
      DOUBLE PRECISION BASE

*  Arguments Returned:
      INTEGER OUTARR( EL )
      INTEGER OUTVAR( EL )
      INTEGER NERR
      INTEGER NERRV

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      DOUBLE PRECISION LBASE2    ! Log(base) squared
      INTEGER J                  ! Counter variable
      INTEGER MAXVAL             ! Maximum valid pixel value allowed
                                 ! for exponentiation
      DOUBLE PRECISION MAXV      ! Maximum value for the data type
      INTEGER MAXVAR             ! Maximum valid variance value allowed
                                 ! for exponentiation
      DOUBLE PRECISION MINV      ! Minimum value for the data type
      INTEGER MINVAL             ! Minimum valid pixel value allowed
                                 ! for exponentiation
      LOGICAL POSCHK             ! True if the danger is from large 
                                 ! positive pixels, as opposed to large
                                 ! negative ones

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM_ type conversion functions
      INCLUDE 'NUM_DEF_CVT'      ! Define functions...

*.

*  Check the iherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Validate the base.
      IF ( BASE .LE. 0.0D0 ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETD( 'BASE', BASE )
         CALL ERR_REP( 'KPG1_EXPOx_1',
     :     'Base for exponentiation is ^BASE.  It must be positive.',
     :     STATUS )
         GOTO 999
      END IF

*  Initialise returned counters.
      NERR = 0
      NERRV = 0

*  Define a couple of useful variables.
      MINV = NUM_ITOD( VAL__MINI )
      MAXV = NUM_ITOD( VAL__MAXI )

*  Proceed according to supplied base.
      IF ( BASE .LT. 1.0D0 ) THEN

*  The danger pixel values are large negative ones.  Work out the
*  limiting pixel value within the allowed range for the data type.
*  This check is not fullproof, especially for double precision
*  and bases close to 1, but it should protect the vast majority
*  of cases, and saves testing pixel by pixel.
         MINVAL = NUM_DTOI( MIN( MAXV, MAX( MINV,
     :            LOG( MINV ) / LOG( BASE ) ) ) )

*  Set positive-checking flag false, i.e. we will be checking for
*  excessively negative values.
         POSCHK  =  .FALSE.

      ELSE IF ( BASE .GT. 1.0 ) THEN

*  Large positive pixel values will cause problems.  Work out the
*  limiting pixel value within the allowed range for the data type.
*  This check is not fullproof, especially for double precision
*  and bases close to 1, but it should protect the vast majority
*  of cases, and saves testing pixel by pixel.
         MAXVAL = NUM_DTOI( MIN( MAXV, MAX( MINV,
     :            LOG( MAXV ) / LOG( BASE ) ) ) )

*  Set positive-checking flag to true.
         POSCHK  =  .TRUE.

*  Last case is base is one.
      ELSE

*  Any pixel value is fine as 1**anything = 1.  So set the limit to
*  a large number.
         MAXVAL  =  VAL__MAXI

*  Set positive-checking flag to true, just to define a value.
         POSCHK  =  .TRUE.

      END IF

*  For variance only postive values are possible.
      IF ( VAR ) THEN

*  Set up a useful constant.
         LBASE2 = LOG( BASE ) * LOG( BASE ) 

*  Large positive variance values will cause problems.  Work out the
*  limiting pixel value within the allowed range for the data type.
*  This is only approximate because it depends on the output value too.
         MAXVAR = NUM_DTOI( MIN( MAXV, MAX( MINV,
     :            0.5D0 * LOG( MAXV ) / LOG( BASE ) ) ) )
      END IF

*  Processing depends on value of flags for limit checking, presence
*  of bad pixels, and whether to process variance.

*  Positive-limit check.
*  =====================
      IF ( POSCHK ) THEN

*  We will be checking for pixel values larger than the calculated
*  positive maximum.

*  Bad-pixels may be present.
*  --------------------------
         IF ( BAD ) THEN

*  Now loop round all the pixels of the output image.
            DO J = 1, EL

*  Propagate a bad pixel.
               IF ( INARR( J ) .EQ. VAL__BADI ) THEN
                  OUTARR( J ) = VAL__BADI
 
*  Check current pixel value.
               ELSE IF ( INARR( J ) .GE. MAXVAL ) THEN

*  Exponentiated value would cause an overflow.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                  OUTARR( J ) = VAL__BADI
                  NERR = NERR + 1

               ELSE

*  Input array pixel is good.  Compute the output variance.
                  OUTARR( J ) = NUM_DTOI( BASE ** 
     :                          NUM_ITOD( INARR( J ) ) )

               END IF
            END DO

*  Variance is present.
*  --------------------
            IF ( VAR ) THEN

*  Now loop round all the pixels of the output image.
               DO J = 1, EL

*  Propagate a bad pixel.
                  IF ( INVAR( J ) .EQ. VAL__BADI .OR.
     :                  OUTARR( J ) .EQ. VAL__BADI ) THEN
                     OUTVAR( J ) = VAL__BADI
 
*  Check current pixel variance.
                  ELSE IF ( INVAR( J ) .GE. MAXVAR ) THEN

*  Exponentiated value would cause an overflow.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                     OUTARR( J ) = VAL__BADI
                     NERRV = NERRV + 1

                  ELSE

*  Input variance pixel is good.  Compute the output variance.
                     OUTVAR( J ) = NUM_DTOI( LBASE2 * 
     :                             NUM_ITOD( OUTARR( J ) ) *
     :                             NUM_ITOD( OUTARR( J ) ) *
     :                             NUM_ITOD( INVAR( J ) ) )

                  END IF
               END DO
            END IF

*  No bad pixels are present.
*  --------------------------
         ELSE

*  Now loop round all the pixels of the output image.
            DO J = 1, EL

*  Check current pixel value.
               IF ( INARR( J ) .GE. MAXVAL ) THEN

*  Exponentiated value would cause an overflow.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                  OUTARR( J ) = VAL__BADI
                  NERR = NERR + 1

               ELSE

*  Input array pixel is good.  Compute the output variance.
                  OUTARR( J ) = NUM_DTOI( BASE ** 
     :                          NUM_ITOD( INARR( J ) ) )

               END IF
            END DO

*  Variance is present.
*  --------------------
            IF ( VAR ) THEN

*  Now loop round all the pixels of the output image.
               DO J = 1, EL

*  Check current pixel variance.
                  IF ( INVAR( J ) .GE. MAXVAR ) THEN

*  Exponentiated value would cause an overflow.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                     OUTARR( J ) = VAL__BADI
                     NERRV = NERRV + 1

                  ELSE

*  Input variance pixel is good.  Compute the output value.
                     OUTVAR( J ) = NUM_DTOI( LBASE2 * 
     :                             NUM_ITOD( OUTARR( J ) ) *
     :                             NUM_ITOD( OUTARR( J ) ) *
     :                             NUM_ITOD( INVAR( J ) ) )

                  END IF
               END DO
            END IF
         END IF

*  Negative-limit checking
*  =======================
      ELSE

*  Bad-pixels may be present.
*  --------------------------
         IF ( BAD ) THEN

*  Now loop round all the pixels of the output image.
            DO J = 1, EL

*  Propagate a bad pixel.
               IF ( INARR( J ) .EQ. VAL__BADI ) THEN
                  OUTARR( J ) = VAL__BADI
 
*  Check current pixel value.
               ELSE IF ( INARR( J ) .LE. MINVAL ) THEN

*  Exponentiated value would cause an overflow.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                  OUTARR( J ) = VAL__BADI
                  NERR = NERR + 1

               ELSE

*  Input array pixel is good.  Compute the output value.
                  OUTARR( J ) = NUM_DTOI( BASE ** 
     :                          NUM_ITOD( INARR( J ) ) )

               END IF
            END DO

*  Variance is present.
*  --------------------
            IF ( VAR ) THEN

*  Now loop round all the pixels of the output image.
               DO J = 1, EL

*  Propagate a bad pixel.
                  IF ( INVAR( J ) .EQ. VAL__BADI .OR.
     :                 OUTARR( J ) .EQ. VAL__BADI ) THEN
                     OUTVAR( J ) = VAL__BADI
 
*  Check current pixel variance.
                  ELSE IF ( INVAR( J ) .GE. MAXVAR ) THEN

*  Exponentiated value would cause an overflow.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                     OUTARR( J ) = VAL__BADI
                     NERRV = NERRV + 1

                  ELSE

*  Input variance pixel is good.  Compute the output value.
                     OUTVAR( J ) = NUM_DTOI( LBASE2 * 
     :                             NUM_ITOD( OUTARR( J ) ) *
     :                             NUM_ITOD( OUTARR( J ) ) *
     :                             NUM_ITOD( INVAR( J ) ) )

                  END IF
               END DO
            END IF

*  No bad pixels are present
*  -------------------------
         ELSE

*  Now loop round all the pixels of the output image.
            DO J = 1, EL

*  Check current pixel value.
               IF ( INARR( J ) .LE. MINVAL ) THEN

*  Exponentiated value would cause an overflow.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                  OUTARR( J ) = VAL__BADI
                  NERR = NERR + 1

               ELSE

*  Input array pixel is good.  Compute the output value.
                  OUTARR( J ) = NUM_DTOI( BASE ** 
     :                          NUM_ITOD( INARR( J ) ) )

               END IF
            END DO

*  Variance is present.
*  --------------------
            IF ( VAR ) THEN

*  Now loop round all the pixels of the output image.
               DO J = 1, EL

*  Check current pixel variance.
                  IF ( INVAR( J ) .GE. MAXVAR ) THEN

*  Exponentiated value would cause an overflow.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                     OUTARR( J ) = VAL__BADI
                     NERRV = NERRV + 1

                  ELSE

*  Input variance pixel is good.  Compute the output value.
                     OUTVAR( J ) = NUM_DTOI( LBASE2 * 
     :                             NUM_ITOD( OUTARR( J ) ) *
     :                             NUM_ITOD( OUTARR( J ) ) *
     :                             NUM_ITOD( INVAR( J ) ) )

                  END IF
               END DO
            END IF
         END IF
      END IF

  999 CONTINUE

      END
