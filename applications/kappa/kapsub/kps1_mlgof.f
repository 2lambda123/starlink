      SUBROUTINE KPS1_MLGOF( PARAM, OFMTHD, STATUS )
*+
*  Name:
*     KPS1_MLGOF

*  Purpose:
*     Gets the method to offset the lines in a multi-line plot.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_MLGOF( PARAM, OFMTHD, STATUS )

*  Description:
*     This routine obtains the way to vertically offset the lines in
*     a multi-line plot from the environment.

*  Arguments:
*     PARAM = CHARACTER * ( * ) (Given)
*        The name of the parameter used to get the method of offset 
*        from the user. They can take the value 'FREE', CONSTANT' and 
*        'AVERAGE'. The input can be abbreviated to an unambigious 
*        length and is case insensitive.
*     OFMTHD = INTEGER (Returned)
*        It specifies the method to offset the traces.
*
*          0 :'FREE' offset
*
*          1 :'CONSTANT' offset
*
*          2 :'AVERAGE' offset
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     WG: Wei Gong (IPMAF)
*     {enter_new_authors_here}

*  History:
*     28-FEB-1991 (WG):
*        Original version.
*     1991 June 18 (MJC):
*        Renamed from GETOFF.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER*( * ) PARAM

*  Arguments Returned:
      INTEGER OFMTHD

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER*( 8 ) METHOD     ! Specified offset method


*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Get the offset method from the enviroment.
      CALL PAR_CHOIC( PARAM, 'AVERAGE', 'FREE,CONSTANT,AVERAGE',
     :               .FALSE., METHOD, STATUS )

*  Check error, if so, report the error and exit.
      IF ( STATUS .EQ. SAI__OK ) THEN

*  Remove the leading blank of METHOD.
         CALL CHR_LDBLK( METHOD )      

*  Setting the returned offset code.
         IF ( METHOD( : 4 ) .EQ. 'FREE' ) THEN
            OFMTHD = 0
         ELSE IF ( METHOD .EQ. 'CONSTANT' ) THEN
            OFMTHD = 1
         ELSE IF ( METHOD( : 7 ) .EQ. 'AVERAGE' ) THEN
           OFMTHD = 2
         END IF
      END IF

 999  CONTINUE
      
      END
