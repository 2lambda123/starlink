      SUBROUTINE KPG1_LTGET( PLOC, STATUS )
*+
*  Name:
*     KPG1_LTGET

*  Purpose:
*     Obtain a locator to an array holding a colour table for the currently
*     opened graphics device.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPG1_LTGET( PLOC, STATUS )

*  Description:
*     This routine returns an HDS locator for a 2-dimensional array
*     holding the colour table to load into the currently open graphics 
*     device. The HDS object is searched for in an HDS container file in 
*     the users ADAM directory. The  file is called "kappa.lut.sdf" and 
*     contains a LUT for different devices. The file should have been 
*     created by KPG1_LTSAV.
*
*     Each lut in the file is a _REAL array of shape (3,n) where
*     n is the number of colours in the lut. 
*
*     Each array has a name which identifies the graphics device
*     to which it refers. 
*
*  Arguments:
*     PLOC = CHARACTER * ( DAT__SZLOC ) (Returned)
*        The locator. returned equal to DAT__NOLOC if the colour table
*        cannot be found, or if an error occurs.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  A graphics device must previously have been opened using PGPLOT.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     22-NOV-2001 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT constants
      INCLUDE 'DAT_ERR'          ! DAT error constants

*  Arguments Returned:
      CHARACTER PLOC*(DAT__SZLOC)

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Used length of a string

*  Local Variables:
      CHARACTER LOC*(DAT__SZLOC) ! Locator to top-level container file object
      CHARACTER PATH*132         ! Path to the container file
      INTEGER DIMS( 2 )          ! Array dimensions
      INTEGER NC                 ! Number of characters in the buffer
      INTEGER NDIM               ! Number of array dimensions
*.

*  Initialize
      PLOC = DAT__NOLOC

*  Check the inherited status. 
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Translate the environment variable/logical name for ADAM_USER.
      CALL PSX_GETENV( 'ADAM_USER', PATH, STATUS )
      IF ( STATUS .NE. SAI__OK ) THEN

*  ADAM_USER may not be defined so annul the error and try a different
*  route to the file.
         CALL ERR_ANNUL( STATUS )

*  Obtain the home directory.
         CALL PSX_GETENV( 'HOME', PATH, STATUS )
         IF ( STATUS .NE. SAI__OK ) THEN
            CALL ERR_REP( 'KPG1_LTGET_1', '$HOME not defined.', 
     :                    STATUS )
            GO TO 999
         END IF

*  Generate the path of the ADAM_USER.
         NC = CHR_LEN( PATH )
         CALL CHR_APPND( '/adam', PATH, NC )

      ELSE

*  Find the length of the path for ADAM_USER.
         NC = CHR_LEN( PATH )
  
      END IF

*  Generate the full pathname to the file.
      CALL CHR_APPND( '/kappa_lut', PATH, NC )

*  Get a locator for the top level object in the container file.
*  ========================================================================

*  Attempt to open the file assuming it exists.
      CALL HDS_OPEN( PATH( : NC ), 'READ', LOC, STATUS ) 

*  If the file was not found, annul the error.
      IF( STATUS .EQ. DAT__FILNF ) THEN
         CALL ERR_ANNUL( STATUS )         

*  Otherwise...
      ELSE

*  Get a locator to the component within the HDS container file which
*  contains the LUT to be used.
         CALL KPG1_PGLOC( LOC, PLOC, STATUS )

*  If a component with the right name exists, use it.
         IF( PLOC .NE. DAT__NOLOC ) THEN

*  Get its dimensions.
            CALL DAT_SHAPE( PLOC, 2, DIMS, NDIM, STATUS )

*  Report an error if it is has the wrong number of dimensions.
            IF( NDIM .NE. 2 .AND. STATUS .EQ. SAI__OK ) THEN
               STATUS = SAI__ERROR
               CALL DAT_MSG( 'DAT', PLOC )

               IF( NDIM .EQ. 1 ) THEN
                  CALL ERR_REP( 'KPG1_LTGET_2', 'The colour table '//
     :                          'stored in HDS object ''^DAT'' '//
     :                          'has only 1 dimension. It should '//
     :                          'have 2.', STATUS )
               ELSE
                  CALL MSG_SETI( 'NDIM', NDIM )
                  CALL ERR_REP( 'KPG1_LTGET_3', 'The colour table '//
     :                         'stored in HDS object ''^DAT'' has '//
     :                         '^NDIM dimensions. It should have 2.',
     :                          STATUS )
               END IF
        
            END IF

*  Report an error if it is has the wrong number of colour guns.
            IF( DIMS( 1 ) .NE. 3 .AND. STATUS .EQ. SAI__OK ) THEN
               STATUS = SAI__ERROR
               CALL DAT_MSG( 'DAT', PLOC )
      
               IF( DIMS( 1 ) .EQ. 1 ) THEN
                  CALL ERR_REP( 'KPG1_LTGET_4', 'The colour table '//
     :                        'stored in HDS object ''^DAT'' has '//
     :                        'only 1 colour gun. It should have 3.',
     :                        STATUS )
               ELSE
                  CALL MSG_SETI( 'NG', DIMS( 1 ) )
                  CALL ERR_REP( 'KPG1_LTGET_5', 'The colour table '//
     :                        'stored in HDS object ''^DAT'' has '//
     :                        '^NG colour guns. It should have 3.',
     :                        STATUS )
               END IF
      
            END IF


*  Promote the locator to a prinmary locator so that the container file
*  will not be closed when we annul LOC.
            CALL DAT_PRMRY( .TRUE., PLOC, .TRUE., STATUS ) 

         END IF

*  Close the HDS container file.
         CALL DAT_ANNUL( LOC, STATUS )

      END IF

*  Tidy up.
 999  CONTINUE

      END
