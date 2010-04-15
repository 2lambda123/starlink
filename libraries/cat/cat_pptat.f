      SUBROUTINE CAT_PPTAB (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS,
     :  EXTFMT, PRFDSP, COMM, VALUE, QI, STATUS)
*+
*  Name:
*     CAT_PPTAB
*  Purpose:
*     Create a parameter, simultaneously setting all its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTAB (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS, EXTFMT,
*       PRFDSP, COMM, VALUE; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting all its attributes.
*
*     Note that the data type attribute can be deduced from the type
*     of the routine.  However the CHARACTER size attribute must still
*     be passed.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     CSIZE  =  INTEGER (Given)
*        Size of a CHARACTER parameter.  If the parameter is not of type
*        CHARACTER CSIZE is irrelevant; it is conventional to set it
*        to zero.
*     DIMS  =  INTEGER (Given)
*        Dimensionality of the parameter.  Currently the only permitted
*        value is CAT__SCALR, corresponding to a scalar.
*     SIZEA(1)  =  INTEGER (Given)
*        For vector parameters this attribute would be set to the
*        number of elements in the vector.  However, currently only
*        scalar parameters are supported and it should be set to one.
*     UNITS  =  CHARACTER*(*) (Given)
*        The units of the parameter.
*     EXTFMT  =  CHARACTER*(*) (Given)
*        The external format for the parameter.
*     PRFDSP  =  LOGICAL (Given)
*        The preferential display flag for the parameter:
*        .TRUE.  - display the parameter by default,
*        .FALSE. - do not display the parameter by default.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     VALUE  =  BYTE (Given)
*        Value for the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the attributes (they are all mutable at this stage
*         except those for the name and the data type).
*         If (all is ok) then
*           Increment the number of physical parameters.
*         end if
*       end if
*     else
*       Set the status.
*     end if
*     Report any error.
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
*     23/11/94 (ACD): Original version.
*     21/12/99 (ACD): Added check that the given parameter or name is unique,
*        ie. does not alreay exist in the catalogue.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      INTEGER
     :  CI,
     :  CSIZE,
     :  DIMS,
     :  SIZEA(1)
      CHARACTER
     :  QNAME*(*),
     :  UNITS*(*),
     :  EXTFMT*(*),
     :  COMM*(*)
      LOGICAL
     :  PRFDSP
      BYTE
     :  VALUE
*  Arguments Returned:
      INTEGER
     :  QI
*  Status:
      INTEGER STATUS             ! Global status.
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      LOGICAL
     :  EXIST  ! Flag; does the given name already exist in the catalogue?
      INTEGER
     :  CIELM,     ! Common block array element for the catalogue.
     :  LQNAME,    ! Length of QNAME  (excl. trail. blanks).
     :  ERRLEN     !   "    "  ERRTXT ( "  .   "  .   "   ).
      DOUBLE PRECISION
     :  DATE       ! Modification date attribute.
      CHARACTER
     :  ERRTXT*75  ! Text of error message.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check whether the given parameter name is unique, ie. whether a
*       column or parameter of this name already exists in the catalogue,
*       and proceed if the name is unique.

         CALL CAT1_NMCHK (CI, QNAME, EXIST, STATUS)
         IF (.NOT. EXIST) THEN

*
*          Attempt to create an identifier for the parameter.

            CALL CAT1_CRTID (CAT__QITYP, CI, QI, STATUS)
            IF (STATUS .EQ. CAT__OK) THEN

*
*             Get the common block array element for the catalogue.

               CALL CAT1_CIELM (CI, CIELM, STATUS)

*
*             Get the creation date.

               CALL CAT1_GTDAT (DATE, STATUS)

*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., CAT__TYPEB,
     :           STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., CSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., DIMS, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., SIZEA, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., DATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., UNITS, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., EXTFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., PRFDSP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., COMM, STATUS)
               CALL CAT1_ADDAB (QI, 'VALUE', .TRUE., VALUE, STATUS)


*
*             If all is ok then increment the number of parameters.

               IF (STATUS .EQ. CAT__OK) THEN
                  NPAR__CAT1(CIELM) = NPAR__CAT1(CIELM) + 1
               END IF

            END IF
         ELSE

*
*          A parameter of the given name already exists; set the status.

            STATUS = CAT__DUPNM

         END IF

*
*       Report any error.

         IF (STATUS .NE. CAT__OK) THEN
            ERRTXT = ' '
            ERRLEN = 0

            CALL CHR_PUTC ('CAT_PPTAB: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTAB_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTAC (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS,
     :  EXTFMT, PRFDSP, COMM, VALUE, QI, STATUS)
*+
*  Name:
*     CAT_PPTAC
*  Purpose:
*     Create a parameter, simultaneously setting all its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTAC (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS, EXTFMT,
*       PRFDSP, COMM, VALUE; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting all its attributes.
*
*     Note that the data type attribute can be deduced from the type
*     of the routine.  However the CHARACTER size attribute must still
*     be passed.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     CSIZE  =  INTEGER (Given)
*        Size of a CHARACTER parameter.  If the parameter is not of type
*        CHARACTER CSIZE is irrelevant; it is conventional to set it
*        to zero.
*     DIMS  =  INTEGER (Given)
*        Dimensionality of the parameter.  Currently the only permitted
*        value is CAT__SCALR, corresponding to a scalar.
*     SIZEA(1)  =  INTEGER (Given)
*        For vector parameters this attribute would be set to the
*        number of elements in the vector.  However, currently only
*        scalar parameters are supported and it should be set to one.
*     UNITS  =  CHARACTER*(*) (Given)
*        The units of the parameter.
*     EXTFMT  =  CHARACTER*(*) (Given)
*        The external format for the parameter.
*     PRFDSP  =  LOGICAL (Given)
*        The preferential display flag for the parameter:
*        .TRUE.  - display the parameter by default,
*        .FALSE. - do not display the parameter by default.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     VALUE  =  CHARACTER*(*) (Given)
*        Value for the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the attributes (they are all mutable at this stage
*         except those for the name and the data type).
*         If (all is ok) then
*           Increment the number of physical parameters.
*         end if
*       end if
*     else
*       Set the status.
*     end if
*     Report any error.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     23/11/94 (ACD): Original version.
*     21/12/99 (ACD): Added check that the given parameter or name is unique,
*        ie. does not alreay exist in the catalogue.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      INTEGER
     :  CI,
     :  CSIZE,
     :  DIMS,
     :  SIZEA(1)
      CHARACTER
     :  QNAME*(*),
     :  UNITS*(*),
     :  EXTFMT*(*),
     :  COMM*(*)
      LOGICAL
     :  PRFDSP
      CHARACTER*(*)
     :  VALUE
*  Arguments Returned:
      INTEGER
     :  QI
*  Status:
      INTEGER STATUS             ! Global status.
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      LOGICAL
     :  EXIST  ! Flag; does the given name already exist in the catalogue?
      INTEGER
     :  CIELM,     ! Common block array element for the catalogue.
     :  LQNAME,    ! Length of QNAME  (excl. trail. blanks).
     :  ERRLEN     !   "    "  ERRTXT ( "  .   "  .   "   ).
      DOUBLE PRECISION
     :  DATE       ! Modification date attribute.
      CHARACTER
     :  ERRTXT*75  ! Text of error message.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check whether the given parameter name is unique, ie. whether a
*       column or parameter of this name already exists in the catalogue,
*       and proceed if the name is unique.

         CALL CAT1_NMCHK (CI, QNAME, EXIST, STATUS)
         IF (.NOT. EXIST) THEN

*
*          Attempt to create an identifier for the parameter.

            CALL CAT1_CRTID (CAT__QITYP, CI, QI, STATUS)
            IF (STATUS .EQ. CAT__OK) THEN

*
*             Get the common block array element for the catalogue.

               CALL CAT1_CIELM (CI, CIELM, STATUS)

*
*             Get the creation date.

               CALL CAT1_GTDAT (DATE, STATUS)

*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., CAT__TYPEC,
     :           STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., CSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., DIMS, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., SIZEA, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., DATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., UNITS, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., EXTFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., PRFDSP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., COMM, STATUS)
               CALL CAT1_ADDAC (QI, 'VALUE', .TRUE., VALUE, STATUS)


*
*             If all is ok then increment the number of parameters.

               IF (STATUS .EQ. CAT__OK) THEN
                  NPAR__CAT1(CIELM) = NPAR__CAT1(CIELM) + 1
               END IF

            END IF
         ELSE

*
*          A parameter of the given name already exists; set the status.

            STATUS = CAT__DUPNM

         END IF

*
*       Report any error.

         IF (STATUS .NE. CAT__OK) THEN
            ERRTXT = ' '
            ERRLEN = 0

            CALL CHR_PUTC ('CAT_PPTAC: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTAC_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTAD (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS,
     :  EXTFMT, PRFDSP, COMM, VALUE, QI, STATUS)
*+
*  Name:
*     CAT_PPTAD
*  Purpose:
*     Create a parameter, simultaneously setting all its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTAD (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS, EXTFMT,
*       PRFDSP, COMM, VALUE; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting all its attributes.
*
*     Note that the data type attribute can be deduced from the type
*     of the routine.  However the CHARACTER size attribute must still
*     be passed.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     CSIZE  =  INTEGER (Given)
*        Size of a CHARACTER parameter.  If the parameter is not of type
*        CHARACTER CSIZE is irrelevant; it is conventional to set it
*        to zero.
*     DIMS  =  INTEGER (Given)
*        Dimensionality of the parameter.  Currently the only permitted
*        value is CAT__SCALR, corresponding to a scalar.
*     SIZEA(1)  =  INTEGER (Given)
*        For vector parameters this attribute would be set to the
*        number of elements in the vector.  However, currently only
*        scalar parameters are supported and it should be set to one.
*     UNITS  =  CHARACTER*(*) (Given)
*        The units of the parameter.
*     EXTFMT  =  CHARACTER*(*) (Given)
*        The external format for the parameter.
*     PRFDSP  =  LOGICAL (Given)
*        The preferential display flag for the parameter:
*        .TRUE.  - display the parameter by default,
*        .FALSE. - do not display the parameter by default.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     VALUE  =  DOUBLE PRECISION (Given)
*        Value for the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the attributes (they are all mutable at this stage
*         except those for the name and the data type).
*         If (all is ok) then
*           Increment the number of physical parameters.
*         end if
*       end if
*     else
*       Set the status.
*     end if
*     Report any error.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     23/11/94 (ACD): Original version.
*     21/12/99 (ACD): Added check that the given parameter or name is unique,
*        ie. does not alreay exist in the catalogue.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      INTEGER
     :  CI,
     :  CSIZE,
     :  DIMS,
     :  SIZEA(1)
      CHARACTER
     :  QNAME*(*),
     :  UNITS*(*),
     :  EXTFMT*(*),
     :  COMM*(*)
      LOGICAL
     :  PRFDSP
      DOUBLE PRECISION
     :  VALUE
*  Arguments Returned:
      INTEGER
     :  QI
*  Status:
      INTEGER STATUS             ! Global status.
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      LOGICAL
     :  EXIST  ! Flag; does the given name already exist in the catalogue?
      INTEGER
     :  CIELM,     ! Common block array element for the catalogue.
     :  LQNAME,    ! Length of QNAME  (excl. trail. blanks).
     :  ERRLEN     !   "    "  ERRTXT ( "  .   "  .   "   ).
      DOUBLE PRECISION
     :  DATE       ! Modification date attribute.
      CHARACTER
     :  ERRTXT*75  ! Text of error message.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check whether the given parameter name is unique, ie. whether a
*       column or parameter of this name already exists in the catalogue,
*       and proceed if the name is unique.

         CALL CAT1_NMCHK (CI, QNAME, EXIST, STATUS)
         IF (.NOT. EXIST) THEN

*
*          Attempt to create an identifier for the parameter.

            CALL CAT1_CRTID (CAT__QITYP, CI, QI, STATUS)
            IF (STATUS .EQ. CAT__OK) THEN

*
*             Get the common block array element for the catalogue.

               CALL CAT1_CIELM (CI, CIELM, STATUS)

*
*             Get the creation date.

               CALL CAT1_GTDAT (DATE, STATUS)

*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., CAT__TYPED,
     :           STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., CSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., DIMS, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., SIZEA, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., DATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., UNITS, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., EXTFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., PRFDSP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., COMM, STATUS)
               CALL CAT1_ADDAD (QI, 'VALUE', .TRUE., VALUE, STATUS)


*
*             If all is ok then increment the number of parameters.

               IF (STATUS .EQ. CAT__OK) THEN
                  NPAR__CAT1(CIELM) = NPAR__CAT1(CIELM) + 1
               END IF

            END IF
         ELSE

*
*          A parameter of the given name already exists; set the status.

            STATUS = CAT__DUPNM

         END IF

*
*       Report any error.

         IF (STATUS .NE. CAT__OK) THEN
            ERRTXT = ' '
            ERRLEN = 0

            CALL CHR_PUTC ('CAT_PPTAD: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTAD_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTAI (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS,
     :  EXTFMT, PRFDSP, COMM, VALUE, QI, STATUS)
*+
*  Name:
*     CAT_PPTAI
*  Purpose:
*     Create a parameter, simultaneously setting all its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTAI (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS, EXTFMT,
*       PRFDSP, COMM, VALUE; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting all its attributes.
*
*     Note that the data type attribute can be deduced from the type
*     of the routine.  However the CHARACTER size attribute must still
*     be passed.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     CSIZE  =  INTEGER (Given)
*        Size of a CHARACTER parameter.  If the parameter is not of type
*        CHARACTER CSIZE is irrelevant; it is conventional to set it
*        to zero.
*     DIMS  =  INTEGER (Given)
*        Dimensionality of the parameter.  Currently the only permitted
*        value is CAT__SCALR, corresponding to a scalar.
*     SIZEA(1)  =  INTEGER (Given)
*        For vector parameters this attribute would be set to the
*        number of elements in the vector.  However, currently only
*        scalar parameters are supported and it should be set to one.
*     UNITS  =  CHARACTER*(*) (Given)
*        The units of the parameter.
*     EXTFMT  =  CHARACTER*(*) (Given)
*        The external format for the parameter.
*     PRFDSP  =  LOGICAL (Given)
*        The preferential display flag for the parameter:
*        .TRUE.  - display the parameter by default,
*        .FALSE. - do not display the parameter by default.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     VALUE  =  INTEGER (Given)
*        Value for the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the attributes (they are all mutable at this stage
*         except those for the name and the data type).
*         If (all is ok) then
*           Increment the number of physical parameters.
*         end if
*       end if
*     else
*       Set the status.
*     end if
*     Report any error.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     23/11/94 (ACD): Original version.
*     21/12/99 (ACD): Added check that the given parameter or name is unique,
*        ie. does not alreay exist in the catalogue.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      INTEGER
     :  CI,
     :  CSIZE,
     :  DIMS,
     :  SIZEA(1)
      CHARACTER
     :  QNAME*(*),
     :  UNITS*(*),
     :  EXTFMT*(*),
     :  COMM*(*)
      LOGICAL
     :  PRFDSP
      INTEGER
     :  VALUE
*  Arguments Returned:
      INTEGER
     :  QI
*  Status:
      INTEGER STATUS             ! Global status.
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      LOGICAL
     :  EXIST  ! Flag; does the given name already exist in the catalogue?
      INTEGER
     :  CIELM,     ! Common block array element for the catalogue.
     :  LQNAME,    ! Length of QNAME  (excl. trail. blanks).
     :  ERRLEN     !   "    "  ERRTXT ( "  .   "  .   "   ).
      DOUBLE PRECISION
     :  DATE       ! Modification date attribute.
      CHARACTER
     :  ERRTXT*75  ! Text of error message.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check whether the given parameter name is unique, ie. whether a
*       column or parameter of this name already exists in the catalogue,
*       and proceed if the name is unique.

         CALL CAT1_NMCHK (CI, QNAME, EXIST, STATUS)
         IF (.NOT. EXIST) THEN

*
*          Attempt to create an identifier for the parameter.

            CALL CAT1_CRTID (CAT__QITYP, CI, QI, STATUS)
            IF (STATUS .EQ. CAT__OK) THEN

*
*             Get the common block array element for the catalogue.

               CALL CAT1_CIELM (CI, CIELM, STATUS)

*
*             Get the creation date.

               CALL CAT1_GTDAT (DATE, STATUS)

*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., CAT__TYPEI,
     :           STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., CSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., DIMS, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., SIZEA, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., DATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., UNITS, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., EXTFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., PRFDSP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., COMM, STATUS)
               CALL CAT1_ADDAI (QI, 'VALUE', .TRUE., VALUE, STATUS)


*
*             If all is ok then increment the number of parameters.

               IF (STATUS .EQ. CAT__OK) THEN
                  NPAR__CAT1(CIELM) = NPAR__CAT1(CIELM) + 1
               END IF

            END IF
         ELSE

*
*          A parameter of the given name already exists; set the status.

            STATUS = CAT__DUPNM

         END IF

*
*       Report any error.

         IF (STATUS .NE. CAT__OK) THEN
            ERRTXT = ' '
            ERRLEN = 0

            CALL CHR_PUTC ('CAT_PPTAI: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTAI_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTAL (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS,
     :  EXTFMT, PRFDSP, COMM, VALUE, QI, STATUS)
*+
*  Name:
*     CAT_PPTAL
*  Purpose:
*     Create a parameter, simultaneously setting all its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTAL (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS, EXTFMT,
*       PRFDSP, COMM, VALUE; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting all its attributes.
*
*     Note that the data type attribute can be deduced from the type
*     of the routine.  However the CHARACTER size attribute must still
*     be passed.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     CSIZE  =  INTEGER (Given)
*        Size of a CHARACTER parameter.  If the parameter is not of type
*        CHARACTER CSIZE is irrelevant; it is conventional to set it
*        to zero.
*     DIMS  =  INTEGER (Given)
*        Dimensionality of the parameter.  Currently the only permitted
*        value is CAT__SCALR, corresponding to a scalar.
*     SIZEA(1)  =  INTEGER (Given)
*        For vector parameters this attribute would be set to the
*        number of elements in the vector.  However, currently only
*        scalar parameters are supported and it should be set to one.
*     UNITS  =  CHARACTER*(*) (Given)
*        The units of the parameter.
*     EXTFMT  =  CHARACTER*(*) (Given)
*        The external format for the parameter.
*     PRFDSP  =  LOGICAL (Given)
*        The preferential display flag for the parameter:
*        .TRUE.  - display the parameter by default,
*        .FALSE. - do not display the parameter by default.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     VALUE  =  LOGICAL (Given)
*        Value for the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the attributes (they are all mutable at this stage
*         except those for the name and the data type).
*         If (all is ok) then
*           Increment the number of physical parameters.
*         end if
*       end if
*     else
*       Set the status.
*     end if
*     Report any error.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     23/11/94 (ACD): Original version.
*     21/12/99 (ACD): Added check that the given parameter or name is unique,
*        ie. does not alreay exist in the catalogue.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      INTEGER
     :  CI,
     :  CSIZE,
     :  DIMS,
     :  SIZEA(1)
      CHARACTER
     :  QNAME*(*),
     :  UNITS*(*),
     :  EXTFMT*(*),
     :  COMM*(*)
      LOGICAL
     :  PRFDSP
      LOGICAL
     :  VALUE
*  Arguments Returned:
      INTEGER
     :  QI
*  Status:
      INTEGER STATUS             ! Global status.
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      LOGICAL
     :  EXIST  ! Flag; does the given name already exist in the catalogue?
      INTEGER
     :  CIELM,     ! Common block array element for the catalogue.
     :  LQNAME,    ! Length of QNAME  (excl. trail. blanks).
     :  ERRLEN     !   "    "  ERRTXT ( "  .   "  .   "   ).
      DOUBLE PRECISION
     :  DATE       ! Modification date attribute.
      CHARACTER
     :  ERRTXT*75  ! Text of error message.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check whether the given parameter name is unique, ie. whether a
*       column or parameter of this name already exists in the catalogue,
*       and proceed if the name is unique.

         CALL CAT1_NMCHK (CI, QNAME, EXIST, STATUS)
         IF (.NOT. EXIST) THEN

*
*          Attempt to create an identifier for the parameter.

            CALL CAT1_CRTID (CAT__QITYP, CI, QI, STATUS)
            IF (STATUS .EQ. CAT__OK) THEN

*
*             Get the common block array element for the catalogue.

               CALL CAT1_CIELM (CI, CIELM, STATUS)

*
*             Get the creation date.

               CALL CAT1_GTDAT (DATE, STATUS)

*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., CAT__TYPEL,
     :           STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., CSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., DIMS, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., SIZEA, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., DATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., UNITS, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., EXTFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., PRFDSP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., COMM, STATUS)
               CALL CAT1_ADDAL (QI, 'VALUE', .TRUE., VALUE, STATUS)


*
*             If all is ok then increment the number of parameters.

               IF (STATUS .EQ. CAT__OK) THEN
                  NPAR__CAT1(CIELM) = NPAR__CAT1(CIELM) + 1
               END IF

            END IF
         ELSE

*
*          A parameter of the given name already exists; set the status.

            STATUS = CAT__DUPNM

         END IF

*
*       Report any error.

         IF (STATUS .NE. CAT__OK) THEN
            ERRTXT = ' '
            ERRLEN = 0

            CALL CHR_PUTC ('CAT_PPTAL: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTAL_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTAR (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS,
     :  EXTFMT, PRFDSP, COMM, VALUE, QI, STATUS)
*+
*  Name:
*     CAT_PPTAR
*  Purpose:
*     Create a parameter, simultaneously setting all its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTAR (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS, EXTFMT,
*       PRFDSP, COMM, VALUE; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting all its attributes.
*
*     Note that the data type attribute can be deduced from the type
*     of the routine.  However the CHARACTER size attribute must still
*     be passed.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     CSIZE  =  INTEGER (Given)
*        Size of a CHARACTER parameter.  If the parameter is not of type
*        CHARACTER CSIZE is irrelevant; it is conventional to set it
*        to zero.
*     DIMS  =  INTEGER (Given)
*        Dimensionality of the parameter.  Currently the only permitted
*        value is CAT__SCALR, corresponding to a scalar.
*     SIZEA(1)  =  INTEGER (Given)
*        For vector parameters this attribute would be set to the
*        number of elements in the vector.  However, currently only
*        scalar parameters are supported and it should be set to one.
*     UNITS  =  CHARACTER*(*) (Given)
*        The units of the parameter.
*     EXTFMT  =  CHARACTER*(*) (Given)
*        The external format for the parameter.
*     PRFDSP  =  LOGICAL (Given)
*        The preferential display flag for the parameter:
*        .TRUE.  - display the parameter by default,
*        .FALSE. - do not display the parameter by default.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     VALUE  =  REAL (Given)
*        Value for the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the attributes (they are all mutable at this stage
*         except those for the name and the data type).
*         If (all is ok) then
*           Increment the number of physical parameters.
*         end if
*       end if
*     else
*       Set the status.
*     end if
*     Report any error.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     23/11/94 (ACD): Original version.
*     21/12/99 (ACD): Added check that the given parameter or name is unique,
*        ie. does not alreay exist in the catalogue.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      INTEGER
     :  CI,
     :  CSIZE,
     :  DIMS,
     :  SIZEA(1)
      CHARACTER
     :  QNAME*(*),
     :  UNITS*(*),
     :  EXTFMT*(*),
     :  COMM*(*)
      LOGICAL
     :  PRFDSP
      REAL
     :  VALUE
*  Arguments Returned:
      INTEGER
     :  QI
*  Status:
      INTEGER STATUS             ! Global status.
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      LOGICAL
     :  EXIST  ! Flag; does the given name already exist in the catalogue?
      INTEGER
     :  CIELM,     ! Common block array element for the catalogue.
     :  LQNAME,    ! Length of QNAME  (excl. trail. blanks).
     :  ERRLEN     !   "    "  ERRTXT ( "  .   "  .   "   ).
      DOUBLE PRECISION
     :  DATE       ! Modification date attribute.
      CHARACTER
     :  ERRTXT*75  ! Text of error message.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check whether the given parameter name is unique, ie. whether a
*       column or parameter of this name already exists in the catalogue,
*       and proceed if the name is unique.

         CALL CAT1_NMCHK (CI, QNAME, EXIST, STATUS)
         IF (.NOT. EXIST) THEN

*
*          Attempt to create an identifier for the parameter.

            CALL CAT1_CRTID (CAT__QITYP, CI, QI, STATUS)
            IF (STATUS .EQ. CAT__OK) THEN

*
*             Get the common block array element for the catalogue.

               CALL CAT1_CIELM (CI, CIELM, STATUS)

*
*             Get the creation date.

               CALL CAT1_GTDAT (DATE, STATUS)

*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., CAT__TYPER,
     :           STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., CSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., DIMS, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., SIZEA, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., DATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., UNITS, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., EXTFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., PRFDSP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., COMM, STATUS)
               CALL CAT1_ADDAR (QI, 'VALUE', .TRUE., VALUE, STATUS)


*
*             If all is ok then increment the number of parameters.

               IF (STATUS .EQ. CAT__OK) THEN
                  NPAR__CAT1(CIELM) = NPAR__CAT1(CIELM) + 1
               END IF

            END IF
         ELSE

*
*          A parameter of the given name already exists; set the status.

            STATUS = CAT__DUPNM

         END IF

*
*       Report any error.

         IF (STATUS .NE. CAT__OK) THEN
            ERRTXT = ' '
            ERRLEN = 0

            CALL CHR_PUTC ('CAT_PPTAR: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTAR_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTAW (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS,
     :  EXTFMT, PRFDSP, COMM, VALUE, QI, STATUS)
*+
*  Name:
*     CAT_PPTAW
*  Purpose:
*     Create a parameter, simultaneously setting all its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTAW (CI, QNAME, CSIZE, DIMS, SIZEA, UNITS, EXTFMT,
*       PRFDSP, COMM, VALUE; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting all its attributes.
*
*     Note that the data type attribute can be deduced from the type
*     of the routine.  However the CHARACTER size attribute must still
*     be passed.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     CSIZE  =  INTEGER (Given)
*        Size of a CHARACTER parameter.  If the parameter is not of type
*        CHARACTER CSIZE is irrelevant; it is conventional to set it
*        to zero.
*     DIMS  =  INTEGER (Given)
*        Dimensionality of the parameter.  Currently the only permitted
*        value is CAT__SCALR, corresponding to a scalar.
*     SIZEA(1)  =  INTEGER (Given)
*        For vector parameters this attribute would be set to the
*        number of elements in the vector.  However, currently only
*        scalar parameters are supported and it should be set to one.
*     UNITS  =  CHARACTER*(*) (Given)
*        The units of the parameter.
*     EXTFMT  =  CHARACTER*(*) (Given)
*        The external format for the parameter.
*     PRFDSP  =  LOGICAL (Given)
*        The preferential display flag for the parameter:
*        .TRUE.  - display the parameter by default,
*        .FALSE. - do not display the parameter by default.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     VALUE  =  INTEGER*2 (Given)
*        Value for the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the attributes (they are all mutable at this stage
*         except those for the name and the data type).
*         If (all is ok) then
*           Increment the number of physical parameters.
*         end if
*       end if
*     else
*       Set the status.
*     end if
*     Report any error.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     23/11/94 (ACD): Original version.
*     21/12/99 (ACD): Added check that the given parameter or name is unique,
*        ie. does not alreay exist in the catalogue.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
      INCLUDE 'CAT_ERR'           ! CAT error codes.
*  Global Variables:
      INCLUDE 'CAT1_CATS_CMN'     ! Catalogues common block.
*  Arguments Given:
      INTEGER
     :  CI,
     :  CSIZE,
     :  DIMS,
     :  SIZEA(1)
      CHARACTER
     :  QNAME*(*),
     :  UNITS*(*),
     :  EXTFMT*(*),
     :  COMM*(*)
      LOGICAL
     :  PRFDSP
      INTEGER*2
     :  VALUE
*  Arguments Returned:
      INTEGER
     :  QI
*  Status:
      INTEGER STATUS             ! Global status.
*  External References:
      INTEGER CHR_LEN
*  Local Variables:
      LOGICAL
     :  EXIST  ! Flag; does the given name already exist in the catalogue?
      INTEGER
     :  CIELM,     ! Common block array element for the catalogue.
     :  LQNAME,    ! Length of QNAME  (excl. trail. blanks).
     :  ERRLEN     !   "    "  ERRTXT ( "  .   "  .   "   ).
      DOUBLE PRECISION
     :  DATE       ! Modification date attribute.
      CHARACTER
     :  ERRTXT*75  ! Text of error message.
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Check whether the given parameter name is unique, ie. whether a
*       column or parameter of this name already exists in the catalogue,
*       and proceed if the name is unique.

         CALL CAT1_NMCHK (CI, QNAME, EXIST, STATUS)
         IF (.NOT. EXIST) THEN

*
*          Attempt to create an identifier for the parameter.

            CALL CAT1_CRTID (CAT__QITYP, CI, QI, STATUS)
            IF (STATUS .EQ. CAT__OK) THEN

*
*             Get the common block array element for the catalogue.

               CALL CAT1_CIELM (CI, CIELM, STATUS)

*
*             Get the creation date.

               CALL CAT1_GTDAT (DATE, STATUS)

*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., CAT__TYPEW,
     :           STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., CSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., DIMS, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., SIZEA, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., DATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., UNITS, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., EXTFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., PRFDSP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., COMM, STATUS)
               CALL CAT1_ADDAW (QI, 'VALUE', .TRUE., VALUE, STATUS)


*
*             If all is ok then increment the number of parameters.

               IF (STATUS .EQ. CAT__OK) THEN
                  NPAR__CAT1(CIELM) = NPAR__CAT1(CIELM) + 1
               END IF

            END IF
         ELSE

*
*          A parameter of the given name already exists; set the status.

            STATUS = CAT__DUPNM

         END IF

*
*       Report any error.

         IF (STATUS .NE. CAT__OK) THEN
            ERRTXT = ' '
            ERRLEN = 0

            CALL CHR_PUTC ('CAT_PPTAW: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTAW_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
