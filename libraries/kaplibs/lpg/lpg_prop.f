      SUBROUTINE LPG_PROP( INDF1, CLIST, PARAM, INDF2, STATUS )
*+
*  Name:
*     LPG_PROP

*  Purpose:
*     Propagate NDF information to create a new NDF via the 
*     parameter system.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL LPG_PROP( INDF1, CLIST, PARAM, INDF2, STATUS )

*  Description:
*     This routine should be called in place of NDF_PROP within
*     applications which process groups of NDFs.
*
*     On the first invocation of the applicaton, a group of names for
*     some new NDFs will be obtained from the environment using the 
*     specified parameter. The first name will be used to create an NDF 
*     by propagation from INDF1, and an identifier for the new NDF will 
*     be returned. If more than one name was supplied for the parameter 
*     then the application may be invoked again (see LPG_AGAIN), in which 
*     case this routine will return an identifier for a new NDF with the
*     next name in the group supplied on the first invocation. 
*
*     If a modification element is included in the group expression
*     supplied for the parameter on the first invocation of the
*     application, the new NDF names are based on the names of the
*     first group of existing data files (NDFs or catalogues) to be 
*     accessed by the application.
*
*     If an application attempts to get a new NDF by cancelling the 
*     parameter (PAR_CANCL), the name used to create the returned NDF is 
*     NOT the next one in the group, but is obtained by prompting the 
*     user for a single new NDF.
*
*     The monolith routine should arrange to invoke the application 
*     repeatedly until one or more of its NDF parameters have been 
*     exhausted (i.e. all its values used). See NDF_AGAIN.

*  Arguments:
*     INDF1 = INTEGER (Given)
*        Identifier for an existing NDF (or NDF section) to act as a
*        template.
*     CLIST = CHARACTER * ( * ) (Given)
*        A comma-separated list of the NDF components which are to be
*        propagated to the new data structure. By default, the HISTORY,
*        LABEL and TITLE components and all extensions are propagated.
*        See the "Component Propagation" section for further details.
*     PARAM = CHARACTER * ( * ) (Given)
*        Name of the parameter for the new NDF.
*     INDF2 = INTEGER (Returned)
*        Identifier for the new NDF.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     13-SEP-1999 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! HDS constants.
      INCLUDE 'GRP_PAR'          ! GRP constants.
      INCLUDE 'NDF_PAR'          ! NDF constants
      INCLUDE 'SUBPAR_PAR'       ! SUBPAR constants
      INCLUDE 'LPG_CONST'        ! LPG private constants
      INCLUDE 'PAR_ERR'          ! PAR error constants

*  Global Variables:
      INCLUDE 'LPG_COM'          ! LPG global variables
*        PNAME( LPG__MXPAR ) = CHARACTER * ( DAT__SZNAM ) (Read and Write)
*           The names of the data file parameters used by the application.
*        IGRP( LPG__MXPAR ) = INTEGER (Read and Write)
*           The identifier for the GRP groups holding the data file names 
*           supplied for each data file parameter.
*        SIZE( LPG__MXPAR ) = INTEGER (Read and Write)
*           The number of data files supplied for each data file parameter.
*        NPAR = INTEGER (Read and Write)
*           The number of data file parameters used by the application.
*        NRUN = INTEGER (Read)
*           The number of times the application has been invoked so far.
*        OLD( LPG__MXPAR ) = LOGICAL (Read and Write)
*           A flag for each data file parameter indicating if the parameter is 
*           used to access existing (i.e. old) data files. If not, the parameter 
*           is used to access new data files to be created by the application.
*        REP( LPG__MXPAR ) = LOGICAL (Read and Write)
*           A flag for each data file parameter indicating if the parameter value 
*           has been reported yet by the current invocation of the
*           application.
*        VERB = LOGICAL (Read)
*           A flag indicating if the values used for each multi-valued 
*           parameter should be displayed each time the parameter is accessed.
*        DISAB = (Read)
*           A flag indicating if looping is currently disabled.

*  Arguments Given:
      INTEGER INDF1
      CHARACTER CLIST*(*)
      CHARACTER PARAM*(*)

*  Arguments Returned:
      INTEGER INDF2

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL LPG1_INIT         ! Ensure LPG common blocks are initialised

*  Local Variables:
      CHARACTER NAME*(GRP__SZNAM)! NDF name
      CHARACTER UPAR*(DAT__SZNAM)! Upper case parameter name
      INTEGER I                  ! Loop count
      INTEGER IGRP0              ! Basis group for modifications
      INTEGER IPAR               ! LPG common block slot index
      INTEGER STATE              ! Parameter state
      LOGICAL FLAG               ! Get more NDFs?
*.

*  Set an initial value for the INDF argument.
      INDF2 = NDF__NOID

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  If looping is currently disabled, just call NDF_PROP and exit.
      IF( DISAB ) THEN
         CALL NDF_PROP( INDF1, CLIST, PARAM, INDF2, STATUS )
         GO TO 999
      END IF

*  Convert the supplied parameter name to upper case.
      UPAR = PARAM
      CALL CHR_UCASE( UPAR )

*  See if the supplied parameter matches any of the parameters which have
*  already been accessed. If so, get the index of the matching parameter
*  within the LPG common arrays.
      IPAR = 0
      DO I = 1, NPAR
         IF( PNAME( I ) .EQ. UPAR ) THEN
            IPAR = I
            GO TO 10 
         END IF
      END DO
 10   CONTINUE

*  If this parameter has not been accessed before...
      IF( IPAR .EQ. 0 ) THEN

*  Reserve the next available common block slot for this parameter.
*  Report an error if all slots are in use.
         NPAR = NPAR + 1
         IF( NPAR .GT. LPG__MXPAR .AND. STATUS .EQ. SAI__OK ) THEN
            STATUS = SAI__ERROR
            CALL MSG_SETI( 'MX', LPG__MXPAR )
            CALL ERR_REP( 'LPG_PROP_ERR1', 'Too many data file '//
     :                    'parameters (>^MX) accessed by this '//
     :                    'application (programming error).', STATUS )
            GO TO 999
         END IF

         PNAME( NPAR ) = UPAR
         OLD( NPAR ) = .FALSE.

*  Modification elements will use the first group of existing data files 
*  (NDFs or catalogues) as the basis group. Find the index of the first 
*  parameter associated with existing data files.
         IGRP0 = GRP__NOID
         DO I = 1, NPAR - 1  
            IF( OLD( I ) .AND. IGRP( I ) .NE. GRP__NOID ) THEN
               IGRP0 = IGRP( I )
               GO TO 20
            END IF
         END DO
 20      CONTINUE

*  Get a group of NDFs from the environment using the supplied parameter.
*  Loop until a group expression is given which is not terminated by a
*  flag character.
         FLAG = .TRUE.
         DO WHILE( FLAG .AND. STATUS .EQ. SAI__OK ) 
            CALL NDG_CREAT( UPAR, IGRP0, IGRP( NPAR ), SIZE( NPAR ), 
     :                      FLAG, STATUS )
            IF( FLAG ) THEN
               CALL PAR_CANCL( UPAR, STATUS )
               CALL MSG_SETC( 'P', UPAR )
               CALL MSG_OUT( 'LPG_PROP_MSG1', 'Please supply more '//
     :                       'values for parameter %^P.', STATUS )
            END IF

         END DO

*  If no error occurred getting the NDF names, but no NDF names were
*  supplied, report a PAR__NULL status.
         IF( STATUS .EQ. SAI__OK .AND. SIZE( NPAR ) .EQ. 0 ) THEN
            STATUS = PAR__NULL
            CALL MSG_SETC( 'PARAM', UPAR )
            CALL ERR_REP( 'LPG_PROP_ERR2', 'Null NDF structure '//
     :                    'specified for the ''%^PARAM'' parameter.', 
     :                    STATUS )
         END IF

*  If a PAR__NULL status exists, store a null group identifier in common
*  for this parameter, and reset the size to zero.
         IF( STATUS .EQ. PAR__NULL ) THEN 
            IF( IGRP( NPAR ) .NE. GRP__NOID ) THEN
               CALL GRP_DELET( IGRP( NPAR ), STATUS )
            END IF
            SIZE( NPAR ) = 0
         END IF

*  Store the expanded list of names as the parameter's current value.
         IF( IGRP( NPAR ) .NE. GRP__NOID ) THEN
            CALL LPG1_PTPAR( UPAR, IGRP( NPAR ), STATUS )         
         END IF

*  Use this common block slot.
         IPAR = NPAR

*  If the parameter has been accessed before...
      ELSE

*  See if the application has cancelled the parameter value. If so, 
*  we get a new NDF using the parameter directly. This will probably
*  result in the user being prompted for a new parameter value. 
         CALL PAR_STATE( UPAR, STATE, STATUS )
         IF( STATE .EQ. SUBPAR__CANCEL ) THEN
            CALL NDG_PROP1( INDF1, CLIST, UPAR, INDF2, NAME, STATUS )

*  Store the new value in the group, replacing the old value, and store
*  the new list of names as the parameter's current value.
            IF( SIZE( IPAR ) .GT. 1 ) THEN
               CALL GRP_PUT( IGRP( IPAR ), 1, NAME, NRUN, STATUS )
               CALL LPG1_PTPAR( UPAR, IGRP( NPAR ), STATUS )         
            END IF

*  Otherwise, report a PAR__NULL error if the parameter has no GRP group
*  associated with it.
         ELSE IF( IGRP( IPAR ) .EQ. GRP__NOID .AND. 
     :            STATUS .EQ. SAI__OK ) THEN
            STATUS = PAR__NULL
            CALL MSG_SETC( 'PARAM', UPAR )
            CALL ERR_REP( 'LPG_PROP_ERR3', 'Null NDF structure '//
     :                    'specified for the ''%^PARAM'' parameter.', 
     :                    STATUS )
         END IF

      END IF

*  Get the NDF identifier unless one was obtained above.
      IF( INDF2 .EQ. NDF__NOID .AND. STATUS .EQ. SAI__OK ) THEN

*  Get the NDF from the group. If the group only contains one NDF name,
*  use it on all invocations of the application.
         IF( SIZE( IPAR ) .EQ. 1 ) THEN
            CALL NDG_NDFPR( INDF1, CLIST, IGRP( IPAR ), 1, INDF2, 
     :                      STATUS )
         ELSE
            CALL NDG_NDFPR( INDF1, CLIST, IGRP( IPAR ), NRUN, INDF2, 
     :                      STATUS )
         END IF

*  Tell the user which NDF is being used, if required, and if it has not 
*  already been reported.
         IF( VERB .AND. .NOT. REP( IPAR ) ) THEN
            CALL NDF_MSG( 'N', INDF2 )
            CALL MSG_SETC( 'P', UPAR )
            CALL MSG_OUT( 'LPG_PROP_MSG2', '%^P = ^N', STATUS )
            REP( IPAR ) = .TRUE.
         END IF

      END IF

*  Tidy up.
 999  CONTINUE

*  If an error occurred, annul the NDF.
      IF( STATUS .NE. SAI__OK ) CALL NDF_ANNUL( INDF2, STATUS )

      END
