
*+  ADDSCA2D - add scalar to every pixel of a 2-d array

      SUBROUTINE ADDSCA2D ( INARRAY, DIMS1, DIMS2, SCALAR, OUTARRAY, 
     :                      STATUS )

*    Description :
*
*     This routine fills the output array pixels with the results
*     of adding a given real scalar value to the pixels of the
*     input array one at a time.
*
*    Invocation :
*
*     CALL ADDSCA2D( INARRAY, DIMS, SCALAR; OUTARRAY, STATUS )
*
*    Method :
*
*     Check for error on entry - if not o.k. return immediately
*     For all pixels of the output array
*        Outarray pixel = Inarray pixel + Scalar
*     Endfor
*     Return
*
*    Bugs :
*
*     None known.
*
*    Authors :
*
*     Mark McCaughrean UoE ( REVA::MJM )
*
*    History :
*
*     26-06-1986 :  First implementation (REVA::MJM)
*     12-AUG-1994   Changed DIM arguments so that routine will compile(SKL@JACH)
*
*    Type definitions :

      IMPLICIT  NONE              ! no implicit typing allowed

*    Global constants :

      INCLUDE  'SAE_PAR'          ! SSE global definitions

*    Import :

      INTEGER
     :   DIMS1, DIMS2                ! dimensions of arrays

      REAL
     :   INARRAY( DIMS1, DIMS2 ),   ! input array
     :   SCALAR           ! number to be added to each pixel of array

*    Export :

      REAL
     :   OUTARRAY( DIMS1, DIMS2 )  ! output array

*    Status :

      INTEGER  STATUS             ! global status parameter

*    Local variables :

      INTEGER
     :   I, J             ! counter variables 

*-
*    check status on entry - return if not o.k.
      IF ( STATUS .NE. SAI__OK ) THEN
         RETURN
      ENDIF


*    loop round all rows of the output array
      DO  J  =  1, DIMS2

*       loop round all pixels of the current row
         DO  I  =  1, DIMS1

*          set output pixel to be input array pixel plus scalar
            OUTARRAY( I, J )  =  INARRAY( I, J ) + SCALAR

         END DO

      END DO

*    return
      END
