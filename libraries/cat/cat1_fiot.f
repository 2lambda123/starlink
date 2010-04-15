      SUBROUTINE CAT1_FIOB (IOFLG, FI, ELEM, ROWNO, VALUE, NULFLG,
     :  STATUS)
*+
*  Name:
*     CAT1_FIOB
*  Purpose:
*     Get or put a value for a single field.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT1_FIOB (IOFLG, FI, ELEM, ROWNO; VALUE, NULFLG; STATUS)
*  Description:
*     Get or put a value for a single field.
*  Arguments:
*     IOFLG  =  LOGICAL (Given)
*        Flag indicating whether the routine is to get or put a value,
*        coded as follows:
*        .TRUE.  - get a value,
*        .FALSE. - put a value.
*     FI  =  INTEGER (Given)
*        Identifier to the field to be put or got.
*     ELEM  =  INTEGER (Given)
*        Element of the array which is to be put or got.
*     ROWNO  =  INTEGER (Given)
*        Number of the row in which a field is to be accessed.
*     VALUE  =  BYTE (ENTRY or EXIT)
*        Value to be put or obtained.
*     NULFLG  =  LOGICAL (ENTRY or EXIT)
*        Flag indicating whether or not the value is null.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Check that the identifier belongs to a physical column.
*     If so then
*       Determine the back-end type for the catalogue being accessed.
*       Invoke the appropiate back-end to Attempt to get or put a field.
*     else
*       Report an error and set the status.
*     end if
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     6/7/93   (ACD): Original version.
*     11/10/93 (ACD): First stable version.
*     23/1/94  (ACD): Modified error reporting.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT1_PAR'          ! Internal CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      LOGICAL
     :  IOFLG
      INTEGER
     :  FI,
     :  ELEM,
     :  ROWNO
*  Arguments Given and Returned:
      BYTE
     :  VALUE
      LOGICAL
     :  NULFLG
*  Status:
      INTEGER STATUS             ! Global status
*  Local Variables:
      INTEGER
     :  GENUS,   ! Genus of the component.
     :  BCKTYP,  ! Back-end type for the catalogue being accessed.
     :  CI,      ! Identifier to the parent catalogue.
     :  CIELM    ! Element in catalogues arrays for the catalogue.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check that the identifier belongs to a physical column.

         CALL CAT_TIQAI (FI, 'GENUS', GENUS, STATUS)
         IF (STATUS .EQ. CAT__OK  .AND.  GENUS .EQ. CAT__GPHYS) THEN

*
*          Determine the catalogue being accessed and its back-end
*          type.

            CALL CAT_TIDPR (FI, CI, STATUS)
            CALL CAT1_CIELM (CI, CIELM, STATUS)
            BCKTYP = BKTYP__CAT1(CIELM)

*
*          Invoke the appropiate back-end to attempt to get or put a
*          field.

            CALL CAT0_FIOB (BCKTYP, IOFLG, CIELM, FI, ELEM, ROWNO,
     :        VALUE, NULFLG, STATUS)

         ELSE

*
*          The identifier given does not correspond to a physical
*          column; set the status and report an error.

            STATUS = CAT__ERROR

            CALL CAT1_ERREP ('CAT1_FIOTB_ERR', 'Error: get or put to'/
     :        /' a component which is not a physical column', STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT1_FIOC (IOFLG, FI, ELEM, ROWNO, VALUE, NULFLG,
     :  STATUS)
*+
*  Name:
*     CAT1_FIOC
*  Purpose:
*     Get or put a value for a single field.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT1_FIOC (IOFLG, FI, ELEM, ROWNO; VALUE, NULFLG; STATUS)
*  Description:
*     Get or put a value for a single field.
*  Arguments:
*     IOFLG  =  LOGICAL (Given)
*        Flag indicating whether the routine is to get or put a value,
*        coded as follows:
*        .TRUE.  - get a value,
*        .FALSE. - put a value.
*     FI  =  INTEGER (Given)
*        Identifier to the field to be put or got.
*     ELEM  =  INTEGER (Given)
*        Element of the array which is to be put or got.
*     ROWNO  =  INTEGER (Given)
*        Number of the row in which a field is to be accessed.
*     VALUE  =  CHARACTER*(*) (ENTRY or EXIT)
*        Value to be put or obtained.
*     NULFLG  =  LOGICAL (ENTRY or EXIT)
*        Flag indicating whether or not the value is null.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Check that the identifier belongs to a physical column.
*     If so then
*       Determine the back-end type for the catalogue being accessed.
*       Invoke the appropiate back-end to Attempt to get or put a field.
*     else
*       Report an error and set the status.
*     end if
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     6/7/93   (ACD): Original version.
*     11/10/93 (ACD): First stable version.
*     23/1/94  (ACD): Modified error reporting.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT1_PAR'          ! Internal CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      LOGICAL
     :  IOFLG
      INTEGER
     :  FI,
     :  ELEM,
     :  ROWNO
*  Arguments Given and Returned:
      CHARACTER*(*)
     :  VALUE
      LOGICAL
     :  NULFLG
*  Status:
      INTEGER STATUS             ! Global status
*  Local Variables:
      INTEGER
     :  GENUS,   ! Genus of the component.
     :  BCKTYP,  ! Back-end type for the catalogue being accessed.
     :  CI,      ! Identifier to the parent catalogue.
     :  CIELM    ! Element in catalogues arrays for the catalogue.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check that the identifier belongs to a physical column.

         CALL CAT_TIQAI (FI, 'GENUS', GENUS, STATUS)
         IF (STATUS .EQ. CAT__OK  .AND.  GENUS .EQ. CAT__GPHYS) THEN

*
*          Determine the catalogue being accessed and its back-end
*          type.

            CALL CAT_TIDPR (FI, CI, STATUS)
            CALL CAT1_CIELM (CI, CIELM, STATUS)
            BCKTYP = BKTYP__CAT1(CIELM)

*
*          Invoke the appropiate back-end to attempt to get or put a
*          field.

            CALL CAT0_FIOC (BCKTYP, IOFLG, CIELM, FI, ELEM, ROWNO,
     :        VALUE, NULFLG, STATUS)

         ELSE

*
*          The identifier given does not correspond to a physical
*          column; set the status and report an error.

            STATUS = CAT__ERROR

            CALL CAT1_ERREP ('CAT1_FIOTC_ERR', 'Error: get or put to'/
     :        /' a component which is not a physical column', STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT1_FIOD (IOFLG, FI, ELEM, ROWNO, VALUE, NULFLG,
     :  STATUS)
*+
*  Name:
*     CAT1_FIOD
*  Purpose:
*     Get or put a value for a single field.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT1_FIOD (IOFLG, FI, ELEM, ROWNO; VALUE, NULFLG; STATUS)
*  Description:
*     Get or put a value for a single field.
*  Arguments:
*     IOFLG  =  LOGICAL (Given)
*        Flag indicating whether the routine is to get or put a value,
*        coded as follows:
*        .TRUE.  - get a value,
*        .FALSE. - put a value.
*     FI  =  INTEGER (Given)
*        Identifier to the field to be put or got.
*     ELEM  =  INTEGER (Given)
*        Element of the array which is to be put or got.
*     ROWNO  =  INTEGER (Given)
*        Number of the row in which a field is to be accessed.
*     VALUE  =  DOUBLE PRECISION (ENTRY or EXIT)
*        Value to be put or obtained.
*     NULFLG  =  LOGICAL (ENTRY or EXIT)
*        Flag indicating whether or not the value is null.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Check that the identifier belongs to a physical column.
*     If so then
*       Determine the back-end type for the catalogue being accessed.
*       Invoke the appropiate back-end to Attempt to get or put a field.
*     else
*       Report an error and set the status.
*     end if
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     6/7/93   (ACD): Original version.
*     11/10/93 (ACD): First stable version.
*     23/1/94  (ACD): Modified error reporting.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT1_PAR'          ! Internal CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      LOGICAL
     :  IOFLG
      INTEGER
     :  FI,
     :  ELEM,
     :  ROWNO
*  Arguments Given and Returned:
      DOUBLE PRECISION
     :  VALUE
      LOGICAL
     :  NULFLG
*  Status:
      INTEGER STATUS             ! Global status
*  Local Variables:
      INTEGER
     :  GENUS,   ! Genus of the component.
     :  BCKTYP,  ! Back-end type for the catalogue being accessed.
     :  CI,      ! Identifier to the parent catalogue.
     :  CIELM    ! Element in catalogues arrays for the catalogue.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check that the identifier belongs to a physical column.

         CALL CAT_TIQAI (FI, 'GENUS', GENUS, STATUS)
         IF (STATUS .EQ. CAT__OK  .AND.  GENUS .EQ. CAT__GPHYS) THEN

*
*          Determine the catalogue being accessed and its back-end
*          type.

            CALL CAT_TIDPR (FI, CI, STATUS)
            CALL CAT1_CIELM (CI, CIELM, STATUS)
            BCKTYP = BKTYP__CAT1(CIELM)

*
*          Invoke the appropiate back-end to attempt to get or put a
*          field.

            CALL CAT0_FIOD (BCKTYP, IOFLG, CIELM, FI, ELEM, ROWNO,
     :        VALUE, NULFLG, STATUS)

         ELSE

*
*          The identifier given does not correspond to a physical
*          column; set the status and report an error.

            STATUS = CAT__ERROR

            CALL CAT1_ERREP ('CAT1_FIOTD_ERR', 'Error: get or put to'/
     :        /' a component which is not a physical column', STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT1_FIOI (IOFLG, FI, ELEM, ROWNO, VALUE, NULFLG,
     :  STATUS)
*+
*  Name:
*     CAT1_FIOI
*  Purpose:
*     Get or put a value for a single field.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT1_FIOI (IOFLG, FI, ELEM, ROWNO; VALUE, NULFLG; STATUS)
*  Description:
*     Get or put a value for a single field.
*  Arguments:
*     IOFLG  =  LOGICAL (Given)
*        Flag indicating whether the routine is to get or put a value,
*        coded as follows:
*        .TRUE.  - get a value,
*        .FALSE. - put a value.
*     FI  =  INTEGER (Given)
*        Identifier to the field to be put or got.
*     ELEM  =  INTEGER (Given)
*        Element of the array which is to be put or got.
*     ROWNO  =  INTEGER (Given)
*        Number of the row in which a field is to be accessed.
*     VALUE  =  INTEGER (ENTRY or EXIT)
*        Value to be put or obtained.
*     NULFLG  =  LOGICAL (ENTRY or EXIT)
*        Flag indicating whether or not the value is null.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Check that the identifier belongs to a physical column.
*     If so then
*       Determine the back-end type for the catalogue being accessed.
*       Invoke the appropiate back-end to Attempt to get or put a field.
*     else
*       Report an error and set the status.
*     end if
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     6/7/93   (ACD): Original version.
*     11/10/93 (ACD): First stable version.
*     23/1/94  (ACD): Modified error reporting.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT1_PAR'          ! Internal CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      LOGICAL
     :  IOFLG
      INTEGER
     :  FI,
     :  ELEM,
     :  ROWNO
*  Arguments Given and Returned:
      INTEGER
     :  VALUE
      LOGICAL
     :  NULFLG
*  Status:
      INTEGER STATUS             ! Global status
*  Local Variables:
      INTEGER
     :  GENUS,   ! Genus of the component.
     :  BCKTYP,  ! Back-end type for the catalogue being accessed.
     :  CI,      ! Identifier to the parent catalogue.
     :  CIELM    ! Element in catalogues arrays for the catalogue.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check that the identifier belongs to a physical column.

         CALL CAT_TIQAI (FI, 'GENUS', GENUS, STATUS)
         IF (STATUS .EQ. CAT__OK  .AND.  GENUS .EQ. CAT__GPHYS) THEN

*
*          Determine the catalogue being accessed and its back-end
*          type.

            CALL CAT_TIDPR (FI, CI, STATUS)
            CALL CAT1_CIELM (CI, CIELM, STATUS)
            BCKTYP = BKTYP__CAT1(CIELM)

*
*          Invoke the appropiate back-end to attempt to get or put a
*          field.

            CALL CAT0_FIOI (BCKTYP, IOFLG, CIELM, FI, ELEM, ROWNO,
     :        VALUE, NULFLG, STATUS)

         ELSE

*
*          The identifier given does not correspond to a physical
*          column; set the status and report an error.

            STATUS = CAT__ERROR

            CALL CAT1_ERREP ('CAT1_FIOTI_ERR', 'Error: get or put to'/
     :        /' a component which is not a physical column', STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT1_FIOL (IOFLG, FI, ELEM, ROWNO, VALUE, NULFLG,
     :  STATUS)
*+
*  Name:
*     CAT1_FIOL
*  Purpose:
*     Get or put a value for a single field.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT1_FIOL (IOFLG, FI, ELEM, ROWNO; VALUE, NULFLG; STATUS)
*  Description:
*     Get or put a value for a single field.
*  Arguments:
*     IOFLG  =  LOGICAL (Given)
*        Flag indicating whether the routine is to get or put a value,
*        coded as follows:
*        .TRUE.  - get a value,
*        .FALSE. - put a value.
*     FI  =  INTEGER (Given)
*        Identifier to the field to be put or got.
*     ELEM  =  INTEGER (Given)
*        Element of the array which is to be put or got.
*     ROWNO  =  INTEGER (Given)
*        Number of the row in which a field is to be accessed.
*     VALUE  =  LOGICAL (ENTRY or EXIT)
*        Value to be put or obtained.
*     NULFLG  =  LOGICAL (ENTRY or EXIT)
*        Flag indicating whether or not the value is null.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Check that the identifier belongs to a physical column.
*     If so then
*       Determine the back-end type for the catalogue being accessed.
*       Invoke the appropiate back-end to Attempt to get or put a field.
*     else
*       Report an error and set the status.
*     end if
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     6/7/93   (ACD): Original version.
*     11/10/93 (ACD): First stable version.
*     23/1/94  (ACD): Modified error reporting.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT1_PAR'          ! Internal CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      LOGICAL
     :  IOFLG
      INTEGER
     :  FI,
     :  ELEM,
     :  ROWNO
*  Arguments Given and Returned:
      LOGICAL
     :  VALUE
      LOGICAL
     :  NULFLG
*  Status:
      INTEGER STATUS             ! Global status
*  Local Variables:
      INTEGER
     :  GENUS,   ! Genus of the component.
     :  BCKTYP,  ! Back-end type for the catalogue being accessed.
     :  CI,      ! Identifier to the parent catalogue.
     :  CIELM    ! Element in catalogues arrays for the catalogue.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check that the identifier belongs to a physical column.

         CALL CAT_TIQAI (FI, 'GENUS', GENUS, STATUS)
         IF (STATUS .EQ. CAT__OK  .AND.  GENUS .EQ. CAT__GPHYS) THEN

*
*          Determine the catalogue being accessed and its back-end
*          type.

            CALL CAT_TIDPR (FI, CI, STATUS)
            CALL CAT1_CIELM (CI, CIELM, STATUS)
            BCKTYP = BKTYP__CAT1(CIELM)

*
*          Invoke the appropiate back-end to attempt to get or put a
*          field.

            CALL CAT0_FIOL (BCKTYP, IOFLG, CIELM, FI, ELEM, ROWNO,
     :        VALUE, NULFLG, STATUS)

         ELSE

*
*          The identifier given does not correspond to a physical
*          column; set the status and report an error.

            STATUS = CAT__ERROR

            CALL CAT1_ERREP ('CAT1_FIOTL_ERR', 'Error: get or put to'/
     :        /' a component which is not a physical column', STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT1_FIOR (IOFLG, FI, ELEM, ROWNO, VALUE, NULFLG,
     :  STATUS)
*+
*  Name:
*     CAT1_FIOR
*  Purpose:
*     Get or put a value for a single field.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT1_FIOR (IOFLG, FI, ELEM, ROWNO; VALUE, NULFLG; STATUS)
*  Description:
*     Get or put a value for a single field.
*  Arguments:
*     IOFLG  =  LOGICAL (Given)
*        Flag indicating whether the routine is to get or put a value,
*        coded as follows:
*        .TRUE.  - get a value,
*        .FALSE. - put a value.
*     FI  =  INTEGER (Given)
*        Identifier to the field to be put or got.
*     ELEM  =  INTEGER (Given)
*        Element of the array which is to be put or got.
*     ROWNO  =  INTEGER (Given)
*        Number of the row in which a field is to be accessed.
*     VALUE  =  REAL (ENTRY or EXIT)
*        Value to be put or obtained.
*     NULFLG  =  LOGICAL (ENTRY or EXIT)
*        Flag indicating whether or not the value is null.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Check that the identifier belongs to a physical column.
*     If so then
*       Determine the back-end type for the catalogue being accessed.
*       Invoke the appropiate back-end to Attempt to get or put a field.
*     else
*       Report an error and set the status.
*     end if
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     6/7/93   (ACD): Original version.
*     11/10/93 (ACD): First stable version.
*     23/1/94  (ACD): Modified error reporting.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT1_PAR'          ! Internal CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      LOGICAL
     :  IOFLG
      INTEGER
     :  FI,
     :  ELEM,
     :  ROWNO
*  Arguments Given and Returned:
      REAL
     :  VALUE
      LOGICAL
     :  NULFLG
*  Status:
      INTEGER STATUS             ! Global status
*  Local Variables:
      INTEGER
     :  GENUS,   ! Genus of the component.
     :  BCKTYP,  ! Back-end type for the catalogue being accessed.
     :  CI,      ! Identifier to the parent catalogue.
     :  CIELM    ! Element in catalogues arrays for the catalogue.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check that the identifier belongs to a physical column.

         CALL CAT_TIQAI (FI, 'GENUS', GENUS, STATUS)
         IF (STATUS .EQ. CAT__OK  .AND.  GENUS .EQ. CAT__GPHYS) THEN

*
*          Determine the catalogue being accessed and its back-end
*          type.

            CALL CAT_TIDPR (FI, CI, STATUS)
            CALL CAT1_CIELM (CI, CIELM, STATUS)
            BCKTYP = BKTYP__CAT1(CIELM)

*
*          Invoke the appropiate back-end to attempt to get or put a
*          field.

            CALL CAT0_FIOR (BCKTYP, IOFLG, CIELM, FI, ELEM, ROWNO,
     :        VALUE, NULFLG, STATUS)

         ELSE

*
*          The identifier given does not correspond to a physical
*          column; set the status and report an error.

            STATUS = CAT__ERROR

            CALL CAT1_ERREP ('CAT1_FIOTR_ERR', 'Error: get or put to'/
     :        /' a component which is not a physical column', STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT1_FIOW (IOFLG, FI, ELEM, ROWNO, VALUE, NULFLG,
     :  STATUS)
*+
*  Name:
*     CAT1_FIOW
*  Purpose:
*     Get or put a value for a single field.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT1_FIOW (IOFLG, FI, ELEM, ROWNO; VALUE, NULFLG; STATUS)
*  Description:
*     Get or put a value for a single field.
*  Arguments:
*     IOFLG  =  LOGICAL (Given)
*        Flag indicating whether the routine is to get or put a value,
*        coded as follows:
*        .TRUE.  - get a value,
*        .FALSE. - put a value.
*     FI  =  INTEGER (Given)
*        Identifier to the field to be put or got.
*     ELEM  =  INTEGER (Given)
*        Element of the array which is to be put or got.
*     ROWNO  =  INTEGER (Given)
*        Number of the row in which a field is to be accessed.
*     VALUE  =  INTEGER*2 (ENTRY or EXIT)
*        Value to be put or obtained.
*     NULFLG  =  LOGICAL (ENTRY or EXIT)
*        Flag indicating whether or not the value is null.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Check that the identifier belongs to a physical column.
*     If so then
*       Determine the back-end type for the catalogue being accessed.
*       Invoke the appropiate back-end to Attempt to get or put a field.
*     else
*       Report an error and set the status.
*     end if
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     6/7/93   (ACD): Original version.
*     11/10/93 (ACD): First stable version.
*     23/1/94  (ACD): Modified error reporting.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT1_PAR'          ! Internal CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      LOGICAL
     :  IOFLG
      INTEGER
     :  FI,
     :  ELEM,
     :  ROWNO
*  Arguments Given and Returned:
      INTEGER*2
     :  VALUE
      LOGICAL
     :  NULFLG
*  Status:
      INTEGER STATUS             ! Global status
*  Local Variables:
      INTEGER
     :  GENUS,   ! Genus of the component.
     :  BCKTYP,  ! Back-end type for the catalogue being accessed.
     :  CI,      ! Identifier to the parent catalogue.
     :  CIELM    ! Element in catalogues arrays for the catalogue.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check that the identifier belongs to a physical column.

         CALL CAT_TIQAI (FI, 'GENUS', GENUS, STATUS)
         IF (STATUS .EQ. CAT__OK  .AND.  GENUS .EQ. CAT__GPHYS) THEN

*
*          Determine the catalogue being accessed and its back-end
*          type.

            CALL CAT_TIDPR (FI, CI, STATUS)
            CALL CAT1_CIELM (CI, CIELM, STATUS)
            BCKTYP = BKTYP__CAT1(CIELM)

*
*          Invoke the appropiate back-end to attempt to get or put a
*          field.

            CALL CAT0_FIOW (BCKTYP, IOFLG, CIELM, FI, ELEM, ROWNO,
     :        VALUE, NULFLG, STATUS)

         ELSE

*
*          The identifier given does not correspond to a physical
*          column; set the status and report an error.

            STATUS = CAT__ERROR

            CALL CAT1_ERREP ('CAT1_FIOTW_ERR', 'Error: get or put to'/
     :        /' a component which is not a physical column', STATUS)
         END IF

      END IF

      END
