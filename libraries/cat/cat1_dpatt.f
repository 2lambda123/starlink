      SUBROUTINE CAT1_DPATT (PNAME, PDTYPE, PCSIZE, PDIM, PSIZE, PDATE, 
     :  PUNIT, PXFMT, PPDISP, PCOMM, PVALUE, STATUS)
*+
*  Name:
*     CAT1_DPATT
*  Purpose:
*     Generate default attributes for a parameter.
*  Language:
*     Fortran 77.
*  Invocation:
*     CALL CAT1_DPATT (PNAME, PDTYPE, PCSIZE, PDIM, PSIZE, PDATE, PUNIT,
*       PXFMT, PPDISP, PCOMM, PVALUE; STATUS)
*  Description:
*     Generate a default set of attributes for a parameter.
*  Arguments:
*     PNAME  =  CHARACTER*(*) (Returned)
*        Name attribute.
*     PDTYPE  =  INTEGER (Returned)
*        Data type attribute.
*     PCSIZE  =  INTEGER (Returned)
*        Character size attribute (equals zero if the attribute is not
*        of data type character).
*     PDIM  =  INTEGER (Returned)
*        Dimensionality attribute.
*     PSIZE  =  INTEGER (Returned)
*        Size attribute.
*     PDATE  =  DOUBLE PRECISION (Returned)
*        Modification date attribute.
*     PUNIT  =  CHARACTER (Returned)
*        Units attribute.
*     PXFMT  =  CHARACTER*(*) (Returned)
*        External format attribute.
*     PPDISP  =  LOGICAL (Returned)
*        Preferential display flag attribute.
*     PCOMM  =  CHARACTER*(*) (Returned)
*        Comments attribute.
*     PVALUE  =  CHARACTER*(*) (Returned)
*        Value attribute (here always character).
*     STATUS  =  INTEGER (Given and Returned)
*        The global status.
*  Algorithm:
*     Set each of the attributes to a default value.
*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils
*  Authors:
*     ACD: A C Davenhall (Leicester)
*  History:
*     24/6/93 (ACD): Original version.
*     16/2/94 (ACD): First stable version.
*  Bugs:
*     None known
*-
*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'CAT_PAR'           ! External CAT constants.
*  Arguments Returned:
      CHARACTER
     :  PNAME*(*),
     :  PUNIT*(*),
     :  PXFMT*(*),
     :  PCOMM*(*),
     :  PVALUE*(*)
      INTEGER
     :  PDTYPE,
     :  PCSIZE,
     :  PDIM,
     :  PSIZE
      DOUBLE PRECISION
     :  PDATE
      LOGICAL
     :  PPDISP
*  Status:
      INTEGER STATUS             ! Global status
*.

      IF (STATUS .EQ. CAT__OK) THEN

*
*       Define a default value for each attribute of the parameter.

         PNAME = ' '
         PDTYPE = CAT__TYPEC
         PCSIZE = CAT__SZVAL
         PDIM = CAT__SCALR
         PSIZE = 1
         CALL CAT1_GTDAT (PDATE, STATUS)
         PUNIT = ' '
         PXFMT = ' '
         PPDISP = .TRUE.
         PCOMM = ' '
         PVALUE = ' '

      END IF

      END
