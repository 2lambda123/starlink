      SUBROUTINE KPG1_NOISUB( BAD, EL, VARNCE, ARRAY, STATUS )
*+
*  Name:
*     KPG1_NOISx

*  Purpose:
*     Adds random Normal noise to a 1-d array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_NOISx( BAD, EL, VARNCE, ARRAY, STATUS )

*  Description:
*     This routine takes a 1-d array and adds noise randomly to each
*     element in the array.  The random number at each element is drawn
*     from a Normal distribution whose spread is given by the
*     corresponding variance array at that element.

*  Arguments:
*     BAD = INTEGER (Given)
*        If true there may be bad pixels in input arrays, and so there
*        will be bad-pixel testing.
*     EL = INTEGER (Given)
*        The number of elements in the arrays.
*     VARNCE( EL ) = ? (Given)
*        The Normal variance array corresponding to the data array.
*     ARRAY( EL ) = ? (Given and Returned)
*        The data array to which random errors are to be applied.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  There is a routine for all numeric data types: replace "x" in
*     the routine name by B, D, I, R, UB, UW or W as appropriate.  The
*     arrays supplied to the routine must have the data type specified.
*     -  All arithmetic is performed in double precision.

*  [optional_subroutine_items]...
*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council.
*     Copyright (C) 1997, 1999 Central Laboratory of the Research Councils.
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
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1991 April 25 (MJC):
*        Original version.
*     1997 January 10 (MJC):
*        Replaced NAG calls.  Used commenting modern style.
*     7-JUL-1999 (DSB):
*        Set seed using KPG1_PSEED instead of PDA_RNSED.
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
      LOGICAL BAD
      INTEGER EL
      BYTE VARNCE( EL )

*  Arguments Given and Returned:
      BYTE ARRAY( EL )

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL PDA_RNNOR
      REAL PDA_RNNOR             ! PDA random-number generator with
                                 ! Normal distribution for one value

*  Local Variables:
      INTEGER I                  ! Loop counter
      REAL SIGMA                 ! Standard deviation

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM declarations for conversions
      INCLUDE 'NUM_DEF_CVT'      ! NUM definitions for conversions

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the random number generator seed to a non-repeatable
*  value.
      CALL KPG1_PSEED( STATUS )

*  There are two processing loops depending on whether there might be
*  bad values present.
      IF ( BAD ) THEN

         DO I = 1, EL

*  Check for a bad data-array value or a bad data value.  In this case
*  noise cannot be added to the data array, so set it bad.
            IF ( ARRAY( I ) .EQ. VAL__BADUB .OR.
     :           VARNCE( I ) .EQ. VAL__BADUB ) THEN
               ARRAY( I ) = VAL__BADUB

            ELSE

*  Find the  of the Normal distribution at the element.
               SIGMA = SQRT( NUM_UBTOR( VARNCE( I ) ) )

*  Generate the random noise.  There is no offset.
               ARRAY( I ) = ARRAY( I ) +
     :                      NUM_RTOUB( PDA_RNNOR( 0.0, SIGMA ) )
            END IF
         END DO

      ELSE

         DO  I = 1, EL

*  Find the sigma of the Normal distribution at the element.
            SIGMA = SQRT( NUM_UBTOR( VARNCE( I ) ) )

*  Generate the random noise.  There is no offset.
            ARRAY( I ) = ARRAY( I ) +
     :                   NUM_RTOUB( PDA_RNNOR( 0.0, SIGMA ) )
         END DO
      END IF

      END
