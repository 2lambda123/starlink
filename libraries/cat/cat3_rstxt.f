      SUBROUTINE CAT3_RSTXT (CI, STATUS)
*+
*  Name:
*     CAT3_RSTXT
*  Purpose:
*     Reset the access to the textual information in a FITS table.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT3_RSTXT (CI; STATUS)
*  Description:
*     Reset the access to the textual information in a FITS table.
*     A subsequent attempt access a line of textual information will
*     return the first line of textual information.
*
*     Note that all that is required for the FITS back-end is to set
*     the state for access to the textual information to 'before the
*     primary header'.  All other manipulations are carried out in 
*     routine CAT3_GETXT.
*  Arguments:
*     CI  =  INTEGER (Given)
*         Catalogue identifier.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Determine the common block array element for the catalogue.
*     Set the text access state to 'before the primary header'.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     22/9/94 (ACD): Original version.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT1_PAR'          ! Internal CAT constants.
      INCLUDE 'CAT3_FIT_PAR'      ! FITS tables back-end constants.
*  Global Variables:
      INCLUDE 'CAT3_FIT_CMN'      ! FITS tables back-end common block.
*  Arguments Given:
      INTEGER
     :  CI
*  Status:
      INTEGER STATUS              ! Global status.
*  Local Variables:
      INTEGER
     :  CIELM   ! Element for the catalogue in the common block arrays.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Determine the common block array element for the catalogue.

         CALL CAT1_CIELM (CI, CIELM, STATUS)

*
*       Set the text access state to 'before the primary header'.

         HSTAT__CAT3(CIELM) = CAT3__HSTTB

      END IF

      END
