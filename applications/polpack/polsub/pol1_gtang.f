      SUBROUTINE POL1_GTANG( INDF, CI, IWCS, ANGROT, STATUS )
*+
*  Name:
*     POL1_GTANG

*  Purpose:
*     Get the orientation of the reference direction from an NDF or
*     catalogue.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL POL1_GTANG( INDF, CI, IWCS, ANGROT, STATUS )

*  Description:
*     The routine returns the anti-clockwise angle from the first axis of
*     the Base Frame of the supplied FrameSet to the POLPACK reference
*     direction, in degrees.
*
*     If the NDF or catalogue contains a ANGROT value (either in the
*     POLPACK extension of an NDF or as a catalogue parameter), then
*     the ANGROT value is returned.
*
*     Otherwise, it the supplied FrameSet contains a Frame with Domain
*     POLANAL, the angle between the first axis of the POLANAL Frame
*     and the first axis of the Base Frame is returned as ANGROT.
*
*     ANGROT items were written by versions of POLPACK prior to V2.0.
*     The POLANAL Frame written before V2.0 did not take account of the
*     rotation of the reference Frame produced by POLCAL, and so was not
*     usable.

*  Arguments:
*     INDF = INTEGER (Given)
*        An NDF identifier. Supply NDF__NOID if a catalogue is being used.
*     CI = INTEGER (Given)
*        A CAT catalogue identifier. Only accessed if INDF is NDF__NOID.
*     IWCS = INTEGER (Given)
*        AST pointer to the FrameSet.
*     ANGROT = REAL (Given and Returned)
*        The anti-clockwise angle from the first axis of the Base Frame
*        to the reference direction, in degrees.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1999 Central Laboratory of the Research Councils

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     8-APR-1999 (DSB):
*        Original version.
*     20-SEP-2000 (DSB):
*        Report an error if neither ANGROT nor POLANAL Frame can be found.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'NDF_PAR'          ! NDF constants
      INCLUDE 'PRM_PAR'          ! VAL__ constants
      INCLUDE 'AST_PAR'          ! AST constants

*  Arguments Given:
      INTEGER INDF
      INTEGER CI
      INTEGER IWCS

*  Arguments Returned:
      REAL ANGROT

*  Status:
      INTEGER STATUS             ! Global status

*  Local Constants:
      DOUBLE PRECISION DTOR
      PARAMETER ( DTOR = 0.01745329251994329577 )

*  Local Variables:
      DOUBLE PRECISION OUT( 2, NDF__MXDIM )
      DOUBLE PRECISION IN( 2, NDF__MXDIM )
      INTEGER FS
      INTEGER GANG
      INTEGER I
      INTEGER ICURR
      INTEGER NDIM
      INTEGER NPOL
      REAL LANG
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise a local copy of ANGROT to indicate no value has yet been
*  obtained.
      LANG = VAL__BADR

*  If an NDF has been supplied, attempt to get the ANGROT value from the
*  POLPACK extension.
      IF( INDF .NE. NDF__NOID ) THEN
         CALL NDF_XGT0R( INDF, 'POLPACK', 'ANGROT', LANG, STATUS )

*  Otherwise, attempt to get a CAT identifier for the ANGROT catalogue
*  parameter.
      ELSE IF( STATUS .EQ. SAI__OK ) THEN
         CALL CAT_TIDNT( CI, 'ANGROT', GANG, STATUS )

*  Annul the error if no ANGROT parameter was found.
         IF( STATUS .NE. SAI__OK ) THEN
            CALL ERR_ANNUL( STATUS )

*  Otherwise, get its value and release the parameter identifier.
         ELSE
            CALL CAT_TIQAR( GANG, 'VALUE', LANG, STATUS )
            CALL CAT_TRLSE( GANG, STATUS )
         END IF
      END IF

*  If an ANGROT value was found, return it.
      IF( LANG .NE. VAL__BADR ) THEN
         ANGROT = LANG

*  If no ANGROT value was found, we need to look for a POLANAL Frame in
*  the WCS FrameSet.
      ELSE

*  Start an AST context.
         CALL AST_BEGIN( STATUS )

*  Get the number of axes in the Base Frame.
         NDIM = AST_GETI( IWCS, 'NIN', STATUS )

*  Note the index of the original Current frame.
         ICURR = AST_GETI( IWCS, 'CURRENT', STATUS )

*  Find the POLANAL Frame. It becomes the Current Frame in the FrameSet.
         FS = AST_FINDFRAME( IWCS, AST_FRAME( NDIM, 'MINAXES=1, '//
     :                       'MAXAXES=20', STATUS ), 'POLANAL',
     :                       STATUS )

*  Report an error if no POLANAL Frame was found.
         IF( FS .EQ. AST__NULL ) THEN
            STATUS = SAI__ERROR
            CALL ERR_REP( 'POL1_GTANG_ERR1', 'The reference direction'//
     :                    ' in the input data is undefined since the '//
     :                    'WCS information does not contain a POLANAL'//
     :                    ' Frame.', STATUS )

*  If a POLANAL Frame was found
         ELSE

*  Get the number of axes in it.
            NPOL = AST_GETI( FS, 'NAXES', STATUS )

*  Transform 2 points along the first axis of the reference Frame into
*  the Base Frame. The first point is the origin, the second point is a
*  unit distance along the first axis.
            DO I = 1, NPOL
               IN( 1, I ) = 0.0D0
               IN( 2, I ) = 0.0D0
            END DO
            IN( 2, 1 ) = 1.0D0

            CALL AST_TRANN( FS, 2, NPOL, 2, IN, .FALSE., NDIM, 2,
     :                      OUT, STATUS )

*  Find the anti-clockwise angle from the first axis of the Base Frame to
*  the line from point 1 to point 2. Convert from radians to degrees.
            ANGROT = REAL( ATAN2( OUT( 2, 2 ) - OUT( 1, 2 ),
     :                            OUT( 2, 1 ) - OUT( 1, 1 ) )/DTOR )

         END IF

*  Reinstate the original Current Frame.
         CALL AST_SETI( IWCS, 'Current', ICURR, STATUS )

*  End the AST context.
         CALL AST_END( STATUS )

      END IF

      END
