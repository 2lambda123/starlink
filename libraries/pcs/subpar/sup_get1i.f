      SUBROUTINE SUBPAR_GET1I ( NAMECODE, MAXVAL, IVALUES, ACTVAL,
     :  STATUS )
*+
*  Name:
*     SUBPAR_GET1I
 
*  Purpose:
*     Read vector parameter values.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL SUBPAR_GET1I ( NAMECODE, MAXVAL, IVALUES, ACTVAL, STATUS )
 
*  Description:
*     Read the values from a vector (or scalar) primitive object associated
*     with a Parameter.
*     There is a routine for each access type, INTEGER:
 
*        SUBPAR_GET1D    DOUBLE PRECISION
*        SUBPAR_GET1R    REAL
*        SUBPAR_GET1I    INTEGER
*        SUBPAR_GET1L    LOGICAL
*        SUBPAR_GET1C    CHARACTER[*n]
 
*     If the object data type differs from the access type, INTEGER, then
*     conversion is performed (if allowed).
 
*  Arguments:
*     NAMECODE=INTEGER ( given)
*        pointer to the parameter
*     MAXVAL=INTEGER
*        the maximum number of values to be obtained.
*     IVALUES(NVAL)=INTEGER
*        Array containing the values to be read from the object.
*     ACTVAL=INTEGER
*        number of values returned
*     STATUS=INTEGER
 
*  Algorithm:
*     The HDS locator associated with the parameter is obtained.
*     If this is successful, the shape of the object is obtained
*     If the object is scalar or 1-D and not larger than MAXVAL, the data
*     are extracted by appropriate means into the given array;
*     otherwise error SUBPAR__ARRDIM is reported.
*     If after ASSOC is OK, an error is detected, the value cancelled and
*     another value obtained if possible by prompting up to a set number
*     of times.
*     If the locator was obtained it is annulled.
 
*  Authors:
*     BDK: B D Kelly (ROE)
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     06-NOV-1984 (BDK):
*        Original version
*     12-FEB-1985 (BDK):
*        Only set STATUS=DAT__BOUND if status is ok
*     05-JUN-1985 (BDK):
*        Call DAT_ASSOC with UPDATE in case of subsequent
*        PAR_PUT to the parameter
*     18-AUG-1986 (BDK):
*        Check status before using pointer
*     10-JUN-1987 (BDK):
*        Accept scalar as 1-element vector
*     23-JUN-1987 (BDK):
*        Trap problem passing pointer to OUTCOPY
*     15-AUG-1988 (AJC):
*        Don't annul locator if not obtained
*     09-JUL-1991 (AJC):
*        Use HDS conversion
*     16-OCT-1991 (AJC):
*        Restore ability to read scalar object
*      5-AUG-1992 (AJC):
*        Report to cover HDS failure without report
*      9-SEP-1992 (AJC):
*        Allow internal scalar as 1 element array
*     26-FEB-1993 (AJC):
*        Add INCLUDE DAT_PAR
*      1-JUL-1993 (AJC):
*        Reprompt on all errors up to five times
*     29-SEP-1994 (AJC):
*        Use EMS_FACER not DAT_ERMSG to report errors
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type Definitions:
      IMPLICIT NONE
 
*  Global Constants:
      INCLUDE 'SAE_PAR'                 ! SAI Constants
      INCLUDE 'DAT_PAR'                 ! DAT Constants
      INCLUDE 'SUBPAR_PAR'              ! SUBPAR Constants
      INCLUDE 'SUBPAR_ERR'              ! SUBPAR errors
      INCLUDE 'SUBPAR_PARERR'           ! SUBPAR PAR errors
 
*  Local Constants:
      INTEGER MAXDIM                    ! Maximum number of dimensions
      PARAMETER ( MAXDIM = 7 )
      INTEGER MAXTRY                    ! Maximum attempts to get good value
      PARAMETER ( MAXTRY = 5 )
 
*  Arguments Given:
      INTEGER NAMECODE                  ! Parameter number
 
      INTEGER MAXVAL                    ! maximum number of values
 
*  Arguments Returned:
      INTEGER IVALUES(*)               ! Array for values
 
      INTEGER ACTVAL                    ! number of values
 
*    Status return :
      INTEGER STATUS                    ! Status Return
 
*  Global Variables:
      INCLUDE 'SUBPAR_CMN'
 
*  Local Variables:
      INTEGER DIMS(MAXDIM)                     ! Object dimensions
      INTEGER ACTDIM                           ! Actual number of dimensions
      INTEGER TRIES                            ! Number of tries
      CHARACTER*(DAT__SZLOC) BOTLOC            ! HDS locator
      LOGICAL ACCEPTED                         ! If no re-prompt required
 
*.
      IF (STATUS .NE. SAI__OK) RETURN
 
*   Protect higher level tokens
      CALL EMS_MARK
 
*   Loop until ACCEPTED
      ACCEPTED = .FALSE.
      TRIES = 0
 
      DOWHILE ( .NOT. ACCEPTED )
 
*      Get an HDS locator to the data for the parameter.
         IF ( PARWRITE(NAMECODE) ) THEN
            CALL SUBPAR_ASSOC ( NAMECODE, 'UPDATE', BOTLOC, STATUS )
         ELSE
            CALL SUBPAR_ASSOC ( NAMECODE, 'READ', BOTLOC, STATUS )
         ENDIF
 
         IF (STATUS .EQ. SAI__OK) THEN
*        Get shape of object
            CALL DAT_SHAPE ( BOTLOC, MAXDIM, DIMS, ACTDIM, STATUS )
 
*        If it is a 1-D object, read it as such provided that the size
*        is OK.
            IF (ACTDIM .EQ. 1 ) THEN
               IF( DIMS(1) .GT. MAXVAL ) THEN
                  STATUS = SUBPAR__ARRDIM
                  CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
                  CALL EMS_SETI( 'MAXVAL', MAXVAL )
                  CALL EMS_REP ( 'SUP_GET1_1', 'SUBPAR: '//
     :            'No more than ^MAXVAL elements are allowed '//
     :            'for parameter ^NAME', STATUS )
 
               ELSE
*              Get the data values and size
                  CALL DAT_GET1I( BOTLOC, MAXVAL, IVALUES,
     :            ACTVAL, STATUS )
               ENDIF
 
*        Else if it is a scalar object read it as such
            ELSEIF ( ACTDIM .EQ. 0 ) THEN
*           Get the data value
               CALL DAT_GET0I( BOTLOC, IVALUES(1), STATUS )
*           and set size = 1
               ACTVAL = 1
 
*        Else the object is invalid
            ELSE
               STATUS = SUBPAR__ARRDIM
               CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
               CALL EMS_REP ( 'SUP_GET1_2',
     :         'SUBPAR: N-D value supplied for 1-D parameter ^NAME',
     :          STATUS )
 
            ENDIF
 
*        Annul the locator
            CALL DAT_ANNUL( BOTLOC, STATUS )
 
*        If OK, break the loop
            IF ( STATUS .EQ. SAI__OK ) THEN
               ACCEPTED = .TRUE.
 
*        Otherwise cancel the parameter - forcing reprompt,
*        flush error messages and loop up to MAXTRY times
            ELSE
               IF ( STATUS .NE. SUBPAR__ARRDIM ) THEN
                  CALL EMS_FACER( 'MESS', STATUS )
                  CALL EMS_REP( 'SUP_GET1_3', '^MESS', STATUS )
               ENDIF
               CALL SUBPAR_CANCL ( NAMECODE, STATUS )
*           Flush error and reset status
               CALL SUBPAR_EFLSH( STATUS )
 
*           Check for try limit
               TRIES = TRIES + 1
               IF ( TRIES .EQ. MAXTRY ) THEN
                  ACCEPTED = .FALSE.
                  STATUS = PAR__NULL
                  PARSTATE(NAMECODE) = SUBPAR__NULL
                  CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
                  CALL EMS_SETI( 'TRIES', TRIES )
                  CALL EMS_REP( 'SUP_GET1_4', 'SUBPAR: '//
     :            '^TRIES prompts failed to get a good value for '//
     :            'parameter ^NAME - NULL assumed', STATUS )
               ENDIF
 
            ENDIF
 
 
*     Else if ASSOC failed exit
         ELSE
 
            ACCEPTED = .TRUE.
 
         ENDIF
 
      ENDDO
 
*  Release the error context
      CALL EMS_RLSE
 
      END
