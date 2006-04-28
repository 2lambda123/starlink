      SUBROUTINE TASK_DECNR ( STRING, NMAXDIMS, MAXDIMS, NDIMS, DIMS,
     :                          RVALS, STATUS )
*+
*  Name:
*     TASK_DECNR

*  Purpose:
*     Decode a character string as an array

*  Language:
*     Starlink Fortran 77

*  Type Of Module:
*     SUBROUTINE

*  Invocation:
*     CALL TASK_DECNR ( STRING, NMAXDIMS, MAXDIMS, NDIMS, DIMS,
*                         RVALS, STATUS )

*  Description:
*     Convert the given character string, which is assumed to have
*     the ADAM syntax for an array, that is the whole is surrounded by
*     [] and the elements of the array are separated, into a 1-D array.
*     Future versions could support returning multi-dimensional arrays.
*     There is a routine for each type C, D, I, L, R.

*  Arguments:
*     STRING=CHARACTER*(*) (given)
*           the given character string
*     NMAXDIMS=INTEGER (given)
*           the maximum number of dimensions that can be returned
*     MAXDIMS(NMAXDIMS)=INTEGER (given)
*           the maximum array indices in the various dimensions that
*           can be returned
*     NDIMS=INTEGER (returned)
*           number of dimensions in the decoded array
*     DIMS(NDIMS)=INTEGER (returned)
*           sizes of dimensions of the decoded array
*     RVALS(1:*)=REAL (returned)
*           the decoded array, treated as a vector
*     STATUS=INTEGER

*  Algorithm:
*     Call the ADAM string splitting routine to split the string into a
*     1-D array of strings. Then convert each of these strings into an
*     element of the returned array using the appropriate TASK_DEC0 routine.

*  Authors:
*     W.F.Lupton (AAOEPP::WFL)
*     {enter_new_authors_here}

*  History:
*     29-APR-1989 (AAOEPP::WFL):
*        Original
*     05-OCT-1992: use TASK_DEC0 routine for portability.
*                  use only used length of CARRAY element. (RLVAD::AJC)
*     24-AUG-1993 (RLVAD::AJC):
*        Remove istat - not used
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'SAE_PAR'
 
*  Arguments Given:
      CHARACTER*(*) STRING ! the given character string
 
      INTEGER NMAXDIMS     ! the maximum number of dimensions that can be
                           ! returned
 
      INTEGER MAXDIMS(NMAXDIMS) ! the maximum array indices in the various
                           ! dimensions that can be returned
 
*  Arguments Returned:
      INTEGER NDIMS        ! number of dimensions in the decoded array
 
      INTEGER DIMS(1:*)    ! sizes of dimensions of the given array
 
      REAL RVALS(1:*)  ! the decoded array, treated as a vector
 
*  Status:
      INTEGER STATUS
 
*    External references :
      INTEGER STRING_INANYL
      EXTERNAL STRING_INANYL
      INTEGER STRING_INANYR
      EXTERNAL STRING_INANYR
 
*  Local Variables:
      CHARACTER*(40) CARRAY(20)  ! store for original type conversions
      INTEGER CLENGTHS(20)       ! lengths of original converted strings
      INTEGER START              ! start position in string
      INTEGER END                ! end position in string
      INTEGER COUNT              ! number of items for conversion
      INTEGER J                  ! loop counter
*.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
*
*    Only single-dimensioned arrays are supported
*
      NDIMS = 1
      DIMS(1) = 0
*
*    Remove [] if present
*
      START = STRING_INANYL ( STRING, ' ' )
      IF ( START .EQ. 0 ) THEN
         START = 1
      ELSE IF ( STRING(START:START) .EQ. '[' ) THEN
         START = START + 1
      ENDIF
      END = STRING_INANYR ( STRING, ' ' )
      IF ( END .EQ. 0 ) THEN
         END = LEN ( STRING )
      ELSE IF ( STRING(END:END) .EQ. ']' ) THEN
         END = END - 1
      ENDIF
*
*    Split string into its components
*
      IF ( START .LE. END ) THEN
         CALL STRING_ARRCHAR ( STRING(START:END), 20, DIMS(1), CARRAY,
     :                         CLENGTHS, STATUS )
         J = 0
         COUNT = MIN ( DIMS(1), MAXDIMS(1) )
         DO WHILE ( ( J .LT. COUNT ) .AND. ( STATUS .EQ. SAI__OK ) )
            J = J + 1
            CALL TASK_DEC0R ( CARRAY(J)(1:CLENGTHS(J)), RVALS(J),
     :      STATUS )
         ENDDO
      ENDIF
 
      END
