      SUBROUTINE ARD1_STAT( TYPE, ELEM, L, NDIM, AWCS, DLBND, DUBND, 
     :                      NEEDIM, NARG, II, UWCS, MAP, STAT, IWCS, 
     :                      WCSDAT, STATUS )
*+
*  Name:
*     ARD1_STAT

*  Purpose:
*     Get statement arguments from the ARD description and modify the
*     appropriate parameters.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARD1_STAT( TYPE, ELEM, L, NDIM, AWCS, DLBND, DUBND, NEEDIM, 
*                     NARG, II, UWCS, MAP, STAT, IWCS, WCSDAT, STATUS )

*  Description:
*     On succesive passes through this routine, arguments are read from
*     the supplied element until a complete set of arguments has been
*     constructed. The arguments are then used to implement the required
*     effect (modifying the user transformation, etc).

*  Arguments:
*     TYPE = INTEGER (Given)
*        An integer value identifing the statement.
*     ELEM = CHARACTER * ( * ) (Given)
*        The text of the current element of the ARD description.
*     L = INTEGER (Given)
*        The index of the last character to be checked in ELEM.
*     NDIM = INTEGER (Given)
*        The number of dimensions in the mask supplied to ARD_WORK.
*     AWCS = INTEGER (Given)
*        A pointer to an AST FrameSet supplied by the application. This
*        should have a Base Frame with Domain PIXEL referring to pixel
*        coords within the pixel mask and another Frame with Domain 
*        ARDAPP referring to "Application co-ordinates" (as defined by
*        the TRCOEF argument of ARD_WORK).
*     DLBND( * ) = DOUBLE PRECISION (Given)
*        The lower bounds of pixel coordinates.
*     DUBND( * ) = DOUBLE PRECISION (Given)
*        The upper bounds of pixel coordinates.
*     NEEDIM = LOGICAL (Given and Returned)
*        .TRUE. if a DIMENSION statement is still needed to define the
*        dimensionality of the ARD description.
*     NARG = INTEGER (Given and Returned)
*        The number of arguments extracted from the ARD description so
*        far for the current statement. Supplied equal to -1 if a new
*        argument list is being started.
*     II = INTEGER (Given and Returned)
*        The index within ELEM of the next character to be checked.
*     UWCS = INTEGER (Given)
*        A pointer to an AST FrameSet supplied by the user. If not
*        AST__NULL, this should at least have a Frame with Domain ARDAPP 
*        referring to "Application co-ordinates" (as defined by the TRCOEF 
*        argument of ARD_WORK). The current Frame in this FrameSet should
*        refer to "User co-ordinates" (i.e. the coord system in which
*        positions are supplied in the ARD description).
*     MAP = INTEGER (Returned)
*        A pointer to an AST Mapping from the pixel coords in the mask,
*        to the coordinate system in which positions are specified in the 
*        ARD expression. This is obtained by merging UWCS and AWCS,
*        aligning them in a suitable common Frame. 
*     STAT = LOGICAL (Returned)
*        Returned .TRUE. if more arguments are required for the current
*        statement. Returned .FALSE. if the current statement has now
*        been completed.
*     IWCS = INTEGER (Returned)
*        Returned equal to AST__NULL if the pixel->user mapping is linear.
*        Otherwise, it is returned holding a pointer to an AST FrameSet
*        containing just two Frames, the Base frame is pixel coords, the
*        current Frame is user coords.
*     WCSDAT( * ) = DOUBLE PRECISION (Returned)
*        Returned holding information which qualifies IWCS. If IWCS is
*        AST__NULL, then WCSDAT holds the coefficiets of the linear mapping 
*        from pixel to user coords. Otherwise, wcsdat(1) holds a lower
*        limit on the distance (within the user coords) per pixel, and
*        the other elements in WCSDAT are not used. The supplied array
*        should have at least NDIM*(NDIM+1) elements.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     16-FEB-1994 (DSB):
*        Original version.
*     5-JUN-2001 (DSB):
*        Modified to use AST instead of linear coeffs.
*     18-JUL-2001 (DSB):
*        Modified for ARD version 2.0.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL_ constants
      INCLUDE 'ARD_CONST'        ! ARD_ private constants
      INCLUDE 'ARD_ERR'          ! ARD_ error constants
      INCLUDE 'AST_PAR'          ! AST_ constants and functions

*  Global Variables:
      INCLUDE 'ARD_COM'          ! ARD common blocks
*        CMN_STARG( ARD__NSTAT ) = INTEGER (Read)
*           The number of arguments required by each statement.
*        CMN_STSYM( ARD__NSTAT ) = CHARACTER * ( ARD__SZSTA )
*           Symbols used to represent statement fields.

*  Arguments Given:
      INTEGER TYPE
      CHARACTER ELEM*(*)
      INTEGER L
      INTEGER NDIM
      INTEGER AWCS
      DOUBLE PRECISION DLBND( * )
      DOUBLE PRECISION DUBND( * )

*  Arguments Given and Returned:
      LOGICAL NEEDIM
      INTEGER NARG
      INTEGER II
      INTEGER UWCS

*  Arguments Returned:
      INTEGER MAP
      LOGICAL STAT
      INTEGER IWCS
      DOUBLE PRECISION WCSDAT( * )

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      EXTERNAL ARD1_INIT         ! Initialise ARD common blocks.

*  Local Variables:
      INTEGER
     :  ARGREQ,                  ! No. of arguments required
     :  I,                       ! Dimension counter
     :  IGRP,                    ! Group to store WCS FrameSet
     :  IOFF,                    ! Index of offset term in mapping
     :  J,                       ! Row count
     :  K                        ! Column count

      DOUBLE PRECISION
     :  STARGS( ARD__MXSAR )     ! Statement argument values
 
*  Ensure that the number of arguments required, and the arguments
*  values obtained so far are preserved.
      SAVE ARGREQ, STARGS, IGRP

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  WCS and COFRAME statements do not have a simple list of numerical arguments 
*  and so are treated as special cases.
      IF( TYPE .EQ. ARD__WCS .OR. TYPE .EQ. ARD__COF ) THEN 

*  If a new argument list is being started...
         IF( NARG .EQ. -1 ) THEN

*  Create a GRP group to hold the body of the statement.
            CALL GRP_NEW( ' ', IGRP, STATUS )

         ENDIF

*  Copy the argument list from the ARD description into the GRP group.
         CALL ARD1_ARGS2( ELEM, L, IGRP, NARG, II, STAT, STATUS )

*  Now handle statements with simple argument lists.
      ELSE

*  If a new argument list is being started...
         IF( NARG .EQ. -1 ) THEN

*  ...Store the number of arguments required for the statement.
            ARGREQ = CMN_STARG( TYPE )

*  Some statements have a variable number of arguments (indicated by
*  CMN_STARG being negative). Calculate the number of arguments required
*  for such statements.
            IF( ARGREQ .LT. 0 ) THEN

*  Report an error and abort if the dimensionality of the ARD
*  description has not yet been determined (NEEDIM is supplied .FALSE.
*  if NDIM is 2).
               IF( NEEDIM .AND. STATUS .EQ. SAI__OK ) THEN
                  STATUS = ARD__BADDM
                  CALL MSG_SETI( 'NDIM', NDIM )
                  CALL ERR_REP( 'ARD1_STAT_ERR1', 'ARD description is'//
     :                     ' defaulting to 2-dimensions. It should be'//
     :                     ' ^NDIM dimensional.', STATUS )
                  GO TO 999
               END IF

*  OFFSET - The number of arguments required for the OFFSET statement
*  equals the dimensionality of the ARD description. 
               IF( TYPE .EQ. ARD__OFF ) THEN
                  ARGREQ = NDIM

*  STRETCH - The number of arguments required for the STRETCH statement
*  equals the dimensionality of the ARD description. 
               ELSE IF( TYPE .EQ. ARD__STR ) THEN
                  ARGREQ = NDIM

*  COEFFS - The number of arguments required for the COEFFS statement
*  depends on the dimensionality of the ARD description. 
               ELSE IF( TYPE .EQ. ARD__COE ) THEN
                  ARGREQ = NDIM*( NDIM + 1 )

*  Report an error for any other statement.
               ELSE IF (STATUS .EQ. SAI__OK ) THEN
                  STATUS = ARD__INTER
                  CALL MSG_SETI( 'T', TYPE )
                  CALL ERR_REP( 'ARD1_STAT_ERR2', 'ARD1_STAT: '//
     :                    'Statement type ^T should not have '//
     :                    'variable argument list (programming error).', 
     :                    STATUS )
                  GO TO 999
               END IF
   
            END IF
   
         END IF

*  Copy the argument list from the ARD description into a local array.
         CALL ARD1_ARGS( ELEM, L, ARGREQ, ARD__MXSAR, STARGS, NARG, II,
     :                   STAT, STATUS )
      END IF

*  If the argument list is complete, update the appropriate ARD
*  parameters.
      IF( .NOT. STAT ) THEN 

*  If it is a DIMENSION statement, report an error and abort if the
*  specified dimensionality is not the same as that of the mask.
         IF( TYPE .EQ. ARD__DIM ) THEN

            IF( NINT( STARGS( 1 ) ) .NE. NDIM .AND.
     :          STATUS .EQ. SAI__OK ) THEN
               STATUS = ARD__BADDM
               CALL MSG_SETI( 'NDIM', NDIM )
               CALL ERR_REP( 'ARD1_STAT_ERR3', 'ARD description '//
     :                       'should be ^NDIM dimensional.',STATUS )
               GO TO 999
            END IF

*  Otherwise, indicate that a DIMENSION statement has been found.
            NEEDIM = .FALSE.

*  If it is a WCS statement, read the UWCS FrameSet from the GRP group and
*  delete it.
         ELSE IF( TYPE .EQ. ARD__WCS ) THEN
            IF( UWCS .NE. AST__NULL ) CALL AST_ANNUL( UWCS, STATUS )
            CALL ARD1_RDWCS( NDIM, IGRP, UWCS, STATUS )
            CALL GRP_DELET( IGRP, STATUS )

*  If it is a COFRAME statement, create a UWCS FrameSet from the GRP group and
*  delete it.
         ELSE IF( TYPE .EQ. ARD__COF ) THEN
            IF( UWCS .NE. AST__NULL ) CALL AST_ANNUL( UWCS, STATUS )
            CALL ARD1_RDCOF( NDIM, IGRP, UWCS, STATUS )
            CALL GRP_DELET( IGRP, STATUS )

*  If it is a COEFFS statement, create a new UWCS from the coefficients.
         ELSE IF( TYPE .EQ. ARD__COE ) THEN
            IF( UWCS .NE. AST__NULL ) CALL AST_ANNUL( UWCS, STATUS )
            CALL ARD1_COWCS( NDIM, STARGS, UWCS, STATUS )

*  If it is an OFFSET statement, modify the current UWCS.
         ELSE IF( TYPE .EQ. ARD__OFF ) THEN
            CALL ARD1_OFWCS( NDIM, STARGS, UWCS, STATUS )

*  If it is a SCALE statement, modify the current UWCS.
         ELSE IF( TYPE .EQ. ARD__SCA ) THEN
            CALL ARD1_SCWCS( NDIM, STARGS, UWCS, STATUS )

*  If it is a TWIST statement, modify the current UWCS.
         ELSE IF( TYPE .EQ. ARD__TWI ) THEN
            CALL ARD1_TWWCS( NDIM, STARGS, UWCS, STATUS )

*  If it is a STRETCH statement, modify the current UWCS.
         ELSE IF( TYPE .EQ. ARD__STR ) THEN
            CALL ARD1_STWCS( NDIM, STARGS, UWCS, STATUS )

*  Report an error and abort for any other statement.
         ELSE
            STATUS = ARD__INTER
            CALL MSG_SETI( 'TYPE', TYPE )
            CALL ERR_REP( 'ARD1_STAT_ERR5', 'Illegal statement '//
     :                    'identifier (^TYPE) encountered in routine '//
     :                    'ARD1_STAT (programming error).', STATUS )
            GO TO 999

         END IF

*  Merge the UWCS and AWCS to get the Mapping from PIXEL to user coords.
         CALL ARD1_MERGE( UWCS, AWCS, DLBND, DUBND, MAP, IWCS, WCSDAT, 
     :                    STATUS )

      END IF

*  Jump to here if an error occurs.
 999  CONTINUE

*  Give a context message if an error has occurred.      
      IF( STATUS .NE. SAI__OK ) THEN
         CALL MSG_SETC( 'ELEM', ELEM )
         CALL MSG_SETC( 'ST', CMN_STSYM( TYPE ) )
         CALL ERR_REP( 'ARD1_STAT_ERR6', 'Error processing ^ST '//
     :                 'statement in ARD description ''^ELEM''.',
     :                 STATUS )
      END IF
      
      END
