      SUBROUTINE GNS_GWNG ( FILTER, ICNTX, NAME, DESCR, LD, STATUS )

*+
*  Name:
*     GNS_GWNG

*  Purpose:
*     Get next GKS workstation name

*  Invocation:
*     CALL GNS_GWNG( FILTER, ICNTX, NAME, DESCR, LD, STATUS )

*  Description:
*     The name and description of the "next" GKS workstation from the
*     list of defined workstation names is returned. If the context
*     argument is set to zero the first name in the list will be returned.
*     The context argument is incremented each time a new name is returned
*     until there are no more names in the list when it will be set to
*     zero.
*
*     FILTER is the name of a logical function that is called for each
*     workstation name in the list and can be used to select or reject
*     workstations on criteria such as workstation class. It should
*     return the value .TRUE. if the name is to be included in the list
*     and .FALSE. if it should not. FILTER has one integer argument; the
*     GKS workstation type.
*
*     The GNS library contains a suitable function called GNS_FILTG which
*     rejects any workstations that are not supported by the copy of GKS
*     being run (if GKS is open; if it is not all workstation types are
*     selected).

*  Arguments:
*     FILTER = LOGICAL FUNCTION (Given)
*        The name of the filter routine (which must be declared as
*        external in the calling routine)
*     ICNTX = INTEGER (Given and Returned)
*        Search context. An input value of zero starts at the beginning
*        of the list; returned as zero when there are no more names in
*        the list.
*     NAME = CHARACTER*(GNS__SZNAM) (Returned)
*        Workstation name
*     DESCR = CHARACTER*(GNS__SZDES) (Returned)
*        Text description of the workstation
*     LD = INTEGER (Returned)
*        Length of description
*     STATUS = INTEGER (Given and Returned)
*        The global status

*  Side Effects:
*     The GNS system may be initialized.

*  Authors:
*     DLT: D.L. Terrett (STARLINK)
*     NE: Nick Eaton (Durham University)

*  History:
*      4-APR-1989 (DLT):
*        Original version.
*      1-SEP-1992 (NE):
*        Updated prologue.
*-
      
*  Type Definitions:
      IMPLICIT NONE

*  Global Variables:
      INCLUDE 'GNS_PAR'
      INCLUDE 'gns.cmn'

*  Arguments Given:
      LOGICAL FILTER

*  Arguments Given and Returned:
      INTEGER ICNTX

*  Arguments Returned:
      CHARACTER*(*) NAME
      CHARACTER*(*) DESCR
      INTEGER LD

*  Status:
      INTEGER STATUS

*  External References:
      EXTERNAL FILTER

*  Local Variables:
      LOGICAL INCL
*.

      IF (STATUS.EQ.0) THEN

         IF (ICNTX.LE.0) THEN

*        We are starting a new search
            CALL gns_1INITG(STATUS)
            ICNTX = 0

         END IF

         IF (STATUS.EQ.0) THEN
      
*     Increment context count
   10       CONTINUE
            ICNTX = ICNTX + 1

            IF (ICNTX.LE.NUMNAM) THEN

*           Call filter routine
               INCL = FILTER(ITYPES(ICNTX))

*           If we want this one then copy it's name and description
               IF (INCL) THEN
                  NAME = NAMES(ICNTX)
                  LD = LDESC(ICNTX)
                  IF (LD.GT.0) DESCR = WSDESC(ICNTX)(:LD)
               ELSE
      
*           Go and get another one (if there are any more)
                  GO TO 10
               END IF
            ELSE

*        There are no names left so reset the context argument
               ICNTX = 0
            END IF
         END IF
      END IF
      END

