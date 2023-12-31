      SUBROUTINE NDF1_DQANL( IDCB, DEL, STATUS )
*+
*  Name:
*     NDF1_DQANL

*  Purpose:
*     Annul the quality data object in an NDF.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_DQANL( IDCB, DEL, STATUS )

*  Description:
*     The routine performs an annul operation on the DCB items
*     describing the quality data object in an NDF as part of anulling
*     the DCB entry for the NDF itself. If no DCB information about the
*     quality component is available, then no action is taken.
*     Otherwise, the DCB items relating to this component are annulled
*     and the quality data object deleted if necessary.

*  Arguments:
*     IDCB = INTEGER (Given)
*        Index to the DCB entry.
*     DEL = LOGICAL (Given)
*        Whether the annul operation is to result in deletion of the
*        data object.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  This routine will attempt to execute even if STATUS is set on
*     entry, although no further error report will be made if it
*     subsequently fails under these circumstances.

*  Algorithm:
*     -  Save the error context on entry.
*     -  Check that quality information is available in the DCB. There
*     is nothing to do if it is not.
*     -  See if the DCB locator for the quality structure is valid. If
*     not, then there is nothing to do.
*     -  See if the DCB ARY_ system identifier for the quality array is
*     valid. If not, then the array does not exist, so delete the
*     enclosing quality structure.
*     -  If the quality array exists, then delete it and the enclosing
*     quality structure if required.
*     -  Otherwise, see if the array is in the defined state.
*     -  If so, then annul its identifier in the DCB.
*     -  Otherwise, delete the array and the enclosing quality
*     structure, since an undefined quality array is not allowed.
*     -  Note that DCB quality information is no longer available.
*     -  Restore the error context.

*  Copyright:
*     Copyright (C) 1990 Science & Engineering Research Council.
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
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}

*  History:
*     17-JAN-1990 (RFWS):
*        Original, derived from the NDF1_DVANL routine.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'NDF_CONST'        ! NDF_ private constants

*  Global Variables:
      INCLUDE 'NDF_DCB'          ! NDF_ Data Control Block
*        DCB_KQ( NDF__MXDCB ) = LOGICAL (Read and Write)
*           Whether information about the NDF's quality component is
*           available in the DCB.
*        DCB_QID( NDF__MXDCB ) = INTEGER (Read and Write)
*           ARY_ system identifier for the NDF's quality array.
*        DCB_QLOC( NDF__MXDCB ) = CHARACTER * ( DAT__SZLOC ) (Read and
*        Write)
*           Locator for the NDF's quality structure.

*  Arguments Given:
      INTEGER IDCB
      LOGICAL DEL

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER TSTAT              ! Temporary status variable
      LOGICAL STATE              ! Whether array is in defined state
      LOGICAL VALID              ! Whether array identifier is valid

*.

*  Save the STATUS value and mark the error stack.
      TSTAT = STATUS
      CALL ERR_MARK

*  Check that quality information is available in the DCB. Otherwise
*  there is nothing to do.
      STATUS = SAI__OK
      IF ( DCB_KQ( IDCB ) ) THEN

*  See if the DCB locator for the quality component is valid. If not,
*  then the quality structure does not exist, so there is nothing to do.
         IF ( DCB_QLOC( IDCB ) .NE. DAT__NOLOC ) THEN

*  See if the DCB ARY_ system identifier for the quality array is valid.
            CALL ARY_VALID( DCB_QID( IDCB ), VALID, STATUS )
            IF ( STATUS .EQ. SAI__OK ) THEN

*  If not, then the quality component is undefined, so the quality
*  structure must be deleted.
               IF ( .NOT. VALID ) THEN
                  CALL NDF1_ANTMP( DCB_QLOC( IDCB ), STATUS )

*  If the quality array exists, but deletion is required, then delete
*  the array, followed by the quality structure itself.
               ELSE
                  IF ( DEL ) THEN
                     CALL ARY_DELET( DCB_QID( IDCB ), STATUS )
                     CALL NDF1_ANTMP( DCB_QLOC( IDCB ), STATUS )

*  Otherwise, see if the array is in the defined state.
                  ELSE
                     CALL ARY_STATE( DCB_QID( IDCB ), STATE, STATUS )
                     IF ( STATUS .EQ. SAI__OK ) THEN

*  If so, then it must be kept, so simply annul the DCB identifier for
*  it, followed by the DCB locator to the quality structure.
                        IF ( STATE ) THEN
                           CALL ARY_ANNUL( DCB_QID( IDCB ), STATUS )
                           CALL DAT_ANNUL( DCB_QLOC( IDCB ), STATUS )

*  Otherwise, the whole structure must be deleted as an undefined array
*  within the quality structure is not allowed (this should never
*  actually need to be done).
                        ELSE
                           CALL ARY_DELET( DCB_QID( IDCB ), STATUS )
                           CALL NDF1_ANTMP( DCB_QLOC( IDCB ), STATUS )
                        END IF
                     END IF
                  END IF
               END IF
            END IF
         END IF

*  Note that DCB quality information is no longer available.
         DCB_KQ( IDCB ) = .FALSE.
      END IF

*  Annul any error if STATUS was previously bad, otherwise let the new
*  error report stand.
      IF ( STATUS .NE. SAI__OK ) THEN
         IF ( TSTAT .NE. SAI__OK ) THEN
            CALL ERR_ANNUL( STATUS )
            STATUS = TSTAT

*  Call error tracing routine if appropriate.
         ELSE
            CALL NDF1_TRACE( 'NDF1_DQANL', STATUS )
         END IF
      ELSE
         STATUS = TSTAT
      END IF

*  Release the error stack.
      CALL ERR_RLSE

      END
