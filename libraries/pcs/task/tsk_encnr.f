      SUBROUTINE TASK_ENCNR ( NDIMS, DIMS, RVALS, STRING, STATUS )
*+
*  Name:
*     TASK_ENCNR

*  Purpose:
*     Encode an array as a character string

*  Language:
*     Starlink Fortran 77

*  Type Of Module:
*     SUBROUTINE

*  Invocation:
*     CALL TASK_ENCNR ( NDIMS, DIMS, RVALS, STRING, STATUS )

*  Description:
*     Convert the given multidimensional array into characters and
*     concatenate the values into a string with separators. The
*     dimensions of the array are delimited by [] following the ADAM
*     syntax.
*     There is a routine for each type C, D, I, L, R.

*  Arguments:
*     NDIMS=INTEGER (given)
*           number of dimensions of the given array
*     DIMS(NDIMS)=INTEGER (given)
*           the dimensions of the given array
*     RVALS(1:*)=REAL (given)
*           the given array, treated as a vector
*     STRING=CHARACTER*(*) (returned)
*           the returned string
*     STATUS=INTEGER

*  Algorithm:
*     Convert each of the given values into an element in a 1-D array of
*     strings. Then call the ADAM string building routine to concatenate
*     the strings into a single string with the correct syntax.

*  Authors:
*     B.D.Kelly (REVAD::BDK)
*     {enter_new_authors_here}

*  History:
*     06-NOV-1987 (REVAD::BDK):
*        Original
*     29-APR-1989 (AAOEPP::WFL):
*        Make it generic
*     04-OCT-1992 (RLVAD::AJC):
*        Use CHR
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'SAE_PAR'
 
*  Arguments Given:
      INTEGER NDIMS        ! number of dimensions of the given array
 
      INTEGER DIMS(NDIMS)  ! the dimensions of the given array
 
      REAL RVALS(1:*) ! the given array, treated as a vector
 
*  Arguments Returned:
      CHARACTER*(*) STRING ! the returned string
 
*  Status:
      INTEGER STATUS
 
*  Local Variables:
      CHARACTER*(40) CARRAY(20)  ! store for original type conversions
      INTEGER TOTNUM             ! number of items for conversion
      INTEGER J                  ! loop counter
      INTEGER NCHAR              ! size of encoded item
*.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
      TOTNUM = 1
      DO J = 1, NDIMS
         TOTNUM = TOTNUM * DIMS(J)
      ENDDO
 
      J = 0
      DO WHILE ( ( J .LT. TOTNUM ) .AND. ( STATUS .EQ. SAI__OK ) )
         J = J + 1
         CALL CHR_RTOC( RVALS(J), CARRAY(J), NCHAR )
      ENDDO
 
      CALL STRING_BUILDARR ( NDIMS, DIMS, CARRAY, STRING, STATUS )
 
      END
