      SUBROUTINE NDF1_ADFRM( IAX, IACB, FORM, STATUS )
*+
*  Name:
*     NDF1_ADFRM

*  Purpose:
*     Obtain the storage form of an axis data array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF1_ADFRM( IAX, IACB, FORM, STATUS )

*  Description:
*     The routine returns the storage form of an NDF axis data array as
*     an upper case character string. The NDF is identified by its
*     entry in the ACB.

*  Arguments:
*     IAX = INTEGER (Given)
*        Number of the axis for which informaton is required.
*     IACB = INTEGER (Given)
*        Index to the NDF entry in the ACB.
*     FORM = CHARACTER * ( * ) (Returned)
*        Axis data array storage form (upper case).
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Algorithm:
*     -  Obtain an index to the data object entry in the DCB.
*     -  Ensure that axis data array information is available.
*     -  If the axis data array exists, then determine its storage form
*     directly.
*     -  Otherwise, obtain the default storage form from the DCB.

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
*     10-OCT-1990 (RFWS):
*        Original version.
*     {enter_changes_here}

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
      INCLUDE 'ARY_PAR'          ! ARY_ public constants

*  Global Variables:
      INCLUDE 'NDF_DCB'          ! NDF_ Data Control Block
*        DCB_ADID( NDF__MXDIM, NDF__MXDCB ) = INTEGER (Read)
*           ARY_ system identifiers for axis data arrays.
*        DCB_ADFRM( NDF__MXDIM, NDF__MXDCB ) = CHARACTER * ( NDF__SZFRM
*        ) (Read)
*           Storage form of axis data arrays.

      INCLUDE 'NDF_ACB'          ! NDF_ Access Control Block
*        ACB_IDCB( NDF__MXACB ) = INTEGER (Read)
*           Index to data object entry in the DCB.

*  Arguments Given:
      INTEGER IAX
      INTEGER IACB

*  Arguments Returned:
      CHARACTER * ( * ) FORM

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER IDCB               ! Index to data object entry in the DCB

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain an index to the data object entry in the DCB.
      IDCB = ACB_IDCB( IACB )

*  Ensure that axis data array information is available.
      CALL NDF1_DAD( IAX, IDCB, STATUS )
      IF ( STATUS .EQ. SAI__OK ) THEN

*  If the axis data array exists, then determine its storage form
*  directly.
         IF ( DCB_ADID( IAX, IDCB ) .NE. ARY__NOID ) THEN
            CALL ARY_FORM( DCB_ADID( IAX, IDCB ), FORM, STATUS )

*  Otherwise, obtain the default storage form from the DCB.
         ELSE
            CALL NDF1_CCPY( DCB_ADFRM( IAX, IDCB ), FORM, STATUS )
         END IF
      END IF

*  Call error tracing routine and exit.
      IF ( STATUS .NE. SAI__OK ) CALL NDF1_TRACE( 'NDF1_ADFRM', STATUS )

      END
