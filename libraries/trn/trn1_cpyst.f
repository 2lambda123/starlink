      SUBROUTINE TRN1_CPYST( STR1, STR2, STATUS )








*+
*  Name:
*     TRN1_CPYST

*  Purpose:
*     copy the contents of a structure.

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL TRN1_CPYST( STR1, STR2, STATUS )

*  Description:
*     The routine copies all the components of one structure into a
*     second structure.  Any existing components in the second
*     structure whose names clash with components being copied are first
*     erased.

*  Authors:
*     R.F. Warren-Smith (DUVAD::RFWS)
*     {enter_new_authors_here}

*  History:
*     11-FEB-1988:  Original version (DUVAD::RFWS)
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-


*  Type Definitions:
      IMPLICIT NONE             ! No implicit typing


*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants


*  Arguments Given:
      CHARACTER * ( * ) STR1    ! Locator to first structure
      CHARACTER * ( * ) STR2    ! Locator to second structure


*  Arguments Given and Returned:
*     <declarations and descriptions for imported/exported arguments>


*  Arguments Returned:
*     <declarations and descriptions for exported arguments>


*  Status:
      INTEGER STATUS            ! Error status


*  External References:
*     <declarations for external function references>


*  Global Variables:
*     <any INCLUDE files for global variables held in named COMMON>


*  Local Constants:
*     <local constants defined by PARAMETER>


*  Local Variables:
      LOGICAL THERE             ! Whether a component is present
      INTEGER NCOMP1            ! Number of components in structure 1
      INTEGER NCOMP2            ! Number of components in structure 2
      INTEGER ICOMP             ! Loop counter for components
      CHARACTER * ( DAT__SZLOC ) LOCC
                                ! Locator to structure component
      CHARACTER * ( DAT__SZNAM ) NAME
                                ! Structure component name


*  Internal References:
*     <declarations for internal functions>


*  Local Data:
*     <any DATA initialisations for local variables>


*.



*   Check status.
      IF( STATUS .NE. SAI__OK ) RETURN


*   Find the number of components in each structure.
      NCOMP1 = 0
      CALL DAT_NCOMP( STR1, NCOMP1, STATUS )
      NCOMP2 = 0
      CALL DAT_NCOMP( STR2, NCOMP2, STATUS )


*   Locate each component in the first structure in turn and obtain its
*   name.
      ICOMP = 0
      DO WHILE ( ( ICOMP .LT. NCOMP1 ) .AND. ( STATUS .EQ. SAI__OK ) )
        ICOMP = ICOMP + 1
        CALL DAT_INDEX( STR1, ICOMP, LOCC, STATUS )
        CALL DAT_NAME( LOCC, NAME, STATUS )


*   See if there is a component with the same name in the second
*   structure.  If so, erase it.
        IF( NCOMP2 .GT. 0 ) THEN
          THERE = .FALSE.
          CALL DAT_THERE( STR2, NAME, THERE, STATUS )
          IF( THERE ) CALL DAT_ERASE( STR2, NAME, STATUS )
        ENDIF


*   Copy the component across from the first structure and annul the
*   locator.
        CALL DAT_COPY( LOCC, STR2, NAME, STATUS )
        CALL DAT_ANNUL( LOCC, STATUS )


*   End of "locate each component in turn" loop.
      ENDDO


*   Exit routine.
      END
