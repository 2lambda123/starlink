      SUBROUTINE CCD1_CMULT( BAD, ITYPE, IPOINT, EL, CVAL, IPWORK,
     :                       NERR, STATUS )
*+
*  Name:
*     CCD1_CMULT

*  Purpose:
*     To multiply a data array by a const returning the result in
*     the same array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCD1_CMULT( BAD, ITYPE, IPOINT, EL, CVAL, IPWORK, NERR,
*                      STATUS )

*  Description:
*     This routine just dummys to the appropriate CCG1_CMLT routine,
*     and copies the result back into the IPOINT array.

*  Arguments:
*     ITYPE = CHARACTER * ( * ) (Given)
*        The type of the data pointed to by IPOINT.
*     BAD = LOGICAL (Given and Returned)
*        Flag for BAD pixels present.
*     IPOINT = INTEGER (Given and Returned)
*        Pointer to data array.
*     EL = INTEGER (Given)
*        Number of elements in array.
*     CVAL = DOUBLE PRECISION (Given)
*        Constant to multiply.
*     IPWORK = INTEGER (Given and Returned)
*        Pointer to workspace (same size as input array).
*     NERR = INTEGER (Returned)
*        Number of numeric errors that occurred when performing
*        multiplication.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  Uses array pointers

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     {enter_new_authors_here}

*  History:
*     30-APR-1991 (PDRAPER):
*        Original version.
*     20-MAR-1992 (PDRAPER):
*        Added NERR argument.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CNF_PAR'          ! For CNF_PVAL function

*  Arguments Given:
      CHARACTER * ( * ) ITYPE
      DOUBLE PRECISION CVAL
      INTEGER EL

*  Arguments Given and Returned:
      INTEGER IPOINT
      INTEGER IPWORK
      LOGICAL BAD

*  Arguments Returned:
      INTEGER NERR

*  Status:
      INTEGER STATUS             ! Global status

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Call the appropriate subtraction routine by type. Copy the result to
*  the  first array.
      IF ( ITYPE .EQ. '_UBYTE' ) THEN
         CALL CCG1_CMLTUB( BAD, EL, %VAL( CNF_PVAL( IPOINT ) ), CVAL,
     :                     %VAL( CNF_PVAL( IPWORK ) ), NERR, STATUS )
         CALL CCG1_COPAUB( EL, %VAL( CNF_PVAL( IPWORK ) ), 
     :                     %VAL( CNF_PVAL( IPOINT ) ), STATUS )
      ELSE IF ( ITYPE .EQ. '_BYTE' ) THEN
         CALL CCG1_CMLTB( BAD, EL, %VAL( CNF_PVAL( IPOINT ) ), CVAL, 
     :                    %VAL( CNF_PVAL( IPWORK ) ),
     :                    NERR, STATUS )
         CALL CCG1_COPAB( EL, %VAL( CNF_PVAL( IPWORK ) ), 
     :                    %VAL( CNF_PVAL( IPOINT ) ), STATUS )
      ELSE IF ( ITYPE .EQ. '_UWORD' ) THEN
         CALL CCG1_CMLTUW( BAD, EL, %VAL( CNF_PVAL( IPOINT ) ), CVAL,
     :                     %VAL( CNF_PVAL( IPWORK ) ), NERR, STATUS )
         CALL CCG1_COPAUW( EL, %VAL( CNF_PVAL( IPWORK ) ), 
     :                     %VAL( CNF_PVAL( IPOINT ) ), STATUS )
      ELSE IF ( ITYPE .EQ. '_WORD' ) THEN
         CALL CCG1_CMLTW( BAD, EL, %VAL( CNF_PVAL( IPOINT ) ), CVAL, 
     :                    %VAL( CNF_PVAL( IPWORK ) ),
     :                    NERR, STATUS )
         CALL CCG1_COPAW( EL, %VAL( CNF_PVAL( IPWORK ) ), 
     :                    %VAL( CNF_PVAL( IPOINT ) ), STATUS )
      ELSE IF ( ITYPE .EQ. '_INTEGER' ) THEN
         CALL CCG1_CMLTI( BAD, EL, %VAL( CNF_PVAL( IPOINT ) ), CVAL, 
     :                    %VAL( CNF_PVAL( IPWORK ) ),
     :                    NERR, STATUS )
         CALL CCG1_COPAI( EL, %VAL( CNF_PVAL( IPWORK ) ), 
     :                    %VAL( CNF_PVAL( IPOINT ) ), STATUS )
      ELSE IF ( ITYPE .EQ. '_REAL' ) THEN
         CALL CCG1_CMLTR( BAD, EL, %VAL( CNF_PVAL( IPOINT ) ), CVAL, 
     :                    %VAL( CNF_PVAL( IPWORK ) ),
     :                    NERR, STATUS )
         CALL CCG1_COPAR( EL, %VAL( CNF_PVAL( IPWORK ) ), 
     :                    %VAL( CNF_PVAL( IPOINT ) ), STATUS )
      ELSE IF ( ITYPE .EQ. '_DOUBLE' ) THEN
         CALL CCG1_CMLTD( BAD, EL, %VAL( CNF_PVAL( IPOINT ) ), CVAL, 
     :                    %VAL( CNF_PVAL( IPWORK ) ),
     :                    NERR, STATUS )
         CALL CCG1_COPAD( EL, %VAL( CNF_PVAL( IPWORK ) ), 
     :                    %VAL( CNF_PVAL( IPOINT ) ), STATUS )
      ELSE

*  Unsupported numeric type, issue error.
         STATUS = SAI__ERROR
         CALL MSG_SETC( 'TYPE', ITYPE )
         CALL ERR_REP( 'CCD1_CMULT1',
     :   '  CCD1_CMULT: Unsupported numeric type ^TYPE', STATUS )
      END IF
      BAD = BAD .OR. ( NERR .NE. 0 )

      END
* $Id$
