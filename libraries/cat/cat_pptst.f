      SUBROUTINE CAT_PPTSB (CI, QNAME, VALUE, COMM, QI, STATUS)
*+
*  Name:
*     CAT_PPTSB
*  Purpose:
*     Create a parameter, simultaneously setting some of its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTSB (CI, QNAME, VALUE, COMM; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting some of its attributes.
*
*     Note that the attributes set correspond to the ones usually used
*     with FITS tables.  Also note that the data type attribute can be 
*     deduced from the type of the routine.  However for CHARACTER 
*     parameters the CHARACTER size attribute should be set using
*     CAT_TATTC.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     VALUE  =  BYTE (Given)
*        Value for the parameter.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the default set of attributes of a parameter.
*         Replace the defaults with the actual values for those
*         attributes which are passed as arguments.
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
*     28/3/97  (ACD): Changed the definition of column and parameter
*        names to use the correct parametric contstant (CAT__SZCMP).
*     21/12/99 (ACD): Added check that the given parameter or name is
*        unique, ie. does not alreay exist in the catalogue.
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
     :  CI
      CHARACTER
     :  QNAME*(*),
     :  COMM*(*)
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
      CHARACTER
     :  ERRTXT*75  ! Text of error message.

*
*    Attributes for a single parameter.

      CHARACTER
     :  QNAM*(CAT__SZCMP),   ! Name attribute.
     :  QUNIT*(CAT__SZUNI),  ! Units attribute.
     :  QXFMT*(CAT__SZEXF),  ! External format attribute.
     :  QCOMM*(CAT__SZCOM),  ! Comments attribute.
     :  QVALUE*(CAT__SZVAL)  ! Value attribute.
      INTEGER
     :  QDTYPE,  ! Data type attribute.
     :  QCSIZE,  ! Character size attribute.
     :  QDIM,    ! Dimensionality attribute.
     :  QSIZE    ! Size attribute.
      DOUBLE PRECISION
     :  QDATE    ! Modification date attribute.
      LOGICAL
     :  QPDISP   ! Preferential display flag attribute.
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
*             Create the default set of values for the attributes of a
*             parameter.

               CALL CAT1_DPATT (QNAM, QDTYPE, QCSIZE, QDIM, QSIZE,
     :           QDATE, QUNIT, QXFMT, QPDISP, QCOMM, QVALUE, STATUS)

*
*             Replace the defaults with the actual values for those
*             attributes which are passed as arguments.

               QNAM = QNAME
               QDTYPE = CAT__TYPEB
               QCOMM = COMM
            
*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., QDTYPE, STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., QCSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., QDIM, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., QSIZE, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., QDATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., QUNIT, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., QXFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., QPDISP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., QCOMM, STATUS)
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

            CALL CHR_PUTC ('CAT_PPTSB: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTSB_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTSC (CI, QNAME, VALUE, COMM, QI, STATUS)
*+
*  Name:
*     CAT_PPTSC
*  Purpose:
*     Create a parameter, simultaneously setting some of its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTSC (CI, QNAME, VALUE, COMM; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting some of its attributes.
*
*     Note that the attributes set correspond to the ones usually used
*     with FITS tables.  Also note that the data type attribute can be 
*     deduced from the type of the routine.  However for CHARACTER 
*     parameters the CHARACTER size attribute should be set using
*     CAT_TATTC.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     VALUE  =  CHARACTER*(*) (Given)
*        Value for the parameter.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the default set of attributes of a parameter.
*         Replace the defaults with the actual values for those
*         attributes which are passed as arguments.
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
*     28/3/97  (ACD): Changed the definition of column and parameter
*        names to use the correct parametric contstant (CAT__SZCMP).
*     21/12/99 (ACD): Added check that the given parameter or name is
*        unique, ie. does not alreay exist in the catalogue.
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
     :  CI
      CHARACTER
     :  QNAME*(*),
     :  COMM*(*)
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
      CHARACTER
     :  ERRTXT*75  ! Text of error message.

*
*    Attributes for a single parameter.

      CHARACTER
     :  QNAM*(CAT__SZCMP),   ! Name attribute.
     :  QUNIT*(CAT__SZUNI),  ! Units attribute.
     :  QXFMT*(CAT__SZEXF),  ! External format attribute.
     :  QCOMM*(CAT__SZCOM),  ! Comments attribute.
     :  QVALUE*(CAT__SZVAL)  ! Value attribute.
      INTEGER
     :  QDTYPE,  ! Data type attribute.
     :  QCSIZE,  ! Character size attribute.
     :  QDIM,    ! Dimensionality attribute.
     :  QSIZE    ! Size attribute.
      DOUBLE PRECISION
     :  QDATE    ! Modification date attribute.
      LOGICAL
     :  QPDISP   ! Preferential display flag attribute.
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
*             Create the default set of values for the attributes of a
*             parameter.

               CALL CAT1_DPATT (QNAM, QDTYPE, QCSIZE, QDIM, QSIZE,
     :           QDATE, QUNIT, QXFMT, QPDISP, QCOMM, QVALUE, STATUS)

*
*             Replace the defaults with the actual values for those
*             attributes which are passed as arguments.

               QNAM = QNAME
               QDTYPE = CAT__TYPEC
               QCOMM = COMM
            
*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., QDTYPE, STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., QCSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., QDIM, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., QSIZE, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., QDATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., QUNIT, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., QXFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., QPDISP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., QCOMM, STATUS)
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

            CALL CHR_PUTC ('CAT_PPTSC: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTSC_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTSD (CI, QNAME, VALUE, COMM, QI, STATUS)
*+
*  Name:
*     CAT_PPTSD
*  Purpose:
*     Create a parameter, simultaneously setting some of its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTSD (CI, QNAME, VALUE, COMM; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting some of its attributes.
*
*     Note that the attributes set correspond to the ones usually used
*     with FITS tables.  Also note that the data type attribute can be 
*     deduced from the type of the routine.  However for CHARACTER 
*     parameters the CHARACTER size attribute should be set using
*     CAT_TATTC.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     VALUE  =  DOUBLE PRECISION (Given)
*        Value for the parameter.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the default set of attributes of a parameter.
*         Replace the defaults with the actual values for those
*         attributes which are passed as arguments.
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
*     28/3/97  (ACD): Changed the definition of column and parameter
*        names to use the correct parametric contstant (CAT__SZCMP).
*     21/12/99 (ACD): Added check that the given parameter or name is
*        unique, ie. does not alreay exist in the catalogue.
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
     :  CI
      CHARACTER
     :  QNAME*(*),
     :  COMM*(*)
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
      CHARACTER
     :  ERRTXT*75  ! Text of error message.

*
*    Attributes for a single parameter.

      CHARACTER
     :  QNAM*(CAT__SZCMP),   ! Name attribute.
     :  QUNIT*(CAT__SZUNI),  ! Units attribute.
     :  QXFMT*(CAT__SZEXF),  ! External format attribute.
     :  QCOMM*(CAT__SZCOM),  ! Comments attribute.
     :  QVALUE*(CAT__SZVAL)  ! Value attribute.
      INTEGER
     :  QDTYPE,  ! Data type attribute.
     :  QCSIZE,  ! Character size attribute.
     :  QDIM,    ! Dimensionality attribute.
     :  QSIZE    ! Size attribute.
      DOUBLE PRECISION
     :  QDATE    ! Modification date attribute.
      LOGICAL
     :  QPDISP   ! Preferential display flag attribute.
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
*             Create the default set of values for the attributes of a
*             parameter.

               CALL CAT1_DPATT (QNAM, QDTYPE, QCSIZE, QDIM, QSIZE,
     :           QDATE, QUNIT, QXFMT, QPDISP, QCOMM, QVALUE, STATUS)

*
*             Replace the defaults with the actual values for those
*             attributes which are passed as arguments.

               QNAM = QNAME
               QDTYPE = CAT__TYPED
               QCOMM = COMM
            
*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., QDTYPE, STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., QCSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., QDIM, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., QSIZE, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., QDATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., QUNIT, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., QXFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., QPDISP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., QCOMM, STATUS)
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

            CALL CHR_PUTC ('CAT_PPTSD: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTSD_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTSI (CI, QNAME, VALUE, COMM, QI, STATUS)
*+
*  Name:
*     CAT_PPTSI
*  Purpose:
*     Create a parameter, simultaneously setting some of its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTSI (CI, QNAME, VALUE, COMM; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting some of its attributes.
*
*     Note that the attributes set correspond to the ones usually used
*     with FITS tables.  Also note that the data type attribute can be 
*     deduced from the type of the routine.  However for CHARACTER 
*     parameters the CHARACTER size attribute should be set using
*     CAT_TATTC.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     VALUE  =  INTEGER (Given)
*        Value for the parameter.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the default set of attributes of a parameter.
*         Replace the defaults with the actual values for those
*         attributes which are passed as arguments.
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
*     28/3/97  (ACD): Changed the definition of column and parameter
*        names to use the correct parametric contstant (CAT__SZCMP).
*     21/12/99 (ACD): Added check that the given parameter or name is
*        unique, ie. does not alreay exist in the catalogue.
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
     :  CI
      CHARACTER
     :  QNAME*(*),
     :  COMM*(*)
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
      CHARACTER
     :  ERRTXT*75  ! Text of error message.

*
*    Attributes for a single parameter.

      CHARACTER
     :  QNAM*(CAT__SZCMP),   ! Name attribute.
     :  QUNIT*(CAT__SZUNI),  ! Units attribute.
     :  QXFMT*(CAT__SZEXF),  ! External format attribute.
     :  QCOMM*(CAT__SZCOM),  ! Comments attribute.
     :  QVALUE*(CAT__SZVAL)  ! Value attribute.
      INTEGER
     :  QDTYPE,  ! Data type attribute.
     :  QCSIZE,  ! Character size attribute.
     :  QDIM,    ! Dimensionality attribute.
     :  QSIZE    ! Size attribute.
      DOUBLE PRECISION
     :  QDATE    ! Modification date attribute.
      LOGICAL
     :  QPDISP   ! Preferential display flag attribute.
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
*             Create the default set of values for the attributes of a
*             parameter.

               CALL CAT1_DPATT (QNAM, QDTYPE, QCSIZE, QDIM, QSIZE,
     :           QDATE, QUNIT, QXFMT, QPDISP, QCOMM, QVALUE, STATUS)

*
*             Replace the defaults with the actual values for those
*             attributes which are passed as arguments.

               QNAM = QNAME
               QDTYPE = CAT__TYPEI
               QCOMM = COMM
            
*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., QDTYPE, STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., QCSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., QDIM, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., QSIZE, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., QDATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., QUNIT, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., QXFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., QPDISP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., QCOMM, STATUS)
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

            CALL CHR_PUTC ('CAT_PPTSI: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTSI_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTSL (CI, QNAME, VALUE, COMM, QI, STATUS)
*+
*  Name:
*     CAT_PPTSL
*  Purpose:
*     Create a parameter, simultaneously setting some of its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTSL (CI, QNAME, VALUE, COMM; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting some of its attributes.
*
*     Note that the attributes set correspond to the ones usually used
*     with FITS tables.  Also note that the data type attribute can be 
*     deduced from the type of the routine.  However for CHARACTER 
*     parameters the CHARACTER size attribute should be set using
*     CAT_TATTC.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     VALUE  =  LOGICAL (Given)
*        Value for the parameter.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the default set of attributes of a parameter.
*         Replace the defaults with the actual values for those
*         attributes which are passed as arguments.
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
*     28/3/97  (ACD): Changed the definition of column and parameter
*        names to use the correct parametric contstant (CAT__SZCMP).
*     21/12/99 (ACD): Added check that the given parameter or name is
*        unique, ie. does not alreay exist in the catalogue.
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
     :  CI
      CHARACTER
     :  QNAME*(*),
     :  COMM*(*)
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
      CHARACTER
     :  ERRTXT*75  ! Text of error message.

*
*    Attributes for a single parameter.

      CHARACTER
     :  QNAM*(CAT__SZCMP),   ! Name attribute.
     :  QUNIT*(CAT__SZUNI),  ! Units attribute.
     :  QXFMT*(CAT__SZEXF),  ! External format attribute.
     :  QCOMM*(CAT__SZCOM),  ! Comments attribute.
     :  QVALUE*(CAT__SZVAL)  ! Value attribute.
      INTEGER
     :  QDTYPE,  ! Data type attribute.
     :  QCSIZE,  ! Character size attribute.
     :  QDIM,    ! Dimensionality attribute.
     :  QSIZE    ! Size attribute.
      DOUBLE PRECISION
     :  QDATE    ! Modification date attribute.
      LOGICAL
     :  QPDISP   ! Preferential display flag attribute.
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
*             Create the default set of values for the attributes of a
*             parameter.

               CALL CAT1_DPATT (QNAM, QDTYPE, QCSIZE, QDIM, QSIZE,
     :           QDATE, QUNIT, QXFMT, QPDISP, QCOMM, QVALUE, STATUS)

*
*             Replace the defaults with the actual values for those
*             attributes which are passed as arguments.

               QNAM = QNAME
               QDTYPE = CAT__TYPEL
               QCOMM = COMM
            
*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., QDTYPE, STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., QCSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., QDIM, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., QSIZE, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., QDATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., QUNIT, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., QXFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., QPDISP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., QCOMM, STATUS)
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

            CALL CHR_PUTC ('CAT_PPTSL: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTSL_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTSR (CI, QNAME, VALUE, COMM, QI, STATUS)
*+
*  Name:
*     CAT_PPTSR
*  Purpose:
*     Create a parameter, simultaneously setting some of its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTSR (CI, QNAME, VALUE, COMM; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting some of its attributes.
*
*     Note that the attributes set correspond to the ones usually used
*     with FITS tables.  Also note that the data type attribute can be 
*     deduced from the type of the routine.  However for CHARACTER 
*     parameters the CHARACTER size attribute should be set using
*     CAT_TATTC.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     VALUE  =  REAL (Given)
*        Value for the parameter.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the default set of attributes of a parameter.
*         Replace the defaults with the actual values for those
*         attributes which are passed as arguments.
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
*     28/3/97  (ACD): Changed the definition of column and parameter
*        names to use the correct parametric contstant (CAT__SZCMP).
*     21/12/99 (ACD): Added check that the given parameter or name is
*        unique, ie. does not alreay exist in the catalogue.
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
     :  CI
      CHARACTER
     :  QNAME*(*),
     :  COMM*(*)
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
      CHARACTER
     :  ERRTXT*75  ! Text of error message.

*
*    Attributes for a single parameter.

      CHARACTER
     :  QNAM*(CAT__SZCMP),   ! Name attribute.
     :  QUNIT*(CAT__SZUNI),  ! Units attribute.
     :  QXFMT*(CAT__SZEXF),  ! External format attribute.
     :  QCOMM*(CAT__SZCOM),  ! Comments attribute.
     :  QVALUE*(CAT__SZVAL)  ! Value attribute.
      INTEGER
     :  QDTYPE,  ! Data type attribute.
     :  QCSIZE,  ! Character size attribute.
     :  QDIM,    ! Dimensionality attribute.
     :  QSIZE    ! Size attribute.
      DOUBLE PRECISION
     :  QDATE    ! Modification date attribute.
      LOGICAL
     :  QPDISP   ! Preferential display flag attribute.
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
*             Create the default set of values for the attributes of a
*             parameter.

               CALL CAT1_DPATT (QNAM, QDTYPE, QCSIZE, QDIM, QSIZE,
     :           QDATE, QUNIT, QXFMT, QPDISP, QCOMM, QVALUE, STATUS)

*
*             Replace the defaults with the actual values for those
*             attributes which are passed as arguments.

               QNAM = QNAME
               QDTYPE = CAT__TYPER
               QCOMM = COMM
            
*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., QDTYPE, STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., QCSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., QDIM, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., QSIZE, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., QDATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., QUNIT, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., QXFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., QPDISP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., QCOMM, STATUS)
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

            CALL CHR_PUTC ('CAT_PPTSR: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTSR_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
      SUBROUTINE CAT_PPTSW (CI, QNAME, VALUE, COMM, QI, STATUS)
*+
*  Name:
*     CAT_PPTSW
*  Purpose:
*     Create a parameter, simultaneously setting some of its attributes.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT_PPTSW (CI, QNAME, VALUE, COMM; QI; STATUS)
*  Description:
*     Create a parameter, simultaneously setting some of its attributes.
*
*     Note that the attributes set correspond to the ones usually used
*     with FITS tables.  Also note that the data type attribute can be 
*     deduced from the type of the routine.  However for CHARACTER 
*     parameters the CHARACTER size attribute should be set using
*     CAT_TATTC.
*  Arguments:
*     CI  =  INTEGER (Given)
*        Catalogue identifier.
*     QNAME  =  CHARACTER*(*) (Given)
*        Name of the parameter.
*     VALUE  =  INTEGER*2 (Given)
*        Value for the parameter.
*     COMM  =  CHARACTER*(*) (Given)
*        Comments about the parameter.
*     QI  =  INTEGER (Returned)
*        Identifier for the parameter.
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     If the parameter name does not already exist in the catalogue then
*       Attempt to get an identifier for the parameter.
*       If ok then
*         Get the array element for the catalogue.
*         Create the default set of attributes of a parameter.
*         Replace the defaults with the actual values for those
*         attributes which are passed as arguments.
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
*     28/3/97  (ACD): Changed the definition of column and parameter
*        names to use the correct parametric contstant (CAT__SZCMP).
*     21/12/99 (ACD): Added check that the given parameter or name is
*        unique, ie. does not alreay exist in the catalogue.
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
     :  CI
      CHARACTER
     :  QNAME*(*),
     :  COMM*(*)
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
      CHARACTER
     :  ERRTXT*75  ! Text of error message.

*
*    Attributes for a single parameter.

      CHARACTER
     :  QNAM*(CAT__SZCMP),   ! Name attribute.
     :  QUNIT*(CAT__SZUNI),  ! Units attribute.
     :  QXFMT*(CAT__SZEXF),  ! External format attribute.
     :  QCOMM*(CAT__SZCOM),  ! Comments attribute.
     :  QVALUE*(CAT__SZVAL)  ! Value attribute.
      INTEGER
     :  QDTYPE,  ! Data type attribute.
     :  QCSIZE,  ! Character size attribute.
     :  QDIM,    ! Dimensionality attribute.
     :  QSIZE    ! Size attribute.
      DOUBLE PRECISION
     :  QDATE    ! Modification date attribute.
      LOGICAL
     :  QPDISP   ! Preferential display flag attribute.
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
*             Create the default set of values for the attributes of a
*             parameter.

               CALL CAT1_DPATT (QNAM, QDTYPE, QCSIZE, QDIM, QSIZE,
     :           QDATE, QUNIT, QXFMT, QPDISP, QCOMM, QVALUE, STATUS)

*
*             Replace the defaults with the actual values for those
*             attributes which are passed as arguments.

               QNAM = QNAME
               QDTYPE = CAT__TYPEW
               QCOMM = COMM
            
*
*             Create the attributes (they are all mutable at this stage
*             except those for the name and the data type).

               CALL CAT1_ADDAC (QI, 'NAME', .FALSE., QNAME, STATUS)
               CALL CAT1_ADDAI (QI, 'DTYPE', .FALSE., QDTYPE, STATUS)
               CALL CAT1_ADDAI (QI, 'CSIZE', .TRUE., QCSIZE, STATUS)
               CALL CAT1_ADDAI (QI, 'DIMS', .TRUE., QDIM, STATUS)
               CALL CAT1_ADDAI (QI, 'SIZE', .TRUE., QSIZE, STATUS)
               CALL CAT1_ADDAD (QI, 'DATE', .TRUE., QDATE, STATUS)
               CALL CAT1_ADDAC (QI, 'UNITS', .TRUE., QUNIT, STATUS)
               CALL CAT1_ADDAC (QI, 'EXFMT', .TRUE., QXFMT, STATUS)
               CALL CAT1_ADDAL (QI, 'PRFDSP', .TRUE., QPDISP, STATUS)
               CALL CAT1_ADDAC (QI, 'COMM', .TRUE., QCOMM, STATUS)
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

            CALL CHR_PUTC ('CAT_PPTSW: failed to create parameter ',
     :         ERRTXT, ERRLEN)

            IF (QNAME .NE. ' ') THEN
               LQNAME = CHR_LEN (QNAME)
               CALL CHR_PUTC (QNAME(1 : LQNAME), ERRTXT, ERRLEN)
            ELSE
               CALL CHR_PUTC ('<blank>', ERRTXT, ERRLEN)
            END IF

            CALL CHR_PUTC ('.', ERRTXT, ERRLEN)

            CALL CAT1_ERREP ('CAT_PPTSW_ERR', ERRTXT(1 : ERRLEN),
     :        STATUS)
         END IF

      END IF

      END
