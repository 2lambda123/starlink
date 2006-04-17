      SUBROUTINE IRQ_GETQN( LOCS, QNAME, FIXED, VALUE, BIT, COMMNT,
     :                      STATUS )
*+
*  Name:
*     IRQ_GETQN

*  Purpose:
*     Search for a specified quality name.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL IRQ_GETQN( LOCS, QNAME, FIXED, VALUE, BIT, COMMNT, STATUS )

*  Description:
*     This routine searches for a specified quality name in the quality
*     name specified by LOCS, and returns information related to the
*     quality name. If the quality name is not defined then an error is
*     reported and STATUS returned equal to IRQ__NOQNM.

*  Arguments:
*     LOCS(5) = CHARACTER * ( * ) (Given)
*        An array of 5 HDS locators. These locators identify the NDF
*        and the associated quality name information.  They should have
*        been obtained using routine IRQ_FIND or routine IRQ_NEW.
*     QNAME = CHARACTER * ( * ) (Given)
*        The quality name to search for. Leading blanks are ignored and
*        the search is case-insensitive. The maximum allowed length for
*        quality names is given by symbolic constant IRQ__SZQNM which
*        currently has the value of 15.
*     FIXED = LOGICAL (Returned)
*        If true, then the quality is either held by all pixels, or by
*        no pixels. In this case the quality does not have a
*        corresponding bit in the QUALITY component. If false, then
*        some pixels have the quality and some don't, as indicated by
*        the corresponding bit in the QUALITY component.
*     VALUE = LOGICAL (Returned)
*        If FIXED is true, then VALUE specifies whether all pixels hold
*        the quality ( VALUE = .TRUE. ), or whether no pixels hold the
*        quality ( VALUE = .FALSE. ). If FIXED is false, then VALUE is
*        indeterminate.
*     BIT = INTEGER (Returned)
*        If FIXED is false, then BIT holds the corresponding bit number
*        in the QUALITY component. The least significant bit is called
*        bit 1 (not bit 0). If FIXED is true, then BIT is
*        indeterminate.
*     COMMNT = CHARACTER * ( * ) (Returned)
*        The descriptive comment which was stored with the quality name.
*        The supplied character variable should have a declared length
*        given by symbolic constant IRQ__SZCOM.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1991 Science & Engineering Research Council.
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
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     25-JUL-1991 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT__ constants
      INCLUDE 'IRQ_PAR'          ! IRQ constants.

*  Arguments Given:
      CHARACTER LOCS(5)*(*)
      CHARACTER QNAME*(*)

*  Arguments returned:
      LOGICAL FIXED
      LOGICAL VALUE
      INTEGER BIT
      CHARACTER COMMNT*(*)

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER FIRST              ! Position of first non-blank character
      INTEGER INDF               ! Identifier for the NDF containing the
                                 ! quality names information.
      INTEGER LAST               ! Position of last non-blank character.
      CHARACTER LQNAME*(IRQ__SZQNM) ! Upper case copy of quality name.
      INTEGER SLOT               ! Index into the QUAL structure at
                                 ! which the name was found.
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain the NDF identifier from LOCS, and check it is still valid.
      CALL IRQ1_INDF( LOCS, INDF, STATUS )

*  Produce an uppercase copy of the supplied quality name, exluding
*  leading blanks.
      CALL CHR_FANDL( QNAME, FIRST, LAST )
      LQNAME = QNAME( FIRST : LAST )
      CALL CHR_UCASE( LQNAME )

*  Search for the requested quality name.
      CALL IRQ1_SEARC( LOCS, LQNAME( : LAST - FIRST + 1 ), FIXED, VALUE,
     :                 BIT, COMMNT, SLOT, STATUS )

*  If an error occur, give context information.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL NDF_MSG( 'NDF', INDF )
         CALL MSG_SETC( 'QN', QNAME )
         CALL ERR_REP( 'IRQ_GETQN_ERR1',
     :      'IRQ_GETQN: Unable to find quality name ^QN in NDF ^NDF',
     :       STATUS )
      END IF

      END
