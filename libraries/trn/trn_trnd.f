      SUBROUTINE TRN_TRND( BAD, ND1, NCIN, NDAT, DATA, IDT, NR1,
     :                       NCOUT, RESULT, STATUS )
*+
*  Name:
*     TRN_TRND
 
*  Purpose:
*     apply general transformation to DOUBLE PRECISION data.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL TRN_TRND( BAD, ND1, NCIN, NDAT, DATA, IDT, NR1, NCOUT,
*                      RESULT, STATUS )
 
*  Description:
*     The routine applies a general compiled transformation to a set of
*     DOUBLE PRECISION data points.
 
*  Arguments:
*     BAD = LOGICAL (given)
*        Whether the input coordinate values may be "bad".
*     ND1 = INTEGER (given)
*        First dimension of the DATA array.
*     NCIN = INTEGER (given)
*        Number of coordinates for each input data point.
*     NDAT = INTEGER (given)
*        Number of data points to transform.
*     DATA( ND1, NCIN ) = DOUBLE PRECISION (given)
*        Array containing the coordinates for each input data point.
*     IDT = INTEGER (given)
*        ID for the compiled transformation to be applied.
*     NR1 = INTEGER (given)
*        First dimension of the RESULT array.
*     NCOUT = INTEGER (given)
*        Number of coordinates for each output data point.
*     RESULT( NR1, NCOUT ) = DOUBLE PRECISION (returned)
*        Array to receive the transformed coordinates for each
*        output data point.
*     STATUS = INTEGER (given & returned)
*        Inherited error status.
 
*  Algorithm:
*     - Ensure that the TRANSFORM facility is active.
*     - Obtain the compiled transformation table (CTT) slot number from
*       the identifier supplied, validating the identifier in the
*       process.
*     - Call TRN1_TRDTD to transform the data using the compiled
*       transformation associated with the CTT slot.
 
*  Copyright:
*     Copyright (C) 1988 Science & Engineering Research Council.
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
*     R.F. Warren-Smith (DUVAD::RFWS)
*     {enter_new_authors_here}
 
*  History:
*     18-AUG-1988:  Original version (DUVAD::RFWS)
*     {enter_further_changes_here}
 
*  Bugs:
*     None known.
*     {note_new_bugs_here}
 
*-
 
 
*  Type Definitions:
      IMPLICIT NONE             ! No implicit typing
 
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
 
 
*  Arguments Given:
      LOGICAL BAD               ! Whether input DATA values may be "bad"
 
      INTEGER ND1               ! First dimension of DATA array
 
      INTEGER NCIN              ! Number of coordinates for each input
                                ! data point
 
      INTEGER NDAT              ! Number of data points to transform
 
      DOUBLE PRECISION DATA( ND1, NCIN )  ! Array containing coordinates for each
                                ! input data point
 
      INTEGER IDT               ! ID for compiled transformation
 
      INTEGER NR1               ! First dimension of RESULT array
 
      INTEGER NCOUT             ! Number of coordinates for each output
                                ! data point
 
 
*  Arguments Returned:
      DOUBLE PRECISION RESULT( NR1, NCOUT )
                                ! Array to contain transformed
                                ! coordinates for each output data point
 
 
*  Status:
      INTEGER STATUS            ! Error status
 
 
*  Global Variables:
      INCLUDE 'TRN_CMN'         ! TRN_ common blocks
 
 
*  Local Variables:
      INTEGER SLOT              ! Slot number for the transformation in
                                ! the compiled transformation table
 
 
*.
 
 
 
*   Check status.
      IF( STATUS .NE. SAI__OK ) RETURN
 
 
*   Ensure the TRANSFORM facility is active.
      CALL TRN1_SETUP( .TRUE., STATUS )
 
 
*   Import the ID for the transformation.
      CALL TRN1_IMPID( IDT, %VAL( CNF_PVAL( TRN_PCTTI ) ), SLOT,
     :                 STATUS )

*   Apply the transformation to the data points.
      CALL TRN1_TRDTD( BAD, ND1, NCIN, DATA, NDAT,
     :                   %VAL( CNF_PVAL( TRN_PCTTI ) ), SLOT,
     :                   NR1, NCOUT, RESULT, STATUS )

*   Exit routine.
      END
 
 
