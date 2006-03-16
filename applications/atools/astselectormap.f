      SUBROUTINE ASTSELECTORMAP( STATUS )
*+
*  Name:
*     ASTSELECTORMAP

*  Purpose:
*     Create a SelectorMap.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL ASTSELECTORMAP( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     This application creates a new SelectorMap and optionally initialises its 
*     attributes. 
*
*     A SelectorMap is a Mapping that identifies which Region contains 
*     a given input position.
*     
*     A SelectorMap encapsulates a number of Regions that all have the same 
*     number of axes and represent the same coordinate Frame. The number of 
*     inputs (Nin attribute) of the SelectorMap equals the number of axes 
*     spanned by one of the encapsulated Region. All SelectorMaps have only 
*     a single output. SelectorMaps do not define an inverse transformation.
*
*     For each input position, the forward transformation of a SelectorMap 
*     searches through the encapsulated Regions (in the order supplied when 
*     the SelectorMap was created) until a Region is found which contains
*     the input position. The index associated with this Region is
*     returned as the SelectorMap output value (the index value is the
*     position of the Region within the list of Regions supplied when the 
*     SelectorMap was created, starting at 1 for the first Region). If an
*     input position is not contained within any Region, a value of zero is 
*     returned by the forward transformation.
*
*     If a compound Mapping contains a SelectorMap in series with its own
*     inverse, the combination of the two adjacent SelectorMaps will be 
*     replaced by a UnitMap when the compound Mapping is simplified using
*     astsimplify.
*
*     In practice, SelectorMaps are often used in conjunction with SwitchMaps.

*  Usage:
*     astselectormap reg1 reg2 options result

*  ADAM Parameters:
*     REG1-REG25 = LITERAL (Given)
*        A set of 25 parameters associated with the NDFs or text files holding 
*        the Regions. All the supplied Regions must relate to the same 
*        coordinate Frame. The number of axes in this coordinate Frame 
*        defines the number of inputs for the SelectorMap. There can be no 
*        missing Regions; if REG3 is to be processed then REG1 and REG2 must 
*        also be supplied. A null value (!) should be supplied to indicate 
*        that there are no further Regions. REG3 to REG25 default to null 
*        (!).  At least one Region must be supplied.
*     OPTIONS = LITERAL (Read)
*        A string containing an optional comma-separated list of attribute 
*        assignments to be used for initialising the new SelectorMap. 
*     RESULT = LITERAL (Read)
*        A text file to receive the new SelectorMap.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     16-MAR-2006 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
*  Type Definitions:
      IMPLICIT NONE              ! no default typing allowed

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST constants and function declarations
      INCLUDE 'PAR_ERR'          ! PAR error constants 

*  Status:
      INTEGER STATUS

*  External References:
      EXTERNAL AST_ISAREGION

*  Local Constants:
      INTEGER MAXREG
      PARAMETER ( MAXREG = 25 )

*  Local Variables:
      CHARACTER PARAM*15
      INTEGER IAT
      INTEGER NREG
      INTEGER RESULT
      INTEGER REGS( MAXREG )
*.

*  Check inherited status.      
      IF( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Get the first two route Regions. These must be supplied.
      CALL ATL1_GTOBJ( 'REG1', 'Region', AST_ISAREGION, 
     :                 REGS( 1 ), STATUS )
      CALL ATL1_GTOBJ( 'REG2', 'Region', AST_ISAREGION, 
     :                 REGS( 2 ), STATUS )

*  Loop round getting route Regions until a null value is supplied. 
*  These can be omitted.
      NREG = 3
      DO WHILE( NREG .LE. MAXREG .AND. STATUS .EQ. SAI__OK )
         PARAM = 'REG'
         IAT = 3
         CALL CHR_PUTI( NREG, PARAM, IAT )
         CALL ATL1_GTOBJ( PARAM, 'Region', AST_ISAREGION, 
     :                    REGS( NREG ), STATUS )
         IF( STATUS .EQ. PAR__NULL ) THEN
            CALL ERR_ANNUL( STATUS )
            NREG = NREG - 1
            GO TO 10
         ELSE
            NREG = NREG + 1
         END IF
      END DO
 10   CONTINUE

*  Create the required SelectorMap.
      RESULT = AST_SELECTORMAP( NREG, REGS, ' ', STATUS )

*  Store the required attribute values.
      CALL ATL1_SETOP( 'OPTIONS', RESULT, STATUS )

*  Write the results out to a text file.
      CALL ATL1_PTOBJ( 'RESULT', ' ', RESULT, STATUS )

 999  CONTINUE

*  End the AST context.
      CALL AST_END( STATUS )

*  Give a context message if anything went wrong.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL ERR_REP( 'ASTSELECTORMAP_ERR', 'Error creating a new '//
     :                 'SelectorMap.', STATUS )
      END IF

      END
