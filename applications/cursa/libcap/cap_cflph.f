      SUBROUTINE CAP_CFLPH (FILNME, INSCON, ZEROP, ATMOS, STATUS)
*+
*  Name:
*     CAP_CFLPH
*  Purpose:
*     Write a file of photometry trasformation coefficients.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAP_CFLPH (FILNME, INSCON, ZEROP, ATMOS; STATUS)
*  Description:
*     Write a file of photometry trasformation coefficients.
*  Arguments:
*     FILNME  =  CHARACTER*(*) (Given)
*        Name of the file.
*     INSCON  =  DOUBLE PRECISION (Given)
*        Arbitrary constant applied to the instrumental magnitudes.
*     ZEROP  =  DOUBLE PRECISION (Given)
*        Zero point.
*     ATMOS  =  DOUBLE PRECISION (Given)
*        Atmospheric extinction.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Attempt to open the file.
*     If ok then
*       Write the transformation coefficients.
*       Attempt to close the file.
*       Report any error.
*     else
*       Report error opening the file.
*     end if
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Edinburgh)
*  History:
*     9/5/97  (ACD): Original version.
*     7/10/97 (ACD): First stable version.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'SAE_PAR'           ! Standard Starlink constants.
*  Arguments Given:
      CHARACTER
     :  FILNME*(*)
      DOUBLE PRECISION
     :  INSCON,
     :  ZEROP,
     :  ATMOS
*  Status:
      INTEGER STATUS             ! Global status.
*  Local Variables:
      INTEGER
     :  FUNIT,    ! Fortran unit number for writing the file.
     :  LSTAT     ! Local Fortran I/O status.
*.

      IF (STATUS .EQ. SAI__OK) THEN

*
*       Attempt to open the file and proceed if ok.


         CALL FIO_GUNIT (FUNIT, STATUS)

         OPEN(UNIT=FUNIT, NAME=FILNME, STATUS='UNKNOWN',
     :     FORM='UNFORMATTED', IOSTAT=LSTAT)
         CALL FIO_SERR (LSTAT, STATUS)

         IF (STATUS .EQ. SAI__OK) THEN

*
*          Write the transformation coefficients.

            WRITE(FUNIT, IOSTAT=LSTAT) INSCON, ZEROP, ATMOS
            CALL FIO_SERR (LSTAT, STATUS)

*
*          Attempt to close the file.

            CLOSE(UNIT=FUNIT, IOSTAT=LSTAT)
            IF (STATUS .EQ. SAI__OK) THEN
               CALL FIO_SERR (LSTAT, STATUS)
            END IF

*
*          Report any error.

            IF (STATUS .NE. SAI__OK) THEN
               CALL MSG_SETC ('FILNME', FILNME)
               CALL ERR_REP ('CAP_CFLPM_WRT', 'Error writing '/
     :           /'transformation coefficients file ^FILNME.',
     :           STATUS)
            END IF
         ELSE

*
*          Report error opening the file.

            CALL MSG_SETC ('FILNME', FILNME)
            CALL ERR_REP ('CAP_CFLPM_OPN', 'Unable to open '/
     :        /'transformation coefficients file ^FILNME.',
     :        STATUS)

         END IF
      END IF

      END
