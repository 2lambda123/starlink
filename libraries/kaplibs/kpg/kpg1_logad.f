      SUBROUTINE KPG1_LOGAD( BAD, EL, INARR, VAR, INVAR, BASE, OUTARR,
     :                       OUTVAR, NERR, NERRV, STATUS )
*+
*  Name:
*     KPG1_LOGAx

*  Purpose:
*     Takes the logarithm to an arbitrary base of an array and its
*     variance.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_LOGAx( BAD, EL, INARR, VAR, INVAR, BASE, OUTARR,
*                      OUTVAR, NERR, NERRV, STATUS )

*  Description:
*     This routine fills the output array pixels with the results
*     of taking the logarithm of the pixels of the input array
*     to the base specified, i.e. New_value = Log    Old_value.
*                                                Base
*     If the input pixel is negative, then a bad pixel value is
*     used for the output value.
*
*     To find the logarithm to any base, the following algorithm
*     is used, providing the base is positive and not equal to one:
*
*         New_Value  =  Log Old_Value / Log Base
*                          e               e
*
*     If variance is present it is computed as:                 2
*         New_Variance = Old_Variance / ( Old_value * log Base )
*                                                        e

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
*        Base of logarithm to be used.  It must be a positive number.
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
*     1997 June 16 (MJC):
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
      DOUBLE PRECISION INARR( EL )
      LOGICAL VAR
      DOUBLE PRECISION INVAR( EL )
      DOUBLE PRECISION BASE

*  Arguments Returned:
      DOUBLE PRECISION OUTARR( EL )
      DOUBLE PRECISION OUTVAR( EL )
      INTEGER NERR
      INTEGER NERRV

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      DOUBLE PRECISION FACTOR    ! Factor used to define base being
                                 ! used
      DOUBLE PRECISION FACTSQ    ! Factor used to define base being
                                 ! used for variances
      INTEGER J                  ! Counter variable

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM_ type conversion functions
      INCLUDE 'NUM_DEF_CVT'      ! Define functions...

*.

*  Check the iherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise returned counters.
      NERR = 0
      NERRV = 0

*  Proceed according to supplied base.
      IF ( BASE .GT. 0.0D0 .AND. BASE .NE. 1.0D0 ) THEN

*  This is fine.  Evaluate the factors required taking logs to the
*  specified base, and for variance.
         FACTOR = 1.0D0 / LOG( BASE )
         FACTSQ = FACTOR * FACTOR

*  First deal with the bad-pixel case.
*  ===================================
         IF ( BAD ) THEN

*  Now loop round all the pixels of the output image.
            DO J = 1, EL

*  Propagate a bad pixel.
               IF ( INARR( J ) .EQ. VAL__BADD ) THEN
                  OUTARR( J ) = VAL__BADD
 
*  Check current pixel value.
               ELSE IF ( INARR( J ) .LE. 0.0D0 ) THEN

*  Cannot take log of zero or negative value.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                  OUTARR( J ) = VAL__BADD
                  NERR = NERR + 1

               ELSE

*  Input array pixel is good.  Compute the output value.
                  OUTARR( J ) = NUM_DTOD( FACTOR *
     :                          LOG( NUM_DTOD( INARR( J ) ) ) )

               END IF

*  End of loop round all rows.
            END DO

*  Compute the new variances.
*  ==========================
            IF ( VAR ) THEN

*  Now loop round all the pixels of the output variance array.
               DO J = 1, EL

*  Propagate a bad variance.
                  IF ( INVAR( J ) .EQ. VAL__BADD .OR.
     :                 INARR( J ) .EQ. VAL__BADD ) THEN
                     OUTVAR( J ) = VAL__BADD

*  Check current variance value.  Also the input value appears in the
*  denominator, so check for zeroes.
                  ELSE IF ( INVAR( J ) .LE. 0.0D0 .OR.
     :                      INARR( J ) .EQ. 0.0D0 ) THEN

*  Cannot take log of zero or negative value.  The resultant output
*  variance is therefore undefined and is set to the bad value.
                     OUTVAR( J ) = VAL__BADD

                  ELSE

*  Input variance value is good.  Compute the output value.  Keep a
*  count of the number of errors.
                     OUTVAR( J ) = NUM_DTOD( FACTSQ *
     :                             NUM_DTOD( INVAR( J ) ) /
     :                             NUM_DTOD( INARR( J ) ) /
     :                             NUM_DTOD( INARR( J ) ) )
                  END IF

*  End of loop round all rows.
               END DO

            END IF

*  No bad pixels are present.
*  ==========================
         ELSE

*  Now loop round all the pixels of the output image.
            DO J = 1, EL

*  Check current pixel value.
               IF ( INARR( J ) .LE. 0.0D0 ) THEN

*  Cannot take log of zero or negative value.  The resultant output
*  pixel is therefore undefined and is set to the bad value.  Keep a
*  count of the number of errors.
                  OUTARR( J ) = VAL__BADD
                  NERR = NERR + 1

               ELSE

*  Input array pixel is good.  Compute the output value.
                  OUTARR( J ) = NUM_DTOD( FACTOR *
     :                          LOG( NUM_DTOD( INARR( J ) ) ) )

               END IF

*  End of loop round all rows.
            END DO

*  Compute the new variances.
*  ==========================
            IF ( VAR ) THEN

*  Now loop round all the pixels of the output variance array.
               DO J = 1, EL

*  Check current variance value.  Also the input value appears in the
*  denominator, so check for zeroes.
                  IF ( INVAR( J ) .LE. 0.0D0 .OR.
     :                 INARR( J ) .EQ. 0.0D0 ) THEN

*  Cannot take log of zero or negative value.  The resultant output
*  variance is therefore undefined and is set to the bad value.
                     OUTVAR( J ) = VAL__BADD

                  ELSE

*  Input variance value is good.  Compute the output value.  Keep a
*  count of the number of errors.
                     OUTVAR( J ) = NUM_DTOD( FACTSQ *
     :                             NUM_DTOD( INVAR( J ) ) /
     :                             NUM_DTOD( INARR( J ) ) /
     :                             NUM_DTOD( INARR( J ) ) )
                  END IF

*  End of loop round all rows.
               END DO

            END IF
         END IF

*  Base is one, zero, or negative.
*  ===============================
      ELSE

*  Loop round all pixels in the output array.  Set the output pixel
*  value to bad,
         DO J = 1, EL
            OUTARR( J ) = VAL__BADD
         END DO

*  Set the variance values to bad too.
         IF ( VAR ) THEN
            DO J = 1, EL
               OUTVAR( J ) = VAL__BADD
            END DO
         END IF

*  Set the bad-value counters.
         NERR = EL
         NERRV = EL
      END IF

      END
