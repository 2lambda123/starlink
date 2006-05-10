      SUBROUTINE GDCLEAR( STATUS )
*+
*  Name:
*     GDCLEAR

*  Purpose:
*     Clears a graphics device and purges its database entries.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL GDCLEAR( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application software resets a graphics device. In effect
*     the device is cleared.  It purges the graphics-database entries
*     for the device.  Optionally, only the current picture is cleared
*     and the database unchanged. (Note the clearing of the current
*     picture may not work on some graphics devices.)

*  Usage:
*     gdclear [device] [current]

*  ADAM Parameters:
*     CURRENT = _LOGICAL (Read)
*        If TRUE then only the current picture is cleared. [FALSE]
*     DEVICE = DEVICE (Read)
*        The device to be cleared. [Current graphics device]

*  Examples:
*     gdclear
*        Clears the current graphics device and purges its graphics
*        database entries.
*     gdclear current
*        Clears the current picture on the current graphics device.
*     gdclear xw
*        Clears the xw device and purges its graphics database entries.

*  Related Applications:
*     KAPPA: GDSET, GDSTATE.

*  Copyright:
*     Copyright (C) 1989-1992 Science & Engineering Research Council.
*     Copyright (C) 1999, 2004 Central Laboratory of the Research
*     Councils. All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     MJC: Malcolm J. Currie  (STARLINK)
*     TDCA: Tim Ash (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1989 Apr 13 (MJC):
*        Original version.
*     1989 Jul 24 (MJC):
*        Uses SGS to get device names consistent with the rest of KAPPA
*        in the partial GNS era.
*     1990 Jan 12 (MJC):
*        Option to clear the current picture added.
*     1991 March 24 (MJC):
*        Converted to SST prologue.
*     1991 April 9 (MJC):
*        Added AGI begin-and-end block.
*     1992 March 3 (MJC):
*        Replaced AIF parameter-system calls by the extended PAR
*        library.
*     29-SEP-1999 (TDCA):
*        Converted to PGPLOT.
*     30-SEP-1999 (DSB):
*        Re-written to use KPG1_PGCLR.
*     2004 September 3 (TIMJ):
*        Use CNF_PVAL
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE            ! no implicit typing allowed


*  Global Constants:
      INCLUDE  'SAE_PAR'       ! global SSE definitions

*  Status:
      INTEGER STATUS

*  Local Variables:
      INTEGER IPIC             ! AGI input picture identifier
      INTEGER IPICB            ! AGI Base picture identifier
      LOGICAL CURRNT           ! Only the current picture is to be cleared?
*.

*  Check the inherited status on entry.
      IF( STATUS .NE. SAI__OK ) RETURN

*  Find whether the device is to be reset or just the current picture
*  is to be cleared.
      CALL PAR_GTD0L( 'CURRENT', .FALSE., .TRUE., CURRNT, STATUS )

*  Open the graphics device in update mode. This does not clear the current 
*  picture. The PGPLOT viewport is set so that it corresponds to the current 
*  picture.
      CALL KPG1_PGOPN( 'DEVICE', 'WRITE', IPIC, STATUS )

*  If the whole display is to be cleared. Select the Base picture as the
*  current picture, and create a PGPLOT viewport from it.
      IF( .NOT. CURRNT ) THEN
         CALL AGI_IBASE( IPICB, STATUS )
         CALL AGI_SELP( IPICB, STATUS )
         CALL AGP_NVIEW( .FALSE., STATUS )
      END IF

*  Attempt to clear the viewport. This will only do anything if 
*  the device allows us to draw in the background colour. 
      CALL KPG1_PGCLR( STATUS )

*  If the whole screen was cleared, empty the database of all pictures
*  (except the Base picture).
      IF( .NOT. CURRNT ) CALL AGI_PDEL( STATUS )

*  Shut down the workstation and database, retaining the original current 
*  picture only if the whole screen has not been cleared.
      CALL KPG1_PGCLS( 'DEVICE', .NOT.CURRNT, STATUS )

*  If an error occurred, add a context message.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'GDCLEAR_ERR', 'GDCLEAR: Unable to clear '//
     :                 'current graphics device.', STATUS )
      END IF

      END
