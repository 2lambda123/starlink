      SUBROUTINE SUBPAR_GETNI ( NAMECODE, NDIM, MAXD, VALUES, ACTD,
     :  STATUS )
*+
*  Name:
*     SUBPAR_GETNI
 
*  Purpose:
*     Read parameter values.
 
*  Language:
*     Starlink Fortran 77
 
*  Invocation:
*     CALL SUBPAR_GETNI ( NAMECODE, NDIM, MAXD, VALUES, ACTD, STATUS )
 
*  Description:
*     Read the values from an n-dimensional object associated with a
*     parameter.
*     The supplied number of dimensions, NDIM, must be .GE. the
*     actual number of object dimensions.   The dimensions, MAXD, of
*     the program array must be of sufficient size (along each axis)
*     to contain the object array.
*     There is a routine for each access type, INTEGER:
 
*        SUBPAR_GETND    DOUBLE PRECISION
*        SUBPAR_GETNR    REAL
*        SUBPAR_GETNI    INTEGER
*        SUBPAR_GETNL    LOGICAL
*        SUBPAR_GETNC    CHARACTER[*n]
 
*     If the object data type differs from the access type, INTEGER, then
*     conversion is performed (if allowed).
 
*  Arguments:
*     NAMECODE=INTEGER
*        pointer to the parameter
*     NDIM=INTEGER
*        The dimensionality of the VALUES array
*     MAXD(NDIM)=INTEGER
*        Array specifying the dimensions of the program array
*        to receive the data values.
*     VALUES(*)=INTEGER
*        Array to receive the values associated with the object.
*        It must be of sufficient size to contain them all.
*     ACTD(NDIM)=INTEGER
*        Array to receive the actual object dimensions.
*     STATUS=INTEGER
 
*  Algorithm:
*     The HDS locator associated with the parameter is obtained.
*     If this is successful, the shape of the associated object is found
*     and checked. Missing dimensions of the ACTD vector are set to 1.
*     If the object associated is too large, error SUBPAR__ARRDIM is
*     reported.
*     If all is OK, the data are extracted into the required array and
*     the locator annulled.
*     If an error is detected after an object is associated, error messages
*     are flushed and another value obtained if possible by prompting up to
*     a set number of times.
 
*  Authors:
*     BDK: B D Kelly (ROE)
*     AJC: A J Chipperfield (STARLINK)
*     {enter_new_authors_here}
 
*  History:
*     06.11.1984 (BDK):
*        Original version
*     12.02.1985 (BDK):
*        Only set STATUS=DAT__BOUND if status is ok
*     05.06.1985 (BDK):
*        Call DAT_ASSOC with UPDATE in case of subsequent
*        calls to DAT_PUT
*     18.08.1986 (BDK):
*        Check status before using pointer
*     10.06.1987 (BDK):
*        Allow objects of fewer than NDIM dimensions
*     23.06.1987 (BDK):
*        Avoid passing invalid descriptor to OUTCOPY
*     15.08.1988 (AJC):
*        Don't annul locator if not obtained
*     11.07.1991 (AJC):
*        Use HDS conversion
*      5.08.1992 (AJC):
*        Report to cover HDS failure to do so on error
*     26-FEB-1993 (AJC):
*        Add INCLUDE DAT_PAR
*      2-JUL-1993 (AJC):
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
 
*  Arguments Given:
      INTEGER NAMECODE                  ! Parameter number
      INTEGER NDIM			! Number of dimensions
      INTEGER MAXD(*)			! Array dimensions
 
*  Arguments Returned:
      INTEGER VALUES(*)			! Array to receive values
      INTEGER ACTD(*)			! Object dimensions
 
*    Status return :
      INTEGER STATUS			! Status Return
 
*  Global Variables:
      INCLUDE 'SUBPAR_CMN'
 
*  Local Constants:
      INTEGER MAXDIM                    ! Maximum number of dimensions
      PARAMETER ( MAXDIM = 7 )
      INTEGER MAXTRY                    ! Maximum attempts to get good value
      PARAMETER ( MAXTRY = 5 )
 
*  Local Variables:
      INTEGER DIMS(MAXDIM)                     ! dimensions of HDS object
      INTEGER ACTDIM                           ! dimensionality of HDS object
      INTEGER J                                ! loop counter
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
*
*      Get an HDS locator to the data for the parameter.
*
         IF ( PARWRITE(NAMECODE) ) THEN
            CALL SUBPAR_ASSOC ( NAMECODE, 'UPDATE', BOTLOC, STATUS )
         ELSE
            CALL SUBPAR_ASSOC ( NAMECODE, 'READ', BOTLOC, STATUS )
         ENDIF
 
         IF (STATUS .EQ. SAI__OK) THEN
*        Get the object dimensions
            CALL DAT_SHAPE ( BOTLOC, MAXDIM, DIMS, ACTDIM, STATUS )
 
*        Now check size and shape.
*        If actual dimensionality less than given, set higher dimensions
*        to 1
            IF ( STATUS .EQ. SAI__OK ) THEN
 
*           Ensure DIMS set correct for a scalar object
               IF ( ACTDIM .EQ. 0 ) DIMS(1) = 0
 
               IF (ACTDIM .LE. NDIM) THEN
                  DO J = 1, NDIM
                     IF ( J .GT. ACTDIM ) ACTD(J) = 1
                     IF ( DIMS( J ) .GT. MAXD(J) ) THEN
                        STATUS = SUBPAR__ARRDIM
                        CALL EMS_SETI( 'DIM', J )
                        CALL EMS_SETI( 'MAX', MAXD(J) )
                        CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
                        CALL EMS_REP ( 'SUP_GETN1', 'SUBPAR: '//
     :                  'Maximum ^MAX exceeded for dimension ^DIM '//
     :                  'of parameter ^NAME', STATUS )
                     ENDIF
                  ENDDO
 
*              If OK, get the data values and size
                  IF ( STATUS .EQ. SAI__OK )
     :               CALL DAT_GETNI( BOTLOC, ACTDIM, MAXD,
     :                 VALUES, ACTD, STATUS )
 
               ELSE
                  STATUS = SUBPAR__ARRDIM
                  CALL EMS_SETI( 'DIMS', NDIM )
                  CALL EMS_SETC( 'NAME', PARKEY(NAMECODE) )
                  CALL EMS_REP ( 'SUP_GETN2',
     :            'SUBPAR: Maximum ^DIMS dimensions exceeded '//
     :            'for parameter ^NAME', STATUS )
 
               ENDIF
 
            ENDIF
 
 
*        Annul the locator
            CALL DAT_ANNUL( BOTLOC, STATUS )
 
*        If OK, break the loop
            IF ( STATUS .EQ. SAI__OK ) THEN
               ACCEPTED = .TRUE.
 
*        Otherwise cancel the parameter - forcing reprompt,
*        flush error messages and loop
            ELSE
               IF ( STATUS .NE. SUBPAR__ARRDIM ) THEN
                  CALL EMS_FACER( 'MESS', STATUS )
                  CALL EMS_REP( 'SUP_GETN3', '^MESS', STATUS )
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
                  CALL EMS_REP( 'SUP_GETN4', 'SUBPAR: '//
     :            '^TRIES prompts failed to get a good value for '//
     :            'parameter ^NAME - NULL assumed', STATUS )
               ENDIF
 
            ENDIF
 
 
*     Else if ASSOC failed - stop loop
         ELSE
            ACCEPTED = .TRUE.
 
         ENDIF
 
      ENDDO
 
*  Release the error context
      CALL EMS_RLSE
 
      END
