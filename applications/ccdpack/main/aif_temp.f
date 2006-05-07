      SUBROUTINE AIF_TEMP( TYPE, NDIM, DIM, LOC, STATUS )
*+
*  Name:
*     AIF_TEMP

*  Purpose:
*     Create a temporary HDS object.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL AIF_TEMP( TYPE, NDIM, DIM, LOC, STATUS )

*  Description:
*     The routine creates a temporary HDS object with the specified
*     type and shape. On the first invocation a temporary structure is
*     created to contain such objects. Subsequently, temporary objects
*     are created within this enclosing structure.

*  Arguments:
*     TYPE = CHARACTER * ( * ) (Given)
*        HDS type of object to be created.
*     NDIM = INTEGER (Given)
*        Number of object dimensions.
*     DIM( NDIM ) = INTEGER (Given)
*        Object dimensions.
*     LOC = CHARACTER * ( * ) (Returned)
*        Locator to temporary object.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Algorithm:
*     -  Initialise the LOC argument, before checking the inherited
*     status.
*     -  On the first invocation, create a temporary enclosing
*     structure.
*     -  Subsequently, create a unique name for the temporary object
*     required.
*     -  Create the object within the enclosing structure and obtain a
*     locator to it.
*     -  If an error occurred, then reset the LOC argument.

*  Notes:
*     -  A blank string will be returned for the LOC argument if this
*     routine is called with STATUS set, although no further processing
*     will occur. The same value will also be returned if the routine
*     should fail for any reason.
*     -  This routine is a work-around to avoid the problems associated
*     with calling DAT_TEMP if the objects created must subsequently be
*     erased.

*  Copyright:
*     Copyright (C) 1989, 1991 Science & Engineering Research Council.
*     All Rights Reserved.

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
*     RFWS: R.F. Warren-Smith (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     7-DEC-1989 (RFWS):
*        Original, derived from the equivalent NDF_ routine.
*     1991 July 5 (MJC):
*        Added contextual error report.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! HDS DAT constants

*  Arguments Given:
      CHARACTER * ( * ) TYPE
      INTEGER NDIM
      INTEGER DIM( * )

*  Arguments Returned:
      CHARACTER * ( * ) LOC

*  Status:
      INTEGER STATUS             ! Global status

*  Local variables:
      CHARACTER * ( DAT__SZLOC ) TMPLOC ! Locator to enclosing structure
      CHARACTER * ( DAT__SZNAM ) NAME ! Temporary object name
      INTEGER COUNT              ! Count of objects created
      INTEGER DUMMY( 1 )         ! Dummy dimensions array
      INTEGER EL                 ! Total number of elements requested
      INTEGER I                  ! Loop counter
      INTEGER NCHAR              ! Number of characters formatted
      SAVE COUNT
      SAVE TMPLOC

*  Local Data:
      DATA COUNT / 0 /

*.

*  Initialise the LOC argument.
      LOC = ' '

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Increment the count of temporary objects created.
      COUNT = COUNT + 1

*  Before creating the first object, create a temporary enclosing
*  structure.
      IF ( COUNT .EQ. 1 ) THEN
         TMPLOC = ' '
         CALL DAT_TEMP( 'AIF_TEMP', 0, DUMMY, TMPLOC, STATUS )
      END IF

*  Form a unique name for the temporary object.
      IF ( STATUS .EQ. SAI__OK ) THEN
         NAME = 'AIF_'
         CALL CHR_ITOC( COUNT, NAME( 5 : ), NCHAR )

*  Create an object inside the enclosing structure and obtain a locator
*  to it.
         CALL DAT_NEW( TMPLOC, NAME, TYPE, NDIM, DIM, STATUS )
         CALL DAT_FIND( TMPLOC, NAME, LOC, STATUS )

*  If an error occurred, then reset the LOC argument.
         IF ( STATUS .NE. SAI__OK ) THEN
            LOC = ' '
         END IF
      END IF

*  Report a contextual error containing the total number of array
*  elements.
      IF ( STATUS .NE. SAI__OK ) THEN
         EL = 1
         DO  I = 1, NDIM
            EL = EL * DIM( I )
         END DO

         CALL MSG_SETI( 'EL', EL )
         CALL MSG_SETC( 'TYPE', TYPE )
         CALL ERR_REP( 'AIF_TEMP_NOTOBT',
     :     'Error obtaining ^EL elements of ^TYPE temporary space.',
     :     STATUS )
      END IF

      END
* $Id$
