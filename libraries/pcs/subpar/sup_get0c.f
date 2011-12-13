      SUBROUTINE SUBPAR_GET0C ( NAMECODE, CVALUE, STATUS )
*+
*  Name:
*     SUBPAR_GET0C

*  Purpose:
*     Read scalar parameter value.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL SUBPAR_GET0C ( NAMECODE, CVALUE, STATUS )

*  Description:
*     Get a scalar CHARACTER value from the storage associated with the
*     indicated parameter.
*     If the object data type differs from the access type, CHARACTER*(*), then
*     conversion is performed if possible.

*     Note that a Vector (1-D) object containing a single value is
*     different from a Scalar (0-D).

*  Arguments:
*     NAMECODE=INTEGER (given)
*        pointer to the parameter
*     CVALUE=CHARACTER*(*) (returned)
*        Value to be obtained from the parameter
*     STATUS=INTEGER

*  Algorithm:
*     Look-up the parameter definition, and extract the value from the
*     internal data area, or from a data structure, if one is defined
*     The number is extracted in the data type declared for the parameter.
*     Any required limits checking is done and, if successful, the
*     necessary type conversion is done.
*     Note that this differs from the Starlink strategy in which all
*     program parameters are actually stored in HDS structures. This
*     change has been made to optimise the time taken to access scalar
*     parameters.
*     For errors other than PAR__*, if not internal, re-prompt up to
*     MAXTRY times.

*  Copyright:
*     Copyright (C) 1984, 1985, 1987, 1988, 1991-1994 Science & Engineering Research Council.
*     Copyright (C) 1995, 2002 Central Laboratory of the Research Councils.
*     Copyright (C) 2006 Particle Physics and Astronomy Research Council.
*     All Rights Reserved.

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
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     BDK: B D Kelly (ROE)
*     AJC: A J Chipperfield (STARLINK)
*     PCTR: P.C.T. Rees (STARLINK)
*     TIMJ: Tim Jenness (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     24-SEP-1984 (BDK):
*        Original version
*     25-MAY-1985 (BDK):
*        Allow for type 'UNIV'
*     05-JUN-1985 (BDK):
*        do DAT_ASSOC with 'UPDATE', in case of subsequent
*        PAR_PUTs to the parameter
*     13-AUG-1987 (BDK):
*        on out-of-range, retry
*     16-NOV-1987 (BDK):
*        improve logical-to-char conversion
*     16-FEB-1988 (BDK):
*        don't overwrite bad status with OUTRANGE
*     12-AUG-1988 (AJC):
*        don't annul locator if not obtained
*     09-JUL-1991 (AJC):
*        remove LIB$CVT_DX_DX conversion
*     29-JUL-1991 (AJC):
*        handle improved error reporting from LIMITR
*     26-AUG-1992 (PCTR):
*        Replaced EMS_ELOAD/SUBPAR_WRITE loop with a call to
*        SUBPAR_EFLSH.
*     27-AUG-1992 (AJC):
*        Mark and release to protect higher level message tokens
*     19-NOV-1992 (AJC):
*        Changed status from LIMIT routines
*        Correct cleanup before reprompt
*     10-MAR-1993 (AJC):
*        Add DAT_PAR for SUBPAR_CMN
*      1-JUL-1993 (AJC):
*        Re-prompt on most errors, up to 5 times
*     29-SEP-1994 (AJC):
*        Use EMS_FACER not DAT_ERMSG to report errors
*        Don't report message associated with SUBPAR__OUTRANGE
*     20-DEC-1995 (AJC):
*        Don't use intermediate VALUE_STRING
*     26-FEB-2002 (AJC):
*        Trap truncation in the DAT_GET0C to improve error message.
*     21-NOV-2006 (TIMJ):
*        Initialise return value even if status is bad. Fixes valgrind warning.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE

*  Global Constants:
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'DAT_ERR'
      INCLUDE 'SUBPAR_PAR'
      INCLUDE 'SUBPAR_ERR'
      INCLUDE 'SUBPAR_PARERR'

*  Arguments Given:
      INTEGER NAMECODE                  ! Parameter number

*  Arguments Returned:
      CHARACTER * ( * ) CVALUE          ! Value obtained

*  Status:
      INTEGER STATUS                    ! Global status

*  Global Variables:
      INCLUDE 'SUBPAR_CMN'

*  Local Constants:
      INTEGER MAXDIM                    ! Maximum number of dimensions
      PARAMETER ( MAXDIM = 7 )
      INTEGER MAXTRY                    ! Maximum attempts to get good value
      PARAMETER ( MAXTRY = 5 )

*  Local Variables:
      LOGICAL INTERNAL                  ! .TRUE. => the value is
                                        ! stored internally rather than
                                        ! in a user-specified HDS
                                        ! structure.


      REAL VALUE_REAL                   ! Variables to store converted
      INTEGER VALUE_INTEGER             ! parameter value
      DOUBLE PRECISION VALUE_DOUBLE
      LOGICAL VALUE_LOGICAL

      INTEGER STYPE                           ! Stored type of the
                                              ! parameter.
                                              ! STYPE .LT. 10 => value
                                              ! stored internally
                                              ! STYPE .GE. 10 => value
                                              ! in a data structure.

      INTEGER TYPE                            ! Data type of the
                                              ! parameter.
                                              ! This is a numeric code
                                              ! with possible values
                                              ! SUBPAR__NONE
                                              ! SUBPAR__REAL
                                              ! SUBPAR__CHAR
                                              ! SUBPAR__INTEGER
                                              ! SUBPAR__DOUBLE
                                              ! SUBPAR__LOGICAL

      CHARACTER*(DAT__SZLOC) LOC              ! Locator if data stored in HDS
      INTEGER DIMS(MAXDIM)                    ! Object dimensions
      INTEGER ACTDIM                          ! Actual number of dimensions
      INTEGER TRIES                           ! Number of tries
      LOGICAL ACCEPTED                        ! If no reprompt required

      INTEGER LENST                           ! length of string

*.

*  Initialise the return value
      CVALUE = ' '

*  Check the inherited status.
      IF (STATUS .NE. SAI__OK) RETURN

*  Protect higher level tokens
      CALL EMS_MARK
*
*   Loop until in-range value got or some error
*
      ACCEPTED = .FALSE.
      TRIES = 0

      DO WHILE ( .NOT. ACCEPTED )
*
*      get the data type
*
         STYPE = PARTYPE(NAMECODE)

         TYPE = MOD ( STYPE, 10 )
*
*      Check whether the parameter is stored internally.
*
         IF ( ( PARSTATE(NAMECODE) .NE. SUBPAR__NULL ) .AND.
     :     ( PARVPATH(1,NAMECODE) .EQ. SUBPAR__INTERNAL ) .AND.
     :     ( PARTYPE(NAMECODE) .LT. 10 ) ) THEN
            INTERNAL = .TRUE.
         ELSE
            INTERNAL = .FALSE.
         ENDIF
*
*      If stored in a data structure, get its locator
*
         IF ( .NOT. INTERNAL ) THEN
            IF ( PARWRITE(NAMECODE) ) THEN
               CALL SUBPAR_ASSOC ( NAMECODE, 'UPDATE', LOC, STATUS )
            ELSE
               CALL SUBPAR_ASSOC ( NAMECODE, 'READ', LOC, STATUS )
            ENDIF

            IF (STATUS .EQ. SAI__OK) THEN
*           Get shape of object
               CALL DAT_SHAPE ( LOC, MAXDIM, DIMS, ACTDIM, STATUS )

*           It must be scalar
               IF (ACTDIM .NE. 0 ) THEN
                  STATUS = SUBPAR__ARRDIM
                  CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
                  CALL EMS_REP( 'SUP_GET0C1',
     :            'SUBPAR: Parameter ^NAME requires a scalar value',
     :             STATUS )
               ENDIF

            ENDIF

         ENDIF

         IF ( STATUS .EQ. SAI__OK ) THEN
*
*      Extract the data and do type conversion.
*
            IF ( TYPE .EQ. SUBPAR__CHAR ) THEN

               IF ( INTERNAL ) THEN
                  CALL SUBPAR_FETCHC ( NAMECODE, CVALUE, STATUS )
               ELSE
                  CALL DAT_GETC ( LOC, 0, 0, CVALUE, STATUS )
                  IF ( STATUS .EQ. DAT__TRUNC ) THEN
                     CALL EMS_ANNUL( STATUS )
                     STATUS = SUBPAR__OUTRANGE
                     CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
                     CALL EMS_SETC( 'CVALUE', CVALUE )
                     CALL EMS_REP( 'SUP_GET0C3',
     :               'SUBPAR: Parameter ^NAME - ' //
     :               'value ''^CVALUE...'' is too long',
     :                STATUS )
                     CALL EMS_SETI( 'MAX', LEN(CVALUE) )
                     CALL EMS_REP( 'SUP_GET0C3a',
     :               'Maximum length allowed is ^MAX characters',
     :                STATUS )
                  ENDIF
               ENDIF

               CALL SUBPAR_LIMITC ( NAMECODE, CVALUE, ACCEPTED,
     :           STATUS )

            ELSE IF ( TYPE .EQ. SUBPAR__REAL ) THEN

               IF ( INTERNAL ) THEN
                  CALL SUBPAR_FETCHR ( NAMECODE, VALUE_REAL, STATUS )
               ELSE
                  CALL DAT_GETR ( LOC, 0, 0, VALUE_REAL, STATUS )
               ENDIF

               CALL SUBPAR_LIMITR ( NAMECODE, VALUE_REAL, ACCEPTED,
     :           STATUS )

               IF ( STATUS .EQ. SAI__OK ) THEN
                  CALL CHR_RTOC( VALUE_REAL, CVALUE, LENST )
               ENDIF

            ELSE IF ( TYPE .EQ. SUBPAR__INTEGER ) THEN

               IF ( INTERNAL ) THEN
                  CALL SUBPAR_FETCHI ( NAMECODE, VALUE_INTEGER, STATUS )
               ELSE
                  CALL DAT_GETI ( LOC, 0, 0, VALUE_INTEGER, STATUS )
               ENDIF

               CALL SUBPAR_LIMITI ( NAMECODE, VALUE_INTEGER, ACCEPTED,
     :           STATUS )

               IF ( STATUS .EQ. SAI__OK ) THEN
                  CALL CHR_ITOC( VALUE_INTEGER, CVALUE, LENST )
               ENDIF

            ELSE IF ( TYPE .EQ. SUBPAR__DOUBLE ) THEN

               IF ( INTERNAL ) THEN
                  CALL SUBPAR_FETCHD ( NAMECODE, VALUE_DOUBLE, STATUS )
               ELSE
                  CALL DAT_GETD ( LOC, 0, 0, VALUE_DOUBLE, STATUS )
               ENDIF

               CALL SUBPAR_LIMITD ( NAMECODE, VALUE_DOUBLE, ACCEPTED,
     :           STATUS )

               IF ( STATUS .EQ. SAI__OK ) THEN
                  CALL CHR_DTOC( VALUE_DOUBLE, CVALUE, LENST )
               ENDIF

            ELSE IF ( TYPE .EQ. SUBPAR__LOGICAL ) THEN
               IF ( INTERNAL ) THEN
                  CALL SUBPAR_FETCHL ( NAMECODE, VALUE_LOGICAL, STATUS )
               ELSE
                  CALL DAT_GETL ( LOC, 0, 0, VALUE_LOGICAL, STATUS )
               ENDIF
*
*            There is no limit checking for logicals
*
               IF( VALUE_LOGICAL ) THEN
                  CVALUE = 'TRUE'
               ELSE
                  CVALUE = 'FALSE'
               ENDIF

            ELSE
*
*            The declared type is not primitive (eg. 'UNIV'). Just try
*            to get the value from HDS.
*
               CALL DAT_GETC ( LOC, 0, 0, CVALUE, STATUS )

            ENDIF
*
*          If storage was in an HDS structure, annul the locator.
*          NB - does not close the container file, or annul other cloned
*          locators which might have been previously associated with this
*          parameter. This should be good from the point of view of future
*          access speed to the same value.
*          This corresponds with SSE 0.75.
*
            IF ( .NOT. INTERNAL ) THEN
               CALL DAT_ANNUL ( LOC, STATUS )
            ENDIF

         ENDIF

*      Break the loop unless an error was reported and re-prompting is
*      a likely option i.e. for non-internals or one of the PAR errors was
*      reported from the ASSOC (or FETCHC) routine.
         IF ( (STATUS .EQ. SAI__OK )
     :   .OR. ( STATUS .EQ. PAR__NULL )
     :   .OR. ( STATUS .EQ. PAR__ABORT )
     :   .OR. ( STATUS .EQ. PAR__NOUSR )
     :   .OR. INTERNAL ) THEN

            ACCEPTED = .TRUE.

         ELSE
            ACCEPTED = .FALSE.
*        If not SUBPAR probable status error, report status
            IF ( ( STATUS .NE. SUBPAR__ARRDIM )
     :      .AND. ( STATUS .NE. SUBPAR__OUTRANGE )
     :      .AND. ( STATUS .NE. SUBPAR__CONER ) ) THEN
               CALL EMS_FACER( 'MESS', STATUS )
               CALL EMS_REP( 'SUP_GET0C4', '^MESS', STATUS )
            ENDIF
*        Cancel parameter value to force reprompt
            CALL SUBPAR_CANCL ( NAMECODE, STATUS )

*        Flush any pending error messages - resets status
            CALL SUBPAR_EFLSH( STATUS )

*        Check for try limit
            TRIES = TRIES + 1
            IF ( TRIES .EQ. MAXTRY ) THEN
               STATUS = PAR__NULL
               PARSTATE(NAMECODE) = SUBPAR__NULL
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_SETI( 'TRIES', TRIES )
               CALL EMS_REP( 'SUP_GET0C5', 'SUBPAR: '//
     :         '^TRIES prompts failed to get a good value for '//
     :         'parameter ^NAME - NULL assumed', STATUS )
            ENDIF

         ENDIF

      ENDDO

*  Release the error context
      CALL EMS_RLSE

      END
