      SUBROUTINE SUBPAR_DEF0D ( NAMECODE, DVALUE, STATUS )
      IMPLICIT NONE
 
*+
*  Name:
*     SUBPAR_DEF0D
 
*  Purpose:
*     Set dynamic default scalar value.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL SUBPAR_DEF0D ( NAMECODE, VALUE, STATUS )
 
*  Description:
*     This routine sets a default value for a scalar primitive object
*     associated with a Parameter.
*     There is a routine for each access type, DOUBLE PRECISION:
 
*        SUBPAR_DEF0D    DOUBLE PRECISION
*        SUBPAR_DEF0R    REAL
*        SUBPAR_DEF0I    INTEGER
*        SUBPAR_DEF0L    LOGICAL
*        SUBPAR_DEF0C    CHARACTER[*n]
 
*     If the object data type differs from the access type, DOUBLE PRECISION, then
*     conversion is performed (if allowed).
 
*  Arguments:
*     NAMECODE=INTEGER (given)
*        code-number of the parameter
*     DVALUE=DOUBLE PRECISION
*        Expression specifying the default value for the object.
*     STATUS=INTEGER
 
*  Algorithm:
*     Use SUBPAR_DEF1D.
 
*  Authors:
*     BDK: B D Kelly (ROE)
*     {enter_new_authors_here}
 
*  History:
*     10-DEC-1984 (BDK):
*        Original
*     05-JUN-1985 (BDK):
*        Set PARDYN(2,NAMECODE) values
*     09-NOV-1987 (BDK):
*        Use SUBPAR_DEF1D
*     09-MAR-1992 (AJC):
*        Use the special flag NVAL = 0 in calling _DEF1D
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Global Constants:
      INCLUDE 'SAE_PAR'
 
 
*  Arguments Given:
      INTEGER NAMECODE                  ! Parameter code number
 
      DOUBLE PRECISION DVALUE			! Scalar to supply value
 
*    Status return :
      INTEGER STATUS			! Status Return
 
 
*  Local Variables:
      INTEGER NVAL                      ! number of values
 
*.
 
 
      IF (STATUS .NE. SAI__OK) RETURN
 
*
*   set the number of values and call SUBPAR_DEF1D.
*   NVAL = 0 has special meaning i.e a scalar value
*
      NVAL = 0
      CALL SUBPAR_DEF1D ( NAMECODE, NVAL, DVALUE, STATUS )
 
      END
