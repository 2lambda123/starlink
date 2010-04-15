      SUBROUTINE PAR_PUT0D ( PARAM, VALUE, STATUS )
*+
*  Name:
*     PAR_PUT0x

*  Purpose:
*     Puts a scalar value into a parameter.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL PAR_PUT0x( PARAM, VALUE, STATUS )

*  Description:
*     This routine puts a scalar value into a parameter.  If necessary,
*     the specified value is converted to the type of the parameter.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The parameter name.
*     VALUE = ? (Given)
*        The value to be put into the parameter.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  There is a routine for each of the data types character,
*     double precision, integer, logical, and real: replace "x" in the
*     routine name by C, D, I, L, or R respectively as appropriate.  The
*     VALUE argument must have the corresponding data type.
*     -  A scalar (0-dimensional) parameter is different from a vector
*     (1-dimensional) parameter containing a single value.
*     -  In order to obtain a storage object for the parameter, the
*     current implementation of the underlying ADAM parameter system
*     will proceed in the same way as it does for input parameters.
*     This can result in users being prompted for 'a value'. This
*     behaviour, and how to avoid it, is discussed further in the
*     Interface Module Reference Manual (SUN/115).
*     -  Limit checks for IN, RANGE, MIN/MAX are not applied.

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
*     26-OCT-1984 (BDK):
*        Original version.
*     7-JUN-1988 (AJC):
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
      CHARACTER * ( * ) PARAM
      DOUBLE PRECISION VALUE

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER NAMCOD             ! Pointer to parameter in tables

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Find the parameter-system pointer to the internal parameter space
*  associated with the parameter.
      CALL SUBPAR_FINDPAR( PARAM, NAMCOD, STATUS )

*  Use the pointer to put value into the parameter.
      CALL SUBPAR_PUT0D( NAMCOD, VALUE, STATUS )

      END
