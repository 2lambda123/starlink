      SUBROUTINE PAR_DEF0L ( PARAM, VALUE, STATUS )
*+
*  Name:
*     PAR_DEF0x
 
*  Purpose:
*     Sets a scalar dynamic default parameter value.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL PAR_DEF0x( PARAM, VALUE, STATUS )
 
*  Description:
*     This routine sets a scalar as the dynamic default value for a
*     parameter. The dynamic default may be used as the parameter value
*     by means of appropriate specifications in the interface file.
 
*     If the declared parameter type differs from the type of the
*     value supplied, then conversion is performed.
 
*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The name of the parameter.
*     VALUE = ? (Given)
*        The dynamic default value for the parameter.
*     STATUS = INTEGER (Given and Returned)
*        The global status.
 
*  Notes:
*     -  There is a routine for each of the data types character,
*     double precision, integer, logical, and real: replace "x" in the
*     routine name by C, D, I, L, or R respectively as appropriate.  The
*     VALUE argument must have the corresponding data type.
 
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
*     10-DEC-1984 (BDK):
*        Original version.
*     1-JUN-1988 (AJC):
*        Revised prologue
*     9-NOV-1990 (AJC):
*        Revised prologue again
*     1992 March 27 (MJC):
*        Used SST prologues.
*     1992 November 9 (MJC):
*        Used PARAM as the first argument for consistency with other
*        routines.
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
      INCLUDE 'SAE_PAR'          ! SAE Constants
 
*  Arguments Given:
      CHARACTER * ( * ) PARAM    ! Parameter Name
      LOGICAL VALUE               ! Scalar to supply value
 
*  Status:
      INTEGER STATUS             ! Global status
 
*  Local Variables:
      INTEGER NAMCOD             ! Pointer to parameter
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Find the parameter-system pointer to the internal parameter space
*  associated with the parameter.
      CALL SUBPAR_FINDPAR( PARAM, NAMCOD, STATUS )
 
*  Use the pointer to set the dynamic default value.
      CALL SUBPAR_DEF0L( NAMCOD, VALUE, STATUS )
 
      END
