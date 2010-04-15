************************************************************************

      SUBROUTINE AGP_DEASS ( PARAM, PARCAN, STATUS )

*+
*  Name:
*     AGP_DEASS
*
*  Purpose:
*     Deassociate a device from AGI and PGPLOT.
*
*  Invocation:
*     CALL AGP_DEASS( PARAM, PARCAN, STATUS )
*
*  Description:
*     This is a wrap-up routine to deassociate a device from the AGI
*     database and to close down PGPLOT. The picture current when
*     AGP_ASSOC was called is reinstated. This routine calls AGP_DEACT,
*     AGI_END and either AGI_CANCL or AGI_ANNUL. This routine is
*     executed regardless of the given value of status.
*
*  Arguments:
*     PARAM = CHARACTER*(*) (Given)
*        The name of the ADAM parameter associated with the device.
*     PARCAN = LOGICAL (Given)
*        If true the parameter given by PARAM is cancelled, otherwise
*        it is annulled.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
*
*  Algorithm:
*     Record the input status and begin an error context.
*     Deactivate the PGPLOT interface.
*     End the AGI context.
*     Annul any errors from the last two steps.
*     If PARCAN is true then
*        Cancel the AGI device parameter.
*     Else
*        Annul the current picture identifier.
*     Endif
*     Reinstate the input status.
*
*  Copyright:
*     Copyright (C) 1992 Science & Engineering Research Council.
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
*     NE: Nick Eaton (Durham University)
*
*  History:
*      7-JUL-1992 (NE):
*        Original version.
*-

*  Type Definitions :
      IMPLICIT NONE

*  Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'

*  Arguments Given :
      CHARACTER * ( * ) PARAM
      LOGICAL PARCAN

*  Status :
      INTEGER STATUS

*  Local variables :
      INTEGER ISTAT, PICID
*.

*  Record the input status and set the internal status to OK.
      ISTAT = STATUS
      STATUS = SAI__OK

*  Start a new error context to prevent error reports if there is no
*  active workstation or no current picture.
      CALL ERR_MARK

*  Deactivate PGPLOT and close the workstation. If the workstation was
*  not activated an error results.
      CALL AGP_DEACT( STATUS )

*  Close the AGI context and reinstate the input current picture.  If
*  there is no current picture an error results.
      CALL AGI_END( -1, STATUS )

*  We do not want either error message, but want to retain the
*  original error status, if there is one.
      IF ( STATUS .NE. SAI__OK ) CALL ERR_ANNUL( STATUS )

*  Release the new error context.
      CALL ERR_RLSE

*  Close the AGI database.  Record the name of the workstation only
*  if it was used successfully.
      IF ( PARCAN ) THEN
         CALL AGI_CANCL( PARAM, STATUS )

*  Inquire the input picture identifier so that it may be annulled
*  and the database closed.
      ELSE
         CALL AGI_ICURP( PICID, STATUS )
         CALL AGI_ANNUL( PICID, STATUS )
      END IF

*  Restore the input status if nothing went wrong.
      IF ( STATUS .EQ. SAI__OK ) STATUS = ISTAT

      END

