      SUBROUTINE KPG1_CCPRO( PNCOMP, COMP, NDFI, NDFO, STATUS )
*+
*  Name:
*     KPG1_CCPRO

*  Purpose:
*     Gets a character component for an output NDF with optional
*     propagation from another NDF.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_CCPRO( PNCOMP, COMP, NDFI, NDFO, STATUS )

*  Description:
*     This routine uses the parameter sysyem to obtain a value for a
*     selected character component of an output or updated NDF.  If the
*     null value is supplied, the character component is copied from
*     an input NDF to the output NDF, unless the component is undefined,
*     in the input, in which case it is left undefined in the output.

*  Arguments:
*     PNCOMP = CHARACTER * ( * ) (Given)
*        The name of the ADAM parameter used to obtain the character
*        component's value.
*     COMP = CHARACTER * ( * ) (Given)
*        The name of the character component.  It must be 'TITLE',
*        'LABEL', or 'UNITS'.
*     NDFI = INTEGER (Given)
*        The identifier of the input NDF from which a character component
*        is to be copied to the output NDF.
*     NDFO = INTEGER (Given)
*        The identifier of the output or updated NDF to which a
*        character component is to be written.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  [optional_subroutine_items]...
*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1994 September 27 (MJC):
*        Original version.
*     9-JAN-2001 (DSB):
*        Changed behaviour so that the component is left undefined in the
*        output NDF (rather than being set blank) if a null parameter value 
*        is supplied, and no component exists in the input NDF.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER * ( * ) PNCOMP
      CHARACTER * ( * ) COMP
      INTEGER NDFI
      INTEGER NDFO

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER * ( 80 ) VALUE   ! Value of the character component
      LOGICAL THERE              ! Is the component defined in the input NDF?

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  See if the component is defined in the input NDF.
      CALL NDF_STATE( NDFI, COMP, THERE, STATUS )

*  If so, use the current value as the parameter's dynamic default, and
*  store it as an initial value in the output NDF.
      IF( THERE ) THEN
        CALL NDF_CGET( NDFI, COMP, VALUE, STATUS )
        CALL PAR_DEF0C( PNCOMP, VALUE, STATUS )
        CALL NDF_CPUT( VALUE, NDFO, COMP, STATUS )
      END IF

*  Obtain the value for the character component from the parameter
*  system.  If a null value is supplied, any existing component is
*  retained.
      CALL NDF_CINP( PNCOMP, NDFO, COMP, STATUS )

      END
