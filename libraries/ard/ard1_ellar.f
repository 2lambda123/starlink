      SUBROUTINE ARD1_ELLAR( NDIM, CFRM, ELEM, L, IPOPND, IOPND, SZOPND,
     :                       NARG, I, KEYW, STATUS )
*+
*  Name:
*     ARD1_ELLAR

*  Purpose:
*     Assemble argument list for an ELLIPSE keyword

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARD1_ELLAR( NDIM, CFRM, ELEM, L, IPOPND, IOPND, SZOPND, NARG,
*                      I, KEYW, STATUS )

*  Description:
*     The supplied arguments are stored on the operand stack.

*  Arguments:
*     NDIM = INTEGER (Given)
*        The dimensionality of the ARD description (i.e. the number of
*        values required to specify a position).
*     CFRM = INTEGER (Given)
*        An AST pointer to a Frame describing user coordinates.
*     ELEM = CHARACTER * ( * ) (Given)
*        An element of an ARD description.
*     L = INTEGER (Given)
*        The index of the final character in ELEM to be checked.
*     IPOPND = INTEGER (Given)
*        The pointer to the array holding the operand stack.
*     IOPND = INTEGER (Given and Returned)
*        The index within the operand stack at which the next value
*        should be stored.
*     SZOPND = INTEGER (Given and Returned)
*        The size of the operand stack. This is increased if necessary.
*     NARG = INTEGER (Given and Returned)
*        The number of arguments so far obtained. This should be
*        supplied equal to -1 if no argument list has yet been found.
*     I = INTEGER (Given and Returned)
*        The index of the next character to be checked in ELEM.
*     KEYW = LOGICAL (Given and Returned)
*        Returned as .FALSE. if the argument list for the keyword has
*        been completed.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     17-FEB-1994 (DSB):
*        Original version.
*     18-JUL-2001 (DSB):
*        Modified for ARD version 2.0.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST_ constants
      INCLUDE 'ARD_CONST'        ! ARD_ private constants
      INCLUDE 'ARD_ERR'          ! ARD_ error constants

*  Arguments Given:
      INTEGER NDIM
      INTEGER CFRM
      CHARACTER ELEM*(*)
      INTEGER L

*  Arguments Given and Returned:
      INTEGER IPOPND
      INTEGER IOPND
      INTEGER SZOPND
      INTEGER NARG
      INTEGER I
      LOGICAL KEYW

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      INTEGER AXIS               ! Axis index
      LOGICAL OK                 ! Was an argument value obtained?
      DOUBLE PRECISION VALUE     ! The argument value


*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Report an error and abort if the dimensionality is not 2.
      IF( NDIM .NE. 2 ) THEN
         STATUS = ARD__NOT2D
         CALL ERR_REP( 'ARD1_ELLAR_ERR1', 'ARD mask is not 2 '//
     :                 'dimensional.', STATUS )
         GO TO 999
      END IF

*  Attempt to read argument value from the current element until the
*  end of the element, or the end of the argument list is encountered.
      DO WHILE( I .LE. L .AND. KEYW .AND. STATUS .EQ. SAI__OK ) 

*  First argument refers to axis 1.
         IF( NARG .EQ. 0 ) THEN
            AXIS = 1

*  Second argument refers to axis 2.
         ELSE IF( NARG .EQ. 1 ) THEN
            AXIS = 2

*  Third and fourth arguments are distances. Find the index of the axis 
*  along which they are measured.
         ELSE IF( NARG .LT. 4 ) THEN
            CALL ARD1_DSTAX( CFRM, AXIS, STATUS )

*  The fifth argument is interpreted as a simple floating point value.
         ELSE 
            AXIS = 0
         END IF

*  Read the next argument.
         CALL ARD1_GTARG( CFRM, AXIS, ELEM, L, I, OK, KEYW, VALUE, 
     :                    STATUS )

*  If an argument was obtained, store it on the operands stack.
         IF( OK ) THEN
            NARG = NARG + 1
            CALL ARD1_STORD( VALUE, SZOPND, IOPND, IPOPND, STATUS )

*  If the end of the argument list has been reached, report an error if
*  the number of arguments obtained is incorrect.
         ELSE IF( .NOT. KEYW ) THEN
 
            IF( NARG .NE. 5 .AND. STATUS .EQ. SAI__OK ) THEN
               STATUS = ARD__ARGS
               CALL ERR_REP( 'ARD1_ELLAR_ERR1', 'Incorrect number of '//
     :                       'arguments found.', STATUS )
            END IF

         END IF

      END DO

 999  CONTINUE

      END
