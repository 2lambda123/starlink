      SUBROUTINE PAR_PUTVC( PARAM, NVAL, VALUES, STATUS )
*+
*  Name:
*     PAR_PUTVx
 
*  Purpose:
*     Puts an array of values into a parameter as if the parameter were
*     a vector.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL PAR_PUTVx( PARAM, NVAL, VALUES, STATUS )
 
*  Description:
*     This routine puts a 1-dimensional array of primitive values into
*     a parameter as it if the parameter were vectorized (i.e.
*     regardless of its actual dimensionality).  If necessary, the
*     specified array is converted to the type of the parameter.
 
*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The parameter name.
*     NVAL = INTEGER (Given)
*        The number of values that are to be put into the parameter.
*        It must match the actual parameter's size.
*     VALUES( NVAL ) = ? (Given)
*        The values to be put into the parameter.
*     STATUS = INTEGER (Given and Returned)
*        The global status .
 
*  Notes:
*     -  There is a routine for each of the data types character,
*     double precision, integer, logical, and real: replace "x" in the
*     routine name by C, D, I, L, or R respectively as appropriate.  The
*     VALUES argument must have the corresponding data type.
*     - In order to obtain a storage object for the parameter, the
*     current implementation of the underlying ADAM parameter system
*     will proceed in the same way as it does for input parameters.
*     This can result in users being prompted for 'a value'. This
*     behaviour, and how to avoid it, is discussed further in the
*     Interface Module Reference Manual (SUN/115).
*     -  Limit checks for IN, RANGE, MIN/MAX are not applied.
 
*  Algorithm:
*     Call the underlying parameter-system primitives.
 
*  Authors:
*     B D Kelly (REVAD::BDK)
*     A J Chipperfield (STARLINK)
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     20-NOV-1984:
*        Original (BDK)
*     1-JUN-1988:
*        Check import status
*        Revised prologue  (AJC)
*     7-JAN-1991:
*        Revised prologue again (AJC)
*     1992 March 27 (MJC):
*        Used SST prologues.
*     1992 November 13 (MJC):
*        Commented the code, and renamed the NAMECODE identifier.
*        Re-tidied the prologue.
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Dfeinitions:
      IMPLICIT NONE              ! No implicit typing
 
*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
 
*  Arguments Given:
      CHARACTER * ( * ) PARAM    ! Parameter Name
      INTEGER NVAL               ! Number of values
      CHARACTER*(*) VALUES( * )         ! Array to supply values
 
*  Status:
      INTEGER STATUS              ! Global status
 
*  Local Variables:
      INTEGER NAMCOD              ! Pointer to the parameter
 
*.
 
*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*  Find the parameter-system pointer to the internal parameter space
*  associated with the parameter.
      CALL SUBPAR_FINDPAR( PARAM, NAMCOD, STATUS )
 
*  Use the pointer to put the values into the parameter.
      CALL SUBPAR_PUTVC( NAMCOD, NVAL, VALUES, STATUS )
 
      END
