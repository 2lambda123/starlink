*+  USI_DELET - Delete environment value
      SUBROUTINE USI_DELET( PAR, STATUS )
*    Description :
*     <description of what the subroutine does - for user info>
*    Method :
*     <description of how the subroutine works - for programmer info>
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*
*     David J. Allan (JET-X, University of Birmingham)
*
*    History :
*
*     21 May 93 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'USI0_PAR'
*
*    Import :
*
      CHARACTER*(*)		PAR			! Parameter name
*
*    Status :
*
      INTEGER 			STATUS
*
*    Local variables :
*
      INTEGER			RPTR			! Facility routine
*-

*    New error context
      CALL ERR_MARK

*    Locate the DELET facility in this context
      CALL USI0_LOCRTN( USI__F_DELET, RPTR, STATUS )

*    Invoke it
      CALL USI_DELET_E( %VAL(RPTR), PAR, STATUS )

*    Restore error context
      CALL ERR_RLSE

      END



*+  USI_DELET_E - Invoke parameter deleting routine
      SUBROUTINE USI_DELET_E( DELET_RTN, PAR, STATUS )
*    Description :
*     <description of what the subroutine does - for user info>
*    Method :
*     <description of how the subroutine works - for programmer info>
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*
*     David J. Allan (JET-X, University of Birmingham)
*
*    History :
*
*     21 May 93 : Original (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
*
*    Import :
*
      EXTERNAL			DELET_RTN		! Cancel routine
      CHARACTER*(*)		PAR			! Parameter name
*
*    Status :
*
      INTEGER 			STATUS
*-

*    Check status
      IF ( STATUS .NE. SAI__OK ) RETURN

*    Invoke the DELET routine
      CALL DELET_RTN( PAR, STATUS )

      END
