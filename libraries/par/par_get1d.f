      SUBROUTINE PAR_GET1D ( PARAM, MAXVAL, VALUES, ACTVAL, STATUS )
*+
*  Name:
*     PAR_GET1x

*  Purpose:
*     Obtains a vector of values from a parameter.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL PAR_GET1x( PARAM, MAXVAL, VALUES, ACTVAL, STATUS )

*  Description:
*     This routine obtains a vector of values from a parameter. If it is
*     necessary, the values are converted to the required type.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The parameter name.
*     MAXVAL = INTEGER (Given)
*        The maximum number of values that can be obtained.
*     VALUES( MAXVAL ) = ? (Returned)
*        The array to receive the values associated with the parameter.
*     ACTVAL = INTEGER (Returned)
*        The actual number of values obtained.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  There is a routine for each of the data types character,
*     double precision, integer, logical, and real: replace "x" in the
*     routine name by C, D, I, L, or R respectively as appropriate.  The
*     VALUES argument must have the corresponding data type.
*     -  Note that this routine will accept a scalar value, returning
*     a single-element vector.

*  Algorithm:
*     Call the underlying parameter-system primitives.

*  Copyright:
*     Copyright (C) 1984, 1988, 1990, 1992 Science & Engineering Research Council.
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
*     BDK: B D Kelly (REVAD::BDK)
*     AJC: A J Chipperfield (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     7-NOV-1984 (BDK):
*        Original version.
*     02-JUN-1988 (AJC):
*        Revised prologue.
*     9-NOV-1990 (AJC):
*        Revised prologue again
*     1992 March 27 (MJC):
*        Used SST prologues.
*     1992 November 13 (MJC):
*        Commented the code, and renamed the NAMECODE identifier.
*        Re-tidied the prologue.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER * ( * ) PARAM    ! Parameter Name
      INTEGER MAXVAL             ! Maximum number of values

*  Arguments Returned:
      DOUBLE PRECISION VALUES( * )
      INTEGER ACTVAL

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER NAMCOD             ! Pointer to the parameter

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Find the parameter-system pointer to the internal parameter space
*  associated with the parameter.
      CALL SUBPAR_FINDPAR( PARAM, NAMCOD, STATUS )

*  Use the pointer to get the vector of values.
      CALL SUBPAR_GET1D( NAMCOD, MAXVAL, VALUES, ACTVAL, STATUS )

      END
