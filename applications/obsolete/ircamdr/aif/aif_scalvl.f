*+  AIF_SCALVL - scale and shift a vectorised array of type LOGICAL
      SUBROUTINE AIF_SCALVL( DIM, BIAS, SCALE, ARRAY, STATUS )
*    Description :
*     All the elements of the array are scaled and shifted in situ
*     using the linear formula
*
*        ELEMENT = BIAS + ( SCALE * ELEMENT )
*
*     The array given need not be 1-D, as long as DIM contains the total
*     size of the array (i.e. the product of all its dimensions).
*    Invocation :
*      CALL AIF_SCALVL( DIM, BIAS, SCALE; ARRAY, STATUS )
*    Parameters :
*     DIM           = INTEGER( READ )
*           The size of the array
*     BIAS          = LOGICAL( READ )
*           Bias to add on to array
*     SCALE         = REAL( READ )
*           Scale factor to multiply array by
*     ARRAY( DIM )  = LOGICAL( READ )
*           Array to be modified
*     STATUS        = INTEGER( UPDATE )
*           Global status. If this has an error value on entry then
*           this routine will terminate without execution.
*    Method :
*     If no error on entry then
*        For all the elements of the array
*           apply the formula
*        Endfor
*     Endif
*    Deficiencies :
*     The double precision version of this routine can only use single
*     precision scale factor because the routine is generic
*    Bugs :
*    Authors :
*     Steven Beard (ROE::SMB)
*    History :
*     30/03/1984 : original version                (ROE::SMB)
*     10/06/1984 : modified to generic AIF version (ROE::SMB)
*    Type Definitions :
      IMPLICIT NONE         ! must declare all variables
*    Global constants :
      INCLUDE 'SAE_PAR'     ! SSE global variables
*    Import :
      INTEGER
     :  DIM          ! dimension of array
      LOGICAL
     :  BIAS         ! bias for array
      REAL
     :  SCALE        ! scale factor for array
*    Import-Export :
      LOGICAL
     :  ARRAY( DIM ) ! array to be scaled
*    Status :
      INTEGER
     :  STATUS       ! global status
*    Local variables :
      INTEGER
     :  I            ! array index
*-
 
*   check for error on entry
      IF ( STATUS .NE. SAI__OK ) RETURN

      STATUS = SAI__ERROR
      CALL ERR_REP('LOG_ERR','Makes no sense to scale a LOGICAL'//
     :     ' array', STATUS)
 
      END
